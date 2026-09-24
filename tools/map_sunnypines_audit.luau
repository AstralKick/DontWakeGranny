-- Sunny Pines geometry audit. Read-only unless FIX = true. Set SECTION to one of:
--   "doors"     door leaf gaps (raycasts from the leaf edges), swing sweep 0/+-30/+-60/+-90, player capsule 2x5x1 through the opening
--   "doorpaths" Grandma agent path through every door in both directions (PassThrough leaf)
--   "leaks"     light leaks: horizontal rays from every room toward its walls (thin escapes = seams), floor/ceiling rays
--   "zfight"    coplanar same-facing overlapping faces of axis-aligned blocks with different colour/material
--   "clip"      visible props intersecting structure or other props (different models)
--   "float"     props / prop models not touching anything (0.1 tolerance)
--   "stairs"    walking-surface profile along each flight + the entrance ramp (lip / gap detection)
--   "flags"     decor CanTouch/CanQuery/CastShadow rules, part count
local function audit(SECTION, FIX)
local CS = game:GetService("CollectionService")
local PFS = game:GetService("PathfindingService")
local H = workspace.Maps.SunnyPines
local O = Vector3.new(3000, 0, 0)
local V = Vector3.new
local out = {}
local function say(s) table.insert(out, s) end
local function L(p) return p - O end
local function fmt(p) p = L(p) return ("(%.2f,%.2f,%.2f)"):format(p.X, p.Y, p.Z) end
local HELPER_FOLDERS = { Rooms = true, LootSpawns = true, PrizeSpawns = true, SearchNodes = true, PlayerSpawns = true }
local function topFolder(p)
	local x = p
	while x.Parent and x.Parent ~= H do x = x.Parent end
	return x
end
local function isHelper(p)
	if p.Transparency >= 1 then return true end
	return HELPER_FOLDERS[topFolder(p).Name] or false
end
local STRUCT = { Structure = true, Exterior = true }
local function isStructure(p)
	local t = topFolder(p)
	if STRUCT[t.Name] then return true end
	-- walls / stairs / shell folders inside the floor folders
	local x = p.Parent
	while x and x ~= H do
		if x.Name == "Walls" or x.Name == "Stairs" or x.Name == "Shell" then return true end
		x = x.Parent
	end
	return false
end
-- nearest "prop" container: first Model ancestor below a floor/room folder, else the part itself
local function propOf(p)
	local best = nil
	local x = p.Parent
	while x and x ~= H do
		if x:IsA("Model") then best = x end
		x = x.Parent
	end
	return best or p
end
local function allParts()
	local t = {}
	for _, d in H:GetDescendants() do
		if d:IsA("BasePart") then table.insert(t, d) end
	end
	return t
end
local function aligned(cf)
	local r = { cf.RightVector, cf.UpVector, cf.LookVector }
	for _, v in r do
		local a = math.max(math.abs(v.X), math.abs(v.Y), math.abs(v.Z))
		if a < 0.9999 then return false end
	end
	return true
end
local function isBlock(p)
	return p.ClassName == "Part" and p.Shape == Enum.PartType.Block
end
local function aabb(p)
	local cf, s = p.CFrame, p.Size / 2
	local R, U, K = cf.RightVector, cf.UpVector, cf.LookVector
	local h = V(math.abs(R.X) * s.X + math.abs(U.X) * s.Y + math.abs(K.X) * s.Z, math.abs(R.Y) * s.X + math.abs(U.Y) * s.Y + math.abs(K.Y) * s.Z, math.abs(R.Z) * s.X + math.abs(U.Z) * s.Y + math.abs(K.Z) * s.Z)
	return cf.Position - h, cf.Position + h
end
-- respectCollide = true: only collidable parts, invisible colliders included (physical test)
-- respectCollide = false: only visible parts (visual test)
local function overlapBox(cf, size, exclude, respectCollide)
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = exclude or {}
	op.RespectCanCollide = respectCollide or false
	local res = {}
	for _, q in workspace:GetPartBoundsInBox(cf, size, op) do
		if q:IsDescendantOf(H) and (respectCollide or not isHelper(q)) and not H.Rooms:IsAncestorOf(q) then table.insert(res, q) end
	end
	return res
