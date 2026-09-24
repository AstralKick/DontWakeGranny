--!strict
-- EventConfig
-- Random night events. One (at most) is rolled per night by EventService using
-- NightConfig.EventChance, weighted by Weight, respecting MinNight.
-- Effects are read by the relevant services via EventService:Get() / Has().

return {
	LightSleeper = {
		Title = "GRANDMA IS A LIGHT SLEEPER",
		Blurb = "She hears everything tonight.",
		Weight = 10, MinNight = 3, Color = Color3.fromRGB(217, 122, 138),
		HearingMult = 1.55,
	},
	HardOfHearing = {
		Title = "GRANDMA LOST HER HEARING AID",
		Blurb = "Loud is fine. Mostly.",
		Weight = 9, MinNight = 3, Color = Color3.fromRGB(156, 197, 161),
		HearingMult = 0.5,
	},
	PowerOutage = {
		Title = "POWER OUTAGE",
		Blurb = "Keep your flashlight close.",
		Weight = 8, MinNight = 4, Color = Color3.fromRGB(123, 92, 142),
		PowerOff = true,
	},
	BloodMoon = {
		Title = "BLOOD MOON",
		Blurb = "Loot is worth double. So is Grandma.",
		Weight = 6, MinNight = 8, Color = Color3.fromRGB(168, 50, 62),
		LootMult = 2, SpeedMult = 1.12, HearingMult = 1.15, RedSky = true,
	},
	DoubleLoot = {
		Title = "GRANDMA WENT SHOPPING",
		Blurb = "Twice the loot tonight.",
		Weight = 7, MinNight = 3, Color = Color3.fromRGB(224, 176, 79),
		LootCountMult = 1.8,
	},
	LockedDoors = {
		Title = "LOCKED DOORS",
		Blurb = "Grandma locked up. Pick carefully.",
		Weight = 7, MinNight = 5, Color = Color3.fromRGB(123, 92, 142),
		LockCount = 4,
	},
	AlreadyAwake = {
		Title = "GRANDMA IS ALREADY AWAKE",
		Blurb = "Good luck.",
		Weight = 5, MinNight = 7, Color = Color3.fromRGB(168, 50, 62),
		StartAwake = true,
	},
	CookieNight = {
		Title = "GRANDMA BAKED COOKIES",
		Blurb = "Throw one. She can't resist.",
		Weight = 7, MinNight = 3, Color = Color3.fromRGB(224, 176, 79),
		FreeItem = "Cookie",
	},
}
