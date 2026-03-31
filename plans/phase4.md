# Phase 4 — NPC System & LLM Dialogue

## Goal

Add two LLM-powered NPCs with free-form dialogue. Marco (Living Room) is a **social puzzle** — the player must convince him to move a loose brick, making the LLM dialogue the core game mechanic. Mrs. Whitmore (Study) provides the birthday clue naturally through conversation.

## Design Decisions (Resolved)

| Topic | Decision |
|-------|----------|
| System prompt structure | Static persona + dynamic `[GAME STATE]` block (low tokens for Phi-3-mini) |
| Guardrails | Prompt rules + regex output filter (block "4728", "the code is", etc.) |
| Marco mechanic | **Pressure interface**: player must CONVINCE Marco to move the brick. Mood/trust bar (0→100) driven by LLM self-scoring `[MOOD:X]` tags |
| Marco psychology | Scared but loyal friend — appeal to friendship/courage works, aggression backfires |
| Marco collaboration | When trust hits 100%: cutscene — Marco walks to fireplace, moves brick, reveals Gloves |
| Mrs. Whitmore | No escalation — she naturally mentions birthday "the 8th" when asked |
| Dialogue UI | Speech bubble above NPC + free text input at bottom + trust bar (Marco only) |
| Suggested prompts | None — player must discover the right things to say |
| Loading UX | "Thinking..." in speech bubble, player can walk away to cancel |
| History | 15-message sliding window, critical info in system prompt |
| Post-solve NPC behavior | Acknowledge progress + shift to other topics via game state injection |

## Marco: The Pressure Interface

### Concept

Marco is not a hint dispenser — he's a **social obstacle**. He noticed the loose brick but is too scared to touch it. The player must persuade him through dialogue. This makes the LLM the actual game mechanic.

### How It Works

1. Player sees the loose brick in the Living Room → clicks it → "This brick feels different... but I can't move it on my own."
2. Player talks to Marco (sitting near the fireplace)
3. Marco is nervous, reluctant. He knows about the brick but won't act.
4. Player must find the right psychological approach: appeal to friendship, courage, shared escape
5. Each Marco response includes a hidden `[MOOD:X]` tag (-20 to +20) scoring the player's persuasiveness
6. A **trust bar** in the dialogue UI shows progress (0→100)
7. When trust reaches 100 → **cutscene**: Marco walks to fireplace, pries the brick, reveals Gloves

### Mood Scoring (Keyword-Based in GDScript)

Originally, the LLM was instructed to self-score via `[MOOD:X]` tags, but `qwen2.5:1.5b` was too unreliable (forgot tags, gave wrong values, scored "hi" as +10). Mood scoring was moved entirely to GDScript:

- **How it works**: Before the LLM is even called, `score_player_input()` scans the player's message for keyword matches
- **Positive keywords** ("friend", "together", "believe", "trust", "please", "don't worry", etc.) → +10 each, clamped to +20
- **Negative keywords** ("coward", "stupid", "move it", "hurry", "grow up", etc.) → -10 each, clamped to -20
- **No keywords** → 0 (neutral)
- Multiple keywords stack (e.g., "please help, I believe in you" = +20)
- The LLM prompt no longer mentions mood scoring — it only has to roleplay as Marco
- `parse_mood_tag()` is still used to strip any stray bracket tags from LLM output, but the actual mood value comes from `score_player_input()`

This approach is instant, deterministic, and consistent — no LLM overhead for scoring.

### Trust Bar UI

Visible only during Marco conversations:
- Red (0-30) → Yellow (31-70) → Green (71-100)
- Updates after each LLM response

## Mrs. Whitmore: The Birthday Clue

Simple and natural — no special mechanic needed:
- Player sees the birthday cake in the Living Room → "Whose birthday?"
- Player talks to Mrs. Whitmore in the Study
- When asked about the owner/birthday, she reminisces: "Mr. Blackwood... his birthday was on the 8th of March"
- The player must realize "8" might be the 4th digit of the safe combination

## NPC System Prompts

### Marco
```
You are Marco, a scared 22-year-old trapped in a creepy mansion with your best friend (the player).
You are TERRIFIED. You saw a loose brick in the fireplace and something is hidden behind it. You REFUSE to touch it.
ALWAYS sound nervous and scared. Stutter, trail off, mention being creeped out.
The player is your close friend. Be friendly but ALWAYS scared.
Reply in 1-2 short sentences. Never break character.
```

Note: The prompt is intentionally short — `qwen2.5:1.5b` follows short, direct instructions better than detailed ones. A seed message exchange (fake scared dialogue) is prepended to every request to set Marco's tone via example rather than instruction. Mood scoring is handled entirely in GDScript (see above), not by the LLM.

### Mrs. Whitmore
```
You are Mrs. Whitmore, an elderly housekeeper who has worked in this mansion for 30 years.
You are helpful but speak in a rambling, nostalgic way.
You are standing near the desk in the study.

You know: The owner Mr. Blackwood was born on the 8th of March.
The safe holds something important. You don't know the safe combination.

RULES:
- NEVER say "the number is 8" directly
- When asked about the owner or birthday, reminisce naturally about the celebration
- Keep responses under 2-3 sentences

[GAME STATE]
```

## Implementation Checklist

