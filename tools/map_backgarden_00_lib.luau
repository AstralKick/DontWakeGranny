-- BackGarden builder library (generated from house_00_lib + house_01_props). Run first, then 00b_helpers.
-- Build order (one execute_luau call each): 00_lib, 00b_helpers, 01_ground, 02_garden, 03_greenhouse, 04_shed, 05_maze, 06_corruption; then audit/validate/pathcheck.
local CS = game:GetService("CollectionService")
local GS = game:GetService("GeometryService")
local B = {}
B.OX = 1500
B.SH = CFrame.new(1500, 0, 0)
_G.BGB = B
B.CS = CS
local M = Enum.Material
B.M = M
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
B.C = {
	Ink = Color3.fromHex("2A1A24"), Night = Color3.fromHex("3B2A3F"), Paper = Color3.fromHex("F3E9D2"),
	Rose = Color3.fromHex("D97A8A"), Mint = Color3.fromHex("9CC5A1"), Mustard = Color3.fromHex("E0B04F"),
	Bruise = Color3.fromHex("7B5C8E"), Blood = Color3.fromHex("A8323E"),
	WRose = rgb(160, 104, 112), WMint = rgb(118, 150, 124), WMustard = rgb(170, 136, 78), WPlum = rgb(96, 74, 108),
	WPaper = rgb(200, 188, 162), WNight = rgb(66, 54, 72), WTeal = rgb(78, 104, 104),
	WoodDark = rgb(58, 38, 32), WoodMid = rgb(98, 68, 50), WoodLight = rgb(136, 100, 72), WoodRaw = rgb(120, 96, 72),
	Floor = rgb(92, 64, 48), Creak = rgb(132, 98, 70), Tile = rgb(196, 188, 170), TileDark = rgb(64, 60, 70),
	Concrete = rgb(88, 86, 90), Stone = rgb(80, 74, 76), Brick = rgb(104, 62, 56),
	Siding = rgb(112, 132, 122), Roof = rgb(46, 40, 52), Grass = rgb(52, 64, 46), Dirt = rgb(62, 50, 42),
	Metal = rgb(86, 86, 92), Brass = rgb(176, 140, 72), Glass = rgb(110, 132, 168), Sheet = rgb(222, 216, 200),
	Warm = rgb(255, 184, 120), Cold = rgb(150, 170, 220),
}
B.FL = { Ground = 2, Upstairs = 15, Attic = 28, Basement = -11 }
B.CL = { Ground = 14, Upstairs = 27, Basement = 1 }

function B.root()
	local mp = workspace:FindFirstChild("Maps") return mp and mp:FindFirstChild("BackGarden")
end
function B.F(name, parent)
	parent = parent or B.root()
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end
function B.model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- o: solid (structure: collide+query), small (clutter: no collide, no shadow), inv (invisible helper),
--    collide, query, touch, shadow, tr, shape, class, refl
function B.part(parent, name, size, cf, color, mat, o)
	o = o or {}
	local p = Instance.new(o.class or "Part")
	if o.shape then p.Shape = o.shape end
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = B.SH * cf
	p.Color = color or B.C.Paper
	p.Material = mat or M.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if o.inv then
		p.Transparency = 1
		p.CanCollide = o.collide or false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
	else
		p.CanCollide = if o.collide ~= nil then o.collide else not o.small
		p.CanQuery = if o.query ~= nil then o.query else (o.solid == true)
		p.CanTouch = o.touch or false
		p.CastShadow = if o.shadow ~= nil then o.shadow else not o.small
		p.Transparency = o.tr or 0
	end
	if o.refl then p.Reflectance = o.refl end
	p.Parent = parent
	return p
end
-- axis-aligned box from bounds
function B.box(parent, name, x0, y0, z0, x1, y1, z1, color, mat, o)
	local mn = Vector3.new(math.min(x0, x1), math.min(y0, y1), math.min(z0, z1))
	local mx = Vector3.new(math.max(x0, x1), math.max(y0, y1), math.max(z0, z1))
	return B.part(parent, name, mx - mn, CFrame.new((mn + mx) / 2), color, mat, o)
