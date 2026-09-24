-- HarvestFair Ground zone part 2: carousel plaza (stopped carousel, generator = FuseBox, candy-floss cart,
-- high striker), the fortune-teller's tent (Grandma's velvet armchair + crystal ball = GrandmaSleepSpot),
-- west field, scarecrow field, promenade + rooms/nodes/loot. Section "plaza" (idempotent).
local B = _G.HF
local C, M = B.C, B.M
local V = Vector3.new
local root = B.root()
local S = B.begin("plaza")
local SM = { small = true }
local G = "Ground"
local function sdoor(par, name, center, dir, w, h, col, kind, danger)
	local p = B.part(par, name, V(w, h, 0.12), CFrame.lookAt(center, center + dir), col, M.Wood, { collide = false, shadow = false })
	return B.searchable(p, kind, G, danger or 1)
end
-- square/rect pyramid roof from 4 CornerWedgeParts (apex over the centre). hx/hz = half extents.
function B.pyramid(par, cx, cz, hx, hz, y0, h, c1, c2, mat)
	local quads = { { 1, 1, 90 }, { -1, 1, 0 }, { -1, -1, -90 }, { 1, -1, 180 } }
	for i, q in quads do
		local sx, sz, th = q[1], q[2], q[3]
		local size = if th == 0 or th == 180 then V(hx, h, hz) else V(hz, h, hx)
		B.part(par, "Roof", size, CFrame.new(cx + sx * hx / 2, y0 + h / 2, cz + sz * hz / 2) * CFrame.Angles(0, math.rad(th), 0), if i % 2 == 0 then c1 else c2, mat or M.Fabric, { solid = true, class = "CornerWedgePart" })
	end
end

