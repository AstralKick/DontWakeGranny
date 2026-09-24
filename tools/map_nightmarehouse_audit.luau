-- NightmareHouse geometry audit (read-only; restores every property it touches). Run in Edit mode.
-- Defines _G.NHAudit(only) and runs it. `only` = nil (everything) or a set like { doors = true, leak = true }.
-- Categories:
--   doors     gap between leaf and opening (raycasts in the leaf plane, <= 0.25 left/right/top); leaf intersections closed
--             and swung +-30/60/90 deg around the Hinge; 2x5x1 player box through the doorway with the door open either way
--   leak      light leaks: rays (32 headings x 3 elevations x 3 heights) from every Room centre must stop before leaving
--             the union of Room boxes (pad 1.2)
--   zfight    coplanar, same-facing, overlapping faces of different Block parts whose shared face is exposed
--   penetrate new props (and the throne) sinking into walls/floors/ceilings/casings
--   floating  prop models / loose decor touching nothing (deliberate floaters: Corruption, Mobile, fog, veins);
--             every vein must sit on a surface
--   ramp      invisible ramps: continuous, monotonic, <= 35 deg, and flush with the floor at both ends
-- Set _G.NHAUDIT_DETAIL = "<category>" to list up to 80 issues of that category.
_G.NHAudit = function(only)
	local CS = game:GetService("CollectionService")
	local H = workspace.Maps.NightmareHouse
	local OX = 7500
	local V3 = Vector3.new
	local out, issues = {}, {}
	local function issue(cat, s)
		issues[cat] = issues[cat] or {}
		table.insert(issues[cat], s)
	end
	local function L(v) return ("%.1f,%.1f,%.1f"):format(v.X - OX, v.Y, v.Z) end
	local savedQ = {}
	local all = {}
	for _, d in H:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(all, d)
			local helper = d.Transparency >= 1 and not d.CanCollide
			if not helper and not d.CanQuery then
				savedQ[d] = true
				d.CanQuery = true
			end
		end
	end
	local function isHelper(p) return p.Transparency >= 1 and not p.CanCollide end
	local function want(k) return not only or only[k] end
	local ok, err = pcall(function()
		local probe = Instance.new("Part")
		probe.Anchored = true
		probe.CanCollide = false
		probe.CanQuery = false
		probe.CanTouch = false
		probe.Transparency = 1
		probe.Parent = H
		local function hitsIn(cf, size, exclude, collideOnly)
			probe.CFrame = cf
			probe.Size = size
			local op = OverlapParams.new()
			op.FilterType = Enum.RaycastFilterType.Include
			op.FilterDescendantsInstances = { H }
			local res = {}
			for _, p in workspace:GetPartsInPart(probe, op) do
				if p ~= probe and not isHelper(p) and not (exclude and p:IsDescendantOf(exclude)) and (not collideOnly or p.CanCollide) and not CS:HasTag(p, "Creaky") then
					table.insert(res, p)
				end
			end
			return res
		end
		local function nm(p) return (p:GetFullName():gsub("Workspace.Maps.NightmareHouse.", "")) end

		-------------------------------------------------------------- doors
		if want("doors") then
			local nDoor = 0
			for _, m in CS:GetTagged("Door") do
				if m:IsDescendantOf(H) then
					nDoor += 1
					local panel, hinge = m:FindFirstChild("Panel"), m:FindFirstChild("Hinge")
					local pcf, ps = panel.CFrame, panel.Size
					local rp = RaycastParams.new()
					rp.FilterType = Enum.RaycastFilterType.Exclude
					rp.FilterDescendantsInstances = { m, probe }
					local maxGap = { L = 0, R = 0, T = 0 }
					for _, side in { { "L", -1 }, { "R", 1 } } do
						for _, fy in { -0.35, 0, 0.35 } do
							local o = pcf * V3(side[2] * (ps.X / 2 - 0.05), fy * ps.Y, 0)
							local h = workspace:Raycast(o, pcf.RightVector * side[2] * 3, rp)
							maxGap[side[1]] = math.max(maxGap[side[1]], if h then h.Distance - 0.05 else 3)
						end
					end
					for _, fx in { -0.3, 0, 0.3 } do
						local o = pcf * V3(fx * ps.X, ps.Y / 2 - 0.05, 0)
						local h = workspace:Raycast(o, pcf.UpVector * 3, rp)
						maxGap.T = math.max(maxGap.T, if h then h.Distance - 0.05 else 3)
					end
					for k, g in maxGap do
						if g > 0.26 then issue("doorGap", ("%s %s gap %.2f"):format(m.Name, k, g)) end
					end
					local shrink = ps - V3(0.1, 0.1, 0.1)
					for _, deg in { 0, 30, 60, 90, -30, -60, -90 } do
						local R = hinge.CFrame * CFrame.Angles(0, math.rad(deg), 0) * hinge.CFrame:Inverse()
						for _, p in hitsIn(R * pcf, shrink, m, false) do issue("doorSweep", ("%s @%d hits %s"):format(m.Name, deg, nm(p))) end
					end
					for _, deg in { 90, -90 } do
						local R = hinge.CFrame * CFrame.Angles(0, math.rad(deg), 0) * hinge.CFrame:Inverse()
						local saved = {}
						for _, p in m:GetDescendants() do
							if p:IsA("BasePart") then
								saved[p] = p.CFrame
								p.CFrame = R * p.CFrame
							end
						end
						local floorY = pcf.Position.Y - ps.Y / 2
						local box = CFrame.fromMatrix(V3(pcf.Position.X, floorY + 2.65, pcf.Position.Z), pcf.RightVector, Vector3.yAxis)
						local hits = hitsIn(box, V3(2, 5, 1), nil, true)
						for p, cf in saved do p.CFrame = cf end
						for _, p in hits do issue("doorPass", ("%s open %d blocked by %s"):format(m.Name, deg, nm(p))) end
					end
				end
			end
			table.insert(out, "doors checked " .. nDoor)
		end

		-------------------------------------------------------------- leaks
		local rooms = H.Rooms:GetChildren()
		local function inAnyRoom(p, pad)
			for _, r in rooms do
				local rel = r.CFrame:PointToObjectSpace(p)
				local h = r.Size / 2 + V3(pad, pad, pad)
				if math.abs(rel.X) <= h.X and math.abs(rel.Y) <= h.Y and math.abs(rel.Z) <= h.Z then return r end
			end
			return nil
		end
		if want("leak") then
			local rpVis = RaycastParams.new()
			rpVis.FilterType = Enum.RaycastFilterType.Include
			rpVis.FilterDescendantsInstances = { H }
			local nRays, leaks = 0, 0
			for _, r in rooms do
				local c = r.Position
				for _, fy in { 0.25, 0.55, 0.85 } do
					local o = V3(c.X, r.Position.Y - r.Size.Y / 2 + fy * r.Size.Y, c.Z)
					for k = 0, 95 do
						local a = (k % 32) / 32 * math.pi * 2
						local e = math.rad(({ 0, 35, -35 })[k // 32 + 1])
						local dir = V3(math.cos(a) * math.cos(e), math.sin(e), math.sin(a) * math.cos(e))
						local h = workspace:Raycast(o, dir * 200, rpVis)
						nRays += 1
						local guard = 0
						while h and (h.Instance.Transparency > 0.3 and h.Instance.Material ~= Enum.Material.Glass) and guard < 6 do
							guard += 1
							h = workspace:Raycast(h.Position + dir * 0.02, dir * 200, rpVis)
						end
						local stop = if h then h.Position else o + dir * 200
						local d = (stop - o).Magnitude
						local t = 0
						while t < d do
							local p = o + dir * t
							if not inAnyRoom(p, 1.2) then
								leaks += 1
								issue("leak", ("%s: ray %d@%.2f exits rooms at %s (stops %s on %s)"):format(r.Name, k, fy, L(p), L(stop), if h then nm(h.Instance) else "nothing"))
								break
							end
							t += 0.5
						end
					end
				end
			end
			table.insert(out, ("leak rays %d, leaks %d"):format(nRays, leaks))
		end

		-------------------------------------------------------------- z-fighting
		if want("zfight") then
			local buckets = {}
			local nFaces = 0
			for _, p in all do
				if p.Transparency < 0.95 and p:IsA("Part") and p.Shape == Enum.PartType.Block and p.Parent then
					local cf, s = p.CFrame, p.Size
					for _, f in { { cf.RightVector, s.X, s.Y, s.Z, cf.UpVector, cf.LookVector }, { cf.UpVector, s.Y, s.X, s.Z, cf.RightVector, cf.LookVector }, { cf.LookVector, s.Z, s.X, s.Y, cf.RightVector, cf.UpVector } } do
						for _, sg in { 1, -1 } do
							local n = f[1] * sg
							local center = cf.Position + n * f[2] / 2
							local key = ("%d,%d,%d|%d"):format(math.round(n.X * 200), math.round(n.Y * 200), math.round(n.Z * 200), math.round(center:Dot(n) * 50))
							buckets[key] = buckets[key] or {}
							table.insert(buckets[key], { p = p, c = center, u = f[5], v = f[6], hu = f[3] / 2, hv = f[4] / 2, n = n })
							nFaces += 1
						end
					end
				end
			end
			local zf, hidden = 0, 0
			local seen = {}
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
									local k2 = if A.p:GetDebugId() < Bf.p:GetDebugId() then A.p:GetDebugId() .. Bf.p:GetDebugId() else Bf.p:GetDebugId() .. A.p:GetDebugId()
									if not seen[k2] then
										seen[k2] = true
										-- only a real problem if the shared face is exposed: just in front of the overlap must be open air
										local uc = (math.min(A.hu, du + bu) + math.max(-A.hu, du - bu)) / 2
										local vc = (math.min(A.hv, dv + bv) + math.max(-A.hv, dv - bv)) / 2
										local pt = A.c + A.u * uc + A.v * vc + A.n * 0.03
										if #hitsIn(CFrame.new(pt), V3(0.02, 0.02, 0.02), nil, false) == 0 then
											zf += 1
											local same = A.p.Color == Bf.p.Color and A.p.Material == Bf.p.Material
											issue(if same then "zfightSame" else "zfight", ("%s <> %s (%.2fx%.2f) @%s"):format(nm(A.p), nm(Bf.p), ou, ov, L(A.c)))
										else
											hidden += 1
										end
									end
								end
							end
						end
					end
				end
			end
			table.insert(out, ("faces %d, exposed z-fight pairs %d (hidden coplanar contacts %d)"):format(nFaces, zf, hidden))
		end

		-------------------------------------------------------------- props sinking into structure
		local NF = H:FindFirstChild("Nightmare")
		local function isStructure(p)
			local n = p.Name
			return p.CanCollide and (n == "Wall" or n == "Siding" or n == "EndWall" or n:find("Floor") or n:find("Ceiling") or n == "Roof" or n == "RoomFloor" or n:find("Facade") or n == "Foundation" or n == "BasementWall" or n == "KneeWall")
		end
		if want("penetrate") then
			local nPen = 0
			local checkRoots = { NF and NF:FindFirstChild("LongHall"), NF and NF:FindFirstChild("WrongStairs"), NF and NF:FindFirstChild("Nursery"), NF and NF:FindFirstChild("Dolls"), NF and NF:FindFirstChild("GiantClock"), NF and NF:FindFirstChild("Throne"), H.GrandmaChair }
			for _, root in checkRoots do
				if root then
					for _, p in root:GetDescendants() do
						if p:IsA("BasePart") and not isHelper(p) and not isStructure(p) and p.Name ~= "Stilt" and p.Name ~= "Root" and p.Name ~= "Portal" and p.Name ~= "Threshold" then
							local shrinkBy = math.min(0.3, math.min(p.Size.X, p.Size.Y, p.Size.Z) * 0.45)
							local sz = p.Size - V3(shrinkBy, shrinkBy, shrinkBy) * 2
							if sz.X > 0.02 and sz.Y > 0.02 and sz.Z > 0.02 then
								for _, q in hitsIn(p.CFrame, sz, nil, false) do
									if isStructure(q) and not q:IsDescendantOf(root) or (q.Name == "Casing" and not q:IsDescendantOf(root)) then
										nPen += 1
										issue("penetrate", ("%s into %s"):format(nm(p), nm(q)))
									end
								end
							end
						end
					end
				end
			end
			table.insert(out, "prop penetrations " .. nPen)
		end

		-------------------------------------------------------------- floating props / unseated veins
		if want("floating") then
			local nFloat = 0
			local DELIBERATE = { Corruption = true, Mobile = true, YardFog = true, Veins = true }
			local function deliberate(inst)
				local x = inst
				while x and x ~= H do
					if DELIBERATE[x.Name] then return true end
					x = x.Parent
				end
				return false
			end
			local candidates = {}
			for _, folderName in { "Ground", "Upstairs", "Basement", "Attic", "Interactables" } do
				for _, c in H[folderName]:GetChildren() do table.insert(candidates, c) end
			end
			if NF then
				for _, f in NF:GetChildren() do
					for _, c in f:GetChildren() do table.insert(candidates, c) end
				end
			end
			local op = OverlapParams.new()
			op.FilterType = Enum.RaycastFilterType.Include
			op.FilterDescendantsInstances = { H }
			for _, c in candidates do
				if not deliberate(c) then
					local cf, sz
					if c:IsA("Model") then cf, sz = c:GetBoundingBox() elseif c:IsA("BasePart") and not isHelper(c) then cf, sz = c.CFrame, c.Size end
					if cf then
						local touching = false
						for _, q in workspace:GetPartBoundsInBox(cf, sz + V3(0.3, 0.3, 0.3), op) do
							if q ~= probe and not q:IsDescendantOf(c) and q ~= c and not isHelper(q) then
								touching = true
								break
							end
						end
						if not touching then
							nFloat += 1
							issue("floating", nm(c) .. " @" .. L(cf.Position))
						end
					end
				end
			end
			-- veins: the flat back must rest on something within 0.35
			local veins = {}
			for _, f in { NF and NF:FindFirstChild("Veins"), H.Corruption:FindFirstChild("1") } do
				if f then
					for _, v in f:GetDescendants() do
						if v:IsA("BasePart") and v.Name == "Vein" then table.insert(veins, v) end
					end
				end
			end
			local rpV = RaycastParams.new()
			rpV.FilterType = Enum.RaycastFilterType.Exclude
			rpV.FilterDescendantsInstances = veins
			local loose = 0
			for _, v in veins do
				local h = workspace:Raycast(v.Position, -v.CFrame.UpVector * 0.35, rpV)
				if not h then
					loose += 1
					issue("veinLoose", nm(v) .. " @" .. L(v.Position))
				end
			end
			table.insert(out, ("floating props %d, loose veins %d / %d"):format(nFloat, loose, #veins))
		end

		-------------------------------------------------------------- ramps
		if want("ramp") then
			local nRamp = 0
			for _, p in all do
				if p:IsA("WedgePart") and p.CanCollide and p.Transparency >= 1 and p.Parent then
					nRamp += 1
					local rpR = RaycastParams.new()
					rpR.FilterType = Enum.RaycastFilterType.Include
					rpR.FilterDescendantsInstances = { p }
					local lo, hi, prev = nil, nil, nil
					local steps = 12
					for i = 0, steps do
						local t = -0.5 + i / steps
						local o = p.CFrame * V3(0, p.Size.Y / 2 + 1, t * p.Size.Z * 0.98)
						local h = workspace:Raycast(o, V3(0, -(p.Size.Y + 3), 0), rpR)
						if not h then
							issue("ramp", nm(p) .. " no surface at t=" .. t)
							break
						end
						if prev and h.Position.Y < prev - 0.05 then issue("ramp", nm(p) .. " not monotonic") end
						prev = h.Position.Y
						if i == 0 then lo = h.Position end
						if i == steps then hi = h.Position end
					end
					if lo and hi then
						local slope = math.deg(math.atan2(hi.Y - lo.Y, (V3(hi.X, 0, hi.Z) - V3(lo.X, 0, lo.Z)).Magnitude))
						if slope > 35 then issue("ramp", ("%s slope %.1f"):format(nm(p), slope)) end
						local rpF = RaycastParams.new()
						rpF.FilterType = Enum.RaycastFilterType.Exclude
						rpF.FilterDescendantsInstances = { p, probe, NF and NF:FindFirstChild("YardFog") }
						local dirH = (V3(hi.X, 0, hi.Z) - V3(lo.X, 0, lo.Z)).Unit
						local hTop = workspace:Raycast(hi + dirH * 0.6 + V3(0, 2, 0), V3(0, -4, 0), rpF)
						local hBot = workspace:Raycast(lo - dirH * 0.6 + V3(0, 2, 0), V3(0, -4, 0), rpF)
						if not hTop or math.abs(hTop.Position.Y - hi.Y) > 0.35 then issue("ramp", ("%s top end step %.2f"):format(nm(p), if hTop then hTop.Position.Y - hi.Y else 99)) end
						if not hBot or math.abs(hBot.Position.Y - lo.Y) > 0.35 then issue("ramp", ("%s bottom end step %.2f"):format(nm(p), if hBot then hBot.Position.Y - lo.Y else 99)) end
						table.insert(out, ("ramp %s: %.1f deg, %.2f -> %.2f"):format(nm(p), slope, lo.Y, hi.Y))
					end
				end
			end
			table.insert(out, "ramps " .. nRamp)
		end
		probe:Destroy()
	end)
	for p in savedQ do p.CanQuery = false end
	if not ok then table.insert(out, "AUDIT ERROR: " .. tostring(err)) end
	_G.NHAUDIT_LAST = issues
	local detail = _G.NHAUDIT_DETAIL
	for cat, list in issues do
		table.insert(out, ("[%s] %d"):format(cat, #list))
		local lim = if detail == cat then 80 else 6
		for i = 1, math.min(#list, lim) do table.insert(out, "   " .. list[i]) end
	end
	return table.concat(out, "\n")
end
return _G.NHAudit(_G.NHAUDIT_ONLY)
