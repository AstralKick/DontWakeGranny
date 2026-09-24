-- BackGarden 03: THE GREENHOUSE (Area "Upstairs", unlocks night 2 of the chapter).
-- Footprint x 30..62, z -2..34. Brick knee wall + glass, gabled glass roof, partition at x = 50.
-- Doors: GreenhouseDoor (west wall, z 16) and OrchidDoor (partition, z 16). Barrier: boards outside the west door.
local B = _G.BGB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local SM = { small = true }
local CS = B.CS
local root = B.root()
local U = B.F("Upstairs")
local A = "Upstairs"
-- idempotent re-run of this chunk: clear the previous greenhouse build
for _, c in U:GetChildren() do c:Destroy() end
if B.F("Barriers"):FindFirstChild("GreenhouseBoards") then B.F("Barriers").GreenhouseBoards:Destroy() end
for _, fn in { "Rooms", "LootSpawns", "PrizeSpawns", "SearchNodes" } do
	for _, c in B.F(fn):GetChildren() do if c:GetAttribute("Area") == "Upstairs" then c:Destroy() end end
end
for _, c in B.F("Creaky"):GetChildren() do
	local p = c.Position - Vector3.new(B.OX, 0, 0)
	if p.X > 30 and p.X < 62 and p.Z > -2 and p.Z < 34 then c:Destroy() end
end
local GH = B.model(U, "Greenhouse")
local paint = C.Paper:Lerp(C.Mint, 0.25):Lerp(C.Ink, 0.12)
local glassC = C.GlassG
local function glass(parent, name, x0, y0, z0, x1, y1, z1)
	local g = B.box(parent, name, x0, y0, z0, x1, y1, z1, glassC, M.Glass, { solid = true, shadow = false, tr = 0.62 })
	return g
end
-- one greenhouse wall line. axis "z": runs along Z at x = fixed; "x": along X at z = fixed. gaps like B.pieces
local function ghWall(axis, fixed, a, b, gaps)
	for _, pc in B.pieces(a, b, 0, 2.5, gaps) do
		if axis == "z" then
			B.box(GH, "KneeWall", fixed - 0.3, pc[3], pc[1], fixed + 0.3, pc[4], pc[2], C.Brick, M.Brick, { solid = true })
		else
			B.box(GH, "KneeWall", pc[1], pc[3], fixed - 0.3, pc[2], pc[4], fixed + 0.3, C.Brick, M.Brick, { solid = true })
		end
	end
	local ggaps = {}
	for _, g in gaps or {} do table.insert(ggaps, { c = g.c, w = g.w, h = g.h - 2.5 }) end
	for _, pc in B.pieces(a, b, 2.5, 10, ggaps) do
		-- the wall-end pieces stop 0.01 short so they are never coplanar with the top plate ends
		local s0 = if math.abs(pc[1] - a) < 0.001 then pc[1] + 0.01 else pc[1]
		local s1 = if math.abs(pc[2] - b) < 0.001 then pc[2] - 0.01 else pc[2]
		if axis == "z" then
			glass(GH, "Glass", fixed - 0.1, pc[3], s0, fixed + 0.1, pc[4], s1)
		else
			glass(GH, "Glass", s0, pc[3], fixed - 0.1, s1, pc[4], fixed + 0.1)
		end
	end
	-- knee coping + top plate + mullions (skip mullions inside door gaps)
	for _, pc in B.pieces(a, b, 0, 2.5, gaps) do
		if axis == "z" then
			B.box(GH, "KneeCap", fixed - 0.4, 2.5, pc[1], fixed - 0.1, 2.7, pc[2], paint, M.Wood, SM)
			B.box(GH, "KneeCap", fixed + 0.1, 2.5, pc[1], fixed + 0.4, 2.7, pc[2], paint, M.Wood, SM)
		else
			B.box(GH, "KneeCap", pc[1], 2.5, fixed - 0.4, pc[2], 2.7, fixed - 0.1, paint, M.Wood, SM)
			B.box(GH, "KneeCap", pc[1], 2.5, fixed + 0.1, pc[2], 2.7, fixed + 0.4, paint, M.Wood, SM)
		end
	end
	if axis == "z" then
		B.box(GH, "TopPlate", fixed - 0.25, 9.8, a, fixed + 0.25, 10.2, b, paint, M.Wood, { collide = true })
	else
		B.box(GH, "TopPlate", a, 9.8, fixed - 0.25, b, 10.2, fixed + 0.25, paint, M.Wood, { collide = true })
	end
	for s = a + 4, b - 3.9, 4 do
		local inGap = false
		for _, g in gaps or {} do if math.abs(s - g.c) < g.w / 2 + 0.4 then inGap = true end end
		if not inGap then
			if axis == "z" then
				B.box(GH, "Mullion", fixed - 0.2, 2.7, s - 0.15, fixed + 0.2, 9.8, s + 0.15, paint, M.Wood, SM)
			else
				B.box(GH, "Mullion", s - 0.15, 2.7, fixed - 0.2, s + 0.15, 9.8, fixed + 0.2, paint, M.Wood, SM)
			end
		end
	end
