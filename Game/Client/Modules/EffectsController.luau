--!strict
-- EffectsController (Match)
-- Local-only visual feedback. Never changes gameplay state.
--   (a) Noise: world ripple ring at the source (size by radius, colour by loudness) and a
--       bouncing "!" over the noisy player's head for everyone; edge pulse if YOU were loud.
--   (b) Chase post-FX: red grade + vignette + FOV + shake when Grandma targets you, lighter
--       when she chases someone near you.
--   (c) Lamp flicker: lamps tagged "Lamp" with Flickery = true flicker (a few per frame), and
--       every nearby lamp stutters when Grandma wakes up or starts a chase.
--   (d) Stirring: "she heard that" — a dark breath on the screen edges + heartbeat + FOV squeeze.
--
--   EffectsController:FlashEdge(layer "Red"|"Dark"|"Pulse", alpha, seconds, color?)
--   EffectsController:SetVignette(layer, key, alpha)      sustained source (0 = release)
--   EffectsController:FlickerLamps(seconds)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlaceRole = shared("PlaceRole")
local ScreenFx = shared("ScreenFx")

local EffectsController = {}

local player = Players.LocalPlayer
local C = ScreenFx.Colors

local settings: any = nil
local camCtl: any = nil
local music: any = nil
local matchState: Instance? = nil

-- ------------------------------------------------------------------ vignette layers

type Flash = { alpha: number, t0: number, dur: number }
type Layer = { Vig: any, Sustained: { [string]: number }, Flashes: { Flash }, Pulse: boolean }
local layers: { [string]: Layer } = {}

local function makeLayers(gui: ScreenGui)
	layers.Dark = { Vig = ScreenFx.Vignette(gui, C.Ink, 0.34), Sustained = {}, Flashes = {}, Pulse = false }
	layers.Red = { Vig = ScreenFx.Vignette(gui, C.Blood, 0.3), Sustained = {}, Flashes = {}, Pulse = true }
	layers.Pulse = { Vig = ScreenFx.Vignette(gui, C.Mustard, 0.22), Sustained = {}, Flashes = {}, Pulse = false }
end

function EffectsController:FlashEdge(layer: string, alpha: number, seconds: number, color: Color3?)
	local l = layers[layer]
	if not l then
		return
	end
	if settings and settings:Get("ReduceFlashes") then
		alpha *= 0.5
	end
	if color then
		l.Vig:Set(l.Vig.Alpha, color)
	end
	table.insert(l.Flashes, { alpha = alpha, t0 = os.clock(), dur = math.max(0.05, seconds) })
end

function EffectsController:SetVignette(layer: string, key: string, alpha: number)
	local l = layers[layer]
	if l then
		l.Sustained[key] = if alpha > 0 then alpha else nil
	end
end

local function stepLayers(now: number)
	local calm = settings and settings:Get("ReduceFlashes")
	for _, l in layers do
		local a = 0
		for _, v in l.Sustained do
			a = math.max(a, v)
		end
		if l.Pulse and a > 0 and not calm then
			a *= 0.82 + 0.18 * math.sin(now * 7)
		end
		for i = #l.Flashes, 1, -1 do
			local f = l.Flashes[i]
			local x = (now - f.t0) / f.dur
			if x >= 1 then
				table.remove(l.Flashes, i)
			else
				-- fast attack, smooth decay
				local env = if x < 0.12 then x / 0.12 else (1 - (x - 0.12) / 0.88) ^ 2
				a += f.alpha * env
			end
		end
		l.Vig:Set(math.min(a, 0.95))
	end
end

-- ------------------------------------------------------------------ (a) noise

local fxFolder: Folder? = nil
local markerFolder: Folder? = nil

-- The per-night respawn clears loose PlayerGui children (Folders included), so recreate the
-- noise-marker container on demand; its BillboardGuis have ResetOnSpawn = false.
local function ensureMarkerFolder(): Folder?
	if markerFolder and markerFolder.Parent then
		return markerFolder
	end
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil
	end
	local f = Instance.new("Folder")
	f.Name = "NoiseMarkers"
	f.Parent = pg
	markerFolder = f
	return f
end
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
local activeRipples = 0
local MAX_RIPPLES = 14

local function loudColor(loudness: number, kind: string): Color3
	if kind == "Break" or loudness >= 45 then
		return C.Blood
	elseif loudness >= 20 then
		return C.Mustard
	end
	return C.Paper
end

local function floorAt(pos: Vector3): Vector3
	local list: { Instance } = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	if fxFolder then
		table.insert(list, fxFolder)
	end
	rayParams.FilterDescendantsInstances = list
	local hit = workspace:Raycast(pos + Vector3.new(0, 1.5, 0), Vector3.new(0, -9, 0), rayParams)
	return if hit then hit.Position + Vector3.new(0, 0.08, 0) else pos
