-- St. Mildred's 01: reset the map model, folders, ROOM VOLUMES (defined first so later chunks auto-resolve Area/Danger),
-- ground, churchyard walls, lych-gate, paths, lane, Mom's car, player spawns, boundary, moon.
local B = _G.SMB
local C, M = B.C, B.M
local V = Vector3.new
local maps = workspace:FindFirstChild("Maps")
if not maps then
	maps = Instance.new("Folder")
	maps.Name = "Maps"
	maps.Parent = workspace
end
local old = maps:FindFirstChild("StMildreds")
if old then old:Destroy() end
local root = Instance.new("Model")
root.Name = "StMildreds"
root:SetAttribute("MapId", "StMildreds")
root:SetAttribute("DisplayName", "St. Mildred's Chapel")
root:SetAttribute("AreaName_Upstairs", "THE BELL TOWER")
root:SetAttribute("AreaName_Basement", "THE CRYPT")
root:SetAttribute("AreaName_Attic", "THE GRAVEYARD")
root.Parent = maps
for _, n in { "PlayerSpawns", "Rooms", "LootSpawns", "PrizeSpawns", "SearchNodes", "Barriers", "Corruption", "Structure", "Exterior", "Ground", "Upstairs", "Basement", "Attic", "Interactables", "Creaky" } do
	B.F(n)
end
for i = 1, 4 do B.F(tostring(i), B.F("Corruption")) end

----------------------------------------------------------------- rooms (local coords: x0,y0,z0,x1,y1,z1)
local R = B.room
-- Ground
R("Porch", "Ground", 1, -5, 2, -31.5, 5, 12, -23.5)
R("Nave", "Ground", 3, -16, 2, -10, 16, 28, 24)
R("Nave (Under the Loft)", "Ground", 1, -16, 2, -22, 16, 12, -10)
R("Tower Base", "Ground", 1, -41.5, 2, -23.5, -17.5, 12, -8.5)
R("Organ Loft Stairs", "Ground", 2, -25, 2, 15.5, -17.5, 22.5, 24)
R("Chancel", "Ground", 3, -8, 2, 25.5, 8, 24, 40)
R("Lady Chapel", "Ground", 2, -26, 2, 25.5, -9, 14, 40)
R("Vestry", "Ground", 2, 9, 2, 25.5, 19, 14, 40)
R("Vestry", "Ground", 2, 19, 2, 32, 26, 14, 40)
R("Vestry WC", "Ground", 1, 20, 2, 25.5, 26, 14, 31)
R("Cloister Passage", "Ground", 2, -26, 2, 41, 26, 14, 50)
R("Churchyard Path", "Ground", 1, -60, 0, -78, 60, 20, -33)
R("West Churchyard", "Ground", 1, -60, 0, -33, -43, 20, 51.5)
R("East Churchyard", "Ground", 1, 27.5, 0, -33, 60, 20, 51.5)
R("South Lawn", "Ground", 1, -43, 0, -33, -6.5, 20, -23.5)
R("South Lawn", "Ground", 1, 6.5, 0, -33, 27.5, 20, -23.5)
R("East Garth", "Ground", 1, 17.5, 0, -23.5, 27.5, 20, -8.5)
R("Tower Garth", "Ground", 1, -43, 0, -7, -27.5, 20, 51.5)
-- Upstairs = THE BELL TOWER
R("Tower Stairs", "Upstairs", 2, -25, 2, -7, -17.5, 22.5, 14.5)
R("Ringing Chamber", "Upstairs", 2, -41.5, 13, -23.5, -17.5, 21, -8.5)
R("Belfry", "Upstairs", 3, -41.5, 21, -23.5, -17.5, 34, -8.5)
R("Choir Loft", "Upstairs", 2, -16, 13, -22, 16, 28, -10)
-- Basement = THE CRYPT
R("Crypt Stairs", "Basement", 2, 17.5, -11, -7, 25, 12, 24)
R("Crypt Hall", "Basement", 3, -26, -11, 25.5, 26, 1, 33.5)
R("Burial Vault", "Basement", 3, -26, -11, 34.5, -1, 1, 50)
R("Founders' Vault", "Basement", 3, 1, -11, 34.5, 26, 1, 50)
-- Attic = THE GRAVEYARD
R("Graveyard Gate", "Attic", 2, 27.5, 0, 53, 60, 16, 66)
R("Yew Walk", "Attic", 2, -46, 0, 53, 27.5, 16, 66)
R("Gardener's Hut", "Attic", 2, -59, 0, 54, -46.5, 12, 65.5)
R("West Graves", "Attic", 2, -60, 0, 66, -8, 16, 100)
R("Mausoleum Lawn", "Attic", 3, -8, 0, 66, 8, 16, 88.5)
R("Mausoleum", "Attic", 3, -6.5, 0, 90, 6.5, 11, 98.5)
R("East Graves", "Attic", 2, 8, 0, 66, 60, 16, 100)

