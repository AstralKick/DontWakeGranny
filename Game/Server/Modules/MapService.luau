--!strict
-- MapService (Match)
-- One map per chapter (Game/Config/MapConfig.luau). In Studio the maps sit in the place:
-- the original house at Workspace.House (MapId GrandmasHouse) and the rest at
-- Workspace.Maps/<MapId>. At server start every map is moved into ServerStorage.MapTemplates;
-- the chapter's map is then CLONED into Workspace as "House", so every system keeps finding
-- Workspace.House. Swapping chapters destroys the old clone (which also drops every prompt
-- and connection the services made on it) and fires MapChanged so services rebind.
--
--   MapService:EnsureFor(night) -> boolean   (true if the map changed)
--   MapService:GetHouse() / GetMapId() / GetChapter()
--   MapService:Owns(inst) -> boolean          inst belongs to the active map (tag filters)
--   MapService:OnChanged(fn(house, chapter))  services rebind here (runs synchronously)
--   MapService.MapChanged                     (house, chapter) deferred notification

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlaceRole = shared("PlaceRole")
local MapConfig = shared("MapConfig")

local MapService = {}

-- Rebind callbacks run synchronously inside EnsureFor (a BindableEvent would be deferred and
-- fire after the night was already prepared on the old map).
local callbacks: { (Instance, any) -> () } = {}
function MapService:OnChanged(fn: (Instance, any) -> ())
	table.insert(callbacks, fn)
end

local mapChanged = Instance.new("BindableEvent")
MapService.MapChanged = mapChanged.Event

local templates: Folder? = nil
local house: Instance? = nil
local mapId: string? = nil

local function collectTemplates()
	local folder = Instance.new("Folder")
	folder.Name = "MapTemplates"
	folder.Parent = ServerStorage
	templates = folder

	local original = workspace:FindFirstChild("House")
	if original then
		original:SetAttribute("MapId", original:GetAttribute("MapId") or "GrandmasHouse")
		original.Name = original:GetAttribute("MapId") :: string
		original.Parent = folder
	end
	local maps = workspace:FindFirstChild("Maps")
	if maps then
		for _, m in maps:GetChildren() do
			local id = m:GetAttribute("MapId")
			if typeof(id) == "string" and id ~= "" then
				m.Name = id
				m.Parent = folder
			else
				warn("[Map] Workspace.Maps." .. m.Name .. " has no MapId attribute; ignored")
			end
		end
		maps:Destroy()
	end
end

local function templateFor(id: string): Instance?
	local t = templates and templates:FindFirstChild(id)
	if t then
		return t
	end
	-- A chapter whose map isn't built yet falls back to the original house.
	warn("[Map] no map for " .. id .. "; using GrandmasHouse")
	return templates and templates:FindFirstChild("GrandmasHouse")
end

function MapService:GetHouse(): Instance?
	return house
end

function MapService:GetMapId(): string?
	return mapId
end

function MapService:GetChapter(): any
	return mapId and MapConfig.ByMapId(mapId) or MapConfig.Chapters[1]
end

function MapService:Owns(inst: Instance): boolean
	return house ~= nil and inst:IsDescendantOf(house)
end

local function load(id: string): boolean
	if id == mapId and house and house.Parent then
		return false
	end
	local template = templateFor(id)
	if not template then
		return false
	end
	local old = house
	if old then
		old.Name = "HouseOld"
	end
	local clone = template:Clone()
	clone.Name = "House"
	clone:SetAttribute("MapId", id)
	clone.Parent = workspace
	house = clone
	mapId = id

	-- Park characters on the new map's spawns before the old floor disappears.
	local spawns = clone:FindFirstChild("PlayerSpawns")
	local list = spawns and spawns:GetChildren() or {}
	for i, p in Players:GetPlayers() do
		local char = p.Character
		local sp = list[((i - 1) % math.max(1, #list)) + 1]
		if char and sp and sp:IsA("BasePart") then
			char:PivotTo(sp.CFrame + Vector3.new(0, 3, 0))
		end
	end
	if old then
		old:Destroy()
	end
	local chapter = MapService:GetChapter()
	for _, fn in callbacks do
		local ok, err = pcall(fn, clone, chapter)
		if not ok then
			warn("[Map] rebind failed:", err)
		end
	end
	mapChanged:Fire(clone, chapter)
	return true
end

function MapService:EnsureFor(night: number): boolean
	local changed = load(MapConfig.ChapterFor(night).MapId)
	local ms = ReplicatedStorage:FindFirstChild("MatchState")
	if ms and mapId then
		ms:SetAttribute("MapId", mapId)
		ms:SetAttribute("MapName", MapService:GetChapter().Name)
	end
	return changed
end

function MapService.Preload()
	if not PlaceRole.IsMatch then
		return
	end
	collectTemplates()
	-- Services grab Workspace.House in :Start(); give them the first chapter's map (or the
	-- Studio test night's) now, before anything starts.
	local n = tonumber(workspace:GetAttribute("DebugStartNight")) or 1
	load(MapConfig.ChapterFor(n).MapId)
end

function MapService:Start() end

return MapService
