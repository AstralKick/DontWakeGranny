--!strict
-- ScreenFx
-- Image-free full-screen overlay helpers shared by the gameplay FX controllers.
--   ScreenFx.Gui(name, displayOrder)                -> ScreenGui (PlayerGui, full-bleed, persistent)
--   ScreenFx.Vignette(parent, color, thickness?)    -> Vignette  (:Set(alpha, color?), :Destroy())
--   ScreenFx.Fill(parent, color, zIndex?)           -> Frame     (full-screen, starts transparent)
-- A vignette is 4 edge frames whose UIGradients fade from opaque at the edge to clear inwards.

local Players = game:GetService("Players")

local ScreenFx = {}

ScreenFx.Colors = {
	Ink = Color3.fromRGB(42, 26, 36),
	Night = Color3.fromRGB(59, 42, 63),
	Paper = Color3.fromRGB(243, 233, 210),
	Rose = Color3.fromRGB(217, 122, 138),
	Mint = Color3.fromRGB(156, 197, 161),
	Mustard = Color3.fromRGB(224, 176, 79),
	Bruise = Color3.fromRGB(123, 92, 142),
	Blood = Color3.fromRGB(168, 50, 62),
}

function ScreenFx.Gui(name: string, displayOrder: number): ScreenGui
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local existing = pg:FindFirstChild(name)
	if existing and existing:IsA("ScreenGui") then
		return existing
	end
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.DisplayOrder = displayOrder
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.ScreenInsets = Enum.ScreenInsets.None
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = pg
	return g
end

function ScreenFx.Fill(parent: Instance, color: Color3, zIndex: number?): Frame
	local f = Instance.new("Frame")
	f.Name = "Fill"
	f.BorderSizePixel = 0
	f.BackgroundColor3 = color
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromScale(1, 1)
	f.ZIndex = zIndex or 1
	f.Active = false
	f.Visible = false
	f.Parent = parent
	return f
end

export type Vignette = {
	Frames: { Frame },
	Alpha: number,
	Set: (self: Vignette, alpha: number, color: Color3?) -> (),
	Destroy: (self: Vignette) -> (),
}

local EDGE_FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.4, 0.55),
	NumberSequenceKeypoint.new(1, 1),
})

function ScreenFx.Vignette(parent: Instance, color: Color3, thickness: number?): Vignette
	local th = thickness or 0.3
	local specs = {
		-- name, size, position, gradient rotation (0 keypoint = screen edge)
		{ "Top", UDim2.fromScale(1, th), UDim2.fromScale(0, 0), 90 },
		{ "Bottom", UDim2.fromScale(1, th), UDim2.fromScale(0, 1 - th), 270 },
		{ "Left", UDim2.fromScale(th * 0.75, 1), UDim2.fromScale(0, 0), 0 },
		{ "Right", UDim2.fromScale(th * 0.75, 1), UDim2.fromScale(1 - th * 0.75, 0), 180 },
	}
	local holder = Instance.new("Frame")
	holder.Name = "Vignette"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = parent
	local frames: { Frame } = {}
	for _, s in specs do
		local f = Instance.new("Frame")
		f.Name = s[1] :: string
		f.BorderSizePixel = 0
		f.BackgroundColor3 = color
		f.BackgroundTransparency = 1
		f.Size = s[2] :: UDim2
		f.Position = s[3] :: UDim2
		f.Visible = false
		local g = Instance.new("UIGradient")
		g.Rotation = s[4] :: number
		g.Transparency = EDGE_FADE
		g.Parent = f
		f.Parent = holder
		table.insert(frames, f)
	end
	local v = {} :: any
	v.Frames = frames
	v.Alpha = 0
	function v.Set(self: Vignette, alpha: number, c: Color3?)
		alpha = math.clamp(alpha, 0, 1)
		if math.abs(alpha - self.Alpha) < 0.002 and not c then
			return
		end
		self.Alpha = alpha
		for _, f in self.Frames do
			f.BackgroundTransparency = 1 - alpha
			f.Visible = alpha > 0.003
			if c then
				f.BackgroundColor3 = c
			end
		end
	end
	function v.Destroy(_self: Vignette)
		holder:Destroy()
	end
	return v :: Vignette
end

return ScreenFx
