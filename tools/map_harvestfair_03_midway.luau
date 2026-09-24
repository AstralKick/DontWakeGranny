-- HarvestFair Ground zone part 1: entrance plaza (ticket booth), the midway stall islands (8 game/food booths),
-- avenue centre row (poles, festoons, prize-bear bin), pumpkin patch (hay-bale fort), back lot (portaloos, crate stack).
-- Section "midway" (idempotent).
local B = _G.HF
local C, M = B.C, B.M
local V = Vector3.new
local root = B.root()
local S = B.begin("midway")
local SM = { small = true }
local G = "Ground"
-- flat searchable front (drawer / cabinet door): centre, facing dir (loot pops out along dir)
local function sdoor(par, name, center, dir, w, h, col, kind, danger)
	local p = B.part(par, name, V(w, h, 0.12), CFrame.lookAt(center, center + dir), col, M.Wood, { collide = false, shadow = false })
	return B.searchable(p, kind, G, danger or 1)
end

----------------------------------------------------------------- game booth
-- front at x = xf, back at x = xb (|xf - xb| = 8), z range za..zb. door = "za"/"zb"/nil (open side doorway on the other)
local function booth(name, xf, xb, za, zb, title, col, o)
	o = o or {}
	local m = B.model(S, "Booth_" .. name)
	local s = if xf > xb then 1 else -1
	local y0 = 0.08
	local x0, x1 = math.min(xf, xb), math.max(xf, xb)
	local wallC = col:Lerp(C.Ink, 0.35)
	B.box(m, "Floor", x0, -0.1, za, x1, y0, zb, C.WoodMid:Lerp(C.Ink, 0.2), M.WoodPlanks, { solid = true })
	B.box(m, "BackWall", xb, y0, za, xb + s * 0.25, 9, zb, wallC, M.WoodPlanks, { solid = true })
	-- side walls (axis x at fixed z), doorway centred 3.15 from the back
	local dc = xb + s * 3.15
	for _, side in { "za", "zb" } do
		local fz = if side == "za" then za + 0.125 else zb - 0.125
		local gaps = if o.door == side or o.open == side then { B.DG(dc) } else nil
		B.wall(m, "SideWall", "x", fz, math.min(xb + s * 0.25, xf), math.max(xb + s * 0.25, xf), y0, 9, 0.25, wallC, M.WoodPlanks, gaps)
		if gaps then
			B.doorway(m, "x", fz, dc, y0, 0.25, C.WoodDark)
			if o.door == side then
				B.door(m, "Door", "x", fz, dc, y0, G, (za % 2) == 0, false, col:Lerp(C.Paper, 0.2), -s)
			end
		end
	end
	-- counter (hollow: front boards with a peep slit, top overhang)
	local cz0, cz1 = za + 0.25, zb - 0.25
	B.box(m, "CounterFront", xf - s * 0.2, y0, cz0, xf, 2.2, cz1, col, M.WoodPlanks, { solid = true })
	B.box(m, "CounterFront", xf - s * 0.2, 2.5, cz0, xf, 3.4, cz1, col, M.WoodPlanks, { solid = true })
	B.box(m, "CounterTop", xf - s * 1.7, 3.4, cz0, xf + s * 0.3, 3.65, cz1, C.WoodLight, M.Wood, { solid = true })
	B.box(m, "CounterStripe", xf, 1.0, cz0, xf + s * 0.05, 1.4, cz1, C.Cream, M.SmoothPlastic, SM)
	-- roof, sign, striped awning
	B.box(m, "Roof", x0, 9, za, x1, 9.3, zb, C.Ink:Lerp(C.WoodDark, 0.5), M.WoodPlanks, { solid = true })
	local sign = B.box(m, "Sign", xf - s * 0.3, 9.3, za + 0.5, xf, 11.5, zb - 0.5, C.Night, M.Wood, { solid = true })
	B.text(sign, title, { face = if s > 0 then Enum.NormalId.Right else Enum.NormalId.Left, color = o.textCol or C.Mustard, pps = 24 })
	local n = math.floor((zb - za) / 2)
	for i = 0, n - 1 do
		local z = za + (i + 0.5) * (zb - za) / n
		local p0, p1 = V(xf, 9.1, z), V(xf + s * 2.4, 8.3, z)
		B.part(m, "Awning", V((zb - za) / n, 0.12, (p1 - p0).Magnitude), CFrame.lookAt((p0 + p1) / 2, p1), if i % 2 == 0 then col else C.Cream, M.Fabric, SM)
	end
	-- prize shelf on the back wall (kept 1.5 clear of the side walls for the door swing)
	local bb = CFrame.lookAt(V(xb + s * 0.85, y0, (za + zb) / 2), V(xb + s * 10, y0, (za + zb) / 2))
	if not o.noShelf then B.prizeShelf(m, bb, (zb - za) - 4, math.floor(za)) end
	-- contract bits
	local cx = xf - s * 0.9
	B.loot(G, 1, V(cx, 3.65, za + 3.5))
	if o.lamp then
		B.lamp(m, "bare", CFrame.new((xf + xb) / 2 + s * 1, 9, (za + zb) / 2), G, { drop = 1.4, range = 20, bright = 0.9 })
	end
	if o.hide then
		local ctr = V(xf - s * 0.95, y0 + 0.9, (za + zb) / 2 + 3)
		local hm = B.model(m, "CounterHide")
		B.hideParts(hm, "Cabinet", G, CFrame.lookAt(ctr, ctr + V(s, 0, 0)), V(xf + s * 2.2, y0 - 0.08, ctr.Z), V(xf + s * 2.4, y0 - 0.08, ctr.Z + 1.5))
	end
	return m, s, y0
