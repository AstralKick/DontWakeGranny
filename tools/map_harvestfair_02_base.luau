-- HarvestFair base: map model + folders, ground, mud paths, perimeter hoarding + invisible boundary, car park,
-- Mom's car + spawns, entrance arch (FrontDoor gate), distant Ferris wheel and tree line. Idempotent (section "base").
local B = _G.HF
local C, M = B.C, B.M
local V = Vector3.new
local maps = workspace:FindFirstChild("Maps")
if not maps then
	maps = Instance.new("Folder")
	maps.Name = "Maps"
	maps.Parent = workspace
end
local root = maps:FindFirstChild("HarvestFair")
if not root then
	root = Instance.new("Model")
	root.Name = "HarvestFair"
	root.Parent = maps
end
B.attrs(root, { MapId = "HarvestFair", DisplayName = "The Harvest Fair", AreaName_Upstairs = "THE FUNHOUSE", AreaName_Basement = "THE GHOST TRAIN", AreaName_Attic = "THE BIG TOP" })
for _, n in { "PlayerSpawns", "Rooms", "LootSpawns", "PrizeSpawns", "SearchNodes", "Barriers", "Corruption", "Creaky", "Sections" } do
	B.F(n)
end
for i = 1, 4 do B.F(tostring(i), B.F("Corruption")) end
local S = B.begin("base")
local SM = { small = true }

----------------------------------------------------------------- ground (hole under the ghost train: x -100..-60, z 65..105)
local G = B.model(S, "Ground")
local function grass(x0, z0, x1, z1)
	B.box(G, "Grass", x0, -2, z0, x1, 0, z1, C.Grass, M.Grass, { solid = true })
end
grass(-260, -220, 260, 65)
grass(-260, 105, 260, 300)
grass(-260, 65, -100, 105)
grass(-60, 65, 260, 105)
-- mud paths (top 0.05), gravel car park (top 0.08)
local function mud(x0, z0, x1, z1, col)
	B.box(G, "Mud", x0, -0.3, z0, x1, 0.05, z1, col or C.Mud, M.Mud, { solid = true, shadow = false })
end
B.box(G, "CarPark", -48, -0.3, -143, 48, 0.08, -100, C.Stone:Lerp(C.Paper, 0.15), M.Pebble, { solid = true, shadow = false })
mud(-12, -100, 12, -92)
mud(-26, -92, 26, -70)
mud(-22, -70, 22, -5)
mud(-46, -66, -38, -11) -- west lane
mud(38, -66, 46, -11)
mud(-38, -66, -22, -58) -- south cross
mud(22, -66, 38, -58)
mud(-38, -19, -22, -11) -- north cross
mud(22, -19, 38, -11)
mud(-38, -42, -22, -35) -- island alleys
mud(22, -42, 38, -35)
mud(-40, -5, 50, 44) -- carousel plaza
mud(-64, -9, -40, -1) -- to the fortune tent (south flap)
mud(-64, -1, -56, 6)
mud(-48, 13, -40, 23) -- east flap
mud(50, 9, 58, 21) -- funhouse mouth
mud(-40, 44, 50, 60) -- big top promenade
mud(-96, 48, -40, 58) -- ghost train queue
mud(-96, 58, -64, 65)
mud(-40, 105, 40, 140, C.Dirt) -- backstage lot
mud(-58, 60, -42, 104) -- ghost alley
-- tractor ruts / puddles on the plaza
for i, p in { V(-20, 0, 30), V(26, 0, 6), V(8, 0, -40), V(-30, 0, -80) } do
	B.part(G, "Puddle", V(0.06, 5 + i, 3 + i * 0.5), CFrame.new(p + V(0, 0.07, 0)) * CFrame.Angles(0, math.rad(i * 37), math.rad(90)), C.Night:Lerp(C.Glass, 0.3), M.Glass, { small = true, tr = 0.3, shape = Enum.PartType.Cylinder, collide = false })
