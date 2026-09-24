-- Sunny Pines builder library (adapted from house_00_lib + house_01_props).
-- Stores helpers in _G.SPB (NOT _G.HB: other map builders share this Studio session).
-- All coordinates passed to helpers are LOCAL to the map origin; B.part applies B.W = CFrame.new(3000,0,0).
-- Full rebuild (each file = one execute_luau call, Edit datamodel): 00_lib, 01_props, 02_shell (deletes and recreates
-- Workspace.Maps.SunnyPines), 03_walls, 04_ground, 05_upstairs, 06_basement_attic, 07_details.
-- Then map_sunnypines_audit.luau (registers _G.SPAudit) and run the fixing passes
--   _G.SPAudit("zfight", true)  -- shrinks the few remaining coplanar decor faces by 0.04
--   _G.SPAudit("flags", true)   -- CastShadow off on small clutter, CanQuery off on non-colliding decor
-- and the checks: 10_validate, 11_pathcheck, _G.SPAudit("doors"/"doorpaths"/"leaks"/"zfight"/"clip"/"float"/"stairs").
local CS = game:GetService("CollectionService")
local GS = game:GetService("GeometryService")
local B = {}
_G.SPB = B
B.CS = CS
B.OX = 3000
B.W = CFrame.new(B.OX, 0, 0)
local M = Enum.Material
B.M = M
local V = Vector3.new
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
B.C = {
	Ink = Color3.fromHex("2A1A24"), Night = Color3.fromHex("3B2A3F"), Paper = Color3.fromHex("F3E9D2"),
	Rose = Color3.fromHex("D97A8A"), Mint = Color3.fromHex("9CC5A1"), Mustard = Color3.fromHex("E0B04F"),
	Bruise = Color3.fromHex("7B5C8E"), Blood = Color3.fromHex("A8323E"),
	-- institutional pastels (slightly sickly)
	PMint = rgb(168, 196, 170), PPeach = rgb(222, 184, 160), PLemon = rgb(220, 206, 150), PBlue = rgb(160, 180, 196),
	PLilac = rgb(184, 168, 196), PPink = rgb(214, 170, 172), PCream = rgb(226, 214, 186), PGreen = rgb(140, 164, 130),
	Lino = rgb(176, 170, 146), LinoDark = rgb(120, 118, 100), LinoMint = rgb(150, 172, 150), LinoRose = rgb(178, 142, 138),
	Carpet = rgb(110, 84, 96), CarpetBlue = rgb(84, 96, 118), Ceil = rgb(206, 202, 188),
	WoodDark = rgb(58, 38, 32), WoodMid = rgb(98, 68, 50), WoodLight = rgb(150, 112, 76), WoodRaw = rgb(120, 96, 72),
	Creak = rgb(196, 190, 164), Tile = rgb(196, 200, 190), TileDark = rgb(64, 60, 70),
	Concrete = rgb(88, 86, 90), Stone = rgb(80, 74, 76), Brick = rgb(122, 72, 58), Render = rgb(214, 196, 160),
	Grass = rgb(52, 64, 46), Dirt = rgb(62, 50, 42), Asphalt = rgb(46, 44, 50),
	Metal = rgb(120, 122, 128), Chrome = rgb(170, 172, 178), Brass = rgb(176, 140, 72), Glass = rgb(110, 132, 168), Sheet = rgb(222, 216, 200),
	Warm = rgb(255, 196, 140), Cold = rgb(200, 220, 235), Pine = rgb(40, 62, 46),
}
local C = B.C
B.FL = { Ground = 2, Upstairs = 15, Attic = 28, Basement = -11 }

function B.root()
	return workspace:FindFirstChild("Maps") and workspace.Maps:FindFirstChild("SunnyPines")
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
-- o: solid, small, inv, collide, query, touch, shadow, tr, shape, class, refl. cf is LOCAL.
function B.part(parent, name, size, cf, color, mat, o)
	o = o or {}
	local p = Instance.new(o.class or "Part")
	if o.shape then p.Shape = o.shape end
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = B.W * cf
	p.Color = color or C.Paper
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
function B.box(parent, name, x0, y0, z0, x1, y1, z1, color, mat, o)
	local mn = V(math.min(x0, x1), math.min(y0, y1), math.min(z0, z1))
	local mx = V(math.max(x0, x1), math.max(y0, y1), math.max(z0, z1))
	return B.part(parent, name, mx - mn, CFrame.new((mn + mx) / 2), color, mat, o)
