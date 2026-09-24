-- Ground floor part B: Kitchen, Laundry/Pantry (FuseBox), Hallway, Stair Hall, Bathroom, Storage, Den, Basement stair room volume.
local B = _G.HB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local G = B.FL.Ground
local GF = B.F("Ground")
local SM = { small = true }
local function folder(n) return B.F(n, GF) end

B.room("Kitchen", "Ground", 1, -45, G, -7, -13, 14, 21)
B.room("Laundry & Pantry", "Ground", 1, -45, G, 21, -13, 14, 35)
B.room("Hallway", "Ground", 1, -13, G, -7, 45, 14, 1)
B.room("Stair Hall", "Ground", 1, -13, G, 1, 1, 14, 35)
B.room("Bathroom", "Ground", 1, 1, G, 1, 13, 14, 13)
B.room("Storage Room", "Ground", 1, 1, G, 13, 13, 14, 35)
B.room("Den", "Ground", 2, 23, G, 1, 45, 14, 35)
B.room("Basement Stairs", "Basement", 3, 13, B.FL.Basement, 1, 23, 14, 35)

----------------------------------------------------------------- KITCHEN
do
	local f = folder("Kitchen")
	local cab = C.Mint:Lerp(C.Paper, 0.35)
	local top = C.Paper:Lerp(C.Ink, 0.1)
	-- west counter run (sink under the window at Z=1)
	B.counter(f, cf(-43.7, G, -3.25, "+x"), 4.5, cab, top, "Ground", 1, { [1] = "Drawer" })
	-- sink cabinet with a CSG basin
	do
		local sk = B.counter(f, cf(-43.7, G, 1, "+x"), 4, cab, top, "Ground", 1, { [1] = "Cabinet" }, { noTop = true, name = "SinkCabinet" })
		local b = cf(-43.7, G, 1, "+x")
		local slab = B.rp(sk, "SinkTop", b, V(4.2, 0.6, 2.8), V(0, 3.2, 0), top, M.Marble, { collide = true })
		local basin = B.cutter(V(2.8, 0.8, 1.6), b * CFrame.new(0, 3.55, -0.05))
		B.csg("sub", slab, { basin }, { fid = Enum.CollisionFidelity.Box })
		B.rp(sk, "Faucet", b, V(0.2, 0.9, 0.2), V(0, 3.9, 0.9), C.Metal, M.Metal, SM)
		B.rp(sk, "Spout", b, V(0.18, 0.18, 0.8), V(0, 4.3, 0.55), C.Metal, M.Metal, SM)
		B.rp(sk, "DishRack", b, V(1.4, 0.6, 1.2), V(-2.8, 3.7, 0.3), C.Metal, M.Metal, SM)
	end
	B.counter(f, cf(-43.7, G, 10.1, "+x"), 14.2, cab, top, "Ground", 1, { [2] = "Cabinet", [4] = "Drawer" })
	B.uppers(f, cf(-43.6, G, 7, "+x"), 5, cab, { [1] = true }, "Ground", 1)
	B.uppers(f, cf(-43.6, G, -4, "+x"), 4, cab, nil, "Ground", 1)
	-- backsplash tiles
	B.box(f, "Backsplash", -45, G + 3.4, -5.5, -44.9, G + 5.8, 17.2, C.Mint:Lerp(C.Paper, 0.55), M.Glass, { small = true })
	-- north wall: counter, stove, counter, fridge
	B.counter(f, cf(-33.6, G, 19.7, "-z"), 3.8, cab, top, "Ground", 1, { [1] = "Drawer" })
	B.stove(f, cf(-30, G, 19.7, "-z"))
	B.rp(f, "Hood", cf(-30, G, 19.7, "-z"), V(3.6, 1.2, 2), V(0, 7.6, 0.3), C.Paper:Lerp(C.Ink, 0.15), M.Metal)
	B.counter(f, cf(-23.4, G, 19.7, "-z"), 9.2, cab, top, "Ground", 1, { [2] = "Cabinet" })
	B.uppers(f, cf(-23.4, G, 19.6, "-z"), 9, cab, { [3] = true }, "Ground", 1)
	B.fridge(f, cf(-16.4, G, 19.4, "-z"), "Ground", 1)
	-- counter props + loot
	B.cyl(f, "CookieJar", cf(-43.6, G + 3.5, 7), 1, 1.2, V(0, 0.6, 0), C.Rose:Lerp(C.Paper, 0.3), M.SmoothPlastic, SM, true)
	B.rp(f, "Breadbox", cf(-43.6, G + 3.5, 13.5, "+x"), V(2, 1.1, 1.3), V(0, 0.55, 0), C.Mustard:Lerp(C.Paper, 0.3), M.Metal, SM)
	B.rp(f, "CuttingBoard", cf(-23, G + 3.5, 19.6, "-z"), V(2, 0.15, 1.3), V(0, 0.08, 0), C.WoodLight, M.Wood, SM)
	B.loot("Ground", 1, V(-43.6, G + 3.5, 4.5))
	B.loot("Ground", 1, V(-43.5, G + 3.5, 16))
	B.loot("Ground", 1, V(-26, G + 3.5, 19.4))
	B.loot("Ground", 1, V(-33.6, G + 3.5, 19.5))
	B.plates(f, cf(-19.8, G + 3.5, 18.8), 5)
	-- breakfast table + chairs + hanging lamp
	B.table(f, cf(-27, G, 5), 5, 5, 3.1, C.WoodLight, { name = "BreakfastTable", cloth = C.Rose:Lerp(C.Paper, 0.4) })
	B.chair(f, cf(-27, G, 1.4, "+z"), C.Paper:Lerp(C.Ink, 0.2))
	B.chair(f, cf(-27, G, 8.6, "-z"), C.Paper:Lerp(C.Ink, 0.2))
	B.chair(f, cf(-30.6, G, 5, "+x"), C.Paper:Lerp(C.Ink, 0.2))
	B.chair(f, cf(-23.4, G, 5, "-x"), C.Paper:Lerp(C.Ink, 0.2))
	B.cyl(f, "FruitBowl", cf(-27, G + 3.1, 5), 1.4, 0.4, V(0, 0.2, 0), C.Paper, M.SmoothPlastic, SM, true)
	B.loot("Ground", 1, V(-26, G + 3.12, 6))
	B.lamp(f, "hang", cf(-27, 14, 5), "Ground", { shade = C.Mint, range = 18, bright = 1 })
	-- broom closet (HidingSpot Cabinet) on the east wall
	B.wardrobe(f, cf(-15.1, G, 14, "-x"), C.Mint:Lerp(C.Ink, 0.25), "Ground", "Cabinet", { name = "BroomCloset", w = 4.6, louvre = true })
	-- wall clock + calendar
	B.cyl(f, "WallClock", cf(-13.4, G + 9, 5, "-x"), 1.6, 0.15, V(0, 0, -0.08), C.Paper, M.SmoothPlastic, SM, false).CFrame = cf(-13.35, G + 9, 5, "-x") * CFrame.Angles(0, math.rad(90), 0)
	B.picture(f, cf(-13.25, G + 6.5, 3, "-x"), 1.6, 2.2, { canvas = C.Paper, frame = C.Rose })
	B.node("Ground", -24, G, -3)
	B.node("Ground", -34, G, 12)
	B.creak(-3, G, 22)
	B.creak(-17, G, -28)
	B.pumpkin("Ground", V(-19, G, 12))
