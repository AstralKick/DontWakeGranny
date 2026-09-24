-- NightmareHouse builder library (_G.NH). Run AFTER house_00_lib + house_01_props (reuses _G.HB helpers).
-- All coordinates in the NH chunks are HOUSE-LOCAL (same numbers as the original house); NH.V/NH.CF add the X offset.
-- Never touches anything outside Workspace.Maps.NightmareHouse.
-- Rebuild order (one execute_luau each): 00_lib, 01_clone, 02_mood, 03_ground, 04_upstairs, 05_basement, 06_attic,
-- 07_contract, 08_fixes, 09_polish, 09b_zfix (re-runnable),
-- then map_nightmarehouse_audit, _10_validate and _11_pathcheck (read-only checks).
local B = _G.HB
assert(B and B.doll, "run house_00_lib and house_01_props first")
local CS = game:GetService("CollectionService")

local NH = {}
_G.NH = NH
NH.B = B
NH.OX = 7500
local OX = NH.OX
local V3 = Vector3.new
local M = Enum.Material
NH.C = {
	Vein = Color3.fromRGB(96, 6, 14), VeinHot = Color3.fromRGB(140, 10, 22),
	Root = Color3.fromRGB(46, 30, 28), RootDark = Color3.fromRGB(30, 20, 20), RootMoss = Color3.fromRGB(52, 48, 34),
	Red = Color3.fromRGB(255, 58, 66), Purple = Color3.fromRGB(168, 80, 255), Sick = Color3.fromRGB(190, 255, 120),
	Tint = Color3.fromRGB(64, 26, 48), Velvet = Color3.fromRGB(96, 16, 30), Gold = Color3.fromRGB(150, 116, 52),
	Brick = Color3.fromRGB(92, 50, 48), Mortar = Color3.fromRGB(60, 44, 46), Scratch = Color3.fromRGB(20, 12, 16),
	Fog = Color3.fromRGB(120, 96, 150), Baby = Color3.fromRGB(176, 150, 170), BabyBlue = Color3.fromRGB(120, 138, 160),
	Cream = Color3.fromRGB(196, 180, 150), DeadBulb = Color3.fromRGB(46, 42, 44),
}
setmetatable(NH.C, { __index = B.C }) -- NH.C falls back to the house palette
function NH.root() return workspace.Maps.NightmareHouse end
function NH.V(x, y, z) return V3(x + OX, y, z) end
function NH.CF(x, y, z, dir) return B.cf(x + OX, y, z, dir) end
function NH.W(cf) return cf + V3(OX, 0, 0) end -- local CFrame -> world
function NH.F(name, parent)
	parent = parent or NH.root()
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end
-- the transformation decor lives here (re-created by each chunk that owns a subfolder)
function NH.fresh(name)
	local nf = NH.F("Nightmare")
	local old = nf:FindFirstChild(name)
	if old then old:Destroy() end
	return NH.F(name, nf)
end
-- local-coordinate box
function NH.box(par, name, x0, y0, z0, x1, y1, z1, col, mat, o)
	return B.box(par, name, x0 + OX, y0, z0, x1 + OX, y1, z1, col, mat, o)
end
-- block/cylinder spanning two WORLD points
function NH.seg(par, name, a, b, w, h, col, mat, o)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	return B.part(par, name, V3(w, h, len), cf, col, mat, o)
end
function NH.rootSeg(par, name, a, b, dia, col, o)
	local len = (b - a).Magnitude + dia * 0.5
	local cf = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
	local p = B.part(par, name, V3(len, dia, dia), cf, col or NH.C.Root, M.Wood, o)
	p.Shape = Enum.PartType.Cylinder
	return p
end
-- a chain of root segments through WORLD points, tapering from d0 to d1
function NH.rootChain(par, pts, d0, d1, col, o)
	local n = #pts - 1
	local out = {}
	for i = 1, n do
		local d = d0 + (d1 - d0) * ((i - 1) / math.max(1, n - 1))
		table.insert(out, NH.rootSeg(par, "Root", pts[i], pts[i + 1], d, col, o))
	end
	return out
