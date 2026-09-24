-- Upstairs (Area Upstairs): Grandma's Bedroom, Sewing Room, Kids' Old Room, Upstairs Hallway, Guest Room, Landing,
-- Upstairs Bathroom, Linen Room, Attic Stair Hall, Study. Requires 00..06.
local B = _G.HB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local U = B.FL.Upstairs
local UF = B.F("Upstairs")
local SM = { small = true }
local A = "Upstairs"
local function folder(n) return B.F(n, UF) end
local function dark(c, k) return c:Lerp(C.Ink, k or 0.35) end

B.room("Grandma's Bedroom", A, 3, 13, U, -35, 45, 27, -7)
B.room("Sewing Room", A, 2, -45, U, -35, -13, 27, -7)
B.room("Kids' Old Room", A, 2, -13, U, -35, 13, 27, -7)
B.room("Upstairs Hallway", A, 2, -45, U, -7, 45, 27, 1)
B.room("Guest Room", A, 2, -45, U, 1, -13, 27, 35)
B.room("Landing", A, 2, -13, U, 1, 1, 27, 35)
B.room("Upstairs Bathroom", A, 2, 1, U, 1, 13, 27, 15)
B.room("Linen Room", A, 2, 1, U, 15, 13, 27, 35)
B.room("Attic Stairs", A, 2, 13, U, 1, 27, 27, 35)
B.room("Study", A, 2, 27, U, 1, 45, 27, 35)

local function nightstand(par, b, col, area, danger, search)
	local m, top = B.dresser(par, b, 2.2, 1.8, 2.6, col, 2, area, danger, { name = "Nightstand", search = search })
	return m, top
end

