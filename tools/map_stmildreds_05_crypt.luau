-- St. Mildred's 05: BASEMENT = THE CRYPT (night 3): iron crypt gate (Barrier), crypt stairs, crypt hall with coffins,
-- burial vault (alcoves, effigy tomb), founders' vault. Tasteful: closed coffins, candles, urns.
local B = _G.SMB
local C, M = B.C, B.M
local V = Vector3.new
local SM = B.SM
local BA = B.F("Basement")
local IA = B.F("Interactables")
local F = -11
local oak = C.Oak
local oakD = C.Oak:Lerp(C.Ink, 0.3)
local stone = C.StoneD:Lerp(C.Ink, 0.2)
local function R(m, n, b, sz, off, col, mat, o) return B.rp(m, n, b, sz, off, col, mat, o) end

----------------------------------------------------------------- barrier: iron gate in the nave's east doorway
do
	local m = B.model(B.F("Barriers"), "Barrier_Basement")
	for i = 0, 8 do
		local z = -6 + i * 0.5
		B.cyl(m, "Bar", CFrame.new(16.75, 2, z), 0.16, 7.9, V(0, 3.98, 0), C.Iron, M.Metal, { collide = true, query = true, shadow = true })
	end
	for _, y in { 2.6, 6.2, 9.6 } do
		B.box(m, "Rail", 16.62, y - 0.12, -6.2, 16.88, y + 0.12, -1.8, C.Iron, M.Metal, { collide = true })
	end
	B.box(m, "Chain", 16.4, 5.5, -4.6, 16.5, 5.7, -2.2, C.Metal, M.Metal, SM)
	B.box(m, "Padlock", 16.2, 4.9, -3.1, 16.45, 5.65, -2.5, C.Brass, M.Metal, SM)
	B.box(m, "Collider", 16.3, 2, -6.25, 17.2, 10, -1.75, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	m.PrimaryPart = m:FindFirstChild("Collider")
	B.attrs(m, { Area = "Basement" })
end

----------------------------------------------------------------- crypt stairs dressing
do
	local CS = B.model(BA, "CryptStairsDressing")
	B.LP(CS, "sconce", B.cf(24.95, 7.2, -4, "-x"), { shade = C.Wax, range = 16, bright = 0.8 })
	B.LP(CS, "sconce", B.cf(24.95, -1.5, 12, "-x"), { shade = C.Wax, range = 16, bright = 0.8 })
	B.box(CS, "Crate", 23.4, 2, -7, 25, 3.3, -5.6, C.WoodRaw, M.WoodPlanks, { solid = true })
	B.L(V(24.2, 3.3, -6.3))
	B.cobweb(CS, V(24.4, 11.5, -6.4), 225, 1)
	B.N(21.25, 2, -4.5)
	B.N(21.25, F, 22.6)
end

----------------------------------------------------------------- coffins, tombs, alcoves
local function coffin(par, b, len, col)
	local m = B.model(par, "Coffin")
	R(m, "Box", b, V(2.2, 1.4, len), V(0, 0.7, 0), col, M.Wood, { solid = true })
	R(m, "Lid", b, V(2.4, 0.25, len + 0.2), V(0, 1.52, 0), col:Lerp(C.Ink, 0.2), M.Wood, SM)
	R(m, "Plate", b, V(0.9, 0.05, 0.6), V(0, 1.665, -len * 0.2), C.Brass, M.Metal, SM)
	for _, sz in { -0.3, 0.3 } do
		R(m, "Handle", b, V(0.1, 0.12, 0.8), V(1.15, 0.8, sz * len), C.Brass, M.Metal, SM)
		R(m, "Handle", b, V(0.1, 0.12, 0.8), V(-1.15, 0.8, sz * len), C.Brass, M.Metal, SM)
	end
	return m, 1.645
end
local function bier(par, b, len)
	local m = B.model(par, "Bier")
	R(m, "Top", b, V(2.6, 0.3, len + 0.4), V(0, 1.55, 0), stone, M.Limestone, { solid = true })
	R(m, "Base", b, V(2.2, 1.4, len), V(0, 0.7, 0), stone:Lerp(C.Ink, 0.15), M.Limestone, { solid = true })
	return m, 1.7
end
local function curtainAlcove(par, name, x0, x1, z0, z1, curtainX, dir)
	-- alcove bay between two stone piers; curtain across its mouth at curtainX. dir = +1 if the room is on +x of the curtain
	local m = B.model(par, name)
	local zc = (z0 + z1) / 2
	local w = z1 - z0
	for i = 0, 3 do
		local zz = z0 + 0.1 + (w - 0.2) * (i + 0.5) / 4
		local off = (i % 2) * 0.05
		B.box(m, "Curtain", curtainX - 0.08 + off, F + 0.15, zz - (w - 0.2) / 8 - 0.02, curtainX + 0.08 + off, F + 8.6 - off, zz + (w - 0.2) / 8 + 0.02, C.Velvet:Lerp(C.Ink, 0.2 + (i % 2) * 0.12), M.Fabric, { collide = false, shadow = true })
	end
	B.box(m, "Rod", curtainX - 0.1, F + 8.7, z0, curtainX + 0.1, F + 8.9, z1, C.Brass, M.Metal, SM)
	local ins = V((x0 + x1) / 2, F + 3.1, zc)
	local front = V(curtainX + dir * 2.3, F, zc)
	B.HP(m, "Closet", CFrame.lookAt(ins, ins + V(dir, 0, 0)), front, V(curtainX + dir * 2.1, F, zc + 0.8))
	return m
end
local function pier(par, x0, x1, z0, z1)
	B.box(par, "Pier", x0, F, z0, x1, 0.9, z1, stone, M.Limestone, { solid = true })
end
local function crypt_candle(par, pos, h) return B.candleLamp(par, pos, h or 0.9, { range = 12, bright = 0.75 }) end

----------------------------------------------------------------- crypt hall
do
	local H = B.model(BA, "CryptHall")
	for _, x in { -21, -11 } do
		local b = B.cf(x, F, 26.9, "+x")
		local _, bh = bier(H, b, 6)
		coffin(H, b * CFrame.new(0, bh, 0), 5.6, oakD)
	end
	B.L(V(-25.2, F + 1.8, 32.6))
	B.L(V(10.6, F + 1.8, 32.9))
	-- stone benches along the divider
	for _, x in { -9.3, 9.3 } do
		B.box(H, "StoneBench", x - 2.2, F, 32.0, x + 2.2, F + 1.8, 33.3, stone, M.Limestone, { solid = true })
	end
	B.L(V(-8.5, F + 1.8, 32.9))
	-- iron candelabrum (Lamp) in the middle
	do
		local m = B.model(H, "Candelabrum")
		local b = CFrame.new(0, F, 26.6)
		B.cyl(m, "Foot", b, 1.4, 0.3, V(0, 0.15, 0), C.Iron, M.Metal, { solid = true })
		B.cyl(m, "Stem", b, 0.25, 4.2, V(0, 2.4, 0), C.Iron, M.Metal, { solid = true })
		B.box(m, "Arms", -1.3, F + 4.4, 26.5, 1.3, F + 4.6, 26.7, C.Iron, M.Metal, SM)
		local first
		for _, x in { -1.2, 0, 1.2 } do
			B.cyl(m, "Candle", CFrame.new(x, F + 4.6, 26.6), 0.28, 0.9, V(0, 0.45, 0), C.Wax, M.SmoothPlastic, SM)
			local f = B.ball(m, "Bulb", CFrame.new(x, F + 4.6, 26.6), 0.2, V(0, 1.05, 0), C.FlameC, M.Neon, SM)
			first = first or f
		end
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 170, 100)
		l.Range = 22
		l.Brightness = 0.9
		l.Parent = first
		m.PrimaryPart = first
		B.attrs(m, { Area = B.A(V(0, F + 1, 26.6)) })
		B.tag(m, "Lamp")
	end
	-- old chest by the stairs
	local tr = B.trunk(H, B.cf(24.3, F, 30.5, "-x"), oakD, "Basement", 3, { w = 3.2, d = 1.8 })
	tr.Name = "CryptChest"
	B.S(tr:FindFirstChild("Lid"), "Trunk")
	B.L(V(24.3, F + 2.15, 30.5))
	crypt_candle(H, V(-25.2, F + 1.8, 31.8), 0.9)
	B.box(H, "Ledge", -26, F, 30.6, -24.4, F + 1.8, 33, stone, M.Limestone, { solid = true })
	B.cobweb(H, V(-25.2, 0.2, 26.3), 45, 1.3)
	B.cobweb(H, V(25.3, 0.2, 33), 225, 1.1)
	B.N(-12, F, 30.3)
	B.N(12, F, 30.3)
	B.N(0, F, 31.5)
