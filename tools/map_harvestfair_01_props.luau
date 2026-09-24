-- HarvestFair prop builders. Requires map_harvestfair_00_lib. Adds functions to _G.HF.
-- Adapted from tools/house_01_props (same conventions): base CFrame b sits on the floor at the footprint centre,
-- b.LookVector = the front of the prop. All coordinates are map-local.
local B = _G.HF
local C, M = B.C, B.M
local V = Vector3.new
local SM = { small = true }
local function R(m, n, b, sz, off, col, mat, o) return B.rp(m, n, b, sz, off, col, mat, o) end
local function dark(c, k) return c:Lerp(C.Ink, k or 0.35) end
B.dark = dark

function B.table(par, b, w, d, h, col, o)
	o = o or {}
	local m = B.model(par, o.name or "Table")
	R(m, "Top", b, V(w, 0.3, d), V(0, h - 0.15, 0), col, M.Wood, { solid = true })
	local lx, lz = w / 2 - 0.45, d / 2 - 0.45
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			R(m, "Leg", b, V(0.35, h - 0.3, 0.35), V(sx * lx, (h - 0.3) / 2, sz * lz), dark(col, 0.15), M.Wood)
		end
	end
	if o.cloth then
		R(m, "Cloth", b, V(w + 0.3, 0.05, d + 0.3), V(0, h + 0.025, 0), o.cloth, M.Fabric, SM)
		R(m, "ClothDrop", b, V(w + 0.3, h * 0.7, 0.05), V(0, h - h * 0.35, -d / 2 - 0.175), o.cloth, M.Fabric, SM)
	end
	return m, h + (if o.cloth then 0.05 else 0)
end
function B.chair(par, b, col)
	local m = B.model(par, "Chair")
	local sh = 1.9
	R(m, "Seat", b, V(1.9, 0.25, 1.9), V(0, sh, 0), col, M.Wood)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			R(m, "Leg", b, V(0.22, sh - 0.125, 0.22), V(sx * 0.8, (sh - 0.125) / 2, sz * 0.8), dark(col, 0.2), M.Wood, SM)
		end
		R(m, "Post", b, V(0.22, 2.6, 0.22), V(sx * 0.8, sh + 0.125 + 1.3, 0.8), dark(col, 0.2), M.Wood, SM)
	end
	R(m, "Back", b, V(1.38, 1.1, 0.15), V(0, sh + 1.9, 0.8), col, M.Wood, SM)
	return m
