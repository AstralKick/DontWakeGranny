-- Granny's House (Workspace.House) fixes driven by house_14_audit. Idempotent: a second run changes nothing.
-- a) doors: hinge moved 0.2 into the opening and the leaf (+ insets) trimmed 0.2 on the hinge side, so the leaf swung
--    +-30/60/90 clears jamb, casing and wall (same fix as map_nightmarehouse_08_fixes). Guarded by attribute H15_Doors.
-- b) double-leaf hiding furniture: a thin astragal strip (leaf colour) over the 0.04 seam between the two leaves, so the
--    hidden player can't be seen through the crack
-- c) attic bare lamps: the cord is lengthened up into the ridge beam (they hung in mid-air)
-- d) furniture / pictures / lamps pushed out of the wall skins they sank into (depth + 0.02), with the loot/prize spawns
--    resting on them
-- e) stairs: attic steps + east stringer out of the east wall, stringer tops and the main-stair skirt kept below the floor
--    surface they poked through, main-stair steps/noses out of the west wall, redundant east under-stair panel removed,
--    duplicate newels removed (landing + attic), west landing newel / its handrail and the attic corner newels off the
--    walls; living-room armchair slid east (0.53 total) out of Door_LivingHall's -90 swing
-- d2) attic canvases leaning on the knee walls: seated on the floor and resting against the wall
-- g) corruption veins hanging in the air: loose tails trimmed, a branch crossing the arch curve removed
-- f) z-fighting: coplanar, overlapping, exposed faces of different Block parts; one part of each pair is nudged 0.015
--    out along the shared normal (walls/floors/door leaves/creaky patches/helpers never move; otherwise the smaller;
--    a part still coplanar after its first nudge jumps 0.04). Converges; a re-run nudges nothing.
-- Run history (the script grew over several audit rounds): in total 22 doors, 14 astragals, 2 cords, 70 prop pushes,
-- 11 attic pictures, 61 stair/railing edits, armchair 0.53, 2 veins trimmed + 1 removed, ~780 z-fight nudges; parts
-- 5552 -> 5561. The current version re-run on the fixed house reports all zeros.
local CS = game:GetService("CollectionService")
local H = workspace.House
local V3 = Vector3.new
local out = {}
local function isHelper(p) return p.Transparency >= 1 and not p.CanCollide end
local function aabb(p)
	local cf, s = p.CFrame, p.Size
	local e = V3(
		math.abs(cf.RightVector.X) * s.X + math.abs(cf.UpVector.X) * s.Y + math.abs(cf.LookVector.X) * s.Z,
		math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z,
		math.abs(cf.RightVector.Z) * s.X + math.abs(cf.UpVector.Z) * s.Y + math.abs(cf.LookVector.Z) * s.Z
	) / 2
	return cf.Position - e, cf.Position + e
end
-- queries need CanQuery on decor; restored at the end
local savedQ = {}
for _, d in H:GetDescendants() do
	if d:IsA("BasePart") and not isHelper(d) and not d.CanQuery then
		savedQ[d] = true
		d.CanQuery = true
	end
