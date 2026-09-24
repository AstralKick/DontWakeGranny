--!strict
-- GrandmaConfig
-- Everything about Grandma that isn't per-night tuning.
--
-- ============================================================================
-- DEVELOPER — ADDING / REPLACING GRANNIES
--   1. Drop rigs (Models) into ReplicatedStorage.Grannies. Every Model in that folder is a
--      candidate Grandma; one is picked at random (see RigSelection). Add as many as you like.
--   2. Requirements per rig: a Humanoid, a HumanoidRootPart (set as PrimaryPart), a part
--      named "Head". Optional: parts named "Eye" (forms make them glow), parts with attribute
--      Skin = true (forms tint them). An Animator is created automatically if missing.
--   3. Optional per-rig overrides as attributes on the rig Model:
--        DisplayName (string)  e.g. "Granny Mae" — shown in the night intro / caught screen
--        Weight (number)       relative pick chance (default 1)
--        MinNight (number)     only eligible from this night (default 1)
--        SpeedMult (number)    multiplies her speeds (default 1)
--   4. Put animation IDs in Animations (below). Any animation with Id = 0 falls back to the
--      procedural placeholder, so you can replace them one at a time. A rig may override
--      a slot with a StringValue child "Anim_<Slot>" whose Value is "rbxassetid://...".
--   5. Optional: per-form jumpscare tuning in Forms[*].Jumpscare.
-- Nothing in the AI depends on the rig's parts beyond Humanoid / HumanoidRootPart / Head.
-- ============================================================================

local GrandmaConfig = {}

GrandmaConfig.RigFolder = "Grannies" -- ReplicatedStorage.<RigFolder>
GrandmaConfig.RigName = "TempGrandma" -- fallback if the folder is empty / selection fails
-- "PerRun": one Grandma for the whole run. "PerNight": may change every night.
GrandmaConfig.RigSelection = "PerRun"

-- Collision/pathing agent
GrandmaConfig.Agent = {
	AgentRadius = 1.6,
	AgentHeight = 5.5,
	AgentCanJump = false,
	AgentCanClimb = false,
	WaypointSpacing = 4,
}

-- Animation slots. Id = 0 -> procedural placeholder (see Client/Modules/GrandmaAnimController).
-- Priority is the AnimationPriority used when a real ID is supplied.
GrandmaConfig.Animations = {
	Sleep = { Id = 0, Looped = true, Priority = Enum.AnimationPriority.Idle },
	Stir = { Id = 0, Looped = true, Priority = Enum.AnimationPriority.Action },
	Wake = { Id = 0, Looped = false, Priority = Enum.AnimationPriority.Action },
	Idle = { Id = 0, Looped = true, Priority = Enum.AnimationPriority.Idle },
	Walk = { Id = 0, Looped = true, Priority = Enum.AnimationPriority.Movement },
	Search = { Id = 0, Looped = true, Priority = Enum.AnimationPriority.Action },
	Run = { Id = 0, Looped = true, Priority = Enum.AnimationPriority.Movement },
	Attack = { Id = 0, Looped = false, Priority = Enum.AnimationPriority.Action4 },
	CheckHiding = { Id = 0, Looped = false, Priority = Enum.AnimationPriority.Action2 },
	Laugh = { Id = 0, Looped = false, Priority = Enum.AnimationPriority.Action2 },
	Jumpscare = { Id = 0, Looped = false, Priority = Enum.AnimationPriority.Action4 },
}

-- Maps AI states to animation slots. Moving states pick Walk/Run by speed automatically.
GrandmaConfig.StateAnimation = {
	Asleep = "Sleep",
	FakeSleep = "Sleep",
	Stirring = "Stir",
	Waking = "Wake",
	Searching = "Search",
	Returning = "Walk",
	Stalking = "Idle",
	Chasing = "Run",
	Attacking = "Attack",
	CheckingHiding = "CheckHiding",
	Patrolling = "Walk",
}

