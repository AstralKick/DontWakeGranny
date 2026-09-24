-- Furniture / prop builders. Requires house_00_lib (run it first). Adds functions to _G.HB.
-- Convention: base CFrame b sits on the floor at the footprint centre; b.LookVector = the front of the prop.
local B = _G.HB
local C, M = B.C, B.M
local V = Vector3.new
local SM = { small = true }
local function R(m, n, b, sz, off, col, mat, o) return B.rp(m, n, b, sz, off, col, mat, o) end
local function dark(c, k) return c:Lerp(C.Ink, k or 0.35) end

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
		c1.CFrame = b * CFrame.new(-(w - d) / 2, h - 0.15, 0) * CFrame.Angles(0, 0, math.rad(90))
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

function B.chair(par, b, col, o)
	o = o or {}
	local m = B.model(par, "Chair")
	local sh = 1.9
	R(m, "Seat", b, V(1.9, 0.25, 1.9), V(0, sh, 0), col, M.Wood)
	if o.cushion then R(m, "Cushion", b, V(1.7, 0.2, 1.7), V(0, sh + 0.22, 0), o.cushion, M.Fabric, SM) end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			R(m, "Leg", b, V(0.22, sh, 0.22), V(sx * 0.8, sh / 2, sz * 0.8), dark(col, 0.2), M.Wood, SM)
		end
		R(m, "Post", b, V(0.22, 2.6, 0.22), V(sx * 0.8, sh + 1.3, 0.8), dark(col, 0.2), M.Wood, SM)
	end
	R(m, "Back", b, V(1.5, 1.1, 0.15), V(0, sh + 1.9, 0.8), col, M.Wood, SM)
	R(m, "Slat", b, V(0.3, 1.2, 0.12), V(0, sh + 0.8, 0.8), col, M.Wood, SM)
	return m
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

function B.sofa(par, b, w, fab, o)
	o = o or {}
	local m = B.model(par, o.name or "Sofa")
	local d = 3.6
	R(m, "Base", b, V(w, 1.2, d), V(0, 0.95, 0), fab, M.Fabric)
	R(m, "Back", b, V(w, 2.6, 0.9), V(0, 2.4, d / 2 - 0.45), fab, M.Fabric)
	for _, sx in { -1, 1 } do
		R(m, "Arm", b, V(0.8, 1.2, d), V(sx * (w / 2 - 0.4), 2.1, 0), fab, M.Fabric)
		R(m, "Foot", b, V(0.35, 0.35, 0.35), V(sx * (w / 2 - 0.4), 0.17, -(d / 2 - 0.4)), C.WoodDark, M.Wood, SM)
	end
	local n = math.max(2, math.floor((w - 1.6) / 2.6))
	local cw = (w - 1.6) / n
	for i = 1, n do
		R(m, "Cushion", b, V(cw - 0.1, 0.5, d - 1.1), V(-(w - 1.6) / 2 + cw * (i - 0.5), 1.8, -0.4), fab:Lerp(C.Paper, 0.1), M.Fabric, SM)
	end
	if o.pillow then R(m, "Pillow", b, V(1.2, 1.2, 0.4), V(w / 2 - 1.5, 2.5, d / 2 - 1.1), o.pillow, M.Fabric, SM) end
	return m
end