end

local W = {}
-- west island (back line x = -30)
W.ring = { booth("RingToss", -38, -30, -58, -42, "RING TOSS", C.Teal, { open = "zb" }) }
W.duck = { booth("HookADuck", -22, -30, -58, -42, "HOOK-A-DUCK", C.Red, { door = "zb", lamp = true, hide = true }) }
W.tin = { booth("TinCanAlley", -38, -30, -35, -19, "TIN CAN ALLEY", C.Plum, { door = "za" }) }
W.coco = { booth("CoconutShy", -22, -30, -35, -19, "COCONUT SHY", C.Mustard:Lerp(C.Ink, 0.3), { open = "za", lamp = true }) }
-- east island (back line x = 30)
W.apple = { booth("CandyApples", 22, 30, -58, -42, "CANDY APPLES", C.Red, { door = "zb", lamp = true, noShelf = true }) }
W.dog = { booth("HotDogs", 38, 30, -58, -42, "HOT DOGS", C.Mustard:Lerp(C.Ink, 0.25), { open = "zb", noShelf = true }) }
W.prize = { booth("PrizeBooth", 22, 30, -35, -19, "PRIZES!", C.Bruise, { door = "za", hide = true, lamp = true }) }
W.dip = { booth("LuckyDip", 38, 30, -35, -19, "LUCKY DIP", C.Teal, { open = "za" }) }

-- booth dressings
do -- ring toss: bottle pyramids (Breakable) on a stepped stand, pegs
	local m = W.ring[1]
	B.box(m, "Stand", -34.4, 0.08, -54, -32.6, 2.6, -46, C.WoodDark, M.Wood, { solid = true })
	B.bottles(m, CFrame.new(-33.5, 2.6, -52), C.Mint:Lerp(C.Ink, 0.3))
	B.bottles(m, CFrame.new(-33.5, 2.6, -48), C.Rose:Lerp(C.Ink, 0.3))
	for i = 0, 3 do B.cyl(m, "Ring", CFrame.new(-37.2, 3.7, -55 + i * 0.6), 0.9, 0.1, V(0, 0, 0), C.Mustard, M.SmoothPlastic, SM, true) end
	B.loot(G, 1, V(-33.5, 2.6, -50))
end
do -- hook-a-duck: water trough with ducks
	local m = W.duck[1]
	B.box(m, "Trough", -26.8, 0.08, -54.5, -24.6, 2.4, -47, C.Red:Lerp(C.Ink, 0.3), M.Wood, { solid = true })
	B.box(m, "Water", -26.6, 2.4, -54.3, -24.8, 2.45, -47.2, C.Teal:Lerp(C.Glass, 0.3), M.Glass, { small = true, tr = 0.2 })
	for i = 0, 5 do B.duck(m, V(-25.7 + (i % 2) * 0.6 - 0.3, 2.45, -53.5 + i * 1.2), if i % 3 == 0 then C.Rose else C.Mustard) end
	for i = 0, 2 do B.part(m, "HookPole", V(0.1, 0.1, 3.2), CFrame.new(-23.4, 3.7, -55 + i * 0.4) * CFrame.Angles(0, math.rad(90), 0), C.WoodLight, M.Wood, SM) end
	sdoor(m, "CashDrawer", V(-23.76, 3.1, -45.8), V(-1, 0, 0), 2, 0.6, C.WoodDark, "Drawer")
end
do -- tin can alley: glass jars on shelves (Breakable) + cans
	local m = W.tin[1]
	B.box(m, "Shelf", -33.6, 0.08, -29, -32.2, 2.8, -21, C.WoodMid, M.Wood, { solid = true })
	B.jarBreak(m, V(-32.9, 2.8, -27.8), C.Mint, 1)
	B.jarBreak(m, V(-32.9, 2.8, -25.2), C.Rose, 1)
	B.jarBreak(m, V(-32.9, 2.8, -22.6), C.Mustard, 1)
	for i = 0, 5 do B.cyl(m, "Can", CFrame.new(-37.2, 3.65, -33 + i * 0.7), 0.6, 0.9, V(0, 0.45, 0), C.Metal, M.Metal, SM, true) end
	B.box(m, "PrizeCabinet", -31.4, 0.08, -26, -30.25, 2.6, -23.5, C.Plum:Lerp(C.Ink, 0.3), M.Wood, { solid = true })
	sdoor(m, "CabinetDoor", V(-31.46, 1.35, -24.75), V(-1, 0, 0), 2.3, 2.1, C.Plum:Lerp(C.Paper, 0.1), "Cabinet")
	B.loot(G, 1, V(-32.9, 2.8, -21.6))
