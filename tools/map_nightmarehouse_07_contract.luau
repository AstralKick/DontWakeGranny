-- NightmareHouse step 7: contract pass + house-wide dressing. Exactly 5 PumpkinSpots, prize tidy-up, nightmare room
-- names, dolls everywhere, a vein cluster in every room, and Corruption/1..4 extras (always shown on nights 26-31 since
-- corruption is 4 there; all non-colliding decor). Guarded by NH_Contract.
local NH = _G.NH
local B, C, M, V3, OX = NH.B, NH.C, Enum.Material, Vector3.new, NH.OX
local H = NH.root()
if H:GetAttribute("NH_Contract") then return "contract pass already applied" end
H:SetAttribute("NH_Contract", true)
local out = {}
local SM = { small = true }
local function W(x, y, z) return V3(x + OX, y, z) end

-- 1) pumpkins: drop the 5 cloned spots, keep the 3 placed by the zone chunks, add the 2 ground ones
local keep = 0
for _, p in H.PumpkinSpots:GetChildren() do
	local lp = p.Position - V3(OX, 0, 0)
	local cloned = (lp - V3(38.5, 2.1, -25.5)).Magnitude < 0.5 or (lp - V3(-19, 2.1, 12)).Magnitude < 0.5 or (lp - V3(6, 15.1, -13)).Magnitude < 0.5 or (lp - V3(6, -10.9, 18)).Magnitude < 0.5 or (lp - V3(-22, 28.1, 6)).Magnitude < 0.5
	if cloned then p:Destroy() else keep += 1 end
end
NH.pumpkin("Ground", W(89.5, 2, -3), "+x") -- the end of the Long Hall, at the bricked door
NH.pumpkin("Ground", W(5.4, 2, -16.4), "+z") -- under the giant cracked clock, beside the throne
table.insert(out, ("pumpkins: kept %d zone spots + 2 ground = %d"):format(keep, #H.PumpkinSpots:GetChildren()))

-- 2) prize next to the throne moved clear of its pillar
for _, p in H.PrizeSpawns:GetChildren() do
	local lp = p.Position - V3(OX, 0, 0)
	if (lp - V3(15.9, 2.35, -12.3)).Magnitude < 0.5 then p.Position = W(17.2, 2.35, -13.4) end
end
-- invisible ramps should not be queryable
for _, d in H.Nightmare:GetDescendants() do
	if d:IsA("BasePart") and d.Name == "Ramp" then d.CanQuery = false end
end

-- 3) nightmare names for the rooms (display only; Instance names stay, the ground Bathroom keeps its Name)
local NAMES = {
	["Entry Hall"] = "The Wrong Foyer", ["Living Room"] = "The Throne Room", ["Dining Room"] = "The Upside-Down Dining Room",
	["Kitchen"] = "Grandma's Kitchen?", ["Hallway"] = "The Hallway", ["Den"] = "The Den (Ceiling Side)",
	["Grandma's Bedroom"] = "Her Bedroom", ["Kids' Old Room"] = "The Room That Was Yours", ["Upstairs Hallway"] = "The Upstairs Hall",
	["Basement Hall"] = "The Root Tunnel", ["Canning Cellar"] = "The Overgrown Cellar", ["Furnace Room"] = "The Furnace Roots",
}
for _, rm in H.Rooms:GetChildren() do
	if NAMES[rm.Name] then rm:SetAttribute("RoomName", NAMES[rm.Name]) end
end

-- 4) dolls everywhere: stood on the floor (raycast) facing into the room
local DF = NH.fresh("Dolls")
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = { H }
local function doll(x, y, z, face, s, col)
	local hit = workspace:Raycast(W(x, y + 3, z), V3(0, -6, 0), rp)
	if not hit then return end
	local p = hit.Position
	B.doll(DF, CFrame.lookAt(p, p + V3(face.X, 0, face.Z)), s or 1, col or (if (x + z) % 2 < 1 then C.Velvet else B.C.WPlum))
