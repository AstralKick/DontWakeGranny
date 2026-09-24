-- build_grannies.luau
-- Builds the five chapter Grannies in ReplicatedStorage.Grannies, each cloned from TempGrandma
-- (same skeleton, Humanoid, HumanoidRootPart / Head / Eye / Skin conventions):
--   GardenGranny    "Nana Thorn"     BackGarden
--   MatronGranny    "Matron Gladys"  SunnyPines
--   WidowGranny     "Widow Wren"     StMildreds
--   FortuneGranny   "Madame Nana"    HarvestFair
--   NightmareGranny "Grandma?"       NightmareHouse (MinNight 26)
-- Idempotent: destroys and rebuilds those five. Never touches TempGrandma.
-- Run in Studio (Edit mode) via the command bar or the MCP execute_luau tool.
--
-- Rules kept here (see GrandmaConfig.OutfitParts / GrandmaRig):
--   * TempGrandma clothing part names stay where the garment still exists, so nightly outfits
--     keep recolouring them.
--   * Every NEW part is named "Acc_*" and never matches an OutfitParts pattern, so costume
--     pieces keep their own colours.
--   * Eye / EyeWhite parts stay on the head surface (GrandmaEyesController builds lids from them).
--   * All added parts: unanchored, CanCollide/CanQuery/CanTouch false, Massless, welded with
--     WeldConstraints to the body part that should carry them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Set to e.g. { WidowGranny = true } to rebuild only some rigs.
local ONLY: { [string]: boolean }? = nil

local folder = ReplicatedStorage:FindFirstChild("Grannies")
assert(folder, "ReplicatedStorage.Grannies is missing")
local template = folder:FindFirstChild("TempGrandma")
assert(template and template:IsA("Model"), "ReplicatedStorage.Grannies.TempGrandma is missing")

local rad = math.rad
local V = Vector3.new
local rgb, hex = Color3.fromRGB, Color3.fromHex

local SMOOTH = Enum.Material.SmoothPlastic
local FABRIC = Enum.Material.Fabric
local METAL = Enum.Material.Metal
local NEON = Enum.Material.Neon
local GLASS = Enum.Material.Glass
local WOOD = Enum.Material.Wood

local BALL = Enum.PartType.Ball
local CYL = Enum.PartType.Cylinder
local BLOCK = Enum.PartType.Block
local AXIS_Y = CFrame.Angles(0, 0, rad(90)) -- cylinder axis X -> Y
local AXIS_Z = CFrame.Angles(0, rad(90), 0) -- cylinder axis X -> Z

local C = {
	Rose = hex("#D97A8A"),
	RoseDark = rgb(184, 98, 116),
	Mint = hex("#9CC5A1"),
	Mustard = hex("#E0B04F"),
	Bruise = hex("#7B5C8E"),
	Paper = hex("#F3E9D2"),
	Ink = hex("#2A1A24"),
	Blood = hex("#A8323E"),
	Night = hex("#3B2A3F"),
	Hair = rgb(178, 170, 198),
	HairDark = rgb(150, 140, 172),
	Lens = rgb(214, 236, 222),
	Gold = rgb(232, 184, 72),
	Silver = rgb(188, 192, 200),
}

-- ---------------------------------------------------------------------------- helpers
local M: Model = nil :: any

local function find(name: string): BasePart
	local p = M:FindFirstChild(name, true)
	assert(p and p:IsA("BasePart"), `{M.Name}: part {name} missing`)
	return p
end

local function kill(pattern: string)
	for _, d in M:GetDescendants() do
		if d:IsA("BasePart") and d.Name:find(pattern) then
			d:Destroy()
		end
	end
end

type Opts = { ell: boolean?, t: number?, skin: boolean?, shadow: boolean?, refl: number?, cyl: boolean?, w: number?, extra: number? }

local function acc(name: string, attach: BasePart, size: Vector3, localCf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?, o: Opts?): Part
	local opts: Opts = o or {}
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape or BLOCK
	p.Size = size
	p.CFrame = attach.CFrame * localCf
	p.Color = color
	p.Material = material or SMOOTH
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = opts.shadow ~= false
	if opts.t then
		p.Transparency = opts.t
	end
	if opts.refl then
		p.Reflectance = opts.refl
	end
	if opts.ell then
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
	end
	if opts.skin then
		p:SetAttribute("Skin", true)
	end
	local w = Instance.new("WeldConstraint")
	w.Part0 = attach
	w.Part1 = p
	w.Parent = p
	p.Parent = M
	return p
end

-- Rod from a to b (attach-local points). Block (w x thick x len) or cylinder (o.cyl).
local function seg(name: string, attach: BasePart, a: Vector3, b: Vector3, thick: number, color: Color3, material: Enum.Material?, o: Opts?): Part
	local opts: Opts = o or {}
	local dir = b - a
	local len = dir.Magnitude + (opts.extra or 0)
	local up = if math.abs(dir.Unit.Y) > 0.95 then Vector3.zAxis else Vector3.yAxis
	local cf = CFrame.lookAt((a + b) / 2, b, up)
	if opts.cyl then
		return acc(name, attach, V(len, thick, thick), cf * AXIS_Z, color, material, CYL, opts)
	end
	return acc(name, attach, V(opts.w or thick, thick, len), cf, color, material, BLOCK, opts)
end

-- Flat strip from a (bottom) to b (top) whose face points along `normal`.
local function strip(name: string, attach: BasePart, a: Vector3, b: Vector3, width: number, thick: number, color: Color3, material: Enum.Material?, normal: Vector3, o: Opts?): Part
	local up = (b - a).Unit
	local right = up:Cross(normal).Unit
	local cf = CFrame.fromMatrix((a + b) / 2, right, up)
	return acc(name, attach, V(width, (b - a).Magnitude, thick), cf, color, material, BLOCK, o)
end

-- Point on an ellipsoid surface in direction dir from its centre (+ push along the normal).
local function ellPoint(center: Vector3, r: Vector3, dir: Vector3, push: number?): (Vector3, Vector3)
	local d = dir.Unit
	local t = 1 / math.sqrt((d.X / r.X) ^ 2 + (d.Y / r.Y) ^ 2 + (d.Z / r.Z) ^ 2)
	local p = center + d * t
	local q = p - center
	local n = V(q.X / r.X ^ 2, q.Y / r.Y ^ 2, q.Z / r.Z ^ 2).Unit
	return p + n * (push or 0), n
end

-- Head: ellipsoid 1.3 x 1.45 x 1.25, front is -Z.
local HEAD_R = V(0.65, 0.725, 0.625)
local function headSurface(x: number, y: number): (Vector3, Vector3)
	local k = math.max(0, 1 - (x / HEAD_R.X) ^ 2 - (y / HEAD_R.Y) ^ 2)
	local z = -HEAD_R.Z * math.sqrt(k)
	local n = V(x / HEAD_R.X ^ 2, y / HEAD_R.Y ^ 2, z / HEAD_R.Z ^ 2).Unit
	return V(x, y, z), n
end
local function onHead(x: number, y: number, push: number): CFrame
	local pos, n = headSurface(x, y)
	pos += n * push
	return CFrame.lookAt(pos, pos + n)
end

-- A line of thin segments hugging the face (smiles, cracks).
local function faceLine(prefix: string, head: BasePart, pts: { Vector2 }, thick: number, color: Color3, push: number?)
	local list = {}
	for _, v in pts do
		local p, n = headSurface(v.X, v.Y)
		table.insert(list, { pos = p + n * (push or 0.012), n = n })
	end
	for i = 1, #list - 1 do
		local a, b = list[i], list[i + 1]
		local dir = b.pos - a.pos
		local mid = (a.pos + b.pos) / 2
		local n = (a.n + b.n).Unit
		acc(prefix .. i, head, V(dir.Magnitude + thick * 0.8, thick, thick), CFrame.fromMatrix(mid, dir.Unit, n:Cross(dir).Unit), color, SMOOTH)
	end
end

