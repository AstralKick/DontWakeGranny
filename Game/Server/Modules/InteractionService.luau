--!strict
-- InteractionService (Match)
-- Doors (swing, squeak, lock/lockpick, Grandma opens them), hiding spots + Hold Your Breath,
-- the fuse box, consumable items (wind-up toy, cookie, soda), and the Night 31 finale
-- (light the jack-o'-lanterns, then escape to Mom's car).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local PlaceRole = shared("PlaceRole")
local GameConfig = shared("GameConfig")
local GrandmaConfig = shared("GrandmaConfig")
local EconomyConfig = shared("EconomyConfig")
local DataService = shared("DataService")
local Net = shared("Net")
local Notify = shared("Notify")
local Sfx = shared("Sfx")

local function svc(name: string): any
	return shared(name)
end

local InteractionService = {}

local LeaveHiding = Net.Event("LeaveHiding")
local HidingState = Net.Event("HidingState") -- -> player: (hidden: boolean, kind)
local HoldBreath = Net.Event("HoldBreath") -- -> player: (id, duration); player -> server: (id, success)
local UseItem = Net.Event("UseItem") -- player -> server: (key, lookDir)
local FinaleEvent = Net.Event("Finale") -- -> all: (stage, data)

local cfg: any = nil
local house: Instance?

-- ------------------------------------------------------------------ doors

type Door = {
	Model: Model,
	Hinge: BasePart,
	Panel: BasePart,
	ClosedPivot: CFrame,
	Open: boolean,
	Locked: boolean,
	Busy: boolean,
	Squeaky: boolean,
	Lockable: boolean,
	Area: string?,
	Prompt: ProximityPrompt,
}
local doors: { Door } = {}

local function setDoorPrompt(d: Door)
	if d.Locked then
		d.Prompt.ActionText = "Pick Lock"
		d.Prompt.HoldDuration = 2.4
		d.Prompt.ObjectText = "Locked"
	else
		d.Prompt.ActionText = if d.Open then "Close" else "Open"
		d.Prompt.HoldDuration = 0
		d.Prompt.ObjectText = if d.Squeaky then "Squeaky door" else ""
	end
	d.Model:SetAttribute("Open", d.Open)
	d.Model:SetAttribute("Locked", d.Locked)
end

local function swing(d: Door, open: boolean, awayFrom: Vector3?, speed: number?)
	if d.Busy or d.Open == open then
		return
	end
	d.Busy = true
	d.Open = open
	local target = d.ClosedPivot
	if open then
		-- Swing away from whoever opened it.
		local rel = d.ClosedPivot:PointToObjectSpace(awayFrom or (d.ClosedPivot.Position + d.ClosedPivot.LookVector))
		local sign = if rel.Z > 0 then 1 else -1
		target = d.ClosedPivot * CFrame.Angles(0, math.rad(90) * sign, 0)
	end
	local cv = Instance.new("CFrameValue")
	cv.Value = d.Model:GetPivot()
	cv.Changed:Connect(function(v)
		d.Model:PivotTo(v)
	end)
	local tw = TweenService:Create(cv, TweenInfo.new(speed or 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = target })
	tw.Completed:Once(function()
		cv:Destroy()
		d.Busy = false
	end)
	tw:Play()
	setDoorPrompt(d)
end

