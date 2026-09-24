-- Sunny Pines props. Requires map_sunnypines_00_lib. Adds functions to _G.SPB.
-- Convention: base CFrame b sits on the floor at the footprint centre; b.LookVector = the front of the prop. LOCAL coords.
local B = _G.SPB
local C, M = B.C, B.M
local V = Vector3.new
local SM = { small = true }
local NC = { collide = false }
local function R(m, n, b, sz, off, col, mat, o) return B.rp(m, n, b, sz, off, col, mat, o) end
local function dark(c, k) return c:Lerp(C.Ink, k or 0.35) end
B.dark = dark

function B.table(par, b, w, d, h, col, o)
	o = o or {}
	local m = B.model(par, o.name or "Table")
	R(m, "Top", b, V(w, 0.25, d), V(0, h - 0.125, 0), col, o.mat or M.Wood)
	local lx, lz = w / 2 - 0.35, d / 2 - 0.35
	local lc = o.leg or C.Chrome
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			R(m, "Leg", b, V(0.2, h - 0.25, 0.2), V(sx * lx, (h - 0.25) / 2, sz * lz), lc, M.Metal, SM)
		end
	end
	if o.cloth then R(m, "Cloth", b, V(w + 0.1, 0.04, d + 0.1), V(0, h + 0.02, 0), o.cloth, M.Fabric, SM) end
	return m, h + (if o.cloth then 0.04 else 0)
end
function B.chair(par, b, col, o)
	o = o or {}
	local m = B.model(par, "Chair")
	local sh = 1.8
	R(m, "Seat", b, V(1.8, 0.25, 1.8), V(0, sh, 0), col, M.Fabric)
	for _, sx in { -1, 1 } do
		R(m, "Leg", b, V(0.15, sh, 0.15), V(sx * 0.75, sh / 2, -0.75), C.Chrome, M.Metal, SM)
		R(m, "Post", b, V(0.15, sh + 2.2, 0.15), V(sx * 0.75, (sh + 2.2) / 2, 0.75), C.Chrome, M.Metal, SM)
	end
	R(m, "Back", b, V(1.35, 1.1, 0.2), V(0, sh + 1.6, 0.78), col, M.Fabric, SM) -- between the posts
	return m
end
-- high-backed wipe-clean armchair / recliner. returns model, seat height
function B.armchair(par, b, fab, name, o)
	o = o or {}
	local m = B.model(par, name or "Armchair")
	local w, d = o.w or 4.6, o.d or 4.4
	R(m, "Base", b, V(w - 0.1, 1.6, d - 0.1), V(0, 0.8, 0), dark(fab, 0.15), M.Leather, NC)
	R(m, "Cushion", b, V(w - 1.6, 0.6, d - 1.1), V(0, 1.9, -0.35), fab:Lerp(C.Paper, 0.1), M.Leather, NC)
	R(m, "Back", b, V(w, 5.2, 1.1), V(0, 3.2, d / 2 - 0.55), fab, M.Leather)
	R(m, "Head", b, V(w - 1, 1.1, 0.9), V(0, 5.4, d / 2 - 1.1), fab:Lerp(C.Paper, 0.1), M.Leather, SM)
	for _, sx in { -1, 1 } do
		R(m, "Arm", b, V(0.8, 1.6, d), V(sx * (w / 2 - 0.4), 2.4, 0), fab, M.Leather, NC)
	end
	if o.footrest then
		R(m, "Footrest", b, V(w - 1.6, 0.4, 1.8), V(0, 1.5, -d / 2 - 0.9), fab, M.Leather, NC)
		R(m, "FootArm", b, V(0.2, 0.9, 1.2), V(0, 1.0, -d / 2 - 0.6), C.Metal, M.Metal, SM)
	end
	if o.doily then R(m, "Doily", b, V(2, 1, 0.05), V(0, 4.9, d / 2 - 1.12), C.Paper, M.Fabric, SM) end
	if o.throw then R(m, "Throw", b, V(1.0, 1.9, d * 0.7), V(-(w / 2 - 0.4), 2.7, 0.2), o.throw, M.Fabric, SM) end
	return m, 2.2
end
function B.sofa(par, b, w, fab, o)
	o = o or {}
	local m = B.model(par, o.name or "Sofa")
	local d = 3.4
	R(m, "Base", b, V(w, 1.2, d), V(0, 0.95, 0), fab, M.Fabric)
	R(m, "Back", b, V(w, 2.6, 0.9), V(0, 2.4, d / 2 - 0.45), fab, M.Fabric)
	for _, sx in { -1, 1 } do
		R(m, "Arm", b, V(0.7, 1.1, d), V(sx * (w / 2 - 0.35), 2.1, 0), fab, M.Fabric)
		R(m, "Foot", b, V(0.3, 0.35, 0.3), V(sx * (w / 2 - 0.4), 0.175, -(d / 2 - 0.4)), C.Chrome, M.Metal, SM)
	end
	R(m, "Cushions", b, V(w - 1.4, 0.45, d - 1.1), V(0, 1.77, -0.4), fab:Lerp(C.Paper, 0.12), M.Fabric, SM)
	return m