----------------------------------------------------------------- GRANDMA'S BEDROOM (Danger 3)
do
	local f = folder("GrandmaBedroom")
	B.rug(f, 29, U, -26, 12, 10, C.Bruise:Lerp(C.Ink, 0.35), C.Rose:Lerp(C.Ink, 0.45))
	B.bed(f, cf(29, U, -30.5, "+z"), 6.5, 8.5, C.WoodDark, C.Rose:Lerp(C.Paper, 0.25), A, { name = "GrandmaBed", skirt = C.Paper:Lerp(C.Rose, 0.3) })
	-- bedposts (four-poster feel)
	for _, sx in { -1, 1 } do
		B.box(f, "BedPost", 29 + sx * 3.4 - 0.2, U, -34.9, 29 + sx * 3.4 + 0.2, U + 8, -34.5, C.WoodDark, M.Wood, SM)
	end
	nightstand(f, cf(24.1, U, -33.6, "+z"), C.WoodDark, A, 3, { 1 })
	nightstand(f, cf(33.9, U, -33.6, "+z"), C.WoodDark, A, 3, {})
	B.lamp(f, "table", cf(24.1, U + 2.8, -33.9), A, { shade = C.Rose, body = C.Paper, shadows = true, bright = 1.1, range = 14 })
	B.cyl(f, "DentureGlass", cf(33.3, U + 2.8, -33.3), 0.5, 0.7, V(0, 0.35, 0), C.Glass, M.Glass, { small = true, tr = 0.4 }, true)
	B.prize(A, V(34.3, U + 2.82, -33.6))
	B.prize(A, V(29, U + 3.83, -27.6))
	B.picture(f, cf(29, U + 8.6, -35, "+z"), 3.6, 2.8, { portrait = true, canvas = C.Night, clothes = C.Ink, hair = C.Paper:Lerp(C.Ink, 0.55), frame = C.Brass, name = "GrandpaOverBed" })
	B.rp(f, "Slippers", cf(26.5, U, -24.8), V(1.4, 0.3, 1), V(0, 0.15, 0), C.Rose:Lerp(C.Paper, 0.3), M.Fabric, SM)
	-- vanity on the east wall (Searchable Vanity) with a round CSG mirror
	local vb = cf(44, U, -21, "-x")
	local vm = B.model(f, "Vanity")
	B.rp(vm, "Top", vb, V(5, 0.3, 2), V(0, 2.9, 0), C.Paper:Lerp(C.Rose, 0.2), M.Wood)
	for _, sx in { -1, 1 } do
		B.rp(vm, "Pedestal", vb, V(1.3, 2.75, 1.8), V(sx * 1.75, 1.4, 0), C.Paper:Lerp(C.Rose, 0.2), M.Wood)
	end
	local vd = B.rp(vm, "VanityDrawer", vb, V(2, 0.6, 0.12), V(0, 2.5, -0.95), dark(C.Paper:Lerp(C.Rose, 0.2), 0.1), M.Wood, { collide = false })
	B.searchable(vd, "Vanity", A, 3)
	local ring = B.cyl(vm, "MirrorFrame", vb, 3.6, 0.3, V(0, 6, 0.8), C.Brass, M.Metal, SM, false)
	ring.CFrame = vb * CFrame.new(0, 6, 0.8) * CFrame.Angles(0, math.rad(90), 0)
	ring = B.csg("sub", ring, { B.cutter(V(1, 3.1, 3.1), vb * CFrame.new(0, 6, 0.8) * CFrame.Angles(0, math.rad(90), 0), Enum.PartType.Cylinder) })
	local mir = B.cyl(vm, "Mirror", vb, 3.1, 0.08, V(0, 6, 0.8), Color3.fromRGB(150, 158, 170), M.Glass, { small = true, refl = 0.4 }, false)
	mir.CFrame = vb * CFrame.new(0, 6, 0.85) * CFrame.Angles(0, math.rad(90), 0)
	for i, x in { -1.6, -1.1, 1.4 } do
		B.cyl(vm, "Perfume", vb, 0.35, 0.5 + i * 0.1, V(x, 3.3, 0.3), ({ C.Rose, C.Mint, C.Bruise })[i], M.Glass, { small = true, tr = 0.2 }, true)
	end
	B.rp(vm, "JewelryBox", vb, V(1.1, 0.6, 0.8), V(0.3, 3.35, 0.2), C.Blood:Lerp(C.Ink, 0.3), M.Fabric, SM)
	B.loot(A, 3, (vb * CFrame.new(0.4, 3.05, -0.3)).Position)
	B.loot(A, 3, (vb * CFrame.new(-0.6, 3.05, -0.4)).Position)
	B.rp(f, "VanityStool", cf(41.3, U, -21), V(1.8, 1.8, 1.8), V(0, 0.9, 0), C.Rose:Lerp(C.Ink, 0.2), M.Fabric)
	-- tall jewelry chest (Searchable Drawer)
	B.dresser(f, cf(44, U, -11.2, "-x"), 2.6, 1.8, 4.6, C.WoodDark, 5, A, 3, { name = "JewelryChest", search = { 1, 3 } })
	B.loot(A, 3, V(44, U + 4.82, -11.2))
	-- dresser on the north wall
	B.dresser(f, cf(31, U, -8.2, "-z"), 6, 2, 3.4, C.WoodDark, 3, A, 3, { name = "GrandmaDresser", search = { 2 } })
	B.loot(A, 3, V(29.5, U + 3.62, -8.4))
	B.picture(f, cf(31, U + 7.5, -7.25, "-z"), 2.2, 2.8, { portrait = true, canvas = C.Bruise:Lerp(C.Ink, 0.5), clothes = C.Rose:Lerp(C.Ink, 0.3), hair = C.Mustard:Lerp(C.Ink, 0.3), frame = C.Brass })
	-- wardrobe (HidingSpot) on the west wall
	B.wardrobe(f, cf(15.1, U, -16, "+x"), C.WoodDark:Lerp(C.WoodMid, 0.3), A, "Wardrobe", { name = "GrandmaWardrobe" })
	B.rocker(f, cf(40, U, -30.5, -140), C.WoodMid)
	B.lamp(f, "hang", cf(29, 27, -21), A, { shade = C.Rose, range = 18, bright = 0.7 })
	B.node(A, 29, U, -21)
	B.node(A, 19, U, -11)
	for _, p in { { 21, -24 }, { 37, -24 }, { 21, -15 }, { 36, -15 } } do
		B.creak(p[1], U, p[2])
	end
end

