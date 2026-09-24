--!strict
-- LobbyService (Lobby place only)
-- Mom's Car matchmaking. Each car in Workspace.Lobby.Cars is a physical queue:
--   * Walk into the car's glowing door zone (or use its prompt) to get in.
--   * The first person in is the Driver: they pick Public / Friends Only and the start night.
--   * Countdown starts with the first passenger; drops to 5s when the car is full.
--   * When it hits 0 the car pulls away and the party teleports to a reserved Granny's House.
--
-- Map contract per car Model (built by tools/build_lobby.luau):
--   QueueZone (BasePart)       touch area at the sliding door
--   Seats (Folder of Seat)     MaxPlayers seats; the first is the driver's seat
--   Exit (BasePart)            where players are placed when they leave
--   Display (BasePart)         BillboardGui anchor for the "2/5" sign
--   Door (BasePart, optional)  tweened when the car departs

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local PlaceRole = shared("PlaceRole")
local PlaceConfig = shared("PlaceConfig")
local GameConfig = shared("GameConfig")
local DataService = shared("DataService")
local Net = shared("Net")
local Notify = shared("Notify")
local Sfx = shared("Sfx")

local LobbyService = {}

local COUNTDOWN = 15
local FULL_COUNTDOWN = 5

local CarAction = Net.Event("CarAction") -- client -> server: ("Leave") | ("FriendsOnly", bool) | ("StartNight", n) | ("Go")
local CarState = Net.Event("CarState") -- server -> client: (state table | nil)
local CarDepart = Net.Event("CarDepart") -- server -> party: ()

type Car = {
	Model: Model,
	Name: string,
	Seats: { Seat },
	Occupants: { Player },
	Leader: Player?,
	FriendsOnly: boolean,
	StartNight: number,
	Countdown: number?,
	Departing: boolean,
	HomePivot: CFrame,
	Billboard: BillboardGui,
}

local cars: { Car } = {}
local playerCar: { [Player]: Car } = {}
local reenterAfter: { [Player]: number } = {} -- short cooldown so leaving doesn't instantly re-queue you

-- ------------------------------------------------------------------ helpers

local function unlockedCheckpoints(player: Player): { number }
	local highest = DataService:Get(player, "HighestNight") or 0
	local out = {}
	for _, c in GameConfig.Checkpoints do
		if c <= highest + 1 then
			table.insert(out, c)
		end
	end
	return out
end

local function isFriend(a: Player, b: Player): boolean
	if a == b then
		return true
	end
	local ok, res = pcall(a.IsFriendsWith, a, b.UserId)
	return ok and res == true
end

local function buildBillboard(car: Car)
	local anchor = car.Model:FindFirstChild("Display") :: BasePart
	local bb = Instance.new("BillboardGui")
	bb.Name = "QueueSign"
	bb.Size = UDim2.fromScale(6.5, 2.5)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 140
	bb.DistanceLowerLimit = 0
	bb.AlwaysOnTop = false
	bb.Adornee = anchor
	bb.Parent = anchor

	local count = Instance.new("TextLabel")
	count.Name = "Count"
	count.BackgroundTransparency = 1
	count.Size = UDim2.fromScale(1, 0.55)
	count.FontFace = Font.fromEnum(Enum.Font.LuckiestGuy)
	count.TextScaled = true
	count.TextColor3 = Color3.fromRGB(243, 233, 210)
	count.Text = "0/5"
	count.Parent = bb
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(42, 26, 36)
	stroke.Parent = count

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.fromScale(0, 0.55)
	sub.Size = UDim2.fromScale(1, 0.4)
	sub.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	sub.TextScaled = true
	sub.TextColor3 = Color3.fromRGB(224, 176, 79)
	sub.Text = "WALK IN TO RIDE"
	sub.Parent = bb
	local stroke2 = stroke:Clone()
	stroke2.Thickness = 2
	stroke2.Parent = sub

	car.Billboard = bb
end

