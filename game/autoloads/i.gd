@tool
extends "res://addons/popochiu/engine/interfaces/i_inventory.gd"

# classes ----
const PIIGloves := preload("res://game/inventory_items/gloves/inventory_item_gloves.gd")
const PIIPhoto := preload("res://game/inventory_items/photo/inventory_item_photo.gd")
const PIIFrontDoorKey := preload("res://game/inventory_items/front_door_key/inventory_item_front_door_key.gd")
# ---- classes

# nodes ----
var Gloves: PIIGloves : get = get_Gloves
var Photo: PIIPhoto : get = get_Photo
var FrontDoorKey: PIIFrontDoorKey : get = get_FrontDoorKey
# ---- nodes

# functions ----
func get_Gloves() -> PIIGloves: return get_item_instance("Gloves")
func get_Photo() -> PIIPhoto: return get_item_instance("Photo")
func get_FrontDoorKey() -> PIIFrontDoorKey: return get_item_instance("FrontDoorKey")
# ---- functions

