-- Sunny Pines: reset Workspace.Maps.SunnyPines and build the shell (slabs, floors, facades, roof),
-- the car park (MomsCar + Trunk, PlayerSpawns, lamppost, signs, fence + invisible boundary).
local B = _G.SPB
local C, M = B.C, B.M
local V = Vector3.new
local maps = workspace:FindFirstChild("Maps")
if not maps then
	maps = Instance.new("Folder")
	maps.Name = "Maps"
	maps.Parent = workspace
end
local old = maps:FindFirstChild("SunnyPines")
if old then old:Destroy() end
local root = Instance.new("Model")
root.Name = "SunnyPines"
root:SetAttribute("MapId", "SunnyPines")
root:SetAttribute("DisplayName", "Sunny Pines Retirement Home")
root:SetAttribute("AreaName_Upstairs", "THE RESIDENTS' WING")
root:SetAttribute("AreaName_Basement", "THE BOILER ROOM")
root:SetAttribute("AreaName_Attic", "MATRON'S WARD")
root.Parent = maps
for _, n in { "PlayerSpawns", "Rooms", "LootSpawns", "PrizeSpawns", "SearchNodes", "Barriers", "Corruption", "Structure", "Exterior", "Ground", "Upstairs", "Basement", "Attic", "Interactables", "Creaky" } do
	B.F(n)
end
for i = 1, 4 do B.F(tostring(i), B.F("Corruption")) end
local S = B.F("Structure")
local EX = B.F("Exterior")

-- holes (stair wells) in slabs
B.HOLE_MAIN = { -52, -40, -38.75, -23 } -- in the upstairs slab
B.HOLE_BASE = { -52, 23, -38.75, 40 } -- in the ground slab
B.HOLE_ATTIC = { 38.75, -40, 52, -23 } -- in the attic slab

