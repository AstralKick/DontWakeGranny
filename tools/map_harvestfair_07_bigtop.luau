-- HarvestFair "Attic" zone = THE BIG TOP (night 4): circus tent x -40..40, z 60..105 (ring, bleachers with an
-- under-bleacher hiding spot, trapeze rigging decor), roped-off front flap with a padlocked gate (Barrier),
-- back flap to the backstage lot with three caravans (ringmaster's caravan holds a Prize + wardrobe hide).
-- Section "bigtop" (idempotent).
local B = _G.HF
local C, M = B.C, B.M
local V = Vector3.new
local root = B.root()
local S = B.begin("bigtop")
local SM = { small = true }
local A = "Attic"
local function sdoor(par, name, center, dir, w, h, col, kind, danger)
	local p = B.part(par, name, V(w, h, 0.12), CFrame.lookAt(center, center + dir), col, M.Wood, { collide = false, shadow = false })
	return B.searchable(p, kind, A, danger or 3)
end
local Y0, H = 0.08, 20
local c1, c2 = C.Red:Lerp(C.Ink, 0.25), C.Cream:Lerp(C.Ink, 0.25)

----------------------------------------------------------------- tent shell
local T = B.model(S, "BigTop")
B.box(T, "Sawdust", -40, -0.3, 60, 40, Y0, 105, C.Hay:Lerp(C.WoodMid, 0.45), M.Sand, { solid = true })
B.stripes(T, "Canvas", "x", 60.25, -40, 40, Y0, H, 0.5, c1, c2, 4, { { c = 0, w = 10, h = 12 } })
B.stripes(T, "Canvas", "x", 104.75, -40, 40, Y0, H, 0.5, c1, c2, 4, { { c = 0, w = 8, h = 9 } })
B.stripes(T, "Canvas", "z", -39.75, 60.5, 104.5, Y0, H, 0.5, c1, c2, 4)
B.stripes(T, "Canvas", "z", 39.75, 60.5, 104.5, Y0, H, 0.5, c1, c2, 4)
B.pyramid(T, 0, 82.5, 40.5, 23, H, 16, c1, c2)
for _, z in { 69.5, 95.5 } do
	B.cyl(T, "KingPole", CFrame.new(0, Y0, z), 1.4, 40, V(0, 20, 0), C.WoodDark, M.Wood, { solid = true }, true)
	B.box(T, "PoleFlag", 0.7, 38, z - 0.05, 3.2, 39.4, z + 0.05, C.Mustard, M.Fabric, SM)
end
-- valance round the entrance + back flap trims
for _, sx in { -1, 1 } do
	B.box(T, "Flap", sx * 6.2 - 0.6, Y0, 59.6, sx * 6.2 + 0.6, 12, 60, C.Blood:Lerp(C.Ink, 0.2), M.Fabric, SM)
	B.box(T, "BackFlap", sx * 4 - 0.6, Y0, 105, sx * 4 + 0.6, 9, 105.4, C.Blood:Lerp(C.Ink, 0.2), M.Fabric, SM)
end
local sg = B.box(T, "Sign", -9, 13.2, 59.6, 9, 17.6, 60, C.Night, M.Wood, SM)
B.text(sg, "THE BIG TOP", { face = Enum.NormalId.Front, color = C.Mustard, pps = 16 })
B.festoon(T, V(-12, 18.5, 59.5), V(12, 18.5, 59.5), 1.6, 12, nil, { seed = 5 })

----------------------------------------------------------------- the ring (centre 0, 82.5): curb with east/west gaps
do
	local m = B.model(S, "Ring")
	local c = V(0, Y0, 82.5)
	B.cyl(m, "RingFloor", CFrame.new(c), 21.4, 0.04, V(0, 0.02, 0), C.Blood:Lerp(C.Ink, 0.35), M.Fabric, { small = true, collide = false }, true)
	for i = 0, 15 do
		local a = (i + 0.5) / 16 * math.pi * 2
		local skip = (i == 0 or i == 15 or i == 7 or i == 8) -- gaps at +x and -x
		if not skip then
			local dir = V(math.cos(a), 0, math.sin(a))
			local p = c + dir * 11 + V(0, 0.6, 0)
			B.part(m, "Curb", V(4.5, 1.2, 0.8), CFrame.lookAt(p, p + dir), if i % 2 == 0 then C.Red:Lerp(C.Ink, 0.2) else C.Cream:Lerp(C.Ink, 0.2), M.Wood, { solid = true })
		end
	end
	-- circus drums / pedestals
	for i, p in { V(-5, 0, 78), V(5, 0, 78), V(0, 0, 88.5) } do
		local b = CFrame.new(c.X + p.X, Y0, p.Z)
		B.cyl(m, "Drum", b, 3.2, 2.4 + i * 0.4, V(0, (2.4 + i * 0.4) / 2, 0), if i == 2 then C.Teal:Lerp(C.Ink, 0.2) else C.Red:Lerp(C.Ink, 0.2), M.Wood, { solid = true }, true)
		B.cyl(m, "DrumBand", b, 3.3, 0.35, V(0, (2.4 + i * 0.4) - 0.3, 0), C.Gold:Lerp(C.Ink, 0.3), M.Metal, SM, true)
		B.loot(A, 3, V(b.X, Y0 + 2.4 + i * 0.4, b.Z))
	end
	-- ringmaster's podium with his hat (PrizeSpawn)
	B.box(m, "Podium", -1.2, Y0, 81, 1.2, 3.6, 83.4, C.Plum:Lerp(C.Ink, 0.3), M.Wood, { solid = true })
	B.box(m, "PodiumTop", -1.5, 3.6, 80.7, 1.5, 3.8, 83.7, C.Gold:Lerp(C.Ink, 0.3), M.Wood, SM)
	B.prize(A, V(0, 3.8, 82.2))
	B.cyl(m, "TopHat", CFrame.new(0.7, 3.8, 83.1), 0.9, 1, V(0, 0.5, 0), C.Ink, M.Fabric, SM, true)
	B.cyl(m, "HatBrim", CFrame.new(0.7, 3.8, 83.1), 1.4, 0.08, V(0, 0.04, 0), C.Ink, M.Fabric, SM, true)
	-- hoop stand
	B.box(m, "HoopPost", 6.8, Y0, 85.9, 7.1, 5, 86.2, C.Metal, M.Metal, SM)
	local hp = CFrame.new(6.95, 5.9, 86.05) * CFrame.Angles(0, math.rad(90), 0)
	B.set(B.cyl(m, "Hoop", hp, 3, 0.2, V(0, 0, 0), C.Mustard, M.Metal, SM, false), hp)
	-- decor cannon (pointing up at the trapeze)
	local cb = CFrame.new(-7, Y0, 86.5)
	B.rp(m, "CannonCart", cb, V(2.4, 1.2, 3.4), V(0, 0.9, 0), C.Red:Lerp(C.Ink, 0.3), M.Wood, { solid = true })
	B.set(B.cyl(m, "Barrel", cb, 1.6, 4.4, V(0, 0, 0), C.Metal:Lerp(C.Ink, 0.2), M.Metal, { solid = true }, false), cb * CFrame.new(0, 2.6, 0.3) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, math.rad(55)))
	for _, sx in { -1, 1 } do
		local wb = cb * CFrame.new(sx * 1.35, 0.95, 0)
		B.set(B.cyl(m, "Wheel", wb, 1.8, 0.3, V(0, 0, 0), C.WoodDark, M.Wood, SM, false), wb)
	end
	B.node(A, 0, Y0, 76)
