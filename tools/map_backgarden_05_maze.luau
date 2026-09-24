-- BackGarden 05: THE HEDGE MAZE (Area "Attic", unlocks night 4 of the chapter).
-- 6x6 cells of 10 studs: grid lines x = 72 + 10i, z = -20 + 10j (hedges 2 thick, 9.5 tall, 8-stud corridors).
-- Entrance on the west line at cell (0,0) behind a chained iron gate (Barrier). Gazebo clearing in the centre
-- 2x2 cells (x 92..112, z 0..20) with two entrances. Several loops + dead ends; two garden doors inside.
local B = _G.BGB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local SM = { small = true }
local root = B.root()
local AT = B.F("Attic")
local A = "Attic"
-- idempotent re-run of this chunk: clear the previous maze build
for _, c in AT:GetChildren() do c:Destroy() end
if B.F("Barriers"):FindFirstChild("MazeGate") then B.F("Barriers").MazeGate:Destroy() end
for _, fn in { "Rooms", "LootSpawns", "PrizeSpawns", "SearchNodes" } do
	for _, c in B.F(fn):GetChildren() do
		if c:GetAttribute("Area") == "Attic" then c:Destroy() end
	end
end
for _, c in B.F("Creaky"):GetChildren() do if c.Position.X - B.OX > 72 then c:Destroy() end end
local MZ = B.model(AT, "HedgeMaze")
local H = 9.5
local function X(i) return 72 + 10 * i end
local function Z(j) return -20 + 10 * j end
local function cellC(i, j) return V(77 + 10 * i, 0, -15 + 10 * j) end

-- wall layout (V = vertical line x=X(i) spanning row j; H = horizontal line z=Z(j) spanning column i)
local VW, HW = {}, {}
for j = 1, 5 do VW["0," .. j] = "wall" end
for j = 0, 5 do VW["6," .. j] = "wall" end
for i = 0, 5 do HW[i .. ",0"] = "wall"; HW[i .. ",6"] = "wall" end
for _, k in { "1,1", "1,2", "1,4", "5,2", "5,3", "5,4", "3,5", "4,0", "2,1", "2,3", "4,2" } do VW[k] = "wall" end
VW["5,1"] = "gate"
for _, k in { "1,1", "3,1", "4,1", "2,5", "3,5", "0,5", "2,2", "3,2", "2,4", "3,4" } do HW[k] = "wall" end
HW["2,1"] = "gate"

local function topPiece(x0, z0, x1, z1, ya, yb)
	B.box(MZ, "Hedge", x0, ya, z0, x1, yb, z1, C.Hedge, M.LeafyGrass, { solid = true })
	B.box(MZ, "HedgeTop", x0 + 0.2, yb, z0 + 0.2, x1 - 0.2, yb + 0.35, z1 - 0.2, C.HedgeTop, M.LeafyGrass, SM)
end
local gates = {}
for k, kind in VW do
	local i, j = string.match(k, "(%d+),(%d+)")
	i, j = tonumber(i), tonumber(j)
	local x, z0, z1 = X(i), Z(j) + 1, Z(j + 1) - 1
	if kind == "wall" then
		B.hedge(MZ, x - 1, z0, x + 1, z1, H)
	else
		local c = (z0 + z1) / 2
		for _, pc in B.pieces(z0, z1, 0, H, { B.dgap(c) }) do
			if pc[3] > 0.1 then topPiece(x - 1, pc[1], x + 1, pc[2], pc[3], pc[4]) else B.hedge(MZ, x - 1, pc[1], x + 1, pc[2], H, { nolumps = true }) end
		end
		table.insert(gates, { "z", x, c })
	end
end
for k, kind in HW do
	local i, j = string.match(k, "(%d+),(%d+)")
	i, j = tonumber(i), tonumber(j)
	local z, x0, x1 = Z(j), X(i) + 1, X(i + 1) - 1
	if kind == "wall" then
		B.hedge(MZ, x0, z - 1, x1, z + 1, H)
	else
		local c = (x0 + x1) / 2
		for _, pc in B.pieces(x0, x1, 0, H, { B.dgap(c) }) do
			if pc[3] > 0.1 then topPiece(pc[1], z - 1, pc[2], z + 1, pc[3], pc[4]) else B.hedge(MZ, pc[1], z - 1, pc[2], z + 1, H, { nolumps = true }) end
		end
		table.insert(gates, { "x", z, c })
	end
