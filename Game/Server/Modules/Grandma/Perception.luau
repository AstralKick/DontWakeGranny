--!strict
-- Perception: Grandma's eyes. Pure functions + one shared RaycastParams.

local Players = game:GetService("Players")

local Perception = {}

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.RespectCanCollide = true -- curtains, volumes, FX etc. never block her sight
params.IgnoreWater = true

-- Rebuilt whenever characters change (cheap; called by GrandmaService each second).
function Perception.RefreshFilter(grandma: Model)
	local list: { Instance } = { grandma }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	local lootFolder = workspace:FindFirstChild("LootActive")
	if lootFolder then
		table.insert(list, lootFolder)
	end
	local fx = workspace:FindFirstChild("FX")
	if fx then
		table.insert(list, fx)
	end
	params.FilterDescendantsInstances = list
end

-- Unobstructed line between two points (ignores characters/loot).
function Perception.Clear(from: Vector3, to: Vector3): boolean
	local dir = to - from
	local hit = workspace:Raycast(from, dir, params)
	if not hit then
		return true
	end
	-- Transparent/non-colliding decor never blocks sight.
	local inst = hit.Instance
	return inst.Transparency > 0.9 or (not inst.CanCollide and not inst.CanQuery)
end

-- Can Grandma (head position + facing) see this character?
function Perception.CanSee(eye: Vector3, facing: Vector3, char: Model, range: number, fovDeg: number): boolean
	local head = char:FindFirstChild("Head") :: BasePart?
	local torso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")) :: BasePart?
	if not head or not torso then
		return false
	end
	local toTarget = head.Position - eye
	local dist = toTarget.Magnitude
	if dist > range then
		return false
	end
	if dist > 4 then
		local flatLook = Vector3.new(facing.X, 0, facing.Z)
		local flatDir = Vector3.new(toTarget.X, 0, toTarget.Z)
		if flatLook.Magnitude > 0 and flatDir.Magnitude > 0 then
			local dot = flatLook.Unit:Dot(flatDir.Unit)
			if dot < math.cos(math.rad(fovDeg / 2)) then
				return false
			end
		end
	end
	return Perception.Clear(eye, head.Position) or Perception.Clear(eye, torso.Position)
end

return Perception
