# Phase 4 — Open Design Questions

## Q1: System Prompt Structure

**Option A — Static persona + dynamic state block**
One fixed persona section (personality, knowledge, rules) + a `[GAME STATE]` block rebuilt each turn. Simple, low token count — good for Phi-3-mini's small context.

**Option B — Layered prompt**
Separate sections: `[IDENTITY]`, `[KNOWLEDGE]`, `[RULES]`, `[GAME STATE]`, `[HINT DIRECTIVES]`. Each updated independently. More tokens but finer control over hint progression and behavior.

**Recommendation**: Option A — keeps token count low for the small model.

---

## Q2: Guardrails / Information Leak Prevention

Phi-3-mini is small and may break character rules more easily than larger models. Players can ask bluntly ("what's the code?") or attempt prompt injection.

- **Prompt-only**: Rely on "NEVER say directly..." rules in the system prompt. Simpler but less reliable.
- **Prompt + output filter**: Post-process LLM responses with regex checks for forbidden patterns (e.g., "4728", "the code is", "combination is"). Replace matches with a deflection line.
- **How aggressive?** Accept some leakage, or hard-block any mention of the answer?

**Recommendation**: Prompt + light regex filter — catches the obvious leaks without over-engineering.

---

## Q3: Progressive Hint System

Marco gives 3 levels of poetic hints about the fireplace. Mrs. Whitmore progressively reveals the birthday. Who controls the progression?

- **LLM-managed**: Describe the 3 levels in the system prompt and trust the model to escalate naturally. Simpler but unreliable with small models.
- **Game-managed**: Track `hint_level` per NPC per puzzle in GameState. Inject the current level into the prompt (e.g., "Give a LEVEL 2 hint — more direct but still poetic"). The game controls *when* to escalate, the LLM controls *how* to phrase it.

**Recommendation**: Game-managed — more reliable with Phi-3-mini. The model generates natural language at the right directness level rather than tracking state itself.

---

## Q4: Dialogue UI Layout

- **Free text only**: Player types anything. Most natural, but small models may struggle with unusual inputs.
- **Hybrid**: Free text input + clickable suggested prompts (e.g., "Ask about the fireplace", "Ask about the owner"). Guides the player while still allowing free typing.
- **Display format**: Speech bubble above NPC? Bottom panel with portrait + text + input? Popochiu's built-in dialog system?

**Recommendation**: Bottom panel (NPC portrait + response text on top, text input + send/exit buttons at bottom) with suggested prompt buttons. Doesn't obscure the room, guides player interaction.

---

## Q5: Loading / UX During LLM Response

Phi-3-mini on CPU can take 5-15 seconds. How do we handle the wait?

- "Thinking..." text or animated dots in the dialogue panel?
- Disable input while waiting, or allow the player to walk away / cancel?
- If player exits conversation mid-request, discard the response or show it when they re-engage?

---

## Q6: Conversation Persistence & History Limits

Current: sliding window of 15 messages. Early conversation gets lost.

- Is 15 enough? Phi-3-mini has ~4K context — system prompt + 15 messages may already be tight.
- Should we summarize old messages instead of dropping them? (More complex, extra LLM call.)
- Or keep it simple: 15 messages + critical info always in the system prompt?

**Recommendation**: Keep 15-message window. Critical info (hints given, facts revealed) tracked in GameState and injected into system prompt so it's never lost.

---

## Q7: NPC Behavior When Puzzle Is Already Solved

What should Marco say after the player already found the fireplace compartment? What about Mrs. Whitmore after the safe is opened?

- Stop giving hints, shift to flavor dialogue?
- Acknowledge the player's progress? ("Ah, you found what the fire concealed...")
- Handled via game state injection: `[Player has already solved: fireplace compartment]`

---

## References

- [LLMs as NPCs survey (arxiv 2402.18659)](https://arxiv.org/html/2402.18659v1): Key takeaways — keep game state external and injected, use hybrid approaches (LLM + rule-based validation), output filtering for guardrails, RAG for long memory.