----------------------------------------------------------------- SEWING ROOM
do
	local f = folder("SewingRoom")
	-- sewing machine table under the front window gap
	local sb = cf(-29, U, -33.4, "+z")
	B.table(f, sb, 4.4, 2.2, 3, C.WoodMid, { name = "SewingTable" })
	local sm = B.model(f, "SewingMachine")
	B.rp(sm, "Base", sb, V(2.4, 0.3, 1.2), V(0, 3.15, 0), C.Ink, M.SmoothPlastic, SM)
	B.rp(sm, "Pillar", sb, V(0.5, 1.2, 0.8), V(0.8, 3.9, 0), C.Ink, M.SmoothPlastic, SM)
	B.rp(sm, "Arm", sb, V(2.2, 0.5, 0.8), V(0, 4.6, 0), C.Ink, M.SmoothPlastic, SM)
	B.rp(sm, "Head", sb, V(0.5, 0.9, 0.7), V(-0.9, 4.1, 0), C.Ink, M.SmoothPlastic, SM)
	B.rp(sm, "Decal", sb, V(1.4, 0.15, 0.05), V(0, 4.6, -0.42), C.Brass, M.Metal, SM)
	B.cyl(sm, "Wheel", sb, 0.8, 0.12, V(1.15, 4.6, 0), C.Metal, M.Metal, SM, false)
	B.loot(A, 2, (sb * CFrame.new(-1.5, 3.02, 0.3)).Position)
	B.chair(f, cf(-29, U, -30.4, "-z"), C.WoodDark, { cushion = C.Mustard:Lerp(C.Ink, 0.2) })
	-- cutting table with patterns + scissors
	B.table(f, cf(-30, U, -19), 7, 4, 3.2, C.WoodLight, { name = "CuttingTable" })
	B.rp(f, "Pattern", cf(-31, U + 3.2, -19.3), V(3.4, 0.03, 2.4), V(0, 0.02, 0), C.Paper:Lerp(C.Mustard, 0.3), M.SmoothPlastic, SM)
	B.rp(f, "FabricPiece", cf(-28, U + 3.2, -18.6, 12), V(2.2, 0.06, 1.8), V(0, 0.03, 0), C.Rose, M.Fabric, SM)
	B.loot(A, 2, V(-27.7, U + 3.25, -19.8))
	B.loot(A, 2, V(-32.4, U + 3.25, -18.2))
	-- fabric bolt shelf between the west windows
	B.bookshelf(f, cf(-44.1, U, -21, "+x"), 6, 8, C.WoodRaw, { empty = true, name = "FabricShelf" })
	local fabs = { C.Rose, C.Mint, C.Mustard, C.Bruise, C.Paper, C.Blood }
	for s = 0, 3 do
		for j = 0, 3 do
			local p = V(-44.1, U + 0.38 + s * 1.85 + 0.6, -23.2 + j * 1.45)
			B.cyl(f, "FabricBolt", CFrame.new(p), 1.1, 1.3, V(0, 0, 0), fabs[(s * 2 + j) % 6 + 1]:Lerp(C.Ink, 0.2), M.Fabric, SM, false)
		end
	end
	-- dress form
	local db = cf(-40, U, -12.5, 30)
	local dm = B.model(f, "DressForm")
	B.cyl(dm, "Stand", db, 1.4, 0.2, V(0, 0.1, 0), C.WoodDark, M.Wood, SM, true)
	B.cyl(dm, "Pole", db, 0.2, 3.2, V(0, 1.7, 0), C.Brass, M.Metal, SM, true)
	B.cyl(dm, "Waist", db, 1.4, 1.2, V(0, 3.6, 0), C.Paper:Lerp(C.Rose, 0.35), M.Fabric, { collide = true }, true)
	B.ball(dm, "Bust", db, 1.9, V(0, 4.8, 0), C.Paper:Lerp(C.Rose, 0.35), M.Fabric, { collide = true })
	B.cyl(dm, "Neck", db, 0.5, 0.6, V(0, 5.9, 0), C.WoodDark, M.Wood, SM, true)
	B.ball(dm, "Knob", db, 0.45, V(0, 6.3, 0), C.WoodDark, M.Wood, SM)
	B.rp(dm, "HalfDress", db, V(2.2, 2.2, 0.1), V(0, 3.4, -0.9), C.Mint:Lerp(C.Ink, 0.2), M.Fabric, SM)
	B.rp(dm, "Tape", db, V(0.12, 2.4, 0.05), V(0.35, 4.4, -0.95), C.Mustard, M.Fabric, SM)
	-- notions chest (Searchable) on the east wall, fabric armoire (HidingSpot) on the north wall
	B.dresser(f, cf(-13.9, U, -17, "-x"), 4, 1.8, 3.2, C.WoodMid, 4, A, 2, { name = "NotionsChest", search = { 1 } })
	for i = 0, 4 do
		B.cyl(f, "Spool", cf(-13.9, U + 3.4, -18.4 + i * 0.6), 0.35, 0.45, V(0, 0.22, 0), fabs[i + 1], M.Fabric, SM, true)
	end
	B.loot(A, 2, V(-13.9, U + 3.42, -15.5))
	B.wardrobe(f, cf(-40, U, -8.9, "-z"), C.WoodMid:Lerp(C.Mustard, 0.15), A, "Wardrobe", { name = "FabricArmoire", w = 4.8 })
	B.lamp(f, "bare", cf(-30, 27, -20), A, { drop = 2, bright = 0.5, range = 14 })
	B.node(A, -30, U, -26)
	B.node(A, -22, U, -11)
	B.creak(-22, U, -27)
