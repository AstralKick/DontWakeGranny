-- Stairs (visible steps + invisible collidable wedge ramps), railings, Barriers, porch, yard, Mom's car, spawns, boundary.
local B = _G.HB
local C, M = B.C, B.M
local V = Vector3.new
local S = B.F("Structure")
local FL = B.FL

-- stair along Z between (lowZ, lowY) and (highZ, highY), x0..x1. solid = fill under each step
function B.stairs(par, name, x0, x1, lowZ, lowY, highZ, highY, n, col, o)
	o = o or {}
	local m = B.model(par, name)
	local dz = (highZ - lowZ) / n
	local rise = (highY - lowY) / n
	for i = 1, n do
		local za, zb = lowZ + dz * (i - 1), lowZ + dz * i
		local top = lowY + rise * i
		local bottom = if o.open then top - 0.3 else (o.floorY or lowY) - 0.1
		B.box(m, "Step", x0, bottom, za, x1, top, zb, col, M.WoodPlanks, { collide = (not o.open) or i == n, query = true, shadow = true })
		if not o.open then
			B.box(m, "Nose", x0, top - 0.12, za - (if dz > 0 then 0.08 else -0.08), x1, top + 0.02, za, C.WoodDark, M.Wood, { small = true })
		end
	end
	-- wedge through the step noses, extended one run past the bottom
	local zLow = lowZ - dz
	local zHigh = highZ - dz
	local len = math.abs(zHigh - zLow)
	local ctr = V((x0 + x1) / 2, (lowY + highY) / 2, (zLow + zHigh) / 2)
	local dirLow = V(0, 0, if zLow < zHigh then -1 else 1)
	local w = B.part(m, "Ramp", V(x1 - x0, highY - lowY, len), CFrame.lookAt(ctr, ctr + dirLow), C.Paper, M.SmoothPlastic, { inv = true, collide = true, class = "WedgePart" })
	w.CanQuery = true
	return m
