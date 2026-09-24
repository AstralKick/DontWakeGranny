--!strict
-- UIState
-- Tiny shared store for UI-wide facts: the active input kind, the viewport scale and
-- the reduce-motion preference. UIController writes it; every screen reads it.
--   UIState.Input        "Touch" | "Gamepad" | "KeyboardMouse"
--   UIState.Scale        current root UIScale value
--   UIState.ReduceMotion boolean (Settings.ReduceFlashes)
--   UIState.Set(key, value)             -- fires Changed if it differs
--   UIState.Changed:Connect(fn(key, value))
--
-- Also exposes LAZY accessors for runtime-only modules, so every UI module stays
-- require-able in Edit mode (Net would create/wait for remotes at require time).
--   UIState.Net()  UIState.Bus()  UIState.Data()  UIState.Sfx()

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIState = {
	Input = "KeyboardMouse",
	Scale = 1,
	ReduceMotion = false,
}

local changed = Instance.new("BindableEvent")
UIState.Changed = changed.Event

function UIState.Set(key: string, value: any)
	if (UIState :: any)[key] == value then
		return
	end
	(UIState :: any)[key] = value
	changed:Fire(key, value)
end

function UIState.Net(): any
	return require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("Net") :: ModuleScript)
end

function UIState.Bus(): any
	return require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("ClientBus") :: ModuleScript)
end

function UIState.Sfx(): any
	return require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("Sfx") :: ModuleScript)
end

function UIState.Data(): any
	return shared("DataController")
end

function UIState.Config(name: string): any
	return require(ReplicatedStorage:WaitForChild("Config"):WaitForChild(name) :: ModuleScript)
end

-- Plays a UI sound by AssetConfig key (silently skipped if the id is empty).
function UIState.Play(key: string)
	pcall(function()
		UIState.Sfx().Play(key)
	end)
end

return UIState