end

----------------------------------------------------------------- KIDS' OLD ROOM
do
	local f = folder("KidsRoom")
	B.rug(f, 2, U, -21, 8, 8, C.Mint:Lerp(C.Paper, 0.2), C.Rose:Lerp(C.Paper, 0.2))
	B.bed(f, cf(-8.8, U, -12.4, "+x"), 4.8, 7.6, C.Paper:Lerp(C.Ink, 0.2), C.Mint:Lerp(C.Paper, 0.3), A, { name = "KidsBed", skirt = C.Mustard:Lerp(C.Paper, 0.4) })
	nightstand(f, cf(-11.8, U, -16.6, "+x"), C.Paper:Lerp(C.Ink, 0.25), A, 2, { 1 })
	B.lamp(f, "table", cf(-11.8, U + 2.8, -16.2), A, { shade = C.Bruise:Lerp(C.Paper, 0.3), body = C.Mint, bright = 0.6, range = 12, color = Color3.fromRGB(255, 170, 190) })
	B.loot(A, 2, V(-11.7, U + 2.82, -17.3))
	-- toy chest (Searchable ToyChest) between the front windows
	local tb = cf(-1, U, -33.6, "+z")
	local tc = B.model(f, "ToyChest")
	B.rp(tc, "Body", tb, V(3.4, 1.8, 2), V(0, 0.9, 0), C.Mint:Lerp(C.Ink, 0.15), M.Wood)
	local lid = B.rp(tc, "Lid", tb, V(3.5, 0.4, 2.1), V(0, 2, 0), C.Rose:Lerp(C.Ink, 0.15), M.Wood)
	B.searchable(lid, "ToyChest", A, 2)
	B.loot(A, 2, V(-0.2, U + 2.2, -33.6))
	for i, c in { C.Mustard, C.Rose, C.Mint } do
		B.rp(tc, "Letter", tb, V(0.6, 0.6, 0.05), V(-1.2 + (i - 1) * 1.2, 1, -1.03), c, M.SmoothPlastic, SM)
	end
	-- creepy tea party: little table, tiny chairs, dolls
	local tp = cf(3, U, -21)
	B.cyl(f, "TeaTable", tp, 3, 0.2, V(0, 2, 0), C.Paper, M.Wood, { collide = true }, true)
	B.cyl(f, "TeaLeg", tp, 0.4, 2, V(0, 1, 0), C.Paper, M.Wood, SM, true)
	B.cyl(f, "TinyTeapot", tp, 0.6, 0.5, V(0, 2.35, 0), C.Rose, M.SmoothPlastic, SM, true)
	B.loot(A, 2, V(3.8, U + 2.12, -20.4))
	for i, a in { 0, 90, 180, 270 } do
		local cb = tp * CFrame.Angles(0, math.rad(a), 0) * CFrame.new(0, 0, -2.3) * CFrame.Angles(0, math.rad(180), 0)
		B.rp(f, "TinyChair", cb, V(1.1, 1.1, 1.1), V(0, 0.55, 0), ({ C.Mint, C.Rose, C.Mustard, C.Paper })[i], M.Wood)
		if i ~= 3 then
			B.doll(f, cb * CFrame.new(0, 1.1, 0), 0.9, ({ C.Rose, C.Bruise, C.Mint })[math.min(i, 3)])
		end
	end
	-- doll shelf on the east wall
	B.box(f, "DollShelf", 12.1, U + 5.2, -26, 12.75, U + 5.4, -16, C.Paper:Lerp(C.Ink, 0.2), M.Wood, SM)
	for i = 0, 3 do
		B.doll(f, cf(12.3, U + 5.4, -25 + i * 2.2, "-x"), 0.75, ({ C.Rose, C.Mint, C.Mustard, C.Bruise, C.Paper })[i + 1])
	end
	B.loot(A, 2, V(12.35, U + 5.42, -16.8))
	-- rocking horse
	local rh = B.model(f, "RockingHorse")
	local rb = cf(8, U, -30, 60)
	B.rp(rh, "Body", rb, V(0.9, 1, 2.4), V(0, 2, 0), C.Paper:Lerp(C.Ink, 0.1), M.Wood)
	B.rp(rh, "Head", rb, V(0.7, 1.3, 0.9), V(0, 2.9, -1.3), C.Paper:Lerp(C.Ink, 0.1), M.Wood)
	B.rp(rh, "Mane", rb, V(0.2, 1.2, 0.7), V(0, 3.2, -1.05), C.Blood:Lerp(C.Ink, 0.2), M.Fabric, SM)
	for _, sx in { -1, 1 } do
		B.rp(rh, "Rocker", rb, V(0.2, 0.3, 3.6), V(sx * 0.6, 0.2, 0), C.Rose:Lerp(C.Ink, 0.2), M.Wood, SM)
		B.rp(rh, "Legs", rb, V(0.15, 1.5, 2), V(sx * 0.5, 1, 0), C.Paper:Lerp(C.Ink, 0.1), M.Wood, SM)
	end
	-- blocks + kids' closet (HidingSpot Closet)
	for i, p in { { -4, -27 }, { -3.2, -26.5 }, { -3.6, -26.8 } } do
		B.rp(f, "Block", cf(p[1], U + (if i == 3 then 0.8 else 0), p[2], i * 20), V(0.8, 0.8, 0.8), V(0, 0.4, 0), ({ C.Rose, C.Mustard, C.Mint })[i], M.Wood, SM)
	end
	B.wardrobe(f, cf(10.3, U, -9.2, "-z"), C.Paper:Lerp(C.Ink, 0.2), A, "Closet", { name = "KidsCloset", w = 4.6, louvre = true })
	B.picture(f, cf(-12.75, U + 7.2, -21, "+x"), 2.6, 2, { scene = C.Mint:Lerp(C.Ink, 0.3), canvas = C.Mustard:Lerp(C.Paper, 0.4), frame = C.Rose })
	B.node(A, 0, U, -14)
	B.node(A, -2, U, -28)
	B.creak(-4, U, -18)
	B.pumpkin(A, V(6, U, -13))
