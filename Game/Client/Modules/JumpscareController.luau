--!strict
-- JumpscareController (Match)
-- Remote Caught(formKey, lostValue, lostCount, canRevive, freeRevive, cause):
--   ClientBus "JumpscareStarted"(formKey, variantKey) -> ~1.2-1.8 s scare -> black -> "JumpscareFinished"().
-- Two config layers, both in GrandmaConfig:
--   Forms[formKey].Jumpscare   sound, flash colour, line, base Shake / FOV / Distortion, animation slot
--   JumpscareVariants          HOW she gets you (Motion + Stage), picked per catch: weighted over
--                              the variants allowed at tonight's Night (MinNight/MaxNight; Weight lerps
--                              to WeightLate by Night 30). Night 31 uses only Halloween = true variants.
--   JumpscareIntensity         per-night scaling (shake, FOV punch, distortion, duration, volume,
--                              pitch); nights <= ComedicUntil get a bouncy line and a warm grade.
-- Motions (choreography, below in MOTIONS): Lunge · Grab · BehindYou · Drop · Peek · Scream · Rise,
-- plus map-themed ones (variant Maps = { MapId }): Curtain · Rush · Beside · Pop · Crooked.
-- Sound: each variant's Sound table = timed cues (Pre build-up, Hit replacing the Form sting when
-- its AssetConfig Id is set, Extra layer, JumpscareScream) with night-scaled pitch, distortion,
-- pitch-shift and optional reverb; all in the SFXDry group so Settings.SFX applies.
-- Stages: "Void" = a dark local stage far above the map; "World" = right where the camera is
-- (falls back to Void when a wall is in the way).
-- The scare uses a LOCAL clone of workspace.Grandma posed by the same RigAnimator as the live
-- Grandma (real animation if the slot Id ~= 0, else procedural), so a replacement rig or
-- animation needs no code changes. cause == "Fell" skips the scare.
-- Settings.ReduceFlashes: no bright flashes, dimmer reveals, softer shake/distortion.
-- Studio only: workspace attribute DebugJumpscare = "<VariantKey>" forces a variant;
-- DebugJumpscareSlow = N plays it N times slower.
-- Remote TeammateCaught(name): distant muffled scream + brief red edge flash.
--
--   JumpscareController:IsActive() -> boolean
--   JumpscareController:GetLastCaught() -> { Form, Variant, LostValue, LostCount, CanRevive, FreeRevive, Cause }?
--   JumpscareController:PickVariant(night) -> (key, def)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlaceRole = shared("PlaceRole")
local ClientBus = shared("ClientBus")
local GrandmaConfig = shared("GrandmaConfig")
local AssetConfig = shared("AssetConfig")
local Sfx = shared("Sfx")
local ScreenFx = shared("ScreenFx")

local JumpscareController = {}

local player = Players.LocalPlayer
local C = ScreenFx.Colors

local STAGE = CFrame.new(0, 4200, 0)
local BASE_FOV = 70

local active = false
local lastCaught: { [string]: any }? = nil
local gui: ScreenGui? = nil
local black: Frame? = nil
local flash: Frame? = nil
local lineLabel: TextLabel? = nil

local settings: any = nil
local camCtl: any = nil
local music: any = nil
local effects: any = nil

local function ease(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function expoOut(x: number): number
	x = math.clamp(x, 0, 1)
	return if x >= 1 then 1 else 1 - 2 ^ (-10 * x)
end

local function backOut(x: number): number
	x = math.clamp(x, 0, 1)
	local c1, c3 = 1.70158, 2.70158
	return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function range(pair: any, k: number, default: number): number
	if typeof(pair) ~= "table" then
		return default
	end
	return lerp(pair[1] or default, pair[2] or pair[1] or default, k)
end

function JumpscareController:IsActive(): boolean
	return active
end

function JumpscareController:GetLastCaught(): { [string]: any }?
	return lastCaught
end

-- ------------------------------------------------------------------ variant selection

local function currentNight(): number
	local ms = ReplicatedStorage:FindFirstChild("MatchState")
	local n = ms and ms:GetAttribute("Night")
	return if typeof(n) == "number" then n else 1
end

function JumpscareController:PickVariant(night: number): (string, { [string]: any })
	local variants = GrandmaConfig.JumpscareVariants or {}
	if RunService:IsStudio() then
		local forced = workspace:GetAttribute("DebugJumpscare")
		if typeof(forced) == "string" and variants[forced] then
			return forced, variants[forced]
		end
	end
	local halloween = night >= 31
	local ms = ReplicatedStorage:FindFirstChild("MatchState")
	local mapId = ms and ms:GetAttribute("MapId")
	local k = math.clamp((night - 1) / 29, 0, 1)
	local pool: { { key: string, w: number } } = {}
	local total = 0
	for key, v in variants do
		local ok
		if halloween then
			ok = v.Halloween == true
		else
			ok = v.Halloween ~= true and night >= (v.MinNight or 1) and night <= (v.MaxNight or 30)
			-- Map-themed scares (Maps = { MapId, ... }) only happen on their own maps.
			if ok and v.Maps then
				ok = typeof(mapId) == "string" and table.find(v.Maps, mapId) ~= nil
			end
		end
		if ok then
			local w = lerp(v.Weight or 1, v.WeightLate or v.Weight or 1, k)
			if w > 0 then
				table.insert(pool, { key = key, w = w })
				total += w
			end
		end
	end
	if #pool == 0 then
		-- Halloween with no special variant configured: any late variant will do.
		if halloween then
			return JumpscareController:PickVariant(30)
		end
		return "Lunge", variants.Lunge or { Motion = "Lunge", Stage = "Void", Duration = 1.35 }
	end
	table.sort(pool, function(a, b)
		return a.key < b.key
	end)
	local r = math.random() * total
	for _, p in pool do
		r -= p.w
		if r <= 0 then
			return p.key, variants[p.key]
		end
	end
	local last = pool[#pool]
	return last.key, variants[last.key]
end

-- ------------------------------------------------------------------ building

local function buildGui()
	local g = ScreenFx.Gui("JumpscareFx", 1000)
	gui = g
	flash = ScreenFx.Fill(g, Color3.new(1, 1, 1), 2)
	black = ScreenFx.Fill(g, Color3.new(0, 0, 0), 3)
	local l = Instance.new("TextLabel")
	l.Name = "Line"
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, 0.78)
	l.Size = UDim2.fromScale(0.9, 0.14)
	l.FontFace = Font.fromEnum(Enum.Font.LuckiestGuy)
	l.TextColor3 = C.Paper
	l.TextScaled = true
	l.Text = ""
	l.Visible = false
	l.ZIndex = 4
	local s = Instance.new("UIStroke")
	s.Color = C.Blood
	s.Thickness = 4
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = l
	local sc = Instance.new("UIScale")
	sc.Parent = l
	l.Parent = g
	lineLabel = l
end

local function fadeBlack(to: number, time: number)
	local b = black
	if not b then
		return
	end
	b.Visible = true
	local tw = TweenService:Create(b, TweenInfo.new(time, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 - to })
	tw:Play()
	if to <= 0 then
		tw.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed then
				b.Visible = false
			end
		end)
	end
