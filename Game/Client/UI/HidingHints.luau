--!strict
-- HidingHints (Match)
-- Little storybook "closed eye" badges that mark hiding spots once Grandma is awake, so
-- players know where to run. One BillboardGui per Model tagged "HidingSpot", hung at the
-- server's Front.HidePromptAnchor (fallback: between Front and Inside, +2.8 studs).
--
-- Shown only when ALL of these hold (checked at ~5 Hz, never per frame):
--   · Phase "Night" and Grandma awake (workspace.Grandma.State, else MatchState.GrandmaState,
--     is not Asleep / FakeSleep)
--   · you're alive and not hidden yourself
--   · the spot's Hide prompt is Enabled (disabled = locked area or someone is inside)
--   · the Hide prompt itself isn't on screen (the prompt takes over up close)
--   · within FAR studs of the camera; occluded spots only show faintly within NEAR studs
-- The badge breathes gently while she's searching and pulses red while she's chasing.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))
local UIState = require(script.Parent:WaitForChild("UIState"))

local C = Theme.Color
local HidingHints = {}

local TICK = 0.2
local FAR = 30 -- fully faded out beyond this
local FULL = 22 -- fully visible inside this (when in sight)
local NEAR_OCCLUDED = 16 -- through a wall: faint, and only this close
local OCCLUDED_ALPHA = 0.35
local SIZE = 58 -- design px (scaled with the UI)

local ASLEEP = { Asleep = true, FakeSleep = true, [""] = true }
local CHASE = { Chasing = true, Attacking = true }

type Hint = {
	Model: Model,
	Gui: BillboardGui,
	Adornee: Instance,
	Prompt: ProximityPrompt?,
	Parts: { { Inst: Instance, Prop: string, Base: number } },
	Alpha: NumberValue,
	Target: number,
	Scale: UIScale,
	Ring: UIStroke,
	PromptShown: boolean,
}

local hints: { [Model]: Hint } = {}
local pulseMode = "" -- "", "Calm", "Chase"
local pulseTweens: { Tween } = {}

local function findAnchor(model: Model): (Instance?, ProximityPrompt?)
	local front = model:FindFirstChild("Front", true)
	local inside = model:FindFirstChild("Inside", true)
	local att = front and front:FindFirstChild("HidePromptAnchor")
	if att and att:IsA("Attachment") then
		return att, att:FindFirstChildOfClass("ProximityPrompt")
	end
	if front and front:IsA("BasePart") then
		-- No server anchor yet: make a local one at eye level on the spot's face.
		local a = Instance.new("Attachment")
		a.Name = "HideHintAnchor"
		a.Parent = front
		local mid = if inside and inside:IsA("BasePart") then front.Position:Lerp(inside.Position, 0.5) else front.Position
		local y = if inside and inside:IsA("BasePart") then math.max(front.Position.Y + 2.8, inside.Position.Y) else front.Position.Y + 2.8
		a.WorldPosition = Vector3.new(mid.X, y, mid.Z)
		return a, model:FindFirstChildWhichIsA("ProximityPrompt", true)
	end
	return nil, nil
end

-- The spot's Hide prompt (server-made; Enabled = false while locked or occupied).
local function findPrompt(model: Model): ProximityPrompt?
	for _, d in model:GetDescendants() do
		if d:IsA("ProximityPrompt") and d:GetAttribute("Kind") == "Hide" then
			return d
		end
	end
	return nil
end

local function applyAlpha(h: Hint, a: number)
	for _, p in h.Parts do
		(p.Inst :: any)[p.Prop] = 1 - (1 - p.Base) * a
	end
	h.Gui.Enabled = a > 0.02
end

