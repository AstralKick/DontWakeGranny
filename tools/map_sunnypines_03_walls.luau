-- Sunny Pines: interior walls (all floors), doors, stair cores, barriers, basement shell, Rooms volumes.
local B = _G.SPB
local C, M = B.C, B.M
local V = Vector3.new
local root = B.root()
local IA = B.F("Interactables")
local GW, UW, BW, AW = B.F("Walls", B.F("Ground")), B.F("Walls", B.F("Upstairs")), B.F("Walls", B.F("Basement")), B.F("Walls", B.F("Attic"))
local RC = {
	corr = C.PLemon, lobby = C.PCream, stair = C.PCream:Lerp(C.Concrete, 0.25), office = C.PBlue, nurse = C.PMint,
	lounge = C.PLilac, rec = C.PPeach, dining = C.PPink, activity = C.PLemon:Lerp(C.PMint, 0.5), wash = C.Tile,
	linen = C.PBlue:Lerp(C.Paper, 0.3), kitchen = C.Tile:Lerp(C.PLemon, 0.2),
	ucorr = C.PMint, b1 = C.PPink, b2 = C.PBlue, b3 = C.PLilac, b4 = C.PPeach, ward = C.PMint:Lerp(C.Paper, 0.35),
	ulinen = C.PBlue:Lerp(C.Paper, 0.3), double = C.PLemon, b5 = C.PBlue, b6 = C.PPink, bath = C.Tile, sun = C.PLemon:Lerp(C.Paper, 0.2),
	base = C.Concrete:Lerp(C.Paper, 0.35), boiler = C.Concrete:Lerp(C.Blood, 0.12),
	att = C.PGreen:Lerp(C.Paper, 0.4), matron = C.Blood:Lerp(C.Paper, 0.55), records = C.PGreen:Lerp(C.Ink, 0.15),
}
B.RC = RC
local CR = { rail = 3.1 } -- corridor side: handrail
local TL = { mat = M.CeramicTiles }
local CON = { mat = M.Concrete }
local function W(par, axis, fixed, a, b, y0, y1, cn, cp, gaps, on, op)
	B.iwall(par, axis, fixed, a, b, y0, y1, cn, cp, gaps, on, op)
end
local g, u, bs, at = 2, 15, -11, 28
local gt, ut, bt, att = 14, 27, 1, 40

