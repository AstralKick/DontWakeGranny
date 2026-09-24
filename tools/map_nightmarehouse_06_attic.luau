-- NightmareHouse step 6 (Attic = THE NURSERY): the attic is a giant's nursery - an enormous cot you can climb into
-- (the Prize waits on its pillow), a mobile turning over it, giant letter blocks, a dolls' tea party, a moon night-light
-- and a huge toy chest you can hide in. Guarded by NH_Attic.
local NH = _G.NH
local B, C, M, V3, OX = NH.B, NH.C, Enum.Material, Vector3.new, NH.OX
local CS = game:GetService("CollectionService")
local H = NH.root()
if H:GetAttribute("NH_Attic") then return "attic already applied" end
H:SetAttribute("NH_Attic", true)
local out = {}
local SM = { small = true }
local SOLID = { solid = true }
local AF = NH.fresh("Nursery")
local FY = 28
local function W(x, y, z) return V3(x + OX, y, z) end

-- 1) clear the old attic clutter (keep hiding spots, searchable trunks, lamps, posts, railings, sheets, cobwebs)
local removed = 0
local picN = 0
for _, c in H.Attic:GetChildren() do
	local kill = c.Name:find("^Sheeted") or c.Name == "Box" or c.Name == "Easel" or c.Name == "Crib" or c.Name == "Crate" or c.Name == "Doll" or c.Name == "RockingChair"
	if c.Name == "Picture" then
		picN += 1
		kill = picN % 2 == 0 -- every other portrait goes
	end
	if kill and not NH.isProtected(c) then
		c:Destroy()
		removed += 1
	end
end
table.insert(out, "attic clutter removed " .. removed)

-- 2) THE COT (x -34..-18, z 2..14), rails 9.6 tall, mattress on a raised base, broken bars + blanket ramp at the front
local X0, X1, Z0, Z1 = -34, -18, 2, 14
local cot = B.model(AF, "GiantCot")
local wood = C.Cream:Lerp(C.Tint, 0.35)
local paint = C.Baby:Lerp(C.Tint, 0.3)
local RT = FY + 9.6 -- front top rail clears Grandma (5.5) walking up the ramp
for _, x in { X0, X1 } do
	for _, z in { Z0, Z1 } do
		NH.box(cot, "Post", x - 0.6, FY, z - 0.6, x + 0.6, RT + 0.6, z + 0.6, wood, M.Wood, SOLID)
		B.part(cot, "Finial", V3(0.8, 0.8, 0.8), CFrame.new(W(x, RT + 1.0, z)), paint, M.SmoothPlastic, { small = true, shape = Enum.PartType.Ball }) -- small: the back ones sit just under the rafters
	end
end
-- rails (top + bottom) on four sides
for _, z in { Z0, Z1 } do
	NH.box(cot, "Rail", X0 + 0.6, RT - 0.7, z - 0.35, X1 - 0.6, RT, z + 0.35, wood, M.Wood, SOLID)
	NH.box(cot, "Rail", X0 + 0.6, FY + 3, z - 0.35, X1 - 0.6, FY + 3.7, z + 0.35, wood, M.Wood, SOLID)
end
for _, x in { X0, X1 } do
	NH.box(cot, "Rail", x - 0.35, RT - 0.7, Z0 + 0.6, x + 0.35, RT, Z1 - 0.6, wood, M.Wood, SOLID)
	NH.box(cot, "Rail", x - 0.35, FY + 3, Z0 + 0.6, x + 0.35, FY + 3.7, Z1 - 0.6, wood, M.Wood, SOLID)
end
-- bars: the front (z = Z0) has a broken gap in the middle (x -28.5..-23.5)
local function bar(x, z, y0, y1)
	B.part(cot, "Bar", V3(y1 - y0, 0.45, 0.45), CFrame.new(W(x, (y0 + y1) / 2, z)) * CFrame.Angles(0, 0, math.rad(90)), wood, M.Wood, { solid = true, shape = Enum.PartType.Cylinder })
end
for x = X0 + 1.5, X1 - 1.4, 1.35 do
	bar(x, Z1, FY + 3.7, RT - 0.7)
	if x < -28.5 or x > -23.5 then
		bar(x, Z0, FY + 3.7, RT - 0.7)
	end
end
-- one snapped bar lying on the floor in front of the gap
B.part(cot, "FallenBar", V3(4.8, 0.45, 0.45), CFrame.new(W(-31.5, FY + 0.23, Z0 - 4.5)) * CFrame.Angles(0, math.rad(20), 0), wood, M.Wood, { small = true, shape = Enum.PartType.Cylinder })
for z = Z0 + 1.5, Z1 - 1.4, 1.35 do
	bar(X0, z, FY + 3.7, RT - 0.7)
	bar(X1, z, FY + 3.7, RT - 0.7)
