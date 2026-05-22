# @popochiu-docs-ignore-class
@tool
extends PopochiuProp


func _on_click() -> void:
	await C.player.walk_to_clicked()
	await C.player.face_clicked()
	if not GameState.globe_kenya_marker_seen:
		await C.player.say("An old wooden globe. The borders look pre-war.")
		await C.player.say("Wait — there's a small red X marked on Kenya.")
		GameState.globe_kenya_marker_seen = true
	else:
		await C.player.say("The red X over Kenya is still there.")


func _on_right_click() -> void:
	await C.player.say("Continents and faded colors. A traveler's globe.")
