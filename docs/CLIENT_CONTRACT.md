# Client ⇄ Server Contract

The server is authoritative. Clients render state and send **intent** only.
Remotes live in `ReplicatedStorage.Remotes`. Get them with `shared("Net").Event(name)`, `.Function(name)` or `.Unreliable(name)`; on the client these wait for the remote to exist.
Client-local wiring goes through `shared("ClientBus")` (see `Game/Client/Util/ClientBus.luau`).
Persistent data is read with `shared("DataController")` (`Get(key)`, `GetCandy()`, `.Changed`).
The place role is `shared("PlaceRole")` (`IsLobby` / `IsMatch`).

## Match state — `ReplicatedStorage.MatchState` (Folder attributes, Match place only)
| Attribute | Meaning |
|---|---|
| `Phase` | `Waiting` · `Intro` (title card, 4 s) · `Night` · `Morning` (summary, 14 s) · `GameOver` (Continue window) · `Victory` · `Ended` |
| `Night`, `Title`, `Subtitle`, `NewArea` ("" or e.g. "UPSTAIRS"), `Duration` | Current night card data |
| `MapId`, `MapName`, `Chapter` | Active chapter map (MapConfig), e.g. "SunnyPines" / "Sunny Pines Retirement Home" |
| `NightStart`, `NightEnd` | `workspace:GetServerTimeNow()` timestamps. The clock runs 12:00 AM → 6:00 AM (use `Format.Clock(frac, 0, 6)`) |
| `Event` | EventConfig key or "" (the title/blurb/color come from `Config/EventConfig`) |
| `GrandmaState` | `Asleep` `FakeSleep` `Stirring` `Waking` `Searching` `Patrolling` `Returning` `Chasing` `Attacking` `CheckingHiding` `Stalking` `Distracted` |
| `Alert` | 0–100 (it's 100 whenever she's awake) |
| `Form` | `Normal` / `Wretched` / `Nightmare` / `Halloween` (GrandmaConfig.Forms) |
| `Corruption` | 0–4 |
| `Power` | bool. `RedSky` bool |
| `AliveCount`, `PartySize`, `Arrived`, `Expected` | Party info |
| `PrizeName`, `PrizeState` (`Hidden`/`Carried`/`Banked`/""), `PrizeHolder` | Tonight's Prize |
| `List` (JSON `[{Name, State: Hidden/Carried/Stashed, Holder, Prize}]` or ""), `ListStolen` (bool) | Tonight's list; `ListStolen` = all stashed, the night is ending early |
| `ContinuesLeft`, `GameOverEnd` (server time) | Continue Run window |
| `SugarRushNight` | The night number 2× loot applies to |
| `Finale` (bool), `PumpkinsLit`, `PumpkinsTotal`, `FinaleOpen` | Night 31 |

