# Known Issues

## 1. Prop InteractionPolygon not editable in Godot editor

Props have `InteractionPolygon` (CollisionPolygon2D) set to `visible = false`. Even when toggling visibility on, the polygon handles cannot be dragged or edited visually in the 2D viewport — unlike hotspot polygons which work fine. Inspector value changes revert on save because the visual editor overwrites them.

**Workaround**: Edit the `prop_*.tscn` file directly in a text editor (with Godot closed), changing the `polygon = PackedVector2Array(...)` line on the InteractionPolygon node.

## 2. Marco LLM hallucinating / breaking character

`qwen2.5:1.5b` sometimes ignores Marco's system prompt — sounds too cheerful, generic, or out-of-character instead of scared and nervous. Small models struggle with sustained role-play even with short prompts and seed messages.

**Current mitigations**: Simplified prompt, seed messages prepended to every request, keyword-based mood scoring in GDScript (not relying on LLM). Issue persists — only affects `llm_manager.gd`.