-- Visual forms, chosen by NightConfig.Form. Applied to whatever rig is loaded.
-- Scale: Model:ScaleTo multiplier. EyeColor/EyeGlow: applied to parts tagged/named "Eye".
-- Jumpscare: modular per form. Sound keys refer to AssetConfig.Sounds.
GrandmaConfig.Forms = {
	Normal = {
		Scale = 1,
		EyeColor = Color3.fromRGB(40, 30, 30),
		EyeGlow = 0,
		SkinTint = nil,
		Jumpscare = {
			Duration = 1.35,
			Sound = "JumpscareNormal",
			Flash = Color3.fromRGB(255, 240, 225),
			Shake = 0.9,
			FOV = 55,
			Distortion = 0.4,
			Animation = "Jumpscare",
			Line = "GOTCHA, SWEETIE!",
		},
	},
	Wretched = {
		Scale = 1.08,
		EyeColor = Color3.fromRGB(255, 214, 120),
		EyeGlow = 1.5,
		SkinTint = Color3.fromRGB(176, 170, 150),
		Jumpscare = {
			Duration = 1.4,
			Sound = "JumpscareWretched",
			Flash = Color3.fromRGB(255, 220, 150),
			Shake = 1.1,
			FOV = 50,
			Distortion = 0.6,
			Animation = "Jumpscare",
			Line = "NO RUNNING IN MY HOUSE.",
		},
	},
	Nightmare = {
		Scale = 1.28,
		EyeColor = Color3.fromRGB(255, 40, 40),
		EyeGlow = 4,
		SkinTint = Color3.fromRGB(128, 112, 118),
		Jumpscare = {
			Duration = 1.5,
			Sound = "JumpscareNightmare",
			Flash = Color3.fromRGB(255, 50, 40),
			Shake = 1.5,
			FOV = 42,
			Distortion = 1,
			Animation = "Jumpscare",
			Line = "MINE.",
		},
	},
	Halloween = {
		Scale = 1.35,
		EyeColor = Color3.fromRGB(255, 140, 20),
		EyeGlow = 5,
		SkinTint = Color3.fromRGB(120, 105, 110),
		Jumpscare = {
			Duration = 1.55,
			Sound = "JumpscareNightmare",
			Flash = Color3.fromRGB(255, 140, 20),
			Shake = 1.6,
			FOV = 40,
			Distortion = 1,
			Animation = "Jumpscare",
			Line = "TRICK. OR. TREAT.",
		},
	},
}

