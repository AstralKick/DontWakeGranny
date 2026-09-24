-- BackGarden helper additions (run right after map_backgarden_00_lib). Adds functions to _G.BGB.
-- map_backgarden_00_lib = house_00_lib + house_01_props with: its own _G.BGB table (never shared
-- with the other map builders), B.root() = Workspace.Maps.BackGarden, and every part shifted by
-- B.SH (X +1500) so all builder coordinates are LOCAL to the map origin (1500, 0, 0).
local B = _G.BGB
local C, M = B.C, B.M
local V = Vector3.new
local SM = { small = true }
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
C.Hedge = rgb(40, 58, 42)
C.HedgeTop = rgb(54, 74, 52)
C.Terracotta = rgb(160, 88, 62)
C.Gravel = rgb(118, 110, 106)
C.Wicker = rgb(168, 136, 94)
C.Moss = rgb(70, 88, 60)
C.GlassG = rgb(150, 182, 172)
C.Iron = rgb(40, 36, 44)
C.Soil = rgb(56, 42, 36)
C.Flag = rgb(104, 98, 100)
B.DW = 4.5

-- wall gap for a framed door (the frame fills 0.35 each side and a 0.35 header)
function B.dgap(c) return { c = c, w = B.DW + 0.7, h = 8.35 } end