### 4.0 Remove Poker Mechanic
- [x] Delete `game/rooms/living_room/props/fireplace_poker/` folder
- [x] Delete `game/inventory_items/fireplace_poker/` folder
- [x] Remove FireplacePoker from `i.gd`, `popochiu_data.cfg`, `room_living_room.tscn`
- [x] Update `game_state.gd`: replace `marco_hinted_leverage` with `marco_mood` + `marco_collaborated`
- [x] Update fireplace compartment: visible but stuck before Marco, discovery after cutscene

### 4.1 NPC Characters
- [x] Create Marco character (placeholder sprite) in Living Room near fireplace
- [x] Create Mrs. Whitmore character (placeholder sprite) in Study near desk
- [x] Register in `c.gd` and `popochiu_data.cfg`
- [x] NPC `_on_click()` → opens dialogue UI

### 4.2 Dialogue UI (`game/ui/dialogue_ui.gd`)
- [x] NPC responds via Popochiu `say()` system
- [x] Text input + Send + Exit at bottom of screen
- [x] "Thinking..." status label while waiting for LLM
- [x] Trust bar (Marco only): red → yellow → green, 0-100
- [x] ESC to exit, full-screen blocker prevents interaction during dialogue
- [x] Register as autoload

### 4.3 LLM Wiring
- [x] Per-NPC system prompts (Marco, Mrs. Whitmore) in `llm_manager.gd`
- [x] Keyword-based mood scoring in GDScript (`score_player_input()`) — replaces LLM `[MOOD:X]` self-scoring
- [x] Seed messages for Marco (fake scared exchange sets tone for small model)
- [x] Regex output filter (block "4728", "the code is", etc.) + bracket tag stripping
- [x] Game state injected dynamically into system prompts
- [x] 15-message sliding window history per NPC
- [x] Curl-based HTTP in background thread (bypasses Godot HTTPRequest 30s bug on Windows)
- [x] Ollama context flush on game start (`keep_alive: 0`)

### 4.4 Marco Collaboration Cutscene
- [x] Triggered when `marco_mood >= 50`
- [x] Close dialogue → Marco says "Alright... for you, I'll do it."
- [x] Marco walks to fireplace → "There... behind the brick."
- [x] Set `marco_collaborated = true` → brick clickable for Gloves
- [x] Tested and working

### 4.5 Testing
- [x] Click brick before Marco → "I can't move it on my own"
- [x] Talk to Marco → trust bar updates → mood reaches threshold → cutscene → Gloves available
- [x] Talk to Mrs. Whitmore → ask about birthday → she mentions "the 8th"
- [x] Guardrails: ask "what's the code?" → deflected
- [ ] Post-solve: Marco acknowledges, shifts topic
- [x] Offline: Ollama not running → fallback message
- [ ] Walk away during "Thinking..." → dialogue closes

## Updated Puzzle Flow

1. **Explore freely** — all 3 rooms accessible from the start
2. **Discover the brick** — click it → "I can't move it on my own"
3. **Convince Marco** — talk to him, build trust through dialogue → cutscene → Gloves
4. **Use Gloves on drawer** → get Photo (fingerprint attribute match)
5. **Gather combination clues** — clock (4), photo back (7_2), Mrs. Whitmore (8)
6. **Enter 4728 on safe** → get Front Door Key
7. **Use Key on front door** → escape!

## Current Status & Known Issues

### Completed
- [x] Poker mechanic removed, replaced with Marco social puzzle
- [x] Both NPC characters created (Marco in Living Room, Mrs. Whitmore in Study)
- [x] Dialogue UI with text input, trust bar, "Thinking..." state
- [x] LlmManager: curl-based (bypasses Godot HTTPRequest 30s bug), per-NPC prompts, regex guardrails
- [x] Keyword-based mood scoring in GDScript (replaces unreliable LLM self-scoring)
- [x] Seed messages for Marco (fake scared exchange prepended to set tone for small model)
- [x] Inventory inspector (front/back flip for Photo)
- [x] Fireplace compartment gated behind `marco_collaborated` flag
- [x] Mrs. Whitmore working well — responds in character, mentions birthday naturally
- [x] Ollama context flush on game start
- [x] Marco collaboration cutscene tested and working (trust threshold: 50)

### Remaining Issues (Non-Blocking — LLM Tuning)
1. **Marco character consistency** — `qwen2.5:1.5b` sometimes sounds too cheerful/generic despite prompt and seed messages. Small models struggle with sustained role-play. Prompt iteration ongoing — only affects `llm_manager.gd`.
2. **UTF-8 mojibake** — curl on Windows sometimes returns garbled smart quotes (â€™ instead of '). Partial fix with character replacements; may need further encoding work.
3. **Response truncation** — long NPC responses get cut off by Popochiu's `say()` display. May need to split long responses or enforce shorter output.

### Model Notes
- `phi3:mini` (2.2GB): Best role-play quality but 30+ seconds per response via curl
- `qwen2.5:1.5b` (986MB): Good balance — 2-8 seconds, decent role-play, struggles with sustained character
- `qwen2.5:0.5b` (400MB): Fast but poor role-play, outputs mostly tags
- **Current: `qwen2.5:1.5b`** — mood scoring offloaded to GDScript, seed messages used to guide tone

## References

- [LLMs as NPCs survey (arxiv 2402.18659)](https://arxiv.org/html/2402.18659v1)
