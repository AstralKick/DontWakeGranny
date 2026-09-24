-- NightmareHouse step 3 (Ground): throne armchair, giant cracked clock, upside-down dining room & den corner,
-- leaning furniture, and THE LONG HALL: the ground hallway now runs 48 studs past the east wall, lined with
-- repeating doors (some open onto brick). Run once per fresh clone (guarded by NH_Ground).
local NH = _G.NH
local B, C, M, V3, OX = NH.B, NH.C, Enum.Material, Vector3.new, NH.OX
local H = NH.root()
if H:GetAttribute("NH_Ground") then return "ground already applied" end
H:SetAttribute("NH_Ground", true)
local out = {}
local SM = { small = true }
local function up(cf) return cf * CFrame.Angles(0, math.rad(90), 0) end -- cylinder axis along the base's look axis

-------------------------------------------------------------------- A) the throne
local gc = H.GrandmaChair
for _, p in gc:GetDescendants() do
	if p:IsA("BasePart") then
		if p.Name == "Cushion" or p.Name == "Back" or p.Name == "Arm" or p.Name == "Wing" or p.Name == "Base" then
			p.Color = C.Velvet
			p.Material = M.Fabric
		elseif p.Name == "ArmRoll" or p.Name == "Skirt" or p.Name == "Foot" or p.Name == "Button" then
			p.Color = C.Gold
			p.Material = M.Metal
		elseif p.Name == "Flower" or p.Name == "Doily" or p.Name == "Throw" or p.Name == "BackTop" then
			p:Destroy()
		end
	end
end
local back = gc:FindFirstChild("Back")
back.Size = V3(6.4, 10.3, 1.1)
back.CFrame = CFrame.new(12 + OX, 3 + 5.15, -11.05)
for _, w in gc:GetChildren() do
	if w.Name == "Wing" then
		local x = w.Position.X
		w.Size = V3(0.7, 7.6, 1.8)
		w.CFrame = CFrame.new(x, 5.3 + 3.8, -11.8)
	end
end
local TB = CFrame.new(12 + OX, 2, -11.05) -- throne base (floor, back centre); LookVector -Z = where she faces
for i = 0, 3 do
	for j = 0, 2 do
		B.part(gc, "Button", V3(0.2, 0.2, 0.2), TB * CFrame.new(-1.8 + j * 1.8 + (i % 2) * 0.9, 7.6 + i * 1.3, -0.62), C.Gold, M.Metal, SM)
	end
end
for _, sx in { -1, 1 } do
	B.cyl(gc, "Pillar", TB, 0.9, 10.6, V3(sx * 3.35, 5.3, 0), C.WoodDark:Lerp(C.Velvet, 0.25), M.Wood, SM)
	B.ball(gc, "Finial", TB, 1.3, V3(sx * 3.35, 11.2, 0), C.Gold, M.Metal, SM)
	B.rp(gc, "Spike", TB, V3(0.8, 1.2, 0.5), V3(sx * 1.6, 11.4, 0), C.Gold, M.Metal, SM, CFrame.Angles(0, 0, math.rad(sx * -12)))
	B.rp(gc, "Claw", TB, V3(0.9, 0.4, 1.4), V3(sx * 2.4, 0.2, -4.4), C.Gold, M.Metal, SM)
end
B.rp(gc, "Crest", TB, V3(2.2, 1.6, 0.5), V3(0, 11.9, 0), C.Gold, M.Metal, SM)
B.ball(gc, "CrestJewel", TB, 0.6, V3(0, 12.1, -0.3), C.VeinHot, M.Neon, SM)
B.rp(gc, "Trim", TB, V3(6.6, 0.3, 1.3), V3(0, 13.25, 0), C.Gold, M.Metal, SM)
NH.box(NH.fresh("Throne"), "ThroneRug", 7, 2, -21, 17, 2.06, -9.2, C.Velvet:Lerp(C.Tint, 0.4), M.Fabric, SM)
-- side table + footstool shuffled out of the way of the pillars
local lr = H.Ground.LivingRoom
for _, c in lr:GetChildren() do
	if c.Name == "SideTable" or c.Name == "Lamp_table" or c.Name == "Teacup" then c:PivotTo(c:GetPivot() + V3(-1.2, 0, 0)) end
