-- HarvestFair Corruption decor (shown by the service at corruption >= N). Non-collidable, non-queryable clutter.
-- 1: crows on the hoarding and booth roofs. 2: clown masks nailed up + chalk "HAHA" boards.
-- 3: extra scarecrows in the midway watching the entrance. 4: a giant grinning face on the Big Top, glowing-eyed
-- carousel horses, "SHE SEES YOU" boards. Section "corruption" (idempotent: rebuilds the four level folders).
local B = _G.HF
local C, M = B.C, B.M
local V = Vector3.new
local root = B.root()
B.begin("corruption")
local CF = B.F("Corruption")
local L = {}
for i = 1, 4 do
	local f = CF:FindFirstChild(tostring(i))
	if f then f:Destroy() end
	f = Instance.new("Folder")
	f.Name = tostring(i)
	f.Parent = CF
	L[i] = f
end
local SM = { small = true, collide = false, query = false }
local function sm(p) p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false return p end
local function ball(par, name, pos, d, col, mat) return sm(B.part(par, name, V(d, d, d), CFrame.new(pos), col, mat or M.SmoothPlastic, { small = true, shape = Enum.PartType.Ball })) end

-- 1: crows (body on the perch top)
for i, p in { V(-100, 7, -40), V(-100, 7, 20), V(100, 7, -70), V(-30, 9.3, -50), V(30, 9.3, -27), V(-24, 9.4, -85), V(0, 14.4, -26), V(13.5, 16.6, -94.2) } do
	local m = B.model(L[1], "Crow")
	local yaw = math.rad(i * 47)
	local b = CFrame.new(p) * CFrame.Angles(0, yaw, 0)
	sm(B.rp(m, "Body", b, V(0.5, 0.5, 0.9), V(0, 0.25, 0), C.Ink, M.SmoothPlastic, SM))
	ball(m, "Head", (b * CFrame.new(0, 0.6, -0.45)).Position, 0.35, C.Ink)
	sm(B.rp(m, "Beak", b, V(0.1, 0.1, 0.3), V(0, 0.6, -0.72), C.Mustard:Lerp(C.Ink, 0.3), M.SmoothPlastic, SM))
	sm(B.rp(m, "Tail", b, V(0.3, 0.08, 0.5), V(0, 0.3, 0.65), C.Ink, M.SmoothPlastic, SM, CFrame.Angles(math.rad(-20), 0, 0)))
end

-- 2: clown masks on booth fronts / hoarding + chalk boards
for i, spec in { { V(-34, 6, -58), V(0, 0, -1) }, { V(-26, 6, -58), V(0, 0, -1) }, { V(26, 6, -58), V(0, 0, -1) }, { V(34, 6, -58), V(0, 0, -1) }, { V(-34, 6, -19), V(0, 0, 1) }, { V(34, 6, -19), V(0, 0, 1) }, { V(-44, 5, -94.8), V(0, 0, 1) } } do
	local p, look = spec[1], spec[2]
	local off = V(0, 0, 0)
	local f = B.clownFace(L[2], CFrame.lookAt(p + off, p + off + look), 0.45, { hair = ({ C.Rose, C.Mint, C.Mustard })[i % 3 + 1] })
	for _, d in f:GetDescendants() do if d:IsA("BasePart") then sm(d) end end
end
for i, p in { V(-12, 0.05, -66), V(14, 0.05, -8) } do
	local m = B.model(L[2], "ChalkBoard")
	local b = CFrame.new(p) * CFrame.Angles(0, math.rad(if i == 1 then 180 else 160), 0)
	sm(B.rp(m, "Board", b, V(3, 2.2, 0.15), V(0, 3.2, 0), C.Ink:Lerp(C.Teal, 0.2), M.Slate, SM))
	sm(B.rp(m, "Leg", b, V(0.2, 2.2, 0.2), V(-1.2, 1.1, 0.4), C.WoodDark, M.Wood, SM, CFrame.Angles(math.rad(-10), 0, 0)))
	sm(B.rp(m, "Leg", b, V(0.2, 2.2, 0.2), V(1.2, 1.1, 0.4), C.WoodDark, M.Wood, SM, CFrame.Angles(math.rad(-10), 0, 0)))
	B.text(m.Board, "HA HA HA\nHA HA", { face = Enum.NormalId.Front, color = C.Paper, stroke = C.Ink, strokeT = 1, font = Enum.Font.IndieFlower })
