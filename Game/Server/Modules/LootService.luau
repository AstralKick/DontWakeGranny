--!strict
-- LootService (Match)
-- Loot spawning, searching containers, carrying (pillowcase slots), banking at Mom's car
-- trunk, and what happens to your loot when Grandma catches you.
--
-- Risk/reward: spawn points carry a Danger 1..3 which picks the item tier. Prizes sit in
-- Danger-3 PrizeSpawns. Banking converts carried loot to Candy immediately (safe forever).
-- Getting caught loses it all — but you drop your pillowcase, and a brave teammate can
-- grab it (the caught player still loses everything; the teammate gains it).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local PlaceRole = shared("PlaceRole")
local GameConfig = shared("GameConfig")
local LootConfig = shared("LootConfig")
local EconomyConfig = shared("EconomyConfig")
local MonetizationConfig = shared("MonetizationConfig")
local DataService = shared("DataService")
local Net = shared("Net")
local Notify = shared("Notify")
local Sfx = shared("Sfx")

local function svc(name: string): any
	return shared(name)
end

local LootService = {}

local LootPicked = Net.Event("LootPicked") -- -> picker: (name, baseValue, isPrize)
local Banked = Net.Event("Banked") -- -> banker: (candy, count, reason)
local SearchResult = Net.Event("SearchResult") -- -> searcher: (foundName?)

type Item = { Key: string, Name: string, Value: number, Slots: number, Heavy: boolean, Prize: boolean }

local carry: { [Player]: { Item } } = {}
local active: Folder
local house: Instance?
local lootSpawns: { BasePart } = {}
local prizeSpawns: { BasePart } = {}
local searchables: { BasePart } = {}
local trunk: BasePart?
local cfg: any = nil
local prizeKey: string? = nil
local prizeSpawnPart: BasePart? = nil
local rng = Random.new()

-- ------------------------------------------------------------------ helpers

local function matchState(key: string, value: any)
	local ms = ReplicatedStorage:FindFirstChild("MatchState")
	if ms then
		ms:SetAttribute(key, value)
	end
end

local function areaOpen(part: Instance): boolean
	local area = part:GetAttribute("Area")
	return not cfg or not area or cfg.Areas[area] == true
end

function LootService:MaxSlots(p: Player): number
	local upgrades = DataService:Get(p, "Upgrades") or {}
	local slots = GameConfig.Inventory.BaseSlots + (upgrades.Pillowcase or 0) * EconomyConfig.Upgrades.Pillowcase.PerLevel
	if svc("MonetizationService"):HasPass(p, "BigPillowcase") then
		slots += MonetizationConfig.Passes.BigPillowcase.Slots
	end
	return slots
end

local function usedSlots(p: Player): number
	local n = 0
	for _, it in carry[p] or {} do
		n += it.Slots
	end
	return n
end

function LootService:IsCarryingHeavy(p: Player): boolean
	for _, it in carry[p] or {} do
		if it.Heavy then
			return true
		end
	end
	return false
end

-- Candy multiplier applied when banking.
function LootService:ValueMult(p: Player): number
	local m = (cfg and cfg.LootMult or 1) * svc("EventService"):LootMult()
	if svc("MatchService"):IsSugarRush() then
		m *= MonetizationConfig.SugarRush.LootMult
	end
	local rewards = svc("RewardsService")
	m *= rewards:FriendMultiplier(rewards:CountFriendsIn(p))
	if svc("MonetizationService"):HasPass(p, "VIP") then
		m *= 1 + EconomyConfig.VIPCandyMult
	end
	return m
end

local function refreshAttrs(p: Player)
	local list = carry[p] or {}
	local base = 0
	local names = {}
	for _, it in list do
		base += it.Value
		table.insert(names, it.Name)
	end
	p:SetAttribute("CarryValue", math.floor(base * LootService:ValueMult(p)))
	p:SetAttribute("CarrySlots", usedSlots(p))
	p:SetAttribute("MaxSlots", LootService:MaxSlots(p))
	p:SetAttribute("CarryList", HttpService:JSONEncode(names))
	p:SetAttribute("CarryingPrize", (function()
		for _, it in list do
			if it.Prize then
				return true
			end
		end
		return false
	end)())
	svc("PlayerStateService"):UpdateSack(p)
end

