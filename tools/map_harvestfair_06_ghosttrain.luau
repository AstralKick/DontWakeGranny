-- HarvestFair "Basement" zone = THE GHOST TRAIN (night 3): dark ride building x -100..-60, z 65..105.
-- Ring of ride corridors round a maintenance block (track, 2 static cars = hiding spots, pop-up scenes),
-- boarded IN/OUT ride doors (Barriers), a ramp in the maintenance room down to the maintenance tunnel ring
-- (floor y -10). Queue canopy outside. Section "ghosttrain" (idempotent).
local B = _G.HF
local C, M = B.C, B.M
local V = Vector3.new
local root = B.root()
local S = B.begin("ghosttrain")
local SM = { small = true }
local BA = "Basement"
local function sdoor(par, name, center, dir, w, h, col, kind, danger)
	local p = B.part(par, name, V(w, h, 0.12), CFrame.lookAt(center, center + dir), col, M.Wood, { collide = false, shadow = false })
	return B.searchable(p, kind, BA, danger or 2)
end
local Y0, YT = 0.08, 14
local TY = -10 -- tunnel floor top
local TC = -1.5 -- tunnel ceiling (ride floor slab bottom)
local black = C.Ink:Lerp(C.Night, 0.3)
local wallIn = C.Night:Lerp(C.Ink, 0.5)
local outC1, outC2 = C.Teal:Lerp(C.Ink, 0.45), C.Night:Lerp(C.Ink, 0.2)

----------------------------------------------------------------- shell
local SH = B.model(S, "Shell")
-- ride floor slab with the ramp hole x -84..-76, z 75.5..93
local fl = C.Ink:Lerp(C.WoodDark, 0.5)
B.box(SH, "RideFloor", -100, TC, 65, -84, Y0, 105, fl, M.WoodPlanks, { solid = true })
B.box(SH, "RideFloor", -76, TC, 65, -60, Y0, 105, fl, M.WoodPlanks, { solid = true })
B.box(SH, "RideFloor", -84, TC, 65, -76, Y0, 75.5, fl, M.WoodPlanks, { solid = true })
B.box(SH, "RideFloor", -84, TC, 93, -76, Y0, 105, fl, M.WoodPlanks, { solid = true })
-- outer walls; IN door x -97, OUT door x -63 on the south wall
B.stripes(SH, "OuterWall", "x", 65.25, -100, -60, Y0, YT, 0.5, outC1, outC2, 5, { B.DG(-96), B.DG(-64) }, M.WoodPlanks)
B.stripes(SH, "OuterWall", "x", 104.75, -100, -60, Y0, YT, 0.5, outC1, outC2, 5, nil, M.WoodPlanks)
B.stripes(SH, "OuterWall", "z", -99.75, 65.5, 104.5, Y0, YT, 0.5, outC1, outC2, 5, nil, M.WoodPlanks)
B.stripes(SH, "OuterWall", "z", -60.25, 65.5, 104.5, Y0, YT, 0.5, outC1, outC2, 5, nil, M.WoodPlanks)
B.box(SH, "Roof", -100.5, YT, 64.5, -59.5, YT + 0.5, 105.5, C.Ink, M.Slate, { solid = true })
-- inner black lining on the corridor side of the outer walls (painted)
B.doorway(SH, "x", 65.25, -96, Y0, 0.5, C.WoodDark)
B.doorway(SH, "x", 65.25, -64, Y0, 0.5, C.WoodDark)
B.door(SH, "RideDoorIn", "x", 65.25, -96, Y0, BA, true, false, C.Blood:Lerp(C.Ink, 0.35), 1)
B.door(SH, "RideDoorOut", "x", 65.25, -64, Y0, BA, true, false, C.Blood:Lerp(C.Ink, 0.35), -1)
-- false front facade (south) above the roof line
local FF = B.model(S, "Facade")
B.box(FF, "FalseFront", -100, YT + 0.5, 64.9, -60, 22, 65.4, C.Night:Lerp(C.Ink, 0.3), M.WoodPlanks, { solid = true })
local sg = B.box(FF, "Sign", -92, 15.5, 64.6, -68, 20.5, 64.9, C.Ink, M.Wood, SM)
B.text(sg, "GHOST TRAIN", { face = Enum.NormalId.Front, color = C.Mint, font = Enum.Font.Creepster, pps = 16 })
for _, x in { -96, -64 } do
	local e = B.model(FF, "GhostHead")
	B.part(e, "Sheet", V(0.1, 4.4, 4.4), CFrame.new(x, 18, 64.85) * CFrame.Angles(0, math.rad(90), 0), C.Sheet, M.Fabric, { small = true, shape = Enum.PartType.Cylinder })
	for _, dx in { -0.7, 0.7 } do
		B.part(e, "Eye", V(0.1, 0.8, 0.8), CFrame.new(x + dx, 18.4, 64.75) * CFrame.Angles(0, math.rad(90), 0), C.Ink, M.SmoothPlastic, { small = true, shape = Enum.PartType.Cylinder })
	end
	B.part(e, "Mouth", V(0.1, 1, 1), CFrame.new(x, 17.1, 64.75) * CFrame.Angles(0, math.rad(90), 0), C.Ink, M.SmoothPlastic, { small = true, shape = Enum.PartType.Cylinder })