-- Hinged door. The hinge axis is inset 0.27 from the jamb so the leaf never clips the frame
-- while it swings; closed gaps: 0.05 at the sides, 0.07 at the top, 0.06 at the floor.
-- o: style ("wood"/"glass"/"garden"), color, hs (+1 hinge on the low side), squeaky, lockable,
--    wallT (frame depth), frame=false (no frame), frameColor, sill (threshold)
function B.door2(parent, name, axis, fixed, c, y0, area, o)
	o = o or {}
	local W = B.DW
	local hs = o.hs or 1
	local right = if axis == "x" then Vector3.xAxis else Vector3.zAxis
	local along = c - hs * (W / 2 - 0.27)
	local hinge = if axis == "x" then V(along, y0, fixed) else V(fixed, y0, along)
	local base = CFrame.fromMatrix(hinge, right * hs, Vector3.yAxis)
	local m = B.model(parent, name)
	local hp = B.rp(m, "Hinge", base, V(0.2, 8, 0.2), V(0, 4, 0), C.Paper, M.SmoothPlastic, { inv = true })
	local style = o.style or "wood"
	local col = o.color or C.WoodMid
	local glass = style == "glass"
	local pw = W - 0.1
	local pcx = (W - 0.54) / 2
	local panel = B.rp(m, "Panel", base, V(pw, 7.87, 0.3), V(pcx, 3.995, 0), if glass then C.GlassG else col, if glass then M.Glass else M.Wood,
		{ collide = true, query = true, tr = if glass then 0.55 else 0, shadow = not glass })
	local pm = Instance.new("PathfindingModifier")
	pm.PassThrough = true
	pm.Parent = panel
	local dk = col:Lerp(C.Ink, 0.3)
	for _, zz in { -0.17, 0.17 } do
		if glass then
			B.rp(m, "Stile", base, V(0.4, 7.87, 0.06), V(pcx - pw / 2 + 0.2, 3.995, zz), col, M.Wood, SM)
			B.rp(m, "Stile", base, V(0.4, 7.87, 0.06), V(pcx + pw / 2 - 0.2, 3.995, zz), col, M.Wood, SM)
			B.rp(m, "Rail", base, V(pw - 0.8, 0.4, 0.06), V(pcx, 7.73, zz), col, M.Wood, SM)
			B.rp(m, "Rail", base, V(pw - 0.8, 1.2, 0.06), V(pcx, 0.66, zz), col, M.Wood, SM)
			B.rp(m, "Rail", base, V(pw - 0.8, 0.25, 0.06), V(pcx, 3.9, zz), col, M.Wood, SM)
			B.rp(m, "Mullion", base, V(0.2, 6.2, 0.06), V(pcx, 4.43, zz), col, M.Wood, SM)
		elseif style == "garden" then
			for i = 1, 4 do
				B.rp(m, "PlankLine", base, V(0.08, 7.7, 0.04), V(pcx - pw / 2 + i * pw / 5, 3.995, zz * 1.03), dk, M.Wood, SM)
			end
			B.rp(m, "Ledge", base, V(pw - 0.4, 0.5, 0.08), V(pcx, 1.4, zz * 1.1), dk, M.Wood, SM)
			B.rp(m, "Ledge", base, V(pw - 0.4, 0.5, 0.08), V(pcx, 6.6, zz * 1.1), dk, M.Wood, SM)
			local br = B.rp(m, "Brace", base, V(0.45, 5.6, 0.08), V(pcx, 4, zz * 1.1), dk, M.Wood, SM)
			br.CFrame = br.CFrame * CFrame.Angles(0, 0, math.rad(-35))
		else
			B.rp(m, "Inset", base, V(pw - 1.2, 2.9, 0.06), V(pcx, 5.6, zz), dk, M.Wood, SM)
			B.rp(m, "Inset", base, V(pw - 1.2, 3.2, 0.06), V(pcx, 1.9, zz), dk, M.Wood, SM)
		end
		B.ball(m, "Knob", base, 0.3, V(W - 0.75, 3.6, zz * 1.6), if style == "garden" then C.Iron else C.Brass, M.Metal, SM)
	end
	if o.frame ~= false then
		local t = (o.wallT or 0.5) + 0.3
		local fc = o.frameColor or C.WoodDark
		-- frames are visual only: the collidable opening is the 5.2 wall gap (Grandma pathing clearance)
		local fo = { collide = false, shadow = true }
		local e0, e1 = c - W / 2, c + W / 2
		if axis == "x" then
			B.box(parent, "DoorFrame", e0 - 0.35, y0, fixed - t / 2, e0, y0 + 8, fixed + t / 2, fc, M.Wood, fo)
			B.box(parent, "DoorFrame", e1, y0, fixed - t / 2, e1 + 0.35, y0 + 8, fixed + t / 2, fc, M.Wood, fo)
			B.box(parent, "DoorHead", e0 - 0.35, y0 + 8, fixed - t / 2, e1 + 0.35, y0 + 8.35, fixed + t / 2, fc, M.Wood, fo)
			if o.sill then B.box(parent, "Threshold", e0, y0 - 0.3, fixed - t / 2, e1, y0 + 0.03, fixed + t / 2, C.Stone, M.Slate, fo) end
		else
			B.box(parent, "DoorFrame", fixed - t / 2, y0, e0 - 0.35, fixed + t / 2, y0 + 8, e0, fc, M.Wood, fo)
			B.box(parent, "DoorFrame", fixed - t / 2, y0, e1, fixed + t / 2, y0 + 8, e1 + 0.35, fc, M.Wood, fo)
			B.box(parent, "DoorHead", fixed - t / 2, y0 + 8, e0 - 0.35, fixed + t / 2, y0 + 8.35, e1 + 0.35, fc, M.Wood, fo)
			if o.sill then B.box(parent, "Threshold", fixed - t / 2, y0 - 0.3, e0, fixed + t / 2, y0 + 0.03, e1, C.Stone, M.Slate, fo) end
		end
	end
	m.PrimaryPart = hp
	B.attrs(m, { Area = area, Squeaky = o.squeaky == true, Lockable = o.lockable == true })
	B.tag(m, "Door")
	return m
end

