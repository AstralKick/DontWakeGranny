--!strict
-- EndScreen (Match)
--   Phase "GameOver": "EVERYONE GOT CAUGHT", countdown to GameOverEnd, a big
--                     CONTINUE RUN (Product ContinueRun; hidden if Id = 0 or none left)
--   Phase "Ended":    "GRANDMA WINS — you made it to Night n", back-to-lobby timer
--   Phase "Victory":  "HAPPY HALLOWEEN — YOU SURVIVED 31 NIGHTS" with falling candy
--   Finale remote:    Lit (pumpkin count pop) / Open ("GET TO THE CAR" tag) / Escaped

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))
local UIWidgets = require(script.Parent:WaitForChild("UIWidgets"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local NotifyScreen = require(script.Parent:WaitForChild("NotifyScreen"))
local GamepadNav = require(script.Parent:WaitForChild("GamepadNav"))

local C = Theme.Color
local EndScreen = {}

function EndScreen.Mount(ctx: any)
	local player = Players.LocalPlayer
	local MS = ReplicatedStorage:WaitForChild("MatchState") :: Folder
	local Net = UIState.Net()
	local Monetization = UIState.Config("MonetizationConfig")
	local GameConfig = UIState.Config("GameConfig")
	local EconomyConfig = UIState.Config("EconomyConfig")

	-- We draw these moments ourselves.
	NotifyScreen.Suppress("HAPPY HALLOWEEN")
	NotifyScreen.Suppress("GRANDMA WINS")

	local screen = UIKit.Box({ Name = "End", Size = UDim2.fromScale(1, 1), Visible = false, Parent = ctx.Overlay })
	local dim = UIKit.new("Frame", { Name = "EndDim", BackgroundColor3 = C.Ink, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = ctx.Bleed })
	local token = 0

	local function clear()
		token += 1
		for _, c in screen:GetChildren() do
			c:Destroy()
		end
	end
	local function hide()
		clear()
		screen.Visible = false
		if dim.Visible then
			UIKit.Tween(dim, 0.4, { BackgroundTransparency = 1 }).Completed:Once(function()
				if not screen.Visible then
					dim.Visible = false
				end
			end)
		end
		if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(screen) then
			GuiService.SelectedObject = nil
		end
	end
	local function open(dimColor: Color3, alpha: number)
		clear()
		screen.Visible = true
		dim.BackgroundColor3 = dimColor
		dim.Visible = true
		dim.BackgroundTransparency = 1
		UIKit.Tween(dim, 0.6, { BackgroundTransparency = alpha })
	end

	local function countdownTo(label: TextLabel, endsAt: number, fmt: (number) -> string)
		local my = token
		task.spawn(function()
			while token == my do
				local left = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
				label.Text = fmt(left)
				if left <= 0 then
					break
				end
				task.wait(0.25)
			end
		end)
	end

	-- ============================================================ game over
	local function showGameOver()
		open(Color3.fromRGB(30, 10, 18), 0.3)
		local title = UIKit.Title({ Text = "EVERYONE GOT CAUGHT", TextSize = 100, Color = C.Blood, Stroke = 7, Size = UDim2.new(1, 0, 0, 120), Position = UDim2.fromScale(0.5, 0.24), AnchorPoint = Vector2.new(0.5, 0.5), Crooked = 10, Parent = screen })
		UIKit.Pop(title, 1.4, 0.3)
		UIKit.Shake(title, 8, 0.35)
		UIKit.Twitcher(title, 3, 6, 4)
		UIKit.Label({ Text = "Grandma's tucking you all in…", Font = Theme.Font.Body, TextSize = Theme.Text.Header, Color = C.Rose, Size = UDim2.new(1, 0, 0, 56), Position = UDim2.fromScale(0.5, 0.35), AnchorPoint = Vector2.new(0.5, 0.5), Parent = screen })

		local left = MS:GetAttribute("ContinuesLeft") or 0
		local product = Monetization.Products.ContinueRun
		if product and product.Id ~= 0 and left > 0 then
			local btn = UIKit.Button({
				Parent = screen,
				Text = `CONTINUE RUN  <font size="26">· {left} left</font>`,
				TextSize = 46,
				Color = C.Rose,
				Size = UDim2.fromOffset(620, 130),
				Position = UDim2.fromScale(0.5, 0.52),
				AnchorPoint = Vector2.new(0.5, 0.5),
				OnClick = function()
					local ok, res, reason = pcall(function()
						return Net.Function("RequestPurchase"):InvokeServer("Product", "ContinueRun")
					end)
					if not ok or not res then
						NotifyScreen.Toast(if typeof(reason) == "string" then reason else "Not right now.", "Bad")
					end
				end,
			})
			btn.Button.Modal = true
			GamepadNav.AddZone("GameOver", {
				Priority = 30,
				Get = function()
					return if screen.Visible and btn.Instance.Parent then btn.Button else nil
				end,
			})
			UIKit.Label({ Text = "Anyone can buy it — it saves the whole team. Replay this night; lost loot stays lost.", Font = Theme.Font.Body, TextSize = Theme.Text.Small, Color = C.PaperDim, Stroke = false, Size = UDim2.new(0.8, 0, 0, 34), Position = UDim2.new(0.5, 0, 0.52, 86), AnchorPoint = Vector2.new(0.5, 0), Parent = screen })
			UIKit.Pop(btn.Instance :: any, 0.6, 0.35)
			UIKit.Bob(btn.Instance, 3, 3.5)
			if UIState.Input == "Gamepad" then
				task.defer(function()
					GuiService.SelectedObject = btn.Button
				end)
			end
		end
		local timer = UIKit.Label({ Text = "", Font = Theme.Font.Button, TextSize = Theme.Text.Body, Color = C.Paper, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0.5, 0, 1, -60), AnchorPoint = Vector2.new(0.5, 1), Parent = screen })
		local endsAt = MS:GetAttribute("GameOverEnd") or (workspace:GetServerTimeNow() + (GameConfig.GameOverTime or 20))
		countdownTo(timer, endsAt, function(n)
			return if n > 0 then `Back to the lobby in {n}…` else "Back to the lobby…"
		end)
	end

	-- ============================================================ ended (grandma wins)
	local function showEnded()
		open(C.Ink, 0.2)
		local n = MS:GetAttribute("Night") or 1
		local t = UIKit.Title({ Text = "GRANDMA WINS", TextSize = 120, Color = C.Blood, Stroke = 7, Size = UDim2.new(1, 0, 0, 140), Position = UDim2.fromScale(0.5, 0.36), AnchorPoint = Vector2.new(0.5, 0.5), Crooked = 3, Parent = screen })
		UIKit.Pop(t, 0.6, 0.4)
		UIKit.Label({ Text = `You made it to Night {n}. She'll be waiting.`, Font = Theme.Font.Body, TextSize = Theme.Text.Header, Color = C.Paper, Size = UDim2.new(1, 0, 0, 56), Position = UDim2.fromScale(0.5, 0.48), AnchorPoint = Vector2.new(0.5, 0.5), Parent = screen })
		local timer = UIKit.Label({ Text = "", Font = Theme.Font.Button, TextSize = Theme.Text.Body, Color = C.PaperDim, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0.5, 0, 1, -60), AnchorPoint = Vector2.new(0.5, 1), Parent = screen })
		countdownTo(timer, workspace:GetServerTimeNow() + (GameConfig.ReturnToLobbyDelay or 8), function(s)
			return if s > 0 then `Mom's picking you up in {s}…` else "Mom's here."
		end)
	end

	-- ============================================================ victory
	local function confetti(my: number)
		task.spawn(function()
			local makers = { UIIcons.Candy, UIIcons.Pumpkin :: any, UIIcons.Candy }
			while token == my do
				local f = UIKit.Box({ Size = UDim2.fromOffset(math.random(40, 70), math.random(34, 50)), Position = UDim2.new(math.random(), 0, 0, -80), Rotation = math.random(-40, 40), Parent = screen })
				local mk = makers[math.random(1, #makers)]
				if mk == UIIcons.Pumpkin then
					UIIcons.Pumpkin(f, true)
				else
					UIIcons.Candy(f, if math.random() < 0.5 then C.Mustard else C.Pumpkin)
				end
				local dur = math.random(28, 45) / 10
				UIKit.Tween(f, dur, { Position = UDim2.new(f.Position.X.Scale + (math.random() - 0.5) * 0.2, 0, 1, 80), Rotation = f.Rotation + math.random(-200, 200) }, Enum.EasingStyle.Linear).Completed:Once(function()
					f:Destroy()
				end)
				task.wait(if UIState.ReduceMotion then 0.9 else 0.12)
			end
		end)
	end

	local function showVictory()
		open(Color3.fromRGB(60, 24, 10), 0.35)
		local my = token
		confetti(my)
		local holder, body = UIKit.Panel({
			Parent = screen,
			Size = UDim2.fromOffset(1100, 520),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = C.Night,
			Tilt = -2,
			Tape = true,
			Stitch = true,
			ZIndex = 5,
		})
		UIKit.Title({ Text = "HAPPY HALLOWEEN", TextSize = 120, Color = C.Pumpkin, Stroke = 7, Size = UDim2.new(1, 0, 0, 140), Position = UDim2.fromOffset(0, 30), Crooked = 7, Parent = body })
		UIKit.Title({ Text = "YOU SURVIVED 31 NIGHTS", TextSize = 60, Color = C.Paper, Stroke = 5, Size = UDim2.new(1, 0, 0, 70), Position = UDim2.fromOffset(0, 180), Parent = body })
		UIKit.Label({ Text = "Grandma's gone quiet. Mom's honking. Don't look back.", Font = Theme.Font.Body, TextSize = Theme.Text.Body + 2, Color = C.Rose, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 262), Parent = body })
		local bonusRow = UIKit.Box({ Size = UDim2.new(1, 0, 0, 90), Position = UDim2.fromOffset(0, 320), Parent = body })
		UIKit.List(bonusRow, { Dir = Enum.FillDirection.Horizontal, Gap = 12, V = Enum.VerticalAlignment.Center })
		local amt = UIWidgets.CandyAmount({ Parent = bonusRow, Amount = 0, Prefix = "+", TextSize = 70, LayoutOrder = 1 })
		UIKit.Label({ Text = "survivor's bonus", Font = Theme.Font.Body, TextSize = Theme.Text.Body, Color = C.Paper, Auto = "X", Size = UDim2.fromOffset(0, 50), LayoutOrder = 2, Parent = bonusRow })
		local rewards = UIKit.Label({ Text = "Unlocked: Jack-o'-Lantern flashlight & Survivor's Sack", Font = Theme.Font.Button, TextSize = Theme.Text.Small, Color = C.Mustard, Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 420), Visible = false, Parent = body })
		UIKit.Pop(holder :: any, 0.4, 0.5)
		UIState.Play("Victory")
		task.delay(0.8, function()
			if token == my then
				amt:Set(EconomyConfig.VictoryBonus or 2500, true)
			end
		end)
		task.delay(1.8, function()
			if token == my then
				rewards.Visible = true
				UIKit.Pop(rewards :: any, 0.6)
			end
		end)
	end

	-- ============================================================ finale beats
	local escapeTag: Frame? = nil
	Net.Event("Finale").OnClientEvent:Connect(function(stage, data)
		data = if typeof(data) == "table" then data else {}
		if stage == "Lit" then
			local lit, total = data.Lit or 0, data.Total or 5
			local card = UIKit.Box({ Size = UDim2.fromOffset(700, 160), Position = UDim2.fromScale(0.5, 0.3), AnchorPoint = Vector2.new(0.5, 0.5), Parent = ctx.Overlay })
			local ic = UIKit.Box({ Size = UDim2.fromOffset(110, 110), Position = UDim2.new(0.5, 0, 0, 0), AnchorPoint = Vector2.new(0.5, 0), Parent = card })
			UIIcons.Pumpkin(ic, true)
			local who = if typeof(data.By) == "string" then data.By else "Someone"
			UIKit.Label({ Text = `{who} lit a pumpkin!  <font color="#FF8C14">{lit}/{total}</font>`, Rich = true, Font = Theme.Font.Button, TextSize = Theme.Text.Header - 6, Size = UDim2.new(1, 0, 0, 50), Position = UDim2.fromOffset(0, 112), Parent = card })
			UIKit.Pop(card :: any, 1.5, 0.25)
			UIState.Play("LanternLight")
			task.delay(2.4, function()
				UIKit.PopOut(card :: any, 0.2).Completed:Once(function()
					card:Destroy()
				end)
			end)
		elseif stage == "Open" then
			if escapeTag then
				escapeTag:Destroy()
			end
			local tag = UIKit.Tag({ Parent = ctx.HUD, Text = "ESCAPE TO MOM'S CAR!", Font = Theme.Font.Title, TextSize = 44, Color = C.Pumpkin, Position = UDim2.new(0.5, 0, 0, 24), AnchorPoint = Vector2.new(0.5, 0), Tilt = -2, ZIndex = 30 })
			UIKit.Pop(tag :: any, 1.4, 0.3)
			if not UIState.ReduceMotion then
				local s = UIKit.ScaleOf(tag)
				game:GetService("TweenService"):Create(s, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.08 }):Play()
			end
			escapeTag = tag
		elseif stage == "Escaped" then
			if data.Name == player.DisplayName then
				if escapeTag then
					escapeTag:Destroy()
					escapeTag = nil
				end
				NotifyScreen.Banner("YOU ESCAPED!", "Wait in the car. Pray for your friends.", C.Mint)
			end
		end
	end)

	local function onPhase()
		local phase = MS:GetAttribute("Phase")
		if phase ~= "Night" and escapeTag then
			escapeTag:Destroy()
			escapeTag = nil
		end
		if phase == "GameOver" then
			showGameOver()
		elseif phase == "Victory" then
			showVictory()
		elseif phase == "Ended" then
			-- Victory keeps its card until the teleport; a wipe shows "GRANDMA WINS".
			if not screen:FindFirstChild("Panel") then
				showEnded()
			end
		else
			hide()
		end
	end
	MS:GetAttributeChangedSignal("Phase"):Connect(onPhase)
	MS:GetAttributeChangedSignal("ContinuesLeft"):Connect(function()
		if MS:GetAttribute("Phase") == "GameOver" then
			showGameOver()
		end
	end)
	onPhase()
end

return EndScreen