-- room table: name, area, danger, x0, z0, x1, z1, y0, y1, floor colour, floor material, floor holes
local G, U, A, Bs = "Ground", "Upstairs", "Attic", "Basement"
local lino, carpet, tile = M.SmoothPlastic, M.Carpet, M.CeramicTiles
B.RM = {
	-- ground (floor 2, ceiling 14)
	{ "Reception Lobby", G, 1, -14, -40, 14, -20, 2, 14, C.PCream:Lerp(C.Lino, 0.4), M.Marble },
	{ "Main Stairwell", U, 2, -52, -40, -38.5, -20, 2, 27, C.LinoDark, lino },
	{ "Manager's Office", G, 1, -38.5, -40, -14, -20, 2, 14, C.CarpetBlue, carpet },
	{ "Nurse Station", G, 1, 14, -40, 32, -20, 2, 14, C.LinoMint, lino },
	{ "Quiet Lounge", G, 1, 32, -40, 52, -20, 2, 14, C.Carpet, carpet },
	{ "Front Corridor", G, 1, -52, -20, 52, -13, 2, 14, C.Lino, lino },
	{ "West Corridor", G, 1, -52, -13, -45, 13, 2, 14, C.Lino, lino },
	{ "Centre Corridor", G, 2, -3.5, -13, 3.5, 13, 2, 14, C.Lino, lino },
	{ "East Corridor", G, 1, 45, -13, 52, 13, 2, 14, C.Lino, lino },
	{ "Back Corridor", G, 2, -52, 13, 52, 20, 2, 14, C.Lino, lino },
	{ "Rec Room", G, 3, -45, -13, -3.5, 13, 2, 14, C.Carpet:Lerp(C.PPeach, 0.25), carpet },
	{ "Dining Hall", G, 2, 3.5, -13, 45, 13, 2, 14, C.LinoRose, lino },
	{ "Service Stairwell", Bs, 2, -52, 20, -38.5, 40, -11, 14, C.LinoDark, lino, { B.HOLE_BASE } },
	{ "Activity Room", G, 2, -38.5, 20, -14, 40, 2, 14, C.LinoMint:Lerp(C.Lino, 0.5), lino },
	{ "Washroom", G, 1, -14, 20, 0, 40, 2, 14, C.Tile, tile },
	{ "Linen Store", G, 2, 0, 20, 14, 40, 2, 14, C.Lino, lino },
	{ "Kitchen", G, 2, 14, 20, 52, 40, 2, 14, C.Tile:Lerp(C.PLemon, 0.2), tile },
	-- upstairs (floor 15, ceiling 27)
	{ "Bedroom 1", U, 2, -38.5, -40, -19, -20, 15, 27, C.Carpet:Lerp(C.PLilac, 0.3), carpet },
	{ "Bedroom 2", U, 2, -19, -40, 0, -20, 15, 27, C.CarpetBlue:Lerp(C.PBlue, 0.3), carpet },
	{ "Bedroom 3", U, 2, 0, -40, 19, -20, 15, 27, C.Carpet:Lerp(C.PPink, 0.3), carpet },
	{ "Bedroom 4", U, 2, 19, -40, 38.5, -20, 15, 27, C.CarpetBlue, carpet },
	{ "Ward Stairwell", A, 3, 38.5, -40, 52, -20, 15, 40, C.LinoDark, lino },
	{ "Upper Front Corridor", U, 2, -52, -20, 52, -13, 15, 27, C.LinoMint, lino },
	{ "Upper West Corridor", U, 2, -52, -13, -45, 13, 15, 27, C.LinoMint, lino },
	{ "Upper Centre Corridor", U, 2, -3.5, -13, 3.5, 13, 15, 27, C.LinoMint, lino },
	{ "Upper East Corridor", U, 2, 45, -13, 52, 13, 15, 27, C.LinoMint, lino },
	{ "Upper Back Corridor", U, 2, -52, 13, 52, 20, 15, 27, C.LinoMint, lino },
	{ "Shared Ward", U, 2, -45, -13, -3.5, 13, 15, 27, C.Lino, lino },
	{ "Linen Room", U, 2, 3.5, -13, 16, 13, 15, 27, C.Lino, lino },
	{ "Double Room", U, 2, 16, -13, 45, 13, 15, 27, C.Carpet:Lerp(C.PGreen, 0.3), carpet },
	{ "Bedroom 5", U, 2, -52, 20, -30, 40, 15, 27, C.Carpet:Lerp(C.PPeach, 0.3), carpet },
	{ "Bedroom 6", U, 2, -30, 20, -8, 40, 15, 27, C.CarpetBlue:Lerp(C.PLilac, 0.3), carpet },
	{ "Residents' Bathroom", U, 2, -8, 20, 8, 40, 15, 27, C.Tile, tile },
	{ "Sunroom", U, 2, 8, 20, 52, 40, 15, 27, C.LinoRose:Lerp(C.PLemon, 0.4), lino },
	-- basement (floor -11, ceiling 1)
	{ "Basement Corridor", Bs, 2, -52, 13, 0, 20, -11, 1, C.Concrete, M.Concrete },
	{ "Laundry", Bs, 2, -52, 0, -24, 13, -11, 1, C.Tile:Lerp(C.Concrete, 0.4), tile },
	{ "Boiler Room", Bs, 3, -24, 0, 0, 13, -11, 1, C.Concrete, M.Concrete },
	{ "Storage Cages", Bs, 3, -38.5, 20, -14, 40, -11, 1, C.Concrete, M.Concrete },
	{ "Maintenance Room", Bs, 2, -14, 20, 0, 40, -11, 1, C.Concrete, M.Concrete },
	-- attic (floor 28, ceiling 40)
	{ "Matron's Ward", A, 3, 14, -40, 38.5, -20, 28, 40, C.LinoDark:Lerp(C.PGreen, 0.2), lino },
	{ "Attic Corridor", A, 3, 14, -20, 52, -13, 28, 40, C.LinoDark, lino },
	{ "Matron's Office", A, 3, 14, -13, 33, 0, 28, 40, C.Carpet:Lerp(C.Blood, 0.2), carpet },
	{ "Records Room", A, 3, 33, -13, 52, 0, 28, 40, C.LinoDark, lino },
}

