-- HarvestFair detailed geometry audit (read-only; temporarily enables CanQuery on every part of the map for
-- spatial queries, then restores it). Defines _G.HF.audit(section) and returns its report.
--  1. Doors: gaps round the closed leaf (raycasts in the panel plane), leaf vs frame/walls/props at 0/+-30/+-60/+-90,
--     player capsule 2x5x1 through the open doorway.
--  2. Z-fighting: coplanar, same-facing, overlapping faces of different visible block parts.
--     Floating parts: visible parts touching nothing. Ramps: top/bottom edges flush with the floors.
--     Light leaks: rays from enclosed room centres to their corners/edges must hit something.
local B = _G.HF
local CS = game:GetService("CollectionService")
local V = Vector3.new
function B.audit(which)
	which = which or "all"
	local R = B.root()
	local out = {}
	local function add(s) table.insert(out, s) end
	-- temporarily make everything queryable
	local saved = {}
	for _, d in R:GetDescendants() do
		if d:IsA("BasePart") then
			saved[d] = d.CanQuery
			d.CanQuery = true
		end
	end
	local function isHelper(p)
		return p.Transparency >= 0.99 or p:IsDescendantOf(R.Rooms) or p:IsDescendantOf(R.LootSpawns) or p:IsDescendantOf(R.PrizeSpawns) or p:IsDescendantOf(R.SearchNodes) or p:IsDescendantOf(R.PlayerSpawns)
	end
	local helpers = {}
	for _, d in R:GetDescendants() do
		if d:IsA("BasePart") and isHelper(d) then table.insert(helpers, d) end
	end
	local function L(v) return v - V(B.OX, 0, 0) end
	local function fmt(v) v = L(v) return string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) end
	local ok, e = pcall(function()
		------------------------------------------------------------- 1. doors
		if which == "all" or which == "doors" then
			local nd, bad = 0, 0
			for _, m in CS:GetTagged("Door") do
				if m:IsDescendantOf(R) then
					nd += 1
					local hinge, panel = m.Hinge, m.Panel
					local rp = RaycastParams.new()
					rp.FilterType = Enum.RaycastFilterType.Exclude
					-- Barriers are excluded: they are hidden whenever the zone (and its doors) is usable
					local ex = { m, R.Barriers }
					for _, h in helpers do table.insert(ex, h) end
					rp.FilterDescendantsInstances = ex
					local cf, sz = panel.CFrame, panel.Size
					local issues = {}
					-- gaps
					for _, y in { -sz.Y * 0.35, 0, sz.Y * 0.35 } do
						for _, sx in { -1, 1 } do
							local o = (cf * CFrame.new(sx * (sz.X / 2 - 0.05), y, 0)).Position
							local r = workspace:Raycast(o, cf.RightVector * sx * 1.5, rp)
							local gap = if r then (r.Position - o).Magnitude - 0.05 else 99
							if gap > 0.25 then table.insert(issues, ("side gap %.2f"):format(gap)) end
						end
					end
					do
						local o = (cf * CFrame.new(0, sz.Y / 2 - 0.05, 0)).Position
						local r = workspace:Raycast(o, cf.UpVector * 1.5, rp)
						local gap = if r then (r.Position - o).Magnitude - 0.05 else 99
						if gap > 0.25 then table.insert(issues, ("top gap %.2f"):format(gap)) end
						local o2 = (cf * CFrame.new(0, -sz.Y / 2 + 0.05, 0)).Position
						local r2 = workspace:Raycast(o2, -cf.UpVector * 1.5, rp)
						local g2 = if r2 then (r2.Position - o2).Magnitude - 0.05 else 99
						if g2 > 0.25 then table.insert(issues, ("floor gap %.2f"):format(g2)) end
					end
					-- sweep
					local op = OverlapParams.new()
					op.FilterType = Enum.RaycastFilterType.Exclude
					op.FilterDescendantsInstances = ex
					local hcf = hinge.CFrame
					local rel = hcf:ToObjectSpace(cf)
					for _, ang in { 0, 30, 60, 90, -30, -60, -90 } do
						local pcf = hcf * CFrame.Angles(0, math.rad(ang), 0) * rel
						local hits = workspace:GetPartBoundsInBox(pcf, sz - V(0.04, 0.04, 0.04), op)
						local names = {}
						for _, h in hits do
							if h.CanCollide or h.Transparency < 0.5 then table.insert(names, h.Name) end
						end
						if #names > 0 then table.insert(issues, ("hits at %d: %s"):format(ang, table.concat(names, ",", 1, math.min(#names, 4)))) end
					end
					-- capsule through the open doorway (both swing directions)
					local through = cf.LookVector
					local center = (cf * CFrame.new(0, -sz.Y / 2 + 2.6 + 0.02, 0)).Position
					for _, ang in { 90, -90 } do
						-- move the door model virtually: exclude it, but test against its open panel position
						local pcf = hcf * CFrame.Angles(0, math.rad(ang), 0) * rel
						local ccf = CFrame.fromMatrix(center, cf.RightVector, Vector3.yAxis)
						local hits = workspace:GetPartBoundsInBox(ccf, V(2, 5, 1.2), op)
						local names = {}
						for _, h in hits do if h.CanCollide then table.insert(names, h.Name) end end
						-- the open leaf itself
						local lr = pcf:PointToObjectSpace(center)
						if math.abs(lr.X) < sz.X / 2 + 1 and math.abs(lr.Z) < sz.Z / 2 + 0.6 and math.abs(lr.Y) < sz.Y / 2 then table.insert(names, "OpenLeaf") end
						if #names > 0 then table.insert(issues, ("capsule blocked (%d): %s"):format(ang, table.concat(names, ",", 1, math.min(#names, 4)))) break end
					end
					if #issues > 0 then
						bad += 1
						add("DOOR " .. m:GetFullName():gsub("Workspace.Maps.HarvestFair.", "") .. " @" .. fmt(hinge.Position) .. ": " .. table.concat(issues, "; "))
					end
				end
			end
			add(("Doors checked %d, with issues %d"):format(nd, bad))
		end
		------------------------------------------------------------- 2a. z-fighting (block parts, axis-aligned in 90 deg steps)
		if which == "all" or which == "zfight" then
			local function aligned(p)
				if not (p:IsA("Part") and p.Shape == Enum.PartType.Block) then return false end
				local r = p.CFrame - p.CFrame.Position
				for _, v in { r.RightVector, r.UpVector, r.LookVector } do
					local ax = math.max(math.abs(v.X), math.abs(v.Y), math.abs(v.Z))
					if ax < 0.9999 then return false end
				end
				return true
			end
			local function aabb(p)
				local cf, s = p.CFrame, p.Size / 2
				local r = cf - cf.Position
				local ext = V(math.abs(r.RightVector.X) * s.X + math.abs(r.UpVector.X) * s.Y + math.abs(r.LookVector.X) * s.Z,
					math.abs(r.RightVector.Y) * s.X + math.abs(r.UpVector.Y) * s.Y + math.abs(r.LookVector.Y) * s.Z,
					math.abs(r.RightVector.Z) * s.X + math.abs(r.UpVector.Z) * s.Y + math.abs(r.LookVector.Z) * s.Z)
				return cf.Position - ext, cf.Position + ext
			end
			local op = OverlapParams.new()
			op.FilterType = Enum.RaycastFilterType.Include
			op.FilterDescendantsInstances = { R }
			-- a coplanar overlap is only visible if the space just outside it is not filled by a third opaque part
			local function hiddenFace(p, q, ka, o1, o2, a0, a1, b0, b1, coord, sgn)
				local c1 = (math.max(a0[o1], b0[o1]) + math.min(a1[o1], b1[o1])) / 2
				local c2 = (math.max(a0[o2], b0[o2]) + math.min(a1[o2], b1[o2])) / 2
				local t = { X = 0, Y = 0, Z = 0 }
				t[ka] = coord + sgn * 0.04
				t[o1] = c1
				t[o2] = c2
				local pt = V(t.X, t.Y, t.Z)
				for _, h in workspace:GetPartBoundsInBox(CFrame.new(pt), V(0.02, 0.02, 0.02), op) do
					if h ~= p and h ~= q and not isHelper(h) and h.Transparency < 0.5 then return true end
				end
				return false
			end
			local seen, n, list = {}, 0, {}
			for _, p in R:GetDescendants() do
				if p:IsA("BasePart") and not isHelper(p) and aligned(p) and p.Transparency < 0.9 then
					local a0, a1 = aabb(p)
					for _, q in workspace:GetPartBoundsInBox(CFrame.new((a0 + a1) / 2), (a1 - a0) + V(0.02, 0.02, 0.02), op) do
						if q ~= p and not isHelper(q) and aligned(q) and q.Transparency < 0.9 and not seen[q] then
							local b0, b1 = aabb(q)
							for ax = 1, 3 do
								local ka = if ax == 1 then "X" elseif ax == 2 then "Y" else "Z"
								local o1, o2 = if ax == 1 then "Y" else "X", if ax == 3 then "Y" else "Z"
								-- overlap area on the other two axes
								local w1 = math.min(a1[o1], b1[o1]) - math.max(a0[o1], b0[o1])
								local w2 = math.min(a1[o2], b1[o2]) - math.max(a0[o2], b0[o2])
								if w1 > 0.02 and w2 > 0.02 then
									for side, pair in { { a0[ka], b0[ka] }, { a1[ka], b1[ka] } } do
										if math.abs(pair[1] - pair[2]) < 0.003 and not hiddenFace(p, q, ka, o1, o2, a0, a1, b0, b1, pair[1], if side == 1 then -1 else 1) then
											n += 1
											if #list < 40 then
												table.insert(list, ("%s / %s (%s face @%.2f, %.2fx%.2f) %s"):format(p:GetFullName():gsub("Workspace.Maps.HarvestFair.Sections.", ""), q.Name, ka, pair[1] - (if ka == "X" then B.OX else 0), w1, w2, fmt(p.Position)))
											end
										end
									end
								end
							end
						end
					end
					seen[p] = true
				end
			end
			add("Z-fight candidates (coplanar same-facing overlapping faces): " .. n)
			for _, s in list do add("  ZF " .. s) end
		end
		------------------------------------------------------------- 2b. floating (visible parts touching nothing)
		if which == "all" or which == "float" then
			local op = OverlapParams.new()
			op.FilterType = Enum.RaycastFilterType.Include
			op.FilterDescendantsInstances = { R }
			local n, list = 0, {}
			for _, p in R:GetDescendants() do
				if p:IsA("BasePart") and not isHelper(p) and p.Transparency < 0.9 and not p:IsDescendantOf(R.Sections.base:FindFirstChild("FerrisWheel") or R) then
					local hits = workspace:GetPartBoundsInBox(p.CFrame, p.Size + V(0.12, 0.12, 0.12), op)
					local touching = false
					for _, h in hits do if h ~= p and not isHelper(h) then touching = true break end end
					if not touching then
						n += 1
						if #list < 40 then table.insert(list, p:GetFullName():gsub("Workspace.Maps.HarvestFair.Sections.", "") .. " " .. fmt(p.Position)) end
					end
				end
			end
			add("Floating/isolated parts: " .. n)
			for _, s in list do add("  FL " .. s) end
		end
		------------------------------------------------------------- 2c. ramps flush at both ends
		if which == "all" or which == "ramps" then
			local rp = RaycastParams.new()
			rp.FilterType = Enum.RaycastFilterType.Exclude
			rp.FilterDescendantsInstances = helpers
			for _, w in R:GetDescendants() do
				if w:IsA("WedgePart") and (w.Name:find("Ramp") or w.Name:find("Tilt")) then
					local cf, s = w.CFrame, w.Size
					-- low edge at local (0, -s.Y/2, -s.Z/2) (LookVector side), high edge at (0, s.Y/2, s.Z/2)
					local lowP = (cf * CFrame.new(0, -s.Y / 2, -s.Z / 2)).Position
					local highP = (cf * CFrame.new(0, s.Y / 2, s.Z / 2)).Position
					local function floorAt(p, dir)
						local o = p + dir * 0.3 + V(0, 1.5, 0)
						local r = workspace:Raycast(o, V(0, -3, 0), rp)
						return r and r.Position.Y
					end
					local fl = floorAt(lowP, cf.LookVector)
					local fh = floorAt(highP, -cf.LookVector)
					local msg = ("%s low %.2f/floor %s high %.2f/floor %s slope %.1f"):format(w:GetFullName():gsub("Workspace.Maps.HarvestFair.Sections.", ""), lowP.Y, fl and string.format("%.2f", fl) or "none", highP.Y, fh and string.format("%.2f", fh) or "none", math.deg(math.atan(s.Y / s.Z)))
					local lip = (fl and math.abs(fl - lowP.Y) > 0.12) or (fh and math.abs(fh - highP.Y) > 0.12) or not fl
					add((if lip then "  RAMP-LIP " else "  ramp ok ") .. msg)
				end
			end
		end
		------------------------------------------------------------- 2d. light leaks in enclosed rooms
		if which == "all" or which == "leaks" then
			local enclosed = { ["Fortune Teller's Tent"] = true, ["Funhouse Lobby"] = true, ["Tilted Room"] = true, ["Workshop"] = true, ["Costume Loft"] = true, ["Clown Gallery"] = true, ["Gallery Landing"] = true, ["Ghost Train West"] = true, ["Ghost Train East"] = true, ["Haunted Hall"] = true, ["Maintenance Room"] = true, ["Maintenance Tunnel"] = true, ["The Big Top"] = true, ["Ringmaster's Caravan"] = true, ["Clown Caravan"] = true, ["Strongman's Caravan"] = true, ["Ghost Train Station"] = true }
			local rp = RaycastParams.new()
			rp.FilterType = Enum.RaycastFilterType.Exclude
			rp.FilterDescendantsInstances = helpers
			local n = 0
			for _, r in R.Rooms:GetChildren() do
				if enclosed[r.Name] then
					local c, h = r.Position, r.Size / 2
					local leaks = {}
					for _, sx in { -1, 0, 1 } do
						for _, sy in { 0.2, 0.95 } do
							for _, sz in { -1, 0, 1 } do
								if not (sx == 0 and sz == 0) then
									local target = c + V(sx * h.X, (sy * 2 - 1) * h.Y, sz * h.Z)
									local o = c + V(0, (sy * 2 - 1) * h.Y * 0.5, 0)
									local dir = (target - o)
									dir = dir + dir.Unit * 3
									local hit = workspace:Raycast(o, dir, rp)
									if not hit then table.insert(leaks, string.format("(%d,%.1f,%d)", sx, sy, sz)) end
								end
							end
						end
					end
					if #leaks > 0 then
						n += 1
						add("  LEAK " .. r.Name .. " toward " .. table.concat(leaks, " "))
					end
				end
			end
			add("Rooms with open rays (possible light leaks / openings): " .. n)
		end
	end)
	for p, v in saved do if p.Parent then p.CanQuery = v end end
	if not ok then add("AUDIT ERROR: " .. tostring(e)) end
	return table.concat(out, "\n")
end
return B.audit("doors")
