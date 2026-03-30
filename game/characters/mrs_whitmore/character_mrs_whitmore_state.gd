# @popochiu-docs-ignore-class
extends PopochiuCharacterData


#region Virtual ####################################################################################
func _on_save() -> Dictionary:
	return {}


func _on_load(data: Dictionary) -> void:
	prints(data)


#endregion
