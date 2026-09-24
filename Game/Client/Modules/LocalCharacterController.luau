--!strict
-- LocalCharacterController (Match)
-- Small local-character polish: heavy breathing loop (Sfx "Breath") while stamina is low
-- (Stamina < 20% of MaxStamina, fades out above 35%), and a gasp when it runs dry.
-- Footsteps are Roblox's default character sounds.

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local PlaceRole = shared("PlaceRole")
local AssetConfig = shared("AssetConfig")
local Sfx = shared("Sfx")

local LocalCharacterController = {}

local player = Players.LocalPlayer
local LOW, RECOVER = 0.2, 0.35

local loop: Sound? = nil
local breathing = false
local wasEmpty = false

local function staminaFrac(): number
	local s = tonumber(player:GetAttribute("Stamina")) or 100
	local m = tonumber(player:GetAttribute("MaxStamina")) or 100
	return if m > 0 then s / m else 1
end

local function setBreathing(on: boolean)
	if on == breathing then
		return
	end
	breathing = on
	if on and not loop then
		loop = Sfx.Loop("Breath", SoundService)
		local music = shared("MusicController")
		local dry = music:GetGroup("SFXDry")
		if loop and dry then
			loop.SoundGroup = dry
		end
		if loop then
			loop.Volume = 0
		end
	end
	local l = loop
	if l then
		local def = AssetConfig.Sounds.Breath
		TweenService:Create(l, TweenInfo.new(if on then 0.6 else 1.6), { Volume = if on then (def and def.Volume or 0.7) else 0 }):Play()
	end
end

local function update()
	local alive = player:GetAttribute("Alive") ~= false and player.Character ~= nil
	local f = staminaFrac()
	if not alive then
		setBreathing(false)
		wasEmpty = false
		return
	end
	if f < LOW then
		setBreathing(true)
	elseif f > RECOVER then
		setBreathing(false)
	end
	local empty = f <= 0.01
	if empty and not wasEmpty then
		Sfx.Play("Gasp")
	end
	wasEmpty = empty
end

function LocalCharacterController.Preload() end

function LocalCharacterController:Start()
	if not PlaceRole.IsMatch then
		return
	end
	player:GetAttributeChangedSignal("Stamina"):Connect(update)
	player:GetAttributeChangedSignal("Alive"):Connect(update)
end

return LocalCharacterController
