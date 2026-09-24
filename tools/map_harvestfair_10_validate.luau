-- HarvestFair contract validation (adapted from house_10_validate). Read-only.
-- Counts every MAP_CONTRACT element under Workspace.Maps.HarvestFair, checks attributes, area consistency,
-- room overlaps, light budget, map attributes. Returns a text report.
local CS = game:GetService("CollectionService")
local H = workspace:FindFirstChild("Maps") and workspace.Maps:FindFirstChild("HarvestFair")
assert(H, "no Workspace.Maps.HarvestFair")
local out, errs = {}, {}
local function err(s) table.insert(errs, s) end
local AREAS = { Ground = true, Upstairs = true, Basement = true, Attic = true }
local function inMap(i) return i:IsDescendantOf(H) end
-- map attributes
for k, v in { MapId = "HarvestFair", DisplayName = "The Harvest Fair", AreaName_Upstairs = "THE FUNHOUSE", AreaName_Basement = "THE GHOST TRAIN", AreaName_Attic = "THE BIG TOP" } do
	if H:GetAttribute(k) ~= v then err("map attr " .. k .. " = " .. tostring(H:GetAttribute(k))) end
end
if not H:IsA("Model") then err("map root is not a Model") end
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
	if not r then err(label .. " outside every Room: " .. inst:GetFullName() .. " @" .. tostring(pos - Vector3.new(6000, 0, 0))) return end
	if r:GetAttribute("Area") ~= a then err(label .. " Area " .. a .. " but in room " .. r.Name .. " (" .. r:GetAttribute("Area") .. ")") end
	return r
end
-- rooms + overlaps
local byArea = {}
for _, r in rooms do
	if not (r:GetAttribute("RoomName") and AREAS[r:GetAttribute("Area")] and type(r:GetAttribute("Danger")) == "number") then err("room attrs " .. r.Name) end
	if r.Transparency ~= 1 or r.CanCollide or r.CanQuery or r.CanTouch then err("room helper flags " .. r.Name) end
	byArea[r:GetAttribute("Area")] = (byArea[r:GetAttribute("Area")] or 0) + 1
end
for i = 1, #rooms do
	for j = i + 1, #rooms do
		local a, b = rooms[i], rooms[j]
		local amin, amax = a.Position - a.Size / 2, a.Position + a.Size / 2
		local bmin, bmax = b.Position - b.Size / 2, b.Position + b.Size / 2
		local ov = Vector3.new(math.min(amax.X, bmax.X) - math.max(amin.X, bmin.X), math.min(amax.Y, bmax.Y) - math.max(amin.Y, bmin.Y), math.min(amax.Z, bmax.Z) - math.max(amin.Z, bmin.Z))
		if ov.X > 0.05 and ov.Y > 0.05 and ov.Z > 0.05 then err("rooms overlap: " .. a.Name .. " / " .. b.Name) end
	end
