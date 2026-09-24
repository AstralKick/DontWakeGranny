--!strict
-- InputController
-- Cross-platform gameplay bindings (ContextActionService). No on-screen buttons here: the UI
-- draws touch buttons and fires the same ClientBus intents, which are translated to remotes.
--
--   Keyboard: Shift (hold) sprint · C / LeftControl crouch · F flashlight · Q use item ·
--             Z / X / mouse wheel cycle item
--   Gamepad:  L3 or L2 (hold) sprint · B crouch (no menu open) · Y flashlight · R1 use item ·
--             L1 cycle item · DPad left/right or L1/R1 spectate while dead
--   UI (GamepadNav, not here): ButtonSelect = lobby HUD focus / match Settings, DPadUp = focus
--             on-screen buttons, B = back. ButtonStart is Roblox's system menu: never bound.
--
--   InputController:GetInputType()    -> "Touch" | "Gamepad" | "KeyboardMouse"
--   InputController:GetSelectedItem() -> item key or ""
-- Fires ClientBus "SelectedItem"(key) and "InputTypeChanged"(kind).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local PlaceRole = shared("PlaceRole")
local ClientBus = shared("ClientBus")
local EconomyConfig = shared("EconomyConfig")

local InputController = {}

local player = Players.LocalPlayer
local PRIORITY = Enum.ContextActionPriority.High.Value

local inputType = "KeyboardMouse"
local selected = ""
local sprintSources: { [string]: boolean } = {}
local sentSprint = false
local wantCrouch = false
local menuOpen = false
local lastUse = 0

local remotes: { [string]: RemoteEvent } = {}

local function remote(name: string): RemoteEvent?
	local r = remotes[name]
	if not r then
		local Net = shared("Net")
		r = Net.Event(name)
		remotes[name] = r
	end
	return r
end

local function alive(): boolean
	return player:GetAttribute("Alive") ~= false and player.Character ~= nil
end

local function menuBlocking(): boolean
	return menuOpen or GuiService.SelectedObject ~= nil
end

-- ------------------------------------------------------------------ sprint / crouch / light

local function refreshSprint()
	local want = false
	for _, down in sprintSources do
		if down then
			want = true
			break
		end
	end
	if not alive() then
		want = false
	end
	if want ~= sentSprint then
		sentSprint = want
		local r = remote("SetSprint")
		if r then
			r:FireServer(want)
		end
	end
end

local function setSprintSource(source: string, down: boolean)
	sprintSources[source] = down or nil
	refreshSprint()
end

local function toggleCrouch()
	if not alive() or player:GetAttribute("Hidden") == true then
		return
	end
	wantCrouch = not (player:GetAttribute("Crouching") == true)
	local r = remote("SetCrouch")
	if r then
		r:FireServer(wantCrouch)
	end
end

local function toggleFlashlight()
	if not alive() then
		return
	end
	local r = remote("ToggleFlashlight")
	if r then
		r:FireServer()
	end
end

-- ------------------------------------------------------------------ items

local function itemCounts(): { [string]: number }
	local raw = player:GetAttribute("Items")
	if typeof(raw) ~= "string" or raw == "" then
		return {}
	end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
	return if ok and typeof(decoded) == "table" then decoded else {}
end

local function available(): { string }
	local counts = itemCounts()
	local out = {}
	for _, key in EconomyConfig.ItemOrder do
		if (tonumber(counts[key]) or 0) > 0 then
			table.insert(out, key)
		end
	end
	return out
end

local function setSelected(key: string)
	if key ~= selected then
		selected = key
		ClientBus.Fire("SelectedItem", key)
	end
end

local function validateSelected()
	local list = available()
	if table.find(list, selected) then
		return
	end
	setSelected(list[1] or "")
end

