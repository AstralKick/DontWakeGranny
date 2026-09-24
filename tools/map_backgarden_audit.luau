-- BackGarden geometry audit (edit mode). Defines _G.BGB.audit(opts) and runs it.
-- opts.fixZ = true: nudge the smaller decor part of each z-fighting pair 0.02 outward.
-- Checks:
--  1. Doors: closed-panel gaps to the frame (left/right/top raycasts in the panel plane, max 0.25),
--     sweep at 0/+-30/+-60/+-90 deg (panel must not intersect frame/walls/props), a 2x5x1 player box
--     must pass through the doorway with the door open at +90 and -90.
--  2. Light leaks: dense rays from inside every enclosed room must hit geometry before leaving the room.
--     Z-fighting: coplanar, same-facing, overlapping faces of different colour/material.
--     Floating props: every prop must rest within 0.1 of a surface or touch something beside it.
--     Props intersecting walls / each other (penetration > 0.1).
--     Ramps: both edges flush (<= 0.1) with the floor they join.
--  3. Hiding spots: rays from the hidden body must hit opaque geometry within 5 studs (concealed).
local B = _G.BGB
-- Z-fighting: coplanar, same-facing, overlapping box faces of different colour/material. Down-facing faces
-- and overlaps entirely below the ground surface (outside the cellar/ramp well) are never visible and are
-- skipped. opts.fixZ nudges the non-collidable (else smaller, non-structural) part of each pair 0.02 outward.
function B.auditZ(opts)
	opts = opts or {}
	local H = workspace.Maps.BackGarden
	local O = Vector3.new(1500, 0, 0)
	local restoreQ = {}
	for _, d in H:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 and not d.CanQuery then restoreQ[d] = true d.CanQuery = true end
	end
	local op = OverlapParams.new()
	local function visibleUnderground(p)
		local x, z = p.X - O.X, p.Z
		return (x > -77 and x < -43 and z > 6.5 and z < 35) or (x > -67 and x < -58 and z > -8.5 and z < 13)
	end
	local structuralNames = { Hedge = true, Wall = true, GardenWall = true, Glass = true, KneeWall = true, TopPlate = true, Partition = true, Floor = true, Deck = true, Foundation = true, HouseBody = true, Grass = true, CellarWall = true, WellWall = true, Paving = true, Roof = true, Panel = true }
	local function faces(p)
		local cf, s = p.CFrame, p.Size / 2
		local list = {}
		for _, ax in { { cf.RightVector, s.X, cf.UpVector, s.Y, cf.LookVector, s.Z }, { cf.UpVector, s.Y, cf.RightVector, s.X, cf.LookVector, s.Z }, { cf.LookVector, s.Z, cf.RightVector, s.X, cf.UpVector, s.Y } } do
			for _, sg in { 1, -1 } do
				table.insert(list, { n = ax[1] * sg, c = cf.Position + ax[1] * sg * ax[2], u = ax[3], hu = ax[4], v = ax[5], hv = ax[6] })
			end
		end
		return list
	end
	local function isBox(p) return p:IsA("Part") and p.Shape == Enum.PartType.Block end
	local pairsL, groups = {}, {}
	local seen = {}
	for _, a in H:GetDescendants() do
		if a:IsA("BasePart") and isBox(a) and a.Transparency < 1 then
			for _, b in workspace:GetPartBoundsInBox(a.CFrame, a.Size + Vector3.new(0.05, 0.05, 0.05), op) do
				if b ~= a and isBox(b) and b.Transparency < 1 and b:IsDescendantOf(H) and not seen[b] and (a.Color ~= b.Color or a.Material ~= b.Material) then
					for _, fa in faces(a) do
						if fa.n.Y < -0.9 then continue end
						for _, fb in faces(b) do
							if fa.n:Dot(fb.n) > 0.999 and math.abs((fb.c - fa.c):Dot(fa.n)) < 0.004 and (math.abs(fb.u:Dot(fa.u)) > 0.999 or math.abs(fb.v:Dot(fa.u)) > 0.999) then
								local same = math.abs(fb.u:Dot(fa.u)) > 0.999
								local bu = if same then fb.hu else fb.hv
								local bv = if same then fb.hv else fb.hu
								local d = fb.c - fa.c
								local du, dv = d:Dot(fa.u), d:Dot(fa.v)
								local lu0, lu1 = math.max(-fa.hu, du - bu), math.min(fa.hu, du + bu)
								local lv0, lv1 = math.max(-fa.hv, dv - bv), math.min(fa.hv, dv + bv)
								if lu1 - lu0 > 0.05 and lv1 - lv0 > 0.05 then
									local cen = fa.c + fa.u * ((lu0 + lu1) / 2) + fa.v * ((lv0 + lv1) / 2)
									local topY = cen.Y + math.abs(fa.u.Y) * (lu1 - lu0) / 2 + math.abs(fa.v.Y) * (lv1 - lv0) / 2
									if topY <= 0.005 and not visibleUnderground(cen) then continue end
									local cand
									if not a.CanCollide and b.CanCollide then cand = a
									elseif not b.CanCollide and a.CanCollide then cand = b
									else cand = if fa.hu * fa.hv <= bu * bv then a else b end
									if structuralNames[cand.Name] then
										local other = if cand == a then b else a
										cand = if structuralNames[other.Name] then nil else other
									end
									local nrm = if cand == a then fa.n elseif cand == b then fb.n else nil
									local key = a.Name .. "|" .. b.Name
									groups[key] = (groups[key] or 0) + 1
									table.insert(pairsL, { a = a, b = b, cen = cen, area = (lu1 - lu0) * (lv1 - lv0), cand = cand, n = nrm })
								end
							end
						end
					end
				end
			end
			seen[a] = true
		end
	end
	local out, fixed, left = {}, 0, 0
	for _, p in pairsL do
		if opts.fixZ and p.cand and not p.cand:GetAttribute("ZFixed") then
			p.cand.CFrame = p.cand.CFrame + p.n * 0.02
			p.cand:SetAttribute("ZFixed", true)
			fixed += 1
		elseif not (p.cand and p.cand:GetAttribute("ZFixed")) then
			left += 1
			if #out < 40 then table.insert(out, ("  %s | %s @(%.1f,%.1f,%.1f) area %.2f"):format(p.a:GetFullName():gsub("Workspace.Maps.BackGarden.", ""), p.b:GetFullName():gsub("Workspace.Maps.BackGarden.", ""), p.cen.X - O.X, p.cen.Y, p.cen.Z, p.area)) end
		end
	end
	for d in restoreQ do d.CanQuery = false end
	local gl = {}
	for k, v in groups do table.insert(gl, k .. " x" .. v) end
	table.sort(gl)
	return ("Z-FIGHTING: %d coplanar pairs, %d nudged now, %d remaining (not auto-fixable)\n%s\n  groups: %s"):format(#pairsL, fixed, left, table.concat(out, "\n"), table.concat(gl, ", "))
end
function B.audit(opts)
	opts = opts or {}
	local CS = game:GetService("CollectionService")
	local H = workspace.Maps.BackGarden
	local O = Vector3.new(1500, 0, 0)
	local function L(v) return v - O end
	local function fmt(v) return ("(%.1f, %.1f, %.1f)"):format(v.X - O.X, v.Y, v.Z) end
	local out = {}
	local function say(s) table.insert(out, s) end
	-- make every visible part queryable for the duration of the audit
	local restoreQ = {}
	for _, d in H:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Transparency < 1 and not d.CanQuery then restoreQ[d] = false d.CanQuery = true end
		end
	end
	local barriers = H.Barriers
	local function isHelper(p) return p.Transparency >= 1 end
	local function rayParams(excl)
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = excl
		return rp
	end
	local function visibleHit(origin, dir, excl)
		local rp = rayParams(excl)
		local ignore = {}
		for _ = 1, 6 do
			local r = workspace:Raycast(origin, dir, rp)
			if not r then return nil end
			if r.Instance:IsDescendantOf(H) and not isHelper(r.Instance) then return r end
			table.insert(ignore, r.Instance)
			local e = table.clone(excl)
			for _, i in ignore do table.insert(e, i) end
			rp = rayParams(e)
		end
		return nil
	end
	local function overlapParams(excl)
		local op = OverlapParams.new()
		op.FilterType = Enum.RaycastFilterType.Exclude
		op.FilterDescendantsInstances = excl
		return op
	end
	local function probe(cf, size)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Size = size
		p.CFrame = cf
		p.Transparency = 1
		p.Parent = workspace
		return p
	end
	local function hitsIn(part, excl, pred)
		local res = {}
		for _, q in workspace:GetPartsInPart(part, overlapParams(excl)) do
			if q:IsDescendantOf(H) and not isHelper(q) and (not pred or pred(q)) then table.insert(res, q) end
		end
		return res
	end

	----------------------------------------------------------------- 1. doors
	local doorLines, doorBad = {}, 0
	for _, m in CS:GetTagged("Door") do
		if m:IsDescendantOf(H) then
			local panel, hinge = m.Panel, m.Hinge
			local pc, ps = panel.CFrame, panel.Size
			local excl = { m, barriers }
			local gaps = {}
			local worst = 0
			local function edgeRay(localPos, localDir, label)
				local origin = (pc * CFrame.new(localPos - localDir * 0.02)).Position
				local dir = pc:VectorToWorldSpace(localDir) * 0.4
				local r = visibleHit(origin, dir, excl)
				local g = if r then math.max(0, (r.Position - origin).Magnitude - 0.02) else 99
				worst = math.max(worst, g)
				if g > 0.25 then table.insert(gaps, ("%s gap %.2f"):format(label, g)) end
			end
			for _, fy in { -0.4, 0, 0.4 } do
				edgeRay(Vector3.new(-ps.X / 2, fy * ps.Y, 0), Vector3.new(-1, 0, 0), "L")
				edgeRay(Vector3.new(ps.X / 2, fy * ps.Y, 0), Vector3.new(1, 0, 0), "R")
			end
			for _, fx in { -0.4, 0, 0.4 } do
				edgeRay(Vector3.new(fx * ps.X, ps.Y / 2, 0), Vector3.new(0, 1, 0), "Top")
			end
			-- swing sweep
			local pivot = m:GetPivot()
			local sweepHits = {}
			for _, deg in { 0, 30, 60, 90, -30, -60, -90 } do
				local rot = pivot * CFrame.Angles(0, math.rad(deg), 0) * pivot:Inverse()
				local pr = probe(rot * pc, ps - Vector3.new(0.04, 0.04, 0.04))
				for _, q in hitsIn(pr, excl) do sweepHits[q:GetFullName():gsub("Workspace.Maps.BackGarden.", "") .. "@" .. deg] = true end
				pr:Destroy()
			end
			-- player box through the open doorway (door really rotated, then restored)
			local passFail = {}
			local mid = (pc * CFrame.new(0, -ps.Y / 2 + 0.1 + 2.5, 0))
			for _, deg in { 90, -90 } do
				m:PivotTo(pivot * CFrame.Angles(0, math.rad(deg), 0))
				local blocked = false
				for dz = -1.5, 1.5, 0.5 do
					local cfp = mid * CFrame.new(0, 0, dz)
					local pr = probe(cfp, Vector3.new(2, 5, 1))
					local hs = hitsIn(pr, { barriers }, function(q) return q.CanCollide end)
					pr:Destroy()
					if #hs > 0 then blocked = true passFail[deg] = hs[1].Name end
				end
				m:PivotTo(pivot)
				local _ = blocked
			end
			local sweepList = {}
			for k in sweepHits do table.insert(sweepList, k) end
			local bad = #gaps > 0 or #sweepList > 0 or passFail[90] or passFail[-90]
			if bad then doorBad += 1 end
			table.insert(doorLines, ("  %s %s maxgap %.2f%s%s%s"):format(if bad then "FAIL" else "ok  ", m.Name, worst,
				if #gaps > 0 then " [" .. table.concat(gaps, ", ") .. "]" else "",
				if #sweepList > 0 then " sweep-hits: " .. table.concat(sweepList, "; ") else "",
				(passFail[90] and (" blocked+90 by " .. passFail[90]) or "") .. (passFail[-90] and (" blocked-90 by " .. passFail[-90]) or "")))
		end
	end
	table.sort(doorLines)
	say(("DOORS: %d with problems"):format(doorBad))
	for _, l in doorLines do say(l) end

	----------------------------------------------------------------- 2a. light leaks in enclosed rooms
	local enclosed = { ["Potting Shed"] = true, ["Tool Room"] = true, ["Root Cellar"] = true, ["Cellar Steps"] = true, ["Outhouse"] = true, ["The Glasshouse"] = true, ["Orchid House"] = true }
	local leakTotal = 0
	local leakLines = {}
	local N = 300
	for _, r in H.Rooms:GetChildren() do
		if enclosed[r.Name] and r.Name ~= "Cellar Steps" then -- the steps are open to the shed by design
			local leaks = 0
			local ex = {}
			local c, hs = r.Position, r.Size / 2
			for _, off in { Vector3.new(0, 0, 0), Vector3.new(hs.X * 0.5, -hs.Y * 0.3, hs.Z * 0.5), Vector3.new(-hs.X * 0.5, -hs.Y * 0.3, -hs.Z * 0.5) } do
				local o = c + off
				for i = 0, N - 1 do
					local y = 1 - (i + 0.5) / N * 2
					local rad = math.sqrt(1 - y * y)
					local th = i * 2.399963
					local dir = Vector3.new(math.cos(th) * rad, y, math.sin(th) * rad)
					local len = r.Size.Magnitude + 2
					local hit = visibleHit(o, dir * len, { barriers })
					if not hit then
						leaks += 1
						if #ex < 3 then table.insert(ex, "dir " .. ("(%.2f,%.2f,%.2f)"):format(dir.X, dir.Y, dir.Z)) end
					else
						-- a hit far outside the room box = the ray escaped through a gap
						-- ok if the hit is inside this room (+4 for the roof space) or inside another enclosed room
						local inside = false
						for _, r2 in H.Rooms:GetChildren() do
							if enclosed[r2.Name] then
								local rel = r2.CFrame:PointToObjectSpace(hit.Position)
								local m2 = if r2 == r then 4 else 0.6
								local h2 = r2.Size / 2
								if math.abs(rel.X) <= h2.X + m2 and math.abs(rel.Y) <= h2.Y + m2 and math.abs(rel.Z) <= h2.Z + m2 then inside = true break end
							end
						end
						if not inside then
							-- open doorways/windows are fine only if glass/door: count escapes
							leaks += 1
							if #ex < 3 then table.insert(ex, "exits to " .. hit.Instance.Name .. " " .. fmt(hit.Position)) end
						end
					end
				end
			end
			leakTotal += leaks
			table.insert(leakLines, ("  %s %s: %d escaped rays %s"):format(if leaks == 0 then "ok  " else "LEAK", r.Name, leaks, table.concat(ex, "; ")))
		end
	end
	say(("LIGHT LEAKS: %d escaped rays"):format(leakTotal))
	for _, l in leakLines do say(l) end

	----------------------------------------------------------------- 2b. z-fighting (see B.auditZ)
	say(B.auditZ(opts))

	----------------------------------------------------------------- 2c. floating props + props in walls
	local props = {}
	local zones = { H.Ground, H.Upstairs, H.Basement, H.Attic }
	for i = 1, 4 do table.insert(zones, H.Corruption[tostring(i)]) end
	-- structure (walls, floors, roofs, trims) is not a prop
	local structGroups = { Greenhouse = true, PottingShed = true, HedgeMaze = true, MazeEntrance = true }
	local structNames = { Floor = true, CellarFloor = true, LandingFloor = true, CellarCeiling = true, WellCeiling = true, Beam = true, Step = true, Ramp = true, Roof = true,
		Gable = true, CellarWall = true, WellWall = true, Wall = true, Ceiling = true, Flagstones = true, Joint = true, GravelPath = true, LaneGravel = true, Rut = true,
		Deck = true, DeckEdge = true, Skirt = true, Batten = true, Post = true, Rail = true, Baluster = true, PorchCeiling = true, PorchRoof = true, Fascia = true, StepCheek = true,
		Conduit = true, DoorMat = true, Hedge = true, HedgeTop = true, HedgeLump = true, LightPole = true, ArchPost = true, ArchTop = true, ArchRose = true, Bed = true }
	local function addProp(inst)
		if CS:HasTag(inst, "Door") or structGroups[inst.Name] then return end
		if inst:IsA("BasePart") and (structNames[inst.Name] or inst.Transparency >= 1) then return end
		table.insert(props, inst)
	end
	for zi, z in zones do
		for _, g in z:GetChildren() do
			if zi > 4 then addProp(g)
			elseif g:IsA("Model") and not structGroups[g.Name] then
				if CS:HasTag(g, "Door") or CS:HasTag(g, "Lamp") or CS:HasTag(g, "HidingSpot") or CS:HasTag(g, "Breakable") then addProp(g)
				else
					for _, c in g:GetChildren() do addProp(c) end
				end
			end
		end
	end
	local structural = { Wall = true, GardenWall = true, Hedge = true, Glass = true, KneeWall = true, Partition = true, CellarWall = true, WellWall = true, HouseBody = true, Skirt = true, Deck = true }
	local floating, inWall = {}, {}
	for _, pr in props do
		if pr:IsA("Model") and pr:GetAttribute("NoGround") then continue end
		local parts = {}
		if pr:IsA("BasePart") then parts = { pr } else for _, d in pr:GetDescendants() do if d:IsA("BasePart") and d.Transparency < 1 then table.insert(parts, d) end end end
		if #parts == 0 then continue end
		-- supported?
		local minY, best = math.huge, nil
		for _, p in parts do
			local by = p.Position.Y - (math.abs(p.CFrame.UpVector.Y) * p.Size.Y + math.abs(p.CFrame.RightVector.Y) * p.Size.X + math.abs(p.CFrame.LookVector.Y) * p.Size.Z) / 2
			if by < minY then minY, best = by, p end
		end
		local supported = false
		local lowGap = math.huge
		for _, off in { Vector3.new(0, 0, 0), Vector3.new(0.3, 0, 0.3), Vector3.new(-0.3, 0, -0.3) } do
			local o = Vector3.new(best.Position.X, minY + 0.3, best.Position.Z) + off
			local r = visibleHit(o, Vector3.new(0, -3, 0), { pr })
			if r then
				local gap = (o.Y - 0.3) - r.Position.Y
				lowGap = math.min(lowGap, gap)
				if gap <= 0.1 then supported = true end
			end
		end
		if not supported then
			-- lateral attachment: does any part touch geometry outside the prop?
			for _, p in parts do
				local q = probe(p.CFrame, p.Size + Vector3.new(0.12, 0.12, 0.12))
				q.Shape = if p:IsA("Part") then p.Shape else Enum.PartType.Block
				local hs = hitsIn(q, { pr })
				q:Destroy()
				if #hs > 0 then supported = true break end
			end
		end
		if not supported then table.insert(floating, ("%s bottom %s gap %s"):format(pr:GetFullName():gsub("Workspace.Maps.BackGarden.", ""), fmt(Vector3.new(best.Position.X, minY, best.Position.Z)), if lowGap == math.huge then "none" else ("%.2f"):format(lowGap))) end
		-- penetration into walls (prop models only)
		for _, p in (if pr:IsA("Model") then parts else {}) do
			if p.Size.Magnitude > 0.3 then
				local q = probe(p.CFrame, Vector3.new(math.max(p.Size.X - 0.2, 0.02), math.max(p.Size.Y - 0.2, 0.02), math.max(p.Size.Z - 0.2, 0.02)))
				q.Shape = if p:IsA("Part") then p.Shape else Enum.PartType.Block
				local hs = hitsIn(q, { pr }, function(x) return structural[x.Name] == true end)
				q:Destroy()
				if #hs > 0 then table.insert(inWall, ("%s.%s in %s"):format(pr:GetFullName():gsub("Workspace.Maps.BackGarden.", ""), p.Name, hs[1]:GetFullName():gsub("Workspace.Maps.BackGarden.", ""))) break end
			end
		end
	end
	say(("FLOATING PROPS: %d of %d props"):format(#floating, #props))
	for i = 1, math.min(#floating, 40) do say("  " .. floating[i]) end
	say(("PROPS IN WALLS: %d"):format(#inWall))
	for i = 1, math.min(#inWall, 30) do say("  " .. inWall[i]) end

	----------------------------------------------------------------- 2d. ramps
	local rampLines = {}
	for _, d in H:GetDescendants() do
		if d:IsA("WedgePart") and d.Name == "Ramp" then
			local cf, s = d.CFrame, d.Size
			local top = cf * Vector3.new(0, s.Y / 2, s.Z / 2)
			local bot = cf * Vector3.new(0, -s.Y / 2, -s.Z / 2)
			local fwd = cf.LookVector * -1 -- WedgePart rises toward +Z local
			local rt = visibleHit(top + fwd * 0.6 + Vector3.new(0, 1, 0), Vector3.new(0, -3, 0), { d })
			local rb = visibleHit(bot - fwd * 0.6 + Vector3.new(0, 1, 0), Vector3.new(0, -3, 0), { d })
			local lt = if rt then math.abs(rt.Position.Y - top.Y) else 99
			local lb = if rb then math.abs(rb.Position.Y - bot.Y) else 99
			table.insert(rampLines, ("  %s ramp %s: top lip %.2f, bottom lip %.2f (%.0f deg)"):format(if lt <= 0.1 and lb <= 0.1 then "ok  " else "FAIL", fmt(d.Position), lt, lb, math.deg(math.atan2(s.Y, s.Z))))
		end
	end
	say("RAMPS:")
	for _, l in rampLines do say(l) end

	----------------------------------------------------------------- 3. hiding spot concealment
	local hideLines, hideBad = {}, 0
	for _, m in CS:GetTagged("HidingSpot") do
		if m:IsDescendantOf(H) then
			local ins = m:FindFirstChild("Inside", true)
			local icf = ins.CFrame
			local esc, total = 0, 0
			local exEx = nil
			for _, dy in { -1.8, -0.9, 0, 0.9, 1.8 } do
				local o = (icf * CFrame.new(0, dy, 0)).Position
				local dirs = {}
				for k = 0, 11 do
					local a = k * math.pi / 6
					table.insert(dirs, (icf.RightVector * math.cos(a) + icf.LookVector * math.sin(a)))
				end
				if math.abs(dy) > 1.7 then table.insert(dirs, icf.UpVector * (if dy > 0 then 1 else -1)) end
				for _, dir in dirs do
					total += 1
					local r = workspace:Raycast(o, dir * 5, rayParams({}))
					local ok = false
					local rp2 = rayParams({})
					local skip = {}
					for _ = 1, 5 do
						r = workspace:Raycast(o, dir * 5, rp2)
						if not r then break end
						if r.Instance:IsDescendantOf(H) and r.Instance.Transparency <= 0.5 then ok = true break end
						table.insert(skip, r.Instance)
						rp2 = rayParams(skip)
					end
					if not ok then
						esc += 1
						exEx = exEx or ("dy %.1f dir (%.1f,%.1f,%.1f)"):format(dy, dir.X, dir.Y, dir.Z)
					end
				end
			end
			if esc > 0 then hideBad += 1 end
			table.insert(hideLines, ("  %s %s (%s): %d/%d rays escape%s"):format(if esc == 0 then "ok  " else "OPEN", m.Name, m:GetAttribute("Kind"), esc, total, if exEx then " e.g. " .. exEx else ""))
		end
	end
	table.sort(hideLines)
	say(("HIDING SPOTS: %d not fully concealed"):format(hideBad))
	for _, l in hideLines do say(l) end

	----------------------------------------------------------------- performance
	local parts, clutterShadow, decorQuery = 0, 0, 0
	for _, d in H:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
			local wasQ = restoreQ[d] == nil and d.CanQuery
			if not d.CanCollide and d.Transparency < 1 and d.CastShadow and d.Size.Magnitude < 3 then clutterShadow += 1 end
			if not d.CanCollide and wasQ and not CS:HasTag(d, "Searchable") and d.Transparency < 1 then decorQuery += 1 end
		end
	end
	for d in restoreQ do d.CanQuery = false end
	say(("PERF: parts %d (limit 6000); small clutter casting shadows %d; non-collide decor with CanQuery %d"):format(parts, clutterShadow, decorQuery))
	return table.concat(out, "\n")
end
return B.audit({ fixZ = false })
