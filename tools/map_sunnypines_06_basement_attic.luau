-- Sunny Pines basement = THE BOILER ROOM (laundry, boiler room, storage cages, maintenance) and
-- attic = MATRON'S WARD (old ward, Matron's office, records room). Contract items for both areas.
local B = _G.SPB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local SM = { small = true }
local BA, AT = B.F("Basement"), B.F("Attic")
local Bs, A = "Basement", "Attic"
local by, ay = -11, 28
local function lootB(d, x, yy, z) B.loot(Bs, d, V(x, yy, z)) end
local function lootA(d, x, yy, z) B.loot(A, d, V(x, yy, z)) end
local function box(par, x0, x1, z0, z1, y0, h, col) -- cardboard box
	return B.box(par, "Box", x0, y0, z0, x1, y0 + h, z1, col or C.WoodRaw:Lerp(C.Paper, 0.25), M.Cardboard, { solid = true })
end
local function trunk(par, b, col, area, danger)
	local m = B.model(par, "OldTrunk")
	B.rp(m, "Body", b, V(3.6, 1.6, 2.2), V(0, 0.8, 0), col, M.Wood, { solid = true })
	local lid = B.rp(m, "Lid", b, V(3.7, 0.55, 2.3), V(0, 1.875, 0), col:Lerp(C.Ink, 0.15), M.Wood, { solid = true })
	B.searchable(lid, "Trunk", area, danger)
	for _, x in { -1.1, 1.1 } do B.rp(m, "Band", b, V(0.25, 2.2, 2.36), V(x, 1.1, 0), C.Metal:Lerp(C.Ink, 0.3), M.Metal, SM) end
	B.rp(m, "Latch", b, V(0.4, 0.5, 0.1), V(0, 1.6, -1.2), C.Brass, M.Metal, SM)
	return m
end

----------------------------------------------------------------- basement corridor + service stair foot
local BC = B.F("BasementCorridor", BA)
B.lamp(BC, "bare", CFrame.new(-26, 1, 16.5), Bs, { drop = 1.6, range = 18, color = Color3.fromRGB(255, 190, 120) })
for _, z in { 14, 14.8 } do
	B.part(BC, "Pipe", V(51.8, 0.5, 0.5), CFrame.new(-26, 0.72, z), if z < 14.5 then C.Metal else C.Blood:Lerp(C.Ink, 0.4), M.Metal, { small = true, shape = Enum.PartType.Cylinder })
end
B.creak(-20, by, 16.5, 0, C.Concrete:Lerp(C.Paper, 0.12))
B.node(Bs, -30, by, 16.5)
B.node(Bs, -8, by, 16.5)
B.node(Bs, -42, by, 21.5)
B.sign(BC, cf(-24, -5, 13.25, "+z"), 4, 1.6, "LAUNDRY  <-   -> BOILER", C.Paper, C.Ink, Enum.Font.FredokaOne)

----------------------------------------------------------------- laundry
local LA = B.F("Laundry", BA)
for i, x in { -49.4, -46.2, -43, -39.8 } do
	B.washer(LA, cf(x, by, 1.5, "+z"), if i % 2 == 0 then C.Paper:Lerp(C.Metal, 0.3) else C.PMint:Lerp(C.Metal, 0.3))
end
lootB(2, -46.2, by + 3.6, 1.5)
lootB(2, -39.8, by + 3.6, 1.8)
B.table(LA, cf(-38, by, 5.5), 5, 2.5, 3.2, C.Chrome, { mat = M.Metal, name = "FoldingTable" })
lootB(2, -37.2, by + 3.2, 5.5)
B.cart(LA, cf(-49.5, by, 8, "+x"), Bs)
B.cart(LA, cf(-30, by, 10.5, "-z"), Bs, { col = C.PPink:Lerp(C.Ink, 0.2), name = "LaundryCart2" })
B.lockers(LA, cf(-26.4, by, 2.1, "-x"), 2, Bs, 2, { 1 }, C.PMint:Lerp(C.Metal, 0.4))
B.shelf(LA, cf(-33, by, 0.9, "+z"), 5, 7, C.Metal, { stuffMat = M.Plastic, pal = { C.PBlue, C.Paper, C.PPink, C.Mustard }, d = 1.4 })
lootB(2, -34.5, by + 1.98, 0.9)
B.lamp(LA, "bare", CFrame.new(-38, 1, 7), Bs, { drop = 1.6, range = 16 })
B.creak(-44, by, 7.5, 0, C.Tile:Lerp(C.Concrete, 0.3))
B.node(Bs, -40, by, 9.5)