end
local DIR = { ["-z"] = 0, ["+z"] = 180, ["+x"] = -90, ["-x"] = 90 }
function B.cf(x, y, z, dir)
	local deg = if type(dir) == "number" then dir else (DIR[dir or "-z"] or 0)
	return CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(deg), 0)
end
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
	return B.part(parent, name, V(len, dia, dia), cf, color, mat, o)
end
function B.ball(parent, name, base, dia, off, color, mat, o)
	o = table.clone(o or {})
	o.shape = Enum.PartType.Ball
	return B.part(parent, name, V(dia, dia, dia), base * CFrame.new(off), color, mat, o)
end
function B.attrs(inst, t)
	for k, v in t do inst:SetAttribute(k, v) end
	return inst
end
function B.tag(inst, t)
	CS:AddTag(inst, t)
	return inst
end
-- SurfaceGui text on a part face
function B.text(p, face, txt, col, font, o)
	o = o or {}
	local g = Instance.new("SurfaceGui")
	g.Face = face or Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = o.pps or 40
	g.LightInfluence = o.light or 1
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = txt
	t.TextScaled = true
	t.TextColor3 = col or C.Ink
	t.FontFace = Font.fromEnum(font or Enum.Font.FredokaOne)
	t.Rotation = o.rot or 0
	t.Parent = g
	return g
end
B.GS = GS

----------------------------------------------------------------- walls
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
-- one skin layer; axis "x" = runs along X at z=fixed. sign = side facing the room (for trims). o.rail = handrail height
function B.skin(parent, name, axis, fixed, a, b, y0, y1, thick, color, mat, gaps, sign, o)
	o = o or {}
	local parts = {}
	for _, pc in B.pieces(a, b, y0, y1, gaps) do
		local s, e, ya, yb, isGapPiece = pc[1], pc[2], pc[3], pc[4], pc[5]
		local p
		if axis == "x" then
			p = B.box(parent, name, s, ya, fixed - thick / 2, e, yb, fixed + thick / 2, color, mat, { solid = true })
		else
			p = B.box(parent, name, fixed - thick / 2, ya, s, fixed + thick / 2, yb, e, color, mat, { solid = true })
		end
		table.insert(parts, p)
		if sign and ya <= y0 + 0.01 and not o.nobase then
			local face = fixed + sign * thick / 2
			local th = math.min(if o.wain then 3.4 else 0.6, yb - ya) -- never taller than the piece (low window sills)
			local d = if o.wain then 0.1 else 0.16
			local col = o.trimColor or C.WoodDark
			if axis == "x" then
				B.box(parent, "Trim", s, y0, face, e, y0 + th, face + sign * d, col, if o.wain then M.Wood else M.SmoothPlastic, { small = true })
			else
				B.box(parent, "Trim", face, y0, s, face + sign * d, y0 + th, e, col, if o.wain then M.Wood else M.SmoothPlastic, { small = true })
			end
			if o.rail and not isGapPiece and e - s > 1.2 then -- corridor handrail on brackets
				local ry = y0 + o.rail
				local rc = o.railColor or C.WoodLight
				if axis == "x" then
					B.box(parent, "Handrail", s + 0.4, ry - 0.15, face + sign * 0.3, e - 0.4, ry + 0.15, face + sign * 0.6, rc, M.Wood, { small = true })
				else
					B.box(parent, "Handrail", face + sign * 0.3, ry - 0.15, s + 0.4, face + sign * 0.6, ry + 0.15, e - 0.4, rc, M.Wood, { small = true })
				end
			end
		end
	end
	return parts
end
-- interior wall 0.5 thick; cn = colour on the -side, cp = +side; on/op = per-side opts (mat, rail, wain, nobase, trimColor)
function B.iwall(parent, axis, fixed, a, b, y0, y1, cn, cp, gaps, on, op)
	on = on or {}
	op = op or {}
	B.skin(parent, "Wall", axis, fixed - 0.125, a, b, y0, y1, 0.25, cn, on.mat or M.Plaster, gaps, -1, on)
	B.skin(parent, "Wall", axis, fixed + 0.125, a, b, y0, y1, 0.25, cp, op.mat or M.Plaster, gaps, 1, op)
	for _, g in gaps or {} do
		if (g.sill or 0) == 0 and g.trim ~= false then B.casing(parent, axis, fixed, g.c, g.w, y0, g.h or 8, 0.5, g.casing) end
	end
