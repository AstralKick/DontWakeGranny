--!strict
-- LeaderboardBoard (Lobby)
-- SurfaceGui on workspace.Lobby.Leaderboard (Front face): "MOST NIGHTS SURVIVED",
-- top 10 from the board's attribute Rows (JSON [{Name, Night}]), live on change.
-- Looks like a hand-written chalkboard sign pinned to the fence.

local HttpService = game:GetService("HttpService")

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UIIcons = require(script.Parent:WaitForChild("UIIcons"))

local C = Theme.Color
local LeaderboardBoard = {}

local function boardPart(board: Instance): BasePart?
	if board:IsA("BasePart") then
		return board
	end
	if board:IsA("Model") and board.PrimaryPart then
		return board.PrimaryPart
	end
	local named = board:FindFirstChild("Board", true) or board:FindFirstChild("Screen", true)
	if named and named:IsA("BasePart") then
		return named
	end
	local best: BasePart? = nil
	for _, d in board:GetDescendants() do
		if d:IsA("BasePart") and (not best or d.Size.Magnitude > best.Size.Magnitude) then
			best = d
		end
	end
	return best
end

function LeaderboardBoard.Mount(ctx: any)
	local lobby = workspace:WaitForChild("Lobby", 30)
	local board = lobby and lobby:WaitForChild("Leaderboard", 30)
	if not board then
		return
	end
	local part = boardPart(board)
	if not part then
		return
	end

	local gui = UIKit.new("SurfaceGui", {
		Name = "DWG_Leaderboard",
		Adornee = part,
		Face = Enum.NormalId.Front,
		SizingMode = Enum.SurfaceGuiSizingMode.FixedSize,
		CanvasSize = Vector2.new(800, 1000),
		LightInfluence = 0.4,
		MaxDistance = 250,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = ctx.PlayerGui,
	})
	-- keep the canvas proportional to the face
	local sz = part.Size
	gui.CanvasSize = Vector2.new(math.clamp(math.floor(1000 * sz.X / math.max(0.1, sz.Y)), 600, 2400), 1000)

	local bg = UIKit.new("Frame", { BackgroundColor3 = C.Night, Size = UDim2.fromScale(1, 1), Parent = gui })
	UIKit.Stroke(bg, 10, C.Ink)
	UIKit.Corner(bg, UDim.new(0, 30))
	UIKit.Pad(bg, 30)
	local head = UIKit.Box({ Size = UDim2.new(1, 0, 0, 170), Parent = bg })
	UIKit.Label({ Text = "MOST NIGHTS", Font = Theme.Font.Title, TextSize = 76, Color = C.Mustard, Stroke = 5, Size = UDim2.new(1, 0, 0, 84), Parent = head })
	UIKit.Label({ Text = "SURVIVED", Font = Theme.Font.Title, TextSize = 64, Color = C.Paper, Stroke = 5, Size = UDim2.new(1, 0, 0, 70), Position = UDim2.fromOffset(0, 80), Rotation = -2, Parent = head })
	local list = UIKit.Box({ Size = UDim2.new(1, 0, 1, -190), Position = UDim2.fromOffset(0, 190), Parent = bg })
	UIKit.List(list, { Gap = 8 })

	local function render()
		for _, c in list:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local raw = board:GetAttribute("Rows")
		local ok, rows = pcall(HttpService.JSONDecode, HttpService, if typeof(raw) == "string" then raw else "[]")
		if not ok or typeof(rows) ~= "table" or #rows == 0 then
			UIKit.Label({ Text = "Nobody's brave enough yet.", Font = Theme.Font.Body, TextSize = 44, Color = C.PaperDim, Stroke = false, Size = UDim2.new(1, 0, 0, 80), Parent = list })
			return
		end
		for i = 1, math.min(10, #rows) do
			local r = rows[i]
			local row = UIKit.new("Frame", { BackgroundColor3 = if i == 1 then C.Mustard elseif i <= 3 then C.Paper else C.NightDeep, Size = UDim2.new(1, 0, 0, 66), Rotation = ((i * 17) % 3) - 1, LayoutOrder = i, Parent = list })
			UIKit.Corner(row, UDim.new(0, 16))
			UIKit.Stroke(row, 4, C.Ink)
			local dark = i > 3
			local ink = if dark then C.Paper else C.Ink
			UIKit.Label({ Text = `{i}.`, Font = Theme.Font.Title, TextSize = 42, Color = ink, Stroke = if dark then 3 else false, XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(80, 66), Position = UDim2.fromOffset(18, 0), Parent = row })
			UIKit.Label({ Text = tostring(r.Name or "???"), Font = Theme.Font.Button, TextSize = 38, Color = ink, Stroke = if dark then 3 else false, XAlign = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, -300, 1, 0), Position = UDim2.fromOffset(100, 0), Parent = row })
			UIKit.Label({ Text = `Night {r.Night or 0}`, Font = Theme.Font.Button, TextSize = 36, Color = if dark then C.Mustard else C.Blood, Stroke = if dark then 3 else false, XAlign = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(180, 66), Position = UDim2.new(1, -18, 0, 0), AnchorPoint = Vector2.new(1, 0), Parent = row })
			if (r.Night or 0) >= 31 then
				local pk = UIKit.Box({ Size = UDim2.fromOffset(50, 50), Position = UDim2.new(1, -210, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Parent = row })
				UIIcons.Pumpkin(pk, true)
			end
		end
	end
	board:GetAttributeChangedSignal("Rows"):Connect(render)
	render()
end

return LeaderboardBoard
