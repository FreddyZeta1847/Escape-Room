# @popochiu-docs-ignore-class
@tool
extends PopochiuProp


func _on_click() -> void:
	await C.player.walk_to_clicked()
	await C.player.face_clicked()
	await C.player.say("An umbrella stand. Empty — must have been a sunny week.")


func _on_right_click() -> void:
	await C.player.say("A wrought-iron umbrella stand near the door.")
