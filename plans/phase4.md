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

### Mood Scoring (LLM Self-Scoring)

Marco's system prompt instructs the LLM to append `[MOOD:X]` to every response:
- **Positive** (+5 to +20): player was kind, appealed to friendship, showed understanding of his fear
- **Negative** (-5 to -20): player was rude, demanding, dismissive
- **Zero** (0): off-topic or neutral

The tag is parsed out before displaying the response. The mood value is clamped to 0-100.

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
You are Marco, a young philosophy student and close friend of the player.
You are trapped in this mansion together. You are sitting near the fireplace in the living room.

PERSONALITY: You are scared of this place but deeply loyal to your friend.
You love philosophy and sometimes quote thinkers. You speak warmly but nervously.

SITUATION: You've noticed a loose brick in the fireplace that might hide something.
But you're terrified — you don't want to touch it. The player needs to convince you.

RULES:
- You are RELUCTANT to help with the brick. You need emotional persuasion.
- If the player appeals to your friendship, courage, or shared situation → warm up
- If the player is aggressive, dismissive, or rude → become more resistant
- NEVER directly say "convince me" or explain the mood mechanic
- Keep responses under 2-3 sentences
- At the END of every response, output [MOOD:X] where X is -20 to +20:
  * Positive: player was persuasive, kind, appealed to friendship/bravery
  * Negative: player was rude, demanding, dismissive of your fears
  * Zero: neutral or off-topic
  * This tag is HIDDEN from the player — always include it

[GAME STATE]
```

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
- [ ] Delete `game/rooms/living_room/props/fireplace_poker/` folder
- [ ] Delete `game/inventory_items/fireplace_poker/` folder
- [ ] Remove FireplacePoker from `i.gd`, `popochiu_data.cfg`, `room_living_room.tscn`
- [ ] Update `game_state.gd`: replace `marco_hinted_leverage` with `marco_mood` + `marco_collaborated`
- [ ] Update fireplace compartment: visible but stuck before Marco, discovery after cutscene

### 4.1 NPC Characters
- [ ] Create Marco character (placeholder sprite) in Living Room near fireplace
- [ ] Create Mrs. Whitmore character (placeholder sprite) in Study near desk
- [ ] Register in `c.gd` and `popochiu_data.cfg`
- [ ] NPC `_on_click()` → opens dialogue UI

### 4.2 Dialogue UI (`game/ui/dialogue_ui.gd`)
- [ ] Speech bubble above NPC (response text)
- [ ] Text input + Send + Exit at bottom of screen
- [ ] "Thinking..." animated state while waiting for LLM
- [ ] Trust bar (Marco only): red → yellow → green, 0-100
- [ ] ESC to exit, walking away cancels pending request
- [ ] Register as autoload

### 4.3 LLM Wiring
- [ ] Per-NPC system prompts (Marco, Mrs. Whitmore) in `llm_manager.gd`
- [ ] Parse `[MOOD:X]` from Marco's responses → update trust bar
- [ ] Regex output filter (block "4728", "the code is", etc.)
- [ ] Game state injected dynamically into system prompts
- [ ] 15-message sliding window history per NPC

### 4.4 Marco Collaboration Cutscene
- [ ] Triggered when `marco_mood >= 100`
- [ ] Close dialogue → Marco says "Alright... for you, I'll do it."
- [ ] Marco walks to fireplace → "There... behind the brick."
- [ ] Set `marco_collaborated = true` → brick clickable for Gloves

### 4.5 Testing
- [ ] Click brick before Marco → "I can't move it on my own"
- [ ] Talk to Marco → trust bar updates → mood reaches 100 → cutscene → Gloves available
- [ ] Talk to Mrs. Whitmore → ask about birthday → she mentions "the 8th"
- [ ] Guardrails: ask "what's the code?" → deflected
- [ ] Post-solve: Marco acknowledges, shifts topic
- [ ] Offline: Ollama not running → fallback message
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
- [x] LlmManager rewritten: curl-based (bypasses Godot HTTPRequest 30s bug), per-NPC prompts, mood parsing, regex guardrails
- [x] Inventory inspector (front/back flip for Photo)
- [x] Fireplace compartment gated behind `marco_collaborated` flag
- [x] Mrs. Whitmore working well — responds in character, mentions birthday naturally
- [x] Ollama context flush on game start

### Known Issues (In Progress)
1. **Marco mood scoring inconsistent** — `qwen2.5:1.5b` sometimes forgets `[MOOD:X]` tag or gives wrong values (e.g., -20 for friendly messages). Prompt has been iterated multiple times; current version uses explicit examples. Defaults to 0 when tag missing.
2. **Marco character consistency** — model occasionally breaks character (talks about itself in third person, or acts not scared). Smaller models struggle with sustained role-play. Current prompt uses "role-playing" framing which helps but isn't perfect.
3. **UTF-8 mojibake** — curl on Windows sometimes returns garbled smart quotes (â€™ instead of '). Partial fix with character replacements; may need further encoding work.
4. **Trust bar threshold** — set to 50 for easier testing. May need tuning once mood scoring is more reliable.
5. **Marco cutscene untested** — the collaboration sequence (walk to fireplace, move brick) hasn't been triggered yet in gameplay.
6. **Response truncation** — long NPC responses get cut off by Popochiu's `say()` display. May need to split long responses or enforce shorter output.

### Model Notes
- `phi3:mini` (2.2GB): Best role-play quality but 30+ seconds per response via curl
- `qwen2.5:1.5b` (986MB): Good balance — 2-8 seconds, decent role-play, some tag issues
- `qwen2.5:0.5b` (400MB): Fast but poor role-play, outputs mostly tags
- Current: `qwen2.5:1.5b`

## References

- [LLMs as NPCs survey (arxiv 2402.18659)](https://arxiv.org/html/2402.18659v1)