end
local doorGap = { c = 16, w = B.DW + 0.7, h = 8.4 }
ghWall("z", 30, -2.3, 34.3, { doorGap })
ghWall("z", 62, -2.3, 34.3)
ghWall("x", -2, 30.3, 61.7)
ghWall("x", 34, 30.3, 61.7)
ghWall("z", 50, -1.7, 33.7, { { c = 16, w = B.DW + 0.7, h = 8.4 } })
-- corner posts
for _, p in { V(30, 0, -2), V(62, 0, -2), V(30, 0, 34), V(62, 0, 34) } do
	B.box(GH, "CornerPost", p.X - 0.35, 2.5, p.Z - 0.35, p.X + 0.35, 10.2, p.Z + 0.35, paint, M.Wood, { collide = true })
end
-- floor (brick paving) and a centre aisle of old boards
B.box(GH, "Paving", 30.3, -0.2, -1.7, 61.7, 0.05, 33.7, C.Brick:Lerp(C.Paper, 0.12), M.Brick, { solid = true })
-- gabled glass roof: ridge along X at z 16, y 16; eaves at y 10
local ang = math.atan2(6, 18)
local slopeLen = math.sqrt(18 ^ 2 + 6 ^ 2)
for _, side in { -1, 1 } do
	local zc = 16 + side * 9
	local rot = CFrame.Angles(side * ang, 0, 0)
	B.part(GH, "RoofGlass", V(32.6, 0.15, slopeLen + 0.2), CFrame.new(46, 13.08, zc) * rot, glassC, M.Glass, { solid = true, shadow = false, tr = 0.6 })
	for x = 30, 62, 4 do
		B.part(GH, "Rafter", V(0.3, 0.3, slopeLen), CFrame.new(x, 12.85, zc) * rot, paint, M.Wood, SM)
	end
end
B.box(GH, "Ridge", 29.8, 15.9, 15.8, 62.2, 16.35, 16.2, paint, M.Wood, SM)
-- gable ends (and the partition gable) as glass wedges
for _, x in { 30, 50, 62 } do
	B.part(GH, "GableGlass", V(0.2, 6, 18), CFrame.new(x, 13, 7), glassC, M.Glass, { solid = true, shadow = false, tr = 0.62, class = "WedgePart" })
	B.part(GH, "GableGlass", V(0.2, 6, 18), CFrame.new(x, 13, 25) * CFrame.Angles(0, math.pi, 0), glassC, M.Glass, { solid = true, shadow = false, tr = 0.62, class = "WedgePart" })
	B.box(GH, "GablePost", x - 0.15, 10.2, 15.85, x + 0.15, 15.9, 16.15, paint, M.Wood, SM)
end
-- weather vane
B.box(GH, "VanePole", 45.9, 16.35, 15.9, 46.1, 19, 16.1, C.Iron, M.Metal, SM)
B.part(GH, "VaneRooster", V(0.1, 1.2, 1.6), CFrame.new(46, 19.2, 16), C.Iron, M.Metal, SM)
-- ivy creeping up the outside glass, a cracked pane
for _, i in { 0, 1, 2, 3, 6, 7, 8, 9 } do
	local z = -1 + i * 3.7
	B.part(GH, "Ivy", V(0.3, 2 + (i % 3), 1.6), CFrame.new(29.65, 3.2 + (i % 4) * 1.3, z) * CFrame.Angles(math.rad(i * 17), 0, 0), C.Moss:Lerp(C.Ink, 0.3), M.LeafyGrass, SM)
end
B.box(GH, "CrackedPane", 29.83, 5.2, 24, 29.88, 8.4, 27.6, C.Paper:Lerp(C.GlassG, 0.6), M.Glass, { small = true, tr = 0.3 })

