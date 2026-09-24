-- BackGarden 02: Ground zone dressing. Lawn, patio, kitchen garden, compost corner, old orchard + outhouse,
-- rose garden, greenhouse path; west/east hedges with gates; Ground rooms, loot, nodes, lamps, hides.
local B = _G.BGB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local SM = { small = true }
local root = B.root()
local S, G = B.F("Structure"), B.F("Ground")
local A = "Ground"

-- prone enclosure (tarp, planter...). b on the floor, LookVector = head side. o: len, wid, h, col, mat, name, kind
function B.lowHide(par, b, area, o)
	local m = B.model(par, o.name or "LowHide")
	local len, wid, h = o.len or 7, o.wid or 3.6, o.h or 2.8
	local col, mat = o.col or C.WoodRaw, o.mat or M.WoodPlanks
	local function R(n, sz, off, c, mt, op) return B.rp(m, n, b, sz, off, c or col, mt or mat, op) end
	R("EndPanel", V(wid, h - 0.3, 0.25), V(0, (h - 0.3) / 2, -len / 2 + 0.125))
	R("EndPanel", V(wid, h - 0.3, 0.25), V(0, (h - 0.3) / 2, len / 2 - 0.125))
	for _, sx in { -1, 1 } do R("SidePanel", V(0.25, h - 0.3, len - 0.5), V(sx * (wid / 2 - 0.125), (h - 0.3) / 2, 0)) end
	R("TopPanel", V(wid + (o.over or 0), 0.3, len + (o.over or 0)), V(0, h - 0.15, 0), o.topColor or col, o.topMat or mat)
	B.proneInside(m, b, area, len, 1.1, o.kind or "Bed")
	return m
end

----------------------------------------------------------------- hedges + gates (west: kitchen garden & orchard; east: rose garden)
local HG = B.model(S, "GardenHedges")
local function hedgePiece(x0, z0, x1, z1, ya, yb)
	if ya > 0.1 then -- the piece above a gate sits on the door head
		B.box(HG, "Hedge", x0, ya, z0, x1, yb, z1, C.Hedge, M.LeafyGrass, { solid = true })
		B.box(HG, "HedgeTop", x0 + 0.2, yb, z0 + 0.2, x1 - 0.2, yb + 0.35, z1 - 0.2, C.HedgeTop, M.LeafyGrass, SM)
	else
		B.hedge(HG, x0, z0, x1, z1, yb)
	end
end
for _, pc in B.pieces(-28, 46, 0, 9.5, { B.dgap(-8), B.dgap(24) }) do hedgePiece(-35, pc[1], -33, pc[2], pc[3], pc[4]) end
B.door2(G, "KitchenGardenGate", "z", -34, -8, 0, A, { style = "garden", color = C.WoodMid:Lerp(C.Mint, 0.25), wallT = 2, frameColor = C.WoodRaw:Lerp(C.Ink, 0.3) })
B.door2(G, "OrchardGate", "z", -34, 24, 0, A, { style = "garden", color = C.WoodMid:Lerp(C.Rose, 0.2), wallT = 2, squeaky = true, frameColor = C.WoodRaw:Lerp(C.Ink, 0.3) })
-- rose garden hedge (x 29..31, z 34..60) with the RoseGate at z 37 (y0 0.05: flagstones/gravel on both sides)
for _, pc in B.pieces(34, 59.7, 0, 9.5, { { c = 37, w = B.DW + 0.7, h = 8.4 } }) do hedgePiece(29, pc[1], 31, pc[2], pc[3], pc[4]) end
B.box(HG, "Hedge", 29, 1.2, 59.7, 31, 9.5, 60, C.Hedge, M.LeafyGrass, { solid = true }) -- above the house foundation
B.door2(G, "RoseGate", "z", 30, 37, 0.05, A, { style = "garden", color = C.Rose:Lerp(C.Ink, 0.5), wallT = 2, frameColor = C.WoodRaw:Lerp(C.Ink, 0.3) })
-- solid hedge block between the greenhouse and the maze (x 62..71, z -2..34)
B.hedge(HG, 62, -2, 71, 34, 9.5)
-- roses over the gates
for _, g in { { -34, -8 }, { -34, 24 }, { 30, 37 } } do
	for i = 0, 4 do
		B.part(HG, "ArbourRose", V(0.7, 0.7, 0.7), CFrame.new(g[1] + ((i % 2) - 0.5) * 1.4, 9.75 + (i % 3) * 0.1, g[2] - 2.6 + i * 1.3), C.Blood:Lerp(C.Rose, 0.3 + (i % 2) * 0.2), M.Fabric, { small = true, shape = Enum.PartType.Ball })
	end
end

----------------------------------------------------------------- lawn (x -33..30, z -28..32)
local LW = B.model(G, "Lawn")
-- stepping-stone path gate -> patio
local path = { V(-22.5, 0, -22), V(-20.5, 0, -18.6), V(-18, 0, -15.4), V(-15.6, 0, -12), V(-13.4, 0, -8.5), V(-11.6, 0, -5), V(-10, 0, -1.4), V(-8.8, 0, 2.3), V(-7.8, 0, 6), V(-7, 0, 9.8), V(-6.3, 0, 13.6), V(-5.7, 0, 17.4), V(-5.2, 0, 21.2), V(-4.8, 0, 25), V(-4.4, 0, 28.8) }
for i, p in path do
	B.part(LW, "SteppingStone", V(0.12, 2.4 + (i % 3) * 0.2, 2.4 + (i % 3) * 0.2), CFrame.new(p.X, 0.04, p.Z) * CFrame.Angles(0, math.rad(i * 29), math.rad(90)), C.Stone:Lerp(C.Paper, 0.22), M.Slate, { small = true, shape = Enum.PartType.Cylinder })
