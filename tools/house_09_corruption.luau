-- Corruption decor (House.Corruption.1..4). Shown by EnvironmentService when corruption >= N. Requires 00..08.
-- Everything here is non-collidable decor so it never changes pathing.
local B = _G.HB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local G, U, BS, AT = B.FL.Ground, B.FL.Upstairs, B.FL.Basement, B.FL.Attic
local CR = B.F("Corruption")
local L1, L2, L3, L4 = B.F("1", CR), B.F("2", CR), B.F("3", CR), B.F("4", CR)
for _, f in { L1, L2, L3, L4 } do f:ClearAllChildren() end
local SM = { small = true }
local function decorize(inst)
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
		end
	end
	if inst:IsA("BasePart") then
		inst.CanCollide = false
		inst.CanQuery = false
		inst.CanTouch = false
	end
	return inst
end

----------------------------------------------------------------- 1: pictures turned to the wall, extra cobwebs
do
	local turned = {
		cf(2.75, G + 7.5, -12, "-x"), cf(30.5, G + 7.6, -6.75, "+z"), cf(0.75, G + 7.8, 3.2, "-x"),
		cf(-18, G + 7.8, -7.25, "-z"), cf(40, G + 8.4, -7.25, "-z"), cf(-32, U + 7.4, -6.75, "+z"),
		cf(2.7, U + 7.4, 0.75, "-z"), cf(-12.75, U + 6.4, 30, "+x"),
	}
	for i, wb in turned do
		decorize(B.picture(L1, wb, 1.8 + (i % 3) * 0.4, 2.4 + (i % 2) * 0.5, { back = true, name = "TurnedPicture" }))
	end
	-- a portrait that fell and lies face down in the entry
	decorize(B.picture(L1, CFrame.new(-10.8, G + 0.12, -20) * CFrame.Angles(math.rad(90), math.rad(20), 0), 2.2, 2.8, { back = true, name = "FallenPicture" }))
	local corners = {
		{ -12, 13.2, -34, -135 }, { 2, 13.2, -34, 135 }, { -44, 13.2, -34, -135 }, { 44, 13.2, -34, 135 },
		{ -44, 13.2, 20, -45 }, { 44, 13.2, 0, 45 }, { -12, 13.2, 0, -45 }, { -44, 26.2, -34, -135 },
		{ 44, 26.2, -34, 135 }, { -12, 26.2, 34, -45 }, { 44, 26.2, 34, 45 }, { 12, 26.2, -8, 45 },
		{ -44, 0.2, -34, -135 }, { 44, 0.2, -34, 135 }, { 12, 0.2, 34, 45 },
	}
	for _, c in corners do
		B.cobweb(L1, V(c[1], c[2], c[3]), c[4], 1.1)
	end
end

----------------------------------------------------------------- 2: scratch marks, dolls in odd places, peeling wallpaper
do
	local function scratches(wb, n, len)
		local m = B.model(L2, "Scratches")
		for i = 1, n do
			B.rp(m, "Scratch", wb, V(0.07, len * (0.8 + (i % 3) * 0.15), 0.03), V((i - n / 2) * 0.28, (i % 2) * 0.2, -0.02), C.Ink, M.SmoothPlastic, SM, CFrame.Angles(0, 0, math.rad(18)))
		end
		return decorize(m)
	end
	scratches(cf(-9.2, G + 5.2, -7.25, "-z"), 4, 2.4)
	scratches(cf(21.2, G + 3.2, 0.75, "-z"), 5, 1.8)
	scratches(cf(15.5, U + 5.5, -6.75, "+z"), 4, 2.6)
	scratches(cf(-12.75, U + 4, -24, "+x"), 3, 2)
	scratches(cf(22.75, BS + 4, -21.5, "-x"), 5, 2.2)
	scratches(cf(-0.2, AT + 3, 25.4, "-z"), 4, 1.6)
	-- dolls where dolls should not be
	for _, spec in {
		{ cf(-9.5, G + 0.8125 * 6, 12.3, "-z"), 1.0, C.Rose },
		{ cf(-16.4, G + 7.1, 19.5, "-z"), 0.9, C.Mint },
		{ cf(12, G + 5.25, -24.8, "+z"), 0.8, C.Paper },
		{ cf(43.2, U, -3, "-x"), 1.3, C.Bruise },
		{ cf(5.2, G + 1.1, 11.2, "-z"), 0.9, C.Mustard },
		{ cf(-31, BS, 16, "+x"), 1.1, C.Blood:Lerp(C.Paper, 0.3) },
		{ cf(-1.8, U + 2.3, 32.4, -20), 1.2, C.Paper:Lerp(C.Rose, 0.3) },
	} do
		decorize(B.doll(L2, spec[1], spec[2], spec[3]))
	end
	-- peeling wallpaper: curled strips + exposed plaster behind them
	local function peel(wb, wallCol)
		local m = B.model(L2, "PeelingWallpaper")
		B.rp(m, "Exposed", wb, V(1.6, 2.6, 0.02), V(0, 0, -0.01), C.Paper:Lerp(C.Ink, 0.35), M.Plaster, SM)
		B.rp(m, "Strip", wb, V(0.8, 2.4, 0.04), V(-0.4, -0.3, -0.35), wallCol:Lerp(C.Paper, 0.15), M.Plaster, SM, CFrame.Angles(math.rad(-28), math.rad(10), 0))
		B.rp(m, "Strip", wb, V(0.7, 1.6, 0.04), V(0.45, 0.2, -0.22), wallCol:Lerp(C.Paper, 0.1), M.Plaster, SM, CFrame.Angles(math.rad(-18), math.rad(-14), 0))
		return decorize(m)
	end
	peel(cf(18, G + 11, -7.25, "-z"), C.WRose)
	peel(cf(-12.75, G + 11, -31, "+x"), C.WMustard)
	peel(cf(-6, U + 11, -7.25, "-z"), C.WMint)
	peel(cf(-30, U + 11, -6.75, "+z"), C.WPlum)
	peel(cf(-45, G + 11, -10, "+x"), C.WMint)
	peel(cf(0.75, G + 11, 14, "-x"), C.WPlum)