-- Jumpscare VARIANTS (how she gets you). The Form's Jumpscare block above still gives the
-- sound / flash colour / line / base shake+FOV+distortion; a variant picks the choreography
-- and multiplies the numbers. JumpscareController picks one per catch: weighted random over
-- the variants with MinNight <= Night <= (MaxNight or 30). Night 31 only uses Halloween = true.
--   Motion      choreography in JumpscareController: Lunge · Grab · BehindYou · Drop · Peek · Scream · Rise,
--               and the map-themed Curtain · Rush · Beside · Pop · Crooked (always on the Void stage)
--               (several variants may share a Motion with different numbers)
--   Stage       "Void" (dark stage far above the map) or "World" (right where you stand; falls
--               back to Void when there's no room behind/in front of the camera)
--   Weight      at Night 1 · WeightLate = weight at Night 30 (lerped; defaults to Weight)
--   Duration    seconds (clamped 1.2–1.8 after intensity)
--   Shake / FOV / Distortion   multipliers on the Form's values (default 1)
--   Line        optional override of the Form's line
--   Maps        { MapId, ... }: only on these maps (map-themed scares) · PropColor: stage prop colour
--   Sound       per-variant sound design (all optional; every key is an AssetConfig.Sounds key):
--     Hit / HitAt      the main sting, REPLACES the Form's Sound when its Id is set (else Form sting)
--     Pre / PreAt      build-up before the hit (whisper, creak, click...)   · Extra / ExtraAt  one more layer
--     Scream           false = no JumpscareScream layer (default on, at the motion's scream beat)
--     Volume           multiplier on everything this variant plays
--     Pitch            { Night 1, Night 30 } PlaybackSpeed multiplier (early = higher / bouncier)
--     Distortion       { Night 1, Night 30 } DistortionSoundEffect.Level on the hit + scream (0 = none)
--     PitchShift       { Night 1, Night 30 } PitchShiftSoundEffect.Octave on the scream (1 = none)
--     Reverb           true = a ReverbSoundEffect on the hit (roomy, late-night feel)
GrandmaConfig.JumpscareVariants = {
	Lunge = {
		Motion = "Lunge", Stage = "Void", MinNight = 1, Weight = 10, WeightLate = 3, Duration = 1.35,
		-- classic orchestral stab
		Sound = { Hit = "Jumpscare_Lunge", Pitch = { 1.1, 0.92 }, Distortion = { 0, 0.3 } },
	},
	Grab = {
		Motion = "Grab", Stage = "Void", MinNight = 3, Weight = 5, WeightLate = 5, Duration = 1.45, Shake = 1.1, FOV = 1.1,
		-- fast whoosh -> grab impact
		Sound = { Pre = "Jumpscare_GrabPre", PreAt = 0, Hit = "Jumpscare_Grab", HitAt = 0.22, Pitch = { 1.15, 0.95 }, Distortion = { 0, 0.35 } },
	},
	BehindYou = {
		Motion = "BehindYou", Stage = "World", MinNight = 7, Weight = 5, WeightLate = 7, Duration = 1.6,
		-- a whisper right behind you... sharp hit on the whip-around
		Sound = { Pre = "Jumpscare_BehindYouPre", PreAt = 0, Hit = "Jumpscare_BehindYou", Pitch = { 1.05, 0.88 }, Distortion = { 0, 0.4 }, Reverb = true },
	},
	Drop = {
		Motion = "Drop", Stage = "World", MinNight = 11, Weight = 4, WeightLate = 6, Duration = 1.5,
		-- ceiling creak -> thud + shriek
		Sound = { Pre = "Jumpscare_DropPre", PreAt = 0, Hit = "Jumpscare_Drop", Extra = "Break", ExtraAt = 0.32, Pitch = { 1.05, 0.85 }, Distortion = { 0.05, 0.45 } },
	},
	Peek = {
		Motion = "Peek", Stage = "World", MinNight = 16, Weight = 4, WeightLate = 6, Duration = 1.75,
		-- power-down click, silence, a giggle in the flash, then the scream
		Sound = { Pre = "Jumpscare_PeekPre", PreAt = 0.08, Hit = "Jumpscare_Peek", Pitch = { 1, 0.85 }, Distortion = { 0.1, 0.5 }, PitchShift = { 1, 0.85 }, Reverb = true },
	},
	Scream = {
		Motion = "Scream", Stage = "Void", MinNight = 21, Weight = 4, WeightLate = 7, Duration = 1.3, Shake = 1.35, Distortion = 1.3, FOV = 1.2,
		-- one long, distorted scream
		Sound = { Hit = "Jumpscare_Scream", Pitch = { 0.95, 0.8 }, Distortion = { 0.3, 0.75 }, PitchShift = { 0.95, 0.8 }, Volume = 1.1 },
	},
	-- Map-themed scares: Maps = only on these maps (see MapConfig). Weighted high so roughly
	-- a third to half of the catches on a map use its own scare.
	Sheet = {
		Motion = "Curtain", Stage = "Void", Maps = { "BackGarden" }, Weight = 7, WeightLate = 7, Duration = 1.55,
		PropColor = Color3.fromRGB(236, 230, 214), Line = "Peekaboo, dearie.",
		-- sheet flapping on the washing line -> whip + scream
		Sound = { Pre = "Jumpscare_SheetPre", PreAt = 0, Hit = "Jumpscare_Sheet", Pitch = { 1.05, 0.9 }, Distortion = { 0.05, 0.4 } },
	},
	Curtain = {
		Motion = "Curtain", Stage = "Void", Maps = { "SunnyPines" }, Weight = 5, WeightLate = 5, Duration = 1.55,
		PropColor = Color3.fromRGB(170, 204, 196), Line = "Lights out means BED.",
		-- privacy-curtain rings rattling -> rip it open
		Sound = { Pre = "Jumpscare_CurtainPre", PreAt = 0, Hit = "Jumpscare_Curtain", Pitch = { 1.05, 0.9 }, Distortion = { 0.05, 0.4 } },
	},
	Wheelchair = {
		Motion = "Rush", Stage = "Void", Maps = { "SunnyPines" }, Weight = 6, WeightLate = 6, Duration = 1.5, Shake = 1.15,
		-- buzzing tube light + squeaky wheels getting closer -> hit
		Sound = { Pre = "Jumpscare_WheelchairPre", PreAt = 0, Hit = "Jumpscare_Wheelchair", Pitch = { 1.05, 0.9 }, Distortion = { 0.1, 0.45 } },
	},
	Toll = {
		Motion = "Beside", Stage = "Void", Maps = { "StMildreds" }, Weight = 7, WeightLate = 7, Duration = 1.6,
		-- one deep bell toll in the dark -> she's beside you
		Sound = { Pre = "Jumpscare_TollPre", PreAt = 0, Hit = "Jumpscare_Toll", Pitch = { 1, 0.85 }, Distortion = { 0.05, 0.4 }, Reverb = true },
	},
	JackInTheBox = {
		Motion = "Pop", Stage = "Void", Maps = { "HarvestFair" }, Weight = 7, WeightLate = 7, Duration = 1.6, Line = "POP!",
		PropColor = Color3.fromRGB(196, 40, 52),
		-- music-box "Pop Goes the Weasel" slowing down -> spring boing + shriek
		Sound = { Pre = "Jumpscare_JackInTheBoxPre", PreAt = 0, Hit = "Jumpscare_JackInTheBox", Pitch = { 1.1, 0.9 }, Distortion = { 0.05, 0.4 } },
	},
	Crooked = {
		Motion = "Crooked", Stage = "Void", Maps = { "NightmareHouse" }, Weight = 7, WeightLate = 7, Duration = 1.65, Distortion = 1.2,
		-- dripping silence, a slow neck crack -> distorted hit
		Sound = { Pre = "Jumpscare_CrookedPre", PreAt = 0.46, Hit = "Jumpscare_Crooked", Pitch = { 0.95, 0.8 }, Distortion = { 0.3, 0.7 }, Reverb = true },
	},
	TrickOrTreat = {
		Motion = "Rise", Stage = "Void", Halloween = true, Weight = 1, Duration = 1.7, Line = "TRICK. OR. TREAT.",
		-- cackle in the dark -> pumpkin crunch / bell hit
		Sound = { Pre = "Jumpscare_TrickOrTreatPre", PreAt = 0, Hit = "Jumpscare_TrickOrTreat", Extra = "ClockChime", ExtraAt = 0.62, Pitch = { 0.9, 0.9 }, Distortion = { 0.35, 0.35 }, Reverb = true },
	},
}

-- How hard the scare hits by night: { Night 1 value, Night 30 value } (lerped; Night 31 = late).
-- Nights <= ComedicUntil get a bouncy line, a higher-pitched sting and a warm grade.
GrandmaConfig.JumpscareIntensity = {
	ComedicUntil = 5,
	Shake = { 0.7, 1.5 },
	FOV = { 0.8, 1.2 }, -- scales how far the FOV punches in from 70
	Distortion = { 0.45, 1.35 },
	Duration = { -0.08, 0.2 },
	Volume = { 0.85, 1.25 },
	Pitch = { 1.12, 0.9 },
}

-- ============================================================================
-- OUTFITS — Grandma wears something different every night.
-- A rig's clothing parts are grouped into slots. Final rigs: give clothing parts the
-- attribute OutfitSlot = "<Slot>". Rigs without attributes use OutfitParts (name patterns,
-- matched against part names — set up for TempGrandma).
-- Slots: Top, TopTrim, Buttons, Dress, DressShade (auto: darker Dress if omitted), DressTrim,
--        Pattern (list; cycled across pattern parts), Collar, Slippers, SlipperTrim, Needles (list)
-- Outfit fields: Name, MinNight / MaxNight / Nights (explicit list), Weight, Material (Dress).
-- One outfit per night, never the same as the previous night (random per run).
-- ============================================================================
GrandmaConfig.OutfitParts = {
	Top = { "^UpperTorso$", "^Hump$", "UpperArm$" },
	TopTrim = { "Cuff$" },
	Buttons = { "^CardiganButton" },
	Dress = { "^GownTier", "^NightgownBib$", "^LowerTorso$" },
	DressShade = { "UpperLeg$" },
	DressTrim = { "^GownHem$" },
	Pattern = { "^GownFlower" },
	Collar = { "Collar$" },
	Slippers = { "^LeftFoot$", "^RightFoot$" },
	SlipperTrim = { "SlipperPom$" },
	Needles = { "^KnittingNeedle[AB]$" },
}

local C = Color3.fromRGB
GrandmaConfig.Outfits = {
	{ Name = "Sunday Best", MaxNight = 15,
		Top = C(217, 122, 138), TopTrim = C(184, 98, 116), Buttons = C(224, 176, 79), Dress = C(166, 128, 150), DressTrim = C(123, 92, 142),
		Pattern = { C(224, 176, 79), C(243, 233, 210), C(217, 122, 138) }, Collar = C(243, 233, 210), Slippers = C(156, 197, 161), SlipperTrim = C(205, 228, 205), Needles = { C(123, 92, 142), C(217, 122, 138) } },
	{ Name = "Mint Tea", MaxNight = 15,
		Top = C(156, 197, 161), TopTrim = C(112, 150, 118), Buttons = C(243, 233, 210), Dress = C(226, 214, 188), DressTrim = C(217, 122, 138),
		Pattern = { C(217, 122, 138), C(156, 197, 161), C(224, 176, 79) }, Collar = C(243, 233, 210), Slippers = C(217, 122, 138), SlipperTrim = C(240, 196, 204), Needles = { C(224, 176, 79), C(112, 150, 118) } },
	{ Name = "Butterscotch", MaxNight = 20,
		Top = C(224, 176, 79), TopTrim = C(176, 130, 52), Buttons = C(92, 62, 44), Dress = C(170, 98, 74), DressTrim = C(110, 60, 48),
		Pattern = { C(243, 233, 210), C(224, 176, 79), C(156, 197, 161) }, Collar = C(243, 233, 210), Slippers = C(123, 92, 142), SlipperTrim = C(172, 150, 200), Needles = { C(110, 60, 48), C(243, 233, 210) } },
	{ Name = "Lavender Nightie", MaxNight = 20,
		Top = C(150, 130, 190), TopTrim = C(110, 92, 150), Buttons = C(243, 233, 210), Dress = C(204, 194, 226), DressTrim = C(123, 92, 142),
		Pattern = { C(243, 233, 210), C(217, 122, 138), C(156, 197, 161) }, Collar = C(243, 233, 210), Slippers = C(240, 200, 210), SlipperTrim = C(243, 233, 210), Needles = { C(217, 122, 138), C(110, 92, 150) } },
	{ Name = "Gingham Kitchen", MaxNight = 20,
		Top = C(206, 96, 90), TopTrim = C(243, 233, 210), Buttons = C(243, 233, 210), Dress = C(240, 232, 215), DressTrim = C(206, 96, 90),
		Pattern = { C(206, 96, 90), C(206, 96, 90), C(243, 233, 210) }, Collar = C(206, 96, 90), Slippers = C(92, 72, 62), SlipperTrim = C(150, 122, 100), Needles = { C(206, 96, 90), C(92, 72, 62) } },
	{ Name = "Church Pew", MinNight = 3, MaxNight = 25,
		Top = C(62, 70, 110), TopTrim = C(40, 46, 80), Buttons = C(214, 178, 84), Dress = C(92, 98, 140), DressTrim = C(40, 46, 80),
		Pattern = { C(243, 233, 210), C(214, 178, 84), C(217, 122, 138) }, Collar = C(243, 233, 210), Slippers = C(62, 52, 52), SlipperTrim = C(122, 112, 112), Needles = { C(214, 178, 84), C(40, 46, 80) } },
	{ Name = "Rose Garden", MinNight = 4, MaxNight = 20,
		Top = C(200, 90, 110), TopTrim = C(150, 60, 80), Buttons = C(243, 233, 210), Dress = C(240, 204, 208), DressTrim = C(156, 197, 161),
		Pattern = { C(200, 90, 110), C(156, 197, 161), C(224, 176, 79) }, Collar = C(243, 233, 210), Slippers = C(156, 197, 161), SlipperTrim = C(243, 233, 210), Needles = { C(156, 197, 161), C(150, 60, 80) } },
	{ Name = "Moth-Eaten", MinNight = 8,
		Top = C(140, 128, 112), TopTrim = C(110, 98, 86), Buttons = C(80, 70, 60), Dress = C(170, 160, 140), DressTrim = C(110, 98, 86),
		Pattern = { C(120, 110, 96), C(150, 140, 120), C(100, 90, 80) }, Collar = C(200, 190, 170), Slippers = C(110, 98, 86), SlipperTrim = C(150, 140, 120), Needles = { C(80, 70, 60), C(120, 110, 96) } },
	{ Name = "Cherry Jam Apron", MinNight = 12,
		Top = C(150, 140, 130), TopTrim = C(120, 40, 50), Buttons = C(120, 40, 50), Dress = C(222, 212, 196), DressTrim = C(168, 50, 62),
		Pattern = { C(168, 50, 62), C(140, 40, 50), C(168, 50, 62) }, Collar = C(222, 212, 196), Slippers = C(120, 40, 50), SlipperTrim = C(222, 212, 196), Needles = { C(168, 50, 62), C(120, 40, 50) } },
	{ Name = "Widow's Black", MinNight = 16, MaxNight = 30,
		Top = C(42, 36, 44), TopTrim = C(70, 56, 68), Buttons = C(168, 50, 62), Dress = C(58, 48, 60), DressTrim = C(168, 50, 62),
		Pattern = { C(90, 70, 80), C(168, 50, 62), C(90, 70, 80) }, Collar = C(200, 190, 180), Slippers = C(42, 36, 44), SlipperTrim = C(168, 50, 62), Needles = { C(168, 50, 62), C(70, 56, 68) } },
	{ Name = "Funeral Lace", MinNight = 22, MaxNight = 30,
		Top = C(30, 26, 34), TopTrim = C(123, 92, 142), Buttons = C(200, 196, 210), Dress = C(46, 38, 56), DressTrim = C(123, 92, 142),
		Pattern = { C(123, 92, 142), C(200, 196, 210), C(123, 92, 142) }, Collar = C(200, 196, 210), Slippers = C(30, 26, 34), SlipperTrim = C(123, 92, 142), Needles = { C(200, 196, 210), C(30, 26, 34) } },
	{ Name = "Grave Dirt", MinNight = 26, MaxNight = 30,
		Top = C(70, 64, 52), TopTrim = C(48, 42, 34), Buttons = C(120, 110, 90), Dress = C(96, 88, 70), DressTrim = C(48, 42, 34),
		Pattern = { C(60, 54, 44), C(80, 72, 58), C(60, 54, 44) }, Collar = C(140, 130, 110), Slippers = C(48, 42, 34), SlipperTrim = C(80, 72, 58), Needles = { C(48, 42, 34), C(120, 110, 90) } },
	-- Chapter wardrobes (Maps = only on these maps, 4x as likely there; see GrandmaRig.PickOutfit).
	{ Name = "Potting Shed", Maps = { "BackGarden" },
		Top = C(122, 140, 88), TopTrim = C(86, 100, 60), Buttons = C(150, 110, 70), Dress = C(196, 178, 140), DressTrim = C(122, 140, 88),
		Pattern = { C(217, 122, 138), C(224, 176, 79), C(156, 197, 161) }, Collar = C(236, 226, 206), Slippers = C(70, 90, 60), SlipperTrim = C(120, 100, 70), Needles = { C(122, 140, 88), C(150, 110, 70) } },
	{ Name = "Prize Marrow", Maps = { "BackGarden" },
		Top = C(224, 176, 79), TopTrim = C(160, 120, 50), Buttons = C(92, 120, 70), Dress = C(236, 220, 176), DressTrim = C(92, 120, 70),
		Pattern = { C(92, 120, 70), C(200, 90, 110), C(92, 120, 70) }, Collar = C(243, 233, 210), Slippers = C(92, 120, 70), SlipperTrim = C(224, 176, 79), Needles = { C(92, 120, 70), C(224, 176, 79) } },
	{ Name = "Visiting Hours", Maps = { "SunnyPines" },
		Top = C(170, 200, 214), TopTrim = C(120, 150, 170), Buttons = C(243, 233, 210), Dress = C(214, 228, 232), DressTrim = C(120, 150, 170),
		Pattern = { C(243, 233, 210), C(156, 197, 161), C(170, 200, 214) }, Collar = C(243, 233, 210), Slippers = C(236, 236, 230), SlipperTrim = C(170, 200, 214), Needles = { C(120, 150, 170), C(243, 233, 210) } },
	{ Name = "Bingo Night", Maps = { "SunnyPines" },
		Top = C(236, 160, 120), TopTrim = C(190, 110, 80), Buttons = C(243, 233, 210), Dress = C(156, 197, 161), DressTrim = C(190, 110, 80),
		Pattern = { C(236, 160, 120), C(243, 233, 210), C(224, 176, 79) }, Collar = C(243, 233, 210), Slippers = C(236, 160, 120), SlipperTrim = C(243, 233, 210), Needles = { C(190, 110, 80), C(156, 197, 161) } },
	{ Name = "Evensong", Maps = { "StMildreds" },
		Top = C(60, 54, 80), TopTrim = C(214, 178, 84), Buttons = C(214, 178, 84), Dress = C(88, 78, 110), DressTrim = C(214, 178, 84),
		Pattern = { C(214, 178, 84), C(200, 196, 210), C(214, 178, 84) }, Collar = C(236, 232, 224), Slippers = C(40, 36, 48), SlipperTrim = C(214, 178, 84), Needles = { C(214, 178, 84), C(60, 54, 80) } },
	{ Name = "Graveside Grey", Maps = { "StMildreds" },
		Top = C(110, 110, 118), TopTrim = C(70, 70, 80), Buttons = C(40, 36, 44), Dress = C(150, 150, 158), DressTrim = C(70, 70, 80),
		Pattern = { C(90, 90, 100), C(120, 90, 110), C(90, 90, 100) }, Collar = C(210, 206, 200), Slippers = C(50, 48, 54), SlipperTrim = C(110, 110, 118), Needles = { C(70, 70, 80), C(150, 150, 158) } },
	{ Name = "Candy Apple", Maps = { "HarvestFair" },
		Top = C(196, 40, 52), TopTrim = C(130, 24, 36), Buttons = C(243, 233, 210), Dress = C(243, 220, 190), DressTrim = C(196, 40, 52),
		Pattern = { C(196, 40, 52), C(92, 150, 120), C(224, 176, 79) }, Collar = C(243, 233, 210), Slippers = C(92, 150, 120), SlipperTrim = C(243, 233, 210), Needles = { C(196, 40, 52), C(224, 176, 79) } },
	{ Name = "Ringmaster", Maps = { "HarvestFair" },
		Top = C(120, 40, 70), TopTrim = C(224, 176, 79), Buttons = C(224, 176, 79), Dress = C(40, 90, 100), DressTrim = C(224, 176, 79),
		Pattern = { C(224, 176, 79), C(243, 233, 210), C(120, 40, 70) }, Collar = C(243, 233, 210), Slippers = C(30, 26, 34), SlipperTrim = C(224, 176, 79), Needles = { C(224, 176, 79), C(40, 90, 100) } },
	{ Name = "Nursery Rhyme", Maps = { "NightmareHouse" },
		Top = C(236, 200, 214), TopTrim = C(150, 50, 70), Buttons = C(150, 50, 70), Dress = C(214, 226, 236), DressTrim = C(150, 50, 70),
		Pattern = { C(150, 50, 70), C(90, 30, 50), C(150, 50, 70) }, Collar = C(243, 233, 210), Slippers = C(236, 200, 214), SlipperTrim = C(150, 50, 70), Needles = { C(150, 50, 70), C(214, 226, 236) } },
	{ Name = "Rootbound", Maps = { "NightmareHouse" },
		Top = C(60, 30, 40), TopTrim = C(120, 20, 40), Buttons = C(200, 60, 60), Dress = C(80, 50, 56), DressTrim = C(140, 30, 50),
		Pattern = { C(140, 30, 50), C(60, 30, 40), C(140, 30, 50) }, Collar = C(170, 150, 150), Slippers = C(40, 24, 28), SlipperTrim = C(140, 30, 50), Needles = { C(140, 30, 50), C(60, 30, 40) } },
	{ Name = "Halloween Witch", Nights = { 31 },
		Top = C(30, 26, 34), TopTrim = C(255, 140, 20), Buttons = C(255, 140, 20), Dress = C(64, 40, 76), DressTrim = C(255, 140, 20),
		Pattern = { C(255, 140, 20), C(140, 200, 80), C(255, 140, 20) }, Collar = C(30, 26, 34), Slippers = C(255, 140, 20), SlipperTrim = C(30, 26, 34), Needles = { C(255, 140, 20), C(140, 200, 80) } },
}

-- AI timing (seconds). Per-night speeds/senses are in NightConfig.
GrandmaConfig.AI = {
	TickRate = 0.1,
	StirDuration = 5,
	WakeAt = 88, -- alert (0..100) at which a stirring Grandma gets up (the HUD ring is alert / 100)
	MaxStirTime = 11, -- stirring this long without calming below the stir line = she gets up anyway
	WakeDuration = 1.6, -- stand-up time before she starts moving (fair warning)
	AttackPause = 2.6,
	LookAroundTime = 2.2,
	CloseSenseRange = 7, -- she notices anyone this close (not crouching) even behind her
	CrouchVisionMult = 0.6,
	FlashlightVisionMult = 1.6, -- only when ReactsToLights
	StirNoiseMult = 1.5,
	WakeNoiseFloor = 18, -- alert after she goes back to sleep
	NoiseInvestigateMin = 3.5, -- effective loudness needed to redirect her search (awake: she turns toward most noises)
	StuckTime = 1.8,
	DoorOpenPause = 0.45,
	HoldBreathTime = 2.4,
	StalkTime = 9,
	FakeSleepChance = 0.35,
	TeleportChance = 0.25,
	PowerCutCooldown = 45,
	LoseTargetLookTime = 2.5,
	BathroomBreakAt = 40, -- seconds into night 1/2 for her scripted wander
	-- Camping: stay hidden too long and she comes for you (even from her chair). The hide timer
	-- fills while you're hidden and drains CampDecay x as fast while you're out. At the limit
	-- she walks straight to your spot and pulls you out if you're still in it (no breath save).
	CampLimit = { 75, 30 }, -- seconds, Night 1 -> Night 30 (lerped); Night 31 uses the last
	CampWarnAt = 0.6, -- fraction of the limit where the "she can smell you" warning starts
	CampDecay = 2,
	CampAfterCheck = 0.35, -- the timer drops to this fraction once she has come and gone
}

-- Voice lines by tier (NightConfig.VoiceTier). Shown as a bubble above her + optional sound.
-- DEVELOPER: add sound keys by setting AssetConfig.Sounds["Voice_<Category>"].
GrandmaConfig.VoiceLines = {
	Asleep = {
		[1] = { "Zzz... Harold...", "Mmm... cookies...", "Zzz..." },
		[2] = { "Zzz... who's been in my room...", "Harold, the children are here...", "Zzz..." },
		[3] = { "I can hear you breathing...", "Zzz... hungry...", "Zzz... count the children..." },
		[4] = { "...awake... awake... awake...", "I never sleep, dearie.", "Zzz... mine..." },
	},
	Stirring = {
		[1] = { "Hm? Who's there?", "Is that you, sweetie?", "Mmh... Harold?" },
		[2] = { "Who's making that racket?", "I heard that.", "Sweetie...?" },
		[3] = { "I know you're here.", "Little mouse...", "I heard you." },
		[4] = { "I SMELL you.", "Come here.", "Found you... almost." },
	},
	Searching = {
		[1] = { "Come out, come out!", "Grandma made cookies!", "Where's my little helper?" },
		[2] = { "No hiding in Grandma's house!", "I'll find you, sweetie.", "Who touched my things?" },
		[3] = { "You can't hide forever.", "I checked there last time...", "Such naughty children." },
		[4] = { "EVERY. ROOM.", "I can hear your heart.", "There's no morning here." },
	},
	Chasing = {
		[1] = { "COME GIVE GRANDMA A HUG!", "NO RUNNING IN THE HOUSE!", "COME BACK HERE!" },
		[2] = { "GET BACK HERE, YOU LITTLE THIEF!", "THOSE ARE MINE!", "GRANDMA WANTS A HUG!" },
		[3] = { "YOU'RE STAYING FOREVER!", "RUN, RUN, RUN!", "I'M SO HUNGRY!" },
		[4] = { "MINE MINE MINE MINE", "COME HERE COME HERE", "YOU CAN'T LEAVE" },
	},
	Lost = {
		[1] = { "Hmph. Kids these days.", "Where did they go?", "My old knees..." },
		[2] = { "Next time, sweetie.", "I'll find you later.", "Sneaky little mouse." },
		[3] = { "I'll wait.", "I'm very patient.", "You'll come back." },
		[4] = { "I'm right behind you.", "Always.", "Soon." },
	},
	Caught = {
		[1] = { "Gotcha!", "Time for bed!", "Big hug!" },
		[2] = { "Naughty!", "Into the cupboard with you!", "Caught one!" },
		[3] = { "One less.", "Delicious.", "Stay forever." },
		[4] = { "MINE.", "Next.", "Who's next, dearies?" },
	},
	Camping = {
		[1] = { "Is somebody in my wardrobe?", "Come out, come out, sweetie...", "Grandma knows where you are!" },
		[2] = { "I can hear you in there.", "Hiding again, dearie?", "Coming to tuck you in..." },
		[3] = { "I can SMELL you in there.", "Such a long time in the dark...", "Knock knock." },
		[4] = { "I'm coming in.", "No more hiding.", "Found you. FOUND YOU." },
	},
	HidingCheck = {
		[1] = { "Anybody in here?" },
		[2] = { "Peekaboo?" },
		[3] = { "I know this spot..." },
		[4] = { "Hello again." },
	},
}

return GrandmaConfig