----------------------------------------------------------------- ground (grass top Y 0), leaving the crypt + crypt-stair pit open
local EX = B.F("Exterior")
local function grass(x0, z0, x1, z1)
	B.box(EX, "Grass", x0, -2, z0, x1, 0, z1, C.Grass, M.Grass, { solid = true })
end
grass(-220, -220, 220, -8.5)
grass(-220, 51.5, 220, 240)
grass(-220, -8.5, -27.5, 51.5)
grass(27.5, -8.5, 220, 51.5)
grass(-27.5, -8.5, 16, 24)
grass(26.5, -8.5, 27.5, 24)

----------------------------------------------------------------- churchyard walls (rubble + limestone coping, butt-jointed)
local WL = B.model(EX, "ChurchyardWall")
local function cwall(x0, z0, x1, z1, h)
	h = h or 4.2
	B.box(WL, "Wall", x0, 0, z0, x1, h, z1, C.StoneW:Lerp(C.Moss, 0.15), M.Cobblestone, { solid = true })
	B.box(WL, "Coping", x0, h, z0, x1, h + 0.5, z1, C.StoneD, M.Limestone, { solid = true })
end
cwall(-61.5, -79.5, -4, -78)
cwall(4, -79.5, 61.5, -78)
cwall(-61.5, -78, -60, 101.5)
cwall(60, -78, 61.5, 101.5)
cwall(-60, 100, 60, 101.5)
-- graveyard wall (behind the chapel line), gate gap x 40..47
cwall(-60, 51.5, -26, 53)
cwall(26, 51.5, 40, 53)
cwall(48, 51.5, 60, 53)
-- gate piers (0.05 proud into the gap so no face is coplanar with the wall ends); clear gap x 40.05..47.95
for _, x in { { 38.8, 40.05 }, { 47.95, 49.2 } } do
	B.box(WL, "GatePier", x[1], -0.1, 51.2, x[2], 6, 53.3, C.StoneD, M.Limestone, { solid = true })
	B.box(WL, "PierCap", x[1] - 0.2, 6, 51.0, x[2] + 0.2, 6.5, 53.5, C.StoneD, M.Limestone, { small = true })
	B.ball(WL, "PierBall", CFrame.new((x[1] + x[2]) / 2, 6.5, 52.25), 1, V(0, 0.45, 0), C.StoneD, M.Limestone, { small = true })
end

----------------------------------------------------------------- lych-gate (timber roofed gate over the path)
do
	local lg = B.model(EX, "LychGate")
	local oak = C.Oak:Lerp(C.Ink, 0.2)
	for _, x in { -4.55, 4.55 } do
		for _, z in { -80.65, -76.85 } do
			B.box(lg, "Post", x - 0.35, 0, z - 0.35, x + 0.35, 8, z + 0.35, oak, M.Wood, { solid = true })
		end
		B.box(lg, "SideBeam", x - 0.3, 7.3, -81.3, x + 0.3, 7.95, -76.2, oak, M.Wood, { small = true })
	end
	for _, z in { -80.65, -76.85 } do
		B.box(lg, "TieBeam", -5.2, 8, z - 0.3, 5.2, 8.6, z + 0.3, oak, M.Wood, { small = true })
	end
	for _, s in { -1, 1 } do
		local ang = math.atan2(3.4, 6.4)
		local len = math.sqrt(6.4 ^ 2 + 3.4 ^ 2) + 0.4
		B.part(lg, "Roof", V(len, 0.5, 6.6 - (s + 1) * 0.03), CFrame.new(s * 3.1, 10.1, -78.75) * CFrame.Angles(0, 0, -s * ang), C.Slate, M.Slate, { solid = true })
	end
	B.box(lg, "Ridge", -0.35, 11.6, -82.1, 0.35, 12.1, -75.4, C.Slate:Lerp(C.Ink, 0.3), M.Slate, { small = true })
	for _, s in { -1, 1 } do -- gable boards
		local len = math.sqrt(5.2 ^ 2 + 2.8 ^ 2)
		for _, z in { -81.9, -75.6 } do
			B.part(lg, "Barge", V(len, 0.4, 0.2), CFrame.new(s * 2.6, 10.0, z) * CFrame.Angles(0, 0, -s * math.atan2(2.8, 5.2)), oak, M.Wood, { small = true })
		end
	end
	B.LP(lg, "bare", CFrame.new(0, 8, -78.75), { drop = 1.4, range = 20, bright = 1.1, color = Color3.fromRGB(255, 190, 120), shadows = true })
	-- small lantern cage around that bulb
	B.box(lg, "LanternCage", -0.45, 5.6, -79.2, 0.45, 6.6, -78.3, C.Iron, M.Glass, { small = true, tr = 0.65 })
	B.box(lg, "LanternCap", -0.55, 6.6, -79.3, 0.55, 6.8, -78.2, C.Iron, M.Metal, { small = true })
