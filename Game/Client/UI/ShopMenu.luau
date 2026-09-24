--!strict
-- ShopMenu (Lobby) — menu "Shop"
-- Tabs:
--   Upgrades  EconomyConfig.Upgrades: level pips + next cost -> ShopBuy("Upgrade", key)
--   Pockets   EconomyConfig.Items: owned / max + cost      -> ShopBuy("Item", key)
--   Treats    Robux: Candy packs + game passes with Id ~= 0 -> RequestPurchase(kind, key)
--             (the tab doesn't exist at all when nothing is configured)
-- Also exposes ShopMenu.Row / ShopMenu.PriceButton for the other lobby menus.

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))
local UIWidgets = require(script.Parent:WaitForChild("UIWidgets"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local MenuHost = require(script.Parent:WaitForChild("MenuHost"))
local NotifyScreen = require(script.Parent:WaitForChild("NotifyScreen"))

local C = Theme.Color
local ShopMenu = {}

-- ---------------------------------------------------------------- shared bits

-- A card row: icon well on the left, title + blurb, a right-side slot for actions.
-- Returns row, rightSlot.
function ShopMenu.Row(parent: Instance, order: number, iconFn: ((Instance) -> ())?, title: string, blurb: string, color: Color3?, reserve: number?): (Frame, Frame)
	local rw = reserve or 440 -- px kept free on the right for actions
	local row = UIKit.new("Frame", { Name = "Row", BackgroundColor3 = color or C.Paper, Size = UDim2.new(1, -24, 0, 116), LayoutOrder = order })
	UIKit.Corner(row, UDim.new(0, 22))
	UIKit.Stroke(row, Theme.Stroke.Panel, C.Ink)
	local well = UIKit.new("Frame", { BackgroundColor3 = C.Night, Size = UDim2.fromOffset(88, 88), Position = UDim2.fromOffset(14, 14), Rotation = -3, Parent = row })
	UIKit.Corner(well, UDim.new(0, 18))
	UIKit.Stroke(well, 3, C.Ink)
	if iconFn then
		local host = UIKit.Box({ Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.15, 0.15), ZIndex = 2, Parent = well })
		iconFn(host)
	end
	local textColor = UIKit.ContrastText(color or C.Paper)
	UIKit.Label({ Name = "Title", Text = title, Font = Theme.Font.Button, TextSize = Theme.Text.Body + 2, Color = textColor, Stroke = if textColor == C.Paper then 2 else false, XAlign = Enum.TextXAlignment.Left, Rich = true, Size = UDim2.new(1, -rw, 0, 42), Position = UDim2.fromOffset(120, 14), TextTruncate = Enum.TextTruncate.AtEnd, Parent = row })
	UIKit.Label({ Name = "Blurb", Text = blurb, Font = Theme.Font.Body, TextSize = Theme.Text.Small, Color = if textColor == C.Paper then C.PaperDim else C.Bruise, Stroke = false, XAlign = Enum.TextXAlignment.Left, Rich = true, Size = UDim2.new(1, -rw, 0, 50), Position = UDim2.fromOffset(120, 56), Wrap = true, Parent = row })
	local right = UIKit.Box({ Name = "Right", Size = UDim2.fromOffset(300, 92), Position = UDim2.new(1, -14, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Parent = row })
	row.Parent = parent
	return row, right
end

-- Pill button showing a Candy price with the candy icon.
function ShopMenu.PriceButton(parent: Instance, amount: number, onClick: () -> (), key: string?): any
	local b = UIKit.Button({ Parent = parent, Text = UIWidgets.Number(amount), Color = C.Mustard, Size = UDim2.fromOffset(250, 84), Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), TextSize = 34, OnClick = onClick, Sound = false })
	b.Label.Size = UDim2.new(1, -86, 1, 0)
	b.Label.Position = UDim2.fromOffset(24, -1)
	local ic = UIKit.Box({ Size = UDim2.fromOffset(62, 46), Position = UDim2.new(1, -20, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), ZIndex = 4, Parent = b.Button })
	UIIcons.Candy(ic)
	if key then
		b.Button:SetAttribute("Key", key)
	end
	return b
end

-- A flat status stamp for the right slot ("MAXED", "OWNED", "WEARING").
function ShopMenu.Stamp(parent: Instance, text: string, color: Color3): Frame
	local st = UIKit.new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 60), Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Rotation = -6, Parent = parent })
	UIKit.Corner(st, UDim.new(0, 10))
	UIKit.Stroke(st, 5, color)
	UIKit.Pad(st, 0, 16, 0)
	UIKit.Label({ Text = text, Font = Theme.Font.Title, TextSize = 34, Color = color, Stroke = false, Auto = "X", Size = UDim2.fromOffset(0, 60), Parent = st })
	return st
end

