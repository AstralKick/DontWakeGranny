# Developer TODO Before Release

This list only covers things that need a human in Creator Dashboard or Studio, or final assets. Every external ID is centralised in `Game/Config`. You won't need to edit any gameplay script.

## 1. Save & publish
- [ ] In **both** Studio places (Lobby, Granny's House): **File → Save to Roblox / Publish**. The maps (Workspace.House plus the 5 chapter maps in `Workspace.Maps`), Mom's cars and the Grandma rig (`ReplicatedStorage.Grannies.TempGrandma`, Granny's House place) exist only in those place files. The builder scripts in `tools/` can rebuild the maps if needed.
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
- [ ] **Grannies to make** (one per map, plus specials). Put each in `ReplicatedStorage.Grannies` and set the `Maps` attribute (comma-separated MapIds). A Granny with `Maps` only appears on those maps and is 4× preferred there. A new Granny is picked at each chapter change.

| # | Model name | DisplayName | Maps / attributes | Look |
|---|---|---|---|---|
| 1 | `ClassicGrandma` | Grandma | `GrandmasHouse` (also the fallback everywhere) | Cardigan, grey bun, big round glasses, slippers, pearl necklace. The icon/thumbnail Granny: make her the best one |
| 2 | `GardenGranny` | Nana Thorn | `BackGarden` | Straw sun hat, floral apron with muddy knees, wellies, garden gloves, pruning shears in hand, leaves in her hair |
| 3 | `MatronGranny` | Matron Gladys | `SunnyPines` | 70s nurse cap and pale blue uniform, cat-eye glasses on a chain, fob watch, pushes a squeaky walker (walker as part of the rig) |
| 4 | `WidowGranny` | Widow Wren | `StMildreds` | Black Victorian mourning dress, lace veil over her face, long gloves, holds a candle. Tasteful; no religious costume |
| 5 | `FortuneGranny` | Madame Nana | `HarvestFair` | Fortune-teller headscarf, gold hoop earrings, layered shawls, bangles, a crystal ball on a belt |
| 6 | `NightmareGranny` | Grandma? | `NightmareHouse`, `MinNight = 26` | Same silhouette as #1 but wrong: too tall, long arms, cracked porcelain skin, a too-wide smile, eyes that glow in the dark |
| 7 | `WitchGranny` | Grandma Hallow | `NightmareHouse`, `MinNight = 31`, `Weight = 20` | Night 31 only: pointy witch hat, cape, pumpkin lantern. (The "Halloween Witch" outfit already recolours any rig; this is the dedicated model) |
| 8 | *(later, for events)* `ChristmasGranny`, `ValentineGranny` | — | Leave `Maps` empty; keep `Weight = 0` until the event, then raise it (e.g. 10) | Seasonal drops. They're good reasons for players to come back |

  Rig rules: R15-like or custom, about 6–7 studs tall. Name clothing parts to match `GrandmaConfig.OutfitParts` so nightly outfits recolour them, or set `NoOutfits = true` on themed rigs to keep their colours. Name eye parts `Eye` and give skin parts `Skin = true`. The closed-eye lids are generated automatically from the `Head`.
- [ ] Upload animations and paste their IDs into `GrandmaConfig.Animations`: `Sleep`, `Stir`, `Wake`, `Idle`, `Walk`, `Search`, `Run`, `Attack`, `CheckHiding`, `Laugh`, `Jumpscare`. Any slot left at `0` keeps its procedural placeholder.
- [ ] Optional per-form jumpscare tuning: `GrandmaConfig.Forms.<Form>.Jumpscare` (sound key, flash color, FOV, duration, animation slot).

## 6. Sounds to grab → `Game/Config/AssetConfig.luau`
Paste each ID into the key listed. An empty key means silence or a fallback, so nothing breaks while you work down the list. Search the Creator Store (Audio), or record and upload your own; voice lines are best recorded. **P1 = do before launch** (these carry the horror), P2 = soon after, P3 = nice to have.

### Grandma (P1: she's the star)
| Key | What to find | Now |
|---|---|---|
| `GrandmaWake` | Old woman's gasp or snort as she wakes, "Hm?! Who's there?" | empty |
| `GrandmaChaseScream` | Furious old-lady shriek, short (≤ 1.5 s) | empty |
| `GrandmaLaugh` | Creepy cackle | empty |
| `Voice_Asleep` / `Voice_Stirring` / `Voice_Searching` / `Voice_Chasing` / `Voice_Lost` / `Voice_Caught` / `Voice_HidingCheck` | One clip per line in `GrandmaConfig.VoiceLines` (e.g. "Come to Grandma, sweetie", "I KNOW you're in here"), or a single `Voice_Generic` mumble | empty |
| `GrandmaStir` | Sleepy snort or mumble | placeholder |
| `Snore` | Looping old-lady snore | OK |
| `GrandmaFootstep` | Heavy slipper shuffle | placeholder |

### Jumpscares (P1: each variant has its own)
| Key | What to find | Now |
|---|---|---|
| `Jumpscare_Lunge` | Shriek + orchestral hit | placeholder |
| `Jumpscare_Grab` / `Jumpscare_GrabPre` | Grab hit / a quick fabric whoosh before it | placeholder |
| `Jumpscare_BehindYou` / `…Pre` | Whisper "boo" + stinger / a breath right in your ear | placeholder |
| `Jumpscare_Drop` / `…Pre` | **Heavy thud + shriek** / ceiling creak | empty |
| `Jumpscare_Peek` / `…Pre` | Slow door creak into a scream / a tiny giggle | placeholder |
| `Jumpscare_Scream` | Full-face distorted scream | community upload |
| `Jumpscare_TrickOrTreat` / `…Pre` | **Pumpkin crunch or deep bell hit** / kids' "trick or treat" slowed down | empty |
| `JumpscareNormal` / `JumpscareWretched` / `JumpscareNightmare` | Fallback stings per form (gets nastier) | placeholder |
| **Map-themed scares** (only on their own map): | | |
| `Jumpscare_Sheet` / `…Pre` | Back Garden "Sheet": cloth whip + shriek / wet sheet flapping on the line | hit empty, pre placeholder |
| `Jumpscare_Curtain` / `…Pre` | Sunny Pines "Curtain": curtain rip + scream / rings sliding on a rail | hit empty, pre placeholder |
| `Jumpscare_Wheelchair` / `…Pre` | Sunny Pines "Wheelchair": metal crash + shriek / tube-light buzz + squeaky wheels | hit empty, pre placeholder |
| `Jumpscare_Toll` / `…Pre` | St. Mildred's "Toll": choir or organ stab / one deep church bell | hit empty, pre placeholder |
| `Jumpscare_JackInTheBox` / `…Pre` | Harvest Fair "Jack-in-the-box": spring boing + cackle / music box "Pop Goes the Weasel", slowing | hit empty, pre placeholder |
| `Jumpscare_Crooked` / `…Pre` | Nightmare House "Crooked": deep distorted hit / slow neck crack | hit empty, pre placeholder |

### Countdown & night flow (P1: this is what keeps people playing)
| Key | What to find | Now |
|---|---|---|
| `ClockTick` | Loud grandfather-clock tick (last minute before 6 AM) | placeholder click |
| `ClockChime` | Single deep clock chime (every in-game hour) | empty |
| `Rooster` | Rooster crow at 6 AM | empty |
| `Music.Morning` | Short, relieved "you survived" sting or loop | empty |
| `Victory` | Night 31 win fanfare | empty |
| `Music.Finale` | Halloween night chase theme | placeholder |
| `Music.Lobby` | Cosy-but-uneasy lobby music box | placeholder |

### Per-map ambience (P2: makes each map feel different; loops)
| Key | What to find |
|---|---|
| `Ambience_GrandmasHouse` | House room tone, clock tick, rain on windows |
| `Ambience_BackGarden` | Crickets, owl, leaves rustling |
| `Ambience_SunnyPines` | Fluorescent buzz, distant heart monitor, radiator ticks |
| `Ambience_StMildreds` | Cold wind through stone, distant organ drone, crows |
| `Ambience_HarvestFair` | Slowed, detuned carousel/calliope music, creaking rides |
| `Ambience_NightmareHouse` | Low drone, reversed lullaby, thumps like a heartbeat |

### World & UI (P2/P3)
| Key | What to find | Priority |
|---|---|---|
| `LightSwitch` | Old chunky light-switch click | P2 (placeholder) |
| `DoorSlam` | Door slam | P2 |
| `PowerDown` / `PowerUp` | Electrical power-down whine / fuse clunk + hum | P2 |
| `Breath` / `Gasp` | Held-breath exhale / scared gasp | P2 |
| `Whisper` | Unintelligible whisper (Nightmare events) | P3 |
| `LanternLight` | Pumpkin lantern "whoomp" (Night 31) | P2 |
| `CarEngine` / `CarDoor` | Minivan engine start / sliding door | P3 |
| `UIHover` | Very soft pop | P3 |

- [ ] When done, check that every Creator Store sound is allowed in your experience (Creator Dashboard → Audio permissions).

## 7. Creator Dashboard settings
- [ ] Experience → Places: allow **teleports between places** (on by default in the same universe).
- [ ] Security: turn on **Studio Access to API Services** so ProfileStore / OrderedDataStore work in Studio tests.
- [ ] Social: invite prompts use `SocialService:PromptGameInvite` with `LaunchData` (the referral bonus). No setup needed; check it works on a published build.
- [ ] Analytics → Funnels: the onboarding funnel (steps 1–6) is logged automatically. Watch step 3 → 4 (arrive → first loot) closely.
- [ ] Maturity & compliance questionnaire: the game has horror themes and jumpscares (likely **Mild/Moderate** fear). Fill it in honestly.
- [ ] Thumbnails, icon and trailer (Mom's minivan + Grandma asleep in her chair is a strong key-art moment).
