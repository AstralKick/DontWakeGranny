-- Interior walls, exterior inner skins + window dressing, arches (CSG), doors, floor overlays. Requires 00/01/02.
local B = _G.HB
local C, M = B.C, B.M
local V = Vector3.new
local S = B.F("Structure")
local FL = B.FL
local Sage = Color3.fromRGB(146, 156, 132)
local RC = { -- room wall colours
	Dining = C.WMint, Entry = C.WMustard, Living = C.WRose, Kitchen = C.WPaper, Hall = C.WMustard, Stair = C.WPlum,
	Laundry = Sage, Bath = C.WMint, Storage = C.WPaper, BStair = C.WNight, Den = C.WTeal,
	Sewing = C.WMustard, Kids = C.WMint, Grandma = C.WRose, UHall = C.WPlum, Guest = C.WPaper, Landing = C.WPlum,
	UBath = C.WMint, Linen = C.WPaper, AStair = C.WNight, Study = C.WTeal,
}
B.RC = RC
local W = { wain = true }
local FAB = { mat = M.Fabric }
local TILE = { wain = true, trimColor = C.Tile }

----------------------------------------------------------------- exterior inner skins + windows
local SIDES = {
	front = { axis = "x", fixed = -35.25, glass = -35.5, sign = 1 },
	back = { axis = "x", fixed = 35.25, glass = 35.5, sign = -1 },
	left = { axis = "z", fixed = -45.25, glass = -45.5, sign = 1 },
	right = { axis = "z", fixed = 45.25, glass = 45.5, sign = -1 },
}
local WH = B.WH
local function inner(side, fl, a, b, color, curtain, o, extra)
	local sd = SIDES[side]
	local y0 = FL[fl]
	local gaps = {}
	local par = B.F(fl)
	for _, c in B.WIN[side][fl] do
		if c > a and c < b then
			table.insert(gaps, { c = c, w = WH.w, sill = WH.sill, h = WH.h })
			B.window(par, sd.axis, sd.glass, c, y0, 3.5, 9, 4, 1, sd.sign, curtain)
		end
	end
	for _, g in extra or {} do table.insert(gaps, g) end
	o = o or {}
	B.skin(par, "Wall", sd.axis, sd.fixed, a, b, y0, y0 + 12, 0.5, color, o.mat or M.Plaster, gaps, sd.sign, o)
end
-- ground
inner("front", "Ground", -45, -13, RC.Dining, C.Rose)
inner("front", "Ground", -13, 3, RC.Entry, nil, W, { { c = -5, w = 4.5, h = 8 }, { c = -8.4, w = 1.2, sill = 1, h = 7.5 }, { c = -1.6, w = 1.2, sill = 1, h = 7.5 } })
inner("front", "Ground", 3, 45, RC.Living, C.Mustard)
inner("back", "Ground", -45, -13, RC.Laundry, C.Paper)
inner("back", "Ground", -13, 1, RC.Stair, nil, W)
inner("back", "Ground", 1, 13, RC.Storage)
inner("back", "Ground", 23, 45, RC.Den, C.Bruise)
inner("left", "Ground", -35, -7, RC.Dining, C.Rose)
inner("left", "Ground", -7, 21, RC.Kitchen, C.Mint)
inner("left", "Ground", 21, 35, RC.Laundry, C.Paper)
inner("right", "Ground", -35, -7, RC.Living, C.Mustard)
inner("right", "Ground", -7, 1, RC.Hall, nil, W)
inner("right", "Ground", 1, 35, RC.Den, C.Bruise)
-- upstairs
inner("front", "Upstairs", -45, -13, RC.Sewing, C.Mint)
inner("front", "Upstairs", -13, 13, RC.Kids, C.Rose)
inner("front", "Upstairs", 13, 45, RC.Grandma, C.Bruise, FAB)
inner("back", "Upstairs", -45, -13, RC.Guest, C.Mustard)
inner("back", "Upstairs", -13, 1, RC.Landing, nil, W)
inner("back", "Upstairs", 1, 13, RC.Linen)
inner("back", "Upstairs", 13, 27, RC.AStair)
inner("back", "Upstairs", 27, 45, RC.Study, C.Rose)
inner("left", "Upstairs", -35, -7, RC.Sewing, C.Mint)
inner("left", "Upstairs", -7, 1, RC.UHall, nil, W)
inner("left", "Upstairs", 1, 35, RC.Guest, C.Mustard)
inner("right", "Upstairs", -35, -7, RC.Grandma, C.Bruise, FAB)
inner("right", "Upstairs", -7, 1, RC.UHall, nil, W)
inner("right", "Upstairs", 1, 35, RC.Study, C.Rose)
-- basement stair room back wall spans basement..ground
B.skin(B.F("Basement"), "Wall", "x", 34.75, 13, 23, FL.Basement, 1, 0.5, C.Concrete, M.Concrete, {}, -1, { nobase = true })
inner("back", "Ground", 13, 23, RC.BStair)

