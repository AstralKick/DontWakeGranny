--!strict
-- LootConfig
-- Loot items, their Candy value, noise, and a tiny procedural visual spec.
-- Value is multiplied by NightConfig.LootMult, party size scaling and events at bank time.
--
-- Tier = which spawn points can roll it (spawn point attribute "Danger" 1..3).
-- Slots = pillowcase slots used. Heavy = slows the carrier and makes footsteps louder.
-- Visual = list of { Shape, Size, Color, Material?, Offset? } built by LootService.

local LootConfig = {}

local C = Color3.fromRGB
local M = Enum.Material

LootConfig.Items = {
	-- Tier 1 — hallways, kitchen, bathroom
	WrappedCandy = { Name = "Wrapped Candy", Tier = 1, Value = 8, Noise = 4, Slots = 1, Weight = 10,
		Visual = { { "Ball", Vector3.new(0.6, 0.45, 0.45), C(226, 96, 120), M.SmoothPlastic }, { "Box", Vector3.new(1.1, 0.12, 0.3), C(240, 200, 90), M.SmoothPlastic } } },
	LooseChange = { Name = "Loose Change", Tier = 1, Value = 10, Noise = 8, Slots = 1, Weight = 9,
		Visual = { { "Cyl", Vector3.new(0.1, 0.55, 0.55), C(214, 180, 90), M.Metal }, { "Cyl", Vector3.new(0.1, 0.45, 0.45), C(190, 190, 196), M.Metal, Vector3.new(0.3, 0.02, 0.2) } } },
	ButterscotchTin = { Name = "Butterscotch Tin", Tier = 1, Value = 14, Noise = 7, Slots = 1, Weight = 8,
		Visual = { { "Cyl", Vector3.new(0.45, 1.1, 1.1), C(70, 110, 170), M.Metal }, { "Cyl", Vector3.new(0.05, 1.12, 1.12), C(230, 190, 90), M.Metal, Vector3.new(0, 0.24, 0) } } },
	SilverSpoon = { Name = "Silver Spoon", Tier = 1, Value = 16, Noise = 5, Slots = 1, Weight = 7,
		Visual = { { "Box", Vector3.new(1.3, 0.08, 0.16), C(205, 205, 212), M.Metal }, { "Ball", Vector3.new(0.4, 0.12, 0.3), C(205, 205, 212), M.Metal, Vector3.new(0.75, 0, 0) } } },
	ButtonJar = { Name = "Jar of Buttons", Tier = 1, Value = 12, Noise = 9, Slots = 1, Weight = 7,
		Visual = { { "Cyl", Vector3.new(0.9, 0.7, 0.7), C(200, 220, 230), M.Glass }, { "Cyl", Vector3.new(0.15, 0.72, 0.72), C(150, 80, 70), M.Metal, Vector3.new(0, 0.5, 0) } } },

	-- Tier 2 — living room, dining, upstairs
	PocketWatch = { Name = "Pocket Watch", Tier = 2, Value = 36, Noise = 5, Slots = 1, Weight = 8,
		Visual = { { "Cyl", Vector3.new(0.18, 0.8, 0.8), C(214, 178, 84), M.Metal }, { "Cyl", Vector3.new(0.2, 0.62, 0.62), C(240, 232, 214), M.SmoothPlastic } } },
	Teacup = { Name = "Porcelain Teacup", Tier = 2, Value = 30, Noise = 10, Slots = 1, Weight = 8,
		Visual = { { "Cyl", Vector3.new(0.55, 0.7, 0.7), C(240, 236, 228), M.SmoothPlastic }, { "Cyl", Vector3.new(0.06, 1.05, 1.05), C(240, 236, 228), M.SmoothPlastic, Vector3.new(0, -0.28, 0) } } },
	CameoBrooch = { Name = "Cameo Brooch", Tier = 2, Value = 44, Noise = 4, Slots = 1, Weight = 6,
		Visual = { { "Cyl", Vector3.new(0.12, 0.75, 0.55), C(214, 178, 84), M.Metal }, { "Cyl", Vector3.new(0.14, 0.55, 0.4), C(230, 150, 140), M.SmoothPlastic } } },
	SnowGlobe = { Name = "Snow Globe", Tier = 2, Value = 40, Noise = 8, Slots = 1, Weight = 6,
		Visual = { { "Ball", Vector3.new(0.9, 0.9, 0.9), C(210, 230, 240), M.Glass, Vector3.new(0, 0.3, 0) }, { "Cyl", Vector3.new(0.3, 0.9, 0.9), C(90, 60, 50), M.Wood, Vector3.new(0, -0.2, 0) } } },
	GrandpasMedal = { Name = "Grandpa's Medal", Tier = 2, Value = 55, Noise = 5, Slots = 1, Weight = 5,
		Visual = { { "Cyl", Vector3.new(0.1, 0.6, 0.6), C(214, 178, 84), M.Metal }, { "Box", Vector3.new(0.35, 0.7, 0.08), C(150, 50, 60), M.Fabric, Vector3.new(0, 0.55, 0) } } },

	-- Tier 3 — Grandma's bedroom, basement, attic
	PearlNecklace = { Name = "Pearl Necklace", Tier = 3, Value = 95, Noise = 6, Slots = 1, Weight = 6,
		Visual = { { "Ball", Vector3.new(0.3, 0.3, 0.3), C(245, 240, 232), M.SmoothPlastic, Vector3.new(-0.3, 0, 0) }, { "Ball", Vector3.new(0.3, 0.3, 0.3), C(245, 240, 232), M.SmoothPlastic }, { "Ball", Vector3.new(0.3, 0.3, 0.3), C(245, 240, 232), M.SmoothPlastic, Vector3.new(0.3, 0, 0) } } },
	GoldTooth = { Name = "Gold Tooth", Tier = 3, Value = 110, Noise = 3, Slots = 1, Weight = 4,
		Visual = { { "Box", Vector3.new(0.35, 0.45, 0.35), C(240, 196, 70), M.Metal } } },
	MusicBox = { Name = "Music Box", Tier = 3, Value = 120, Noise = 14, Slots = 2, Weight = 4,
		Visual = { { "Box", Vector3.new(1.2, 0.7, 0.9), C(120, 60, 70), M.Wood }, { "Box", Vector3.new(1.22, 0.1, 0.92), C(214, 178, 84), M.Metal, Vector3.new(0, 0.3, 0) } } },
	JewelryBox = { Name = "Jewelry Box", Tier = 3, Value = 150, Noise = 12, Slots = 2, Weight = 3,
		Visual = { { "Box", Vector3.new(1.3, 0.8, 1), C(60, 40, 70), M.Fabric }, { "Box", Vector3.new(0.3, 0.2, 0.1), C(214, 178, 84), M.Metal, Vector3.new(0, 0.1, 0.5) } } },
}

