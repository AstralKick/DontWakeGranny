-- NightmareHouse step 4 (Upstairs = THE WRONG STAIRS): the upstairs hallway now continues out through the west wall
-- into a crooked corridor (shell rolled 6 deg, floor flat) and a tall skewed room around a staircase that climbs out of a
-- pit in the floor and vanishes into the ceiling directly above where it began. Guarded by NH_Upstairs.
local NH = _G.NH
local B, C, M, V3, OX = NH.B, NH.C, Enum.Material, Vector3.new, NH.OX
local H = NH.root()
if H:GetAttribute("NH_Upstairs") then return "upstairs already applied" end
H:SetAttribute("NH_Upstairs", true)
local out = {}
local SM = { small = true }
local UF = NH.fresh("WrongStairs")
local wallCol = Color3.fromRGB(125, 89, 65)
local ceilCol = Color3.fromRGB(140, 118, 116)
local floorCol = H.Structure:FindFirstChild("UpstairsFloor").Color
local siding = H.Exterior:FindFirstChild("Facade_left").Color
local FY = 15 -- upstairs floor top

-- clear anything outside the west facade in the annex footprint (nothing but air should be there)
local cleared = 0
for _, p in (NH.partsIn(-96, 0.05, -20, -46.2, 45, 14)) do
	if p.Parent and p:IsDescendantOf(H.Exterior) and p.Name ~= "Grass" and not string.find(p.Name, "Facade") and not p:FindFirstAncestor("Boundary") and not p:FindFirstAncestor("Fence") and not p:FindFirstAncestor("Roof") then
		p:Destroy()
		cleared += 1
	end
end
local cN, dN = NH.cut(-46.3, FY, -6.75, -44.9, 27, 0.75)
table.insert(out, ("west cut %d/%d, cleared %d"):format(cN, dN, cleared))

------------------------------------------------------------------ corridor (x -46 .. -66), shell rolled 6 deg
local CX0, CX1 = -66, -46
NH.box(UF, "CorridorFloor", CX0 - 1, FY - 1, -9.5, CX1 + 0.1, FY, 3.5, floorCol, M.WoodPlanks, { solid = true })
NH.box(UF, "CorridorUnder", CX0 - 1, FY - 1.4, -9.5, CX1 + 0.1, FY - 1, 3.5, C.WoodRaw:Lerp(C.Tint, 0.4), M.WoodPlanks, SM)
NH.box(UF, "Threshold", -46.4, FY - 0.4, -6.75, -44.9, FY + 0.03, 0.75, C.WoodDark, M.Wood, { solid = true })
local shell = B.model(UF, "CorridorShell")
for _, s in { { -7.75, -7, -6.75, 1, "+z" }, { 1.75, 1, 0.75, -1, "-z" } } do
	NH.box(shell, "Siding", CX0 + 0.5, FY - 0.5, math.min(s[1], s[2]), CX1 - 0.5, FY + 12.3, math.max(s[1], s[2]), siding, M.WoodPlanks, { solid = true })
	NH.box(shell, "Wall", CX0 + 0.5, FY - 0.5, math.min(s[2], s[3]), CX1 - 0.5, FY + 12, math.max(s[2], s[3]), wallCol, M.Plaster, { solid = true })
	NH.box(shell, "Rail", CX0 + 0.5, FY + 3.6, s[3], CX1 - 0.5, FY + 3.9, s[3] + s[4] * 0.2, C.WoodDark, M.Wood, SM)
	for i, x in { -51.5, -60.5 } do
		NH.fakeDoor(shell, NH.CF(x, FY, s[3], s[5]), if (i + s[4]) % 3 == 0 then "ajar" else "closed")
	end
	local pic = B.picture(shell, NH.CF(-56, FY + 7, s[3], s[5]), 2, 2.6, { portrait = true, clothes = C.Velvet, eyes = C.Red, canvas = C.Tint })
	if pic:FindFirstChild("Head") then pic.Head.Color = Color3.fromRGB(40, 30, 34) end
end
NH.box(shell, "Ceiling", CX0 + 0.5, FY + 12, -8, CX1 - 0.5, FY + 12.3, 2, ceilCol, M.Plaster, { solid = true })
NH.box(shell, "Roof", CX0 + 0.5, FY + 12.3, -9, CX1 - 0.5, FY + 13.2, 3, B.C.Roof, M.Slate, { solid = true })
local piv = CFrame.new(NH.V(0, FY, -3))
local R = piv * CFrame.Angles(math.rad(6), 0, 0) * piv:Inverse()
for _, p in shell:GetDescendants() do
	if p:IsA("BasePart") then p.CFrame = R * p.CFrame end