-- Barrier model (locks an Area): collidable boards + chain + padlock + an invisible full blocker.
-- Sits on the outside of an opening: axis/fixed/c like a door gap, n = normal sign toward the outside.
function B.barrier(area, name, axis, fixed, c, y0, w, h, n, o)
	o = o or {}
	local m = B.model(B.F("Barriers"), name)
	m:SetAttribute("Area", area)
	local right = if axis == "x" then Vector3.xAxis else Vector3.zAxis
	local nrm = (if axis == "x" then Vector3.zAxis else Vector3.xAxis) * n
	local d = o.d or 0.8
	local ctr = (if axis == "x" then V(c, y0, fixed) else V(fixed, y0, c)) + nrm * d
	local base = CFrame.lookAt(ctr, ctr + nrm) -- local -Z = outside, local X along the opening
	B.rp(m, "Blocker", base, V(w + 0.6, h, 0.5), V(0, h / 2, 0), C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	local wood = o.color or C.WoodRaw:Lerp(C.Ink, 0.25)
	if o.iron then
		-- wrought-iron gate leaf, chained shut
		B.rp(m, "GateRail", base, V(w + 0.4, 0.25, 0.2), V(0, 0.6, 0), C.Iron, M.Metal, { collide = true })
		B.rp(m, "GateRail", base, V(w + 0.4, 0.25, 0.2), V(0, 4.5, 0), C.Iron, M.Metal, { collide = true })
		B.rp(m, "GateRail", base, V(w + 0.4, 0.25, 0.2), V(0, h - 0.4, 0), C.Iron, M.Metal, { collide = true })
		local nb = math.floor(w / 0.6)
		for i = 0, nb do
			local x = -w / 2 + i * w / nb
			B.rp(m, "GateBar", base, V(0.14, h - 0.3, 0.14), V(x, (h - 0.3) / 2 + 0.15, 0), C.Iron, M.Metal, { collide = true })
			B.rp(m, "Spike", base, V(0.22, 0.5, 0.22), V(x, h + 0.1, 0), C.Iron, M.Metal, SM)
		end
	else
		local planks = { { 1.4, 4 }, { 3.6, -5 }, { 6.1, 3 } }
		for i, pl in planks do
			local p = B.rp(m, "Board", base, V(w + 1.2, 0.8, 0.25), V(0, pl[1], 0), wood:Lerp(C.Paper, (i % 2) * 0.08), M.WoodPlanks, { collide = true })
			p.CFrame = p.CFrame * CFrame.Angles(0, 0, math.rad(pl[2]))
		end
		local diag = math.sqrt(w * w + (h - 1.5) ^ 2)
		local x = B.rp(m, "CrossBoard", base, V(0.8, diag - 0.4, 0.25), V(0, h / 2, -0.26), wood, M.WoodPlanks, { collide = true })
		x.CFrame = x.CFrame * CFrame.Angles(0, 0, math.atan2(w, h - 1.5))
	end
	for i = -3, 3 do
		local link = B.rp(m, "ChainLink", base, V(0.5, 0.22, 0.12), V(i * 0.55, 4.0 + math.abs(i) * 0.1, -0.45), C.Iron:Lerp(C.Paper, 0.25), M.Metal, SM)
		link.CFrame = link.CFrame * CFrame.Angles((i % 2) * math.rad(90), 0, 0)
	end
	B.rp(m, "Padlock", base, V(0.6, 0.7, 0.3), V(0, 3.6, -0.55), C.Brass, M.Metal, SM)
	B.rp(m, "Sign", base, V(2.6, 1.3, 0.08), V(0.4, 5.4, -0.5), C.Paper:Lerp(C.Ink, 0.15), M.Cardboard, SM)
	B.rp(m, "SignInk", base, V(2.0, 0.25, 0.02), V(0.4, 5.6, -0.55), C.Blood, M.SmoothPlastic, SM)
	B.rp(m, "SignInk", base, V(1.4, 0.2, 0.02), V(0.3, 5.2, -0.55), C.Ink, M.SmoothPlastic, SM)
	return m
end

-- hedge block (solid) with a lighter clipped top and a few soft lumps
function B.hedge(parent, x0, z0, x1, z1, h, o)
	o = o or {}
	local ax0, ax1, az0, az1 = math.min(x0, x1), math.max(x0, x1), math.min(z0, z1), math.max(z0, z1)
	local hp = B.box(parent, "Hedge", ax0, 0, az0, ax1, h, az1, C.Hedge, M.LeafyGrass, { solid = true })
	B.box(parent, "HedgeTop", ax0 + 0.2, h, az0 + 0.2, ax1 - 0.2, h + 0.35, az1 - 0.2, C.HedgeTop, M.LeafyGrass, { small = true })
	local lx, lz = ax1 - ax0, az1 - az0
	if not o.nolumps then
		local len = math.max(lx, lz)
		local n = math.floor(len / 7)
		for i = 1, n do
			local t = (i - 0.5) / n
			local x = ax0 + (if lx >= lz then lx * t else lx / 2)
			local z = az0 + (if lz > lx then lz * t else lz / 2)
			local s = 1.4 + ((i * 7 + math.floor(x + z)) % 4) * 0.2
			local wdt = math.min(lx, lz) - 0.5
			B.part(parent, "HedgeLump", V(s * 1.8, s, wdt), CFrame.new(x, h + 0.2, z) * CFrame.Angles(0, if lx >= lz then 0 else math.rad(90), 0), C.HedgeTop, M.LeafyGrass, { small = true, shape = Enum.PartType.Ball })
		end
	end
	return hp
end

-- brick garden wall with a coping stone
function B.brickWall(parent, x0, z0, x1, z1, h)
	local w = B.box(parent, "GardenWall", x0, 0, z0, x1, h, z1, C.Brick, M.Brick, { solid = true })
	B.box(parent, "Coping", math.min(x0, x1) - 0.2, h, math.min(z0, z1) - 0.2, math.max(x0, x1) + 0.2, h + 0.4, math.max(z0, z1) + 0.2, C.Stone:Lerp(C.Paper, 0.15), M.Slate, { small = true })
	return w
end

-- picket fence run along X (z fixed) or Z (x fixed). Collidable.
function B.picket(parent, axis, fixed, a, b, h)
	local fc = C.Paper:Lerp(C.Ink, 0.3)
	h = h or 4.2
	local n = math.floor((b - a) / 1.1)
	for i = 0, n do
		local s = a + 0.3 + i * (b - a - 0.6) / math.max(n, 1)
		local hh = h + (i % 3) * 0.1
		local cf = if axis == "x" then CFrame.new(s, hh / 2, fixed) else CFrame.new(fixed, hh / 2, s) * CFrame.Angles(0, math.rad(90), 0)
		B.part(parent, "Picket", V(0.55, hh, 0.18), cf * CFrame.Angles(0, 0, math.rad(((i * 17) % 7 - 3) * 0.7)), fc, M.Wood, { small = true, collide = true })
	end
	for _, y in { 1.1, 3.0 } do
		if axis == "x" then
			B.box(parent, "FenceRail", a, y, fixed + 0.09, b, y + 0.3, fixed + 0.3, fc:Lerp(C.Ink, 0.1), M.Wood, { small = true })
		else
			B.box(parent, "FenceRail", fixed + 0.09, y, a, fixed + 0.3, y + 0.3, b, fc:Lerp(C.Ink, 0.1), M.Wood, { small = true })
		end
	end
end

-- terracotta pot (Breakable). b on the surface
function B.pot(par, b, s, plant)
	s = s or 1
	local m = B.model(par, "TerracottaPot")
	local col = C.Terracotta:Lerp(C.Ink, (math.floor(math.abs(b.Position.X * 7 + b.Position.Z * 3)) % 3) * 0.06)
	local body = B.cyl(m, "Body", b, 1.0 * s, 1.1 * s, V(0, 0.55 * s, 0), col, M.Slate, { collide = true, touch = true, query = true, shadow = false }, true)
	B.cyl(m, "Rim", b, 1.25 * s, 0.25 * s, V(0, 1.12 * s, 0), col:Lerp(C.Paper, 0.1), M.Slate, SM, true)
	B.cyl(m, "Soil", b, 1.05 * s, 0.05, V(0, 1.24 * s + 0.01, 0), C.Soil, M.Ground, SM, true)
	if plant == "dead" then
		for i = 1, 3 do
			local st = B.rp(m, "Stalk", b, V(0.08, 1.1 * s, 0.08), V((i - 2) * 0.2 * s, 1.8 * s, 0), C.WoodDark:Lerp(C.Moss, 0.3), M.Wood, SM)
			st.CFrame = st.CFrame * CFrame.Angles(math.rad((i - 2) * 20), 0, math.rad((i - 2) * -15))
		end
	elseif plant ~= false then
		B.ball(m, "Leaves", b, 1.2 * s, V(0, 1.75 * s, 0), (plant or C.Moss):Lerp(C.Ink, 0.15), M.LeafyGrass, SM)
	end
	m.PrimaryPart = body
	B.tag(m, "Breakable")
	return m
end

-- garden gnome (Breakable)
function B.gnome(par, b, hat)
	local m = B.model(par, "Gnome")
	local body = B.cyl(m, "Body", b, 1.0, 1.2, V(0, 0.6, 0), C.Mint:Lerp(C.Ink, 0.35), M.SmoothPlastic, { collide = true, touch = true, query = true, shadow = false }, true)
	B.ball(m, "Head", b, 0.75, V(0, 1.5, 0), C.Paper:Lerp(C.Rose, 0.25), M.SmoothPlastic, SM)
	B.rp(m, "Beard", b, V(0.6, 0.6, 0.2), V(0, 1.2, -0.38), C.Paper, M.Fabric, SM)
	for i = 0, 2 do
		B.cyl(m, "Hat", b, 0.8 - i * 0.25, 0.3, V(0, 1.85 + i * 0.28, 0.04 * i), hat or C.Blood:Lerp(C.Ink, 0.15), M.SmoothPlastic, SM, true)
	end
	for _, sx in { -1, 1 } do
		B.rp(m, "Eye", b, V(0.1, 0.1, 0.04), V(sx * 0.14, 1.56, -0.36), C.Ink, M.SmoothPlastic, SM)
	end
	m.PrimaryPart = body
	B.tag(m, "Breakable")
	return m
end

-- lantern on a post (Lamp)
function B.lanternPost(par, x, y, z, area, o)
	o = o or {}
	local m = B.model(par, "Lamp_lantern")
	local b = CFrame.new(x, y, z)
	local h = o.h or 6
	B.cyl(m, "Post", b, 0.35, h, V(0, h / 2, 0), C.Iron, M.Metal, SM, true)
	B.rp(m, "Cage", b, V(0.9, 1.2, 0.9), V(0, h + 0.6, 0), C.Iron, M.Glass, { small = true, tr = 0.55 })
	B.rp(m, "Cap", b, V(1.2, 0.2, 1.2), V(0, h + 1.3, 0), C.Iron, M.Metal, SM)
	B.rp(m, "Foot", b, V(0.8, 0.3, 0.8), V(0, 0.15, 0), C.Iron, M.Metal, SM)
	local bulb = B.ball(m, "Bulb", b, 0.5, V(0, h + 0.55, 0), Color3.fromRGB(255, 200, 140), M.Neon, SM)
	local l = Instance.new("PointLight")
	l.Color = o.color or Color3.fromRGB(255, 180, 120)
	l.Range = o.range or 16
	l.Brightness = o.bright or 0.9
	l.Shadows = o.shadows or false
	l.Parent = bulb
	m.PrimaryPart = bulb
	B.attrs(m, { Area = area })
	B.tag(m, "Lamp")
	return m
end

-- hanging lantern (Lamp). pos = hook point (local)
function B.hangLantern(par, pos, area, o)
	o = o or {}
	local m = B.model(par, "Lamp_hanging")
	local b = CFrame.new(pos)
	local drop = o.drop or 1.2
	B.rp(m, "Chain", b, V(0.08, drop, 0.08), V(0, -drop / 2, 0), C.Iron, M.Metal, SM)
	B.rp(m, "Cap", b, V(0.9, 0.2, 0.9), V(0, -drop - 0.1, 0), C.Iron, M.Metal, SM)
	B.rp(m, "Cage", b, V(0.75, 1.0, 0.75), V(0, -drop - 0.7, 0), C.Iron, M.Glass, { small = true, tr = 0.55 })
	local bulb = B.ball(m, "Bulb", b, 0.45, V(0, -drop - 0.7, 0), Color3.fromRGB(255, 200, 140), M.Neon, SM)
	local l = Instance.new("PointLight")
	l.Color = o.color or Color3.fromRGB(255, 184, 120)
	l.Range = o.range or 14
	l.Brightness = o.bright or 0.8
	l.Shadows = o.shadows or false
	l.Parent = bulb
	m.PrimaryPart = bulb
	B.attrs(m, { Area = area, NoGround = true })
	B.tag(m, "Lamp")
	return m
end

-- string of fairy lights hung between points (Lamp). pts = list of local Vector3
function B.stringLights(par, pts, area, o)
	o = o or {}
	local m = B.model(par, "Lamp_string")
	local first
	local lit = 0
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local n = math.max(2, math.floor((a - b).Magnitude / 3))
		local prev = a
		for k = 1, n do
			local t = k / n
			local sag = math.sin(t * math.pi) * (o.sag or 1.2)
			local p = a:Lerp(b, t) - V(0, sag, 0)
			local mid = (prev + p) / 2
			local seg = (p - prev).Magnitude
			B.part(m, "Wire", V(0.06, 0.06, seg), CFrame.lookAt(mid, p), C.Ink, M.SmoothPlastic, SM)
			if k < n then
				local col = ({ Color3.fromRGB(255, 210, 150), Color3.fromRGB(240, 170, 170), Color3.fromRGB(200, 230, 180) })[(k + i) % 3 + 1]
				local bulb = B.part(m, "Bulb", V(0.32, 0.32, 0.32), CFrame.new(p - V(0, 0.22, 0)), col, M.Neon, { small = true, shape = Enum.PartType.Ball })
				first = first or bulb
				if (k + i) % 4 == 0 and lit < (o.lights or 3) then
					lit += 1
					local l = Instance.new("PointLight")
					l.Color = Color3.fromRGB(255, 190, 140)
					l.Range = 12
					l.Brightness = 0.55
					l.Parent = bulb
				end
			end
			prev = p
		end
	end
	if lit == 0 and first then
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 190, 140)
		l.Range = 12
		l.Brightness = 0.55
		l.Parent = first
	end
	m.PrimaryPart = first
	B.attrs(m, { Area = area, NoGround = true })
	B.tag(m, "Lamp")
	return m
