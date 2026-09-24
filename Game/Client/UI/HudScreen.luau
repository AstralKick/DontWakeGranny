--!strict
-- HudScreen (Match)
-- Minimal, edge-pinned night HUD. The house is the star.
--   top-left     Grandma alert face  +  NIGHT n / clock (or PUMPKINS on the finale)
--                + tonight's Prize line + event badge
--   top-right    teammates strip (headshots; grey + X when caught, eye when hidden)
--   bottom-mid   stamina (only when not full), battery (only when on / low),
--                pillowcase "3/5 · 120" chip and the selected item slot
-- Also: teammate-caught toasts and
-- the Night 1 onboarding tags.
-- Exposes HudScreen.Anchors (Grandma, Carry, Item) for other screens.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))
local UIWidgets = require(script.Parent:WaitForChild("UIWidgets"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local NotifyScreen = require(script.Parent:WaitForChild("NotifyScreen"))

local C = Theme.Color
local HudScreen = {}
HudScreen.Anchors = {} :: { [string]: GuiObject }

local MOODS = {
	Asleep = "Asleep",
	FakeSleep = "Asleep",
	Distracted = "Distracted",
	Stirring = "Stirring",
	Waking = "Stirring",
	Returning = "Stirring",
	Searching = "Awake",
	Patrolling = "Awake",
	CheckingHiding = "Awake",
	Stalking = "Awake",
	Chasing = "Chase",
	Attacking = "Chase",
}

local function decode(json: any): any
	if typeof(json) ~= "string" or json == "" then
		return nil
	end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, json)
	return if ok then v else nil
end

-- A pill "chip" with an icon on the left and a label.
local function chip(parent: Instance, name: string, iconFn: ((Instance) -> ())?, order: number): (Frame, TextLabel, Frame)
	local holder = UIKit.Box({ Name = name, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 78), LayoutOrder = order, Parent = parent })
	local shadow = UIKit.new("Frame", { Name = "Shadow", BackgroundColor3 = C.Shadow, BackgroundTransparency = Theme.Shadow.Transparency, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 72), Position = UDim2.fromOffset(0, Theme.Shadow.Offset), Parent = holder })
	UIKit.Corner(shadow, Theme.Corner.Round)
	local face = UIKit.new("Frame", { Name = "Face", BackgroundColor3 = C.Night, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 72), ZIndex = 1, Parent = holder })
	UIKit.Corner(face, Theme.Corner.Round)
	UIKit.Stroke(face, Theme.Stroke.Panel, C.Ink)
	UIKit.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 24), Parent = face })
	UIKit.List(face, { Dir = Enum.FillDirection.Horizontal, Gap = 10, V = Enum.VerticalAlignment.Center, H = Enum.HorizontalAlignment.Left })
	local icon = UIKit.Box({ Name = "Icon", Size = UDim2.fromOffset(56, 56), LayoutOrder = 1, ZIndex = 2, Parent = face })
	if iconFn then
		iconFn(icon)
	end
	local label = UIKit.Label({ Name = "Text", Font = Theme.Font.Button, TextSize = Theme.Text.Body, Auto = "X", Size = UDim2.fromOffset(0, 60), LayoutOrder = 2, ZIndex = 2, Parent = face })
	-- keep shadow width in sync with the auto-sized face
	face:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local sc = UIState.Scale
		shadow.Size = UDim2.fromOffset(face.AbsoluteSize.X / math.max(sc, 0.01), 72)
	end)
	return holder, label, face
end

-- ---------------------------------------------------------------- tutorial tags

local function hintTag(parent: Instance, text: string, anchor: GuiObject, below: boolean): Frame
	local root = parent :: GuiObject
	local sc = math.max(UIState.Scale, 0.01)
	local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
	local rp = root.AbsolutePosition
	local x = (ap.X - rp.X + as.X / 2) / sc
	local y = if below then (ap.Y - rp.Y + as.Y) / sc + 28 else (ap.Y - rp.Y) / sc - 28
	local tag = UIKit.Tag({
		Parent = parent,
		Text = text,
		Font = Theme.Font.Body,
		TextSize = Theme.Text.Body + 4,
		Color = C.Paper,
		Position = UDim2.fromOffset(x, y),
		AnchorPoint = Vector2.new(0.5, if below then 0 else 1),
		Tilt = if below then -3 else 3,
		ZIndex = 20,
	})
	-- little pointer nub
	local nub = UIKit.new("Frame", {
		BackgroundColor3 = C.Paper,
		Size = UDim2.fromOffset(22, 22),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = if below then UDim2.new(0.5, 0, 0, 0) else UDim2.new(0.5, 0, 1, 0),
		Rotation = 45,
		ZIndex = 19,
		Parent = tag,
	})
	UIKit.Stroke(nub, 3, C.Ink)
	UIKit.Pop(tag :: any, 0.5)
	UIKit.Bob(tag :: any, 5, 2.4)
	return tag
