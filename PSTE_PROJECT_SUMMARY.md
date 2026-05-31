# Project PSTE -- Point, Solve, Think, Escape 
### thank you claude forda help^^

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
│   │   │   ├── minigames/      # WireFixerGame.tscn, SnakeGame.tscn
│   │   │   └── ui/             # HUD.tscn
│   │   ├── scripts/
│   │   │   ├── GameManager.gd  # Autoload singleton
│   │   │   ├── FloorBase.gd    # Base class for all floors
│   │   │   ├── HUD.gd
│   │   │   ├── Main.gd
│   │   │   ├── rooms/          # Floor1.gd - Floor6.gd
│   │   │   └── minigames/      # WireFixer.gd, SnakeGame.gd, SnakeBoard.gd
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
- Stair costs: Floor 5→4: 3, 4→3: 3, 3→2: 3, 2→1: 3 (total 12, max stamina 10 = can't reach Floor 1 without resting for maximum ragebait)

## FloorBase
- File: `res://scripts/FloorBase.gd`
- class_name: `FloorBase`
- Each floor script extends `FloorBase`
- Export vars: `floor_number`, `stair_cost`
- Methods: `go_up()`, `go_down()`

## Minigame Template
Every minigame must:
```gdscript
extends Control
const minigame_id = "unique_id"
signal completed(success: bool)

func _ready():
    get_tree().get_first_node_in_group("room_container").hide()

func _on_win():
    get_tree().get_first_node_in_group("room_container").show()
    completed.emit(true)

func _on_lose():
    get_tree().get_first_node_in_group("room_container").show()
    completed.emit(false)
```

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
- Taunts:
  - Start: "Sssso you found my nest... Allow me to shed some light on your ssituation — by taking it away! Conssider thiss your practical exam!"
  - Phase 2: "Impresssive... but can you handle my WALL-gorithmsss?"
  - Phase 3: "You think you can COMPILE me?! I'll turn YOU to SSSTONEEE!"
  - Pong summon: "You may have defeated my algorithmss... but have you met my SSERVE-ior?! I sssummon — ALEX EALA!"
  - Pong taunt: "Ssstruggling? Allow me to RALLY some backup!"
  - Pong win: "Fault! FAULT! Thiss can't be happening..."
  - Full defeat: "Imposssible... I'll add this to your final exam..."
  - Pong loss: "Out of boundsss! Just like your chanccess of esscaping!"

## Pending Minigames
| Minigame | Floor | Member | Status |
|---|---|---|---|
| Memory Game | 4 | Uzi | Not started |
| Lockpicker | 3 | Uzi | Not started |
| Jigsaw Puzzle | 2 | Uzi | Not started |
| Find the Difference | 1 | Jan | Not started |
| The Gate (Run Away) | Ground | Jan | Not started |

## Floor Unlock Logic
- Floor 6 unlocked by: beating Find the Difference fast OR elevator (Maintenance Guy on Floor 1)
- Flag: `GameManager.set_flag("floor6_unlocked", true)`
- Floor 5 StairsUp disabled until `floor6_unlocked` is true

## Known Issues / TODO
- [ ] Statue visibility added to SnakeBoard.gd (just added, test needed)
- [ ] Snake game layout — currently black box on side of screen, fix with assets later
- [ ] Pong transition working but snake doesn't block ball properly yet (needs tuning, not tried yet since it currently requires tester to playthrough all phases)
- [ ] All floor scenes need real backgrounds (Assets are here, but not yet inserted)
- [ ] HUD positioning needs cleanup
- [ ] Ate girl NPC dialogue not built yet (Hya)
- [ ] Maintenance Guy NPC not built yet
- [ ] The Gate final boss (run away sequence) not built yet
- [ ] Find the Difference time tracking not built yet
- [ ] Remove temp `game_flags["floor6_unlocked"] = true` from GameManager._ready() when Find the Difference is done

## Team
- **Jan** — Core game, floors, WireFixer ✅, Snake ✅, Find the Difference, The Gate
- **Uzi** — Memory Game, Lockpicker, Jigsaw Puzzle
- **Hya** — PPT/game flow presentation, NPC dialogue