end
-- posts at every grid vertex touched by a hedge
for i = 0, 6 do
	for j = 0, 6 do
		local touched = VW[i .. "," .. (j - 1)] or VW[i .. "," .. j] or HW[(i - 1) .. "," .. j] or HW[i .. "," .. j]
		if touched then
			B.hedge(MZ, X(i) - 1, Z(j) - 1, X(i) + 1, Z(j) + 1, H, { nolumps = true })
			if (i + j) % 2 == 0 then
				B.part(MZ, "Finial", V(1.8, 1.8, 1.8), CFrame.new(X(i), H + 1.1, Z(j)), C.HedgeTop, M.LeafyGrass, { small = true, shape = Enum.PartType.Ball })
			end
		end
	end
end
-- west hedge outside the grid (lane wall to the maze, maze to the house wall)
B.hedge(MZ, 71, -28, 73, -21, H)
B.hedge(MZ, 71, 41, 73, 60, H)
-- the two garden doors inside the maze
for n, g in gates do
	B.door2(AT, "MazeDoor" .. n, g[1], g[2], g[3], 0, A, { style = "garden", color = C.WoodDark:Lerp(C.Moss, 0.3), wallT = 2, squeaky = n == 1, frameColor = C.WoodDark })
end

----------------------------------------------------------------- entrance: stone pillars + chained iron gate (Barrier)
do
	local EN = B.model(AT, "MazeEntrance")
	for _, z in { -21.2, -8.8 } do
		B.box(EN, "Pillar", 69.4, 0, z - 1.1, 71, 10, z + 1.1, C.Stone:Lerp(C.Paper, 0.25), M.Slate, { solid = true })
		B.box(EN, "PillarCap", 69.2, 10, z - 1.3, 71.2, 10.4, z + 1.3, C.Stone:Lerp(C.Paper, 0.35), M.Slate, SM)
		B.cyl(EN, "Urn", cf(70.2, 10.4, z), 1.2, 1, V(0, 0.5, 0), C.Stone:Lerp(C.Paper, 0.3), M.Slate, SM, true)
		B.ball(EN, "UrnIvy", cf(70.2, 10.4, z), 1.3, V(0, 1.3, 0), C.Moss:Lerp(C.Ink, 0.3), M.LeafyGrass, SM)
	end
	B.box(EN, "Plaque", 69.3, 5, -20.2, 69.4, 6.2, -18.3, C.Brass:Lerp(C.Ink, 0.4), M.Metal, SM)
end
B.barrier(A, "MazeGate", "z", 72, -15, 0, 8, 9.2, -1, { iron = true, d = 1.35 })

----------------------------------------------------------------- the gazebo (centre clearing x 93..111, z 1..19)
local GZ = B.model(AT, "Gazebo")
local gc = V(102, 0, 10)
local wood = C.Paper:Lerp(C.Ink, 0.35)
B.part(GZ, "GazeboFloor", V(0.1, 14.8, 14.8), CFrame.new(gc + V(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90)), C.WoodMid:Lerp(C.Paper, 0.1), M.WoodPlanks, { solid = true, shape = Enum.PartType.Cylinder })
-- open-sided hexagon: six posts (r 6.5, 6 clear between them) so Grandma can walk in from either maze entrance
for k = 0, 5 do
	local a = math.rad(30 + k * 60)
	local p = gc + V(math.cos(a) * 6.5, 0, math.sin(a) * 6.5)
	B.box(GZ, "GazeboPost", p.X - 0.25, 0.1, p.Z - 0.25, p.X + 0.25, 8.6, p.Z + 0.25, wood, M.Wood, { solid = true })
	local a2 = math.rad(30 + (k + 1) * 60)
	local p2 = gc + V(math.cos(a2) * 6.5, 0, math.sin(a2) * 6.5)
	local c2 = (p + p2) / 2
	local len = (p2 - p).Magnitude - 0.5
	local rot = CFrame.lookAt(c2, c2 + (p2 - p).Unit).Rotation
	B.part(GZ, "Fret", V(0.15, 0.6, len), CFrame.new(c2 + V(0, 8.1, 0)) * rot, wood, M.Wood, SM)
	for t = -1, 1 do
		B.part(GZ, "FretDrop", V(0.1, 0.9, 0.1), CFrame.new(c2 + V(0, 7.45, 0)) * rot * CFrame.new(0, 0, t * len / 3.2), wood, M.Wood, SM)
	end