----------------------------------------------------------------- doors + barrier
B.door2(U, "GreenhouseDoor", "z", 30, 16, 0.05, A, { style = "glass", color = paint, wallT = 0.6, frameColor = paint, squeaky = true })
B.door2(U, "OrchidDoor", "z", 50, 16, 0.05, A, { style = "glass", color = paint:Lerp(C.Mint, 0.2), wallT = 0.6, frameColor = paint, hs = -1 })
B.barrier(A, "GreenhouseBoards", "z", 30, 16, 0, 4.5, 8.4, -1, { d = 0.95 })

----------------------------------------------------------------- the glasshouse (x 30.3..49.7)
local GL = B.model(U, "Glasshouse")
local function decoPot(par, pos, s, leaf)
	local b = CFrame.new(pos)
	B.cyl(par, "Pot", b, 0.8 * s, 0.8 * s, V(0, 0.4 * s, 0), C.Terracotta:Lerp(C.Ink, 0.1), M.Slate, SM, true)
	if leaf ~= false then B.ball(par, "Leaves", b, 1.0 * s, V(0, 1.1 * s, 0), (leaf or C.Moss):Lerp(C.Ink, 0.15), M.LeafyGrass, SM) end
end
local _, bh = B.bench(GL, cf(40, 0.05, -0.2, "+z"), 16, A, 2, { name = "SouthBench", search = { [2] = "Drawer", [4] = "Drawer" }, d = 2.6 })
local topY = 0.05 + bh
B.pot(GL, cf(34, topY, -0.4), 0.9, C.Moss)
B.pot(GL, cf(45.5, topY, -0.5), 0.9, "dead")
for _, x in { 36.2, 38, 41.5, 43.3 } do decoPot(GL, V(x, topY, -0.6), 0.8, if x > 40 then C.Rose:Lerp(C.Moss, 0.5) else nil) end
B.loot(A, 2, V(39.8, topY, 0.1))
B.loot(A, 2, V(47, topY, 0))
B.bench(GL, cf(40, 0.05, 32.2, "-z"), 16, A, 2, { name = "NorthBench", search = { [3] = "Drawer" }, d = 2.6 })
B.pot(GL, cf(46.5, topY, 32.4), 1, C.Mint:Lerp(C.Moss, 0.5))
for _, x in { 33, 34.8, 37, 42, 44 } do decoPot(GL, V(x, topY, 32.5), 0.7) end
B.loot(A, 2, V(39.5, topY, 32))
B.loot(A, 2, V(35.6, topY, 31.9))
-- staging islands
for _, z in { 9.5, 22.5 } do
	local _, th = B.table(GL, cf(40, 0.05, z), 8, 3, 3.1, C.WoodRaw:Lerp(C.Ink, 0.1), { name = "StagingTable" })
	local ty = 0.05 + th
	for i = 0, 2 do
		B.box(GL, "SeedTray", 36.2 + i * 2.6, ty, z - 0.9, 38.4 + i * 2.6, ty + 0.3, z + 0.9, C.Ink:Lerp(C.WoodDark, 0.5), M.Plastic, SM)
		for k = 0, 2 do
			B.part(GL, "Seedling", V(0.4, 0.5, 0.4), CFrame.new(36.7 + i * 2.6 + k * 0.6, ty + 0.5, z + ((k % 2) - 0.5) * 0.8), C.Mint:Lerp(C.Moss, 0.4), M.LeafyGrass, { small = true, shape = Enum.PartType.Ball })
		end
	end
	B.loot(A, 2, V(43.3, ty, z + 1.15))
	B.loot(A, 2, V(36.6, ty, z - 1.2))
	-- sacks of compost under the tables
	B.box(GL, "CompostSack", 37, 0.05, z - 1.2, 39.2, 1.1, z + 0.4, C.Mustard:Lerp(C.WoodDark, 0.5), M.Fabric, SM)
end
-- hanging baskets from the rafters
for _, p in { V(34, 0, 12), V(46, 0, 12), V(34, 0, 20), V(46, 0, 20) } do
	local hb = B.model(GL, "HangingBasket")
	hb:SetAttribute("NoGround", true)
	local y = 16 - math.abs(p.Z - 16) / 3 - 0.3
	B.box(hb, "Chain", p.X - 0.04, 11.2, p.Z - 0.04, p.X + 0.04, y, p.Z + 0.04, C.Iron, M.Metal, SM)
	B.part(hb, "Basket", V(1.8, 1.0, 1.8), CFrame.new(p.X, 10.7, p.Z), C.Wicker:Lerp(C.Ink, 0.3), M.Fabric, { small = true, shape = Enum.PartType.Ball })
	for i = 0, 2 do
		B.box(hb, "Trailing", p.X - 0.9 + (i % 2) * 1.6, 8.4 - (i % 3) * 0.5, p.Z - 0.9 + math.floor(i / 2) * 1.6, p.X - 0.7 + (i % 2) * 1.6, 10.6, p.Z - 0.7 + math.floor(i / 2) * 1.6, C.Moss:Lerp(C.Ink, 0.2), M.LeafyGrass, SM)
	end
