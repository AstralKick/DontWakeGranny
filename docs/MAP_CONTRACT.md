# Map Contract

The code finds map objects **only** through the names, tags (CollectionService) and attributes listed here. Anything not listed is free decoration. Builders must follow this contract exactly, and coders must not depend on anything outside it.

General rules for both places:
- Everything is **Anchored**.
- Invisible helper parts (volumes, spawns, nodes): `Transparency = 1`, `CanCollide = false`, `CanQuery = false`, `CanTouch = false`, unless a rule below says otherwise.
- Pure decor: `CanTouch = false`, `CanQuery = false`, `CastShadow = false` on small clutter.
- Players **cannot jump**. Every walkable height change needs a ramp: visible steps plus an invisible collidable `WedgePart` ramp, slope ≤ 35°.
- Scale: a character is about 5 studs tall. Doorways are 4.5 wide × 8 tall. Ceilings are 12. Hallways are ≥ 7 wide (Grandma's pathing radius is 1.6).

---

## Granny's House place → `Workspace.House` (Model or Folder)

| Path / tag | Type | Attributes | Notes |
|---|---|---|---|
| `House.PlayerSpawns` | Folder of ≥5 Parts | — | Front yard beside Mom's car, facing the front door |
| `House.MomsCar` | Model | — | Parked in the driveway. Must contain a BasePart named **`Trunk`** at the rear (the bank point; the service adds the prompt) |
| `House.Rooms` | Folder of box Parts (axis-aligned, invisible) | `RoomName` (display string), `Area` (`Ground`/`Upstairs`/`Basement`/`Attic`), `Danger` (1–3) | Each covers one room interior, floor to ceiling. "Inside the house" = inside any Room box. Hallways and stairwells are rooms too |
| `House.LootSpawns` | Folder of small invisible Parts | `Area`, `Danger` | Loot rests at the part's position. Put them just above surfaces (tables, shelves, counters, nightstands). ~80 total |
| `House.PrizeSpawns` | Folder of Parts | `Area` | ≥6, in the most dangerous spots (next to Grandma's chair, her bedroom nightstand, basement shrine, attic trunk…) |
| tag **`Searchable`** | BasePart (drawer front, cabinet door, fridge door, chest lid…) | `Kind` (`Drawer`/`Cabinet`/`Fridge`/`ToyChest`/`Vanity`/`Trunk`), `Area`, `Danger` | ~30. Loot pops out in front of the part (its `CFrame.LookVector` side) |
| tag **`Door`** | Model: `Hinge` (invisible part on the hinge edge, **PrimaryPart**), `Panel` (door leaf, collidable), optional knob parts | `Area`, `Squeaky` (bool), `Lockable` (bool) | Closed by default. The service swings the model's pivot ±90° around Hinge Y. `Panel` contains a `PathfindingModifier` with `PassThrough = true`. The front door model is named **`FrontDoor`** |
| tag **`HidingSpot`** | Model: `Inside` (invisible; where the HumanoidRootPart goes, facing out), `Front` (invisible, on the floor where Grandma stands to check), `Exit` (invisible, where the player is placed on exit) | `Kind` (`Wardrobe`/`Bed`/`Closet`/`Cabinet`), `Area` | ~14 across all areas. Wardrobes/closets need a door leaf that looks closed |
| tag **`Creaky`** | Part (a floor plank patch ~4×0.2×4, slightly lighter wood, flush with the floor, CanCollide + CanTouch true) | — | ~20, mostly in hallways and around Grandma's chair. Visible to observant players |
| tag **`Breakable`** | Part, or Model with a PrimaryPart (CanTouch + CanCollide true) | — | Vases and plate stacks where people run (hall tables, corners). ~10 |
| tag **`Lamp`** | Part or Model containing a PointLight/SpotLight/SurfaceLight, plus a part named `Bulb` (Neon) | `Area` | The house's practical lights. The service toggles and flickers them |
| `House.SearchNodes` | Folder of invisible floor Parts | `Area`; exactly one with `Bathroom = true` in the ground-floor bathroom | ~40 across rooms and hallways. Grandma's search/patrol points |
| `House.GrandmaSleepSpot` | Part (invisible) | — | Where Grandma's HumanoidRootPart sits in her armchair (Living Room). LookVector = the way she faces. The armchair model next to it is named `GrandmaChair` |
| `House.Barriers` | Folder of Parts/Models | `Area` (`Upstairs`/`Basement`/`Attic`) | Collidable boards/doors blocking each locked area. The service hides them when the area unlocks |
| `House.FuseBox` | Part | — | Ground floor (laundry/kitchen). Restores power |
| `House.PumpkinSpots` | Folder of 5 Parts | `Area` | Night 31 jack-o'-lantern placements, at least one per area |
| `House.Corruption` | Folder with subfolders `1`,`2`,`3`,`4` | — | Decor that should only exist at corruption ≥ N (the service shows/hides it) |

### Multiple maps (chapters)
The run has 6 maps, one per chapter (see `Game/Config/MapConfig.luau`). **Every map follows this exact House contract**; the only differences:
- **Container:** the original house stays at `Workspace.House` (MapId `GrandmasHouse`). Every other map is a Model at `Workspace.Maps.<MapId>`, built far from the others: X offset = 1500 × chapter index (BackGarden 1500, SunnyPines 3000, StMildreds 4500, HarvestFair 6000, NightmareHouse 7500), at the same Y as the house. Z is around 0.
- **Model attributes:**
  - `MapId` (string)
  - `DisplayName` (string)
  - optional `AreaName_Upstairs` / `AreaName_Basement` / `AreaName_Attic` (display names for the zones)
- **Zones:** the Area names stay `Ground` / `Upstairs` / `Basement` / `Attic`, but in a non-house map they're just zones 1–4 (e.g. Garden: Upstairs = the greenhouse). They unlock on nights 2, 3 and 4 of the chapter, and each locked zone needs a Barrier.
- **Runtime:** MapService moves the inactive maps to ServerStorage and renames the active one to `House` in Workspace. Nothing may depend on world coordinates.
- **Pumpkins:** `PumpkinSpots` (5) are only required in `NightmareHouse` (the Night 31 finale lives there).

Areas unlock by night of the chapter (see MapConfig). Grandma's House: Ground (1), Upstairs (3), Basement (4), Attic (5). Rooms in a locked area must be unreachable because of the Barriers.

The front yard is fenced (no exit to the void). There's grass or terrain ground and a night sky. `Lighting` is overridden at runtime by EnvironmentService, so the builder only sets a sensible base look for editing.

---

## Lobby place → `Workspace.Lobby` (Folder)

| Path / tag | Type | Notes |
|---|---|---|
| `Lobby.Spawn` | SpawnLocation(s) | `Neutral = true`, decal removed |
| `Lobby.Cars` | Folder of 3 Models `Car1`,`Car2`,`Car3` | Minivans. Each has a PrimaryPart plus: `QueueZone` (Part at the open sliding door; CanCollide false, CanTouch true, subtle see-through glow), `Seats` (Folder with 5 `Seat` parts `Seat1`..`Seat5` inside the car), `Exit` (invisible part beside the door), `Display` (invisible part ~2 studs above the roof). **All parts inside the model, all anchored** (the car moves via PivotTo when it departs; it drives 70 studs along its −Z/LookVector, so leave that road clear) |
| `Lobby.Leaderboard` | Part (~12×8) | Front face shows the "Most Nights Survived" board (the client builds the SurfaceGui from the part's attribute `Rows`) |
| `ProximityPrompt` with attribute **`Menu`** | inside a Part | `Menu` = `Shop` / `Daily` / `Cosmetics` / `Diary` / `Quests`. The client opens that menu when the prompt fires. Mailbox → Daily, candy stand on the porch → Shop, coat rack → Cosmetics, diary on a pedestal → Diary, chore list board → Quests |
