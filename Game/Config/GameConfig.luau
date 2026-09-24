--!strict
-- GameConfig
-- Global gameplay tuning. Per-night tuning lives in NightConfig, Grandma in GrandmaConfig.

return {
	MaxPlayers = 5,
	TotalNights = 31,
	Checkpoints = { 1, 6, 11, 16, 21, 26 },

	-- Match flow (seconds)
	ArrivalTimeout = 25, -- wait this long for the whole party to arrive before starting anyway
	NightIntroTime = 9, -- cinematic night intro (establishing shots + title card); players are frozen
	FirstNightIntroTime = 11, -- Night 1 gets a slightly longer, scene-setting intro
	IntermissionTime = 14, -- morning summary between nights
	GameOverTime = 20, -- window to buy Continue Run after a team wipe
	ReturnToLobbyDelay = 8, -- after victory / game over

	-- The in-game clock runs 12:00 AM -> 6:00 AM over the night's Duration.
	ClockStartHour = 0,
	ClockEndHour = 6,

	-- Movement
	Movement = {
		CrouchSpeed = 7,
		WalkSpeed = 12,
		SprintSpeed = 20,
		HeavySpeedPenalty = 3, -- carrying a Heavy item (Prize)
		StaminaMax = 100,
		StaminaDrain = 22, -- per second sprinting
		StaminaRegen = 14, -- per second not sprinting
		StaminaRegenDelay = 0.8,
		StaminaMinToSprint = 15,
		CrouchCameraOffset = Vector3.new(0, -1.6, 0),
	},

	-- Carrying
	Inventory = {
		BaseSlots = 5,
	},

	-- Staying outside the house during a night
	Loiter = {
		GraceSeconds = 20, -- continuous seconds outside before Grandma "senses" you
		Loudness = 70,
	},

	-- Death / revive
	Revive = {
		MaxPerNight = 1, -- per player
		MinTimeLeft = 12, -- can't revive in the last N seconds of a night
		SpawnProtection = 4, -- Grandma ignores revived players for N seconds
		FreeFirstRevive = true, -- every player's first-ever revive is free ("First one's on Grandma")
	},
	ContinueRun = {
		MaxPerRun = 3,
	},

	-- Difficulty scaling by party size. Index = number of players in the match.
	-- Hearing: more players = more noise sources, so Grandma hears a bit less per sound.
	PartyScaling = {
		[1] = { Hearing = 1.0, Speed = 0.94, LootMult = 1.0, CatchGrace = 0.35 },
		[2] = { Hearing = 0.92, Speed = 0.97, LootMult = 1.15, CatchGrace = 0.2 },
		[3] = { Hearing = 0.85, Speed = 1.0, LootMult = 1.3, CatchGrace = 0.1 },
		[4] = { Hearing = 0.8, Speed = 1.02, LootMult = 1.45, CatchGrace = 0 },
		[5] = { Hearing = 0.76, Speed = 1.04, LootMult = 1.6, CatchGrace = 0 },
	},

	-- Collision groups
	CollisionGroups = {
		Players = "Players",
		Grandma = "Grandma",
		Doors = "Doors",
		Loot = "Loot",
	},
}