local function stateFor(car: Car, viewer: Player)
	local names = {}
	for _, p in car.Occupants do
		table.insert(names, { UserId = p.UserId, Name = p.DisplayName })
	end
	return {
		Car = car.Name,
		Count = #car.Occupants,
		Max = GameConfig.MaxPlayers,
		Countdown = car.Countdown,
		FriendsOnly = car.FriendsOnly,
		StartNight = car.StartNight,
		IsLeader = car.Leader == viewer,
		Checkpoints = if car.Leader == viewer then unlockedCheckpoints(viewer) else nil,
		Occupants = names,
		Departing = car.Departing,
	}
end

local function refresh(car: Car)
	local n = #car.Occupants
	local count = car.Billboard:FindFirstChild("Count") :: TextLabel
	local sub = car.Billboard:FindFirstChild("Sub") :: TextLabel
	count.Text = `{n}/{GameConfig.MaxPlayers}`
	if car.Departing then
		sub.Text = "SEE YOU AT GRANDMA'S"
	elseif car.Countdown then
		sub.Text = `LEAVING IN {math.ceil(car.Countdown)}`
	elseif car.FriendsOnly then
		sub.Text = "🔒 FRIENDS ONLY"
	else
		sub.Text = "WALK IN TO RIDE"
	end
	sub.TextColor3 = if car.FriendsOnly then Color3.fromRGB(156, 197, 161) else Color3.fromRGB(224, 176, 79)
	car.Model:SetAttribute("Count", n)
	car.Model:SetAttribute("FriendsOnly", car.FriendsOnly)
	car.Model:SetAttribute("Leader", car.Leader and car.Leader.UserId or 0)
	for _, p in car.Occupants do
		CarState:FireClient(p, stateFor(car, p))
	end
end

local function exitCar(player: Player, silent: boolean?)
	local car = playerCar[player]
	if not car then
		return
	end
	playerCar[player] = nil
	reenterAfter[player] = os.clock() + 3
	player:SetAttribute("InCar", nil)
	local idx = table.find(car.Occupants, player)
	if idx then
		table.remove(car.Occupants, idx)
	end
	if car.Leader == player then
		car.Leader = car.Occupants[1]
		if not car.Leader then
			car.FriendsOnly = false
			car.StartNight = 1
		end
	end
	if #car.Occupants == 0 then
		car.Countdown = nil
	end

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Sit = false
		local seat = hum.SeatPart
		if seat then
			local weld = seat:FindFirstChild("SeatWeld")
			if weld then
				weld:Destroy()
			end
		end
		task.defer(function()
			local exit = car.Model:FindFirstChild("Exit") :: BasePart?
			if exit and char.Parent then
				char:PivotTo(exit.CFrame + Vector3.new(0, 3, 0))
			end
		end)
	end
	if not silent and player.Parent then
		CarState:FireClient(player, nil)
	end
	refresh(car)
end

local function tryEnter(player: Player, car: Car)
	if playerCar[player] or car.Departing then
		return
	end
	if not DataService:IsLoaded(player) then
		return
	end
	if #car.Occupants >= GameConfig.MaxPlayers then
		Notify.Toast(player, "This car is full!", "Bad")
		return
	end
	if car.FriendsOnly and car.Leader and not isFriend(car.Leader, player) then
		Notify.Toast(player, `🔒 {car.Leader.DisplayName}'s car is friends only`, "Bad")
		return
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	-- Already sitting in one of this car's seats (physics sit)? Use it; else find a free one.
	local seat: Seat? = nil
	if hum.SeatPart and table.find(car.Seats, hum.SeatPart :: any) then
		seat = hum.SeatPart :: Seat
	else
		for _, s in car.Seats do
			if not s.Occupant then
				seat = s
				break
			end
		end
	end
	if not seat then
		return
	end

	table.insert(car.Occupants, player)
	playerCar[player] = car
	player:SetAttribute("InCar", car.Name)
	if not car.Leader then
		car.Leader = player
		car.StartNight = 1
	end
	if hum.SeatPart ~= seat then
		seat:Sit(hum)
	end
	if DataService:GetStat(player, "NightsPlayed") == 0 then
		shared("Analytics").Onboarding(player, "GotInCar")
	end
	Sfx.Play("CarDoor", seat)

	if not car.Countdown then
		car.Countdown = COUNTDOWN
	end
	if #car.Occupants >= GameConfig.MaxPlayers then
		car.Countdown = math.min(car.Countdown :: number, FULL_COUNTDOWN)
	end
	refresh(car)
