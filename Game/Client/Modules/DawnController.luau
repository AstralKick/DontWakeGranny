--!strict
-- DawnController (Match)
-- Makes the countdown to 6 AM feel like a finish line:
--   * Sunrise track (top-centre): moon -> sun bar that fills through the night, hour notches,
--     "4:20 AM · 1:05 to dawn" under it.
--   * Every new hour: grandfather-clock chime + the hour pops ("3 AM").
--   * Last 60 s: the track pulses, label becomes "DAWN IN 0:59", clock ticking starts
--     (every 2 s, then every second for the final 30 s).
--   * Last 10 s: big centre numbers 10…1 and the screen slowly warms like a sunrise.
-- Hidden during the night-intro cinematic and on Night 31 (Halloween night has no dawn).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local PlaceRole = shared("PlaceRole")
local ClientBus = shared("ClientBus")
local Sfx = shared("Sfx")
local Format = shared("Format")
local GameConfig = shared("GameConfig")

local DawnController = {}

local Theme: any = nil
local C = {
	Ink = Color3.fromRGB(42, 26, 36), Night = Color3.fromRGB(59, 42, 63), Paper = Color3.fromRGB(243, 233, 210),
	Mustard = Color3.fromRGB(224, 176, 79), Rose = Color3.fromRGB(217, 122, 138), Bruise = Color3.fromRGB(123, 92, 142),
}

local gui: ScreenGui
local track: Frame
local fill: Frame
local marker: Frame
local label: TextLabel
local hourPop: TextLabel
local bigNum: TextLabel
local scale: UIScale
local warm: ColorCorrectionEffect

local inCinematic = false
local lastHour = -1
local lastSecond = -1
local lastTick = 0

local function stroke(parent: Instance, thick: number)
	local s = Instance.new("UIStroke")
	s.Color = C.Ink
	s.Thickness = thick
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = parent
	return s
end

local function corner(parent: Instance, r: UDim?)
	local c = Instance.new("UICorner")
	c.CornerRadius = r or UDim.new(0.5, 0)
	c.Parent = parent
end

local function font(kind: string): Font
	if Theme and Theme.Font and Theme.Font[kind] then
		return Theme.Font[kind]
	end
	return if kind == "Title" then Font.fromEnum(Enum.Font.LuckiestGuy) else Font.fromEnum(Enum.Font.FredokaOne)
end

