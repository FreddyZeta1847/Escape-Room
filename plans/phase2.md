# Phase 2: Core Systems (Greybox) — Implementation Plan

## Context

Phase 1 setup scripts and LLM manager are done. **Popochiu is downloaded but not yet initialized in the editor** (remaining Phase 1 tasks — must be completed before starting Phase 2).

Phase 2 builds all core game mechanics so that the game loop works end-to-end, even without real rooms or art. This follows the professional game dev approach: **systems first, content later**.

---

## Prerequisites (Remaining Phase 1 — Editor)

These must be done in the Godot editor before Phase 2 work begins:

### Enable Popochiu Plugin
1. Open project in Godot 4.6
2. **Project > Project Settings > Plugins** tab
3. Check **Enable** on "Popochiu 2.0"
4. This auto-creates `game/` directory and registers autoloads (E, R, C, I, D, A, G, T, Cursor, Globals)

### Setup Wizard
The wizard appears automatically:
1. **Game Type**: Select **Retro** (pixel art, matches 320x180)
2. **GUI Template**: Select **Simple Click** (left-click interact, right-click examine)
3. Click **Finish**

### Verify
- `game/` directory exists with `autoloads/`, `rooms/`, `characters/`, etc.
- `game/popochiu_data.cfg` exists
- `project.godot` has Popochiu autoloads **AND** LlmManager (re-add LlmManager if missing)

---

## Part A: Attribute Graph & Interaction System

The attribute graph is the core mechanic that makes all puzzles work. Build this first so everything else plugs into it.

### A.1: Interaction Base Classes (Claude — CLI)

Create a reusable interaction system that all props will use:

**`game/autoloads/interaction_system.gd`** — Autoload singleton
```gdscript
# Core logic:
# - Items have attributes: Array[String]
# - Containers have required_attribute: String (or empty)
# - When player uses item on container:
#     if container.required_attribute in item.attributes → success
#     else → failure feedback

func try_use_item_on_container(item: PopochiuInventoryItem, container: PopochiuProp) -> bool:
    # Check attribute match
    # Return true if opened, false if not
```

Three lock types to support:
1. **Attribute-based**: Drawer (needs `"fingerprint"`), Front Door (needs `"front_door_key"`)
2. **Combination/knowledge-based**: Safe (player enters digits, no item needed)
3. **Discovery-based**: Fireplace compartment (just find and click the hidden hotspot)

### A.2: Item Attribute Definitions

Each Popochiu inventory item gets an `attributes` array. Define in the item script:

| Item | `attributes` |
|------|-------------|
| Gloves | `["fingerprint"]` |
| Photo | `[]` (pure information) |
| Front Door Key | `["front_door_key"]` |

### A.3: Container Attribute Definitions

Each interactive prop gets a `required_attribute` and lock type. Define in the prop script:

| Container | `required_attribute` | `lock_type` |
|-----------|---------------------|-------------|
| Small Drawer | `"fingerprint"` | `"attribute"` |
| Front Door | `"front_door_key"` | `"attribute"` |
| Safe | `""` | `"combination"` |
| Fireplace Compartment | `""` | `"discovery"` |

### A.4: Feedback Messages

- Wrong item on attribute container: "That doesn't seem to work."
- Correct item on attribute container: opens container, gives contents
- Click locked container without item: "It's locked." / "It needs something to open."

---

## Part B: Inventory System

### B.1: Create Inventory Items (Editor + CLI)

**Editor** — Create items via Popochiu Dock:
1. Popochiu Dock > Inventory > **+** > Name: `Gloves`
2. Repeat for `Photo`, `FrontDoorKey`
3. Assign placeholder icons (colored squares are fine)

**Claude (CLI)** — Add attributes to item scripts:
- `game/inventory_items/gloves/inventory_item_gloves.gd` → `var attributes := ["fingerprint"]`
- `game/inventory_items/photo/inventory_item_photo.gd` → `var attributes := []`
- `game/inventory_items/front_door_key/inventory_item_front_door_key.gd` → `var attributes := ["front_door_key"]`

### B.2: Item Collection Flow

Items are picked up from props. The flow:
1. Player clicks prop (e.g., fireplace compartment after discovering it)
2. Prop's `_on_click()` → adds item to inventory via `I.Gloves.add()`
3. Item appears in inventory bar
4. Player can click inventory item to select it, then click a prop to use it

