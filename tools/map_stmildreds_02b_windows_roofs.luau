-- St. Mildred's 02b: windows (from B.WINS recorded by 02), belfry louvres, roofs, gables, spire.
local B = _G.SMB
local C, M = B.C, B.M
local V = Vector3.new
local S = B.F("Structure")
local WF = B.F("Windows", S)
assert(B.WINS and #B.WINS > 0, "run 02_masonry first")

local function louvre(wn)
	local m = B.model(WF, "BelfryOpening")
	local T = wn.f1 - wn.f0
	local fc = (wn.f0 + wn.f1) / 2
	local c, w = wn.c, wn.w
	local spring = wn.yt - w / 2
	local inf, cylCF
	if wn.axis == "x" then
		inf = B.box(m, "ArchInfill", c - w / 2, spring, wn.f0, c + w / 2, wn.yt, wn.f1, C.StoneW, M.Cobblestone, { solid = true })
		cylCF = CFrame.new(c, spring, fc) * CFrame.Angles(0, math.rad(90), 0)
	else
		inf = B.box(m, "ArchInfill", wn.f0, spring, c - w / 2, wn.f1, wn.yt, c + w / 2, C.StoneW, M.Cobblestone, { solid = true })
		cylCF = CFrame.new(fc, spring, c)
	end
	B.csg("sub", inf, { B.cutter(V(T + 1, w, w), cylCF, Enum.PartType.Cylinder) })
	local n = math.floor((spring - wn.ys - 0.3) / 0.75)
	for i = 1, n do
		local y = wn.ys + 0.2 + (i - 0.5) * 0.75
		if wn.axis == "x" then
			B.part(m, "Louvre", V(w - 0.06, 0.12, T * 0.8), CFrame.new(c, y, fc) * CFrame.Angles(math.rad(38), 0, 0), C.WoodDark:Lerp(C.Ink, 0.3), M.Wood, B.SM)
		else
			B.part(m, "Louvre", V(T * 0.8, 0.12, w - 0.06), CFrame.new(fc, y, c) * CFrame.Angles(0, 0, math.rad(38)), C.WoodDark:Lerp(C.Ink, 0.3), M.Wood, B.SM)
		end
	end
	if wn.axis == "x" then
		B.box(m, "Collider", c - w / 2, wn.ys, wn.f0, c + w / 2, wn.yt, wn.f1, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	else
		B.box(m, "Collider", wn.f0, wn.ys, c - w / 2, wn.f1, wn.yt, c + w / 2, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	end
end
for _, wn in B.WINS do
	if wn.kind == "louvre" then
		louvre(wn)
	else
		B.lancet(WF, wn.axis, wn.f0, wn.f1, wn.c, wn.ys, wn.yt, wn.w, wn.col)
	end
end

----------------------------------------------------------------- roofs
local RF = B.F("Roofs", S)
-- slab from the ridge (x=0, y=ridgeY) down to the eave xe (signed), along Z z0..z1
local function slope(name, ridgeY, s, xe, z0, z1, xc)
	xc = xc or 0
	local sg = math.sign(xe)
	local k = math.sqrt(1 + s * s)
	local pr = Vector2.new(xc - sg * 0.5 / k, ridgeY + 0.5 * s / k)
	local pe = Vector2.new(xc + xe, ridgeY - math.abs(xe) * s)
	local ctr = (pr + pe) / 2
	local len = (pe - pr).Magnitude
	local ang = math.atan2(pe.Y - pr.Y, pe.X - pr.X)
	return B.part(RF, name, V(len, 0.8, z1 - z0), CFrame.new(ctr.X, ctr.Y, (z0 + z1) / 2) * CFrame.Angles(0, 0, ang), C.Slate, M.Slate, { solid = true })
end
-- gable triangle half: full height at x=xc (top at ridgeY) sloping to baseY at xc + len*dir
local function gable(name, xc, baseY, topY, len, dir, z0, z1)
	local h = topY - baseY
	local ctr = V(xc + dir * len / 2, baseY + h / 2, (z0 + z1) / 2)
	return B.part(RF, name, V(z1 - z0, h, len), CFrame.lookAt(ctr, ctr + V(dir, 0, 0)), C.StoneW, M.Cobblestone, { solid = true, class = "WedgePart" })
end
-- nave: ridge Y40, eaves at x=+-18.5 (y 27.5)
local sN = 12.5 / 18.5
slope("NaveRoof", 40, sN, 18.5, -24, 26)
slope("NaveRoof", 40, sN, -18.5, -7, 25.95)
slope("NaveRoof", 40, sN, -16.3, -23.95, -7)
B.box(RF, "Ridge", -0.6, 40.2, -24.2, 0.6, 40.9, 26.2, C.Slate:Lerp(C.Ink, 0.3), M.Slate, { small = true })
local gl = 12 / sN
gable("Gable", 0, 28, 40, gl, 1, 24, 25.5)
gable("Gable", 0, 28, 40, gl, -1, 24, 25.5)
gable("Gable", 0, 28, 40, gl, 1, -23.5, -22)
gable("Gable", 0, 28 + 16 * sN * 0 + (40 - 28) - 16 * (12 / gl), 40, 16, -1, -23.5, -22)
B.box(RF, "GableFill", -16, 28, -23.5, 0, 40 - 16 * (12 / gl), -22, C.StoneW, M.Cobblestone, { solid = true })
-- porch: ridge 16, eaves +-7.3 (y 11.8)
local sP = 4.2 / 7.3
slope("PorchRoof", 16, sP, 7.3, -34, -23.3)
slope("PorchRoof", 16, sP, -7.3, -33.95, -23.35)
B.box(RF, "Ridge", -0.4, 16.2, -34.2, 0.4, 16.7, -23.2, C.Slate:Lerp(C.Ink, 0.3), M.Slate, { small = true })
gable("Gable", 0, 12, 16, 4 / sP, 1, -33, -31.5)
gable("Gable", 0, 12, 16, 4 / sP, -1, -33, -31.5)
-- chancel: ridge 31, eaves +-9.8 (y 24.4)
local sC = 6.6 / 9.8
slope("ChancelRoof", 31, sC, 9.8, 25.3, 41.8)
slope("ChancelRoof", 31, sC, -9.8, 25.35, 41.75)
B.box(RF, "Ridge", -0.5, 31.2, 25.2, 0.5, 31.8, 42, C.Slate:Lerp(C.Ink, 0.3), M.Slate, { small = true })
gable("Gable", 0, 25, 31, 6 / sC, 1, 40, 41)
gable("Gable", 0, 25, 31, 6 / sC, -1, 40, 41)
-- copings on the flat roofs' parapets and lean-tos
B.box(RF, "Coping", -26.7, 23.5, -7, -24.8, 23.9, 24, C.StoneD, M.Limestone, { small = true })
B.box(RF, "Coping", 24.8, 13, -7, 26.7, 13.4, 24, C.StoneD, M.Limestone, { small = true })
B.box(RF, "Coping", -27.7, 16.5, 25.5, -25.8, 16.9, 51.7, C.StoneD, M.Limestone, { small = true })
B.box(RF, "Coping", 25.8, 16.5, 25.5, 27.7, 16.9, 51.7, C.StoneD, M.Limestone, { small = true })
B.box(RF, "Coping", -25.8, 16.5, 49.8, 25.8, 16.9, 51.7, C.StoneD, M.Limestone, { small = true })

----------------------------------------------------------------- spire (pyramid = two prisms intersected)
do
	local x0, x1, z0, z1, y0, y1 = -40.5, -18.5, -22.5, -9.5, 35, 53
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local h = y1 - y0
	local function wedge(size, ctr, dir)
		return B.part(RF, "Spire", size, CFrame.lookAt(ctr, ctr + dir), C.Slate, M.Slate, { solid = true, class = "WedgePart" })
	end
	local hz = (z1 - z0) / 2
	local hx = (x1 - x0) / 2
	local a1 = wedge(V(x1 - x0, h, hz), V(cx, y0 + h / 2, cz + hz / 2), V(0, 0, 1))
	local a2 = wedge(V(x1 - x0, h, hz), V(cx, y0 + h / 2, cz - hz / 2), V(0, 0, -1))
	local b1 = wedge(V(z1 - z0, h, hx), V(cx + hx / 2, y0 + h / 2, cz), V(1, 0, 0))
	local b2 = wedge(V(z1 - z0, h, hx), V(cx - hx / 2, y0 + h / 2, cz), V(-1, 0, 0))
	local pa = B.csg("union", a1, { a2 })
	local pb = B.csg("union", b1, { b2 })
	local sp = B.csg("int", pa, { pb })
	sp.Name = "Spire"
	B.cyl(RF, "Finial", CFrame.new(cx, y1 - 0.5, cz), 0.3, 4, V(0, 2, 0), C.Iron, M.Metal, B.SM)
	B.box(RF, "Vane", cx - 1.4, y1 + 2.6, cz - 0.05, cx + 1.4, y1 + 3.1, cz + 0.05, C.Iron, M.Metal, B.SM)
	B.box(RF, "Vane", cx - 0.05, y1 + 2.6, cz - 1.0, cx + 0.05, y1 + 3.1, cz + 1.0, C.Iron, M.Metal, B.SM)
end
return "windows+roofs ok, parts=" .. B.count(B.root())
