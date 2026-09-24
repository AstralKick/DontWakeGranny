--!strict
-- ClientBus
-- Local (client-only) signals that decouple UI from gameplay controllers.
-- UI buttons fire intents; gameplay controllers fire state changes the UI reacts to.
--   ClientBus.Fire(name, ...)   ClientBus.On(name, fn) -> RBXScriptConnection
--
-- Known signals (keep this list up to date):
--   Intents (UI/Input -> gameplay):
--     "SprintInput"(isDown: boolean)       "CrouchToggle"()        "FlashlightToggle"()
--     "UseItem"(key: string)               "CycleItem"(dir: number)
--     "LeaveHiding"()                      "HoldBreathInput"(isDown: boolean)
--     "SpectateCycle"(dir: number)         "OpenMenu"(name: string) "CloseMenus"()
--     "SpectateRequest"(on: boolean)       (DeathScreen: player chose SPECTATE / was revived)
--     "SettingsChanged"(settings: {Music, SFX, Sensitivity, ReduceFlashes}) (SettingsMenu)
--   UI state (UI -> anyone):
--     "UIMenuOpen"(isOpen: boolean)        a modal menu opened/closed (gameplay may ignore input)
--     "SettingsChanged"(settings: table)   -- partial or full {Music?, SFX?, ReduceFlashes?, Sensitivity?};
--                                             applied locally at once (ClientSettings), save via SaveSettings
--     "UIMenuOpen"(isOpen: boolean)        -- MenuHost; InputController stops gamepad B = crouch while open
--     "SpectateRequest"(on: boolean)       -- DeathScreen spectate bar; SpectateController re-validates
--   State (gameplay -> UI):
--     "SelectedItem"(key: string)          "SpectateTarget"(player: Player?)
--     "JumpscareStarted"(formKey, variant) "JumpscareFinished"()
--     "CinematicStarted"(kind: string, night: number)  "CinematicEnded"(kind: string)
--                                          NightIntroController (kind "NightIntro"); the HUD hides
--                                          while a cinematic owns the camera/screen
--     "HidingChanged"(hidden: boolean, kind: string?)
--     "HoldBreathStart"(duration: number)  "HoldBreathEnd"(success: boolean)
--     "InputTypeChanged"(kind: "Touch" | "Gamepad" | "KeyboardMouse")

local ClientBus = {}

local events: { [string]: BindableEvent } = {}

local function get(name: string): BindableEvent
	local e = events[name]
	if not e then
		e = Instance.new("BindableEvent")
		events[name] = e
	end
	return e
end

function ClientBus.Fire(name: string, ...: any)
	get(name):Fire(...)
end

function ClientBus.On(name: string, fn: (...any) -> ()): RBXScriptConnection
	return get(name).Event:Connect(fn)
end

return ClientBus
