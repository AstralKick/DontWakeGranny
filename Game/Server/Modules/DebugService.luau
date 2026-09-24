--!strict
-- DebugService (Studio only)
-- Tiny command channel for testing. In a Studio playtest, set the Workspace attribute
-- "DebugCmd" (e.g. from the command bar on the server) to one of:
--   wake                 Grandma wakes and searches near player 1
--   chase                Grandma chases player 1
--   checkhide            Grandma checks the hiding spot player 1 is in (Hold Your Breath)
--   noise <loudness>     noise at player 1's position
--   endnight             jump the clock to 6 AM
--   power                cut the power for 20s
--   alert <0..100>       set her sleeping alert (tests stirring / waking)
--   hide                 put player 1 in the nearest hiding spot
--   stealall             player 1 grabs + stashes everything on tonight's list
-- Other useful Workspace attributes: DebugStartNight (number), DebugEvent (EventConfig key),
-- DebugNoCatch (bool).  None of this runs outside Studio.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugService = {}

local function svc(name: string): any
	return shared(name)
end

local function run(cmd: string)
	local args = string.split(cmd, " ")
	local p = Players:GetPlayers()[1]
	local root = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local grandma = svc("GrandmaService")
	if args[1] == "wake" and root then
		grandma:DebugWake(root.Position)
	elseif args[1] == "chase" and p then
		grandma:DebugChase(p)
	elseif args[1] == "checkhide" and p then
		local spot = svc("InteractionService"):SpotOf(p)
		if spot then
			grandma:DebugCheckSpot(spot)
		end
	elseif args[1] == "noise" and root then
		svc("NoiseService"):Emit(root.Position, tonumber(args[2]) or 40, 80, p, "Debug")
	elseif args[1] == "endnight" then
		svc("MatchService"):DebugEndNight()
	elseif args[1] == "timeleft" then
		svc("MatchService"):DebugSetTimeLeft(tonumber(args[2]) or 30)
	elseif args[1] == "stealall" and p then
		svc("LootService"):DebugStealList(p)
	elseif args[1] == "hide" and p then
		svc("InteractionService"):DebugHide(p)
	elseif args[1] == "alert" then
		grandma:DebugAlert(tonumber(args[2]) or 50)
	elseif args[1] == "power" then
		svc("EnvironmentService"):CutPower(20)
	end
end

function DebugService.Preload() end

function DebugService:Start()
	if not RunService:IsStudio() then
		return
	end
	workspace:GetAttributeChangedSignal("DebugCmd"):Connect(function()
		local cmd = workspace:GetAttribute("DebugCmd")
		if typeof(cmd) == "string" and cmd ~= "" then
			local ok, err = pcall(run, cmd)
			if not ok then
				warn("[Debug]", err)
			end
			workspace:SetAttribute("DebugCmd", "")
		end
	end)
	local _ = ReplicatedStorage
end

return DebugService