## Player attributes (on each `Player`, visible to everyone)
`Alive`, `Hidden`, `HideHeat` (0..1, how long you've been hiding vs the camping limit), `Hunted` (Grandma is coming for your hiding spot), `Protected`, `Escaped`, `Crouching`, `Sprinting`, `Flashlight`, `Stamina` / `MaxStamina`, `Battery` / `MaxBattery`, `CarryValue` (Candy value if banked now), `CarrySlots` / `MaxSlots`, `CarryList` (JSON array of item names), `CarryingPrize`, `Items` (JSON `{WindupToy=n, Cookie=n, FizzySoda=n}`), `Candy`, `FlashlightColor`, `SackColor`, `InCar` (lobby), `Pass_<Key>`.

## Grandma model (`workspace.Grandma`, tag `Grandma`)
Attributes: `State` (as above), `Say` (`"line|id"` — show a speech bubble whenever it changes), `Target` (the chased player's UserId, 0 if none), `Checking` (bool, while checking a hiding spot), `Form`, `DistractTime`.
Only `Humanoid`, `HumanoidRootPart` and `Head` are guaranteed. Motor6Ds are R15-named when present. Grandma's animations are played **client-side** by GrandmaAnimController (real IDs from `GrandmaConfig.Animations`; any slot with `Id = 0` uses a procedural fallback).

## Remotes
### Server → Client
| Name | Args | Use |
|---|---|---|
| `Toast` | (text, style `Candy`/`Good`/`Bad`/`Info`) | Small notification |
| `Banner` | (title, subtitle?, color?) | Big center title |
| `Noise` (Unreliable) | (pos, loudness, radius, sourceUserId, kind) | Ripple at the source + "!" over the source player. Kinds: Run, Creak, Break, Door, Search, Pickup, Lockpick, Toy, Cookie, Lantern, Fuse, Lurking |
| `Caught` | (formKey, lostValue, lostCount, canRevive, freeRevive, cause) | You were caught → jumpscare → death screen |
| `TeammateCaught` | (name, lostValue) | Teammate went down |
| `NightSummary` | {Night, Survived, Banked, Lost, AutoBanked, Bonus, Friends, FriendMult, NextNight, NextNewArea?, Checkpoint?, ChapterComplete?, NextChapter?, Goal?, GoalMet?, GoalBonus?, ListComplete?, ListBonus?, Candy} | Morning screen |
| `LootPicked` | (name, baseValue, isPrize) | Pickup pop |
| `Banked` | (candy, count, reason `Trunk`/`Dawn`) | Bank celebration |
| `SearchResult` | (foundName?) | "Nothing here…" / found |
| `HidingState` | (hidden, kind) | Enter/exit hiding |
| `HoldBreath` | (id, duration) | Start the breath check. The client must answer `HoldBreath:FireServer(id, success)` — success = the button was held for the whole duration |
| `DiaryFound` | (pageIndex, isNew) | Show the diary page (DiaryConfig[pageIndex]) |
| `Finale` | (stage `Lit`/`Open`/`Escaped`, data) | Night 31 beats |
| `CarState` | (state table or nil) | Lobby car panel: {Car, Count, Max, Countdown, FriendsOnly, StartNight, IsLeader, Checkpoints?, Occupants={{UserId,Name}}, Departing} |
| `CarDepart` | () | Fade out / "Off to Grandma's" |
| `PurchaseResult` | (productKey, success) | Thank-you feedback |

### Client → Server
| Name | Args |
|---|---|
| `SetSprint` | (bool) — while the sprint input is held |
| `SetCrouch` | (bool) |
| `ToggleFlashlight` | () |
| `UseItem` | (key, lookDirection: Vector3) |
| `LeaveHiding` | () |
| `HoldBreath` | (id, success) |
| `ReturnToLobby` | () |
| `CarAction` | ("Leave") / ("FriendsOnly", bool) / ("StartNight", n) / ("Go") |
| `SaveSettings` | ({Music?, SFX?, Sensitivity?, ReduceFlashes?}) |
| `MarkTutorial` | ("SeenIntro") |
| **Functions** | `RequestPurchase(kind "Product"/"Pass", key)` → (ok, reason). `RequestFreeRevive()` → ok. `UseReviveToken()` → ok. `ClaimDaily()` → (ok, streak or reason). `ClaimQuest(index)` → (ok, reward). `ShopBuy(kind "Upgrade"/"Item"/"Cosmetic", a, b?)` → (ok, reason). `ShopEquip(slot, id)` → ok |

## ProximityPrompts
Every gameplay prompt uses `Style = Custom` and has attribute `Kind`: `Loot`, `Prize`, `Search`, `Door`, `Hide`, `Bank`, `Diary`, `Objective`. **The client must render custom prompts** (`ProximityPromptService.PromptShown`), including the hold progress, the key/button glyph (keyboard `E`, gamepad `ButtonX`, touch = tap the prompt itself) and the Action/Object text. Lobby menu prompts carry attribute `Menu` (`Shop`/`Daily`/`Cosmetics`/`Diary`/`Quests`) and may use the default style.

## Persistent data keys (`DataController:Get`)
`TotalCandy, HighestNight, Wins, Upgrades{Pillowcase,SoftSocks,StrongLungs,Batteries}, Items{WindupToy,Cookie,FizzySoda}, Cosmetics{Owned{Flashlight{},Sack{}},Equipped{Flashlight,Sack}}, Stats{...}, Diary{["1"]=true}, Achievements{id=true}, Daily{LastClaimDay,Streak}, Quests{Day,List{{Id,Target,Reward,Progress,Claimed}}}, Social, Tutorial{UsedFreeRevive,SeenIntro,FirstNightDone}, Settings{Music,SFX,ReduceFlashes,Sensitivity}, Passes, Tokens{Revive}`. Candy = `DataController:GetCandy()`.
