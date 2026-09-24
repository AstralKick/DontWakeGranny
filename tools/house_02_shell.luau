-- Reset Workspace.House and build the shell: yard ground, foundation, slabs, ceilings, facades (CSG windows), roof, gables.
local B = _G.HB
local C, M = B.C, B.M
local V = Vector3.new
local old = workspace:FindFirstChild("House")
if old then old:Destroy() end
for _, n in { "Baseplate", "SpawnLocation" } do
	local x = workspace:FindFirstChild(n)
	if x then x:Destroy() end
end
local house = Instance.new("Model")
house.Name = "House"
house.Parent = workspace
for _, n in { "PlayerSpawns", "Rooms", "LootSpawns", "PrizeSpawns", "SearchNodes", "Barriers", "PumpkinSpots", "Corruption", "Structure", "Exterior", "Ground", "Upstairs", "Basement", "Attic", "Interactables", "Creaky" } do
	B.F(n)
end
for i = 1, 4 do B.F(tostring(i), B.F("Corruption")) end

-- Lighting base look (EnvironmentService overrides at runtime)
local L = game:GetService("Lighting")
L.ClockTime = 0.5
L.Brightness = 0.4
L.Ambient = Color3.fromRGB(38, 32, 58)
L.OutdoorAmbient = Color3.fromRGB(58, 52, 88)
L.EnvironmentDiffuseScale = 0.25
L.EnvironmentSpecularScale = 0.3
L.GlobalShadows = true
L.FogEnd = 100000
for _, c in L:GetChildren() do
	if c:IsA("Atmosphere") or c:IsA("Sky") then c:Destroy() end
end
local atm = Instance.new("Atmosphere")
atm.Density = 0.32
atm.Offset = 0.1
atm.Color = Color3.fromRGB(70, 66, 110)
atm.Decay = Color3.fromRGB(40, 30, 60)
atm.Glare = 0.1
atm.Haze = 1.6
atm.Parent = L
local sky = Instance.new("Sky")
sky.MoonAngularSize = 16
sky.StarCount = 2500
sky.CelestialBodiesShown = true
sky.Parent = L
L.GeographicLatitude = 20

-- window definitions (centres along the wall) per facade/floor
B.WIN = {
	front = { Ground = { -36, -22, 14, 26, 38 }, Upstairs = { -36, -22, -6, 4, 22, 36 } },
	back = { Ground = { -36, -22, 30, 40 }, Upstairs = { -36, -22, -6, 36 } },
	left = { Ground = { -27, -15, 1, 13, 28 }, Upstairs = { -27, -15, -3, 10, 26 } },
	right = { Ground = { -27, -15, -3, 10, 26 }, Upstairs = { -27, -15, -3, 10, 26 } },
}
B.WH = { w = 4.6, sill = 3.2, h = 9.3 } -- hole (relative to floor)

local S = B.F("Structure")
local EX = B.F("Exterior")

-- yard ground (4 slabs around the footprint so the basement stays clear)
local function grass(x0, z0, x1, z1)
	B.box(EX, "Grass", x0, -2, z0, x1, 0, z1, C.Grass, M.Grass, { solid = true })
end
grass(-160, -210, 160, -36)
grass(-160, 36, 160, 160)
grass(-160, -36, -46, 36)
grass(46, -36, 160, 36)

-- foundation band + basement outer walls
B.box(S, "Foundation", -46.3, -0.6, -36.3, 46.3, 2, -36, C.Brick, M.Brick, { solid = true })
B.box(S, "Foundation", -46.3, -0.6, 36, 46.3, 2, 36.3, C.Brick, M.Brick, { solid = true })
B.box(S, "Foundation", -46.3, -0.6, -36, -46, 2, 36, C.Brick, M.Brick, { solid = true })
B.box(S, "Foundation", 46, -0.6, -36, 46.3, 2, 36, C.Brick, M.Brick, { solid = true })
B.box(S, "BasementWall", -46, -12, -36, 46, 1, -35, C.Concrete, M.Concrete, { solid = true })
B.box(S, "BasementWall", -46, -12, 35, 46, 1, 36, C.Concrete, M.Concrete, { solid = true })
B.box(S, "BasementWall", -46, -12, -35, -45, 1, 35, C.Concrete, M.Concrete, { solid = true })
B.box(S, "BasementWall", 45, -12, -35, 46, 1, 35, C.Concrete, M.Concrete, { solid = true })
B.box(S, "BasementSlab", -45, -12, -35, 45, -11, 35, C.Concrete, M.Concrete, { solid = true })
-- rim between basement ceiling and ground floor on the outer walls
B.box(S, "Rim", -46, 1, -36, 46, 2, -35, C.Brick, M.Brick, { solid = true })
B.box(S, "Rim", -46, 1, 35, 46, 2, 36, C.Brick, M.Brick, { solid = true })
B.box(S, "Rim", -46, 1, -35, -45, 2, 35, C.Brick, M.Brick, { solid = true })
B.box(S, "Rim", 45, 1, -35, 46, 2, 35, C.Brick, M.Brick, { solid = true })