end
-- washing line with sheets (they hide you from far away)
do
	local wl = B.model(LW, "WashingLine")
	wl:SetAttribute("NoGround", true)
	for _, p in { V(-22, 0, 12), V(14, 0, 16) } do
		B.box(wl, "Pole", p.X - 0.2, 0, p.Z - 0.2, p.X + 0.2, 8, p.Z + 0.2, C.WoodRaw:Lerp(C.Ink, 0.3), M.Wood, { solid = true })
		B.box(wl, "CrossBar", p.X - 0.15, 7.6, p.Z - 1.2, p.X + 0.15, 7.9, p.Z + 1.2, C.WoodRaw:Lerp(C.Ink, 0.3), M.Wood, SM)
	end
	local a, b = V(-22, 7.6, 12), V(14, 7.6, 16)
	local dir = (b - a).Unit
	B.part(wl, "Line", V(0.05, 0.05, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), C.Paper:Lerp(C.Ink, 0.4), M.SmoothPlastic, SM)
	local sheets = { { 3, 4.6, C.Paper }, { 9, 5.2, C.Mint:Lerp(C.Paper, 0.5) }, { 15, 4.8, C.Paper:Lerp(C.Rose, 0.25) }, { 21.5, 5.4, C.Paper }, { 28, 3.4, C.Mustard:Lerp(C.Paper, 0.5) } }
	for i, s in sheets do
		local p = a + dir * s[1]
		local sh = B.part(wl, "Sheet", V(0.08, s[2], 4.2), CFrame.lookAt(p - V(0, s[2] / 2, 0), p - V(0, s[2] / 2, 0) + dir), s[3], M.Fabric, { small = true, shadow = true })
		sh.CFrame = sh.CFrame * CFrame.Angles(0, 0, math.rad((i % 2) * 4 - 2))
		for _, o in { -1.6, 1.6 } do
			B.part(wl, "Peg", V(0.15, 0.4, 0.15), CFrame.new(p + dir * o + V(0, 0.05, 0)), C.WoodLight, M.Wood, SM)
		end
	end
	-- the ghost sheet: two eye holes
	local p = a + dir * 21.5
	for _, o in { -0.6, 0.6 } do
		B.part(wl, "EyeHole", V(0.1, 0.45, 0.35), CFrame.new(p + dir * o - V(0, 1.4, 0)), C.Ink, M.SmoothPlastic, SM)
	end
	-- laundry basket
	local lb = B.model(LW, "LaundryBasket")
	B.box(lb, "Basket", -19.6, 0, 9.4, -17.4, 1.2, 11, C.Wicker, M.Fabric, { collide = true })
	B.box(lb, "Laundry", -19.4, 1.2, 9.6, -17.6, 1.5, 10.8, C.Paper:Lerp(C.Mint, 0.3), M.Fabric, SM)
	B.loot(A, 1, V(-18.5, 1.5, 10.2))
end
-- bird bath
do
	local bb = B.model(LW, "BirdBath")
	local b = cf(2, 0, -2)
	B.cyl(bb, "Base", b, 2, 0.4, V(0, 0.2, 0), C.Stone:Lerp(C.Paper, 0.3), M.Slate, { solid = true }, true)
	B.cyl(bb, "Pedestal", b, 0.9, 2.6, V(0, 1.7, 0), C.Stone:Lerp(C.Paper, 0.3), M.Slate, { solid = true }, true)
	B.cyl(bb, "Bowl", b, 3.4, 0.5, V(0, 3.25, 0), C.Stone:Lerp(C.Paper, 0.3), M.Slate, { solid = true }, true)
	B.cyl(bb, "Water", b, 2.9, 0.06, V(0, 3.53, 0), C.Glass:Lerp(C.Ink, 0.4), M.Glass, { small = true, refl = 0.3 }, true)
	B.ball(bb, "DeadBird", b, 0.5, V(0.6, 3.72, 0.3), C.Ink:Lerp(C.Mustard, 0.2), M.Fabric, SM)
	B.loot(A, 1, V(1.2, 3.56, -2.6))