----------------------------------------------------------------- interior walls
local G, U, BS = FL.Ground, FL.Upstairs, FL.Basement
local function wall(fl, axis, fixed, a, b, cn, cp, gaps, on, op, y0, y1)
	local y = y0 or FL[fl]
	B.iwall(B.F(fl), axis, fixed, a, b, y, y1 or (y + 12), cn, cp, gaps, on, op)
end
-- ground floor
wall("Ground", "z", -13, -35, -7, RC.Dining, RC.Entry, { { c = -21, w = 4.5 } }, {}, W)
wall("Ground", "z", 3, -35, -7, RC.Entry, RC.Living, { { c = -22, w = 10, h = 12, trim = false } }, W, {})
wall("Ground", "x", -7, -45, -13, RC.Dining, RC.Kitchen, { { c = -30, w = 4.5 } })
wall("Ground", "x", -7, -13, 3, RC.Entry, RC.Hall, { { c = -5, w = 8, h = 12, trim = false } }, W, W)
wall("Ground", "x", -7, 3, 45, RC.Living, RC.Hall, { { c = 36, w = 4.5 } }, {}, W)
wall("Ground", "z", -13, -7, 1, RC.Kitchen, RC.Hall, { { c = -3, w = 4.5 } }, {}, W)
wall("Ground", "z", -13, 1, 21, RC.Kitchen, RC.Stair, {}, {}, W)
wall("Ground", "x", 21, -45, -13, RC.Kitchen, RC.Laundry, { { c = -38, w = 4.5 } })
wall("Ground", "z", -13, 21, 35, RC.Laundry, RC.Stair, { { c = 31.5, w = 4.5 } }, {}, W)
wall("Ground", "x", 1, -13, 1, RC.Hall, RC.Stair, { { c = -6, w = 12.4, h = 10 } }, W, W)
wall("Ground", "x", 1, 1, 13, RC.Hall, RC.Bath, { { c = 7, w = 4.5 } }, W, TILE)
wall("Ground", "x", 13, 1, 13, RC.Bath, RC.Storage, {}, TILE, {})
wall("Ground", "z", 1, 1, 13, RC.Stair, RC.Bath, {}, W, TILE)
wall("Ground", "z", 1, 13, 35, RC.Stair, RC.Storage, { { c = 24, w = 4.5 } }, W, {})
wall("Ground", "x", 1, 13, 23, RC.Hall, RC.BStair, { { c = 18, w = 4.5 } }, W, {})
wall("Ground", "x", 1, 23, 45, RC.Hall, RC.Den, { { c = 34, w = 4.5 } }, W, {})
wall("Ground", "z", 13, 1, 13, RC.Bath, RC.BStair, {}, TILE, { nobase = true })
wall("Ground", "z", 13, 13, 35, RC.Storage, RC.BStair, {}, {}, { nobase = true })
wall("Ground", "z", 23, 1, 35, RC.BStair, RC.Den, {}, { nobase = true }, {})
-- slab-edge fillers inside the basement stair room
B.box(S, "Filler", 12.75, 0.9, 1, 13.25, 2.1, 35, RC.BStair, M.Plaster, { solid = true })
B.box(S, "Filler", 22.75, 0.9, 1, 23.25, 2.1, 35, RC.BStair, M.Plaster, { solid = true })
-- upstairs
wall("Upstairs", "z", -13, -35, -7, RC.Sewing, RC.Kids, { { c = -28, w = 4.5 } })
wall("Upstairs", "z", 13, -35, -7, RC.Kids, RC.Grandma, {}, {}, FAB)
wall("Upstairs", "x", -7, -45, -13, RC.Sewing, RC.UHall, { { c = -20, w = 4.5 } }, {}, W)
wall("Upstairs", "x", -7, -13, 13, RC.Kids, RC.UHall, { { c = 0, w = 4.5 } }, {}, W)
wall("Upstairs", "x", -7, 13, 45, RC.Grandma, RC.UHall, { { c = 18, w = 4.5 } }, FAB, W)
wall("Upstairs", "x", 1, -45, -13, RC.UHall, RC.Guest, { { c = -30, w = 4.5 } }, W, {})
wall("Upstairs", "x", 1, -13, 1, RC.UHall, RC.Landing, { { c = -2.5, w = 6.4, h = 9.5 } }, W, W)
wall("Upstairs", "x", 1, 1, 13, RC.UHall, RC.UBath, { { c = 7, w = 4.5 } }, W, TILE)
wall("Upstairs", "x", 1, 13, 27, RC.UHall, RC.AStair, { { c = 16.5, w = 6.4, h = 9.5 } }, W, {})
wall("Upstairs", "x", 1, 27, 45, RC.UHall, RC.Study, { { c = 36, w = 4.5 } }, W, {})
wall("Upstairs", "z", -13, 1, 35, RC.Guest, RC.Landing, {}, {}, W)
wall("Upstairs", "z", 1, 1, 15, RC.Landing, RC.UBath, {}, W, TILE)
wall("Upstairs", "x", 15, 1, 13, RC.UBath, RC.Linen, {}, TILE, {})
wall("Upstairs", "z", 1, 15, 35, RC.Landing, RC.Linen, { { c = 20, w = 4.5 } }, W, {})
wall("Upstairs", "z", 13, 1, 15, RC.UBath, RC.AStair, {}, TILE, {})
wall("Upstairs", "z", 13, 15, 35, RC.Linen, RC.AStair, {}, {}, {})
wall("Upstairs", "z", 27, 1, 35, RC.AStair, RC.Study, {}, {}, {})
-- basement (concrete / brick / planks)
local CON = { mat = M.Concrete, trimColor = C.Stone }
local BRK = { mat = M.Brick, trimColor = C.Stone }
local PLK = { mat = M.WoodPlanks, trimColor = C.WoodDark }
local PL = { mat = M.Plaster }
local cc, bc, wc = C.Concrete:Lerp(C.Paper, 0.15), C.Brick:Lerp(C.Stone, 0.3), C.WoodRaw:Lerp(C.Ink, 0.2)
wall("Basement", "z", -13, 0, 35, bc, cc, { { c = 20, w = 4.5 } }, BRK, CON)
wall("Basement", "z", -13, -35, 0, wc, cc, { { c = -15, w = 4.5 } }, PLK, CON)
wall("Basement", "x", 0, -45, -13, wc, bc, { { c = -30, w = 4.5 } }, PLK, BRK)
wall("Basement", "x", 0, -13, 23, cc, cc, { { c = 0, w = 4.5 } }, CON, CON)
wall("Basement", "z", 23, -35, -15, cc, C.WNight, { { c = -25, w = 4.5 } }, CON, PL)
wall("Basement", "x", -15, 23, 45, C.WNight, cc, {}, PL, CON)
wall("Basement", "z", 23, -15, 0, cc, cc, {}, CON, CON)
wall("Basement", "z", 13, 1, 35, cc, cc, { { c = 31.5, w = 6, h = 9 } }, CON, CON, BS, 1)
wall("Basement", "z", 23, 1, 35, cc, cc, {}, CON, CON, BS, 1)
B.box(B.F("Basement"), "Filler", 13, BS, 0.25, 23, 1, 1, cc, M.Concrete, { solid = true })
-- basement ceiling joists
for x = -42, 42, 6 do
	B.box(B.F("Basement"), "Joist", x - 0.3, 0.1, -35, x + 0.3, 1, 35, C.WoodRaw:Lerp(C.Ink, 0.35), M.Wood, { small = true })
