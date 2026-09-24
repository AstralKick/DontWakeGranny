--!strict
-- CarPanel (Lobby)
-- CarState(state | nil) -> "MOM'S CAR  2/5" with occupant headshots, the departure
-- countdown (interpolated locally between the server's 1 Hz updates), a friend-bonus
-- hint and a Get Out button. The driver (IsLeader) also gets: Anyone / Friends only,
-- the start-night picker (Checkpoints) and GO NOW.
-- Gamepad: focus jumps to GO NOW (driver) or Get out when the panel opens and returns after a
-- menu closes (sticky GamepadNav zone); B = Get out while the panel is up.
-- CarDepart -> fade to black, "Off to Grandma's…" and a tiny minivan on a road.

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local MenuHost = require(script.Parent:WaitForChild("MenuHost"))
local GamepadNav = require(script.Parent:WaitForChild("GamepadNav"))
local ContextActionService = game:GetService("ContextActionService")

local C = Theme.Color
local MapConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("MapConfig"))
local CarPanel = {}

local friendCache: { [number]: boolean } = {}

local function isFriend(uid: number): boolean?
	local player = Players.LocalPlayer
	if uid == player.UserId then
		return false
	end
	local v = friendCache[uid]
	if v == nil then
		task.spawn(function()
			local ok, res = pcall(player.IsFriendsWith, player, uid)
			friendCache[uid] = ok and res == true
		end)
	end
	return v
end

