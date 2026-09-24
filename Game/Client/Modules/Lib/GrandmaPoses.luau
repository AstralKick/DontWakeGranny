--!strict
-- GrandmaPoses
-- Procedural placeholder animation for Grandma, one pose function per animation slot
-- (GrandmaConfig.Animations). Used whenever a slot's Id == 0.
--
--   GrandmaPoses.Poses[slot](ctx, pose)   fills `pose[jointName] = CFrame` (Motor6D.Transform)
--   GrandmaPoses.Joints                   the R15 joint names a pose may write
--
-- DEVELOPER: to replace a pose, give the slot a real animation Id in GrandmaConfig (no code
-- change) or edit/replace the function here. Unwritten joints rest at identity.
--
-- Conventions (R15, Transform is applied in the joint's C0 space, ~ the parent part's axes):
--   Hip/Shoulder  +X = limb swings forward      Knee  -X = bends (lower leg goes back)
--   Elbow         +X = forearm bends forward    Waist -X = hunch forward, +X = lean back
--   Neck          +X = look up, -X = nod down,  +Y = look left,  Z = roll
--   Shoulder Z    left arm out = -Z, right arm out = +Z (hips alike)
--   Root          translation moves the whole body (in studs at scale 1)

export type Ctx = {
	t: number, -- seconds since this slot started
	time: number, -- global clock
	dt: number,
	speed: number, -- horizontal speed (studs/s)
	moveAmp: number, -- 0..1 locomotion amount (speed scaled)
	phase: number, -- gait phase (advances with distance travelled)
	twitch: number, -- 0..1 decaying random twitch pulse
	twitchSign: number, -- -1 or 1, random per twitch
	seed: number,
}

export type Pose = { [string]: CFrame }

local GrandmaPoses = {}

GrandmaPoses.Joints = {
	"Root", "Waist", "Neck",
	"LeftShoulder", "LeftElbow", "LeftWrist",
	"RightShoulder", "RightElbow", "RightWrist",
	"LeftHip", "LeftKnee", "LeftAnkle",
	"RightHip", "RightKnee", "RightAnkle",
}

-- Sitting geometry: how far the pelvis drops/moves back when she sits in her armchair.
GrandmaPoses.SitDrop = 0.95
GrandmaPoses.SitBack = 0.35

local A = CFrame.Angles
local sin, cos, abs, clamp, noise = math.sin, math.cos, math.abs, math.clamp, math.noise
local PI = math.pi

local function ease(x: number): number
	x = clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function easeOut(x: number): number
	x = clamp(x, 0, 1)
	return 1 - (1 - x) ^ 3
end

-- smooth random in [-1, 1]
local function jitter(ctx: Ctx, rate: number, channel: number): number
	return clamp(noise(ctx.time * rate, ctx.seed + channel * 7.31, channel) * 2, -1, 1)
end

local function lerpPose(a: Pose, b: Pose, alpha: number, out: Pose)
	for _, name in GrandmaPoses.Joints do
		local ca, cb = a[name], b[name]
		if ca or cb then
			out[name] = (ca or CFrame.identity):Lerp(cb or CFrame.identity, alpha)
		end
	end
end
GrandmaPoses.Lerp = lerpPose

-- ------------------------------------------------------------------ building blocks

local function sitBase(ctx: Ctx, p: Pose)
	local breath = sin(ctx.time * 1.5)
	p.Root = CFrame.new(0, -GrandmaPoses.SitDrop, GrandmaPoses.SitBack) * A(0.12, 0, 0)
	p.LeftHip = A(1.45, 0, -0.1)
	p.RightHip = A(1.45, 0, 0.1)
	p.LeftKnee = A(-1.4, 0, 0)
	p.RightKnee = A(-1.4, 0, 0)
	p.LeftAnkle = A(0.08, 0, 0)
	p.RightAnkle = A(0.08, 0, 0)
	p.Waist = A(0.1 + breath * 0.035, 0, 0)
	-- hands folded in her lap (knitting)
	p.LeftShoulder = A(0.5 + breath * 0.02, 0, -0.08)
	p.RightShoulder = A(0.5 + breath * 0.02, 0, 0.08)
	p.LeftElbow = A(0.9, 0, 0.25)
	p.RightElbow = A(0.9, 0, -0.25)
	p.LeftWrist = A(-0.15, 0, 0)
	p.RightWrist = A(-0.15, 0, 0)
end