end

local function liveGrandma(): Model?
	local g = CollectionService:GetTagged("Grandma")[1] or workspace:FindFirstChild("Grandma")
	return if g and g:IsA("Model") then g else nil
end

local function cloneGrandma(): Model?
	local g = liveGrandma()
	if not g then
		return nil
	end
	local wasArchivable = g.Archivable
	g.Archivable = true
	local ok, clone = pcall(g.Clone, g)
	g.Archivable = wasArchivable
	if not ok or not clone then
		return nil
	end
	local m = clone :: Model
	m.Name = "JumpscareGrandma"
	for _, tag in CollectionService:GetTags(m) do
		CollectionService:RemoveTag(m, tag)
	end
	local root = m:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or not m:FindFirstChild("Head") then
		m:Destroy()
		return nil
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Anchored = d == root
			d.CastShadow = false
			d.LocalTransparencyModifier = 0
		elseif d:IsA("Motor6D") then
			-- back to the rest pose, so the head offset is measured standing (she may be seated)
			d.Transform = CFrame.identity
		elseif d:IsA("Sound") or d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("ProximityPrompt") then
			d:Destroy()
		end
	end
	local hum = m:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.EvaluateStateMachine = false
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	m.PrimaryPart = root
	return m
end

local function setLiveGrandmaHidden(hidden: boolean)
	local g = liveGrandma()
	if not g then
		return
	end
	for _, d in g:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			(d :: any).LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

local function playScareSound(key: string?, overrides: { [string]: any }?): Sound?
	if not key or key == "" then
		return nil
	end
	local s = Sfx.Play(key, nil, overrides)
	local dry = music and music:GetGroup("SFXDry")
	if s and dry then
		s.SoundGroup = dry
	end
	return s
end

local function stagePart(parent: Instance, cf: CFrame, size: Vector3, color: Color3)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Size = size
	p.CFrame = cf
	p.Parent = parent
end

-- Clearance from the camera along a direction (ignores characters, Grandma, see-through parts).
local function clearance(origin: Vector3, dir: Vector3, stage: Instance): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude: { Instance } = { stage }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(exclude, p.Character)
		end
	end
	local g = liveGrandma()
	if g then
		table.insert(exclude, g)
	end
	for _ = 1, 6 do
		params.FilterDescendantsInstances = exclude
		local r = workspace:Raycast(origin, dir, params)
		if not r then
			return dir.Magnitude
		end
		if r.Instance.Transparency >= 0.5 then
			table.insert(exclude, r.Instance)
		else
			return (r.Position - origin).Magnitude
		end
	end
	return dir.Magnitude
end

-- ------------------------------------------------------------------ motions
-- Each motion: Impact (s, when the hit lands: flash / distortion / line), StingAt, ScreamAt,
-- Need (World stage only: { Dir = "Back"|"Front", Min = studs }), and
-- Update(t, m, out) filling out = { Cam: CFrame, Head: Vector3?, Rot: CFrame, Fov: 0..1 (how
-- much of the FOV punch is applied), Black: 0..1, Light: 0..1, Blur: extra blur 0..1 }.
-- m = { D, O (origin CFrame, level), Front(dist, y), Face (rotation facing the camera),
--       Back (studs available behind), Sign (+-1 random side), Calm }

type Out = { Cam: CFrame, Head: Vector3?, Rot: CFrame, Fov: number, Black: number, Light: number, Blur: number }

local MOTIONS: { [string]: { Impact: number, StingAt: number, ScreamAt: number, Need: { Dir: string, Min: number }?, Setup: ((any, Instance, any) -> ())?, Update: (number, any, Out) -> () } } = {}

-- She lunges at the camera out of the dark (the classic).
MOTIONS.Lunge = {
	Impact = 0.3,
	StingAt = 0,
	ScreamAt = 0,
	Update = function(t, m, out)
		local START, END = 4.2, 1.3
		local dist
		if t < 0.08 then
			dist = START
		elseif t < 0.36 then
			dist = START + (END - START) * expoOut((t - 0.08) / 0.28)
		else
			dist = END - 0.35 * ease((t - (m.D - 0.35)) / 0.25)
		end
		out.Cam = m.O
		out.Head = m.Front(dist, 0.12)
		out.Rot = m.Face
		out.Fov = ease((t - 0.06) / 0.25)
	end,
}

