--!strict
-- NightIntroController (Match)
-- The cinematic night intro played during MatchState Phase "Intro".
-- The server sets IntroEnd (server time) + IntroLength just before Phase becomes "Intro" and
-- freezes the players; this controller fills exactly that window:
--   letterbox + fade up from black -> 3 establishing/detail shots -> title card shot that
--   settles into the player's own first-person view -> hands the camera back as Night begins.
--
-- Timing is derived from IntroLength and sampled every frame from the server clock, so a
-- player who joins mid-intro lands in the right shot, and the sequence always ends on
-- IntroEnd. If Phase leaves "Intro" early the cinematic ends at once.
--
-- Shots are chosen per night by planFor() (see SHOT PLANS below) and built by SHOTS[name]
-- from map markers (House.FrontDoor, GrandmaSleepSpot, MomsCar, Barriers, Rooms,
-- Corruption, PumpkinSpots, workspace.Grandma.Head). A shot whose markers are missing falls
-- back to a generic Room / Exterior shot.
--
-- Camera ownership: while running, the camera is Scriptable and written at RenderPriority
-- Last + 1 (after CameraController's post step, which leaves Scriptable cameras alone).
-- The final shot ends at CameraController's first-person eye point looking where the
-- character faces, so handing back (CameraType = Custom) has no snap.
-- UI: IntroScreen (letterbox, captions, stamp, event card, title card).
-- Bus: fires "CinematicStarted"("NightIntro", night) / "CinematicEnded"("NightIntro").
-- Settings.ReduceFlashes / reduce motion: no handheld shake, no glitch cuts, no bright flashes.
--
--   NightIntroController:IsPlaying() -> boolean

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ProximityPromptService = game:GetService("ProximityPromptService")

local PlaceRole = shared("PlaceRole")
local ClientBus = shared("ClientBus")
local NightConfig = shared("NightConfig")
local GrandmaConfig = shared("GrandmaConfig")
local Sfx = shared("Sfx")

local NightIntroController = {}

local player = Players.LocalPlayer
local UP = Vector3.yAxis
local RENDER_NAME = "DWG_NightIntro"
local END_UI_TIME = 0.45 -- the title card / bars leave during the last this-many seconds

local settings: any = nil
local camCtl: any = nil
local Intro: any = nil -- ReplicatedStorage.UI.IntroScreen
local SpeechBubble: any = nil

local playing = false
local stopFn: ((early: boolean) -> ())? = nil

function NightIntroController:IsPlaying(): boolean
	return playing
end

-- ------------------------------------------------------------------ math helpers

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function sineInOut(x: number): number
	x = math.clamp(x, 0, 1)
	return -(math.cos(math.pi * x) - 1) / 2
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 1e-4 then f.Unit else Vector3.new(0, 0, -1)
end

local function yawRotate(v: Vector3, deg: number): Vector3
	return CFrame.Angles(0, math.rad(deg), 0):VectorToWorldSpace(v)
end

-- ------------------------------------------------------------------ map helpers

local function house(): Instance?
	return workspace:FindFirstChild("House")
end

local function pivotPos(inst: Instance?): Vector3?
	if not inst then
		return nil
	end
	if inst:IsA("BasePart") then
		return inst.Position
	elseif inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	return nil
end

local function grandma(): Model?
	local g = workspace:FindFirstChild("Grandma")
	return if g and g:IsA("Model") then g else nil
end

local function grandmaHead(): BasePart?
	local g = grandma()
	local h = g and g:FindFirstChild("Head")
	return if h and h:IsA("BasePart") then h else nil
end

local function sleepSpot(): BasePart?
	local h = house()
	local s = h and h:FindFirstChild("GrandmaSleepSpot")
	return if s and s:IsA("BasePart") then s else nil
end

local function rooms(): { BasePart }
	local out = {}
	local h = house()
	local f = h and h:FindFirstChild("Rooms")
	if f then
		for _, r in f:GetChildren() do
			if r:IsA("BasePart") then
				table.insert(out, r)
			end
		end
	end
	return out
end

local function inBox(box: BasePart, p: Vector3): boolean
	local lp = box.CFrame:PointToObjectSpace(p)
	local s = box.Size * 0.5
	return math.abs(lp.X) <= s.X and math.abs(lp.Y) <= s.Y and math.abs(lp.Z) <= s.Z
end

local function roomAt(p: Vector3): BasePart?
	for _, r in rooms() do
		if inBox(r, p) then
			return r
		end
	end
	return nil
end

local function houseCenter(): Vector3
	local sum, n = Vector3.zero, 0
	for _, r in rooms() do
		if r:GetAttribute("Area") == "Ground" then
			sum += r.Position
			n += 1
		end
	end
	if n > 0 then
		return sum / n
	end
	local h = house()
	return if h and h:IsA("Model") then h:GetPivot().Position else Vector3.zero
end

local function frontDoorPos(): Vector3?
	local h = house()
	local d = h and h:FindFirstChild("FrontDoor", true)
	if d and d:IsA("Model") then
		local cf, size = d:GetBoundingBox()
		return cf.Position - Vector3.new(0, size.Y * 0.5 - 0.1, 0) -- floor at the door
	end
	return pivotPos(d)
end

-- Raycast clearance from `from` toward `to`, ignoring characters, Grandma and see-through parts.
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function clearDist(from: Vector3, to: Vector3): number
	local dir = to - from
	local len = dir.Magnitude
	if len < 0.01 then
		return len
	end
	local exclude: { Instance } = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(exclude, p.Character)
		end
	end
	local g = grandma()
	if g then
		table.insert(exclude, g)
	end
	local stage = workspace:FindFirstChild("DWG_IntroStage")
	if stage then
		table.insert(exclude, stage)
	end
	for _ = 1, 8 do
		rayParams.FilterDescendantsInstances = exclude
		local r = workspace:Raycast(from, dir, rayParams)
		if not r then
			return len
		end
		local part = r.Instance
		if part.Transparency >= 0.3 or not part.CanCollide and part.Transparency > 0 then
			table.insert(exclude, part)
		else
			return (r.Position - from).Magnitude
		end
	end
	return len
end

-- Pulls `desired` in toward `target` if a wall is in the way.
local function safe(target: Vector3, desired: Vector3, pad: number?): Vector3
	local d = clearDist(target, desired)
	local len = (desired - target).Magnitude
	if d >= len - 0.01 then
		return desired
	end
	return target + (desired - target).Unit * math.max(0.6, d - (pad or 0.7))
end

-- ------------------------------------------------------------------ tone tiers

-- 1 cozy-creepy (1-5) · 2 unsettling (6-15) · 3 disturbing (16-25) · 4 nightmare (26-30) · 5 Halloween (31)
local function tierFor(n: number): number
	if n >= 31 then
		return 5
	elseif n >= 26 then
		return 4
	elseif n >= 16 then
		return 3
	elseif n >= 6 then
		return 2
	end
	return 1
end

local TIERS = {
	[1] = { Tint = Color3.fromRGB(255, 236, 214), Sat = 0.05, Contrast = 0.05, Bright = 0.02, Handheld = 0.25, Cut = "Dip" },
	[2] = { Tint = Color3.fromRGB(222, 224, 245), Sat = -0.15, Contrast = 0.1, Bright = 0, Handheld = 0.45, Cut = "Dip" },
	[3] = { Tint = Color3.fromRGB(214, 222, 220), Sat = -0.55, Contrast = 0.2, Bright = -0.03, Handheld = 1.2, Cut = "Hard", Whisper = true },
	[4] = { Tint = Color3.fromRGB(255, 176, 172), Sat = -0.35, Contrast = 0.28, Bright = -0.02, Handheld = 1.6, Cut = "Glitch", Whisper = true, Subliminal = true },
	[5] = { Tint = Color3.fromRGB(255, 196, 140), Sat = 0.12, Contrast = 0.16, Bright = 0, Handheld = 0.8, Cut = "Dip" },
}

local FLASH_WARM = Color3.fromRGB(243, 233, 210)
local FLASH_BLOOD = Color3.fromRGB(168, 50, 62)
local FLASH_PUMPKIN = Color3.fromRGB(255, 140, 20)

-- ------------------------------------------------------------------ shots
-- A shot is built when it starts (Grandma may stream in late). It returns:
--   Pos(a) -> Vector3, Look(a) -> Vector3, Fov(a) -> number, Roll(a)? -> degrees,
--   Beats? = { { At = 0..1, Fn = () -> () } }, Exit? = () -> (), HideSelf? = boolean,
--   Ease? = (x) -> x   (default sine in/out)
-- `ctx` = { Night, Tier, Cfg, Event, Rng, Calm, Temp (Folder for local props), Dur (s) }

type Shot = {
	Pos: (number) -> Vector3,
	Look: (number) -> Vector3,
	Fov: (number) -> number,
	Roll: ((number) -> number)?,
	Beats: { { At: number, Fn: () -> () } }?,
	Exit: (() -> ())?,
	HideSelf: boolean?,
	Ease: ((number) -> number)?,
	Shake: ((number) -> number)?, -- extra shake amount at alpha
}

local SHOTS: { [string]: (ctx: any, entry: any) -> Shot? } = {}

local function linePath(p0: Vector3, p1: Vector3, l0: Vector3, l1: Vector3, f0: number, f1: number): Shot
	return {
		Pos = function(a)
			return p0:Lerp(p1, a)
		end,
		Look = function(a)
			return l0:Lerp(l1, a)
		end,
		Fov = function(a)
			return lerp(f0, f1, a)
		end,
	}
end

local function playAt(key: string, where: (Instance | Vector3)?, overrides: { [string]: any }?)
	pcall(Sfx.Play, key, where, overrides)
end

-- Local "movie light" so interior detail shots read even in a dark (or powerless) house.
local FILL_COLOR = {
	[1] = Color3.fromRGB(255, 210, 160),
	[2] = Color3.fromRGB(200, 205, 255),
	[3] = Color3.fromRGB(190, 215, 200),
	[4] = Color3.fromRGB(255, 120, 110),
	[5] = Color3.fromRGB(255, 150, 60),
}

local function fillLight(ctx: any, pos: Vector3, range: number?, brightness: number?): PointLight
	local p = Instance.new("Part")
	p.Name = "FillLight"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.one * 0.2
	p.Position = pos
	local l = Instance.new("PointLight")
	l.Color = FILL_COLOR[ctx.Tier] or FILL_COLOR[1]
	l.Range = range or 16
	l.Brightness = brightness or (if ctx.Tier >= 3 then 0.9 else 1.3)
	l.Shadows = true
	l.Parent = p
	p.Parent = ctx.Temp
	return l
end

-- Puts a fill light between the camera path and the subject.
local function withFill(ctx: any, shot: Shot?, subject: Vector3, fromCam: Vector3): Shot?
	if shot then
		local dir = fromCam - subject
		local pos = subject + (if dir.Magnitude > 0.1 then dir.Unit * math.min(3, dir.Magnitude * 0.5) else Vector3.zero) + UP * 2
		fillLight(ctx, safe(subject, pos, 0.3))
	end
	return shot
end

-- 1) Exterior establishing shot: the house at night, slow push toward the front door.
SHOTS.Exterior = function(ctx)
	local door = frontDoorPos()
	if not door then
		return nil
	end
	local center = houseCenter()
	local out = flat(door - center)
	local side = UP:Cross(out) * (if ctx.Rng:NextNumber() < 0.5 then 1 else -1)
	local tgt = door + UP * 5
	local p0 = safe(tgt, door + out * 48 + side * 16 + UP * 3.5)
	local p1 = safe(tgt, door + out * 27 + side * 6 + UP * 5)
	local shot = linePath(p0, p1, door + UP * 11, door + UP * 6, 55, 48)
	if ctx.Tier >= 4 then
		shot.Roll = function(a)
			return lerp(-7, -3, a)
		end
	end
	local beats = {}
	if ctx.Tier >= 4 or ctx.Night % 3 == 0 then
		table.insert(beats, {
			At = 0.08,
			Fn = function()
				playAt("Thunder")
				if not ctx.Calm then
					Intro.Flash(FLASH_WARM, if ctx.Tier >= 4 then 0.35 else 0.2, 0.35)
				end
			end,
		})
	end
	if TIERS[ctx.Tier].Subliminal and not ctx.Calm then
		-- two frames of her face, then back like nothing happened
		table.insert(beats, {
			At = 0.62,
			Fn = function()
				ctx.Subliminal = os.clock() + 0.08
			end,
		})
	end
	shot.Beats = beats
	return shot