----------------------------------------------------------------- boiler room
local BO = B.F("BoilerRoom", BA)
B.boiler(BO, cf(-12, by, 4.7, "+z"))
B.counter(BO, cf(-1.5, by, 5, "-x"), 6, C.WoodRaw, C.WoodMid, Bs, 3, { "Drawer", nil }, { topMat = M.Wood, name = "Workbench" })
B.prize(Bs, V(-1.5, by + 3.5, 6.2))
lootB(3, -1.5, by + 3.5, 3.5)
B.lockers(BO, cf(-22.55, by, 10.9, "+x"), 2, Bs, 3, { 2 }, C.Blood:Lerp(C.Metal, 0.5))
local gauge = B.sign(BO, cf(-0.01, -4.5, 10.5, "-x"), 2.4, 1.6, "PRESSURE\nDO NOT TOUCH", C.Mustard, C.Ink, Enum.Font.FredokaOne)
local _ = gauge
B.lamp(BO, "bare", CFrame.new(-5, 1, 10.5), Bs, { drop = 1.4, range = 14, color = Color3.fromRGB(255, 170, 110) })
B.creak(-19.5, by, 2.2, 0, C.Concrete:Lerp(C.Paper, 0.12))
B.node(Bs, -18, by, 10)
B.node(Bs, -5, by, 10.5)

----------------------------------------------------------------- storage cages
local SC = B.F("StorageCages", BA)
B.cageWall(SC, V(-38.25, by, 28), V(-14.25, by, 28), 9, { { 4.1, 3.5 }, { 12.1, 3.5 }, { 20.1, 3.5 } })
for _, x in { -30, -22 } do B.cageWall(SC, V(x, by, 28.1), V(x, by, 39.9), 9) end -- start behind the front cage top bar
-- bay 1: resident's trunk and boxes
trunk(SC, cf(-35.5, by, 37.4, "-z"), C.WoodMid:Lerp(C.Blood, 0.2), Bs, 3)
box(SC, -37.9, -35.4, 30.2, 32.7, by, 2.4)
box(SC, -37.7, -35.8, 30.4, 32.5, by + 2.4, 1.8, C.WoodRaw:Lerp(C.Paper, 0.4))
lootB(3, -36.7, by + 4.2, 31.4)
-- bay 2: sheeted furniture + old wheelchair
B.wheelchair(SC, cf(-26, by, 36.5, "+z"))
do
	local m = B.model(SC, "SheetedCabinet")
	B.box(m, "Sheet", -29.5, by, 30.4, -26.5, by + 6, 32.4, C.Sheet, M.Fabric, { solid = true })
	B.box(m, "Hem", -29.7, by, 30.2, -26.3, by + 0.3, 32.6, C.Sheet:Lerp(C.Ink, 0.08), M.Fabric, SM)
end
lootB(3, -24, by, 31)
-- bay 3: strongbox (prize) on crates
box(SC, -20.5, -16.5, 36, 39.6, by, 3)
B.prize(Bs, V(-18.5, by + 3, 37.8))
box(SC, -21, -18.5, 30.5, 33, by, 2)
lootB(3, -19.75, by + 2, 31.75)
B.lamp(SC, "bare", CFrame.new(-26, 1, 24), Bs, { drop = 1.8, range = 18 })
B.creak(-22, by, 24, 0, C.Concrete:Lerp(C.Paper, 0.12))
B.node(Bs, -26, by, 24)

----------------------------------------------------------------- maintenance room
local MR = B.F("Maintenance", BA)
B.counter(MR, cf(-7, by, 38.5, "-z"), 8, C.WoodRaw, C.WoodMid, Bs, 2, nil, { topMat = M.Wood, name = "Workbench" })
lootB(2, -9, by + 3.5, 38.5)
lootB(2, -4.5, by + 3.5, 38.5)
lootB(2, -43, by + 3.6, 1.5)
B.shelf(MR, cf(-0.9, by, 28, "-x"), 5, 7, C.Metal, { stuffMat = M.Metal, pal = { C.PMint, C.PBlue, C.Mustard, C.Blood }, d = 1.4, seed = 3 })
lootB(2, -0.9, by + 1.98, 27.5)
do
	local m = B.model(MR, "MopBucket")
	B.cyl(m, "Bucket", cf(-12, by, 24), 1.4, 1.2, V(0, 0.6, 0), C.Mustard, M.Plastic, { collide = true }, true)
	B.part(m, "Mop", V(0.12, 5, 0.12), CFrame.new(-12, by + 2.6, 24) * CFrame.Angles(0, 0, math.rad(12)), C.WoodLight, M.Wood, SM)
