--!nocheck
-- build_lobby_3_props.luau  (run 3rd, after build_lobby_1_base.luau and build_lobby_2_cars.luau)
-- Spawn, Leaderboard, menu stations (ProximityPrompts with a Menu attribute), the "GRANDMA'S HOUSE →" sign,
-- streetlamps, bare trees, jack-o'-lanterns, leaves, low fog, and the distant hill with Grandma's crooked house.
-- Idempotent: destroys the folders/instances it owns first.

local C = {
	Ink = Color3.fromRGB(42, 26, 36),
	Night = Color3.fromRGB(59, 42, 63),
	Paper = Color3.fromRGB(243, 233, 210),
	Rose = Color3.fromRGB(217, 122, 138),
	Mint = Color3.fromRGB(156, 197, 161),
	Mustard = Color3.fromRGB(224, 176, 79),
	Bruise = Color3.fromRGB(123, 92, 142),
	Blood = Color3.fromRGB(168, 50, 62),
}
local GS = game:GetService("GeometryService")
local M = Enum.Material
local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local function P(parent, props)
	local p = Instance.new(props.Class or "Part")
	props.Class = nil
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	p.CanQuery = false
	p.Material = M.SmoothPlastic
	if props.Shape then
		p.Shape = props.Shape
		props.Shape = nil
	end
	for k, v in props do
		p[k] = v
	end
	p.Parent = parent
	return p
