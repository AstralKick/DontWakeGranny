-- HarvestFair builder library (Nights 21-25). Run this chunk first (execute_luau, Edit datamodel).
-- A namespaced, offset-aware copy of tools/house_00_lib + house_01_props helpers, stored in _G.HF so it never
-- clashes with _G.HB or the other map builders. Every builder works in LOCAL coordinates; B.part/B.cutter/B.set
-- add the map offset (X = 6000) so nothing is built near Workspace.House.
-- Build order: 00_lib, 01_props, 02_base, 03_midway, 04_plaza_tent, 05_funhouse, 06_ghosttrain, 07_bigtop,
-- 08_corruption. Checks: 10_validate, 11_pathcheck, audit.
local CS = game:GetService("CollectionService")
local GS = game:GetService("GeometryService")
local B = {}
_G.HF = B
B.CS = CS
local M = Enum.Material
B.M = M
B.OX = 6000
B.OFF = CFrame.new(B.OX, 0, 0)
local V = Vector3.new
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
B.C = {
	Ink = Color3.fromHex("2A1A24"), Night = Color3.fromHex("3B2A3F"), Paper = Color3.fromHex("F3E9D2"),
	Rose = Color3.fromHex("D97A8A"), Mint = Color3.fromHex("9CC5A1"), Mustard = Color3.fromHex("E0B04F"),
	Bruise = Color3.fromHex("7B5C8E"), Blood = Color3.fromHex("A8323E"),
	WoodDark = rgb(58, 38, 32), WoodMid = rgb(98, 68, 50), WoodLight = rgb(136, 100, 72), WoodRaw = rgb(120, 96, 72),
	Creak = rgb(132, 98, 70), Concrete = rgb(88, 86, 90), Stone = rgb(80, 74, 76),
	Grass = rgb(52, 64, 46), Dirt = rgb(62, 50, 42), Mud = rgb(70, 54, 42), Hay = rgb(196, 160, 92),
	Metal = rgb(86, 86, 92), Brass = rgb(176, 140, 72), Glass = rgb(110, 132, 168), Sheet = rgb(222, 216, 200),
	Warm = rgb(255, 184, 120), Cold = rgb(150, 170, 220),
	-- fair fabrics (faded circus stripes)
	Red = rgb(150, 52, 58), Cream = rgb(214, 198, 168), Teal = rgb(70, 112, 110), Plum = rgb(96, 60, 96),
	Velvet = rgb(110, 30, 56), Pumpkin = rgb(196, 104, 40), Gold = rgb(200, 158, 70),
}
local C = B.C

function B.root()
	return workspace:FindFirstChild("Maps") and workspace.Maps:FindFirstChild("HarvestFair")
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
-- local -> world
function B.W(v) return v + V(B.OX, 0, 0) end
function B.set(p, cf) p.CFrame = B.OFF * cf return p end

-- o: solid (structure: collide+query), small (clutter: no collide, no shadow), inv (invisible helper),
--    collide, query, touch, shadow, tr, shape, class, refl
function B.part(parent, name, size, cf, color, mat, o)
	o = o or {}
	local p = Instance.new(o.class or "Part")
	if o.shape then p.Shape = o.shape end
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = B.OFF * cf
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
	p.CFrame = B.OFF * cf
	if shape then p.Shape = shape end
	return p
end
-- SurfaceGui sign text on a part face
function B.text(p, txt, o)
	o = o or {}
	local g = Instance.new("SurfaceGui")
	g.Face = o.face or Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = o.pps or 40
	g.LightInfluence = o.light or 0.6
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = txt
	t.TextScaled = true
	t.FontFace = Font.fromEnum(o.font or Enum.Font.LuckiestGuy)
	t.TextColor3 = o.color or C.Paper
	t.Rotation = o.rot or 0
	local s = Instance.new("UIStroke")
	s.Color = o.stroke or C.Ink
	s.Thickness = o.strokeT or 3
	s.Parent = t
	t.Parent = g
	return g
end