local function standBase(ctx: Ctx, p: Pose)
	local breath = sin(ctx.time * 1.8)
	p.Root = CFrame.new(0, -0.05, 0)
	p.Waist = A(-0.12 + breath * 0.02, 0, 0)
	p.Neck = A(0.14 + breath * 0.015, sin(ctx.time * 0.35) * 0.22, sin(ctx.time * 0.5) * 0.05)
	p.LeftShoulder = A(0.12, 0, -0.06)
	p.RightShoulder = A(0.12, 0, 0.06)
	p.LeftElbow = A(0.4, 0, 0)
	p.RightElbow = A(0.4, 0, 0)
	p.LeftHip = A(0.1, 0, -0.03)
	p.RightHip = A(0.1, 0, 0.03)
	p.LeftKnee = A(-0.14, 0, 0)
	p.RightKnee = A(-0.14, 0, 0)
	p.LeftAnkle = A(0.04, 0, 0)
	p.RightAnkle = A(0.04, 0, 0)
end

-- Leg cycle. Returns the vertical bob so callers can add it to Root.
local function legs(ctx: Ctx, p: Pose, phase: number, amp: number, stride: number, kneeBase: number): number
	local s, c = sin(phase), cos(phase)
	p.LeftHip = A(0.08 + s * stride * amp, 0, -0.04)
	p.RightHip = A(0.08 - s * stride * amp, 0, 0.04)
	p.LeftKnee = A(-(kneeBase + math.max(0, c) * 0.85 * amp), 0, 0)
	p.RightKnee = A(-(kneeBase + math.max(0, -c) * 0.85 * amp), 0, 0)
	p.LeftAnkle = A(math.max(0, -s) * 0.25 * amp, 0, 0)
	p.RightAnkle = A(math.max(0, s) * 0.25 * amp, 0, 0)
	return -abs(c) * 0.1 * amp
end

local function withTwitch(ctx: Ctx, cf: CFrame, strength: number): CFrame
	if ctx.twitch <= 0.01 then
		return cf
	end
	local k = ctx.twitch * strength * ctx.twitchSign
	return cf * A(k * 0.6, k * 0.4, k)
end

-- ------------------------------------------------------------------ poses

local Poses: { [string]: (Ctx, Pose) -> () } = {}

-- Slumped in the armchair, slow breathing, head lolled to one side, the odd twitch.
Poses.Sleep = function(ctx, p)
	sitBase(ctx, p)
	local breath = sin(ctx.time * 1.5)
	p.Neck = withTwitch(ctx, A(-0.5 + breath * 0.04, 0.15, 0.38), 0.35)
	p.RightWrist = withTwitch(ctx, A(-0.15, 0, 0), 0.6)
end

-- Head lifts and looks around, hands grip the armrests.
Poses.Stir = function(ctx, p)
	sitBase(ctx, p)
	local lift = easeOut(ctx.t / 0.6)
	p.Waist = A(0.1 - 0.2 * lift, 0, 0)
	p.Neck = withTwitch(ctx, A(-0.4 + 0.5 * lift + sin(ctx.time * 0.9) * 0.06, sin(ctx.t * 1.1) * 0.7 * lift, 0), 0.4)
	p.LeftShoulder = A(0.35, 0, -0.32)
	p.RightShoulder = A(0.35, 0, 0.32)
	p.LeftElbow = A(0.65, 0, 0)
	p.RightElbow = A(0.65, 0, 0)
end

-- Stand-up lurch out of the chair (one-shot, ~GrandmaConfig.AI.WakeDuration).
GrandmaPoses.WakeTime = 1.6 -- overwritten from GrandmaConfig.AI.WakeDuration by GrandmaAnimController
local sitTmp: Pose, standTmp: Pose = {}, {}
Poses.Wake = function(ctx, p)
	local x = ctx.t / GrandmaPoses.WakeTime
	table.clear(sitTmp)
	table.clear(standTmp)
	sitBase(ctx, sitTmp)
	standBase(ctx, standTmp)
	-- head snaps up first
	sitTmp.Neck = A(0.3, 0, 0)
	sitTmp.LeftShoulder = A(0.3, 0, -0.35)
	sitTmp.RightShoulder = A(0.3, 0, 0.35)
	local e = ease((x - 0.2) / 0.55)
	lerpPose(sitTmp, standTmp, e, p)
	-- forward lurch while rising, arms swinging out for balance
	local lurch = sin(clamp((x - 0.2) / 0.6, 0, 1) * PI)
	p.Root = (p.Root or CFrame.identity) * CFrame.new(0, 0, -0.35 * lurch) * A(-0.45 * lurch, 0, 0)
	p.Waist = (p.Waist or CFrame.identity) * A(-0.3 * lurch, 0, 0)
	p.LeftShoulder = (p.LeftShoulder or CFrame.identity) * A(0.6 * lurch, 0, -0.3 * lurch)
	p.RightShoulder = (p.RightShoulder or CFrame.identity) * A(0.6 * lurch, 0, 0.3 * lurch)
	-- a neck crack at the end
	if x > 0.85 and x < 1 then
		p.Neck = (p.Neck or CFrame.identity) * A(0, 0, sin((x - 0.85) / 0.15 * PI) * 0.35)
	end
