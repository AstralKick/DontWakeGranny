# Developer TODO Before Release

This list only covers things that need a human in Creator Dashboard or Studio, or final assets. Every external ID is centralised in `Game/Config`. You won't need to edit any gameplay script.

## 1. Save & publish
- [ ] In **both** Studio places (Lobby, Granny's House): **File → Save to Roblox / Publish**. The maps, Mom's cars and the Grandma rig (`ReplicatedStorage.Grannies.TempGrandma`, Granny's House place) exist only in those place files.
- [ ] Make sure the **Lobby is the universe's start place** and Granny's House is a secondary place (teleport target only).
- [ ] In both places, set `Lighting.Technology = Future` (scripts can't set it). `Workspace.StreamingEnabled` can stay off for now (the house is small).

## 2. Developer Products → `Game/Config/MonetizationConfig.luau` → `Products.<Key>.Id`
| Key | Name | Recommended price | What it does |
|---|---|---|---|
| `Revive` | Revive | 29 R$ | Revive yourself mid-night (1 per night; your first-ever revive is free) |
| `ContinueRun` | Continue Run | 79 R$ | After a team wipe, replay the night for everyone (max 3 per run) |
| `SugarRush` | Sugar Rush | 49 R$ | 2× loot value for the whole server for one night |
| `CandySmall` | Handful of Candy | 49 R$ | +500 Candy |
| `CandyMedium` | Bag of Candy | 149 R$ | +1,800 Candy |
| `CandyLarge` | Bucket of Candy | 399 R$ | +5,500 Candy |

A product whose Id is `0` is hidden in the UI and can't be prompted.

## 3. Game Passes → `MonetizationConfig.luau` → `Passes.<Key>.Id`
| Key | Name | Recommended price | Effect |
|---|---|---|---|
| `VIP` | VIP | 249 R$ | +20% Candy, gold flashlight beam |
| `BigPillowcase` | Huge Pillowcase | 149 R$ | +2 loot slots |
| `StarterPack` | Sneaky Starter Pack | 99 R$ | 1,000 Candy, 3 of each item, Patchwork pillowcase (granted once) |

## 4. Badges → `Game/Config/AchievementConfig.luau` → `<Id>.BadgeId`
Create one badge per entry: Welcome, FirstNight, Night5, Night10, Night15, Night20, Night25, Night30, Halloween, Caught, Thief, Hoarder, Breathless, Escapist, Historian, Pals. Achievements still work while an ID is `0`; no badge is awarded.

## 5. Final Grandma rig & animations → `Game/Config/GrandmaConfig.luau`
- [ ] Put final Granny rigs (Models) in `ReplicatedStorage.Grannies` (Granny's House place). Each needs a Humanoid, a HumanoidRootPart as PrimaryPart and a part named `Head`; name eye parts `Eye` and give skin parts the attribute `Skin = true` so late-night forms can tint them. One is picked at random per run (`GrandmaConfig.RigSelection = "PerRun"` or `"PerNight"`). Optional rig attributes: `DisplayName`, `Weight`, `MinNight`, `SpeedMult`. Per-rig animations: add StringValue children `Anim_<Slot>` (e.g. `Anim_Run`) holding the animation id.
- [ ] Upload animations and paste their IDs into `GrandmaConfig.Animations`: `Sleep`, `Stir`, `Wake`, `Idle`, `Walk`, `Search`, `Run`, `Attack`, `CheckHiding`, `Laugh`, `Jumpscare`. Any slot left at `0` keeps its procedural placeholder.
- [ ] Optional per-form jumpscare tuning: `GrandmaConfig.Forms.<Form>.Jumpscare` (sound key, flash color, FOV, duration, animation slot).

## 6. Audio → `Game/Config/AssetConfig.luau`
Music is already wired (`GrannyAsleep`, `GrannySearching`, `GrannyChasing`). Replace or fill in:
- [ ] `Music.Lobby`, `Music.Morning`, `Music.Finale` (currently placeholders or empty)
- [ ] Jumpscares: `JumpscareNormal`, `JumpscareWretched`, `JumpscareNightmare`, `JumpscareScream` (currently a generic orchestral hit and a community upload)
- [ ] Per-variant jumpscare sounds (`Jumpscare_<Variant>` + `Jumpscare_<Variant>Pre` build-ups, see `GrandmaConfig.JumpscareVariants`): still empty: `Jumpscare_Drop` (thud + shriek) and `Jumpscare_TrickOrTreat` (pumpkin crunch or bell). `Jumpscare_Scream` is a community upload, and the rest are licensed placeholders.
- [ ] `LightSwitch` (Grandma flicking room lights on) is a placeholder click
- [ ] Grandma: `GrandmaWake`, `GrandmaChaseScream`, `GrandmaLaugh`, voice lines (`Voice_Asleep`, `Voice_Stirring`, `Voice_Searching`, `Voice_Chasing`, `Voice_Lost`, `Voice_Caught`, `Voice_HidingCheck`, or one `Voice_Generic`)
- [ ] House/UI SFX left empty: `DoorSlam`, `PowerDown`, `PowerUp`, `ClockChime`, `Whisper`, `LanternLight`, `Breath`, `Gasp`, `UIHover`, `Rooster`, `Victory`, `CarEngine`, `CarDoor`
- [ ] Check that every Creator Store sound in AssetConfig is allowed in your experience (Creator Dashboard → Audio permissions)

## 7. Creator Dashboard settings
- [ ] Experience → Places: allow **teleports between places** (on by default in the same universe).
- [ ] Security: turn on **Studio Access to API Services** so ProfileStore / OrderedDataStore work in Studio tests.
- [ ] Social: invite prompts use `SocialService:PromptGameInvite` with `LaunchData` (the referral bonus). No setup needed; check it works on a published build.
- [ ] Analytics → Funnels: the onboarding funnel (steps 1–6) is logged automatically. Watch step 3 → 4 (arrive → first loot) closely.
- [ ] Maturity & compliance questionnaire: the game has horror themes and jumpscares (likely **Mild/Moderate** fear). Fill it in honestly.
- [ ] Thumbnails, icon and trailer (Mom's minivan + Grandma asleep in her chair is a strong key-art moment).
