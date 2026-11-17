# HeyChomp Visual System v5: "Quiet window, loud characters"

This spec replaces `CompanionStyle`, `WorkspaceMetrics`, `WorkspaceTypography` and `InterfaceMotion` in `Sieghart/Shared/Components/DesignSystem.swift`.

**How the numbers were produced**

- **Contrast** is WCAG 2.x relative luminance, computed by script (Appendix A), against *floors* (worst-case surfaces). The app ships on **macOS 14.6**, so light floors include macOS 14 values: `windowBackgroundColor` is about `#ECECEC` there and `#FFFFFF` on macOS 26/27, where it was sampled. The vibrant sidebar and popover floor is a design assumption: `#E3E3E3` light, `#282828` dark. Materials depend on the wallpaper, so the guarantee for them is the Reduce Transparency solid fallback.
- **Character hues** come from `Companion-*-illustration` atlas pixels, in OKLCH, then moved as little as the distinctness requirement allows (§3.1 gives every distance moved).
- **Color-vision check**: Machado et al. 2009 matrices at severity 1.0 (protanopia, deuteranopia, tritanopia), distance in OKLab (ΔEok), all 15 pairs, normal vision plus three simulations. The values come from a **hill-climbing search that maximizes the worst pair** (not one that stops at a threshold), under: a hue window around the art hue (one window per character, the **same window in light and dark** so a character stays in one colour family when the appearance changes), lightness window, chroma floor, and 3.05:1 on every floor. The script is Appendix A.
- **What the distinctness numbers do and do not prove.** No standard exists for color-vision distance of small marks. OKLab's just-noticeable difference is about 0.02 for large patches. Worst pairs here are **0.097 light, 0.123 dark**. Small marks (a 2.5 pt ring) are harder than large patches, so the spec does **not** rely on color alone: the illustration is always inside the ring, and the bar marker always sits beside an avatar and a name (S11). §3.3 lists every pair under 0.105. Colour is a **redundant** cue in this system, never the only carrier of identity (S11).

## 0. Assumptions

