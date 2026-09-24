--!strict
-- GrandmaService (Match)
-- Grandma's brain. A state machine ticking at GrandmaConfig.AI.TickRate.
--
--   Asleep ──noise──> Stirring ──more noise──> Waking ──> Searching <──> Chasing ──> Attacking
--      ^                 │ (quiet)                          │  ^            │
--      └─────────────────┘                                  v  │            v
--   Returning <──────────── search timer ends ─────────── CheckingHiding / Stalking / Distracted
--
-- Late-game additions: FakeSleep (eyes open, snoring stops), Teleports, CutsPower, Stalks,
-- ChecksHiding + LearnsHiding. All gated by NightConfig.Abilities.
--
-- Replication: model attributes State, Say (voice line "text|id"), Target (userId),
-- MatchState.GrandmaState / Alert. Clients animate her locally from State.
-- The rig is loaded through GrandmaRig and never referenced beyond Humanoid/Root/Head.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlaceRole = shared("PlaceRole")
local GrandmaConfig = shared("GrandmaConfig")
local DataService = shared("DataService")
local Sfx = shared("Sfx")
local GrandmaRig = shared("GrandmaRig")
local Perception = shared("Perception")
local Mover = shared("Mover")

local function svc(name: string): any
	return shared(name)
end

local AI = GrandmaConfig.AI

local GrandmaService = {}

local rig: any = nil
local mover: any = nil
local snore: Sound? = nil

local state = "Asleep"
local stateSince = 0
local alert = 0
local cfg: any = nil
local nightStartClock = 0

local target: Player? = nil
local lastSeenPos: Vector3? = nil
local lastSeenAt = 0
local chasedThisChase: { [Player]: boolean } = {}
local investigatePos: Vector3? = nil
local investigateLoud = 0
local investigateAt = 0
local lastHeardAt = 0
local searchUntil = 0
local searchCenter: Vector3? = nil
local lookUntil = 0
local attackUntil = 0
local wakeUntil = 0
local stirUntil = 0
local distractPos: Vector3? = nil
local distractUntil = 0
local checkSpot: any = nil
local checkPhase = 0 -- 0 walking, 1 checking
local checkUntil = 0
local stalkUntil = 0
local stalkPos: Vector3? = nil
local lastPowerCut = -999
local bathroomDone = false
local fakeSleeping = false
local lastSayAt = 0
local sayId = 0
local lastFootstep = 0
local sawEnter: { [Player]: any } = {}
local spotUsage: { [any]: number } = {}
-- Camping (AI.CampLimit): seconds each player has spent hidden, and who she's coming for.
local campTime: { [Player]: number } = {}
local campTarget: Player? = nil

local sleepSpot: CFrame = CFrame.new(0, 3, 0)
local searchNodes: { BasePart } = {}

-- ------------------------------------------------------------------ utils

local function now(): number
	return os.clock()
end

local function matchState(key: string, value: any)
	local ms = ReplicatedStorage:FindFirstChild("MatchState")
	if ms then
		ms:SetAttribute(key, value)
	end
end

