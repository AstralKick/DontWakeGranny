-- Basement (Area Basement, Danger 3) and Attic (Area Attic, Danger 3). Requires 00..07.
local B = _G.HB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local BS = B.FL.Basement
local AT = B.FL.Attic
local BF = B.F("Basement")
local AF = B.F("Attic")
local SM = { small = true }

B.room("Basement Hall", "Basement", 3, -13, BS, 0, 13, 1, 35)
B.room("Canning Cellar", "Basement", 3, -45, BS, 0, -13, 1, 35)
B.room("Grandpa's Workshop", "Basement", 3, -45, BS, -35, -13, 1, 0)
B.room("Furnace Room", "Basement", 3, -13, BS, -35, 23, 1, 0)
B.room("The Shrine", "Basement", 3, 23, BS, -35, 45, 1, -15)
B.room("Attic Storage", "Attic", 3, -45, AT, -25.4, 0, 48, 25.4)
B.room("Attic Gallery", "Attic", 3, 0, AT, -25.4, 45, 48, 25.4)

local jarCols = { C.Blood:Lerp(C.Ink, 0.3), C.Mustard:Lerp(C.Ink, 0.2), C.Mint:Lerp(C.Ink, 0.35), C.Rose:Lerp(C.Ink, 0.2), C.Bruise }
-- jar shelf: bookshelf frame + jars, leaving one free slot per shelf for loot (returns loot positions)
local function jarShelf(par, b, w, h, seed)
	B.bookshelf(par, b, w, h, C.WoodRaw:Lerp(C.Ink, 0.3), { empty = true, name = "JarShelf" })
	local n = 4
	local slots = {}
	for s = 0, n - 1 do
		local top = 0.3 + (h - 0.6) * s / n + 0.075
		local count = math.floor((w - 0.8) / 0.75)
		local free = (seed + s) % count
		for j = 0, count - 1 do
			local lx = -w / 2 + 0.55 + j * 0.75
			local p = (b * CFrame.new(lx, top, 0.1)).Position
			if j == free then
				table.insert(slots, p)
			else
				B.jar(par, p, jarCols[(seed + s * 3 + j) % #jarCols + 1], if (j + s) % 3 == 0 then 1.25 else 1)
			end
		end
	end
	return slots
end

----------------------------------------------------------------- BASEMENT HALL
do
	local f = B.F("BasementHall", BF)
	B.lamp(f, "bare", cf(0, 1, 18), "Basement", { drop = 2.2, bright = 0.8, range = 18, shadows = true })
	-- water heater, chest freezer (Searchable Fridge), paint shelf, metal locker (HidingSpot)
	B.cyl(f, "WaterHeater", cf(-10.5, BS, 32.5), 2.6, 6, V(0, 3, 0), C.Metal:Lerp(C.Paper, 0.3), M.Metal, { collide = true }, true)
	B.cyl(f, "Pipe", cf(-10.5, BS + 6, 32.5), 0.4, 6, V(0, 3, 0), C.Brass:Lerp(C.Ink, 0.3), M.Metal, SM, true)
	local fz = B.model(f, "ChestFreezer")
	local fb = cf(-9.5, BS, 12, "+x")
	B.rp(fz, "Body", fb, V(5, 3, 2.6), V(0, 1.5, 0), C.Paper:Lerp(C.Ink, 0.15), M.SmoothPlastic)
	local lid = B.rp(fz, "FreezerLid", fb, V(5.1, 0.35, 2.7), V(0, 3.15, 0), C.Paper:Lerp(C.Ink, 0.1), M.SmoothPlastic)
	B.searchable(lid, "Fridge", "Basement", 3)
	B.rp(fz, "Handle", fb, V(1.6, 0.2, 0.2), V(0, 2.9, -1.4), C.Metal, M.Metal, SM)
	B.loot("Basement", 3, (fb * CFrame.new(1.4, 3.35, 0)).Position)
	local sl = jarShelf(f, cf(0, BS, 34.1, "-z"), 6, 7, 2)
	B.loot("Basement", 3, sl[2])
	B.wardrobe(f, cf(11.1, BS, 10, "-x"), C.Metal:Lerp(C.Mint, 0.25), "Basement", "Cabinet", { name = "MetalLocker", w = 4.4, h = 8.2, louvre = true })
	-- pipes along the ceiling
	B.box(f, "CeilingPipe", -13, -0.2, 26.6, 13, 0.3, 27.1, C.Metal:Lerp(C.Brass, 0.3), M.Metal, SM)
	B.box(f, "CeilingPipe", 6.6, -0.2, 0, 7.1, 0.3, 35, C.Metal:Lerp(C.Brass, 0.3), M.Metal, SM)
	for i, p in { { -4, 24 }, { -1.8, 24.2 }, { -2.9, 24.1 } } do
		B.rp(f, "Box", cf(p[1], BS + (if i == 3 then 1.6 else 0), p[2], i * 17), V(2, 1.6, 1.8), V(0, 0.8, 0), C.WoodLight:Lerp(C.Paper, 0.1), M.Cardboard)
	end
	B.loot("Basement", 3, V(-2.9, BS + 3.22, 24.1))
	B.node("Basement", 0, BS, 6)
	B.node("Basement", 4, BS, 28)
	B.pumpkin("Basement", V(6, BS, 18))
end

----------------------------------------------------------------- CANNING CELLAR
do
	local f = B.F("CanningCellar", BF)
	B.box(f, "CellarFloor", -45, BS - 0.1, 0, -13, BS + 0.03, 35, C.Stone:Lerp(C.Dirt, 0.4), M.Cobblestone, { solid = true })
	local slots = {}
	for _, spec in { { -44.1, 6, "+x" }, { -44.1, 13, "+x" }, { -44.1, 20, "+x" }, { -44.1, 27, "+x" } } do
		for _, p in jarShelf(f, cf(spec[1], BS, spec[2], spec[3]), 6.4, 8, math.floor(spec[2])) do table.insert(slots, p) end
	end
	for _, spec in { { -38, 34.1 }, { -30.5, 34.1 }, { -23, 34.1 } } do
		for _, p in jarShelf(f, cf(spec[1], BS, spec[2], "-z"), 6.4, 8, math.floor(-spec[1])) do table.insert(slots, p) end
	end
	for i, idx in { 2, 7, 11, 16, 22, 26 } do
		if slots[idx] then B.loot("Basement", 3, slots[idx]) end
	end
	-- potato bin + big pantry cabinet (Searchable + HidingSpot) + stool
	B.rp(f, "PotatoBin", cf(-24, BS, 2.5, "+z"), V(5, 2.4, 3), V(0, 1.2, 0), C.WoodRaw:Lerp(C.Ink, 0.3), M.WoodPlanks)
	for i = 1, 5 do
		B.ball(f, "Potato", cf(-26 + i * 0.7, BS + 2.4, 2.5 + (i % 2) * 0.5), 0.6, V(0, 0, 0), C.Dirt:Lerp(C.Mustard, 0.3), M.Slate, SM)
	end
	B.wardrobe(f, cf(-15.1, BS, 8, "-x"), C.WoodRaw:Lerp(C.Ink, 0.2), "Basement", "Cabinet", { name = "CellarCabinet", w = 4.8, h = 8.6 })
	local cd = B.rp(f, "Cabinet", cf(-14.8, BS, 30, "-x"), V(4, 3.2, 2.2), V(0, 1.6, 0), C.WoodRaw:Lerp(C.Ink, 0.1), M.Wood)
	B.searchable(cd, "Cabinet", "Basement", 3)
	B.loot("Basement", 3, V(-14.8, BS + 3.25, 30.6))
	B.rp(f, "Stool", cf(-30, BS, 16), V(1.4, 2, 1.4), V(0, 1, 0), C.WoodRaw, M.Wood)
	B.lamp(f, "bare", cf(-29, 1, 17), "Basement", { drop = 2.5, bright = 0.7, range = 18 })
	B.cobweb(f, V(-44, -0.5, 34), 45, 1)
	B.cobweb(f, V(-14, -0.5, 34), -45, 0.8)
	B.node("Basement", -30, BS, 10)
	B.node("Basement", -30, BS, 25)
end

----------------------------------------------------------------- GRANDPA'S WORKSHOP
do
	local f = B.F("Workshop", BF)
	local wb = cf(-43.6, BS, -18, "+x")
	B.table(f, wb, 12, 2.8, 3.4, C.WoodRaw, { name = "Workbench" })
	B.rp(f, "Pegboard", wb, V(12, 5, 0.2), V(0, 6.5, 1.3), C.WoodLight:Lerp(C.Paper, 0.2), M.Cardboard, { small = true })
	local tools = { { -4.5, 7.5, 0.3, 2.4 }, { -3, 7, 1.4, 0.3 }, { -1, 7.4, 0.25, 2 }, { 0.5, 6.8, 1.2, 1.2 }, { 2.4, 7.3, 0.25, 2.6 }, { 4, 7, 1.6, 0.35 } }
	for _, t in tools do
		B.rp(f, "Tool", wb, V(t[3], t[4], 0.15), V(t[1], t[2], 1.1), C.Ink:Lerp(C.Metal, 0.4), M.Metal, SM)
	end
	B.rp(f, "Vise", wb, V(1, 0.8, 1.2), V(4.8, 3.8, -0.6), C.Mint:Lerp(C.Ink, 0.4), M.Metal, SM)
	B.rp(f, "Clamp", wb, V(0.3, 1, 0.8), V(-2, 3.9, -0.3), C.Blood:Lerp(C.Ink, 0.3), M.Metal, SM)
	B.loot("Basement", 3, (wb * CFrame.new(-3.5, 3.42, -0.4)).Position)
	B.loot("Basement", 3, (wb * CFrame.new(1.8, 3.42, -0.2)).Position)
	B.lamp(f, "table", cf(-44, BS + 3.4, -22.5), "Basement", { shade = C.Mint:Lerp(C.Ink, 0.3), body = C.Metal, bright = 0.9, range = 14 })
	-- tool chest (Searchable drawers)
	B.dresser(f, cf(-35, BS, -34, "+z"), 4, 2, 4, C.Blood:Lerp(C.Ink, 0.3), 5, "Basement", 3, { name = "ToolChest", search = { 1, 4 } })
	B.loot("Basement", 3, V(-35.8, BS + 4.22, -34))
	-- lumber stack, saw horses, old radio shelf
	for i = 0, 3 do
		B.box(f, "Lumber", -28, BS + i * 0.5, -33.8 + (i % 2) * 0.2, -16, BS + 0.45 + i * 0.5, -32.8 + (i % 2) * 0.2, C.WoodLight:Lerp(C.WoodRaw, (i % 2) * 0.5), M.Wood)
	end
	for _, x in { -27, -21 } do
		B.rp(f, "SawHorse", cf(x, BS, -22), V(0.5, 2.6, 3), V(0, 1.3, 0), C.WoodRaw, M.Wood)
	end
	B.box(f, "SawBoard", -28, BS + 2.6, -22.6, -20, BS + 2.9, -21.4, C.WoodLight, M.Wood, {})
	B.loot("Basement", 3, V(-24.5, BS + 2.92, -22))
	B.bookshelf(f, cf(-39, BS, -0.9, "-z"), 5, 7, C.WoodRaw, { empty = true, name = "CanShelf" })
	for s = 0, 2 do
		for j = 0, 3 do
			B.cyl(f, "PaintCan", cf(-40.8 + j * 1.2, BS + 0.38 + s * 1.6, -1.1), 0.8, 0.9, V(0, 0.45, 0), jarCols[(s + j) % 5 + 1]:Lerp(C.Metal, 0.4), M.Metal, SM, true)
		end
	end
	B.node("Basement", -30, BS, -12)
	B.node("Basement", -22, BS, -28)
end

----------------------------------------------------------------- FURNACE ROOM (warm orange SurfaceLight)
do
	local f = B.F("FurnaceRoom", BF)
	local fb = cf(5, BS, -26, "+z")
	local fm = B.model(f, "Furnace")
	B.rp(fm, "Body", fb, V(8, 6.5, 6), V(0, 3.25, 0), C.Metal:Lerp(C.Ink, 0.35), M.Metal)
	B.rp(fm, "Plinth", fb, V(8.6, 0.6, 6.6), V(0, 0.3, 0), C.Ink, M.Concrete, SM)
	local grille = B.rp(fm, "Grille", fb, V(3.4, 1.4, 0.2), V(0, 1.8, -3.05), Color3.fromRGB(255, 120, 40), M.Neon, SM)
	local sl = Instance.new("SurfaceLight")
	sl.Face = Enum.NormalId.Front
	sl.Color = Color3.fromRGB(255, 130, 60)
	sl.Brightness = 2.2
	sl.Range = 22
	sl.Angle = 120
	sl.Shadows = true
	sl.Parent = grille
	for i = -1, 1 do
		B.rp(fm, "Bar", fb, V(0.15, 1.5, 0.1), V(i * 0.9, 1.8, -3.18), C.Ink, M.Metal, SM)
	end
	B.rp(fm, "Door", fb, V(2.4, 1.8, 0.15), V(0, 4.3, -3.08), C.Ink:Lerp(C.Metal, 0.2), M.Metal, SM)
	-- octopus ducts to the ceiling
	for i, a in { -50, -15, 20, 55 } do
		local base = fb * CFrame.new(math.sin(math.rad(a)) * 2.5, 6.5, math.cos(math.rad(a)) * 1.5)
		local p = B.part(fm, "Duct", V(1.4, 6, 1.4), base * CFrame.new(0, 2, 0) * CFrame.Angles(math.rad(math.cos(math.rad(a)) * 20), 0, math.rad(-math.sin(math.rad(a)) * 35)), C.Metal:Lerp(C.Paper, 0.2), M.Metal, { small = true, shape = Enum.PartType.Cylinder })
		p.Size = V(6.2, 1.4, 1.4)
		p.CFrame = base * CFrame.Angles(math.rad(math.cos(math.rad(a)) * 20), 0, math.rad(-math.sin(math.rad(a)) * 35)) * CFrame.new(0, 3.1, 0) * CFrame.Angles(0, 0, math.rad(90))
	end
	-- oil tank, coal bin, shelf
	B.cyl(f, "OilTank", cf(-8, BS + 2.5, -31.5), 4.5, 9, V(0, 0, 0), C.Mint:Lerp(C.Ink, 0.55), M.Metal, { collide = true }, false)
	B.rp(f, "CoalBin", cf(18, BS, -31, "-x"), V(6, 3, 4.5), V(0, 1.5, 0), C.WoodRaw:Lerp(C.Ink, 0.4), M.WoodPlanks)
	B.rp(f, "Coal", cf(18, BS + 2.6, -31), V(4, 0.5, 5.4), V(0, 0.25, 0), C.Ink, M.Slate, SM)
	B.rp(f, "Shovel", cf(15, BS, -28.6, 20), V(0.2, 4.4, 0.8), V(0, 2.2, 0), C.Metal, M.Metal, SM)
	local mc = B.rp(f, "Cabinet", cf(-12, BS, -8, "+x"), V(4, 6, 1.8), V(0, 3, 0), C.Metal:Lerp(C.Mint, 0.3), M.Metal)
	B.searchable(mc, "Cabinet", "Basement", 3)
	B.loot("Basement", 3, V(-12, BS + 6.05, -8))
	B.table(f, cf(19.5, BS, -5), 5, 2.5, 3.2, C.WoodRaw:Lerp(C.Ink, 0.2), { name = "OldTable" })
	B.loot("Basement", 3, V(18.5, BS + 3.22, -5))
	B.rp(f, "Radio", cf(21, BS + 3.2, -5, "-z"), V(1.6, 1.1, 0.9), V(0, 0.55, 0), C.WoodMid, M.Wood, SM)
	B.prize("Basement", V(5, BS, -21.3))
	B.node("Basement", 0, BS, -14)
	B.node("Basement", 14, BS, -18)
	B.node("Basement", -6, BS, -22)
end

----------------------------------------------------------------- THE SHRINE (PrizeSpawn)
do
	local f = B.F("Shrine", BF)
	B.rug(f, 36, BS, -25, 10, 12, C.Blood:Lerp(C.Ink, 0.55), C.Ink)
	-- altar table against the east wall
	local ab = cf(43.6, BS, -25, "-x")
	local al = B.model(f, "Altar")
	B.rp(al, "Top", ab, V(6, 0.3, 2.4), V(0, 3, 0), C.WoodDark, M.Wood)
	B.rp(al, "Cloth", ab, V(6.2, 2.4, 2.5), V(0, 1.9, 0), C.Paper:Lerp(C.Mustard, 0.25), M.Fabric)
	local dr = B.rp(al, "AltarDrawer", ab, V(2.2, 0.5, 0.12), V(0, 2.55, -1.3), C.WoodDark, M.Wood, { collide = false })
	B.searchable(dr, "Drawer", "Basement", 3)
	B.candleSet(al, (ab * CFrame.new(-2.2, 3.15, 0.3)).Position, 5, 3)
	B.candleSet(al, (ab * CFrame.new(2.3, 3.15, 0.4)).Position, 4, 7)
	B.lamp(al, "candle", ab * CFrame.new(0, 3.15, 0.6), "Basement", { h = 1.4, bright = 1.2, range = 14, color = Color3.fromRGB(255, 150, 80) })
	B.prize("Basement", (ab * CFrame.new(0.2, 3.17, -0.35)).Position)
	B.loot("Basement", 3, (ab * CFrame.new(-1.4, 3.17, -0.6)).Position)
	-- photos pinned to the wall above the altar, a framed portrait in the centre
	B.picture(f, ab * CFrame.new(0, 7.2, 1.4), 2.4, 3, { portrait = true, canvas = C.Night, clothes = C.Ink, hair = C.Paper:Lerp(C.Ink, 0.4), frame = C.Brass, name = "ShrinePortrait" })
	for i = 1, 11 do
		local x = ((i * 37) % 11) / 11 * 7 - 3.5
		local y = 5 + ((i * 23) % 7) / 7 * 4.5
		if math.abs(x) > 1.4 or y > 9 then
			B.part(f, "Photo", V(0.05, 0.9, 0.7), CFrame.new(44.93, BS + y, -25 + x) * CFrame.Angles(math.rad((i * 13) % 20 - 10), 0, 0), C.Paper:Lerp(C.Mustard, 0.2 + (i % 3) * 0.1), M.SmoothPlastic, SM)
			B.part(f, "PhotoImage", V(0.05, 0.6, 0.5), CFrame.new(44.9, BS + y + 0.05, -25 + x) * CFrame.Angles(math.rad((i * 13) % 20 - 10), 0, 0), C.Night:Lerp(C.Bruise, (i % 4) * 0.2), M.SmoothPlastic, SM)
		end
	end
	B.doll(f, ab * CFrame.new(2.4, 3.15, -0.4) * CFrame.Angles(0, math.rad(20), 0), 0.9, C.Paper:Lerp(C.Blood, 0.2))
	B.rp(f, "DriedFlowers", ab * CFrame.new(-2.6, 3.15, 0.5), V(0.8, 1.4, 0.8), V(0, 0.7, 0), C.WoodDark:Lerp(C.Bruise, 0.4), M.Fabric, SM)
	-- an empty chair facing the altar
	B.chair(f, cf(36.5, BS, -25, "+x"), C.WoodDark, { cushion = C.Blood:Lerp(C.Ink, 0.4) })
	B.cobweb(f, V(44, -0.5, -34), 135, 1)
	B.cobweb(f, V(24, -0.5, -16), -45, 0.9)
	B.node("Basement", 34, BS, -20)
	B.loot("Basement", 3, V(25.5, BS + 3.22, -33))
	B.table(f, cf(25.5, BS, -33), 2.4, 2, 3.2, C.WoodDark, { name = "SmallTable" })
end

----------------------------------------------------------------- ATTIC
do
	local f = AF
	-- knee walls and a timber partition (posts + a hanging sheet) between storage and gallery
	for _, z in { -25.6, 25.6 } do
		B.box(f, "KneeWall", -45, AT, z - 0.2, 45, 33.3, z + 0.2, C.WoodRaw:Lerp(C.Ink, 0.25), M.WoodPlanks, { solid = true })
	end
	for _, x in { -30, -15, 15, 30 } do
		B.box(f, "KingPost", x - 0.4, AT, -0.4, x + 0.4, 47.6, 0.4, C.WoodRaw:Lerp(C.Ink, 0.3), M.Wood, { solid = true })
	end
	B.box(f, "RidgeBeam", -45, 46.6, -0.5, 45, 47.6, 0.5, C.WoodRaw:Lerp(C.Ink, 0.3), M.Wood, SM)
	for _, z in { -14, 14 } do
		B.box(f, "PartitionPost", -0.4, AT, z - 0.4, 0.4, 28 + 20 * (35 - math.abs(z)) / 35 - 0.3, z + 0.4, C.WoodRaw:Lerp(C.Ink, 0.3), M.Wood, { solid = true })
	end
	B.box(f, "SheetRope", -0.1, 38.5, -16, 0.1, 38.6, 16, C.Paper:Lerp(C.Ink, 0.3), M.Fabric, SM)
	B.part(f, "HangingSheet", V(0.1, 7.5, 5), CFrame.new(0, 34.7, -9) * CFrame.Angles(0, math.rad(4), 0), C.Sheet, M.Fabric, { small = true, tr = 0.1 })
	B.part(f, "HangingSheet", V(0.1, 7.5, 4.5), CFrame.new(0.2, 34.7, 9.5) * CFrame.Angles(0, math.rad(-6), 0), C.Sheet, M.Fabric, { small = true, tr = 0.1 })
	-- hanging bulbs (Lamps)
	B.lamp(f, "bare", cf(-22, 44.4, 0), "Attic", { drop = 5, bright = 0.7, range = 22, shadows = true })
	B.lamp(f, "bare", cf(22, 44.4, 0), "Attic", { drop = 5, bright = 0.6, range = 22 })
	-- storage half: trunks (Searchable Trunk), sheeted furniture, wardrobe (HidingSpot)
	B.trunk(f, cf(-38, AT, -19.5, "+z"), C.Rose:Lerp(C.Ink, 0.45), "Attic", 3)
	B.trunk(f, cf(-26, AT, 19.8, "-z"), C.Mint:Lerp(C.Ink, 0.5), "Attic", 3, { w = 4 })
	B.trunk(f, cf(-8, AT, -19.8, "+z"), C.WoodMid, "Attic", 3)
	B.prize("Attic", V(-35.2, AT, -19.4))
	B.prize("Attic", V(39, AT, 3.4))
	B.loot("Attic", 3, V(-38.8, AT + 2.18, -19.5))
	B.loot("Attic", 3, V(-8, AT + 2.18, -19.8))
	B.loot("Attic", 3, V(-19, AT + 1.62, 20.6))
	B.loot("Attic", 3, V(-26, AT + 2.18, 19.8))
	B.wardrobe(f, cf(-43.1, AT, -8, "+x"), C.WoodDark, "Attic", "Wardrobe", { name = "AtticWardrobe", h = 8 })
	B.sheeted(f, cf(-34, AT, 8, 160), "chair")
	B.sheeted(f, cf(-18, AT, -10, 20), "tall")
	B.sheeted(f, cf(-12, AT, 12, "+z"), "table", 0.9)
	B.sheeted(f, cf(-40, AT, 18, "+x"), "chair", 0.9)
	B.loot("Attic", 3, V(-12, AT + 2.85, 12))
	for i, p in { { -30, -20.5 }, { -28.2, -21 }, { -29.2, -20.6 }, { -20, 20.5 }, { -18.2, 20.8 } } do
		B.rp(f, "Box", cf(p[1], AT + (if i == 3 then 1.6 else 0), p[2], i * 23), V(2, 1.6, 1.8), V(0, 0.8, 0), C.WoodLight:Lerp(C.Paper, 0.1 * (i % 3)), M.Cardboard)
	end
	B.loot("Attic", 3, V(-29.2, AT + 3.22, -20.6))
	B.rp(f, "Crib", cf(-36, AT, 20, "-z"), V(4, 3, 2.4), V(0, 1.5, 0), C.Paper:Lerp(C.Ink, 0.3), M.Wood)
	B.doll(f, cf(-36, AT + 3, 20, "+z"), 1, C.Bruise:Lerp(C.Paper, 0.3))
	-- gallery half: portraits on easels and leaning on the knee walls, rocking chair facing the round window
	local canv = { C.Night, C.Bruise:Lerp(C.Ink, 0.5), C.WoodDark:Lerp(C.Ink, 0.3), C.Blood:Lerp(C.Ink, 0.6) }
	for i, x in { 6, 12, 18, 31, 37, 42 } do
		local lean = CFrame.new(x, AT + 1.6, -24.9) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(math.rad(12), 0, 0)
		B.picture(f, lean, 2.2 + (i % 2) * 0.6, 3 + (i % 3) * 0.4, { portrait = true, canvas = canv[i % 4 + 1], clothes = C.Ink, hair = C.Paper:Lerp(C.Ink, 0.2 * (i % 4)), frame = if i % 2 == 0 then C.Brass else C.WoodDark })
	end
	for i, x in { 5, 11, 32, 38, 43 } do
		local lean = CFrame.new(x, AT + 1.6, 24.9) * CFrame.Angles(math.rad(12), 0, 0)
		B.picture(f, lean, 2.4, 3.2, { portrait = true, canvas = canv[(i + 1) % 4 + 1], clothes = C.Ink:Lerp(C.Bruise, 0.3), hair = C.Paper:Lerp(C.Ink, 0.2 * (i % 4)), frame = if i % 2 == 1 then C.Brass else C.WoodDark })
	end
	-- easel with an unfinished portrait of Grandma
	local eb = cf(8, AT, 2, 200)
	local em = B.model(f, "Easel")
	for _, sx in { -1, 1 } do
		B.rp(em, "Leg", eb, V(0.2, 6, 0.2), V(sx * 1, 3, 0), C.WoodRaw, M.Wood, SM)
	end
	B.rp(em, "BackLeg", eb, V(0.2, 6, 0.2), V(0, 2.9, 1), C.WoodRaw, M.Wood, SM)
	B.rp(em, "Ledge", eb, V(2.6, 0.2, 0.6), V(0, 2.4, -0.2), C.WoodRaw, M.Wood, SM)
	B.picture(em, eb * CFrame.new(0, 4, -0.1), 2.4, 3, { portrait = true, canvas = C.Paper:Lerp(C.Mustard, 0.2), clothes = C.Rose, hair = C.Paper:Lerp(C.Ink, 0.2), frame = C.WoodRaw, name = "UnfinishedPortrait" })
	B.loot("Attic", 3, (eb * CFrame.new(0.6, 2.52, -0.2)).Position)
	B.rocker(f, cf(39, AT, 0, "+x"), C.WoodDark)
	B.trunk(f, cf(28, AT, 19.8, "-z"), C.Bruise:Lerp(C.Ink, 0.4), "Attic", 3)
	B.rp(f, "Crate", cf(35.5, AT, -18.5, 10), V(2.2, 1.8, 2.2), V(0, 0.9, 0), C.WoodRaw:Lerp(C.Ink, 0.2), M.WoodPlanks)
	B.loot("Attic", 3, V(35.5, AT + 1.82, -18.5))
	B.wardrobe(f, cf(43.1, AT, 12.5, "-x"), C.WoodDark:Lerp(C.Rose, 0.15), "Attic", "Cabinet", { name = "OldArmoire", w = 4.6, h = 7.8 })
	B.sheeted(f, cf(34, AT, -14, "+z"), "tall", 0.9)
	B.lamp(f, "candle", cf(28, AT + 2.2, 19.6), "Attic", { h = 0.6, bright = 0.8, range = 10 })
	-- cobwebs in the rafters
	for i, p in { { -42, 36, -20, 30 }, { -20, 41, 12, -40 }, { 10, 40, -14, 60 }, { 40, 36, 18, -30 }, { 0, 44, 5, 80 } } do
		B.cobweb(f, V(p[1], p[2], p[3]), p[4], 1.2)
	end
	B.node("Attic", -30, AT, 0)
	B.node("Attic", -10, AT, 8)
	B.node("Attic", 10, AT, -8)
	B.node("Attic", 34, AT, 6)
	B.pumpkin("Attic", V(-22, AT, 6))
	for _, p in { { -22, -8 }, { 6, -8 }, { 28, 4 } } do
		B.creak(p[1], AT, p[2])
	end
end
return "basement+attic ok, parts=" .. B.count(B.root())