end

-- Spatial queries (GetPartBoundsInBox / raycasts) skip CanQuery=false parts, which is most decor and every invisible
-- collider. Enable CanQuery on the whole map while the audit runs, restore it at the end.
local restoreQ = {}
if SECTION ~= "flags" then
	for _, p in allParts() do
		if not p.CanQuery then restoreQ[p] = true p.CanQuery = true end
	end
end

----------------------------------------------------------------- doors
if SECTION == "doors" then
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local nBad, nDoors = 0, 0
	for _, m in CS:GetTagged("Door") do
		if m:IsDescendantOf(H) then
			nDoors += 1
			local panel, hinge = m.Panel, m.Hinge
			local issues = {}
			rp.FilterDescendantsInstances = { m }
			local cf, s = panel.CFrame, panel.Size / 2
			-- gaps: from inside the leaf edge outward along the leaf plane
			local function probe(localPt, dir, label)
				local o = cf:PointToWorldSpace(localPt)
				local r = workspace:Raycast(o, dir * 1.5, rp)
				local d = r and (r.Position - o).Magnitude or 99
				if d > 0.25 + 0.02 then table.insert(issues, ("%s gap %.2f"):format(label, d)) end
				return d
			end
			local maxL, maxR, maxT = 0, 0, 0
			for _, fy in { -0.9, -0.5, 0, 0.5, 0.9 } do
				maxL = math.max(maxL, probe(V(-s.X + 0.01, fy * s.Y, 0), -cf.RightVector, "left"))
				maxR = math.max(maxR, probe(V(s.X - 0.01, fy * s.Y, 0), cf.RightVector, "right"))
			end
			for _, fx in { -0.8, 0, 0.8 } do
				maxT = math.max(maxT, probe(V(fx * s.X, s.Y - 0.01, 0), cf.UpVector, "top"))
			end
			-- sweep
			local pivot0 = m:GetPivot()
			for _, ang in { 0, 30, 60, 90, -30, -60, -90 } do
				m:PivotTo(pivot0 * CFrame.Angles(0, math.rad(ang), 0))
				local hits = overlapBox(panel.CFrame, panel.Size - V(0.04, 0.04, 0.04), { m }, false)
				for _, q in hits do
					if q.Name ~= "Rug" and q.Name ~= "RugField" then
						table.insert(issues, ("sweep %d hits %s"):format(ang, q:GetFullName():sub(22)))
					end
				end
			end
			-- player capsule through the opening with the leaf open +-90
			for _, ang in { 90, -90 } do
				m:PivotTo(pivot0 * CFrame.Angles(0, math.rad(ang), 0))
				-- pivot = Hinge part centre (floor + 4); the opening centre is panel.Size.X/2 - 0.15 along the pivot's X
				local c0 = pivot0 * CFrame.new(panel.Size.X / 2 - 0.15, -4, 0)
				local blocked = false
				for dn = -2.5, 2.5, 0.5 do
					local cc = c0 * CFrame.new(0.15, 2.6, dn)
					local hits = overlapBox(cc, V(2, 5, 1), { m }, true)
					for _, q in hits do
						if q.CanCollide then blocked = true table.insert(issues, ("capsule(%d) blocked by %s at %.1f"):format(ang, q:GetFullName():sub(22), dn)) break end
					end
					if blocked then break end
				end
			end
			m:PivotTo(pivot0)
			if #issues > 0 then
				nBad += 1
				say(m.Name .. " @" .. fmt(hinge.Position) .. ": " .. table.concat(issues, "; "))
			end
			m:SetAttribute("_gap", ("%.2f/%.2f/%.2f"):format(maxL, maxR, maxT))
		end
	end
	say(("doors checked %d, with issues %d"):format(nDoors, nBad))
	-- summary of the gap widths
	local worst = 0
	for _, m in CS:GetTagged("Door") do
		if m:IsDescendantOf(H) then
			for v in string.gmatch(m:GetAttribute("_gap") or "", "[%d%.]+") do worst = math.max(worst, tonumber(v)) end
			m:SetAttribute("_gap", nil)
		end
	end
	say(("worst leaf-to-frame gap %.2f"):format(worst))