end

-- Night 1 opener: behind Mom's car, looking over it at Grandma's house.
SHOTS.Arrival = function(ctx)
	local h = house()
	local car = h and h:FindFirstChild("MomsCar")
	local carPos = pivotPos(car)
	local door = frontDoorPos()
	if not carPos or not door then
		return SHOTS.Exterior(ctx)
	end
	local toHouse = flat(door - carPos)
	local side = UP:Cross(toHouse)
	local p0 = carPos - toHouse * 11 + side * 3 + UP * 4
	local p1 = carPos - toHouse * 6.5 + side * 1.5 + UP * 4.6
	return linePath(p0, p1, door + UP * 8, door + UP * 6, 60, 52)
end

-- 2) Grandma asleep in her chair: a slow dolly around her (closer and lower as nights go on).
local ORBIT = {
	[1] = { R = 7.5, H = 1.3, A0 = -55, A1 = -15, Push = 1, Fov = { 52, 48 } },
	[2] = { R = 6, H = 0.5, A0 = 45, A1 = 12, Push = 0.85, Fov = { 50, 45 } },
	[3] = { R = 4.8, H = 0.1, A0 = -22, A1 = -6, Push = 0.7, Fov = { 46, 40 } },
	[4] = { R = 4, H = -0.5, A0 = 12, A1 = 2, Push = 0.55, Fov = { 44, 36 } },
	[5] = { R = 6.5, H = 0.8, A0 = -40, A1 = 5, Push = 0.8, Fov = { 50, 44 } },
}