-- Recolour a hand (and optionally the forearm) as a glove: no longer skin.
local function glove(side: string, color: Color3, material: Enum.Material, forearm: boolean?)
	local names = { side .. "Hand", side .. "Finger1", side .. "Finger2", side .. "Finger3" }
	if forearm then
		table.insert(names, side .. "LowerArm")
	end
	for _, n in names do
		local p = find(n)
		p.Color = color
		p.Material = material
		p:SetAttribute("Skin", nil)
	end
end

-- Fabric bow (knot + 2 loops + 2 tails). cf: centre in attach space, -Z facing out.
local function bow(prefix: string, attach: BasePart, cf: CFrame, color: Color3, s: number)
	acc(prefix .. "Knot", attach, V(0.17, 0.17, 0.13) * s, cf, color, FABRIC, BLOCK, { ell = true })
	for _, side in { -1, 1 } do
		local tag = if side < 0 then "L" else "R"
		acc(prefix .. "Loop" .. tag, attach, V(0.44, 0.27, 0.11) * s, cf * CFrame.new(0.2 * side * s, 0.02 * s, 0.01) * CFrame.Angles(0, 0, rad(14 * side)), color, FABRIC, BLOCK, { ell = true })
		acc(prefix .. "Tail" .. tag, attach, V(0.13 * s, 0.5 * s, 0.035), cf * CFrame.new(0.09 * side * s, -0.27 * s, 0.02) * CFrame.Angles(0, 0, rad(-14 * side)), color, FABRIC)
	end
end

-- Apron skirt: flat panels fanned around the gown (LowerTorso space), top (yTop, rTop) to bottom (yBot, rBot).
local function apronSkirt(prefix: string, lt: BasePart, yTop: number, yBot: number, rTop: number, rBot: number, angles: { number }, width: number, color: Color3)
	local out = {}
	local T, B = V(0, yTop, -rTop), V(0, yBot, -rBot)
	local up = (T - B).Unit
	local len = (T - B).Magnitude
	for i, a in angles do
		local cf = CFrame.Angles(0, rad(a), 0) * CFrame.fromMatrix((T + B) / 2, Vector3.xAxis, up)
		local p = acc(prefix .. i, lt, V(width, len, 0.05), cf, color, FABRIC)
		out[i] = { part = p, cf = cf, len = len }
	end
	return out
end

-- Re-solve the skeleton after changing Motor6D offsets / part sizes; welded parts follow their
-- Part0 with the offsets in `recs` (editable by the mutate callback), then welds are rebuilt.
local function relayout(mutate: ({ [string]: { any } }) -> ())
	local recs = {}
	local byName: { [string]: { any } } = {}
	for _, w in M:GetDescendants() do
		if w:IsA("WeldConstraint") and w.Part0 and w.Part1 then
			local r = { w = w, p0 = w.Part0, p1 = w.Part1, off = w.Part0.CFrame:ToObjectSpace(w.Part1.CFrame) }
			table.insert(recs, r)
			byName[w.Part1.Name] = byName[w.Part1.Name] or {}
			table.insert(byName[w.Part1.Name], r)
		end
	end
	mutate(byName)
	local motors = {}
	for _, d in M:GetDescendants() do
		if d:IsA("Motor6D") then
			table.insert(motors, d)
		end
	end
	local placed = { [M:FindFirstChild("HumanoidRootPart")] = true }
	local progress = true
	while progress do
		progress = false
		for _, m in motors do
			if placed[m.Part0] and not placed[m.Part1] then
				m.Part1.CFrame = m.Part0.CFrame * m.C0 * m.C1:Inverse()
				placed[m.Part1] = true
				progress = true
			end
		end
		for _, r in recs do
			if placed[r.p0] and not placed[r.p1] then
				r.p1.CFrame = r.p0.CFrame * r.off
				placed[r.p1] = true
				progress = true
			end
		end
	end
	for _, r in recs do
		local parent = r.w.Parent
		r.w:Destroy()
		local w = Instance.new("WeldConstraint")
		w.Part0 = r.p0
		w.Part1 = r.p1
		w.Parent = parent
	end
end

local function motor(name: string): Motor6D
	for _, d in M:GetDescendants() do
		if d:IsA("Motor6D") and d.Name == name then
			return d
		end
	end
	error(`motor {name} missing`)
end