----------------------------------------------------------------- walls
function B.pieces(a, b, y0, y1, gaps)
	local list = {}
	gaps = table.clone(gaps or {})
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
-- plain wall. axis "x" = runs along X at z=fixed; "z" = runs along Z at x=fixed
function B.wall(parent, name, axis, fixed, a, b, y0, y1, t, color, mat, gaps, o)
	o = o or { solid = true }
	local out = {}
	for _, pc in B.pieces(a, b, y0, y1, gaps) do
		local s, e, ya, yb = pc[1], pc[2], pc[3], pc[4]
		if axis == "x" then
			table.insert(out, B.box(parent, name, s, ya, fixed - t / 2, e, yb, fixed + t / 2, color, mat, o))
		else
			table.insert(out, B.box(parent, name, fixed - t / 2, ya, s, fixed + t / 2, yb, e, color, mat, o))
		end
	end
	return out
end
-- vertical stripes (tent canvas / painted boards). stripes align to a global grid of width sw
function B.stripes(parent, name, axis, fixed, a, b, y0, y1, t, c1, c2, sw, gaps, mat)
	mat = mat or M.Fabric
	for _, pc in B.pieces(a, b, y0, y1, gaps) do
		local s, e, ya, yb = pc[1], pc[2], pc[3], pc[4]
		local x = s
		while x < e - 0.01 do
			local idx = math.floor((x + 0.001) / sw)
			local nx = math.min(e, (idx + 1) * sw)
			local col = if idx % 2 == 0 then c1 else c2
			if axis == "x" then
				B.box(parent, name, x, ya, fixed - t / 2, nx, yb, fixed + t / 2, col, mat, { solid = true })
			else
				B.box(parent, name, fixed - t / 2, ya, x, fixed + t / 2, yb, nx, col, mat, { solid = true })
			end
			x = nx
		end
	end
end
-- door frame inside a wall gap of width 5.2 / height 8.45 (use B.DG as the gap spec). jambs + header span the wall
B.DW, B.DH = 5.2, 8.45
function B.DG(c) return { c = c, w = 5.2, h = 8.45 } end
function B.doorway(parent, axis, fixed, c, y0, wallT, col)
	col = col or C.WoodDark
	local d = wallT + 0.3
	local o = { small = true, collide = true }
	if axis == "x" then
		B.box(parent, "Jamb", c - 2.6, y0, fixed - d / 2, c - 2.25, y0 + 8, fixed + d / 2, col, M.Wood, o)
		B.box(parent, "Jamb", c + 2.25, y0, fixed - d / 2, c + 2.6, y0 + 8, fixed + d / 2, col, M.Wood, o)
		B.box(parent, "Header", c - 2.6, y0 + 8, fixed - d / 2, c + 2.6, y0 + 8.45, fixed + d / 2, col, M.Wood, o)
	else
		B.box(parent, "Jamb", fixed - d / 2, y0, c - 2.6, fixed + d / 2, y0 + 8, c - 2.25, col, M.Wood, o)
		B.box(parent, "Jamb", fixed - d / 2, y0, c + 2.25, fixed + d / 2, y0 + 8, c + 2.6, col, M.Wood, o)
		B.box(parent, "Header", fixed - d / 2, y0 + 8, c - 2.6, fixed + d / 2, y0 + 8.45, c + 2.6, col, M.Wood, o)
	end
end

----------------------------------------------------------------- ramps
-- visible wedge ramp (walkable). from low point to high point along an axis. w = width across.
-- axis "x": runs along X (lowX -> highX) centred at z; "z": along Z centred at x.
function B.ramp(parent, name, axis, lowA, highA, cross, w, lowY, highY, col, mat)
	local len = math.abs(highA - lowA)
	local mid = (lowA + highA) / 2
	local ctr = if axis == "x" then V(mid, (lowY + highY) / 2, cross) else V(cross, (lowY + highY) / 2, mid)
	local dir = if axis == "x" then V(if lowA < highA then -1 else 1, 0, 0) else V(0, 0, if lowA < highA then -1 else 1)
	-- WedgePart: slope rises toward -Z local... Roblox wedge: high at back (+Z), low at front (-Z). LookVector = -Z = low side.
	local p = B.part(parent, name, V(w, highY - lowY, len), CFrame.lookAt(ctr, ctr + dir), col or C.WoodMid, mat or M.WoodPlanks, { solid = true, class = "WedgePart" })
	return p