local function headAndFacing(): (Vector3?, Vector3, BasePart?)
	local head = grandmaHead()
	local spot = sleepSpot()
	local g = grandma()
	local root = g and g:FindFirstChild("HumanoidRootPart") :: BasePart?
	local facing = if root then flat(root.CFrame.LookVector) elseif spot then flat(spot.CFrame.LookVector) else Vector3.new(0, 0, -1)
	if head then
		return head.Position, facing, head
	elseif spot then
		return spot.Position + UP * 2, facing, nil
	end
	return nil, facing, nil
end

local function orbitShot(ctx: any, center: Vector3, facing: Vector3, o: any): Shot
	-- One safe radius for the whole move (no distance popping mid-shot).
	local r = o.R
	for i = 0, 4 do
		local ang = lerp(o.A0, o.A1, i / 4)
		local want = center + yawRotate(facing, ang) * o.R + UP * o.H
		r = math.min(r, clearDist(center, want) - 0.7)
	end
	r = math.max(2.2, r)
	-- aim a little above her head so the snore bubble is in frame
	-- (close-up tiers stay on the face)
	local look0 = center + UP * (if ctx.Tier == 1 then 0.9 elseif ctx.Tier == 2 or ctx.Tier == 5 then 0.5 else -0.1)
	return {
		Pos = function(a)
			local ang = lerp(o.A0, o.A1, a)
			local rad = r * lerp(1, o.Push, a)
			return center + yawRotate(facing, ang) * rad + UP * o.H
		end,
		Look = function(a)
			return look0:Lerp(center, a * 0.5)
		end,
		Fov = function(a)
			return lerp(o.Fov[1], o.Fov[2], a)
		end,
	}
end