end
-- hospital bed, hiding spot underneath (Kind Bed). b faces the foot of the bed.
function B.hbed(par, b, area, o)
	o = o or {}
	local m = B.model(par, o.name or "HospitalBed")
	local w, l = 3.8, 7.6
	local sheet = o.sheet or C.PBlue
	R(m, "Frame", b, V(w, 0.4, l), V(0, 2.5, 0), C.Chrome, M.Metal)
	R(m, "Mattress", b, V(w - 0.2, 0.7, l - 0.4), V(0, 3.05, 0), C.Paper, M.Fabric)
	R(m, "Blanket", b, V(w + 0.1, 0.2, l * 0.62), V(0, 3.45, -l * 0.17), sheet, M.Fabric)
	R(m, "Pillow", b, V(w * 0.7, 0.5, 1.2), V(0, 3.6, l / 2 - 1), C.Paper, M.Fabric, SM)
	-- drapes of the blanket down both sides (the dark space underneath is the hiding spot)
	for _, sx in { -1, 1 } do
		R(m, "Drape", b, V(0.08, 2.35, l * 0.62), V(sx * (w / 2 + 0.06), 2.2, -l * 0.17), sheet, M.Fabric)
		R(m, "SideRail", b, V(0.12, 0.8, l * 0.4), V(sx * (w / 2 + 0.2), 4.0, l * 0.15), C.Chrome, M.Metal, SM)
	end
	R(m, "HeadBoard", b, V(w + 0.3, 3.2, 0.25), V(0, 3.2, l / 2 + 0.1), o.board or C.PPeach, M.SmoothPlastic)
	R(m, "FootBoard", b, V(w + 0.3, 1.8, 0.25), V(0, 3.0, -l / 2 - 0.1), o.board or C.PPeach, M.SmoothPlastic)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			R(m, "Leg", b, V(0.25, 2.1, 0.25), V(sx * (w / 2 - 0.2), 1.25, sz * (l / 2 - 0.2)), C.Chrome, M.Metal, SM)
			R(m, "Castor", b, V(0.3, 0.2, 0.4), V(sx * (w / 2 - 0.2), 0.1, sz * (l / 2 - 0.2)), C.Ink, M.Rubber, SM)
		end
	end
	R(m, "Chart", b, V(0.9, 1.1, 0.05), V(0.6, 3.3, -l / 2 - 0.26), C.Paper, M.SmoothPlastic, SM)
	local pos = (b * CFrame.new(0, 1.1, 0.6)).Position
	local inside = CFrame.fromMatrix(pos, b.RightVector, b.LookVector)
	B.hideParts(m, "Bed", area, inside, (b * CFrame.new(0, 0, -l / 2 - 2)).Position, (b * CFrame.new(1.2, 0, -l / 2 - 2.1)).Position)
	return m
end
-- wardrobe/linen cupboard with an enclosed interior. kind: Wardrobe/Closet/Cabinet
function B.wardrobe(par, b, col, area, kind, o)
	o = o or {}
	local m = B.model(par, o.name or kind)
	local w, d, h = o.w or 5.2, 3.8, o.h or 8.6
	R(m, "Back", b, V(w, h, 0.3), V(0, h / 2, d / 2 - 0.15), col, M.Wood)
	for _, sx in { -1, 1 } do
		R(m, "Side", b, V(0.3, h, d), V(sx * (w / 2 - 0.15), h / 2, 0), col, M.Wood)
	end
	R(m, "Top", b, V(w, 0.4, d), V(0, h - 0.2, 0), col, M.Wood)
	R(m, "Plinth", b, V(w - 0.6, 0.5, d - 0.3), V(0, 0.25, -0.15), dark(col), M.Wood) -- inside the carcass
	local dc = o.doorColor or col
	local lw = (w - 0.1) / 2
	for _, sx in { -1, 1 } do
		local cx = sx * lw / 2
		R(m, "DoorLeaf", b, V(lw - 0.04, h - 0.9, 0.25), V(cx, 0.5 + (h - 0.9) / 2, -d / 2 + 0.125), dc, M.Wood)
		if o.louvre then
			for i = 1, 5 do
				R(m, "Louvre", b, V(lw - 0.7, 0.12, 0.08), V(cx, 1.4 + i * 1.1, -d / 2 - 0.03), dark(dc, 0.25), M.Wood, SM)
			end
		end
		R(m, "Knob", b, V(0.15, 0.6, 0.12), V(sx * 0.3, 4.2, -d / 2 - 0.06), C.Chrome, M.Metal, SM)
	end
	if o.label then
		local lp = R(m, "Label", b, V(2.4, 0.5, 0.04), V(0, h - 0.9, -d / 2 - 0.02), C.Paper, M.SmoothPlastic, SM)
		B.text(lp, Enum.NormalId.Front, o.label, C.Ink, Enum.Font.FredokaOne)
	end
	local inside = b * CFrame.new(0, 3.1, 0.2)
	B.hideParts(m, kind, area, inside, (b * CFrame.new(0, 0, -d / 2 - 2.1)).Position, (b * CFrame.new(0, 0, -d / 2 - 2)).Position)
	return m
