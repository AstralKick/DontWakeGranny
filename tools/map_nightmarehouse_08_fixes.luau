-- NightmareHouse step 8: fixes driven by map_nightmarehouse_audit. Guarded by NH_Fixes.
-- a) doors: hinge moved 0.2 into the opening and the leaf trimmed 0.2, so a leaf swung +-90 clears the jamb/casing
--    (hinge-side gap 0.25, far side 0.05, top 0.07)
-- b) roots in the basement never poke up through the ground floor slab (top <= 0.95)
-- c) things in door swings: the living-room armchair slides 1.2 east; veins inside any door sweep are removed
-- d) the yard fog's top layer (it crossed the front door's swing) is dropped
local NH = _G.NH
local V3, OX = Vector3.new, NH.OX
local CS = game:GetService("CollectionService")
local H = NH.root()
if H:GetAttribute("NH_Fixes") then return "fixes already applied" end
H:SetAttribute("NH_Fixes", true)
local out = {}

-- a) doors
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

-- b) roots under the den / hall: clamp every root cylinder below the ground-floor slab
local clamped = 0
local roots = H.Nightmare:FindFirstChild("Roots")
if roots then
	for _, p in roots:GetDescendants() do
		if p:IsA("Part") and p.Shape == Enum.PartType.Cylinder then
			local ax = p.CFrame.RightVector
			local rad = p.Size.Y / 2
			local len = p.Size.X
			local function topOf(l, c) return c.Y + math.abs(ax.Y) * l / 2 + math.sqrt(math.max(0, 1 - ax.Y * ax.Y)) * rad end
			local c = p.Position
			if topOf(len, c) > 0.95 then
				local lowEnd = if ax.Y >= 0 then c - ax * len / 2 else c + ax * len / 2
				local upDir = if ax.Y >= 0 then ax else -ax
				if math.abs(ax.Y) > 0.2 then
					local over = topOf(len, c) - 0.95
					local newLen = math.max(0.4, len - over / math.abs(ax.Y))
					p.Size = V3(newLen, p.Size.Y, p.Size.Z)
					p.CFrame = CFrame.fromMatrix(lowEnd + upDir * newLen / 2, p.CFrame.RightVector, p.CFrame.UpVector)
				else
					p.CFrame -= V3(0, topOf(len, c) - 0.95, 0)
				end
				clamped += 1
			end
		end
	end
end
-- glowing sap strips that ended up above the (clamped) trunk tops go too
if roots then
	for _, s in roots:GetChildren() do
		if s.Name == "Sap" then
			local a, b = NH.aabb(s)
			if b.Y > 0.95 then s:Destroy() end
		end
	end
end
table.insert(out, "roots clamped " .. clamped)

-- c) armchair out of the living-hall door swing
local arm = H.Ground.LivingRoom:FindFirstChild("Armchair")
if arm then arm:PivotTo(arm:GetPivot() + V3(1.2, 0, 0)) end -- 1.2: clear of the door swing, not into the east wall
for _, l in H.LootSpawns:GetChildren() do
	local lp = l.Position - V3(OX, 0, 0)
	if lp.X > 37 and lp.X < 43.5 and lp.Z > -15 and lp.Z < -8 and lp.Y < 10 then l.Position += V3(1.2, 0, 0) end
end
-- veins swept by any door (checked at 0..+-90 in 15 deg steps)
local probe = Instance.new("Part")
probe.Anchored = true
probe.CanCollide = false
probe.CanQuery = false
probe.Transparency = 1
probe.Parent = H
local veinsRemoved = 0
local VF = H.Nightmare:FindFirstChild("Veins")
local vlist = {}
for _, f in { VF, H.Corruption } do
	for _, v in f:GetDescendants() do
		if v:IsA("BasePart") and v.Name == "Vein" then
			vlist[v] = v.CanQuery
			v.CanQuery = true
		end
	end
end
local op = OverlapParams.new()
op.FilterType = Enum.RaycastFilterType.Include
op.FilterDescendantsInstances = { VF, H.Corruption }
for _, m in CS:GetTagged("Door") do
	if m:IsDescendantOf(H) then
		local hinge, panel = m.Hinge, m.Panel
		for deg = -90, 90, 15 do
			probe.Size = panel.Size + V3(0.1, 0.1, 0.3)
			probe.CFrame = hinge.CFrame * CFrame.Angles(0, math.rad(deg), 0) * hinge.CFrame:Inverse() * panel.CFrame
			for _, v in workspace:GetPartsInPart(probe, op) do
				if v.Name == "Vein" and v.Parent then
					vlist[v] = nil
					v:Destroy()
					veinsRemoved += 1
				end
			end
		end
	end
end
for v, q in vlist do if v.Parent then v.CanQuery = q end end
probe:Destroy()
table.insert(out, "veins removed from door swings " .. veinsRemoved)

-- e) Barrier_Basement moved from the hall side of the doorway (inside the door swing) to the top of the basement stair,
--    widened to the full stairwell (x 14..22) so it still seals the basement
local bb = H.Barriers:FindFirstChild("Barrier_Basement")
if bb then
	local k = 7.9 / 5.3
	for _, c in bb:GetChildren() do
		if c:IsA("BasePart") then
			local p = c.Position
			local rot = c.CFrame - c.Position
			if c.Name == "Collider" then
				c.Size = V3(8, 9.3, 0.45)
				c.CFrame = CFrame.new(OX + 18, 1.2 + 9.3 / 2, 5.975)
			else
				if c.Name == "Board" or c.Name == "Chain" then c.Size = V3(c.Size.X * k, c.Size.Y, c.Size.Z) end
				c.CFrame = rot + V3(OX + 18 + (p.X - OX - 18) * k, p.Y, p.Z + 5.45)
			end
		end
	end
end
-- d) fog layer that reached the front door
for _, p in H.Nightmare.YardFog:GetChildren() do
	if p.Name == "FogLayer" and p.Position.Y > 2 then p:Destroy() end
end
table.insert(out, "parts now " .. NH.count())
return table.concat(out, "\n")