end

----------------------------------------------------------------- 3: red stains, furniture on the ceiling, stacked chairs
do
	local stainCol = C.Blood:Lerp(C.Ink, 0.35)
	local function stain(p, d, y)
		local s = B.cyl(L3, "Stain", CFrame.new(p.X, (y or p.Y) + 0.09, p.Z), d, 0.02, V(0, 0, 0), stainCol, M.SmoothPlastic, { small = true, tr = 0.1 }, true)
		return decorize(s)
	end
	-- a trail from the living-room door to the basement door
	local trail = { V(36, G, -5.2), V(33, G, -3.4), V(30.2, G, -2.2), V(27.1, G, -3.6), V(24.4, G, -2.1), V(21.6, G, -1.2), V(19.2, G, -0.2) }
	for i, p in trail do stain(p, 0.5 + (i % 3) * 0.35) end
	stain(V(18, G, 0.1), 1.8)
	stain(V(29, U, -24), 2.6)
	stain(V(3, G, 3), 1.4)
	stain(V(-35, BS, -18), 3.2)
	stain(V(41, BS, -25), 2)
	stain(V(-25, AT, 0), 1.6)
	-- handprint smear + wall streaks
	for i, wb in { cf(21.5, G + 4.5, 0.74, "-z"), cf(-12.74, U + 5, 16, "+x"), cf(44.98, BS + 5, -29, "-x") } do
		local m = B.model(L3, "Smear")
		B.rp(m, "Smear", wb, V(1.1, 1.3, 0.02), V(0, 0, -0.01), stainCol, M.SmoothPlastic, SM)
		for k = 1, 3 do
			B.rp(m, "Drip", wb, V(0.12, 1 + k * 0.5, 0.02), V(-0.35 + k * 0.3, -0.6 - k * 0.25, -0.012), stainCol, M.SmoothPlastic, SM)
		end
		decorize(m)
	end
	-- furniture stuck to the ceiling
	local up = CFrame.Angles(math.pi, 0, 0)
	decorize(B.chair(L3, CFrame.new(-33, 14, -21) * up * CFrame.Angles(0, math.rad(30), 0), C.WoodDark, { cushion = C.Rose:Lerp(C.Ink, 0.2) }))
	decorize(B.chair(L3, CFrame.new(-25, 14, -20) * up * CFrame.Angles(0, math.rad(-70), 0), C.WoodDark, { cushion = C.Rose:Lerp(C.Ink, 0.2) }))
	decorize(B.chair(L3, CFrame.new(-27, 14, 5) * up * CFrame.Angles(0, math.rad(12), 0), C.Paper:Lerp(C.Ink, 0.2)))
	decorize(B.table(L3, CFrame.new(28, 14, -14) * up * CFrame.Angles(0, math.rad(20), 0), 2.4, 2.4, 2.8, C.WoodDark, { name = "CeilingTable" }))
	decorize(B.rocker(L3, CFrame.new(-28, 27, 18) * up * CFrame.Angles(0, math.rad(40), 0), C.WoodMid))
	-- a leaning tower of chairs
	local base = cf(42.5, G, -32.5)
	for i = 0, 4 do
		local c = base * CFrame.new(math.sin(i * 1.3) * 0.25, i * 2.05, math.cos(i * 1.7) * 0.2) * CFrame.Angles(math.rad((i % 2) * 5 - 2.5), math.rad(i * 37), math.rad(((i + 1) % 2) * 4 - 2))
		decorize(B.chair(L3, c, C.WoodDark:Lerp(C.WoodMid, (i % 3) * 0.3)))
	end
	local base2 = cf(-42.5, U, -3)
	for i = 0, 3 do
		decorize(B.chair(L3, base2 * CFrame.new(0, i * 2.2, 0) * CFrame.Angles(0, math.rad(i * 55), math.rad((i % 2) * 4)), C.Paper:Lerp(C.Ink, 0.25)))
	end
