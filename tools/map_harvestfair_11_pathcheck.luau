-- HarvestFair pathfinding check (adapted from house_11_pathcheck). Grandma's agent: radius 1.6, height 5.5, no jump.
-- From the car-park spawn to every SearchNode, HidingSpot Front, the GrandmaSleepSpot (in front of the chair),
-- every PrizeSpawn (closest floor point) and Mom's car trunk, with the Barriers made non-collidable; then, with
-- the Barriers solid, every locked zone must be unreachable. Barrier collision is restored afterwards.
local PFS = game:GetService("PathfindingService")
local CS = game:GetService("CollectionService")
local H = workspace.Maps.HarvestFair
local V = Vector3.new
local function mk() return PFS:CreatePath({ AgentRadius = 1.6, AgentHeight = 5.5, AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 4 }) end
local start = H.PlayerSpawns.Spawn1.Position + V(0, 3, 0)
local targets = {}
for _, n in H.SearchNodes:GetChildren() do table.insert(targets, { "Node " .. n:GetAttribute("Area") .. " " .. tostring(n.Position - V(6000, 0, 0)), n.Position + V(0, 2.5, 0), n:GetAttribute("Area") }) end
for _, m in CS:GetTagged("HidingSpot") do
	if m:IsDescendantOf(H) then table.insert(targets, { "Hide " .. m.Name .. " " .. m:GetAttribute("Area"), m:FindFirstChild("Front", true).Position + V(0, 2.5, 0), m:GetAttribute("Area") }) end
end
local ss = H.GrandmaSleepSpot
table.insert(targets, { "SleepSpot (front of chair)", ss.Position + ss.CFrame.LookVector * 4.3 - V(0, 1, 0), "Ground" })
table.insert(targets, { "Trunk", H.MomsCar.Trunk.Position - H.MomsCar.Trunk.CFrame.LookVector * 3, "Ground" })
local saved = {}
local function barriers(on)
	for _, d in H.Barriers:GetDescendants() do
		if d:IsA("BasePart") then
			if saved[d] == nil then saved[d] = d.CanCollide end
			d.CanCollide = if on then saved[d] else false
		end
	end
end
local ok, fail = 0, {}
barriers(false)
local good, e = pcall(function()
	for _, t in targets do
		local p = mk()
		local s, err = pcall(function() p:ComputeAsync(start, t[2]) end)
		if s and p.Status == Enum.PathStatus.Success then
			local wps = p:GetWaypoints()
			local last = wps[#wps].Position
			if (last - t[2]).Magnitude > 4 then table.insert(fail, t[1] .. " (ends " .. math.floor((last - t[2]).Magnitude) .. " away)") else ok += 1 end
		else
			table.insert(fail, t[1] .. " status=" .. tostring(p.Status) .. " " .. tostring(err or ""))
		end
	end
end)
barriers(true)
-- locked zones with barriers solid
local locked = {}
local good2, e2 = pcall(function()
	for _, area in { "Upstairs", "Basement", "Attic" } do
		local reach, tried = 0, 0
		for _, t in targets do
			if t[3] == area and t[1]:sub(1, 4) == "Node" then
				tried += 1
				local p = mk()
				p:ComputeAsync(start, t[2])
				if p.Status == Enum.PathStatus.Success then
					local wps = p:GetWaypoints()
					if (wps[#wps].Position - t[2]).Magnitude < 4 then reach += 1 end
				end
			end
		end
		table.insert(locked, ("%s %d/%d reachable"):format(area, reach, tried))
	end
end)
for d, v in saved do d.CanCollide = v end
return ("paths ok %d / %d (barriers off)\nfailures:\n  %s\nwith barriers ON: %s\n%s %s"):format(ok, #targets, table.concat(fail, "\n  "), table.concat(locked, ", "), good and "" or tostring(e), good2 and "" or tostring(e2))