end
-- bedside cabinet: top drawer searchable (Drawer). returns model, top height
function B.bedside(par, b, col, area, danger, search)
	local m = B.model(par, "BedsideCabinet")
	R(m, "Body", b, V(1.9, 2.5, 1.8), V(0, 1.25, 0), col, M.Wood)
	R(m, "Top", b, V(2.0, 0.1, 1.9), V(0, 2.55, 0), dark(col, 0.2), M.Wood, SM)
	local f = R(m, "DrawerFront", b, V(1.7, 0.7, 0.1), V(0, 2.0, -0.95), dark(col, 0.08), M.Wood, NC)
	R(m, "Pull", b, V(0.6, 0.1, 0.1), V(0, 2.0, -1.05), C.Chrome, M.Metal, SM)
	R(m, "CabDoor", b, V(1.7, 1.3, 0.1), V(0, 0.9, -0.95), dark(col, 0.08), M.Wood, SM)
	if search ~= false then
		f.Name = "Drawer"
		B.searchable(f, "Drawer", area, danger)
	end
	return m, 2.6
end
-- filing cabinet (n drawers, drawer `si` searchable)
function B.filing(par, b, n, area, danger, si, col)
	local m = B.model(par, "FilingCabinet")
	col = col or C.PGreen:Lerp(C.Metal, 0.4)
	local h = n * 1.3 + 0.2
	R(m, "Body", b, V(1.9, h, 2.4), V(0, h / 2, 0), col, M.Metal)
	for i = 1, n do
		local y = h - 0.1 - 1.3 * (i - 0.5)
		local f = R(m, "DrawerFront", b, V(1.7, 1.15, 0.1), V(0, y, -1.24), dark(col, 0.1), M.Metal, NC)
		R(m, "Pull", b, V(0.7, 0.12, 0.1), V(0, y + 0.2, -1.33), C.Chrome, M.Metal, SM)
		if si and i == si then
			f.Name = "Drawer"
			B.searchable(f, "Drawer", area, danger)
		end
	end
	return m, h
end
-- staff lockers (n doors, index list `si` searchable Cabinet)
function B.lockers(par, b, n, area, danger, si, col)
	local m = B.model(par, "Lockers")
	col = col or C.PBlue:Lerp(C.Metal, 0.3)
	local w = n * 1.6
	R(m, "Body", b, V(w, 7, 1.9), V(0, 3.5, 0), col, M.Metal)
	for i = 1, n do
		local x = -w / 2 + 1.6 * (i - 0.5)
		local d = R(m, "LockerDoor", b, V(1.5, 6.6, 0.1), V(x, 3.5, -1.0), dark(col, 0.08), M.DiamondPlate, NC)
		R(m, "Vent", b, V(0.9, 0.5, 0.06), V(x, 6.2, -1.07), dark(col, 0.35), M.Metal, SM)
		if si and table.find(si, i) then
			d.Name = "Cabinet"
			B.searchable(d, "Cabinet", area, danger)
		end
	end
	return m
end
-- kitchen base counter run along local X
function B.counter(par, b, len, col, top, area, danger, search, o)
	o = o or {}
	local m = B.model(par, o.name or "Counter")
	local d, h = 2.6, 3.4
	R(m, "Body", b, V(len, h - 0.5, d - 0.2), V(0, (h - 0.5) / 2 + 0.4, 0.1), col, M.Wood)
	R(m, "Toe", b, V(len, 0.4, d - 0.5), V(0, 0.2, 0.25), C.Ink, M.SmoothPlastic, SM)
	R(m, "Countertop", b, V(len + 0.2, 0.3, d + 0.2), V(0, h - 0.05, 0), top, o.topMat or M.Metal)
	local n = math.max(1, math.floor(len / 2.5 + 0.5))
	local cw = len / n
	for i = 1, n do
		local x = -len / 2 + cw * (i - 0.5)
		local kind = search and search[i]
		local door = R(m, "CabDoor", b, V(cw - 0.25, 1.9, 0.12), V(x, 1.5, -d / 2 - 0.06), dark(col, 0.05), M.Wood, NC)
		local drw = R(m, "DrawerFront", b, V(cw - 0.25, 0.6, 0.12), V(x, 2.85, -d / 2 - 0.06), dark(col, 0.05), M.Wood, NC)
		R(m, "Pull", b, V(0.5, 0.1, 0.1), V(x, 2.85, -d / 2 - 0.16), C.Chrome, M.Metal, SM)
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
function B.fridge(par, b, area, danger, o)
	o = o or {}
	local m = B.model(par, o.name or "Fridge")
	local w = o.w or 3.4
	local col = C.Chrome:Lerp(C.Paper, 0.3)
	R(m, "Body", b, V(w, 7.4, 2.8), V(0, 3.7, 0.2), col, M.Metal)
	local door = R(m, "FridgeDoor", b, V(w - 0.1, 7.1, 0.25), V(0, 3.75, -1.33), col:Lerp(C.Ink, 0.05), M.Metal, NC)
	B.searchable(door, "Fridge", area, danger)
	R(m, "Handle", b, V(0.15, 2.2, 0.25), V(w / 2 - 0.4, 4, -1.55), C.Metal, M.Metal, SM)
	local note = R(m, "Note", b, V(1.4, 0.9, 0.03), V(-0.3, 5.4, -1.47), C.Paper, M.SmoothPlastic, SM)
	B.text(note, Enum.NormalId.Front, o.note or "NO SECONDS\n- Cook", C.Blood, Enum.Font.PatrickHand)
	return m