-- ============================================================================ 1. GardenGranny
local function buildGarden()
	local head, ut, lt = find("Head"), find("UpperTorso"), find("LowerTorso")
	kill("^HairKnob$")
	kill("SlipperPom$") -- wellies, not slippers

	local STRAW, STRAW_DK = rgb(224, 192, 120), rgb(170, 132, 78)
	local GREENS = { rgb(96, 142, 78), rgb(126, 166, 92), rgb(78, 118, 66) }
	local TWIG = rgb(112, 80, 56)
	local MUD, MUD_DK = rgb(134, 98, 66), rgb(108, 78, 54)

	-- Wide straw sun hat perched on the beehive (knitting needles poke through as hatpins)
	local brimCf = CFrame.new(0, 0.84, 0.14) * CFrame.Angles(rad(13), 0, 0)
	acc("Acc_HatBrim", head, V(0.07, 2.9, 2.9), brimCf * AXIS_Y, STRAW, FABRIC, CYL)
	acc("Acc_HatBrimUnder", head, V(0.05, 2.66, 2.66), brimCf * CFrame.new(0, -0.05, 0) * AXIS_Y, STRAW_DK, FABRIC, CYL)
	-- rounded, slightly squashed straw dome over the beehive (not a top hat)
	acc("Acc_HatCrown", head, V(0.4, 1.38, 1.38), brimCf * CFrame.new(0, 0.2, 0.12) * AXIS_Y, STRAW, FABRIC, CYL)
	acc("Acc_HatCrownTop", head, V(1.4, 1.72, 1.4), brimCf * CFrame.new(0, 0.36, 0.12) * CFrame.Angles(0, 0, rad(4)), STRAW, FABRIC, BLOCK, { ell = true })
	acc("Acc_HatRibbon", head, V(0.24, 1.4, 1.4), brimCf * CFrame.new(0, 0.17, 0.12) * AXIS_Y, C.Rose, FABRIC, CYL)
	for _, side in { -1, 1 } do
		local tag = if side < 0 then "L" else "R"
		local a = brimCf * V(0.1 * side, 0.06, 0.78)
		local b = brimCf * V(0.2 * side, 0.06, 1.46)
		local c = brimCf * V(0.27 * side, -0.62, 1.56)
		seg("Acc_RibbonTailTop" .. tag, head, a, b, 0.03, C.Rose, FABRIC, { w = 0.16, extra = 0.04 })
		strip("Acc_RibbonTailDrop" .. tag, head, c, b, 0.16, 0.03, C.Rose, FABRIC, (brimCf.Rotation * V(0, 0, 1)))
	end
	bow("Acc_HatBow", head, brimCf * CFrame.new(-0.7, 0.2, 0.05) * CFrame.Angles(0, rad(90), 0), C.Rose, 0.8)
	for i, a in { 18, 42, 66 } do
		local ar = rad(a)
		local out = brimCf.Rotation * V(math.sin(ar), 0, -math.cos(ar))
		local pos = brimCf * V(0.71 * math.sin(ar), 0.2 + (i % 2) * 0.05, 0.12 - 0.71 * math.cos(ar))
		acc("Acc_HatDaisy" .. i, head, V(0.36, 0.36, 0.07), CFrame.lookAt(pos, pos + out), C.Paper, SMOOTH, BLOCK, { ell = true })
		acc("Acc_HatDaisyEye" .. i, head, V(0.13, 0.13, 0.13), CFrame.lookAt(pos + out * 0.035, pos + out * 2), C.Mustard, SMOOTH, BALL)
	end

	-- Leaves and twigs caught in the hair (poking out under the brim)
	local capC, capR = V(0, 0.5, 0.2), V(0.71, 0.5, 0.69)
	local leaves = { V(-1, -0.15, 0.15), V(1, -0.2, 0.35), V(0.5, -0.3, 1), V(-0.6, -0.25, 0.9), V(-0.9, -0.05, -0.45) }
	for i, d in leaves do
		local p, n = ellPoint(capC, capR, d, -0.02)
		acc("Acc_HairLeaf" .. i, head, V(0.05, 0.2, 0.42), CFrame.lookAt(p, p + n) * CFrame.Angles(rad(-25), 0, rad(i * 47)) * CFrame.new(0, 0, -0.15), GREENS[(i % 3) + 1], SMOOTH, BLOCK, { ell = true })
	end
	for i, d in { V(0.95, -0.1, -0.25), V(-0.35, -0.2, 1), V(0.25, -0.35, 1) } do
		local p, n = ellPoint(capC, capR, d, -0.03)
		local tip = p + (n + V(0, 0.25 * (i - 2), 0)).Unit * 0.5
		seg("Acc_HairTwig" .. i, head, p, tip, 0.05, TWIG, WOOD, { cyl = true })
	end

	-- Gardening gloves
	local GLOVE = rgb(128, 170, 110)
	for _, side in { "Left", "Right" } do
		glove(side, GLOVE, FABRIC)
		acc("Acc_GloveCuff" .. side:sub(1, 1), find(side .. "LowerArm"), V(0.26, 0.5, 0.5), CFrame.new(0, -0.42, 0) * AXIS_Y, C.Rose, FABRIC, CYL)
	end

	-- Pruning shears in her right hand (outer side of the hand, blades down and forward)
	local rh = find("RightHand")
	seg("Acc_ShearHandleA", rh, V(0.15, 0.12, -0.02), V(0.15, -0.42, -0.11), 0.09, C.Blood, SMOOTH, { cyl = true })
	seg("Acc_ShearHandleB", rh, V(0.15, 0.12, 0.09), V(0.15, -0.42, -0.04), 0.09, C.Blood, SMOOTH, { cyl = true })
	acc("Acc_ShearBolt", rh, V(0.13, 0.13, 0.13), CFrame.new(0.16, -0.47, -0.07), C.Silver, METAL, BALL)
	seg("Acc_ShearBladeA", rh, V(0.17, -0.45, -0.07), V(0.21, -1.02, -0.36), 0.12, C.Silver, METAL, { w = 0.04 })
	seg("Acc_ShearBladeB", rh, V(0.19, -0.45, -0.07), V(0.23, -1.05, -0.14), 0.12, C.Silver, METAL, { w = 0.04 })

	-- Floral apron (bib + fanned skirt panels + waistband + bow at the back)
	local APRON = rgb(246, 226, 178)
	acc("Acc_ApronBib", ut, V(0.62, 0.8, 0.05), CFrame.new(0, -0.36, -0.58), APRON, FABRIC)
	for _, side in { -1, 1 } do
		strip("Acc_ApronStrap" .. (if side < 0 then "L" else "R"), ut, V(0.26 * side, 0.0, -0.585), V(0.42 * side, 0.8, -0.47), 0.11, 0.04, C.Rose, FABRIC, V(0, 0, -1))
	end
	acc("Acc_ApronBibFlowerA", ut, V(0.17, 0.17, 0.04), CFrame.new(-0.12, -0.2, -0.61), C.Rose, SMOOTH, BLOCK, { ell = true })
	acc("Acc_ApronBibFlowerB", ut, V(0.15, 0.15, 0.04), CFrame.new(0.14, -0.5, -0.61), C.Bruise, SMOOTH, BLOCK, { ell = true })
	local panels = apronSkirt("Acc_ApronPanel", lt, 0.2, -1.12, 1.02, 1.32, { -30, 0, 30 }, 0.7, APRON)
	for i, pn in panels do
		acc("Acc_ApronTrim" .. i, lt, V(0.72, 0.08, 0.075), pn.cf * CFrame.new(0, -pn.len / 2 + 0.03, -0.005), C.Rose, FABRIC)
	end
	local flowers = {
		{ 1, -0.18, 0.42, C.Rose }, { 1, 0.15, -0.05, C.Bruise }, { 1, -0.1, -0.45, C.Mustard },
		{ 2, 0.2, 0.45, C.Mint }, { 2, -0.22, 0.12, C.Rose },
		{ 3, 0.12, 0.38, C.Mustard }, { 3, -0.16, 0.0, C.Rose }, { 3, 0.18, -0.4, C.Bruise }, { 2, 0.22, -0.2, C.Rose },
	}
	for i, f in flowers do
		local pn = panels[f[1]]
		acc("Acc_ApronFlower" .. i, lt, V(0.19, 0.19, 0.04), pn.cf * CFrame.new(f[2], f[3], -0.035), f[4], SMOOTH, BLOCK, { ell = true })
	end
	for i, m in { { 1, 0.12, -0.3, 0.42, 0.28, MUD }, { 3, -0.1, -0.22, 0.38, 0.3, MUD_DK }, { 2, -0.05, -0.5, 0.3, 0.18, MUD } } do
		local pn = panels[m[1]]
		acc("Acc_ApronMud" .. i, lt, V(m[4], m[5], 0.04), pn.cf * CFrame.new(m[2], m[3], -0.04) * CFrame.Angles(0, 0, rad(i * 23)), m[6], SMOOTH, BLOCK, { ell = true })
	end
	local mid = panels[2]
	acc("Acc_ApronPocket", lt, V(0.42, 0.32, 0.04), mid.cf * CFrame.new(-0.08, -0.08, -0.045), C.Rose, FABRIC)
	acc("Acc_TrowelHandle", lt, V(0.34, 0.09, 0.09), mid.cf * CFrame.new(-0.18, 0.18, -0.07) * CFrame.Angles(0, 0, rad(8)) * AXIS_Y, rgb(140, 98, 62), WOOD, CYL)
	acc("Acc_SeedPacket", lt, V(0.16, 0.22, 0.02), mid.cf * CFrame.new(0.04, 0.12, -0.06) * CFrame.Angles(0, 0, rad(-12)), C.Mustard, SMOOTH)
	acc("Acc_ApronBand", lt, V(0.14, 2.02, 2.02), CFrame.new(0, 0.26, 0.02) * AXIS_Y, C.Rose, FABRIC, CYL)
	bow("Acc_ApronBow", lt, CFrame.new(0, 0.24, 1.05) * CFrame.Angles(0, math.pi, 0), C.Rose, 1)

	-- Muddy wellies over the slipper feet (feet keep their names, hidden inside the boots)
	local BOOT, BOOT_DK = rgb(88, 124, 86), rgb(52, 70, 50)
	for _, side in { "Left", "Right" } do
		local s = side:sub(1, 1)
		local sx = if s == "L" then -1 else 1
		local foot, leg = find(side .. "Foot"), find(side .. "LowerLeg")
		acc("Acc_WellieSole" .. s, foot, V(0.8, 0.1, 1.18), CFrame.new(0, -0.11, 0), BOOT_DK, SMOOTH)
		acc("Acc_WellieUpper" .. s, foot, V(0.76, 0.34, 0.8), CFrame.new(0, 0.03, 0.16), BOOT, SMOOTH)
		acc("Acc_WellieToe" .. s, foot, V(0.76, 0.36, 0.62), CFrame.new(0, 0.02, -0.26), BOOT, SMOOTH, BLOCK, { ell = true })
		acc("Acc_WellieShaft" .. s, leg, V(0.62, 0.62, 0.62), CFrame.new(0, -0.18, 0) * AXIS_Y, BOOT, SMOOTH, CYL)
		acc("Acc_WellieMudToe" .. s, foot, V(0.36, 0.18, 0.34), CFrame.new(0.16 * sx, -0.04, -0.44), MUD, SMOOTH, BLOCK, { ell = true })
		acc("Acc_WellieMudShaft" .. s, leg, V(0.08, 0.26, 0.3), CFrame.new(0.3 * sx, -0.34, -0.06), MUD_DK, SMOOTH, BLOCK, { ell = true })
	end
end

