--!strict
-- LootFeedback (Match)
--   LootPicked(name, value, isPrize) -> "+Pocket Watch  36 (candy)" slip that flies into
--                                        the pillowcase chip; Prize -> banner-lite
--   Banked(candy, count, reason)     -> "+340 (candy) STASHED" count-up + new total
--   SearchResult(nil)                -> "Nothing here…"

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIWidgets = require(script.Parent:WaitForChild("UIWidgets"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local HudScreen = require(script.Parent:WaitForChild("HudScreen"))

local C = Theme.Color
local LootFeedback = {}

function LootFeedback.Mount(ctx: any)
	local Net = UIState.Net()
	local root = UIKit.Box({ Name = "LootFeedback", Size = UDim2.fromScale(1, 1), Parent = ctx.Overlay })
	local stack = 0

	local function pickupPop(name: string, value: number)
		stack = (stack + 1) % 3
		local slip = UIKit.new("Frame", {
			Name = "Pickup",
			BackgroundColor3 = C.Paper,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 60),
			Position = UDim2.new(0.5, 0, 1, -250 - stack * 20),
			AnchorPoint = Vector2.new(0.5, 1),
			Rotation = (math.random() - 0.5) * 6,
			Parent = root,
		})
		UIKit.Corner(slip, Theme.Corner.Round)
		UIKit.Stroke(slip, 4, C.Ink)
		UIKit.new("UIPadding", { PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 18), Parent = slip })
		UIKit.List(slip, { Dir = Enum.FillDirection.Horizontal, Gap = 10, V = Enum.VerticalAlignment.Center })
		UIKit.Label({ Text = `+{name}`, Font = Theme.Font.Button, TextSize = Theme.Text.Body, Color = C.Ink, Stroke = false, Auto = "X", Size = UDim2.fromOffset(0, 50), LayoutOrder = 1, Parent = slip })
		if value > 0 then
			UIWidgets.CandyAmount({ Parent = slip, Amount = value, TextSize = Theme.Text.Body, Color = C.Mustard, LayoutOrder = 2 })
		end
		UIKit.Pop(slip :: any, 0.5)
		UIState.Play("Pickup")
		task.delay(1.1, function()
			-- fly down into the pillowcase chip
			local carry = HudScreen.Anchors.Carry
			local target = UDim2.new(0.5, 0, 1, -110)
			if carry and carry.Parent then
				local sc = math.max(UIState.Scale, 0.01)
				local rp = root.AbsolutePosition
				local cp = carry.AbsolutePosition + carry.AbsoluteSize / 2
				target = UDim2.fromOffset((cp.X - rp.X) / sc, (cp.Y - rp.Y) / sc)
			end
			UIKit.Tween(slip, 0.35, { Position = target }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			UIKit.Tween(UIKit.ScaleOf(slip), 0.35, { Scale = 0.2 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Once(function()
				slip:Destroy()
			end)
		end)
	end

	local function prizePop(name: string)
		local holder, body = UIKit.Panel({
			Parent = root,
			Size = UDim2.fromOffset(760, 150),
			Position = UDim2.fromScale(0.5, 0.3),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = C.Mustard,
			Tilt = -2,
			Tape = true,
		})
		UIKit.Label({ Text = `YOU'VE GOT {string.upper(name)}!`, Font = Theme.Font.Title, TextSize = 50, Color = C.Ink, Stroke = false, Size = UDim2.new(1, 0, 0, 60), Position = UDim2.fromOffset(0, 8), Parent = body })
		UIKit.Label({ Text = "It's heavy. It's loud. Get it to Mom's trunk.", Font = Theme.Font.Body, TextSize = Theme.Text.Body, Color = C.Ink, Stroke = false, Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 70), Parent = body })
		UIKit.Pop(holder :: any, 0.5, 0.35)
		task.delay(0.35, UIKit.Twitch, holder, 3)
		task.delay(3, function()
			UIKit.PopOut(holder :: any, 0.2).Completed:Once(function()
				holder:Destroy()
			end)
		end)
	end

	local function bankPop(candy: number, count: number, reason: string?)
		local card = UIKit.Box({ Name = "Banked", Size = UDim2.fromOffset(900, 220), Position = UDim2.fromScale(0.5, 0.4), AnchorPoint = Vector2.new(0.5, 0.5), Parent = root })
		local row = UIKit.Box({ Size = UDim2.new(1, 0, 0, 120), Parent = card })
		UIKit.List(row, { Dir = Enum.FillDirection.Horizontal, Gap = 14, V = Enum.VerticalAlignment.Center })
		local amount = UIWidgets.CandyAmount({ Parent = row, Amount = 0, Prefix = "+", TextSize = 96, Color = C.Mustard, LayoutOrder = 1 })
		UIKit.Title({ Text = "STASHED", TextSize = 72, Color = C.Mint, Auto = "X", Size = UDim2.fromOffset(0, 100), LayoutOrder = 2, Parent = row })
		local sub = UIKit.Label({
			Text = if reason == "Dawn" then `{count} things made it to morning` else `{count} thing{if count == 1 then "" else "s"} safe in Mom's trunk`,
			Font = Theme.Font.Body,
			TextSize = Theme.Text.Body + 2,
			Color = C.Paper,
			Size = UDim2.new(1, 0, 0, 40),
			Position = UDim2.fromOffset(0, 120),
			Parent = card,
		})
		local total = UIKit.Label({ Text = "", Font = Theme.Font.Button, TextSize = Theme.Text.Small, Color = C.Mustard, Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 164), Rich = true, Parent = card })
		UIKit.Pop(card :: any, 0.5, 0.35)
		UIState.Play("Bank")
		amount:Set(candy, true)
		task.delay(0.9, function()
			local ok, have = pcall(function()
				return UIState.Data():GetCandy()
			end)
			if ok and card.Parent then
				total.Text = `You have {UIWidgets.Number(have)} Candy`
				UIKit.Pop(total :: any, 0.6)
			end
		end)
		task.delay(0.3, UIKit.Twitch, sub, 2)
		task.delay(2.8, function()
			UIKit.PopOut(card :: any, 0.2).Completed:Once(function()
				card:Destroy()
			end)
		end)
	end

	local function nothingHere()
		local l = UIKit.Label({
			Text = "Nothing here…",
			Font = Theme.Font.Body,
			TextSize = Theme.Text.Header,
			Color = C.PaperDim,
			Size = UDim2.fromOffset(500, 60),
			Position = UDim2.new(0.5, 0, 0.62, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = -3,
			Parent = root,
		})
		UIKit.Pop(l :: any, 0.8)
		UIKit.Tween(l, 1.4, { Position = UDim2.new(0.5, 0, 0.58, 0), TextTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0.6).Completed:Once(function()
			l:Destroy()
		end)
		local stroke = l:FindFirstChildOfClass("UIStroke")
		if stroke then
			UIKit.Tween(stroke, 1.4, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0.6)
		end
	end

	Net.Event("LootPicked").OnClientEvent:Connect(function(name, value, isPrize)
		if typeof(name) ~= "string" then
			return
		end
		if isPrize then
			prizePop(name)
		else
			pickupPop(name, if typeof(value) == "number" then value else 0)
		end
	end)
	Net.Event("Banked").OnClientEvent:Connect(function(candy, count, reason)
		if typeof(candy) == "number" and candy > 0 then
			-- Dawn banking is shown on the morning summary; keep it quiet here.
			if reason == "Dawn" then
				return
			end
			bankPop(candy, if typeof(count) == "number" then count else 0, reason)
		end
	end)
	Net.Event("SearchResult").OnClientEvent:Connect(function(found)
		if found == nil then
			nothingHere()
		end
	end)
end

return LootFeedback