local function disc(parent: Instance, name: string, size: number, color: Color3, x: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = UDim2.fromOffset(size, size)
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.new(x, 0, 0.5, 0)
	f.BackgroundColor3 = color
	f.ZIndex = 4
	corner(f)
	stroke(f, 3)
	f.Parent = parent
	return f
end

local function build()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = Instance.new("ScreenGui")
	gui.Name = "DWG_Dawn"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = 8
	gui.Enabled = false
	gui.Parent = pg

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = gui
	scale = Instance.new("UIScale")
	scale.Parent = root

	-- Track
	local holder = Instance.new("Frame")
	holder.Name = "Sunrise"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.Position = UDim2.new(0.5, 0, 0, 22)
	holder.Size = UDim2.fromOffset(540, 90)
	holder.Parent = root

	track = Instance.new("Frame")
	track.Name = "Track"
	track.AnchorPoint = Vector2.new(0.5, 0)
	track.Position = UDim2.new(0.5, 0, 0, 12)
	track.Size = UDim2.fromOffset(440, 22)
	track.BackgroundColor3 = C.Night
	corner(track)
	stroke(track, 3)
	track.Parent = holder

	fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = C.Bruise
	corner(fill)
	fill.ZIndex = 2
	fill.Parent = track

	-- Hour notches (1 AM .. 5 AM)
	local hours = GameConfig.ClockEndHour - GameConfig.ClockStartHour
	for i = 1, hours - 1 do
		local n = Instance.new("Frame")
		n.Name = "Notch"
		n.BackgroundColor3 = C.Ink
		n.BorderSizePixel = 0
		n.AnchorPoint = Vector2.new(0.5, 0.5)
		n.Position = UDim2.fromScale(i / hours, 0.5)
		n.Size = UDim2.fromOffset(3, 12)
		n.ZIndex = 3
		n.Parent = track
	end

	disc(holder, "Moon", 38, C.Paper, 0.07)
	local sun = disc(holder, "Sun", 42, C.Mustard, 0.93)
	sun.Position = UDim2.new(0.93, 0, 0, 23)
	local moon = holder:FindFirstChild("Moon") :: Frame
	moon.Position = UDim2.new(0.07, 0, 0, 23)

	marker = Instance.new("Frame")
	marker.Name = "Marker"
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Size = UDim2.fromOffset(16, 30)
	marker.Position = UDim2.fromScale(0, 0.5)
	marker.BackgroundColor3 = C.Paper
	marker.ZIndex = 5
	corner(marker, UDim.new(0.4, 0))
	stroke(marker, 3)
	marker.Parent = track

	label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 42)
	label.Size = UDim2.fromOffset(520, 34)
	label.FontFace = font("Button")
	label.TextSize = 26
	label.TextColor3 = C.Paper
	label.Text = ""
	label.Parent = holder
	stroke(label, 2)

	hourPop = Instance.new("TextLabel")
	hourPop.Name = "HourPop"
	hourPop.BackgroundTransparency = 1
	hourPop.AnchorPoint = Vector2.new(0.5, 0)
	hourPop.Position = UDim2.new(0.5, 0, 0, 92)
	hourPop.Size = UDim2.fromOffset(300, 64)
	hourPop.FontFace = font("Title")
	hourPop.TextSize = 54
	hourPop.TextColor3 = C.Mustard
	hourPop.Rotation = -4
	hourPop.TextTransparency = 1
	hourPop.Parent = root
	local hs = stroke(hourPop, 4)
	hs.Transparency = 1

	bigNum = Instance.new("TextLabel")
	bigNum.Name = "Countdown"
	bigNum.BackgroundTransparency = 1
	bigNum.AnchorPoint = Vector2.new(0.5, 0.5)
	bigNum.Position = UDim2.fromScale(0.5, 0.36)
	bigNum.Size = UDim2.fromOffset(360, 220)
	bigNum.FontFace = font("Title")
	bigNum.TextSize = 170
	bigNum.TextColor3 = C.Mustard
	bigNum.TextTransparency = 1
	bigNum.Parent = root
	local bs = stroke(bigNum, 6)
	bs.Transparency = 1

	warm = Instance.new("ColorCorrectionEffect")
	warm.Name = "DWG_DawnWarm"
	warm.Enabled = false
	warm.Parent = Lighting

	local function rescale()
		local vp = workspace.CurrentCamera.ViewportSize
		scale.Scale = math.clamp(math.min(vp.X / 1920, vp.Y / 1080), 0.5, 1.5)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()
end