end

local function ripple(pos: Vector3, loudness: number, radius: number, kind: string, delay: number?)
	if activeRipples >= MAX_RIPPLES or not fxFolder then
		return
	end
	activeRipples += 1
	local floor = floorAt(pos)
	local size = math.clamp(radius * 0.22 + loudness * 0.12, 3, 26)
	local color = loudColor(loudness, kind)
	local ring = Instance.new("CylinderHandleAdornment")
	ring.Name = "NoiseRipple"
	ring.Adornee = workspace.Terrain
	ring.CFrame = CFrame.new(floor) * CFrame.Angles(math.rad(90), 0, 0)
	ring.Height = 0.08
	ring.Radius = 0.6
	ring.InnerRadius = 0.3
	ring.Color3 = color
	ring.Transparency = 0.15
	ring.AlwaysOnTop = false
	ring.ZIndex = 1
	ring.Parent = fxFolder
	local dur = 0.8 + math.min(0.6, loudness / 100)
	local tw = TweenService:Create(ring, TweenInfo.new(dur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, delay or 0), {
		Radius = size,
		InnerRadius = size * 0.86,
		Transparency = 1,
	})
	tw:Play()
	tw.Completed:Once(function()
		ring:Destroy()
		activeRipples -= 1
	end)
end

type Marker = { Gui: BillboardGui, Label: TextLabel, Stroke: UIStroke, Scale: UIScale, T0: number, Until: number }
local markers: { [number]: Marker } = {}

local function markHead(userId: number, loudness: number, kind: string)
	local p = Players:GetPlayerByUserId(userId)
	local char = p and p.Character
	local head = char and char:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") or not ensureMarkerFolder() then
		return
	end
	local m = markers[userId]
	if not m or m.Gui.Adornee ~= head or m.Gui.Parent ~= markerFolder then
		if m then
			m.Gui:Destroy()
		end
		local bb = Instance.new("BillboardGui")
		bb.Name = "Noisy_" .. userId
		bb.Adornee = head
		bb.Size = UDim2.fromOffset(46, 60)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.MaxDistance = 220
		bb.ResetOnSpawn = false
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(0.5, 0.5)
		label.Size = UDim2.fromScale(1, 1)
		label.FontFace = Font.fromEnum(Enum.Font.LuckiestGuy)
		label.TextScaled = true
		label.Text = "!"
		label.Parent = bb
		local stroke = Instance.new("UIStroke")
		stroke.Color = C.Ink
		stroke.Thickness = 3
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		stroke.Parent = label
		local sc = Instance.new("UIScale")
		sc.Parent = label
		bb.Parent = markerFolder
		m = { Gui = bb, Label = label, Stroke = stroke, Scale = sc, T0 = 0, Until = 0 }
		markers[userId] = m
	end
	local mk = m :: Marker
	local loud = kind == "Break" or loudness >= 45
	mk.Label.Text = if loud then "!!" else "!"
	mk.Label.TextColor3 = loudColor(math.max(loudness, 20), kind)
	mk.Label.TextTransparency = 0
	mk.Stroke.Transparency = 0
	mk.Label.Rotation = math.random(-12, 12)
	mk.T0 = os.clock()
	mk.Until = os.clock() + (if loud then 2.4 else 1.6)
	mk.Scale.Scale = 0.2
	TweenService:Create(mk.Scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = if loud then 1.35 else 1 }):Play()
end

local function stepMarkers(now: number)
	for id, m in markers do
		if now > m.Until or not m.Gui.Parent or not m.Gui.Adornee or not m.Gui.Adornee:IsDescendantOf(workspace) then
			m.Gui:Destroy()
			markers[id] = nil
		else
			local t = now - m.T0
			local left = m.Until - now
			m.Label.Position = UDim2.fromScale(0.5, 0.5 - math.abs(math.sin(t * 9)) * 0.18 * math.max(0, 1 - t / 1.2))
			if left < 0.3 then
				local a = 1 - left / 0.3
				m.Label.TextTransparency = a
				m.Stroke.Transparency = a
			end
		end
	end
end

local function onNoise(pos: any, loudness: any, radius: any, sourceUserId: any, kind: any)
	if typeof(pos) ~= "Vector3" then
		return
	end
	local loud = tonumber(loudness) or 0
	local rad = tonumber(radius) or 20
	local k = if typeof(kind) == "string" then kind else ""
	local cam = workspace.CurrentCamera
	if cam and (cam.CFrame.Position - pos).Magnitude < 170 then
		ripple(pos, loud, rad, k)
		if k == "Break" or loud >= 45 then
			ripple(pos, loud * 0.7, rad, k, 0.18)
		end
	end
	local uid = tonumber(sourceUserId) or 0
	if uid ~= 0 and loud >= 8 then
		if uid == player.UserId then
			if loud >= 20 then
				EffectsController:FlashEdge("Pulse", math.clamp(loud / 90, 0.3, 0.7), 0.7, if k == "Break" or loud >= 45 then C.Blood else C.Mustard)
				if k == "Break" and camCtl then
					camCtl:Shake(0.5, 0.25)
				end
			end
		else
			markHead(uid, loud, k)
		end
	end