local function buildVisual(spec: { any }, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	local primary: BasePart? = nil
	for _, s in spec do
		local shape, size, color, material, offset = s[1], s[2], s[3], s[4], s[5]
		local part = Instance.new("Part")
		part.Shape = if shape == "Ball" then Enum.PartType.Ball elseif shape == "Cyl" then Enum.PartType.Cylinder else Enum.PartType.Block
		part.Size = size
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = true
		part.CastShadow = false
		part.CollisionGroup = GameConfig.CollisionGroups.Loot
		part.CFrame = CFrame.new(offset or Vector3.zero) * (if shape == "Cyl" then CFrame.Angles(0, 0, math.rad(90)) else CFrame.identity)
		part.Parent = model
		if not primary then
			primary = part
		end
	end
	model.PrimaryPart = primary
	return model
end

-- ProximityPrompts only appear while their anchor is on screen. In first person, things on
-- the floor or in bottom drawers fall below the view when you stand next to them, so hang
-- every prompt on an Attachment raised to at least `minAboveGround` studs above the floor.
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
local function promptAnchor(part: BasePart, minAboveGround: number, ignore: Instance?): Attachment
	groundParams.FilterDescendantsInstances = { ignore or part }
	local ground = workspace:Raycast(part.Position + Vector3.new(0, 0.5, 0), Vector3.new(0, -14, 0), groundParams)
	local groundY = if ground then ground.Position.Y else part.Position.Y - 1
	local att = Instance.new("Attachment")
	att.Name = "PromptAnchor"
	att.Parent = part
	att.WorldPosition = Vector3.new(part.Position.X, math.max(part.Position.Y, groundY + minAboveGround), part.Position.Z)
	return att
end

local function glint(model: Model, color: Color3, rate: number)
	local p = model.PrimaryPart
	if not p then
		return
	end
	local att = Instance.new("Attachment")
	att.Parent = p
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Rate = rate
	pe.Lifetime = NumberRange.new(0.5, 0.9)
	pe.Speed = NumberRange.new(0)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 0) })
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(color)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Parent = att
end

local function weightedPick(pool: { string }, defs: { [string]: any }): string?
	local total = 0
	for _, k in pool do
		total += defs[k].Weight or 1
	end
	if total <= 0 then
		return nil
	end
	local r = rng:NextNumber() * total
	for _, k in pool do
		r -= defs[k].Weight or 1
		if r <= 0 then
			return k
		end
	end
	return pool[#pool]
end

local function itemForDanger(danger: number): string?
	-- Mostly the room's tier, sometimes one tier better (keeps the house surprising).
	local tier = danger
	if rng:NextNumber() < 0.12 then
		tier = math.min(3, danger + 1)
	end
	local pool = {}
	for k, def in LootConfig.Items do
		if def.Tier == tier then
			table.insert(pool, k)
		end
	end
	return weightedPick(pool, LootConfig.Items)
end

-- ------------------------------------------------------------------ carrying

local function tryAdd(p: Player, item: Item): boolean
	local list = carry[p]
	if not list then
		return false
	end
	if usedSlots(p) + item.Slots > LootService:MaxSlots(p) then
		Notify.Toast(p, "Your pillowcase is full! Stash it in Mom's trunk.", "Bad")
		return false
	end
	table.insert(list, item)
	refreshAttrs(p)
	return true
end

local function makeItem(key: string, isPrize: boolean): Item
	local def = if isPrize then LootConfig.Prizes[key] else LootConfig.Items[key]
	return { Key = key, Name = def.Name, Value = def.Value, Slots = def.Slots or 1, Heavy = def.Heavy == true, Prize = isPrize }
end

local function validPicker(p: Player, part: BasePart?, maxDist: number): boolean
	local match = svc("MatchService")
	if match:GetPhase() ~= "Night" or not match:IsAlive(p) or p:GetAttribute("Hidden") then
		return false
	end
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and (part == nil or (root.Position - part.Position).Magnitude <= maxDist)
end

-- Spawns a pickup model at cf with a Steal prompt.
local function spawnPickup(key: string, isPrize: boolean, cf: CFrame, spawnPart: BasePart?): Model
	local def = if isPrize then LootConfig.Prizes[key] else LootConfig.Items[key]
	local model = buildVisual(def.Visual, def.Name)
	model:PivotTo(cf * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0))
	model:SetAttribute("LootKey", key)
	model:SetAttribute("Prize", isPrize)
	model.Parent = active
	if isPrize then
		glint(model, Color3.fromRGB(255, 214, 110), 6)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 200, 120)
		light.Range = 7
		light.Brightness = 0.8
		light.Shadows = false
		light.Parent = model.PrimaryPart
	else
		glint(model, Color3.fromRGB(255, 240, 200), if def.Tier == 3 then 2 else 0.6)
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = if isPrize then "Steal the Prize" else "Steal"
	prompt.ObjectText = `{def.Name}  ·  {def.Value} 🍬`
	prompt.HoldDuration = if isPrize then 1.1 else 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false -- multi-part loot models would block their own sight line
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt:SetAttribute("Kind", if isPrize then "Prize" else "Loot")
	-- Right over the item (it glints, players look at it); just a hair above so it doesn't clip.
	local over = Instance.new("Attachment")
	over.Name = "PromptAnchor"
	over.Parent = model.PrimaryPart
	over.WorldPosition = (model.PrimaryPart :: BasePart).Position + Vector3.new(0, 0.6, 0)
	prompt.Parent = over

	local taken = false
	prompt.Triggered:Connect(function(p)
		if taken or not validPicker(p, model.PrimaryPart, 11) then
			return
		end
		local item = makeItem(key, isPrize)
		if not tryAdd(p, item) then
			return
		end
		taken = true
		local pos = (model.PrimaryPart :: BasePart).Position
		model:Destroy()
		Sfx.Play("Pickup", pos)
		svc("NoiseService"):Emit(pos, def.Noise * 2.4 * (cfg and cfg.PickupNoiseMult or 1), LootConfig.PickupNoiseRadius, p, "Pickup")
		LootPicked:FireClient(p, def.Name, def.Value, isPrize)
		DataService:IncStat(p, "LootStolen")
		if (DataService:Get(p, "HighestNight") or 0) == 0 then
			shared("Analytics").Onboarding(p, "FirstLoot")
		end
		if isPrize then
			matchState("PrizeState", "Carried")
			matchState("PrizeHolder", p.DisplayName)
			Notify.Toast("all", `{p.DisplayName} grabbed {def.Name}! Get it to the car!`, "Candy")
		end
	end)
	return model
