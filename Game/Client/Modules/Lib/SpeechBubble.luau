--!strict
-- SpeechBubble
-- Storybook speech bubble above a part (Grandma's voice lines).
--   SpeechBubble.Show(adornee, text, opts?)   opts = { Scary: boolean?, Duration: number?, ReduceMotion: boolean? }
-- One bubble per adornee; a new line replaces the old one. Paper card, Ink outline, hard
-- offset shadow, pops in with overshoot and wobbles; the scary variant (chasing) is red,
-- Creepster and shakes.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local SpeechBubble = {}

local INK = Color3.fromRGB(42, 26, 36)
local PAPER = Color3.fromRGB(243, 233, 210)
local BLOOD = Color3.fromRGB(168, 50, 62)
local BLOOD_DARK = Color3.fromRGB(92, 18, 30)

local active: { [Instance]: () -> () } = {}

local function folder(): Instance
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local f = pg:FindFirstChild("GrandmaBubbles")
	if not f then
		f = Instance.new("Folder")
		f.Name = "GrandmaBubbles"
		f.Parent = pg
	end
	return f
end

local function corner(parent: Instance, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(r, 0)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, th: number): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = th
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

function SpeechBubble.Show(adornee: BasePart, text: string, opts: { [string]: any }?)
	local o = opts or {}
	local scary = o.Scary == true
	local duration = o.Duration or (3 + math.min(2, #text / 30))
	local calm = o.ReduceMotion == true

	local prev = active[adornee]
	if prev then
		prev()
	end

	local w, h = if scary then 300 else 250, if scary then 104 else 88
	local bb = Instance.new("BillboardGui")
	bb.Name = "GrandmaSays"
	bb.Adornee = adornee
	bb.Size = UDim2.fromOffset(w, h + 16)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.2 + adornee.Size.Y * 0.5, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 80
	bb.AlwaysOnTop = false -- walls hide her voice bubble: never reveal her position
	bb.ResetOnSpawn = false
	bb.ClipsDescendants = false

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.AnchorPoint = Vector2.new(0.5, 1)
	root.Position = UDim2.new(0.5, 0, 1, 0)
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = bb
	local scale = Instance.new("UIScale")
	scale.Scale = 0.2
	scale.Parent = root

	local baseRot = (math.random() * 2 - 1) * 3
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.BackgroundColor3 = INK
	shadow.BackgroundTransparency = 0.6
	shadow.BorderSizePixel = 0
	shadow.Size = UDim2.new(1, -8, 1, -20)
	shadow.Position = UDim2.fromOffset(4, 9)
	shadow.Rotation = baseRot
	shadow.ZIndex = 1
	corner(shadow, 0.35)
	shadow.Parent = root

	-- tail (a rotated square peeking out under the bubble)
	local tail = Instance.new("Frame")
	tail.Name = "Tail"
	tail.BackgroundColor3 = if scary then PAPER else PAPER
	tail.BorderSizePixel = 0
	tail.Size = UDim2.fromOffset(18, 18)
	tail.AnchorPoint = Vector2.new(0.5, 0.5)
	tail.Position = UDim2.new(0.38, 0, 1, -16)
	tail.Rotation = 45
	tail.ZIndex = 2
	local tailStroke = stroke(tail, if scary then BLOOD_DARK else INK, 3)
	tail.Parent = root

	local bubble = Instance.new("Frame")
	bubble.Name = "Bubble"
	bubble.BackgroundColor3 = PAPER
	bubble.BorderSizePixel = 0
	bubble.Size = UDim2.new(1, -8, 1, -20)
	bubble.Position = UDim2.fromOffset(0, 2)
	bubble.Rotation = baseRot
	bubble.ZIndex = 3
	corner(bubble, 0.35)
	local bubbleStroke = stroke(bubble, if scary then BLOOD_DARK else INK, 3)
	bubble.Parent = root
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = bubble

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.FontFace = Font.fromEnum(if scary then Enum.Font.Creepster else Enum.Font.PatrickHand)
	label.Text = text
	label.TextColor3 = if scary then BLOOD else INK
	label.TextScaled = true
	label.TextWrapped = true
	label.ZIndex = 4
	local tsc = Instance.new("UITextSizeConstraint")
	tsc.MaxTextSize = if scary then 34 else 26
	tsc.MinTextSize = 12
	tsc.Parent = label
	label.Parent = bubble

	bb.Parent = folder()

	-- pop in: 0.2 -> 1.08 -> 1
	local pop = TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.08 })
	pop:Play()
	pop.Completed:Once(function()
		TweenService:Create(scale, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { Scale = 1 }):Play()
	end)

	local alive = true
	local conn: RBXScriptConnection? = nil
	if not calm then
		local t0 = os.clock()
		local nextShake = 0
		conn = RunService.Heartbeat:Connect(function()
			local t = os.clock() - t0
			local rot = baseRot + math.sin(t * 3.1) * 1.8
			if scary and os.clock() > nextShake then
				nextShake = os.clock() + 0.045
				root.Position = UDim2.new(0.5, math.random(-3, 3), 1, math.random(-3, 3))
				rot += math.random(-40, 40) / 10
			end
			bubble.Rotation = rot
			shadow.Rotation = rot
		end)
	end

	local function kill()
		if not alive then
			return
		end
		alive = false
		if conn then
			conn:Disconnect()
		end
		if active[adornee] == kill then
			active[adornee] = nil
		end
		bb:Destroy()
	end
	active[adornee] = kill

	task.delay(duration, function()
		if not alive then
			return
		end
		local info = TweenInfo.new(0.4, Enum.EasingStyle.Quad)
		TweenService:Create(bubble, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(shadow, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(tail, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(label, info, { TextTransparency = 1 }):Play()
		TweenService:Create(bubbleStroke, info, { Transparency = 1 }):Play()
		TweenService:Create(tailStroke, info, { Transparency = 1 }):Play()
		TweenService:Create(scale, info, { Scale = 0.85 }):Play()
		task.delay(0.45, kill)
	end)
	adornee.AncestryChanged:Once(function()
		if not adornee:IsDescendantOf(workspace) then
			kill()
		end
	end)
end

function SpeechBubble.Clear(adornee: Instance)
	local k = active[adornee]
	if k then
		k()
	end
end

return SpeechBubble