end
-- door/opening casing: jambs + header, 0.2 proud of the wall faces on both sides. The jamb inner faces sit 0.02 inside the
-- opening and the header 0.02 below the opening top, so no casing face is coplanar with a wall end (no z-fighting).
function B.casing(parent, axis, fixed, c, w, y0, h, wallT, col)
	local t = wallT + 0.4
	col = col or C.WoodLight
	local o = { small = true }
	local a0, a1 = c - w / 2 + 0.02, c + w / 2 - 0.02
	if axis == "x" then
		B.box(parent, "Casing", a0 - 0.37, y0, fixed - t / 2, a0, y0 + h + 0.35, fixed + t / 2, col, M.Wood, o)
		B.box(parent, "Casing", a1, y0, fixed - t / 2, a1 + 0.37, y0 + h + 0.35, fixed + t / 2, col, M.Wood, o)
		B.box(parent, "Casing", a0, y0 + h - 0.02, fixed - t / 2, a1, y0 + h + 0.35, fixed + t / 2, col, M.Wood, o)
	else
		B.box(parent, "Casing", fixed - t / 2, y0, a0 - 0.37, fixed + t / 2, y0 + h + 0.35, a0, col, M.Wood, o)
		B.box(parent, "Casing", fixed - t / 2, y0, a1, fixed + t / 2, y0 + h + 0.35, a1 + 0.37, col, M.Wood, o)
		B.box(parent, "Casing", fixed - t / 2, y0 + h - 0.02, a0, fixed + t / 2, y0 + h + 0.35, a1, col, M.Wood, o)
	end
end
-- glazing inside a wall hole (no curtains): glass + frame
function B.glaze(parent, axis, fixed, c, y0, sill, top, w, wallT, o)
	o = o or {}
	local m = B.model(parent, "Window")
	local yc = y0 + (sill + top) / 2
	local hgt = top - sill
	local fc = o.frame or C.Paper
	local base = if axis == "x" then CFrame.new(c, yc, fixed) else CFrame.new(fixed, yc, c) * CFrame.Angles(0, math.pi / 2, 0)
	-- glass and mullion stop at the inner faces of the frame (no coplanar faces)
	B.rp(m, "Glass", base, V(w - 0.5, hgt - 0.5, 0.1), V(0, 0, 0), C.Glass, M.Glass, { tr = o.tr or 0.55, solid = true, shadow = false })
	B.rp(m, "Mullion", base, V(0.2, hgt - 0.46, wallT + 0.1), V(0, 0, 0), fc, M.SmoothPlastic, { small = true })
	B.rp(m, "Frame", base, V(w, 0.25, wallT + 0.2), V(0, hgt / 2 - 0.125, 0), fc, M.SmoothPlastic, { small = true })
	B.rp(m, "Frame", base, V(w, 0.25, wallT + 0.2), V(0, -hgt / 2 + 0.125, 0), fc, M.SmoothPlastic, { small = true })
	B.rp(m, "Frame", base, V(0.25, hgt - 0.5, wallT + 0.2), V(-w / 2 + 0.125, 0, 0), fc, M.SmoothPlastic, { small = true })
	B.rp(m, "Frame", base, V(0.25, hgt - 0.5, wallT + 0.2), V(w / 2 - 0.125, 0, 0), fc, M.SmoothPlastic, { small = true })
	if o.sill then
		B.rp(m, "Sill", base, V(w + 0.6, 0.2, wallT + 0.4), V(0, -hgt / 2 - 0.08, 0), fc, M.SmoothPlastic, { small = true })
	end
	return m
end
-- partition rectangle minus holes into boxes. holes = { {x0,z0,x1,z1}, ... }
function B.rects(x0, z0, x1, z1, holes)
	local xs, zs = { x0, x1 }, { z0, z1 }
	for _, h in holes or {} do
		for _, x in { h[1], h[3] } do if x > x0 and x < x1 then table.insert(xs, x) end end
		for _, z in { h[2], h[4] } do if z > z0 and z < z1 then table.insert(zs, z) end end
	end
	table.sort(xs)
	table.sort(zs)
	local out = {}
	for j = 1, #zs - 1 do
		local za, zb = zs[j], zs[j + 1]
		if zb - za > 0.001 then
			local run = nil
			for i = 1, #xs - 1 do
				local xa, xb = xs[i], xs[i + 1]
				if xb - xa > 0.001 then
					local cx, cz = (xa + xb) / 2, (za + zb) / 2
					local inHole = false
					for _, h in holes or {} do
						if cx > h[1] and cx < h[3] and cz > h[2] and cz < h[4] then inHole = true break end
					end
					if inHole then
						if run then table.insert(out, run) run = nil end
					elseif run then
						run[3] = xb
					else
						run = { xa, za, xb, zb }
					end
				end
			end
			if run then table.insert(out, run) end
		end
	end
	return out
