--!strict
-- MonetizationService
-- Game passes + developer products. IDs live in Config/MonetizationConfig.
-- Clients never prompt directly: they ask RequestPurchase(key) and the server validates
-- the moment (e.g. you can only buy a Revive while dead) before prompting.
--
-- Product handlers are registered by gameplay services:
--   MonetizationService:RegisterProduct(key, validate(player) -> bool, grant(player) -> bool)
-- If grant fails at receipt time (e.g. the night ended), the purchase is converted to a
-- stored Token so the player never loses what they paid for.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local MonetizationConfig = shared("MonetizationConfig")
local EconomyConfig = shared("EconomyConfig")
local DataService = shared("DataService")
local Net = shared("Net")

local MonetizationService = {}

type Handler = { Validate: (Player) -> (boolean, string?), Grant: (Player) -> boolean, Fallback: ((Player) -> ())? }
local handlers: { [string]: Handler } = {}
local productKeyById: { [number]: string } = {}
local passKeyById: { [number]: string } = {}

local RequestPurchase = Net.Function("RequestPurchase")
local PurchaseResult = Net.Event("PurchaseResult") -- (key, success)

for key, p in MonetizationConfig.Products do
	if p.Id ~= 0 then
		productKeyById[p.Id] = key
	end
end
for key, p in MonetizationConfig.Passes do
	if p.Id ~= 0 then
		passKeyById[p.Id] = key
	end
end

function MonetizationService:RegisterProduct(key: string, validate: (Player) -> (boolean, string?), grant: (Player) -> boolean, fallback: ((Player) -> ())?)
	handlers[key] = { Validate = validate, Grant = grant, Fallback = fallback }
end

function MonetizationService:HasPass(player: Player, key: string): boolean
	return player:GetAttribute("Pass_" .. key) == true
end

function MonetizationService:IsProductConfigured(key: string): boolean
	local p = MonetizationConfig.Products[key]
	return p ~= nil and p.Id ~= 0
end

-- Apply a pass's permanent effects. Idempotent.
function MonetizationService:OnPassOwned(player: Player, key: string)
	if not DataService:IsLoaded(player) then
		return
	end
	player:SetAttribute("Pass_" .. key, true)
	DataService:Update(player, "Passes", function(p)
		p[key] = true
		return p
	end)

	if key == "VIP" then
		DataService:UnlockCosmetic(player, "Flashlight", "Gold")
	elseif key == "StarterPack" then
		local grants = DataService:Get(player, "Grants")
		if not grants.StarterPack then
			local cfg = MonetizationConfig.Passes.StarterPack
			DataService:AddCandy(player, cfg.Candy)
			for _, item in EconomyConfig.ItemOrder do
				DataService:AddItem(player, item, cfg.ItemCount, EconomyConfig.Items[item].Max)
			end
			DataService:UnlockCosmetic(player, "Sack", cfg.Cosmetic)
			DataService:Update(player, "Grants", function(g)
				g.StarterPack = true
				return g
			end)
		end
	end
end

local function checkPasses(player: Player)
	-- Cached ownership first (instant), then verify with Roblox.
	local cached = DataService:Get(player, "Passes") or {}
	for key in cached do
		player:SetAttribute("Pass_" .. key, true)
	end
	for id, key in passKeyById do
		local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
		if ok and owns then
			MonetizationService:OnPassOwned(player, key)
		end
	end
end

-- Candy packs are handled here; gameplay products are registered by their services.
local function grantBuiltin(player: Player, key: string): boolean?
	local p = MonetizationConfig.Products[key]
	if p and p.Candy then
		DataService:AddCandy(player, p.Candy)
		return true
	end
	return nil
end

local function processReceipt(receipt): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player or not DataService:WaitForData(player, 10) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local processed = DataService:Get(player, "ProcessedReceipts")
	if processed[receipt.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local key = productKeyById[receipt.ProductId]
	if not key then
		warn("[Monetization] Unknown product", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local granted = grantBuiltin(player, key)
	if granted == nil then
		local h = handlers[key]
		local ok, result = pcall(function()
			return h and h.Grant(player)
		end)
		if not (ok and result) then
			-- Couldn't apply right now (moment passed): store it so it's never lost.
			if h and h.Fallback then
				pcall(h.Fallback, player)
			else
				DataService:AddCandy(player, math.floor((MonetizationConfig.Products[key].RecommendedPrice or 25) * 10))
			end
		end
	end

	DataService:Update(player, "ProcessedReceipts", function(r)
		r[receipt.PurchaseId] = os.time()
		-- Trim entries older than 30 days
		local cutoff = os.time() - 30 * 86400
		for id, t in r do
			if t < cutoff then
				r[id] = nil
			end
		end
		return r
	end)
	PurchaseResult:FireClient(player, key, true)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.Preload() end

function MonetizationService:Start()
	-- Override VIDK's handler with our de-duplicating one.
	MarketplaceService.ProcessReceipt = processReceipt

	DataService.PlayerLoaded:Connect(function(player)
		task.spawn(checkPasses, player)
	end)
	for _, p in Players:GetPlayers() do
		if DataService:IsLoaded(p) then
			task.spawn(checkPasses, p)
		end
	end

	RequestPurchase.OnServerInvoke = function(player: Player, kind: string, key: string)
		if typeof(kind) ~= "string" or typeof(key) ~= "string" then
			return false, "Invalid"
		end
		if not Net.RateLimit(player, "Purchase", 1) then
			return false, "Slow down"
		end
		if kind == "Pass" then
			local pass = MonetizationConfig.Passes[key]
			if not pass or pass.Id == 0 then
				return false, "Coming soon"
			end
			if MonetizationService:HasPass(player, key) then
				return false, "Owned"
			end
			MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			return true
		elseif kind == "Product" then
			local product = MonetizationConfig.Products[key]
			if not product or product.Id == 0 then
				return false, "Coming soon"
			end
			local h = handlers[key]
			if h then
				local ok, reason = h.Validate(player)
				if not ok then
					return false, reason or "Not now"
				end
			end
			MarketplaceService:PromptProductPurchase(player, product.Id)
			return true
		end
		return false, "Invalid"
	end
end

return MonetizationService