----------------------------------------------------------------- ground walls
-- z=-20: front rooms (-) | front corridor (+)
-- stair-core openings (barriers only, no door leaf) are 5.8 wide: at 4.5-5.4 the navmesh would not connect the corridor
W(GW, "x", -20, -52, -38.5, g, gt, RC.stair, RC.corr, { { c = -48.75, w = 5.8 } }, nil, CR)
W(GW, "x", -20, -38.5, -14, g, gt, RC.office, RC.corr, { { c = -22, w = 4.5 }, { c = -32, w = 5, h = 8.5, casing = C.Chrome } }, nil, CR)
W(GW, "x", -20, -14, 14, g, gt, RC.lobby, RC.corr, { { c = 0, w = 8, h = 9 } }, { wain = true, trimColor = C.WoodLight }, CR)
W(GW, "x", -20, 14, 32, g, gt, RC.nurse, RC.corr, { { c = 18, w = 4.5 }, { c = 26.5, w = 6, sill = 3.2, h = 7.6, trim = false } }, nil, CR)
W(GW, "x", -20, 32, 52, g, gt, RC.lounge, RC.corr, { { c = 42, w = 4.5 } }, nil, CR)
-- z=-13 and z=13 (cores)
W(GW, "x", -13, -45, -3.5, g, gt, RC.corr, RC.rec, { { c = -24, w = 6, h = 9 } }, CR, nil)
W(GW, "x", -13, 3.5, 45, g, gt, RC.corr, RC.dining, { { c = 24, w = 6, h = 9 } }, CR, nil)
W(GW, "x", 13, -45, -3.5, g, gt, RC.rec, RC.corr, { { c = -24, w = 6, h = 9 } }, nil, CR)
W(GW, "x", 13, 3.5, 45, g, gt, RC.dining, RC.corr, { { c = 24, w = 6, h = 9 } }, nil, CR)
-- z=20: back corridor (-) | back rooms (+)
W(GW, "x", 20, -52, -38.5, g, gt, RC.corr, RC.stair, { { c = -48.75, w = 5.8 } }, CR, nil)
W(GW, "x", 20, -38.5, -14, g, gt, RC.corr, RC.activity, { { c = -26, w = 4.5 } }, CR, nil)
W(GW, "x", 20, -14, 0, g, gt, RC.corr, RC.wash, { { c = -8, w = 4.5 } }, CR, TL) -- c=-8: at -7 the navmesh would not pass the door from the east
W(GW, "x", 20, 0, 14, g, gt, RC.corr, RC.linen, { { c = 7, w = 4.5 } }, CR, nil)
W(GW, "x", 20, 14, 52, g, gt, RC.corr, RC.kitchen, { { c = 22, w = 4.5 }, { c = 44, w = 5, h = 8.5 } }, CR, TL)
-- x walls of the cores
W(GW, "z", -45, -13, 13, g, gt, RC.corr, RC.rec, { { c = 0, w = 4.5 } }, CR, nil)
W(GW, "z", -3.5, -13, 13, g, gt, RC.rec, RC.corr, { { c = -6, w = 5, h = 9 } }, nil, CR)
W(GW, "z", 3.5, -13, 13, g, gt, RC.corr, RC.dining, { { c = 6, w = 5, h = 9 } }, CR, nil)
W(GW, "z", 45, -13, 13, g, gt, RC.dining, RC.corr, { { c = 0, w = 4.5 } }, nil, CR)
-- front / back row partitions
W(GW, "z", -38.5, -40, -20, g, gt, RC.stair, RC.office)
W(GW, "z", -14, -40, -20, g, gt, RC.office, RC.lobby, nil, nil, { wain = true, trimColor = C.WoodLight })
W(GW, "z", 14, -40, -20, g, gt, RC.lobby, RC.nurse, nil, { wain = true, trimColor = C.WoodLight }, nil)
W(GW, "z", 32, -40, -20, g, gt, RC.nurse, RC.lounge, { { c = -30, w = 4.5, h = 8.5 } })
W(GW, "z", -38.5, 20, 40, g, gt, RC.stair, RC.activity)
W(GW, "z", -14, 20, 40, g, gt, RC.activity, RC.wash, nil, nil, TL)
W(GW, "z", 0, 20, 40, g, gt, RC.wash, RC.linen, nil, TL, nil)
W(GW, "z", 14, 20, 40, g, gt, RC.linen, RC.kitchen, nil, nil, TL)