----------------------------------------------------------------- carousel (stopped) at (0, 20)
do
	local m = B.model(S, "Carousel")
	local c = V(0, 0.05, 20)
	local base = CFrame.new(c)
	B.cyl(m, "Platform", base, 22, 1.2, V(0, 0.6, 0), C.WoodMid:Lerp(C.Ink, 0.2), M.WoodPlanks, { solid = true }, true)
	B.cyl(m, "PlatformTrim", base, 22.3, 0.3, V(0, 0.95, 0), C.Gold:Lerp(C.Ink, 0.35), M.Wood, SM, true)
	B.cyl(m, "Column", base, 4, 11, V(0, 6.7, 0), C.Red:Lerp(C.Ink, 0.3), M.Wood, { solid = true }, true)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local dir = V(math.cos(a), 0, math.sin(a))
		local p = c + dir * 2.05 + V(0, 6.7, 0)
		B.part(m, "Mirror", V(1.2, 3, 0.1), CFrame.lookAt(p, p + dir), C.Glass:Lerp(C.Paper, 0.3), M.Glass, { small = true, refl = 0.3 })
	end
	B.cyl(m, "Canopy", base, 25, 0.8, V(0, 12.6, 0), C.Cream:Lerp(C.Ink, 0.2), M.Fabric, { solid = true }, true)
	B.cyl(m, "CanopyTop", base, 16, 1.2, V(0, 13.6, 0), C.Red:Lerp(C.Ink, 0.2), M.Fabric, SM, true)
	B.cyl(m, "CanopyCap", base, 8, 1.2, V(0, 14.8, 0), C.Cream:Lerp(C.Ink, 0.2), M.Fabric, SM, true)
	B.cyl(m, "Finial", base, 1, 1.6, V(0, 16.2, 0), C.Gold, M.Metal, SM, true)
	-- valance: 16 hanging panels round the canopy edge
	for i = 0, 15 do
		local a = (i + 0.5) / 16 * math.pi * 2
		local dir = V(math.cos(a), 0, math.sin(a))
		local p = c + dir * 12.45 + V(0, 11.4, 0)
		B.part(m, "Valance", V(4.9, 1.6, 0.12), CFrame.lookAt(p, p + dir), if i % 2 == 0 then C.Red:Lerp(C.Ink, 0.2) else C.Cream:Lerp(C.Ink, 0.15), M.Fabric, SM)
	end
	-- horses on poles
	local hc = { C.Paper, C.Rose, C.Mint, C.Mustard, C.Paper, C.Bruise, C.Teal, C.Paper }
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2 + 0.2
		local p = c + V(math.cos(a) * 8, 1.25, math.sin(a) * 8)
		local tangent = V(-math.sin(a), 0, math.cos(a))
		local hb = CFrame.lookAt(p, p + tangent)
		local h = 2.2 + (i % 2) * 0.9 -- frozen mid-bob
		B.rp(m, "Pole", hb, V(0.25, 10.95, 0.25), V(0, 5.475, 0), C.Gold:Lerp(C.Paper, 0.2), M.Metal, SM)
		local col = hc[i + 1]:Lerp(C.Ink, 0.15)
		B.rp(m, "HorseBody", hb, V(1.2, 1.4, 3.2), V(0, h + 0.7, 0), col, M.SmoothPlastic, SM)
		B.rp(m, "HorseNeck", hb, V(0.9, 1.8, 0.9), V(0, h + 1.8, -1.5), col, M.SmoothPlastic, SM, CFrame.Angles(math.rad(-25), 0, 0))
		B.rp(m, "HorseHead", hb, V(0.9, 0.9, 1.6), V(0, h + 2.6, -2.1), col, M.SmoothPlastic, SM)
		B.rp(m, "Saddle", hb, V(1.3, 0.3, 1.2), V(0, h + 1.5, 0.2), C.Red:Lerp(C.Ink, 0.2), M.Fabric, SM)
		for _, zz in { -1.2, 1.2 } do
			B.rp(m, "Legs", hb, V(0.9, 1.1, 0.4), V(0, h - 0.5, zz), col, M.SmoothPlastic, SM, CFrame.Angles(math.rad(zz * 15), 0, 0))
		end
		B.rp(m, "Eye", hb, V(0.92, 0.18, 0.18), V(0, h + 2.8, -2.5), C.Ink, M.SmoothPlastic, SM)
	end
	-- two bulb rings (Lamp): bulbs round the canopy rim, one light each
	for k = 0, 1 do
		local lm = B.model(m, "Lamp_CarouselRing")
		local first
		for i = 0, 7 do
			local a = (i * 2 + k) / 16 * math.pi * 2
			local p = c + V(math.cos(a) * 12.1, 13.25, math.sin(a) * 12.1)
			local dead = (i + k) % 4 == 3
			local b = B.part(lm, if dead then "DeadBulb" else "Bulb", V(0.5, 0.5, 0.5), CFrame.new(p), if dead then Color3.fromRGB(70, 66, 60) else Color3.fromRGB(255, 210, 150), if dead then M.Glass else M.Neon, { small = true, shape = Enum.PartType.Ball })
			if not dead and not first then first = b end
		end
		local l = Instance.new("PointLight")
		l.Range = 24
		l.Brightness = 1
		l.Color = Color3.fromRGB(255, 196, 140)
		l.Parent = first
		lm.PrimaryPart = first
		B.attrs(lm, { Area = G })
		B.tag(lm, "Lamp")
	end
	-- loot on the platform edge
	for _, a in { 0.6, 3.9 } do
		B.loot(G, 1, c + V(math.cos(a) * 10.2, 1.2, math.sin(a) * 10.2))
	end
	-- low ticket barrier posts round the platform (decor)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		B.part(m, "RopePost", V(0.4, 3, 0.4), CFrame.new(c + V(math.cos(a) * 12.4, 1.5, math.sin(a) * 12.4)), C.Gold:Lerp(C.Ink, 0.4), M.Metal, SM)
	end
end