-- She grabs you: the camera is yanked in toward her and twisted.
MOTIONS.Grab = {
	Impact = 0.3,
	StingAt = 0,
	ScreamAt = 0.1,
	Update = function(t, m, out)
		local reach = expoOut((t - 0.08) / 0.25)
		out.Head = m.Front(2.9 - 0.3 * reach, 0.05)
		out.Rot = m.Face
		local y = expoOut((t - 0.14) / 0.2)
		local drag = ease((t - 0.4) / (m.D - 0.4))
		out.Cam = m.O
			* CFrame.new(0, -0.1 * y, -(0.9 * y + 0.15 * drag) * m.S)
			* CFrame.Angles(math.rad(3 * y), math.rad(3 * y * m.Sign), math.rad(13 * y * m.Sign))
		out.Fov = y
		out.Blur = math.exp(-((t - 0.24) / 0.08) ^ 2)
	end,
}

-- Quiet... a breath behind you... the camera whips round 180 degrees: she's right there.
MOTIONS.BehindYou = {
	Impact = 0.62,
	StingAt = 0.46,
	ScreamAt = 0.58,
	Need = { Dir = "Back", Min = 1.25 },
	Update = function(t, m, out)
		local d = math.min(1.8 * m.S, m.Back)
		local w = if t < 0.42 then 0 else ease((t - 0.42) / 0.18)
		local over = math.sin(math.clamp((t - 0.6) / 0.25, 0, 1) * math.pi) * 0.06 * m.Sign
		local creep = ease(t / 0.42)
		out.Cam = m.O * CFrame.Angles(math.rad(-2 * creep), math.pi * w * m.Sign + over, 0)
		local lunge = expoOut((t - 0.6) / 0.16)
		out.Head = (m.O * CFrame.new(0, 0.05, math.max(0.9 * m.S, d - 0.55 * m.S * lunge))).Position
		out.Rot = m.O.Rotation
		out.Fov = if t < 0.42 then 0.15 * creep else ease((t - 0.56) / 0.2)
		out.Blur = if t > 0.42 and t < 0.62 then math.sin((t - 0.42) / 0.2 * math.pi) else 0
		out.Light = if t < 0.5 then 0 else 1
	end,
}

-- A creak above... she drops from the ceiling, upside down, face to face.
MOTIONS.Drop = {
	Impact = 0.34,
	StingAt = 0.2,
	ScreamAt = 0.28,
	Need = { Dir = "Front", Min = 1.6 },
	Update = function(t, m, out)
		local f = expoOut((t - 0.2) / 0.14)
		local swing = if t > 0.34 then math.sin((t - 0.34) * 9) * 0.16 * math.exp(-(t - 0.34) * 2.5) else 0
		local y = 4.6 - 4.5 * f
		-- upright fall from above the frame; lands with a squashy bounce and a sway
		local bounce = if t > 0.34 then math.sin((t - 0.34) * 14) * 0.12 * math.exp(-(t - 0.34) * 6) else 0
		out.Head = (m.O * CFrame.new(swing, (y - bounce) * m.S, -m.S * (1.9 - 0.25 * ease((t - 0.5) / 0.6)))).Position
		out.Rot = m.Face * CFrame.Angles(0, 0, swing * 0.8)
		local lookUp = if t < 0.2 then ease(t / 0.2) * 7 else 7 * (1 - expoOut((t - 0.2) / 0.12))
		out.Cam = m.O * CFrame.Angles(math.rad(lookUp), 0, 0)
		out.Fov = f
	end,
}

-- The lights cut. Black. One flash: her face, inches away. Black. Then she's there.
MOTIONS.Peek = {
	Impact = 0.8,
	StingAt = 0.45,
	ScreamAt = 0.76,
	Need = { Dir = "Front", Min = 1.2 },
	Update = function(t, m, out)
		out.Cam = m.O * CFrame.Angles(math.rad(math.sin(t * 2.2) * 0.6), 0, 0)
		local second = t >= 0.78
		out.Head = m.Front(if second then 0.78 - 0.12 * ease((t - 0.78) / 0.3) else 0.98, 0.04)
		out.Rot = m.Face
		if t < 0.12 then
			out.Black = ease(t / 0.12)
			out.Light = 0
		elseif t < 0.45 then
			out.Black = 1
			out.Light = 0
		elseif t < 0.58 then
			out.Black = 0
			out.Light = if m.Calm then 0.6 else 1.4
		elseif t < 0.78 then
			out.Black = 1
			out.Light = 0
		else
			out.Black = 0
			out.Light = 0.8 + 0.4 * math.abs(math.sin(t * 31))
		end
		out.Fov = if second then ease((t - 0.78) / 0.12) else 0.5
	end,
}

-- Her face fills the screen, screaming, and everything shakes.
MOTIONS.Scream = {
	Impact = 0.06,
	StingAt = 0,
	ScreamAt = 0,
	Update = function(t, m, out)
		out.Head = m.Front(0.95 - 0.2 * ease(t / 0.35), -0.02)
		out.Rot = m.Face
		local roll = math.sin(t * 19) * 5 * (1 - ease((t - m.D + 0.4) / 0.4))
		out.Cam = m.O * CFrame.Angles(0, 0, math.rad(roll))
		out.Fov = expoOut(t / 0.14)
	end,
}

