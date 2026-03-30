# Escape Room AI — Project Plan

## Context

Build a 2D top-down point-and-click escape room game in Godot 4.6 using the **Popochiu 2.1.0** framework. The player is trapped in a **detective/mystery old mansion** and must solve puzzles (inventory items, combination locks, NPC dialogue) to find a key and escape. Two NPCs are powered by a **local LLM (Phi-3-mini via Ollama)** for natural language dialogue:
- **Housekeeper (Mrs. Whitmore)**: Elderly, nostalgic, holds the 4th digit (owner's birthday)
- **Friend (Marco)**: Philosophy student, speaks in poetic/cryptic riddles. Player must ask deep questions to decode his hints. His key role: directs the player to a **hidden compartment** they'd never find on their own.

Conversation history **persists per NPC for the entire session** (resets on game restart). The project is shared via GitHub — colleagues clone and run a setup script.

---

## Architecture Overview

```
escape-room-ai/
├── addons/popochiu/          # Downloaded by setup script
├── game/
│   ├── rooms/
│   │   ├── entrance_hall/    # Starting room, locked front door
│   │   ├── living_room/      # NPC: Marco (friend), fireplace, bookshelf
│   │   └── study/            # NPC: Mrs. Whitmore (housekeeper), desk, safe
│   ├── characters/
│   │   ├── player/
│   │   ├── mrs_whitmore/     # Housekeeper NPC
│   │   └── marco/            # Philosophy student friend NPC
│   ├── inventory_items/      # Key, Gloves, Photo, etc.
│   ├── dialogs/
│   └── autoloads/
│       └── llm_manager.gd   # Singleton: HTTP calls to Ollama
├── setup.sh                  # Downloads Popochiu plugin
├── setup.bat                 # Windows version
├── SETUP.md                  # Instructions (Godot 4.6 + Ollama)
└── project.godot
```

---

## Game Design (Reference)

This section documents the full game design. All phases reference this — it is not a phase itself.

### Rooms

**Entrance Hall (Starting Room)**
- **Props**: Front door (locked — needs final key), coat rack, mirror
- **Hotspots**: Welcome mat (hint text), wall clock showing "4:15"
- **Connections**: Door to Living Room, door to Study
- **Purpose**: Starting point + final exit. Clock shows a number for the combination.

**Living Room**
- **NPC**: Marco (philosophy student friend, sitting on couch)
- **Props**: Bookshelf, fireplace with **hidden compartment** (behind a loose brick — only discoverable via Marco's cryptic hints), small drawer (needs fingerprint → opened with **gloves**), couch
- **Inventory items found here**: Photo (inside drawer, back shows "7_2"), Gloves (inside fireplace hidden compartment)
- **Props (additional)**: Birthday cake on table (half-eaten, with candles) — clicking: "A birthday cake with candles... looks like it was eaten recently. Whose birthday was it?" → leads player to ask Mrs. Whitmore
- **Hotspots**: Mantle inscription, painting on wall
- **Connections**: Back to Entrance Hall
- **Marco's role**: When asked about the room, he speaks poetically about "warmth hiding secrets" and "fire's embrace concealing truth" — hinting at the fireplace compartment. Player must engage deeply to understand he means: check behind the fireplace bricks.

**Study**
- **NPC**: Housekeeper (standing near desk)
- **Props**: Desk with locked safe (4-digit combination lock), filing cabinet, window (barred)
- **Inventory items found here**: **Front Door Key** (inside safe)
- **Hotspots**: Wall writing with partial code hint, framed certificate
- **Connections**: Back to Entrance Hall

### Puzzle Design — Attribute Graph System

**Core Mechanic: Attribute-Based Interactions**

Instead of hardcoded linear item→lock relationships, the game uses an **attribute graph**:

- **Containers/locks** can have a `required_attribute` (e.g., `"fingerprint"`) — or none at all
- **Inventory items** can have `attributes` (e.g., Gloves have `["fingerprint"]`) — or none
- When the player uses an item on a container, the system checks: *does any attribute on this item match the container's `required_attribute`?* If yes → opens
- **Not all containers require attributes**: the combination lock is purely knowledge-based (enter the right digits). The front door just needs the key item directly.
- **Not all items have attributes**: the Photo has no special attribute, it's just information

This makes puzzle logic **data-driven and flexible** — you can add new items/containers by editing attributes, not code.

```
# Attribute graph example:
Drawer:       required_attribute = "fingerprint"
Gloves:       attributes = ["fingerprint"]
→ Gloves can open Drawer (attribute match)

Safe:         required_attribute = null (combination lock — knowledge-based)
→ Player enters digits directly. No item required.

Front Door:   required_attribute = null (requires specific key item)
→ Hardcoded: needs "front_door_key" item
```

**The Master Puzzle: Open the Safe (4-digit combination)**

The combination is **4728**. Clues are scattered but **none are mandatory** — if the player guesses/stumbles upon the combination, the safe opens regardless:

| Digit | Clue Source | Location | Required to solve? |
|-------|------------|----------|--------------------|
| 1st: **4** | Wall clock shows 4:15 | Entrance Hall | No — just a hint |
| 2nd: **7** | Back of photo (shows "7_2") | Living Room drawer | No — just a hint |
| 3rd: **2** | Back of photo (shows "7_2") | Living Room drawer | No — just a hint |
| 4th: **8** | NPC dialogue — owner's birthday | Mrs. Whitmore (Study) | No — just a hint |

**Intended Flow (not enforced as linear):**
1. **Explore freely** — all 3 rooms are accessible from the start
2. **Discover the brick** — click the loose brick → "I can't move it on my own"
3. **Convince Marco** (social puzzle) — talk to him, build trust through dialogue → cutscene → he moves the brick → **Gloves**
4. **Use Gloves on drawer** → attribute match (`fingerprint`) → get **Photo**
5. **Gather combination clues** — clock (4), photo back (7_2), Mrs. Whitmore (8)
6. **Enter 4728 on safe** → get **Front Door Key**
7. **Use Key on Front Door** → escape!

**Key design**: Marco is essential — the player physically cannot move the brick alone. They must convince Marco through free-form LLM dialogue, making NPC conversation the core mechanic. The combination lock rewards exploration *and* conversation — items are hints, not gates.

**Sub-puzzle: Fireplace Brick (Social — Marco)**
- Loose brick is always visible and clickable in the Living Room
- Player alone: "This brick feels different... but I can't move it on my own."
- Marco sits nearby, scared but loyal. He noticed the brick but won't act.
- Player must persuade Marco through dialogue (trust bar: 0→100, LLM self-scoring)
- When trust reaches 100: cutscene — Marco moves the brick, reveals **Gloves**
- See `plans/phase4.md` for full Marco mechanic details

**Sub-puzzle: Fingerprint Drawer (attribute-based)**
- Drawer in Living Room has a fingerprint scanner
- `required_attribute = "fingerprint"`
- When player clicks the drawer, the system auto-checks inventory for matching attribute
- Currently only Gloves have this attribute, but the system supports adding more items later

### Item Definitions

| Item | Collectible? | Found In | Attributes |
|------|-------------|----------|------------|
| Gloves | Yes | Fireplace hidden compartment (Living Room) | `["fingerprint"]` |
| Photo | Yes | Small drawer (Living Room) | `[]` (no attributes — pure information) |
| Front Door Key | Yes | Safe (Study) | `["front_door_key"]` |

### Container / Lock Definitions

Each container defines a `contained_items: Array[String]` — the items given to the player when opened. This keeps puzzle logic data-driven: the open logic reads from `contained_items` generically instead of hardcoding per-container.

| Container | Required Attribute | Lock Type | Location | `contained_items` |
|-----------|-------------------|-----------|----------|--------------------|
| Small Drawer | `"fingerprint"` | Attribute-based | Living Room | `["Photo"]` |
| Safe | *none* | Combination (knowledge) | Study | `["FrontDoorKey"]` |
| Front Door | `"front_door_key"` | Attribute-based | Entrance Hall | `[]` (triggers victory) |
| Fireplace Brick | *none* | Social (convince Marco) | Living Room | `["Gloves"]` |

### Observable Items (Not collected, just information)

| Item | Info | Location |
|------|------|----------|
| Wall Clock | Shows 4:15 (hint for digit 4) | Entrance Hall |
| Birthday Cake | "Whose birthday?" → conversation prompt | Living Room (table) |
| Photo Back | Shows "7_2" (hint for digits 7, 2) | Inventory (examine action) |

### NPC Personas & Mechanics

Full NPC system prompts and mechanics are documented in `plans/phase4.md`.

**Mrs. Whitmore** (Study) — Nostalgic housekeeper. Naturally mentions owner's birthday "the 8th of March" when asked. No special mechanic needed.

**Marco** (Living Room) — Scared but loyal friend. Social puzzle: player must convince him to move the brick through dialogue. Trust bar (0→100) driven by LLM self-scoring `[MOOD:X]` tags. When trust hits 100 → cutscene → Gloves.

### Game State Integration
- Game state tracked: `items_collected`, `rooms_visited`, `puzzles_solved`, `marco_mood`, `marco_collaborated`
- State injected into NPC system prompts dynamically each turn
- Conversation history: 15-message sliding window per NPC, persists per session
- Post-solve: NPCs acknowledge progress and shift to other topics
- Guardrails: regex output filter blocks direct puzzle answers

---

## Phase 1: Project Setup & Infrastructure ✅

**Goal**: Repository ready, Popochiu downloaded, LLM manager working.

### 1.1 Setup Script
- [x] `setup.sh` / `setup.bat`: Downloads Popochiu 2.1.0 release ZIP from GitHub, extracts `addons/popochiu/` into the project
- [x] `SETUP.md`: Documents prerequisites (Godot 4.6, Ollama with `ollama pull phi3:mini`)
- [x] `.gitignore`: Exclude `addons/popochiu/`, `.godot/`, `*.import` caches

### 1.2 Popochiu Initialization
- [ ] Enable the Popochiu plugin in `project.godot` (editor)
- [ ] Run the setup wizard — Game Type: Retro, GUI: Simple Click (editor)
- [ ] Configure top-down 2D camera and resolution (320x180 pixel art scaled up)

### 1.3 LLM Manager Autoload (`llm_manager.gd`)
- [x] Singleton registered in Project Settings > Autoload
- [x] Sends POST requests to `http://localhost:11434/api/chat`
- [x] Non-streaming (`"stream": false`) for simplicity
- [x] Persistent conversation history per NPC (sliding window ~15 messages)
- [x] Dynamic system prompt injection (game state appended)
- [x] Parameters: `temperature: 0.3`, `num_predict: 150`
- [x] Timeout handling + fallback message if Ollama is not running

```gdscript
# API:
# LlmManager.chat(npc_id: String, user_message: String) -> String
# LlmManager.update_game_state(items: Array, rooms_visited: Array) -> void
# LlmManager.reset_conversation(npc_id: String) -> void
```

---

## Phase 2: Core Systems (Greybox)

**Goal**: Build all game mechanics with placeholder art. The full game loop should be playable end-to-end with colored rectangles and programmer art.

### 2.1 Attribute Graph & Interaction System
- [x] Base interaction logic: `_on_click()` and `_on_item_used(item)` patterns
- [x] Attribute matching system: items have `attributes[]`, containers have `required_attribute`
- [x] Containers define `contained_items: Array[String]` — items given to player on open
- [x] Three lock types working: attribute-based, combination (knowledge), discovery (hidden hotspot)
- [x] Feedback messages for wrong item usage ("That doesn't seem to work")

### 2.2 Inventory System
- [x] Create inventory items (Gloves, Photo, Front Door Key) with Popochiu
- [x] Item attributes defined on each item
- [x] Item collection (pick up) and usage (use on prop) flow
- [x] Photo examine action (flip to see "7_2" on the back)

### 2.3 Combination Lock UI
- [x] Custom 4-digit spinner UI for the safe
- [x] Accepts code 4728 → opens safe → gives Front Door Key
- [x] No item required — purely knowledge-based

### 2.4 Game State Tracker
- [x] Track: `items_collected`, `rooms_visited`, `puzzles_solved`
- [x] Expose to LLM Manager for dynamic system prompt injection (Phase 4)

---

## Phase 3: Greybox Rooms & Navigation ✅

**Goal**: 3 rooms with placeholder backgrounds, walkable areas, room transitions, all props and hotspots placed. Full puzzle chain playable.

### 3.1 Player Character
- [x] Create Player character with Popochiu (placeholder sprite)
- [x] Basic walk animation (4-direction or simple)

### 3.2 Room Shells (Placeholder Art)
- [x] Entrance Hall — colored rectangle background, walkable area, markers (Start, FromLivingRoom, FromStudy)
- [x] Living Room — colored rectangle background, walkable area, markers (FromEntranceHall)
- [x] Study — colored rectangle background, walkable area, markers (FromEntranceHall)
- [x] Room transition scripts (door hotspots → `R.goto_room()`)

### 3.3 Props & Hotspots (All Rooms)
- [x] **Entrance Hall**: Front door (locked), wall clock (examine: "4:15"), coat rack, mirror, welcome mat
- [x] **Living Room**: Fireplace + hidden compartment (loose brick hotspot), small drawer (fingerprint lock), bookshelf, couch, birthday cake, mantle inscription, painting
- [x] **Study**: Safe (combination lock), desk, filing cabinet, barred window, wall writing, framed certificate
- [x] All props have `_on_click()` examine text
- [x] All interactive props have `_on_item_used(item)` wired to attribute system

### 3.4 Wire Full Puzzle Chain
- [x] Fireplace loose brick → click → discover Gloves
- [x] Gloves on drawer → attribute match → get Photo
- [x] Safe → enter 4728 → get Front Door Key
- [x] Key on front door → victory / escape
- [x] **Test**: Full game playable from start to finish with placeholders

### 3.5 Runtime Fixes (room_setup.gd)
- [x] Y-sort fix: Background `z_index = -1` + Hotspots `y_sort_enabled = true` (all rooms)
- [x] Camera limits locked to viewport size (all rooms)
- [x] CombinationLock overlay hidden when lock is closed (was blocking all input)

---

## Phase 4: NPC System & Dialogue

**Goal**: Both NPCs placed in rooms, LLM dialogue working, Marco social puzzle functional. Full details in `plans/phase4.md`.

### 4.0 Remove Poker Mechanic
- [x] Delete poker prop/inventory item, update fireplace compartment to social gate

### 4.1 NPC Characters
- [x] Create Marco character (placeholder sprite) in Living Room near fireplace
- [x] Create Mrs. Whitmore character (placeholder sprite) in Study near desk

### 4.2 Dialogue UI
- [x] Text input bar at bottom + NPC responds via Popochiu `say()`
- [x] Trust bar (Marco only): ColorRect-based, red → yellow → green
- [x] "Thinking..." status label while waiting for LLM
- [x] ESC to exit, full-screen blocker prevents interaction during dialogue

### 4.3 LLM Wiring
- [x] Per-NPC system prompts (Marco: social puzzle, Mrs. Whitmore: birthday clue)
- [x] Curl-based HTTP (bypasses Godot HTTPRequest 30s delay on Windows)
- [x] `[MOOD:X]` tag parsing → trust bar update
- [x] Regex output filter + bracket tag stripping
- [x] 15-message sliding window history per NPC
- [x] Ollama context flush on game start

### 4.4 Marco Collaboration Cutscene
- [ ] Trust hits 50 → Marco walks to fireplace → moves brick → Gloves available
- **Status**: Untested — mood scoring needs to reliably reach threshold first

### 4.5 Known Issues (In Progress)
- [ ] Marco mood scoring inconsistent — model sometimes forgets `[MOOD:X]` tag or gives wrong values
- [ ] Marco character consistency — occasionally breaks role (third person, not scared)
- [ ] UTF-8 mojibake from curl on Windows (smart quotes garbled)
- [ ] Long responses truncated by Popochiu `say()` display
- [ ] Cutscene not yet triggered/tested in gameplay

### 4.6 Testing Completed
- [x] Mrs. Whitmore responds in character, mentions birthday naturally
- [x] Dialogue UI blocks game interaction while open
- [x] Offline fallback works (graceful error when Ollama not running)
- [x] Response times acceptable (2-8 seconds with `qwen2.5:1.5b` via curl)

---

## Phase 5: Art Pass

**Goal**: Replace all placeholder art with real pixel art. The game looks finished.

### 5.1 Assets
- [ ] Download/create pixel art tileset (e.g., LimeZu "Modern Interiors" from itch.io)
- [ ] Character sprites: Player (4-direction walk), Mrs. Whitmore (idle), Marco (idle)
- [ ] Room backgrounds: Entrance Hall, Living Room, Study
- [ ] Props: all furniture, fireplace, safe, drawer, clock, cake, etc.
- [ ] Inventory item icons: Gloves, Photo, Front Door Key

### 5.2 Apply to Rooms
- [ ] Replace placeholder backgrounds with tiled rooms
- [ ] Replace placeholder prop sprites
- [ ] Adjust walkable areas to match new art
- [ ] Adjust hotspot regions to match new prop positions

### 5.3 Apply to Characters
- [ ] Player walk animation with real sprites
- [ ] NPC idle animations

---

## Phase 6: Polish

**Goal**: The game feels complete and handles edge cases.

- [ ] Victory screen when player escapes
- [ ] Sound effects (door open, item pickup, safe click, drawer open)
- [ ] Ambient audio per room
- [ ] Transition effects between rooms (fade)
- [ ] Error handling (Ollama not running, timeout, unexpected states)
- [ ] Playtesting and puzzle balance tuning

---

## Technical Details

### Ollama Integration
- **Endpoint**: `POST http://localhost:11434/api/chat`
- **Model**: `phi3:mini`
- **Stream**: `false` (wait for complete response)
- **Options**: `{ "temperature": 0.3, "num_predict": 150 }`
- **Godot**: `HTTPRequest` node with `use_threads = true`

### Popochiu Key APIs Used
- `C.Player.walk_to_clicked()` — movement
- `C.NpcName.say("text")` — NPC speech
- `I.ItemName.add()` — add to inventory
- `R.RoomName.change_to()` — room transitions
- `_on_click()` / `_on_item_used(item)` — prop interactions

### Collaboration Setup
1. Clone repo
2. Run `setup.sh` (or `setup.bat` on Windows)
3. Open project in Godot 4.6
4. Install Ollama + `ollama pull phi3:mini`
5. Start Ollama (`ollama serve`)
6. Run the game from Godot

---

## Verification / Testing

1. **Setup test**: Clone fresh → run setup script → open in Godot → no errors
2. **Room navigation**: Player walks between all 3 rooms via door clicks
3. **Inventory**: Pick up Gloves → use on drawer → get Photo → examine Photo
4. **Combination lock**: Enter 4728 on safe → opens → get Key
5. **Front door**: Use Key on door → victory screen
6. **NPC dialogue**: Click NPC → type message → get LLM response in < 10 seconds
7. **NPC hints**: Ask Housekeeper about birthday → she mentions "the 8th" naturally
8. **Offline fallback**: Stop Ollama → click NPC → graceful error message