-- structural slabs (ceiling colour underneath)
B.slab(S, "GroundSlab", -52, -40, 52, 40, 1, 1.9, C.Ceil, M.Concrete, { B.HOLE_BASE })
B.slab(S, "UpperSlab", -52, -40, 52, 40, 14, 14.9, C.Ceil, M.Plaster, { B.HOLE_MAIN })
B.slab(S, "RoofSlab", -52, -40, 52, 40, 27, 27.9, C.Ceil, M.Plaster, { B.HOLE_ATTIC })
B.box(S, "BasementSlab", -52.5, -12, -0.5, 0.5, -11.1, 40.5, C.Concrete, M.Concrete, { solid = true })
B.box(S, "AtticRoof", 13, 40, -41, 53, 41, 1, C.Ceil, M.Plaster, { solid = true })
B.box(S, "AtticRoofTop", 12.8, 41, -41.2, 53.2, 41.3, 1.2, C.Asphalt, M.Slate, { solid = true })
-- floor finishes per room (0.1 thick), special cases for stair cores
local FF = B.F("Floors", S)
for _, r in B.RM do
	local name, area, x0, z0, x1, z1, y0 = r[1], r[2], r[4], r[5], r[6], r[7], r[8]
	local ft = if y0 < -5 then -11 elseif y0 < 10 then 2 elseif y0 < 20 then 15 else 28
	if name == "Main Stairwell" then
		B.box(FF, "Floor", x0, 1.9, z0, x1, 2, z1, r[10], r[11], { solid = true })
		B.slab(FF, "Floor", x0, z0, x1, z1, 14.9, 15, r[10], r[11], { B.HOLE_MAIN })
	elseif name == "Service Stairwell" then
		B.slab(FF, "Floor", x0, z0, x1, z1, 1.9, 2, r[10], r[11], { B.HOLE_BASE })
		B.box(FF, "Floor", x0, -11.1, z0, x1, -11, z1, r[10], r[11], { solid = true })
	elseif name == "Ward Stairwell" then
		B.box(FF, "Floor", x0, 14.9, z0, x1, 15, z1, r[10], r[11], { solid = true })
		B.slab(FF, "Floor", x0, z0, x1, z1, 27.9, 28, r[10], r[11], { B.HOLE_ATTIC })
	elseif ft == -11 then
		B.box(FF, "Floor", x0, -11.1, z0, x1, -11, z1, r[10], r[11], { solid = true })
	else
		B.box(FF, "Floor", x0, ft - 0.1, z0, x1, ft, z1, r[10], r[11], { solid = true })
	end
end
-- roof membrane over upstairs (outside the attic block)
B.slab(S, "RoofTop", -52, -40, 52, 40, 27.9, 28, C.Asphalt, M.Slate, { { 13, -41, 53, 1 } })

----------------------------------------------------------------- facades
-- two skins: outer 0.5 (brick ground / render upstairs), inner 0.5 plaster. Interior faces at x=+-52, z=+-40.
local WIN = {
	front = { Ground = { { -45, 3 }, { -31, 5 }, { -21, 5 }, { -9, 5 }, { 9, 5 }, { 20, 5 }, { 27, 5 }, { 38, 5 }, { 46, 5 } },
		Upstairs = { { -45, 3 }, { -33, 5 }, { -24, 5 }, { -13, 5 }, { -5, 5 }, { 5, 5 }, { 13, 5 }, { 24, 5 }, { 33, 5 }, { 45, 3 } } },
	back = { Ground = { { -31, 5 }, { -21, 5 }, { -7, 3, 6 }, { 7, 4 }, { 22, 5 }, { 33, 5 }, { 44, 5 } },
		Upstairs = { { -46, 5 }, { -36, 5 }, { -24, 5 }, { -14, 5 }, { 0, 3, 6 }, { 13, 6, 1.5 }, { 20.5, 6, 1.5 }, { 28, 6, 1.5 }, { 35.5, 6, 1.5 }, { 43, 6, 1.5 }, { 49, 4, 1.5 } } },
	left = { Ground = { { -8, 4 }, { 8, 4 } }, Upstairs = { { -8, 4 }, { 8, 4 }, { -30, 5 }, { 30, 5 } } },
	right = { Ground = { { -8, 4 }, { 8, 4 }, { -30, 5 }, { 30, 5 } }, Upstairs = { { -8, 4 }, { 8, 4 }, { 30, 6, 1.5 }, { 24, 4, 1.5 } } },
}
local function gapsFor(list, sillDefault, top)
	local g = {}
	for _, w in list do
		table.insert(g, { c = w[1], w = w[2], sill = w[3] or sillDefault, h = top, trim = false })
	end
	return g
