--!strict
-- DataController
-- Client view of the player's persistent data (server "PlayerData" replica, read-only)
-- and Candy (VIDK LMCurrency "Currency" replica, SoftCurrency).
--   DataController:Get(key)            -> current value (tables are read-only!)
--   DataController:GetCandy()          -> number
--   DataController.Changed:Connect(fn(key, value))   fired for any top-level key ("Candy" too)
--   DataController:WaitReady()

local ReplicaClient = shared("ReplicaClient")

local DataController = {}

local changed = Instance.new("BindableEvent")
DataController.Changed = changed.Event

local replica: any = nil
local ready = false
local readyEvent = Instance.new("BindableEvent")

function DataController.Preload()
	ReplicaClient.OnNew("PlayerData", function(r)
		replica = r
		r:OnChange(function(_action, path)
			local key = path[1]
			if key then
				changed:Fire(key, r.Data[key])
			end
		end)
		ready = true
		readyEvent:Fire()
	end)
	-- Candy lives in VIDK's Currency replica.
	local LMCurrency = shared("LMCurrency")
	LMCurrency.CurrencyChanged.Event:Connect(function(kind, newValue)
		if kind == "SoftCurrency" then
			changed:Fire("Candy", tonumber(tostring(newValue)) or 0)
		end
	end)
	ReplicaClient.RequestData()
end

function DataController:Start() end

function DataController:WaitReady()
	if not ready then
		readyEvent.Event:Wait()
	end
end

function DataController:IsReady(): boolean
	return ready
end

function DataController:Get(key: string): any
	return replica and replica.Data[key]
end

function DataController:GetCandy(): number
	local LMCurrency = shared("LMCurrency")
	local r = LMCurrency:GetReplica()
	local v = r and r.Data.SoftCurrency
	return tonumber(tostring(v or 0)) or 0
end

return DataController
