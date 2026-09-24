-- St. Mildred's 06: ATTIC = THE GRAVEYARD (night 4): chained gate (Barrier), lantern-lit path loop, graves, yews,
-- mausoleum (prize, niche hiding), gardener's hut (cupboard hiding, workbench), planter hiding.
local B = _G.SMB
local C, M = B.C, B.M
local V = Vector3.new
local SM = B.SM
local AT = B.F("Attic")
local S = B.F("Structure")
local IA = B.F("Interactables")
local oak = C.Oak
local oakD = C.Oak:Lerp(C.Ink, 0.3)
local stone = C.StoneD:Lerp(C.Ink, 0.1)
local function R(m, n, b, sz, off, col, mat, o) return B.rp(m, n, b, sz, off, col, mat, o) end

----------------------------------------------------------------- barrier: chained graveyard gate
do
	local m = B.model(B.F("Barriers"), "Barrier_Attic")
	for i = 0, 12 do
		local x = 40.5 + i * 0.58
		local h = 6.4 + math.sin(i / 12 * math.pi) * 1.2
		B.cyl(m, "Bar", CFrame.new(x, 0, 52.25), 0.14, h, V(0, h / 2, 0), C.Iron, M.Metal, { collide = true, query = true })
		B.ball(m, "Finial", CFrame.new(x, h, 52.25), 0.26, V(0, 0.05, 0), C.Iron, M.Metal, SM)
	end
	for _, y in { 1.0, 5.2 } do
		B.box(m, "Rail", 40.15, y - 0.12, 52.13, 47.85, y + 0.12, 52.37, C.Iron, M.Metal, { collide = true })
	end
	B.box(m, "Chain", 43.1, 3.2, 51.95, 44.9, 3.4, 52.05, C.Metal, M.Metal, SM)
	B.box(m, "Chain", 43.1, 3.2, 52.45, 44.9, 3.4, 52.55, C.Metal, M.Metal, SM)
	B.box(m, "Padlock", 43.7, 2.5, 51.75, 44.3, 3.3, 51.95, C.Brass, M.Metal, SM)
	B.box(m, "Collider", 40.05, 0, 51.6, 47.95, 10, 52.9, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	m.PrimaryPart = m:FindFirstChild("Collider")
	B.attrs(m, { Area = "Attic" })
end

----------------------------------------------------------------- paths (loop around the central graves)
local EX = B.F("Exterior")
local gravel = C.Stone:Lerp(C.Paper, 0.2)
local function path(x0, z0, x1, z1, h)
	B.box(EX, "Path", x0, -0.2, z0, x1, h or 0.05, z1, gravel, M.Pebble, { solid = true })
end
path(40, 53, 47, 59)
path(-40, 59, 47, 66)
path(40, 66, 47, 86)
path(-40, 79, 40, 86)
path(-40, 66, -33, 79)
path(-46, 57, -40, 63)

----------------------------------------------------------------- graves, yews, lanterns
local GY = B.model(EX, "Graveyard")
local kinds = { "stone", "stone", "cross", "stone", "slab", "stone", "cross" }
local k = 0
local function g(x, z, rot)
	k += 1
	local m = B.grave(GY, V(x, 0, z), rot or 0, kinds[(k % #kinds) + 1])
	local top = m:FindFirstChild("Top")
	if top then top.CFrame = top.CFrame * CFrame.Angles(0, math.rad(90), 0) end
	return m
end
for x = -30, 35, 5 do
	g(x, 70.5)
	g(x + 1.2, 77)
end
for _, x in { -55, -49 } do
	for _, z in { 74, 81, 88 } do g(x, z) end
end
for _, x in { -35, -25, -15, 15, 25, 35 } do g(x, 94) end
for _, x in { 52, 57 } do
	for _, z in { 72, 80, 88, 95 } do g(x, z) end
end
B.yew(EX, V(54, 0, 59.5), 1.1)
B.yew(EX, V(-53, 0, 95.4), 1)
B.yew(EX, V(-42, 0, 95.5), 0.9)
B.yew(EX, V(42, 0, 95.5), 0.9)
for i, p in { { -31.8, 67.6 }, { 38.3, 67.6 }, { -31.8, 77.6 }, { 38.3, 77.8 }, { 0, 56.5 }, { 49, 76 }, { -20, 88.3 }, { 20, 88.3 } } do
	B.lanternPost(EX, V(p[1], 0, p[2]), 6.5, i == 2 or i == 3 or i == 6 or i == 8)
end
-- benches on the loop (+ loot), flowers on a grave
for _, p in { { -20, 57.8, "+z" }, { 20, 57.8, "+z" } } do
	local bm = B.model(EX, "Bench")
	local b = B.cf(p[1], 0, p[2], p[3])
	R(bm, "Seat", b, V(4.5, 0.3, 1.4), V(0, 1.7, 0), oak, M.Wood, { solid = true })
	R(bm, "Back", b, V(4.5, 1.4, 0.2), V(0, 2.8, 0.6), oak, M.Wood, SM)
	R(bm, "Leg", b, V(0.3, 1.55, 1.2), V(-1.9, 0.78, 0), C.Iron, M.Metal, { solid = true })
	R(bm, "Leg", b, V(0.3, 1.55, 1.2), V(1.9, 0.78, 0), C.Iron, M.Metal, { solid = true })
	B.L(V(p[1] + 1, 1.85, p[2]))
end
B.lilies(GY, V(10, 0, 67.6), 0.8, true)
B.L(V(-19.8, 0.2, 67.7))
B.L(V(31.2, 0.2, 74.3))
B.L(V(-52, 0.2, 81.2))
B.L(V(54.5, 0.2, 85.1))

----------------------------------------------------------------- mausoleum
do
	local MS = B.model(AT, "Mausoleum")
	local W = function(axis, f0, f1, a, b, y0, y1, holes)
		return B.wallH(MS, "Wall", axis, f0, f1, a, b, y0, y1, holes, stone, M.Limestone)
	end
	W("z", -8, -6.5, 88.5, 100, 0, 10)
	W("z", 6.5, 8, 88.5, 100, 0, 10)
	W("x", 98.5, 100, -6.5, 6.5, 0, 10)
	W("x", 88.5, 90, -6.5, 6.5, 0, 10, { B.Dh(0, 0) })
	B.frame(MS, "x", 89.25, 0, 0, 1.5, stone:Lerp(C.Paper, 0.15), { hood = true })
	B.box(MS, "Floor", -6.5, -0.2, 90, 6.5, 0.04, 98.5, stone:Lerp(C.Paper, 0.2), M.Marble, { solid = true })
	B.box(MS, "Roof", -8.6, 10, 85.9, 8.6, 11, 100.3, stone:Lerp(C.Ink, 0.15), M.Slate, { solid = true })
	for _, s in { -1, 1 } do -- pediment halves
		local ctr = V(s * 4.3, 12.5, 86.5)
		B.part(MS, "Pediment", V(1.2, 3, 8.6), CFrame.lookAt(ctr, ctr + V(s, 0, 0)), stone, M.Limestone, { solid = true, class = "WedgePart" })
	end
	for _, x in { -5.2, 5.2 } do -- portico columns
		B.cyl(MS, "Column", CFrame.new(x, 0, 87.3), 1.1, 10, V(0, 5, 0), stone:Lerp(C.Paper, 0.1), M.Marble, { solid = true })
	end
	B.box(MS, "Step", -6.5, -0.2, 86, 6.5, 0.05, 88.3, stone, M.Limestone, { solid = true })
	B.door2(IA, "MausoleumDoor", "x", 89.25, 0, 0, true, false, C.Iron:Lerp(C.Mint, 0.2), 1, { mat = M.Metal })
	-- sarcophagus (prize), niche (hiding), urns, candles
	local sc = B.model(MS, "Sarcophagus")
	B.box(sc, "Chest", 1.7, 0.04, 93.8, 5.7, 3, 97.8, stone:Lerp(C.Paper, 0.1), M.Marble, { solid = true })
	B.box(sc, "Lid", 1.5, 3, 93.6, 5.9, 3.4, 98.0, stone:Lerp(C.Paper, 0.25), M.Marble, { solid = true })
	B.PZ(V(3.7, 3.4, 95.2))
	B.L(V(5.0, 3.4, 97.3))
	B.candleLamp(MS, V(2.0, 3.4, 93.9), 0.9, { range = 12, bright = 0.75 })
	B.candleDecor(MS, V(5.4, 3.4, 97.7), 0.7)
	local ni = B.wardrobe(MS, B.cf(-4.6, 0.04, 95.7, "+x"), stone:Lerp(C.Ink, 0.1), B.A(V(-0.6, 0.5, 95.7)), "Cabinet", { name = "MausoleumNiche", w = 3.4, h = 6.4, doorColor = stone:Lerp(C.Paper, 0.15) })
	for _, p in ni:GetDescendants() do
		if p:IsA("BasePart") and p.Material == M.Wood then p.Material = M.Limestone end
	end
	B.L(V(-4.6, 6.9, 95.7))
	B.box(MS, "Shelf", -6.5, 5.6, 90.4, -4.9, 5.9, 93.4, stone, M.Limestone, { solid = true })
	B.lilies(MS, V(-5.7, 5.9, 91.4), 0.7)
	B.L(V(-5.7, 5.9, 92.8))
	local ch = B.trunk(MS, B.cf(5.1, 0.04, 91.6, "-x"), stone:Lerp(C.Ink, 0.2), "Attic", 3, { w = 2.4, d = 1.6 })
	ch.Name = "StoneChest"
	for _, p in ch:GetDescendants() do
		if p:IsA("BasePart") and p.Material == M.Wood then p.Material = M.Limestone end
	end
	B.S(ch:FindFirstChild("Lid"), "Trunk")
	B.box(MS, "Plaque", -2, 5.5, 98.34, 2, 7.5, 98.5, C.Brass:Lerp(C.Ink, 0.3), M.Metal, SM)
	B.cobweb(MS, V(6, 9.4, 98), 225, 1)
	B.N(0, 0.04, 92.3)
	B.N(0, 0, 84)
end

----------------------------------------------------------------- gardener's hut
do
	local HT = B.model(AT, "GardenersHut")
	local wood = C.WoodRaw:Lerp(C.Ink, 0.35)
	local W = function(axis, f0, f1, a, b, y0, y1, holes)
		return B.wallH(HT, "Wall", axis, f0, f1, a, b, y0, y1, holes, wood, M.WoodPlanks)
	end
	W("z", -59.5, -59, 53.5, 66, 0, 9)
	W("z", -46.5, -46, 53.5, 66, 0, 9, { B.Dh(60, 0), { 55, 57, 4, 7 } })
	W("x", 53.5, 54, -59, -46.5, 0, 9, { { -56, -53, 4, 7 } })
	W("x", 65.5, 66, -59, -46.5, 0, 9)
	-- window glass (square panes)
	B.box(HT, "Glass", -46.3, 4, 55, -46.2, 7, 57, C.Glass, M.Glass, { solid = true, tr = 0.4, shadow = false })
	B.box(HT, "Glass", -56, 4, 53.7, -53, 7, 53.8, C.Glass, M.Glass, { solid = true, tr = 0.4, shadow = false })
	B.frame(HT, "z", -46.25, 60, 0, 0.5, oakD, { mat = M.Wood })
	B.box(HT, "Floor", -59, -0.2, 54, -46.5, 0.04, 65.5, wood:Lerp(C.Paper, 0.1), M.WoodPlanks, { solid = true })
	B.box(HT, "Ceiling", -59, 8.6, 54, -46.5, 9, 65.5, wood, M.WoodPlanks, { solid = true })
	-- gable roof, ridge along X
	local s = 4 / 7.2
	for _, sg in { -1, 1 } do
		local len = math.sqrt(7.2 ^ 2 + 4 ^ 2) + 0.4
		local ctr = V(-52.75, 10.8, 59.75 + sg * 3.45)
		B.part(HT, "Roof", V(15 - (sg + 1) * 0.03, 0.5, len), CFrame.new(ctr) * CFrame.Angles(sg * math.atan(s), 0, 0), C.Slate:Lerp(C.Moss, 0.2), M.Slate, { solid = true })
		local gc = V(-52.75, 9, 59.75)
	end
	for _, x in { -59.25, -46.25 } do
		for _, sg in { -1, 1 } do
			local ctr = V(x, 11, 59.75 + sg * 3.125)
			B.part(HT, "Gable", V(0.5, 4, 6.25), CFrame.lookAt(ctr, ctr + V(0, 0, sg)), wood, M.WoodPlanks, { solid = true, class = "WedgePart" })
		end
	end
	B.door2(IA, "HutDoor", "z", -46.25, 60, 0, true, true, wood:Lerp(C.Paper, 0.1), 1)
	-- cupboard (hiding)
	B.wardrobe(HT, B.cf(-55.5, 0.04, 63.6, "-z"), oakD, B.A(V(-55.5, 0.5, 59.5)), "Closet", { name = "GardenersCupboard", w = 4.6, h = 7.8 })
	B.L(V(-55.5, 8.29, 63.6))
	-- workbench with drawer + cabinet
	local wb, wh = B.counter(HT, B.cf(-55, 0.04, 55.45, "+z"), 6, wood:Lerp(C.Paper, 0.15), C.WoodRaw, "Attic", 2, { [1] = "Drawer", [2] = "Cabinet" }, { name = "PottingBench" })
	for _, p in wb:GetChildren() do
		if p.Name == "Drawer" then B.S(p, "Drawer") elseif p.Name == "Cabinet" then B.S(p, "Cabinet") end
	end
	B.L(V(-56.5, 0.04 + wh, 55.3))
	B.L(V(-53.2, 0.04 + wh, 55.4))
	for i, x in { -57.8, -56.9, -55.9 } do
		B.cyl(HT, "Pot", CFrame.new(x, 0.04 + wh, 55.8), 0.7, 0.7, V(0, 0.35, 0), C.Brick:Lerp(C.Paper, 0.1 * i), M.Brick, SM)
	end
	-- tool chest, shelf, sacks, tools, lamp
	local tc = B.trunk(HT, B.cf(-58, 0.04, 59.8, "+x"), wood, "Attic", 2, { w = 2.8, d = 1.6 })
	tc.Name = "ToolChest"
	B.S(tc:FindFirstChild("Lid"), "Trunk")
	B.box(HT, "Shelf", -59, 5.2, 57, -57.8, 5.45, 59.4, wood:Lerp(C.Paper, 0.2), M.Wood, { solid = true })
	B.L(V(-58.4, 5.45, 58.2))
	for _, z in { 57.4, 58.9 } do B.jar(HT, V(-58.4, 5.45, z), C.Mint:Lerp(C.Ink, 0.3), 1) end
	B.box(HT, "Sack", -50.2, 0.04, 64.2, -48.4, 2.2, 65.4, C.WoodRaw:Lerp(C.Paper, 0.3), M.Fabric, { solid = true })
	B.box(HT, "Sack", -52.1, 0.04, 64.4, -50.5, 1.8, 65.4, C.WoodRaw:Lerp(C.Paper, 0.2), M.Fabric, { solid = true })
	B.part(HT, "Spade", V(0.12, 4.5, 0.6), CFrame.new(-47.0, 2.32, 64.5) * CFrame.Angles(0, 0, math.rad(-6)), C.Metal, M.Metal, SM)
	B.part(HT, "Rake", V(0.12, 5, 0.12), CFrame.new(-47.2, 2.56, 64.9) * CFrame.Angles(0, 0, math.rad(-5)), oakD, M.Wood, SM)
	B.LP(HT, "bare", CFrame.new(-52.75, 8.6, 59.75), { drop = 1.4, range = 18, bright = 0.9 })
	B.creak(-51.5, 0.04, 58.8)
	B.N(-51.8, 0.04, 60.2)
	B.cobweb(HT, V(-58.4, 8.1, 65), 135, 0.9)
end

----------------------------------------------------------------- large planter / compost bin (hiding, Cabinet)
do
	local m = B.model(EX, "CompostPlanter")
	local wood = C.WoodRaw:Lerp(C.Ink, 0.4)
	local cx, cz = -44.5, 69.5
	B.box(m, "SideN", cx - 2.2, 0, cz + 1.9, cx + 2.2, 3.6, cz + 2.2, wood, M.WoodPlanks, { solid = true })
	B.box(m, "SideS", cx - 2.2, 0, cz - 2.2, cx + 2.2, 3.6, cz - 1.9, wood, M.WoodPlanks, { solid = true })
	B.box(m, "SideW", cx - 2.2, 0, cz - 1.9, cx - 1.9, 3.6, cz + 1.9, wood, M.WoodPlanks, { solid = true })
	B.box(m, "SideE", cx + 1.9, 0, cz - 1.9, cx + 2.2, 3.6, cz + 1.9, wood, M.WoodPlanks, { solid = true })
	local lid = B.box(m, "Lid", cx - 2.2, 3.6, cz - 2.2, cx + 2.2, 3.85, cz + 2.2, wood:Lerp(C.Ink, 0.2), M.WoodPlanks, { solid = true })
	lid.CFrame = lid.CFrame * CFrame.Angles(0, 0, math.rad(-4))
	B.HP(m, "Cabinet", CFrame.lookAt(V(cx, 1.6, cz), V(cx + 5, 1.6, cz)), V(cx + 4.3, 0, cz), V(cx + 4.1, 0, cz + 1.2))
end

----------------------------------------------------------------- search nodes (graveyard)
for _, n in { { 43.5, 0, 56 }, { -20, 0, 62.5 }, { -36.5, 0, 72 }, { -20, 0, 82.5 }, { 43.5, 0, 72 }, { 20, 0, 82.5 } } do
	B.N(n[1], n[2], n[3])
end
return "graveyard ok, parts=" .. B.count(B.root())
