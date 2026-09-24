-- St. Mildred's 02: masonry shell. Walls with rectangular holes (doors/windows), floors, ceilings, stairs/ramps structure.
-- Windows (CSG arch infill + glass) and roofs are added by 02b (uses B.WINS recorded here).
local B = _G.SMB
local C, M = B.C, B.M
local V = Vector3.new
local S = B.F("Structure")
local G, UPF, BF = 2, 13, 22

-- generic wall with any number of rectangular holes (absolute coords): holes = { {a0, a1, y0, y1}, ... }
-- splits into vertical bands at every hole edge and merges equal neighbouring bands (few parts, no overlaps).
function B.wallH(par, name, axis, f0, f1, a, b, y0, y1, holes, col, mat)
	holes = holes or {}
	local xs = { a, b }
	for _, h in holes do
		table.insert(xs, math.clamp(h[1], a, b))
		table.insert(xs, math.clamp(h[2], a, b))
	end
	table.sort(xs)
	local bands = {}
	for i = 1, #xs - 1 do
		local s, e = xs[i], xs[i + 1]
		if e - s > 0.001 then
			local hs = {}
			for _, h in holes do
				if h[1] <= s + 0.001 and h[2] >= e - 0.001 then table.insert(hs, h) end
			end
			table.sort(hs, function(p, q) return p[3] < q[3] end)
			local key = {}
			for _, h in hs do table.insert(key, h[3] .. ":" .. h[4]) end
			local k = table.concat(key, ",")
			local last = bands[#bands]
			if last and last.k == k and math.abs(last.e - s) < 0.001 then
				last.e = e
			else
				table.insert(bands, { s = s, e = e, k = k, hs = hs })
			end
		end
	end
	local out = {}
	local function emit(s, e, ya, yb)
		if yb - ya < 0.001 then return end
		local p
		if axis == "x" then
			p = B.box(par, name, s, ya, f0, e, yb, f1, col or C.StoneW, mat or M.Cobblestone, { solid = true })
		else
			p = B.box(par, name, f0, ya, s, f1, yb, e, col or C.StoneW, mat or M.Cobblestone, { solid = true })
		end
		table.insert(out, p)
	end
	for _, bd in bands do
		local cur = y0
		for _, h in bd.hs do
			emit(bd.s, bd.e, cur, math.max(cur, h[3]))
			cur = math.max(cur, h[4])
		end
		emit(bd.s, bd.e, cur, y1)
	end
	return out
end
function B.Dh(c, fy, ch) return { c - 2.6, c + 2.6, fy, fy + (ch or 8) + 0.35 } end
B.WINS = {}
-- window hole + record for 02b. kind: "glass" | "louvre"
function B.Wh(axis, f0, f1, c, w, ys, yt, kind, col)
	table.insert(B.WINS, { axis = axis, f0 = f0, f1 = f1, c = c, w = w, ys = ys, yt = yt, kind = kind or "glass", col = col })
	return { c - w / 2, c + w / 2, ys, yt }
end
local function W(axis, f0, f1, a, b, y0, y1, holes, col, mat)
	return B.wallH(S, "Wall", axis, f0, f1, a, b, y0, y1, holes, col, mat)
end
local GL1 = Color3.fromRGB(104, 86, 132) -- stained glass tints (muted)
local GL2 = Color3.fromRGB(86, 112, 132)
local GL3 = Color3.fromRGB(132, 104, 78)
local oakF = C.Oak:Lerp(C.Ink, 0.15)

----------------------------------------------------------------- nave
W("x", -23.5, -22, -17.5, 17.5, 0, 28, { B.Dh(0, G), B.Wh("x", -23.5, -22, 0, 4, 17.5, 25.5, "glass", GL1) })
W("z", -17.5, -16, -22, 24, 0, 28, { B.Dh(-16, G), B.Dh(-14, UPF, 7.5), B.Dh(19, G) })
W("z", 16, 17.5, -22, 24, 0, 28, {
	B.Dh(-4, G),
	B.Wh("z", 16, 17.5, -16, 3.6, 15, 24, "glass", GL2),
	B.Wh("z", 16, 17.5, 2, 3.6, 15, 24, "glass", GL1),
	B.Wh("z", 16, 17.5, 12, 3.6, 15, 24, "glass", GL3),
})
W("z", 16, 17.5, -8.5, 24, -12, 0) -- crypt-stair pit wall under the nave's east wall
-- north wall line (nave / rear block), below ground part carries the crypt-stair opening
W("x", 24, 25.5, -27.5, 27.5, -12, 2, { { 17.5, 25, -11, -2.65 } })
W("x", 24, 25.5, -27.5, -26.5, 2, 16.5)
W("x", 24, 25.5, -26.5, -17.5, 2, 23.5)
W("x", 24, 25.5, -17.5, 17.5, 2, 28, { { -7, 7, 2, 15 }, B.Dh(-12, G), B.Dh(12, G) })
W("x", 24, 25.5, 17.5, 27.5, 2, 16.5)
-- chancel arch: infill with a semicircular cut (spring 15, crown 22)
do
	local inf = B.box(S, "ChancelArch", -7, 15, 24, 7, 22, 25.5, C.StoneW, M.Cobblestone, { solid = true })
	local cut = B.cutter(V(2.5, 14, 14), CFrame.new(0, 15, 24.75) * CFrame.Angles(0, math.rad(90), 0), Enum.PartType.Cylinder)
	B.csg("sub", inf, { cut })
	for _, s in { -1, 1 } do -- imposts at the spring (0.05 proud of the arch reveal)
		local x0, x1 = s * 6.95, s * 8.2
		B.box(S, "Impost", math.min(x0, x1), 14.6, 23.8, math.max(x0, x1), 15.2, 25.7, C.StoneD, M.Limestone, { small = true })
	end
	for _, x in { -7.3, 7.3 } do -- dressed pier faces
		B.box(S, "Pier", x - 0.3, 2, 23.8, x + 0.3, 14.6, 24, C.StoneD, M.Limestone, { small = true })
	end
end
-- floors
B.box(S, "Floor", -16, 0, -22, -3.5, G, 24, C.WoodDark:Lerp(C.Ink, 0.15), M.WoodPlanks, { solid = true })
B.box(S, "Floor", -3.5, 0, -22, 3.5, G, 24, C.Flag, M.Slate, { solid = true })
B.box(S, "Floor", 3.5, 0, -22, 16, G, 24, C.WoodDark:Lerp(C.Ink, 0.15), M.WoodPlanks, { solid = true })
-- nave ceiling + tie beams
B.box(S, "Ceiling", -16, 28, -22, 16, 28.6, 24, C.WoodDark, M.WoodPlanks, { solid = true })
for z = -19, 22, 6.5 do
	B.box(S, "TieBeam", -16, 26.6, z - 0.4, 16, 27.4, z + 0.4, C.WoodDark:Lerp(C.Ink, 0.25), M.Wood, { small = true })
	for _, x in { -16, 16 } do
		B.box(S, "Corbel", x - (if x < 0 then 0 else 0.6), 25.6, z - 0.5, x + (if x < 0 then 0.6 else 0), 26.6, z + 0.5, C.StoneD, M.Limestone, { small = true })
	end
end
-- choir loft slab, fascia, columns
B.box(S, "LoftFloor", -16, 12, -22, 16, UPF, -10, C.WoodMid:Lerp(C.Ink, 0.2), M.WoodPlanks, { solid = true })
B.box(S, "LoftFascia", -16, 11.3, -10, 16, 12.9, -9.7, oakF, M.Wood, { small = true })
for _, x in { -6.25, 6.25 } do
	B.box(S, "LoftPost", x - 0.5, G, -11.2, x + 0.5, 12, -10.2, oakF, M.Wood, { solid = true })
	B.box(S, "PostBrace", x - 1.6, 10.9, -11.1, x + 1.6, 11.3, -10.3, oakF, M.Wood, { small = true })
end

----------------------------------------------------------------- porch
W("z", -6.5, -5, -31.5, -23.5, 0, 12.8)
W("z", 5, 6.5, -31.5, -23.5, 0, 12.8)
W("x", -33, -31.5, -6.5, 6.5, 0, 12, { { -3.5, 3.5, 2, 8 } })
do
	local inf = B.box(S, "PorchArch", -3.5, 8, -33, 3.5, 11.5, -31.5, C.StoneW, M.Cobblestone, { solid = true })
	local cut = B.cutter(V(2.5, 7, 7), CFrame.new(0, 8, -32.25) * CFrame.Angles(0, math.rad(90), 0), Enum.PartType.Cylinder)
	B.csg("sub", inf, { cut })
end
B.box(S, "PorchFloor", -5, 0, -31.5, 5, G, -23.5, C.Flag, M.Slate, { solid = true })

----------------------------------------------------------------- tower
-- tower interior x -41.5..-17.5, z -23.5..-8.5 (west wall x -43..-41.5)
W("z", -43, -41.5, -25, -7, 0, 37.5, {
	B.Dh(-16, G),
	B.Wh("z", -43, -41.5, -11, 1.2, 5, 9, "glass", GL2),
	B.Wh("z", -43, -41.5, -12, 1.2, 15.5, 19.5, "glass", GL2),
	B.Wh("z", -43, -41.5, -16, 3.6, 26, 32.5, "louvre"),
})
W("x", -25, -23.5, -41.5, -16, 0, 37.5, {
	B.Wh("x", -25, -23.5, -29.5, 1.2, 5, 9, "glass", GL2),
	B.Wh("x", -25, -23.5, -20, 1.2, 15.5, 19.5, "glass", GL2),
	B.Wh("x", -25, -23.5, -29.5, 3.6, 26, 32.5, "louvre"),
})
W("x", -8.5, -7, -41.5, -17.5, 0, 37.5, {
	B.Dh(-21.25, UPF, 7.5),
	B.Wh("x", -8.5, -7, -39.5, 1.2, 5, 9, "glass", GL2),
	B.Wh("x", -8.5, -7, -31.5, 3.6, 26, 32.5, "louvre"),
})
W("z", -17.5, -16, -23.5, -7, 28, 37.5, { B.Wh("z", -17.5, -16, -16, 3, 30.5, 33.8, "louvre") })
B.box(S, "TowerFloor", -41.5, 0, -23.5, -17.5, G, -8.5, C.Flag, M.Slate, { solid = true })
B.box(S, "RingingFloor", -41.5, 12, -23.5, -17.5, UPF, -8.5, C.WoodMid:Lerp(C.Ink, 0.25), M.WoodPlanks, { solid = true })
-- belfry stairs: flat approach x -22..-17.5 at the ringing floor, ramp x -22 (Y13) -> -35 (Y22), landing x -41.5..-35.
-- the belfry floor covers the approach strip (headroom >= 6.2) and leaves a hole x -35..-24.5 over the ramp
B.box(S, "BelfryFloor", -41.5, 21, -17.5, -17.5, BF, -8.5, C.WoodRaw:Lerp(C.Ink, 0.3), M.WoodPlanks, { solid = true })
B.box(S, "BelfryFloor", -22, 21, -23.5, -17.5, BF, -17.5, C.WoodRaw:Lerp(C.Ink, 0.3), M.WoodPlanks, { solid = true })
B.box(S, "BelfryLanding", -41.5, UPF, -23.5, -35, BF, -17.5, C.WoodRaw:Lerp(C.Ink, 0.3), M.WoodPlanks, { solid = true })
B.flight(B.F("Upstairs"), "BelfryStairs", "x", -23.5, -17.5, -22, UPF, -35, BF, 15, C.WoodMid, M.WoodPlanks, UPF)
B.box(S, "TowerRoof", -41.5, 34, -23.5, -17.5, 35, -8.5, C.Slate, M.Slate, { solid = true })
-- merlons on the parapet
local function merlons(axis, f0, f1, a, b, n)
	for i = 0, n - 1, 2 do
		local s, e = a + (b - a) * i / n, a + (b - a) * (i + 1) / n
		if axis == "x" then
			B.box(S, "Merlon", s, 37.5, f0, e, 39.3, f1, C.StoneW, M.Cobblestone, { small = true })
		else
			B.box(S, "Merlon", f0, 37.5, s, f1, 39.3, e, C.StoneW, M.Cobblestone, { small = true })
		end
	end
end
merlons("x", -25, -23.5, -43, -16, 11)
merlons("x", -8.5, -7, -43, -16, 11)
merlons("z", -43, -41.5, -23.5, -8.5, 5)
merlons("z", -17.5, -16, -23.5, -8.5, 5)

----------------------------------------------------------------- west lean-to (tower stairs + organ loft stairs foot)
W("z", -26.5, -25, -7, 24, 0, 23.5, {
	B.Wh("z", -26.5, -25, 0, 1.6, 14, 19, "glass", GL3),
	B.Wh("z", -26.5, -25, 8, 1.6, 9, 14, "glass", GL3),
	B.Wh("z", -26.5, -25, 20, 1.6, 6.5, 11, "glass", GL3),
})
B.box(S, "LeanToFloor", -25, 0, -7, -17.5, G, 24, C.Flag, M.Slate, { solid = true })
B.box(S, "LeanToRoof", -25, 22.5, -7, -17.5, 23.5, 24, C.Slate, M.Slate, { solid = true })
B.wallH(S, "Screen", "x", 14.5, 15.5, -25, -17.5, G, 22.5, { B.Dh(-21.25, G) }, oakF, M.WoodPlanks)
B.box(S, "StairLanding", -25, G, -7, -17.5, UPF, -5, C.StoneD, M.Limestone, { solid = true })
B.flight(B.F("Upstairs"), "TowerStairs", "z", -25, -17.5, 13.5, G, -5, UPF, 18, C.StoneD, M.Limestone, G)

----------------------------------------------------------------- east lean-to (crypt stairs)
W("z", 25, 26.5, -7, 24, -12, 13, {
	B.Wh("z", 25, 26.5, 4, 1.6, 5, 10, "glass", GL2),
	B.Wh("z", 25, 26.5, 14, 1.6, 5, 10, "glass", GL2),
})
W("x", -8.5, -7, 17.5, 26.5, -12, 13)
B.box(S, "PitRoof", 17.5, 12, -7, 25, 13, 24, C.Slate, M.Slate, { solid = true })
B.box(S, "PitLanding", 17.5, -12, -7, 25, G, -1, C.Flag, M.Slate, { solid = true })
B.box(S, "PitFloor", 17.5, -12, -1, 25, -11, 24, C.Flag, M.Slate, { solid = true })
B.flight(B.F("Basement"), "CryptStairs", "z", 17.5, 25, 21, -11, -1, G, 22, C.StoneD:Lerp(C.Ink, 0.2), M.Slate, -11)

----------------------------------------------------------------- rear block (chancel, lady chapel, vestry, WC, cloister passage) + crypt shell
W("z", -27.5, -26, 25.5, 51.5, -12, 16.5, {
	B.Wh("z", -27.5, -26, 32, 3, 5, 11, "glass", GL1),
})
W("z", 26, 27.5, 25.5, 51.5, -12, 16.5, {
	B.Wh("z", 26, 27.5, 28.2, 1.6, 7, 10.5, "glass", GL2),
	B.Wh("z", 26, 27.5, 36, 3, 5, 11, "glass", GL3),
	B.Wh("z", 26, 27.5, 45.5, 3, 6.5, 11.5, "glass", GL2),
})
W("x", 50, 51.5, -26, 26, -12, 16.5, {
	B.Wh("x", 50, 51.5, -18, 3, 5, 11, "glass", GL2),
	B.Wh("x", 50, 51.5, -6, 3, 5, 11, "glass", GL1),
	B.Wh("x", 50, 51.5, 6, 3, 5, 11, "glass", GL1),
	B.Wh("x", 50, 51.5, 18, 3, 5, 11, "glass", GL2),
})
-- chancel box (partitions below the roof line, clerestory above)
W("z", -9, -8, 25.5, 40, G, 25, { B.Wh("z", -9, -8, 33, 3, 16, 22, "glass", GL3) })
W("z", 8, 9, 25.5, 40, G, 25, { B.Wh("z", 8, 9, 33, 3, 16, 22, "glass", GL3) })
W("x", 40, 41, -9, 9, G, 25, { B.Dh(5, G), B.Wh("x", 40, 41, 0, 4, 15.5, 22.5, "glass", GL1) })
B.box(S, "ChancelCeiling", -8, 24, 25.5, 8, 25, 40, C.WoodDark, M.WoodPlanks, { solid = true })
-- passage wall and WC
W("x", 40, 41, -26, -9, G, 14, { B.Dh(-18, G) })
W("x", 40, 41, 9, 26, G, 14, { B.Dh(18, G) })
W("z", 19, 20, 25.5, 32, G, 14, nil, C.WPaper:Lerp(C.StoneW, 0.4), M.Plaster)
W("x", 31, 32, 20, 26, G, 14, { B.Dh(23, G) }, C.WPaper:Lerp(C.StoneW, 0.4), M.Plaster)
-- floors (stone over the crypt), ceilings/flat roof
B.box(S, "ChancelFloor", -8, 1, 25.5, 8, G, 40, Color3.fromRGB(110, 70, 58), M.Slate, { solid = true })
B.box(S, "RearFloor", -26, 1, 25.5, -8, G, 40, C.Flag, M.Slate, { solid = true })
local plank = C.WoodMid:Lerp(C.Ink, 0.25)
B.box(S, "VestryFloor", 8, 1, 25.5, 20, G, 40, plank, M.WoodPlanks, { solid = true })
B.box(S, "WCFloor", 20, 1, 25.5, 26, G, 31, C.Tile, M.Marble, { solid = true })
B.box(S, "VestryFloor", 20, 1, 31, 26, G, 40, plank, M.WoodPlanks, { solid = true })
B.box(S, "PassageFloor", -26, 1, 40, 26, G, 50, plank, M.WoodPlanks, { solid = true })
B.box(S, "RearRoof", -26, 14, 25.5, -9, 15, 41, C.Slate, M.Slate, { solid = true })
B.box(S, "RearRoof", 9, 14, 25.5, 26, 15, 41, C.Slate, M.Slate, { solid = true })
B.box(S, "RearRoof", -26, 14, 41, 26, 15, 50, C.Slate, M.Slate, { solid = true })
-- crypt: floor, dividers, pillars
B.box(S, "CryptFloor", -26, -12, 25.5, 26, -11, 50, C.Flag:Lerp(C.Ink, 0.2), M.Slate, { solid = true })
W("x", 33.5, 34.5, -26, 26, -11, 0.9, { B.Dh(-14, -11), B.Dh(14, -11) })
W("z", -1, 1, 34.5, 50, -11, 0.9, { B.Dh(42, -11) })
-- pilasters against the vault divider (the hall stays clear for Grandma)
for _, x in { -22, -6, 6, 22 } do
	B.box(S, "Pilaster", x - 0.7, -11, 32.9, x + 0.7, 0.9, 33.5, C.StoneD:Lerp(C.Ink, 0.2), M.Limestone, { solid = true })
end
-- vault ribs under the crypt ceiling
B.box(S, "CryptVault", -26, 0.9, 25.5, 26, 1, 50, C.StoneW:Lerp(C.Ink, 0.2), M.Cobblestone, { solid = true })
for _, z in { 38, 44, 49 } do
	B.box(S, "Rib", -26, 0.3, z - 0.4, -1, 0.9, z + 0.4, C.StoneD:Lerp(C.Ink, 0.3), M.Limestone, { small = true })
	B.box(S, "Rib", 1, 0.3, z - 0.4, 26, 0.9, z + 0.4, C.StoneD:Lerp(C.Ink, 0.3), M.Limestone, { small = true })
end

----------------------------------------------------------------- door frames (stone, hood moulds on the chapel's outer doors)
local frames = {
	{ "x", -22.75, 0, G, 1.5, true }, -- front door
	{ "z", -16.75, -16, G, 1.5, true }, -- nave -> tower base
	{ "z", -16.75, -14, UPF, 1.5, false }, -- ringing chamber -> choir loft
	{ "z", -16.75, 19, G, 1.5, true }, -- nave -> organ loft stairs
	{ "z", 16.75, -4, G, 1.5, true }, -- nave -> crypt stairs (iron gate)
	{ "z", -42.25, -16, G, 1.5, true }, -- tower west door
	{ "x", -7.75, -21.25, UPF, 1.5, false }, -- tower stairs top -> ringing chamber
	{ "x", 24.75, -12, G, 1.5, true }, -- nave -> lady chapel
	{ "x", 24.75, 12, G, 1.5, true }, -- nave -> vestry
	{ "x", 40.5, 5, G, 1, false }, -- chancel -> passage
	{ "x", 40.5, -18, G, 1, false }, -- lady chapel -> passage
	{ "x", 40.5, 18, G, 1, false }, -- vestry -> passage
	{ "x", 31.5, 23, G, 1, false }, -- WC
	{ "x", 34, -14, -11, 1, false }, -- crypt hall -> burial vault
	{ "x", 34, 14, -11, 1, false }, -- crypt hall -> founders' vault
	{ "z", 0, 42, -11, 2, false }, -- vault <-> vault
}
for _, f in frames do
	B.frame(S, f[1], f[2], f[3], f[4], f[5], nil, { hood = f[6], ch = if f[4] == UPF then 7.5 else 8 })
end
-- screen (organ loft stairs) frame in oak
B.frame(S, "x", 15, -21.25, G, 1, oakF, { mat = M.Wood })
return "masonry ok, windows queued " .. #B.WINS .. ", parts=" .. B.count(B.root())
