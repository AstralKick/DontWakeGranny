--!strict
-- DiaryScreen (both places)
--   Menu "DiaryPage"(pageIndex, isNew): one torn diary page in SpecialElite, with a
--       "NEW PAGE" stamp. Opened by the DiaryFound remote (match) or the collection.
--   Menu "Diary": the collection (found pages / "???") + an Achievements tab.
-- Lobby prompts with Menu = "Diary" open the collection (see LobbyHud).

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))
local UIWidgets = require(script.Parent:WaitForChild("UIWidgets"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local MenuHost = require(script.Parent:WaitForChild("MenuHost"))

local C = Theme.Color
local DiaryScreen = {}

local function dataGet(key: string): any
	local ok, v = pcall(function()
		return UIState.Data():Get(key)
	end)
	return if ok then v else nil
end

-- ================================================================ single page

local function buildPage(): any
	local DiaryConfig = UIState.Config("DiaryConfig")
	local shell = MenuHost.Shell({ Name = "DiaryPage", Title = "Grandma's Diary", Color = C.Paper, Accent = C.Bruise, Size = UDim2.fromScale(0.62, 0.84), Max = Vector2.new(900, 860), Tilt = 2, Stitch = true })
	local body = shell.Body
	local date = UIKit.Label({ Text = "", Font = Theme.Font.Note, TextSize = 40, Color = C.Blood, Stroke = false, XAlign = Enum.TextXAlignment.Left, Size = UDim2.new(1, -40, 0, 50), Position = UDim2.fromOffset(20, 10), Parent = body })
	-- ruled lines behind the text
	local lines = UIKit.Box({ Size = UDim2.new(1, -40, 1, -170), Position = UDim2.fromOffset(20, 70), Parent = body })
	for i = 1, 14 do
		UIKit.new("Frame", { BackgroundColor3 = C.Bruise, BackgroundTransparency = 0.75, Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 0, i * 44), Parent = lines })
	end
	local text = UIKit.Label({
		Text = "",
		Font = Theme.Font.Note,
		TextSize = 32,
		Color = C.Ink,
		Stroke = false,
		Wrap = true,
		XAlign = Enum.TextXAlignment.Left,
		YAlign = Enum.TextYAlignment.Top,
		LineHeight = 1.25,
		Size = UDim2.new(1, -40, 1, -180),
		Position = UDim2.fromOffset(20, 80),
		ZIndex = 4,
		Parent = body,
	})
	UIKit.new("UITextSizeConstraint", { MinTextSize = 20, MaxTextSize = 34, Parent = text })
	text.TextScaled = true
	local pageNo = UIKit.Label({ Text = "", Font = Theme.Font.Body, TextSize = Theme.Text.Small, Color = C.Bruise, Stroke = false, XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(300, 40), Position = UDim2.new(0, 20, 1, -60), Parent = body })
	local closeBtn = UIKit.Button({ Parent = body, Text = "Close", Color = C.Bruise, Size = UDim2.fromOffset(220, 80), Position = UDim2.new(1, -10, 1, -10), AnchorPoint = Vector2.new(1, 1), OnClick = function()
		MenuHost.Close()
	end })
	-- a thumbprint smudge in the corner (the creepy detail)
	local smudge = UIKit.new("Frame", { BackgroundColor3 = C.Blood, BackgroundTransparency = 0.8, Size = UDim2.fromOffset(60, 72), Position = UDim2.new(1, -90, 0, 30), Rotation = 24, Parent = body })
	UIKit.Corner(smudge, UDim.new(0.5, 0))
	local stamp = UIKit.new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 70), Position = UDim2.new(1, -30, 0, 60), AnchorPoint = Vector2.new(1, 0), Rotation = 10, Visible = false, ZIndex = 8, Parent = body })
	UIKit.Corner(stamp, UDim.new(0, 12))
	UIKit.Stroke(stamp, 6, C.Blood)
	UIKit.Pad(stamp, 0, 18, 0)
	UIKit.Label({ Text = "NEW PAGE", Font = Theme.Font.Title, TextSize = 44, Color = C.Blood, Stroke = false, Auto = "X", Size = UDim2.fromOffset(0, 70), ZIndex = 9, Parent = stamp })

	local closeToken = 0
	return {
		Root = shell.Root,
		Panel = shell.Panel,
		Backdrop = shell.Backdrop,
		First = closeBtn.Button,
		OnOpen = function(arg: any)
			local index = if typeof(arg) == "table" then arg.Index else arg
			local isNew = typeof(arg) == "table" and arg.New == true
			local page = DiaryConfig[index]
			if not page then
				return
			end
			date.Text = page.Title
			text.Text = page.Text
			pageNo.Text = `Page {index} of {#DiaryConfig}`
			stamp.Visible = false
			if isNew then
				task.delay(0.45, function()
					stamp.Visible = true
					UIKit.Pop(stamp :: any, 1.8, 0.18)
					UIState.Play("NewArea")
				end)
			end
			UIState.Play("Whisper")
			-- in the house, the page doesn't stay open forever
			closeToken += 1
			local my = closeToken
			if typeof(arg) == "table" and arg.AutoClose then
				task.delay(arg.AutoClose, function()
					if closeToken == my and MenuHost.Current() == "DiaryPage" then
						MenuHost.Close()
					end
				end)
			end
		end,
		OnClose = function()
			closeToken += 1
		end,
	}