end

-- generic standing hide box (compost bin, locker, cupboard...). b on the floor, LookVector = front.
-- o: w, d, h, col, mat, kind, name, slats, lid (colour), doorColor
function B.hideBox(par, b, area, o)
	local m = B.model(par, o.name or "HideBox")
	local w, d, h = o.w or 4.6, o.d or 3.8, o.h or 7.6
	local col, mat = o.col or C.WoodMid, o.mat or M.Wood
	local function R(n, sz, off, c, mt, op) return B.rp(m, n, b, sz, off, c or col, mt or mat, op) end
	R("Back", V(w, h, 0.3), V(0, h / 2, d / 2 - 0.15))
	for _, sx in { -1, 1 } do R("Side", V(0.3, h, d - 0.55), V(sx * (w / 2 - 0.15), h / 2, -0.025)) end
	R("Top", V(w - 0.6, 0.35, d - 0.55), V(0, h - 0.175, -0.025))
	R("Plinth", V(w - 0.6, 0.4, d - 0.55), V(0, 0.2, -0.025), col:Lerp(C.Ink, 0.3))
	local front = R("Leaf", V(w, h, 0.25), V(0, h / 2, -d / 2 + 0.125), o.doorColor or col)
	local dc = (o.doorColor or col):Lerp(C.Ink, 0.3)
	if o.slats then
		for y = 0.8, h - 0.6, 0.9 do
			R("Slat", V(w - 0.3, 0.12, 0.06), V(0, y, -d / 2 - 0.02), dc, M.Wood, SM)
		end
	else
		R("Inset", V(w - 1.0, h * 0.5, 0.06), V(0, h * 0.62, -d / 2 - 0.02), dc, M.Wood, SM)
		R("Inset", V(w - 1.0, h * 0.25, 0.06), V(0, h * 0.2, -d / 2 - 0.02), dc, M.Wood, SM)
	end
	if o.lid then R("Lid", V(w + 0.3, 0.3, d + 0.2), V(0, h + 0.15, -0.05), o.lid, M.Wood, SM) end
	B.ball(m, "Handle", b, 0.3, V(w / 2 - 0.6, h * 0.5, -d / 2 - 0.12), C.Iron, M.Metal, SM)
	local inside = b * CFrame.new(0, 3.1, 0.1)
	B.hideParts(m, o.kind or "Cabinet", area, inside, (b * CFrame.new(0, 0, -d / 2 - 2.1)).Position, (b * CFrame.new(0, 0, -d / 2 - 2)).Position)
	return m, front
