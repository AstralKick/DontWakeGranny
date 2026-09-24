--!strict
-- CameraController
-- Owns the local camera "feel". Match: first person while alive, smooth crouch height,
-- head-bob, sprint FOV, own pillowcase hidden. Lobby: normal third person.
-- Other controllers layer on top through this API instead of fighting over the camera:
--
--   CameraController:SetFlag(name, on, data?)   "Jumpscare" (hands-off, Scriptable), "Spectate"
--                                               (SpectateController drives subject/zoom), "Hiding"
--                                               (data = hiding kind)
--   CameraController:SetFovOffset(key, degrees) additive FOV target (smoothed)
--   CameraController:Punch(degrees, seconds)    quick FOV kick that decays
--   CameraController:Shake(amount, seconds)     one-off shake impulse (0..1+)
--   CameraController:SetShake(key, amount)      continuous shake source (0 = off)
--   CameraController:SetLookClamp(cf?, yawDeg, pitchDeg)  restrict look around cf.LookVector
--
-- Rotational offsets (shake) are removed before the default camera runs each frame and
-- re-applied after it, so they never accumulate into the player's look direction.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local PlaceRole = shared("PlaceRole")
local GameConfig = shared("GameConfig")

local CameraController = {}

local player = Players.LocalPlayer

local BASE_FOV = 70
local SPRINT_FOV = 6
local CROUCH_OFFSET: Vector3 = GameConfig.Movement.CrouchCameraOffset or Vector3.new(0, -1.6, 0)
local HIDE_OFFSET = {
	Bed = Vector3.new(0, -1.2, 0),
	Cabinet = Vector3.new(0, -0.6, 0),
}

local flags: { [string]: boolean } = {}
local hidingKind: string? = nil
local mode = ""
local fovOffsets: { [string]: number } = {}
local shakeSources: { [string]: number } = {}
local punches: { { amount: number, t0: number, dur: number } } = {}
local impulse = 0
local lastRot = CFrame.identity
local fov = BASE_FOV
local crouchAlpha = 0
local bobPhase = 0
local bobAmount = 0
local sprintAlpha = 0
local lookClamp: { cf: CFrame, yaw: number, pitch: number }? = nil
local defaultMin = StarterPlayer.CameraMinZoomDistance
local defaultMax = StarterPlayer.CameraMaxZoomDistance
local hiddenParts: { BasePart } = {}

local settings: any = nil

local function reduceMotion(): boolean
	return settings ~= nil and settings:ReduceMotion()
end

local function humanoid(): Humanoid?
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function desiredMode(): string
	if flags.Jumpscare then
		return "Jumpscare"
	elseif flags.Spectate then
		return "Spectate"
	elseif not PlaceRole.IsMatch then
		return "Lobby"
	elseif flags.Hiding then
		return "Hiding"
	end
	return "FirstPerson"
end

local function collectHiddenParts()
	table.clear(hiddenParts)
	local c = player.Character
	if not c then
		return
	end
	for _, d in c:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(hiddenParts, d)
		end
	end
end

local function restoreHiddenParts()
	for _, p in hiddenParts do
		if p.Parent then
			p.LocalTransparencyModifier = 0
		end
	end
	table.clear(hiddenParts)
end

local function applyMode()
	local cam = workspace.CurrentCamera
	local want = desiredMode()
	local prev = mode
	mode = want
	if want == "FirstPerson" or want == "Hiding" then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 0.5
		if cam then
			cam.CameraType = Enum.CameraType.Custom
			local hum = humanoid()
			if hum then
				cam.CameraSubject = hum
			end
		end
	elseif want == "Lobby" then
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMaxZoomDistance = defaultMax
		player.CameraMinZoomDistance = defaultMin
		if cam then
			cam.CameraType = Enum.CameraType.Custom
		end
	end
	if want == "Hiding" and prev ~= "Hiding" then
		collectHiddenParts()
	elseif want ~= "Hiding" and prev == "Hiding" then
		restoreHiddenParts()
	end
	if want ~= "FirstPerson" and want ~= "Hiding" then
		local hum = humanoid()
		if hum then
			hum.CameraOffset = Vector3.zero
		end
	end
