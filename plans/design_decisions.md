# Phase 4 — Design Decisions

## D1: Safe Combination UI

**Problem**: The combination lock panel (200x160) exceeds the 180px viewport height. Try/Close buttons are cut off.

**Fix needed**: Make the UI more compact (smaller buttons, tighter spacing) or restructure the layout to fit within the viewport.

---

## D2: Inventory Bar

**Problem**: No visible inventory bar in the top of the screen. Popochiu's Simple Click GUI should have one but it may not be configured.

**Fix needed**: Check Popochiu GUI configuration and enable/fix the inventory display.

---

## D3: The Brick + Marco Puzzle (Core Design)

### The Problem

The loose brick in the fireplace gives the player Gloves. But if clicking the brick is enough to get them, Marco becomes optional. The player must be forced through Marco in a way that feels realistic.

### Rejected Options

**Option 1 — Brick not inspectable until Marco hints**
- Unrealistic: why would a brick become clickable after a conversation?
- Chicken-and-egg: player won't ask Marco about a brick they don't know exists

**Option 2 — Brick is visible, suggests talking to Marco**
- Too hand-holdy, and Marco still isn't strictly required
- Player could brute-force by trying everything on the brick

### Chosen Design: Option 3b — Fireplace Poker as Gate

Instead of a new item (crowbar), repurpose a prop already in the living room: the **fireplace poker**.

**How it works:**

| Element | Before Marco's hint | After Marco's hint |
|---------|---------------------|-------------------|
| Loose brick | Clickable: *"This brick feels different from the others... but it won't budge"* | Same message — until poker is used on it |
| Fireplace poker | Examine only: *"An old iron poker. Dusty but sturdy."* | **Collectible** — clicking adds it to inventory |
| Using poker on brick | N/A (poker not in inventory) | Opens compartment → player gets **Gloves** |

**Why this works:**
- Poker is always visible — no items appearing from nowhere (realistic)
- Player can't brute-force it — bare hands can't move the brick, and poker isn't collectible until Marco hints
- Marco is truly essential — his poetic hints lead the player to realize the poker is the tool
- Uses the existing attribute system: poker has `["leverage"]`, brick's `required_attribute = "leverage"`

**Game state flag**: `marco_hinted_leverage` — set to `true` when Marco's hint level reaches the point where he mentions leverage/tool concepts. When true, clicking the poker makes it collectible.

**Marco's hint progression (poetic → clearer):**
1. *"Where warmth once danced, secrets rest in stone's embrace..."*
2. *"The hearth's own servant holds more power than it knows. Not everything yields to bare hands."*
3. *"Leverage, my friend — iron and stone have an old understanding. Look beside where the fire once breathed."*

### Open Question: Hint Detection

How does the game know Marco has given the leverage hint if the dialogue is free-form LLM text? Options:
- **Turn-count based**: After N exchanges about the fireplace/room, set the flag
- **Keyword detection on LLM output**: Scan Marco's responses for trigger words (leverage, poker, iron, tool, servant)
- **LLM-managed flag**: Ask the LLM to output a structured tag (e.g., `[HINT_GIVEN]`) alongside its response — risky with small models
- **Game-managed escalation**: Track hint_level per topic in GameState, inject it into the prompt. The game decides when to escalate, the LLM just phrases it

---

## D4: Marco's Role & Dialogue Space

### The Problem

If Marco only speaks in poetic metaphors, the conversational space is narrow. This undermines the point of having a real LLM — the player has limited reason to engage in free-form dialogue.

### Solution: Expand Marco Beyond Hints

Marco is a philosophy student and the player's **close friend**. His personality has multiple facets:

- **Casual/warm**: Talks naturally about the situation, the mansion, being trapped
- **Philosophical**: Shares observations, quotes thinkers, theorizes about why they're here
- **Observant**: Comments on objects, Mrs. Whitmore, the atmosphere
- **Cryptic (hints only)**: The poetic/metaphoric style applies specifically to puzzle hints, not to all dialogue

This gives the LLM conversational freedom (the player can ask Marco about anything) while keeping hint delivery as a distinct, recognizable mode.

**Example conversation flow:**
> **Player**: "What do you think about this room?"
> **Marco**: "It's got a strange energy. Like the walls are listening. Reminds me of Sartre — hell isn't other people, sometimes it's old furniture."
>
> **Player**: "Have you noticed anything weird?"
> **Marco**: "Where warmth once danced, secrets rest in stone's embrace... but that's just how I see things."
>
> **Player**: "What do you mean about the warmth?"
> **Marco**: "The hearth's own servant holds more power than it knows. Leverage, my friend — not everything yields to bare hands."

### Updated System Prompt Direction

Marco's system prompt should reflect both facets:
- Personality: warm, witty, philosophical, observant — a real friend
- Hint mode: when the topic touches the fireplace/brick/secrets, shift to poetic/cryptic style
- Knowledge: knows about the poker + loose brick, noticed the clock, has opinions about the mansion
- Freedom: can discuss anything the player asks about — the escape, philosophy, Mrs. Whitmore, the room

---

## D5: New Item & Prop Additions

To implement Option 3b, Phase 4 needs:

| What | Type | Location | Details |
|------|------|----------|---------|
| Fireplace Poker | Prop → Inventory item | Living Room (next to fireplace) | `attributes: ["leverage"]`, collectible only when `marco_hinted_leverage == true` |

### Updated Puzzle Flow

1. Explore freely — all 3 rooms accessible
2. Talk to Marco — he progressively hints about the fireplace and the poker
3. **Pick up poker** (now collectible after Marco's hint)
4. **Use poker on loose brick** → opens compartment → get Gloves
5. Use Gloves on drawer → get Photo
6. Gather combination clues (clock, photo, Mrs. Whitmore)
7. Enter 4728 on safe → get Front Door Key
8. Use Key on front door → escape

---

## References

- [LLMs as NPCs survey (arxiv 2402.18659)](https://arxiv.org/html/2402.18659v1)
- `plans/questions.md` — open technical questions for Phase 4 implementation
- `plans/plan.md` — master project plan
