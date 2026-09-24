# UI Style Guide

Read this before building or changing any UI. UI code lives in `Game/Client/UI` (synced to `ReplicatedStorage.UI`).

## The vibe: creepy, but bubbly

Think **a children's picture book that's gone slightly wrong**. Chunky, soft, rounded and toy-like, but the colors are a little sickly, things lean a little, and there's always something off in the corner.

- **Bubbly**: fat rounded shapes, thick outlines, squishy button presses, bouncy tweens, big friendly type.
- **Creepy**: faded, dusty colors; an almost-cute palette that's slightly "off"; shapes that are uneven on purpose; a few unsettling details (a drip, a stitched seam, an eye that follows the cursor, a crack in a corner).
- The balance is roughly **70% bubbly, 30% creepy**. It should make someone smile *and* feel uneasy. It should never be gory, and never full-on horror-edgy.

## It must NOT look AI-generated

Generic "AI UI" has a recognizable look. Avoid all of these:

| ❌ Don't | ✅ Do instead |
|---|---|
| Purple→blue or neon gradients, glassmorphism, frosted blur panels | Flat colors with a subtle paper/grain texture and a single darker shadow offset |
| Perfectly symmetrical, centered, identical cards in a grid | Slight rotation (±1–3°) on panels/stickers, varied sizes, asymmetric layouts |
| Glowing outlines, sparkles, lens flares, "futuristic" HUD lines | Thick dark `UIStroke` outlines like a cartoon inked by hand |
| Emoji as icons, generic stock icon packs | Custom icons with the same stroke weight and palette, doodle-style |
| Gotham/Arial/Source Sans everywhere | A deliberate font pairing (below) |
| Pure white text on pure black | Warm off-whites (`#F3E9D2`) on deep plum/brown |
| Everything fades in the same way | Animation with character: squash, overshoot, a wobble, occasional twitch |
| Placeholder copy ("Welcome to the game!", "Unlock amazing rewards!") | Written copy with a voice: "Shhh… she's sleeping.", "Don't. Make. A. Sound." |

A good test: **would a human artist have made this choice on purpose?** If a detail is there only because it's the default, change it.

## Palette

Faded nursery colors with a sickly undertone. Build every color from these tokens (keep them in one `UITheme` module):

| Token | Hex | Use |
|---|---|---|
| `Ink` | `#2A1A24` | Outlines, primary text on light panels |
| `Night` | `#3B2A3F` | Panel backgrounds, dark surfaces |
| `Paper` | `#F3E9D2` | Light panels, text on dark |
| `Rose` | `#D97A8A` | Primary buttons, highlights |
| `Mint` | `#9CC5A1` | Positive / confirm (slightly sickly green) |
| `Mustard` | `#E0B04F` | Currency, rewards, warnings |
| `Bruise` | `#7B5C8E` | Secondary buttons, accents |
| `Blood` | `#A8323E` | Danger, "Granny is awake", destructive actions (use sparingly) |

- Shadows: a hard offset copy of the shape in `Ink` at ~0.6 transparency, shifted 0,4–6px down. **No soft blurry drop shadows.**
- Use `Blood` as a signal only. If everything is red, nothing is scary.

## Typography

Use `Font.new(...)` / `Font.fromEnum(...)` with `TextLabel.FontFace`.

| Role | Font | Notes |
|---|---|---|
| Titles / logo | `LuckiestGuy` or `FredokaOne` (bold) | Chunky and bubbly. `Creepster` is only for one-word accents ("AWAKE!") and never for body text |
| Buttons / headers | `FredokaOne` | Rounded, readable at any size |
| Body / flavor text | `PatrickHand` | Handwritten feel, like notes scribbled by a kid |
| Notes / clues found in-world | `SpecialElite` or `IndieFlower` | Typewriter or diary look |

- Every title gets a thick `UIStroke` (`Ink`, 2–4px, `ApplyStrokeMode = Contextual`).
- Never use more than 2 fonts on one screen.

## Shapes & components

- **Corners**: big `UICorner` radii (`UDim.new(0.2, 0)` to `UDim.new(0.5, 0)` for pills). Nothing sharp except intentional "cracks".
- **Outlines**: every panel and button has a `UIStroke` in `Ink`. Keep stroke thickness consistent across the whole game (3px at 1080p, scaled; see below).
- **Buttons**: pill-shaped, with a hard shadow underneath. On press, the button moves down onto its shadow (squish), then pops back with `Enum.EasingStyle.Back`.
- **Panels**: look like paper or card stock, rotated slightly, maybe with a "tape" or "pin" decal at the top.
- **Creepy details** (one or two per screen, not everywhere): a drip hanging off a panel edge, a stitched seam, a tiny eye, a scratch mark, a slightly misaligned letter in a title.

## Motion

- Open: scale from 0.8 → 1.05 → 1 (`Back` easing, ~0.25s). Close: quick shrink (~0.15s).
- Idle: very slow bob or breathe (±2px, 3–4s loop) on key elements like the title and the main play button.
- Creepy beats: rare, short twitches (a 0.05s rotation jolt, a flicker) that happen at random intervals, not on a loop.
- Respect "reduce motion". Keep an option to turn off idle and twitch animations.

## HUD during gameplay

- Minimal. The house is the star. Show only a noise meter, the objective, the interact prompt and the inventory.
- The **noise meter** is the key HUD element: a cute "sleeping Granny" face that goes from peaceful → stirring → eyes open, and gets more wobbly and red as noise rises.
- Keep HUD elements pinned to the edges, away from the center of the screen and away from the thumb zones on mobile.