-- ============================================================================ 2. MatronGranny
local function buildMatron()
	local head, ut, lt = find("Head"), find("UpperTorso"), find("LowerTorso")
	for _, n in { "LeftGlassesRim", "RightGlassesRim", "LeftLens", "RightLens", "LeftGlassesArm", "RightGlassesArm", "GlassesBridge" } do
		find(n):Destroy()
	end
	local FRAME = rgb(112, 50, 82)
	local WHITE = rgb(244, 242, 236)
	local NAVY = rgb(62, 70, 110)

	-- Cat-eye glasses (eye whites / pupils kept, new frames with upswept wings)
	for _, side in { -1, 1 } do
		local s = if side < 0 then "L" else "R"
		local x = 0.385 * side
		acc("Acc_CatRim" .. s, head, V(0.05, 0.8, 0.8), CFrame.new(x, 0.05, -0.655) * AXIS_Z, FRAME, SMOOTH, CYL)
		acc("Acc_CatBrow" .. s, head, V(0.68, 0.14, 0.08), CFrame.new(x + 0.02 * side, 0.41, -0.69) * CFrame.Angles(0, 0, rad(9 * side)), FRAME)
		acc("Acc_CatWing" .. s, head, V(0.42, 0.13, 0.08), CFrame.new(x + 0.37 * side, 0.43, -0.66) * CFrame.Angles(0, 0, rad(32 * side)), FRAME)
		acc("Acc_Rhinestone" .. s, head, V(0.09, 0.09, 0.09), CFrame.new(x + 0.53 * side, 0.54, -0.7), rgb(236, 244, 255), NEON, BALL, { shadow = false })
		local lens = acc("Acc_Lens" .. s, head, V(0.02, 0.76, 0.76), CFrame.new(x, 0.05, -0.86) * AXIS_Z, C.Lens, NEON, CYL, { t = 0.86, shadow = false })
		lens.CastShadow = false
		acc("Acc_GlassesArm" .. s, head, V(0.045, 0.045, 0.9), CFrame.new(0.715 * side, 0.1, -0.28), FRAME)
		-- chain from the arm, down past the ear, round the back of the neck
		local a, b, c = V(0.74 * side, 0.08, 0.15), V(0.75 * side, -0.55, 0.3), V(0.38 * side, -0.9, 0.52)
		seg("Acc_GlassChainA" .. s, head, a, b, 0.035, C.Gold, METAL, { cyl = true, extra = 0.02 })
		seg("Acc_GlassChainB" .. s, head, b, c, 0.035, C.Gold, METAL, { cyl = true, extra = 0.02 })
	end
	seg("Acc_GlassChainBack", head, V(-0.38, -0.9, 0.52), V(0.38, -0.9, 0.52), 0.035, C.Gold, METAL, { cyl = true, extra = 0.02 })
	acc("Acc_GlassesBridge", head, V(0.14, 0.05, 0.05), CFrame.new(0, 0.14, -0.7), FRAME)

	-- 70s nurse cap: a curved white band standing on the hair in front of the beehive
	local capCf = CFrame.new(0, 0.95, -0.32) * CFrame.Angles(rad(22), 0, 0)
	acc("Acc_NurseCapFront", head, V(0.72, 0.52, 0.1), capCf, WHITE, SMOOTH)
	acc("Acc_NurseCapStripeF", head, V(0.73, 0.08, 0.02), capCf * CFrame.new(0, 0.16, -0.055), NAVY, SMOOTH)
	acc("Acc_NurseCapPin", head, V(0.1, 0.1, 0.1), capCf * CFrame.new(0, -0.06, -0.06), NAVY, SMOOTH, BALL)
	for _, side in { -1, 1 } do
		local s = if side < 0 then "L" else "R"
		local pc = capCf * CFrame.new(0.34 * side, 0, 0) * CFrame.Angles(0, rad(-52 * side), 0) * CFrame.new(0.28 * side, 0, 0)
		acc("Acc_NurseCapSide" .. s, head, V(0.58, 0.52, 0.1), pc, WHITE, SMOOTH)
		acc("Acc_NurseCapStripe" .. s, head, V(0.59, 0.08, 0.02), pc * CFrame.new(0, 0.16, -0.055), NAVY, SMOOTH)
		-- folded-back wing at the rear end of each side piece
		acc("Acc_NurseCapWing" .. s, head, V(0.34, 0.4, 0.08), pc * CFrame.new(0.3 * side, 0.05, 0.08) * CFrame.Angles(0, rad(-35 * side), rad(-10 * side)) * CFrame.new(0.15 * side, 0, 0), WHITE, SMOOTH)
	end
	acc("Acc_NurseCapFold", head, V(1.0, 0.06, 0.5), capCf * CFrame.new(0, 0.25, 0.22), WHITE, SMOOTH)

	-- White apron bib + short apron, navy belt with a silver buckle
	acc("Acc_ApronBib", ut, V(0.64, 0.86, 0.05), CFrame.new(0, -0.33, -0.58), WHITE, FABRIC)
	for _, side in { -1, 1 } do
		strip("Acc_ApronStrap" .. (if side < 0 then "L" else "R"), ut, V(0.27 * side, 0.08, -0.585), V(0.42 * side, 0.8, -0.47), 0.11, 0.04, WHITE, FABRIC, V(0, 0, -1))
	end
	apronSkirt("Acc_ApronPanel", lt, 0.2, -0.95, 1.02, 1.28, { -28, 0, 28 }, 0.66, WHITE)
	acc("Acc_NurseBelt", lt, V(0.15, 2.02, 2.02), CFrame.new(0, 0.26, 0.02) * AXIS_Y, NAVY, FABRIC, CYL)
	acc("Acc_BeltBuckle", lt, V(0.36, 0.24, 0.05), CFrame.new(0, 0.26, -1.01), C.Silver, METAL)
	acc("Acc_BeltBuckleInner", lt, V(0.2, 0.1, 0.06), CFrame.new(0, 0.26, -1.015), NAVY, SMOOTH)

	-- Fob watch pinned on her left breast
	acc("Acc_FobPin", ut, V(0.1, 0.1, 0.1), CFrame.new(-0.6, 0.34, -0.555), C.Gold, METAL, BALL)
	strip("Acc_FobChain", ut, V(-0.6, 0.1, -0.56), V(-0.6, 0.33, -0.56), 0.03, 0.03, C.Gold, METAL, V(0, 0, -1))
	acc("Acc_FobWatch", ut, V(0.07, 0.28, 0.28), CFrame.new(-0.6, -0.03, -0.565) * AXIS_Z, C.Silver, METAL, CYL)
	acc("Acc_FobFace", ut, V(0.02, 0.22, 0.22), CFrame.new(-0.6, -0.03, -0.605) * AXIS_Z, C.Paper, SMOOTH, CYL)
	acc("Acc_FobHand", ut, V(0.02, 0.09, 0.015), CFrame.new(-0.6, 0.0, -0.618) * CFrame.Angles(0, 0, rad(-30)), C.Ink)

	-- Name badge "MATRON" on her right breast
	acc("Acc_BadgeBack", ut, V(0.64, 0.25, 0.03), CFrame.new(0.5, 0.36, -0.54), C.Blood)
	local badge = acc("Acc_NameBadge", ut, V(0.58, 0.19, 0.03), CFrame.new(0.5, 0.36, -0.56), C.Paper)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BadgeGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 200
	gui.LightInfluence = 0.4
	gui.Parent = badge
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "MATRON"
	label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	label.TextScaled = true
	label.TextColor3 = C.Ink
	label.Parent = gui

	-- Squeaky walking frame welded in front of her (2.86 studs wide, feet on the ground)
	local ALU, GRIP, BALLC = rgb(186, 190, 198), rgb(52, 44, 50), rgb(206, 224, 96)
	local W, ZR, ZF, TOP, GROUND = 1.35, -0.55, -1.55, -0.2, -2.36
	for _, sx in { -1, 1 } do
		local s = if sx < 0 then "L" else "R"
		local fBot, rBot = GROUND + 0.16, GROUND + 0.12
		acc("Acc_WalkerLegF" .. s, lt, V(TOP - fBot, 0.1, 0.1), CFrame.new(W * sx, (TOP + fBot) / 2, ZF) * AXIS_Y, ALU, METAL, CYL)
		acc("Acc_WalkerLegB" .. s, lt, V(TOP - rBot, 0.1, 0.1), CFrame.new(W * sx, (TOP + rBot) / 2, ZR) * AXIS_Y, ALU, METAL, CYL)
		acc("Acc_WalkerRail" .. s, lt, V(ZR - ZF + 0.1, 0.1, 0.1), CFrame.new(W * sx, TOP, (ZR + ZF) / 2) * AXIS_Z, ALU, METAL, CYL)
		acc("Acc_WalkerBrace" .. s, lt, V(ZR - ZF, 0.08, 0.08), CFrame.new(W * sx, -1.3, (ZR + ZF) / 2) * AXIS_Z, ALU, METAL, CYL)
		acc("Acc_WalkerGrip" .. s, lt, V(0.5, 0.16, 0.16), CFrame.new(W * sx, TOP + 0.02, ZR - 0.27) * AXIS_Z, GRIP, SMOOTH, CYL)
		acc("Acc_WalkerBall" .. s, lt, V(0.32, 0.32, 0.32), CFrame.new(W * sx, GROUND + 0.16, ZF), BALLC, FABRIC, BALL)
		acc("Acc_WalkerTip" .. s, lt, V(0.12, 0.14, 0.14), CFrame.new(W * sx, GROUND + 0.06, ZR) * AXIS_Y, GRIP, SMOOTH, CYL)
	end
	acc("Acc_WalkerFrontBar", lt, V(2 * W, 0.1, 0.1), CFrame.new(0, TOP, ZF), ALU, METAL, CYL)
	acc("Acc_WalkerLowBar", lt, V(2 * W, 0.08, 0.08), CFrame.new(0, -1.2, ZF), ALU, METAL, CYL)
	acc("Acc_WalkerBag", lt, V(0.9, 0.55, 0.22), CFrame.new(0, TOP - 0.33, ZF - 0.12), C.Rose, FABRIC)
	acc("Acc_WalkerBagStripe", lt, V(0.92, 0.08, 0.23), CFrame.new(0, TOP - 0.25, ZF - 0.12), C.Paper, FABRIC)
