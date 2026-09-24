-- BackGarden 01: reset Workspace.Maps.BackGarden, map attributes, ground, boundary, house facade, porch,
-- Grandma's chair, lane + Mom's car + spawns, the lane wall with the garden gate. Requires 00_lib + 00b.
-- All coordinates are local to the map origin (1500, 0, 0); B.part adds the offset.
local B = _G.BGB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local SM = { small = true }
local maps = workspace:FindFirstChild("Maps")
if not maps then
	maps = Instance.new("Folder")
	maps.Name = "Maps"
	maps.Parent = workspace
end
local old = maps:FindFirstChild("BackGarden")
if old then old:Destroy() end
local root = Instance.new("Model")
root.Name = "BackGarden"
B.attrs(root, { MapId = "BackGarden", DisplayName = "The Back Garden", AreaName_Upstairs = "THE GREENHOUSE", AreaName_Basement = "THE POTTING SHED", AreaName_Attic = "THE HEDGE MAZE" })
root.Parent = maps
for _, n in { "PlayerSpawns", "Rooms", "LootSpawns", "PrizeSpawns", "SearchNodes", "Barriers", "Corruption", "Creaky", "Structure", "Exterior", "Ground", "Upstairs", "Basement", "Attic" } do
	B.F(n)
end
for i = 1, 4 do B.F(tostring(i), B.F("Corruption")) end
local S, EX, G = B.F("Structure"), B.F("Exterior"), B.F("Ground")

----------------------------------------------------------------- ground (hole for the cellar hatch at x -65.75..-58.75, z -8..3)
local function grass(x0, z0, x1, z1) B.box(EX, "Grass", x0, -1, z0, x1, 0, z1, C.Grass, M.Grass, { solid = true }) end
grass(-150, -120, 210, -8)
grass(-150, 7, 210, 130)
grass(-150, 3, -65.75, 7)
grass(-58.75, 3, 210, 7)
grass(-150, -8, -65.75, 3)
grass(-58.75, -8, 210, 3)

----------------------------------------------------------------- invisible boundary + visible walls
local BD = B.F("Boundary", EX)
local function bwall(x0, z0, x1, z1) B.box(BD, "Boundary", x0, -2, z0, x1, 60, z1, C.Paper, M.SmoothPlastic, { inv = true, collide = true }) end
bwall(-81, -58, -79, 64)
bwall(134, -58, 136, 64)
bwall(-81, -58, 136, -56)
bwall(-81, 62, 136, 64)
B.brickWall(S, -79, -56, -77, 62, 9) -- west
B.brickWall(S, -77, 60, -44, 62, 9) -- north-west (beside the house)
B.brickWall(S, 44, 60, 133, 62, 9) -- north-east
B.hedge(S, -77, -56, 71, -53, 9.5) -- lane south hedge
B.brickWall(S, 71, -56, 73, -29, 9) -- lane east end
B.hedge(S, 133, -56, 134, 60, 9.5, { nolumps = true }) -- east edge behind the maze

