--!strict
-- CosmeticsConfig
-- Visible identity items. Kept to things other players actually see in the house:
-- the flashlight beam tint and the pillowcase on your back.
-- Source: "Shop" (Candy), "Pass" (game pass), "Reward" (achievement/victory only).

local C = Color3.fromRGB

return {
	Flashlight = {
		Warm = { Name = "Old Bulb", Color = C(255, 226, 170), Source = "Default", Order = 1 },
		Moonlight = { Name = "Moonlight", Color = C(190, 214, 255), Source = "Shop", Cost = 600, Order = 2 },
		Minty = { Name = "Mint Candy", Color = C(170, 255, 205), Source = "Shop", Cost = 900, Order = 3 },
		Bubblegum = { Name = "Bubblegum", Color = C(255, 170, 214), Source = "Shop", Cost = 1200, Order = 4 },
		Candlelight = { Name = "Candlelight", Color = C(255, 170, 90), Source = "Shop", Cost = 1800, Order = 5 },
		Gold = { Name = "VIP Gold", Color = C(255, 214, 110), Source = "Pass", Pass = "VIP", Order = 6 },
		Pumpkin = { Name = "Jack-o'-Lantern", Color = C(255, 130, 30), Source = "Reward", Order = 7 },
	},
	Sack = {
		Plain = { Name = "Plain Pillowcase", Color = C(236, 226, 206), Source = "Default", Order = 1 },
		Floral = { Name = "Grandma's Floral", Color = C(217, 122, 138), Source = "Shop", Cost = 500, Order = 2 },
		Plaid = { Name = "Plaid", Color = C(123, 92, 142), Source = "Shop", Cost = 900, Order = 3 },
		Mint = { Name = "Minty Stripes", Color = C(156, 197, 161), Source = "Shop", Cost = 900, Order = 4 },
		Patchwork = { Name = "Patchwork", Color = C(224, 176, 79), Source = "Pass", Pass = "StarterPack", Order = 5 },
		Halloween = { Name = "Survivor's Sack", Color = C(255, 120, 20), Source = "Reward", Order = 6 },
	},
}
