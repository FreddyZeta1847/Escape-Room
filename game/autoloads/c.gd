@tool
extends "res://addons/popochiu/engine/interfaces/i_character.gd"

# classes ----
const PCPlayer := preload("res://game/characters/player/character_player.gd")
const PCMarco := preload("res://game/characters/marco/character_marco.gd")
const PCMrsWhitmore := preload("res://game/characters/mrs_whitmore/character_mrs_whitmore.gd")
# ---- classes

# nodes ----
var Player: PCPlayer : get = get_Player
var Marco: PCMarco : get = get_Marco
var MrsWhitmore: PCMrsWhitmore : get = get_MrsWhitmore
# ---- nodes

# functions ----
func get_Player() -> PCPlayer: return get_runtime_character("Player")
func get_Marco() -> PCMarco: return get_runtime_character("Marco")
func get_MrsWhitmore() -> PCMrsWhitmore: return get_runtime_character("MrsWhitmore")
# ---- functions