end
do -- coconut shy: posts with coconuts
	local m = W.coco[1]
	for i = 0, 4 do
		local z = -32 + i * 2.6
		B.box(m, "CocoPost", -27.1, 0.08, z - 0.15, -26.8, 3.6, z + 0.15, C.WoodRaw, M.Wood, SM)
		B.part(m, "CocoCup", V(0.7, 0.2, 0.7), CFrame.new(-26.95, 3.7, z), C.Metal, M.Metal, SM)
		if i ~= 2 then B.part(m, "Coconut", V(0.9, 0.9, 0.9), CFrame.new(-26.95, 4.25, z), C.WoodMid, M.Sand, { small = true, shape = Enum.PartType.Ball }) end
	end
	B.crate(m, B.cf(-25.5, 0.08, -21.5, 0), 1.6)
	B.loot(G, 1, V(-25.5, 1.68, -21.5))
end
do -- candy apples: trays, bubbling vat, sugar jars (Breakable)
	local m = W.apple[1]
	for i = 0, 5 do
		B.ball(m, "Apple", CFrame.new(23, 3.65, -55 + i * 0.9), 0.7, V(0, 0.35, 0), C.Blood, M.SmoothPlastic, SM)
		B.part(m, "Stick", V(0.08, 0.8, 0.08), CFrame.new(23, 4.4, -55 + i * 0.9), C.WoodLight, M.Wood, SM)
	end
	B.cyl(m, "Vat", CFrame.new(27, 0.08, -48), 2.4, 3, V(0, 1.5, 0), C.Metal, M.Metal, { solid = true }, true)
	B.cyl(m, "Toffee", CFrame.new(27, 0.08, -48), 2.1, 0.1, V(0, 3.02, 0), C.Pumpkin:Lerp(C.Ink, 0.3), M.SmoothPlastic, SM, true)
	B.jarBreak(m, V(23.1, 3.65, -45.2), C.Rose, 0.9)
	B.dresser(m, CFrame.lookAt(V(29.05, 0.08, -54), V(22, 0.08, -54)), 3, 1.4, 2.8, C.Red:Lerp(C.Ink, 0.3), 2, G, 1, { search = { 1 } })
	B.loot(G, 1, V(29.05, 3.0, -54))
end
do -- hot dogs: grill, fridge
	local m = W.dog[1]
	B.box(m, "Grill", 32.4, 0.08, -56, 34.4, 3.2, -50, C.Metal:Lerp(C.Ink, 0.4), M.Metal, { solid = true })
	B.box(m, "Hotplate", 32.5, 3.2, -55.9, 34.3, 3.3, -50.1, C.Ink, M.Metal, SM)
	for i = 0, 4 do B.part(m, "Sausage", V(0.3, 0.3, 0.85), CFrame.new(33.4, 3.45, -55 + i), C.Red:Lerp(C.WoodMid, 0.5), M.SmoothPlastic, { small = true }) end
	B.fridge(m, CFrame.lookAt(V(31.7, 0.08, -46), V(40, 0.08, -46)), G, 1, C.Paper:Lerp(C.Mint, 0.3))
	B.jarBreak(m, V(36.9, 3.65, -47.5), C.Mustard, 0.8)
	B.loot(G, 1, V(33.4, 3.3, -51))
end
do -- prize booth: prize cabinets (Searchable) + giant bear
	local m = W.prize[1]
	B.bear(m, CFrame.lookAt(V(27.5, 0.08, -23), V(20, 0.08, -23)), 2.4, C.Rose:Lerp(C.Ink, 0.2))
	B.dresser(m, CFrame.lookAt(V(28.95, 0.08, -29.5), V(20, 0.08, -29.5)), 3.4, 1.6, 3.2, C.Bruise:Lerp(C.Ink, 0.3), 3, G, 1, { search = { 1 }, kind = "Cabinet", name = "PrizeCabinet" })
	B.loot(G, 1, V(28.95, 3.4, -29.5))
end
do -- lucky dip: prize boxes (ToyChest)
	local m = W.dip[1]
	for i, z in { -30, -23.5 } do
		local _, lid = B.trunk(m, CFrame.lookAt(V(33.8, 0.08, z), V(40, 0.08, z)), if i == 2 then C.Rose:Lerp(C.Ink, 0.3) else C.Teal:Lerp(C.Ink, 0.3), G, 1, { kind = "ToyChest", name = "PrizeBox", w = 3, d = 2 })
	end
	B.loot(G, 1, V(33.8, 2.2, -28.8))
