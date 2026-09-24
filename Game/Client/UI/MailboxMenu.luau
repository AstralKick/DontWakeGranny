--!strict
-- MailboxMenu (Lobby) — menu "Mailbox"
-- 7-day streak calendar from EconomyConfig.DailyRewards; ClaimDaily() -> (ok, streak).
-- Days already collected get a stamp; today's envelope wiggles until you open it.
-- (Missing a day resets the streak — the copy says so, gently.)

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))
local UIWidgets = require(script.Parent:WaitForChild("UIWidgets"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local MenuHost = require(script.Parent:WaitForChild("MenuHost"))
local ShopMenu = require(script.Parent:WaitForChild("ShopMenu"))
local NotifyScreen = require(script.Parent:WaitForChild("NotifyScreen"))

local C = Theme.Color
local MailboxMenu = {}

local function today(): number
	return math.floor(os.time() / 86400)
end

local function build(): any
	local Data = UIState.Data()
	local EconomyConfig = UIState.Config("EconomyConfig")
	local days = EconomyConfig.DailyRewards

	local shell = MenuHost.Shell({ Name = "Mailbox", Title = "Mailbox", Color = C.Night, Accent = C.Mint, Size = UDim2.fromScale(0.9, 0.74), Max = Vector2.new(1500, 700), Tilt = -1 })
	local body = shell.Body
	local subtitle = UIKit.Label({ Text = "", Font = Theme.Font.Body, TextSize = Theme.Text.Body, Color = C.PaperDim, Stroke = false, XAlign = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(10, 6), Parent = body })
	local row = UIKit.Box({ Size = UDim2.new(1, 0, 0, 300), Position = UDim2.fromOffset(0, 54), Parent = body })
	UIKit.List(row, { Dir = Enum.FillDirection.Horizontal, Gap = 16, V = Enum.VerticalAlignment.Center })
	local claimHolder = UIKit.Box({ Size = UDim2.new(1, 0, 0, 110), Position = UDim2.new(0, 0, 1, -10), AnchorPoint = Vector2.new(0, 1), Parent = body })
	local claimBtn: any = nil
	local busy = false
	local isOpen = false

	local function render()
		for _, c in row:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		if claimBtn then
			claimBtn:Destroy()
			claimBtn = nil
		end
		local d = Data:Get("Daily") or { LastClaimDay = 0, Streak = 0 }
		local t = today()
		local canClaim = (d.LastClaimDay or 0) < t
		local streak = d.Streak or 0
		local nextDay = if (d.LastClaimDay or 0) == t - 1 then streak + 1 else 1
		if nextDay > #days then
			nextDay = 1
		end
		local doneUpTo = if canClaim then nextDay - 1 else streak

		subtitle.Text = if canClaim
			then (if nextDay == 1 and streak > 0 then "You missed a day — the streak starts over. Grandma noticed." else `Day {nextDay} of {#days}. Come back every day for bigger treats.`)
			else "Nothing else today. The mailbox rattles anyway."

		for i, r in days do
			local isToday = canClaim and i == nextDay
			local done = i <= doneUpTo
			local card = UIKit.new("Frame", {
				BackgroundColor3 = if isToday then C.Mustard elseif done then C.PaperDim else C.Paper,
				Size = UDim2.fromOffset(if i == #days then 220 else 170, if isToday then 282 else 256),
				Rotation = ((i * 29) % 7) - 3,
				LayoutOrder = i,
				Parent = row,
			})
			UIKit.Corner(card, UDim.new(0, 22))
			UIKit.Stroke(card, Theme.Stroke.Panel, C.Ink)
			UIKit.Label({ Text = `DAY {i}`, Font = Theme.Font.Title, TextSize = 34, Color = C.Ink, Stroke = false, Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 12), Parent = card })
			local ic = UIKit.Box({ Size = UDim2.fromOffset(92, 70), Position = UDim2.new(0.5, 0, 0, 66), AnchorPoint = Vector2.new(0.5, 0), Parent = card })
			if r.Item and (UIIcons :: any)[r.Item] then
				(UIIcons :: any)[r.Item](ic)
			else
				UIIcons.Candy(ic)
			end
			UIWidgets.CandyAmount({ Parent = card, Amount = r.Candy, TextSize = 30, Color = if isToday then C.Paper else C.Mustard, Position = UDim2.new(0.5, 0, 0, 150), AnchorPoint = Vector2.new(0.5, 0), H = Enum.HorizontalAlignment.Center })
			if r.Item then
				local def = EconomyConfig.Items[r.Item]
				UIKit.Label({ Text = `+ {r.ItemCount or 1} {def and def.Name or r.Item}`, Font = Theme.Font.Body, TextSize = 22, Color = C.Bruise, Stroke = false, Wrap = true, Size = UDim2.new(1, -16, 0, 50), Position = UDim2.fromOffset(8, 192), Parent = card })
			end
			if done then
				local st = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(120, 54), Position = UDim2.fromScale(0.5, 0.52), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = -14, ZIndex = 6, Parent = card })
				UIKit.Corner(st, UDim.new(0, 10))
				UIKit.Stroke(st, 5, C.Blood)
				UIKit.Label({ Text = "GOT IT", Font = Theme.Font.Title, TextSize = 30, Color = C.Blood, Stroke = false, ZIndex = 7, Parent = st })
			end
			if isToday then
				UIKit.Twitcher(card, 2, 4, 3)
			end
		end

		if canClaim then
			claimBtn = UIKit.Button({
				Parent = claimHolder,
				Text = "OPEN TODAY'S MAIL",
				Color = C.Mint,
				Size = UDim2.fromOffset(460, 100),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				TextSize = 36,
				OnClick = function()
					if busy then
						return
					end
					busy = true
					local ok, streak2 = ShopMenu.Call("ClaimDaily")
					busy = false
					if ok then
						local r = days[if typeof(streak2) == "number" then streak2 else nextDay]
						UIState.Play("Purchase")
						if r then
							NotifyScreen.Toast(`Mail! +{r.Candy} Candy` .. (if r.Item then " and a treat" else ""), "Candy")
						end
					end
				end,
			})
			UIKit.Bob(claimBtn.Instance, 3, 3)
		end
		MenuHost.Refocus(if claimBtn then claimBtn.Button else nil)
	end

	Data.Changed:Connect(function(key)
		if isOpen and key == "Daily" then
			render()
		end
	end)

	return {
		Root = shell.Root,
		Panel = shell.Panel,
		Backdrop = shell.Backdrop,
		GetFirst = function()
			return if claimBtn then claimBtn.Button else shell.Close.Button
		end,
		OnOpen = function()
			isOpen = true
			render()
		end,
		OnClose = function()
			isOpen = false
		end,
	}
end

function MailboxMenu.Mount(_ctx: any)
	MenuHost.Register("Mailbox", build)
end

return MailboxMenu