local function hookDoor(model: Model)
	local hinge = model:FindFirstChild("Hinge") :: BasePart?
	local panel = model:FindFirstChild("Panel") :: BasePart?
	if not hinge or not panel then
		warn("[Interaction] Door missing Hinge/Panel:", model:GetFullName())
		return
	end
	model.PrimaryPart = hinge
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = GameConfig.CollisionGroups.Doors
		end
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt:SetAttribute("Kind", "Door")
	prompt.Parent = panel

	local d: Door = {
		Model = model,
		Hinge = hinge,
		Panel = panel,
		ClosedPivot = model:GetPivot(),
		Open = false,
		Locked = false,
		Busy = false,
		Squeaky = model:GetAttribute("Squeaky") == true,
		Lockable = model:GetAttribute("Lockable") == true,
		Area = model:GetAttribute("Area"),
		Prompt = prompt,
	}
	table.insert(doors, d)
	setDoorPrompt(d)

	local picking: { [Player]: boolean } = {}
	prompt.PromptButtonHoldBegan:Connect(function(p)
		if not d.Locked or picking[p] then
			return
		end
		picking[p] = true
		task.spawn(function()
			while picking[p] and d.Locked do
				Sfx.Play("Lockpick", panel)
				svc("NoiseService"):Emit(panel.Position, 9, 36, p, "Lockpick")
				task.wait(0.6)
			end
		end)
	end)
	prompt.PromptButtonHoldEnded:Connect(function(p)
		picking[p] = nil
	end)
	prompt.Triggered:Connect(function(p)
		picking[p] = nil
		local match = svc("MatchService")
		if not match:IsAlive(p) or p:GetAttribute("Hidden") then
			return
		end
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root or (root.Position - panel.Position).Magnitude > 10 then
			return
		end
		if d.Locked then
			d.Locked = false
			Notify.Toast(p, "Click! Unlocked.", "Good")
			setDoorPrompt(d)
			swing(d, true, root.Position)
			return
		end
		local opening = not d.Open
		swing(d, opening, root.Position)
		if match:GetPhase() == "Night" then
			if d.Squeaky and opening then
				Sfx.Play("DoorCreak", panel)
				svc("NoiseService"):Emit(panel.Position, 26, 60, p, "Door")
			else
				Sfx.Play("DoorOpen", panel)
				local sprinting = p:GetAttribute("Sprinting")
				svc("NoiseService"):Emit(panel.Position, if sprinting then 20 else 13, 48, p, "Door")
			end
		end
	end)
end

-- Called by Grandma's mover: opens a closed door in her way. Returns pause seconds.
function InteractionService:DoorHook(from: Vector3, to: Vector3): number
	local dir = to - from
	for _, d in doors do
		if not d.Open and not d.Busy then
			local toDoor = d.Panel.Position - from
			if Vector3.new(toDoor.X, 0, toDoor.Z).Magnitude < 5.5 and math.abs(toDoor.Y) < 6 and (dir.Magnitude < 0.1 or toDoor:Dot(dir) > -1) then
				if d.Locked then
					d.Locked = false -- Grandma has the keys
				end
				swing(d, true, from, 0.3)
				Sfx.Play(if d.Squeaky then "DoorCreak" else "DoorOpen", d.Panel)
				return GrandmaConfig.AI.DoorOpenPause
			end
		end
	end
	return 0
end

-- ------------------------------------------------------------------ hiding

type Spot = { Model: Model, Inside: BasePart, Front: BasePart, Exit: BasePart, Kind: string, Area: string?, Occupant: Player?, Prompt: ProximityPrompt }
local spots: { Spot } = {}
local spotOf: { [Player]: Spot } = {}
local lastHideToggle: { [Player]: number } = {}

function InteractionService:GetHidingSpots(): { Spot }
	return spots
end

function InteractionService:SpotOf(p: Player): Spot?
	return spotOf[p]
end

local breathPending: { [Player]: { Id: number, Callback: (boolean) -> (), Done: boolean } } = {}