end

----------------------------------------------------------------- perimeter hoarding (painted boards) + boundary
local F = B.model(S, "Fence")
local board = C.WoodRaw:Lerp(C.Ink, 0.25)
local posts = {}
local function post(p)
	local k = math.floor(p.X * 10) .. ":" .. math.floor(p.Z * 10)
	if posts[k] then return end
	posts[k] = true
	B.part(F, "Post", V(0.8, 7.6, 0.8), CFrame.new(p + V(0, 3.8, 0)), C.WoodDark, M.Wood, { solid = true })
end
local function fence(x0, z0, x1, z1)
	local d = V(x1 - x0, 0, z1 - z0)
	local len = d.Magnitude
	local n = math.max(1, math.ceil(len / 12))
	for i = 0, n - 1 do
		local a = V(x0, 0, z0) + d * (i / n)
		local b = V(x0, 0, z0) + d * ((i + 1) / n)
		local mid = (a + b) / 2
		local col = if i % 3 == 0 then board:Lerp(C.Red, 0.25) elseif i % 3 == 1 then board else board:Lerp(C.Cream, 0.15)
		B.part(F, "Hoarding", V(0.4, 7, (b - a).Magnitude), CFrame.lookAt(mid + V(0, 3.5, 0), b + V(0, 3.5, 0)), col, M.WoodPlanks, { solid = true })
		post(a)
	end
	post(V(x1, 0, z1))