-- Halloween: orange flicker in the dark, she RISES into frame, grinning, then lunges.
MOTIONS.Rise = {
	Impact = 0.64,
	StingAt = 0.44,
	ScreamAt = 0.6,
	Update = function(t, m, out)
		local r = backOut((t - 0.42) / 0.2)
		local lunge = expoOut((t - 0.64) / 0.18)
		out.Head = m.Front(1.7 - 0.6 * lunge, -3.4 + 3.45 * r)
		out.Rot = m.Face
		out.Cam = m.O * CFrame.Angles(math.rad(-3 * (1 - r)), 0, 0)
		out.Light = 0.35 + 0.35 * math.abs(math.noise(t * 9, 2.2)) + 0.6 * ease((t - 0.42) / 0.2)
		out.Black = if t < 0.1 then 1 - t / 0.1 else 0
		out.Fov = ease((t - 0.6) / 0.2)
	end,
}

-- ---------------------------------------------------------- map-themed motions
-- These build their own little props in Setup(m, stage, variant) (stored in m.P) and move
-- them in Update. They always run on the Void stage.

local function prop(stage: Instance, size: Vector3, color: Color3, material: Enum.Material?): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = stage
	return p
end

local function elasticOut(x: number): number
	x = math.clamp(x, 0, 1)
	if x <= 0 or x >= 1 then
		return x
	end
	return 2 ^ (-10 * x) * math.sin((x * 10 - 0.75) * (2 * math.pi) / 3) + 1
end

-- Garden washing line / care-home privacy curtain: a sheet sways in front of you... it whips
-- aside and she's right behind it.
MOTIONS.Curtain = {
	Impact = 0.62,
	StingAt = 0.5,
	ScreamAt = 0.58,
	Setup = function(m, stage, variant)
		local sheet = prop(stage, Vector3.new(5.5, 7.5, 0.08) * m.S, variant.PropColor or Color3.fromRGB(236, 230, 214), Enum.Material.Fabric)
		m.P = { Sheet = sheet }
	end,
	Update = function(t, m, out)
		local whip = expoOut((t - 0.5) / 0.14)
		local sway = math.sin(t * 5.5) * 0.06 * (1 - whip)
		local sheet = m.P and m.P.Sheet
		if sheet then
			sheet.CFrame = m.O
				* CFrame.new(whip * 5.2 * m.Sign * m.S + sway, 0.4 * m.S, -1.35 * m.S)
				* CFrame.Angles(0, math.rad(75) * whip * m.Sign, math.sin(t * 3.2) * 0.03)
		end
		local lunge = expoOut((t - 0.56) / 0.16)
		out.Head = m.Front(2.7 - 1.5 * lunge, 0.08)
		out.Rot = m.Face
		out.Cam = m.O * CFrame.Angles(math.rad(-1.5 * ease(t / 0.5)), 0, 0)
		out.Light = if t < 0.5 then 0.45 else 1
		out.Fov = ease((t - 0.54) / 0.2)
	end,
}

-- Sunny Pines: the fluorescent tube strobes; every flash she's closer (wheelchair-fast).
MOTIONS.Rush = {
	Impact = 0.72,
	StingAt = 0.68,
	ScreamAt = 0.68,
	Update = function(t, m, out)
		local p = math.clamp((t - 0.12) / 0.58, 0, 1)
		local stepped = math.floor(p * 6) / 6
		local dist = if t < 0.7 then 9 - 7.4 * stepped ^ 1.3 else 1.6 - 0.45 * expoOut((t - 0.7) / 0.14)
		out.Head = m.Front(dist, 0.06)
		out.Rot = m.Face
		out.Cam = m.O
		local on = math.floor(t * 13) % 2 == 0
		out.Light = if t >= 0.7 then 1 elseif on then (if m.Calm then 0.5 else 1) else 0.04
		out.Fov = if t < 0.7 then 0.12 * p else expoOut((t - 0.7) / 0.12)
	end,
}

-- St. Mildred's: a bell tolls in candle-dark... you turn to the side: she's standing right
-- beside you.
MOTIONS.Beside = {
	Impact = 0.68,
	StingAt = 0.52,
	ScreamAt = 0.62,
	Update = function(t, m, out)
		local turn = ease((t - 0.46) / 0.16)
		local drift = math.sin(t * 1.7) * 0.02
		out.Cam = m.O * CFrame.Angles(0, (math.pi / 2) * turn * m.Sign + drift, 0)
		local side = m.O * CFrame.Angles(0, (math.pi / 2) * m.Sign, 0)
		local lunge = expoOut((t - 0.64) / 0.16)
		out.Head = (side * CFrame.new(0, 0.05 * m.S, -(1.7 - 0.6 * lunge) * m.S)).Position
		out.Rot = side.Rotation * CFrame.Angles(0, math.pi, 0)
		out.Light = if t < 0.5 then 0.3 + 0.08 * math.noise(t * 6, 1.7) else 0.95
		out.Fov = ease((t - 0.6) / 0.2)
		out.Blur = if t > 0.46 and t < 0.64 then math.sin((t - 0.46) / 0.18 * math.pi) * 0.6 else 0
	end,
}

