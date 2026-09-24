-- BackGarden 04: THE POTTING SHED (Area "Basement", unlocks night 3 of the chapter).
-- Shed x -77..-50, z -16..14 (walls 0.5): potting room + tool room (partition x = -66). A floor hatch
-- (x -65.75..-58.75, z -8..3, against the partition) opens onto a 33.7-degree ramp down to a landing (y -10) and the root cellar door
-- (z 12.75). Root cellar x -76..-44, z 13..34, y -10..-1. Barrier: padlocked planks outside the shed door.
local B = _G.BGB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local SM = { small = true }
local root = B.root()
local BS = B.F("Basement")
local A = "Basement"
-- idempotent re-run of this chunk: clear the previous shed + cellar build
for _, c in BS:GetChildren() do c:Destroy() end
if B.F("Barriers"):FindFirstChild("ShedPadlock") then B.F("Barriers").ShedPadlock:Destroy() end
for _, fn in { "Rooms", "LootSpawns", "PrizeSpawns", "SearchNodes" } do
	for _, c in B.F(fn):GetChildren() do if c:GetAttribute("Area") == "Basement" then c:Destroy() end end
end
for _, c in B.F("Creaky"):GetChildren() do
	local p = c.Position - Vector3.new(B.OX, 0, 0)
	if p.X > -77 and p.X < -44 and p.Z > -16 and p.Z < 34 then c:Destroy() end
end
local SH = B.model(BS, "PottingShed")
local wc = C.WMint:Lerp(C.Ink, 0.45)
local winGap = function(c) return { c = c, w = 3, sill = 3.5, h = 7 } end
local function shedWall(axis, fixed, a, b, gaps)
	for _, pc in B.pieces(a, b, 0, 10, gaps) do
		if axis == "z" then
			B.box(SH, "Wall", fixed - 0.25, pc[3], pc[1], fixed + 0.25, pc[4], pc[2], wc, M.WoodPlanks, { solid = true })
		else
			B.box(SH, "Wall", pc[1], pc[3], fixed - 0.25, pc[2], pc[4], fixed + 0.25, wc, M.WoodPlanks, { solid = true })
		end
	end
end
local function shedWindow(axis, fixed, c)
	local m = B.model(SH, "ShedWindow")
	if axis == "z" then
		B.box(m, "Glass", fixed - 0.05, 3.5, c - 1.5, fixed + 0.05, 7, c + 1.5, C.GlassG:Lerp(C.Ink, 0.4), M.Glass, { solid = true, tr = 0.35 })
		B.box(m, "Mullion", fixed - 0.12, 3.5, c - 0.08, fixed + 0.12, 7, c + 0.08, C.WoodDark, M.Wood, SM)
		B.box(m, "Mullion", fixed - 0.12, 5.2, c - 1.5, fixed + 0.12, 5.36, c + 1.5, C.WoodDark, M.Wood, SM)
		B.box(m, "Sill", fixed - 0.5, 3.35, c - 1.7, fixed + 0.5, 3.55, c + 1.7, C.WoodDark, M.Wood, SM)
	else
		B.box(m, "Glass", c - 1.5, 3.5, fixed - 0.05, c + 1.5, 7, fixed + 0.05, C.GlassG:Lerp(C.Ink, 0.4), M.Glass, { solid = true, tr = 0.35 })
		B.box(m, "Mullion", c - 0.08, 3.5, fixed - 0.12, c + 0.08, 7, fixed + 0.12, C.WoodDark, M.Wood, SM)
		B.box(m, "Mullion", c - 1.5, 5.2, fixed - 0.12, c + 1.5, 5.36, fixed + 0.12, C.WoodDark, M.Wood, SM)
		B.box(m, "Sill", c - 1.7, 3.35, fixed - 0.5, c + 1.7, 3.55, fixed + 0.5, C.WoodDark, M.Wood, SM)
	end