-- bed with an under-bed hiding spot. b faces the foot of the bed.
function B.bed(par, b, w, l, frame, sheet, area, o)
	o = o or {}
	local m = B.model(par, o.name or "Bed")
	R(m, "Support", b, V(w, 0.4, l), V(0, 2.6, 0), frame, M.Wood)
	R(m, "Mattress", b, V(w - 0.3, 0.8, l - 0.5), V(0, 3.2, 0.1), C.Paper, M.Fabric)
	R(m, "Quilt", b, V(w, 0.25, l * 0.72), V(0, 3.7, -l * 0.14), sheet, M.Fabric)
	R(m, "QuiltSideL", b, V(0.1, 1.5, l * 0.72), V(-w / 2 - 0.05, 2.95, -l * 0.14), sheet, M.Fabric, SM)
	R(m, "QuiltSideR", b, V(0.1, 1.5, l * 0.72), V(w / 2 + 0.05, 2.95, -l * 0.14), sheet, M.Fabric, SM)
	R(m, "Fold", b, V(w + 0.05, 0.3, 0.8), V(0, 3.75, l * 0.22 + 0.2), C.Paper, M.Fabric, SM)
	R(m, "Pillow", b, V(w * 0.4, 0.5, 1.3), V(-w * 0.22, 3.85, l / 2 - 1.1), C.Paper, M.Fabric, SM)
	R(m, "Pillow", b, V(w * 0.4, 0.5, 1.3), V(w * 0.22, 3.85, l / 2 - 1.1), C.Paper, M.Fabric, SM)
	-- skirt hides the space underneath (one panel per side)
	local sk = o.skirt or dark(sheet, 0.1)
	R(m, "Skirt", b, V(w, 2.3, 0.1), V(0, 1.25, -l / 2 + 0.05), sk, M.Fabric)
	R(m, "Skirt", b, V(0.1, 2.3, l), V(-w / 2 + 0.05, 1.25, 0), sk, M.Fabric)
	R(m, "Skirt", b, V(0.1, 2.3, l), V(w / 2 - 0.05, 1.25, 0), sk, M.Fabric)
	R(m, "Head", b, V(w + 0.6, 6, 0.4), V(0, 3, l / 2 + 0.2), frame, M.Wood)
	R(m, "HeadCap", b, V(w + 1, 0.35, 0.6), V(0, 6.1, l / 2 + 0.2), dark(frame), M.Wood, SM)
	R(m, "Foot", b, V(w + 0.6, 4, 0.35), V(0, 2, -l / 2 - 0.15), frame, M.Wood)
	for _, sx in { -1, 1 } do
		B.ball(m, "Finial", b, 0.55, V(sx * (w / 2 + 0.2), 4.2, -l / 2 - 0.15), dark(frame), M.Wood, SM)
	end
	-- hiding: player lies prone under the bed, head toward the foot
	local pos = (b * CFrame.new(0, 1.1, 0.8)).Position
	local inside = CFrame.fromMatrix(pos, b.RightVector, b.LookVector)
	B.hideParts(m, "Bed", area, inside, (b * CFrame.new(0, 0, -l / 2 - 2)).Position, (b * CFrame.new(1.5, 0, -l / 2 - 2.2)).Position)
	return m
end

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
	R(m, "Plinth", b, V(w, 0.5, d), V(0, 0.25, 0), dark(col), M.Wood)
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
function B.counter(par, b, len, col, top, area, danger, search, o)
	o = o or {}
	local m = B.model(par, o.name or "Counter")
	local d, h = 2.6, 3.4
	R(m, "Body", b, V(len, h - 0.5, d - 0.2), V(0, (h - 0.5) / 2 + 0.4, 0.1), col, M.Wood)
	R(m, "Toe", b, V(len, 0.4, d - 0.5), V(0, 0.2, 0.25), C.WoodDark, M.Wood, SM)
	if not o.noTop then R(m, "Countertop", b, V(len + 0.2, 0.3, d + 0.2), V(0, h - 0.05, 0), top, M.Marble) end
	local n = math.max(1, math.floor(len / 2.5 + 0.5))
	local cw = len / n
	for i = 1, n do
		local x = -len / 2 + cw * (i - 0.5)
		local kind = search and search[i]
		local door = R(m, "CabDoor", b, V(cw - 0.25, 1.9, 0.12), V(x, 1.5, -d / 2 - 0.06), dark(col, 0.05), M.Wood, { collide = false })
		local drw = R(m, "DrawerFront", b, V(cw - 0.25, 0.6, 0.12), V(x, 2.85, -d / 2 - 0.06), dark(col, 0.05), M.Wood, { collide = false })
		B.ball(m, "Pull", b, 0.18, V(x + cw * 0.3, 2.1, -d / 2 - 0.16), C.Brass, M.Metal, SM)
		B.ball(m, "Pull", b, 0.18, V(x, 2.85, -d / 2 - 0.16), C.Brass, M.Metal, SM)
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

-- upper wall cabinets (b on the floor against the wall)
function B.uppers(par, b, len, col, search, area, danger)
	local m = B.model(par, "UpperCabinets")
	local n = math.max(1, math.floor(len / 2.5 + 0.5))
	local cw = len / n
	R(m, "Body", b, V(len, 3, 1.4), V(0, 8.2, 0.7), col, M.Wood)
	R(m, "Crown", b, V(len + 0.2, 0.3, 1.7), V(0, 9.85, 0.6), dark(col), M.Wood, SM)
	for i = 1, n do
		local x = -len / 2 + cw * (i - 0.5)
		local dp = R(m, "CabDoor", b, V(cw - 0.2, 2.7, 0.1), V(x, 8.2, -0.05), dark(col, 0.05), M.Wood, { collide = false })
		B.ball(m, "Pull", b, 0.16, V(x + cw * 0.3, 7.3, -0.15), C.Brass, M.Metal, SM)
		if search and search[i] then
			dp.Name = "Cabinet"
			B.searchable(dp, "Cabinet", area, danger)
		end
	end
	return m