----------------------------------------------------------------- upstairs walls
W(UW, "x", -20, -52, -38.5, u, ut, RC.stair, RC.ucorr, { { c = -42, w = 5, h = 9 } }, nil, CR)
W(UW, "x", -20, -38.5, -19, u, ut, RC.b1, RC.ucorr, { { c = -29, w = 4.5 }, { c = -35, w = 5, h = 8.5, casing = C.Chrome } }, nil, CR)
W(UW, "x", -20, -19, 0, u, ut, RC.b2, RC.ucorr, { { c = -10, w = 4.5 } }, nil, CR)
W(UW, "x", -20, 0, 19, u, ut, RC.b3, RC.ucorr, { { c = 10, w = 4.5 } }, nil, CR)
W(UW, "x", -20, 19, 38.5, u, ut, RC.b4, RC.ucorr, { { c = 29, w = 4.5 } }, nil, CR)
W(UW, "x", -20, 38.5, 52, u, ut, RC.stair, RC.ucorr, { { c = 48.75, w = 5.8 } }, nil, CR)
W(UW, "x", -13, -45, -3.5, u, ut, RC.ucorr, RC.ward, { { c = -24, w = 6, h = 9 } }, CR, nil)
W(UW, "x", -13, 3.5, 16, u, ut, RC.ucorr, RC.ulinen, { { c = 10, w = 4.5 } }, CR, nil)
W(UW, "x", -13, 16, 45, u, ut, RC.ucorr, RC.double, { { c = 30, w = 4.5 } }, CR, nil)
W(UW, "x", 13, -45, -3.5, u, ut, RC.ward, RC.ucorr, { { c = -24, w = 6, h = 9 } }, nil, CR)
W(UW, "x", 13, 3.5, 16, u, ut, RC.ulinen, RC.ucorr, nil, nil, CR)
W(UW, "x", 13, 16, 45, u, ut, RC.double, RC.ucorr, nil, nil, CR)
W(UW, "x", 20, -52, -30, u, ut, RC.ucorr, RC.b5, { { c = -41, w = 4.5 } }, CR, nil)
W(UW, "x", 20, -30, -8, u, ut, RC.ucorr, RC.b6, { { c = -19, w = 4.5 } }, CR, nil)
W(UW, "x", 20, -8, 8, u, ut, RC.ucorr, RC.bath, { { c = 0, w = 4.5 } }, CR, TL)
W(UW, "x", 20, 8, 52, u, ut, RC.ucorr, RC.sun, { { c = 30, w = 8, h = 9 } }, CR, nil)
W(UW, "z", -45, -13, 13, u, ut, RC.ucorr, RC.ward, { { c = 0, w = 5, h = 9 } }, CR, nil)
W(UW, "z", -3.5, -13, 13, u, ut, RC.ward, RC.ucorr, nil, nil, CR)
W(UW, "z", 3.5, -13, 13, u, ut, RC.ucorr, RC.ulinen, nil, CR, nil)
W(UW, "z", 16, -13, 13, u, ut, RC.ulinen, RC.double)
W(UW, "z", 45, -13, 13, u, ut, RC.double, RC.ucorr, nil, nil, CR)
W(UW, "z", -38.5, -40, -20, u, ut, RC.stair, RC.b1)
W(UW, "z", -19, -40, -20, u, ut, RC.b1, RC.b2)
W(UW, "z", 0, -40, -20, u, ut, RC.b2, RC.b3)
W(UW, "z", 19, -40, -20, u, ut, RC.b3, RC.b4)
W(UW, "z", 38.5, -40, -20, u, ut, RC.b4, RC.stair)
W(UW, "z", -30, 20, 40, u, ut, RC.b5, RC.b6)
W(UW, "z", -8, 20, 40, u, ut, RC.b6, RC.bath, nil, nil, TL)
W(UW, "z", 8, 20, 40, u, ut, RC.bath, RC.sun, nil, TL, nil)

----------------------------------------------------------------- basement shell + walls
local BS = B.F("Shell", B.F("Basement"))
B.box(BS, "BasementWall", -53, -12, -1, -51.9, 1, 41, RC.base, M.Concrete, { solid = true })
B.box(BS, "BasementWall", 0, -12, -1, 1, 1, 41, RC.base, M.Concrete, { solid = true })
B.box(BS, "BasementWall", -51.9, -12, -1, 0, 1, 0, RC.base, M.Concrete, { solid = true })
B.box(BS, "BasementWall", -51.9, -12, 39.9, 0, 1, 41, RC.base, M.Concrete, { solid = true })
W(BW, "x", 13, -51.9, -24, bs, bt, RC.base, RC.base, { { c = -38, w = 6, h = 9 } }, CON, CON)
W(BW, "x", 13, -24, 0, bs, bt, RC.boiler, RC.base, { { c = -12, w = 4.5 } }, CON, CON)
W(BW, "x", 20, -51.9, -38.5, bs, bt, RC.base, RC.base, { { c = -41.75, w = 6.5, h = 9, trim = false } }, CON, CON)
W(BW, "x", 20, -38.5, -14, bs, bt, RC.base, RC.base, { { c = -30, w = 4.5 } }, CON, CON)
W(BW, "x", 20, -14, 0, bs, bt, RC.base, RC.base, { { c = -7, w = 5, h = 8.5 } }, CON, CON)
W(BW, "z", -24, 0, 13, bs, bt, RC.base, RC.boiler, { { c = 6, w = 4.5, h = 8.5 } }, CON, CON)
W(BW, "z", -38.5, 20, 39.9, bs, bt, RC.base, RC.base, nil, CON, CON)
W(BW, "z", -14, 20, 39.9, bs, bt, RC.base, RC.base, { { c = 34, w = 4.5, h = 8.5 } }, CON, CON)

----------------------------------------------------------------- attic walls
W(AW, "x", -20, 14, 38.5, at, att, RC.att, RC.att, { { c = 20, w = 5, h = 9 }, { c = 33, w = 5, h = 9 } }, nil, CR)
W(AW, "x", -20, 38.5, 52, at, att, RC.stair, RC.att, { { c = 42, w = 5, h = 9 } }, nil, CR)
W(AW, "x", -13, 14, 33, at, att, RC.att, RC.matron, { { c = 24, w = 4.5 } }, CR, nil)
W(AW, "x", -13, 33, 52, at, att, RC.att, RC.records, { { c = 44, w = 4.5 } }, CR, nil)
W(AW, "z", 33, -13, 0, at, att, RC.matron, RC.records, { { c = -6, w = 4.5, h = 8.5 } })
W(AW, "z", 38.5, -40, -20, at, att, RC.att, RC.stair)

