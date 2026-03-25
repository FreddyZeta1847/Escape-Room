# @popochiu-docs-ignore-class
@tool
extends PopochiuRoom

const Data := preload('room_entrance_hall_state.gd')

var state: Data = load("res://game/rooms/entrance_hall/room_entrance_hall.tres")


#region Virtual ####################################################################################
func _on_room_entered() -> void:
	GameState.visit_room("EntranceHall")

	if not C.player:
		return

	# Position the player based on where they came from
	if C.player.last_room.is_empty():
		C.player.position = $Markers/Start.position
	elif C.player.last_room == "LivingRoom":
		C.player.position = $Markers/FromLivingRoom.position
	elif C.player.last_room == "Study":
		C.player.position = $Markers/FromStudy.position


func _on_room_transition_finished() -> void:
	pass


func _on_room_exited() -> void:
	pass


#endregion