end

-- ------------------------------------------------------------------ API

function CameraController:SetFlag(name: string, on: boolean, data: any?)
	flags[name] = on or nil
	if name == "Hiding" then
		hidingKind = if on then data else nil
		if not on then
			lookClamp = nil
		end
	end
	applyMode()
end

function CameraController:GetFlag(name: string): boolean
	return flags[name] == true
end

function CameraController:GetMode(): string
	return mode
end

function CameraController:SetFovOffset(key: string, degrees: number)
	fovOffsets[key] = if degrees ~= 0 then degrees else nil
end

function CameraController:Punch(degrees: number, seconds: number)
	table.insert(punches, { amount = degrees, t0 = os.clock(), dur = math.max(0.05, seconds) })
end

function CameraController:Shake(amount: number, seconds: number)
	impulse = math.max(impulse, amount * math.max(0.1, seconds) * 2)
end

function CameraController:SetShake(key: string, amount: number)
	shakeSources[key] = if amount > 0 then amount else nil
end

function CameraController:SetLookClamp(cf: CFrame?, yawDeg: number?, pitchDeg: number?)
	if cf then
		lookClamp = { cf = cf, yaw = math.rad(yawDeg or 60), pitch = math.rad(pitchDeg or 35) }
	else
		lookClamp = nil
	end
end

function CameraController:GetBaseFov(): number
	return BASE_FOV
end

-- ------------------------------------------------------------------ per frame

local function preCamera()
	local cam = workspace.CurrentCamera
	if cam and lastRot ~= CFrame.identity and cam.CameraType ~= Enum.CameraType.Scriptable then
		cam.CFrame = cam.CFrame * lastRot:Inverse()
	end
	lastRot = CFrame.identity
end

local function clampLook(cam: Camera)
	local lc = lookClamp
	if not lc then
		return
	end
	local rel = lc.cf:VectorToObjectSpace(cam.CFrame.LookVector)
	local yaw = math.atan2(-rel.X, -rel.Z)
	local pitch = math.asin(math.clamp(rel.Y, -1, 1))
	local cy = math.clamp(yaw, -lc.yaw, lc.yaw)
	local cp = math.clamp(pitch, -lc.pitch, lc.pitch)
	if cy ~= yaw or cp ~= pitch then
		local dir = lc.cf:VectorToWorldSpace((CFrame.Angles(0, cy, 0) * CFrame.Angles(cp, 0, 0)).LookVector)
		local pos = cam.CFrame.Position
		cam.CFrame = CFrame.lookAt(pos, pos + dir)
	end
end

