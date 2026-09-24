-- St. Mildred's 03: GROUND (night 1) interiors + churchyard dressing: pews (Grandma's pew = GrandmaChair), porch, nave,
-- tower base, organ-loft stairs foot, chancel, lady chapel (confessional), vestry (+FuseBox), WC, cloister passage.
-- Doors, hiding spots, searchables, loot, prizes, lamps, breakables, creaky boards, search nodes.
local B = _G.SMB
local C, M = B.C, B.M
local V = Vector3.new
local SM = B.SM
local GR = B.F("Ground")
local IA = B.F("Interactables")
local G = 2
local oak = C.Oak
local oakD = C.Oak:Lerp(C.Ink, 0.3)
local function R(m, n, b, sz, off, col, mat, o) return B.rp(m, n, b, sz, off, col, mat, o) end
local function dark(c, k) return c:Lerp(C.Ink, k or 0.35) end

----------------------------------------------------------------- pews
-- b on the floor at the pew centre, LookVector = the way worshippers face (+z, the altar)
local function pew(par, b, L, name, o)
	o = o or {}
	local m = B.model(par, name or "Pew")
	for _, sx in { -1, 1 } do
		R(m, "End", b, V(0.3, 3.4, 2.1), V(sx * (L / 2 - 0.15), 1.7, 0.1), C.Pew, M.Wood, { solid = true })
		R(m, "EndCap", b, V(0.42, 0.18, 2.2), V(sx * (L / 2 - 0.15), 3.49, 0.1), dark(C.Pew, 0.2), M.Wood, SM)
	end
	R(m, "Seat", b, V(L - 0.45, 0.22, 1.5), V(0, 1.8, -0.1), C.Pew:Lerp(C.WoodMid, 0.3), M.Wood, { solid = true })
	R(m, "Back", b, V(L - 0.5, 1.9, 0.2), V(0, 2.86, 0.75), C.Pew, M.Wood, { solid = true })
	R(m, "BookLedge", b, V(L - 0.6, 0.12, 0.44), V(0, 3.3, 1.08), dark(C.Pew, 0.15), M.Wood, SM)
	if o.closed then -- kick board + drape: the space under the seat is hidden
		R(m, "KickBoard", b, V(L - 0.6, 1.58, 0.2), V(0, 0.9, 0.75), C.Pew, M.Wood, { solid = true })
		R(m, "Drape", b, V(L - 0.7, 1.55, 0.06), V(0, 0.9, -0.88), o.drape or C.Velvet, M.Fabric, { solid = true })
	end
	return m
