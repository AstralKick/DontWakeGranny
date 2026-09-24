--!nocheck
-- build_lobby_1_base.luau  (run 1st, via Studio MCP execute_luau, Edit datamodel)
-- Lobby for "31 Nights at Grandma's": Halloween-dusk cul-de-sac.
-- Recreates Workspace.Lobby from scratch (idempotent), removes default Baseplate/SpawnLocation,
-- sets base Lighting, and builds ground, street, sidewalks, family home + porch + garage,
-- neighbour houses, fences, hedges and invisible boundary walls.
-- Then run build_lobby_2_cars.luau and build_lobby_3_props.luau.
--
-- World layout (studs, +Y up, north = -Z):
--   Home front wall z=38 (porch z 28..38), cul-de-sac bulb centred (0,-14) r=33 (+4 sidewalk),
--   street x -22..22 (flared into the bulb) running north to z=-106 and on toward Grandma's hill (z≈-700).
--   Cars Car1..Car5 fanned around the bulb (CAR_LAYOUT below; keep in sync with build_lobby_2_cars.luau),
--   each angled toward the street so its 75-stud departure lane along LookVector stays on the asphalt.

local GS = game:GetService("GeometryService")
local Lighting = game:GetService("Lighting")

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
local M = Enum.Material
local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles

local function F(parent, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- Every part defaults to anchored decor (CanTouch/CanQuery off).
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

local function csg(kind, base, tools, opts)
	local ok, res = pcall(function()
		if kind == "union" then
			return GS:UnionAsync(base, tools, opts)
		elseif kind == "subtract" then
			return GS:SubtractAsync(base, tools, opts)
		else
			return GS:IntersectAsync(base, tools, opts)
		end
	end)
	assert(ok, "CSG failed: " .. tostring(res))
	local r = res[1]
	r.Anchored = true
	base:Destroy()
	for _, t in tools do
		t:Destroy()
	end
	return r
end

-- ------------------------------------------------------------------ cleanup
for _, n in { "Baseplate", "SpawnLocation", "Lobby" } do
	local old = workspace:FindFirstChild(n)
	if old then
		old:Destroy()
	end
end

local lobby = F(workspace, "Lobby")
local env = F(lobby, "Environment")

-- ------------------------------------------------------------------ lighting (base look; dusk)
Lighting.ClockTime = 18.3
Lighting.GeographicLatitude = 30
Lighting.Brightness = 1.8
Lighting.Ambient = rgb(52, 38, 62)
Lighting.OutdoorAmbient = rgb(122, 96, 136)
Lighting.ColorShift_Top = rgb(255, 168, 118)
Lighting.ColorShift_Bottom = rgb(96, 62, 120)
Lighting.EnvironmentDiffuseScale = 0.45
Lighting.EnvironmentSpecularScale = 0.35
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.35
Lighting.ExposureCompensation = 0.1
Lighting.FogEnd = 100000
Lighting.FogStart = 0

local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atm.Density = 0.34
atm.Offset = 0.15
atm.Color = rgb(206, 150, 168)
atm.Decay = rgb(96, 66, 118)
atm.Glare = 0.5
atm.Haze = 1.9
atm.Parent = Lighting

local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
bloom.Intensity = 0.5
bloom.Size = 26
bloom.Threshold = 1.25
bloom.Enabled = true
bloom.Parent = Lighting

local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
if rays then
	rays.Intensity = 0.04
	rays.Spread = 0.6
end
local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
if dof then
	dof.Enabled = false -- would blur Grandma's house on the hill
end
local cc = Lighting:FindFirstChild("LobbyGrade") or Instance.new("ColorCorrectionEffect")
cc.Name = "LobbyGrade"
cc.Saturation = 0.06
cc.Contrast = 0.07
cc.Brightness = 0
cc.TintColor = rgb(255, 243, 238)
cc.Parent = Lighting
local sky = Lighting:FindFirstChildOfClass("Sky")
if sky then
	sky.StarCount = 1500
	sky.SunAngularSize = 14
	sky.MoonAngularSize = 13
	sky.CelestialBodiesShown = false -- the lobby has its own big moon behind Grandma's hill
end

-- ------------------------------------------------------------------ ground & street
local ground = F(env, "Ground")
P(ground, { Name = "FarGround", Size = V(2048, 1, 2048), CFrame = CF(0, -0.8, -600), Material = M.Grass, Color = rgb(58, 54, 52) })
P(ground, { Name = "Lawn", Size = V(170, 1, 180), CFrame = CF(0, -0.5, -15), Material = M.Grass, Color = rgb(88, 92, 66) })

-- cul-de-sac geometry (shared with the car layout)
local BULB_C, BULB_R, STREET_HW = V(0, 0, -14), 33, 22
-- mouth fillets: fill the concave corner where the bulb meets the street (edge line A→B, per side)
local function fillet(parent, side, offset, y, h, w)
	local a, b = V(side * STREET_HW, y, -60), V(side * 28.5, y, -30)
	local mid = (a + b) / 2
	local cf = CFrame.lookAt(mid, V(a.X, y, a.Z))
	local out = cf.RightVector * (cf.RightVector.X * side > 0 and 1 or -1)
	return P(parent, { Size = V(w, h, (a - b).Magnitude + 2), CFrame = cf + out * (offset - w / 2) })
end
-- asphalt: cul-de-sac bulb + street + mouth fillets (one union)
do
	local disc = P(ground, { Shape = Enum.PartType.Cylinder, Size = V(0.2, BULB_R * 2, BULB_R * 2), CFrame = CF(0, -0.04, BULB_C.Z) * ANG(0, 0, math.pi / 2) })
	local strip = P(ground, { Size = V(STREET_HW * 2, 0.2, 92), CFrame = CF(0, -0.04, -60) })
	local f1, f2 = fillet(ground, 1, 0, -0.04, 0.2, 10), fillet(ground, -1, 0, -0.04, 0.2, 10)
	local u = csg("union", disc, { strip, f1, f2 }, { CollisionFidelity = Enum.CollisionFidelity.Box })
	u.Name = "Asphalt"
	u.UsePartColor = true
	u.Color = rgb(62, 54, 66)
	u.Material = M.Asphalt
	u.Parent = ground
end
-- sidewalk ring + side sidewalks (top y=0.2)
do
	local outer = P(ground, { Shape = Enum.PartType.Cylinder, Size = V(0.4, BULB_R * 2 + 8, BULB_R * 2 + 8), CFrame = CF(0, 0, BULB_C.Z) * ANG(0, 0, math.pi / 2) })
	local ostrip = P(ground, { Size = V(STREET_HW * 2 + 8, 0.4, 92), CFrame = CF(0, 0, -60) })
	local of1, of2 = fillet(ground, 1, 4, 0, 0.4, 14), fillet(ground, -1, 4, 0, 0.4, 14)
	local o = csg("union", outer, { ostrip, of1, of2 }, {})
	o.Parent = ground
	local inner = P(ground, { Shape = Enum.PartType.Cylinder, Size = V(1, BULB_R * 2, BULB_R * 2), CFrame = CF(0, 0, BULB_C.Z) * ANG(0, 0, math.pi / 2) })
	local istrip = P(ground, { Size = V(STREET_HW * 2, 1, 96), CFrame = CF(0, 0, -61) })
	local if1, if2 = fillet(ground, 1, 0, 0, 1, 10), fillet(ground, -1, 0, 0, 1, 10)
	local s = csg("subtract", o, { inner, istrip, if1, if2 }, { CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition })
	s.Name = "Sidewalk"
	s.UsePartColor = true
	s.Color = rgb(150, 138, 138)
	s.Material = M.Concrete
	s.Parent = ground
end
-- far road toward Grandma's (beyond the boundary)
P(ground, { Name = "FarRoad", Size = V(20, 0.46, 460), CFrame = CF(0, -0.17, -336), Material = M.Asphalt, Color = rgb(56, 48, 60) })
P(ground, { Name = "FarRoadEdge", Size = V(STREET_HW * 2, 0.44, 30), CFrame = CF(0, -0.18, -120), Material = M.Asphalt, Color = rgb(58, 50, 62) })

-- road paint: fanned parking bays for Mom's five cars + dashed centre line
-- CAR_LAYOUT must match build_lobby_2_cars.luau (pivot x/z on the ground, yaw in degrees; LookVector = the departure lane)
local CAR_LAYOUT = {
	{ x = -26.2, z = -16, yaw = -12 },
	{ x = -13.7, z = -12, yaw = -4 },
	{ x = -1.2, z = -8, yaw = 0 },
	{ x = 11.3, z = -12, yaw = 4 },
	{ x = 23.8, z = -16, yaw = 12 },
}
local function bayCF(i)
	local c = CAR_LAYOUT[i]
	return CF(c.x, 0, c.z) * ANG(0, math.rad(c.yaw), 0)
end
local paint = F(ground, "Paint")
local function bayLine(cf)
	P(paint, { Name = "BayLine", Size = V(0.35, 0.03, 16), CFrame = cf + V(0, 0.075, 0), Color = C.Paper, Transparency = 0.25, CanCollide = false, CastShadow = false })
end
-- a line left of each bay (door side is +X, so the right-hand line sits past the QueueZone); shared lines between neighbours
bayLine(bayCF(1) * CF(-5.2, 0, 1))
for i = 1, #CAR_LAYOUT - 1 do
	bayLine((bayCF(i) * CF(7.1, 0, 1)):Lerp(bayCF(i + 1) * CF(-5.2, 0, 1), 0.5))
end
bayLine(bayCF(#CAR_LAYOUT) * CF(7.1, 0, 1))
for z = -40, -104, -9 do
	P(paint, { Name = "Dash", Size = V(0.4, 0.03, 4), CFrame = CF(0, 0.075, z), Color = C.Mustard, Transparency = 0.3, CanCollide = false, CastShadow = false })
end
for i = 1, #CAR_LAYOUT do
	local s = P(paint, { Name = "BayStencil", Size = V(6, 0.03, 2.4), CFrame = bayCF(i) * CF(0, 0.075, -11), Transparency = 1, CanCollide = false, CastShadow = false })
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Top
	g.CanvasSize = Vector2.new(300, 120)
	g.LightInfluence = 1
	g.Parent = s
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.FontFace = Font.fromEnum(Enum.Font.LuckiestGuy)
	t.TextScaled = true
	t.TextColor3 = C.Paper
	t.TextTransparency = 0.3
	t.Text = "MOM"
	t.Rotation = 180
	t.Parent = g
end

-- ------------------------------------------------------------------ building helpers
local function window(parent, cf, w, h, lit, curtain)
	P(parent, { Name = "WinFrame", Size = V(w + 0.6, h + 0.6, 0.3), CFrame = cf * CF(0, 0, -0.05), Color = C.Paper, CastShadow = false })
	P(parent, {
		Name = "WinPane",
		Size = V(w, h, 0.1),
		CFrame = cf * CF(0, 0, -0.25),
		Material = lit and M.Neon or M.Glass,
		Color = lit and (typeof(lit) == "Color3" and lit or rgb(196, 126, 70)) or rgb(38, 28, 46),
		Transparency = lit and 0 or 0.05,
		CastShadow = false,
	})
	P(parent, { Name = "Muntin", Size = V(0.18, h, 0.12), CFrame = cf * CF(0, 0, -0.34), Color = C.Paper, CastShadow = false })
	P(parent, { Name = "Muntin", Size = V(w, 0.18, 0.12), CFrame = cf * CF(0, 0, -0.34), Color = C.Paper, CastShadow = false })
	P(parent, { Name = "Sill", Size = V(w + 1, 0.3, 0.7), CFrame = cf * CF(0, -h / 2 - 0.4, -0.3), Color = C.Paper, CastShadow = false })
	if curtain then
		for _, sx in { -1, 1 } do
			P(parent, { Name = "Curtain", Size = V(w * 0.26, h - 0.2, 0.08), CFrame = cf * CF(sx * (w / 2 - w * 0.13), 0, -0.31), Material = M.Fabric, Color = curtain, CastShadow = false })
		end
	end
end

local function shutters(parent, cf, w, h, color)
	for _, sx in { -1, 1 } do
		P(parent, { Name = "Shutter", Size = V(1.1, h + 0.4, 0.2), CFrame = cf * CF(sx * (w / 2 + 0.95), 0, -0.12) * ANG(0, 0, math.rad(sx * 1.5)), Color = color, CastShadow = false })
	end
end

-- frontCF: at ground level, centre of the front wall; LookVector = outward (the way the house faces)
local function house(parent, name, frontCF, o)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	local w, d, h, rh = o.w, o.d, o.h, o.roofH
	local base = o.base or 0
	P(m, { Name = "Foundation", Size = V(w + 0.4, 1 + base, d + 0.4), CFrame = frontCF * CF(0, (1 + base) / 2, d / 2), Material = M.Concrete, Color = rgb(96, 82, 92) })
	local body = P(m, { Name = "Walls", Size = V(w, h, d), CFrame = frontCF * CF(0, h / 2, d / 2), Material = M.WoodPlanks, Color = o.wall, CanQuery = true })
	m.PrimaryPart = body
	-- gable fill (wall colour) + roof slabs
	P(m, { Class = "WedgePart", Name = "Gable", Size = V(w, rh, d / 2), CFrame = frontCF * CF(0, h + rh / 2, d / 4), Material = M.WoodPlanks, Color = o.wall })
	P(m, { Class = "WedgePart", Name = "Gable", Size = V(w, rh, d / 2), CFrame = frontCF * CF(0, h + rh / 2, 3 * d / 4) * ANG(0, math.pi, 0), Material = M.WoodPlanks, Color = o.wall })
	local a = math.atan(rh / (d / 2))
	local ls = (d / 2) / math.cos(a) + 1.4
	for _, side in { 0, 1 } do
		local mid = frontCF * CF(0, h + rh / 2, side == 0 and d / 4 or 3 * d / 4) * ANG(0, side * math.pi, 0) * ANG(-a, 0, 0)
		P(m, { Name = "Roof", Size = V(w + 2.4, 0.6, ls), CFrame = mid * CF(0, 0.3, -0.7 + 0.35), Material = M.Slate, Color = o.roof })
	end
	P(m, { Name = "Ridge", Size = V(w + 2.6, 0.5, 0.9), CFrame = frontCF * CF(0, h + rh + 0.3, d / 2), Material = M.Slate, Color = o.roof })
	-- trim band under eaves
	P(m, { Name = "Trim", Size = V(w + 0.3, 0.5, 0.3), CFrame = frontCF * CF(0, h - 0.25, -0.1), Color = o.trim or C.Paper })
	if o.chimney then
		P(m, { Name = "Chimney", Size = V(3, rh + 5, 3), CFrame = frontCF * CF(o.chimney, h + (rh + 5) / 2 - 1, d * 0.62) * ANG(0, 0, math.rad(2)), Material = M.Brick, Color = rgb(120, 70, 72) })
	end
	-- door
	if o.doorX then
		local dcf = frontCF * CF(o.doorX, base + 3.75, 0)
		P(m, { Name = "DoorTrim", Size = V(5.2, 8.3, 0.3), CFrame = dcf * CF(0, 0.3, -0.05), Color = C.Paper })
		P(m, { Name = "Door", Size = V(4, 7.5, 0.3), CFrame = dcf * CF(0, 0, -0.25), Material = M.Wood, Color = o.door or C.Rose })
		P(m, { Name = "Knob", Shape = Enum.PartType.Ball, Size = V(0.4, 0.4, 0.4), CFrame = dcf * CF(1.4, -0.3, -0.5), Material = M.Metal, Color = C.Mustard, CastShadow = false, CanCollide = false })
		for _, py in { 1.9, -1.9 } do
			P(m, { Name = "DoorPanel", Size = V(2.8, 2.6, 0.1), CFrame = dcf * CF(0, py, -0.42), Material = M.Wood, Color = (o.door or C.Rose):Lerp(C.Ink, 0.18), CastShadow = false, CanCollide = false })
		end
	end
	for _, win in o.windows or {} do
		local wcf = frontCF * CF(win[1], win[2], 0)
		window(m, wcf, win.w or 3.4, win.h or 4.4, win[3], win[4])
		if o.shutter then
			shutters(m, wcf, win.w or 3.4, win.h or 4.4, o.shutter)
		end
	end
	-- side windows so houses read from any angle
	for _, sw in o.sideWindows or {} do
		for _, sx in { -1, 1 } do
			local wcf = frontCF * CF(sx * w / 2, sw[2], sw[1]) * ANG(0, sx * -math.pi / 2, 0)
			window(m, wcf, 3, 4, sw[3], nil)
		end
	end
	return m
end

-- ------------------------------------------------------------------ the family home
local home = F(env, "Home")
local homeCF = CFrame.lookAt(V(0, 0, 38), V(0, 0, 37)) -- faces north toward the cars
local warm = rgb(196, 126, 70)
local house1 = house(home, "FamilyHouse", homeCF, {
	w = 44,
	d = 24,
	h = 22,
	roofH = 9,
	base = 1.2,
	wall = rgb(92, 78, 110), -- dusky plum siding
	roof = rgb(46, 32, 44),
	door = C.Rose,
	doorX = 0,
	chimney = -12,
	shutter = C.Bruise:Lerp(C.Ink, 0.25),
	windows = {
		{ -15, 5.8, warm, C.Rose },
		{ -8, 5.8, warm, nil },
		{ 8, 5.8, warm, C.Mustard },
		{ 15, 5.8, false, nil },
		{ -15, 16.5, false, nil },
		{ -8, 16.5, warm, C.Bruise },
		{ 0, 16.5, rgb(120, 170, 130), nil, w = 2.6, h = 3.6 }, -- kid's night-light (sickly mint)
		{ 8, 16.5, false, nil },
		{ 15, 16.5, warm, C.Rose },
	},
	sideWindows = { { 8, 6, warm }, { 16, 16.5, false } },
})
-- crooked TV antenna
P(house1, { Name = "Antenna", Size = V(0.2, 5, 0.2), CFrame = homeCF * CF(10, 33.5, 12) * ANG(0, 0, math.rad(8)), Material = M.Metal, Color = C.Ink, CastShadow = false })
P(house1, { Name = "Antenna", Size = V(4, 0.15, 0.15), CFrame = homeCF * CF(10.3, 35, 12) * ANG(0, 0.3, math.rad(-6)), Material = M.Metal, Color = C.Ink, CastShadow = false })
P(house1, { Name = "Antenna", Size = V(2.6, 0.15, 0.15), CFrame = homeCF * CF(10.5, 34.2, 12) * ANG(0, -0.2, math.rad(4)), Material = M.Metal, Color = C.Ink, CastShadow = false })

-- porch (top y = 1.2), z 28..38, x -18..18
local porch = Instance.new("Model")
porch.Name = "Porch"
porch.Parent = home
local deck = P(porch, { Name = "Deck", Size = V(36, 1.2, 10.2), CFrame = CF(0, 0.6, 33.1), Material = M.WoodPlanks, Color = rgb(122, 88, 74), CanQuery = true })
porch.PrimaryPart = deck
P(porch, { Name = "Skirt", Size = V(36.2, 1.0, 0.2), CFrame = CF(0, 0.5, 27.95), Material = M.WoodPlanks, Color = C.Paper:Lerp(C.Ink, 0.25) })
-- steps + invisible ramp (players can't jump)
for i, zc in { 25.5, 26.5, 27.5 } do
	P(porch, { Name = "Step", Size = V(6.4, 0.4 * i, 1), CFrame = CF(0, 0.2 * i, zc), Material = M.WoodPlanks, Color = rgb(132, 96, 80) })
end
P(porch, { Class = "WedgePart", Name = "StepRamp", Size = V(6.4, 1.2, 4), CFrame = CF(0, 0.6, 26), Transparency = 1, CanCollide = true })
-- posts, rails, balusters
local postColor = C.Paper:Lerp(rgb(200, 190, 175), 0.3)
for _, x in { -17.6, -3.6, 3.6, 17.6 } do
	P(porch, { Name = "Post", Size = V(0.7, 9, 0.7), CFrame = CF(x, 1.2 + 4.5, 28.4), Material = M.SmoothPlastic, Color = postColor })
end
for _, x in { -17.6, 17.6 } do
	P(porch, { Name = "Post", Size = V(0.7, 9, 0.7), CFrame = CF(x, 1.2 + 4.5, 37.6), Material = M.SmoothPlastic, Color = postColor })
end
local function railRun(a, b)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	P(porch, { Name = "Rail", Size = V(0.35, 0.25, len), CFrame = cf * CF(0, 3.2, 0), Material = M.SmoothPlastic, Color = postColor })
	P(porch, { Name = "Rail", Size = V(0.3, 0.2, len), CFrame = cf * CF(0, 0.5, 0), Material = M.SmoothPlastic, Color = postColor, CastShadow = false })
	local n = math.floor(len / 0.9)
	for i = 1, n - 1 do
		P(porch, { Name = "Baluster", Size = V(0.18, 2.7, 0.18), CFrame = cf * CF(0, 1.85, -len / 2 + i * len / n), Material = M.SmoothPlastic, Color = postColor, CastShadow = false, CanCollide = false })
	end
	-- invisible blocker along the rail
	P(porch, { Name = "RailBlock", Size = V(0.4, 4, len), CFrame = cf * CF(0, 2, 0), Transparency = 1, CanCollide = true })
end
railRun(V(-17.6, 1.2, 28.4), V(-3.6, 1.2, 28.4))
railRun(V(3.6, 1.2, 28.4), V(17.6, 1.2, 28.4))
railRun(V(-17.6, 1.2, 28.4), V(-17.6, 1.2, 37.6))
railRun(V(17.6, 1.2, 28.4), V(17.6, 1.2, 37.6))
-- porch roof
P(porch, { Name = "PorchCeiling", Size = V(37, 0.5, 10.8), CFrame = CF(0, 10.45, 33.1), Material = M.WoodPlanks, Color = rgb(120, 96, 112) })
P(porch, { Class = "WedgePart", Name = "PorchRoof", Size = V(37.6, 1.8, 11.4), CFrame = CF(0, 11.6, 32.9), Material = M.Slate, Color = rgb(46, 32, 44) })
P(porch, { Name = "Fascia", Size = V(37.4, 0.8, 0.3), CFrame = CF(0, 10.3, 27.65), Color = C.Paper })
-- bunting along the porch roof edge (Rose / Mustard / Mint / Bruise)
do
	local cols = { C.Rose, C.Mustard, C.Mint, C.Bruise }
	local i = 0
	for x = -17, 17, 1.6 do
		i += 1
		local sag = 0.55 * math.sin(((x + 17) % 11.33) / 11.33 * math.pi)
		P(porch, {
			Class = "WedgePart",
			Name = "Pennant",
			Size = V(0.06, 0.75, 0.6),
			CFrame = CF(x, 9.75 - sag * 0.5, 27.55) * ANG(0, math.pi / 2, 0) * ANG(math.pi, 0, 0) * ANG(0, 0, 0),
			Material = M.Fabric,
			Color = cols[(i % 4) + 1],
			CanCollide = false,
			CastShadow = false,
		})
	end
end
P(porch, { Name = "WelcomeMat", Size = V(4.4, 0.06, 2.2), CFrame = CF(0, 1.23, 36.6), Material = M.Fabric, Color = C.Blood:Lerp(C.Ink, 0.2), CanCollide = false, CastShadow = false })
-- porch lantern by the door
do
	local lan = P(porch, { Name = "PorchLantern", Size = V(0.9, 1.4, 0.9), CFrame = CF(3.4, 7.4, 37.5), Material = M.Neon, Color = rgb(214, 132, 64), CastShadow = false, CanCollide = false })
	P(porch, { Name = "LanternCap", Size = V(1.2, 0.3, 1.2), CFrame = CF(3.4, 8.2, 37.5), Material = M.Metal, Color = C.Ink, CastShadow = false, CanCollide = false })
	local l = Instance.new("PointLight")
	l.Color = rgb(255, 180, 120)
	l.Range = 18
	l.Brightness = 1.4
	l.Shadows = true
	l.Parent = lan
end
-- walkway from the steps to the sidewalk ring
P(home, { Name = "Walkway", Size = V(4, 0.3, 3), CFrame = CF(0, 0.0, 23.5), Material = M.Concrete, Color = rgb(160, 148, 146) })

-- garage (x 22..40, front z=40)
local garageCF = CFrame.lookAt(V(31, 0, 40), V(31, 0, 39))
local garage = house(home, "Garage", garageCF, {
	w = 18,
	d = 22,
	h = 11,
	roofH = 5,
	wall = rgb(92, 78, 110),
	roof = rgb(46, 32, 44),
	sideWindows = { { 14, 6, false } },
})
do
	local gcf = garageCF * CF(0, 4.25, 0)
	P(garage, { Name = "GarageDoorTrim", Size = V(13, 9, 0.3), CFrame = gcf * CF(0, 0.2, -0.05), Color = C.Paper })
	P(garage, { Name = "GarageDoor", Size = V(12, 8.5, 0.3), CFrame = gcf * CF(0, 0, -0.2), Color = C.Paper:Lerp(C.Mint, 0.18) })
	for i = 1, 3 do
		P(garage, { Name = "DoorSeam", Size = V(12, 0.12, 0.1), CFrame = gcf * CF(0, -4.25 + i * 2.125, -0.38), Color = C.Ink:Lerp(C.Paper, 0.55), CastShadow = false, CanCollide = false })
	end
	for i = -2, 2 do
		P(garage, { Name = "DoorWindow", Size = V(1.8, 0.8, 0.1), CFrame = gcf * CF(i * 2.3, 3, -0.4), Material = M.Neon, Color = rgb(150, 96, 60), CastShadow = false, CanCollide = false })
	end
end
-- driveway (angled from the garage to the cul-de-sac)
do
	local a, b = V(31, 0, 40.5), V(22.5, 0, 13.5)
	local len = (a - b).Magnitude
	P(home, { Name = "Driveway", Size = V(13, 0.3, len), CFrame = CFrame.lookAt((a + b) / 2, b) * CF(0, 0, 0), Material = M.Concrete, Color = rgb(128, 118, 120) })
end
-- the thin sliver of house wall between house & garage is covered by the garage; fine.

-- ------------------------------------------------------------------ neighbours
local nb = F(env, "Neighbors")
house(nb, "HouseWest", CFrame.lookAt(V(-47, 0, -26), V(-46, 0, -26)), {
	w = 24,
	d = 20,
	h = 11,
	roofH = 7,
	base = 0,
	wall = rgb(150, 116, 126),
	roof = rgb(58, 40, 52),
	door = C.Mint:Lerp(C.Ink, 0.2),
	doorX = 0,
	shutter = C.Paper:Lerp(C.Ink, 0.3),
	chimney = 6,
	windows = { { -7, 5.5, warm, C.Paper }, { 7, 5.5, false } },
	sideWindows = { { 10, 5.5, false } },
})
house(nb, "HouseEast", CFrame.lookAt(V(47, 0, -26), V(46, 0, -26)), {
	w = 24,
	d = 20,
	h = 11,
	roofH = 7,
	wall = rgb(116, 126, 148),
	roof = rgb(50, 38, 56),
	door = C.Mustard:Lerp(C.Ink, 0.15),
	doorX = 0,
	shutter = C.Night,
	windows = { { -7, 5.5, false }, { 7, 5.5, warm, C.Rose } },
	sideWindows = { { 10, 5.5, warm } },
})
house(nb, "HouseNorthWest", CFrame.lookAt(V(-47, 0, -70), V(-46, 0, -70)), {
	w = 18,
	d = 18,
	h = 18,
	roofH = 9,
	wall = rgb(168, 150, 110),
	roof = rgb(52, 36, 46),
	door = C.Bruise,
	doorX = -3,
	chimney = 4,
	shutter = C.Blood:Lerp(C.Ink, 0.4),
	windows = { { 4, 5.5, false }, { -4, 13.5, warm, C.Mustard }, { 4, 13.5, false } },
})
local vacant = house(nb, "HouseNorthEast_Vacant", CFrame.lookAt(V(47, 0, -70), V(46, 0, -70)) * ANG(0, 0, math.rad(0.8)), {
	w = 20,
	d = 18,
	h = 12,
	roofH = 7,
	wall = rgb(84, 76, 90),
	roof = rgb(40, 30, 38),
	door = C.Night,
	doorX = 2,
	windows = { { -5, 5.5, false } },
})
do -- boarded window + faded FOR SALE sign
	local vcf = CFrame.lookAt(V(47, 0, -70), V(46, 0, -70))
	for i, ang in { 18, -14, 5 } do
		P(vacant, { Name = "Board", Size = V(4.6, 0.6, 0.15), CFrame = vcf * CF(-5, 4.5 + i * 0.7, -0.55) * ANG(0, 0, math.rad(ang)), Material = M.WoodPlanks, Color = rgb(110, 90, 72), CastShadow = false, CanCollide = false })
	end
	P(vacant, { Name = "SignPost", Size = V(0.3, 4, 0.3), CFrame = CF(38, 2, -63), Material = M.Wood, Color = rgb(90, 72, 60) })
	local sp = P(vacant, { Name = "ForSale", Size = V(0.15, 2, 3), CFrame = CF(38, 3.6, -63.9) * ANG(0, 0, math.rad(-7)), Color = C.Paper:Lerp(C.Ink, 0.25) })
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Left
	g.CanvasSize = Vector2.new(300, 200)
	g.Parent = sp
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.FontFace = Font.fromEnum(Enum.Font.PatrickHand)
	t.TextScaled = true
	t.TextColor3 = C.Blood
	t.Text = "SOLD\n(she moved in)"
	t.Parent = g
end
-- neighbour stoops + walkways
for _, s in { { -47, -26, 1 }, { 47, -26, -1 }, { -47, -73, 1 }, { 47, -72, -1 } } do
	local x, z, dir = s[1], s[2], s[3]
	P(nb, { Name = "Stoop", Size = V(3, 0.5, 6), CFrame = CF(x + dir * 1.5, 0.25, z), Material = M.Concrete, Color = rgb(140, 128, 128) })
	local walkLen = math.abs(x) - 3 - (z > -40 and 33 or 25) -- stop at the sidewalk (bulb ring or street side)
	P(nb, { Name = "Walk", Size = V(walkLen, 0.26, 3.4), CFrame = CF(x + dir * (3 + walkLen / 2), 0.0, z), Material = M.Concrete, Color = rgb(150, 138, 138) })
end

-- ------------------------------------------------------------------ fences & hedges
local fences = F(env, "Fences")
local fenceColor = rgb(222, 210, 192)
local rngF = Random.new(31)
local function fence(a, b)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	local m = Instance.new("Model")
	m.Name = "PicketFence"
	m.Parent = fences
	for _, y in { 1.0, 2.5 } do
		P(m, { Name = "Rail", Size = V(0.2, 0.3, len), CFrame = cf * CF(0.15, y, 0), Material = M.Wood, Color = fenceColor:Lerp(C.Ink, 0.15), CastShadow = false })
	end
	local posts = math.max(1, math.floor(len / 8))
	for i = 0, posts do
		P(m, { Name = "Post", Size = V(0.5, 3.8, 0.5), CFrame = cf * CF(0, 1.9, -len / 2 + i * len / posts), Material = M.Wood, Color = fenceColor })
	end
	local n = math.floor(len / 1.05)
	for i = 0, n do
		local hgt = 3.1 + rngF:NextNumber(-0.25, 0.25)
		P(m, {
			Name = "Picket",
			Size = V(0.12, hgt, 0.42),
			CFrame = cf * CF(-0.1, hgt / 2, -len / 2 + i * len / n) * ANG(math.rad(rngF:NextNumber(-3, 3)), 0, math.rad(rngF:NextNumber(-2, 2))),
			Material = M.Wood,
			Color = fenceColor:Lerp(C.Bruise, rngF:NextNumber(0, 0.15)),
			CanCollide = false,
			CastShadow = false,
		})
	end
	P(m, { Name = "Collider", Size = V(0.6, 4, len), CFrame = cf * CF(0, 2, 0), Transparency = 1, CanCollide = true })
end
fence(V(-28, 0, 14), V(-46, 0, 14))
fence(V(-46, 0, 14), V(-46, 0, 66))
fence(V(-46, 0, 66), V(-22, 0, 66))
fence(V(40, 0, 66), V(48, 0, 66))
fence(V(48, 0, 66), V(48, 0, 14))
fence(V(48, 0, 14), V(31, 0, 14))
fence(V(-28, 0, -50), V(-77, 0, -50))
fence(V(28, 0, -50), V(77, 0, -50))

local hedges = F(env, "Hedges")
local rngH = Random.new(7)
local function hedge(a, b)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	local segs = math.max(1, math.floor(len / 7))
	for i = 0, segs - 1 do
		local hgt = rngH:NextNumber(4.2, 5.6)
		P(hedges, {
			Name = "Hedge",
			Size = V(3.4 + rngH:NextNumber(-0.3, 0.4), hgt, len / segs + 1.2),
			CFrame = cf * CF(rngH:NextNumber(-0.2, 0.2), hgt / 2, -len / 2 + (i + 0.5) * len / segs),
			Material = M.Grass,
			Color = rgb(50, 60, 46):Lerp(C.Bruise, rngH:NextNumber(0, 0.12)),
			CanCollide = true,
		})
	end
end
hedge(V(-77, 0, -93), V(-77, 0, 14))
hedge(V(77, 0, -93), V(77, 0, 14))
hedge(V(-77, 0, -93), V(-25, 0, -93))
hedge(V(25, 0, -93), V(77, 0, -93))
hedge(V(-77, 0, 14), V(-47, 0, 14))
hedge(V(77, 0, 14), V(49, 0, 14))

-- ------------------------------------------------------------------ invisible boundary
local bnd = F(lobby, "Boundary")
local function wall(a, b)
	local len = (b - a).Magnitude
	P(bnd, { Name = "Wall", Size = V(2, 40, len + 2), CFrame = CFrame.lookAt((a + b) / 2, b) * CF(0, 20, 0), Transparency = 1, CanCollide = true, CastShadow = false })
end
wall(V(-79, 0, -102), V(-79, 0, 15)) -- north edge at z=-102 leaves Car1/Car5 a clear 75-stud body sweep
wall(V(79, 0, -102), V(79, 0, 15))
wall(V(-79, 0, -102), V(79, 0, -102))
wall(V(-79, 0, 15.5), V(-47.5, 0, 15.5))
wall(V(79, 0, 15.5), V(49.5, 0, 15.5))
wall(V(-47.5, 0, 15), V(-47.5, 0, 67.5))
wall(V(49.5, 0, 15), V(49.5, 0, 67.5))
wall(V(-47.5, 0, 67.5), V(49.5, 0, 67.5))
P(bnd, { Name = "Ceiling", Size = V(160, 2, 172), CFrame = CF(0, 41, -17), Transparency = 1, CanCollide = true, CastShadow = false })

local n = 0
for _, d in lobby:GetDescendants() do
	if d:IsA("BasePart") then
		n += 1
	end
end
return "base ok, parts=" .. n