end
-- island back seams / cut-through alley dressing (hay + lanterns)
for _, x in { -30, 30 } do
	B.hay(S, B.cf(x, 0, -60.5, 90))
	B.hay(S, B.cf(x, 0, -16.5, 90))
end

----------------------------------------------------------------- avenue centre row (x = 0)
for i, z in { -62, -44, -26, -10 } do
	B.box(S, "FestoonPole", -0.35, 0.05, z - 0.35, 0.35, 14, z + 0.35, C.WoodDark, M.Wood, { solid = true })
	B.box(S, "PoleCap", -0.6, 14, z - 0.6, 0.6, 14.4, z + 0.6, C.Gold:Lerp(C.Ink, 0.3), M.Wood, SM)
	for _, sx in { -1, 1 } do
		local lamp = (i == 2 and sx == -1) or (i == 3 and sx == 1) or (i == 4 and sx == -1)
		B.festoon(S, V(0, 13.6, z), V(sx * 22, 11.2, math.clamp(z, -57.5, -19.5)), 1.6, 9, if lamp then G else nil, { seed = i * 3 + sx })
	end
end
-- lengthwise festoon along the pole row
B.festoon(S, V(0, 13.6, -62), V(0, 13.6, -44), 1.2, 8, nil, { seed = 7 })
B.festoon(S, V(0, 13.6, -26), V(0, 13.6, -10), 1.2, 8, nil, { seed = 9 })
-- benches and hay between the poles
B.bench(S, B.cf(0, 0.05, -53, "+x"), 6)
B.bench(S, B.cf(0, 0.05, -17, "-x"), 6)
B.hay(S, B.cf(1.5, 0.05, -38, 90))
B.hay(S, B.cf(-1.6, 0.05, -41.5, 90), { tint = 0.2 })
-- prize-bear bin (HidingSpot Cabinet): open-top bin full of plush bears
do
	local m = B.model(S, "PrizeBearBin")
	local cx, cz = 0, -32
	local y0 = 0.05
	local col = C.Teal:Lerp(C.Ink, 0.2)
	B.box(m, "BinWall", cx - 2.5, y0, cz - 2.5, cx + 2.5, 4.6, cz - 2.2, col, M.Metal, { solid = true })
	B.box(m, "BinWall", cx - 2.5, y0, cz + 2.2, cx + 2.5, 4.6, cz + 2.5, col, M.Metal, { solid = true })
	B.box(m, "BinWall", cx - 2.5, y0, cz - 2.2, cx - 2.2, 4.6, cz + 2.2, col, M.Metal, { solid = true })
	B.box(m, "BinWall", cx + 2.2, y0, cz - 2.2, cx + 2.5, 4.6, cz + 2.2, col, M.Metal, { solid = true })
	B.box(m, "BinRim", cx - 2.6, 4.6, cz - 2.6, cx + 2.6, 4.8, cz + 2.6, C.Mustard:Lerp(C.Ink, 0.2), M.Metal, SM)
	local sign = B.box(m, "BinSign", cx + 2.5, 2.2, cz - 1.8, cx + 2.55, 4.2, cz + 1.8, C.Paper, M.SmoothPlastic, SM)
	B.text(sign, "WIN A BEAR!", { face = Enum.NormalId.Right, color = C.Rose })
	local sign2 = B.box(m, "BinSign", cx - 2.55, 2.2, cz - 1.8, cx - 2.5, 4.2, cz + 1.8, C.Paper, M.SmoothPlastic, SM)
	B.text(sign2, "WIN A BEAR!", { face = Enum.NormalId.Left, color = C.Rose })
	local cols = { C.Rose, C.Mint, C.Mustard, C.Bruise, C.Paper }
	for k = 1, 9 do
		local a = k * 2.1
		B.ball(m, "Plush", CFrame.new(cx + math.cos(a) * 1.2, 4.1 + (k % 3) * 0.25, cz + math.sin(a) * 1.2), 1.1 + (k % 2) * 0.3, V(0, 0, 0), cols[k % #cols + 1]:Lerp(C.Ink, 0.15), M.Fabric, SM)
	end
	local ins = V(cx, y0 + 1.2, cz)
	B.hideParts(m, "Cabinet", G, CFrame.lookAt(ins, ins + V(1, 0, 0)), V(cx + 4.2, y0, cz), V(cx + 4.4, y0, cz + 1.5))
end
B.lamp(S, "post", B.cf(0, 0.05, -70, "+z"), G, { range = 24 })

----------------------------------------------------------------- entrance plaza: ticket booth (HidingSpot Closet + Door)
do
	local m = B.model(S, "TicketBooth")
	local x0, x1, z0, z1 = -24, -18, -88.5, -82
	local y0 = 0.08
	local col = C.Red:Lerp(C.Ink, 0.25)
	B.box(m, "Floor", x0, -0.1, z0, x1, y0, z1, C.WoodDark, M.WoodPlanks, { solid = true })
	-- front (z0) with ticket window, back (z1) with door, sides solid
	B.wall(m, "Wall", "x", z0 + 0.125, x0, x1, y0, 9, 0.25, col, M.WoodPlanks, { { c = -21, w = 3, sill = 3.6, h = 6.4 } })
	B.box(m, "WindowGlass", -22.5, 3.72, z0 + 0.1, -19.5, 6.48, z0 + 0.15, C.Glass, M.Glass, { solid = true, tr = 0.6, shadow = false })
	B.box(m, "TicketShelf", -22.6, 3.44, z0 - 0.6, -19.4, 3.72, z0 + 0.6, C.WoodLight, M.Wood, SM)
	B.wall(m, "Wall", "x", z1 - 0.125, x0, x1, y0, 9, 0.25, col, M.WoodPlanks, { B.DG(-21) })
	B.doorway(m, "x", z1 - 0.125, -21, y0, 0.25, C.WoodDark)
	B.door(m, "Door", "x", z1 - 0.125, -21, y0, G, true, true, C.Cream:Lerp(C.Ink, 0.2), 1)
	B.box(m, "Wall", x0, y0, z0 + 0.25, x0 + 0.25, 9, z1 - 0.25, col, M.WoodPlanks, { solid = true })
	B.box(m, "Wall", x1 - 0.25, y0, z0 + 0.25, x1, 9, z1 - 0.25, col, M.WoodPlanks, { solid = true })
	B.box(m, "Roof", x0 - 0.5, 9, z0 - 0.5, x1 + 0.5, 9.4, z1 + 0.5, C.Ink, M.WoodPlanks, { solid = true })
	local sg = B.box(m, "Sign", x0, 9.4, z0 - 0.3, x1, 10.9, z0, C.Paper, M.Wood, SM)
	B.text(sg, "TICKETS", { color = C.Blood, face = Enum.NormalId.Front })
	B.box(m, "Counter", x0 + 0.25, y0, z0 + 0.25, x1 - 0.25, 3.4, z0 + 1.6, C.WoodMid, M.Wood, { solid = true })
	B.loot(G, 1, V(-22.5, 3.4, z0 + 0.95))
	sdoor(m, "TicketDrawer", V(-19.85, 2.75, z0 + 1.66), V(0, 0, 1), 1.3, 0.7, C.WoodDark, "Drawer")
	B.lamp(m, "bare", CFrame.new(-20, 9, -86.5), G, { drop = 1.2, range = 14, bright = 0.8 })
	local ins = V(-22.4, y0 + 3, -84.6)
	B.hideParts(m, "Closet", G, CFrame.lookAt(ins, ins + V(0, 0, 1)), V(-21, 0.05, -79.3), V(-19.8, 0.05, -79))
end
-- plaza dressing: hay bales, pumpkins, a welcome board
B.hay(S, B.cf(-30, 0, -78, 15))
B.hay(S, B.cf(30, 0, -80, -20))
B.hay(S, B.cf(31, 2.2, -80, -5), { tint = 0.25 })
for i, p in { V(-28, 0, -74), V(-27, 0, -76.5), V(29, 0, -74), V(33, 0, -76), V(-12, 0.05, -72), V(12, 0.05, -72) } do
	B.pumpkinProp(S, p, 0.8 + (i % 3) * 0.2, i == 5 or i == 6)
end
do
	local wb = B.box(S, "MapBoard", 18, 3, -78.2, 26, 8, -77.9, C.Cream:Lerp(C.Ink, 0.15), M.Wood, { solid = true })
	B.text(wb, "MIDWAY  >  CAROUSEL\nFUNHOUSE  >  EAST\nGHOST TRAIN  >  WEST\nBIG TOP  >  NORTH", { color = C.Ink, stroke = C.Paper, strokeT = 1, font = Enum.Font.SpecialElite, face = Enum.NormalId.Front })
	for _, x in { 18.5, 25.5 } do B.box(S, "BoardLeg", x - 0.2, 0.05, -78.1, x + 0.2, 3, -77.9, C.WoodDark, M.Wood, SM) end
end

----------------------------------------------------------------- pumpkin patch (west field): hay-bale fort + scarecrow + pumpkin rows
local function bale(par, x0, y0, z0, x1, y1, z1, tint)
	return B.box(par, "HayBale", x0, y0, z0, x1, y1, z1, C.Hay:Lerp(C.WoodMid, tint or 0.1), M.Grass, { solid = true })
end
do
	local m = B.model(S, "HayBaleFort")
	local cx, cz = -72, -44
	-- bales 3 high round a 4.8 x 4.8 hollow; open (crawl) gap on the +x side behind a sack; tarp roof
	for lvl = 0, 2 do
		local y = lvl * 2.2
		bale(m, cx - 4.8, y, cz - 4.8, cx - 2.4, y + 2.2, cz + 4.8, lvl * 0.08) -- west
		bale(m, cx - 2.4, y, cz - 4.8, cx + 4.8, y + 2.2, cz - 2.4, 0.05 + lvl * 0.05) -- south
		bale(m, cx - 2.4, y, cz + 2.4, cx + 4.8, y + 2.2, cz + 4.8, 0.12 + lvl * 0.03) -- north
	end
	bale(m, cx + 2.4, 0, cz - 2.4, cx + 4.8, 2.2, cz - 0.8, 0.15)
	bale(m, cx + 2.4, 0, cz + 0.8, cx + 4.8, 2.2, cz + 2.4, 0.18)
	bale(m, cx + 2.4, 2.2, cz - 2.4, cx + 4.8, 4.4, cz + 2.4, 0.2)
	bale(m, cx + 2.4, 4.4, cz - 2.4, cx + 4.8, 6.6, cz + 2.4, 0.1)
	for _, z in { cz - 3.6, cz + 3.6 } do
		B.box(m, "Twine", cx - 1, 0, z - 1.22, cx - 0.88, 6.6, z + 1.22, C.WoodDark, M.Fabric, SM)
	end
	B.box(m, "Tarp", cx - 4.9, 6.6, cz - 4.9, cx + 4.9, 6.8, cz + 4.9, C.Teal:Lerp(C.Ink, 0.4), M.Fabric, { solid = true })
	B.box(m, "Sack", cx + 4.8, 0.3, cz - 0.9, cx + 4.9, 2.1, cz + 0.9, C.WoodRaw:Lerp(C.Paper, 0.2), M.Fabric, SM)
	local ins = V(cx, 3, cz)
	B.hideParts(m, "Closet", G, CFrame.lookAt(ins, ins + V(1, 0, 0)), V(cx + 7, 0, cz), V(cx + 7.2, 0, cz + 1.5))
	-- lantern on a pole beside the fort
	B.box(m, "LanternPole", cx + 5.8, 0, cz + 5.8, cx + 6.2, 7.4, cz + 6.2, C.WoodDark, M.Wood, { solid = true })
	B.box(m, "LanternArm", cx + 5.8, 7.2, cz + 5.1, cx + 6.2, 7.4, cz + 5.8, C.WoodDark, M.Wood, SM)
	B.box(m, "Chain", cx + 5.96, 6.825, cz + 5.36, cx + 6.04, 7.2, cz + 5.44, C.Ink, M.Metal, SM)
	B.lamp(m, "lantern", CFrame.new(cx + 6, 7.2, cz + 5.4), G, { range = 16, bright = 0.9 })
	B.loot(G, 1, V(cx - 1.5, 0, cz + 1.2))
end
do -- scarecrow
	local m = B.model(S, "Scarecrow")
	local b = B.cf(-84, 0, -52, "+x")
	B.rp(m, "Pole", b, V(0.4, 9, 0.4), V(0, 4.5, 0), C.WoodDark, M.Wood, { solid = true })
	B.rp(m, "Shirt", b, V(2.6, 2.8, 1.2), V(0, 6, 0), C.Red:Lerp(C.Ink, 0.4), M.Fabric, SM)
	B.rp(m, "Sleeves", b, V(5.4, 0.9, 0.9), V(0, 6.8, 0), C.Red:Lerp(C.Ink, 0.45), M.Fabric, SM)
	B.rp(m, "Hands", b, V(6.2, 0.4, 0.4), V(0, 6.8, 0), C.Hay, M.Grass, SM)
	B.ball(m, "Head", b, 1.8, V(0, 8.3, 0), C.Hay:Lerp(C.Paper, 0.2), M.Fabric, SM)
	B.rp(m, "HatBrim", b, V(2.8, 0.15, 2.8), V(0, 9.1, 0), C.WoodDark:Lerp(C.Ink, 0.4), M.Fabric, SM)
	B.rp(m, "HatTop", b, V(1.5, 1.1, 1.5), V(0, 9.725, 0), C.WoodDark:Lerp(C.Ink, 0.4), M.Fabric, SM)
	for _, sx in { -0.35, 0.35 } do B.rp(m, "Eye", b, V(0.25, 0.25, 0.1), V(sx, 8.5, -0.86), C.Ink, M.SmoothPlastic, SM) end
end
-- pumpkin rows (a few lit) on dirt rows
for r = 0, 3 do
	B.box(S, "PatchRow", -96, -0.2, -84 + r * 7, -66, 0.04, -81 + r * 7, C.Dirt, M.Ground, { solid = true, shadow = false })
	for k = 0, 4 do
		local x = -93 + k * 6 + (r % 2) * 2
		B.pumpkinProp(S, V(x, 0.04, -82.5 + r * 7), 0.9 + ((k + r) % 3) * 0.3, (k + r) % 5 == 0)
	end
end
B.hay(S, B.cf(-58, 0, -30, 30))
B.loot(G, 1, V(-58, 2.2, -30))
B.hay(S, B.cf(-86, 0, -20, -10))
B.hay(S, B.cf(-86.5, 2.2, -20.2, 80), { tint = 0.2 })
do -- pumpkin weigh-in table
	local _, h = B.table(S, B.cf(-62, 0, -70, "+x"), 6, 3, 3.2, C.WoodRaw, { cloth = C.Mustard:Lerp(C.Ink, 0.3) })
	B.pumpkinProp(S, V(-62, h, -71.5), 1.2)
	B.box(S, "PrizeRibbon", -60.3, 1.6, -70.4, -60.25, 2.6, -69.6, C.Blood, M.Fabric, SM)
	B.loot(G, 1, V(-62, h, -68.8))
end

----------------------------------------------------------------- back lot: portaloos (Bathroom node) + crate stack hide + drums
do
	local m = B.model(S, "Portaloos")
	local y0 = 0.08
	local z0, z1 = -30, -24 -- doors on the z0 side (facing -z), backs at z1
	local cols = { C.Teal, C.Mint:Lerp(C.Ink, 0.3), C.Teal:Lerp(C.Ink, 0.2) }
	for i = 0, 2 do
		local xa = 60 + i * 6
		local xb = xa + 6
		local c = (xa + xb) / 2
		local col = cols[i + 1]
		B.box(m, "Base", xa, -0.1, z0, xb, y0, z1, C.Concrete, M.Concrete, { solid = true })
		B.wall(m, "Front", "x", z0 + 0.125, xa, xb, y0, 9, 0.25, col, M.Plastic, { B.DG(c) })
		B.doorway(m, "x", z0 + 0.125, c, y0, 0.25, col:Lerp(C.Ink, 0.3))
		B.box(m, "Back", xa, y0, z1 - 0.25, xb, 9, z1, col, M.Plastic, { solid = true })
		B.box(m, "Side", xa, y0, z0 + 0.25, xa + 0.4, 9, z1 - 0.25, col, M.Plastic, { solid = true })
		if i == 2 then B.box(m, "Side", xb - 0.4, y0, z0 + 0.25, xb, 9, z1 - 0.25, col, M.Plastic, { solid = true }) end
		B.box(m, "Roof", xa, 9, z0, xb, 9.4, z1, col:Lerp(C.Paper, 0.2), M.Plastic, { solid = true })
		B.box(m, "Seat", c - 1, y0, z1 - 1.9, c + 1, 2, z1 - 0.25, C.Paper:Lerp(C.Ink, 0.2), M.Plastic, { solid = true })
		B.box(m, "Vent", c - 1, 7.5, z1 - 0.3, c + 1, 8, z1 - 0.25, C.Ink, M.Metal, SM)
		if i == 1 then
			-- hiding cubicle: a closed (fake) door leaf; the player hides inside
			local hm = B.model(m, "PortalooHide")
			B.box(hm, "DoorLeaf", c - 2.25, y0 + 0.03, z0, c + 2.25, y0 + 7.93, z0 + 0.25, col:Lerp(C.Paper, 0.15), M.Plastic, { solid = true })
			local occ = B.box(hm, "Sign", c - 0.8, 5, z0 - 0.05, c + 0.8, 5.6, z0, C.Blood, M.SmoothPlastic, SM)
			B.text(occ, "ENGAGED", { face = Enum.NormalId.Front, color = C.Paper, strokeT = 1 })
			local ins = V(c, y0 + 3, z0 + 3.2)
			B.hideParts(hm, "Closet", G, CFrame.lookAt(ins, ins - V(0, 0, 1)), V(c, 0.05, z0 - 2.4), V(c - 1.4, 0.05, z0 - 2.6))
		else
			B.door(m, "Door", "x", z0 + 0.125, c, y0, G, true, true, col:Lerp(C.Paper, 0.15), if i == 0 then 1 else -1)
		end
	end
	B.lamp(m, "flood", B.cf(56, 0.05, -35, -110), G, { spot = true, face = Enum.NormalId.Front, angle = 70, range = 26, bright = 1.2 })
	B.box(m, "HandWash", 79, 0.05, -29, 81, 3.4, -25, C.Paper:Lerp(C.Ink, 0.2), M.Plastic, { solid = true })
	B.loot(G, 1, V(80, 3.4, -27))
end
do -- crate stack with a hollow (HidingSpot Cabinet); the crawl slot on the -x side hides behind a tarp
	local m = B.model(S, "CrateStack")
	local cx, cz = 72, -62
	local col = C.WoodRaw:Lerp(C.Ink, 0.15)
	local function crate(x, y, z, k)
		B.box(m, "Crate", x - 2.5, y, z - 2.5, x + 2.5, y + 5, z + 2.5, col:Lerp(C.Ink, k * 0.06), M.WoodPlanks, { solid = true })
	end
	local k = 0
	for _, p in { V(-5, 0, -5), V(0, 0, -5), V(5, 0, -5), V(5, 0, 0), V(-5, 0, 5), V(0, 0, 5), V(5, 0, 5) } do
		k += 1
		crate(cx + p.X, 0.05, cz + p.Z, k % 3)
	end
	for _, p in { V(-5, 0, -5), V(0, 0, -5), V(-5, 0, 0), V(0, 0, 0), V(5, 0, 0), V(0, 0, 5), V(-5, 0, 5) } do
		k += 1
		crate(cx + p.X, 5.05, cz + p.Z, k % 3)
	end
	B.box(m, "Tarp", cx - 7.55, 0.3, cz - 2.5, cx - 7.5, 5.05, cz + 2.5, C.Teal:Lerp(C.Ink, 0.4), M.Fabric, { small = true })
	local st = B.box(m, "Stencil", cx + 7.5, 1.5, cz - 1.5, cx + 7.55, 3.5, cz + 1.5, C.Paper, M.SmoothPlastic, SM)
	B.text(st, "FRAGILE\nPRIZES", { face = Enum.NormalId.Right, color = C.Blood, stroke = C.Paper, strokeT = 1, font = Enum.Font.SpecialElite })
	local ins = V(cx, 3.05, cz)
	B.hideParts(m, "Cabinet", G, CFrame.lookAt(ins, ins - V(1, 0, 0)), V(cx - 9.5, 0.05, cz), V(cx - 9.7, 0.05, cz + 1.5))
	B.box(m, "SmallCrate", cx + 8, 0.05, cz + 5, cx + 10.5, 2.55, cz + 7.5, col, M.WoodPlanks, { solid = true })
	B.loot(G, 1, V(cx + 9.25, 2.55, cz + 6.25))
end
do -- oil drums, tool bench
	B.barrel(S, B.cf(84, 0.05, -70, 0), C.Red:Lerp(C.Ink, 0.4))
	B.barrel(S, B.cf(86.6, 0.05, -71, 0), C.Teal:Lerp(C.Ink, 0.4))
	B.loot(G, 1, V(84, 3.25, -70))
	B.crate(S, B.cf(88, 0.05, -52, 20), 3)
	B.loot(G, 1, V(88, 3.05, -52))
	B.box(S, "ToolBench", 56, 0.05, -84, 64, 3.2, -81, C.WoodMid, M.Wood, { solid = true })
	sdoor(S, "ToolDrawer", V(62, 2.55, -84.06), V(0, 0, -1), 2, 0.7, C.WoodDark, "Drawer")
end


----------------------------------------------------------------- rooms, nodes, loot on the lanes
B.room("Entrance Plaza", G, 1, -46, -1, -95, 46, 16, -70)
B.room("Pumpkin Patch", G, 1, -100, -1, -95, -46, 16, -5)
B.room("Back Lot", G, 1, 46, -1, -95, 100, 16, -36)
B.room("Portaloos", G, 1, 46, -1, -36, 100, 16, -5)
B.room("West Midway", G, 1, -46, -1, -70, -14, 16, -5)
B.room("Midway Avenue", G, 1, -14, -1, -70, 14, 16, -5)
B.room("East Midway", G, 1, 14, -1, -70, 46, 16, -5)
B.node(G, 0, 0.05, -82)
B.node(G, -72, 0.05, -72)
B.node(G, -80, 0.05, -30)
B.node(G, 64, 0.05, -40)
B.node(G, 66, 0.05, -18, true) -- portaloos (Bathroom)
B.node(G, -42, 0.05, -50)
B.node(G, -30, 0.05, -38.5)
B.node(G, 8, 0.05, -60)
B.node(G, -8, 0.05, -22)
B.node(G, 30, 0.05, -38.5)
B.node(G, 42, 0.05, -24)
-- lane loot (crates / hay / benches)
B.loot(G, 1, V(-1.6, 2.25, -41.5))
B.loot(G, 1, V(31, 4.4, -80))
-- creaky boardwalk planks across the muddy lanes
local BW = B.model(S, "Boardwalk")
for i, p in { V(-42, 0, -36), V(-42, 0, -50), V(42, 0, -30), V(42, 0, -46), V(-30, 0, -62), V(30, 0, -62), V(-30, 0, -15), V(30, 0, -15), V(0, 0, -74), V(-8, 0, -46) } do
	local rot = if math.abs(p.X) > 35 then 0 else 90
	-- boardwalk strip (plain) with a creaky patch in the middle
	local base = CFrame.new(p) * CFrame.Angles(0, math.rad(rot), 0)
	B.rp(BW, "Boards", base, V(4, 0.15, 3), V(0, 0.125, -3.5), C.WoodMid:Lerp(C.Ink, 0.15), M.WoodPlanks, { solid = true, shadow = false })
	B.rp(BW, "Boards", base, V(4, 0.15, 3), V(0, 0.125, 3.5), C.WoodMid:Lerp(C.Ink, 0.15), M.WoodPlanks, { solid = true, shadow = false })
	if i <= 7 then
		B.creak(p.X, 0.18, p.Z, rot)
	else
		B.rp(BW, "Boards", base, V(4, 0.15, 4), V(0, 0.125, 0), C.WoodMid:Lerp(C.Ink, 0.15), M.WoodPlanks, { solid = true, shadow = false })
	end
end
return "midway ok, parts=" .. B.count(root)