end
local inner = C.PCream
local function facade(side)
	local FA = B.F("Facade_" .. side, EX)
	local axis = if side == "front" or side == "back" then "x" else "z"
	local sgn = if side == "front" or side == "left" then -1 else 1
	local face = if axis == "x" then 40 * sgn else 52 * sgn
	local a, b = if axis == "x" then -53 else -40.5, if axis == "x" then 53 else 40.5
	local ai, bi = if axis == "x" then -52.5 else -40, if axis == "x" then 52.5 else 40
	local outerC = face + sgn * 0.75
	local innerC = face + sgn * 0.25
	for _, fl in { { "Ground", 2, 15, C.Brick, M.Brick }, { "Upstairs", 15, 28, C.Render, M.Plaster } } do
		local list = WIN[side][fl[1]]
		local gaps = gapsFor(list, 3, 9.5)
		if side == "front" and fl[1] == "Ground" then
			table.insert(gaps, { c = 0, w = 4.5, h = 8, trim = false })
			table.insert(gaps, { c = -3.9, w = 2.6, sill = 0.5, h = 8, trim = false })
			table.insert(gaps, { c = 3.9, w = 2.6, sill = 0.5, h = 8, trim = false })
		end
		B.skin(FA, "Outer", axis, outerC, a, b, fl[2], fl[3], 0.5, fl[4], fl[5], table.clone(gaps))
		local gi = table.clone(gaps)
		-- inner skin stops at the interior faces; interior colour per floor
		B.skin(FA, "Inner", axis, innerC, ai, bi, fl[2], math.min(fl[3], if fl[1] == "Ground" then 14 else 27), 0.5, inner, M.Plaster, gi, -sgn)
		-- glazing
		for _, g in gaps do
			local sill = g.sill or 0
			if sill > 0 then
				B.glaze(FA, axis, face + sgn * 0.5, g.c, fl[2], sill, g.h, g.w, 1, { sill = true, frame = C.Paper })
			end
		end
	end
	-- plinth band 0..2 and floor band
	if axis == "x" then
		B.box(FA, "Plinth", a - 0.1, -0.5, face + sgn * 0.0, b + 0.1, 2, face + sgn * 1.1, C.Brick:Lerp(C.Ink, 0.25), M.Brick, { solid = true })
		B.box(FA, "Band", a - 0.1, 14.7, face + sgn * 0.95, b + 0.1, 15.3, face + sgn * 1.15, C.Paper, M.SmoothPlastic, { small = true })
	else
		B.box(FA, "Plinth", face + sgn * 0.0, -0.5, a, face + sgn * 1.1, 2, b, C.Brick:Lerp(C.Ink, 0.25), M.Brick, { solid = true })
		B.box(FA, "Band", face + sgn * 0.95, 14.7, a, face + sgn * 1.15, 15.3, b, C.Paper, M.SmoothPlastic, { small = true })
	end
end
for _, s in { "front", "back", "left", "right" } do facade(s) end
-- inner skin between ceiling and next floor (slab edge band inside the walls): walls run 14..15 / 27..28 on inner line
for _, y in { { 14, 15 }, { 27, 28 } } do
	B.box(S, "SlabEdge", -52.5, y[1], -40.5, 52.5, y[2], -40, inner, M.Plaster, { solid = true })
	B.box(S, "SlabEdge", -52.5, y[1], 40, 52.5, y[2], 40.5, inner, M.Plaster, { solid = true })
	B.box(S, "SlabEdge", -52.5, y[1], -40, -52, y[2], 40, inner, M.Plaster, { solid = true })
	B.box(S, "SlabEdge", 52, y[1], -40, 52.5, y[2], 40, inner, M.Plaster, { solid = true })
end
-- parapet around the upstairs roof and the attic block walls
local PA = B.F("Roof", EX)
B.box(PA, "Parapet", -53, 28, -41, 13, 30, -40, C.Render, M.Plaster, { solid = true })
B.box(PA, "Parapet", -53, 28, 40, 53, 30, 41, C.Render, M.Plaster, { solid = true })
B.box(PA, "Parapet", -53, 28, -40, -52, 30, 40, C.Render, M.Plaster, { solid = true })
B.box(PA, "Parapet", 52, 28, 1, 53, 30, 40, C.Render, M.Plaster, { solid = true })
for _, cap in { { -53.2, -41.2, 13, -39.8 }, { -53.2, 39.8, 53.2, 41.2 }, { -53.2, -39.8, -51.8, 39.8 }, { 51.8, 1, 53.2, 39.8 } } do
	B.box(PA, "Coping", cap[1], 30, cap[2], cap[3], 30.3, cap[4], C.Paper, M.Concrete, { small = true })
