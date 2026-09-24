-- House builder library. Run this chunk first (execute_luau, Edit datamodel).
-- Stores helpers in _G.HB so later chunks (house_01.. files) can use them.
-- Full rebuild order (each file is one execute_luau call): 00_lib, 01_props, 02_shell (deletes and recreates
-- Workspace.House), 03_walls, 04_stairs_yard, 05_ground_a, 06_ground_b, 07_upstairs, 08_basement_attic,
-- 09_corruption, 12_exterior_details, 13_extra_hiding. Then 10_validate (contract counts/attributes) and 11_pathcheck (read-only checks).
local CS = game:GetService("CollectionService")
local GS = game:GetService("GeometryService")
local B = {}
_G.HB = B
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
	return workspace:FindFirstChild("House")
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
	p.CFrame = cf
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
	p.CFrame = cf
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
function B.iwall(parent, axis, fixed, a, b, y0, y1, cn, cp, gaps, on, op)
	on = on or {}
	op = op or {}
	B.skin(parent, "Wall", axis, fixed - 0.125, a, b, y0, y1, 0.25, cn, on.mat or M.Plaster, gaps, -1, on)
	B.skin(parent, "Wall", axis, fixed + 0.125, a, b, y0, y1, 0.25, cp, op.mat or M.Plaster, gaps, 1, op)
	for _, g in gaps or {} do
		if (g.sill or 0) == 0 and g.trim ~= false then B.casing(parent, axis, fixed, g.c, g.w, y0, g.h or 8, 0.5) end
	end
end
-- door/opening casing: jambs + header, crossing the wall thickness
function B.casing(parent, axis, fixed, c, w, y0, h, wallT)
	local t = wallT + 0.3
	local col = B.C.WoodDark
	local o = { small = true }
	if axis == "x" then
		B.box(parent, "Casing", c - w / 2 - 0.35, y0, fixed - t / 2, c - w / 2, y0 + h + 0.35, fixed + t / 2, col, M.Wood, o)
		B.box(parent, "Casing", c + w / 2, y0, fixed - t / 2, c + w / 2 + 0.35, y0 + h + 0.35, fixed + t / 2, col, M.Wood, o)
		B.box(parent, "Casing", c - w / 2, y0 + h, fixed - t / 2, c + w / 2, y0 + h + 0.35, fixed + t / 2, col, M.Wood, o)
	else
		B.box(parent, "Casing", fixed - t / 2, y0, c - w / 2 - 0.35, fixed + t / 2, y0 + h + 0.35, c - w / 2, col, M.Wood, o)
		B.box(parent, "Casing", fixed - t / 2, y0, c + w / 2, fixed + t / 2, y0 + h + 0.35, c + w / 2 + 0.35, col, M.Wood, o)
		B.box(parent, "Casing", fixed - t / 2, y0 + h, c - w / 2, fixed + t / 2, y0 + h + 0.35, c + w / 2, col, M.Wood, o)
	end
