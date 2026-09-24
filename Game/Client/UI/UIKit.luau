--!strict
-- UIKit
-- Component builders for the "storybook gone wrong" look (docs/UI_STYLE.md).
-- Everything is plain Instances: no image assets. Sizes are 1080p design pixels
-- (the root UIScale does the rest, see UITheme header).
--
--   UIKit.new(class, props)                       generic builder (props.Parent / props.Children)
--   UIKit.Corner / Stroke / Pad / List / Aspect / SizeLimit
--   UIKit.Label{...}  UIKit.Title{...}
--   UIKit.Panel{...}  -> holder, content         paper card: hard shadow, tilt, tape / drip
--   UIKit.Button{...} -> button object            pill with squish press + hard shadow
--   UIKit.IconButton{...}                         round sticker button (HUD / lobby)
--   UIKit.Bar{...}    -> {Set(frac)}              pill progress bar
--   UIKit.Ring{...}   -> {Set(frac)}              radial ring drawn from 2 clipped strokes
--   UIKit.Headshot{...}
--   UIKit.Toggle{...} UIKit.Stepper{...} UIKit.Tabs{...}
--   UIKit.Tween / Pop / PopOut / Twitch / Bob / CountUp / Shake
--   UIKit.SelectionImage(kind)                   custom gamepad focus ring

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIState = require(script.Parent:WaitForChild("UIState"))

local C = Theme.Color

local UIKit = {}

-- ---------------------------------------------------------------- basics

function UIKit.new(className: string, props: { [string]: any }?): any
	local inst = Instance.new(className) :: any
	local parent, children = nil, nil
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
	end
	if props then
		for k, v in props do
			if k == "Parent" then
				parent = v
			elseif k == "Children" then
				children = v
			else
				inst[k] = v
			end
		end
	end
	if children then
		for _, c in children do
			c.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

-- Transparent layout frame.
function UIKit.Box(props: { [string]: any }): any
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	return UIKit.new("Frame", props)
end

function UIKit.Corner(parent: Instance, radius: UDim?): UICorner
	return UIKit.new("UICorner", { CornerRadius = radius or Theme.Corner.Panel, Parent = parent })
end

function UIKit.Stroke(parent: Instance, thickness: number?, color: Color3?, contextual: boolean?): UIStroke
	return UIKit.new("UIStroke", {
		Thickness = thickness or Theme.Stroke.Panel,
		Color = color or C.Ink,
		ApplyStrokeMode = if contextual then Enum.ApplyStrokeMode.Contextual else Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = parent,
	})
end

function UIKit.Pad(parent: Instance, all: number, lr: number?, tb: number?): UIPadding
	local h = UDim.new(0, lr or all)
	local v = UDim.new(0, tb or all)
	return UIKit.new("UIPadding", { PaddingLeft = h, PaddingRight = h, PaddingTop = v, PaddingBottom = v, Parent = parent })
end

function UIKit.List(parent: Instance, props: { [string]: any }?): UIListLayout
	local p = props or {}
	return UIKit.new("UIListLayout", {
		FillDirection = p.Dir or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, p.Gap or 12),
		HorizontalAlignment = p.H or Enum.HorizontalAlignment.Center,
		VerticalAlignment = p.V or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Wraps = p.Wraps == true,
		Parent = parent,
	})
end

function UIKit.Aspect(parent: Instance, ratio: number): UIAspectRatioConstraint
	return UIKit.new("UIAspectRatioConstraint", { AspectRatio = ratio, Parent = parent })
end

function UIKit.SizeLimit(parent: Instance, maxX: number, maxY: number, minX: number?, minY: number?): UISizeConstraint
	return UIKit.new("UISizeConstraint", {
		MaxSize = Vector2.new(maxX, maxY),
		MinSize = Vector2.new(minX or 0, minY or 0),
		Parent = parent,
	})
end

function UIKit.ScaleOf(obj: Instance): UIScale
	local s = obj:FindFirstChild("PopScale") :: UIScale?
	if not s then
		s = UIKit.new("UIScale", { Name = "PopScale", Parent = obj })
	end
	return s :: UIScale
end

-- ---------------------------------------------------------------- text

export type LabelProps = { [string]: any }