end
local rows = { -6.2, -3.0, 0.2, 3.4, 6.6, 9.8, 13.0, 16.2 }
local PW = B.F("Pews", GR)
for ri, z in rows do
	for _, xc in { -6.25, 6.25 } do
		local isGran = (xc > 0 and ri == #rows)
		local hideL = (xc < 0 and ri == 3)
		local hideR = (xc > 0 and ri == 5)
		local b = B.cf(xc, G, z, "+z")
		local m = pew(if isGran then B.root() else PW, b, 5.5, if isGran then "GrandmaChair" else "Pew", { closed = hideL or hideR })
		if hideL or hideR then
			local aisle = if xc < 0 then 1 else -1 -- toward the centre aisle
			local up = V(aisle, 0, 0)
			local inside = CFrame.fromMatrix(V(xc, G + 1.05, z + 0.05), up:Cross(Vector3.yAxis), up)
			m.Name = "Pew_Hiding"
			B.HP(m, "Bed", inside, V(if xc < 0 then -1.8 else 1.8, G, z + 0.2), V(if xc < 0 then -1.0 else 1.0, G, z - 0.8))
		end
		if isGran then
			R(m, "Cushion", b, V(4.0, 0.25, 1.3), V(-0.2, 2.03, -0.1), C.Velvet, M.Fabric, SM)
			R(m, "Blanket", b, V(1.2, 0.8, 1.1), V(-2.05, 2.35, -0.1), C.Mustard:Lerp(C.Ink, 0.35), M.Fabric, SM)
			R(m, "HymnBook", b, V(0.7, 0.2, 0.55), V(2.25, 2.01, 0.1), C.Blood:Lerp(C.Ink, 0.4), M.Fabric, SM)
			-- sleep spot: HRP sitting on the cushion near the aisle, facing the altar
			local sp = V(5.1, G + 1.91 + 0.25 + 1.3, z + 0.15)
			B.part(B.root(), "GrandmaSleepSpot", V(2, 2, 1), CFrame.lookAt(sp, sp + V(0, 0, 1)), C.Paper, M.SmoothPlastic, { inv = true })
			B.PZ(V(7.0, G + 2.15, z + 0.1))
		end
	end
end
-- candles around Grandma: on the pew-end caps, and little clusters on the floor at the pew front (non-collidable, she can stand up)
B.candleLamp(GR, V(3.65, G + 3.58, 16.4), 0.8)
B.candleLamp(GR, V(8.85, G + 3.58, 16.4), 0.8)
do
	local ps = B.model(GR, "FloorCandles")
	B.candleSet(ps, V(8.3, G, 17.8), 4, 2)
	B.candleSet(ps, V(3.9, G, 17.7), 3, 5)
end
-- aisle runner
B.rug(GR, 0, G, 4.5, 3.2, 25, C.Velvet, dark(C.Velvet, 0.4))

----------------------------------------------------------------- nave furniture
-- pulpit (left of the chancel arch)
do
	local p = B.model(GR, "Pulpit")
	B.box(p, "Base", -9.2, G, 20.6, -7.2, G + 1.2, 22.6, C.StoneD, M.Limestone, { solid = true })
	B.box(p, "Drum", -9.4, G + 1.2, 20.4, -7.0, G + 4.6, 22.8, oak, M.Wood, { solid = true })
	B.box(p, "Rail", -9.6, G + 4.6, 20.2, -6.8, G + 4.9, 23.0, oakD, M.Wood, SM)
	B.box(p, "Frontal", -9.45, G + 2.4, 20.35, -6.95, G + 4.2, 20.4, C.Velvet, M.Fabric, SM)
	B.box(p, "Desk", -9.0, G + 4.9, 20.6, -7.4, G + 5.1, 21.4, oakD, M.Wood, SM)
	B.L(V(-8.2, G + 5.1, 21.0))
end
-- lectern (right)
do
	local l = B.model(GR, "Lectern")
	local b = B.cf(8.2, G, 21.6, "-z")
	B.cyl(l, "Foot", b, 1.6, 0.3, V(0, 0.15, 0), C.Brass, M.Metal, { solid = true })
	B.cyl(l, "Column", b, 0.35, 3.6, V(0, 2.1, 0), C.Brass, M.Metal, { solid = true })
	local top = R(l, "BookRest", b, V(2.0, 0.15, 1.4), V(0, 4.1, 0), C.Brass, M.Metal, SM)
	top.CFrame = CFrame.new(B.O) * b * CFrame.new(0, 4.1, 0) * CFrame.Angles(math.rad(-20), 0, 0)
	local bk = R(l, "Bible", b, V(1.7, 0.3, 1.2), V(0, 4.3, 0), C.Blood:Lerp(C.Ink, 0.45), M.Fabric, SM)
	bk.CFrame = CFrame.new(B.O) * b * CFrame.new(0, 4.3, -0.05) * CFrame.Angles(math.rad(-20), 0, 0)
end
-- hymn boards on the north wall
for _, x in { -8.4, 8.4 } do
	local hb = B.model(GR, "HymnBoard")
	B.box(hb, "Board", x - 0.65, 5.5, 23.72, x + 0.65, 9.5, 24, oakD, M.Wood, SM)
	B.box(hb, "Crest", x - 0.75, 9.5, 23.66, x + 0.75, 9.8, 24, oak, M.Wood, SM)
	for i = 0, 3 do
		B.box(hb, "Number", x - 0.45, 5.8 + i * 0.9, 23.64, x + 0.45, 6.4 + i * 0.9, 23.72, C.Paper, M.SmoothPlastic, SM)
	end
end
-- chandeliers (wheel of candles)
local function chandelier(par, x, z, yTop, yRing)
	local m = B.model(par, "Chandelier")
	B.cyl(m, "Chain", CFrame.new(x, yRing, z), 0.15, yTop - yRing, V(0, (yTop - yRing) / 2, 0), C.Iron, M.Metal, SM)
	B.cyl(m, "Wheel", CFrame.new(x, yRing, z), 5, 0.25, V(0, 0, 0), C.Iron, M.Metal, SM)
	B.cyl(m, "Hub", CFrame.new(x, yRing, z), 1.2, 0.6, V(0, 0.2, 0), C.Iron, M.Metal, SM)
	local first
	for i = 1, 8 do
		local a = i * math.pi / 4
		local p = V(x + math.cos(a) * 2.3, yRing + 0.12, z + math.sin(a) * 2.3)
		B.cyl(m, "Candle", CFrame.new(p), 0.28, 0.8, V(0, 0.4, 0), C.Wax, M.SmoothPlastic, SM)
		local f = B.ball(m, "Bulb", CFrame.new(p), 0.2, V(0, 0.95, 0), C.FlameC, M.Neon, SM)
		first = first or f
	end
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 176, 110)
	l.Range = 30
	l.Brightness = 1.1
	l.Shadows = true
	l.Parent = first
	m.PrimaryPart = first
	B.attrs(m, { Area = B.A(V(x, yRing, z)) })
	B.tag(m, "Lamp")
	return m
end
chandelier(GR, 0, 3.8, 28, 20.5)
chandelier(GR, 0, 10.3, 28, 20.5)
-- wall sconces (candle in a glass chimney)
for _, s in { { -15.95, 9, "+x" }, { 15.95, -2, "-x" } } do
	B.LP(GR, "sconce", B.cf(s[1], 8.5, s[2], s[3]), { shade = C.Wax, range = 16, bright = 0.8 })
end
-- breakables where people run
B.candleStand(GR, V(12.6, G, 19.2), 4)
B.candleStand(GR, V(-10.3, G, 18.6), 4)
B.candleStand(GR, V(12.8, G, -8.4), 3.6)
-- creaky boards (nave floor planks)
for _, p in { { 5.4, 21.8 }, { 11.5, 17.6 }, { -11.5, 17.6 }, { 12.5, 6 }, { -12.5, 6 }, { 12.5, -4 }, { -12.5, -4 }, { -9, -15 }, { 9, -15.5 } } do
	B.creak(p[1], G, p[2])
end
-- loot on the pew book ledges / seats
for _, p in { { -6.25, 3.4 }, { 6.25, 9.8 }, { -6.25, 13.0 }, { 6.25, 0.2 }, { -4.6, 6.6 } } do
	B.L(V(p[1], G + 3.36, p[2] - 1.08))
end
B.L(V(-7.2, G + 1.91, 16.1))
B.L(V(4.8, G + 1.91, 9.7))

----------------------------------------------------------------- nave back (under the choir loft)
-- font
do
	local f = B.model(GR, "Font")
	local b = CFrame.new(-10, G, -17)
	B.cyl(f, "Step", b, 3.4, 0.4, V(0, 0.2, 0), C.StoneD:Lerp(C.Ink, 0.15), M.Limestone, { solid = true })
	B.cyl(f, "Stem", b, 1.2, 2.2, V(0, 1.5, 0), C.StoneD, M.Limestone, { solid = true })
	local bowl = B.cyl(f, "Bowl", b, 2.6, 1.1, V(0, 3.15, 0), C.StoneD, M.Limestone, { solid = true })
	B.cyl(f, "Cover", b, 2.3, 0.3, V(0, 3.85, 0), oakD, M.Wood, SM)
	B.cyl(f, "Knob", b, 0.4, 0.5, V(0, 4.2, 0), C.Brass, M.Metal, SM)
	B.L(V(-9.3, G + 4.0, -16.5))
