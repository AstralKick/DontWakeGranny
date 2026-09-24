-- BackGarden 07: in-place fixes found by map_backgarden_audit (the builder files 00..06 already contain
-- the same changes, so a full rebuild does not need this; running it twice is harmless).
local B = _G.BGB
local C, M = B.C, B.M
local V = Vector3.new
local cf = B.cf
local SM = { small = true }
local root = B.root()
local O = V(B.OX, 0, 0)
local log = {}
local function L(v) return v - O end
local P = root.Ground.BackPorch
-- 1. porch: no battens / deck edge behind the step treads; piers closing the under-porch hiding bay
for _, d in P:GetChildren() do
	if d.Name == "Batten" then
		local x = L(d.Position).X
		if (x > -9.6 and x < 1.6) or (x > 17.4 and x < 28.6) then d:Destroy() end
	elseif d.Name == "DeckEdge" and d.Size.X > 60 then
		d:Destroy()
		for _, seg in { { -33, -9.3 }, { 1.3, 17.7 }, { 28.3, 29.2 } } do
			B.box(P, "DeckEdge", seg[1], 2.5, 45.8, seg[2], 2.9, 46, C.WoodDark, M.Wood, SM)
		end
		table.insert(log, "deck edge split")
	end
end
if not P:FindFirstChild("Pier") then
	local skirtC = C.WoodDark:Lerp(C.Paper, 0.1)
	for _, x in { -17.2, -11.1 } do B.box(P, "Pier", x, 0, 46.3, x + 0.3, 2.6, 59.7, skirtC, M.WoodPlanks, { solid = true }) end
	B.box(P, "Pier", -16.9, 0, 56.4, -11.1, 2.6, 56.7, skirtC, M.WoodPlanks, { solid = true })
	table.insert(log, "porch piers")
end
-- 2. fuse box clear of the window frame
local fb = root.FuseBox
if math.abs(L(fb.Position).X + 24) < 0.1 then
	for _, d in { fb, P.Conduit, P.FuseLever, P.FuseLabel } do d.Position += V(3.4, 0, 0) end
	table.insert(log, "fuse box moved")
end
-- 3. lamps: out of the outhouse door swing, hung from a rafter / tie beams
local function moveLamp(model, newBase)
	local bulb = model:FindFirstChild("Bulb")
	local cord = model:FindFirstChild("Cord")
	local top = cord.Position + V(0, cord.Size.X / 2, 0) -- vertical cylinder: length along X
	local delta = (O + newBase) - top
	for _, d in model:GetDescendants() do if d:IsA("BasePart") then d.Position += delta end end
	local _ = bulb
end
for _, lm in root.Ground.Orchard.Outhouse:GetChildren() do
	if lm.Name == "Lamp_bare" and math.abs(L(lm.Bulb.Position).X + 72.5) < 0.1 then moveLamp(lm, V(-74.6, 9.2, 56)) table.insert(log, "outhouse lamp") end
end
for _, lm in root.Upstairs.OrchidHouse:GetChildren() do
	if lm.Name == "Lamp_bare" and math.abs(L(lm.Bulb.Position).X - 56) < 0.1 then moveLamp(lm, V(58, 12.45, 6)) table.insert(log, "orchid lamp") end
end
for _, lm in root.Basement.PottingRoom:GetChildren() do
	if lm.Name == "Lamp_bare" then
		local z = lm.Bulb.Position.Z
		if math.abs(z + 12) < 0.1 then moveLamp(lm, V(-58, 9.6, -8.8)) table.insert(log, "shed lamp S") end
		if math.abs(z - 8) < 0.1 then moveLamp(lm, V(-58, 9.6, 6.8)) table.insert(log, "shed lamp N") end
	end
end
-- 4. shed: partition gable (closes the roof space) and the tool-room floor not under the partition
local SH = root.Basement.PottingShed
if not SH:FindFirstChild("PartitionGable") then
	B.box(SH, "PartitionGable", -66.25, 10, -15.5, -65.75, 14, 13.5, C.WMint:Lerp(C.Ink, 0.45):Lerp(C.Paper, 0.08), M.WoodPlanks, { solid = true })
	table.insert(log, "partition gable")
end
for _, d in SH:GetChildren() do
	if d.Name == "Floor" and math.abs(L(d.Position).X + (76.5 + 65.75) / 2) < 0.01 then
		d.Size = V(76.5 - 66.25, d.Size.Y, d.Size.Z)
		d.Position = V(O.X - (76.5 + 66.25) / 2, d.Position.Y, d.Position.Z)
		table.insert(log, "tool floor trimmed")
	end
end
-- 5. wardrobes: inset plinth (no coplanar faces with sides/back) + meeting stile over the leaf seam
for _, m in root:GetDescendants() do
	if m:IsA("Model") and m:FindFirstChild("DoorLeaf") and m:FindFirstChild("Plinth") and not m:FindFirstChild("MeetingStile") then
		local pl, back = m.Plinth, m.Back
		local fwd = back.CFrame.LookVector
		local w, d = back.Size.X, m.Side.Size.Z
		pl.Size = V(w - 0.62, pl.Size.Y, d - 0.3)
		pl.CFrame = pl.CFrame + fwd * 0.15 -- front stays flush, back edge meets the back panel
		local leaves = {}
		for _, c in m:GetChildren() do if c.Name == "DoorLeaf" then table.insert(leaves, c) end end
		local mid = (leaves[1].Position + leaves[2].Position) / 2
		B.part(m, "MeetingStile", V(0.3, leaves[1].Size.Y, 0.06), (B.SH:Inverse() * CFrame.lookAt(mid, mid + fwd)) * CFrame.new(0, 0, -(leaves[1].Size.Z / 2 + 0.03)), leaves[1].Color:Lerp(C.Ink, 0.15), M.Wood, SM)
		table.insert(log, "wardrobe " .. m.Name)
	end
end
-- 6. corruption: the rose-gate eye moved off the gate swing, the empty rocker on the ground
local L3 = root.Corruption["3"]
local movedEye = false
for _, e in L3:GetChildren() do
	if e.Name == "Eye" and math.abs(L(e.Position).X - 28.97) < 0.1 then e:Destroy() movedEye = true end
end
if movedEye then
	local b = CFrame.lookAt(V(31.03, 6.2, 52), V(32.03, 6.2, 52))
	for _, sx in { -1, 1 } do
		B.part(L3, "Eye", V(0.28, 0.2, 0.05), b * CFrame.new(sx * 0.3, 0, 0), Color3.fromRGB(255, 70, 60), M.Neon, { small = true, collide = false, query = false })
	end
	table.insert(log, "eye moved")
end
local rk = L3:FindFirstChild("EmptyRocker")
if rk then for _, d in rk:GetChildren() do if d.Name == "Rocker" and d.Position.Y > 0.2 then d.Position -= V(0, 0.15, 0) end end end
-- 7. small clutter never casts shadows
local ns = 0
for _, d in root:GetDescendants() do
	if d:IsA("BasePart") and not d.CanCollide and d.Transparency < 1 and d.CastShadow and d.Size.Magnitude < 3 then d.CastShadow = false ns += 1 end
end
table.insert(log, "shadows off on " .. ns .. " clutter parts")
return table.concat(log, "\n")