end
local ok, err = pcall(function()
	---------------------------------------------------------------- a) doors
	if not H:GetAttribute("H15_Doors") then
		H:SetAttribute("H15_Doors", true)
		local nd = 0
		for _, m in CS:GetTagged("Door") do
			if m:IsDescendantOf(H) then
				local panel, hinge = m.Panel, m.Hinge
				local far = panel.CFrame.RightVector * (if panel.CFrame:PointToObjectSpace(hinge.Position).X < 0 then 1 else -1)
				hinge.CFrame += far * 0.2
				panel.Size -= V3(0.2, 0, 0)
				panel.CFrame += far * 0.1
				for _, c in m:GetChildren() do
					if c.Name == "Inset" then
						c.Size -= V3(0.2, 0, 0)
						c.CFrame += far * 0.1
					end
				end
				nd += 1
			end
		end
		table.insert(out, "doors re-hinged " .. nd)
	else
		table.insert(out, "doors already re-hinged")
	end

	---------------------------------------------------------------- b) astragals
	local nAst = 0
	for _, m in CS:GetTagged("HidingSpot") do
		if m:IsDescendantOf(H) and not m:FindFirstChild("Astragal", true) then
			local leaves = {}
			for _, c in m:GetDescendants() do if c:IsA("BasePart") and c.Name == "DoorLeaf" then table.insert(leaves, c) end end
			local ins = m:FindFirstChild("Inside", true)
			if #leaves == 2 and ins then
				local a, b = leaves[1], leaves[2]
				local r = a.CFrame.RightVector
				local gap = math.abs((b.Position - a.Position):Dot(r)) - (a.Size.X + b.Size.X) / 2
				if gap > 0 and gap < 0.2 then
					local outward = ins.CFrame.LookVector
					local n = a.CFrame.LookVector * (if a.CFrame.LookVector:Dot(outward) >= 0 then 1 else -1)
					local sgn = if (b.Position - a.Position):Dot(r) > 0 then 1 else -1
					local seam = a.Position + r * sgn * (a.Size.X / 2 + gap / 2)
					local s = Instance.new("Part")
					s.Name = "Astragal"
					s.Anchored = true
					s.CanCollide = false
					s.CanTouch = false
					s.CanQuery = false
					s.CastShadow = false
					s.TopSurface = Enum.SurfaceType.Smooth
					s.BottomSurface = Enum.SurfaceType.Smooth
					s.Color = a.Color
					s.Material = a.Material
					s.MaterialVariant = a.MaterialVariant
					s.Size = V3(gap + 0.12, math.min(a.Size.Y, b.Size.Y), 0.05)
					s.CFrame = a.CFrame.Rotation + seam + n * (a.Size.Z / 2 + 0.025)
					s.Parent = a.Parent
					nAst += 1
				end
			end
		end
	end
	table.insert(out, "astragals added " .. nAst)

	---------------------------------------------------------------- c) attic lamp cords
	local ridge = H.Attic:FindFirstChild("RidgeBeam")
	local nCord = 0
	if ridge then
		local ridgeBottom = ridge.Position.Y - ridge.Size.Y / 2
		for _, l in H.Attic:GetChildren() do
			if l.Name == "Lamp_bare" then
				local cord = l:FindFirstChild("Cord")
				if cord then
					local lo, hi = aabb(cord)
					local target = ridgeBottom + 0.1
					if hi.Y < target - 0.01 then
						-- cord length runs along its X axis (vertical in world): keep the bottom end, extend the top
						local newLen = target - lo.Y
						cord.Size = V3(newLen, cord.Size.Y, cord.Size.Z)
						cord.CFrame = cord.CFrame.Rotation + V3(cord.Position.X, lo.Y + newLen / 2, cord.Position.Z)
						nCord += 1
					end
				end
			end
		end
	end
	table.insert(out, "attic lamp cords extended " .. nCord)

	---------------------------------------------------------------- d) props out of walls
	local SKIP = { Window = true, MainStairs = true, StairRail = true, Railing = true, AtticStairs = true, BasementStairs = true, StairSkirt = true, Stringer = true, UnderStair = true }
	local STRUCT_NAMES = { Wall = true, Trim = true, Rail = true, Casing = true, Window = true, Arch = true, ArchJamb = true, KneeWall = true, Filler = true, Joist = true, Tile = true }
	local roots = {}
	for _, a in { "Ground", "Upstairs", "Basement", "Attic" } do
		for _, c in H[a]:GetChildren() do
			if c:IsA("Folder") then
				for _, cc in c:GetChildren() do
					if not SKIP[cc.Name] and not cc.Name:find("Pipe") and (cc:IsA("Model") or cc:IsA("BasePart")) then table.insert(roots, cc) end
				end
			elseif not SKIP[c.Name] and (c:IsA("Model") or (c:IsA("BasePart") and not STRUCT_NAMES[c.Name] and not c.Name:find("Floor"))) then
				table.insert(roots, c)
			end
		end
	end
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Include
	op.FilterDescendantsInstances = { H.Ground, H.Upstairs, H.Basement, H.Attic, H.Structure }
	local nPush, pushLines = 0, {}
	-- repeated until nothing moves: a prop can sit in both skins of a double wall
	for _iter = 1, 6 do
	local movedThisIter = 0
	for _, root in roots do
		local parts = if root:IsA("BasePart") then { root } else root:GetDescendants()
		local rc = if root:IsA("Model") then root:GetBoundingBox().Position else root.Position
		local push = { X = { 0, 0 }, Z = { 0, 0 } } -- [axis] = { max +, max - }
		for _, p in parts do
			if p:IsA("BasePart") and not isHelper(p) then
				for _, q in workspace:GetPartBoundsInBox(p.CFrame, p.Size, op) do
					if (q.Name == "Wall" or q.Name == "Casing" or q.Name == "BasementWall" or q.Name == "KneeWall") and not q:IsDescendantOf(root) then
						local a0, a1 = aabb(p)
						local b0, b1 = aabb(q)
						local o = V3(math.min(a1.X, b1.X) - math.max(a0.X, b0.X), math.min(a1.Y, b1.Y) - math.max(a0.Y, b0.Y), math.min(a1.Z, b1.Z) - math.max(a0.Z, b0.Z))
						if o.X > 0.02 and o.Y > 0.02 and o.Z > 0.02 then
							local ax = if o.X < o.Z then "X" else "Z"
							local d = o[ax]
							if d <= o.Y then
								local sgn = if (rc - q.Position)[ax] >= 0 then 1 else 2
								push[ax][sgn] = math.max(push[ax][sgn], d)
							end
						end
					end
				end
			end
		end
		local mv = V3()
		local conflict = false
		for _, ax in { "X", "Z" } do
			local pos, neg = push[ax][1], push[ax][2]
			if pos > 0 and neg > 0 then conflict = true
			elseif pos > 0 then mv += (if ax == "X" then V3(1, 0, 0) else V3(0, 0, 1)) * (pos + 0.02)
			elseif neg > 0 then mv -= (if ax == "X" then V3(1, 0, 0) else V3(0, 0, 1)) * (neg + 0.02) end
		end
		if conflict then
			table.insert(pushLines, "  CONFLICT (not moved) " .. root:GetFullName())
		elseif mv.Magnitude > 0 then
			-- loot / prize spawns resting on it travel with it
			local cf, sz
			if root:IsA("Model") then cf, sz = root:GetBoundingBox() else cf, sz = root.CFrame, root.Size end
			for _, f in { H.LootSpawns, H.PrizeSpawns } do
				for _, s in f:GetChildren() do
					local rel = cf:PointToObjectSpace(s.Position)
					if math.abs(rel.X) <= sz.X / 2 + 0.3 and math.abs(rel.Z) <= sz.Z / 2 + 0.3 and rel.Y >= -sz.Y / 2 and rel.Y <= sz.Y / 2 + 1.5 then
						s.CFrame += mv
					end
				end
			end
			if root:IsA("Model") then root:PivotTo(root:GetPivot() + mv) else root.CFrame += mv end
			nPush += 1
			movedThisIter += 1
			table.insert(pushLines, ("  %s moved (%.2f,%.2f)"):format(root:GetFullName():gsub("Workspace%.House%.", ""), mv.X, mv.Z))
		end
	end
	if movedThisIter == 0 then break end
	end
	table.insert(out, "props pushed out of walls " .. nPush)
	for _, l in pushLines do table.insert(out, l) end

	-- attic canvases leaning on the knee walls were all placed by their centre, so the taller ones sank up to 0.26 into
	-- the floor and the shorter ones hovered 0.13 and didn't reach the wall: bottom edge seated on the attic floor
	-- (top y 28.0), top edge against the knee wall face
	local nSeat = 0
	local kneeFace = {}
	for _, kw in H.Attic:GetChildren() do
		if kw.Name == "KneeWall" and kw:IsA("BasePart") then
			local k0, k1 = aabb(kw)
			if kw.Position.Z < 0 then kneeFace[-1] = k1.Z else kneeFace[1] = k0.Z end
		end
	end
	for _, pic in H.Attic:GetChildren() do
		if pic.Name == "Picture" and pic:IsA("Model") then
			local side = if pic:GetPivot().Position.Z < 0 then -1 else 1
			local function ext()
				local minY, wallZ = math.huge, -math.huge
				for _, p in pic:GetDescendants() do
					if p:IsA("BasePart") and p.Transparency < 1 then
						local cf, s = p.CFrame, p.Size / 2
						for _, x in { -1, 1 } do for _, y in { -1, 1 } do for _, z in { -1, 1 } do
							local w = cf * V3(x * s.X, y * s.Y, z * s.Z)
							minY = math.min(minY, w.Y)
							wallZ = math.max(wallZ, w.Z * side)
						end end end
					end
				end
				return minY, wallZ
			end
			local minY, wallZ = ext()
			local face = kneeFace[side]
			local moved = false
			if minY < 29 and math.abs(minY - 28.005) > 0.01 then
				pic:PivotTo(pic:GetPivot() + V3(0, 28.005 - minY, 0))
				moved = true
			end
			if face then
				minY, wallZ = ext()
				local target = face * side - 0.005 -- distance toward the wall, in "side" units
				if math.abs(wallZ - target) > 0.01 and math.abs(wallZ - target) < 1 then
					pic:PivotTo(pic:GetPivot() + V3(0, 0, (target - wallZ) * side))
					moved = true
				end
			end
			if moved then nSeat += 1 end
		end
	end
	table.insert(out, "attic pictures seated " .. nSeat)

	---------------------------------------------------------------- e) stairs
	local nSt = 0
	local as = H.Upstairs:FindFirstChild("AtticStairs")
	local eastFace = 26.75 -- inner face of the stairwell's east wall (x 26.75..27.0)
	if as then
		for _, s in as:GetChildren() do
			if s.Name == "Step" and s:IsA("BasePart") then
				local _, hi = aabb(s)
				if hi.X > eastFace - 0.01 then
					local cut = hi.X - (eastFace - 0.02)
					s.Size -= V3(cut, 0, 0)
					s.CFrame -= V3(cut / 2, 0, 0)
					nSt += 1
				end
			end
		end
	end
	for _, s in H.Upstairs:GetChildren() do
		if s.Name == "Stringer" and s:IsA("BasePart") then
			local lo, hi = aabb(s)
			-- the east stringer was built inside the wall skin (x 26.775..27.025): bring it flush with the wall face so it
			-- matches the west one (overlapping the step ends)
			if hi.X > eastFace + 0.001 and lo.X > eastFace - 0.5 then
				s.CFrame -= V3(hi.X - (eastFace - 0.005), 0, 0)
				nSt += 1
			end
			-- top end kept 0.03 under the attic floor surface (28.0)
			lo, hi = aabb(s)
			local lv = s.CFrame.LookVector
			if hi.Y > 27.975 and lv.Y > 0.1 then
				local d = (hi.Y - 27.97) / lv.Y
				s.Size -= V3(0, 0, d)
				s.CFrame -= lv * (d / 2)
				nSt += 1
			end
		end
	end
	local skirt = H.Ground:FindFirstChild("StairSkirt")
	if skirt then
		local _, hi = aabb(skirt)
		local lv = skirt.CFrame.LookVector
		if hi.Y > 14.985 and lv.Y > 0.1 then
			local d = (hi.Y - 14.98) / lv.Y
			skirt.Size -= V3(0, 0, d)
			skirt.CFrame -= lv * (d / 2)
			nSt += 1
		end
	end
	-- main stair: steps and noses ran 0.25 into the stair-hall skin of the west wall (inner face x = -12.75)
	local ms = H.Ground:FindFirstChild("MainStairs")
	if ms then
		for _, s in ms:GetChildren() do
			if (s.Name == "Step" or s.Name == "Nose") and s:IsA("BasePart") then
				local lo = aabb(s)
				if lo.X < -12.74 and lo.X > -13.3 then
					local cut = -12.73 - lo.X
					s.Size -= V3(cut, 0, 0)
					s.CFrame += V3(cut / 2, 0, 0)
					nSt += 1
				end
			end
		end
	end
	-- east under-stair panel of the attic stair sits inside the east wall (redundant; poked into the stairwell hole)
	for _, u in H.Upstairs:GetChildren() do
		if u.Name == "UnderStair" and u:IsA("BasePart") and u.Position.X > 26.8 and u.Position.X < 27.1 then
			u:Destroy()
			nSt += 1
		end
	end
	-- duplicate newels (two railings sharing a corner post), in both railings
	local newels = {}
	for _, area in { H.Upstairs, H.Attic } do
		for _, r in area:GetChildren() do
			if r.Name == "Railing" then
				for _, c in r:GetChildren() do if c.Name == "Newel" and c:IsA("BasePart") then table.insert(newels, c) end end
			end
		end
	end
	for i = 1, #newels do
		for j = i + 1, #newels do
			local a, b = newels[i], newels[j]
			if a.Parent and b.Parent and (a.Position - b.Position).Magnitude < 0.05 and (a.Size - b.Size).Magnitude < 0.01 then
				b:Destroy()
				nSt += 1
			end
		end
	end
	-- attic railing corner newels 0.05 into the north knee wall
	for _, kw in H.Attic:GetChildren() do
		if kw.Name == "KneeWall" and kw:IsA("BasePart") then
			local k0, k1 = aabb(kw)
			for _, n in newels do
				if n.Parent and n:IsDescendantOf(H.Attic) then
					local a0, a1 = aabb(n)
					local oz = math.min(a1.Z, k1.Z) - math.max(a0.Z, k0.Z)
					local ox = math.min(a1.X, k1.X) - math.max(a0.X, k0.X)
					local oy = math.min(a1.Y, k1.Y) - math.max(a0.Y, k0.Y)
					if oz > 0.001 and ox > 0 and oy > 0 then
						n.CFrame += V3(0, 0, (oz + 0.02) * (if n.Position.Z < kw.Position.Z then -1 else 1))
						nSt += 1
					end
				end
			end
		end
	end
	-- landing handrail's west end 0.05 into the wall
	for _, r in H.Upstairs:GetChildren() do
		if r.Name == "Railing" then
			for _, c in r:GetChildren() do
				if c.Name == "Handrail" and c:IsA("BasePart") and math.abs(c.CFrame.LookVector.X) > 0.99 then
					local lo = aabb(c)
					if lo.X < -12.745 and lo.X > -13.2 then
						local cut = -12.74 - lo.X
						c.Size -= V3(0, 0, cut)
						c.CFrame += V3(cut / 2, 0, 0)
						nSt += 1
					end
				end
			end
		end
	end
	for _, n in newels do
		if n.Parent then
			local lo = aabb(n)
			-- landing newel at the stairwell's west corner sat half inside the wall pair (inner face x = -12.75)
			if lo.X < -12.749 and lo.X > -13.2 then
				n.CFrame += V3(-12.73 - lo.X, 0, 0)
				nSt += 1
			end
		end
	end
	table.insert(out, "stair fixes " .. nSt)

	-- living-room armchair (rotated 40 deg) out of Door_LivingHall's swing: slid east in 0.1 steps until the leaf,
	-- tested every 10 deg from -90 to -10, touches none of it, plus 0.1 margin
	local arm = H.Ground.LivingRoom:FindFirstChild("Armchair")
	local dlh = H.Interactables:FindFirstChild("Door_LivingHall")
	if arm and dlh then
		local sweep = Instance.new("Part")
		sweep.Anchored = true
		sweep.CanCollide = false
		sweep.CanQuery = false
		sweep.Transparency = 1
		sweep.Parent = H
		local opArm = OverlapParams.new()
		opArm.FilterType = Enum.RaycastFilterType.Include
		opArm.FilterDescendantsInstances = { arm }
		local function leafHitsArm()
			for deg = -90, -10, 10 do
				sweep.CFrame = dlh.Hinge.CFrame * CFrame.Angles(0, math.rad(deg), 0) * dlh.Hinge.CFrame:Inverse() * dlh.Panel.CFrame
				sweep.Size = dlh.Panel.Size - V3(0.1, 0.1, 0.1)
				if #workspace:GetPartsInPart(sweep, opArm) > 0 then return true end
			end
			return false
		end
		local base = arm:GetPivot()
		local steps = 0
		while leafHitsArm() and steps < 10 do
			steps += 1
			arm:PivotTo(base + V3(0.1 * steps, 0, 0))
		end
		sweep:Destroy()
		arm:PivotTo(base)
		local cf, sz = arm:GetBoundingBox()
		if steps > 0 then
			local mv = V3(0.1 * steps + 0.1, 0, 0)
			for _, f in { H.LootSpawns, H.PrizeSpawns } do
				for _, s in f:GetChildren() do
					local rel = cf:PointToObjectSpace(s.Position)
					if math.abs(rel.X) <= sz.X / 2 + 0.3 and math.abs(rel.Z) <= sz.Z / 2 + 0.3 and math.abs(rel.Y) <= sz.Y / 2 + 1.5 then s.CFrame += mv end
				end
			end
			arm:PivotTo(arm:GetPivot() + mv)
			table.insert(out, ("armchair moved %.2f east"):format(mv.X))
		end
	end

	---------------------------------------------------------------- g) corruption veins hanging over an opening
	-- 11 samples along each vein; a sample is loose when no surface is within 0.35 across the vein and it isn't buried
	-- in something (veins run into the arch jambs). Loose tail -> the vein is trimmed back to its last supported sample;
	-- loose middle (the branch crossing the living-room arch's curve) -> removed.
	do
		local EX = { H.Corruption, H.Rooms, H.SearchNodes, H.LootSpawns, H.PrizeSpawns }
		local rpV = RaycastParams.new()
		rpV.FilterType = Enum.RaycastFilterType.Exclude
		rpV.FilterDescendantsInstances = EX
		local opV = OverlapParams.new()
		opV.FilterType = Enum.RaycastFilterType.Exclude
		opV.FilterDescendantsInstances = EX
		local nTrim, nDel = 0, 0
		for _, v in H.Corruption:GetDescendants() do
			if v:IsA("BasePart") and v.Name:find("^Vein") then
				local okS = {}
				for i = 0, 10 do
					local t = -0.5 + i / 10
					local p = v.Position + v.CFrame.LookVector * t * v.Size.Z * 0.96
					local hit = false
					for _, d in { v.CFrame.RightVector, -v.CFrame.RightVector, v.CFrame.UpVector, -v.CFrame.UpVector } do
						if workspace:Raycast(p, d * 0.35, rpV) then hit = true break end
					end
					if not hit and #workspace:GetPartBoundsInBox(CFrame.new(p), V3(0.02, 0.02, 0.02), opV) > 0 then hit = true end
					okS[i] = hit
				end
				local first, last = nil, nil
				for i = 0, 10 do if okS[i] then first = first or i last = i end end
				local interiorGap = false
				if first then for i = first, last do if not okS[i] then interiorGap = true end end end
				if not first or interiorGap then
					v:Destroy()
					nDel += 1
				elseif first > 0 or last < 10 then
					-- keep the supported span between the first and last supported samples
					local L = v.Size.Z
					local t0 = if first == 0 then -0.5 else (-0.5 + first / 10) * 0.96
					local t1 = if last == 10 then 0.5 else (-0.5 + last / 10) * 0.96
					v.CFrame += v.CFrame.LookVector * ((t0 + t1) / 2) * L
					v.Size = V3(v.Size.X, v.Size.Y, (t1 - t0) * L)
					nTrim += 1
				end
			end
		end
		table.insert(out, ("loose veins: trimmed %d, removed %d"):format(nTrim, nDel))
	end

	---------------------------------------------------------------- f) z-fighting
	local function immovable(p)
		local n = p.Name
		if n:find("Pipe") then return false end
		if n == "Wall" or n == "Siding" or n == "EndWall" or n:find("Floor") or n:find("Ceiling") or n == "Roof" or n:find("Facade") or n == "Foundation" or n == "BasementWall" or n == "BasementSlab" or n == "KneeWall" or n == "Grass" then return true end
		local m = p:FindFirstAncestorOfClass("Model")
		if m and CS:HasTag(m, "Door") and (n == "Panel" or n == "Hinge") then return true end
		if CS:HasTag(p, "Creaky") then return true end
		return false
	end
	local probe = Instance.new("Part")
	probe.Anchored = true
	probe.CanCollide = false
	probe.CanQuery = false
	probe.CanTouch = false
	probe.Transparency = 1
	probe.Size = V3(0.02, 0.02, 0.02)
	probe.Parent = H
	local opA = OverlapParams.new()
	opA.FilterType = Enum.RaycastFilterType.Include
	opA.FilterDescendantsInstances = { H }
	local function exposed(pt)
		probe.CFrame = CFrame.new(pt)
		for _, q in workspace:GetPartsInPart(probe, opA) do
			if q ~= probe and not isHelper(q) then return false end
		end
		return true
	end
	local nudged = {}
	for pass = 1, 12 do
		local buckets = {}
		for _, p in H:GetDescendants() do
			if p:IsA("Part") and p.Shape == Enum.PartType.Block and p.Transparency < 0.95 and p ~= probe then
				local cf, s = p.CFrame, p.Size
				for _, f in { { cf.RightVector, s.X, s.Y, s.Z, cf.UpVector, cf.LookVector }, { cf.UpVector, s.Y, s.X, s.Z, cf.RightVector, cf.LookVector }, { cf.LookVector, s.Z, s.X, s.Y, cf.RightVector, cf.UpVector } } do
					for _, sg in { 1, -1 } do
						local n = f[1] * sg
						local center = cf.Position + n * f[2] / 2
						local key = ("%d,%d,%d|%d"):format(math.round(n.X * 200), math.round(n.Y * 200), math.round(n.Z * 200), math.round(center:Dot(n) * 50))
						buckets[key] = buckets[key] or {}
						table.insert(buckets[key], { p = p, c = center, u = f[5], v = f[6], hu = f[3] / 2, hv = f[4] / 2, n = n })
					end
				end
			end
		end
		local moves, moved, stuck = {}, {}, 0
		for _, list in buckets do
			if #list > 1 and #list < 400 then
				for i = 1, #list do
					for j = i + 1, #list do
						local A, Bf = list[i], list[j]
						if A.p ~= Bf.p and math.abs((A.c - Bf.c):Dot(A.n)) < 0.012 then
							local du, dv = (Bf.c - A.c):Dot(A.u), (Bf.c - A.c):Dot(A.v)
							local bu = math.abs(Bf.u:Dot(A.u)) * Bf.hu + math.abs(Bf.v:Dot(A.u)) * Bf.hv
							local bv = math.abs(Bf.u:Dot(A.v)) * Bf.hu + math.abs(Bf.v:Dot(A.v)) * Bf.hv
							local ou = math.min(A.hu, du + bu) - math.max(-A.hu, du - bu)
							local ov = math.min(A.hv, dv + bv) - math.max(-A.hv, dv - bv)
							if ou > 0.05 and ov > 0.05 then
								local uc = (math.min(A.hu, du + bu) + math.max(-A.hu, du - bu)) / 2
								local vc = (math.min(A.hv, dv + bv) + math.max(-A.hv, dv - bv)) / 2
								if exposed(A.c + A.u * uc + A.v * vc + A.n * 0.03) then
									local ia, ib = immovable(A.p), immovable(Bf.p)
									local pick
									if ia and not ib then pick = Bf.p elseif ib and not ia then pick = A.p elseif (not ia and not ib) or (A.p.Name == "Roof" and Bf.p.Name == "Roof") then
										-- two roof boards may slide against each other; walls / floors never
										local va, vb = A.p.Size.X * A.p.Size.Y * A.p.Size.Z, Bf.p.Size.X * Bf.p.Size.Y * Bf.p.Size.Z
										pick = if va <= vb then A.p else Bf.p
									else
										stuck += 1
									end
									if pick and not moved[pick] then
										moved[pick] = true
										table.insert(moves, { pick, A.n })
									end
								end
							end
						end
					end
				end
			end
		end
		-- 0.015 first; a part that is still coplanar after a nudge (veins are stacked 0.015 apart) jumps 0.04
		for _, mv in moves do
			local k = nudged[mv[1]] or 0
			mv[1].CFrame += mv[2] * (if k == 0 then 0.015 else 0.04)
			nudged[mv[1]] = k + 1
		end
		table.insert(out, ("z-fight pass %d: nudged %d (both immovable %d)"):format(pass, #moves, stuck))
		if #moves == 0 then break end
	end
	probe:Destroy()
end)
for p in savedQ do if p.Parent then p.CanQuery = false end end
if not ok then table.insert(out, "ERROR " .. tostring(err)) end
local n = 0
for _, d in H:GetDescendants() do if d:IsA("BasePart") then n += 1 end end
table.insert(out, "parts now " .. n)
return table.concat(out, "\n")
