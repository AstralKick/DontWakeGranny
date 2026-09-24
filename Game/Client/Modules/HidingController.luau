--!strict
-- HidingController (Match)
-- Remote HidingState(hidden, kind): first-person view from inside the spot, looking out with
-- restricted look angles; your own body hidden locally. Fires ClientBus "HidingChanged".
-- While hidden (and no breath check): E / gamepad B leave the spot (UI touch buttons fire
-- ClientBus "LeaveHiding", handled by InputController).
--
-- Hold Your Breath: remote HoldBreath(id, duration) -> ClientBus "HoldBreathStart"(duration).
-- Held via ClientBus "HoldBreathInput"(isDown) (touch button) or Space / E / ButtonA / ButtonX.
-- Success = held continuously from within 0.5 s of the start until the end; releasing early
-- fails immediately. Answers HoldBreath:FireServer(id, success) and fires
-- ClientBus "HoldBreathEnd"(success). The world is muffled + heartbeat while it runs.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local PlaceRole = shared("PlaceRole")
local ClientBus = shared("ClientBus")

local HidingController = {}

local player = Players.LocalPlayer
local PRIORITY = Enum.ContextActionPriority.High.Value + 10
local GRACE = 0.5

local LOOK_LIMITS: { [string]: { number } } = { -- yaw, pitch (degrees)
	Bed = { 70, 22 },
	Cabinet = { 45, 30 },
	Closet = { 50, 35 },
	Wardrobe = { 50, 35 },
}

local camCtl: any = nil
local music: any = nil
local effects: any = nil
local holdRemote: RemoteEvent? = nil
local leaveRemote: RemoteEvent? = nil

local hidden = false
local kind: string? = nil

type Breath = { Id: any, Start: number, Duration: number, Sources: { [string]: boolean }, WasHeld: boolean, Done: boolean }
local breath: Breath? = nil

local function isHeld(b: Breath): boolean
	return next(b.Sources) ~= nil
end

-- ------------------------------------------------------------------ hold breath

local function endBreath(success: boolean, send: boolean)
	local b = breath
	if not b or b.Done then
		return
	end
	b.Done = true
	breath = nil
	ContextActionService:UnbindAction("DWG_HoldBreath")
	if send and holdRemote then
		holdRemote:FireServer(b.Id, success)
	end
	if music then
		music:SetMuffle("Breath", 0)
		music:SetHeartbeat("Breath", 0)
		if hidden then
			music:SetMuffle("Hidden", 0.3)
		end
	end
	if effects then
		effects:SetVignette("Dark", "Breath", 0)
		if not success then
			effects:FlashEdge("Red", 0.6, 0.6)
		end
	end
	ClientBus.Fire("HoldBreathEnd", success)
end

local function setSource(source: string, down: boolean)
	local b = breath
	if not b or b.Done then
		return
	end
	if down then
		b.Sources[source] = true
		b.WasHeld = true
	else
		b.Sources[source] = nil
		if b.WasHeld and not isHeld(b) then
			endBreath(false, true) -- let go too early
		end
	end
end

local function stepBreath()
	local b = breath
	if not b or b.Done then
		return
	end
	local t = os.clock() - b.Start
	local held = isHeld(b)
	if not held and t > GRACE then
		endBreath(false, true)
		return
	end
	if music then
		music:SetHeartbeat("Breath", if held then 1 else 0.6)
		music:SetMuffle("Breath", if held then 1 else 0.4)
	end
	if effects then
		effects:SetVignette("Dark", "Breath", if held then 0.55 + 0.1 * math.sin(t * 5) else 0.3)
	end
	if t >= b.Duration then
		endBreath(held, true)
	end
end

local function onHoldBreath(id: any, duration: any)
	if breath then
		endBreath(false, false)
	end
	local d = tonumber(duration) or 2.4
	local b: Breath = { Id = id, Start = os.clock(), Duration = d, Sources = {}, WasHeld = false, Done = false }
	breath = b
	ContextActionService:UnbindAction("DWG_LeaveHiding")
	ContextActionService:BindActionAtPriority("DWG_HoldBreath", function(_, state, input)
		local src = input.KeyCode.Name
		if state == Enum.UserInputState.Begin then
			setSource(src, true)
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			setSource(src, false)
		end
		return Enum.ContextActionResult.Sink
	end, false, PRIORITY, Enum.KeyCode.Space, Enum.KeyCode.E, Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonX)
	ClientBus.Fire("HoldBreathStart", d)