end
-- flat baseboards hide the sliver where the rolled walls meet the level floor
NH.box(UF, "Trim", CX0 + 0.5, FY, -6.75, CX1 - 0.5, FY + 1.1, -6.2, C.WoodDark, M.Wood, SM)
NH.box(UF, "Trim", CX0 + 0.5, FY, 0.2, CX1 - 0.5, FY + 1.1, 0.75, C.WoodDark, M.Wood, SM)
-- heavy portal frames at both joints (they cover the mismatch between straight and rolled geometry)
local function portal(x0, x1)
	local col = C.WoodDark:Lerp(C.Velvet, 0.2)
	NH.box(UF, "Portal", x0, FY + 12, -9.6, x1, FY + 14.2, 3.6, col, M.Wood, { solid = true })
	NH.box(UF, "Portal", x0, FY - 0.9, -9.6, x1, FY + 12, -6.75, col, M.Wood, { solid = true })
	NH.box(UF, "Portal", x0, FY - 0.9, 0.75, x1, FY + 12, 3.6, col, M.Wood, { solid = true })
end
portal(-47.9, -46.3)
portal(CX0 - 1.2, CX0 + 0.6)
NH.room("WrongHall", "The Crooked Hall", "Upstairs", 3, -66, FY, -7, -45, FY + 12, 1)
NH.node("Upstairs", NH.V(-56, FY, -3))
NH.creak(NH.V(-54, FY, -3), 0)

------------------------------------------------------------------ the Wrong Stairs room (x -67 .. -93), skewed 7 deg
local RX0, RX1, RZ0, RZ1, RH = -93, -67, -16, 10, 22
local cx, cz = (RX0 + RX1) / 2, (RZ0 + RZ1) / 2
local room = B.model(UF, "RoomShell")
local T = 1
local function slab(x0, x1, z0, z1, y0, y1, col, mat, name) NH.box(room, name, x0, y0, z0, x1, y1, z1, col, mat, { solid = true }) end
-- east wall (with the corridor opening z -6.75..0.75, 12 tall)
for _, pc in B.pieces(RZ0 - T, RZ1 + T, FY - 0.5, FY + RH, { { c = -3, w = 7.5, h = 12.5 } }) do
	slab(RX1, RX1 + T, pc[1], pc[2], pc[3], pc[4], wallCol, M.Plaster, "Wall")
end
slab(RX0 - T, RX0, RZ0 - T, RZ1 + T, FY - 0.5, FY + RH, wallCol, M.Plaster, "Wall")
slab(RX0, RX1, RZ0 - T, RZ0, FY - 0.5, FY + RH, wallCol, M.Plaster, "Wall")
slab(RX0, RX1, RZ1, RZ1 + T, FY - 0.5, FY + RH, wallCol, M.Plaster, "Wall")
slab(RX0 - T, RX1 + T, RZ0 - T, RZ1 + T, FY + RH, FY + RH + 0.4, ceilCol, M.Plaster, "Ceiling")
slab(RX0 - T - 0.8, RX1 + T + 0.8, RZ0 - T - 0.8, RZ1 + T + 0.8, FY + RH + 0.4, FY + RH + 1.3, B.C.Roof, M.Slate, "Roof")
NH.box(room, "Rail", RX0, FY + 3.6, RZ0, RX1, FY + 3.9, RZ0 + 0.2, C.WoodDark, M.Wood, SM)
NH.box(room, "Rail", RX0, FY + 3.6, RZ1 - 0.2, RX1, FY + 3.9, RZ1, C.WoodDark, M.Wood, SM)
NH.box(room, "Rail", RX0, FY + 3.6, RZ0, RX0 + 0.2, FY + 3.9, RZ1, C.WoodDark, M.Wood, SM)
-- doors that go nowhere (several bricked); at a room this big the leaves never meet
NH.fakeDoor(room, NH.CF(RX0, FY, -9, "+x"), "brick")
NH.fakeDoor(room, NH.CF(RX0, FY, 3, "+x"), "closed")
NH.fakeDoor(room, NH.CF(-85, FY, RZ0, "+z"), "closed")
NH.fakeDoor(room, NH.CF(-75, FY, RZ0, "+z"), "brick")
NH.fakeDoor(room, NH.CF(-85, FY, RZ1, "-z"), "brick")
NH.fakeDoor(room, NH.CF(-75, FY, RZ1, "-z"), "ajar")
-- a door high up on the wall, where no floor is
NH.fakeDoor(room, NH.CF(RX0, FY + 11, -3, "+x"), "ajar")
-- skew the whole shell 5 deg about the doorway centre (floor stays level; the portal hides the joint)
local rp = CFrame.new(NH.V(RX1, FY, -3))
local RY = rp * CFrame.Angles(0, math.rad(5), 0) * rp:Inverse()
for _, p in room:GetDescendants() do
	if p:IsA("BasePart") then p.CFrame = RY * p.CFrame end