end
for _, l in H.LootSpawns:GetChildren() do
	local p = l.Position - V3(OX, 0, 0)
	if p.X > 6.5 and p.X < 9.5 and p.Z > -15 and p.Z < -12 and p.Y > 4 then l.Position += V3(-1.2, 0, 0) end
end
table.insert(out, "throne ok")

-------------------------------------------------------------------- B) giant cracked clock (living room west wall)
local CK = NH.fresh("GiantClock")
local cb = NH.CF(3.25, 8.2, -12.6, "+x")
local r = NH.rng(7)
B.part(CK, "Rim", V3(0.6, 10, 10), up(cb * CFrame.new(0, 0, -0.3)), C.WoodDark:Lerp(C.Gold, 0.25), M.Wood, { small = true, shape = Enum.PartType.Cylinder }).Shape = Enum.PartType.Cylinder
local face = B.part(CK, "Face", V3(0.1, 9, 9), up(cb * CFrame.new(0, 0, -0.64)), C.Cream:Lerp(C.Tint, 0.35), M.SmoothPlastic, SM)
face.Shape = Enum.PartType.Cylinder
for h = 1, 12 do
	local a = math.rad(h * 30)
	local big = h % 3 == 0
	B.part(CK, "Numeral", V3(if big then 0.45 else 0.25, if big then 1.1 else 0.7, 0.05), cb * CFrame.new(math.sin(a) * 3.7, math.cos(a) * 3.7, -0.72) * CFrame.Angles(0, 0, -a), C.Scratch, M.SmoothPlastic, SM)
end
B.part(CK, "HourHand", V3(0.35, 2.6, 0.05), cb * CFrame.Angles(0, 0, math.rad(4)) * CFrame.new(0, 1.2, -0.76), C.Scratch, M.Metal, SM)
B.part(CK, "MinuteHand", V3(0.22, 3.6, 0.05), cb * CFrame.Angles(0, 0, math.rad(8)) * CFrame.new(0, 1.7, -0.8), C.Scratch, M.Metal, SM)
B.ball(CK, "Cap", cb * CFrame.new(0, 0, -0.8), 0.5, V3(0, 0, 0), C.Gold, M.Metal, SM)
-- cracks radiating from an impact point, plus a punched-out hole
local hit = cb * CFrame.new(-1.6, -1.3, -0.7)
B.part(CK, "Hole", V3(0.06, 1.3, 1.3), up(hit), Color3.new(0, 0, 0), M.SmoothPlastic, SM).Shape = Enum.PartType.Cylinder
for k = 1, 9 do
	local a = math.rad(k * 40 + r:NextNumber(-12, 12))
	local p0 = V3(0, 0, 0)
	local len = r:NextNumber(1.6, 3.4)
	for s = 1, 3 do
		local aa = a + math.rad(r:NextNumber(-25, 25))
		local p1 = p0 + V3(math.cos(aa), math.sin(aa), 0) * (len / 3)
		local w0 = hit * CFrame.new(p0)
		local w1 = hit * CFrame.new(p1)
		NH.seg(CK, "Crack", w0.Position, w1.Position, 0.09, 0.03, C.Scratch, M.SmoothPlastic, SM).CFrame = CFrame.lookAt((w0.Position + w1.Position) / 2, w1.Position, cb.LookVector) * CFrame.new(0, 0, 0) -- lies on the face
		p0 = p1
	end
end
-- the cracks must lie in the face plane: re-orient each so its thin axis is the face normal
for _, c in CK:GetChildren() do
	if c.Name == "Crack" then
		local dir = c.CFrame.LookVector
		local n = cb.LookVector
		c.CFrame = CFrame.fromMatrix(c.Position, dir:Cross(n).Unit, n, -dir) -- X = in-plane perpendicular, Y = normal, Z = along
		c.Size = V3(0.09, 0.03, c.Size.Z)
	end
end
B.part(CK, "Pendulum", V3(0.15, 2.6, 0.1), cb * CFrame.Angles(0, 0, math.rad(18)) * CFrame.new(0, -5.6, -0.3), C.Gold, M.Metal, SM)
table.insert(out, "clock ok")

