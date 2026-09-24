--!strict
-- Sfx
-- Play sounds by AssetConfig key. Missing IDs are silently skipped, so the game works
-- before final audio exists. Works on server (3D sounds everyone hears) and client.
--   Sfx.Play(key, parentOrPosition?, overrides?) -> Sound?
--   Sfx.Loop(key, parent) -> Sound? (caller stops/destroys)

local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local AssetConfig = require(script.Parent.Parent:WaitForChild("Config"):WaitForChild("AssetConfig"))

local Sfx = {}

local function resolveId(id: string?): string?
	if not id or id == "" or id == "0" then
		return nil
	end
	if tonumber(id) then
		return "rbxassetid://" .. id
	end
	return id
end

local function make(key: string, overrides: { [string]: any }?): Sound?
	local def = AssetConfig.Sounds[key]
	if not def then
		return nil
	end
	local id = resolveId(def.Id)
	if not id then
		return nil
	end
	local s = Instance.new("Sound")
	s.Name = key
	s.SoundId = id
	s.Volume = def.Volume or 1
	s.Looped = def.Looped == true
	if def.Max then
		s.RollOffMaxDistance = def.Max
		s.RollOffMinDistance = 6
		s.RollOffMode = Enum.RollOffMode.InverseTapered
	end
	if overrides then
		for k, v in overrides do
			(s :: any)[k] = v
		end
	end
	return s
end

function Sfx.Play(key: string, where: (Instance | Vector3)?, overrides: { [string]: any }?): Sound?
	local s = make(key, overrides)
	if not s then
		return nil
	end
	local holder: Instance
	if typeof(where) == "Vector3" then
		local att = Instance.new("Attachment")
		att.WorldPosition = where
		att.Parent = workspace.Terrain
		holder = att
		Debris:AddItem(att, 12)
	elseif typeof(where) == "Instance" then
		holder = where
	else
		holder = SoundService
	end
	s.Parent = holder
	if not s.Looped then
		s.Ended:Once(function()
			s:Destroy()
		end)
		Debris:AddItem(s, 15)
	end
	s:Play()
	return s
end

function Sfx.Loop(key: string, parent: Instance): Sound?
	local s = make(key, { Looped = true })
	if not s then
		return nil
	end
	s.Parent = parent
	s:Play()
	return s
end

function Sfx.Has(key: string): boolean
	local def = AssetConfig.Sounds[key]
	return def ~= nil and resolveId(def.Id) ~= nil
end

return Sfx