end

----------------------------------------------------------------- LAUNDRY & PANTRY
do
	local f = folder("Laundry")
	-- washer + dryer between the back windows
	for i, x in { -31.4, -28 } do
		local b = cf(x, G, 33.5, "-z")
		B.rp(f, if i == 1 then "Washer" else "Dryer", b, V(3.2, 3.4, 2.6), V(0, 1.7, 0), C.Paper:Lerp(C.Ink, 0.1), M.SmoothPlastic)
		B.cyl(f, "Porthole", b, 1.8, 0.1, V(0, 1.7, -1.32), C.Ink:Lerp(C.Glass, 0.4), M.Glass, SM, false).CFrame = b * CFrame.new(0, 1.7, -1.32) * CFrame.Angles(0, math.rad(90), 0)
		B.rp(f, "Panel", b, V(3.2, 0.8, 0.6), V(0, 3.8, 1), C.Paper:Lerp(C.Ink, 0.2), M.SmoothPlastic, SM)
	end
	B.loot("Ground", 1, V(-28, G + 3.4, 33.2))
	B.rp(f, "DetergentBox", cf(-31.4, G + 3.4, 33.5), V(1, 1, 0.6), V(0, 0.5, 0), C.Mustard, M.SmoothPlastic, SM)
	-- laundry sink tub
	B.rp(f, "UtilitySink", cf(-19, G, 33.6, "-z"), V(3, 3.2, 2.2), V(0, 1.6, 0), C.Concrete:Lerp(C.Paper, 0.3), M.Concrete)
	-- pantry shelves on the east wall (Searchable cabinet)
	B.bookshelf(f, cf(-14, G, 25, "-x"), 7, 8.5, C.WoodRaw, { empty = true, name = "PantryShelf" })
	local jarCols = { C.Blood:Lerp(C.Ink, 0.2), C.Mustard, C.Mint:Lerp(C.Ink, 0.3), C.Rose }
	for s = 0, 3 do
		for j = 0, 3 do
			B.jar(f, V(-14, G + 0.4 + s * 1.975, 22.2 + j * 1.35), jarCols[(s + j) % 4 + 1], if s == 3 then 1.2 else 1)
		end
	end
	local pd = B.rp(f, "PantryBin", cf(-14.1, G, 25, "-x"), V(6.4, 0.9, 0.12), V(0, 0.9, -0.85), C.WoodRaw:Lerp(C.Ink, 0.2), M.Wood, { collide = false })
	pd.Name = "Cabinet"
	B.searchable(pd, "Cabinet", "Ground", 1)
	B.loot("Ground", 1, V(-14, G + 4.35, 27.6))
	-- ironing board + clothesline with hanging sheets
	B.rp(f, "IroningBoard", cf(-22, G, 25), V(4.5, 0.15, 1.3), V(0, 3, 0), C.Rose:Lerp(C.Paper, 0.5), M.Fabric)
	B.rp(f, "IronLegs", cf(-22, G, 25), V(0.15, 3, 1), V(0, 1.5, 0), C.Metal, M.Metal, SM)
	B.box(f, "Clothesline", -44.5, G + 9.5, 29.9, -21, G + 9.6, 30, C.Paper, M.Fabric, SM)
	for _, x in { -40, -34.5, -26.5 } do
		B.part(f, "HangingSheet", V(3.6, 5.8, 0.08), CFrame.new(x, G + 6.6, 30) * CFrame.Angles(0, math.rad((x * 7) % 10 - 5), 0), C.Sheet, M.Fabric, { small = true, tr = 0.08 })
	end
	-- FuseBox on the west wall (House.FuseBox)
	B.part(B.root(), "FuseBox", V(1.8, 2.4, 0.5), cf(-44.75, G + 5.2, 23.4, "+x"), C.Metal:Lerp(C.Mint, 0.2), M.Metal, { collide = true, query = true })
	B.box(f, "Conduit", -44.9, G + 6.4, 23.3, -44.7, G + 12, 23.5, C.Metal, M.Metal, SM)
	B.part(f, "FuseLever", V(0.5, 0.8, 0.2), cf(-44.4, G + 5.2, 23.9, "+x"), C.Blood, M.SmoothPlastic, SM)
	B.part(f, "FuseLabel", V(1.2, 0.4, 0.05), cf(-44.48, G + 6.1, 23.4, "+x"), C.Paper, M.SmoothPlastic, SM)
	-- tall linen closet (HidingSpot Closet)
	B.wardrobe(f, cf(-43.1, G, 32.6, "+x"), C.Paper:Lerp(C.Ink, 0.3), "Ground", "Closet", { name = "LinenCloset", w = 4.4, louvre = true })
	B.lamp(f, "bare", cf(-29, 14, 27), "Ground", { drop = 2.5, bright = 0.9, range = 16 })
	B.node("Ground", -30, G, 27)
	B.creak(40.5, G, 31)
