-- Sunny Pines pathfinding check (edit mode, read-only apart from toggling Barrier collision for the test).
-- Grandma's agent (radius 1.6, height 5.5, no jumping). From the car-park spawn to every SearchNode, every
-- HidingSpot Front, the GrandmaSleepSpot and the Trunk with Barriers non-collidable; then with Barriers solid
-- every node of each locked area must be unreachable.
local PFS = game:GetService("PathfindingService")
local CS = game:GetService("CollectionService")
local H = workspace.Maps.SunnyPines
local function mk()
	return PFS:CreatePath({ AgentRadius = 1.6, AgentHeight = 5.5, AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 4 })
end
local spawn = H.PlayerSpawns:GetChildren()[1].Position + Vector3.new(0, 2.5, 0)
local function reach(from, to)
	local p = mk()
	local ok, e = pcall(function() p:ComputeAsync(from, to) end)
	if not ok then return false, "err " .. tostring(e) end
	if p.Status ~= Enum.PathStatus.Success then return false, tostring(p.Status) end
	local w = p:GetWaypoints()
	local d = (w[#w].Position - to) * Vector3.new(1, 0, 1)
	if d.Magnitude > 3.5 or math.abs(w[#w].Position.Y - to.Y) > 4 then return false, "ends " .. math.floor(d.Magnitude) .. " away" end
	return true
end
local targets = {}
for _, n in H.SearchNodes:GetChildren() do table.insert(targets, { "Node " .. n:GetAttribute("Area") .. " " .. tostring(n.Position - Vector3.new(3000, 0, 0)), n.Position + Vector3.new(0, 2.5, 0) }) end
for _, m in CS:GetTagged("HidingSpot") do
	if m:IsDescendantOf(H) then table.insert(targets, { "Hide " .. m:GetFullName():sub(22), m:FindFirstChild("Front", true).Position + Vector3.new(0, 2.5, 0) }) end
end
local ss = H.GrandmaSleepSpot
table.insert(targets, { "SleepSpot(front of chair)", (ss.CFrame * CFrame.new(0, -1.5, -3.2)).Position })
local tr = H.MomsCar.Trunk
table.insert(targets, { "Trunk", tr.Position - tr.CFrame.LookVector * 3 + Vector3.new(0, -0.6, 0) })
local saved = {}
for _, d in H.Barriers:GetDescendants() do
	if d:IsA("BasePart") then
		saved[d] = d.CanCollide
		d.CanCollide = false
	end
end
local ok, fail = 0, {}
for _, t in targets do
	local r, why = reach(spawn, t[2])
	if r then ok += 1 else table.insert(fail, t[1] .. ": " .. tostring(why)) end
end
for d, v in saved do d.CanCollide = v end
-- progressive unlock (nights 1..3 of the chapter): only the barriers of the open areas are removed
local locked = {}
for _, open in { {}, { "Upstairs" }, { "Upstairs", "Basement" } } do
	local set = {}
	for _, a in open do set[a] = true end
	local sv = {}
	for _, b in H.Barriers:GetChildren() do
		if set[b:GetAttribute("Area")] then
			for _, d in b:GetDescendants() do if d:IsA("BasePart") then sv[d] = d.CanCollide d.CanCollide = false end end
		end
	end
	local res = {}
	for _, area in { "Upstairs", "Basement", "Attic" } do
		local n, r = 0, 0
		for _, node in H.SearchNodes:GetChildren() do
			if node:GetAttribute("Area") == area then
				n += 1
				if reach(spawn, node.Position + Vector3.new(0, 2.5, 0)) then r += 1 end
			end
		end
		table.insert(res, ("%s %d/%d"):format(area, r, n))
	end
	for d, v in sv do d.CanCollide = v end
	table.insert(locked, "open {" .. table.concat(open, ",") .. "}: " .. table.concat(res, "  "))
end
return ("paths ok %d / %d\nfailures:\n  %s\nreachable nodes per area:\n  %s"):format(ok, #targets, table.concat(fail, "\n  "), table.concat(locked, "\n  "))