end

-- prone Inside (lies along b.LookVector, head toward the front, same convention as B.bed)
function B.proneInside(m, b, area, len, y, kind)
	local pos = (b * CFrame.new(0, y or 1.1, 0.3)).Position
	local inside = CFrame.fromMatrix(pos, b.RightVector, b.LookVector)
	return B.hideParts(m, kind or "Bed", area, inside, (b * CFrame.new(0, 0, -len / 2 - 2)).Position, (b * CFrame.new(1.4, 0, -len / 2 - 2.2)).Position)
end

-- potting bench: top at 3.2, lower shelf, apron drawers (search = { [i] = kind }), optional sacking skirt
function B.bench(par, b, len, area, danger, o)
	o = o or {}
	local m = B.model(par, o.name or "PottingBench")
	local d, h = o.d or 3, 3.2
	local col = o.col or C.WoodRaw
	local function R(n, sz, off, c, mt, op) return B.rp(m, n, b, sz, off, c or col, mt or M.Wood, op) end
	R("Top", V(len, 0.25, d), V(0, h - 0.125, 0), nil, M.WoodPlanks, { solid = true })
	R("Upstand", V(len, 1.2, 0.2), V(0, h + 0.6, d / 2 - 0.1), col:Lerp(C.Ink, 0.2))
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			R("Leg", V(0.3, h - 0.25, 0.3), V(sx * (len / 2 - 0.3), (h - 0.25) / 2, sz * (d / 2 - 0.3)), col:Lerp(C.Ink, 0.2))
		end
	end
	if not o.skirt then R("Shelf", V(len - 0.6, 0.15, d - 0.6), V(0, 0.8, 0), col:Lerp(C.Ink, 0.1), M.WoodPlanks, SM) end
	local nd = math.max(1, math.floor(len / 3))
	local dw = (len - 0.8) / nd
	for i = 1, nd do
		local x = -len / 2 + 0.4 + dw * (i - 0.5)
		local f = R("DrawerFront", V(dw - 0.2, 0.55, 0.12), V(x, h - 0.55, -d / 2 - 0.06), col:Lerp(C.Ink, 0.12), M.Wood, { collide = false })
		B.ball(m, "Pull", b, 0.18, V(x, h - 0.55, -d / 2 - 0.16), C.Iron, M.Metal, SM)
		if o.search and o.search[i] then
			f.Name = "Drawer"
			B.searchable(f, o.search[i], area, danger)
		end
	end
	if o.skirt then
		local sk = C.Mustard:Lerp(C.WoodDark, 0.55)
		R("Sacking", V(len - 0.7, h - 0.9, 0.1), V(0, (h - 0.9) / 2 + 0.05, -d / 2 + 0.35), sk, M.Fabric)
		for _, sx in { -1, 1 } do R("Sacking", V(0.1, h - 0.9, d - 0.8), V(sx * (len / 2 - 0.35), (h - 0.9) / 2 + 0.05, 0), sk, M.Fabric) end
		R("Sacking", V(len - 0.7, h - 0.9, 0.1), V(0, (h - 0.9) / 2 + 0.05, d / 2 - 0.35), sk, M.Fabric)
	end
	return m, h
