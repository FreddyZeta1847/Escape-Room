@tool
extends "res://addons/popochiu/engine/interfaces/i_room.gd"

# classes ----
const PREntranceHall := preload("res://game/rooms/entrance_hall/room_entrance_hall.gd")
const PRLivingRoom := preload("res://game/rooms/living_room/room_living_room.gd")
const PRStudy := preload("res://game/rooms/study/room_study.gd")
# ---- classes

# nodes ----
var EntranceHall: PREntranceHall : get = get_EntranceHall
var LivingRoom: PRLivingRoom : get = get_LivingRoom
var Study: PRStudy : get = get_Study
# ---- nodes

# functions ----
func get_EntranceHall() -> PREntranceHall: return get_runtime_room("EntranceHall")
func get_LivingRoom() -> PRLivingRoom: return get_runtime_room("LivingRoom")
func get_Study() -> PRStudy: return get_runtime_room("Study")
# ---- functions