end
local doorGap = { c = -10, w = B.DW + 0.7, h = 8.4 }
shedWall("z", -50.25, -16, 14, { doorGap, winGap(4) })
shedWindow("z", -50.25, 4)
shedWall("z", -76.75, -16, 14)
shedWall("x", -15.75, -76.5, -50.5, { winGap(-58) })
shedWindow("x", -15.75, -58)
shedWall("x", 13.75, -76.5, -50.5, { winGap(-70) })
shedWindow("x", 13.75, -70)
-- partition gable: closes the roof space between the rooms (roof underside at x -66.25 is y 14.02)
B.box(SH, "PartitionGable", -66.25, 10, -15.5, -65.75, 14, 13.5, wc:Lerp(C.Paper, 0.08), M.WoodPlanks, { solid = true })
for _, pc in B.pieces(-15.5, 13.5, 0.05, 10, { { c = 6, w = B.DW + 0.7, h = 8.35 } }) do -- stands on the floor planks
	B.box(SH, "Partition", -66.25, pc[3], pc[1], -65.75, pc[4], pc[2], wc:Lerp(C.Paper, 0.08), M.WoodPlanks, { solid = true })
end
-- corner trims
for _, p in { V(-77, 0, -16), V(-50, 0, -16), V(-77, 0, 14), V(-50, 0, 14) } do
	B.box(SH, "CornerTrim", p.X - 0.3, 0, p.Z - 0.3, p.X + 0.3, 10, p.Z + 0.3, C.WoodDark, M.Wood, SM)
end
-- floor planks (0..0.05 on top of the ground slab), leaving the hatch open
B.box(SH, "Floor", -76.5, 0, -15.5, -50.5, 0.05, -8, C.WoodMid, M.WoodPlanks, { solid = true })
B.box(SH, "Floor", -76.5, 0, 3, -50.5, 0.05, 13.5, C.WoodMid, M.WoodPlanks, { solid = true })
B.box(SH, "Floor", -76.5, 0, -8, -66.25, 0.05, 3, C.WoodMid, M.WoodPlanks, { solid = true })
B.box(SH, "Floor", -58.75, 0, -8, -50.5, 0.05, 3, C.WoodMid, M.WoodPlanks, { solid = true })
-- roof: gable ridge along Z at x -63.5, y 15; eaves y 10
do
	local ang = math.atan2(5, 14)
	local len = math.sqrt(14 ^ 2 + 5 ^ 2) + 0.6
	B.part(SH, "Roof", V(len, 0.4, 31), CFrame.new(-70.5, 12.7, -1) * CFrame.Angles(0, 0, ang), C.Roof:Lerp(C.Moss, 0.15), M.Slate, { solid = true })
	B.part(SH, "Roof", V(len, 0.4, 31), CFrame.new(-56.5, 12.7, -1) * CFrame.Angles(0, 0, -ang), C.Roof:Lerp(C.Moss, 0.15), M.Slate, { solid = true })
	B.box(SH, "RidgeCap", -64, 15, -16.5, -63, 15.5, 14.5, C.Roof, M.Slate, SM)
	for _, z in { -15.75, 13.75 } do
		B.part(SH, "Gable", V(0.5, 5, 13.5), CFrame.new(-70.25, 12.5, z) * CFrame.Angles(0, math.rad(90), 0), wc, M.WoodPlanks, { solid = true, class = "WedgePart" })
		B.part(SH, "Gable", V(0.5, 5, 13.5), CFrame.new(-56.75, 12.5, z) * CFrame.Angles(0, math.rad(-90), 0), wc, M.WoodPlanks, { solid = true, class = "WedgePart" })
	end
	for z = -14, 12, 5.2 do
		B.box(SH, "TieBeam", -76.5, 9.6, z - 0.2, -50.5, 10, z + 0.2, C.WoodDark, M.Wood, SM)
	end
	B.box(SH, "Plate", -76.5, 9.6, -15.5, -76.1, 10, 13.5, C.WoodDark, M.Wood, SM)
	B.box(SH, "Plate", -50.9, 9.6, -15.5, -50.5, 10, 13.5, C.WoodDark, M.Wood, SM)
end
-- sign
B.box(SH, "ShedSign", -49.95, 9.1, -12.2, -49.85, 10.3, -7.8, C.Paper:Lerp(C.Ink, 0.3), M.Wood, SM)
B.box(SH, "ShedSignInk", -49.84, 9.5, -11.6, -49.8, 9.9, -8.4, C.Ink, M.SmoothPlastic, SM)

----------------------------------------------------------------- doors + barrier
B.door2(BS, "ShedDoor", "z", -50.25, -10, 0.05, A, { style = "garden", color = C.WoodMid:Lerp(C.Mint, 0.35), wallT = 0.5, squeaky = true, lockable = true })
B.door2(BS, "ToolRoomDoor", "z", -66, 6, 0.05, A, { style = "garden", color = C.WoodRaw:Lerp(C.Ink, 0.25), wallT = 0.5, hs = -1 })
B.barrier(A, "ShedPadlock", "z", -50.25, -10, 0, 4.5, 8.4, 1, { d = 0.9 })