end

----------------------------------------------------------------- HALLWAY
do
	local f = folder("Hallway")
	-- slim console with a vase (Breakable) and loot
	B.table(f, cf(26, G, -6.35), 3.2, 1, 3, C.WoodDark, { name = "HallConsole" })
	B.vase(f, cf(25.1, G + 3, -6.35), C.Mint:Lerp(C.Ink, 0.15), 0.8)
	B.loot("Ground", 1, V(26.6, G + 3.02, -6.35))
	B.vase(f, cf(43.8, G, -6), C.Rose:Lerp(C.Ink, 0.3), 1.4)
	B.vase(f, cf(-11.8, G, 0), C.Bruise:Lerp(C.Paper, 0.3), 1.2)
	B.lamp(f, "sconce", cf(12, G + 7.8, -6.75, "+z"), "Ground", { shade = C.Mustard, bright = 0.6, range = 12 })
	B.lamp(f, "sconce", cf(29, G + 7.8, 0.75, "-z"), "Ground", { shade = C.Mustard, bright = 0.6, range = 12 })
	-- portraits along the hall
	local pc = { C.Night, C.WoodDark:Lerp(C.Ink, 0.3), C.Bruise:Lerp(C.Ink, 0.5) }
	for i, x in { 7, 16, 21 } do
		B.picture(f, cf(x, G + 7.6, -6.75, "+z"), 1.8, 2.4, { portrait = true, canvas = pc[i], clothes = C.Ink, hair = C.Paper:Lerp(C.Ink, 0.3 * i), frame = if i == 2 then C.Brass else C.WoodDark })
	end
	for i, x in { 26, 40.5 } do
		B.picture(f, cf(x, G + 7.6, 0.75, "-z"), 2.4, 1.8, { scene = C.Mint:Lerp(C.Ink, 0.5), canvas = pc[i] })
	end
	B.node("Ground", -6, G, -3)
	B.node("Ground", 15, G, -3)
	B.node("Ground", 30, G, -3)
	B.node("Ground", 42, G, -3)
	for _, x in { -9, 10, 20, 31, 40 } do
		B.creak(x, G, -3 + ((x % 3) - 1) * 0.5)
	end