end

----------------------------------------------------------------- CSG arches
local function arch(axis, fixed, c, w, y0, colN, colP, span)
	for _, layer in { { fixed - 0.125, colN }, { fixed + 0.125, colP } } do
		local p
		if axis == "z" then
			p = B.box(B.F("Ground"), "Arch", layer[1] - 0.125, y0, c - span / 2, layer[1] + 0.125, y0 + 12, c + span / 2, layer[2], M.Plaster, { solid = true })
		else
			p = B.box(B.F("Ground"), "Arch", c - span / 2, y0, layer[1] - 0.125, c + span / 2, y0 + 12, layer[1] + 0.125, layer[2], M.Plaster, { solid = true })
		end
		local r = w / 2
		local spring = y0 + 12 - 1 - r
		local blk, cyl
		if axis == "z" then
			blk = B.cutter(V(2, spring - y0 + 1, w), CFrame.new(fixed, (y0 - 1 + spring) / 2, c))
			cyl = B.cutter(V(2, w, w), CFrame.new(fixed, spring, c), Enum.PartType.Cylinder)
		else
			blk = B.cutter(V(w, spring - y0 + 1, 2), CFrame.new(c, (y0 - 1 + spring) / 2, fixed))
			cyl = B.cutter(V(2, w, w), CFrame.new(c, spring, fixed) * CFrame.Angles(0, math.rad(90), 0), Enum.PartType.Cylinder)
		end
		B.csg("sub", p, { blk, cyl }, { fid = Enum.CollisionFidelity.PreciseConvexDecomposition })
	end
	-- dark wood jamb trims at the arch feet
	local spring = y0 + 12 - 1 - w / 2
	for _, sgn in { -1, 1 } do
		if axis == "z" then
			B.box(B.F("Ground"), "ArchJamb", fixed - 0.4, y0, c + sgn * w / 2 - 0.2, fixed + 0.4, spring, c + sgn * w / 2 + 0.2, C.WoodDark, M.Wood, { small = true })
		else
			B.box(B.F("Ground"), "ArchJamb", c + sgn * w / 2 - 0.2, y0, fixed - 0.4, c + sgn * w / 2 + 0.2, spring, fixed + 0.4, C.WoodDark, M.Wood, { small = true })
		end
	end