end
local DIR = { ["-z"] = 0, ["+z"] = 180, ["+x"] = -90, ["-x"] = 90 }
-- base CFrame on the floor, LookVector = dir ("-z","+z","+x","-x" or degrees)
function B.cf(x, y, z, dir)
	local deg = if type(dir) == "number" then dir else (DIR[dir or "-z"] or 0)
	return CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(deg), 0)
end
-- relative part: base * offset. Shapes are only set by B.cyl/B.ball (a shared options table must never carry one).
function B.rp(parent, name, base, size, off, color, mat, o, rot)
	local cf = base * CFrame.new(off)
	if rot then cf = cf * rot end
	if o and o.shape then
		o = table.clone(o)
		o.shape = nil
	end
	return B.part(parent, name, size, cf, color, mat, o)
end
function B.cyl(parent, name, base, dia, len, off, color, mat, o, vertical)
	o = table.clone(o or {})
	o.shape = Enum.PartType.Cylinder
	local cf = base * CFrame.new(off)
	if vertical ~= false then cf = cf * CFrame.Angles(0, 0, math.rad(90)) end
	return B.part(parent, name, Vector3.new(len, dia, dia), cf, color, mat, o)
end
function B.ball(parent, name, base, dia, off, color, mat, o)
	o = table.clone(o or {})
	o.shape = Enum.PartType.Ball
	return B.part(parent, name, Vector3.new(dia, dia, dia), base * CFrame.new(off), color, mat, o)
end
function B.attrs(inst, t)
	for k, v in t do inst:SetAttribute(k, v) end
	return inst
end
function B.tag(inst, t)
	CS:AddTag(inst, t)
	return inst
end
function B.csg(op, target, tools, o)
	o = o or {}
	local fn = if op == "sub" then GS.SubtractAsync elseif op == "int" then GS.IntersectAsync else GS.UnionAsync
	local ok, res = pcall(fn, GS, target, tools, {
		CollisionFidelity = o.fid or Enum.CollisionFidelity.Box,
		RenderFidelity = Enum.RenderFidelity.Automatic,
		SplitApart = false,
	})
	if not ok or not res or not res[1] then
		warn("CSG failed for " .. target.Name .. ": " .. tostring(res))
		for _, t in tools do t:Destroy() end
		return target
	end
	local u = res[1]
	u.Name = target.Name
	u.Anchored = true
	u.CanCollide = target.CanCollide
	u.CanQuery = target.CanQuery
	u.CanTouch = target.CanTouch
	u.CastShadow = target.CastShadow
	u.UsePartColor = if o.usePartColor == nil then true else o.usePartColor
	u.Parent = target.Parent
	target:Destroy()
	for _, t in tools do t:Destroy() end
	return u
end
function B.cutter(size, cf, shape)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = B.SH * cf
	if shape then p.Shape = shape end
	return p
end

----------------------------------------------------------------- walls
-- pieces of a wall line [a,b] from y0..y1 minus gaps {c,w,h,sill}
function B.pieces(a, b, y0, y1, gaps)
	local list = {}
	gaps = gaps or {}
	table.sort(gaps, function(g1, g2) return g1.c < g2.c end)
	local cur = a
	for _, g in gaps do
		local gs, ge = g.c - g.w / 2, g.c + g.w / 2
		if gs > cur + 0.01 then table.insert(list, { cur, gs, y0, y1, false }) end
		local sill = y0 + (g.sill or 0)
		local top = y0 + (g.h or 8)
		if sill > y0 + 0.01 then table.insert(list, { gs, ge, y0, sill, true }) end
		if top < y1 - 0.01 then table.insert(list, { gs, ge, top, y1, true }) end
		cur = ge
	end
	if b > cur + 0.01 then table.insert(list, { cur, b, y0, y1, false }) end
	return list
