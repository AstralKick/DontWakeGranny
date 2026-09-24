--!strict
-- PlayerStateService (Match)
-- Server-authoritative movement state: sprint / crouch / stamina / flashlight battery,
-- the pillowcase on your back, spawn protection, and "lurking outside" detection.
-- Clients only send intent (SetSprint, SetCrouch, ToggleFlashlight); speeds are set here.

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")

local PlaceRole = shared("PlaceRole")
local GameConfig = shared("GameConfig")
local EconomyConfig = shared("EconomyConfig")
local DataService = shared("DataService")
local Net = shared("Net")
local Notify = shared("Notify")

local function svc(name: string): any
	return shared(name)
end

local PlayerStateService = {}

local SetSprint = Net.Event("SetSprint")
local SetCrouch = Net.Event("SetCrouch")
local ToggleFlashlight = Net.Event("ToggleFlashlight")

local MOVE = GameConfig.Movement
local CG = GameConfig.CollisionGroups

type PState = {
	WantsSprint: boolean,
	Crouch: boolean,
	Stamina: number,
	MaxStamina: number,
	LastSprint: number,
	Battery: number,
	MaxBattery: number,
	FlashOn: boolean,
	TurboUntil: number,
	ProtectedUntil: number,
	OutsideSince: number?,
	EnteredTonight: boolean?,
	LastLoiterPing: number,
	Sack: BasePart?,
	Light: SpotLight?,
}

local states: { [Player]: PState } = {}

local roomParts: { BasePart } = {}

-- ------------------------------------------------------------------ collision groups

local function setupCollisionGroups()
	for _, g in { CG.Players, CG.Grandma, CG.Doors, CG.Loot } do
		pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, g)
	end
	PhysicsService:CollisionGroupSetCollidable(CG.Players, CG.Players, false)
	PhysicsService:CollisionGroupSetCollidable(CG.Players, CG.Grandma, false)
	PhysicsService:CollisionGroupSetCollidable(CG.Grandma, CG.Doors, false)
	PhysicsService:CollisionGroupSetCollidable(CG.Loot, CG.Players, false)
	PhysicsService:CollisionGroupSetCollidable(CG.Loot, CG.Grandma, false)
end

-- ------------------------------------------------------------------ helpers

function PlayerStateService:IsInside(pos: Vector3): boolean
	for _, part in roomParts do
		local rel = part.CFrame:PointToObjectSpace(pos)
		local half = part.Size / 2
		if math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y + 2 and math.abs(rel.Z) <= half.Z then
			return true
		end
	end
	return false
end

function PlayerStateService:RoomAt(pos: Vector3): BasePart?
	for _, part in roomParts do
		local rel = part.CFrame:PointToObjectSpace(pos)
		local half = part.Size / 2
		if math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y + 2 and math.abs(rel.Z) <= half.Z then
			return part
		end
	end
	return nil
end

function PlayerStateService:IsCrouching(p: Player): boolean
	local s = states[p]
	return s ~= nil and s.Crouch
end

function PlayerStateService:IsSprinting(p: Player): boolean
	return p:GetAttribute("Sprinting") == true
end

function PlayerStateService:IsFlashlightOn(p: Player): boolean
	local s = states[p]
	return s ~= nil and s.FlashOn
end

function PlayerStateService:IsProtected(p: Player): boolean
	local s = states[p]
	return s ~= nil and os.clock() < s.ProtectedUntil
end

function PlayerStateService:GrantProtection(p: Player, seconds: number)
	local s = states[p]
	if s then
		s.ProtectedUntil = os.clock() + seconds
		p:SetAttribute("Protected", true)
		task.delay(seconds, function()
			if states[p] and os.clock() >= states[p].ProtectedUntil then
				p:SetAttribute("Protected", false)
			end
		end)
	end
end

function PlayerStateService:Turbo(p: Player, seconds: number)
	local s = states[p]
	if s then
		s.Stamina = s.MaxStamina
		s.TurboUntil = os.clock() + seconds
	end
end

function PlayerStateService:ForceFlashlight(p: Player, on: boolean)
	local s = states[p]
	if s then
		s.FlashOn = on and s.Battery > 0
		p:SetAttribute("Flashlight", s.FlashOn)
		if s.Light then
			s.Light.Enabled = s.FlashOn
		end
	end
end

-- Sack grows with how much you carry — everyone can see who's loaded.
function PlayerStateService:UpdateSack(p: Player)
	local s = states[p]
	if not s or not s.Sack then
		return
	end
	local used = p:GetAttribute("CarrySlots") or 0
	local max = p:GetAttribute("MaxSlots") or 5
	local t = math.clamp(used / math.max(1, max), 0, 1)
	s.Sack.Size = Vector3.new(1.2 + t * 0.9, 1.3 + t * 1.1, 0.7 + t * 0.6)
	s.Sack.Transparency = if used == 0 then 0.35 else 0
end

