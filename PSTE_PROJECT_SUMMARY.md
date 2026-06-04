# Project PSTE -- Point, Solve, Think, Escape 

## What is this??
A **point-and-click adventure game** built in **Godot 4.6** with **C++ GDExtension** (godot-cpp).
The game is called **"Escape from CSB"** — a school escape game where the player navigates floors of a building, completes minigames, and tries to escape.

## Tech Stack
- **Godot 4.6** (standard build)
- **C++ via GDExtension** (godot-cpp, built with SCons)
- **GDScript** for scene logic, UI, room scripts
- **GitHub repo**: https://github.com/floorsdmayo/cmsc-pste

## Project Structure
```
cmsc-pste/
├── src/                        # C++ source files
│   ├── register_types.h/.cpp   # GDExtension entry point
│   ├── wirefixer.h/.cpp        # WireFixer minigame logic (C++)
│   ├── snake_game.h/.cpp       # Snake/Boss minigame logic (C++)
│   └── pong_game.h/.cpp        # Pong minigame logic (C++)
├── game/
│   ├── godot-pste/             # Godot project folder
│   │   ├── scenes/
│   │   │   ├── rooms/          # Floor1-6.tscn
│   │   │   ├── minigames/      # WireFixerGame.tscn, SnakeGame.tscn,
│   │   │   │                   # FindTheDifferenceGame.tscn, RunAwayGame.tscn
│   │   │   └── ui/             # HUD.tscn
│   │   ├── scripts/
│   │   │   ├── GameManager.gd  # Autoload singleton
│   │   │   ├── FloorBase.gd    # Base class for all floors
│   │   │   ├── HUD.gd
│   │   │   ├── Main.gd
│   │   │   ├── rooms/          # Floor1.gd - Floor6.gd
│   │   │   └── minigames/      # WireFixer.gd, SnakeGame.gd, SnakeBoard.gd,
│   │   │                       # find_the_difference.gd, run_away.gd
│   │   ├── assets/
│   │   │   └── images/
│   │   │       └── minigames/  # left_image.jpg, right_image_enhanced.png (FtD images)
│   │   ├── bin/                # Compiled .dll lives here
│   │   └── pste.gdextension
│   └── bin/                    # SCons outputs .dll here, copy to godot-pste/bin/
├── godot-cpp/                  # Submodule
└── SConstruct
```

## Build Command
```bash
cd ~/OneDrive/Documents/GitHub/cmsc-pste
python -m SCons
cp game/bin/pste.windows.template_debug.x86_64.dll game/godot-pste/bin/
```
Then reload project in Godot.

## C++ Classes (GDExtension)
| Class | File | Purpose |
|---|---|---|
| `WireFixer` | wirefixer.h/.cpp | Wire matching logic for WireFixer minigame |
| `SnakeLogic` | snake_game.h/.cpp | Snake game logic (phases, walls, statues, light) |
| `PongLogic` | pong_game.h/.cpp | Pong game logic (ball, Alex AI paddle) |

## Game Flow
```
Start at Floor 6 (player spawns here, respawns here on feint)
      → Floor 5 (Wirefixer minigame, Bench, Ate Girl NPC) [Jan]
      → Floor 4 (Memory Game) [Uzi]
      → Floor 3 (Lockpicker) [Uzi]
      → Floor 2 (Jigsaw) [Uzi]
      → Floor 1 (Find the Difference — secret condition: pick diff3 first + under 6.7s)
            → Default ending: dialogue → Floor 0 (The Gate)
            → Secret ending: adrenaline triggered → Floor 7 (true ending)
      → Floor 0 (Run Away minigame — final boss vs The Guard)
      → Floor 7 (true ending scene) [adrenaline only]

Stamina gating (natural, no hard locks):
  Base 10 → after each minigame +5 max → Floor 1 reachable only after all 5 clears
  Feint (stamina runs out) → respawn Floor 6, keep all upgrades
  Death (hearts == 0) → respawn Floor 6, keep all upgrades
```