end

function B.fridge(par, b, area, danger)
	local m = B.model(par, "Fridge")
	local col = C.Mint:Lerp(C.Paper, 0.25)
	R(m, "Body", b, V(3.2, 7, 2.6), V(0, 3.6, 0.2), col, M.SmoothPlastic)
	local door = R(m, "FridgeDoor", b, V(3.1, 4.4, 0.3), V(0, 2.6, -1.25), col, M.SmoothPlastic, { collide = false })
	B.searchable(door, "Fridge", area, danger)
	R(m, "FreezerDoor", b, V(3.1, 2.0, 0.3), V(0, 6.0, -1.25), col, M.SmoothPlastic, { collide = false })
	R(m, "Handle", b, V(0.15, 1.6, 0.25), V(1.2, 3.8, -1.5), C.Metal, M.Metal, SM)
	R(m, "Handle", b, V(0.15, 0.8, 0.25), V(1.2, 5.6, -1.5), C.Metal, M.Metal, SM)
	R(m, "Badge", b, V(0.9, 0.2, 0.05), V(0, 4.5, -1.42), C.Brass, M.Metal, SM)
	R(m, "Note", b, V(0.6, 0.7, 0.03), V(-0.8, 3.6, -1.42), C.Paper, M.SmoothPlastic, SM)
	R(m, "Magnet", b, V(0.2, 0.2, 0.06), V(-0.8, 3.95, -1.44), C.Blood, M.SmoothPlastic, SM)
	R(m, "Drawing", b, V(0.8, 0.6, 0.03), V(0.2, 2.2, -1.42), C.Mustard:Lerp(C.Paper, 0.5), M.SmoothPlastic, SM)
	return m
end

function B.stove(par, b)
	local m = B.model(par, "Stove")
	R(m, "Body", b, V(3.2, 3.3, 2.6), V(0, 1.65, 0), C.Paper:Lerp(C.Ink, 0.08), M.SmoothPlastic)
	R(m, "OvenDoor", b, V(2.6, 1.7, 0.12), V(0, 1.4, -1.33), C.Paper:Lerp(C.Ink, 0.15), M.SmoothPlastic, SM)
	R(m, "OvenWindow", b, V(1.6, 0.8, 0.05), V(0, 1.5, -1.4), C.Ink, M.Glass, SM)
	R(m, "BackPanel", b, V(3.2, 1.0, 0.3), V(0, 3.8, 1.15), C.Paper:Lerp(C.Ink, 0.08), M.SmoothPlastic, SM)
	for i, x in { -0.8, 0.8 } do
		for _, z in { -0.55, 0.55 } do
			B.cyl(m, "Burner", b, 0.9, 0.08, V(x, 3.34, z), C.Ink, M.Metal, SM, true)
		end
		R(m, "Knob", b, V(0.25, 0.25, 0.1), V(x * 1.2, 3.8, 0.95), C.Ink, M.SmoothPlastic, SM)
	end
	-- kettle
	B.cyl(m, "Kettle", b, 0.8, 0.7, V(0.8, 3.75, -0.55), C.Blood:Lerp(C.Ink, 0.2), M.SmoothPlastic, SM, true)
	return m
end