end
local bcf, bsz = room:GetBoundingBox()
local blo, bhi = bcf.Position - bsz / 2 - V3(OX, 0, 0), bcf.Position + bsz / 2 - V3(OX, 0, 0)
NH.box(UF, "RoomFloor", blo.X - 0.3, FY - 1, blo.Z - 0.3, CX0 - 1, FY, bhi.Z + 0.3, floorCol, M.WoodPlanks, { solid = true })
NH.box(UF, "RoomUnder", blo.X - 0.3, FY - 1.4, blo.Z - 0.3, CX0 - 1, FY - 1, bhi.Z + 0.3, C.WoodRaw:Lerp(C.Tint, 0.4), M.WoodPlanks, SM)

-- the staircase: square helix round a pillar, out of a pit in the floor and into the ceiling above it
local SX, SZ = cx, cz
local ST = B.model(UF, "LoopingStair")
NH.box(ST, "Pillar", SX - 2.5, FY, SZ - 2.5, SX + 2.5, FY + RH, SZ + 2.5, wallCol:Lerp(C.Tint, 0.3), M.Plaster, { solid = true })
NH.box(ST, "Pit", SX + 2.5, FY + 0.01, SZ - 6.5, SX + 6.5, FY + 0.05, SZ - 2.5, Color3.new(0, 0, 0), M.SmoothPlastic, SM)
NH.box(ST, "PitRim", SX + 2.4, FY, SZ - 6.6, SX + 6.6, FY + 0.12, SZ - 6.4, C.WoodDark, M.Wood, SM)
NH.box(ST, "CeilPit", SX + 2.5, FY + RH - 0.05, SZ - 6.5, SX + 6.5, FY + RH - 0.01, SZ - 2.5, Color3.new(0, 0, 0), M.SmoothPlastic, SM)
-- four flights round the pillar (+x, +z, -x, -z sides), each 6 steps between corner landings; after the 4th flight
-- the stair is back above the pit, at the ceiling
local sides = {
	{ o = V3(4.5, 0, 0), d = V3(0, 0, 1) }, { o = V3(0, 0, 4.5), d = V3(-1, 0, 0) },
	{ o = V3(-4.5, 0, 0), d = V3(0, 0, -1) }, { o = V3(0, 0, -4.5), d = V3(1, 0, 0) },
}
local run, h = 5 / 6, 0.4
local rise = (RH - 1.2) / 27 -- 24 steps + 3 landings, the 4th landing tucks under the ceiling pit
local stepCol = C.WoodMid:Lerp(C.Tint, 0.3)
local n = 0
local SC = V3(SX, 0, SZ)
local function stepTop(k) return FY + 0.2 + k * rise + h / 2 end
for f = 0, 3 do
	local s = sides[f + 1]
	for i = 0, 5 do
		local y = FY + 0.2 + n * rise
		local p = SC + s.o + s.d * (i * run - 2.5 + run / 2)
		local cf = CFrame.lookAt(V3(p.X + OX, y, p.Z), V3(p.X + OX, y, p.Z) + s.d)
		B.part(ST, "Step", V3(4, h, run + 0.02), cf, stepCol, M.Wood, { solid = true })
		B.part(ST, "Riser", V3(4, rise, 0.1), cf * CFrame.new(0, -rise / 2, run / 2), stepCol:Lerp(C.Ink, 0.3), M.Wood, SM)
		n += 1
	end
	-- soffit under the flight
	local a = SC + s.o + s.d * -2.5
	local b2 = SC + s.o + s.d * 2.5
	local ya, yb = stepTop(n - 6) - h - 0.5, stepTop(n - 1) - h - 0.5
	local sof = NH.seg(ST, "Soffit", V3(a.X + OX, ya, a.Z), V3(b2.X + OX, yb, b2.Z), 4, 0.3, stepCol:Lerp(C.Ink, 0.45), M.Wood, SM)
	sof.Size = V3(4, 0.3, sof.Size.Z)
	-- landing at the corner the flight arrives at (the last one sits right under the black ceiling pit)
	do
		local cpos = SC + s.o + s.d * 4.5
		local ly = FY + 0.2 + n * rise
		NH.box(ST, "Landing", cpos.X - 2, ly - h / 2, cpos.Z - 2, cpos.X + 2, ly + h / 2, cpos.Z + 2, stepCol, M.Wood, { solid = true })
		n += 1
	end