end

local function depart(car: Car)
	car.Departing = true
	car.Countdown = nil
	refresh(car)

	local party = table.clone(car.Occupants)
	for _, p in party do
		CarDepart:FireClient(p)
	end
	Sfx.Play("CarEngine", car.Model.PrimaryPart)

	-- Drive forward (visual). Players stay seated & welded, so they ride along.
	local cf = Instance.new("CFrameValue")
	cf.Value = car.Model:GetPivot()
	local conn = cf.Changed:Connect(function(v)
		car.Model:PivotTo(v)
	end)
	local forward = car.Model:GetPivot() * CFrame.new(0, 0, -70)
	local tween = TweenService:Create(cf, TweenInfo.new(3.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = forward })
	tween:Play()
	task.wait(2.4)

	local userIds = {}
	for _, p in party do
		table.insert(userIds, p.UserId)
	end
	local valid = {}
	for _, p in party do
		if p.Parent == Players then
			table.insert(valid, p)
		end
	end

	local ok, err = false, "Empty party"
	if #valid > 0 then
		local options = Instance.new("TeleportOptions")
		options.ShouldReserveServer = true
		options:SetTeleportData({
			Party = userIds,
			StartNight = car.StartNight,
			FriendsOnly = car.FriendsOnly,
			Leader = car.Leader and car.Leader.UserId or 0,
		})
		ok, err = pcall(TeleportService.TeleportAsync, TeleportService, PlaceConfig.MatchPlaceId, valid, options)
	end

	if not ok then
		warn("[Lobby] Teleport failed:", err)
		for _, p in valid do
			Notify.Toast(p, if RunService:IsStudio() then "Teleports don't work in Studio — press Play in the Granny's House place to test a match." else "Couldn't reach Grandma's. Try again!", "Bad")
		end
	end

	task.wait(if ok then 6 else 1)
	-- Return the car home, empty it.
	tween:Cancel()
	conn:Disconnect()
	cf:Destroy()
	-- Park back home first so anyone still aboard (teleport failed) exits at the curb.
	car.Model:PivotTo(car.HomePivot)
	for _, p in table.clone(car.Occupants) do
		exitCar(p)
	end
	car.Departing = false
	car.Leader = nil
	car.FriendsOnly = false
	car.StartNight = 1
	refresh(car)
end

-- ------------------------------------------------------------------ leaderboard

local function startLeaderboard()
	local board = workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("Leaderboard")
	if not board then
		return
	end
	local okStore, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, "HighestNight_v1")
	if not okStore then
		return
	end
	local nameCache: { [number]: string } = {}

	local function submit(player: Player)
		local night = DataService:Get(player, "HighestNight") or 0
		if night > 0 then
			pcall(store.SetAsync, store, tostring(player.UserId), night)
		end
	end
	DataService.PlayerLoaded:Connect(submit)

	task.spawn(function()
		while true do
			local ok, pages = pcall(store.GetSortedAsync, store, false, 10)
			if ok and pages then
				local entries = pages:GetCurrentPage()
				local rows = {}
				for i, e in entries do
					local uid = tonumber(e.key) or 0
					local name = nameCache[uid]
					if not name then
						local okN, n = pcall(Players.GetNameFromUserIdAsync, Players, uid)
						name = if okN then n else "???"
						nameCache[uid] = name
					end
					rows[i] = { Name = name, Night = e.value }
				end
				board:SetAttribute("Rows", game:GetService("HttpService"):JSONEncode(rows))
			end
			task.wait(90)
		end
	end)
end

-- ------------------------------------------------------------------ lifecycle

function LobbyService.Preload() end