end

-- ============================================================================ 3. WidowGranny
local function buildWidow()
	local head, lt = find("Head"), find("LowerTorso")
	kill("^Pearl%d") -- the high lace neck replaces the pearls
	local BLACK, LACE = rgb(34, 28, 38), rgb(78, 66, 84)

	-- Long black gloves up to the cardigan cuffs
	for _, side in { "Left", "Right" } do
		glove(side, BLACK, SMOOTH, true)
	end

	-- High lace neck with a scalloped frill, cameo brooch at the throat
	acc("Acc_HighNeck", head, V(0.44, 1.08, 1.08), CFrame.new(0, -0.74, 0.04) * AXIS_Y, BLACK, FABRIC, CYL)
	for i = 1, 10 do
		local a = rad((i - 1) * 36)
		local pos = V(0.56 * math.sin(a), -0.53, 0.04 - 0.56 * math.cos(a))
		acc("Acc_NeckLace" .. i, head, V(0.2, 0.14, 0.1), CFrame.lookAt(pos, pos + V(math.sin(a), 0.7, -math.cos(a))), LACE, FABRIC, BLOCK, { ell = true })
	end
	acc("Acc_CameoFrame", head, V(0.27, 0.33, 0.06), CFrame.new(0, -0.74, -0.52), C.Gold, METAL, BLOCK, { ell = true })
	acc("Acc_CameoStone", head, V(0.21, 0.27, 0.05), CFrame.new(0, -0.74, -0.545), rgb(206, 140, 132), SMOOTH, BLOCK, { ell = true })
	acc("Acc_CameoFace", head, V(0.09, 0.16, 0.04), CFrame.new(0.015, -0.73, -0.565), C.Paper, SMOOTH, BLOCK, { ell = true })

	-- Small mourning hat tipped forward on the beehive, two plumes
	local hatCf = CFrame.new(0, 0.95, -0.2) * CFrame.Angles(rad(-10), 0, rad(-6))
	acc("Acc_MourningHat", head, V(0.36, 0.95, 0.95), hatCf * CFrame.new(0, 0.18, 0) * AXIS_Y, BLACK, FABRIC, CYL)
	acc("Acc_MourningHatBrim", head, V(0.05, 1.9, 1.9), hatCf * AXIS_Y, BLACK, FABRIC, CYL)
	acc("Acc_MourningHatBand", head, V(0.1, 0.97, 0.97), hatCf * CFrame.new(0, 0.07, 0) * AXIS_Y, C.Bruise, SMOOTH, CYL)
	-- two plumes sweeping out and back from the side of the hat (read from front, side and back)
	local FEATHER = rgb(88, 60, 100)
	acc("Acc_HatPlumeA", head, V(0.12, 1.3, 0.4), hatCf * CFrame.new(0.5, 0.5, 0.12) * CFrame.Angles(rad(30), 0, rad(-48)), FEATHER, FABRIC, BLOCK, { ell = true })
	acc("Acc_HatPlumeB", head, V(0.1, 1.05, 0.32), hatCf * CFrame.new(0.52, 0.32, 0.28) * CFrame.Angles(rad(55), 0, rad(-62)), BLACK, FABRIC, BLOCK, { ell = true })

	-- Semi-transparent lace veil: a rounded shell under the brim over the face (eyes read through it),
	-- a bead trim round its lower edge and a few opaque lace spots
	local veilC, veilR = V(0, 0.02, -0.2), V(0.9, 0.78, 0.84)
	acc("Acc_Veil", head, veilR * 2, CFrame.new(veilC), BLACK, SMOOTH, BLOCK, { ell = true, t = 0.45, shadow = false })
	for i = 1, 9 do
		local a = rad(-100 + (i - 1) * 25)
		local p, n = ellPoint(veilC, veilR, V(math.sin(a), -0.95, -math.cos(a)), 0.02)
		acc("Acc_VeilBead" .. i, head, V(0.08, 0.08, 0.08), CFrame.new(p), BLACK, SMOOTH, BALL)
	end
	for i, d in { V(-0.75, 0.45, -0.5), V(0.75, 0.45, -0.5), V(0, 0.75, -0.65), V(-0.35, -0.6, -0.75), V(0.35, -0.6, -0.75), V(-0.9, -0.2, -0.3), V(0.9, -0.2, -0.3) } do
		local p, n = ellPoint(veilC, veilR, d, 0.005)
		acc("Acc_VeilDot" .. i, head, V(0.07, 0.07, 0.03), CFrame.lookAt(p, p + n), BLACK, SMOOTH, BLOCK, { ell = true })
	end

	-- Lit candle on a brass chamberstick in her right hand
	local rh = find("RightHand")
	local BRASS, WAX = rgb(196, 150, 72), rgb(238, 228, 204)
	local z = -0.44
	acc("Acc_CandleDish", rh, V(0.06, 0.44, 0.44), CFrame.new(0, -0.5, z) * AXIS_Y, BRASS, METAL, CYL)
	seg("Acc_CandleHandle", rh, V(0, -0.5, z + 0.2), V(0, -0.42, -0.05), 0.05, BRASS, METAL, { cyl = true })
	acc("Acc_Candle", rh, V(0.62, 0.17, 0.17), CFrame.new(0, -0.16, z) * AXIS_Y, WAX, SMOOTH, CYL)
	acc("Acc_CandleDripA", rh, V(0.07, 0.2, 0.07), CFrame.new(0.075, 0.02, z - 0.03), WAX, SMOOTH, BLOCK, { ell = true })
	acc("Acc_CandleDripB", rh, V(0.06, 0.16, 0.06), CFrame.new(-0.05, -0.06, z - 0.065), WAX, SMOOTH, BLOCK, { ell = true })
	acc("Acc_CandleWick", rh, V(0.025, 0.07, 0.025), CFrame.new(0, 0.18, z), C.Ink)
	local flame = acc("Acc_CandleFlame", rh, V(0.13, 0.26, 0.13), CFrame.new(0, 0.3, z), rgb(255, 176, 80), NEON, BLOCK, { ell = true, shadow = false })
	acc("Acc_CandleFlameCore", rh, V(0.06, 0.13, 0.06), CFrame.new(0, 0.27, z), rgb(255, 240, 200), NEON, BLOCK, { ell = true, shadow = false })
	local light = Instance.new("PointLight")
	light.Range = 8
	light.Brightness = 1
	light.Shadows = false
	light.Color = rgb(255, 180, 110)
	light.Parent = flame

	-- Mourning bustle bow at the back of the waist
	bow("Acc_BustleBow", lt, CFrame.new(0, 0.1, 1.04) * CFrame.Angles(0, math.pi, 0), BLACK, 1.3)