----------------------------------------------------------------- generator (FuseBox) beside the carousel
do
	local m = B.model(S, "Generator")
	local x, z = 22, 38
	B.box(m, "Skid", x - 3, 0.05, z - 1.8, x + 3, 0.6, z + 1.8, C.Metal:Lerp(C.Ink, 0.4), M.Metal, { solid = true })
	B.box(m, "Body", x - 2.8, 0.6, z - 1.6, x + 2.8, 4.2, z + 1.6, C.Mustard:Lerp(C.Ink, 0.35), M.Metal, { solid = true })
	B.box(m, "Exhaust", x + 1.8, 4.2, z + 0.4, x + 2.3, 6, z + 0.9, C.Ink, M.Metal, SM)
	B.box(m, "Grille", x - 2.2, 1.2, z - 1.65, x + 0.2, 3.6, z - 1.6, C.Ink, M.Metal, SM)
	local fb = B.box(root, "FuseBox", x + 0.8, 1.6, z - 2.1, x + 2.6, 4.0, z - 1.6, C.Metal:Lerp(C.Mint, 0.2), M.Metal, { solid = true })
	B.mark(fb)
	B.box(m, "FuseLever", x + 2.3, 2.6, z - 2.3, x + 2.5, 3.4, z - 2.1, C.Blood, M.Metal, SM)
	local sg = B.box(m, "DangerSign", x - 2, 3.7, z - 1.66, x - 0.4, 4.1, z - 1.6, C.Mustard, M.SmoothPlastic, SM)
	-- cable runs to the carousel
	do
		local a, b = V(x - 3, 0.12, z), V(7.98, 0.12, 27.55)
		B.part(m, "Cable", V(0.2, 0.15, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), C.Ink, M.Rubber, SM)
	end
	B.lamp(m, "flood", B.cf(x - 4, 0.05, z - 3, 50), G, { spot = true, face = Enum.NormalId.Front, angle = 80, range = 26, bright = 1.1 })
end

----------------------------------------------------------------- plaza dressing
do -- candy floss cart (Searchable drawer) with striped parasol
	local m = B.model(S, "CandyFlossCart")
	local x, z = -30, 34
	B.box(m, "Cart", x - 3, 1.2, z - 1.5, x + 3, 3.6, z + 1.5, C.Rose:Lerp(C.Ink, 0.25), M.Wood, { solid = true })
	B.box(m, "CartTop", x - 3.2, 3.6, z - 1.7, x + 3.2, 3.85, z + 1.7, C.Paper:Lerp(C.Ink, 0.15), M.Wood, { solid = true })
	for _, sz in { -1, 1 } do
		local wc = CFrame.new(x - 2.2, 1.25, z + sz * 1.65) * CFrame.Angles(0, math.rad(90), 0)
		B.set(B.cyl(m, "Wheel", wc, 2.4, 0.3, V(0, 0, 0), C.Ink, M.Wood, SM, false), wc)
		B.box(m, "Leg", x + 2.4, 0.05, z + sz * 1 - 0.2, x + 2.8, 1.2, z + sz * 1 + 0.2, C.WoodDark, M.Wood, SM)
	end
	B.cyl(m, "Drum", CFrame.new(x, 3.85, z), 2.2, 1.2, V(0, 0.6, 0), C.Metal, M.Metal, SM, true)
	B.ball(m, "Floss", CFrame.new(x + 1.9, 3.85, z), 1.3, V(0, 1.4, 0), C.Rose:Lerp(C.Paper, 0.4), M.Fabric, SM)
	B.box(m, "Stick", x + 1.86, 3.85, z - 0.04, x + 1.94, 4.9, z + 0.04, C.Paper, M.Wood, SM)
	B.box(m, "ParasolPole", x - 2.3, 3.85, z - 0.1, x - 2.1, 10, z + 0.1, C.Paper, M.Metal, SM)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local p0 = V(x - 2.2, 10.1, z)
		local p1 = p0 + V(math.cos(a) * 3.2, -1.1, math.sin(a) * 3.2)
		B.part(m, "Parasol", V(2.4, 0.1, (p1 - p0).Magnitude), CFrame.lookAt((p0 + p1) / 2, p1), if i % 2 == 0 then C.Rose else C.Cream, M.Fabric, SM)
	end
	sdoor(m, "CartDrawer", V(x + 0.8, 2.4, z - 1.56), V(0, 0, -1), 2.4, 0.9, C.Paper:Lerp(C.Rose, 0.3), "Drawer")
	B.loot(G, 1, V(x - 1.2, 3.85, z + 0.8))
