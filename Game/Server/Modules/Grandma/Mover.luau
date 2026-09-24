--!strict
-- Mover: pathfinding locomotion for an NPC humanoid.
--   local m = Mover.new(humanoid, root, agentParams)
--   m:SetGoal(position)          -- path there (async compute, stale results discarded)
--   m:SetDirect(position)        -- walk straight at it (used when she has line of sight)
--   m:Step()                     -- call every AI tick
--   m:Arrived() / m:Stop() / m:Pause(seconds)
-- Opens doors on the way through the DoorHook callback.

local PathfindingService = game:GetService("PathfindingService")

local Mover = {}
Mover.__index = Mover

export type Mover = typeof(setmetatable({} :: {
	Humanoid: Humanoid,
	Root: BasePart,
	Agent: { [string]: any },
	Goal: Vector3?,
	Direct: Vector3?,
	Waypoints: { PathWaypoint }?,
	Index: number,
	Req: number,
	PausedUntil: number,
	LastPos: Vector3,
	LastCheck: number,
	Stuck: number,
	DoorHook: ((Vector3, Vector3) -> number)?,
}, Mover))

local STUCK_TIME = 1.6
local REACH = 2.6

function Mover.new(humanoid: Humanoid, root: BasePart, agent: { [string]: any }): Mover
	return setmetatable({
		Humanoid = humanoid,
		Root = root,
		Agent = agent,
		Goal = nil,
		Direct = nil,
		Waypoints = nil,
		Index = 1,
		Req = 0,
		PausedUntil = 0,
		LastPos = root.Position,
		LastCheck = os.clock(),
		Stuck = 0,
		DoorHook = nil,
	}, Mover)
end

local function flatDist(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

function Mover.Compute(self: Mover, goal: Vector3)
	self.Req += 1
	local id = self.Req
	local from = self.Root.Position
	task.spawn(function()
		local path = PathfindingService:CreatePath(self.Agent)
		local ok = pcall(path.ComputeAsync, path, from, goal)
		if id ~= self.Req then
			return
		end
		if ok and path.Status == Enum.PathStatus.Success then
			local wps = path:GetWaypoints()
			self.Waypoints = wps
			self.Index = math.min(2, #wps)
		else
			-- No path: walk straight and let stuck-recovery sort it out.
			self.Waypoints = { PathWaypoint.new(goal, Enum.PathWaypointAction.Walk) }
			self.Index = 1
		end
	end)
end

function Mover.SetGoal(self: Mover, goal: Vector3, force: boolean?)
	self.Direct = nil
	if not force and self.Goal and (self.Goal - goal).Magnitude < 3 and self.Waypoints then
		return
	end
	self.Goal = goal
	self.Stuck = 0
	self:Compute(goal)
end

function Mover.SetDirect(self: Mover, pos: Vector3)
	self.Direct = pos
	self.Goal = pos
	self.Waypoints = nil
	self.Req += 1 -- discard any in-flight path
end

function Mover.Stop(self: Mover)
	self.Goal = nil
	self.Direct = nil
	self.Waypoints = nil
	self.Req += 1
	self.Humanoid:MoveTo(self.Root.Position)
end

function Mover.Pause(self: Mover, seconds: number)
	self.PausedUntil = os.clock() + seconds
	self.Humanoid:MoveTo(self.Root.Position)
end

function Mover.IsPaused(self: Mover): boolean
	return os.clock() < self.PausedUntil
end

function Mover.Arrived(self: Mover): boolean
	if not self.Goal then
		return true
	end
	if flatDist(self.Root.Position, self.Goal) < 3.2 and math.abs(self.Root.Position.Y - self.Goal.Y) < 6 then
		return true
	end
	if self.Waypoints and self.Index > #self.Waypoints then
		return true
	end
	return false
end

function Mover.Step(self: Mover)
	local now = os.clock()
	if now < self.PausedUntil then
		return
	end

	local target: Vector3? = nil
	if self.Direct then
		target = self.Direct
	elseif self.Waypoints then
		local wp = self.Waypoints[self.Index]
		if wp then
			if flatDist(self.Root.Position, wp.Position) < REACH and math.abs(self.Root.Position.Y - wp.Position.Y) < 5 then
				self.Index += 1
				wp = self.Waypoints[self.Index]
			end
			target = wp and wp.Position
		end
	end
	if not target then
		return
	end

	-- Doors ahead?
	if self.DoorHook then
		local pause = self.DoorHook(self.Root.Position, target)
		if pause > 0 then
			self:Pause(pause)
			return
		end
	end

	self.Humanoid:MoveTo(target)

	-- Stuck recovery
	if now - self.LastCheck > STUCK_TIME then
		local moved = (self.Root.Position - self.LastPos).Magnitude
		self.LastPos = self.Root.Position
		self.LastCheck = now
		if moved < 1 and self.Humanoid.WalkSpeed > 0 then
			self.Stuck += 1
			if self.Stuck >= 3 and self.Waypoints and self.Waypoints[self.Index] then
				-- Last resort: hop to the waypoint (never visible for long; she's in the dark).
				self.Root.CFrame = CFrame.new(self.Waypoints[self.Index].Position + Vector3.new(0, 3, 0)) * self.Root.CFrame.Rotation
				self.Stuck = 0
			elseif self.Goal then
				self:Compute(self.Goal)
			end
		else
			self.Stuck = 0
		end
	end
end

return Mover
