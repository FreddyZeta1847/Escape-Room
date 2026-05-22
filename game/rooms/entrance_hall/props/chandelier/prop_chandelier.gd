# @popochiu-docs-ignore-class
@tool
extends PopochiuProp


func _on_click() -> void:
	await C.player.walk_to_clicked()
	await C.player.face_clicked()
	await C.player.say("A dusty chandelier hangs above. Half the bulbs are out.")


func _on_right_click() -> void:
	await C.player.say("Crystal chandelier. It hasn't been cleaned in years.")
