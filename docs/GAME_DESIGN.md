# 31 Nights at Grandma's — Design & Architecture

> Get stuff. Don't make noise. Don't wake Grandma. Survive.

This is the working design doc for the team. Tuning numbers live in `Game/Config`, not here.

## Places
| Place | PlaceId | Role |
|---|---|---|
| Lobby | 113809617295749 | Suburban street on Halloween eve. Mom's minivans are the matchmaking queues. Shop, mailbox (daily reward), leaderboard. |
| Granny's House | 82470107066597 | Reserved server per party. The whole 31-night run happens here. |

Both places sync the **same Rojo project**. `ReplicatedStorage.Util.PlaceRole` decides which services run (see `Game/Config/PlaceConfig.luau`). In Studio, pressing Play in Granny's House starts a solo run immediately (debug start night = `workspace:GetAttribute("DebugStartNight")`).

## Core loop
ENTER → EXPLORE → LOOT → RISK → NOISE → GRANDMA REACTS → HIDE/RUN → SURVIVE TO 6 AM → BANK → NEXT NIGHT

* **Loot** goes into your pillowcase (limited slots). Carried loot is **lost if you're caught**.
- **Bank** loot at Mom's car trunk in the driveway, which turns it into Candy right away and keeps it safe. Surviving until 6 AM auto-banks what you're still carrying.
- Safer rooms have cheap loot. Grandma's rooms have the good stuff.
- **Each night has one Prize** (dentures, cookie jar, wedding ring…). It's big, heavy and noisy, and it's always in a dangerous spot.

## Noise (signature mechanic)
Noise events have loudness and a radius. Grandma's **Alert** meter (0–100) fills from noise, falloff by distance and walls.
- Crouch: silent. Walk: nearly silent. Sprint: loud footsteps.
- Creaky floorboards (slightly lighter planks) creak if you walk over them. Crouching reduces the creak.
- Searching containers, squeaky doors, lockpicking and grabbing loot make noise.
- Breakables (vases, plates) make huge noise if you bump into them.
- Anyone hanging around outside too long makes Grandma "sense" them.
- Feedback: world ripple at the source, a "!" over the noisy player's head for everyone, the Grandma-face alert meter, and sound.

## Grandma
State machine: `Asleep → Stirring → Searching → Chasing → Attacking → Returning`. Late-game adds `FakeSleep` and `Stalking`.
- Asleep: snores in her armchair. Noise fills Alert. Stirring gives you a 5-second window to go quiet.
- Searching: walks to the noise, looks around, checks nearby search nodes (and hiding spots on later nights).
- Chasing: she's seen you. Music, red grade, FOV punch and heartbeat all kick in. Break line of sight to lose her.
- Hiding: wardrobes, closets, under beds. If she saw you get in, she drags you out. If she checks your spot, you get a **Hold Your Breath** check. **No camping:** hide too long (75 s on Night 1, down to 30 s by Night 30) and she gets up, even from her chair, and walks straight to your spot. If you're still inside when she arrives she pulls you out, with no breath save. An AIR meter and warnings ("stuffy…", "she can smell you…", "SHE'S COMING FOR YOU") give you time to slip out.
- Doors block her sight. She opens them in about 0.5 s, which is enough time to slam one in her face.

Abilities unlock by night (see `NightConfig`): hears doors (N6), reacts to flashlights (N11), checks hiding spots and learns favourite spots (N16), locks doors (N18), stalks outside rooms (N20), cuts the power (N21), fake sleep (N23), appears unexpectedly (N24), Nightmare form (N26).

