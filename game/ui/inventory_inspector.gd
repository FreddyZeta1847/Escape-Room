extends CanvasLayer

## Inventory item inspection overlay.
## Shows a large view of an inventory item with optional front/back flip.
##
## Usage:
##   InventoryInspector.show_item("Photo")

signal inspector_closed

var _bg: ColorRect
var _panel: PanelContainer
var _item_sprite: TextureRect
var _item_name_label: Label
var _side_label: Label
var _flip_btn: Button
var _is_open := false
var _showing_front := true
var _front_texture: Texture2D
var _back_texture: Texture2D


func _ready() -> void:
	_build_ui()
	_bg.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_item(item_name: String) -> void:
	if _is_open:
		return
	if CombinationLock and CombinationLock._is_open:
		return

	var item: PopochiuInventoryItem = I.get_item_instance(item_name)
	if not item:
		push_warning("InventoryInspector: item '%s' not found" % item_name)
		return

	_front_texture = item.texture
	_back_texture = item.back_texture if "back_texture" in item else null

	_item_sprite.texture = _front_texture
	_item_name_label.text = item.description if item.description else item_name
	_showing_front = true
	_side_label.text = "Front"
	_flip_btn.visible = _back_texture != null

	_bg.visible = true
	_is_open = true
	var cursor_node = get_tree().root.find_child("Cursor", true, false)
	if cursor_node:
		cursor_node.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true


func hide_item() -> void:
	_bg.visible = false
	_is_open = false
	get_tree().paused = false
	inspector_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				hide_item()
			KEY_F, KEY_SPACE:
				if _back_texture:
					_on_flip_pressed()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	layer = 100
	follow_viewport_enabled = true

	# Full-screen dimming background
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.7)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	# Centered panel
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(120, 120)
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.position = Vector2(-60, 10)
	_bg.add_child(_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 3)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(main_vbox)

	# Item name
	_item_name_label = Label.new()
	_item_name_label.text = ""
	_item_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_item_name_label)

	# Item sprite (scaled up from 16x16 to 64x64)
	var sprite_container := CenterContainer.new()
	sprite_container.custom_minimum_size = Vector2(64, 64)
	main_vbox.add_child(sprite_container)

	_item_sprite = TextureRect.new()
	_item_sprite.custom_minimum_size = Vector2(64, 64)
	_item_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_item_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_item_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_container.add_child(_item_sprite)

	# Side indicator
	_side_label = Label.new()
	_side_label.text = "Front"
	_side_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_side_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	main_vbox.add_child(_side_label)

	# Buttons row
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 6)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(btn_hbox)

	_flip_btn = Button.new()
	_flip_btn.text = "Flip"
	_flip_btn.custom_minimum_size = Vector2(40, 14)
	_flip_btn.pressed.connect(_on_flip_pressed)
	btn_hbox.add_child(_flip_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(40, 14)
	close_btn.pressed.connect(hide_item)
	btn_hbox.add_child(close_btn)


func _on_flip_pressed() -> void:
	_showing_front = not _showing_front
	if _showing_front:
		_item_sprite.texture = _front_texture
		_side_label.text = "Front"
	else:
		_item_sprite.texture = _back_texture
		_side_label.text = "Back"
