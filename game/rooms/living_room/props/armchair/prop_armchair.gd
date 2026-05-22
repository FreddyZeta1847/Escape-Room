# @popochiu-docs-ignore-class
@tool
extends PopochiuProp


func _on_click() -> void:
	await C.player.walk_to_clicked()
	await C.player.face_clicked()
	await C.player.say("A worn velvet armchair. Looks like someone sat here often.")


func _on_right_click() -> void:
	await C.player.say("The cushions are pressed in. The owner had a favorite spot.")
