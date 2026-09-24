--!strict
-- AssetConfig
-- ============================================================================
-- DEVELOPER: every external audio/image ID in the game lives here.
-- A value of "" (empty) means "no sound yet" — the game runs silently for that key.
-- Values can be "rbxassetid://123" or plain numbers-as-strings.
-- Sounds tagged -- PLACEHOLDER are temporary picks from the Creator Store; replace freely.
-- ============================================================================

local AssetConfig = {}

-- Music states driven by Grandma's AI state (see Client/Modules/MusicController).
AssetConfig.Music = {
	GrannyAsleep = { Id = "rbxassetid://88770013238738", Volume = 0.45 },
	GrannySearching = { Id = "rbxassetid://118205694442661", Volume = 0.5 },
	GrannyChasing = { Id = "rbxassetid://73519596632243", Volume = 0.6 },
	Lobby = { Id = "rbxassetid://88770013238738", Volume = 0.25 }, -- PLACEHOLDER: reuses GrannyAsleep
	Morning = { Id = "", Volume = 0.35 }, -- intermission sting/loop
	Finale = { Id = "rbxassetid://73519596632243", Volume = 0.6 }, -- PLACEHOLDER: Halloween Night
}

-- One-shot & looped sound effects. Volume/RollOff defaults are applied by Util/Sfx.
AssetConfig.Sounds = {
	-- Grandma
	Snore = { Id = "rbxassetid://9113587030", Volume = 0.9, Looped = true, Max = 60 },
	GrandmaStir = { Id = "rbxassetid://9113861808", Volume = 0.9, Max = 70 }, -- PLACEHOLDER snort
	GrandmaWake = { Id = "", Volume = 1, Max = 90 },
	GrandmaFootstep = { Id = "rbxassetid://9125563740", Volume = 0.55, Max = 55 },
	GrandmaChaseScream = { Id = "", Volume = 1, Max = 120 },
	GrandmaLaugh = { Id = "", Volume = 1, Max = 90 },
	Voice_Generic = { Id = "", Volume = 1, Max = 70 },

	-- Jumpscares (per form, see GrandmaConfig.Forms)
	JumpscareNormal = { Id = "rbxassetid://1846887425", Volume = 1.4 }, -- PLACEHOLDER orchestral hit
	JumpscareWretched = { Id = "rbxassetid://1846887425", Volume = 1.5 },
	JumpscareNightmare = { Id = "rbxassetid://1846887425", Volume = 1.6 },
	JumpscareScream = { Id = "rbxassetid://139162107746216", Volume = 1.2 }, -- PLACEHOLDER (community upload)

	-- Jumpscare VARIANTS (GrandmaConfig.JumpscareVariants[*].Sound). "<Key>" = the hit (replaces the
	-- Form's sting when set, "" -> Form sting), "<Key>Pre" = the build-up before the hit.
	Jumpscare_Lunge = { Id = "rbxassetid://1846887425", Volume = 1.4 }, -- PLACEHOLDER APM orchestral stab
	Jumpscare_GrabPre = { Id = "rbxassetid://9125805579", Volume = 1 }, -- PLACEHOLDER PSE rising whoosh
	Jumpscare_Grab = { Id = "rbxassetid://1846885498", Volume = 1.3 }, -- PLACEHOLDER APM "Action Sting (j)"
	Jumpscare_BehindYouPre = { Id = "rbxassetid://9126213744", Volume = 1 }, -- PLACEHOLDER PSE breathy whisper
	Jumpscare_BehindYou = { Id = "rbxassetid://1841717931", Volume = 1.4 }, -- PLACEHOLDER APM "Immortal Conquest (sting)"
	Jumpscare_DropPre = { Id = "rbxassetid://9126263691", Volume = 1.1 }, -- PLACEHOLDER PSE wood groan creak
	Jumpscare_Drop = { Id = "", Volume = 1.4 }, -- TODO heavy thud + shriek (falls back to the Form sting)
	Jumpscare_PeekPre = { Id = "rbxassetid://9125609743", Volume = 1 }, -- PLACEHOLDER PSE light switch click
	Jumpscare_Peek = { Id = "rbxassetid://9114571613", Volume = 1.3 }, -- PLACEHOLDER PSE ghost giggle (close)
	Jumpscare_Scream = { Id = "rbxassetid://72748337174109", Volume = 1.3 }, -- PLACEHOLDER (community upload) shriek
	Jumpscare_TrickOrTreatPre = { Id = "rbxassetid://9114572131", Volume = 1.2 }, -- PLACEHOLDER PSE possessed giggle (stand-in cackle)
	Jumpscare_TrickOrTreat = { Id = "", Volume = 1.4 }, -- TODO pumpkin crunch / bell hit (falls back to the Form sting)

	-- House
	DoorCreak = { Id = "rbxassetid://9120839174", Volume = 0.8, Max = 60 },
	DoorOpen = { Id = "rbxassetid://9120839010", Volume = 0.5, Max = 40 },
	DoorSlam = { Id = "", Volume = 1, Max = 80 },
	DoorLocked = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.8, Max = 30 },
	Lockpick = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.5, Max = 40 },
	FloorCreak = { Id = "rbxassetid://9125563505", Volume = 1, Max = 60 },
	Break = { Id = "rbxasset://sounds/glassbreak.wav", Volume = 1.2, Max = 120 },
	DrawerSearch = { Id = "rbxassetid://9114496277", Volume = 0.5, Max = 40 },
	LightSwitch = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.7, Max = 45 }, -- PLACEHOLDER: Grandma flicks a light on
	PowerDown = { Id = "", Volume = 1 },
	PowerUp = { Id = "", Volume = 1 },
	ClockChime = { Id = "", Volume = 0.8, Max = 120 }, -- each new hour (1 AM, 2 AM...) on the dawn countdown
	ClockTick = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.35 }, -- PLACEHOLDER: last-minute countdown tick
	Thunder = { Id = "rbxassetid://9120018695", Volume = 0.5 },
	Wind = { Id = "rbxassetid://9114057128", Volume = 0.25, Looped = true },
	Whisper = { Id = "", Volume = 0.6 },
	WindupToy = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 1, Max = 90 },
	LanternLight = { Id = "", Volume = 1, Max = 60 },

	-- Player / UI
	Pickup = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.35 },
	Bank = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6 },
	Heartbeat = { Id = "rbxassetid://9043365842", Volume = 0.8, Looped = true },
	Breath = { Id = "", Volume = 0.7 },
	Gasp = { Id = "", Volume = 0.9 },
	Flashlight = { Id = "rbxasset://sounds/switch.wav", Volume = 0.5 },
	UIClick = { Id = "rbxassetid://9125746460", Volume = 0.45 }, -- soft hollow tap (Pro Sound Effects); swap for a custom UI sound any time
	UIHover = { Id = "", Volume = 0.2 },
	Countdown = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.35 },
	Rooster = { Id = "", Volume = 0.8 }, -- 6 AM
	Victory = { Id = "", Volume = 1 },
	NewArea = { Id = "rbxassetid://1846887425", Volume = 0.6 },
	ChaseStinger = { Id = "rbxassetid://1846887425", Volume = 0.9 }, -- PLACEHOLDER: hit when a chase starts
	CarEngine = { Id = "", Volume = 0.8, Max = 80 },
	CarDoor = { Id = "", Volume = 0.8, Max = 40 },
	Purchase = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6 },
}

-- Images (decals/UI). Empty = UI draws a primitive fallback.
AssetConfig.Images = {
	GrandmaFace = "", -- optional portrait for the alert meter; primitive face is drawn otherwise
	PaperGrain = "", -- optional subtle grain overlay for panels
	Logo = "",
}

return AssetConfig
