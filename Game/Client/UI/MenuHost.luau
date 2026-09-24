--!strict
-- MenuHost
-- One-at-a-time modal menus with gamepad focus handling.
--   MenuHost.Init(menusRoot)                     called by UIController
--   MenuHost.Register(name, build)               build(host) -> menu {Root, First?, OnOpen?(arg), OnClose?()}
--   MenuHost.Open(name, arg?) / MenuHost.Close() / MenuHost.Toggle(name)
--   MenuHost.Current() -> string?
--   MenuHost.Shell{Title, Color, Size, Tilt, Accent} -> shell {Root, Panel, Body, Close}
--       builds the standard paper modal (dim backdrop, title tab, X button).
--
-- Rules (docs/UI_STYLE.md): ButtonB always closes, the first button is focused when a
-- menu opens with a gamepad, and focus is handed back to gameplay (SelectedObject = nil)
-- on close. The X button has Modal = true so the mouse is freed in first person.
-- ClientBus: listens to "OpenMenu"(name) / "CloseMenus"(); fires "UIMenuOpen"(isOpen).

local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIState = require(script.Parent:WaitForChild("UIState"))

local C = Theme.Color
local MenuHost = {}

local root: Frame? = nil
local builders: { [string]: (any) -> any } = {}
local built: { [string]: any } = {}
local current: string? = nil
local busy = false

local BACK_ACTION = "UIMenuBack"

function MenuHost.Init(menusRoot: Frame)
	root = menusRoot
	-- Fallback for B: if the engine's own gamepad selection swallows ButtonB before our
	-- ContextActionService binding sees it, UserInputService still reports the press.
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.ButtonB and current then
			local name = current
			task.defer(function()
				if current == name then
					MenuHost.Close()
				end
			end)
		end
	end)
	UIState.Changed:Connect(function(key, value)
		if key == "Input" and value == "Gamepad" and current then
			local m = built[current]
			if m and m.First and m.First.Parent then
				GuiService.SelectedObject = m.First
			end
		end
	end)
end

function MenuHost.Register(name: string, build: (any) -> any)
	builders[name] = build
end

function MenuHost.Current(): string?
	return current
end

function MenuHost.Has(name: string): boolean
	return builders[name] ~= nil
end

local function bus(): any
	local ok, b = pcall(UIState.Bus)
	return if ok then b else nil
end

function MenuHost.Close()
	local name = current
	if not name then
		return
	end
	current = nil
	ContextActionService:UnbindAction(BACK_ACTION)
	local m = built[name]
	if m then
		if m.OnClose then
			task.spawn(m.OnClose)
		end
		local panel = m.Panel or m.Root
		local tw = UIKit.PopOut(panel)
		if m.Backdrop then
			UIKit.Tween(m.Backdrop, Theme.Motion.Close, { BackgroundTransparency = 1 })
		end
		tw.Completed:Once(function()
			if current ~= name then
				m.Root.Visible = false
			end
		end)
	end
	if GuiService.SelectedObject then
		GuiService.SelectedObject = nil
	end
	local b = bus()
	if b then
		b.Fire("UIMenuOpen", false)
	end
end

function MenuHost.Open(name: string, arg: any?)
	if busy or not root then
		return
	end
	local build = builders[name]
	if not build then
		warn("[MenuHost] unknown menu", name)
		return
	end
	if current == name then
		return
	end
	if current then
		local prev = built[current]
		if prev then
			prev.Root.Visible = false
			if prev.OnClose then
				task.spawn(prev.OnClose)
			end
		end
		current = nil
	end
	local m = built[name]
	if not m then
		busy = true
		local ok, res = pcall(build, MenuHost)
		busy = false
		if not ok then
			warn("[MenuHost] failed to build", name, res)
			return
		end
		m = res
		built[name] = m
		m.Root.Parent = root
	end
	current = name
	m.Root.Visible = true
	UIKit.Pop(m.Panel or m.Root)
	if m.Backdrop then
		m.Backdrop.BackgroundTransparency = 1
		UIKit.Tween(m.Backdrop, Theme.Motion.Pop, { BackgroundTransparency = 0.45 })
	end
	if m.OnOpen then
		task.spawn(m.OnOpen, arg)
	end
	UIState.Play("UIClick")
	ContextActionService:BindActionAtPriority(BACK_ACTION, function(_, state)
		if state == Enum.UserInputState.Begin then
			MenuHost.Close()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 50, Enum.KeyCode.ButtonB)
	if UIState.Input == "Gamepad" then
		task.defer(function()
			local first = m.First
			if typeof(m.GetFirst) == "function" then
				first = m.GetFirst()
			end
			if first and first.Parent and current == name then
				GuiService.SelectedObject = first
			end
		end)
	end
	local b = bus()
	if b then
		b.Fire("UIMenuOpen", true)
	end