end

----------------------------------------------------------------- UPSTAIRS HALLWAY (portraits)
do
	local f = folder("UpHallway")
	local canv = { C.Night, C.Bruise:Lerp(C.Ink, 0.5), C.WoodDark:Lerp(C.Ink, 0.3), C.Night:Lerp(C.Blood, 0.2) }
	local k = 0
	for _, x in { -38, -26, -8, 7, 25, 30, 41 } do
		k += 1
		B.picture(f, cf(x, U + 7.4, -6.75, "+z"), 1.9, 2.6, { portrait = true, canvas = canv[k % 4 + 1], clothes = C.Ink, hair = C.Paper:Lerp(C.Ink, 0.2 + (k % 3) * 0.2), frame = if k % 2 == 0 then C.Brass else C.WoodDark })
	end
	for _, x in { -40, -22, 11, 24, 29.5, 41.5 } do
		k += 1
		B.picture(f, cf(x, U + 7.4, 0.75, "-z"), 1.9, 2.6, { portrait = true, canvas = canv[k % 4 + 1], clothes = C.Ink:Lerp(C.Bruise, 0.3), hair = C.Paper:Lerp(C.Ink, 0.2 + (k % 3) * 0.2), frame = if k % 2 == 0 then C.Brass else C.WoodDark })
	end
	B.table(f, cf(-37.5, U, 0.3), 3.2, 1, 3, C.WoodDark, { name = "HallTable" })
	B.vase(f, cf(-36.6, U + 3, 0.3), C.Rose:Lerp(C.Ink, 0.2), 0.8)
	B.loot(A, 2, V(-38.3, U + 3.02, 0.3))
	B.vase(f, cf(44, U, -6), C.Mint:Lerp(C.Ink, 0.25), 1.4)
	B.vase(f, cf(-44, U, -6), C.Mustard:Lerp(C.Ink, 0.35), 1.3)
	B.lamp(f, "sconce", cf(-12, U + 7.8, -6.75, "+z"), A, { shade = C.Rose, bright = 0.55, range = 12 })
	B.lamp(f, "sconce", cf(21.5, U + 7.8, 0.75, "-z"), A, { shade = C.Rose, bright = 0.55, range = 12 })
	for _, x in { -34, -14, 4, 12, 27, 38 } do
		B.creak(x, U, -3)
	end
	B.node(A, -35, U, -3)
	B.node(A, -12, U, -3)
	B.node(A, 10, U, -3)
	B.node(A, 30, U, -3)
