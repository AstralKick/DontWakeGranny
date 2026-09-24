-- Granny's House (Workspace.House) geometry audit. Read-only: every property it touches is restored. Run in Edit mode.
-- Adapted from map_nightmarehouse_audit (+ hiding-spot concealment from map_backgarden_audit).
-- Defines _G.HAudit(only) and runs it with _G.HAUDIT_ONLY. `only` = nil (everything) or a set like { doors = true }.
-- Categories:
--   doors     leaf/opening gap (raycasts in the leaf plane, <= 0.25 left/right/top); leaf intersections closed and swung
--             0/+-30/60/90 deg about the Hinge; a 2x5x1 player box through the doorway with the door open either way
--   leak      light leaks: 96 rays x 3 heights from every Room centre must stop before leaving the union of Room boxes
--   zfight    coplanar, same-facing, overlapping, exposed faces of different Block parts
--             (a leaf touching its own area's Barrier is reported as info only: it can only swing that way from the locked
--             side, because InteractionService swings doors away from the opener)
--   penetrate props (room-folder contents, stairs, Interactables, GrandmaChair) sinking > 0.03 into walls/casings/ceilings
--             or > 0.1 into floors (seating up to 0.1 is fine). Exempt by design: windows, pipes/ducts, parts fully buried
--             in structure, stringer/skirt ends in the floor slabs
--   floating  prop models / loose decor touching nothing; lamps must hang from / stand on something; corruption veins
--             must rest on a surface along their whole length
--   ramp      invisible collidable WedgeParts: continuous, monotonic, <= 35 deg, flush with the floor at both ends
--   hide      hiding spots: rays from the hidden body (5 heights x 12 headings + up/down) hit opaque geometry within 5
--   path      Grandma's agent (r 1.6, h 5.5, no jump) from the yard spawn to every node / hide Front / pumpkin / sleep
--             spot / trunk with Barriers off; locked areas unreachable at each unlock stage (slowest category)
-- Set _G.HAUDIT_DETAIL = "<category>" to list up to 80 issues of that category.
_G.HAudit = function(only)
	local CS = game:GetService("CollectionService")
	local H = workspace.House
	local V3 = Vector3.new
	local out, issues = {}, {}
	local function issue(cat, s)
		issues[cat] = issues[cat] or {}
		table.insert(issues[cat], s)
	end
	local function L(v) return ("%.1f,%.1f,%.1f"):format(v.X, v.Y, v.Z) end
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
				if p ~= probe and not isHelper(p) and not (exclude and p:IsDescendantOf(exclude)) and (not collideOnly or p.CanCollide) and not CS:HasTag(p, "Creaky") and not p:IsDescendantOf(H.Corruption) then
					table.insert(res, p)
				end
			end
			return res
		end
		local function nm(p) return (p:GetFullName():gsub("^Workspace%.House%.", "")) end

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
					rp.FilterDescendantsInstances = { m, probe, H.Corruption, H.Rooms, H.SearchNodes, H.LootSpawns }
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
						for _, p in hitsIn(R * pcf, shrink, m, false) do
							-- a door can only swing into its own area's barrier from the locked side (it swings away from the
							-- opener), so those contacts are listed for information only
							if p:IsDescendantOf(H.Barriers) then
								issue("info_doorIntoBarrier", ("%s @%d touches %s"):format(m.Name, deg, nm(p)))
							else
								issue("doorSweep", ("%s @%d hits %s"):format(m.Name, deg, nm(p)))
							end
						end
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
						for _, p in hits do
							if not p:IsDescendantOf(H.Barriers) then issue("doorPass", ("%s open %d blocked by %s"):format(m.Name, deg, nm(p))) end
						end
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
										local uc = (math.min(A.hu, du + bu) + math.max(-A.hu, du - bu)) / 2
										local vc = (math.min(A.hv, dv + bv) + math.max(-A.hv, dv - bv)) / 2
										local pt = A.c + A.u * uc + A.v * vc + A.n * 0.03
										probe.CFrame = CFrame.new(pt)
										probe.Size = V3(0.02, 0.02, 0.02)
										local op = OverlapParams.new()
										op.FilterType = Enum.RaycastFilterType.Include
										op.FilterDescendantsInstances = { H }
										local blocked = false
										for _, q in workspace:GetPartsInPart(probe, op) do
											if q ~= probe and not isHelper(q) then blocked = true break end
										end
										if not blocked then
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

		-------------------------------------------------------------- prop roots (room folders' contents)
		local AREAF = { "Ground", "Upstairs", "Basement", "Attic" }
		local propRoots = {}
		for _, a in AREAF do
			for _, c in H[a]:GetChildren() do
				if c:IsA("Folder") then
					for _, cc in c:GetChildren() do table.insert(propRoots, cc) end
				elseif c:IsA("Model") or (c:IsA("BasePart") and not ({ Wall = 1, Trim = 1, Rail = 1, Casing = 1, Window = 1, Arch = 1, ArchJamb = 1, KneeWall = 1, Filler = 1, Joist = 1, Tile = 1 })[c.Name] and not c.Name:find("Floor")) then
					table.insert(propRoots, c)
				end
			end
		end
		for _, c in H.Interactables:GetChildren() do table.insert(propRoots, c) end
		table.insert(propRoots, H.GrandmaChair)
		local function isStructure(p)
			local n = p.Name
			return p.CanCollide and (n == "Wall" or n == "Siding" or n == "EndWall" or n:find("Floor") or n:find("Ceiling") or n == "Roof" or n:find("Facade") or n == "Foundation" or n == "BasementWall" or n == "BasementSlab" or n == "KneeWall")
		end
		-- Exempt by design: windows (set into the walls), invisible ramps, pipes/ducts running through walls/ceilings,
		-- stair stringers/skirts whose ends are buried in the floor slabs.
		local function aabb(p)
			local cf, s = p.CFrame, p.Size
			local e = V3(
				math.abs(cf.RightVector.X) * s.X + math.abs(cf.UpVector.X) * s.Y + math.abs(cf.LookVector.X) * s.Z,
				math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z,
				math.abs(cf.RightVector.Z) * s.X + math.abs(cf.UpVector.Z) * s.Y + math.abs(cf.LookVector.Z) * s.Z
			) / 2
			return cf.Position - e, cf.Position + e
		end
		if want("penetrate") then
			local nPen = 0
			for _, root in propRoots do
				if root.Name ~= "Window" then
					local list = if root:IsA("BasePart") then { root } else root:GetDescendants()
					for _, p in list do
						if p:IsA("BasePart") and p.Transparency < 1 and not isStructure(p) and p.Name ~= "Threshold" and not p.Name:find("Pipe") and p.Name ~= "Duct" and not (CS:HasTag(root, "Door") and p.Name ~= "Panel") then
							local sz = p.Size - V3(0.04, 0.04, 0.04)
							if sz.X > 0.01 and sz.Y > 0.01 and sz.Z > 0.01 then
								local cands
								if p:IsA("Part") and p.Shape == Enum.PartType.Block then
									cands = hitsIn(p.CFrame, sz, nil, false)
								else
									-- wedges / cylinders / unions: query with the part's own geometry
									local opP = OverlapParams.new()
									opP.FilterType = Enum.RaycastFilterType.Include
									opP.FilterDescendantsInstances = { H.Ground, H.Upstairs, H.Basement, H.Attic, H.Structure, H.Exterior }
									cands = {}
									for _, q in workspace:GetPartsInPart(p, opP) do if not isHelper(q) then table.insert(cands, q) end end
								end
								for _, q in cands do
									local slabEnd = (p.Name == "Stringer" or p.Name == "StairSkirt") and (q.Name:find("Floor") or q.Name:find("Ceiling"))
									if (isStructure(q) or q.Name == "Casing") and not q:IsDescendantOf(root) and q ~= p and not slabEnd then
										local a0, a1 = aabb(p)
										local b0, b1 = aabb(q)
										local d
										local isFloor = (q.Name:find("Floor") or q.Name:find("Slab")) and not q.Name:find("Ceiling")
										if isFloor then
											-- sinking into a floor: real depth = floor top - the part's lowest corner; seating up to 0.1 is fine
											local cf, s = p.CFrame, p.Size / 2
											local low = math.huge
											for _, x in { -1, 1 } do for _, y in { -1, 1 } do for _, z in { -1, 1 } do low = math.min(low, (cf * V3(x * s.X, y * s.Y, z * s.Z)).Y) end end end
											d = b1.Y - low
											if d <= 0.105 or low < b0.Y then d = 0 end
										else
											d = math.min(math.min(a1.X, b1.X) - math.max(a0.X, b0.X), math.min(a1.Y, b1.Y) - math.max(a0.Y, b0.Y), math.min(a1.Z, b1.Z) - math.max(a0.Z, b0.Z))
										end
										local buried = a0.X >= b0.X - 0.001 and a0.Y >= b0.Y - 0.001 and a0.Z >= b0.Z - 0.001 and a1.X <= b1.X + 0.001 and a1.Y <= b1.Y + 0.001 and a1.Z <= b1.Z + 0.001
										if d > 0.03 and not buried then
											nPen += 1
											issue("penetrate", ("%s into %s by %.2f @%s"):format(nm(p), nm(q), d, L(p.Position)))
										end
									end
								end
							end
						end
					end
				end
			end
			table.insert(out, "prop penetrations " .. nPen)
		end

		-------------------------------------------------------------- floating props
		if want("floating") then
			local nFloat = 0
			local op = OverlapParams.new()
			op.FilterType = Enum.RaycastFilterType.Include
			op.FilterDescendantsInstances = { H }
			for _, c in propRoots do
				local cf, sz
				if c:IsA("Model") then cf, sz = c:GetBoundingBox() elseif c:IsA("BasePart") and not isHelper(c) then cf, sz = c.CFrame, c.Size end
				if cf then
					local touching = false
					for _, q in workspace:GetPartBoundsInBox(cf, sz + V3(0.3, 0.3, 0.3), op) do
						if q ~= probe and not q:IsDescendantOf(c) and q ~= c and not isHelper(q) and not q:IsDescendantOf(H.Corruption) then
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
			-- lamps: a hanging lamp's highest point must touch something (ceiling/beam/cord)
			for _, l in CS:GetTagged("Lamp") do
				if l:IsDescendantOf(H) and l:IsA("Model") then
					local cf, sz = l:GetBoundingBox()
					local topCf = cf * CFrame.new(0, sz.Y / 2, 0)
					local touching = false
					for _, q in workspace:GetPartBoundsInBox(topCf, V3(sz.X + 0.2, 0.3, sz.Z + 0.2), op) do
						if not q:IsDescendantOf(l) and not isHelper(q) and q ~= probe and not q:IsDescendantOf(H.Corruption) then touching = true break end
					end
					local below = false
					for _, q in workspace:GetPartBoundsInBox(cf * CFrame.new(0, -sz.Y / 2, 0), V3(sz.X + 0.2, 0.3, sz.Z + 0.2), op) do
						if not q:IsDescendantOf(l) and not isHelper(q) and q ~= probe and not q:IsDescendantOf(H.Corruption) then below = true break end
					end
					if not touching and not below then
						nFloat += 1
						issue("lampLoose", nm(l) .. " @" .. L(cf.Position))
					end
				end
			end
			-- corruption veins: 11 samples along each; loose = no surface within 0.35 across it and not buried in anything
			local EX = { H.Corruption, H.Rooms, H.SearchNodes, H.LootSpawns, H.PrizeSpawns, probe }
			local rpV = RaycastParams.new()
			rpV.FilterType = Enum.RaycastFilterType.Exclude
			rpV.FilterDescendantsInstances = EX
			local opV = OverlapParams.new()
			opV.FilterType = Enum.RaycastFilterType.Exclude
			opV.FilterDescendantsInstances = EX
			local nVein, nLoose = 0, 0
			for _, v in H.Corruption:GetDescendants() do
				if v:IsA("BasePart") and v.Name:find("^Vein") then
					nVein += 1
					local loose = 0
					for i = 0, 10 do
						local p = v.Position + v.CFrame.LookVector * (-0.5 + i / 10) * v.Size.Z * 0.96
						local hit = false
						for _, d in { v.CFrame.RightVector, -v.CFrame.RightVector, v.CFrame.UpVector, -v.CFrame.UpVector } do
							if workspace:Raycast(p, d * 0.35, rpV) then hit = true break end
						end
						if not hit and #workspace:GetPartBoundsInBox(CFrame.new(p), V3(0.02, 0.02, 0.02), opV) > 0 then hit = true end
						if not hit then loose += 1 end
					end
					if loose > 0 then
						nLoose += 1
						issue("veinLoose", ("%s %d/11 samples unsupported @%s"):format(nm(v), loose, L(v.Position)))
					end
				end
			end
			table.insert(out, ("floating props/lamps %d; loose veins %d / %d"):format(nFloat, nLoose, nVein))
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
						rpF.FilterDescendantsInstances = { p, probe, H.Rooms, H.SearchNodes, H.LootSpawns, H.Corruption }
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

		-------------------------------------------------------------- hiding spot concealment
		if want("hide") then
			local nBad, nSpots = 0, 0
			for _, m in CS:GetTagged("HidingSpot") do
				if m:IsDescendantOf(H) then
					nSpots += 1
					local icf = m:FindFirstChild("Inside", true).CFrame
					local esc, total, ex = 0, 0, nil
					for _, dy in { -1.8, -0.9, 0, 0.9, 1.8 } do
						local o = (icf * CFrame.new(0, dy, 0)).Position
						local dirs = {}
						for k = 0, 11 do
							local a = k * math.pi / 6
							table.insert(dirs, icf.RightVector * math.cos(a) + icf.LookVector * math.sin(a))
						end
						if math.abs(dy) > 1.7 then table.insert(dirs, icf.UpVector * (if dy > 0 then 1 else -1)) end
						for _, dir in dirs do
							total += 1
							local skip = { probe, H.Rooms, H.SearchNodes, H.LootSpawns, H.PrizeSpawns }
							local okRay = false
							for _ = 1, 6 do
								local rp2 = RaycastParams.new()
								rp2.FilterType = Enum.RaycastFilterType.Exclude
								rp2.FilterDescendantsInstances = skip
								local r = workspace:Raycast(o, dir * 5, rp2)
								if not r then break end
								if r.Instance.Transparency <= 0.5 then okRay = true break end
								table.insert(skip, r.Instance)
							end
							if not okRay then
								esc += 1
								ex = ex or ("dy %.1f dir (%.1f,%.1f,%.1f)"):format(dy, dir.X, dir.Y, dir.Z)
							end
						end
					end
					if esc > 0 then
						nBad += 1
						issue("hide", ("%s (%s): %d/%d rays escape e.g. %s"):format(nm(m), tostring(m:GetAttribute("Kind")), esc, total, ex))
					end
				end
			end
			table.insert(out, ("hiding spots %d, not concealed %d"):format(nSpots, nBad))
		end

		-------------------------------------------------------------- pathfinding (Grandma's agent)
		-- From the yard spawn with every Barrier off: every SearchNode, HidingSpot Front, PumpkinSpot, the GrandmaSleepSpot
		-- and the Trunk. Then the unlock order (Ground n1, Upstairs n3, Basement n4, Attic n5): every target in a still-locked
		-- area must be unreachable. Barrier collision is restored afterwards.
		if want("path") then
			local PFS = game:GetService("PathfindingService")
			local function mk() return PFS:CreatePath({ AgentRadius = 1.6, AgentHeight = 5.5, AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 4 }) end
			local savedC = {}
			for _, d in H.Barriers:GetDescendants() do if d:IsA("BasePart") then savedC[d] = d.CanCollide end end
			local function barriers(openAreas)
				for d, v in savedC do
					local m = d:FindFirstAncestorOfClass("Model")
					local area = (m and m:GetAttribute("Area")) or d:GetAttribute("Area")
					d.CanCollide = v and not openAreas[area]
				end
			end
			local function reach(from, to, tolH, tolV)
				local p = mk()
				local okP = pcall(function() p:ComputeAsync(from, to) end)
				if not okP or p.Status ~= Enum.PathStatus.Success then return false, "status " .. tostring(p.Status) end
				local wps = p:GetWaypoints()
				local last = wps[#wps].Position
				local d = (V3(last.X, 0, last.Z) - V3(to.X, 0, to.Z)).Magnitude
				if d > (tolH or 4) or math.abs(last.Y - to.Y) > (tolV or 4) then return false, ("ends %.1f away"):format(d) end
				return true
			end
			local yard = H.PlayerSpawns:GetChildren()[1].Position + V3(0, 3, 0)
			local targets = {}
			for _, n in H.SearchNodes:GetChildren() do table.insert(targets, { "Node " .. n.Name, n.Position + V3(0, 2.5, 0), n:GetAttribute("Area") }) end
			for _, m in CS:GetTagged("HidingSpot") do
				if m:IsDescendantOf(H) then table.insert(targets, { "Hide " .. m.Name, m:FindFirstChild("Front", true).Position + V3(0, 2.5, 0), m:GetAttribute("Area") }) end
			end
			for _, p in H.PumpkinSpots:GetChildren() do table.insert(targets, { "Pumpkin " .. p:GetAttribute("Area"), p.Position + V3(0, 2.5, 0), p:GetAttribute("Area") }) end
			table.insert(targets, { "SleepSpot", H.GrandmaSleepSpot.Position, "Ground", 4, 5 })
			table.insert(targets, { "Trunk", H.MomsCar.Trunk.Position + H.MomsCar.Trunk.CFrame.LookVector * -3, "Ground" })
			local okAll, errP = pcall(function()
				barriers({ Upstairs = true, Basement = true, Attic = true })
				local good = 0
				for _, t in targets do
					local s, why = reach(yard, t[2], t[4], t[5])
					if s then good += 1 else issue("path", ("%s @%s: %s"):format(t[1], L(t[2]), why)) end
				end
				table.insert(out, ("path: barriers off %d / %d reachable from the yard spawn"):format(good, #targets))
				for _, st in { { "nights 1-2", {} }, { "night 3", { Upstairs = true } }, { "night 4", { Upstairs = true, Basement = true } } } do
					barriers(st[2])
					local tested, leaks = 0, 0
					for _, t in targets do
						if t[3] and t[3] ~= "Ground" and not st[2][t[3]] then
							tested += 1
							if reach(yard, t[2]) then
								leaks += 1
								issue("pathLocked", st[1] .. ": " .. t[1] .. " reachable")
							end
						end
					end
					table.insert(out, ("path %s: %d locked targets, %d reachable"):format(st[1], tested, leaks))
				end
			end)
			for d, v in savedC do d.CanCollide = v end
			if not okAll then table.insert(out, "PATH ERROR " .. tostring(errP)) end
		end
		probe:Destroy()
	end)
	for p in savedQ do if p.Parent then p.CanQuery = false end end
	if not ok then table.insert(out, "AUDIT ERROR: " .. tostring(err)) end
	_G.HAUDIT_LAST = issues
	local detail = _G.HAUDIT_DETAIL
	for cat, list in issues do
		table.insert(out, ("[%s] %d"):format(cat, #list))
		local lim = if detail == cat then 80 else 6
		for i = 1, math.min(#list, lim) do table.insert(out, "   " .. list[i]) end
	end
	local n = 0
	for _, d in H:GetDescendants() do if d:IsA("BasePart") then n += 1 end end
	table.insert(out, "parts " .. n)
	return table.concat(out, "\n")
end
return _G.HAudit(_G.HAUDIT_ONLY)
