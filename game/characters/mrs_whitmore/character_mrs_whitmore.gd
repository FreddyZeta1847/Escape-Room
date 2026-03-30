# @popochiu-docs-ignore-class
@tool
extends PopochiuCharacter

const Data := preload('character_mrs_whitmore_state.gd')

var state: Data = load("res://game/characters/mrs_whitmore/character_mrs_whitmore.tres")


#region Virtual ####################################################################################
func _on_room_set() -> void:
	pass


func _on_click() -> void:
	await C.player.walk_to_clicked()
	await C.player.face_clicked()
	DialogueUI.open_dialogue("MrsWhitmore")


func _on_double_click() -> void:
	E.command_fallback()


func _on_right_click() -> void:
	await C.player.say("Mrs. Whitmore, the housekeeper. She's been here for decades.")


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
