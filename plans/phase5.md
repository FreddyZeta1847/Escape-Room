# Phase 5: Art Pass

## Goal

Replace all placeholder art (solid colored rectangles) with real pixel art. The game should look finished.

## Design Decisions

| Topic | Decision |
|-------|----------|
| Art source | Hybrid: Szadi Art "Cozy Interior" tileset (free, 16x16, itch.io) for walls/floors/standard furniture + AI-generated sprites for unique props |
| Perspective | 3/4 top-down (RPG-style angled view) |
| Mood/atmosphere | Cozy-dark Victorian mansion — warm wood tones, fireplaces, old library at night |
| Room backgrounds | Pre-rendered 320x180 PNGs composed from tileset in image editor. Props are separate sprites on top. |
| Unique props | User generates externally with AI tools, integrates as transparent PNGs |
| Character animations | Sprite sheets with `region_rect` keyframes in AnimationPlayer. `flips_when = LOOKING_LEFT` to avoid separate left-facing sprites. |

---

## Asset List (33 total)

### Room Backgrounds (3) — Tileset-composed, 320x180 PNG

| Asset | File to overwrite | Notes |
|-------|-------------------|-------|
| Entrance Hall | `game/rooms/entrance_hall/bg_entrance_hall.png` | Victorian foyer, wooden floor, front door top-center, doorways left/right |
| Living Room | `game/rooms/living_room/bg_living_room.png` | Fireplace on wall, bookshelves, couch area, warm rug |
| Study | `game/rooms/study/bg_study.png` | Desk area, bookshelves, barred window, filing cabinet |

### Props (16) — Mix of tileset and AI-generated

**From tileset (extract/compose from Szadi Art tiles):**

| Prop | File | Size | Room |
|------|------|------|------|
| Front door | `entrance_hall/props/front_door/placeholder.png` | ~40x60 | Entrance Hall |
| Mirror | `entrance_hall/props/mirror/placeholder.png` | ~16x24 | Entrance Hall |
| Small drawer | `living_room/props/small_drawer/placeholder.png` | ~20x20 | Living Room |
| Bookshelf | `living_room/props/bookshelf/placeholder.png` | ~24x40 | Living Room |
| Desk | `study/props/desk/placeholder.png` | ~48x32 | Study |
| Filing cabinet | `study/props/filing_cabinet/placeholder.png` | ~20x32 | Study |

**AI-generated (unique/narrative props):**

| Prop | File | Size | Room |
|------|------|------|------|
| Wall clock | `entrance_hall/props/wall_clock/placeholder.png` | ~16x20 | Entrance Hall |
| Coat rack | `entrance_hall/props/coat_rack/placeholder.png` | ~16x32 | Entrance Hall |
| Fireplace | `living_room/props/fireplace/placeholder.png` | ~50x40 | Living Room |
| Loose brick | `living_room/props/fireplace_compartment/placeholder.png` | ~10x10 | Living Room |
| Couch | `living_room/props/couch/placeholder.png` | ~48x24 | Living Room |
| Birthday cake | `living_room/props/birthday_cake/placeholder.png` | ~16x16 | Living Room |
| Painting | `living_room/props/painting/placeholder.png` | ~24x20 | Living Room |
| Safe | `study/props/safe/placeholder.png` | ~25x25 | Study |
| Barred window | `study/props/barred_window/placeholder.png` | ~32x32 | Study |
| Framed certificate | `study/props/framed_certificate/placeholder.png` | ~16x16 | Study |

All prop paths are relative to `game/rooms/`.

### Hotspots (7) — Most become invisible

| Hotspot | Visibility | Notes |
|---------|-----------|-------|
| Welcome mat | Optional visible sprite (~32x16) | Could be baked into background |
| Door to living room | Invisible | Doorway baked into background |
| Door to study | Invisible | Doorway baked into background |
| Mantle inscription | Invisible | Part of fireplace area |
| Door to entrance (living room) | Invisible | Doorway baked into background |
| Wall writing | Optional subtle sprite | Could be invisible |
| Door to entrance (study) | Invisible | Doorway baked into background |

### Inventory Icons (4) — AI-generated, ~16x16 transparent PNG

| Icon | File |
|------|------|
| Front door key | `game/inventory_items/front_door_key/icon_front_door_key.png` |
| Gloves | `game/inventory_items/gloves/icon_gloves.png` |
| Photo (front) | `game/inventory_items/photo/icon_photo.png` |
| Photo (back) | `game/inventory_items/photo/icon_photo_back.png` |

### Character Sprite Sheets (3)

| Character | File | Frame size | Sheet layout | Animations needed |
|-----------|------|-----------|-------------|-------------------|
| Player | `game/characters/player/player.png` | 16x24 | 4 cols x 4 rows (64x96) | idle + walk for d/u/r (left auto-flipped) |
| Marco | `game/characters/marco/marco.png` | 16x24 | 3 cols x 3 rows (48x72) | idle_d, walk_d, walk_r |
| Mrs. Whitmore | `game/characters/mrs_whitmore/mrs_whitmore.png` | 16x24 | 1-2 frames (16x24 or 32x24) | idle_d only |

