--!strict
-- NightConfig
-- Builds the full tuning table for any night 1..31.
-- Base values ramp smoothly; MILESTONES layer on new mechanics, areas and forms so the
-- run feels like chapters instead of one long number increase.
--
-- DEVELOPER: tune the curves in BASE, or override single nights in OVERRIDES.

local MapConfig = require(script.Parent:WaitForChild("MapConfig"))

local NightConfig = {}

export type Abilities = {
	HearsDoors: boolean,
	ReactsToLights: boolean,
	ChecksHiding: boolean,
	LearnsHiding: boolean,
	LocksDoors: boolean,
	Stalks: boolean,
	CutsPower: boolean,
	FakeSleep: boolean,
	Teleports: boolean,
	NeverSleeps: boolean,
}

export type Night = {
	Night: number,
	Duration: number,
	WalkSpeed: number,
	SearchSpeed: number,
	ChaseSpeed: number,
	Hearing: number,
	VisionRange: number,
	FOV: number,
	SearchDuration: number,
	LoseSightTime: number,
	AlertDecay: number,
	StirThreshold: number,
	CatchRange: number,
	HidingCheckChance: number,
	LootMult: number,
	LootCount: number,
	DangerBias: number,
	ContainerChanceMult: number,
	PickupNoiseMult: number,
	EasyLoot: number,
	ListCount: number,
	LootGoal: number,
	GoalBonus: number,
	EventChance: number,
	Areas: { [string]: boolean },
	NewArea: string?,
	Corruption: number,
	Form: string,
	VoiceTier: number,
	Abilities: Abilities,
	BathroomBreak: boolean,
	Finale: boolean,
	Title: string,
	Subtitle: string,
}

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Chapter subtitles shown on the night title card.
local SUBTITLES = {
	[1] = "She's just napping.",
	[2] = "Don't wake her.",
	[3] = "She talks in her sleep.",
	[4] = "Tiptoe.",
	[5] = "She's getting lighter sleep.",
	[6] = "Upstairs is open.",
	[7] = "Doors squeak. She knows.",
	[8] = "The pictures moved.",
	[9] = "Grandma's awake more often.",
	[10] = "Halfway to Halloween.",
	[11] = "Something's in the basement.",
	[12] = "She hates flashlights.",
	[13] = "The house is humming.",
	[14] = "Where's Grandpa?",
	[15] = "Don't look at the dolls.",
	[16] = "The attic door is open.",
	[17] = "She checks the closets now.",
	[18] = "She's locking doors.",
	[19] = "She remembers where you hide.",
	[20] = "She waits outside.",
	[21] = "The lights belong to her.",
	[22] = "The walls are breathing.",
	[23] = "Is she really asleep?",
	[24] = "She's everywhere.",
	[25] = "This isn't Grandma's house anymore.",
	[26] = "What has she become?",
	[27] = "Nightmare.",
	[28] = "She's so hungry.",
	[29] = "Two more nights.",
	[30] = "Tomorrow is Halloween.",
	[31] = "Light the pumpkins. Get to the car.",
}

-- Chapter milestones: new areas / forms / corruption.
local function areasFor(n: number): ({ [string]: boolean }, string?)
	-- Areas open per night of the current chapter (each chapter is its own map).
	return MapConfig.AreasFor(n)
end

local function formFor(n: number): string
	if n == 31 then
		return "Halloween"
	elseif n >= 26 then
		return "Nightmare"
	elseif n >= 16 then
		return "Wretched"
	end
	return "Normal"
end

local function corruptionFor(n: number): number
	if n >= 26 then
		return 4
	elseif n >= 21 then
		return 3
	elseif n >= 14 then
		return 2
	elseif n >= 8 then
		return 1
	end
	return 0
end