end

----------------------------------------------------------------- trapeze rigging (decor, high up) between the king poles
do
	local m = B.model(S, "Rigging")
	for _, z in { 69.5, 95.5 } do
		local dz = if z < 82.5 then 1 else -1
		B.box(m, "Platform", -1.6, 15.8, z + dz * 0.7 - 1.6, 1.6, 16.1, z + dz * 0.7 + 1.6, C.WoodMid, M.WoodPlanks, SM)
		B.box(m, "PlatformRail", -1.6, 16.1, z + dz * 2.3 - 0.05, 1.6, 17.4, z + dz * 2.3 + 0.05, C.Gold:Lerp(C.Ink, 0.3), M.Metal, SM)
		for k = 0, 5 do
			B.box(m, "LadderRung", -0.6, 1 + k * 2.6, z - dz * 0.75 - 0.05, 0.6, 1.1 + k * 2.6, z - dz * 0.75 + 0.05, C.WoodLight, M.Wood, SM)
		end
	end
	B.box(m, "Wire", -0.05, 19.2, 70.2, 0.05, 19.3, 94.8, C.Ink, M.Metal, SM)
	for _, x in { -1.2, 1.2 } do
		B.box(m, "TrapezeRope", x - 0.04, 13.3, 82.46, x + 0.04, 19.2, 82.54, C.Paper:Lerp(C.Ink, 0.3), M.Fabric, SM)
	end
	B.box(m, "TrapezeBar", -1.3, 13.2, 82.43, 1.3, 13.35, 82.57, C.Gold, M.Metal, SM)
	B.box(m, "SafetyNet", -8, 7.5, 76, 8, 7.55, 89, C.Paper:Lerp(C.Ink, 0.4), M.Fabric, { small = true, tr = 0.55 })
	for _, cx in { -7.9, 7.9 } do
		for _, cz in { 76.1, 88.9 } do
			B.box(m, "NetRope", cx - 0.04, 7.55, cz - 0.04, cx + 0.04, H, cz + 0.04, C.Paper:Lerp(C.Ink, 0.4), M.Fabric, SM)
		end
	end
	-- follow-spots on the king poles aimed at the ring (Lamps)
	B.lamp(m, "flood", CFrame.lookAt(V(1.4, 17, 69.5), V(0, 0, 82.5)), A, { spot = true, face = Enum.NormalId.Front, angle = 45, range = 34, bright = 1.4, color = Color3.fromRGB(255, 226, 180) })
	B.lamp(m, "flood", CFrame.lookAt(V(-1.4, 17, 95.5), V(0, 0, 82.5)), A, { spot = true, face = Enum.NormalId.Front, angle = 45, range = 34, bright = 1.2, color = Color3.fromRGB(255, 190, 200) })