end
-- attic block: outer walls (front z=-40.5, right x=52.5 continue up; left x=13.5 and back z=0.5 new)
local AW = B.F("AtticShell", EX)
local atticWin = { front = { { 20, 4 }, { 32, 4 }, { 45, 3 } }, right = { { -30, 3 }, { -6, 4 } }, left = { { -30, 4 }, { -6, 4 } }, back = { { 24, 4 }, { 42, 4 } } }
local function atticWall(axis, fixedIn, sgn, a, b, ai, bi, list)
	local gaps = gapsFor(list, 3.5, 9)
	B.skin(AW, "Outer", axis, fixedIn + sgn * 0.75, a, b, 28, 40, 0.5, C.Render:Lerp(C.Ink, 0.08), M.Plaster, table.clone(gaps))
	B.skin(AW, "Inner", axis, fixedIn + sgn * 0.25, ai, bi, 28, 40, 0.5, C.PGreen:Lerp(C.Paper, 0.4), M.Plaster, table.clone(gaps), -sgn)
	for _, g in gaps do
		B.glaze(AW, axis, fixedIn + sgn * 0.5, g.c, 28, g.sill, g.h, g.w, 1, { sill = true, frame = C.Paper:Lerp(C.Ink, 0.2), tr = 0.45 })
	end
end
atticWall("x", -40, -1, 13, 53, 13.5, 52.5, atticWin.front)
atticWall("x", 0, 1, 13, 53, 13.5, 52.5, atticWin.back)
atticWall("z", 14, -1, -40.5, 0.5, -40, 0, atticWin.left)
atticWall("z", 52, 1, -40.5, 0.5, -40, 0, atticWin.right)
-- fill the membrane gap under the new attic walls
B.box(AW, "WallBase", 13, 27.9, 0, 53, 28, 1, C.Render, M.Plaster, { solid = true })
B.box(AW, "WallBase", 13, 27.9, -41, 14, 28, 0, C.Render, M.Plaster, { solid = true })
-- roof-top clutter: AC units, vent stacks
for i, p in { { -30, -20 }, { -12, 25 }, { 30, 25 } } do
	local m = B.model(PA, "ACUnit")
	B.box(m, "Box", p[1] - 3, 28, p[2] - 2, p[1] + 3, 31.5, p[2] + 2, C.Chrome:Lerp(C.Ink, 0.2), M.Metal, { small = true })
	B.box(m, "Fan", p[1] - 2, 31.5, p[2] - 1.5, p[1] + 2, 31.7, p[2] + 1.5, C.Ink, M.Metal, { small = true })
end
B.box(PA, "Sign", -12, 30, -41.4, 12, 33.6, -41.1, C.PMint:Lerp(C.Paper, 0.2), M.SmoothPlastic, { small = true })
B.text(PA:FindFirstChild("Sign"), Enum.NormalId.Front, "SUNNY PINES", C.Rose:Lerp(C.Ink, 0.2), Enum.Font.LuckiestGuy, { pps = 20 })

----------------------------------------------------------------- grounds
local Y = B.F("Grounds", EX)
-- grass around (leaving the basement footprint clear)
for _, r in B.rects(-110, -130, 110, 90, { { -53, -0.5, 0.5, 41 } }) do
	B.box(Y, "Grass", r[1], -2, r[2], r[3], 0, r[4], C.Grass, M.Grass, { solid = true })
end
B.box(Y, "BasementDirt", -53.5, -13, -1.5, 1.5, -12, 41.5, C.Dirt, M.Ground, { solid = true })
-- car park
B.box(Y, "Asphalt", -62, -0.2, -104, 62, 0.05, -52, C.Asphalt, M.Asphalt, { solid = true })
for x = -54, 54, 9 do
	if math.abs(x) > 10 then
		B.box(Y, "BayLine", x - 0.15, 0.05, -100, x + 0.15, 0.08, -86, C.Paper:Lerp(C.Ink, 0.2), M.SmoothPlastic, { small = true })
		B.box(Y, "BayLine", x - 0.15, 0.05, -70, x + 0.15, 0.08, -56, C.Paper:Lerp(C.Ink, 0.2), M.SmoothPlastic, { small = true })
	end
