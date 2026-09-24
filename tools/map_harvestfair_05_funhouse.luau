-- HarvestFair "Upstairs" zone = THE FUNHOUSE (night 2): two-storey wooden funhouse, x 58..100, z -5..35.
-- Ground: lobby (clown-mouth entrance, Barrier), tilted room (hump floor), barrel tunnel, workshop.
-- Two ramps (south up / north down, 29 deg) to the upper floor: costume loft + clown gallery.
-- Section "funhouse" (idempotent).
local B = _G.HF
local C, M = B.C, B.M
local V = Vector3.new
local root = B.root()
local S = B.begin("funhouse")
local SM = { small = true }
local U = "Upstairs"
local function sdoor(par, name, center, dir, w, h, col, kind, danger)
	local p = B.part(par, name, V(w, h, 0.12), CFrame.lookAt(center, center + dir), col, M.Wood, { collide = false, shadow = false })
	return B.searchable(p, kind, U, danger or 2)
end
local X0, X1, Z0, Z1 = 58, 100, -5, 35
local Y0, Y1, YT = 0.08, 12.5, 24.5 -- ground floor top, upper floor top, wall top
local wood = C.WoodMid:Lerp(C.Ink, 0.15)
local inW = C.Cream:Lerp(C.Ink, 0.3)

----------------------------------------------------------------- shell
local SH = B.model(S, "Shell")
B.box(SH, "Floor", X0, -0.3, Z0, X1, Y0, Z1, C.WoodMid:Lerp(C.Ink, 0.3), M.WoodPlanks, { solid = true })
-- exterior walls: painted vertical stripes (mustard / red), clown-mouth entrance west at z 15
local e1, e2 = C.Mustard:Lerp(C.Ink, 0.35), C.Red:Lerp(C.Ink, 0.3)
B.stripes(SH, "OuterWall", "z", X0 + 0.25, Z0, Z1, Y0, YT, 0.5, e1, e2, 4, { { c = 15, w = 8, h = 9 } }, M.WoodPlanks)
B.stripes(SH, "OuterWall", "z", X1 - 0.25, Z0, Z1, Y0, YT, 0.5, e1, e2, 4, nil, M.WoodPlanks)
B.stripes(SH, "OuterWall", "x", Z0 + 0.25, X0 + 0.5, X1 - 0.5, Y0, YT, 0.5, e1, e2, 4, nil, M.WoodPlanks)
B.stripes(SH, "OuterWall", "x", Z1 - 0.25, X0 + 0.5, X1 - 0.5, Y0, YT, 0.5, e1, e2, 4, nil, M.WoodPlanks)
B.pyramid(SH, 79, 15, 21.5, 20.5, YT, 10, C.Red:Lerp(C.Ink, 0.35), C.Cream:Lerp(C.Ink, 0.35), M.WoodPlanks)
B.box(SH, "Eave", X0 - 0.5, YT - 0.6, Z0 - 0.5, X1 + 0.5, YT, Z0, C.Ink, M.Wood, SM)
B.box(SH, "Eave", X0 - 0.5, YT - 0.6, Z1, X1 + 0.5, YT, Z1 + 0.5, C.Ink, M.Wood, SM)
-- upper slab (holes over the two ramps)
B.box(SH, "UpperFloor", X0 + 0.5, 12, Z0 + 0.5, 70.5, Y1, Z1 - 0.5, wood, M.WoodPlanks, { solid = true })
B.box(SH, "UpperFloor", 70.5, 12, 3.5, 92.5, Y1, 26.5, wood, M.WoodPlanks, { solid = true })
B.box(SH, "UpperFloor", 92.5, 12, Z0 + 0.5, X1 - 0.5, Y1, Z1 - 0.5, wood, M.WoodPlanks, { solid = true })
-- ramps
B.ramp(SH, "RampUp", "x", 70.5, 92.5, -0.5, 8, Y0, Y1, C.WoodLight:Lerp(C.Ink, 0.2), M.WoodPlanks)
B.ramp(SH, "RampDown", "x", 70.5, 92.5, 30.5, 8, Y0, Y1, C.WoodLight:Lerp(C.Ink, 0.2), M.WoodPlanks)
-- rails round the ramp holes (upper floor)
local railC = C.Red:Lerp(C.Ink, 0.3)
B.rail(SH, V(70.5, Y1, 3.7), V(80, Y1, 3.7), 3.4, railC)
B.rail(SH, V(80.5, Y1, 3.7), V(92.5, Y1, 3.7), 3.4, railC)
B.rail(SH, V(70.5, Y1, 26.3), V(80, Y1, 26.3), 3.4, railC)
B.rail(SH, V(80.5, Y1, 26.3), V(92.5, Y1, 26.3), 3.4, railC)
B.rail(SH, V(70.3, Y1, Z0 + 0.5), V(70.3, Y1, 3.1), 3.4, railC)
B.rail(SH, V(70.3, Y1, 26.9), V(70.3, Y1, Z1 - 0.5), 3.4, railC)
-- ramp handrails along the open (hole) side are the block walls; add a low rail on the ramp's wall side
for _, z in { -4.3, 34.3 } do
	local a, b = V(70.5, Y0 + 3.2, z), V(92.5, Y1 + 3.2, z)
	B.part(SH, "RampHandrail", V(0.25, 0.25, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), C.WoodDark, M.Wood, SM)
