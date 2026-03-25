extends Node

## Singleton that tracks player progress throughout the game.
## Auto-wires to InteractionSystem signals and Popochiu's inventory signals.
## Provides get_state_summary() for LLM system prompt injection.

var items_collected: Array[String] = []
var rooms_visited: Array[String] = []
var puzzles_solved: Array[String] = []


func _ready() -> void:
	# Auto-track puzzle solves from InteractionSystem signals
	InteractionSystem.container_opened.connect(_on_puzzle_solved)
	InteractionSystem.combination_solved.connect(_on_puzzle_solved_simple)
	InteractionSystem.discovery_made.connect(_on_puzzle_solved_simple)

	# Auto-track item collection from Popochiu's inventory signal
	I.item_added.connect(_on_item_added)


func collect_item(item_id: String) -> void:
	if item_id not in items_collected:
		items_collected.append(item_id)


func visit_room(room_id: String) -> void:
	if room_id not in rooms_visited:
		rooms_visited.append(room_id)


func solve_puzzle(puzzle_id: String) -> void:
	if puzzle_id not in puzzles_solved:
		puzzles_solved.append(puzzle_id)


## Returns a formatted string for LLM system prompt injection.
func get_state_summary() -> String:
	var parts: Array[String] = []

	if rooms_visited.size() > 0:
		parts.append("Rooms visited: %s" % ", ".join(rooms_visited))

	if items_collected.size() > 0:
		parts.append("Items collected: %s" % ", ".join(items_collected))

	if puzzles_solved.size() > 0:
		parts.append("Puzzles solved: %s" % ", ".join(puzzles_solved))

	if parts.is_empty():
		return ""

	return "[GAME STATE: %s]" % ". ".join(parts)


# --- Signal callbacks ---

func _on_item_added(item: PopochiuInventoryItem, _animate: bool) -> void:
	collect_item(item.script_name)


func _on_puzzle_solved(prop_name: String, _item_name: String) -> void:
	solve_puzzle(prop_name)


func _on_puzzle_solved_simple(prop_name: String) -> void:
	solve_puzzle(prop_name)
