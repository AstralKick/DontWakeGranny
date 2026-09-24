-- house_13_extra_hiding: adds hiding spots to ground-floor rooms that have none, so
-- Nights 1-5 (ground floor only) always have somewhere to hide near you.
-- Self-contained (same look as house_01_props' B.wardrobe). Run after the house is built.
-- Idempotent: removes previously added "ExtraHide_*" models first.
-- Finds wall-backed floor space automatically: no furniture in the footprint, clear space in
-- front, not near doors or windows, >= 12 studs from any existing hiding spot.

local CS = game:GetService("CollectionService")
local house = workspace.House
local M = Enum.Material
local C = {
	Ink = Color3.fromHex("2A1A24"), Paper = Color3.fromHex("F3E9D2"), Rose = Color3.fromHex("D97A8A"),
	Mint = Color3.fromHex("9CC5A1"), WoodDark = Color3.fromRGB(58, 38, 32), WoodMid = Color3.fromRGB(98, 68, 50),
	Brass = Color3.fromRGB(176, 140, 72),
}
local B = {}
function B.part(parent, name, size, cf, color, mat, o)
	o = o or {}
	local p = Instance.new("Part")
	if o.shape then
		p.Shape = o.shape
	end
	p.Name, p.Anchored, p.Size, p.CFrame = name, true, size, cf
	p.Color, p.Material = color or C.Paper, mat or M.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if o.inv then
		p.Transparency, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = 1, false, false, false, false
	else
		p.CanCollide = not o.small
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = not o.small
	end
	p.Parent = parent
	return p
end
local function R(m, n, b, sz, off, col, mat, o)
	return B.part(m, n, sz, b * CFrame.new(off), col, mat, o)
end
local function dark(c, k)
	return c:Lerp(C.Ink, k or 0.35)
end
local SM = { small = true }
local V = Vector3.new
function B.wardrobe(par, b, col, area, kind, o)
	local m = Instance.new("Model")
	m.Name = o.name
	m.Parent = par
	local w, d, h = o.w or 5.2, 3.8, o.h or 8.8
	R(m, "Back", b, V(w, h, 0.3), V(0, h / 2, d / 2 - 0.15), col, M.Wood)
	for _, sx in { -1, 1 } do
		R(m, "Side", b, V(0.3, h, d), V(sx * (w / 2 - 0.15), h / 2, 0), col, M.Wood)
	end
	R(m, "Top", b, V(w, 0.4, d), V(0, h - 0.2, 0), col, M.Wood)
	R(m, "Crown", b, V(w + 0.5, 0.45, d + 0.3), V(0, h + 0.2, -0.15), dark(col), M.Wood, SM)
	R(m, "Plinth", b, V(w, 0.5, d), V(0, 0.25, 0), dark(col), M.Wood)
	local lw = (w - 0.1) / 2
	for _, sx in { -1, 1 } do
		local cx = sx * lw / 2
		R(m, "DoorLeaf", b, V(lw - 0.04, h - 1.0, 0.25), V(cx, 0.5 + (h - 1) / 2, -d / 2 + 0.125), col, M.Wood)
		if o.louvre then
			for i = 1, 7 do
				R(m, "Louvre", b, V(lw - 0.7, 0.12, 0.1), V(cx, 1.6 + i * 0.75, -d / 2 - 0.02), dark(col, 0.25), M.Wood, SM)
			end
		else
			R(m, "Inset", b, V(lw - 0.8, h * 0.36, 0.06), V(cx, 0.5 + h * 0.66, -d / 2 - 0.02), dark(col, 0.2), M.Wood, SM)
			R(m, "Inset", b, V(lw - 0.8, h * 0.3, 0.06), V(cx, 0.5 + h * 0.22, -d / 2 - 0.02), dark(col, 0.2), M.Wood, SM)
		end
		B.part(m, "Knob", V(0.28, 0.28, 0.28), b * CFrame.new(sx * 0.35, 4.2, -d / 2 - 0.12), C.Brass, M.Metal, { small = true, shape = Enum.PartType.Ball })
	end
	-- Hiding helpers (same contract as house_01_props B.hideParts)
	local inside = b * CFrame.new(0, 3.1, 0.2)
	local front = (b * CFrame.new(0, 0, -d / 2 - 2.1)).Position
	local exit = (b * CFrame.new(0, 0, -d / 2 - 2)).Position
	B.part(m, "Inside", V(1.6, 2, 1), inside, C.Paper, M.SmoothPlastic, { inv = true })
	B.part(m, "Front", V(2, 0.2, 2), CFrame.new(front + V(0, 0.1, 0)), C.Paper, M.SmoothPlastic, { inv = true })
	local ep = exit + V(0, 0.5, 0)
	local look = (exit - inside.Position) * V(1, 0, 1)
	B.part(m, "Exit", V(2, 1, 2), CFrame.lookAt(ep, ep + look), C.Paper, M.SmoothPlastic, { inv = true })
	m:SetAttribute("Kind", kind)
	m:SetAttribute("Area", area)
	CS:AddTag(m, "HidingSpot")
	return m
end

for _, m in house:GetDescendants() do
	if m:IsA("Model") and m.Name:find("^ExtraHide_") then
		m:Destroy()
	end
end

local W, D, H = 4.8, 3.8, 8.6
local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.RespectCanCollide = true
local ignore = { house.Rooms, house:FindFirstChild("LootSpawns"), house:FindFirstChild("SearchNodes"), house:FindFirstChild("PrizeSpawns") }
local ignoreList = {}
for _, f in ignore do
	if f then
		table.insert(ignoreList, f)
	end
end
params.FilterDescendantsInstances = ignoreList

local function spotsIn(room: BasePart): number
	local n = 0
	for _, m in CS:GetTagged("HidingSpot") do
		local inside = m:FindFirstChild("Inside", true)
		if inside then
			local rel = room.CFrame:PointToObjectSpace(inside.Position)
			local half = room.Size / 2
			if math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z then
				n += 1
			end
		end
	end
	return n
end

local function nearExisting(pos: Vector3, dist: number): boolean
	for _, m in CS:GetTagged("HidingSpot") do
		local inside = m:FindFirstChild("Inside", true)
		if inside and (Vector3.new(inside.Position.X, pos.Y, inside.Position.Z) - pos).Magnitude < dist then
			return true
		end
	end
	return false
end

local function nearDoor(pos: Vector3): boolean
	for _, d in CS:GetTagged("Door") do
		local p = d:FindFirstChild("Panel")
		if p and (Vector3.new(p.Position.X, pos.Y, p.Position.Z) - pos).Magnitude < 7 then
			return true
		end
	end
	return false
end

local function boxClear(cf: CFrame, size: Vector3): boolean
	local parts = workspace:GetPartBoundsInBox(cf, size, params)
	for _, p in parts do
		if p.CanCollide and p.Transparency < 1 then
			return false
		end
	end
	return true
end

local function windowBehind(cf: CFrame): boolean
	local parts = workspace:GetPartBoundsInBox(cf * CFrame.new(0, H / 2, D / 2 + 0.6), Vector3.new(W + 1, H, 1.4), params)
	for _, p in parts do
		local n = p.Name:lower()
		if n:find("glass") or n:find("window") or n:find("pane") or n:find("curtain") or n:find("sill") or n:find("fireplace") then
			return true
		end
	end
	return false
end

local placed = {}
local palette = { C.WoodMid, C.WoodDark:Lerp(C.WoodMid, 0.4), C.Mint:Lerp(C.Ink, 0.3), C.Rose:Lerp(C.Ink, 0.35), C.Paper:Lerp(C.Ink, 0.3) }

for _, room in house.Rooms:GetChildren() do
	if not room:IsA("BasePart") or room:GetAttribute("Area") ~= "Ground" then
		continue
	end
	local name = room:GetAttribute("RoomName") or room.Name
	-- (Entry Hall excluded: a wardrobe there blocks the front-door view of Grandma's chair.)
	if spotsIn(room) > 0 or name:lower():find("stair") or name:lower():find("entry") or room.Size.X < 10 or room.Size.Z < 10 then
		continue
	end
	local floorY = room.Position.Y - room.Size.Y / 2
	local half = room.Size / 2
	local best: CFrame? = nil
	-- walls: facing into the room (+x wall faces -x, etc.)
	for _, inset in { 0.05, 0.4, 0.8 } do
	if best then break end
	local walls = {
		{ dir = Vector3.new(-1, 0, 0), fixed = room.Position.X + half.X - D / 2 - inset, along = "z", len = half.Z },
		{ dir = Vector3.new(1, 0, 0), fixed = room.Position.X - half.X + D / 2 + inset, along = "z", len = half.Z },
		{ dir = Vector3.new(0, 0, -1), fixed = room.Position.Z + half.Z - D / 2 - inset, along = "x", len = half.X },
		{ dir = Vector3.new(0, 0, 1), fixed = room.Position.Z - half.Z + D / 2 + inset, along = "x", len = half.X },
	}
	for _, w in walls do
		if best then
			break
		end
		local s = -w.len + W / 2 + 1
		while s <= w.len - W / 2 - 1 do
			local pos = if w.along == "z"
				then Vector3.new(w.fixed, floorY, room.Position.Z + s)
				else Vector3.new(room.Position.X + s, floorY, w.fixed)
			local cf = CFrame.lookAt(pos, pos + w.dir)
			if not nearDoor(pos) and not nearExisting(pos, 12) and not windowBehind(cf)
				and boxClear(cf * CFrame.new(0, H / 2 + 0.35, 0), Vector3.new(W, H - 0.8, D - 0.3))
				and boxClear(cf * CFrame.new(0, 3.2, -D / 2 - 3), Vector3.new(3.4, 5.5, 5.4)) then
				best = cf
				break
			end
			s += 1
		end
	end
	end -- inset loop
	if best then
		local kind = if #placed % 2 == 0 then "Wardrobe" else "Closet"
		local m = B.wardrobe(house.Ground, best, palette[#placed % #palette + 1], "Ground", kind, {
			name = "ExtraHide_" .. name:gsub("%s", ""),
			w = W,
			h = H,
			louvre = kind == "Closet",
		})
		table.insert(placed, name .. " @ " .. tostring(best.Position))
		local _ = m
	else
		table.insert(placed, name .. ": no clear wall space")
	end
end

return table.concat(placed, "\n")
