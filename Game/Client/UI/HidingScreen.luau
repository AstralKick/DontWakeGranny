--!strict
-- HidingScreen (Match)
-- ClientBus "HidingChanged"(true, kind): dark vignette + wardrobe slats / under-bed
-- framing + a LEAVE button (fires "LeaveHiding").
-- ClientBus "HoldBreathStart"(duration): big "HOLD YOUR BREATH" with lungs and a
-- draining meter + a big HOLD button (fires "HoldBreathInput"(down)).
-- ClientBus "HoldBreathEnd"(success): "phew." / "GASP!"
-- The server remotes HidingState / HoldBreath are also watched as a display-only
-- fallback (HidingController answers the server, never this screen).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local UIWidgets = require(script.Parent:WaitForChild("UIWidgets"))

local C = Theme.Color
local HidingScreen = {}

local function isPress(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
end

function HidingScreen.Mount(ctx: any)
	local Bus = UIState.Bus()
	local Net = UIState.Net()
	local player = Players.LocalPlayer

	-- ============================================================ framing (full bleed)
	local frame = UIKit.Box({ Name = "Hiding", Size = UDim2.fromScale(1, 1), Visible = false, Parent = ctx.Bleed })
	local vignette = UIKit.new("Frame", { Name = "Vignette", BackgroundColor3 = C.Ink, BackgroundTransparency = 0.2, Size = UDim2.fromScale(1, 1), Parent = frame })
	-- radial-ish vignette: dark edges, see-through middle
	UIKit.new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.75),
			NumberSequenceKeypoint.new(0.7, 0.75),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = vignette,
	})
	local slats = UIKit.Box({ Name = "Slats", Size = UDim2.fromScale(1, 1), Parent = frame })
	local bed = UIKit.Box({ Name = "Bed", Size = UDim2.fromScale(1, 1), Parent = frame })

	local slatColor = Color3.fromRGB(34, 22, 26)
	-- Louvered door: slats top and bottom, a gap to peek through in the middle.
	for i = 0, 3 do -- 4 slats per band: frames the view but leaves a wide gap to watch her
		for _, band in { 0, 1 } do
			local y = if band == 0 then i * 0.058 else 1 - (i + 1) * 0.058
			local s = UIKit.new("Frame", {
				BackgroundColor3 = slatColor,
				Size = UDim2.new(1.1, 0, 0.042, 0),
				Position = UDim2.new(-0.05, 0, y, 0),
				Rotation = if band == 0 then -1.2 else 1.2,
				Parent = slats,
			})
			UIKit.Stroke(s, 3, C.Ink)
		end
	end
	for _, x in { 0, 1 } do
		UIKit.new("Frame", { BackgroundColor3 = slatColor, Size = UDim2.new(0.08, 0, 1, 0), Position = UDim2.fromScale(x, 0), AnchorPoint = Vector2.new(x, 0), Parent = slats })
	end
	-- Under the bed: bed-board on top with a blanket fringe, floor at the bottom.
	UIKit.new("Frame", { BackgroundColor3 = slatColor, Size = UDim2.fromScale(1, 0.4), Parent = bed })
	local fringe = UIKit.Box({ Size = UDim2.fromScale(1, 0.06), Position = UDim2.fromScale(0, 0.4), Parent = bed })
	UIKit.List(fringe, { Dir = Enum.FillDirection.Horizontal, Gap = 0 })
	for i = 1, 24 do
		local tab = UIKit.new("Frame", { BackgroundColor3 = if i % 2 == 0 then C.Rose:Lerp(C.Ink, 0.55) else C.Bruise:Lerp(C.Ink, 0.5), Size = UDim2.new(1 / 24, 0, 1 + (i % 3) * 0.2, 0), LayoutOrder = i, Parent = fringe })
		UIKit.Corner(tab, UDim.new(0.5, 0))
	end
	UIKit.new("Frame", { BackgroundColor3 = slatColor, Size = UDim2.fromScale(1, 0.14), Position = UDim2.fromScale(0, 1), AnchorPoint = Vector2.new(0, 1), Parent = bed })

	-- ============================================================ controls (safe area)
	local ui = UIKit.Box({ Name = "HidingUI", Size = UDim2.fromScale(1, 1), Visible = false, Parent = ctx.Overlay })
	local hint = UIKit.Label({ Text = "Shhh…", Font = Theme.Font.Body, TextSize = Theme.Text.Header, Color = C.PaperDim, Size = UDim2.fromOffset(600, 60), Position = UDim2.new(0.5, 0, 0, 90), AnchorPoint = Vector2.new(0.5, 0), Parent = ui })
	local leave = UIKit.Button({ Parent = ui, Name = "Leave", Text = "LEAVE", Color = C.Bruise, Size = UDim2.fromOffset(240, 96), Position = UDim2.new(1, -40, 1, -40), AnchorPoint = Vector2.new(1, 1), OnClick = function()
		Bus.Fire("LeaveHiding")
	end })
	-- Keyboard / gamepad: HidingController binds Leave = E / ButtonB. Show that instead.
	local leaveHint = UIKit.Box({ Name = "LeaveHint", Size = UDim2.fromOffset(260, 70), Position = UDim2.new(1, -40, 1, -40), AnchorPoint = Vector2.new(1, 1), Parent = ui })
	UIKit.List(leaveHint, { Dir = Enum.FillDirection.Horizontal, Gap = 12, H = Enum.HorizontalAlignment.Right, V = Enum.VerticalAlignment.Center })
	UIWidgets.Glyph({ Parent = leaveHint, Key = Enum.KeyCode.E, Pad = Enum.KeyCode.ButtonB, Size = 60, LayoutOrder = 1 })
	UIKit.Label({ Text = "Leave", Font = Theme.Font.Button, TextSize = Theme.Text.Body, Auto = "X", Size = UDim2.fromOffset(0, 60), LayoutOrder = 2, Parent = leaveHint })

	-- ============================================================ hold your breath
	local breath = UIKit.Box({ Name = "Breath", Size = UDim2.fromScale(1, 1), Visible = false, Parent = ctx.Overlay })
	local bTitle = UIKit.Title({ Text = "HOLD YOUR BREATH", TextSize = 92, Color = C.Paper, Stroke = 6, Size = UDim2.new(1, 0, 0, 110), Position = UDim2.fromScale(0.5, 0.2), AnchorPoint = Vector2.new(0.5, 0.5), Crooked = 6, Parent = breath })
	local lungs = UIKit.Box({ Size = UDim2.fromOffset(150, 150), Position = UDim2.fromScale(0.5, 0.42), AnchorPoint = Vector2.new(0.5, 0.5), Parent = breath })
	UIIcons.Lungs(lungs)
	local meter = UIKit.Bar({ Parent = breath, Size = UDim2.fromOffset(520, 38), Position = UDim2.fromScale(0.5, 0.55), AnchorPoint = Vector2.new(0.5, 0.5), Color = C.Rose })
	local sub = UIKit.Label({ Text = "She's right outside. Don't let go.", Font = Theme.Font.Body, TextSize = Theme.Text.Body + 2, Color = C.PaperDim, Size = UDim2.fromOffset(800, 44), Position = UDim2.fromScale(0.5, 0.62), AnchorPoint = Vector2.new(0.5, 0.5), Parent = breath })
	local holdBtn = UIKit.IconButton({ Parent = breath, Name = "Hold", Size = 200, Color = C.Rose, Icon = UIIcons.Lungs, Caption = "HOLD", Position = UDim2.new(1, -50, 1, -60), AnchorPoint = Vector2.new(1, 1), Sound = false })
	local holdHint = UIKit.Box({ Name = "HoldHint", Size = UDim2.fromOffset(400, 80), Position = UDim2.fromScale(0.5, 0.7), AnchorPoint = Vector2.new(0.5, 0.5), Parent = breath })
	UIKit.List(holdHint, { Dir = Enum.FillDirection.Horizontal, Gap = 14, V = Enum.VerticalAlignment.Center })
	UIKit.Label({ Text = "HOLD", Font = Theme.Font.Title, TextSize = 50, Color = C.Rose, Auto = "X", Size = UDim2.fromOffset(0, 70), LayoutOrder = 1, Parent = holdHint })
	UIWidgets.Glyph({ Parent = holdHint, Key = Enum.KeyCode.Space, Pad = Enum.KeyCode.ButtonA, Size = 70, LayoutOrder = 2 })
	local leaveOn = false
	local function refreshInputHints()
		local touch = UIState.Input == "Touch"
		holdBtn.Instance.Visible = touch
		holdHint.Visible = not touch
		leave.Instance.Visible = leaveOn and touch
		leaveHint.Visible = leaveOn and not touch
	end
	local function setLeaveVisible(on: boolean)
		leaveOn = on
		refreshInputHints()
	end
	refreshInputHints()
	UIState.Changed:Connect(function(k)
		if k == "Input" then
			refreshInputHints()
		end
	end)
	local result = UIKit.Label({ Text = "", Font = Theme.Font.Title, TextSize = 110, Color = C.Mint, Stroke = 6, Size = UDim2.fromOffset(900, 140), Position = UDim2.fromScale(0.5, 0.4), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, Parent = ctx.Overlay })

	local holding = false
	local function setHold(on: boolean)
		if holding == on then
			return
		end
		holding = on
		Bus.Fire("HoldBreathInput", on)
		UIKit.Tween(UIKit.ScaleOf(lungs), 0.2, { Scale = if on then 0.8 else 1.1 }, Enum.EasingStyle.Back)
	end
	holdBtn.Button.InputBegan:Connect(function(input)
		if isPress(input) then
			setHold(true)
		end
	end)
	holdBtn.Button.InputEnded:Connect(function(input)
		if isPress(input) then
			setHold(false)
		end
	end)

	-- ============================================================ state
	local hidden = false
	local function setHidden(on: boolean, kind: string?)
		if on == hidden then
			return
		end
		hidden = on
		frame.Visible = on
		ui.Visible = on
		if on then
			local underBed = typeof(kind) == "string" and (kind:lower():find("bed") ~= nil)
			slats.Visible = not underBed
			bed.Visible = underBed
			vignette.BackgroundTransparency = 1
			UIKit.Tween(vignette, 0.35, { BackgroundTransparency = 0.2 })
			setLeaveVisible(true)
			UIKit.Pop(leave.Instance :: any, 0.7)
			hint.Text = "Shhh…"
			UIKit.Pop(hint :: any, 0.8)
		else
			breath.Visible = false
			setHold(false)
		end
	end
	Bus.On("HidingChanged", function(h, kind)
		setHidden(h == true, kind)
	end)
	Net.Event("HidingState").OnClientEvent:Connect(function(h, kind)
		task.delay(0.1, setHidden, h == true, kind)
	end)

	local breathToken = 0
	local breathActive = false
	local function startBreath(duration: number)
		breathToken += 1
		local my = breathToken
		breathActive = true
		breath.Visible = true
		setLeaveVisible(false)
		result.Visible = false
		UIKit.Pop(bTitle :: any, 1.4, 0.2)
		UIKit.Shake(bTitle, 6, 0.3)
		UIState.Play("Heartbeat")
		meter:Set(1)
		local t0 = os.clock()
		task.spawn(function()
			while breathToken == my and breathActive do
				local frac = 1 - (os.clock() - t0) / math.max(0.1, duration)
				meter:Set(frac)
				if UIState.Input == "Touch" then
					sub.Text = if holding then "Don't let go…" else "HOLD THE BUTTON!"
					sub.TextColor3 = if holding then C.PaperDim else C.Blood
				else
					sub.Text = "She's right outside. Don't let go."
				end
				if frac <= 0 then
					break
				end
				RunService.RenderStepped:Wait()
			end
		end)
	end
	local function endBreath(success: boolean)
		if not breathActive then
			return
		end
		breathActive = false
		breathToken += 1
		breath.Visible = false
		setHold(false)
		result.Text = if success then "phew." else "GASP!"
		result.FontFace = if success then Theme.Font.Title else Theme.Font.Creep
		result.TextColor3 = if success then C.Mint else C.Blood
		result.Visible = true
		UIKit.Pop(result :: any, 0.5, 0.3)
		if not success then
			UIState.Play("Gasp")
			UIKit.Shake(result, 10, 0.4)
		end
		task.delay(1.4, function()
			result.Visible = false
			if hidden then
				setLeaveVisible(true)
			end
		end)
	end
	Bus.On("HoldBreathStart", function(duration)
		startBreath(if typeof(duration) == "number" then duration else 3)
	end)
	Bus.On("HoldBreathEnd", function(success)
		endBreath(success == true)
	end)
	-- display-only fallback if no gameplay controller relays the check
	Net.Event("HoldBreath").OnClientEvent:Connect(function(_id, duration)
		task.delay(0.15, function()
			if not breathActive and typeof(duration) == "number" then
				startBreath(duration)
				task.delay(duration + 0.2, function()
					if breathActive then
						endBreath(player:GetAttribute("Alive") ~= false)
					end
				end)
			end
		end)
	end)
	player:GetAttributeChangedSignal("Alive"):Connect(function()
		if player:GetAttribute("Alive") == false then
			setHidden(false)
		end
	end)
end

return HidingScreen