## Stamina System (C++ GDExtension) ✅ IMPLEMENTED
- C++ class: `PSTEStamina` (in `src/stamina_system.h/.cpp`)
- Registered via `register_types.cpp`
- Autoload name: `PSTEStamina` (loaded as `player_stamina.tscn` which has PSTEStamina as root node)
- `GameManager.gd` is now a thin GDScript wrapper — all stamina logic lives in C++
- Access via `GameManager.ss` anywhere in GDScript

### Stamina Values
- Base max stamina: 10
- Stair cost (go down): 8 per floor
- Per minigame first-clear bonus: +5 max stamina + full refill
- Hard cap: 35 (allows reaching Floor 1 after all 5 minigames)
- Adrenaline surge (secret ending): +20 temporary above max

### Key Methods (call via GameManager.ss)
- `get_stamina()`, `get_max_stamina()`, `get_hearts()`, `get_max_hearts()`
- `try_go_down(floor_number)` → bool (emits player_exhausted if insufficient)
- `go_up()` → free, no cost
- `on_minigame_cleared(minigame_id)` → +5 max, full refill, one-time only
- `is_minigame_cleared(minigame_id)` → bool
- `trigger_adrenaline()` → secret ending surge
- `is_adrenaline_active()` → bool
- `rest()`, `respawn()` → refill stamina+hearts, keep upgrades
- `lose_heart()`, `gain_heart()`

### Signals (connect via GameManager which re-emits them)
- `stamina_changed(new_value)`, `hearts_changed(new_value)`
- `player_exhausted` → feint, respawn at Floor 6, keep all upgrades
- `player_died` → hearts == 0 only
- `adrenaline_triggered`

### Minigame IDs (must match exactly for on_minigame_cleared)
- Floor 5: `"wirefixer"`
- Floor 4: `"memory"`
- Floor 3: `"lockpicker"`
- Floor 2: `"jigsaw"`
- Floor 1: `"find_the_difference"`

## GameManager (Autoload) ✅ UPDATED
- Name: `GameManager`
- File: `res://scripts/GameManager.gd`
- Key variables: `current_floor` (starts at 6), `secret_key`, `inventory`, `game_flags`
- Key methods: `change_room()`, `launch_minigame()`, `try_go_down()`, `go_up()`, `rest_at_bench()`, `gain_stamina()`, `lose_heart()`, `set_flag()`, `get_flag()`
- Signals: `stamina_changed`, `hearts_changed`, `minigame_completed`
- `elevator_unlocked` var REMOVED (elevator scrapped)
- `_on_player_exhausted` shows HUD message only, does NOT respawn
- `_do_respawn` called only on hearts == 0

## FloorBase ✅ UPDATED
- File: `res://scripts/FloorBase.gd`
- class_name: `FloorBase`
- Each floor script extends `FloorBase`
- Export var: `floor_number` only (`stair_cost` removed — cost hardcoded in C++)
- Methods: `go_up()`, `go_down()`, `_update_button()`, `_on_stamina_changed()`
- StairsDownButton auto-updates text and color based on current stamina vs cost (8)
- go_up() blocks floor 6→7 unless adrenaline active

## Minigame Template
Every minigame must follow this exact structure:
```gdscript
extends Control
const minigame_id = "unique_id"
signal completed(success: bool)

func _ready():
    get_tree().get_first_node_in_group("room_container").hide()

func _on_win():
    get_tree().get_first_node_in_group("room_container").show()
    completed.emit(true)

func _on_lose_or_give_up():
    get_tree().get_first_node_in_group("room_container").show()
    completed.emit(false)
```
- Save scenes to `res://scenes/minigames/`
- Save scripts to `res://scripts/minigames/`

