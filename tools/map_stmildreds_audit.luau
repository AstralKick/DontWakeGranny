-- St. Mildred's geometry audit (edit mode, read-only apart from temporarily enabling CanQuery on the map's parts).
-- 1 doors: closed-panel gaps (raycasts in the panel plane), swing sweep 0/+-30/60/90 (GetPartsInPart), player box 2x5x1 through the open doorway
-- 2 z-fighting: coplanar, same-facing, overlapping faces of different visible block parts
-- 3 props intersecting structure (>0.1 penetration) ; 4 floating parts ; 5 ramp continuity
local CS = game:GetService("CollectionService")
local H = workspace.Maps:FindFirstChild("StMildreds")
assert(H, "no map")
local MODE = _G.SMAUDIT_MODE or "all" -- "doors" | "zfight" | "props" | "float" | "ramps" | "all"
local out = {}
local function add(s) table.insert(out, s) end
local function loc(p) local v = p - Vector3.new(4500, 0, 0) return ("(%.1f,%.1f,%.1f)"):format(v.X, v.Y, v.Z) end

-- temporarily enable CanQuery everywhere in the map so decor is seen by spatial queries/raycasts
local savedQ = {}
for _, d in H:GetDescendants() do
	if d:IsA("BasePart") and not d.CanQuery then
		savedQ[d] = true
		d.CanQuery = true
	end
end
local function isHelper(p)
	return p.Transparency >= 0.99
end
local function inFolder(p, name)
	local f = H:FindFirstChild(name)
	return f and p:IsDescendantOf(f)
