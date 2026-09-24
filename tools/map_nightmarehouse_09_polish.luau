-- NightmareHouse step 9: second audit round. Guarded by NH_Polish.
-- a) throne crown kept under the 14-stud ceiling (back 3..12.4, trim, crest, spikes; top button row dropped)
-- b) attic bare lamps get cords up to the ridge beam (they hung in mid-air in the base house)
-- c) every vein is re-seated on its surface: flat side on the wall/ceiling, 0.14 thick, and a staggered stand-off
--    (0.07..0.13) so overlapping strands are never coplanar (no z-fighting)
-- d) picture scratches / fake-door mortar spread apart so no two faces are coplanar
-- e) hall tree off the wall, dolls out of furniture, back cot finials, trims/rails split around fake doors
local NH = _G.NH
local B, C, M, V3, OX = NH.B, NH.C, Enum.Material, Vector3.new, NH.OX
local H = NH.root()
if H:GetAttribute("NH_Polish") then return "polish already applied" end
H:SetAttribute("NH_Polish", true)
local out = {}
local SM = { small = true }

-- a) throne
local gc = H.GrandmaChair
local TB = CFrame.new(12 + OX, 2, -11.05)
gc.Back.Size = V3(6.4, 9.4, 1.1)
gc.Back.CFrame = CFrame.new(12 + OX, 3 + 4.7, -11.05)
for _, c in gc:GetChildren() do
	if c.Name == "Wing" then
		c.Size = V3(c.Size.X, 7.1, c.Size.Z)
		c.CFrame = CFrame.new(c.Position.X, 5.3 + 3.55, c.Position.Z)
	elseif c.Name == "Button" and c.Position.Y > 12.3 then
		c:Destroy()
	elseif c.Name == "Trim" then
		c.CFrame = TB * CFrame.new(0, 10.55, 0)
	elseif c.Name == "Crest" then
		c.Size = V3(2.2, 1.1, 0.5)
		c.CFrame = TB * CFrame.new(0, 11.25, 0)
	elseif c.Name == "CrestJewel" then
		c.Size = V3(0.5, 0.5, 0.5)
		c.CFrame = TB * CFrame.new(0, 11.25, -0.3)
	elseif c.Name == "Spike" then
		local sx = if c.Position.X > TB.Position.X then 1 else -1
		c.Size = V3(0.7, 1, 0.45)
		c.CFrame = TB * CFrame.new(sx * 1.9, 11.05, 0) * CFrame.Angles(0, 0, math.rad(sx * -12))
	end
end

-- b) attic lamp cords
local ridgeY = 46.6
for _, l in H.Attic:GetChildren() do
	if l.Name == "Lamp_bare" then
		local cf, sz = l:GetBoundingBox()
		local top = cf.Position.Y + sz.Y / 2
		local p = NH.seg(l, "Cord", V3(cf.Position.X, top - 0.05, cf.Position.Z), V3(cf.Position.X, ridgeY + 0.1, cf.Position.Z), 0.1, 0.1, C.Ink, M.SmoothPlastic, SM)
		p.CastShadow = false
	end
end

-- c) veins re-seated on their surfaces
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
local vlist = {}
for _, f in { H.Nightmare.Veins, H.Corruption["1"] } do
	for _, v in f:GetDescendants() do if v:IsA("BasePart") and v.Name == "Vein" then table.insert(vlist, v) end end
end
local skip = {}
for _, v in vlist do table.insert(skip, v) end
rp.FilterDescendantsInstances = skip
local fixedV, lostV = 0, 0
for i, v in vlist do
	local look = v.CFrame.LookVector
	local len = v.Size.Z
	local width = math.max(v.Size.X, 0.14)
	local best
	for _, d in { v.CFrame.RightVector, -v.CFrame.RightVector, v.CFrame.UpVector, -v.CFrame.UpVector } do
		local h = workspace:Raycast(v.Position - d * 0.05, d * 0.9, rp)
		if h and math.abs(h.Normal:Dot(look)) < 0.35 and (not best or h.Distance < best.Distance) then best = h end
	end
	if best then
		local n = best.Normal
		local along = (look - n * look:Dot(n)).Unit
		local off = 0.07 + (i % 4) * 0.02
		-- project the strand centre onto the surface, then stand it off by `off`
		local pos = v.Position + n * (n:Dot(best.Position - v.Position) + off)
		v.Size = V3(width, 0.14, len)
		v.CFrame = CFrame.fromMatrix(pos, along:Cross(n).Unit, n, -along)
		fixedV += 1
	else
		lostV += 1
	end
end
table.insert(out, ("veins re-seated %d (no surface found for %d)"):format(fixedV, lostV))