end
function B.slab(parent, name, x0, z0, x1, z1, y0, y1, col, mat, holes)
	for _, r in B.rects(x0, z0, x1, z1, holes) do
		B.box(parent, name, r[1], y0, r[2], r[3], y1, r[4], col, mat, { solid = true })
	end
end

----------------------------------------------------------------- contract helpers
function B.inv(parent, name, size, cf)
	return B.part(parent, name, size, cf, C.Paper, M.SmoothPlastic, { inv = true })
end
function B.room(name, area, danger, x0, y0, z0, x1, y1, z1)
	local p = B.box(B.F("Rooms"), name, x0, y0, z0, x1, y1, z1, C.Paper, M.SmoothPlastic, { inv = true })
	return B.attrs(p, { RoomName = name, Area = area, Danger = danger })
end
function B.loot(area, danger, pos)
	local p = B.inv(B.F("LootSpawns"), "LootSpawn", V(0.8, 0.4, 0.8), CFrame.new(pos + V(0, 0.35, 0)))
	return B.attrs(p, { Area = area, Danger = danger })
end
function B.prize(area, pos)
	local p = B.inv(B.F("PrizeSpawns"), "PrizeSpawn", V(1.5, 0.4, 1.5), CFrame.new(pos + V(0, 0.35, 0)))
	return B.attrs(p, { Area = area })
end
function B.node(area, x, y, z, bath)
	local p = B.inv(B.F("SearchNodes"), "SearchNode", V(1, 0.2, 1), CFrame.new(x, y + 0.1, z))
	B.attrs(p, { Area = area })
	if bath then p:SetAttribute("Bathroom", true) end
	return p
end
function B.searchable(p, kind, area, danger)
	p.CanQuery = true
	B.tag(p, "Searchable")
	return B.attrs(p, { Kind = kind, Area = area, Danger = danger })
end
-- loose linoleum tile: flush with the floor top (y = floor top)
function B.creak(x, y, z, rot, col)
	local p = B.part(B.F("Creaky"), "LooseTile", V(4, 0.2, 4), CFrame.new(x, y - 0.09, z) * CFrame.Angles(0, math.rad(rot or 0), 0), col or C.Creak, M.SmoothPlastic, { collide = true, touch = true, query = true, shadow = false })
	return B.tag(p, "Creaky")
end
-- Hinged door in a doorway gap (axis/fixed/c like B.pieces). hs = +1 hinge on the low side, -1 on the high side.
-- The pivot (Hinge) sits 0.2 inside the opening on the wall centre line, so the leaf clears the casing and the
-- wall when swung +-90 degrees. The leaf leaves 0.05 at each jamb and 0.07 under the header.
function B.door(parent, name, axis, fixed, c, y0, area, squeaky, lockable, color, hs, w, o)
	o = o or {}
	hs = hs or 1
	w = w or 4.5
	local av = if axis == "x" then Vector3.xAxis else Vector3.zAxis
	local edge = c - hs * w / 2
	local piv = edge + hs * 0.2
	local hinge = if axis == "x" then V(piv, y0, fixed) else V(fixed, y0, piv)
	local base = CFrame.fromMatrix(hinge, av * hs, Vector3.yAxis)
	local m = B.model(parent, name)
	local hp = B.rp(m, "Hinge", base, V(0.2, 8, 0.2), V(0, 4, 0), C.Paper, M.SmoothPlastic, { inv = true })
	local pw = w - 0.1
	local pc = pw / 2 - 0.15
	color = color or C.PMint
	local panel = B.rp(m, "Panel", base, V(pw, 7.9, 0.3), V(pc, 3.98, 0), color, o.mat or M.Wood, { collide = true, query = true })
	local pm = Instance.new("PathfindingModifier")
	pm.PassThrough = true
	pm.Parent = panel
	local dk = color:Lerp(C.Ink, 0.3)
	for _, zz in { -0.17, 0.17 } do
		if o.window then
			B.rp(m, "Vision", base, V(1.1, 2.2, 0.04), V(pc, 5.5, zz), C.Glass, M.Glass, { small = true, tr = 0.3 })
		end
		B.rp(m, "KickPlate", base, V(pw - 0.6, 0.9, 0.04), V(pc, 0.6, zz), C.Chrome, M.Metal, { small = true })
		B.rp(m, "Handle", base, V(0.7, 0.14, 0.12), V(pw - 0.75, 3.6, zz * 1.5), C.Chrome, M.Metal, { small = true })
	end
	if o.label then
		local lp = B.rp(m, "Label", base, V(1.8, 0.45, 0.03), V(pc, 6.9, -0.165), C.Paper, M.SmoothPlastic, { small = true })
		B.text(lp, Enum.NormalId.Front, o.label, C.Ink, Enum.Font.FredokaOne)
		local lp2 = B.rp(m, "Label", base, V(1.8, 0.45, 0.03), V(pc, 6.9, 0.165), C.Paper, M.SmoothPlastic, { small = true })
		B.text(lp2, Enum.NormalId.Back, o.label, C.Ink, Enum.Font.FredokaOne)
	end
	m.PrimaryPart = hp
	B.attrs(m, { Area = area, Squeaky = squeaky, Lockable = lockable })
	B.tag(m, "Door")
	return m