end
-- disabled bay symbol + arrows
B.box(Y, "BayMark", -7, 0.05, -66, -3, 0.08, -62, C.PBlue, M.SmoothPlastic, { small = true })
-- front terrace (floor level 2) and the wheelchair ramp
B.box(Y, "Terrace", -22, -0.5, -52, 22, 2, -41.1, C.Concrete:Lerp(C.Paper, 0.25), M.Concrete, { solid = true })
B.box(Y, "TerraceEdge", -22.2, 1.8, -52.2, 22.2, 2.1, -51.8, C.Paper:Lerp(C.Ink, 0.15), M.Concrete, { small = true, collide = false })
do
	local ctr = V(0, 1, -57)
	local ramp = B.part(Y, "Ramp", V(10, 2, 10), CFrame.lookAt(ctr, ctr + V(0, 0, -1)), C.Concrete:Lerp(C.Paper, 0.25), M.Concrete, { solid = true, class = "WedgePart" })
	ramp.CanQuery = true
	for _, sx in { -1, 1 } do
		B.rail(Y, V(sx * 5.3, 0, -62), V(sx * 5.3, 2, -52), 3, C.Chrome, 2)
		local wing = B.part(Y, "RampWall", V(0.6, 2, 10), CFrame.lookAt(V(sx * 5.3, 1, -57), V(sx * 5.3, 1, -58)), C.Concrete, M.Concrete, { solid = true, class = "WedgePart" })
		local _ = wing
	end
end
-- entrance canopy on posts
local CAN = B.model(Y, "Canopy")
B.box(CAN, "Roof", -9, 12, -50, 9, 12.8, -41, C.PMint:Lerp(C.Ink, 0.1), M.Metal, { solid = true })
B.box(CAN, "Fascia", -9.1, 11.6, -50.1, 9.1, 12.9, -49.9, C.Paper, M.SmoothPlastic, { small = true })
B.text(CAN:FindFirstChild("Fascia"), Enum.NormalId.Front, "Welcome to Sunny Pines ~ Visiting 2 till 4", C.Ink, Enum.Font.FredokaOne, { pps = 25 })
for _, x in { -8.5, 8.5 } do
	B.box(CAN, "Post", x - 0.3, 2, -49.8, x + 0.3, 12, -49.2, C.Chrome, M.Metal, { solid = true })
end
B.lamp(CAN, "fluoro", CFrame.new(0, 12, -45.5), "Ground", { len = 5, bright = 1.3, range = 20, color = Color3.fromRGB(230, 236, 220) })
-- monument sign
do
	local sg = B.model(Y, "SunnyPinesSign")
	B.box(sg, "Base", 14, 0, -58, 26, 1.2, -56.6, C.Brick, M.Brick, { solid = true })
	local board = B.box(sg, "Board", 14.4, 1.2, -57.5, 25.6, 5.4, -57.1, C.PMint:Lerp(C.Paper, 0.3), M.Wood, { solid = true })
	B.text(board, Enum.NormalId.Front, "Sunny Pines\nRetirement Home", C.Ink, Enum.Font.LuckiestGuy, { pps = 25 })
	B.text(board, Enum.NormalId.Back, "Est. 1974 ~ Where every day is sunny!", C.Ink, Enum.Font.PatrickHand, { pps = 25 })
	for i = 0, 5 do
		B.part(sg, "Flower", V(0.6, 0.6, 0.6), CFrame.new(14.8 + i * 2, 1.5, -56.3), if i % 2 == 0 then C.Mustard else C.Rose, M.Fabric, { small = true, shape = Enum.PartType.Ball })
	end
