--!nocheck
-- build_lobby_2_cars.luau  (run 2nd, after build_lobby_1_base.luau)
-- Mom's five pastel minivans: Workspace.Lobby.Cars.Car1..Car5 (see docs/MAP_CONTRACT.md, "Lobby place"),
-- fanned around the cul-de-sac bulb (centre (0,-14), r=33) and angled toward the street.
-- Each car Model: PrimaryPart "Body" (CSG union: rounded body, hollow cabin, wheel wells, window + door cut-outs),
-- QueueZone (glowing, CanCollide false / CanTouch true) at the open right-hand sliding door,
-- Seats folder (Seat1 driver .. Seat5; 2 front + 3 back), Exit (invisible, on the sidewalk behind the door),
-- Display (invisible, ~2 studs above the roof), optional Door (the slid-open door leaf).
-- Every part is inside the model and anchored. Pivot = Body CFrame, LookVector = the car's nose (toward the street).
-- LobbyService drives each car 70 studs along its LookVector on departure; that lane (75 studs) is kept clear.
-- CARS x/z/yaw must match CAR_LAYOUT in build_lobby_1_base.luau (it paints the bays).
-- Idempotent: destroys Lobby.Cars first.

local GS = game:GetService("GeometryService")
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
local CYL = Enum.PartType.Cylinder

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

local lobby = workspace:FindFirstChild("Lobby")
assert(lobby, "run build_lobby_1_base.luau first")
local old = lobby:FindFirstChild("Cars")
if old then
	old:Destroy()
end
local cars = Instance.new("Folder")
cars.Name = "Cars"
cars.Parent = lobby

-- yaw in degrees (CFrame.Angles Y): negative turns the nose toward +X. Door/QueueZone is always on the car's +X side.
local CARS = {
	{ name = "Car1", x = -26.2, z = -16, yaw = -12, color = C.Mint, sticker = "MY KID SURVIVED GRANDMA'S", plate = "MOM  01" },
	{ name = "Car2", x = -13.7, z = -12, yaw = -4, color = C.Rose, sticker = "HONK IF SHE'S AWAKE", plate = "MOM  02" },
	{ name = "Car3", x = -1.2, z = -8, yaw = 0, color = C.Mustard, sticker = "ARE WE THERE YET?", plate = "MOM  03" },
	{ name = "Car4", x = 11.3, z = -12, yaw = 4, color = C.Bruise, sticker = "I BRAKE FOR GRANNIES", plate = "MOM  04" },
	{ name = "Car5", x = 23.8, z = -16, yaw = 12, color = C.Paper, trim = C.Rose, zone = C.Rose:Lerp(C.Paper, 0.35), stickerBg = C.Rose:Lerp(C.Paper, 0.55), sticker = "BACK BEFORE DAWN", plate = "MOM  05" },
}
local BULB_C, EXIT_R = Vector3.new(0, 0, -14), 35 -- Exit parts go on the sidewalk ring (r 33..37)

local function surfaceText(part, face, text, font, color, canvas)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.CanvasSize = canvas or Vector2.new(400, 80)
	g.LightInfluence = 1
	g.Parent = part
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.FontFace = Font.fromEnum(font)
	t.TextScaled = true
	t.TextColor3 = color
	t.Text = text
	t.Parent = g
	return g
end