end

-- ------------------------------------------------------------------ (b) chase

local grade: ColorCorrectionEffect? = nil
local chaseTarget = 0
local chase = 0
local wasTargeted = false

local function grandma(): Model?
	local g = CollectionService:GetTagged("Grandma")[1] or workspace:FindFirstChild("Grandma")
	return if g and g:IsA("Model") then g else nil
end

local function evalChase()
	local ms = matchState
	local state = ms and ms:GetAttribute("GrandmaState")
	local target = 0
	local targeted = false
	if (state == "Chasing" or state == "Attacking") and player:GetAttribute("Alive") ~= false then
		local g = grandma()
		targeted = g ~= nil and g:GetAttribute("Target") == player.UserId
		if targeted then
			target = 1
		else
			local root = g and g:FindFirstChild("HumanoidRootPart") :: BasePart?
			local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and me then
				local d = (root.Position - me.Position).Magnitude
				if d < 55 then
					target = 0.2 + 0.25 * (1 - d / 55)
				end
			end
		end
	end
	if targeted and not wasTargeted and camCtl then
		camCtl:Punch(10, 0.5)
		camCtl:Shake(0.9, 0.35)
	end
	wasTargeted = targeted
	chaseTarget = target
end

local function stepChase(dt: number)
	chase += (chaseTarget - chase) * (1 - math.exp(-dt * (if chaseTarget > chase then 5 else 1.6)))
	if chase < 0.002 then
		chase = 0
	end
	local g = grade
	if g then
		g.Enabled = chase > 0
		g.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(255, 186, 186), chase)
		g.Saturation = -0.18 * chase
		g.Contrast = 0.12 * chase
	end
	EffectsController:SetVignette("Red", "Chase", 0.5 * chase)
	if camCtl then
		camCtl:SetFovOffset("Chase", 5 * chase)
		camCtl:SetShake("Chase", 0.22 * chase)
	end
end

-- ------------------------------------------------------------------ (c) lamps

type Lamp = {
	Root: Instance,
	Pos: Vector3,
	Lights: { { L: Light, Base: number } },
	Bulbs: { BasePart },
	NextDip: number,
	DipUntil: number,
	DipLevel: number,
	Level: number,
}
local lamps: { Lamp } = {}
local lampOf: { [Instance]: Lamp } = {}
local rr = 0
local burstUntil = 0
local burstDirty: { [Lamp]: boolean } = {}
local LAMPS_PER_FRAME = 6
local LAMP_RANGE = 130

local function lampPos(root: Instance): Vector3?
	if root:IsA("BasePart") then
		return root.Position
	elseif root:IsA("Model") then
		return root:GetPivot().Position
	elseif root:IsA("Light") and root.Parent and root.Parent:IsA("BasePart") then
		return root.Parent.Position
	end
	local part = root:FindFirstChildWhichIsA("BasePart", true)
	return part and part.Position
end

local function addLamp(root: Instance)
	if lampOf[root] then
		return
	end
	local pos = lampPos(root)
	if not pos then
		return
	end
	local lamp: Lamp = { Root = root, Pos = pos, Lights = {}, Bulbs = {}, NextDip = 0, DipUntil = 0, DipLevel = 1, Level = 1 }
	local list = root:GetDescendants()
	if root:IsA("Light") then
		table.insert(list, root)
	end
	for _, d in list do
		if d:IsA("Light") then
			table.insert(lamp.Lights, { L = d, Base = d.Brightness })
		elseif d:IsA("BasePart") and d.Name == "Bulb" then
			table.insert(lamp.Bulbs, d)
		end
	end
	if #lamp.Lights == 0 and #lamp.Bulbs == 0 then
		return
	end
	lampOf[root] = lamp
	table.insert(lamps, lamp)
end

local function removeLamp(root: Instance)
	local lamp = lampOf[root]
	if not lamp then
		return
	end
	lampOf[root] = nil
	local i = table.find(lamps, lamp)
	if i then
		table.remove(lamps, i)
	end
end

local function setLevel(lamp: Lamp, level: number)
	if math.abs(level - lamp.Level) < 0.02 then
		return
	end
	lamp.Level = level
	for _, e in lamp.Lights do
		e.L.Brightness = e.Base * level
	end
	for _, b in lamp.Bulbs do
		b.LocalTransparencyModifier = if level < 0.45 then 0.75 else 0
	end
end

function EffectsController:FlickerLamps(seconds: number)
	burstUntil = math.max(burstUntil, os.clock() + seconds)
