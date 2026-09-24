-- Sunny Pines upstairs = THE RESIDENTS' WING: bedrooms 1-6, shared ward (curtain cubicles), linen room,
-- double room, residents' bathroom, sunroom, corridors. Contract items for Area "Upstairs".
local B = _G.SPB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local SM = { small = true }
local UP = B.F("Upstairs")
local U = "Upstairs"
local y = 15
local function F(n) return B.F(n, UP) end
local function loot(d, x, yy, z) B.loot(U, d, V(x, yy, z)) end

----------------------------------------------------------------- corridors + stair core
local CO = F("Corridors")
for _, p in { { -30, -16.5 }, { 20, -16.5 }, { -20, 16.5 }, { 30, 16.5 } } do
	B.lamp(CO, "fluoro", CFrame.new(p[1], 27, p[2]), U, { len = 4, bright = 0.9, tint = Color3.fromRGB(226, 240, 228) })
end
for _, p in { { -35, -16.5 }, { 0, -16.5 }, { -48.5, 5 }, { 25, 16.5 } } do B.creak(p[1], y, p[2]) end
for _, p in { { -44, -16.5 }, { 10, -16.5 }, { -48.5, -4 }, { 0, 6 }, { 48.5, 0 }, { -12, 16.5 }, { 42, 16.5 } } do B.node(U, p[1], y, p[2]) end
B.node(U, -42, y, -21.5) -- stair core landing
loot(2, 36, y + 1.93, -25.5)
loot(2, -2.5, y + 1.93, -25.5)
B.picture(CO, cf(-10, 21, -13.25, "-z"), 3.4, 2.6, { canvas = C.PMint, scene = C.PGreen, frame = C.WoodLight })
B.picture(CO, cf(24, 21, 13.25, "+z"), 3.4, 2.6, { canvas = C.PPeach, scene = C.PGreen, frame = C.WoodLight })
B.sign(CO, cf(-51.99, 21.5, -2, "+x"), 4, 2.2, "RESIDENTS' WING\nRooms 1-7  ->", C.PBlue, C.Ink, Enum.Font.FredokaOne)
B.sign(CO, cf(43.5, 21.5, -19.75, "+z"), 3.6, 2.6, "MATRON'S WARD\nis CLOSED.\nDo not ask.", C.Paper, C.Blood, Enum.Font.PatrickHand)
B.plant(CO, cf(-50.3, y, -18.3), 0.9)

----------------------------------------------------------------- front bedrooms 1-4 (Z -40..-20)
local fronts = {
	{ "Bedroom1", -38.5, -19, -28.5, C.PPink, C.Rose:Lerp(C.Paper, 0.3) },
	{ "Bedroom2", -19, 0, -9, C.PBlue, C.PBlue:Lerp(C.Ink, 0.1) },
	{ "Bedroom3", 0, 19, 9, C.PLilac, C.PLilac:Lerp(C.Ink, 0.1) },
	{ "Bedroom4", 19, 38.5, 28.5, C.PPeach, C.PMint:Lerp(C.Ink, 0.1) },
}
for i, r in fronts do
	local P = F(r[1])
	local x0, x1, bx = r[2], r[3], r[4]
	B.hbed(P, cf(bx, y, -35.6, "+z"), U, { sheet = r[6], board = r[5]:Lerp(C.Ink, 0.15) })
	B.bedside(P, cf(bx + 3.1, y, -38.8, "+z"), C.WoodLight, U, 2)
	B.picture(P, cf(x0 + 0.25, 21.5, -31, "+x"), 3, 3.6, { portrait = true, canvas = r[5], clothes = C.Night:Lerp(r[5], 0.3), hair = C.Sheet })
	B.rug(P, bx, y, -28.2, 5, 3, r[5]:Lerp(C.Ink, 0.35))
	B.node(U, bx, y, -26)
	if i == 1 then
		B.prize(U, V(bx + 2.9, y + 2.6, -38.3))
		B.lamp(P, "table", cf(bx + 3.55, y + 2.6, -39.25), U, { shade = C.Rose, range = 12 })
	else
		loot(2, bx + 2.8, y + 2.6, -38.5)
	end
	if i % 2 == 1 then
		B.chair(P, cf(x0 + 2.5, y, -25.5, "+x"), r[5]:Lerp(C.Ink, 0.25))
	else
		B.chair(P, cf(x1 - 2.5, y, -25.5, "-x"), r[5]:Lerp(C.Ink, 0.25))
	end
	if i == 2 or i == 4 then
		B.wardrobe(P, cf(x0 + 2.36, y, -27, "+x"), C.WoodMid, U, "Wardrobe", { name = "Wardrobe" })
	else
		B.shelf(P, cf(x1 - 1.2, y, -30, "-x"), 3.6, 6, C.WoodLight, { seed = i, shelves = 3 })
		if i == 1 then loot(2, -20.9, y + 3.98, -30) else loot(2, 17.8, y + 2.18, -30.5) end -- free spots between the shelf stock
	end
	if i == 3 then B.vase(P, cf(bx + 3.6, y + 2.6, -39.3), C.PMint, 0.7) end