end

----------------------------------------------------------------- GUEST ROOM (dust sheets)
do
	local f = folder("GuestRoom")
	B.bed(f, cf(-29, U, 30.5, "-z"), 6, 8.5, C.WoodMid, C.Sheet, A, { name = "GuestBed", skirt = C.Sheet:Lerp(C.Ink, 0.08) })
	nightstand(f, cf(-33.6, U, 33.6, "-z"), C.WoodMid, A, 2, { 1 })
	B.lamp(f, "table", cf(-33.6, U + 2.8, 34), A, { shade = C.Mustard, body = C.Paper, bright = 0.7 })
	B.loot(A, 2, V(-33.2, U + 2.82, 33.2))
	B.wardrobe(f, cf(-15.1, U, 18, "-x"), C.WoodMid, A, "Wardrobe", { name = "GuestWardrobe" })
	B.dresser(f, cf(-44, U, 18, "+x"), 5, 1.8, 3.2, C.WoodMid, 3, A, 2, { name = "GuestDresser", search = { 1 } })
	B.loot(A, 2, V(-44, U + 3.42, 19.5))
	B.picture(f, cf(-45, U + 7.4, 18, "+x"), 3, 3.4, { canvas = Color3.fromRGB(140, 150, 160), frame = C.WoodDark, name = "Mirror" })
	B.sheeted(f, cf(-38, U, 6.5, 200), "chair")
	B.sheeted(f, cf(-20.5, U, 5.5, "-x"), "table", 0.9)
	B.rp(f, "Suitcase", cf(-24, U, 31.5, 15), V(2.6, 0.9, 1.8), V(0, 0.45, 0), C.Mustard:Lerp(C.Ink, 0.4), M.Leather)
	B.loot(A, 2, V(-20.5, U + 2.85, 5.5))
	B.node(A, -29, U, 16)
	B.creak(-30, U, 5)
end

----------------------------------------------------------------- LANDING
do
	local f = folder("Landing")
	for i, z in { 9, 16, 23 } do
		B.picture(f, cf(-12.75, U + 6.2, z, "+x"), 2.2, 2.9, { portrait = true, canvas = C.Night:Lerp(C.Bruise, i * 0.15), clothes = C.Ink, hair = C.WoodDark:Lerp(C.Paper, i * 0.2), frame = C.Brass })
	end
	B.armchair(f, cf(-1.8, U, 32.6, -20), C.Bruise:Lerp(C.Ink, 0.3), "ReadingChair", { w = 4, d = 3.8, trim = C.Ink })
	B.rp(f, "PlantStand", cf(-11, U, 33.5), V(1.2, 3, 1.2), V(0, 1.5, 0), C.WoodDark, M.Wood)
	B.ball(f, "DeadFern", cf(-11, U + 3, 33.5), 1.6, V(0, 0.5, 0), C.Grass:Lerp(C.WoodDark, 0.5), M.Fabric, SM)
	B.loot(A, 2, V(-10.6, U + 3.02, 33.2))
	B.node(A, -2.5, U, 16)
	B.creak(-2.5, U, 10)
	B.creak(-9.5, U, 31)