----------------------------------------------------------------- house facade (back of Grandma's house), faces -Z at z = 60
local HF = B.model(S, "HouseBack")
local siding = C.Siding:Lerp(C.Ink, 0.25)
B.box(HF, "HouseBody", -44, 0, 60, 44, 24, 86, siding, M.WoodPlanks, { solid = true })
B.box(HF, "Foundation", -44.3, 0, 59.7, 44.3, 1.2, 60, C.Brick, M.Brick, { small = true })
B.box(HF, "Trim", -44.3, 23.4, 59.6, 44.3, 24, 60, C.Paper:Lerp(C.Ink, 0.3), M.Wood, { small = true })
B.box(HF, "CornerBoard", -44.3, 1.2, 59.6, -43.7, 23.4, 60, C.Paper:Lerp(C.Ink, 0.3), M.Wood, { small = true })
B.box(HF, "CornerBoard", 43.7, 1.2, 59.6, 44.3, 23.4, 60, C.Paper:Lerp(C.Ink, 0.3), M.Wood, { small = true })
-- roof: front + back slopes (WedgePart slope rises toward +Z), end faces are the gables
B.part(HF, "Roof", V(92, 11, 16), CFrame.new(0, 29.5, 67), C.Roof, M.Slate, { solid = true, class = "WedgePart" })
B.part(HF, "Roof", V(92, 11, 16), CFrame.new(0, 29.5, 91) * CFrame.Angles(0, math.pi, 0), C.Roof, M.Slate, { solid = true, class = "WedgePart" })
B.box(HF, "Chimney", 22, 26, 72, 27, 40, 77, C.Brick, M.Brick, { solid = true })
B.box(HF, "ChimneyCap", 21.6, 40, 71.6, 27.4, 40.6, 77.4, C.Stone, M.Slate, { small = true })
B.box(HF, "Gutter", -46, 23.2, 58.6, 46, 23.7, 59.2, C.Metal:Lerp(C.Ink, 0.4), M.Metal, { small = true })
B.box(HF, "Downpipe", -43, 1, 58.7, -42.5, 23.2, 59.2, C.Metal:Lerp(C.Ink, 0.4), M.Metal, { small = true })
-- windows: ground floor (above the porch deck) and upstairs; one upstairs window glows
for _, x in { -26, 12, 22 } do B.fakeWindow(HF, x, 5.5, 60, 4, 5, false) end
for _, x in { -39.5, 38 } do B.fakeWindow(HF, x, 4.5, 60, 3.4, 5, false) end
for i, x in { -30, -12, 6, 24, 38 } do B.fakeWindow(HF, x, 15.8, 60, 4, 5, i == 3) end
-- a silhouette in the lit window
B.box(HF, "Silhouette", 5.2, 15.8, 59.84, 6.8, 18.6, 59.87, C.Ink, M.SmoothPlastic, { small = true })
B.part(HF, "SilhouetteHead", V(1.1, 1.1, 0.03), CFrame.new(6, 19.1, 59.855), C.Ink, M.SmoothPlastic, { small = true })
-- fake back door (locked set dressing, NOT a Door)
do
	local d = B.model(HF, "BackDoor_Locked")
	B.box(d, "Leaf", -16.25, 3, 59.8, -11.75, 11, 60, C.Rose:Lerp(C.Ink, 0.45), M.Wood, { small = true })
	B.box(d, "Casing", -16.6, 3, 59.6, -16.25, 11.35, 60, C.WoodDark, M.Wood, { small = true })
	B.box(d, "Casing", -11.75, 3, 59.6, -11.4, 11.35, 60, C.WoodDark, M.Wood, { small = true })
	B.box(d, "Casing", -16.25, 11, 59.6, -11.75, 11.35, 60, C.WoodDark, M.Wood, { small = true })
	B.box(d, "Window", -15.4, 7.6, 59.75, -12.6, 10.2, 59.8, Color3.fromRGB(34, 36, 50), M.Glass, { small = true })
	B.box(d, "KickPlate", -16, 3, 59.75, -12, 3.9, 59.8, C.Brass:Lerp(C.Ink, 0.3), M.Metal, { small = true })
	B.part(d, "Knob", V(0.32, 0.32, 0.32), CFrame.new(-12.4, 6.6, 59.65), C.Brass, M.Metal, { small = true, shape = Enum.PartType.Ball })
	B.box(d, "Bolt", -12.9, 7.3, 59.6, -12.1, 7.6, 59.8, C.Iron, M.Metal, { small = true })
end

----------------------------------------------------------------- back porch: deck top y = 3, x -34..29, z 46..60
local P = B.model(G, "BackPorch")
local deckC = C.WoodMid:Lerp(C.Paper, 0.08)
B.box(P, "Deck", -34, 2.6, 46, 29, 3, 60, deckC, M.WoodPlanks, { solid = true })
for _, seg in { { -33, -9.3 }, { 1.3, 17.7 }, { 28.3, 29.2 } } do -- not behind the step treads
	B.box(P, "DeckEdge", seg[1], 2.5, 45.8, seg[2], 2.9, 46, C.WoodDark, M.Wood, { small = true })
end
-- skirt boards + battens (the space under the deck is a hiding spot)
local skirtC = C.WoodDark:Lerp(C.Paper, 0.1)
B.box(P, "Skirt", -34, 0, 46, 29, 2.5, 46.3, skirtC, M.WoodPlanks, { solid = true })
B.box(P, "Skirt", -34, 0, 46.3, -33.7, 2.6, 59.7, skirtC, M.WoodPlanks, { solid = true })
B.box(P, "Skirt", 28.7, 0, 46.3, 29, 2.6, 59.7, skirtC, M.WoodPlanks, { solid = true })
for x = -32, 28, 2.4 do
	if not ((x > -9.6 and x < 1.6) or (x > 17.4 and x < 28.6)) then B.box(P, "Batten", x - 0.15, 0, 45.85, x + 0.15, 2.5, 46, C.WoodDark, M.Wood, SM) end
end
-- piers under the deck: they close the crawl-space bay that is the under-porch hiding spot
for _, x in { -17.2, -11.1 } do B.box(P, "Pier", x, 0, 46.3, x + 0.3, 2.6, 59.7, skirtC, M.WoodPlanks, { solid = true }) end
B.box(P, "Pier", -16.9, 0, 56.4, -11.1, 2.6, 56.7, skirtC, M.WoodPlanks, { solid = true })
-- posts, rails, roof
local postC = C.Paper:Lerp(C.Ink, 0.28)
for _, x in { -33.4, -20, -9.4, 1.4, 17.6, 28.4 } do
	B.box(P, "Post", x - 0.3, 3, 46.1, x + 0.3, 13, 46.7, postC, M.Wood, { solid = true })
end
local function rail(x0, z0, x1, z1)
	B.box(P, "Rail", x0, 5.6, z0, x1, 5.9, z1, postC, M.Wood, { collide = true })
	B.box(P, "Rail", x0, 3.4, z0, x1, 3.6, z1, postC, M.Wood, SM)
	local len = math.max(math.abs(x1 - x0), math.abs(z1 - z0))
	for t = 0.9, len - 0.5, 0.9 do
		if math.abs(x1 - x0) > math.abs(z1 - z0) then
			B.box(P, "Baluster", x0 + t - 0.07, 3.6, (z0 + z1) / 2 - 0.07, x0 + t + 0.07, 5.6, (z0 + z1) / 2 + 0.07, postC, M.Wood, SM)
		else
			B.box(P, "Baluster", (x0 + x1) / 2 - 0.07, 3.6, z0 + t - 0.07, (x0 + x1) / 2 + 0.07, 5.6, z0 + t + 0.07, postC, M.Wood, SM)
		end
	end
end
rail(-33.1, 46.25, -20.3, 46.55)
rail(-19.7, 46.25, -9.7, 46.55)
rail(1.7, 46.25, 17.3, 46.55)
rail(-33.95, 46.7, -33.65, 59.6)
rail(28.65, 46.7, 28.95, 59.6)
-- the lattice gap between x 17.6..28.4 is the side steps; x -9.4..1.4 the main steps
B.box(P, "PorchCeiling", -34.5, 13, 45.5, 29.5, 13.4, 60, C.Paper:Lerp(C.Ink, 0.35), M.WoodPlanks, { solid = true })
B.part(P, "PorchRoof", V(64.4, 2.2, 14.9), CFrame.new(-2.5, 14.5, 52.75), C.Roof, M.Slate, { solid = true, class = "WedgePart" })
B.box(P, "Fascia", -34.6, 12.6, 45.3, 29.6, 13.4, 45.5, postC, M.Wood, SM)
-- steps (visible + invisible wedge ramp)
B.steps(P, -4, 43, 10.6, 6, 0, 3, "+z", C.WoodMid, M.WoodPlanks)
B.steps(P, 23, 43, 10.6, 6, 0, 3, "+z", C.WoodMid, M.WoodPlanks)
for _, x in { -9.5, 1.5 } do B.box(P, "StepCheek", x - 0.15, 0, 40, x + 0.15, 3.2, 46, C.WoodDark, M.Wood, { collide = true }) end
for _, x in { 17.5, 28.5 } do B.box(P, "StepCheek", x - 0.15, 0, 40, x + 0.15, 3.2, 46, C.WoodDark, M.Wood, { collide = true }) end
-- under-porch hiding spot (prone behind the skirt) + a loose lattice panel as the tell
do
	local h = B.model(P, "UnderPorch")
	B.proneInside(h, cf(-14, 0, 52, "-z"), "Ground", 10, 1.1, "Bed")
	local lp = B.part(h, "LooseBoard", V(2.6, 2.2, 0.15), CFrame.new(-14, 1.05, 45.6) * CFrame.Angles(math.rad(-14), 0, math.rad(6)), skirtC:Lerp(C.Paper, 0.1), M.WoodPlanks, SM)
	lp.CastShadow = true
end
-- porch lights (Lamps) + hanging lanterns
B.lamp(P, "porch", cf(-7, 9.6, 60, "-z"), "Ground", { shadows = true, range = 20, bright = 1.1, color = Color3.fromRGB(255, 190, 130) })
B.lamp(P, "porch", cf(16, 9.6, 60, "-z"), "Ground", { range = 18, bright = 0.9, color = Color3.fromRGB(255, 190, 130) })
B.hangLantern(P, V(-24, 13, 52), "Ground", { drop = 1.6 })
B.hangLantern(P, V(22, 13, 52), "Ground", { drop = 1.6 })
-- fuse box on the porch wall
B.part(root, "FuseBox", V(1.8, 2.4, 0.5), cf(-20.6, 8.2, 59.75, "-z"), C.Metal:Lerp(C.Mint, 0.2), M.Metal, { collide = true, query = true })
B.box(P, "Conduit", -20.7, 9.4, 59.75, -20.5, 13, 59.95, C.Metal, M.Metal, SM)
B.part(P, "FuseLever", V(0.5, 0.8, 0.2), cf(-20.2, 8.2, 59.4, "-z"), C.Blood, M.SmoothPlastic, SM)
B.part(P, "FuseLabel", V(1.2, 0.4, 0.05), cf(-20.8, 9.1, 59.475, "-z"), C.Paper, M.SmoothPlastic, SM)

----------------------------------------------------------------- Grandma's wicker rocking chair (GrandmaChair) + her side table
local chairCF = cf(2, 3, 54, "-z")
do
	local chair = B.armchair(root, chairCF, C.Wicker, "GrandmaChair", { w = 5.4, d = 5, trim = C.WoodLight, throw = C.Rose:Lerp(C.Ink, 0.25) })
	for _, sx in { -1, 1 } do
		B.rp(chair, "Rocker", chairCF, V(0.35, 0.3, 6.2), V(sx * 2.3, 0.15, 0.2), C.WoodDark, M.Wood, SM)
		B.rp(chair, "RockerTip", chairCF, V(0.35, 0.3, 1.0), V(sx * 2.3, 0.35, -3.35), C.WoodDark, M.Wood, SM, CFrame.Angles(math.rad(20), 0, 0))
	end
	for i = 0, 5 do
		B.rp(chair, "Weave", chairCF, V(5.3, 0.14, 0.06), V(0, 1.4 + i * 0.8, 2.53), C.Wicker:Lerp(C.Ink, 0.3), M.Fabric, SM)
	end
	B.rp(chair, "BackCushion", chairCF, V(3.4, 2.4, 0.4), V(0, 3.9, 1.2), C.Rose:Lerp(C.Paper, 0.3), M.Fabric, SM)
	B.part(root, "GrandmaSleepSpot", V(2, 2, 1), chairCF * CFrame.new(0, 2.3 + 1.3, 0.3), C.Paper, M.SmoothPlastic, { inv = true })
	-- knitting basket
	local kb = B.model(P, "KnittingBasket")
	B.cyl(kb, "Basket", cf(-2.3, 3, 51.4), 1.3, 0.9, V(0, 0.45, 0), C.Wicker:Lerp(C.Ink, 0.2), M.Fabric, SM, true)
	B.ball(kb, "Yarn", cf(-2.3, 3, 51.4), 0.6, V(0.2, 0.95, 0), C.Rose, M.Fabric, SM)
	B.ball(kb, "Yarn", cf(-2.3, 3, 51.4), 0.55, V(-0.25, 0.9, 0.2), C.Mint, M.Fabric, SM)
end
local st = B.table(P, cf(6.6, 3, 54.4), 2.2, 2.2, 2.8, C.WoodDark, { name = "SideTable", cloth = C.Paper })
B.lamp(P, "table", cf(7.0, 5.82, 54.9), "Ground", { shade = C.Mustard:Lerp(C.Rose, 0.4), range = 14, bright = 0.9, shadows = false })
B.cyl(P, "Teacup", cf(6.1, 5.82, 53.9), 0.5, 0.4, V(0, 0.2, 0), C.Paper, M.SmoothPlastic, SM, true)
B.cyl(P, "Saucer", cf(6.1, 5.82, 53.9), 0.8, 0.05, V(0, 0.025, 0), C.Paper, M.SmoothPlastic, SM, true)
-- porch furniture
do
	-- old drinks fridge (Searchable Fridge)
	local fb = cf(-30.5, 3, 57.9, "-z")
	local fr = B.model(P, "PorchFridge")
	local col = C.Mint:Lerp(C.Paper, 0.2)
	B.rp(fr, "Body", fb, V(3, 5.4, 2.6), V(0, 2.7, 0.3), col, M.SmoothPlastic, { solid = true })
	local door = B.rp(fr, "FridgeDoor", fb, V(2.9, 5.2, 0.25), V(0, 2.75, -1.1), col, M.SmoothPlastic, { collide = false })
	B.searchable(door, "Fridge", "Ground", 2)
	B.rp(fr, "Handle", fb, V(0.15, 1.4, 0.2), V(1.15, 3.2, -1.32), C.Metal, M.Metal, SM)
	B.rp(fr, "Badge", fb, V(0.9, 0.2, 0.05), V(0, 4.8, -1.25), C.Brass, M.Metal, SM)
	-- sideboard (one Searchable drawer, one Cabinet)
	local sb = B.dresser(P, cf(19, 3, 58.6, "-z"), 5, 2.2, 3.4, C.WoodMid, 3, "Ground", 2, { search = { 1 }, name = "PorchSideboard" })
	local low
	for _, c in sb:GetChildren() do
		if c.Name == "DrawerFront" and (not low or c.Position.Y < low.Position.Y) then low = c end
	end
	low.Name = "Cabinet"
	B.searchable(low, "Cabinet", "Ground", 2)
	-- glider bench with cushions
	local gb = B.model(P, "Glider")
	local b = cf(-22, 3, 57.6, "-z")
	B.rp(gb, "Seat", b, V(6, 0.3, 2.2), V(0, 1.8, 0), C.Iron, M.Metal, { solid = true })
	B.rp(gb, "Back", b, V(6, 2.2, 0.2), V(0, 3.1, 1.0), C.Iron, M.Metal, SM)
	for _, sx in { -1, 1 } do
		B.rp(gb, "Leg", b, V(0.2, 1.8, 2.2), V(sx * 2.9, 0.9, 0), C.Iron, M.Metal, SM)
		B.rp(gb, "Arm", b, V(0.3, 0.2, 2.2), V(sx * 3.05, 2.6, 0), C.Iron, M.Metal, SM)
	end
	B.rp(gb, "Cushion", b, V(5.6, 0.35, 2.0), V(0, 2.12, -0.05), C.WRose, M.Fabric, SM)
	B.rp(gb, "Pillow", b, V(1.4, 1.4, 0.4), V(-2, 2.9, 0.65), C.Mustard:Lerp(C.Ink, 0.2), M.Fabric, SM)
	-- doormat + boots + watering can
	B.box(P, "DoorMat", -16, 3, 57, -12, 3.06, 59.2, C.Mustard:Lerp(C.Ink, 0.4), M.Fabric, SM)
	for i, x in { -10.6, -9.9 } do
		B.box(P, "Boot", x - 0.3, 3, 58.2, x + 0.3, 4.3, 59.2 - i * 0.05, C.Ink:Lerp(C.Mint, 0.2), M.Rubber, SM)
	end
end
-- porch creaky boards (around the chair and the steps)
for _, p in { { -4, 49 }, { 8.4, 49.2 }, { -9, 53.8 }, { 12, 53 }, { 23, 49 }, { -26, 51 }, { -4, 57.4 } } do
	B.creak(p[1], 3, p[2])
end

----------------------------------------------------------------- the lane (Mom's car, spawns)
local L = B.model(G, "Lane")
B.box(L, "LaneGravel", -76.5, -0.2, -50, 68, 0.05, -32.5, C.Gravel, M.Pebble, { solid = true })
for i = 0, 10 do
	local x = -70 + i * 13 + (i % 3) * 2
	B.box(L, "Rut", x, 0.05, -45.2 + (i % 2) * 0.4, x + 7, 0.07, -44.8 + (i % 2) * 0.4, C.Dirt, M.Ground, SM)
end
-- Mom's car (pastel minivan), nose along +X; Trunk at the rear
do
	local car = B.model(root, "MomsCar")
	local b = cf(-2, 0, -41, "+x")
	local body = C.Bruise:Lerp(C.Paper, 0.55)
	local glass = Color3.fromRGB(40, 44, 60)
	local function R(n, sz, off, col, mat, o) return B.rp(car, n, b, sz, off, col, mat, o or { solid = true }) end
	R("Body", V(7, 2.6, 16), V(0, 2.1, 0), body, M.SmoothPlastic)
	R("Cabin", V(6.7, 2.9, 11.5), V(0, 4.85, 1.6), body, M.SmoothPlastic)
	B.rp(car, "Hood", b, V(6.7, 1.4, 3.2), V(0, 4.1, -5.75), body, M.SmoothPlastic, { solid = true, class = "WedgePart" })
	local ws = R("Windshield", V(6.3, 0.1, 3.4), V(0, 4.9, -4.9), glass, M.Glass, { small = true })
	ws.CFrame = B.SH * b * CFrame.new(0, 4.95, -4.65) * CFrame.Angles(math.rad(-58), 0, 0)
	for _, sx in { -1, 1 } do
		R("SideGlass", V(0.1, 1.9, 10.4), V(sx * 3.37, 5.1, 1.6), glass, M.Glass, { small = true })
		R("Pillar", V(0.15, 2.0, 0.35), V(sx * 3.39, 5.1, -1.4), body, M.SmoothPlastic, { small = true })
		R("Pillar", V(0.15, 2.0, 0.35), V(sx * 3.39, 5.1, 3.2), body, M.SmoothPlastic, { small = true })
		R("DoorSeam", V(0.05, 2.4, 0.08), V(sx * 3.52, 2.6, 0.2), C.Ink, M.SmoothPlastic, { small = true })
		R("Stripe", V(0.05, 0.3, 15.6), V(sx * 3.52, 2.7, 0), C.Rose:Lerp(C.Ink, 0.1), M.SmoothPlastic, { small = true })
		R("Mirror", V(0.6, 0.45, 0.3), V(sx * 3.7, 4.2, -3.2), body, M.SmoothPlastic, { small = true })
		for _, z in { -5, 5 } do
			B.cyl(car, "Wheel", b, 2.6, 1.0, V(sx * 3.2, 1.3, z), C.Ink, M.Rubber, { solid = true }, false)
			B.cyl(car, "Hubcap", b, 1.3, 0.1, V(sx * 3.72, 1.3, z), C.Metal, M.Metal, { small = true }, false)
		end
		R("Headlight", V(1.3, 0.6, 0.1), V(sx * 2.4, 2.8, -8.02), Color3.fromRGB(230, 225, 200), M.Glass, { small = true })
		R("Taillight", V(0.9, 1.4, 0.1), V(sx * 2.9, 3.4, 8.02), C.Blood:Lerp(C.Ink, 0.2), M.Glass, { small = true })
	end
	R("BumperFront", V(7.2, 0.7, 0.6), V(0, 1.2, -8.1), C.Metal:Lerp(C.Ink, 0.3), M.Metal)
	R("BumperRear", V(7.2, 0.7, 0.6), V(0, 1.2, 8.1), C.Metal:Lerp(C.Ink, 0.3), M.Metal)
	R("Grille", V(3, 0.8, 0.1), V(0, 2.6, -8.02), C.Ink, M.Metal, { small = true })
	R("RoofRack", V(5.6, 0.2, 9), V(0, 6.4, 1.6), C.Ink, M.Metal, { small = true })
	R("RearGlass", V(5.6, 1.8, 0.1), V(0, 5.2, 7.38), glass, M.Glass, { small = true })
	local trunk = R("Trunk", V(6.4, 3.4, 0.3), V(0, 3.1, 8.05), body:Lerp(C.Ink, 0.08), M.SmoothPlastic)
	trunk.CanQuery = true
	R("Plate", V(1.6, 0.7, 0.05), V(0, 2.2, 8.22), C.Paper, M.SmoothPlastic, { small = true })
	R("Bag", V(1.6, 1.1, 1.2), V(-1.4, 4.4, 6.4), C.Mustard:Lerp(C.Ink, 0.2), M.Fabric, { small = true })
	car.PrimaryPart = car:FindFirstChild("Body")
end
-- player spawns behind the car, facing the garden gate
do
	local SP = B.F("PlayerSpawns")
	local gate = V(-24, 0, -28)
	for i, p in { V(-20, 0, -36), V(-15.5, 0, -36.5), V(-20, 0, -40.5), V(-15.5, 0, -41), V(-17.8, 0, -45) } do
		B.part(SP, "Spawn" .. i, V(2, 0.2, 2), CFrame.lookAt(p + V(0, 0.15, 0), V(gate.X, 0.15, gate.Z)), C.Paper, M.SmoothPlastic, { inv = true })
	end
end
-- lane dressing: bins, a crooked lamp post, an old bike against the hedge
do
	for i, x in { 30, 34 } do
		local bin = B.model(L, "Dustbin")
		local b = cf(x, 0.05, -50.6)
		B.cyl(bin, "Bin", b, 2.2, 3.4, V(0, 1.7, 0), C.Metal:Lerp(C.Mint, 0.15 * i), M.Metal, { solid = true }, true)
		B.cyl(bin, "Lid", b, 2.4, 0.25, V(0, 3.52, 0), C.Metal:Lerp(C.Ink, 0.3), M.Metal, SM, true)
	end
	B.lanternPost(L, -34, 0.05, -50.5, "Ground", { h = 8, range = 22, bright = 0.8 })
	B.lanternPost(L, 52, 0.05, -50.5, "Ground", { h = 8, range = 22, bright = 0.7 })
	local bike = B.model(L, "OldBike")
	for _, x in { -51.5, -48.5 } do
		B.part(bike, "Wheel", V(0.15, 2.4, 2.4), CFrame.new(x, 1.26, -52.5) * CFrame.Angles(0, math.rad(90), 0), C.Ink, M.Rubber, { small = true, shape = Enum.PartType.Cylinder })
	end
	B.part(bike, "Frame", V(3.2, 0.2, 0.2), CFrame.new(-50, 1.9, -52.5), C.Blood:Lerp(C.Ink, 0.3), M.Metal, SM)
	B.part(bike, "Seat", V(0.8, 0.25, 0.4), CFrame.new(-50.8, 2.5, -52.5), C.Ink, M.Fabric, SM)
	B.part(bike, "Basket", V(1, 0.8, 1), CFrame.new(-48.2, 2.5, -52.5), C.Wicker, M.Fabric, SM)
end
-- lane-side hedge nook (HidingSpot, Ground) on the lane's south hedge
do
	local b = cf(8, 0.05, -51.1, "+z")
	local m = B.hideBox(L, b, "Ground", { name = "LaneHedgeNook", w = 4.8, d = 3.8, h = 8.4, col = C.Hedge, mat = M.LeafyGrass, doorColor = C.HedgeTop:Lerp(C.Ink, 0.15), kind = "Closet", slats = false })
	for _, c in m:GetChildren() do
		if c.Name == "Inset" or c.Name == "Handle" then c:Destroy() end
	end
	for i = 1, 6 do
		B.part(m, "Ivy", V(1.4, 2.2, 0.3), CFrame.new(8 - 2 + (i % 3) * 2, 1.5 + math.floor((i - 1) / 3) * 3.5, -49.1) * CFrame.Angles(0, 0, math.rad(i * 23)), C.Moss:Lerp(C.Ink, 0.2), M.LeafyGrass, SM)
	end
end

----------------------------------------------------------------- lane wall (z -29..-28) with the garden gate (Door) and a broken gap
local WL = B.model(S, "LaneWall")
local gateX = -24
for _, pc in B.pieces(-77, 71, 0, 9, { { c = gateX, w = B.DW + 0.7, h = 8.35 }, { c = 17.5, w = 7, h = 9 } }) do
	B.box(WL, "GardenWall", pc[1], pc[3], -29, pc[2], pc[4], -28, C.Brick, M.Brick, { solid = true })
end
for _, seg in { { -77, gateX - 2.6 }, { gateX + 2.6, 14 }, { 21, 71 } } do
	B.box(WL, "Coping", seg[1], 9, -29.2, seg[2], 9.4, -27.8, C.Stone:Lerp(C.Paper, 0.15), M.Slate, SM)
end
B.box(WL, "Coping", gateX - 2.6, 9, -29.2, gateX + 2.6, 9.4, -27.8, C.Stone:Lerp(C.Paper, 0.15), M.Slate, SM)
B.door2(G, "GardenGate", "x", -28.5, gateX, 0, "Ground", { style = "garden", color = C.Mint:Lerp(C.Ink, 0.45), wallT = 1, squeaky = true })
-- broken wall edges: rubble and jagged bricks
for i = 0, 7 do
	local x = 14 + (i % 4) * 0.9 + (if i >= 4 then 4.1 else 0)
	B.part(WL, "Rubble", V(0.9, 0.5, 0.6), CFrame.new(x, 0.24,-28.5 + ((i * 3) % 5 - 2) * 0.7) * CFrame.Angles(0, math.rad(i * 37), 0), C.Brick:Lerp(C.Paper, 0.08), M.Brick, SM)
end
root.WorldPivot = CFrame.new(1500, 0, 0)
return "01 ground ok, parts=" .. B.count(root)
