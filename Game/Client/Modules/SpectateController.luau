--!strict
-- SpectateController (Match)
-- While you're caught (Player attribute Alive == false) and no jumpscare is playing, follow a
-- living teammate: third-person orbit on their Humanoid; if they're hiding, you see their
-- hiding view (first person from their head, their body hidden locally). Cycle with ClientBus
-- "SpectateCycle"(dir) (UI buttons / gamepad DPad via InputController). Fires ClientBus
-- "SpectateTarget"(player?) whenever the target changes (nil = nobody to watch; a slow orbit
-- over the house is shown instead). Never reveals Grandma: no highlights, normal lighting.
-- When Alive becomes true again (revive / new night) first person is restored.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlaceRole = shared("PlaceRole")
local ClientBus = shared("ClientBus")

local SpectateController = {}

local player = Players.LocalPlayer

local ORBIT_MIN, ORBIT_MAX = 6, 14
local WATCH_PHASES = { Night = true, Intro = true, Morning = true }

local camCtl: any = nil
local matchState: Instance? = nil
local jumpscaring = false
local active = false
local target: Player? = nil
local targetHidden = false
local hiddenParts: { BasePart } = {}
local orbiting = false
local orbitAngle = 0

local function isAliveTeammate(p: Player): boolean
	if p == player or p.Parent ~= Players or p:GetAttribute("Alive") ~= true then
		return false
	end
	local c = p.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

local function candidates(): { Player }
	local phase = matchState and matchState:GetAttribute("Phase")
	local out = {}
	if phase and not WATCH_PHASES[phase] then
		return out
	end
	for _, p in Players:GetPlayers() do
		if isAliveTeammate(p) then
			table.insert(out, p)
		end
	end
	table.sort(out, function(a, b)
		return a.UserId < b.UserId
	end)
	return out
end

local function restoreHidden()
	for _, part in hiddenParts do
		if part.Parent then
			part.LocalTransparencyModifier = 0
		end
	end
	table.clear(hiddenParts)
end

local function applyView()
	local cam = workspace.CurrentCamera
	local p = target
	if not cam then
		return
	end
	if not p then
		return
	end
	local c = p.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if not c or not hum then
		return
	end
	orbiting = false
	cam.CameraType = Enum.CameraType.Custom
	cam.CameraSubject = hum
	player.CameraMode = Enum.CameraMode.Classic
	targetHidden = p:GetAttribute("Hidden") == true
	restoreHidden()
	if targetHidden then
		-- the hiding view: from their head, looking out of the spot
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 0.5
		for _, d in c:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(hiddenParts, d)
			end
		end
		local root = c:FindFirstChild("HumanoidRootPart") :: BasePart?
		local head = c:FindFirstChild("Head") :: BasePart?
		if root and head then
			cam.CFrame = CFrame.lookAt(head.Position, head.Position + root.CFrame.LookVector)
		end
	else
		player.CameraMaxZoomDistance = ORBIT_MAX
		player.CameraMinZoomDistance = ORBIT_MIN
	end
end

local function setTarget(p: Player?)
	if p == target then
		applyView()
		return
	end
	target = p
	if p then
		applyView()
	else
		restoreHidden()
		orbiting = true
	end
	ClientBus.Fire("SpectateTarget", p)
end

local function cycle(dir: number)
	if not active then
		return
	end
	local list = candidates()
	if #list == 0 then
		setTarget(nil)
		return
	end
	local i = (target and table.find(list, target)) or 0
	i = ((i - 1 + (if dir < 0 then -1 else 1)) % #list) + 1
	setTarget(list[i])
end

local function shouldBeActive(): boolean
	return PlaceRole.IsMatch and player:GetAttribute("Alive") == false and not jumpscaring
end

local function refresh()
	local want = shouldBeActive()
	if want and not active then
		active = true
		camCtl:SetFlag("Spectate", true)
		local list = candidates()
		target = nil
		setTarget(list[1])
	elseif not want and active then
		active = false
		restoreHidden()
		orbiting = false
		target = nil
		ClientBus.Fire("SpectateTarget", nil)
		local cam = workspace.CurrentCamera
		if cam then
			cam.CameraType = Enum.CameraType.Custom
		end
		camCtl:SetFlag("Spectate", false) -- CameraController restores first person
	elseif active then
		-- keep the target valid (left / caught / respawned / hid)
		local t = target
		if not t or not isAliveTeammate(t) then
			local list = candidates()
			setTarget(list[1])
		else
			local hidden = t:GetAttribute("Hidden") == true
			local cam = workspace.CurrentCamera
			local c = t.Character
			local hum = c and c:FindFirstChildOfClass("Humanoid")
			if hidden ~= targetHidden or (cam and hum and cam.CameraSubject ~= hum) then
				applyView()
			end
		end
	end
end

local function orbitCenter(): Vector3
	local house = workspace:FindFirstChild("House")
	if house and house:IsA("Model") then
		return house:GetPivot().Position
	end
	local spawns = house and house:FindFirstChild("PlayerSpawns")
	local first = spawns and spawns:FindFirstChildWhichIsA("BasePart")
	return if first then first.Position else Vector3.new(0, 10, 0)
end

local center: Vector3? = nil
local function stepOrbit(dt: number)
	if not active or not orbiting then
		return
	end
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	center = center or orbitCenter()
	orbitAngle += dt * 0.08
	local c = center :: Vector3
	cam.CameraType = Enum.CameraType.Scriptable
	local pos = c + Vector3.new(math.cos(orbitAngle) * 70, 45, math.sin(orbitAngle) * 70)
	cam.CFrame = CFrame.lookAt(pos, c)
end

local function stepHidden()
	if active and targetHidden then
		for _, part in hiddenParts do
			part.LocalTransparencyModifier = 1
		end
	end
end

function SpectateController:GetTarget(): Player?
	return target
end

function SpectateController:IsActive(): boolean
	return active
end

function SpectateController.Preload() end

function SpectateController:Start()
	if not PlaceRole.IsMatch then
		return
	end
	camCtl = shared("CameraController")
	matchState = ReplicatedStorage:WaitForChild("MatchState", 30)

	ClientBus.On("JumpscareStarted", function()
		jumpscaring = true
		refresh()
	end)
	ClientBus.On("JumpscareFinished", function()
		jumpscaring = false
		refresh()
	end)
	ClientBus.On("SpectateCycle", function(dir: number?)
		cycle(dir or 1)
	end)
	-- DeathScreen fires this when its spectate bar opens/closes; we're already following a
	-- teammate after the jumpscare, so just re-validate the target.
	ClientBus.On("SpectateRequest", function()
		refresh()
	end)
	player:GetAttributeChangedSignal("Alive"):Connect(function()
		if player:GetAttribute("Alive") == false then
			-- give the Caught remote a moment to start the jumpscare first
			task.delay(0.25, refresh)
		else
			refresh()
		end
	end)
	if matchState then
		matchState:GetAttributeChangedSignal("Phase"):Connect(refresh)
	end
	Players.PlayerRemoving:Connect(function(p)
		if p == target then
			task.defer(refresh)
		end
	end)
	RunService:BindToRenderStep("DWG_SpectateOrbit", Enum.RenderPriority.Camera.Value + 2, function(dt)
		stepOrbit(dt)
		stepHidden()
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			refresh()
		end
	end)
	refresh()
end

return SpectateController