local function buildGui(model: Model, adornee: Instance): Hint
	local s = math.clamp(UIState.Scale, 0.6, 1.2)
	local gui = UIKit.new("BillboardGui", {
		Name = "DWG_HideHint",
		Adornee = adornee,
		AlwaysOnTop = true,
		LightInfluence = 0,
		ResetOnSpawn = false,
		Active = false,
		Enabled = false,
		Size = UDim2.fromOffset(SIZE * s, SIZE * s),
		StudsOffset = Vector3.new(0, 0.5, 0),
		MaxDistance = FAR + 4,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local root = UIKit.Box({ Name = "Root", Size = UDim2.fromOffset(SIZE, SIZE), Parent = gui })
	local view = UIKit.new("UIScale", { Name = "ViewScale", Scale = s, Parent = root })
	-- one UIScale per frame: root = view scale, beat = pulse, pop = UIKit.Pop
	local beat = UIKit.Box({ Name = "Beat", Size = UDim2.fromScale(1, 1), Parent = root })
	local pulse = UIKit.new("UIScale", { Name = "Pulse", Parent = beat })
	local pop = UIKit.Box({ Name = "Pop", Size = UDim2.fromScale(1, 1), Parent = beat })

	-- hard shadow + bruise disc + ink outline (same family as the Hide prompt)
	local shadow = UIKit.new("Frame", { BackgroundColor3 = C.Shadow, BackgroundTransparency = Theme.Shadow.Transparency, Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4 + 4), Parent = pop })
	UIKit.Corner(shadow, Theme.Corner.Round)
	local disc = UIKit.new("Frame", { Name = "Disc", BackgroundColor3 = C.Bruise, Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), Rotation = -6, ZIndex = 2, Parent = pop })
	UIKit.Corner(disc, Theme.Corner.Round)
	UIKit.Stroke(disc, 3, C.Ink)
	-- outer ring that turns red and throbs during a chase
	local ringFrame = UIKit.Box({ Size = UDim2.fromScale(1, 1), ZIndex = 1, Parent = pop })
	UIKit.Corner(ringFrame, Theme.Corner.Round)
	local ring = UIKit.Stroke(ringFrame, 3, C.Paper)
	ring.Transparency = 0.35
	-- the closed eye: "shhh, in here"
	local eye = UIKit.Box({ Name = "Eye", Size = UDim2.fromScale(0.62, 0.42), Position = UDim2.fromScale(0.5, 0.46), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3, Parent = disc })
	UIIcons.EyeClosed(eye, C.Paper)
	-- a tiny tab below, like a sticker's peel corner
	local tab = UIKit.new("Frame", { BackgroundColor3 = C.Paper, Size = UDim2.fromScale(0.22, 0.14), Position = UDim2.fromScale(0.72, 0.84), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 18, ZIndex = 4, Parent = pop })
	UIKit.Corner(tab, UDim.new(0.4, 0))
	UIKit.Stroke(tab, 2, C.Ink)

	local parts: { { Inst: Instance, Prop: string, Base: number } } = {}
	for _, d in pop:GetDescendants() do
		if d:IsA("Frame") then
			if d.BackgroundTransparency < 1 then
				table.insert(parts, { Inst = d, Prop = "BackgroundTransparency", Base = d.BackgroundTransparency })
			end
		elseif d:IsA("UIStroke") then
			table.insert(parts, { Inst = d, Prop = "Transparency", Base = d.Transparency })
		end
	end
	local alpha = Instance.new("NumberValue")
	local h: Hint = {
		Model = model,
		Gui = gui,
		Adornee = adornee,
		Prompt = nil,
		Parts = parts,
		Alpha = alpha,
		Target = 0,
		Scale = pulse,
		Ring = ring,
		PromptShown = false,
	}
	alpha.Changed:Connect(function(v)
		applyAlpha(h, v)
	end)
	applyAlpha(h, 0)
	UIState.Changed:Connect(function(k)
		if k == "Scale" and gui.Parent then
			local ns = math.clamp(UIState.Scale, 0.6, 1.2)
			gui.Size = UDim2.fromOffset(SIZE * ns, SIZE * ns)
			view.Scale = ns
		end
	end)
	return h
end

