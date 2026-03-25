@tool
extends "res://addons/popochiu/engine/interfaces/i_character.gd"

# classes ----
const PCPlayer := preload("res://game/characters/player/character_player.gd")
# ---- classes

# nodes ----
var Player: PCPlayer : get = get_Player
# ---- nodes

# functions ----
func get_Player() -> PCPlayer: return get_runtime_character("Player")
# ---- functions