end
-- station canopy over the queue (Ground)
do
	local m = B.model(S, "QueueCanopy")
	B.box(m, "Canopy", -100, 10, 58, -60, 10.4, 65, C.Plum:Lerp(C.Ink, 0.4), M.Fabric, { solid = true })
	-- station platform flush with the ride floor (a level threshold at the ride doors keeps Grandma's path clean)
	B.box(m, "StationPlatform", -99.2, -0.3, 58.6, -60.8, Y0, 65, C.WoodMid:Lerp(C.Ink, 0.35), M.WoodPlanks, { solid = true, shadow = false })
	for _, x in { -99.5, -80, -60.5 } do
		B.box(m, "CanopyPost", x - 0.25, 0.05, 58, x + 0.25, 10, 58.5, C.Ink, M.Metal, { solid = true })
	end
	for i = 0, 7 do
		local x = -100 + i * 5
		B.part(m, "Scallop", V(5, 1, 0.1), CFrame.new(x + 2.5, 9.5, 57.95), if i % 2 == 0 then C.Mint:Lerp(C.Ink, 0.4) else C.Plum:Lerp(C.Ink, 0.3), M.Fabric, SM)
	end
	B.lamp(m, "bare", CFrame.new(-80, 10, 61.5), "Ground", { drop = 1.5, range = 22, bright = 0.9, color = Color3.fromRGB(190, 255, 200) })
	-- queue rails (rope posts) leading to the IN door
	for i = 0, 4 do
		local z = 59 + i * 1.2
		B.part(m, "QueuePost", V(0.35, 3, 0.35), CFrame.new(-92, 1.55, z), C.Gold:Lerp(C.Ink, 0.4), M.Metal, SM)
	end
	B.part(m, "QueueRope", V(0.12, 0.12, 4.8), CFrame.new(-92, 2.7, 61.4), C.Blood:Lerp(C.Ink, 0.2), M.Fabric, SM)
	B.bench(m, B.cf(-80, 0.05, 50, "+z"), 6)
	B.loot("Ground", 1, V(-80, 2.0, 50))
	local tb = B.box(m, "RideSign", -88, 1, 64.5, -84, 5, 65, C.Paper:Lerp(C.Ink, 0.2), M.Wood, SM)
	B.text(tb, "YOU MUST BE\nTHIS BRAVE\nTO RIDE", { face = Enum.NormalId.Front, color = C.Ink, stroke = C.Paper, strokeT = 1, font = Enum.Font.SpecialElite })
end

----------------------------------------------------------------- central maintenance block x -88..-72, z 75..97 (walls 0.5)
local MB = B.model(S, "MaintenanceBlock")
B.wall(MB, "BlockWall", "x", 75.25, -88, -72, Y0, YT, 0.5, wallIn, M.WoodPlanks)
B.wall(MB, "BlockWall", "x", 96.75, -88, -72, Y0, YT, 0.5, wallIn, M.WoodPlanks, { B.DG(-80) })
B.wall(MB, "BlockWall", "z", -87.75, 75.5, 96.5, Y0, YT, 0.5, wallIn, M.WoodPlanks)
B.wall(MB, "BlockWall", "z", -72.25, 75.5, 96.5, Y0, YT, 0.5, wallIn, M.WoodPlanks)
B.doorway(MB, "x", 96.75, -80, Y0, 0.5, C.WoodDark)
B.door(MB, "MaintenanceDoor", "x", 96.75, -80, Y0, BA, true, true, C.Metal:Lerp(C.Mustard, 0.2), 1)
local ds = B.box(MB, "StaffSign", -81.6, 9.2, 97, -78.4, 10.4, 97.05, C.Mustard, M.SmoothPlastic, SM)
B.text(ds, "STAFF ONLY", { face = Enum.NormalId.Back, color = C.Ink, stroke = C.Mustard, strokeT = 1 })
-- ramp down (x -84..-76) from z 93 (y 0.08) to z 75.5 (y -10), rails along the hole
B.ramp(MB, "TunnelRamp", "z", 75.5, 93, -80, 8, TY, Y0, C.Concrete, M.Concrete)
B.rail(MB, V(-84.2, Y0, 75.5), V(-84.2, Y0, 93), 3.4, C.Mustard:Lerp(C.Ink, 0.3))
B.rail(MB, V(-75.8, Y0, 75.5), V(-75.8, Y0, 93), 3.4, C.Mustard:Lerp(C.Ink, 0.3))
B.lamp(MB, "hang", CFrame.new(-80, YT, 94.5), BA, { range = 20, shade = C.Mustard:Lerp(C.Ink, 0.4) })
-- side bays: control desk, spare pop-ups, crates
do
	local m = B.model(S, "ControlBay")
	B.box(m, "Desk", -87.5, Y0, 84, -85.3, 3.3, 90, C.Metal:Lerp(C.Ink, 0.3), M.Metal, { solid = true })
	for i = 0, 3 do
		B.box(m, "Lever", -86.6, 3.3, 85 + i * 1.2, -86.4, 4.4, 85.2 + i * 1.2, if i == 2 then C.Blood else C.Paper, M.Metal, SM)
	end
	sdoor(m, "DeskDrawer", V(-85.24, 2.6, 87), V(1, 0, 0), 2, 0.7, C.Metal, "Drawer")
	B.loot(BA, 3, V(-86.4, 3.3, 89.2))
	B.crate(m, B.cf(-86, Y0, 78.5, 10), 2.6)
	B.loot(BA, 3, V(-86, 2.68, 78.5))
	-- spare skeleton on a hook (decor) east bay
	B.box(m, "Hook", -73.6, 9, 86.9, -72.5, 9.3, 87.1, C.Metal, M.Metal, SM)
	B.part(m, "SpareSkull", V(1.1, 1.1, 1.1), CFrame.new(-73.9, 8.45, 87), C.Paper, M.SmoothPlastic, { small = true, shape = Enum.PartType.Ball })
	for k = 0, 3 do
		B.box(m, "Rib", -74.4, 5.3 + k * 0.5, 86.3, -73.4, 5.45 + k * 0.5, 87.7, C.Paper, M.SmoothPlastic, SM)
	end
	B.box(m, "Spine", -74, 3.2, 86.93, -73.8, 7.9, 87.07, C.Paper, M.SmoothPlastic, SM)
	B.box(m, "PaintShelf", -73.5, 4, 78, -72.5, 4.2, 83, C.WoodDark, M.Wood, SM)
	B.jarBreak(m, V(-73, 4.2, 79.5), C.Mint, 0.8)
	B.jarBreak(m, V(-73, 4.2, 81.5), C.Blood:Lerp(C.Paper, 0.3), 0.8)
	B.loot(BA, 3, V(-73, 4.2, 80.5))
	B.node(BA, -80, Y0, 95)
end

----------------------------------------------------------------- track (rails + dark bed) round the ring, 2 from the outer walls
local TR = B.model(S, "Track")
local function track(a, b)
	local d = b - a
	local len = d.Magnitude
	local mid = (a + b) / 2
	local cf = CFrame.lookAt(mid, b)
	B.part(TR, "TrackBed", V(3, 0.04, len), cf + V(0, 0.02, 0), C.Ink, M.Slate, { small = true, collide = false })
	for _, sx in { -0.8, 0.8 } do
		B.part(TR, "Rail", V(0.2, 0.15, len), cf * CFrame.new(sx, 0.075, 0) + V(0, 0.04, 0), C.Metal, M.Metal, { small = true, collide = false })
	end
end
track(V(-97.5, Y0, 70.5), V(-97.5, Y0, 102.8))
track(V(-96, Y0, 102.8), V(-64, Y0, 102.8))
track(V(-62.5, Y0, 102.8), V(-62.5, Y0, 70.5))

----------------------------------------------------------------- ghost-train cars (static) = HidingSpots
local function car(name, pos, look, col)
	local m = B.model(S, name)
	local b = CFrame.lookAt(pos, pos + look)
	B.rp(m, "Chassis", b, V(3.4, 0.6, 5.4), V(0, 0.5, 0), C.Ink, M.Metal, { solid = true })
	for _, sx in { -1, 1 } do
		B.rp(m, "Side", b, V(0.3, 2.6, 5.4), V(sx * 1.55, 2.1, 0), col, M.Metal, { solid = true })
		for _, zz in { -1.8, 1.8 } do
			B.cyl(m, "Wheel", b, 0.8, 0.3, V(sx * 1.2, 0.4, zz), C.Metal:Lerp(C.Ink, 0.4), M.Metal, SM, false)
		end
	end
	B.rp(m, "Back", b, V(2.8, 3.4, 0.3), V(0, 2.5, 2.55), col, M.Metal, { solid = true })
	B.rp(m, "Nose", b, V(2.8, 2, 0.3), V(0, 1.8, -2.55), col, M.Metal, { solid = true })
	-- front: a grinning ghost figurehead
	B.rp(m, "Figurehead", b, V(3, 2.4, 0.4), V(0, 4, -2.55), C.Sheet, M.SmoothPlastic, { solid = true })
	for _, sx in { -0.6, 0.6 } do
		B.rp(m, "Eye", b, V(0.5, 0.6, 0.1), V(sx, 4.3, -2.8), C.Ink, M.SmoothPlastic, SM)
	end
	B.rp(m, "Grin", b, V(1.6, 0.3, 0.1), V(0, 3.4, -2.8), C.Ink, M.SmoothPlastic, SM)
	B.rp(m, "Seat", b, V(2.8, 0.5, 1.6), V(0, 1.05, 1.4), C.Blood:Lerp(C.Ink, 0.3), M.Fabric, { solid = true })
	B.rp(m, "SeatBack", b, V(2.8, 1.8, 0.4), V(0, 2.1, 2.2), C.Blood:Lerp(C.Ink, 0.3), M.Fabric, SM)
	B.rp(m, "SafetyBar", b, V(2.8, 0.2, 0.2), V(0, 3.1, 0), C.Mustard, M.Metal, SM)
	return m, b
end
do
	local m, b = car("GhostTrainCar", V(-97.5, Y0, 80), V(0, 0, 1), C.Red:Lerp(C.Ink, 0.35))
	local ins = (b * CFrame.new(0, 0.9, 0.6)).Position
	B.hideParts(m, "Cabinet", BA, CFrame.lookAt(ins, ins + V(1, 0, 0)), V(-93.2, Y0, 80), V(-93, Y0, 81.8))
end
do
	local m, b = car("GhostTrainCar", V(-62.5, Y0, 88), V(0, 0, -1), C.Teal:Lerp(C.Ink, 0.4))
	local ins = (b * CFrame.new(0, 0.9, 0.6)).Position
	B.hideParts(m, "Cabinet", BA, CFrame.lookAt(ins, ins + V(-1, 0, 0)), V(-66.8, Y0, 88), V(-67, Y0, 86.2))
end
B.loot(BA, 2, V(-97.5, 1.38, 78.6))

----------------------------------------------------------------- pop-up scenes (on the block walls / overhead)
do
	local m = B.model(S, "Scenes")
	-- west: coffin with a skeleton sitting up
	local cb = CFrame.lookAt(V(-89.4, Y0, 90), V(-89.4, Y0, 80))
	B.rp(m, "Coffin", cb, V(2.6, 1.6, 6), V(0, 0.8, 0), C.WoodDark, M.Wood, { solid = true })
	B.rp(m, "CoffinLid", cb, V(2.6, 0.3, 6), V(-1.5, 2.5, 0), C.WoodDark:Lerp(C.Ink, 0.2), M.Wood, SM, CFrame.Angles(0, 0, math.rad(-70)))
	B.ball(m, "Skull", cb, 1.2, V(0, 3.4, -1.8), C.Paper, M.SmoothPlastic, SM)
	for _, sx in { -0.25, 0.25 } do B.rp(m, "Socket", cb, V(0.3, 0.3, 0.1), V(sx, 3.5, -2.4), C.Ink, M.SmoothPlastic, SM) end
	B.rp(m, "Ribcage", cb, V(1.2, 1.2, 0.5), V(0, 2.3, -1.8), C.Paper, M.SmoothPlastic, SM)
	B.loot(BA, 2, (cb * CFrame.new(0, 1.6, 1.6)).Position)
	B.prize(BA, (cb * CFrame.new(0, 1.6, 0.3)).Position)
	-- north: hanging sheet ghosts over the track
	for i, x in { -92, -84, -76, -68 } do
		local g = B.model(m, "HangingGhost")
		local p = V(x, 8.5, 101.5)
		B.part(g, "Wire", V(0.05, 5.4, 0.05), CFrame.new(p + V(0, 2.8, 0)), C.Ink, M.SmoothPlastic, SM)
		B.part(g, "Head", V(1.8, 1.8, 1.8), CFrame.new(p), C.Sheet, M.Fabric, { small = true, shape = Enum.PartType.Ball })
		B.part(g, "Drape", V(2.4, 3, 1.6), CFrame.new(p - V(0, 1.8, 0)) * CFrame.Angles(0, math.rad(i * 20), 0), C.Sheet:Lerp(C.Ink, 0.08), M.Fabric, SM)
		for _, dx in { -0.35, 0.35 } do
			B.part(g, "Eye", V(0.3, 0.4, 0.1), CFrame.new(p + V(dx, 0.2, -0.88)), C.Ink, M.SmoothPlastic, SM)
		end
	end
	-- east: cauldron with glowing brew + a big spider in a web (friendly-spooky)
	local cz = 80
	B.cyl(m, "Cauldron", CFrame.new(-70.6, Y0, cz), 2.4, 2, V(0, 1, 0), C.Ink, M.Metal, { solid = true }, true)
	B.cyl(m, "Brew", CFrame.new(-70.6, Y0, cz), 2.1, 0.1, V(0, 2.02, 0), C.Mint:Lerp(C.Paper, 0.1), M.Neon, SM, true)
	B.part(m, "SpiderBody", V(1.8, 1.8, 1.8), CFrame.new(-71, 9, 92), C.Ink, M.Fabric, { small = true, shape = Enum.PartType.Ball })
	for k = 0, 3 do
		for _, sx in { -1, 1 } do
			B.part(m, "Leg", V(0.12, 0.12, 2.6), CFrame.new(-71, 9, 92 + (k - 1.5) * 0.5) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, math.rad(sx * 40), math.rad(sx * 30)) * CFrame.new(0, 0, -1.3 * sx), C.Ink, M.Fabric, SM)
		end
	end
	for _, dx in { -0.3, 0.3 } do B.part(m, "SpiderEye", V(0.2, 0.2, 0.2), CFrame.new(-70.15, 9.2, 92 + dx), Color3.fromRGB(255, 70, 70), M.Neon, SM) end
	-- scene lamps (coloured)
	B.lamp(m, "bare", CFrame.new(-93, YT, 86), BA, { drop = 2.5, range = 22, bright = 0.9, color = Color3.fromRGB(140, 255, 170), bulb = Color3.fromRGB(150, 255, 170) })
	B.lamp(m, "bare", CFrame.new(-80, YT, 101), BA, { drop = 2.5, range = 22, bright = 0.9, color = Color3.fromRGB(190, 140, 255), bulb = Color3.fromRGB(200, 160, 255) })
	B.lamp(m, "bare", CFrame.new(-66, YT, 80), BA, { drop = 2.5, range = 22, bright = 0.9, color = Color3.fromRGB(255, 120, 110), bulb = Color3.fromRGB(255, 130, 120) })
	-- station: operator stand at the south corridor
	B.box(m, "OperatorStand", -82, Y0, 66, -78, 3.4, 67.6, C.Blood:Lerp(C.Ink, 0.4), M.Wood, { solid = true })
	sdoor(m, "TicketDrawer", V(-80, 2.7, 67.66), V(0, 0, 1), 2.4, 0.8, C.WoodDark, "Drawer")
	B.loot(BA, 2, V(-81, 3.4, 66.8))
	B.loot(BA, 2, V(-70.6, 2.12, cz))
	B.creak(-88, Y0, 70, 0)
	B.creak(-74, Y0, 70, 0)
	B.node(BA, -92, Y0, 86)
	B.node(BA, -80, Y0, 100.5)
	B.node(BA, -67, Y0, 84)
	B.node(BA, -80, Y0, 71)