end

-- ============================================================================ 4. FortuneGranny
local function buildFortune()
	local head, ut, lt = find("Head"), find("UpperTorso"), find("LowerTorso")
	local PLUM, PLUM_L = rgb(136, 60, 118), rgb(172, 96, 150)
	local TEAL, TEAL_L = rgb(40, 128, 126), rgb(96, 176, 164)
	local GOLD = C.Gold
	local SHINY = { refl = 0.15 }

	-- Patterned headscarf over the hair, a teal band with dangling coins, knot + tails at the back
	-- covers the hair and the ears, tied at the nape; the face stays clear
	local scarfC, scarfR = V(0, 0.3, 0.2), V(0.81, 0.7, 0.79)
	acc("Acc_Headscarf", head, scarfR * 2, CFrame.new(scarfC), PLUM, FABRIC, BLOCK, { ell = true })
	local bandC, bandR = V(0, 0.52, 0.2), V(0.84, 0.13, 0.81)
	acc("Acc_ScarfBand", head, bandR * 2, CFrame.new(bandC), TEAL, FABRIC, BLOCK, { ell = true })
	for i, a in { -76, -50, 0, 50, 76 } do
		local ar = rad(a)
		local out = V(math.sin(ar), 0, -math.cos(ar))
		local p = bandC + V(bandR.X * math.sin(ar), -0.05, -bandR.Z * math.cos(ar)) * 1.01
		acc("Acc_ScarfCoin" .. i, head, V(0.03, 0.14, 0.14), CFrame.lookAt(p + V(0, -0.08, 0), p + V(0, -0.08, 0) + out) * AXIS_Z, GOLD, SMOOTH, CYL, SHINY)
	end
	for i, d in { V(0.35, 1, 0.1), V(-0.55, 0.7, 0.55), V(0.7, 0.45, 0.6), V(-0.9, 0.3, -0.15), V(0.9, 0.25, -0.1), V(0, 0.55, 1) } do
		local p, n = ellPoint(scarfC, scarfR, d, 0.005)
		acc("Acc_ScarfDot" .. i, head, V(0.17, 0.17, 0.04), CFrame.lookAt(p, p + n), if i % 2 == 0 then TEAL_L else GOLD, SMOOTH, BLOCK, { ell = true })
	end
	acc("Acc_ScarfKnot", head, V(0.4, 0.34, 0.32), CFrame.new(0, 0.0, 0.94), PLUM_L, FABRIC, BLOCK, { ell = true })
	for _, side in { -1, 1 } do
		local s = if side < 0 then "L" else "R"
		local bot = V(0.36 * side, -0.42, 1.04)
		strip("Acc_ScarfTail" .. s, head, bot, V(0.08 * side, -0.02, 1.0), 0.26, 0.05, PLUM, FABRIC, V(0, 0, 1))
		for j, dx in { -0.09, 0, 0.09 } do
			acc("Acc_ScarfFringe" .. s .. j, head, V(0.035, 0.22, 0.035), CFrame.new(bot.X + dx, bot.Y - 0.1, bot.Z + 0.01), GOLD, SMOOTH)
		end
	end

	-- Big gold hoop earrings (8 segments each, hanging from the lobes)
	for _, side in { -1, 1 } do
		local s = if side < 0 then "L" else "R"
		local ctr = V(0.71 * side, -0.41, 0.03)
		local u = V(0, 1, 0)
		local v = V(math.sin(rad(35)) * side, 0, math.cos(rad(35)))
		local R = 0.2
		for i = 0, 7 do
			local a0, a1 = rad(i * 45), rad((i + 1) * 45)
			local p0 = ctr + (u * math.cos(a0) + v * math.sin(a0)) * R
			local p1 = ctr + (u * math.cos(a1) + v * math.sin(a1)) * R
			seg("Acc_Hoop" .. s .. (i + 1), head, p0, p1, 0.05, GOLD, SMOOTH, { cyl = true, extra = 0.035, refl = 0.15 })
		end
	end

	-- Layered fringe shawls: teal under, plum over, open front ends, a point down the back
	-- capelets wrap the shoulders and show above the chest from the front
	local lowC, lowR = V(0, 0.45, 0.12), V(1.22, 0.5, 0.78)
	local upC, upR = V(0, 0.66, 0.14), V(1.1, 0.38, 0.7)
	acc("Acc_ShawlLower", ut, lowR * 2, CFrame.new(lowC), TEAL, FABRIC, BLOCK, { ell = true })
	acc("Acc_ShawlUpper", ut, upR * 2, CFrame.new(upC), PLUM, FABRIC, BLOCK, { ell = true })
	for _, side in { -1, 1 } do
		local s = if side < 0 then "L" else "R"
		local bot = V(0.62 * side, -0.55, -0.6)
		strip("Acc_ShawlFront" .. s, ut, bot, V(0.68 * side, 0.72, -0.5), 0.4, 0.05, TEAL, FABRIC, V(0, 0, -1))
		for j, dx in { -0.13, 0, 0.13 } do
			acc("Acc_ShawlFringeF" .. s .. j, ut, V(0.04, 0.26, 0.03), CFrame.new(bot.X + dx, bot.Y - 0.13, bot.Z), GOLD, SMOOTH)
		end
	end
	acc("Acc_ShawlPoint", ut, V(0.9, 0.9, 0.06), CFrame.new(0, -0.12, 0.78) * CFrame.Angles(rad(12), 0, 0) * CFrame.Angles(0, 0, rad(45)), TEAL, FABRIC)
	for j, dx in { -0.1, 0, 0.1 } do
		acc("Acc_ShawlFringeP" .. j, ut, V(0.04, 0.26, 0.03), CFrame.new(dx, -0.86 + math.abs(dx) * 0.9, 0.66), GOLD, SMOOTH)
	end
	for i, a in { -120, -60, 0, 60, 120, 155, -155 } do
		local ar = rad(a)
		local p = ellPoint(upC, upR, V(math.sin(ar), -0.55, math.cos(ar)), -0.01)
		acc("Acc_ShawlFringeU" .. i, ut, V(0.04, 0.26, 0.04), CFrame.new(p + V(0, -0.12, 0)), TEAL_L, SMOOTH)
	end
	for i, a in { -135, -100, -65, -30, 30, 65, 100, 135 } do
		local ar = rad(a)
		local p = ellPoint(lowC, lowR, V(math.sin(ar), -0.6, math.cos(ar)), -0.01)
		acc("Acc_ShawlFringeL" .. i, ut, V(0.04, 0.28, 0.04), CFrame.new(p + V(0, -0.13, 0)), GOLD, SMOOTH)
	end

	-- Stacked bangles and rings
	local bangleColors = { GOLD, TEAL, GOLD }
	for _, side in { "Left", "Right" } do
		local s = side:sub(1, 1)
		local la = find(side .. "LowerArm")
		for i, y in { -0.26, -0.34, -0.42 } do
			acc("Acc_Bangle" .. s .. i, la, V(0.06, 0.44, 0.44), CFrame.new(0, y, 0) * CFrame.Angles(rad((i - 2) * 7), 0, rad((2 - i) * 5)) * AXIS_Y, bangleColors[i], SMOOTH, CYL, SHINY)
		end
		local out = if s == "L" then -1 else 1
		acc("Acc_Ring" .. s .. "1", find(side .. "Finger1"), V(0.05, 0.12, 0.12), CFrame.new(0, 0.02, 0) * AXIS_Y, GOLD, SMOOTH, CYL, SHINY)
		acc("Acc_Ring" .. s .. "3", find(side .. "Finger3"), V(0.05, 0.12, 0.12), CFrame.new(0, 0.02, 0) * AXIS_Y, GOLD, SMOOTH, CYL, SHINY)
		acc("Acc_RingGem" .. s, find(side .. "Finger3"), V(0.08, 0.08, 0.08), CFrame.new(0.055 * out, 0.02, 0), if s == "L" then TEAL_L else PLUM_L, NEON, BALL, { shadow = false })
	end

	-- Coin belt with a leather pouch holding a faintly glowing crystal ball (right hip)
	acc("Acc_CoinBelt", lt, V(0.16, 2.02, 2.02), CFrame.new(0, 0.24, 0.02) * AXIS_Y, PLUM_L, FABRIC, CYL)
	for i, a in { -40, -20, 0, 20 } do
		local ar = rad(a)
		local out = V(math.sin(ar), 0, -math.cos(ar))
		local pos = V(1.02 * math.sin(ar), 0.12, 0.02 - 1.02 * math.cos(ar))
		acc("Acc_BeltCoin" .. i, lt, V(0.03, 0.14, 0.14), CFrame.lookAt(pos, pos + out) * AXIS_Z, GOLD, SMOOTH, CYL, SHINY)
	end
	local pa = rad(42)
	local pout = V(math.sin(pa), 0, -math.cos(pa))
	local ppos = V(1.2 * math.sin(pa), -0.1, 0.02 - 1.2 * math.cos(pa))
	acc("Acc_BallPouch", lt, V(0.56, 0.44, 0.46), CFrame.lookAt(ppos, ppos + pout), rgb(112, 72, 50), FABRIC, BLOCK, { ell = true })
	strip("Acc_PouchStrap", lt, ppos + V(0, 0.15, 0) + pout * 0.02, V(1.01 * math.sin(pa) * 0.93, 0.24, 0.02 - 1.01 * math.cos(pa) * 0.93) + pout * 0.1, 0.07, 0.03, rgb(84, 54, 40), FABRIC, pout)
	acc("Acc_PouchRim", lt, V(0.06, 0.4, 0.4), CFrame.new(ppos + V(0, 0.19, 0)) * AXIS_Y, GOLD, SMOOTH, CYL, SHINY)
	acc("Acc_CrystalBall", lt, V(0.48, 0.48, 0.48), CFrame.new(ppos + V(0, 0.42, 0)), rgb(200, 172, 240), GLASS, BALL, { t = 0.3, shadow = false })
	local glow = acc("Acc_CrystalGlow", lt, V(0.3, 0.3, 0.3), CFrame.new(ppos + V(0, 0.42, 0)), rgb(178, 118, 236), NEON, BALL, { t = 0.35, shadow = false })
	local light = Instance.new("PointLight")
	light.Range = 5
	light.Brightness = 0.8
	light.Shadows = false
	light.Color = rgb(180, 120, 240)
	light.Parent = glow