end

-- ------------------------------------------------------------------ banking

function LootService:BankAll(p: Player, reason: string): number
	local list = carry[p]
	if not list or #list == 0 then
		return 0
	end
	local base = 0
	local prizes = 0
	for _, it in list do
		base += it.Value
		if it.Prize then
			prizes += 1
		end
	end
	local candy = math.floor(base * LootService:ValueMult(p))
	local count = #list
	carry[p] = {}
	refreshAttrs(p)

	DataService:AddCandy(p, candy)
	svc("MatchService"):RecordBank(p, candy)
	DataService:SetStatMax(p, "BiggestHaul", candy)
	svc("RewardsService"):QuestProgress(p, "BankCandy", candy)
	if prizes > 0 then
		DataService:IncStat(p, "PrizesBanked", prizes)
		svc("RewardsService"):QuestProgress(p, "StealPrize", prizes)
		matchState("PrizeState", "Banked")
		Notify.Banner("all", "PRIZE STOLEN!", `{p.DisplayName} got it out.`, Color3.fromRGB(224, 176, 79))
	end
	svc("RewardsService"):CheckAchievements(p)
	Banked:FireClient(p, candy, count, reason)
	return candy
end

-- ------------------------------------------------------------------ getting caught

-- Returns (candyValueLost, itemCount). Drops a grabbable pillowcase for teammates.
function LootService:OnCaught(p: Player): (number, number)
	local list = carry[p]
	if not list or #list == 0 then
		return 0, 0
	end
	local lostValue = math.floor(LootService:ValueMult(p) * (function()
		local s = 0
		for _, it in list do
			s += it.Value
		end
		return s
	end)())
	local count = #list
	carry[p] = {}
	refreshAttrs(p)

	-- Prizes go back where Grandma keeps them.
	local keep: { Item } = {}
	for _, it in list do
		if it.Prize then
			if prizeSpawnPart and prizeKey then
				spawnPickup(prizeKey, true, prizeSpawnPart.CFrame, prizeSpawnPart)
				matchState("PrizeState", "Hidden")
				matchState("PrizeHolder", "")
			end
		else
			table.insert(keep, it)
		end
	end

	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if #keep > 0 and root and svc("MatchService"):GetPhase() == "Night" then
		local bag = Instance.new("Part")
		bag.Name = "LostPillowcase"
		bag.Shape = Enum.PartType.Ball
		bag.Size = Vector3.new(2.2, 1.6, 1.6)
		bag.Material = Enum.Material.Fabric
		bag.Color = p:GetAttribute("SackColor") or Color3.fromRGB(236, 226, 206)
		bag.Anchored = true
		bag.CanCollide = false
		bag.CanTouch = false
		bag.CollisionGroup = GameConfig.CollisionGroups.Loot
		local ray = workspace:Raycast(root.Position, Vector3.new(0, -12, 0))
		bag.CFrame = CFrame.new((if ray then ray.Position else root.Position - Vector3.new(0, 3, 0)) + Vector3.new(0, 0.8, 0))
		bag.Parent = active
		local bagModel = Instance.new("Model")
		bagModel.Name = "LostPillowcase"
		bagModel.Parent = active
		bag.Parent = bagModel
		bagModel.PrimaryPart = bag
		glint(bagModel, Color3.fromRGB(217, 122, 138), 3)

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Grab Pillowcase"
		prompt.ObjectText = `{p.DisplayName}'s loot`
		prompt.HoldDuration = 0.6
		prompt.MaxActivationDistance = 8
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt:SetAttribute("Kind", "Loot")
		prompt.Parent = promptAnchor(bag, 1.2, bagModel)
		prompt.Triggered:Connect(function(grabber)
			if not validPicker(grabber, bag, 11) then
				return
			end
			local took = 0
			for i = #keep, 1, -1 do
				if tryAdd(grabber, keep[i]) then
					table.remove(keep, i)
					took += 1
				end
			end
			if took > 0 then
				Sfx.Play("Pickup", bag.Position)
				LootPicked:FireClient(grabber, `{p.DisplayName}'s pillowcase`, 0, false)
			end
			if #keep == 0 then
				bagModel:Destroy()
			end
		end)
		Debris:AddItem(bagModel, 60)
	end
	return lostValue, count