-- Nightly Prize — one spawns each night in a Danger 3 "PrizeSpawn". Big value, Heavy.
-- MinNight gates creepier prizes to later chapters.
LootConfig.Prizes = {
	Dentures = { Name = "Grandma's Dentures", Value = 260, Noise = 10, Slots = 2, Heavy = false, MinNight = 1,
		Visual = { { "Box", Vector3.new(1.1, 0.35, 0.8), C(230, 120, 130), M.SmoothPlastic }, { "Box", Vector3.new(1, 0.2, 0.7), C(250, 248, 240), M.SmoothPlastic, Vector3.new(0, 0.25, 0) } } },
	CookieJar = { Name = "The Cookie Jar", Value = 240, Noise = 16, Slots = 3, Heavy = true, MinNight = 1,
		Visual = { { "Cyl", Vector3.new(1.6, 1.4, 1.4), C(200, 150, 100), M.SmoothPlastic }, { "Ball", Vector3.new(1, 0.5, 1), C(160, 90, 70), M.SmoothPlastic, Vector3.new(0, 0.9, 0) } } },
	WeddingRing = { Name = "Wedding Ring", Value = 320, Noise = 3, Slots = 1, Heavy = false, MinNight = 4,
		Visual = { { "Cyl", Vector3.new(0.12, 0.5, 0.5), C(240, 196, 70), M.Metal }, { "Ball", Vector3.new(0.18, 0.18, 0.18), C(200, 240, 255), M.Glass, Vector3.new(0, 0.28, 0) } } },
	PhotoAlbum = { Name = "Family Photo Album", Value = 220, Noise = 8, Slots = 2, Heavy = false, MinNight = 6,
		Visual = { { "Box", Vector3.new(1.4, 0.4, 1.1), C(110, 50, 45), M.Fabric } } },
	GrandpasUrn = { Name = "Grandpa's Urn", Value = 380, Noise = 18, Slots = 3, Heavy = true, MinNight = 14,
		Visual = { { "Cyl", Vector3.new(1.5, 1, 1), C(60, 70, 90), M.Metal }, { "Ball", Vector3.new(0.7, 0.4, 0.7), C(214, 178, 84), M.Metal, Vector3.new(0, 0.9, 0) } } },
	CursedDoll = { Name = "The Porcelain Doll", Value = 420, Noise = 12, Slots = 2, Heavy = false, MinNight = 21,
		Visual = { { "Ball", Vector3.new(0.7, 0.7, 0.7), C(240, 230, 220), M.SmoothPlastic, Vector3.new(0, 0.7, 0) }, { "Box", Vector3.new(0.8, 1, 0.5), C(150, 60, 80), M.Fabric } } },
}

-- Diary pages: collectible lore (DiaryConfig). One may spawn per night.
LootConfig.DiaryChance = 0.4

-- Searchable containers. Placed in the map as parts tagged "Searchable" with attribute Kind.
LootConfig.Containers = {
	Drawer = { Label = "Search Drawer", Hold = 0.9, Noise = 16, Chance = 0.7 },
	Cabinet = { Label = "Search Cabinet", Hold = 1.1, Noise = 20, Chance = 0.7 },
	Fridge = { Label = "Raid Fridge", Hold = 1.3, Noise = 26, Chance = 0.8 },
	ToyChest = { Label = "Open Toy Chest", Hold = 1.3, Noise = 24, Chance = 0.75 },
	Vanity = { Label = "Search Vanity", Hold = 1.5, Noise = 22, Chance = 0.9, TierBonus = 1 },
	Trunk = { Label = "Open Old Trunk", Hold = 1.8, Noise = 30, Chance = 0.95, TierBonus = 1 },
}

-- Picking something up makes this much noise * item Noise / 10.
LootConfig.PickupNoiseRadius = 45

return LootConfig
