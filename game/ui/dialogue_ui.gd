extends CanvasLayer

## Dialogue UI overlay for NPC conversations.
## Shows a text input at the bottom. NPC responses use Popochiu's say() system.
## For Marco: also shows a trust bar (0-100).
## Does NOT pause the game — blocks interaction via UI overlay instead.

signal dialogue_closed

var _npc_id := ""
var _is_open := false
var _waiting_for_response := false

var _blocker: ColorRect
var _bg: ColorRect
var _input_bar: HBoxContainer
var _line_edit: LineEdit
var _send_btn: Button
var _exit_btn: Button
var _trust_bar: ColorRect
var _trust_label: Label
var _trust_container: HBoxContainer
var _status_label: Label


func _ready() -> void:
	_build_ui()
	_blocker.visible = false
	_bg.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func open_dialogue(npc_id: String) -> void:
	if _is_open:
		print("[DialogueUI] Already open, ignoring open_dialogue('%s')" % npc_id)
		return
	print("[DialogueUI] Opening dialogue with '%s'" % npc_id)
	_npc_id = npc_id
	_is_open = true
	_waiting_for_response = false
	_line_edit.text = ""
	_line_edit.editable = true
	_send_btn.disabled = false
	_status_label.text = ""
	_blocker.visible = true
	_bg.visible = true

	# Show trust bar only for Marco
	_trust_container.visible = (npc_id == "Marco")
	if npc_id == "Marco":
		_update_trust_bar()

	_line_edit.grab_focus()

	# Connect to LLM response
	if not LlmManager.chat_completed.is_connected(_on_chat_completed):
		LlmManager.chat_completed.connect(_on_chat_completed)


func close_dialogue() -> void:
	if not _is_open:
		return
	print("[DialogueUI] Closing dialogue with '%s'" % _npc_id)
	_blocker.visible = false
	_bg.visible = false
	_is_open = false
	_waiting_for_response = false
	_npc_id = ""

	if LlmManager.chat_completed.is_connected(_on_chat_completed):
		LlmManager.chat_completed.disconnect(_on_chat_completed)

	dialogue_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			close_dialogue()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if not _waiting_for_response:
				_on_send_pressed()
			get_viewport().set_input_as_handled()


func _on_send_pressed() -> void:
	if _waiting_for_response:
		print("[DialogueUI] Still waiting for response, ignoring send")
		return
	var text := _line_edit.text.strip_edges()
	if text.is_empty():
		return

	print("[DialogueUI] Sending message to '%s': %s" % [_npc_id, text])
	_line_edit.text = ""
	_line_edit.editable = false
	_waiting_for_response = true
	_send_btn.disabled = true
	_status_label.text = "Thinking..."

	# Send to LLM
	LlmManager.chat(_npc_id, text)


func _on_chat_completed(npc_id: String, response: String, mood_delta: int) -> void:
	print("[DialogueUI] Received response for '%s': %s" % [npc_id, response.left(80)])
	if npc_id != _npc_id or not _is_open:
		print("[DialogueUI] Ignoring response (npc_id mismatch or dialogue closed)")
		return

	_waiting_for_response = false
	_send_btn.disabled = false
	_line_edit.editable = true
	_status_label.text = ""

	# Update mood for Marco
	if npc_id == "Marco":
		print("[DialogueUI] Marco mood delta: %d (total: %d)" % [mood_delta, GameState.marco_mood + mood_delta])
		GameState.increment_marco_mood(mood_delta)
		_update_trust_bar()

	# Show response via Popochiu's say system
	var npc_char = _get_npc_character()
	if npc_char:
		await npc_char.say(response)

	if _is_open:
		_line_edit.grab_focus()

	# Check if Marco reached trust threshold
	if npc_id == "Marco" and GameState.marco_mood >= 50 and not GameState.marco_collaborated:
		await _trigger_marco_cutscene()


func _trigger_marco_cutscene() -> void:
	print("[DialogueUI] Triggering Marco collaboration cutscene")
	close_dialogue()
	var marco = C.Marco
	if marco:
		await marco.collaboration_cutscene()


func _get_npc_character():
	match _npc_id:
		"Marco":
			return C.Marco
		"MrsWhitmore":
			return C.MrsWhitmore
	return null


func _update_trust_bar() -> void:
	_trust_label.text = "Trust: %d%%" % GameState.marco_mood
	# Resize the fill bar (parent is 60px wide)
	var fill_width := 60.0 * (GameState.marco_mood / 100.0)
	_trust_bar.custom_minimum_size.x = fill_width
	_trust_bar.size.x = fill_width
	# Color: red → yellow → green
	if GameState.marco_mood >= 70:
		_trust_bar.color = Color(0.3, 0.9, 0.3)
	elif GameState.marco_mood >= 30:
		_trust_bar.color = Color(0.9, 0.9, 0.3)
	else:
		_trust_bar.color = Color(0.9, 0.3, 0.3)


func _apply_small_font(control: Control) -> void:
	control.add_theme_font_size_override("font_size", 7)


func _build_ui() -> void:
	layer = 99
	follow_viewport_enabled = true

	# Full-screen transparent blocker — stops all clicks on the game behind
	_blocker = ColorRect.new()
	_blocker.color = Color(0, 0, 0, 0.0)
	_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_blocker)

	# Thin bar at very bottom — only ~18px tall in 320x180
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.7)
	_bg.anchor_left = 0.0
	_bg.anchor_right = 1.0
	_bg.anchor_top = 1.0
	_bg.anchor_bottom = 1.0
	_bg.offset_top = -42
	_bg.offset_bottom = 0
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_bg.add_child(vbox)

	# Status label (shows "Thinking..." while waiting)
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3))
	_apply_small_font(_status_label)
	vbox.add_child(_status_label)

	# Trust bar (Marco only) — using a ColorRect instead of ProgressBar for compact size
	_trust_container = HBoxContainer.new()
	_trust_container.add_theme_constant_override("separation", 2)
	_trust_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_trust_container.visible = false
	vbox.add_child(_trust_container)

	_trust_label = Label.new()
	_trust_label.text = "Trust: 0%"
	_apply_small_font(_trust_label)
	_trust_container.add_child(_trust_label)

	# Custom thin bar using nested ColorRects
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.3, 0.3, 0.3)
	bar_bg.custom_minimum_size = Vector2(60, 4)
	_trust_container.add_child(bar_bg)

	_trust_bar = ColorRect.new()
	_trust_bar.color = Color(0.9, 0.3, 0.3)
	_trust_bar.custom_minimum_size = Vector2(0, 4)
	_trust_bar.size = Vector2(0, 4)
	bar_bg.add_child(_trust_bar)

	# Input row
	_input_bar = HBoxContainer.new()
	_input_bar.add_theme_constant_override("separation", 1)
	_input_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_input_bar)

	_line_edit = LineEdit.new()
	_line_edit.placeholder_text = "Type..."
	_line_edit.custom_minimum_size = Vector2(0, 10)
	_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_small_font(_line_edit)
	_input_bar.add_child(_line_edit)

	_send_btn = Button.new()
	_send_btn.text = ">"
	_send_btn.custom_minimum_size = Vector2(14, 10)
	_apply_small_font(_send_btn)
	_send_btn.pressed.connect(_on_send_pressed)
	_input_bar.add_child(_send_btn)

	_exit_btn = Button.new()
	_exit_btn.text = "X"
	_exit_btn.custom_minimum_size = Vector2(14, 10)
	_apply_small_font(_exit_btn)
	_exit_btn.pressed.connect(close_dialogue)
	_input_bar.add_child(_exit_btn)