-- slab helper: floor planks top at y, with optional ceiling plaster under it
local function slab(name, x0, z0, x1, z1, yTop, floorCol, floorMat, ceilCol)
	B.box(S, name, x0, yTop - 0.7, z0, x1, yTop, z1, floorCol, floorMat, { solid = true })
	if ceilCol then
		B.box(S, name .. "Ceiling", x0, yTop - 1, z0, x1, yTop - 0.7, z1, ceilCol, M.Plaster, { solid = true })
	else
		B.box(S, name .. "Under", x0, yTop - 1, z0, x1, yTop - 0.7, z1, C.WoodRaw:Lerp(C.Ink, 0.3), M.WoodPlanks, { solid = true })
	end
end
-- ground floor (hole for basement stairs X13..23 Z4..35)
slab("GroundFloor", -45, -35, 13, 35, 2, C.Floor, M.WoodPlanks)
slab("GroundFloor", 23, -35, 45, 35, 2, C.Floor, M.WoodPlanks)
slab("GroundFloor", 13, -35, 23, 4, 2, C.Floor, M.WoodPlanks)
-- upstairs floor (hole for main stairs X-13..-6 Z4..28)
local ceil = Color3.fromRGB(196, 186, 166)
slab("UpstairsFloor", -45, -35, -13, 35, 15, C.Floor, M.WoodPlanks, ceil)
slab("UpstairsFloor", -6, -35, 45, 35, 15, C.Floor, M.WoodPlanks, ceil)
slab("UpstairsFloor", -13, -35, -6, 4, 15, C.Floor, M.WoodPlanks, ceil)
slab("UpstairsFloor", -13, 28, -6, 35, 15, C.Floor, M.WoodPlanks, ceil)
-- attic floor (hole for attic stairs X20..27 Z11..23)
local af = C.WoodRaw:Lerp(C.Ink, 0.15)
slab("AtticFloor", -45, -35, 20, 35, 28, af, M.WoodPlanks, ceil)
slab("AtticFloor", 27, -35, 45, 35, 28, af, M.WoodPlanks, ceil)
slab("AtticFloor", 20, -35, 27, 11, 28, af, M.WoodPlanks, ceil)
slab("AtticFloor", 20, 25.5, 27, 35, 28, af, M.WoodPlanks, ceil)

-- facades: siding with CSG window/door holes
local WH = B.WH
local function facade(side)
	local wins = B.WIN[side]
	local p, cut = nil, {}
	local y0, y1 = 2, 28
	if side == "front" then
		p = B.box(EX, "Facade_front", -46, y0, -36, 46, y1, -35.5, C.Siding, M.WoodPlanks, { solid = true })
	elseif side == "back" then
		p = B.box(EX, "Facade_back", -46, y0, 35.5, 46, y1, 36, C.Siding, M.WoodPlanks, { solid = true })
	elseif side == "left" then
		p = B.box(EX, "Facade_left", -46, y0, -35.5, -45.5, y1, 35.5, C.Siding, M.WoodPlanks, { solid = true })
	else
		p = B.box(EX, "Facade_right", 45.5, y0, -35.5, 46, y1, 35.5, C.Siding, M.WoodPlanks, { solid = true })
	end
	local pc = p.Position
	for fl, list in wins do
		local fy = B.FL[fl]
		for _, c in list do
			local yc = fy + (WH.sill + WH.h) / 2
			local sz = if side == "front" or side == "back" then V(WH.w, WH.h - WH.sill, 3) else V(3, WH.h - WH.sill, WH.w)
			local pos = if side == "front" or side == "back" then V(c, yc, pc.Z) else V(pc.X, yc, c)
			table.insert(cut, B.cutter(sz, CFrame.new(pos)))
		end
	end
	if side == "front" then
		table.insert(cut, B.cutter(V(4.5, 8, 3), CFrame.new(-5, 2 + 4, pc.Z)))
		for _, sx in { -8.4, -1.6 } do
			table.insert(cut, B.cutter(V(1.2, 6.5, 3), CFrame.new(sx, 2 + 1 + 3.25, pc.Z)))
		end
	end
	local fid = if side == "front" then Enum.CollisionFidelity.PreciseConvexDecomposition else Enum.CollisionFidelity.Box
	return B.csg("sub", p, cut, { fid = fid })
