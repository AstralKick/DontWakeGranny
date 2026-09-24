--!strict
-- IntroScreen (Match)
-- Phase "Waiting": "Waiting for your party… 2/4" (Arrived / Expected).
-- Phase "Intro":   the UI layer of the cinematic night intro. The camera work and the
--                  timing live in Modules/NightIntroController, which drives this API:
--
--   IntroScreen.IsMounted() -> boolean
--   IntroScreen.CineBegin({ Tier, FromBlack })  letterbox bars in, fade up from black
--   IntroScreen.Fade(alpha, seconds)            full-screen black (0 = clear, 1 = black)
--   IntroScreen.Flash(color, alpha, seconds)    one-off coloured flash that decays
--   IntroScreen.Caption(text, seconds)          short typed line on the bottom bar
--   IntroScreen.Stamp(areaText)                 "NEW AREA UNLOCKED" rubber stamp slam
--   IntroScreen.EventCard(eventKey)             "TONIGHT" event card (EventConfig)
--   IntroScreen.Title(title, subtitle, opts)    big "NIGHT 7" + typewriter subtitle
--                                               opts = { Finale, Night, TypeTime }
--   IntroScreen.Glitch(strength)                nightmare-tier UI jitter for a glitch cut
--   IntroScreen.CineEnd(seconds)                bars out, cards out, back to gameplay
--
-- Tier (1 cozy · 2 unsettling · 3 disturbing · 4 nightmare · 5 Halloween) picks the text
-- font/colour. If no cinematic starts within 0.6 s of Phase "Intro" (e.g. the controller
-- failed), a static title card is shown instead, so there is never a double title card.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIState = require(script.Parent:WaitForChild("UIState"))

local C = Theme.Color
local BAR_COLOR = C.Ink:Lerp(Color3.new(0, 0, 0), 0.7)
local BAR_H = 0.11 -- fraction of the screen per bar

local IntroScreen = {}

type Refs = {
	Card: Frame, -- Overlay: titles, captions, stamp, event card
	Layer: Frame, -- Bleed: bars, dim, black, flash
	TopBar: Frame,
	BotBar: Frame,
	Dim: Frame,
	Black: Frame,
	FlashFill: Frame,
	Caption: TextLabel,
}

local refs: Refs? = nil
local cineActive = false
local tier = 1
local captionToken = 0
local endToken = 0

local function subFont(): Font
	return if tier >= 3 then Theme.Font.Note else Theme.Font.Body
end

local function subColor(): Color3
	if tier == 5 then
		return C.Pumpkin
	elseif tier >= 4 then
		return C.Rose
	end
	return C.Paper
end

-- Types a label out grapheme by grapheme (MaxVisibleGraphemes; no string churn).
local function typeOut(label: TextLabel, seconds: number)
	local n = utf8.len(label.Text) or #label.Text
	if UIState.ReduceMotion or n <= 0 then
		label.MaxVisibleGraphemes = -1
		return
	end
	label.MaxVisibleGraphemes = 0
	task.spawn(function()
		local per = math.max(0.012, seconds / n)
		for i = 1, n do
			if not label.Parent then
				return
			end
			label.MaxVisibleGraphemes = i
			task.wait(per)
		end
		label.MaxVisibleGraphemes = -1
	end)
end

function IntroScreen.IsMounted(): boolean
	return refs ~= nil
end

function IntroScreen.IsCinematic(): boolean
	return cineActive
end

local function clearCard()
	local r = refs
	if not r then
		return
	end
	for _, c in r.Card:GetChildren() do
		c:Destroy()
	end
end

function IntroScreen.Fade(alpha: number, seconds: number)
	local r = refs
	if not r then
		return
	end
	local b = r.Black
	b.Visible = true
	if seconds <= 0 then
		b.BackgroundTransparency = 1 - alpha
		b.Visible = alpha > 0.001
		return
	end
	local tw = UIKit.Tween(b, seconds, { BackgroundTransparency = 1 - alpha }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	if alpha <= 0.001 then
		tw.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed then
				b.Visible = false
			end
		end)
	end