end
do -- high striker ("test your strength")
	local m = B.model(S, "HighStriker")
	local x, z = 42, 6
	B.box(m, "Base", x - 1.5, 0.05, z - 1.5, x + 1.5, 0.8, z + 1.5, C.WoodDark, M.Wood, { solid = true })
	B.box(m, "Tower", x - 0.5, 0.8, z - 0.2, x + 0.5, 16, z + 0.2, C.Red:Lerp(C.Ink, 0.3), M.Wood, { solid = true })
	for i = 1, 6 do
		B.box(m, "Band", x - 0.52, 0.8 + i * 2.2, z - 0.22, x + 0.52, 1.1 + i * 2.2, z + 0.22, C.Cream, M.SmoothPlastic, SM)
	end
	B.part(m, "Bell", V(1.4, 1.4, 1.4), CFrame.new(x, 16.6, z), C.Gold, M.Metal, { small = true, shape = Enum.PartType.Ball })
	B.box(m, "Pad", x - 1, 0.8, z - 1.4, x + 1, 1.1, z - 0.4, C.Blood, M.Rubber, SM)
	B.box(m, "Mallet", x + 1.2, 0.8, z - 1.2, x + 1.5, 4, z - 0.9, C.WoodLight, M.Wood, SM)
	local sg = B.box(m, "Sign", x - 1.6, 14.4, z - 0.28, x + 1.6, 15.9, z - 0.2, C.Paper, M.Wood, SM)
	B.text(sg, "RING THE BELL", { face = Enum.NormalId.Front, color = C.Red })
end
for _, p in { { V(-36, 0.05, 6), "+x" }, { V(34, 0.05, 30), "-x" }, { V(-10, 0.05, 42), "+z" } } do
	B.bench(S, B.cf(p[1].X, p[1].Y, p[1].Z, p[2]), 6)
end
B.loot(G, 1, V(-36, 2.0, 6))
for i, p in { V(-38, 0.05, 40), V(46, 0.05, -2), V(16, 0.05, -2), V(-18, 0.05, 44) } do
	B.hay(S, B.cf(p.X, p.Y, p.Z, i * 25), { tint = i * 0.05 })
end
B.loot(G, 1, V(46, 2.25, -2))
for i, p in { V(-37, 0.05, 43), V(-36, 0.05, 37), V(47.5, 0.05, 1), V(18.5, 0.05, -3.5), V(12, 0.05, 44) } do
	B.pumpkinProp(S, p, 0.8 + (i % 3) * 0.25, i % 2 == 1)
end
B.lamp(S, "post", B.cf(-26, 0.05, -3, "+z"), G, { range = 26 })
B.lamp(S, "post", B.cf(40, 0.05, 44, "-z"), G, { range = 26 })

