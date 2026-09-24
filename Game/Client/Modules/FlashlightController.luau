--!strict
-- FlashlightController (Match)
-- Your own flashlight is a local, camera-attached SpotLight that smoothly follows your view
-- (feels far better than the server beam on your head, which is disabled locally to avoid a
-- double beam). Other players still see the server beam on your head.
-- Driven only by Player attributes: Flashlight, FlashlightColor, Battery / MaxBattery, Alive.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlaceRole = shared("PlaceRole")
local Sfx = shared("Sfx")

local FlashlightController = {}

local player = Players.LocalPlayer

local RANGE = 40
local BRIGHTNESS = 2.4
local ANGLE = 58
local LOW_BATTERY = 0.15
local DEFAULT_COLOR = Color3.fromRGB(255, 226, 170)

local FILL_RANGE = 10
local FILL_BRIGHTNESS = 0.9

local holder: Attachment? = nil
local light: SpotLight? = nil
local fill: PointLight? = nil -- soft near-field light so things right in front of you are lit
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true
local followCF: CFrame? = nil
local flickerUntil = 0
local flickerLevel = 1
local nextFlicker = 0

local function wantOn(): boolean
	return player:GetAttribute("Flashlight") == true and player:GetAttribute("Alive") ~= false and player.Character ~= nil
end

local function batteryFrac(): number
	local b = tonumber(player:GetAttribute("Battery")) or 1
	local m = tonumber(player:GetAttribute("MaxBattery")) or 1
	return if m > 0 then b / m else 1
end

local function build()
	local att = Instance.new("Attachment")
	att.Name = "LocalFlashlight"
	local spot = Instance.new("SpotLight")
	spot.Name = "Beam"
	spot.Range = RANGE
	spot.Angle = ANGLE
	spot.Brightness = BRIGHTNESS
	spot.Shadows = true
	spot.Face = Enum.NormalId.Front
	spot.Enabled = false
	spot.Parent = att
	local pt = Instance.new("PointLight")
	pt.Name = "Fill"
	pt.Range = FILL_RANGE
	pt.Brightness = FILL_BRIGHTNESS
	pt.Shadows = false
	pt.Enabled = false
	pt.Parent = att
	att.Parent = workspace.Terrain
	holder, light, fill = att, spot, pt
end

local function applyColor()
	if light then
		local c = player:GetAttribute("FlashlightColor")
		light.Color = if typeof(c) == "Color3" then c else DEFAULT_COLOR
		if fill then
			fill.Color = light.Color
		end
	end
end

-- Server-made beam on our own head: hide it locally.
local function suppressServerBeam()
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	local att = head and head:FindFirstChild("FlashlightAttachment")
	local beam = att and att:FindFirstChild("Flashlight")
	if beam and beam:IsA("Light") and beam.Enabled then
		beam.Enabled = false
	end
end

local function step(dt: number)
	local l, h = light, holder
	local cam = workspace.CurrentCamera
	if not l or not h or not cam then
		return
	end
	local on = wantOn()
	suppressServerBeam()
	if not on then
		if l.Enabled then
			l.Enabled = false
		end
		if fill and fill.Enabled then
			fill.Enabled = false
		end
		followCF = nil
		return
	end
	-- Smooth follow: position locks to the camera, rotation lags a touch (hand-held feel).
	-- Close to a wall/object the beam origin would sit inside it (nothing lit), so pull the
	-- light back behind the eye and drop the side offset as surfaces get close.
	rayParams.FilterDescendantsInstances = { player.Character :: Instance }
	local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 4, rayParams)
	local near = if hit then math.clamp(1 - hit.Distance / 4, 0, 1) else 0
	local target = cam.CFrame * CFrame.new(0.35 * (1 - near), -0.3 * (1 - near), 1.6 * near)
	if fill then
		fill.Enabled = true
		fill.Brightness = FILL_BRIGHTNESS * (0.6 + near * 0.6)
	end
	local cur = followCF or target
	local alpha = 1 - math.exp(-dt * 16)
	local rot = cur.Rotation:Lerp(target.Rotation, alpha)
	followCF = CFrame.new(target.Position) * rot
	h.WorldCFrame = followCF :: CFrame

	-- Low battery flicker.
	local now = os.clock()
	local level = 1
	if batteryFrac() < LOW_BATTERY then
		if now > nextFlicker then
			nextFlicker = now + 0.25 + math.random() * 1.4
			flickerUntil = now + 0.05 + math.random() * 0.2
			flickerLevel = if math.random() < 0.4 then 0 else 0.15 + math.random() * 0.4
		end
		if now < flickerUntil then
			level = flickerLevel
		else
			level = 0.8 + math.noise(now * 6, 3.3) * 0.3
		end
	end
	l.Brightness = BRIGHTNESS * math.clamp(level, 0, 1.2)
	l.Enabled = level > 0.01
	l.Shadows = near < 0.3 -- pulled back behind the eye: don't let our own head shadow the beam
	if fill then
		fill.Brightness *= math.clamp(level, 0, 1)
		fill.Enabled = level > 0.01
	end
end

function FlashlightController.Preload() end

function FlashlightController:Start()
	if not PlaceRole.IsMatch then
		return
	end
	build()
	applyColor()
	player:GetAttributeChangedSignal("FlashlightColor"):Connect(applyColor)
	player:GetAttributeChangedSignal("Flashlight"):Connect(function()
		if player:GetAttribute("Alive") ~= false then
			Sfx.Play("Flashlight")
		end
	end)
	RunService:BindToRenderStep("DWG_Flashlight", Enum.RenderPriority.Camera.Value + 3, step)
end

return FlashlightController