end

-- ============================================================================ 5. NightmareGranny
local function buildNightmare()
	local PORCELAIN, PORC_SHADOW, PORC_LINE = rgb(228, 226, 220), rgb(192, 188, 186), rgb(150, 144, 146)
	local CRACK = rgb(66, 52, 62)

	-- Skeleton: deeper hunch + longer neck (height stays ~ the same), longer arms and fingers
	relayout(function(recs)
		motor("Waist").C0 = CFrame.new(0, 0.3, 0.05) * CFrame.Angles(rad(-23), 0, 0)
		motor("Neck").C0 = CFrame.new(0, 1.0, -0.28) * CFrame.Angles(rad(14), 0, 0)
		for _, side in { "Left", "Right" } do
			local sx = if side == "Left" then -1 else 1
			find(side .. "UpperArm").Size = V(0.46, 1.25, 0.46)
			find(side .. "LowerArm").Size = V(0.3, 1.38, 0.3)
			motor(side .. "Shoulder").C1 = CFrame.new(-0.125 * sx, 0.52, 0)
			motor(side .. "Elbow").C0 = CFrame.new(0, -0.55, 0)
			motor(side .. "Elbow").C1 = CFrame.new(0, 0.64, 0)
			motor(side .. "Wrist").C0 = CFrame.new(0, -0.66, 0)
			recs[side .. "Cuff"][1].off = CFrame.new(0, 0.5, 0) * AXIS_Y
			for i, z in { -0.12, 0, 0.12 } do
				local len = if i == 2 then 0.9 else 0.76
				local f = find(side .. "Finger" .. i)
				f.Size = V(0.065, len, 0.065)
				recs[f.Name][1].off = CFrame.new(0, -0.25, z) * CFrame.Angles(rad(z * 70 - 6), 0, 0) * CFrame.new(0, -len / 2 + 0.03, 0) * CFrame.Angles(0, 0, rad(-8))
			end
		end
		-- the bun has come loose: sagging to one side
		recs.HairBun[1].off = CFrame.new(0.3, 1.2, 0.34) * CFrame.Angles(rad(16), 0, rad(-26))
	end)
	kill("^HairKnob$")
	kill("^Smile%d")

	local head = find("Head")

	-- Cracked porcelain skin
	for _, d in M:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Skin") then
			d.Material = SMOOTH
			d.Reflectance = 0.05
			d.Color = if d.Name:find("CheekHollow") then PORC_SHADOW elseif d.Name:find("Wrinkle") then PORC_LINE else PORCELAIN
		end
	end
	acc("Acc_Neck", head, V(0.62, 0.42, 0.42), CFrame.new(0, -0.8, 0.1) * AXIS_Y, PORCELAIN, SMOOTH, CYL, { skin = true })

	-- Glowing eyes in dark sockets
	for _, d in M:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name:find("EyeWhite") then
				d.Color = rgb(26, 18, 24)
			elseif d.Name == "Eye" then
				d.Color = rgb(255, 96, 40)
				d.Material = NEON
				d.CastShadow = false
				local l = Instance.new("PointLight")
				l.Range = 6
				l.Brightness = 1.5
				l.Shadows = false
				l.Color = rgb(255, 96, 40)
				l.Parent = d
			end
		end
	end

	-- Extra-wide grin wrapping round the cheeks, with little pointed teeth
	local upper, lower = {}, {}
	for i = 0, 8 do
		local t = i / 8 * 2 - 1
		table.insert(upper, Vector2.new(t * 0.56, -0.44 + 0.13 * t * t))
	end
	for i = 0, 6 do
		local t = i / 6 * 2 - 1
		table.insert(lower, Vector2.new(t * 0.4, -0.44 - 0.1 * (1 - t * t) + 0.064 * t * t))
	end
	acc("Acc_GrinMouth", head, V(0.74, 0.11, 0.04), onHead(0, -0.49, -0.005), rgb(40, 20, 28), SMOOTH, BLOCK, { ell = true })
	faceLine("Acc_GrinTop", head, upper, 0.045, C.Ink)
	faceLine("Acc_GrinLow", head, lower, 0.04, C.Ink)
	for i, x in { -0.24, -0.12, 0, 0.12, 0.24 } do
		local t = x / 0.56
		local y = -0.44 + 0.13 * t * t - 0.035
		acc("Acc_GrinTooth" .. i, head, V(0.06, 0.06, 0.03), onHead(x, y, 0.01) * CFrame.Angles(0, 0, rad(45)), C.Paper, SMOOTH)
	end

	-- Cracks: face, lens, forearms, neck
	faceLine("Acc_CrackBrow", head, { Vector2.new(0.0, 0.43), Vector2.new(-0.04, 0.34), Vector2.new(0.02, 0.24) }, 0.028, CRACK, 0.008)
	faceLine("Acc_CrackChin", head, { Vector2.new(0.14, -0.57), Vector2.new(0.06, -0.63), Vector2.new(0.11, -0.7) }, 0.028, CRACK, 0.008)
	faceLine("Acc_CrackJaw", head, { Vector2.new(0.5, -0.37), Vector2.new(0.55, -0.46), Vector2.new(0.49, -0.55), Vector2.new(0.53, -0.62) }, 0.028, CRACK, 0.008)
	faceLine("Acc_CrackTemple", head, { Vector2.new(-0.5, 0.36), Vector2.new(-0.57, 0.22), Vector2.new(-0.53, 0.08) }, 0.028, CRACK, 0.008)
	local LENS_Z = -0.875
	seg("Acc_LensCrackA", head, V(0.28, 0.27, LENS_Z), V(0.42, 0.08, LENS_Z), 0.018, rgb(236, 240, 236), SMOOTH)
	seg("Acc_LensCrackB", head, V(0.42, 0.08, LENS_Z), V(0.35, -0.1, LENS_Z), 0.018, rgb(236, 240, 236), SMOOTH)
	seg("Acc_LensCrackC", head, V(0.42, 0.08, LENS_Z), V(0.6, 0.13, LENS_Z), 0.018, rgb(236, 240, 236), SMOOTH)
	for _, side in { "Left", "Right" } do
		local la = find(side .. "LowerArm")
		local pts = { V(0.03, 0.42, -0.155), V(-0.05, 0.16, -0.155), V(0.04, -0.1, -0.155), V(-0.02, -0.36, -0.155) }
		for i = 1, 3 do
			seg("Acc_CrackArm" .. side:sub(1, 1) .. i, la, pts[i], pts[i + 1], 0.035, CRACK, SMOOTH, { extra = 0.02 })
		end
		for i = 1, 3 do
			local f = find(side .. "Finger" .. i)
			acc("Acc_Nail" .. side:sub(1, 1) .. i, f, V(0.08, 0.13, 0.08), CFrame.new(0, -f.Size.Y / 2, 0), rgb(70, 60, 64), SMOOTH, BLOCK, { ell = true })
		end
	end
	seg("Acc_CrackNeckA", head, V(-0.12, -0.62, -0.215), V(-0.05, -0.8, -0.215), 0.03, CRACK, SMOOTH)
	seg("Acc_CrackNeckB", head, V(-0.05, -0.8, -0.215), V(-0.13, -0.95, -0.215), 0.03, CRACK, SMOOTH)

	-- Loose hair: a sagging loop off the bun and stray strands
	acc("Acc_BunLoop", head, V(0.34, 0.95, 0.3), CFrame.new(0.72, 0.55, 0.42) * CFrame.Angles(0, 0, rad(-20)), C.Hair, FABRIC, BLOCK, { ell = true })
	local capC, capR = V(0, 0.5, 0.2), V(0.71, 0.5, 0.69)
	local strands = {
		{ V(-1, -0.2, -0.3), V(-0.12, -0.75, -0.05) },
		{ V(-0.8, -0.3, 0.6), V(-0.1, -0.8, 0.1) },
		{ V(0.2, -0.3, 1), V(0.05, -0.7, 0.15) },
		{ V(-0.3, -0.2, 1), V(-0.05, -0.85, 0.1) },
		{ V(0.95, -0.2, -0.2), V(0.12, -0.6, -0.1) },
		{ V(-0.5, 0.1, -1), V(-0.1, -0.55, -0.15) },
	}
	for i, s in strands do
		local p = ellPoint(capC, capR, s[1], -0.03)
		seg("Acc_HairStrand" .. i, head, p, p + s[2], 0.06, if i % 2 == 0 then C.HairDark else C.Hair, FABRIC, { cyl = true })
	end