end

----------------------------------------------------------------- bleachers (east & west), west one hides a crawl space
local function bleacher(side)
	local m = B.model(S, "Bleachers")
	local sx = side
	local seat = { C.Red:Lerp(C.Ink, 0.4), C.Cream:Lerp(C.Ink, 0.4), C.Teal:Lerp(C.Ink, 0.4), C.Mustard:Lerp(C.Ink, 0.4) }
	for k = 1, 4 do
		local xa, xb = sx * (29.5 + 2.5 * (k - 1)), sx * (29.5 + 2.5 * k)
		if side < 0 and k >= 3 then
			-- hollow crawl space under tiers 3-4 between z 79.5 and 86.5
			B.box(m, "Tier", xa, Y0, 66, xb, 1.2 * k, 79.5, seat[k], M.WoodPlanks, { solid = true })
			B.box(m, "Tier", xa, Y0, 86.5, xb, 1.2 * k, 99, seat[k], M.WoodPlanks, { solid = true })
			B.box(m, "Tier", xa, 2.4, 79.5, xb, 1.2 * k, 86.5, seat[k], M.WoodPlanks, { solid = true })
		else
			B.box(m, "Tier", xa, Y0, 66, xb, 1.2 * k, 99, seat[k], M.WoodPlanks, { solid = true })
		end
		B.box(m, "SeatEdge", xa, 1.2 * k, 66, xa + sx * 0.3, 1.2 * k + 0.12, 99, C.Gold:Lerp(C.Ink, 0.4), M.Wood, SM)
	end
	-- bunting skirt along the front
	for i = 0, 7 do
		local z = 66 + i * 4.125 + 2.06
		B.part(m, "Bunting", V(0.08, 0.8, 4), CFrame.new(sx * 29.46, 0.9, z), if i % 2 == 0 then C.Mustard:Lerp(C.Ink, 0.2) else C.Teal:Lerp(C.Ink, 0.2), M.Fabric, SM)
	end
	return m
