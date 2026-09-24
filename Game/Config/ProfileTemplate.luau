-- ProfileTemplate (VIDK SMProfile)
-- Default profile data. SMProfile passes this to ProfileStore.New, and ProfileStore's
-- Reconcile() fills any missing keys in existing profiles on load.
-- DEVELOPER: add new persistent fields here. Candy is SMCurrency "SoftCurrency" (not here).

return {
	TotalCandy = 0, -- lifetime earned (achievements / referral checks)
	HighestNight = 0, -- highest night survived
	Wins = 0,
	Upgrades = { Pillowcase = 0, SoftSocks = 0, StrongLungs = 0, Batteries = 0 },
	Items = { WindupToy = 1, Cookie = 1, FizzySoda = 1 },
	Cosmetics = {
		Owned = { Flashlight = { Warm = true }, Sack = { Plain = true } },
		Equipped = { Flashlight = "Warm", Sack = "Plain" },
	},
	Stats = {
		NightsPlayed = 0, NightsSurvived = 0, TimesCaught = 0, LootStolen = 0,
		BiggestHaul = 0, BreathsHeld = 0, ChasesEscaped = 0, DiaryPages = 0, FriendNights = 0,
		ContainersSearched = 0, ItemsUsed = 0, PrizesBanked = 0, Hides = 0,
	},
	Diary = {}, -- [pageIndex as string] = true
	Achievements = {}, -- [id] = true
	Daily = { LastClaimDay = 0, Streak = 0 },
	Quests = { Day = 0, List = {} }, -- List = { {Id, Target, Reward, Progress, Claimed} }
	Social = { Referred = false, LastBuddyDay = 0, InvitesRewarded = 0 },
	Tutorial = { UsedFreeRevive = false, SeenIntro = false, FirstNightDone = false },
	Settings = { Music = 0.7, SFX = 1, ReduceFlashes = false, Sensitivity = 1 },
	Passes = {}, -- [passKey] = true (cached ownership, also re-checked on join)
	Grants = {}, -- one-time grants already delivered, e.g. StarterPack = true
	Tokens = { Revive = 0 }, -- paid-for but unusable purchases are stored here, never lost
	ProcessedReceipts = {}, -- [purchaseId] = os.time()  (de-dupe, trimmed)
}