end

----------------------------------------------------------------- back bedrooms 5, 6 (Z 20..40)
local backs = { { "Bedroom5", -52, -30, -41, C.PBlue, C.PBlue:Lerp(C.Ink, 0.15) }, { "Bedroom6", -30, -8, -19, C.PPink, C.PPink:Lerp(C.Ink, 0.15) } }
for i, r in backs do
	local P = F(r[1])
	local x0, x1, bx = r[2], r[3], r[4]
	B.hbed(P, cf(bx, y, 35.6, "-z"), U, { sheet = r[6], board = r[5]:Lerp(C.Ink, 0.15) })
	B.bedside(P, cf(bx + 3.1, y, 38.8, "-z"), C.WoodLight, U, 2)
	loot(2, bx + 3.1, y + 2.6, 38.8)
	B.picture(P, if i == 1 then cf(-30.25, 21, 34, "-x") else cf(-29.75, 21, 34, "+x"), 2.6, 3.2, { portrait = true, canvas = r[5], clothes = C.Ink, hair = C.Sheet })
	B.node(U, bx, y, 27)
	if i == 1 then
		B.wardrobe(P, cf(-32.4, y, 26, "-x"), C.WoodMid, U, "Wardrobe", { name = "Wardrobe" })
		B.wheelchair(P, cf(-49.5, y, 24, "+z"))
	else
		B.chair(P, cf(-10.5, y, 25, "-x"), C.PPink:Lerp(C.Ink, 0.25))
		B.table(P, cf(-12.6, y, 29), 2, 2, 2.6, C.WoodLight, { leg = C.WoodDark })
		loot(2, -12.6, y + 2.6, 29)
	end
end

----------------------------------------------------------------- shared ward (curtain cubicles)
local WD = F("SharedWard")
B.hbed(WD, cf(-38, y, -8.5, "+z"), U, { sheet = C.PMint })
B.hbed(WD, cf(-12, y, 8.5, "-z"), U, { sheet = C.PBlue, name = "HospitalBed2" })
B.cubicle(WD, cf(-31, y, -10, "+z"), U, 12, { name = "WardCubicle" })
B.cubicle(WD, cf(-17, y, 10, "-z"), U, 12, { name = "WardCubicle", col = C.PBlue:Lerp(C.Paper, 0.3) })
B.bedside(WD, cf(-41.1, y, -11.65, "+z"), C.Paper:Lerp(C.PMint, 0.3), U, 2)
B.bedside(WD, cf(-8.9, y, 11.65, "-z"), C.Paper:Lerp(C.PMint, 0.3), U, 2, false)
loot(2, -41.1, y + 2.6, -11.65)
loot(2, -8.9, y + 2.6, 11.65)
-- empty beds (no hiding) with folded sheets
for _, p in { { -38, 8.5, "-z" }, { -12, -8.5, "+z" } } do
	local b = cf(p[1], y, p[2], p[3])
	local m = B.model(WD, "EmptyBed")
	B.rp(m, "Frame", b, V(3.8, 0.4, 7.6), V(0, 2.5, 0), C.Chrome, M.Metal, { solid = true })
	B.rp(m, "Mattress", b, V(3.6, 0.7, 7.2), V(0, 3.05, 0), C.Sheet, M.Fabric, { solid = true })
	B.rp(m, "Folded", b, V(2, 0.4, 1.4), V(0, 3.6, 1.8), C.Paper, M.Fabric, SM)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do B.rp(m, "Leg", b, V(0.25, 2.3, 0.25), V(sx * 1.7, 1.15, sz * 3.6), C.Chrome, M.Metal, SM) end
	end
	B.rp(m, "HeadBoard", b, V(4.1, 3.2, 0.25), V(0, 3.2, 3.9), C.PMint:Lerp(C.Ink, 0.15), M.SmoothPlastic, { solid = true })