SHOTS.Grandma = function(ctx)
	local center, facing, head = headAndFacing()
	if not center then
		return nil
	end
	local shot = orbitShot(ctx, center, facing, ORBIT[ctx.Tier] or ORBIT[1])
	local beats = {}
	table.insert(beats, {
		At = 0.12,
		Fn = function()
			local tierLines = GrandmaConfig.VoiceLines.Asleep
			local vt = ctx.Cfg.VoiceTier or 1
			local lines = tierLines[vt] or tierLines[1]
			local line = if ctx.Night == 1 then "Zzz... mmm... cookies..." else lines[ctx.Rng:NextInteger(1, #lines)]
			if head and SpeechBubble then
				pcall(SpeechBubble.Show, head, line, { Duration = math.max(1.2, ctx.Dur * 0.75), ReduceMotion = ctx.Calm })
			end
			if ctx.Tier == 1 then
				playAt("GrandmaStir", head or center, { Volume = 0.5, PlaybackSpeed = 0.9 })
			end
		end,
	})
	if ctx.Tier >= 4 then
		table.insert(beats, {
			At = 0.8,
			Fn = function()
				playAt("Whisper", nil, { PlaybackSpeed = 0.8 })
			end,
		})
		shot.Roll = function(a)
			return lerp(4, -3, a)
		end
	end
	shot.Beats = beats
	return shot
end

-- Night 31: the chair is EMPTY (she's awake)... slow push-in... then a jolt: her face.
local function setGrandmaHidden(hidden: boolean)
	local g = grandma()
	if not g then
		return
	end
	for _, d in g:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			(d :: any).LocalTransparencyModifier = if hidden then 1 else 0
		elseif d:IsA("Light") then
			if hidden then
				if d:GetAttribute("DWG_IntroLight") == nil then
					d:SetAttribute("DWG_IntroLight", d.Enabled)
				end
				d.Enabled = false
			elseif d:GetAttribute("DWG_IntroLight") ~= nil then
				d.Enabled = d:GetAttribute("DWG_IntroLight") == true
				d:SetAttribute("DWG_IntroLight", nil)
			end
		end
	end
end

SHOTS.EmptyChair = function(ctx)
	local center, facing, head = headAndFacing()
	if not center then
		return nil
	end
	local JOLT = 0.8
	setGrandmaHidden(true)
	local orbit = orbitShot(ctx, center, facing, ORBIT[5])
	local joltPos = safe(center, center + facing * 1.5 + UP * 0.1, 0.3)
	local jolted = false
	local shot: Shot = {
		Pos = function(a)
			if a >= JOLT then
				return joltPos
			end
			return orbit.Pos(sineInOut(a / JOLT))
		end,
		Look = function(a)
			if a >= JOLT then
				return center
			end
			return orbit.Look(sineInOut(a / JOLT))
		end,
		Fov = function(a)
			if a >= JOLT then
				return lerp(38, 32, (a - JOLT) / (1 - JOLT))
			end
			return orbit.Fov(sineInOut(a / JOLT))
		end,
		Ease = function(x)
			return x -- the orbit part is eased by the remap; keep the jolt a hard cut
		end,
		Shake = function(a)
			return if a >= JOLT then 2.2 else 0
		end,
		Beats = {
			{
				At = 0.1,
				Fn = function()
					playAt("Wind", nil, { Looped = false, Volume = 0.35 })
				end,
			},
			{
				At = JOLT,
				Fn = function()
					if jolted then
						return
					end
					jolted = true
					setGrandmaHidden(false)
					playAt("ChaseStinger")
					playAt("GrandmaLaugh", head or center)
					Intro.Flash(FLASH_PUMPKIN, if ctx.Calm then 0.15 else 0.7, 0.3)
					if head and SpeechBubble then
						pcall(SpeechBubble.Show, head, "TRICK OR TREAT, DEARIES!", { Scary = true, Duration = 1.2, ReduceMotion = ctx.Calm })
					end
				end,
			},
		},
		Exit = function()
			setGrandmaHidden(false)
		end,
	}
	return shot
end

-- Extreme close-up of her sleeping face (event nights about Grandma herself).
SHOTS.GrandmaClose = function(ctx)
	local center, facing = headAndFacing()
	if not center then
		return nil
	end
	local side = UP:Cross(facing)
	local p0 = safe(center, center + facing * 3.4 + side * 0.8 + UP * 0.3, 0.4)
	local p1 = safe(center, center + facing * 1.7 + side * 0.3 + UP * 0.1, 0.4)
	return linePath(p0, p1, center - UP * 0.1, center, 42, 34)
end

-- Barrier boards for tonight's new area: a local copy of the (now hidden) boards falls away.
local function barrierFor(areaText: string): Instance?
	local h = house()
	local f = h and h:FindFirstChild("Barriers")
	if not f then
		return nil
	end
	local want = areaText:upper():gsub("^THE ", "")
	for _, b in f:GetChildren() do
		local a = b:GetAttribute("Area")
		if typeof(a) == "string" and a:upper() == want then
			return b
		end
	end
	return nil
end

SHOTS.Barrier = function(ctx)
	local newArea = ctx.Cfg.NewArea or ""
	local barrier = barrierFor(newArea)
	if not barrier then
		return nil
	end
	local cf: CFrame, size: Vector3
	-- Frame the boards themselves (a model may also hold hatches / invisible colliders).
	local boards: { BasePart } = {}
	for _, d in barrier:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Board" then
			table.insert(boards, d)
		end
	end
	if #boards > 0 then
		local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
		local ref = boards[1].CFrame.Rotation
		for _, b in boards do
			local lp = ref:PointToObjectSpace(b.Position)
			local half = b.Size * 0.5
			lo = lo:Min(lp - half)
			hi = hi:Max(lp + half)
		end
		cf = ref + ref:PointToWorldSpace((lo + hi) * 0.5)
		size = hi - lo
	elseif barrier:IsA("Model") then
		cf, size = barrier:GetBoundingBox()
	elseif barrier:IsA("BasePart") then
		cf, size = barrier.CFrame, barrier.Size
	else
		return nil
	end
	-- The boards' thin axis is the viewing axis; look from the side that's already open.
	local axes = { { cf.RightVector, size.X }, { cf.UpVector, size.Y }, { cf.LookVector, size.Z } }
	table.sort(axes, function(x, y)
		return x[2] < y[2]
	end)
	local normal: Vector3 = axes[1][1]
	local center = cf.Position
	local newKey = newArea:upper():gsub("^THE ", "")
	local function openSide(n: Vector3): number
		local p = center + n * 4
		local r = roomAt(p)
		local area = r and r:GetAttribute("Area")
		local score = clearDist(center + n * 0.8, center + n * 10)
		if typeof(area) == "string" and area:upper() ~= newKey then
			score += 100
		end
		return score
	end
	if openSide(-normal) > openSide(normal) then
		normal = -normal
	end
	local lookAt = center
	local vertical = math.abs(normal.Y) > 0.7
	local p0, p1
	if vertical then
		-- a hatch: look up/down at it from a little off-axis
		local side = flat(cf.RightVector)
		p0 = safe(center, center + normal * 8 + side * 4)
		p1 = safe(center, center + normal * 5 + side * 2)
	else
		local side = UP:Cross(normal)
		p0 = safe(center, center + normal * 10 + side * 2.5 + UP * 0.5)
		p1 = safe(center, center + normal * 5.5 + side * 1 + UP * 0.2)
	end
	-- Local visible copy of the boards (the server already hid the real ones).
	local copy: Instance? = nil
	local ok = pcall(function()
		local was = barrier.Archivable
		barrier.Archivable = true
		local c = barrier:Clone()
		barrier.Archivable = was
		if not c then
			return
		end
		for _, d in c:GetDescendants() do
			if d:IsA("BasePart") then
				local o = d:GetAttribute("OrigT")
				d.Transparency = if typeof(o) == "number" then o else 0
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			elseif d:IsA("Decal") or d:IsA("Texture") then
				local o = d:GetAttribute("OrigT")
				d.Transparency = if typeof(o) == "number" then o else 0
			end
		end
		if c:IsA("BasePart") then
			local o = c:GetAttribute("OrigT")
			c.Transparency = if typeof(o) == "number" then o else 0
			c.Anchored = true
			c.CanCollide = false
			c.CanQuery = false
		end
		c.Parent = ctx.Temp
		copy = c
	end)
	if not ok then
		copy = nil
	end
	local shot = linePath(p0, p1, lookAt + UP * 0.3, lookAt, 55, 48)
	withFill(ctx, shot, center, p0)
	-- the new area is usually pitch dark: a stronger key light from just behind the lens
	fillLight(ctx, p1:Lerp(center, 0.25) + UP * 1.2, 20, 2.2)
	shot.Beats = {
		{
			At = 0.3,
			Fn = function()
				local c = copy
				if not c then
					return
				end
				local parts = {}
				if c:IsA("BasePart") then
					table.insert(parts, c)
				end
				for _, d in c:GetDescendants() do
					if d:IsA("BasePart") then
						table.insert(parts, d)
					end
				end
				playAt("Break", center, { Volume = 0.6 })
				for i, p in parts do
					local delayT = (i - 1) * 0.06 + ctx.Rng:NextNumber() * 0.05
					local drop = math.max(1.5, p.Size.Y * 0.5 + (center.Y - p.Position.Y) + size.Y * 0.5)
					local tilt = CFrame.Angles(ctx.Rng:NextNumber(-0.9, 0.9), ctx.Rng:NextNumber(-0.4, 0.4), ctx.Rng:NextNumber(-1.2, 1.2))
					local goal = (p.CFrame - UP * drop + normal * ctx.Rng:NextNumber(0.3, 1.5)) * tilt
					local info = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, delayT)
					TweenService:Create(p, info, { CFrame = goal }):Play()
					TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, delayT + 0.45), { Transparency = 1 }):Play()
				end
			end,
		},
		{
			At = 0.42,
			Fn = function()
				Intro.Stamp(newArea)
			end,
		},
	}
	return shot