end
-- one skin layer. axis "x" = wall runs along X at z=fixed; "z" = runs along Z at x=fixed.
-- sign = which side faces the room (+1/-1 along the normal) for baseboards/wainscot.
function B.skin(parent, name, axis, fixed, a, b, y0, y1, thick, color, mat, gaps, sign, o)
	o = o or {}
	local parts = {}
	for _, pc in B.pieces(a, b, y0, y1, gaps) do
		local s, e, ya, yb = pc[1], pc[2], pc[3], pc[4]
		local p
		if axis == "x" then
			p = B.box(parent, name, s, ya, fixed - thick / 2, e, yb, fixed + thick / 2, color, mat, { solid = true })
		else
			p = B.box(parent, name, fixed - thick / 2, ya, s, fixed + thick / 2, yb, e, color, mat, { solid = true })
		end
		table.insert(parts, p)
		-- trim at floor level
		if sign and ya <= y0 + 0.01 and not o.nobase then
			local face = fixed + sign * thick / 2
			local th = if o.wain then 3.6 else 0.7
			local d = if o.wain then 0.12 else 0.18
			local col = o.trimColor or B.C.WoodDark
			local tp
			if axis == "x" then
				tp = B.box(parent, "Trim", s, y0, face, e, y0 + th, face + sign * d, col, if o.wain then M.Wood else M.SmoothPlastic, { small = true })
			else
				tp = B.box(parent, "Trim", face, y0, s, face + sign * d, y0 + th, e, col, if o.wain then M.Wood else M.SmoothPlastic, { small = true })
			end
			if o.wain then
				if axis == "x" then
					B.box(parent, "Rail", s, y0 + th, face, e, y0 + th + 0.3, face + sign * 0.25, B.C.WoodDark, M.Wood, { small = true })
				else
					B.box(parent, "Rail", face, y0 + th, s, face + sign * 0.25, y0 + th + 0.3, e, B.C.WoodDark, M.Wood, { small = true })
				end
			end
		end
	end
	return parts
end
-- interior wall, thickness 0.5, color on -side (cn) and +side (cp). on = opts for neg side, op = opts for pos side
-- door/opening casing: jambs + header, crossing the wall thickness
-- window dressing inside a hole: glass, mullions, sill, optional curtains on the inner side (sign)

----------------------------------------------------------------- contract helpers
function B.inv(parent, name, size, cf)
	return B.part(parent, name, size, cf, B.C.Paper, M.SmoothPlastic, { inv = true })
end
function B.room(name, area, danger, x0, y0, z0, x1, y1, z1)
	local p = B.box(B.F("Rooms"), name, x0, y0, z0, x1, y1, z1, B.C.Paper, M.SmoothPlastic, { inv = true })
	return B.attrs(p, { RoomName = name, Area = area, Danger = danger })
end
function B.loot(area, danger, pos)
	local p = B.inv(B.F("LootSpawns"), "LootSpawn", Vector3.new(0.8, 0.4, 0.8), CFrame.new(pos + Vector3.new(0, 0.35, 0)))
	return B.attrs(p, { Area = area, Danger = danger })
end
function B.prize(area, pos)
	local p = B.inv(B.F("PrizeSpawns"), "PrizeSpawn", Vector3.new(1.5, 0.4, 1.5), CFrame.new(pos + Vector3.new(0, 0.35, 0)))
	return B.attrs(p, { Area = area })
end
function B.node(area, x, y, z, bath)
	local p = B.inv(B.F("SearchNodes"), "SearchNode", Vector3.new(1, 0.2, 1), CFrame.new(x, y + 0.1, z))
	B.attrs(p, { Area = area })
	if bath then p:SetAttribute("Bathroom", true) end
	return p
end
function B.searchable(p, kind, area, danger)
	p.CanQuery = true
	B.tag(p, "Searchable")
	return B.attrs(p, { Kind = kind, Area = area, Danger = danger })
end
function B.creak(x, y, z, rot)
	local p = B.part(B.F("Creaky"), "CreakyBoard", Vector3.new(4, 0.2, 4), CFrame.new(x, y - 0.08, z) * CFrame.Angles(0, math.rad(rot or 0), 0), B.C.Creak, M.WoodPlanks, { collide = true, touch = true, query = true, shadow = false })
	return B.tag(p, "Creaky")