end

----------------------------------------------------------------- door paths
if SECTION == "doorpaths" then
	local bad = 0
	local n = 0
	for _, m in CS:GetTagged("Door") do
		if m:IsDescendantOf(H) then
			local pv = m:GetPivot()
			local panel = m.Panel
			local c = pv * CFrame.new(panel.Size.X / 2 - 0.15, -1.5, 0)
			for _, lat in { -3, 0, 3 } do
				for _, dist in { 3.5 } do
					local a = (c * CFrame.new(lat, 0, -dist)).Position
					local b = (c * CFrame.new(-lat, 0, dist)).Position
					for _, pair in { { a, b }, { b, a } } do
						n += 1
						local p = PFS:CreatePath({ AgentRadius = 1.6, AgentHeight = 5.5, AgentCanJump = false, WaypointSpacing = 4 })
						p:ComputeAsync(pair[1], pair[2])
						if p.Status ~= Enum.PathStatus.Success then
							-- endpoints may be inside furniture; only count if both ends are on free floor
							local free = true
							for _, e in pair do
								for _, q in overlapBox(CFrame.new(e), V(3, 4, 3), { m }, true) do
									if q.CanCollide then free = false end
								end
							end
							if free then
								bad += 1
								say(("%s: no path %s -> %s"):format(m.Name, fmt(pair[1]), fmt(pair[2])))
							end
						end
					end
				end
			end
		end
	end
	say(("door path tests %d, failures %d"):format(n, bad))
end

----------------------------------------------------------------- light leaks
if SECTION == "leaks" then
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	local solids = {}
	for _, p in allParts() do
		if not isHelper(p) and p.Transparency < 0.95 then table.insert(solids, p) end
	end
	-- raycasts ignore CanQuery=false parts, so temporarily enable query on visible parts
	local restore = {}
	for _, p in solids do
		if not p.CanQuery then restore[p] = true p.CanQuery = true end
	end
	rp.FilterDescendantsInstances = solids
	local leaks = 0
	local rooms = H.Rooms:GetChildren()
	for _, r in rooms do
		local mn, mx = aabb(r)
		local y0, y1 = mn.Y, mx.Y
		local heights = { y0 + 0.05, y0 + 0.4, (y0 + y1) / 2, y1 - 0.3, y1 - 0.05 }
		-- 4 walls: sample along each, ray from 1 stud inside toward the wall, max travel 2.2
		local walls = {
			{ V(0, 0, -1), "z", mn.Z, mn.X, mx.X }, { V(0, 0, 1), "z", mx.Z, mn.X, mx.X },
			{ V(-1, 0, 0), "x", mn.X, mn.Z, mx.Z }, { V(1, 0, 0), "x", mx.X, mn.Z, mx.Z },
		}
		for _, w in walls do
			local dir, ax, fixed, a, b = w[1], w[2], w[3], w[4], w[5]
			for _, yy in heights do
				local run = {}
				local t = a + 0.05
				while t <= b - 0.05 do
					local o = if ax == "z" then V(t, yy, fixed - dir.Z * 1) else V(fixed - dir.X * 1, yy, t)
					local res = workspace:Raycast(o, dir * 2.2, rp)
					if res == nil then
						-- a ray exactly on the shared face of two touching wall pieces can slip between them
						-- (float precision, not a render gap): only count it if the ray also escapes 0.005 to each side
						local side = if ax == "z" then V(0.005, 0, 0) else V(0, 0, 0.005)
						res = workspace:Raycast(o + side, dir * 2.2, rp) or workspace:Raycast(o - side, dir * 2.2, rp)
					end
					table.insert(run, { t, res == nil })
					t += 0.25
				end
				-- thin escapes: an escaping sample with blocked samples within 0.5 on both sides
				for i = 3, #run - 2 do
					if run[i][2] then
						local left = not run[i - 1][2] or not run[i - 2][2]
						local right = not run[i + 1][2] or not run[i + 2][2]
						if left and right then
							leaks += 1
							if leaks <= 25 then say(("leak in %s toward %s at %s=%.2f y=%.2f"):format(r.Name, tostring(dir), ax == "z" and "x" or "z", run[i][1] - (if ax == "z" then 3000 else 0), yy)) end
						end
					end
				end
			end
		end
		-- floor/ceiling seams at the room edges (just inside) and a coarse grid
		local function vray(x, z)
			local up = workspace:Raycast(V(x, y1 - 1, z), V(0, 1.4, 0), rp)
			local dn = workspace:Raycast(V(x, y0 + 1, z), V(0, -1.4, 0), rp)
			return up ~= nil, dn ~= nil
		end
		for x = mn.X + 0.02, mx.X - 0.01, 1 do
			for z = mn.Z + 0.02, mx.Z - 0.01, 1 do
				local u, d = vray(x, z)
				local lz = z
				if not u or not d then
					-- stair holes are expected in the stair cores
					if not (r.Name:find("Stairwell")) then
						leaks += 1
						if leaks <= 25 then say(("%s seam in %s at x=%.2f z=%.2f"):format(if not u then "ceiling" else "floor", r.Name, x - 3000, lz)) end
					end
				end
			end
		end
	end
	for p in restore do p.CanQuery = false end
	say("leak samples flagged: " .. leaks)
