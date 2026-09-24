--!strict
-- UIController
-- Root of the whole client UI. Creates the ScreenGuis (one Root frame + one
-- viewport-driven UIScale each), tracks the preferred input type and reduce-motion,
-- then mounts either the Lobby or the Match screens (PlaceRole).
--
-- ScreenGuis (DisplayOrder):
--   DWG_HUD      5   edge-pinned gameplay HUD, touch controls
--   DWG_Bleed    8   full-bleed dims & vignettes (ScreenInsets None)
--   DWG_Overlay 10   title cards, death, morning, game over, diary page
--   DWG_Menus   20   modal menus (MenuHost)
--   DWG_Notify  30   toasts & banners
--   DWG_Fade    40   car departure fade (ScreenInsets None)
-- Prompt BillboardGuis live in PlayerGui.DWG_Prompts. On console (IsTenFootInterface) every
-- non-bleed Root gets an extra TV title-safe UIPadding. GamepadNav owns ButtonSelect / DPadUp
-- focus for non-menu buttons; HidingHints marks hiding spots while Grandma is awake (Match).
--
-- Every screen module in ReplicatedStorage.UI exposes Mount(ctx). ctx fields:
--   HUD, Bleed, Overlay, Menus, Notify, Fade (Root frames), PromptFolder, PlayerGui

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")

local UIController = {}

local UIFolder = ReplicatedStorage:WaitForChild("UI")

local function uiModule(name: string): any
	return require(UIFolder:WaitForChild(name) :: ModuleScript)
end

local UITheme = uiModule("UITheme")
local UIState = uiModule("UIState")
local UIKit = uiModule("UIKit")

local TV_SAFE = 0.035 -- per edge, console only

local roots: { [string]: Frame } = {}
local scales: { UIScale } = {}