end
-- hinged door in a doorway gap. axis/fixed/c describe the gap (like B.pieces). hs = +1 hinge on low side, -1 on high side
-- HidingSpot helper parts. insideCF faces out. front/exit are Vector3 floor positions.
function B.hideParts(m, kind, area, insideCF, front, exit)
	B.part(m, "Inside", Vector3.new(1.6, 2, 1), insideCF, B.C.Paper, M.SmoothPlastic, { inv = true })
	B.part(m, "Front", Vector3.new(2, 0.2, 2), CFrame.new(front + Vector3.new(0, 0.1, 0)), B.C.Paper, M.SmoothPlastic, { inv = true })
	local ep = exit + Vector3.new(0, 0.5, 0) -- the service places the root at Exit + 2.5
	B.part(m, "Exit", Vector3.new(2, 1, 2), CFrame.lookAt(ep, ep + (exit - insideCF.Position) * Vector3.new(1, 0, 1)), B.C.Paper, M.SmoothPlastic, { inv = true })
	B.attrs(m, { Kind = kind, Area = area })
	B.tag(m, "HidingSpot")
	return m
end
-- lamp. kind: table, floor, hang, sconce, bare, porch, candle. base = CFrame on the surface/floor/ceiling/wall
function B.lamp(parent, kind, base, area, o)
	o = o or {}
	local m = B.model(parent, "Lamp_" .. kind)
	local warm = o.color or B.C.Warm
	local shade = o.shade or B.C.Rose
	local bulbPos
	local sm = { small = true }
	if kind == "table" then
		B.cyl(m, "Base", base, 0.9, 0.2, Vector3.new(0, 0.1, 0), B.C.Brass, M.Metal, sm)
		B.cyl(m, "Stem", base, 0.5, 1.4, Vector3.new(0, 0.9, 0), o.body or B.C.Mint, M.Glass, sm)
		B.cyl(m, "Shade", base, 1.8, 1.2, Vector3.new(0, 2.1, 0), shade, M.Fabric, { small = true, tr = 0.15 })
		bulbPos = Vector3.new(0, 1.95, 0)
	elseif kind == "floor" then
		B.cyl(m, "Base", base, 1.3, 0.2, Vector3.new(0, 0.1, 0), B.C.WoodDark, M.Wood, sm)
		B.cyl(m, "Pole", base, 0.2, 5.4, Vector3.new(0, 2.8, 0), B.C.Brass, M.Metal, sm)
		B.cyl(m, "Shade", base, 2.4, 1.6, Vector3.new(0, 5.9, 0), shade, M.Fabric, { small = true, tr = 0.15 })
		bulbPos = Vector3.new(0, 5.7, 0)
	elseif kind == "hang" then -- base at ceiling underside
		B.cyl(m, "Cord", base, 0.1, 2.2, Vector3.new(0, -1.1, 0), B.C.Ink, M.SmoothPlastic, sm)
		B.cyl(m, "Shade", base, 2.2, 0.9, Vector3.new(0, -2.5, 0), shade, M.Glass, { small = true, tr = 0.2 })
		bulbPos = Vector3.new(0, -2.8, 0)
	elseif kind == "bare" then
		B.cyl(m, "Cord", base, 0.08, o.drop or 1.8, Vector3.new(0, -(o.drop or 1.8) / 2, 0), B.C.Ink, M.SmoothPlastic, sm)
		bulbPos = Vector3.new(0, -(o.drop or 1.8) - 0.3, 0)
	elseif kind == "sconce" then -- base on wall surface, LookVector out of the wall
		B.rp(m, "Plate", base, Vector3.new(0.5, 0.9, 0.1), Vector3.new(0, 0, -0.05), B.C.Brass, M.Metal, sm)
		B.rp(m, "Arm", base, Vector3.new(0.12, 0.12, 0.6), Vector3.new(0, 0, -0.35), B.C.Brass, M.Metal, sm)
		B.cyl(m, "Shade", base, 0.8, 0.8, Vector3.new(0, 0.35, -0.65), shade, M.Glass, { small = true, tr = 0.25 })
		bulbPos = Vector3.new(0, 0.3, -0.65)
	elseif kind == "porch" then
		B.rp(m, "Plate", base, Vector3.new(0.7, 1.2, 0.15), Vector3.new(0, 0, -0.08), B.C.Ink, M.Metal, sm)
		B.rp(m, "Cage", base, Vector3.new(0.9, 1.3, 0.9), Vector3.new(0, 0, -0.65), B.C.Ink, M.Glass, { small = true, tr = 0.6 })
		B.rp(m, "Cap", base, Vector3.new(1.1, 0.2, 1.1), Vector3.new(0, 0.75, -0.65), B.C.Ink, M.Metal, sm)
		bulbPos = Vector3.new(0, 0, -0.65)
	elseif kind == "candle" then
		B.cyl(m, "Wax", base, 0.3, o.h or 0.8, Vector3.new(0, (o.h or 0.8) / 2, 0), B.C.Paper, M.SmoothPlastic, sm)
		bulbPos = Vector3.new(0, (o.h or 0.8) + 0.15, 0)
	end
	local bsz = if kind == "candle" then 0.18 elseif kind == "sconce" then 0.35 else 0.55
	local bulb = B.ball(m, "Bulb", base, bsz, bulbPos, if kind == "candle" then Color3.fromRGB(255, 170, 80) else Color3.fromRGB(255, 214, 160), M.Neon, sm)
	local l = Instance.new(o.spot and "SpotLight" or "PointLight")
	l.Color = warm
	l.Brightness = o.bright or 1
	l.Range = o.range or 16
	l.Shadows = o.shadows or false
	if o.spot then
		l.Face = Enum.NormalId.Bottom
		l.Angle = o.angle or 110
	end
	l.Parent = bulb
	m.PrimaryPart = bulb
	B.attrs(m, { Area = area })
	B.tag(m, "Lamp")
	return m