local function buildSack(p: Player, char: Model): BasePart?
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not torso or not torso:IsA("BasePart") then
		return nil
	end
	local sack = Instance.new("Part")
	sack.Name = "Pillowcase"
	sack.Shape = Enum.PartType.Ball
	sack.Material = Enum.Material.Fabric
	sack.Color = p:GetAttribute("SackColor") or Color3.fromRGB(236, 226, 206)
	sack.Size = Vector3.new(1.2, 1.3, 0.7)
	sack.CanCollide = false
	sack.CanQuery = false
	sack.CanTouch = false
	sack.Massless = true
	sack.CastShadow = false
	sack.CollisionGroup = CG.Players
	local weld = Instance.new("Weld")
	weld.Part0 = torso
	weld.Part1 = sack
	weld.C0 = CFrame.new(0, 0.2, 0.9)
	weld.Parent = sack
	sack.Parent = char
	return sack
end

local function buildLight(p: Player, char: Model): SpotLight?
	local head = char:FindFirstChild("Head")
	if not head then
		return nil
	end
	local att = Instance.new("Attachment")
	att.Name = "FlashlightAttachment"
	att.Position = Vector3.new(0, 0, -0.6)
	att.Parent = head
	local light = Instance.new("SpotLight")
	light.Name = "Flashlight"
	light.Angle = 55
	light.Range = 34
	light.Brightness = 2.2
	light.Shadows = true
	light.Face = Enum.NormalId.Front
	light.Color = p:GetAttribute("FlashlightColor") or Color3.fromRGB(255, 226, 170)
	light.Enabled = false
	light.Parent = att
	return light
end

local function onCharacter(p: Player, char: Model)
	local s = states[p]
	if not s then
		return
	end
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum then
		return
	end
	hum.WalkSpeed = MOVE.WalkSpeed
	hum.JumpHeight = 0
	hum.JumpPower = 0
	hum.UseJumpPower = false
	hum.BreakJointsOnDeath = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	for _, d in char:GetDescendants() do
		if d:IsA("BasePart") then
			d.CollisionGroup = CG.Players
		end
	end
	char.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			d.CollisionGroup = CG.Players
		end
	end)
	CollectionService:AddTag(char, "PlayerCharacter")

	s.Crouch = false
	s.WantsSprint = false
	s.Stamina = s.MaxStamina
	s.FlashOn = false
	s.Battery = s.MaxBattery -- fresh batteries every night
	s.OutsideSince = nil
	s.EnteredTonight = false
	p:SetAttribute("Crouching", false)
	p:SetAttribute("Sprinting", false)
	p:SetAttribute("Flashlight", false)
	p:SetAttribute("Hidden", false)
	s.Sack = buildSack(p, char)
	s.Light = buildLight(p, char)
	-- The house is dark while Grandma sleeps: everyone arrives with their flashlight ON (F / Y / LIGHT toggles it).
	PlayerStateService:ForceFlashlight(p, true)
	PlayerStateService:UpdateSack(p)

	hum.Died:Connect(function()
		-- Falling out of the world / resetting counts as getting caught.
		svc("MatchService"):CatchPlayer(p, "Fell")
	end)
end

local function initPlayer(p: Player)
	if not DataService:WaitForData(p, 20) then
		return
	end
	local upgrades = DataService:Get(p, "Upgrades") or {}
	local lungs = (upgrades.StrongLungs or 0) * EconomyConfig.Upgrades.StrongLungs.PerLevel
	local battery = EconomyConfig.FlashlightBattery * (1 + (upgrades.Batteries or 0) * EconomyConfig.Upgrades.Batteries.PerLevel)
	states[p] = {
		WantsSprint = false,
		Crouch = false,
		Stamina = MOVE.StaminaMax + lungs,
		MaxStamina = MOVE.StaminaMax + lungs,
		LastSprint = 0,
		Battery = battery,
		MaxBattery = battery,
		FlashOn = false,
		TurboUntil = 0,
		ProtectedUntil = 0,
		OutsideSince = nil,
		LastLoiterPing = 0,
		Sack = nil,
		Light = nil,
	}
	p:SetAttribute("MaxStamina", MOVE.StaminaMax + lungs)
	p:SetAttribute("MaxBattery", battery)
	p:SetAttribute("SoftSocks", upgrades.SoftSocks or 0)
	p.CharacterAdded:Connect(function(c)
		onCharacter(p, c)
	end)
	if p.Character then
		onCharacter(p, p.Character)
	end
	-- Cosmetics may change in the lobby only, but keep the light tint in sync anyway.
	p:GetAttributeChangedSignal("FlashlightColor"):Connect(function()
		local st = states[p]
		if st and st.Light then
			st.Light.Color = p:GetAttribute("FlashlightColor")
		end
	end)
end

-- ------------------------------------------------------------------ tick

local TICK = 0.1