----------------------------------------------------------------- fortune teller's tent (x -72..-48, z 6..30), Grandma sleeps here
do
	local m = B.model(S, "FortuneTent")
	local x0, x1, z0, z1 = -72, -48, 6, 30
	local y0, H = 0.08, 10
	local c1, c2 = C.Plum:Lerp(C.Ink, 0.2), C.Cream:Lerp(C.Ink, 0.25)
	B.box(m, "Floor", x0, -0.1, z0, x1, y0, z1, C.WoodDark:Lerp(C.Plum, 0.15), M.WoodPlanks, { solid = true })
	-- striped canvas walls; flaps: south (x=-60) and east (z=18), 8 wide x 9 tall
	B.stripes(m, "Canvas", "x", z0 + 0.2, x0, x1, y0, H, 0.4, c1, c2, 2, { { c = -60, w = 8, h = 9 - y0 } })
	B.stripes(m, "Canvas", "x", z1 - 0.2, x0, x1, y0, H, 0.4, c1, c2, 2)
	B.stripes(m, "Canvas", "z", x0 + 0.2, z0 + 0.4, z1 - 0.4, y0, H, 0.4, c1, c2, 2)
	B.stripes(m, "Canvas", "z", x1 - 0.2, z0 + 0.4, z1 - 0.4, y0, H, 0.4, c1, c2, 2, { { c = 18, w = 8, h = 9 - y0 } })
	B.pyramid(m, -60, 18, 12.5, 12.5, H, 9, c1, c2)
	B.box(m, "Pennant", -60.15, H + 9, 17.85, -59.85, H + 12, 18.15, C.Ink, M.Metal, SM)
	B.box(m, "Flag", -59.85, H + 11, 17.9, -58.2, H + 11.9, 18.1, C.Mustard, M.Fabric, SM)
	-- tied-back flaps
	for _, sx in { -1, 1 } do
		B.box(m, "Flap", -60 + sx * 4 - 0.6, y0, z0 - 0.35, -60 + sx * 4 + 0.6, 9, z0, C.Velvet, M.Fabric, SM)
		B.box(m, "Flap", x1, y0, 18 + sx * 4 - 0.6, x1 + 0.35, 9, 18 + sx * 4 + 0.6, C.Velvet, M.Fabric, SM)
	end
	local sign = B.box(m, "Sign", x1, 9.2, 13, x1 + 0.1, 11.4, 23, C.Night, M.Wood, SM)
	B.text(sign, "MADAME GRANDMA\nSEES ALL", { face = Enum.NormalId.Right, color = C.Mustard, font = Enum.Font.LuckiestGuy })
	-- interior: rugs, draped ceiling, curtains
	B.rug(m, -60, y0, 18, 14, 12, C.Velvet, C.Gold:Lerp(C.Ink, 0.4))
	for i = 0, 3 do
		B.box(m, "Drape", x0 + 0.4, H - 1.6 - (i % 2) * 0.4, z0 + 2 + i * 6, x0 + 0.5, H, z0 + 4.5 + i * 6, C.Velvet:Lerp(C.Ink, 0.2), M.Fabric, SM)
	end
	-- Grandma's velvet armchair (GrandmaChair) facing the east flap
	local chairB = B.cf(-67, y0, 18, "+x")
	local chair = B.armchair(root, chairB, C.Velvet, "GrandmaChair", { trim = C.Gold:Lerp(C.Ink, 0.2) })
	B.mark(chair)
	local sp = (chairB * CFrame.new(0, 3.6, -0.3)).Position
	local ss = B.part(root, "GrandmaSleepSpot", V(2, 2, 1), CFrame.lookAt(sp, sp + V(1, 0, 0)), C.Paper, M.SmoothPlastic, { inv = true })
	B.mark(ss)
	-- crystal ball table (Lamp: the ball glows)
	local tb = CFrame.new(-58, y0, 18)
	B.cyl(m, "TableTop", tb, 4, 0.3, V(0, 3.05, 0), C.WoodDark, M.Wood, { solid = true }, true)
	B.cyl(m, "TableCloth", tb, 4.3, 3.1, V(0, 1.55, 0), C.Plum:Lerp(C.Ink, 0.3), M.Fabric, { solid = true }, true)
	B.cyl(m, "BallStand", tb, 1, 0.4, V(0, 3.4, 0), C.Gold, M.Metal, SM, true)
	do
		local lm = B.model(m, "Lamp_CrystalBall")
		B.ball(lm, "Glass", tb, 1.6, V(0, 4.35, 0), C.Glass:Lerp(C.Paper, 0.3), M.Glass, { small = true, tr = 0.5 })
		local core = B.ball(lm, "Bulb", tb, 0.8, V(0, 4.35, 0), Color3.fromRGB(190, 150, 255), M.Neon, SM)
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(170, 130, 255)
		l.Range = 16
		l.Brightness = 1.1
		l.Parent = core
		lm.PrimaryPart = core
		B.attrs(lm, { Area = G })
		B.tag(lm, "Lamp")
	end
	for i = 0, 2 do
		B.part(m, "TarotCard", V(0.5, 0.03, 0.8), CFrame.new(-57.1 + i * 0.1, y0 + 3.215, 16.8 + i * 0.7) * CFrame.Angles(0, math.rad(i * 12 - 10), 0), if i == 1 then C.Blood else C.Paper, M.SmoothPlastic, SM)
	end
	B.loot(G, 3, V(-56.8, y0 + 3.2, 19.2))
	-- side table beside the chair: the Prize
	local st, sh = B.table(m, B.cf(-67, y0, 23.2, "+x"), 2.2, 2.2, 2.8, C.WoodDark)
	B.prize(G, V(-67, y0 + sh, 23.2))
	B.candleSet(m, V(-67.6, y0 + sh, 22.6), 3, 1)
	local st2, sh2 = B.table(m, B.cf(-67, y0, 12.8, "+x"), 2.2, 2.2, 2.8, C.WoodDark)
	B.lamp(m, "candle", CFrame.new(-67.3, y0 + sh2, 12.5), G, { h = 0.9, range = 12, bright = 0.8 })
	B.loot(G, 3, V(-66.6, y0 + sh2, 13.2))
	-- vanity with mirror (Vanity), costume trunk (Trunk), shelf of jars
	B.dresser(m, B.cf(-58, y0, 28.75, "-z"), 4, 1.6, 3, C.WoodDark:Lerp(C.Plum, 0.3), 2, G, 3, { search = { 1 }, kind = "Vanity", name = "Vanity" })
	B.box(m, "VanityMirror", -59.6, y0 + 3.2, 29.2, -56.4, 7, 29.6, C.Gold:Lerp(C.Ink, 0.3), M.Wood, SM)
	B.box(m, "MirrorGlass", -59.3, y0 + 3.5, 29.15, -56.7, 6.7, 29.2, C.Glass:Lerp(C.Paper, 0.4), M.Glass, { small = true, refl = 0.4 })
	B.loot(G, 3, V(-57, y0 + 3.2, 28.4))
	B.trunk(m, B.cf(-52, y0, 27.8, "-z"), C.Velvet:Lerp(C.Ink, 0.3), G, 3)
	B.jarBreak(m, V(-59.2, y0 + 3.2, 28.4), C.Mint, 0.7)
	B.box(m, "ShelfBoard", -71.6, 5, 8, -70.4, 5.2, 13, C.WoodDark, M.Wood, SM)
	B.jarBreak(m, V(-71, 5.2, 9.2), C.Rose, 0.8)
	B.jarBreak(m, V(-71, 5.2, 11.6), C.Bruise, 0.8)
	B.loot(G, 3, V(-71, 5.2, 10.4))
	B.lamp(m, "lantern", CFrame.new(-55, H, 12), G, { range = 18, bright = 0.9, color = Color3.fromRGB(255, 170, 120) })
	-- creaky planks round the chair
	B.creak(-60, y0, 9, 0)
	B.creak(-64, y0, 9.5, 0)
	B.creak(-51, y0, 14, 0)
	B.creak(-51, y0, 22.5, 0)
	B.creak(-63.5, y0, 26.5, 0)
	-- boardwalk approach to the east flap (with a creaky patch)
	B.box(m, "Boardwalk", -47.6, 0.05, 15, -44, 0.2, 21, C.WoodMid:Lerp(C.Ink, 0.2), M.WoodPlanks, { solid = true, shadow = false })
	B.creak(-42, 0.18, 18, 0)
	B.box(m, "Boardwalk", -40, 0.05, 15, -36.4, 0.2, 21, C.WoodMid:Lerp(C.Ink, 0.2), M.WoodPlanks, { solid = true, shadow = false })
