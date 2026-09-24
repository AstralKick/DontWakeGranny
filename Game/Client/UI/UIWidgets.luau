--!strict
-- UIWidgets
-- Composite widgets shared by several screens.
--   UIWidgets.CandyAmount{Parent, Amount, TextSize, Color, Prefix} -> {Instance, Label, Set(n, animate?)}
--   UIWidgets.Glyph{Parent, Key, Pad, Size}  -> input-aware key cap / gamepad button / "TAP"
--   UIWidgets.GrandmaFace{Parent, Size}      -> {Instance, SetState(mood), SetAlert(frac)}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))
local UIState = require(script.Parent:WaitForChild("UIState"))

local C = Theme.Color
local UIWidgets = {}

local function fmtNumber(n: number): string
	n = math.floor(n + 0.5)
	local s = tostring(math.abs(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if s:sub(1, 1) == "," then
		s = s:sub(2)
	end
	return (if n < 0 then "-" else "") .. s
end
UIWidgets.Number = fmtNumber

-- ---------------------------------------------------------------- candy amount

function UIWidgets.CandyAmount(p: { [string]: any }): any
	local size = p.TextSize or Theme.Text.Body
	local row = UIKit.Box({
		Name = p.Name or "Candy",
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, size + 8),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		Parent = p.Parent,
	})
	UIKit.List(row, { Dir = Enum.FillDirection.Horizontal, Gap = 6, V = Enum.VerticalAlignment.Center, H = p.H or Enum.HorizontalAlignment.Left })
	local prefix = p.Prefix or ""
	local label = UIKit.Label({
		Name = "Amount",
		Text = prefix .. fmtNumber(p.Amount or 0),
		Font = p.Font or Theme.Font.Title,
		TextSize = size,
		Color = p.Color or C.Mustard,
		Auto = "X",
		Size = UDim2.fromOffset(0, size + 6),
		LayoutOrder = 1,
		Parent = row,
	})
	local icon = UIKit.Box({ Name = "Icon", Size = UDim2.fromOffset(size * 1.3, size * 0.95), LayoutOrder = 2, Parent = row })
	UIIcons.Candy(icon)
	local obj = {} :: any
	obj.Instance = row
	obj.Label = label
	obj.Value = p.Amount or 0
	function obj.Set(self: any, n: number, animate: boolean?)
		local from = self.Value
		self.Value = n
		if animate and n ~= from then
			UIKit.CountUp(label, from, n, 0.8, function(v)
				return prefix .. fmtNumber(v)
			end)
			UIKit.Pop(icon :: any, 1.35)
		else
			label.Text = prefix .. fmtNumber(n)
		end
	end
	function obj.SetPrefix(_self: any, s: string)
		prefix = s
	end
	return obj
end

-- ---------------------------------------------------------------- input glyph

local KEY_NAMES = {
	LeftShift = "SHIFT",
	RightShift = "SHIFT",
	LeftControl = "CTRL",
	Space = "SPACE",
	Return = "ENTER",
	Tab = "TAB",
}

-- props: Parent, Key (Enum.KeyCode keyboard), Pad (Enum.KeyCode gamepad), Size (px),
-- Position, AnchorPoint, LayoutOrder, TouchText
function UIWidgets.Glyph(p: { [string]: any }): any
	local size = p.Size or 56
	local holder = UIKit.Box({
		Name = "Glyph",
		Size = UDim2.fromOffset(size, size),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		ZIndex = p.ZIndex or 1,
		Parent = p.Parent,
	})
	local cap = UIKit.new("Frame", { Name = "Cap", BackgroundColor3 = C.Paper, Size = UDim2.fromScale(1, 1), ZIndex = holder.ZIndex, Parent = holder })
	local capCorner = UIKit.Corner(cap, UDim.new(0.26, 0))
	UIKit.Stroke(cap, 3, C.Ink)
	-- key cap bottom lip
	local lip = UIKit.new("Frame", { Name = "Lip", BackgroundColor3 = C.PaperDim, Size = UDim2.new(1, 0, 0.2, 0), Position = UDim2.fromScale(0, 0.8), ZIndex = holder.ZIndex, Parent = cap })
	UIKit.Corner(lip, UDim.new(0.5, 0))
	local text = UIKit.Label({
		Name = "Text",
		Font = Theme.Font.Button,
		TextSize = math.floor(size * 0.52),
		Color = C.Ink,
		Stroke = false,
		ZIndex = holder.ZIndex + 1,
		Size = UDim2.fromScale(1, 0.9),
		Parent = cap,
	})
	local image = UIKit.new("ImageLabel", {
		Name = "Pad",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1.1, 1.1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = holder.ZIndex + 2,
		Visible = false,
		Parent = holder,
	})

	local obj = {} :: any
	obj.Instance = holder
	obj.Key = p.Key or Enum.KeyCode.E
	obj.Pad = p.Pad or Enum.KeyCode.ButtonX

	local function render()
		local kind = UIState.Input
		image.Visible = false
		cap.Visible = true
		lip.Visible = true
		capCorner.CornerRadius = UDim.new(0.26, 0)
		if kind == "Gamepad" then
			local ok, img = pcall(UserInputService.GetImageForKeyCode, UserInputService, obj.Pad)
			if ok and img and img ~= "" then
				image.Image = img
				image.Visible = true
				cap.Visible = false
			else
				text.Text = (obj.Pad :: Enum.KeyCode).Name:gsub("Button", "")
				capCorner.CornerRadius = UDim.new(0.5, 0)
				lip.Visible = false
			end
		elseif kind == "Touch" then
			text.Text = p.TouchText or "TAP"
			text.TextSize = math.floor(size * 0.34)
			capCorner.CornerRadius = UDim.new(0.5, 0)
			lip.Visible = false
		else
			local name = (obj.Key :: Enum.KeyCode).Name
			text.Text = KEY_NAMES[name] or name
			text.TextSize = math.floor(size * (if #text.Text > 1 then 0.3 else 0.52))
		end
	end
	obj.Render = render
	function obj.SetKeys(_self: any, key: Enum.KeyCode?, pad: Enum.KeyCode?)
		obj.Key = key or obj.Key
		obj.Pad = pad or obj.Pad
		render()
	end
	render()
	local conn = UIState.Changed:Connect(function(k)
		if k == "Input" then
			render()
		end
	end)
	holder.Destroying:Connect(function()
		conn:Disconnect()
	end)
	return obj
end

-- ---------------------------------------------------------------- grandma face

-- The signature HUD element: a cute sleeping Granny that stirs, then stares.
-- Moods: "Asleep" | "Stirring" | "Awake" | "Chase" | "Distracted"
function UIWidgets.GrandmaFace(p: { [string]: any }): any
	local size = p.Size or 160
	local holder = UIKit.Box({
		Name = "GrandmaMeter",
		Size = UDim2.fromOffset(size, size),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		Parent = p.Parent,
	})
	-- backing disc + hard shadow
	local shadow = UIKit.new("Frame", { BackgroundColor3 = C.Shadow, BackgroundTransparency = Theme.Shadow.Transparency, Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, Theme.Shadow.Offset), Parent = holder })
	UIKit.Corner(shadow, Theme.Corner.Round)
	local disc = UIKit.new("Frame", { BackgroundColor3 = C.Night, Size = UDim2.fromScale(1, 1), ZIndex = 1, Parent = holder })
	UIKit.Corner(disc, Theme.Corner.Round)
	UIKit.Stroke(disc, Theme.Stroke.Panel, C.Ink)

	local ring = UIKit.Ring({ Parent = holder, Size = size - 10, Thickness = 11, Position = UDim2.fromOffset(5, 5), Color = C.Mint, Track = C.NightDeep, ZIndex = 2 })

	-- The face itself (never rotate the ring's ancestors; the face frame is a sibling).
	local faceSize = math.floor(size * 0.66)
	local head = UIKit.new("Frame", {
		Name = "Head",
		BackgroundColor3 = Color3.fromRGB(236, 205, 188),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.54),
		Size = UDim2.fromOffset(faceSize, math.floor(faceSize * 0.94)),
		ZIndex = 4,
		Parent = holder,
	})
	UIKit.Corner(head, UDim.new(0.48, 0))
	UIKit.Stroke(head, 3, C.Ink)
	local hairColor = Color3.fromRGB(196, 190, 205)
	-- bun: a sibling behind the head (children always draw above their parent)
	local bun = UIIcons.Blob(holder, hairColor, 0.5, 0.2, 0.3, 0.24, 0.5, 0, 3, 0)
	bun.ZIndex = 3
	UIIcons.Blob(head, hairColor, 0.5, 0.1, 1.04, 0.36, 0.5, 0, 3, 1) -- fringe
	UIIcons.Blob(head, hairColor, 0.08, 0.42, 0.22, 0.4, 0.5, 8, 3, 1)
	UIIcons.Blob(head, hairColor, 0.92, 0.42, 0.22, 0.4, 0.5, -8, 3, 1)
	UIIcons.Blob(head, C.Rose, 0.2, 0.7, 0.16, 0.1, 0.5, 0, 0, 1).BackgroundTransparency = 0.35
	UIIcons.Blob(head, C.Rose, 0.8, 0.7, 0.16, 0.1, 0.5, 0, 0, 1).BackgroundTransparency = 0.35

	local eyes = {}
	for i, x in { 0.32, 0.68 } do
		-- glasses rim
		local rim = UIIcons.Blob(head, C.Paper, x, 0.5, 0.34, 0.34, 0.5, 0, 3, 2)
		rim.BackgroundTransparency = 0.55
		local closed = UIIcons.Blob(rim, C.Ink, 0.5, 0.55, 0.7, 0.12, 0.5, if i == 1 then 8 else -8, 0, 2)
		local white = UIIcons.Blob(rim, C.Paper, 0.5, 0.5, 0.8, 0.8, 0.5, 0, 2, 2)
		local pupil = UIIcons.Blob(white, C.Ink, 0.5, 0.5, 0.42, 0.42, 0.5, 0, 0, 3)
		local lid = UIIcons.Blob(white, Color3.fromRGB(226, 190, 172), 0.5, 0.2, 1.05, 0.6, 0.2, 0, 0, 4)
		eyes[i] = { Rim = rim, Closed = closed, White = white, Pupil = pupil, Lid = lid }
	end
	UIIcons.Blob(head, C.Ink, 0.5, 0.5, 0.1, 0.05, 0.5, 0, 0, 3) -- glasses bridge
	local mouth = UIIcons.Blob(head, C.Ink, 0.5, 0.82, 0.22, 0.06, 0.5, 0, 0, 3)

	local zzz = UIKit.Label({
		Name = "Zzz",
		Text = "z<font size=\"30\">z</font><font size=\"38\">Z</font>",
		Rich = true,
		Font = Theme.Font.Title,
		TextSize = 24,
		Color = C.Paper,
		Size = UDim2.fromOffset(80, 50),
		Position = UDim2.new(1, -18, 0, -6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 8,
		Rotation = -12,
		Parent = holder,
	})
	local run = UIKit.Label({
		Name = "Run",
		Text = "RUN!",
		Font = Theme.Font.Creep,
		TextSize = 64,
		Color = C.Blood,
		StrokeColor = C.Ink,
		Stroke = 4,
		Size = UDim2.fromOffset(220, 70),
		Position = UDim2.new(0.5, 0, 1, 18),
		AnchorPoint = Vector2.new(0.5, 0),
		ZIndex = 8,
		Visible = false,
		Parent = holder,
	})
	local runScale = UIKit.ScaleOf(run)

	local obj = {} :: any
	obj.Instance = holder
	obj.Mood = ""
	local alert = 0
	local zzzTween: Tween? = nil
	local runTween: Tween? = nil
	local shakeUntil = 0

	local function setEyes(mode: string)
		for _, e in eyes do
			e.Closed.Visible = mode == "closed"
			e.White.Visible = mode ~= "closed"
			e.Lid.Visible = mode == "half"
			e.White.BackgroundColor3 = if mode == "red" then Color3.fromRGB(255, 214, 214) else C.Paper
			e.Pupil.BackgroundColor3 = if mode == "red" then C.Blood else C.Ink
			e.Pupil.Size = if mode == "red" then UDim2.fromScale(0.32, 0.32) else UDim2.fromScale(0.42, 0.42)
		end
	end

	function obj.SetState(_self: any, mood: string)
		if mood == obj.Mood then
			return
		end
		local prev = obj.Mood
		obj.Mood = mood
		if zzzTween then
			zzzTween:Cancel()
			zzzTween = nil
		end
		if runTween then
			runTween:Cancel()
			runTween = nil
		end
		zzz.Visible = mood == "Asleep" or mood == "Distracted"
		run.Visible = mood == "Chase"
		head.Rotation = 0
		if mood == "Asleep" or mood == "Distracted" then
			setEyes("closed")
			mouth.Size = UDim2.fromScale(if mood == "Distracted" then 0.3 else 0.2, 0.06)
			mouth.BackgroundColor3 = C.Ink
			if not UIState.ReduceMotion then
				zzz.Position = UDim2.new(1, -18, 0, -6)
				zzz.TextTransparency = 0
				zzzTween = TweenService:Create(zzz, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, -1), { Position = UDim2.new(1, 0, 0, -30), TextTransparency = 0.8 })
				zzzTween:Play()
			end
		elseif mood == "Stirring" then
			setEyes("half")
			mouth.Size = UDim2.fromScale(0.16, 0.08)
			mouth.BackgroundColor3 = C.Ink
		else
			setEyes("red")
			mouth.Size = if mood == "Chase" then UDim2.fromScale(0.26, 0.16) else UDim2.fromScale(0.18, 0.12)
			mouth.BackgroundColor3 = if mood == "Chase" then C.Blood else C.Ink
			if prev ~= "Chase" and prev ~= "Awake" then
				UIKit.Pop(head :: any, 1.35, 0.3)
				shakeUntil = os.clock() + 0.6
			end
			if mood == "Chase" and not UIState.ReduceMotion then
				runScale.Scale = 1
				runTween = TweenService:Create(runScale, TweenInfo.new(0.32, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.18 })
				runTween:Play()
				UIKit.Pop(run :: any, 0.4)
			end
		end
	end

	function obj.SetAlert(_self: any, frac: number)
		alert = math.clamp(frac, 0, 1)
		ring:Set(alert)
		local col = if alert < 0.45 then C.Mint:Lerp(C.Mustard, alert / 0.45) else C.Mustard:Lerp(C.Blood, (alert - 0.45) / 0.55)
		ring:SetColor(col)
	end

	-- Idle animation: stirring wobble, awake shake, sleepy breathing, glancing pupils.
	local t = 0
	function obj.Step(_self: any, dt: number)
		t += dt
		if UIState.ReduceMotion then
			head.Rotation = 0
			return
		end
		local mood = obj.Mood
		if mood == "Stirring" then
			head.Rotation = math.sin(t * 7) * (4 + alert * 6)
		elseif mood == "Awake" or mood == "Chase" then
			local k = if os.clock() < shakeUntil then 5 else (if mood == "Chase" then 2.2 else 1)
			head.Position = UDim2.new(0.5, math.random(-10, 10) * 0.1 * k, 0.54, math.random(-10, 10) * 0.1 * k)
			head.Rotation = math.sin(t * 13) * 1.5
			-- pupils dart around, never quite settling
			local px, py = 0.5 + math.sin(t * 1.7) * 0.18, 0.5 + math.cos(t * 2.3) * 0.12
			for _, e in eyes do
				e.Pupil.Position = UDim2.fromScale(px, py)
			end
		else
			head.Position = UDim2.fromScale(0.5, 0.54 + math.sin(t * 1.6) * 0.012)
			head.Rotation = math.sin(t * 0.8) * 3
		end
	end

	obj:SetState("Asleep")
	obj:SetAlert(0)
	return obj
end

return UIWidgets