end

-- open shelf unit, b on the floor. returns model and shelf top heights
function B.shelves(par, b, w, h, d, n, col)
	local m = B.model(par, "Shelves")
	col = col or C.WoodRaw
	for _, sx in { -1, 1 } do B.rp(m, "Upright", b, V(0.25, h, d), V(sx * (w / 2 - 0.125), h / 2, 0), col:Lerp(C.Ink, 0.2), M.Wood) end
	local ys = {}
	for i = 0, n - 1 do
		local y = 0.4 + (h - 0.8) * i / math.max(n - 1, 1)
		B.rp(m, "Shelf", b, V(w - 0.5, 0.15, d), V(0, y, 0), col, M.WoodPlanks, SM)
		table.insert(ys, y + 0.075)
	end
	return m, ys
end

-- gravel creaky patch (tag Creaky)
function B.gravelCreak(x, y, z, rot)
	local p = B.part(B.F("Creaky"), "CreakyGravel", V(4, 0.2, 4), CFrame.new(x, y - 0.07, z) * CFrame.Angles(0, math.rad(rot or 0), 0), C.Gravel:Lerp(C.Paper, 0.12), M.Pebble, { collide = true, touch = true, query = true, shadow = false })
	return B.tag(p, "Creaky")
end

-- visible steps + invisible collidable WedgePart ramp from y0 (low edge) up to y1 along dir.
-- x,z = footprint centre, w across, run along dir. WedgePart slope rises toward local +Z.
function B.steps(par, x, z, w, run, y0, y1, dir, col, mat)
	local rise = y1 - y0
	local deg = ({ ["+z"] = 0, ["-z"] = 180, ["+x"] = 90, ["-x"] = -90 })[dir]
	local base = CFrame.new(x, y0, z) * CFrame.Angles(0, math.rad(deg), 0)
	local ramp = B.part(par, "Ramp", V(w, rise, run), base * CFrame.new(0, rise / 2, 0), C.Paper, M.SmoothPlastic, { inv = true, collide = true, class = "WedgePart" })
	local n = math.max(2, math.ceil(rise / 0.8))
	for i = 1, n do
		local top = rise * i / n
		local depth = run * (n - i + 1) / n
		B.part(par, "Step", V(w - 0.02, top - 0.03, depth), base * CFrame.new(0, (top - 0.03) / 2, run / 2 - depth / 2), col or C.Stone, mat or M.Slate, { collide = false, shadow = true })
	end
	return ramp
