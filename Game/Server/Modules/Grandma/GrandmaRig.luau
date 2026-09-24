--!strict
-- GrandmaRig
-- Picks and loads a Grandma rig from ReplicatedStorage.<GrandmaConfig.RigFolder> (random,
-- weighted, respecting per-rig MinNight) and applies a visual Form to it.
-- This is the ONLY place that knows anything about the rig's structure, and it only relies
-- on: Humanoid, HumanoidRootPart, Head, and optionally parts named "Eye" and parts with
-- attribute Skin = true (tinted per form). Swap or add rigs freely.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local GrandmaConfig = shared("GrandmaConfig")
local GameConfig = shared("GameConfig")

local GrandmaRig = {}

export type Rig = {
	Model: Model,
	Humanoid: Humanoid,
	Root: BasePart,
	Head: BasePart,
	BaseScale: number,
	Template: Model,
	SpeedMult: number,
}

local rng = Random.new()

local function candidates(): { Model }
	local out = {}
	local folder = ReplicatedStorage:FindFirstChild(GrandmaConfig.RigFolder)
		-- legacy location, kept so old places still work
		or ServerStorage:FindFirstChild("GrandmaRigs")
	if folder then
		for _, m in folder:GetChildren() do
			if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") and m:FindFirstChild("HumanoidRootPart") then
				table.insert(out, m)
			end
		end
	end
	return out
end

-- Weighted random pick among rigs eligible for this night.
function GrandmaRig.Pick(night: number, exclude: Model?): Model?
	local pool, total = {}, 0
	for _, m in candidates() do
		local minNight = tonumber(m:GetAttribute("MinNight")) or 1
		if night >= minNight and (m ~= exclude or #candidates() == 1) then
			local w = math.max(0, tonumber(m:GetAttribute("Weight")) or 1)
			if w > 0 then
				table.insert(pool, { m, w })
				total += w
			end
		end
	end
	if total <= 0 then
		local all = candidates()
		for _, m in all do
			if m.Name == GrandmaConfig.RigName then
				return m
			end
		end
		return all[1]
	end
	local r = rng:NextNumber() * total
	for _, e in pool do
		r -= e[2]
		if r <= 0 then
			return e[1]
		end
	end
	return pool[#pool][1]
end

function GrandmaRig.Load(parent: Instance, template: Model?): Rig
	template = template or GrandmaRig.Pick(1)
	assert(template, `[GrandmaRig] no rigs in ReplicatedStorage.{GrandmaConfig.RigFolder}`)

	local model = (template :: Model):Clone()
	model.Name = "Grandma"
	model:SetAttribute("RigName", (template :: Model).Name)
	model:SetAttribute("DisplayName", (template :: Model):GetAttribute("DisplayName") or "Grandma")
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local head = model:FindFirstChild("Head") :: BasePart
	assert(humanoid and root and head, "[GrandmaRig] rig needs Humanoid, HumanoidRootPart and Head")

	model.PrimaryPart = root
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge
	humanoid.AutoRotate = true
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	if not humanoid:FindFirstChildOfClass("Animator") then
		Instance.new("Animator").Parent = humanoid
	end

	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CollisionGroup = GameConfig.CollisionGroups.Grandma
			d.CanTouch = false
			d:SetAttribute("BaseColor", d.Color)
		elseif d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy() -- rigs never carry their own logic
		end
	end
	CollectionService:AddTag(model, "Grandma")
	model.Parent = parent
	pcall(root.SetNetworkOwner, root, nil)

	return {
		Model = model,
		Humanoid = humanoid,
		Root = root,
		Head = head,
		BaseScale = model:GetScale(),
		Template = template :: Model,
		SpeedMult = tonumber((template :: Model):GetAttribute("SpeedMult")) or 1,
	}
end

-- ------------------------------------------------------------------ outfits

local function slotFor(part: BasePart): string?
	local attr = part:GetAttribute("OutfitSlot")
	if typeof(attr) == "string" then
		return attr
	end
	for slot, patterns in GrandmaConfig.OutfitParts or {} do
		for _, pat in patterns do
			if part.Name:find(pat) then
				return slot
			end
		end
	end
	return nil
end

-- Pick tonight's outfit: eligible for the night, never the same as last night.
function GrandmaRig.PickOutfit(night: number, previous: string?): any
	local pool, total = {}, 0
	for _, o in GrandmaConfig.Outfits or {} do
		local ok
		if o.Nights then
			ok = table.find(o.Nights, night) ~= nil
		else
			ok = night >= (o.MinNight or 1) and night <= (o.MaxNight or 30)
		end
		if ok and (o.Name ~= previous) then
			table.insert(pool, o)
			total += o.Weight or 1
		end
	end
	if #pool == 0 then
		return nil
	end
	local r = rng:NextNumber() * total
	for _, o in pool do
		r -= o.Weight or 1
		if r <= 0 then
			return o
		end
	end
	return pool[#pool]
end

function GrandmaRig.ApplyOutfit(rig: Rig, outfit: any)
	if not outfit then
		return
	end
	local counters: { [string]: number } = {}
	local ink = Color3.fromRGB(42, 26, 36)
	for _, d in rig.Model:GetDescendants() do
		if d:IsA("BasePart") and not d:GetAttribute("Skin") then
			local slot = slotFor(d)
			if slot then
				local value = outfit[slot]
				if slot == "DressShade" and value == nil and outfit.Dress then
					value = (outfit.Dress :: Color3):Lerp(ink, 0.18)
				end
				if typeof(value) == "table" then
					counters[slot] = (counters[slot] or 0) + 1
					value = value[((counters[slot] - 1) % #value) + 1]
				end
				if typeof(value) == "Color3" then
					d.Color = value
					d:SetAttribute("BaseColor", value)
				end
				if outfit.Material and (slot == "Dress" or slot == "DressShade" or slot == "DressTrim") then
					d.Material = outfit.Material
				end
			end
		end
	end
	rig.Model:SetAttribute("Outfit", outfit.Name)
end

function GrandmaRig.ApplyForm(rig: Rig, formKey: string)
	local form = GrandmaConfig.Forms[formKey] or GrandmaConfig.Forms.Normal
	local target = rig.BaseScale * form.Scale
	if math.abs(rig.Model:GetScale() - target) > 0.001 then
		rig.Model:ScaleTo(target)
	end
	for _, d in rig.Model:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "Eye" then
				d.Color = form.EyeColor
				d.Material = if form.EyeGlow > 0 then Enum.Material.Neon else Enum.Material.SmoothPlastic
				local light = d:FindFirstChildOfClass("PointLight")
				if form.EyeGlow > 0 then
					if not light then
						light = Instance.new("PointLight")
						light.Range = 6
						light.Shadows = false
						light.Parent = d
					end
					light.Color = form.EyeColor
					light.Brightness = form.EyeGlow
				elseif light then
					light:Destroy()
				end
			elseif d:GetAttribute("Skin") then
				local base = d:GetAttribute("BaseColor") :: Color3
				d.Color = if form.SkinTint then base:Lerp(form.SkinTint, 0.65) else base
			end
		end
	end
	rig.Model:SetAttribute("Form", formKey)
end

return GrandmaRig