local function cycleItem(dir: number)
	local list = available()
	if #list == 0 then
		setSelected("")
		return
	end
	local i = table.find(list, selected) or 0
	i = ((i - 1 + (if dir < 0 then -1 else 1)) % #list) + 1
	setSelected(list[i])
end

local function useItem(key: string?)
	if not alive() or player:GetAttribute("Hidden") == true then
		return
	end
	local k = if key and key ~= "" then key else selected
	if k == "" or os.clock() - lastUse < 0.4 then
		return
	end
	lastUse = os.clock()
	local cam = workspace.CurrentCamera
	local r = remote("UseItem")
	if r and cam then
		r:FireServer(k, cam.CFrame.LookVector)
	end
end

-- ------------------------------------------------------------------ input type

local function mapPreferred(v: any): string?
	if v == nil then
		return nil
	end
	local name = tostring(v)
	if name:find("Touch") then
		return "Touch"
	elseif name:find("Gamepad") then
		return "Gamepad"
	elseif name:find("Keyboard") then
		return "KeyboardMouse"
	end
	return nil
end

local function mapLast(t: Enum.UserInputType): string?
	if t == Enum.UserInputType.Touch then
		return "Touch"
	elseif t.Name:sub(1, 7) == "Gamepad" then
		return "Gamepad"
	elseif t == Enum.UserInputType.Keyboard or t.Name:sub(1, 5) == "Mouse" then
		return "KeyboardMouse"
	end
	return nil
end

local function setInputType(kind: string?)
	if kind and kind ~= inputType then
		inputType = kind
		ClientBus.Fire("InputTypeChanged", kind)
	end
end

local function hookInputType()
	local okPref, pref = pcall(function()
		return (UserInputService :: any).PreferredInput
	end)
	if okPref and pref ~= nil then
		setInputType(mapPreferred(pref))
		UserInputService:GetPropertyChangedSignal("PreferredInput" :: any):Connect(function()
			setInputType(mapPreferred((UserInputService :: any).PreferredInput))
		end)
	else
		-- Fallback: last used device.
		local initial = if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
			then "Touch"
			elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then "Gamepad"
			else mapLast(UserInputService:GetLastInputType())
		setInputType(initial)
		UserInputService.LastInputTypeChanged:Connect(function(t)
			setInputType(mapLast(t))
		end)
	end
	-- Late listeners (UI) also get the initial value.
	task.defer(function()
		ClientBus.Fire("InputTypeChanged", inputType)
	end)
end

function InputController:GetInputType(): string
	return inputType
end

function InputController:GetSelectedItem(): string
	return selected
end

-- ------------------------------------------------------------------ bindings

local Begin = Enum.UserInputState.Begin
local Pass = Enum.ContextActionResult.Pass
local Sink = Enum.ContextActionResult.Sink

local function bindMatch()
	ContextActionService:BindActionAtPriority("DWG_Sprint", function(_, state, input)
		local source = if input.KeyCode == Enum.KeyCode.ButtonL3 or input.KeyCode == Enum.KeyCode.ButtonL2 then "Pad" else "Key"
		if state == Begin then
			setSprintSource(source, true)
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			setSprintSource(source, false)
		end
		return Pass -- let shift-lock / other listeners see it too
	end, false, PRIORITY, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonL3, Enum.KeyCode.ButtonL2)

	ContextActionService:BindActionAtPriority("DWG_Crouch", function(_, state, input)
		if input.KeyCode == Enum.KeyCode.ButtonB and menuBlocking() then
			return Pass
		end
		if state == Begin then
			toggleCrouch()
		end
		return Sink
	end, false, PRIORITY, Enum.KeyCode.C, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonB)

	ContextActionService:BindActionAtPriority("DWG_Flashlight", function(_, state)
		if state == Begin then
			toggleFlashlight()
		end
		return Sink
	end, false, PRIORITY, Enum.KeyCode.F, Enum.KeyCode.ButtonY)

	ContextActionService:BindActionAtPriority("DWG_UseItem", function(_, state)
		if state == Begin then
			useItem(nil)
		end
		return Sink
	end, false, PRIORITY, Enum.KeyCode.Q, Enum.KeyCode.ButtonR1)

	ContextActionService:BindActionAtPriority("DWG_CycleItem", function(_, state, input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			if state == Enum.UserInputState.Change and input.Position.Z ~= 0 then
				cycleItem(if input.Position.Z > 0 then -1 else 1)
			end
			return Pass
		end
		if state == Begin then
			cycleItem(if input.KeyCode == Enum.KeyCode.Z then -1 else 1)
		end
		return Sink
	end, false, PRIORITY, Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.ButtonL1, Enum.UserInputType.MouseWheel)

	ContextActionService:BindActionAtPriority("DWG_Spectate", function(_, state, input)
		if player:GetAttribute("Alive") ~= false then
			return Pass
		end
		if state == Begin then
			local back = input.KeyCode == Enum.KeyCode.DPadLeft or input.KeyCode == Enum.KeyCode.ButtonL1
			ClientBus.Fire("SpectateCycle", if back then -1 else 1)
		end
		return Sink
	end, false, PRIORITY, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
end

local function disableReset()
	task.spawn(function()
		for _ = 1, 20 do
			local ok = pcall(StarterGui.SetCore, StarterGui, "ResetButtonCallback", false)
			if ok then
				return
			end
			task.wait(1)
		end
	end)
end

-- ------------------------------------------------------------------ lifecycle

function InputController.Preload() end

function InputController:Start()
	hookInputType()

	ClientBus.On("OpenMenu", function()
		menuOpen = true
	end)
	ClientBus.On("CloseMenus", function()
		menuOpen = false
	end)
	ClientBus.On("UIMenuOpen", function(isOpen: boolean)
		menuOpen = isOpen == true
	end)

	if not PlaceRole.IsMatch then
		return
	end
	disableReset()
	bindMatch()

	-- UI intents (touch buttons etc.)
	ClientBus.On("SprintInput", function(isDown: boolean)
		setSprintSource("UI", isDown == true)
	end)
	ClientBus.On("CrouchToggle", toggleCrouch)
	ClientBus.On("FlashlightToggle", toggleFlashlight)
	ClientBus.On("UseItem", function(key: string?)
		useItem(key)
	end)
	ClientBus.On("CycleItem", function(dir: number?)
		cycleItem(dir or 1)
	end)
	ClientBus.On("LeaveHiding", function()
		local r = remote("LeaveHiding")
		if r then
			r:FireServer()
		end
	end)

	-- Items
	player:GetAttributeChangedSignal("Items"):Connect(validateSelected)
	validateSelected()

	-- Keep local intent in sync with authoritative state.
	player:GetAttributeChangedSignal("Crouching"):Connect(function()
		wantCrouch = player:GetAttribute("Crouching") == true
	end)
	player:GetAttributeChangedSignal("Alive"):Connect(function()
		if player:GetAttribute("Alive") == false then
			table.clear(sprintSources)
		end
		refreshSprint()
	end)
	player.CharacterAdded:Connect(function()
		sentSprint = false -- server resets sprint intent state on spawn; resend if still held
		task.defer(refreshSprint)
	end)
	UserInputService.WindowFocusReleased:Connect(function()
		table.clear(sprintSources)
		refreshSprint()
	end)
end

return InputController
