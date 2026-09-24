--!strict
-- DressUpMenu (Lobby) — menu "DressUp"
-- CosmeticsConfig Flashlight beams and Sack (pillowcase) patterns.
--   owned     -> Wear (ShopEquip(slot, id)) / WEARING
--   Shop      -> Candy price (ShopBuy("Cosmetic", slot, id))
--   Pass      -> locked, "Comes with <pass>" (+ Get it via RequestPurchase if the pass has an Id)
--   Reward    -> locked, "Survive all 31 nights"

local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local MenuHost = require(script.Parent:WaitForChild("MenuHost"))
local ShopMenu = require(script.Parent:WaitForChild("ShopMenu"))
local NotifyScreen = require(script.Parent:WaitForChild("NotifyScreen"))

local C = Theme.Color
local DressUpMenu = {}

local function beamSwatch(host: Instance, color: Color3)
	local glow = UIIcons.Blob(host, color, 0.5, 0.42, 0.9, 0.7, 0.5, 0, 0)
	glow.BackgroundTransparency = 0.45
	UIIcons.Blob(host, color, 0.5, 0.42, 0.5, 0.4, 0.5, 0, 3, 1)
	UIIcons.Blob(host, C.Bruise, 0.5, 0.86, 0.26, 0.24, 0.3, 0, 3, 1)
end

