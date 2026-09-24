--!strict
-- Net
-- Tiny remote registry. The server creates remotes on demand; clients wait for them.
--   Net.Event(name)    -> RemoteEvent
--   Net.Function(name) -> RemoteFunction
--   Net.Unreliable(name) -> UnreliableRemoteEvent (for cosmetic spam like noise ripples)
--   Net.RateLimit(player, key, maxPerSecond) -> boolean (server only)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local IS_SERVER = RunService:IsServer()

local Net = {}

local folder: Folder
if IS_SERVER then
	folder = ReplicatedStorage:FindFirstChild("Remotes") :: Folder
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

local function get(name: string, className: string): any
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing
	end
	if IS_SERVER then
		local r = Instance.new(className)
		r.Name = name
		r.Parent = folder
		return r
	end
	return folder:WaitForChild(name)
end

function Net.Event(name: string): RemoteEvent
	return get(name, "RemoteEvent")
end

function Net.Function(name: string): RemoteFunction
	return get(name, "RemoteFunction")
end

function Net.Unreliable(name: string): UnreliableRemoteEvent
	return get(name, "UnreliableRemoteEvent")
end

-- Token bucket per player per key.
local buckets: { [Player]: { [string]: { tokens: number, last: number } } } = {}

function Net.RateLimit(player: Player, key: string, maxPerSecond: number): boolean
	local pb = buckets[player]
	if not pb then
		pb = {}
		buckets[player] = pb
	end
	local now = os.clock()
	local b = pb[key]
	if not b then
		b = { tokens = maxPerSecond, last = now }
		pb[key] = b
	end
	b.tokens = math.min(maxPerSecond, b.tokens + (now - b.last) * maxPerSecond)
	b.last = now
	if b.tokens < 1 then
		return false
	end
	b.tokens -= 1
	return true
end

if IS_SERVER then
	Players.PlayerRemoving:Connect(function(p)
		buckets[p] = nil
	end)
end

return Net