end
-- hymn-book cabinets flanking the front door
local function cabinet(par, b, w, h, d, col, name, kind, searchIdx)
	local m = B.model(par, name or "Cabinet")
	R(m, "Body", b, V(w, h, d), V(0, h / 2, 0), col, M.Wood, { solid = true })
	R(m, "Top", b, V(w + 0.3, 0.2, d + 0.2), V(0, h + 0.1, -0.05), dark(col, 0.2), M.Wood, { solid = true })
	local n = math.max(1, math.floor(w / 1.8 + 0.5))
	local dw = (w - 0.3) / n
	local doors = {}
	for i = 1, n do
		local x = -w / 2 + 0.15 + dw * (i - 0.5)
		local dp = R(m, "CabDoor", b, V(dw - 0.1, h - 0.6, 0.12), V(x, h / 2, -d / 2 - 0.06), dark(col, 0.08), M.Wood, { collide = false })
		B.ball(m, "Pull", b, 0.2, V(x + (if i % 2 == 1 then dw * 0.32 else -dw * 0.32), h / 2, -d / 2 - 0.18), C.Brass, M.Metal, SM)
		table.insert(doors, dp)
	end
	if kind then
		for _, i in searchIdx or { 1 } do
			local dp = doors[i]
			if dp then
				dp.Name = kind
				B.S(dp, kind)
			end
		end
	end
	return m, h + 0.2
end
local _, ch = cabinet(GR, B.cf(-13, G, -21.1, "+z"), 3.6, 3.4, 1.8, oakD, "HymnBookCabinet", "Cabinet", { 1 })
B.L(V(-13.6, G + ch, -21.1))
local _, ch2 = cabinet(GR, B.cf(11, G, -21.1, "+z"), 3.6, 3.4, 1.8, oakD, "HymnBookCabinet", "Cabinet", { 2 })
B.L(V(11.5, G + ch2, -21.1))
B.box(GR, "HymnBooks", -14.6, G + ch, -21.6, -13.9, G + ch + 0.9, -20.7, C.Blood:Lerp(C.Ink, 0.4), M.Fabric, SM)
-- collection box on a post (Cabinet)
do
	local cb = B.model(GR, "CollectionBox")
	B.box(cb, "Post", 3.9, G, -21.0, 4.5, G + 3.2, -20.4, oakD, M.Wood, { solid = true })
	B.box(cb, "Box", 3.5, G + 3.2, -21.2, 4.9, G + 4.4, -20.2, oak, M.Wood, { solid = true })
	local lid = B.box(cb, "Front", 3.55, G + 3.3, -20.2, 4.85, G + 4.3, -20.1, oakD, M.Wood, { collide = false })
	B.box(cb, "Slot", 3.9, G + 4.4, -20.8, 4.5, G + 4.45, -20.6, C.Ink, M.Metal, SM)
	lid.CFrame = CFrame.lookAt(B.O + V(4.2, G + 3.8, -20.15), B.O + V(4.2, G + 3.8, -19))
	lid.Name = "Cabinet"
	B.S(lid, "Cabinet")
end
-- lilies by the door, notice board
do
	B.box(GR, "Plinth", -5.2, G, -21.9, -4.2, G + 2.8, -20.9, C.StoneD, M.Limestone, { solid = true })
	B.lilies(GR, V(-4.7, G + 2.8, -21.4), 1)
	local nb = B.model(GR, "NoticeBoard")
	B.box(nb, "Board", 6, 6, -21.96, 9.6, 8.6, -21.83, C.WoodRaw, M.Cardboard, SM)
	B.box(nb, "Frame", 5.85, 5.85, -22, 9.75, 8.75, -21.9, oakD, M.Wood, SM)
	for i, p in { { 6.6, 7.7 }, { 7.9, 7.4 }, { 8.9, 7.9 }, { 7.0, 6.6 }, { 8.4, 6.5 } } do
		local zf = -21.79 + (i % 2) * 0.03
		B.box(nb, "Notice", p[1] - 0.4, p[2] - 0.5, zf - 0.05, p[1] + 0.4, p[2] + 0.5, zf, if i % 2 == 0 then C.Paper else C.Paper:Lerp(C.Mustard, 0.3), M.SmoothPlastic, SM)
	end
end
-- benches under the loft
for _, x in { -12.5, 12.5 } do
	local bm = B.model(GR, "Bench")
	local b = B.cf(x, G, -11.9, "+z")
	R(bm, "Seat", b, V(4.5, 0.25, 1.3), V(0, 1.7, 0), oak, M.Wood, { solid = true })
	R(bm, "Leg", b, V(0.3, 1.58, 1.1), V(-1.9, 0.79, 0), oakD, M.Wood, { solid = true })
	R(bm, "Leg", b, V(0.3, 1.58, 1.1), V(1.9, 0.79, 0), oakD, M.Wood, { solid = true })
	B.L(V(x + 1.1, G + 1.83, -11.9))
end

----------------------------------------------------------------- doors (Ground)
local D = B.door2
local fd = D(IA, "FrontDoor", "x", -22.75, 0, G, true, false, oakD, 1)
fd.Parent = B.root()
D(IA, "TowerBaseDoor", "z", -16.75, -16, G, true, false, oak, 1)
D(IA, "TowerWestDoor", "z", -42.25, -16, G, true, true, oakD, -1)
D(IA, "OrganStairsDoor", "z", -16.75, 19, G, false, false, oak, 1)
D(IA, "LadyChapelDoor", "x", 24.75, -12, G, false, false, oak, 1)
D(IA, "VestryDoor", "x", 24.75, 12, G, true, true, oak, -1)
D(IA, "ChancelBackDoor", "x", 40.5, 5, G, false, false, oak, -1)
D(IA, "LadyPassageDoor", "x", 40.5, -18, G, true, false, oak, 1)
D(IA, "VestryPassageDoor", "x", 40.5, 18, G, false, false, oak, 1)
D(IA, "WCDoor", "x", 31.5, 23, G, true, true, C.WPaper:Lerp(C.Ink, 0.3), 1)