end
local function F(parent, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end
local function Model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end
local function light(parent, class, props)
	local l = Instance.new(class)
	for k, v in props do
		l[k] = v
	end
	l.Parent = parent
	return l
end
local function text(part, face, str, font, color, canvas, props)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.CanvasSize = canvas
	g.LightInfluence = 0.6
	g.Parent = part
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.FontFace = Font.fromEnum(font)
	t.TextScaled = true
	t.TextColor3 = color
	t.Text = str
	for k, v in props or {} do
		t[k] = v
	end
	t.Parent = g
	return t
end
local function prompt(part, menu, action, object)
	local pp = Instance.new("ProximityPrompt")
	pp.Name = menu .. "Prompt"
	pp.ActionText = action
	pp.ObjectText = object
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 10
	pp.RequiresLineOfSight = false
	pp:SetAttribute("Menu", menu)
	pp.Parent = part
	return pp
end

local lobby = workspace:FindFirstChild("Lobby")
assert(lobby and lobby:FindFirstChild("Environment"), "run build_lobby_1_base.luau first")
local env = lobby.Environment
for _, n in { "Spawn", "Leaderboard", "Stations", "Sign" } do
	local o = lobby:FindFirstChild(n)
	if o then
		o:Destroy()
	end
end
for _, n in { "Lamps", "Trees", "Pumpkins", "Leaves", "Fog", "Distant", "YardProps", "LeaderboardFrame" } do
	local o = env:FindFirstChild(n)
	if o then
		o:Destroy()
	end
end

-- ground height lookup (for leaves / props on uneven bits)
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.FilterDescendantsInstances = { env.Ground, env.Home }
local function groundY(x, z)
	-- CanQuery is off on decor, so temporarily query via a filtered GetPartBoundsInRadius-free approach:
	local r = workspace:Raycast(V(x, 60, z), V(0, -80, 0), groundParams)
	return r and r.Position.Y or 0
end
-- decor parts have CanQuery=false, so enable it on ground pieces while scattering
local queryRestore = {}
for _, d in env.Ground:GetDescendants() do
	if d:IsA("BasePart") and not d.CanQuery then
		d.CanQuery = true
		table.insert(queryRestore, d)
	end
end
for _, n in { "Walkway", "Driveway" } do
	local d = env.Home:FindFirstChild(n)
	if d and not d.CanQuery then
		d.CanQuery = true
		table.insert(queryRestore, d)
	end
end
local deck = env.Home.Porch.Deck

-- ------------------------------------------------------------------ Spawn (porch, facing the minivans)
do
	local s = Instance.new("SpawnLocation")
	s.Name = "Spawn"
	s.Anchored = true
	s.Size = V(6, 1, 4)
	s.CFrame = CFrame.lookAt(V(6, 0.7, 30.6), V(-4, 0.7, -3))
	s.Neutral = true
	s.AllowTeamChangeOnTouch = false
	s.Duration = 0
	s.Transparency = 1
	s.CanCollide = true
	s.CanTouch = true
	s.CanQuery = false
	s.CastShadow = false
	s.TopSurface = Enum.SurfaceType.Smooth
	for _, c in s:GetChildren() do
		if c:IsA("Decal") then
			c:Destroy()
		end
	end
	s.Parent = lobby
end

-- ------------------------------------------------------------------ Leaderboard (front face toward the yard)
do
	local center = V(-35, 6.5, 30)
	local cf = CFrame.lookAt(center, V(6, 6.5, 16))
	local board = P(lobby, { Name = "Leaderboard", Size = V(12, 8, 0.5), CFrame = cf, Material = M.WoodPlanks, Color = rgb(66, 46, 60), CanCollide = true, CanQuery = true })
	board:SetAttribute("Rows", board:GetAttribute("Rows") or "[]")
	local frame = Model(lobby.Environment, "LeaderboardFrame")
	local wood = rgb(92, 64, 58)
	for _, sx in { -1, 1 } do
		P(frame, { Name = "Post", Size = V(0.7, 11, 0.7), CFrame = cf * CF(sx * 6.4, -1, 0.35), Material = M.Wood, Color = wood })
		P(frame, { Name = "SideTrim", Size = V(0.4, 8.4, 0.3), CFrame = cf * CF(sx * 6.15, 0, 0.05), Material = M.Wood, Color = wood, CastShadow = false })
	end
	P(frame, { Name = "Cap", Size = V(13.8, 0.6, 1.2), CFrame = cf * CF(0, 4.35, 0.2), Material = M.Wood, Color = wood })
	P(frame, { Name = "Ledge", Size = V(12.6, 0.4, 0.8), CFrame = cf * CF(0, -4.2, 0.1), Material = M.Wood, Color = wood, CastShadow = false })
	P(frame, { Name = "BackBrace", Size = V(12, 0.4, 0.3), CFrame = cf * CF(0, -2, 0.55), Material = M.Wood, Color = wood, CastShadow = false })
	local title = P(frame, { Name = "TitlePlank", Size = V(8.5, 1.5, 0.3), CFrame = cf * CF(0.4, 5.55, 0.1) * ANG(0, 0, math.rad(2.5)), Material = M.WoodPlanks, Color = rgb(214, 190, 150) })
	text(title, Enum.NormalId.Front, "BRAVEST GRANDKIDS", Enum.Font.LuckiestGuy, C.Blood, Vector2.new(600, 100))
	P(frame, { Name = "Nail", Shape = BALL, Size = V(0.25, 0.25, 0.25), CFrame = cf * CF(-3.4, 5.7, -0.05), Material = M.Metal, Color = C.Ink, CastShadow = false, CanCollide = false })
	P(frame, { Name = "Nail", Shape = BALL, Size = V(0.25, 0.25, 0.25), CFrame = cf * CF(4.2, 5.5, -0.05), Material = M.Metal, Color = C.Ink, CastShadow = false, CanCollide = false })
	-- little lantern hooked on the right post so the board reads at dusk
	local lan = P(frame, { Name = "BoardLantern", Size = V(0.7, 1.0, 0.7), CFrame = cf * CF(7.1, 3.2, -0.3), Material = M.Neon, Color = rgb(214, 132, 64), CastShadow = false, CanCollide = false })
	light(lan, "SpotLight", { Face = Enum.NormalId.Left, Range = 16, Angle = 110, Brightness = 1.2, Color = rgb(255, 190, 130) })
	P(frame, { Name = "LanternHook", Size = V(0.9, 0.12, 0.12), CFrame = cf * CF(6.75, 3.85, -0.3), Material = M.Metal, Color = C.Ink, CastShadow = false, CanCollide = false })
end

-- ------------------------------------------------------------------ Stations
local stations = F(lobby, "Stations")

-- Mailbox → Daily
do
	local m = Model(stations, "Mailbox")
	local base = CFrame.lookAt(V(-4.6, 0, 21.2), V(-4.6, 0, 10)) -- opening faces the street
	P(m, { Name = "Post", Size = V(0.45, 3.6, 0.45), CFrame = base * CF(0, 1.8, 0.2) * ANG(0, 0, math.rad(3)), Material = M.Wood, Color = rgb(92, 64, 58) })
	local blk = P(m, { Size = V(1.3, 0.8, 2.2), CFrame = base * CF(0.08, 4.0, 0) })
	local cyl = P(m, { Shape = CYL, Size = V(2.2, 1.3, 1.3), CFrame = base * CF(0.08, 4.4, 0) * ANG(0, math.pi / 2, 0) })
	local ok, res = pcall(function()
		return GS:UnionAsync(blk, { cyl }, { CollisionFidelity = Enum.CollisionFidelity.Box })
	end)
	local box = ok and res[1] or blk
	if ok then
		blk:Destroy()
		cyl:Destroy()
	end
	box.Name = "MailboxBody"
	box.Anchored = true
	box.UsePartColor = true
	box.Color = C.Bruise
	box.CanCollide = true
	box.Parent = m
	m.PrimaryPart = box
	P(m, { Name = "DoorLid", Size = V(1.32, 1.3, 0.1), CFrame = base * CF(0.08, 4.25, -1.12), Color = C.Bruise:Lerp(C.Ink, 0.2), CanCollide = false, CastShadow = false })
	P(m, { Name = "Letter", Size = V(0.8, 0.05, 0.9), CFrame = base * CF(0.08, 4.1, -1.3) * ANG(math.rad(-12), 0, 0), Color = C.Paper, CanCollide = false, CastShadow = false })
	P(m, { Name = "FlagArm", Size = V(0.08, 1.2, 0.18), CFrame = base * CF(0.78, 4.9, 0.5), Color = C.Blood, CanCollide = false, CastShadow = false })
	P(m, { Name = "Flag", Size = V(0.08, 0.45, 0.7), CFrame = base * CF(0.78, 5.35, 0.25), Color = C.Blood, CanCollide = false, CastShadow = false })
	local plate = P(m, { Name = "NamePlate", Size = V(0.05, 0.45, 1.6), CFrame = base * CF(-0.62, 4.1, 0), Color = C.Paper, CanCollide = false, CastShadow = false })
	text(plate, Enum.NormalId.Left, "THE KIDS", Enum.Font.PatrickHand, C.Ink, Vector2.new(300, 80))
	prompt(box, "Daily", "Check Mail", "Daily Candy")
end

-- Candy stand on the porch → Shop
do
	local m = Model(stations, "CandyStand")
	local base = CF(-9.5, 1.2, 31.3)
	local tbl = P(m, { Name = "CandyTable", Size = V(6, 2.9, 2.6), CFrame = base * CF(0, 1.45, 0), Material = M.Fabric, Color = C.Rose, CanCollide = true })
	m.PrimaryPart = tbl
	P(m, { Name = "Cloth", Size = V(6.4, 0.12, 3.0), CFrame = base * CF(0, 2.96, 0), Material = M.Fabric, Color = C.Paper, CanCollide = false })
	for i = 0, 9 do -- scalloped hem
		P(m, { Name = "Scallop", Shape = CYL, Size = V(0.1, 0.62, 0.62), CFrame = base * CF(-2.9 + i * 0.645, 2.82, -1.52) * ANG(0, math.pi / 2, 0), Material = M.Fabric, Color = C.Paper, CanCollide = false, CastShadow = false })
	end
	local bowlCols = { C.Mint, C.Mustard, C.Bruise }
	local candyCols = { C.Rose, C.Mustard, C.Mint, C.Paper, C.Blood, C.Bruise }
	local rng = Random.new(12)
	for i, bx in { -1.9, 0, 1.9 } do
		local ball = P(m, { Shape = BALL, Size = V(1.7, 1.7, 1.7), CFrame = base * CF(bx, 3.85, 0) })
		local top = P(m, { Size = V(2, 1, 2), CFrame = base * CF(bx, 4.35, 0) })
		local inner = P(m, { Shape = BALL, Size = V(1.45, 1.45, 1.45), CFrame = base * CF(bx, 3.9, 0) })
		local ok, res = pcall(function()
			return GS:SubtractAsync(ball, { top, inner }, { CollisionFidelity = Enum.CollisionFidelity.Box })
		end)
		ball:Destroy()
		top:Destroy()
		inner:Destroy()
		if ok then
			local bowl = res[1]
			bowl.Name = "Bowl"
			bowl.Anchored = true
			bowl.UsePartColor = true
			bowl.Color = bowlCols[i]
			bowl.CanCollide = false
			bowl.CanTouch = false
			bowl.CanQuery = false
			bowl.CastShadow = false
			bowl.CFrame = bowl.CFrame * CF(0, 0.02, 0)
			bowl.Parent = m
		end
		for k = 1, 9 do
			local a = rng:NextNumber(0, math.pi * 2)
			local r = rng:NextNumber(0, 0.5)
			P(m, {
				Name = "Candy",
				Shape = k % 3 == 0 and CYL or BALL,
				Size = k % 3 == 0 and V(0.45, 0.28, 0.28) or V(0.3, 0.3, 0.3),
				CFrame = base * CF(bx + math.cos(a) * r, 3.75 + rng:NextNumber(0, 0.3), math.sin(a) * r) * ANG(0, a, 0),
				Color = candyCols[rng:NextInteger(1, #candyCols)],
				CanCollide = false,
				CastShadow = false,
			})
		end
	end
	-- giant lollipop + hand-written card
	P(m, { Name = "LolliStick", Size = V(0.12, 2.4, 0.12), CFrame = base * CF(2.75, 4.2, 0.8), Color = C.Paper, CanCollide = false, CastShadow = false })
	P(m, { Name = "Lollipop", Shape = CYL, Size = V(0.2, 1.2, 1.2), CFrame = base * CF(2.75, 5.5, 0.8) * ANG(0, math.pi / 2, 0) * ANG(math.rad(10), 0, 0), Color = C.Rose, CanCollide = false, CastShadow = false })
	local card = P(m, { Name = "Card", Size = V(2.4, 1.4, 0.06), CFrame = base * CF(-0.6, 3.7, -1.3) * ANG(math.rad(-15), 0, math.rad(-4)), Color = C.Paper, CanCollide = false, CastShadow = false })
	text(card, Enum.NormalId.Front, "TAKE ONE.\n(she counts)", Enum.Font.PatrickHand, C.Blood, Vector2.new(240, 140))
	local pp = prompt(tbl, "Shop", "Browse", "Candy Stand")
	pp.UIOffset = Vector2.new(0, 0)
end

-- Coat rack + mirror on the porch → Cosmetics
do
	local m = Model(stations, "CoatRack")
	local base = CF(16.2, 1.2, 35.8)
	local pole = P(m, { Name = "RackPole", Shape = CYL, Size = V(6.6, 0.4, 0.4), CFrame = base * CF(0, 3.3, 0) * ANG(0, 0, math.pi / 2) * ANG(math.rad(2), 0, 0), Material = M.Wood, Color = rgb(96, 64, 56), CanCollide = true })
	m.PrimaryPart = pole
	for k = 0, 2 do
		P(m, { Name = "Foot", Size = V(2.2, 0.25, 0.3), CFrame = base * CF(0, 0.15, 0) * ANG(0, k * math.pi / 3, 0), Material = M.Wood, Color = rgb(96, 64, 56), CanCollide = false })
	end
	P(m, { Name = "Knob", Shape = BALL, Size = V(0.6, 0.6, 0.6), CFrame = base * CF(0.1, 6.7, 0), Material = M.Wood, Color = rgb(96, 64, 56), CanCollide = false, CastShadow = false })
	for k = 0, 3 do
		local a = k * math.pi / 2 + 0.4
		P(m, { Name = "Hook", Size = V(0.12, 0.12, 0.9), CFrame = base * CF(0.08, 6.1, 0) * ANG(0, a, 0) * CF(0, 0.15, -0.45) * ANG(math.rad(35), 0, 0), Material = M.Metal, Color = C.Ink, CanCollide = false, CastShadow = false })
	end
	-- hanging costumes: a sheet-ghost, a raincoat, a knit scarf; a pointy witch hat on top
	P(m, { Name = "GhostSheet", Size = V(1.7, 2.6, 0.35), CFrame = base * CF(0, 3.9, -0.55) * ANG(math.rad(4), 0.2, math.rad(2)), Material = M.Fabric, Color = C.Paper, CanCollide = false })
	P(m, { Name = "GhostHead", Shape = BALL, Size = V(1.5, 1.5, 1.5), CFrame = base * CF(0, 5.55, -0.6), Material = M.Fabric, Color = C.Paper, CanCollide = false })
	for _, ex in { -0.3, 0.3 } do
		P(m, { Name = "GhostEye", Size = V(0.24, 0.36, 0.05), CFrame = base * CF(ex, 5.6, -1.33) * ANG(0, 0.2, 0), Color = C.Ink, CanCollide = false, CastShadow = false })
	end
	P(m, { Name = "Raincoat", Size = V(1.5, 3.2, 0.6), CFrame = base * CF(0.7, 4.4, 0.45) * ANG(0, -0.9, math.rad(-3)), Material = M.Fabric, Color = C.Mustard, CanCollide = false })
	P(m, { Name = "Scarf", Size = V(0.4, 2.8, 0.15), CFrame = base * CF(-0.55, 4.6, 0.3) * ANG(0, 1.2, math.rad(4)), Material = M.Fabric, Color = C.Mint, CanCollide = false, CastShadow = false })
	P(m, { Name = "HatBrim", Shape = CYL, Size = V(0.1, 1.9, 1.9), CFrame = base * CF(0.1, 6.95, 0) * ANG(0, 0, math.pi / 2) * ANG(math.rad(8), 0, 0), Material = M.Fabric, Color = C.Bruise, CanCollide = false, CastShadow = false })
	P(m, { Class = "WedgePart", Name = "HatTip", Size = V(0.9, 1.4, 0.9), CFrame = base * CF(0.15, 7.7, 0) * ANG(0, 0, math.rad(12)), Material = M.Fabric, Color = C.Bruise, CanCollide = false, CastShadow = false })
	-- oval mirror on the house wall (z = 38)
	local mcf = CF(12.6, 5.6, 37.8)
	P(m, { Name = "MirrorFrame", Shape = CYL, Size = V(0.25, 3.8, 3.8), CFrame = mcf * ANG(0, math.pi / 2, 0), Material = M.Wood, Color = C.Mustard:Lerp(C.Ink, 0.3), CanCollide = false })
	P(m, { Name = "MirrorGlass", Shape = CYL, Size = V(0.1, 3.2, 3.2), CFrame = mcf * CF(0, 0, -0.12) * ANG(0, math.pi / 2, 0), Material = M.Glass, Color = rgb(170, 160, 190), Reflectance = 0.5, CanCollide = false, CastShadow = false })
	P(m, { Name = "MirrorCrack", Size = V(0.06, 1.4, 0.02), CFrame = mcf * CF(0.5, -0.2, -0.19) * ANG(0, 0, math.rad(28)), Color = C.Paper, CanCollide = false, CastShadow = false })
	prompt(pole, "Cosmetics", "Dress Up", "Coat Rack")
end

-- Grandma's diary on a stone pedestal under the dead tree → Diary
local diaryBase = CF(-27.5, 0, 20.5)
do
	local m = Model(stations, "Diary")
	local base = diaryBase * ANG(0, math.rad(-30), 0)
	P(m, { Name = "Plinth", Size = V(2.2, 0.5, 2.2), CFrame = base * CF(0, 0.25, 0), Material = M.Cobblestone, Color = rgb(120, 110, 118), CanCollide = true })
	P(m, { Name = "Column", Shape = CYL, Size = V(3, 1.1, 1.1), CFrame = base * CF(0, 2, 0) * ANG(0, 0, math.pi / 2), Material = M.Cobblestone, Color = rgb(128, 118, 124), CanCollide = true })
	P(m, { Name = "Top", Size = V(2.0, 0.35, 1.6), CFrame = base * CF(0, 3.6, 0) * ANG(math.rad(-14), 0, 0), Material = M.Cobblestone, Color = rgb(120, 110, 118), CanCollide = false })
	local top = base * CF(0, 3.85, 0) * ANG(math.rad(-14), 0, 0)
	local cover = P(m, { Name = "DiaryCover", Size = V(2.0, 0.12, 1.4), CFrame = top, Material = M.Fabric, Color = C.Blood:Lerp(C.Ink, 0.25), CanCollide = false })
	m.PrimaryPart = cover
	for _, sx in { -1, 1 } do
		P(m, { Name = "Pages", Size = V(0.9, 0.12, 1.25), CFrame = top * CF(sx * 0.47, 0.1, 0) * ANG(0, 0, math.rad(sx * -6)), Color = C.Paper:Lerp(C.Mustard, 0.15), CanCollide = false, CastShadow = false })
	end
	local pg = P(m, { Name = "Scribble", Size = V(0.8, 0.02, 1.1), CFrame = top * CF(0.47, 0.2, 0) * ANG(0, 0, math.rad(-6)), Transparency = 1, CanCollide = false, CastShadow = false })
	text(pg, Enum.NormalId.Top, "night 1...\nthey're coming\nfor my candy", Enum.Font.IndieFlower, C.Ink, Vector2.new(160, 220), { Rotation = 180 })
	P(m, { Name = "Ribbon", Size = V(0.1, 0.02, 1.2), CFrame = top * CF(0.1, 0.1, 0.9) * ANG(math.rad(40), 0, 0), Color = C.Mustard, CanCollide = false, CastShadow = false })
	-- candle
	P(m, { Name = "Candle", Shape = CYL, Size = V(0.7, 0.3, 0.3), CFrame = base * CF(0.8, 4.05, 0.55) * ANG(0, 0, math.pi / 2), Color = C.Paper, CanCollide = false, CastShadow = false })
	local flame = P(m, { Name = "Flame", Shape = BALL, Size = V(0.22, 0.22, 0.22), CFrame = base * CF(0.8, 4.52, 0.55), Material = M.Neon, Color = rgb(255, 190, 110), CanCollide = false, CastShadow = false })
	light(flame, "PointLight", { Range = 9, Brightness = 1.1, Color = rgb(255, 170, 110) })
	prompt(cover, "Diary", "Read", "Grandma's Diary")
end

-- Chore list pinned on a board by the garage → Quests
do
	local m = Model(stations, "ChoreBoard")
	local base = CFrame.lookAt(V(20.1, 4.6, 37.82), V(20.1, 4.6, 30))
	local board = P(m, { Name = "Corkboard", Size = V(3.2, 3.8, 0.2), CFrame = base, Material = M.Fabric, Color = rgb(150, 104, 72), CanCollide = false, CanQuery = true })
	m.PrimaryPart = board
	for _, e in { { 0, 2.0, 3.5, 0.3 }, { 0, -2.0, 3.5, 0.3 }, { -1.7, 0, 0.3, 4.3 }, { 1.7, 0, 0.3, 4.3 } } do
		P(m, { Name = "Frame", Size = V(e[3], e[4], 0.3), CFrame = base * CF(e[1], e[2], -0.05), Material = M.Wood, Color = C.Paper:Lerp(C.Ink, 0.2), CanCollide = false, CastShadow = false })
	end
	local note = P(m, { Name = "ChoreList", Size = V(2.2, 2.9, 0.04), CFrame = base * CF(-0.15, -0.1, -0.13) * ANG(0, 0, math.rad(-3)), Color = C.Paper, CanCollide = false, CastShadow = false })
	text(note, Enum.NormalId.Front, "CHORES\n1. rake leaves\n2. feed the cat\n3. get Grandma's candy\n4. DON'T wake her", Enum.Font.PatrickHand, C.Ink, Vector2.new(220, 290))
	local sticky = P(m, { Name = "StickyNote", Size = V(0.9, 0.9, 0.04), CFrame = base * CF(1.05, 1.15, -0.15) * ANG(0, 0, math.rad(8)), Color = C.Mustard, CanCollide = false, CastShadow = false })
	text(sticky, Enum.NormalId.Front, "31 nights!!", Enum.Font.PatrickHand, C.Blood, Vector2.new(100, 100))
	for _, px in { { -0.2, 1.3 }, { 1.05, 1.5 } } do
		P(m, { Name = "Pin", Shape = BALL, Size = V(0.22, 0.22, 0.22), CFrame = base * CF(px[1], px[2], -0.2), Color = C.Blood, CanCollide = false, CastShadow = false })
	end
	local bulb = P(m, { Name = "BoardLight", Size = V(0.5, 0.3, 0.5), CFrame = base * CF(0, 2.5, -0.5), Material = M.Neon, Color = rgb(214, 136, 70), CanCollide = false, CastShadow = false })
	light(bulb, "SpotLight", { Face = Enum.NormalId.Bottom, Range = 8, Angle = 90, Brightness = 1.2, Color = rgb(255, 196, 140) })
	prompt(board, "Quests", "Read", "Chore List")
end

-- ------------------------------------------------------------------ "GRANDMA'S HOUSE →" sign
do
	local sign = Model(lobby, "Sign")
	local pos = V(-38, 0, -4) -- on the west sidewalk ring, clear of Car1 and its departure lane
	local cf = CFrame.lookAt(pos, pos + V(1, 0, 0.55)) -- arrow (screen-right) points up the road
	for _, sx in { -1, 1 } do
		P(sign, { Name = "Post", Size = V(0.55, 11, 0.55), CFrame = cf * CF(sx * 5.2, 5.5, 0.35) * ANG(0, 0, math.rad(sx * 1.5)), Material = M.Wood, Color = rgb(86, 60, 54), CanCollide = true })
	end
	local main = P(sign, { Name = "SignBoard", Size = V(13.5, 3.6, 0.35), CFrame = cf * CF(0, 8.4, 0) * ANG(0, 0, math.rad(-2.5)), Material = M.WoodPlanks, Color = rgb(222, 196, 150), CanCollide = false })
	sign.PrimaryPart = main
	-- "GRANDMA'S HOUSE" (fixed size, one line) + a painted arrow made of parts pointing up the road.
	-- (The → glyph falls back to a tiny font, so the arrow is painted instead.)
	-- Viewer's right on the Front face = the board's local -X.
	local title = text(main, Enum.NormalId.Front, "GRANDMA'S HOUSE", Enum.Font.LuckiestGuy, C.Blood, Vector2.new(900, 240), { TextStrokeTransparency = 0.6, TextStrokeColor3 = C.Ink })
	title.TextScaled = false
	title.TextWrapped = false
	title.TextSize = 72
	title.Size = UDim2.fromScale(0.72, 0.84)
	title.Position = UDim2.fromScale(0.03, 0.08)
	local mcf = main.CFrame
	P(sign, { Name = "ArrowShaft", Size = V(1.7, 0.55, 0.05), CFrame = mcf * CF(-4.95, -0.05, -0.2), Color = C.Blood, CanCollide = false, CastShadow = false })
	P(sign, { Name = "ArrowHead", Size = V(1.55, 0.55, 0.05), CFrame = mcf * CF(-5.45, 0.42, -0.21) * ANG(0, 0, math.rad(42)), Color = C.Blood, CanCollide = false, CastShadow = false })
	P(sign, { Name = "ArrowHead", Size = V(1.55, 0.55, 0.05), CFrame = mcf * CF(-5.45, -0.52, -0.21) * ANG(0, 0, math.rad(-42)), Color = C.Blood, CanCollide = false, CastShadow = false })
	local sub = P(sign, { Name = "SubPlank", Size = V(9, 1.5, 0.3), CFrame = cf * CF(-0.8, 5.9, 0.05) * ANG(0, 0, math.rad(3.5)), Material = M.WoodPlanks, Color = rgb(196, 170, 130), CanCollide = false })
	text(sub, Enum.NormalId.Front, "31 nights · don't wake her", Enum.Font.PatrickHand, C.Ink, Vector2.new(600, 100))
	P(sign, { Name = "PaintDrip", Size = V(0.18, 0.9, 0.05), CFrame = cf * CF(3.7, 6.6, -0.2), Color = C.Blood, CanCollide = false, CastShadow = false })
	P(sign, { Name = "PaintDrip", Size = V(0.15, 0.6, 0.05), CFrame = cf * CF(-4.6, 6.75, -0.2), Color = C.Blood, CanCollide = false, CastShadow = false })
	local lamp = P(sign, { Name = "SignLamp", Size = V(0.6, 0.4, 0.9), CFrame = cf * CF(0, 10.6, -0.9), Material = M.Neon, Color = rgb(214, 136, 70), CanCollide = false, CastShadow = false })
	P(sign, { Name = "SignLampArm", Size = V(0.15, 0.15, 1.2), CFrame = cf * CF(0, 10.6, -0.3), Material = M.Metal, Color = C.Ink, CanCollide = false, CastShadow = false })
	light(lamp, "SpotLight", { Face = Enum.NormalId.Bottom, Range = 10, Angle = 120, Brightness = 1.6, Color = rgb(255, 196, 140) })
end

-- ------------------------------------------------------------------ streetlamps
local lamps = F(env, "Lamps")
local function streetlamp(pos, towards, flicker, shadows)
	local m = Model(lamps, "Streetlamp")
	local dir = (V(towards.X, pos.Y, towards.Z) - pos).Unit
	local cf = CFrame.lookAt(pos, pos + dir)
	P(m, { Name = "Base", Size = V(1.1, 1.2, 1.1), CFrame = cf * CF(0, 0.6, 0), Material = M.Metal, Color = C.Ink, CanCollide = true })
	P(m, { Name = "Pole", Shape = CYL, Size = V(13, 0.45, 0.45), CFrame = cf * CF(0, 6.5, 0) * ANG(0, 0, math.pi / 2), Material = M.Metal, Color = C.Ink, CanCollide = true })
	P(m, { Name = "Arm", Size = V(0.3, 0.3, 3.2), CFrame = cf * CF(0, 12.8, -1.5) * ANG(math.rad(-8), 0, 0), Material = M.Metal, Color = C.Ink, CanCollide = false })
	P(m, { Name = "Curl", Shape = CYL, Size = V(0.2, 1.4, 1.4), CFrame = cf * CF(0, 12.1, -0.7), Material = M.Metal, Color = C.Ink, CanCollide = false, CastShadow = false })
	P(m, { Name = "Hood", Size = V(1.5, 0.6, 1.9), CFrame = cf * CF(0, 12.75, -3.2), Material = M.Metal, Color = C.Ink, CanCollide = false })
	local bulb = P(m, { Name = "Bulb", Size = V(1.1, 0.3, 1.4), CFrame = cf * CF(0, 12.35, -3.2), Material = M.Neon, Color = rgb(232, 162, 100), CanCollide = false, CastShadow = false })
	light(bulb, "SpotLight", { Face = Enum.NormalId.Bottom, Range = 30, Angle = 110, Brightness = 2.0, Color = rgb(255, 190, 128), Shadows = shadows == true })
	light(bulb, "PointLight", { Range = 7, Brightness = 0.6, Color = rgb(255, 190, 128) })
	m.PrimaryPart = bulb
	m:SetAttribute("Flicker", flicker == true)
	return m
end
local center = V(0, 0, -14) -- cul-de-sac centre (see build_lobby_1_base.luau)
streetlamp(V(-25, 0, 11), center, false, true)
streetlamp(V(25, 0, 11), center, true, true)
streetlamp(V(-34, 0, -16), center, false, false)
streetlamp(V(34, 0, -16), center, false, false)
streetlamp(V(-25.5, 0, -52), V(0, 0, -52), false, false)
streetlamp(V(25.5, 0, -64), V(0, 0, -64), false, false)
streetlamp(V(-25.5, 0, -88), V(0, 0, -88), true, false)
streetlamp(V(12.5, -0.3, -150), V(0, 0, -150), false, false)
streetlamp(V(-12.5, -0.3, -230), V(0, 0, -230), true, false)
streetlamp(V(12.5, -0.3, -320), V(0, 0, -320), false, false)

-- ------------------------------------------------------------------ bare trees
local trees = F(env, "Trees")
local bark = rgb(54, 40, 48)
local function tree(parent, pos, height, seed, levels, collide)
	local rng = Random.new(seed)
	local m = Model(parent, "BareTree")
	local function branch(cf, len, rad, lvl)
		P(m, {
			Name = lvl == 0 and "Trunk" or "Branch",
			Shape = CYL,
			Size = V(len, rad * 2, rad * 2),
			CFrame = cf * CF(0, len / 2, 0) * ANG(0, 0, math.pi / 2),
			Material = M.Wood,
			Color = bark:Lerp(C.Bruise, rng:NextNumber(0, 0.12)),
			CanCollide = collide and lvl == 0,
			CastShadow = lvl <= 2,
		})
		if lvl >= levels then
			return
		end
		local tip = cf * CF(0, len * 0.94, 0)
		local n = lvl == 0 and 3 or rng:NextInteger(2, 3)
		local spin = rng:NextNumber(0, math.pi * 2)
		for i = 1, n do
			local yaw = spin + (i / n) * math.pi * 2 + rng:NextNumber(-0.5, 0.5)
			local pitch = rng:NextNumber(0.35, 0.85)
			branch(tip * ANG(0, yaw, 0) * ANG(pitch, 0, 0) * ANG(0, rng:NextNumber(-1, 1), 0), len * rng:NextNumber(0.55, 0.78), rad * 0.62, lvl + 1)
		end
		if lvl == 0 then -- a low, crooked side limb
			branch(cf * CF(0, len * 0.55, 0) * ANG(0, rng:NextNumber(0, 6.28), 0) * ANG(1.1, 0, 0), len * 0.5, rad * 0.55, 2)
		end
	end
	local lean = ANG(math.rad(rng:NextNumber(-6, 6)), rng:NextNumber(0, 6.28), math.rad(rng:NextNumber(-6, 6)))
	branch(CF(pos) * lean, height * 0.42, height * 0.04, 0)
	return m
end
local treeSpots = {
	{ V(-39, 0, 22), 26 },
	{ V(-40, 0, 50), 22 },
	{ V(44, 0, 22), 18 },
	{ V(-37, 0, -40), 24 },
	{ V(37, 0, -8), 22 },
	{ V(36, 0, -62), 20 },
	{ V(-64, 0, 4), 24 },
	{ V(65, 0, -2), 22 },
	{ V(-66, 0, -86), 22 },
	{ V(64, 0, -86), 24 },
	{ V(-30, 0, 60), 20 },
}
for i, t in treeSpots do
	tree(trees, t[1], t[2], 100 + i, 3, true)
end
-- trees lining the far road and on the hill
local farTrees = F(trees, "Far")
for i = 1, 14 do
	local side = i % 2 == 0 and 1 or -1
	local z = -120 - i * 30
	tree(farTrees, V(side * (18 + (i * 7) % 11), -0.3, z), 20 + (i * 5) % 9, 300 + i, 2, false)
end

-- ------------------------------------------------------------------ jack-o'-lanterns
local pumpkins = F(env, "Pumpkins")
local pumpkinColor = rgb(214, 112, 46)
local function pumpkin(pos, s, lit, lookAt, seed)
	local rng = Random.new(seed or 1)
	local m = Model(pumpkins, lit and "JackOLantern" or "Pumpkin")
	local dir = lookAt and (V(lookAt.X, pos.Y, lookAt.Z) - pos) or V(0, 0, -1)
	if dir.Magnitude < 0.01 then
		dir = V(0, 0, -1)
	end
	local cf = CFrame.lookAt(pos, pos + dir.Unit) * ANG(0, 0, math.rad(rng:NextNumber(-6, 6)))
	local col = pumpkinColor:Lerp(C.Mustard, rng:NextNumber(0, 0.3))
	local body = P(m, { Name = "Body", Size = V(s, s * 0.78, s), CFrame = cf * CF(0, s * 0.37, 0), Color = col, CanCollide = false })
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = body
	m.PrimaryPart = body
	for k = 1, 2 do
		local lobe = P(m, { Name = "Lobe", Size = V(s * 0.62, s * 0.8, s * 1.02), CFrame = cf * CF(0, s * 0.37, 0) * ANG(0, k * math.pi / 3, 0), Color = col:Lerp(C.Blood, 0.08), CanCollide = false, CastShadow = false })
		local lm = Instance.new("SpecialMesh")
		lm.MeshType = Enum.MeshType.Sphere
		lm.Parent = lobe
	end
	P(m, { Name = "Stem", Shape = CYL, Size = V(s * 0.3, s * 0.12, s * 0.12), CFrame = cf * CF(0, s * 0.8, 0) * ANG(0, 0, math.pi / 2 + 0.25), Material = M.Wood, Color = rgb(78, 84, 52), CanCollide = false, CastShadow = false })
	if lit then
		local glow = rgb(255, 170, 70)
		for _, ex in { -1, 1 } do
			P(m, { Class = "WedgePart", Name = "Eye", Size = V(0.05, s * 0.2, s * 0.2), CFrame = cf * CF(ex * s * 0.2, s * 0.47, -s * 0.47) * ANG(0, math.pi / 2, 0) * ANG(ex > 0 and 0 or math.rad(10), 0, 0), Material = M.Neon, Color = glow, CanCollide = false, CastShadow = false })
		end
		P(m, { Name = "Mouth", Size = V(s * 0.5, s * 0.11, 0.05), CFrame = cf * CF(0, s * 0.25, -s * 0.48) * ANG(0, 0, math.rad(rng:NextNumber(-8, 8))), Material = M.Neon, Color = glow, CanCollide = false, CastShadow = false })
		P(m, { Name = "Tooth", Size = V(s * 0.08, s * 0.06, 0.07), CFrame = cf * CF(s * 0.07, s * 0.28, -s * 0.49), Color = col, CanCollide = false, CastShadow = false })
		light(body, "PointLight", { Range = 7 + s, Brightness = 0.9, Color = rgb(255, 150, 70) })
	end
	return m
end
local porchFront = V(0, 0, 12)
pumpkin(V(-4.2, 0, 26.4), 1.6, true, porchFront, 1)
pumpkin(V(4.3, 0, 26.2), 1.3, true, porchFront, 2)
pumpkin(V(-5.2, 0, 25.6), 0.9, false, nil, 3)
pumpkin(V(-16.6, 1.2, 29.3), 1.5, true, V(0, 0, 0), 4)
pumpkin(V(-3.2, 0, 20.4), 1.1, true, V(-3, 0, 0), 5)
pumpkin(V(-32.5, 0, 1.5), 1.7, true, V(0, 0, 20), 6)
pumpkin(V(-31, 0, 0.8), 1.0, false, nil, 7)
pumpkin(V(-30.5, 0, 28.4), 1.4, true, V(6, 0, 16), 8)
pumpkin(V(-25.8, 0, 19.2), 1.0, true, V(0, 0, 10), 9)
pumpkin(V(-44.3, 0.5, -28.6), 1.3, true, V(0, 0, -28), 10)
pumpkin(V(44.2, 0.5, -23.4), 1.4, true, V(0, 0, -23), 11)
pumpkin(V(-44.2, 0.5, -75.5), 1.1, true, V(0, 0, -75), 12)
pumpkin(V(22.6, 0, 36.6), 1.2, true, V(10, 0, 10), 13)
pumpkin(V(10.5, 1.2, 36.4), 1.0, false, nil, 14)
for i = 1, 6 do -- little pumpkin patch in the west yard
	pumpkin(V(-40 + (i % 3) * 2.4, 0, 34 + math.floor(i / 3) * 2.6), 0.9 + (i % 3) * 0.3, false, nil, 20 + i)
end
-- a smashed one on the sidewalk (someone woke her?)
do
	local m = Model(pumpkins, "SmashedPumpkin")
	for k = 1, 5 do
		P(m, { Name = "Shard", Size = V(0.6 + k * 0.1, 0.18, 0.4 + (k % 2) * 0.3), CFrame = CF(27.5 + k * 0.35, 0.3, 4 - k * 0.2) * ANG(0.2 * k, k, 0.15), Color = pumpkinColor, CanCollide = false, CastShadow = false })
	end
	P(m, { Name = "Splat", Size = V(2.2, 0.03, 1.6), CFrame = CF(28.4, 0.22, 3.6) * ANG(0, 0.5, 0), Color = pumpkinColor:Lerp(C.Mustard, 0.3), Transparency = 0.2, CanCollide = false, CastShadow = false })
end

-- ------------------------------------------------------------------ yard props: leaf piles, rake, trash can
local yard = F(env, "YardProps")
do
	P(yard, { Name = "RakeHandle", Size = V(0.18, 5.6, 0.18), CFrame = CF(39.2, 2.7, 39.4) * ANG(math.rad(-14), 0, math.rad(4)), Material = M.Wood, Color = rgb(150, 110, 80), CanCollide = false, CastShadow = false })
	P(yard, { Name = "RakeHead", Size = V(1.8, 0.2, 0.3), CFrame = CF(39.35, 0.3, 38.7), Material = M.Metal, Color = C.Blood:Lerp(C.Ink, 0.3), CanCollide = false, CastShadow = false })
	P(yard, { Name = "TrashCan", Shape = CYL, Size = V(3.2, 2.2, 2.2), CFrame = CF(42.8, 1.6, 38.2) * ANG(0, 0, math.pi / 2), Material = M.Metal, Color = rgb(90, 100, 96), CanCollide = true })
	P(yard, { Name = "TrashLid", Shape = CYL, Size = V(0.25, 2.5, 2.5), CFrame = CF(42.9, 3.3, 38.1) * ANG(0, 0, math.pi / 2 + 0.12), Material = M.Metal, Color = rgb(100, 110, 106), CanCollide = false })
end

-- ------------------------------------------------------------------ fallen leaves
local leaves = F(env, "Leaves")
local leafCols = { rgb(196, 98, 44), rgb(168, 72, 50), C.Mustard, rgb(140, 64, 58), rgb(186, 128, 60), C.Blood:Lerp(C.Mustard, 0.3) }
local rngL = Random.new(2031)
local blocked = {
	{ -22.5, 40.5, 37.5, 62.5 }, -- home + garage
	{ -68, -46, -37, -15 },
	{ 46, 68, -37, -15 },
	{ -66, -46, -80, -60 },
	{ 46, 68, -80, -60 },
	{ -18.5, 18.5, 28, 38.5 }, -- porch deck
}
local function isBlocked(x, z)
	for _, b in blocked do
		if x > b[1] and x < b[2] and z > b[3] and z < b[4] then
			return true
		end
	end
	return false
end
local function leaf(x, z, yOverride)
	local y = yOverride or groundY(x, z)
	P(leaves, {
		Name = "Leaf",
		Size = V(rngL:NextNumber(0.5, 0.8), 0.04, rngL:NextNumber(0.35, 0.55)),
		CFrame = CF(x, y + 0.03, z) * ANG(math.rad(rngL:NextNumber(-8, 8)), rngL:NextNumber(0, 6.28), math.rad(rngL:NextNumber(-8, 8))),
		Color = leafCols[rngL:NextInteger(1, #leafCols)],
		Material = M.Fabric,
		CanCollide = false,
		CastShadow = false,
	})
end
local placed = 0
while placed < 520 do
	local x, z
	if rngL:NextNumber() < 0.45 then -- cluster under trees
		local t = treeSpots[rngL:NextInteger(1, #treeSpots)]
		local a, r = rngL:NextNumber(0, 6.28), math.sqrt(rngL:NextNumber()) * 10
		x, z = t[1].X + math.cos(a) * r, t[1].Z + math.sin(a) * r
	else
		x, z = rngL:NextNumber(-75, 75), rngL:NextNumber(-92, 64)
	end
	if math.abs(x) < 76 and z > -92 and z < 65 and not isBlocked(x, z) then
		leaf(x, z)
		placed += 1
	end
end
-- leaf piles
for i, pile in { { V(43.5, 0, 30), 5.5 }, { V(-38, 0, 42), 6 }, { V(-58, 0, -8), 5 } } do
	local c, r = pile[1], pile[2]
	local mound = P(leaves, { Name = "LeafPile", Size = V(r * 2, r * 0.55, r * 1.7), CFrame = CF(c.X, 0.1, c.Z) * ANG(0, i, 0), Material = M.Fabric, Color = rgb(170, 84, 46), CanCollide = false, CastShadow = true })
	local mm = Instance.new("SpecialMesh")
	mm.MeshType = Enum.MeshType.Sphere
	mm.Parent = mound
	for k = 1, 34 do
		local a, rr = rngL:NextNumber(0, 6.28), math.sqrt(rngL:NextNumber())
		local lx, lz = math.cos(a) * rr * r * 0.95, math.sin(a) * rr * r * 0.8
		local h = 0.1 + (r * 0.275) * math.sqrt(math.max(0, 1 - rr * rr))
		leaf(c.X + lx, c.Z + lz, h)
	end
end

-- ------------------------------------------------------------------ low fog (drifting smoke sheets near the ground)
local fog = F(env, "Fog")
local function fogPatch(pos, size, rate)
	local p = P(fog, { Name = "FogEmitter", Size = size, CFrame = CF(pos), Transparency = 1, CanCollide = false, CastShadow = false })
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.EmissionDirection = Enum.NormalId.Top
	e.Rate = rate or 1.2
	e.Lifetime = NumberRange.new(14, 20)
	e.Speed = NumberRange.new(0.1, 0.35)
	e.SpreadAngle = Vector2.new(80, 80)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 8), NumberSequenceKeypoint.new(1, 16) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.87), NumberSequenceKeypoint.new(0.7, 0.88), NumberSequenceKeypoint.new(1, 1) })
	e.Color = ColorSequence.new(rgb(196, 168, 204))
	e.LightInfluence = 1
	e.LightEmission = 0
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-6, 6)
	e.Acceleration = V(0.15, -0.01, 0)
	e.Parent = p
	return p
end
for _, f in {
	{ V(0, 0.5, -20), V(44, 0.2, 40) },
	{ V(-45, 0.5, -20), V(34, 0.2, 60) },
	{ V(45, 0.5, -20), V(34, 0.2, 60) },
	{ V(0, 0.5, -70), V(40, 0.2, 40) },
	{ V(-45, 0.5, -75), V(34, 0.2, 30) },
	{ V(45, 0.5, -75), V(34, 0.2, 30) },
	{ V(-32, 0.5, 30), V(26, 0.2, 30) },
	{ V(0, 0.2, -140), V(90, 0.2, 60), 3 },
	{ V(0, 0.2, -260), V(160, 0.2, 120), 4 },
} do
	fogPatch(f[1], f[2], f[3])
end

-- ------------------------------------------------------------------ the distance: hill, road, poles, Grandma's crooked house
local far = F(env, "Distant")
local hillCol = rgb(50, 42, 56)
P(far, { Name = "Hill", Shape = BALL, Size = V(700, 700, 700), CFrame = CF(0, -290, -620), Material = M.Grass, Color = hillCol })
P(far, { Name = "HillWest", Shape = BALL, Size = V(760, 760, 760), CFrame = CF(-430, -320, -700), Material = M.Grass, Color = hillCol:Lerp(C.Night, 0.3) })
P(far, { Name = "HillEast", Shape = BALL, Size = V(720, 720, 720), CFrame = CF(420, -330, -660), Material = M.Grass, Color = hillCol:Lerp(C.Night, 0.3) })
-- telephone poles along the road (a bit crooked)
do
	local prev
	for i = 0, 9 do
		local z = -110 - i * 44
		local pos = V(15, -0.3, z)
		local tilt = ANG(math.rad(((i * 37) % 7) - 3), 0, math.rad(((i * 53) % 9) - 4))
		local base = CF(pos) * tilt
		P(far, { Name = "Pole", Shape = CYL, Size = V(22, 0.7, 0.7), CFrame = base * CF(0, 11, 0) * ANG(0, 0, math.pi / 2), Material = M.Wood, Color = rgb(70, 52, 50) })
		P(far, { Name = "Crossbar", Size = V(5, 0.4, 0.4), CFrame = base * CF(0, 20.5, 0), Material = M.Wood, Color = rgb(70, 52, 50), CastShadow = false })
		local ends = { (base * CF(-2.3, 20.8, 0)).Position, (base * CF(2.3, 20.8, 0)).Position }
		if prev then
			for k = 1, 2 do
				local a, b = prev[k], ends[k]
				P(far, { Name = "Wire", Size = V(0.07, 0.07, (b - a).Magnitude), CFrame = CFrame.lookAt((a + b) / 2 - V(0, 0.6, 0), b), Color = C.Ink, CastShadow = false })
			end
		end
		prev = ends
	end
end
-- Grandma's crooked house on the hilltop, one window lit
do
	local gm = Model(far, "GrandmasHouse")
	local hx, hy, hz = 6, 58, -585
	local dark = rgb(34, 24, 34)
	local dark2 = rgb(44, 32, 44)
	local function g(name, size, cf, col)
		return P(gm, { Name = name, Size = size, CFrame = CF(hx, hy, hz) * cf, Color = col or dark, CastShadow = false })
	end
	local body = g("Body", V(34, 22, 24), CF(0, 11, 0) * ANG(0, 0, math.rad(2.5)))
	gm.PrimaryPart = body
	g("Upper", V(28, 15, 21), CF(2.5, 29, 0.5) * ANG(0, 0, math.rad(-4)), dark2)
	P(gm, { Class = "WedgePart", Name = "RoofFront", Size = V(31, 14, 11.5), CFrame = CF(hx, hy, hz) * CF(3.2, 43.4, 5.9) * ANG(0, math.pi, 0) * ANG(0, 0, math.rad(5)), Color = dark, CastShadow = false })
	P(gm, { Class = "WedgePart", Name = "RoofBack", Size = V(31, 14, 11.5), CFrame = CF(hx, hy, hz) * CF(3.2, 43.4, -4.9) * ANG(0, 0, math.rad(-5)), Color = dark, CastShadow = false })
	g("Tower", V(9, 44, 9), CF(-18, 22, 3) * ANG(0, 0, math.rad(3)), dark2)
	P(gm, { Class = "WedgePart", Name = "Spire", Size = V(10, 18, 5), CFrame = CF(hx, hy, hz) * CF(-19.4, 53, 5.5) * ANG(0, math.pi, 0) * ANG(0, 0, math.rad(-4)), Color = dark, CastShadow = false })
	P(gm, { Class = "WedgePart", Name = "Spire", Size = V(10, 18, 5), CFrame = CF(hx, hy, hz) * CF(-19.4, 53, 0.5) * ANG(0, 0, math.rad(4)), Color = dark, CastShadow = false })
	g("Chimney", V(3, 16, 3), CF(12, 47, -2) * ANG(0, 0, math.rad(-11)))
	g("Porch", V(18, 1.2, 5), CF(2, 3.5, 14) * ANG(0, 0, math.rad(1.5)), dark2)
	g("PorchRoof", V(19, 0.8, 6), CF(2, 10, 14.3) * ANG(math.rad(-8), 0, math.rad(-2)))
	for _, px in { -6, 10 } do
		g("PorchPost", V(0.8, 7, 0.8), CF(px, 6.6, 16.2) * ANG(0, 0, math.rad(px > 0 and 4 or -2)), dark)
	end
	-- dark windows (a hair lighter than the walls) and ONE lit window
	for _, w in { { -8, 12 }, { 12, 12.5 }, { -3, 29 }, { -18, 32 } } do
		g("Window", V(3, 4, 0.3), CF(w[1], w[2], 12.2) * ANG(0, 0, math.rad(w[1] * 0.3)), rgb(56, 44, 60))
	end
	local lit = g("LitWindow", V(3.6, 4.6, 0.3), CF(9, 30, 11.2) * ANG(0, 0, math.rad(-4)), rgb(255, 170, 70))
	lit.Material = M.Neon
	g("LitWindowBar", V(0.35, 4.6, 0.35), CF(9, 30, 11.1) * ANG(0, 0, math.rad(-4)), dark)
	g("LitWindowBar", V(3.6, 0.35, 0.35), CF(9, 30, 11.1) * ANG(0, 0, math.rad(-4)), dark)
	light(lit, "PointLight", { Range = 40, Brightness = 2, Color = rgb(255, 160, 70) })
	-- dead trees and a crooked fence on the hill
	tree(gm, V(hx - 40, hy - 2, hz + 14), 38, 901, 3, false)
	tree(gm, V(hx + 38, hy - 3, hz + 6), 30, 902, 3, false)
	for i = 0, 9 do
		g("FencePost", V(0.8, 5, 0.8), CF(-20 + i * 5, 1.5, 24 + (i % 3) * 0.4) * ANG(0, 0, math.rad(((i * 29) % 17) - 8)), dark)
	end
	for _, d in gm:GetDescendants() do
		if d:IsA("BasePart") then
			d.CastShadow = false
			d.CanCollide = false
		end
	end
end
-- a big low moon behind the hill
do
	P(far, { Name = "Moon", Shape = CYL, Size = V(1, 150, 150), CFrame = CF(-150, 190, -1250) * ANG(0, math.pi / 2, 0), Material = M.Neon, Color = rgb(236, 214, 190), CanCollide = false, CastShadow = false })
end

-- restore CanQuery on ground decor
for _, d in queryRestore do
	d.CanQuery = false
end

-- ------------------------------------------------------------------ final normalisation
for _, d in lobby:GetDescendants() do
	if d:IsA("BasePart") then
		d.Anchored = true
	end
end
local n = 0
for _, d in lobby:GetDescendants() do
	if d:IsA("BasePart") then
		n += 1
	end
end
return "props ok, total lobby parts=" .. n