end

----------------------------------------------------------------- lane, paths
local gravel = C.Stone:Lerp(C.Paper, 0.22)
B.box(EX, "Lane", -62, -0.2, -102, 62, 0.06, -79.5, C.Dirt:Lerp(C.Stone, 0.4), M.Pebble, { solid = true })
for _, x in { -40, -12, 18, 44 } do
	B.box(EX, "Rut", x, 0.06, -93.5, x + 14, 0.09, -92.9, C.Dirt, M.Mud, { small = true })
	B.box(EX, "Rut", x + 3, 0.06, -88.1, x + 17, 0.09, -87.5, C.Dirt, M.Mud, { small = true })
end
local function path(x0, z0, x1, z1, h)
	B.box(EX, "Path", x0, -0.2, z0, x1, h or 0.05, z1, gravel, M.Pebble, { solid = true })
end
path(-3.5, -79.5, 3.5, -37)
path(-50, -48, -3.5, -42)
path(-50, -42, -44.03, -13)
path(3.5, -48, 47, -42)
path(40, -42, 47, 53) -- runs on through the graveyard gate so the walking surface has no seams there
-- porch steps (visible) + wedge
B.flight(EX, "PorchSteps", "z", -3.5, 3.5, -36, 0, -33, 2, 3, C.StoneD, M.Limestone, 0)
-- tower west door steps
B.flight(EX, "TowerDoorSteps", "x", -18.5, -13.5, -46, 0, -43, 2, 3, C.StoneD, M.Limestone, 0)
-- lane hedge (south edge) and an old lamp post by the gate (decor light, not a contract Lamp)
B.box(EX, "Hedge", -62, 0, -104, 62, 6.5, -102, C.Grass:Lerp(C.Ink, 0.4), M.LeafyGrass, { solid = true })
do
	local lp = B.model(EX, "LanePost")
	B.box(lp, "Pole", -9.3, 0, -82.3, -8.7, 11, -81.7, C.Iron, M.Metal, { small = true })
	B.box(lp, "Head", -9.6, 11, -82.6, -8.4, 12.2, -81.4, C.Iron, M.Glass, { small = true, tr = 0.5 })
	local g = B.box(lp, "Glow", -9.25, 11.2, -82.25, -8.75, 11.9, -81.75, Color3.fromRGB(255, 196, 130), M.Neon, { small = true })
	local l = Instance.new("PointLight")
	l.Range = 22
	l.Brightness = 0.9
	l.Color = Color3.fromRGB(255, 186, 120)
	l.Parent = g
end

