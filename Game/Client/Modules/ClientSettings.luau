--!strict
-- ClientSettings
-- One local view of the player's settings for the gameplay controllers.
-- Source of truth: DataController "Settings" (persistent); instant local overrides come from
-- ClientBus "SettingsChanged"(table) which the settings UI fires before saving.
--   ClientSettings:Get(key)        -> value (Music 0..1, SFX 0..1, ReduceFlashes bool, Sensitivity)
--   ClientSettings:ReduceMotion()  -> boolean (ReduceFlashes or ReduceMotion)
--   ClientSettings.Changed:Connect(fn(settings))

local ClientBus = shared("ClientBus")

local ClientSettings = {}

local DEFAULTS = { Music = 0.7, SFX = 1, ReduceFlashes = false, Sensitivity = 1 }
local current: { [string]: any } = table.clone(DEFAULTS)

local changed = Instance.new("BindableEvent")
ClientSettings.Changed = changed.Event

local function merge(t: any)
	if typeof(t) ~= "table" then
		return
	end
	for k, v in t do
		current[k] = v
	end
	-- Look sensitivity multiplies the player's own Roblox setting.
	if typeof(current.Sensitivity) == "number" then
		pcall(function()
			game:GetService("UserInputService").MouseDeltaSensitivity = math.clamp(current.Sensitivity, 0.2, 3)
		end)
	end
	changed:Fire(current)
end

function ClientSettings:Get(key: string): any
	return current[key]
end

function ClientSettings:All(): { [string]: any }
	return current
end

function ClientSettings:ReduceMotion(): boolean
	return current.ReduceFlashes == true or current.ReduceMotion == true
end

function ClientSettings.Preload() end

function ClientSettings:Start()
	ClientBus.On("SettingsChanged", merge)
	local DataController = shared("DataController")
	DataController.Changed:Connect(function(key, value)
		if key == "Settings" then
			merge(value)
		end
	end)
	DataController:WaitReady()
	merge(DataController:Get("Settings"))
end

return ClientSettings