end

----------------------------------------------------------------- UPSTAIRS BATHROOM
do
	local f = folder("UpBath")
	local tb = cf(11.2, U, 7.5, "-x")
	local tub = B.rp(f, "Tub", tb, V(6, 2.4, 3.2), V(0, 1.7, 0), C.Rose:Lerp(C.Paper, 0.5), M.SmoothPlastic, { collide = true })
	B.csg("sub", tub, { B.cutter(V(5.4, 2.4, 2.6), tb * CFrame.new(0, 2.3, 0)) }, { fid = Enum.CollisionFidelity.Box })
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			B.ball(f, "ClawFoot", tb, 0.45, V(sx * 2.5, 0.25, sz * 1.2), C.Brass, M.Metal, SM)
		end
	end
	B.loot(A, 2, (tb * CFrame.new(-2.6, 2.9, 0)).Position)
	B.rp(f, "RubberDuck", tb * CFrame.new(1.4, 2.95, 0.6), V(0.5, 0.45, 0.6), V(0, 0.2, 0), C.Mustard, M.SmoothPlastic, SM)
	local tt = cf(4, U, 13.9, "-z")
	B.rp(f, "Bowl", tt, V(1.4, 1.6, 2), V(0, 0.8, -0.3), C.Paper, M.SmoothPlastic)
	B.rp(f, "Seat", tt, V(1.6, 0.15, 2.1), V(0, 1.68, -0.35), C.Rose:Lerp(C.Paper, 0.4), M.SmoothPlastic, SM)
	B.rp(f, "Tank", tt, V(2, 2, 0.8), V(0, 2.4, 0.6), C.Paper, M.SmoothPlastic)
	local sb = cf(1.9, U, 9, "+x")
	B.rp(f, "Pedestal", sb, V(0.8, 2.6, 0.8), V(0, 1.3, 0), C.Paper, M.SmoothPlastic)
	local basin = B.rp(f, "Basin", sb, V(2.4, 0.7, 1.6), V(0, 2.95, 0), C.Paper, M.SmoothPlastic, { collide = true })
	B.csg("sub", basin, { B.cutter(V(1.9, 0.6, 1.1), sb * CFrame.new(0, 3.2, -0.05)) }, { fid = Enum.CollisionFidelity.Box })
	local mc = B.model(f, "MirrorCabinet")
	B.rp(mc, "Box", sb, V(2.2, 2.6, 0.6), V(0, 6.6, 0.55), C.Paper:Lerp(C.Ink, 0.1), M.Wood)
	local md = B.rp(mc, "Cabinet", sb, V(2, 2.4, 0.1), V(0, 6.6, 0.2), Color3.fromRGB(150, 160, 170), M.Glass, { refl = 0.35, collide = false })
	B.searchable(md, "Cabinet", A, 2)
	B.cyl(f, "Hamper", cf(3, U, 3), 1.6, 2.4, V(0, 1.2, 0), C.WoodLight, M.Fabric, { collide = true }, true)
	B.lamp(f, "sconce", cf(1.25, U + 8.7, 11, "+x"), A, { shade = C.Paper, bright = 0.55, range = 12 })
	B.node(A, 6.5, U, 6)
end