end
loot(2, -12, y + 3.4, -9.1)
do -- IV drip stands
	for _, p in { { -35.2, -5.5 }, { -14.8, 5.5 } } do
		local m = B.model(WD, "DripStand")
		B.box(m, "Base", p[1] - 0.6, y, p[2] - 0.6, p[1] + 0.6, y + 0.2, p[2] + 0.6, C.Chrome, M.Metal, SM)
		B.box(m, "Pole", p[1] - 0.06, y + 0.2, p[2] - 0.06, p[1] + 0.06, y + 6.5, p[2] + 0.06, C.Chrome, M.Metal, SM)
		B.box(m, "Bag", p[1] - 0.35, y + 5.2, p[2] - 0.12, p[1] + 0.35, y + 6.2, p[2] + 0.12, C.Glass:Lerp(C.Paper, 0.5), M.Glass, { small = true, tr = 0.3 })
	end
end
B.crockery(WD, cf(-24, y + 2.8, -3))
B.table(WD, cf(-24, y, -3), 3, 2.2, 2.8, C.PMint:Lerp(C.Ink, 0.2), { name = "BedTable" })
B.lamp(WD, "fluoro", CFrame.new(-24, 27, 0), U, { len = 5, bright = 0.8, tint = Color3.fromRGB(226, 240, 228) })
B.sign(WD, cf(-44.75, 21.5, -8, "+x"), 3.4, 2, "WARD B\nquiet please", C.Paper, C.Ink, Enum.Font.FredokaOne)
B.node(U, -24, y, 4)
B.node(U, -40, y, 0)
loot(2, -38, y + 3.4, 9.1)

----------------------------------------------------------------- linen room
local LR = F("LinenRoom")
for i, z in { -2, 5.5 } do
	B.shelf(LR, cf(14.75, y, z, "-x"), 5.5, 8, C.Paper:Lerp(C.Ink, 0.2), { pal = { C.Paper, C.PBlue, C.Sheet, C.PPink }, seed = i + 3 })
	loot(2, 14.75, y + (if i == 1 then 4.07 else 2.22), if i == 1 then -1.7 else 5.7)
end
B.cart(LR, cf(7, y, 6, "+x"), U, { col = C.PMint:Lerp(C.Ink, 0.2) })
B.lockers(LR, cf(4.9, y, -4, "+x"), 2, U, 2, { 2 }, C.PBlue:Lerp(C.Metal, 0.3))
B.node(U, 10, y, -4)

----------------------------------------------------------------- double room (room 7)
local DR = F("DoubleRoom")
B.hbed(DR, cf(22, y, 8.5, "-z"), U, { sheet = C.PLemon:Lerp(C.Ink, 0.15), name = "HospitalBedA" })
B.hbed(DR, cf(38, y, 8.5, "-z"), U, { sheet = C.PGreen:Lerp(C.Paper, 0.2), name = "HospitalBedB" })
B.bedside(DR, cf(30, y, 11.6, "-z"), C.WoodLight, U, 2)
B.lamp(DR, "table", cf(30.5, y + 2.6, 11.7), U, { shade = C.Mustard, range = 12 })
loot(2, 29.5, y + 2.6, 11.3)
B.bedside(DR, cf(43.65, y, -4, "-x"), C.WoodMid, U, 2)
B.prize(U, V(43.65, y + 2.6, -4))
B.armchair(DR, cf(20, y, -6, "+z"), C.PGreen:Lerp(C.Ink, 0.2), "Armchair", { w = 4, d = 4 })
loot(2, 20, y + 2.2, -5.65)
B.picture(DR, cf(44.75, 21.5, 4, "-x"), 3, 2.4, { canvas = C.Night, scene = C.PGreen:Lerp(C.Ink, 0.4), name = "MedalFrame" })
B.rug(DR, 30, y, 0, 8, 5, C.PLemon:Lerp(C.Ink, 0.4))
B.node(U, 30, y, 0)

----------------------------------------------------------------- residents' bathroom
local BA = F("ResidentsBathroom")
do
	local tub = B.model(BA, "Bathtub")
	local b = cf(-4, y, 36.4, "-z")
	B.rp(tub, "Body", b, V(7, 2.4, 3.6), V(0, 1.2, 0), C.Paper, M.SmoothPlastic, { solid = true })
	B.rp(tub, "Water", b, V(6.2, 0.1, 2.8), V(0, 2.1, 0), C.Glass:Lerp(C.PMint, 0.4), M.Glass, { small = true, tr = 0.3 })
	local panel = B.rp(tub, "BathPanel", b, V(6.8, 2.0, 0.1), V(0, 1.1, -1.85), C.PMint, M.SmoothPlastic, { collide = false })
	B.searchable(panel, "Cabinet", U, 2)
	B.rp(tub, "Hoist", b, V(0.3, 6, 0.3), V(3.2, 3, 1.4), C.Chrome, M.Metal, SM)
	B.rp(tub, "HoistArm", b, V(3, 0.25, 0.25), V(1.8, 5.9, 1.4), C.Chrome, M.Metal, SM)