end
function B.hideParts(m, kind, area, insideCF, front, exit)
	B.part(m, "Inside", V(1.6, 2, 1), insideCF, C.Paper, M.SmoothPlastic, { inv = true })
	B.part(m, "Front", V(2, 0.2, 2), CFrame.new(front + V(0, 0.1, 0)), C.Paper, M.SmoothPlastic, { inv = true })
	local ep = exit + V(0, 0.5, 0)
	local look = (exit - insideCF.Position) * V(1, 0, 1)
	if look.Magnitude < 0.1 then look = V(0, 0, -1) end
	B.part(m, "Exit", V(2, 1, 2), CFrame.lookAt(ep, ep + look), C.Paper, M.SmoothPlastic, { inv = true })
	B.attrs(m, { Kind = kind, Area = area })
	B.tag(m, "HidingSpot")
	return m
end
-- lamps. kind: fluoro (base = ceiling underside), table, exit (base on wall, LookVector out), bare, desk
function B.lamp(parent, kind, base, area, o)
	o = o or {}
	local m = B.model(parent, "Lamp_" .. kind)
	local sm = { small = true }
	local bulb
	local l
	if kind == "fluoro" then
		local len = o.len or 4
		B.rp(m, "Housing", base, V(len + 0.4, 0.25, 1.5), V(0, -0.125, 0), C.Paper:Lerp(C.Metal, 0.2), M.Metal, sm)
		bulb = B.rp(m, "Bulb", base, V(len, 0.08, 1.1), V(0, -0.29, 0), o.tint or Color3.fromRGB(236, 244, 236), M.Neon, sm)
		l = Instance.new("SurfaceLight")
		l.Face = Enum.NormalId.Bottom
		l.Angle = 120
		l.Color = o.color or C.Cold
		l.Brightness = o.bright or 1.1
		l.Range = o.range or 18
	elseif kind == "exit" then
		local box = B.rp(m, "Sign", base, V(2.2, 0.8, 0.3), V(0, 0, -0.15), C.Paper, M.SmoothPlastic, sm)
		bulb = B.rp(m, "Bulb", base, V(1.9, 0.55, 0.05), V(0, 0, -0.32), Color3.fromRGB(90, 220, 130), M.Neon, sm)
		B.text(bulb, Enum.NormalId.Front, "EXIT", Color3.fromRGB(240, 255, 240), Enum.Font.GothamBlack, { light = 0 })
		l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(110, 230, 150)
		l.Brightness = 0.6
		l.Range = 8
		local _ = box
	elseif kind == "bare" then
		local drop = o.drop or 1.8
		B.cyl(m, "Cord", base, 0.08, drop, V(0, -drop / 2, 0), C.Ink, M.SmoothPlastic, sm)
		bulb = B.ball(m, "Bulb", base, 0.55, V(0, -drop - 0.3, 0), Color3.fromRGB(255, 214, 160), M.Neon, sm)
		l = Instance.new("PointLight")
		l.Color = o.color or C.Warm
		l.Brightness = o.bright or 1
		l.Range = o.range or 16
	elseif kind == "desk" then
		B.rp(m, "Base", base, V(0.8, 0.15, 0.6), V(0, 0.075, 0), C.PMint:Lerp(C.Ink, 0.2), M.Metal, sm)
		B.rp(m, "Arm", base, V(0.12, 1.4, 0.12), V(0, 0.8, 0.1), C.PMint:Lerp(C.Ink, 0.2), M.Metal, sm)
		B.rp(m, "Head", base, V(0.7, 0.35, 0.9), V(0, 1.55, -0.2), C.PMint:Lerp(C.Ink, 0.2), M.Metal, sm)
		bulb = B.rp(m, "Bulb", base, V(0.5, 0.05, 0.6), V(0, 1.35, -0.25), Color3.fromRGB(255, 214, 160), M.Neon, sm)
		l = Instance.new("SpotLight")
		l.Face = Enum.NormalId.Bottom
		l.Angle = 100
		l.Color = C.Warm
		l.Brightness = 1.2
		l.Range = 12
	else -- table lamp
		B.cyl(m, "Base", base, 0.9, 0.2, V(0, 0.1, 0), C.Brass, M.Metal, sm)
		B.cyl(m, "Stem", base, 0.5, 1.4, V(0, 0.9, 0), o.body or C.PMint, M.Glass, sm)
		B.cyl(m, "Shade", base, 1.8, 1.2, V(0, 2.1, 0), o.shade or C.PPeach, M.Fabric, { small = true, tr = 0.15 })
		bulb = B.ball(m, "Bulb", base, 0.5, V(0, 1.95, 0), Color3.fromRGB(255, 214, 160), M.Neon, sm)
		l = Instance.new("PointLight")
		l.Color = o.color or C.Warm
		l.Brightness = o.bright or 0.9
		l.Range = o.range or 14
	end
	l.Shadows = o.shadows or false
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

