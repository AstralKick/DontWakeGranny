--!strict
-- AchievementConfig
-- ============================================================================
-- DEVELOPER: create a Badge per entry in Creator Dashboard → Badges and paste its
-- ID into BadgeId. BadgeId = 0 -> the achievement still works in-game, no badge is awarded.
-- ============================================================================
-- Stat = which stat is checked (RewardsService), Target = value needed.

return {
	Welcome = { Name = "Welcome to Grandma's", Text = "Play your first night", Stat = "NightsPlayed", Target = 1, Candy = 50, BadgeId = 0 },
	FirstNight = { Name = "She's Just Napping", Text = "Survive Night 1", Stat = "HighestNight", Target = 1, Candy = 100, BadgeId = 0 },
	Night5 = { Name = "Light Sleeper", Text = "Survive Night 5", Stat = "HighestNight", Target = 5, Candy = 250, BadgeId = 0 },
	Night10 = { Name = "Upstairs Regular", Text = "Survive Night 10", Stat = "HighestNight", Target = 10, Candy = 500, BadgeId = 0 },
	Night15 = { Name = "Down the Cellar Stairs", Text = "Survive Night 15", Stat = "HighestNight", Target = 15, Candy = 800, BadgeId = 0 },
	Night20 = { Name = "Attic Dust", Text = "Survive Night 20", Stat = "HighestNight", Target = 20, Candy = 1200, BadgeId = 0 },
	Night25 = { Name = "It Isn't Her Anymore", Text = "Survive Night 25", Stat = "HighestNight", Target = 25, Candy = 1600, BadgeId = 0 },
	Night30 = { Name = "One More Night", Text = "Survive Night 30", Stat = "HighestNight", Target = 30, Candy = 2000, BadgeId = 0 },
	Halloween = { Name = "HAPPY HALLOWEEN", Text = "Survive all 31 nights", Stat = "Wins", Target = 1, Candy = 0, BadgeId = 0,
		Cosmetics = { { "Flashlight", "Pumpkin" }, { "Sack", "Halloween" } } },
	Caught = { Name = "Big Hug", Text = "Get caught by Grandma", Stat = "TimesCaught", Target = 1, Candy = 25, BadgeId = 0 },
	Thief = { Name = "Sticky Fingers", Text = "Steal 100 items", Stat = "LootStolen", Target = 100, Candy = 300, BadgeId = 0 },
	Hoarder = { Name = "Candy Hoarder", Text = "Bank 10,000 Candy total", Stat = "TotalCandy", Target = 10000, Candy = 500, BadgeId = 0 },
	Breathless = { Name = "Breathless", Text = "Hold your breath 10 times", Stat = "BreathsHeld", Target = 10, Candy = 300, BadgeId = 0 },
	Escapist = { Name = "Not Today, Grandma", Text = "Escape 25 chases", Stat = "ChasesEscaped", Target = 25, Candy = 400, BadgeId = 0 },
	Historian = { Name = "Family History", Text = "Find every diary page", Stat = "DiaryPages", Target = 12, Candy = 1000, BadgeId = 0 },
	Pals = { Name = "Sleepover", Text = "Play a night with a friend", Stat = "FriendNights", Target = 1, Candy = 100, BadgeId = 0 },
}