---

## Cross-platform scaling (Mobile, PC, Console)

UI has to work on a 5" phone, a 27" monitor and a TV across the room.

### Layout rules
- **Size with Scale, not Offset.** Use `UDim2.fromScale(...)` for sizes and positions.
- Lock shapes with `UIAspectRatioConstraint` so buttons and panels don't stretch.
- Clamp extremes with `UISizeConstraint` / `UITextSizeConstraint` (e.g. min text 14px on phones, max so text doesn't get huge on ultrawide screens).
- Use `TextScaled = true` **only** with a `UITextSizeConstraint`. Otherwise, pick sizes from a scale factor.
- Set `AnchorPoint` deliberately (e.g. `0.5, 0.5` for centered things, `1, 1` for bottom-right HUD).
- Use `UIListLayout` / `UIGridLayout` / `UIPadding` (with Scale padding) instead of hand-placing items.
- `ScreenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets` so nothing sits under the notch, the Roblox top bar or the TV overscan area. Use `DeviceSafeInsets` only for full-bleed backgrounds.
- `ScreenGui.ResetOnSpawn = false` for persistent UI.

### Global UI scale
One `UIScale` per ScreenGui, driven by the viewport so stroke widths, corners and offsets stay proportional:

```lua
local camera = workspace.CurrentCamera
local BASE = Vector2.new(1920, 1080)

local function updateScale(uiScale: UIScale)
	local vp = camera.ViewportSize
	uiScale.Scale = math.clamp(math.min(vp.X / BASE.X, vp.Y / BASE.Y), 0.5, 1.5)
end
```

For `UIStroke.Thickness` (which is in pixels), multiply the base thickness by the same factor.

### Detect the input type, not the device
Use `UserInputService.PreferredInput` (`Touch`, `Gamepad`, `KeyboardAndMouse`) and listen for changes. Players switch between input types mid-session (e.g. a gamepad plugged into a PC). As a fallback, use `LastInputType`, `TouchEnabled` or `GamepadEnabled`.

| | Mobile (Touch) | PC (Keyboard/Mouse) | Console (Gamepad) |
|---|---|---|---|
| Hit targets | **≥ 44×44 pt**, spaced apart; big bottom-corner action buttons | Can be smaller; hover states matter | Big and clearly focused; designed for "10-foot" viewing |
| Text | Min ~14pt on screen | ~16px+ | **Min ~24px at 1080p**, since TVs are far away |
| Prompts | Tap icons | Key glyphs (`E`, `Shift`) | Button glyphs via `UserInputService:GetImageForKeyCode(Enum.KeyCode.ButtonX)` |
| Hover | None, so never hide info behind hover | Use hover for the wobble/highlight | Replace with the **selection** state |
| Layout | Keep thumb zones (bottom-left joystick, bottom-right jump/action) clear | Free | Keep everything inside TV-safe insets |

### Console / gamepad navigation
- Every interactive element needs `Selectable = true`. Set `GuiService.SelectedObject` when a menu opens, and give it back to the gameplay HUD when the menu closes.
- Define `NextSelectionUp/Down/Left/Right` wherever automatic navigation guesses wrong.
- Replace the default blue selection box with a custom `SelectionImageObject` that fits the style (a thick `Rose` outline plus a bounce), so focus is always obvious.
- `B` / `ButtonB` always closes or goes back. Never trap focus.
- Use `GuiService.SelectionGroup` behavior (`SelectionBehaviorUp`, etc.) or group containers so focus doesn't jump across the screen.
- Buttons that aren't inside a MenuHost menu register a focus zone with `GamepadNav.AddZone` (see `Game/Client/UI/GamepadNav.luau`). Gameplay runs with `SelectedObject = nil`, so the sticks move the kid, not a cursor.
- **Never bind `ButtonStart`**: Roblox reserves it for the system menu.

#### Gamepad map
| Where | Buttons |
|---|---|
| Walking (Match) | L3/L2 sprint (hold) · B crouch · Y flashlight · R1 use item · L1 next item · X interact / hold prompt · **Select = Settings** · DPadUp = focus on-screen buttons (morning Sugar Rush, Continue Run, death panel) |
| Walking (Lobby) | X station prompts · **Select / DPadUp = focus the HUD buttons** (Shop, Dress Up, Chores, Mailbox, Diary, Settings, then Invite to the right of the top row) · B or Select lets go |
| Any menu | The first button is focused on open · A picks · **B closes** · Select closes · focus goes back to gameplay |
| Car panel | Focus jumps to GO NOW (driver) or Get out · B = Get out · focus comes back after a menu closes |
| Hiding | B leave · A (or X) hold breath during a check |
| Caught | Panel: SPECTATE focused, B = spectate · Spectating: DPad ‹ › or LB/RB switch teammate, Y = options |
| Console layout | `GuiService:IsTenFootInterface()` adds a 3.5% TV-safe `UIPadding` to every non-bleed Root (UIController) |

Studio testing: `LocalPlayer:SetAttribute("DebugInput", "Gamepad" | "Touch" | "KeyboardMouse")` (client, Studio only) forces the UI's input kind so you can check glyphs and layouts.

### Test every screen
Use the Studio **Device Emulator** on at least:
- A small phone (portrait-ish and landscape)
- A tablet
- 1080p desktop
- An ultrawide monitor
- A 1080p/4K console (TV) target

Also navigate every menu with **only a gamepad** and with **only touch**. Use `screen_capture` to check the results.