end
-- tent backs: crates + costume trunk
B.crate(S, B.cf(-66, 0, 36, 10), 3)
B.crate(S, B.cf(-62.6, 0, 35.2, -5), 2.4)
B.loot(G, 2, V(-66, 3, 36))
B.trunk(S, B.cf(-54, 0, 34, "+z"), C.WoodMid, G, 2, { name = "CostumeTrunk" })
B.hay(S, B.cf(-68, 0, 0, 5))
B.loot(G, 2, V(-68, 2.2, 0))

----------------------------------------------------------------- west field + scarecrow field + promenade
do
	local m = B.model(S, "HayWagon")
	local b = B.cf(-86, 0, 22, 0)
	B.rp(m, "Bed", b, V(7, 0.5, 12), V(0, 2.3, 0), C.WoodMid, M.WoodPlanks, { solid = true })
	for _, sx in { -1, 1 } do
		B.rp(m, "Side", b, V(0.3, 1.4, 12), V(sx * 3.35, 3.25, 0), C.WoodMid:Lerp(C.Ink, 0.2), M.WoodPlanks, { solid = true })
		for _, zz in { -4.5, 4.5 } do
			B.cyl(m, "Wheel", b, 4, 0.5, V(sx * 3.75, 2, zz), C.WoodDark, M.Wood, { solid = true }, false)
		end
	end
	B.hay(m, b * CFrame.new(-1.2, 2.55, -2), { size = V(3.8, 2.2, 2.4) })
	B.hay(m, b * CFrame.new(1.2, 2.55, 2.5), { size = V(3.8, 2.2, 2.4), tint = 0.2 })
	B.loot(G, 1, V(-86, 2.55, 0) + V(0, 0, 22 + 5))