end

----------------------------------------------------------------- ground floor partitions
local P = B.model(S, "GroundWalls")
-- central block walls along the ramps (z 3.5..4 and 26..26.5), full ground height
B.wall(P, "BlockWall", "x", 3.75, 70.5, 99.5, Y0, 12, 0.5, inW, M.WoodPlanks)
B.wall(P, "BlockWall", "x", 26.25, 70.5, 99.5, Y0, 12, 0.5, inW, M.WoodPlanks)
-- lobby | tilted room (x 70.5..71): Door A z 9, open doorway z 21
B.wall(P, "LobbyWall", "z", 70.75, 4, 26, Y0, 12, 0.5, inW, M.WoodPlanks, { B.DG(9), B.DG(21) })
B.doorway(P, "z", 70.75, 9, Y0, 0.5, C.WoodDark)
B.doorway(P, "z", 70.75, 21, Y0, 0.5, C.WoodDark)
B.door(P, "TiltedDoor", "z", 70.75, 9, Y0, U, true, false, C.Teal:Lerp(C.Paper, 0.2), 1)
-- tilted room | barrel (x 83.5..84): barrel mouth 12 wide x 8.485 tall at z 15
B.wall(P, "BarrelWall", "z", 83.75, 4, 26, Y0, 12, 0.5, inW, M.WoodPlanks, { { c = 15, w = 12, h = 8.485 } })
-- barrel | workshop (x 92..92.5): door z 15
B.wall(P, "WorkshopWall", "z", 92.25, 4, 26, Y0, 12, 0.5, inW, M.WoodPlanks, { B.DG(15) })
B.doorway(P, "z", 92.25, 15, Y0, 0.5, C.WoodDark)
B.door(P, "WorkshopDoor", "z", 92.25, 15, Y0, U, true, true, C.Red:Lerp(C.Paper, 0.2), 1)
-- void walls closing the spaces round the barrel (x 84..92): the barrel shell itself seals the tunnel