function LobbyService:Start()
	if not PlaceRole.IsLobby then
		return
	end

	local lobby = workspace:WaitForChild("Lobby", 10)
	local folder = lobby and lobby:FindFirstChild("Cars")
	if not folder then
		warn("[Lobby] Workspace.Lobby.Cars missing — run tools/build_lobby.luau")
		return
	end

	for _, model in folder:GetChildren() do
		if not model:IsA("Model") then
			continue
		end
		local seats = {}
		local seatFolder = model:FindFirstChild("Seats")
		if seatFolder then
			for _, s in seatFolder:GetChildren() do
				if s:IsA("Seat") then
					table.insert(seats, s)
				end
			end
		end
		table.sort(seats, function(a, b)
			return a.Name < b.Name
		end)
		local car: Car = {
			Model = model,
			Name = model.Name,
			Seats = seats,
			Occupants = {},
			Leader = nil,
			FriendsOnly = false,
			StartNight = 1,
			Countdown = nil,
			Departing = false,
			HomePivot = model:GetPivot(),
			Billboard = nil :: any,
		}
		buildBillboard(car)
		table.insert(cars, car)

		local zone = model:FindFirstChild("QueueZone") :: BasePart?
		if zone then
			zone.Touched:Connect(function(hit)
				local p = Players:GetPlayerFromCharacter(hit.Parent)
				if p then
					tryEnter(p, car)
				end
			end)
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Ride to Grandma's"
			prompt.ObjectText = "Mom's Car"
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 12
			prompt.RequiresLineOfSight = false
			prompt.Parent = zone
			prompt.Triggered:Connect(function(p)
				tryEnter(p, car)
			end)
		end
		for _, seat in seats do
			-- Anyone sitting via physics without queueing gets queued; standing up leaves.
			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				local occ = seat.Occupant
				if occ then
					local p = Players:GetPlayerFromCharacter(occ.Parent)
					if p and not playerCar[p] then
						task.defer(function()
							tryEnter(p, car)
							if not playerCar[p] then
								-- Not allowed in (full / friends only / departing): stand back up.
								occ.Sit = false
							end
						end)
					end
				else
					for _, p in table.clone(car.Occupants) do
						local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
						if not h or h.SeatPart == nil then
							exitCar(p)
						end
					end
				end
			end)
		end
		refresh(car)
	end

	CarAction.OnServerEvent:Connect(function(player, action, value)
		if not Net.RateLimit(player, "CarAction", 6) then
			return
		end
		local car = playerCar[player]
		if not car or car.Departing then
			return
		end
		if action == "Leave" then
			exitCar(player)
		elseif action == "FriendsOnly" and car.Leader == player and typeof(value) == "boolean" then
			car.FriendsOnly = value
			if value then
				-- Remove non-friends politely
				for _, p in table.clone(car.Occupants) do
					if not isFriend(player, p) then
						exitCar(p)
						Notify.Toast(p, `{player.DisplayName} made their car friends only`, "Info")
					end
				end
			end
			refresh(car)
		elseif action == "StartNight" and car.Leader == player and typeof(value) == "number" then
			if table.find(unlockedCheckpoints(player), value) then
				car.StartNight = value
				refresh(car)
			end
		elseif action == "Go" and car.Leader == player then
			car.Countdown = math.min(car.Countdown or FULL_COUNTDOWN, 3)
			refresh(car)
		end
	end)

	Players.PlayerRemoving:Connect(function(p)
		exitCar(p, true)
	end)

	-- Zone poll: Touched misses teleports/standing still, so also check who is inside
	-- each car's door zone a few times per second (cheap: ≤5 players × 3 cars).
	task.spawn(function()
		while true do
			task.wait(0.3)
			for _, car in cars do
				local zone = car.Model:FindFirstChild("QueueZone") :: BasePart?
				if zone and not car.Departing then
					for _, p in Players:GetPlayers() do
						local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
						if root and not playerCar[p] and os.clock() > (reenterAfter[p] or 0) then
							local rel = zone.CFrame:PointToObjectSpace(root.Position)
							local half = zone.Size / 2 + Vector3.new(1, 3, 1)
							if math.abs(rel.X) < half.X and math.abs(rel.Y) < half.Y and math.abs(rel.Z) < half.Z then
								tryEnter(p, car)
							end
						end
					end
				end
			end
		end
	end)

	-- Countdown loop (1 Hz is plenty; the client interpolates)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, car in cars do
				if car.Countdown and not car.Departing then
					car.Countdown -= 1
					if car.Countdown <= 0 then
						task.spawn(depart, car)
					else
						refresh(car)
					end
				end
			end
		end
	end)

	startLeaderboard()
end

return LobbyService