end

-- fake window on a wall facing -Z at z = face (house facade). lit = faint warm glow
function B.fakeWindow(par, x, y0, face, w, h, lit)
	local m = B.model(par, "FakeWindow")
	local glass = if lit then Color3.fromRGB(120, 92, 70) else Color3.fromRGB(34, 36, 50)
	local g = B.box(m, "Glass", x - w / 2, y0, face - 0.12, x + w / 2, y0 + h, face - 0.02, glass, if lit then M.Neon else M.Glass, { small = true })
	if lit then g.Transparency = 0.35 end
	B.box(m, "Mullion", x - 0.1, y0, face - 0.25, x + 0.1, y0 + h, face - 0.1, C.Paper:Lerp(C.Ink, 0.25), M.Wood, { small = true })
	B.box(m, "Mullion", x - w / 2, y0 + h * 0.55 - 0.1, face - 0.25, x + w / 2, y0 + h * 0.55 + 0.1, face - 0.1, C.Paper:Lerp(C.Ink, 0.25), M.Wood, { small = true })
	B.box(m, "Frame", x - w / 2 - 0.35, y0 + h, face - 0.4, x + w / 2 + 0.35, y0 + h + 0.35, face, C.Paper:Lerp(C.Ink, 0.25), M.Wood, { small = true })
	B.box(m, "Sill", x - w / 2 - 0.5, y0 - 0.35, face - 0.7, x + w / 2 + 0.5, y0, face, C.Paper:Lerp(C.Ink, 0.25), M.Wood, { small = true })
	B.box(m, "Frame", x - w / 2 - 0.35, y0, face - 0.4, x - w / 2, y0 + h, face, C.Paper:Lerp(C.Ink, 0.25), M.Wood, { small = true })
	B.box(m, "Frame", x + w / 2, y0, face - 0.4, x + w / 2 + 0.35, y0 + h, face, C.Paper:Lerp(C.Ink, 0.25), M.Wood, { small = true })
	for _, s in { -1, 1 } do
		B.box(m, "Shutter", x + s * (w / 2 + 0.4), y0, face - 0.2, x + s * (w / 2 + 2.0), y0 + h, face - 0.05, C.Mint:Lerp(C.Ink, 0.45), M.Wood, { small = true })
	end
	return m
end
return "BackGarden helpers ok"
