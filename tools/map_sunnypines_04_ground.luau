-- Sunny Pines ground floor dressing + contract items: lobby, office, nurse station (FuseBox), lounge,
-- Rec Room (GrandmaChair + GrandmaSleepSpot), dining hall, activity room, washroom (Bathroom node),
-- linen store, kitchen, corridors (lamps, creaky tiles, nodes).
local B = _G.SPB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local SM = { small = true }
local root = B.root()
local GR = B.F("Ground")
local G = "Ground"
local y = 2
local function F(n) return B.F(n, GR) end
local function loot(d, x, yy, z) B.loot(G, d, V(x, yy, z)) end

----------------------------------------------------------------- corridors
local CO = F("Corridors")
for _, p in { { -35, -16.5 }, { 0, -16.5 }, { 35, -16.5 }, { -25, 16.5 }, { 25, 16.5 } } do
	B.lamp(CO, "fluoro", CFrame.new(p[1], 14, p[2]), G, { len = 4 })
end
for _, p in { { -30, -16.5, 0 }, { 8, -16.5, 0 }, { 30, -16.5, 0 }, { -20, 16.5, 0 }, { 15, 16.5, 0 }, { -48.5, -6, 0 }, { 48.5, 6, 0 } } do
	B.creak(p[1], y, p[2], p[3])
end
for _, p in { { -42, -16.5 }, { 20, -16.5 }, { 46, -16.5 }, { -48.5, 8 }, { 0, -8 }, { 48.5, -8 }, { -40, 16.5 }, { 5, 16.5 }, { 40, 16.5 } } do
	B.node(G, p[1], y, p[2])
end
-- exit signs over the corridor ends and the entrance
B.lamp(CO, "exit", cf(0, 11.2, -39.99, "+z"), G)
-- corridor wall art + notices
B.picture(CO, cf(-14, 8.2, -13.25, "-z"), 3.4, 2.6, { canvas = C.PBlue, scene = C.PGreen, frame = C.WoodLight })
B.picture(CO, cf(30, 8.2, -13.25, "-z"), 3.4, 2.6, { canvas = C.PPeach, scene = C.PGreen:Lerp(C.Ink, 0.2), frame = C.WoodLight })
B.picture(CO, cf(-10, 8.2, 13.25, "+z"), 3.4, 2.6, { canvas = C.PLilac, scene = C.PMint, frame = C.WoodLight })
B.sign(CO, cf(-27, 8.5, -19.75, "+z"), 3.6, 2.4, "NIGHT RULES\n1. Lights out at 9\n2. NO wandering\n3. Matron is watching", C.Paper, C.Ink, Enum.Font.PatrickHand)
B.sign(CO, cf(-45.25, 8.2, 8, "-x"), 3, 1.6, "REC ROOM", C.PMint, C.Ink, Enum.Font.FredokaOne)
B.plant(CO, cf(50.3, y, -18.2), 0.9)

----------------------------------------------------------------- reception lobby
local LO = F("Lobby")
B.lamp(LO, "fluoro", CFrame.new(0, 14, -30), G, { len = 5, bright = 1.2 })
B.counter(LO, cf(8.5, y, -30.75, "-z"), 7, C.PPeach:Lerp(C.Ink, 0.1), C.Paper, G, 1, { nil, "Drawer" }, { topMat = M.Marble, name = "ReceptionDesk" })
loot(1, 6.2, 5.5, -30.75)
loot(1, 9, 5.5, -30.5)
local bell = B.cyl(LO, "DeskBell", cf(7.6, 5.5, -31.4), 0.5, 0.35, V(0, 0.175, 0), C.Brass, M.Metal, SM, true)
local _ = bell
B.sign(LO, cf(13.75, 9.5, -30.75, "-x"), 5, 1.2, "RECEPTION ~ please ring", C.PMint, C.Ink, Enum.Font.FredokaOne)
B.wheelchair(LO, cf(11.5, y, -36.5, "-x"))
B.fishtank(LO, cf(-12.5, y, -30, "+x"), G)
B.sofa(LO, cf(-8.5, y, -36.9, "+z"), 7, C.PMint:Lerp(C.Ink, 0.2))
B.table(LO, cf(-8.5, y, -32.2), 4, 2, 1.6, C.WoodLight, { leg = C.WoodDark })
loot(1, -9.5, 3.6, -32.2)
B.vase(LO, cf(-7.2, 3.6, -32.2), C.PBlue, 0.8)
B.plant(LO, cf(12, y, -22.5), 1)
B.plant(LO, cf(-3.6, y, -38.3), 0.9)
B.booth(LO, cf(-11.4, y, -23.4, "+x"), G)
B.rug(LO, 0, y, -33, 5, 3, C.PMint:Lerp(C.Ink, 0.4))
B.node(G, 0, y, -28)
loot(1, -10.5, 4.0, -36.5)
B.picture(LO, cf(13.75, 8.5, -24, "-x"), 3, 3.6, { portrait = true, canvas = C.PBlue, clothes = C.Bruise, name = "Founder" })