----------------------------------------------------------------- porch
do
	local P = B.model(GR, "PorchFurniture")
	for _, s in { -1, 1 } do
		B.box(P, "StoneBench", s * 5 - (if s > 0 then 1.2 else 0), G, -30.6, s * 5 + (if s < 0 then 1.2 else 0), G + 1.8, -25.2, C.StoneD:Lerp(C.Ink, 0.1), M.Limestone, { solid = true })
		B.L(V(s * 4.4, G + 1.8, -28.8))
	end
	local b = B.cf(-4.0, G, -24.4, "+x")
	local tr = B.trunk(P, b, oakD, "Ground", 1, { w = 1.6, d = 1.2 })
	tr.Name = "ParishChest"
	local lid = tr:FindFirstChild("Lid")
	B.S(lid, "Trunk")
	B.LP(P, "porch", B.cf(3.9, 8.6, -23.55, "-z"), { shadows = true, range = 18, bright = 1.2, color = Color3.fromRGB(255, 190, 130) })
	B.box(P, "Mat", -2.0, G - 0.02, -26.2, 2.0, G + 0.035, -24.2, C.Mustard:Lerp(C.Ink, 0.5), M.Fabric, { small = true, collide = false })
	B.cobweb(P, V(4.3, 11.2, -31.0), 45, 0.8)
end

----------------------------------------------------------------- tower base
do
	local T = B.model(GR, "TowerBaseFurniture")
	local cup = B.wardrobe(T, B.cf(-30.5, G, -10.4, "-z"), oakD, B.A(V(-30.5, G + 1, -14)), "Closet", { name = "BellRingersCupboard", w = 4.6 })
	B.L(V(-30.5, G + 9.0, -10.5))
	local tr = B.trunk(T, B.cf(-30, G, -22.2, "+z"), oak, "Ground", 1, { w = 3.4, d = 2.0 })
	tr.Name = "RingersChest"
	B.S(tr:FindFirstChild("Lid"), "Trunk")
	local bm = B.model(T, "Bench")
	local b = B.cf(-23.5, G, -22.6, "+z")
	R(bm, "Seat", b, V(5, 0.25, 1.4), V(0, 1.7, 0), oak, M.Wood, { solid = true })
	R(bm, "Leg", b, V(0.3, 1.58, 1.2), V(-2.1, 0.79, 0), oakD, M.Wood, { solid = true })
	R(bm, "Leg", b, V(0.3, 1.58, 1.2), V(2.1, 0.79, 0), oakD, M.Wood, { solid = true })
	B.L(V(-22.4, G + 1.83, -22.6))
	-- peal boards and a rope coil
	B.box(T, "PealBoard", -41.45, 6, -21, -41.3, 9.5, -18.8, oakD, M.Wood, SM)
	B.cyl(T, "RopeCoil", CFrame.new(-39.5, G, -21.8), 1.6, 0.5, V(0, 0.25, 0), C.Paper:Lerp(C.WoodRaw, 0.5), M.Fabric, SM)
	B.LP(T, "bare", CFrame.new(-29.5, 12, -16), { drop = 1.6, range = 22, bright = 0.9 })
end

----------------------------------------------------------------- organ loft stairs (foot room, Ground)
do
	local O = B.model(GR, "OrganStairsFurniture")
	local _, h = cabinet(O, B.cf(-24.05, G, 20.4, "+x"), 3.6, 3.4, 1.8, oakD, "MusicCabinet", "Cabinet", { 1 })
	B.L(V(-24.05, G + h, 19.9))
	B.box(O, "CoatHooks", -17.9, 7, 22, -17.6, 7.3, 23.8, oakD, M.Wood, SM)
	B.box(O, "Cassock", -17.95, 3.6, 22.3, -17.65, 7, 23.3, C.Ink:Lerp(C.Night, 0.4), M.Fabric, SM)
	B.LP(O, "sconce", B.cf(-21.25, 9.5, 23.95, "-z"), { shade = C.Wax, range = 14, bright = 0.8 })
	B.cobweb(O, V(-24.2, 21, 23.2), 135, 0.9)
end

