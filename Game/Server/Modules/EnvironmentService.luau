--!strict
-- EnvironmentService (Match)
-- The house's mood: lighting presets per chapter, corruption decor, area barriers, and power
-- (lamps on/off, outages, Grandma cutting the lights, fixing the fuse box).
-- Lighting properties replicate automatically; per-lamp flicker is animated by clients
-- (EffectsController) from the lamp's "Flickery" attribute to save bandwidth.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local PlaceRole = shared("PlaceRole")
local Notify = shared("Notify")
local Sfx = shared("Sfx")

local function svc(name: string): any
	return shared(name)
end

local EnvironmentService = {}

local house: Instance?
local powerOn = true
local powerToken = 0
local cfg: any = nil
local lamps: { { Root: Instance, Lights: { Light }, Bulbs: { BasePart }, Brightness: { [Light]: number } } } = {}

local grade: ColorCorrectionEffect
local atmosphere: Atmosphere
local bloom: BloomEffect

-- DEVELOPER: tune the look of each chapter here.
local PRESETS = {
	Night = {
		-- Playability first: dark enough to be tense, never black. Moonlit yard, dim interior.
		ClockTime = 0.3, Brightness = 2.2, Ambient = Color3.fromRGB(48, 42, 62), OutdoorAmbient = Color3.fromRGB(96, 92, 132),
		FogColor = Color3.fromRGB(20, 18, 30), ExposureCompensation = 0.35,
		Tint = Color3.fromRGB(228, 230, 255), Saturation = -0.12, Contrast = 0.12,
		AtmoDensity = 0.36, AtmoColor = Color3.fromRGB(70, 64, 96), AtmoDecay = Color3.fromRGB(36, 28, 48), AtmoHaze = 1.4,
	},
	Morning = {
		ClockTime = 6.6, Brightness = 2.2, Ambient = Color3.fromRGB(120, 108, 110), OutdoorAmbient = Color3.fromRGB(170, 150, 150),
		FogColor = Color3.fromRGB(230, 200, 190), ExposureCompensation = 0.2,
		Tint = Color3.fromRGB(255, 240, 225), Saturation = 0.05, Contrast = 0.02,
		AtmoDensity = 0.3, AtmoColor = Color3.fromRGB(255, 214, 190), AtmoDecay = Color3.fromRGB(255, 170, 150), AtmoHaze = 1.2,
	},
}

-- Corruption grade offsets (0..4): the house slowly turns sick.
local CORRUPTION_TINT = {
	[0] = Color3.fromRGB(228, 230, 255),
	[1] = Color3.fromRGB(235, 232, 250),
	[2] = Color3.fromRGB(240, 228, 236),
	[3] = Color3.fromRGB(250, 214, 214),
	[4] = Color3.fromRGB(255, 190, 190),
}

local function matchState(key: string, value: any)
	local ms = ReplicatedStorage:FindFirstChild("MatchState")
	if ms then
		ms:SetAttribute(key, value)
	end
end

local function ensureEffects()
	grade = Lighting:FindFirstChild("NightGrade") :: ColorCorrectionEffect
	if not grade then
		grade = Instance.new("ColorCorrectionEffect")
		grade.Name = "NightGrade"
		grade.Parent = Lighting
	end
	atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") :: Atmosphere
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	bloom = Lighting:FindFirstChildOfClass("BloomEffect") :: BloomEffect
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Intensity = 0.6
		bloom.Size = 20
		bloom.Threshold = 1.6
		bloom.Parent = Lighting
	end
end

local function apply(preset: any, tint: Color3?, time: number?)
	local info = TweenInfo.new(time or 2, Enum.EasingStyle.Sine)
	Lighting.ClockTime = preset.ClockTime
	TweenService:Create(Lighting, info, {
		Brightness = preset.Brightness,
		Ambient = preset.Ambient,
		OutdoorAmbient = preset.OutdoorAmbient,
		FogColor = preset.FogColor,
		ExposureCompensation = preset.ExposureCompensation,
	}):Play()
	TweenService:Create(grade, info, { TintColor = tint or preset.Tint, Saturation = preset.Saturation, Contrast = preset.Contrast }):Play()
	TweenService:Create(atmosphere, info, { Density = preset.AtmoDensity, Color = preset.AtmoColor, Decay = preset.AtmoDecay, Haze = preset.AtmoHaze }):Play()
