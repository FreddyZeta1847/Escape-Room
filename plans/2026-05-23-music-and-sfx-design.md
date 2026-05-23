# Music and SFX — Design

## Goal

Add audio to the escape room game: looping background music for the start menu, gameplay, and win screen, plus six interaction sound effects (UI clicks, item pickup, door open / locked / key turn, combo lock click). All audio routes through Popochiu's existing `AudioManager` so the existing volume-settings UI controls it without changes.

## Scope

In scope:
- Three music tracks (menu, gameplay, win) using user-supplied MP3 files already present at the repo root.
- Six SFX, sourced from Kenney.nl (CC0) and Freesound.org (CC0 filter).
- One small autoload (`Audio`) exposing semantic helpers (`Audio.click()`, `Audio.pickup()`, etc.) so call sites don't repeat string literals.
- AudioCue `.tres` resources for each track / sound.
- Hookups at the existing call sites listed below.

Out of scope:
- Per-room background music or crossfades between rooms (single shared `game_theme` for all rooms).
- Dialogue voice-over, footsteps, ambient room loops (rain, fireplace crackle, etc.).
- New volume-settings UI work — the existing `sound_volumes` component already covers Master / Music / SFX buses.
- Procedural / dynamic music.

## Approach

Approach A from the brainstorm: use Popochiu's `AudioManager` (autoload `A`) and `AudioCue` resources. Popochiu ships the buses (`Master`, `Music`, `SFX`), the play/stop/fade API, and the volume-settings UI already wired up. Bypassing it would mean duplicating that wiring.

## File Layout

```
game/audio/
  music/
    menu_theme.mp3        # moved from repo root
    game_theme.mp3        # moved from repo root
    win_theme.mp3         # moved from repo root
  sfx/
    ui_click.wav
    item_pickup.wav
    door_open.wav
    door_locked.wav
    key_turn.wav
    lock_click.wav
  cues/
    menu_theme.tres       # AudioCueMusic
    game_theme.tres       # AudioCueMusic
    win_theme.tres        # AudioCueMusic
    ui_click.tres         # AudioCueSound
    item_pickup.tres
    door_open.tres
    door_locked.tres
    key_turn.tres
    lock_click.tres
  audio.gd                # autoload helper — see below
```

Music MP3s are imported with **Loop** enabled (Import tab → Loop checkbox → Reimport) for `menu_theme` and `game_theme`. `win_theme` plays once, no loop.

## Autoload Helper

`game/audio/audio.gd`, registered as autoload `Audio`. Thin façade over `Popochiu.A` so call sites stay terse and the string-literal cue names live in one place.

```gdscript
extends Node

func play_menu_music() -> void:    A.play_music("menu_theme")
func play_game_music() -> void:    A.play_music("game_theme")
func play_win_music() -> void:     A.play_music("win_theme")
func stop_music(fade := 1.0) -> void: A.stop_music(fade)

func click() -> void:       A.play_sound("ui_click")
func pickup() -> void:      A.play_sound("item_pickup")
func door_open() -> void:   A.play_sound("door_open")
func door_locked() -> void: A.play_sound("door_locked")
func key_turn() -> void:    A.play_sound("key_turn")
func lock_click() -> void:  A.play_sound("lock_click")
```

(Exact `play_music` / `stop_music` / `play_sound` signatures will be confirmed against `addons/popochiu/engine/audio_manager/audio_manager.gd` during implementation; the autoload wraps whatever the real API is.)

## Hook Points

| Event | Call | File |
|---|---|---|
| Start menu opens | `Audio.play_menu_music()` | `game/ui/start_menu/start_menu.gd` `_ready()` |
| Any start-menu button pressed | `Audio.click()` | `start_menu.gd` button handlers |
| "Play" pressed | `Audio.stop_music()` → scene change | `start_menu.gd` |
| First gameplay room entered | `Audio.play_game_music()` | first room's `on_room_entered()` (idempotent — no-ops if same track already playing) |
| Win screen `_ready()` | `Audio.stop_music()` then `Audio.play_win_music()` | `game/ui/win_screen/win_screen.gd` |
| Win-screen button pressed | `Audio.click()` | `win_screen.gd` |
| Inventory item picked up | `Audio.pickup()` | `game/inventory_items/*/inventory_item_*.gd` `_on_click()` — or once in a shared place if Popochiu emits a pickup signal (decide during implementation) |
| Door opened | `Audio.door_open()` | door-prop scripts (currently `prop_front_door.gd`) |
| Door interacted while locked | `Audio.door_locked()` | same files, on locked branch |
| Key used on door | `Audio.key_turn()` | front-door-key inventory script `_on_use_with_other` |
| Combo lock dial tick | `Audio.lock_click()` | combo-lock prop script (if/when one exists; if not, deferred) |

## Volume Settings Integration

No changes required. The existing `game/gui/components/sound_volumes/sound_volumes.tscn` already drives the Master / Music / SFX buses that Popochiu's `AudioManager` routes through. Volume slider behaviour will work automatically once cues exist.

## Testing

Manual only:

1. Launch → menu music plays within ~1s.
2. Hover/click menu buttons → ui_click on each press.
3. Press Play → menu music fades, scene changes, game music starts.
4. Walk between rooms (study ↔ hallway ↔ living) → music keeps playing uninterrupted.
5. Pick up an item → pickup sound.
6. Click the locked front door without key → door_locked rattle.
7. Use key on front door → key_turn → door_open → scene end.
8. Open settings, set Music slider to 0 → music silent, SFX still audible.
9. Reach win screen → game music stops, win music plays once.

## Open Questions (resolve during implementation, not blockers)

- Does Popochiu's inventory emit a pickup signal we can subscribe to once, or do we need to call `Audio.pickup()` from each item's `_on_click()`? Check `addons/popochiu` during implementation; pick whichever needs less code.
- Combo-lock prop: does one exist yet? If not, `lock_click.tres` is created but unused — fine, costs nothing.

## Sourcing Checklist (SFX)

User to download these CC0 files into `game/audio/sfx/` before or during implementation:

- `ui_click.wav` — Kenney "Interface Sounds" pack, `click_001.ogg`
- `item_pickup.wav` — Kenney "RPG Audio" pack, `handleCoins.ogg` or similar
- `door_open.wav` — Freesound CC0 search: `wooden door open`
- `door_locked.wav` — Freesound CC0 search: `door rattle locked`
- `key_turn.wav` — Freesound CC0 search: `key turn lock`
- `lock_click.wav` — Kenney "Casino Audio" dial click, or Freesound `combination lock`

Implementation can proceed without these files using silent placeholders; sound starts working as soon as files are dropped in.