end
-- the front rails (bottom AND top) are snapped where the bars are broken out: replace them with stubs
-- the front bottom rail is broken where the bars are: replace it with two stubs
for _, p in cot:GetChildren() do
	if p.Name == "Rail" and math.abs(p.Position.Z - Z0) < 0.1 then p:Destroy() end
end
NH.box(cot, "Rail", X0 + 0.6, FY + 3, Z0 - 0.35, -28.6, FY + 3.7, Z0 + 0.35, wood, M.Wood, SOLID)
NH.box(cot, "Rail", -23.4, FY + 3, Z0 - 0.35, X1 - 0.6, FY + 3.7, Z0 + 0.35, wood, M.Wood, SOLID)
NH.box(cot, "Rail", X0 + 0.6, RT - 0.7, Z0 - 0.35, -28.6, RT, Z0 + 0.35, wood, M.Wood, SOLID)
NH.box(cot, "Rail", -23.4, RT - 0.7, Z0 - 0.35, X1 - 0.6, RT, Z0 + 0.35, wood, M.Wood, SOLID)
B.part(cot, "Splinter", V3(0.9, 0.35, 0.3), CFrame.new(W(-28.4, RT - 0.45, Z0)) * CFrame.Angles(0, 0, math.rad(-25)), wood, M.Wood, SM)
B.part(cot, "Splinter", V3(0.9, 0.35, 0.3), CFrame.new(W(-23.6, RT - 0.45, Z0)) * CFrame.Angles(0, 0, math.rad(25)), wood, M.Wood, SM)
-- base + mattress + pillow + blanket
NH.box(cot, "Base", X0 + 0.35, FY, Z0 + 0.35, X1 - 0.35, FY + 2.4, Z1 - 0.35, wood:Lerp(C.Ink, 0.2), M.Wood, SOLID)
NH.box(cot, "Mattress", X0 + 0.5, FY + 2.4, Z0 + 0.5, X1 - 0.5, FY + 3.2, Z1 - 0.5, C.Sheet:Lerp(C.Tint, 0.3), M.Fabric, SOLID)
local pillow = NH.box(cot, "Pillow", X0 + 1.2, FY + 3.2, Z0 + 3, X0 + 5.4, FY + 4.4, Z1 - 3, C.Sheet:Lerp(C.Tint, 0.2), M.Fabric, SOLID)
NH.box(cot, "Blanket", -26, FY + 3.2, Z0 + 0.6, X1 - 0.6, FY + 3.45, Z1 - 0.6, C.BabyBlue:Lerp(C.Tint, 0.35), M.Fabric, SOLID)
-- blanket spilling out through the gap, with an invisible collidable ramp under it (rise 3.2 over 8.5: 20.6 deg)
local rampLen = 8.5
local rise = 3.2
local ramp = B.part(cot, "Ramp", V3(5, rise, rampLen), CFrame.new(W(-26, FY + rise / 2, Z0 + 0.6 - rampLen / 2)), C.Paper, M.SmoothPlastic, { class = "WedgePart", inv = true, collide = true })
ramp.CanQuery = true
local slope = math.atan2(rise, rampLen)
local hyp = math.sqrt(rise * rise + rampLen * rampLen)
B.part(cot, "BlanketSpill", V3(5.2, 0.2, hyp + 0.2), CFrame.new(W(-26, FY + rise / 2 + 0.08, Z0 + 0.6 - rampLen / 2)) * CFrame.Angles(-slope, 0, 0), C.BabyBlue:Lerp(C.Tint, 0.35), M.Fabric, SM)
-- the mobile, turning over the cot (hangs from the roof boards)
local mob = B.model(AF, "Mobile")
local MX, MZ = -26, 8
local roofY = 48 - math.abs(MZ) * (20 / 35) + 0.1 -- tucked into the roof boards
NH.seg(mob, "Cord", W(MX, roofY, MZ), W(MX, RT + 1.6, MZ), 0.08, 0.08, C.Ink, M.SmoothPlastic, SM)
for k = 0, 1 do
	local a = math.rad(k * 90 + 20)
	local d = V3(math.cos(a), 0, math.sin(a)) * 3.2
	NH.seg(mob, "Arm", W(MX, RT + 1.6, MZ) - d, W(MX, RT + 1.6, MZ) + d, 0.12, 0.12, C.Gold, M.Metal, SM)
	for _, s in { -1, 1 } do
		local tip = W(MX, RT + 1.6, MZ) + d * s
		NH.seg(mob, "String", tip, tip - V3(0, 1.4, 0), 0.05, 0.05, C.Ink, M.SmoothPlastic, SM)
		if (k + (s + 1) / 2) % 2 == 0 then
			B.part(mob, "Moon", V3(0.3, 1.2, 1.2), CFrame.new(tip - V3(0, 2, 0)), C.Mustard:Lerp(C.Tint, 0.3), M.SmoothPlastic, { small = true, shape = Enum.PartType.Cylinder })
		else
			B.part(mob, "DollHead", V3(1, 1, 1), CFrame.new(tip - V3(0, 2, 0)), C.Paper:Lerp(C.Rose, 0.15):Lerp(C.Tint, 0.2), M.SmoothPlastic, { small = true, shape = Enum.PartType.Ball })
			B.part(mob, "Eye", V3(0.14, 0.14, 0.05), CFrame.new(tip - V3(0.15, 1.9, 0.5)), C.Ink, M.SmoothPlastic, SM)
			B.part(mob, "Eye", V3(0.14, 0.14, 0.05), CFrame.new(tip - V3(-0.15, 1.9, 0.5)), C.Ink, M.SmoothPlastic, SM)
		end
	end
