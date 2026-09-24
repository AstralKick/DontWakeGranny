-- Ground floor part A: Entry Hall, Living Room (Grandma's chair), Dining Room. Requires 00..04.
local B = _G.HB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local G = B.FL.Ground
local GF = B.F("Ground")
local SM = { small = true }
local function folder(n) return B.F(n, GF) end

B.room("Entry Hall", "Ground", 1, -13, G, -35, 3, 14, -7)
B.room("Living Room", "Ground", 2, 3, G, -35, 45, 14, -7)
B.room("Dining Room", "Ground", 1, -45, G, -35, -13, 14, -7)

----------------------------------------------------------------- ENTRY HALL
do
	local f = folder("EntryHall")
	B.rug(f, -5, G, -21, 5, 22, C.Rose:Lerp(C.Ink, 0.55), C.Mustard:Lerp(C.Ink, 0.55))
	-- hall tree by the door (bench, hooks, mirror)
	local ht = B.model(f, "HallTree")
	local b = cf(-12.3, G, -31.5, "+x")
	B.rp(ht, "Bench", b, V(3.6, 0.35, 1.3), V(0, 1.9, -0.1), C.WoodDark, M.Wood)
	B.rp(ht, "BenchBox", b, V(3.6, 1.7, 1.2), V(0, 0.85, -0.05), C.WoodDark:Lerp(C.WoodMid, 0.3), M.Wood)
	B.rp(ht, "Back", b, V(3.6, 5.2, 0.25), V(0, 4.6, 0.5), C.WoodDark, M.Wood)
	B.rp(ht, "Mirror", b, V(2.2, 2.2, 0.05), V(0, 5.2, 0.35), Color3.fromRGB(140, 150, 160), M.Glass, { small = true, refl = 0.3 })
	for i, x in { -1.3, 0, 1.3 } do
		B.rp(ht, "Hook", b, V(0.15, 0.15, 0.5), V(x, 7.0, 0.2), C.Brass, M.Metal, SM)
	end
	B.rp(ht, "Coat", b, V(1.1, 2.6, 0.5), V(-1.3, 5.6, 0.05), C.Bruise:Lerp(C.Ink, 0.3), M.Fabric, SM)
	B.rp(ht, "Scarf", b, V(0.4, 2.2, 0.3), V(1.3, 5.7, 0.1), C.Mustard:Lerp(C.Ink, 0.15), M.Fabric, SM)
	B.rp(ht, "Boots", b, V(1.4, 0.8, 0.9), V(1, 0.4, -1.2), C.Ink, M.Rubber, SM)
	B.loot("Ground", 1, (b * CFrame.new(0.9, 2.08, -0.2)).Position)
	-- entry chest of drawers + mirror on the west wall
	B.dresser(f, cf(-12.1, G, -26.8, "+x"), 3.4, 1.6, 3, C.WoodMid, 3, "Ground", 1, { name = "EntryChest", search = { 1 } })
	B.loot("Ground", 1, V(-12.1, G + 3.2, -26.2))
	B.lamp(f, "table", cf(-12.2, G + 3.2, -27.8), "Ground", { shade = C.Mustard, body = C.Rose })
	B.picture(f, cf(-12.75, G + 7, -26.8, "+x"), 2.6, 3.2, { portrait = true, canvas = C.Night, clothes = C.Bruise:Lerp(C.Ink, 0.4), hair = C.Paper:Lerp(C.Ink, 0.4), frame = C.Brass })
	-- console table on the east wall with a vase (Breakable) and key bowl
	B.table(f, cf(2.1, G, -31, "-x"), 3.4, 1.3, 3, C.WoodDark, { name = "Console" })
	B.vase(f, cf(2.1, G + 3, -32.2), C.Mint:Lerp(C.Ink, 0.2), 0.8)
	B.cyl(f, "KeyBowl", cf(2.1, G + 3, -30.3), 0.9, 0.2, V(0, 0.1, 0), C.Rose:Lerp(C.Ink, 0.3), M.Glass, SM, true)
	B.loot("Ground", 1, V(2.1, G + 3.05, -30.1))
	B.picture(f, cf(2.75, G + 7.5, -31, "-x"), 3, 2.2, { scene = C.Mint:Lerp(C.Ink, 0.5), canvas = C.Night:Lerp(C.Bruise, 0.3) })
	-- grandfather clock near the hall arch, umbrella stand
	B.clock(f, cf(-12, G, -11.2, "+x"))
	B.cyl(f, "UmbrellaStand", cf(-12, G, -14.3), 1, 1.8, V(0, 0.9, 0), C.Mint:Lerp(C.Ink, 0.4), M.Metal, { collide = true }, true)
	B.rp(f, "Umbrella", cf(-12, G, -14.3), V(0.2, 3, 0.2), V(0.1, 2.2, 0), C.Ink, M.Fabric, SM)
	B.picture(f, cf(-12.75, G + 7.5, -16.5, "+x"), 2, 2.6, { portrait = true, canvas = C.WoodDark:Lerp(C.Ink, 0.4), clothes = C.Ink, frame = C.WoodDark })
	-- ceiling pendant
	B.lamp(f, "hang", cf(-5, 14, -22), "Ground", { shade = C.Mustard, range = 20, bright = 0.9 })
	-- a basket of yarn by the arch (early loot, visible from the door)
	B.cyl(f, "Basket", cf(1.4, G, -15.5), 1.6, 1.1, V(0, 0.55, 0), C.WoodLight, M.Fabric, { collide = true }, true)
	B.ball(f, "Yarn", cf(1.4, G + 1.1, -15.5), 0.7, V(0.2, 0, 0.1), C.Rose, M.Fabric, SM)
	B.loot("Ground", 1, V(1.4, G + 1.1, -15.2))
	B.node("Ground", -5, G, -30)
	B.node("Ground", -5, G, -14)
	B.creak(-1, G, -22)
	B.creak(-8.5, G, -11)
end

----------------------------------------------------------------- LIVING ROOM (Danger 2) - Grandma's chair
do
	local f = folder("LivingRoom")
	B.rug(f, 12, G, -19.5, 9, 10, C.Rose:Lerp(C.Ink, 0.45), C.Mustard:Lerp(C.Ink, 0.45))
	-- Grandma's chair faces the TV; placed on the sightline door -> entry arch so new players see it at once
	local chairCF = cf(12, G, -13, "-z")
	local chair = B.armchair(B.root(), chairCF, C.Rose:Lerp(C.Ink, 0.08), "GrandmaChair", { w = 5.4, d = 5, trim = C.Bruise, doily = true, throw = C.Mustard:Lerp(C.Ink, 0.15) })
	for _, p in { { -1.2, 4.6 }, { 0, 4.6 }, { 1.2, 4.6 }, { -0.6, 3.6 }, { 0.6, 3.6 } } do
		B.ball(chair, "Button", chairCF, 0.22, V(p[1], p[2], 1.4), C.Mustard, M.Fabric, SM)
	end
	for _, p in { { -1.8, 3.2 }, { 1.7, 4.2 }, { -0.9, 5.4 }, { 0.9, 2.9 } } do
		B.ball(chair, "Flower", chairCF, 0.45, V(p[1], p[2], 1.43), C.Paper:Lerp(C.Rose, 0.4), M.Fabric, SM)
	end
	B.part(B.root(), "GrandmaSleepSpot", V(2, 2, 1), chairCF * CFrame.new(0, 2.3 + 1.3, 0.3), C.Paper, M.SmoothPlastic, { inv = true })
	-- the TV she stares at
	B.tv(f, cf(12, G, -25, "+z"), "Ground")
	-- side table with the reading lamp (shadows) and her tea
	B.table(f, cf(7.9, G, -13.6), 2, 2, 2.8, C.WoodDark, { name = "SideTable" })
	B.lamp(f, "table", cf(7.9, G + 2.8, -14.1), "Ground", { shade = C.Rose, body = C.Mustard, shadows = true, bright = 1.4, range = 14 })
	B.cyl(f, "Teacup", cf(8.3, G + 2.8, -12.9), 0.45, 0.35, V(0, 0.17, 0), C.Paper, M.SmoothPlastic, SM, true)
	B.loot("Ground", 2, V(7.5, G + 2.85, -12.9))
	B.prize("Ground", V(15.9, G, -12.3))
	-- knitting basket + needles
	B.cyl(f, "KnitBasket", cf(16, G, -16.2), 1.5, 1.0, V(0, 0.5, 0), C.WoodLight:Lerp(C.Ink, 0.2), M.Fabric, { collide = true }, true)
	B.ball(f, "Yarn", cf(16, G + 1, -16.2), 0.7, V(-0.2, 0, 0.1), C.Mint, M.Fabric, SM)
	B.ball(f, "Yarn", cf(16, G + 1, -16.2), 0.6, V(0.3, 0, -0.2), C.Mustard, M.Fabric, SM)
	B.rp(f, "Knitting", cf(16, G + 1.2, -16.2), V(1.4, 0.15, 1), V(0, 0.2, 0), C.Rose:Lerp(C.Paper, 0.2), M.Fabric, SM)
	-- footstool
	B.rp(f, "Footstool", cf(12, G, -17.7), V(2.4, 1.1, 1.8), V(0, 0.55, 0), C.Bruise:Lerp(C.Ink, 0.2), M.Fabric)
	-- fireplace on the east wall
	local fp = B.model(f, "Fireplace")
	local fb = cf(44.2, G, -21, "-x")
	B.rp(fp, "Body", fb, V(7.5, 5.5, 1.6), V(0, 2.75, 0), C.Brick:Lerp(C.Ink, 0.15), M.Brick)
	B.rp(fp, "Firebox", fb, V(3.4, 3, 0.3), V(0, 1.6, -0.7), C.Ink, M.Slate, SM)
	local emb = B.rp(fp, "Embers", fb, V(2.6, 0.35, 0.6), V(0, 0.35, -0.6), Color3.fromRGB(150, 50, 30), M.Neon, SM)
	local el = Instance.new("PointLight")
	el.Color = Color3.fromRGB(255, 110, 60)
	el.Range = 10
	el.Brightness = 0.7
	el.Parent = emb
	B.rp(fp, "Grate", fb, V(3, 0.2, 0.2), V(0, 0.8, -0.9), C.Ink, M.Metal, SM)
	B.rp(fp, "Mantel", fb, V(7.6, 0.35, 2.2), V(0, 5.65, -0.3), C.WoodDark, M.Wood)
	B.rp(fp, "Chimney", fb, V(5.6, 6.2, 1.2), V(0, 8.9, 0.2), C.Brick:Lerp(C.Ink, 0.2), M.Brick)
	B.rp(fp, "Hearth", fb, V(8.4, 0.12, 2.6), V(0, 0.06, -1.7), C.Stone, M.Slate, SM)
	B.picture(fp, fb * CFrame.new(0, 9, -0.42), 3.4, 2.6, { portrait = true, canvas = C.Night, clothes = C.Rose:Lerp(C.Ink, 0.4), hair = C.Paper:Lerp(C.Ink, 0.5), frame = C.Brass })
	B.candleSet(fp, (fb * CFrame.new(-3.2, 5.82, -0.3)).Position, 3, 1)
	B.rp(fp, "MantelClock", fb, V(1.4, 1.3, 0.7), V(2.4, 6.5, -0.3), C.WoodMid, M.Wood, SM)
	B.loot("Ground", 2, (fb * CFrame.new(-1.2, 5.82, -0.4)).Position)
	B.loot("Ground", 2, (fb * CFrame.new(1.0, 5.82, -0.4)).Position)
	B.prize("Ground", (fb * CFrame.new(-0.1, 5.82, -0.45)).Position)
	B.rp(fp, "Poker", fb, V(0.1, 3, 0.1), V(4.0, 1.5, -0.9), C.Ink, M.Metal, SM)
	-- sofa facing the fire, coffee table
	B.sofa(f, cf(31.5, G, -21, "+x"), 9, C.Mint:Lerp(C.Ink, 0.3), { pillow = C.Rose })
	B.rp(f, "SofaDoily", cf(31.5, G, -21, "+x"), V(1.8, 0.8, 0.05), V(0, 3.2, 0.87), C.Paper, M.Fabric, SM)
	B.table(f, cf(37, G, -21), 3, 5, 1.8, C.WoodDark, { name = "CoffeeTable", cloth = C.Paper })
	B.loot("Ground", 2, V(37, G + 1.85, -22.2))
	B.rp(f, "Magazines", cf(37, G + 1.8, -19.8), V(1.2, 0.2, 1.5), V(0, 0.1, 0), C.Mustard:Lerp(C.Ink, 0.3), M.Fabric, SM)
	B.armchair(f, cf(40.5, G, -11.5, -140), C.Bruise:Lerp(C.Ink, 0.2), "Armchair", { w = 4.4, d = 4.2, trim = C.Ink })
	-- north wall: bookshelf, curio cabinet
	B.bookshelf(f, cf(9, G, -7.9, "-z"), 5, 8.5, C.WoodDark, { seed = 3, gap = 2 })
	B.loot("Ground", 2, V(10.25, G + 4.33, -8.1))
	local cu = B.model(f, "CurioCabinet")
	local cb = cf(26, G, -8, "-z")
	B.rp(cu, "Base", cb, V(4, 3, 1.8), V(0, 1.5, 0), C.WoodDark, M.Wood)
	local cd = B.rp(cu, "CabinetDoor", cb, V(3.6, 2.4, 0.12), V(0, 1.5, -0.95), C.WoodDark:Lerp(C.WoodMid, 0.4), M.Wood, { collide = false })
	B.searchable(cd, "Cabinet", "Ground", 2)
	B.rp(cu, "Hutch", cb, V(3.8, 4.5, 1.2), V(0, 5.25, 0.25), C.Glass, M.Glass, { tr = 0.6 })
	B.rp(cu, "HutchFrame", cb, V(4, 0.3, 1.4), V(0, 7.6, 0.2), C.WoodDark, M.Wood, SM)
	for i = 0, 2 do
		B.rp(cu, "Shelf", cb, V(3.6, 0.1, 1.0), V(0, 3.6 + i * 1.4, 0.25), C.WoodDark, M.Wood, SM)
		for j = -1, 1 do
			B.ball(cu, "Figurine", cb, 0.45, V(j * 1.1, 3.9 + i * 1.4, 0.25), ({ C.Rose, C.Mint, C.Paper })[(i + j + 2) % 3 + 1], M.SmoothPlastic, SM)
		end
	end
	-- floor vase by the arch (Breakable, on the running path)
	B.vase(f, cf(4.3, G, -27.6), C.Rose:Lerp(C.Ink, 0.25), 1.4)
	B.vase(f, cf(33.2, G, -8.6), C.Bruise:Lerp(C.Paper, 0.2), 1.2)
	-- pictures
	B.picture(f, cf(3.25, G + 7.5, -30.5, "+x"), 2.4, 3, { portrait = true, canvas = C.Night, clothes = C.Ink, hair = C.WoodDark, frame = C.WoodDark })
	B.picture(f, cf(26, G + 9.8, -7.25, "-z"), 3, 2, { scene = C.Rose:Lerp(C.Ink, 0.5), canvas = C.Night })
	B.node("Ground", 19, G, -17)
	B.node("Ground", 28, G, -29)
	B.node("Ground", 35.5, G, -14.5)
	B.pumpkin("Ground", V(38.5, G, -25.5))
	for _, p in { { 5.6, -10.5 }, { 19, -13.5 }, { 19, -21 }, { 5.6, -21 }, { 12, -29 } } do
		B.creak(p[1], G, p[2])
	end
end

----------------------------------------------------------------- DINING ROOM
do
	local f = folder("DiningRoom")
	B.rug(f, -29, G, -21, 18, 10, C.Bruise:Lerp(C.Ink, 0.4), C.Rose:Lerp(C.Ink, 0.5))
	B.table(f, cf(-29, G, -21), 15, 5.2, 3.1, C.WoodMid, { name = "DiningTable", oval = true, cloth = C.Paper })
	for i, x in { -34, -29, -24 } do
		B.chair(f, cf(x, G, -24.4, "+z"), C.WoodDark, { cushion = C.Rose:Lerp(C.Ink, 0.2) })
		B.chair(f, cf(x, G, -17.6, "-z"), C.WoodDark, { cushion = C.Rose:Lerp(C.Ink, 0.2) })
	end
	B.chair(f, cf(-37.8, G, -21, "+x"), C.WoodDark, { cushion = C.Mustard:Lerp(C.Ink, 0.2) })
	B.chair(f, cf(-20.2, G, -21, "-x"), C.WoodDark, { cushion = C.Mustard:Lerp(C.Ink, 0.2) })
	-- place settings + candelabra
	for _, x in { -34, -29, -24 } do
		for _, z in { -23.1, -18.9 } do
			B.cyl(f, "Plate", cf(x, G + 3.1, z), 1.1, 0.06, V(0, 0.03, 0), C.Paper, M.SmoothPlastic, SM, true)
		end
	end
	B.candleSet(f, V(-29, G + 3.1, -21), 3, 2)
	B.loot("Ground", 1, V(-26.3, G + 3.12, -21))
	B.loot("Ground", 1, V(-32, G + 3.12, -21.2))
	-- chandelier
	B.lamp(f, "hang", cf(-29, 14, -21), "Ground", { shade = C.Paper, range = 18, bright = 0.9 })
	-- china cabinet on the west wall (Searchable), plates inside
	local cc = B.model(f, "ChinaCabinet")
	local cb = cf(-44, G, -21, "+x")
	B.rp(cc, "Base", cb, V(6, 3.2, 2), V(0, 1.6, 0), C.WoodDark, M.Wood)
	local d1 = B.rp(cc, "CabinetDoor", cb, V(2.7, 2.5, 0.12), V(-1.45, 1.6, -1.05), C.WoodDark:Lerp(C.WoodMid, 0.4), M.Wood, { collide = false })
	B.rp(cc, "CabinetDoor", cb, V(2.7, 2.5, 0.12), V(1.45, 1.6, -1.05), C.WoodDark:Lerp(C.WoodMid, 0.4), M.Wood, { collide = false })
	B.searchable(d1, "Cabinet", "Ground", 1)
	B.rp(cc, "Hutch", cb, V(5.6, 5, 1.2), V(0, 5.7, 0.3), C.WoodDark, M.Wood)
	B.rp(cc, "Glass", cb, V(5.2, 4.4, 0.08), V(0, 5.7, -0.34), C.Glass, M.Glass, { small = true, tr = 0.65 })
	B.rp(cc, "Crown", cb, V(6.4, 0.4, 2.2), V(0, 8.4, 0), C.WoodDark:Lerp(C.Ink, 0.3), M.Wood, SM)
	for row = 0, 1 do
		for j = -2, 2 do
			B.cyl(cc, "DisplayPlate", cb, 0.95, 0.06, V(j * 1.05, 4.4 + row * 2, 0.2), (if (j + row) % 2 == 0 then C.Paper else C.Mint:Lerp(C.Paper, 0.5)), M.SmoothPlastic, SM, false).CFrame = cb * CFrame.new(j * 1.05, 4.4 + row * 2, 0.2) * CFrame.Angles(math.rad(-10), math.rad(90), 0)
		end
	end
	B.loot("Ground", 1, (cb * CFrame.new(0, 3.2, -0.5)).Position)
	-- sideboard on the north wall with plate stacks (Breakables) at the edge
	B.dresser(f, cf(-39, G, -8.1, "-z"), 7, 2, 3.2, C.WoodMid, 2, "Ground", 1, { name = "Sideboard", search = { 1 } })
	B.plates(f, cf(-36.2, G + 3.4, -8.6), 6)
	B.plates(f, cf(-41.8, G + 3.4, -8.5), 4)
	B.cyl(f, "Teapot", cf(-39, G + 3.4, -8.4), 1, 0.9, V(0, 0.45, 0), C.Mint:Lerp(C.Paper, 0.3), M.SmoothPlastic, SM, true)
	B.loot("Ground", 1, V(-39.8, G + 3.42, -8.4))
	B.picture(f, cf(-39, G + 8, -7.25, "-z"), 4.5, 3, { scene = C.Mint:Lerp(C.Ink, 0.5), canvas = C.Night:Lerp(C.Bruise, 0.4), frame = C.Brass })
	-- tea cart by the kitchen door
	local tc = B.model(f, "TeaCart")
	local tb = cf(-22, G, -9.2, "+z")
	B.rp(tc, "Top", tb, V(3, 0.15, 1.6), V(0, 2.8, 0), C.Brass, M.Metal)
	B.rp(tc, "Lower", tb, V(3, 0.15, 1.6), V(0, 1, 0), C.Brass, M.Metal, SM)
	for _, sx in { -1, 1 } do
		B.cyl(tc, "Wheel", tb, 0.6, 0.15, V(sx * 1.3, 0.3, 0), C.Ink, M.Rubber, SM, false)
		B.rp(tc, "Leg", tb, V(0.1, 2.6, 0.1), V(sx * 1.4, 1.5, 0), C.Brass, M.Metal, SM)
	end
	B.loot("Ground", 1, (tb * CFrame.new(0.5, 2.9, 0)).Position)
	B.vase(f, cf(-15, G, -33.4), C.Mustard:Lerp(C.Ink, 0.3), 1.3)
	B.node("Ground", -29, G, -12)
	B.node("Ground", -38, G, -29)
	B.creak(-20, G, -12.5)
	B.creak(-30, G, -30)
end
return "ground A ok, parts=" .. B.count(B.root())