end
fence(-100, -95, -13.5, -95)
fence(13.5, -95, 100, -95)
fence(-100, -95, -100, 65)
fence(100, -95, 100, -5)
fence(100, 35, 100, 105)
fence(-60, 105, -40, 105)
fence(40, 105, 100, 105)
fence(-40, 105, -40, 140)
fence(40, 105, 40, 140)
fence(-40, 140, 40, 140)
-- car park: rail fence + hedge
local hedge = C.Grass:Lerp(C.Ink, 0.35)
B.box(F, "Hedge", -52, 0, -148, 52, 6.5, -144, hedge, M.LeafyGrass, { solid = true })
B.box(F, "Hedge", -52, 0, -144, -48, 6.5, -95, hedge, M.LeafyGrass, { solid = true })
B.box(F, "Hedge", 48, 0, -144, 52, 6.5, -95, hedge, M.LeafyGrass, { solid = true })
B.box(F, "Hedge", -100, 0, -99, -52, 6.5, -95.2, hedge, M.LeafyGrass, { solid = true })
B.box(F, "Hedge", 52, 0, -99, 100, 6.5, -95.2, hedge, M.LeafyGrass, { solid = true })
local BD = B.model(S, "Boundary")
local function bwall(x0, z0, x1, z1)
	B.box(BD, "Boundary", x0, -2, z0, x1, 60, z1, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
end
bwall(-54, -150, 54, -148.5)
bwall(-54, -150, -52.5, -95)
bwall(52.5, -150, 54, -95)
bwall(-102, -99, -52, -97.5)
bwall(52, -99, 102, -97.5)
bwall(-102, -99, -100.6, 105)
bwall(100.6, -99, 102, 105)
bwall(-102, 105.6, -40.6, 107) -- behind the ghost train and alley
bwall(40.6, 105.6, 102, 107)
bwall(-42, 105, -40.6, 142)
bwall(40.6, 105, 42, 142)
bwall(-42, 140.6, 42, 142)

----------------------------------------------------------------- entrance arch + FrontDoor gate (fence line z = -95)
local A = B.model(S, "EntranceArch")
for _, sx in { -1, 1 } do
	local x = sx * 12.75
	B.box(A, "Pillar", x - 0.75, 0, -95.75, x + 0.75, 16, -94.25, C.Red:Lerp(C.Ink, 0.2), M.Wood, { solid = true })
	B.box(A, "PillarCap", x - 1.1, 16, -96.1, x + 1.1, 16.6, -93.9, C.Gold:Lerp(C.Ink, 0.2), M.Wood, { small = true })
	B.pumpkinProp(A, V(x, 16.6, -95), 1.2, true)
	-- short board fillers between lane and gate
	B.box(A, "GateFence", sx * 2.6, 0, -95.25, sx * 4, 8.5, -94.75, board, M.WoodPlanks, { solid = true })
	B.box(A, "GatePost", sx * 4 - 0.35, 0, -95.4, sx * 4 + 0.35, 9.2, -94.6, C.WoodDark, M.Wood, { solid = true })
end
local sign = B.box(A, "ArchSign", -12, 12.2, -95.4, 12, 15.4, -94.6, C.Night, M.Wood, { solid = true })
B.text(sign, "HARVEST FAIR", { color = C.Mustard, face = Enum.NormalId.Front, pps = 30 })
B.text(sign, "COME BACK SOON", { color = C.Rose, face = Enum.NormalId.Back, pps = 30 })
B.box(A, "ArchTrim", -12, 11.8, -95.5, 12, 12.2, -94.5, C.Gold:Lerp(C.Ink, 0.3), M.Wood, { small = true })
B.doorway(A, "x", -95, 0, 0.05, 0.5, C.WoodDark)
local fd = B.door(root, "FrontDoor", "x", -95, 0, 0.05, "Ground", true, false, C.Cream:Lerp(C.Ink, 0.2), 1)
B.mark(fd)
-- slatted gate look
B.festoon(A, V(-12.75, 11.4, -95.8), V(12.75, 11.4, -95.8), 1.4, 14, "Ground", { seed = 1, range = 22 })
-- ticket prices board
local tb = B.box(A, "PriceBoard", 14.2, 5, -95.5, 18.2, 9, -95.2, C.Paper:Lerp(C.Ink, 0.15), M.Wood, { small = true })
B.text(tb, "RIDES 2 TICKETS\nGAMES 1 TICKET\nNO REFUNDS", { color = C.Ink, stroke = C.Paper, strokeT = 1, font = Enum.Font.SpecialElite })

----------------------------------------------------------------- Mom's car (nose toward the fair, trunk facing the car park)
do
	local car = B.model(root, "MomsCar")
	B.mark(car)
	local b = B.cf(22, 0.08, -122, "+z")
	local body = C.Bruise:Lerp(C.Paper, 0.55)
	local glass = Color3.fromRGB(40, 44, 60)
	local R = function(n, sz, off, col, mat, o) return B.rp(car, n, b, sz, off, col, mat, o or { solid = true }) end
	R("Body", V(7, 2.6, 16), V(0, 2.1, 0), body, M.SmoothPlastic)
	R("Cabin", V(6.7, 2.9, 11.5), V(0, 4.85, 1.6), body, M.SmoothPlastic)
	B.rp(car, "Hood", b, V(6.7, 1.4, 3.2), V(0, 4.1, -5.75), body, M.SmoothPlastic, { solid = true, class = "WedgePart" })
	local ws = R("Windshield", V(6.3, 0.1, 3.4), V(0, 4.9, -4.9), glass, M.Glass, { small = true })
	B.set(ws, b * CFrame.new(0, 4.95, -4.65) * CFrame.Angles(math.rad(-58), 0, 0))
	for _, sx in { -1, 1 } do
		R("SideGlass", V(0.1, 1.9, 10.4), V(sx * 3.4, 5.1, 1.6), glass, M.Glass, { small = true })
		R("Stripe", V(0.05, 0.3, 15.6), V(sx * 3.525, 2.7, 0), C.Rose:Lerp(C.Ink, 0.1), M.SmoothPlastic, { small = true })
		R("Mirror", V(0.6, 0.45, 0.3), V(sx * 3.7, 4.2, -3.2), body, M.SmoothPlastic, { small = true })
		for _, z in { -5, 5 } do
			B.cyl(car, "Wheel", b, 2.6, 1.0, V(sx * 3.2, 1.3, z), C.Ink, M.Rubber, { solid = true }, false)
			B.cyl(car, "Hubcap", b, 1.3, 0.1, V(sx * 3.75, 1.3, z), C.Metal, M.Metal, { small = true }, false)
		end
		R("Headlight", V(1.3, 0.6, 0.1), V(sx * 2.4, 2.8, -8.05), Color3.fromRGB(230, 225, 200), M.Glass, { small = true })
		R("Taillight", V(0.9, 1.4, 0.1), V(sx * 2.9, 3.4, 8.35), C.Blood:Lerp(C.Ink, 0.2), M.Glass, { small = true })
	end
	R("BumperFront", V(7.2, 0.7, 0.6), V(0, 1.2, -8.3), C.Metal:Lerp(C.Ink, 0.3), M.Metal)
	R("BumperRear", V(7.2, 0.7, 0.6), V(0, 1.2, 8.3), C.Metal:Lerp(C.Ink, 0.3), M.Metal)
	R("RoofRack", V(5.6, 0.2, 9), V(0, 6.4, 1.6), C.Ink, M.Metal, { small = true })
	R("RearGlass", V(5.6, 1.8, 0.1), V(0, 5.2, 7.4), glass, M.Glass, { small = true })
	local trunk = R("Trunk", V(6.4, 3.4, 0.3), V(0, 3.1, 8.15), body:Lerp(C.Ink, 0.08), M.SmoothPlastic)
	trunk.CanQuery = true
	R("Plate", V(1.6, 0.7, 0.05), V(0, 2.2, 8.325), C.Paper, M.SmoothPlastic, { small = true })
	R("Bag", V(1.6, 1.1, 1.2), V(-1.4, 4.4, 6.4), C.Mustard:Lerp(C.Ink, 0.2), M.Fabric, { small = true })
	car.PrimaryPart = car:FindFirstChild("Body")
end
-- player spawns beside the car, facing the entrance arch
local SP = B.F("PlayerSpawns")
for i, p in { V(12, 0.08, -110), V(8, 0.08, -113), V(12, 0.08, -116), V(8, 0.08, -119), V(12, 0.08, -122) } do
	B.mark(B.part(SP, "Spawn" .. i, V(2, 0.2, 2), CFrame.lookAt(p + V(0, 0.1, 0), V(0, 0.18, -95)), C.Paper, M.SmoothPlastic, { inv = true }))
end
-- car park dressing: other abandoned car silhouette, parking lamp post, wheel stops
B.lamp(S, "post", B.cf(-8, 0.08, -118, "-x"), "Ground", { range = 26, bright = 1.1, color = Color3.fromRGB(255, 200, 150) })
for i, x in { -38, -26, -14, 34 } do
	B.box(S, "WheelStop", x - 2.5, 0.08, -141, x + 2.5, 0.5, -140, C.Concrete, M.Concrete, { small = true, collide = true })
end
do
	local tr = B.model(S, "OldTractor")
	local b = B.cf(-30, 0.08, -125, 20)
	B.rp(tr, "Body", b, V(5, 4, 9), V(0, 3.5, 0), C.Red:Lerp(C.Ink, 0.4), M.Metal, { solid = true })
	B.rp(tr, "Cab", b, V(4.6, 4, 4), V(0, 7.5, 2), C.Red:Lerp(C.Ink, 0.45), M.Metal, { solid = true })
	for _, sx in { -1, 1 } do
		B.cyl(tr, "BigWheel", b, 6, 1.4, V(sx * 3.2, 3, 2.5), C.Ink, M.Rubber, { solid = true }, false)
		B.cyl(tr, "SmallWheel", b, 3.2, 1, V(sx * 3, 1.6, -3), C.Ink, M.Rubber, { solid = true }, false)
	end
end

----------------------------------------------------------------- Ferris wheel (decor, outside the fence to the north-east)
do
	local fw = B.model(S, "FerrisWheel")
	local ctr = V(70, 44, 190)
	local R0 = 34
	local o = { small = true }
	local steel = C.Cream:Lerp(C.Ink, 0.35)
	for i = 0, 15 do
		local a1, a2 = i / 16 * math.pi * 2, (i + 1) / 16 * math.pi * 2
		local p1 = ctr + V(math.cos(a1) * R0, math.sin(a1) * R0, 0)
		local p2 = ctr + V(math.cos(a2) * R0, math.sin(a2) * R0, 0)
		B.part(fw, "Rim", V(0.8, 0.8, (p2 - p1).Magnitude + 0.6), CFrame.lookAt((p1 + p2) / 2, p2), steel, M.Metal, o)
		if i % 2 == 0 then
			B.part(fw, "Spoke", V(0.4, 0.4, R0), CFrame.lookAt((ctr + p1) / 2, p1), steel, M.Metal, o)
			local g = p1 - V(0, 3, 0)
			B.part(fw, "Gondola", V(3, 3, 3.4), CFrame.new(g), if i % 4 == 0 then C.Teal else C.Red, M.Metal, o)
			B.part(fw, "GondolaRoof", V(3.6, 0.4, 4), CFrame.new(g + V(0, 1.7, 0)), C.Ink, M.Metal, o)
			if i == 4 or i == 10 then
				B.part(fw, "RimBulb", V(0.6, 0.6, 0.6), CFrame.new(p1 + V(0, 0, -0.6)), Color3.fromRGB(255, 200, 150), M.Neon, o)
			end
		end
	end
	B.cyl(fw, "Hub", CFrame.new(ctr), 4, 3, V(0, 0, 0), C.Ink, M.Metal, o, false).CFrame = B.OFF * CFrame.new(ctr) * CFrame.Angles(0, math.rad(90), 0)
	for _, sx in { -1, 1 } do
		local foot = V(ctr.X + sx * 22, 0, ctr.Z)
		B.part(fw, "Leg", V(1.2, 1.2, (ctr - foot).Magnitude), CFrame.lookAt((ctr + foot) / 2 + V(0, 0, 1.5), ctr + V(0, 0, 1.5)), C.Ink, M.Metal, o)
		B.part(fw, "Leg", V(1.2, 1.2, (ctr - foot).Magnitude), CFrame.lookAt((ctr + foot) / 2 + V(0, 0, -1.5), ctr + V(0, 0, -1.5)), C.Ink, M.Metal, o)
	end
	B.box(fw, "Platform", 50, 0, 184, 90, 1.5, 196, C.WoodDark, M.WoodPlanks, o)
end
-- dark tree line around the field
local T = B.model(S, "Trees")
local seeds = { { -150, -60 }, { -170, 20 }, { -140, 110 }, { -180, 160 }, { -110, 200 }, { -40, 210 }, { 140, -40 }, { 170, 50 }, { 150, 130 }, { 130, 230 }, { 190, -130 }, { -190, -140 }, { 20, 250 }, { -80, -190 }, { 90, -185 } }
for i, s in seeds do
	local x, z = s[1], s[2]
	local h = 14 + (i % 4) * 4
	B.box(T, "TreeTrunk", x - 1, 0, z - 1, x + 1, h, z + 1, C.WoodDark:Lerp(C.Ink, 0.5), M.Wood, SM)
	for k = 0, 2 do
		local d = 16 - k * 4.5
		B.part(T, "Canopy", V(d, d * 0.8, d), CFrame.new(x, h - 2 + k * 5, z), C.Grass:Lerp(C.Ink, 0.55), M.LeafyGrass, { small = true, shape = Enum.PartType.Ball })
	end
end
return "base ok, parts=" .. B.count(root)