-------------------------------------------------------------------- C) things stuck to the ceiling (flip about y = 8)
local function flip(inst, zc)
	local R = CFrame.new(0, 8, zc) * CFrame.Angles(math.pi, 0, 0) * CFrame.new(0, -8, -zc)
	local list = if inst:IsA("BasePart") then { inst } else inst:GetDescendants()
	for _, p in list do
		if p:IsA("BasePart") then p.CFrame = R * p.CFrame end
	end
end
local flipped = 0
local dr = H.Ground.DiningRoom
for _, c in dr:GetChildren() do
	if c.Name == "DiningTable" or c.Name == "Chair" or c.Name == "Plate" or c.Name == "Candle" or c.Name == "Flame" or c.Name == "Lamp_hang" then
		flip(c, -21)
		flipped += 1
	end
end
local den = H.Ground.Den
for _, c in den:GetChildren() do
	if c.Name == "CardTable" or c.Name == "Puzzle" or c.Name == "Chair" then
		flip(c, 29)
		flipped += 1
	elseif c.Name == "Recliner" then
		flip(c, 21)
		flipped += 1
	end
end
-- loot that sat on flipped furniture drops to the floor below
local moved = 0
for _, l in H.LootSpawns:GetChildren() do
	local p = l.Position - V3(OX, 0, 0)
	local inDining = p.X > -37 and p.X < -18 and p.Z > -26 and p.Z < -16 and p.Y > 3 and p.Y < 13 -- ground floor only
	local inDen = p.X > 32.5 and p.X < 39.5 and ((p.Z > 17.5 and p.Z < 24.5) or (p.Z > 26.5 and p.Z < 33.5)) and p.Y > 3 and p.Y < 13
	if inDining or inDen then
		l.Position = V3(l.Position.X, 2.45, l.Position.Z)
		moved += 1
	end
end
table.insert(out, ("flipped %d, loot dropped %d"):format(flipped, moved))

-------------------------------------------------------------------- D) leaning tall furniture (tilted rooms), with shims
local leaned = 0
local function lean(m, deg, ax) -- ax = the long axis parallel to the wall behind it
	local cf, sz = m:GetBoundingBox()
	local lo = cf.Position - sz / 2
	-- pivot on one bottom corner line running along the thin axis (depth); lean sideways along the long axis
	local alongX = ax == "x"
	local piv = if alongX then V3(lo.X, lo.Y, cf.Position.Z) else V3(cf.Position.X, lo.Y, lo.Z)
	local axis = if alongX then V3(0, 0, 1) else V3(1, 0, 0)
	local a = math.rad(deg) * (if alongX then 1 else -1)
	local R = CFrame.new(piv) * CFrame.fromAxisAngle(axis, a) * CFrame.new(-piv)
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then p.CFrame = R * p.CFrame end
	end
	local w = if alongX then sz.X else sz.Z
	local lift = w * math.sin(math.abs(math.rad(deg)))
	local far = if alongX then V3(lo.X + w - 0.6, lo.Y + lift / 2, cf.Position.Z) else V3(cf.Position.X, lo.Y + lift / 2, lo.Z + w - 0.6)
	B.part(m, "Shim", V3(if alongX then 1.2 else math.min(sz.X, 1.2), lift, if alongX then math.min(sz.Z, 1.2) else 1.2), CFrame.new(far), C.WoodRaw:Lerp(C.Tint, 0.3), M.Wood, SM)
	leaned += 1
end
for _, c in lr:GetChildren() do if c.Name == "Bookshelf" then lean(c, 6, "x") end end
local oneShelf = false
for _, c in den:GetChildren() do if c.Name == "Bookshelf" and not oneShelf then oneShelf = true lean(c, 4, "z") end end
for _, c in H.Ground.EntryHall:GetChildren() do if c.Name == "GrandfatherClock" then lean(c, 7, "z") end end -- (the hall tree stays upright: its back is on the wall)
table.insert(out, "leaned " .. leaned)