local function build(): any
	local player = Players.LocalPlayer
	local Data = UIState.Data()
	local Cosmetics = UIState.Config("CosmeticsConfig")
	local Monetization = UIState.Config("MonetizationConfig")

	local shell = MenuHost.Shell({ Name = "DressUp", Title = "Dress Up", Color = C.Night, Accent = C.Mint, Tilt = 1.5 })
	local body = shell.Body
	local content = UIKit.Box({ Size = UDim2.new(1, 0, 1, -96), Position = UDim2.fromOffset(0, 96), Parent = body })
	local slot = "Flashlight"
	local tabs: any
	local grid: ScrollingFrame? = nil
	local isOpen = false

	local function render()
		local focus = ShopMenu.FocusKey()
		if grid then
			grid:Destroy()
		end
		local g = UIKit.new("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 10,
			ScrollBarImageColor3 = C.Rose,
			Selectable = false,
			Parent = content,
		})
		grid = g
		UIKit.new("UIGridLayout", { CellSize = UDim2.fromOffset(270, 330), CellPadding = UDim2.fromOffset(24, 24), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = g })
		UIKit.new("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), Parent = g })

		local c = Data:Get("Cosmetics") or { Owned = {}, Equipped = {} }
		local owned = (c.Owned and c.Owned[slot]) or {}
		local equipped = c.Equipped and c.Equipped[slot]
		local balance = Data:GetCandy()
		local ids = {}
		for id in Cosmetics[slot] do
			table.insert(ids, id)
		end
		table.sort(ids, function(a, b)
			return Cosmetics[slot][a].Order < Cosmetics[slot][b].Order
		end)

		for i, id in ids do
			local def = Cosmetics[slot][id]
			local have = owned[id] == true or def.Source == "Default"
			local wearing = equipped == id
			local cell = UIKit.Box({ LayoutOrder = i, Parent = g })
			local card = UIKit.new("Frame", { BackgroundColor3 = if wearing then C.Paper else (if have then C.PaperDim else C.NightDeep), Size = UDim2.fromScale(1, 1), Rotation = ((i * 41) % 5) - 2, Parent = cell })
			UIKit.Corner(card, UDim.new(0, 24))
			UIKit.Stroke(card, Theme.Stroke.Panel, if wearing then C.Mint else C.Ink)
			local sw = UIKit.Box({ Size = UDim2.fromOffset(150, 130), Position = UDim2.new(0.5, 0, 0, 20), AnchorPoint = Vector2.new(0.5, 0), Parent = card })
			if slot == "Flashlight" then
				beamSwatch(sw, def.Color)
			else
				UIIcons.Sack(sw, def.Color)
			end
			local dark = not have and not wearing
			UIKit.Label({ Text = def.Name, Font = Theme.Font.Button, TextSize = 28, Color = if dark then C.Paper else C.Ink, Stroke = if dark then 2 else false, Size = UDim2.new(1, -20, 0, 36), Position = UDim2.fromOffset(10, 158), TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
			local action = UIKit.Box({ Size = UDim2.new(1, -30, 0, 96), Position = UDim2.new(0.5, 0, 1, -12), AnchorPoint = Vector2.new(0.5, 1), Parent = card })
			local key = `{slot}_{id}`
			if wearing then
				local st = ShopMenu.Stamp(action, "WEARING", C.Mint:Lerp(C.Ink, 0.3))
				st.Position = UDim2.fromScale(0.5, 0.5)
				st.AnchorPoint = Vector2.new(0.5, 0.5)
			elseif have then
				local b = UIKit.Button({ Parent = action, Text = "Wear", Color = C.Mint, Size = UDim2.fromOffset(200, 80), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), OnClick = function()
					local ok = ShopMenu.Call("ShopEquip", slot, id)
					if ok then
						UIState.Play("Purchase")
					end
				end })
				b.Button:SetAttribute("Key", key)
			elseif def.Source == "Shop" then
				local b = ShopMenu.PriceButton(action, def.Cost or 0, function()
					local ok = ShopMenu.Call("ShopBuy", "Cosmetic", slot, id)
					if ok then
						UIState.Play("Purchase")
						NotifyScreen.Toast(`{def.Name} is yours. Wear it?`, "Good")
					end
				end, key)
				b.Instance.Position = UDim2.fromScale(0.5, 0.5)
				b.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
				b.Instance.Size = UDim2.fromOffset(220, 84)
				if balance < (def.Cost or 0) then
					b:SetColor(C.PaperDim)
				end
			else
				-- locked: tell them exactly how to get it
				local lock = UIKit.Box({ Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0, 16, 0, 16), Parent = card })
				UIIcons.Lock(lock)
				local how = if def.Source == "Pass"
					then `Comes with {(Monetization.Passes[def.Pass] and Monetization.Passes[def.Pass].Name) or def.Pass}`
					else "Survive all 31 nights"
				local pass = def.Source == "Pass" and Monetization.Passes[def.Pass]
				if pass and pass.Id ~= 0 and player:GetAttribute("Pass_" .. def.Pass) ~= true then
					local b = UIKit.Button({ Parent = action, Text = how, TextSize = 20, Color = C.Mustard, Size = UDim2.fromOffset(232, 80), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), OnClick = function()
						ShopMenu.Call("RequestPurchase", "Pass", def.Pass)
					end })
					b.Button:SetAttribute("Key", key)
				else
					UIKit.Label({ Text = how, Font = Theme.Font.Body, TextSize = Theme.Text.Small, Color = C.Mustard, Stroke = false, Wrap = true, Size = UDim2.fromScale(1, 1), Parent = action })
				end
			end
		end
		ShopMenu.RestoreFocus(g, focus)
	end

	tabs = UIKit.Tabs({
		Parent = body,
		Tabs = { { Key = "Flashlight", Text = "Flashlight" }, { Key = "Sack", Text = "Pillowcase", Width = 240 } },
		OnSelect = function(key)
			slot = key
			render()
		end,
	})
	UIKit.Label({ Text = "Everyone in the house sees these.", Font = Theme.Font.Body, TextSize = Theme.Text.Small, Color = C.PaperDim, Stroke = false, XAlign = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(500, 40), Position = UDim2.new(1, -10, 0, 20), AnchorPoint = Vector2.new(1, 0), Parent = body })

	Data.Changed:Connect(function(key)
		if isOpen and (key == "Cosmetics" or key == "Candy") then
			render()
		end
	end)

	return {
		Root = shell.Root,
		Panel = shell.Panel,
		Backdrop = shell.Backdrop,
		GetFirst = function()
			return tabs.Order[1]
		end,
		OnOpen = function()
			isOpen = true
			tabs:Select(tabs.Current() or "Flashlight")
		end,
		OnClose = function()
			isOpen = false
		end,
	}
end

function DressUpMenu.Mount(_ctx: any)
	MenuHost.Register("DressUp", build)
end

return DressUpMenu