end
local ok, err = pcall(function()
	----------------------------------------------------------------- 1 doors
	if MODE == "doors" or MODE == "all" then
		local nd, bad = 0, 0
		for _, m in CS:GetTagged("Door") do
			if m:IsDescendantOf(H) then
				nd += 1
				local panel, hinge = m:FindFirstChild("Panel"), m:FindFirstChild("Hinge")
				local probs = {}
				local rp = RaycastParams.new()
				rp.FilterType = Enum.RaycastFilterType.Exclude
				rp.FilterDescendantsInstances = { m }
				local cf, sz = panel.CFrame, panel.Size
				local function gapRay(origin, dir)
					local r = workspace:Raycast(origin, dir * 1.0, rp)
					while r and isHelper(r.Instance) do
						local o2 = r.Position + dir * 0.01
						r = workspace:Raycast(o2, dir * (1.0 - (o2 - origin).Magnitude), rp)
					end
					return if r then (r.Position - origin).Magnitude else 99
				end
				local worst = { L = 0, R = 0, T = 0 }
				for _, zz in { -0.1, 0, 0.1 } do
					for _, yy in { -3.5, -1.5, 0, 1.5, 3.5 } do
						for _, side in { -1, 1 } do
							local o = cf * Vector3.new(side * sz.X / 2, yy, zz)
							local g = gapRay(o, cf.RightVector * side)
							local k = if side < 0 then "L" else "R"
							worst[k] = math.max(worst[k], g)
						end
					end
					for _, xx in { -0.4, 0, 0.4 } do
						local o = cf * Vector3.new(xx * sz.X, sz.Y / 2, zz)
						worst.T = math.max(worst.T, gapRay(o, cf.UpVector))
					end
				end
				for k, g in worst do
					if g > 0.25 then table.insert(probs, ("gap %s %.2f"):format(k, g)) end
				end
				-- sweep
				local op = OverlapParams.new()
				op.FilterType = Enum.RaycastFilterType.Exclude
				local probe = Instance.new("Part")
				probe.Anchored = true
				probe.CanCollide = false
				probe.Transparency = 1
				probe.Size = sz - Vector3.new(0.04, 0.04, 0.04)
				probe.Parent = workspace
				op.FilterDescendantsInstances = { m, probe }
				local rel = hinge.CFrame:ToObjectSpace(cf)
				for _, deg in { 0, 30, 60, 90, -30, -60, -90 } do
					probe.CFrame = hinge.CFrame * CFrame.Angles(0, math.rad(deg), 0) * rel
					local hits = workspace:GetPartsInPart(probe, op)
					local names = {}
					for _, h in hits do
						if not isHelper(h) then table.insert(names, h.Name .. "@" .. (h.Parent and h.Parent.Name or "?")) end
					end
					if #names > 0 then table.insert(probs, ("sweep %d: %s"):format(deg, table.concat(names, ",", 1, math.min(#names, 4)))) end
				end
				-- player box through the open doorway (either swing direction must work)
				local floorY = cf.Position.Y - sz.Y / 2 - 0.05
				local passOK = false
				local passNote = ""
				for _, deg in { 90, -90 } do
					local savedPivot = m:GetPivot()
					m:PivotTo(hinge.CFrame * CFrame.Angles(0, math.rad(deg), 0) * hinge.CFrame:ToObjectSpace(savedPivot))
					probe.Size = Vector3.new(2, 5, 1)
					local blocked = nil
					for _, dd in { -2, -1, 0, 1, 2 } do
						local c = Vector3.new(cf.Position.X, floorY + 2.65, cf.Position.Z) + cf.LookVector * dd
						probe.CFrame = CFrame.fromMatrix(c, cf.RightVector, Vector3.yAxis)
						local op2 = OverlapParams.new()
						op2.FilterType = Enum.RaycastFilterType.Exclude
						op2.FilterDescendantsInstances = { probe }
						op2.RespectCanCollide = true
						local hits = workspace:GetPartsInPart(probe, op2)
						for _, h in hits do
							if h.CanCollide and not (h:IsDescendantOf(H.Barriers)) then
								blocked = h.Name .. "@" .. (h.Parent and h.Parent.Name or "?") .. " d=" .. dd
								break
							end
						end
						if blocked then break end
					end
					m:PivotTo(savedPivot)
					if not blocked then passOK = true break end
					passNote = passNote .. (" [%d: %s]"):format(deg, blocked)
				end
				probe:Destroy()
				if not passOK then table.insert(probs, "player box blocked" .. passNote) end
				if #probs > 0 then
					bad += 1
					add(("DOOR %s %s: %s"):format(m.Name, loc(cf.Position), table.concat(probs, "; ")))
				end
			end
		end
		add(("doors checked %d, with problems %d"):format(nd, bad))
	end

	----------------------------------------------------------------- 2 z-fighting
	if MODE == "zfight" or MODE == "all" then
		local faces = {}
		local buckets = {}
		local function keyOf(n, d)
			return ("%d,%d,%d|%d"):format(math.round(n.X * 100), math.round(n.Y * 100), math.round(n.Z * 100), math.floor(d / 0.02))
		end
		for _, p in H:GetDescendants() do
			if p:IsA("Part") and p.Shape == Enum.PartType.Block and p.Transparency < 0.99 then
				local cf, s = p.CFrame, p.Size / 2
				local axes = { { cf.RightVector, s.X, cf.UpVector, s.Y, cf.LookVector, s.Z }, { cf.UpVector, s.Y, cf.RightVector, s.X, cf.LookVector, s.Z }, { cf.LookVector, s.Z, cf.RightVector, s.X, cf.UpVector, s.Y } }
				for _, a in axes do
					for _, sg in { 1, -1 } do
						local n = a[1] * sg
						local d = n:Dot(cf.Position) + a[2]
						local f = { p = p, n = n, d = d, c = cf.Position + n * a[2], u = a[3], ue = a[4], v = a[5], ve = a[6] }
						local k = keyOf(n, d)
						buckets[k] = buckets[k] or {}
						table.insert(buckets[k], f)
					end
				end
			end
		end
		local seen, count = {}, 0
		local function overlapArea(f1, f2)
			-- project f2's rectangle onto f1's axes (only when axes are aligned)
			local a1 = math.abs(f1.u:Dot(f2.u))
			local e2u, e2v
			if a1 > 0.999 then
				e2u, e2v = f2.ue, f2.ve
			elseif math.abs(f1.u:Dot(f2.v)) > 0.999 then
				e2u, e2v = f2.ve, f2.ue
			else
				-- rotated in-plane: sample face2 and count samples strictly inside face1
				local inside, n = 0, 0
				for a = -0.9, 0.91, 0.3 do
					for b = -0.9, 0.91, 0.3 do
						n += 1
						local pt = f2.c + f2.u * (a * f2.ue) + f2.v * (b * f2.ve) - f1.c
						if math.abs(pt:Dot(f1.u)) < f1.ue - 0.01 and math.abs(pt:Dot(f1.v)) < f1.ve - 0.01 then inside += 1 end
					end
				end
				return inside / n * (4 * f2.ue * f2.ve)
			end
			local dc = f2.c - f1.c
			local du, dv = dc:Dot(f1.u), dc:Dot(f1.v)
			local ou = math.min(f1.ue, du + e2u) - math.max(-f1.ue, du - e2u)
			local ov = math.min(f1.ve, dv + e2v) - math.max(-f1.ve, dv - e2v)
			if ou <= 0.01 or ov <= 0.01 then return 0 end
			return ou * ov
		end
		for k, list in buckets do
			-- also compare with the neighbouring d bucket
			local nb = {}
			for _, f in list do table.insert(nb, f) end
			local base, di = k:match("^(.*)|(%-?%d+)$")
			local other = buckets[base .. "|" .. (tonumber(di) + 1)]
			if other then for _, f in other do table.insert(nb, f) end end
			for i = 1, #list do
				local f1 = list[i]
				for j = (if i < #list then i + 1 else #list + 1), #nb do
					local f2 = nb[j]
					if f2 and f1.p ~= f2.p and math.abs(f1.d - f2.d) < 0.012 and f1.n:Dot(f2.n) > 0.999 then
						local a = overlapArea(f1, f2)
						if a > 0.01 then
							local key = if f1.p:GetDebugId() < f2.p:GetDebugId() then f1.p:GetDebugId() .. f2.p:GetDebugId() else f2.p:GetDebugId() .. f1.p:GetDebugId()
							if not seen[key] then
								seen[key] = true
								count += 1
								if count <= (_G.SMAUDIT_MAX or 150) then
									add(("ZFIGHT %s/%s & %s/%s at %s area %.2f"):format(f1.p.Parent.Name, f1.p.Name, f2.p.Parent.Name, f2.p.Name, loc(f1.c), a))
								end
							end
						end
					end
				end
			end
		end
		add("z-fight pairs: " .. count)
	end

	----------------------------------------------------------------- 3 props intersecting structure
	if MODE == "props" or MODE == "all" then
		local structSet = {}
		for _, p in H.Structure:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency < 0.99 then structSet[p] = true end
		end
		for _, p in H.Exterior:GetChildren() do
			if p:IsA("BasePart") and (p.Name == "Grass" or p.Name == "Path" or p.Name == "Lane") then structSet[p] = true end
		end
		for _, p in H.Exterior.ChurchyardWall:GetDescendants() do
			if p:IsA("BasePart") then structSet[p] = true end
		end
		local op = OverlapParams.new()
		op.FilterType = Enum.RaycastFilterType.Include
		local list = {}
		for p in structSet do table.insert(list, p) end
		op.FilterDescendantsInstances = list
		local probe = Instance.new("Part")
		probe.Anchored = true
		probe.CanCollide = false
		probe.Transparency = 1
		probe.Parent = workspace
		local count = 0
		local skipNames = { Mound = 1, Headstone = 1, Shaft = 1, Top = 1, Slab = 1, Rug = 1, RugField = 1, Stave = 1, Trunk = 0 }
		for _, p in H:GetDescendants() do
			if p:IsA("BasePart") and not structSet[p] and p.Transparency < 0.99 and not inFolder(p, "Creaky") and not skipNames[p.Name] and not p:IsDescendantOf(H.Exterior.ChurchyardWall) then
				local s = p.Size - Vector3.new(0.2, 0.2, 0.2)
				if s.X > 0.05 and s.Y > 0.05 and s.Z > 0.05 then
					probe.Shape = if p:IsA("Part") then p.Shape else Enum.PartType.Block
					probe.Size = s
					probe.CFrame = p.CFrame
					local hits = workspace:GetPartsInPart(probe, op)
					if #hits > 0 then
						count += 1
						if count <= 60 then
							add(("INTERSECT %s/%s %s with %s/%s"):format(p.Parent.Name, p.Name, loc(p.Position), hits[1].Parent.Name, hits[1].Name))
						end
					end
				end
			end
		end
		probe:Destroy()
		add("prop/structure intersections: " .. count)
	end

	----------------------------------------------------------------- 4 floating parts
	if MODE == "float" or MODE == "all" then
		local hangers = { "Lamp", "Chandelier", "Cobweb", "Window", "Railing", "HymnBoard", "NoticeBoard", "Picture", "Belfry", "Bell", "Roof", "Ridge", "Coping", "Hood", "Louvre", "Came", "Sill", "Glass", "Strap", "Ring", "Handle", "Pull", "Knob", "Inset", "Rope", "Sally", "Boss", "Frame", "Header", "Moon", "Vane", "Finial", "Spire", "Plaque", "PealBoard", "Corbel", "TieBeam", "Impost", "Pier", "Capital", "Rib", "Ceiling", "Fascia", "Brace", "Cistern", "Pipe", "Chain", "Mirror", "CoatHooks", "Cassock", "Crest", "Number", "Stain", "Eye", "Conduit", "FuseLabel", "Downpipe", "Barge", "TieBeam", "SideBeam", "LanternCage", "LanternCap", "Head", "Glow", "Cage", "Cap", "Canopy", "Gable", "Pediment", "Arm", "Curtain", "Rod", "Shelf", "Grille", "Merlon", "Lid", "Wheel", "Headstock", "Crown", "Waist", "Lip", "Clapper", "FrameBeam", "FrameCross", "Pipe", "PipeMouth", "MusicDesk", "Desk", "Frontal", "Drape", "DrawerFront", "Drawer", "CabDoor", "Cabinet", "Vanity", "VanityDoor", "Front", "Doily", "Wing", "Handrail", "BookLedge", "EndCap", "Back", "Arch", "Infill", "Collider", "Hasp", "Padlock", "Sign", "SignText", "Rail", "Bar", "Mullion", "Crate", "FuseBox" }
		local function hanging(p)
			local n = p.Name
			for _, h in hangers do
				if n:find(h) then return true end
			end
			local a = p.Parent
			while a and a ~= H do
				for _, h in { "Lamp", "Chandelier", "Window", "Railing", "Belfry", "HymnBoard", "NoticeBoard", "Picture" } do
					if a.Name:find(h) then return true end
				end
				a = a.Parent
			end
			return false
		end
		-- a part is supported if a thin probe covering its footprint, from 0.12 below its bottom up to 0.05 above, overlaps any other visible or collidable part
		local probe = Instance.new("Part")
		probe.Anchored = true
		probe.CanCollide = false
		probe.Transparency = 1
		probe.Parent = workspace
		local count = 0
		for _, p in H:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency < 0.99 and not inFolder(p, "Structure") and not inFolder(p, "Corruption") and not hanging(p) and p.Size.Magnitude > 0.8 and p.Name ~= "Grass" then
				local okCF = math.abs(p.CFrame.UpVector.Y) > 0.99 or (p:IsA("Part") and p.Shape == Enum.PartType.Cylinder and math.abs(p.CFrame.RightVector.Y) > 0.99)
				if okCF then
					local hy = if math.abs(p.CFrame.UpVector.Y) > 0.99 then p.Size.Y else p.Size.X
					local bottom = p.Position.Y - hy / 2
					local vertCyl = math.abs(p.CFrame.UpVector.Y) <= 0.99
					local fx = if vertCyl then p.Size.Y * 0.7 else p.Size.X * 0.98
					local fz = if vertCyl then p.Size.Z * 0.7 else p.Size.Z * 0.98
					probe.Size = Vector3.new(math.max(0.1, fx), 0.17, math.max(0.1, fz))
					local look = p.CFrame.LookVector * Vector3.new(1, 0, 1)
					if look.Magnitude < 0.1 then look = Vector3.zAxis end
					local c0 = Vector3.new(p.Position.X, bottom - 0.035, p.Position.Z)
					probe.CFrame = if vertCyl then CFrame.new(c0) else CFrame.lookAt(c0, c0 + look)
					local op = OverlapParams.new()
					op.FilterType = Enum.RaycastFilterType.Exclude
					op.FilterDescendantsInstances = { p, probe }
					local hits = workspace:GetPartsInPart(probe, op)
					local supported = false
					for _, h in hits do
						if h.Transparency < 0.99 or h.CanCollide then supported = true break end
					end
					if not supported then
						count += 1
						if count <= 60 then add(("FLOAT %s/%s bottom %.2f at %s"):format(p.Parent.Name, p.Name, bottom, loc(p.Position))) end
					end
				end
			end
		end
		probe:Destroy()
		add("floating parts: " .. count)
	end

	----------------------------------------------------------------- 5 ramps
	if MODE == "ramps" or MODE == "all" then
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		for _, w in H:GetDescendants() do
			if w:IsA("WedgePart") and w.Name == "Ramp" then
				rp.FilterDescendantsInstances = { w }
				local lowEdge = w.CFrame * Vector3.new(0, -w.Size.Y / 2, -w.Size.Z / 2)
				local highEdge = w.CFrame * Vector3.new(0, w.Size.Y / 2, w.Size.Z / 2)
				local function down(o, len)
					local r = workspace:Raycast(o, Vector3.new(0, -len, 0), rp)
					while r and isHelper(r.Instance) and not r.Instance.CanCollide do
						local o2 = r.Position - Vector3.new(0, 0.01, 0)
						r = workspace:Raycast(o2, Vector3.new(0, -(len - (o.Y - o2.Y)), 0), rp)
					end
					return r
				end
				local r1 = down(lowEdge + w.CFrame.LookVector * 0.3 + Vector3.new(0, 1, 0), 2)
				local r2 = down(highEdge - w.CFrame.LookVector * 0.6 + Vector3.new(0, 1.5, 0), 2.5)
				local e1 = if r1 then r1.Position.Y - lowEdge.Y else 99
				local e2 = if r2 then r2.Position.Y - highEdge.Y else 99
				local slope = math.deg(math.atan2(w.Size.Y, w.Size.Z))
				add(("RAMP %s low-step %.2f high-step %.2f slope %.1f%s"):format(w.Parent.Name, e1, e2, slope, if math.abs(e1) > 0.2 or math.abs(e2) > 0.2 or slope > 35 then "  <-- CHECK" else ""))
			end
		end
	end
end)
for p in savedQ do
	if p.Parent then p.CanQuery = false end
end
if not ok then add("AUDIT ERROR: " .. tostring(err)) end
return table.concat(out, "\n")