## Completed Minigames
### WireFixer (Floor 5) ✅
- C++ class: `WireFixer`
- Scene: `res://scenes/minigames/WireFixerGame.tscn`
- Script: `res://scripts/minigames/WireFixer.gd`
- Logic: Match 4 colored wires left to right. Click left wire then matching right wire.
- Win: All 4 matched → gain stamina +3

### Snake Boss (Floor 6) ✅ — in progress
- C++ classes: `SnakeLogic`, `PongLogic`
- Scene: `res://scenes/minigames/SnakeGame.tscn`
- Script: `res://scripts/minigames/SnakeGame.gd`, `SnakeBoard.gd`
- Boss: Sssir Rrryan
- Score: +2 per apple, win at 67/8
- Phases:
  - Phase 1 (0-22): Light mode (darkness overlay, radius around head)
  - Phase 2 (22-44): Wall mode (walls spawn every other apple)
  - Phase 3 (44-68): Statue mode (tail leaves stone behind, breaks after 2+ apples)
- After winning Snake → Pong phase (Alex Eala summoned)
  - Snake body = your paddle on the left
  - Alex Eala AI paddle on the right
  - First to 7 points wins
- Taunts defined in SnakeGame.gd

### Memory Game (Floor 4) ✅
- Connected to floor system by Uzi
- Scene: `res://scenes/minigames/memory.tscn`

## Pending / In Progress Minigames
| Minigame | Floor | Member | Status |
|---|---|---|---|
| Find the Difference | 1 | Jan | In progress — see notes below |
| Run Away (The Gate) | Ground | Jan | Script written, scene not built yet |
| Lockpicker | 3 | Uzi | Not started |
| Jigsaw Puzzle | 2 | Uzi | Not started |

## Find the Difference — Implementation Notes
- Scene: `res://scenes/minigames/FindTheDifferenceGame.tscn`
- Script: `res://scripts/minigames/find_the_difference.gd`
- Images: `res://assets/images/minigames/left_image.jpg` and `right_image_enhanced.png`
- Base resolution: **1152x648**, images display at **575x575** each side by side
- `total_differences` export var = 4 (set in Inspector, not hardcoded)
- Fast clear threshold: 30 seconds → sets `GameManager.secret_boss_unlocked = true`

### Scene Tree Structure
```
FindTheDifferenceGame (Control)
 └─ MarginContainer
     └─ VBox (VBoxContainer)
         ├─ HBox (HBoxContainer)
         │   ├─ LeftImage (TextureRect)   ← stretch: KEEP_ASPECT_COVERED, clip: true
         │   │   ├─ Diff1 (Area2D) [group: difference_hotspot] [meta: diff_id = 1]
         │   │   │   └─ CollisionShape2D (RectangleShape2D) ← Make Unique per diff!
         │   │   ├─ Diff2 ... Diff4 (same pattern, diff_id 2-4)
         │   └─ RightImage (TextureRect)  ← same settings as LeftImage
         │       ├─ Diff1 ... Diff4       ← SAME diff_id values as LeftImage counterparts
         ├─ StatusLabel (Label)
         └─ TimerLabel (Label)
```

### Critical Setup Rules for Find the Difference
1. **Mouse Filter** on both TextureRect nodes must be set to **Pass** (not Stop)
2. Each CollisionShape2D must have **Make Unique** applied (or they share the same shape resource and all resize together)
3. Area2D nodes need **Input Pickable = ON**
4. Both images should be **cropped to the same resolution** before importing — mismatched resolutions cause collision position offset issues
5. Collision detection uses `col_shape.global_position` directly (no manual scale math needed if images are same size)
6. Only right image clicks are processed — left image is display only
7. Wrong clicks inside right image (but outside hotspots) cost a heart via `GameManager.lose_heart()`

### Known Issues
- Image UID mismatch warning on `right_image_enhanced.png` — fix by reassigning texture in Inspector and reimporting
- If collider positions appear offset from visual differences, ensure both images are the same crop/resolution