----------------------------------------------------------------- doors (23)
local function D(name, axis, fixed, c, y0, area, sq, lk, col, hs, o)
	return B.door(IA, name, axis, fixed, c, y0, area, sq, lk, col, hs, 4.5, o)
end
local fd = B.door(root, "FrontDoor", "x", -40.5, 0, g, "Ground", false, true, C.PMint:Lerp(C.Ink, 0.15), 1, 4.5, { window = true, label = "SUNNY PINES" })
B.casing(B.F("Walls", B.F("Ground")), "x", -40.5, 0, 4.5, g, 8, 1, C.Paper)
local _ = fd
D("Door_Office", "x", -20, -22, g, "Ground", true, true, C.PBlue:Lerp(C.Ink, 0.2), 1, { label = "MANAGER", window = true })
D("Door_Nurse", "x", -20, 18, g, "Ground", false, true, C.PMint:Lerp(C.Ink, 0.2), -1, { label = "NURSE", window = true })
D("Door_Lounge", "x", -20, 42, g, "Ground", true, false, C.PLilac:Lerp(C.Ink, 0.2), 1, { label = "QUIET LOUNGE" })
D("Door_RecWest", "z", -45, 0, g, "Ground", true, false, C.PPeach:Lerp(C.Ink, 0.2), 1, { window = true })
D("Door_DiningEast", "z", 45, 0, g, "Ground", false, false, C.PPink:Lerp(C.Ink, 0.2), -1, { window = true })
D("Door_Activity", "x", 20, -26, g, "Ground", true, false, C.PLemon:Lerp(C.Ink, 0.25), 1, { label = "ACTIVITIES" })
D("Door_Washroom", "x", 20, -8, g, "Ground", false, true, C.PMint:Lerp(C.Ink, 0.2), -1, { label = "WC" })
D("Door_Linen", "x", 20, 7, g, "Ground", true, true, C.PBlue:Lerp(C.Ink, 0.2), 1, { label = "LINEN" })
D("Door_Kitchen", "x", 20, 22, g, "Ground", false, false, C.Chrome:Lerp(C.Ink, 0.1), 1, { label = "KITCHEN", window = true, mat = M.Metal })
D("Door_Bedroom1", "x", -20, -29, u, "Upstairs", true, true, C.PPink:Lerp(C.Ink, 0.2), -1, { label = "ROOM 1" })
D("Door_Bedroom2", "x", -20, -10, u, "Upstairs", false, false, C.PBlue:Lerp(C.Ink, 0.2), 1, { label = "ROOM 2" })
D("Door_Bedroom3", "x", -20, 10, u, "Upstairs", true, false, C.PLilac:Lerp(C.Ink, 0.2), -1, { label = "ROOM 3" })
D("Door_Bedroom4", "x", -20, 29, u, "Upstairs", false, true, C.PPeach:Lerp(C.Ink, 0.2), 1, { label = "ROOM 4" })
D("Door_UpperLinen", "x", -13, 10, u, "Upstairs", true, false, C.PBlue:Lerp(C.Ink, 0.25), 1, { label = "LINEN" })
D("Door_Double", "x", -13, 30, u, "Upstairs", false, true, C.PLemon:Lerp(C.Ink, 0.25), -1, { label = "ROOM 7" })
D("Door_Bedroom5", "x", 20, -41, u, "Upstairs", true, false, C.PBlue:Lerp(C.Ink, 0.2), 1, { label = "ROOM 5" })
D("Door_Bedroom6", "x", 20, -19, u, "Upstairs", false, true, C.PPink:Lerp(C.Ink, 0.2), -1, { label = "ROOM 6" })
D("Door_Bathroom", "x", 20, 0, u, "Upstairs", true, false, C.PMint:Lerp(C.Ink, 0.2), 1, { label = "BATHROOM" })
D("Door_Boiler", "x", 13, -12, bs, "Basement", true, true, C.Blood:Lerp(C.Ink, 0.3), 1, { label = "BOILER", mat = M.Metal })
D("Door_Storage", "x", 20, -30, bs, "Basement", true, false, C.Metal:Lerp(C.Ink, 0.2), -1, { label = "STORAGE", mat = M.Metal })
D("Door_MatronOffice", "x", -13, 24, at, "Attic", true, true, C.WoodMid, 1, { label = "MATRON", window = true })
D("Door_Records", "x", -13, 44, at, "Attic", true, false, C.WoodMid:Lerp(C.PGreen, 0.2), -1, { label = "RECORDS" })

