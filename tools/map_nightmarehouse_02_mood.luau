-- NightmareHouse step 2: palette shift, dead lamps / sickly lamps, scratched-out & crooked portraits, dolls, yard fog.
-- Run once per fresh clone (guarded by the NH_Mood attribute).
local NH = _G.NH
local B = NH.B
local C = NH.C
local M = Enum.Material
local V3 = Vector3.new
local CS = game:GetService("CollectionService")
local H = NH.root()
if H:GetAttribute("NH_Mood") then return "mood already applied (re-clone to redo)" end
H:SetAttribute("NH_Mood", true)
local out = {}

-- 1) palette: everything drifts towards bruised mauve; walls a bit more, the outside grey-violet
local skip = { Rooms = 1, LootSpawns = 1, PrizeSpawns = 1, SearchNodes = 1, PumpkinSpots = 1, PlayerSpawns = 1, MomsCar = 1, Corruption = 1, Nightmare = 1 }
local recol = 0
for _, top in H:GetChildren() do
	if not skip[top.Name] then
		local list = if top:IsA("BasePart") then { top } else top:GetDescendants()
		for _, p in list do
			if p:IsA("BasePart") and p.Transparency < 1 and p.Material ~= M.Neon then
				local k = 0.3
				if p.Material == M.Plaster then k = 0.42 end
				if top.Name == "Exterior" then
					k = if p.Material == M.Grass then 0.25 else 0.45
				end
				if p.Material == M.Glass and p.Name == "Glass" then
					p.Color = Color3.fromRGB(70, 22, 34)
				else
					p.Color = p.Color:Lerp(C.Tint, k)
				end
				recol += 1
			end
		end
	end
end
table.insert(out, "recoloured " .. recol)

-- 2) lamps: only a handful still work (sickly red / purple); the rest are dead fittings
local KEEP = {
	{ "CRT_TV", 12.4, -23.8 }, { "Lamp_hang", -5, -22 }, { "Lamp_hang", -27, 5 }, { "Lamp_sconce", 12, -6.1 },
	{ "Lamp_bare", -29, 27 }, { "Lamp_porch", -1.1, -36.7 }, { "Lamp_sconce", -12, -6.1, 23.1 }, { "Lamp_hang", 29, -21, 24.2 },
	{ "Lamp_bare", 16.5, 20 }, { "Lamp_bare", 0, 18 }, { "Lamp_candle", 44.2, -25 }, { "Lamp_bare", 22, 0, 39.1 },
}
local kept, dead, i = 0, 0, 0
for _, l in CS:GetTagged("Lamp") do
	if l:IsDescendantOf(H) then
		local p = l:GetPivot().Position
		local keep = false
		for _, k in KEEP do
			if l.Name == k[1] and math.abs(p.X - NH.OX - k[2]) < 0.6 and math.abs(p.Z - k[3]) < 0.6 and (not k[4] or math.abs(p.Y - k[4]) < 1) then keep = true end
		end
		local light = l:FindFirstChildWhichIsA("Light", true)
		local bulb = l:FindFirstChild("Bulb", true)
		if keep then
			i += 1
			local purple = i % 2 == 0
			if light then
				light.Color = if purple then C.Purple else C.Red
				light.Brightness = light.Brightness * 0.85
				light.Range = math.min(light.Range, 18)
			end
			if bulb and l.Name ~= "CRT_TV" then bulb.Color = if purple then Color3.fromRGB(200, 150, 255) else Color3.fromRGB(255, 120, 120) end
			if l.Name == "CRT_TV" and bulb then bulb.Color = Color3.fromRGB(120, 96, 150) end
			kept += 1
		else
			CS:RemoveTag(l, "Lamp")
			l:SetAttribute("Area", nil)
			if light then light:Destroy() end
			if bulb then
				bulb.Material = M.Glass
				bulb.Color = C.DeadBulb
				bulb.Name = "DeadBulb"
			end
			dead += 1
		end
	end
end
table.insert(out, ("lamps kept %d, dead %d"):format(kept, dead))

-- 3) portraits: crooked, faces scratched out
local r = NH.rng(31)
local pics, scratched = 0, 0
for _, m in H:GetDescendants() do
	if m:IsA("Model") and (m.Name == "Picture" or m.Name == "GrandpaPortrait" or m.Name == "ShrinePortrait") then
		local frame = m:FindFirstChild("Frame") or m:FindFirstChild("Back")
		if frame then
			pics += 1
			local ang = math.rad((r:NextNumber() < 0.5 and -1 or 1) * r:NextNumber(6, 17))
			local cen = frame.CFrame
			local rot = cen * CFrame.Angles(0, 0, ang) * cen:Inverse()
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") then p.CFrame = rot * p.CFrame end
			end
			local head = m:FindFirstChild("Head")
			local canvas = m:FindFirstChild("Canvas")
			local target = head or canvas
			if target then
				local sz = if head then head.Size.Y * 1.35 else math.min(canvas.Size.X, canvas.Size.Y) * 0.8
				local base = CFrame.new(target.Position) * frame.CFrame.Rotation * CFrame.new(0, 0, if head then -0.06 else -0.04)
				for s = 1, 5 do
					local a = math.rad(-60 + s * 24 + r:NextNumber(-8, 8))
					B.part(m, "Scratch", V3(sz * r:NextNumber(0.8, 1.05), 0.07, 0.02), base * CFrame.new(r:NextNumber(-0.08, 0.08) * sz, r:NextNumber(-0.1, 0.1) * sz, -0.01 * s) * CFrame.Angles(0, 0, a), C.Scratch, M.SmoothPlastic, { small = true })
				end
				if head then head.Color = Color3.fromRGB(40, 30, 34) end
				for _, e in m:GetChildren() do
					if e.Name == "Eye" then e.Color = C.Red end
				end
				scratched += 1
			end
		end
	end
end
table.insert(out, ("pictures tilted %d, scratched %d"):format(pics, scratched))

-- 4) yard fog (low layers + slow drifting particles), non-colliding
local fog = NH.fresh("YardFog")
for i2, y in { 0.5, 1.4, 2.6 } do
	local p = NH.box(fog, "FogLayer", -64, y, -95, 64, y + 0.05, -36.6, C.Fog, M.SmoothPlastic, { small = true, tr = 0.86 + i2 * 0.03 })
	p.CanQuery = false
end
for _, xz in { { -40, -60 }, { -10, -80 }, { 20, -55 }, { 45, -80 }, { 0, -45 }, { -50, -85 } } do
	local e = NH.box(fog, "FogEmitter", xz[1] - 6, 0, xz[2] - 6, xz[1] + 6, 0.2, xz[2] + 6, C.Fog, M.SmoothPlastic, { inv = true })
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(110, 88, 140), Color3.fromRGB(70, 50, 90))
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.8), NumberSequenceKeypoint.new(1, 1) })
	pe.Size = NumberSequence.new(8, 14)
	pe.Lifetime = NumberRange.new(10, 14)
	pe.Rate = 1.2
	pe.Speed = NumberRange.new(0.4, 1)
	pe.SpreadAngle = Vector2.new(180, 10)
	pe.EmissionDirection = Enum.NormalId.Top
	pe.Acceleration = V3(0.3, -0.05, 0)
	pe.LightInfluence = 1
	pe.Parent = e
end
table.insert(out, "parts now " .. NH.count())
return table.concat(out, "\n")
