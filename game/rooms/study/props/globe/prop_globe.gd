# @popochiu-docs-ignore-class
@tool
extends PopochiuProp


func _on_click() -> void:
	await C.player.walk_to_clicked()
	await C.player.face_clicked()
	await C.player.say("An old wooden globe. The borders look pre-war.")


func _on_right_click() -> void:
	await C.player.say("Continents and faded colors. A traveler's globe.")