local function say(category: string, force: boolean?)
	if not rig then
		return
	end
	if not force and now() - lastSayAt < 3 then
		return
	end
	local lines = GrandmaConfig.VoiceLines[category]
	local tier = cfg and cfg.VoiceTier or 1
	local list = lines and (lines[tier] or lines[1])
	if not list or #list == 0 then
		return
	end
	lastSayAt = now()
	sayId += 1
	local line = list[math.random(1, #list)]
	rig.Model:SetAttribute("Say", `{line}|{sayId}`)
	local key = "Voice_" .. category
	if Sfx.Has(key) then
		Sfx.Play(key, rig.Head)
	elseif Sfx.Has("Voice_Generic") then
		Sfx.Play("Voice_Generic", rig.Head)
	end
end

local function setState(s: string)
	if state == s and rig and rig.Model:GetAttribute("State") == s then
		return
	end
	if rig and s ~= "CheckingHiding" then
		rig.Humanoid.AutoRotate = true
	end
	state = s
	stateSince = now()
	if rig then
		rig.Model:SetAttribute("State", s)
		local anchored = (s == "Asleep" or s == "FakeSleep" or s == "Stirring")
		rig.Root.Anchored = anchored
		if snore then
			if s == "Asleep" then
				if not snore.IsPlaying then
					snore:Play()
				end
			else
				snore:Stop()
			end
		end
	end
	matchState("GrandmaState", s)
end

local function speedFor(s: string): number
	if not cfg then
		return 8
	end
	local party = svc("MatchService"):PartyScale()
	local mult = (party and party.Speed or 1) * svc("EventService"):SpeedMult() * (rig and rig.SpeedMult or 1)
	if s == "Chasing" then
		return cfg.ChaseSpeed * mult
	elseif s == "Searching" or s == "Distracted" then
		return cfg.SearchSpeed * mult
	elseif s == "Waking" or s == "Asleep" or s == "Stirring" or s == "FakeSleep" or s == "Attacking" or s == "Stalking" then
		return 0
	end
	return cfg.WalkSpeed * mult
end

local function hearingMult(): number
	local party = svc("MatchService"):PartyScale()
	return (cfg and cfg.Hearing or 1) * (party and party.Hearing or 1) * svc("EventService"):HearingMult()
end

local function areaUnlocked(area: string?): boolean
	if not area or not cfg then
		return true
	end
	return cfg.Areas[area] == true
end

local function nodesNear(center: Vector3, radius: number): { BasePart }
	local out = {}
	for _, n in searchNodes do
		if areaUnlocked(n:GetAttribute("Area")) and (n.Position - center).Magnitude <= radius then
			table.insert(out, n)
		end
	end
	return out
end

local function randomNode(): BasePart?
	local pool = {}
	for _, n in searchNodes do
		if areaUnlocked(n:GetAttribute("Area")) then
			table.insert(pool, n)
		end
	end
	return if #pool > 0 then pool[math.random(1, #pool)] else nil
end

local function charOf(p: Player): (Model?, BasePart?)
	local c = p.Character
	local root = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
	return c, root
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function faceTowards(pos: Vector3)
	if not rig then
		return
	end
	local root = rig.Root
	local dir = flat(pos - root.Position)
	if dir.Magnitude > 0.1 then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
	end
end

-- ------------------------------------------------------------------ perception

local function visionRangeFor(p: Player): number
	local r = cfg.VisionRange
	local ps = svc("PlayerStateService")
	if ps:IsCrouching(p) then
		r *= AI.CrouchVisionMult
	end
	if cfg.Abilities.ReactsToLights and ps:IsFlashlightOn(p) then
		r *= AI.FlashlightVisionMult
	end
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and not ps:IsFlashlightOn(p) and not svc("EnvironmentService"):IsLitAt(root.Position) then
		r *= 0.7 -- dark room: harder to spot you, unless you light yourself up
	end
	return r
end

local function canSee(p: Player, rangeMult: number?): boolean
	if not rig or p:GetAttribute("Hidden") or svc("PlayerStateService"):IsProtected(p) then
		return false
	end
	if not svc("MatchService"):IsAlive(p) then
		return false
	end
	local c, root = charOf(p)
	if not c or not root then
		return false
	end
	local range = visionRangeFor(p) * (rangeMult or 1)
	local eye = rig.Head.Position
	-- Close sense: very near + not crouching = she notices even behind her.
	local dist = (root.Position - rig.Root.Position).Magnitude
	if dist < AI.CloseSenseRange and not svc("PlayerStateService"):IsCrouching(p) then
		return Perception.Clear(eye, root.Position)
	end
	return Perception.CanSee(eye, rig.Root.CFrame.LookVector, c, range, cfg.FOV)
end

local function findVisible(rangeMult: number?): Player?
	local best: Player? = nil
	local bestDist = math.huge
	for _, p in svc("MatchService"):GetAlivePlayers() do
		if canSee(p, rangeMult) then
			local _, root = charOf(p)
			local d = (root :: BasePart).Position - rig.Root.Position
			if d.Magnitude < bestDist then
				best, bestDist = p, d.Magnitude
			end
		end
	end
	return best
end

-- ------------------------------------------------------------------ transitions

local function startSearch(center: Vector3?, duration: number?)
	searchCenter = center or rig.Root.Position
	searchUntil = now() + (duration or cfg.SearchDuration)
	investigatePos = center
	lookUntil = 0
	setState("Searching")
	if investigatePos then
		mover:SetGoal(investigatePos)
	end
end

local function startChase(p: Player)
	if state ~= "Chasing" then
		say("Chasing", true)
		Sfx.Play("GrandmaChaseScream", rig.Head)
		table.clear(chasedThisChase)
	end
	target = p
	chasedThisChase[p] = true
	local _, root = charOf(p)
	lastSeenPos = root and root.Position
	lastSeenAt = now()
	rig.Model:SetAttribute("Target", p.UserId)
	setState("Chasing")
end

local function endChaseEscaped()
	-- Everyone she was chasing got away: that's a clip moment + quest progress.
	for p in chasedThisChase do
		if p.Parent == Players and svc("MatchService"):IsAlive(p) then
			DataService:IncStat(p, "ChasesEscaped")
			svc("RewardsService"):QuestProgress(p, "EscapeChase", 1)
		end
	end
	table.clear(chasedThisChase)
	target = nil
	rig.Model:SetAttribute("Target", 0)
end

local function goToSleep()
	setState("Returning")
	mover:SetGoal(sleepSpot.Position)
end

local function sitDown()
	rig.Root.Anchored = true
	rig.Model:PivotTo(sleepSpot)
	mover:Stop()
	alert = cfg and math.min(AI.WakeNoiseFloor, cfg.StirThreshold * 0.5) or 0
	if cfg and cfg.Abilities.FakeSleep and math.random() < AI.FakeSleepChance then
		fakeSleeping = true
		setState("FakeSleep")
	else
		fakeSleeping = false
		setState("Asleep")
	end
end

local function wake(towards: Vector3?)
	investigatePos = towards or investigatePos
	wakeUntil = now() + AI.WakeDuration
	Sfx.Play("GrandmaWake", rig.Head)
	say("Stirring", true)
	setState("Waking")
end

local function catchTarget(p: Player)
	-- Studio testing aid: set workspace attribute DebugNoCatch = true to observe chases safely.
	if game:GetService("RunService"):IsStudio() and workspace:GetAttribute("DebugNoCatch") then
		return
	end
	setState("Attacking")
	attackUntil = now() + AI.AttackPause
	mover:Stop()
	local _, root = charOf(p)
	if root then
		faceTowards(root.Position)
	end
	svc("InteractionService"):PullOut(p)
	svc("MatchService"):CatchPlayer(p, "Grandma")
	say("Caught", true)
	table.clear(chasedThisChase)
	target = nil
	rig.Model:SetAttribute("Target", 0)
end

-- ------------------------------------------------------------------ hiding

local function tryHidingCheck(): boolean
	if not cfg.Abilities.ChecksHiding then
		return false
	end
	local spots = svc("InteractionService"):GetHidingSpots()
	local best, bestScore = nil, 0
	for _, spot in spots do
		if areaUnlocked(spot.Area) then
			local d = (spot.Front.Position - rig.Root.Position).Magnitude
			if d < 28 then
				local chance = cfg.HidingCheckChance
				if cfg.Abilities.LearnsHiding then
					chance += math.min(0.3, (spotUsage[spot] or 0) * 0.08)
				end
				local score = chance * (1 - d / 40)
				if score > bestScore and math.random() < chance then
					best, bestScore = spot, score
				end
			end
		end
	end
	if best then
		checkSpot = best
		checkPhase = 0
		setState("CheckingHiding")
		mover:SetGoal(best.Front.Position)
		return true
	end
	return false
end

-- ------------------------------------------------------------------ camping
-- Hide too long and she comes to get you. Player attributes for the UI:
--   HideHeat 0..1 (how close you are to the limit), Hunted (she's on her way to YOUR spot).

local function campLimit(): number
	-- Studio: workspace attribute DebugCampLimit = seconds overrides it for testing.
	local dbg = game:GetService("RunService"):IsStudio() and workspace:GetAttribute("DebugCampLimit")
	if typeof(dbg) == "number" and dbg > 0 then
		return dbg
	end
	local night = (cfg and cfg.Night) or 1
	local k = math.clamp((night - 1) / 29, 0, 1)
	local lim = AI.CampLimit or { 75, 30 }
	return lim[1] + (lim[2] - lim[1]) * k
end

local function endCamp(found: boolean?)
	local p = campTarget
	campTarget = nil
	if p then
		p:SetAttribute("Hunted", false)
		-- She came and went: the timer drops a lot, but not to zero (don't just hop back in).
		campTime[p] = math.min(campTime[p] or 0, campLimit() * (AI.CampAfterCheck or 0.35))
		if found == false then
			campTime[p] = 0
		end
	end
end

local function campTick(dt: number)
	local limit = campLimit()
	local match = svc("MatchService")
	local interaction = svc("InteractionService")
	local worst: Player?, worstTime = nil, 0
	for _, p in match:GetAlivePlayers() do
		local tNow = campTime[p] or 0
		if p:GetAttribute("Hidden") then
			tNow += dt
		else
			tNow = math.max(0, tNow - dt * (AI.CampDecay or 2))
		end
		campTime[p] = tNow
		local heat = math.clamp(tNow / limit, 0, 1)
		local shown = p:GetAttribute("HideHeat") or 0
		if math.abs(heat - shown) >= 0.02 or (heat == 0 and shown ~= 0) or (heat == 1 and shown ~= 1) then
			p:SetAttribute("HideHeat", math.floor(heat * 100 + 0.5) / 100)
		end
		if p:GetAttribute("Hidden") and tNow >= limit and tNow > worstTime then
			worst, worstTime = p, tNow
		end
	end

	-- She was coming for someone and got pulled away (a chase, a distraction...): let it go.
	if campTarget and state ~= "CheckingHiding" then
		endCamp()
	end
	if campTarget or not worst then
		return
	end
	-- Busy with something more urgent.
	if state == "Chasing" or state == "Attacking" or (state == "CheckingHiding" and checkPhase == 1) then
		return
	end
	local spot = interaction:SpotOf(worst)
	if not spot then
		return
	end
	campTarget = worst
	worst:SetAttribute("Hunted", true)
	local wasAsleep = state == "Asleep" or state == "FakeSleep" or state == "Stirring"
	rig.Root.Anchored = false
	fakeSleeping = false
	if wasAsleep then
		Sfx.Play("GrandmaWake", rig.Head)
	end
	checkSpot = spot
	checkPhase = 0
	setState("CheckingHiding")
	mover:SetGoal(spot.Front.Position)
	say("Camping", true)
end

-- Called by InteractionService when a player enters a hiding spot.
function GrandmaService:OnPlayerHid(p: Player, spot: any)
	spotUsage[spot] = (spotUsage[spot] or 0) + 1
	if not rig then
		return
	end
	-- Did she see them get in?
	local c, root = charOf(p)
	local seen = false
	if c and root and (state == "Chasing" or state == "Searching" or state == "Stalking") then
		local eye = rig.Head.Position
		seen = Perception.CanSee(eye, rig.Root.CFrame.LookVector, c, cfg.VisionRange, cfg.FOV + 20)
			or (state == "Chasing" and target == p and now() - lastSeenAt < 0.6)
	end
	sawEnter[p] = if seen then spot else nil
	if seen then
		checkSpot = spot
		checkPhase = 0
		setState("CheckingHiding")
		mover:SetGoal(spot.Front.Position)
		say("HidingCheck", true)
	end
end

function GrandmaService:OnPlayerUnhid(p: Player)
	sawEnter[p] = nil
end

-- ------------------------------------------------------------------ noise

function GrandmaService:HearNoise(pos: Vector3, loudness: number, radius: number, source: Player?, kind: string?)
	if not rig or not cfg or svc("MatchService"):GetPhase() ~= "Night" then
		return
	end
	local d = (pos - rig.Head.Position).Magnitude
	if d > radius then
		return
	end
	local eff = loudness * (1 - d / radius) * hearingMult()
	-- Right next to her, everything counts extra (you're breathing on her).
	if d < 9 then
		eff *= 1 + (1 - d / 9) * 0.8
	end
	if kind == "Door" and not cfg.Abilities.HearsDoors then
		eff *= 0.75 -- before Night 6 doors are a little quieter to her, but never ignored
	end
	if kind ~= "Lurking" and d > 8 and not Perception.Clear(pos + Vector3.new(0, 1.5, 0), rig.Head.Position) then
		eff *= 0.6 -- through walls
	end
	if eff < 0.3 then
		return
	end

	-- Track the loudest recent noise as where to look.
	if eff >= investigateLoud * 0.7 or now() - investigateAt > 3 then
		investigatePos = pos
		investigateLoud = eff
		investigateAt = now()
	end

	if eff >= 1 then
		lastHeardAt = now()
	end
	if state == "Asleep" then
		alert += eff
		-- She reacts in her sleep to anything that registers (a mumble / snort), so players
		-- feel that she heard them before she actually stirs.
		if eff >= 4 and now() - lastSayAt > 5 then
			say("Asleep", true)
			if eff >= 9 then
				Sfx.Play("GrandmaStir", rig.Head, { Volume = 0.5 })
			end
		end
	elseif state == "Stirring" then
		alert += eff * AI.StirNoiseMult
	elseif state == "FakeSleep" then
		if eff > 8 then
			say("Searching", true)
			startSearch(pos, cfg.SearchDuration * 1.2)
		end
	elseif state == "Searching" or state == "Returning" or state == "Stalking" or state == "Patrolling" then
		if eff >= AI.NoiseInvestigateMin then
			startSearch(pos, math.max(searchUntil - now(), cfg.SearchDuration * 0.6))
		end
	elseif state == "CheckingHiding" and eff >= AI.NoiseInvestigateMin * 2 then
		startSearch(pos)
	end
	alert = math.clamp(alert, 0, 100)
end

-- ------------------------------------------------------------------ distractions

function GrandmaService:Distract(pos: Vector3, seconds: number): boolean
	if not rig or state == "Asleep" or state == "FakeSleep" or state == "Stirring" or state == "Attacking" then
		return false
	end
	distractPos = pos
	distractUntil = 0
	setState("Distracted")
	mover:SetGoal(pos)
	rig.Model:SetAttribute("DistractTime", seconds)
	if target then
		endChaseEscaped()
	end
	return true
end

-- ------------------------------------------------------------------ tick

local function tick(dt: number)
	local match = svc("MatchService")
	if match:GetPhase() ~= "Night" or not rig then
		return
	end
	local t = now()

	-- Shared awake behaviour: spotting players
	local awake = state ~= "Asleep" and state ~= "Stirring" and state ~= "FakeSleep" and state ~= "Waking" and state ~= "Attacking" and state ~= "Distracted"
	if awake and state ~= "Chasing" then
		local seen = findVisible()
		if seen then
			startChase(seen)
		end
	end

	-- Footsteps & speed
	rig.Humanoid.WalkSpeed = speedFor(state)
	if rig.Humanoid.MoveDirection.Magnitude > 0.1 and t - lastFootstep > (if state == "Chasing" then 0.3 else 0.55) then
		lastFootstep = t
		Sfx.Play("GrandmaFootstep", rig.Root, { PlaybackSpeed = 0.85 + math.random() * 0.2 })
	end

	-- Camping in a hiding spot too long brings her straight to it.
	campTick(dt)

	if state == "Asleep" then
		-- She keeps listening for a moment after each noise before settling back down, so a
		-- door + a pickup + a footstep in a row genuinely add up.
		if now() - lastHeardAt > 2.5 then
			alert = math.max(0, alert - cfg.AlertDecay * dt)
		end
		if t - lastSayAt > 18 then
			say("Asleep")
		end
		-- Night 1/2: she gets up for the bathroom so everyone meets her early.
		if cfg.BathroomBreak and not bathroomDone and t - nightStartClock > AI.BathroomBreakAt then
			bathroomDone = true
			local node = nil
			for _, n in searchNodes do
				if n:GetAttribute("Bathroom") then
					node = n
				end
			end
			rig.Model:SetAttribute("Say", `Ooh, my bladder...|{sayId + 1}`)
			sayId += 1
			wakeUntil = t + AI.WakeDuration
			investigatePos = node and node.Position or nil
			setState("Waking")
			return
		end
		if alert >= cfg.StirThreshold then
			stirUntil = t + AI.StirDuration
			Sfx.Play("GrandmaStir", rig.Head)
			say("Stirring", true)
			setState("Stirring")
		end
	elseif state == "FakeSleep" then
		-- Eyes open behind the glasses. Get too close in front of her and she lunges.
		local seen = findVisible(0.3)
		if seen then
			local _, root = charOf(seen)
			if root and (root.Position - rig.Root.Position).Magnitude < 16 then
				rig.Root.Anchored = false
				startChase(seen)
				return
			end
		end
		if t - stateSince > 28 then
			setState("Asleep")
		end
	elseif state == "Stirring" then
		alert = math.max(0, alert - cfg.AlertDecay * 0.5 * dt)
		-- Half-awake: she looks around a little.
		local seen = findVisible(0.35)
		if seen then
			rig.Root.Anchored = false
			wake(nil)
			return
		end
		-- "Almost" must resolve: she wakes a little before the ring is visually full, and if
		-- she keeps stirring (you never let it drop back below the stir line) she gets up anyway.
		if alert >= (AI.WakeAt or 88) then
			wake(investigatePos)
		elseif t > stirUntil then
			if alert < cfg.StirThreshold then
				say("Lost")
				setState("Asleep")
			elseif t - stateSince > (AI.MaxStirTime or 11) then
				rig.Root.Anchored = false
				wake(investigatePos)
			else
				stirUntil = t + 2
			end
		end
	elseif state == "Waking" then
		alert = 100
		if t > wakeUntil then
			rig.Root.Anchored = false
			-- The scripted bathroom trip is a short wander, not a full search.
			local trip = cfg.BathroomBreak and bathroomDone and t - nightStartClock < AI.BathroomBreakAt + AI.WakeDuration + 1
			startSearch(investigatePos, if trip then 14 else nil)
		end
	elseif state == "Searching" or state == "Patrolling" then
		alert = 100
		if t > searchUntil and not cfg.Abilities.NeverSleeps then
			say("Lost")
			goToSleep()
			return
		end
		if mover:Arrived() then
			if lookUntil == 0 then
				lookUntil = t + AI.LookAroundTime
				mover:Stop()
				if math.random() < 0.35 then
					say("Searching")
				end
			elseif t > lookUntil then
				lookUntil = 0
				if tryHidingCheck() then
					return
				end
				-- Teleport trick (late nights): pop up somewhere nobody is looking.
				if cfg.Abilities.Teleports and math.random() < AI.TeleportChance then
					local node = randomNode()
					if node and GrandmaService:_unobserved(node.Position) then
						rig.Root.CFrame = CFrame.new(node.Position + Vector3.new(0, 3, 0))
						Sfx.Play("Whisper", node.Position)
						searchCenter = node.Position
					end
				end
				local center = searchCenter or rig.Root.Position
				local pool = nodesNear(center, 45)
				local node = if #pool > 0 then pool[math.random(1, #pool)] else randomNode()
				if node then
					mover:SetGoal(node.Position)
				end
			end
		else
			-- slowly scan while walking
		end
	elseif state == "Chasing" then
		alert = 100
		local p = target
		local root: BasePart? = nil
		if p then
			local _c
			_c, root = charOf(p)
		end
		if not p or not root or not match:IsAlive(p) then
			local other = findVisible()
			if other then
				startChase(other)
			else
				startSearch(lastSeenPos)
			end
			return
		end
		if p:GetAttribute("Hidden") then
			local spot = sawEnter[p]
			if spot then
				checkSpot = spot
				checkPhase = 0
				setState("CheckingHiding")
				mover:SetGoal(spot.Front.Position)
				return
			end
			-- Lost them into a hiding spot she didn't see.
			say("Lost", true)
			endChaseEscaped()
			if cfg.Abilities.Stalks then
				stalkPos = lastSeenPos
				stalkUntil = t + AI.StalkTime
				setState("Stalking")
				mover:Stop()
			else
				startSearch(lastSeenPos)
			end
			return
		end
		local visible = canSee(p, 1.2)
		if visible then
			lastSeenPos = root.Position
			lastSeenAt = t
		end
		local dist = (root.Position - rig.Root.Position).Magnitude
		local party = match:PartyScale()
		local catchRange = cfg.CatchRange - (party and party.CatchGrace or 0)
		if dist <= catchRange and math.abs(root.Position.Y - rig.Root.Position.Y) < 4.5 and Perception.Clear(rig.Root.Position, root.Position) and not svc("PlayerStateService"):IsProtected(p) then
			catchTarget(p)
			return
		end
		-- Switch to a closer visible player
		local other = findVisible()
		if other and other ~= p then
			local _, oroot = charOf(other)
			if oroot and (oroot.Position - rig.Root.Position).Magnitude < dist * 0.6 then
				startChase(other)
				return
			end
		end
		if visible and dist < 30 then
			mover:SetDirect(root.Position)
		elseif lastSeenPos then
			mover:SetGoal(lastSeenPos)
		end
		if t - lastSeenAt > cfg.LoseSightTime then
			say("Lost", true)
			endChaseEscaped()
			if cfg.Abilities.CutsPower and t - lastPowerCut > AI.PowerCutCooldown then
				lastPowerCut = t
				rig.Model:SetAttribute("Say", `Lights out, dearies.|{sayId + 1}`)
				sayId += 1
				svc("EnvironmentService"):CutPower(22)
			end
			startSearch(lastSeenPos)
		end
	elseif state == "Attacking" then
		if t > attackUntil then
			local other = findVisible()
			if other then
				startChase(other)
			else
				startSearch(rig.Root.Position, cfg.SearchDuration * 0.7)
			end
		end
	elseif state == "CheckingHiding" then
		local spot = checkSpot
		if not spot then
			startSearch(rig.Root.Position)
			return
		end
		if checkPhase == 0 then
			if mover:Arrived() or (spot.Front.Position - rig.Root.Position).Magnitude < 3.5 then
				checkPhase = 1
				mover:Stop()
				rig.Humanoid.AutoRotate = false -- keep staring at the door while she checks
				faceTowards(spot.Inside.Position)
				rig.Model:SetAttribute("Checking", true)
				checkUntil = t + AI.HoldBreathTime + 0.4
				local occupant = spot.Occupant
				if campTarget then
					-- She came for a camper: still in there = yanked out, no breath save.
					local camper = campTarget
					if occupant == camper then
						endCamp(true)
						catchTarget(camper)
						rig.Model:SetAttribute("Checking", false)
						return
					end
					endCamp(false)
				end
				if occupant then
					if sawEnter[occupant] == spot then
						catchTarget(occupant)
						rig.Model:SetAttribute("Checking", false)
						return
					end
					svc("InteractionService"):BeginHoldBreath(occupant, AI.HoldBreathTime, function(success: boolean)
						if not success and occupant.Parent and svc("MatchService"):IsAlive(occupant) and occupant:GetAttribute("Hidden") then
							catchTarget(occupant)
						elseif success then
							DataService:IncStat(occupant, "BreathsHeld")
							svc("RewardsService"):QuestProgress(occupant, "HoldBreath", 1)
						end
					end)
				end
				say("HidingCheck", true)
			elseif t - stateSince > 30 then -- couldn't reach it (blocked path); give up
				startSearch(rig.Root.Position)
			end
		elseif checkPhase == 1 and t > checkUntil then
			rig.Humanoid.AutoRotate = true
			rig.Model:SetAttribute("Checking", false)
			checkSpot = nil
			if state == "CheckingHiding" then
				startSearch(rig.Root.Position, math.max(6, searchUntil - t))
			end
		end
	elseif state == "Stalking" then
		-- Pretends to leave, then waits just outside. Players who pop out too early get chased.
		if t > stalkUntil then
			startSearch(stalkPos)
		end
	elseif state == "Distracted" then
		if distractPos then
			if distractUntil == 0 then
				if mover:Arrived() or (flat(distractPos - rig.Root.Position)).Magnitude < 4 then
					mover:Stop()
					distractUntil = t + (rig.Model:GetAttribute("DistractTime") or 6)
					rig.Model:SetAttribute("Say", `Ooh... a cookie!|{sayId + 1}`)
					sayId += 1
				end
			elseif t > distractUntil then
				distractPos = nil
				startSearch(rig.Root.Position, cfg.SearchDuration * 0.5)
			end
		else
			startSearch(rig.Root.Position)
		end
	elseif state == "Returning" then
		alert = math.max(0, alert - 20 * dt)
		if mover:Arrived() or (flat(sleepSpot.Position - rig.Root.Position)).Magnitude < 3.5 then
			sitDown()
		end
	end

	mover:Step()
	-- Scaled so the HUD ring is full exactly when she gets up (AI.WakeAt).
	matchState("Alert", math.floor(if state == "Asleep" or state == "Stirring" or state == "FakeSleep" then math.min(100, alert / (AI.WakeAt or 88) * 100) else 100))
end

-- True if no alive player can see this spot (so a teleport isn't witnessed).
function GrandmaService:_unobserved(pos: Vector3): boolean
	for _, p in svc("MatchService"):GetAlivePlayers() do
		local c = p.Character
		local head = c and c:FindFirstChild("Head") :: BasePart?
		if head then
			if (head.Position - pos).Magnitude < 30 then
				return false
			end
			if Perception.Clear(head.Position, pos + Vector3.new(0, 3, 0)) then
				return false
			end
		end
	end
	return true
end

-- ------------------------------------------------------------------ debug (Studio: DebugService)

function GrandmaService:DebugWake(pos: Vector3)
	if rig then
		rig.Root.Anchored = false
		wake(pos)
	end
end

function GrandmaService:DebugAlert(value: number)
	if rig and (state == "Asleep" or state == "Stirring") then
		alert = math.clamp(value, 0, 100)
		lastHeardAt = now()
	end
end

function GrandmaService:DebugChase(p: Player)
	if rig then
		rig.Root.Anchored = false
		startChase(p)
	end
end

function GrandmaService:DebugCheckSpot(spot: any)
	if rig then
		rig.Root.Anchored = false
		checkSpot = spot
		checkPhase = 0
		setState("CheckingHiding")
		mover:SetGoal(spot.Front.Position)
	end
end

-- ------------------------------------------------------------------ night hooks

function GrandmaService:GetState(): string
	return state
end

function GrandmaService:GetModel(): Model?
	return rig and rig.Model
end

-- (Re)spawns Grandma from a rig template. Used at start and when a different Granny is picked.
local runPicked = false
function GrandmaService:_spawnRig(template: Model?): boolean
	if rig and rig.Model then
		rig.Model:Destroy()
	end
	if snore then
		snore:Destroy()
		snore = nil
	end
	local ok, err = pcall(function()
		rig = GrandmaRig.Load(workspace, template)
	end)
	if not ok then
		warn(err)
		rig = nil
		return false
	end
	mover = Mover.new(rig.Humanoid, rig.Root, GrandmaConfig.Agent)
	mover.DoorHook = function(from: Vector3, to: Vector3): number
		return svc("InteractionService"):DoorHook(from, to)
	end
	snore = Sfx.Loop("Snore", rig.Head)
	sitDown()
	return true
end

function GrandmaService:ResetForNight(night: number, nightCfg: any)
	cfg = nightCfg
	-- Which Granny tonight? Picked once per run (default) or every night.
	if not runPicked or GrandmaConfig.RigSelection == "PerNight" then
		runPicked = true
		local pick = GrandmaRig.Pick(night, if GrandmaConfig.RigSelection == "PerNight" and rig then rig.Template else nil)
		if pick and (not rig or rig.Template ~= pick) then
			GrandmaService:_spawnRig(pick)
		end
	end
	if not rig then
		return
	end
	-- New night, new outfit (never the same twice in a row).
	-- Themed rigs (Maps-specific Grannies) can opt out with the NoOutfits attribute.
	if not (rig.Template and rig.Template:GetAttribute("NoOutfits") == true) then
		local outfit = GrandmaRig.PickOutfit(night, rig.Model:GetAttribute("Outfit"))
		GrandmaRig.ApplyOutfit(rig, outfit)
	end
	GrandmaRig.ApplyForm(rig, nightCfg.Form)
	bathroomDone = false
	target = nil
	table.clear(sawEnter)
	endCamp()
	table.clear(campTime)
	for _, p in Players:GetPlayers() do
		p:SetAttribute("HideHeat", 0)
		p:SetAttribute("Hunted", false)
	end
	table.clear(chasedThisChase)
	checkSpot = nil
	distractPos = nil
	investigatePos = nil
	investigateLoud = 0
	rig.Model:SetAttribute("Target", 0)
	rig.Model:SetAttribute("Checking", false)
	sitDown()
	-- Every night starts with a genuinely sleeping Grandma (fake sleep comes later).
	fakeSleeping = false
	setState("Asleep")
	alert = 0
	matchState("Alert", 0)
end

local function onNightStarted()
	nightStartClock = now()
	if not rig or not cfg then
		return
	end
	if cfg.Abilities.NeverSleeps or svc("EventService"):Has("StartAwake") then
		rig.Root.Anchored = false
		local node = randomNode()
		wake(node and node.Position or nil)
		if cfg.Abilities.NeverSleeps then
			rig.Model:SetAttribute("Say", `TRICK OR TREAT, DEARIES!|{sayId + 1}`)
			sayId += 1
		end
	end
end

function GrandmaService:EnterMorning()
	if not rig then
		return
	end
	target = nil
	rig.Model:SetAttribute("Target", 0)
	rig.Model:SetAttribute("Checking", false)
	fakeSleeping = false
	rig.Root.Anchored = true
	rig.Model:PivotTo(sleepSpot)
	mover:Stop()
	setState("Asleep")
	alert = 0
	matchState("Alert", 0)
end

-- ------------------------------------------------------------------ lifecycle

function GrandmaService.Preload() end

function GrandmaService:Start()
	if not PlaceRole.IsMatch then
		return
	end
	local house = workspace:WaitForChild("House", 20)
	if not house then
		warn("[Grandma] Workspace.House missing")
		return
	end
	local function bindMap(h: Instance)
		local spot = h:FindFirstChild("GrandmaSleepSpot") :: BasePart?
		if spot then
			sleepSpot = spot.CFrame
		end
		table.clear(searchNodes)
		table.clear(spotUsage)
		local nodes = h:FindFirstChild("SearchNodes")
		if nodes then
			for _, n in nodes:GetChildren() do
				if n:IsA("BasePart") then
					table.insert(searchNodes, n)
				end
			end
		end
	end
	bindMap(house)
	shared("MapService"):OnChanged(function(h)
		bindMap(h)
		-- New chapter: maybe a new (map-themed) Granny; ResetForNight re-picks.
		runPicked = false
		-- Park her in her new chair right away (ResetForNight follows).
		if rig then
			rig.Model:PivotTo(sleepSpot)
		end
	end)

	cfg = svc("MatchService"):GetNightConfig()
	if not GrandmaService:_spawnRig(GrandmaRig.Pick(1)) then
		return
	end

	svc("MatchService").NightStarted:Connect(onNightStarted)

	task.spawn(function()
		local last = os.clock()
		local filterAt = 0
		while true do
			task.wait(AI.TickRate)
			local t = os.clock()
			local dt = t - last
			last = t
			if t - filterAt > 1 then
				filterAt = t
				if rig then
					Perception.RefreshFilter(rig.Model)
				end
			end
			debug.profilebegin("GrandmaTick")
			local okTick, e = pcall(tick, dt)
			debug.profileend()
			if not okTick then
				warn("[Grandma]", e)
			end
		end
	end)
end

return GrandmaService