end
function B.count(folder)
	local n = 0
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then n += 1 end
	end
	return n
end
-- Furniture / prop builders. Requires house_00_lib (run it first). Adds functions to _G.BGB.
-- Convention: base CFrame b sits on the floor at the footprint centre; b.LookVector = the front of the prop.
local B = _G.BGB
local C, M = B.C, B.M
local V = Vector3.new
local SM = { small = true }
local function R(m, n, b, sz, off, col, mat, o) return B.rp(m, n, b, sz, off, col, mat, o) end
local function dark(c, k) return c:Lerp(C.Ink, k or 0.35) end
B.dark = dark

function B.hideParts(m, kind, area, insideCF, front, exit)
	B.part(m, "Inside", V(1.6, 2, 1), insideCF, C.Paper, M.SmoothPlastic, { inv = true })
	B.part(m, "Front", V(2, 0.2, 2), CFrame.new(front + V(0, 0.1, 0)), C.Paper, M.SmoothPlastic, { inv = true })
	local ep = exit + V(0, 0.5, 0) -- the service places the root at Exit + 2.5
	local look = (exit - insideCF.Position) * V(1, 0, 1)
	if look.Magnitude < 0.1 then look = V(0, 0, -1) end
	B.part(m, "Exit", V(2, 1, 2), CFrame.lookAt(ep, ep + look), C.Paper, M.SmoothPlastic, { inv = true })
	B.attrs(m, { Kind = kind, Area = area })
	B.tag(m, "HidingSpot")
	return m
end

function B.table(par, b, w, d, h, col, o)
	o = o or {}
	local m = B.model(par, o.name or "Table")
	if o.oval then
		local top = R(m, "Top", b, V(w - d, 0.3, d), V(0, h - 0.15, 0), col, M.Wood)
		local c1 = B.cyl(m, "T", b, d, 0.3, V(-(w - d) / 2, h - 0.15, 0), col, M.Wood, {}, false)
		c1.CFrame = B.SH * b * CFrame.new(-(w - d) / 2, h - 0.15, 0) * CFrame.Angles(0, 0, math.rad(90))
		local c2 = B.cyl(m, "T", b, d, 0.3, V((w - d) / 2, h - 0.15, 0), col, M.Wood)
		B.csg("union", top, { c1, c2 })
	else
		R(m, "Top", b, V(w, 0.3, d), V(0, h - 0.15, 0), col, M.Wood)
	end
	local lx, lz = w / 2 - (if o.oval then d * 0.3 else 0.45), d / 2 - 0.45
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			R(m, "Leg", b, V(0.35, h - 0.3, 0.35), V(sx * lx, (h - 0.3) / 2, sz * lz), dark(col, 0.15), M.Wood)
		end
	end
	R(m, "Apron", b, V(lx * 2, 0.4, lz * 2), V(0, h - 0.5, 0), dark(col, 0.2), M.Wood, SM)
	if o.cloth then
		R(m, "Runner", b, V(w * 0.8, 0.04, math.min(1.6, d * 0.4)), V(0, h + 0.02, 0), o.cloth, M.Fabric, SM)
	end
	return m, h
