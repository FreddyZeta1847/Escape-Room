# @popochiu-docs-ignore-class
@tool
extends PopochiuProp


func _on_click() -> void:
	await C.player.walk_to_clicked()
	await C.player.face_clicked()
	await C.player.say("An old record player. The vinyl on it reads: 'Nocturnes, Op. 9'.")


func _on_right_click() -> void:
	await C.player.say("Vinyl and brass. A relic from another era.")
