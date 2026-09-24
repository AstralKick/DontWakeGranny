-- Sunny Pines details: creaky tiles take the colour/material of the floor under them (slightly lighter, so observant
-- players can spot them), and Corruption/1..4 decor (non-collidable; the service shows level N at corruption >= N).
local B = _G.SPB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local CS = B.CS
local root = B.root()
local SM = { small = true, collide = false }

-- creaky tiles
local floors = root.Structure.Floors:GetChildren()
for _, t in CS:GetTagged("Creaky") do
	if t:IsDescendantOf(root) then
		local best = nil
		for _, f in floors do
			local rel = f.CFrame:PointToObjectSpace(t.Position)
			local h = f.Size / 2
			if math.abs(rel.X) <= h.X and math.abs(rel.Z) <= h.Z and math.abs(rel.Y) < 1 then best = f break end
		end
		if best then
			t.Color = best.Color:Lerp(C.Paper, 0.14)
			t.Material = best.Material
		end
	end
end

-- corruption
local K = root.Corruption
local function dec(level, name, size, cframe, col, mat)
	local p = B.part(K[tostring(level)], name, size, cframe, col, mat or M.SmoothPlastic, SM)
	p.CanQuery = false
	return p
end
-- 1: a wheelchair parked facing the wall, the TV left on static, a note on the Rec Room door
do
	local f = K["1"]
	local wc = B.wheelchair(f, cf(-50.2, 2, -9.5, "-x")) -- clear of the Rec Room door swing
	for _, p in wc:GetDescendants() do if p:IsA("BasePart") then p.CanCollide = false p.CanQuery = false end end
	B.sign(f, cf(-45.25, 7.2, -3.5, "-x"), 1.8, 1.2, "shhh...\nshe's resting", C.Paper, C.Blood, Enum.Font.PatrickHand)
	dec(1, "Static", V(0.05, 2.0, 2.5), CFrame.new(-36.79, 6, -5.8), Color3.fromRGB(190, 200, 210), M.Neon)
end
-- 2: the banner and the bingo board change, the matron portrait's eyes follow
do
	B.sign(K["2"], cf(-12, 10.6, -12.75, "+z"), 10, 0.9, "...AND MANY MORE. AND MORE. AND MORE.", C.PPink:Lerp(C.Ink, 0.3), C.Blood, Enum.Font.PatrickHand)
	B.sign(K["2"], cf(-36, 5.9, 12.75, "-z"), 5, 0.9, "31  31  31  31  31", C.PLemon:Lerp(C.Ink, 0.2), C.Blood, Enum.Font.FredokaOne)
	-- the former residents in the attic corridor open their eyes
	for _, x in { 16.5, 19.5, 29.5, 36.5, 49.5 } do
		for _, dx in { -0.163, 0.163 } do
			dec(2, "Eye", V(0.13, 0.08, 0.03), CFrame.new(x + dx, 34.38, -13.48), C.Blood, M.Neon)
		end
	end
end
-- 3: scratch marks along the corridors, wet footprints to the Rec Room
do
	for i, x in { -40, -20, 8, 38 } do
		for k = 0, 2 do
			dec(3, "Scratch", V(0.06, 2.2, 0.08), CFrame.new(x + k * 0.35, 7 + (i % 2) * 0.5, -13.3) * CFrame.Angles(0, 0, math.rad(12)), C.Ink:Lerp(C.Night, 0.4))
		end
	end
	for i = 0, 7 do
		local x = -20 + i * 2.2
		dec(3, "Footprint", V(0.7, 0.02, 1.1), CFrame.new(x, 2.01, -16.5 + (i % 2) * 0.8) * CFrame.Angles(0, math.rad(90), 0), C.Ink:Lerp(C.Glass, 0.2))
	end
end
-- 4: every wheelchair in the home has come to the Rec Room door; the portraits have turned round
do
	for _, x in { -30.5, -28, -25.5 } do -- lined up facing the Rec Room arch, clear of the office door swing
		local wc = B.wheelchair(K["4"], cf(x, 2, -15, "+z"))
		for _, p in wc:GetDescendants() do if p:IsA("BasePart") then p.CanCollide = false p.CanQuery = false end end
	end
	for _, x in { 16.5, 19.5, 29.5, 36.5, 49.5 } do
		dec(4, "TurnedPortrait", V(2.5, 3.1, 0.25), CFrame.new(x, 34.2, -13.625), C.WoodRaw:Lerp(C.Paper, 0.2), M.Cardboard)
	end
end
return "details ok, parts=" .. B.count(root)