end

----------------------------------------------------------------- STAIR HALL
do
	local f = folder("StairHall")
	-- bench + boot tray under the landing
	B.rp(f, "Bench", cf(-2.5, G, 33.6, "-z"), V(5, 1.9, 1.6), V(0, 0.95, 0), C.WoodDark, M.Wood)
	B.rp(f, "Boots", cf(-4, G + 1.9, 33.6), V(1.2, 0.9, 0.8), V(0, 0.45, 0), C.Ink, M.Rubber, SM)
	B.loot("Ground", 1, V(-1.3, G + 1.92, 33.6))
	for i, z in { 7, 12.5, 18 } do
		B.picture(f, cf(0.75, G + 7.8, z, "-x"), 2.2, 2.8, { portrait = true, canvas = C.Night:Lerp(C.Bruise, 0.2 * i), clothes = C.Ink, hair = C.WoodDark, frame = C.WoodDark })
	end
	B.lamp(f, "sconce", cf(0.75, G + 8, 30, "-x"), "Ground", { shade = C.Rose, bright = 0.6, range = 12 })
	B.node("Ground", -2.5, G, 16)
	B.creak(-2.5, G, 8)
	B.creak(-3, G, 30)
end

----------------------------------------------------------------- BATHROOM (the SearchNode with Bathroom = true)
do
	local f = folder("Bathroom")
	-- clawfoot tub (CSG hollow) along the north wall
	local tb = cf(5, G, 11.2, "-z")
	local tub = B.rp(f, "Tub", tb, V(6, 2.4, 3.2), V(0, 1.7, 0), C.Paper, M.SmoothPlastic, { collide = true })
	local hole = B.cutter(V(5.4, 2.4, 2.6), tb * CFrame.new(0, 2.3, 0))
	B.csg("sub", tub, { hole }, { fid = Enum.CollisionFidelity.Box })
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			B.ball(f, "ClawFoot", tb, 0.45, V(sx * 2.5, 0.25, sz * 1.2), C.Brass, M.Metal, SM)
		end
	end
	B.box(f, "CurtainRod", 1.2, G + 9, 9.4, 8.3, G + 9.1, 9.5, C.Metal, M.Metal, SM)
	B.box(f, "ShowerCurtain", 1.3, G + 3.4, 9.35, 5.5, G + 9, 9.45, C.Rose:Lerp(C.Paper, 0.35), M.Fabric, { small = true, tr = 0.1 })
	B.loot("Ground", 1, (tb * CFrame.new(2.6, 2.9, 0)).Position)
	-- toilet
	local tt = cf(12, G, 4.5, "-x")
	B.rp(f, "Bowl", tt, V(1.4, 1.6, 2), V(0, 0.8, -0.3), C.Paper, M.SmoothPlastic)
	B.rp(f, "Seat", tt, V(1.6, 0.15, 2.1), V(0, 1.68, -0.35), C.Paper:Lerp(C.Mint, 0.3), M.SmoothPlastic, SM)
	B.rp(f, "Tank", tt, V(2, 2, 0.8), V(0, 2.4, 0.6), C.Paper, M.SmoothPlastic)
	B.cyl(f, "ToiletPaper", cf(12.6, G + 3, 7.2), 0.5, 0.6, V(0, 0, 0), C.Paper, M.Fabric, SM, false).CFrame = CFrame.new(12.6, G + 3, 7.2) * CFrame.Angles(0, math.rad(90), 0)
	-- pedestal sink (CSG basin) + medicine cabinet (Searchable)
	local sb = cf(1.9, G, 6.5, "+x")
	B.rp(f, "Pedestal", sb, V(0.8, 2.6, 0.8), V(0, 1.3, 0), C.Paper, M.SmoothPlastic)
	local basin = B.rp(f, "Basin", sb, V(2.4, 0.7, 1.6), V(0, 2.95, 0), C.Paper, M.SmoothPlastic, { collide = true })
	B.csg("sub", basin, { B.cutter(V(1.9, 0.6, 1.1), sb * CFrame.new(0, 3.2, -0.05)) }, { fid = Enum.CollisionFidelity.Box })
	B.rp(f, "Faucet", sb, V(0.15, 0.6, 0.15), V(0, 3.5, 0.65), C.Metal, M.Metal, SM)
	local mc = B.model(f, "MedicineCabinet")
	B.rp(mc, "Box", sb, V(2.2, 2.6, 0.6), V(0, 6.6, 0.55), C.Paper:Lerp(C.Ink, 0.1), M.Wood)
	local mirror = B.rp(mc, "MirrorDoor", sb, V(2, 2.4, 0.1), V(0, 6.6, 0.2), Color3.fromRGB(150, 160, 170), M.Glass, { refl = 0.35, collide = false })
	mirror.Name = "Cabinet"
	B.searchable(mirror, "Cabinet", "Ground", 1)
	B.loot("Ground", 1, (sb * CFrame.new(0.9, 3.3, -0.2)).Position)
	B.lamp(f, "sconce", cf(1.25, G + 8.7, 8.4, "+x"), "Ground", { shade = C.Paper, bright = 0.6, range = 12 })
	B.rug(f, 6.5, G + 0.02, 6, 3, 2, C.Mint:Lerp(C.Paper, 0.2))
	B.node("Ground", 7, G, 5, true)