end
do
	local wc = B.model(BA, "Toilet")
	local b = cf(5.8, y, 36.5, "-z")
	B.rp(wc, "Pan", b, V(1.6, 1.5, 2.2), V(0, 0.75, 0), C.Paper, M.SmoothPlastic, { solid = true })
	B.rp(wc, "Cistern", b, V(1.8, 1.8, 0.8), V(0, 2.2, 1.3), C.Paper, M.SmoothPlastic, { solid = true })
	B.rp(wc, "Seat", b, V(1.6, 0.1, 2.0), V(0, 1.55, 0), C.PMint, M.SmoothPlastic, SM)
end
B.counter(BA, cf(6.2, y, 26, "-x"), 4, C.Paper, C.Paper:Lerp(C.Ink, 0.1), U, 2, nil, { name = "Sink", topMat = M.Marble })
local mc2 = B.part(BA, "MirrorCabinet", V(2.5, 2.5, 0.4), cf(7.55, 21, 26, "-x"), C.Chrome, M.Glass, { collide = false, refl = 0.3 })
B.searchable(mc2, "Cabinet", U, 2)
loot(2, 6.2, y + 3.5, 24.8)
loot(2, -1, y + 2.4, 36.4)
B.node(U, 0, y, 28)
loot(2, 5.8, y + 3.1, 37.8)

----------------------------------------------------------------- sunroom
local SR = F("Sunroom")
for i, p in { { 16, 30, 160 }, { 22, 33, 200 }, { 40, 30, 150 }, { 46, 33, 210 } } do
	local b = cf(p[1], y, p[2], p[3])
	local m = B.model(SR, "WickerChair")
	B.rp(m, "Seat", b, V(2.6, 1.6, 2.6), V(0, 0.8, 0), C.Mustard:Lerp(C.WoodMid, 0.5), M.Fabric, { solid = true })
	B.rp(m, "Back", b, V(2.8, 3.4, 0.4), V(0, 2.5, 1.2), C.Mustard:Lerp(C.WoodMid, 0.5), M.Fabric, { small = true })
	B.rp(m, "Cushion", b, V(2.2, 0.35, 2.1), V(0, 1.77, -0.1), if i % 2 == 0 then C.PPink else C.PMint, M.Fabric, SM)
end
B.table(SR, cf(19, y, 26.5), 4, 3, 2.6, C.WoodLight, { leg = C.WoodDark, cloth = C.PLemon, name = "JigsawTable" })
loot(2, 18.2, y + 2.64, 26.5)
B.table(SR, cf(43, y, 26.5), 4, 3, 2.6, C.WoodLight, { leg = C.WoodDark, cloth = C.PPink })
loot(2, 43.6, y + 2.64, 26.8)
B.lamp(SR, "table", cf(42, y + 2.64, 26), U, { shade = C.PLemon, range = 14 })
B.vase(SR, cf(20.2, y + 2.64, 26.1), C.PBlue, 0.8)
for _, p in { { 10.5, 37.5 }, { 30, 37.8 }, { 50, 37.5 }, { 50, 22.5 } } do B.plant(SR, cf(p[1], y, p[2]), 1.1) end
do -- bird cage on a stand, the bird is long gone
	local m = B.model(SR, "BirdCage")
	B.box(m, "Stand", 33.7, y, 26.7, 34.3, y + 4.5, 27.3, C.Brass, M.Metal, SM)
	B.box(m, "Cage", 33, y + 4.5, 26, 35, y + 7, 28, C.Brass, M.DiamondPlate, { small = true, tr = 0.5 })
	B.box(m, "Seed", 33.4, y + 4.55, 26.4, 34.6, y + 4.7, 27.6, C.Mustard, M.Sand, SM)
end
loot(2, 20.3, y + 2.64, 27.3) -- (not inside the bird cage)
B.sign(SR, cf(8.25, 22, 30, "+x"), 4, 2.6, "SUNROOM\nMind the step\n(there is no step)", C.PLemon, C.Ink, Enum.Font.PatrickHand)
B.node(U, 30, y, 30)
return "upstairs ok, parts=" .. B.count(B.root())