end
-- deterministic RNG
function NH.rng(seed) return Random.new(seed) end

-- Veins: branching Neon strands on a wall surface. origin = WORLD point on the surface, n = wall normal (unit,
-- pointing into the room), up = initial growth direction (in the wall plane). Parts sit 0.13 proud of the wall.
-- o.lo/o.hi (WORLD Vector3) clamp the growth to a box (e.g. the wall face) so veins never poke through ceilings.
function NH.veins(par, origin, n, up, len, seed, depth, o)
	o = o or {}
	local r = NH.rng(seed)
	local side = n:Cross(up).Unit
	local count = 0
	local function inside(p)
		return not o.lo or (p.X >= o.lo.X and p.Y >= o.lo.Y and p.Z >= o.lo.Z and p.X <= o.hi.X and p.Y <= o.hi.Y and p.Z <= o.hi.Z)
	end
	local function grow(p, dir, L, w, d)
		local steps = math.max(2, math.floor(L / 2.2))
		local cur = p
		for i = 1, steps do
			local ang = (r:NextNumber() - 0.5) * 0.9
			dir = (dir * math.cos(ang) + side * math.sin(ang) * (if dir:Dot(up) > 0 then 1 else -1)).Unit
			dir = (dir - n * dir:Dot(n)).Unit
			local nxt = cur + dir * (L / steps)
			local tries = 0
			while not inside(nxt) and tries < 3 do -- deflect along the surface instead of leaving it
				tries += 1
				dir = n:Cross(dir).Unit * (if tries == 2 then -1 else 1)
				nxt = cur + dir * (L / steps)
			end
			if not inside(nxt) then return end
			local sw = w * (1 - (i - 1) / (steps + 1))
			local pp = NH.seg(par, "Vein", cur + n * 0.13, nxt + n * 0.13, math.max(0.12, sw), 0.14, if d == 0 then NH.C.VeinHot else NH.C.Vein, M.Neon, { small = true, tr = o.tr or 0.12 })
			pp.CastShadow = false
			count += 1
			if d < (depth or 2) and r:NextNumber() < 0.45 then
				local bd = (dir + side * (r:NextNumber() - 0.5) * 2.2).Unit
				bd = (bd - n * bd:Dot(n)).Unit
				grow(nxt, bd, L * 0.45, sw * 0.7, d + 1)
			end
			cur = nxt
		end
	end
	grow(origin, up.Unit, len, o.w or 0.45, 0)
	return count
end

-- vein cluster on whatever wall/ceiling a ray from `from` (LOCAL point inside a room) along `dir` hits first.
-- rb = LOCAL room box {x0,y0,z0,x1,y1,z1}; growth is clamped to that box (minus 0.3 at floor/ceiling).
function NH.wallVein(par, rb, from, dir, len, seed, depth, o)
	o = o or {}
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { NH.root() }
	local w0 = from + V3(OX, 0, 0)
	local hit = workspace:Raycast(w0, dir.Unit * 40, rp)
	if not hit then return 0 end
	local n = hit.Normal
	local r = NH.rng(seed)
	local upv
	if math.abs(n.Y) > 0.7 then
		local a = r:NextNumber(0, math.pi * 2)
		upv = V3(math.cos(a), 0, math.sin(a))
	else
		local side = n:Cross(Vector3.yAxis).Unit
		upv = (Vector3.yAxis * (o.rise or r:NextNumber(0.3, 1)) + side * r:NextNumber(-1, 1)).Unit
	end
	local lo = V3(math.min(rb[1], rb[4]) + OX - 0.4, math.min(rb[2], rb[5]) + 0.3, math.min(rb[3], rb[6]) - 0.4)
	local hi = V3(math.max(rb[1], rb[4]) + OX + 0.4, math.max(rb[2], rb[5]) - 0.3, math.max(rb[3], rb[6]) + 0.4)
	lo = lo:Min(hit.Position - V3(0.6, 0.6, 0.6))
	hi = hi:Max(hit.Position + V3(0.6, 0.6, 0.6))
	return NH.veins(par, hit.Position, n, upv, len, seed, depth, { lo = lo, hi = hi, w = o.w })