end

-- ---------------------------------------------------------------- mount

function HudScreen.Mount(ctx: any)
	local player = Players.LocalPlayer
	local MS = ReplicatedStorage:WaitForChild("MatchState") :: Folder
	local Net = UIState.Net()
	local Bus = UIState.Bus()
	local EventConfig = UIState.Config("EventConfig")
	local EconomyConfig = UIState.Config("EconomyConfig")
	local Format = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("Format") :: ModuleScript)
	local GameConfig = UIState.Config("GameConfig")

	local hud = UIKit.Box({ Name = "Hud", Size = UDim2.fromScale(1, 1), Visible = false, Parent = ctx.HUD })

	-- ============================================================ top-left
	local tl = UIKit.Box({ Name = "TopLeft", Size = UDim2.fromOffset(760, 260), Position = UDim2.fromOffset(24, 18), Parent = hud })
	local face = UIWidgets.GrandmaFace({ Parent = tl, Size = 160, Position = UDim2.fromOffset(0, 0) })
	HudScreen.Anchors.Grandma = face.Instance

	local info = UIKit.Box({ Name = "Info", Size = UDim2.fromOffset(560, 240), Position = UDim2.fromOffset(180, 4), Parent = tl })
	UIKit.List(info, { Gap = 6, H = Enum.HorizontalAlignment.Left })
	local nightRow = UIKit.Box({ Name = "NightRow", Size = UDim2.fromOffset(560, 64), LayoutOrder = 1, Parent = info })
	UIKit.List(nightRow, { Dir = Enum.FillDirection.Horizontal, Gap = 14, H = Enum.HorizontalAlignment.Left, V = Enum.VerticalAlignment.Center })
	local nightLabel = UIKit.Title({ Name = "Night", Text = "NIGHT 1", TextSize = 52, Color = C.Paper, Auto = "X", Size = UDim2.fromOffset(0, 64), LayoutOrder = 1, Parent = nightRow })
	local clockTag = UIKit.Tag({ Parent = nightRow, Name = "Clock", Text = "12:00 AM", Font = Theme.Font.Button, TextSize = Theme.Text.Body, Color = C.Paper, Tilt = -3 })
	clockTag.LayoutOrder = 2
	local clockText = clockTag:FindFirstChild("Text", true) :: TextLabel

	-- Finale: pumpkins instead of the clock
	local pumpkinRow = UIKit.Box({ Name = "Pumpkins", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 56), LayoutOrder = 3, Visible = false, Parent = nightRow })
	UIKit.List(pumpkinRow, { Dir = Enum.FillDirection.Horizontal, Gap = 4, H = Enum.HorizontalAlignment.Left, V = Enum.VerticalAlignment.Center })
	local pumpkinLabel = UIKit.Label({ Text = "PUMPKINS 0/5", Font = Theme.Font.Button, TextSize = Theme.Text.Body, Color = C.Pumpkin, Auto = "X", Size = UDim2.fromOffset(0, 50), LayoutOrder = 99, Parent = pumpkinRow })

	local prizeLabel = UIKit.Label({
		Name = "Prize",
		Text = "",
		Font = Theme.Font.Body,
		TextSize = math.max(Theme.Text.Body, 26), -- readable from the couch on console (>= 24px)
		Color = C.Paper,
		Rich = true,
		XAlign = Enum.TextXAlignment.Left,
		Size = UDim2.fromOffset(620, 38),
		LayoutOrder = 2,
		Parent = info,
	})
	-- Tonight's stash goal: "grab as much as you can" made concrete.
	local goalLabel = UIKit.Label({
		Name = "Goal",
		Text = "",
		Font = Theme.Font.Button,
		TextSize = 26,
		Color = C.Paper,
		Rich = true,
		XAlign = Enum.TextXAlignment.Left,
		Size = UDim2.fromOffset(620, 34),
		LayoutOrder = 3,
		Stroke = 2,
		Parent = info,
	})
	local function refreshGoal()
		local goal = player:GetAttribute("NightGoal") or 0
		local banked = player:GetAttribute("BankedTonight") or 0
		goalLabel.Visible = goal > 0
		if banked >= goal and goal > 0 then
			goalLabel.Text = `<font color="#9CC5A1">Stash goal reached!</font>  {UIWidgets.Number(banked)} Candy stashed — keep going`
		else
			goalLabel.Text = `Tonight's goal: stash <font color="#E0B04F">{UIWidgets.Number(banked)} / {UIWidgets.Number(goal)}</font> Candy`
		end
	end
	refreshGoal()
	player:GetAttributeChangedSignal("NightGoal"):Connect(refreshGoal)
	player:GetAttributeChangedSignal("BankedTonight"):Connect(refreshGoal)
	HudScreen.Anchors.Goal = goalLabel

	local badges = UIKit.Box({ Name = "Badges", Size = UDim2.fromOffset(560, 50), LayoutOrder = 4, Parent = info })
	UIKit.List(badges, { Dir = Enum.FillDirection.Horizontal, Gap = 10, H = Enum.HorizontalAlignment.Left, V = Enum.VerticalAlignment.Center })

	-- ============================================================ top-right teammates
	UIKit.IconButton({ Parent = hud, Name = "Settings", Size = 88, Color = C.Night, Icon = UIIcons.Knobs, Position = UDim2.new(1, -24, 0, 18), AnchorPoint = Vector2.new(1, 0), OnClick = function()
		require(script.Parent:WaitForChild("MenuHost")).Toggle("Settings")
	end })
	local mates = UIKit.Box({ Name = "Teammates", Size = UDim2.fromOffset(460, 100), Position = UDim2.new(1, -112, 0, 18), AnchorPoint = Vector2.new(1, 0), Parent = hud })
	UIKit.List(mates, { Dir = Enum.FillDirection.Horizontal, Gap = 12, H = Enum.HorizontalAlignment.Right })

	-- ============================================================ bottom-center
	local bottom = UIKit.Box({ Name = "Bottom", Size = UDim2.fromOffset(720, 190), Position = UDim2.new(0.5, 0, 1, -18), AnchorPoint = Vector2.new(0.5, 1), Parent = hud })
	UIKit.List(bottom, { Gap = 10, V = Enum.VerticalAlignment.Bottom })

	local meters = UIKit.Box({ Name = "Meters", Size = UDim2.fromOffset(720, 40), LayoutOrder = 1, Parent = bottom })
	UIKit.List(meters, { Dir = Enum.FillDirection.Horizontal, Gap = 26, V = Enum.VerticalAlignment.Center })
	local function meter(name: string, iconFn: (Instance) -> (), color: Color3, order: number): (Frame, any)
		local row = UIKit.Box({ Name = name, Size = UDim2.fromOffset(290, 40), LayoutOrder = order, Visible = false, Parent = meters })
		local ic = UIKit.Box({ Size = UDim2.fromOffset(40, 40), Parent = row })
		iconFn(ic)
		local bar = UIKit.Bar({ Parent = row, Size = UDim2.fromOffset(236, 26), Position = UDim2.fromOffset(50, 7), Color = color })
		return row, bar
	end
	local staminaRow, staminaBar = meter("Stamina", UIIcons.Shoe, C.Mint, 1)
	local batteryRow, batteryBar = meter("Battery", UIIcons.Battery, C.Mustard, 2)

	local chips = UIKit.Box({ Name = "Chips", Size = UDim2.fromOffset(720, 80), LayoutOrder = 2, Parent = bottom })
	UIKit.List(chips, { Dir = Enum.FillDirection.Horizontal, Gap = 18, V = Enum.VerticalAlignment.Center })
	local carryChip, carryLabel, carryFace = chip(chips, "Carry", UIIcons.Sack, 1)
	HudScreen.Anchors.Carry = carryChip
	local itemChip, itemLabel, itemFace = chip(chips, "Item", nil, 2)
	HudScreen.Anchors.Item = itemChip
	itemChip.Visible = false
	local itemIcon = itemFace:FindFirstChild("Icon") :: Frame
	-- use-item key hint (InputController: Q / ButtonR1); touch has its own USE button
	local itemGlyph = UIWidgets.Glyph({ Parent = itemFace, Key = Enum.KeyCode.Q, Pad = Enum.KeyCode.ButtonR1, Size = 44, LayoutOrder = 3, ZIndex = 3 })
	local function refreshGlyph()
		itemGlyph.Instance.Visible = UIState.Input ~= "Touch"
	end
	refreshGlyph()
	UIState.Changed:Connect(function(k)
		if k == "Input" then
			refreshGlyph()
		end
	end)
	local prizeSticker = UIKit.Tag({ Parent = carryChip, Text = "PRIZE!", Color = C.Mustard, Position = UDim2.new(1, 6, 0, -14), AnchorPoint = Vector2.new(1, 0), Tilt = 8, ZIndex = 6, TextSize = 24 })
	prizeSticker.Visible = false

	-- Flashlight chip: tells PC/console players which key toggles the light (F / ButtonY)
	-- and whether it's on. Touch players have the LIGHT button instead.
	local lightChip, lightLabel, lightFace = chip(chips, "Light", UIIcons.Battery, 3)
	local lightGlyph = UIWidgets.Glyph({ Parent = lightFace, Key = Enum.KeyCode.F, Pad = Enum.KeyCode.ButtonY, Size = 44, LayoutOrder = 3, ZIndex = 3 })
	local function refreshLight()
		local on = player:GetAttribute("Flashlight") == true
		lightLabel.Text = if on then "Light ON" else "Light OFF"
		lightLabel.TextColor3 = if on then C.Mustard else C.PaperDim
		lightChip.Visible = UIState.Input ~= "Touch"
		lightGlyph.Instance.Visible = UIState.Input ~= "Touch"
	end
	refreshLight()
	player:GetAttributeChangedSignal("Flashlight"):Connect(refreshLight)
	UIState.Changed:Connect(function(k)
		if k == "Input" then
			refreshLight()
		end
	end)

	-- Early-night control hints for keyboard/gamepad (sprint / sneak); fades after Night 3.
	local hints = UIKit.Box({ Name = "ControlHints", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 44), Position = UDim2.new(0, 24, 1, -120), AnchorPoint = Vector2.new(0, 1), Parent = hud }) -- above the bottom chip row
	UIKit.List(hints, { Dir = Enum.FillDirection.Horizontal, Gap = 10, V = Enum.VerticalAlignment.Center })
	local function hint(key: Enum.KeyCode, pad: Enum.KeyCode, text: string, order: number)
		UIWidgets.Glyph({ Parent = hints, Key = key, Pad = pad, Size = 40, LayoutOrder = order * 2 - 1 })
		UIKit.Label({ Text = text, Font = Theme.Font.Button, TextSize = 24, Color = C.Paper, Auto = "X", Size = UDim2.fromOffset(0, 40), LayoutOrder = order * 2, Stroke = 2, Parent = hints })
	end
	hint(Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3, "Run (loud)", 1)
	hint(Enum.KeyCode.C, Enum.KeyCode.ButtonB, "Sneak", 2)
	hint(Enum.KeyCode.F, Enum.KeyCode.ButtonY, "Flashlight", 3)
	local function refreshHints()
		hints.Visible = UIState.Input ~= "Touch" and (MS:GetAttribute("Night") or 1) <= 3
	end
	refreshHints()
	MS:GetAttributeChangedSignal("Night"):Connect(refreshHints)
	UIState.Changed:Connect(function(k)
		if k == "Input" then
			refreshHints()
		end
	end)

	-- ============================================================ state → view

	local function refreshNight()
		local finale = MS:GetAttribute("Finale") == true
		local n = MS:GetAttribute("Night") or 1
		nightLabel.Text = if finale then "HALLOWEEN" else `NIGHT {n}`
		nightLabel.TextColor3 = if finale then C.Pumpkin else C.Paper
		clockTag.Visible = not finale
		pumpkinRow.Visible = finale
	end

	local pumpkinIcons: { Frame } = {}
	local function refreshPumpkins()
		local lit = MS:GetAttribute("PumpkinsLit") or 0
		local total = MS:GetAttribute("PumpkinsTotal") or 5
		pumpkinLabel.Text = `PUMPKINS {lit}/{total}`
		for _, f in pumpkinIcons do
			f:Destroy()
		end
		table.clear(pumpkinIcons)
		for i = 1, total do
			local f = UIKit.Box({ Size = UDim2.fromOffset(40, 40), LayoutOrder = i, Parent = pumpkinRow })
			UIIcons.Pumpkin(f, i <= lit)
			table.insert(pumpkinIcons, f)
		end
	end

	local function refreshPrize()
		local name = MS:GetAttribute("PrizeName") or ""
		local st = MS:GetAttribute("PrizeState") or ""
		if name == "" or st == "" then
			prizeLabel.Visible = false
			return
		end
		prizeLabel.Visible = true
		local suffix = ""
		if st == "Hidden" then
			suffix = "<font color=\"#9CC5A1\"> · somewhere around here</font>"
		elseif st == "Carried" then
			local holder = MS:GetAttribute("PrizeHolder")
			local who = if typeof(holder) == "string" and holder ~= "" then holder else "someone"
			suffix = `<font color="#E0B04F"> · {who} has it — get it to the car!</font>`
		elseif st == "Banked" then
			suffix = "<font color=\"#E0B04F\"> · STOLEN!</font>"
		end
		prizeLabel.Text = `Tonight's Prize: <b>{name}</b>{suffix}`
	end

	local badgeEvent: Frame? = nil
	local badgeRush: Frame? = nil
	local function refreshBadges()
		if badgeEvent then
			badgeEvent:Destroy()
			badgeEvent = nil
		end
		if badgeRush then
			badgeRush:Destroy()
			badgeRush = nil
		end
		local key = MS:GetAttribute("Event") or ""
		local def = EventConfig[key]
		if def then
			local col: Color3 = def.Color
			badgeEvent = UIKit.Tag({ Parent = badges, Text = def.Title, Color = col, TextColor = UIKit.ContrastText(col), TextSize = 24, Tilt = -2 })
			;(badgeEvent :: Frame).LayoutOrder = 1
			UIKit.Twitcher(badgeEvent :: any, 10, 20, 3)
		end
		if (MS:GetAttribute("SugarRushNight") or 0) == (MS:GetAttribute("Night") or -1) then
			badgeRush = UIKit.Tag({ Parent = badges, Text = "SUGAR RUSH · 2× LOOT", Color = C.Mustard, TextSize = 24, Tilt = 2 })
			;(badgeRush :: Frame).LayoutOrder = 2
		end
	end

	local lastMood = ""
	local function refreshGrandma()
		local st = MS:GetAttribute("GrandmaState") or "Asleep"
		local mood = MOODS[st] or "Asleep"
		if mood == "Chase" then
			local g = workspace:FindFirstChild("Grandma")
			local target = g and g:GetAttribute("Target")
			if target and target ~= 0 and target ~= player.UserId then
				mood = "Awake" -- she's after someone else: scary face, no "RUN!"
			end
		end
		if mood ~= lastMood then
			if mood == "Stirring" and lastMood == "Asleep" then
				UIState.Play("GrandmaStir")
			end
			lastMood = mood
		end
		face:SetState(mood)
		local alert = (MS:GetAttribute("Alert") or 0) / 100
		face:SetAlert(if mood == "Asleep" or mood == "Distracted" or mood == "Stirring" then alert else 1)
	end

	-- carry
	local fullTween: Tween? = nil
	local lastSlots = -1
	local function refreshCarry()
		local slots = player:GetAttribute("CarrySlots") or 0
		local max = player:GetAttribute("MaxSlots") or GameConfig.Inventory.BaseSlots
		local value = player:GetAttribute("CarryValue") or 0
		-- Name the pillowcase outright so nobody wonders what the bag is for.
		carryLabel.Text = if slots == 0
			then `PILLOWCASE {slots}/{max}  ·  <font color="#9CC5A1">empty — steal stuff!</font>`
			else `PILLOWCASE {slots}/{max}  ·  <font color="#E0B04F">{UIWidgets.Number(value)} Candy</font>`
		carryLabel.RichText = true
		local full = slots >= max and max > 0
		local faceStroke = carryFace:FindFirstChildOfClass("UIStroke") :: UIStroke
		faceStroke.Color = if full then C.Mustard else C.Ink
		if full and not fullTween and not UIState.ReduceMotion then
			local s = UIKit.ScaleOf(carryChip)
			fullTween = TweenService:Create(s, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.07 })
			;(fullTween :: Tween):Play()
		elseif not full and fullTween then
			fullTween:Cancel()
			fullTween = nil
			UIKit.ScaleOf(carryChip).Scale = 1
		end
		if slots ~= lastSlots and lastSlots >= 0 and slots > lastSlots then
			UIKit.Pop(carryFace :: any, 1.2, 0.25)
		end
		lastSlots = slots
		prizeSticker.Visible = player:GetAttribute("CarryingPrize") == true
	end

	-- items
	local selected: string? = nil
	local function items(): { [string]: number }
		return decode(player:GetAttribute("Items")) or {}
	end
	local function refreshItem()
		local have = items()
		if not selected or (have[selected] or 0) <= 0 then
			selected = nil
			for _, k in EconomyConfig.ItemOrder do
				if (have[k] or 0) > 0 then
					selected = k
					break
				end
			end
		end
		UIState.Set("SelectedItem", selected)
		if not selected then
			itemChip.Visible = false
			return
		end
		itemChip.Visible = true
		for _, c in itemIcon:GetChildren() do
			c:Destroy()
		end
		local fn = (UIIcons :: any)[selected]
		if fn then
			fn(itemIcon)
		end
		local def = EconomyConfig.Items[selected]
		itemLabel.Text = `{if def then def.Name else selected}  <font color="#E0B04F">×{have[selected] or 0}</font>`
		itemLabel.RichText = true
	end
	Bus.On("SelectedItem", function(key)
		if typeof(key) == "string" and key ~= selected then
			selected = key
			refreshItem()
			UIKit.Pop(itemFace :: any, 0.85, 0.2)
		end
	end)

	-- stamina / battery
	local function refreshMeters()
		local st, maxSt = player:GetAttribute("Stamina") or 100, player:GetAttribute("MaxStamina") or 100
		local showSt = st < maxSt - 0.5
		if showSt ~= staminaRow.Visible then
			staminaRow.Visible = showSt
			if showSt then
				UIKit.Pop(staminaRow :: any, 0.85, 0.2)
			end
		end
		staminaBar:Set(st / math.max(1, maxSt), true)
		staminaBar.Fill.BackgroundColor3 = if st / math.max(1, maxSt) < 0.2 then C.Blood else C.Mint

		local b, maxB = player:GetAttribute("Battery") or 0, player:GetAttribute("MaxBattery") or 1
		local frac = b / math.max(1, maxB)
		local on = player:GetAttribute("Flashlight") == true
		local showB = on or frac < 0.25
		if showB ~= batteryRow.Visible then
			batteryRow.Visible = showB
		end
		batteryBar:Set(frac, true)
		batteryBar.Fill.BackgroundColor3 = if frac < 0.2 then C.Blood else C.Mustard
	end

	-- teammates
	local mateCards: { [Player]: { Frame: Frame, Refresh: () -> (), Conns: { RBXScriptConnection } } } = {}
	local function addMate(p: Player)
		if p == player or mateCards[p] then
			return
		end
		local card = UIKit.Box({ Name = p.Name, Size = UDim2.fromOffset(72, 96), Parent = mates })
		local shot = UIKit.Headshot({ Parent = card, UserId = p.UserId, Size = 68, Position = UDim2.fromOffset(2, 0) })
		local ringStroke = shot:FindFirstChildOfClass("UIStroke") :: UIStroke
		local dim = UIKit.new("Frame", { BackgroundColor3 = C.Ink, BackgroundTransparency = 0.35, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 2, Parent = shot })
		UIKit.Corner(dim, Theme.Corner.Round)
		local x = UIKit.Box({ Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.15, 0.15), Visible = false, ZIndex = 3, Parent = shot })
		UIIcons.X(x)
		local eye = UIKit.new("Frame", { BackgroundColor3 = C.Bruise, Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -6, 1, -4), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 4, Parent = shot })
		UIKit.Corner(eye, Theme.Corner.Round)
		UIKit.Stroke(eye, 3, C.Ink)
		local eyeIcon = UIKit.Box({ Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.15, 0.15), ZIndex = 5, Parent = eye })
		UIIcons.EyeClosed(eyeIcon, C.Paper)
		UIKit.Label({ Text = p.DisplayName, Font = Theme.Font.Button, TextSize = 24, Size = UDim2.new(1, 24, 0, 28), Position = UDim2.new(0.5, 0, 0, 72), AnchorPoint = Vector2.new(0.5, 0), TextTruncate = Enum.TextTruncate.AtEnd, Stroke = 2, Parent = card })
		local wasAlive = true
		local function refresh()
			local alive = p:GetAttribute("Alive") ~= false
			dim.Visible = not alive
			x.Visible = not alive
			shot.ImageTransparency = if alive then 0 else 0.4
			eye.Visible = alive and p:GetAttribute("Hidden") == true
			ringStroke.Color = if p:GetAttribute("CarryingPrize") == true then C.Mustard else C.Ink
			ringStroke.Thickness = if p:GetAttribute("CarryingPrize") == true then 5 else 3
			if wasAlive ~= alive then
				UIKit.Pop(shot :: any, if alive then 0.6 else 1.3, 0.3)
				if not alive then
					UIKit.Shake(card, 5, 0.3)
				end
			end
			wasAlive = alive
		end
		local conns = { p.AttributeChanged:Connect(refresh) }
		refresh()
		mateCards[p] = { Frame = card, Refresh = refresh, Conns = conns }
	end
	local function removeMate(p: Player)
		local m = mateCards[p]
		if m then
			for _, c in m.Conns do
				c:Disconnect()
			end
			m.Frame:Destroy()
			mateCards[p] = nil
		end
	end
	for _, p in Players:GetPlayers() do
		addMate(p)
	end
	Players.PlayerAdded:Connect(addMate)
	Players.PlayerRemoving:Connect(removeMate)

	-- ============================================================ visibility

	local scaring = false
	local cinematic = false
	local function refreshVisible()
		local phase = MS:GetAttribute("Phase")
		local show = phase == "Night" and not scaring and not cinematic
		if show ~= hud.Visible then
			hud.Visible = show
			if show then
				UIKit.Pop(tl :: any, 0.85)
				UIKit.Pop(bottom :: any, 0.85)
			end
		end
		local alive = player:GetAttribute("Alive") ~= false
		bottom.Visible = alive
	end

	-- ============================================================ wiring

	-- Get out of the way of the jumpscare, come back after it.
	Bus.On("JumpscareStarted", function()
		scaring = true
		refreshVisible()
		task.delay(4, function()
			if scaring then
				scaring = false
				refreshVisible()
			end
		end)
	end)
	Bus.On("JumpscareFinished", function()
		scaring = false
		refreshVisible()
	end)

	-- Cinematics (night intro) own the whole screen; the HUD pops back in afterwards.
	local cineToken = 0
	Bus.On("CinematicStarted", function()
		cinematic = true
		cineToken += 1
		local token = cineToken
		refreshVisible()
		task.delay(20, function()
			if cinematic and token == cineToken then
				cinematic = false
				refreshVisible()
			end
		end)
	end)
	Bus.On("CinematicEnded", function()
		cinematic = false
		refreshVisible()
	end)

	MS.AttributeChanged:Connect(function(key)
		if key == "Phase" then
			refreshVisible()
			refreshNight()
			refreshBadges()
		elseif key == "Night" or key == "Finale" then
			refreshNight()
			refreshBadges()
		elseif key == "GrandmaState" or key == "Alert" then
			refreshGrandma()
		elseif key == "PrizeName" or key == "PrizeState" or key == "PrizeHolder" then
			refreshPrize()
		elseif key == "Event" or key == "SugarRushNight" then
			refreshBadges()
		elseif key == "PumpkinsLit" or key == "PumpkinsTotal" then
			refreshPumpkins()
			if key == "PumpkinsLit" then
				UIKit.Pop(pumpkinRow :: any, 1.25)
			end
		end
	end)
	player.AttributeChanged:Connect(function(key)
		if key == "CarrySlots" or key == "MaxSlots" or key == "CarryValue" or key == "CarryingPrize" then
			refreshCarry()
		elseif key == "Items" then
			refreshItem()
		elseif key == "Stamina" or key == "MaxStamina" or key == "Battery" or key == "MaxBattery" or key == "Flashlight" then
			refreshMeters()
		elseif key == "Alive" then
			refreshVisible()
		end
	end)

	refreshNight()
	refreshPumpkins()
	refreshPrize()
	refreshBadges()
	refreshGrandma()
	refreshCarry()
	refreshItem()
	refreshMeters()
	refreshVisible()

	-- clock (10-minute ticks, like an old clock)
	task.spawn(function()
		local lastText = ""
		while true do
			local s0 = MS:GetAttribute("NightStart") or 0
			local s1 = MS:GetAttribute("NightEnd") or 1
			local frac = if s1 > s0 then (workspace:GetServerTimeNow() - s0) / (s1 - s0) else 0
			local phase = MS:GetAttribute("Phase")
			if phase ~= "Night" then
				frac = if phase == "Morning" then 1 else 0
			end
			local text = Format.Clock(frac, GameConfig.ClockStartHour or 0, GameConfig.ClockEndHour or 6)
			if text ~= lastText then
				lastText = text
				clockText.Text = text
				if text:sub(-5) == "00 AM" then
					UIKit.Pop(clockTag :: any, 1.25, 0.3) -- the hour ticks over
				end
				-- last half hour: the clock turns mint, dawn is close
				clockText.TextColor3 = if frac > 0.92 then C.Mint:Lerp(C.Ink, 0.5) else C.Ink
			end
			task.wait(0.25)
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		if hud.Visible then
			face:Step(dt)
		end
	end)

	-- ============================================================ teammate caught
	Net.Event("TeammateCaught").OnClientEvent:Connect(function(name, lost)
		local extra = if typeof(lost) == "number" and lost > 0 then ` — dropped {UIWidgets.Number(lost)} Candy` else ""
		NotifyScreen.Toast(`{name} got caught!{extra}`, "Bad")
	end)

	-- ============================================================ chase target
	-- (Grandma's speech bubbles are drawn by GrandmaAnimController / SpeechBubble.)
	local function hookGrandma(g: Instance)
		g:GetAttributeChangedSignal("Target"):Connect(refreshGrandma)
	end
	local g0 = workspace:FindFirstChild("Grandma")
	if g0 then
		hookGrandma(g0)
	end
	workspace.ChildAdded:Connect(function(c)
		if c.Name == "Grandma" then
			hookGrandma(c)
		end
	end)

	-- ============================================================ Night 1 onboarding
	task.spawn(function()
		local Data = UIState.Data()
		Data:WaitReady()
		local tut = Data:Get("Tutorial")
		if tut and tut.SeenIntro then
			return
		end
		while not (MS:GetAttribute("Phase") == "Night") do
			MS:GetAttributeChangedSignal("Phase"):Wait()
		end
		if (MS:GetAttribute("Night") or 1) ~= 1 then
			return
		end
		task.wait(1.5)
		local picked = false
		local banked = false
		local c1 = Net.Event("LootPicked").OnClientEvent:Connect(function()
			picked = true
		end)
		local c2 = Net.Event("Banked").OnClientEvent:Connect(function()
			banked = true
		end)
		local function step(text: string, anchor: GuiObject, below: boolean, untilFn: () -> boolean, maxTime: number)
			if not hud.Visible then
				return
			end
			local tag = hintTag(hud, text, anchor, below)
			local t0 = os.clock()
			while os.clock() - t0 < maxTime and not untilFn() and hud.Visible do
				task.wait(0.2)
			end
			UIKit.PopOut(tag :: any, 0.2).Completed:Once(function()
				tag:Destroy()
			end)
			task.wait(0.6)
		end
		step("Steal shiny things — they go in your pillowcase!", carryChip, false, function()
			return picked
		end, 14)
		step("Don't wake Grandma.", face.Instance, true, function()
			return false
		end, 6)
		step("Stash your pillowcase in Mom's trunk to keep it!", carryChip, false, function()
			return banked
		end, 14)
		step("Grab as much as you can before 6 AM!", goalLabel, true, function()
			return false
		end, 7)
		c1:Disconnect()
		c2:Disconnect()
		Net.Event("MarkTutorial"):FireServer("SeenIntro")
	end)
end

return HudScreen