end
-- potting cupboard (HidingSpot Wardrobe) against the partition
B.wardrobe(GL, cf(47.75, 0.05, 4, "-x"), C.Mint:Lerp(C.Ink, 0.5), A, "Wardrobe", { name = "PottingCupboard", w = 5.2, h = 8.8 })
-- sacking-covered staging (HidingSpot, prone)
do
	local b = cf(36, 0.05, 27.5, "+x")
	local sk = C.Mustard:Lerp(C.WoodDark, 0.55)
	local m = B.lowHide(GL, b, A, { name = "SackedStaging", len = 7, wid = 3.4, h = 3.2, col = sk, mat = M.Fabric, topColor = C.WoodRaw, topMat = M.WoodPlanks, over = 0.3 })
	for i = 0, 2 do decoPot(m, (b * CFrame.new(-0.4 + (i % 2) * 0.8, 3.2, -2.4 + i * 2.4)).Position, 0.7, C.Mint:Lerp(C.Moss, 0.6)) end
end
-- seed chest (Searchable drawers) by the west wall
B.dresser(GL, cf(31.4, 0.05, 6, "+x"), 3.6, 2, 3.4, C.WoodMid:Lerp(C.Mint, 0.15), 4, A, 2, { search = { 2, 4 }, name = "SeedChest" })
B.loot(A, 2, V(31.4, 3.65, 5.4))
-- floor pots (Breakable) by the door, watering can
B.pot(GL, cf(32, 0.05, 20.4), 1.2, C.Moss)
do
	local wc = B.model(GL, "WateringCan")
	local b = cf(33, 0.05, 11.3)
	B.cyl(wc, "Can", b, 1.1, 1.1, V(0, 0.55, 0), C.Metal:Lerp(C.Mint, 0.3), M.Metal, SM, true)
	B.rp(wc, "Spout", b, V(0.18, 0.18, 1.4), V(0, 0.9, -0.9), C.Metal:Lerp(C.Mint, 0.3), M.Metal, SM, CFrame.Angles(math.rad(35), 0, 0))
	B.rp(wc, "Handle", b, V(0.12, 0.8, 0.12), V(0, 1.4, 0.3), C.Metal:Lerp(C.Mint, 0.3), M.Metal, SM)
end
B.lamp(GL, "bare", cf(35, 15.9, 16), A, { drop = 3, range = 18, bright = 0.9, color = Color3.fromRGB(230, 240, 200) })
B.lamp(GL, "bare", cf(44, 15.9, 16), A, { drop = 3, range = 18, bright = 0.9, color = Color3.fromRGB(230, 240, 200) })
B.creak(37, 0.05, 16, 0)
B.creak(44.5, 0.05, 13.5, 0)
B.cobweb(GL, V(31, 9, -1), 45, 0.8)

----------------------------------------------------------------- the orchid house (x 50.3..61.7)
local OH = B.model(U, "OrchidHouse")
local _, ebh = B.bench(OH, cf(59.8, 0.05, 16, "-x"), 18, A, 3, { name = "OrchidBench", search = { [2] = "Drawer" }, d = 2.6 })
local ey = 0.05 + ebh
for i = 0, 6 do
	local z = 8.5 + i * 2.4
	decoPot(OH, V(59.9, ey, z), 0.8, false)
	B.box(OH, "OrchidStem", 59.86, ey + 0.6, z - 0.04, 59.94, ey + 2.4, z + 0.04, C.Moss, M.Wood, SM)
	B.part(OH, "Orchid", V(0.7, 0.5, 0.7), CFrame.new(59.9, ey + 2.4, z), ({ C.Rose, C.Paper, C.Bruise })[i % 3 + 1]:Lerp(C.Paper, 0.2), M.Fabric, { small = true, shape = Enum.PartType.Ball })