end

-- ------------------------------------------------------------------ hiding

local function bindLeave()
	ContextActionService:BindActionAtPriority("DWG_LeaveHiding", function(_, state)
		if state == Enum.UserInputState.Begin and hidden and not breath and leaveRemote then
			leaveRemote:FireServer()
		end
		return Enum.ContextActionResult.Sink
	end, false, PRIORITY, Enum.KeyCode.E, Enum.KeyCode.ButtonB)
end

-- While hidden, the spot you're in turns mostly see-through (locally) so you can peek out
-- through the slat overlay and watch Grandma walk by.
local peekParts: { BasePart } = {}

local function setPeek(on: boolean)
	for _, p in peekParts do
		if p.Parent then
			p.LocalTransparencyModifier = 0
		end
	end
	table.clear(peekParts)
	if not on then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local best, bestDist = nil, 6
	for _, m in game:GetService("CollectionService"):GetTagged("HidingSpot") do
		local inside = m:FindFirstChild("Inside", true) :: BasePart?
		if inside and (inside.Position - root.Position).Magnitude < bestDist then
			best, bestDist = m, (inside.Position - root.Position).Magnitude
		end
	end
	if best then
		for _, d in best:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency < 1 then
				d.LocalTransparencyModifier = 0.82
				table.insert(peekParts, d)
			end
		end
	end
end

local function onHidingState(isHidden: any, k: any)
	local nowHidden = isHidden == true
	kind = if typeof(k) == "string" then k else nil
	if nowHidden == hidden then
		return
	end
	hidden = nowHidden
	task.defer(setPeek, hidden)
	if hidden then
		camCtl:SetFlag("Hiding", true, kind)
		local lim = LOOK_LIMITS[kind or ""] or { 55, 35 }
		-- face out of the spot (the server has placed our root at Inside, facing out)
		task.defer(function()
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local cam = workspace.CurrentCamera
			if root and cam then
				camCtl:SetLookClamp(root.CFrame, lim[1], lim[2])
				cam.CFrame = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + root.CFrame.LookVector)
			end
		end)
		if music then
			music:SetMuffle("Hidden", 0.3)
		end
		task.delay(0.35, function()
			if hidden and not breath then
				bindLeave()
			end
		end)
	else
		endBreath(false, false)
		ContextActionService:UnbindAction("DWG_LeaveHiding")
		camCtl:SetFlag("Hiding", false)
		if music then
			music:SetMuffle("Hidden", 0)
		end
	end
	ClientBus.Fire("HidingChanged", hidden, if hidden then kind else nil)
end

function HidingController:IsHidden(): boolean
	return hidden
end

function HidingController:IsHoldingBreathCheck(): boolean
	return breath ~= nil
end

function HidingController.Preload() end

function HidingController:Start()
	if not PlaceRole.IsMatch then
		return
	end
	camCtl = shared("CameraController")
	music = shared("MusicController")
	effects = shared("EffectsController")

	ClientBus.On("HoldBreathInput", function(isDown: boolean)
		setSource("UI", isDown == true)
	end)
	-- If our body is removed / we're caught, drop out of hiding locally.
	player:GetAttributeChangedSignal("Alive"):Connect(function()
		if player:GetAttribute("Alive") == false and hidden then
			onHidingState(false, kind)
		end
	end)
	player.CharacterRemoving:Connect(function()
		if hidden then
			onHidingState(false, kind)
		end
	end)
	RunService.Heartbeat:Connect(stepBreath)

	local Net = shared("Net")
	holdRemote = Net.Event("HoldBreath")
	leaveRemote = Net.Event("LeaveHiding")
	Net.Event("HidingState").OnClientEvent:Connect(onHidingState)
	;(holdRemote :: RemoteEvent).OnClientEvent:Connect(onHoldBreath)
end

return HidingController
