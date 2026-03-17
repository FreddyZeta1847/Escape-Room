# Phase 1: Project Setup & Infrastructure

## Context
The project is a bare Godot 4.6 skeleton (just `project.godot`, icon, gitignore). We need to set up the foundation: a setup script to download the Popochiu plugin, configure project settings for 2D pixel art, and create the LLM Manager singleton for Ollama integration.

---

## 1.1 Setup Script

**Files to create:** `setup.sh`, `setup.bat`, `SETUP.md`
**File to modify:** `.gitignore`

### setup.sh / setup.bat
- Download `popochiu-v2.1.0.zip` from `https://github.com/carenalgas/popochiu/releases/download/v2.1.0/popochiu-v2.1.0.zip`
- Extract `addons/popochiu/` into the project root
- Clean up the ZIP after extraction
- Skip download if `addons/popochiu/` already exists
- Print success message with next steps

### .gitignore updates
- Add `addons/popochiu/` (downloaded by script, not tracked)
- Add `*.import` (per user preference)

### SETUP.md
Quick-reference guide covering:
- Prerequisites: Godot 4.6, Ollama
- Run `setup.sh` or `setup.bat`
- Manual steps: enable Popochiu plugin in Godot (Project Settings > Plugins)
- Run Popochiu setup wizard (GUI templates, point-and-click)
- `ollama pull phi3:mini` and `ollama serve`

---

## 1.2 Popochiu Initialization (project.godot)

**File to modify:** `project.godot`

Automate what we can:
- Set display resolution: 320x180, stretch mode `canvas_items`, aspect `keep`
- Switch renderer from Forward Plus to **Compatibility** (better for 2D)
- Document manual GUI steps in SETUP.md (enable plugin, run wizard)

---

## 1.3 LLM Manager Autoload

**File to create:** `llm_manager.gd` (at project root for now, will move to `game/autoloads/` in Phase 2)
**File to modify:** `project.godot` (register autoload)

### Implementation
- Singleton with `HTTPRequest` node (`use_threads = true`)
- `POST` to `http://localhost:11434/api/chat`, non-streaming (`"stream": false`)
- Model: `phi3:mini`, temperature: 0.3, num_predict: 150

### API
```gdscript
LlmManager.chat(npc_id: String, user_message: String) -> String
LlmManager.update_game_state(items: Array, rooms_visited: Array) -> void
LlmManager.reset_conversation(npc_id: String) -> void
```

### Key features
- `conversations` dictionary: per-NPC message history (`{ "marco": [...], "mrs_whitmore": [...] }`)
- Each entry: array of `{ role, content }` messages (system + user + assistant)
- Sliding window: keep last ~15 messages to stay within Phi-3's 4K context
- Dynamic system prompt injection: game state (items, rooms visited) appended to system prompt
- Timeout handling + fallback message if Ollama is unreachable
- Signal-based: emit `chat_completed(npc_id, response)` so callers aren't blocked

---

## Execution Order
1. Update `.gitignore`
2. Create `setup.sh` + `setup.bat`
3. Create `SETUP.md`
4. Update `project.godot` (display settings, renderer)
5. Create `llm_manager.gd`
6. Register autoload in `project.godot`

## Verification
1. Run `setup.sh` — Popochiu downloads and extracts to `addons/popochiu/`
2. Open project in Godot — no errors, resolution is 320x180
3. `LlmManager` autoload is visible in Godot's Autoload list
4. With Ollama running: call `LlmManager.chat("marco", "hello")` from a test script — get a response
5. Without Ollama: get graceful fallback message