end

----------------------------------------------------------------- STORAGE ROOM
do
	local f = folder("Storage")
	B.wardrobe(f, cf(11.1, G, 17, "-x"), C.WoodMid, "Ground", "Wardrobe", { name = "OldWardrobe" })
	B.bookshelf(f, cf(12.1, G, 28, "-x"), 7, 8, C.WoodRaw, { empty = true, name = "StorageShelf" })
	local boxCol = C.WoodLight:Lerp(C.Paper, 0.2)
	for i, p in { { 12, 0.38, 25.8 }, { 12, 0.38, 29.5 }, { 12, 2.23, 26.4 }, { 12, 4.08, 30.2 }, { 12, 5.93, 26.2 } } do
		B.rp(f, "Box", cf(p[1], G + p[2], p[3]), V(1.3, 1.5, 2.2 + (i % 2) * 0.6), V(0, 0.75, 0), boxCol:Lerp(C.Ink, (i % 3) * 0.1), M.Cardboard, SM)
	end
	local lid = B.rp(f, "ToolBox", cf(12, G + 2.23, 29.8, "-x"), V(1.2, 1.1, 2), V(0, 0.55, 0), C.Blood:Lerp(C.Ink, 0.3), M.Metal, { collide = false })
	lid.Name = "Cabinet"
	B.searchable(lid, "Cabinet", "Ground", 1)
	B.dresser(f, cf(2.1, G, 30, "+x"), 3.6, 1.8, 3.4, C.WoodDark, 3, "Ground", 1, { name = "OldDresser", search = { 2 } })
	B.loot("Ground", 1, V(2.1, G + 3.6, 30.8))
	B.loot("Ground", 1, V(12, G + 4.1, 27))
	B.rp(f, "Bicycle", cf(4, G, 16, 20), V(0.3, 2.6, 4.6), V(0, 1.3, 0), C.Mint:Lerp(C.Ink, 0.4), M.Metal)
	B.sheeted(f, cf(5, G, 33, "-z"), "tall", 0.9)
	B.node("Ground", 6.5, G, 23)