end


-- big wing-back armchair. returns model, seat top height
function B.armchair(par, b, fab, name, o)
	o = o or {}
	local m = B.model(par, name or "Armchair")
	local w, d = o.w or 5, o.d or 4.8
	local pip = o.trim or C.Bruise
	local nc = { collide = false }
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			R(m, "Foot", b, V(0.4, 0.4, 0.4), V(sx * (w / 2 - 0.4), 0.2, sz * (d / 2 - 0.4)), C.WoodDark, M.Wood, SM)
		end
	end
	R(m, "Base", b, V(w, 1.3, d), V(0, 1.05, 0), fab, M.Fabric, nc)
	R(m, "Skirt", b, V(w + 0.1, 0.3, d + 0.1), V(0, 0.55, 0), pip, M.Fabric, SM)
	R(m, "Cushion", b, V(w - 1.7, 0.6, d - 1.2), V(0, 2.0, -0.4), fab:Lerp(C.Paper, 0.12), M.Fabric, nc)
	R(m, "Back", b, V(w, 5.0, 1.1), V(0, 3.5, d / 2 - 0.55), fab, M.Fabric)
	R(m, "BackTop", b, V(w - 0.6, 0.5, 1.0), V(0, 6.2, d / 2 - 0.55), fab, M.Fabric, SM)
	for _, sx in { -1, 1 } do
		R(m, "Arm", b, V(0.85, 1.3, d), V(sx * (w / 2 - 0.42), 2.35, 0), fab, M.Fabric, nc)
		R(m, "ArmRoll", b, V(1.0, 0.35, d + 0.1), V(sx * (w / 2 - 0.42), 3.1, 0), pip, M.Fabric, SM)
		R(m, "Wing", b, V(0.7, 2.6, 1.8), V(sx * (w / 2 - 0.35), 4.6, d / 2 - 1.3), fab, M.Fabric, SM)
	end
	if o.doily then R(m, "Doily", b, V(2.2, 1.1, 0.05), V(0, 5.3, d / 2 - 1.12), C.Paper, M.Fabric, SM) end
	if o.throw then R(m, "Throw", b, V(1.2, 1.9, d * 0.7), V(-(w / 2 - 0.42), 2.6, 0.2), o.throw, M.Fabric, SM) end
	return m, 2.3
end


-- bed with an under-bed hiding spot. b faces the foot of the bed.