end
B.node(Bs, -7, by, 30)

----------------------------------------------------------------- attic: stair landing + corridor
local AC = B.F("AtticCorridor", AT)
B.node(A, 42, ay, -21.5)
B.lamp(AC, "bare", CFrame.new(33, 40, -16.5), A, { drop = 1.8, range = 18, color = Color3.fromRGB(255, 180, 120) })
B.creak(28, ay, -16.5, 0, C.LinoDark:Lerp(C.Paper, 0.15))
B.creak(47, ay, -16.5, 0, C.LinoDark:Lerp(C.Paper, 0.15))
B.node(A, 20, ay, -16.5)
B.node(A, 48, ay, -16.5)
local faces = { { C.PBlue, C.Sheet }, { C.PPink, C.WoodDark }, { C.PMint, C.Sheet }, { C.PLilac, C.Paper:Lerp(C.Ink, 0.4) }, { C.PPeach, C.Sheet } }
for i, x in { 16.5, 19.5, 29.5, 36.5, 49.5 } do -- former residents
	local f = faces[i]
	B.picture(AC, cf(x, 34.2, -13.25, "-z"), 2.4, 3, { portrait = true, canvas = f[1]:Lerp(C.Ink, 0.3), clothes = C.Night, hair = f[2], frame = C.WoodDark, name = "ResidentPortrait" })
end

----------------------------------------------------------------- matron's ward (old ward)
local MW = B.F("MatronsWard", AT)
B.hbed(MW, cf(26, ay, -35.6, "+z"), A, { sheet = C.Sheet:Lerp(C.Ink, 0.2), board = C.Metal:Lerp(C.Ink, 0.3), name = "OldWardBed" })
for _, x in { 17.5, 34.2 } do
	local b = cf(x, ay, -35.6, "+z")
	local m = B.model(MW, "IronBed")
	B.rp(m, "Frame", b, V(3.6, 0.3, 7.6), V(0, 2.2, 0), C.Metal:Lerp(C.Ink, 0.35), M.Metal, { solid = true })
	B.rp(m, "Mattress", b, V(3.4, 0.6, 7.2), V(0, 2.65, 0), C.Sheet:Lerp(C.Mustard, 0.25), M.Fabric, { solid = true })
	B.rp(m, "Head", b, V(3.8, 3.6, 0.2), V(0, 1.8, 3.9), C.Metal:Lerp(C.Ink, 0.35), M.Metal, { solid = true })
	B.rp(m, "Foot", b, V(3.8, 2.4, 0.2), V(0, 1.2, -3.9), C.Metal:Lerp(C.Ink, 0.35), M.Metal, { solid = true })
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do B.rp(m, "Leg", b, V(0.2, 2.05, 0.2), V(sx * 1.7, 1.025, sz * 3.6), C.Metal:Lerp(C.Ink, 0.35), M.Metal, SM) end
	end
end
lootA(3, 17.5, ay + 2.95, -34.5)
B.bedside(MW, cf(29.2, ay, -38.8, "+z"), C.WoodDark, A, 3)
lootA(3, 29.2, ay + 2.6, -38.8)
B.bedside(MW, cf(37.1, ay, -38.8, "+z"), C.WoodDark, A, 3, false)
lootA(3, 37.1, ay + 2.6, -38.8)
lootA(3, 34.2, ay + 2.95, -34.5)
B.wheelchair(MW, cf(27, ay, -24, "+z")) -- facing the wall
for i, z in { -37.5, -34.5, -25 } do
	B.picture(MW, cf(14, 34, z, "+x"), 2.4, 3, { portrait = true, canvas = faces[i + 1][1]:Lerp(C.Ink, 0.35), clothes = C.Night, hair = faces[i][2], frame = C.WoodDark, name = "ResidentPortrait" })
end
B.sign(MW, cf(38.25, 34, -30, "-x"), 4, 2.6, "LIGHTS OUT.\nNO VISITORS.\n- Matron", C.Paper:Lerp(C.Ink, 0.2), C.Blood, Enum.Font.SpecialElite)
B.lamp(MW, "bare", CFrame.new(26, 40, -29), A, { drop = 2.2, range = 18, color = Color3.fromRGB(255, 170, 110) })
B.creak(21.5, ay, -27)
B.node(A, 26, ay, -28)