end

----------------------------------------------------------------- z-fighting
if SECTION == "zfight" then
	local buckets = {}
	local faces = 0
	for _, p in allParts() do
		if isBlock(p) and not isHelper(p) and p.Transparency < 0.9 and aligned(p.CFrame) then
			local mn, mx = aabb(p)
			for ai, ax in { "X", "Y", "Z" } do
				local o1, o2 = if ax == "X" then "Y" else "X", if ax == "Z" then "Y" else "Z"
				for _, sgn in { -1, 1 } do
					local coord = if sgn < 0 then mn[ax] else mx[ax]
					local key = ax .. sgn .. math.floor(coord * 100 + 0.5)
					local b = buckets[key]
					if not b then b = {} buckets[key] = b end
					table.insert(b, { p, mn[o1], mx[o1], mn[o2], mx[o2] })
					faces += 1
				end
				local _ = ai
			end
		end
	end
	local pairsFound, fixed = 0, 0
	local seen = {}
	for key, b in buckets do
		if #b > 1 then
			for i = 1, #b do
				for j = i + 1, #b do
					local A, Bf = b[i], b[j]
					local ox = math.min(A[3], Bf[3]) - math.max(A[2], Bf[2])
					local oy = math.min(A[5], Bf[5]) - math.max(A[4], Bf[4])
					if ox > 0.02 and oy > 0.02 then
						local p, q = A[1], Bf[1]
						-- a coplanar pair is only visible if the space in front of the shared face is open:
						-- probe just outside the centre of the overlap (buried faces, e.g. under floors, are skipped)
						local buried = false
						do
							local ax = key:sub(1, 1)
							local sgn = tonumber(key:match("^.(%-?1)"))
							local c1 = (math.max(A[2], Bf[2]) + math.min(A[3], Bf[3])) / 2
							local c2 = (math.max(A[4], Bf[4]) + math.min(A[5], Bf[5])) / 2
							local coord = tonumber(key:match("^.%-?1(%-?%d+)$")) / 100 + sgn * 0.02
							local pt = if ax == "X" then V(coord, c1, c2) elseif ax == "Y" then V(c1, coord, c2) else V(c1, c2, coord)
							for _, r in overlapBox(CFrame.new(pt), V(0.01, 0.01, 0.01), { p, q }, false) do
								if r.Transparency < 0.3 then buried = true break end
							end
						end
						if not buried and (p.Color ~= q.Color or p.Material ~= q.Material or p.Transparency ~= q.Transparency) then
							local k = if p:GetDebugId() < q:GetDebugId() then p:GetDebugId() .. q:GetDebugId() else q:GetDebugId() .. p:GetDebugId()
							if not seen[k] then
								seen[k] = true
								pairsFound += 1
								if pairsFound <= 40 then
									say(("zfight %s | %s  plane %s  overlap %.2fx%.2f"):format(p:GetFullName():sub(22), q:GetFullName():sub(22), key, ox, oy))
								end
								if FIX then
									-- shrink the smaller (or the non-structural) part by 0.04 along the face normal so both of its
									-- faces on that axis sit 0.02 inside (a plain nudge can just move the fight to the other face)
									local ax = key:sub(1, 1)
									local small = if p.Size.Magnitude <= q.Size.Magnitude then p else q
									if isStructure(small) and not isStructure(if small == p then q else p) then small = if small == p then q else p end
									local wv = if ax == "X" then V(1, 0, 0) elseif ax == "Y" then V(0, 1, 0) else V(0, 0, 1)
									local lv = small.CFrame:VectorToObjectSpace(wv)
									small.Size = small.Size - V(math.abs(lv.X), math.abs(lv.Y), math.abs(lv.Z)) * 0.04
									fixed += 1
								end
							end
						end
					end
				end
			end
		end
	end
	say(("faces %d, z-fighting pairs %d, nudged %d"):format(faces, pairsFound, fixed))
