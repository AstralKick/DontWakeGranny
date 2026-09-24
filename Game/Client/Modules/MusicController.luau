--!strict
-- MusicController
-- Dynamic music + the local sound mix.
--   * 3-state music from AssetConfig.Music driven by MatchState.GrandmaState:
--       Asleep/FakeSleep -> GrannyAsleep · Stirring..Distracted -> GrannySearching ·
--       Chasing/Attacking -> GrannyChasing. Lobby track in the lobby, Morning/Finale overrides.
--     Crossfades: 1.2 s into a chase (with a stinger), 3 s out of it, 2 s otherwise.
--   * SoundGroups under SoundService: Music, SFX, SFXDry (heartbeat/breath: never muffled).
--     Every Sound without a group is put in SFX. Volumes follow Settings.Music / Settings.SFX.
--   * Ambient bed: wind loop, occasional thunder, distant creaks during the night.
--   * Heartbeat loop when Grandma is chasing you or chasing close by.
--
--   MusicController:SetHeartbeat(key, intensity 0..1)   (0 = release)
--   MusicController:SetMuffle(key, level 0..1)          (low-pass the world, e.g. holding breath)
--   MusicController:GetGroup("Music" | "SFX" | "SFXDry") -> SoundGroup

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local PlaceRole = shared("PlaceRole")
local AssetConfig = shared("AssetConfig")
local Sfx = shared("Sfx")

local MusicController = {}

local player = Players.LocalPlayer

local STATE_MUSIC: { [string]: string } = {
	Asleep = "GrannyAsleep",
	FakeSleep = "GrannyAsleep",
	Stirring = "GrannySearching",
	Waking = "GrannySearching",
	Searching = "GrannySearching",
	Patrolling = "GrannySearching",
	Returning = "GrannySearching",
	CheckingHiding = "GrannySearching",
	Stalking = "GrannySearching",
	Distracted = "GrannySearching",
	Chasing = "GrannyChasing",
	Attacking = "GrannyChasing",
}
local HEARTBEAT_RANGE = 40

local groups: { [string]: SoundGroup } = {}
local eqs: { EqualizerSoundEffect } = {}
local tracks: { [string]: Sound } = {}
local trackTweens: { [Sound]: Tween } = {}
local currentKey: string? = nil
local heartbeat: Sound? = nil
local heartReasons: { [string]: number } = {}
local heartLevel = 0
local muffleReasons: { [string]: number } = {}
local muffleLevel = 0
local savedReverb: Enum.ReverbType? = nil
local wind: Sound? = nil
local matchState: Instance? = nil
local settings: any = nil

-- ------------------------------------------------------------------ groups

local function group(name: string, muffled: boolean): SoundGroup
	local g = SoundService:FindFirstChild(name)
	if not g or not g:IsA("SoundGroup") then
		g = Instance.new("SoundGroup")
		g.Name = name
		g.Parent = SoundService
	end
	if muffled then
		local eq = Instance.new("EqualizerSoundEffect")
		eq.Name = "Muffle"
		eq.HighGain = 0
		eq.MidGain = 0
		eq.LowGain = 0
		eq.Enabled = false
		eq.Parent = g
		table.insert(eqs, eq)
	end
	groups[name] = g :: SoundGroup
	return g :: SoundGroup
end

function MusicController:GetGroup(name: string): SoundGroup?
	return groups[name]
end

local function applyVolumes()
	local music = tonumber(settings and settings:Get("Music")) or 0.7
	local sfx = tonumber(settings and settings:Get("SFX")) or 1
	if groups.Music then
		groups.Music.Volume = math.clamp(music, 0, 2)
	end
	if groups.SFX then
		groups.SFX.Volume = math.clamp(sfx, 0, 2)
	end
	if groups.SFXDry then
		groups.SFXDry.Volume = math.clamp(sfx, 0, 2)
	end
end

local function assign(s: Instance)
	if s:IsA("Sound") and s.SoundGroup == nil then
		s.SoundGroup = groups.SFX
	end
end

local function hookGroupAssignment()
	local roots: { Instance } = { workspace, SoundService }
	local pg = player:FindFirstChild("PlayerGui")
	if pg then
		table.insert(roots, pg)
	end
	for _, root in roots do
		root.DescendantAdded:Connect(assign)
		task.spawn(function()
			for i, d in root:GetDescendants() do
				assign(d)
				if i % 3000 == 0 then
					task.wait()
				end
			end
		end)
	end
end

-- ------------------------------------------------------------------ music

