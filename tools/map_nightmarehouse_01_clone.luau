-- NightmareHouse step 1: (re)clone Workspace.House (read-only reference) into Workspace.Maps.NightmareHouse at X+7500.
-- Idempotent: deletes the old NightmareHouse first. Run house_00_lib + house_01_props first (for _G.HB), then
-- map_nightmarehouse_00_lib, then 01..N in order.
local CS = game:GetService("CollectionService")
local OX = 7500
local src = workspace:FindFirstChild("House")
assert(src, "Workspace.House missing")
local maps = workspace:FindFirstChild("Maps")
if not maps then
	maps = Instance.new("Folder")
	maps.Name = "Maps"
	maps.Parent = workspace
end
local old = maps:FindFirstChild("NightmareHouse")
if old then old:Destroy() end
local m = src:Clone()
m.Name = "NightmareHouse"
-- Corruption from the base house is removed; this map's own Corruption/1..4 extras are built later.
local cor = m:FindFirstChild("Corruption")
if cor then cor:ClearAllChildren() end
for i = 1, 4 do
	local f = Instance.new("Folder")
	f.Name = tostring(i)
	f.Parent = cor
end
m:PivotTo(src:GetPivot() + Vector3.new(OX, 0, 0))
m:SetAttribute("MapId", "NightmareHouse")
m:SetAttribute("DisplayName", "The House That Grandma Built")
m:SetAttribute("AreaName_Upstairs", "THE WRONG STAIRS")
m:SetAttribute("AreaName_Basement", "THE ROOTS")
m:SetAttribute("AreaName_Attic", "THE NURSERY")
m.Parent = maps
-- verify tags copied
local cnt = {}
for _, t in { "Door", "HidingSpot", "Searchable", "Creaky", "Breakable", "Lamp" } do
	local n = 0
	for _, i in CS:GetTagged(t) do if i:IsDescendantOf(m) then n += 1 end end
	table.insert(cnt, t .. "=" .. n)
end
local parts = 0
for _, d in m:GetDescendants() do if d:IsA("BasePart") then parts += 1 end end
return "cloned; " .. table.concat(cnt, " ") .. " parts=" .. parts .. " pivot=" .. tostring(m:GetPivot().Position)