end
B.cyl(GZ, "RoofBase", CFrame.new(gc), 16, 0.4, V(0, 8.8, 0), C.Roof:Lerp(C.Rose, 0.15), M.Slate, { solid = true }, true)
for i, d in { 13, 10, 6.8, 3.8 } do
	B.cyl(GZ, "RoofTier", CFrame.new(gc), d, 0.7, V(0, 8.8 + i * 0.7, 0), C.Roof:Lerp(C.Rose, 0.1 + i * 0.03), M.Slate, SM, true)
end
B.ball(GZ, "Finial", CFrame.new(gc), 0.9, V(0, 12.1, 0), C.Brass:Lerp(C.Ink, 0.3), M.Metal, SM)
B.hangLantern(GZ, gc + V(0, 8.6, 0), A, { drop = 1.4, range = 20, bright = 1, color = Color3.fromRGB(255, 170, 120), shadows = true })
-- Grandma's tea party for the dolls: round table, four stools, a doll on each
do
	local tb = CFrame.new(gc + V(0, 0.1, 0))
	B.cyl(GZ, "TeaTable", tb, 4.2, 0.25, V(0, 2.95, 0), C.WoodDark:Lerp(C.Rose, 0.1), M.Wood, { solid = true }, true)
	B.cyl(GZ, "TeaCloth", tb, 4.4, 0.06, V(0, 3.1, 0), C.Paper:Lerp(C.Rose, 0.2), M.Fabric, SM, true)
	B.cyl(GZ, "TableLeg", tb, 0.5, 2.83, V(0, 1.415, 0), C.WoodDark, M.Wood, SM, true)
	B.cyl(GZ, "TableFoot", tb, 1.8, 0.2, V(0, 0.1, 0), C.WoodDark, M.Wood, SM, true)
	for k = 0, 3, 2 do
		local a = math.rad(90 + k * 90)
		local sp = gc + V(math.cos(a) * 3.3, 0.1, math.sin(a) * 3.3)
		B.cyl(GZ, "Stool", CFrame.new(sp), 1.4, 1.8, V(0, 0.9, 0), C.WoodMid, M.Wood, { collide = true }, true)
		B.doll(GZ, CFrame.lookAt(sp + V(0, 1.8, 0), gc + V(0, 1.8, 0)), 1.1, ({ C.Rose, C.Mint, C.Bruise, C.Mustard })[k + 1]:Lerp(C.Ink, 0.3))
		B.cyl(GZ, "Teacup", CFrame.new(gc + V(math.cos(a) * 1.4, 3.13, math.sin(a) * 1.4)), 0.45, 0.35, V(0, 0.175, 0), C.Paper, M.SmoothPlastic, SM, true)
	end
	B.cyl(GZ, "Teapot", CFrame.new(gc + V(0.4, 3.13, -0.3)), 0.9, 0.8, V(0, 0.4, 0), C.Mint:Lerp(C.Paper, 0.4), M.SmoothPlastic, SM, true)
	B.prize(A, gc + V(-0.6, 3.13, 0.5))
	B.loot(A, 3, gc + V(1.1, 3.13, 0.9))
	-- picnic hamper (Searchable Trunk) + side cabinet (Searchable Cabinet)
	local hb = cf(105.8, 0.1, 12.2, "-x")
	local hm = B.model(GZ, "Hamper")
	B.rp(hm, "Body", hb, V(2.6, 1.4, 1.8), V(0, 0.7, 0), C.Wicker, M.Fabric, { solid = true })
	local lid = B.rp(hm, "Lid", hb, V(2.7, 0.3, 1.9), V(0, 1.55, 0), C.Wicker:Lerp(C.Ink, 0.15), M.Fabric, { collide = true })
	B.searchable(lid, "Trunk", A, 3)
	B.rp(hm, "Strap", hb, V(0.25, 1.8, 1.95), V(0, 0.9, 0), C.WoodDark, M.Fabric, SM)
	local _, ch = B.dresser(GZ, cf(102, 0.1, 4.6, "+z"), 3, 1.6, 3, C.Mint:Lerp(C.Ink, 0.45), 2, A, 3, { search = { 1 }, kind = "Cabinet", name = "GazeboCabinet" })
	B.loot(A, 3, V(102.6, 0.1 + ch, 4.6))
end

