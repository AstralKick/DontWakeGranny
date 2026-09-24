--!strict
-- MatchService (Granny's House place only)
-- Owns the run: party arrival -> nights 1..31 -> victory / game over.
-- Every phase change is mirrored to ReplicatedStorage.MatchState attributes for clients.
--
-- Phases: Waiting -> Intro -> Night -> Morning -> (Intro ...) | GameOver | Victory | Ended
--
-- Other services talk to the run through this API (never the other way round):
--   MatchService:GetNight() / :GetNightConfig() / :GetPhase()
--   MatchService:GetPlayers() / :GetAlivePlayers() / :IsAlive(p)
--   MatchService:CatchPlayer(p, cause)   -- Grandma (or anything) eliminates a player
--   MatchService.NightStarted / NightEnded / PlayerCaught (BindableEvent .Event)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local PlaceRole = shared("PlaceRole")
local PlaceConfig = shared("PlaceConfig")
local GameConfig = shared("GameConfig")
local NightConfig = shared("NightConfig")
local MapConfig = shared("MapConfig")
local EconomyConfig = shared("EconomyConfig")
local GrandmaConfig = shared("GrandmaConfig")
local DataService = shared("DataService")
local Net = shared("Net")
local Notify = shared("Notify")

local function svc(name: string): any
	return shared(name)
end

local MatchService = {}

local nightStarted = Instance.new("BindableEvent")
local nightEnded = Instance.new("BindableEvent")
local playerCaught = Instance.new("BindableEvent")
MatchService.NightStarted = nightStarted.Event -- (night, cfg)
MatchService.NightEnded = nightEnded.Event -- (night, survived: boolean)
MatchService.PlayerCaught = playerCaught.Event -- (player, cause)

-- Remotes
local CaughtEvent = Net.Event("Caught") -- -> victim: (formKey, lostValue, lostCount, canRevive, freeRevive)
local TeammateCaught = Net.Event("TeammateCaught") -- -> others: (name)
local NightSummary = Net.Event("NightSummary") -- -> each: summary table
local RequestReturn = Net.Event("ReturnToLobby")
local RequestFreeRevive = Net.Function("RequestFreeRevive")
local UseReviveToken = Net.Function("UseReviveToken")

local state = Instance.new("Folder")
state.Name = "MatchState"

local phase = "Waiting"
local night = 1
local nightCfg: any = NightConfig.Get(1)
local nightEndsAt = 0
local continueRequested = false
local continuesLeft = GameConfig.ContinueRun.MaxPerRun
local expectedParty: { number } = {}
local runPlayers: { [Player]: boolean } = {} -- players participating in this run
local alive: { [Player]: boolean } = {}
local revivesThisNight: { [Player]: number } = {}
local nightStats: { [Player]: { Banked: number, Lost: number, Survived: boolean } } = {}
local sugarRushNight = 0

-- ------------------------------------------------------------------ state helpers

local function setState(key: string, value: any)
	state:SetAttribute(key, value)
end

local function setPhase(p: string)
	phase = p
	setState("Phase", p)
end

function MatchService:GetPhase(): string
	return phase
end

function MatchService:GetNight(): number
	return night
end

function MatchService:GetNightConfig(): any
	return nightCfg
end

function MatchService:GetPlayers(): { Player }
	local out = {}
	for p in runPlayers do
		if p.Parent == Players then
			table.insert(out, p)
		end
	end
	return out
end

function MatchService:GetAlivePlayers(): { Player }
	local out = {}
	for p in alive do
		if p.Parent == Players then
			table.insert(out, p)
		end
	end
	return out
end

function MatchService:IsAlive(p: Player): boolean
	return alive[p] == true
end

-- Studio only (DebugService): jump the clock to dawn.
function MatchService:DebugEndNight()
	MatchService:DebugSetTimeLeft(0)
end

-- Studio only: set how many seconds remain until dawn (e.g. to watch the final countdown).
function MatchService:DebugSetTimeLeft(seconds: number)
	if RunService:IsStudio() and phase == "Night" then
		nightEndsAt = workspace:GetServerTimeNow() + seconds
		local startAt = state:GetAttribute("NightStart") or 0
		local duration = nightCfg.Duration
		-- keep the clock/progress consistent: shift the start so frac matches the new end
		state:SetAttribute("NightStart", nightEndsAt - duration)
		state:SetAttribute("NightEnd", nightEndsAt)
		local _ = startAt
	end
end

function MatchService:GetNightStart(): number
	return state:GetAttribute("NightStart") or 0
end

function MatchService:TimeLeft(): number
	return math.max(0, nightEndsAt - workspace:GetServerTimeNow())
end

function MatchService:PartyScale()
	local n = math.clamp(#self:GetPlayers(), 1, 5)
	return GameConfig.PartyScaling[n]
end

function MatchService:IsSugarRush(): boolean
	return sugarRushNight == night
end

function MatchService:RecordBank(p: Player, value: number)
	local s = nightStats[p]
	if s then
		s.Banked += value
		p:SetAttribute("BankedTonight", s.Banked)
	end
end

-- ------------------------------------------------------------------ spawning

local function spawnPoints(): { BasePart }
	local house = workspace:FindFirstChild("House")
	local folder = house and house:FindFirstChild("PlayerSpawns")
	local out = {}
	if folder then
		for _, p in folder:GetChildren() do
			if p:IsA("BasePart") then
				table.insert(out, p)
			end
		end
	end
	return out
end

local function spawnPlayer(p: Player, index: number)
	if p.Parent ~= Players then
		return
	end
	p:LoadCharacter()
	local char = p.Character or p.CharacterAdded:Wait()
	local points = spawnPoints()
	local point = points[((index - 1) % math.max(1, #points)) + 1]
	if point then
		char:PivotTo(point.CFrame + Vector3.new(0, 3, 0))
	end
end

local function setAlive(p: Player, isAlive: boolean)
	alive[p] = if isAlive then true else nil
	p:SetAttribute("Alive", isAlive)
	local count = #MatchService:GetAlivePlayers()
	setState("AliveCount", count)
end

-- ------------------------------------------------------------------ catching

function MatchService:CatchPlayer(p: Player, cause: string?)
	if not alive[p] or (phase ~= "Night") then
		return
	end
	setAlive(p, false)
	local lostValue, lostCount = svc("LootService"):OnCaught(p)
	local s = nightStats[p]
	if s then
		s.Lost += lostValue
	end
	DataService:IncStat(p, "TimesCaught")
	svc("RewardsService"):CheckAchievements(p)

	local tutorial = DataService:Get(p, "Tutorial") or {}
	local freeRevive = GameConfig.Revive.FreeFirstRevive and not tutorial.UsedFreeRevive
	local canRevive = MatchService:CanRevive(p)
	CaughtEvent:FireClient(p, nightCfg.Form, lostValue, lostCount, canRevive, freeRevive and canRevive, cause or "Grandma")
	for other in runPlayers do
		if other ~= p and other.Parent == Players then
			TeammateCaught:FireClient(other, p.DisplayName, lostValue)
		end
	end
	playerCaught:Fire(p, cause)

	-- Remove the body after the jumpscare so spectators see a clean world.
	local form = GrandmaConfig.Forms[nightCfg.Form] or GrandmaConfig.Forms.Normal
	task.delay(form.Jumpscare.Duration + 0.3, function()
		if not alive[p] and p.Character then
			p.Character:Destroy()
			p.Character = nil
		end
	end)
end

-- ------------------------------------------------------------------ revive

function MatchService:CanRevive(p: Player): (boolean, string?)
	if phase ~= "Night" then
		return false, "Only during the night"
	end
	if alive[p] or not runPlayers[p] then
		return false, "You're alive!"
	end
	if (revivesThisNight[p] or 0) >= GameConfig.Revive.MaxPerNight then
		return false, "One revive per night"
	end
	if MatchService:TimeLeft() < GameConfig.Revive.MinTimeLeft then
		return false, "Almost morning — hang on!"
	end
	if #MatchService:GetAlivePlayers() == 0 then
		return false, "Everyone's caught"
	end
	return true
end

function MatchService:RevivePlayer(p: Player): boolean
	if not MatchService:CanRevive(p) then
		return false
	end
	revivesThisNight[p] = (revivesThisNight[p] or 0) + 1
	spawnPlayer(p, math.random(1, 5))
	setAlive(p, true)
	svc("PlayerStateService"):GrantProtection(p, GameConfig.Revive.SpawnProtection)
	Notify.Toast("all", `{p.DisplayName} is back! 💖`, "Good")
	return true
end

-- ------------------------------------------------------------------ continue run

function MatchService:CanContinue(): (boolean, string?)
	if phase ~= "GameOver" then
		return false, "Not now"
	end
	if continuesLeft <= 0 then
		return false, "No continues left this run"
	end
	return true
end

function MatchService:ContinueRun(buyer: Player): boolean
	if not MatchService:CanContinue() then
		return false
	end
	continuesLeft -= 1
	setState("ContinuesLeft", continuesLeft)
	continueRequested = true
	Notify.Banner("all", "ONE MORE TRY", `{buyer.DisplayName} continued the run!`, Color3.fromRGB(217, 122, 138))
	return true
end

-- ------------------------------------------------------------------ sugar rush

function MatchService:StartSugarRush(buyer: Player): boolean
	if phase == "Ended" or phase == "Victory" then
		return false
	end
	sugarRushNight = if phase == "Night" or phase == "Intro" then night else night + 1
	setState("SugarRushNight", sugarRushNight)
	Notify.Banner("all", "SUGAR RUSH!", `{buyer.DisplayName} doubled everyone's loot ` .. (if sugarRushNight == night then "tonight!" else "next night!"), Color3.fromRGB(224, 176, 79))
	return true
end

-- ------------------------------------------------------------------ lobby return

local function sendToLobby(list: { Player })
	if #list == 0 then
		return
	end
	local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, PlaceConfig.LobbyPlaceId, list)
	if not ok then
		warn("[Match] Return to lobby failed:", err)
		for _, p in list do
			if RunService:IsStudio() then
				Notify.Toast(p, "Teleports don't work in Studio (would return to lobby).", "Info")
			else
				p:Kick("Returning to the lobby failed — please rejoin!")
			end
		end
	end
end

-- ------------------------------------------------------------------ night flow

local function prepareNight(n: number)
	night = n
	local eventKey = svc("EventService"):Roll(n)
	nightCfg = NightConfig.Get(n)
	revivesThisNight = {}
	nightStats = {}
	continueRequested = false

	setState("Night", n)
	setState("Event", eventKey or "")
	setState("Form", nightCfg.Form)
	setState("Corruption", nightCfg.Corruption)
	setState("Finale", nightCfg.Finale)
	setState("Title", nightCfg.Title)
	setState("Subtitle", nightCfg.Subtitle)
	setState("NewArea", nightCfg.NewArea or "")
	setState("Duration", nightCfg.Duration)
	setState("SugarRushNight", sugarRushNight)

	-- New chapter -> new map (services rebind via MapService.MapChanged).
	svc("MapService"):EnsureFor(n)
	setState("Chapter", MapConfig.ChapterFor(n).Name)
	svc("EnvironmentService"):ApplyNight(n, nightCfg)
	svc("InteractionService"):ResetForNight(n, nightCfg)
	svc("LootService"):SpawnForNight(n, nightCfg)
	svc("GrandmaService"):ResetForNight(n, nightCfg)

	-- Everyone in the run comes back for the new night (dead players return here).
	local i = 0
	for _, p in MatchService:GetPlayers() do
		i += 1
		nightStats[p] = { Banked = 0, Lost = 0, Survived = false }
		p:SetAttribute("BankedTonight", 0)
		p:SetAttribute("NightGoal", nightCfg.LootGoal or 0)
		task.spawn(spawnPlayer, p, i)
		setAlive(p, true)
		DataService:IncStat(p, "NightsPlayed")
		-- The Night-1 hint tags only run on Night 1; anyone starting later has "seen" them.
		if n > 1 then
			DataService:Update(p, "Tutorial", function(t)
				t.SeenIntro = true
				return t
			end)
		end
	end
end

local function runNight(): string -- returns "Survived" | "Wiped"
	-- Cinematic intro: clients play the establishing shots until IntroEnd (server time).
	local introTime = if night == 1 then GameConfig.FirstNightIntroTime else GameConfig.NightIntroTime
	setState("IntroEnd", workspace:GetServerTimeNow() + introTime)
	setState("IntroLength", introTime)
	setPhase("Intro")
	task.wait(introTime)

	local startAt = workspace:GetServerTimeNow()
	nightEndsAt = startAt + nightCfg.Duration
	setState("NightStart", startAt)
	setState("NightEnd", nightEndsAt)
	setPhase("Night")
	nightStarted:Fire(night, nightCfg)

	while true do
		task.wait(0.25)
		if #MatchService:GetPlayers() == 0 then
			return "Wiped"
		end
		if #MatchService:GetAlivePlayers() == 0 then
			return "Wiped"
		end
		if nightCfg.Finale and svc("InteractionService"):FinaleEscaped() then
			return "Survived"
		end
		if workspace:GetServerTimeNow() >= nightEndsAt then
			if nightCfg.Finale then
				-- Halloween night has no dawn: you only win by escaping.
				return "Wiped"
			end
			return "Survived"
		end
	end
end

local function morning()
	setPhase("Morning")
	nightEnded:Fire(night, true)
	svc("InteractionService"):LeaveAll()

	local players = MatchService:GetPlayers()
	local survivors = MatchService:GetAlivePlayers()
	local loot = svc("LootService")
	local rewards = svc("RewardsService")

	for _, p in players do
		local survived = alive[p] == true
		local s = nightStats[p] or { Banked = 0, Lost = 0, Survived = false }
		s.Survived = survived
		local friends = rewards:CountFriendsIn(p, players)
		local summary = {
			Night = night,
			Survived = survived,
			Banked = s.Banked,
			Lost = s.Lost,
			AutoBanked = 0,
			Bonus = 0,
			Friends = friends,
			FriendMult = rewards:FriendMultiplier(friends),
			NextNight = night + 1,
			NextNewArea = if night < 31 then NightConfig.Get(night + 1).NewArea else nil,
			Checkpoint = NightConfig.IsCheckpoint(night + 1) and (night + 1) or nil,
			ChapterComplete = if MapConfig.ChapterFor(night).LastNight == night then MapConfig.ChapterFor(night).Name else nil,
			NextChapter = if night < 31 and MapConfig.ChapterFor(night).LastNight == night then MapConfig.ChapterFor(night + 1).Name else nil,
		}
		if survived then
			summary.AutoBanked = loot:BankAll(p, "Dawn")
			local bonus = math.floor(EconomyConfig.SurviveBonus(night) * summary.FriendMult)
			-- Stash goal: stashed (incl. dawn auto-stash) >= tonight's goal pays extra.
			local goal = nightCfg.LootGoal or 0
			summary.Goal = goal
			summary.GoalMet = goal > 0 and s.Banked >= goal
			if summary.GoalMet then
				local goalBonus = math.floor(goal * (nightCfg.GoalBonus or 0.3))
				bonus += goalBonus
				summary.GoalBonus = goalBonus
				Notify.Toast(p, `Stash goal smashed! +{goalBonus} Candy`, "Candy")
			end
			DataService:AddCandy(p, bonus)
			summary.Bonus = bonus
			DataService:IncStat(p, "NightsSurvived")
			DataService:Update(p, "HighestNight", function(v)
				return math.max(v or 0, night)
			end)
			rewards:QuestProgress(p, "SurviveNights", 1)
			if friends > 0 then
				DataService:IncStat(p, "FriendNights")
				rewards:TryBuddyBonus(p)
			end
			shared("Analytics").Custom(p, "NightSurvived", night)
			if night == 1 then
				shared("Analytics").Onboarding(p, "SurvivedNight1")
				DataService:Update(p, "Tutorial", function(t)
					t.FirstNightDone = true
					return t
				end)
			end
		end
		summary.Candy = DataService:GetCandy(p)
		rewards:CheckAchievements(p)
		NightSummary:FireClient(p, summary)
	end

	svc("GrandmaService"):EnterMorning()
	svc("EnvironmentService"):Morning()
	task.wait(GameConfig.IntermissionTime)
	return #survivors
end

local function victory()
	setPhase("Victory")
	nightEnded:Fire(night, true)
	svc("InteractionService"):LeaveAll()
	for _, p in MatchService:GetPlayers() do
		local escaped = alive[p] == true
		if escaped then
			svc("LootService"):BankAll(p, "Dawn")
		end
		-- Everyone in the party shares the win if anyone escaped: it's a co-op finale.
		DataService:AddCandy(p, EconomyConfig.VictoryBonus)
		DataService:Update(p, "Wins", function(v)
			return (v or 0) + 1
		end)
		DataService:Update(p, "HighestNight", function(v)
			return math.max(v or 0, 31)
		end)
		svc("RewardsService"):CheckAchievements(p)
	end
	Notify.Banner("all", "HAPPY HALLOWEEN", "You survived 31 nights at Grandma's.", Color3.fromRGB(255, 140, 20))
	svc("GrandmaService"):EnterMorning()
	svc("EnvironmentService"):Morning()
	task.wait(GameConfig.ReturnToLobbyDelay + 6)
	setPhase("Ended")
	sendToLobby(MatchService:GetPlayers())
end

local function gameOver(): boolean -- returns true if continued
	setPhase("GameOver")
	nightEnded:Fire(night, false)
	setState("GameOverEnd", workspace:GetServerTimeNow() + GameConfig.GameOverTime)
	svc("GrandmaService"):EnterMorning()
	local t0 = os.clock()
	while os.clock() - t0 < GameConfig.GameOverTime do
		task.wait(0.25)
		if continueRequested then
			return true
		end
		if #MatchService:GetPlayers() == 0 then
			return false
		end
	end
	return false
end

local function runLoop(startNight: number)
	night = startNight
	while true do
		prepareNight(night)
		local result = runNight()
		if result == "Survived" then
			if night >= GameConfig.TotalNights or nightCfg.Finale then
				victory()
				return
			end
			morning()
			night += 1
		else
			if gameOver() then
				-- Continue: replay the same night. Lost loot stays lost.
				continue
			end
			setPhase("Ended")
			Notify.Banner("all", "GRANDMA WINS", `You made it to Night {night}.`, Color3.fromRGB(168, 50, 62))
			task.wait(GameConfig.ReturnToLobbyDelay)
			sendToLobby(MatchService:GetPlayers())
			return
		end
	end
end

-- ------------------------------------------------------------------ arrival

local function readTeleportData(p: Player): any
	local ok, jd = pcall(p.GetJoinData, p)
	if ok and jd and type(jd.TeleportData) == "table" then
		return jd.TeleportData
	end
	return nil
end

local function waitForParty(): number
	setPhase("Waiting")
	local startNight = 1
	local gotData = false
	local deadline = os.clock() + GameConfig.ArrivalTimeout

	while os.clock() < deadline do
		for _, p in Players:GetPlayers() do
			if not gotData then
				local td = readTeleportData(p)
				if td and type(td.Party) == "table" then
					gotData = true
					expectedParty = td.Party
					startNight = math.clamp(tonumber(td.StartNight) or 1, 1, 31)
				end
			end
		end
		if not gotData and RunService:IsStudio() and #Players:GetPlayers() > 0 then
			-- Studio test: start with whoever pressed Play.
			startNight = math.clamp(tonumber(workspace:GetAttribute("DebugStartNight")) or 1, 1, 31)
			task.wait(2)
			break
		end
		if gotData then
			local arrived = 0
			for _, uid in expectedParty do
				local p = Players:GetPlayerByUserId(uid)
				if p and DataService:IsLoaded(p) then
					arrived += 1
				end
			end
			setState("Arrived", arrived)
			setState("Expected", #expectedParty)
			if arrived >= #expectedParty then
				break
			end
		end
		task.wait(0.5)
	end

	for _, p in Players:GetPlayers() do
		-- Slow saves after the teleport: give them time, otherwise tonight's Candy can't be saved.
		DataService:WaitForData(p, 30)
		runPlayers[p] = true
		if DataService:GetStat(p, "NightsPlayed") == 0 then
			shared("Analytics").Onboarding(p, "ArrivedAtGrandmas")
		end
	end
	setState("PartySize", #MatchService:GetPlayers())
	return startNight
end

-- ------------------------------------------------------------------ lifecycle

function MatchService.Preload()
	if PlaceRole.IsMatch then
		Players.CharacterAutoLoads = false
		StarterPlayer.CharacterWalkSpeed = GameConfig.Movement.WalkSpeed
		StarterPlayer.CharacterJumpHeight = 0
		StarterPlayer.CharacterJumpPower = 0
	end
end

function MatchService:Start()
	if not PlaceRole.IsMatch then
		return
	end
	state.Parent = ReplicatedStorage
	setState("ContinuesLeft", continuesLeft)
	setState("Phase", "Waiting")

	-- Products
	local monetization = svc("MonetizationService")
	monetization:RegisterProduct("Revive", function(p)
		return MatchService:CanRevive(p)
	end, function(p)
		return MatchService:RevivePlayer(p)
	end, function(p)
		DataService:Update(p, "Tokens", function(t)
			t.Revive = (t.Revive or 0) + 1
			return t
		end)
		Notify.Toast(p, "Revive saved for later 💖", "Good")
	end)
	monetization:RegisterProduct("ContinueRun", function()
		return MatchService:CanContinue()
	end, function(p)
		return MatchService:ContinueRun(p)
	end)
	monetization:RegisterProduct("SugarRush", function()
		if phase == "Ended" or phase == "Victory" or phase == "GameOver" then
			return false, "Not now"
		end
		return true
	end, function(p)
		return MatchService:StartSugarRush(p)
	end)

	RequestFreeRevive.OnServerInvoke = function(p)
		if not Net.RateLimit(p, "FreeRevive", 1) then
			return false
		end
		local t = DataService:Get(p, "Tutorial")
		if not t or t.UsedFreeRevive or not GameConfig.Revive.FreeFirstRevive then
			return false, "Already used"
		end
		if not MatchService:CanRevive(p) then
			return false, "Not now"
		end
		DataService:Update(p, "Tutorial", function(v)
			v.UsedFreeRevive = true
			return v
		end)
		return MatchService:RevivePlayer(p)
	end
	UseReviveToken.OnServerInvoke = function(p)
		if not Net.RateLimit(p, "ReviveToken", 1) then
			return false
		end
		local tokens = DataService:Get(p, "Tokens")
		if not tokens or (tokens.Revive or 0) <= 0 or not MatchService:CanRevive(p) then
			return false
		end
		DataService:Update(p, "Tokens", function(v)
			v.Revive -= 1
			return v
		end)
		return MatchService:RevivePlayer(p)
	end
	RequestReturn.OnServerEvent:Connect(function(p)
		if Net.RateLimit(p, "Return", 0.5) then
			svc("LootService"):OnCaught(p) -- anything unbanked is lost when you leave
			runPlayers[p] = nil
			setAlive(p, false)
			sendToLobby({ p })
		end
	end)

	Players.PlayerAdded:Connect(function(p)
		-- Late party member: join the run. Mid-night arrivals spectate until next night
		-- unless the night just started.
		DataService:WaitForData(p, 15)
		-- Already in the run (arrived with the party; their save just loaded slowly after the
		-- teleport): they were spawned by the night itself. Never mark them dead here, or they
		-- lose their controls and HUD until the next night.
		if phase == "Waiting" or phase == "Ended" or runPlayers[p] or alive[p] then
			return
		end
		runPlayers[p] = true
		setState("PartySize", #MatchService:GetPlayers())
		local sinceStart = workspace:GetServerTimeNow() - (state:GetAttribute("NightStart") or 0)
		if phase == "Intro" or (phase == "Night" and sinceStart < 25) then
			nightStats[p] = { Banked = 0, Lost = 0, Survived = false }
			spawnPlayer(p, 1)
			setAlive(p, true)
		else
			p:SetAttribute("Alive", false)
		end
	end)

	Players.PlayerRemoving:Connect(function(p)
		runPlayers[p] = nil
		if alive[p] then
			setAlive(p, false)
		end
		svc("LootService"):OnCaught(p)
		setState("PartySize", #MatchService:GetPlayers())
	end)

	task.spawn(function()
		-- Let everyone's character exist in the yard while we wait.
		task.spawn(function()
			while phase == "Waiting" do
				for i, p in Players:GetPlayers() do
					if not p.Character and DataService:IsLoaded(p) then
						task.spawn(spawnPlayer, p, i)
					end
				end
				task.wait(0.5)
			end
		end)
		local startNight = waitForParty()
		runLoop(startNight)
	end)
end

return MatchService