end
-- window dressing inside a hole: glass, mullions, sill, optional curtains on the inner side (sign)
function B.window(parent, axis, fixed, c, y0, sill, top, w, wallT, sign, curtain)
	local m = B.model(parent, "Window")
	local yc = y0 + (sill + top) / 2
	local hgt = top - sill
	local base
	if axis == "x" then
		base = CFrame.new(c, yc, fixed) * CFrame.Angles(0, if sign > 0 then math.pi else 0, 0)
	else
		base = CFrame.new(fixed, yc, c) * CFrame.Angles(0, if sign > 0 then -math.pi / 2 else math.pi / 2, 0)
	end
	-- base LookVector points INTO the room (-Z local = room side)
	B.rp(m, "Glass", base, Vector3.new(w, hgt, 0.1), Vector3.new(0, 0, 0), B.C.Glass, M.Glass, { tr = 0.55, solid = true, shadow = false })
	B.rp(m, "Mullion", base, Vector3.new(0.2, hgt, 0.3), Vector3.new(0, 0, 0), B.C.Paper, M.Wood, { small = true })
	B.rp(m, "Mullion", base, Vector3.new(w, 0.2, 0.3), Vector3.new(0, hgt * 0.1, 0), B.C.Paper, M.Wood, { small = true })
	local frameC = B.C.Paper
	B.rp(m, "Frame", base, Vector3.new(w + 0.6, 0.3, wallT + 0.2), Vector3.new(0, hgt / 2 + 0.15, 0), frameC, M.Wood, { small = true })
	B.rp(m, "Sill", base, Vector3.new(w + 0.9, 0.3, wallT + 0.9), Vector3.new(0, -hgt / 2 - 0.15, -0.3), frameC, M.Wood, { small = true })
	B.rp(m, "Frame", base, Vector3.new(0.3, hgt, wallT + 0.2), Vector3.new(-w / 2 - 0.15, 0, 0), frameC, M.Wood, { small = true })
	B.rp(m, "Frame", base, Vector3.new(0.3, hgt, wallT + 0.2), Vector3.new(w / 2 + 0.15, 0, 0), frameC, M.Wood, { small = true })
	if curtain then
		local d = -(wallT / 2 + 0.35)
		B.rp(m, "Rod", base, Vector3.new(w + 3, 0.15, 0.15), Vector3.new(0, hgt / 2 + 0.8, d), B.C.WoodDark, M.Wood, { small = true })
		B.rp(m, "Curtain", base, Vector3.new(1.4, hgt + 2.2, 0.2), Vector3.new(-w / 2 - 0.5, -0.3, d), curtain, M.Fabric, { small = true })
		B.rp(m, "Curtain", base, Vector3.new(1.4, hgt + 2.2, 0.2), Vector3.new(w / 2 + 0.5, -0.3, d), curtain, M.Fabric, { small = true })
	end
	return m
end

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
function B.pumpkin(area, pos, face)
	local p = B.inv(B.F("PumpkinSpots"), "PumpkinSpot", Vector3.new(1.5, 0.2, 1.5), B.cf(pos.X, pos.Y + 0.1, pos.Z, face))
	return B.attrs(p, { Area = area })
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
function B.door(parent, name, axis, fixed, c, y0, area, squeaky, lockable, color, hs, w)
	hs = hs or 1
	w = w or 4.5
	local right = if axis == "x" then Vector3.xAxis else Vector3.zAxis
	local hinge = if axis == "x" then Vector3.new(c - hs * w / 2, y0, fixed) else Vector3.new(fixed, y0, c - hs * w / 2)
	local base = CFrame.fromMatrix(hinge, right * hs, Vector3.yAxis)
	local m = B.model(parent, name)
	local hp = B.rp(m, "Hinge", base, Vector3.new(0.2, 8, 0.2), Vector3.new(0, 4, 0), B.C.Paper, M.SmoothPlastic, { inv = true })
	local panel = B.rp(m, "Panel", base, Vector3.new(w - 0.1, 7.9, 0.3), Vector3.new(w / 2, 3.98, 0), color or B.C.WoodMid, M.Wood, { collide = true, query = true })
	local pm = Instance.new("PathfindingModifier")
	pm.PassThrough = true
	pm.Parent = panel
	local dk = (color or B.C.WoodMid):Lerp(B.C.Ink, 0.3)
	for _, zz in { -0.17, 0.17 } do
		B.rp(m, "Inset", base, Vector3.new(w - 1.3, 2.9, 0.06), Vector3.new(w / 2, 5.6, zz), dk, M.Wood, { small = true })
		B.rp(m, "Inset", base, Vector3.new(w - 1.3, 3.2, 0.06), Vector3.new(w / 2, 1.9, zz), dk, M.Wood, { small = true })
		B.ball(m, "Knob", base, 0.32, Vector3.new(w - 0.45, 3.6, zz * 1.6), B.C.Brass, M.Metal, { small = true })
	end
	m.PrimaryPart = hp
	B.attrs(m, { Area = area, Squeaky = squeaky, Lockable = lockable })
	B.tag(m, "Door")
	return m
end
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
return "lib ok"