local function postCamera(dt: number)
	local cam = workspace.CurrentCamera
	if not cam or mode == "Jumpscare" then
		return
	end
	local now = os.clock()
	local calm = reduceMotion()
	local hum = humanoid()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?

	-- Hiding: keep the view inside the spot, looking out.
	if mode == "Hiding" then
		if root then
			lookClamp = lookClamp or { cf = root.CFrame, yaw = math.rad(55), pitch = math.rad(35) }
			;(lookClamp :: any).cf = root.CFrame
		end
		clampLook(cam)
		for _, p in hiddenParts do
			p.LocalTransparencyModifier = 1
		end
	elseif lookClamp then
		clampLook(cam)
	end

	-- Crouch height + head-bob via Humanoid.CameraOffset (root space, never accumulates).
	local firstPerson = mode == "FirstPerson" or mode == "Hiding"
	if hum and firstPerson then
		local crouching = player:GetAttribute("Crouching") == true
		crouchAlpha += ((if crouching then 1 else 0) - crouchAlpha) * (1 - math.exp(-dt * 10))
		local speed = 0
		if root and mode == "FirstPerson" and hum.FloorMaterial ~= Enum.Material.Air then
			local v = root.AssemblyLinearVelocity
			speed = Vector3.new(v.X, 0, v.Z).Magnitude
		end
		local targetBob = if calm then 0 else math.clamp(speed / 12, 0, 1.6)
		bobAmount += (targetBob - bobAmount) * (1 - math.exp(-dt * 8))
		bobPhase += dt * (4 + speed * 0.55)
		local amp = bobAmount * (if crouching then 0.6 else 1)
		local bob = Vector3.new(math.sin(bobPhase) * 0.07 * amp, -math.abs(math.cos(bobPhase)) * 0.11 * amp, 0)
		local offset = CROUCH_OFFSET * crouchAlpha + bob
		if mode == "Hiding" then
			offset = HIDE_OFFSET[hidingKind or ""] or Vector3.zero
		end
		if (hum.CameraOffset - offset).Magnitude > 0.001 then
			hum.CameraOffset = offset
		end
		-- Own pillowcase would float in front of the lens.
		local sack = char and char:FindFirstChild("Pillowcase")
		if sack and sack:IsA("BasePart") then
			sack.LocalTransparencyModifier = 1
		end
	end

	-- FOV
	local sprinting = PlaceRole.IsMatch and mode == "FirstPerson" and player:GetAttribute("Sprinting") == true
	sprintAlpha += ((if sprinting then 1 else 0) - sprintAlpha) * (1 - math.exp(-dt * 6))
	local target = BASE_FOV + SPRINT_FOV * sprintAlpha
	for _, v in fovOffsets do
		target += v
	end
	fov += (target - fov) * (1 - math.exp(-dt * 7))
	local punch = 0
	for i = #punches, 1, -1 do
		local p = punches[i]
		local x = (now - p.t0) / p.dur
		if x >= 1 then
			table.remove(punches, i)
		else
			punch += p.amount * math.sin(math.min(1, x * 4) * math.pi * 0.5) * (1 - x) ^ 2
		end
	end
	cam.FieldOfView = math.clamp(fov + punch, 20, 110)

	-- Shake (rotation only; undone in preCamera)
	local amount = impulse
	for _, v in shakeSources do
		amount = math.max(amount, v)
	end
	impulse = math.max(0, impulse - dt * 2.2)
	if calm then
		amount *= 0.35
	end
	if amount > 0.001 and cam.CameraType ~= Enum.CameraType.Scriptable then
		local t = now * 18
		local rot = CFrame.Angles(
			math.noise(t, 1.3) * amount * 0.035,
			math.noise(t, 7.1) * amount * 0.035,
			math.noise(t, 13.7) * amount * 0.025
		)
		cam.CFrame = cam.CFrame * rot
		lastRot = rot
	end
end

-- ------------------------------------------------------------------ lifecycle

function CameraController.Preload() end

function CameraController:Start()
	settings = shared("ClientSettings")
	RunService:BindToRenderStep("DWG_CameraPre", Enum.RenderPriority.Camera.Value - 1, preCamera)
	RunService:BindToRenderStep("DWG_CameraPost", Enum.RenderPriority.Camera.Value + 1, postCamera)

	player.CharacterAdded:Connect(function(char)
		crouchAlpha = 0
		task.defer(applyMode)
		-- The server places the character after spawning it; once it has settled, point the
		-- camera the way the character faces (spawns face the front door / something useful).
		task.spawn(function()
			local root = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
			if not root then
				return
			end
			-- Re-aim whenever the character teleports during the first few seconds.
			local function snap()
				local cam = workspace.CurrentCamera
				local eye = root.Position + Vector3.new(0, 1.5, 0)
				cam.CFrame = CFrame.lookAt(eye, eye + root.CFrame.LookVector)
			end
			snap()
			local last = root.Position
			local t0 = os.clock()
			while os.clock() - t0 < 3 and root.Parent do
				RunService.RenderStepped:Wait()
				if (root.Position - last).Magnitude > 6 then
					snap()
				end
				last = root.Position
			end
		end)
	end)
	applyMode()
end

return CameraController