end
B.loot(A, 3, V(60, ey, 11.3))
B.loot(A, 3, V(59.6, ey, 22.1))
-- flower-arranging vanity (Searchable Vanity) with a mirror; the prize sits on it
do
	local vb = cf(55.5, 0.05, 32.35, "-z")
	local vm, vh = B.dresser(OH, vb, 4.2, 2, 3, C.Rose:Lerp(C.Ink, 0.45), 2, A, 3, { search = { 1 }, kind = "Vanity", name = "FlowerVanity" })
	B.rp(vm, "Mirror", vb, V(2.6, 3.2, 0.1), V(0, vh + 1.7, 0.85), C.Glass:Lerp(C.Paper, 0.3), M.Glass, { small = true, refl = 0.4 })
	B.rp(vm, "MirrorFrame", vb, V(3, 3.6, 0.08), V(0, vh + 1.7, 0.94), C.Brass:Lerp(C.Ink, 0.3), M.Metal, SM)
	B.prize(A, (vb * CFrame.new(-0.9, vh, 0.1)).Position)
	B.loot(A, 3, (vb * CFrame.new(1.2, vh, 0)).Position)
	B.jar(OH, (vb * CFrame.new(0.3, vh, 0.4)).Position, C.Rose:Lerp(C.Paper, 0.4), 0.9)
end
-- seed cabinet (HidingSpot Closet)
B.wardrobe(OH, cf(56, 0.05, 0.2, "+z"), C.WoodMid:Lerp(C.Mint, 0.3), A, "Closet", { name = "SeedCabinet", w = 5, h = 8.8, louvre = true })
-- the big hungry plant
do
	local fp = B.model(OH, "HungryPlant")
	local b = cf(53.2, 0.05, 23)
	B.cyl(fp, "BigPot", b, 3, 2.4, V(0, 1.2, 0), C.Terracotta:Lerp(C.Ink, 0.2), M.Slate, { solid = true }, true)
	B.cyl(fp, "Soil", b, 2.6, 0.06, V(0, 2.42, 0), C.Soil, M.Ground, SM, true)
	B.rp(fp, "Stem", b, V(0.4, 3, 0.4), V(0, 3.9, 0), C.Moss:Lerp(C.Ink, 0.2), M.Wood, SM)
	for _, s in { -1, 1 } do
		B.part(fp, "Jaw", V(2.4, 0.6, 1.6), b * CFrame.new(0, 5.6 + s * 0.35, -0.3) * CFrame.Angles(math.rad(s * 18), 0, 0), C.Blood:Lerp(C.Moss, 0.35), M.SmoothPlastic, { small = true, shape = Enum.PartType.Ball })
		for k = -2, 2 do
			B.rp(fp, "Tooth", b, V(0.12, 0.35, 0.12), V(k * 0.4, 5.6 + s * 0.12, -1.0), C.Paper, M.SmoothPlastic, SM)
		end
	end
	for _, a in { 40, 150, 260 } do
		B.part(fp, "Leaf", V(0.2, 0.9, 2.6), b * CFrame.Angles(0, math.rad(a), 0) * CFrame.new(0, 2.9, -1.4) * CFrame.Angles(math.rad(-30), 0, 0), C.Moss:Lerp(C.Mint, 0.2), M.LeafyGrass, SM)
	end
	fp:SetAttribute("NoGround", true)
end
B.pot(OH, cf(52.5, 0.05, 10), 1.1, "dead")
B.hangLantern(OH, V(56, 15.9, 16), A, { drop = 2.4, range = 16, bright = 0.8, color = Color3.fromRGB(220, 200, 255) })
B.lamp(OH, "bare", cf(58, 12.45, 6), A, { drop = 1.6, range = 12, bright = 0.6 }) -- hangs from a rafter
B.creak(55.5, 0.05, 12.5, 0)
B.cobweb(OH, V(61, 9, 33), -135, 0.9)

----------------------------------------------------------------- rooms + nodes
B.room("The Glasshouse", A, 2, 30.3, 0, -1.7, 49.7, 16, 33.7)
B.room("Orchid House", A, 3, 50.3, 0, -1.7, 61.7, 16, 33.7)
for _, n in { { 36, 4.5 }, { 44, 16 }, { 36.5, 16 }, { 44, 28 }, { 47, 9.5 } } do B.node(A, n[1], 0.05, n[2]) end
for _, n in { { 55, 6 }, { 55, 16 }, { 55.5, 27.5 } } do B.node(A, n[1], 0.05, n[2]) end
return "03 greenhouse ok, parts=" .. B.count(root)