end

Poses.Idle = function(ctx, p)
	standBase(ctx, p)
	p.Neck = withTwitch(ctx, p.Neck, 0.3)
	p.RightWrist = withTwitch(ctx, A(0, 0, 0), 0.5)
end

-- Old-lady shuffle.
Poses.Walk = function(ctx, p)
	standBase(ctx, p)
	local amp = ctx.moveAmp
	local bob = legs(ctx, p, ctx.phase, amp, 0.5, 0.15)
	local s = sin(ctx.phase)
	p.Root = CFrame.new(0, -0.05 + bob, 0) * A(-0.04 * amp, 0, 0)
	p.Waist = A(-0.18, s * 0.09 * amp, 0)
	p.Neck = withTwitch(ctx, A(0.2, -s * 0.07 * amp, 0), 0.3)
	p.LeftShoulder = A(0.12 - s * 0.3 * amp, 0, -0.08)
	p.RightShoulder = A(0.12 + s * 0.3 * amp, 0, 0.08)
	p.LeftElbow = A(0.45, 0, 0)
	p.RightElbow = A(0.45, 0, 0)
end

-- Hunched forward, arms reaching out, fast shuffling steps, twitchy head. Creepy.
Poses.Run = function(ctx, p)
	local amp = math.max(ctx.moveAmp, 0.15)
	local phase = ctx.phase * 1.2
	local bob = legs(ctx, p, phase, amp, 0.42, 0.4)
	local s = sin(phase)
	p.Root = CFrame.new(0, -0.18 + bob * 1.4, 0) * A(-0.22, 0, 0)
	p.Waist = A(-0.62 + abs(s) * 0.05, s * 0.06, jitter(ctx, 3, 1) * 0.05)
	p.Neck = withTwitch(ctx, A(0.62 + jitter(ctx, 9, 2) * 0.06, jitter(ctx, 5, 3) * 0.12, sin(ctx.time * 21) * 0.07), 0.5)
	p.LeftShoulder = A(1.3 + s * 0.28, 0, 0.1)
	p.RightShoulder = A(1.3 - s * 0.28, 0, -0.1)
	p.LeftElbow = A(0.15 + math.max(0, -s) * 0.35, 0, 0)
	p.RightElbow = A(0.15 + math.max(0, s) * 0.35, 0, 0)
	-- clawing hands
	p.LeftWrist = A(-0.45 + sin(ctx.time * 11) * 0.15, 0, 0)
	p.RightWrist = A(-0.45 + sin(ctx.time * 11 + 1.7) * 0.15, 0, 0)
end

-- Slow head sweeps, one arm feeling the air ahead. Walks while searching.
Poses.Search = function(ctx, p)
	standBase(ctx, p)
	local amp = ctx.moveAmp
	local bob = legs(ctx, p, ctx.phase, amp, 0.45, 0.15)
	local s = sin(ctx.phase)
	p.Root = CFrame.new(0, -0.05 + bob, 0)
	p.Waist = A(-0.24, s * 0.06 * amp + sin(ctx.t * 0.8) * 0.1, 0)
	p.Neck = withTwitch(ctx, A(0.2 + sin(ctx.t * 0.55) * 0.1, sin(ctx.t * 0.8) * 0.85, 0), 0.4)
	p.RightShoulder = A(1.05 + sin(ctx.t * 1.6) * 0.12, 0, 0.08 + sin(ctx.t * 0.8) * 0.12)
	p.RightElbow = A(0.35, 0, 0)
	p.RightWrist = A(-0.3 + sin(ctx.t * 3.2) * 0.12, 0, 0)
	p.LeftShoulder = A(0.12 - s * 0.25 * amp, 0, -0.08)
	p.LeftElbow = A(0.5, 0, 0)
end

