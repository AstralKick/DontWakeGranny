-- Exterior character: front cross-gable (CSG round window), shutters, window boxes, brick chimney. Requires 00..04.
local B = _G.HB
local C, M = B.C, B.M
local V = Vector3.new
local EX = B.F("Exterior")
local old = EX:FindFirstChild("Details")
if old then old:Destroy() end
local D = B.model(EX, "Details")
local T = C.Paper:Lerp(C.Ink, 0.12)
local SM = { small = true }

-- shutters on the front windows (both floors) and window boxes with dead flowers on the ground floor
local shutter = C.Bruise:Lerp(C.Ink, 0.45)
for fl, list in B.WIN.front do
	local y0 = B.FL[fl]
	for _, c in list do
		for _, sx in { -1, 1 } do
			local x = c + sx * 3.1
			B.box(D, "Shutter", x - 0.65, y0 + 3.2, -36.35, x + 0.65, y0 + 9.3, -36.05, shutter, M.WoodPlanks, SM)
			for k = 1, 5 do
				B.box(D, "Slat", x - 0.55, y0 + 3.2 + k * 1.02, -36.42, x + 0.55, y0 + 3.3 + k * 1.02, -36.34, shutter:Lerp(C.Ink, 0.3), M.Wood, SM)
			end
		end
		if fl == "Ground" then
			B.box(D, "WindowBox", c - 2.4, y0 + 2.2, -37.1, c + 2.4, y0 + 3.1, -36.05, C.Paper:Lerp(C.Ink, 0.35), M.Wood, SM)
			B.box(D, "Soil", c - 2.2, y0 + 3.0, -36.95, c + 2.2, y0 + 3.15, -36.2, C.Dirt, M.Ground, SM)
			for k = -2, 2 do
				local h = 0.8 + ((c + k) % 3) * 0.35
				B.part(D, "DeadStem", V(0.1, h, 0.1), CFrame.new(c + k * 0.85, y0 + 3.1 + h / 2, -36.6) * CFrame.Angles(math.rad(((c * k) % 30) - 15), 0, math.rad(((c + k * 7) % 40) - 20)), C.WoodDark:Lerp(C.Grass, 0.3), M.Wood, SM)
			end
		end
	end
end

-- cross-gable over the centre of the front facade (X -12..10), with a round CSG window
do
	local x0, x1, xm = -12, 10, -1
	local ybase, ytop = 27.4, 37
	local zf, zb = -36.3, -26
	local half = (x1 - x0) / 2
	local rise = ytop - ybase
	-- front and back triangles (two wedges each)
	for _, z in { zf, zb } do
		local w1 = B.part(D, "CrossGable", V(0.6, rise, half), CFrame.new(xm - half / 2, ybase + rise / 2, z) * CFrame.Angles(0, math.rad(90), 0), C.Siding, M.WoodPlanks, { solid = true, class = "WedgePart" })
		local w2 = B.part(D, "CrossGable", V(0.6, rise, half), CFrame.new(xm + half / 2, ybase + rise / 2, z) * CFrame.Angles(0, math.rad(-90), 0), C.Siding, M.WoodPlanks, { solid = true, class = "WedgePart" })
		local g = B.csg("union", w1, { w2 })
		if z == zf then
			local wy = ybase + rise * 0.42
			g = B.csg("sub", g, { B.cutter(V(3, 3.2, 3.2), CFrame.new(xm, wy, z) * CFrame.Angles(0, math.rad(90), 0), Enum.PartType.Cylinder) })
			local ring = B.part(D, "RoundFrame", V(0.8, 3.8, 3.8), CFrame.new(xm, wy, z - 0.05) * CFrame.Angles(0, math.rad(90), 0), T, M.Wood, { small = true, shape = Enum.PartType.Cylinder })
			B.csg("sub", ring, { B.cutter(V(2, 3.1, 3.1), CFrame.new(xm, wy, z - 0.05) * CFrame.Angles(0, math.rad(90), 0), Enum.PartType.Cylinder) })
			B.part(D, "RoundGlass", V(0.1, 3.2, 3.2), CFrame.new(xm, wy, z) * CFrame.Angles(0, math.rad(90), 0), C.Glass, M.Glass, { tr = 0.45, shape = Enum.PartType.Cylinder, solid = true })
			B.part(D, "AtticGlow", V(0.05, 2.6, 2.6), CFrame.new(xm, wy, z + 0.2) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(120, 70, 50), M.Neon, { small = true, shape = Enum.PartType.Cylinder, tr = 0.55 })
			B.box(D, "Mullion", xm - 0.1, wy - 1.6, z - 0.2, xm + 0.1, wy + 1.6, z + 0.1, T, M.Wood, SM)
			B.box(D, "Mullion", xm - 1.6, wy - 0.1, z - 0.2, xm + 1.6, wy + 0.1, z + 0.1, T, M.Wood, SM)
		end
	end
	-- the two roof slopes of the cross-gable
	local th = math.atan2(rise, half)
	local slopeLen = math.sqrt(rise * rise + half * half)
	local depth = zb - zf + 2.2
	for _, s in { -1, 1 } do
		local mid = V(xm + s * half / 2, ybase + rise / 2, (zf + zb) / 2 - 1)
		local rot = CFrame.Angles(0, 0, -s * th)
		B.part(D, "CrossRoof", V(slopeLen + 1.6, 0.8, depth), CFrame.new(mid) * rot * CFrame.new(s * 0.6, 0.7, 0), C.Roof, M.Slate, { solid = true })
		B.part(D, "CrossFascia", V(slopeLen + 1.6, 1, 0.3), CFrame.new(mid) * rot * CFrame.new(s * 0.6, 0.55, -depth / 2 - 0.1), T, M.Wood, SM)
	end
	B.box(D, "CrossRidge", xm - 0.6, ytop + 0.3, zf - 2.3, xm + 0.6, ytop + 1.3, zb, C.Roof:Lerp(C.Ink, 0.3), M.Slate, SM)
end

-- brick chimney on the east wall (above the living-room fireplace)
do
	local brick = C.Brick:Lerp(C.Ink, 0.2)
	B.box(D, "Chimney", 46, -0.6, -23.2, 49.2, 41, -18.8, brick, M.Brick, { solid = true })
	B.box(D, "ChimneyCap", 45.7, 41, -23.5, 49.5, 41.8, -18.5, C.Stone, M.Concrete, SM)
	B.box(D, "Flue", 47, 41.8, -22, 48.2, 43, -20, C.Ink, M.Metal, SM)
end
return "exterior details ok, parts=" .. B.count(B.root())
