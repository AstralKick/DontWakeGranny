--!strict
-- MonetizationConfig
-- ============================================================================
-- DEVELOPER: create these in Creator Dashboard → Monetization and paste the IDs.
-- Id = 0 means "not configured": the product is hidden in UI and cannot be prompted.
-- Recommended prices are in Robux and only shown here as guidance.
-- ============================================================================

return {
	-- Developer Products (repeatable)
	Products = {
		Revive = { Id = 0, RecommendedPrice = 29, Name = "Revive" },
		ContinueRun = { Id = 0, RecommendedPrice = 79, Name = "Continue Run" },
		SugarRush = { Id = 0, RecommendedPrice = 49, Name = "Sugar Rush" }, -- 2x loot for the whole server, next night
		CandySmall = { Id = 0, RecommendedPrice = 49, Name = "Handful of Candy", Candy = 500 },
		CandyMedium = { Id = 0, RecommendedPrice = 149, Name = "Bag of Candy", Candy = 1800 },
		CandyLarge = { Id = 0, RecommendedPrice = 399, Name = "Bucket of Candy", Candy = 5500 },
	},

	-- Game Passes (one-time)
	Passes = {
		VIP = { Id = 0, RecommendedPrice = 249, Name = "VIP",
			Blurb = "+20% Candy, gold flashlight, VIP tag" },
		BigPillowcase = { Id = 0, RecommendedPrice = 149, Name = "Huge Pillowcase",
			Blurb = "+2 loot slots, forever", Slots = 2 },
		StarterPack = { Id = 0, RecommendedPrice = 99, Name = "Sneaky Starter Pack",
			Blurb = "1,000 Candy, 3 of each item, Patchwork pillowcase", Candy = 1000, ItemCount = 3,
			Cosmetic = "Patchwork" },
	},

	-- Sugar Rush strength/duration
	SugarRush = { LootMult = 2, Nights = 1 },
}
