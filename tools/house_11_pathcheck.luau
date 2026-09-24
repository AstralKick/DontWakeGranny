-- Pathfinding check (edit mode): from the entry hall (and the yard spawn) to every SearchNode, HidingSpot Front,
-- PrizeSpawn and Grandma's sleep spot. Barriers are made non-collidable during the check, then restored.
local PFS = game:GetService("PathfindingService")
local CS = game:GetService("CollectionService")
local H = workspace.House
local saved = {}
for _, d in H.Barriers:GetDescendants() do
	if d:IsA("BasePart") then
		saved[d] = d.CanCollide
		d.CanCollide = false
	end
end
local function mk() return PFS:CreatePath({ AgentRadius = 1.6, AgentHeight = 5.5, AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 4 }) end
local starts = { Entry = Vector3.new(-5, 5, -28), Yard = H.PlayerSpawns:GetChildren()[1].Position + Vector3.new(0, 3, 0) }
local targets = {}
for _, n in H.SearchNodes:GetChildren() do table.insert(targets, { "Node " .. n:GetAttribute("Area"), n.Position + Vector3.new(0, 2.5, 0) }) end
for _, m in CS:GetTagged("HidingSpot") do
	if m:IsDescendantOf(H) then table.insert(targets, { "Hide " .. m.Name, m:FindFirstChild("Front", true).Position + Vector3.new(0, 2.5, 0) }) end
end
table.insert(targets, { "SleepSpot", H.GrandmaSleepSpot.Position })
table.insert(targets, { "Trunk", H.MomsCar.Trunk.Position + H.MomsCar.Trunk.CFrame.LookVector * -3 })
local ok, fail = 0, {}
for _, t in targets do
	local p = mk()
	local s, e = pcall(function() p:ComputeAsync(starts.Entry, t[2]) end)
	if s and p.Status == Enum.PathStatus.Success then
		ok += 1
		local wps = p:GetWaypoints()
		local last = wps[#wps].Position
		if (last - t[2]).Magnitude > 4 then table.insert(fail, t[1] .. " (ends " .. math.floor((last - t[2]).Magnitude) .. " away)") end
	else
		table.insert(fail, t[1] .. " @" .. tostring(t[2]) .. " status=" .. tostring(p.Status) .. " " .. tostring(e or ""))
	end
end
local py = mk()
py:ComputeAsync(starts.Yard, starts.Entry)
for d, v in saved do d.CanCollide = v end
-- barrier check: with barriers solid, locked areas must be unreachable from the entry
local locked = {}
for _, area in { "Upstairs", "Basement", "Attic" } do
	for _, n in H.SearchNodes:GetChildren() do
		if n:GetAttribute("Area") == area then
			local p = mk()
			p:ComputeAsync(starts.Entry, n.Position + Vector3.new(0, 2.5, 0))
			local reached = p.Status == Enum.PathStatus.Success and (p:GetWaypoints()[#p:GetWaypoints()].Position - n.Position).Magnitude < 4
			table.insert(locked, area .. (if reached then " REACHABLE(!)" else " blocked"))
			break
		end
	end
end
return ("paths ok %d / %d; yard->entry %s\nfailures:\n  %s\nwith barriers: %s"):format(ok, #targets, tostring(py.Status), table.concat(fail, "\n  "), table.concat(locked, ", "))
