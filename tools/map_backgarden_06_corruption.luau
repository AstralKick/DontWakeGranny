-- BackGarden 06: Corruption decor (Corruption/1..4, shown at corruption >= N) + small fixes.
-- Everything here is non-collidable, non-queryable decor. Idempotent (clears the Corruption folders first).
local B = _G.BGB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local root = B.root()
local CF = B.F("Corruption")
for i = 1, 4 do
	for _, c in B.F(tostring(i), CF):GetChildren() do c:Destroy() end
end
local function deco(o)
	o = o or {}
	o.small = true
	o.collide = false
	return o
end
local SM = deco()
local function eyes(par, pos, face, s)
	s = s or 1
	local b = CFrame.lookAt(pos, pos + face)
	for _, sx in { -1, 1 } do
		B.part(par, "Eye", V(0.28 * s, 0.2 * s, 0.05), b * CFrame.new(sx * 0.3 * s, 0, 0), Color3.fromRGB(255, 70, 60), M.Neon, SM)
	end
end

-- ===== 1: the dolls come out; the gnomes turn to watch the house
local L1 = B.F("1", CF)
for i, p in { V(-12, 0, 18), V(6, 0, 8), V(-2, 0, -12), V(18, 0, 24) } do
	B.doll(L1, CFrame.lookAt(p, V(2, 0, 54)), 1.2 + (i % 2) * 0.2, ({ C.Rose, C.Mint, C.Bruise, C.Mustard })[i]:Lerp(C.Ink, 0.35))
end
B.box(L1, "Scratches", -49.99, 4, -4, -49.95, 6.5, 0, C.Paper:Lerp(C.Ink, 0.2), M.SmoothPlastic, SM)
for i = 0, 3 do
	B.box(L1, "ScratchLine", -49.95, 4.3 + i * 0.55, -3.8 + i * 0.3, -49.93, 4.42 + i * 0.55, -0.6 - i * 0.2, C.Blood:Lerp(C.Ink, 0.3), M.SmoothPlastic, SM)
end
B.part(L1, "FallenPot", V(1.1, 0.8, 0.8), CFrame.new(-4, 0.4, 32) * CFrame.Angles(0, 0, math.rad(90)), C.Terracotta:Lerp(C.Ink, 0.2), M.Slate, deco({ shape = Enum.PartType.Cylinder }))
for i = 0, 4 do
	B.part(L1, "Shard", V(0.4, 0.08, 0.3), CFrame.new(-3 + i * 0.4, 0.04, 31.4 + (i % 2) * 0.5) * CFrame.Angles(0, math.rad(i * 40), 0), C.Terracotta, M.Slate, SM)
end

-- ===== 2: crows on the washing line, stained sheets, extra webs in the greenhouse
local L2 = B.F("2", CF)
for i = 0, 4 do
	local p = V(-22, 7.72, 12):Lerp(V(14, 7.72, 16), 0.12 + i * 0.19)
	local crow = B.model(L2, "Crow")
	B.part(crow, "Body", V(0.5, 0.5, 0.9), CFrame.new(p + V(0, 0.25, 0)), C.Ink, M.Fabric, deco({ shape = Enum.PartType.Ball }))
	B.part(crow, "Head", V(0.35, 0.35, 0.35), CFrame.new(p + V(0, 0.6, -0.35)), C.Ink, M.Fabric, deco({ shape = Enum.PartType.Ball }))
	B.part(crow, "Beak", V(0.1, 0.1, 0.25), CFrame.new(p + V(0, 0.58, -0.6)), C.Mustard:Lerp(C.Ink, 0.4), M.SmoothPlastic, SM)
	crow:SetAttribute("NoGround", true)
end
for i, z in { 3, 12, 22, 31 } do
	B.cobweb(L2, V(31 + (i % 2) * 18, 8.5, z), 90, 1.1)
end
do
	local a, b = V(-22, 7.6, 12), V(14, 7.6, 16)
	local dir = (b - a).Unit
	local p = a + dir * 21.5 - V(0, 3.4, 0)
	B.part(L2, "Stain", V(0.1, 1.6, 1.3), CFrame.lookAt(p, p + dir) * CFrame.new(0, 0, 0.6), C.Blood:Lerp(C.Ink, 0.35), M.Fabric, SM)
end
for i, p in { V(-50, 0, 28), V(-60, 0, 46), V(-40, 0, 40) } do
	B.part(L2, "DeadApple", V(0.5, 0.4, 0.5), CFrame.new(p + V(0, 0.2, 0)), C.Ink:Lerp(C.Blood, 0.4), M.SmoothPlastic, deco({ shape = Enum.PartType.Ball }))
	local _ = i
end

-- ===== 3: dolls hung from the oak, eyes in the hedges, an empty rocking chair on the lawn
local L3 = B.F("3", CF)
for i, dx in { 1.2, 2.8, 6.7 } do
	local top = V(14 + dx, 11.2, -2)
	local rope = B.part(L3, "Rope", V(0.06, 3, 0.06), CFrame.new(top - V(0, 1.5, 0)), C.Paper:Lerp(C.Ink, 0.4), M.Fabric, SM)
	local d = B.doll(L3, CFrame.new(top - V(0, 4.6, 0)) * CFrame.Angles(0, math.rad(i * 70), 0), 1.1, C.Paper:Lerp(C.Ink, 0.4))
	d:SetAttribute("NoGround", true)
	local _ = rope
end
for _, e in {
	{ V(-32.97, 6, -18), V(1, 0, 0) }, { V(-32.97, 4.5, 6), V(1, 0, 0) }, { V(31.03, 6.2, 52), V(1, 0, 0) },
	{ V(70.97, 6, -24), V(-1, 0, 0) }, { V(80.97, 5.8, 5), V(-1, 0, 0) }, { V(103.03, 6.5, 38.4), V(1, 0, 0) }, { V(130.97, 5, -5), V(-1, 0, 0) },
	{ V(0, 5.5, -52.97), V(0, 0, 1) }, { V(40, 6, -52.97), V(0, 0, 1) },
} do
	eyes(L3, e[1], e[2], 1)