end

-- fake door on a wall: base = WORLD CFrame at the wall surface (bottom centre of the opening), LookVector out of the
-- wall into the corridor. mode "closed" | "brick" (leaf swung open, brick behind) | "ajar". NOT Door-tagged.
function NH.fakeDoor(par, base, mode, col, leafDeg)
	local m = B.model(par, "FakeDoor")
	local w, h = 4.5, 8
	local sm = { small = true }
	local frame = NH.C.RootDark:Lerp(B.C.WoodDark, 0.6)
	-- frame (casing) proud of the wall
	B.rp(m, "Casing", base, V3(0.4, h + 0.4, 0.3), V3(-w / 2 - 0.2, (h + 0.4) / 2, -0.15), frame, M.Wood, sm)
	B.rp(m, "Casing", base, V3(0.4, h + 0.4, 0.3), V3(w / 2 + 0.2, (h + 0.4) / 2, -0.15), frame, M.Wood, sm)
	B.rp(m, "Casing", base, V3(w, 0.4, 0.3), V3(0, h + 0.2, -0.15), frame, M.Wood, sm)
	col = col or B.C.WoodMid:Lerp(NH.C.Tint, 0.4)
	if mode == "brick" then
		-- bricked-up opening (behind where the leaf was), leaf swung open 150 deg
		B.rp(m, "Bricks", base, V3(w, h, 0.12), V3(0, h / 2, -0.06), NH.C.Brick, M.Brick, { small = true })
		for i = 0, 3 do
			B.rp(m, "Mortar", base, V3(w, 0.08, 0.14), V3(0, 1 + i * 2, -0.07), NH.C.Mortar, M.Concrete, sm)
		end
		local hinge = base * CFrame.new(-w / 2 - 0.4, 0, -0.45) * CFrame.Angles(0, math.rad(leafDeg or 150), 0) -- swung wide open (150: sticks out 2.6 into the room)
		B.rp(m, "Leaf", hinge, V3(w - 0.1, h - 0.1, 0.25), V3(w / 2, h / 2, 0), col, M.Wood, { collide = true, query = false })
		B.ball(m, "Knob", hinge, 0.3, V3(w - 0.45, 3.6, -0.2), B.C.Brass, M.Metal, sm)
	elseif mode == "ajar" then
		B.rp(m, "Dark", base, V3(w, h, 0.1), V3(0, h / 2, -0.05), Color3.new(0, 0, 0), M.SmoothPlastic, { small = true })
		local hinge = base * CFrame.new(-w / 2, 0, -0.3) * CFrame.Angles(0, math.rad(22), 0) -- ajar leaf is decor (CanCollide false)
		B.rp(m, "Leaf", hinge, V3(w - 0.1, h - 0.1, 0.25), V3(w / 2, h / 2, 0), col, M.Wood, { small = true })
		B.ball(m, "Knob", hinge, 0.3, V3(w - 0.45, 3.6, -0.2), B.C.Brass, M.Metal, sm)
	else
		B.rp(m, "Leaf", base, V3(w - 0.1, h - 0.1, 0.2), V3(0, h / 2, -0.1), col, M.Wood, { small = true })
		B.rp(m, "Inset", base, V3(w - 1.3, 2.9, 0.06), V3(0, 5.6, -0.22), col:Lerp(B.C.Ink, 0.3), M.Wood, sm)
		B.rp(m, "Inset", base, V3(w - 1.3, 3.2, 0.06), V3(0, 1.9, -0.22), col:Lerp(B.C.Ink, 0.3), M.Wood, sm)
		B.ball(m, "Knob", base, 0.3, V3(w / 2 - 0.45, 3.6, -0.3), B.C.Brass, M.Metal, sm)
	end
	return m