end

-- ============================================================================ build + checks
local RIGS = {
	{ name = "GardenGranny", display = "Nana Thorn", maps = "BackGarden", build = buildGarden },
	{ name = "MatronGranny", display = "Matron Gladys", maps = "SunnyPines", build = buildMatron },
	{ name = "WidowGranny", display = "Widow Wren", maps = "StMildreds", build = buildWidow },
	{ name = "FortuneGranny", display = "Madame Nana", maps = "HarvestFair", build = buildFortune },
	{ name = "NightmareGranny", display = "Grandma?", maps = "NightmareHouse", minNight = 26, build = buildNightmare },
}

local outfitParts = {}
do
	local cfgModule = ReplicatedStorage:FindFirstChild("Config") and ReplicatedStorage.Config:FindFirstChild("GrandmaConfig")
	local ok, cfg = pcall(function()
		return (loadstring :: any)((cfgModule :: ModuleScript).Source)()
	end)
	outfitParts = if ok and cfg and cfg.OutfitParts then cfg.OutfitParts else {}
end

local templateMotors = {}
for _, d in template:GetDescendants() do
	if d:IsA("Motor6D") then
		templateMotors[d.Name] = true
	end
end
local templateHeight = template:GetExtentsSize().Y

local function check(m: Model): string
	local issues = {}
	local note = ""
	local parts, eyes, lowest = 0, 0, math.huge
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
			if d.Name == "Eye" then
				eyes += 1
			end
			local cf, s = d.CFrame, d.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						lowest = math.min(lowest, (cf * V(sx * s.X, sy * s.Y, sz * s.Z)).Y)
					end
				end
			end
			if d.Name:sub(1, 4) == "Acc_" then
				for slot, pats in outfitParts do
					for _, pat in pats do
						if d.Name:find(pat) then
							table.insert(issues, `{d.Name} matches OutfitParts.{slot}`)
						end
					end
				end
				if d.Anchored or d.CanCollide or d.CanQuery or d.CanTouch or not d.Massless then
					table.insert(issues, `{d.Name} bad physics flags`)
				end
				if not d:FindFirstChildOfClass("WeldConstraint") then
					table.insert(issues, `{d.Name} not welded`)
				end
			end
		end
	end
	local hum = m:FindFirstChildOfClass("Humanoid")
	local hrp = m:FindFirstChild("HumanoidRootPart")
	if not hum then table.insert(issues, "no Humanoid") end
	if not hrp or m.PrimaryPart ~= hrp then table.insert(issues, "PrimaryPart is not HumanoidRootPart") end
	if not m:FindFirstChild("Head") then table.insert(issues, "no Head") end
	if eyes < 1 then table.insert(issues, "no Eye") end
	local motors = {}
	for _, d in m:GetDescendants() do
		if d:IsA("Motor6D") then
			motors[d.Name] = true
		end
	end
	for n in templateMotors do
		if not motors[n] then table.insert(issues, `missing motor {n}`) end
	end
	for n in motors do
		if not templateMotors[n] then table.insert(issues, `extra motor {n}`) end
	end
	if parts > 180 then table.insert(issues, `{parts} parts > 180`) end
	-- walking frame footprint: <= 3.2 studs wide, never below her feet
	if hrp then
		local minX, maxX, minY = math.huge, -math.huge, math.huge
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") and d.Name:find("^Acc_Walker") then
				local cf, s = d.CFrame, d.Size / 2
				for _, sx in { -1, 1 } do
					for _, sy in { -1, 1 } do
						for _, sz in { -1, 1 } do
							local w = cf * V(sx * s.X, sy * s.Y, sz * s.Z)
							local l = (hrp :: BasePart).CFrame:PointToObjectSpace(w)
							minX, maxX, minY = math.min(minX, l.X), math.max(maxX, l.X), math.min(minY, w.Y)
						end
					end
				end
			end
		end
		if maxX > minX then
			local foot = m:FindFirstChild("LeftFoot") :: BasePart
			local feetY = foot.Position.Y - foot.Size.Y / 2
			if maxX - minX > 3.2 then table.insert(issues, string.format("walker %.2f wide", maxX - minX)) end
			if minY < feetY - 0.001 then table.insert(issues, "walker below feet") end
			note = string.format(", walker %.2f wide, bottom %+.3f vs feet", maxX - minX, minY - feetY)
		end
	end
	local height = m:GetExtentsSize().Y
	if math.abs(height - templateHeight) > 0.3 then table.insert(issues, "height off by > 0.3") end
	return string.format("%s: %d parts, height %.2f (Temp %.2f), lowest %.3f, eyes %d%s, %s", m.Name, parts, height, templateHeight, lowest, eyes, note,
		if #issues == 0 then "OK" else table.concat(issues, "; "))
end

local report = {}
for _, r in RIGS do
	if ONLY == nil or (ONLY :: any)[r.name] then
		local old = folder:FindFirstChild(r.name)
		if old then
			old:Destroy()
		end
		M = template:Clone()
		M.Name = r.name
		r.build()
		M:SetAttribute("DisplayName", r.display)
		M:SetAttribute("Maps", r.maps)
		M:SetAttribute("Weight", 1)
		M:SetAttribute("MinNight", r.minNight)
		M.PrimaryPart = M:FindFirstChild("HumanoidRootPart") :: BasePart
		M.Parent = folder
		table.insert(report, check(M))
	end
end

local slots = 0
for _ in outfitParts do
	slots += 1
end
table.insert(report, 1, `OutfitParts slots checked against Acc_ names: {slots}` .. (if slots == 0 then " (WARNING: GrandmaConfig not loaded)" else ""))
return table.concat(report, "\n")