----------------------------------------------------------------- LINEN ROOM (walk-in closet)
do
	local f = folder("LinenRoom")
	B.bookshelf(f, cf(12.1, U, 20.5, "-x"), 6, 8.5, C.Paper:Lerp(C.Ink, 0.2), { empty = true, name = "LinenShelf" })
	for s = 0, 3 do
		for j = 0, 1 do
			B.rp(f, "Towels", cf(12.1, U + 0.38 + s * 1.975, 18.5 + j * 2), V(1.2, 0.9, 1.6), V(0, 0.45, 0), ({ C.Paper, C.Mint:Lerp(C.Paper, 0.4), C.Rose:Lerp(C.Paper, 0.4) })[(s + j) % 3 + 1], M.Fabric, SM)
		end
	end
	local bin = B.rp(f, "Cabinet", cf(12.1, U, 27.5, "-x"), V(3, 3, 1.6), V(0, 1.5, 0), C.Paper:Lerp(C.Ink, 0.25), M.Wood)
	B.searchable(bin, "Cabinet", A, 2)
	B.loot(A, 2, V(12.1, U + 3.05, 27.5))
	B.loot(A, 2, V(12.1, U + 4.33, 22.7))
	B.wardrobe(f, cf(7, U, 33.1, "-z"), C.Paper:Lerp(C.Ink, 0.3), A, "Closet", { name = "WalkInCloset", w = 5, louvre = true })
	B.sheeted(f, cf(3.2, U, 30, "+x"), "tall", 0.85)
	B.node(A, 6, U, 24)
end

----------------------------------------------------------------- ATTIC STAIR HALL
do
	local f = folder("AtticStairHall")
	B.lamp(f, "bare", cf(16.5, 27, 20), A, { drop = 2.8, bright = 0.45, range = 14 })
	B.rp(f, "MopBucket", cf(14, U, 9), V(1.3, 1.3, 1.3), V(0, 0.65, 0), C.Metal, M.Metal)
	B.node(A, 16.5, U, 27)
	B.creak(16.5, U, 18)
end

----------------------------------------------------------------- STUDY (Grandpa's)
do
	local f = folder("Study")
	B.rug(f, 36, U, 18, 10, 12, C.Blood:Lerp(C.Ink, 0.5), C.Mustard:Lerp(C.Ink, 0.5))
	B.dresser(f, cf(36, U, 33.2, "-z"), 6, 2.6, 3, C.WoodDark, 2, A, 2, { name = "Desk", search = { 1 } })
	B.chair(f, cf(36, U, 30.4, "+z"), C.WoodDark, { cushion = C.Blood:Lerp(C.Ink, 0.3) })
	B.rp(f, "Typewriter", cf(35.2, U + 3.2, 33, "-z"), V(1.8, 0.7, 1.4), V(0, 0.35, 0), C.Ink, M.Metal, SM)
	B.lamp(f, "table", cf(38.4, U + 3.2, 33.6), A, { shade = C.Mint:Lerp(C.Ink, 0.2), body = C.Brass, bright = 0.8, range = 14 })
	B.loot(A, 2, V(37.3, U + 3.22, 32.6))
	for i, z in { 8, 13, 18 } do
		B.bookshelf(f, cf(27.9, U, z, "+x"), 4.6, 9.5, C.WoodDark, { seed = 20 + i, gap = if i == 2 then 2 else nil })
	end
	B.loot(A, 2, V(28, U + 4.83, 14.15))
	B.dresser(f, cf(44, U, 18, "-x"), 2.4, 2.2, 4.4, C.Metal:Lerp(C.Mint, 0.3), 3, A, 2, { name = "FilingCabinet", search = { 2 } })
	B.loot(A, 2, V(44, U + 4.62, 18))
	local gb = cf(40.5, U, 29)
	B.cyl(f, "GlobeStand", gb, 0.25, 2.6, V(0, 1.3, 0), C.WoodDark, M.Wood, SM, true)
	B.ball(f, "Globe", gb, 1.8, V(0, 3.2, 0), C.Mint:Lerp(C.Mustard, 0.4), M.SmoothPlastic, { collide = true })
	B.armchair(f, cf(38, U, 9, 160), C.Blood:Lerp(C.Ink, 0.45), "StudyChair", { w = 4.2, d = 4, trim = C.Ink })
	B.picture(f, cf(45, U + 7.6, 18, "-x"), 4, 3, { scene = C.Mustard:Lerp(C.Ink, 0.5), canvas = C.Paper:Lerp(C.Mustard, 0.3), frame = C.WoodDark, name = "OldMap" })
	B.node(A, 34, U, 22)
	B.creak(33, U, 4.5)
end
return "upstairs ok, parts=" .. B.count(B.root())