end
-- lamppost over Mom's car
do
	local lp = B.model(Y, "Lamppost")
	B.box(lp, "Pole", 27.7, 0, -73.3, 28.3, 16, -72.7, C.Ink, M.Metal, { solid = true })
	B.box(lp, "Arm", 24, 15.6, -73.2, 28.3, 16, -72.8, C.Ink, M.Metal, { small = true })
	local head = B.box(lp, "Head", 22.8, 15.1, -73.6, 25, 15.6, -72.4, Color3.fromRGB(255, 206, 150), M.Neon, { small = true })
	local l = Instance.new("SpotLight")
	l.Face = Enum.NormalId.Bottom
	l.Angle = 120
	l.Range = 30
	l.Brightness = 1.6
	l.Shadows = true
	l.Color = Color3.fromRGB(255, 196, 140)
	l.Parent = head
	for _, x in { -40, 40 } do
		local lp2 = B.model(Y, "Lamppost")
		B.box(lp2, "Pole", x - 0.3, 0, -95.3, x + 0.3, 16, -94.7, C.Ink, M.Metal, { solid = true })
		local h2 = B.box(lp2, "Head", x - 1.1, 15.1, -95.6, x + 1.1, 15.6, -94.4, Color3.fromRGB(255, 190, 130), M.Neon, { small = true })
		local l2 = Instance.new("SpotLight")
		l2.Face = Enum.NormalId.Bottom
		l2.Angle = 120
		l2.Range = 26
		l2.Brightness = 1
		l2.Color = Color3.fromRGB(255, 190, 130)
		l2.Parent = h2
	end
end
-- pines and shrubs
for _, p in { { -70, -70, 1.3 }, { -74, -44, 1.1 }, { 68, -60, 1.25 }, { 70, -30, 1.0 }, { -70, 10, 1.4 }, { 72, 20, 1.3 }, { -40, 60, 1.5 }, { 10, 62, 1.2 }, { 50, 60, 1.4 }, { -80, -110, 1.3 }, { 80, -112, 1.4 }, { -30, -118, 1.1 }, { 35, -120, 1.2 } } do
	B.pine(Y, p[1], p[2], p[3])
end
for _, x in { -40, -30, 30, 40 } do
	B.box(Y, "Hedge", x - 4, 0, -51, x + 4, 3, -48, C.Grass:Lerp(C.Ink, 0.3), M.LeafyGrass, { solid = true })
end
-- a bench by the entrance
do
	local bb = B.cf(-15, 2, -45, "-z")
	local bm = B.model(Y, "Bench")
	B.rp(bm, "Seat", bb, V(6, 0.3, 1.6), V(0, 1.8, 0), C.WoodLight, M.Wood, { solid = true })
	B.rp(bm, "Back", bb, V(6, 1.4, 0.25), V(0, 2.9, 0.75), C.WoodLight, M.Wood, { small = true })
	for _, sx in { -1, 1 } do B.rp(bm, "Leg", bb, V(0.3, 1.8, 1.4), V(sx * 2.6, 0.9, 0), C.Ink, M.Metal, { small = true }) end
	local plaque = B.rp(bm, "Plaque", bb, V(1.6, 0.35, 0.05), V(0, 2.9, 0.6), C.Brass, M.Metal, { small = true })
	B.text(plaque, Enum.NormalId.Front, "In loving memory of Mabel", C.Ink, Enum.Font.SpecialElite)
end
-- the old minibus
do
	local mb = B.model(Y, "Minibus")
	local b = B.cf(-36, 0, -62, "+z")
	local col = C.PLemon:Lerp(C.Paper, 0.2)
	B.rp(mb, "Body", b, V(7.5, 6, 18), V(0, 3.9, 0), col, M.SmoothPlastic, { solid = true })
	B.rp(mb, "Stripe", b, V(7.6, 0.8, 18.1), V(0, 3.2, 0), C.PMint:Lerp(C.Ink, 0.2), M.SmoothPlastic, { small = true })
	for _, sx in { -1, 1 } do
		B.rp(mb, "Windows", b, V(0.1, 1.8, 14), V(sx * 3.8, 5.3, 1), Color3.fromRGB(40, 44, 60), M.Glass, { small = true })
		for _, z in { -6, 6 } do
			B.cyl(mb, "Wheel", b, 2.6, 0.9, V(sx * 3.4, 1.3, z), C.Ink, M.Rubber, { small = true }, false)
		end
	end
	local side = B.rp(mb, "Lettering", b, V(0.05, 1.2, 10), V(-3.78, 2.2, 0), col, M.SmoothPlastic, { small = true })
	B.text(side, Enum.NormalId.Left, "SUNNY PINES", C.Rose:Lerp(C.Ink, 0.3), Enum.Font.LuckiestGuy)
	B.rp(mb, "Windshield", b, V(6.8, 2.2, 0.1), V(0, 5.2, -9.02), Color3.fromRGB(40, 44, 60), M.Glass, { small = true })
