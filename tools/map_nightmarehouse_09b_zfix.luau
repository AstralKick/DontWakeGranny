-- NightmareHouse step 9b: z-fighting fixer (idempotent; can be re-run). Finds coplanar, same-facing, overlapping and
-- EXPOSED faces of Block parts (same test as the audit) and nudges one part of each pair 0.015 studs out along the
-- shared normal, so the two faces are never coplanar. Structure (walls/floors/ceilings), door leaves/hinges and contract
-- helpers are never moved; otherwise the smaller part moves. Also removes veins that have no surface behind them.
local CS = game:GetService("CollectionService")
local H = workspace.Maps.NightmareHouse
local V3 = Vector3.new
local savedQ = {}
for _, d in H:GetDescendants() do
	if d:IsA("BasePart") and not (d.Transparency >= 1 and not d.CanCollide) and not d.CanQuery then
		savedQ[d] = true
		d.CanQuery = true
	end
end
local function isHelper(p) return p.Transparency >= 1 and not p.CanCollide end
local function immovable(p)
	local n = p.Name
	if n == "Wall" or n == "Siding" or n == "EndWall" or n:find("Floor") or n:find("Ceiling") or n == "Roof" or n:find("Facade") or n == "Foundation" or n == "BasementWall" or n == "KneeWall" or n == "Grass" then return true end
	local m = p:FindFirstAncestorOfClass("Model")
	if m and CS:HasTag(m, "Door") and (n == "Panel" or n == "Hinge") then return true end
	if CS:HasTag(p, "Creaky") then return true end
	return false
end
local probe = Instance.new("Part")
probe.Anchored = true
probe.CanCollide = false
probe.CanQuery = false
probe.Transparency = 1
probe.Size = V3(0.02, 0.02, 0.02)
probe.Parent = H
local op = OverlapParams.new()
op.FilterType = Enum.RaycastFilterType.Include
op.FilterDescendantsInstances = { H }
local function exposed(pt)
	probe.CFrame = CFrame.new(pt)
	for _, q in workspace:GetPartsInPart(probe, op) do
		if q ~= probe and not isHelper(q) then return false end
	end
	return true
end
local report = {}
local ok, err = pcall(function()
	-- 1) loose veins
	local veins = {}
	for _, f in { H.Nightmare:FindFirstChild("Veins"), H.Corruption:FindFirstChild("1") } do
		if f then for _, v in f:GetDescendants() do if v:IsA("BasePart") and v.Name == "Vein" then table.insert(veins, v) end end end
	end
	local rpV = RaycastParams.new()
	rpV.FilterType = Enum.RaycastFilterType.Exclude
	rpV.FilterDescendantsInstances = veins
	local loose = 0
	for _, v in veins do
		if not workspace:Raycast(v.Position, -v.CFrame.UpVector * 0.35, rpV) then
			v:Destroy()
			loose += 1
		end
	end
	table.insert(report, "loose veins removed " .. loose)
	-- 1b) veins lying in the same plane as an overlapping vein (flat faces coplanar) are duplicates: drop one
	local alive = {}
	for _, v in veins do if v.Parent then table.insert(alive, v) end end
	local dead = {}
	for i = 1, #alive do
		local a = alive[i]
		if not dead[a] then
			for j = i + 1, #alive do
				local b = alive[j]
				local n, nb = a.CFrame.UpVector, b.CFrame.UpVector
				if not dead[b] and math.abs(n:Dot(nb)) > 0.999 then
					local coplanar = false
					for _, sa in { 1, -1 } do
						for _, sb in { 1, -1 } do
							local fa = a.Position + n * sa * a.Size.Y / 2
							local fb = b.Position + nb * sb * b.Size.Y / 2
							if (n * sa):Dot(nb * sb) > 0.999 and math.abs((fa - fb):Dot(n)) < 0.013 then coplanar = true end
						end
					end
					if coplanar then
						local d = b.Position - a.Position
						local sep = false
						for _, axis in { a.CFrame.RightVector, a.CFrame.LookVector, b.CFrame.RightVector, b.CFrame.LookVector } do
							local ra = math.abs(a.CFrame.RightVector:Dot(axis)) * a.Size.X / 2 + math.abs(a.CFrame.LookVector:Dot(axis)) * a.Size.Z / 2
							local rb = math.abs(b.CFrame.RightVector:Dot(axis)) * b.Size.X / 2 + math.abs(b.CFrame.LookVector:Dot(axis)) * b.Size.Z / 2
							if math.abs(d:Dot(axis)) > ra + rb - 0.04 then sep = true break end
						end
						if not sep then dead[b] = true end
					end
				end
			end
		end
	end
	local nDead = 0
	for v in dead do v:Destroy() nDead += 1 end
	table.insert(report, "coplanar duplicate veins removed " .. nDead)
	-- 1c) veins that grew round the outside of the (rolled / skewed) annex shells: the way back to the room centre is blocked
	do
		local OX = 7500
		local walls = {}
		for _, s in { H.Nightmare.WrongStairs.RoomShell, H.Nightmare.WrongStairs.CorridorShell, H.Nightmare.LongHall } do
			for _, p in s:GetDescendants() do
				if p:IsA("BasePart") and (p.Name == "Wall" or p.Name == "Ceiling" or p.Name == "Roof" or p.Name == "Siding" or p.Name == "EndWall") then table.insert(walls, p) end
			end
		end
		local rpW = RaycastParams.new()
		rpW.FilterType = Enum.RaycastFilterType.Include
		rpW.FilterDescendantsInstances = walls
		local outside = 0
		for _, v in veins do
			if v.Parent then
				local lx = v.Position.X - OX
				local c = if lx < -66.5 then V3(-80 + OX, 26, -3) elseif lx < -45.5 then V3(-56 + OX, 21, -3) elseif lx > 45.5 then V3(70 + OX, 8, -3) else nil
				if c then
					local from = v.Position + v.CFrame.UpVector * 0.1
					if workspace:Raycast(from, c - from, rpW) then
						v:Destroy()
						outside += 1
					end
				end
			end
		end
		table.insert(report, "veins outside annex shells removed " .. outside)
	end
	-- 2) nudge passes
	for pass = 1, 6 do
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
		local moves = {}
		local moved = {}
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
									if ia and not ib then pick = Bf.p elseif ib and not ia then pick = A.p elseif not ia and not ib then
										local va, vb = A.p.Size.X * A.p.Size.Y * A.p.Size.Z, Bf.p.Size.X * Bf.p.Size.Y * Bf.p.Size.Z
										pick = if va <= vb then A.p else Bf.p
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
		for _, mv in moves do mv[1].CFrame += mv[2] * 0.015 end
		table.insert(report, ("pass %d: nudged %d"):format(pass, #moves))
		if #moves == 0 then break end
	end
end)
probe:Destroy()
for p in savedQ do if p.Parent then p.CanQuery = false end end
if not ok then table.insert(report, "ERROR " .. tostring(err)) end
return table.concat(report, "\n")
