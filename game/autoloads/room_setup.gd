extends Node

## Runtime room setup helper.
## Fixes y-sort rendering, camera limits, and loads missing prop/hotspot textures.
## Runs AFTER Popochiu has initialized the room.
##
## Key fixes applied to every room:
## - Background z_index set to -1 so it renders behind y-sorted props/hotspots
## - Hotspots container gets y_sort_enabled so each hotspot sorts at its own y
## - Camera limits locked to viewport size (320x180) for rooms that match viewport

var _setup_done_for_room := ""


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _process(_delta: float) -> void:
	# Continuously enforce correct camera limits (Popochiu may reset them)
	var cam = E.camera
	if cam and cam is Camera2D:
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = 320
		cam.limit_bottom = 180


func _on_node_added(node: Node) -> void:
	if node is PopochiuRoom:
		node.ready.connect(_setup_room.bind(node), CONNECT_ONE_SHOT | CONNECT_DEFERRED)


func _setup_room(room: PopochiuRoom) -> void:
	if room.script_name == _setup_done_for_room:
		return
	_setup_done_for_room = room.script_name

	await get_tree().process_frame

	_fix_y_sort(room)
	_setup_prop_textures(room)


func _fix_y_sort(room: PopochiuRoom) -> void:
	# BUG FIX: Popochiu enables y_sort on rooms at runtime. Background sprite
	# (at room center, e.g. y=90) renders ON TOP of props/hotspots with y < 90,
	# making upper-half items invisible. Fix: z_index=-1 forces Background behind
	# everything. Hotspots also need y_sort so they sort individually instead of
	# grouping at y=0 (which put them all behind Background).
	var bg := room.get_node_or_null("Background")
	if bg:
		bg.z_index = -1

	var hotspots := room.get_node_or_null("Hotspots")
	if hotspots:
		hotspots.y_sort_enabled = true


func _setup_prop_textures(room: PopochiuRoom) -> void:
	var props_node := room.get_node_or_null("Props")
	if not props_node:
		return

	for prop in props_node.get_children():
		var sprite: Sprite2D = prop.get_node_or_null("Sprite2D")
		if not sprite or sprite.texture:
			continue

		var script: Script = prop.get_script()
		if not script:
			continue

		var script_path: String = script.resource_path
		var dir := script_path.get_base_dir()
		var tex_path := dir + "/placeholder.png"

		if ResourceLoader.exists(tex_path):
			sprite.texture = load(tex_path)

	var hotspots_node := room.get_node_or_null("Hotspots")
	if not hotspots_node:
		return

	for hotspot in hotspots_node.get_children():
		var sprite: Sprite2D = hotspot.get_node_or_null("Sprite2D")
		if sprite and sprite.texture:
			continue

		var script: Script = hotspot.get_script()
		if not script:
			continue

		var script_path: String = script.resource_path
		var dir := script_path.get_base_dir()
		var tex_path := dir + "/placeholder.png"

		if ResourceLoader.exists(tex_path):
			if not sprite:
				sprite = Sprite2D.new()
				sprite.name = "Sprite2D"
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				hotspot.add_child(sprite)
			sprite.texture = load(tex_path)