local function buildCar(def)
	local model = Instance.new("Model")
	model.Name = def.name
	model.Parent = cars
	local base = CF(def.x, 0, def.z) * ANG(0, math.rad(def.yaw), 0) -- ground under the car's centre, nose along LookVector
	local function L(x, y, z)
		return base * CF(x, y, z)
	end
	local paint = def.color

	-- ---------------------------------------------------------- body shell (CSG)
	local tmp = {}
	local function T(props)
		props.Color = paint
		local p = P(model, props)
		table.insert(tmp, p)
		return p
	end
	local core = T({ Size = V(7, 3.1, 13.6), CFrame = L(0, 2.45, 0) })
	T({ Size = V(4.6, 3.1, 16), CFrame = L(0, 2.45, 0) })
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			T({ Shape = CYL, Size = V(3.1, 2.4, 2.4), CFrame = L(sx * 2.3, 2.45, sz * 6.8) * ANG(0, 0, math.pi / 2) })
		end
	end
	T({ Size = V(6.6, 2.4, 10.8), CFrame = L(0, 5.1, 2.4) }) -- cabin
	T({ Size = V(5.6, 0.5, 10.8), CFrame = L(0, 6.55, 2.4) }) -- roof crown
	for _, sx in { -1, 1 } do
		T({ Shape = CYL, Size = V(10.8, 1.0, 1.0), CFrame = L(sx * 2.8, 6.3, 2.4) * ANG(0, math.pi / 2, 0) }) -- rounded roof edges
	end
	table.remove(tmp, 1)
	local okU, res = pcall(function()
		return GS:UnionAsync(core, tmp, { SplitApart = false })
	end)
	assert(okU, "car union failed: " .. tostring(res))
	local shell = res[1]
	core:Destroy()
	for _, p in tmp do
		p:Destroy()
	end

	local cut = {}
	local function K(size, cf, shape)
		local p = P(model, { Size = size, CFrame = cf, Shape = shape })
		table.insert(cut, p)
		return p
	end
	K(V(6.2, 4.85, 10.9), L(0, 4.025, 1.95)) -- cabin hollow
	K(V(6.2, 2.0, 2.2), L(0, 2.6, -4.6)) -- footwell under the dash
	for _, sz in { -1, 1 } do
		K(V(8, 3.3, 3.3), L(0, 1.3, sz * 5.3), CYL) -- wheel wells
	end
	K(V(1.6, 5.0, 4.8), L(3.4, 3.7, 1.2)) -- sliding-door opening (right / +X side)
	-- windows
	K(V(1.2, 1.7, 2.3), L(-3.3, 5.25, -1.75))
	K(V(1.2, 1.7, 3.4), L(-3.3, 5.25, 1.9))
	K(V(1.2, 1.7, 3.0), L(-3.3, 5.25, 5.6))
	K(V(1.2, 1.7, 1.4), L(3.3, 5.25, -2.1))
	K(V(1.2, 1.7, 3.0), L(3.3, 5.25, 5.6))
	K(V(5.2, 1.8, 1.2), L(0, 5.3, 7.8)) -- rear window
	-- chamfer the hood's front edge (upside-down wedge = top-front corner)
	local ch = P(model, { Class = "WedgePart", Size = V(7.4, 0.8, 1.2), CFrame = L(0, 3.6, -7.6) * ANG(math.pi, 0, 0) })
	table.insert(cut, ch)
	shell.Parent = model
	local okS, res2 = pcall(function()
		return GS:SubtractAsync(shell, cut, { SplitApart = false, CollisionFidelity = Enum.CollisionFidelity.Box })
	end)
	assert(okS, "car subtract failed: " .. tostring(res2))
	local body = res2[1]
	shell:Destroy()
	for _, p in cut do
		p:Destroy()
	end
	body.Name = "Body"
	body.Anchored = true
	body.UsePartColor = true
	body.Color = paint
	body.Material = M.SmoothPlastic
	body.Reflectance = 0.04
	body.CanCollide = true
	body.CanTouch = false
	body.CanQuery = true
	body.CollisionFidelity = Enum.CollisionFidelity.Box
	body.Parent = model
	model.PrimaryPart = body

	-- ---------------------------------------------------------- glass
	local glass = rgb(52, 40, 66)
	local function G(size, cf, name)
		return P(model, { Name = name or "Glass", Size = size, CFrame = cf, Material = M.Glass, Color = glass, Transparency = 0.45, CanCollide = false, CastShadow = false })
	end
	G(V(0.1, 1.7, 2.3), L(-3.2, 5.25, -1.75))
	G(V(0.1, 1.7, 3.4), L(-3.2, 5.25, 1.9))
	G(V(0.1, 1.7, 3.0), L(-3.2, 5.25, 5.6))
	G(V(0.1, 1.7, 1.4), L(3.2, 5.25, -2.1))
	G(V(0.1, 1.7, 3.0), L(3.2, 5.25, 5.6))
	G(V(5.2, 1.8, 0.1), L(0, 5.3, 7.6), "RearGlass")
	P(model, { Class = "WedgePart", Name = "Windshield", Size = V(6.2, 2.8, 3.5), CFrame = L(0, 5.4, -4.75), Material = M.Glass, Color = glass, Transparency = 0.5, CanCollide = false, CastShadow = false })
	for _, sx in { -1, 1 } do
		P(model, { Class = "WedgePart", Name = "APillar", Size = V(0.25, 2.8, 3.5), CFrame = L(sx * 3.18, 5.4, -4.75), Color = paint, CanCollide = false })
	end
	P(model, { Name = "Dash", Size = V(6.2, 0.5, 1.4), CFrame = L(0, 4.1, -4.4), Material = M.Plastic, Color = C.Ink, CanCollide = false, CastShadow = false })

	-- ---------------------------------------------------------- open sliding door (slid back along the right side)
	local door = P(model, { Name = "Door", Size = V(0.22, 4.9, 4.8), CFrame = L(3.72, 3.75, 5.3), Color = paint, Reflectance = 0.04, CanCollide = true })
	P(model, { Name = "DoorGlass", Size = V(0.05, 1.6, 3.4), CFrame = L(3.85, 5.25, 5.3), Material = M.Glass, Color = glass, Transparency = 0.2, CanCollide = false, CastShadow = false })
	P(model, { Name = "DoorHandle", Size = V(0.12, 0.2, 0.8), CFrame = L(3.88, 3.9, 3.3), Material = M.Metal, Color = C.Ink, CanCollide = false, CastShadow = false })
	P(model, { Name = "DoorRail", Size = V(0.1, 0.15, 9.2), CFrame = L(3.55, 1.35, 3.4), Material = M.Metal, Color = C.Ink, CanCollide = false, CastShadow = false })
	P(model, { Name = "DoorRail", Size = V(0.1, 0.12, 4.2), CFrame = L(3.36, 6.25, 5.3), Material = M.Metal, Color = C.Ink, CanCollide = false, CastShadow = false })
	P(model, { Name = "StepSill", Size = V(0.6, 0.25, 4.6), CFrame = L(3.3, 1.45, 1.2), Material = M.DiamondPlate, Color = rgb(120, 110, 118), CanCollide = false, CastShadow = false })

	-- ---------------------------------------------------------- trim & lights
	local trim = def.trim or rgb(72, 58, 70)
	P(model, { Name = "BumperF", Size = V(7.1, 0.9, 0.7), CFrame = L(0, 1.35, -8.05), Color = trim, CanCollide = false })
	P(model, { Name = "BumperR", Size = V(7.1, 0.9, 0.7), CFrame = L(0, 1.35, 8.05), Color = trim, CanCollide = false })
	P(model, { Name = "Grille", Size = V(2.2, 0.8, 0.12), CFrame = L(0, 2.45, -8.02), Color = C.Ink, CanCollide = false, CastShadow = false })
	P(model, { Name = "Badge", Shape = CYL, Size = V(0.1, 0.5, 0.5), CFrame = L(0, 2.45, -8.1) * ANG(0, math.pi / 2, 0), Material = M.Metal, Color = C.Paper, CanCollide = false, CastShadow = false })
	for _, sx in { -1, 1 } do
		local hl = P(model, { Name = "Headlight", Size = V(1.2, 0.6, 0.1), CFrame = L(sx * 1.7, 2.85, -8.03), Material = M.Neon, Color = rgb(255, 236, 196), CanCollide = false, CastShadow = false })
		local sl = Instance.new("SpotLight")
		sl.Face = Enum.NormalId.Front
		sl.Range = 26
		sl.Angle = 55
		sl.Brightness = 1.6
		sl.Color = rgb(255, 222, 170)
		sl.Parent = hl
		P(model, { Name = "Taillight", Size = V(0.6, 1.3, 0.08), CFrame = L(sx * 2.0, 3.2, 8.03), Material = M.Neon, Color = C.Blood, CanCollide = false, CastShadow = false })
		P(model, { Name = "Mirror", Size = V(0.5, 0.45, 0.4), CFrame = L(sx * 3.75, 4.55, -3.4), Color = def.trim or paint, CanCollide = false, CastShadow = false })
		P(model, { Name = "MirrorArm", Size = V(0.4, 0.12, 0.2), CFrame = L(sx * 3.45, 4.4, -3.4), Color = C.Ink, CanCollide = false, CastShadow = false })
		P(model, { Name = "RoofRail", Size = V(0.2, 0.22, 8), CFrame = L(sx * 2.45, 6.92, 2.6), Color = C.Ink, CanCollide = false, CastShadow = false })
		P(model, { Name = "Sidetrim", Size = V(0.08, 0.3, 13.6), CFrame = L(sx * 3.52, 2.4, 0), Color = trim, CanCollide = false, CastShadow = false })
		for _, sz in { -1, 1 } do
			P(model, { Name = "Tire", Shape = CYL, Size = V(0.9, 2.6, 2.6), CFrame = L(sx * 3.1, 1.3, sz * 5.3), Material = M.Rubber, Color = rgb(36, 28, 36), CanCollide = false })
			P(model, { Name = "Hubcap", Shape = CYL, Size = V(0.1, 1.4, 1.4), CFrame = L(sx * 3.56, 1.3, sz * 5.3), Material = M.Metal, Color = C.Paper:Lerp(C.Bruise, 0.3), CanCollide = false, CastShadow = false })
		end
	end
	for _, sx in { -1, 1 } do
		P(model, { Name = "RackBar", Size = V(4.9, 0.14, 0.2), CFrame = L(0, 7.05, 2.6 + sx * 3.2), Color = C.Ink, CanCollide = false, CastShadow = false })
	end
	local plate = P(model, { Name = "Plate", Size = V(1.6, 0.7, 0.05), CFrame = L(0, 2.3, 8.05), Color = C.Paper, CanCollide = false, CastShadow = false })
	surfaceText(plate, Enum.NormalId.Back, def.plate, Enum.Font.FredokaOne, C.Night, Vector2.new(240, 100))
	local sticker = P(model, { Name = "BumperSticker", Size = V(2.6, 0.5, 0.05), CFrame = L(0.6, 3.55, 8.03) * ANG(0, 0, math.rad(-3)), Color = def.stickerBg or C.Paper, CanCollide = false, CastShadow = false })
	surfaceText(sticker, Enum.NormalId.Back, def.sticker, Enum.Font.PatrickHand, C.Blood, Vector2.new(520, 100))
	-- stick-figure family on the rear glass: 3 tiny figures + one extra, taller, crooked one
	for i, hgt in { 0.9, 0.6, 0.5, 1.15 } do
		local fx = -2.0 + i * 0.55
		local col = i == 4 and C.Ink or C.Paper
		P(model, { Name = "StickFigure", Size = V(0.08, hgt, 0.03), CFrame = L(fx, 4.75 + hgt / 2, 7.66) * ANG(0, 0, math.rad(i == 4 and 9 or 0)), Color = col, CanCollide = false, CastShadow = false })
		P(model, { Name = "StickHead", Shape = Enum.PartType.Ball, Size = V(0.24, 0.24, 0.24), CFrame = L(fx + (i == 4 and -0.08 or 0), 4.85 + hgt, 7.66), Color = col, CanCollide = false, CastShadow = false })
	end

	-- ---------------------------------------------------------- interior + seats
	P(model, { Name = "Floor", Size = V(6.2, 0.1, 10.8), CFrame = L(0, 1.65, 1.95), Material = M.Fabric, Color = C.Night, CanCollide = false, CastShadow = false })
	P(model, { Name = "SteeringWheel", Shape = CYL, Size = V(0.15, 1.1, 1.1), CFrame = L(-1.5, 4.25, -3.55) * ANG(math.rad(-25), 0, 0) * ANG(0, math.pi / 2, 0), Color = C.Ink, CanCollide = false, CastShadow = false })
	local seats = Instance.new("Folder")
	seats.Name = "Seats"
	seats.Parent = model
	local seatColor = C.Paper:Lerp(paint, 0.25):Lerp(C.Ink, 0.1)
	local layout = {
		{ -1.5, -2.0 }, -- Seat1 driver (front-left)
		{ 1.5, -2.0 }, -- Seat2 front passenger
		{ -2.05, 2.2 }, -- Seat3 back-left
		{ 0, 2.2 }, -- Seat4 back-middle
		{ 2.05, 2.2 }, -- Seat5 back-right
	}
	for i, xz in layout do
		local s = Instance.new("Seat")
		s.Name = "Seat" .. i
		s.Anchored = true
		s.Size = V(2.0, 0.6, 2.0)
		s.CFrame = L(xz[1], 2.3, xz[2]) -- faces -Z (forward)
		s.Material = M.Fabric
		s.Color = seatColor
		s.TopSurface = Enum.SurfaceType.Smooth
		s.BottomSurface = Enum.SurfaceType.Smooth
		s.CanCollide = false
		s.CastShadow = false
		s.Parent = seats
		P(model, { Name = "SeatBack", Size = V(2.0, 2.4, 0.45), CFrame = L(xz[1], 3.8, xz[2] + 1.15) * ANG(math.rad(-8), 0, 0), Material = M.Fabric, Color = seatColor, CanCollide = false, CastShadow = false })
		P(model, { Name = "Headrest", Size = V(1.1, 0.6, 0.35), CFrame = L(xz[1], 5.3, xz[2] + 1.35), Material = M.Fabric, Color = seatColor:Lerp(C.Ink, 0.15), CanCollide = false, CastShadow = false })
	end
	-- a forgotten plush bunny in the cargo area (a little off)
	P(model, { Name = "Plush", Shape = Enum.PartType.Ball, Size = V(0.9, 0.9, 0.9), CFrame = L(-1.8, 2.15, 6.3), Material = M.Fabric, Color = C.Rose:Lerp(C.Paper, 0.4), CanCollide = false, CastShadow = false })
	P(model, { Name = "PlushEar", Size = V(0.2, 0.7, 0.12), CFrame = L(-1.95, 2.8, 6.3) * ANG(0, 0, math.rad(12)), Material = M.Fabric, Color = C.Rose:Lerp(C.Paper, 0.4), CanCollide = false, CastShadow = false })
	P(model, { Name = "PlushEar", Size = V(0.2, 0.5, 0.12), CFrame = L(-1.62, 2.7, 6.3) * ANG(0, 0, math.rad(-40)), Material = M.Fabric, Color = C.Rose:Lerp(C.Paper, 0.4), CanCollide = false, CastShadow = false })

	-- ---------------------------------------------------------- contract helpers
	local zoneColor = def.zone or paint:Lerp(C.Paper, 0.35)
	local zone = P(model, {
		Name = "QueueZone",
		Size = V(2.4, 6, 4.8),
		CFrame = L(5.1, 3.0, 1.2),
		Material = M.Neon,
		Color = zoneColor,
		Transparency = 0.8,
		CanCollide = false,
		CanTouch = true,
		CanQuery = false,
		CastShadow = false,
	})
	local zl = Instance.new("PointLight")
	zl.Color = zoneColor
	zl.Range = 11
	zl.Brightness = 1.3
	zl.Parent = zone
	P(model, { Name = "ZonePad", Size = V(2.8, 0.05, 5.2), CFrame = L(5.1, 0.1, 1.2), Material = M.Neon, Color = zoneColor, Transparency = 0.45, CanCollide = false, CastShadow = false })
	-- Exit: on the sidewalk ring, straight out from the bulb centre behind the door (never inside a QueueZone)
	local behind = (L(4.5, 0, 9)).Position - BULB_C
	local exitPos = BULB_C + V(behind.X, 0, behind.Z).Unit * EXIT_R + V(0, 0.7, 0)
	P(model, { Name = "Exit", Size = V(2, 1, 2), CFrame = CFrame.lookAt(exitPos, V(def.x, 0.7, def.z)), Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false })
	P(model, { Name = "Display", Size = V(1, 1, 1), CFrame = L(0, 8.9, 0), Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false })

	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	return model
end

for _, def in CARS do
	buildCar(def)
end

local n = 0
for _, d in cars:GetDescendants() do
	if d:IsA("BasePart") then
		n += 1
	end
end
return "cars ok, parts=" .. n
