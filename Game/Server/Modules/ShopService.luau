--!strict
-- ShopService
-- Candy purchases (upgrades, consumables, cosmetics) and cosmetic equipping.
-- All prices come from EconomyConfig / CosmeticsConfig; the client only sends intent.

local Players = game:GetService("Players")

local DataService = shared("DataService")
local EconomyConfig = shared("EconomyConfig")
local CosmeticsConfig = shared("CosmeticsConfig")
local Net = shared("Net")

local ShopService = {}

local Buy = Net.Function("ShopBuy")
local Equip = Net.Function("ShopEquip")

-- Push equipped cosmetics into attributes so every client can render them.
function ShopService:ApplyCosmetics(player: Player)
	local c = DataService:Get(player, "Cosmetics")
	if not c then
		return
	end
	local fl = CosmeticsConfig.Flashlight[c.Equipped.Flashlight] or CosmeticsConfig.Flashlight.Warm
	local sack = CosmeticsConfig.Sack[c.Equipped.Sack] or CosmeticsConfig.Sack.Plain
	player:SetAttribute("FlashlightColor", fl.Color)
	player:SetAttribute("SackColor", sack.Color)
end

local function buyUpgrade(player: Player, key: string)
	local def = EconomyConfig.Upgrades[key]
	if not def then
		return false, "Unknown"
	end
	local level = (DataService:Get(player, "Upgrades") or {})[key] or 0
	local cost = def.Cost[level + 1]
	if not cost then
		return false, "Maxed"
	end
	if not DataService:TrySpend(player, cost) then
		return false, "Not enough Candy"
	end
	DataService:Update(player, "Upgrades", function(u)
		u[key] = level + 1
		return u
	end)
	return true
end

local function buyItem(player: Player, key: string)
	local def = EconomyConfig.Items[key]
	if not def then
		return false, "Unknown"
	end
	local owned = (DataService:Get(player, "Items") or {})[key] or 0
	if owned >= def.Max then
		return false, "Pockets full"
	end
	if not DataService:TrySpend(player, def.Cost) then
		return false, "Not enough Candy"
	end
	DataService:AddItem(player, key, 1, def.Max)
	return true
end

local function buyCosmetic(player: Player, slot: string, id: string)
	local set = CosmeticsConfig[slot]
	local def = set and set[id]
	if not def or def.Source ~= "Shop" then
		return false, "Not for sale"
	end
	local c = DataService:Get(player, "Cosmetics")
	if c.Owned[slot] and c.Owned[slot][id] then
		return false, "Owned"
	end
	if not DataService:TrySpend(player, def.Cost) then
		return false, "Not enough Candy"
	end
	DataService:UnlockCosmetic(player, slot, id)
	return true
end

function ShopService.Preload() end

function ShopService:Start()
	Buy.OnServerInvoke = function(player, kind, a, b)
		if not Net.RateLimit(player, "ShopBuy", 4) or not DataService:IsLoaded(player) then
			return false, "Slow down"
		end
		if typeof(kind) ~= "string" or typeof(a) ~= "string" then
			return false, "Invalid"
		end
		if kind == "Upgrade" then
			return buyUpgrade(player, a)
		elseif kind == "Item" then
			return buyItem(player, a)
		elseif kind == "Cosmetic" and typeof(b) == "string" then
			return buyCosmetic(player, a, b)
		end
		return false, "Invalid"
	end

	Equip.OnServerInvoke = function(player, slot, id)
		if not Net.RateLimit(player, "ShopEquip", 4) or typeof(slot) ~= "string" or typeof(id) ~= "string" then
			return false
		end
		local c = DataService:Get(player, "Cosmetics")
		if not c or not CosmeticsConfig[slot] or not (c.Owned[slot] and c.Owned[slot][id]) then
			return false
		end
		DataService:Update(player, "Cosmetics", function(v)
			v.Equipped[slot] = id
			return v
		end)
		ShopService:ApplyCosmetics(player)
		return true
	end

	-- Settings (client sends the whole table; every field is validated & clamped)
	Net.Event("SaveSettings").OnServerEvent:Connect(function(player, s)
		if typeof(s) ~= "table" or not Net.RateLimit(player, "SaveSettings", 2) then
			return
		end
		DataService:Update(player, "Settings", function(cur)
			if typeof(s.Music) == "number" then
				cur.Music = math.clamp(s.Music, 0, 1)
			end
			if typeof(s.SFX) == "number" then
				cur.SFX = math.clamp(s.SFX, 0, 1)
			end
			if typeof(s.Sensitivity) == "number" then
				cur.Sensitivity = math.clamp(s.Sensitivity, 0.2, 3)
			end
			if typeof(s.ReduceFlashes) == "boolean" then
				cur.ReduceFlashes = s.ReduceFlashes
			end
			return cur
		end)
	end)
	Net.Event("MarkTutorial").OnServerEvent:Connect(function(player, key)
		if key == "SeenIntro" and Net.RateLimit(player, "MarkTutorial", 1) then
			DataService:Update(player, "Tutorial", function(t)
				t.SeenIntro = true
				return t
			end)
		end
	end)

	DataService.PlayerLoaded:Connect(function(p)
		ShopService:ApplyCosmetics(p)
	end)
	for _, p in Players:GetPlayers() do
		if DataService:IsLoaded(p) then
			ShopService:ApplyCosmetics(p)
		end
	end
end

return ShopService