local function leave(p: Player)
	local spot = spotOf[p]
	if not spot then
		return
	end
	-- Bailing out mid breath-check ends it (you're standing in front of her now anyway).
	local pending = breathPending[p]
	if pending and not pending.Done then
		pending.Done = true
		breathPending[p] = nil
		task.defer(pending.Callback, false)
	end
	spotOf[p] = nil
	spot.Occupant = nil
	spot.Prompt.Enabled = true
	p:SetAttribute("Hidden", false)
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.Anchored = false
		root.CFrame = spot.Exit.CFrame + Vector3.new(0, 2.5, 0)
	end
	HidingState:FireClient(p, false, spot.Kind)
	svc("GrandmaService"):OnPlayerUnhid(p)
end

function InteractionService:PullOut(p: Player)
	leave(p)
end

-- Morning / game over: everyone climbs out.
function InteractionService:LeaveAll()
	for p in spotOf do
		leave(p)
	end
end

local function hide(p: Player, spot: Spot)
	if spot.Occupant or spotOf[p] then
		return
	end
	local match = svc("MatchService")
	if not match:IsAlive(p) then
		return
	end
	if os.clock() - (lastHideToggle[p] or 0) < 0.8 then
		return
	end
	lastHideToggle[p] = os.clock()
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or (root.Position - spot.Front.Position).Magnitude > 10 then
		return
	end
	spot.Occupant = p
	spotOf[p] = spot
	spot.Prompt.Enabled = false
	root.Anchored = true
	root.CFrame = spot.Inside.CFrame
	p:SetAttribute("Hidden", true)
	HidingState:FireClient(p, true, spot.Kind)
	DataService:IncStat(p, "Hides")
	Sfx.Play("DoorOpen", spot.Inside, { Volume = 0.25 })
	svc("GrandmaService"):OnPlayerHid(p, spot)
end

local function hookSpot(model: Model)
	local inside = model:FindFirstChild("Inside", true) :: BasePart?
	local front = model:FindFirstChild("Front", true) :: BasePart?
	local exit = model:FindFirstChild("Exit", true) :: BasePart?
	if not inside or not front or not exit then
		warn("[Interaction] HidingSpot missing Inside/Front/Exit:", model:GetFullName())
		return
	end
	local kind = model:GetAttribute("Kind") or "Wardrobe"
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Hide"
	prompt.ObjectText = kind
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 6
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt:SetAttribute("Kind", "Hide")
	-- Prompts only show when on screen: hang it at eye level on the spot's face (between
	-- Front, which is on the floor, and Inside) instead of on the floor marker.
	local anchor = Instance.new("Attachment")
	anchor.Name = "HidePromptAnchor"
	anchor.Parent = front
	local mid = front.Position:Lerp(inside.Position, 0.5)
	anchor.WorldPosition = Vector3.new(mid.X, math.max(front.Position.Y + 2.8, inside.Position.Y), mid.Z)
	prompt.Parent = anchor
	local spot: Spot = { Model = model, Inside = inside, Front = front, Exit = exit, Kind = kind, Area = model:GetAttribute("Area"), Occupant = nil, Prompt = prompt }
	table.insert(spots, spot)
	prompt.Triggered:Connect(function(p)
		hide(p, spot)
	end)
end

-- Hold Your Breath: the hidden player must hold the button for the whole check.
local breathId = 0

function InteractionService:BeginHoldBreath(p: Player, duration: number, callback: (boolean) -> ())
	breathId += 1
	local id = breathId
	local entry = { Id = id, Callback = callback, Done = false }
	breathPending[p] = entry
	HoldBreath:FireClient(p, id, duration)
	task.delay(duration + 0.8, function()
		if not entry.Done then
			-- No answer (lag/disconnect): be generous.
			entry.Done = true
			breathPending[p] = nil
			callback(true)
		end
	end)
end

-- ------------------------------------------------------------------ power

local fuseBox: BasePart?
local fusePrompt: ProximityPrompt?

function InteractionService:OnPowerChanged(on: boolean)
	if fusePrompt then
		fusePrompt.Enabled = not on
	end
end

-- ------------------------------------------------------------------ items

local freeItems: { [Player]: { [string]: number } } = {}

local function itemCount(p: Player, key: string): number
	local items = DataService:Get(p, "Items") or {}
	return (items[key] or 0) + ((freeItems[p] or {})[key] or 0)
end

local function pushItemAttrs(p: Player)
	local out = {}
	for _, key in EconomyConfig.ItemOrder do
		out[key] = itemCount(p, key)
	end
	p:SetAttribute("Items", HttpService:JSONEncode(out))
end

local function consume(p: Player, key: string): boolean
	local free = freeItems[p]
	if free and (free[key] or 0) > 0 then
		free[key] -= 1
		return true
	end
	local items = DataService:Get(p, "Items") or {}
	if (items[key] or 0) <= 0 then
		return false
	end
	DataService:AddItem(p, key, -1, EconomyConfig.Items[key].Max)
	return true
end

