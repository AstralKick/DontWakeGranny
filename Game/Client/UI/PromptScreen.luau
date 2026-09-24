--!strict
-- PromptScreen (both places)
-- Renders every ProximityPrompt with Style = Custom (all gameplay prompts are custom,
-- so without this they'd be invisible). One BillboardGui per shown prompt:
--   [ key glyph inside a hold ring ]  [ ObjectText / ActionText card ]
-- Style variant from the prompt attribute Kind: Loot/Prize/Search/Door/Hide/Bank/
-- Diary/Objective. Touch: tapping the billboard drives InputHoldBegin/End.

local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIWidgets = require(script.Parent:WaitForChild("UIWidgets"))
local UIState = require(script.Parent:WaitForChild("UIState"))

local C = Theme.Color
local PromptScreen = {}

type Style = { Card: Color3, Text: Color3, Sub: Color3, Ring: Color3, Tag: string?, Font: Font? }

local STYLES: { [string]: Style } = {
	Loot = { Card = C.Paper, Text = C.Ink, Sub = C.Bruise, Ring = C.Rose },
	Prize = { Card = C.Mustard, Text = C.Ink, Sub = C.Ink, Ring = C.Blood, Tag = "PRIZE" },
	List = { Card = C.Mint, Text = C.Ink, Sub = C.Ink, Ring = C.Mustard, Tag = "ON THE LIST" },
	Search = { Card = C.PaperDim, Text = C.Ink, Sub = C.Bruise, Ring = C.Bruise },
	Door = { Card = C.Night, Text = C.Paper, Sub = C.Rose, Ring = C.Rose },
	Hide = { Card = C.Bruise, Text = C.Paper, Sub = C.Paper, Ring = C.Paper },
	Bank = { Card = C.Mint, Text = C.Ink, Sub = C.Ink, Ring = C.Mustard, Tag = "STASH" },
	Diary = { Card = C.Paper, Text = C.Ink, Sub = C.Blood, Ring = C.Blood, Font = Theme.Font.Note },
	Objective = { Card = C.Pumpkin, Text = C.Ink, Sub = C.Ink, Ring = C.Mustard },
	Menu = { Card = C.Rose, Text = C.Ink, Sub = C.Night, Ring = C.Paper },
	Default = { Card = C.Night, Text = C.Paper, Sub = C.Mustard, Ring = C.Rose },
}

local W, H = 440, 124

type Entry = {
	Gui: BillboardGui,
	Card: Frame,
	Ring: any,
	Glyph: any,
	Conns: { RBXScriptConnection },
	Hold: NumberValue,
	HoldTween: Tween?,
	Hiding: boolean,
}

local entries: { [ProximityPrompt]: Entry } = {}
local folder: Folder? = nil

local function billboardScale(): number
	local s = math.clamp(UIState.Scale, 0.55, 1.2)
	if UIState.Input == "Touch" then
		s *= 1.2 -- fatter tap target
	elseif UIState.Input == "Gamepad" then
		s *= 1.1
	end
	return s * 0.85
end

local function adorneeOf(prompt: ProximityPrompt): Instance?
	local parent = prompt.Parent
	if not parent then
		return nil
	end
	if parent:IsA("Attachment") or parent:IsA("BasePart") then
		return parent
	end
	if parent:IsA("Model") then
		return parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

local function destroyEntry(prompt: ProximityPrompt)
	local e = entries[prompt]
	if not e then
		return
	end
	entries[prompt] = nil
	for _, c in e.Conns do
		c:Disconnect()
	end
	if e.HoldTween then
		e.HoldTween:Cancel()
	end
	e.Hold:Destroy()
	e.Gui:Destroy()
end

-- Respawning clears loose PlayerGui children (the match respawns everyone each night),
-- so (re)create the billboard container on demand.
local function ensureFolder(): Instance?
	if folder and folder.Parent then
		return folder
	end
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return nil
	end
	local existing = playerGui:FindFirstChild("DWG_Prompts")
	if existing and existing:IsA("Folder") then
		folder = existing
	else
		local f = Instance.new("Folder")
		f.Name = "DWG_Prompts"
		f.Parent = playerGui
		folder = f
	end
	-- Entries whose billboards were wiped with the old folder are stale.
	for prompt, e in entries do
		if e.Gui.Parent ~= folder then
			destroyEntry(prompt)
		end
	end
	return folder
end

local function build(prompt: ProximityPrompt)
	destroyEntry(prompt)
	local adornee = adorneeOf(prompt)
	if not adornee or not ensureFolder() then
		return
	end
	local kind = prompt:GetAttribute("Kind")
	local style = STYLES[if typeof(kind) == "string" then kind else "Default"] or STYLES.Default
	local s = billboardScale()

	local gui = UIKit.new("BillboardGui", {
		Name = "Prompt_" .. (prompt.ActionText or ""),
		Adornee = adornee,
		AlwaysOnTop = true,
		LightInfluence = 0,
		ResetOnSpawn = false,
		Active = true,
		ClipsDescendants = false,
		Size = UDim2.fromOffset(W * s, H * s),
		StudsOffset = Vector3.new(0, 0.2, 0), -- sits right over the thing you interact with
		MaxDistance = prompt.MaxActivationDistance * 2 + 10,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local root = UIKit.Box({ Name = "Root", Size = UDim2.fromOffset(W, H), Parent = gui })
	UIKit.new("UIScale", { Name = "ViewScale", Scale = s, Parent = root })
	local pop = UIKit.Box({ Name = "Pop", Size = UDim2.fromScale(1, 1), Parent = root })

	-- Glyph disc + hold ring (left)
	local disc = UIKit.new("Frame", { Name = "Disc", BackgroundColor3 = C.Night, Size = UDim2.fromOffset(H - 8, H - 8), Position = UDim2.fromOffset(0, 4), ZIndex = 2, Parent = pop })
	UIKit.Corner(disc, Theme.Corner.Round)
	UIKit.Stroke(disc, Theme.Stroke.Panel, C.Ink)
	local ring = UIKit.Ring({ Parent = pop, Size = H - 16, Thickness = 9, Position = UDim2.fromOffset(4, 8), Color = style.Ring, Track = C.NightDeep, ZIndex = 3 })
	local glyph = UIWidgets.Glyph({
		Parent = pop,
		Key = prompt.KeyboardKeyCode,
		Pad = prompt.GamepadKeyCode,
		Size = 54,
		Position = UDim2.fromOffset((H - 8) / 2, (H - 8) / 2 + 4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 6,
	})
	if prompt.HoldDuration <= 0 then
		ring.Instance.Visible = false
	end

	-- Card (right)
	local cardShadow = UIKit.new("Frame", { BackgroundColor3 = C.Shadow, BackgroundTransparency = Theme.Shadow.Transparency, Size = UDim2.new(1, -(H + 2), 0, H - 30), Position = UDim2.fromOffset(H - 12, 22 + Theme.Shadow.Offset), Rotation = -2, ZIndex = 0, Parent = pop })
	UIKit.Corner(cardShadow, Theme.Corner.Chip)
	local card = UIKit.new("Frame", {
		Name = "Card",
		BackgroundColor3 = style.Card,
		Size = UDim2.new(1, -(H + 2), 0, H - 30),
		Position = UDim2.fromOffset(H - 12, 22),
		Rotation = -2,
		ZIndex = 1,
		Parent = pop,
	})
	UIKit.Corner(card, Theme.Corner.Chip)
	UIKit.Stroke(card, Theme.Stroke.Panel, C.Ink)
	UIKit.new("UIPadding", { PaddingLeft = UDim.new(0, 26), PaddingRight = UDim.new(0, 12), Parent = card })
	local objectLabel = UIKit.Label({
		Name = "Object",
		Text = prompt.ObjectText,
		Font = style.Font or Theme.Font.Body,
		TextSize = 26,
		Color = style.Sub,
		Stroke = false,
		XAlign = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 6),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
		Parent = card,
	})
	local actionLabel = UIKit.Label({
		Name = "Action",
		Text = prompt.ActionText,
		Font = style.Font or Theme.Font.Button,
		TextSize = 38,
		Color = style.Text,
		Stroke = if style.Text == C.Paper then 3 else false,
		XAlign = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.fromOffset(0, 36),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
		Parent = card,
	})
	if style.Tag then
		UIKit.Tag({ Parent = pop, Text = style.Tag, Color = C.Blood, TextColor = C.Paper, Position = UDim2.new(1, -10, 0, 2), AnchorPoint = Vector2.new(1, 0), Tilt = 6, ZIndex = 7, TextSize = 20 })
	end

	-- Tap / click target over everything.
	local hit = UIKit.new("TextButton", { Name = "Hit", Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 10, Selectable = false, Parent = pop })
	-- Only touch needs to TAP the prompt. With a mouse/gamepad the button (and an Active
	-- billboard) would swallow input and stop you turning the camera while the cursor is
	-- over a prompt, so it's click-through there (PC/console use the key instead).
	local function applyInteractive()
		local touch = UIState.Input == "Touch"
		gui.Active = touch
		hit.Active = touch
		pcall(function()
			hit.Interactable = touch
		end)
	end
	applyInteractive()

	local holdValue = Instance.new("NumberValue")
	local e: Entry = {
		Gui = gui,
		Card = card,
		Ring = ring,
		Glyph = glyph,
		Conns = {},
		Hold = holdValue,
		HoldTween = nil,
		Hiding = false,
	}
	entries[prompt] = e

	local function refreshText()
		objectLabel.Text = prompt.ObjectText
		actionLabel.Text = prompt.ActionText
		objectLabel.Visible = prompt.ObjectText ~= ""
		actionLabel.Position = if prompt.ObjectText ~= "" then UDim2.fromOffset(0, 36) else UDim2.fromOffset(0, 20)
		ring.Instance.Visible = prompt.HoldDuration > 0
	end
	refreshText()

	local function holdBegin()
		if prompt.HoldDuration <= 0 then
			return
		end
		if e.HoldTween then
			e.HoldTween:Cancel()
		end
		holdValue.Value = 0
		e.HoldTween = UIKit.Tween(holdValue, prompt.HoldDuration, { Value = 1 }, Enum.EasingStyle.Linear)
		UIKit.Tween(UIKit.ScaleOf(disc), 0.12, { Scale = 0.92 })
	end
	local function holdEnd()
		if e.HoldTween then
			e.HoldTween:Cancel()
		end
		e.HoldTween = UIKit.Tween(holdValue, 0.18, { Value = 0 })
		UIKit.Tween(UIKit.ScaleOf(disc), 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
	end

	table.insert(e.Conns, holdValue.Changed:Connect(function(v)
		ring:Set(v)
	end))
	table.insert(e.Conns, prompt.PromptButtonHoldBegan:Connect(function(plr)
		if plr == Players.LocalPlayer then
			holdBegin()
		end
	end))
	table.insert(e.Conns, prompt.PromptButtonHoldEnded:Connect(function(plr)
		if plr == Players.LocalPlayer then
			holdEnd()
		end
	end))
	table.insert(e.Conns, prompt.Triggered:Connect(function(plr)
		if plr == Players.LocalPlayer then
			holdValue.Value = 0
			UIKit.Pop(card :: any, 1.15, 0.2)
			UIKit.Twitch(card :: any, 3)
		end
	end))
	for _, prop in { "ActionText", "ObjectText", "HoldDuration" } do
		table.insert(e.Conns, prompt:GetPropertyChangedSignal(prop):Connect(refreshText))
	end
	table.insert(e.Conns, prompt:GetPropertyChangedSignal("KeyboardKeyCode"):Connect(function()
		glyph:SetKeys(prompt.KeyboardKeyCode, prompt.GamepadKeyCode)
	end))
	table.insert(e.Conns, UIState.Changed:Connect(function(key)
		if key == "Input" then
			applyInteractive()
		end
		if key == "Scale" or key == "Input" then
			local ns = billboardScale()
			gui.Size = UDim2.fromOffset(W * ns, H * ns)
			local vs = root:FindFirstChild("ViewScale") :: UIScale
			vs.Scale = ns
		end
	end))
	-- Tap (touch) or click with a FREE cursor. In first person the cursor is locked to the
	-- screen centre, where prompts sit, so a locked-cursor click must never trigger them
	-- (players were picking things up by accident). PC uses the key (E) instead.
	local UIS = game:GetService("UserInputService")
	table.insert(e.Conns, hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or (input.UserInputType == Enum.UserInputType.MouseButton1 and UIS.MouseBehavior == Enum.MouseBehavior.Default) then
			prompt:InputHoldBegin()
		end
	end))
	table.insert(e.Conns, hit.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldEnd()
		end
	end))
	table.insert(e.Conns, prompt.AncestryChanged:Connect(function()
		if not prompt:IsDescendantOf(workspace) then
			destroyEntry(prompt)
		end
	end))

	gui.Parent = folder
	UIKit.Pop(pop :: any, 0.6, 0.22)
end

local function hide(prompt: ProximityPrompt)
	local e = entries[prompt]
	if not e or e.Hiding then
		return
	end
	e.Hiding = true
	local pop = e.Gui:FindFirstChild("Pop", true) :: Frame?
	if pop then
		UIKit.PopOut(pop, 0.12).Completed:Once(function()
			if entries[prompt] == e then
				destroyEntry(prompt)
			end
		end)
	else
		destroyEntry(prompt)
	end
end

function PromptScreen.Mount(ctx: any)
	folder = ctx.PromptFolder
	-- Lobby prompts (menu stations, car doors) are default-style on the server; switch them
	-- to Custom locally so every prompt in the game shares one look.
	if ctx.IsLobby then
		local function adopt(d: Instance)
			if d:IsA("ProximityPrompt") and d.Style ~= Enum.ProximityPromptStyle.Custom then
				d.Style = Enum.ProximityPromptStyle.Custom
				if d:GetAttribute("Kind") == nil and d:GetAttribute("Menu") ~= nil then
					d:SetAttribute("Kind", "Menu")
				end
			end
		end
		for _, d in workspace:GetDescendants() do
			adopt(d)
		end
		workspace.DescendantAdded:Connect(adopt)
	end
	ProximityPromptService.PromptShown:Connect(function(prompt)
		if prompt.Style == Enum.ProximityPromptStyle.Custom then
			build(prompt)
		end
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		hide(prompt)
	end)
end

return PromptScreen
