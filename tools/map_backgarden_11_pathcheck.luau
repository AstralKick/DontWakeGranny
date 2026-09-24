-- BackGarden pathfinding check (edit mode, adapted from house_11_pathcheck). Grandma's agent
-- (radius 1.6, height 5.5, no jump) from the first PlayerSpawn to every SearchNode, HidingSpot Front,
-- the GrandmaSleepSpot (standing point in front of her chair) and the Trunk, with Barriers
-- temporarily non-collidable (goals = the exact positions GrandmaService uses: node.Position, Front.Position,
-- GrandmaSleepSpot.Position); then verifies every locked zone is unreachable with the Barriers solid.
local PFS = game:GetService("PathfindingService")
local CS = game:GetService("CollectionService")
local H = workspace.Maps.BackGarden
local function mk() return PFS:CreatePath({ AgentRadius = 1.6, AgentHeight = 5.5, AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 4 }) end
local start = H.PlayerSpawns:GetChildren()[1].Position + Vector3.new(0, 3, 0)
local OFF = Vector3.new(1500, 0, 0)
local function loc(v) return v - OFF end
local function reach(target)
	local p = mk()
	local ok, e = pcall(function() p:ComputeAsync(start, target) end)
	if not ok then return false, "err " .. tostring(e) end
	if p.Status ~= Enum.PathStatus.Success then return false, tostring(p.Status) end
	local wps = p:GetWaypoints()
	local last = wps[#wps].Position
	local d = (Vector3.new(last.X, 0, last.Z) - Vector3.new(target.X, 0, target.Z)).Magnitude
	if d > 4 or math.abs(last.Y - target.Y) > 6 then return false, ("ends %.1f away"):format(d) end
	return true, #wps
end
local targets = {}
for _, n in H.SearchNodes:GetChildren() do table.insert(targets, { "Node " .. n:GetAttribute("Area"), n.Position, n:GetAttribute("Area") }) end
for _, m in CS:GetTagged("HidingSpot") do
	if m:IsDescendantOf(H) then table.insert(targets, { "Hide " .. m.Name, m:FindFirstChild("Front", true).Position, m:GetAttribute("Area") }) end
end
local ss = H.GrandmaSleepSpot
local stand = ss.Position + ss.CFrame.LookVector * 4
table.insert(targets, { "SleepSpot(front of chair)", Vector3.new(stand.X, ss.Position.Y - 1, stand.Z), "Ground" })
table.insert(targets, { "SleepSpot(exact goal)", ss.Position, "Ground" })
table.insert(targets, { "Trunk", H.MomsCar.Trunk.Position + H.MomsCar.Trunk.CFrame.LookVector * -3, "Ground" })
-- barriers off
local saved = {}
for _, d in H.Barriers:GetDescendants() do
	if d:IsA("BasePart") then
		saved[d] = d.CanCollide
		d.CanCollide = false
	end
end
local okN, fail = 0, {}
for _, t in targets do
	local ok, info = reach(t[2])
	if ok then okN += 1 else table.insert(fail, t[1] .. " @" .. tostring(loc(t[2])) .. " -> " .. tostring(info)) end
end
for d, v in saved do d.CanCollide = v end
-- barriers on: locked zones must be unreachable (every node of every locked area)
local locked = {}
for _, area in { "Upstairs", "Basement", "Attic" } do
	local reached, total = 0, 0
	for _, n in H.SearchNodes:GetChildren() do
		if n:GetAttribute("Area") == area then
			total += 1
			if reach(n.Position) then reached += 1 end
		end
	end
	table.insert(locked, ("%s %s (%d/%d nodes reachable)"):format(area, if reached == 0 then "blocked" else "REACHABLE(!)", reached, total))
end
return ("paths ok %d / %d\nfailures:\n  %s\nwith barriers: %s"):format(okN, #targets, table.concat(fail, "\n  "), table.concat(locked, ", "))