end
-- railing: posts + handrail from p0 to p1 (floor-level points), with an invisible collider
function B.rail(par, p0, p1, h, col, spacing)
	local m = B.model(par, "Railing")
	local d = p1 - p0
	local len = d.Magnitude
	local n = math.max(1, math.floor(len / (spacing or 2.5)))
	for i = 0, n do
		local p = p0 + d * (i / n)
		B.part(m, "Post", V(0.3, h, 0.3), CFrame.new(p + V(0, h / 2, 0)), col, M.Wood, { small = true })
	end
	local mid = p0 + d / 2 + V(0, h, 0)
	B.part(m, "Handrail", V(0.35, 0.3, len + 0.4), CFrame.lookAt(mid, mid + d), col, M.Wood, { small = true })
	local mid2 = p0 + d / 2 + V(0, h * 0.5, 0)
	B.part(m, "MidRail", V(0.2, 0.2, len), CFrame.lookAt(mid2, mid2 + d), col, M.Wood, { small = true })
	B.part(m, "RailCollider", V(0.4, 5, len), CFrame.lookAt(p0 + d / 2 + V(0, 2.5, 0), p0 + d / 2 + V(0, 2.5, 0) + d), C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	return m
end

----------------------------------------------------------------- contract helpers
function B.inv(parent, name, size, cf)
	return B.part(parent, name, size, cf, C.Paper, M.SmoothPlastic, { inv = true })
end
function B.room(name, area, danger, x0, y0, z0, x1, y1, z1)
	local p = B.mark(B.box(B.F("Rooms"), name, x0, y0, z0, x1, y1, z1, C.Paper, M.SmoothPlastic, { inv = true }))
	return B.attrs(p, { RoomName = name, Area = area, Danger = danger })
end
function B.loot(area, danger, pos)
	local p = B.mark(B.inv(B.F("LootSpawns"), "LootSpawn", V(0.8, 0.4, 0.8), CFrame.new(pos + V(0, 0.35, 0))))
	return B.attrs(p, { Area = area, Danger = danger })
end
function B.prize(area, pos)
	local p = B.mark(B.inv(B.F("PrizeSpawns"), "PrizeSpawn", V(1.5, 0.4, 1.5), CFrame.new(pos + V(0, 0.35, 0))))
	return B.attrs(p, { Area = area })
end
function B.node(area, x, y, z, bath)
	local p = B.mark(B.inv(B.F("SearchNodes"), "SearchNode", V(1, 0.2, 1), CFrame.new(x, y + 0.1, z)))
	B.attrs(p, { Area = area })
	if bath then p:SetAttribute("Bathroom", true) end
	return p
end
function B.searchable(p, kind, area, danger)
	p.CanQuery = true
	B.tag(p, "Searchable")
	return B.attrs(p, { Kind = kind, Area = area, Danger = danger })
end
-- creaky boardwalk plank patch (top flush at y)
function B.creak(x, y, z, rot)
	local p = B.part(B.F("Creaky"), "CreakyBoard", V(4, 0.2, 4), CFrame.new(x, y - 0.08, z) * CFrame.Angles(0, math.rad(rot or 0), 0), C.Creak, M.WoodPlanks, { collide = true, touch = true, query = true, shadow = false })
	B.mark(p)
	return B.tag(p, "Creaky")
end
-- hinged door inside a B.doorway frame. The hinge sits 0.16 inside the jamb so the leaf clears the frame at +-90.
-- axis/fixed/c describe the gap; hs = +1 hinge on the low side, -1 on the high side.
function B.door(parent, name, axis, fixed, c, y0, area, squeaky, lockable, color, hs)
	hs = hs or 1
	local L = 4.5 - 0.16 - 0.05
	local hx = c - hs * (2.25 - 0.16)
	local right = if axis == "x" then Vector3.xAxis else Vector3.zAxis
	local hinge = if axis == "x" then V(hx, y0, fixed) else V(fixed, y0, hx)
	local base = CFrame.fromMatrix(hinge, right * hs, Vector3.yAxis)
	local m = B.model(parent, name)
	local hp = B.rp(m, "Hinge", base, V(0.2, 8, 0.2), V(0, 4, 0), C.Paper, M.SmoothPlastic, { inv = true })
	local col = color or C.WoodMid
	local panel = B.rp(m, "Panel", base, V(L, 7.9, 0.3), V(L / 2, 0.03 + 3.95, 0), col, M.Wood, { collide = true, query = true })
	local pm = Instance.new("PathfindingModifier")
	pm.PassThrough = true
	pm.Parent = panel
	local dk = col:Lerp(C.Ink, 0.3)
	for _, zz in { -0.17, 0.17 } do
		B.rp(m, "Inset", base, V(L - 1.3, 2.9, 0.04), V(L / 2, 5.6, zz), dk, M.Wood, { small = true })
		B.rp(m, "Inset", base, V(L - 1.3, 3.2, 0.04), V(L / 2, 1.9, zz), dk, M.Wood, { small = true })
		B.ball(m, "Knob", base, 0.32, V(L - 0.45, 3.6, zz * 1.6), C.Brass, M.Metal, { small = true })
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
-- lamp. kind: bare, hang, lantern, post, candle, flood, sconce. base = CFrame (local)
function B.lamp(parent, kind, base, area, o)
	o = o or {}
	local m = B.model(parent, "Lamp_" .. kind)
	local sm = { small = true }
	local bulbPos
	if kind == "bare" then
		local drop = o.drop or 1.8
		B.cyl(m, "Cord", base, 0.08, drop, V(0, -drop / 2, 0), C.Ink, M.SmoothPlastic, sm)
		bulbPos = V(0, -drop - 0.3, 0)
	elseif kind == "hang" then
		B.cyl(m, "Cord", base, 0.1, 2.2, V(0, -1.1, 0), C.Ink, M.SmoothPlastic, sm)
		B.cyl(m, "Shade", base, 2.2, 0.9, V(0, -2.5, 0), o.shade or C.Mint, M.Metal, sm)
		bulbPos = V(0, -2.9, 0)
	elseif kind == "lantern" then -- base = hook point; lantern hangs below
		B.rp(m, "Cap", base, V(0.9, 0.25, 0.9), V(0, -0.5, 0), C.Ink, M.Metal, sm)
		B.rp(m, "Cage", base, V(0.8, 1.2, 0.8), V(0, -1.2, 0), C.Ink, M.Glass, { small = true, tr = 0.65 })
		B.rp(m, "Foot", base, V(0.9, 0.2, 0.9), V(0, -1.9, 0), C.Ink, M.Metal, sm)
		bulbPos = V(0, -1.2, 0)
	elseif kind == "post" then -- base on the ground
		B.rp(m, "Pole", base, V(0.5, 10, 0.5), V(0, 5, 0), C.Ink, M.Metal, { solid = true })
		B.rp(m, "Arm", base, V(0.25, 0.25, 2), V(0, 9.8, -0.9), C.Ink, M.Metal, sm)
		B.rp(m, "Cap", base, V(1, 0.3, 1), V(0, 9.4, -1.7), C.Ink, M.Metal, sm)
		B.rp(m, "Cage", base, V(0.8, 1.2, 0.8), V(0, 8.65, -1.7), C.Ink, M.Glass, { small = true, tr = 0.65 })
		bulbPos = V(0, 8.65, -1.7)
	elseif kind == "flood" then -- work light on a stand
		B.rp(m, "Stand", base, V(0.3, 5, 0.3), V(0, 2.5, 0), C.Mustard:Lerp(C.Ink, 0.4), M.Metal, sm)
		B.rp(m, "Head", base, V(1.4, 1, 0.6), V(0, 5.3, 0), C.Mustard:Lerp(C.Ink, 0.3), M.Metal, sm)
		bulbPos = V(0, 5.3, -0.3)
	elseif kind == "sconce" then
		B.rp(m, "Plate", base, V(0.5, 0.9, 0.1), V(0, 0, -0.05), C.Brass, M.Metal, sm)
		B.rp(m, "Arm", base, V(0.12, 0.12, 0.6), V(0, 0, -0.35), C.Brass, M.Metal, sm)
		bulbPos = V(0, 0.2, -0.65)
	elseif kind == "candle" then
		B.cyl(m, "Wax", base, 0.3, o.h or 0.8, V(0, (o.h or 0.8) / 2, 0), C.Paper, M.SmoothPlastic, sm)
		bulbPos = V(0, (o.h or 0.8) + 0.15, 0)
	end
	local bsz = if kind == "candle" then 0.18 elseif kind == "sconce" then 0.35 elseif kind == "flood" then 0.3 else 0.5
	local bulb
	if kind == "flood" then
		bulb = B.rp(m, "Bulb", base, V(1.1, 0.7, 0.1), bulbPos, Color3.fromRGB(255, 236, 200), M.Neon, sm)
	else
		bulb = B.ball(m, "Bulb", base, bsz, bulbPos, o.bulb or (if kind == "candle" then Color3.fromRGB(255, 170, 80) else Color3.fromRGB(255, 214, 160)), M.Neon, sm)
	end
	local l = Instance.new(o.spot and "SpotLight" or "PointLight")
	l.Color = o.color or C.Warm
	l.Brightness = o.bright or 1
	l.Range = o.range or 16
	l.Shadows = o.shadows or false
	if o.spot then
		l.Face = o.face or Enum.NormalId.Bottom
		l.Angle = o.angle or 110
	end
	l.Parent = bulb
	m.PrimaryPart = bulb
	B.attrs(m, { Area = area })
	B.tag(m, "Lamp")
	return m
end
-- string of festoon bulbs between two points (local), sagging. lampArea -> tagged Lamp with one PointLight
-- dead = every n-th bulb dead (grey glass). Returns model.
local BULBC = { Color3.fromRGB(255, 214, 150), Color3.fromRGB(255, 170, 120), Color3.fromRGB(250, 226, 170), Color3.fromRGB(255, 150, 150) }
function B.festoon(parent, p0, p1, sag, n, lampArea, o)
	o = o or {}
	local m = B.model(parent, if lampArea then "Lamp_Festoon" else "Festoon")
	local pts = {}
	local segs = o.segs or 4
	for i = 0, segs do
		local t = i / segs
		table.insert(pts, p0:Lerp(p1, t) - V(0, sag * 4 * t * (1 - t), 0))
	end
	for i = 1, segs do
		local a, b = pts[i], pts[i + 1]
		B.part(m, "Cable", V(0.08, 0.08, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), C.Ink, M.SmoothPlastic, { small = true, collide = false })
	end
	local mid = nil
	local seed = o.seed or 0
	for i = 1, n do
		local t = i / (n + 1)
		local fs = t * segs
		local si = math.clamp(math.floor(fs) + 1, 1, segs)
		local p = pts[si]:Lerp(pts[si + 1], fs - (si - 1)) - V(0, 0.18, 0)
		local dead = ((i + seed) % (o.deadEvery or 3)) == 0
		local name = if dead then "DeadBulb" else (if lampArea then "Bulb" else "LitBulb")
		local b = B.part(m, name, V(0.35, 0.45, 0.35), CFrame.new(p), if dead then Color3.fromRGB(70, 66, 60) else BULBC[(i + seed) % #BULBC + 1], if dead then M.Glass else M.Neon, { small = true, collide = false, shape = Enum.PartType.Ball })
		if not dead and (mid == nil or math.abs(t - 0.5) < math.abs(mid[2] - 0.5)) then mid = { b, t } end
	end
	if lampArea and mid then
		local l = Instance.new("PointLight")
		l.Color = o.color or Color3.fromRGB(255, 190, 130)
		l.Brightness = o.bright or 0.9
		l.Range = o.range or 18
		l.Parent = mid[1]
		m.PrimaryPart = mid[1]
		B.attrs(m, { Area = lampArea })
		B.tag(m, "Lamp")
	end
	return m
end
function B.count(folder)
	local n = 0
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then n += 1 end
	end
	return n
end
-- Sections: every builder file calls B.begin("<sec>"), which deletes that section's folder
-- (Sections/<sec>) and every contract item it created elsewhere (marked with attribute Sec), so any file
-- can be re-run on its own.
function B.mark(inst)
	if B.SEC then inst:SetAttribute("Sec", B.SEC) end
	return inst
end
function B.begin(sec)
	B.SEC = sec
	local root = B.root()
	local secs = B.F("Sections")
	local old = secs:FindFirstChild(sec)
	if old then old:Destroy() end
	for _, d in root:GetDescendants() do
		if d.Parent and d:GetAttribute("Sec") == sec then d:Destroy() end
	end
	local f = Instance.new("Folder")
	f.Name = sec
	f.Parent = secs
	return f
end
function B.barrier(name, area)
	local m = B.model(B.F("Barriers"), name)
	B.attrs(m, { Area = area })
	return B.mark(m)
end
return "HF lib ok"