end

-- Inside a room: from a high corner, drifting across (cozy loot shots, event rooms).
local function pickRoom(ctx: any, prefer: string?): BasePart?
	local list = {}
	local preferred = nil
	for _, r in rooms() do
		local area = r:GetAttribute("Area")
		local open = typeof(area) ~= "string" or ctx.Cfg.Areas == nil or ctx.Cfg.Areas[area] == true
		local name = tostring(r:GetAttribute("RoomName") or r.Name)
		if open then
			if prefer and name:lower():find(prefer:lower(), 1, true) then
				preferred = r
			end
			-- skip hallways / stairs, they make boring shots
			if not name:find("Hall") and not name:find("Stair") and not name:find("Landing") and r.Size.X >= 10 and r.Size.Z >= 10 then
				table.insert(list, r)
			end
		end
	end
	if preferred then
		return preferred
	end
	if #list == 0 then
		return nil
	end
	table.sort(list, function(a, b)
		return a:GetFullName() < b:GetFullName()
	end)
	return list[ctx.Rng:NextInteger(1, #list)]
end

SHOTS.Room = function(ctx, entry)
	local room = pickRoom(ctx, entry and entry.Room)
	if not room then
		return nil
	end
	local cf, s = room.CFrame, room.Size
	local sx = if ctx.Rng:NextNumber() < 0.5 then 1 else -1
	local sz = if ctx.Rng:NextNumber() < 0.5 then 1 else -1
	local p0 = cf:PointToWorldSpace(Vector3.new(s.X * 0.4 * sx, s.Y * 0.26, s.Z * 0.4 * sz))
	local p1 = cf:PointToWorldSpace(Vector3.new(s.X * 0.3 * sx, s.Y * 0.18, s.Z * 0.22 * sz))
	local l0 = cf:PointToWorldSpace(Vector3.new(0, -s.Y * 0.28, 0))
	local l1 = cf:PointToWorldSpace(Vector3.new(-s.X * 0.12 * sx, -s.Y * 0.3, -s.Z * 0.05 * sz))
	local shot = linePath(p0, p1, l0, l1, 62, 55)
	fillLight(ctx, cf:PointToWorldSpace(Vector3.new(0, s.Y * 0.1, 0)), math.max(s.X, s.Z) * 0.9, if ctx.Tier >= 3 then 0.7 else 1)
	return shot
end

-- A creepy detail from House.Corruption/<level>: a turned portrait, a doll, a rocking chair...
local CORRUPTION_PREFER = {
	[1] = { "TurnedPicture", "FallenPicture" },
	[2] = { "Doll" },
	[3] = { "RockingChair", "CeilingTable", "Chair" },
	[4] = { "StaringPortrait", "StaringEyes" },
}

SHOTS.Corruption = function(ctx)
	local h = house()
	local folder = h and h:FindFirstChild("Corruption")
	if not folder then
		return nil
	end
	local level = math.clamp(ctx.Cfg.Corruption or 0, 1, 4)
	local target: Instance? = nil
	for lv = level, 1, -1 do
		local sub = folder:FindFirstChild(tostring(lv))
		if sub then
			local candidates = {}
			for _, name in CORRUPTION_PREFER[lv] or {} do
				for _, c in sub:GetChildren() do
					if c.Name == name then
						local p = pivotPos(c)
						local r = p and roomAt(p)
						local area = r and r:GetAttribute("Area")
						if p and r and (typeof(area) ~= "string" or ctx.Cfg.Areas[area]) then
							table.insert(candidates, c)
						end
					end
				end
				if #candidates > 0 then
					break
				end
			end
			if #candidates > 0 then
				table.sort(candidates, function(a, b)
					return tostring(pivotPos(a)) < tostring(pivotPos(b))
				end)
				target = candidates[ctx.Rng:NextInteger(1, #candidates)]
				break
			end
		end
	end
	local pos = pivotPos(target)
	if not target or not pos then
		return nil
	end
	local room = roomAt(pos) :: BasePart
	local toRoom = flat(room.Position - pos)
	local side = UP:Cross(toRoom)
	local p0 = safe(pos, pos + toRoom * 6.5 + side * 1.5 + UP * 0.4)
	local p1 = safe(pos, pos + toRoom * 3.2 + side * 0.4 + UP * 0.1)
	local shot = linePath(p0, p1, pos + side * 0.4, pos, 50, 40)
	withFill(ctx, shot, pos, p0)
	if ctx.Tier >= 3 then
		shot.Beats = {
			{
				At = 0.5,
				Fn = function()
					playAt("Whisper")
				end,
			},
		}
	end
	return shot
end

-- Up at the roofline and the sky (Blood Moon).
SHOTS.Sky = function(ctx)
	local door = frontDoorPos()
	if not door then
		return nil
	end
	local out = flat(door - houseCenter())
	local side = UP:Cross(out)
	local p0 = door + out * 20 + side * 4 + UP * 1.5
	local p1 = door + out * 16 + side * 2 + UP * 1.2
	return linePath(p0, p1, door + UP * 16, door + UP * 32 - out * 6, 66, 60)
end

-- Night 31: a jack-o'-lantern spot, glowing.
SHOTS.Pumpkins = function(ctx)
	local h = house()
	local f = h and h:FindFirstChild("PumpkinSpots")
	if not f then
		return SHOTS.Exterior(ctx)
	end
	local spots = {}
	for _, s in f:GetChildren() do
		if s:IsA("BasePart") then
			table.insert(spots, s)
		end
	end
	if #spots == 0 then
		return SHOTS.Exterior(ctx)
	end
	table.sort(spots, function(a, b)
		return a.Name .. tostring(a.Position) < b.Name .. tostring(b.Position)
	end)
	local spot = spots[ctx.Rng:NextInteger(1, #spots)]
	local pos = spot.Position
	local room = roomAt(pos)
	local dir = if room then flat(room.Position - pos) else flat(pos - houseCenter())
	local side = UP:Cross(dir)
	local p0 = safe(pos, pos + dir * 6 + side * 2 + UP * 2.2)
	local p1 = safe(pos, pos + dir * 3 + side * 0.6 + UP * 1.1)
	-- local glow so the spot reads even before the pumpkin is lit
	local glowPart = Instance.new("Part")
	glowPart.Anchored = true
	glowPart.CanCollide = false
	glowPart.CanQuery = false
	glowPart.CanTouch = false
	glowPart.Transparency = 1
	glowPart.Size = Vector3.one * 0.2
	glowPart.Position = pos + UP * 1
	local light = Instance.new("PointLight")
	light.Color = FLASH_PUMPKIN
	light.Range = 14
	light.Brightness = 2
	light.Shadows = true
	light.Parent = glowPart
	glowPart.Parent = ctx.Temp
	local shot = linePath(p0, p1, pos + UP * 0.8, pos + UP * 0.6, 55, 46)
	local baseFov = shot.Fov
	shot.Fov = function(a)
		-- flicker the glow as a side effect of the per-frame FOV query (cheap)
		light.Brightness = 1.6 + math.noise(os.clock() * 6, 3.3) * 1.4
		return baseFov(a)
	end
	return shot
end

-- 4) Title card: the camera settles into the player's own eyes, looking where they face.
local function eyeCFrame(): CFrame?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then
		return nil
	end
	-- Mirrors the default camera's subject point (R15 head offset) + CameraOffset.
	local height = if hum.RigType == Enum.HumanoidRigType.R15 then 1.5 + (root.Size.Y - 2) * 0.5 else 1.5
	local pos = root.CFrame:PointToWorldSpace(Vector3.new(0, height, 0) + hum.CameraOffset)
	local look = flat(root.CFrame.LookVector)
	return CFrame.lookAt(pos, pos + look)
end

SHOTS.POV = function(ctx)
	local eye0 = eyeCFrame()
	if not eye0 then
		return nil
	end
	local door = frontDoorPos()
	-- start looking up at the house (or up-ish if there's no door), settle to level
	local startLook = if door then (door + UP * 12 - eye0.Position).Unit else (eye0.LookVector + UP * 0.35).Unit
	local shot: Shot = {
		Pos = function(_a)
			local e = eyeCFrame() or eye0
			return e.Position
		end,
		Look = function(a)
			local e = eyeCFrame() or eye0
			local dir = startLook:Lerp(e.LookVector, a)
			if dir.Magnitude < 1e-3 then
				dir = e.LookVector
			end
			return e.Position + dir.Unit * 10
		end,
		Fov = function(a)
			return lerp(56, camCtl and camCtl:GetBaseFov() or 70, a)
		end,
		Ease = function(x)
			-- settle early, hold on the eye line for the hand-off
			return smooth(math.min(1, x / 0.82))
		end,
		HideSelf = true,
		Beats = {
			{
				At = 0,
				Fn = function()
					Intro.Title(ctx.Cfg.Title, ctx.Cfg.Subtitle or "", {
						Night = ctx.Night,
						Finale = ctx.Cfg.Finale == true,
						TypeTime = math.clamp(ctx.Dur * 0.4, 0.5, 1.2),
					})
					playAt("ClockChime")
					if ctx.Tier >= 4 then
						playAt("Thunder", nil, { Volume = 0.35 })
					end
				end,
			},
		},
	}
	return shot
end

-- Last resort: hold whatever the camera sees and creep forward.
SHOTS.Hold = function(_ctx)
	local cam = workspace.CurrentCamera
	local cf = cam.CFrame
	return linePath(cf.Position, cf.Position + cf.LookVector * 2, cf.Position + cf.LookVector * 20, cf.Position + cf.LookVector * 22, 60, 55)
end

-- ------------------------------------------------------------------ SHOT PLANS
-- Weights are relative; durations = Weight / total * IntroLength (9 s, 11 s on Night 1).
-- Detail shot per night: NEW AREA nights -> the barrier boards + stamp; event nights ->
-- EVENT_SHOTS + the event card; corruption nights -> a creepy detail; else a cozy room.

local EVENT_SHOTS: { [string]: { Shot: string, Room: string? } } = {
	BloodMoon = { Shot = "Sky" },
	PowerOutage = { Shot = "Room", Room = "Living" },
	LightSleeper = { Shot = "GrandmaClose" },
	HardOfHearing = { Shot = "GrandmaClose" },
	AlreadyAwake = { Shot = "GrandmaClose" },
	DoubleLoot = { Shot = "Room", Room = "Dining" },
	CookieNight = { Shot = "Room", Room = "Kitchen" },
	LockedDoors = { Shot = "Room", Room = "Hallway" },
}

local function detailFor(ctx: any): { [string]: any }
	local cfg = ctx.Cfg
	if cfg.NewArea and cfg.NewArea ~= "" then
		return { Shot = "Barrier", Weight = 2.2 }
	end
	if ctx.Event ~= "" then
		local e = EVENT_SHOTS[ctx.Event] or { Shot = "Room" }
		return { Shot = e.Shot, Room = e.Room, Weight = 2.2, Event = ctx.Event }
	end
	if (cfg.Corruption or 0) >= 1 then
		return { Shot = "Corruption", Weight = 2 }
	end
	return { Shot = "Room", Weight = 2 }
end

local function planFor(ctx: any): { { [string]: any } }
	local n = ctx.Night
	if n == 1 then
		return {
			{ Shot = "Arrival", Weight = 3, Caption = "Mom's dropping you off at Grandma's…" },
			{ Shot = "Grandma", Weight = 2.8, Caption = "Shhh. Don't wake her." },
			{ Shot = "Room", Room = "Living", Weight = 2.2, Caption = "Grab the good stuff. Be out by 6 AM." },
			{ Shot = "POV", Weight = 3 },
		}
	elseif n >= 31 then
		return {
			{ Shot = "Exterior", Weight = 2 },
			{ Shot = "EmptyChair", Weight = 2.7 },
			{ Shot = "Pumpkins", Weight = 1.8 },
			{ Shot = "POV", Weight = 2.5 },
		}
	end
	return {
		{ Shot = "Exterior", Weight = 2.2 },
		{ Shot = "Grandma", Weight = 2.1 },
		detailFor(ctx),
		{ Shot = "POV", Weight = 2.5 },
	}
end

-- ------------------------------------------------------------------ the sequencer

local function setSelfHidden(hidden: boolean)
	local char = player.Character
	if not char then
		return
	end
	for _, d in char:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = if hidden then 1 else d.LocalTransparencyModifier
		end
	end
end

local function run()
	local MS = ReplicatedStorage:FindFirstChild("MatchState")
	if not MS or playing then
		return
	end
	if MS:GetAttribute("Phase") ~= "Intro" then
		return
	end
	local night = MS:GetAttribute("Night") or 1
	local cfg = NightConfig.Get(night)
	local L: number = MS:GetAttribute("IntroLength") or (if night == 1 then 11 else 9)
	local introEnd: number = MS:GetAttribute("IntroEnd") or (workspace:GetServerTimeNow() + L)
	local startT = introEnd - L
	local function clockT(): number
		return workspace:GetServerTimeNow() - startT
	end
	if clockT() >= L - 0.35 then
		return -- joined in the last instant: nothing worth showing
	end

	playing = true
	local tier = tierFor(night)
	local T = TIERS[tier]
	local calm = settings ~= nil and settings:ReduceMotion()
	local temp = Instance.new("Folder")
	temp.Name = "DWG_IntroStage"
	temp.Parent = workspace
	local ctx = {
		Night = night,
		Tier = tier,
		Cfg = cfg,
		Event = MS:GetAttribute("Event") or "",
		Rng = Random.new(night * 7919 + 17),
		Calm = calm,
		Temp = temp,
		Dur = 2,
		Subliminal = 0,
	}
	local plan = planFor(ctx)
	local total = 0
	for _, e in plan do
		total += e.Weight
	end
	local starts, durs = {}, {}
	local acc = 0
	for i, e in plan do
		starts[i] = acc
		durs[i] = e.Weight / total * L
		acc += durs[i]
	end

	ClientBus.Fire("CinematicStarted", "NightIntro", night)
	local promptsWere = ProximityPromptService.Enabled
	pcall(function()
		ProximityPromptService.Enabled = false
	end)
	local lateJoin = clockT() > 0.5
	Intro.CineBegin({ Tier = tier, FromBlack = true })
	if lateJoin then
		Intro.Fade(1, 0)
		Intro.Fade(0, 0.3)
	end

	-- colour grade (local; stacks on top of EnvironmentService's)
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "DWG_IntroGrade"
	grade.Parent = Lighting
	TweenService:Create(grade, TweenInfo.new(0.8), {
		TintColor = T.Tint,
		Saturation = T.Sat,
		Contrast = T.Contrast,
		Brightness = T.Bright,
	}):Play()
	if T.Whisper then
		playAt("Whisper", nil, { Volume = 0.45 })
	end

	local cam = workspace.CurrentCamera
	local fxRng = Random.new()
	local idx = 0
	local shot: Shot? = nil
	local fired: { [number]: boolean } = {}
	local glitchUntil = 0
	local endUiDone = false
	local dipOutDone = false
	local finished = false
	local phaseConn: RBXScriptConnection? = nil

	local function enterShot(i: number, t: number)
		if shot and shot.Exit then
			pcall(shot.Exit)
		end
		local entry = plan[i]
		ctx.Dur = durs[i]
		-- per-shot seed: every client (late joiners too) frames the same things
		ctx.Rng = Random.new(night * 7919 + i * 101 + 17)
		local ok, built = pcall(SHOTS[entry.Shot] or SHOTS.Room, ctx, entry)
		if not ok then
			warn("[NightIntro] shot", entry.Shot, built)
			built = nil
		end
		if not built and entry.Shot ~= "POV" then
			local ok2, b2 = pcall(SHOTS.Room, ctx, entry)
			built = if ok2 then b2 else nil
		end
		if not built then
			local ok3, b3 = pcall(SHOTS.Exterior, ctx, entry)
			built = if ok3 then b3 else nil
		end
		shot = built or SHOTS.Hold(ctx)
		idx = i
		fired = {}
		dipOutDone = false
		local late = t - starts[i] > 0.4
		-- caption / event card beats from the plan entry
		local s = shot :: Shot
		local beats = s.Beats or {}
		s.Beats = beats
		if entry.Caption then
			table.insert(beats, {
				At = 0.05,
				Fn = function()
					Intro.Caption(entry.Caption, durs[i] * 0.92)
				end,
			})
		end
		if entry.Event then
			table.insert(beats, {
				At = 0.18,
				Fn = function()
					Intro.EventCard(entry.Event)
				end,
			})
		end
		-- the cut itself
		if i > 1 and not late then
			if T.Cut == "Dip" then
				Intro.Fade(1, 0)
				Intro.Fade(0, 0.22)
			elseif T.Cut == "Glitch" and not calm then
				glitchUntil = os.clock() + 0.14
				Intro.Flash(FLASH_BLOOD, 0.45, 0.14)
				Intro.Glitch(1)
			end
		end
	end

	local function finish(early: boolean)
		if finished then
			return
		end
		finished = true
		RunService:UnbindFromRenderStep(RENDER_NAME)
		if phaseConn then
			phaseConn:Disconnect()
		end
		if shot and shot.Exit then
			pcall(shot.Exit)
		end
		setGrandmaHidden(false)
		local head = grandmaHead()
		if head and SpeechBubble and SpeechBubble.Clear then
			pcall(SpeechBubble.Clear, head)
		end
		-- hand the camera back on the eye line
		local eye = eyeCFrame()
		if eye then
			cam.CFrame = eye
		end
		cam.FieldOfView = camCtl and camCtl:GetBaseFov() or 70
		cam.CameraType = Enum.CameraType.Custom
		if camCtl then
			camCtl:SetFlag("Cinematic", false) -- re-applies CameraController's mode (subject, zoom)
		end
		if not endUiDone then
			Intro.CineEnd(if early then 0.25 else END_UI_TIME)
		end
		TweenService:Create(grade, TweenInfo.new(if early then 0.3 else 0.6), {
			TintColor = Color3.new(1, 1, 1),
			Saturation = 0,
			Contrast = 0,
			Brightness = 0,
		}):Play()
		task.delay(0.7, function()
			grade:Destroy()
		end)
		task.delay(1.2, function()
			temp:Destroy()
		end)
		pcall(function()
			ProximityPromptService.Enabled = promptsWere
		end)
		playing = false
		stopFn = nil
		ClientBus.Fire("CinematicEnded", "NightIntro")
	end
	stopFn = finish

	phaseConn = MS:GetAttributeChangedSignal("Phase"):Connect(function()
		if MS:GetAttribute("Phase") ~= "Intro" then
			finish(true)
		end
	end)

	local lastT = clockT()
	RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Last.Value + 1, function()
		if finished then
			return
		end
		local ok, err = pcall(function()
			local t = math.max(lastT, clockT()) -- never run backwards on clock jitter
			lastT = t
			if t >= L then
				finish(false)
				return
			end
			-- which shot?
			local want = #plan
			for i = 1, #plan do
				if t < starts[i] + durs[i] then
					want = i
					break
				end
			end
			if want ~= idx then
				enterShot(want, t)
			end
			local s = shot :: Shot
			local raw = math.clamp((t - starts[idx]) / durs[idx], 0, 1)
			-- beats (skip ones a late joiner missed by more than ~0.6 s)
			for bi, b in s.Beats or {} do
				if not fired[bi] and raw >= b.At then
					fired[bi] = true
					if (raw - b.At) * durs[idx] < 0.6 then
						task.spawn(b.Fn)
					end
				end
			end
			-- dip-to-black before a cut
			if T.Cut == "Dip" and idx < #plan and not dipOutDone and t > starts[idx] + durs[idx] - 0.12 then
				dipOutDone = true
				Intro.Fade(1, 0.1)
			end
			-- bars / title leave just before the hand-off
			if not endUiDone and t >= L - END_UI_TIME then
				endUiDone = true
				Intro.CineEnd(END_UI_TIME)
			end

			local a = (s.Ease or sineInOut)(raw)
			local pos = s.Pos(a)
			local look = s.Look(a)
			if (look - pos).Magnitude < 1e-3 then
				look = pos + Vector3.new(0, 0, -1)
			end
			local cf = CFrame.lookAt(pos, look)
			if s.Roll then
				cf *= CFrame.Angles(0, 0, math.rad(s.Roll(a)))
			end
			-- handheld (fades out as the POV shot settles so the hand-off is still)
			local hand = if calm then 0 else T.Handheld
			local extra = if s.Shake and not calm then s.Shake(raw) else 0
			if s.HideSelf then
				hand *= 1 - smooth(raw / 0.8)
			end
			local amp = hand + extra
			if amp > 0 then
				local n = os.clock() * (if tier >= 3 then 2.2 else 0.9)
				local j = if tier >= 3 then os.clock() * 11 else 0
				cf *= CFrame.Angles(
					math.rad((math.noise(n, 1.7) + math.noise(j, 4.1) * 0.25 * extra) * amp),
					math.rad((math.noise(n, 5.3) + math.noise(j, 7.9) * 0.25 * extra) * amp),
					math.rad(math.noise(n, 9.1) * amp * 0.6)
				)
			end
			-- glitch cut: jittered frames
			if os.clock() < glitchUntil then
				local rng = fxRng
				cf = cf * CFrame.new(rng:NextNumber(-0.6, 0.6), rng:NextNumber(-0.4, 0.4), 0) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-5, 5)))
			end
			local fov = s.Fov(a)
			-- subliminal frame (nightmare tier): her face for a blink
			if os.clock() < ctx.Subliminal then
				local head = grandmaHead()
				if head then
					local _, facing = headAndFacing()
					local p = head.Position + facing * 1.6
					cf = CFrame.lookAt(p, head.Position)
					fov = 34
				end
			end
			if s.HideSelf then
				setSelfHidden(true)
			end
			cam.CameraType = Enum.CameraType.Scriptable
			cam.CFrame = cf
			cam.FieldOfView = fov
		end)
		if not ok then
			warn("[NightIntro]", err)
			finish(true)
		end
	end)
end

-- ------------------------------------------------------------------ lifecycle

function NightIntroController.Preload() end

function NightIntroController:Start()
	if not PlaceRole.IsMatch then
		return
	end
	settings = shared("ClientSettings")
	camCtl = shared("CameraController")
	SpeechBubble = shared("SpeechBubble")
	Intro = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("IntroScreen") :: ModuleScript)
	local MS = ReplicatedStorage:WaitForChild("MatchState") :: Folder

	local function tryRun()
		if MS:GetAttribute("Phase") ~= "Intro" or playing then
			return
		end
		task.spawn(function()
			-- IntroScreen mounts asynchronously (UIController); give it a moment.
			local t0 = os.clock()
			while not Intro.IsMounted() and os.clock() - t0 < 3 do
				task.wait(0.05)
			end
			if not Intro.IsMounted() then
				return
			end
			local ok, err = pcall(run)
			if not ok then
				warn("[NightIntro] failed:", err)
				if stopFn then
					stopFn(true)
				end
				playing = false
			end
		end)
	end

	MS:GetAttributeChangedSignal("Phase"):Connect(tryRun)
	tryRun()
end

return NightIntroController
