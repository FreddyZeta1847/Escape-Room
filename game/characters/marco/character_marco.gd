# @popochiu-docs-ignore-class
@tool
extends PopochiuCharacter

const Data := preload('character_marco_state.gd')

var state: Data = load("res://game/characters/marco/character_marco.tres")


#region Virtual ####################################################################################
func _on_room_set() -> void:
	pass


func _on_click() -> void:
	await C.player.walk_to_clicked()
	await C.player.face_clicked()
	DialogueUI.open_dialogue("Marco")


func _on_double_click() -> void:
	E.command_fallback()


func _on_right_click() -> void:
	await C.player.say("That's Marco, my friend. He looks scared.")


func _on_middle_click() -> void:
	E.command_fallback()


func _on_item_used(_item: PopochiuInventoryItem) -> void:
	E.command_fallback()


func _play_idle() -> void:
	super()


func _play_walk(target_pos: Vector2) -> void:
	super(target_pos)


func _play_talk() -> void:
	super()


func _play_grab() -> void:
	super()


func _on_movement_started() -> void:
	pass


func _on_movement_ended() -> void:
	pass


#endregion

#region Public #####################################################################################

## Called by DialogueUI when Marco's trust reaches 100.
func collaboration_cutscene() -> void:
	await say("Alright... for you, I'll do it.")
	await walk_to(Vector2(75, 50))  # Walk toward fireplace compartment
	await say("There... behind the brick. Take what's inside.")
	GameState.marco_collaborated = true


#endregion