end

-- parts that the code relies on must never be cut/deleted by the geometry helpers
local PROTECT = { Rooms = 1, LootSpawns = 1, PrizeSpawns = 1, SearchNodes = 1, Barriers = 1, PumpkinSpots = 1, PlayerSpawns = 1, Creaky = 1, MomsCar = 1 }
function NH.isProtected(p)
	local r = NH.root()
	local x = p
	while x and x ~= r do
		if PROTECT[x.Name] and x.Parent == r then return true end
		if CS:HasTag(x, "Door") or CS:HasTag(x, "HidingSpot") or CS:HasTag(x, "Searchable") or CS:HasTag(x, "Lamp") or CS:HasTag(x, "Breakable") then return true end
		if x.Name == "GrandmaChair" or x.Name == "GrandmaSleepSpot" or x.Name == "FuseBox" then return true end
		x = x.Parent
	end
	return false
end
function NH.aabb(d)
	local cf, s = d.CFrame, d.Size
	local e = V3(math.abs(cf.RightVector.X) * s.X / 2 + math.abs(cf.UpVector.X) * s.Y / 2 + math.abs(cf.LookVector.X) * s.Z / 2,
		math.abs(cf.RightVector.Y) * s.X / 2 + math.abs(cf.UpVector.Y) * s.Y / 2 + math.abs(cf.LookVector.Y) * s.Z / 2,
		math.abs(cf.RightVector.Z) * s.X / 2 + math.abs(cf.UpVector.Z) * s.Y / 2 + math.abs(cf.LookVector.Z) * s.Z / 2)
	return cf.Position - e, cf.Position + e
end
-- parts of the map whose world AABB overlaps a LOCAL box (manual scan: GetPartBoundsInBox skips CanQuery=false)
function NH.partsIn(x0, y0, z0, x1, y1, z1)
	local mn = V3(math.min(x0, x1) + OX, math.min(y0, y1), math.min(z0, z1))
	local mx = V3(math.max(x0, x1) + OX, math.max(y0, y1), math.max(z0, z1))
	local out = {}
	for _, d in NH.root():GetDescendants() do
		if d:IsA("BasePart") then
			local a, b = NH.aabb(d)
			if b.X > mn.X and a.X < mx.X and b.Y > mn.Y and a.Y < mx.Y and b.Z > mn.Z and a.Z < mx.Z then
				table.insert(out, d)
			end
		end
	end
	return out, mn, mx
end
-- cut an opening (LOCAL box) through every unprotected visible part it touches; parts fully inside are removed.
-- Also removes Window models whose centre is inside the box.
function NH.cut(x0, y0, z0, x1, y1, z1)
	local list, mn, mx = NH.partsIn(x0, y0, z0, x1, y1, z1)
	local cutN, delN = 0, 0
	for _, w in NH.root():GetDescendants() do
		if w:IsA("Model") and w.Name == "Window" and w.Parent then
			local c = w:GetBoundingBox().Position
			if c.X > mn.X - 0.8 and c.X < mx.X + 0.8 and c.Y > mn.Y and c.Y < mx.Y and c.Z > mn.Z - 0.8 and c.Z < mx.Z + 0.8 then
				w:Destroy()
				delN += 1
			end
		end
	end
	for _, p in list do
		if p.Parent and not NH.isProtected(p) and p.Transparency < 1 then
			local a, b = NH.aabb(p)
			if a.X >= mn.X - 0.01 and b.X <= mx.X + 0.01 and a.Y >= mn.Y - 0.01 and b.Y <= mx.Y + 0.01 and a.Z >= mn.Z - 0.01 and b.Z <= mx.Z + 0.01 then
				p:Destroy()
				delN += 1
			elseif p:IsA("Part") or p:IsA("UnionOperation") or p:IsA("WedgePart") then
				local cutter = B.cutter(mx - mn, CFrame.new((mn + mx) / 2))
				local fid = if p.CanCollide then Enum.CollisionFidelity.PreciseConvexDecomposition else Enum.CollisionFidelity.Box
				B.csg("sub", p, { cutter }, { fid = fid, usePartColor = if p:IsA("UnionOperation") then p.UsePartColor else true })
				cutN += 1
			end
		end
	end
	return cutN, delN
