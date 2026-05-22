# @popochiu-docs-ignore-class
@tool
extends PopochiuProp

var lamp_on := false


func _on_click() -> void:
	await C.player.walk_to_clicked()
	await C.player.face_clicked()
	lamp_on = not lamp_on
	if lamp_on:
		await C.player.say("Click. The lamp warms up, casting a soft pool of light.")
	else:
		await C.player.say("Click. The lamp goes dark.")


func _on_right_click() -> void:
	await C.player.say("An old brass desk lamp. The switch still works.")