end
do
	local w = bleacher(-1)
	local e = bleacher(1)
	-- crawl space hide (Bed kind: lie prone under the seats, head toward the ring)
	local hm = B.model(w, "UnderBleachers")
	local pos = V(-37, Y0 + 1.1, 83)
	local inside = CFrame.fromMatrix(pos, Vector3.zAxis, Vector3.xAxis)
	B.hideParts(hm, "Bed", A, inside, V(-27.5, Y0, 83), V(-27.3, Y0, 84.8))
	-- loot on the seats
	B.loot(A, 3, V(-33.5, 2.4, 70))
	B.loot(A, 3, V(35.5, 3.6, 92))
	B.jarBreak(e, V(33.2, 2.4, 88), C.Rose, 0.7) -- abandoned popcorn jar
	B.node(A, 24, Y0, 82.5)
end

----------------------------------------------------------------- big top props: prop trunks, clown box, popcorn stand, lantern
do
	local m = B.model(S, "TentProps")
	B.trunk(m, B.cf(-20, Y0, 101.6, "-z"), C.Red:Lerp(C.Ink, 0.4), A, 3, { name = "PropTrunk" })
	B.trunk(m, B.cf(20, Y0, 101.6, "-z"), C.Teal:Lerp(C.Ink, 0.4), A, 3, { kind = "ToyChest", name = "ClownBox" })
	B.bench(m, B.cf(-14, Y0, 63.6, "+z"), 6, C.Red:Lerp(C.Ink, 0.4))
	B.loot(A, 3, V(-14, 2.05, 63.6))
	B.lamp(m, "lantern", CFrame.new(0, 12, 64), A, { range = 20, bright = 0.9 })
	B.box(m, "LanternWire", -0.05, 12, 63.95, 0.05, H, 64.05, C.Ink, M.Metal, SM)
	-- stacked clown pedestals by the back flap
	for i, p in { V(-9, 0, 99), V(-11.5, 0, 101), V(10, 0, 100) } do
		B.cyl(m, "Stool", CFrame.new(p.X, Y0, p.Z), 2.2, 2, V(0, 1, 0), if i == 2 then C.Mustard:Lerp(C.Ink, 0.3) else C.Plum:Lerp(C.Ink, 0.2), M.Wood, { solid = true }, true)
	end
	B.loot(A, 3, V(10, Y0 + 2, 100))
	B.creak(0, Y0, 101.5, 0)
	B.creak(-8, Y0, 66, 0)
	B.node(A, 0, Y0, 100)
end