-- d) scratches and mortar
for _, m in H:GetDescendants() do
	if m:IsA("Model") and (m.Name == "Picture" or m.Name == "GrandpaPortrait" or m.Name == "ShrinePortrait") then
		local frame = m:FindFirstChild("Frame")
		if frame then
			local k = 0
			for _, s in m:GetChildren() do
				if s.Name == "Scratch" then
					k += 1
					s.CFrame += frame.CFrame.LookVector * (0.006 * k)
				end
			end
		end
	elseif m:IsA("Model") and m.Name == "FakeDoor" then
		local bricks = m:FindFirstChild("Bricks")
		for _, s in m:GetChildren() do
			if s.Name == "Mortar" and bricks then
				-- mortar strips sit on the brick face instead of sharing its back plane
				s.Size = V3(s.Size.X, s.Size.Y, 0.04)
				local rel = bricks.CFrame:PointToObjectSpace(s.Position)
				s.CFrame = bricks.CFrame * CFrame.new(rel.X, rel.Y, -(bricks.Size.Z / 2 + 0.02))
			end
		end
	end
end

-- e) third audit round: hall tree off the wall, landing doll off the plant stand, back cot finials (touched rafters),
--    one doll at the end of the Long Hall, and baseboards / chair rails split around every fake door
do
	local ht = H.Ground.EntryHall:FindFirstChild("HallTree")
	if ht then
		local minX = math.huge
		for _, p in ht:GetDescendants() do if p:IsA("BasePart") then minX = math.min(minX, (NH.aabb(p)).X) end end
		local walls = {}
		for _, p in H.Ground:GetChildren() do if p.Name == "Wall" or p.Name == "Trim" then table.insert(walls, p) end end
		local rpW = RaycastParams.new()
		rpW.FilterType = Enum.RaycastFilterType.Include
		rpW.FilterDescendantsInstances = walls
		local c = ht:GetBoundingBox().Position
		local hit = workspace:Raycast(V3(c.X + 3, 4, c.Z), V3(-10, 0, 0), rpW)
		local face = if hit then hit.Position.X else -12.75 + OX
		ht:PivotTo(ht:GetPivot() + V3(face - minX + 0.03, 0, 0))
	end
	for _, d in H.Nightmare.Dolls:GetChildren() do
		local p = d:GetPivot().Position - V3(OX, 0, 0)
		if (V3(p.X, 0, p.Z) - V3(-11.5, 0, 33.3)).Magnitude < 1 and p.Y > 14 then d:PivotTo(d:GetPivot() + V3(0, 0, -2.2)) end
	end
	for _, f in H.Nightmare.Nursery.GiantCot:GetChildren() do
		if f.Name == "Finial" and f.Position.Z > 10 then f:Destroy() end
	end
	local lhd = {}
	for _, d in H.Nightmare.LongHall:GetChildren() do if d.Name == "Doll" then table.insert(lhd, d) end end
	if #lhd == 2 then
		lhd[2]:Destroy()
		local p = lhd[1]:GetPivot()
		lhd[1]:PivotTo(CFrame.new(94 - 0.9 + OX, p.Position.Y, -2.6) * p.Rotation)
	end
	local function splitAround(part, holes)
		local a0, a1 = part.Position.X - part.Size.X / 2, part.Position.X + part.Size.X / 2
		table.sort(holes, function(u, v) return u[1] < v[1] end)
		local segs, cur = {}, a0
		for _, hh in holes do
			if hh[2] > a0 and hh[1] < a1 then
				if hh[1] > cur + 0.05 then table.insert(segs, { cur, hh[1] }) end
				cur = math.max(cur, hh[2])
			end
		end
		if a1 > cur + 0.05 then table.insert(segs, { cur, a1 }) end
		if #segs == 1 and math.abs(segs[1][1] - a0) < 0.01 and math.abs(segs[1][2] - a1) < 0.01 then return 0 end
		for _, s in segs do
			local np = part:Clone()
			np.Size = V3(s[2] - s[1], part.Size.Y, part.Size.Z)
			np.CFrame = CFrame.new((s[1] + s[2]) / 2, part.Position.Y, part.Position.Z) * part.CFrame.Rotation
			np.Parent = part.Parent
		end
		part:Destroy()
		return #segs
	end
	local LH = H.Nightmare.LongHall
	local holesS, holesN = {}, {}
	for _, fd in LH:GetChildren() do
		if fd.Name == "FakeDoor" then
			local zc = fd:GetBoundingBox().Position.Z
			local lo, hi = math.huge, -math.huge
			for _, p in fd:GetChildren() do
				if p.Name == "Casing" then
					local a, b = NH.aabb(p)
					lo, hi = math.min(lo, a.X), math.max(hi, b.X)
				end
			end
			if zc < -3 then table.insert(holesS, { lo, hi }) elseif zc > -2 then table.insert(holesN, { lo, hi }) end
		end
	end
	for _, p in LH:GetChildren() do
		if (p.Name == "Trim" or p.Name == "Rail") and p:IsA("BasePart") then splitAround(p, if p.Position.Z < -3 then holesS else holesN) end
	end
	local WS = H.Nightmare.WrongStairs
	local holes = { { -54.2 + OX, -48.8 + OX }, { -63.2 + OX, -57.8 + OX } }
	for _, p in WS:GetChildren() do if p.Name == "Trim" and p:IsA("BasePart") then splitAround(p, table.clone(holes)) end end
	for _, p in WS.CorridorShell:GetChildren() do if p.Name == "Rail" then splitAround(p, table.clone(holes)) end end
end
table.insert(out, "parts now " .. NH.count())
return table.concat(out, "\n")