----------------------------------------------------------------- Mom's car (pastel minivan) in the lane, nose west; trunk at the east end
do
	local car = B.model(B.root(), "MomsCar")
	local b = B.cf(22, 0, -91, "-x")
	local body = C.Bruise:Lerp(C.Paper, 0.55)
	local glass = Color3.fromRGB(40, 44, 60)
	local R2 = function(n, sz, off, col, mat, o) return B.rp(car, n, b, sz, off, col, mat, o or { solid = true }) end
	R2("Body", V(7, 2.6, 16), V(0, 2.1, 0), body, M.SmoothPlastic)
	R2("Cabin", V(6.7, 2.9, 11.5), V(0, 4.85, 1.6), body, M.SmoothPlastic)
	B.rp(car, "Hood", b, V(6.7, 1.4, 3.2), V(0, 4.1, -5.75), body, M.SmoothPlastic, { solid = true, class = "WedgePart" })
	local ws = R2("Windshield", V(6.3, 0.1, 3.4), V(0, 4.9, -4.9), glass, M.Glass, { small = true })
	ws.CFrame = CFrame.new(B.O) * b * CFrame.new(0, 4.95, -4.65) * CFrame.Angles(math.rad(-58), 0, 0)
	for _, sx in { -1, 1 } do
		R2("SideGlass", V(0.1, 1.9, 10.4), V(sx * 3.37, 5.1, 1.6), glass, M.Glass, { small = true })
		R2("Pillar", V(0.25, 2.0, 0.35), V(sx * 3.39, 5.1, -1.4), body, M.SmoothPlastic, { small = true })
		R2("Pillar", V(0.25, 2.0, 0.35), V(sx * 3.39, 5.1, 3.2), body, M.SmoothPlastic, { small = true })
		R2("DoorSeam", V(0.05, 2.4, 0.08), V(sx * 3.52, 2.6, 0.2), C.Ink, M.SmoothPlastic, { small = true })
		R2("Stripe", V(0.05, 0.3, 15.6), V(sx * 3.535, 2.7, 0), C.Rose:Lerp(C.Ink, 0.1), M.SmoothPlastic, { small = true })
		R2("Mirror", V(0.6, 0.45, 0.3), V(sx * 3.7, 4.2, -3.2), body, M.SmoothPlastic, { small = true })
		for _, z in { -5, 5 } do
			B.cyl(car, "Wheel", b, 2.6, 1.0, V(sx * 3.2, 1.3, z), C.Ink, M.Rubber, { solid = true }, false)
			B.cyl(car, "Hubcap", b, 1.3, 0.1, V(sx * 3.72, 1.3, z), C.Metal, M.Metal, { small = true }, false)
		end
		R2("Headlight", V(1.3, 0.6, 0.1), V(sx * 2.4, 2.8, -8.02), Color3.fromRGB(230, 225, 200), M.Glass, { small = true })
		R2("Taillight", V(0.9, 1.4, 0.1), V(sx * 2.9, 3.4, 8.02), C.Blood:Lerp(C.Ink, 0.2), M.Glass, { small = true })
	end
	R2("BumperFront", V(7.2, 0.7, 0.6), V(0, 1.2, -8.1), C.Metal:Lerp(C.Ink, 0.3), M.Metal)
	R2("BumperRear", V(7.2, 0.7, 0.6), V(0, 1.2, 8.1), C.Metal:Lerp(C.Ink, 0.3), M.Metal)
	R2("Grille", V(3, 0.8, 0.1), V(0, 2.6, -8.02), C.Ink, M.Metal, { small = true })
	R2("RoofRack", V(5.6, 0.2, 9), V(0, 6.45, 1.6), C.Ink, M.Metal, { small = true })
	R2("RearGlass", V(5.6, 1.8, 0.1), V(0, 5.2, 7.38), glass, M.Glass, { small = true })
	local trunk = R2("Trunk", V(6.4, 3.4, 0.3), V(0, 3.1, 8.05), body:Lerp(C.Ink, 0.08), M.SmoothPlastic)
	trunk.CanQuery = true
	R2("Plate", V(1.6, 0.7, 0.05), V(0, 2.2, 8.22), C.Paper, M.SmoothPlastic, { small = true })
	R2("Bag", V(1.6, 1.1, 1.2), V(-1.4, 4.4, 6.4), C.Mustard:Lerp(C.Ink, 0.2), M.Fabric, { small = true })
	car.PrimaryPart = car:FindFirstChild("Body")
end

----------------------------------------------------------------- player spawns (beside the car, facing the lych-gate / chapel path)
local SP = B.F("PlayerSpawns")
for i, x in { 10, 13.5, 17, 20.5, 24 } do
	local p = V(x, 0.1, -84)
	B.part(SP, "Spawn" .. i, V(2, 0.2, 2), CFrame.lookAt(p, V(0, 0.1, -70)), C.Paper, M.SmoothPlastic, { inv = true })
end

----------------------------------------------------------------- invisible boundary
local BD = B.F("Boundary", EX)
local function bwall(x0, z0, x1, z1)
	B.box(BD, "Boundary", x0, -2, z0, x1, 70, z1, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
end
bwall(-63, -103, 63, -102)
bwall(-63, -102, -62, 103)
bwall(62, -102, 63, 103)
bwall(-62, 102, 62, 103)
-- keep players off the churchyard walls' tops is unnecessary (no jumping); lane ends are walled by the boundary.

----------------------------------------------------------------- the moon, low behind the bell tower as seen from the lane
do
	-- on the sight line from the player spawns past the spire
	local moon = B.ball(EX, "Moon", CFrame.new(-138, 142, 142), 36, V(0, 0, 0), Color3.fromRGB(226, 228, 236), M.Neon, { small = true })
	moon.Transparency = 0.05
end
root.WorldPivot = CFrame.new(B.O)
return "site ok, parts=" .. B.count(root)