----------------------------------------------------------------- chancel
do
	local CH = B.model(GR, "ChancelFurniture")
	-- altar with frontal
	B.box(CH, "Altar", -2.05, G, 37.6, 2.05, G + 3.4, 39.8, C.StoneD, M.Limestone, { solid = true })
	B.box(CH, "AltarTop", -2.25, G + 3.4, 37.4, 2.25, G + 3.7, 39.9, C.StoneD:Lerp(C.Paper, 0.2), M.Marble, { solid = true })
	B.box(CH, "Frontal", -1.7, G + 0.6, 37.54, 1.7, G + 3.3, 37.6, C.Velvet, M.Fabric, SM)
	B.box(CH, "Cloth", -2.28, G + 3.7, 37.35, 2.28, G + 3.76, 39.9, C.Paper, M.Fabric, SM)
	B.box(CH, "Cross", -0.12, G + 3.76, 39.2, 0.12, G + 5.6, 39.44, C.Brass, M.Metal, SM)
	B.box(CH, "CrossBar", -0.6, G + 4.9, 39.17, 0.6, G + 5.12, 39.47, C.Brass, M.Metal, SM)
	for _, x in { -1.65, 1.65 } do
		B.cyl(CH, "Candlestick", CFrame.new(x, G + 3.76, 39.1), 0.5, 1.2, V(0, 0.6, 0), C.Brass, M.Metal, SM)
		if x < 0 then
			B.candleLamp(CH, V(x, G + 4.96, 39.1), 1.0, { range = 14, bright = 0.9 })
		else
			B.candleDecor(CH, V(x, G + 4.96, 39.1), 1.0)
		end
	end
	B.PZ(V(-1.2, G + 3.76, 38.4))
	B.L(V(1.2, G + 3.76, 38.3))
	-- communion rail with a gap in the middle
	for _, s in { -1, 1 } do
		local x0, x1 = s * 3, s * 8
		B.box(CH, "RailTop", math.min(x0, x1), G + 2.6, 28.8, math.max(x0, x1), G + 2.9, 29.3, oak, M.Wood, SM)
		for x = math.min(x0, x1) + 0.3, math.max(x0, x1) - 0.1, 0.8 do
			B.box(CH, "Baluster", x - 0.08, G, 28.97, x + 0.08, G + 2.6, 29.13, C.Brass, M.Metal, SM)
		end
		B.box(CH, "RailCollider", math.min(x0, x1), G, 28.8, math.max(x0, x1), G + 4, 29.3, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
		B.box(CH, "Kneeler", math.min(x0, x1), G, 27.6, math.max(x0, x1), G + 0.5, 28.6, C.Velvet, M.Fabric, SM)
	end
	-- lilies either side of the altar
	B.box(CH, "Plinth", -5.9, G, 37.9, -4.9, G + 2.4, 38.9, C.StoneD, M.Limestone, { solid = true })
	B.lilies(CH, V(-5.4, G + 2.4, 38.4), 1)
	B.box(CH, "Plinth", 4.1, G, 30.8, 5.1, G + 2.4, 31.8, C.StoneD, M.Limestone, { solid = true })
	B.lilies(CH, V(4.6, G + 2.4, 31.3), 1)
	-- credence table with a drawer (against the west wall)
	local ct, h = B.table(CH, B.cf(-6.9, G, 35.6, "+x"), 2.4, 1.8, 3.2, oakD)
	ct.Name = "CredenceTable"
	local drw = B.rp(CH, "Drawer", B.cf(-6.9, G, 35.6, "+x"), V(1.6, 0.4, 0.12), V(0, 2.7, -0.96), oak, M.Wood, { collide = false })
	B.S(drw, "Drawer")
	B.L(V(-6.9, G + h, 35.8))
	-- sanctuary chest against the east wall
	local tr = B.trunk(CH, B.cf(6.9, G, 31.7, "-x"), oakD, "Ground", 3, { w = 3.0, d = 1.8 })
	tr.Name = "SanctuaryChest"
	B.S(tr:FindFirstChild("Lid"), "Trunk")
	-- sanctuary lamp (red glass)
	B.LP(CH, "hang", CFrame.new(0, 24, 33), { shade = C.Blood, color = Color3.fromRGB(255, 120, 100), range = 18, bright = 0.9 })
	-- choir stalls
	do
		local b = B.cf(-7.2, G, 31.7, "+x")
		local st = B.model(CH, "ChoirStall")
		R(st, "Seat", b, V(3.8, 0.25, 1.4), V(0, 1.8, 0), oak, M.Wood, { solid = true })
		R(st, "Back", b, V(3.7, 3.6, 0.2), V(0, 2.9, 0.62), oakD, M.Wood, { solid = true })
		R(st, "Front", b, V(3.7, 1.67, 0.2), V(0, 0.835, -0.62), oakD, M.Wood, { solid = true })
	end
end

----------------------------------------------------------------- lady chapel
do
	local LC = B.model(GR, "LadyChapelFurniture")
	-- confessional: closed booth, left door + curtain
	local b = B.cf(-23.9, G, 28, "+x")
	local cf = B.wardrobe(LC, b, oakD, B.A(V(-19.5, G + 1, 28)), "Closet", { name = "Confessional", w = 4.4, h = 8.2, doorColor = oak })
	R(cf, "Grille", b, V(0.9, 0.9, 0.08), V(-1.05, 4.9, -1.99), C.Brass, M.Metal, SM)
	R(cf, "Curtain", b, V(1.6, 5.4, 0.1), V(1.05, 3.4, -2.02), C.Velvet, M.Fabric, SM)
	R(cf, "Gable", b, V(4.8, 0.6, 4.3), V(0, 8.9, -0.1), oak, M.Wood, SM)
	-- small altar against the chancel wall
	B.box(LC, "Altar", -11.2, G, 31, -9, G + 3.2, 35.6, C.StoneD, M.Limestone, { solid = true })
	B.box(LC, "AltarCloth", -11.3, G + 3.2, 30.9, -9, G + 3.26, 35.7, C.Paper, M.Fabric, SM)
	B.box(LC, "Frontal", -11.26, G + 0.6, 31.4, -11.2, G + 3.1, 35.2, C.Mint:Lerp(C.Ink, 0.45), M.Fabric, SM)
	B.candleLamp(LC, V(-10, G + 3.26, 31.7), 0.9)
	B.candleDecor(LC, V(-10, G + 3.26, 34.9), 0.9)
	B.lilies(LC, V(-10.1, G + 3.26, 33.3), 0.9, true)
	B.L(V(-10.5, G + 3.26, 32.6))
	-- votive stand (Breakable) and cupboard
	B.candleStand(LC, V(-20, G, 33.5), 3.4)
	local _, h = cabinet(LC, B.cf(-23.5, G, 39.1, "-z"), 3.8, 3.6, 1.6, oakD, "VotiveCupboard", "Cabinet", { 2 })
	B.L(V(-23.8, G + h, 39.1))
	for _, z in { 31.4, 36.0 } do
		local bm = B.model(LC, "Bench")
		local bb = B.cf(-14, G, z, "+x")
		R(bm, "Seat", bb, V(4.2, 0.25, 1.3), V(0, 1.7, 0), oak, M.Wood, { solid = true })
		R(bm, "Leg", bb, V(0.3, 1.58, 1.1), V(-1.7, 0.79, 0), oakD, M.Wood, { solid = true })
		R(bm, "Leg", bb, V(0.3, 1.58, 1.1), V(1.7, 0.79, 0), oakD, M.Wood, { solid = true })
	end
	B.L(V(-14, G + 1.83, 36.6))
	do -- memorial tablet on the west wall
		local pm = B.model(LC, "MemorialTablet")
		B.box(pm, "Frame", -26, 6.3, 35.2, -25.8, 9.7, 37.8, C.StoneD, M.Marble, SM)
		B.box(pm, "Tablet", -25.8, 6.6, 35.45, -25.72, 9.4, 37.55, C.StoneD:Lerp(C.Ink, 0.35), M.Slate, SM)
	end
end

----------------------------------------------------------------- vestry (+ FuseBox) and WC
do
	local VE = B.model(GR, "VestryFurniture")
	local F = G
	B.wardrobe(VE, B.cf(10.95, F, 33.6, "+x"), oakD, B.A(V(15, F + 1, 33.6)), "Wardrobe", { name = "VestmentWardrobe" })
	B.L(V(10.9, F + 9.0, 33.6))
	local dr, h = B.dresser(VE, B.cf(23, F, 39.0, "-z"), 4.6, 1.8, 3.4, oak, 3, "Ground", 2, { search = { 1, 3 }, name = "VestmentChest" })
	for _, p in dr:GetChildren() do
		if p.Name == "Drawer" then B.S(p, "Drawer") end
	end
	B.L(V(22.2, F + h, 39.0))
	B.lilies(VE, V(24.3, F + h, 39.0), 0.8, true)
	-- press cupboard (Cabinet)
	local _, h2 = cabinet(VE, B.cf(9.9, F, 38.1, "+x"), 3.0, 6.2, 1.6, oakD, "VestryPress", "Cabinet", { 1 })
	B.L(V(9.9, F + h2, 38.1))
	-- desk + chair + registers
	-- desk against the WC wall, chair on its west side (keeps a 3.7-wide walkway past the wardrobe)
	local dk, dh = B.table(VE, B.cf(17.8, F, 28.7, "-x"), 4.4, 2.4, 3.2, oak)
	dk.Name = "Desk"
	local dd = B.rp(VE, "Drawer", B.cf(17.8, F, 28.7, "-x"), V(1.8, 0.45, 0.12), V(0, 2.75, -1.26), oakD, M.Wood, { collide = false })
	B.S(dd, "Drawer")
	B.chair(VE, B.cf(15.3, F, 28.7, "+x"), oakD)
	B.box(VE, "Register", 17.1, F + dh, 26.9, 18.3, F + dh + 0.35, 27.9, C.Blood:Lerp(C.Ink, 0.5), M.Fabric, SM)
	B.L(V(17.6, F + dh, 29.6))
	B.LP(VE, "table", B.cf(17.9, F + dh, 30.2, "-x"), { shade = C.Mint, range = 12, bright = 0.8 })
	-- fuse box on the east wall
	local fb = B.part(B.root(), "FuseBox", V(0.4, 2.2, 1.6), CFrame.new(25.8, 7, 33.2), C.Metal:Lerp(C.Ink, 0.3), M.Metal, { solid = true })
	B.box(VE, "Conduit", 25.85, 8.1, 33.1, 25.95, 14, 33.3, C.Metal, M.Metal, SM)
	B.box(VE, "FuseLabel", 25.58, 7.6, 32.9, 25.6, 7.9, 33.5, C.Mustard, M.SmoothPlastic, SM)
	B.cobweb(VE, V(25.3, 13.3, 39.4), 225, 0.8)
	B.creak(12, F, 29)
	B.creak(13.5, F, 37)
	-- WC
	local WC = B.model(GR, "WC")
	local T = G
	local tb = B.cf(24.6, T, 26.6, "+z")
	R(WC, "Pan", tb, V(1.4, 1.5, 1.8), V(0, 0.75, 0.1), C.Paper, M.Marble, { solid = true })
	R(WC, "Seat", tb, V(1.5, 0.12, 1.8), V(0, 1.56, 0.1), oak, M.Wood, SM)
	R(WC, "Cistern", tb, V(1.8, 1.1, 0.8), V(0, 7.4, 0.55), C.Metal:Lerp(C.Paper, 0.3), M.Metal, SM)
	R(WC, "Pipe", tb, V(0.15, 5.4, 0.15), V(0.5, 4.25, 0.62), C.Metal, M.Metal, SM)
	R(WC, "Chain", tb, V(0.05, 2.2, 0.05), V(-0.6, 5.8, 0.3), C.Metal, M.Metal, SM)
	local sb = B.cf(20.95, T, 26.3, "+x")
	R(WC, "Basin", sb, V(1.6, 0.6, 1.4), V(0, 3.1, 0), C.Paper, M.Marble, { solid = true })
	R(WC, "Pedestal", sb, V(0.5, 2.8, 0.5), V(0, 1.4, 0.2), C.Paper, M.Marble, { solid = true })
	local van = R(WC, "VanityDoor", sb, V(1.2, 0.6, 0.1), V(0, 3.1, -0.75), C.Paper:Lerp(C.Ink, 0.1), M.Marble, { collide = false })
	van.Name = "Vanity"
	B.S(van, "Vanity")
	R(WC, "Mirror", sb, V(1.4, 1.8, 0.08), V(0, 5.4, 0.8), C.Glass, M.Glass, { small = true, refl = 0.3 })
	B.L(V(20.7, T + 3.4, 26.3))
	B.LP(WC, "bare", CFrame.new(23, 14, 28.3), { drop = 2.2, range = 12, bright = 0.8 })
end

----------------------------------------------------------------- cloister passage
do
	local CP = B.model(GR, "PassageFurniture")
	local F = G
	B.wardrobe(CP, B.cf(-24.1, F, 45.6, "+x"), oakD, B.A(V(-19.5, F + 1, 45.6)), "Closet", { name = "CoatCupboard", louvre = true, w = 4.8 })
	B.L(V(-24.1, F + 9.0, 45.6))
	local _, h = cabinet(CP, B.cf(25.1, F, 45.4, "-x"), 3.6, 3.4, 1.8, oakD, "HymnBookCupboard", "Cabinet", { 1 })
	B.L(V(25.1, F + h, 45.0))
	for _, x in { -12, 0, 12 } do
		local bm = B.model(CP, "Bench")
		local b = B.cf(x, F, 49.2, "-z")
		R(bm, "Seat", b, V(5, 0.25, 1.3), V(0, 1.7, 0), oak, M.Wood, { solid = true })
		R(bm, "Leg", b, V(0.3, 1.58, 1.1), V(-2.1, 0.79, 0), oakD, M.Wood, { solid = true })
		R(bm, "Leg", b, V(0.3, 1.58, 1.1), V(2.1, 0.79, 0), oakD, M.Wood, { solid = true })
	end
	B.L(V(-11, F + 1.83, 49.2))
	B.L(V(12.8, F + 1.83, 49.2))
	-- flower table with lilies
	local tb, th = B.table(CP, B.cf(-4.5, F, 48.6, "-z"), 3.2, 1.6, 3.0, oak)
	B.lilies(CP, V(-5.2, F + th, 48.6), 0.9)
	B.L(V(-3.7, F + th, 48.6))
	B.candleStand(CP, V(8.5, F, 43.2), 3.6)
	-- stacked chairs
	for i = 0, 3 do
		B.box(CP, "StackedChair", 21.6 + (i % 2) * 0.06, F + i * 0.5, 48.1 + (i % 2) * 0.06, 23.4 + (i % 2) * 0.06, F + i * 0.5 + 0.5, 49.8 + (i % 2) * 0.06, oak:Lerp(C.Paper, 0.1 * i), M.Wood, { solid = true })
	end
	B.LP(CP, "sconce", B.cf(-12, 9.5, 49.95, "-z"), { shade = C.Wax, range = 18, bright = 0.8 })
	B.LP(CP, "sconce", B.cf(12, 9.5, 49.95, "-z"), { shade = C.Wax, range = 18, bright = 0.8 })
	B.creak(-9, F, 45.5)
	B.creak(9.5, F, 45.8)
	B.creak(0, F, 44.2)
end

----------------------------------------------------------------- churchyard dressing (Ground outdoors)
local EX = B.F("Exterior")
local function yew(par, pos, s)
	s = s or 1
	local m = B.model(par, "Yew")
	B.cyl(m, "Trunk", CFrame.new(pos), 1.6 * s, 5 * s, V(0, 2.5 * s, 0), C.WoodDark:Lerp(C.Ink, 0.3), M.Wood, { solid = true })
	B.ball(m, "Canopy", CFrame.new(pos), 9 * s, V(0, 7 * s, 0), C.Yew, M.LeafyGrass, { solid = true })
	B.ball(m, "Canopy", CFrame.new(pos), 6.5 * s, V(1.2 * s, 10.5 * s, 0.6 * s), C.Yew:Lerp(C.Ink, 0.15), M.LeafyGrass, { small = true })
	B.ball(m, "Canopy", CFrame.new(pos), 5 * s, V(-1.4 * s, 9.5 * s, -1.2 * s), C.Yew:Lerp(C.Grass, 0.2), M.LeafyGrass, { small = true })
	return m
end
B.yew = yew
function B.grave(par, pos, rot, kind, s)
	s = s or 1
	local m = B.model(par, "Grave")
	local b = CFrame.new(pos) * CFrame.Angles(0, math.rad(rot or 0), 0)
	local lean = CFrame.Angles(math.rad(((pos.X * 7 + pos.Z * 3) % 11) - 5), 0, math.rad(((pos.X * 3 + pos.Z * 5) % 9) - 4))
	local col = C.Grave:Lerp(C.Moss, ((pos.X + pos.Z) % 5) * 0.06)
	if kind == "cross" then
		B.part(m, "Shaft", V(0.6 * s, 4.4 * s, 0.5 * s), b * lean * CFrame.new(0, 2.1 * s, 0), col, M.Limestone, { solid = true })
		B.part(m, "Arm", V(2.2 * s, 0.55 * s, 0.42 * s), b * lean * CFrame.new(0, 3.2 * s, 0), col, M.Limestone, { small = true })
	elseif kind == "slab" then
		B.part(m, "Slab", V(2.6 * s, 0.5, 5 * s), b * CFrame.new(0, 0.2, 0), col, M.Limestone, { solid = true })
	else
		B.part(m, "Headstone", V(2.4 * s, 3 * s, 0.45 * s), b * lean * CFrame.new(0, 1.3 * s, 0), col, M.Limestone, { solid = true })
		B.part(m, "Top", V(2.4 * s, 0.7 * s, 0.45 * s), b * lean * CFrame.new(0, 2.95 * s, 0), col, M.Limestone, { small = true, shape = Enum.PartType.Cylinder }).Size = V(0.4 * s, 2.4 * s, 2.4 * s)
	end
	if kind ~= "slab" then
		B.part(m, "Mound", V(2.4 * s, 0.3, 3.4 * s), b * CFrame.new(0, 0.0, -2.1 * s), C.Grass:Lerp(C.Dirt, 0.4), M.Grass, { small = true, collide = false })
	end
	return m
end
-- fix the rounded top orientation (cylinder axis must run through the stone's thickness)
local gy = B.model(EX, "Churchyard")
for i, g in { { -30, -60, "stone" }, { -24, -63, "cross" }, { -18, -58, "stone" }, { -40, -66, "stone" }, { 22, -60, "stone" }, { 28, -64, "cross" }, { 36, -58, "stone" }, { 15, -67, "slab" }, { -52, -25, "stone" }, { -50, 10, "stone" }, { -52, 30, "cross" }, { 50, 0, "stone" }, { 52, 25, "stone" } } do
	local m = B.grave(gy, V(g[1], 0, g[2]), 0, g[3])
	local top = m:FindFirstChild("Top")
	if top then top.CFrame = top.CFrame * CFrame.Angles(0, math.rad(90), 0) end
end
yew(EX, V(-18, 0, -70), 1)
yew(EX, V(20, 0, -70), 1.1)
yew(EX, V(-55.5, 0, -30), 1)
yew(EX, V(54, 0, 38), 1.1)
-- benches along the path
for _, p in { { -8, -60, "+x" }, { 8, -52, "-x" } } do
	local bm = B.model(EX, "Bench")
	local b = B.cf(p[1], 0, p[2], p[3])
	R(bm, "Seat", b, V(4.5, 0.3, 1.4), V(0, 1.7, 0), oak, M.Wood, { solid = true })
	R(bm, "Back", b, V(4.5, 1.4, 0.2), V(0, 2.8, 0.6), oak, M.Wood, SM)
	R(bm, "Leg", b, V(0.3, 1.55, 1.2), V(-1.9, 0.78, 0), C.Iron, M.Metal, { solid = true })
	R(bm, "Leg", b, V(0.3, 1.55, 1.2), V(1.9, 0.78, 0), C.Iron, M.Metal, { solid = true })
	B.L(V(p[1], 1.85, p[2]))
end
-- lantern posts along the path (Lamps)
local function lanternPost(par, pos, h, unlit)
	h = h or 7
	if unlit then
		local m = B.model(par, "LanternPost_Unlit")
		B.box(m, "Post", pos.X - 0.2, 0, pos.Z - 0.2, pos.X + 0.2, h, pos.Z + 0.2, C.Iron, M.Metal, { solid = true })
		B.box(m, "Cage", pos.X - 0.5, h, pos.Z - 0.5, pos.X + 0.5, h + 1.2, pos.Z + 0.5, C.Iron, M.Glass, { small = true, tr = 0.6 })
		B.box(m, "Cap", pos.X - 0.65, h + 1.2, pos.Z - 0.65, pos.X + 0.65, h + 1.45, pos.Z + 0.65, C.Iron, M.Metal, SM)
		return m
	end
	local m = B.model(par, "LanternPost")
	B.box(m, "Post", pos.X - 0.2, 0, pos.Z - 0.2, pos.X + 0.2, h, pos.Z + 0.2, C.Iron, M.Metal, { solid = true })
	B.box(m, "Cage", pos.X - 0.5, h, pos.Z - 0.5, pos.X + 0.5, h + 1.2, pos.Z + 0.5, C.Iron, M.Glass, { small = true, tr = 0.6 })
	B.box(m, "Cap", pos.X - 0.65, h + 1.2, pos.Z - 0.65, pos.X + 0.65, h + 1.45, pos.Z + 0.65, C.Iron, M.Metal, SM)
	local bulb = B.ball(m, "Bulb", CFrame.new(pos), 0.45, V(0, h + 0.55, 0), Color3.fromRGB(255, 200, 140), M.Neon, SM)
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 186, 120)
	l.Range = 20
	l.Brightness = 1
	l.Parent = bulb
	m.PrimaryPart = bulb
	B.attrs(m, { Area = B.A(pos + V(0, 1, 0)) })
	B.tag(m, "Lamp")
	return m
end
B.lanternPost = lanternPost
lanternPost(EX, V(-4.6, 0, -58))
lanternPost(EX, V(4.6, 0, -38.5), 7, true)
lanternPost(EX, V(38.5, 0, 10), 7, true)
-- rain barrel (hiding, Cabinet) by the crypt-stair lean-to, with downpipe
do
	local m = B.model(EX, "RainBarrel")
	local b = CFrame.new(22, 0, -11)
	local wood = C.WoodRaw:Lerp(C.Ink, 0.35)
	for i, a in { 0, 60, 120, 180, 240, 300 } do
		local r = math.rad(a)
		local lift = if i % 2 == 0 then 0.03 else 0
		B.part(m, "Stave", V(1.75, 4.6 - lift + (i % 2) * 0.05, 0.3), b * CFrame.Angles(0, r, 0) * CFrame.new(0, 2.3 + lift / 2 + (i % 2) * 0.025, -1.5), wood, M.Wood, { solid = true })
	end
	for _, y in { 0.8, 3.8 } do
		B.cyl(m, "Hoop", b, 3.42, 0.2, V(0, y, 0), C.Iron, M.Metal, SM)
	end
	local lid = B.cyl(m, "Lid", b, 3.1, 0.2, V(0, 4.65, 0), wood:Lerp(C.Ink, 0.2), M.Wood, SM)
	lid.CFrame = CFrame.new(B.O) * b * CFrame.new(0.5, 4.7, 0.2) * CFrame.Angles(0, 0, math.rad(90 + 8))
	B.box(m, "Downpipe", 21.8, 4.7, -8.9, 22.2, 13, -8.5, C.Metal:Lerp(C.Ink, 0.3), M.Metal, SM)
	B.HP(m, "Cabinet", CFrame.new(22, 1.8, -11), V(22, 0, -15), V(21, 0, -15.2))
end

----------------------------------------------------------------- search nodes (Ground)
for _, n in {
	{ 0, G, -27.5 }, { -8, G, -16 }, { 8, G, -16 },
	{ 0, G, -8 }, { 0, G, 5 }, { 0, G, 20.5 }, { 12.5, G, 4 }, { -12.5, G, 4 },
	{ -27, G, -16 }, { -21.25, G, 19.5 }, { 0, G, 33 }, { -17, G, 31.5 }, { 16, G, 34.5 }, { 22.5, G, 34 },
	{ -15, G, 45.5 }, { 0, G, 45.5 }, { 15, G, 45.5 },
	{ 0, 0, -55 }, { -50, 0, 5 }, { 44, 0, 20 }, { -22, 0, -29 }, { 15, 0, -29 }, { 22, 0, -17 }, { -33, 0, 20 },
} do
	B.N(n[1], n[2], n[3])
end
B.N(23.4, G, 29.2, true) -- vestry WC (Bathroom)
-- a little outdoor loot
B.L(V(-24, 0.2, -61.3))
B.L(V(36, 0.2, -59.5))
return "ground ok, parts=" .. B.count(B.root())
