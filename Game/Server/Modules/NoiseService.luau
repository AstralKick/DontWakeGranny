--!strict
-- NoiseService (Match)
-- The signature mechanic. Every sound a player makes becomes a noise event:
--   NoiseService:Emit(position, loudness 0-100, radius studs, sourcePlayer?, kind)
-- Grandma hears it (GrandmaService:HearNoise) and clients get a ripple + "!" over the
-- noisy player's head so the whole team knows exactly who messed up.
--
-- Built-in sources: footsteps (sprinting), creaky floorboards (tag "Creaky"),
-- breakables (tag "Breakable"). Other services Emit for doors, drawers, loot, items.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local PlaceRole = shared("PlaceRole")
local EconomyConfig = shared("EconomyConfig")
local Net = shared("Net")
local Sfx = shared("Sfx")

local function svc(name: string): any
	return shared(name)
end

local NoiseService = {}

local NoiseEvent = Net.Unreliable("Noise") -- (pos, loudness, radius, sourceUserId, kind)

-- Footstep tuning
local STEP_INTERVAL = 0.3
local SPRINT_LOUDNESS = 15
local SPRINT_RADIUS = 50
local WALK_LOUDNESS = 4 -- walking right next to her adds up; crouching is still silent
local WALK_RADIUS = 16
local HEAVY_MULT = 1.35

-- Crouching over a creaky board is the safe way past her (nearly silent); walking creaks, sprinting SCREAMS.
local CREAK = { Crouch = 1.2, Walk = 18, Sprint = 34, Radius = 60, Cooldown = 1.1 }
local BREAK = { Loudness = 85, Radius = 140, MinSpeed = 13.5 }

local creakCooldown: { [Player]: { [BasePart]: number } } = {}
local broken: { [Instance]: boolean } = {}

function NoiseService:Emit(pos: Vector3, loudness: number, radius: number, source: Player?, kind: string?)
	local match = svc("MatchService")
	if match:GetPhase() ~= "Night" then
		return
	end
	svc("GrandmaService"):HearNoise(pos, loudness, radius, source, kind)
	if loudness >= 6 then
		NoiseEvent:FireAllClients(pos, loudness, radius, source and source.UserId or 0, kind or "")
	end
end

local function playerSpeedClass(p: Player): string
	if p:GetAttribute("Crouching") then
		return "Crouch"
	elseif p:GetAttribute("Sprinting") then
		return "Sprint"
	end
	return "Walk"
end

local function onCreak(board: BasePart, hit: BasePart)
	local char = hit.Parent
	local p = char and Players:GetPlayerFromCharacter(char)
	if not p or hit.Name ~= "HumanoidRootPart" and hit.Name ~= "LeftFoot" and hit.Name ~= "RightFoot" and hit.Name ~= "LowerTorso" then
		return
	end
	local root = (char :: Model):FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or root.AssemblyLinearVelocity.Magnitude < 2 then
		return
	end
	creakCooldown[p] = creakCooldown[p] or {}
	local now = os.clock()
	if (creakCooldown[p][board] or 0) > now then
		return
	end
	creakCooldown[p][board] = now + CREAK.Cooldown
	local class = playerSpeedClass(p)
	local loud = CREAK[class]
	Sfx.Play("FloorCreak", board, { Volume = if class == "Crouch" then 0.35 else 1, PlaybackSpeed = 0.9 + math.random() * 0.25 })
	NoiseService:Emit(board.Position, loud, CREAK.Radius, p, "Creak")
end

local function breakObject(obj: Instance, p: Player?)
	if broken[obj] then
		return
	end
	broken[obj] = true
	local parts: { BasePart } = {}
	if obj:IsA("BasePart") then
		table.insert(parts, obj)
	end
	for _, d in obj:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	local center = if obj:IsA("Model") then obj:GetPivot().Position else (obj :: BasePart).Position
	for _, part in parts do
		part:SetAttribute("OrigTransparency", part:GetAttribute("OrigTransparency") or part.Transparency)
		part.Transparency = 1
		part.CanCollide = false
		part.CanTouch = false
	end
	-- Shards
	local color = parts[1] and parts[1].Color or Color3.new(1, 1, 1)
	for _ = 1, 6 do
		local shard = Instance.new("Part")
		shard.Size = Vector3.new(0.3, 0.1, 0.25) * (0.6 + math.random())
		shard.Color = color
		shard.Material = Enum.Material.SmoothPlastic
		shard.CFrame = CFrame.new(center) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		shard.CanQuery = false
		shard.CollisionGroup = "Loot"
		shard.AssemblyLinearVelocity = Vector3.new(math.random(-12, 12), math.random(6, 14), math.random(-12, 12))
		shard.Parent = workspace
		Debris:AddItem(shard, 4)
	end
	Sfx.Play("Break", center)
	NoiseService:Emit(center, BREAK.Loudness, BREAK.Radius, p, "Break")
end

-- Restore breakables for a new night.
function NoiseService:ResetBreakables()
	for obj in broken do
		local parts: { BasePart } = {}
		if obj:IsA("BasePart") then
			table.insert(parts, obj)
		end
		for _, d in obj:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(parts, d)
			end
		end
		for _, part in parts do
			part.Transparency = part:GetAttribute("OrigTransparency") or 0
			part.CanCollide = true
			part.CanTouch = true
		end
	end
	table.clear(broken)
end

local function hookBreakable(obj: Instance)
	local touchPart: BasePart? = if obj:IsA("BasePart") then obj elseif obj:IsA("Model") then obj.PrimaryPart else nil
	if not touchPart then
		return
	end
	touchPart.Touched:Connect(function(hit)
		local p = Players:GetPlayerFromCharacter(hit.Parent)
		if not p or broken[obj] then
			return
		end
		local root = (hit.Parent :: Model):FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and root.AssemblyLinearVelocity.Magnitude >= BREAK.MinSpeed then
			breakObject(obj, p)
		end
	end)
end

local function footstepLoop()
	local match = svc("MatchService")
	local loot = svc("LootService")
	while true do
		task.wait(STEP_INTERVAL)
		if match:GetPhase() ~= "Night" then
			continue
		end
		for _, p in match:GetAlivePlayers() do
			local char = p.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if not root or not hum or hum.MoveDirection.Magnitude < 0.1 or p:GetAttribute("Hidden") then
				continue
			end
			local class = playerSpeedClass(p)
			local heavy = loot:IsCarryingHeavy(p)
			if class == "Sprint" then
				local socks = (p:GetAttribute("SoftSocks") or 0) * EconomyConfig.Upgrades.SoftSocks.PerLevel
				local loud = SPRINT_LOUDNESS * (1 - socks) * (if heavy then HEAVY_MULT else 1)
				NoiseService:Emit(root.Position, loud, SPRINT_RADIUS, p, "Run")
			elseif class == "Walk" then
				local loud = WALK_LOUDNESS * (if heavy then 3 else 1)
				svc("GrandmaService"):HearNoise(root.Position, loud, WALK_RADIUS, p, "Walk")
			end
		end
	end
end

function NoiseService.Preload() end

function NoiseService:Start()
	if not PlaceRole.IsMatch then
		return
	end
	for _, board in CollectionService:GetTagged("Creaky") do
		if board:IsA("BasePart") then
			board.Touched:Connect(function(hit)
				onCreak(board, hit)
			end)
		end
	end
	for _, obj in CollectionService:GetTagged("Breakable") do
		hookBreakable(obj)
	end
	Players.PlayerRemoving:Connect(function(p)
		creakCooldown[p] = nil
	end)
	task.spawn(footstepLoop)
end

return NoiseService