end

-- ================================================================ collection

local function buildCollection(): any
	local DiaryConfig = UIState.Config("DiaryConfig")
	local AchievementConfig = UIState.Config("AchievementConfig")
	local shell = MenuHost.Shell({ Name = "Diary", Title = "Diary", Color = C.Night, Accent = C.Bruise, Drip = true })
	local body = shell.Body
	local content = UIKit.Box({ Size = UDim2.new(1, 0, 1, -96), Position = UDim2.fromOffset(0, 96), Parent = body })
	local first: GuiObject? = nil
	local tabs: any

	local function clearContent()
		for _, c in content:GetChildren() do
			c:Destroy()
		end
	end

	local function showPages()
		clearContent()
		local found = dataGet("Diary") or {}
		local count = 0
		for i in DiaryConfig do
			if found[tostring(i)] then
				count += 1
			end
		end
		UIKit.Label({ Text = `{count} of {#DiaryConfig} pages found. Some rooms keep secrets.`, Font = Theme.Font.Body, TextSize = Theme.Text.Body, Color = C.PaperDim, Stroke = false, XAlign = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 40), Parent = content })
		local grid = UIKit.new("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, -50),
			Position = UDim2.fromOffset(0, 50),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 10,
			ScrollBarImageColor3 = C.Rose,
			Selectable = false,
			Parent = content,
		})
		UIKit.new("UIGridLayout", { CellSize = UDim2.fromOffset(250, 170), CellPadding = UDim2.fromOffset(22, 22), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = grid })
		UIKit.new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = grid })
		first = nil
		for i, page in DiaryConfig do
			local have = found[tostring(i)] == true
			local cell = UIKit.Box({ LayoutOrder = i, Parent = grid })
			local b = UIKit.Button({
				Parent = cell,
				Size = UDim2.fromScale(1, 1),
				Corner = UDim.new(0, 18),
				Color = if have then C.Paper else C.NightDeep,
				Text = "",
				OnClick = function()
					if have then
						MenuHost.Open("DiaryPage", { Index = i })
					else
						UIKit.Shake(cell, 5, 0.2)
					end
				end,
			})
			b.Instance.Rotation = ((i * 37) % 7) - 3
			UIKit.Label({ Text = if have then page.Title else "???", Font = if have then Theme.Font.Note else Theme.Font.Title, TextSize = if have then 30 else 50, Color = if have then C.Ink else C.Bruise, Stroke = false, Size = UDim2.new(1, -20, 0, 60), Position = UDim2.fromOffset(10, 30), ZIndex = 4, Parent = b.Button })
			UIKit.Label({ Text = if have then `page {i}` else `from night {page.MinNight}`, Font = Theme.Font.Body, TextSize = Theme.Text.Small, Color = if have then C.Bruise else C.PaperDim, Stroke = false, Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromOffset(10, 96), ZIndex = 4, Parent = b.Button })
			if i == 1 then
				first = b.Button
			end
		end
	end

	local function showAchievements()
		clearContent()
		local have = dataGet("Achievements") or {}
		local keys = {}
		for k in AchievementConfig do
			table.insert(keys, k)
		end
		table.sort(keys, function(a, b)
			local ha, hb = have[a] == true, have[b] == true
			if ha ~= hb then
				return ha
			end
			return AchievementConfig[a].Target < AchievementConfig[b].Target or (AchievementConfig[a].Target == AchievementConfig[b].Target and a < b)
		end)
		local list = UIKit.Scroll({ Parent = content, Gap = 12 })
		first = nil
		for i, k in keys do
			local a = AchievementConfig[k]
			local done = have[k] == true
			local row = UIKit.new("Frame", { BackgroundColor3 = if done then C.Paper else C.NightDeep, Size = UDim2.new(1, -20, 0, 92), LayoutOrder = i, Parent = list })
			UIKit.Corner(row, Theme.Corner.Chip)
			UIKit.Stroke(row, 3, C.Ink)
			local ic = UIKit.Box({ Size = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(16, 14), Parent = row })
			if done then
				UIIcons.Trophy(ic)
			else
				UIIcons.Lock(ic)
			end
			UIKit.Label({ Text = a.Name, Font = Theme.Font.Button, TextSize = Theme.Text.Body, Color = if done then C.Ink else C.Paper, Stroke = if done then false else 2, XAlign = Enum.TextXAlignment.Left, Size = UDim2.new(1, -330, 0, 40), Position = UDim2.fromOffset(96, 8), Parent = row })
			UIKit.Label({ Text = a.Text, Font = Theme.Font.Body, TextSize = Theme.Text.Small, Color = if done then C.Bruise else C.PaperDim, Stroke = false, XAlign = Enum.TextXAlignment.Left, Size = UDim2.new(1, -330, 0, 34), Position = UDim2.fromOffset(96, 48), Parent = row })
			if (a.Candy or 0) > 0 then
				UIWidgets.CandyAmount({ Parent = row, Amount = a.Candy, TextSize = 28, Position = UDim2.new(1, -24, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), H = Enum.HorizontalAlignment.Right })
			end
		end
	end

	tabs = UIKit.Tabs({
		Parent = body,
		Tabs = { { Key = "Pages", Text = "Pages" }, { Key = "Achievements", Text = "Achievements", Width = 280 } },
		OnSelect = function(key)
			if key == "Pages" then
				showPages()
			else
				showAchievements()
			end
		end,
	})

	return {
		Root = shell.Root,
		Panel = shell.Panel,
		Backdrop = shell.Backdrop,
		GetFirst = function()
			return tabs.Order[1]
		end,
		OnOpen = function()
			tabs:Select(tabs.Current() or "Pages")
		end,
	}
end

function DiaryScreen.Mount(ctx: any)
	MenuHost.Register("DiaryPage", buildPage)
	MenuHost.Register("Diary", buildCollection)
	local Net = UIState.Net()
	Net.Event("DiaryFound").OnClientEvent:Connect(function(index, isNew)
		if typeof(index) == "number" then
			MenuHost.Open("DiaryPage", { Index = index, New = isNew == true, AutoClose = if ctx.IsMatch then 14 else nil })
		end
	end)
end

return DiaryScreen
