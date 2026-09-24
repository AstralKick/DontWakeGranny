--!strict
-- build_grandma_rig.luau
-- Builds the ORIGINAL temporary Grandma rig at ServerStorage.GrandmaRigs.TempGrandma.
-- Idempotent: destroys any existing TempGrandma and rebuilds it from scratch.
-- Run in Studio (Edit mode) via the command bar or the MCP execute_luau tool.
--
-- Design: "sweet storybook grandma who is slightly wrong".
--   Tall grey-lavender beehive with knitting needles, enormous round glasses with
--   magnified eyes, rose cardigan over a tiered dusty-mauve floral nightgown,
--   pearls, fuzzy mint slippers, long bony fingers, a too-wide thin smile, hunched back.
--
-- Rig contract (see Game/Server/Modules/Grandma/GrandmaRig.luau):
--   Humanoid (R15), HumanoidRootPart (PrimaryPart), Head, parts named "Eye",
--   skin parts carry attribute Skin = true. Standard R15 part + Motor6D names.

local ServerStorage = game:GetService("ServerStorage")

local FOLDER_NAME = "GrandmaRigs"
local RIG_NAME = "TempGrandma"

-- Palette ---------------------------------------------------------------------
local C = {
	Rose = Color3.fromHex("#D97A8A"),
	RoseDark = Color3.fromRGB(184, 98, 116),
	Mint = Color3.fromHex("#9CC5A1"),
	MintLight = Color3.fromRGB(205, 228, 205),
	Mustard = Color3.fromHex("#E0B04F"),
	Bruise = Color3.fromHex("#7B5C8E"),
	Paper = Color3.fromHex("#F3E9D2"),
	Ink = Color3.fromHex("#2A1A24"),
	Skin = Color3.fromHex("#E6CDB8"),
	SkinShadow = Color3.fromRGB(201, 172, 160),
	SkinLine = Color3.fromRGB(176, 140, 134),
	Mauve = Color3.fromRGB(166, 128, 150),
	MauveDeep = Color3.fromRGB(142, 106, 132),
	Hair = Color3.fromRGB(178, 170, 198),
	HairDark = Color3.fromRGB(150, 140, 172),
	Eye = Color3.fromRGB(40, 30, 30),
	Lens = Color3.fromRGB(214, 236, 222),
}

local SMOOTH = Enum.Material.SmoothPlastic
local FABRIC = Enum.Material.Fabric

-- Clean slate -------------------------------------------------------------------
local folder = ServerStorage:FindFirstChild(FOLDER_NAME)
if not folder then
	folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = ServerStorage
end
local old = folder:FindFirstChild(RIG_NAME)
if old then
	old:Destroy()
end

local model = Instance.new("Model")
model.Name = RIG_NAME

local partCount = 0

