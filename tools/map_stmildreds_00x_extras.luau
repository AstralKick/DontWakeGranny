----------------------------------------------------------------- St Mildred's extras (appended to the lib by map_stmildreds_00_lib.luau)
-- Everything is built in LOCAL map coordinates; B.part adds B.O (the map's world offset).
local V = Vector3.new
local C, M = B.C, B.M
C.StoneW = Color3.fromRGB(108, 102, 100) -- rubble wall stone
C.StoneD = Color3.fromRGB(146, 138, 124) -- dressed limestone (jambs, copings)
C.Flag = Color3.fromRGB(76, 72, 76) -- floor flags
C.Moss = Color3.fromRGB(62, 76, 50)
C.Yew = Color3.fromRGB(32, 50, 38)
C.Iron = Color3.fromRGB(44, 42, 48)
C.Oak = Color3.fromRGB(82, 56, 40)
C.Pew = Color3.fromRGB(70, 46, 34)
C.Wax = Color3.fromRGB(236, 224, 196)
C.FlameC = Color3.fromRGB(255, 170, 80)
C.Velvet = Color3.fromRGB(112, 42, 54)
C.Slate = Color3.fromRGB(52, 50, 60)
C.Grave = Color3.fromRGB(124, 122, 118)
C.Lily = Color3.fromRGB(236, 232, 214)
B.SM = { small = true }

function B.W(p) return p + B.O end

-- room lookup from the Rooms folder (world boxes). pos is LOCAL.
function B.at(pos)
	local wp = pos + B.O
	for _, r in B.F("Rooms"):GetChildren() do
		local rel = r.CFrame:PointToObjectSpace(wp)
		local h = r.Size / 2
		if math.abs(rel.X) <= h.X + 0.05 and math.abs(rel.Y) <= h.Y + 0.6 and math.abs(rel.Z) <= h.Z + 0.05 then return r end
	end
	return nil
end
function B.A(pos)
	local r = B.at(pos)
	if not r then
		warn("SMB: no room at " .. tostring(pos))
		return "Ground", 1
	end
	return r:GetAttribute("Area"), r:GetAttribute("Danger")
end
function B.L(pos)
	local a, d = B.A(pos + V(0, 0.4, 0))
	return B.loot(a, d, pos)
end
function B.PZ(pos)
	local a = B.A(pos + V(0, 0.4, 0))
	return B.prize(a, pos)
end
function B.N(x, y, z, bath)
	local a = B.A(V(x, y + 0.5, z))
	return B.node(a, x, y, z, bath)
end
function B.S(p, kind)
	local a, d = B.A(p.Position - B.O)
	return B.searchable(p, kind, a, d)
end
function B.HP(m, kind, insideCF, front, exit)
	local a = B.A(front + V(0, 0.5, 0))
	return B.hideParts(m, kind, a, insideCF, front, exit)
end
function B.LP(parent, kind, base, o)
	local a = B.A(base.Position + V(0, 0.3, 0))
	return B.lamp(parent, kind, base, a, o)
end

-- solid wall slab: axis "x" runs along X (thickness f0..f1 in Z), "z" runs along Z (thickness in X).
-- gaps use B.pieces semantics: { c, w, h (top rel y0), sill (rel y0) }
function B.wall(par, name, axis, f0, f1, a, b, y0, y1, gaps, col, mat)
	local out = {}
	local g2 = {}
	for _, g in gaps or {} do table.insert(g2, table.clone(g)) end
	for _, pc in B.pieces(a, b, y0, y1, g2) do
		local s, e, ya, yb = pc[1], pc[2], pc[3], pc[4]
		local p
		if axis == "x" then
			p = B.box(par, name, s, ya, f0, e, yb, f1, col or C.StoneW, mat or M.Cobblestone, { solid = true })
		else
			p = B.box(par, name, f0, ya, s, f1, yb, e, col or C.StoneW, mat or M.Cobblestone, { solid = true })
		end
		table.insert(out, p)
	end
	return out
end
-- door hole spec: clear 4.5 x 8 plus room for a 0.35 frame; fy = floor height relative to the wall's y0
function B.dgap(c, fy) return { c = c, w = 5.2, h = (fy or 0) + 8.35, sill = fy or 0 } end
-- door frame (jambs + header) INSIDE a B.dgap hole. fy = absolute floor Y. T = wall thickness. fixed = wall centre line.
function B.frame(par, axis, fixed, c, fy, T, col, o)
	o = o or {}
	col = col or C.StoneD
	local mat = o.mat or M.Limestone
	local d = (T + 0.3) / 2
	local ch = o.ch or 8
	local sm = { solid = true }
	if axis == "x" then
		B.box(par, "Jamb", c - 2.6, fy, fixed - d, c - 2.25, fy + ch, fixed + d, col, mat, sm)
		B.box(par, "Jamb", c + 2.25, fy, fixed - d, c + 2.6, fy + ch, fixed + d, col, mat, sm)
		B.box(par, "Header", c - 2.6, fy + ch, fixed - d, c + 2.6, fy + ch + 0.35, fixed + d, col, mat, sm)
	else
		B.box(par, "Jamb", fixed - d, fy, c - 2.6, fixed + d, fy + ch, c - 2.25, col, mat, sm)
		B.box(par, "Jamb", fixed - d, fy, c + 2.25, fixed + d, fy + ch, c + 2.6, col, mat, sm)
		B.box(par, "Header", fixed - d, fy + ch, c - 2.6, fixed + d, fy + ch + 0.35, c + 2.6, col, mat, sm)
	end
	-- round hood mould above the door on both faces (decor, sits above the header)
	if o.hood then
		for _, sgn in { -1, 1 } do
			local face = fixed + sgn * (T / 2 + 0.12)
			local base = if axis == "x" then CFrame.new(c, fy, face) else CFrame.new(face, fy, c) * CFrame.Angles(0, math.rad(90), 0)
			for i = 0, 6 do
				local a = math.rad(i * 30)
				local t = if i % 2 == 0 then 0.24 else 0.3 -- alternate depth so overlapping bar ends never share a front plane
				local inset = if i % 2 == 0 then 0.02 else 0.04 -- ...nor a back plane (backs sink slightly into the wall)
				local cf = base * CFrame.new(math.cos(a) * 2.9, 8.9 + math.sin(a) * 0.85, sgn * (t / 2 - 0.12 - inset)) * CFrame.Angles(0, 0, math.atan2(math.cos(a) * 0.85, -math.sin(a) * 2.9))
				B.part(par, "Hood", V(1.0, 0.4, t), cf, col, mat, { small = true })
			end
		end
	end
end
-- hinged door for a B.dgap hole. hs = +1: hinge on the low side of c. Panel clears the frame by 0.17 (hinge) / 0.06 (latch) / 0.05 (top).
function B.door2(parent, name, axis, fixed, c, fy, squeaky, lockable, col, hs, o)
	o = o or {}
	hs = hs or 1
	local w = 4.5
	local W = w - 0.23
	local along = if axis == "x" then Vector3.xAxis else Vector3.zAxis
	local ax = c - hs * (w / 2 - 0.17)
	local ch = o.ch or 8
	local hpos = if axis == "x" then V(ax, fy + ch / 2, fixed) else V(fixed, fy + ch / 2, ax)
	local base = CFrame.fromMatrix(hpos, along * hs, Vector3.yAxis)
	local m = B.model(parent, name)
	local hp = B.part(m, "Hinge", V(0.2, ch - 0.1, 0.2), base, C.Paper, M.SmoothPlastic, { inv = true })
	col = col or C.Oak
	local panel = B.rp(m, "Panel", base, V(W, ch - 0.1, 0.3), V(W / 2, 0, 0), col, o.mat or M.WoodPlanks, { collide = true, query = true })
	local pm = Instance.new("PathfindingModifier")
	pm.PassThrough = true
	pm.Parent = panel
	local iron = C.Iron
	for _, zz in { -0.175, 0.175 } do
		for _, yy in { -ch * 0.3, ch * 0.3 } do
			B.rp(m, "Strap", base, V(W - 0.5, 0.3, 0.05), V(W / 2 - 0.1, yy, zz), iron, M.Metal, B.SM)
		end
		B.cyl(m, "Ring", base, 0.45, 0.08, V(W - 0.5, 0.2, zz * 1.55), iron, M.Metal, B.SM, false).CFrame = CFrame.new(B.O) * base * CFrame.new(W - 0.5, 0.2, zz * 1.55) * CFrame.Angles(0, math.rad(90), 0)
	end
	m.PrimaryPart = hp
	local nrm = if axis == "x" then Vector3.zAxis else Vector3.xAxis
	local p0 = hpos - V(0, ch / 2 - 0.5, 0) + along * hs * 2
	local area = o.area or ((B.at(p0 + nrm * 1.6) or B.at(p0 - nrm * 1.6) or { GetAttribute = function() return "Ground" end }):GetAttribute("Area"))
	B.attrs(m, { Area = area, Squeaky = squeaky, Lockable = lockable })
	B.tag(m, "Door")
	return m
end

-- round-headed (Norman) window in a rectangular wall hole (c +- w/2, ys..yt absolute).
-- Builds: stone infill with the arch cut (CSG), glass (CSG union), a lead came, sill.
function B.lancet(par, axis, f0, f1, c, ys, yt, w, glassCol, o)
	o = o or {}
	local m = B.model(par, "Window")
	local T = f1 - f0
	local fc = (f0 + f1) / 2
	local spring = yt - w / 2
	local function bx(x0, y0, x1, y1, t0, t1, name, col, mat, opt)
		if axis == "x" then return B.box(m, name, x0, y0, t0, x1, y1, t1, col, mat, opt) end
		return B.box(m, name, t0, y0, x0, t1, y1, x1, col, mat, opt)
	end
	local inf = bx(c - w / 2, spring, c + w / 2, yt, f0, f1, "ArchInfill", o.stone or C.StoneW, o.stoneMat or M.Cobblestone, { solid = true })
	local cylCF = if axis == "x" then CFrame.new(c, spring, fc) * CFrame.Angles(0, math.rad(90), 0) else CFrame.new(fc, spring, c)
	local cut = B.cutter(V(T + 1, w, w), cylCF, Enum.PartType.Cylinder)
	B.csg("sub", inf, { cut })
	-- glass: rectangle up to the spring + a disc (union)
	local gt0, gt1 = fc - 0.1, fc + 0.1
	local g = bx(c - w / 2 + 0.02, ys, c + w / 2 - 0.02, spring, gt0, gt1, "Glass", glassCol or C.Glass, M.Glass, { solid = true, shadow = false })
	local gcf = if axis == "x" then CFrame.new(c, spring, fc) * CFrame.Angles(0, math.rad(90), 0) else CFrame.new(fc, spring, c)
	local disc = B.part(m, "GlassTop", V(0.2, w - 0.04, w - 0.04), gcf, glassCol or C.Glass, M.Glass, { solid = true, shape = Enum.PartType.Cylinder })
	local u = B.csg("union", g, { disc }, { fid = Enum.CollisionFidelity.Box })
	u.Transparency = o.tr or 0.35
	u.CastShadow = false
	-- lead cames (thin dark bars, proud of the glass on both faces)
	for _, s in { -1, 1 } do
		local t = fc + s * 0.13
		bx(c - 0.06, ys, c + 0.06, yt - 0.1, t - 0.03, t + 0.03, "Came", C.Iron, M.Metal, B.SM)
		bx(c - w / 2 + 0.05, (ys + spring) / 2 - 0.05, c + w / 2 - 0.05, (ys + spring) / 2 + 0.05, t - 0.05, t + 0.05, "Came", C.Iron, M.Metal, B.SM)
	end
	-- stone sills protruding on both faces
	bx(c - w / 2 - 0.3, ys - 0.35, c + w / 2 + 0.3, ys, f0 - 0.35, f0, "Sill", C.StoneD, M.Limestone, B.SM)
	bx(c - w / 2 - 0.3, ys - 0.35, c + w / 2 + 0.3, ys, f1, f1 + 0.35, "Sill", C.StoneD, M.Limestone, B.SM)
	return m
end
-- window gap for B.wall (absolute ys/yt given the wall base y0)
function B.wgap(c, w, ys, yt, y0) return { c = c, w = w, sill = ys - y0, h = yt - y0 } end

-- straight flight of visible steps + invisible collidable wedge ramp. axis "z": runs along Z, cross range c0..c1 in X.
function B.flight(par, name, axis, c0, c1, lowS, lowY, highS, highY, n, col, mat, floorY)
	local m = B.model(par, name)
	local ds = (highS - lowS) / n
	local rise = (highY - lowY) / n
	floorY = floorY or lowY
	for i = 1, n do
		local sa, sb = lowS + ds * (i - 1), lowS + ds * i
		local top = lowY + rise * i
		if axis == "z" then
			B.box(m, "Step", c0, floorY, sa, c1, top, sb, col, mat, { solid = true })
		else
			B.box(m, "Step", sa, floorY, c0, sb, top, c1, col, mat, { solid = true })
		end
	end
	local sLow, sHigh = lowS - ds, highS - ds
	local len = math.abs(sHigh - sLow)
	local mid = (sLow + sHigh) / 2
	local sg = if sLow < sHigh then -1 else 1
	local ctr, dirLow
	if axis == "z" then
		ctr = V((c0 + c1) / 2, (lowY + highY) / 2, mid)
		dirLow = V(0, 0, sg)
	else
		ctr = V(mid, (lowY + highY) / 2, (c0 + c1) / 2)
		dirLow = V(sg, 0, 0)
	end
	local wdg = B.part(m, "Ramp", V(math.abs(c1 - c0), highY - lowY, len), CFrame.lookAt(ctr, ctr + dirLow), C.Paper, M.SmoothPlastic, { inv = true, collide = true, class = "WedgePart" })
	wdg.CanQuery = true
	return m
end

-- railing (from house_04): posts + handrail from p0 to p1 (floor-level points), with an invisible collider
function B.rail(par, p0, p1, h, col, spacing)
	local m = B.model(par, "Railing")
	local d = p1 - p0
	local len = d.Magnitude
	local n = math.max(1, math.floor(len / (spacing or 1.3)))
	for i = 0, n do
		local p = p0 + d * (i / n)
		local newel = i == 0 or i == n
		B.part(m, if newel then "Newel" else "Baluster", if newel then V(0.5, h + 0.3, 0.5) else V(0.18, h, 0.18), CFrame.new(p + V(0, (h + (if newel then 0.3 else 0)) / 2, 0)), col, M.Wood, { small = true })
	end
	local mid = p0 + d / 2 + V(0, h, 0)
	B.part(m, "Handrail", V(0.35, 0.3, len), CFrame.lookAt(mid, mid + d), col, M.Wood, { small = true })
	B.part(m, "RailCollider", V(0.4, 4.5, len), CFrame.lookAt(p0 + d / 2 + V(0, 2.25, 0), p0 + d / 2 + V(0, 2.25, 0) + d), C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	return m
end

-- wardrobe/closet/cabinet (overrides the house version): no coplanar faces between sides/back/top/plinth/leaves.
function B.wardrobe(par, b, col, area, kind, o)
	o = o or {}
	local R = function(n, sz, off, c, mat, opt) return B.rp(par, n, b, sz, off, c, mat, opt) end
	local m = B.model(par, o.name or kind)
	R = function(n, sz, off, c, mat, opt) return B.rp(m, n, b, sz, off, c, mat, opt) end
	local w, d, h = o.w or 5.2, 3.8, o.h or 8.8
	local dk = col:Lerp(C.Ink, 0.35)
	R("Plinth", V(w, 0.5, d), V(0, 0.25, 0), dk, M.Wood, { solid = true })
	R("Top", V(w, 0.4, d), V(0, h - 0.2, 0), col, M.Wood, { solid = true })
	for _, sx in { -1, 1 } do
		R("Side", V(0.3, h - 0.9, d), V(sx * (w / 2 - 0.15), 0.5 + (h - 0.9) / 2, 0), col, M.Wood, { solid = true })
	end
	R("Back", V(w - 0.6, h - 0.9, 0.3), V(0, 0.5 + (h - 0.9) / 2, d / 2 - 0.15), col, M.Wood, { solid = true })
	R("Crown", V(w + 0.5, 0.45, d + 0.3), V(0, h + 0.2, -0.17), dk, M.Wood, B.SM)
	local dc = o.doorColor or col
	local inner = w - 0.6
	local lw = inner / 2
	for _, sx in { -1, 1 } do
		local cx = sx * lw / 2
		R("DoorLeaf", V(lw - 0.04, h - 0.94, 0.25), V(cx, 0.5 + (h - 0.9) / 2, -d / 2 + 0.105), dc, M.Wood, { solid = true })
		if o.louvre then
			for i = 1, 7 do
				R("Louvre", V(lw - 0.5, 0.12, 0.1), V(cx, 1.6 + i * 0.75, -d / 2 - 0.07), dc:Lerp(C.Ink, 0.25), M.Wood, B.SM)
			end
		else
			R("Inset", V(lw - 0.6, h * 0.36, 0.06), V(cx, 0.5 + h * 0.62, -d / 2 - 0.05), dc:Lerp(C.Ink, 0.2), M.Wood, B.SM)
			R("Inset", V(lw - 0.6, h * 0.28, 0.06), V(cx, 0.5 + h * 0.2, -d / 2 - 0.05), dc:Lerp(C.Ink, 0.2), M.Wood, B.SM)
		end
		B.ball(m, "Knob", b, 0.28, V(sx * 0.3, h * 0.48, -d / 2 - 0.16), C.Brass, M.Metal, B.SM)
	end
	local inside = b * CFrame.new(0, 3.1, 0.2)
	B.hideParts(m, kind, area, inside, (b * CFrame.new(0, 0, -d / 2 - 2.1)).Position, (b * CFrame.new(0, 0, -d / 2 - 2)).Position)
	return m
end

-- overrides of house props with coplanar faces removed
function B.trunk(par, b, col, area, danger, o)
	o = o or {}
	local m = B.model(par, "Trunk")
	local w, d = o.w or 3.6, o.d or 2.2
	B.rp(m, "Body", b, V(w, 1.6, d), V(0, 0.8, 0), col, M.Wood, { solid = true })
	local lid = B.rp(m, "Lid", b, V(w + 0.1, 0.55, d + 0.1), V(0, 1.875, 0), col:Lerp(C.Ink, 0.1), M.Wood, { solid = true })
	B.searchable(lid, "Trunk", area, danger)
	for _, x in { -w * 0.3, w * 0.3 } do
		B.rp(m, "Band", b, V(0.25, 2.18, d + 0.16), V(x, 1.11, 0), C.Metal:Lerp(C.Ink, 0.3), M.Metal, B.SM)
	end
	B.rp(m, "Latch", b, V(0.4, 0.5, 0.1), V(0, 1.6, -d / 2 - 0.1), C.Brass, M.Metal, B.SM)
	return m
end
function B.table(par, b, w, d, h, col, o)
	o = o or {}
	local m = B.model(par, o.name or "Table")
	B.rp(m, "Top", b, V(w, 0.3, d), V(0, h - 0.15, 0), col, M.Wood, { solid = true })
	local lx, lz = w / 2 - 0.45, d / 2 - 0.45
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			B.rp(m, "Leg", b, V(0.35, h - 0.3, 0.35), V(sx * lx, (h - 0.3) / 2, sz * lz), col:Lerp(C.Ink, 0.15), M.Wood, { solid = true })
		end
	end
	B.rp(m, "Apron", b, V(lx * 2, 0.38, lz * 2), V(0, h - 0.51, 0), col:Lerp(C.Ink, 0.2), M.Wood, B.SM)
	if o.cloth then
		B.rp(m, "Runner", b, V(w * 0.8, 0.04, math.min(1.6, d * 0.4)), V(0, h + 0.02, 0), o.cloth, M.Fabric, B.SM)
	end
	return m, h
end
function B.counter(par, b, len, col, top, area, danger, search, o)
	o = o or {}
	local m = B.model(par, o.name or "Counter")
	local d, h = 2.6, 3.4
	B.rp(m, "Body", b, V(len, h - 0.5, d - 0.2), V(0, (h - 0.5) / 2 + 0.4, 0.1), col, M.Wood, { solid = true })
	B.rp(m, "Toe", b, V(len - 0.1, 0.4, d - 0.5), V(0, 0.2, 0.25), C.WoodDark, M.Wood, B.SM)
	if not o.noTop then B.rp(m, "Countertop", b, V(len + 0.2, 0.3, d + 0.2), V(0, h - 0.05, 0), top, M.Marble, { solid = true }) end
	local n = math.max(1, math.floor(len / 2.5 + 0.5))
	local cw = len / n
	local fz = 0.1 - (d - 0.2) / 2 -- body front face
	for i = 1, n do
		local x = -len / 2 + cw * (i - 0.5)
		local kind = search and search[i]
		local door = B.rp(m, "CabDoor", b, V(cw - 0.25, 1.9, 0.12), V(x, 1.5, fz - 0.06), col:Lerp(C.Ink, 0.05), M.Wood, { collide = false })
		local drw = B.rp(m, "DrawerFront", b, V(cw - 0.25, 0.6, 0.12), V(x, 2.85, fz - 0.06), col:Lerp(C.Ink, 0.05), M.Wood, { collide = false })
		B.ball(m, "Pull", b, 0.18, V(x + cw * 0.3, 2.1, fz - 0.2), C.Brass, M.Metal, B.SM)
		B.ball(m, "Pull", b, 0.18, V(x, 2.85, fz - 0.2), C.Brass, M.Metal, B.SM)
		if kind == "Cabinet" then
			door.Name = "Cabinet"
			B.searchable(door, "Cabinet", area, danger)
		elseif kind == "Drawer" then
			drw.Name = "Drawer"
			B.searchable(drw, "Drawer", area, danger)
		end
	end
	return m, h + 0.1
end
function B.dresser(par, b, w, d, h, col, n, area, danger, o)
	o = o or {}
	local m = B.model(par, o.name or "Dresser")
	local dk = col:Lerp(C.Ink, 0.35)
	B.rp(m, "Body", b, V(w, h - 0.3, d), V(0, (h - 0.3) / 2 + 0.3, 0), col, M.Wood, { solid = true })
	B.rp(m, "Top", b, V(w + 0.3, 0.2, d + 0.2), V(0, h + 0.1, -0.05), col:Lerp(C.Ink, 0.25), M.Wood, { solid = true })
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			B.rp(m, "Foot", b, V(0.4, 0.3, 0.4), V(sx * (w / 2 - 0.3), 0.15, sz * (d / 2 - 0.3)), dk, M.Wood, B.SM)
		end
	end
	local dh = (h - 0.6) / n
	for i = 1, n do
		local y = h - 0.15 - dh * (i - 0.5)
		local f = B.rp(m, "DrawerFront", b, V(w - 0.4, dh - 0.15, 0.15), V(0, y, -d / 2 - 0.07), col:Lerp(C.Ink, 0.1), M.Wood, { collide = false })
		for _, sx in { -1, 1 } do
			B.ball(m, "Pull", b, 0.22, V(sx * w * 0.25, y, -d / 2 - 0.2), C.Brass, M.Metal, B.SM)
		end
		if o.search and table.find(o.search, i) then
			f.Name = "Drawer"
			B.searchable(f, o.kind or "Drawer", area, danger)
		end
	end
	return m, h + 0.2
end
function B.rug(par, x, y, z, w, d, col, border)
	B.box(par, "Rug", x - w / 2, y - 0.04, z - d / 2, x + w / 2, y + 0.05, z + d / 2, border or col:Lerp(C.Ink, 0.3), M.Fabric, { small = true, collide = false })
	B.box(par, "RugField", x - w / 2 + 0.6, y - 0.01, z - d / 2 + 0.6, x + w / 2 - 0.6, y + 0.07, z + d / 2 - 0.6, col, M.Fabric, { small = true, collide = false })
end

-- small candle Lamp (warm, short range)
function B.candleLamp(par, pos, h, o)
	o = o or {}
	return B.LP(par, "candle", CFrame.new(pos), { h = h or 0.8, range = o.range or 8, bright = o.bright or 0.7, color = Color3.fromRGB(255, 170, 96) })
end
-- unlit-by-code decor candle (glowing flame, no light, not a contract Lamp)
function B.candleDecor(par, pos, h)
	h = h or 0.8
	local b = CFrame.new(pos)
	B.cyl(par, "Candle", b, 0.3, h, V(0, h / 2, 0), C.Wax, M.SmoothPlastic, B.SM)
	B.ball(par, "Flame", b, 0.18, V(0, h + 0.15, 0), C.FlameC, M.Neon, B.SM)
end
-- iron candle stand (Breakable; flames are decor, not a Lamp)
function B.candleStand(par, pos, h)
	h = h or 4
	local m = B.model(par, "CandleStand")
	local b = CFrame.new(pos)
	local base = B.cyl(m, "Base", b, 1.2, 0.25, V(0, 0.125, 0), C.Iron, M.Metal, { collide = true, touch = true, query = true, shadow = false })
	B.cyl(m, "Stem", b, 0.2, h - 0.3, V(0, 0.25 + (h - 0.3) / 2, 0), C.Iron, M.Metal, { collide = true, touch = true, shadow = false })
	B.cyl(m, "Pan", b, 0.8, 0.1, V(0, h - 0.02, 0), C.Iron, M.Metal, B.SM)
	B.cyl(m, "Candle", b, 0.35, 0.9, V(0, h + 0.48, 0), C.Wax, M.SmoothPlastic, B.SM)
	B.ball(m, "Flame", b, 0.2, V(0, h + 1.05, 0), C.FlameC, M.Neon, B.SM)
	m.PrimaryPart = base
	B.tag(m, "Breakable")
	return m
end
-- vase of lilies (Breakable)
function B.lilies(par, pos, s, decor)
	s = s or 1
	local m = B.model(par, "VaseOfLilies")
	local b = CFrame.new(pos)
	local body = B.cyl(m, "Body", b, 0.9 * s, 1.3 * s, V(0, 0.65 * s, 0), C.StoneD:Lerp(C.Paper, 0.3), M.Marble, { collide = true, touch = true, query = true, shadow = false })
	for i = 1, 5 do
		local a = i * 1.26
		local off = V(math.cos(a) * 0.25 * s, 1.3 * s, math.sin(a) * 0.25 * s)
		B.part(m, "Stem", V(0.06, 1.1 * s, 0.06), b * CFrame.new(off + V(0, 0.5 * s, 0)) * CFrame.Angles(math.cos(a) * 0.25, 0, math.sin(a) * 0.25), C.Moss, M.SmoothPlastic, B.SM)
		B.ball(m, "Lily", b, 0.42 * s, off + V(math.cos(a) * 0.15, 1.15 * s, math.sin(a) * 0.15), C.Lily, M.SmoothPlastic, B.SM)
	end
	m.PrimaryPart = body
	if decor then
		body.CanTouch = false
		body.CanQuery = false
	else
		B.tag(m, "Breakable")
	end
	return m
end
return "extras ok"