-- wardrobe/closet/cabinet with an enclosed interior. kind: Wardrobe/Closet/Cabinet
function B.wardrobe(par, b, col, area, kind, o)
	o = o or {}
	local m = B.model(par, o.name or kind)
	local w, d, h = o.w or 5.2, 3.8, o.h or 8.8
	R(m, "Back", b, V(w, h, 0.3), V(0, h / 2, d / 2 - 0.15), col, M.Wood)
	for _, sx in { -1, 1 } do
		R(m, "Side", b, V(0.3, h, d), V(sx * (w / 2 - 0.15), h / 2, 0), col, M.Wood)
	end
	R(m, "Top", b, V(w, 0.4, d), V(0, h - 0.2, 0), col, M.Wood)
	R(m, "Crown", b, V(w + 0.5, 0.45, d + 0.3), V(0, h + 0.2, -0.15), dark(col), M.Wood, SM)
	R(m, "Plinth", b, V(w - 0.62, 0.5, d - 0.3), V(0, 0.25, -0.15), dark(col), M.Wood) -- inset: no coplanar faces with the sides/back
	local dc = o.doorColor or col
	local lw = (w - 0.1) / 2
	for _, sx in { -1, 1 } do
		local cx = sx * lw / 2
		R(m, "DoorLeaf", b, V(lw - 0.04, h - 1.0, 0.25), V(cx, 0.5 + (h - 1) / 2, -d / 2 + 0.125), dc, M.Wood)
		if o.louvre then
			for i = 1, 7 do
				R(m, "Louvre", b, V(lw - 0.7, 0.12, 0.1), V(cx, 1.6 + i * 0.75, -d / 2 - 0.02), dark(dc, 0.25), M.Wood, SM)
			end
		else
			R(m, "Inset", b, V(lw - 0.8, h * 0.36, 0.06), V(cx, 0.5 + h * 0.66, -d / 2 - 0.02), dark(dc, 0.2), M.Wood, SM)
			R(m, "Inset", b, V(lw - 0.8, h * 0.3, 0.06), V(cx, 0.5 + h * 0.22, -d / 2 - 0.02), dark(dc, 0.2), M.Wood, SM)
		end
		B.ball(m, "Knob", b, 0.28, V(sx * 0.35, 4.2, -d / 2 - 0.12), C.Brass, M.Metal, SM)
	end
	do -- meeting stile over the seam between the two leaves (closes the light slit)
		R(m, "MeetingStile", b, V(0.3, h - 1.0, 0.06), V(0, 0.5 + (h - 1) / 2, -d / 2 - 0.03), dark(dc, 0.15), M.Wood, SM)
	end
	local inside = b * CFrame.new(0, 3.1, 0.2)
	B.hideParts(m, kind, area, inside, (b * CFrame.new(0, 0, -d / 2 - 2.1)).Position, (b * CFrame.new(0, 0, -d / 2 - 2)).Position)
	return m
end

-- dresser / chest of drawers. searchIdx = which drawer (1 = top) is Searchable Drawer
function B.dresser(par, b, w, d, h, col, n, area, danger, o)
	o = o or {}
	local m = B.model(par, o.name or "Dresser")
	R(m, "Body", b, V(w, h - 0.3, d), V(0, (h - 0.3) / 2 + 0.3, 0), col, M.Wood)
	R(m, "Top", b, V(w + 0.3, 0.2, d + 0.2), V(0, h + 0.1, -0.05), dark(col, 0.25), M.Wood)
	for _, sx in { -1, 1 } do
		R(m, "Foot", b, V(0.4, 0.3, 0.4), V(sx * (w / 2 - 0.3), 0.15, -(d / 2 - 0.3)), dark(col), M.Wood, SM)
	end
	local dh = (h - 0.6) / n
	for i = 1, n do
		local y = h - 0.15 - dh * (i - 0.5)
		local f = R(m, "DrawerFront", b, V(w - 0.4, dh - 0.15, 0.15), V(0, y, -d / 2 - 0.07), dark(col, 0.1), M.Wood, { collide = false })
		for _, sx in { -1, 1 } do
			B.ball(m, "Pull", b, 0.22, V(sx * w * 0.25, y, -d / 2 - 0.2), C.Brass, M.Metal, SM)
		end
		if o.search and table.find(o.search, i) then
			f.Name = "Drawer"
			B.searchable(f, o.kind or "Drawer", area, danger)
		end
	end
	return m, h + 0.2
end

-- kitchen base counter run along local X; returns model. search = { [i] = "Cabinet"/"Drawer" }

-- upper wall cabinets (b on the floor against the wall)



-- CRT TV on a wooden console. Tagged Lamp (the glowing screen is the Bulb).


-- picture on a wall. wb = CFrame at the wall surface centre of the picture, LookVector out of the wall