----------------------------------------------------------------- barrier: roped-off front flap with a padlocked gate
do
	local m = B.barrier("Barrier_Attic", A)
	for _, x in { -4.6, 4.6 } do
		B.box(m, "GatePost", x - 0.4, 0.05, 59.2, x + 0.4, 9, 60, C.Gold:Lerp(C.Ink, 0.4), M.Metal, { collide = false })
		B.part(m, "PostKnob", V(1, 1, 1), CFrame.new(x, 9.4, 59.6), C.Gold, M.Metal, { small = true, shape = Enum.PartType.Ball })
	end
	for _, sx in { -1, 1 } do
		local x0 = sx * 0.1
		local x1 = sx * 4.2
		for k = 0, 4 do
			local x = x0 + (x1 - x0) * (k + 0.5) / 5
			B.box(m, "GateBar", x - 0.08, 0.4, 59.5, x + 0.08, 6.4, 59.7, C.Ink, M.Metal, { collide = false })
		end
		B.box(m, "GateRail", math.min(x0, x1), 0.9, 59.45, math.max(x0, x1), 1.1, 59.75, C.Ink, M.Metal, { collide = false })
		B.box(m, "GateRail", math.min(x0, x1), 5.9, 59.45, math.max(x0, x1), 6.1, 59.75, C.Ink, M.Metal, { collide = false })
	end
	B.part(m, "Chain", V(1.6, 0.15, 0.15), CFrame.new(0, 2.6, 59.35) * CFrame.Angles(0, 0, math.rad(20)), C.Metal, M.Metal, { small = true })
	B.part(m, "Padlock", V(0.6, 0.7, 0.3), CFrame.new(0, 2.3, 59.25), C.Brass, M.Metal, { small = true })
	for _, y in { 7.4, 8.6 } do
		B.part(m, "Rope", V(9.2, 0.18, 0.18), CFrame.new(0, y, 59.4) * CFrame.Angles(0, 0, math.rad(y == 7.4 and 2 or -2)), C.Blood:Lerp(C.Ink, 0.2), M.Fabric, { small = true })
	end
	local s = B.part(m, "Sign", V(3.4, 1.4, 0.1), CFrame.new(0, 4.6, 59.45), C.Paper, M.Wood, { small = true })
	B.text(s, "SHOW CANCELLED", { face = Enum.NormalId.Front, color = C.Blood })
	B.box(m, "Collider", -5, 0, 59.2, 5, 12.1, 60.1, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
end

----------------------------------------------------------------- backstage lot: three caravans (doors face south), lion-cage wagon
local function caravan(name, x0, x1, z0, z1, col, doorX, o)
	o = o or {}
	local m = B.model(S, name)
	local fy = 2.08 -- floor top
	local top = 11.2
	local trim = C.Gold:Lerp(C.Ink, 0.3)
	B.box(m, "Chassis", x0 + 1, 0.6, z0 + 0.6, x1 - 1, fy - 0.2, z1 - 0.6, C.Ink, M.Metal, { solid = true })
	B.box(m, "Floor", x0, fy - 0.2, z0, x1, fy, z1, C.WoodMid:Lerp(C.Ink, 0.2), M.WoodPlanks, { solid = true })
	B.wall(m, "Wall", "x", z0 + 0.15, x0, x1, fy, top, 0.3, col, M.WoodPlanks, { B.DG(doorX) })
	B.wall(m, "Wall", "x", z1 - 0.15, x0, x1, fy, top, 0.3, col, M.WoodPlanks)
	B.box(m, "Wall", x0, fy, z0 + 0.3, x0 + 0.3, top, z1 - 0.3, col, M.WoodPlanks, { solid = true })
	B.box(m, "Wall", x1 - 0.3, fy, z0 + 0.3, x1, top, z1 - 0.3, col, M.WoodPlanks, { solid = true })
	B.box(m, "Roof", x0 - 0.4, top, z0 - 0.4, x1 + 0.4, top + 0.4, z1 + 0.4, C.Ink:Lerp(col, 0.3), M.WoodPlanks, { solid = true })
	B.box(m, "RoofLantern", (x0 + x1) / 2 - 3, top + 0.4, z0 + 2, (x0 + x1) / 2 + 3, top + 1.4, z1 - 2, col:Lerp(C.Paper, 0.2), M.WoodPlanks, SM)
	B.box(m, "TrimBand", x0, fy + 7.4 + 1.2, z0 - 0.05, x1, fy + 7.8 + 1.2, z0, trim, M.Wood, SM)
	B.doorway(m, "x", z0 + 0.15, doorX, fy, 0.3, trim)
	B.door(m, "Door", "x", z0 + 0.15, doorX, fy, A, true, true, col:Lerp(C.Paper, 0.25), 1)
	-- big spoked wheels
	for _, xx in { x0 + 3, x1 - 3 } do
		for _, zz in { z0 - 0.25, z1 + 0.25 } do
			local wb = CFrame.new(xx, 1.7, zz) * CFrame.Angles(0, math.rad(90), 0)
			B.set(B.cyl(m, "Wheel", wb, 3.4, 0.4, V(0, 0, 0), C.WoodDark, M.Wood, { solid = true }, false), wb)
		end
	end
	-- access ramp to the door (2 up over 4.5, 24 deg) + side steps look
	B.ramp(m, "DoorRamp", "z", z0 - 4.5, z0, doorX, 5.4, 0.05, fy, C.WoodMid, M.WoodPlanks)
	-- name board
	local nb = B.box(m, "NameBoard", doorX + 3, fy + 5, z0 - 0.08, doorX + 7.4, fy + 7, z0, C.Night, M.Wood, SM)
	B.text(nb, o.title or name, { face = Enum.NormalId.Front, color = C.Mustard, pps = 30 })
	B.room(o.room or name, A, 3, x0 + 0.3, fy - 0.3, z0 + 0.3, x1 - 0.3, top, z1 - 0.3)
	return m, fy
end
do -- ringmaster's caravan (centre)
	local m, fy = caravan("RingmasterCaravan", -8, 8, 124, 132, C.Plum:Lerp(C.Ink, 0.3), 0, { title = "RINGMASTER", room = "Ringmaster's Caravan" })
	B.wardrobe(m, B.cf(6.2, fy, 128, "-x"), C.WoodDark:Lerp(C.Plum, 0.3), A, "Wardrobe", { name = "CaravanWardrobe", w = 5, d = 3, h = 8.6 })
	B.fridge(m, B.cf(-6.2, fy, 130.1, "+x"), A, 3, C.Cream:Lerp(C.Ink, 0.2))
	local _, th = B.table(m, B.cf(-2.5, fy, 130, "-z"), 3.6, 2.4, 3, C.WoodDark, { cloth = C.Blood:Lerp(C.Ink, 0.3) })
	B.prize(A, V(-2.5, fy + th, 130))
	B.dresser(m, B.cf(2.4, fy, 130.95, "-z"), 3, 1.4, 3, C.WoodMid, 3, A, 3, { search = { 1 }, kind = "Vanity", name = "Vanity" })
	B.loot(A, 3, V(2.4, fy + 3.2, 130.8))
	B.trunk(m, B.cf(-5.8, fy, 125.6, "+z"), C.Red:Lerp(C.Ink, 0.4), A, 3)
	B.lamp(m, "hang", CFrame.new(-3, 11.2, 130.5), A, { range = 18, shade = C.Gold:Lerp(C.Ink, 0.3) })
	B.loot(A, 3, V(-5.8, fy + 2.15, 125.6))
	B.node(A, 0, fy, 127)
end
do -- clown caravan (west)
	local m, fy = caravan("ClownCaravan", -36, -20, 124, 132, C.Teal:Lerp(C.Ink, 0.35), -28, { title = "CLOWNS", room = "Clown Caravan" })
	B.wardrobe(m, B.cf(-21.8, fy, 128, "-x"), C.Rose:Lerp(C.Ink, 0.4), A, "Closet", { name = "CostumeCloset", w = 5, d = 3, h = 8.6, doorColor = C.Mustard:Lerp(C.Ink, 0.3) })
	B.trunk(m, B.cf(-33.5, fy, 129.8, "+x"), C.Mustard:Lerp(C.Ink, 0.4), A, 3, { name = "CostumeTrunk" })
	B.fridge(m, B.cf(-34.25, fy, 125.9, "+x"), A, 3, C.Rose:Lerp(C.Paper, 0.4))
	B.dresser(m, B.cf(-28, fy, 130.95, "-z"), 3.6, 1.4, 3, C.Mustard:Lerp(C.Ink, 0.35), 2, A, 3, { search = { 2 } })
	B.loot(A, 3, V(-28, fy + 3.2, 130.8))
	B.clownFace(m, CFrame.lookAt(V(-28, fy + 6.2, 131.7), V(-28, fy + 6.2, 120)), 0.5)
	B.loot(A, 3, V(-33.5, fy + 2.15, 129.8))
	B.lamp(m, "bare", CFrame.new(-26, 11.2, 129.5), A, { drop = 2, range = 16, bright = 0.8 })
	B.node(A, -28, fy, 127)
end
do -- strongman's caravan (east)
	local m, fy = caravan("StrongmanCaravan", 20, 36, 124, 132, C.Red:Lerp(C.Ink, 0.4), 28, { title = "STRONGMAN", room = "Strongman's Caravan" })
	B.fridge(m, B.cf(34.25, fy, 128, "-x"), A, 3, C.Metal:Lerp(C.Paper, 0.3))
	B.crate(m, B.cf(22.6, fy, 129.8, 10), 2.4, C.WoodDark)
	for i = 0, 1 do
		local db = CFrame.new(30.5 + i * 2.2, fy + 0.5, 130.4)
		B.set(B.cyl(m, "Bar", db, 0.25, 2.4, V(0, 0, 0), C.Metal, M.Metal, SM, false), db)
		for _, ex in { -1.1, 1.1 } do
			B.set(B.cyl(m, "Weight", db, 1, 0.3, V(0, 0, 0), C.Ink, M.Metal, SM, false), db * CFrame.new(ex, 0, 0))
		end
	end
	local _, th = B.table(m, B.cf(24, fy, 126.2, "+z"), 3, 2, 3, C.WoodMid)
	B.loot(A, 3, V(24, fy + th, 126.2))
	B.loot(A, 3, V(22.6, fy + 2.4, 129.8))
	B.lamp(m, "bare", CFrame.new(28, 11.2, 128.5), A, { drop = 2, range = 16, bright = 0.8 })
	B.node(A, 28, fy, 127)
end
do -- lot dressing: lion cage wagon (empty), hay, crates
	local m = B.model(S, "LionCage")
	local b = CFrame.new(-24, 0, 112) * CFrame.Angles(0, math.rad(8), 0)
	B.rp(m, "Base", b, V(10, 1, 5), V(0, 2, 0), C.Red:Lerp(C.Ink, 0.4), M.Wood, { solid = true })
	B.rp(m, "Roof", b, V(10.4, 0.5, 5.4), V(0, 8.25, 0), C.Red:Lerp(C.Ink, 0.4), M.Wood, SM)
	for i = 0, 10 do
		for _, zz in { -2.3, 2.3 } do
			B.rp(m, "Bar", b, V(0.15, 5.5, 0.15), V(-4.8 + i * 0.96, 5.25, zz), C.Gold:Lerp(C.Ink, 0.4), M.Metal, SM)
		end
	end
	B.rp(m, "Collider", b, V(10, 6, 5), V(0, 5.5, 0), C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	for _, xx in { -3.5, 3.5 } do
		for _, zz in { -2.7, 2.7 } do
			B.set(B.cyl(m, "Wheel", b, 3, 0.4, V(0, 0, 0), C.WoodDark, M.Wood, { solid = true }, false), b * CFrame.new(xx, 1.5, zz) * CFrame.Angles(0, math.rad(90), 0))
		end
	end
	B.hay(S, B.cf(24, 0.05, 110, 20))
	B.hay(S, B.cf(26.5, 0.05, 113, -15), { tint = 0.25 })
	B.loot(A, 2, V(24, 2.25, 110))
	B.crate(S, B.cf(10, 0.05, 116, 12), 3)
	B.lamp(S, "post", B.cf(-12, 0.05, 118, "+x"), A, { range = 24 })
	B.node(A, 0, 0.05, 112)
	B.node(A, -30, 0.05, 118)
end

----------------------------------------------------------------- rooms
B.room("The Big Top", A, 3, -39.5, -1, 60.5, 39.5, H, 104.5)
B.room("Backstage Lot", A, 2, -40, -1, 105, 40, 16, 124)
return "big top ok, parts=" .. B.count(root)