end
-- railing: posts + handrail from p0 to p1 (floor-level points), with an invisible collider
function B.rail(par, p0, p1, h, col, spacing)
	local m = B.model(par, "Railing")
	local d = p1 - p0
	local len = d.Magnitude
	local n = math.max(1, math.floor(len / (spacing or 1.3)))
	for i = 0, n do
		local p = p0 + d * (i / n)
		B.part(m, if i == 0 or i == n then "Newel" else "Baluster", if i == 0 or i == n then V(0.5, h + 0.3, 0.5) else V(0.18, h, 0.18), CFrame.new(p + V(0, (h + (if i == 0 or i == n then 0.3 else 0)) / 2, 0)), col, M.Wood, { small = true })
	end
	local mid = p0 + d / 2 + V(0, h, 0)
	B.part(m, "Handrail", V(0.35, 0.3, len), CFrame.lookAt(mid, mid + d), col, M.Wood, { small = true })
	B.part(m, "RailCollider", V(0.4, 4.5, len), CFrame.lookAt(p0 + d / 2 + V(0, 2.25, 0), p0 + d / 2 + V(0, 2.25, 0) + d), C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	return m
end

local stairCol = C.WoodMid
-- main stairs: X -13..-6, Z 4 (Y2) -> Z 28 (Y15)
B.stairs(B.F("Ground"), "MainStairs", -13, -6, 4, FL.Ground, 28, FL.Upstairs, 16, stairCol)
-- side skirt board along the open side
B.part(B.F("Ground"), "StairSkirt", V(0.3, 1.2, math.sqrt(24 ^ 2 + 13 ^ 2)), CFrame.lookAt(V(-5.95, 8.5, 16), V(-5.95, 8.5 + 13, 16 + 24)), C.WoodDark, M.Wood, { small = true })
-- diagonal handrail on the open side
do
	local m = B.model(B.F("Ground"), "StairRail")
	local p0, p1 = V(-6.3, FL.Ground, 3.5), V(-6.3, FL.Upstairs, 27.5)
	for i = 0, 12 do
		local t = i / 12
		local p = p0:Lerp(p1, t)
		local bh = if i == 0 then 4.4 else 3.6
		B.part(m, if i == 0 then "Newel" else "Baluster", if i == 0 then V(0.6, bh, 0.6) else V(0.18, bh, 0.18), CFrame.new(p + V(0, bh / 2 + 0.4, 0)), C.WoodDark, M.Wood, { small = true })
	end
	local a, b = p0 + V(0, 4.1, 0), p1 + V(0, 4.1, 0)
	B.part(m, "Handrail", V(0.35, 0.3, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), C.WoodDark, M.Wood, { small = true })
	B.part(m, "RailCollider", V(0.3, 5, (b - a).Magnitude), CFrame.lookAt((a + b) / 2 - V(0, 1.6, 0), b - V(0, 1.6, 0)), C.Paper, M.SmoothPlastic, { inv = true, collide = true })
end
-- upstairs railings around the stair hole (X -13..-6, Z 4..28)
B.rail(B.F("Upstairs"), V(-6.2, FL.Upstairs, 4.2), V(-6.2, FL.Upstairs, 27.8), 3.4, C.WoodDark)
B.rail(B.F("Upstairs"), V(-12.8, FL.Upstairs, 4.2), V(-6.2, FL.Upstairs, 4.2), 3.4, C.WoodDark)
-- basement stairs: X 14..22, high Z 4 (Y2) -> low Z 28 (Y-11)
B.stairs(B.F("Basement"), "BasementStairs", 14, 22, 28, FL.Basement, 4, FL.Ground, 16, C.WoodRaw:Lerp(C.Ink, 0.25), { floorY = FL.Basement })
-- side fillers between stair and walls, and a landing at the top
B.box(B.F("Basement"), "StairSide", 13.25, FL.Basement, 4, 14, FL.Ground, 28, C.Concrete, M.Concrete, { solid = true })
B.box(B.F("Basement"), "StairSide", 22, FL.Basement, 4, 22.75, FL.Ground, 28, C.Concrete, M.Concrete, { solid = true })
-- attic stairs: X 20..27, low Z 31 (Y15) -> high Z 11 (Y28). steep open treads like a pull-down stair
B.stairs(B.F("Upstairs"), "AtticStairs", 20.05, 26.95, 31, FL.Upstairs, 11, FL.Attic, 16, C.WoodRaw, { open = true })
for _, x in { 20.1, 26.9 } do
	local len = math.sqrt(20 ^ 2 + 13 ^ 2)
	B.part(B.F("Upstairs"), "Stringer", V(0.25, 1, len), CFrame.lookAt(V(x, 21.3, 21), V(x, 21.3 + 13, 21 - 20)), C.WoodRaw:Lerp(C.Ink, 0.2), M.Wood, { solid = true })
end
-- close the space under the attic stairs (wedge panels)
for _, x in { 20.05, 26.95 } do
	B.part(B.F("Upstairs"), "UnderStair", V(0.1, 13, 20), CFrame.new(x, 21.5, 21) * CFrame.Angles(0, math.pi, 0), C.WNight, M.Plaster, { solid = true, class = "WedgePart" })
end
-- attic rails around the attic floor hole (X20..27, Z11..23)
B.rail(B.F("Attic"), V(19.7, FL.Attic, 11.2), V(19.7, FL.Attic, 25.2), 3.2, C.WoodRaw)
B.rail(B.F("Attic"), V(27.3, FL.Attic, 11.2), V(27.3, FL.Attic, 25.2), 3.2, C.WoodRaw)
B.rail(B.F("Attic"), V(19.7, FL.Attic, 25.2), V(27.3, FL.Attic, 25.2), 3.2, C.WoodRaw)

----------------------------------------------------------------- barriers
local BR = B.F("Barriers")
local function boards(m, x0, x1, z, y0, list, col)
	for i, spec in list do
		local y, ang = spec[1], spec[2]
		local cx = (x0 + x1) / 2
		B.part(m, "Board", V(x1 - x0 + 0.8, 0.8, 0.25), CFrame.new(cx, y0 + y, z) * CFrame.Angles(0, 0, math.rad(ang)), (col or C.WoodRaw):Lerp(C.Ink, (i % 3) * 0.12), M.WoodPlanks, { collide = false })
		for _, sx in { -1, 1 } do
			B.part(m, "Nail", V(0.15, 0.15, 0.1), CFrame.new(cx + sx * (x1 - x0) / 2 * 0.9, y0 + y + sx * math.tan(math.rad(ang)) * (x1 - x0) / 2 * 0.9, z - 0.15), C.Metal, M.Metal, { small = true })
		end
	end
end
do
	local m = B.model(BR, "Barrier_Upstairs")
	boards(m, -13, -6, 3.8, FL.Ground, { { 1.2, 4 }, { 2.9, -7 }, { 4.6, 3 }, { 6.4, -10 }, { 7.6, 6 } })
	B.box(m, "Collider", -13, FL.Ground, 3.3, -6, FL.Ground + 11.5, 4.3, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	B.part(m, "Sign", V(2.2, 1.2, 0.08), CFrame.new(-9.5, FL.Ground + 5.4, 3.6) * CFrame.Angles(0, 0, math.rad(-4)), C.Paper, M.SmoothPlastic, { small = true })
	B.part(m, "SignText", V(1.6, 0.25, 0.05), CFrame.new(-9.5, FL.Ground + 5.5, 3.54) * CFrame.Angles(0, 0, math.rad(-4)), C.Blood, M.SmoothPlastic, { small = true })
	B.attrs(m, { Area = "Upstairs" })
end
do
	local m = B.model(BR, "Barrier_Basement")
	boards(m, 15.75, 20.25, 0.55, FL.Ground, { { 1.5, -6 }, { 3.5, 8 }, { 5.2, -3 }, { 7.0, 5 } }, C.WoodDark:Lerp(C.WoodRaw, 0.5))
	B.box(m, "Collider", 15.5, FL.Ground, 0.3, 20.5, FL.Ground + 8.5, 0.75, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	-- padlock and chain
	B.part(m, "Chain", V(4.8, 0.2, 0.1), CFrame.new(18, FL.Ground + 4.2, 0.35) * CFrame.Angles(0, 0, math.rad(18)), C.Metal, M.Metal, { small = true })
	B.part(m, "Padlock", V(0.6, 0.7, 0.3), CFrame.new(18.3, FL.Ground + 4.1, 0.3), C.Brass, M.Metal, { small = true })
	B.attrs(m, { Area = "Basement" })
end
do
	local m = B.model(BR, "Barrier_Attic")
	boards(m, 20.2, 26.8, 32.3, FL.Upstairs, { { 1.2, 5 }, { 3.0, -6 }, { 4.8, 4 } })
	B.box(m, "Collider", 20, FL.Upstairs, 31.6, 27, FL.Upstairs + 9, 32.6, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	B.box(m, "Hatch", 20, 26.95, 11, 27, 27.3, 25.5, C.WoodRaw:Lerp(C.Ink, 0.3), M.WoodPlanks, { collide = true, query = true })
	B.box(m, "HatchCollider", 20, 27.3, 11, 27, 28, 25.5, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	B.part(m, "PullCord", V(0.08, 3, 0.08), CFrame.new(23.5, 25.4, 24.8), C.Paper, M.Fabric, { small = true })
	B.attrs(m, { Area = "Attic" })
end

----------------------------------------------------------------- porch
local EX = B.F("Exterior")
local P = B.model(EX, "Porch")
B.box(P, "Deck", -21, 0, -45, 11, 2, -36, C.WoodMid:Lerp(C.Ink, 0.2), M.WoodPlanks, { solid = true })
B.box(P, "Skirt", -21.1, 0, -45.1, 11.1, 1.6, -44.9, C.Paper:Lerp(C.Ink, 0.25), M.Wood, { small = true })
for i = 1, 2 do
	local r = 2 / 3
	B.box(P, "Step", -9, 0, -45 - (3 - i), -1, r * i, -45, C.WoodMid:Lerp(C.Ink, 0.2), M.WoodPlanks, { solid = true })
end
do
	local ctr = V(-5, 1, -46.6)
	B.part(P, "Ramp", V(8, 2, 3.2), CFrame.lookAt(ctr, ctr + V(0, 0, -1)), C.Paper, M.SmoothPlastic, { inv = true, collide = true, class = "WedgePart" })
end
local post = C.Paper:Lerp(C.Ink, 0.15)
for _, x in { -20.5, -9.6, -0.4, 10.5 } do
	B.box(P, "Post", x - 0.4, 2, -45.4, x + 0.4, 13.2, -44.6, post, M.Wood, { solid = true })
end
B.part(P, "PorchRoof", V(34, 0.6, 11.5), CFrame.new(-5, 13.6, -41) * CFrame.Angles(math.rad(-9), 0, 0), C.Roof, M.Slate, { solid = true })
B.box(P, "Beam", -21, 12.8, -45.5, 11, 13.3, -44.5, post, M.Wood, { small = true })
B.box(P, "Ceiling", -21, 12.6, -44.6, 11, 12.8, -36, C.Mint:Lerp(C.Paper, 0.3), M.Wood, { small = true })
B.rail(P, V(-20.5, 2, -45), V(-9.6, 2, -45), 3, post, 1.1)
B.rail(P, V(-0.4, 2, -45), V(10.5, 2, -45), 3, post, 1.1)
B.rail(P, V(-20.9, 2, -44.6), V(-20.9, 2, -36.4), 3, post, 1.1)
B.rail(P, V(10.9, 2, -44.6), V(10.9, 2, -36.4), 3, post, 1.1)
-- porch light (Lamp) beside the door, shadows on
B.lamp(P, "porch", B.cf(-1.1, 8.4, -36.05, "-z"), "Ground", { shadows = true, range = 18, bright = 1.3, color = Color3.fromRGB(255, 196, 130) })
-- door casing + welcome mat + house number
B.casing(P, "x", -35.5, -5, 4.5, FL.Ground, 8, 1.2)
B.box(P, "WelcomeMat", -7, 1.97, -39, -3, 2.06, -37, C.Mustard:Lerp(C.Ink, 0.35), M.Fabric, { small = true, collide = false })
B.part(P, "Number", V(1.2, 0.5, 0.05), CFrame.new(-5, 10.8, -36.1), C.Brass, M.Metal, { small = true })
-- porch swing / rocking chair and jack-o'-lanterns
B.rocker(P, B.cf(-15, 2, -40, -150), C.Paper:Lerp(C.Ink, 0.3))
B.pumpkinProp(P, V(-8.4, 2, -44.2), 1.1, true)
B.pumpkinProp(P, V(-1.6, 2, -44.3), 0.9, true)
B.pumpkinProp(P, V(-10.2, 0, -47.6), 0.8, false)
B.pumpkinProp(P, V(6.5, 2, -37.4), 1.3, true)

----------------------------------------------------------------- yard
local Y = B.model(EX, "Yard")
local gravel = C.Stone:Lerp(C.Paper, 0.25)
B.box(Y, "Path", -8, -0.2, -94, -2, 0.06, -48, gravel, M.Pebble, { solid = true })
B.box(Y, "Driveway", 27, -0.2, -97, 45, 0.05, -38, C.Concrete, M.Concrete, { solid = true })
for _, z in { -85, -71, -57, -46 } do
	B.box(Y, "Crack", 30 + (z % 7), 0.05, z, 39 + (z % 5), 0.07, z + 0.15, C.Ink, M.Concrete, { small = true })
end
-- stepping stones from the driveway to the path
for i = 0, 6 do
	local x = 24 - i * 3.9
	B.part(Y, "Stone", V(0.2, 2.2, 2.2), CFrame.new(x, 0.03, -58 + math.sin(i) * 0.8) * CFrame.Angles(0, 0, math.rad(90)), gravel, M.Slate, { small = true, shape = Enum.PartType.Cylinder })
end
-- dead flower beds along the house front
for _, bed in { { -45, -22 }, { 12, 45 } } do
	B.box(Y, "Bed", bed[1], -0.2, -41, bed[2], 0.25, -36.3, C.Dirt, M.Ground, { solid = true })
	B.box(Y, "BedEdge", bed[1], 0, -41.3, bed[2], 0.45, -41, C.Stone, M.Brick, { small = true })
	for x = bed[1] + 1.5, bed[2] - 1, 2.3 do
		local h = 1.2 + (x * 7 % 5) * 0.35
		B.part(Y, "DeadStalk", V(0.12, h, 0.12), CFrame.new(x, 0.25 + h / 2, -38.5 + (x % 3) * 0.6) * CFrame.Angles(math.rad((x * 13) % 30 - 15), 0, math.rad((x * 7) % 40 - 20)), C.WoodDark:Lerp(C.Grass, 0.3), M.Wood, { small = true })
		if (math.floor(x) % 3) == 0 then
			B.part(Y, "DeadBloom", V(0.45, 0.45, 0.45), CFrame.new(x + 0.2, 0.25 + h, -38.3 + (x % 3) * 0.6), C.WoodDark:Lerp(C.Mustard, 0.25), M.Fabric, { small = true, shape = Enum.PartType.Ball })
		end
	end
end
-- dead tree
do
	local t = B.model(Y, "DeadTree")
	local base = V(-36, 0, -72)
	B.part(t, "Trunk", V(2.2, 14, 2.2), CFrame.new(base + V(0, 7, 0)) * CFrame.Angles(0, 0, math.rad(4)), C.WoodDark:Lerp(C.Ink, 0.3), M.Wood, { solid = true })
	local br = { { 11, 40, 0, 7 }, { 12.5, -35, 60, 6 }, { 9, 50, 150, 5 }, { 13.5, -20, 230, 5.5 }, { 8, -45, 300, 4 } }
	for _, b in br do
		local h, tilt, yaw, len = b[1], b[2], b[3], b[4]
		local cf = CFrame.new(base + V(0, h, 0)) * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(0, 0, math.rad(tilt)) * CFrame.new(0, len / 2, 0)
		B.part(t, "Branch", V(0.6, len, 0.6), cf, C.WoodDark:Lerp(C.Ink, 0.3), M.Wood, { small = true })
	end
	B.part(t, "Swing", V(2.4, 0.2, 0.9), CFrame.new(base + V(3.5, 3.2, 0)), C.WoodRaw, M.Wood, { small = true })
	for _, dz in { -0.35, 0.35 } do
		B.part(t, "Rope", V(0.06, 7.4, 0.06), CFrame.new(base + V(3.5, 7, dz)), C.Paper:Lerp(C.Ink, 0.4), M.Fabric, { small = true })
	end
	B.part(t, "Limb", V(5, 0.5, 0.5), CFrame.new(base + V(2.6, 10.7, 0)) * CFrame.Angles(0, 0, math.rad(8)), C.WoodDark:Lerp(C.Ink, 0.3), M.Wood, { small = true })
end
-- crooked mailbox by the front gate
do
	local mb = B.model(Y, "Mailbox")
	local b = CFrame.new(-11, 0, -92.5) * CFrame.Angles(0, math.rad(12), math.rad(9))
	B.rp(mb, "Post", b, V(0.4, 4, 0.4), V(0, 2, 0), C.WoodRaw:Lerp(C.Ink, 0.3), M.Wood)
	B.rp(mb, "Box", b, V(1.2, 1.1, 2.2), V(0, 4.5, 0), C.Rose:Lerp(C.Ink, 0.35), M.Metal)
	B.rp(mb, "Flag", b, V(0.08, 0.9, 0.3), V(0.65, 4.7, 0.5), C.Blood, M.Metal, { small = true })
end
-- picket fence along the front with two closed gates; tall hedges at the sides
local F = B.model(EX, "Fence")
local fc = C.Paper:Lerp(C.Ink, 0.22)
local function picketRun(x0, x1, z)
	for x = x0, x1, 1.1 do
		local h = 3.8 + (math.floor(x * 3) % 3) * 0.08
		B.part(F, "Picket", V(0.55, h, 0.18), CFrame.new(x, h / 2, z) * CFrame.Angles(0, 0, math.rad(((x * 17) % 7 - 3) * 0.8)), fc, M.Wood, { small = true, collide = true })
	end
	B.box(F, "Rail", x0 - 0.3, 1.1, z + 0.09, x1 + 0.3, 1.4, z + 0.3, fc, M.Wood, { small = true })
	B.box(F, "Rail", x0 - 0.3, 3.0, z + 0.09, x1 + 0.3, 3.3, z + 0.3, fc, M.Wood, { small = true })
end
picketRun(-65, -9, -95)
picketRun(-1, 26, -95)
picketRun(46, 65, -95)
-- path gate (closed) and driveway gate (closed)
picketRun(-8.4, -1.6, -95.3)
picketRun(27.3, 44.7, -95.3)
for _, x in { -9, -1, 26.6, 45.4 } do
	B.box(F, "GatePost", x - 0.4, 0, -95.5, x + 0.4, 4.8, -94.7, fc, M.Wood, { solid = true })
end
local hedge = C.Grass:Lerp(C.Ink, 0.35)
for _, x in { -64, 64 } do
	for z = -94, -36, 10 do
		B.box(F, "Hedge", x - 1.8, 0, z, x + 1.8, 7.5 + (z % 3) * 0.3, z + 10.2, hedge, M.LeafyGrass, { solid = true })
	end
end
B.box(F, "Hedge", -64, 0, -34, -46, 7.2, -30, hedge, M.LeafyGrass, { solid = true })
B.box(F, "Hedge", 46, 0, -34, 64, 7.2, -30, hedge, M.LeafyGrass, { solid = true })
-- invisible boundary (well past the fence)
local BD = B.F("Boundary", EX)
local function bwall(x0, z0, x1, z1)
	B.box(BD, "Boundary", x0, -2, z0, x1, 60, z1, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
end
bwall(-67, -98, 67, -96.5)
bwall(-67, -98, -65.5, -28)
bwall(65.5, -98, 67, -28)
bwall(-67, -30, -46, -28)
bwall(46, -30, 67, -28)
-- street beyond the fence
B.box(Y, "Sidewalk", -160, -0.2, -104, 160, 0.15, -97.5, C.Concrete:Lerp(C.Paper, 0.1), M.Concrete, { solid = true })
B.box(Y, "Curb", -160, -0.2, -104.5, 160, 0.3, -104, C.Concrete, M.Concrete, { small = true })
B.box(Y, "Road", -160, -0.2, -124, 160, 0.02, -104.5, C.Ink:Lerp(C.Concrete, 0.3), M.Asphalt, { solid = true })
for x = -150, 150, 12 do
	B.box(Y, "RoadLine", x, 0.02, -114.4, x + 5, 0.05, -114.1, C.Mustard:Lerp(C.Ink, 0.4), M.SmoothPlastic, { small = true })
end
do
	local sl = B.model(Y, "StreetLamp")
	B.box(sl, "Pole", 54.7, 0, -101.3, 55.3, 16, -100.7, C.Ink, M.Metal, { small = true })
	B.box(sl, "Arm", 52, 15.6, -101.2, 55.3, 16, -100.8, C.Ink, M.Metal, { small = true })
	local bulb = B.box(sl, "Head", 51.4, 15.1, -101.5, 53, 15.6, -100.5, Color3.fromRGB(255, 200, 140), M.Neon, { small = true })
	local l = Instance.new("SpotLight")
	l.Face = Enum.NormalId.Bottom
	l.Angle = 120
	l.Range = 28
	l.Brightness = 1.2
	l.Color = Color3.fromRGB(255, 190, 130)
	l.Parent = bulb
end
-- neighbour silhouettes across the street
for i, x in { -90, -30, 35, 95 } do
	local hm = B.model(Y, "NeighbourHouse")
	B.box(hm, "Body", x - 16, 0, -160, x + 16, 22, -136, C.Night:Lerp(C.Ink, 0.4), M.SmoothPlastic, { small = true })
	B.part(hm, "Roof", V(34, 12, 26), CFrame.new(x, 28, -148), C.Ink, M.SmoothPlastic, { small = true, class = "WedgePart" })
	if i % 2 == 1 then
		B.box(hm, "LitWindow", x - 4 + i, 9, -136.2, x - 1 + i, 12, -135.9, Color3.fromRGB(200, 150, 90), M.Neon, { small = true })
	end
end

----------------------------------------------------------------- Mom's car (pastel minivan), nose toward the house
do
	local car = B.model(B.root(), "MomsCar")
	local b = B.cf(36, 0, -67, "+z")
	local body = C.Bruise:Lerp(C.Paper, 0.55)
	local glass = Color3.fromRGB(40, 44, 60)
	local R = function(n, sz, off, col, mat, o) return B.rp(car, n, b, sz, off, col, mat, o or { solid = true }) end
	R("Body", V(7, 2.6, 16), V(0, 2.1, 0), body, M.SmoothPlastic)
	R("Cabin", V(6.7, 2.9, 11.5), V(0, 4.85, 1.6), body, M.SmoothPlastic)
	B.rp(car, "Hood", b, V(6.7, 1.4, 3.2), V(0, 4.1, -5.75), body, M.SmoothPlastic, { solid = true, class = "WedgePart" })
	local ws = R("Windshield", V(6.3, 0.1, 3.4), V(0, 4.9, -4.9), glass, M.Glass, { small = true })
	ws.CFrame = b * CFrame.new(0, 4.95, -4.65) * CFrame.Angles(math.rad(-58), 0, 0)
	for _, sx in { -1, 1 } do
		R("SideGlass", V(0.1, 1.9, 10.4), V(sx * 3.37, 5.1, 1.6), glass, M.Glass, { small = true })
		R("Pillar", V(0.15, 2.0, 0.35), V(sx * 3.39, 5.1, -1.4), body, M.SmoothPlastic, { small = true })
		R("Pillar", V(0.15, 2.0, 0.35), V(sx * 3.39, 5.1, 3.2), body, M.SmoothPlastic, { small = true })
		R("DoorSeam", V(0.05, 2.4, 0.08), V(sx * 3.52, 2.6, 0.2), C.Ink, M.SmoothPlastic, { small = true })
		R("Stripe", V(0.05, 0.3, 15.6), V(sx * 3.52, 2.7, 0), C.Rose:Lerp(C.Ink, 0.1), M.SmoothPlastic, { small = true })
		R("Mirror", V(0.6, 0.45, 0.3), V(sx * 3.7, 4.2, -3.2), body, M.SmoothPlastic, { small = true })
		for _, z in { -5, 5 } do
			B.cyl(car, "Wheel", b, 2.6, 1.0, V(sx * 3.2, 1.3, z), C.Ink, M.Rubber, { solid = true }, false)
			B.cyl(car, "Hubcap", b, 1.3, 0.1, V(sx * 3.72, 1.3, z), C.Metal, M.Metal, { small = true }, false)
		end
		R("Headlight", V(1.3, 0.6, 0.1), V(sx * 2.4, 2.8, -8.02), Color3.fromRGB(230, 225, 200), M.Glass, { small = true })
		R("Taillight", V(0.9, 1.4, 0.1), V(sx * 2.9, 3.4, 8.02), C.Blood:Lerp(C.Ink, 0.2), M.Glass, { small = true })
	end
	R("BumperFront", V(7.2, 0.7, 0.6), V(0, 1.2, -8.1), C.Metal:Lerp(C.Ink, 0.3), M.Metal)
	R("BumperRear", V(7.2, 0.7, 0.6), V(0, 1.2, 8.1), C.Metal:Lerp(C.Ink, 0.3), M.Metal)
	R("Grille", V(3, 0.8, 0.1), V(0, 2.6, -8.02), C.Ink, M.Metal, { small = true })
	R("RoofRack", V(5.6, 0.2, 9), V(0, 6.45, 1.6), C.Ink, M.Metal, { small = true })
	R("RearGlass", V(5.6, 1.8, 0.1), V(0, 5.2, 7.38), glass, M.Glass, { small = true })
	local trunk = R("Trunk", V(6.4, 3.4, 0.3), V(0, 3.1, 8.05), body:Lerp(C.Ink, 0.08), M.SmoothPlastic)
	trunk.CanQuery = true
	R("Plate", V(1.6, 0.7, 0.05), V(0, 2.2, 8.22), C.Paper, M.SmoothPlastic, { small = true })
	-- a stuffed bag and a pillowcase peeking from the trunk window
	R("Bag", V(1.6, 1.1, 1.2), V(-1.4, 4.4, 6.4), C.Mustard:Lerp(C.Ink, 0.2), M.Fabric, { small = true })
	car.PrimaryPart = car:FindFirstChild("Body")
end

----------------------------------------------------------------- player spawns (beside the car, facing the door)
local SP = B.F("PlayerSpawns")
local door = V(-5, 0, -36)
for i, p in { V(26, 0, -60), V(22.5, 0, -62), V(26, 0, -64.5), V(22.5, 0, -67), V(26, 0, -69.5) } do
	B.part(SP, "Spawn" .. i, V(2, 0.2, 2), CFrame.lookAt(p + V(0, 0.1, 0), V(door.X, 0.1, door.Z)), C.Paper, M.SmoothPlastic, { inv = true })
end
return "stairs+yard ok, parts=" .. B.count(B.root())