----------------------------------------------------------------- manager's office
local OF = F("Office")
for i, z in { -36, -33.8, -31.6 } do
	B.filing(OF, cf(-37.0, y, z, "+x"), 4, G, 1, if i == 1 then 2 else nil)
end
B.table(OF, cf(-26, y, -32, "+z"), 6, 3, 3.2, C.WoodMid, { leg = C.WoodDark, name = "Desk" })
B.chair(OF, cf(-26, y, -34.4, "+z"), C.Bruise)
loot(1, -27.6, 5.2, -32)
B.shelf(OF, cf(-15.2, y, -30, "-x"), 5, 8, C.WoodMid, { seed = 2 })
loot(1, -15.2, 4.22, -29.8)
B.picture(OF, cf(-38.25, 10, -33.8, "+x"), 3, 3.4, { portrait = true, canvas = C.Night, clothes = C.Ink, hair = C.WoodDark })
B.plant(OF, cf(-17, y, -38), 0.9)
B.node(G, -26, y, -26)
loot(1, -37, 7.4, -36)

----------------------------------------------------------------- nurse station (FuseBox)
local NU = F("NurseStation")
B.counter(NU, cf(26.5, y, -21.8, "-z"), 6, C.PMint:Lerp(C.Ink, 0.1), C.Paper, G, 1, { "Drawer" }, { name = "HatchCounter" })
loot(1, 25, 5.5, -21.8)
B.crockery(NU, cf(28.2, 5.5, -21.8))
B.lockers(NU, cf(15.4, y, -31, "+x"), 3, G, 1, { 1, 3 }, C.Paper:Lerp(C.PMint, 0.3))
B.fridge(NU, cf(16.1, y, -37, "+x"), G, 1, { w = 2.6, note = "INSULIN ONLY", name = "DrugFridge" })
local fb = B.part(root, "FuseBox", V(1.8, 2.4, 0.5), cf(14.5, 7.2, -25, "+x"), C.Metal:Lerp(C.PMint, 0.2), M.Metal, { collide = true, query = true })
B.text(fb, Enum.NormalId.Front, "FUSES", C.Blood, Enum.Font.FredokaOne)
B.table(NU, cf(22, y, -31, "-z"), 5, 3, 3.2, C.PPeach, { name = "NurseDesk" })
B.chair(NU, cf(22, y, -28.6, "-z"), C.PMint:Lerp(C.Ink, 0.2))
loot(1, 23.5, 5.2, -31)
B.bedside(NU, cf(25.6, y, -31, "-z"), C.PPeach, G, 1, false)
B.wardrobe(NU, cf(29.7, y, -37, "-x"), C.Paper:Lerp(C.PMint, 0.2), G, "Closet", { label = "SUPPLIES", louvre = true, name = "SupplyCloset" })
B.sign(NU, cf(14.25, 10.5, -31, "+x"), 4.4, 1.6, "Night shift:\nNurse Pat  (on break)", C.Paper, C.Ink, Enum.Font.PatrickHand)
B.lamp(NU, "fluoro", CFrame.new(22, 14, -34), G, { len = 3.5 })
B.node(G, 21, y, -25.5)

