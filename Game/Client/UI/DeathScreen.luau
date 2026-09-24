--!strict
-- DeathScreen (Match)
-- Caught -> (jumpscare plays: ClientBus JumpscareStarted/Finished) -> this screen:
--   "GRANDMA GOT YOU", what you dropped, "your team can still make it" copy, and
--   SPECTATE (default, auto after a few seconds) / REVIVE / Return to lobby (confirm).
-- Then the spectate bar: "Watching NAME" + arrows (ClientBus "SpectateCycle"),
-- the watched teammate's pillowcase. Never shows Grandma's location.
-- Gamepad: panel focus starts on SPECTATE, B = spectate (or "Stay" on the leave confirm).
-- Spectating keeps GUI focus off: DPad / LB RB switch teammate (InputController), Y = options.
--
-- ClientBus fired: "SpectateRequest"(on) (new; SpectateController may start/stop on it),
--                  "SpectateCycle"(dir)
-- ClientBus heard: "JumpscareFinished", "SpectateTarget"(player?)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIWidgets = require(script.Parent:WaitForChild("UIWidgets"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local NotifyScreen = require(script.Parent:WaitForChild("NotifyScreen"))
local GamepadNav = require(script.Parent:WaitForChild("GamepadNav"))

local C = Theme.Color
local DeathScreen = {}

local AUTO_SPECTATE = 7

function DeathScreen.Mount(ctx: any)
	local player = Players.LocalPlayer
	local MS = ReplicatedStorage:WaitForChild("MatchState") :: Folder
	local Net = UIState.Net()
	local Bus = UIState.Bus()
	local Monetization = UIState.Config("MonetizationConfig")
	local GrandmaConfig = UIState.Config("GrandmaConfig")

	local dim = UIKit.new("Frame", { Name = "DeathDim", BackgroundColor3 = Color3.fromRGB(30, 10, 18), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = ctx.Bleed })
	local screen = UIKit.Box({ Name = "Death", Size = UDim2.fromScale(1, 1), Visible = false, Parent = ctx.Overlay })
	local bar = UIKit.Box({ Name = "SpectateBar", Size = UDim2.fromOffset(820, 150), Position = UDim2.new(0.5, 0, 1, -24), AnchorPoint = Vector2.new(0.5, 1), Visible = false, Parent = ctx.Overlay })

	local state = {
		Caught = false,
		Lost = 0,
		LostCount = 0,
		CanRevive = false,
		Free = false,
		Spectating = false,
		Interacted = false,
		Token = 0,
	}
	local target: Player? = nil

	-- ============================================================ spectate bar
	local _barHolder, barBody = UIKit.Panel({ Parent = bar, Size = UDim2.fromScale(1, 1), Color = C.Night, Tilt = 1, Pad = 14 })
	local left = UIKit.Button({ Parent = barBody, Text = "‹", TextSize = 60, Color = C.Bruise, Size = UDim2.fromOffset(96, 104), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Corner = Theme.Corner.Round, OnClick = function()
		Bus.Fire("SpectateCycle", -1)
	end })
	local right = UIKit.Button({ Parent = barBody, Text = "›", TextSize = 60, Color = C.Bruise, Size = UDim2.fromOffset(96, 104), Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Corner = Theme.Corner.Round, OnClick = function()
		Bus.Fire("SpectateCycle", 1)
	end })
	left.Button.NextSelectionRight = right.Button
	right.Button.Modal = true -- free the mouse while spectating
	right.Button.NextSelectionLeft = left.Button
	local watchShot: ImageLabel? = nil
	local watchName = UIKit.Label({ Text = "Watching…", Font = Theme.Font.Button, TextSize = Theme.Text.Header - 4, Rich = true, Size = UDim2.new(1, -330, 0, 52), Position = UDim2.new(0.5, 40, 0, 6), AnchorPoint = Vector2.new(0.5, 0), Parent = barBody })
	local watchInfo = UIKit.Label({ Text = "", Font = Theme.Font.Body, TextSize = Theme.Text.Body, Color = C.Mustard, Stroke = false, Rich = true, Size = UDim2.new(1, -330, 0, 36), Position = UDim2.new(0.5, 40, 0, 62), AnchorPoint = Vector2.new(0.5, 0), Parent = barBody })
	local optionsBtn = UIKit.Button({ Parent = bar, Text = "Options", TextSize = Theme.Text.Small, Color = C.PaperDim, Size = UDim2.fromOffset(170, 62), Position = UDim2.new(1, -20, 0, -30), AnchorPoint = Vector2.new(1, 1), OnClick = function()
		DeathScreen.ShowPanel()
	end })
	local shotHolder = UIKit.Box({ Size = UDim2.fromOffset(84, 84), Position = UDim2.new(0, 116, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Parent = barBody })

	-- gamepad hints above the bar: DPad ‹ › / LB RB switch teammate, Y = options.
	-- (Gamepad spectating keeps GUI focus off so the DPad isn't eaten by UI navigation.)
	local padRow = UIKit.Box({ Name = "PadHints", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 48), Position = UDim2.new(0, 16, 0, -12), AnchorPoint = Vector2.new(0, 1), Parent = bar })
	UIKit.List(padRow, { Dir = Enum.FillDirection.Horizontal, Gap = 18, H = Enum.HorizontalAlignment.Left, V = Enum.VerticalAlignment.Center })
	local function padPair(a: Enum.KeyCode, b: Enum.KeyCode, text: string, order: number)
		local pair = UIKit.Box({ AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 48), LayoutOrder = order, Parent = padRow })
		UIKit.List(pair, { Dir = Enum.FillDirection.Horizontal, Gap = 6, H = Enum.HorizontalAlignment.Left, V = Enum.VerticalAlignment.Center })
		UIWidgets.Glyph({ Parent = pair, Pad = a, Size = 44, LayoutOrder = 1 })
		UIWidgets.Glyph({ Parent = pair, Pad = b, Size = 44, LayoutOrder = 2 })
		UIKit.Label({ Text = text, Font = Theme.Font.Button, TextSize = Theme.Text.Small, Auto = "X", Size = UDim2.fromOffset(0, 48), LayoutOrder = 3, Parent = pair })
	end
	padPair(Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1, "Switch", 1)
	local yHint = UIKit.Box({ AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 48), LayoutOrder = 2, Parent = padRow })
	UIKit.List(yHint, { Dir = Enum.FillDirection.Horizontal, Gap = 6, H = Enum.HorizontalAlignment.Left, V = Enum.VerticalAlignment.Center })
	UIWidgets.Glyph({ Parent = yHint, Pad = Enum.KeyCode.ButtonY, Size = 44, LayoutOrder = 1 })
	UIKit.Label({ Text = "Options", Font = Theme.Font.Button, TextSize = Theme.Text.Small, Auto = "X", Size = UDim2.fromOffset(0, 48), LayoutOrder = 2, Parent = yHint })
	local function refreshPad()
		local pad = UIState.Input == "Gamepad"
		padRow.Visible = pad
		optionsBtn.Instance.Visible = not pad
	end
	refreshPad()
	UIState.Changed:Connect(function(k)
		if k == "Input" then
			refreshPad()
		end
	end)

	local targetConn: RBXScriptConnection? = nil
	local function refreshTarget()
		if targetConn then
			targetConn:Disconnect()
			targetConn = nil
		end
		if watchShot then
			watchShot:Destroy()
			watchShot = nil
		end
		local t = target
		if not t or t.Parent ~= Players then
			watchName.Text = "Nobody left to watch…"
			watchInfo.Text = "Hold on. Morning's coming."
			return
		end
		watchShot = UIKit.Headshot({ Parent = shotHolder, UserId = t.UserId, Size = 84 })
		watchName.Text = `Watching <font color="#D97A8A">{t.DisplayName}</font>`
		local function info()
			local slots, max = t:GetAttribute("CarrySlots") or 0, t:GetAttribute("MaxSlots") or 5
			local value = t:GetAttribute("CarryValue") or 0
			local extra = if t:GetAttribute("CarryingPrize") == true then "  ·  has the PRIZE" elseif t:GetAttribute("Hidden") == true then "  ·  hiding" else ""
			watchInfo.Text = `Pillowcase {slots}/{max}  ·  {UIWidgets.Number(value)} Candy{extra}`
		end
		info()
		targetConn = t.AttributeChanged:Connect(info)
		UIKit.Pop(watchName :: any, 0.8)
	end

	-- ============================================================ death panel
	local panelHolder, panelBody = UIKit.Panel({
		Parent = screen,
		Size = UDim2.fromOffset(1000, 620),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = C.Night,
		Tilt = -2,
		Drip = true,
		DripX = 0.78,
	})
	UIKit.SizeLimit(panelHolder, 1000, 620)
	local title = UIKit.Title({ Text = "GRANDMA GOT YOU", TextSize = 92, Color = C.Blood, Stroke = 6, Size = UDim2.new(1, 0, 0, 110), Position = UDim2.fromOffset(0, 6), Crooked = 9, Parent = panelBody })
	local lostLine = UIKit.Label({ Text = "", Font = Theme.Font.Body, TextSize = Theme.Text.Header - 6, Color = C.Paper, Rich = true, Size = UDim2.new(1, 0, 0, 48), Position = UDim2.fromOffset(0, 124), Parent = panelBody })
	local teamLine = UIKit.Label({ Text = "", Font = Theme.Font.Body, TextSize = Theme.Text.Body, Color = C.Mint, Stroke = false, Wrap = true, Size = UDim2.new(0.9, 0, 0, 80), Position = UDim2.new(0.5, 0, 0, 180), AnchorPoint = Vector2.new(0.5, 0), Parent = panelBody })

	local buttons = UIKit.Box({ Size = UDim2.new(1, 0, 0, 110), Position = UDim2.fromOffset(0, 290), Parent = panelBody })
	UIKit.List(buttons, { Dir = Enum.FillDirection.Horizontal, Gap = 24, V = Enum.VerticalAlignment.Center })

	local spectateBtn = UIKit.Button({ Parent = buttons, Text = "SPECTATE", Color = C.Mint, Size = UDim2.fromOffset(360, 104), LayoutOrder = 1, OnClick = function()
		DeathScreen.StartSpectate()
	end })
	spectateBtn.Button.Modal = true
	local reviveBtn = UIKit.Button({ Parent = buttons, Text = "REVIVE", Color = C.Rose, Size = UDim2.fromOffset(460, 104), LayoutOrder = 2, TextSize = 30 })
	local lobbyBtn = UIKit.Button({ Parent = panelBody, Text = "Return to lobby", Color = C.PaperDim, Size = UDim2.fromOffset(300, 74), TextSize = Theme.Text.Small, Position = UDim2.new(0.5, 0, 0, 430), AnchorPoint = Vector2.new(0.5, 0) })
	spectateBtn.Button.NextSelectionDown = lobbyBtn.Button
	reviveBtn.Button.NextSelectionDown = lobbyBtn.Button
	lobbyBtn.Button.NextSelectionUp = spectateBtn.Button

	-- confirm strip for leaving
	local confirm = UIKit.Box({ Name = "Confirm", Size = UDim2.new(1, 0, 0, 110), Position = UDim2.fromOffset(0, 420), Visible = false, Parent = panelBody })
	UIKit.Label({ Text = "Leave the run? Your team keeps going without you.", Font = Theme.Font.Body, TextSize = Theme.Text.Body, Color = C.Paper, Size = UDim2.new(1, 0, 0, 36), Parent = confirm })
	local confirmRow = UIKit.Box({ Size = UDim2.new(1, 0, 0, 80), Position = UDim2.fromOffset(0, 40), Parent = confirm })
	UIKit.List(confirmRow, { Dir = Enum.FillDirection.Horizontal, Gap = 20, V = Enum.VerticalAlignment.Center })
	local function stay()
		confirm.Visible = false
		lobbyBtn.Instance.Visible = true
		if UIState.Input == "Gamepad" then
			GuiService.SelectedObject = lobbyBtn.Button
		end
	end
	local stayBtn = UIKit.Button({ Parent = confirmRow, Text = "Stay", Color = C.Mint, Size = UDim2.fromOffset(220, 76), LayoutOrder = 1, OnClick = stay })
	UIKit.Button({ Parent = confirmRow, Text = "Leave", Color = C.Blood, Size = UDim2.fromOffset(220, 76), LayoutOrder = 2, OnClick = function()
		Net.Event("ReturnToLobby"):FireServer()
		confirm.Visible = false
		NotifyScreen.Toast("Heading back to the lobby…", "Info")
	end })
	lobbyBtn.Button.Activated:Connect(function()
		state.Interacted = true
		lobbyBtn.Instance.Visible = false
		confirm.Visible = true
		UIKit.Pop(confirm :: any, 0.9)
		if UIState.Input == "Gamepad" then
			GuiService.SelectedObject = stayBtn.Button
		end
	end)

	-- DPadUp re-grabs the death panel if focus was lost (e.g. the engine's own B deselect)
	GamepadNav.AddZone("Death", {
		Priority = 60,
		Get = function()
			if not screen.Visible then
				return nil
			end
			return if confirm.Visible then stayBtn.Button else spectateBtn.Button
		end,
	})

	local function tokens(): number
		local ok, t = pcall(function()
			return UIState.Data():Get("Tokens")
		end)
		return if ok and typeof(t) == "table" then (t.Revive or 0) else 0
	end

	local reviveMode = "None"
	local function refreshRevive()
		local canPaid = Monetization.Products.Revive and Monetization.Products.Revive.Id ~= 0
		if not state.CanRevive or MS:GetAttribute("Phase") ~= "Night" then
			reviveMode = "None"
		elseif state.Free then
			reviveMode = "Free"
		elseif tokens() > 0 then
			reviveMode = "Token"
		elseif canPaid then
			reviveMode = "Paid"
		else
			reviveMode = "None"
		end
		reviveBtn.Instance.Visible = reviveMode ~= "None"
		if reviveMode == "Free" then
			reviveBtn:SetText("REVIVE · <font size=\"24\">FIRST ONE'S ON GRANDMA</font>")
			reviveBtn:SetColor(C.Mustard)
		elseif reviveMode == "Token" then
			reviveBtn:SetText(`USE SAVED REVIVE <font size="24">({tokens()})</font>`)
			reviveBtn:SetColor(C.Rose)
		elseif reviveMode == "Paid" then
			reviveBtn:SetText("REVIVE NOW")
			reviveBtn:SetColor(C.Rose)
		end
		spectateBtn.Button.NextSelectionRight = if reviveMode ~= "None" then reviveBtn.Button else nil
		reviveBtn.Button.NextSelectionLeft = spectateBtn.Button
	end

	local reviving = false
	reviveBtn.Button.Activated:Connect(function()
		state.Interacted = true
		if reviving then
			return
		end
		reviving = true
		reviveBtn:SetText("…")
		local ok, res, reason = pcall(function()
			if reviveMode == "Free" then
				return Net.Function("RequestFreeRevive"):InvokeServer()
			elseif reviveMode == "Token" then
				return Net.Function("UseReviveToken"):InvokeServer()
			elseif reviveMode == "Paid" then
				return Net.Function("RequestPurchase"):InvokeServer("Product", "Revive")
			end
			return false
		end)
		reviving = false
		if not ok or not res then
			NotifyScreen.Toast(if typeof(reason) == "string" then reason else "Can't revive right now.", "Bad")
			if reviveMode == "Free" then
				state.Free = false
			end
		end
		refreshRevive()
	end)

	-- ============================================================ flow

	local backBound = false
	local function bindBack(on: boolean)
		if on and not backBound then
			backBound = true
			ContextActionService:BindActionAtPriority("UIDeathBack", function(_, st)
				if st == Enum.UserInputState.Begin then
					if confirm.Visible then
						stay()
					else
						DeathScreen.StartSpectate()
					end
				end
				return Enum.ContextActionResult.Sink
			end, false, Enum.ContextActionPriority.High.Value + 15, Enum.KeyCode.ButtonB)
		elseif not on and backBound then
			backBound = false
			ContextActionService:UnbindAction("UIDeathBack")
		end
	end

	-- Y opens the death panel again while spectating (gamepad has no Options button).
	local function bindOptions(on: boolean)
		if on then
			ContextActionService:BindActionAtPriority("UISpectateOptions", function(_, st)
				if st == Enum.UserInputState.Begin then
					DeathScreen.ShowPanel()
				end
				return Enum.ContextActionResult.Sink
			end, false, Enum.ContextActionPriority.High.Value + 15, Enum.KeyCode.ButtonY)
		else
			ContextActionService:UnbindAction("UISpectateOptions")
		end
	end

	local function hideAll()
		screen.Visible = false
		bar.Visible = false
		bindBack(false)
		bindOptions(false)
		if dim.Visible then
			UIKit.Tween(dim, 0.4, { BackgroundTransparency = 1 }).Completed:Once(function()
				if not screen.Visible then
					dim.Visible = false
				end
			end)
		end
		if GuiService.SelectedObject and (GuiService.SelectedObject:IsDescendantOf(screen) or GuiService.SelectedObject:IsDescendantOf(bar)) then
			GuiService.SelectedObject = nil
		end
	end

	function DeathScreen.ShowPanel()
		refreshRevive()
		bar.Visible = false
		screen.Visible = true
		dim.Visible = true
		UIKit.Tween(dim, 0.4, { BackgroundTransparency = 0.35 })
		confirm.Visible = false
		lobbyBtn.Instance.Visible = true
		UIKit.Pop(panelHolder :: any, 0.7, 0.35)
		bindBack(true)
		bindOptions(false)
		if UIState.Input == "Gamepad" then
			GuiService.SelectedObject = spectateBtn.Button
		end
	end

	function DeathScreen.StartSpectate()
		if not state.Caught then
			return
		end
		state.Spectating = true
		screen.Visible = false
		bindBack(false)
		UIKit.Tween(dim, 0.4, { BackgroundTransparency = 1 })
		bar.Visible = true
		UIKit.Pop(bar :: any, 0.8)
		refreshPad()
		bindOptions(true)
		Bus.Fire("SpectateRequest", true)
		refreshTarget()
		-- gamepad: release focus so DPad / LB / RB drive the spectate camera, not the UI
		if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(screen) then
			GuiService.SelectedObject = nil
		end
	end

	local function showDeath()
		state.Interacted = false
		state.Spectating = false
		local aliveCount = MS:GetAttribute("AliveCount") or 0
		if state.LostCount > 0 then
			lostLine.Text = `You dropped {state.LostCount} thing{if state.LostCount == 1 then "" else "s"} · <font color="#E0B04F">{UIWidgets.Number(state.Lost)} Candy</font> — gone.`
		else
			lostLine.Text = "Your pillowcase was empty. Lucky you."
		end
		teamLine.Text = if aliveCount > 0
			then "Your team can still make it to 6 AM. If they do, you're back next night."
			else "That was the last of you…"
		DeathScreen.ShowPanel()
		task.delay(0.4, UIKit.Twitch, title, 5)
		local myToken = state.Token
		-- auto-spectate countdown on the button
		task.spawn(function()
			for i = AUTO_SPECTATE, 1, -1 do
				if state.Token ~= myToken or state.Interacted or not screen.Visible then
					spectateBtn:SetText("SPECTATE")
					return
				end
				spectateBtn:SetText(`SPECTATE <font size="24">({i})</font>`)
				task.wait(1)
			end
			spectateBtn:SetText("SPECTATE")
			if state.Token == myToken and not state.Interacted and screen.Visible and (MS:GetAttribute("AliveCount") or 0) > 0 then
				DeathScreen.StartSpectate()
			end
		end)
	end

	local waitingForScare = false
	Net.Event("Caught").OnClientEvent:Connect(function(formKey, lost, lostCount, canRevive, freeRevive)
		state.Token += 1
		state.Caught = true
		state.Lost = if typeof(lost) == "number" then lost else 0
		state.LostCount = if typeof(lostCount) == "number" then lostCount else 0
		state.CanRevive = canRevive == true
		state.Free = freeRevive == true
		waitingForScare = true
		-- If no jumpscare controller answers, show the screen after the scare's length.
		local form = GrandmaConfig.Forms[formKey] or GrandmaConfig.Forms.Normal
		local myToken = state.Token
		task.delay((form and form.Jumpscare and form.Jumpscare.Duration or 1.4) + 1.2, function()
			if waitingForScare and state.Token == myToken then
				waitingForScare = false
				showDeath()
			end
		end)
	end)
	Bus.On("JumpscareFinished", function()
		if waitingForScare then
			waitingForScare = false
			showDeath()
		end
	end)
	Bus.On("SpectateTarget", function(p)
		target = if typeof(p) == "Instance" and p:IsA("Player") then p else nil
		if state.Spectating then
			refreshTarget()
		end
	end)

	local function endDeath()
		if state.Caught or screen.Visible or bar.Visible then
			state.Caught = false
			state.Spectating = false
			waitingForScare = false
			hideAll()
			Bus.Fire("SpectateRequest", false)
		end
	end
	player:GetAttributeChangedSignal("Alive"):Connect(function()
		if player:GetAttribute("Alive") == true then
			endDeath()
		end
	end)
	MS:GetAttributeChangedSignal("Phase"):Connect(function()
		local phase = MS:GetAttribute("Phase")
		if phase ~= "Night" then
			endDeath()
		end
	end)
	MS:GetAttributeChangedSignal("AliveCount"):Connect(function()
		if screen.Visible then
			refreshRevive()
		end
	end)
end

return DeathScreen