local function resolve(id: string?): string?
	if not id or id == "" or id == "0" then
		return nil
	end
	return if tonumber(id) then "rbxassetid://" .. id else id
end

local function getTrack(key: string): Sound?
	local s = tracks[key]
	if s then
		return s
	end
	local def = AssetConfig.Music[key]
	local id = def and resolve(def.Id)
	if not id then
		return nil
	end
	s = Instance.new("Sound")
	s.Name = "Music_" .. key
	s.SoundId = id
	s.Looped = true
	s.Volume = 0
	s.SoundGroup = groups.Music
	s.Parent = SoundService
	tracks[key] = s
	return s
end

local function fadeTo(s: Sound, volume: number, time: number, onDone: (() -> ())?)
	local old = trackTweens[s]
	if old then
		old:Cancel()
	end
	local tw = TweenService:Create(s, TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Volume = volume })
	trackTweens[s] = tw
	tw.Completed:Once(function(state)
		if state == Enum.PlaybackState.Completed and onDone then
			onDone()
		end
	end)
	tw:Play()
end

local function isChaseKey(key: string?): boolean
	return key == "GrannyChasing"
end

local function playTrack(key: string?, fadeIn: number, fadeOut: number)
	if key == currentKey then
		return
	end
	local oldKey = currentKey
	currentKey = key
	local old = oldKey and tracks[oldKey]
	local new = key and getTrack(key)
	if old and old ~= new then
		fadeTo(old, 0, fadeOut, function()
			if not (currentKey and tracks[currentKey] == old) then
				old:Pause()
			end
		end)
	end
	if new and key then
		local def = AssetConfig.Music[key]
		if not new.IsPlaying then
			-- The chase always hits from the top; ambient states resume where they paused.
			if isChaseKey(key) then
				new.TimePosition = 0
			end
			new:Resume()
		end
		fadeTo(new, def.Volume or 0.5, fadeIn)
	end
end

local function chooseMusic(): string?
	if not PlaceRole.IsMatch then
		return "Lobby"
	end
	local ms = matchState
	if not ms then
		return "GrannyAsleep"
	end
	local phase = ms:GetAttribute("Phase")
	local gstate = ms:GetAttribute("GrandmaState") or "Asleep"
	if phase == "Morning" or phase == "Victory" then
		return if resolve(AssetConfig.Music.Morning.Id) then "Morning" else nil
	elseif phase == "GameOver" or phase == "Ended" then
		return nil
	end
	local base = STATE_MUSIC[gstate] or "GrannyAsleep"
	if ms:GetAttribute("Finale") == true and phase == "Night" and not isChaseKey(base) then
		return "Finale"
	end
	return base
end

local function refreshMusic()
	local key = chooseMusic()
	if key == currentKey then
		return
	end
	local intoChase = isChaseKey(key) and not isChaseKey(currentKey)
	local outOfChase = isChaseKey(currentKey) and not isChaseKey(key)
	if intoChase then
		playTrack(key, 1.2, 0.8)
		local stinger = if Sfx.Has("ChaseStinger") then "ChaseStinger" else "NewArea"
		local s = Sfx.Play(stinger, nil, { Volume = 0.55 })
		if s and groups.SFXDry then
			s.SoundGroup = groups.SFXDry
		end
	elseif outOfChase then
		playTrack(key, 3, 3)
	else
		playTrack(key, 2, 2)
	end
end

-- ------------------------------------------------------------------ heartbeat / muffle

function MusicController:SetHeartbeat(key: string, intensity: number)
	heartReasons[key] = if intensity > 0 then math.clamp(intensity, 0, 1) else nil
end

function MusicController:SetMuffle(key: string, level: number)
	muffleReasons[key] = if level > 0 then math.clamp(level, 0, 1) else nil
	local target = 0
	for _, v in muffleReasons do
		target = math.max(target, v)
	end
	if math.abs(target - muffleLevel) < 0.01 then
		return
	end
	muffleLevel = target
	for _, eq in eqs do
		eq.Enabled = true
		local tw = TweenService:Create(eq, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
			HighGain = -38 * target,
			MidGain = -14 * target,
			LowGain = 3 * target,
		})
		tw:Play()
		if target == 0 then
			tw.Completed:Once(function(state)
				if state == Enum.PlaybackState.Completed and muffleLevel == 0 then
					eq.Enabled = false
				end
			end)
		end
	end
	if target >= 0.5 then
		if savedReverb == nil then
			savedReverb = SoundService.AmbientReverb
		end
		SoundService.AmbientReverb = Enum.ReverbType.PaddedCell
	elseif savedReverb ~= nil then
		SoundService.AmbientReverb = savedReverb :: Enum.ReverbType
		savedReverb = nil
	end
