extends Control

const START_MENU_SCENE := "res://game/ui/start_menu/start_menu.tscn"

@onready var title_label: Label = %TitleLabel
@onready var stats_label: Label = %StatsLabel
@onready var play_again_button: Button = %PlayAgainButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	_hide_popochiu_cursor()
	_fill_stats()
	_connect_buttons()
	_start_title_flicker()
	play_again_button.grab_focus()
	A.safe_stop(A.game_theme, 0.8)
	A.win_theme.play(0.5)


func _hide_popochiu_cursor() -> void:
	var root := get_tree().root
	if root.has_node("Cursor"):
		var cursor := root.get_node("Cursor")
		if cursor.has_method("toggle_visibility"):
			cursor.toggle_visibility(false)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _connect_buttons() -> void:
	play_again_button.pressed.connect(_on_play_again_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _start_title_flicker() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(title_label, "modulate:a", 0.82, 1.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(title_label, "modulate:a", 1.0, 1.6).set_trans(Tween.TRANS_SINE)


func _fill_stats() -> void:
	var rooms := GameState.rooms_visited.size()
	var items := GameState.items_collected.size()
	var puzzles := GameState.puzzles_solved.size()
	stats_label.text = "Rooms visited: %d\nItems collected: %d\nPuzzles solved: %d" % [rooms, items, puzzles]


func _on_play_again_pressed() -> void:
	_reset_game_state()
	A.safe_stop(A.win_theme, 0.5)
	get_tree().change_scene_to_file(START_MENU_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _reset_game_state() -> void:
	GameState.items_collected.clear()
	GameState.rooms_visited.clear()
	GameState.puzzles_solved.clear()
	GameState.marco_mood = 0
	GameState.marco_collaborated = false
