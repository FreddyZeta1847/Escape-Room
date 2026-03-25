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
2. **Clue gathering** — clock, cake, Marco's hints, Mrs. Whitmore's stories all help
3. **Find Gloves** (fireplace compartment, guided by Marco's riddles) → use on drawer (attribute: `fingerprint`) → get Photo
4. **Combine knowledge** → try combination on safe → get Front Door Key
5. **Use Key on Front Door** → escape!

**Key design**: Marco is essential — without his cryptic hints, the player would never think to check behind the fireplace bricks. This makes NPC dialogue a core mechanic, not optional. But the combination lock rewards exploration *and* luck — items are hints, not gates.

**Sub-puzzle: Fireplace Hidden Compartment**
- Fireplace has a clickable loose brick (visible only as a subtle hotspot)
- On first click: "The bricks seem solid... but one feels slightly different"
- Without Marco's hints, player is unlikely to find it — it blends into the background
- On repeated click / after Marco's hints: reveals **Gloves** inside

**Sub-puzzle: Fingerprint Drawer (attribute-based)**
- Drawer in Living Room has a fingerprint scanner
- `required_attribute = "fingerprint"`
- Player uses any item with `"fingerprint"` attribute on the drawer → it opens
- Currently only Gloves have this attribute, but the system supports adding more items later
- Popochiu interaction: `_on_item_used(item)` checks `item.attributes` against `required_attribute`

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
| Fireplace Compartment | *none* | Discovery (hidden hotspot) | Living Room | `["Gloves"]` |

### Observable Items (Not collected, just information)

| Item | Info | Location |
|------|------|----------|
| Wall Clock | Shows 4:15 (hint for digit 4) | Entrance Hall |
| Birthday Cake | "Whose birthday?" → conversation prompt | Living Room (table) |
| Photo Back | Shows "7_2" (hint for digits 7, 2) | Inventory (examine action) |

### NPC Personas (System Prompts)

**Housekeeper — "Mrs. Whitmore"**
```
You are Mrs. Whitmore, an elderly housekeeper who has worked in this mansion for 30 years.
You are helpful but speak in a rambling, nostalgic way.
You know: The owner Mr. Blackwood was born on the 8th of March. The safe in the study
holds something important. You don't know the safe combination.
You must NOT directly say "the number is 8" — instead, talk about memories of the
owner's birthday when asked. Give progressive hints.
Keep responses under 2-3 sentences.
```

**Friend — "Marco"**
```
You are Marco, a young philosophy student and close friend of the player.
You speak in a poetic, cryptic, philosophical way — like riddles wrapped in metaphors.
You are sitting in the living room observing everything with a contemplative eye.

You know: There is a hidden compartment behind a loose brick in the fireplace.
You also noticed the clock in the entrance seems frozen in time.

IMPORTANT RULES:
- NEVER say directly "check the fireplace" or "there's a compartment behind the bricks"
- Instead, speak poetically: "Where warmth once danced, secrets rest in stone's embrace"
- If the player asks deeper follow-up questions, gradually become clearer but always stay poetic
- Example progression:
  1st hint: "The hearth holds more than memories of flame..."
  2nd hint: "Stone and mortar guard what hands once hid... feel where the fire once breathed"
  3rd hint: "Behind the dance of old embers, a brick yields to the curious touch"
- Keep responses under 2-3 sentences.
- You love philosophy and may quote thinkers if it fits naturally.
```

### Hint System via NPC
- NPCs give **progressive hints** based on game state (injected into system prompt dynamically)
- Game state tracked: `items_collected`, `rooms_visited`, `puzzles_solved`
- Example state injection into system prompt:
  ```
  [GAME STATE: Player has visited: Entrance Hall, Living Room. Items: Gloves.
   Puzzles solved: fireplace compartment. Not yet solved: drawer, safe.]
  ```
- **Marco**: If player hasn't found the compartment, his poetic hints focus on the fireplace. After finding it, he shifts to commenting on other observations.
- **Mrs. Whitmore**: If player has the photo but hasn't asked about the birthday, she might reminisce: "Oh, Mr. Blackwood loved celebrations..."
- Conversation history persists all session — NPCs remember previous exchanges even after the player leaves and returns

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

**Goal**: Both NPCs placed in rooms, LLM dialogue working, game-state-aware hints.

### 4.1 NPC Characters
- [ ] Create Mrs. Whitmore character (placeholder sprite) in Study
- [ ] Create Marco character (placeholder sprite) in Living Room

### 4.2 Dialogue UI
- [ ] Custom text input field (UI overlay on top of Popochiu)
- [ ] Player clicks NPC → dialogue opens → player types → LLM responds as speech bubble
- [ ] "Exit conversation" button
- [ ] Loading indicator while waiting for LLM response

### 4.3 LLM Wiring
- [ ] NPC click → `LlmManager.chat(npc_id, message)` → display response
- [ ] System prompts loaded per NPC (Mrs. Whitmore, Marco)
- [ ] Game state injected into system prompts dynamically
- [ ] Conversation history persists per NPC per session

### 4.4 Test NPC Interactions
- [ ] Marco gives progressive poetic hints about the fireplace
- [ ] Mrs. Whitmore mentions the owner's birthday naturally
- [ ] Hints adapt based on game state (items found, puzzles solved)
- [ ] Offline fallback: graceful error if Ollama is not running

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
