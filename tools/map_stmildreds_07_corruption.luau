-- St. Mildred's 07: Corruption decor (shown at corruption >= N by the service). All non-collidable, no query/touch.
local B = _G.SMB
local C, M = B.C, B.M
local V = Vector3.new
local CO = B.F("Corruption")
local c1, c2, c3, c4 = B.F("1", CO), B.F("2", CO), B.F("3", CO), B.F("4", CO)
local NC = { small = true, collide = false }
local G = 2
-- 1: more cobwebs
for _, p in { { V(-15.3, 26, -21.3), 45 }, { V(15.3, 26, 23.3), 225 }, { V(-15.3, 26, 23.3), 135 }, { V(7.4, 23, 39.4), 225 }, { V(-25.4, 13.3, 26.1), 45 }, { V(25.3, 13.3, 49.4), 225 }, { V(-41, 20.4, -9.1), 135 }, { V(-25.3, 0.3, 49.2), 135 } } do
	B.cobweb(c1, p[1], p[2], 1.1)
end
-- 2: fallen hymn books and toppled candles in the nave
for i, p in { { -1.2, 2.4 }, { 1.4, 9.1 }, { -12.1, 11.3 }, { 11.8, -1.6 }, { 0.6, -14.2 }, { -10.4, 20.2 } } do
	B.part(c2, "FallenBook", V(0.8, 0.18, 0.6), CFrame.new(p[1], G + 0.1, p[2]) * CFrame.Angles(0, math.rad(i * 47), 0), C.Blood:Lerp(C.Ink, 0.45), M.Fabric, NC)
end
for i, p in { { 4.2, 18.3 }, { -3.1, 21.4 }, { 9.6, 18.9 } } do
	B.part(c2, "ToppledCandle", V(0.9, 0.3, 0.3), CFrame.new(p[1], G + 0.15, p[2]) * CFrame.Angles(0, math.rad(i * 70), 0), C.Wax, M.SmoothPlastic, NC)
end
-- 3: damp stains / creeping ivy on the walls, wilted petals
for i, s in { { "z", 15.95, 6, 4 }, { "z", -15.95, -3, 6 }, { "x", 23.95, -11.5, 2.5 }, { "x", -21.95, 14, 3 } } do
	local h = 6 + i
	if s[1] == "z" then
		B.box(c3, "Stain", s[2] - 0.03, 2.1, s[3] - s[4] / 2, s[2] + 0.03, 2.1 + h, s[3] + s[4] / 2, C.Moss:Lerp(C.Ink, 0.55), M.Grass, NC)
	else
		B.box(c3, "Stain", s[3] - s[4] / 2, 17, s[2] - 0.03, s[3] + s[4] / 2, 17 + h * 0.8, s[2] + 0.03, C.Moss:Lerp(C.Ink, 0.55), M.Grass, NC)
	end
end
for i = 1, 8 do
	local a = i * 0.8
	B.part(c3, "Petal", V(0.35, 0.05, 0.25), CFrame.new(6.3 + math.cos(a) * 1.4, G + 0.03, 20.6 + math.sin(a) * 0.9) * CFrame.Angles(0, a, 0), C.WoodDark:Lerp(C.Lily, 0.35), M.Fabric, NC)
end
-- 4: red votive glow around Grandma's pew and faint eyes in the belfry louvres
for i = 1, 6 do
	local a = math.pi * (i - 0.5) / 6
	local p = V(6.25 + math.cos(a) * 4.2, G, 17.4 + math.sin(a) * 2.6)
	B.cyl(c4, "RedCandle", CFrame.new(p), 0.25, 0.5, V(0, 0.25, 0), C.Blood:Lerp(C.Ink, 0.3), M.SmoothPlastic, NC)
	B.ball(c4, "RedFlame", CFrame.new(p), 0.16, V(0, 0.6, 0), Color3.fromRGB(255, 70, 60), M.Neon, NC)
end
for _, e in { { V(-43.3, 29.4, -16.5), V(-43.3, 29.4, -15.5) }, { V(-29.9, 29.4, -25.3), V(-29.1, 29.4, -25.3) } } do
	for _, p in e do
		B.part(c4, "Eye", V(0.25, 0.14, 0.25), CFrame.new(p), Color3.fromRGB(255, 60, 50), M.Neon, NC)
	end
end
return "corruption ok, parts=" .. B.count(B.root())