end

-- ------------------------------------------------------------------ containers

local function hookSearchable(part: BasePart)
	local kind = part:GetAttribute("Kind") or "Drawer"
	local def = LootConfig.Containers[kind] or LootConfig.Containers.Drawer
	local prompt = part:FindFirstChild("SearchPrompt", true) :: ProximityPrompt?
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "SearchPrompt"
		prompt.Parent = promptAnchor(part, 1.4, part.Parent)
	end
	local pr = prompt :: ProximityPrompt
	pr.ActionText = def.Label
	pr.ObjectText = ""
	pr.HoldDuration = def.Hold
	pr.MaxActivationDistance = 7
	pr.RequiresLineOfSight = false
	pr.Style = Enum.ProximityPromptStyle.Custom
	pr:SetAttribute("Kind", "Search")
	pr.PromptButtonHoldBegan:Connect(function(p)
		if validPicker(p, part, 10) then
			Sfx.Play("DrawerSearch", part)
			svc("NoiseService"):Emit(part.Position, def.Noise * 0.5, 40, p, "Search")
		end
	end)
	pr.Triggered:Connect(function(p)
		if part:GetAttribute("Searched") or not validPicker(p, part, 10) or not areaOpen(part) then
			return
		end
		part:SetAttribute("Searched", true)
		pr.Enabled = false
		svc("NoiseService"):Emit(part.Position, def.Noise, 50, p, "Search")
		DataService:IncStat(p, "ContainersSearched")
		svc("RewardsService"):QuestProgress(p, "SearchContainers", 1)

		if rng:NextNumber() > def.Chance * (cfg and cfg.ContainerChanceMult or 1) then
			SearchResult:FireClient(p, nil)
			return
		end
		local danger = math.clamp((part:GetAttribute("Danger") or 1) + (def.TierBonus or 0), 1, 3)
		local key = itemForDanger(danger)
		if not key then
			SearchResult:FireClient(p, nil)
			return
		end
		local item = makeItem(key, false)
		if tryAdd(p, item) then
			LootPicked:FireClient(p, item.Name, item.Value, false)
			DataService:IncStat(p, "LootStolen")
			SearchResult:FireClient(p, item.Name)
		else
			-- No room: it tumbles out onto the floor in front of the container.
			local cf = part.CFrame * CFrame.new(0, 0, -2)
			local ray = workspace:Raycast(cf.Position, Vector3.new(0, -8, 0))
			spawnPickup(key, false, CFrame.new((if ray then ray.Position else cf.Position) + Vector3.new(0, 0.4, 0)))
			SearchResult:FireClient(p, item.Name)
		end
	end)