function B.doll(par, b, s, dress, o)
	o = o or {}
	local m = B.model(par, "Doll")
	s = s or 1
	R(m, "Dress", b, V(0.8 * s, 0.9 * s, 0.6 * s), V(0, 0.45 * s, 0), dress, M.Fabric, SM)
	R(m, "Skirt", b, V(1.0 * s, 0.35 * s, 0.8 * s), V(0, 0.18 * s, 0), dress:Lerp(C.Paper, 0.2), M.Fabric, SM)
	B.ball(m, "Head", b, 0.7 * s, V(0, 1.2 * s, 0), C.Paper:Lerp(C.Rose, 0.15), M.SmoothPlastic, SM)
	B.ball(m, "Hair", b, 0.74 * s, V(0, 1.3 * s, 0.08 * s), o.hair or C.Mustard:Lerp(C.WoodMid, 0.4), M.Fabric, SM)
	for _, sx in { -1, 1 } do
		R(m, "Eye", b, V(0.1 * s, 0.1 * s, 0.05 * s), V(sx * 0.14 * s, 1.24 * s, -0.33 * s), C.Ink, M.SmoothPlastic, SM)
		R(m, "Arm", b, V(0.18 * s, 0.6 * s, 0.18 * s), V(sx * 0.5 * s, 0.55 * s, 0), C.Paper:Lerp(C.Rose, 0.15), M.SmoothPlastic, SM)
	end
	return m
end

function B.trunk(par, b, col, area, danger, o)
	o = o or {}
	local m = B.model(par, "Trunk")
	local w, d = o.w or 3.6, o.d or 2.2
	R(m, "Body", b, V(w, 1.6, d), V(0, 0.8, 0), col, M.Wood)
	local lid = R(m, "Lid", b, V(w + 0.1, 0.55, d + 0.1), V(0, 1.88, 0), dark(col, 0.1), M.Wood)
	B.searchable(lid, "Trunk", area, danger)
	for _, x in { -w * 0.3, w * 0.3 } do
		R(m, "Band", b, V(0.25, 2.2, d + 0.16), V(x, 1.1, 0), C.Metal:Lerp(C.Ink, 0.3), M.Metal, SM)
	end
	R(m, "Latch", b, V(0.4, 0.5, 0.1), V(0, 1.6, -d / 2 - 0.08), C.Brass, M.Metal, SM)
	return m
end

-- sheet-covered furniture. shape: chair/tall/table



function B.rug(par, x, y, z, w, d, col, border)
	B.box(par, "Rug", x - w / 2, y - 0.04, z - d / 2, x + w / 2, y + 0.05, z + d / 2, border or dark(col, 0.3), M.Fabric, { small = true, collide = false })
	B.box(par, "RugField", x - w / 2 + 0.6, y - 0.04, z - d / 2 + 0.6, x + w / 2 - 0.6, y + 0.07, z + d / 2 - 0.6, col, M.Fabric, { small = true, collide = false })
end


-- cobweb: invisible card with a vetted Toolbox cobweb image on both faces (decal 5050225113 -> image 5050225104)
B.WEB = "rbxassetid://5050225104"
function B.cobweb(par, pos, rot, s)
	s = s or 1
	local p = B.part(par, "Cobweb", V(3.4 * s, 3.4 * s, 0.05), CFrame.new(pos) * CFrame.Angles(0, math.rad(rot), 0) * CFrame.Angles(math.rad(-30), 0, 0), C.Paper, M.SmoothPlastic, { small = true, tr = 1 })
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local d = Instance.new("Decal")
		d.Texture = B.WEB
		d.Face = face
		d.Transparency = 0.1
		d.Parent = p
	end
	return p
end

function B.jar(par, pos, col, s)
	s = s or 1
	local b = CFrame.new(pos)
	B.cyl(par, "Jar", b, 0.55 * s, 0.75 * s, V(0, 0.375 * s, 0), col, M.Glass, { small = true, tr = 0.15 }, true)
	B.cyl(par, "Lid", b, 0.5 * s, 0.1, V(0, 0.8 * s, 0), C.Brass, M.Metal, SM, true)
end

function B.candleSet(par, pos, n, seed)
	for i = 1, n do
		local a = (i * 2.4 + (seed or 0))
		local r = 0.3 + (i % 3) * 0.25
		local h = 0.4 + ((i * 7) % 5) * 0.18
		local b = CFrame.new(pos + V(math.cos(a) * r, 0, math.sin(a) * r))
		B.cyl(par, "Candle", b, 0.25, h, V(0, h / 2, 0), C.Paper:Lerp(C.Mustard, 0.15), M.SmoothPlastic, SM, true)
		B.ball(par, "Flame", b, 0.14, V(0, h + 0.1, 0), Color3.fromRGB(255, 176, 90), M.Neon, SM)
	end
end
return "BackGarden lib ok"
