-- ProductConfig
-- VIDK integration shim. VIDK's SMProfile reads this table keyed by numeric Game Pass ID
-- ({ GamepassFunction = fn(player) }) when a profile loads / a pass is bought.
-- The real source of truth is MonetizationConfig; this file just forwards to
-- MonetizationService so passes are handled in one place. Developer Products are
-- processed by MonetizationService's own ProcessReceipt (with purchase de-duplication).

local MonetizationConfig = require(script.Parent.MonetizationConfig)

local ProductConfig = {}

for key, pass in MonetizationConfig.Passes do
	if pass.Id and pass.Id ~= 0 then
		ProductConfig[pass.Id] = {
			GamepassFunction = function(player: Player)
				local ok, service = pcall(shared, "MonetizationService")
				if ok and service then
					service:OnPassOwned(player, key)
				end
			end,
		}
	end
end

return ProductConfig