local function setPulse(mode: string)
	if mode == pulseMode then
		return
	end
	pulseMode = mode
	for _, t in pulseTweens do
		t:Cancel()
	end
	table.clear(pulseTweens)
	local chase = mode == "Chase"
	for _, h in hints do
		h.Ring.Color = if chase then C.Blood else C.Paper
		h.Ring.Thickness = if chase then 5 else 3
		h.Scale.Scale = 1
		if mode ~= "" and not UIState.ReduceMotion then
			local info = if chase
				then TweenInfo.new(0.28, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
				else TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			local t = TweenService:Create(h.Scale, info, { Scale = if chase then 1.22 else 1.07 })
			t:Play()
			table.insert(pulseTweens, t)
		end
	end
end

function HidingHints.Mount(_ctx: any)
	local player = Players.LocalPlayer
	local MS = ReplicatedStorage:WaitForChild("MatchState") :: Folder

	local function grandmaState(): string
		local g = workspace:FindFirstChild("Grandma")
		local st = g and g:GetAttribute("State")
		if typeof(st) ~= "string" then
			st = MS:GetAttribute("GrandmaState")
		end
		return if typeof(st) == "string" then st else ""
	end

	local function add(model: Instance)
		if not model:IsA("Model") or hints[model] then
			return
		end
		task.spawn(function()
			-- the server hangs the Hide prompt on Front.HidePromptAnchor; give it a moment
			local front = model:WaitForChild("Front", 10)
			if front then
				front:WaitForChild("HidePromptAnchor", 5)
			end
			if hints[model] or not model.Parent then
				return
			end
			local adornee = findAnchor(model)
			if not adornee then
				return
			end
			local h = buildGui(model, adornee)
			hints[model] = h
			if pulseMode ~= "" then
				local m = pulseMode
				pulseMode = ""
				setPulse(m)
			end
		end)
	end
	local function remove(model: Instance)
		local h = hints[model :: Model]
		if h then
			hints[model :: Model] = nil
			h.Gui:Destroy()
			h.Alpha:Destroy()
		end
	end
	for _, m in CollectionService:GetTagged("HidingSpot") do
		add(m)
	end
	CollectionService:GetInstanceAddedSignal("HidingSpot"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("HidingSpot"):Connect(remove)

	-- The Hide prompt itself replaces the badge when you're close enough to use it.
	local function promptOwner(prompt: ProximityPrompt): Hint?
		for _, h in hints do
			if prompt:IsDescendantOf(h.Model) then
				return h
			end
		end
		return nil
	end
	ProximityPromptService.PromptShown:Connect(function(prompt)
		if prompt:GetAttribute("Kind") == "Hide" then
			local h = promptOwner(prompt)
			if h then
				h.PromptShown = true
			end
		end
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		if prompt:GetAttribute("Kind") == "Hide" then
			local h = promptOwner(prompt)
			if h then
				h.PromptShown = false
			end
		end
	end)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true

	local function fadeTo(h: Hint, a: number)
		if math.abs(h.Target - a) < 0.01 then
			return
		end
		local wasHidden = h.Target <= 0.01
		h.Target = a
		UIKit.Tween(h.Alpha, if a > h.Alpha.Value then 0.35 else 0.25, { Value = a })
		if wasHidden and a > 0 then
			UIKit.Pop(h.Gui:FindFirstChild("Pop", true) :: any, 0.6, 0.3)
		end
	end

	local playerGui = player:WaitForChild("PlayerGui")
	task.spawn(function()
		while true do
			task.wait(TICK)
			-- respawn wipes non-persistent PlayerGui children: keep ours parented
			if not playerGui.Parent then
				playerGui = player:FindFirstChildOfClass("PlayerGui") or playerGui
			end
			local st = grandmaState()
			local awake = MS:GetAttribute("Phase") == "Night" and not ASLEEP[st]
			local me = player:GetAttribute("Alive") ~= false and player:GetAttribute("Hidden") ~= true and player.Character ~= nil
			local on = awake and me
			setPulse(if not on then "" elseif CHASE[st] then "Chase" else "Calm")

			local cam = workspace.CurrentCamera
			local camPos = cam and cam.CFrame.Position
			if on and camPos then
				local exclude: { Instance } = {}
				for _, p in Players:GetPlayers() do
					if p.Character then
						table.insert(exclude, p.Character)
					end
				end
				local g = workspace:FindFirstChild("Grandma")
				if g then
					table.insert(exclude, g)
				end
				for _, h in hints do
					table.insert(exclude, h.Model)
				end
				rayParams.FilterDescendantsInstances = exclude
			end

			for model, h in hints do
				if h.Gui.Parent ~= playerGui then
					h.Gui.Parent = playerGui
				end
				if not h.Prompt or not h.Prompt.Parent then
					h.Prompt = findPrompt(model)
				end
				local a = 0
				local prompt = h.Prompt
				local usable = prompt == nil or prompt.Enabled
				if on and camPos and usable and not h.PromptShown then
					local pos = (h.Adornee :: any).WorldPosition or (h.Adornee :: any).Position
					if typeof(pos) == "Vector3" then
						local dist = (pos - camPos).Magnitude
						if dist < FAR then
							local k = math.clamp((FAR - dist) / (FAR - FULL), 0, 1)
							local hit = workspace:Raycast(camPos, pos - camPos, rayParams)
							if hit == nil then
								a = k
							elseif dist < NEAR_OCCLUDED then
								a = OCCLUDED_ALPHA
							end
						end
					end
				end
				fadeTo(h, a)
			end
		end
	end)
end

return HidingHints
