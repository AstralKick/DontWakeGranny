--!strict
-- FavoritePrompt (Match)
-- After a player SURVIVES a night, a small card slides in (bottom-right, after the morning
-- report has counted up): "Enjoying Grandma's? Favourite it so you can find her again
-- (and a thumbs-up helps a lot!)". [⭐ Favourite] opens Roblox's own favourite prompt for the
-- experience (the Lobby = start place), [Not now] closes it.
--
-- NO REWARDS: Roblox forbids giving anything in exchange for likes/favourites, so this is
-- only a friendly ask. Asked at most twice per player (the 2nd time in a later session, 20h+
-- later) and never again once they have favourited. State: profile Tutorial.FavAsks /
-- FavLastAt / Favorited, written through the "MarkTutorial" remote.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarEditorService = game:GetService("AvatarEditorService")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIState = require(script.Parent:WaitForChild("UIState"))

local C = Theme.Color
local FavoritePrompt = {}

local MAX_ASKS = 2
local REASK_AFTER = 20 * 3600 -- seconds between the 1st and 2nd ask
local SHOW_DELAY = 6.5 -- after the morning report arrives (lets the count-up finish)

function FavoritePrompt.Mount(ctx: any)
	local Net = UIState.Net()
	local Data = UIState.Data()
	local MS = ReplicatedStorage:WaitForChild("MatchState") :: Folder
	local PlaceConfig = UIState.Config("PlaceConfig")
	local experiencePlace = (PlaceConfig and PlaceConfig.LobbyPlaceId) or game.PlaceId

	local askedThisSession = false
	local current: Frame? = nil

	local function shouldAsk(): boolean
		if askedThisSession then
			return false
		end
		local t = Data:Get("Tutorial")
		if typeof(t) ~= "table" then
			return false
		end
		if t.Favorited == true then
			return false
		end
		local asks = tonumber(t.FavAsks) or 0
		if asks >= MAX_ASKS then
			return false
		end
		if asks > 0 and os.time() - (tonumber(t.FavLastAt) or 0) < REASK_AFTER then
			return false
		end
		return true
	end

	local function close()
		local card = current
		current = nil
		if card then
			UIKit.PopOut(card, 0.2).Completed:Once(function()
				card:Destroy()
			end)
		end
	end

	local function show()
		askedThisSession = true
		Net.Event("MarkTutorial"):FireServer("FavAsked")

		local holder, body = UIKit.Panel({
			Name = "FavoriteAsk",
			Parent = ctx.Overlay,
			Size = UDim2.fromOffset(470, 236),
			Position = UDim2.new(1, -28, 1, -28),
			AnchorPoint = Vector2.new(1, 1),
			Color = C.Paper,
			Tilt = 2,
			Tape = true,
			Pad = 20,
		})
		current = holder
		UIKit.List(body, { Gap = 6 })
		UIKit.Title({
			Text = "ENJOYING GRANDMA'S?",
			TextSize = 34,
			Color = C.Rose,
			Stroke = 3,
			Size = UDim2.new(1, 0, 0, 42),
			LayoutOrder = 1,
			Parent = body,
		})
		UIKit.Label({
			Text = "Favourite it so you can find her again tonight, and a 👍 on the game page helps us loads!",
			Font = Theme.Font.Body,
			TextSize = Theme.Text.Small + 1,
			Color = C.Ink,
			Stroke = false,
			Wrap = true,
			Size = UDim2.new(1, 0, 0, 58),
			LayoutOrder = 2,
			Parent = body,
		})
		local row = UIKit.Box({ Size = UDim2.new(1, 0, 0, 70), LayoutOrder = 3, Parent = body })
		UIKit.List(row, { Dir = Enum.FillDirection.Horizontal, Gap = 12, H = Enum.HorizontalAlignment.Center, V = Enum.VerticalAlignment.Center })
		local fav = UIKit.Button({
			Parent = row,
			Text = "⭐ Favourite",
			TextSize = 26,
			Color = C.Mustard,
			Size = UDim2.fromOffset(230, 64),
			LayoutOrder = 1,
			OnClick = function()
				local ok = pcall(function()
					AvatarEditorService:PromptSetFavorite(experiencePlace, Enum.AvatarItemType.Asset, true)
				end)
				if not ok then
					close()
				end
			end,
		})
		fav.Button.Modal = true
		UIKit.Button({
			Parent = row,
			Text = "Not now",
			TextSize = 22,
			Color = C.PaperDim,
			Size = UDim2.fromOffset(150, 64),
			LayoutOrder = 2,
			OnClick = close,
		})
		UIKit.Pop(holder :: any, 0.6, 0.35)
		UIState.Play("NewArea")
		-- Gone with the morning either way.
		task.delay(25, function()
			if current == holder then
				close()
			end
		end)
	end

	AvatarEditorService.PromptSetFavoriteCompleted:Connect(function(result)
		if result == Enum.AvatarPromptResult.Success then
			Net.Event("MarkTutorial"):FireServer("Favorited")
			close()
		elseif current then
			close()
		end
	end)

	Net.Event("NightSummary").OnClientEvent:Connect(function(summary)
		if typeof(summary) ~= "table" or summary.Survived ~= true then
			return
		end
		task.delay(SHOW_DELAY, function()
			if MS:GetAttribute("Phase") == "Morning" and not current and shouldAsk() then
				show()
			end
		end)
	end)
	MS:GetAttributeChangedSignal("Phase"):Connect(function()
		if MS:GetAttribute("Phase") ~= "Morning" and current then
			close()
		end
	end)
end

return FavoritePrompt
