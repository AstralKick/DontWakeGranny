--!strict
-- UITheme
-- Every color, font, size and motion token the UI uses. Nothing else in Game/Client/UI
-- should hard-code a Color3 or a Font. See docs/UI_STYLE.md.
--
-- Layout model (read this before adding screens):
--   Each ScreenGui has ONE "Root" frame with ONE UIScale driven by the viewport
--   (UIController). Root is sized 1/scale so it always covers the screen exactly.
--   Inside Root, POSITIONS use Scale (edge pinning with AnchorPoint) and component
--   SIZES are authored in 1080p "design pixels" (Offset), which the UIScale shrinks /
--   grows together with stroke widths and corner radii. Big menus size with Scale of
--   Root plus a UISizeConstraint so they fit a phone and don't sprawl on ultrawide.

local UITheme = {}

local rgb = Color3.fromRGB

UITheme.Color = {
	Ink = rgb(42, 26, 36),
	Night = rgb(59, 42, 63),
	NightDeep = rgb(38, 26, 42), -- inset wells, track backgrounds
	Paper = rgb(243, 233, 210),
	PaperDim = rgb(221, 207, 178), -- paper in shadow / disabled
	Rose = rgb(217, 122, 138),
	Mint = rgb(156, 197, 161),
	Mustard = rgb(224, 176, 79),
	Bruise = rgb(123, 92, 142),
	Blood = rgb(168, 50, 62),
	Pumpkin = rgb(255, 140, 20), -- Halloween night only
	Shadow = rgb(42, 26, 36),
}

-- Kind -> accent for world prompts and toasts.
UITheme.KindColor = {
	Loot = UITheme.Color.Paper,
	Prize = UITheme.Color.Mustard,
	Search = UITheme.Color.PaperDim,
	Door = UITheme.Color.Rose,
	Hide = UITheme.Color.Bruise,
	Bank = UITheme.Color.Mint,
	Diary = UITheme.Color.Paper,
	Objective = UITheme.Color.Pumpkin,
	Menu = UITheme.Color.Rose,
}

UITheme.ToastColor = {
	Candy = UITheme.Color.Mustard,
	Good = UITheme.Color.Mint,
	Bad = UITheme.Color.Blood,
	Info = UITheme.Color.Paper,
}

local function font(name: string, weight: Enum.FontWeight?): Font
	return Font.new(`rbxasset://fonts/families/{name}.json`, weight or Enum.FontWeight.Regular)
end

UITheme.Font = {
	Title = font("LuckiestGuy"), -- titles, big numbers
	Button = font("FredokaOne"), -- buttons, headers, HUD labels
	Body = font("PatrickHand"), -- flavor & body copy
	Note = font("SpecialElite"), -- diary pages, in-world notes
	Creep = font("Creepster"), -- ONE-WORD accents only ("RUN!", "AWAKE!")
}

-- Design-pixel sizes at 1080p (scaled by the root UIScale).
UITheme.Text = {
	Huge = 120, -- night card number
	Title = 72,
	Header = 44,
	Button = 34,
	Body = 30,
	Small = 25, -- never go below this: at the 0.5 phone clamp it's ~12.5pt
}

UITheme.Stroke = {
	Panel = 4, -- the one outline weight of the game (3px at 1080p reads thin on TVs)
	Text = 3,
	Thin = 2,
}

UITheme.Corner = {
	Panel = UDim.new(0, 28),
	Button = UDim.new(0.5, 0), -- pills
	Chip = UDim.new(0, 16),
	Round = UDim.new(0.5, 0),
}

UITheme.Shadow = {
	Offset = 6, -- hard offset shadow: an Ink copy shifted down
	Transparency = 0.55,
}

UITheme.Touch = {
	MinTarget = 88, -- design px; 44pt at the 0.5 phone clamp
}

UITheme.Motion = {
	Pop = 0.28,
	Close = 0.15,
	Squish = 0.07,
}

-- Viewport scale (see header). Clamped per UI_STYLE.md.
UITheme.BaseResolution = Vector2.new(1920, 1080)
UITheme.MinScale = 0.5
UITheme.MaxScale = 1.5

return UITheme
