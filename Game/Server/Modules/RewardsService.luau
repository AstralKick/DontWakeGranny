--!strict
-- RewardsService
-- Retention systems: daily mailbox, daily quests, achievements + badges, diary pages,
-- friend (buddy) bonus and referrals. Runs in both places.
--
-- Gameplay services report progress with:
--   RewardsService:QuestProgress(player, questId, amount)
--   RewardsService:CheckAchievements(player)

local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

local DataService = shared("DataService")
local EconomyConfig = shared("EconomyConfig")
local AchievementConfig = shared("AchievementConfig")
local DiaryConfig = shared("DiaryConfig")
local SMProfile = shared("SMProfile")
local Net = shared("Net")
local Notify = shared("Notify")

local RewardsService = {}

local ClaimDaily = Net.Function("ClaimDaily")
local ClaimQuest = Net.Function("ClaimQuest")
local DiaryFound = Net.Event("DiaryFound") -- (pageIndex)

local function today(): number
	return DataService:Today()
end

-- ---------------------------------------------------------------- Daily mailbox

function RewardsService:CanClaimDaily(player: Player): boolean
	local d = DataService:Get(player, "Daily")
	return d ~= nil and d.LastClaimDay < today()
end

local function claimDaily(player: Player)
	if not RewardsService:CanClaimDaily(player) then
		return false, "Come back tomorrow!"
	end
	local d = DataService:Get(player, "Daily")
	local streak = if d.LastClaimDay == today() - 1 then d.Streak + 1 else 1
	if streak > #EconomyConfig.DailyRewards then
		streak = 1
	end
	local reward = EconomyConfig.DailyRewards[streak]
	DataService:Update(player, "Daily", function(v)
		v.LastClaimDay = today()
		v.Streak = streak
		return v
	end)
	DataService:AddCandy(player, reward.Candy)
	if reward.Item then
		local item = EconomyConfig.Items[reward.Item]
		DataService:AddItem(player, reward.Item, reward.ItemCount or 1, item and item.Max)
	end
	return true, streak
end

-- ---------------------------------------------------------------- Quests