end

-- ------------------------------------------------------------------ lamps & power

local function collectLamps()
	for _, root in CollectionService:GetTagged("Lamp") do
		local entry = { Root = root, Lights = {}, Bulbs = {}, Brightness = {} }
		local list = root:GetDescendants()
		if root:IsA("Light") then
			table.insert(list, root)
		end
		for _, d in list do
			if d:IsA("Light") then
				table.insert(entry.Lights, d)
				entry.Brightness[d] = d.Brightness
			elseif d:IsA("BasePart") and d.Name == "Bulb" then
				table.insert(entry.Bulbs, d)
				d:SetAttribute("OnColor", d.Color)
			end
		end
		table.insert(lamps, entry)
	end
end

-- ------------------------------------------------------------------ room lights
-- While Grandma sleeps the house is dark (only the pool of light around her chair and the
-- porch stay on). When she's awake she switches on the lights of every room she walks into,
-- which is also a great tell for players: lights popping on = she's coming.
-- Lamps outside any Room volume, or within ALWAYS_ON_RADIUS of her chair, are "always on".
local ALWAYS_ON_RADIUS = 14
local roomLit: { [BasePart]: boolean } = {}
local allLit = false -- morning / intermission: everything on
local lampRoomsResolved = false

local function lampPosition(lamp): Vector3?
	local b = lamp.Bulbs[1]
	if b then
		return b.Position
	end
	local l = lamp.Lights[1]
	local p = l and l.Parent
	if p and p:IsA("BasePart") then
		return p.Position
	elseif p and p:IsA("Attachment") then
		return p.WorldPosition
	end
	return nil
end

local function resolveLampRooms()
	if lampRoomsResolved then
		return
	end
	lampRoomsResolved = true
	local ps = svc("PlayerStateService")
	local sleep = house and house:FindFirstChild("GrandmaSleepSpot") :: BasePart?
	for _, lamp in lamps do
		local pos = lampPosition(lamp)
		lamp.Room = pos and ps:RoomAt(pos) or nil
		lamp.AlwaysOn = lamp.Room == nil or (sleep ~= nil and pos ~= nil and (pos - sleep.Position).Magnitude <= ALWAYS_ON_RADIUS)
	end
end

local function setLamp(lamp, on: boolean)
	for _, l in lamp.Lights do
		l.Enabled = on
	end
	for _, b in lamp.Bulbs do
		b.Material = if on then Enum.Material.Neon else Enum.Material.Glass
		b.Color = if on then (b:GetAttribute("OnColor") or b.Color) else Color3.fromRGB(60, 56, 50)
	end
	lamp.On = on
end

local function lampShouldBeOn(lamp): boolean
	if not powerOn then
		return false
	end
	return allLit or lamp.AlwaysOn == true or (lamp.Room ~= nil and roomLit[lamp.Room] == true)
end

local function refreshLamps()
	resolveLampRooms()
	for _, lamp in lamps do
		local want = lampShouldBeOn(lamp)
		if lamp.On ~= want then
			setLamp(lamp, want)
		end
	end
end

-- Old API kept for power changes.
local function setLamps(_on: boolean)
	refreshLamps()
end

function EnvironmentService:IsRoomLit(room: BasePart?): boolean
	return powerOn and (allLit or (room ~= nil and roomLit[room] == true))
end