----------------------------------------------------------------- matron's office
local MO = B.F("MatronsOffice", AT)
B.table(MO, cf(24, ay, -5, "-z"), 6, 3, 3.2, C.WoodDark, { leg = C.WoodDark, name = "MatronDesk" })
B.chair(MO, cf(24, ay, -2.6, "-z"), C.Blood:Lerp(C.Ink, 0.3))
B.lamp(MO, "desk", cf(26, ay + 3.2, -5.4, "-z"), A)
B.prize(A, V(22.6, ay + 3.2, -5))
for i, z in { -11.2, -9 } do B.filing(MO, cf(15.4, ay, z, "+x"), 4, A, 3, if i == 1 then 1 else 3, C.PGreen:Lerp(C.Ink, 0.3)) end
B.wardrobe(MO, cf(18, ay, -2.06, "-z"), C.WoodDark, A, "Wardrobe", { name = "MatronWardrobe" })
do -- Matron's vanity
	local m = B.model(MO, "Vanity")
	local b = cf(30.5, ay, -1.1, "-z")
	B.rp(m, "Body", b, V(3.4, 2.8, 1.6), V(0, 1.4, 0), C.WoodDark, M.Wood, { solid = true })
	local d = B.rp(m, "VanityDrawer", b, V(3.0, 0.7, 0.1), V(0, 2.3, -0.85), C.WoodMid, M.Wood, { collide = false })
	B.searchable(d, "Vanity", A, 3)
	B.rp(m, "Mirror", b, V(2.6, 3.2, 0.12), V(0, 4.6, 0.6), C.Chrome, M.Glass, { small = true, refl = 0.35 })
	B.rp(m, "MirrorFrame", b, V(2.9, 3.5, 0.08), V(0, 4.6, 0.7), C.WoodDark, M.Wood, SM)
end
lootA(3, 29.6, ay + 2.8, -1.2)
B.picture(MO, cf(32.75, 35, -10.5, "-x"), 3.4, 4.2, { portrait = true, canvas = C.Night, clothes = C.Ink, hair = C.Ink, eyes = C.Blood, frame = C.Brass, name = "MatronPortrait" })
B.rug(MO, 24, ay, -5.5, 9, 5, C.Blood:Lerp(C.Ink, 0.45))
B.node(A, 28, ay, -9)
lootA(3, 15.4, ay + 5.4, -9)

----------------------------------------------------------------- records room
local RE = B.F("RecordsRoom", AT)
for i, x in { 36.5, 47.5 } do
	B.shelf(RE, cf(x, ay, -1.05), 4, 8, C.WoodDark, { stuffMat = M.Cardboard, pal = { C.Paper, C.PLemon, C.Sheet }, d = 1.6, seed = i })
end
lootA(3, 48.5, ay + 2.15, -2.75) -- on the records trunk lid
for i, z in { -11.2, -9 } do B.filing(RE, cf(50.6, ay, z, "-x"), 4, A, 3, if i == 1 then 2 else nil, C.WoodMid) end
B.table(RE, cf(41, ay, -6.5), 5, 3, 3, C.WoodMid, { leg = C.WoodDark, name = "RecordsTable" })
B.prize(A, V(40, ay + 3, -6.2))
lootA(3, 42.6, ay + 3, -6.2)
trunk(RE, cf(49.6, ay, -4.5, "-x"), C.WoodDark:Lerp(C.PGreen, 0.2), A, 3)
for i = 0, 3 do
	B.part(RE, "Files", V(1.4, 0.25, 1), CFrame.new(40.4 + i * 0.3, ay + 3.125 + i * 0.25, -7.4) * CFrame.Angles(0, math.rad(i * 17), 0), C.PLemon:Lerp(C.Paper, 0.3), M.Cardboard, SM)
end
B.vase(RE, cf(39.1, ay + 3, -5.8), C.PGreen, 0.7)
B.lamp(RE, "bare", CFrame.new(42, 40, -6), A, { drop = 2, range = 16 })
B.creak(36.3, ay, -10.5, 0, C.LinoDark:Lerp(C.Paper, 0.15))
B.node(A, 44, ay, -9.5)
lootA(3, 50.6, ay + 5.4, -11.2)
lootA(3, 43.3, ay + 3, -7.2)
return "basement+attic ok, parts=" .. B.count(B.root())
