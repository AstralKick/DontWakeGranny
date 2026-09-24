-- NightmareHouse contract validation (adapted from house_10_validate): counts every MAP_CONTRACT element, checks
-- attributes and area consistency, plus the multi-map rules (MapId, names, 5 pumpkins, hiding totals, part budget). Read-only.
local CS = game:GetService("CollectionService")
local H = workspace:FindFirstChild("Maps") and workspace.Maps:FindFirstChild("NightmareHouse")
assert(H, "no Workspace.Maps.NightmareHouse")
local out, errs = {}, {}
local function err(s) table.insert(errs, s) end
local AREAS = { Ground = true, Upstairs = true, Basement = true, Attic = true }
local rooms = H.Rooms:GetChildren()
local function roomAt(pos)
	for _, r in rooms do
		local rel = r.CFrame:PointToObjectSpace(pos)
		local h = r.Size / 2
		if math.abs(rel.X) <= h.X + 0.05 and math.abs(rel.Y) <= h.Y + 0.6 and math.abs(rel.Z) <= h.Z + 0.05 then return r end
	end
	return nil
end
local function checkArea(inst, pos, label)
	local a = inst:GetAttribute("Area")
	if not AREAS[a] then err(label .. " bad Area " .. inst:GetFullName()) return end
	local r = roomAt(pos)
	if not r then err(label .. " outside every Room: " .. inst:GetFullName() .. " @" .. tostring(pos)) return end
	if r:GetAttribute("Area") ~= a then err(label .. " Area " .. a .. " but in room " .. r.Name .. " (" .. r:GetAttribute("Area") .. ")") end
	return r
end
-- rooms
local byArea = {}
for _, r in rooms do
	if not (r:GetAttribute("RoomName") and AREAS[r:GetAttribute("Area")] and r:GetAttribute("Danger")) then err("room attrs " .. r.Name) end
	if r.Transparency ~= 1 or r.CanCollide or r.CanQuery or r.CanTouch then err("room helper flags " .. r.Name) end
	byArea[r:GetAttribute("Area")] = (byArea[r:GetAttribute("Area")] or 0) + 1