end
-- destroy unprotected decor models/parts whose bounding centre lies in a LOCAL box (under folder `within`)
function NH.clearIn(within, x0, y0, z0, x1, y1, z1, filter)
	local n = 0
	for _, c in within:GetChildren() do
		local pos
		if c:IsA("BasePart") then pos = c.Position elseif c:IsA("Model") then pos = c:GetBoundingBox().Position end
		if pos and not NH.isProtected(c) and (not filter or filter(c)) then
			local lx = pos.X - OX
			if lx > math.min(x0, x1) and lx < math.max(x0, x1) and pos.Y > math.min(y0, y1) and pos.Y < math.max(y0, y1) and pos.Z > math.min(z0, z1) and pos.Z < math.max(z0, z1) then
				c:Destroy()
				n += 1
			end
		end
	end
	return n
end

-- contract helpers (explicit NightmareHouse parent; HB's versions use workspace.House)
function NH.room(name, display, area, danger, x0, y0, z0, x1, y1, z1)
	local old = NH.F("Rooms"):FindFirstChild(name)
	if old then old:Destroy() end
	local p = NH.box(NH.F("Rooms"), name, x0, y0, z0, x1, y1, z1, B.C.Paper, M.SmoothPlastic, { inv = true })
	return B.attrs(p, { RoomName = display, Area = area, Danger = danger })
end
function NH.loot(area, danger, pos)
	local p = B.inv(NH.F("LootSpawns"), "LootSpawn", V3(0.8, 0.4, 0.8), CFrame.new(pos + V3(0, 0.35, 0)))
	return B.attrs(p, { Area = area, Danger = danger })
end
function NH.prize(area, pos)
	local p = B.inv(NH.F("PrizeSpawns"), "PrizeSpawn", V3(1.5, 0.4, 1.5), CFrame.new(pos + V3(0, 0.35, 0)))
	return B.attrs(p, { Area = area })
end
function NH.node(area, pos, bath)
	local p = B.inv(NH.F("SearchNodes"), "SearchNode", V3(1, 0.2, 1), CFrame.new(pos + V3(0, 0.1, 0)))
	B.attrs(p, { Area = area })
	if bath then p:SetAttribute("Bathroom", true) end
	return p
end
function NH.pumpkin(area, pos, face)
	local p = B.inv(NH.F("PumpkinSpots"), "PumpkinSpot", V3(1.5, 0.2, 1.5), B.cf(pos.X, pos.Y + 0.1, pos.Z, face))
	return B.attrs(p, { Area = area })
end
function NH.creak(pos, rot)
	local p = B.part(NH.F("Creaky"), "CreakyBoard", V3(4, 0.2, 4), CFrame.new(pos.X, pos.Y - 0.08, pos.Z) * CFrame.Angles(0, math.rad(rot or 0), 0), B.C.Creak:Lerp(NH.C.Tint, 0.3), M.WoodPlanks, { collide = true, touch = true, query = true, shadow = false })
	return B.tag(p, "Creaky")
end
-- sickly lamp (Lamp-tagged). kind as HB.lamp; red or purple light
function NH.lamp(par, kind, base, area, purple, o)
	o = o or {}
	o.color = if purple then NH.C.Purple else NH.C.Red
	o.shade = o.shade or NH.C.Velvet
	local l = B.lamp(par, kind, base, area, o)
	local bulb = l:FindFirstChild("Bulb")
	if bulb then bulb.Color = if purple then Color3.fromRGB(200, 150, 255) else Color3.fromRGB(255, 120, 120) end
	return l
end
function NH.count()
	local n = 0
	for _, d in NH.root():GetDescendants() do if d:IsA("BasePart") then n += 1 end end
	return n
end
return "NH lib ok"
