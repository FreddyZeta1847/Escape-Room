extends CanvasLayer

## A 4-digit combination lock UI overlay.
## Shows a panel with 4 digit spinners (up/down arrows), a Try button, and a Close button.
## Calls InteractionSystem.try_combination() on submit.
##
## Usage:
##   CombinationLock.show_lock("4728", ["FrontDoorKey"], "Safe")
##   CombinationLock.lock_solved.connect(_on_safe_opened)

## Emitted when the correct combination is entered.
signal lock_solved
## Emitted when the player closes the lock UI without solving it.
signal lock_closed

var _correct_code := ""
var _contained_items: Array = []
var _prop_name := ""
var _digits := [0, 0, 0, 0]
var _digit_labels: Array[Label] = []
var _feedback_label: Label
var _panel: PanelContainer
var _bg: ColorRect
var _is_open := false


func _ready() -> void:
	_build_ui()
	# BUG FIX: Previously only _panel was hidden, but _bg (full-screen ColorRect with
	# mouse_filter=STOP on CanvasLayer 100) stayed visible — blocking ALL mouse input
	# and darkening the screen with a 60% black overlay.
	_bg.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


## Show the combination lock overlay.
## correct_code: the code to match (e.g. "4728")
## contained_items: items to give on success (passed to InteractionSystem)
## prop_name: name of the prop for signals/tracking
func show_lock(correct_code: String, contained_items: Array, prop_name: String) -> void:
	if _is_open:
		return
	_correct_code = correct_code
	_contained_items = contained_items
	_prop_name = prop_name
	_digits = [0, 0, 0, 0]
	_update_digit_labels()
	_feedback_label.text = ""
	_bg.visible = true
	_is_open = true
	get_tree().paused = true


func hide_lock() -> void:
	_bg.visible = false
	_is_open = false
	get_tree().paused = false


func _build_ui() -> void:
	layer = 100

	# Full-screen dimming background (hidden by default, shown when lock opens)
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.6)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	# Centered panel
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(200, 120)
	_panel.position = Vector2(-100, -60)
	_bg.add_child(_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(main_vbox)

	# Title
	var title := Label.new()
	title.text = "Enter Combination"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)

	# Digit spinners row
	var digits_hbox := HBoxContainer.new()
	digits_hbox.add_theme_constant_override("separation", 8)
	digits_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(digits_hbox)

	for i in range(4):
		var digit_col := VBoxContainer.new()
		digit_col.alignment = BoxContainer.ALIGNMENT_CENTER
		digits_hbox.add_child(digit_col)

		var up_btn := Button.new()
		up_btn.text = "^"
		up_btn.custom_minimum_size = Vector2(24, 18)
		up_btn.pressed.connect(_on_digit_up.bind(i))
		digit_col.add_child(up_btn)

		var digit_label := Label.new()
		digit_label.text = "0"
		digit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		digit_label.custom_minimum_size = Vector2(24, 18)
		digit_col.add_child(digit_label)
		_digit_labels.append(digit_label)

		var down_btn := Button.new()
		down_btn.text = "v"
		down_btn.custom_minimum_size = Vector2(24, 18)
		down_btn.pressed.connect(_on_digit_down.bind(i))
		digit_col.add_child(down_btn)

	# Feedback label
	_feedback_label = Label.new()
	_feedback_label.text = ""
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_color_override("font_color", Color.INDIAN_RED)
	main_vbox.add_child(_feedback_label)

	# Buttons row
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 10)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(btn_hbox)

	var try_btn := Button.new()
	try_btn.text = "Try"
	try_btn.custom_minimum_size = Vector2(50, 20)
	try_btn.pressed.connect(_on_try_pressed)
	btn_hbox.add_child(try_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(50, 20)
	close_btn.pressed.connect(_on_close_pressed)
	btn_hbox.add_child(close_btn)


func _on_digit_up(index: int) -> void:
	_digits[index] = (_digits[index] + 1) % 10
	_update_digit_labels()


func _on_digit_down(index: int) -> void:
	_digits[index] = (_digits[index] - 1 + 10) % 10
	_update_digit_labels()


func _update_digit_labels() -> void:
	for i in range(4):
		_digit_labels[i].text = str(_digits[i])


func _on_try_pressed() -> void:
	var entered := "%d%d%d%d" % [_digits[0], _digits[1], _digits[2], _digits[3]]
	var success := await InteractionSystem.try_combination(
		entered, _correct_code, _contained_items, _prop_name
	)
	if success:
		hide_lock()
		lock_solved.emit()
	else:
		_feedback_label.text = "Wrong combination..."


func _on_close_pressed() -> void:
	hide_lock()
	lock_closed.emit()