-- CRT TV on a wooden console. Tagged Lamp (the glowing screen is the Bulb).
function B.tv(par, b, area)
	local m = B.model(par, "CRT_TV")
	R(m, "Console", b, V(4.4, 2.2, 2.4), V(0, 1.1, 0), C.WoodMid, M.Wood)
	R(m, "ConsoleTop", b, V(4.6, 0.15, 2.5), V(0, 2.27, 0), C.WoodDark, M.Wood, SM)
	R(m, "Grille", b, V(3.6, 1.2, 0.05), V(0, 1.2, -1.22), C.WoodDark, M.Fabric, SM)
	R(m, "Box", b, V(3.6, 2.9, 2.6), V(0, 3.8, 0.1), C.Ink:Lerp(C.WoodDark, 0.5), M.Wood)
	R(m, "Bezel", b, V(3.3, 2.6, 0.1), V(-0.2, 3.8, -1.2), C.Ink, M.SmoothPlastic, SM)
	local scr = R(m, "Bulb", b, V(2.5, 2.0, 0.1), V(-0.35, 3.8, -1.25), Color3.fromRGB(96, 108, 130), M.Neon, SM)
	local sl = Instance.new("SurfaceLight")
	sl.Face = Enum.NormalId.Front
	sl.Color = Color3.fromRGB(170, 190, 230)
	sl.Brightness = 1.6
	sl.Range = 16
	sl.Angle = 100
	sl.Parent = scr
	for i = 1, 2 do
		R(m, "Dial", b, V(0.35, 0.35, 0.1), V(1.35, 4.5 - i * 0.7, -1.22), C.Brass, M.Metal, SM)
	end
	for _, sx in { -1, 1 } do
		local a = R(m, "Antenna", b, V(0.08, 2.4, 0.08), V(sx * 0.5, 6.1, 0.3), C.Metal, M.Metal, SM)
		a.CFrame = b * CFrame.new(sx * 0.45, 5.9, 0.3) * CFrame.Angles(0, 0, math.rad(-sx * 25))
	end
	m.PrimaryPart = scr
	B.attrs(m, { Area = area })
	B.tag(m, "Lamp")
	return m
end