end
-- 3) giant letter blocks (collidable; you can duck behind them)
local function block(x, y, z, s, letter, col, rot)
	local p = B.part(AF, "ToyBlock", V3(s, s, s), CFrame.new(W(x, y + s / 2, z)) * CFrame.Angles(0, math.rad(rot or 0), 0), col, M.SmoothPlastic, SOLID)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top } do
		local g = Instance.new("SurfaceGui")
		g.Face = face
		g.CanvasSize = Vector2.new(100, 100)
		g.LightInfluence = 1
		g.Parent = p
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = letter
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = col:Lerp(C.Ink, 0.55)
		t.Parent = g
	end
	return p
end
block(-40, FY, 1.5, 3, "N", C.WRose:Lerp(C.Tint, 0.2), 8)
block(-40.3, FY + 3, 1.3, 3, "A", C.WMint:Lerp(C.Tint, 0.2), -14)
block(-12, FY, -4, 3, "N", C.WMustard:Lerp(C.Tint, 0.2), 25)
block(-11.4, FY + 3, -3.8, 3, "A", C.WPlum:Lerp(C.Tint, 0.1), 5)
block(-16, FY, 19, 2.6, "B", C.WTeal:Lerp(C.Tint, 0.2), -30)
block(-36.5, FY, -15, 2.6, "Y", C.WRose:Lerp(C.Tint, 0.2), 40)
block(10, FY, -18, 2.6, "E", C.WMint:Lerp(C.Tint, 0.2), -10)
-- 4) dolls' tea party (east of the cot)
local TX, TZ = -8, -10
local tea = B.model(AF, "TeaParty")
B.cyl(tea, "Table", CFrame.new(W(TX, FY, TZ)), 2.6, 0.2, V3(0, 1.4, 0), C.Cream:Lerp(C.Tint, 0.3), M.Wood, SOLID)
B.cyl(tea, "Stem", CFrame.new(W(TX, FY, TZ)), 0.4, 1.3, V3(0, 0.65, 0), C.WoodDark, M.Wood, SM)
B.cyl(tea, "Pot", CFrame.new(W(TX, FY, TZ)), 0.6, 0.6, V3(0, 1.8, 0), C.WRose, M.SmoothPlastic, SM)
for i = 0, 4 do
	local a = i / 5 * math.pi * 2
	local p = W(TX + math.cos(a) * 2.3, FY, TZ + math.sin(a) * 2.3)
	B.doll(tea, CFrame.lookAt(p, W(TX, FY, TZ)), 1.2, if i % 2 == 0 then C.Velvet else B.C.WPlum)