local function makeScreen(playerGui: PlayerGui, name: string, order: number, fullBleed: boolean?): Frame
	local gui = UIKit.new("ScreenGui", {
		Name = "DWG_" .. name,
		ResetOnSpawn = false,
		DisplayOrder = order,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	-- IgnoreGuiInset and ScreenInsets are coupled; set them in this order.
	gui.IgnoreGuiInset = fullBleed == true
	gui.ScreenInsets = if fullBleed then Enum.ScreenInsets.None else Enum.ScreenInsets.CoreUISafeInsets
	gui.Parent = playerGui
	local root = UIKit.Box({ Name = "Root", Size = UDim2.fromScale(1, 1), Parent = gui })
	local scale = UIKit.new("UIScale", { Name = "ViewportScale", Parent = root })
	if not fullBleed and GuiService:IsTenFootInterface() then
		-- Console: keep everything inside the TV title-safe area on top of CoreUISafeInsets,
		-- since many TVs still overscan.
		local pad = UDim.new(TV_SAFE, 0)
		UIKit.new("UIPadding", { Name = "TVSafe", PaddingLeft = pad, PaddingRight = pad, PaddingTop = pad, PaddingBottom = pad, Parent = root })
	end
	table.insert(scales, scale)
	roots[name] = root
	return root
end

local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local vp = camera.ViewportSize
	local base = UITheme.BaseResolution
	local s = math.clamp(math.min(vp.X / base.X, vp.Y / base.Y), UITheme.MinScale, UITheme.MaxScale)
	for _, sc in scales do
		sc.Scale = s
		local root = sc.Parent :: Frame
		-- Root is sized 1/s so after scaling it exactly covers the ScreenGui.
		root.Size = UDim2.fromScale(1 / s, 1 / s)
	end
	UIState.Set("Scale", s)
end

-- ---------------------------------------------------------------- input kind

local function detectInput(): string
	local ok, pref = pcall(function()
		return (UserInputService :: any).PreferredInput
	end)
	if ok and pref ~= nil then
		local name = tostring(pref)
		if name:find("Touch") then
			return "Touch"
		elseif name:find("Gamepad") then
			return "Gamepad"
		end
		return "KeyboardMouse"
	end
	local last = UserInputService:GetLastInputType()
	if last == Enum.UserInputType.Touch then
		return "Touch"
	elseif last.Name:find("Gamepad") then
		return "Gamepad"
	elseif UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "Touch"
	end
	return "KeyboardMouse"
end

local function watchInput()
	UIState.Set("Input", detectInput())
	local ok = pcall(function()
		UserInputService:GetPropertyChangedSignal("PreferredInput" :: any):Connect(function()
			UIState.Set("Input", detectInput())
		end)
	end)
	if not ok then
		UserInputService.LastInputTypeChanged:Connect(function()
			UIState.Set("Input", detectInput())
		end)
	end
	-- Studio only: force the UI's input kind for testing layouts / gamepad focus, e.g.
	-- LocalPlayer:SetAttribute("DebugInput", "Gamepad") from a client command.
	if game:GetService("RunService"):IsStudio() then
		local lp = Players.LocalPlayer
		lp:GetAttributeChangedSignal("DebugInput"):Connect(function()
			local v = lp:GetAttribute("DebugInput")
			UIState.Set("Input", if v == "Touch" or v == "Gamepad" or v == "KeyboardMouse" then v else detectInput())
		end)
	end
	-- A gameplay controller may also announce it; trust whichever speaks last.
	UIState.Bus().On("InputTypeChanged", function(kind)
		if kind == "Touch" or kind == "Gamepad" or kind == "KeyboardMouse" then
			UIState.Set("Input", kind)
		end
	end)
end

-- ---------------------------------------------------------------- settings

local function watchSettings()
	task.spawn(function()
		local Data = UIState.Data()
		Data:WaitReady()
		local function apply()
			local s = Data:Get("Settings")
			UIState.Set("ReduceMotion", s ~= nil and s.ReduceFlashes == true)
		end
		apply()
		Data.Changed:Connect(function(key)
			if key == "Settings" then
				apply()
			end
		end)
	end)
end

-- ---------------------------------------------------------------- mounting

local function mount(ctx: any, names: { string })
	for _, name in names do
		task.spawn(function()
			local ok, err = pcall(function()
				local m = uiModule(name)
				if m.Mount then
					m.Mount(ctx)
				end
			end)
			if not ok then
				warn(`[UIController] {name} failed to mount: {err}`)
			end
		end)
	end
end

function UIController.Preload() end

function UIController:Start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	local PlaceRole = shared("PlaceRole")

	local ctx = {
		HUD = makeScreen(playerGui, "HUD", 5),
		Bleed = makeScreen(playerGui, "Bleed", 8, true),
		Overlay = makeScreen(playerGui, "Overlay", 10),
		Menus = makeScreen(playerGui, "Menus", 20),
		Notify = makeScreen(playerGui, "Notify", 30),
		Fade = makeScreen(playerGui, "Fade", 40, true),
		PromptFolder = UIKit.new("Folder", { Name = "DWG_Prompts", Parent = playerGui }),
		PlayerGui = playerGui,
		IsMatch = PlaceRole.IsMatch,
		IsLobby = PlaceRole.IsLobby,
	}

	updateScale()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local cam = workspace.CurrentCamera
		if cam then
			cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
		end
		updateScale()
	end)
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end

	watchInput()
	watchSettings()

	local MenuHost = uiModule("MenuHost")
	MenuHost.Init(ctx.Menus)
	local Bus = UIState.Bus()
	Bus.On("OpenMenu", function(name)
		if typeof(name) == "string" and MenuHost.Has(name) then
			MenuHost.Open(name)
		end
	end)
	Bus.On("CloseMenus", function()
		MenuHost.Close()
	end)

	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, false)

	mount(ctx, { "NotifyScreen", "PromptScreen", "SettingsMenu", "DiaryScreen", "GamepadNav" })
	if PlaceRole.IsMatch then
		mount(ctx, { "HudScreen", "TouchControls", "IntroScreen", "LootFeedback", "DeathScreen", "HidingScreen", "MorningScreen", "EndScreen", "HidingHints", "FavoritePrompt", "HowToPlay" })
	else
		mount(ctx, { "LobbyHud", "CarPanel", "ShopMenu", "DressUpMenu", "MailboxMenu", "ChoresMenu", "LeaderboardBoard" })
	end
end

return UIController