----------------------------------------------------------------- barrel tunnel (x 84..92, axis x, centre z 15): flat floor, 5 visible sides
do
	local m = B.model(S, "BarrelTunnel")
	local ap = 6
	local side = 2 * ap * math.tan(math.rad(22.5)) -- 4.97
	local half = side / 2
	local cy = Y0 + half
	local cz = 15
	local cols = { C.Teal:Lerp(C.Ink, 0.2), C.Cream:Lerp(C.Ink, 0.2), C.Red:Lerp(C.Ink, 0.25), C.Mustard:Lerp(C.Ink, 0.3) }
	for r = 0, 3 do
		local x = 84 + r * 2 + 1
		-- sides: angle measured from +y (top) around the x axis; 0 = top, +-45 = upper diagonals, +-90 = verticals
		for k, ang in { -90, -45, 0, 45, 90 } do
			local a = math.rad(ang)
			local n = V(0, math.cos(a), math.sin(a)) -- outward normal (y,z)
			local ctr = V(x, cy, cz) + n * (ap + 0.15)
			local cf = CFrame.fromMatrix(ctr, Vector3.xAxis, n) -- local Y = normal
			B.part(m, "Stave", V(2, 0.3, side + 0.12), cf, cols[(r + k) % #cols + 1], M.WoodPlanks, { solid = true })
		end
	end
	-- mouth fillers (triangles above the diagonals) in the west wall opening
	local leg = ap - half
	for _, sz in { -1, 1 } do
		local zc = cz + sz * (ap - leg / 2)
		local yc = cy + half + leg / 2
		local rot = if sz < 0 then CFrame.Angles(math.pi, 0, 0) else CFrame.Angles(0, 0, math.pi)
		B.part(m, "MouthFiller", V(0.5, leg, leg), CFrame.new(83.75, yc, zc) * rot, inW, M.WoodPlanks, { solid = true, class = "WedgePart" })
	end
	B.loot(U, 2, V(88, Y0, 12))
	B.creak(88, Y0, 15, 0)
	B.node(U, 86, Y0, 17.5)
end

----------------------------------------------------------------- lobby (x 58.5..70.5)
do
	local m = B.model(S, "Lobby")
	B.lamp(m, "hang", CFrame.new(64, 12, 15), U, { range = 22, shade = C.Red:Lerp(C.Ink, 0.2) })
	-- funny mirrors on the west wall either side of the mouth
	for _, z in { 4, 26 } do
		B.box(m, "MirrorFrame", 58.5, 1.5, z - 2.2, 58.8, 9.5, z + 2.2, C.Gold:Lerp(C.Ink, 0.3), M.Wood, SM)
		B.box(m, "WobblyMirror", 58.8, 2, z - 1.8, 58.9, 9, z + 1.8, C.Glass:Lerp(C.Paper, 0.5), M.Glass, { small = true, refl = 0.5 })
	end
	-- popcorn machine
	local pb = CFrame.new(61, Y0, -2.5)
	B.rp(m, "Cart", pb, V(3, 3, 2.4), V(0, 1.5, 0), C.Red:Lerp(C.Ink, 0.2), M.Metal, { solid = true })
	B.rp(m, "Glass", pb, V(2.8, 2.6, 2.2), V(0, 4.3, 0), C.Glass:Lerp(C.Paper, 0.3), M.Glass, { solid = true, tr = 0.4 })
	B.rp(m, "Popcorn", pb, V(2.6, 0.8, 2), V(0, 3.4, 0), C.Mustard:Lerp(C.Paper, 0.5), M.Sand, SM)
	B.rp(m, "Top", pb, V(3.2, 0.4, 2.6), V(0, 5.8, 0), C.Red:Lerp(C.Ink, 0.2), M.Metal, SM)
	-- ticket stand + bench
	B.bench(m, B.cf(60, Y0, 31, "+x"), 5)
	B.loot(U, 2, V(60, 2.0, 31))
	local _, th = B.table(m, B.cf(67.5, Y0, 30.5, "-x"), 2.4, 2.4, 3.2, C.WoodDark, { cloth = C.Red:Lerp(C.Ink, 0.4) })
	B.loot(U, 2, V(67.5, Y0 + th, 30.5))
	B.jarBreak(m, V(66.9, Y0 + th, 31), C.Mustard, 0.8)
	B.creak(61, Y0, 7, 0)
	B.rug(m, 64, Y0, 15, 5, 8, C.Red:Lerp(C.Ink, 0.3))
	B.clownFace(m, CFrame.lookAt(V(70.5, 9.8, 15), V(60, 9.8, 15)), 0.55, { eyeGlow = Color3.fromRGB(255, 90, 90) })
end

----------------------------------------------------------------- tilted room (x 71..83.5): hump floor, everything leans
do
	local m = B.model(S, "TiltedRoom")
	local tile = C.Paper:Lerp(C.Ink, 0.25)
	B.box(m, "FlatFloor", 71, Y0, 4, 75.6, Y0 + 0.01, 26, C.Ink:Lerp(C.Paper, 0.2), M.Slate, { solid = true, shadow = false })
	B.ramp(m, "TiltUp", "x", 75.6, 79.5, 15, 22, Y0, Y0 + 0.8, tile, M.Slate)
	B.ramp(m, "TiltDown", "x", 83.5, 79.5, 15, 22, Y0, Y0 + 0.8, C.Ink:Lerp(C.Paper, 0.2), M.Slate)
	B.lamp(m, "bare", CFrame.new(78, 12, 15), U, { drop = 3, range = 20, bright = 0.9 })
	-- leaning props (rotated about z to follow the hump)
	local tilt = math.atan(0.8 / 3.9)
	local tb = CFrame.new(77.6, Y0 + 0.4, 8) * CFrame.Angles(0, 0, tilt)
	local _, th = B.table(m, tb, 3, 2.2, 3, C.Rose:Lerp(C.Ink, 0.3))
	B.loot(U, 2, (tb * CFrame.new(0, th, 0)).Position)
	local ch = CFrame.new(81.5, Y0 + 0.4, 22) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(0, 0, tilt)
	B.chair(m, ch, C.Teal:Lerp(C.Ink, 0.3))
	-- crooked picture frames
	for i, z in { 6, 24 } do
		B.part(m, "CrookedFrame", V(0.15, 2.2, 1.8), CFrame.new(83.425, 7, z) * CFrame.Angles(math.rad(if i == 1 then 14 else -11), 0, 0), C.Gold:Lerp(C.Ink, 0.3), M.Wood, SM)
	end
	for i, x in { 73, 78.5 } do
		B.part(m, "CrookedFrame", V(1.8, 2.2, 0.15), CFrame.new(x, 7, 4.075) * CFrame.Angles(0, 0, math.rad(if i == 1 then -13 else 9)), C.Gold:Lerp(C.Ink, 0.3), M.Wood, SM)
	end
	B.dresser(m, B.cf(73.6, Y0, 24.9, "-z"), 3.4, 1.4, 3, C.Bruise:Lerp(C.Ink, 0.3), 3, U, 2)
	B.loot(U, 2, V(73.6, Y0 + 3.2, 24.9))
	B.node(U, 73.5, Y0, 15)
	B.creak(73, Y0 + 0.02, 16, 0)
end

----------------------------------------------------------------- workshop (x 92.5..99.5, z 4..26): clown cabinet (HidingSpot)
do
	local m = B.model(S, "Workshop")
	B.box(m, "Bench", 97.8, Y0, 6, 99.5, 3.2, 13, C.WoodRaw, M.Wood, { solid = true })
	B.loot(U, 2, V(98.6, 3.2, 8))
	B.loot(U, 2, V(98.6, 3.2, 11.5))
	sdoor(m, "BenchDrawer", V(97.74, 2.55, 9.5), V(-1, 0, 0), 2, 0.7, C.WoodDark, "Drawer")
	for i = 0, 3 do
		B.cyl(m, "PaintCan", CFrame.new(98.4, 3.2, 6.8 + i * 0.8), 0.6, 0.7, V(0, 0.35, 0), ({ C.Red, C.Mustard, C.Teal, C.Rose })[i + 1], M.Metal, SM, true)
	end
	B.wardrobe(m, B.cf(98, Y0, 19.5, "-x"), C.Plum:Lerp(C.Ink, 0.3), U, "Cabinet", { name = "ClownCabinet", w = 4.6, d = 3, h = 8.6, doorColor = C.Cream:Lerp(C.Ink, 0.2) })
	B.clownFace(m, CFrame.lookAt(V(96.5, 6.3, 19.5), V(90, 6.3, 19.5)), 0.5)
	B.box(m, "ToolCabinet", 98.2, Y0, 23.2, 99.5, 6, 25.8, C.Teal:Lerp(C.Ink, 0.4), M.Metal, { solid = true })
	sdoor(m, "ToolCabinetDoor", V(98.14, 3, 24.5), V(-1, 0, 0), 2.4, 5.6, C.Teal:Lerp(C.Ink, 0.25), "Cabinet")
	B.lamp(m, "hang", CFrame.new(95.5, 12, 11), U, { range = 18, shade = C.Mint:Lerp(C.Ink, 0.3) })
	-- spare clown heads and a unicycle
	B.ball(m, "ClownHead", CFrame.new(94, Y0, 5.2), 2, V(0, 1, 0), C.Paper:Lerp(C.Sheet, 0.3), M.SmoothPlastic, SM)
	B.ball(m, "ClownNose", CFrame.new(94, Y0, 5.2), 0.6, V(0, 1.1, 1), C.Blood, M.SmoothPlastic, SM)
	B.cyl(m, "Unicycle", CFrame.new(94.2, Y0 + 1.2, 25.4) * CFrame.Angles(0, math.rad(90), 0), 2.4, 0.2, V(0, 0, 0), C.Ink, M.Rubber, SM, false)
	B.node(U, 95, Y0, 15)
end

----------------------------------------------------------------- upper floor: costume loft (x 58.5..80) and clown gallery (x 80.5..99.5)
local UP = B.model(S, "UpperFloor")
B.wall(UP, "LoftWall", "z", 80.25, 3.5, 26.5, Y1, YT, 0.5, C.Plum:Lerp(C.Ink, 0.3), M.WoodPlanks, { B.DG(9), B.DG(21) })
B.doorway(UP, "z", 80.25, 9, Y1, 0.5, C.WoodDark)
B.doorway(UP, "z", 80.25, 21, Y1, 0.5, C.WoodDark)
B.door(UP, "LoftDoor", "z", 80.25, 9, Y1, U, true, false, C.Plum:Lerp(C.Paper, 0.3), 1)
do -- costume loft
	local m = B.model(S, "CostumeLoft")
	B.lamp(m, "hang", CFrame.new(66, YT, 15), U, { range = 22, shade = C.Rose:Lerp(C.Ink, 0.3) })
	-- costume rack (HidingSpot Closet) against the west wall
	local rk = B.model(m, "CostumeRack")
	for _, z in { 19.5, 28.5 } do
		B.box(rk, "RackPost", 60.1, Y1, z - 0.15, 60.4, Y1 + 7.4, z + 0.15, C.Metal, M.Metal, SM)
	end
	B.box(rk, "RackRail", 60.1, Y1 + 7.4, 19.35, 60.4, Y1 + 7.7, 28.65, C.Metal, M.Metal, SM)
	local cc = { C.Red, C.Teal, C.Mustard, C.Bruise, C.Rose, C.Mint }
	for i = 0, 5 do
		local z = 20.2 + i * 1.35
		B.box(rk, "Costume", 60.45, Y1 + 0.4, z - 0.62, 60.75, Y1 + 7.4, z + 0.62, cc[i + 1]:Lerp(C.Ink, 0.3), M.Fabric, { solid = true })
		B.box(rk, "Ruff", 60.4, Y1 + 6.6, z - 0.64, 60.8, Y1 + 7.0, z + 0.64, C.Paper:Lerp(C.Ink, 0.1), M.Fabric, SM)
	end
	local ins = V(59.5, Y1 + 3, 24)
	B.hideParts(rk, "Closet", U, CFrame.lookAt(ins, ins + V(1, 0, 0)), V(63.2, Y1, 24), V(63.4, Y1, 25.8))
	-- costume trunks, vanity, mannequins
	B.trunk(m, B.cf(61, Y1, 8, "+x"), C.Red:Lerp(C.Ink, 0.35), U, 2, { name = "CostumeTrunk" })
	B.trunk(m, B.cf(61, Y1, 13, "+x"), C.Teal:Lerp(C.Ink, 0.35), U, 2, { name = "CostumeTrunk" })
	B.dresser(m, B.cf(64.5, Y1, 33.65, "-z"), 4, 1.6, 3, C.Cream:Lerp(C.Ink, 0.35), 2, U, 2, { search = { 1 }, kind = "Vanity", name = "MakeupVanity" })
	B.box(m, "VanityMirror", 62.9, Y1 + 3.2, 34.1, 66.1, Y1 + 7, 34.5, C.Gold:Lerp(C.Ink, 0.3), M.Wood, SM)
	B.box(m, "MirrorGlass", 63.2, Y1 + 3.5, 34.05, 65.8, Y1 + 6.7, 34.1, C.Glass:Lerp(C.Paper, 0.4), M.Glass, { small = true, refl = 0.4 })
	for i = 0, 4 do
		B.ball(m, "VanityBulb", CFrame.new(63.1 + i * 0.75, Y1 + 7.15, 33.95), 0.3, V(0, 0, 0), Color3.fromRGB(90, 86, 80), M.Glass, SM)
	end
	B.loot(U, 2, V(65.5, Y1 + 3.2, 33.4))
	for i, p in { V(67.5, Y1, 4.5), V(76, Y1, 23.5) } do
		local mb = CFrame.new(p) * CFrame.Angles(0, math.rad(i * 60), 0)
		local mm = B.model(m, "Mannequin")
		B.rp(mm, "Stand", mb, V(1.2, 0.2, 1.2), V(0, 0.1, 0), C.Ink, M.Metal, SM)
		B.rp(mm, "Pole", mb, V(0.2, 3, 0.2), V(0, 1.7, 0), C.Ink, M.Metal, SM)
		B.rp(mm, "Torso", mb, V(1.8, 2.4, 1.1), V(0, 4.3, 0), cc[i * 2]:Lerp(C.Ink, 0.25), M.Fabric, { solid = true })
		B.ball(mm, "Mask", mb, 1.3, V(0, 6.2, 0), C.Paper, M.SmoothPlastic, SM)
		B.rp(mm, "Smile", mb, V(0.8, 0.15, 0.1), V(0, 6.0, -0.64), C.Blood, M.SmoothPlastic, SM)
	end
	local _, th = B.table(m, B.cf(73.5, Y1, 9, "+z"), 4, 2.4, 3, C.WoodDark, { cloth = C.Bruise:Lerp(C.Ink, 0.4) })
	B.loot(U, 2, V(72.7, Y1 + th, 9))
	B.jarBreak(m, V(74.5, Y1 + th, 9.3), C.Rose, 0.8)
	B.loot(U, 2, V(61, Y1 + 2.15, 8))
	B.creak(66, Y1, 20, 0)
	B.creak(76, Y1, 15, 0)
	B.node(U, 64, Y1, 26)
	B.node(U, 75, Y1, 17)
end
do -- clown gallery
	local m = B.model(S, "ClownGallery")
	B.lamp(m, "hang", CFrame.new(89, YT, 15), U, { range = 22, shade = C.Teal:Lerp(C.Ink, 0.3) })
	-- big clown faces on the east wall
	for i, z in { 6, 15, 24 } do
		B.clownFace(m, CFrame.lookAt(V(99.5, 19, z), V(90, 19, z)), 1.1, { hair = ({ C.Rose, C.Mint, C.Mustard })[i], eyeGlow = if i == 2 then Color3.fromRGB(255, 80, 80) else nil })
	end
	-- prize pedestal (PrizeSpawn) + prize box (ToyChest)
	B.box(m, "Pedestal", 86.5, Y1, 13.5, 89.5, Y1 + 3.4, 16.5, C.Red:Lerp(C.Ink, 0.3), M.Wood, { solid = true })
	B.box(m, "PedestalTop", 86.3, Y1 + 3.4, 13.3, 89.7, Y1 + 3.6, 16.7, C.Gold:Lerp(C.Ink, 0.3), M.Wood, SM)
	B.prize(U, V(88, Y1 + 3.6, 15))
	B.trunk(m, B.cf(96.5, Y1, 31.5, "-x"), C.Mustard:Lerp(C.Ink, 0.35), U, 2, { kind = "ToyChest", name = "PrizeBox" })
	B.trunk(m, B.cf(96.5, Y1, -1.5, "-x"), C.Teal:Lerp(C.Ink, 0.35), U, 2, { kind = "ToyChest", name = "PrizeBox" })
	-- distorting mirrors along the partition (gallery side)
	for _, z in { 14.5, 17.2 } do
		B.box(m, "MirrorFrame", 80.5, Y1 + 1.5, z - 1, 80.8, Y1 + 9.5, z + 1, C.Gold:Lerp(C.Ink, 0.3), M.Wood, SM)
		B.box(m, "WobblyMirror", 80.8, Y1 + 2, z - 0.8, 80.9, Y1 + 9, z + 0.8, C.Glass:Lerp(C.Paper, 0.5), M.Glass, { small = true, refl = 0.5 })
	end
	B.loot(U, 2, V(97.5, Y1 + 2.15, 31.5))
	B.bench(m, B.cf(90, Y1, 25.2, "-z"), 5, C.Red:Lerp(C.Ink, 0.4))
	B.loot(U, 3, V(90, Y1 + 2.0, 25.2))
	B.creak(95, Y1, 8, 0)
	B.node(U, 84, Y1, 9)
	B.node(U, 96, Y1, 15)
end
-- lobby + ramp nodes
B.node(U, 64, Y0, 24)
B.node(U, 81.5, Y0 + 11 / 22 * (Y1 - Y0), -0.5)
B.node(U, 81.5, Y0 + 11 / 22 * (Y1 - Y0), 30.5)

----------------------------------------------------------------- facade: clown face over the mouth + sign
do
	local m = B.model(S, "Facade")
	B.clownFace(m, CFrame.lookAt(V(58, 15.8, 15), V(40, 15.8, 15)), 2.2, { hair = C.Rose:Lerp(C.Ink, 0.1), eyeGlow = Color3.fromRGB(255, 120, 90) })
	-- red lips round the mouth opening (outside face)
	B.box(m, "LipTop", 57.8, 9.08, 10.4, 58, 10.1, 19.6, C.Blood:Lerp(C.Ink, 0.15), M.SmoothPlastic, SM)
	B.box(m, "LipSide", 57.8, Y0, 10.4, 58, 9.08, 11, C.Blood:Lerp(C.Ink, 0.15), M.SmoothPlastic, SM)
	B.box(m, "LipSide", 57.8, Y0, 19, 58, 9.08, 19.6, C.Blood:Lerp(C.Ink, 0.15), M.SmoothPlastic, SM)
	for i = 0, 3 do
		B.part(m, "Tooth", V(0.2, 0.9, 1.6), CFrame.new(57.9, 8.6, 11.8 + i * 2.1), C.Paper, M.SmoothPlastic, SM)
	end
	local sg = B.box(m, "Sign", 57.6, 21, 7, 58, 23.6, 23, C.Night, M.Wood, SM)
	B.text(sg, "FUNHOUSE", { face = Enum.NormalId.Left, color = C.Mustard, pps = 20 })
	B.festoon(m, V(57.6, 23.8, 7), V(57.6, 23.8, 23), 1.2, 10, nil, { seed = 4 })
end

----------------------------------------------------------------- barrier: chained turnstiles + CLOSED in the mouth
do
	local m = B.barrier("Barrier_Upstairs", U)
	for i, z in { 12.2, 15, 17.8 } do
		local b = B.cf(57, 0.05, z, "-x")
		B.rp(m, "Turnstile", b, V(1, 3.2, 1), V(0, 1.6, 0), C.Metal:Lerp(C.Ink, 0.3), M.Metal, { collide = false })
		for k = 0, 2 do
			B.rp(m, "Arm", b, V(0.15, 0.15, 1.8), V(0, 3, -0.9), C.Metal, M.Metal, SM, CFrame.Angles(0, math.rad(k * 120), 0))
		end
	end
	for _, y in { 2.5, 3.3 } do
		B.part(m, "Chain", V(0.15, 0.15, 7.6), CFrame.new(57.4, y, 15) * CFrame.Angles(math.rad(y * 3), 0, 0), C.Metal, M.Metal, { small = true })
	end
	B.part(m, "Padlock", V(0.3, 0.7, 0.6), CFrame.new(57.3, 2.8, 15.6), C.Brass, M.Metal, { small = true })
	local sg = B.part(m, "ClosedSign", V(0.12, 1.8, 4.2), CFrame.new(57.3, 2.9, 15) * CFrame.Angles(math.rad(-6), 0, 0), C.Paper, M.Wood, { small = true })
	B.text(sg, "CLOSED", { face = Enum.NormalId.Left, color = C.Blood, stroke = C.Ink })
	B.box(m, "Collider", 57, 0, 11, 58.25, 12, 19, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
end

----------------------------------------------------------------- rooms
B.room("Funhouse Lobby", U, 2, 58.5, -0.5, -4.5, 70.5, 12, 34.5)
B.room("Tilted Room", U, 2, 71, -0.5, 4, 83.5, 12, 26)
B.room("Barrel Tunnel", U, 2, 84, -0.5, 9, 92, 12, 21)
B.room("Workshop", U, 2, 92.5, -0.5, 4, 99.5, 12, 26)
B.room("South Ramp", U, 2, 70.5, -0.5, -4.5, 92.5, 24.5, 3.5)
B.room("North Ramp", U, 2, 70.5, -0.5, 26.5, 92.5, 24.5, 34.5)
B.room("Costume Loft", U, 2, 58.5, 12, -4.5, 70.5, 24.5, 34.5)
B.room("Loft Walkway", U, 2, 70.5, 12, 3.5, 80, 24.5, 26.5)
B.room("Clown Gallery", U, 3, 80.5, 12, 3.5, 92.5, 24.5, 26.5)
B.room("Gallery Landing", U, 2, 92.5, 12, -4.5, 99.5, 24.5, 34.5)
return "funhouse ok, parts=" .. B.count(root)
