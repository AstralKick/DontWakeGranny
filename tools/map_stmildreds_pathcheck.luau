-- St. Mildred's pathfinding check (edit mode; adapted from house_11_pathcheck.luau). Grandma's agent: radius 1.6, height 5.5, no jumping.
-- 1) Barriers made non-collidable: paths from Grandma's pew (and from the lane spawn) to every SearchNode, HidingSpot Front,
--    PrizeSpawn, the GrandmaSleepSpot and the car Trunk. 2) Barriers restored: every locked area must be unreachable.
local PFS = game:GetService("PathfindingService")
local CS = game:GetService("CollectionService")
local H = workspace.Maps.StMildreds
local O = Vector3.new(4500, 0, 0)
local saved = {}
for _, d in H.Barriers:GetDescendants() do
	if d:IsA("BasePart") then
		saved[d] = d.CanCollide
		d.CanCollide = false
	end
end
local function mk() return PFS:CreatePath({ AgentRadius = 1.6, AgentHeight = 5.5, AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 4 }) end
local pewFront = O + Vector3.new(0, 4.5, 14.5) -- centre aisle beside Grandma's pew
local spawn = H.PlayerSpawns:GetChildren()[1].Position + Vector3.new(0, 3, 0)
local targets = {}
-- goals 1.5 above the floor marker (2.5 made PathfindingService snap some ringing-chamber goals to the belfry floor above)
for _, n in H.SearchNodes:GetChildren() do table.insert(targets, { "Node " .. n:GetAttribute("Area") .. " " .. tostring(n.Position - O), n.Position + Vector3.new(0, 1.5, 0) }) end
for _, m in CS:GetTagged("HidingSpot") do
	if m:IsDescendantOf(H) then table.insert(targets, { "Hide " .. m.Name, m:FindFirstChild("Front", true).Position + Vector3.new(0, 1.5, 0) }) end
end
-- Grandma gets up from her pew seat and steps forward into the cross aisle
local ss = H.GrandmaSleepSpot
table.insert(targets, { "SleepSpot (in front of the pew)", ss.Position + ss.CFrame.LookVector * 2.6 - Vector3.new(0, 1, 0) })
local trunk = H.MomsCar.Trunk
table.insert(targets, { "Trunk", trunk.Position - trunk.CFrame.LookVector * 3 - Vector3.new(0, 0.5, 0) })
task.wait(1.5) -- let the navmesh pick up the barrier change
local okN, fail, far = 0, {}, 0
local slow = os.clock()
for _, t in targets do
	local p = mk()
	local s, e = pcall(function() p:ComputeAsync(pewFront, t[2]) end)
	if s and p.Status == Enum.PathStatus.Success then
		local wps = p:GetWaypoints()
		local last = wps[#wps].Position
		local tol = 4
		if (last - t[2]).Magnitude > tol then
			far += 1
			table.insert(fail, t[1] .. " (ends " .. math.floor((last - t[2]).Magnitude * 10) / 10 .. " away)")
		else
			okN += 1
		end
	else
		table.insert(fail, t[1] .. " status=" .. tostring(p.Status) .. " " .. tostring(e or ""))
	end
end
local py = mk()
py:ComputeAsync(spawn, pewFront)
local spawnStatus = tostring(py.Status)
-- players (radius 1, height 5) must reach a floor point within 5 studs of every PrizeSpawn
local pfail = {}
local function floorY(pos)
	for _, r in H.Rooms:GetChildren() do
		local rel = r.CFrame:PointToObjectSpace(pos)
		local h = r.Size / 2
		if math.abs(rel.X) <= h.X and math.abs(rel.Y) <= h.Y + 0.6 and math.abs(rel.Z) <= h.Z then return r.Position.Y - h.Y end
	end
	return pos.Y - 3
end
for _, pz in H.PrizeSpawns:GetChildren() do
	local fy = floorY(pz.Position)
	local reached = false
	for i = 0, 11 do
		local a = i * math.pi / 6
		for _, rad in { 2.2, 3.2 } do
			local tgt = Vector3.new(pz.Position.X + math.cos(a) * rad, fy + 2.5, pz.Position.Z + math.sin(a) * rad)
			local p = PFS:CreatePath({ AgentRadius = 1, AgentHeight = 5, AgentCanJump = false })
			p:ComputeAsync(spawn, tgt)
			local wps = p:GetWaypoints()
			if p.Status == Enum.PathStatus.Success and (wps[#wps].Position - pz.Position).Magnitude < 5.5 then
				reached = true
				break
			end
		end
		if reached then break end
	end
	if not reached then table.insert(pfail, tostring(pz.Position - O)) end
end
for d, v in saved do d.CanCollide = v end
task.wait(1.5)
-- barrier check: with barriers solid, locked areas must be unreachable from the pew (and from the spawn)
local locked = {}
for _, area in { "Upstairs", "Basement", "Attic" } do
	local reachable = 0
	local total = 0
	for _, n in H.SearchNodes:GetChildren() do
		if n:GetAttribute("Area") == area then
			total += 1
			for _, st in { pewFront, spawn } do
				local p = mk()
				p:ComputeAsync(st, n.Position + Vector3.new(0, 1.5, 0))
				if p.Status == Enum.PathStatus.Success and (p:GetWaypoints()[#p:GetWaypoints()].Position - n.Position).Magnitude < 4 then
					reachable += 1
					break
				end
			end
		end
	end
	table.insert(locked, ("%s %d/%d nodes reachable%s"):format(area, reachable, total, if reachable > 0 then " (!)" else " -> blocked OK"))
end
return ("Grandma paths ok %d / %d (from beside her pew); spawn->pew %s; player->prizes failures %d %s; %.1fs\nfailures:\n  %s\nwith barriers: %s"):format(okN, #targets, spawnStatus, #pfail, table.concat(pfail, "; "), os.clock() - slow, table.concat(fail, "\n  "), table.concat(locked, ", "))