-- props: Text, Font, TextSize, Color, Stroke (number | false), XAlign, YAlign, Wrap,
-- Rich, Auto ("X"/"Y"/"XY"), plus any TextLabel property (Size, Position, ...).
function UIKit.Label(p: LabelProps): TextLabel
	local stroke = p.Stroke
	local props: { [string]: any } = {
		BackgroundTransparency = 1,
		FontFace = p.Font or Theme.Font.Body,
		TextSize = p.TextSize or Theme.Text.Body,
		TextColor3 = p.Color or C.Paper,
		Text = p.Text or "",
		TextWrapped = p.Wrap == true,
		RichText = p.Rich == true,
		TextXAlignment = p.XAlign or Enum.TextXAlignment.Center,
		TextYAlignment = p.YAlign or Enum.TextYAlignment.Center,
		Size = p.Size or UDim2.fromScale(1, 1),
	}
	if p.Auto == "X" then
		props.AutomaticSize = Enum.AutomaticSize.X
	elseif p.Auto == "Y" then
		props.AutomaticSize = Enum.AutomaticSize.Y
	elseif p.Auto == "XY" then
		props.AutomaticSize = Enum.AutomaticSize.XY
	end
	for k, v in p do
		if
			k ~= "Font" and k ~= "Color" and k ~= "Stroke" and k ~= "XAlign" and k ~= "YAlign"
			and k ~= "Wrap" and k ~= "Rich" and k ~= "Auto" and k ~= "StrokeColor" and k ~= "Crooked"
		then
			props[k] = v
		end
	end
	local label = UIKit.new("TextLabel", props)
	if stroke ~= false then
		UIKit.Stroke(label, if typeof(stroke) == "number" then stroke else Theme.Stroke.Text, p.StrokeColor or C.Ink, true)
	end
	return label
end

-- Chunky title: LuckiestGuy + thick ink stroke. A "Wobble" letter can be nudged
-- (the deliberately misaligned letter) by passing Crooked = index.
function UIKit.Title(p: LabelProps): TextLabel
	p.Font = p.Font or Theme.Font.Title
	p.TextSize = p.TextSize or Theme.Text.Title
	p.Stroke = p.Stroke or 4
	local crooked = p.Crooked
	p.Crooked = nil
	if crooked and typeof(p.Text) == "string" then
		-- Drop one letter slightly, like a sticker applied by a kid.
		local t = p.Text :: string
		local i = math.clamp(crooked, 1, #t)
		p.Rich = true
		p.Text = t:sub(1, i - 1) .. `<font size="{math.floor((p.TextSize :: number) * 1.08)}">` .. t:sub(i, i) .. "</font>" .. t:sub(i + 1)
	end
	return UIKit.Label(p)
end

-- ---------------------------------------------------------------- tweens & motion

function UIKit.Tween(obj: Instance, time: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?, delay: number?): Tween
	local tw = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out, 0, false, delay or 0), props)
	tw:Play()
	return tw
end