end

----------------------------------------------------------------- 4: dark-red veins, portraits start staring
do
	local vein = Color3.fromRGB(70, 8, 18)
	local function veins(origin, right, up, seed, len)
		local m = B.model(L4, "Vein")
		local p = origin
		local dir = up
		for i = 1, len do
			local ang = math.rad(((seed * 17 + i * 29) % 50) - 25)
			local d = (dir * math.cos(ang) + right * math.sin(ang)).Unit
			local l = 1.2 + ((seed + i * 7) % 5) * 0.3
			local q = p + d * l
			local mid = (p + q) / 2
			B.part(m, "Vein", V(0.09, 0.09, l + 0.1), CFrame.lookAt(mid, q), vein, M.Neon, SM)
			if i % 2 == 0 then
				local bd = (d + right * (if i % 4 == 0 then 1 else -1) * 0.9).Unit
				local bq = p + bd * (l * 0.8)
				B.part(m, "VeinBranch", V(0.06, 0.06, l * 0.8), CFrame.lookAt((p + bq) / 2, bq), vein, M.Neon, SM)
			end
			p = q
			if p.Y - origin.Y > 9.5 then break end
		end
		return decorize(m)
	end
	local X, Z, Y = Vector3.xAxis, Vector3.zAxis, Vector3.yAxis
	-- ground hallway, entry, stair hall, living, upstairs hall, landing, basement hall, shrine, attic
	veins(V(-2, G + 0.2, -6.7), X, Y, 1, 7)
	veins(V(24, G + 0.2, 0.7), -X, Y, 2, 8)
	veins(V(38, G + 0.2, -6.7), X, Y, 3, 6)
	veins(V(-12.7, G + 0.2, -24), Z, Y, 4, 7)
	veins(V(0.7, G + 0.2, 8), -Z, Y, 5, 8)
	veins(V(12, G + 0.2, -7.3), X, Y, 6, 7)
	veins(V(16, U + 0.2, -6.7), X, Y, 7, 7)
	veins(V(-20, U + 0.2, 0.7), -X, Y, 8, 8)
	veins(V(-12.7, U + 0.2, 20), Z, Y, 9, 6)
	veins(V(12.7, BS + 0.2, 20), -Z, Y, 10, 8)
	veins(V(44.9, BS + 0.2, -20), Z, Y, 11, 7)
	veins(V(10, AT + 0.2, -25.3), X, Y, 12, 4)
	veins(V(-40, AT + 0.2, 25.3), -X, Y, 13, 4)
	-- every painted portrait in the house gets glowing eyes
	local n = 0
	for _, head in B.root():GetDescendants() do
		if head:IsA("BasePart") and head.Name == "Head" and head.Parent and head.Parent:IsA("Model") and head.Parent:FindFirstChild("Canvas") and not head.Parent:IsDescendantOf(CR) then
			local wb = head.CFrame * CFrame.Angles(0, math.rad(-90), 0)
			local hd = head.Size.Y
			local m = B.model(L4, "StaringEyes")
			for _, sx in { -1, 1 } do
				B.rp(m, "Eye", wb, V(hd * 0.16, hd * 0.11, 0.03), V(sx * hd * 0.18, hd * 0.02, -0.03), Color3.fromRGB(255, 60, 60), M.Neon, SM)
			end
			decorize(m)
			n += 1
		end
	end
	-- and a few new portraits appear where there were none
	local extra = { cf(-12.75, G + 9.8, -31.5, "+x"), cf(16, G + 8, -7.25, "-z"), cf(-45, U + 7.5, -32.3, "+x"), cf(-12.75, BS + 6, 12, "+x"), cf(12.75, BS + 6, 18, "-x"), cf(-45.5, AT + 4, 0, "+x") }
	for i, wb in extra do
		decorize(B.picture(L4, wb, 1.8, 2.4, { portrait = true, canvas = C.Night:Lerp(C.Blood, 0.25), clothes = C.Ink, hair = C.Ink:Lerp(C.Paper, 0.2 * (i % 3)), frame = C.Brass, eyes = Color3.fromRGB(255, 60, 60), name = "StaringPortrait" }))
	end
end
local total = 0
for _, f in { L1, L2, L3, L4 } do total += B.count(f) end
return "corruption ok, corruption parts=" .. total .. ", total parts=" .. B.count(B.root())
