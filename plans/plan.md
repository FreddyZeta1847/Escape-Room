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

## Phase 1: Project Setup & Infrastructure

### 1.1 Setup Script
- `setup.sh` / `setup.bat`: Downloads Popochiu 2.1.0 release ZIP from GitHub, extracts `addons/popochiu/` into the project
- `SETUP.md`: Documents prerequisites (Godot 4.6, Ollama with `ollama pull phi3:mini`)
- `.gitignore`: Exclude `addons/popochiu/`, `.godot/`, `*.import` caches

### 1.2 Popochiu Initialization
- Enable the Popochiu plugin in `project.godot`
- Run the setup wizard (GUI templates, input style: point-and-click)
- Configure top-down 2D camera and resolution (e.g. 320x180 pixel art scaled up)

### 1.3 LLM Manager Autoload (`llm_manager.gd`)
- Singleton registered in Project Settings > Autoload
- Sends POST requests to `http://localhost:11434/api/chat`
- Non-streaming (`"stream": false`) for simplicity
- **Persistent conversation history per NPC** for the entire session:
  - Dictionary `conversations: { "marco": [...], "mrs_whitmore": [...] }`
  - Each entry is an array of `{ role, content }` messages (system + user + assistant)
  - Full history sent with each request so the NPC "remembers" the conversation
  - Sliding window: keep last ~15 messages to avoid exceeding Phi-3's 4K context
- **Dynamic system prompt injection**: game state (items collected, rooms visited) appended to system prompt so NPCs react to player progress
- Parameters: `temperature: 0.3`, `num_predict: 150` (keep responses short/fast)
- Timeout handling + fallback message if Ollama is not running

```gdscript
# API:
# LlmManager.chat(npc_id: String, user_message: String) -> String
# LlmManager.update_game_state(items: Array, rooms_visited: Array) -> void
# LlmManager.reset_conversation(npc_id: String) -> void
```

---

## Phase 2: Room & Scene Design (3 Rooms)

### 2.1 Entrance Hall (Starting Room)
- **Props**: Front door (locked — needs final key), coat rack, mirror
- **Hotspots**: Welcome mat (hint text), wall clock showing "4:15"
- **Connections**: Door to Living Room, door to Study
- **Purpose**: Starting point + final exit. Clock shows a number for the combination.