-- Harvest Fair: a jack-in-the-box plays its tune... POP. She springs out on a wobbly spring.
MOTIONS.Pop = {
	Impact = 0.5,
	StingAt = 0.46,
	ScreamAt = 0.5,
	Setup = function(m, stage, variant)
		local c = variant.PropColor or Color3.fromRGB(196, 40, 52)
		local box = prop(stage, Vector3.new(2.6, 2.6, 2.6) * m.S, c)
		local lid = prop(stage, Vector3.new(2.8, 0.25, 2.8) * m.S, Color3.fromRGB(224, 176, 79))
		local stripe = prop(stage, Vector3.new(2.66, 0.5, 2.66) * m.S, Color3.fromRGB(243, 233, 210))
		m.P = { Box = box, Lid = lid, Stripe = stripe }
	end,
	Update = function(t, m, out)
		local base = m.O * CFrame.new(0, -2.5 * m.S, -2.6 * m.S)
		local P = m.P
		if P then
			P.Box.CFrame = base
			P.Stripe.CFrame = base
			local fly = expoOut((t - 0.46) / 0.3)
			P.Lid.CFrame = base * CFrame.new(1.6 * fly * m.Sign * m.S, (1.42 + 3.2 * fly) * m.S, -0.8 * fly * m.S) * CFrame.Angles(math.rad(-120 * fly), 0, math.rad(40 * fly * m.Sign))
		end
		local spring = elasticOut((t - 0.46) / 0.42)
		local lunge = expoOut((t - 0.9) / 0.16)
		out.Head = m.Front(2.5 - 1.2 * lunge, -3.6 + 3.7 * spring)
		out.Rot = m.Face * CFrame.Angles(0, 0, math.sin(t * 17) * 0.12 * (1 - ease((t - 0.8) / 0.3)))
		out.Cam = m.O * CFrame.Angles(math.rad(-14 * (1 - ease((t - 0.44) / 0.2))), 0, 0)
		out.Fov = math.max(0.35 * ease((t - 0.46) / 0.1), ease((t - 0.9) / 0.16))
	end,
}

-- The Nightmare House: she stands there with her head bent sideways, much too far... it
-- snaps straight with a crack and she comes at you.
MOTIONS.Crooked = {
	Impact = 0.7,
	StingAt = 0.62,
	ScreamAt = 0.66,
	Update = function(t, m, out)
		local snap = backOut((t - 0.54) / 0.1)
		local tilt = math.rad(84) * m.Sign * (1 - snap)
		local twitch = if t < 0.54 then math.sin(t * 40) * 0.015 * math.max(0, math.noise(t * 5, 3.1)) else 0
		local lunge = expoOut((t - 0.66) / 0.16)
		out.Head = m.Front(3.1 - 2.0 * lunge, 0.12)
		out.Rot = m.Face * CFrame.Angles(0, 0, tilt + twitch)
		out.Cam = m.O * CFrame.Angles(math.rad(-1 * ease(t / 0.5)), 0, 0)
		out.Light = if t < 0.54 then 0.35 + 0.35 * math.max(0, math.noise(t * 7, 8.3)) else 1
		out.Fov = if t < 0.54 then 0.1 else ease((t - 0.62) / 0.16)
	end,
}

-- ------------------------------------------------------------------ the scare

local function finish(_formKey: string)
	ClientBus.Fire("JumpscareFinished")
	task.delay(0.35, function()
		fadeBlack(0, 0.6)
	end)
	active = false
end