-- Open: 0.8 -> overshoot -> 1 (Back easing does the overshoot).
function UIKit.Pop(obj: GuiObject, from: number?, time: number?)
	local s = UIKit.ScaleOf(obj)
	if UIState.ReduceMotion then
		s.Scale = 1
		return
	end
	s.Scale = from or 0.8
	UIKit.Tween(s, time or Theme.Motion.Pop, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- Close: quick shrink. Returns the tween (connect .Completed to destroy / hide).
function UIKit.PopOut(obj: GuiObject, time: number?): Tween
	local s = UIKit.ScaleOf(obj)
	return UIKit.Tween(s, time or Theme.Motion.Close, { Scale = 0.85 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

-- A rare, short creepy jolt.
function UIKit.Twitch(obj: GuiObject, degrees: number?)
	if UIState.ReduceMotion then
		return
	end
	local base = obj.Rotation
	obj.Rotation = base + (degrees or 5) * (if math.random() < 0.5 then -1 else 1)
	task.delay(0.05, function()
		obj.Rotation = base
	end)
end

-- Fires Twitch at random intervals while obj is alive.
function UIKit.Twitcher(obj: GuiObject, minGap: number?, maxGap: number?, degrees: number?)
	task.spawn(function()
		while obj.Parent do
			task.wait(math.random(minGap or 6, maxGap or 14) + math.random())
			if obj.Parent and obj.Visible then
				UIKit.Twitch(obj, degrees)
			end
		end
	end)
end

-- Slow idle bob (±px, 3-4s loop). Only use on things that don't otherwise move.
function UIKit.Bob(obj: GuiObject, px: number?, period: number?): Tween?
	if UIState.ReduceMotion then
		return nil
	end
	local p = obj.Position
	local tw = TweenService:Create(
		obj,
		TweenInfo.new((period or 3.5) / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Position = p + UDim2.fromOffset(0, px or 3) }
	)
	tw:Play()
	return tw
end

-- Rattles a GuiObject around its current position.
function UIKit.Shake(obj: GuiObject, px: number, time: number)
	if UIState.ReduceMotion then
		return
	end
	local base = obj.Position
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < time and obj.Parent do
			local k = 1 - (os.clock() - t0) / time
			obj.Position = base + UDim2.fromOffset(math.random(-px, px) * k, math.random(-px, px) * k)
			task.wait(0.03)
		end
		obj.Position = base
	end)
end

-- Counts a label up from a to b. fmt(n) -> string.
function UIKit.CountUp(label: TextLabel, a: number, b: number, time: number, fmt: ((number) -> string)?, tick: boolean?)
	local f = fmt or function(n: number)
		return tostring(math.floor(n + 0.5))
	end
	local nv = Instance.new("NumberValue")
	nv.Value = a
	label.Text = f(a)
	local last = -1
	nv.Changed:Connect(function(v)
		label.Text = f(v)
		local step = math.floor(v / math.max(1, (b - a) / 12))
		if tick and step ~= last then
			last = step
			UIState.Play("Countdown")
		end
	end)
	local tw = UIKit.Tween(nv, time, { Value = b }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	tw.Completed:Once(function()
		label.Text = f(b)
		nv:Destroy()
	end)
end

-- ---------------------------------------------------------------- gamepad focus ring

local selectionImages: { [string]: Frame } = {}

-- A thick Rose outline that breathes, replacing the default blue box.
function UIKit.SelectionImage(kind: string?): Frame
	local key = kind or "Pill"
	local existing = selectionImages[key]
	if existing then
		return existing
	end
	local f = UIKit.new("Frame", {
		Name = "Selection" .. key,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 16, 1, 16),
		Position = UDim2.fromOffset(-8, -8),
	})
	UIKit.Corner(f, if key == "Pill" or key == "Round" then Theme.Corner.Round else Theme.Corner.Panel)
	local s = UIKit.Stroke(f, 6, C.Rose)
	-- Inner ink hairline so the rose ring reads on rose buttons too.
	local inner = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), Parent = f })
	UIKit.Corner(inner, if key == "Pill" or key == "Round" then Theme.Corner.Round else Theme.Corner.Panel)
	UIKit.Stroke(inner, 2, C.Ink)
	TweenService:Create(s, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Thickness = 9 }):Play()
	selectionImages[key] = f
	return f
end

-- ---------------------------------------------------------------- panels