### 2.2 Living Room
- **NPC**: Marco (philosophy student friend, sitting on couch)
- **Props**: Bookshelf, fireplace with **hidden compartment** (behind a loose brick — only discoverable via Marco's cryptic hints), small drawer (needs fingerprint → opened with **gloves**), couch
- **Inventory items found here**: Photo (inside drawer, back shows "7_2"), Gloves (inside fireplace hidden compartment)
- **Props (additional)**: Birthday cake on table (half-eaten, with candles) — clicking: "A birthday cake with candles... looks like it was eaten recently. Whose birthday was it?" → leads player to ask Mrs. Whitmore
- **Hotspots**: Mantle inscription, painting on wall
- **Connections**: Back to Entrance Hall
- **Marco's role**: When asked about the room, he speaks poetically about "warmth hiding secrets" and "fire's embrace concealing truth" — hinting at the fireplace compartment. Player must engage deeply to understand he means: check behind the fireplace bricks.

### 2.3 Study
- **NPC**: Housekeeper (standing near desk)
- **Props**: Desk with locked safe (4-digit combination lock), filing cabinet, window (barred)
- **Inventory items found here**: **Front Door Key** (inside safe)
- **Hotspots**: Wall writing with partial code hint, framed certificate
- **Connections**: Back to Entrance Hall

---

## Phase 3: Puzzle Design — Attribute Graph System

### Core Mechanic: Attribute-Based Interactions

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

### The Master Puzzle: Open the Safe (4-digit combination)

The combination is **4728**. Clues are scattered but **none are mandatory** — if the player guesses/stumbles upon the combination, the safe opens regardless:

| Digit | Clue Source | Location | Required to solve? |
|-------|------------|----------|--------------------|
| 1st: **4** | Wall clock shows 4:15 | Entrance Hall | No — just a hint |
| 2nd: **7** | Back of photo (shows "7_2") | Living Room drawer | No — just a hint |
| 3rd: **2** | Back of photo (shows "7_2") | Living Room drawer | No — just a hint |
| 4th: **8** | NPC dialogue — owner's birthday | Mrs. Whitmore (Study) | No — just a hint |

### Intended Flow (not enforced as linear):
1. **Explore freely** — all 3 rooms are accessible from the start
2. **Clue gathering** — clock, cake, Marco's hints, Mrs. Whitmore's stories all help
3. **Find Gloves** (fireplace compartment, guided by Marco's riddles) → use on drawer (attribute: `fingerprint`) → get Photo
4. **Combine knowledge** → try combination on safe → get Front Door Key
5. **Use Key on Front Door** → escape!

**Key design**: Marco is essential — without his cryptic hints, the player would never think to check behind the fireplace bricks. This makes NPC dialogue a core mechanic, not optional. But the combination lock rewards exploration *and* luck — items are hints, not gates.

### Sub-puzzle: Fireplace Hidden Compartment
- Fireplace has a clickable loose brick (visible only as a subtle hotspot)
- On first click: "The bricks seem solid... but one feels slightly different"
- Without Marco's hints, player is unlikely to find it — it blends into the background
- On repeated click / after Marco's hints: reveals **Gloves** inside

### Sub-puzzle: Fingerprint Drawer (attribute-based)
- Drawer in Living Room has a fingerprint scanner
- `required_attribute = "fingerprint"`
- Player uses any item with `"fingerprint"` attribute on the drawer → it opens
- Currently only Gloves have this attribute, but the system supports adding more items later
- Popochiu interaction: `_on_item_used(item)` checks `item.attributes` against `required_attribute`

---

## Phase 4: NPC System (LLM Integration)

### 4.1 NPC Personas (System Prompts)

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

### 4.2 Dialogue UI
- Player clicks NPC → Popochiu dialogue opens
- Show a **text input field** (custom UI overlay on top of Popochiu)
- Player types free-form message → sent to LLM Manager → response displayed as NPC speech bubble
- Conversation history maintained per NPC per session
- "Exit conversation" button to close dialogue

### 4.3 Hint System via NPC
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

## Phase 5: Inventory & Interaction System (Attribute Graph)

### Item Definitions
| Item | Collectible? | Found In | Attributes |
|------|-------------|----------|------------|
| Gloves | Yes | Fireplace hidden compartment (Living Room) | `["fingerprint"]` |
| Photo | Yes | Small drawer (Living Room) | `[]` (no attributes — pure information) |
| Front Door Key | Yes | Safe (Study) | `["front_door_key"]` |

### Container / Lock Definitions
| Container | Required Attribute | Lock Type | Location |
|-----------|-------------------|-----------|----------|
| Small Drawer | `"fingerprint"` | Attribute-based | Living Room |
| Safe | *none* | Combination (knowledge) | Study |
| Front Door | `"front_door_key"` | Attribute-based | Entrance Hall |
| Fireplace Compartment | *none* | Discovery (hidden hotspot) | Living Room |

### Observable Items (Not collected, just information)
| Item | Info | Location |
|------|------|----------|
| Wall Clock | Shows 4:15 (hint for digit 4) | Entrance Hall |
| Birthday Cake | "Whose birthday?" → conversation prompt | Living Room (table) |
| Photo Back | Shows "7_2" (hint for digits 7, 2) | Inventory (examine action) |

### Interaction Logic
- Each prop has `_on_click()` and `_on_item_used(item)` handlers
- **Attribute-based containers**: `_on_item_used(item)` checks if `item.attributes` contains the container's `required_attribute`. If match → opens. If no match → feedback message ("That doesn't seem to work")
- **Knowledge-based locks** (Safe): No item needed. Custom combination UI (4 digit spinners). Accepts the correct code regardless of which clues the player has found
- **Discovery-based** (Fireplace): No attribute or item needed — just find and click the hidden hotspot
- This system is **extensible**: adding a new puzzle means defining a new attribute on an item and a requirement on a container — no new code paths needed

---

## Phase 6: Implementation Order

### Step 1 — Setup & Skeleton
- [ ] Create setup scripts (download Popochiu)
- [ ] Initialize Popochiu, configure project settings
- [ ] Create Player character with basic walk animation
- [ ] Create 3 empty rooms with walkable areas and room transitions

### Step 2 — LLM Integration
- [ ] Create `llm_manager.gd` autoload singleton
- [ ] Implement Ollama HTTP chat with system prompts
- [ ] Create custom text input UI for NPC dialogue
- [ ] Test with a single NPC

### Step 3 — Props & Hotspots
- [ ] Add all props and hotspots to rooms (with placeholder art)
- [ ] Implement click interactions (examine text, descriptions)
- [ ] Add wall clock, paintings, inscriptions as hotspots

### Step 4 — Inventory & Puzzles
- [ ] Create inventory items (Gloves, Photo, Key)
- [ ] Implement drawer fingerprint puzzle (item-on-prop interaction)
- [ ] Implement safe combination UI (4-digit input)
- [ ] Implement front door unlock with key
- [ ] Wire up the full puzzle chain

### Step 5 — NPCs
- [ ] Create Housekeeper and Guest characters with sprites
- [ ] Wire up NPC click → dialogue → LLM chat flow
- [ ] Write and test system prompts for both NPCs
- [ ] Add game-state-aware hint injection

### Step 6 — Polish & Art
- [ ] Find/create pixel art assets for rooms, props, characters
- [ ] Add sound effects and ambient audio
- [ ] Victory screen when player escapes
- [ ] Error handling (Ollama not running, timeout)

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