end
table.insert(out, ("Rooms: %d (G %d, U %d, B %d, A %d)"):format(#rooms, byArea.Ground or 0, byArea.Upstairs or 0, byArea.Basement or 0, byArea.Attic or 0))
-- loot / prize
local lootA = {}
for _, p in H.LootSpawns:GetChildren() do
	local r = checkArea(p, p.Position, "Loot")
	if r and p:GetAttribute("Danger") ~= r:GetAttribute("Danger") then err("Loot danger mismatch in " .. r.Name .. " @" .. tostring(p.Position - Vector3.new(6000, 0, 0))) end
	if type(p:GetAttribute("Danger")) ~= "number" then err("loot no danger") end
	lootA[p:GetAttribute("Area")] = (lootA[p:GetAttribute("Area")] or 0) + 1
end
table.insert(out, ("LootSpawns: %d (G %d, U %d, B %d, A %d)"):format(#H.LootSpawns:GetChildren(), lootA.Ground or 0, lootA.Upstairs or 0, lootA.Basement or 0, lootA.Attic or 0))
local prA = {}
for _, p in H.PrizeSpawns:GetChildren() do
	checkArea(p, p.Position, "Prize")
	prA[p:GetAttribute("Area")] = (prA[p:GetAttribute("Area")] or 0) + 1
end
table.insert(out, ("PrizeSpawns: %d (G %d, U %d, B %d, A %d)"):format(#H.PrizeSpawns:GetChildren(), prA.Ground or 0, prA.Upstairs or 0, prA.Basement or 0, prA.Attic or 0))
-- searchables
local kinds = { Drawer = 0, Cabinet = 0, Fridge = 0, ToyChest = 0, Vanity = 0, Trunk = 0 }
local sA = {}
for _, p in CS:GetTagged("Searchable") do
	if inMap(p) then
		local k = p:GetAttribute("Kind")
		if kinds[k] == nil then err("Searchable bad Kind " .. p:GetFullName()) else kinds[k] += 1 end
		checkArea(p, p.Position, "Searchable")
		if type(p:GetAttribute("Danger")) ~= "number" then err("Searchable no Danger " .. p:GetFullName()) end
		if not p:IsA("BasePart") then err("Searchable not a part") end
		sA[p:GetAttribute("Area")] = (sA[p:GetAttribute("Area")] or 0) + 1
	end
end
local ns = 0
for _, v in kinds do ns += v end
table.insert(out, ("Searchables: %d (Drawer %d, Cabinet %d, Fridge %d, ToyChest %d, Vanity %d, Trunk %d; G %d U %d B %d A %d)"):format(ns, kinds.Drawer, kinds.Cabinet, kinds.Fridge, kinds.ToyChest, kinds.Vanity, kinds.Trunk, sA.Ground or 0, sA.Upstairs or 0, sA.Basement or 0, sA.Attic or 0))
-- doors
local nd, sq, lk = 0, 0, 0
for _, m in CS:GetTagged("Door") do
	if inMap(m) then
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
local hk, nh, ha = {}, 0, {}
for _, m in CS:GetTagged("HidingSpot") do
	if inMap(m) then
		nh += 1
		local ins, fr, ex = m:FindFirstChild("Inside", true), m:FindFirstChild("Front", true), m:FindFirstChild("Exit", true)
		if not (ins and fr and ex) then err("HidingSpot parts " .. m:GetFullName()) else checkArea(m, fr.Position, "HidingSpot") end
		local k = m:GetAttribute("Kind")
		if not ({ Wardrobe = 1, Bed = 1, Closet = 1, Cabinet = 1 })[k] then err("HidingSpot Kind " .. m.Name) end
		hk[k] = (hk[k] or 0) + 1
		ha[m:GetAttribute("Area")] = (ha[m:GetAttribute("Area")] or 0) + 1
	end
end
table.insert(out, ("HidingSpots: %d (Wardrobe %d, Bed %d, Closet %d, Cabinet %d; G %d U %d B %d A %d)"):format(nh, hk.Wardrobe or 0, hk.Bed or 0, hk.Closet or 0, hk.Cabinet or 0, ha.Ground or 0, ha.Upstairs or 0, ha.Basement or 0, ha.Attic or 0))
if nh < 14 then err("fewer than 14 hiding spots") end
if (ha.Ground or 0) < 5 then err("fewer than 5 Ground hiding spots") end
-- creaky / breakable
local nc = 0
for _, p in CS:GetTagged("Creaky") do
	if inMap(p) then
		nc += 1
		if not (p.CanCollide and p.CanTouch) then err("Creaky flags") end
		if not roomAt(p.Position + Vector3.new(0, 1, 0)) then err("Creaky outside rooms @" .. tostring(p.Position - Vector3.new(6000, 0, 0))) end
	end
end
table.insert(out, "Creaky: " .. nc)
local nb = 0
for _, b in CS:GetTagged("Breakable") do
	if inMap(b) then
		nb += 1
		local p = if b:IsA("Model") then b.PrimaryPart else b
		if not (p and p.CanTouch and p.CanCollide) then err("Breakable flags " .. b:GetFullName()) end
	end
end
table.insert(out, "Breakables: " .. nb)
-- lamps + light budget
local nl, shadows, la = 0, 0, {}
for _, l in CS:GetTagged("Lamp") do
	if inMap(l) then
		nl += 1
		local bulb = l:FindFirstChild("Bulb", true)
		local light = l:FindFirstChildWhichIsA("Light", true)
		if not (bulb and bulb.Material == Enum.Material.Neon and light) then err("Lamp structure " .. l:GetFullName()) end
		if light and light.Shadows then shadows += 1 end
		if not AREAS[l:GetAttribute("Area")] then err("Lamp area " .. l:GetFullName()) end
		la[l:GetAttribute("Area")] = (la[l:GetAttribute("Area")] or 0) + 1
	end
end
local lights = 0
for _, d in H:GetDescendants() do if d:IsA("Light") then lights += 1 end end
table.insert(out, ("Lamps: %d (shadows %d; G %d, U %d, B %d, A %d); dynamic lights total %d"):format(nl, shadows, la.Ground or 0, la.Upstairs or 0, la.Basement or 0, la.Attic or 0, lights))
if lights > 45 then err("more than 45 lights") end
-- search nodes
local nn, bath, na = 0, 0, {}
for _, p in H.SearchNodes:GetChildren() do
	nn += 1
	checkArea(p, p.Position, "SearchNode")
	if p:GetAttribute("Bathroom") then
		bath += 1
		local r = roomAt(p.Position)
		if not r or r:GetAttribute("RoomName") ~= "Portaloos" or r:GetAttribute("Area") ~= "Ground" then err("Bathroom node not at the portaloos") end
	end
	na[p:GetAttribute("Area")] = (na[p:GetAttribute("Area")] or 0) + 1
end
if bath ~= 1 then err("Bathroom nodes = " .. bath) end
for _, r in rooms do
	local has = false
	for _, p in H.SearchNodes:GetChildren() do if roomAt(p.Position) == r then has = true break end end
	if not has then err("Room without SearchNode: " .. r.Name) end
end
table.insert(out, ("SearchNodes: %d (G %d, U %d, B %d, A %d), Bathroom=true: %d"):format(nn, na.Ground or 0, na.Upstairs or 0, na.Basement or 0, na.Attic or 0, bath))
-- singletons
local ss, gc = H:FindFirstChild("GrandmaSleepSpot"), H:FindFirstChild("GrandmaChair")
if not (ss and ss:IsA("BasePart") and gc) then err("GrandmaSleepSpot/GrandmaChair") end
if ss and roomAt(ss.Position) == nil then err("GrandmaSleepSpot outside rooms") end
if not (H:FindFirstChild("FuseBox") and H.FuseBox:IsA("BasePart")) then err("FuseBox") end
local car = H:FindFirstChild("MomsCar")
if not (car and car:FindFirstChild("Trunk") and car.Trunk:IsA("BasePart")) then err("MomsCar.Trunk") end
local bars = {}
for _, b in H.Barriers:GetChildren() do bars[b:GetAttribute("Area") or "?"] = b.Name end
for _, a in { "Upstairs", "Basement", "Attic" } do if not bars[a] then err("No Barrier for " .. a) end end
table.insert(out, "Barriers: " .. #H.Barriers:GetChildren())
table.insert(out, "PlayerSpawns: " .. #H.PlayerSpawns:GetChildren())
if #H.PlayerSpawns:GetChildren() < 5 then err("fewer than 5 PlayerSpawns") end
local cc = {}
for i = 1, 4 do
	local f = H.Corruption:FindFirstChild(tostring(i))
	local n = 0
	if f then for _, d in f:GetDescendants() do if d:IsA("BasePart") then n += 1 if d.CanCollide then err("Corruption part collides " .. d:GetFullName()) end end end else err("Corruption/" .. i) end
	table.insert(cc, tostring(n))
end
table.insert(out, "Corruption parts per level: " .. table.concat(cc, "/"))
-- parts, flags
local parts, unanch, smallTouch, smallShadow = 0, 0, 0, 0
for _, d in H:GetDescendants() do
	if d:IsA("BasePart") then
		parts += 1
		if not d.Anchored then unanch += 1 end
	end
end
table.insert(out, ("Parts: %d (unanchored %d)"):format(parts, unanch))
if parts > 6000 then err("more than 6000 parts") end
local scripts = 0
for _, d in H:GetDescendants() do if d:IsA("LuaSourceContainer") then scripts += 1 end end
table.insert(out, "Scripts inside map: " .. scripts)
table.insert(out, "ERRORS (" .. #errs .. "):")
for i = 1, math.min(#errs, 60) do table.insert(out, "  " .. errs[i]) end
return table.concat(out, "\n")