end
B.door2(IA, "BurialVaultDoor", "x", 34, -14, F, true, false, oakD, 1)
B.door2(IA, "FoundersVaultDoor", "x", 34, 14, F, true, false, oakD, -1)
B.door2(IA, "VaultPassDoor", "z", 0, 42, F, false, false, oakD, 1)

----------------------------------------------------------------- burial vault (west)
do
	local BV = B.model(BA, "BurialVault")
	pier(BV, -26, -22.5, 40.5, 41.5)
	pier(BV, -26, -22.5, 46, 47)
	-- bay A: coffin on a shelf
	local b = B.cf(-24.4, F, 37.5, "+z")
	local _, bh = bier(BV, b, 5)
	coffin(BV, b * CFrame.new(0, bh, 0), 4.6, C.WoodDark)
	B.L(V(-15, F + 3.3, 49.4))
	-- bay B: curtained alcove (hiding)
	curtainAlcove(BV, "AlcoveCurtain", -26, -22.5, 41.5, 46, -22.5, 1)
	-- bay C: chest
	local tr = B.trunk(BV, B.cf(-24.4, F, 48.5, "+x"), oakD, "Basement", 3, { w = 2.6, d = 1.8 })
	tr.Name = "VaultChest"
	B.S(tr:FindFirstChild("Lid"), "Trunk")
	-- effigy tomb (prize)
	do
		local t = B.model(BV, "EffigyTomb")
		B.box(t, "Chest", -15.5, F, 40.6, -9.5, F + 3, 44.4, stone, M.Limestone, { solid = true })
		B.box(t, "Slab", -15.8, F + 3, 40.3, -9.2, F + 3.4, 44.7, stone:Lerp(C.Paper, 0.15), M.Marble, { solid = true })
		B.box(t, "EffigyBody", -14.6, F + 3.4, 41.6, -10.6, F + 4.2, 43.4, stone:Lerp(C.Paper, 0.25), M.Marble, SM)
		B.box(t, "EffigyPillow", -15.4, F + 3.4, 41.8, -14.6, F + 4.0, 43.2, stone:Lerp(C.Paper, 0.25), M.Marble, SM)
		B.ball(t, "EffigyHead", CFrame.new(-14.9, F + 4.25, 42.5), 0.9, V(0, 0, 0), stone:Lerp(C.Paper, 0.25), M.Marble, SM)
		for _, x in { -14, -11.5 } do
			B.box(t, "Panel", x - 0.6, F + 0.6, 40.55, x + 0.6, F + 2.4, 40.6, stone:Lerp(C.Ink, 0.2), M.Limestone, SM)
		end
		B.PZ(V(-10.0, F + 3.4, 43.9))
		crypt_candle(t, V(-15.4, F + 3.4, 40.7), 0.8)
		B.candleDecor(t, V(-9.6, F + 3.4, 40.7), 1.0)
	end
	-- chest against the north wall + urn niche
	local tr2 = B.trunk(BV, B.cf(-7, F, 48.9, "-z"), C.WoodDark, "Basement", 3, { w = 3.0, d = 1.6 })
	tr2.Name = "OldChest"
	B.S(tr2:FindFirstChild("Lid"), "Trunk")
	B.L(V(-7, F + 2.15, 48.9))
	B.box(BV, "UrnShelf", -18, F + 3, 48.8, -12, F + 3.3, 50, stone, M.Limestone, { solid = true })
	local urn = B.vase(BV, CFrame.new(-16.5, F + 3.3, 49.4), stone:Lerp(C.Mustard, 0.2), 0.9)
	urn.Name = "Urn"
	B.L(V(-13.5, F + 3.3, 49.4))
	B.cobweb(BV, V(-25.3, 0.2, 49.3), 135, 1.2)
	B.N(-12.5, F, 37.5)
	B.N(-18, F, 46.5)