end
arch("z", 3, -22, 8, G, RC.Entry, RC.Living, 10)
arch("x", -7, -5, 6.5, G, RC.Entry, RC.Hall, 8)

----------------------------------------------------------------- doors
local I = B.F("Interactables")
local function door(name, fl, axis, fixed, c, area, sq, lk, col, hs)
	return B.door(I, name, axis, fixed, c, FL[fl], area, sq, lk, col, hs)
end
local dw = C.WoodMid
local pw = C.Paper:Lerp(C.Ink, 0.15) -- painted doors
B.door(B.root(), "FrontDoor", "x", -35.5, -5, G, "Ground", true, false, C.Blood:Lerp(C.Ink, 0.45), 1)
door("Door_DiningKitchen", "Ground", "x", -7, -30, "Ground", true, false, pw, 1)
door("Door_LivingHall", "Ground", "x", -7, 36, "Ground", true, false, dw, -1)
door("Door_KitchenLaundry", "Ground", "x", 21, -38, "Ground", false, false, pw, 1)
door("Door_LaundryStair", "Ground", "z", -13, 31.5, "Ground", true, false, pw, 1)
door("Door_Bathroom", "Ground", "x", 1, 7, "Ground", false, true, pw, 1)
door("Door_Storage", "Ground", "z", 1, 24, "Ground", true, true, dw, 1)
door("Door_Basement", "Ground", "x", 1, 18, "Basement", true, false, C.WoodDark, 1)
door("Door_Den", "Ground", "x", 1, 34, "Ground", false, false, dw, 1)
door("Door_Sewing", "Upstairs", "x", -7, -20, "Upstairs", false, false, pw, 1)
door("Door_Kids", "Upstairs", "x", -7, 0, "Upstairs", true, false, pw, -1)
door("Door_GrandmaBedroom", "Upstairs", "x", -7, 18, "Upstairs", true, true, dw, 1)
door("Door_SewingKids", "Upstairs", "z", -13, -28, "Upstairs", true, false, pw, 1)
door("Door_Guest", "Upstairs", "x", 1, -30, "Upstairs", false, true, pw, 1)
door("Door_UpBath", "Upstairs", "x", 1, 7, "Upstairs", false, true, pw, 1)
door("Door_Linen", "Upstairs", "z", 1, 20, "Upstairs", true, true, pw, 1)
door("Door_Study", "Upstairs", "x", 1, 36, "Upstairs", true, false, dw, -1)
door("Door_Cellar", "Basement", "z", -13, 20, "Basement", true, false, C.WoodRaw, 1)
door("Door_CellarWorkshop", "Basement", "x", 0, -30, "Basement", false, false, C.WoodRaw, 1)
door("Door_Furnace", "Basement", "x", 0, 0, "Basement", true, false, C.Metal, 1)
door("Door_WorkshopFurnace", "Basement", "z", -13, -15, "Basement", false, false, C.WoodRaw, 1)
door("Door_Shrine", "Basement", "z", 23, -25, "Basement", true, true, C.WoodDark, 1)

----------------------------------------------------------------- floor overlays
local GF = B.F("Ground")
-- kitchen checker (4-stud tiles) X -45..-13, Z -7..21
B.box(GF, "KitchenFloor", -45, 1.9, -7, -13, 2.02, 21, C.Tile, M.SmoothPlastic, { solid = true })
for ix = 0, 7 do
	for iz = 0, 6 do
		if (ix + iz) % 2 == 0 then
			local x0, z0 = -45 + ix * 4, -7 + iz * 4
			B.box(GF, "Tile", x0, 2.0, z0, x0 + 4, 2.04, z0 + 4, C.Mint:Lerp(C.Ink, 0.45), M.SmoothPlastic, { small = true })
		end
	end
end
B.box(GF, "LaundryFloor", -45, 1.9, 21, -13, 2.02, 35, C.Concrete:Lerp(C.Paper, 0.2), M.Slate, { solid = true })
B.box(GF, "BathFloor", 1, 1.9, 1, 13, 2.02, 13, C.Paper:Lerp(C.Mint, 0.2), M.Marble, { solid = true })
local UF = B.F("Upstairs")
B.box(UF, "BathFloor", 1, 14.9, 1, 13, 15.02, 15, C.Paper:Lerp(C.Rose, 0.15), M.Marble, { solid = true })
return "walls ok, parts=" .. B.count(B.root())