end
function B.stove(par, b)
	local m = B.model(par, "Range")
	R(m, "Body", b, V(4.2, 3.3, 2.6), V(0, 1.65, 0), C.Chrome, M.Metal)
	R(m, "OvenDoor", b, V(3.4, 1.7, 0.12), V(0, 1.4, -1.33), C.Chrome:Lerp(C.Ink, 0.15), M.Metal, SM)
	R(m, "Hob", b, V(4.1, 0.08, 2.4), V(0, 3.34, 0), C.Ink, M.Metal, SM)
	R(m, "Pot", b, V(1.2, 1.0, 1.2), V(-1, 3.88, -0.2), C.Metal, M.Metal, SM)
	R(m, "Hood", b, V(4.6, 1.4, 2.4), V(0, 9.5, 0.2), C.Chrome, M.Metal, SM)
	return m
end
-- CRT TV on a trolley, tagged Lamp (screen = Bulb)
function B.tv(par, b, area)
	local m = B.model(par, "TV_Trolley")
	R(m, "Trolley", b, V(4, 0.2, 2.4), V(0, 2.4, 0), C.Chrome, M.Metal)
	R(m, "Shelf", b, V(4, 0.2, 2.4), V(0, 0.6, 0), C.Chrome, M.Metal, SM)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			R(m, "Post", b, V(0.15, 2.5, 0.15), V(sx * 1.9, 1.25, sz * 1.1), C.Chrome, M.Metal, SM)
		end
	end
	R(m, "VCR", b, V(2.6, 0.5, 1.6), V(0, 0.95, 0), C.Ink, M.SmoothPlastic, SM)
	R(m, "Box", b, V(3.6, 3, 2.4), V(0, 4.0, 0.1), C.WoodMid, M.Wood)
	local scr = R(m, "Bulb", b, V(2.6, 2.1, 0.1), V(-0.3, 4.0, -1.13), Color3.fromRGB(110, 130, 160), M.Neon, SM)
	local sl = Instance.new("SurfaceLight")
	sl.Face = Enum.NormalId.Front
	sl.Color = Color3.fromRGB(170, 190, 230)
	sl.Brightness = 1.6
	sl.Range = 16
	sl.Angle = 100
	sl.Parent = scr
	R(m, "Dials", b, V(0.5, 1.6, 0.06), V(1.4, 4.1, -1.12), C.Brass, M.Metal, SM)
	m.PrimaryPart = scr
	B.attrs(m, { Area = area })
	B.tag(m, "Lamp")
	return m
