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
Start → Floor 5 (Wirefixer, Bench, Ate Girl NPC) [Jan]
      → Floor 4 (Memory Game) [Uzi]
      → Floor 3 (Lockpicker) [Uzi]
      → Floor 2 (Jigsaw) [Uzi]
      → Floor 1 (Find the Difference, Maintenance Guy, The Gate) [Jan]
      → Secret: Floor 6 (Snake Boss — Sssir Rrryan) [unlocked by beating FtD fast] [Jan]
      → The Gate (Final Boss — Run Away) [Jan]
```

## GameManager (Autoload)
- Name: `GameManager`
- File: `res://scripts/GameManager.gd`
- Key variables: `stamina`, `hearts`, `current_floor`, `game_flags`
- Key methods: `change_room()`, `launch_minigame()`, `use_stairs()`, `rest_at_bench()`, `gain_stamina()`, `lose_heart()`, `set_flag()`, `get_flag()`
- Signals: `stamina_changed`, `hearts_changed`, `minigame_completed`
- Stair costs: Floor 5→4: 3, 4→3: 3, 3→2: 3, 2→1: 3 (total 12, max stamina 10 = can't reach Floor 1 without resting/minigames — intentional ragebait)
- **NOTE**: There is a temp line `game_flags["floor6_unlocked"] = true` in `_ready()` for testing. Remove this when Find the Difference fast-clear unlock is implemented.

## FloorBase
- File: `res://scripts/FloorBase.gd`
- class_name: `FloorBase`
- Each floor script extends `FloorBase`
- Export vars: `floor_number`, `stair_cost`
- Methods: `go_up()`, `go_down()`

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
- Script: `res://scripts/minigames/run_away.gd` ✅ written
- Triggered at The Gate on Floor 1 (final boss vs The Guard)
- Mechanic: Press Space when indicator is in green zone to advance across 5 squares
- Each square makes the indicator faster
- Miss = lose, complete all 5 = win

### Scene Tree Structure Needed
```
RunAwayGame (Control)
 └─ MarginContainer
     └─ VBox (VBoxContainer)
         ├─ InstructionLabel (Label)
         ├─ BarContainer (Control)        ← fixed size e.g. 600x40
         │   ├─ SafeZone (ColorRect)      ← green, positioned by script
         │   └─ IndicatorBar (ColorRect)  ← red/white, moved by script
         ├─ SquaresContainer (HBoxContainer) ← script auto-fills with 5 squares
         └─ ResultLabel (Label)
```

## Floor Unlock Logic
- Floor 6 unlocked by: beating Find the Difference under 30s OR elevator (Maintenance Guy on Floor 1)
- Flag: `GameManager.set_flag("floor6_unlocked", true)`
- Floor 5 StairsUp disabled until `floor6_unlocked` is true

## Known Issues / TODO
- [ ] Remove temp `game_flags["floor6_unlocked"] = true` from GameManager._ready() when FtD fast-clear is done
- [ ] Statue visibility added to SnakeBoard.gd — test needed
- [ ] Snake game layout — black box on side of screen, fix with assets later
- [ ] Pong transition working but snake doesn't block ball properly yet
- [ ] All floor scenes need real backgrounds
- [ ] HUD positioning needs cleanup
- [ ] Ate girl NPC dialogue not built yet (Hya)
- [ ] Maintenance Guy NPC not built yet
- [ ] Find the Difference — finalize collision placement after image crop fix
- [ ] Run Away — build scene in Godot editor

## Team
- **Jan** — Core game, floors, WireFixer ✅, Snake ✅, Find the Difference (in progress), Run Away (script done)
- **Uzi** — Memory Game ✅, Lockpicker, Jigsaw Puzzle
- **Hya** — PPT/game flow presentation, NPC dialogue