end

function MenuHost.Toggle(name: string, arg: any?)
	if current == name then
		MenuHost.Close()
	else
		MenuHost.Open(name, arg)
	end
end

-- Re-focus the current menu's preferred button (after rebuilding its contents).
function MenuHost.Refocus(obj: GuiObject?)
	if UIState.Input == "Gamepad" and current then
		local m = built[current]
		local target = obj or (m and m.First)
		if target and target.Parent then
			GuiService.SelectedObject = target
		end
	end
end

-- ---------------------------------------------------------------- standard shell

-- props: Name, Title, Color (panel), Accent (title tab), Size (UDim2 of root),
-- Max (Vector2), Tilt, Drip
function MenuHost.Shell(p: { [string]: any }): any
	local rootFrame = UIKit.Box({ Name = p.Name or "Menu", Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 1 })
	local backdrop = UIKit.new("TextButton", {
		Name = "Backdrop",
		Text = "",
		AutoButtonColor = false,
		Selectable = false,
		BackgroundColor3 = C.Ink,
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = rootFrame,
	})
	backdrop.Activated:Connect(function()
		MenuHost.Close()
	end)
	local max = p.Max or Vector2.new(1500, 880)
	local holder, body = UIKit.Panel({
		Name = "Panel",
		Parent = rootFrame,
		Size = p.Size or UDim2.fromScale(0.86, 0.8),
		Position = UDim2.fromScale(0.5, 0.53),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = p.Color or C.Night,
		Tilt = p.Tilt or -1,
		Drip = p.Drip,
		Stitch = p.Stitch,
		Pad = 28,
		ZIndex = 2,
	})
	UIKit.SizeLimit(holder, max.X, max.Y, 600, 420)

	-- Title tab sticking out of the top-left corner.
	local tab = UIKit.Tag({
		Name = "TitleTab",
		Parent = holder,
		Text = p.Title or "",
		Font = Theme.Font.Title,
		TextSize = Theme.Text.Header,
		Color = p.Accent or C.Rose,
		TextColor = C.Paper,
		Position = UDim2.fromOffset(34, -30),
		Tilt = -3,
		ZIndex = 6,
	})
	local tabText = tab:FindFirstChild("Text", true) :: TextLabel
	UIKit.Stroke(tabText, 3, C.Ink, true)

	local close = UIKit.Button({
		Name = "Close",
		Parent = holder,
		Text = "X",
		Color = C.Blood,
		Size = UDim2.fromOffset(84, 90),
		Position = UDim2.new(1, 22, 0, -30),
		AnchorPoint = Vector2.new(1, 0),
		Corner = Theme.Corner.Round,
		ZIndex = 7,
		OnClick = function()
			MenuHost.Close()
		end,
	})
	close.Button.Modal = true -- frees the mouse while a menu is up
	close.Button.SelectionImageObject = UIKit.SelectionImage("Round")

	-- Body sits under the title tab.
	local inner = UIKit.Box({ Name = "Body", Size = UDim2.new(1, 0, 1, -40), Position = UDim2.fromOffset(0, 40), ZIndex = 3, Parent = body })

	local shell = {
		Root = rootFrame,
		Backdrop = backdrop,
		Panel = holder,
		Body = inner,
		Close = close,
		TitleText = tabText,
	}
	return shell
end

return MenuHost
