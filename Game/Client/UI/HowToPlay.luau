--!strict
-- HowToPlay (Match)
-- The objective, said plainly, the moment a new player's night starts:
--   1 STEAL the things on tonight's list (+ any loot; it goes in your pillowcase)
--   2 STASH it in Mom's trunk (stashed = safe; whole list stashed = home early)
--   3 HIDE if she wakes (look for the HIDE signs), or survive till 6 AM
-- Shown ~1.5 s into Night 1, and on any night for players who have never survived one
-- (profile HighestNight == 0); once per session. [GOT IT] or auto after 11 s.
-- Also: the first time Grandma wakes on Nights 1-3, a toast says to hide.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))
local UIState = require(script.Parent:WaitForChild("UIState"))
local NotifyScreen = require(script.Parent:WaitForChild("NotifyScreen"))

local C = Theme.Color
local HowToPlay = {}

local SHOW_AFTER = 1.5
local AUTO_HIDE = 11
local AWAKE = { Waking = true, Searching = true, Chasing = true, Patrolling = true, CheckingHiding = true }

function HowToPlay.Mount(ctx: any)
	local MS = ReplicatedStorage:WaitForChild("MatchState") :: Folder
	local Data = UIState.Data()
	local shownThisSession = false
	local current: Frame? = nil

	local function close()
		local card = current
		current = nil
		if card then
			UIKit.PopOut(card, 0.2).Completed:Once(function()
				card:Destroy()
			end)
		end
	end

	local function step(parent: Instance, order: number, icon: (Instance, Color3?) -> (), iconColor: Color3?, disc: Color3, head: string, text: string)
		local col = UIKit.Box({ Name = "Step" .. order, Size = UDim2.new(1 / 3, -12, 1, 0), LayoutOrder = order, Parent = parent })
		UIKit.List(col, { Gap = 6, H = Enum.HorizontalAlignment.Center })
		local badge = UIKit.new("Frame", { BackgroundColor3 = disc, Size = UDim2.fromOffset(86, 86), LayoutOrder = 1, Parent = col })
		UIKit.Corner(badge, Theme.Corner.Round)
		UIKit.Stroke(badge, 4, C.Ink)
		local art = UIKit.Box({ Size = UDim2.fromScale(0.66, 0.66), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Parent = badge })
		icon(art, iconColor)
		UIKit.Label({ Text = `{order}. {head}`, Font = Theme.Font.Button, TextSize = 30, Color = C.Ink, Stroke = false, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = 2, Parent = col })
		UIKit.Label({
			Text = text,
			Font = Theme.Font.Body,
			TextSize = Theme.Text.Small + 2,
			Color = C.Bruise,
			Stroke = false,
			Wrap = true,
			Size = UDim2.new(1, 0, 0, 58),
			LayoutOrder = 3,
			Parent = col,
		})
	end

	local function show()
		shownThisSession = true
		local holder, body = UIKit.Panel({
			Name = "HowToPlay",
			Parent = ctx.Overlay,
			Size = UDim2.fromOffset(880, 330),
			Position = UDim2.fromScale(0.5, 0.42),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = C.Paper,
			Tilt = -1,
			Tape = true,
			Pad = 22,
		})
		current = holder
		UIKit.List(body, { Gap = 8, H = Enum.HorizontalAlignment.Center })
		UIKit.Title({ Text = "HOW TO PLAY", TextSize = 42, Color = C.Rose, Stroke = 4, Size = UDim2.new(1, 0, 0, 48), LayoutOrder = 1, Crooked = 3, Parent = body })
		local row = UIKit.Box({ Size = UDim2.new(1, 0, 0, 190), LayoutOrder = 2, Parent = body })
		UIKit.List(row, { Dir = Enum.FillDirection.Horizontal, Gap = 18, H = Enum.HorizontalAlignment.Center })
		step(row, 1, UIIcons.Candy, nil, C.Night, "STEAL", "Grab the things on tonight's list (top left), plus any shiny loot.")
		step(row, 2, UIIcons.Sack, nil, C.Mint, "STASH", "Put it in Mom's trunk. Whole list stashed = go home early!")
		step(row, 3, UIIcons.EyeClosed, C.Paper, C.Bruise, "HIDE", "She wakes to noise. Hide at the HIDE signs, or survive till 6 AM.")
		UIKit.Button({
			Parent = body,
			Text = "GOT IT",
			TextSize = 28,
			Color = C.Mint,
			Size = UDim2.fromOffset(220, 60),
			LayoutOrder = 3,
			OnClick = close,
		})
		UIKit.Pop(holder :: any, 0.7, 0.35)
		task.delay(AUTO_HIDE, function()
			if current == holder then
				close()
			end
		end)
	end

	local function newPlayer(): boolean
		local highest = Data:Get("HighestNight")
		return typeof(highest) ~= "number" or highest <= 0
	end

	-- "She's awake!" nudge, once per night on the learning nights.
	local wakeToastNight = 0
	local function onGrandmaState()
		local night = tonumber(MS:GetAttribute("Night")) or 1
		if night > 3 or MS:GetAttribute("Phase") ~= "Night" or wakeToastNight == night then
			return
		end
		local st = MS:GetAttribute("GrandmaState")
		if typeof(st) == "string" and AWAKE[st] then
			wakeToastNight = night
			NotifyScreen.Toast("She's awake! Run and HIDE at a HIDE sign, or stay very still.", "Bad")
		end
	end
	MS:GetAttributeChangedSignal("GrandmaState"):Connect(onGrandmaState)

	MS:GetAttributeChangedSignal("Phase"):Connect(function()
		local phase = MS:GetAttribute("Phase")
		if phase ~= "Night" then
			close()
			return
		end
		if shownThisSession then
			return
		end
		local night = tonumber(MS:GetAttribute("Night")) or 1
		task.delay(SHOW_AFTER, function()
			if MS:GetAttribute("Phase") == "Night" and not current and not shownThisSession and (night == 1 or newPlayer()) then
				show()
			end
		end)
	end)
end

return HowToPlay
