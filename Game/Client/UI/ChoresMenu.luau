--!strict
-- ChoresMenu (Lobby) — menu "Chores"
-- Today's quests (data Quests.List {Id, Target, Reward, Progress, Claimed}) with a
-- progress bar each; ClaimQuest(index) -> (ok, reward). New chores roll at midnight UTC.

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))
local UIWidgets = require(script.Parent:WaitForChild("UIWidgets"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local MenuHost = require(script.Parent:WaitForChild("MenuHost"))
local ShopMenu = require(script.Parent:WaitForChild("ShopMenu"))
local NotifyScreen = require(script.Parent:WaitForChild("NotifyScreen"))

local C = Theme.Color
local ChoresMenu = {}

local function build(): any
	local Data = UIState.Data()
	local EconomyConfig = UIState.Config("EconomyConfig")

	local shell = MenuHost.Shell({ Name = "Chores", Title = "Chores", Color = C.Paper, Accent = C.Mustard, Size = UDim2.fromScale(0.7, 0.78), Max = Vector2.new(1150, 780), Tilt = -1.5, Stitch = true })
	local body = shell.Body
	UIKit.Label({ Text = "Grandma's list. Do these, get paid.", Font = Theme.Font.Body, TextSize = Theme.Text.Body, Color = C.Bruise, Stroke = false, XAlign = Enum.TextXAlignment.Left, Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 6), Parent = body })
	local reset = UIKit.Label({ Text = "", Font = Theme.Font.Body, TextSize = Theme.Text.Small, Color = C.Bruise, Stroke = false, XAlign = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(400, 40), Position = UDim2.new(1, -10, 0, 6), AnchorPoint = Vector2.new(1, 0), Parent = body })
	local listHost = UIKit.Box({ Size = UDim2.new(1, 0, 1, -60), Position = UDim2.fromOffset(0, 60), Parent = body })
	local list: ScrollingFrame? = nil
	local first: GuiObject? = nil
	local isOpen = false

	local function render()
		local focus = ShopMenu.FocusKey()
		if list then
			list:Destroy()
		end
		local l = UIKit.Scroll({ Parent = listHost, Gap = 16 })
		list = l
		first = nil
		local q = Data:Get("Quests") or {}
		local quests = q.List or {}
		if #quests == 0 then
			UIKit.Label({ Text = "No chores yet. Check back in a moment.", Font = Theme.Font.Body, TextSize = Theme.Text.Body, Color = C.Bruise, Stroke = false, Size = UDim2.new(1, 0, 0, 60), Parent = l })
		end
		for i, quest in quests do
			local def = EconomyConfig.Quests[quest.Id]
			local text = if def then string.format(def.Text, quest.Target) else quest.Id
			local done = (quest.Progress or 0) >= (quest.Target or 1)
			local row, right = ShopMenu.Row(l, i, UIIcons.Clipboard, text, "", if quest.Claimed then C.PaperDim else C.Paper)
			local blurb = row:FindFirstChild("Blurb") :: TextLabel
			blurb.Visible = false
			local bar = UIKit.Bar({ Parent = row, Size = UDim2.new(1, -600, 0, 24), Position = UDim2.fromOffset(120, 66), Color = if done then C.Mint else C.Rose })
			bar:Set((quest.Progress or 0) / math.max(1, quest.Target or 1))
			UIKit.Label({ Text = `{math.min(quest.Progress or 0, quest.Target or 1)}/{quest.Target}`, Font = Theme.Font.Button, TextSize = 22, Color = C.Ink, Stroke = false, XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(120, 30), Position = UDim2.new(1, -470, 0, 63), Parent = row })
			if quest.Claimed then
				ShopMenu.Stamp(right, "DONE", C.Mint:Lerp(C.Ink, 0.3))
			else
				local b = UIKit.Button({
					Parent = right,
					Text = "",
					Color = if done then C.Mint else C.PaperDim,
					Size = UDim2.fromOffset(250, 84),
					Position = UDim2.new(1, 0, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					OnClick = function()
						if not done then
							NotifyScreen.Toast("Not finished yet!", "Info")
							return
						end
						local ok, reward = ShopMenu.Call("ClaimQuest", i)
						if ok then
							UIState.Play("Purchase")
							NotifyScreen.Toast(`Chore done! +{reward or quest.Reward} Candy`, "Candy")
						end
					end,
				})
				b.Button:SetAttribute("Key", "Quest_" .. i)
				local amt = UIWidgets.CandyAmount({ Parent = b.Button, Amount = quest.Reward or 0, Prefix = if done then "Claim " else "", TextSize = 30, Color = C.Ink, Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), H = Enum.HorizontalAlignment.Center })
				amt.Instance.ZIndex = 4
				for _, d in amt.Instance:GetDescendants() do
					if d:IsA("GuiObject") then
						d.ZIndex += 3
					end
				end
				local st = amt.Label:FindFirstChildOfClass("UIStroke")
				if st then
					st.Enabled = false
				end
				if not first then
					first = b.Button
				end
			end
		end
		ShopMenu.RestoreFocus(l, focus)
	end

	-- "new chores in 5h"
	task.spawn(function()
		while true do
			local secs = 86400 - (os.time() % 86400)
			reset.Text = `New chores in {math.floor(secs / 3600)}h {math.floor(secs % 3600 / 60)}m`
			task.wait(30)
		end
	end)

	Data.Changed:Connect(function(key)
		if isOpen and key == "Quests" then
			render()
		end
	end)

	return {
		Root = shell.Root,
		Panel = shell.Panel,
		Backdrop = shell.Backdrop,
		GetFirst = function()
			return first or shell.Close.Button
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

function ChoresMenu.Mount(_ctx: any)
	MenuHost.Register("Chores", build)
end

return ChoresMenu
