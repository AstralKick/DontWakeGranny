-- NightmareHouse step 5 (Basement = THE ROOTS): the cellar is overgrown. Root arches make a tunnel of the basement hall,
-- roots burst through the cellar shelves, and the sealed crawlspace under the den is opened up as the ROOT WARREN:
-- a loop of root-tunnels round a huge knotted root mass, with a root-nook hiding spot. Guarded by NH_Basement.
local NH = _G.NH
local B, C, M, V3, OX = NH.B, NH.C, Enum.Material, Vector3.new, NH.OX
local H = NH.root()
if H:GetAttribute("NH_Basement") then return "basement already applied" end
H:SetAttribute("NH_Basement", true)
local out = {}
local SM = { small = true }
local BF = NH.fresh("Roots")
local FL, CE = -11, 1 -- basement floor top / ceiling underside
local r = NH.rng(303)
local function W(x, y, z) return V3(x + OX, y, z) end
local SOLID = { solid = true }

-- 1) fewer jars (performance) - roots have eaten most of the cellar's shelves
local jars = 0
for _, p in H.Basement.CanningCellar:GetChildren() do
	if (p.Name == "Jar" or p.Name == "Lid") and not (p.Position.X - OX > -41.5 and p.Position.X - OX < -34.5) then
		p:Destroy()
		jars += 1
	end
end
table.insert(out, "jars removed " .. jars)

-- arch of root across a room: legs at (xa,za) and (xb,zb) on the floor, apex height ya. Legs collide, crown is decor.
local function arch(xa, za, xb, zb, ya, d0, seed)
	local rr = NH.rng(seed)
	local pts = {}
	local N = 8
	for i = 0, N do
		local t = i / N
		local x = xa + (xb - xa) * t
		local z = za + (zb - za) * t
		local y = FL - 0.4 + (ya - FL + 0.4) * math.sin(t * math.pi) ^ 0.7
		table.insert(pts, W(x + rr:NextNumber(-0.4, 0.4), y, z + rr:NextNumber(-0.4, 0.4)))
	end
	for i = 1, N do
		local mid = math.abs((i - 0.5) / N - 0.5) * 2 -- 1 at the legs, 0 at the crown
		local d = d0 * (0.45 + 0.55 * mid)
		local leg = i == 1 or i == N
		NH.rootSeg(BF, "Root", pts[i], pts[i + 1], d, if leg then C.RootDark else C.Root, if leg then SOLID else SM)
	end
	-- a couple of thin tendrils hanging from the crown
	for k = 1, 2 do
		local a = pts[3 + k * 2]
		NH.rootChain(BF, { a, a + V3(rr:NextNumber(-0.6, 0.6), -1.8, rr:NextNumber(-0.6, 0.6)), a + V3(rr:NextNumber(-1, 1), -3.2, rr:NextNumber(-1, 1)) }, 0.4, 0.18, C.Root, SM)
	end
end

-- 2) basement hall becomes a root tunnel (legs hug the walls)
for i, z in { 3.5, 25.5, 27.2 } do arch(-12.2, z, 12.2, z + r:NextNumber(-1, 1), CE - 1.2, 2.4, 10 + i) end
-- furnace room / workshop / cellar: arches from wall to wall where nothing stands
arch(-12.4, -10.5, 21.5, -10.5, CE - 1.5, 2.6, 21)
arch(-44.2, -4, -14, -4.5, CE - 1.3, 2.2, 22)
arch(-40, 27, -14, 26, CE - 1.3, 2.2, 23)

-- roots crawling along walls and ceilings (decor) and bursting out of the cellar shelves
local function crawl(a, b, d, seed)
	local rr = NH.rng(seed)
	local pts = { a }
	for k = 1, 4 do
		table.insert(pts, a:Lerp(b, k / 5) + V3(rr:NextNumber(-0.5, 0.5), rr:NextNumber(-0.5, 0.5), rr:NextNumber(-0.5, 0.5)))
	end
	table.insert(pts, b)
	NH.rootChain(BF, pts, d, d * 0.4, C.Root, SM)
end
crawl(W(-44.3, CE - 0.6, 3), W(-44.3, FL + 2, 30), 1.4, 31)
crawl(W(-44.3, CE - 0.8, 30), W(-20, CE - 0.8, 34.2), 1.2, 32)
crawl(W(-44.3, -3, 10), W(-42, CE - 0.7, 20), 1.0, 33)
crawl(W(-12.4, CE - 0.7, -34), W(-12.4, CE - 0.7, -2), 1.1, 34)
crawl(W(-5, CE - 0.7, -34.2), W(20, CE - 0.7, -34.2), 1.3, 35)
crawl(W(-44.3, CE - 0.7, -34), W(-44.3, FL + 1, -26), 1.3, 36)
crawl(W(0, CE - 0.7, 1), W(0, CE - 0.7, 34), 1.0, 37)
crawl(W(12.4, CE - 0.8, 16), W(12.4, FL + 1.5, 22), 0.9, 38)

