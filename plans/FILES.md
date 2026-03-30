# Project File Tree

```
escape-room-ai/
├── project.godot                    # Godot project config (autoloads, display, input)
├── llm_manager.gd                   # LLM integration autoload
├── setup.bat / setup.sh             # Local LLM setup scripts
├── SETUP.md                         # Setup instructions
├── README.md
│
├── plans/
│   ├── plan.md                      # Master project plan
│   ├── phase1.md                    # Phase 1: project setup & LLM infra
│   ├── phase2.md                    # Phase 2: attribute-based graph system
│   ├── phase3.md                    # Phase 3: greybox rooms & navigation
│   └── FILES.md                     # THIS FILE - project file tree
│
├── game/
│   ├── popochiu_data.cfg            # Popochiu registry (rooms, characters, items)
│   ├── popochiu_globals.gd          # Popochiu global constants
│   │
│   ├── autoloads/
│   │   ├── a.gd                     # Popochiu audio interface
│   │   ├── c.gd                     # Popochiu character interface
│   │   ├── d.gd                     # Popochiu dialog interface
│   │   ├── i.gd                     # Popochiu inventory interface
│   │   ├── r.gd                     # Popochiu room interface (R.current = active room)
│   │   ├── game_state.gd            # Custom game state tracker (visited rooms, flags)
│   │   ├── interaction_system.gd    # Puzzle logic (try_combination, examine, etc.)
│   │   └── room_setup.gd            # Runtime fixes: y-sort, camera limits, textures
│   │
│   ├── ui/
│   │   ├── combination_lock.gd      # 4-digit combo lock overlay (autoload, no .tscn)
│   │   ├── inventory_inspector.gd   # Item inspection overlay with front/back flip
│   │   └── dialogue_ui.gd          # NPC dialogue: text input + trust bar (Marco)
│   │
│   ├── characters/
│   │   ├── player/
│   │   ├── marco/                   # NPC: scared friend, social puzzle (trust bar)
│   │   ├── mrs_whitmore/            # NPC: housekeeper, birthday clue
│   │   └── (pattern: character_*.gd / .tscn / .tres / _state.gd / sprite.png)
│   │   NOTE: player/ is the only one listed below:
│   │       ├── character_player.gd / .tscn / .tres
│   │       ├── character_player_state.gd
│   │       └── player.png
│   │
│   ├── inventory_items/
│   │   ├── front_door_key/
│   │   │   ├── inventory_item_front_door_key.gd / .tscn / .tres
│   │   │   └── inventory_item_front_door_key_state.gd
│   │   ├── gloves/
│   │   │   ├── inventory_item_gloves.gd / .tscn / .tres
│   │   │   └── inventory_item_gloves_state.gd
│   │   ├── photo/
│   │   │   ├── inventory_item_photo.gd / .tscn / .tres
│   │   │   ├── inventory_item_photo_state.gd
│   │   │   └── icon_photo_back.png          # Back of photo showing "7_2"
│   │   └── (fireplace_poker removed — replaced by Marco social puzzle)
│   │
│   ├── rooms/
│   │   ├── entrance_hall/
│   │   │   ├── room_entrance_hall.gd / .tscn / .tres
│   │   │   ├── room_entrance_hall_state.gd
│   │   │   ├── bg_entrance_hall.png
│   │   │   ├── props/
│   │   │   │   ├── front_door/    (prop_front_door.gd/.tscn, placeholder.png)
│   │   │   │   ├── wall_clock/    (prop_wall_clock.gd/.tscn, placeholder.png)
│   │   │   │   ├── coat_rack/     (prop_coat_rack.gd/.tscn, placeholder.png)
│   │   │   │   └── mirror/        (prop_mirror.gd/.tscn, placeholder.png)
│   │   │   ├── hotspots/
│   │   │   │   ├── welcome_mat/          (hotspot + placeholder.png)
│   │   │   │   ├── door_to_living_room/  (hotspot + placeholder.png)
│   │   │   │   └── door_to_study/        (hotspot + placeholder.png)
│   │   │   ├── markers/
│   │   │   │   ├── start/
│   │   │   │   ├── from_living_room/
│   │   │   │   └── from_study/
│   │   │   └── walkable_areas/main/
│   │   │
│   │   ├── living_room/
│   │   │   ├── room_living_room.gd / .tscn / .tres
│   │   │   ├── room_living_room_state.gd
│   │   │   ├── bg_living_room.png
│   │   │   ├── props/
│   │   │   │   ├── birthday_cake/
│   │   │   │   ├── bookshelf/
│   │   │   │   ├── couch/
│   │   │   │   ├── fireplace/
│   │   │   │   ├── fireplace_compartment/ (social gate: Marco must collaborate first)
│   │   │   │   ├── fireplace_compartment/
│   │   │   │   ├── painting/
│   │   │   │   └── small_drawer/
│   │   │   ├── hotspots/
│   │   │   │   ├── door_to_entrance_hall/
│   │   │   │   └── mantle_inscription/
│   │   │   ├── markers/from_entrance_hall/
│   │   │   └── walkable_areas/main/
│   │   │
│   │   └── study/
│   │       ├── room_study.gd / .tscn / .tres
│   │       ├── room_study_state.gd
│   │       ├── bg_study.png
│   │       ├── props/
│   │       │   ├── barred_window/
│   │       │   ├── desk/
│   │       │   ├── filing_cabinet/
│   │       │   ├── framed_certificate/
│   │       │   └── safe/              (combination lock interaction)
│   │       ├── hotspots/
│   │       │   ├── door_to_entrance_hall/
│   │       │   └── wall_writing/
│   │       ├── markers/from_entrance_hall/
│   │       └── walkable_areas/main/
│   │
│   ├── gui/                          # Popochiu Simple Click GUI template
│   │   ├── gui.gd / gui.tscn
│   │   ├── gui_commands.gd
│   │   ├── fonts/monkeyisland_1991.ttf
│   │   ├── images/simple_click_cursor.png
│   │   ├── resources/gui_theme.tres
│   │   └── components/
│   │       ├── dialog_menu/
│   │       ├── dialog_text/dialog_overhead/
│   │       ├── dialogue_advancement/
│   │       ├── hover_text/
│   │       ├── simple_click_bar/
│   │       ├── simple_click_settings_popup/
│   │       ├── sound_volumes/
│   │       ├── system_text/
│   │       └── popups/ (history, quit, save_and_load)
│   │
│   └── transition_layer/
│       ├── transition_layer.gd / .tscn
│       └── textures/
│
└── addons/popochiu/                  # Popochiu plugin (DO NOT EDIT)
```

## Autoload Order (project.godot)
1. T (translations)
2. Globals
3. Cursor
4. E (Popochiu main)
5. R (rooms), C (characters), I (inventory), D (dialogs), A (audio), G (graphic interface)
6. LlmManager
7. GameState
8. InteractionSystem
9. CombinationLock
10. RoomSetup

## Key Conventions
- Each prop/hotspot: own folder with `prop_*.gd`, `prop_*.tscn`, `placeholder.png`
- Each room: `room_*.gd` (logic), `room_*.tscn` (scene), `room_*_state.gd`, `.tres`
- Room access: `R.current` (active room), `R.goto_room("Name")`
- Player: `C.player`, position via markers in `_on_room_entered()`
- Viewport: 320x180, stretched to 1280x720 (canvas_items mode)