function B.bookshelf(par, b, w, h, col, o)
	o = o or {}
	local m = B.model(par, o.name or "Bookshelf")
	local d = 1.6
	R(m, "Back", b, V(w, h, 0.15), V(0, h / 2, d / 2 - 0.08), dark(col, 0.2), M.Wood)
	for _, sx in { -1, 1 } do
		R(m, "Side", b, V(0.2, h, d), V(sx * (w / 2 - 0.1), h / 2, 0), col, M.Wood)
	end
	local n = o.shelves or 4
	local palette = { C.Rose, C.Mint, C.Mustard, C.Bruise, C.Paper, C.Blood, C.Night }
	local seed = o.seed or 1
	for i = 0, n do
		local y = 0.3 + (h - 0.6) * i / n
		R(m, "Shelf", b, V(w - 0.3, 0.15, d - 0.1), V(0, y, 0), col, M.Wood, SM)
		if i < n and not o.empty then
			local x = -w / 2 + 0.35
			local k = 0
			while x < (if o.gap == i then 0 else w / 2 - 0.8) do
				k += 1
				local bw = 0.3 + ((seed * 7 + k * 13 + i * 5) % 5) * 0.12
				local bh = (h - 0.6) / n * (0.62 + ((seed + k * 3 + i) % 4) * 0.07)
				local c = palette[((seed + k * 5 + i * 3) % #palette) + 1]:Lerp(C.Ink, 0.35)
				local gw = bw * 3
				if x + gw > w / 2 - 0.3 then break end
				R(m, "Books", b, V(gw, bh, d * 0.7), V(x + gw / 2, y + 0.08 + bh / 2, 0.05), c, M.Fabric, SM)
				x += gw + 0.15 + ((k + i) % 3) * 0.4
			end
		end
	end
	return m
end

-- picture on a wall. wb = CFrame at the wall surface centre of the picture, LookVector out of the wall
function B.picture(par, wb, w, h, o)
	o = o or {}
	local m = B.model(par, o.name or "Picture")
	local fc = o.frame or C.WoodDark
	if o.back then -- turned to face the wall
		R(m, "Back", wb, V(w, h, 0.18), V(0, 0, -0.09), C.WoodRaw:Lerp(C.Paper, 0.2), M.Cardboard, SM)
		R(m, "Wire", wb, V(w * 0.6, 0.05, 0.05), V(0, h * 0.3, -0.2), C.Metal, M.Metal, SM)
		R(m, "FrameEdge", wb, V(w + 0.2, 0.2, 0.2), V(0, h / 2, -0.1), fc, M.Wood, SM)
		return m
	end
	R(m, "Frame", wb, V(w, h, 0.2), V(0, 0, -0.1), fc, M.Wood, SM)
	local canvas = o.canvas or C.Night
	R(m, "Canvas", wb, V(w - 0.45, h - 0.45, 0.05), V(0, 0, -0.22), canvas, M.Fabric, SM)
	if o.portrait then
		local skin = o.skin or C.Paper:Lerp(C.Rose, 0.2)
		local ph = h - 0.45
		R(m, "Shoulders", wb, V((w - 0.45) * 0.7, ph * 0.28, 0.04), V(0, -ph * 0.36, -0.25), o.clothes or C.Ink, M.Fabric, SM)
		local hd = math.min(w, h) * 0.32
		B.cyl(m, "Head", wb, hd, 0.04, V(0, ph * 0.02, -0.26), skin, M.SmoothPlastic, SM, false).CFrame = wb * CFrame.new(0, ph * 0.02, -0.26) * CFrame.Angles(0, math.rad(90), 0)
		if o.hair then
			B.cyl(m, "Hair", wb, hd * 1.1, 0.03, V(0, ph * 0.1, -0.245), o.hair, M.Fabric, SM, false).CFrame = wb * CFrame.new(0, ph * 0.1, -0.245) * CFrame.Angles(0, math.rad(90), 0)
		end
		if o.eyes then
			for _, sx in { -1, 1 } do
				R(m, "Eye", wb, V(hd * 0.14, hd * 0.1, 0.03), V(sx * hd * 0.18, ph * 0.03, -0.29), o.eyes, M.Neon, SM)
			end
		end
	elseif o.scene then
		R(m, "Hill", wb, V(w - 0.5, (h - 0.5) * 0.35, 0.04), V(0, -(h - 0.5) * 0.3, -0.25), o.scene, M.Fabric, SM)
		B.cyl(m, "Moon", wb, 0.5, 0.04, V(w * 0.2, h * 0.2, -0.25), C.Paper, M.SmoothPlastic, SM, false).CFrame = wb * CFrame.new(w * 0.2, h * 0.2, -0.25) * CFrame.Angles(0, math.rad(90), 0)
	end
	return m
end

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
function B.sheeted(par, b, shape, s)
	local m = B.model(par, "Sheeted_" .. shape)
	s = s or 1
	local sc = C.Sheet
	if shape == "chair" then
		R(m, "Seat", b, V(3.4 * s, 2.2 * s, 3.2 * s), V(0, 1.1 * s, 0), sc, M.Fabric)
		R(m, "Back", b, V(3.4 * s, 2.6 * s, 1.1 * s), V(0, 3.4 * s, 1.1 * s), sc, M.Fabric)
		R(m, "Drape", b, V(3.8 * s, 0.1, 3.6 * s), V(0, 0.05, 0), sc:Lerp(C.Ink, 0.05), M.Fabric, SM)
	elseif shape == "tall" then
		R(m, "Body", b, V(3 * s, 6.5 * s, 1.8 * s), V(0, 3.25 * s, 0), sc, M.Fabric)
		R(m, "Hem", b, V(3.3 * s, 0.4, 2.1 * s), V(0, 0.2, 0), sc:Lerp(C.Ink, 0.05), M.Fabric, SM)
	else
		R(m, "Top", b, V(4.5 * s, 0.3, 3 * s), V(0, 3 * s, 0), sc, M.Fabric)
		R(m, "Skirt", b, V(4.6 * s, 2.7 * s, 3.1 * s), V(0, 1.5 * s, 0), sc:Lerp(C.Ink, 0.04), M.Fabric)
	end
	return m
end

function B.rocker(par, b, col)
	local m = B.model(par, "RockingChair")
	R(m, "Seat", b, V(2.2, 0.25, 2.2), V(0, 1.9, 0), col, M.Wood)
	for _, sx in { -1, 1 } do
		R(m, "Rocker", b, V(0.2, 0.3, 3.6), V(sx * 1, 0.3, 0), dark(col), M.Wood, SM)
		for _, sz in { -0.8, 0.8 } do
			R(m, "Leg", b, V(0.2, 1.6, 0.2), V(sx * 1, 1.05, sz), col, M.Wood, SM)
		end
		R(m, "Post", b, V(0.2, 3.4, 0.2), V(sx * 0.95, 3.4, 1.0), col, M.Wood, SM)
		R(m, "ArmRest", b, V(0.25, 0.15, 2.0), V(sx * 1.05, 3.0, 0.1), col, M.Wood, SM)
	end
	for i = -2, 2 do
		R(m, "Spindle", b, V(0.12, 2.8, 0.12), V(i * 0.35, 3.3, 1.0), col, M.Wood, SM)
	end
	R(m, "TopRail", b, V(2.2, 0.3, 0.25), V(0, 5.0, 1.0), col, M.Wood, SM)
	R(m, "Blanket", b, V(1.6, 1.4, 0.15), V(0.2, 2.8, 0.85), C.Mustard:Lerp(C.Ink, 0.2), M.Fabric, SM)
	return m
end

function B.vase(par, b, col, s)
	s = s or 1
	local m = B.model(par, "Vase")
	local body = B.cyl(m, "Body", b, 1.0 * s, 1.4 * s, V(0, 0.7 * s, 0), col, M.Glass, { collide = true, touch = true, query = true }, true)
	local neck = B.cyl(m, "Neck", b, 0.55 * s, 0.6 * s, V(0, 1.7 * s, 0), col:Lerp(C.Paper, 0.2), M.Glass, { collide = true, touch = true }, true)
	B.ball(m, "Flower", b, 0.5 * s, V(0.1, 2.15 * s, 0), C.Bruise:Lerp(C.Ink, 0.3), M.Fabric, SM)
	m.PrimaryPart = body
	B.tag(m, "Breakable")
	return m
end
function B.plates(par, b, n)
	local p = B.cyl(par, "PlateStack", b, 1.2, 0.12 * (n or 5), V(0, 0.06 * (n or 5), 0), C.Paper, M.SmoothPlastic, { collide = true, touch = true, query = true, shadow = false }, true)
	B.tag(p, "Breakable")
	return p
end

function B.rug(par, x, y, z, w, d, col, border)
	B.box(par, "Rug", x - w / 2, y - 0.04, z - d / 2, x + w / 2, y + 0.05, z + d / 2, border or dark(col, 0.3), M.Fabric, { small = true, collide = false })
	B.box(par, "RugField", x - w / 2 + 0.6, y - 0.04, z - d / 2 + 0.6, x + w / 2 - 0.6, y + 0.07, z + d / 2 - 0.6, col, M.Fabric, { small = true, collide = false })
end

function B.clock(par, b)
	local m = B.model(par, "GrandfatherClock")
	R(m, "Base", b, V(2.2, 2.4, 1.5), V(0, 1.2, 0), C.WoodDark, M.Wood)
	R(m, "Waist", b, V(1.7, 3.6, 1.2), V(0, 4.2, 0.05), C.WoodDark, M.Wood)
	R(m, "Window", b, V(1.0, 2.6, 0.05), V(0, 4.3, -0.57), C.Ink, M.Glass, SM)
	R(m, "Pendulum", b, V(0.08, 1.8, 0.05), V(0, 4.6, -0.5), C.Brass, M.Metal, SM)
	B.cyl(m, "Bob", b, 0.5, 0.06, V(0, 3.7, -0.5), C.Brass, M.Metal, SM, false).CFrame = b * CFrame.new(0, 3.7, -0.5) * CFrame.Angles(0, math.rad(90), 0)
	R(m, "Hood", b, V(2.1, 2.4, 1.5), V(0, 7.2, 0), C.WoodDark, M.Wood)
	B.cyl(m, "Face", b, 1.6, 0.06, V(0, 7.2, -0.76), C.Paper, M.SmoothPlastic, SM, false).CFrame = b * CFrame.new(0, 7.2, -0.76) * CFrame.Angles(0, math.rad(90), 0)
	R(m, "Hand", b, V(0.08, 0.6, 0.03), V(0, 7.45, -0.8), C.Ink, M.SmoothPlastic, SM)
	R(m, "Hand", b, V(0.45, 0.08, 0.03), V(0.2, 7.2, -0.81), C.Ink, M.SmoothPlastic, SM)
	R(m, "Crown", b, V(2.4, 0.5, 1.7), V(0, 8.65, 0), dark(C.WoodDark, 0.2), M.Wood, SM)
	return m
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

function B.pumpkinProp(par, pos, s, lit)
	s = s or 1
	local m = B.model(par, "JackOLantern")
	local b = CFrame.new(pos)
	local body = B.ball(m, "Pumpkin", b, 1.6 * s, V(0, 0.7 * s, 0), Color3.fromRGB(196, 104, 40), M.SmoothPlastic, { collide = true })
	body.Size = V(1.9 * s, 1.5 * s, 1.9 * s)
	body.Shape = Enum.PartType.Ball
	B.cyl(m, "Stem", b, 0.2 * s, 0.35 * s, V(0, 1.5 * s, 0), C.WoodMid, M.Wood, SM, true)
	if lit then
		local f = R(m, "Face", b, V(0.9 * s, 0.5 * s, 0.05), V(0, 0.75 * s, -0.8 * s), Color3.fromRGB(255, 160, 60), M.Neon, SM)
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 140, 60)
		l.Range = 8
		l.Brightness = 1
		l.Parent = f
	end
	return m
end
return "props ok"
