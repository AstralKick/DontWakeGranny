--!strict
-- TouchControls (Match, Touch input only)
-- On-screen buttons that fire the SAME ClientBus intents as the keyboard/gamepad
-- bindings (InputController owns those). Bottom-right cluster, clear of the
-- joystick (bottom-left). Hidden while hiding: HidingScreen shows its own buttons.
--   RUN (hold)  -> "SprintInput"(true/false)
--   SNEAK       -> "CrouchToggle"()
--   LIGHT       -> "FlashlightToggle"()
--   USE + cycle -> "UseItem"(key), "CycleItem"(1)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))
local UIState = require(script.Parent:WaitForChild("UIState"))

local C = Theme.Color
local TouchControls = {}

local function flashlightIcon(host: Instance)
	local beam = UIIcons.Blob(host, C.Mustard, 0.72, 0.5, 0.5, 0.7, 0.2, 0, 0)
	beam.BackgroundTransparency = 0.45
	UIIcons.Blob(host, C.Bruise, 0.34, 0.5, 0.5, 0.3, 0.3, 0, 3, 1)
	UIIcons.Blob(host, C.PaperDim, 0.56, 0.5, 0.16, 0.44, 0.3, 0, 3, 2)
end

local function isTouchInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
end

function TouchControls.Mount(ctx: any)
	local player = Players.LocalPlayer
	local MS = ReplicatedStorage:WaitForChild("MatchState") :: Folder
	local Bus = UIState.Bus()
	local EconomyConfig = UIState.Config("EconomyConfig")

	local pad = UIKit.Box({ Name = "TouchControls", Size = UDim2.fromOffset(560, 520), Position = UDim2.new(1, -30, 1, -30), AnchorPoint = Vector2.new(1, 1), Visible = false, Parent = ctx.HUD })

	-- RUN: big, hold to sprint
	local run = UIKit.IconButton({ Parent = pad, Name = "Run", Size = 176, Color = C.Rose, Icon = UIIcons.Shoe, Caption = "RUN", Position = UDim2.new(1, -10, 1, -40), AnchorPoint = Vector2.new(1, 1), Sound = false })
	local sprinting = false
	local function setSprint(on: boolean)
		if on == sprinting then
			return
		end
		sprinting = on
		Bus.Fire("SprintInput", on)
	end
	run.Button.InputBegan:Connect(function(input)
		if isTouchInput(input) then
			setSprint(true)
		end
	end)
	run.Button.InputEnded:Connect(function(input)
		if isTouchInput(input) then
			setSprint(false)
		end
	end)

	local sneak = UIKit.IconButton({ Parent = pad, Name = "Sneak", Size = 120, Color = C.Bruise, Text = "SNEAK", TextSize = 26, Position = UDim2.new(1, -212, 1, -40), AnchorPoint = Vector2.new(1, 1), OnClick = function()
		Bus.Fire("CrouchToggle")
	end })
	local light = UIKit.IconButton({ Parent = pad, Name = "Light", Size = 112, Color = C.Night, Icon = flashlightIcon, Caption = "LIGHT", Position = UDim2.new(1, -30, 1, -262), AnchorPoint = Vector2.new(1, 1), OnClick = function()
		Bus.Fire("FlashlightToggle")
	end })

	-- USE item + little cycle button
	local use = UIKit.IconButton({ Parent = pad, Name = "Use", Size = 116, Color = C.Paper, Caption = "USE", Position = UDim2.new(1, -196, 1, -218), AnchorPoint = Vector2.new(1, 1), OnClick = function()
		local key = UIState.SelectedItem
		if typeof(key) == "string" then
			Bus.Fire("UseItem", key)
		end
	end })
	local useIcon = UIKit.Box({ Name = "ItemIcon", Size = UDim2.fromScale(0.6, 0.6), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 4, Parent = use.Button })
	local countTag = UIKit.Tag({ Parent = use.Instance, Text = "×0", Color = C.Mustard, Position = UDim2.new(1, 8, 0, -6), AnchorPoint = Vector2.new(1, 0), Tilt = 8, ZIndex = 8, TextSize = 22 })
	local cycle = UIKit.IconButton({ Parent = pad, Name = "Cycle", Size = 88, Color = C.Bruise, Text = "»", TextSize = 44, Position = UDim2.new(1, -340, 1, -250), AnchorPoint = Vector2.new(1, 1), OnClick = function()
		Bus.Fire("CycleItem", 1)
	end })

	local function refreshItem()
		for _, c in useIcon:GetChildren() do
			c:Destroy()
		end
		local key = UIState.SelectedItem
		local ok, items = pcall(function()
			return game:GetService("HttpService"):JSONDecode(player:GetAttribute("Items") or "{}")
		end)
		local counts = if ok and typeof(items) == "table" then items else {}
		local total = 0
		for _, k in EconomyConfig.ItemOrder do
			total += (counts[k] or 0) > 0 and 1 or 0
		end
		use.Instance.Visible = typeof(key) == "string"
		cycle.Instance.Visible = total > 1
		if typeof(key) == "string" then
			local fn = (UIIcons :: any)[key]
			if fn then
				fn(useIcon)
			end
			local label = countTag:FindFirstChild("Text", true) :: TextLabel
			label.Text = `×{counts[key] or 0}`
		end
	end

	local function refreshToggles()
		local crouch = player:GetAttribute("Crouching") == true
		sneak:SetColor(if crouch then C.Mint else C.Bruise)
		light:SetColor(if player:GetAttribute("Flashlight") == true then C.Mustard else C.Night)
	end

	local hidden = false
	local function refreshVisible()
		local show = UIState.Input == "Touch"
			and MS:GetAttribute("Phase") == "Night"
			and player:GetAttribute("Alive") ~= false
			and not hidden
		if show ~= pad.Visible then
			pad.Visible = show
			if show then
				UIKit.Pop(pad :: any, 0.8)
			else
				setSprint(false)
			end
		end
	end

	UIState.Changed:Connect(function(key)
		if key == "Input" then
			refreshVisible()
		elseif key == "SelectedItem" then
			refreshItem()
		end
	end)
	MS:GetAttributeChangedSignal("Phase"):Connect(refreshVisible)
	player.AttributeChanged:Connect(function(key)
		if key == "Alive" then
			refreshVisible()
		elseif key == "Crouching" or key == "Flashlight" then
			refreshToggles()
		elseif key == "Items" then
			refreshItem()
		end
	end)
	Bus.On("HidingChanged", function(h)
		hidden = h == true
		refreshVisible()
	end)

	refreshItem()
	refreshToggles()
	refreshVisible()
end

return TouchControls
