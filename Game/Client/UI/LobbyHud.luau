--!strict
-- LobbyHud (Lobby)
--   top-left   Candy counter (DataController Candy, counts up on change)
--   left       sticker buttons: Shop, Dress Up, Chores, Mailbox, Diary, Settings
--              (red dot on Mailbox when the daily is claimable, on Chores when a
--              chore is ready to claim — the server stays authoritative)
--   top-right  INVITE FRIENDS (+10% Candy per friend) -> SocialService invite
-- Lobby ProximityPrompts with attribute Menu (Shop/Daily/Cosmetics/Diary/Quests)
-- open the matching menu (ProximityPromptService.PromptTriggered, local player).
-- Gamepad: ButtonSelect / DPadUp focus the sticker grid (GamepadNav zone "LobbyHud"), Invite
-- is right of the top row, B / Select release focus back to walking.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local SocialService = game:GetService("SocialService")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))
local UIWidgets = require(script.Parent:WaitForChild("UIWidgets"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local MenuHost = require(script.Parent:WaitForChild("MenuHost"))
local NotifyScreen = require(script.Parent:WaitForChild("NotifyScreen"))
local GamepadNav = require(script.Parent:WaitForChild("GamepadNav"))

local C = Theme.Color
local LobbyHud = {}

-- Prompt attribute Menu -> MenuHost name
local PROMPT_MENUS = {
	Shop = "Shop",
	Daily = "Mailbox",
	Mailbox = "Mailbox",
	Cosmetics = "DressUp",
	DressUp = "DressUp",
	Diary = "Diary",
	Quests = "Chores",
	Chores = "Chores",
	Settings = "Settings",
}

local function today(): number
	return math.floor(os.time() / 86400)
end

local function dot(parent: Instance): Frame
	local d = UIKit.new("Frame", { Name = "Dot", BackgroundColor3 = C.Blood, Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -4, 0, 4), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 10, Parent = parent })
	UIKit.Corner(d, Theme.Corner.Round)
	UIKit.Stroke(d, 3, C.Ink)
	return d
end

function LobbyHud.Mount(ctx: any)
	local player = Players.LocalPlayer
	local Data = UIState.Data()
	local EconomyConfig = UIState.Config("EconomyConfig")

	local hud = UIKit.Box({ Name = "LobbyHud", Size = UDim2.fromScale(1, 1), Parent = ctx.HUD })

	-- ============================================================ candy counter
	local candyHolder = UIKit.Box({ Name = "Candy", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 86), Position = UDim2.fromOffset(24, 18), Parent = hud })
	local candyShadow = UIKit.new("Frame", { BackgroundColor3 = C.Shadow, BackgroundTransparency = Theme.Shadow.Transparency, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 80), Position = UDim2.fromOffset(0, Theme.Shadow.Offset), Parent = candyHolder })
	UIKit.Corner(candyShadow, Theme.Corner.Round)
	local candyFace = UIKit.new("Frame", { BackgroundColor3 = C.Night, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 80), Rotation = -1.5, ZIndex = 1, Parent = candyHolder })
	UIKit.Corner(candyFace, Theme.Corner.Round)
	UIKit.Stroke(candyFace, Theme.Stroke.Panel, C.Ink)
	UIKit.new("UIPadding", { PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22), PaddingTop = UDim.new(0, 12), Parent = candyFace })
	candyShadow.Rotation = -1.5
	local candy = UIWidgets.CandyAmount({ Parent = candyFace, Amount = 0, TextSize = 52 })
	candyFace:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		candyShadow.Size = UDim2.fromOffset(candyFace.AbsoluteSize.X / math.max(UIState.Scale, 0.01), 80)
	end)

	-- ============================================================ menu buttons
	local grid = UIKit.Box({ Name = "Menus", Size = UDim2.fromOffset(250, 440), Position = UDim2.fromOffset(28, 140), Parent = hud })
	UIKit.new("UIGridLayout", { CellSize = UDim2.fromOffset(104, 136), CellPadding = UDim2.fromOffset(22, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	local defs = {
		{ "Shop", "Shop", UIIcons.Bag, C.Rose },
		{ "DressUp", "Dress Up", UIIcons.Hanger, C.Paper },
		{ "Chores", "Chores", UIIcons.Clipboard, C.Paper },
		{ "Mailbox", "Mailbox", UIIcons.Mailbox, C.Paper },
		{ "Diary", "Diary", UIIcons.Book, C.Paper },
		{ "Settings", "Settings", UIIcons.Knobs, C.Night },
	}
	local dots: { [string]: Frame } = {}
	local order: { TextButton } = {}
	for i, d in defs do
		local cell = UIKit.Box({ LayoutOrder = i, Parent = grid })
		local b = UIKit.IconButton({
			Parent = cell,
			Name = d[1],
			Size = 96,
			Color = d[4],
			Icon = d[3],
			Caption = d[2],
			Position = UDim2.fromOffset(4, 0),
			Tilt = ((i * 53) % 5) - 2,
			OnClick = function()
				MenuHost.Toggle(d[1])
			end,
		})
		dots[d[1]] = dot(b.Button)
		table.insert(order, b.Button)
	end
	-- a 2-column grid: tell the gamepad how rows connect
	for i, btn in order do
		btn.NextSelectionUp = order[i - 2]
		btn.NextSelectionDown = order[i + 2]
		btn.NextSelectionLeft = if i % 2 == 0 then order[i - 1] else nil
		btn.NextSelectionRight = if i % 2 == 1 then order[i + 1] else nil
	end
	UIKit.Twitcher((order[5].Parent :: any) :: GuiObject, 12, 25, 6) -- the diary twitches, sometimes

	-- ============================================================ invite
	local inviteHolder = UIKit.Box({ Name = "Invite", Size = UDim2.fromOffset(330, 110), Position = UDim2.new(1, -24, 0, 18), AnchorPoint = Vector2.new(1, 0), Parent = hud })
	local invite = UIKit.Button({
		Parent = inviteHolder,
		Text = "INVITE FRIENDS",
		Color = C.Rose,
		Size = UDim2.fromOffset(330, 92),
		TextSize = 32,
		OnClick = function()
			local ok, can = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
			if not ok or not can then
				NotifyScreen.Toast("Invites aren't available right now.", "Info")
				return
			end
			local okPrompt = pcall(function()
				local options = Instance.new("ExperienceInviteOptions")
				options.LaunchData = tostring(player.UserId)
				options.PromptMessage = "Come rob Grandma with me. Shhh."
				SocialService:PromptGameInvite(player, options)
			end)
			if not okPrompt then
				NotifyScreen.Toast("Couldn't open invites. Try again!", "Bad")
			end
		end,
	})
	local pct = math.floor((EconomyConfig.FriendBonusPerFriend or 0.1) * 100 + 0.5)
	UIKit.Tag({ Parent = inviteHolder, Text = `+{pct}% Candy per friend`, Color = C.Mustard, TextSize = 24, Position = UDim2.new(0, -14, 1, -8), AnchorPoint = Vector2.new(0, 0.5), Tilt = -5, ZIndex = 6 })
	UIKit.Bob(invite.Instance, 2, 3.8)

	-- ============================================================ gamepad
	-- ButtonSelect / DPadUp pull focus into the sticker grid (GamepadNav); B lets go.
	-- Invite hangs off the right of the top row.
	local inviteBtn = invite.Button
	order[2].NextSelectionRight = inviteBtn
	inviteBtn.NextSelectionLeft = order[2]
	inviteBtn.NextSelectionDown = order[2]
	inviteBtn.NextSelectionUp = nil
	GamepadNav.AddZone("LobbyHud", {
		Priority = 10,
		Get = function()
			return if grid.Visible then order[1] else nil
		end,
	})
	local padHint = GamepadNav.Hint(hud, Enum.KeyCode.ButtonSelect, nil, "Menu", 48)
	padHint.Position = UDim2.fromOffset(34, 590)

	-- ============================================================ data
	local shown: { [string]: boolean } = {}
	local function refreshDots()
		local d = Data:Get("Daily")
		dots.Mailbox.Visible = typeof(d) == "table" and (d.LastClaimDay or 0) < today()
		local q = Data:Get("Quests")
		local ready = false
		if typeof(q) == "table" and typeof(q.List) == "table" then
			for _, quest in q.List do
				if not quest.Claimed and (quest.Progress or 0) >= (quest.Target or 1) then
					ready = true
				end
			end
		end
		dots.Chores.Visible = ready
		for name, dd in dots do
			if dd.Visible and not shown[name] then
				UIKit.Pop(dd :: any, 0.5)
			end
			shown[name] = dd.Visible
		end
	end

	task.spawn(function()
		Data:WaitReady()
		candy:Set(Data:GetCandy())
		refreshDots()
		Data.Changed:Connect(function(key, value)
			if key == "Candy" then
				candy:Set(tonumber(value) or Data:GetCandy(), true)
				UIKit.Pop(candyFace :: any, 1.1, 0.25)
			elseif key == "Daily" or key == "Quests" then
				refreshDots()
			end
		end)
		-- the day can roll over while you're standing around
		while true do
			task.wait(60)
			refreshDots()
		end
	end)

	-- ============================================================ world prompts
	ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
		if who ~= player then
			return
		end
		local m = prompt:GetAttribute("Menu")
		local name = if typeof(m) == "string" then PROMPT_MENUS[m] else nil
		if name and MenuHost.Has(name) then
			MenuHost.Open(name)
		end
	end)

	-- hide the lobby HUD buttons while a menu is up (the menu is the focus)
	UIState.Bus().On("UIMenuOpen", function(open)
		grid.Visible = not open
		inviteHolder.Visible = not open
		padHint.Visible = not open and UIState.Input == "Gamepad"
	end)
end

return LobbyHud
