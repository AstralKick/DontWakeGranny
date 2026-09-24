# Building Art & Environments

How to build the world (house, rooms, props) for **Don't Wake Granny**. Read this before any "build the map / room / prop" task.

The Rojo project only syncs code (`ReplicatedStorage`, `ServerStorage`, `ServerScriptService`, `StarterPlayer`). **`Workspace` is not Rojo-managed**, so all art is built directly in Studio via the Roblox Studio MCP (`execute_luau`, `insert_asset`, etc.) and saved in the place file.

There are three tools for making art. Mix them freely:

| Tool | Use it for | Avoid it for |
|---|---|---|
| **Parts** | Walls, floors, ceilings, stairs, simple furniture, blockouts, anything that needs to be cheap | Organic or curved detail |
| **CSG** (Union / Subtract / Intersect) | Door and window holes, arches, rounded furniture, hollow shapes, trims, custom silhouettes built from primitives | Huge high-detail objects (triangle cost), anything a Toolbox mesh does better |
| **Toolbox assets** | Detailed props (lamps, clocks, beds, toys, plants), characters, anything organic | Structural geometry, anything you can't vet |

Also available: the MCP generation tools (`generate_mesh`, `generate_procedural_model`, `generate_material`, `generate_texture`) for custom props or surfaces when neither the Toolbox nor CSG gives a good result.

---

## 1. Parts