local function tick()
	local now = os.clock()
	local match = svc("MatchService")
	local phase = match:GetPhase()
	local loot = svc("LootService")

	for p, s in states do
		local char = p.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hum or not root or hum.Health <= 0 then
			continue
		end

		local moving = hum.MoveDirection.Magnitude > 0.1
		local turbo = now < s.TurboUntil
		local canSprint = s.WantsSprint and not s.Crouch and moving and (turbo or s.Stamina > (if p:GetAttribute("Sprinting") then 0 else MOVE.StaminaMinToSprint))
		local sprinting = canSprint and p:GetAttribute("Hidden") ~= true

		if sprinting and not turbo then
			s.Stamina = math.max(0, s.Stamina - MOVE.StaminaDrain * TICK)
			s.LastSprint = now
		elseif now - s.LastSprint > MOVE.StaminaRegenDelay then
			s.Stamina = math.min(s.MaxStamina, s.Stamina + MOVE.StaminaRegen * TICK)
		end

		local speed = if s.Crouch then MOVE.CrouchSpeed elseif sprinting then MOVE.SprintSpeed else MOVE.WalkSpeed
		if loot:IsCarryingHeavy(p) then
			speed -= MOVE.HeavySpeedPenalty
		end
		if turbo then
			speed *= 1.2
		end
		if p:GetAttribute("Hidden") or phase == "Intro" then -- frozen while the night intro plays
			speed = 0
		end
		if math.abs(hum.WalkSpeed - speed) > 0.05 then
			hum.WalkSpeed = speed
		end

		if p:GetAttribute("Sprinting") ~= sprinting then
			p:SetAttribute("Sprinting", sprinting)
		end
		p:SetAttribute("Stamina", math.floor(s.Stamina))

		-- Flashlight battery
		if s.FlashOn then
			s.Battery = math.max(0, s.Battery - TICK)
			if s.Battery <= 0 then
				PlayerStateService:ForceFlashlight(p, false)
			end
		else
			s.Battery = math.min(s.MaxBattery, s.Battery + EconomyConfig.FlashlightRecharge * TICK)
		end
		p:SetAttribute("Battery", math.floor(s.Battery))

		-- Lurking outside during the night makes Grandma come looking.
		if phase == "Night" and match:IsAlive(p) and not match:GetNightConfig().Finale then
			local inside = PlayerStateService:IsInside(root.Position)
			-- Fair to newcomers: the timer only runs once you've been inside tonight (or the
			-- night is well under way), and the first nights are more forgiving.
			local sinceStart = workspace:GetServerTimeNow() - (match:GetNightStart() or 0)
			local grace = GameConfig.Loiter.GraceSeconds + (if match:GetNight() <= 2 then 15 else 0)
			if inside then
				s.OutsideSince = nil
				s.EnteredTonight = true
			elseif s.EnteredTonight or sinceStart > 45 then
				s.OutsideSince = s.OutsideSince or now
				local outFor = now - (s.OutsideSince :: number)
				if outFor > grace and now - s.LastLoiterPing > 6 then
					s.LastLoiterPing = now
					Notify.Toast(p, "Grandma senses you lurking outside...", "Bad")
					svc("NoiseService"):Emit(root.Position, GameConfig.Loiter.Loudness, 400, p, "Lurking")
				elseif outFor > grace - 5 and outFor < grace - 4.9 then
					Notify.Toast(p, "Don't stay out too long... she can tell.", "Info")
				end
			end
		else
			s.OutsideSince = nil
		end
	end
end

-- ------------------------------------------------------------------ lifecycle

function PlayerStateService.Preload() end

function PlayerStateService:Start()
	if not PlaceRole.IsMatch then
		return
	end
	setupCollisionGroups()

	local house = workspace:WaitForChild("House", 15)
	local rooms = house and house:FindFirstChild("Rooms")
	if rooms then
		for _, r in rooms:GetChildren() do
			if r:IsA("BasePart") then
				table.insert(roomParts, r)
			end
		end
	end

	SetSprint.OnServerEvent:Connect(function(p, on)
		local s = states[p]
		if s and typeof(on) == "boolean" and Net.RateLimit(p, "Sprint", 12) then
			s.WantsSprint = on
		end
	end)
	SetCrouch.OnServerEvent:Connect(function(p, on)
		local s = states[p]
		if s and typeof(on) == "boolean" and Net.RateLimit(p, "Crouch", 8) then
			s.Crouch = on
			p:SetAttribute("Crouching", on)
		end
	end)
	ToggleFlashlight.OnServerEvent:Connect(function(p)
		local s = states[p]
		if s and Net.RateLimit(p, "Flashlight", 5) then
			PlayerStateService:ForceFlashlight(p, not s.FlashOn)
		end
	end)

	Players.PlayerAdded:Connect(initPlayer)
	for _, p in Players:GetPlayers() do
		task.spawn(initPlayer, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		states[p] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(TICK)
			debug.profilebegin("PlayerStateTick")
			local ok, err = pcall(tick)
			debug.profileend()
			if not ok then
				warn("[PlayerState]", err)
			end
		end
	end)
end

return PlayerStateService
