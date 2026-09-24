# DontWakeGranny — "31 Nights at Grandma's"

A Roblox game built with Rojo. Code syncs to two places in one universe: the Lobby (113809617295749) and Granny's House (82470107066597). Both places run the same codebase, and `ReplicatedStorage.Util.PlaceRole` decides which services run. `Workspace` art is built in Studio through the Roblox Studio MCP, and the builder scripts live in `tools/`.

Framework: VIDK (a git submodule). Its loader auto-starts every ModuleScript in `ServerStorage.Modules` and `ReplicatedStorage.Modules` (`Preload`, `Start`, `InitProfile`), and modules are found with `shared("Name")`. Persistent data goes through VIDK SMProfile (ProfileStore), Candy through SMCurrency (`SoftCurrency`), and friends through SMSocial.

## Required reading
- Game overview and architecture → [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md)
- Map names, tags and attributes the code relies on → [docs/MAP_CONTRACT.md](docs/MAP_CONTRACT.md)
- Remotes, attributes and data keys between client and server → [docs/CLIENT_CONTRACT.md](docs/CLIENT_CONTRACT.md)
- **Building the map, rooms or props** → read [docs/ART_BUILDING.md](docs/ART_BUILDING.md) first (Parts, CSG, Toolbox vetting, organization).
- **Building or changing any UI** → read [docs/UI_STYLE.md](docs/UI_STYLE.md) first (creepy-but-bubbly style, anti-"AI look" rules, Mobile/PC/Console scaling).
- Things only a human can do (IDs, publishing, audio) → [docs/DEVELOPER_TODO.md](docs/DEVELOPER_TODO.md)

## Conventions
- All tuning and every external ID lives in `Game/Config`. Never hard-code IDs in scripts.
- The server is authoritative. Clients send intent only; validate and rate-limit every remote with `Net.RateLimit`.
- Syntax check in Studio (Edit mode): run `loadstring(module.Source)` over the synced modules with execute_luau.