-- Run a server call; toast the reason on failure. Returns ok.
function ShopMenu.Call(fnName: string, ...: any): (boolean, any)
	local args = table.pack(...)
	local ok, res, reason = pcall(function()
		return UIState.Net().Function(fnName):InvokeServer(table.unpack(args, 1, args.n))
	end)
	if not ok then
		NotifyScreen.Toast("Something went wrong. Try again!", "Bad")
		return false, nil
	end
	if not res then
		NotifyScreen.Toast(if typeof(reason) == "string" then reason else "Can't do that right now.", "Bad")
		return false, reason
	end
	return true, reason
end

-- Remember which keyed button had gamepad focus so a rebuild can restore it.
function ShopMenu.FocusKey(): string?
	local sel = GuiService.SelectedObject
	local k = sel and sel:GetAttribute("Key")
	return if typeof(k) == "string" then k else nil
end

function ShopMenu.RestoreFocus(root: Instance, key: string?)
	if not key or UIState.Input ~= "Gamepad" then
		return
	end
	for _, d in root:GetDescendants() do
		if d:IsA("GuiButton") and d:GetAttribute("Key") == key then
			GuiService.SelectedObject = d
			return
		end
	end
end

-- ---------------------------------------------------------------- the shop

local function build(): any
	local player = Players.LocalPlayer
	local Data = UIState.Data()
	local EconomyConfig = UIState.Config("EconomyConfig")
	local Monetization = UIState.Config("MonetizationConfig")

	local shell = MenuHost.Shell({ Name = "Shop", Title = "The Corner Store", Color = C.Night, Accent = C.Rose, Drip = true })
	local body = shell.Body
	local candy = UIWidgets.CandyAmount({ Parent = body, Amount = Data:GetCandy(), TextSize = 44, Position = UDim2.new(1, -10, 0, 14), AnchorPoint = Vector2.new(1, 0), H = Enum.HorizontalAlignment.Right })
	local content = UIKit.Box({ Name = "Content", Size = UDim2.new(1, 0, 1, -96), Position = UDim2.fromOffset(0, 96), Parent = body })

	-- Which Robux things exist?
	local packs = {}
	for key, p in Monetization.Products do
		if p.Id ~= 0 and p.Candy then
			table.insert(packs, key)
		end
	end
	table.sort(packs, function(a, b)
		return Monetization.Products[a].Candy < Monetization.Products[b].Candy
	end)
	local passes = {}
	for key, p in Monetization.Passes do
		if p.Id ~= 0 then
			table.insert(passes, key)
		end
	end
	table.sort(passes)
	local hasTreats = #packs + #passes > 0

	local tabDefs = { { Key = "Upgrades", Text = "Upgrades" }, { Key = "Items", Text = "Pockets" } }
	if hasTreats then
		table.insert(tabDefs, { Key = "Treats", Text = "Treats" })
	end
	local tab = "Upgrades"
	local tabs: any
	local list: ScrollingFrame? = nil

	local lastTab = ""
	local function newList(): ScrollingFrame
		local keep = Vector2.zero
		if list then
			if lastTab == tab then
				keep = list.CanvasPosition -- a re-render after a purchase keeps your scroll
			end
			list:Destroy()
		end
		lastTab = tab
		local l = UIKit.Scroll({ Parent = content, Gap = 14 })
		list = l
		task.defer(function()
			l.CanvasPosition = keep
		end)
		return l
	end

	local function renderUpgrades()
		local l = newList()
		local have = Data:Get("Upgrades") or {}
		local keys = {}
		for k in EconomyConfig.Upgrades do
			table.insert(keys, k)
		end
		table.sort(keys, function(a, b)
			return EconomyConfig.Upgrades[a].Cost[1] < EconomyConfig.Upgrades[b].Cost[1]
		end)
		local icons = { Pillowcase = UIIcons.Sack, SoftSocks = UIIcons.Shoe, StrongLungs = UIIcons.Lungs, Batteries = UIIcons.Battery }
		local balance = Data:GetCandy()
		for i, k in keys do
			local def = EconomyConfig.Upgrades[k]
			local level = have[k] or 0
			local _row, right = ShopMenu.Row(l, i, icons[k], def.Name, def.Blurb, nil, 600)
			-- level pips under the title, like buttons sewn on
			local pips = UIKit.Box({ Size = UDim2.fromOffset(200, 22), Position = UDim2.new(1, -336, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Parent = _row })
			UIKit.List(pips, { Dir = Enum.FillDirection.Horizontal, Gap = 8, H = Enum.HorizontalAlignment.Right })
			for p = 1, #def.Cost do
				local pip = UIKit.new("Frame", { BackgroundColor3 = if p <= level then C.Rose else C.PaperDim, Size = UDim2.fromOffset(22, 22), LayoutOrder = p, Parent = pips })
				UIKit.Corner(pip, Theme.Corner.Round)
				UIKit.Stroke(pip, 3, C.Ink)
			end
			local cost = def.Cost[level + 1]
			if cost then
				local b = ShopMenu.PriceButton(right, cost, function()
					local ok = ShopMenu.Call("ShopBuy", "Upgrade", k)
					if ok then
						UIState.Play("Purchase")
						NotifyScreen.Toast(`{def.Name} — level {level + 1}!`, "Good")
					end
				end, "Upgrade_" .. k)
				if balance < cost then
					b:SetColor(C.PaperDim)
				end
			else
				ShopMenu.Stamp(right, "MAXED", C.Mint:Lerp(C.Ink, 0.3))
			end
		end
	end

	local function renderItems()
		local l = newList()
		local have = Data:Get("Items") or {}
		local balance = Data:GetCandy()
		UIKit.Label({ Text = "You bring these into the house. One use each.", Font = Theme.Font.Body, TextSize = Theme.Text.Small, Color = C.PaperDim, Stroke = false, Size = UDim2.new(1, -24, 0, 34), LayoutOrder = 0, Parent = l })
		for i, k in EconomyConfig.ItemOrder do
			local def = EconomyConfig.Items[k]
			local owned = have[k] or 0
			local _row, right = ShopMenu.Row(l, i, (UIIcons :: any)[k], `{def.Name}  <font color="#7B5C8E">×{owned}/{def.Max}</font>`, def.Blurb)
			if owned >= def.Max then
				ShopMenu.Stamp(right, "POCKETS FULL", C.Bruise)
			else
				local b = ShopMenu.PriceButton(right, def.Cost, function()
					local ok = ShopMenu.Call("ShopBuy", "Item", k)
					if ok then
						UIState.Play("Purchase")
					end
				end, "Item_" .. k)
				if balance < def.Cost then
					b:SetColor(C.PaperDim)
				end
			end
		end
	end

	local function robuxButton(parent: Instance, kind: string, key: string, id: number): any
		local b = UIKit.Button({ Parent = parent, Text = "Get it", Color = C.Mint, Size = UDim2.fromOffset(250, 84), Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), TextSize = 32, OnClick = function()
			ShopMenu.Call("RequestPurchase", kind, key)
		end })
		b.Button:SetAttribute("Key", kind .. "_" .. key)
		task.spawn(function()
			local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, if kind == "Pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
			if ok and typeof(info) == "table" and info.PriceInRobux and b.Button.Parent then
				b:SetText(`R$ {info.PriceInRobux}`)
			end
		end)
		return b
	end

	local function renderTreats()
		local l = newList()
		UIKit.Label({ Text = "Grandma doesn't need to know.", Font = Theme.Font.Body, TextSize = Theme.Text.Small, Color = C.PaperDim, Stroke = false, Size = UDim2.new(1, -24, 0, 34), LayoutOrder = 0, Parent = l })
		local order = 0
		for _, key in packs do
			local p = Monetization.Products[key]
			order += 1
			local _row, right = ShopMenu.Row(l, order, UIIcons.Candy, p.Name, `{UIWidgets.Number(p.Candy)} Candy`, C.Mustard)
			robuxButton(right, "Product", key, p.Id)
		end
		for _, key in passes do
			local p = Monetization.Passes[key]
			order += 1
			local _row, right = ShopMenu.Row(l, order, if key == "BigPillowcase" then UIIcons.Sack else UIIcons.Trophy, p.Name, p.Blurb or "", C.Paper)
			if player:GetAttribute("Pass_" .. key) == true then
				ShopMenu.Stamp(right, "OWNED", C.Mint:Lerp(C.Ink, 0.3))
			else
				robuxButton(right, "Pass", key, p.Id)
			end
		end
	end

	local function render()
		local focus = ShopMenu.FocusKey()
		if tab == "Upgrades" then
			renderUpgrades()
		elseif tab == "Items" then
			renderItems()
		else
			renderTreats()
		end
		ShopMenu.RestoreFocus(content, focus)
	end

	tabs = UIKit.Tabs({
		Parent = body,
		Tabs = tabDefs,
		OnSelect = function(key)
			tab = key
			render()
		end,
	})

	local isOpen = false
	Data.Changed:Connect(function(key, value)
		if key == "Candy" then
			candy:Set(tonumber(value) or Data:GetCandy(), isOpen)
		end
		if isOpen and (key == "Upgrades" or key == "Items" or key == "Candy" or key == "Passes") then
			render()
		end
	end)
	player.AttributeChanged:Connect(function(attr)
		if isOpen and tab == "Treats" and attr:sub(1, 5) == "Pass_" then
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
		OnOpen = function(arg: any)
			isOpen = true
			candy:Set(Data:GetCandy())
			tabs:Select(if typeof(arg) == "string" then arg else (tabs.Current() or "Upgrades"))
		end,
		OnClose = function()
			isOpen = false
		end,
	}
end

function ShopMenu.Mount(_ctx: any)
	MenuHost.Register("Shop", build)
end

return ShopMenu