-- props: Parent, Size, Position, AnchorPoint, Color, Tilt (deg), Tape (bool),
-- Drip (bool), Stitch (bool), Pad (px), Name, ZIndex, Stroke (color)
-- Returns holder, content. The paper + shadow are rotated; content is NOT (so text
-- stays crisp and ScrollingFrames can still clip).
function UIKit.Panel(p: { [string]: any }): (Frame, Frame)
	local holder = UIKit.Box({
		Name = p.Name or "Panel",
		Size = p.Size or UDim2.fromOffset(400, 300),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		Parent = p.Parent,
		ZIndex = p.ZIndex or 1,
	})
	local tilt = p.Tilt or 0
	local color = p.Color or C.Night
	local radius = p.Corner or Theme.Corner.Panel

	local shadow = UIKit.new("Frame", {
		Name = "Shadow",
		BackgroundColor3 = C.Shadow,
		BackgroundTransparency = Theme.Shadow.Transparency,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, Theme.Shadow.Offset + 2),
		Rotation = tilt,
		ZIndex = 0,
		Parent = holder,
	})
	UIKit.Corner(shadow, radius)

	local paper = UIKit.new("Frame", {
		Name = "Paper",
		BackgroundColor3 = color,
		Size = UDim2.fromScale(1, 1),
		Rotation = tilt,
		ZIndex = 1,
		Parent = holder,
	})
	UIKit.Corner(paper, radius)
	UIKit.Stroke(paper, Theme.Stroke.Panel, p.Stroke or C.Ink)

	if p.Tape then
		-- A strip of old masking tape holding the card up.
		local tape = UIKit.new("Frame", {
			Name = "Tape",
			BackgroundColor3 = C.PaperDim,
			BackgroundTransparency = 0.15,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(120, 34),
			Position = UDim2.new(0.5, math.random(-40, 40), 0, 2),
			Rotation = math.random(-7, 7),
			ZIndex = 5,
			Parent = holder,
		})
		UIKit.Corner(tape, UDim.new(0, 4))
		UIKit.Stroke(tape, 2, C.Ink).Transparency = 0.5
	end
	if p.Drip then
		-- One drip sliding off the bottom edge.
		local x = p.DripX or (0.18 + math.random() * 0.2)
		local drip = UIKit.new("Frame", {
			Name = "Drip",
			BackgroundColor3 = color,
			AnchorPoint = Vector2.new(0.5, 0),
			Size = UDim2.fromOffset(18, 34),
			Position = UDim2.new(x, 0, 1, -8),
			ZIndex = 2,
			Parent = holder,
		})
		UIKit.Corner(drip, UDim.new(0.5, 0))
		UIKit.Stroke(drip, Theme.Stroke.Panel, C.Ink)
		local bead = UIKit.new("Frame", {
			Name = "Bead",
			BackgroundColor3 = color,
			AnchorPoint = Vector2.new(0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.new(x, 0, 1, 34),
			ZIndex = 2,
			Parent = holder,
		})
		UIKit.Corner(bead, UDim.new(0.5, 0))
		UIKit.Stroke(bead, 3, C.Ink)
		if not UIState.ReduceMotion then
			TweenService:Create(bead, TweenInfo.new(2.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In, -1, false, 1.5), {
				Position = UDim2.new(x, 0, 1, 70),
				BackgroundTransparency = 1,
			}):Play()
		end
	end
	if p.Stitch then
		-- Dashed seam across the top, like the card was sewn together.
		local seam = UIKit.Box({ Name = "Stitch", Size = UDim2.new(1, -60, 0, 4), Position = UDim2.fromOffset(30, 16), Rotation = tilt, ZIndex = 2, Parent = holder })
		UIKit.List(seam, { Dir = Enum.FillDirection.Horizontal, Gap = 10, H = Enum.HorizontalAlignment.Left })
		for i = 1, 40 do
			local dash = UIKit.new("Frame", { BackgroundColor3 = C.Ink, BackgroundTransparency = 0.4, Size = UDim2.fromOffset(14, 3), LayoutOrder = i, Parent = seam })
			UIKit.Corner(dash, UDim.new(0.5, 0))
		end
	end

	local content = UIKit.Box({ Name = "Content", Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = holder })
	if p.Pad ~= false then
		UIKit.Pad(content, p.Pad or 24)
	end
	return holder, content
end

-- A small tilted tag / sticker with one line of text.
function UIKit.Tag(p: { [string]: any }): Frame
	local holder = UIKit.Box({
		Name = p.Name or "Tag",
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		Rotation = p.Tilt or 0,
		Parent = p.Parent,
		ZIndex = p.ZIndex or 1,
	})
	local face = UIKit.new("Frame", {
		Name = "Face",
		BackgroundColor3 = p.Color or C.Paper,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Parent = holder,
	})
	UIKit.Corner(face, p.Corner or Theme.Corner.Chip)
	UIKit.Stroke(face, Theme.Stroke.Thin + 1, C.Ink)
	UIKit.Pad(face, 0, 18, 8)
	UIKit.Label({
		Name = "Text",
		Text = p.Text or "",
		Font = p.Font or Theme.Font.Button,
		TextSize = p.TextSize or Theme.Text.Small,
		Color = p.TextColor or C.Ink,
		Stroke = false,
		Auto = "XY",
		Size = UDim2.fromOffset(0, 0),
		Rich = p.Rich == true,
		Parent = face,
	})
	return holder
end

-- ---------------------------------------------------------------- buttons

export type Button = {
	Instance: Frame,
	Button: TextButton,
	Label: TextLabel,
	SetText: (self: Button, text: string) -> (),
	SetEnabled: (self: Button, on: boolean) -> (),
	SetColor: (self: Button, color: Color3, textColor: Color3?) -> (),
	Destroy: (self: Button) -> (),
}

local function contrastText(color: Color3): Color3
	local lum = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	return if lum > 0.55 then C.Ink else C.Paper
end
UIKit.ContrastText = contrastText

-- props: Parent, Text, Color, TextColor, Size, Position, AnchorPoint, OnClick,
-- TextSize, LayoutOrder, Name, Font, Corner, Sound (AssetConfig key or false)
function UIKit.Button(p: { [string]: any }): Button
	local color = p.Color or C.Rose
	local off = Theme.Shadow.Offset
	local holder = UIKit.Box({
		Name = p.Name or "Button",
		Size = p.Size or UDim2.fromOffset(300, 88),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		Parent = p.Parent,
		ZIndex = p.ZIndex or 1,
	})
	local corner = p.Corner or Theme.Corner.Button
	local shadow = UIKit.new("Frame", {
		Name = "Shadow",
		BackgroundColor3 = C.Shadow,
		Size = UDim2.new(1, 0, 1, -off),
		Position = UDim2.fromOffset(0, off),
		ZIndex = 0,
		Parent = holder,
	})
	UIKit.Corner(shadow, corner)
	local face = UIKit.new("TextButton", {
		Name = "Face",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = color,
		Size = UDim2.new(1, 0, 1, -off),
		ZIndex = 1,
		Selectable = true,
		SelectionImageObject = UIKit.SelectionImage(if corner == Theme.Corner.Button then "Pill" else "Card"),
		Parent = holder,
	})
	UIKit.Corner(face, corner)
	UIKit.Stroke(face, Theme.Stroke.Panel, C.Ink)
	-- A highlight lick along the top: flat, not a gradient.
	local lick = UIKit.new("Frame", {
		Name = "Lick",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.72,
		AnchorPoint = Vector2.new(0, 0),
		Size = UDim2.new(0.28, 0, 0, 7),
		Position = UDim2.new(0.12, 0, 0, 9),
		ZIndex = 2,
		Parent = face,
	})
	UIKit.Corner(lick, UDim.new(0.5, 0))
	local label = UIKit.Label({
		Name = "Text",
		Text = p.Text or "",
		Font = p.Font or Theme.Font.Button,
		TextSize = p.TextSize or Theme.Text.Button,
		Color = p.TextColor or contrastText(color),
		Stroke = if (p.TextColor or contrastText(color)) == C.Paper then 3 else false,
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(12, -1),
		ZIndex = 3,
		Rich = true,
		Parent = face,
	})
	local scale = UIKit.new("UIScale", { Parent = face })

	local enabled = true
	local pressed = false
	local function press(down: boolean)
		if down == pressed then
			return
		end
		pressed = down
		if down then
			UIKit.Tween(face, Theme.Motion.Squish, { Position = UDim2.fromOffset(0, off - 1) }, Enum.EasingStyle.Quad)
			UIKit.Tween(scale, Theme.Motion.Squish, { Scale = 0.97 })
		else
			UIKit.Tween(face, 0.22, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
			UIKit.Tween(scale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
	local function hover(on: boolean)
		if not enabled then
			return
		end
		UIKit.Tween(scale, 0.18, { Scale = if on then 1.04 else 1 }, Enum.EasingStyle.Back)
		if on then
			UIKit.Tween(face, 0.08, { Rotation = if math.random() < 0.5 then -1.5 else 1.5 }).Completed:Once(function()
				UIKit.Tween(face, 0.25, { Rotation = 0 }, Enum.EasingStyle.Back)
			end)
		end
	end
	face.MouseButton1Down:Connect(function()
		if enabled then
			press(true)
		end
	end)
	face.MouseButton1Up:Connect(function()
		press(false)
	end)
	face.MouseEnter:Connect(function()
		hover(true)
	end)
	face.MouseLeave:Connect(function()
		press(false)
		hover(false)
	end)
	face.SelectionGained:Connect(function()
		hover(true)
	end)
	face.SelectionLost:Connect(function()
		hover(false)
	end)
	face.Activated:Connect(function()
		if not enabled then
			UIKit.Shake(holder, 4, 0.2)
			return
		end
		if not pressed then
			-- Gamepad / keyboard activation: play the whole squish.
			press(true)
			task.delay(Theme.Motion.Squish, press, false)
		else
			press(false)
		end
		if p.Sound ~= false then
			UIState.Play(p.Sound or "UIClick")
		end
		if p.OnClick then
			task.spawn(p.OnClick)
		end
	end)

	local obj = {} :: any
	obj.Instance = holder
	obj.Button = face
	obj.Label = label
	function obj.SetText(_self: any, text: string)
		label.Text = text
	end
	function obj.SetEnabled(_self: any, on: boolean)
		enabled = on
		face.BackgroundColor3 = if on then color else C.PaperDim:Lerp(C.Night, 0.35)
		label.TextTransparency = if on then 0 else 0.35
	end
	function obj.SetColor(_self: any, c: Color3, tc: Color3?)
		color = c
		face.BackgroundColor3 = c
		label.TextColor3 = tc or contrastText(c)
		local st = label:FindFirstChildOfClass("UIStroke")
		if st then
			st.Enabled = label.TextColor3 == C.Paper
		end
	end
	function obj.Destroy(_self: any)
		holder:Destroy()
	end
	return obj
end

-- Round sticker button with a drawn icon and an optional caption under it.
-- props: Parent, Size (px), Position, AnchorPoint, Color, Icon (fn(parent) -> ()),
-- Caption, OnClick, Name, LayoutOrder, Tilt
function UIKit.IconButton(p: { [string]: any }): Button
	local size = p.Size or 96
	local b = UIKit.Button({
		Parent = p.Parent,
		Name = p.Name or "IconButton",
		Size = UDim2.fromOffset(size, size + Theme.Shadow.Offset),
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		Color = p.Color or C.Paper,
		Corner = Theme.Corner.Round,
		Text = p.Text or "",
		TextSize = p.TextSize or Theme.Text.Button,
		LayoutOrder = p.LayoutOrder,
		OnClick = p.OnClick,
		Sound = p.Sound,
	})
	b.Button.SelectionImageObject = UIKit.SelectionImage("Round")
	b.Instance.Rotation = p.Tilt or 0
	local lick = b.Button:FindFirstChild("Lick") :: Frame?
	if lick then
		lick.Size = UDim2.new(0.22, 0, 0, 6)
		lick.Position = UDim2.new(0.24, 0, 0, 12)
	end
	if p.Icon then
		local host = UIKit.Box({ Name = "Icon", Size = UDim2.fromScale(0.62, 0.62), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3, Parent = b.Button })
		p.Icon(host)
	end
	if p.Caption then
		UIKit.Label({
			Name = "Caption",
			Text = p.Caption,
			Font = Theme.Font.Button,
			TextSize = Theme.Text.Small - 1, -- >= 24px at 1080p (10-ft)
			Size = UDim2.new(1, 40, 0, 26),
			Position = UDim2.new(0.5, 0, 1, 4),
			AnchorPoint = Vector2.new(0.5, 0),
			Parent = b.Instance,
		})
	end
	return b
end

-- ---------------------------------------------------------------- meters

export type Meter = { Instance: Frame, Set: (self: Meter, frac: number, animate: boolean?) -> (), Fill: Frame }

-- props: Parent, Size, Position, AnchorPoint, Color, Track
function UIKit.Bar(p: { [string]: any }): Meter
	local holder = UIKit.new("Frame", {
		Name = p.Name or "Bar",
		BackgroundColor3 = p.Track or C.NightDeep,
		Size = p.Size or UDim2.fromOffset(240, 26),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		Parent = p.Parent,
	})
	UIKit.Corner(holder, Theme.Corner.Round)
	UIKit.Stroke(holder, Theme.Stroke.Thin + 1, C.Ink)
	local fill = UIKit.new("Frame", {
		Name = "Fill",
		BackgroundColor3 = p.Color or C.Mint,
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.fromOffset(4, 4),
		Parent = holder,
	})
	UIKit.Corner(fill, Theme.Corner.Round)
	local obj = {} :: any
	obj.Instance = holder
	obj.Fill = fill
	function obj.Set(_self: any, frac: number, animate: boolean?)
		frac = math.clamp(frac, 0, 1)
		local target = UDim2.new(frac, -8 * frac, 1, -8)
		fill.Visible = frac > 0.01
		if animate then
			UIKit.Tween(fill, 0.25, { Size = target })
		else
			fill.Size = target
		end
	end
	return obj
end

-- Radial ring built from two half-clips, each holding a stroked circle whose stroke
-- carries a hard-edged UIGradient. Rotating the gradients sweeps the arc clockwise
-- from 12 o'clock. Never put this under a rotated ancestor (clipping stops working).
-- props: Parent, Size (px), Thickness, Color, Track, Position, AnchorPoint, ZIndex
function UIKit.Ring(p: { [string]: any }): Meter
	local size = p.Size or 120
	local t = p.Thickness or 10
	local holder = UIKit.Box({
		Name = p.Name or "Ring",
		Size = UDim2.fromOffset(size, size),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		ZIndex = p.ZIndex or 1,
		Parent = p.Parent,
	})
	if p.Track ~= false then
		local track = UIKit.Box({ Name = "Track", Size = UDim2.new(1, -2 * t, 1, -2 * t), Position = UDim2.fromOffset(t, t), ZIndex = holder.ZIndex, Parent = holder })
		UIKit.Corner(track, Theme.Corner.Round)
		local ts = UIKit.Stroke(track, t, p.Track or C.NightDeep)
		ts.Transparency = p.TrackTransparency or 0.2
	end
	local seq = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.501, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	local grads: { UIGradient } = {}
	local strokes: { UIStroke } = {}
	for i, side in { "Right", "Left" } do
		local clip = UIKit.Box({
			Name = side,
			ClipsDescendants = true,
			Size = UDim2.fromScale(0.5, 1),
			Position = if side == "Right" then UDim2.fromScale(0.5, 0) else UDim2.new(),
			ZIndex = holder.ZIndex + 1,
			Parent = holder,
		})
		local circle = UIKit.Box({
			Size = UDim2.new(2, -2 * t, 1, -2 * t),
			Position = if side == "Right" then UDim2.new(-1, t, 0, t) else UDim2.fromOffset(t, t),
			ZIndex = holder.ZIndex + 1,
			Parent = clip,
		})
		UIKit.Corner(circle, Theme.Corner.Round)
		local st = UIKit.Stroke(circle, t, p.Color or C.Rose)
		strokes[i] = st
		grads[i] = UIKit.new("UIGradient", { Transparency = seq, Rotation = if side == "Right" then 0 else 180, Parent = st })
	end
	local obj = {} :: any
	obj.Instance = holder
	function obj.Set(_self: any, frac: number, _animate: boolean?)
		local a = math.clamp(frac, 0, 1) * 360
		grads[1].Rotation = math.clamp(a, 0, 180)
		grads[2].Rotation = math.clamp(a, 180, 360)
	end
	function obj.SetColor(_self: any, c: Color3)
		for _, s in strokes do
			s.Color = c
		end
	end
	obj:Set(0)
	return obj
end

-- ---------------------------------------------------------------- avatars

-- props: Parent, UserId, Size (px), Position, AnchorPoint, LayoutOrder, Color
function UIKit.Headshot(p: { [string]: any }): ImageLabel
	local size = p.Size or 64
	local img = UIKit.new("ImageLabel", {
		Name = p.Name or "Headshot",
		BackgroundColor3 = p.Color or C.Bruise,
		Size = UDim2.fromOffset(size, size),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		LayoutOrder = p.LayoutOrder or 0,
		ScaleType = Enum.ScaleType.Crop,
		Parent = p.Parent,
	})
	UIKit.Corner(img, Theme.Corner.Round)
	UIKit.Stroke(img, 3, C.Ink)
	local uid = p.UserId
	if typeof(uid) == "number" and uid > 0 then
		task.spawn(function()
			local ok, content = pcall(Players.GetUserThumbnailAsync, Players, uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			if ok and img.Parent then
				img.Image = content
			end
		end)
	end
	return img
end

-- ---------------------------------------------------------------- form controls

-- Pill switch. props: Parent, Value, OnChange(v), Size, LayoutOrder
function UIKit.Toggle(p: { [string]: any }): any
	local value = p.Value == true
	local btn = UIKit.Button({
		Parent = p.Parent,
		Name = p.Name or "Toggle",
		Size = p.Size or UDim2.fromOffset(170, 74),
		LayoutOrder = p.LayoutOrder,
		Color = if value then C.Mint else C.PaperDim,
		Text = if value then "ON" else "OFF",
		TextSize = Theme.Text.Body,
	})
	local obj = {} :: any
	obj.Instance = btn.Instance
	obj.Button = btn.Button
	local function render()
		btn:SetColor(if value then C.Mint else C.PaperDim)
		btn:SetText(if value then "ON" else "OFF")
	end
	btn.Button.Activated:Connect(function()
		value = not value
		render()
		if p.OnChange then
			p.OnChange(value)
		end
	end)
	function obj.Set(_self: any, v: boolean)
		value = v
		render()
	end
	return obj
end

-- Volume as a row of 10 candy pips with − / + buttons (gamepad & touch friendly).
-- props: Parent, Value (0..1), OnChange(v), LayoutOrder, Color
function UIKit.Stepper(p: { [string]: any }): any
	local value = math.clamp(p.Value or 1, 0, 1)
	local row = UIKit.Box({ Name = p.Name or "Stepper", Size = UDim2.fromOffset(560, 80), LayoutOrder = p.LayoutOrder or 0, Parent = p.Parent })
	UIKit.List(row, { Dir = Enum.FillDirection.Horizontal, Gap = 12, V = Enum.VerticalAlignment.Center })
	local pips: { Frame } = {}
	local obj = {} :: any
	local function render()
		local n = math.floor(value * 10 + 0.5)
		for i, pip in pips do
			pip.BackgroundColor3 = if i <= n then (p.Color or C.Mustard) else C.NightDeep
		end
	end
	local function set(v: number)
		value = math.clamp(math.floor(v * 10 + 0.5) / 10, 0, 1)
		render()
		if p.OnChange then
			p.OnChange(value)
		end
	end
	local minus = UIKit.Button({ Parent = row, Text = "−", Size = UDim2.fromOffset(80, 80), LayoutOrder = 1, Color = C.Bruise, OnClick = function()
		set(value - 0.1)
	end })
	local bar = UIKit.Box({ Size = UDim2.fromOffset(360, 44), LayoutOrder = 2, Parent = row })
	UIKit.List(bar, { Dir = Enum.FillDirection.Horizontal, Gap = 6, V = Enum.VerticalAlignment.Center })
	for i = 1, 10 do
		local pip = UIKit.new("TextButton", {
			Text = "",
			AutoButtonColor = false,
			Selectable = false,
			Size = UDim2.fromOffset(30, 30 + (i % 2) * 6),
			BackgroundColor3 = C.NightDeep,
			LayoutOrder = i,
			Parent = bar,
		})
		UIKit.Corner(pip, UDim.new(0.5, 0))
		UIKit.Stroke(pip, 3, C.Ink)
		pip.Activated:Connect(function()
			set(i / 10)
		end)
		pips[i] = pip
	end
	local plus = UIKit.Button({ Parent = row, Text = "+", Size = UDim2.fromOffset(80, 80), LayoutOrder = 3, Color = C.Bruise, OnClick = function()
		set(value + 0.1)
	end })
	minus.Button.NextSelectionRight = plus.Button
	plus.Button.NextSelectionLeft = minus.Button
	render()
	obj.Instance = row
	obj.First = minus.Button
	obj.Last = plus.Button
	function obj.Set(_self: any, v: number)
		value = math.clamp(v, 0, 1)
		render()
	end
	return obj
end

-- Tab strip. props: Parent, Tabs = {{Key, Text}}, OnSelect(key), Size, Position
function UIKit.Tabs(p: { [string]: any }): any
	local strip = UIKit.Box({
		Name = "Tabs",
		Size = p.Size or UDim2.new(1, 0, 0, 76),
		Position = p.Position or UDim2.new(),
		Parent = p.Parent,
	})
	UIKit.List(strip, { Dir = Enum.FillDirection.Horizontal, Gap = 12, H = Enum.HorizontalAlignment.Left, V = Enum.VerticalAlignment.Center })
	local buttons: { [string]: Button } = {}
	local order: { TextButton } = {}
	local obj = {} :: any
	local current: string? = nil
	local function select(key: string)
		current = key
		for k, b in buttons do
			b:SetColor(if k == key then C.Rose else C.Night:Lerp(C.Bruise, 0.5))
		end
		if p.OnSelect then
			p.OnSelect(key)
		end
	end
	for i, t in p.Tabs do
		local b = UIKit.Button({
			Parent = strip,
			Text = t.Text,
			Size = UDim2.fromOffset(t.Width or 210, 72),
			TextSize = Theme.Text.Body,
			LayoutOrder = i,
			Color = C.Bruise,
			OnClick = function()
				select(t.Key)
			end,
		})
		buttons[t.Key] = b
		table.insert(order, b.Button)
	end
	obj.Instance = strip
	obj.Buttons = buttons
	obj.Order = order
	obj.Select = function(_self: any, key: string)
		select(key)
	end
	obj.Current = function()
		return current
	end
	return obj
end

-- Scrolling list area that auto-sizes its canvas. Never place under a rotated parent.
function UIKit.Scroll(p: { [string]: any }): ScrollingFrame
	local sf = UIKit.new("ScrollingFrame", {
		Name = p.Name or "Scroll",
		BackgroundTransparency = 1,
		Size = p.Size or UDim2.fromScale(1, 1),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 10,
		ScrollBarImageColor3 = C.Rose,
		ScrollBarImageTransparency = 0.1,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		Selectable = false,
		Parent = p.Parent,
	})
	UIKit.List(sf, { Gap = p.Gap or 14, H = p.H or Enum.HorizontalAlignment.Center })
	UIKit.new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = sf })
	return sf
end

return UIKit