end

----------------------------------------------------------------- DEN (Grandpa's old sitting room)
do
	local f = folder("Den")
	B.rug(f, 34, G, 17, 12, 14, C.Mint:Lerp(C.Ink, 0.5), C.Mustard:Lerp(C.Ink, 0.5))
	-- upright piano on the west wall
	local pb = cf(24.4, G, 9, "+x")
	local pn = B.model(f, "Piano")
	B.rp(pn, "Body", pb, V(6, 4.8, 2), V(0, 2.4, 0.1), C.Ink:Lerp(C.WoodDark, 0.5), M.Wood)
	B.rp(pn, "Keybed", pb, V(5.6, 0.4, 1.2), V(0, 2.6, -1.4), C.Ink:Lerp(C.WoodDark, 0.5), M.Wood)
	B.rp(pn, "Keys", pb, V(5.3, 0.1, 0.9), V(0, 2.85, -1.45), C.Paper, M.SmoothPlastic, SM)
	B.rp(pn, "SheetMusic", pb, V(1.8, 1.2, 0.05), V(0, 3.9, -0.95), C.Paper:Lerp(C.Mustard, 0.2), M.SmoothPlastic, SM)
	B.rp(f, "PianoBench", cf(27.2, G, 9, "+x"), V(3.6, 1.9, 1.3), V(0, 0.95, 0), C.Ink:Lerp(C.WoodDark, 0.5), M.Wood)
	B.candleSet(pn, (pb * CFrame.new(-2.2, 4.8, 0.2)).Position, 2, 4)
	B.loot("Ground", 2, (pb * CFrame.new(1.5, 4.8, 0.3)).Position)
	B.picture(f, cf(23.25, G + 8.5, 9, "+x"), 3.4, 2.6, { portrait = true, canvas = C.Night, clothes = C.Ink, hair = C.Paper:Lerp(C.Ink, 0.5), frame = C.Brass, name = "GrandpaPortrait" })
	-- bookshelves + wardrobe (HidingSpot) on the west wall
	B.bookshelf(f, cf(24, G, 19.5, "+x"), 4.5, 9, C.WoodDark, { seed = 7 })
	B.bookshelf(f, cf(24, G, 24.3, "+x"), 4.5, 9, C.WoodDark, { seed = 11, gap = 2 })
	B.loot("Ground", 2, V(24.1, G + 4.58, 25.4))
	B.wardrobe(f, cf(24.95, G, 31.4, "+x"), C.WoodDark:Lerp(C.WoodMid, 0.4), "Ground", "Wardrobe", { name = "Armoire", w = 5 })
	-- recliner facing the radio cabinet
	B.armchair(f, cf(36, G, 21, 17), C.Mustard:Lerp(C.Ink, 0.45), "Recliner", { w = 4.6, d = 4.4, trim = C.WoodDark })
	local rb = cf(33.5, G, 12.6, -163)
	local rc = B.model(f, "RadioCabinet")
	B.rp(rc, "Body", rb, V(4, 3.4, 1.8), V(0, 1.7, 0), C.WoodMid, M.Wood)
	B.rp(rc, "Grille", rb, V(3, 1.8, 0.05), V(0, 1.5, -0.92), C.Mustard:Lerp(C.Ink, 0.5), M.Fabric, SM)
	B.rp(rc, "Dial", rb, V(1.8, 0.5, 0.05), V(0, 2.9, -0.92), Color3.fromRGB(230, 190, 120), M.Neon, SM)
	B.loot("Ground", 2, (rb * CFrame.new(0.8, 3.4, 0)).Position)
	-- writing desk between the east windows (Searchable drawer)
	B.dresser(f, cf(43.9, G, 18, "-x"), 5, 2.2, 3, C.WoodDark, 2, "Ground", 2, { name = "WritingDesk", search = { 1 } })
	B.lamp(f, "table", cf(44, G + 3.2, 16.4), "Ground", { shade = C.Mint, body = C.Brass, bright = 0.8 })
	B.loot("Ground", 2, V(43.8, G + 3.22, 19.2))
	-- card table with an unfinished puzzle
	B.table(f, cf(35, G, 29), 4, 4, 2.9, C.WoodMid, { name = "CardTable" })
	B.rp(f, "Puzzle", cf(35, G + 2.9, 29), V(3, 0.06, 2.4), V(0, 0.03, 0), C.Mint:Lerp(C.Mustard, 0.4), M.Cardboard, SM)
	B.chair(f, cf(35, G, 31.8, "-z"), C.WoodDark)
	B.loot("Ground", 2, V(36, G + 2.95, 28.5))
	B.vase(f, cf(29.4, G, 2.6), C.Mustard:Lerp(C.Ink, 0.35), 1.3)
	B.node("Ground", 34, G, 7)
	B.node("Ground", 32, G, 25)
	B.creak(34, G, 4.5)
	B.creak(42, G, 9)
end

----------------------------------------------------------------- BASEMENT STAIR ROOM (landing lamp + node)
do
	local f = B.F("BasementStairs", B.F("Basement"))
	B.lamp(f, "bare", cf(18, 14, 3), "Basement", { drop = 3.5, bright = 0.6, range = 14 })
	B.node("Basement", 18, B.FL.Basement, 31.5)
end
return "ground B ok, parts=" .. B.count(B.root())