**Player sprite sheet layout:**
```
Row 0 (y=0):   walk_d frame0, walk_d frame1, idle_d frame0, idle_d frame1
Row 1 (y=24):  walk_u frame0, walk_u frame1, idle_u frame0, idle_u frame1
Row 2 (y=48):  walk_r frame0, walk_r frame1, idle_r frame0, idle_r frame1
Row 3 (y=72):  (spare row or talk frames)
```

---

## Workflow

### Step 1 — USER: Download tileset
Download Szadi Art "Cozy Interior" from itch.io (free, 16x16 tiles).

### Step 2 — USER: Compose 3 room backgrounds
Create 320x180 canvases in image editor (Aseprite, GIMP, Photoshop). Lay floors, walls, doorways from tileset. Export as PNG, overwrite existing `bg_*.png` files. **Backgrounds must come first** — they define the spatial layout everything else depends on.

### Step 3 — CLAUDE: Adjust walkable areas + markers
Reshape `NavigationPolygon` in each `walkable_area_main.tscn` to match new floor areas. Verify markers (Start, FromRoom) are within walkable area.

### Step 4 — USER: Create prop sprites (parallel with step 3)
Extract tileset-based props + generate AI props. Save as transparent PNGs. Overwrite `placeholder.png` in each prop directory (keep the filename).

### Step 5 — CLAUDE: Adjust prop integration
- Resize `InteractionPolygon` on each prop to match new sprite dimensions
- Add `ObstaclePolygon` vertices for floor-standing props (desk, couch, bookshelf, filing cabinet)
- Adjust `position`, `walk_to_point`, `look_at_point` in room `.tscn` if props shifted

### Step 6 — USER: Create character sprite sheets
16x24 per frame, grid-aligned, no padding between frames. Drop into character directories overwriting current PNGs.

### Step 7 — CLAUDE: Set up character animations
- Enable `region_enabled` + `region_rect` on Sprite2D
- Create `AnimationPlayer` animations (`idle_d`, `walk_d`, `walk_r`, etc.) with `region_rect` keyframes
- Set `flips_when = LOOKING_LEFT` (value 2) to auto-mirror for left movement
- Discrete keyframes (`update: 1`), 4 fps, looped (`loop_mode: 1`)

### Step 8 — USER: Create inventory icons
16x16 transparent PNGs, overwrite existing `icon_*.png` files. No code changes needed.

### Step 9 — CLAUDE: Hotspot cleanup + final pass
- Make door hotspots invisible, adjust interaction polygons to doorway positions
- Verify `texture_filter = 1` on all new sprites
- Fix z-ordering (wall props behind characters, y_sort for floor props)
- Test no broken resource references

---

## Technical Integration Details

### Prop replacement strategy
Overwrite `placeholder.png` with the real sprite (keep filename). No `.tscn` texture path changes needed. Claude adjusts `InteractionPolygon` to: `PackedVector2Array(-W/2, -H/2, W/2, -H/2, W/2, H/2, -W/2, H/2)`.

### Character animation format
AnimationPlayer uses `Animation` sub_resources with value tracks on `Sprite2D:region_rect`. Each keyframe is `Rect2(col*16, row*24, 16, 24)`. Discrete interpolation, loop mode 1, 4 fps.

### Walkable areas
Update `vertices`, `polygons`, and `outlines` in the `NavigationPolygon` sub_resource within `walkable_area_main.tscn`. Polygon traces visible floor area excluding walls and large furniture.

---

## Division of Labor

| Who | What |
|-----|------|
| **User** | All image files: 3 backgrounds, 16 props, 7 hotspots, 4 icons, 3 character sheets (33 assets) |
| **Claude Code** | All `.tscn` edits: positions, polygons, animations, z-ordering (~20 files) |

---

## Files Claude Code Will Modify

- `game/rooms/*/room_*.tscn` — prop positions, hotspot positions, marker positions
- `game/rooms/*/walkable_areas/main/walkable_area_main.tscn` — navigation polygons (3 files)
- `game/rooms/*/props/*/prop_*.tscn` — interaction/obstacle polygons (~16 files)
- `game/characters/*/character_*.tscn` — Sprite2D region, AnimationPlayer, flips_when (3 files)

---

## Verification

1. Launch game — all 3 rooms display new backgrounds with correct props
2. Walk between rooms — doorway hotspots trigger transitions, walkable areas feel natural
3. Click every prop — interaction polygons match visible sprites
4. Player walks in all 4 directions with animation
5. Marco cutscene: walks to fireplace with walk animation
6. Inventory icons display correctly in inventory bar
7. No props floating in wrong positions or clipping through walls