local function popHour(text: string)
	hourPop.Text = text
	local st = hourPop:FindFirstChildOfClass("UIStroke") :: UIStroke
	hourPop.TextTransparency = 0
	st.Transparency = 0
	hourPop.Size = UDim2.fromOffset(220, 46)
	TweenService:Create(hourPop, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(300, 64) }):Play()
	task.delay(1.8, function()
		TweenService:Create(hourPop, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
		TweenService:Create(st, TweenInfo.new(0.6), { Transparency = 1 }):Play()
	end)
end

local function popNumber(n: number)
	local st = bigNum:FindFirstChildOfClass("UIStroke") :: UIStroke
	bigNum.Text = tostring(n)
	bigNum.TextColor3 = if n <= 3 then C.Rose else C.Mustard
	bigNum.TextTransparency = 0.05
	st.Transparency = 0
	bigNum.TextSize = 230
	TweenService:Create(bigNum, TweenInfo.new(0.35, Enum.EasingStyle.Back), { TextSize = 170 }):Play()
	TweenService:Create(bigNum, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
	TweenService:Create(st, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
end

local function step()
	local ms = ReplicatedStorage:FindFirstChild("MatchState")
	if not ms then
		return
	end
	local phase = ms:GetAttribute("Phase")
	local finale = ms:GetAttribute("Finale") == true
	local show = phase == "Night" and not finale and not inCinematic
	if gui.Enabled ~= show then
		gui.Enabled = show
		if not show then
			warm.Enabled = false
			lastHour, lastSecond = -1, -1
		end
	end
	if not show then
		return
	end

	local start = ms:GetAttribute("NightStart") or 0
	local finish = ms:GetAttribute("NightEnd") or 0
	local now = workspace:GetServerTimeNow()
	local total = math.max(1, finish - start)
	local frac = math.clamp((now - start) / total, 0, 1)
	local left = math.max(0, finish - now)

	fill.Size = UDim2.fromScale(frac, 1)
	marker.Position = UDim2.fromScale(frac, 0.5)
	-- Bar warms from bruise to mustard as dawn approaches.
	fill.BackgroundColor3 = C.Bruise:Lerp(C.Mustard, math.clamp((frac - 0.5) * 2, 0, 1))

	local clock = Format.Clock(frac, GameConfig.ClockStartHour, GameConfig.ClockEndHour)
	if left <= 60 then
		label.Text = `DAWN IN {Format.Seconds(left)}`
		label.TextColor3 = C.Mustard
		local pulse = 1 + 0.06 * math.abs(math.sin(os.clock() * (if left <= 10 then 9 else 5)))
		track.Size = UDim2.fromOffset(440 * pulse, 22 * pulse)
	else
		label.Text = `{clock}  ·  {Format.Seconds(left)} to dawn`
		label.TextColor3 = C.Paper
		track.Size = UDim2.fromOffset(440, 22)
	end

	-- Hour chimes (skip the very start of the night).
	local hours = GameConfig.ClockEndHour - GameConfig.ClockStartHour
	local hour = math.floor(frac * hours)
	if lastHour == -1 then
		lastHour = hour
	elseif hour ~= lastHour and hour < hours then
		lastHour = hour
		local display = (GameConfig.ClockStartHour + hour) % 12
		popHour(`{if display == 0 then 12 else display} AM`)
		Sfx.Play("ClockChime")
	end

	-- Ticking in the last minute: every 2 s, then every second for the last 30 s.
	local sec = math.ceil(left)
	if sec ~= lastSecond then
		lastSecond = sec
		if sec <= 60 and sec > 0 then
			local interval = if sec <= 30 then 1 else 2
			if os.clock() - lastTick >= interval - 0.05 then
				lastTick = os.clock()
				Sfx.Play("ClockTick", nil, { PlaybackSpeed = if sec <= 10 then 1.15 else 0.9 })
			end
		end
		if sec <= 10 and sec > 0 then
			popNumber(sec)
		end
	end

	-- Sunrise warm-up over the last 20 s (subtle; respects reduce-flashes by staying gentle).
	if left <= 20 then
		local a = 1 - left / 20
		warm.Enabled = true
		warm.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(255, 222, 190), a)
		warm.Brightness = 0.06 * a
		warm.Saturation = 0.05 * a
	elseif warm.Enabled then
		warm.Enabled = false
	end
end

function DawnController.Preload() end

function DawnController:Start()
	if not PlaceRole.IsMatch then
		return
	end
	local ok, t = pcall(function()
		return require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("UITheme") :: ModuleScript)
	end)
	if ok then
		Theme = t
		if Theme.Color then
			for k, v in Theme.Color do
				if typeof(v) == "Color3" and C[k] then
					C[k] = v
				end
			end
		end
	end
	build()
	ClientBus.On("CinematicStarted", function()
		inCinematic = true
	end)
	ClientBus.On("CinematicEnded", function()
		inCinematic = false
	end)
	RunService.RenderStepped:Connect(step)
end

return DawnController