end

-- 3: scarecrows standing in the midway, all facing the entrance arch
for i, p in { V(-12, 0.05, -48), V(12, 0.05, -34), V(-10, 0.05, -14) } do
	local m = B.model(L[3], "WatchingScarecrow")
	local b = CFrame.lookAt(p, V(0, 0.05, -95) * V(1, 0, 1) + V(0, p.Y, 0))
	sm(B.rp(m, "Pole", b, V(0.4, 9, 0.4), V(0, 4.5, 0), C.WoodDark, M.Wood, SM))
	sm(B.rp(m, "Shirt", b, V(2.6, 2.8, 1.2), V(0, 6, 0), C.Blood:Lerp(C.Ink, 0.45), M.Fabric, SM))
	sm(B.rp(m, "Sleeves", b, V(5.4, 0.9, 0.9), V(0, 6.8, 0), C.Blood:Lerp(C.Ink, 0.5), M.Fabric, SM))
	ball(m, "Head", (b * CFrame.new(0, 8.3, 0)).Position, 1.8, C.Sheet:Lerp(C.Ink, 0.2), M.Fabric)
	for _, sx in { -0.35, 0.35 } do
		sm(B.rp(m, "Eye", b, V(0.25, 0.25, 0.1), V(sx, 8.5, -0.9), Color3.fromRGB(255, 70, 70), M.Neon, SM))
	end
	sm(B.rp(m, "Grin", b, V(0.9, 0.12, 0.1), V(0, 7.9, -0.88), C.Ink, M.SmoothPlastic, SM))
end

-- 4: giant face on the Big Top front, glowing carousel eyes, warning boards
do
	local f = B.clownFace(L[4], CFrame.lookAt(V(0, 15.6, 59.6), V(0, 15.6, 40)), 1.6, { hair = C.Blood:Lerp(C.Ink, 0.2), eyeGlow = Color3.fromRGB(255, 60, 60) })
	for _, d in f:GetDescendants() do if d:IsA("BasePart") then sm(d) end end
end
local car = root.Sections.plaza:FindFirstChild("Carousel")
if car then
	for _, h in car:GetChildren() do
		if h.Name == "HorseHead" then
			for _, sx in { -0.47, 0.47 } do
				sm(B.part(L[4], "HorseEyeGlow", V(0.05, 0.2, 0.2), (B.OFF:Inverse() * h.CFrame) * CFrame.new(sx, 0.2, -0.4), Color3.fromRGB(255, 60, 60), M.Neon, SM))
			end
		end
	end
end
for i, p in { { V(-46.5, 3, -50), "+x" }, { V(0, 3, -71), "-z" } } do
	local pos, dir = p[1], p[2]
	local m = B.model(L[4], "WarningBoard")
	local b = B.cf(pos.X, 0.05, pos.Z, dir)
	sm(B.rp(m, "Post", b, V(0.3, 5.2, 0.3), V(0, 2.6, 0.2), C.WoodDark, M.Wood, SM))
	local bd = sm(B.rp(m, "Board", b, V(3.6, 1.6, 0.15), V(0, 4.2, 0), C.Paper:Lerp(C.Ink, 0.2), M.Wood, SM))
	B.text(bd, "SHE SEES YOU", { face = Enum.NormalId.Front, color = C.Blood, font = Enum.Font.Creepster })
end
local n = { 0, 0, 0, 0 }
for i = 1, 4 do for _, d in L[i]:GetDescendants() do if d:IsA("BasePart") then n[i] += 1 end end end
return ("corruption parts %d/%d/%d/%d"):format(n[1], n[2], n[3], n[4])