-- 3) THE ROOT WARREN (the sealed crawlspace x 23..45, z -15..35)
local cN, dN = NH.cut(22.5, FL, 28.8, 23.6, FL + 8, 34)
table.insert(out, ("warren doorway cut %d/%d"):format(cN, dN))
-- casing for the new opening + dirt floor + a chill in the air
B.casing(BF, "z", 23, 31.4, 5.2, FL, 8, 0.5)
NH.box(BF, "Dirt", 23.45, FL, -14.7, 44.95, FL + 0.08, 34.45, C.Dirt:Lerp(C.Tint, 0.3), M.Ground, { solid = true, shadow = false })
-- central knot: a ring of huge trunks with packed roots between (the loop goes round it)
local KX, KZ = 34, 10
for i = 0, 9 do
	local a = i / 10 * math.pi * 2
	local rx, rz = 4.5 * math.cos(a), 9 * math.sin(a)
	local base = W(KX + rx, FL - 0.3, KZ + rz)
	local top = W(KX + rx * 0.6 + r:NextNumber(-0.8, 0.8), CE + 0.2, KZ + rz * 0.7 + r:NextNumber(-0.8, 0.8))
	local mid = base:Lerp(top, 0.5) + V3(r:NextNumber(-1.2, 1.2), 0, r:NextNumber(-1.2, 1.2))
	NH.rootSeg(BF, "Trunk", base, mid, 3.2, C.RootDark, SOLID)
	NH.rootSeg(BF, "Trunk", mid, top, 2.4, C.Root, SOLID)
end
NH.box(BF, "KnotCore", KX - 3.5, FL, KZ - 7.5, KX + 3.5, CE, KZ + 7.5, C.RootDark, M.Wood, SOLID)
-- the loop is 7 wide between the knot (x 29.5..38.5, z 1..19) and the walls; root arches span it like ribs
for i, z in { -8, -2 } do arch(23.8, z, 44.2, z + r:NextNumber(-0.6, 0.6), CE - 1, 2.4, 50 + i) end
-- half-arches: from the wall up and over onto the knot (only the foot at the wall is solid, so the loop stays 4.5+ wide)
local function halfArch(xa, z, xb, yb, d0, seed)
	local rr = NH.rng(seed)
	local pts = {}
	for i = 0, 5 do
		local t = i / 5
		table.insert(pts, W(xa + (xb - xa) * t, FL - 0.4 + (yb - FL + 0.4) * math.sin(t * math.pi / 2) ^ 0.6, z + rr:NextNumber(-0.4, 0.4)))
	end
	for i = 1, 5 do
		NH.rootSeg(BF, "Root", pts[i], pts[i + 1], d0 * (1 - 0.1 * i), if i == 1 then C.RootDark else C.Root, SM) -- decor only: the loop must stay >= 4.5 wide for Grandma
	end
end
for i, z in { 4, 10, 16 } do
	halfArch(23.8, z, KX - 3, CE - 1.5, 1.8, 60 + i)
	halfArch(44.2, z, KX + 3, CE - 1.5, 1.8, 70 + i)
end
-- roots hanging in the north end
for i = 1, 6 do
	local a = W(r:NextNumber(26, 38), CE - 0.2, r:NextNumber(21.5, 33))
	NH.rootChain(BF, { a, a + V3(r:NextNumber(-0.6, 0.6), -2.2, r:NextNumber(-0.6, 0.6)), a + V3(r:NextNumber(-1, 1), -4, r:NextNumber(-1, 1)) }, 0.6, 0.25, C.Root, SM)
end
-- knuckles of root on the floor to put loot on; glowing fungus (decor)
local knuckles = { { 25.2, -12.5 }, { 43.4, -12 }, { 24.4, -6 }, { 44.1, 21.2 }, { 36, -12.8 } }
for i, k in knuckles do
	local p = W(k[1], FL + 0.5, k[2])
	NH.rootSeg(BF, "Knuckle", p - V3(0.9, 0, 0.3), p + V3(0.9, 0, 0.3), 1.4, C.RootDark, SOLID)
	NH.loot("Basement", 3, p + V3(0, 0.7, 0))