----------------------------------------------------------------- quiet lounge
local QL = F("QuietLounge")
B.armchair(QL, cf(37.5, y, -30, "+x"), C.PLilac:Lerp(C.Ink, 0.2), "Armchair", { w = 4.2, d = 4 })
B.armchair(QL, cf(46.5, y, -30, "-x"), C.PPink:Lerp(C.Ink, 0.2), "Armchair", { w = 4.2, d = 4 })
B.table(QL, cf(42, y, -30), 3, 3, 2.6, C.WoodLight, { leg = C.WoodDark, cloth = C.Paper })
loot(1, 41.5, 2 + 2.64, -29.4)
B.vase(QL, cf(42.7, 4.64, -30.8), C.PPink, 0.8)
B.shelf(QL, cf(51.0, y, -37, "-x"), 4, 8, C.WoodMid, { seed = 4 })
loot(1, 51.0, 6.07, -36.9)
B.wardrobe(QL, cf(49.9, y, -23.2, "-x"), C.WoodMid, G, "Closet", { label = "COATS", name = "CoatCupboard" })
B.table(QL, cf(34.5, y, -37), 2, 2, 2.6, C.WoodMid, { leg = C.WoodDark })
B.lamp(QL, "table", cf(34.5, 4.6, -37), G, { shade = C.PPink })
B.bedside(QL, cf(33.4, y, -24, "+x"), C.WoodMid, G, 1, false)
loot(1, 33.4, 4.6, -24.4)
B.picture(QL, cf(32.25, 8.5, -36, "+x"), 4, 3, { canvas = C.PBlue:Lerp(C.Ink, 0.2), scene = C.PGreen:Lerp(C.Ink, 0.3) })
B.rug(QL, 42, y, -30, 12, 7, C.PLilac:Lerp(C.Ink, 0.3))
B.node(G, 42, y, -25.3)

----------------------------------------------------------------- rec room (Grandma)
local RR = F("RecRoom")
local chairCF = cf(-30, y, -5.5, "-x")
B.armchair(root, chairCF, C.Rose:Lerp(C.Ink, 0.15), "GrandmaChair", { w = 5, d = 4.8, footrest = true, doily = true, throw = C.Mustard:Lerp(C.Ink, 0.15) })
B.part(root, "GrandmaSleepSpot", V(2, 2, 1), chairCF * CFrame.new(0, 3.5, 0.2), C.Paper, M.SmoothPlastic, { inv = true })
B.tv(RR, cf(-38, y, -5.5, "+x"), G)
B.table(RR, cf(-29.5, y, -9.8), 3, 2, 2.6, C.WoodMid, { leg = C.WoodDark, name = "SideTable" })
B.lamp(RR, "table", cf(-28.6, 4.6, -9.8), G, { shade = C.Rose })
B.prize(G, V(-30.4, 4.6, -9.8))
B.sofa(RR, cf(-22, y, -5.5, "-x"), 7, C.PPeach:Lerp(C.Ink, 0.3))
loot(3, -22.4, 4.0, -3.2)
for i, t in { { -36, 7 }, { -14, 7 } } do
	B.table(RR, cf(t[1], y, t[2]), 4, 4, 2.8, C.PLemon:Lerp(C.Ink, 0.2), { name = "CardTable", cloth = C.PMint:Lerp(C.Ink, 0.3) })
	B.chair(RR, cf(t[1], y, t[2] - 2.9, "+z"), C.PPink)
	B.chair(RR, cf(t[1], y, t[2] + 2.9, "-z"), C.PBlue)
	loot(3, t[1] - 0.8, 2.84 + 2, t[2] + 0.6)
end
B.crockery(RR, cf(-13.2, 4.84, 6.4))
local bingo = B.sign(RR, cf(-36, 8.3, 12.75, "-z"), 6, 3.6, "B I N G O\n7  22  41  56  70\n13  29  38  52  66", C.PLemon, C.Blood, Enum.Font.FredokaOne)
local _ = bingo
B.sign(RR, cf(-24, 12.4, -12.75, "+z"), 28, 1.3, "HAPPY 100th BIRTHDAY, DOROTHY!", C.PPink, C.Blood:Lerp(C.Ink, 0.2), Enum.Font.LuckiestGuy)
for i, x in { -38.95, -9.9, -8.7, -7.5 } do
	B.ball(RR, "Balloon", cf(x, 12.2 + (i % 2) * 0.6, -12.1), 1.1, V(0, 0, 0), if i % 2 == 0 then C.PPink else C.Mustard, M.SmoothPlastic, SM)