----------------------------------------------------------------- hiding spots
do
	-- hedge nook at the dead end of cell (3,0)
	local function nook(b, name)
		local m = B.hideBox(MZ, b, A, { name = name, w = 4.8, d = 3.8, h = 9.3, col = C.Hedge, mat = M.LeafyGrass, doorColor = C.Hedge:Lerp(C.Moss, 0.25), kind = "Closet" })
		for _, c in m:GetChildren() do if c.Name == "Inset" or c.Name == "Handle" then c:Destroy() end end
		for i = 0, 5 do
			B.part(m, "Ivy", V(1.5, 2.4, 0.3), b * CFrame.new(-1.6 + (i % 3) * 1.6, 1.6 + math.floor(i / 3) * 4, -1.95) * CFrame.Angles(0, 0, math.rad(i * 29)), C.Moss:Lerp(C.Ink, 0.15), M.LeafyGrass, SM)
		end
		return m
	end
	nook(cf(109.1, 0, -15, "-x"), "HedgeNook_S")
	nook(cf(104.9, 0, 35, "+x"), "HedgeNook_N")
	-- topiary bear with a hollow belly at the dead end of cell (1,1)
	local b = cf(87, 0, -6.9, "+z")
	local bear = B.hideBox(MZ, b, A, { name = "TopiaryBear", w = 5.2, d = 4.2, h = 7.4, col = C.Hedge:Lerp(C.Moss, 0.15), mat = M.LeafyGrass, doorColor = C.Hedge:Lerp(C.Moss, 0.3), kind = "Closet" })
	for _, c in bear:GetChildren() do if c.Name == "Inset" or c.Name == "Handle" then c:Destroy() end end
	B.ball(bear, "Head", b, 4, V(0, 9.2, 0), C.Hedge:Lerp(C.Moss, 0.2), M.LeafyGrass, SM)
	for _, sx in { -1, 1 } do
		B.ball(bear, "Ear", b, 1.4, V(sx * 1.4, 11, 0.2), C.Hedge:Lerp(C.Moss, 0.2), M.LeafyGrass, SM)
		B.ball(bear, "Eye", b, 0.35, V(sx * 0.7, 9.6, -1.9), C.Blood:Lerp(C.Ink, 0.3), M.Neon, SM)
		B.part(bear, "Arm", V(1.4, 4, 1.4), b * CFrame.new(sx * 3, 4.8, -0.4) * CFrame.Angles(0, 0, math.rad(sx * 15)), C.Hedge:Lerp(C.Moss, 0.2), M.LeafyGrass, { small = true, shape = Enum.PartType.Ball })
	end
	B.ball(bear, "Snout", b, 1.4, V(0, 8.7, -1.8), C.HedgeTop, M.LeafyGrass, SM)
	bear:SetAttribute("NoGround", true)
end

----------------------------------------------------------------- dressing: statues, topiaries, lanterns, gravel, dead-end treasures
do
	-- stone angel at the (0,5) dead end, with a Prize on its plinth
	local p = cellC(0, 5)
	local an = B.model(MZ, "StoneAngel")
	B.box(an, "Plinth", p.X - 1.4, 0, p.Z + 1.2, p.X + 1.4, 1.6, p.Z + 3.6, C.Stone:Lerp(C.Paper, 0.3), M.Slate, { solid = true })
	B.box(an, "Body", p.X - 0.7, 1.6, p.Z + 1.9, p.X + 0.7, 4.8, p.Z + 2.9, C.Stone:Lerp(C.Paper, 0.35), M.Slate, { collide = true })
	B.part(an, "Head", V(1, 1, 1), CFrame.new(p.X, 5.35, p.Z + 2.4), C.Stone:Lerp(C.Paper, 0.35), M.Slate, { small = true, shape = Enum.PartType.Ball })
	for _, sx in { -1, 1 } do
		B.part(an, "Wing", V(0.2, 3, 1.6), CFrame.new(p.X + sx * 0.9, 4.2, p.Z + 3.1) * CFrame.Angles(0, math.rad(sx * 30), math.rad(sx * -12)), C.Stone:Lerp(C.Paper, 0.3), M.Slate, SM)
	end
	B.box(an, "Tear", p.X - 0.25, 4.9, p.Z + 1.85, p.X - 0.15, 5.3, p.Z + 1.9, C.Blood, M.SmoothPlastic, SM)
	B.prize(A, V(p.X + 0.9, 1.6, p.Z + 1.8))
	B.trunk(MZ, cf(p.X - 2.4, 0, p.Z - 2, "+x"), C.WoodDark:Lerp(C.Moss, 0.3), A, 3, { w = 3.2, d = 2 })
	-- a plinth with a prize at the (3,0) dead end, in front of the nook
	local q = cellC(3, 0)
	B.box(MZ, "SundialPlinth", q.X - 3.2, 0, q.Z + 1.8, q.X - 1.8, 2.6, q.Z + 3.2, C.Stone:Lerp(C.Paper, 0.3), M.Slate, { solid = true })
	B.prize(A, V(q.X - 2.5, 2.6, q.Z + 2.5))
