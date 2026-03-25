# Phase 3: Greybox Rooms & Navigation — Implementation Plan

## Status: ✅ COMPLETE

## Context

Phase 2 (core systems) is complete: InteractionSystem, GameState, CombinationLock, inventory items with attributes, and LlmManager wired to GameState. These are all **engines without content**. Phase 3 creates the actual game world — 3 rooms with placeholder art, all props/hotspots, room transitions, and the full puzzle chain playable end-to-end.

---

## Editor vs CLI Split

**This phase is heavily editor-dependent.** Popochiu requires rooms, characters, props, hotspots, walkable areas, and markers to be created via the Popochiu Dock — it generates `.tscn` files, registers them in `popochiu_data.cfg`, and updates autoload scripts (`r.gd`, `c.gd`). CLI can only edit the generated `.gd` scripts afterward.

**Workflow per step:** User creates items in editor → tells Claude → Claude edits the generated scripts.

---

## Issues Encountered & Fixes

### Issue 1: CombinationLock overlay blocking all input + darkening screen

**Symptom**: Player could not click anywhere in the game. Screen had a grey gradient overlay. No mouse events reached the room's `_unhandled_input`.

**Root cause**: `combination_lock.gd` created a full-screen `ColorRect` (60% black, `mouse_filter = MOUSE_FILTER_STOP`) on `CanvasLayer 100` during `_build_ui()`. In `_ready()`, only `_panel.visible = false` was set — hiding the lock UI panel but leaving the background overlay always visible and blocking all input.

**Fix**: Store the background `ColorRect` as `_bg` and hide/show it alongside the lock UI in `show_lock()` / `hide_lock()` instead of only toggling the panel.

### Issue 2: Props above screen center invisible (y-sort rendering)

**Symptom**: Props in the bottom half of each room were visible, but props above the vertical midpoint were hidden behind the background.

**Root cause**: Popochiu enables `y_sort_enabled = true` on the room node at runtime. The Background `Sprite2D` is positioned at the room center (e.g. y=90 for a 180px room). With y-sorting, Background renders ON TOP of any prop/hotspot with y < 90. Additionally, the `Hotspots` container had no `y_sort_enabled`, so all hotspots grouped at y=0 (behind the background).

**Fix** (in `room_setup.gd`, applied to all rooms automatically):
- `$Background.z_index = -1` — z_index takes precedence over y-sort, so background always renders behind
- `$Hotspots.y_sort_enabled = true` — each hotspot sorts at its own y position

### Issue 3: Camera not properly constrained

**Symptom**: Camera followed the player position, showing only part of the room instead of the full 320x180 viewport.

**Root cause**: Popochiu's `setup_camera()` only sets camera limits when the room is LARGER than the viewport. Since rooms are exactly 320x180 (same as viewport), limits were never set, leaving Godot defaults that allowed the camera to follow the player off-center.

**Fix**: `room_setup.gd` continuously enforces camera limits `(0, 0, 320, 180)` in `_process()`, locking the view to show the full room.

---

## Part 1: Player Character (EDITOR) ✅

Created via Popochiu Dock > Characters > "+":
- **Name**: `Player`
- Placeholder sprite: colored rectangle PNG (`player.png`)
- Set as player character in Popochiu settings

Generates: `game/characters/player/character_player.tscn + .gd`

---

## Part 2: Room Shells (EDITOR) ✅

Created 3 rooms via Popochiu Dock > Rooms > "+". For each room:
- Background prop (320x180 colored rectangle, different color per room)
- Walkable area `Main` (polygon covering the floor)
- `has_player = true` on each room

| Room | Name | Background Color | Purpose |
|------|------|-----------------|---------|
| Entrance Hall | `EntranceHall` | Light beige/brown | Starting room + final exit |
| Living Room | `LivingRoom` | Warm orange | Marco's room, fireplace, drawer |
| Study | `Study` | Dark green/brown | Mrs. Whitmore's room, safe |

`EntranceHall` set as the **main scene**.

---

## Part 3: Markers (EDITOR) ✅

| Room | Marker | Purpose |
|------|--------|---------|
| EntranceHall | `Start` | Game start |
| EntranceHall | `FromLivingRoom` | Return from Living Room |
| EntranceHall | `FromStudy` | Return from Study |
| LivingRoom | `FromEntranceHall` | Entry from Entrance Hall |
| Study | `FromEntranceHall` | Entry from Entrance Hall |

---

## Part 4: Props & Hotspots (EDITOR) ✅

All created via Popochiu Dock with placeholder textures, positions, interaction polygons, and descriptions.

### Entrance Hall
**Props**: FrontDoor, WallClock, CoatRack, Mirror
**Hotspots**: WelcomeMat, DoorToLivingRoom, DoorToStudy

### Living Room
**Props**: Fireplace, FireplaceCompartment, SmallDrawer, Bookshelf, Couch, BirthdayCake, Painting
**Hotspots**: MantleInscription, DoorToEntranceHall

### Study
**Props**: Safe, Desk, FilingCabinet, BarredWindow, FramedCertificate
**Hotspots**: WallWriting, DoorToEntranceHall

**Total: 1 character, 3 rooms, 3 walkable areas, 5 markers, 16 props, 7 hotspots**

---

## Part 5: Script Logic (CLI — Claude) ✅

### 5.1 Room Scripts — Player positioning + GameState tracking ✅
### 5.2 Door Transitions — Hotspot scripts ✅
### 5.3 Interactive Props — Puzzle logic ✅
### 5.4 Victory Condition ✅

---

## Runtime Fixes (room_setup.gd)

The `RoomSetup` autoload applies fixes to every room at runtime:
1. **Y-sort fix**: Background z_index = -1, Hotspots y_sort enabled
2. **Camera fix**: Limits locked to 0,0,320,180 every frame
3. **Texture loading**: Loads placeholder.png for props/hotspots missing textures

---

## Verification Checklist

- [x] Player appears in Entrance Hall at game start
- [x] Room transitions: Entrance↔Living Room, Entrance↔Study (4 doors work)
- [x] Player positioned at correct marker based on origin room
- [x] `GameState.rooms_visited` updates on each room entry
- [x] Wall Clock: "stuck at 4:15"
- [x] Fireplace Compartment: 1st click hint, 2nd click → Gloves in inventory
- [x] Compartment stays disabled after Gloves collected (even on re-entry)
- [x] Small Drawer: wrong item → "doesn't seem to work", Gloves → Photo in inventory
- [x] Photo right-click → "7_2" clue
- [x] Birthday Cake: "whose birthday?" hint
- [x] Wall Writing: "4 _ _ _" partial hint
- [x] Safe: click → combination UI, enter 4728 → FrontDoorKey, wrong code → feedback
- [x] Front Door: wrong item → failure, FrontDoorKey → victory dialogue
- [x] Full chain: Brick→Gloves→Drawer→Photo→(clues)→Safe 4728→Key→Door→Victory
- [x] All props/hotspots have examine text (no `E.command_fallback()` remaining)
- [x] All props visible regardless of y-position (y-sort fix verified)
- [x] Player movement works (click-to-walk, CombinationLock overlay fix verified)