end
B.counter(RR, cf(-14, y, -11.1, "+z"), 5, C.WoodMid, C.WoodDark, G, 3, { "Cabinet", nil }, { topMat = M.Wood, name = "Sideboard" })
loot(3, -14.8, 5.5, -11.1)
B.cubicle(RR, cf(-42, y, -10, "+z"), G, 12, { name = "HairdresserCubicle", col = C.PPink:Lerp(C.Paper, 0.3) })
do
	local ch = B.model(RR, "GamesChest")
	local b = cf(-43.4, y, 5, "+x")
	B.rp(ch, "Body", b, V(3.6, 1.6, 2.2), V(0, 0.8, 0), C.PBlue:Lerp(C.Ink, 0.2), M.Wood)
	local lid = B.rp(ch, "Lid", b, V(3.7, 0.5, 2.3), V(0, 1.85, 0), C.PBlue:Lerp(C.Ink, 0.3), M.Wood)
	B.searchable(lid, "ToyChest", G, 3)
	local lab = B.rp(ch, "Label", b, V(2.2, 0.6, 0.04), V(0, 1.0, -1.12), C.Paper, M.SmoothPlastic, SM)
	B.text(lab, Enum.NormalId.Front, "GAMES", C.Ink, Enum.Font.FredokaOne)
end
B.wheelchair(RR, cf(-6.5, y, 10.5, "-x"))
B.plant(RR, cf(-5.6, y, -11.2), 1)
B.plant(RR, cf(-43.5, y, 11.2), 0.9)
B.lamp(RR, "fluoro", CFrame.new(-25, 14, 7), G, { len = 4, bright = 0.9 })
B.rug(RR, -32.5, y, -5.5, 11, 6.6, C.Rose:Lerp(C.Ink, 0.45), C.Mustard:Lerp(C.Ink, 0.5))
for _, p in { { -26, 1.5 }, { -33, 1.5 } } do B.creak(p[1], y, p[2]) end
B.node(G, -24, y, 2)
B.node(G, -12, y, -2)

----------------------------------------------------------------- dining hall
local DH = F("DiningHall")
for i, t in { { 12, -6 }, { 12, 6 }, { 35, -5 }, { 35, 5 } } do
	B.table(DH, cf(t[1], y, t[2]), 6, 3.5, 3, C.WoodLight, { cloth = if i % 2 == 0 then C.PPink else C.PMint, name = "DiningTable" })
	B.chair(DH, cf(t[1] - 1.5, y, t[2] - 2.75, "+z"), C.PBlue)
	B.chair(DH, cf(t[1] + 1.5, y, t[2] + 2.75, "-z"), C.PBlue)
	loot(2, t[1] + 1.2, 5.04, t[2])
end
B.counter(DH, cf(38, y, -11.1, "+z"), 7, C.PPink:Lerp(C.Ink, 0.2), C.Chrome, G, 2, { nil, "Drawer", nil }, { name = "ServingCounter" })
B.crockery(DH, cf(36, 5.5, -11.1))
loot(2, 40, 5.5, -11.1)
B.sign(DH, cf(3.75, 8.2, -6, "+x"), 4, 3, "TODAY\nMince & Mash\nPink Jelly\n(no seconds)", C.Night, C.Paper, Enum.Font.PatrickHand)
B.lamp(DH, "fluoro", CFrame.new(24, 14, 0), G, { len = 5 })
B.plant(DH, cf(43.5, y, 11.3), 0.9)
B.creak(27, y, -9)
B.node(G, 24, y, 0)
B.node(G, 8, y, 0)
loot(2, 10.2, 5.04, -6)

----------------------------------------------------------------- activity room
local AC = F("ActivityRoom")
B.table(AC, cf(-26, y, 31), 8, 4, 3, C.PLemon:Lerp(C.Ink, 0.15), { name = "CraftTable" })
for _, x in { -29, -23 } do B.chair(AC, cf(x, y, 28.1, "+z"), C.PMint) end
B.chair(AC, cf(-26, y, 33.9, "-z"), C.PPink)
loot(2, -28, 5, 31)
loot(2, -23.5, 5, 31.4)
B.counter(AC, cf(-26, y, 38.4, "-z"), 10, C.PMint:Lerp(C.Ink, 0.15), C.Paper, G, 2, { "Cabinet", nil, nil, "Drawer" }, { name = "CraftCounter" })
loot(2, -30, 5.5, 38.4)
do
	local e = B.model(AC, "Easel")
	local b = cf(-17, y, 34, 200)
	for _, sx in { -1, 1 } do B.rp(e, "Leg", b, V(0.2, 6, 0.2), V(sx * 1, 3, 0), C.WoodLight, M.Wood, SM, CFrame.Angles(0, 0, math.rad(-sx * 6))) end
	B.rp(e, "Canvas", b, V(3, 2.4, 0.1), V(0, 4.4, -0.2), C.Paper, M.Fabric, SM)
	B.rp(e, "Paint", b, V(1.6, 1.2, 0.02), V(0.2, 4.4, -0.26), C.Blood:Lerp(C.Paper, 0.2), M.SmoothPlastic, SM)