-- A tiny minivan doodle (Mom's car) for the departure screen.
local function minivan(parent: Instance): Frame
	local van = UIKit.Box({ Name = "Van", Size = UDim2.fromOffset(220, 120), Parent = parent })
	UIIcons.Blob(van, C.Mint, 0.5, 0.52, 0.98, 0.56, 0.3)
	UIIcons.Blob(van, C.Mint, 0.42, 0.26, 0.62, 0.34, 0.35, 0, 3, -1)
	UIIcons.Blob(van, Color3.fromRGB(190, 214, 255), 0.3, 0.3, 0.2, 0.2, 0.25, 0, 3, 1)
	UIIcons.Blob(van, Color3.fromRGB(190, 214, 255), 0.55, 0.3, 0.2, 0.2, 0.25, 0, 3, 1)
	UIIcons.Blob(van, C.Mustard, 0.96, 0.5, 0.06, 0.14, 0.5, 0, 2, 1)
	local w1 = UIIcons.Blob(van, C.Ink, 0.24, 0.84, 0.2, 0.36, 0.5, 0, 0, 2)
	local w2 = UIIcons.Blob(van, C.Ink, 0.76, 0.84, 0.2, 0.36, 0.5, 0, 0, 2)
	for _, w in { w1, w2 } do
		UIIcons.Blob(w, C.PaperDim, 0.5, 0.5, 0.4, 0.4, 0.5, 0, 0, 1)
	end
	return van
end

function CarPanel.Mount(ctx: any)
	local Net = UIState.Net()
	local CarAction = Net.Event("CarAction")

	local root = UIKit.Box({ Name = "Car", Size = UDim2.fromOffset(980, 330), Position = UDim2.new(0.5, 0, 1, -24), AnchorPoint = Vector2.new(0.5, 1), Visible = false, Parent = ctx.HUD })
	local _holder, body = UIKit.Panel({ Parent = root, Size = UDim2.fromScale(1, 1), Color = C.Night, Tilt = -1, Tape = true, Pad = 22 })

	local title = UIKit.Title({ Text = "MOM'S CAR", TextSize = 44, Color = C.Mint, Stroke = 4, XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(320, 50), Position = UDim2.fromOffset(6, 0), Parent = body })
	local count = UIKit.Title({ Text = "1/5 PLAYERS", TextSize = 44, Color = C.Paper, Stroke = 4, XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(360, 50), Position = UDim2.fromOffset(300, 0), Parent = body })
	local countdown = UIKit.Label({ Text = "", Font = Theme.Font.Button, TextSize = Theme.Text.Body + 2, Color = C.Mustard, XAlign = Enum.TextXAlignment.Left, Size = UDim2.new(1, -240, 0, 40), Position = UDim2.fromOffset(6, 56), Parent = body })
	local friendHint = UIKit.Label({ Text = "", Font = Theme.Font.Body, TextSize = Theme.Text.Small, Color = C.Rose, Stroke = false, XAlign = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(420, 34), Position = UDim2.new(1, -6, 0, 60), AnchorPoint = Vector2.new(1, 0), Parent = body })

	local seats = UIKit.Box({ Name = "Seats", Size = UDim2.fromOffset(460, 84), Position = UDim2.fromOffset(6, 104), Parent = body })
	UIKit.List(seats, { Dir = Enum.FillDirection.Horizontal, Gap = 12, H = Enum.HorizontalAlignment.Left, V = Enum.VerticalAlignment.Center })

	-- driver controls (right side)
	local driver = UIKit.Box({ Name = "Driver", Size = UDim2.fromOffset(460, 190), Position = UDim2.new(1, 0, 0, 100), AnchorPoint = Vector2.new(1, 0), Parent = body })
	local pickLabel = UIKit.Label({ Text = "Start at", Font = Theme.Font.Body, TextSize = Theme.Text.Small, Color = C.PaperDim, Stroke = false, XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(460, 30), Parent = driver })
	local picker = UIKit.Box({ Name = "Picker", Size = UDim2.new(1, 0, 0, 70), Position = UDim2.fromOffset(0, 30), Parent = driver })
	UIKit.List(picker, { Dir = Enum.FillDirection.Horizontal, Gap = 8, H = Enum.HorizontalAlignment.Left, V = Enum.VerticalAlignment.Center })
	local friendsBtn = UIKit.Button({ Parent = driver, Text = "Anyone can ride", TextSize = 24, Color = C.Bruise, Size = UDim2.fromOffset(250, 76), Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1) })
	local goBtn = UIKit.Button({ Parent = driver, Text = "GO NOW", TextSize = 34, Color = C.Mint, Size = UDim2.fromOffset(190, 76), Position = UDim2.new(1, 0, 1, 0), AnchorPoint = Vector2.new(1, 1), OnClick = function()
		CarAction:FireServer("Go")
	end })
	local riderInfo = UIKit.Label({ Text = "", Font = Theme.Font.Body, TextSize = Theme.Text.Body, Color = C.PaperDim, Stroke = false, Rich = true, XAlign = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(460, 40), Position = UDim2.new(1, 0, 0, 116), AnchorPoint = Vector2.new(1, 0), Parent = body })

	local leaveBtn = UIKit.Button({ Parent = body, Text = "Get out", TextSize = 26, Color = C.PaperDim, Size = UDim2.fromOffset(200, 72), Position = UDim2.new(0, 6, 1, 0), AnchorPoint = Vector2.new(0, 1), OnClick = function()
		CarAction:FireServer("Leave")
	end })
	leaveBtn.Button.Modal = true
	-- gamepad: B = Get out (bound while the panel is up), shown as a glyph on the button
	local leaveHint = GamepadNav.Hint(leaveBtn.Button, Enum.KeyCode.ButtonB, nil, nil, 44)
	leaveHint.AnchorPoint = Vector2.new(0, 0.5)
	leaveHint.Position = UDim2.new(0, 8, 0.5, 0)
	leaveHint.ZIndex = 4

	local current: any = nil
	local countdownAt = 0
	local countdownVal: number? = nil
	local pickerButtons: { [number]: any } = {}
	local wasOpen = false

	friendsBtn.Button.Activated:Connect(function()
		if current and current.IsLeader then
			CarAction:FireServer("FriendsOnly", not current.FriendsOnly)
		end
	end)

	local pickerKey = ""
	local seatKey = ""
	local function rebuildPicker(checkpoints: { number }, selected: number, highest: number)
		local key = table.concat(checkpoints, ",") .. "/" .. highest
		if key == pickerKey then
			-- same buttons: just recolor (keeps gamepad focus stable across 1 Hz updates)
			for n, b in pickerButtons do
				b:SetColor(if n == selected then C.Mustard else C.NightDeep:Lerp(C.Bruise, 0.4))
			end
			return
		end
		pickerKey = key
		local sel = GuiService.SelectedObject
		local hadFocus = sel ~= nil and sel:IsDescendantOf(picker)
		for _, b in pickerButtons do
			b:Destroy()
		end
		table.clear(pickerButtons)
		for i, n in checkpoints do
			-- One tile per chapter (map) you've reached; beaten ones get a gold star.
			local chapter = MapConfig.ChapterFor(n)
			local beaten = highest >= chapter.LastNight
			local b = UIKit.Button({
				Parent = picker,
				Text = chapter.Short or tostring(n),
				TextSize = 20,
				Color = if n == selected then C.Mustard else C.NightDeep:Lerp(C.Bruise, 0.4),
				Size = UDim2.fromOffset(68, 70),
				Corner = Theme.Corner.Round,
				LayoutOrder = i,
				OnClick = function()
					CarAction:FireServer("StartNight", n)
				end,
			})
			if beaten then
				UIKit.Label({ Text = "★", Font = Theme.Font.Button, TextSize = 22, Color = C.Mustard, Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, -2, 0, 2), AnchorPoint = Vector2.new(1, 0), ZIndex = 6, Parent = b.Instance })
			end
			b.Button.SelectionImageObject = UIKit.SelectionImage("Round")
			b.Button.NextSelectionDown = friendsBtn.Button
			pickerButtons[n] = b
		end
		-- the focused night button was just rebuilt: keep focus on the picker
		local keep = pickerButtons[selected] or pickerButtons[checkpoints[1]]
		if hadFocus and keep then
			GamepadNav.Focus(keep.Button)
		end
		friendsBtn.Button.NextSelectionUp = keep and keep.Button or nil
		goBtn.Button.NextSelectionUp = keep and keep.Button or nil
	end

	local function refreshFriends(state: any)
		local n = 0
		for _, o in state.Occupants or {} do
			if isFriend(o.UserId) == true then
				n += 1
			end
		end
		if n > 0 then
			local pct = math.min(40, n * 10)
			friendHint.Text = `Friends in car: +{pct}% Candy`
		else
			friendHint.Text = if state.FriendsOnly then "Friends only" else "Ride with friends: +10% Candy each"
		end
	end

	local function render(state: any)
		current = state
		count.Text = `{state.Count or 0}/{state.Max or 5} PLAYERS`
		title.Text = "MOM'S CAR"
		-- seats (rebuilt only when the occupants change)
		local occKey = ""
		for _, o in state.Occupants or {} do
			occKey ..= tostring(o.UserId) .. ","
		end
		occKey ..= tostring(state.Max)
		if occKey ~= seatKey then
			seatKey = occKey
			for _, c in seats:GetChildren() do
				if c:IsA("GuiObject") then
					c:Destroy()
				end
			end
			local occ = state.Occupants or {}
			for i = 1, state.Max or 5 do
				local o = occ[i]
				if o then
					local shot = UIKit.Headshot({ Parent = seats, UserId = o.UserId, Size = 76, LayoutOrder = i, Color = if i == 1 then C.Mustard else C.Bruise })
					if i == 1 then
						UIKit.Tag({ Parent = shot, Text = "DRIVER", Color = C.Mustard, TextSize = 20, Position = UDim2.new(0.5, 0, 1, 2), AnchorPoint = Vector2.new(0.5, 0.5), Tilt = -4, ZIndex = 5 })
					end
				else
					local empty = UIKit.new("Frame", { BackgroundColor3 = C.NightDeep, BackgroundTransparency = 0.3, Size = UDim2.fromOffset(76, 76), LayoutOrder = i, Parent = seats })
					UIKit.Corner(empty, Theme.Corner.Round)
					UIKit.Stroke(empty, 3, C.PaperDim).Transparency = 0.5
				end
			end
		end
		-- countdown (interpolated)
		countdownVal = state.Countdown
		countdownAt = os.clock()
		-- driver section
		local leader = state.IsLeader == true
		driver.Visible = leader
		riderInfo.Visible = not leader
		if leader then
			friendsBtn:SetText(if state.FriendsOnly then "Friends only" else "Anyone can ride")
			friendsBtn:SetColor(if state.FriendsOnly then C.Rose else C.Bruise)
			rebuildPicker(state.Checkpoints or { 1 }, state.StartNight or 1, state.Highest or 0)
			local ch = MapConfig.ChapterFor(state.StartNight or 1)
			pickLabel.Text = `Map: {ch.Name} · Nights {ch.FirstNight}–{ch.LastNight}`
		else
			local sn = state.StartNight or 1
			riderInfo.Text = `Driver picked <font color="#E0B04F">{MapConfig.ChapterFor(sn).Name}</font> · Night {sn}`
		end
		refreshFriends(state)
		goBtn.Instance.Visible = leader and not state.Departing
		leaveBtn.Instance.Visible = not state.Departing
		-- gamepad: a sensible chain
		leaveBtn.Button.NextSelectionRight = if leader then friendsBtn.Button else nil
		friendsBtn.Button.NextSelectionLeft = leaveBtn.Button
		friendsBtn.Button.NextSelectionRight = goBtn.Button
		goBtn.Button.NextSelectionLeft = friendsBtn.Button
		-- became / stopped being the driver: don't leave focus on a hidden button
		local sel = GuiService.SelectedObject
		if sel and sel:IsDescendantOf(root) then
			local node: Instance? = sel
			while node and node ~= root do
				if node:IsA("GuiObject") and not node.Visible then
					task.defer(GamepadNav.FocusBest, true)
					break
				end
				node = node.Parent
			end
		end
	end

	local function open(state: any)
		render(state)
		if not wasOpen then
			wasOpen = true
			root.Visible = true
			root.Position = UDim2.new(0.5, 0, 1, 360)
			UIKit.Tween(root, 0.4, { Position = UDim2.new(0.5, 0, 1, -24) }, Enum.EasingStyle.Back)
			UIState.Play("CarDoor")
			ContextActionService:BindActionAtPriority("UICarBack", function(_, st)
				if MenuHost.Current() or not wasOpen or (current and current.Departing) then
					return Enum.ContextActionResult.Pass
				end
				if st == Enum.UserInputState.Begin then
					CarAction:FireServer("Leave")
				end
				return Enum.ContextActionResult.Sink
			end, false, Enum.ContextActionPriority.High.Value + 20, Enum.KeyCode.ButtonB)
			if UIState.Input == "Gamepad" and not MenuHost.Current() then
				task.defer(function()
					GamepadNav.Focus(if state.IsLeader then goBtn.Button else leaveBtn.Button)
				end)
			end
		end
	end

	-- Sticky: after a menu closes (or the pad wakes up) focus comes back to the car panel.
	GamepadNav.AddZone("CarPanel", {
		Priority = 50,
		Sticky = true,
		Get = function()
			if not wasOpen or not current then
				return nil
			end
			return if current.IsLeader and goBtn.Instance.Visible then goBtn.Button else leaveBtn.Button
		end,
	})

	local function close()
		if not wasOpen then
			return
		end
		wasOpen = false
		current = nil
		ContextActionService:UnbindAction("UICarBack")
		UIKit.Tween(root, 0.25, { Position = UDim2.new(0.5, 0, 1, 360) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Once(function()
			if not wasOpen then
				root.Visible = false
			end
		end)
		if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(root) then
			GuiService.SelectedObject = nil
		end
	end

	Net.Event("CarState").OnClientEvent:Connect(function(state)
		if typeof(state) == "table" then
			open(state)
		else
			close()
		end
	end)

	-- Getting out: WE own our character's physics, so stand up and step behind the van here
	-- (a server-only move gets undone by the client still sitting in the seat).
	Net.Event("CarExit").OnClientEvent:Connect(function(target)
		if typeof(target) ~= "CFrame" then
			return
		end
		local char = Players.LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not char or not hum then
			return
		end
		hum.Sit = false
		local seat = hum.SeatPart
		local weld = seat and seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		task.wait()
		char:PivotTo(target)
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end)

	-- countdown ticker + friend cache warm-up
	task.spawn(function()
		local last = -1
		while true do
			if current then
				if current.Departing then
					countdown.Text = "Buckle up!"
				elseif typeof(countdownVal) == "number" then
					local left = math.max(0, math.ceil(countdownVal - (os.clock() - countdownAt)))
					countdown.Text = `LEAVING FOR GRANDMA'S IN {left}…`
					if left ~= last then
						last = left
						if left <= 5 then
							UIKit.Pop(countdown :: any, 1.15, 0.2)
							UIState.Play("Countdown")
						end
					end
				else
					countdown.Text = "Waiting for more kids…"
				end
				refreshFriends(current)
			end
			task.wait(0.2)
		end
	end)

	-- ============================================================ departure
	local fade = UIKit.new("Frame", { Name = "Departure", BackgroundColor3 = C.Ink, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Active = true, Parent = ctx.Fade })
	Net.Event("CarDepart").OnClientEvent:Connect(function()
		for _, c in fade:GetChildren() do
			c:Destroy()
		end
		fade.Visible = true
		fade.BackgroundTransparency = 1
		UIKit.Tween(fade, 0.8, { BackgroundTransparency = 0 })
		UIState.Play("CarEngine")
		local center = UIKit.Box({ Size = UDim2.fromOffset(900, 360), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Parent = fade })
		UIKit.Title({ Text = "Off to Grandma's…", TextSize = 84, Color = C.Paper, Stroke = 6, Size = UDim2.new(1, 0, 0, 100), Crooked = 5, Parent = center })
		UIKit.Label({ Text = "Remember: don't. make. a. sound.", Font = Theme.Font.Body, TextSize = Theme.Text.Header - 6, Color = C.Rose, Size = UDim2.new(1, 0, 0, 50), Position = UDim2.fromOffset(0, 100), Parent = center })
		-- road + dashes scrolling under a bouncing minivan
		local road = UIKit.new("Frame", { BackgroundColor3 = C.NightDeep, Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 1, -40), ClipsDescendants = true, Parent = center })
		UIKit.Corner(road, UDim.new(0, 12))
		local dashes = UIKit.Box({ Size = UDim2.new(2, 0, 0, 8), Position = UDim2.new(0, 0, 0.5, -4), Parent = road })
		UIKit.List(dashes, { Dir = Enum.FillDirection.Horizontal, Gap = 40, H = Enum.HorizontalAlignment.Left })
		for i = 1, 30 do
			local d = UIKit.new("Frame", { BackgroundColor3 = C.Mustard, Size = UDim2.fromOffset(50, 8), LayoutOrder = i, Parent = dashes })
			UIKit.Corner(d, UDim.new(0.5, 0))
		end
		TweenService:Create(dashes, TweenInfo.new(0.6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Position = UDim2.new(0, -90, 0.5, -4) }):Play()
		local van = minivan(center)
		van.Position = UDim2.new(0.5, -110, 1, -150)
		if not UIState.ReduceMotion then
			TweenService:Create(van, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = UDim2.new(0.5, -110, 1, -156) }):Play()
		end
		-- The teleport normally takes us away. If it doesn't (Studio), fade back in.
		task.delay(14, function()
			UIKit.Tween(fade, 0.8, { BackgroundTransparency = 1 }).Completed:Once(function()
				fade.Visible = false
				for _, c in fade:GetChildren() do
					c:Destroy()
				end
			end)
		end)
	end)
end

return CarPanel