local function rollQuests(player: Player)
	local q = DataService:Get(player, "Quests")
	if q and q.Day == today() then
		return
	end
	local pool = {}
	for id in EconomyConfig.Quests do
		table.insert(pool, id)
	end
	table.sort(pool)
	local rng = Random.new(player.UserId + today() * 7919)
	local list = {}
	for _ = 1, math.min(EconomyConfig.QuestsPerDay, #pool) do
		local id = table.remove(pool, rng:NextInteger(1, #pool))
		local def = EconomyConfig.Quests[id]
		local tier = rng:NextInteger(1, #def.Targets)
		table.insert(list, { Id = id, Target = def.Targets[tier], Reward = def.Reward[tier], Progress = 0, Claimed = false })
	end
	DataService:Update(player, "Quests", function()
		return { Day = today(), List = list }
	end)
end

function RewardsService:QuestProgress(player: Player, questId: string, amount: number?)
	if not DataService:IsLoaded(player) then
		return
	end
	rollQuests(player)
	local completedNow: { string } = {}
	DataService:Update(player, "Quests", function(q)
		for _, quest in q.List do
			if quest.Id == questId and quest.Progress < quest.Target then
				quest.Progress = math.min(quest.Target, quest.Progress + (amount or 1))
				if quest.Progress >= quest.Target then
					table.insert(completedNow, quest.Id)
				end
			end
		end
		return q
	end)
	for _ in completedNow do
		Notify.Toast(player, "Quest complete! Claim it in the lobby.", "Good")
	end
end

local function claimQuest(player: Player, index: number)
	if typeof(index) ~= "number" then
		return false
	end
	local q = DataService:Get(player, "Quests")
	local quest = q and q.List[index]
	if not quest or quest.Claimed or quest.Progress < quest.Target then
		return false
	end
	DataService:Update(player, "Quests", function(v)
		v.List[index].Claimed = true
		return v
	end)
	DataService:AddCandy(player, quest.Reward)
	return true, quest.Reward
end

-- ---------------------------------------------------------------- Achievements

local function statValue(player: Player, stat: string): number
	if stat == "HighestNight" or stat == "Wins" or stat == "TotalCandy" then
		return DataService:Get(player, stat) or 0
	end
	return DataService:GetStat(player, stat)
end

function RewardsService:CheckAchievements(player: Player)
	if not DataService:IsLoaded(player) then
		return
	end
	local have = DataService:Get(player, "Achievements")
	for id, a in AchievementConfig do
		if not have[id] and statValue(player, a.Stat) >= a.Target then
			DataService:Update(player, "Achievements", function(v)
				v[id] = true
				return v
			end)
			if a.Candy and a.Candy > 0 then
				DataService:AddCandy(player, a.Candy)
			end
			if a.Cosmetics then
				for _, c in a.Cosmetics do
					DataService:UnlockCosmetic(player, c[1], c[2])
				end
			end
			if a.BadgeId and a.BadgeId ~= 0 then
				task.spawn(pcall, BadgeService.AwardBadge, BadgeService, player.UserId, a.BadgeId)
			end
			Notify.Toast(player, `🏆 {a.Name}` .. (if a.Candy and a.Candy > 0 then ` +{a.Candy} 🍬` else ""), "Candy")
		end
	end
end

-- ---------------------------------------------------------------- Diary

-- Returns the index of a page this player hasn't found and that fits the night, or nil.
function RewardsService:PickDiaryPage(night: number, players: { Player }): number?
	local candidates = {}
	for i, page in DiaryConfig do
		if page.MinNight <= night then
			for _, p in players do
				local diary = DataService:Get(p, "Diary")
				if diary and not diary[tostring(i)] then
					table.insert(candidates, i)
					break
				end
			end
		end
	end
	if #candidates == 0 then
		return nil
	end
	-- Prefer the earliest missing page so the story reads in order.
	table.sort(candidates)
	return candidates[1]
end

function RewardsService:GrantDiary(player: Player, index: number)
	local diary = DataService:Get(player, "Diary")
	if not diary or diary[tostring(index)] then
		DiaryFound:FireClient(player, index, false)
		return
	end
	DataService:Update(player, "Diary", function(v)
		v[tostring(index)] = true
		return v
	end)
	local count = 0
	for _ in DataService:Get(player, "Diary") do
		count += 1
	end
	DataService:Update(player, "Stats", function(s)
		s.DiaryPages = count
		return s
	end)
	DiaryFound:FireClient(player, index, true)
	RewardsService:CheckAchievements(player)
end

-- ---------------------------------------------------------------- Friends & referrals

-- Friends of this player currently in the server (tracked by VIDK SMSocial).
function RewardsService:CountFriendsIn(player: Player, _others: { Player }?): number
	local ok, n = pcall(function()
		return shared("SMSocial"):GetFriendCount(player)
	end)
	return if ok then n else 0
end

function RewardsService:FriendMultiplier(friendCount: number): number
	return 1 + math.min(EconomyConfig.FriendBonusMax, friendCount * EconomyConfig.FriendBonusPerFriend)
end

-- Daily buddy bonus: first night each day played with at least one friend.
function RewardsService:TryBuddyBonus(player: Player)
	local social = DataService:Get(player, "Social")
	if not social or social.LastBuddyDay == today() then
		return
	end
	DataService:Update(player, "Social", function(s)
		s.LastBuddyDay = today()
		return s
	end)
	DataService:AddCandy(player, EconomyConfig.BuddyBonusDaily)
	Notify.Toast(player, `Buddy Bonus! +{EconomyConfig.BuddyBonusDaily} 🍬 for playing with a friend`, "Candy")
end

local function checkReferral(player: Player)
	local social = DataService:Get(player, "Social")
	if not social or social.Referred then
		return
	end
	local ok, joinData = pcall(player.GetJoinData, player)
	local launch = ok and joinData and joinData.LaunchData
	local inviterId = tonumber(launch)
	local isNew = (DataService:GetStat(player, "NightsPlayed") == 0) and (DataService:Get(player, "TotalCandy") or 0) == 0
	if not inviterId or inviterId == player.UserId or not isNew then
		return
	end
	DataService:Update(player, "Social", function(s)
		s.Referred = true
		return s
	end)
	DataService:AddCandy(player, EconomyConfig.ReferralNewPlayer)
	Notify.Toast(player, `A friend invited you! +{EconomyConfig.ReferralNewPlayer} 🍬`, "Candy")
	task.spawn(function()
		SMProfile:SendMessage(inviterId, { sAction = "ReferralReward", sItemId = "", nSenderId = player.UserId, tProps = {} })
	end)
end

function RewardsService:GrantReferralInviter(player: Player, _friendId: number)
	DataService:AddCandy(player, EconomyConfig.ReferralInviter)
	DataService:Update(player, "Social", function(s)
		s.InvitesRewarded = (s.InvitesRewarded or 0) + 1
		return s
	end)
	Notify.Toast(player, `Your friend joined! +{EconomyConfig.ReferralInviter} 🍬`, "Candy")
end

-- ---------------------------------------------------------------- Lifecycle

function RewardsService.Preload() end

function RewardsService:Start()
	ClaimDaily.OnServerInvoke = function(player)
		if not Net.RateLimit(player, "ClaimDaily", 1) then
			return false
		end
		return claimDaily(player)
	end
	ClaimQuest.OnServerInvoke = function(player, index)
		if not Net.RateLimit(player, "ClaimQuest", 2) then
			return false
		end
		return claimQuest(player, index)
	end

	local function onLoaded(player: Player)
		player:SetAttribute("Candy", DataService:GetCandy(player))
		if shared("PlaceRole").IsLobby and DataService:GetStat(player, "NightsPlayed") == 0 then
			shared("Analytics").Onboarding(player, "Lobby")
		end
		rollQuests(player)
		checkReferral(player)
		RewardsService:CheckAchievements(player)
	end
	DataService.PlayerLoaded:Connect(onLoaded)
	for _, p in Players:GetPlayers() do
		if DataService:IsLoaded(p) then
			task.spawn(onLoaded, p)
		end
	end
end

return RewardsService