end
B.sign(AC, cf(-38.25, 8.5, 30, "+x"), 4, 2.5, "SING-ALONG\nTUESDAY!\n(mandatory)", C.PPink, C.Ink, Enum.Font.FredokaOne)
B.node(G, -26, y, 24.5)

----------------------------------------------------------------- washroom
local WA = F("Washroom")
B.cubicle(WA, cf(-10, y, 36.5, "-z"), G, 12, { name = "ToiletStall", col = C.PMint:Lerp(C.Paper, 0.4) })
B.counter(WA, cf(-1.7, y, 28, "-x"), 5, C.Paper, C.Paper:Lerp(C.Ink, 0.1), G, 1, nil, { name = "Sinks", topMat = M.Marble })
local mc = B.part(WA, "MirrorCabinet", V(2.5, 2.5, 0.4), cf(-0.45, 8, 28, "-x"), C.Chrome, M.Glass, { collide = false, refl = 0.3 })
B.searchable(mc, "Cabinet", G, 1)
loot(1, -1.7, 5.5, 26.3)
B.lamp(WA, "fluoro", CFrame.new(-7, 14, 28), G, { len = 3.5 })
B.node(G, -7, y, 27, true)

----------------------------------------------------------------- linen store
local LI = F("LinenStore")
for i, z in { 29, 35.5 } do
	B.shelf(LI, cf(12.75, y, z, "-x"), 5.5, 8, C.Paper:Lerp(C.Ink, 0.2), { pal = { C.Paper, C.PBlue, C.PPink, C.Sheet }, seed = i })
	loot(2, 12.75, if i == 1 then 6.07 else 4.22, if i == 1 then 29.3 else 35.7) -- free spots between the shelf stock
end
B.wardrobe(LI, cf(2.36, y, 36.5, "+x"), C.PBlue:Lerp(C.Paper, 0.3), G, "Closet", { label = "CLEAN LINEN", louvre = true, name = "LinenCupboard" })
B.cart(LI, cf(6, y, 30, "+x"), G)
B.lamp(LI, "bare", CFrame.new(7, 14, 32), G, { drop = 2.2, range = 14 })
B.node(G, 7, y, 24.5)

----------------------------------------------------------------- kitchen
local KI = F("Kitchen")
B.counter(KI, cf(26, y, 38.4, "-z"), 14, C.PLemon:Lerp(C.Ink, 0.1), C.Chrome, G, 2, { nil, "Cabinet", nil, "Drawer" }, { name = "BackCounter" })
B.stove(KI, cf(35.6, y, 38.5, "-z"))
B.counter(KI, cf(44, y, 38.4, "-z"), 12, C.PLemon:Lerp(C.Ink, 0.1), C.Chrome, G, 2, { nil, nil, "Cabinet" }, { name = "BackCounter" })
B.fridge(KI, cf(50.2, y, 23, "-x"), G, 2, { name = "KitchenFridge" })
B.table(KI, cf(30, y, 29), 10, 4, 3.4, C.Chrome, { mat = M.Metal, leg = C.Chrome, name = "PrepIsland" })
loot(2, 27, 5.4, 29.5)
loot(2, 32.5, 5.4, 28.6)
B.crockery(KI, cf(29.5, 5.4, 29))
B.crockery(KI, cf(46, 5.5, 38.4))
loot(2, 22, 5.5, 38.4)
loot(2, 41, 5.5, 38.2)
B.shelf(KI, cf(15.3, y, 32, "+x"), 6, 8, C.Chrome, { stuffMat = M.Cardboard, pal = { C.Mustard, C.Paper, C.PPeach, C.Rose } })
loot(2, 15.3, 4.22, 34.2)
B.lamp(KI, "fluoro", CFrame.new(30, 14, 30), G, { len = 5 })
B.sign(KI, cf(14.25, 9, 25, "+x"), 3.5, 2, "WASH YOUR\nHANDS!", C.Paper, C.Blood, Enum.Font.FredokaOne)
B.creak(38, y, 30)
B.node(G, 30, y, 24)
B.node(G, 45, y, 31)
return "ground ok, parts=" .. B.count(root)