local function throwProp(p: Player, dir: Vector3, color: Color3, size: Vector3, onLand: (Vector3) -> ())
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local prop = Instance.new("Part")
	prop.Name = "ThrownItem"
	prop.Size = size
	prop.Color = color
	prop.Material = Enum.Material.SmoothPlastic
	prop.CollisionGroup = GameConfig.CollisionGroups.Loot
	prop.CanQuery = false
	prop.CFrame = root.CFrame * CFrame.new(0, 1.5, -2)
	prop.Parent = workspace
	prop:SetNetworkOwner(nil)
	local flat = Vector3.new(dir.X, 0, dir.Z)
	flat = if flat.Magnitude > 0.1 then flat.Unit else root.CFrame.LookVector
	prop.AssemblyLinearVelocity = flat * 38 + Vector3.new(0, 18, 0)
	task.delay(1.1, function()
		if prop.Parent then
			prop.AssemblyLinearVelocity = Vector3.zero
			onLand(prop.Position)
		end
	end)
	Debris:AddItem(prop, 12)
end

local function useItem(p: Player, key: string, dir: Vector3)
	local match = svc("MatchService")
	if match:GetPhase() ~= "Night" or not match:IsAlive(p) or p:GetAttribute("Hidden") then
		return
	end
	local def = EconomyConfig.Items[key]
	if not def or not consume(p, key) then
		return
	end
	DataService:IncStat(p, "ItemsUsed")
	svc("RewardsService"):QuestProgress(p, "UseItems", 1)
	pushItemAttrs(p)

	if key == "WindupToy" then
		throwProp(p, dir, Color3.fromRGB(217, 122, 138), Vector3.new(0.8, 0.8, 0.8), function(pos)
			for i = 1, def.Noise.Pulses do
				task.delay((i - 1) * def.Noise.Interval, function()
					Sfx.Play("WindupToy", pos)
					svc("NoiseService"):Emit(pos, def.Noise.Loudness, def.Noise.Radius, nil, "Toy")
				end)
			end
		end)
	elseif key == "Cookie" then
		throwProp(p, dir, Color3.fromRGB(200, 150, 100), Vector3.new(0.9, 0.25, 0.9), function(pos)
			local grandma = svc("GrandmaService")
			if not grandma:Distract(pos, def.DistractTime) then
				svc("NoiseService"):Emit(pos, 14, 60, nil, "Cookie")
			end
		end)
	elseif key == "FizzySoda" then
		svc("PlayerStateService"):Turbo(p, def.TurboTime)
		Sfx.Play("Pickup", p.Character and p.Character:FindFirstChild("Head") or nil)
	end
end

-- ------------------------------------------------------------------ finale

local pumpkins: { { Part: BasePart, Lit: boolean, Model: Model } } = {}
local finaleOpen = false
local escaped: { [Player]: boolean } = {}
local escapeZone: BasePart?

local function matchState(key: string, value: any)
	local ms = ReplicatedStorage:FindFirstChild("MatchState")
	if ms then
		ms:SetAttribute(key, value)
	end
end

local function clearFinale()
	for _, pk in pumpkins do
		pk.Model:Destroy()
	end
	table.clear(pumpkins)
	finaleOpen = false
	table.clear(escaped)
	matchState("PumpkinsLit", 0)
	matchState("PumpkinsTotal", 0)
	matchState("FinaleOpen", false)
	for _, p in Players:GetPlayers() do
		p:SetAttribute("Escaped", nil)
	end
end

local function buildPumpkin(at: BasePart): Model
	local m = Instance.new("Model")
	m.Name = "JackOLantern"
	local body = Instance.new("Part")
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2.4, 2, 2.4)
	body.Color = Color3.fromRGB(220, 110, 30)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CFrame = at.CFrame + Vector3.new(0, 1, 0)
	body.Parent = m
	local stem = Instance.new("Part")
	stem.Size = Vector3.new(0.3, 0.6, 0.3)
	stem.Color = Color3.fromRGB(80, 90, 50)
	stem.Anchored = true
	stem.CanCollide = false
	stem.CFrame = body.CFrame + Vector3.new(0, 1.1, 0)
	stem.Parent = m
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 140, 40)
	light.Range = 16
	light.Brightness = 2.5
	light.Enabled = false
	light.Parent = body
	m.PrimaryPart = body
	-- Own folder: LootService clears LootActive when it spawns the night's loot.
	local folder = workspace:FindFirstChild("FinaleProps")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "FinaleProps"
		folder.Parent = workspace
	end
	m.Parent = folder
	return m