1. "Chomp" is the persona `.sig` in `LocalChatPersona`. Its art is the `Companion-sig*` assets.
2. Deployment target stays **macOS 14.6**. Liquid Glass (`glassEffect`) is used only behind `if #available(macOS 26, *)`, with `.regularMaterial` below that.
3. **All settings live in the main window.** Keep Awake's form goes to Tools > Keep Awake (§8.3b). Every other preference (Ativação, Aparência, Widget, Áudio, Uso de IA, Sistema) goes to Tools > **Ajustes** (a `Form { }.formStyle(.grouped)` page). There is **no separate Settings scene**: ⌘, is routed to that page with `CommandGroup(replacing: .appSettings)`, and the popover's "Ajustes…" opens the window on it. The sidebar keeps only places.
4. "Tools" holds Agenda, Timers, Keep Awake, Captura, Área de transferência, Janelas, Tela e energia, Ajustes.
5. UI copy stays pt-BR. This spec is in English so token names match the code.
6. The black blob bodies are assumed to be about `#1A1A1A` or darker. **Pre-ship gate:** sample the real atlas pixel. If the body is darker than `#151515`, raise the dark plate from `#303030` to `#3A3A3A` (island `#333333`); nothing else changes.
7. The global companion shortcut is user-configurable. Default **⌃⌥Space** (⌥Space is ChatGPT's desktop default and is avoided).

---

## 1. How the parts affect each other

| # | Interaction | Consequence if ignored | Rule it produces |
|---|---|---|---|
| S1 | macOS applies an app's `AccentColor` only when the user's System accent is "Multicolor"; `.tint` is unreliable on some AppKit-backed controls (checkboxes in particular); and AppKit draws sidebar selection in the System accent with a white label. | A blue sidebar selection beside mint buttons (two accents on the first screen), or a mint selection with a 3.9:1 white label. | **Every control the app draws is ours** (`ChompProminentButtonStyle`, `ChompToggleStyle`, `ChompProgressBar`, §9) and reads `HC.accent` directly. **The sidebar draws its own selection**: rows are plain buttons in a `List(.sidebar)`; the selected row gets a neutral `selection.sidebar` fill (label primary at 10%), a filled SF Symbol variant and semibold text, so selection is not colour-only and no second hue appears (§8.1 notes cover keyboard). We **also ship an `AccentColor` asset = mint** (light #00945F, dark #3EDC9A) so the few system-drawn leftovers (keyboard focus ring, `Slider` fill, text-selection highlight, segmented control) are mint for Multicolor users. For a user who has chosen another System accent (Graphite, Red...), only those four system-drawn items follow that choice: it is an OS-level preference, none of the four is on the Today screen's content, and our own controls never change. |
| S2 | System status hues sit on top of the characters: `systemGreen` ≈ mint, `systemOrange` ≈ Elinor, `systemYellow` ≈ Gantt. | A "warning" reads as "Elinor is talking", "success" as "Chomp". | **Status never uses hue, except red for errors and destructive actions.** Status is carried by SF Symbol shape plus text. |
| S3 | Five of the six characters have **near-black bodies**. On the dark window or the black island they lose their silhouette, as in the current screenshot. | Idle characters disappear. | Every avatar sits on a **quiet solid neutral plate** (a small step from the surface, in both modes) with a **1 pt neutral rim**, always on (§2.1). The **rim** (3.75:1 or better against every floor) carries the silhouette; the plate is deliberately quiet so the characters stay the only expressive element, and light and dark are symmetric. Agent colour stays reserved for "speaking". |
| S3b | The speaking ring must be certified against the surface it touches. Drawn on a plate it would fail for some marks. | The "who is speaking" signal fails 1.4.11 on the one surface that carries it. | **The ring is drawn outside the plate, separated by a 1.5 pt gap of the surrounding surface** (§9 `AvatarView`). Its floors are the window floors in §2.0. The slot is always reserved (size + 12 pt, island size + 10 pt) so nothing shifts when the ring appears, including the Increase Contrast ring with hairlines (§9 geometry). |
| S4 | The notch is physically black in both appearances. | Light tokens inside the island would be wrong. | The island is **always dark**: `surface.island = #000000`, dark tokens regardless of system appearance, contrast computed against `#000000`. |
| S5 | `secondaryLabelColor` is black at about 50-55%: **3.95:1** on white (macOS 26/27) and **4.58:1** on `#ECECEC` (macOS 14). | Small metadata becomes unreadable for some users. | All small informative text uses `labelColor` or the custom `content.meta` (≥ 5.4:1 on every floor). `secondaryLabelColor` is for glyphs and ornaments only. `tertiaryLabelColor` is for disabled only. |
| S6 | Rita and Toni are both purple in the art (book hue 307°, headphones 309°). Ada's teal tag (172°) sits near Chomp's mint (161°). | Three purples and two greens: no identity. | Hues assigned and moved by §3.1 (one family per character in both modes), verified under three color-vision simulations. |
| S7 | More colored surfaces means less meaning for each one. | The "AI app template" look. | Color is a **signal**: mint means "you can act here / it is running", an agent color means "this agent is speaking / this is theirs". No tinted backgrounds, gradients or colored cards. |
| S8 | Characters are idle-animated, but the window is used all day. | Battery use and motion fatigue. | Idle animation runs only while the window is key and visible. Off under Reduce Motion and Low Power Mode. |
| S9 | A template `NSImage` is tinted as a whole by the system. | A "mint sparkle only" menu bar icon is impossible, and mint is about 1.5-3:1 on a menu bar anyway. | The menu bar icon is a pure template image in two shapes (idle, running). It carries **no color** (§8.3). |
| S10 | Mint is both Chomp's identity and the action color. Earlier drafts also used the same hex as a dot for Chomp's items and for "running". | "Chomp is speaking", "press here" and "running" blur together. | **Each mint shape has one meaning.** *Ring around an avatar* = Chomp is speaking, and only Chomp may have a ring in mint. *Filled button, switch, progress bar, 6 pt running dot, caret* = action or running. *Vertical bar marker* = a specialist's item, and **Chomp's own items carry no marker at all** (Chomp is the default voice). Mint is never a ring on another avatar, never a fill on an avatar, never a marker bar. |
| S11 | Color is not enough at small sizes (island XS 18 pt avatar, 3 pt marker bar). | Color-blind users cannot tell two near marks apart, and 0.097 is not a proven margin for small marks. | Identity never rides on color alone: the **illustration is always inside the ring** (at island XS the avatar is the only identity cue, and the six silhouettes differ: Chomp sparkle, Rita glasses and book, Ada tag, Gantt hard hat, Elinor gem, Toni headphones), the marker bar always sits next to an avatar and a name, and every avatar has `.accessibilityLabel("<name>")` and `.help("<name>")`. Colour only adds a second, redundant cue. |
| S12 | Type-to-chat and ⌘ shortcuts must not fight text fields, `List` type-select or IME. | Typing in a field triggers navigation; the sidebar swallows keys; dead keys (é, ã) are lost. | Type-to-chat is a window-scoped `NSEvent` **local monitor** (runs before the responder chain), fires only when no text input has focus, and **forwards the original event** to the composer (§8.1 notes, §9). |

---

## 2. Color tokens

### 2.0 Reference surfaces (floors)

| Surface | Light | Dark |
|---|---|---|
| `textBackgroundColor` (content column) | `#FFFFFF` | `#1E1E1E` |
| `windowBackgroundColor` macOS 26/27 | `#FFFFFF` | `#1E1E1E` |
| `windowBackgroundColor` **macOS 14/15** | **`#ECECEC`** | `#1E1E1E` |
| Sidebar / popover design floor (vibrant, assumed) | **`#E3E3E3`** | **`#282828`** |
| Island | `#000000` | `#000000` |

The content column (Today, chat, Library) is drawn on `textBackgroundColor`. Only toolbar, sidebar and Ajustes sit on the OS-dependent window color. Ratios are listed as **white or #1E1E1E / #ECECEC or #282828 / #E3E3E3 or #000000**, in that order. The avatar plate is not a floor for any mark (S3b).

### 2.1 Surfaces

| Token | SwiftUI / AppKit | Light | Dark | Where |
|---|---|---|---|---|
| `surface.content` | `Color(nsColor: .textBackgroundColor)` (system) | #FFFFFF | #1E1E1E | Today, chat transcript, Library list |
| `surface.window` | `.windowBackgroundColor` (system) | #FFFFFF (26+) / #ECECEC (14-15) | #1E1E1E | Ajustes, toolbar area |
| `surface.sidebar` | `List(...).listStyle(.sidebar)`; the system draws it | ≈#F6F6F6 to #E3E3E3 | ≈#282828 | Sidebar |
| `surface.raised` | `.quaternarySystemFill` (system) | ≈#F7F7F7 on white | ≈#252525 | The **one** container level: nudge rows, popover "running" rows |
| `surface.control` | `.secondarySystemFill` (system) | ≈#EBEBEB | ≈#333333 | Field and segmented backgrounds |
| `surface.avatarPlate` | **Custom** solid disc, quiet in both modes | **#EDEDF0** | **#303030** | Circle behind every character. Island: **#2A2A2A**. |
| `control.stroke` | **Custom.** Off-state outline of our switch and checkbox, and the off knob | **#7A7A7A** (4.29 on white, 3.63 on #ECECEC, 3.34 on #E3E3E3) | **#8A8A8A** (4.83 on #1E1E1E, 4.27 on #282828) | Non-text 3:1 for control boundaries. Increase Contrast: #595959 / #AAAAAA |
| `selection.sidebar` | **Custom** neutral fill: `labelColor` at 10% (6% when the window is inactive) | ≈#E8E8E8 on #F6F6F6 | ≈#3A3A3A on #282828 | Selected sidebar row. The label stays `content.primary` (≥ 11.8:1), so the fill is not a text floor |
| `avatar.rim` | **Custom**, 1 pt stroke, always on | black **50%** → #808080 on white (3.95:1), #767676 on #ECECEC (3.84), #727272 on #E3E3E3 (3.75) | white **45%** → #838383 on #1E1E1E (4.40), #898989 on #282828 (4.21), #737373 on #000 (4.43) | Outer edge of the plate. Neutral. |
| `surface.panel` | `.regularMaterial`; 26+: `.glassEffect(.regular, in:)`; Reduce Transparency: `surface.window` | system | system | Companion cursor panel |
| `surface.popover` | System `MenuBarExtra(.window)` background | system | system | Menu bar popover |
| `surface.island` | **Custom** `#000000` | #000000 | #000000 | Notch island (S4) |

**Plate against a near-black body** (assumed `#1A1A1A`): `#303030` gives only **1.32:1** and `#2A2A2A` on the island about **1.36:1** against `#0D0D0D`. That is intended: the plate is a quiet seat, not the boundary. The **1 pt rim** (white 45%) closes the silhouette at 4.40:1 on `#1E1E1E` and 4.43:1 on the island, and the art's own clay highlights, props and sparkle carry the rest. The plate against the dark window is 1.26:1 and in light mode `#EDEDF0` on white is 1.17:1: both modes are equally quiet (the previous `#4A4A4A` disc was dropped as too loud). In light mode the dark body against `#EDEDF0` is above **13:1**.

### 2.2 Content (text and glyphs)

| Token | Name | Light | Ratio L (white / #ECECEC / #E3E3E3) | Dark | Ratio D (#1E1E1E / #282828 / #000) |
|---|---|---|---|---|---|
| `content.primary` | system `.labelColor` / `.primary` | #262626 | 15.1 / 12.8 / 11.8 | #DDDDDD | 12.3 / 11.1 / 14.9 on island (#D9D9D9) |
| `content.meta` | **Custom hex** (small metadata, agent name, date line, placeholder) | **#595959** | **7.0 / 5.93 / 5.46** | **#A0A0A0** | **6.38 / 5.64 / 8.03** |
| `content.secondary` | system `.secondaryLabelColor`. **Glyphs and ornaments only.** | ≈#808080 (26+), ≈#6A6A6A on #ECECEC (14) | 3.95 (white), 4.58 (#ECECEC). Non-text 3:1 passes. | #9A9A9A | 5.9 / 5.5 |
| `content.tertiary` | system `.tertiaryLabelColor`. **Disabled only.** | #BDBDBD | 1.9 | #565656 | 2.3 |
| `content.separator` | system `.separatorColor` | #E6E6E6 | decorative | #343434 | decorative |
| Island text | white at **85% / 60%** | | | #D9D9D9 / **#999999** | **14.9 / 7.37** on #000 |

Links use `content.primary` with an underline. **There is no mint text anywhere** (mint on white is 3.89:1, below the 4.5:1 text rule).

### 2.3 Accent: Chomp's mint, one value per mode

The accent is a single mint, tuned separately for light and dark. It is used as **fill, switch track, progress bar, running dot, caret, focus underline** and Chomp's ring. All of those are non-text marks (3:1 rule); the only text on it is the button label.

| Token | Type | Light | Dark | Contrast |
|---|---|---|---|---|
| `accent` | **Custom hex.** OKLCH hue 159° light / 161° dark (the sparkle's hue is 161°). | **#00945F** | **#3EDC9A** | vs surface (non-text 3:1): light **3.89 / 3.29 / 3.03** (white / #ECECEC / #E3E3E3); dark **9.45 / 8.36 / 11.91** (#1E1E1E / #282828 / #000) |
| `accent.onFill` | **Custom hex.** Label on the accent fill. | **#00150C** | **#04170F** | **4.85** on #00945F; **10.5** on #3EDC9A |
| `accent.sparkle` | **Custom.** The art's own mint, art only. | #2AD18F | #2AD18F | 1.98 on white: **never a UI mark in light** |
| Increase Contrast | swap | accent **#00583A**, onFill **#FFFFFF** (8.55 on fill, 8.55 vs white, 7.23 vs #ECECEC) | accent **#6FF0B8**, onFill **#04170F** (13.07 on fill, 11.77 vs #1E1E1E, 10.41 vs #282828) | |

**Why light mint is #00945F and not #2AD18F.** Mint at its true lightness is 1.98:1 on white, so no light-mode switch or ring could use it. #00945F keeps the hue (159° vs 161°) and the chroma family and lowers lightness (OKLab L 0.59 vs 0.76) to the minimum that still gives 3:1 on the sidebar floor. It is clearly green-mint, lighter than any "forest" green; the real #2AD18F stays in the art and on the dark island. **Dark mode has no darkening at all**: #3EDC9A is the same hue as the sparkle (161°) one step brighter, with a dark label, so there is exactly **one** green per mode.

There is **one** primary button style, `ChompProminentButtonStyle`: accent fill, `accent.onFill` label, 6 pt-continuous rounded rectangle, `.controlSize(.regular)` height 22 pt (macOS standard), 28 pt in the companion panel.

### 2.4 Signal / status (S2)

| State | Visual | Token |
|---|---|---|
| Running / active | `circle.fill` 6 pt pulse, or `ChompProgressBar` | `accent` |
| Success / done | `checkmark.circle` + text | glyph `content.secondary`, text `content.primary` |
| Warning / needs permission | `exclamationmark.triangle` + text | `content.primary` for both. **No yellow or orange.** |
| Error / destructive | `exclamationmark.octagon` glyph plus `Button(role: .destructive)` | `systemRed` on the **glyph only**. Error *text* stays `content.primary`. |
| Paused | `pause.fill` | `content.secondary` |

### 2.5 Selection, focus, hover

- **Sidebar and list selection**: system (S1). Unfocused selection is the system's `unemphasizedSelectedContentBackgroundColor`.
- **Focus ring**: system (`focusable()`, `.focusEffectDisabled(false)`).
- **Hover on rows**: `.quaternarySystemFill` to `.secondarySystemFill`. Never mint.

---

## 3. The six character colors

### 3.1 Derivation from the art, and the distance each color moves

Art values are sampled from the atlas (OKLCH: lightness L, chroma C, hue h). Hue windows for the search were built around the art hue, then the search maximized the worst color-vision pair.

| Character | Art prop (OKLCH L / C / h) | UI hue h light / dark | Moved | Why it moved |
|---|---|---|---|---|
| Chomp | Sparkle #2AD18F (0.76 / 0.16 / 161°) | 159° / 161° | ≤ 2° | It is the accent family (S10). |
| Rita | Book #65398A (0.44 / 0.13 / 307°) | **321° / 315°** | +14° / +8° | Plum-magenta, a short step from the book purple, away from Toni. Her **sprout green was tested and rejected by measurement** (first search): in a 118-140° window the best worst pair was 0.061 light, against 0.086 with the book-derived hue; green also sits between Chomp mint and Gantt yellow, where protan/deutan collapse. |
| Ada | Tag #47B89A (0.71 / 0.11 / 172°); purple-ish body | **226° / 207°** | +54° / +35° | The largest move. Teal toward cyan so it separates from Chomp's mint (tritan was the binding pair). **Held in one family in both modes** (cyan-teal, 19° apart) so Ada does not change identity when the appearance changes. Her purple body was rejected: a third purple beside Toni. |
| Gantt | Hat #FCCB49 (0.86 / 0.15 / 88°) | **74° / 104°** | -14° / +16° | Same yellow family: mustard in light (a yellow that reaches 3:1 cannot be lighter), the true hat yellow in dark. |
| Elinor | Gem #FC9401 (0.76 / 0.17 / 63°) | **50° / 64°** | -13° / +1° | Same orange family; light is pushed a little toward red so it separates from Chomp and Gantt under protan/deutan. |
| Toni | Headphones #814EA6 (0.52 / 0.14 / 309°) | **272° / 300°** | -37° / -9° | Indigo (light) / violet (dark) toward blue, so Rita (plum) and Toni (blue-violet) are two distinct hues. |

**What is honest here.** The brief forces three purple characters apart, so three colors must leave the art hue; the largest moves are Ada (+54° light, +35° dark, teal toward cyan) and Toni light (-37°). Each color stays in the **same family as its own prop** (plum for the book, cyan-teal for the tag, indigo/violet for the headphones) and **the same family in both modes** (largest light/dark hue gap 30°, and only for Gantt and Toni, where the lightness change itself shifts the perceived hue); it is drawn only on or beside that character's avatar and name (§3.4). The art is not modified.

### 3.2 Final values (custom hex, `agent.<name>`; non-text marks only)

| Agent | Light | on #FFFFFF | on #ECECEC | on #E3E3E3 | Dark | on #1E1E1E | on #282828 | on #000 (island) |
|---|---|---|---|---|---|---|---|---|
| `agent.chomp` | **#00945F** (= accent) | 3.89 | 3.29 | 3.03 | **#3EDC9A** (= accent) | 9.45 | 8.36 | 11.91 |
| `agent.rita` | **#61216D** plum | 10.79 | 9.13 | 8.41 | **#DB9CF6** orchid | 8.02 | 7.09 | 10.10 |
| `agent.ada` | **#0B6A87** cyan-teal | 6.13 | 5.19 | 4.78 | **#1497A5** teal-cyan | 4.76 | 4.21 | 6.00 |
| `agent.gantt` | **#775113** mustard | 7.07 | 5.98 | 5.51 | **#F3E334** hat yellow | 12.58 | 11.13 | 15.85 |
| `agent.elinor` | **#CC5F01** amber | 4.03 | 3.42 | 3.14 | **#CF7B03** gem orange | 5.15 | 4.55 | 6.49 |
| `agent.toni` | **#2806BF** indigo | 11.24 | 9.51 | 8.76 | **#A96EFC** violet | 5.02 | 4.44 | 6.32 |

**Every mark is ≥ 3.03:1 against every floor it sits on** (WCAG 1.4.11, non-text). Agent color is **never text**. The island always uses the dark column (S4). Light-mode marks are dark by necessity; that is why the ring slot is outside the plate (S3b).

**Increase Contrast.** The hex values do not change; each mark gets a **3.5 pt stroke** instead of 2.5 pt and a **0.5 pt `labelColor` hairline on both edges** (edge ≥ 7:1). Chomp swaps to the IC accent (§2.3).

### 3.3 How distinctness was checked (all 15 pairs, ΔEok)

Each cell is normal / protan / deutan / tritan. Search method: hill climbing on (L, C, h) of the five specialists with Chomp fixed to the accent, maximizing the minimum over all pairs and all four vision models, 3.05:1 floor on all three floors, Ada held to the 200-225° window in both modes. (Moving Ada from the first search's 238° light / 196° dark to one family cost nothing: the worst light pair rose from 0.086 to 0.097.)

| Pair | Light | Dark |
|---|---|---|
| Chomp–Rita | 0.339 / 0.322 / 0.244 / 0.286 | 0.294 / 0.201 / 0.137 / 0.206 |
| Chomp–Ada | 0.162 / 0.157 / 0.153 / **0.099** | 0.213 / 0.213 / 0.208 / 0.173 |
| Chomp–Gantt | 0.197 / 0.185 / 0.125 / 0.224 | 0.192 / 0.123 / 0.171 / 0.212 |
| Chomp–Elinor | 0.243 / **0.097** / **0.097** / 0.295 | 0.269 / 0.240 / 0.158 / 0.324 |
| Chomp–Toni | 0.380 / 0.324 / 0.314 / 0.212 | 0.368 / 0.325 / 0.265 / 0.222 |
| Rita–Ada | 0.203 / 0.179 / 0.107 / 0.204 | 0.258 / 0.131 / 0.171 / 0.227 |
| Rita–Gantt | 0.210 / 0.211 / 0.193 / **0.099** | 0.328 / 0.322 / 0.293 / 0.128 |
| Rita–Elinor | 0.311 / 0.287 / 0.324 / 0.269 | 0.266 / 0.282 / 0.254 / 0.157 |
| Rita–Toni | 0.183 / 0.141 / 0.142 / 0.145 | 0.143 / 0.140 / 0.157 / 0.133 |
| Ada–Gantt | 0.176 / 0.162 / 0.159 / 0.170 | 0.360 / 0.318 / 0.373 / 0.311 |
| Ada–Elinor | 0.279 / 0.167 / 0.245 / 0.299 | 0.241 / 0.166 / 0.200 / 0.265 |
| Ada–Toni | 0.219 / 0.171 / 0.165 / 0.115 | 0.239 / 0.160 / 0.130 / 0.136 |
| Gantt–Elinor | 0.168 / **0.103** / 0.156 / 0.183 | 0.268 / 0.286 / 0.242 / 0.257 |
| Gantt–Toni | 0.339 / 0.294 / 0.311 / 0.174 | 0.446 / 0.440 / 0.431 / 0.254 |
| Elinor–Toni | 0.441 / 0.332 / 0.406 / 0.342 | 0.313 / 0.313 / 0.311 / 0.153 |
| **Worst value** | **0.097** (Chomp–Ada tritan, Chomp–Elinor protan and deutan) | **0.123** (Chomp–Gantt, protan) |

**Weak pairs, stated.** Bold cells (light mode only) are under 0.105: Chomp–Ada tritan 0.099, Chomp–Elinor protan/deutan 0.097, Rita–Gantt tritan 0.099, Gantt–Elinor protan 0.103. Dark mode has none below 0.123. These numbers are for large patches; for the 2.5 pt ring they are an upper bound, and **no figure here proves colour alone suffices**. That is why colour is a redundant cue (S11): the illustration is always inside the ring, the agent name in `content.meta` appears wherever there is room, and every compact mark has a tooltip and an accessibility label; at island XS the six silhouettes themselves identify the character. A mint button next to an Elinor ring is not an identity ambiguity: mint is a ring only for Chomp (S10), and buttons are never rings. In light mode the two lightness classes also help: plum, indigo, cyan-teal and mustard are dark (OKLab L 0.38-0.49), mint and amber are light (0.59-0.61).

### 3.4 Where agent color may appear (exhaustive list)

| # | Where | Form |
|---|---|---|
| 1 | **Speaking ring** | 2.5 pt stroke **outside** the avatar plate (1.5 pt gap) while that agent is producing output or one of its nudges is on screen. Chomp's ring is mint. |
| 2 | **Run indicator** | 2.5 pt circular progress arc in the same outside position, around that agent's mini-avatar in the companion and island while its task runs |
| 3 | **Nudge "from" mark** | The ring (#1) on the nudge's avatar. Nothing else on the nudge is colored. |
| 4 | **Own-item marker (specialists only)** | A **3 × 16 pt vertical capsule** at the leading edge of a conversation row, Library item or Today event that belongs to **Rita, Ada, Gantt, Elinor or Toni**. The row also shows that agent's avatar and name. **Chomp's items have no marker.** |
| 5 | **Team page** | The ring around the large avatar on the agent's own detail view |

Agent color is **never** used for text or links, buttons, backgrounds, washes or gradients, sidebar icons, toolbar items, the menu bar icon, borders of containers, status (S2), or for more than one agent in a single list row. The idle plate rim is neutral.

---

## 4. Rules for the accent (mint)

**Allowed**, and only here:

| # | Where |
|---|---|
| 1 | The sparkle in the Chomp art (`accent.sparkle`). **Not the menu bar icon** (S9). |
| 2 | The **one** primary action per view: `ChompProminentButtonStyle`. Examples: "Levantar" on a nudge, "Enviar", "Estender" in the popover. |
| 3 | Our own controls: `ChompToggleStyle` (switch and checkbox, on-state), `ChompProgressBar`, `Slider` fill, and the `AccentColor` asset (system focus ring, text selection). |
| 4 | The "running" 6 pt dot and the remaining-time bar. |
| 5 | Text caret and the companion input's 1 pt focus underline. **Not text.** |
| 6 | Chomp's speaking ring (§3.4), as a ring only (S10). |

**Not allowed**:

| # | Where |
|---|---|
| 1 | Backgrounds, cards, headers, gradients, glows |
| 2 | **Any text**, including links and section titles |
| 3 | More than one prominent mint button in a single view or container |
| 4 | Sidebar icons and sidebar selection (monochrome; selection is the neutral `selection.sidebar` fill, S1) |
| 5 | Decorative dividers; empty-state art other than Chomp's own sparkle |
| 6 | Status success (S2). "Done" is not mint. |
| 7 | `accent.sparkle` (#2AD18F) as a UI mark in light mode, and anywhere in the menu bar |
| 8 | Any purple. #B7ADEF and #12141A are deleted. |
| 9 | A marker bar for Chomp's items, a mint ring on any avatar but Chomp's, or a mint fill on an avatar (S10) |

---

## 5. Type scale

System font (SF Pro; never SF Pro Rounded) through SwiftUI text styles, so a text-size setting scales everything. macOS default point sizes shown. **Section and page labels are sentence case everywhere.**

| Role | SwiftUI | Size / weight | Color |
|---|---|---|---|
| Window title (toolbar) | `.navigationTitle("Hoje")` | system 13 semibold | system |
| Page header ("Hoje", "Conversas") | `.title2.weight(.bold)` | 17 bold | primary |
| Page sub-line (date, count) | `.subheadline` | 11 regular | `content.meta` |
| Section header in list | `.subheadline.weight(.semibold)` | 11 semibold, sentence case | `content.meta` |
| Row title / nudge headline | `.body.weight(.semibold)` for nudge, `.body` for rows | 13 | primary |
| Nudge evidence / row detail | `.callout` | 12 regular | **primary** (S5) |
| Metadata (time, agent name, counts) | `.caption` + `.monospacedDigit()` for times | 10 regular | `content.meta` |
| Chat message | `.body`; Ajustes option "Texto maior" → `.title3` (15) | 13 / 15 | primary |
| Popover running time | `.title3.weight(.semibold).monospacedDigit()` | 15 semibold | primary |
| Popover item label | `.callout` | 12 | primary |
| Companion input | `.title3` | 15 regular | primary; placeholder `content.meta` |
| Companion agent status line | `.callout` | 12 | primary; agent name `.caption.weight(.semibold)` in `content.meta` |
| Button label | `.body.weight(.medium)` | 13 medium | `accent.onFill` on prominent, primary otherwise |
| Island compact | `.caption.weight(.medium).monospacedDigit()` | 10–11 | white 85% |
| Island expanded line | `.callout` | 12 | white 85%; metadata **white 60% (#999999, 7.37:1 on #000)** |
| Ajustes forms | `Form { }.formStyle(.grouped)`; system | 13 | system |

Banned: `design: .rounded` on UI text, any size above 17 in the window, negative tracking hacks, all-caps labels.

---

## 6. Spacing and radii

4 pt grid. Structure is native: `NavigationSplitView`, a `List` in the sidebar, a toolbar. **No cards inside cards**; the only container level is `surface.raised`.

| Token | Value | Applies to |
|---|---|---|
| `space.xxs` | 4 | Icon↔label inside controls, bar↔avatar |
| `space.xs` | 8 | Row vertical padding, button gap, avatar↔text in compact rows |
| `space.s` | 12 | Avatar↔text in nudges, inner padding of nudge rows and popover rows |
| `space.m` | 16 | Popover outer padding, companion panel padding, gap between nudges |
| `space.l` | 20 | Window content margins, gap between list sections |
| `space.xl` | 28 | Page header → first section |
| `content.maxWidth` | 720 | Readable column for Today and the chat transcript, centered |
| `row.minHeight` | 44 (event row), 28 (sidebar: system), 36 (popover row) | |
| `avatar.size` (plate diameter) | 20 (sidebar / row), 28 (nudge, companion line), 40 (companion Chomp), 64 (Team detail), 18 (island) | |
| `avatar.ringSlot` | **+12 pt** on the plate diameter (6 pt per side), always reserved: 2.5 pt ring + 1.5 pt gap = 4 pt, Increase Contrast 3.5 + 1.5 + 0.25 hairline = 5.25 pt, both fit. Island: ring 2 pt, gap 1 pt, slot **+10 pt**: 18 + 10 = 28 pt, fits the notch height (about 32 pt). | |

**Radii.** Always `RoundedRectangle(cornerRadius:, style: .continuous)`.

| Token | Value | Applies to |
|---|---|---|
| `radius.control` | system (6 for our custom button, toggle track = capsule) | Buttons, fields, segmented. System controls never overridden. |
| `radius.row` | 8 | Nudge rows, popover running rows, hover highlight |
| `radius.panel` | 16 | Companion cursor panel |
| `radius.island` | 0 at top (flush with the notch) / **12 compact, 22 expanded** at the bottom corners | Notch island |
| `radius.avatarPlate` | circle | |
| `radius.marker` | capsule (3 × 16) | Own-item marker |

`WorkspaceMetrics.cardRadius 18`, `cardInset 20` and `pageInset 30` are removed.

---

## 7. Motion spec

Rule: **chrome moves short and flat; only characters bounce.** Every animation goes through one `Motion` enum that checks Reduce Motion once.

| Interaction | Animation | Property |
|---|---|---|
| Button / row press | `.spring(duration: 0.18, bounce: 0)` | scale 0.97, opacity 0.85 |
| Hover highlight | `.easeOut(duration: 0.12)` | background fill |
| Switch / checkbox toggle | `.spring(duration: 0.2, bounce: 0)` | thumb position, track fill |
| Sidebar page change | none (system); content `.opacity` `.easeOut(0.15)` | no slide |
| Nudge arrives in Today | `.spring(duration: 0.35, bounce: 0.12)` | `.move(edge: .top).combined(with: .opacity)`, 8 pt |
| Nudge dismissed / acted on | `.spring(duration: 0.25, bounce: 0)` | `.opacity` + height collapse (List row removal) |
| Speaking ring appears | `.spring(duration: 0.3, bounce: 0)` | `trim(from:0,to:progress)` stroke draw (starts at 12 o'clock), in the reserved slot; implemented in `AvatarView` (§9) |
| Agent spawns in companion / island | `.spring(duration: 0.4, bounce: 0.3)` | **character only**: scale 0.6→1 + opacity |
| Chomp sparkle on reply | `.spring(duration: 0.5, bounce: 0.4)`, once per reply | rotate 0→12°→0, scale 1→1.15→1 |
| Character idle "breath" | `.easeInOut(duration: 3.2).repeatForever(autoreverses: true)` | scaleY 1→1.015; only while window key / panel visible |
| Companion panel open (cursor) | `.spring(duration: 0.32, bounce: 0.15)` | scale 0.94→1 anchored at cursor side + opacity |
| Companion panel close | `.spring(duration: 0.2, bounce: 0)` | opacity + scale 0.98 |
| Island compact → expanded | `.spring(duration: 0.42, bounce: 0.2)` | frame + bottom radius 12→22, `matchedGeometryEffect` for the avatar |
| Island expanded → compact | `.spring(duration: 0.32, bounce: 0)` | reversed |
| Timer digits | `.contentTransition(.numericText(countsDown: true))` with `.smooth(duration: 0.25)` | per second |
| Progress bar | `.linear(duration: 1)` per tick | width |

**Reduce Motion** (`@Environment(\.accessibilityReduceMotion)` plus the existing `islandReduceMotion`):

- Every spring becomes `.easeInOut(duration: 0.15)` on **opacity only**. No scale, move or rotate.
- The island resizes instantly and its content cross-fades over 0.15 s.
- Idle breath and sparkle twirl are **off**.
- Spinner arcs become a static 2.5 pt ring with pulsing opacity (0.4↔1, 1.2 s); `.numericText` is replaced by an instant change.

**Reduce Transparency**: materials and glass become `surface.window`; the island stays #000.

**Increase Contrast**: accent swaps to the IC values (§2.3); agent rings go to 3.5 pt with a 0.5 pt `labelColor` hairline on both edges (inside the +12 pt slot); `control.stroke` swaps to #595959 / #AAAAAA; the avatar rim and row strokes become `labelColor` 60%; separators become `labelColor` 25%.

---

## 8. Wireframes

### 8.1 Main window: Today

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ ● ● ●                          Hoje                       [⊕ Nova conversa ⌘N]│ ← toolbar
├───────────────────────┬──────────────────────────────────────────────────────┤
│ ▌Hoje             ⌘1  │                                                      │
│   Conversas       ⌘2  │   Hoje                                   (title2 bold)│
│   Equipe          ⌘3  │   quarta, 12 de novembro · 4 eventos   (subheadline) │
│   Biblioteca      ⌘4  │                                                      │
│                       │   Agora                     (subheadline semibold meta) │
│ ▸ Ferramentas         │  ┌────────────────────────────────────────────────┐  │
│                       │  │ (◎Rita)  Você está sentado há 52 min        ×  │  │ ← nudge (L)
│                       │  │  ring    Sem pausa desde 13:08 · Foco ativo    │  │   surface.raised
│                       │  │  plum    [ Levantar ]  Depois        14:00     │  │   radius 8
│                       │  └────────────────────────────────────────────────┘  │
│                       │   ● Keep Awake · termina às 16:30  ▬▬▬▬▬▬▭▭  1:12    │ ← running row (mint dot + bar)
│                       │                                                      │
│                       │   Mais cedo                                          │
│                       │  ┃(◌Ada)  Uma função em Swift, passo a passo   11:42 │ ← ┃ = Ada's marker bar
│                       │   (◌Chomp) Organizar as ideias do projeto      10:05 │   (Chomp: no marker)
│                       │   ✓  Timer de foco · 25 min concluído          09:30 │   (status: no color)
│                       │                                                      │
│ ───────────────────── │   Digite para conversar com o Chomp…                 │ ← type-to-chat hint
│ (◌) Chomp             │                                                      │
│     Pronto  ⌃⌥Space   │                                                      │
└───────────────────────┴──────────────────────────────────────────────────────┘
(▌Hoje = selected sidebar row: neutral 10% fill, filled symbol, semibold; no colour · ◌ = quiet solid neutral plate with 1 pt neutral rim, always on · ◎ = same plate + 2.5 pt agent ring OUTSIDE it, 1.5 pt gap · ┃ = 3×16 pt specialist marker bar)
```

**Notes**

- **Expanded Tools** (`DisclosureGroup`, collapsed by default and remembered in `@SceneStorage`): Agenda, Timers, Keep Awake, Captura, Área de transferência, Janelas, Tela e energia, Ajustes.
- **Sidebar**: a `List(.sidebar)` of plain button rows (`Hoje`, `Conversas`, `Equipe`, `Biblioteca`, then the Tools `DisclosureGroup`). Selection is drawn by us (S1). To keep the keyboard, the list is `.focusable()` with `.onMoveCommand` (up/down moves the selection, `Space`/`Return` opens it), each row is `.accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)`, and ⌘1-4 work from anywhere. The window **reopens on the last page used** (`@SceneStorage`), so a person who lives in Conversations lands there.
- **Conversations are one keystroke away, three ways.** (1) **⌘2** opens the Conversations list (one key chord, from any page; ⌘N starts a new conversation from any page). (2) **Type-to-chat** (zero chords) opens the *composer*, not the list: with no text field focused, any printable key in the main window starts or continues a conversation. It is implemented as an `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` installed while the main window is key, so it runs **before** the responder chain and `List`/`NSTableView` type-select cannot swallow the key. It does **not** prefill from `press.characters`: it focuses the composer (`window.makeFirstResponder`) and **forwards the original `NSEvent`** (`composer.keyDown(with:)` / `interpretKeyEvents`), so dead keys, IME composition and pt-BR accents are handled by the text system. (3) From any other app, ⌃⌥Space opens the companion. The sidebar footer shows Chomp's status and the shortcut.
- **S12 safeguard**: the monitor returns the event untouched while any `NSTextView` or `NSTextField` is first responder, while a sheet is open, while ⌘/⌃/⌥ are held, while `event.characters` is empty (a dead key starting a composition: it is forwarded as above, not consumed), and on `Escape`, `Tab` and arrow keys.

**States**

| State | What shows |
|---|---|
| Empty, first day | Header and one quiet line, "Nada por aqui ainda. Digite para conversar com o Chomp e seus dias aparecem aqui." No hero, no team grid. Chomp's 40 pt avatar sits left of the line. |
| Events only | Chronological rows: chats, timers and Keep Awake runs, real data only. "Agora" holds anything running. |
| With nudges | Pinned at the top of "Agora", at most 3. More than 3 shows "Mais 2 avisos" disclosure. |
| Nudge acted on | Row collapses (§7). A one-line event "Rita: pausa iniciada · 14:02" replaces it in "Mais cedo". |
| "Depois" | Snoozes for 20 min. The row leaves; the event log records "adiado". |
| × (dismiss) | Removed. ⌘Z undo through the system `UndoManager`. |

**Team (⌘3)** is a plain list: avatar plate, name, role, what the agent can notice, a toggle per nudge type.

### 8.2 Nudge primitive in four container sizes

```
L  (Today row)        (◎) Who · what (headline)            ×
                           evidence (callout, primary)
                           [Action]  Depois         time

M  (companion panel)  (◎) Rita  Levante-se — 52 min sentado
                           [Levantar]  Depois

S  (island expanded)  (◎) 52 min sentado     [Levantar]   ⌄

XS (island compact)   (◎)·  ← 18 pt avatar with ring only; hover or click expands to S
```

The same model drives all four sizes: `Nudge { agent, headline, evidence, action, snooze, createdAt }`. The evidence line is dropped below M. At XS the avatar has an accessibility label ("Rita: 52 min sentado") and a tooltip.

### 8.3 Menu bar popover (`MenuBarExtra(.window)`, width 300)

```
             ┌──────────────────────────────────────┐
             │ (◌Chomp) HeyChomp           Abrir ⌘O │
             ├──────────────────────────────────────┤
             │ Em andamento                          │
             │ ┌──────────────────────────────────┐ │
             │ │ ☕ Keep Awake         1:12:40     │ │ ← title3 semibold monospaced
             │ │ termina às 16:30  ▬▬▬▬▬▬▬▭▭▭      │ │   progress = accent
             │ │ [Estender ▾]          [Parar]    │ │   Estender = prominent (the one mint)
             │ └──────────────────────────────────┘ │   Parar = bordered
             │ ┌──────────────────────────────────┐ │
             │ │┃⏱ Foco (Rita)          18:02      │ │ ← ┃ Rita's marker bar + her name
             │ │ [+5 min]               [Parar]    │ │   only one prominent per popover
             │ └──────────────────────────────────┘ │
             ├──────────────────────────────────────┤
             │ Manter acordado ▸   Timer ▸           │
             ├──────────────────────────────────────┤
             │ Ajustes…  ⌘,                 Encerrar │ ← opens the main window on Tools > Ajustes
             └──────────────────────────────────────┘
```

**States**

| State | What shows |
|---|---|
| Nothing running | "Nada em andamento" (`content.meta`); the start menus stay. |
| Extend menu | +15 min, +30 min, +1 h, Até as… (opens Keep Awake in the window). |
| Stopping | Row collapses (§7). |
| Settings | The Keep Awake form and every other preference live **in the main window** (Tools > Keep Awake, Tools > Ajustes). "Ajustes…" only opens that page. |
| Menu bar icon | Two **pure template** images, no color: idle = outline blob with outline sparkle; running = solid sparkle with two rays. Shape, not hue, carries the state. |

### 8.3b Keep Awake page (main window, Tools > Keep Awake)

```
┌───────────────────────┬──────────────────────────────────────────────────────┐
│   Hoje                │   Keep Awake                                         │
│   Conversas           │   Mantém o Mac acordado enquanto você precisa        │
│   Equipe              │                                                      │
│   Biblioteca          │   Em andamento                                       │
│ ▾ Ferramentas         │   ● Termina às 16:30 · 1:12:40   [Estender ▾] [Parar]│
│     Agenda            │                                                      │
│     Timers            │   Iniciar                                            │
│   ◉ Keep Awake        │   Duração        [ 30 min | 1 h | 2 h | Até… ]       │
│     Captura           │   Tela           ( ) Pode apagar  (•) Fica acesa     │
│     …                 │                                                      │
│     Ajustes           │   Condições e retomada          (Form .grouped)      │
│                       │   Retomar ao acordar   [toggle]                      │
│                       │   Parar ao desligar a energia [toggle]               │
└───────────────────────┴──────────────────────────────────────────────────────┘
```

`Form { }.formStyle(.grouped)`; toggles use `ChompToggleStyle`. No custom cards.

### 8.4 Companion: cursor panel

A non-activating `NSPanel`: styleMask `[.nonactivatingPanel, .borderless]`, `level = .floating`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`, `canBecomeKey = true` only while the input is focused. It is positioned on the screen containing `NSEvent.mouseLocation`, offset 16 pt right and below the cursor and clamped to `visibleFrame`.

```
   ▲ cursor
    ╲
     ┌────────────────────────────────────────────┐  width 380, radius 16, surface.panel
     │ (◌ Chomp ✦)  Pergunte ao Chomp…          ⏎ │  ← title3 input, 1 pt mint underline on focus
     ├────────────────────────────────────────────┤
     │ Claro. Vou separar isso em duas partes:     │  ← Chomp reply, body, primary
     │ a Ada revisa o código e a Toni resume o     │
     │ documento.                                  │
     │                                             │
     │ (◎Ada)   Revisando Router.swift…   ◔  0:42  │  ← run arc in Ada's color, outside plate
     │ (◎Toni)  Resumo pronto · 3 pontos   ✓  Ver  │  ← done: checkmark secondary
     ├────────────────────────────────────────────┤
     │ esc fechar · ⌘↩ abrir na janela   🎙 segurar │  ← caption, content.meta
     └────────────────────────────────────────────┘
```

Because the panel is a material, its floor depends on the wallpaper. Ring contrast there is guaranteed only by the Reduce Transparency fallback; under the material the ring is backed by the plate, the rim, the agent's name and the illustration (S11).

**States**

| State | What shows |
|---|---|
| Idle-open | Input only, 56 pt tall. |
| Thinking | Chomp's sparkle does a slow 1.2 s opacity pulse (Reduce Motion: static). No typing-dots bubble. |
| Replying | Text streams in as plain text, not bubbles. |
| Agents spawned | One line each, max 4 visible, then "+2". |
| Typed vs mic | Typed input gets a text-only reply. Mic input (hold) gets a reply in the panel plus audio, per project policy. |
| Focus | Esc closes and focus returns to the previous app because the panel never activates. |

### 8.5 Companion: notch island (Macs with a notch, `NotchGeometry` / `NotchPanel`)

Compact. The notch width comes from `NSScreen.auxiliaryTopLeftArea` and `auxiliaryTopRightArea`; ears are 34 pt on each side.

```
       ┌───────┬──────────── notch ────────────┬────────┐
       │ (◌✦)  │                                │ ◔◔ 2   │   ← left: Chomp 18 pt; right: running count
       └───────┴────────────────────────────────┴────────┘     with mini agent arcs; height = notch
```

Expanded. A 300 ms hover dwell on the notch, a click on it, the shortcut, or a nudge arriving.

```
       ┌──────────────────────────────────────────────────────┐
       │                    ███ notch ███                      │ ← top flush, black #000
       │ (◌ Chomp ✦)  Pergunte ao Chomp…                    ⏎  │
       │ (◎Ada)  Revisando Router.swift…           ◔  0:42     │
       │ (◎Rita) 52 min sentado            [Levantar]  Depois  │ ← nudge size S
       └──────────────────────────────────────────────────────╯   bottom radius 22, width 440
```

**Hidden (idle) trigger, specified so it cannot break the menu bar**

- **Hover is detected with a global mouse-moved monitor** (`NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved)`), not by a window that sits in the menu bar. No view intercepts clicks.
- The hit region is **exactly the notch rectangle** (`auxiliaryTopLeftArea.maxX` to `auxiliaryTopRightArea.minX`, menu bar height). No menu title or status item can occupy that area, so nothing is shadowed, and **no side or bottom margin** is used.
- **Suppressed** when any of these holds: `NSEvent.pressedMouseButtons != 0` (this also covers menu tracking and drags, since opening a menu needs a click); pointer speed above 600 pt/s (a pointer crossing, not a stop); the active Space is a full-screen app whose menu bar is hidden; `NSWorkspace.shared.frontmostApplication` is in full-screen presentation; the user setting "Notch do Chomp" is off.
- **Click on the notch** is delivered by the same global monitor (`.leftMouseDown` inside the rectangle); the area has no other click target.
- **The island panel** (once shown): `NSPanel`, `.nonactivatingPanel`, `level = .statusBar`, `collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]`, `canBecomeKey = true` only when expanded with an input, `hidesOnDeactivate = false`. While compact and idle there is **no panel at all** unless the setting "Mostrar o Chomp ao lado do notch" (default off) keeps the ears visible.

**States**

| State | What shows |
|---|---|
| Hidden (idle) | Nothing is drawn: the notch looks untouched. |
| Compact | Something is running or a nudge is pending → ears. |
| Expanded | As above. |
| Collapsing | Collapses on mouse-out after 1.5 s, or Esc. |
| Contents | The same SwiftUI `CompanionView` as the cursor panel, with `\.companionContainer = .island`. That forces dark tokens and swaps radius and size. |
| No notch / external display | The cursor panel is used. Both are fed by the same view model, so a run started in one shows in the other. |

---

## 9. Implementation (drop-in for `DesignSystem.swift`)

```swift
import SwiftUI
import AppKit

// MARK: Colors
enum HC {
    // System semantic (do not hardcode)
    static let content   = Color(nsColor: .textBackgroundColor)
    static let window    = Color(nsColor: .windowBackgroundColor)
    static let raised    = Color(nsColor: .quaternarySystemFill)
    static let control   = Color(nsColor: .secondarySystemFill)
    static let primary   = Color(nsColor: .labelColor)
    static let secondary = Color(nsColor: .secondaryLabelColor)   // glyphs / ornaments only
    static let tertiary  = Color(nsColor: .tertiaryLabelColor)    // disabled only
    static let separator = Color(nsColor: .separatorColor)
    static let error     = Color(nsColor: .systemRed)             // glyph only

    // Custom
    static let island      = Color.black
    static let sparkle     = Color(hex: 0x2AD18F)                 // art only
    static let meta        = dyn(light: 0x595959, dark: 0xA0A0A0, icLight: 0x404040, icDark: 0xC0C0C0)
    static let accent      = dyn(light: 0x00945F, dark: 0x3EDC9A, icLight: 0x00583A, icDark: 0x6FF0B8)
    static let onAccent    = dyn(light: 0x00150C, dark: 0x04170F, icLight: 0xFFFFFF, icDark: 0x04170F)
    static let plate       = dyn(light: 0xEDEDF0, dark: 0x303030, icLight: 0xE0E0E4, icDark: 0x444444)
    static let plateIsland = Color(hex: 0x2A2A2A)
    static let controlStroke = dyn(light: 0x7A7A7A, dark: 0x8A8A8A, icLight: 0x595959, icDark: 0xAAAAAA)
    /// Sidebar selection: neutral, never a hue (S1).
    static func selection(active: Bool) -> Color { Color(nsColor: .labelColor).opacity(active ? 0.10 : 0.06) }

    static func dyn(light: UInt32, dark: UInt32, icLight: UInt32? = nil, icDark: UInt32? = nil) -> Color {
        Color(nsColor: NSColor(name: nil) { ap in
            switch ap.bestMatch(from: [.darkAqua, .aqua, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastAqua]) {
            case .accessibilityHighContrastDarkAqua: return NSColor(hex: icDark ?? dark)
            case .accessibilityHighContrastAqua:     return NSColor(hex: icLight ?? light)
            case .darkAqua:                          return NSColor(hex: dark)
            default:                                 return NSColor(hex: light)
            }
        })
    }
    /// Rim: black 50% light, white 45% dark (3.75:1 or better against every floor).
    static let rim = Color(nsColor: NSColor(name: nil) { ap in
        ap.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor.white.withAlphaComponent(0.45)
                                                            : NSColor.black.withAlphaComponent(0.50)
    })
}

extension LocalChatPersona {
    /// Non-text marks only (ring, run arc, marker bar). Never text, never fills.
    var mark: Color {
        switch self {
        case .sig:    HC.accent
        case .rita:   HC.dyn(light: 0x61216D, dark: 0xDB9CF6)
        case .ada:    HC.dyn(light: 0x0B6A87, dark: 0x1497A5)
        case .gantt:  HC.dyn(light: 0x775113, dark: 0xF3E334)
        case .elinor: HC.dyn(light: 0xCC5F01, dark: 0xCF7B03)
        case .toni:   HC.dyn(light: 0x2806BF, dark: 0xA96EFC)
        }
    }
    /// Chomp has no list marker (S10).
    var hasItemMarker: Bool { self != .sig }
}

// MARK: Controls (all ours; System accent cannot leak in, S1)
struct ChompProminentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduce
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(HC.onAccent)
            .padding(.horizontal, 12).frame(minHeight: 22)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(HC.accent))
            .opacity(enabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
            .scaleEffect(configuration.isPressed && !reduce ? 0.97 : 1)
            .animation(Motion.pick(Motion.press, reduce: reduce), value: configuration.isPressed)
    }
}

struct ChompToggleStyle: ToggleStyle {
    enum Kind { case `switch`, checkbox }
    var kind: Kind = .switch
    @Environment(\.accessibilityReduceMotion) private var reduce
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            Button { configuration.isOn.toggle() } label: {
                switch kind {
                case .switch:
                    // Off: 1.5 pt control.stroke outline + stroke-coloured knob (>= 3.3:1 on every floor).
                    // On: accent track + onAccent knob (4.85:1 light, 10.5:1 dark). Never a white knob on mint.
                    ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                        Capsule().fill(configuration.isOn ? HC.accent : Color.clear)
                        Capsule().strokeBorder(configuration.isOn ? Color.clear : HC.controlStroke, lineWidth: 1.5)
                        Circle().fill(configuration.isOn ? HC.onAccent : HC.controlStroke)
                            .frame(width: 12, height: 12).padding(.horizontal, 4)
                    }
                    .frame(width: 36, height: 20)
                case .checkbox:
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(configuration.isOn ? HC.accent : Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(configuration.isOn ? Color.clear : HC.controlStroke, lineWidth: 1.5))
                        .overlay { if configuration.isOn { Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(HC.onAccent) } }
                        .frame(width: 16, height: 16)
                }
            }
            .buttonStyle(.plain)
            .animation(Motion.pick(.spring(duration: 0.2, bounce: 0), reduce: reduce), value: configuration.isOn)
            configuration.label
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isToggle)          // macOS 14+: system supplies the localized on/off value
    }
}

struct ChompProgressBar: View {          // 4 pt capsule; progress 0...1
    var progress: Double
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(HC.control)
                Capsule().fill(HC.accent).frame(width: g.size.width * max(0, min(1, progress)))
            }
        }.frame(height: 4)
    }
}

/// Specialist marker bar (S10). Rendered only when persona.hasItemMarker.
struct AgentMarker: View {
    let persona: LocalChatPersona
    var body: some View {
        if persona.hasItemMarker { Capsule().fill(persona.mark).frame(width: 3, height: 16) }
    }
}

/// Avatar: quiet solid neutral plate + 1 pt neutral rim, always. The agent ring is drawn OUTSIDE the plate,
/// separated by a gap, so its contrast is against the window floor (S3b). Slot is constant (size + 12, island + 10).
struct AvatarView: View {
    let persona: LocalChatPersona
    var size: CGFloat = 28
    var speaking = false
    var onIsland = false
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduce
    @State private var drawn: CGFloat = 0
    var body: some View {
        let ring: CGFloat = onIsland ? (contrast == .increased ? 3 : 2) : (contrast == .increased ? 3.5 : 2.5)
        let gap: CGFloat = onIsland ? 1 : 1.5
        let slot = size + (onIsland ? 10 : 12)
        let d = size + 2 * gap + ring                      // ring path diameter; outer extent d + ring (+0.25 hairline) <= slot
        ZStack {
            Circle().fill(onIsland ? HC.plateIsland : HC.plate).frame(width: size, height: size)
            Circle().strokeBorder(HC.rim, lineWidth: 1).frame(width: size, height: size)
            persona.illustration.resizable().scaledToFit()
                .frame(width: size, height: size).padding(max(size * 0.06, 1.5))
            Circle().trim(from: 0, to: reduce ? 1 : drawn)
                .stroke(persona.mark, style: StrokeStyle(lineWidth: ring, lineCap: .round))
                .rotationEffect(.degrees(-90)).frame(width: d, height: d)
                .opacity(speaking ? 1 : 0)
            if speaking && contrast == .increased {
                Circle().stroke(HC.primary, lineWidth: 0.5).frame(width: d + ring, height: d + ring)
                Circle().stroke(HC.primary, lineWidth: 0.5).frame(width: d - ring, height: d - ring)
            }
        }
        .frame(width: slot, height: slot)
        .onChange(of: speaking) { _, on in
            withAnimation(Motion.pick(Motion.ring, reduce: reduce)) { drawn = on ? 1 : 0 }   // Reduce Motion: opacity only
        }
        .animation(Motion.pick(Motion.ring, reduce: reduce), value: speaking)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(persona.displayName)
        .help(persona.displayName)
    }
}
// Island: wrap its content in .environment(\.colorScheme, .dark) so dyn() resolves dark values.

// MARK: Metrics
enum Space { static let xxs: CGFloat = 4, xs: CGFloat = 8, s: CGFloat = 12, m: CGFloat = 16, l: CGFloat = 20, xl: CGFloat = 28 }
enum Radius { static let row: CGFloat = 8, panel: CGFloat = 16, islandCompact: CGFloat = 12, islandExpanded: CGFloat = 22 }
enum Layout { static let readableWidth: CGFloat = 720 }

// MARK: Motion
enum Motion {
    static let press       = Animation.spring(duration: 0.18, bounce: 0)
    static let nudgeIn     = Animation.spring(duration: 0.35, bounce: 0.12)
    static let nudgeOut    = Animation.spring(duration: 0.25, bounce: 0)
    static let ring        = Animation.spring(duration: 0.30, bounce: 0)
    static let character   = Animation.spring(duration: 0.40, bounce: 0.30)
    static let sparkle     = Animation.spring(duration: 0.50, bounce: 0.40)
    static let panelIn     = Animation.spring(duration: 0.32, bounce: 0.15)
    static let panelOut    = Animation.spring(duration: 0.20, bounce: 0)
    static let islandOpen  = Animation.spring(duration: 0.42, bounce: 0.20)
    static let islandClose = Animation.spring(duration: 0.32, bounce: 0)
    static let reduced     = Animation.easeInOut(duration: 0.15)
    static func pick(_ a: Animation, reduce: Bool) -> Animation { reduce ? reduced : a }
}
```

`Color(hex:)` and `NSColor(hex:)` are 5-line helpers. The asset catalog gets an **`AccentColor` set = mint** (light #00945F, dark #3EDC9A, with the Increase Contrast variants #00583A / #6FF0B8) and `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor`, so system-drawn leftovers are mint for Multicolor users (S1). The sidebar does not use the system selection.

Menu commands:

```swift
.commands {
    CommandGroup(replacing: .appSettings) { Button("Ajustes…") { router.open(.ajustes) }.keyboardShortcut(",") }
    CommandMenu("Ir") {
        Button("Hoje") { router.open(.today) }.keyboardShortcut("1")
        Button("Conversas") { router.open(.conversations) }.keyboardShortcut("2")
        Button("Equipe") { router.open(.team) }.keyboardShortcut("3")
        Button("Biblioteca") { router.open(.library) }.keyboardShortcut("4")
        Button("Nova conversa") { router.newChat() }.keyboardShortcut("n")
    }
}
// Type-to-chat: a local key monitor, installed while the main window is key (S12, §8.1). It never reads press.characters.
// final class TypeToChat { var token: Any?
//   func install(window: NSWindow, router: Router) {
//     token = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { e in
//       guard e.window === window, window.attachedSheet == nil,
//             !(window.firstResponder is NSText), !(window.firstResponder is NSTextField),
//             e.modifierFlags.intersection([.command, .control, .option]).isEmpty,
//             ![53, 48, 123, 124, 125, 126].contains(e.keyCode) else { return e }   // esc, tab, arrows
//       router.focusComposer()                       // makeFirstResponder(composer)
//       window.firstResponder?.keyDown(with: e)      // text system handles dead keys / IME
//       return nil } }
//   func remove() { if let t = token { NSEvent.removeMonitor(t) } } }
```

### Migration checklist

1. Delete `CompanionStyle.background/surface/sidebar/accent/accentInk/muted`, `WorkspaceTypography.hero`, the rounded `title`, `WorkspacePageHeading`'s hero use, and the old capsule button and toggle styles (lines ~140-165). Replace them with `ChompProminentButtonStyle`, `.bordered`, and `ChompToggleStyle`. Replace the system sidebar selection with `HC.selection(active:)` rows (S1).
2. Replace `CompanionWorkspaceHome` (hero, team grid, "Conversas" block) with the Today `List` (§8.1). Move the team grid to Team (⌘3).
3. Move the Keep Awake form to Tools > Keep Awake (§8.3b) and the other Preferências rows to Tools > Ajustes. Delete the `Settings` scene.
4. Add the commands above. Set the default companion shortcut to ⌃⌥Space.
5. The island uses `.environment(\.colorScheme, .dark)`, `HC.island`, `HC.plateIsland`, and the global-monitor trigger (§8.5).
6. Replace the menu bar icon with the two template images (§8.3).
7. Verify on a **macOS 14.6** machine or VM and on 26+: Accessibility Inspector in light, dark and Increase Contrast; **sample the real blob body color from the atlas and apply the §0 plate gate**; check rings and marker bars with Sim Daltonism at 100% and 200% scale; confirm the sidebar looks identical under Multicolor, Graphite and Red (only focus ring, Slider and text selection may differ); type "é" and an IME sequence with no field focused and check the composer receives it intact; re-run Appendix A after any hex change.

---

## 10. Why this is HeyChomp and not an AI-app template

1. **The template's signature is gone.** ChatGPT-style apps share one shape: a big centered question ("Por onde vamos começar?"), a pill composer, one brand-tinted primary button, and a dark slate background with a lavender/purple accent. All four are removed. HeyChomp opens on **your day as a list of real events**, the way Things opens on Today. You start a conversation by typing, not by facing a hero.
2. **The only expressive thing is a cast you can name.** No generic AI app has six characters whose colors come from their own props: Rita's book (plum), Ada's tag (cyan-teal), Gantt's hat, Elinor's gem, Toni's headphones (indigo/violet), Chomp's sparkle. Those colors appear **only when that character is speaking or owns the item**, so color answers *who*. In template apps color only says "brand".
3. **The accent is a physical object from the mascot.** Mint is Chomp's sparkle, kept at the sparkle's own hue in both modes, not a "tech" hue from a palette generator. It marks the one action to take, things that are running, and Chomp's ring. It never appears as text or as a background.
4. **The product primitive is the nudge, not the chat bubble.** "Rita noticed 52 min sitting → Levantar" is a companion that watches your Mac day and proposes one action with evidence, in the same shape in a window row, the cursor panel and the notch.
5. **It lives in Mac-only places.** In the notch as an island, in the menu bar with the time left, and in a non-activating panel next to the cursor that never steals focus. It uses system colors, system type and system structure in light and dark, and adds only the characters.

---

## Appendix A. Contrast and color-vision script (Python 3, numpy)

Prints the ratio of a hex against a floor and the minimum ΔEok over all pairs and the three simulations. Re-run after any hex change.

```python
import numpy as np, itertools
s2l=lambda c:np.where(c<=0.04045,c/12.92,((c+0.055)/1.055)**2.4)
hx=lambda h:np.array([(h>>16)&255,(h>>8)&255,h&255])/255
lin=lambda h:s2l(hx(h))
lum=lambda l:0.2126*l[0]+0.7152*l[1]+0.0722*l[2]
def cr(a,b):                      # WCAG 2.x contrast of two hex ints
    x,y=sorted((lum(lin(a)),lum(lin(b))),reverse=True); return (x+.05)/(y+.05)
M1=np.array([[.4122214708,.5363325363,.0514459929],[.2119034982,.6806995451,.1073969566],[.0883024619,.2817188376,.6299787005]])
M2=np.array([[.2104542553,.7936177850,-.0040720468],[1.9779984951,-2.4285922050,.4505937099],[.0259040371,.7827717662,-.8086757660]])
SIM={'p':[[.152286,1.052583,-.204868],[.114503,.786281,.099216],[-.003882,-.048116,1.051998]],
     'd':[[.367322,.860646,-.227968],[.280085,.672501,.047413],[-.011820,.042940,.968881]],
     't':[[1.255528,-.076749,-.178779],[-.078411,.930809,.147602],[.004733,.691367,.303900]]}
def lab(h,m=None):                # OKLab of a hex, optionally under a Machado 2009 simulation
    l=lin(h); l=np.clip(np.array(SIM[m])@l,0,1) if m else l
    return M2@np.cbrt(M1@l)
def min_dist(hexes):              # worst pair x {normal, protan, deutan, tritan}
    return min(np.linalg.norm(lab(a,m)-lab(b,m)) for a,b in itertools.combinations(hexes,2) for m in (None,'p','d','t'))
LIGHT=[0x00945F,0x61216D,0x0B6A87,0x775113,0xCC5F01,0x2806BF]   # chomp, rita, ada, gantt, elinor, toni
DARK =[0x3EDC9A,0xDB9CF6,0x1497A5,0xF3E334,0xCF7B03,0xA96EFC]
print(min_dist(LIGHT), min_dist(DARK))                            # 0.097, 0.123
print([round(cr(c,f),2) for c in LIGHT for f in (0xFFFFFF,0xECECEC,0xE3E3E3)])
print([round(cr(c,f),2) for c in DARK  for f in (0x1E1E1E,0x282828,0x000000)])
print(cr(0x00945F,0x00150C), cr(0x3EDC9A,0x04170F))               # label on accent: 4.85, 10.5
print([round(cr(0x7A7A7A,f),2) for f in (0xFFFFFF,0xECECEC,0xE3E3E3)], [round(cr(0x8A8A8A,f),2) for f in (0x1E1E1E,0x282828)])  # control.stroke: 4.29 3.63 3.34 / 4.83 4.27
```

The search that produced the specialists' hexes is a hill climb over OKLCH (L, C, h) for the five specialists, with Chomp fixed to the accent, inside the hue windows (the same window in both modes: Rita 305-345°, Ada 200-225°, Gantt 70-105°, Elinor 50-68°, Toni 262-300°), lightness windows (light L 0.38-0.74, dark L 0.62-0.90), chroma floor 0.10 / 0.11, rejecting any draw outside sRGB or below 3.05:1 on any floor (started from the art-derived values, 4 restarts), and maximizing `min_dist`. §3.2 and §3.3 are this script's output.