end
do
	local b = cf(-10, 0, -18, 200)
	local m = B.model(L3, "EmptyRocker")
	B.rp(m, "Seat", b, V(2.2, 0.25, 2.2), V(0, 1.9, 0), C.Wicker, M.Fabric, SM)
	for _, sx in { -1, 1 } do
		B.rp(m, "Rocker", b, V(0.2, 0.3, 3.6), V(sx * 1, 0.15, 0), C.WoodDark, M.Wood, SM)
		B.rp(m, "Leg", b, V(0.2, 1.6, 0.2), V(sx * 1, 1.05, -0.8), C.Wicker, M.Wood, SM)
		B.rp(m, "Leg", b, V(0.2, 1.6, 0.2), V(sx * 1, 1.05, 0.8), C.Wicker, M.Wood, SM)
		B.rp(m, "Post", b, V(0.2, 3.4, 0.2), V(sx * 0.95, 3.4, 1.0), C.Wicker, M.Wood, SM)
	end
	B.rp(m, "Back", b, V(2.2, 2.8, 0.2), V(0, 3.6, 1.0), C.Wicker, M.Fabric, SM)
	B.rp(m, "Blanket", b, V(1.6, 1.4, 0.15), V(0.2, 2.8, 0.85), C.Rose:Lerp(C.Ink, 0.3), M.Fabric, SM)
end

-- ===== 4: the garden turns: red roses everywhere, silhouettes in every window, a Grandma-shaped scarecrow
local L4 = B.F("4", CF)
for i = 0, 23 do
	local a = i * 2.39996
	local r = 6 + (i % 6) * 5
	local p = V(-4 + math.cos(a) * r, 0, 12 + math.sin(a) * r * 0.8)
	B.part(L4, "BloodRose", V(0.6, 0.6, 0.6), CFrame.new(p + V(0, 0.9 + (i % 3) * 0.2, 0)), C.Blood, M.Fabric, deco({ shape = Enum.PartType.Ball }))
	B.part(L4, "RoseStem", V(0.08, 0.9, 0.08), CFrame.new(p + V(0, 0.45, 0)), C.Moss:Lerp(C.Ink, 0.4), M.Wood, SM)
end
for _, x in { -30, -12, 24, 38 } do
	B.box(L4, "Silhouette", x - 0.7, 15.8, 59.84, x + 0.7, 18.4, 59.87, C.Ink, M.SmoothPlastic, SM)
	B.part(L4, "SilhouetteHead", V(1, 1, 0.03), CFrame.new(x, 18.9, 59.855), C.Ink, M.SmoothPlastic, deco({ shape = Enum.PartType.Cylinder })).CFrame = B.SH * CFrame.new(x, 18.9, 59.855) * CFrame.Angles(0, math.rad(90), 0)
end
do
	local sc = B.model(L4, "GrandmaScarecrow")
	local b = cf(-4, 0, -6, "-z") * CFrame.Angles(0, math.pi, 0)
	B.rp(sc, "Pole", b, V(0.3, 9, 0.3), V(0, 4.5, 0), C.WoodDark, M.Wood, SM)
	B.rp(sc, "Dress", b, V(2.8, 4, 1.4), V(0, 5, 0), C.Bruise:Lerp(C.Ink, 0.35), M.Fabric, SM)
	B.rp(sc, "Shawl", b, V(3.6, 0.9, 1.6), V(0, 6.8, 0), C.Paper:Lerp(C.Ink, 0.4), M.Fabric, SM)
	B.ball(sc, "Head", b, 1.5, V(0, 8.1, 0), C.Sheet:Lerp(C.Ink, 0.2), M.Fabric, SM)
	B.ball(sc, "Bun", b, 0.9, V(0, 8.9, 0.3), C.Paper:Lerp(C.Ink, 0.3), M.Fabric, SM)
	for _, sx in { -1, 1 } do
		B.rp(sc, "Glasses", b, V(0.45, 0.35, 0.05), V(sx * 0.3, 8.2, -0.76), C.Ink, M.SmoothPlastic, SM)
		B.rp(sc, "Eye", b, V(0.18, 0.18, 0.04), V(sx * 0.3, 8.2, -0.8), Color3.fromRGB(255, 70, 60), M.Neon, SM)
	end
	sc:SetAttribute("NoGround", true)
end
for _, e in { { V(-49.97, 7, 8), V(1, 0, 0) }, { V(29.87, 7, 5), V(-1, 0, 0) }, { V(70.97, 7.5, 40), V(-1, 0, 0) }, { V(93.03, 6, 15), V(1, 0, 0) }, { V(-76.47, 5, 5), V(1, 0, 0) }, { V(-62, -4, 33.97), V(0, 0, -1) } } do
	eyes(L4, e[1], e[2], 1.2)
end
-- flag everything as pure decor
for i = 1, 4 do
	for _, d in B.F(tostring(i), CF):GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
		end
	end
end
-- missing search node in the north orchard strip (validator)
local has = false
for _, n in B.F("SearchNodes"):GetChildren() do
	if (n.Position - (B.SH * CFrame.new(-50, 0.15, 56.5)).Position).Magnitude < 0.5 then has = true end
end
if not has then B.node("Ground", -50, 0.05, 56.5) end
local counts = {}
for i = 1, 4 do counts[i] = B.count(B.F(tostring(i), CF)) end
return "06 corruption ok: " .. table.concat(counts, "/") .. ", parts=" .. B.count(root)
