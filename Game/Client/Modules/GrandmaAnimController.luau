--!strict
-- GrandmaAnimController
-- Animates Grandma LOCALLY from her State attribute (GrandmaConfig.StateAnimation ->
-- GrandmaConfig.Animations slot). Per slot: Id ~= 0 plays the real animation through the
-- Humanoid's Animator (with crossfades); Id == 0 uses the procedural pose in
-- Lib/GrandmaPoses, written to R15 Motor6D.Transform after the Animator runs. Rigs without
-- those joints simply aren't posed. Moving states pick Walk / Run by her real speed.
-- Also shows her voice lines (attribute Say = "text|id") as storybook speech bubbles.
--
--   GrandmaAnimController.CreateRigAnimator(model) -> RigAnimator
--       :SetSlot(slot, fade?)  :Step(dt)  :Destroy()
--   Used by JumpscareController on its local clone, so a replacement rig/animation needs no
--   code changes.

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local GrandmaConfig = shared("GrandmaConfig")
local GrandmaPoses = shared("GrandmaPoses")
local SpeechBubble = shared("SpeechBubble")

local GrandmaAnimController = {}

local Animations = GrandmaConfig.Animations
local StateAnimation = GrandmaConfig.StateAnimation
local FALLBACK_STATE: { [string]: string } = { Distracted = "Idle" }

local FADE = 0.3
local RUN_SPEED = 15 -- above this (studs/s) a walking state uses Run
local MOVE_START, MOVE_STOP = 1.5, 0.6
local PHASE_PER_STUD = 2.0
local ATTACK_TIME = 0.95 -- then she laughs until the state changes
local CULL_DISTANCE = 260

local JOINT_SET: { [string]: boolean } = {}
for _, n in GrandmaPoses.Joints do
	JOINT_SET[n] = true
end
GrandmaPoses.WakeTime = GrandmaConfig.AI.WakeDuration or GrandmaPoses.WakeTime

-- ------------------------------------------------------------------ RigAnimator

local RigAnimator = {}
RigAnimator.__index = RigAnimator

export type RigAnimator = typeof(setmetatable({} :: {
	Model: Model,
	Humanoid: Humanoid?,
	Root: BasePart?,
	Motors: { [string]: Motor6D },
	Slot: string,
	SlotTime: number,
	Phase: number,
	Speed: number,
	Moving: boolean,
	LastPos: Vector3?,
	Twitch: number,
	TwitchSign: number,
	NextTwitch: number,
	Seed: number,
	Blend: number,
	BlendTime: number,
	From: { [string]: CFrame },
	Last: { [string]: CFrame },
	Buf: { [string]: CFrame },
	Tracks: { [string]: AnimationTrack },
	ActiveTrack: AnimationTrack?,
	Scale: number,
	ScaleAt: number,
	Conns: { RBXScriptConnection },
	Dead: boolean,
}, RigAnimator))

-- Animation id for a slot: a rig may override it with a StringValue child "Anim_<Slot>"
-- (so each Granny in ReplicatedStorage.Grannies can have her own set), else GrandmaConfig.
local function animId(model: Instance?, slot: string): string?
	local override = model and model:FindFirstChild("Anim_" .. slot)
	if override and override:IsA("StringValue") and override.Value ~= "" and override.Value ~= "0" then
		local v = override.Value
		return if tonumber(v) then "rbxassetid://" .. v else v
	end
	local def = Animations[slot]
	if def and tonumber(def.Id) and tonumber(def.Id) ~= 0 then
		return "rbxassetid://" .. tostring(def.Id)
	end
	return nil
end

local function isReal(slot: string, model: Instance?): boolean
	return animId(model, slot) ~= nil
end

function RigAnimator.new(model: Model): RigAnimator
	local self = setmetatable({
		Model = model,
		Humanoid = model:FindFirstChildOfClass("Humanoid"),
		Root = model:FindFirstChild("HumanoidRootPart") :: BasePart?,
		Motors = {},
		Slot = "",
		SlotTime = 0,
		Phase = 0,
		Speed = 0,
		Moving = false,
		LastPos = nil,
		Twitch = 0,
		TwitchSign = 1,
		NextTwitch = os.clock() + 3,
		Seed = math.random() * 100,
		Blend = 1,
		BlendTime = FADE,
		From = {},
		Last = {},
		Buf = {},
		Tracks = {},
		ActiveTrack = nil,
		Scale = 1,
		ScaleAt = 0,
		Conns = {},
		Dead = false,
	}, RigAnimator)
	local function consider(d: Instance)
		if d:IsA("Motor6D") and JOINT_SET[d.Name] and not self.Motors[d.Name] then
			self.Motors[d.Name] = d
		end
	end
	for _, d in model:GetDescendants() do
		consider(d)
	end
	table.insert(self.Conns, model.DescendantAdded:Connect(consider))
	return self