end
local function topiary(p, kind)
	local t = B.model(MZ, "Topiary_" .. kind)
	B.cyl(t, "Tub", CFrame.new(p), 2.4, 1.6, V(0, 0.8, 0), C.Terracotta:Lerp(C.Ink, 0.3), M.Slate, { solid = true }, true)
	if kind == "rabbit" then
		B.ball(t, "Body", CFrame.new(p), 2.6, V(0, 2.8, 0), C.Hedge:Lerp(C.Moss, 0.2), M.LeafyGrass, SM)
		B.ball(t, "Head", CFrame.new(p), 1.6, V(0, 4.6, -0.5), C.Hedge:Lerp(C.Moss, 0.2), M.LeafyGrass, SM)
		for _, sx in { -1, 1 } do B.part(t, "Ear", V(0.5, 2, 0.6), CFrame.new(p + V(sx * 0.4, 6, -0.4)) * CFrame.Angles(0, 0, math.rad(sx * -10)), C.Hedge:Lerp(C.Moss, 0.2), M.LeafyGrass, SM) end
	else
		B.ball(t, "Body", CFrame.new(p), 2.8, V(0, 2.9, 0), C.Hedge:Lerp(C.Moss, 0.2), M.LeafyGrass, SM)
		B.part(t, "Neck", V(0.7, 3, 0.7), CFrame.new(p + V(0, 4.8, -0.9)) * CFrame.Angles(math.rad(-15), 0, 0), C.Hedge:Lerp(C.Moss, 0.2), M.LeafyGrass, SM)
		B.ball(t, "Head", CFrame.new(p), 1.1, V(0, 6.4, -1.3), C.Hedge:Lerp(C.Moss, 0.2), M.LeafyGrass, SM)
	end
	t:SetAttribute("NoGround", true)
	return t
end
topiary(cellC(2, 5) + V(-1.5, 0, 0), "rabbit")
topiary(cellC(5, 5) + V(1.5, 0, 1.5), "swan")
topiary(cellC(5, 0) + V(1.5, 0, -1.5), "rabbit")
B.lanternPost(MZ, 77 - 2.6, 0, -5, A, { h = 6, range = 18, bright = 0.8 })
B.lanternPost(MZ, 127 + 2.6, 0, 25, A, { h = 6, range = 18, bright = 0.8 })
B.lanternPost(MZ, 87, 0, 35 + 2.6, A, { h = 6, range = 18, bright = 0.7 })
B.gravelCreak(77, 0, 5, 10)
B.gravelCreak(107, 0, 25, -15)
B.gravelCreak(127, 0, 15, 30)
B.gravelCreak(87, 0, 15, 5)
B.cobweb(MZ, V(111, 8.5, -19), 45, 1)
-- loot scattered in the maze
for _, p in { cellC(0, 0) + V(2.4, 0, 2.4), cellC(0, 4) + V(-2.8, 0, 0), cellC(1, 1) + V(3.3, 0, 2), cellC(2, 5) + V(2, 0, 1.5), cellC(3, 0) + V(-3, 0, -2.5), cellC(5, 0) + V(-2, 0, 2), cellC(4, 5) + V(0, 0, 2.6), cellC(5, 3) + V(2.6, 0, 0) } do
	B.loot(A, 3, p)
end
B.loot(A, 3, V(cellC(0, 5).X - 2.4, 2.2, cellC(0, 5).Z - 2))

----------------------------------------------------------------- rooms + nodes
B.room("The Hedge Maze", A, 3, 73, 0, -19, 131, 14, 1)
B.room("The Hedge Maze", A, 3, 73, 0, 19, 131, 14, 39)
B.room("The Hedge Maze", A, 3, 73, 0, 1, 93, 14, 19)
B.room("The Hedge Maze", A, 3, 111, 0, 1, 131, 14, 19)
B.room("The Gazebo", A, 3, 93, 0, 1, 111, 14, 19)
for _, c in { { 0, 0 }, { 0, 3 }, { 1, 3 }, { 2, 0 }, { 3, 1 }, { 5, 1 }, { 5, 4 }, { 4, 5 }, { 1, 5 }, { 4, 2 } } do
	local p = cellC(c[1], c[2])
	B.node(A, p.X, 0, p.Z)
end
B.node(A, 97, 0.1, 10)
return "05 maze ok, parts=" .. B.count(root)
