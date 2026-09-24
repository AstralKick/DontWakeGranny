--!strict
-- Analytics: thin, failure-proof wrapper around AnalyticsService.
-- Onboarding funnel (Creator Dashboard → Analytics → Funnels) measures the first session:
--   1 Lobby · 2 GotInCar · 3 ArrivedAtGrandmas · 4 FirstLoot · 5 FirstStash · 6 SurvivedNight1
-- Each step is logged once per player per server; the dashboard handles de-duplication.

local AnalyticsService = game:GetService("AnalyticsService")

local Analytics = {}

local STEPS = {
	Lobby = 1,
	GotInCar = 2,
	ArrivedAtGrandmas = 3,
	FirstLoot = 4,
	FirstStash = 5,
	SurvivedNight1 = 6,
}

local logged: { [Player]: { [string]: boolean } } = {}

function Analytics.Onboarding(player: Player, step: string)
	local n = STEPS[step]
	if not n then
		return
	end
	logged[player] = logged[player] or {}
	if logged[player][step] then
		return
	end
	logged[player][step] = true
	task.spawn(pcall, AnalyticsService.LogOnboardingFunnelStepEvent, AnalyticsService, player, n, step)
end

-- Custom event (e.g. "NightReached", value = night)
function Analytics.Custom(player: Player, name: string, value: number?)
	task.spawn(pcall, AnalyticsService.LogCustomEvent, AnalyticsService, player, name, value or 1)
end

game:GetService("Players").PlayerRemoving:Connect(function(p)
	logged[p] = nil
end)

return Analytics