end
table.insert(out, ("Rooms: %d (G %d, U %d, B %d, A %d)"):format(#rooms, byArea.Ground or 0, byArea.Upstairs or 0, byArea.Basement or 0, byArea.Attic or 0))
-- loot / prize
local lootA = {}
for _, p in H.LootSpawns:GetChildren() do
	local r = checkArea(p, p.Position, "Loot")
	if r and p:GetAttribute("Danger") ~= r:GetAttribute("Danger") then err("Loot danger mismatch in " .. r.Name) end
	if type(p:GetAttribute("Danger")) ~= "number" then err("loot no danger") end
	lootA[p:GetAttribute("Area")] = (lootA[p:GetAttribute("Area")] or 0) + 1
end
table.insert(out, ("LootSpawns: %d (G %d, U %d, B %d, A %d)"):format(#H.LootSpawns:GetChildren(), lootA.Ground or 0, lootA.Upstairs or 0, lootA.Basement or 0, lootA.Attic or 0))
for _, p in H.PrizeSpawns:GetChildren() do checkArea(p, p.Position, "Prize") end
table.insert(out, "PrizeSpawns: " .. #H.PrizeSpawns:GetChildren())
-- searchables
local kinds = { Drawer = 0, Cabinet = 0, Fridge = 0, ToyChest = 0, Vanity = 0, Trunk = 0 }
for _, p in CS:GetTagged("Searchable") do
	if p:IsDescendantOf(H) then
		local k = p:GetAttribute("Kind")
		if kinds[k] == nil then err("Searchable bad Kind " .. p:GetFullName()) else kinds[k] += 1 end
		checkArea(p, p.Position, "Searchable")
		if type(p:GetAttribute("Danger")) ~= "number" then err("Searchable no Danger " .. p:GetFullName()) end
		if not p:IsA("BasePart") then err("Searchable not a part") end
	end
end
local ns = 0
for _, v in kinds do ns += v end
table.insert(out, ("Searchables: %d (Drawer %d, Cabinet %d, Fridge %d, ToyChest %d, Vanity %d, Trunk %d)"):format(ns, kinds.Drawer, kinds.Cabinet, kinds.Fridge, kinds.ToyChest, kinds.Vanity, kinds.Trunk))
-- doors
local nd, sq, lk = 0, 0, 0
for _, m in CS:GetTagged("Door") do
	if m:IsDescendantOf(H) then
		nd += 1
		local hinge, panel = m:FindFirstChild("Hinge"), m:FindFirstChild("Panel")
		if not (m:IsA("Model") and hinge and panel and m.PrimaryPart == hinge) then err("Door structure " .. m:GetFullName()) end
		if panel and not (panel:FindFirstChildOfClass("PathfindingModifier") and panel:FindFirstChildOfClass("PathfindingModifier").PassThrough) then err("Door modifier " .. m.Name) end
		if panel and not panel.CanCollide then err("Door panel not collidable " .. m.Name) end
		if type(m:GetAttribute("Squeaky")) ~= "boolean" or type(m:GetAttribute("Lockable")) ~= "boolean" or not AREAS[m:GetAttribute("Area")] then err("Door attrs " .. m.Name) end
		if m:GetAttribute("Squeaky") then sq += 1 end
		if m:GetAttribute("Lockable") then lk += 1 end
	end
end
if not (H:FindFirstChild("FrontDoor") and CS:HasTag(H.FrontDoor, "Door")) then err("FrontDoor missing") end
table.insert(out, ("Doors: %d (squeaky %d, lockable %d)"):format(nd, sq, lk))
-- hiding spots
local hk, nh = {}, 0
for _, m in CS:GetTagged("HidingSpot") do
	if m:IsDescendantOf(H) then
		nh += 1
		local ins, fr, ex = m:FindFirstChild("Inside", true), m:FindFirstChild("Front", true), m:FindFirstChild("Exit", true)
		if not (ins and fr and ex) then err("HidingSpot parts " .. m:GetFullName()) else
			checkArea(m, fr.Position, "HidingSpot")
			if fr.Transparency < 1 or ins.Transparency < 1 or ex.Transparency < 1 then err("HidingSpot helper visible (name clash?) " .. m:GetFullName()) end
		end
		local k = m:GetAttribute("Kind")
		if not ({ Wardrobe = 1, Bed = 1, Closet = 1, Cabinet = 1 })[k] then err("HidingSpot Kind " .. m.Name) end
		hk[k] = (hk[k] or 0) + 1
	end
end
table.insert(out, ("HidingSpots: %d (Wardrobe %d, Bed %d, Closet %d, Cabinet %d)"):format(nh, hk.Wardrobe or 0, hk.Bed or 0, hk.Closet or 0, hk.Cabinet or 0))
-- creaky / breakable
local nc = 0
for _, p in CS:GetTagged("Creaky") do
	if p:IsDescendantOf(H) then
		nc += 1
		if not (p.CanCollide and p.CanTouch) then err("Creaky flags") end
		if not roomAt(p.Position + Vector3.new(0, 1, 0)) then err("Creaky outside rooms @" .. tostring(p.Position)) end
	end
end
table.insert(out, "Creaky: " .. nc)
local nb = 0
for _, b in CS:GetTagged("Breakable") do
	if b:IsDescendantOf(H) then
		nb += 1
		local p = if b:IsA("Model") then b.PrimaryPart else b
		if not (p and p.CanTouch and p.CanCollide) then err("Breakable flags " .. b:GetFullName()) end
	end
end
table.insert(out, "Breakables: " .. nb)
-- lamps
local nl, shadows, la = 0, 0, {}
for _, l in CS:GetTagged("Lamp") do
	if l:IsDescendantOf(H) then
		nl += 1
		local bulb = l:FindFirstChild("Bulb", true)
		local light = l:FindFirstChildWhichIsA("Light", true)
		if not (bulb and bulb.Material == Enum.Material.Neon and light) then err("Lamp structure " .. l:GetFullName()) end
		if light and light.Shadows then shadows += 1 end
		if not AREAS[l:GetAttribute("Area")] then err("Lamp area " .. l:GetFullName()) end
		la[l:GetAttribute("Area")] = (la[l:GetAttribute("Area")] or 0) + 1
	end
end
table.insert(out, ("Lamps: %d (shadows %d; G %d, U %d, B %d, A %d)"):format(nl, shadows, la.Ground or 0, la.Upstairs or 0, la.Basement or 0, la.Attic or 0))
-- search nodes
local nn, bath, na = 0, 0, {}
for _, p in H.SearchNodes:GetChildren() do
	nn += 1
	checkArea(p, p.Position, "SearchNode")
	if p:GetAttribute("Bathroom") then
		bath += 1
		local r = roomAt(p.Position)
		if not r or r.Name ~= "Bathroom" then err("Bathroom node not in ground bathroom") end
	end
	na[p:GetAttribute("Area")] = (na[p:GetAttribute("Area")] or 0) + 1
end
if bath ~= 1 then err("Bathroom nodes = " .. bath) end
-- every room has at least one node
for _, r in rooms do
	local has = false
	for _, p in H.SearchNodes:GetChildren() do if roomAt(p.Position) == r then has = true break end end
	if not has then err("Room without SearchNode: " .. r.Name) end
end
table.insert(out, ("SearchNodes: %d (G %d, U %d, B %d, A %d), Bathroom=true: %d"):format(nn, na.Ground or 0, na.Upstairs or 0, na.Basement or 0, na.Attic or 0, bath))
-- singletons
local ss, gc = H:FindFirstChild("GrandmaSleepSpot"), H:FindFirstChild("GrandmaChair")
if not (ss and ss:IsA("BasePart") and gc) then err("GrandmaSleepSpot/GrandmaChair") end
if not (H:FindFirstChild("FuseBox") and H.FuseBox:IsA("BasePart")) then err("FuseBox") end
local car = H:FindFirstChild("MomsCar")
if not (car and car:FindFirstChild("Trunk") and car.Trunk:IsA("BasePart")) then err("MomsCar.Trunk") end
local pa = {}
for _, p in H.PumpkinSpots:GetChildren() do pa[p:GetAttribute("Area")] = (pa[p:GetAttribute("Area")] or 0) + 1 checkArea(p, p.Position, "Pumpkin") end
for a in AREAS do if not pa[a] then err("No PumpkinSpot in " .. a) end end
table.insert(out, ("PumpkinSpots: %d (G %d, U %d, B %d, A %d)"):format(#H.PumpkinSpots:GetChildren(), pa.Ground or 0, pa.Upstairs or 0, pa.Basement or 0, pa.Attic or 0))
local bars = {}
for _, b in H.Barriers:GetChildren() do bars[b:GetAttribute("Area") or "?"] = b.Name end
for _, a in { "Upstairs", "Basement", "Attic" } do if not bars[a] then err("No Barrier for " .. a) end end
table.insert(out, "Barriers: " .. #H.Barriers:GetChildren())
table.insert(out, "PlayerSpawns: " .. #H.PlayerSpawns:GetChildren())
local cc = {}
for i = 1, 4 do
	local f = H.Corruption:FindFirstChild(tostring(i))
	local n = 0
	if f then for _, d in f:GetDescendants() do if d:IsA("BasePart") then n += 1 if d.CanCollide then err("Corruption part collides " .. d:GetFullName()) end end end else err("Corruption/" .. i) end
	table.insert(cc, tostring(n))
end
table.insert(out, "Corruption parts per level: " .. table.concat(cc, "/"))
local parts, unanch = 0, 0
for _, d in H:GetDescendants() do
	if d:IsA("BasePart") then
		parts += 1
		if not d.Anchored then unanch += 1 end
	end
end
table.insert(out, ("Parts: %d (unanchored %d)"):format(parts, unanch))
local scripts = 0
for _, d in H:GetDescendants() do if d:IsA("LuaSourceContainer") then scripts += 1 end end
table.insert(out, "Scripts inside House: " .. scripts)
-- multi-map rules
if H.Name == "House" then err("map model must not be named House") end
if H:GetAttribute("MapId") ~= "NightmareHouse" then err("MapId") end
if H:GetAttribute("DisplayName") ~= "The House That Grandma Built" then err("DisplayName") end
if H:GetAttribute("AreaName_Upstairs") ~= "THE WRONG STAIRS" or H:GetAttribute("AreaName_Basement") ~= "THE ROOTS" or H:GetAttribute("AreaName_Attic") ~= "THE NURSERY" then err("AreaName_* attributes") end
if #H.PumpkinSpots:GetChildren() ~= 5 then err("PumpkinSpots must be exactly 5") end
if nh < 16 then err("HidingSpots < 16") end
local hg = 0
for _, m in CS:GetTagged("HidingSpot") do if m:IsDescendantOf(H) and m:GetAttribute("Area") == "Ground" then hg += 1 end end
if hg < 5 then err("Ground HidingSpots < 5") end
if #H.PrizeSpawns:GetChildren() < 6 then err("PrizeSpawns < 6") end
if parts > 7000 then err("part budget: " .. parts) end
if H:FindFirstChild("_WorkLight") then err("temporary _WorkLight still in the map") end
local pos = H:GetPivot().Position
table.insert(out, ("MapId %s, pivot X %.0f, ground HidingSpots %d"):format(tostring(H:GetAttribute("MapId")), pos.X, hg))
table.insert(out, "ERRORS (" .. #errs .. "):")
for i = 1, math.min(#errs, 40) do table.insert(out, "  " .. errs[i]) end
return table.concat(out, "\n")