end

----------------------------------------------------------------- clipping
if SECTION == "clip" then
	local n = 0
	local report = {}
	local IGN = { Rug = true, RugField = true, Trim = true, Casing = true, Handrail = true }
	for _, p in allParts() do
		if not isHelper(p) and not isStructure(p) and p.Transparency < 0.95 and not IGN[p.Name] then
			local prop = propOf(p)
			local tag = CS:HasTag(p, "Creaky")
			local size = p.Size - V(0.06, 0.06, 0.06)
			if size.X > 0 and size.Y > 0 and size.Z > 0 and not tag then
				for _, q in overlapBox(p.CFrame, size, { prop }, false) do
					if not IGN[q.Name] and q.Transparency < 0.95 then
						local exact = true
						if not (isBlock(p) and isBlock(q) and aligned(p.CFrame) and aligned(q.CFrame)) then
							-- bounding boxes only approximate cylinders/balls/wedges: confirm with exact geometry
							local op = OverlapParams.new()
							op.FilterType = Enum.RaycastFilterType.Include
							op.FilterDescendantsInstances = { q }
							op.RespectCanCollide = false
							local proxy = p:Clone()
							for _, c in proxy:GetChildren() do c:Destroy() end
							proxy.Size = size
							proxy.Transparency = 1
							proxy.CanCollide = false
							proxy.CanQuery = false
							proxy.CanTouch = false
							proxy.Parent = workspace
							exact = #workspace:GetPartsInPart(proxy, op) > 0
							proxy:Destroy()
						end
						if exact then
							local k = p:GetFullName() .. "|" .. q:GetFullName()
							if not report[k] then
								report[k] = true
								n += 1
								if n <= 50 then say(("clip %s  x  %s"):format(p:GetFullName():sub(22), q:GetFullName():sub(22))) end
							end
						end
					end
				end
			end
		end
	end
	say("clipping pairs: " .. n)
end