end
-- the empty chair at the party faces the stairs (it's for you)
-- 5) moon night-light (the nursery's only working lamp)
local ml = NH.lamp(AF, "floor", NH.CF(-15.5, FY, 13, "-z"), "Attic", true, { bright = 0.8, range = 20, shade = C.Mustard:Lerp(C.Tint, 0.25) })
table.insert(out, "nightlight " .. ml.Name)
-- 6) THE TOY CHEST hiding spot (x -8..-2, z 14..18.5), front faces -z
local tc = B.model(AF, "ToyChest")
local b = NH.CF(-5, FY, 16.25, "-z")
local w, d, h = 6, 4.5, 6
local chestCol = C.WMint:Lerp(C.Tint, 0.35)
B.rp(tc, "Back", b, V3(w, h, 0.4), V3(0, h / 2, d / 2 - 0.2), chestCol, M.Wood, SOLID)
for _, sx in { -1, 1 } do B.rp(tc, "Side", b, V3(0.4, h, d), V3(sx * (w / 2 - 0.2), h / 2, 0), chestCol, M.Wood, SOLID) end
B.rp(tc, "Bottom", b, V3(w, 0.4, d), V3(0, 0.2, 0), chestCol:Lerp(C.Ink, 0.2), M.Wood, SOLID)
local frontP = B.rp(tc, "FrontPanel", b, V3(w - 0.8, h - 0.4, 0.35), V3(0, (h - 0.4) / 2 + 0.2, -d / 2 + 0.18), chestCol, M.Wood, SOLID)
B.rp(tc, "Lid", b, V3(w + 0.3, 0.5, d + 0.3), V3(0, h + 0.25, 0), chestCol:Lerp(C.Ink, 0.15), M.Wood, SOLID)
for i = -1, 1 do B.rp(tc, "Stripe", b, V3(0.5, h - 0.8, 0.05), V3(i * 1.8, h / 2, -d / 2 - 0.02), C.WRose:Lerp(C.Tint, 0.3), M.SmoothPlastic, SM) end
B.rp(tc, "Latch", b, V3(0.7, 0.6, 0.12), V3(0, h - 0.4, -d / 2 - 0.08), C.Brass, M.Metal, SM)
local _ = frontP
B.hideParts(tc, "Cabinet", "Attic", b * CFrame.new(0, 3.1, 0.3) * CFrame.Angles(0, 0, 0), (b * CFrame.new(0, 0, -d / 2 - 2.1)).Position, (b * CFrame.new(0, 0, -d / 2 - 2)).Position)
-- a small toy box next to it is Searchable (Kind ToyChest)
local tb = B.model(AF, "ToyBox")
local bb = NH.CF(1.5, FY, 17, "-z")
B.rp(tb, "Body", bb, V3(3, 1.8, 2), V3(0, 0.9, 0), C.WRose:Lerp(C.Tint, 0.35), M.Wood, SOLID)
local lid = B.rp(tb, "Lid", bb, V3(3.1, 0.4, 2.1), V3(0, 2, 0), C.WRose:Lerp(C.Ink, 0.3), M.Wood, SOLID)
B.searchable(lid, "ToyChest", "Attic", 3)
-- contract: prize on the giant pillow and in the toy box, pumpkin on the mattress, nodes, loot on blocks/cot
NH.prize("Attic", W(X0 + 3.3, FY + 4.4, 8))
NH.prize("Attic", W(1.5, FY + 2.2, 17) + V3(0, -0.3, 0))
NH.pumpkin("Attic", W(-22, FY + 3.45, 8), "-x")
NH.node("Attic", W(-26, FY, -1.5))
NH.node("Attic", W(-21, FY + 3.45, 10.5))
NH.node("Attic", W(-5, FY, 10))
NH.loot("Attic", 3, W(-40.3, FY + 6, 1.3))
NH.loot("Attic", 3, W(-11.4, FY + 6, -3.8))
NH.loot("Attic", 3, W(-19.5, FY + 3.45, 4))
NH.loot("Attic", 3, W(TX + 0.5, FY + 1.5, TZ + 0.3))
NH.creak(W(-26, FY, -1), 0)
NH.creak(W(-6, FY, 8), 0)
-- room names for this map
for _, rm in H.Rooms:GetChildren() do
	if rm.Name == "Attic Storage" then rm:SetAttribute("RoomName", "The Nursery") end
	if rm.Name == "Attic Gallery" then rm:SetAttribute("RoomName", "The Playroom") end
end
-- veins creeping down the roof boards towards the cot
local VF = NH.F("Veins", NH.F("Nightmare"))
local nv = 0
local rb = { -45, FY, -25.4, 45, 47.5, 25.4 }
for i, v in { { V3(-26, 32, 8), V3(0, 1, 0.6) }, { V3(-26, 32, 8), V3(0, 1, -0.6) }, { V3(-40, 30, 0), V3(-1, 0, 0) }, { V3(10, 31, -10), V3(0, 1, -0.7) }, { V3(30, 31, 5), V3(0, 1, 0.5) } } do
	nv += NH.wallVein(VF, rb, v[1], v[2], 13, 600 + i, 2)
end
table.insert(out, "attic veins " .. nv)
table.insert(out, "parts now " .. NH.count())
return table.concat(out, "\n")
