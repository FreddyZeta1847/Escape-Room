# @popochiu-docs-ignore-class
@tool
extends PopochiuProp


func _on_click() -> void:
	await C.player.walk_to_clicked()
	await C.player.face_clicked()
	await C.player.say("A half-empty wine decanter. The wine inside smells stale.")


func _on_right_click() -> void:
	await C.player.say("Crystal decanter. Whoever drank from it left in a hurry.")