end

-- ------------------------------------------------------------------ night setup

function LootService:SpawnForNight(n: number, nightCfg: any)
	cfg = nightCfg
	active:ClearAllChildren()
	for p in carry do
		carry[p] = {}
		refreshAttrs(p)
	end

	-- Regular loot
	local party = svc("MatchService"):PartyScale()
	local count = math.floor(nightCfg.LootCount * (party and party.LootMult or 1) * svc("EventService"):LootCountMult())
	local open = {}
	for _, s in lootSpawns do
		if areaOpen(s) then
			table.insert(open, s)
		end
	end
	for i = #open, 2, -1 do
		local j = rng:NextInteger(1, i)
		open[i], open[j] = open[j], open[i]
	end
	-- Early nights guarantee some easy, visible loot by the entrance (first 15 seconds are fun);
	-- later nights stop handing it out (NightConfig.EasyLoot).
	table.sort(open, function(a, b)
		return (a:GetAttribute("Danger") or 1) < (b:GetAttribute("Danger") or 1)
	end)
	local firstEasy = math.min(nightCfg.EasyLoot or 4, #open, count)
	local chosen = {}
	for i = 1, firstEasy do
		table.insert(chosen, open[i])
	end
	local rest, risky = {}, {}
	for i = firstEasy + 1, #open do
		table.insert(rest, open[i])
		if (open[i]:GetAttribute("Danger") or 1) >= 2 then
			table.insert(risky, open[i])
		end
	end
	for _, list in { rest, risky } do
		for i = #list, 2, -1 do
			local j = rng:NextInteger(1, i)
			list[i], list[j] = list[j], list[i]
		end
	end
	-- DangerBias: the later the night, the more of the loot sits in the risky rooms.
	local used: { [BasePart]: boolean } = {}
	for _, s in chosen do
		used[s] = true
	end
	local ri, gi = 1, 1
	while #chosen < count and (gi <= #rest or ri <= #risky) do
		local pick: BasePart? = nil
		if rng:NextNumber() < (nightCfg.DangerBias or 0) then
			while ri <= #risky and used[risky[ri]] do
				ri += 1
			end
			pick = risky[ri]
		end
		if not pick then
			while gi <= #rest and used[rest[gi]] do
				gi += 1
			end
			pick = rest[gi]
		end
		if not pick then
			break
		end
		used[pick] = true
		table.insert(chosen, pick)
	end
	for _, s in chosen do
		local key = itemForDanger(s:GetAttribute("Danger") or 1)
		if key then
			spawnPickup(key, false, s.CFrame, s)
		end
	end

	-- Prize
	prizeKey = nil
	prizeSpawnPart = nil
	local prizePool = {}
	for k, def in LootConfig.Prizes do
		if (def.MinNight or 1) <= n then
			table.insert(prizePool, k)
		end
	end
	local openPrize = {}
	for _, s in prizeSpawns do
		if areaOpen(s) then
			table.insert(openPrize, s)
		end
	end
	if #prizePool > 0 and #openPrize > 0 and not nightCfg.Finale then
		prizeKey = prizePool[rng:NextInteger(1, #prizePool)]
		prizeSpawnPart = openPrize[rng:NextInteger(1, #openPrize)]
		spawnPickup(prizeKey :: string, true, (prizeSpawnPart :: BasePart).CFrame, prizeSpawnPart)
		matchState("PrizeName", LootConfig.Prizes[prizeKey :: string].Name)
		matchState("PrizeState", "Hidden")
		matchState("PrizeHolder", "")
	else
		matchState("PrizeName", "")
		matchState("PrizeState", "")
	end

	-- Diary page (lore collectible), in a riskier room
	if rng:NextNumber() < LootConfig.DiaryChance then
		local page = svc("RewardsService"):PickDiaryPage(n, svc("MatchService"):GetPlayers())
		local risky = {}
		for _, s in open do
			if (s:GetAttribute("Danger") or 1) >= 2 and not table.find(chosen, s) then
				table.insert(risky, s)
			end
		end
		if page and #risky > 0 then
			local s = risky[rng:NextInteger(1, #risky)]
			local paper = buildVisual({ { "Box", Vector3.new(1, 0.05, 1.3), Color3.fromRGB(243, 233, 210), Enum.Material.SmoothPlastic } }, "DiaryPage")
			paper:PivotTo(s.CFrame * CFrame.Angles(0, rng:NextNumber() * 6, 0))
			paper.Parent = active
			glint(paper, Color3.fromRGB(190, 214, 255), 1.5)
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Read"
			prompt.ObjectText = "A torn diary page"
			prompt.HoldDuration = 0.3
			prompt.MaxActivationDistance = 8
			prompt.Style = Enum.ProximityPromptStyle.Custom
			prompt:SetAttribute("Kind", "Diary")
			prompt.Parent = promptAnchor(paper.PrimaryPart :: BasePart, 0.6, paper)
			prompt.Triggered:Connect(function(p)
				if validPicker(p, paper.PrimaryPart, 11) then
					-- Everyone present who hasn't read it gets the page (lore is shared).
					for _, other in svc("MatchService"):GetPlayers() do
						svc("RewardsService"):GrantDiary(other, page)
					end
					paper:Destroy()
				end
			end)
		end
	end

	-- Containers
	for _, part in searchables do
		part:SetAttribute("Searched", false)
		local pr = part:FindFirstChild("SearchPrompt", true) :: ProximityPrompt?
		if pr then
			pr.Enabled = areaOpen(part)
		end
	end
end

-- ------------------------------------------------------------------ lifecycle

function LootService.Preload() end

function LootService:Start()
	if not PlaceRole.IsMatch then
		return
	end
	active = Instance.new("Folder")
	active.Name = "LootActive"
	active.Parent = workspace

	house = workspace:WaitForChild("House", 20)
	if house then
		local ls = house:FindFirstChild("LootSpawns")
		if ls then
			for _, p in ls:GetChildren() do
				if p:IsA("BasePart") then
					table.insert(lootSpawns, p)
				end
			end
		end
		local ps = house:FindFirstChild("PrizeSpawns")
		if ps then
			for _, p in ps:GetChildren() do
				if p:IsA("BasePart") then
					table.insert(prizeSpawns, p)
				end
			end
		end
		local car = house:FindFirstChild("MomsCar")
		trunk = car and car:FindFirstChild("Trunk", true) :: BasePart?
	end
	for _, part in CollectionService:GetTagged("Searchable") do
		if part:IsA("BasePart") then
			table.insert(searchables, part)
			hookSearchable(part)
		end
	end

	if trunk then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Stash Loot"
		prompt.ObjectText = "Mom's Trunk"
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt:SetAttribute("Kind", "Bank")
		-- Prompts only show when on screen: hang it just above the open boot at eye level,
		-- not on the trunk part (which can sit low/inside the car body).
		local anchor = Instance.new("Attachment")
		anchor.Name = "StashPromptAnchor"
		anchor.Parent = trunk
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = { trunk.Parent :: Instance }
		local ground = workspace:Raycast(trunk.Position, Vector3.new(0, -20, 0), rp)
		local groundY = if ground then ground.Position.Y else trunk.Position.Y - 2
		anchor.WorldPosition = Vector3.new(trunk.Position.X, groundY + 4.3, trunk.Position.Z)
		prompt.Parent = anchor
		-- A soft glow so players can find the boot in the dark yard.
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(156, 197, 161)
		glow.Range = 9
		glow.Brightness = 0.7
		glow.Shadows = false
		glow.Parent = anchor
		prompt.Triggered:Connect(function(p)
			if not validPicker(p, trunk, 14) then
				return
			end
			if #(carry[p] or {}) == 0 then
				Notify.Toast(p, "Nothing to stash yet — go steal something!", "Info")
				return
			end
			Sfx.Play("Bank", trunk)
			LootService:BankAll(p, "Trunk")
			if (DataService:Get(p, "HighestNight") or 0) == 0 then
				shared("Analytics").Onboarding(p, "FirstStash")
			end
		end)
	end

	local function init(p: Player)
		carry[p] = {}
		task.spawn(function()
			DataService:WaitForData(p, 20)
			refreshAttrs(p)
		end)
	end
	Players.PlayerAdded:Connect(init)
	for _, p in Players:GetPlayers() do
		init(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		carry[p] = nil
	end)
end

return LootService