end
for i, p in { V(-90, 0, 40), V(-80, 0, 4), V(-94, 0, 8) } do
	B.pumpkinProp(S, p, 1 + (i % 2) * 0.4, i == 2)
end
do -- scarecrow field (east, north of the funhouse): scarecrows + hay rows
	for i, p in { V(60, 0, 80), V(84, 0, 70), V(74, 0, 96) } do
		local m = B.model(S, "Scarecrow")
		local b = B.cf(p.X, 0, p.Z, i * 70)
		B.rp(m, "Pole", b, V(0.4, 9, 0.4), V(0, 4.5, 0), C.WoodDark, M.Wood, { solid = true })
		B.rp(m, "Shirt", b, V(2.6, 2.8, 1.2), V(0, 6, 0), (if i == 2 then C.Teal else C.Plum):Lerp(C.Ink, 0.4), M.Fabric, SM)
		B.rp(m, "Sleeves", b, V(5.4, 0.9, 0.9), V(0, 6.8, 0), C.Plum:Lerp(C.Ink, 0.45), M.Fabric, SM)
		B.ball(m, "Head", b, 1.8, V(0, 8.3, 0), C.Pumpkin:Lerp(C.Ink, 0.3), M.SmoothPlastic, SM)
		B.rp(m, "Face", b, V(0.8, 0.35, 0.1), V(0, 8.2, -0.88), Color3.fromRGB(255, 160, 60), M.Neon, SM)
	end
	for r = 0, 2 do
		for k = 0, 2 do
			local x, z = 54 + k * 14, 66 + r * 13
			B.hay(S, B.cf(x, 0, z, (r * 3 + k) * 17))
		end
	end
	B.loot(G, 1, V(54, 2.2, 66))
	B.lamp(S, "post", B.cf(66, 0, 62, "+z"), G, { range = 26 })
end
B.bench(S, B.cf(-20, 0.05, 57, "-z"), 6)
B.bench(S, B.cf(20, 0.05, 57, "-z"), 6)
B.loot(G, 1, V(20, 2.0, 57))

----------------------------------------------------------------- rooms, nodes
B.room("Carousel Plaza", G, 1, -48, -1, -5, 58, 18, 48)
B.room("Fortune Teller's Tent", G, 3, -72, -1, 6, -48, 12, 30)
B.room("Fortune Path", G, 2, -72, -1, -5, -48, 16, 6)
B.room("Tent Backs", G, 2, -72, -1, 30, -48, 16, 48)
B.room("West Field", G, 1, -100, -1, -5, -72, 16, 48)
B.room("Ghost Train Queue", G, 1, -100, -1, 48, -40, 16, 65)
B.room("Ghost Alley", G, 1, -60, -1, 65, -40, 16, 105)
B.room("Big Top Promenade", G, 1, -40, -1, 48, 58, 16, 60)
B.room("Funhouse Yard", G, 1, 58, -1, 35, 100, 16, 60)
B.room("Scarecrow Field", G, 1, 40, -1, 60, 100, 16, 105)
B.node(G, -20, 0.05, 8)
B.node(G, 20, 0.05, 6)
B.node(G, -18, 0.05, 36)
B.node(G, -52.5, 0.08, 18)
B.node(G, -64, 0.08, 10)
B.node(G, -60, 0.05, 0)
B.node(G, -60, 0.05, 40)
B.node(G, -86, 0.05, 10)
B.node(G, -70, 0.05, 54)
B.node(G, -50, 0.05, 85)
B.node(G, 0, 0.05, 54)
B.node(G, 78, 0.05, 48)
B.node(G, 68, 0.05, 86)
return "plaza ok, parts=" .. B.count(root)
