extends Control

const ENTRANCE_HALL_SCENE := "res://game/rooms/entrance_hall/room_entrance_hall.tscn"
const TITLE_FLICKER_PERIOD := 1.8

@onready var title_label: Label = %TitleLabel
@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_panel: PanelContainer = %SettingsPanel


func _ready() -> void:
	_hide_popochiu_cursor()
	_connect_buttons()
	_start_title_flicker()
	settings_panel.visible = false
	play_button.grab_focus()
	A.play_music_cue("menu_theme", 1.0)


func _hide_popochiu_cursor() -> void:
	var root := get_tree().root
	if root.has_node("Cursor"):
		var cursor := root.get_node("Cursor")
		if cursor.has_method("toggle_visibility"):
			cursor.toggle_visibility(false)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _show_popochiu_cursor() -> void:
	var root := get_tree().root
	if root.has_node("Cursor"):
		var cursor := root.get_node("Cursor")
		if cursor.has_method("toggle_visibility"):
			cursor.toggle_visibility(true)


func _connect_buttons() -> void:
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _start_title_flicker() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(title_label, "modulate:a", 0.78, TITLE_FLICKER_PERIOD).set_trans(Tween.TRANS_SINE)
	tween.tween_property(title_label, "modulate:a", 1.0, TITLE_FLICKER_PERIOD).set_trans(Tween.TRANS_SINE)


func _on_play_pressed() -> void:
	_show_popochiu_cursor()
	A.stop("menu_theme", 1.0)
	A.play_music_cue("game_theme", 1.5)
	get_tree().change_scene_to_file(ENTRANCE_HALL_SCENE)


func _on_settings_pressed() -> void:
	settings_panel.visible = not settings_panel.visible


func _on_quit_pressed() -> void:
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and settings_panel.visible:
		settings_panel.visible = false
		get_viewport().set_input_as_handled()
