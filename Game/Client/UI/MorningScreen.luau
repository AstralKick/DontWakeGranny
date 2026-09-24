--!strict
-- MorningScreen (Match)
-- NightSummary remote during Phase "Morning": the report card.
--   "YOU SURVIVED NIGHT 6" + count-up rows (stashed, dawn auto-stash, survival bonus,
--   friend bonus) or a "Caught — back next night" row, the new Candy total, then
--   NEXT: Night 7 + new-area teaser + checkpoint stamp. A small, quiet Sugar Rush
--   button (only if the product has an Id). Auto-dismisses when the phase changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIWidgets = require(script.Parent:WaitForChild("UIWidgets"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local NotifyScreen = require(script.Parent:WaitForChild("NotifyScreen"))
local GamepadNav = require(script.Parent:WaitForChild("GamepadNav"))

local C = Theme.Color
local MorningScreen = {}

function MorningScreen.Mount(ctx: any)
	local MS = ReplicatedStorage:WaitForChild("MatchState") :: Folder
	local Net = UIState.Net()
	local Monetization = UIState.Config("MonetizationConfig")

	local screen = UIKit.Box({ Name = "Morning", Size = UDim2.fromScale(1, 1), Visible = false, Parent = ctx.Overlay })
	local wash = UIKit.new("Frame", { Name = "MorningWash", BackgroundColor3 = Color3.fromRGB(255, 214, 170), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = ctx.Bleed })
	local token = 0

	local function hide()
		token += 1
		if not screen.Visible then
			return
		end
		UIKit.Tween(wash, 0.5, { BackgroundTransparency = 1 }).Completed:Once(function()
			wash.Visible = false
		end)
		local card = screen:FindFirstChild("Card") :: Frame?
		if card then
			UIKit.PopOut(card, 0.2).Completed:Once(function()
				screen.Visible = false
				card:Destroy()
			end)
		else
			screen.Visible = false
		end
	end

	local function show(s: any)
		token += 1
		local my = token
		for _, c in screen:GetChildren() do
			c:Destroy()
		end
		screen.Visible = true
		wash.Visible = true
		wash.BackgroundTransparency = 1
		UIKit.Tween(wash, 0.8, { BackgroundTransparency = 0.72 })
		UIState.Play("Rooster")

		local holder, body = UIKit.Panel({
			Name = "Card",
			Parent = screen,
			Size = UDim2.fromOffset(980, 760),
			Position = UDim2.fromScale(0.5, 0.52),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = C.Paper,
			Tilt = 1.5,
			Tape = true,
			Stitch = true,
			Pad = 34,
		})
		UIKit.SizeLimit(holder, 980, 760)
		UIKit.Pop(holder :: any, 0.7, 0.4)
		UIKit.List(body, { Gap = 8 })

		local night = s.Night or (MS:GetAttribute("Night") or 1)
		local survived = s.Survived == true
		UIKit.Title({
			Text = if typeof(s.ChapterComplete) == "string" then "CHAPTER COMPLETE!" elseif survived then `YOU SURVIVED NIGHT {night}` else `YOUR TEAM SURVIVED NIGHT {night}`,
			TextSize = if survived then 66 else 56,
			Color = if survived then C.Mint else C.Rose,
			Stroke = 5,
			Size = UDim2.new(1, 0, 0, 84),
			LayoutOrder = 1,
			Crooked = 5,
			Parent = body,
		})
		UIKit.Label({
			Text = if typeof(s.ChapterComplete) == "string" then `You beat {s.ChapterComplete}. Grandma's moving somewhere new...` elseif survived then "The sun's up. Grandma's snoring again." else "You got caught — but you're back tonight.",
			Font = Theme.Font.Body,
			TextSize = Theme.Text.Body,
			Color = C.Bruise,
			Stroke = false,
			Size = UDim2.new(1, 0, 0, 34),
			LayoutOrder = 2,
			Parent = body,
		})

		-- rows
		local rows = UIKit.Box({ Size = UDim2.new(1, -60, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Parent = body })
		UIKit.List(rows, { Gap = 6 })
		local rowDefs: { { any } } = {}
		table.insert(rowDefs, { "Stashed in the trunk", s.Banked or 0, C.Ink })
		if (s.AutoBanked or 0) > 0 then
			table.insert(rowDefs, { "Auto-stashed at dawn", s.AutoBanked, C.Ink })
		end
		if survived then
			table.insert(rowDefs, { "Survival bonus", s.Bonus or 0, C.Ink })
		end
		if (s.Friends or 0) > 0 then
			local pct = math.floor(((s.FriendMult or 1) - 1) * 100 + 0.5)
			table.insert(rowDefs, { `Friend bonus · {s.Friends} friend{if s.Friends == 1 then "" else "s"}`, `+{pct}%`, C.Bruise })
		end
		if not survived or (s.Lost or 0) > 0 then
			table.insert(rowDefs, { "Caught — dropped", -(s.Lost or 0), C.Blood })
		end

		local labels: { { TextLabel | any } } = {}
		for i, def in rowDefs do
			local row = UIKit.Box({ Size = UDim2.new(1, 0, 0, 46), LayoutOrder = i, Parent = rows })
			local line = UIKit.new("Frame", { BackgroundColor3 = C.PaperDim, Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -2), Parent = row })
			UIKit.Corner(line, UDim.new(0.5, 0))
			UIKit.Label({ Text = def[1], Font = Theme.Font.Body, TextSize = Theme.Text.Body + 2, Color = def[3], Stroke = false, XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromScale(0.65, 1), Parent = row })
			local val = UIKit.Label({ Text = "", Font = Theme.Font.Button, TextSize = Theme.Text.Body + 2, Color = if def[3] == C.Blood then C.Blood else C.Ink, Stroke = false, XAlign = Enum.TextXAlignment.Right, Size = UDim2.fromScale(0.35, 1), Position = UDim2.fromScale(0.65, 0), Parent = row })
			row.Visible = false
			labels[i] = { row, val, def[2] }
		end

		-- total
		local totalRow = UIKit.Box({ Size = UDim2.new(1, 0, 0, 80), LayoutOrder = 4, Visible = false, Parent = body })
		UIKit.List(totalRow, { Dir = Enum.FillDirection.Horizontal, Gap = 14, V = Enum.VerticalAlignment.Center })
		UIKit.Label({ Text = "You have", Font = Theme.Font.Body, TextSize = Theme.Text.Header, Color = C.Ink, Stroke = false, Auto = "X", Size = UDim2.fromOffset(0, 60), LayoutOrder = 1, Parent = totalRow })
		local total = UIWidgets.CandyAmount({ Parent = totalRow, Amount = 0, TextSize = 64, LayoutOrder = 2 })

		-- next night
		local nextRow = UIKit.Box({ Size = UDim2.new(1, 0, 0, 120), LayoutOrder = 5, Visible = false, Parent = body })
		UIKit.List(nextRow, { Dir = Enum.FillDirection.Horizontal, Gap = 22, V = Enum.VerticalAlignment.Center })
		local nextNight = s.NextNight or (night + 1)
		UIKit.Label({ Text = "NEXT:", Font = Theme.Font.Button, TextSize = Theme.Text.Body, Color = C.Bruise, Stroke = false, Auto = "X", Size = UDim2.fromOffset(0, 50), LayoutOrder = 1, Parent = nextRow })
		UIKit.Title({ Text = if nextNight >= 31 then "HALLOWEEN" else `Night {nextNight}`, TextSize = 56, Color = if nextNight >= 31 then C.Pumpkin else C.Rose, Stroke = 4, Auto = "X", Size = UDim2.fromOffset(0, 70), LayoutOrder = 2, Parent = nextRow })
		local function stamp(text: string, color: Color3, order: number, rot: number): Frame
			local st = UIKit.new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 62), Rotation = rot, LayoutOrder = order, Visible = false, Parent = nextRow })
			UIKit.Corner(st, UDim.new(0, 10))
			UIKit.Stroke(st, 5, color)
			UIKit.Pad(st, 0, 16, 0)
			UIKit.Label({ Text = text, Font = Theme.Font.Button, TextSize = 28, Color = color, Stroke = false, Auto = "X", Size = UDim2.fromOffset(0, 62), Parent = st })
			return st
		end
		local stamps: { Frame } = {}
		if typeof(s.NextNewArea) == "string" and s.NextNewArea ~= "" then
			table.insert(stamps, stamp(if typeof(s.NextChapter) == "string" then `NEW MAP: {string.upper(s.NextChapter)}` else `NEW AREA: {s.NextNewArea}`, C.Blood, 3, -6))
		end
		if typeof(s.Checkpoint) == "number" then
			table.insert(stamps, stamp("CHAPTER UNLOCKED · REPLAY ANY TIME", C.Bruise, 4, 5))
		end

		-- quiet Sugar Rush offer
		local rush = Monetization.Products.SugarRush
		if rush and rush.Id ~= 0 then
			local btn = UIKit.Button({
				Parent = body,
				Text = "Sugar Rush · 2× loot next night for everyone",
				TextSize = 24,
				Color = C.Mustard,
				Size = UDim2.fromOffset(560, 66),
				LayoutOrder = 6,
				OnClick = function()
					local ok, res, reason = pcall(function()
						return Net.Function("RequestPurchase"):InvokeServer("Product", "SugarRush")
					end)
					if not ok or not res then
						NotifyScreen.Toast(if typeof(reason) == "string" then reason else "Not right now.", "Info")
					end
				end,
			})
			btn.Button.Modal = true
			btn.Instance.Visible = false
			-- gamepad: never auto-focused (you may still be walking); DPadUp reaches it
			local hint = GamepadNav.Hint(btn.Instance, Enum.KeyCode.DPadUp, nil, nil, 44)
			hint.AnchorPoint = Vector2.new(1, 0.5)
			hint.Position = UDim2.new(0, -10, 0.5, -3)
			GamepadNav.AddZone("Morning", {
				Priority = 20,
				Get = function()
					return if token == my and screen.Visible then btn.Button else nil
				end,
			})
			task.delay(2.6, function()
				if token == my then
					btn.Instance.Visible = true
					UIKit.Pop(btn.Instance :: any, 0.7)
				end
			end)
		end

		-- sequence the count-ups
		task.spawn(function()
			task.wait(0.6)
			for _, l in labels do
				if token ~= my then
					return
				end
				local row, val, v = l[1], l[2], l[3]
				row.Visible = true
				UIKit.Pop(row :: any, 0.85, 0.2)
				if typeof(v) == "number" then
					local neg = v < 0
					UIKit.CountUp(val, 0, math.abs(v), 0.6, function(n)
						return (if neg then "−" else "+") .. UIWidgets.Number(n)
					end, true)
				else
					val.Text = tostring(v)
				end
				task.wait(0.55)
			end
			if token ~= my then
				return
			end
			totalRow.Visible = true
			UIKit.Pop(totalRow :: any, 0.7)
			local before = (s.Candy or 0) - (s.AutoBanked or 0) - (s.Bonus or 0)
			total:Set(math.max(0, before))
			total:Set(s.Candy or 0, true)
			UIState.Play("Bank")
			task.wait(0.9)
			if token ~= my then
				return
			end
			nextRow.Visible = true
			UIKit.Pop(nextRow :: any, 0.8)
			for _, st in stamps do
				task.wait(0.35)
				if token ~= my then
					return
				end
				st.Visible = true
				UIKit.Pop(st :: any, 1.7, 0.18)
				UIState.Play("NewArea")
			end
		end)
	end

	Net.Event("NightSummary").OnClientEvent:Connect(function(summary)
		if typeof(summary) == "table" then
			show(summary)
		end
	end)
	MS:GetAttributeChangedSignal("Phase"):Connect(function()
		if MS:GetAttribute("Phase") ~= "Morning" then
			hide()
		end
	end)
end

return MorningScreen