end

local function stepLamps(now: number)
	local cam = workspace.CurrentCamera
	if not cam or #lamps == 0 then
		return
	end
	local camPos = cam.CFrame.Position
	if now < burstUntil then
		local n = 0
		for _, lamp in lamps do
			if (lamp.Pos - camPos).Magnitude < LAMP_RANGE then
				if math.random() < 0.35 then
					setLevel(lamp, if math.random() < 0.5 then 0.05 else 0.4 + math.random() * 0.8)
				end
				burstDirty[lamp] = true
				n += 1
				if n > 40 then
					break
				end
			end
		end
		return
	end
	if next(burstDirty) then
		for lamp in burstDirty do
			setLevel(lamp, 1)
		end
		table.clear(burstDirty)
	end
	-- A few flickery lamps per frame, round robin.
	local count = #lamps
	for _ = 1, math.min(LAMPS_PER_FRAME, count) do
		rr = rr % count + 1
		local lamp = lamps[rr]
		if lamp.Root:GetAttribute("Flickery") == true and (lamp.Pos - camPos).Magnitude < LAMP_RANGE then
			if now > lamp.NextDip then
				lamp.NextDip = now + 0.15 + math.random() * 2.2
				lamp.DipUntil = now + 0.04 + math.random() * 0.16
				lamp.DipLevel = if math.random() < 0.35 then 0.05 else 0.25 + math.random() * 0.4
			end
			setLevel(lamp, if now < lamp.DipUntil then lamp.DipLevel else 1)
		elseif lamp.Level ~= 1 then
			setLevel(lamp, 1)
		end
	end
end

-- ------------------------------------------------------------------ (d) stirring

local stirT0 = -99

local function onGrandmaState()
	local state = matchState and matchState:GetAttribute("GrandmaState")
	if state == "Stirring" then
		stirT0 = os.clock()
		if camCtl then
			camCtl:Punch(-4, 1.1)
		end
		if music then
			music:SetHeartbeat("Stir", 0.55)
			task.delay(3, function()
				music:SetHeartbeat("Stir", 0)
			end)
		end
		shared("Sfx").Play("Gasp")
	elseif state == "Waking" then
		EffectsController:FlickerLamps(1.3)
		if camCtl then
			camCtl:Shake(0.35, 0.4)
		end
		if music then
			music:SetHeartbeat("Stir", 0)
		end
	elseif state == "Chasing" then
		EffectsController:FlickerLamps(0.9)
	end
end

local function stepStir(now: number)
	local x = now - stirT0
	local a = 0
	if x < 3.4 then
		local rise = math.clamp(x / 0.35, 0, 1)
		local fall = if x > 1.6 then 1 - (x - 1.6) / 1.8 else 1
		local breath = 0.75 + 0.25 * math.sin(x * 4.2)
		a = 0.55 * rise * math.max(0, fall) * breath
	end
	EffectsController:SetVignette("Dark", "Stir", a)
end

-- ------------------------------------------------------------------ lifecycle

function EffectsController.Preload() end

function EffectsController:Start()
	if not PlaceRole.IsMatch then
		return
	end
	settings = shared("ClientSettings")
	camCtl = shared("CameraController")
	music = shared("MusicController")

	local gui = ScreenFx.Gui("GameplayFx", -5)
	makeLayers(gui)

	local f = Instance.new("Folder")
	f.Name = "DWG_WorldFx"
	f.Parent = workspace.CurrentCamera
	fxFolder = f
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if fxFolder and workspace.CurrentCamera then
			fxFolder.Parent = workspace.CurrentCamera
		end
	end)
	local mf = Instance.new("Folder")
	mf.Name = "NoiseMarkers"
	mf.Parent = player:WaitForChild("PlayerGui")
	markerFolder = mf

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "DWG_ChaseGrade"
	cc.Enabled = false
	cc.Parent = Lighting
	grade = cc

	-- Lamps
	CollectionService:GetInstanceAddedSignal("Lamp"):Connect(function(i)
		task.defer(addLamp, i)
	end)
	CollectionService:GetInstanceRemovedSignal("Lamp"):Connect(removeLamp)
	for _, i in CollectionService:GetTagged("Lamp") do
		addLamp(i)
	end

	local Net = shared("Net")
	Net.Unreliable("Noise").OnClientEvent:Connect(onNoise)

	matchState = ReplicatedStorage:WaitForChild("MatchState", 30)
	if matchState then
		matchState:GetAttributeChangedSignal("GrandmaState"):Connect(onGrandmaState)
	end

	task.spawn(function()
		while true do
			task.wait(0.1)
			evalChase()
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		stepChase(dt)
		stepStir(now)
		stepLayers(now)
		stepMarkers(now)
		stepLamps(now)
	end)
end

return EffectsController