## 31 nights
| Nights | Beat | New |
|---|---|---|
| 1–5 | "Haha, creepy Grandma." | Ground floor. Night 1 has a scripted "bathroom break" so she gets up within ~45 s. |
| 6–10 | NEW AREA: UPSTAIRS | Hears doors, bedroom loot |
| 11–15 | NEW AREA: BASEMENT | Flashlight reactions; the house starts to rot (corruption 1–2) |
| 16–20 | NEW AREA: ATTIC | She checks hiding spots, learns them, locks doors, stalks |
| 21–25 | Reality breaks | Cuts power, fake sleeps, teleports; corruption 3 |
| 26–30 | Nightmare Grandma | New form, faster, red house (corruption 4) |
| 31 | **HALLOWEEN NIGHT** | She never sleeps. Light 5 jack-o'-lanterns around the house, then escape to Mom's car. |

**Checkpoints** are at Nights 1/6/11/16/21/26. The party leader can start the car at any checkpoint they've unlocked.

## Random events
Rolled per night from Night 3, and never on milestone nights: Light Sleeper, Hard of Hearing, Power Outage, Blood Moon, Double Loot, Locked Doors, Already Awake, Cookie Night.

## Death, spectating, revives
Caught → jumpscare → death screen (shows what you lost) → spectate teammates. From the death screen you can Revive (Developer Product; your first revive ever is free) or Return to Lobby. If your team survives the night, you come back next night. **Lost loot is never restored.**
Team wipe → **Continue Run** (Developer Product, any one player can buy it for the whole team) restarts the night. Otherwise the run ends.

## Economy
Candy is the only currency. You earn it from banked loot, surviving nights, Prizes, daily mailbox, quests and friend bonuses. You spend it on permanent upgrades (pillowcase size, soft socks, strong lungs, better batteries), consumables (wind-up toy, cookie, fizzy soda) and cosmetics (flashlight tint, pillowcase pattern).

## Social
Friends-only car toggle (the first person in a car chooses). **Friend bonus**: +10% Candy per friend in your match (max +40%), plus a daily "Buddy Bonus". Referral: when an invited friend joins for the first time, both of you get Candy.

## Monetisation (moments, not menus)
Revive (death screen), Continue Run (team wipe), Sugar Rush (a server-wide 2× loot boost during intermission), Candy packs (shop), and Game Passes: VIP, Big Pillowcase, Starter Pack. All IDs are in `Game/Config/MonetizationConfig.luau`. A product with `Id = 0` is hidden in the UI.

## Architecture
```
Game/Config            -> ReplicatedStorage.Config     (all tuning + external IDs)
Game/Client/Util       -> ReplicatedStorage.Util       (shared libs: Net, PlaceRole, Format, Sfx)
Game/Client/UI         -> ReplicatedStorage.UI         (UI kit + screens)
Game/Client/Modules    -> ReplicatedStorage.Modules    (client controllers, auto-started)
Game/Server/Modules    -> ServerStorage.Modules        (server services, auto-started; subfolders = libraries)
```
Services and controllers follow the VIDK loader contract: `Preload()`, `Start()`, and optionally `InitProfile(player, replicas)`. Look modules up with `shared("Name")`, and keep names unique.

Server authority: loot, banking, Candy, noise, Grandma, deaths, revives and purchases are all server-side. Clients send only intent (sprint, crouch, flashlight, use item, spectate, UI purchases), and every remote is validated and rate-limited.

Match state replicates through attributes on `ReplicatedStorage.MatchState` and on each `Player`. Grandma's state is an attribute on her model, and each client animates her locally (`GrandmaAnimController`).

## Testing in Studio
- Press Play in **Granny's House** to start a solo run straight away. Teleports don't work in Studio, so Mom's Car in the Lobby shows a notice instead of departing.
- These Workspace attributes are Studio-only (`DebugService`): `DebugStartNight` (1–31), `DebugEvent` (EventConfig key), `DebugNoCatch` (true = Grandma can't catch you), `DebugCampLimit` (seconds of hiding before she comes for you; default GrandmaConfig.AI.CampLimit).
- Setting `workspace:SetAttribute("DebugCmd", "<cmd>")` from the server command bar runs one of: `wake`, `chase`, `checkhide`, `noise 40`, `endnight`, `power`.
- Compile-check everything in Edit mode by running `loadstring(module.Source)` over the synced modules with execute_luau.