----------------------------------------------------------------- hatch, ramp, landing, cellar door
local CE = B.model(BS, "RootCellar")
local stone = C.Stone:Lerp(C.Paper, 0.1)
-- hatch railing (collidable) + invisible side blockers so nobody falls in from the sides
for _, x in { -57.55 } do -- 1.2 in from the hatch edge: keeps the 7-wide ramp pathable for Grandma
	B.box(SH, "HatchRail", x - 0.15, 2.9, -7.8, x + 0.15, 3.2, 3.35, C.WoodDark, M.Wood, { collide = true })
	B.box(SH, "HatchRail", x - 0.1, 1.4, -7.8, x + 0.1, 1.6, 3.35, C.WoodDark, M.Wood, { collide = true })
	for _, z in { -7.8, -2.2, 3.2 } do B.box(SH, "HatchPost", x - 0.15, 0.05, z - 0.15, x + 0.15, 3.2, z + 0.15, C.WoodDark, M.Wood, { collide = true }) end
	B.box(SH, "HatchBlocker", x - 0.15, 0.05, -7.95, x + 0.15, 4, 3.35, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
end
B.box(SH, "HatchRail", -65.75, 2.9, 3.05, -57.4, 3.2, 3.35, C.WoodDark, M.Wood, { collide = true })
B.box(SH, "HatchBlocker", -65.75, 0.05, 3.05, -57.4, 4, 3.35, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
for _, s in { { -65.75, -65.6, -8, 3, 0.05 }, { -58.9, -58.75, -8, 3, 0.05 }, { -65.75, -65.6, 3, 7, 0 }, { -58.9, -58.75, 3, 7, 0 } } do
	B.box(SH, "HatchLining", s[1], -1, s[3], s[2], s[5], s[4], C.WoodDark, M.Wood, SM)
end
-- ramp: low edge z 7 (y -10), high edge z -8 (y 0)
B.steps(CE, -62.25, -0.5, 7, 15, -10, 0, "-z", C.WoodMid:Lerp(C.Ink, 0.15), M.WoodPlanks)
-- well walls, landing, well ceiling
for _, x in { -66, -58.5 } do
	B.box(CE, "WellWall", x - 0.25, -10, -8, x + 0.25, -1, 12.5, stone, M.Cobblestone, { solid = true })
end
B.box(CE, "LandingFloor", -65.75, -10.5, 7, -58.75, -10, 12.5, stone, M.Slate, { solid = true })
B.box(CE, "WellCeiling", -65.75, -1.3, 7, -58.75, -1, 12.5, C.WoodDark, M.WoodPlanks, { solid = true })
-- cellar shell
B.box(CE, "CellarFloor", -76.5, -10.5, 12.5, -43.5, -10, 34.5, stone, M.Slate, { solid = true })
for _, pc in B.pieces(-76.5, -43.5, -10, -1, { { c = -62.25, w = B.DW + 0.7, h = 8.35 } }) do
	B.box(CE, "CellarWall", pc[1], pc[3], 12.5, pc[2], pc[4], 13, stone, M.Cobblestone, { solid = true })
end
B.box(CE, "CellarWall", -76.5, -10, 34, -43.5, -1, 34.5, stone, M.Cobblestone, { solid = true })
B.box(CE, "CellarWall", -76.5, -10, 13, -76, -1, 34, stone, M.Cobblestone, { solid = true })
B.box(CE, "CellarWall", -44, -10, 13, -43.5, -1, 34, stone, M.Cobblestone, { solid = true })
B.box(CE, "CellarCeiling", -76, -1.3, 13, -44, -1, 34, C.WoodDark, M.WoodPlanks, { solid = true })
for x = -72, -48, 6 do B.box(CE, "Beam", x - 0.3, -1.9, 13, x + 0.3, -1.3, 34, C.WoodDark:Lerp(C.Ink, 0.3), M.Wood, SM) end
B.door2(BS, "CellarDoor", "x", 12.75, -62.25, -10, A, { style = "wood", color = C.WoodDark:Lerp(C.Blood, 0.15), wallT = 0.5, squeaky = true, frameColor = C.Ink:Lerp(C.WoodDark, 0.5) })

----------------------------------------------------------------- potting room (x -65.75..-50.5)
local PR = B.model(BS, "PottingRoom")
local TR = B.model(BS, "ToolRoom")
local _, bh = B.bench(PR, cf(-60, 0.05, 11.9, "-z"), 8, A, 2, { name = "ShedBench", search = { [1] = "Drawer", [2] = "Drawer" }, d = 2.6 })
local by = 0.05 + bh
for i = 0, 5 do
	B.cyl(PR, "PotStack", cf(-63 + i * 1.3, by, 12.4), 0.9, 0.7 + (i % 3) * 0.35, V(0, (0.7 + (i % 3) * 0.35) / 2, 0), C.Terracotta:Lerp(C.Ink, 0.2), M.Slate, SM, true)
end
B.box(PR, "SeedPackets", -58.5, by, 11.2, -57.3, by + 0.08, 12, C.Mustard:Lerp(C.Rose, 0.4), M.SmoothPlastic, SM)
B.box(PR, "Trowel", -56.9, by, 11.4, -56.7, by + 0.06, 12.4, C.Metal, M.Metal, SM)
B.loot(A, 2, V(-57, by, 11.6))
B.loot(A, 2, V(-62.5, by, 11.8))
-- potting cupboard (HidingSpot Wardrobe) against the east wall, north of the window
B.wardrobe(PR, cf(-52.4, 0.05, 8.5, "-x"), C.WoodMid:Lerp(C.Mint, 0.2), A, "Wardrobe", { name = "ShedCupboard", w = 5.2, h = 8.8 })
-- Grandma's old dressing table (Searchable Vanity) under the south window
do
	local vb = cf(-58.2, 0.05, -14.45, "+z")
	local _, vh = B.dresser(PR, vb, 4, 2, 3, C.Rose:Lerp(C.Ink, 0.4), 2, A, 2, { search = { 1 }, kind = "Vanity", name = "OldVanity" })
	B.loot(A, 2, (vb * CFrame.new(0.9, vh, 0)).Position)
	B.jar(PR, (vb * CFrame.new(-1.1, vh, 0.2)).Position, C.Mint:Lerp(C.Paper, 0.3), 0.8)
end
-- shelves on the south wall with tins and jars
do
	local sb = cf(-52.9, 0.05, -14.6, "+z")
	local _, ys = B.shelves(PR, sb, 4, 7, 1.6, 4)
	for i, y in ys do
		if i > 1 then
			for k = 0, 2 do
				B.jar(PR, (sb * CFrame.new(-1.2 + k * 1.1, y - 0.05 + 0.05, 0)).Position, ({ C.Mustard, C.Mint, C.Rose })[(i + k) % 3 + 1]:Lerp(C.Ink, 0.3), 0.8)
			end
		end
	end
	B.loot(A, 2, (sb * CFrame.new(0.2, ys[1], 0)).Position)
	B.loot(A, 2, (sb * CFrame.new(1.4, ys[4], 0)).Position)
end
-- lawn mower, sacks, rake
do
	local mw = B.model(TR, "LawnMower")
	local b = cf(-69.5, 0.05, 11.8, "-x")
	B.rp(mw, "Deck", b, V(2.2, 0.8, 2.6), V(0, 0.7, 0), C.Blood:Lerp(C.Ink, 0.4), M.Metal, { collide = true })
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do B.cyl(mw, "Wheel", b, 0.6, 0.2, V(sx * 1.1, 0.3, sz * 1), C.Ink, M.Rubber, SM, false) end
	end
	B.rp(mw, "Handle", b, V(0.12, 3, 0.12), V(-0.8, 2.2, 2.0), C.Metal, M.Metal, SM, CFrame.Angles(math.rad(35), 0, 0))
	B.rp(mw, "Handle", b, V(0.12, 3, 0.12), V(0.8, 2.2, 2.0), C.Metal, M.Metal, SM, CFrame.Angles(math.rad(35), 0, 0))
	B.rp(mw, "Grip", b, V(1.8, 0.12, 0.12), V(0, 3.4, 2.85), C.Ink, M.Rubber, SM)
	mw:SetAttribute("NoGround", true)
	B.part(PR, "Rake", V(0.12, 6.4, 0.12), CFrame.new(-51.2, 3.2, 12.9) * CFrame.Angles(0, 0, math.rad(8)), C.WoodLight, M.Wood, SM)
end
B.lamp(PR, "bare", cf(-58, 9.6, -8.8), A, { drop = 1.4, range = 16, bright = 0.8 })
B.lamp(PR, "bare", cf(-58, 9.6, 6.8), A, { drop = 1.4, range = 16, bright = 0.8 })
B.creak(-57.5, 0.05, -11.2, 0)
B.creak(-56, 0.05, -1, 0)
B.cobweb(PR, V(-51, 9, 13), -135, 0.8)
B.cobweb(PR, V(-65.5, 9, -15.3), 45, 0.8)

----------------------------------------------------------------- tool room (x -76.5..-66.25)
B.wardrobe(TR, cf(-74.5, 0.05, 8, "+x"), C.WoodDark:Lerp(C.Mint, 0.2), A, "Closet", { name = "ToolCupboard", w = 5.2, h = 8.6, louvre = true })
local _, wh = B.bench(TR, cf(-71.4, 0.05, -14.1, "+z"), 9, A, 2, { name = "Workbench", search = { [1] = "Drawer", [3] = "Drawer" }, d = 2.6, col = C.WoodMid })
local wy = 0.05 + wh
B.box(TR, "Vise", -68.8, wy, -14.4, -68, wy + 0.6, -13.6, C.Iron, M.Metal, SM)
B.box(TR, "Toolbox", -74.6, wy, -14.6, -72.8, wy + 0.8, -13.8, C.Blood:Lerp(C.Ink, 0.3), M.Metal, SM)
B.loot(A, 2, V(-71, wy, -13.9))
B.loot(A, 2, V(-69.6, wy, -14.5))
-- pegboard with tool silhouettes on the west wall
B.box(TR, "Pegboard", -76.45, 3.5, -10.5, -76.35, 7.5, -5.5, C.WoodRaw:Lerp(C.Paper, 0.2), M.Wood, SM)
for i = 0, 4 do
	B.box(TR, "HangingTool", -76.34, 4.2 + (i % 2) * 0.6, -10 + i * 1, -76.28, 6.8 - (i % 3) * 0.4, -9.7 + i * 1, C.Metal:Lerp(C.Ink, 0.2), M.Metal, SM)
end
B.trunk(TR, cf(-75.2, 0.05, -2.5, "+x"), C.WoodDark:Lerp(C.Mustard, 0.15), A, 2, { w = 3.6, d = 2.2 })
B.loot(A, 2, V(-75.2, 2.2, -2.5))
B.box(TR, "OilCan", -72.2, 0.05, 12.6, -71.6, 1, 13.2, C.Mustard:Lerp(C.Ink, 0.3), M.Metal, SM)
B.lamp(TR, "bare", cf(-71, 9.6, -3.6), A, { drop = 1.6, range = 16, bright = 0.7 })
B.creak(-71.4, 0.05, -8.5, 0)

----------------------------------------------------------------- root cellar dressing
do
	local sb = cf(-75.2, -10, 20, "+x")
	local _, ys = B.shelves(CE, sb, 8, 7, 1.6, 4)
	for i, y in ys do
		if i > 1 then
			for k = 0, 4 do
				B.jar(CE, (sb * CFrame.new(-3.2 + k * 1.5, y, 0)).Position, ({ C.Mustard, C.Blood, C.Mint, C.Rose })[(i + k) % 4 + 1]:Lerp(C.Ink, 0.35), 0.9)
			end
		end
	end
	B.loot(A, 3, (sb * CFrame.new(-2, ys[1], 0)).Position)
	B.loot(A, 3, (sb * CFrame.new(2.5, ys[1], 0)).Position)
	B.loot(A, 3, (sb * CFrame.new(3.4, ys[3], 0)).Position)
end
B.wardrobe(CE, cf(-45.9, -10, 22, "-x"), C.WoodDark:Lerp(C.Rose, 0.1), A, "Wardrobe", { name = "CellarWardrobe", w = 5.2, h = 8.2 })
-- Grandpa's shrine (candles, photo, the Prize)
do
	local sb = cf(-60, -10, 32.6, "-z")
	local _, th = B.table(CE, sb, 5, 2, 3, C.WoodDark, { name = "ShrineTable", cloth = C.Blood:Lerp(C.Ink, 0.4) })
	local ty = -10 + th
	B.lamp(CE, "candle", cf(-61.8, ty, 32.9), A, { h = 0.9, range = 12, bright = 0.9, color = Color3.fromRGB(255, 160, 90) })
	B.candleSet(CE, V(-58, ty, 32.9), 4, 2)
	B.box(CE, "PhotoFrame", -60.6, ty, 33.3, -59.4, ty + 1.5, 33.45, C.Brass:Lerp(C.Ink, 0.3), M.Metal, SM)
	B.box(CE, "Photo", -60.45, ty + 0.15, 33.24, -59.55, ty + 1.35, 33.3, C.Paper:Lerp(C.Ink, 0.5), M.SmoothPlastic, SM)
	B.prize(A, V(-60, ty, 32.4))
end
-- sack pile (HidingSpot, prone)
do
	local b = cf(-72, -10, 31, "+x")
	local m = B.lowHide(CE, b, A, { name = "PotatoSacks", len = 7, wid = 3.6, h = 3, col = C.Mustard:Lerp(C.WoodDark, 0.55), mat = M.Fabric, over = 0.5 })
	for i = 0, 3 do
		B.part(m, "Sack", V(2.2, 1.2, 1.6), b * CFrame.new(((i % 2) - 0.5) * 1.3, 3.5, -2.4 + i * 1.6) * CFrame.Angles(0, math.rad(i * 30), 0), C.Mustard:Lerp(C.WoodDark, 0.45 + (i % 2) * 0.1), M.Fabric, { small = true, shape = Enum.PartType.Ball })
	end
end
B.trunk(CE, cf(-50, -10, 32.9, "-z"), C.WoodDark:Lerp(C.Blood, 0.2), A, 3, { w = 3.6, d = 2.2 })
B.trunk(CE, cf(-67, -10, 14.2, "+z"), C.WoodMid:Lerp(C.Ink, 0.3), A, 3, { w = 3.6, d = 2.2 })
B.dresser(CE, cf(-47, -10, 14.1, "+z"), 4, 2, 3.4, C.WoodMid:Lerp(C.Ink, 0.35), 3, A, 3, { search = { 2 }, kind = "Cabinet", name = "CellarCabinet" })
-- root crates, coal
for i, p in { V(-56, 0, 27), V(-53.6, 0, 27.2), V(-54.8, 1.6, 27.1) } do
	B.box(CE, "Crate", p.X - 1.1, -10 + p.Y, p.Z - 1, p.X + 1.1, -8.4 + p.Y, p.Z + 1, C.WoodRaw:Lerp(C.Ink, 0.2 + i * 0.05), M.WoodPlanks, { collide = true })
end
B.loot(A, 3, V(-54.8, -6.8, 27.1))
B.part(CE, "CoalHeap", V(5, 2.4, 4), CFrame.new(-46.5, -9.4, 28), C.Ink, M.Slate, { collide = true, shape = Enum.PartType.Ball })
B.lamp(CE, "bare", cf(-66, -1.9, 20), A, { drop = 1.2, range = 16, bright = 0.7 })
B.lamp(CE, "bare", cf(-54, -1.9, 26), A, { drop = 1.2, range = 16, bright = 0.6 })
B.creak(-58.5, -10, 22, 0)
B.cobweb(CE, V(-75.5, -2.5, 33.5), 45, 1)
B.cobweb(CE, V(-44.5, -2.5, 13.5), -135, 1)
B.cobweb(CE, V(-65.4, -2.5, 8), 90, 0.9)

----------------------------------------------------------------- rooms + nodes
B.room("Potting Shed", A, 2, -65.75, 0, -15.5, -50.5, 12, 13.5)
B.room("Tool Room", A, 2, -76.5, 0, -15.5, -66.25, 12, 13.5)
B.room("Cellar Steps", A, 3, -65.75, -10, -8, -58.75, 0, 12.5)
B.room("Root Cellar", A, 3, -76, -10, 13, -44, -1, 34)
for _, n in { { -56, 0.05, -12 }, { -62, 0.05, 7 }, { -57, 0.05, 6 }, { -71, 0.05, -6 }, { -70.2, 0.05, 2 }, { -62.25, -10, 10 }, { -68, -10, 20 }, { -52, -10, 20 }, { -66, -10, 28 }, { -60.5, -10, 28.5 } } do
	B.node(A, n[1], n[2], n[3])
end
B.prize(A, V(-50, -7.8, 32.9)) -- on the cellar trunk
return "04 shed ok, parts=" .. B.count(root)
