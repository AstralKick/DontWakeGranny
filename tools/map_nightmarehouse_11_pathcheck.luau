-- NightmareHouse pathfinding check (Edit mode, read-only; barrier collision is restored at the end).
-- Grandma's agent (radius 1.6, height 5.5, no jumping) from the entry hall and from the yard spawn to every SearchNode,
-- HidingSpot Front, PrizeSpawn, PumpkinSpot, the GrandmaSleepSpot and Mom's car Trunk with all Barriers off; then the
-- chapter's unlock order (night 1: all barriers, night 2: Upstairs open, night 3: + Basement) must keep every node of
-- each still-locked area unreachable.
local PFS = game:GetService("PathfindingService")
local CS = game:GetService("CollectionService")
local H = workspace.Maps.NightmareHouse
local OX = 7500
local V3 = Vector3.new
local function mk() return PFS:CreatePath({ AgentRadius = 1.6, AgentHeight = 5.5, AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 4 }) end
local saved = {}
for _, d in H.Barriers:GetDescendants() do
	if d:IsA("BasePart") then saved[d] = d.CanCollide end
end
local function barriers(openAreas)
	for d, v in saved do
		local area = d:FindFirstAncestorOfClass("Model") and d:FindFirstAncestorOfClass("Model"):GetAttribute("Area") or d:GetAttribute("Area")
		d.CanCollide = v and not openAreas[area]
	end
end
local function reach(from, to, tolH, tolV)
	local p = mk()
	local ok = pcall(function() p:ComputeAsync(from, to) end)
	if not ok or p.Status ~= Enum.PathStatus.Success then return false, "status " .. tostring(p.Status) end
	local wps = p:GetWaypoints()
	local last = wps[#wps].Position
	local d = (V3(last.X, 0, last.Z) - V3(to.X, 0, to.Z)).Magnitude
	if d > (tolH or 4) or math.abs(last.Y - to.Y) > (tolV or 4) then return false, ("ends %.1f away"):format(d) end
	return true
end
local entry = V3(-5 + OX, 5, -28)
local yard = H.PlayerSpawns:GetChildren()[1].Position + V3(0, 3, 0)
local targets = {}
for _, n in H.SearchNodes:GetChildren() do table.insert(targets, { "Node " .. n:GetAttribute("Area"), n.Position + V3(0, 2.5, 0), n:GetAttribute("Area") }) end
for _, m in CS:GetTagged("HidingSpot") do
	if m:IsDescendantOf(H) then table.insert(targets, { "Hide " .. m.Name, m:FindFirstChild("Front", true).Position + V3(0, 2.5, 0) }) end
end
for _, p in H.PumpkinSpots:GetChildren() do table.insert(targets, { "Pumpkin " .. p:GetAttribute("Area"), p.Position + V3(0, 2.5, 0) }) end
-- prizes rest ON furniture (mantel, nightstand, pillow): getting within 5 studs is enough to grab one
for _, p in H.PrizeSpawns:GetChildren() do table.insert(targets, { "Prize " .. p:GetAttribute("Area"), p.Position + V3(0, 1.5, 0), nil, 5, 7 }) end
table.insert(targets, { "SleepSpot", H.GrandmaSleepSpot.Position })
table.insert(targets, { "Trunk", H.MomsCar.Trunk.Position + H.MomsCar.Trunk.CFrame.LookVector * -3 })
local out = {}
local ok, err = pcall(function()
	barriers({ Upstairs = true, Basement = true, Attic = true })
	local good, fails = 0, {}
	for _, t in targets do
		local s, why = reach(entry, t[2], t[4], t[5])
		if not s and t[4] then
			-- prize on furniture: Grandma/players only need to reach the floor within 4 studs of it
			local rpF = RaycastParams.new()
			rpF.FilterType = Enum.RaycastFilterType.Include
			rpF.FilterDescendantsInstances = { H }
			for k = 0, 11 do
				local a = k / 12 * math.pi * 2
				local p = t[2] + V3(math.cos(a) * 3, 0, math.sin(a) * 3)
				local h = workspace:Raycast(p + V3(0, 1, 0), V3(0, -12, 0), rpF)
				if h and h.Instance.CanCollide and t[2].Y - h.Position.Y < 9 and reach(entry, h.Position + V3(0, 2.5, 0)) then
					s = true
					break
				end
			end
		end
		if s then good += 1 else table.insert(fails, ("%s @%.1f,%.1f,%.1f: %s"):format(t[1], t[2].X - OX, t[2].Y, t[2].Z, why)) end
	end
	local ys = reach(yard, entry)
	table.insert(out, ("barriers off: %d / %d reachable from the entry hall; yard -> entry %s"):format(good, #targets, tostring(ys)))
	for i = 1, math.min(#fails, 30) do table.insert(out, "  FAIL " .. fails[i]) end
	-- unlock order of this chapter: night 1 nothing, night 2 Upstairs, night 3 Upstairs+Basement, night 4 all
	for _, st in { { "night 1", {} }, { "night 2", { Upstairs = true } }, { "night 3", { Upstairs = true, Basement = true } } } do
		barriers(st[2])
		local leaks = {}
		local tested = 0
		for _, t in targets do
			local a = t[3]
			if a and a ~= "Ground" and not st[2][a] then
				tested += 1
				if reach(entry, t[2]) then table.insert(leaks, ("%s @%.1f,%.1f,%.1f"):format(t[1], t[2].X - OX, t[2].Y, t[2].Z)) end
			end
		end
		table.insert(out, ("%s: %d locked nodes tested, %d reachable%s"):format(st[1], tested, #leaks, if #leaks > 0 then " -> " .. table.concat(leaks, "; ") else ""))
	end
end)
for d, v in saved do d.CanCollide = v end
if not ok then table.insert(out, "ERROR " .. tostring(err)) end
return table.concat(out, "\n")