end

function RigAnimator.HasJoints(self: RigAnimator): boolean
	return next(self.Motors) ~= nil
end

function RigAnimator._track(self: RigAnimator, slot: string): AnimationTrack?
	local t = self.Tracks[slot]
	if t then
		return t
	end
	local hum = self.Humanoid
	local animator = hum and (hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 2))
	local def = Animations[slot]
	if not animator or not def then
		return nil
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = animId(self.Model, slot) or ("rbxassetid://" .. tostring(def.Id))
	local ok, track = pcall(function()
		return (animator :: Animator):LoadAnimation(anim)
	end)
	if not ok or not track then
		warn("[GrandmaAnim] could not load", slot, track)
		return nil
	end
	track.Looped = def.Looped == true
	if def.Priority then
		track.Priority = def.Priority
	end
	self.Tracks[slot] = track
	return track
end

function RigAnimator.SetSlot(self: RigAnimator, slot: string, fade: number?)
	if slot == self.Slot or self.Dead then
		return
	end
	local f = fade or FADE
	self.Slot = slot
	self.SlotTime = 0
	local track = if isReal(slot, self.Model) then self:_track(slot) else nil
	if self.ActiveTrack and self.ActiveTrack ~= track then
		self.ActiveTrack:Stop(f)
	end
	if track then
		if not self.ActiveTrack then
			-- procedural -> real: hand the joints back to the Animator
			for _, m in self.Motors do
				m.Transform = CFrame.identity
			end
		end
		self.ActiveTrack = track
		track:Play(f)
	else
		self.ActiveTrack = nil
		-- crossfade from whatever is on screen now
		table.clear(self.From)
		for k, v in self.Last do
			self.From[k] = v
		end
		self.Blend = 0
		self.BlendTime = f
	end
end

function RigAnimator._measure(self: RigAnimator, dt: number)
	local root = self.Root
	if not root or dt <= 0 then
		return
	end
	local pos = root.Position
	local last = self.LastPos
	self.LastPos = pos
	if not last then
		return
	end
	local d = Vector3.new(pos.X - last.X, 0, pos.Z - last.Z).Magnitude
	if d > 12 then
		return -- teleport
	end
	local inst = d / dt
	self.Speed += (inst - self.Speed) * math.min(1, dt * 8)
	if self.Moving then
		self.Moving = self.Speed > MOVE_STOP
	else
		self.Moving = self.Speed > MOVE_START
	end
	self.Phase += d * PHASE_PER_STUD / math.max(0.5, self.Scale)
end

function RigAnimator.Step(self: RigAnimator, dt: number)
	if self.Dead then
		return
	end
	self:_measure(dt)
	self.SlotTime += dt
	local now = os.clock()

	-- random twitch pulses
	if now > self.NextTwitch then
		self.NextTwitch = now + 2.5 + math.random() * 6
		self.Twitch = 1
		self.TwitchSign = if math.random() < 0.5 then -1 else 1
	end
	self.Twitch = math.max(0, self.Twitch - dt * 4)

	if self.ActiveTrack then
		local slot = self.Slot
		if slot == "Walk" or slot == "Run" then
			local ref = if slot == "Run" then 18 else 8
			self.ActiveTrack:AdjustSpeed(math.clamp(self.Speed / ref, 0.4, 2))
		end
		return
	end
	if not self:HasJoints() then
		return
	end
	local fn = GrandmaPoses.Poses[self.Slot] or GrandmaPoses.Poses.Idle
	if not fn then
		return
	end

	if now - self.ScaleAt > 1 then
		self.ScaleAt = now
		self.Scale = self.Model:GetScale()
	end

	local ctx = {
		t = self.SlotTime,
		time = now,
		dt = dt,
		speed = self.Speed,
		moveAmp = math.clamp(self.Speed / (8 * self.Scale), 0, 1.25),
		phase = self.Phase,
		twitch = self.Twitch,
		twitchSign = self.TwitchSign,
		seed = self.Seed,
	}
	local pose = self.Buf
	table.clear(pose)
	local ok, err = pcall(fn, ctx, pose)
	if not ok then
		warn("[GrandmaAnim] pose", self.Slot, err)
		return
	end

	local alpha = 1
	if self.Blend < 1 then
		self.Blend = math.min(1, self.Blend + dt / math.max(0.01, self.BlendTime))
		local x = self.Blend
		alpha = x * x * (3 - 2 * x)
	end
	local scale = self.Scale
	for name, motor in self.Motors do
		local cf = pose[name] or CFrame.identity
		if alpha < 1 then
			cf = (self.From[name] or CFrame.identity):Lerp(cf, alpha)
		end
		self.Last[name] = cf
		if scale ~= 1 then
			cf = CFrame.new(cf.Position * scale) * cf.Rotation
		end
		motor.Transform = cf
	end