----------------------------------------------------------------- stairs / rails
-- straight flight along Z: low end (lowZ,lowY) to high end (highZ,highY); steps filled down to o.floorY
function B.stairs(par, name, x0, x1, lowZ, lowY, highZ, highY, n, col, o)
	o = o or {}
	local m = B.model(par, name)
	local dz = (highZ - lowZ) / n
	local rise = (highY - lowY) / n
	for i = 1, n do
		local za, zb = lowZ + dz * (i - 1), lowZ + dz * i
		local top = lowY + rise * i
		local bottom = (o.floorY or lowY) - 0.1
		B.box(m, "Step", x0, bottom, za, x1, top, zb, col, o.mat or M.Concrete, { collide = true, query = true, shadow = true })
		B.box(m, "Nose", x0, top - 0.12, za - (if dz > 0 then 0.1 else -0.1), x1, top + 0.02, za, o.nose or C.Mustard:Lerp(C.Ink, 0.3), M.Rubber, { small = true })
	end
	local zLow = lowZ - dz
	local zHigh = highZ - dz
	local len = math.abs(zHigh - zLow)
	local ctr = V((x0 + x1) / 2, (lowY + highY) / 2, (zLow + zHigh) / 2)
	local dirLow = V(0, 0, if zLow < zHigh then -1 else 1)
	local w = B.part(m, "Ramp", V(x1 - x0, highY - lowY, len), CFrame.lookAt(ctr, ctr + dirLow), C.Paper, M.SmoothPlastic, { inv = true, collide = true, class = "WedgePart" })
	w.CanQuery = true
	return m
end
function B.rail(par, p0, p1, h, col, spacing)
	local m = B.model(par, "Railing")
	local d = p1 - p0
	local len = d.Magnitude
	local n = math.max(1, math.floor(len / (spacing or 1.6)))
	for i = 0, n do
		local p = p0 + d * (i / n)
		local big = i == 0 or i == n
		B.part(m, if big then "Newel" else "Baluster", if big then V(0.4, h + 0.2, 0.4) else V(0.15, h, 0.15), CFrame.new(p + V(0, (h + (if big then 0.2 else 0)) / 2, 0)), col, M.Metal, { small = true })
	end
	local mid = p0 + d / 2 + V(0, h, 0)
	B.part(m, "Handrail", V(0.3, 0.25, len), CFrame.lookAt(mid, mid + d), C.WoodLight, M.Wood, { small = true })
	B.part(m, "RailCollider", V(0.4, 4.5, len), CFrame.lookAt(p0 + d / 2 + V(0, 2.25, 0), p0 + d / 2 + V(0, 2.25, 0) + d), C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	return m
end
return "lib ok"
