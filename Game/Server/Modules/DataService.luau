--!strict
-- DataService
-- Game-side helpers over VIDK's data stack. It stores nothing itself:
--   * SMProfile (ProfileStore, session-locked) holds the data; defaults come from
--     Config/ProfileTemplate and are reconciled by ProfileStore on load.
--   * SMCurrency holds Candy ("SoftCurrency").
--   * The "PlayerData" Replica mirrors the ProfileTemplate keys privately to their owner
--     (same pattern as SMCurrency's "Currency" replica). SMProfile:Modify keeps it in sync.
-- What this module adds: a PlayerLoaded signal / WaitForData, and shared helpers
-- (AddCandy, TrySpend, IncStat, AddItem, ...) so services don't re-implement them.

local Players = game:GetService("Players")

local SMProfile = shared("SMProfile")
local SMCurrency = shared("SMCurrency")
local ReplicaServer = shared("ReplicaServer")
local ProfileTemplate = shared("ProfileTemplate")

local DataService = {}

local loaded: { [Player]: boolean } = {}
local loadedEvent = Instance.new("BindableEvent")
DataService.PlayerLoaded = loadedEvent.Event -- (player)

local token = ReplicaServer.Token("PlayerData")

function DataService.Preload() end
function DataService:Start() end

-- Called by VIDK SMProfile once the profile session is live (already reconciled).
function DataService.InitProfile(player: Player, replicas: { [string]: any })
	local data = {}
	for key in ProfileTemplate do
		data[key] = SMProfile:Get(player, key)
	end
	local replica = ReplicaServer.New({ Token = token, Data = data })
	replica:Subscribe(player)
	replicas.PlayerData = replica

	loaded[player] = true
	player:SetAttribute("DataLoaded", true)
	loadedEvent:Fire(player)
end

Players.PlayerRemoving:Connect(function(p)
	loaded[p] = nil
end)

function DataService:IsLoaded(player: Player): boolean
	return loaded[player] == true
end

-- Yields until loaded (or timeout). Returns true if loaded.
function DataService:WaitForData(player: Player, timeout: number?): boolean
	local t0 = os.clock()
	while not loaded[player] do
		if player.Parent ~= Players or os.clock() - t0 > (timeout or 30) then
			return false
		end
		task.wait(0.1)
	end
	return true
end

-- Read a top-level key. Treat returned tables as READ-ONLY; write through Update.
function DataService:Get(player: Player, key: string): any
	if not loaded[player] then
		return nil
	end
	return SMProfile:Get(player, key)
end

-- Mutate a top-level key. fn receives the current value and returns the new one.
-- Tables may be mutated in place and returned.
function DataService:Update(player: Player, key: string, fn: (any) -> any)
	if not loaded[player] then
		return
	end
	SMProfile:Modify(player, key, fn, "PlayerData")
end

-- ---------------------------------------------------------------- Candy (VIDK SMCurrency)

function DataService:GetCandy(player: Player): number
	local raw = SMProfile:Get(player, "SoftCurrency")
	return tonumber(tostring(raw or 0)) or 0
end

function DataService:AddCandy(player: Player, amount: number): number
	amount = math.floor(amount)
	if amount <= 0 or not loaded[player] then
		return 0
	end
	SMCurrency:AddCurrency(player, "SoftCurrency", amount)
	self:Update(player, "TotalCandy", function(v)
		return (v or 0) + amount
	end)
	player:SetAttribute("Candy", self:GetCandy(player))
	return amount
end

function DataService:TrySpend(player: Player, amount: number): boolean
	amount = math.floor(amount)
	if amount < 0 or not loaded[player] then
		return false
	end
	local ok = SMCurrency:Transaction(player, "SoftCurrency", amount)
	player:SetAttribute("Candy", self:GetCandy(player))
	return ok
end

function DataService:IncStat(player: Player, stat: string, n: number?)
	self:Update(player, "Stats", function(stats)
		stats[stat] = (stats[stat] or 0) + (n or 1)
		return stats
	end)
end

function DataService:SetStatMax(player: Player, stat: string, value: number)
	self:Update(player, "Stats", function(stats)
		stats[stat] = math.max(stats[stat] or 0, value)
		return stats
	end)
end

function DataService:GetStat(player: Player, stat: string): number
	local stats = self:Get(player, "Stats")
	return stats and stats[stat] or 0
end

function DataService:AddItem(player: Player, item: string, n: number, max: number?)
	self:Update(player, "Items", function(items)
		items[item] = math.clamp((items[item] or 0) + n, 0, max or 99)
		return items
	end)
end

function DataService:UnlockCosmetic(player: Player, slot: string, id: string)
	self:Update(player, "Cosmetics", function(c)
		c.Owned[slot] = c.Owned[slot] or {}
		c.Owned[slot][id] = true
		return c
	end)
end

-- UTC day number, used for daily systems.
function DataService:Today(): number
	return math.floor(os.time() / 86400)
end

return DataService