end
local trunks = {}
for _, p in BF:GetChildren() do if p.Name == "Trunk" or p.Name == "Root" then table.insert(trunks, p) end end
for i = 1, 26 do
	-- fungus grows ON the roots: a point on the cylinder surface (axis = local X)
	local t = trunks[r:NextInteger(1, #trunks)]
	local a = r:NextNumber(0, math.pi * 2)
	local rad = t.Size.Y / 2
	local p = (t.CFrame * CFrame.new(r:NextNumber(-0.35, 0.35) * t.Size.X, math.cos(a) * rad, math.sin(a) * rad)).Position
	B.part(BF, "Fungus", V3(0.4, 0.4, 0.4), CFrame.new(p), if i % 3 == 0 then C.Sick else C.Purple:Lerp(C.Sick, 0.3), M.Neon, { small = true, shape = Enum.PartType.Ball, tr = 0.2 })
end
-- a dim bulb somebody strung up long ago
NH.lamp(BF, "bare", NH.CF(28, CE, -6), "Basement", false, { drop = 3, bright = 0.7, range = 18 })

-- ROOT NOOK hiding spot (east wall, z 24..28): trunks on three sides, a curtain of hanging roots in front
local nook = B.model(BF, "RootNook")
local NZ0, NZ1, NX0, NX1 = 23.2, 28.8, 40.2, 44.9
for _, z in { NZ0, NZ1 } do
	for x = NX0, NX1 - 0.5, 1.4 do
		NH.rootSeg(nook, "Trunk", W(x, FL - 0.2, z), W(x + r:NextNumber(-0.3, 0.3), CE + 0.1, z + r:NextNumber(-0.3, 0.3)), 1.6, C.RootDark, SOLID)
	end
end
NH.box(nook, "Canopy", NX0 - 0.4, FL + 7, NZ0 - 0.6, NX1, CE, NZ1 + 0.6, C.RootDark, M.Wood, SOLID)
for z = NZ0 + 0.5, NZ1 - 0.5, 0.45 do
	local a = W(NX0 - 0.2 + r:NextNumber(-0.15, 0.15), FL + 7, z)
	NH.rootChain(nook, { a, a + V3(r:NextNumber(-0.2, 0.2), -3.4, 0), a + V3(r:NextNumber(-0.3, 0.3), -6.7, r:NextNumber(-0.1, 0.1)) }, 0.5, 0.3, C.Root, SM)
end
B.hideParts(nook, "Closet", "Basement", CFrame.lookAt(W(42.8, FL + 3.1, 26), W(38, FL + 3.1, 26)), W(38.2, FL, 26), W(38.6, FL, 26))

-- contract: room, nodes, pumpkin at the far end of the loop
NH.room("RootWarren", "The Root Warren", "Basement", 3, 23, FL, -15, 45, CE, 35)
NH.node("Basement", W(26.5, FL, 30))
NH.node("Basement", W(26.5, FL, 0))
NH.node("Basement", W(41.5, FL, 5))
NH.node("Basement", W(34, FL, -11))
NH.pumpkin("Basement", W(34, FL, -8.5), "+z")
NH.rootSeg(BF, "Knuckle", W(37.6, FL + 0.5, -13.9), W(39.4, FL + 0.5, -13.3), 1.4, C.RootDark, SOLID)
NH.prize("Basement", W(38.5, FL + 1.2, -13.6))
-- fungus a little bigger, and glowing sap along the big knot trunks (so the roots read under red/purple light)
for _, f in BF:GetChildren() do
	if f.Name == "Fungus" then
		f.Size = V3(0.65, 0.65, 0.65)
		f.Transparency = 0.05
	end
end
do
	local rs = NH.rng(515)
	local m = 0
	for _, t in BF:GetChildren() do
		if t.Name == "Trunk" and t.Size.Y >= 2.3 and m < 14 then
			local ax = t.CFrame.RightVector
			local rad = t.Size.Y / 2
			local a = rs:NextNumber(0, math.pi * 2)
			local off = t.CFrame.UpVector * math.cos(a) * (rad + 0.02) + t.CFrame.LookVector * math.sin(a) * (rad + 0.02)
			local p0 = t.Position - ax * t.Size.X * 0.35 + off
			local p1 = t.Position + ax * t.Size.X * 0.35 + off
			local s = NH.seg(BF, "Sap", p0, p1, 0.18, 0.1, C.VeinHot, M.Neon, { small = true, tr = 0.1 })
			local n0 = off.Unit
			local along = (p1 - p0).Unit
			s.CFrame = CFrame.fromMatrix((p0 + p1) / 2, along:Cross(n0).Unit, n0, -along)
			s.Size = V3(0.18, 0.08, (p1 - p0).Magnitude)
			m += 1
		end
	end
end
-- veins in the old basement rooms (roots glow where they break the plaster)
local VF = NH.F("Veins", NH.F("Nightmare"))
local nv = 0
for i, v in { { { -13, FL, 0, 13, CE, 35 }, V3(0, -5, 18), V3(0, 0, 1) }, { { -45, FL, 0, -13, CE, 35 }, V3(-30, -5, 18), V3(0, 0, 1) }, { { -45, FL, -35, -13, CE, 0 }, V3(-30, -4, -18), V3(0, 0, -1) }, { { -13, FL, -35, 23, CE, 0 }, V3(5, -4, -15), V3(1, 0, 0) }, { { 23, FL, -35, 45, CE, -15 }, V3(34, -4, -25), V3(1, 0, 0) } } do
	nv += NH.wallVein(VF, v[1], v[2], v[3], 12, 300 + i, 2)
end
table.insert(out, "basement veins " .. nv)
table.insert(out, "parts now " .. NH.count())
return table.concat(out, "\n")