end
-- dolls climbing it
for i, k in { 3, 10, 17 } do
	local f = math.floor(k / 7)
	local s = sides[f + 1]
	local ii = k - f * 7
	local p = SC + s.o + s.d * (ii * run - 2.5 + run / 2)
	local y = stepTop(k)
	B.doll(ST, CFrame.lookAt(V3(p.X + OX, y, p.Z), V3(p.X + OX, y, p.Z) - s.d), 1.1 + i * 0.1, if i % 2 == 0 then C.Velvet else B.C.WPlum)
end
-- stilts & dangling roots under the floating annex (seen from the yard)
local r = NH.rng(44)
for _, xz in { { -50, -8 }, { -62, 2 }, { -70, -15 }, { -90, -15 }, { -92, 9 }, { -70, 9 }, { -80, -3 } } do
	local top = V3(xz[1] + OX, FY - 1.4, xz[2])
	local bot = top + V3(r:NextNumber(-3, 3), -(FY - 1.4), r:NextNumber(-3, 3))
	NH.seg(UF, "Stilt", bot, top, 0.8, 0.8, C.WoodDark:Lerp(C.Tint, 0.3), M.Wood, { solid = true })
end
for i = 1, 8 do
	local x = r:NextNumber(-92, -48)
	local z = r:NextNumber(-12, 8)
	if x > -66 then z = r:NextNumber(-8, 2) end
	local a = V3(x + OX, FY - 1.4, z)
	NH.rootChain(UF, { a, a + V3(r:NextNumber(-1, 1), -2.5, r:NextNumber(-1, 1)), a + V3(r:NextNumber(-2, 2), -5, r:NextNumber(-2, 2)) }, 0.7, 0.3, C.Root, SM)
end

------------------------------------------------------------------ contract bits
NH.room("WrongStairs", "The Wrong Stairs", "Upstairs", 3, blo.X + 0.5, FY, blo.Z + 0.5, CX0, FY + RH, bhi.Z - 0.5) -- east edge = corridor end: the skewed wall bulges to x -66
NH.node("Upstairs", NH.V(-72, FY, -12))
NH.node("Upstairs", NH.V(-88, FY, 6))
NH.pumpkin("Upstairs", NH.V(SX + 8, FY, SZ - 4.5), "-x") -- beside the pit where the stair begins
NH.lamp(UF, "bare", NH.CF(-73, FY + RH, 5), "Upstairs", true, { drop = 5, bright = 0.9, range = 22 })
-- two little tables with loot, and a trunk (Searchable)
for _, t in { { -90, -13 }, { -71, 7 } } do
	local b = NH.CF(t[1], FY, t[2], "+x")
	local m = B.model(UF, "SideTable")
	B.rp(m, "Top", b, V3(2.4, 0.2, 2.4), V3(0, 2.6, 0), C.WoodDark, M.Wood, { solid = true })
	B.rp(m, "Leg", b, V3(0.4, 2.5, 0.4), V3(0, 1.25, 0), C.WoodDark, M.Wood, SM)
	B.rp(m, "Foot", b, V3(1.6, 0.2, 1.6), V3(0, 0.1, 0), C.WoodDark, M.Wood, SM)
	NH.loot("Upstairs", 3, (b * CFrame.new(0, 2.7, 0)).Position)
end
B.trunk(UF, NH.CF(-90.5, FY, 2, "+x"), C.WoodMid:Lerp(C.Velvet, 0.3), "Upstairs", 3)
-- veins
local VF = NH.F("Veins", NH.F("Nightmare"))
local rb = { blo.X, FY, blo.Z, RX1, FY + RH, bhi.Z }
local nv = 0
for i, v in { { V3(-80, 20, -3), V3(-1, 0.1, 0.3) }, { V3(-80, 24, -3), V3(0.2, 0, -1) }, { V3(-80, 18, -3), V3(0.1, 0, 1) }, { V3(-86, 30, 4), V3(0, 1, 0) }, { V3(-73, 28, -10), V3(0, 1, 0) }, { V3(-85, 22, 0), V3(-1, 0, 0.5) } } do
	nv += NH.wallVein(VF, rb, v[1], v[2], 14, 40 + i, 2)
end
nv += NH.wallVein(VF, { -66, FY, -7, -46, FY + 12, 1 }, V3(-62, 22, -3), V3(0, 0, 1), 10, 51, 2)
table.insert(out, "wrong stairs veins " .. nv .. ", steps " .. n)
table.insert(out, "parts now " .. NH.count())
return table.concat(out, "\n")