local function runScare(formKey: string, cause: string)
	active = true
	local night = currentNight()
	local variantKey, variant = JumpscareController:PickVariant(night)
	if lastCaught then
		lastCaught.Variant = variantKey
	end
	ClientBus.Fire("JumpscareStarted", formKey, variantKey)
	local form = GrandmaConfig.Forms[formKey] or GrandmaConfig.Forms.Normal
	local js = form.Jumpscare or {}
	local I = GrandmaConfig.JumpscareIntensity or {}
	local k = math.clamp((night - 1) / 29, 0, 1)
	local comedic = night <= (I.ComedicUntil or 5)
	local motion = MOTIONS[variant.Motion or "Lunge"] or MOTIONS.Lunge

	if cause == "Fell" then
		fadeBlack(1, 0.35)
		task.wait(0.45)
		finish(formKey)
		return
	end

	local calm = settings and settings:Get("ReduceFlashes") == true
	local D: number = math.clamp((variant.Duration or js.Duration or 1.4) + range(I.Duration, k, 0), 1.2, 1.8)
	local shakeAmt = (js.Shake or 1) * (variant.Shake or 1) * range(I.Shake, k, 1) * (if calm then 0.4 else 1)
	local distortion = math.min(1.1, (js.Distortion or 0.5) * (variant.Distortion or 1) * range(I.Distortion, k, 1)) * (if calm then 0.4 else 1)
	local flashColor: Color3 = js.Flash or Color3.new(1, 1, 1)
	if calm then
		flashColor = flashColor:Lerp(Color3.new(0, 0, 0), 0.55)
	end
	local fovDelta = ((js.FOV or 55) - BASE_FOV) * (variant.FOV or 1) * range(I.FOV, k, 1)
	local targetFov = math.clamp(BASE_FOV + fovDelta, 28, BASE_FOV)
	local volume = range(I.Volume, k, 1)
	local pitch = range(I.Pitch, k, 1)

	local cam = workspace.CurrentCamera
	-- where the player was looking (level), for World-stage variants
	local camCF = cam.CFrame
	local flatLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
	if flatLook.Magnitude < 0.05 then
		flatLook = Vector3.new(0, 0, -1)
	end
	local worldOrigin = CFrame.lookAt(camCF.Position, camCF.Position + flatLook.Unit)

	camCtl:SetFlag("Jumpscare", true)
	if music then
		music:SetMuffle("Jumpscare", 0.8)
	end
	local savedFov = cam.FieldOfView
	cam.CameraType = Enum.CameraType.Scriptable

	-- Stage (all local instances)
	local stage = Instance.new("Folder")
	stage.Name = "JumpscareStage"
	stage.Parent = workspace

	-- Big forms (Nightmare / Halloween rigs are scaled up) need proportionally more room.
	local live = liveGrandma()
	local S = math.clamp(if live then live:GetScale() else 1, 0.5, 2)
	local origin = STAGE
	local back = 1.8 * S
	local worldStage = false
	if variant.Stage == "World" and motion.Need then
		local need = motion.Need
		local dir = if need.Dir == "Back" then -worldOrigin.LookVector else worldOrigin.LookVector
		local room = clearance(worldOrigin.Position, dir * (2.6 * S), stage) - 0.55
		if room >= need.Min * S then
			worldStage = true
			origin = worldOrigin
			back = room
		end
	end
	if not worldStage then
		local ink = Color3.fromRGB(8, 5, 7)
		stagePart(stage, STAGE * CFrame.new(0, 0, -16), Vector3.new(80, 80, 1), ink)
		stagePart(stage, STAGE * CFrame.new(0, 0, 16), Vector3.new(80, 80, 1), ink)
		stagePart(stage, STAGE * CFrame.new(0, -6, 0), Vector3.new(80, 1, 80), ink)
		back = 1.8 * S
		setLiveGrandmaHidden(false)
	else
		setLiveGrandmaHidden(true)
	end
	cam.CFrame = origin
	cam.FieldOfView = BASE_FOV

	local lamp = Instance.new("Part")
	lamp.Anchored = true
	lamp.CanCollide = false
	lamp.CanQuery = false
	lamp.CanTouch = false
	lamp.Transparency = 1
	lamp.Size = Vector3.new(0.2, 0.2, 0.2)
	lamp.CFrame = origin * CFrame.new(0, -1.4, -0.6)
	local faceLight = Instance.new("PointLight")
	faceLight.Range = 11
	faceLight.Brightness = 3.5
	local lightColor = Color3.fromRGB(255, 214, 170):Lerp(flashColor, 0.35)
	if variant.Motion == "Rise" then
		lightColor = Color3.fromRGB(255, 140, 20)
	end
	faceLight.Color = lightColor
	faceLight.Shadows = false
	faceLight.Parent = lamp
	lamp.Parent = stage

	local clone = cloneGrandma()
	local anim: any = nil
	local headOff = Vector3.new(0, 1.5, 0)
	local minHeadDist = 1.2
	local headPart: BasePart? = nil
	local headCorr = Vector3.zero
	local lastTarget: Vector3? = nil
	if clone then
		local root = clone.PrimaryPart :: BasePart
		local head = clone:FindFirstChild("Head") :: BasePart
		headPart = head
		headOff = root.CFrame:PointToObjectSpace(head.Position)
		local hs = head.Size
		minHeadDist = math.max(1.1, math.max(hs.X, hs.Y, hs.Z) * 0.8 + 0.45)
		-- Prefer the REST pose (C0/C1 chain), not whatever pose she was in (e.g. seated).
		local byChild: { [BasePart]: Motor6D } = {}
		for _, d in clone:GetDescendants() do
			if d:IsA("Motor6D") and d.Part1 then
				byChild[d.Part1] = d
			end
		end
		local function rest(part: BasePart, depth: number): CFrame?
			if part == root then
				return CFrame.identity
			end
			local mj = byChild[part]
			if not mj or not mj.Part0 or depth > 12 then
				return nil
			end
			local parentCf = rest(mj.Part0, depth + 1)
			return parentCf and parentCf * mj.C0 * mj.C1:Inverse()
		end
		local restHead = rest(head, 0)
		if restHead then
			headOff = restHead.Position
		end
		clone.Parent = stage
		anim = shared("GrandmaAnimController").CreateRigAnimator(clone)
		local slot = variant.Animation
		if not (slot and GrandmaConfig.Animations[slot]) then
			slot = js.Animation or "Jumpscare"
		end
		anim:SetSlot(slot, 0)
	end
	local m = {
		D = D,
		O = origin,
		Face = origin.Rotation * CFrame.Angles(0, math.pi, 0),
		Back = back,
		Sign = if math.random() < 0.5 then -1 else 1,
		Calm = calm,
		S = S,
		Front = function(dist: number, y: number): Vector3
			return (origin * CFrame.new(0, y * S, -dist * S)).Position
		end,
	}
	if motion.Setup then
		local okSetup, errSetup = pcall(motion.Setup, m, stage, variant)
		if not okSetup then
			warn("[Jumpscare] setup", variant.Motion, errSetup)
		end
	end
	local out: Out = { Cam = origin, Head = nil, Rot = m.Face, Fov = 0, Black = 0, Light = 1, Blur = 0 }

	-- Post FX
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "DWG_ScareGrade"
	grade.Parent = Lighting
	local blur = Instance.new("BlurEffect")
	blur.Name = "DWG_ScareBlur"
	blur.Size = 0
	blur.Parent = Lighting

	if black then
		black.Visible = false
		black.BackgroundTransparency = 1
	end
	if flash then
		flash.BackgroundColor3 = flashColor
	end
	local line = lineLabel
	if line then
		line.Text = variant.Line or js.Line or ""
		line.Visible = false
		line.TextColor3 = if comedic then C.Paper else C.Paper:Lerp(C.Blood, 0.15 * k)
	end

	-- Per-variant sound design (GrandmaConfig.JumpscareVariants[*].Sound). Cues fire on the
	-- scare clock; the hit replaces the Form's sting when its AssetConfig Id is set.
	local SD = variant.Sound or {}
	local function hasId(key: any): boolean
		local def = typeof(key) == "string" and AssetConfig.Sounds[key]
		return def ~= nil and def ~= false and typeof(def.Id) == "string" and def.Id ~= ""
	end
	local hitKey: string = if hasId(SD.Hit) then SD.Hit else (js.Sound or "JumpscareNormal")
	local vPitch = pitch * range(SD.Pitch, k, 1)
	local vVolume = volume * (SD.Volume or 1)
	local distLevel = math.clamp(range(SD.Distortion, k, 0), 0, 1)
	local octave = math.clamp(range(SD.PitchShift, k, 1), 0.5, 2)
	local function sfx(key: string?, kind: string)
		local s = playScareSound(key)
		if not s then
			return
		end
		s.Volume *= vVolume * (if kind == "Pre" then 0.9 else 1)
		s.PlaybackSpeed *= vPitch
		if (kind == "Hit" or kind == "Scream") and distLevel > 0.01 then
			local d = Instance.new("DistortionSoundEffect")
			d.Level = distLevel
			d.Parent = s
		end
		if kind == "Scream" and math.abs(octave - 1) > 0.01 then
			local p = Instance.new("PitchShiftSoundEffect")
			p.Octave = octave
			p.Parent = s
		end
		if kind == "Hit" and SD.Reverb then
			local r = Instance.new("ReverbSoundEffect")
			r.DecayTime = lerp(1.2, 2.6, k)
			r.WetLevel = -4
			r.Parent = s
		end
	end
	local cues: { { At: number, Key: string?, Kind: string, Done: boolean } } = {
		{ At = SD.PreAt or 0, Key = SD.Pre, Kind = "Pre", Done = false },
		{ At = SD.HitAt or motion.StingAt, Key = hitKey, Kind = "Hit", Done = false },
		{ At = SD.ExtraAt or motion.Impact, Key = SD.Extra, Kind = "Extra", Done = false },
	}
	if SD.Scream ~= false then
		table.insert(cues, { At = motion.ScreamAt, Key = "JumpscareScream", Kind = "Scream", Done = false })
	end

	local t0 = os.clock()
	local done = false
	local lineShown = false
	local impact = motion.Impact
	-- Studio only: DebugJumpscareSlow = N plays the scare N times slower (tuning / captures).
	local slow = if RunService:IsStudio() then workspace:GetAttribute("DebugJumpscareSlow") else nil
	local timeScale = if typeof(slow) == "number" and slow > 0 then 1 / slow else 1
	RunService:BindToRenderStep("DWG_Jumpscare", Enum.RenderPriority.Last.Value, function(rawDt)
		if done then
			return
		end
		local dt = rawDt * timeScale
		local t = (os.clock() - t0) * timeScale
		-- sounds
		for _, cue in cues do
			if not cue.Done and t >= cue.At then
				cue.Done = true
				if cue.Key then
					sfx(cue.Key, cue.Kind)
				end
			end
		end
		-- choreography
		out.Black, out.Light, out.Blur = 0, 1, 0
		out.Head = nil
		local ok, err = pcall(motion.Update, t, m, out)
		if not ok then
			warn("[Jumpscare] motion", variant.Motion, err)
			done = true
			return
		end
		if clone and out.Head then
			-- never let the lens end up inside her (big cartoon heads / scaled forms)
			local headPos: Vector3 = out.Head
			local camPos = out.Cam.Position
			local d = (headPos - camPos).Magnitude
			if d < minHeadDist then
				local dir = if d > 1e-3 then (headPos - camPos).Unit else out.Cam.LookVector
				headPos = camPos + dir * minHeadDist
			end
			-- feedback: the pose (lean / snap) moves the real head; nudge the pivot so the FACE
			-- stays where the choreography wants it, whatever rig or animation is loaded
			if headPart and lastTarget then
				local err = lastTarget - headPart.Position
				if err.Magnitude < 6 then
					headCorr += err * 0.6
					if headCorr.Magnitude > 3 then
						headCorr = headCorr.Unit * 3
					end
				end
			end
			lastTarget = headPos
			clone:PivotTo(CFrame.new(headPos + headCorr) * out.Rot * CFrame.new(-headOff))
		end
		if anim then
			anim:Step(dt)
		end
		-- camera: FOV punch + violent shake (after the hit)
		local spike = math.exp(-((t - impact - 0.03) / 0.07) ^ 2)
		local fovNow = BASE_FOV + (targetFov - BASE_FOV) * out.Fov - 8 * spike * (if calm then 0.4 else 1)
		if comedic and t > impact then
			-- cartoon bounce: the punch overshoots and wobbles back
			fovNow += math.sin((t - impact) * 22) * 4 * math.exp(-(t - impact) * 6) * (if calm then 0.3 else 1)
		end
		cam.FieldOfView = math.clamp(fovNow, 20, 100)
		local pre = if t < impact - 0.05 then 0.15 else 1
		local amp = shakeAmt * pre * (1 - 0.4 * ease((t - D + 0.4) / 0.4))
		local n = os.clock() * 30
		local shake = CFrame.new(math.noise(n, 1) * 0.07 * amp, math.noise(n, 2) * 0.07 * amp, 0)
			* CFrame.Angles(math.noise(n, 3) * 0.06 * amp, math.noise(n, 4) * 0.06 * amp, math.noise(n, 5) * 0.09 * amp)
		cam.CFrame = out.Cam * shake
		-- face light follows the lens (Rise lights her from below, like a jack-o'-lantern)
		if variant.Motion == "Rise" and out.Head then
			lamp.CFrame = CFrame.new(out.Head) * CFrame.new(0, -1.6, 0) + (out.Cam.Position - out.Head).Unit * 0.8
		else
			lamp.CFrame = out.Cam * CFrame.new(0, -1.4, -0.6)
		end
		faceLight.Brightness = 3.5 * out.Light
		-- flash frame on impact
		local f = flash
		if f then
			local fx = (t - impact) / 0.18
			local fa = if fx >= 0 and fx < 1 then (1 - fx) ^ 2 * (if calm then 0.25 else 0.85) else 0
			f.Visible = fa > 0.01
			f.BackgroundTransparency = 1 - fa
		end
		-- distortion
		local pulse = math.abs(math.sin(t * 23))
		local dAmt = distortion * ease((t - impact + 0.05) / 0.1)
		grade.Contrast = 0.15 + 0.9 * dAmt * (0.6 + 0.4 * pulse)
		grade.Saturation = if comedic then 0.1 * dAmt else -0.7 * dAmt + 0.5 * spike * distortion
		local tint = if comedic then Color3.fromRGB(255, 226, 190) else flashColor
		grade.TintColor = Color3.new(1, 1, 1):Lerp(tint, 0.25 * math.max(dAmt, if comedic then 0.6 else 0))
		blur.Size = 12 * dAmt * pulse + 18 * out.Blur * (if calm then 0.4 else 1)
		-- the line
		if line and t > impact + 0.1 and line.Text ~= "" then
			if not lineShown then
				lineShown = true
				line.Visible = true
				local sc = line:FindFirstChildOfClass("UIScale")
				if sc then
					sc.Scale = if comedic then 1.9 else 1.6
					TweenService:Create(sc, TweenInfo.new(if comedic then 0.35 else 0.18, if comedic then Enum.EasingStyle.Elastic else Enum.EasingStyle.Back), { Scale = 1 }):Play()
				end
			end
			if comedic then
				line.Rotation = math.sin(t * 9) * 4 * (if calm then 0 else 1)
				line.Position = UDim2.fromScale(0.5, 0.78)
			else
				line.Rotation = math.noise(n, 9) * 6 * amp
				line.Position = UDim2.new(0.5, math.noise(n, 10) * 10 * amp, 0.78, math.noise(n, 11) * 8 * amp)
			end
		end
		-- lights-out moments + the final cut to black
		local b = black
		if b then
			local endA = if t > D - 0.2 then ease((t - (D - 0.2)) / 0.2) else 0
			local a = math.max(out.Black, endA)
			b.Visible = a > 0.001
			b.BackgroundTransparency = 1 - a
		end
		if t >= D then
			done = true
		end
	end)

	while not done do
		task.wait()
	end
	RunService:UnbindFromRenderStep("DWG_Jumpscare")
	if black then
		black.Visible = true
		black.BackgroundTransparency = 0
	end
	if line then
		line.Visible = false
	end
	if flash then
		flash.Visible = false
	end
	if anim then
		anim:Destroy()
	end
	stage:Destroy()
	grade:Destroy()
	blur:Destroy()
	setLiveGrandmaHidden(false)
	if music then
		music:SetMuffle("Jumpscare", 0)
	end
	cam.FieldOfView = savedFov
	cam.CameraType = Enum.CameraType.Custom
	camCtl:SetFlag("Jumpscare", false)
	finish(formKey)
end

local function onCaught(formKey: any, lostValue: any, lostCount: any, canRevive: any, freeRevive: any, cause: any)
	lastCaught = {
		Form = formKey,
		LostValue = lostValue,
		LostCount = lostCount,
		CanRevive = canRevive,
		FreeRevive = freeRevive,
		Cause = cause,
	}
	if active then
		return
	end
	local key = if typeof(formKey) == "string" then formKey else "Normal"
	local ok, err = pcall(runScare, key, if typeof(cause) == "string" then cause else "Grandma")
	if not ok then
		warn("[Jumpscare]", err)
		RunService:UnbindFromRenderStep("DWG_Jumpscare")
		local cam = workspace.CurrentCamera
		if cam then
			cam.CameraType = Enum.CameraType.Custom
			cam.FieldOfView = BASE_FOV
		end
		for _, name in { "DWG_ScareGrade", "DWG_ScareBlur" } do
			local e = Lighting:FindFirstChild(name)
			if e then
				e:Destroy()
			end
		end
		local st = workspace:FindFirstChild("JumpscareStage")
		if st then
			st:Destroy()
		end
		setLiveGrandmaHidden(false)
		camCtl:SetFlag("Jumpscare", false)
		if music then
			music:SetMuffle("Jumpscare", 0)
		end
		if active then
			finish(key)
		end
	end
end

local function onTeammateCaught(_name: any)
	local s = Sfx.Play("JumpscareScream", nil, { Volume = 0.28, PlaybackSpeed = 0.82 })
	if s then
		local eq = Instance.new("EqualizerSoundEffect")
		eq.HighGain = -28
		eq.MidGain = -8
		eq.LowGain = 2
		eq.Parent = s
	end
	if effects then
		effects:FlashEdge("Red", 0.55, 0.7)
	end
	if camCtl then
		camCtl:Shake(0.25, 0.2)
	end
end

-- ------------------------------------------------------------------ lifecycle

function JumpscareController.Preload() end

function JumpscareController:Start()
	if not PlaceRole.IsMatch then
		return
	end
	settings = shared("ClientSettings")
	camCtl = shared("CameraController")
	music = shared("MusicController")
	effects = shared("EffectsController")
	buildGui()
	local Net = shared("Net")
	Net.Event("Caught").OnClientEvent:Connect(function(...)
		task.spawn(onCaught, ...)
	end)
	Net.Event("TeammateCaught").OnClientEvent:Connect(onTeammateCaught)
end

return JumpscareController