----------------------------------------------------------------- out-of-order lifts (fill the lift gaps)
local function lift(par, c, y0, floorLabel)
	local m = B.model(par, "Lift_OutOfOrder")
	B.box(m, "LiftDoors", c - 2.5, y0, -20.25, c + 2.5, y0 + 8.5, -19.75, C.Chrome, M.Metal, { solid = true })
	B.box(m, "Seam", c - 0.04, y0 + 0.05, -19.77, c + 0.04, y0 + 8.45, -19.7, C.Ink, M.Metal, { small = true })
	for _, sx in { -1, 1 } do
		local t = B.part(m, "Tape", V(6.2, 0.45, 0.04), CFrame.new(c, y0 + 4.2, -19.66) * CFrame.Angles(0, 0, math.rad(sx * 34)), C.Mustard, M.SmoothPlastic, { small = true })
		t.CastShadow = false
	end
	local s = B.box(m, "Sign", c - 1.6, y0 + 5.2, -19.64, c + 1.6, y0 + 6.6, -19.6, C.Paper, M.SmoothPlastic, { small = true })
	B.text(s, Enum.NormalId.Back, "OUT OF ORDER\nsorry! - Mgmt", C.Blood, Enum.Font.PatrickHand)
	local ind = B.box(m, "Indicator", c - 1, y0 + 9, -19.72, c + 1, y0 + 9.5, -19.66, C.Ink, M.SmoothPlastic, { small = true })
	B.text(ind, Enum.NormalId.Back, floorLabel, Color3.fromRGB(255, 120, 80), Enum.Font.Arcade, { light = 0 })
	B.box(m, "CallButton", c + 3.1, y0 + 3.6, -19.74, c + 3.6, y0 + 4.6, -19.66, C.Chrome, M.Metal, { small = true })
end
lift(B.F("Ground"), -32, g, "G")
lift(B.F("Upstairs"), -35, u, "1")

----------------------------------------------------------------- stair cores
local SC = B.F("Stairs", B.F("Upstairs"))
local stc = C.Concrete:Lerp(C.Paper, 0.3)
B.stairs(SC, "MainFlight1", -52, -46, -23, 2, -36, 8.5, 10, stc, { floorY = 2 })
B.box(SC, "MainLanding", -52, 2, -40, -38.75, 8.5, -36, stc, M.Concrete, { solid = true })
B.stairs(SC, "MainFlight2", -45, -38.75, -36, 8.5, -23, 15, 10, stc, { floorY = 2 })
-- dividers: the lower part stops 1.5 short of the entry strip and 2.6 short of the landing (both flights are level
-- there); full-length dividers pinched the navmesh at the stair door and on the landing
B.box(SC, "MainDivider", -46, 2, -33.4, -45, 18.5, -24.5, RC.stair, M.Plaster, { solid = true })
B.box(SC, "MainDividerTop", -46, 15, -24.5, -45, 18.5, -23, RC.stair, M.Plaster, { solid = true })
B.box(SC, "DividerCap", -46.1, 18.5, -33.5, -44.9, 18.7, -22.9, C.WoodLight, M.Wood, { small = true })
B.rail(SC, V(-51.8, 15, -22.8), V(-46.1, 15, -22.8), 3.4, C.Chrome)
local SS = B.F("Stairs", B.F("Basement"))
B.stairs(SS, "ServiceFlight1", -52, -46, 36, -4.5, 23, 2, 10, stc, { floorY = -11 })
B.box(SS, "ServiceLanding", -52, -11, 36, -38.75, -4.5, 40, stc, M.Concrete, { solid = true })
B.stairs(SS, "ServiceFlight2", -45, -38.75, 23, -11, 36, -4.5, 10, stc, { floorY = -11 })
B.box(SS, "ServiceDivider", -46, -11, 23, -45, 5.5, 33.4, RC.stair, M.Plaster, { solid = true })
B.box(SS, "DividerCap", -46.1, 5.5, 22.9, -44.9, 5.7, 33.5, C.WoodLight, M.Wood, { small = true })
B.rail(SS, V(-44.9, 2, 22.8), V(-38.95, 2, 22.8), 3.4, C.Chrome)
local SA = B.F("Stairs", B.F("Attic"))
B.stairs(SA, "WardFlight1", 46, 52, -23, 15, -36, 21.5, 10, stc, { floorY = 15 })
B.box(SA, "WardLanding", 38.75, 15, -40, 52, 21.5, -36, stc, M.Concrete, { solid = true })
B.stairs(SA, "WardFlight2", 38.75, 45, -36, 21.5, -23, 28, 10, stc, { floorY = 15 })
B.box(SA, "WardDivider", 45, 15, -33.4, 46, 31.5, -24.5, RC.stair, M.Plaster, { solid = true })
B.box(SA, "WardDividerTop", 45, 28, -24.5, 46, 31.5, -23, RC.stair, M.Plaster, { solid = true })
B.box(SA, "DividerCap", 44.9, 31.5, -33.5, 46.1, 31.7, -22.9, C.WoodLight, M.Wood, { small = true })
B.rail(SA, V(46.1, 28, -22.8), V(51.8, 28, -22.8), 3.4, C.Chrome)