-- Is this position lit by house lights? (used by Grandma's eyes)
function EnvironmentService:IsLitAt(pos: Vector3): boolean
	if not powerOn then
		return false
	end
	if allLit then
		return true
	end
	local room = svc("PlayerStateService"):RoomAt(pos)
	return room == nil or roomLit[room] == true
end

-- Grandma walks into a dark room: click, the lights come on (with a tiny flicker).
local function lightRoom(room: BasePart)
	if roomLit[room] or not powerOn then
		return
	end
	roomLit[room] = true
	for _, lamp in lamps do
		if lamp.Room == room and not lamp.AlwaysOn then
			local b = lamp.Bulbs[1]
			Sfx.Play("LightSwitch", b or room)
			task.spawn(function()
				setLamp(lamp, true)
				task.wait(0.07)
				setLamp(lamp, false)
				task.wait(0.09)
				setLamp(lamp, lampShouldBeOn(lamp))
			end)
		end
	end
end

-- Back to sleep: she switches everything off behind her, one lamp at a time.
local function lightsOutStaggered()
	local list = {}
	for room in roomLit do
		table.insert(list, room)
	end
	table.clear(roomLit)
	task.spawn(function()
		for _, room in list do
			for _, lamp in lamps do
				if lamp.Room == room and lamp.On and not lamp.AlwaysOn then
					setLamp(lamp, false)
					Sfx.Play("LightSwitch", lamp.Bulbs[1] or room, { Volume = 0.3 })
					task.wait(0.12)
				end
			end
		end
	end)
end

local AWAKE = {
	Waking = true, Searching = true, Patrolling = true, Returning = false, Chasing = true, Attacking = true,
	CheckingHiding = true, Stalking = true, Distracted = true,
}
local lastGrandmaState = "Asleep"

local function lightsTick()
	local match = svc("MatchService")
	if match:GetPhase() ~= "Night" or allLit then
		return
	end
	local grandma = svc("GrandmaService")
	local stateNow = grandma:GetState()
	local model = grandma:GetModel()
	if (stateNow == "Asleep" or stateNow == "FakeSleep") and lastGrandmaState ~= stateNow and next(roomLit) then
		lightsOutStaggered()
	end
	lastGrandmaState = stateNow
	if AWAKE[stateNow] and model and model.PrimaryPart then
		local room = svc("PlayerStateService"):RoomAt(model.PrimaryPart.Position)
		if room then
			lightRoom(room)
		end
	end
end

function EnvironmentService:IsPowerOn(): boolean
	return powerOn
end

function EnvironmentService:SetPower(on: boolean)
	if powerOn == on then
		return
	end
	powerOn = on
	setLamps(on)
	matchState("Power", on)
	Sfx.Play(if on then "PowerUp" else "PowerDown")
	svc("InteractionService"):OnPowerChanged(on)
end

-- Grandma flips the breaker. Comes back on its own after `seconds` unless fixed sooner.
function EnvironmentService:CutPower(seconds: number)
	EnvironmentService:SetPower(false)
	Notify.Banner("all", "LIGHTS OUT", "Fix the fuse box — or wait it out.", Color3.fromRGB(123, 92, 142))
	powerToken += 1
	local token = powerToken
	task.delay(seconds, function()
		if token == powerToken and not (svc("EventService"):Has("PowerOff")) then
			EnvironmentService:SetPower(true)
		end
	end)
end

function EnvironmentService:RestorePower(by: Player?)
	if powerOn then
		return
	end
	powerToken += 1
	EnvironmentService:SetPower(true)
	if by then
		Notify.Toast("all", `{by.DisplayName} fixed the fuses!`, "Good")
		svc("NoiseService"):Emit((house and house:FindFirstChild("FuseBox") and (house:FindFirstChild("FuseBox") :: BasePart).Position) or Vector3.zero, 30, 80, by, "Fuse")
	end
end

-- ------------------------------------------------------------------ corruption & areas

local function setVisible(root: Instance, visible: boolean)
	local list = root:GetDescendants()
	for _, d in list do
		if d:IsA("BasePart") then
			if d:GetAttribute("OrigT") == nil then
				d:SetAttribute("OrigT", d.Transparency)
				d:SetAttribute("OrigC", d.CanCollide)
			end
			d.Transparency = if visible then d:GetAttribute("OrigT") else 1
			d.CanCollide = if visible then d:GetAttribute("OrigC") else false
			d.CanQuery = visible and d:GetAttribute("OrigC") == true
		elseif d:IsA("Decal") or d:IsA("Texture") then
			if d:GetAttribute("OrigT") == nil then
				d:SetAttribute("OrigT", d.Transparency)
			end
			d.Transparency = if visible then d:GetAttribute("OrigT") else 1
		elseif d:IsA("Light") or d:IsA("ParticleEmitter") then
			d.Enabled = visible
		end
	end
end

local function applyCorruption(level: number)
	local folder = house and house:FindFirstChild("Corruption")
	if not folder then
		return
	end
	for _, sub in folder:GetChildren() do
		local n = tonumber(sub.Name) or 99
		setVisible(sub, n <= level)
	end
	-- Late corruption: more lamps flicker (client animates).
	for i, lamp in lamps do
		local flickery = level >= 1 and (i % math.max(1, 6 - level) == 0)
		if lamp.Root:IsA("Instance") then
			lamp.Root:SetAttribute("Flickery", flickery)
		end
	end
end

local function applyBarriers(areas: { [string]: boolean })
	local folder = house and house:FindFirstChild("Barriers")
	if not folder then
		return
	end
	for _, b in folder:GetChildren() do
		local area = b:GetAttribute("Area")
		local open = area and areas[area] == true
		setVisible(b, not open)
		-- Pathfinding treats a hidden barrier as passable because CanCollide is false.
	end
end

-- ------------------------------------------------------------------ night hooks

function EnvironmentService:ApplyNight(_n: number, nightCfg: any)
	cfg = nightCfg
	powerToken += 1
	local preset = table.clone(PRESETS.Night)
	local tint = CORRUPTION_TINT[nightCfg.Corruption] or PRESETS.Night.Tint
	local ev = svc("EventService"):Get()
	if ev and ev.RedSky then
		preset.OutdoorAmbient = Color3.fromRGB(90, 30, 36)
		preset.AtmoColor = Color3.fromRGB(120, 40, 50)
		tint = Color3.fromRGB(255, 196, 196)
	end
	if nightCfg.Finale then
		preset.OutdoorAmbient = Color3.fromRGB(90, 50, 30)
		preset.AtmoColor = Color3.fromRGB(120, 70, 40)
		tint = Color3.fromRGB(255, 214, 180)
	end
	if nightCfg.Corruption >= 4 then
		preset.AtmoDensity = 0.45
		preset.Saturation = -0.3
		preset.Contrast = 0.2
	end
	apply(preset, tint, 1.5)
	applyCorruption(nightCfg.Corruption)
	applyBarriers(nightCfg.Areas)
	-- Grandma's asleep: the house goes dark (she lights rooms as she walks when awake).
	allLit = false
	table.clear(roomLit)
	lastGrandmaState = "Asleep"
	powerOn = false -- force refresh
	EnvironmentService:SetPower(not (ev and ev.PowerOff))
	refreshLamps()
	matchState("RedSky", ev ~= nil and ev.RedSky == true)
end

function EnvironmentService:Morning()
	powerToken += 1
	apply(PRESETS.Morning, nil, 3)
	allLit = true
	if not powerOn then
		EnvironmentService:SetPower(true)
	end
	refreshLamps()
	Sfx.Play("Rooster")
end

-- ------------------------------------------------------------------ lifecycle

function EnvironmentService.Preload() end

function EnvironmentService:Start()
	if not PlaceRole.IsMatch then
		return
	end
	house = workspace:WaitForChild("House", 20)
	ensureEffects()
	collectLamps()
	apply(PRESETS.Night, nil, 0.1)
	matchState("Power", true)
	task.spawn(function()
		while true do
			task.wait(0.4)
			local ok, err = pcall(lightsTick)
			if not ok then
				warn("[Environment] lights:", err)
			end
		end
	end)
end

return EnvironmentService