end

local function setupFinale()
	clearFinale()
	local folder = house and house:FindFirstChild("PumpkinSpots")
	if not folder then
		return
	end
	for _, spot in folder:GetChildren() do
		if spot:IsA("BasePart") then
			local model = buildPumpkin(spot)
			local entry = { Part = spot, Lit = false, Model = model }
			table.insert(pumpkins, entry)
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Light"
			prompt.ObjectText = "Jack-o'-Lantern"
			prompt.HoldDuration = 2
			prompt.MaxActivationDistance = 7
			prompt.Style = Enum.ProximityPromptStyle.Custom
			prompt:SetAttribute("Kind", "Objective")
			-- Raise the prompt to eye level so it shows in first person (prompts need to be on screen).
			local pAnchor = Instance.new("Attachment")
			pAnchor.Parent = model.PrimaryPart
			pAnchor.Position = Vector3.new(0, 1.6, 0)
			prompt.Parent = pAnchor
			prompt.Triggered:Connect(function(p)
				local match = svc("MatchService")
				if entry.Lit or not match:IsAlive(p) or match:GetPhase() ~= "Night" then
					return
				end
				entry.Lit = true
				prompt.Enabled = false
				local body = model.PrimaryPart :: BasePart
				body.Material = Enum.Material.Neon
				body.Color = Color3.fromRGB(190, 70, 8) -- Neon brightens a lot; keep it pumpkin-orange under bloom
				local glow = body:FindFirstChildOfClass("PointLight")
				if glow then
					glow.Enabled = true
				end
				Sfx.Play("LanternLight", body)
				svc("NoiseService"):Emit(body.Position, 45, 160, p, "Lantern")
				local lit = 0
				for _, pk in pumpkins do
					if pk.Lit then
						lit += 1
					end
				end
				matchState("PumpkinsLit", lit)
				FinaleEvent:FireAllClients("Lit", { Lit = lit, Total = #pumpkins, By = p.DisplayName })
				if lit >= #pumpkins then
					finaleOpen = true
					matchState("FinaleOpen", true)
					Notify.Banner("all", "GET TO THE CAR!", "Mom's waiting. RUN.", Color3.fromRGB(255, 140, 20))
					FinaleEvent:FireAllClients("Open", {})
				end
			end)
		end
	end
	matchState("PumpkinsTotal", #pumpkins)
	matchState("PumpkinsLit", 0)
end

function InteractionService:FinaleEscaped(): boolean
	if not finaleOpen then
		return false
	end
	local match = svc("MatchService")
	local anyEscaped = false
	for _, p in match:GetAlivePlayers() do
		if escaped[p] then
			anyEscaped = true
		else
			return false
		end
	end
	return anyEscaped
end

local function finaleTick()
	if not finaleOpen or not escapeZone then
		return
	end
	local match = svc("MatchService")
	for _, p in match:GetAlivePlayers() do
		if not escaped[p] then
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and (root.Position - escapeZone.Position).Magnitude < 12 then
				escaped[p] = true
				p:SetAttribute("Escaped", true)
				svc("PlayerStateService"):GrantProtection(p, 999)
				Notify.Toast("all", `{p.DisplayName} made it to the car!`, "Good")
				FinaleEvent:FireAllClients("Escaped", { Name = p.DisplayName })
			end
		end
	end
end

-- ------------------------------------------------------------------ night reset

function InteractionService:ResetForNight(n: number, nightCfg: any)
	cfg = nightCfg
	for p in spotOf do
		leave(p)
	end
	for _, d in doors do
		d.Locked = false
		if d.Open then
			swing(d, false, nil, 0.05)
		end
		setDoorPrompt(d)
		d.Prompt.Enabled = not d.Area or cfg.Areas[d.Area] == true
	end
	-- Locked doors: Grandma's ability + the LockedDoors event
	local lockCount = 0
	if cfg.Abilities.LocksDoors then
		lockCount += 2
	end
	local ev = svc("EventService"):Get()
	if ev and ev.LockCount then
		lockCount += ev.LockCount
	end
	if lockCount > 0 then
		local pool = {}
		for _, d in doors do
			if d.Lockable and (not d.Area or cfg.Areas[d.Area]) then
				table.insert(pool, d)
			end
		end
		for _ = 1, math.min(lockCount, #pool) do
			local d = table.remove(pool, math.random(1, #pool)) :: Door
			d.Locked = true
			setDoorPrompt(d)
		end
	end
	for _, s in spots do
		s.Prompt.Enabled = not s.Area or cfg.Areas[s.Area] == true
	end

	-- Free items (Cookie Night)
	table.clear(freeItems)
	for _, p in Players:GetPlayers() do
		if ev and ev.FreeItem then
			freeItems[p] = { [ev.FreeItem] = 1 }
		end
		pushItemAttrs(p)
	end

	svc("NoiseService"):ResetBreakables()

	if nightCfg.Finale then
		setupFinale()
	else
		clearFinale()
	end
	local _ = n
end

-- ------------------------------------------------------------------ lifecycle

function InteractionService.Preload() end

function InteractionService:Start()
	if not PlaceRole.IsMatch then
		return
	end
	house = workspace:WaitForChild("House", 20)
	for _, m in CollectionService:GetTagged("Door") do
		if m:IsA("Model") then
			hookDoor(m)
		end
	end
	for _, m in CollectionService:GetTagged("HidingSpot") do
		if m:IsA("Model") then
			hookSpot(m)
		end
	end

	if house then
		fuseBox = house:FindFirstChild("FuseBox") :: BasePart?
		local car = house:FindFirstChild("MomsCar")
		escapeZone = car and (car:FindFirstChild("Trunk", true) :: BasePart?)
	end
	if fuseBox then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Fix the Fuses"
		prompt.ObjectText = "Fuse Box"
		prompt.HoldDuration = 3
		prompt.MaxActivationDistance = 7
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt:SetAttribute("Kind", "Objective")
		prompt.Enabled = false
		prompt.Parent = fuseBox
		fusePrompt = prompt
		prompt.PromptButtonHoldBegan:Connect(function(p)
			svc("NoiseService"):Emit((fuseBox :: BasePart).Position, 16, 50, p, "Fuse")
		end)
		prompt.Triggered:Connect(function(p)
			if svc("MatchService"):IsAlive(p) then
				svc("EnvironmentService"):RestorePower(p)
			end
		end)
	end

	LeaveHiding.OnServerEvent:Connect(function(p)
		if Net.RateLimit(p, "LeaveHiding", 3) and os.clock() - (lastHideToggle[p] or 0) > 0.5 then
			lastHideToggle[p] = os.clock()
			leave(p)
		end
	end)
	HoldBreath.OnServerEvent:Connect(function(p, id, success)
		local entry = breathPending[p]
		if entry and entry.Id == id and not entry.Done and typeof(success) == "boolean" then
			entry.Done = true
			breathPending[p] = nil
			entry.Callback(success)
		end
	end)
	UseItem.OnServerEvent:Connect(function(p, key, dir)
		if typeof(key) ~= "string" or typeof(dir) ~= "Vector3" or not Net.RateLimit(p, "UseItem", 1) then
			return
		end
		useItem(p, key, dir)
	end)

	DataService.PlayerLoaded:Connect(pushItemAttrs)
	Players.PlayerRemoving:Connect(function(p)
		leave(p)
		spotOf[p] = nil
		freeItems[p] = nil
		breathPending[p] = nil
		escaped[p] = nil
	end)
	svc("MatchService").PlayerCaught:Connect(function(p)
		leave(p)
	end)

	task.spawn(function()
		while true do
			task.wait(0.25)
			pcall(finaleTick)
		end
	end)
end

return InteractionService