-------------------------------------------------------------------- E) THE LONG HALL (east annex, x 46..94)
local LH = NH.fresh("LongHall")
local floorCol = H.Structure:FindFirstChild("GroundFloor").Color
local wallCol = Color3.fromRGB(125, 89, 65)
local ceilCol = Color3.fromRGB(140, 118, 116)
local siding = H.Exterior:FindFirstChild("Facade_right").Color
-- clear exterior decor in the footprint (never grass / facade / fence / boundary)
local cleared = 0
for _, p in (NH.partsIn(46.2, 0.05, -9, 97, 17, 3)) do
	if p.Parent and p:IsDescendantOf(H.Exterior) and p.Name ~= "Grass" and not string.find(p.Name, "Facade") and not p:FindFirstAncestor("Boundary") and not p:FindFirstAncestor("Fence") then
		p:Destroy()
		cleared += 1
	end
end
local cN, dN = NH.cut(44.9, 2, -6.75, 46.3, 14, 0.75)
table.insert(out, ("long hall: cleared %d, cut %d, removed %d"):format(cleared, cN, dN))
local X0, X1 = 46, 94
NH.box(LH, "Foundation", X0 - 0.1, -0.6, -7.9, X1 + 1.1, 1.3, 1.9, C.Brick:Lerp(C.Tint, 0.4), M.Brick, { solid = true })
NH.box(LH, "Floor", X0 - 0.1, 1.3, -7.75, X1 + 1, 2, 1.75, floorCol, M.WoodPlanks, { solid = true })
NH.box(LH, "Threshold", 44.9, 1.6, -6.75, 46.05, 2.03, 0.75, C.WoodDark, M.Wood, { solid = true })
for _, s in { { -7.75, -7, -6.75, 1 }, { 1.75, 1, 0.75, -1 } } do
	NH.box(LH, "Siding", X0, 2, math.min(s[1], s[2]), X1 + 1, 14.3, math.max(s[1], s[2]), siding, M.WoodPlanks, { solid = true })
	NH.box(LH, "Wall", X0, 2, math.min(s[2], s[3]), X1, 14, math.max(s[2], s[3]), wallCol, M.Plaster, { solid = true })
	local f = s[3]
	NH.box(LH, "Trim", X0, 2, f, X1, 2.7, f + s[4] * 0.18, C.WoodDark, M.Wood, SM)
	NH.box(LH, "Rail", X0, 5.6, f, X1, 5.9, f + s[4] * 0.2, C.WoodDark, M.Wood, SM)
end
NH.box(LH, "EndWall", X1, 2, -7, X1 + 1, 14.3, 1, wallCol, M.Plaster, { solid = true })
NH.box(LH, "Ceiling", X0, 14, -7, X1, 14.3, 1, ceilCol, M.Plaster, { solid = true })
NH.box(LH, "Roof", X0, 14.3, -8.3, X1 + 1.5, 15.2, 2.3, B.C.Roof, M.Slate, { solid = true })
NH.box(LH, "RoofCap", X1 + 1, 2, -7.75, X1 + 1.3, 14.3, 1.75, siding:Lerp(B.C.Ink, 0.2), M.Wood, SM)
-- doors every 9 studs; bricked ones only where their open leaf cannot meet another
local south = { [51] = "closed", [60] = "closed", [69] = "ajar", [78] = "closed", [87] = "brick" }
local north = { [51] = "closed", [60] = "ajar", [69] = "brick", [78] = "closed", [87] = "closed" }
south[51] = "brick"
for x, mode in south do NH.fakeDoor(LH, NH.CF(x, 2, -6.75, "+z"), mode) end
for x, mode in north do NH.fakeDoor(LH, NH.CF(x, 2, 0.75, "-z"), mode) end
NH.fakeDoor(LH, NH.CF(X1, 2, -3, "-x"), "brick", nil, 100) -- leaf nearly square to the wall so it stays inside the hall
-- the same portrait, again and again, a little more crooked each time
local k = 0
for _, x in { 55.5, 64.5, 73.5, 82.5 } do
	for _, side in { { -6.75, "+z" }, { 0.75, "-z" } } do
		k += 1
		local wb = NH.CF(x, 8.6, side[1], side[2]) * CFrame.Angles(0, 0, math.rad(k * 3.2))
		local pic = B.picture(LH, wb, 2, 2.6, { portrait = true, clothes = C.Velvet, hair = Color3.fromRGB(150, 146, 150), eyes = C.Red, canvas = C.Tint })
		local head = pic:FindFirstChild("Head")
		if head then
			head.Color = Color3.fromRGB(40, 30, 34)
			for s = 1, 3 do
				B.part(pic, "Scratch", V3(1.05, 0.07, 0.02), CFrame.new(head.Position) * wb.Rotation * CFrame.new(0, 0, -0.07 - s * 0.01) * CFrame.Angles(0, 0, math.rad(-40 + s * 35)), C.Scratch, M.SmoothPlastic, SM)
			end
		end
	end
