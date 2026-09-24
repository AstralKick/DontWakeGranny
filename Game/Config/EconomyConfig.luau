--!strict
-- EconomyConfig
-- Candy sources and sinks. Everything the player can earn or buy with Candy.

local EconomyConfig = {}

EconomyConfig.CurrencyName = "Candy"

-- Night rewards (per surviving player)
EconomyConfig.SurviveBonus = function(night: number): number
	return 20 + 6 * night
end
-- Tonight's list: every item on it stashed = the night ends early, and each player still
-- standing gets this on top of the survival bonus.
EconomyConfig.ListBonus = function(night: number): number
	return 60 + 15 * night
end
EconomyConfig.VictoryBonus = 2500
EconomyConfig.PrizeXPNote = "Prizes are worth their Value in Candy when banked."

-- Friends
EconomyConfig.FriendBonusPerFriend = 0.10
EconomyConfig.FriendBonusMax = 0.40
EconomyConfig.BuddyBonusDaily = 100 -- first match each day that includes a friend
EconomyConfig.ReferralNewPlayer = 200 -- the invited friend (first join only)
EconomyConfig.ReferralInviter = 300 -- the inviter, delivered via ProfileStore message

-- VIP pass
EconomyConfig.VIPCandyMult = 0.2

-- Permanent upgrades. Cost[i] = price of level i. Effect read by the relevant service.
EconomyConfig.Upgrades = {
	Pillowcase = {
		Name = "Bigger Pillowcase", Blurb = "+1 loot slot",
		Cost = { 400, 1200, 3000 }, PerLevel = 1,
	},
	SoftSocks = {
		Name = "Soft Socks", Blurb = "Quieter sprinting",
		Cost = { 350, 1000, 2600 }, PerLevel = 0.15, -- -15% sprint noise per level
	},
	StrongLungs = {
		Name = "Strong Lungs", Blurb = "+15 stamina",
		Cost = { 300, 900, 2200 }, PerLevel = 15,
	},
	Batteries = {
		Name = "Fresh Batteries", Blurb = "Flashlight lasts longer",
		Cost = { 250, 800, 2000 }, PerLevel = 0.35, -- +35% battery per level
	},
}

-- Consumables brought into a run. Owned counts are persistent; used up on use.
EconomyConfig.Items = {
	WindupToy = {
		Name = "Wind-up Toy", Blurb = "Throw it. It gets LOUD.", Cost = 60, Max = 5,
		Noise = { Loudness = 60, Radius = 90, Pulses = 6, Interval = 1 },
	},
	Cookie = {
		Name = "Grandma's Cookie", Blurb = "She can't resist. 6 seconds.", Cost = 90, Max = 5,
		DistractTime = 6,
	},
	FizzySoda = {
		Name = "Fizzy Soda", Blurb = "Full stamina + 6s turbo.", Cost = 50, Max = 5,
		TurboTime = 6,
	},
}
EconomyConfig.ItemOrder = { "WindupToy", "Cookie", "FizzySoda" }

-- Flashlight battery (seconds of light at base level)
EconomyConfig.FlashlightBattery = 150 -- the house is dark while Grandma sleeps: light is precious, not scarce
EconomyConfig.FlashlightRecharge = 0.5 -- seconds of charge regained per second while off

-- Daily mailbox: 7-day streak loop. Missing a day resets to day 1.
EconomyConfig.DailyRewards = {
	{ Candy = 50 },
	{ Candy = 75 },
	{ Candy = 100, Item = "FizzySoda" },
	{ Candy = 125 },
	{ Candy = 150, Item = "WindupToy" },
	{ Candy = 200 },
	{ Candy = 400, Item = "Cookie", ItemCount = 2 },
}

-- Daily quests: 3 rolled per day from this pool.
EconomyConfig.QuestsPerDay = 3
EconomyConfig.Quests = {
	BankCandy = { Text = "Bank %d Candy", Targets = { 300, 600, 1000 }, Reward = { 100, 175, 250 } },
	SurviveNights = { Text = "Survive %d nights", Targets = { 2, 3, 5 }, Reward = { 100, 150, 250 } },
	StealPrize = { Text = "Bank a Prize", Targets = { 1 }, Reward = { 200 } },
	HoldBreath = { Text = "Hold your breath while Grandma checks", Targets = { 1 }, Reward = { 150 } },
	UseItems = { Text = "Use %d items", Targets = { 2, 4 }, Reward = { 100, 160 } },
	EscapeChase = { Text = "Escape %d chases", Targets = { 1, 3 }, Reward = { 120, 220 } },
	SearchContainers = { Text = "Search %d drawers & cabinets", Targets = { 10, 20 }, Reward = { 100, 160 } },
}

return EconomyConfig