end

----------------------------------------------------------------- maintenance tunnel (floor y -10, ceiling -1.5), ring round the ramp
do
	local m = B.model(S, "MaintenanceTunnel")
	local tc = C.Concrete:Lerp(C.Ink, 0.25)
	B.box(m, "TunnelFloor", -93.5, TY - 1, 65.5, -66.5, TY, 104.5, C.Concrete:Lerp(C.Ink, 0.35), M.Concrete, { solid = true })
	B.wall(m, "TunnelWall", "z", -93.25, 65.5, 104.5, TY, TC, 0.5, tc, M.Concrete)
	B.wall(m, "TunnelWall", "z", -66.75, 65.5, 104.5, TY, TC, 0.5, tc, M.Concrete)
	B.wall(m, "TunnelWall", "x", 65.75, -93, -67, TY, TC, 0.5, tc, M.Concrete)
	B.wall(m, "TunnelWall", "x", 104.25, -93, -67, TY, TC, 0.5, tc, M.Concrete)
	-- pillar round the ramp
	B.wall(m, "PillarWall", "z", -84.25, 75.5, 97, TY, TC, 0.5, tc, M.Concrete)
	B.wall(m, "PillarWall", "z", -75.75, 75.5, 97, TY, TC, 0.5, tc, M.Concrete)
	B.wall(m, "PillarWall", "x", 96.75, -84, -76, TY, TC, 0.5, tc, M.Concrete)
	-- pipes + cable trays along the outer walls
	for _, x in { -92.6, -67.4 } do
		B.cyl(m, "Pipe", CFrame.new(x, -3.2, 85), 0.7, 38, V(0, 0, 0), C.Metal:Lerp(C.Rose, 0.1), M.Metal, SM, false).CFrame = B.OFF * CFrame.new(x, -3.2, 85) * CFrame.Angles(0, math.rad(90), 0)
	end
	B.cyl(m, "Pipe", CFrame.new(-80, -2.6, 103.6), 0.6, 26, V(0, 0, 0), C.Metal:Lerp(C.Mint, 0.1), M.Metal, SM, false)
	-- work lights
	B.lamp(m, "flood", B.cf(-90, TY, 70, -135), BA, { spot = true, face = Enum.NormalId.Front, angle = 90, range = 26, bright = 1 })
	B.lamp(m, "bare", CFrame.new(-72, TC, 100), BA, { drop = 1.2, range = 20, bright = 0.8 })
	-- maintenance locker (HidingSpot Cabinet)
	B.wardrobe(m, B.cf(-91.35, TY, 88, "+x"), C.Metal:Lerp(C.Teal, 0.25), BA, "Cabinet", { name = "MaintenanceLocker", w = 4.2, d = 3.3, h = 6, doorColor = C.Metal:Lerp(C.Teal, 0.35) })
	-- workbench + toolbox + lockers (searchable) + spare car
	B.box(m, "Workbench", -92.8, TY, 70, -90.4, TY + 3.2, 78, C.WoodRaw, M.Wood, { solid = true })
	sdoor(m, "ToolDrawer", V(-90.34, TY + 2.5, 74), V(1, 0, 0), 2.2, 0.7, C.WoodDark, "Drawer", 3)
	B.loot(BA, 3, V(-91.6, TY + 3.2, 72))
	B.loot(BA, 3, V(-91.6, TY + 3.2, 76.5))
	for i = 0, 2 do
		local z = 80 + i * 2.6
		B.box(m, "Locker", -67, TY, z - 1.2, -68.8, TY + 6, z + 1.2, C.Metal:Lerp(C.Mustard, 0.15 * i), M.Metal, { solid = true })
		if i == 0 then sdoor(m, "LockerDoor", V(-68.86, TY + 3.2, z), V(-1, 0, 0), 2.1, 5.4, C.Metal:Lerp(C.Mustard, 0.15 * i + 0.1), "Cabinet", 3) end
	end
	B.loot(BA, 3, V(-68, TY + 6, 82.6))
	car("SpareCar", V(-70.6, TY, 97.5), V(0, 0, -1), C.Plum:Lerp(C.Ink, 0.3))
	B.loot(BA, 3, V(-70.6, TY + 1.38, 98.9))
	-- engineer's desk with the tunnel prize
	local _, th = B.table(m, B.cf(-80, TY, 101.8, "-z"), 5, 2.4, 3.2, C.WoodDark)
	B.prize(BA, V(-81, TY + th, 101.8))
	B.loot(BA, 3, V(-78.4, TY + th, 101.8))
	B.box(m, "Blueprints", -79.8, TY + th, 101.2, -78.2, TY + th + 0.05, 102.4, C.Glass:Lerp(C.Paper, 0.4), M.SmoothPlastic, SM)
	B.crate(m, B.cf(-90, TY, 101, 15), 3)
	B.loot(BA, 3, V(-90, TY + 3, 101))
	B.barrel(m, B.cf(-72, TY, 69, 0), C.Red:Lerp(C.Ink, 0.4))
	B.creak(-80, TY, 70.5, 0) -- metal grate that rattles, at the ramp foot
	B.node(BA, -88.5, TY, 70.5)
	B.node(BA, -80, TY, 99.5)
	B.node(BA, -71.5, TY, 88)