end
-- fence + invisible boundary: car park only (Z -106..-41, X -66..66), meets the building front corners
local FN = B.F("Fence", EX)
local function fence(x0, z0, x1, z1)
	local d = V(x1 - x0, 0, z1 - z0)
	local len = d.Magnitude
	local mid = V((x0 + x1) / 2, 0, (z0 + z1) / 2)
	B.part(FN, "Wall", V(0.8, 2.2, len), CFrame.lookAt(mid + V(0, 1.1, 0), mid + V(0, 1.1, 0) + d), C.Brick, M.Brick, { solid = true })
	B.part(FN, "Railing", V(0.3, 3.2, len), CFrame.lookAt(mid + V(0, 3.8, 0), mid + V(0, 3.8, 0) + d), C.Ink, M.DiamondPlate, { small = true, tr = 0.4 })
	B.part(FN, "TopRail", V(0.4, 0.25, len + 0.1), CFrame.lookAt(mid + V(0, 5.4, 0), mid + V(0, 5.4, 0) + d), C.Ink, M.Metal, { small = true })
	B.part(FN, "Boundary", V(1, 70, len), CFrame.lookAt(mid + V(0, 33, 0), mid + V(0, 33, 0) + d), C.Paper, M.SmoothPlastic, { inv = true, collide = true })
end
fence(-66, -106, 66, -106)
fence(-66, -106, -66, -41)
fence(66, -106, 66, -41)
fence(-66, -41.2, -53, -41.2)
fence(53, -41.2, 66, -41.2)
-- gate pillars at the car park entrance (closed gate)
B.box(FN, "GatePillar", -6.8, 0, -106.8, -5.2, 7, -105.2, C.Brick, M.Brick, { solid = true })
B.box(FN, "GatePillar", 5.2, 0, -106.8, 6.8, 7, -105.2, C.Brick, M.Brick, { solid = true })
-- the road outside
B.box(Y, "Pavement", -110, 0.0, -114, 110, 0.2, -107, C.Concrete:Lerp(C.Paper, 0.15), M.Concrete, { solid = true })
B.box(Y, "Road", -110, -0.2, -130, 110, 0.05, -114, C.Asphalt:Lerp(C.Ink, 0.3), M.Asphalt, { solid = true })

----------------------------------------------------------------- Mom's car, player spawns
do
	local car = B.model(B.root(), "MomsCar")
	local b = B.cf(22, 0.05, -70, "+z") -- wheels rest on the asphalt (top 0.05)
	local body = C.Bruise:Lerp(C.Paper, 0.55)
	local glass = Color3.fromRGB(40, 44, 60)
	local R = function(n, sz, off, col, mat, o) return B.rp(car, n, b, sz, off, col, mat, o or { solid = true }) end
	R("Body", V(7, 2.6, 16), V(0, 2.1, 0), body, M.SmoothPlastic)
	R("Cabin", V(6.7, 2.9, 11.5), V(0, 4.85, 1.6), body, M.SmoothPlastic)
	B.rp(car, "Hood", b, V(6.7, 1.4, 3.2), V(0, 4.1, -5.75), body, M.SmoothPlastic, { solid = true, class = "WedgePart" })
	local ws = R("Windshield", V(6.3, 0.1, 3.4), V(0, 4.9, -4.9), glass, M.Glass, { small = true })
	ws.CFrame = B.W * b * CFrame.new(0, 4.95, -4.65) * CFrame.Angles(math.rad(-58), 0, 0)
	for _, sx in { -1, 1 } do
		R("SideGlass", V(0.1, 1.9, 10.4), V(sx * 3.37, 5.1, 1.6), glass, M.Glass, { small = true })
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
	R("Bag", V(1.6, 1.1, 1.2), V(-1.4, 4.4, 6.4), C.Mustard:Lerp(C.Ink, 0.2), M.Fabric, { small = true })
	car.PrimaryPart = car:FindFirstChild("Body")
end
local SP = B.F("PlayerSpawns")
local door = V(0, 0.15, -41)
for i, p in { V(13, 0, -64), V(9.5, 0, -66.5), V(13, 0, -69), V(9.5, 0, -71.5), V(13, 0, -74) } do
	B.part(SP, "Spawn" .. i, V(2, 0.2, 2), CFrame.lookAt(p + V(0, 0.15, 0), door), C.Paper, M.SmoothPlastic, { inv = true })
end
return "shell ok, parts=" .. B.count(root)