end
for _, s in { "front", "back", "left", "right" } do facade(s) end

-- exterior trim: corner boards, floor band, fascia
local T = C.Paper:Lerp(C.Ink, 0.12)
for _, x in { -46, 46 } do
	for _, z in { -36, 36 } do
		B.box(EX, "CornerBoard", x - 0.45, 2, z - 0.45, x + 0.45, 28, z + 0.45, T, M.Wood, { solid = true })
	end
end
B.box(EX, "Band", -46.2, 14, -36.25, 46.2, 15, -35.9, T, M.Wood, { small = true })
B.box(EX, "Band", -46.2, 14, 35.9, 46.2, 15, 36.25, T, M.Wood, { small = true })
B.box(EX, "Band", -46.25, 14, -36, -45.9, 15, 36, T, M.Wood, { small = true })
B.box(EX, "Band", 45.9, 14, -36, 46.25, 15, 36, T, M.Wood, { small = true })

-- roof: two sloped slabs, ridge along X at Z=0, Y=48; eaves at Z=+-35, Y=28
local th = math.atan2(20, 35)
local slope = math.sqrt(35 * 35 + 20 * 20)
local RF = B.F("Roof", EX)
for _, s in { 1, -1 } do
	local mid = V(0, 38, s * 17.5)
	local rot = CFrame.Angles(s * th, 0, 0)
	local base = CFrame.new(mid) * rot
	-- outer shingles and inner boards (1.5 stud eave overhang)
	B.part(RF, "Roof", V(97, 0.8, slope + 3.5), base * CFrame.new(0, 0.7, s * 1.5), C.Roof, M.Slate, { solid = true })
	B.part(RF, "RoofBoards", V(92, 0.3, slope + 0.2), base * CFrame.new(0, 0.15, 0), C.WoodRaw:Lerp(C.Ink, 0.35), M.WoodPlanks, { solid = true })
	-- rafters (visible from the attic)
	for x = -42, 42, 6 do
		B.part(RF, "Rafter", V(0.6, 0.9, slope - 1), base * CFrame.new(x, -0.45, 0), C.WoodRaw:Lerp(C.Ink, 0.25), M.Wood, { small = true })
	end
	-- fascia board at the eave
	B.part(RF, "Fascia", V(97.2, 1.2, 0.3), base * CFrame.new(0, 0.4, s * (slope / 2 + 3.2)), T, M.Wood, { small = true })
end
B.box(RF, "Ridge", -48.5, 47.6, -0.6, 48.5, 49.2, 0.6, C.Roof:Lerp(C.Ink, 0.3), M.Slate, { small = true })
-- gable ends (two wedges each) with a round CSG window
for _, x in { -45.75, 45.75 } do
	local w1 = B.part(EX, "Gable", V(0.5, 20, 35), CFrame.new(x, 38, -17.5), C.Siding, M.WoodPlanks, { solid = true, class = "WedgePart" })
	local w2 = B.part(EX, "Gable", V(0.5, 20, 35), CFrame.new(x, 38, 17.5) * CFrame.Angles(0, math.pi, 0), C.Siding, M.WoodPlanks, { solid = true, class = "WedgePart" })
	local g = B.csg("union", w1, { w2 })
	local cutter = B.cutter(V(3, 4.4, 4.4), CFrame.new(x, 37, 0), Enum.PartType.Cylinder)
	B.csg("sub", g, { cutter })
	-- round window glass + frame ring
	local ring = B.part(EX, "RoundFrame", V(0.7, 5, 5), CFrame.new(x, 37, 0), T, M.Wood, { small = true, shape = Enum.PartType.Cylinder })
	B.csg("sub", ring, { B.cutter(V(2, 4.3, 4.3), CFrame.new(x, 37, 0), Enum.PartType.Cylinder) })
	B.part(EX, "RoundGlass", V(0.1, 4.4, 4.4), CFrame.new(x, 37, 0), C.Glass, M.Glass, { tr = 0.5, shape = Enum.PartType.Cylinder, solid = true })
	B.part(EX, "RoundMullion", V(0.3, 4.4, 0.2), CFrame.new(x, 37, 0), T, M.Wood, { small = true })
	B.part(EX, "RoundMullion", V(0.3, 0.2, 4.4), CFrame.new(x, 37, 0), T, M.Wood, { small = true })
end
return "shell ok, parts=" .. B.count(house)