end
function B.shelf(par, b, w, h, col, o)
	o = o or {}
	local m = B.model(par, o.name or "Shelf")
	local d = o.d or 1.6
	R(m, "Back", b, V(w - 0.4, h, 0.15), V(0, h / 2, d / 2 - 0.08), dark(col, 0.2), M.Wood) -- between the sides
	for _, sx in { -1, 1 } do
		R(m, "Side", b, V(0.2, h, d), V(sx * (w / 2 - 0.1), h / 2, 0), col, M.Wood)
	end
	local n = o.shelves or 4
	local pal = o.pal or { C.Rose, C.PMint, C.Mustard, C.Bruise, C.Paper, C.PBlue }
	for i = 0, n do
		local y = 0.3 + (h - 0.6) * i / n
		R(m, "Board", b, V(w - 0.3, 0.15, d - 0.1), V(0, y, 0), col, M.Wood, SM)
		if i < n and not o.empty then
			local bh = (h - 0.6) / n * 0.62
			local k = (i + (o.seed or 0)) % 3
			local gw = (w - 0.6) * (0.35 + k * 0.15)
			R(m, "Stuff", b, V(gw, bh, d * 0.7), V(-w / 2 + 0.3 + gw / 2, y + 0.08 + bh / 2, 0.05), dark(pal[(i + (o.seed or 0)) % #pal + 1], 0.3), o.stuffMat or M.Fabric, SM)
			if k ~= 1 then
				local gw2 = (w - 0.6) * 0.25
				R(m, "Stuff", b, V(gw2, bh * 0.8, d * 0.6), V(w / 2 - 0.4 - gw2 / 2, y + 0.08 + bh * 0.4, 0.05), dark(pal[(i + 2 + (o.seed or 0)) % #pal + 1], 0.3), o.stuffMat or M.Cardboard, SM)
			end
		end
	end
	return m
end
-- picture on a wall. wb = CFrame at the wall surface, LookVector out of the wall
function B.picture(par, wb, w, h, o)
	o = o or {}
	local m = B.model(par, o.name or "Picture")
	R(m, "Frame", wb, V(w, h, 0.15), V(0, 0, -0.075), o.frame or C.WoodDark, M.Wood, SM)
	R(m, "Canvas", wb, V(w - 0.4, h - 0.4, 0.04), V(0, 0, -0.17), o.canvas or C.PBlue, M.Fabric, SM)
	if o.portrait then
		local ph = h - 0.4
		R(m, "Shoulders", wb, V((w - 0.4) * 0.7, ph * 0.3, 0.03), V(0, -ph * 0.35, -0.2), o.clothes or C.Night, M.Fabric, SM)
		local hd = math.min(w, h) * 0.34
		R(m, "Head", wb, V(hd, hd * 1.15, 0.03), V(0, ph * 0.04, -0.2), o.skin or C.Paper:Lerp(C.Rose, 0.2), M.SmoothPlastic, SM)
		R(m, "Hair", wb, V(hd * 1.15, hd * 0.45, 0.05), V(0, ph * 0.04 + hd * 0.5, -0.225), o.hair or C.Sheet, M.Fabric, SM)
		if o.eyes then
			for _, sx in { -1, 1 } do
				R(m, "Eye", wb, V(hd * 0.16, hd * 0.1, 0.03), V(sx * hd * 0.2, ph * 0.07, -0.225), o.eyes, M.Neon, SM)
			end
		end
	elseif o.scene then
		R(m, "Hill", wb, V(w - 0.45, (h - 0.4) * 0.4, 0.03), V(0, -(h - 0.4) * 0.3, -0.2), o.scene, M.Fabric, SM)
	end
	return m
end
-- a flat sign with text on a wall (wb LookVector out of the wall)
function B.sign(par, wb, w, h, txt, bg, fg, font, o)
	o = o or {}
	local p = B.rp(par, o.name or "Sign", wb, V(w, h, 0.08), V(0, 0, -0.04), bg or C.Paper, o.mat or M.SmoothPlastic, SM)
	B.text(p, Enum.NormalId.Front, txt, fg or C.Ink, font or Enum.Font.FredokaOne, o)
	return p
end
function B.vase(par, b, col, s)
	s = s or 1
	local m = B.model(par, "Vase")
	local body = B.cyl(m, "Body", b, 0.9 * s, 1.3 * s, V(0, 0.65 * s, 0), col, M.Glass, { collide = true, touch = true, query = true, shadow = false }, true)
	B.ball(m, "Flowers", b, 0.9 * s, V(0, 1.6 * s, 0), C.Rose:Lerp(C.Mustard, 0.3), M.Fabric, SM)
	m.PrimaryPart = body
	B.tag(m, "Breakable")
	return m
end
-- tray of crockery (Breakable model)
function B.crockery(par, b)
	local m = B.model(par, "CrockeryTray")
	local tray = R(m, "Tray", b, V(2.2, 0.12, 1.5), V(0, 0.06, 0), C.Chrome, M.Metal, { collide = true, touch = true, query = true, shadow = false })
	B.cyl(m, "Cups", b, 0.45, 0.45, V(-0.6, 0.345, -0.3), C.PMint, M.SmoothPlastic, SM, true)
	B.cyl(m, "Cups", b, 0.45, 0.45, V(-0.6, 0.345, 0.3), C.PPink, M.SmoothPlastic, SM, true)
	B.cyl(m, "Plates", b, 1.0, 0.36, V(0.4, 0.3, 0), C.Paper, M.SmoothPlastic, SM, true)
	m.PrimaryPart = tray
	B.tag(m, "Breakable")
	return m
end
function B.rug(par, x, y, z, w, d, col, border)
	B.box(par, "Rug", x - w / 2, y, z - d / 2, x + w / 2, y + 0.06, z + d / 2, border or dark(col, 0.3), M.Fabric, { small = true, collide = false })
	B.box(par, "RugField", x - w / 2 + 0.5, y, z - d / 2 + 0.5, x + w / 2 - 0.5, y + 0.08, z + d / 2 - 0.5, col, M.Fabric, { small = true, collide = false })
end
-- fake potted plant
function B.plant(par, b, s)
	s = s or 1
	local m = B.model(par, "FakePlant")
	B.cyl(m, "Pot", b, 1.4 * s, 1.4 * s, V(0, 0.7 * s, 0), C.PPeach:Lerp(C.Ink, 0.2), M.SmoothPlastic, { collide = true }, true)
	B.ball(m, "Leaves", b, 2.4 * s, V(0, 2.4 * s, 0), C.PGreen:Lerp(C.Ink, 0.25), M.Plastic, SM)
	B.ball(m, "Leaves", b, 1.7 * s, V(0.5 * s, 3.4 * s, 0.2), C.PGreen:Lerp(C.Mint, 0.3), M.Plastic, SM)
	return m
end
-- wheelchair (decor, collidable body)
function B.wheelchair(par, b)
	local m = B.model(par, "Wheelchair")
	R(m, "Seat", b, V(2, 0.2, 1.9), V(0, 1.9, 0), C.Night, M.Leather)
	R(m, "Back", b, V(2, 2, 0.15), V(0, 3.0, 0.95), C.Night, M.Leather)
	R(m, "Collider", b, V(2.4, 1.8, 2.2), V(0, 0.9, 0), C.Paper, M.SmoothPlastic, { inv = true, collide = true })
	for _, sx in { -1, 1 } do
		B.cyl(m, "Wheel", b, 2.7, 0.15, V(sx * 1.15, 1.35, 0.2), C.Chrome, M.Metal, SM, false)
		B.cyl(m, "Castor", b, 0.6, 0.12, V(sx * 0.8, 0.3, -0.9), C.Ink, M.Rubber, SM, false)
		R(m, "Arm", b, V(0.15, 0.1, 1.6), V(sx * 1.0, 2.7, 0.1), C.Chrome, M.Metal, SM)
		R(m, "FootPlate", b, V(0.7, 0.08, 0.6), V(sx * 0.5, 0.6, -1.1), C.Chrome, M.Metal, SM)
	end
	return m
end
-- laundry cart hiding spot (Kind Cabinet): canvas bin on castors, heaped with sheets
function B.cart(par, b, area, o)
	o = o or {}
	local m = B.model(par, o.name or "LaundryCart")
	local col = o.col or C.PBlue:Lerp(C.Ink, 0.15)
	local w, d, h = 4.4, 3.4, 4.2
	R(m, "Bottom", b, V(w, 0.2, d), V(0, 0.6, 0), col, M.Fabric)
	for _, sx in { -1, 1 } do
		R(m, "Side", b, V(0.15, h - 0.5, d), V(sx * (w / 2 - 0.075), 0.5 + (h - 0.5) / 2, 0), col, M.Fabric)
		R(m, "End", b, V(w, h - 0.5, 0.15), V(0, 0.5 + (h - 0.5) / 2, sx * (d / 2 - 0.075)), col, M.Fabric)
		for _, sz in { -1, 1 } do
			R(m, "Castor", b, V(0.4, 0.5, 0.4), V(sx * (w / 2 - 0.3), 0.25, sz * (d / 2 - 0.3)), C.Ink, M.Rubber, SM)
		end
	end
	R(m, "Rim", b, V(w + 0.1, 0.15, d + 0.1), V(0, h + 0.05, 0), C.Chrome, M.Metal, SM)
	R(m, "Sheets", b, V(w - 0.3, 0.9, d - 0.3), V(0, h - 0.1, 0), C.Sheet, M.Fabric, SM)
	R(m, "Sheets", b, V(w * 0.5, 0.7, d * 0.6), V(-0.5, h + 0.5, 0.2), C.Paper, M.Fabric, SM)
	local inside = b * CFrame.new(0, 2.0, 0)
	B.hideParts(m, "Cabinet", area, inside, (b * CFrame.new(0, 0, -d / 2 - 2)).Position, (b * CFrame.new(0, 0, -d / 2 - 2)).Position)
	return m
end
-- privacy-curtain cubicle hiding spot (Kind Closet): ceiling rail + three curtain sides + front curtain. 5x5
function B.cubicle(par, b, area, ceilH, o)
	o = o or {}
	local m = B.model(par, o.name or "CurtainCubicle")
	local s = 5
	local col = o.col or C.PMint:Lerp(C.Paper, 0.2)
	local ch = 7.6
	for _, sx in { -1, 1 } do
		R(m, "Curtain", b, V(0.12, ch, s - 0.12), V(sx * s / 2, 0.3 + ch / 2, 0), col, M.Fabric)
	end
	R(m, "Curtain", b, V(s, ch, 0.12), V(0, 0.3 + ch / 2, s / 2), col, M.Fabric)
	R(m, "CurtainFront", b, V(s, ch, 0.12), V(0, 0.3 + ch / 2, -s / 2), col:Lerp(C.Ink, 0.05), M.Fabric)
	R(m, "Rail", b, V(s + 0.2, 0.15, s + 0.2), V(0, 0.3 + ch + 0.15, 0), C.Chrome, M.Metal, SM)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			R(m, "Hanger", b, V(0.08, ceilH - ch - 0.6, 0.08), V(sx * s / 2, 0.3 + ch + 0.15 + (ceilH - ch - 0.6) / 2, sz * s / 2), C.Chrome, M.Metal, SM)
		end
	end
	R(m, "Commode", b, V(1.8, 1.8, 1.8), V(0, 0.9, 1.2), C.PBlue, M.SmoothPlastic, NC)
	local inside = b * CFrame.new(0, 3.1, 0.2)
	B.hideParts(m, "Closet", area, inside, (b * CFrame.new(0, 0, -s / 2 - 2)).Position, (b * CFrame.new(0, 0, -s / 2 - 1.8)).Position)
	return m
end
-- phone booth hiding spot (Kind Closet)
function B.booth(par, b, area)
	local m = B.model(par, "PhoneBooth")
	local w, d, h = 4, 4, 8.6
	local col = C.Blood:Lerp(C.PPink, 0.35)
	R(m, "Back", b, V(w, h, 0.3), V(0, h / 2, d / 2 - 0.15), col, M.Wood)
	for _, sx in { -1, 1 } do
		R(m, "Side", b, V(0.3, h, d), V(sx * (w / 2 - 0.15), h / 2, 0), col, M.Wood)
	end
	R(m, "Roof", b, V(w + 0.3, 0.5, d + 0.3), V(0, h + 0.25, 0), col:Lerp(C.Ink, 0.3), M.Wood)
	R(m, "Base", b, V(w - 0.6, 0.3, d - 0.3), V(0, 0.15, -0.15), col:Lerp(C.Ink, 0.3), M.Wood)
	R(m, "DoorLeaf", b, V(w - 0.65, h - 0.7, 0.2), V(0, 0.35 + (h - 0.7) / 2, -d / 2 + 0.15), col, M.Wood)
	R(m, "DoorGlass", b, V(w - 1.5, h * 0.5, 0.05), V(0, h * 0.58, -d / 2 + 0.02), C.Glass, M.Glass, { small = true, tr = 0.35 })
	local sg = R(m, "Header", b, V(w - 0.6, 0.6, 0.05), V(0, h - 0.4, -d / 2 + 0.02), C.Paper, M.SmoothPlastic, SM)
	B.text(sg, Enum.NormalId.Front, "TELEPHONE", C.Ink, Enum.Font.FredokaOne)
	R(m, "Phone", b, V(1.0, 1.4, 0.5), V(0, 4.6, d / 2 - 0.55), C.Ink, M.Metal, SM)
	local inside = b * CFrame.new(0, 3.1, 0.2)
	B.hideParts(m, "Closet", area, inside, (b * CFrame.new(0, 0, -d / 2 - 2.1)).Position, (b * CFrame.new(0, 0, -d / 2 - 2)).Position)
	return m
end
function B.washer(par, b, col)
	local m = B.model(par, "WashingMachine")
	col = col or C.Paper:Lerp(C.Metal, 0.2)
	R(m, "Body", b, V(3, 3.6, 2.8), V(0, 1.8, 0), col, M.Metal)
	B.cyl(m, "Porthole", b, 1.9, 0.12, V(0, 1.6, -1.42), C.Chrome, M.Metal, SM, false).CFrame = B.W * b * CFrame.new(0, 1.6, -1.42) * CFrame.Angles(0, math.rad(90), 0)
	B.cyl(m, "Glass", b, 1.4, 0.12, V(0, 1.6, -1.47), C.Glass:Lerp(C.Ink, 0.3), M.Glass, SM, false).CFrame = B.W * b * CFrame.new(0, 1.6, -1.47) * CFrame.Angles(0, math.rad(90), 0)
	R(m, "Panel", b, V(3, 0.5, 0.1), V(0, 3.2, -1.44), dark(col, 0.2), M.Metal, SM)
	return m, 3.6
end
function B.boiler(par, b)
	local m = B.model(par, "Boiler")
	local col = C.Blood:Lerp(C.Ink, 0.35)
	B.cyl(m, "Tank", b, 6, 8, V(0, 5, 0), col, M.Metal, { solid = true }, true)
	R(m, "Plinth", b, V(6.6, 1, 6.6), V(0, 0.5, 0), C.Concrete, M.Concrete)
	R(m, "Firebox", b, V(3, 2.4, 0.4), V(0, 2.4, -3.05), C.Ink, M.Metal, SM)
	local glow = R(m, "Glow", b, V(2.2, 0.5, 0.05), V(0, 2.0, -3.28), Color3.fromRGB(255, 120, 50), M.Neon, SM)
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 120, 60)
	l.Range = 12
	l.Brightness = 0.8
	l.Parent = glow
	B.cyl(m, "Gauge", b, 0.9, 0.12, V(1.8, 6, -2.7), C.Paper, M.SmoothPlastic, SM, false).CFrame = B.W * b * CFrame.new(1.6, 6, -2.6) * CFrame.Angles(0, math.rad(90), 0) -- sits on the tank (radius 3)
	B.cyl(m, "Flue", b, 1.4, 3, V(0, 10.5, 0), C.Metal, M.Metal, SM, true)
	return m
end
-- chain-link storage cage wall segment along local X (length len) with posts; transparent mesh look
function B.cageWall(par, p0, p1, h, gaps)
	local m = B.model(par, "Cage")
	local d = p1 - p0
	local len = d.Magnitude
	local dir = d.Unit
	local cf0 = CFrame.lookAt(p0, p0 + dir) -- local -Z along the wall
	local cur = 0
	table.sort(gaps or {}, function(a, b) return a[1] < b[1] end)
	local segs = {}
	for _, g in gaps or {} do
		table.insert(segs, { cur, g[1] - g[2] / 2 })
		cur = g[1] + g[2] / 2
	end
	table.insert(segs, { cur, len })
	for _, s in segs do
		local a, bb = s[1], s[2]
		if bb - a > 0.1 then
			-- mesh stops 0.02 inside the posts at both ends (no coplanar faces)
			local mesh = B.part(m, "Mesh", V(0.1, h, bb - a - 0.04), cf0 * CFrame.new(0, h / 2, -(a + bb) / 2), C.Metal, M.DiamondPlate, { solid = true, tr = 0.55, shadow = false })
			mesh.CanQuery = true
			for _, t in { a, bb } do
				t = math.clamp(t, 0.125, len - 0.125)
				B.part(m, "Post", V(0.25, h + 0.05, 0.25), cf0 * CFrame.new(0, (h + 0.05) / 2, -t), C.Metal:Lerp(C.Ink, 0.3), M.Metal, SM)
			end
		end
	end
	B.part(m, "TopBar", V(0.2, 0.2, len), cf0 * CFrame.new(0, h, -len / 2), C.Metal:Lerp(C.Ink, 0.3), M.Metal, SM)
	return m
end
-- pine tree (stacked pyramids from CornerWedges)
function B.pine(par, x, z, s)
	s = s or 1
	local m = B.model(par, "Pine")
	B.part(m, "Trunk", V(1.2 * s, 5 * s, 1.2 * s), CFrame.new(x, 2.5 * s, z), C.WoodDark, M.Wood, { solid = true })
	for i, t in { { 9, 5, 3 }, { 7, 4.5, 6.5 }, { 4.6, 4, 9.6 } } do
		local w, h, y = t[1] * s / 2, t[2] * s, t[3] * s
		for k = 0, 3 do
			local rot = CFrame.Angles(0, math.rad(90 * k), 0)
			B.part(m, "Needles", V(w, h, w), CFrame.new(x, y + h / 2, z) * rot * CFrame.new(w / 2, 0, w / 2) * CFrame.Angles(0, math.rad(180), 0), C.Pine:Lerp(C.Ink, (i % 2) * 0.1), M.Grass, { small = true, class = "CornerWedgePart", shadow = true })
		end
	end
	return m
end
-- fish tank on a cabinet: Lamp (Bulb = the tank light strip)
function B.fishtank(par, b, area)
	local m = B.model(par, "FishTank")
	R(m, "Stand", b, V(6, 2.8, 2.2), V(0, 1.4, 0), C.WoodMid, M.Wood)
	R(m, "Water", b, V(5.8, 2.6, 2.0), V(0, 4.1, 0), Color3.fromRGB(60, 120, 130), M.Glass, { small = true, tr = 0.35 })
	R(m, "Gravel", b, V(5.7, 0.4, 1.9), V(0, 3.0, 0), C.PPeach:Lerp(C.Ink, 0.2), M.Pebble, SM)
	R(m, "Castle", b, V(0.9, 1.2, 0.6), V(1.6, 3.8, 0.3), C.PLilac, M.SmoothPlastic, SM)
	for i, f in { { -1.5, 4.3, C.Mustard }, { 0.4, 4.8, C.Rose }, { -0.4, 3.8, C.Mustard } } do
		R(m, "Fish", b, V(0.5, 0.3, 0.12), V(f[1], f[2], -0.3 + i * 0.25), f[3], M.SmoothPlastic, SM)
	end
	R(m, "Lid", b, V(6, 0.3, 2.2), V(0, 5.55, 0), C.Ink, M.SmoothPlastic, SM)
	local bulb = R(m, "Bulb", b, V(5.4, 0.08, 0.5), V(0, 5.37, 0), Color3.fromRGB(150, 220, 230), M.Neon, SM)
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(110, 190, 210)
	l.Range = 12
	l.Brightness = 0.9
	l.Parent = bulb
	m.PrimaryPart = bulb
	B.attrs(m, { Area = area })
	B.tag(m, "Lamp")
	return m
end
return "props ok"
