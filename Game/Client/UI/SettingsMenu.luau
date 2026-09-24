--!strict
-- SettingsMenu (both places) — menu "Settings"
-- Music / SFX volume, camera sensitivity and Reduce flashes & motion. Saves with
-- Net "SaveSettings" (debounced) and fires ClientBus "SettingsChanged"(settings) so
-- the gameplay side (music, effects, camera) applies them. Reduce flashes also turns
-- off the UI's idle/twitch animations (UIState.ReduceMotion).

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local MenuHost = require(script.Parent:WaitForChild("MenuHost"))

local C = Theme.Color
local SettingsMenu = {}

local SENS_MIN, SENS_MAX = 0.2, 3

local function build(): any
	local shell = MenuHost.Shell({ Name = "Settings", Title = "Settings", Color = C.Night, Accent = C.Bruise, Size = UDim2.fromScale(0.62, 0.78), Max = Vector2.new(1000, 760), Tilt = 1 })
	local list = UIKit.Scroll({ Parent = shell.Body, Gap = 18, H = Enum.HorizontalAlignment.Left })

	local current = { Music = 1, SFX = 1, Sensitivity = 1, ReduceFlashes = false }
	local saveToken = 0
	local function save()
		saveToken += 1
		local my = saveToken
		local copy = table.clone(current)
		UIState.Set("ReduceMotion", copy.ReduceFlashes == true)
		pcall(function()
			UIState.Bus().Fire("SettingsChanged", copy)
		end)
		task.delay(0.6, function()
			if my == saveToken then
				pcall(function()
					UIState.Net().Event("SaveSettings"):FireServer(copy)
				end)
			end
		end)
	end

	local function row(order: number, title: string, sub: string): Frame
		local r = UIKit.Box({ Size = UDim2.new(1, -20, 0, 156), LayoutOrder = order, Parent = list })
		UIKit.Label({ Text = title, Font = Theme.Font.Button, TextSize = Theme.Text.Body + 2, XAlign = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 40), Parent = r })
		UIKit.Label({ Text = sub, Font = Theme.Font.Body, TextSize = Theme.Text.Small, Color = C.PaperDim, Stroke = false, XAlign = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 38), Parent = r })
		return r
	end

	local music = UIKit.Stepper({ Parent = row(1, "Music", "Grandma's gramophone."), Value = 1, Color = C.Rose, OnChange = function(v)
		current.Music = v
		save()
	end })
	music.Instance.Position = UDim2.fromOffset(0, 72)

	local sfx = UIKit.Stepper({ Parent = row(2, "Sound effects", "Creaks, snores and footsteps. You want these."), Value = 1, Color = C.Mint, OnChange = function(v)
		current.SFX = v
		save()
	end })
	sfx.Instance.Position = UDim2.fromOffset(0, 72)

	local sens = UIKit.Stepper({ Parent = row(3, "Camera sensitivity", "How fast you look around."), Value = 0.3, Color = C.Mustard, OnChange = function(v)
		current.Sensitivity = SENS_MIN + (SENS_MAX - SENS_MIN) * v
		save()
	end })
	sens.Instance.Position = UDim2.fromOffset(0, 72)

	local flashRow = row(4, "Reduce flashes & motion", "Softer jumpscares, no screen shake, calmer menus.")
	local toggle = UIKit.Toggle({ Parent = flashRow, Value = false, OnChange = function(v)
		current.ReduceFlashes = v
		save()
	end })
	toggle.Instance.Position = UDim2.fromOffset(0, 70)

	-- gamepad: vertical order through the rows
	local chain = { music, sfx, sens }
	for i, s in chain do
		local up = chain[i - 1]
		local down = chain[i + 1]
		s.First.NextSelectionUp = if up then up.First else nil
		s.Last.NextSelectionUp = if up then up.Last else nil
		s.First.NextSelectionDown = if down then down.First else toggle.Button
		s.Last.NextSelectionDown = if down then down.Last else toggle.Button
	end
	toggle.Button.NextSelectionUp = sens.First

	return {
		Root = shell.Root,
		Panel = shell.Panel,
		Backdrop = shell.Backdrop,
		First = music.First,
		OnOpen = function()
			local ok, s = pcall(function()
				return UIState.Data():Get("Settings")
			end)
			if ok and typeof(s) == "table" then
				current.Music = s.Music or 1
				current.SFX = s.SFX or 1
				current.Sensitivity = s.Sensitivity or 1
				current.ReduceFlashes = s.ReduceFlashes == true
			end
			music:Set(current.Music)
			sfx:Set(current.SFX)
			sens:Set((current.Sensitivity - SENS_MIN) / (SENS_MAX - SENS_MIN))
			toggle:Set(current.ReduceFlashes)
		end,
	}
end

function SettingsMenu.Mount(_ctx: any)
	MenuHost.Register("Settings", build)
end

return SettingsMenu