end
-- wing-back armchair (Grandma's). returns model, seat height
function B.armchair(par, b, fab, name, o)
	o = o or {}
	local m = B.model(par, name or "Armchair")
	local w, d = o.w or 5, o.d or 4.8
	local pip = o.trim or C.Gold
	local nc = { collide = false }
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			R(m, "Foot", b, V(0.4, 0.4, 0.4), V(sx * (w / 2 - 0.4), 0.2, sz * (d / 2 - 0.4)), C.WoodDark, M.Wood, SM)
		end
	end
	R(m, "Base", b, V(w - 0.2, 1.3, d - 0.2), V(0, 1.05, -0.1), fab, M.Fabric, nc)
	R(m, "Skirt", b, V(w + 0.1, 0.3, d + 0.1), V(0, 0.65, 0), pip, M.Fabric, SM)
	R(m, "Cushion", b, V(w - 1.7, 0.6, d - 1.2), V(0, 2.0, -0.4), fab:Lerp(C.Paper, 0.12), M.Fabric, nc)
	R(m, "Back", b, V(w, 5.0, 1.1), V(0, 3.5, d / 2 - 0.55), fab, M.Fabric)
	R(m, "BackTop", b, V(w - 0.6, 0.5, 1.0), V(0, 6.25, d / 2 - 0.55), fab, M.Fabric, SM)
	for _, sx in { -1, 1 } do
		R(m, "Arm", b, V(0.85, 1.3, d - 1.1), V(sx * (w / 2 - 0.425), 2.35, -0.55), fab, M.Fabric, nc)
		R(m, "ArmRoll", b, V(1.0, 0.35, d - 1.0), V(sx * (w / 2 - 0.425), 3.175, -0.55), pip, M.Fabric, SM)
		R(m, "Wing", b, V(0.7, 2.6, 1.8), V(sx * (w / 2 - 0.35), 4.6, d / 2 - 2.0), fab, M.Fabric, SM)
	end
	return m, 2.3
end
-- wardrobe / closet with an enclosed interior (HidingSpot). kind: Wardrobe/Closet/Cabinet
function B.wardrobe(par, b, col, area, kind, o)
	o = o or {}
	local m = B.model(par, o.name or kind)
	local w, d, h = o.w or 5.2, o.d or 3.8, o.h or 8.8
	R(m, "Back", b, V(w, h, 0.3), V(0, h / 2, d / 2 - 0.15), col, M.Wood)
	for _, sx in { -1, 1 } do
		R(m, "Side", b, V(0.3, h, d - 0.3), V(sx * (w / 2 - 0.15), h / 2, -0.15), col, M.Wood)
	end
	R(m, "Top", b, V(w - 0.6, 0.4, d - 0.3), V(0, h - 0.2, -0.15), col, M.Wood)
	R(m, "Crown", b, V(w + 0.4, 0.4, d + 0.2), V(0, h + 0.2, -0.1), dark(col), M.Wood, SM)
	R(m, "Plinth", b, V(w - 0.6, 0.5, d - 0.3), V(0, 0.25, -0.15), dark(col), M.Wood)
	local dc = o.doorColor or col
	local lw = (w - 0.6) / 2
	for _, sx in { -1, 1 } do
		local cx = sx * lw / 2
		R(m, "DoorLeaf", b, V(lw - 0.04, h - 0.9, 0.25), V(cx, 0.5 + (h - 0.9) / 2, -d / 2 + 0.125), dc, M.Wood)
		R(m, "Inset", b, V(lw - 0.8, h * 0.36, 0.06), V(cx, 0.5 + h * 0.62, -d / 2 - 0.03), dark(dc, 0.2), M.Wood, SM)
		R(m, "Inset", b, V(lw - 0.8, h * 0.28, 0.06), V(cx, 0.5 + h * 0.2, -d / 2 - 0.03), dark(dc, 0.2), M.Wood, SM)
		B.ball(m, "Knob", b, 0.28, V(sx * 0.35, 4.2, -d / 2 - 0.12), C.Brass, M.Metal, SM)
	end
	local inside = b * CFrame.new(0, 3.1, 0.2)
	B.hideParts(m, kind, area, inside, (b * CFrame.new(0, 0, -d / 2 - 2.1)).Position, (b * CFrame.new(0, 0, -d / 2 - 2)).Position)
	return m
end
function B.dresser(par, b, w, d, h, col, n, area, danger, o)
	o = o or {}
	local m = B.model(par, o.name or "Dresser")
	R(m, "Body", b, V(w, h - 0.3, d), V(0, (h - 0.3) / 2 + 0.3, 0), col, M.Wood)
	R(m, "Top", b, V(w + 0.3, 0.2, d + 0.2), V(0, h + 0.1, -0.05), dark(col, 0.25), M.Wood)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			R(m, "Foot", b, V(0.4, 0.3, 0.4), V(sx * (w / 2 - 0.3), 0.15, sz * (d / 2 - 0.3)), dark(col), M.Wood, SM)
		end
	end
	local dh = (h - 0.6) / n
	for i = 1, n do
		local y = h - 0.15 - dh * (i - 0.5)
		local f = R(m, "DrawerFront", b, V(w - 0.4, dh - 0.15, 0.15), V(0, y, -d / 2 - 0.075), dark(col, 0.1), M.Wood, { collide = false })
		B.ball(m, "Pull", b, 0.22, V(0, y, -d / 2 - 0.2), C.Brass, M.Metal, SM)
		if o.search and table.find(o.search, i) then
			f.Name = o.kind or "Drawer"
			B.searchable(f, o.kind or "Drawer", area, danger)
		end
	end
	return m, h + 0.2
end
function B.fridge(par, b, area, danger, col)
	local m = B.model(par, "Fridge")
	col = col or C.Mint:Lerp(C.Paper, 0.25)
	R(m, "Body", b, V(3, 6.4, 2.6), V(0, 3.2, 0.15), col, M.SmoothPlastic)
	local door = R(m, "FridgeDoor", b, V(2.9, 4, 0.3), V(0, 2.3, -1.3), col, M.SmoothPlastic, { collide = false })
	B.searchable(door, "Fridge", area, danger)
	R(m, "FreezerDoor", b, V(2.9, 2.0, 0.3), V(0, 5.35, -1.3), col, M.SmoothPlastic, { collide = false })
	R(m, "Handle", b, V(0.15, 1.6, 0.2), V(1.15, 3.4, -1.55), C.Metal, M.Metal, SM)
	R(m, "Magnet", b, V(0.3, 0.3, 0.06), V(-0.7, 3.6, -1.48), C.Blood, M.SmoothPlastic, SM)
	return m
end
function B.trunk(par, b, col, area, danger, o)
	o = o or {}
	local m = B.model(par, o.name or "Trunk")
	local w, d = o.w or 3.6, o.d or 2.2
	R(m, "Body", b, V(w, 1.6, d), V(0, 0.8, 0), col, M.Wood)
	local lid = R(m, "Lid", b, V(w + 0.1, 0.55, d + 0.1), V(0, 1.875, 0), dark(col, 0.1), M.Wood)
	B.searchable(lid, o.kind or "Trunk", area, danger)
	for _, x in { -w * 0.3, w * 0.3 } do
		R(m, "Band", b, V(0.25, 2.2, d + 0.2), V(x, 1.1, 0), C.Metal:Lerp(C.Ink, 0.3), M.Metal, SM)
	end
	R(m, "Latch", b, V(0.4, 0.5, 0.1), V(0, 1.6, -d / 2 - 0.1), C.Brass, M.Metal, SM)
	return m, lid
end
-- glass jar (Breakable) on a counter
function B.jarBreak(par, pos, col, s)
	s = s or 1
	local m = B.model(par, "GlassJar")
	local b = CFrame.new(pos)
	local body = B.cyl(m, "Body", b, 0.9 * s, 1.2 * s, V(0, 0.6 * s, 0), col, M.Glass, { collide = true, touch = true, query = true, tr = 0.25, shadow = false }, true)
	B.cyl(m, "Lid", b, 0.8 * s, 0.15, V(0, 1.2 * s + 0.075, 0), C.Brass, M.Metal, SM, true)
	for i = 1, 3 do
		B.ball(m, "Sweet", b, 0.3 * s, V(math.cos(i * 2) * 0.2, 0.25 * s + i * 0.15, math.sin(i * 2) * 0.2), ({ C.Rose, C.Mint, C.Mustard })[i], M.SmoothPlastic, SM)
	end
	m.PrimaryPart = body
	B.tag(m, "Breakable")
	return m
end
-- bottle pyramid (Breakable)
function B.bottles(par, b, col)
	local m = B.model(par, "BottlePyramid")
	local base
	local rows = { { -0.9, 0, 0.9 }, { -0.45, 0.45 }, { 0 } }
	for r, xs in rows do
		for _, x in xs do
			local p = B.cyl(m, "Bottle", b, 0.7, 1.3, V(x, (r - 1) * 1.3 + 0.65, 0), col or C.Mint:Lerp(C.Ink, 0.3), M.Glass, { collide = true, touch = true, query = true, tr = 0.2, shadow = false }, true)
			if not base then base = p end
		end
	end
	m.PrimaryPart = base
	B.tag(m, "Breakable")
	return m
end
function B.rug(par, x, y, z, w, d, col, border)
	B.box(par, "Rug", x - w / 2, y, z - d / 2, x + w / 2, y + 0.05, z + d / 2, border or dark(col, 0.3), M.Fabric, { small = true, collide = false })
	B.box(par, "RugField", x - w / 2 + 0.6, y + 0.05, z - d / 2 + 0.6, x + w / 2 - 0.6, y + 0.08, z + d / 2 - 0.6, col, M.Fabric, { small = true, collide = false })
end
function B.candleSet(par, pos, n, seed)
	for i = 1, n do
		local a = (i * 2.4 + (seed or 0))
		local r = 0.3 + (i % 3) * 0.25
		local h = 0.4 + ((i * 7) % 5) * 0.18
		local b = CFrame.new(pos + V(math.cos(a) * r, 0, math.sin(a) * r))
		B.cyl(par, "Candle", b, 0.25, h, V(0, h / 2, 0), C.Paper:Lerp(C.Mustard, 0.15), M.SmoothPlastic, SM, true)
		B.ball(par, "Flame", b, 0.14, V(0, h + 0.07, 0), Color3.fromRGB(255, 176, 90), M.Neon, SM)
	end
end
function B.pumpkinProp(par, pos, s, face)
	s = s or 1
	local m = B.model(par, "Pumpkin")
	local b = CFrame.new(pos)
	local body = B.ball(m, "Pumpkin", b, 1.6 * s, V(0, 0.75 * s, 0), C.Pumpkin:Lerp(C.Ink, ((pos.X * 7 + pos.Z * 3) % 5) * 0.05), M.SmoothPlastic, { collide = true, shadow = false })
	body.Size = V(1.9 * s, 1.5 * s, 1.9 * s)
	B.cyl(m, "Stem", b, 0.2 * s, 0.4 * s, V(0, 1.6 * s, 0), C.WoodMid, M.Wood, SM, true)
	if face then
		R(m, "Face", b, V(0.9 * s, 0.45 * s, 0.1), V(0, 0.8 * s, -0.7 * s), Color3.fromRGB(255, 160, 60), M.Neon, SM)
	end
	return m
end
-- hay bale (collidable, CanQuery for sightlines)
function B.hay(par, b, o)
	o = o or {}
	local sz = o.size or V(4, 2.2, 2.4)
	local p = R(par, "HayBale", b, sz, V(0, sz.Y / 2, 0), C.Hay:Lerp(C.WoodMid, o.tint or 0.1), M.Grass, { solid = true, shadow = true })
	R(par, "Twine", b, V(0.12, sz.Y + 0.04, sz.Z + 0.04), V(-sz.X * 0.28, sz.Y / 2, 0), C.WoodDark, M.Fabric, SM)
	R(par, "Twine", b, V(0.12, sz.Y + 0.04, sz.Z + 0.04), V(sz.X * 0.28, sz.Y / 2, 0), C.WoodDark, M.Fabric, SM)
	return p
end
function B.crate(par, b, s, col)
	s = s or 3
	local p = R(par, "Crate", b, V(s, s, s), V(0, s / 2, 0), col or C.WoodRaw, M.WoodPlanks, { solid = true })
	R(par, "Slat", b, V(s + 0.06, 0.3, s + 0.06), V(0, s * 0.5, 0), dark(col or C.WoodRaw, 0.25), M.Wood, SM)
	return p
end
function B.barrel(par, b, col)
	local p = B.cyl(par, "Barrel", b, 2.4, 3.2, V(0, 1.6, 0), col or C.WoodMid, M.Wood, { solid = true }, true)
	B.cyl(par, "Hoop", b, 2.5, 0.2, V(0, 0.6, 0), C.Metal, M.Metal, SM, true)
	B.cyl(par, "Hoop", b, 2.5, 0.2, V(0, 2.6, 0), C.Metal, M.Metal, SM, true)
	return p
end
-- plush prize bear
function B.bear(par, b, s, col)
	s = s or 1
	local m = B.model(par, "PrizeBear")
	col = col or C.Rose
	B.ball(m, "Body", b, 1.3 * s, V(0, 0.65 * s, 0), col, M.Fabric, SM)
	B.ball(m, "Head", b, 0.95 * s, V(0, 1.55 * s, 0), col, M.Fabric, SM)
	for _, sx in { -1, 1 } do
		B.ball(m, "Ear", b, 0.35 * s, V(sx * 0.35 * s, 1.95 * s, 0), col, M.Fabric, SM)
		R(m, "Eye", b, V(0.12 * s, 0.14 * s, 0.05), V(sx * 0.17 * s, 1.62 * s, -0.46 * s), C.Ink, M.SmoothPlastic, SM)
	end
	B.ball(m, "Snout", b, 0.4 * s, V(0, 1.45 * s, -0.4 * s), C.Paper, M.Fabric, SM)
	return m
end
function B.duck(par, pos, col)
	local b = CFrame.new(pos)
	B.ball(par, "Duck", b, 0.8, V(0, 0.3, 0), col or C.Mustard, M.SmoothPlastic, SM)
	B.ball(par, "DuckHead", b, 0.5, V(0, 0.8, -0.2), col or C.Mustard, M.SmoothPlastic, SM)
	R(par, "Beak", b, V(0.25, 0.12, 0.25), V(0, 0.78, -0.5), C.Pumpkin, M.SmoothPlastic, SM)
end
-- flat painted clown face (on a wall). wb = CFrame at the wall surface, LookVector out of the wall
function B.clownFace(par, wb, s, o)
	o = o or {}
	s = s or 1
	local m = B.model(par, "ClownFace")
	local skin = o.skin or C.Paper:Lerp(C.Sheet, 0.4)
	local function disc(n, d, off, col, mat)
		local o2 = V(off.X * s, off.Y * s, off.Z)
		local p = B.cyl(m, n, wb, d * s, 0.1, o2, col, mat or M.SmoothPlastic, SM, false)
		B.set(p, wb * CFrame.new(o2) * CFrame.Angles(0, math.rad(90), 0))
		return p
	end
	disc("Face", 5, V(0, 0, -0.05), skin)
	disc("HairL", 2.4, V(-2.5, 0.9, -0.03), o.hair or C.Rose)
	disc("HairR", 2.4, V(2.5, 0.9, -0.03), o.hair or C.Rose)
	disc("EyeL", 1.0, V(-0.9, 0.7, -0.12), C.Ink)
	disc("EyeR", 1.0, V(0.9, 0.7, -0.12), C.Ink)
	disc("Nose", 1.1, V(0, -0.1, -0.15), C.Blood)
	R(m, "Mouth", wb, V(2.6 * s, 0.5 * s, 0.1), V(0, -1.2 * s, -0.12), C.Blood:Lerp(C.Ink, 0.2), M.SmoothPlastic, SM)
	R(m, "MouthL", wb, V(0.6 * s, 0.5 * s, 0.1), V(-1.45 * s, -0.95 * s, -0.13), C.Blood:Lerp(C.Ink, 0.2), M.SmoothPlastic, SM, CFrame.Angles(0, 0, math.rad(30)))
	R(m, "MouthR", wb, V(0.6 * s, 0.5 * s, 0.1), V(1.45 * s, -0.95 * s, -0.13), C.Blood:Lerp(C.Ink, 0.2), M.SmoothPlastic, SM, CFrame.Angles(0, 0, math.rad(-30)))
	if o.eyeGlow then
		for _, sx in { -0.9, 0.9 } do
			disc("Pupil", 0.3, V(sx, 0.7, -0.18), o.eyeGlow, M.Neon)
		end
	end
	return m
end
-- wooden bench
function B.bench(par, b, w, col)
	local m = B.model(par, "Bench")
	col = col or C.WoodMid
	R(m, "Seat", b, V(w, 0.3, 1.6), V(0, 1.85, 0), col, M.Wood, { solid = true })
	R(m, "Back", b, V(w, 1.4, 0.25), V(0, 2.7, 0.75), col, M.Wood)
	for _, sx in { -1, 1 } do
		R(m, "Leg", b, V(0.3, 1.7, 1.4), V(sx * (w / 2 - 0.4), 0.85, 0), dark(col), M.Wood)
	end
	return m
end
-- prize shelves on a back wall (local frame: b at floor against wall, LookVector into booth)
function B.prizeShelf(par, b, w, seed)
	local m = B.model(par, "PrizeShelf")
	local cols = { C.Rose, C.Mint, C.Mustard, C.Bruise, C.Teal, C.Paper }
	for i, y in { 3.2, 5.4 } do
		R(m, "Shelf", b, V(w, 0.2, 1.2), V(0, y, 0), C.WoodMid, M.Wood, SM)
		local n = math.floor(w / 1.8)
		for k = 1, n do
			local x = -w / 2 + (k - 0.5) * (w / n)
			local bb = b * CFrame.new(x, y + 0.1, 0)
			local s = 0.6 + ((k + i + seed) % 3) * 0.08
			local col = cols[(k * 3 + i + seed) % #cols + 1]:Lerp(C.Ink, 0.15)
			B.ball(m, "Plush", bb, 1.3 * s, V(0, 0.65 * s, 0), col, M.Fabric, SM)
			B.ball(m, "PlushHead", bb, 0.95 * s, V(0, 1.55 * s, 0), col, M.Fabric, SM)
		end
	end
	return m
end
return "HF props ok"
