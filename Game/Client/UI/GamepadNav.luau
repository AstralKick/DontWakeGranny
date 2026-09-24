--!strict
-- GamepadNav (both places)
-- Console / gamepad-only access to on-screen buttons that aren't inside a MenuHost menu.
-- Gameplay normally runs with GuiService.SelectedObject = nil (sticks move the kid, not a
-- cursor). Screens register "focus zones"; the player pulls focus into them on demand:
--
--   ButtonSelect  Lobby: focus the HUD menu buttons (Shop … Settings, Invite) / release focus
--                 Match: open / close Settings (or release focus if something is focused)
--                 (ButtonStart is reserved by Roblox for the system menu: never bind it.)
--   DPadUp        focus the best visible zone (Lobby HUD, car panel, spectate Options,
--                 morning / game-over buttons) when nothing is focused
--   ButtonB       fallback "back": releases focus to gameplay when no menu is open
--                 (menus, the death panel and the car panel bind their own B above this)
--
--   GamepadNav.AddZone(name, {Priority = n, Get = fn() -> GuiObject?, Sticky = bool?})
--       Sticky zones get focus back automatically after a menu closes (e.g. the car panel).
--   GamepadNav.RemoveZone(name)
--   GamepadNav.Focus(obj?)   select obj if the player is on a gamepad (nil = release)
--   GamepadNav.FocusBest(stickyOnly?) -> boolean
--   GamepadNav.Hint(parent, pad, key?, text?, size?) -> glyph + caption, gamepad-only

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIWidgets = require(script.Parent:WaitForChild("UIWidgets"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local MenuHost = require(script.Parent:WaitForChild("MenuHost"))

local C = Theme.Color
local GamepadNav = {}

type Zone = { Priority: number, Get: () -> GuiObject?, Sticky: boolean? }
local zones: { [string]: Zone } = {}
local isMatch = false

local HIGH = Enum.ContextActionPriority.High.Value
local Sink = Enum.ContextActionResult.Sink
local Pass = Enum.ContextActionResult.Pass

local function usable(obj: GuiObject?): boolean
	if not obj or not obj.Parent or not obj.Selectable then
		return false
	end
	-- visible all the way up to the ScreenGui
	local node: Instance? = obj
	while node and node:IsA("GuiObject") do
		if not node.Visible then
			return false
		end
		node = node.Parent
	end
	if node and node:IsA("LayerCollector") and not node.Enabled then
		return false
	end
	return true
end

function GamepadNav.AddZone(name: string, zone: Zone)
	zones[name] = zone
end

function GamepadNav.RemoveZone(name: string)
	zones[name] = nil
end

function GamepadNav.Focus(obj: GuiObject?)
	if obj == nil then
		if GuiService.SelectedObject then
			GuiService.SelectedObject = nil
		end
		return
	end
	if UIState.Input == "Gamepad" and usable(obj) then
		GuiService.SelectedObject = obj
	end
end

function GamepadNav.FocusBest(stickyOnly: boolean?): boolean
	local best: GuiObject? = nil
	local bestP = -math.huge
	for _, z in zones do
		if (not stickyOnly or z.Sticky) and z.Priority > bestP then
			local ok, obj = pcall(z.Get)
			if ok and usable(obj) then
				best, bestP = obj, z.Priority
			end
		end
	end
	if best then
		GuiService.SelectedObject = best
		return true
	end
	return false
end

-- A gamepad-only "[glyph] Caption" chip. Returns the holder frame.
function GamepadNav.Hint(parent: Instance, pad: Enum.KeyCode, key: Enum.KeyCode?, text: string?, size: number?): Frame
	local s = size or 44
	local holder = UIKit.Box({ Name = "PadHint", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, s), Parent = parent })
	UIKit.List(holder, { Dir = Enum.FillDirection.Horizontal, Gap = 8, H = Enum.HorizontalAlignment.Left, V = Enum.VerticalAlignment.Center })
	UIWidgets.Glyph({ Parent = holder, Key = key or Enum.KeyCode.Unknown, Pad = pad, Size = s, LayoutOrder = 1 })
	if text then
		UIKit.Label({ Text = text, Font = Theme.Font.Button, TextSize = math.max(Theme.Text.Small, math.floor(s * 0.6)), Color = C.Paper, Auto = "X", Size = UDim2.fromOffset(0, s), LayoutOrder = 2, Parent = holder })
	end
	local function refresh()
		holder.Visible = UIState.Input == "Gamepad"
	end
	refresh()
	local conn = UIState.Changed:Connect(function(k)
		if k == "Input" then
			refresh()
		end
	end)
	holder.Destroying:Connect(function()
		conn:Disconnect()
	end)
	return holder
end

local function stickyRefocus()
	task.defer(function()
		if UIState.Input == "Gamepad" and not MenuHost.Current() and GuiService.SelectedObject == nil then
			GamepadNav.FocusBest(true)
		end
	end)
end

function GamepadNav.Mount(ctx: any)
	isMatch = ctx.IsMatch == true
	-- We own ButtonSelect (Roblox's auto-select would grab a random button on screen).
	pcall(function()
		GuiService.AutoSelectGuiEnabled = false
	end)

	ContextActionService:BindActionAtPriority("UINavSelect", function(_, state)
		if state ~= Enum.UserInputState.Begin then
			return Sink
		end
		if MenuHost.Current() then
			MenuHost.Close()
		elseif GuiService.SelectedObject then
			GuiService.SelectedObject = nil
		elseif isMatch then
			if MenuHost.Has("Settings") then
				MenuHost.Open("Settings")
			end
		else
			GamepadNav.FocusBest()
		end
		return Sink
	end, false, HIGH + 40, Enum.KeyCode.ButtonSelect)

	ContextActionService:BindActionAtPriority("UINavFocus", function(_, state)
		if GuiService.SelectedObject ~= nil or MenuHost.Current() then
			return Pass
		end
		if state == Enum.UserInputState.Begin and GamepadNav.FocusBest() then
			return Sink
		end
		return Pass
	end, false, HIGH - 1, Enum.KeyCode.DPadUp)

	ContextActionService:BindActionAtPriority("UINavBack", function(_, state)
		if GuiService.SelectedObject == nil or MenuHost.Current() then
			return Pass
		end
		if state == Enum.UserInputState.Begin then
			GuiService.SelectedObject = nil
		end
		return Sink
	end, false, HIGH - 1, Enum.KeyCode.ButtonB)

	UIState.Bus().On("UIMenuOpen", function(open)
		if not open then
			stickyRefocus()
		end
	end)
	UIState.Changed:Connect(function(k, v)
		if k ~= "Input" then
			return
		end
		if v == "Gamepad" then
			stickyRefocus()
		elseif GuiService.SelectedObject and not MenuHost.Current() then
			-- mouse / touch took over: drop the focus ring
			GuiService.SelectedObject = nil
		end
	end)

	-- Match: a small [Select] badge on the HUD settings gear (HudScreen names it "Settings").
	if isMatch then
		task.spawn(function()
			local gear: Instance? = nil
			for _ = 1, 40 do
				gear = ctx.HUD:FindFirstChild("Settings", true)
				if gear then
					break
				end
				task.wait(0.25)
			end
			if gear and gear:IsA("GuiObject") then
				local badge = GamepadNav.Hint(gear, Enum.KeyCode.ButtonSelect, nil, nil, 40)
				badge.AnchorPoint = Vector2.new(0.5, 0)
				badge.Position = UDim2.new(0.5, 0, 1, 2)
				badge.ZIndex = 10
			end
		end)
	end
end

return GamepadNav