end

----------------------------------------------------------------- founders' vault (east)
do
	local FV = B.model(BA, "FoundersVault")
	pier(FV, 22.5, 26, 40.5, 41.5)
	pier(FV, 22.5, 26, 46, 47)
	curtainAlcove(FV, "AlcoveCurtain", 22.5, 26, 41.5, 46, 22.5, -1)
	-- founders' tomb (prize)
	do
		local t = B.model(FV, "FoundersTomb")
		B.box(t, "Chest", 8, F, 40.6, 14, F + 3, 44.4, stone, M.Limestone, { solid = true })
		B.box(t, "Slab", 7.7, F + 3, 40.3, 14.3, F + 3.4, 44.7, stone:Lerp(C.Paper, 0.15), M.Marble, { solid = true })
		B.box(t, "Inscription", 9, F + 0.8, 40.55, 13, F + 2.2, 40.6, stone:Lerp(C.Ink, 0.3), M.Limestone, SM)
		B.PZ(V(11, F + 3.4, 42.5))
		crypt_candle(t, V(7.9, F + 3.4, 40.5), 0.9)
		B.candleDecor(t, V(14.1, F + 3.4, 44.5), 0.7)
		B.L(V(13.2, F + 3.4, 41.1))
	end
	-- reliquary cupboard (Cabinet) and old drawers (Drawer)
	local cm = B.model(FV, "ReliquaryCupboard")
	do
		local b = B.cf(20.8, F, 35.4, "+z")
		R(cm, "Body", b, V(3.6, 5.4, 1.8), V(0, 2.7, 0), oakD, M.Wood, { solid = true })
		R(cm, "Top", b, V(3.9, 0.25, 2.0), V(0, 5.52, -0.05), oak, M.Wood, SM)
		local d1 = R(cm, "Cabinet", b, V(1.65, 4.6, 0.12), V(-0.86, 2.7, -0.96), oak, M.Wood, { collide = false })
		R(cm, "CabDoor", b, V(1.65, 4.6, 0.12), V(0.86, 2.7, -0.96), oak, M.Wood, { collide = false })
		B.S(d1, "Cabinet")
		B.L(V(20.8, F + 5.65, 35.4))
	end
	local dr, dh = B.dresser(FV, B.cf(24.9, F, 37.8, "-x"), 3.4, 1.8, 3.2, oakD, 3, "Basement", 3, { search = { 2 }, name = "OldDrawers" })
	for _, p in dr:GetChildren() do
		if p.Name == "Drawer" then B.S(p, "Drawer") end
	end
	B.L(V(24.9, F + dh, 37.3))
	-- chests along the north wall with an urn shelf between
	for _, x in { 5, 17.5 } do
		local tr = B.trunk(FV, B.cf(x, F, 48.9, "-z"), oakD, "Basement", 3, { w = 3.0, d = 1.6 })
		tr.Name = "FoundersChest"
		B.S(tr:FindFirstChild("Lid"), "Trunk")
	end
	B.L(V(17.5, F + 2.15, 48.9))
	B.box(FV, "UrnShelf", 8.5, F + 3, 48.8, 14.5, F + 3.3, 50, stone, M.Limestone, { solid = true })
	B.box(FV, "UrnShelf", 8.5, F + 6, 48.8, 14.5, F + 6.3, 50, stone, M.Limestone, { solid = true })
	for i, x in { 9.5, 11.5, 13.5 } do
		B.jar(FV, V(x, F + 6.3, 49.4), stone:Lerp(C.Mustard, 0.1 * i), 1.4)
	end
	B.L(V(11.5, F + 3.3, 49.4))
	B.cobweb(FV, V(25.3, 0.2, 49.3), 225, 1.2)
	B.N(6, F, 37.5)
	B.N(18.5, F, 44)
end
return "crypt ok, parts=" .. B.count(B.root())
