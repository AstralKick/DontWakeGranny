--!strict
-- UIIcons
-- Doodle icons drawn from Frames (no image assets, no emoji). Every icon fills the
-- host it's given (Scale-sized), uses the same ink stroke weight and the palette.
--   UIIcons.<Name>(host: GuiObject, color?: Color3) -> ()
-- Names: Candy, Sack, Lungs, Eye, EyeClosed, Battery, Shoe, WindupToy, Cookie, FizzySoda,
--        Bag, Hanger, Book, Clipboard, Knobs, Friends, Mailbox, Pumpkin, Trophy, Lock, X

local Theme = require(script.Parent:WaitForChild("UITheme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))

local C = Theme.Color
local UIIcons = {}

-- A filled blob: pos/size in host Scale, corner (0..0.5), rotation.
local function blob(host: Instance, color: Color3, px: number, py: number, sx: number, sy: number, corner: number?, rot: number?, stroke: number?, z: number?): Frame
	local f = UIKit.new("Frame", {
		BackgroundColor3 = color,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(px, py),
		Size = UDim2.fromScale(sx, sy),
		Rotation = rot or 0,
		ZIndex = (z or 0) + ((host :: any).ZIndex or 1),
		Parent = host,
	})
	UIKit.Corner(f, UDim.new(corner or 0.5, 0))
	if stroke ~= 0 then
		UIKit.Stroke(f, stroke or 3, C.Ink)
	end
	return f
end
UIIcons.Blob = blob

function UIIcons.Candy(host: Instance, color: Color3?)
	local c = color or C.Mustard
	blob(host, c, 0.16, 0.5, 0.34, 0.42, 0.25, 45)
	blob(host, c, 0.84, 0.5, 0.34, 0.42, 0.25, 45)
	local core = blob(host, c, 0.5, 0.5, 0.56, 0.56, 0.5, 0, 3, 1)
	-- one stripe
	blob(core, C.Rose, 0.5, 0.5, 0.22, 1.02, 0.5, 30, 0, 1)
end

function UIIcons.Sack(host: Instance, color: Color3?)
	local c = color or C.Paper
	blob(host, c, 0.5, 0.6, 0.8, 0.72, 0.38)
	blob(host, c, 0.5, 0.2, 0.34, 0.2, 0.3, -8, 3, 1)
	blob(host, C.Mustard, 0.5, 0.3, 0.46, 0.1, 0.5, 4, 3, 2)
	-- a patch, because Grandma mended it
	blob(host, C.Rose, 0.68, 0.7, 0.2, 0.2, 0.2, 12, 2, 2)
end

function UIIcons.Lungs(host: Instance, color: Color3?)
	local c = color or C.Rose
	blob(host, c, 0.3, 0.58, 0.38, 0.7, 0.45, 10)
	blob(host, c, 0.7, 0.58, 0.38, 0.7, 0.45, -10)
	blob(host, C.PaperDim, 0.5, 0.2, 0.1, 0.36, 0.5, 0, 3, 1)
end

function UIIcons.Eye(host: Instance, color: Color3?)
	local white = blob(host, color or C.Paper, 0.5, 0.5, 0.95, 0.55, 0.5)
	blob(white, C.Ink, 0.55, 0.52, 0.42, 0.78, 0.5, 0, 0, 1)
	blob(white, C.Paper, 0.64, 0.38, 0.14, 0.22, 0.5, 0, 0, 2)
end

function UIIcons.EyeClosed(host: Instance, color: Color3?)
	blob(host, color or C.Ink, 0.5, 0.5, 0.9, 0.12, 0.5, 0, 0)
	for i, x in { 0.25, 0.5, 0.75 } do
		blob(host, color or C.Ink, x, 0.64, 0.07, 0.22, 0.5, (i - 2) * 18, 0)
	end
end

function UIIcons.Battery(host: Instance, color: Color3?)
	local body = blob(host, C.NightDeep, 0.46, 0.5, 0.8, 0.52, 0.22)
	blob(host, C.Ink, 0.92, 0.5, 0.08, 0.24, 0.3, 0, 0)
	blob(body, color or C.Mint, 0.5, 0.5, 0.82, 0.62, 0.2, 0, 0, 1)
end

function UIIcons.Shoe(host: Instance, color: Color3?)
	blob(host, color or C.Rose, 0.44, 0.42, 0.44, 0.5, 0.35, -6)
	blob(host, color or C.Rose, 0.56, 0.62, 0.84, 0.32, 0.5, 0, 3, 1)
	blob(host, C.Paper, 0.56, 0.78, 0.84, 0.1, 0.5, 0, 3, 2)
end

function UIIcons.WindupToy(host: Instance, color: Color3?)
	blob(host, color or C.Mint, 0.42, 0.58, 0.64, 0.6, 0.45)
	blob(host, C.Ink, 0.3, 0.5, 0.1, 0.1, 0.5, 0, 0, 1)
	blob(host, C.Mustard, 0.86, 0.5, 0.1, 0.34, 0.3, 0, 3, 1)
	blob(host, C.Mustard, 0.86, 0.32, 0.26, 0.12, 0.5, 0, 3, 2)
	blob(host, C.Mustard, 0.86, 0.68, 0.26, 0.12, 0.5, 0, 3, 2)
end

function UIIcons.Cookie(host: Instance, color: Color3?)
	local c = blob(host, color or Color3.fromRGB(196, 140, 80), 0.5, 0.5, 0.86, 0.86, 0.5)
	for _, d in { { 0.3, 0.35 }, { 0.62, 0.3 }, { 0.45, 0.62 }, { 0.72, 0.64 } } do
		blob(c, C.Ink, d[1], d[2], 0.14, 0.14, 0.5, 0, 0, 1)
	end
	-- a bite
	blob(host, C.Night, 0.86, 0.2, 0.3, 0.3, 0.5, 0, 0, 1).BackgroundTransparency = 1
end

function UIIcons.FizzySoda(host: Instance, color: Color3?)
	blob(host, color or C.Rose, 0.5, 0.62, 0.5, 0.66, 0.25)
	blob(host, color or C.Rose, 0.5, 0.24, 0.22, 0.24, 0.2, 0, 3, 1)
	blob(host, C.Paper, 0.5, 0.64, 0.5, 0.2, 0.1, 0, 3, 2)
	blob(host, C.Mustard, 0.5, 0.1, 0.28, 0.1, 0.4, 0, 3, 2)
end

function UIIcons.Bag(host: Instance, color: Color3?)
	blob(host, color or C.Rose, 0.5, 0.62, 0.8, 0.66, 0.22)
	local handle = blob(host, C.Ink, 0.5, 0.24, 0.4, 0.3, 0.5, 0, 0)
	handle.BackgroundTransparency = 1
	UIKit.Stroke(handle, 4, C.Ink)
	UIIcons.Candy(UIKit.Box({ Size = UDim2.fromScale(0.5, 0.4), Position = UDim2.fromScale(0.25, 0.44), Parent = host, ZIndex = ((host :: any).ZIndex or 1) + 2 }))
end

function UIIcons.Hanger(host: Instance, color: Color3?)
	blob(host, color or C.Mint, 0.5, 0.62, 0.9, 0.2, 0.5, 0)
	blob(host, color or C.Mint, 0.3, 0.46, 0.5, 0.12, 0.5, -28)
	blob(host, color or C.Mint, 0.7, 0.46, 0.5, 0.12, 0.5, 28)
	blob(host, C.Mustard, 0.5, 0.2, 0.16, 0.24, 0.5, 0, 3, 1)
end

function UIIcons.Book(host: Instance, color: Color3?)
	blob(host, color or C.Bruise, 0.5, 0.5, 0.74, 0.86, 0.14, -4)
	blob(host, C.Paper, 0.58, 0.5, 0.5, 0.74, 0.08, -4, 2, 1)
	blob(host, C.Blood, 0.66, 0.1, 0.1, 0.3, 0.2, -4, 2, 2)
end

function UIIcons.Clipboard(host: Instance, color: Color3?)
	blob(host, Color3.fromRGB(176, 128, 88), 0.5, 0.54, 0.74, 0.88, 0.14)
	blob(host, color or C.Paper, 0.5, 0.58, 0.58, 0.68, 0.08, 0, 2, 1)
	blob(host, C.PaperDim, 0.5, 0.12, 0.36, 0.14, 0.4, 0, 3, 2)
	for i = 1, 3 do
		blob(host, C.Mint, 0.3, 0.36 + i * 0.14, 0.1, 0.1, 0.3, 0, 2, 2)
		blob(host, C.Ink, 0.58, 0.36 + i * 0.14, 0.32, 0.05, 0.5, 0, 0, 2)
	end
end

function UIIcons.Knobs(host: Instance, color: Color3?)
	for i, x in { 0.3, 0.62, 0.45 } do
		local y = 0.2 + i * 0.2
		blob(host, C.Ink, 0.5, y, 0.8, 0.07, 0.5, 0, 0)
		blob(host, color or C.Rose, x, y, 0.24, 0.24, 0.5, 0, 3, 1)
	end
end

function UIIcons.Friends(host: Instance, color: Color3?)
	blob(host, C.Bruise, 0.32, 0.4, 0.34, 0.34, 0.5)
	blob(host, C.Bruise, 0.32, 0.82, 0.54, 0.34, 0.45)
	blob(host, color or C.Rose, 0.66, 0.36, 0.38, 0.38, 0.5, 0, 3, 2)
	blob(host, color or C.Rose, 0.66, 0.82, 0.6, 0.38, 0.45, 0, 3, 2)
end

function UIIcons.Mailbox(host: Instance, color: Color3?)
	blob(host, C.Ink, 0.46, 0.8, 0.1, 0.4, 0.2, 0, 0)
	blob(host, color or C.Mint, 0.46, 0.4, 0.8, 0.5, 0.45)
	blob(host, C.Blood, 0.84, 0.22, 0.08, 0.34, 0.2, 0, 2, 1)
	blob(host, C.Blood, 0.9, 0.1, 0.18, 0.12, 0.2, 0, 2, 1)
end

function UIIcons.Pumpkin(host: Instance, lit: boolean?)
	local body = blob(host, if lit then C.Pumpkin else C.PaperDim:Lerp(C.Night, 0.4), 0.5, 0.58, 0.9, 0.74, 0.5)
	blob(host, C.Mint:Lerp(C.Ink, 0.4), 0.52, 0.14, 0.12, 0.2, 0.3, 12, 3, 1)
	local face = if lit then C.Mustard else C.Ink
	blob(body, face, 0.3, 0.38, 0.18, 0.18, 0.1, 45, 0, 1)
	blob(body, face, 0.7, 0.38, 0.18, 0.18, 0.1, 45, 0, 1)
	blob(body, face, 0.5, 0.72, 0.5, 0.14, 0.4, 0, 0, 1)
end

function UIIcons.Trophy(host: Instance, color: Color3?)
	blob(host, color or C.Mustard, 0.5, 0.36, 0.64, 0.5, 0.4)
	blob(host, color or C.Mustard, 0.5, 0.7, 0.14, 0.24, 0.2, 0, 3, 1)
	blob(host, C.Night, 0.5, 0.88, 0.5, 0.12, 0.3, 0, 3, 1)
end

function UIIcons.Lock(host: Instance, color: Color3?)
	local shackle = blob(host, C.Ink, 0.5, 0.32, 0.46, 0.46, 0.5, 0, 0)
	shackle.BackgroundTransparency = 1
	UIKit.Stroke(shackle, 5, C.Ink)
	blob(host, color or C.PaperDim, 0.5, 0.66, 0.74, 0.54, 0.2, 0, 3, 1)
	blob(host, C.Ink, 0.5, 0.64, 0.1, 0.2, 0.5, 0, 0, 2)
end

function UIIcons.X(host: Instance, color: Color3?)
	blob(host, color or C.Blood, 0.5, 0.5, 0.95, 0.2, 0.5, 45)
	blob(host, color or C.Blood, 0.5, 0.5, 0.95, 0.2, 0.5, -45)
end

return UIIcons