end

function RigAnimator.Destroy(self: RigAnimator)
	self.Dead = true
	for _, c in self.Conns do
		c:Disconnect()
	end
	for _, t in self.Tracks do
		pcall(t.Stop, t, 0)
	end
	table.clear(self.Tracks)
end

function GrandmaAnimController.CreateRigAnimator(model: Model): RigAnimator
	return RigAnimator.new(model)
end

-- ------------------------------------------------------------------ live Grandma(s)

type Entry = { Anim: RigAnimator, StateSince: number, Conns: { RBXScriptConnection } }
local entries: { [Model]: Entry } = {}
local settings: any = nil

local function slotFor(model: Model, anim: RigAnimator, since: number): string
	local state = model:GetAttribute("State") or "Asleep"
	local base = StateAnimation[state] or FALLBACK_STATE[state] or "Idle"
	local moving = anim.Moving
	if state == "Attacking" then
		return if os.clock() - since > ATTACK_TIME then "Laugh" else "Attack"
	elseif state == "Chasing" then
		return "Run"
	elseif state == "CheckingHiding" then
		if model:GetAttribute("Checking") == true or not moving then
			return "CheckHiding"
		end
		return "Walk"
	elseif base == "Walk" or base == "Idle" or base == "Run" then
		if moving then
			return if anim.Speed > RUN_SPEED * anim.Scale then "Run" else "Walk"
		end
		return if base == "Run" then "Run" else "Idle"
	end
	return base
end

local function showSay(model: Model)
	local raw = model:GetAttribute("Say")
	if typeof(raw) ~= "string" or raw == "" then
		return
	end
	local text = raw:match("^(.*)|[^|]*$") or raw
	if text == "" then
		return
	end
	local head = model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end
	local state = model:GetAttribute("State")
	SpeechBubble.Show(head, text, {
		Scary = state == "Chasing" or state == "Attacking",
		ReduceMotion = settings and settings:ReduceMotion() or false,
	})
end

local function track(model: Instance)
	if not model:IsA("Model") or entries[model] then
		return
	end
	local entry: Entry = { Anim = RigAnimator.new(model), StateSince = os.clock(), Conns = {} }
	entries[model] = entry
	table.insert(entry.Conns, model:GetAttributeChangedSignal("State"):Connect(function()
		entry.StateSince = os.clock()
	end))
	table.insert(entry.Conns, model:GetAttributeChangedSignal("Say"):Connect(function()
		showSay(model)
	end))
	table.insert(entry.Conns, model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) then
			local e = entries[model]
			if e then
				entries[model] = nil
				e.Anim:Destroy()
				for _, c in e.Conns do
					c:Disconnect()
				end
			end
		end
	end))
end

local function step(dt: number)
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position
	for model, e in entries do
		local anim = e.Anim
		local root = anim.Root
		if camPos and root and (root.Position - camPos).Magnitude > CULL_DISTANCE then
			continue
		end
		anim:SetSlot(slotFor(model, anim, e.StateSince))
		anim:Step(dt)
	end
end

function GrandmaAnimController.Preload() end

function GrandmaAnimController:Start()
	settings = shared("ClientSettings")
	CollectionService:GetInstanceAddedSignal("Grandma"):Connect(track)
	for _, m in CollectionService:GetTagged("Grandma") do
		track(m)
	end
	-- Fallback if the tag hasn't replicated yet.
	workspace.ChildAdded:Connect(function(c)
		if c.Name == "Grandma" and c:IsA("Model") then
			task.defer(track, c)
		end
	end)
	local g = workspace:FindFirstChild("Grandma")
	if g then
		track(g)
	end
	RunService.PreSimulation:Connect(step)
end

return GrandmaAnimController