Primitives:
- `Part` with `Shape` = `Block`, `Ball`, `Cylinder`, `Wedge`, `CornerWedge`
- `WedgePart`, `CornerWedgePart` (the same shapes as classes; handy for roofs and ramps)
- `TrussPart` (ladders/scaffolding; **can't be used in CSG**)

Things to watch:
- A **Cylinder's length runs along its X axis**. Rotate it 90° on Z to stand it up.
- Always set `Anchored = true` for static geometry.
- Use `Material` + `Color` first. Add `MaterialVariant`, `Texture` or `Decal` when you need more.
- Snap sizes to a grid (0.05 / 0.1 / 0.25 studs) so edges line up and nothing Z-fights. Overlapping coplanar faces flicker.

Scale reference: a character is about 5 studs tall. Doors are 4 × 7.5, ceilings 12–14, walls 0.5–1 thick. **Granny's house should feel slightly too big and too cramped at once**: tall ceilings, narrow halls.

```lua
local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do p[k] = v end
	return p
end

local floor = part({
	Name = "Floor", Size = Vector3.new(40, 1, 30), CFrame = CFrame.new(0, 0, 0),
	Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(110, 78, 56),
	Parent = workspace.Map.House.LivingRoom,
})
```

---

## 2. CSG (Constructive Solid Geometry)

CSG combines parts into one solid (`UnionOperation`, `IntersectOperation`).

| Operation | Result | Typical use |
|---|---|---|
| **Union** | Merges parts into one shape | Rounded table (cylinder + blocks), bathtub body, picture frame |
| **Subtract** (Negate) | Cuts the tool parts out of the target | Door and window holes, sink basins, keyholes, drawer recesses, arches |
| **Intersect** | Keeps only the overlap | Rounded/beveled corners, lens shapes, domes (ball ∩ block) |

### Preferred API: `GeometryService` (works from `execute_luau` in edit mode)

```lua
local GeometryService = game:GetService("GeometryService")

-- Cut a doorway into a wall
local wall = workspace.Map.House.Hallway.Wall_A
local cutter = Instance.new("Part")
cutter.Size = Vector3.new(4, 7.5, wall.Size.Z + 1) -- deeper than the wall so it cuts cleanly
cutter.CFrame = wall.CFrame * CFrame.new(0, -wall.Size.Y / 2 + 3.75, 0)
cutter.Anchored = true

local results = GeometryService:SubtractAsync(wall, { cutter }, {
	CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition, -- players walk through it
	RenderFidelity = Enum.RenderFidelity.Automatic,
	SplitApart = false,
})

local union = results[1]
union.Name = wall.Name
union.Anchored = true
union.Parent = wall.Parent   -- results come back UNPARENTED
wall:Destroy()
cutter:Destroy()
```

Also available: `GeometryService:UnionAsync(part, tools, options)` and `GeometryService:IntersectAsync(part, tools, options)`. They take the same options and return an array of parts.

Legacy API (still works): `part:UnionAsync({...})`, `part:SubtractAsync({...})`, `part:IntersectAsync({...})`. Each returns one unparented operation.

### CSG rules & gotchas
- **Only `Part`, `WedgePart`, `CornerWedgePart` and existing unions/intersects can go in.** MeshParts and TrussParts can't.
- All CSG calls **yield**, so wrap them in `pcall`. They fail if the result exceeds the triangle limit or is otherwise invalid.
- **Cutters must fully pass through** the target (oversize them a little), or you get paper-thin skins.
- Color: `UsePartColor = true` gives the whole union one `Color`. Leave it `false` to keep each input part's color and material.
- **Collision fidelity**:
  - `Box` for decor nobody walks into (cheapest)
  - `Hull` for simple convex props
  - `PreciseConvexDecomposition` only for doorways, arches and anything players move through or hide inside
- Keep unions simple. Many unions of small unions add triangles fast. Balls and cylinders are the most expensive inputs.
- Don't union things that need to move independently (drawers, doors, cabinet lids). Keep those as separate parts or unions inside a Model with a `PrimaryPart`.
- Save the pre-CSG parts in `ServerStorage/ArtSource/<name>` when an object may need to be re-cut later.

### Useful CSG recipes
- **Doorway / window**: subtract a block from a wall (see the code above). Add a separate frame made of 3 thin parts.
- **Arch**: subtract (block + cylinder on top) from the wall.
- **Rounded tabletop**: intersect a thin block with a big flat cylinder, or union a block with 4 cylinders at the corners.
- **Sink / tub / bowl**: subtract a slightly smaller block or ball from a block or ball.
- **Beveled edge**: subtract rotated wedges from the edges.
- **Hollow pipe / lampshade**: subtract a thinner cylinder from a cylinder.

---

## 3. Toolbox assets (cherry-picking)

Use `search_asset` → `insert_asset` via the MCP.

**Every Toolbox insert must be vetted before it stays in the place:**

1. **Delete every `Script`, `LocalScript` and `ModuleScript`** inside the asset unless it's known-safe. Free models are a common source of backdoors (`require(<id>)`, `getfenv`, `loadstring`, obfuscated strings).
2. Check the **triangle/part count**. Reject props that are extremely heavy for their on-screen size.
3. **Scale** with `Model:ScaleTo(n)` to match the character scale above.
4. **Normalize** it:
   - `Anchored = true`
   - Decor collision set to `Box`/`Hull`, or `CanCollide = false` when it's tiny
   - `CanTouch = false` and `CanQuery = false` on pure decor
   - `CastShadow = false` on small clutter
5. **Restyle** colors and materials to match the house palette, so the Toolbox pieces don't look like a mismatched kit.
6. Rename it clearly (e.g. `Prop_GrandfatherClock`) and put it in the correct room folder.

Prefer assets from reputable creators with simple hierarchies. Don't use models that bundle their own lighting, sounds or GUIs.

---

## 4. Organization & performance

```
Workspace
└─ Map
   ├─ House
   │  ├─ LivingRoom   (Structure / Props / Lights)
   │  ├─ Kitchen
   │  ├─ GrannyBedroom
   │  └─ ...
   ├─ Exterior
   └─ Interactables   (anything code touches: doors, drawers, hiding spots, pickups)
```

- **Anything gameplay code references goes in `Interactables`** with a stable name and/or a `CollectionService` tag (e.g. `Door`, `HidingSpot`, `Pickup`). Code should look things up by tag, not by walking the decor tree.
- Group each prop as a `Model` with a `PrimaryPart`.
- Lighting: use `PointLight` / `SpotLight` in lamps, set `Shadows` only on the few lights that matter, and use `Future` lighting technology for the horror mood.
- Keep StreamingEnabled-friendly: no giant single unions spanning multiple rooms.
- Check the result with `screen_capture` after building, and fix any floating props, Z-fighting or gaps.

## 5. Build workflow

1. **Blockout** the room with plain parts (correct scale, doors, hiding spots, sightlines for Granny's patrol).
2. Replace structure with **CSG** where it needs cutouts or shape (doorways, arches, trims).
3. Dress it with **Toolbox props** (vetted) plus custom part/CSG furniture.
4. Apply materials, colors and lighting.
5. Tag interactables and verify with `screen_capture` and a quick playtest (`start_stop_play`).