end

function IntroScreen.Flash(color: Color3, alpha: number, seconds: number)
	local r = refs
	if not r then
		return
	end
	local f = r.FlashFill
	f.BackgroundColor3 = color
	f.BackgroundTransparency = 1 - alpha
	f.Visible = true
	UIKit.Tween(f, math.max(0.03, seconds), { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out).Completed:Once(function(state)
		if state == Enum.PlaybackState.Completed then
			f.Visible = false
		end
	end)
end

function IntroScreen.CineBegin(opts: { [string]: any }?)
	local r = refs
	if not r then
		return
	end
	local o = opts or {}
	tier = o.Tier or 1
	cineActive = true
	endToken += 1
	clearCard()
	r.Card.Visible = true
	r.Card.Position = UDim2.fromScale(0, 0)
	r.Layer.Visible = true
	r.Dim.Visible = false
	r.Dim.BackgroundTransparency = 1
	r.Caption.Text = ""
	-- letterbox in
	r.TopBar.Visible = true
	r.BotBar.Visible = true
	local barTime = if o.FromBlack == false then 0.3 else 0.6
	r.TopBar.Size = UDim2.fromScale(1, 0)
	r.BotBar.Size = UDim2.fromScale(1, 0)
	UIKit.Tween(r.TopBar, barTime, { Size = UDim2.fromScale(1, BAR_H) }, Enum.EasingStyle.Quart)
	UIKit.Tween(r.BotBar, barTime, { Size = UDim2.fromScale(1, BAR_H) }, Enum.EasingStyle.Quart)
	-- up from black
	IntroScreen.Fade(1, 0)
	IntroScreen.Fade(0, if o.FromBlack == false then 0.3 else 0.9)
end

function IntroScreen.Caption(text: string, seconds: number)
	local r = refs
	if not r then
		return
	end
	captionToken += 1
	local token = captionToken
	local l = r.Caption
	l.FontFace = subFont()
	l.TextColor3 = subColor()
	l.Text = text
	l.TextTransparency = 0
	typeOut(l, math.min(0.9, #text * 0.035))
	task.delay(math.max(0.5, seconds - 0.3), function()
		if token == captionToken then
			UIKit.Tween(l, 0.3, { TextTransparency = 1 })
		end
	end)
end

function IntroScreen.Stamp(areaText: string)
	local r = refs
	if not r or areaText == "" then
		return
	end
	-- Rubber stamp: thick blood-red outline, slammed on at an angle.
	local stamp = UIKit.new("Frame", {
		Name = "Stamp",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 130),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -9,
		ZIndex = 10,
		Parent = r.Card,
	})
	UIKit.Corner(stamp, UDim.new(0, 14))
	UIKit.Stroke(stamp, 8, C.Blood)
	UIKit.Pad(stamp, 0, 30, 6)
	UIKit.List(stamp, { Gap = 0 })
	UIKit.Label({ Text = "NEW AREA UNLOCKED", Font = Theme.Font.Button, TextSize = 34, Color = C.Blood, Stroke = 2, StrokeColor = C.Paper, Auto = "X", Size = UDim2.fromOffset(0, 40), LayoutOrder = 1, ZIndex = 11, Parent = stamp })
	UIKit.Label({ Text = areaText, Font = Theme.Font.Title, TextSize = 76, Color = C.Blood, Stroke = 3, StrokeColor = C.Paper, Auto = "X", Size = UDim2.fromOffset(0, 80), LayoutOrder = 2, ZIndex = 11, Parent = stamp })
	UIKit.Pop(stamp :: any, 1.9, 0.18)
	UIState.Play("NewArea")
	task.delay(0.18, UIKit.Shake, r.Card, 8, 0.25)
end

function IntroScreen.EventCard(eventKey: string)
	local r = refs
	if not r then
		return
	end
	local EventConfig = UIState.Config("EventConfig")
	local def = EventConfig[eventKey]
	if not def then
		return
	end
	local holder, body = UIKit.Panel({
		Parent = r.Card,
		Name = "EventCard",
		Size = UDim2.fromOffset(820, 170),
		Position = UDim2.fromScale(0.5, 0.66),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = def.Color,
		Tilt = 2,
		Tape = true,
		Drip = def.Color == C.Blood,
	})
	local tc = UIKit.ContrastText(def.Color)
	UIKit.Label({ Text = "TONIGHT", Font = Theme.Font.Button, TextSize = 26, Color = tc, Stroke = if tc == C.Paper then 2 else false, Size = UDim2.new(1, 0, 0, 30), Parent = body })
	UIKit.Label({ Text = def.Title, Font = Theme.Font.Title, TextSize = 50, Color = tc, Stroke = if tc == C.Paper then 3 else false, Size = UDim2.new(1, 0, 0, 58), Position = UDim2.fromOffset(0, 28), Parent = body })
	UIKit.Label({ Text = def.Blurb, Font = Theme.Font.Body, TextSize = Theme.Text.Body, Color = tc, Stroke = false, Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 88), Parent = body })
	UIKit.Pop(holder :: any, 0.6, 0.35)
	UIState.Play("GrandmaStir")
end

function IntroScreen.Title(title: string, subtitle: string, opts: { [string]: any }?)
	local r = refs
	if not r then
		return
	end
	local o = opts or {}
	local n = o.Night or 1
	local finale = o.Finale == true
	-- The detail shot's cards give way to the title.
	for _, c in r.Card:GetChildren() do
		if c:IsA("GuiObject") then
			UIKit.PopOut(c, 0.15).Completed:Once(function()
				c:Destroy()
			end)
		end
	end
	captionToken += 1
	UIKit.Tween(r.Caption, 0.15, { TextTransparency = 1 })
	r.Dim.Visible = true
	UIKit.Tween(r.Dim, 0.5, { BackgroundTransparency = 0.45 })

	local titleColor = if finale then C.Pumpkin elseif n >= 26 then C.Blood else C.Paper
	local titleLabel = UIKit.Title({
		Name = "NightTitle",
		Text = title,
		TextSize = if finale then 140 else 170,
		Color = titleColor,
		Stroke = 8,
		Size = UDim2.new(1, 0, 0, 200),
		Position = UDim2.fromScale(0.5, 0.42),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Crooked = math.clamp(#title - 1, 1, #title),
		ZIndex = 2,
		Parent = r.Card,
	})
	local shadow = titleLabel:Clone()
	shadow.Name = "NightTitleShadow"
	shadow.TextColor3 = C.Ink
	shadow.TextTransparency = 0.3
	shadow.Position = titleLabel.Position + UDim2.fromOffset(0, 12)
	shadow.ZIndex = 1
	shadow.Parent = r.Card
	UIKit.Pop(titleLabel, 0.4, 0.45)
	UIKit.Pop(shadow, 0.4, 0.45)
	task.delay(0.6, UIKit.Twitch, titleLabel, 4)
	if tier >= 3 then
		UIKit.Twitcher(titleLabel, 1, 2, if tier >= 4 then 6 else 3)
	end

	if subtitle ~= "" then
		local sub = UIKit.Label({
			Name = "NightSubtitle",
			Text = subtitle,
			Font = subFont(),
			TextSize = 52,
			Color = if tier == 1 or tier == 2 then C.Rose else subColor(),
			Stroke = 3,
			Size = UDim2.new(1, 0, 0, 62),
			Position = UDim2.fromScale(0.5, 0.57),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 2,
			Parent = r.Card,
		})
		sub.MaxVisibleGraphemes = 0
		task.delay(0.45, typeOut, sub, o.TypeTime or 0.9)
	end
end

function IntroScreen.Glitch(strength: number)
	local r = refs
	if not r or UIState.ReduceMotion then
		return
	end
	local card = r.Card
	task.spawn(function()
		for _ = 1, 3 do
			card.Position = UDim2.fromOffset(math.random(-14, 14) * strength, math.random(-8, 8) * strength)
			local h = BAR_H + (math.random() - 0.5) * 0.04 * strength
			r.TopBar.Size = UDim2.fromScale(1, h)
			r.BotBar.Size = UDim2.fromScale(1, BAR_H * 2 - h)
			task.wait(0.04)
		end
		card.Position = UDim2.fromScale(0, 0)
		if cineActive then
			r.TopBar.Size = UDim2.fromScale(1, BAR_H)
			r.BotBar.Size = UDim2.fromScale(1, BAR_H)
		end
	end)
end

function IntroScreen.CineEnd(seconds: number)
	local r = refs
	if not r then
		return
	end
	cineActive = false
	endToken += 1
	local token = endToken
	local t = math.max(0.05, seconds)
	UIKit.Tween(r.TopBar, t, { Size = UDim2.fromScale(1, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	UIKit.Tween(r.BotBar, t, { Size = UDim2.fromScale(1, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	UIKit.Tween(r.Dim, t, { BackgroundTransparency = 1 })
	IntroScreen.Fade(0, math.min(t, 0.25))
	captionToken += 1
	UIKit.Tween(r.Caption, math.min(t, 0.2), { TextTransparency = 1 })
	for _, c in r.Card:GetChildren() do
		if c:IsA("GuiObject") then
			UIKit.PopOut(c, math.min(t, 0.25))
			if c:IsA("TextLabel") then
				UIKit.Tween(c, math.min(t, 0.25), { TextTransparency = 1 })
			end
		end
	end
	task.delay(t + 0.05, function()
		if token ~= endToken then
			return
		end
		clearCard()
		r.Dim.Visible = false
		r.TopBar.Visible = false
		r.BotBar.Visible = false
		r.Caption.Text = ""
	end)
end

function IntroScreen.Mount(ctx: any)
	local MS = ReplicatedStorage:WaitForChild("MatchState") :: Folder

	-- ============================================================ waiting
	local waiting = UIKit.Box({ Name = "Waiting", Size = UDim2.fromScale(1, 1), Visible = false, Parent = ctx.Overlay })
	local wHolder, wBody = UIKit.Panel({
		Parent = waiting,
		Size = UDim2.fromOffset(760, 190),
		Position = UDim2.new(0.5, 0, 1, -60),
		AnchorPoint = Vector2.new(0.5, 1),
		Color = C.Night,
		Tilt = -1.5,
		Tape = true,
	})
	local wTitle = UIKit.Label({ Text = "Waiting for your party…", Font = Theme.Font.Button, TextSize = Theme.Text.Header, Size = UDim2.new(1, 0, 0, 60), Position = UDim2.fromOffset(0, 18), Parent = wBody })
	local wSub = UIKit.Label({ Text = "Shhh… she's sleeping.", Font = Theme.Font.Body, TextSize = Theme.Text.Body, Color = C.Rose, Stroke = false, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 84), Parent = wBody })

	local function refreshWaiting()
		local a, e = MS:GetAttribute("Arrived"), MS:GetAttribute("Expected")
		if typeof(a) == "number" and typeof(e) == "number" and e > 0 then
			wTitle.Text = `Waiting for your party…  <font color="#E0B04F">{a}/{e}</font>`
			wTitle.RichText = true
		else
			wTitle.Text = "Waiting for your party…"
		end
	end

	-- ============================================================ cinematic layers
	local card = UIKit.Box({ Name = "NightCard", Size = UDim2.fromScale(1, 1), Visible = false, Parent = ctx.Overlay })
	local layer = UIKit.Box({ Name = "Cinematic", Size = UDim2.fromScale(1, 1), Visible = false, Parent = ctx.Bleed })
	local dim = UIKit.new("Frame", { Name = "Dim", BackgroundColor3 = C.Ink, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 1, Parent = layer })
	local topBar = UIKit.new("Frame", { Name = "TopBar", BackgroundColor3 = BAR_COLOR, Size = UDim2.fromScale(1, 0), Visible = false, ZIndex = 3, Parent = layer })
	local botBar = UIKit.new("Frame", { Name = "BottomBar", BackgroundColor3 = BAR_COLOR, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), Visible = false, ZIndex = 3, Parent = layer })
	local black = UIKit.new("Frame", { Name = "Black", BackgroundColor3 = BAR_COLOR, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 4, Parent = layer })
	local flashFill = UIKit.new("Frame", { Name = "Flash", BackgroundColor3 = C.Paper, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 5, Parent = layer })
	local caption = UIKit.Label({
		Name = "Caption",
		Text = "",
		Font = Theme.Font.Body,
		TextSize = 40,
		Color = C.Paper,
		Stroke = 2,
		Size = UDim2.new(0.9, 0, 0, 56),
		Position = UDim2.new(0.5, 0, 1, -34),
		AnchorPoint = Vector2.new(0.5, 1),
		ZIndex = 20,
		Parent = ctx.Overlay,
	})
	refs = {
		Card = card,
		Layer = layer,
		TopBar = topBar,
		BotBar = botBar,
		Dim = dim,
		Black = black,
		FlashFill = flashFill,
		Caption = caption,
	}

	-- ============================================================ static fallback card
	-- Only used when no cinematic took over (the controller failed / missing map).
	local staticShown = false
	local function showStatic()
		staticShown = true
		clearCard()
		card.Visible = true
		layer.Visible = true
		dim.Visible = true
		dim.BackgroundTransparency = 1
		UIKit.Tween(dim, 0.4, { BackgroundTransparency = 0.25 })
		local n = MS:GetAttribute("Night") or 1
		tier = if n >= 31 then 5 elseif n >= 26 then 4 elseif n >= 16 then 3 elseif n >= 6 then 2 else 1
		IntroScreen.Title(MS:GetAttribute("Title") or `NIGHT {n}`, MS:GetAttribute("Subtitle") or "", { Night = n, Finale = MS:GetAttribute("Finale") == true })
		local eventKey = MS:GetAttribute("Event") or ""
		if eventKey ~= "" then
			task.delay(0.9, IntroScreen.EventCard, eventKey)
		end
		local newArea = MS:GetAttribute("NewArea") or ""
		if newArea ~= "" then
			task.delay(1.5, IntroScreen.Stamp, newArea)
		end
	end

	local introSerial = 0
	local function onPhase()
		local phase = MS:GetAttribute("Phase")
		local w = phase == "Waiting"
		if w ~= waiting.Visible then
			waiting.Visible = w
			if w then
				UIKit.Pop(wHolder :: any)
			end
		end
		introSerial += 1
		local serial = introSerial
		if phase == "Intro" then
			task.delay(0.6, function()
				if serial == introSerial and not cineActive and not staticShown then
					showStatic()
				end
			end)
		elseif staticShown or cineActive then
			staticShown = false
			IntroScreen.CineEnd(0.3)
		end
	end

	MS.AttributeChanged:Connect(function(key)
		if key == "Phase" then
			onPhase()
		elseif key == "Arrived" or key == "Expected" then
			refreshWaiting()
		end
	end)
	refreshWaiting()
	onPhase()

	-- the waiting card's line rotates
	task.spawn(function()
		local lines = { "Shhh… she's sleeping.", "Don't. Make. A. Sound.", "Mom said be back by six.", "Somebody's snoring in there." }
		local i = 1
		while true do
			task.wait(3.5)
			if waiting.Visible then
				i = i % #lines + 1
				wSub.Text = lines[i]
				UIKit.Twitch(wSub, 2)
			end
		end
	end)
end

return IntroScreen
