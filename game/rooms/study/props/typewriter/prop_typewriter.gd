# @popochiu-docs-ignore-class
@tool
extends PopochiuProp


func _on_click() -> void:
	await C.player.walk_to_clicked()
	await C.player.face_clicked()
	await C.player.say("A typewriter. There's a half-finished letter still in the carriage.")


func _on_right_click() -> void:
	await C.player.say("Smith Corona, mid-century. The keys are jammed.")
