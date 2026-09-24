--!strict
-- GrandmaEyesController
-- Grandma's eyelids, animated locally from her State attribute:
--   Asleep            eyes closed (cartoon "︶" lids behind her glasses)
--   FakeSleep         closed... but one lid slowly slides open now and then (the tell!)
--   Stirring          lids flutter
--   awake states      open, with natural blinks (never blinks while Chasing)
--
-- Rig-agnostic: if the rig has its own parts named "Eyelid" (any number) they're toggled
-- visible/invisible. Otherwise lids are generated from "LeftEyeWhite"/"RightEyeWhite" discs
-- when present, or from the parts named "Eye". Nothing here affects gameplay.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local GrandmaEyesController = {}

type Lid = { Parts: { BasePart }, Side: number }
type Rig = { Model: Model, Lids: { Lid }, Conns: { RBXScriptConnection }, NextBlink: number, BlinkUntil: number, PeekUntil: number, NextPeek: number }

local rigs: { [Model]: Rig } = {}
local SKIN_FALLBACK = Color3.fromRGB(230, 205, 184)
local INK = Color3.fromRGB(42, 26, 36)

local function mkPart(name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = false
	p.Massless = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	return p
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

-- Build one generated lid in front of an eye centre. `radius` = visible eye radius.
local function buildLid(head: BasePart, centre: Vector3, frontOffset: number, radius: number, skin: Color3, parent: Instance): { BasePart }
	local look = head.CFrame.LookVector
	local pos = centre + look * frontOffset
	local f = CFrame.lookAt(pos, pos + look, head.CFrame.UpVector)
	local parts = {}
	-- Disc facing forward (cylinder axis = local X -> rotate onto the look direction)
	local disc = mkPart("Eyelid", Vector3.new(0.02, radius * 2.06, radius * 2.06), f * CFrame.Angles(0, math.rad(90), 0), skin, Enum.PartType.Cylinder)
	table.insert(parts, disc)
	-- Lash line: a gentle downward curve "︶" — two strokes that meet cleanly in the middle.
	local len = radius * 0.9
	local ang = math.rad(14)
	for _, side in { -1, 1 } do
		local cx = side * math.cos(ang) * len / 2
		local cy = -radius * 0.12 + math.sin(ang) * len / 2
		local lash = mkPart("EyelidLash", Vector3.new(len, radius * 0.11, 0.012), f * CFrame.new(cx, cy, -0.013) * CFrame.Angles(0, 0, side * ang), INK)
		table.insert(parts, lash)
	end
	for _, p in parts do
		p.Parent = parent
		weld(head, p)
	end
	return parts
end

local function setup(model: Model)
	if rigs[model] then
		return
	end
	local head = model:WaitForChild("Head", 5) :: BasePart?
	if not head then
		return
	end
	local rig: Rig = { Model = model, Lids = {}, Conns = {}, NextBlink = os.clock() + 2, BlinkUntil = 0, PeekUntil = 0, NextPeek = os.clock() + 4 }
	rigs[model] = rig

	-- 1) Rig-provided eyelids
	local own = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Eyelid" then
			table.insert(own, d)
		end
	end
	if #own > 0 then
		for i, p in own do
			table.insert(rig.Lids, { Parts = { p }, Side = if i % 2 == 0 then 1 else -1 })
		end
	else
		-- 2) Generated lids (rebuilt when the server rescales her for a new Form)
		local function generate()
			local old = model:FindFirstChild("LocalEyelids")
			if old then
				old:Destroy()
			end
			table.clear(rig.Lids)
		local skin = head.Color
		local folder = Instance.new("Folder")
		folder.Name = "LocalEyelids"
		folder.Parent = model
		local whites = {}
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and d.Name:find("EyeWhite") then
				table.insert(whites, d)
			end
		end
		local look = head.CFrame.LookVector
		if #whites > 0 then
			-- Eye whites are forward-facing discs; the pupil ball pokes out in front of them.
			local pupilFront = 0.0
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") and d.Name == "Eye" then
					pupilFront = math.max(pupilFront, d.Size.X / 2)
				end
			end
			for _, w in whites do
				local radius = math.max(w.Size.Y, w.Size.Z) / 2
				local side = if head.CFrame:PointToObjectSpace(w.Position).X < 0 then -1 else 1
				table.insert(rig.Lids, { Parts = buildLid(head, w.Position, pupilFront + 0.035, radius, skin, folder), Side = side })
			end
		else
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") and d.Name == "Eye" then
					local radius = d.Size.X / 2
					local side = if head.CFrame:PointToObjectSpace(d.Position).X < 0 then -1 else 1
					table.insert(rig.Lids, { Parts = buildLid(head, d.Position, radius + 0.02, radius * 1.15, skin or SKIN_FALLBACK, folder), Side = side })
				end
			end
		end
		local _ = look
		end
		generate()
		local pending = false
		local function regen()
			if pending then
				return
			end
			pending = true
			task.delay(0.2, function()
				pending = false
				if rigs[model] then
					generate()
				end
			end)
		end
		-- Forms rescale her and tint her skin: keep the lids matching.
		table.insert(rig.Conns, head:GetPropertyChangedSignal("Size"):Connect(regen))
		table.insert(rig.Conns, head:GetPropertyChangedSignal("Color"):Connect(regen))
	end

	table.insert(rig.Conns, model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) then
			for _, c in rig.Conns do
				c:Disconnect()
			end
			rigs[model] = nil
		end
	end))
end

local function setLid(lid: Lid, closed: boolean)
	for _, p in lid.Parts do
		local want = if closed then 0 else 1
		if p.Transparency ~= want then
			p.Transparency = want
		end
	end
end

local function update()
	local t = os.clock()
	for model, rig in rigs do
		local state = model:GetAttribute("State")
		local closedL, closedR = false, false
		if state == "Asleep" then
			closedL, closedR = true, true
		elseif state == "FakeSleep" then
			-- Looks asleep... except the right eye creeps open for a moment every few seconds.
			closedL, closedR = true, true
			if t > rig.NextPeek then
				rig.PeekUntil = t + 0.9
				rig.NextPeek = t + 3.5 + math.random() * 3
			end
			if t < rig.PeekUntil then
				closedR = false
			end
		elseif state == "Stirring" then
			local flutter = math.sin(t * 9) > 0.35
			closedL, closedR = flutter, flutter
		elseif state == "Chasing" or state == "Attacking" or state == "Waking" then
			closedL, closedR = false, false -- wide open. no blinking.
		else
			if t > rig.NextBlink then
				rig.BlinkUntil = t + 0.13
				rig.NextBlink = t + 2.5 + math.random() * 3.5
			end
			local blink = t < rig.BlinkUntil
			closedL, closedR = blink, blink
		end
		for _, lid in rig.Lids do
			setLid(lid, if lid.Side < 0 then closedL else closedR)
		end
	end
end

function GrandmaEyesController.Preload() end

function GrandmaEyesController:Start()
	CollectionService:GetInstanceAddedSignal("Grandma"):Connect(function(m)
		if m:IsA("Model") then
			task.spawn(setup, m)
		end
	end)
	for _, m in CollectionService:GetTagged("Grandma") do
		if m:IsA("Model") then
			task.spawn(setup, m)
		end
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 1 / 20 then -- 20 Hz is plenty for blinks
			acc = 0
			update()
		end
	end)
end

return GrandmaEyesController