end

local function grandmaRoot(): BasePart?
	local g = CollectionService:GetTagged("Grandma")[1] or workspace:FindFirstChild("Grandma")
	local r = g and g:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r else nil
end

local function updateChaseHeartbeat()
	local ms = matchState
	local state = ms and ms:GetAttribute("GrandmaState")
	local intensity = 0
	if (state == "Chasing" or state == "Attacking") and player:GetAttribute("Alive") ~= false then
		local g = CollectionService:GetTagged("Grandma")[1] or workspace:FindFirstChild("Grandma")
		local targeted = g ~= nil and g:GetAttribute("Target") == player.UserId
		local root = grandmaRoot()
		local char = player.Character
		local me = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local dist = if root and me then (root.Position - me.Position).Magnitude else math.huge
		if targeted then
			intensity = 1
		elseif dist < HEARTBEAT_RANGE then
			intensity = 0.4 + 0.6 * (1 - dist / HEARTBEAT_RANGE)
		end
	end
	MusicController:SetHeartbeat("Chase", intensity)
end

local function heartStep(dt: number)
	local hb = heartbeat
	if not hb then
		return
	end
	local target = 0
	for _, v in heartReasons do
		target = math.max(target, v)
	end
	heartLevel += (target - heartLevel) * math.min(1, dt * 3)
	local base = (AssetConfig.Sounds.Heartbeat and AssetConfig.Sounds.Heartbeat.Volume) or 0.8
	hb.Volume = base * heartLevel
	hb.PlaybackSpeed = 0.9 + 0.35 * heartLevel
end

-- ------------------------------------------------------------------ ambient

local function nightActive(): boolean
	return matchState ~= nil and matchState:GetAttribute("Phase") == "Night"
end

local function ambientLoop()
	local nextThunder = os.clock() + 20 + math.random() * 30
	local nextCreak = os.clock() + 12 + math.random() * 15
	while true do
		task.wait(1)
		local now = os.clock()
		if PlaceRole.IsMatch and nightActive() then
			local redSky = matchState and matchState:GetAttribute("RedSky") == true
			if now > nextThunder then
				nextThunder = now + (if redSky then 14 else 28) + math.random() * 40
				Sfx.Play("Thunder", nil, { Volume = 0.3 + math.random() * 0.35, PlaybackSpeed = 0.85 + math.random() * 0.25 })
			end
			local state = matchState and matchState:GetAttribute("GrandmaState")
			if now > nextCreak and state ~= "Chasing" and state ~= "Attacking" then
				nextCreak = now + 14 + math.random() * 22
				local cam = workspace.CurrentCamera
				if cam then
					local a = math.random() * math.pi * 2
					local pos = cam.CFrame.Position + Vector3.new(math.cos(a) * 26, math.random(-2, 6), math.sin(a) * 26)
					Sfx.Play("FloorCreak", pos, { Volume = 0.22 + math.random() * 0.15, PlaybackSpeed = 0.7 + math.random() * 0.25 })
				end
			end
		end
	end
end

-- ------------------------------------------------------------------ lifecycle

function MusicController.Preload() end

function MusicController:Start()
	settings = shared("ClientSettings")
	group("Music", true)
	group("SFX", true)
	group("SFXDry", false)
	applyVolumes()
	settings.Changed:Connect(applyVolumes)
	hookGroupAssignment()

	heartbeat = Sfx.Loop("Heartbeat", SoundService)
	if heartbeat then
		heartbeat.Volume = 0
		heartbeat.SoundGroup = groups.SFXDry
	end
	wind = Sfx.Loop("Wind", SoundService)
	if wind then
		wind.SoundGroup = groups.SFX
		if not PlaceRole.IsMatch then
			wind.Volume *= 0.6
		end
	end

	if PlaceRole.IsMatch then
		matchState = ReplicatedStorage:WaitForChild("MatchState", 30)
		if matchState then
			for _, attr in { "Phase", "GrandmaState", "Finale" } do
				matchState:GetAttributeChangedSignal(attr):Connect(refreshMusic)
			end
		end
		task.spawn(ambientLoop)
		task.spawn(function()
			while true do
				task.wait(0.2)
				updateChaseHeartbeat()
			end
		end)
	end
	game:GetService("RunService").Heartbeat:Connect(heartStep)
	refreshMusic()
end

return MusicController