-- Per-night overrides applied after the base values. Keys match Night fields.
local OVERRIDES: { [number]: { [string]: any } } = {
	[1] = { Hearing = 0.8, StirThreshold = 38, EventChance = 0, BathroomBreak = true, Duration = 120 },
	[2] = { EventChance = 0, BathroomBreak = true },
	[6] = { EventChance = 0 },
	[11] = { EventChance = 0 },
	[16] = { EventChance = 0 },
	[21] = { EventChance = 0 },
	[26] = { EventChance = 0, ChaseSpeed = 23.5 },
	[31] = { EventChance = 0, Finale = true, Duration = 330, ChaseSpeed = 22, SearchSpeed = 15 },
}

local cache: { [number]: Night } = {}

function NightConfig.Get(n: number): Night
	n = math.clamp(math.floor(n), 1, 31)
	if cache[n] then
		return cache[n]
	end

	local t = math.clamp((n - 1) / 29, 0, 1)
	local areas, newArea = areasFor(n)

	local night: Night = {
		Night = n,
		Duration = math.min(240, 140 + 4 * (n - 1)),
		WalkSpeed = lerp(7, 10.5, t),
		SearchSpeed = lerp(10, 14.5, t),
		ChaseSpeed = lerp(16.5, 22.5, t),
		Hearing = lerp(0.95, 1.6, t),
		VisionRange = lerp(42, 78, t),
		FOV = lerp(95, 135, t),
		SearchDuration = lerp(14, 42, t),
		LoseSightTime = lerp(2, 4.5, t),
		AlertDecay = lerp(3.5, 1.8, t), -- slow decay: small noises near her add up
		StirThreshold = lerp(38, 26, t),
		CatchRange = 3.6,
		HidingCheckChance = if n >= 16 then lerp(0.25, 0.6, (n - 16) / 15) else 0,
		-- Economy gets trickier every night: each item is worth more (LootMult), but there is
		-- less of it, more of it sits in dangerous rooms, grabbing is noisier, drawers come up
		-- empty more often and the "free" loot by the front door dries up.
		LootMult = 1 + (n - 1) * 0.07,
		LootCount = math.floor(lerp(26, 17, t)),
		DangerBias = lerp(0, 0.65, t), -- chance a spawn is moved to a riskier room
		ContainerChanceMult = lerp(1, 0.6, t),
		PickupNoiseMult = lerp(1, 1.6, t),
		EasyLoot = if n <= 2 then 4 elseif n <= 5 then 2 elseif n <= 10 then 1 else 0,
		-- Tonight's list: steal these (the Prize + others), stash them all = night ends early.
		ListCount = if n <= 10 then 3 elseif n <= 20 then 4 else 5,
		-- Per-player stash goal for the night (Candy banked incl. dawn auto-stash). Hitting it
		-- pays GoalBonus × goal on top of the survival bonus. Pushes "grab as much as you can".
		LootGoal = if n == 31 then 0 else math.floor(lerp(60, 650, t) / 10) * 10,
		GoalBonus = 0.3,
		EventChance = if n >= 3 then math.min(0.75, 0.3 + n * 0.015) else 0,
		Areas = areas,
		NewArea = newArea,
		Corruption = corruptionFor(n),
		Form = formFor(n),
		VoiceTier = if n >= 26 then 4 elseif n >= 16 then 3 elseif n >= 6 then 2 else 1,
		Abilities = {
			HearsDoors = n >= 6,
			ReactsToLights = n >= 11,
			ChecksHiding = n >= 16,
			LearnsHiding = n >= 19,
			LocksDoors = n >= 18,
			Stalks = n >= 20,
			CutsPower = n >= 21,
			FakeSleep = n >= 23,
			Teleports = n >= 24,
			NeverSleeps = n == 31,
		},
		BathroomBreak = false,
		Finale = false,
		Title = if n == 31 then "HALLOWEEN NIGHT" else `NIGHT {n}`,
		Subtitle = SUBTITLES[n] or "",
	}

	local o = OVERRIDES[n]
	if o then
		for k, v in o do
			(night :: any)[k] = v
		end
	end

	cache[n] = night
	return night
end

function NightConfig.IsCheckpoint(n: number): boolean
	return n == 1 or n == 6 or n == 11 or n == 16 or n == 21 or n == 26
end

return NightConfig