end
-- garden bench + toy chest (grandchildren's)
do
	local bn = B.model(LW, "GardenBench")
	local b = cf(-26, 0, 22, "+x")
	B.rp(bn, "Seat", b, V(6, 0.3, 2), V(0, 1.9, 0), C.WoodLight:Lerp(C.Ink, 0.2), M.WoodPlanks, { solid = true })
	B.rp(bn, "Back", b, V(6, 1.8, 0.25), V(0, 3.3, 0.9), C.WoodLight:Lerp(C.Ink, 0.2), M.WoodPlanks, SM)
	for _, sx in { -1, 1 } do
		B.rp(bn, "Leg", b, V(0.35, 1.75, 2), V(sx * 2.7, 0.875, 0), C.Iron, M.Metal, SM)
		B.rp(bn, "Arm", b, V(0.35, 0.25, 2), V(sx * 2.7, 2.9, 0), C.Iron, M.Metal, SM)
	end
	B.loot(A, 1, V(-26, 2.05, 20.8))
	local tc = B.model(LW, "ToyChest")
	local tb = cf(-25.5, 0, 28.5, "+x")
	B.rp(tc, "Body", tb, V(3.6, 2, 2.2), V(0, 1, 0), C.Mustard:Lerp(C.Ink, 0.3), M.Wood, { solid = true })
	local lid = B.rp(tc, "Lid", tb, V(3.7, 0.4, 2.3), V(0, 2.2, 0), C.Rose:Lerp(C.Ink, 0.3), M.Wood, { collide = true })
	B.searchable(lid, "ToyChest", A, 1)
	for i = 0, 2 do B.rp(tc, "Letter", tb, V(0.6, 0.6, 0.05), V(-1 + i, 1.1, -1.12), ({ C.Rose, C.Mint, C.Mustard })[i + 1], M.SmoothPlastic, SM) end
	B.doll(LW, cf(-23.8, 0, 28.5, "+x"), 1.1, C.Rose:Lerp(C.Ink, 0.2))
end
-- flower beds (lane wall side + greenhouse side), gnomes
do
	local fb = B.model(LW, "FlowerBeds")
	local function bed(x0, z0, x1, z1)
		B.box(fb, "Bed", x0, -0.2, z0, x1, 0.25, z1, C.Soil, M.Ground, { collide = true })
		local n = 0
		for x = x0 + 1, x1 - 1, 1.9 do
			for z = z0 + 0.8, z1 - 0.6, 1.6 do
				n += 1
				local h = 1.1 + ((n * 7) % 5) * 0.3
				B.part(fb, "Stalk", V(0.12, h, 0.12), CFrame.new(x, 0.25 + h / 2, z) * CFrame.Angles(math.rad((n * 13) % 24 - 12), 0, math.rad((n * 7) % 30 - 15)), C.Moss:Lerp(C.Ink, 0.3), M.Wood, SM)
				if n % 2 == 0 then
					B.part(fb, "Bloom", V(0.55, 0.45, 0.55), CFrame.new(x + 0.1, 0.3 + h, z), ({ C.Rose, C.Bruise, C.Mustard, C.Paper })[n % 4 + 1]:Lerp(C.Ink, 0.35), M.Fabric, { small = true, shape = Enum.PartType.Ball })
				end
			end
		end
	end
	bed(-20, -27.8, 12, -25)
	bed(25, 2, 29.6, 12)
	bed(25, 20, 29.6, 30)
	B.gnome(LW, cf(-2, 0.25, -26, "-z") * CFrame.Angles(0, math.rad(180), 0), C.Blood:Lerp(C.Ink, 0.15))
	B.gnome(LW, cf(4.6, 0, 1.2, 160), C.Bruise)
	B.gnome(LW, cf(27.2, 0.25, 9.5, "-x"), C.Mint:Lerp(C.Ink, 0.4))
	B.loot(A, 1, V(-8, 0.25, -26.4))
end
-- wheelbarrow under a tarp (HidingSpot, prone)
do
	local b = cf(19, 0, -14, "-x")
	local m = B.lowHide(LW, b, A, { name = "WheelbarrowTarp", len = 7, wid = 3.8, h = 3, col = C.WTeal:Lerp(C.Ink, 0.4), mat = M.Fabric, over = 0.4 })
	B.cyl(m, "Wheel", b, 1.6, 0.4, V(0, 0.8, -4.0), C.Ink, M.Rubber, SM, false)
	m:SetAttribute("NoGround", true)
	for _, sx in { -1, 1 } do B.rp(m, "Handle", b, V(0.2, 0.2, 2.4), V(sx * 1.1, 1.6, 4.4), C.WoodRaw, M.Wood, SM) end
	B.rp(m, "Rope", b, V(3.9, 0.1, 0.1), V(0, 2.95, -1.5), C.Mustard:Lerp(C.Ink, 0.3), M.Fabric, SM)
	B.rp(m, "Rope", b, V(3.9, 0.1, 0.1), V(0, 2.95, 1.5), C.Mustard:Lerp(C.Ink, 0.3), M.Fabric, SM)
	for i = 0, 2 do B.rp(m, "Brick", b, V(0.8, 0.4, 0.5), V(-1.2 + i * 1.2, 3.2, 0), C.Brick, M.Brick, SM) end
end
-- old oak with a rope swing (cover on the open lawn)
do
	local t = B.model(LW, "OldOak")
	local base = V(14, 0, -2)
	B.box(t, "Trunk", base.X - 1.4, 0, base.Z - 1.4, base.X + 1.4, 16, base.Z + 1.4, C.WoodDark:Lerp(C.Ink, 0.3), M.Wood, { solid = true })
	for i, r in { { 0, 1.8 }, { 90, 1.6 }, { 180, 1.9 }, { 270, 1.5 } } do
		B.part(t, "Root", V(1.2, 0.8, 3), CFrame.new(base) * CFrame.Angles(0, math.rad(r[1] + 20), 0) * CFrame.new(0, 0.3, -r[2] - 0.6) * CFrame.Angles(math.rad(-12), 0, 0), C.WoodDark:Lerp(C.Ink, 0.3), M.Wood, SM)
		local _ = i
	end
	for _, br in { { 11, 40, 0, 8 }, { 13, -35, 70, 7 }, { 10, 50, 150, 6 }, { 14, -25, 230, 7 }, { 12, -45, 300, 5 } } do
		local c2 = CFrame.new(base + V(0, br[1], 0)) * CFrame.Angles(0, math.rad(br[3]), 0) * CFrame.Angles(0, 0, math.rad(br[2])) * CFrame.new(0, br[4] / 2, 0)
		B.part(t, "Branch", V(0.8, br[4], 0.8), c2, C.WoodDark:Lerp(C.Ink, 0.3), M.Wood, SM)
	end
	for _, c in { V(0, 19, 0), V(4, 17, 3), V(-4, 17.5, -2), V(2, 18, -5), V(-3, 16.5, 4) } do
		B.part(t, "Canopy", V(9, 6, 9), CFrame.new(base + c), C.Hedge:Lerp(C.Ink, 0.2), M.LeafyGrass, { small = true, shape = Enum.PartType.Ball })
	end
	B.part(t, "Limb", V(7, 0.6, 0.6), CFrame.new(base + V(3.5, 11.5, 0)), C.WoodDark:Lerp(C.Ink, 0.3), M.Wood, SM)
	B.part(t, "SwingSeat", V(2.4, 0.2, 0.9), CFrame.new(base + V(5, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(6)), C.WoodRaw, M.Wood, SM)
	for _, dz in { -0.35, 0.35 } do
		B.part(t, "Rope", V(0.06, 8.8, 0.06), CFrame.new(base + V(5, 7.05, dz)), C.Paper:Lerp(C.Ink, 0.4), M.Fabric, SM)
	end
	t:SetAttribute("NoGround", true)
end
B.lanternPost(LW, -14, 0, -2, A, { h = 6, range = 18 })
B.lanternPost(LW, 8, 0, 26, A, { h = 6, range = 18 })
-- gravel patches that crunch
B.gravelCreak(-21.5, 0, -20.5, 12)
B.gravelCreak(-9.2, 0, 3.5, -8)
B.gravelCreak(24, 0, -20, 30)

----------------------------------------------------------------- patio (x -33..29, z 32..46)
local PT = B.model(G, "Patio")
B.box(PT, "Flagstones", -32.5, -0.2, 32.4, 28.5, 0.05, 40, C.Flag, M.Slate, { solid = true })
for i = 0, 11 do
	B.box(PT, "Joint", -32.5 + i * 5.08, 0.05, 32.4, -32.4 + i * 5.08, 0.06, 40, C.Ink:Lerp(C.Flag, 0.4), M.Slate, SM)
end
for _, z in { 35, 37.6 } do B.box(PT, "Joint", -32.5, 0.05, z, 28.5, 0.06, z + 0.1, C.Ink:Lerp(C.Flag, 0.4), M.Slate, SM) end
-- garden table + chairs
do
	local t = B.model(PT, "PatioTable")
	local b = cf(-18, 0.05, 36.4)
	B.cyl(t, "Top", b, 4.4, 0.2, V(0, 3.1, 0), C.Iron:Lerp(C.Paper, 0.15), M.Metal, { solid = true }, true)
	B.cyl(t, "Stem", b, 0.3, 3, V(0, 1.5, 0), C.Iron, M.Metal, SM, true)
	B.cyl(t, "Foot", b, 1.8, 0.2, V(0, 0.1, 0), C.Iron, M.Metal, SM, true)
	B.cyl(t, "Umbrella", b, 0.15, 5.5, V(0, 5.9, 0), C.WoodRaw, M.Wood, SM, true)
	B.cyl(t, "Canopy", b, 7, 0.3, V(0, 8.6, 0), C.Mint:Lerp(C.Ink, 0.4), M.Fabric, SM, true)
	B.loot(A, 2, V(-17.2, 3.2, 36.2))
	B.loot(A, 2, V(-19, 3.2, 37.2))
	for _, a in { 30, 200 } do
		local cb = cf(-18, 0.05, 36.4, a) * CFrame.new(0, 0, -3.3)
		local ch = B.model(PT, "PatioChair")
		B.rp(ch, "Seat", cb * CFrame.Angles(0, math.pi, 0), V(2, 0.2, 2), V(0, 1.9, 0), C.Iron, M.Metal, { solid = true })
		B.rp(ch, "Back", cb * CFrame.Angles(0, math.pi, 0), V(2, 2.2, 0.2), V(0, 3.1, 0.95), C.Iron, M.Metal, SM)
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do B.rp(ch, "Leg", cb, V(0.15, 1.8, 0.15), V(sx * 0.85, 0.9, sz * 0.85), C.Iron, M.Metal, SM) end
		end
		B.rp(ch, "Cushion", cb * CFrame.Angles(0, math.pi, 0), V(1.8, 0.2, 1.8), V(0, 2.1, 0), C.WRose, M.Fabric, SM)
	end
end
-- big planter box (HidingSpot, prone) with shrubs on top
do
	local b = cf(20.5, 0.05, 36.5, "-x")
	local m = B.lowHide(PT, b, A, { name = "BigPlanter", len = 8, wid = 4, h = 2.9, col = C.WoodMid:Lerp(C.Ink, 0.2), topColor = C.Soil, topMat = M.Ground })
	for i = 0, 3 do
		B.ball(m, "Shrub", b, 2.2 + (i % 2) * 0.4, V(((i % 2) - 0.5) * 1.2, 3.6, -3 + i * 2), C.Hedge:Lerp(C.Moss, 0.3), M.LeafyGrass, SM)
	end
	for i = 0, 2 do B.ball(m, "Rose", b, 0.5, V(-0.8 + i * 0.8, 4.6, -2 + i * 2), C.Blood:Lerp(C.Rose, 0.3), M.Fabric, SM) end
end
-- pots (Breakable) at the patio edges, grill
B.pot(PT, cf(-30.5, 0.05, 39), 1.3, C.Moss)
B.pot(PT, cf(12.5, 0.05, 39.2), 1.1, "dead")
do
	local gr = B.model(PT, "Grill")
	local b = cf(8, 0.05, 34.2)
	for _, a in { 0, 120, 240 } do B.rp(gr, "Leg", b * CFrame.Angles(0, math.rad(a), 0), V(0.15, 2.8, 0.15), V(0, 1.3, -0.8), C.Iron, M.Metal, SM, CFrame.Angles(math.rad(-12), 0, 0)) end
	B.ball(gr, "Kettle", b, 2.2, V(0, 3, 0), C.Iron, M.Metal, { collide = true })
	B.cyl(gr, "Lid", b, 1.8, 0.3, V(0, 4.05, 0), C.Iron:Lerp(C.Paper, 0.1), M.Metal, SM, true)
end
-- string lights: porch posts -> patio poles
do
	local sl = B.model(PT, "StringLights")
	for _, p in { V(-27, 0, 33), V(24, 0, 33) } do
		B.box(sl, "LightPole", p.X - 0.2, 0.05, p.Z - 0.2, p.X + 0.2, 10.5, p.Z + 0.2, C.WoodDark, M.Wood, { solid = true })
	end
	B.stringLights(PT, { V(-20, 12.4, 46.4), V(-27, 10.3, 33), V(-2, 10.8, 33.2) }, A, { sag = 1.1, lights = 3 })
	B.stringLights(PT, { V(-2, 10.8, 33.2), V(24, 10.3, 33), V(17.6, 12.4, 46.4) }, A, { sag = 1.1, lights = 3 })
end
B.loot(A, 2, V(17.2, 2.95, 35))

----------------------------------------------------------------- kitchen garden (x -50..-35, z -28..14) + compost corner (x -77..-50, z -28..-16)
local KG = B.model(G, "KitchenGarden")
local function raisedBed(x0, z0, x1, z1, crop)
	B.box(KG, "RaisedBed", x0, 0, z0, x1, 1.3, z1, C.WoodRaw:Lerp(C.Ink, 0.25), M.WoodPlanks, { solid = true })
	B.box(KG, "BedSoil", x0 + 0.3, 1.3, z0 + 0.3, x1 - 0.3, 1.36, z1 - 0.3, C.Soil, M.Ground, SM)
	local n = 0
	for x = x0 + 1, x1 - 1, 1.6 do
		for z = z0 + 1, z1 - 1, 1.6 do
			n += 1
			if crop == "cabbage" then
				B.part(KG, "Cabbage", V(1.1, 0.8, 1.1), CFrame.new(x, 1.7, z), C.Moss:Lerp(C.Mint, 0.3 + (n % 3) * 0.1), M.LeafyGrass, { small = true, shape = Enum.PartType.Ball })
			elseif n % 2 == 0 then
				B.part(KG, "Pumpkinish", V(1.0, 0.8, 1.0), CFrame.new(x, 1.7, z), C.Mustard:Lerp(C.Blood, 0.3), M.SmoothPlastic, { small = true, shape = Enum.PartType.Ball })
			end
		end
	end
end
raisedBed(-44, -25, -38, -17, "cabbage")
raisedBed(-48, -4, -42, 4, "gourd")
-- bean teepees
for _, p in { V(-39, 0, -2), V(-39, 0, 7) } do
	for a = 0, 300, 60 do
		local c2 = CFrame.new(p) * CFrame.Angles(0, math.rad(a), 0) * CFrame.new(0, 3.2, -0.9) * CFrame.Angles(math.rad(-16), 0, 0)
		B.part(KG, "Cane", V(0.12, 6.6, 0.12), c2, C.WoodLight, M.Wood, SM)
	end
	B.part(KG, "Vines", V(2.2, 4, 2.2), CFrame.new(p + V(0, 2.4, 0)), C.Moss:Lerp(C.Ink, 0.25), M.LeafyGrass, { small = true, shape = Enum.PartType.Ball })
end
-- scarecrow
do
	local sc = B.model(KG, "Scarecrow")
	local b = cf(-42, 0, 10, "+x")
	B.rp(sc, "Pole", b, V(0.3, 8, 0.3), V(0, 4, 0), C.WoodRaw, M.Wood, { solid = true })
	B.rp(sc, "Arms", b, V(5, 0.25, 0.25), V(0, 6.2, 0), C.WoodRaw, M.Wood, SM)
	B.rp(sc, "Coat", b, V(2.2, 2.8, 1), V(0, 5.2, 0), C.WMustard:Lerp(C.Ink, 0.3), M.Fabric, SM)
	B.rp(sc, "Sleeves", b, V(4.4, 0.7, 0.8), V(0, 6.2, 0), C.WMustard:Lerp(C.Ink, 0.35), M.Fabric, SM)
	B.ball(sc, "Head", b, 1.4, V(0, 7.6, 0), C.Sheet:Lerp(C.Mustard, 0.3), M.Fabric, SM)
	B.rp(sc, "Hat", b, V(2, 0.15, 2), V(0, 8.3, 0), C.Ink, M.Fabric, SM)
	B.rp(sc, "HatTop", b, V(1.1, 0.8, 1.1), V(0, 8.75, 0), C.Ink, M.Fabric, SM)
	for _, sx in { -1, 1 } do B.rp(sc, "Button", b, V(0.25, 0.25, 0.05), V(sx * 0.25, 7.7, -0.7), C.Ink, M.SmoothPlastic, SM) end
	B.rp(sc, "Stitch", b, V(0.7, 0.08, 0.05), V(0, 7.25, -0.7), C.Blood, M.SmoothPlastic, SM)
end
-- potting table with a searchable drawer; tool crate (Trunk)
do
	B.bench(KG, cf(-38.3, 0, 11.4, "-z"), 5, A, 1, { name = "GardenTable", search = { [1] = "Drawer" }, d = 2.6 })
	B.pot(KG, cf(-39.4, 3.2, 11.6), 0.8, C.Moss)
	B.loot(A, 1, V(-36.9, 3.2, 11.2))
	B.trunk(KG, cf(-47.5, 0, 11.8, "-z"), C.WoodMid:Lerp(C.Mint, 0.2), A, 1, { w = 3.4, d = 2 })
end
B.loot(A, 1, V(-41, 1.36, -21))
B.loot(A, 1, V(-45, 1.36, 0))
-- compost bin (HidingSpot) and rain barrel (HidingSpot) against the shed
do
	local cb = B.hideBox(KG, cf(-74.8, 0, -22, "+x"), A, { name = "CompostBin", w = 5, d = 4.2, h = 7.2, col = C.WoodRaw:Lerp(C.Ink, 0.35), slats = true, lid = C.WoodDark, kind = "Cabinet" })
	B.part(cb, "Heap", V(3.2, 1.2, 2.6), CFrame.new(-71.6, 0.6, -18.6), C.Soil:Lerp(C.Moss, 0.3), M.Ground, SM)
	B.loot(A, 1, V(-71.6, 1.2, -18.6))
	-- rain barrel (water butt): hollow ring of staves under the shed gutter
	local rb = B.model(KG, "RainBarrel")
	local c0 = V(-56, 0, -18.7)
	local r = 2.25
	for i = 0, 13 do
		local a = math.rad(i * 360 / 14)
		B.part(rb, "Stave", V(1.06, 7.2, 0.28), CFrame.new(c0 + V(math.sin(a) * r, 3.6, math.cos(a) * r)) * CFrame.Angles(0, a, 0), C.WoodMid:Lerp(C.Ink, (i % 2) * 0.1), M.Wood, { solid = true })
	end
	B.part(rb, "BarrelLid", V(0.3, 5.1, 5.1), CFrame.new(c0 + V(0, 7.35, 0)) * CFrame.Angles(0, 0, math.rad(90)), C.WoodDark, M.Wood, { solid = true, shape = Enum.PartType.Cylinder })
	for _, y in { 1.2, 6 } do
		for i = 0, 13 do
			local a = math.rad(i * 360 / 14)
			B.part(rb, "Hoop", V(1.08, 0.3, 0.06), CFrame.new(c0 + V(math.sin(a) * (r + 0.17), y, math.cos(a) * (r + 0.17))) * CFrame.Angles(0, a, 0), C.Iron, M.Metal, SM)
		end
	end
	B.box(rb, "Tap", -56.2, 1.6, -21.35, -55.8, 1.9, -20.95, C.Brass, M.Metal, SM)
	B.box(rb, "Downpipe", -56.25, 7.5, -16.6, -55.75, 10.3, -16.1, C.Metal:Lerp(C.Ink, 0.4), M.Metal, SM)
	B.box(rb, "DownpipeElbow", -56.25, 7.5, -18.7, -55.75, 7.9, -16.6, C.Metal:Lerp(C.Ink, 0.4), M.Metal, SM)
	local ins = CFrame.lookAt(c0 + V(0, 3.1, 0), c0 + V(0, 3.1, -5))
	B.hideParts(rb, "Closet", A, ins, c0 + V(0, 0, -r - 2.1), c0 + V(0, 0, -r - 2))
end
-- lantern on the compost corner
B.lanternPost(KG, -64, 0, -26.5, A, { h = 6, range = 16, bright = 0.7 })
B.gravelCreak(-62, 0, -21, 5)

----------------------------------------------------------------- old orchard (x -77..-35, z 14..60) + outhouse (Bathroom node)
local OR = B.model(G, "Orchard")
local function appleTree(x, z, s)
	local t = B.model(OR, "AppleTree")
	B.box(t, "Trunk", x - 0.8 * s, 0, z - 0.8 * s, x + 0.8 * s, 7 * s, z + 0.8 * s, C.WoodDark:Lerp(C.Ink, 0.2), M.Wood, { solid = true })
	for i, br in { { 5.5, 45, 20, 4 }, { 6, -40, 140, 4 }, { 6.5, 35, 260, 3.5 } } do
		local c2 = CFrame.new(x, br[1] * s, z) * CFrame.Angles(0, math.rad(br[3]), 0) * CFrame.Angles(0, 0, math.rad(br[2])) * CFrame.new(0, br[4] * s / 2, 0)
		B.part(t, "Branch", V(0.5, br[4] * s, 0.5), c2, C.WoodDark:Lerp(C.Ink, 0.2), M.Wood, SM)
		local _ = i
	end
	B.part(t, "Canopy", V(8 * s, 5 * s, 8 * s), CFrame.new(x, 9.5 * s, z), C.Hedge:Lerp(C.Moss, 0.25), M.LeafyGrass, { small = true, shape = Enum.PartType.Ball })
	for i = 0, 3 do
		B.part(t, "Apple", V(0.45, 0.45, 0.45), CFrame.new(x + math.cos(i * 1.7) * 2.4, 0.22, z + math.sin(i * 1.7) * 2.4), C.Blood:Lerp(C.Ink, 0.2), M.SmoothPlastic, { small = true, shape = Enum.PartType.Ball })
	end
	t:SetAttribute("NoGround", true)
	return t
end
appleTree(-62, 22, 1)
appleTree(-45, 34, 1.1)
appleTree(-66, 44, 0.95)
appleTree(-44, 52, 0.9)
-- hollow old tree (HidingSpot)
do
	local b = cf(-55, 0, 36, "+x")
	local m = B.hideBox(OR, b, A, { name = "HollowTree", w = 5.2, d = 4.4, h = 9, col = C.WoodDark:Lerp(C.Ink, 0.25), doorColor = C.WoodDark:Lerp(C.Moss, 0.2), mat = M.Wood, kind = "Closet" })
	for _, c in m:GetChildren() do if c.Name == "Inset" or c.Name == "Handle" then c:Destroy() end end
	B.rp(m, "KnotHole", b, V(1.2, 1.6, 0.1), V(0.4, 5.6, -2.24), C.Ink, M.Wood, SM)
	for i, br in { { 45, 0 }, { -40, 90 }, { 30, 200 } } do
		B.part(m, "Branch", V(0.9, 6, 0.9), b * CFrame.new(0, 9, 0) * CFrame.Angles(0, math.rad(br[2]), 0) * CFrame.Angles(0, 0, math.rad(br[1])) * CFrame.new(0, 3, 0), C.WoodDark:Lerp(C.Ink, 0.25), M.Wood, SM)
		local _ = i
	end
	B.part(m, "Canopy", V(10, 5, 10), b * CFrame.new(0, 13, 0), C.Hedge:Lerp(C.Ink, 0.15), M.LeafyGrass, { small = true, shape = Enum.PartType.Ball })
	for _, a in { 30, 150, 260 } do
		B.part(m, "Root", V(1.2, 0.8, 2.6), b * CFrame.Angles(0, math.rad(a), 0) * CFrame.new(0, 0.3, -3.2) * CFrame.Angles(math.rad(-10), 0, 0), C.WoodDark:Lerp(C.Ink, 0.25), M.Wood, SM)
	end
	m:SetAttribute("NoGround", true)
end
-- beehives, old trunk
for i, p in { V(-70, 0, 30), V(-70, 0, 36) } do
	local h = B.model(OR, "Beehive")
	B.box(h, "Stand", p.X - 1.2, 0, p.Z - 1.2, p.X + 1.2, 0.8, p.Z + 1.2, C.WoodDark, M.Wood, { solid = true })
	for k = 0, 2 do B.box(h, "Box", p.X - 1.1, 0.8 + k * 1.1, p.Z - 1.1, p.X + 1.1, 1.85 + k * 1.1, p.Z + 1.1, C.Paper:Lerp(C.Ink, 0.15 + k * 0.05), M.Wood, { solid = true }) end
	B.box(h, "Roof", p.X - 1.4, 4.1, p.Z - 1.4, p.X + 1.4, 4.4, p.Z + 1.4, C.Roof, M.Metal, { solid = true })
	if i == 1 then B.loot(A, 1, V(p.X, 4.4, p.Z)) end
end
B.trunk(OR, cf(-60, 0, 56.8, "-z"), C.WoodDark:Lerp(C.Rose, 0.15), A, 1, { w = 3.8, d = 2.2 })
B.loot(A, 1, V(-60, 0, 24.4))
B.loot(A, 1, V(-47.5, 0, 31.5))
B.lanternPost(OR, -50, 0, 24, A, { h = 6, range = 18, bright = 0.8 })
-- outhouse (x -76..-69, z 52.5..59.5), door on the east wall
do
	local oh = B.model(OR, "Outhouse")
	local wc = C.WoodRaw:Lerp(C.Mint, 0.15)
	B.box(oh, "Floor", -75.6, 0, 52.9, -69.4, 0.1, 59.1, C.WoodMid, M.WoodPlanks, { solid = true })
	B.box(oh, "Wall", -76, 0, 52.5, -75.6, 9.6, 59.5, wc, M.WoodPlanks, { solid = true })
	B.box(oh, "Wall", -75.6, 0, 52.5, -69, 9.6, 52.9, wc, M.WoodPlanks, { solid = true })
	B.box(oh, "Wall", -75.6, 0, 59.1, -69, 9.6, 59.5, wc, M.WoodPlanks, { solid = true })
	for _, pc in B.pieces(52.9, 59.1, 0, 9.6, { { c = 56, w = B.DW + 0.7, h = 8.35 + 0.1 } }) do
		B.box(oh, "Wall", -69.4, pc[3], pc[1], -69, pc[4], pc[2], wc, M.WoodPlanks, { solid = true })
	end
	local door = B.door2(G, "OuthouseDoor", "z", -69.2, 56, 0.1, A, { style = "garden", color = C.WoodMid:Lerp(C.Mint, 0.3), wallT = 0.4, squeaky = true, hs = -1 })
	-- crescent moon cut-out on both faces of the leaf
	local pnl = door.Panel
	for _, s in { -1, 1 } do
		B.part(door, "Moon", V(0.9, 0.9, 0.05), (B.SH:Inverse() * pnl.CFrame) * CFrame.new(0, 2.6, s * 0.17), C.Ink, M.SmoothPlastic, SM)
	end
	B.part(oh, "Roof", V(8, 1.2, 8.2), CFrame.new(-72.5, 10.2, 56) * CFrame.Angles(0, math.rad(90), 0), C.Roof, M.Metal, { solid = true, class = "WedgePart" })
	B.box(oh, "Seat", -75.6, 0.1, 53.8, -74.2, 2.2, 58.2, C.WoodMid, M.WoodPlanks, { collide = true })
	B.part(oh, "Hole", V(0.05, 0.8, 1.1), CFrame.new(-74.9, 2.21, 56) * CFrame.Angles(0, 0, math.rad(90)), C.Ink, M.SmoothPlastic, { small = true, shape = Enum.PartType.Cylinder })
	B.box(oh, "Shelf", -75.6, 5, 53.1, -74.8, 5.15, 55.4, C.WoodMid, M.Wood, SM)
	B.box(oh, "Newspaper", -75.4, 2.2, 57.2, -74.5, 2.35, 58, C.Paper:Lerp(C.Ink, 0.2), M.Fabric, SM)
	B.loot(A, 1, V(-75.2, 5.15, 54.2))
	B.lamp(oh, "bare", cf(-74.6, 9.2, 56), A, { drop = 1.4, range = 12, bright = 0.8 }) -- clear of the door swing
	B.box(oh, "Ceiling", -75.6, 9.2, 52.9, -69.4, 9.6, 59.1, wc:Lerp(C.Ink, 0.3), M.WoodPlanks, { solid = true })
end
B.node(A, -72.2, 0.1, 56, true)

----------------------------------------------------------------- rose garden (x 31..71, z 34..60)
local RG = B.model(G, "RoseGarden")
local function roseBush(x, z, s)
	B.part(RG, "RoseBush", V(3 * s, 2.6 * s, 3 * s), CFrame.new(x, 1.2 * s, z), C.Hedge:Lerp(C.Moss, 0.2), M.LeafyGrass, { collide = true, shape = Enum.PartType.Ball })
	for i = 0, 4 do
		B.part(RG, "Rose", V(0.45, 0.45, 0.45), CFrame.new(x + math.cos(i * 1.3) * 1.1 * s, 2.2 * s + (i % 2) * 0.2, z + math.sin(i * 1.3) * 1.1 * s), C.Blood:Lerp(C.Rose, (i % 3) * 0.25), M.Fabric, { small = true, shape = Enum.PartType.Ball })
	end
end
for _, p in { { 36, 36.5 }, { 42, 36.5 }, { 48, 36.5 }, { 54, 36.5 }, { 66, 38 }, { 68.5, 46 }, { 34, 57.5 }, { 40, 57.5 } } do roseBush(p[1], p[2], 1) end
B.box(RG, "GravelPath", 35, -0.2, 41.5, 70.8, 0.05, 47.5, C.Gravel, M.Pebble, { solid = true })
B.box(RG, "GravelPath", 31.2, -0.2, 35.4, 35, 0.05, 47.5, C.Gravel, M.Pebble, { solid = true })
B.box(RG, "GravelPath", 47, -0.2, 47.5, 53, 0.05, 57, C.Gravel, M.Pebble, { solid = true })
-- sundial + stone bench
do
	local b = cf(50, 0.05, 51.5)
	B.cyl(RG, "SundialBase", b, 2, 0.3, V(0, 0.15, 0), C.Stone:Lerp(C.Paper, 0.3), M.Slate, { solid = true }, true)
	B.cyl(RG, "SundialPillar", b, 1, 3, V(0, 1.8, 0), C.Stone:Lerp(C.Paper, 0.3), M.Slate, { solid = true }, true)
	B.cyl(RG, "SundialFace", b, 2, 0.2, V(0, 3.4, 0), C.Brass:Lerp(C.Ink, 0.3), M.Metal, { solid = true }, true)
	B.rp(RG, "Gnomon", b, V(0.1, 0.8, 1), V(0, 3.9, 0), C.Brass:Lerp(C.Ink, 0.3), M.Metal, SM)
	B.loot(A, 2, V(50.5, 3.5, 51.2))
	local bb = cf(40, 0.05, 50.5, "+z")
	B.rp(RG, "BenchSlab", bb, V(6, 0.5, 2), V(0, 1.9, 0), C.Stone:Lerp(C.Paper, 0.2), M.Slate, { solid = true })
	for _, sx in { -2.2, 2.2 } do B.rp(RG, "BenchLeg", bb, V(0.8, 1.65, 1.6), V(sx, 0.825, 0), C.Stone:Lerp(C.Paper, 0.1), M.Slate, { solid = true }) end
	B.loot(A, 2, V(41, 2.15, 50.5))
end
-- rose arches over the path
for _, x in { 38, 58 } do
	for _, z in { 41, 48 } do B.box(RG, "ArchPost", x - 0.2, 0.05, z - 0.2, x + 0.2, 8.5, z + 0.2, C.Iron, M.Metal, { solid = true }) end
	B.box(RG, "ArchTop", x - 0.2, 8.5, 40.8, x + 0.2, 8.8, 48.2, C.Iron, M.Metal, SM)
	for i = 0, 5 do
		B.part(RG, "ArchRose", V(0.8, 0.8, 0.8), CFrame.new(x + ((i % 2) - 0.5) * 0.6, 8.8 + (i % 3) * 0.1, 41.2 + i * 1.3), C.Blood:Lerp(C.Rose, (i % 2) * 0.3), M.Fabric, { small = true, shape = Enum.PartType.Ball })
	end
end
-- garden locker (HidingSpot), potting cabinet (Searchable), chest
B.wardrobe(RG, cf(62, 0, 57.9, "-z"), C.Mint:Lerp(C.Ink, 0.45), A, "Wardrobe", { name = "GardenLocker", w = 5, h = 8.6, louvre = true })
do
	local _, h = B.dresser(RG, cf(54.5, 0, 58.7, "-z"), 4.6, 2.2, 3.6, C.WoodRaw:Lerp(C.Ink, 0.2), 3, A, 2, { search = { 1, 3 }, kind = "Cabinet", name = "PottingCabinet" })
	B.pot(RG, cf(53.4, h, 58.6), 0.8, C.Moss)
	B.loot(A, 2, V(55.6, h, 58.6))
end
B.trunk(RG, cf(68, 0, 56.5, "-x"), C.WoodDark:Lerp(C.Mustard, 0.2), A, 2, { w = 3.4, d = 2 })
B.lanternPost(RG, 45, 0.05, 45, A, { h = 6, range = 18, bright = 0.8 })
B.gravelCreak(50, 0.05, 44.5, 0)

----------------------------------------------------------------- greenhouse path (x 30..71, z -28..-2): the way to the maze
local GP = B.model(G, "GreenhousePath")
B.box(GP, "GravelPath", 30.2, -0.2, -24, 70.8, 0.05, -8, C.Gravel, M.Pebble, { solid = true })
do
	B.bench(GP, cf(45, 0.05, -25.9, "+z"), 6, A, 1, { name = "PathPottingTable", search = { [2] = "Drawer" }, d = 2.6 })
	B.pot(GP, cf(43.4, 3.25, -26), 0.9, "dead")
	B.loot(A, 1, V(46.6, 3.25, -26))
	-- cold frame
	local cfm = B.model(GP, "ColdFrame")
	B.box(cfm, "Frame", 54, 0, -27.8, 62, 1.6, -24.6, C.WoodRaw, M.WoodPlanks, { solid = true })
	B.box(cfm, "Lid", 54.1, 1.6, -27.7, 61.9, 1.75, -24.7, C.GlassG, M.Glass, { solid = true, tr = 0.4 })
	B.loot(A, 1, V(58, 1.75, -26.2))
	-- stacked pots + hose reel
	for i = 0, 2 do
		B.cyl(GP, "PotStack", cf(34.5 + i * 1.6, 0.05, -26.5), 1.1, 1.8 - i * 0.3, V(0, (1.8 - i * 0.3) / 2, 0), C.Terracotta:Lerp(C.Ink, 0.2), M.Slate, SM, true)
	end
	B.part(GP, "HoseReel", V(1.4, 2.4, 2.4), CFrame.new(66.5, 1.25, -26.8), C.Mint:Lerp(C.Ink, 0.4), M.Rubber, { collide = true, shape = Enum.PartType.Cylinder })
	B.box(GP, "Tap", 66.3, 0, -28, 66.7, 3.2, -27.6, C.Metal, M.Metal, SM)
end
B.lanternPost(GP, 38, 0.05, -6, A, { h = 6, range = 18, bright = 0.8 })
B.gravelCreak(52, 0.05, -12, 20)

----------------------------------------------------------------- Ground rooms (floor to 14 studs), search nodes, extra loot
B.room("Garden Lane", A, 1, -77, 0, -53, 71, 14, -29)
B.room("The Lawn", A, 1, -33, 0, -28, 30, 14, 32)
B.room("Patio", A, 2, -33, 0, 32, 29, 14, 46)
B.room("Back Porch", A, 2, -34, 0, 46, 29, 14, 60)
B.room("Kitchen Garden", A, 1, -50, 0, -28, -35, 14, 14)
B.room("Compost Corner", A, 1, -77, 0, -28, -50, 14, -16)
B.room("Old Orchard", A, 1, -77, 0, 14, -35, 14, 52.5)
B.room("Old Orchard", A, 1, -69, 0, 52.5, -35, 14, 60)
B.room("Outhouse", A, 1, -76, 0, 52.5, -69, 12, 59.5)
B.room("Rose Garden", A, 2, 31, 0, 34, 71, 14, 60)
B.room("Greenhouse Path", A, 1, 30, 0, -28, 71, 14, -2)
for _, n in {
	{ -45, -41 }, { 30, -40 }, -- lane
	{ -20, -14 }, { 6, -16 }, { -4, 10 }, { 22, 22 }, { -26, 2 }, -- lawn
	{ -26, 42 }, { 4, 37 }, -- patio
	{ -14, 49 }, { 16, 50 }, -- porch (deck)
	{ -42, -9 }, { -46, 9 }, -- kitchen garden
	{ -66, -22 }, -- compost
	{ -58, 28 }, { -52, 48 }, { -50, 56.5 }, -- orchard
	{ 44, 44 }, { 62, 50 }, -- rose garden
	{ 40, -16 }, { 62, -18 }, -- greenhouse path
} do
	local y = if n[2] > 46 and n[2] < 60 and n[1] > -34 and n[1] < 29 then 3 else 0.05
	B.node(A, n[1], y, n[2])
end
-- extra Ground loot: porch sills and sideboard, glider, lane bins, path
B.loot(A, 2, V(-26, 5.5, 59.5))
B.loot(A, 2, V(12.6, 5.5, 59.5))
B.loot(A, 2, V(18.2, 6.6, 58.5))
B.loot(A, 2, V(-23.5, 5.3, 57.4))
B.loot(A, 2, V(3.6, 3, 50.2))
B.loot(A, 1, V(30.2, 3.7, -50.6))
B.loot(A, 1, V(-26, 0.05, -24))
B.prize(A, V(6.3, 5.82, 55.1))
return "02 garden ok, parts=" .. B.count(root)