end
local spots = {
	{ -12, 2, -30.5, V3(1, 0, 0), 1.3 }, { 1.5, 2, -9, V3(-1, 0, -1), 1.1 }, { -35, 2, -33.5, V3(1, 0, 1), 1.2 },
	{ -44, 2, 18, V3(1, 0, 0), 1 }, { 11.5, 2, 33.5, V3(0, 0, -1), 1.4 }, { 44, 2, 33.5, V3(-1, 0, -1), 1.2 },
	{ -9.5, 2, 33.5, V3(0, 0, -1), 1.2 }, { 43.5, 2, -33.5, V3(-1, 0, 1), 1.3 }, { 21, 2, -33.8, V3(0, 0, 1), 1 },
	{ -43.5, 15, -33.5, V3(1, 0, 1), 1.2 }, { 11.5, 15, -33.5, V3(-1, 0, 1), 1.3 }, { 43.5, 15, 33.5, V3(-1, 0, -1), 1.1 },
	{ -43.5, 15, 33.5, V3(1, 0, -1), 1 }, { 43.5, 15, -8.5, V3(-1, 0, 0), 1.2 }, { -11.5, 15, 33.3, V3(0, 0, -1), 1.2 },
	{ -44, -11, -33.5, V3(1, 0, 1), 1.3 }, { 11.5, -11, 1.5, V3(0, 0, 1), 1.1 },
}
for _, s in spots do doll(s[1], s[2], s[3], s[4], s[5]) end
table.insert(out, "dolls " .. #DF:GetChildren())

-- 5) a vein cluster in every original ground/upstairs room (rays from the room centre to a wall)
local VF = NH.F("Veins", NH.F("Nightmare"))
local nv, i = 0, 0
local dirs = { V3(1, 0, 0.2), V3(-1, 0, -0.3), V3(0.2, 0, 1), V3(-0.3, 0, -1) }
for _, rm in H.Rooms:GetChildren() do
	local a = rm:GetAttribute("Area")
	if (a == "Ground" or a == "Upstairs") and rm.Size.Y <= 13 and rm.Name ~= "LongHall" and rm.Name ~= "WrongHall" then
		i += 1
		local c = rm.Position - V3(OX, 0, 0)
		local lo, hi = c - rm.Size / 2, c + rm.Size / 2
		local rb = { lo.X, lo.Y, lo.Z, hi.X, hi.Y, hi.Z }
		nv += NH.wallVein(VF, rb, V3(c.X, lo.Y + 9, c.Z), dirs[i % 4 + 1], 11, 700 + i, 2)
		if rm.Size.X * rm.Size.Z > 500 then
			nv += NH.wallVein(VF, rb, V3(c.X, lo.Y + 11.4, c.Z), V3(0, 1, 0), 12, 800 + i, 2)
		end
	end
end
table.insert(out, "room veins " .. nv)

-- 6) Corruption extras (non-colliding, non-queryable decor; EnvironmentService shows level <= corruption)
local CO = H.Corruption
local function deco(p)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end
-- 1: veins bleed through the ceiling of the entry, hall and throne room
local c1 = CO["1"]
local n1 = 0
for k, rbox in { { -13, 2, -35, 3, 14, -7 }, { -13, 2, -7, 45, 14, 1 }, { 3, 2, -35, 45, 14, -7 } } do
	local c = V3((rbox[1] + rbox[4]) / 2, 8, (rbox[3] + rbox[6]) / 2)
	n1 += NH.wallVein(c1, rbox, c, V3(0, 1, 0), 14, 900 + k, 2)
	n1 += NH.wallVein(c1, rbox, c + V3(4, 0, 0), V3(0, 1, 0), 10, 910 + k, 2)
end
-- 2: a crowd of dolls on the main stairs, all facing down at you
local c2 = CO["2"]
for k = 0, 4 do
	local z = 8 + k * 4
	local hit = workspace:Raycast(W(-9.5, 16, z), V3(0, -16, 0), rp)
	if hit then B.doll(c2, CFrame.lookAt(hit.Position, hit.Position + V3(0, 0, -1)), 1 + (k % 2) * 0.2, if k % 2 == 0 then C.Velvet else B.C.WPlum) end
end
-- 3: furniture floating in the Long Hall (deliberately airborne, slowly "drifting")
local c3 = CO["3"]
for k, x in { 58, 72, 86 } do
	local b = NH.CF(x, 8 + k * 0.6, -3, 20 * k) * CFrame.Angles(math.rad(12 * k), 0, math.rad(-9 * k))
	local ch = B.chair(c3, b, C.WoodMid:Lerp(C.Tint, 0.4))
	local _ = ch
end
-- 4: eyes in the dark windows (red Neon pairs just inside the glass)
local c4 = CO["4"]
local n4 = 0
for _, w in H:GetDescendants() do
	if w:IsA("Model") and w.Name == "Window" and w:FindFirstChild("Glass") and n4 < 10 then
		local g = w.Glass
		if (g.Position.X - OX + g.Position.Z * 3) % 3 < 1.2 then
			n4 += 1
			local inner = g.CFrame * CFrame.new(0, 0.6, -0.25)
			for _, sx in { -0.35, 0.35 } do
				B.part(c4, "Eye", V3(0.28, 0.16, 0.05), inner * CFrame.new(sx, 0, 0), C.Red, M.Neon, SM)
			end
		end
	end
end
for _, f in CO:GetChildren() do
	for _, d in f:GetDescendants() do
		if d:IsA("BasePart") then deco(d) end
	end
end
local cc = {}
for k = 1, 4 do
	local n = 0
	for _, d in CO[tostring(k)]:GetDescendants() do if d:IsA("BasePart") then n += 1 end end
	table.insert(cc, n)
end
table.insert(out, "corruption parts " .. table.concat(cc, "/"))
table.insert(out, "parts now " .. NH.count())
return table.concat(out, "\n")
