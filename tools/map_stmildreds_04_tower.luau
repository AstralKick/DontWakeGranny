-- St. Mildred's 04: UPSTAIRS = THE BELL TOWER (night 2): locked tower door (Barrier), tower stairs, ringing chamber,
-- belfry with bells + hand-bell table, choir loft with organ, robe closet.
local B = _G.SMB
local C, M = B.C, B.M
local V = Vector3.new
local SM = B.SM
local UP = B.F("Upstairs")
local IA = B.F("Interactables")
local U, BF = 13, 22
local oak = C.Oak
local oakD = C.Oak:Lerp(C.Ink, 0.3)
local function R(m, n, b, sz, off, col, mat, o) return B.rp(m, n, b, sz, off, col, mat, o) end

----------------------------------------------------------------- barrier: locked tower door in the oak screen at the stair foot
do
	local m = B.model(B.F("Barriers"), "Barrier_Upstairs")
	B.box(m, "LockedDoor", -23.48, 2.05, 14.85, -19.02, 9.95, 15.15, oakD, M.WoodPlanks, { collide = true, query = true })
	for _, z in { 14.8, 15.2 } do
		for _, y in { 3.6, 8.2 } do
			B.box(m, "Strap", -23.3, y - 0.15, z - 0.03, -19.2, y + 0.15, z + 0.03, C.Iron, M.Metal, SM)
		end
	end
	B.box(m, "Hasp", -19.9, 5.6, 14.6, -19.5, 6.6, 14.85, C.Iron, M.Metal, SM)
	B.box(m, "Padlock", -20.05, 5.0, 14.48, -19.35, 5.8, 14.78, C.Brass, M.Metal, SM)
	B.box(m, "Chain", -23.2, 5.95, 14.71, -19.6, 6.15, 14.81, C.Metal, M.Metal, SM)
	B.box(m, "Sign", -22.6, 6.8, 14.72, -20.4, 7.9, 14.8, C.Paper, M.SmoothPlastic, SM)
	B.box(m, "SignText", -22.3, 7.2, 14.68, -20.7, 7.45, 14.72, C.Blood, M.SmoothPlastic, SM)
	B.box(m, "Collider", -23.85, 2, 14.4, -18.65, 10.35, 15.6, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	m.PrimaryPart = m:FindFirstChild("LockedDoor")
	B.attrs(m, { Area = "Upstairs" })
end

----------------------------------------------------------------- tower stairs
do
	local T = B.model(UP, "TowerStairsDressing")
	B.LP(T, "sconce", B.cf(-24.95, 12.5, 4, "+x"), { shade = C.Wax, range = 16, bright = 0.8 })
	-- handrail on the east wall, following the slope
	local a, b = V(-17.75, 2 + 3.2, 14.5), V(-17.75, U + 3.2, -4.5)
	B.part(T, "Handrail", V(0.25, 0.25, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), oakD, M.Wood, SM)
	B.box(T, "Crate", -25, U, -6.8, -24.05, U + 1.2, -5.3, C.WoodRaw, M.WoodPlanks, { solid = true })
	B.L(V(-24.5, U + 1.2, -6.05))
	B.N(-21, U, -6)
	B.cobweb(T, V(-24.3, 22, -6.3), 45, 0.9)
end
B.door2(IA, "BellTowerDoor", "x", -7.75, -21.25, U, true, false, oak, 1, { ch = 7.5 })


----------------------------------------------------------------- ringing chamber (x -41.5..-17.5; belfry stairs along the south wall)
do
	local RC = B.model(UP, "RingingChamber")
	-- bell ropes with striped sallies (hang from the bells above)
	for _, p in { { -24, -12.4 }, { -29.5, -14.4 }, { -35, -12.9 } } do
		B.cyl(RC, "Rope", CFrame.new(p[1], U, p[2]), 0.14, 21 - (U + 3.2), V(0, 3.2 + (21 - U - 3.2) / 2, 0), C.Paper:Lerp(C.WoodRaw, 0.5), M.Fabric, SM)
		B.cyl(RC, "Sally", CFrame.new(p[1], U, p[2]), 0.4, 1.8, V(0, 5.6, 0), C.Blood:Lerp(C.Paper, 0.2), M.Fabric, SM)
		B.cyl(RC, "SallyBand", CFrame.new(p[1], U, p[2]), 0.42, 0.3, V(0, 5.6, 0), C.Glass:Lerp(C.Paper, 0.3), M.Fabric, SM)
		B.cyl(RC, "Tail", CFrame.new(p[1], U, p[2]), 0.14, 3.2, V(0, 1.6, 0), C.Paper:Lerp(C.WoodRaw, 0.5), M.Fabric, SM)
		B.cyl(RC, "Boss", CFrame.new(p[1], 21, p[2]), 0.8, 0.12, V(0, -0.06, 0), oakD, M.Wood, SM)
	end
	B.wardrobe(RC, B.cf(-30.5, U, -10.4, "-z"), oakD, B.A(V(-30.5, U + 1, -14.5)), "Closet", { name = "RopeCupboard", w = 4.4, h = 7.4 })
	B.L(V(-30.5, U + 7.6, -10.5))
	local tr = B.trunk(RC, B.cf(-40.4, U, -12.5, "+x"), oakD, "Upstairs", 2, { w = 3.0, d = 1.8 })
	tr.Name = "RopeChest"
	B.S(tr:FindFirstChild("Lid"), "Trunk")
	B.L(V(-40.4, U + 2.15, -11.9))
	B.box(RC, "PealBoard", -17.65, 16, -11, -17.5, 19, -9, oakD, M.Wood, SM)
	B.LP(RC, "bare", CFrame.new(-30, 21, -13.5), { drop = 1.5, range = 24, bright = 0.9 })
	B.creak(-33.5, U, -15.3)
	B.creak(-26, U, -11.2)
	B.N(-26, U, -14.5)
end
-- sloped railing on the open side of the belfry stairs (starts after the flat approach), and railings round the
-- stair hole (x -35..-24.5, z -23.5..-17.5) at belfry level
B.rail(UP, V(-22.6, U + 1.0, -17.75), V(-34.1, BF, -17.75), 3.2, oakD, 1.4)
B.rail(UP, V(-34.6, BF, -17.35), V(-22.4, BF, -17.35), 3.2, oakD, 1.4)
B.rail(UP, V(-21.85, BF, -17.8), V(-21.85, BF, -23.2), 3.2, oakD, 1.4)

----------------------------------------------------------------- belfry
do
	local BL = B.model(UP, "Belfry")
	local bronze = Color3.fromRGB(122, 96, 58)
	-- oak bell frame high up (Grandma walks underneath)
	for _, z in { -10.2, -15.8 } do
		B.box(BL, "FrameBeam", -41.5, 32.2, z - 0.5, -17.5, 33.2, z + 0.5, oakD, M.Wood, SM)
	end
	for _, x in { -38, -32.25, -26.75, -21 } do
		B.box(BL, "FrameCross", x - 0.45, 32.3, -15.3, x + 0.45, 33.1, -10.7, oakD, M.Wood, SM)
	end
	for i, x in { -35, -29.5, -24 } do
		local s = 1 - (i - 1) * 0.12
		local b = CFrame.new(x, 0, -13)
		B.box(BL, "Headstock", x - 0.5, 31.1, -15.3, x + 0.5, 32.2, -10.7, oakD, M.Wood, SM)
		B.cyl(BL, "Crown", b, 1.4 * s, 0.6, V(0, 30.8, 0), bronze, M.Metal, SM)
		B.cyl(BL, "Waist", b, 2.3 * s, 1.8 * s, V(0, 30.5 - 0.9 * s, 0), bronze, M.Metal, SM)
		B.cyl(BL, "Lip", b, 3.2 * s, 0.9 * s, V(0, 30.5 - 1.8 * s - 0.45 * s, 0), bronze:Lerp(C.Ink, 0.15), M.Metal, SM)
		B.ball(BL, "Clapper", b, 0.5, V(0, 30.5 - 2.4 * s, 0), C.Iron, M.Metal, SM)
		B.cyl(BL, "Wheel", CFrame.new(x + 1.9 * s, 0, -13), 3.4 * s, 0.15, V(0, 31, 0), oakD, M.Wood, SM, false)
	end
	-- hand-bell table (Breakables) with the prize
	local tb, th = B.table(BL, B.cf(-38.8, BF, -10.3, "-z"), 3.6, 1.8, 3.1, oak, { cloth = C.Velvet })
	tb.Name = "HandBellTable"
	for _, x in { -39.9, -38.9 } do
		local hb = B.model(BL, "HandBell")
		local b = CFrame.new(x, BF + th, -10.5)
		local body = B.cyl(hb, "Bell", b, 0.7, 0.6, V(0, 0.3, 0), bronze:Lerp(C.Brass, 0.5), M.Metal, { collide = true, touch = true, query = true, shadow = false })
		B.cyl(hb, "Handle", b, 0.18, 0.7, V(0, 0.95, 0), oakD, M.Wood, SM)
		hb.PrimaryPart = body
		B.tag(hb, "Breakable")
	end
	B.PZ(V(-37.6, BF + th, -10.4))
	local tbx = B.trunk(BL, B.cf(-20, BF, -9.6, "-z"), C.WoodRaw:Lerp(C.Ink, 0.3), "Upstairs", 3, { w = 3.0, d = 1.6 })
	tbx.Name = "ToolBox"
	B.S(tbx:FindFirstChild("Lid"), "Trunk")
	B.L(V(-20, BF + 2.15, -9.6))
	B.L(V(-40.2, BF, -22.4))
	B.LP(BL, "porch", B.cf(-22, 27, -8.55, "-z"), { range = 22, bright = 1, color = Color3.fromRGB(255, 190, 130) })
	B.creak(-31.5, BF, -10.6)
	B.creak(-19.55, BF, -20.5)
	B.N(-27.5, BF, -12.8)
	B.N(-38.5, BF, -20.5)
	B.cobweb(BL, V(-41, 33, -9), 135, 1.2)
	B.cobweb(BL, V(-18, 33, -23), -45, 1.1)
end

----------------------------------------------------------------- choir loft
B.door2(IA, "LoftDoor", "z", -16.75, -14, U, true, false, oak, 1, { ch = 7.5 })
B.rail(UP, V(-15.7, U, -10.4), V(15.7, U, -10.4), 3.4, oakD, 1.2)
do
	local CL = B.model(UP, "ChoirLoft")
	local tin = Color3.fromRGB(150, 150, 156)
	-- organ case, pipes, console
	B.box(CL, "OrganCase", -12, U, -22, -4, U + 6, -19.6, oakD, M.Wood, { solid = true })
	B.box(CL, "OrganCornice", -12.2, U + 6, -22, -3.8, U + 6.5, -19.4, oak, M.Wood, SM)
	for i = 0, 8 do
		local x = -11.4 + i * 0.85
		local h = 3.6 + (4 - math.abs(i - 4)) * 0.9
		B.cyl(CL, "Pipe", CFrame.new(x, U + 6.5, -20.6), 0.62, h, V(0, h / 2, 0), tin, M.Metal, SM)
		B.cyl(CL, "PipeMouth", CFrame.new(x, U + 6.5, -20.6), 0.64, 0.3, V(0, 0.6, 0), C.Ink, M.Metal, SM)
	end
	B.box(CL, "Console", -10.6, U, -19.6, -5.4, U + 2.9, -18.4, oak, M.Wood, { solid = true })
	B.box(CL, "Keys", -10.2, U + 2.9, -19.4, -5.8, U + 3.05, -18.7, C.Paper, M.SmoothPlastic, SM)
	B.box(CL, "MusicDesk", -9.6, U + 3.05, -19.6, -6.4, U + 4.4, -19.45, oakD, M.Wood, SM)
	B.box(CL, "OrganBench", -9.8, U + 1.7, -17.9, -6.2, U + 1.95, -16.8, oak, M.Wood, { solid = true })
	B.box(CL, "BenchLeg", -9.6, U, -17.8, -9.3, U + 1.7, -16.9, oakD, M.Wood, SM)
	B.box(CL, "BenchLeg", -6.7, U, -17.8, -6.4, U + 1.7, -16.9, oakD, M.Wood, SM)
	B.PZ(V(-8, U + 3.05, -18.9))
	B.candleLamp(CL, V(-10.1, U + 3.05, -18.8), 0.8)
	B.candleLamp(CL, V(-5.9, U + 3.05, -18.8), 0.8)
	-- organ cabinet (hiding) next to the case
	B.wardrobe(CL, B.cf(-14.1, U, -20.1, "+z"), oakD, B.A(V(-14.1, U + 1, -16)), "Cabinet", { name = "OrganCabinet", w = 3.4, h = 6.2 })
	B.L(V(-14.1, U + 6.8, -20.2))
	-- choir robe closet
	B.wardrobe(CL, B.cf(8.6, U, -20.1, "+z"), oakD, B.A(V(8.6, U + 1, -16)), "Closet", { name = "ChoirRobeCloset" })
	B.L(V(8.6, U + 9.0, -20.2))
	-- music drawers
	local dr, dh = B.dresser(CL, B.cf(13.7, U, -21.1, "+z"), 3.6, 1.8, 3.2, oak, 3, "Upstairs", 2, { search = { 1, 2 }, name = "MusicDrawers" })
	for _, p in dr:GetChildren() do
		if p.Name == "Drawer" then B.S(p, "Drawer") end
	end
	B.L(V(13.2, U + dh, -21.1))
	-- choir benches facing the balustrade
	do -- one choir bench against the organ side, leaving a clear walkway along the balustrade
		local bm = B.model(CL, "ChoirBench")
		local b = B.cf(1, U, -17.3, "+z")
		R(bm, "Seat", b, V(7, 0.25, 1.3), V(0, 1.7, 0), oak, M.Wood, { solid = true })
		R(bm, "Back", b, V(7, 1.4, 0.2), V(0, 2.5, 0.6), oakD, M.Wood, SM)
		R(bm, "Leg", b, V(0.3, 1.58, 1.1), V(-3.1, 0.79, 0), oakD, M.Wood, { solid = true })
		R(bm, "Leg", b, V(0.3, 1.58, 1.1), V(3.1, 0.79, 0), oakD, M.Wood, { solid = true })
		R(bm, "Leg", b, V(0.3, 1.58, 1.1), V(0, 0.79, 0), oakD, M.Wood, { solid = true })
	end
	B.L(V(-0.5, U + 1.83, -17.3))
	B.L(V(3, U + 1.83, -17.3))
	-- music stand + hymn board
	B.cyl(CL, "StandPole", CFrame.new(5.2, U, -18.4), 0.15, 3.6, V(0, 1.8, 0), C.Iron, M.Metal, SM)
	B.box(CL, "StandDesk", 4.5, U + 3.6, -18.3, 5.9, U + 4.5, -18.1, C.Iron, M.Metal, SM)
	B.box(CL, "HymnBoard", 3.4, U + 4, -21.99, 5.0, U + 8, -21.72, oakD, M.Wood, SM)
	B.creak(-3, U, -14.8)
	B.creak(11.5, U, -13.4)
	B.creak(-12.5, U, -12.8)
	B.N(-2, U, -13.5)
	B.N(10, U, -12.2)
	B.cobweb(CL, V(15.2, 27, -21.3), -45, 1)
end
return "tower ok, parts=" .. B.count(B.root())