----------------------------------------------------------------- barriers
local BR = B.F("Barriers")
local function barrierDoor(name, area, axis, fixed, c, y0, col, txt, o)
	o = o or {}
	local m = B.model(BR, name)
	local w = 5.8
	local x0, x1 = c - w / 2, c + w / 2
	B.box(m, "Leaf", x0 + 0.05, y0 + 0.03, fixed - 0.15, x1 - 0.05, y0 + 7.93, fixed + 0.15, col, o.mat or M.Wood, { collide = false, query = false, tr = o.tr or 0 })
	B.box(m, "Collider", x0, y0, fixed - 0.4, x1, y0 + 8, fixed + 0.4, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	for _, side in { -1, 1 } do
		local zf = fixed + side * 0.2
		for i, a in { 26, -26 } do
			local t = B.part(m, "Tape", V(6.8, 0.4, 0.04), CFrame.new(c, y0 + 3.2 + i * 1.4, zf) * CFrame.Angles(0, 0, math.rad(a)), o.tape or C.Mustard, M.SmoothPlastic, { small = true })
			t.CastShadow = false
		end
		local s = B.part(m, "Sign", V(2.8, 1.3, 0.04), CFrame.new(c, y0 + 5.6, fixed + side * 0.24), C.Paper, M.SmoothPlastic, { small = true })
		B.text(s, if side < 0 then Enum.NormalId.Front else Enum.NormalId.Back, txt, C.Blood, Enum.Font.PatrickHand)
	end
	if o.chain then
		for _, side in { -1, 1 } do
			B.part(m, "Chain", V(5.8, 0.18, 0.1), CFrame.new(c, y0 + 3.9, fixed + side * 0.28) * CFrame.Angles(0, 0, math.rad(9)), C.Metal, M.Metal, { small = true })
			B.part(m, "Padlock", V(0.6, 0.75, 0.3), CFrame.new(c + 0.4, y0 + 3.6, fixed + side * 0.36), C.Brass, M.Metal, { small = true })
		end
	end
	B.attrs(m, { Area = area })
	return m
end
barrierDoor("Barrier_Upstairs", "Upstairs", "x", -20, -48.75, g, C.PCream:Lerp(C.Ink, 0.2), "STAIRS\nOUT OF ORDER")
barrierDoor("Barrier_Basement", "Basement", "x", 20, -48.75, g, C.Metal, "STAFF ONLY\nboiler room", { mat = M.DiamondPlate, tr = 0.35, chain = true, tape = C.Blood:Lerp(C.Paper, 0.3) })
barrierDoor("Barrier_Attic", "Attic", "x", -20, 48.75, u, C.WoodDark, "MATRON'S WARD\nCLOSED 1979", { chain = true })

----------------------------------------------------------------- rooms
for _, r in B.RM do
	B.room(r[1], r[2], r[3], r[4], r[8], r[5], r[6], r[9], r[7])
end
return "walls ok, parts=" .. B.count(root)