-- Leaning in towards a hiding spot, arms reaching, peering.
Poses.CheckHiding = function(ctx, p)
	standBase(ctx, p)
	local e = ease(ctx.t / 0.5)
	p.Root = CFrame.new(0, -0.12 * e, 0) * A(-0.12 * e, 0, 0)
	p.Waist = A(-0.12 - 0.5 * e + sin(ctx.t * 1.2) * 0.04, 0, 0)
	p.Neck = withTwitch(ctx, A(0.14 + 0.3 * e, sin(ctx.t * 0.7) * 0.2, 0.15 * e), 0.4)
	p.LeftShoulder = A(0.12 + 1.25 * e + sin(ctx.t * 2.1) * 0.08, 0, -0.15)
	p.RightShoulder = A(0.12 + 1.25 * e + sin(ctx.t * 2.1 + 1) * 0.08, 0, 0.15)
	p.LeftElbow = A(0.4 - 0.2 * e, 0, 0)
	p.RightElbow = A(0.4 - 0.2 * e, 0, 0)
	p.LeftWrist = A(-0.25 + sin(ctx.t * 4) * 0.1, 0, 0)
	p.RightWrist = A(-0.25 + sin(ctx.t * 4 + 2) * 0.1, 0, 0)
	p.LeftKnee = A(-0.25 * e - 0.14, 0, 0)
	p.RightKnee = A(-0.25 * e - 0.14, 0, 0)
end

-- Lunge and grab (one-shot).
Poses.Attack = function(ctx, p)
	standBase(ctx, p)
	local t = ctx.t
	local e = easeOut(t / 0.22)
	local relax = ease((t - 1.0) / 0.6) * 0.5
	local k = e * (1 - relax)
	local squeeze = if t > 0.22 then sin(t * 14) * 0.08 * (1 - relax) else 0
	p.Root = CFrame.new(0, -0.25 * k, -0.9 * k) * A(-0.35 * k, 0, 0)
	p.Waist = A(-0.12 - 0.4 * k, 0, 0)
	p.Neck = withTwitch(ctx, A(0.14 + 0.45 * k, 0, jitter(ctx, 8, 4) * 0.1 * k), 0.5)
	p.LeftShoulder = A(0.12 + 1.55 * k, 0, -0.35 * (1 - e) + squeeze)
	p.RightShoulder = A(0.12 + 1.55 * k, 0, 0.35 * (1 - e) - squeeze)
	p.LeftElbow = A(0.3 + squeeze * 2, 0, 0)
	p.RightElbow = A(0.3 + squeeze * 2, 0, 0)
	p.LeftHip = A(0.1 + 0.45 * k, 0, -0.03)
	p.LeftKnee = A(-0.14 - 0.5 * k, 0, 0)
	p.RightHip = A(0.1 - 0.25 * k, 0, 0.03)
end

-- Shoulders shaking, head thrown back, hands on her belly.
Poses.Laugh = function(ctx, p)
	standBase(ctx, p)
	local shake = sin(ctx.time * 17)
	p.Waist = A(0.1 + shake * 0.05, 0, 0)
	p.Neck = A(0.45 + abs(sin(ctx.time * 8.5)) * 0.14, 0, sin(ctx.time * 3) * 0.1)
	p.LeftShoulder = A(0.55 + shake * 0.06, 0, -0.2)
	p.RightShoulder = A(0.55 + shake * 0.06, 0, 0.2)
	p.LeftElbow = A(1.35, 0, 0.35)
	p.RightElbow = A(1.35, 0, -0.35)
end

-- Jumpscare (played on a local clone facing the camera): wind-up, snap forward, violent jitter.
Poses.Jumpscare = function(ctx, p)
	standBase(ctx, p)
	local t = ctx.t
	local wind = ease(t / 0.1)
	local snap = easeOut((t - 0.1) / 0.16)
	local j = if t > 0.2 then 1 else 0
	p.Root = CFrame.new(0, -0.1 * snap, 0) * A(0.15 * wind - 0.35 * snap, 0, 0)
	p.Waist = A(0.2 * wind * (1 - snap) - 0.45 * snap, 0, jitter(ctx, 14, 5) * 0.08 * j)
	p.Neck = A(0.3 * wind + 0.25 * snap + jitter(ctx, 22, 6) * 0.16 * j, jitter(ctx, 18, 7) * 0.16 * j, jitter(ctx, 25, 8) * 0.22 * j)
	-- arms spread wide, then grab at the camera
	p.LeftShoulder = A(0.6 * wind + 1.0 * snap, 0, -1.2 * wind * (1 - snap) - 0.3 * snap)
	p.RightShoulder = A(0.6 * wind + 1.0 * snap, 0, 1.2 * wind * (1 - snap) + 0.3 * snap)
	p.LeftElbow = A(0.2 + 0.5 * snap + jitter(ctx, 16, 9) * 0.15 * j, 0, 0)
	p.RightElbow = A(0.2 + 0.5 * snap + jitter(ctx, 16, 10) * 0.15 * j, 0, 0)
	p.LeftWrist = A(-0.6 * snap, 0, 0)
	p.RightWrist = A(-0.6 * snap, 0, 0)
end

GrandmaPoses.Poses = Poses

return GrandmaPoses