local function newPart(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = false
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = true
	p.Parent = model
	partCount += 1
	return p
end

local function sphereMesh(p: BasePart)
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Sphere
	m.Parent = p
end

-- Body ------------------------------------------------------------------------
-- Built with the HRP at the origin; the whole model is moved to stand on y = 0 at the end.
local body: { [string]: Part } = {}

local hrp = newPart("HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(), C.Paper, SMOOTH)
hrp.Transparency = 1
hrp.CanCollide = true
hrp.CastShadow = false
body.HumanoidRootPart = hrp

type BodyDef = {
	name: string,
	joint: string,
	parent: string,
	size: Vector3,
	c0: CFrame, -- pivot in Part0 space (carries the pose rotation, e.g. the hunch)
	c1: CFrame, -- pivot in Part1 space (pure translation)
	color: Color3,
	material: Enum.Material,
	skin: boolean?,
	ellipsoid: boolean?,
}

local rad = math.rad
local defs: { BodyDef } = {
	{ name = "LowerTorso", joint = "Root", parent = "HumanoidRootPart", size = Vector3.new(1.6, 0.7, 1.0),
		c0 = CFrame.new(0, -0.3, 0), c1 = CFrame.new(), color = C.Mauve, material = FABRIC },
	-- hunch lives in the Waist C0
	{ name = "UpperTorso", joint = "Waist", parent = "LowerTorso", size = Vector3.new(1.75, 1.6, 1.05),
		c0 = CFrame.new(0, 0.3, 0.05) * CFrame.Angles(rad(-17), 0, 0), c1 = CFrame.new(0, -0.78, 0),
		color = C.Rose, material = FABRIC },
	-- neck juts forward, head tilts back up a little to peer at you
	{ name = "Head", joint = "Neck", parent = "UpperTorso", size = Vector3.new(1.3, 1.45, 1.25),
		c0 = CFrame.new(0, 0.8, -0.24) * CFrame.Angles(rad(9), 0, 0), c1 = CFrame.new(0, -0.62, 0.08),
		color = C.Skin, material = SMOOTH, skin = true, ellipsoid = true },

	{ name = "LeftUpperArm", joint = "LeftShoulder", parent = "UpperTorso", size = Vector3.new(0.5, 1.05, 0.5),
		c0 = CFrame.new(-1.0, 0.5, 0) * CFrame.Angles(rad(3), 0, rad(-3)), c1 = CFrame.new(0.125, 0.42, 0),
		color = C.Rose, material = FABRIC },
	{ name = "LeftLowerArm", joint = "LeftElbow", parent = "LeftUpperArm", size = Vector3.new(0.36, 1.0, 0.36),
		c0 = CFrame.new(0, -0.45, 0), c1 = CFrame.new(0, 0.45, 0), color = C.Skin, material = SMOOTH, skin = true },
	{ name = "LeftHand", joint = "LeftWrist", parent = "LeftLowerArm", size = Vector3.new(0.2, 0.5, 0.36),
		c0 = CFrame.new(0, -0.48, 0), c1 = CFrame.new(0, 0.2, 0), color = C.Skin, material = SMOOTH, skin = true },

	{ name = "RightUpperArm", joint = "RightShoulder", parent = "UpperTorso", size = Vector3.new(0.5, 1.05, 0.5),
		c0 = CFrame.new(1.0, 0.5, 0) * CFrame.Angles(rad(3), 0, rad(3)), c1 = CFrame.new(-0.125, 0.42, 0),
		color = C.Rose, material = FABRIC },
	{ name = "RightLowerArm", joint = "RightElbow", parent = "RightUpperArm", size = Vector3.new(0.36, 1.0, 0.36),
		c0 = CFrame.new(0, -0.45, 0), c1 = CFrame.new(0, 0.45, 0), color = C.Skin, material = SMOOTH, skin = true },
	{ name = "RightHand", joint = "RightWrist", parent = "RightLowerArm", size = Vector3.new(0.2, 0.5, 0.36),
		c0 = CFrame.new(0, -0.48, 0), c1 = CFrame.new(0, 0.2, 0), color = C.Skin, material = SMOOTH, skin = true },

	{ name = "LeftUpperLeg", joint = "LeftHip", parent = "LowerTorso", size = Vector3.new(0.62, 1.0, 0.62),
		c0 = CFrame.new(-0.42, -0.3, 0), c1 = CFrame.new(0, 0.45, 0), color = C.MauveDeep, material = FABRIC },
	{ name = "LeftLowerLeg", joint = "LeftKnee", parent = "LeftUpperLeg", size = Vector3.new(0.46, 1.0, 0.46),
		c0 = CFrame.new(0, -0.45, 0), c1 = CFrame.new(0, 0.45, 0), color = C.Skin, material = SMOOTH, skin = true },
	{ name = "LeftFoot", joint = "LeftAnkle", parent = "LeftLowerLeg", size = Vector3.new(0.7, 0.32, 1.1),
		c0 = CFrame.new(0, -0.45, 0), c1 = CFrame.new(0, 0.1, 0.2), color = C.Mint, material = FABRIC },

	{ name = "RightUpperLeg", joint = "RightHip", parent = "LowerTorso", size = Vector3.new(0.62, 1.0, 0.62),
		c0 = CFrame.new(0.42, -0.3, 0), c1 = CFrame.new(0, 0.45, 0), color = C.MauveDeep, material = FABRIC },
	{ name = "RightLowerLeg", joint = "RightKnee", parent = "RightUpperLeg", size = Vector3.new(0.46, 1.0, 0.46),
		c0 = CFrame.new(0, -0.45, 0), c1 = CFrame.new(0, 0.45, 0), color = C.Skin, material = SMOOTH, skin = true },
	{ name = "RightFoot", joint = "RightAnkle", parent = "RightLowerLeg", size = Vector3.new(0.7, 0.32, 1.1),
		c0 = CFrame.new(0, -0.45, 0), c1 = CFrame.new(0, 0.1, 0.2), color = C.Mint, material = FABRIC },
}

local pendingMotors = {}
for _, d in defs do
	local p0 = body[d.parent]
	local cf = p0.CFrame * d.c0 * d.c1:Inverse()
	local p = newPart(d.name, d.size, cf, d.color, d.material)
	if d.ellipsoid then
		sphereMesh(p)
	end
	if d.skin then
		p:SetAttribute("Skin", true)
	end
	body[d.name] = p
	table.insert(pendingMotors, { d = d, p0 = p0, p1 = p })
end

for _, m in pendingMotors do
	local motor = Instance.new("Motor6D")
	motor.Name = m.d.joint
	motor.Part0 = m.p0
	motor.Part1 = m.p1
	motor.C0 = m.d.c0
	motor.C1 = m.d.c1
	motor.Parent = m.p1
end

-- Decorations -------------------------------------------------------------------
local function decor(name: string, attach: BasePart, size: Vector3, localCf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?, opts: { skin: boolean?, ellipsoid: boolean? }?): Part
	local p = newPart(name, size, attach.CFrame * localCf, color, material, shape)
	p.Massless = true
	p.CanQuery = false
	p.CanTouch = false
	if opts and opts.ellipsoid then
		sphereMesh(p)
	end
	if opts and opts.skin then
		p:SetAttribute("Skin", true)
	end
	local w = Instance.new("WeldConstraint")
	w.Part0 = attach
	w.Part1 = p
	w.Parent = p
	return p
end

local BALL = Enum.PartType.Ball
local CYL = Enum.PartType.Cylinder
local AXIS_Y = CFrame.Angles(0, 0, math.rad(90)) -- cylinder axis X -> Y
local AXIS_Z = CFrame.Angles(0, math.rad(90), 0) -- cylinder axis X -> Z

-- Head ellipsoid helpers (head local space; front is -Z)
local head = body.Head
local HA, HB, HC = head.Size.X / 2, head.Size.Y / 2, head.Size.Z / 2
local function headSurface(x: number, y: number): (Vector3, Vector3)
	local k = math.max(0, 1 - (x / HA) ^ 2 - (y / HB) ^ 2)
	local z = -HC * math.sqrt(k)
	local n = Vector3.new(x / HA ^ 2, y / HB ^ 2, z / HC ^ 2).Unit
	return Vector3.new(x, y, z), n
end
local function onHead(x: number, y: number, push: number): CFrame
	local pos, n = headSurface(x, y)
	pos += n * push
	return CFrame.lookAt(pos, pos + n)
end

-- Hair: cap + tall beehive + knob + two knitting needles
decor("HairCap", head, Vector3.new(1.42, 1.0, 1.38), CFrame.new(0, 0.5, 0.2), C.Hair, FABRIC, nil, { ellipsoid = true })
local bunCf = CFrame.new(0, 1.25, 0.24) * CFrame.Angles(rad(12), 0, 0)
local bun = decor("HairBun", head, Vector3.new(1.0, 1.45, 1.0), bunCf, C.Hair, FABRIC, nil, { ellipsoid = true })
decor("HairKnob", head, Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 2.0, 0.4), C.HairDark, FABRIC, BALL)
local function needle(name: string, localCf: CFrame, color: Color3)
	local n = decor(name, bun, Vector3.new(1.9, 0.07, 0.07), localCf, color, SMOOTH, CYL)
	local tip = n.CFrame * CFrame.new(0.95, 0, 0)
	local bead = newPart(name .. "Bead", Vector3.new(0.17, 0.17, 0.17), tip, C.Mustard, SMOOTH, BALL)
	bead.Massless = true
	bead.CanQuery = false
	bead.CanTouch = false
	local w = Instance.new("WeldConstraint")
	w.Part0 = bun
	w.Part1 = bead
	w.Parent = bead
end
needle("KnittingNeedleA", CFrame.new(0, 0.05, 0) * CFrame.Angles(0, rad(25), rad(32)), C.Bruise)
needle("KnittingNeedleB", CFrame.new(0, -0.05, 0) * CFrame.Angles(0, rad(-30), rad(150)), C.Rose)

-- Ears
decor("LeftEar", head, Vector3.new(0.12, 0.36, 0.24), CFrame.new(-0.64, -0.02, 0.05), C.Skin, SMOOTH, nil, { skin = true, ellipsoid = true })
decor("RightEar", head, Vector3.new(0.12, 0.36, 0.24), CFrame.new(0.64, -0.02, 0.05), C.Skin, SMOOTH, nil, { skin = true, ellipsoid = true })

-- Enormous glasses: dark rim disc, magnified eye-white, dark "Eye", faintly glowing lens
local GLASS_Y, GLASS_X = 0.05, 0.385
for _, side in { -1, 1 } do
	local prefix = if side < 0 then "Left" else "Right"
	local x = GLASS_X * side
	decor(prefix .. "GlassesRim", head, Vector3.new(0.05, 0.78, 0.78), CFrame.new(x, GLASS_Y, -0.655) * AXIS_Z, C.Ink, SMOOTH, CYL)
	decor(prefix .. "EyeWhite", head, Vector3.new(0.02, 0.7, 0.7), CFrame.new(x, GLASS_Y, -0.685) * AXIS_Z, C.Paper, SMOOTH, CYL)
	-- pupils sit a hair toward the nose: slightly wrong
	local eye = decor("Eye", head, Vector3.new(0.24, 0.24, 0.24), CFrame.new(x - 0.03 * side, GLASS_Y - 0.02, -0.7), C.Eye, SMOOTH, BALL)
	eye.CastShadow = false
	local lens = decor(prefix .. "Lens", head, Vector3.new(0.02, 0.76, 0.76), CFrame.new(x, GLASS_Y, -0.86) * AXIS_Z, C.Lens, Enum.Material.Neon, CYL)
	lens.Transparency = 0.86
	lens.CastShadow = false
	decor(prefix .. "GlassesArm", head, Vector3.new(0.045, 0.045, 0.9), CFrame.new(0.715 * side, 0.1, -0.28), C.Ink, SMOOTH)
end
decor("GlassesBridge", head, Vector3.new(0.14, 0.05, 0.05), CFrame.new(0, 0.14, -0.7), C.Ink, SMOOTH)

-- Nose (long, pointy-ish)
decor("Nose", head, Vector3.new(0.2, 0.34, 0.3), CFrame.new(0, -0.1, -0.68) * CFrame.Angles(rad(-15), 0, 0), C.Skin, SMOOTH, nil, { skin = true, ellipsoid = true })

-- Sunken cheeks (shadowy hollows near the jaw)
for _, side in { -1, 1 } do
	local prefix = if side < 0 then "Left" else "Right"
	decor(prefix .. "CheekHollow", head, Vector3.new(0.3, 0.42, 0.08), onHead(0.47 * side, -0.36, -0.015), C.SkinShadow, SMOOTH, nil, { skin = true, ellipsoid = true })
	-- wrinkle line from nose to smile
	local a = headSurface(0.13 * side, -0.13)
	local b = headSurface(0.25 * side, -0.27)
	local _, n = headSurface(0.19 * side, -0.2)
	local mid = (a + b) / 2 + n * 0.01
	local dir = (b - a)
	decor(prefix .. "Wrinkle", head, Vector3.new(dir.Magnitude + 0.02, 0.035, 0.035), CFrame.fromMatrix(mid, dir.Unit, n:Cross(dir).Unit), C.SkinLine, SMOOTH, nil, { skin = true })
end

-- Too-wide thin dark smile: segmented arc hugging the face, corners curl up
do
	local pts = {}
	local N = 6
	for i = 0, N do
		local t = (i / N) * 2 - 1 -- -1..1
		local x = t * 0.47
		local y = -0.4 + 0.2 * t * t
		local pos, n = headSurface(x, y)
		table.insert(pts, { pos = pos + n * 0.012, n = n })
	end
	for i = 1, N do
		local a, b = pts[i], pts[i + 1]
		local dir = b.pos - a.pos
		local mid = (a.pos + b.pos) / 2
		local n = (a.n + b.n).Unit
		decor("Smile" .. i, head, Vector3.new(dir.Magnitude + 0.035, 0.045, 0.04), CFrame.fromMatrix(mid, dir.Unit, n:Cross(dir).Unit), C.Ink, SMOOTH)
	end
end

-- Upper torso: cardigan details, hump, pearls
local ut = body.UpperTorso
decor("Hump", ut, Vector3.new(1.45, 1.15, 0.6), CFrame.new(0, 0.3, 0.42), C.Rose, FABRIC, nil, { ellipsoid = true })
decor("NightgownBib", ut, Vector3.new(0.5, 1.45, 0.06), CFrame.new(0, -0.05, -0.51), C.Mauve, FABRIC)
for i, y in { 0.35, -0.05, -0.45 } do
	decor("CardiganButton" .. i, ut, Vector3.new(0.13, 0.13, 0.13), CFrame.new(-0.36, y, -0.53), C.Mustard, SMOOTH, BALL)
end
decor("LeftCollar", ut, Vector3.new(0.55, 0.12, 0.42), CFrame.new(-0.26, 0.76, -0.4) * CFrame.Angles(0, 0, rad(-10)), C.Paper, FABRIC, nil, { ellipsoid = true })
decor("RightCollar", ut, Vector3.new(0.55, 0.12, 0.42), CFrame.new(0.26, 0.76, -0.4) * CFrame.Angles(0, 0, rad(10)), C.Paper, FABRIC, nil, { ellipsoid = true })
do
	local count = 7
	for i = 1, count do
		local th = rad(-72 + (i - 1) * (144 / (count - 1)))
		local x = 0.5 * math.sin(th)
		local z = -0.08 - 0.5 * math.cos(th)
		local y = 0.8 - 0.2 * math.cos(th)
		decor("Pearl" .. i, ut, Vector3.new(0.15, 0.15, 0.15), CFrame.new(x, y, z), C.Paper, SMOOTH, BALL)
	end
end

-- Sleeve cuffs (3/4 cardigan sleeves, bony forearms show below)
for _, side in { "Left", "Right" } do
	decor(side .. "Cuff", body[side .. "LowerArm"], Vector3.new(0.26, 0.54, 0.54), CFrame.new(0, 0.36, 0) * AXIS_Y, C.RoseDark, FABRIC, CYL)
end

-- Long bony fingers (3 per hand, hanging past the palm, slightly curled)
for _, side in { "Left", "Right" } do
	local hand = body[side .. "Hand"]
	for i, z in { -0.12, 0, 0.12 } do
		local len = if i == 2 then 0.5 else 0.42
		decor(side .. "Finger" .. i, hand, Vector3.new(0.075, len, 0.075),
			CFrame.new(0, -0.25, z) * CFrame.Angles(rad(z * 60), 0, 0) * CFrame.new(0, -len / 2 + 0.03, 0) * CFrame.Angles(0, 0, rad(-6)),
			C.Skin, SMOOTH, nil, { skin = true })
	end
end

-- Nightgown skirt: three flaring tiers welded to LowerTorso (legs swing underneath)
local lt = body.LowerTorso
decor("GownTier1", lt, Vector3.new(1.0, 1.95, 1.95), CFrame.new(0, -0.2, 0.02) * AXIS_Y, C.Mauve, FABRIC, CYL)
decor("GownTier2", lt, Vector3.new(0.58, 2.3, 2.3), CFrame.new(0, -0.95, 0.02) * AXIS_Y, C.Mauve, FABRIC, CYL)
decor("GownHem", lt, Vector3.new(0.5, 2.72, 2.72), CFrame.new(0, -1.45, 0.02) * AXIS_Y, C.Bruise, FABRIC, CYL)
-- Little flowers dotted on the gown
do
	local flowers = {
		{ a = -35, y = -0.45, r = 0.975, c = C.Mustard },
		{ a = 28, y = -0.1, r = 0.975, c = C.Paper },
		{ a = -10, y = -1.0, r = 1.15, c = C.Rose },
		{ a = 50, y = -0.95, r = 1.15, c = C.Mustard },
		{ a = 140, y = -0.6, r = 0.975, c = C.Paper },
		{ a = -130, y = -1.0, r = 1.15, c = C.Rose },
	}
	for i, f in flowers do
		local a = rad(f.a)
		local pos = Vector3.new(math.sin(a) * f.r, f.y, -math.cos(a) * f.r + 0.02)
		decor("GownFlower" .. i, lt, Vector3.new(0.16, 0.16, 0.16), CFrame.new(pos), f.c, SMOOTH, BALL)
	end
end

-- Fuzzy slipper pom-poms
for _, side in { "Left", "Right" } do
	decor(side .. "SlipperPom", body[side .. "Foot"], Vector3.new(0.34, 0.34, 0.34), CFrame.new(0, 0.16, -0.38), C.MintLight, FABRIC, BALL)
end

-- Humanoid ------------------------------------------------------------------------
local lowest = math.huge
for _, d in model:GetDescendants() do
	if d:IsA("BasePart") and d ~= hrp then
		local cf, s = d.CFrame, d.Size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local y = (cf * Vector3.new(sx * s.X, sy * s.Y, sz * s.Z)).Y
					lowest = math.min(lowest, y)
				end
			end
		end
	end
end
local hrpBottom = hrp.Position.Y - hrp.Size.Y / 2
local hipHeight = math.floor((hrpBottom - lowest) * 1000 + 0.5) / 1000

local humanoid = Instance.new("Humanoid")
humanoid.RigType = Enum.HumanoidRigType.R15
humanoid.AutomaticScalingEnabled = false
humanoid.HipHeight = hipHeight
humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
humanoid.RequiresNeck = false
humanoid.BreakJointsOnDeath = false
humanoid.WalkSpeed = 10
humanoid.Parent = model
Instance.new("Animator").Parent = humanoid

model.PrimaryPart = hrp
-- stand on y = 0
model:PivotTo(CFrame.new(0, hipHeight + hrp.Size.Y / 2, 0))
model:SetAttribute("RigVersion", 1)
model.Parent = folder

return string.format("Built %s: %d parts, HipHeight %.3f", model:GetFullName(), partCount, hipHeight)