end
-- consoles with loot, a vase, two creaky boards, one sickly sconce (the rest of the hall is dark)
for _, t in { { 55.5, 0.75, "-z" }, { 82.5, -6.75, "+z" } } do
	local b = NH.CF(t[1], 2, t[2] + (if t[3] == "-z" then -0.7 else 0.7), t[3])
	local m = B.model(LH, "HallConsole")
	B.rp(m, "Top", b, V3(3.2, 0.25, 1.2), V3(0, 3, 0), C.WoodDark, M.Wood, { solid = true })
	for _, sx in { -1.4, 1.4 } do
		B.rp(m, "Leg", b, V3(0.2, 2.9, 0.2), V3(sx, 1.45, 0.35), C.WoodDark, M.Wood, SM)
		B.rp(m, "Leg", b, V3(0.2, 2.9, 0.2), V3(sx, 1.45, -0.35), C.WoodDark, M.Wood, SM)
	end
	NH.loot("Ground", 2, (b * CFrame.new(0.6, 3.125, 0)).Position)
end
B.vase(LH, NH.CF(55.5 - 1, 5.125, 0.75 - 0.7, "-z"), C.Tint:Lerp(C.Velvet, 0.5), 0.8)
NH.creak(NH.V(62, 2, -3))
NH.creak(NH.V(80, 2, -3), 90)
NH.lamp(LH, "sconce", NH.CF(69, 9.6, 0.75, "-z"), "Ground", false, { bright = 0.7, range = 16 })
B.lamp(LH, "sconce", NH.CF(87, 9.6, -6.75, "+z"), "Ground", { bright = 0 }) -- dead fitting (re-tagged below)
for _, l in LH:GetChildren() do
	if l.Name == "Lamp_sconce" and l:FindFirstChildWhichIsA("Light", true).Brightness == 0 then
		game:GetService("CollectionService"):RemoveTag(l, "Lamp")
		l:FindFirstChildWhichIsA("Light", true):Destroy()
		l.Bulb.Material = M.Glass
		l.Bulb.Color = C.DeadBulb
		l.Bulb.Name = "DeadBulb"
		l:SetAttribute("Area", nil)
	end
end
-- dolls waiting at the end of the hall
for i, z in { -3.3, -2.0 } do
	B.doll(LH, NH.CF(X1 - 0.8, 2, z, "-x"), 1.3 + (i % 2) * 0.3, if i % 2 == 0 then C.Velvet else B.C.WPlum)
end
NH.room("LongHall", "The Long Hall", "Ground", 2, 45, 2, -7, X1, 14, 1)
NH.node("Ground", NH.V(58, 2, -3))
NH.node("Ground", NH.V(84, 2, -3))
-- veins crawling out of the far door
local VF = NH.F("Veins", NH.F("Nightmare"))
local nv = 0
local rb = { 45, 2, -7, X1, 14, 1 }
nv += NH.wallVein(VF, rb, V3(90, 11, -3), V3(1, 0, 0), 9, 11, 2)
nv += NH.wallVein(VF, rb, V3(90, 3.2, -1.5), V3(1, 0, 0), 6, 12, 1)
nv += NH.wallVein(VF, rb, V3(90, 6, -3), V3(0, 0, 1), 14, 13, 2)
nv += NH.wallVein(VF, rb, V3(90, 9, -3), V3(0, 0, -1), 12, 14, 2)
nv += NH.wallVein(VF, rb, V3(92, 10, -3), V3(0, 1, 0), 16, 15, 2)
nv += NH.wallVein(VF, rb, V3(80, 12, -3), V3(0, 0, 1), 10, 16, 2)
table.insert(out, "long hall veins " .. nv)
table.insert(out, "parts now " .. NH.count())
return table.concat(out, "\n")
