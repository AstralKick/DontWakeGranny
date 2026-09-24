--!strict
-- NotifyScreen (both places)
-- Toasts (remote "Toast"), Banners (remote "Banner") and purchase feedback
-- ("PurchaseResult"). Other screens call NotifyScreen.Toast / .Banner directly.
--
-- Toasts: small tilted paper slips that drop in under the top bar and stack (max 4).
-- Banners: one big title at a time, queued, with a subtitle ribbon underneath.

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))
local UIState = require(script.Parent:WaitForChild("UIState"))

local C = Theme.Color
local NotifyScreen = {}

local toastHost: Frame? = nil
local bannerHost: Frame? = nil
local bannerQueue: { { any } } = {}
local bannerBusy = false
local toastCount = 0

-- Server copy uses a few emoji; our style draws icons instead (UI_STYLE: no emoji icons).
local function clean(text: string): (string, boolean)
	local hadCandy = text:find("🍬", 1, true) ~= nil
	text = text:gsub(" ?🍬", " Candy"):gsub("💖", ""):gsub("🏆 ?", ""):gsub("🔒 ?", ""):gsub("  +", " ")
	return (text:gsub("^%s+", ""):gsub("%s+$", "")), hadCandy
end
NotifyScreen.Clean = clean

function NotifyScreen.Toast(text: string, style: string?)
	local host = toastHost
	if not host then
		return
	end
	local s = style or "Info"
	local body, hadCandy = clean(text)
	toastCount += 1
	local children = {}
	for _, c in host:GetChildren() do
		if c:IsA("Frame") then
			table.insert(children, c)
		end
	end
	if #children >= 4 then
		table.sort(children, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		children[1]:Destroy()
	end

	local accent = Theme.ToastColor[s] or C.Paper
	local slot = UIKit.Box({ Name = "Toast", Size = UDim2.fromOffset(0, 64), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = toastCount, Parent = host })
	local slip = UIKit.new("Frame", {
		Name = "Slip",
		BackgroundColor3 = if s == "Bad" then C.Night else C.Paper,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 58),
		Rotation = (math.random() - 0.5) * 3,
		Parent = slot,
	})
	UIKit.Corner(slip, Theme.Corner.Chip)
	UIKit.Stroke(slip, 3, C.Ink)
	UIKit.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 22), Parent = slip })
	UIKit.List(slip, { Dir = Enum.FillDirection.Horizontal, Gap = 12, V = Enum.VerticalAlignment.Center, H = Enum.HorizontalAlignment.Left })
	-- colored thumb-tab on the left
	local chip = UIKit.new("Frame", { BackgroundColor3 = accent, Size = UDim2.fromOffset(if s == "Candy" or hadCandy then 50 else 16, 38), LayoutOrder = 1, Parent = slip })
	UIKit.Corner(chip, UDim.new(0.5, 0))
	UIKit.Stroke(chip, 3, C.Ink)
	if s == "Candy" or hadCandy then
		chip.BackgroundTransparency = 1
		chip:FindFirstChildOfClass("UIStroke"):Destroy()
		UIIcons.Candy(chip)
	end
	UIKit.Label({
		Text = body,
		Font = Theme.Font.Button,
		TextSize = Theme.Text.Small,
		Color = if s == "Bad" then C.Paper else C.Ink,
		Stroke = if s == "Bad" then 2 else false,
		Auto = "X",
		Size = UDim2.fromOffset(0, 50),
		LayoutOrder = 2,
		Parent = slip,
	})
	slip.Position = UDim2.fromOffset(0, -30)
	UIKit.Pop(slip, 0.6)
	UIKit.Tween(slip, 0.3, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
	if s == "Bad" then
		task.delay(0.1, UIKit.Twitch, slip, 4)
	end
	task.delay(if #body > 40 then 4.5 else 3.2, function()
		if slot.Parent then
			UIKit.Tween(slip, 0.25, { Position = UDim2.fromOffset(0, -20), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			UIKit.PopOut(slip, 0.25).Completed:Once(function()
				slot:Destroy()
			end)
		end
	end)
end

local function showBanner(title: string, subtitle: string?, color: Color3?)
	local host = bannerHost
	if not host then
		return
	end
	bannerBusy = true
	local col = color or C.Rose
	local card = UIKit.Box({ Name = "Banner", Size = UDim2.fromOffset(1100, 220), Position = UDim2.fromScale(0.5, 0.26), AnchorPoint = Vector2.new(0.5, 0.5), Parent = host })
	local ribbon: Frame? = nil
	if subtitle and subtitle ~= "" then
		local r = UIKit.new("Frame", {
			Name = "Ribbon",
			BackgroundColor3 = C.Night,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 56),
			Position = UDim2.new(0.5, 0, 0, 150),
			AnchorPoint = Vector2.new(0.5, 0),
			Rotation = -1.5,
			Parent = card,
		})
		UIKit.Corner(r, Theme.Corner.Chip)
		UIKit.Stroke(r, 3, C.Ink)
		UIKit.Pad(r, 0, 26, 0)
		UIKit.Label({ Text = (clean(subtitle)), Font = Theme.Font.Body, TextSize = Theme.Text.Body + 2, Auto = "X", Size = UDim2.fromOffset(0, 56), Stroke = false, Parent = r })
		ribbon = r
	end
	local t = UIKit.Title({
		Text = (clean(title)),
		TextSize = 96,
		Color = col,
		Stroke = 6,
		Size = UDim2.new(1, 0, 0, 140),
		Crooked = math.random(2, math.max(2, #title - 1)),
		Parent = card,
	})
	-- second, offset ink copy = hard shadow on the title
	local shadow = t:Clone()
	shadow.Name = "Shadow"
	shadow.TextColor3 = C.Ink
	shadow.TextTransparency = 0.35
	shadow.Position = UDim2.fromOffset(0, 8)
	shadow.ZIndex = t.ZIndex - 1
	shadow.Parent = card
	t.ZIndex += 1

	UIKit.Pop(card, 0.5, 0.4)
	UIState.Play("NewArea")
	if ribbon then
		ribbon.Position = UDim2.new(0.5, 0, 0, 190)
		UIKit.Tween(ribbon, 0.35, { Position = UDim2.new(0.5, 0, 0, 150) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0.15)
	end
	task.delay(0.5, UIKit.Twitch, t, 3)
	task.delay(2.9, function()
		UIKit.PopOut(card, 0.2).Completed:Once(function()
			card:Destroy()
			bannerBusy = false
			local nextOne = table.remove(bannerQueue, 1)
			if nextOne then
				showBanner(nextOne[1], nextOne[2], nextOne[3])
			end
		end)
	end)
end

local suppressed: { [string]: boolean } = {}

-- Screens that draw their own big moment (e.g. Victory) can swallow the matching
-- server banner so the same title isn't shown twice.
function NotifyScreen.Suppress(title: string, on: boolean?)
	suppressed[string.upper(title)] = if on == false then nil else true
end

function NotifyScreen.Banner(title: string, subtitle: string?, color: Color3?)
	if suppressed[string.upper(title)] then
		return
	end
	if bannerBusy then
		if #bannerQueue < 3 then
			table.insert(bannerQueue, { title, subtitle, color })
		end
		return
	end
	showBanner(title, subtitle, color)
end

function NotifyScreen.Mount(ctx: any)
	local root: Frame = ctx.Notify
	-- Match: pinned top-right under the teammates strip (the top-left is the HUD).
	-- Lobby: top-centre.
	local th = UIKit.Box({
		Name = "Toasts",
		Size = UDim2.fromOffset(900, 320),
		Position = if ctx.IsMatch then UDim2.new(1, -24, 0, 140) else UDim2.new(0.5, 0, 0, 18),
		AnchorPoint = if ctx.IsMatch then Vector2.new(1, 0) else Vector2.new(0.5, 0),
		Parent = root,
	})
	UIKit.List(th, { Gap = 8, H = if ctx.IsMatch then Enum.HorizontalAlignment.Right else Enum.HorizontalAlignment.Center })
	toastHost = th
	bannerHost = UIKit.Box({ Name = "Banners", Size = UDim2.fromScale(1, 1), Parent = root })

	local Net = UIState.Net()
	Net.Event("Toast").OnClientEvent:Connect(function(text, style)
		if typeof(text) == "string" then
			NotifyScreen.Toast(text, style)
		end
	end)
	Net.Event("Banner").OnClientEvent:Connect(function(title, subtitle, color)
		if typeof(title) == "string" then
			NotifyScreen.Banner(title, subtitle, if typeof(color) == "Color3" then color else nil)
		end
	end)
	local Monetization = UIState.Config("MonetizationConfig")
	Net.Event("PurchaseResult").OnClientEvent:Connect(function(key, success)
		if not success then
			return
		end
		UIState.Play("Purchase")
		local def = Monetization.Products[key] or Monetization.Passes[key]
		local name = if def then def.Name else "your treat"
		NotifyScreen.Toast(`Thank you! {name} is yours.`, "Candy")
	end)
end

return NotifyScreen