### B.3: Photo Examine Action

The Photo is special — it has a "back" with clue "7_2":
- Player clicks Photo in inventory → `_on_look_at()` → "You flip the photo over. On the back, someone wrote: 7_2"
- This is pure information, no attribute needed

---

## Part C: Combination Lock UI

### C.1: Safe Combination UI (Claude — CLI)

Custom UI scene for the 4-digit safe lock:

**`game/ui/combination_lock.tscn`** + **`game/ui/combination_lock.gd`**
- 4 digit spinners (up/down buttons or scroll)
- Each digit: 0-9
- "Try" button → checks against correct code (4728)
- Correct → safe opens → gives Front Door Key
- Wrong → feedback ("Nothing happens..." or "Wrong combination")
- "Close" button to exit without trying

### C.2: Integration

- Player clicks Safe prop → `_on_click()` → shows combination lock UI
- UI overlays the game (pause game input while UI is open)
- On success: hide UI, play open animation/feedback, add Front Door Key to inventory

---

## Part D: Game State Tracker

### D.1: Game State Singleton (Claude — CLI)

**`game/autoloads/game_state.gd`** — Autoload singleton
```gdscript
var items_collected: Array[String] = []
var rooms_visited: Array[String] = []
var puzzles_solved: Array[String] = []

func collect_item(item_id: String) -> void:
    if item_id not in items_collected:
        items_collected.append(item_id)

func visit_room(room_id: String) -> void:
    if room_id not in rooms_visited:
        rooms_visited.append(room_id)

func solve_puzzle(puzzle_id: String) -> void:
    if puzzle_id not in puzzles_solved:
        puzzles_solved.append(puzzle_id)

func get_state_summary() -> String:
    # Returns formatted string for LLM system prompt injection
```

### D.2: Wire to LLM Manager

- `LlmManager.update_game_state()` pulls from `GameState` singleton
- System prompts dynamically include current state so NPCs react to player progress
- Example injection:
  ```
  [GAME STATE: Player has visited: Entrance Hall, Living Room. Items: Gloves.
   Puzzles solved: fireplace compartment. Not yet solved: drawer, safe.]
  ```

---

## Implementation Sequence

1. **You (editor)**: Complete Phase 1 prerequisites — initialize Popochiu, run setup wizard
2. **You (editor)**: Create 3 inventory items via Popochiu Dock (Gloves, Photo, FrontDoorKey)
3. **Claude (CLI)**: Write interaction system singleton (Part A)
4. **Claude (CLI)**: Add attributes to inventory item scripts (Part B)
5. **Claude (CLI)**: Write game state tracker singleton (Part D)
6. **Claude (CLI)**: Wire game state to LLM manager (Part D.2)
7. **Claude (CLI)**: Write combination lock UI scene + script (Part C)
8. **Test**: Verify systems work in isolation (attribute matching, state tracking, combination UI)

> **Note**: These systems can't be fully end-to-end tested until Phase 3 (rooms + props exist). Phase 2 builds the engines; Phase 3 connects them to the game world.

---

## Verification Checklist

- [ ] Interaction system correctly matches item attributes to container requirements
- [ ] Wrong item gives feedback message, correct item opens container
- [ ] Inventory items have correct attributes defined
- [ ] Photo examine action shows "7_2" clue
- [ ] Combination lock UI appears, accepts input, validates 4728
- [ ] Wrong combination gives feedback, correct combination triggers success
- [ ] Game state tracks items collected, rooms visited, puzzles solved
- [ ] Game state summary string is well-formatted for LLM injection
- [ ] LLM manager receives updated game state for system prompt injection

---

## Key Files

| File | Purpose |
|------|---------|
| `game/autoloads/interaction_system.gd` | Attribute matching logic |
| `game/autoloads/game_state.gd` | Tracks player progress |
| `game/inventory_items/gloves/inventory_item_gloves.gd` | Gloves with `["fingerprint"]` |
| `game/inventory_items/photo/inventory_item_photo.gd` | Photo with examine action |
| `game/inventory_items/front_door_key/inventory_item_front_door_key.gd` | Key with `["front_door_key"]` |
| `game/ui/combination_lock.tscn` | Safe combination UI scene |
| `game/ui/combination_lock.gd` | Combination lock logic |
| `game/autoloads/llm_manager.gd` | Update: wire to GameState |