## Run Away — Implementation Notes
- Scene: `res://scenes/minigames/RunAwayGame.tscn` (not built yet)
- Script: `res://scripts/minigames/run_away.gd` ✅ written (fully in-script, no scene tree needed)
- Triggered at Floor 0 (The Gate) after default ending dialogue
- Mechanic: Press Space when yellow indicator is in green safe zone, 10 rounds
- Each round config defined in ROUND_CONFIG array (speed, safe_start, safe_end)
- Miss = lose heart + fail, complete all 10 = win
- Visual: tunnel with light at end growing closer as rounds progress
- Audio: heartbeat/breath sounds generated programmatically (no audio files needed)
- Scene tree: just a plain Control node, everything built in _ready()

### Secret Ending Condition (Find the Difference)
- Player must click diff_id == 3 FIRST
- AND complete all differences in under 6.7 seconds
- If met: `GameManager.ss.trigger_adrenaline()` is called in `_on_win()`
- Adrenaline allows go_up() from Floor 1 → Floor 7

## Floor Unlock Logic (UPDATED)
- Game starts at Floor 6 (no unlock needed)
- Floors 6→2 freely explorable in any order via go_up/go_down
- Going DOWN costs 8 stamina; going UP is free
- Floor 1 reachable only after all 5 minigames cleared (stamina math enforces this)
- Floor 7 reachable only via adrenaline (secret ending condition in Find the Difference)
- Floor 0 reachable via default ending dialogue after Floor 1 minigame
- Elevator: SCRAPPED entirely

## Known Issues / TODO
- [ ] Run Away — build scene in Godot (just plain Control node, script does everything)
- [ ] Run Away — tunnel visual + heartbeat audio (in progress this session)
- [ ] Statue visibility added to SnakeBoard.gd — test needed
- [ ] Snake game layout — black box on side of screen, fix with assets later
- [ ] Pong transition working but snake doesn't block ball properly yet
- [ ] All floor scenes need real backgrounds
- [ ] HUD positioning needs cleanup
- [ ] Ate girl NPC dialogue not built yet (Hya)
- [ ] Maintenance Guy NPC not built yet (now irrelevant? confirm with team)
- [ ] Find the Difference — finalize collision placement after image crop fix
- [ ] Find the Difference — fast clear condition updated: diff3 first + under 6.7s (was 30s)
- [ ] Floor 1 script — Dialogic timeline names needed from Hya: "default_ending_dialogue" and "secret_ending_dialogue"
- [ ] Debug menu added (res://scripts/DebugMenu.gd) — REMOVE before final build
- [ ] HUD show_exhaustion_message() method needs implementing
- [ ] Snake/Floor 7 scene needs building (true ending)
- [ ] Floor 0 scene needs building (The Gate + Run Away trigger)

## WHERE WE LEFT OFF (session handoff)
**Last thing working:** Stamina system fully wired. Floor traversal working with stamina gating. StairsDownButton shows live stamina vs cost. Feint on exhaustion sends to Floor 6. Debug menu working.

**Next immediate tasks:**
1. Finish `run_away.gd` tunnel visual + heartbeat audio (in progress)
2. Implement `show_exhaustion_message()` in HUD.gd
3. Get Dialogic timeline names from Uzi, wire into every Floor.gd
4. Make the UI for all minigames less janky (snake, find the difference)

**Build reminder:**
```bash
cd ~/OneDrive/Documents/GitHub/cmsc-pste
scons
# dll auto-outputs to game/godot-pste/bin/ now (SConstruct fixed)
```
Close Godot before compiling. Reopen after.

## Team
- **Jan** — Core game, floors, WireFixer ✅, Snake ✅, Find the Difference (in progress), Run Away (script done)
- **Uzi** — Memory Game ✅, Lockpicker, Jigsaw Puzzle
- **Hya** — PPT/game flow presentation, NPC dialogue