----------------------------------------------------------------- floating
if SECTION == "float" then
	local EXEMPT = { Balloon = true }
	local nPart, nModel = 0, 0
	local modelOK = {}
	local props = {}
	for _, p in allParts() do
		if not isHelper(p) and not isStructure(p) and p.Transparency < 0.95 and not EXEMPT[p.Name] then
			local touching = overlapBox(p.CFrame, p.Size + V(0.2, 0.2, 0.2), { p }, false)
			local prop = propOf(p)
			props[prop] = true
			if #touching == 0 then
				nPart += 1
				if nPart <= 30 then say("floating part " .. p:GetFullName():sub(22) .. " @" .. fmt(p.Position)) end
			end
			if prop ~= p then
				for _, q in touching do
					if not q:IsDescendantOf(prop) then modelOK[prop] = true break end
				end
			else
				if #touching > 0 then modelOK[prop] = true end
			end
		end
	end
	for prop in props do
		if not modelOK[prop] and prop:IsA("Model") then
			nModel += 1
			if nModel <= 30 then say("floating model " .. prop:GetFullName():sub(22) .. " @" .. fmt(prop:GetPivot().Position)) end
		end
	end
	say(("floating parts %d, floating models %d"):format(nPart, nModel))
end

----------------------------------------------------------------- stairs profile
if SECTION == "stairs" then
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	local walk = {}
	for _, p in allParts() do if p.CanCollide and not p:IsDescendantOf(H.Barriers) then table.insert(walk, p) end end
	local restore = {}
	for _, p in walk do if not p.CanQuery then restore[p] = true p.CanQuery = true end end
	rp.FilterDescendantsInstances = walk
	local function profile(name, x, z0, z1, ytop)
		local prev = nil
		local worst = 0
		local steps = math.floor(math.abs(z1 - z0) / 0.2)
		for i = 0, steps do
			local z = z0 + (z1 - z0) * i / steps
			local r = workspace:Raycast(O + V(x, ytop, z), V(0, -30, 0), rp)
			local h = r and r.Position.Y or -999
			if prev then worst = math.max(worst, math.abs(h - prev)) end
			prev = h
		end
		say(("%s: largest height change per 0.2 stud = %.2f"):format(name, worst))
		return worst
	end
	for _, xo in { -2, 0, 2 } do
		profile("MainFlight1 x" .. xo, -49 + xo, -19, -39.8, 13)
		profile("MainFlight2 x" .. xo, -41.9 + xo, -39.8, -19, 26)
		profile("ServiceFlight1 x" .. xo, -49 + xo, 19, 39.8, 13)
		profile("ServiceFlight2 x" .. xo, -41.9 + xo, 39.8, 19, 0)
		profile("WardFlight1 x" .. xo, 49 + xo, -19, -39.8, 26)
		profile("WardFlight2 x" .. xo, 41.9 + xo, -39.8, -19, 39)
		profile("EntranceRamp x" .. xo, 0 + xo, -64, -44, 11)
	end
	for p in restore do p.CanQuery = false end
end

----------------------------------------------------------------- flags / performance
if SECTION == "flags" then
	local parts, touchBad, queryDecor, shadowSmall, fixedN = 0, 0, 0, 0, 0
	for _, p in allParts() do
		parts += 1
		local tagged = CS:HasTag(p, "Creaky") or CS:HasTag(p, "Searchable") or (p.Parent and (CS:HasTag(p.Parent, "Breakable") or CS:HasTag(p, "Breakable")))
		if p.CanTouch and not tagged then
			touchBad += 1
			if FIX then p.CanTouch = false fixedN += 1 end
		end
		local vol = p.Size.X * p.Size.Y * p.Size.Z
		if not isStructure(p) and not isHelper(p) and not tagged and p.Name ~= "Panel" and p.Name ~= "FuseBox" and p.Name ~= "Trunk" and p.CanQuery and not p.CanCollide then
			queryDecor += 1
			if FIX then p.CanQuery = false fixedN += 1 end
		end
		if not isStructure(p) and vol < 2 and p.CastShadow then
			shadowSmall += 1
			if FIX then p.CastShadow = false fixedN += 1 end
		end
	end
	say(("parts %d; CanTouch on untagged %d; CanQuery on non-colliding decor %d; small clutter casting shadows %d; fixed %d"):format(parts, touchBad, queryDecor, shadowSmall, fixedN))
end
for p in restoreQ do if p.Parent then p.CanQuery = false end end
return table.concat(out, "\n")
end
_G.SPAudit = audit -- later calls: return _G.SPAudit("zfight", false)
return audit("flags", false)