end

----------------------------------------------------------------- barriers: boards nailed across both ride doors (outside)
local function boards(name, cx)
	local m = B.barrier(name, BA)
	for i, spec in { { 1.4, 6 }, { 3.2, -8 }, { 5.1, 4 }, { 7.0, -5 } } do
		B.part(m, "Board", V(5.8, 0.8, 0.25), CFrame.new(cx, Y0 + spec[1], 64.72) * CFrame.Angles(0, 0, math.rad(spec[2])), C.WoodRaw:Lerp(C.Ink, (i % 3) * 0.12), M.WoodPlanks, { collide = false })
	end
	local s = B.part(m, "Sign", V(3, 1.2, 0.1), CFrame.new(cx, Y0 + 4.2, 64.545) * CFrame.Angles(0, 0, math.rad(-3)), C.Paper, M.Wood, { small = true })
	B.text(s, "RIDE CLOSED", { face = Enum.NormalId.Front, color = C.Blood })
	B.box(m, "Collider", cx - 2.6, 0, 64.2, cx + 2.6, 9, 64.75, C.Paper, M.SmoothPlastic, { inv = true, collide = true })
end
boards("Barrier_Basement", -96)
boards("Barrier_Basement_Out", -64)

----------------------------------------------------------------- rooms
B.room("Ghost Train Station", BA, 2, -88, -1.5, 65.5, -72, YT, 75)
B.room("Ghost Train West", BA, 2, -99.5, -1.5, 65.5, -88, YT, 104.5)
B.room("Ghost Train East", BA, 2, -72, -1.5, 65.5, -60.5, YT, 104.5)
B.room("Haunted Hall", BA, 2, -88, -1.5, 97, -72, YT, 104.5)
B.room("Maintenance Room", BA, 3, -87.5, -1.5, 75.5, -72.5, YT, 96.5)
B.room("Maintenance Tunnel", BA, 3, -93, TY - 0.5, 66, -67, TC, 104)
return "ghost train ok, parts=" .. B.count(root)
