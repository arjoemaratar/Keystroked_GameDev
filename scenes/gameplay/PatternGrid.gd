extends Control

const TILE_SCENE = preload("res://scenes/gameplay/Tile.tscn")

@onready var grid_container: VBoxContainer = $RowsContainer

var tile_instances: Array = [] # 2D array [row][col]
var current_active_row: int = -1
var current_active_col: int = -1

func _ready() -> void:
	pass

func load_grid(rows_data: Array, tile_defs: Dictionary) -> void:
	# Clean existing children
	for child in grid_container.get_children():
		child.queue_free()
	tile_instances.clear()

	for r in range(rows_data.size()):
		var row_info = rows_data[r]
		var tiles_in_row = row_info.get("tiles", ["Q", "Q", "Q", "Q"])
		var phase = row_info.get("phase", "listen")

		var row_hbox = HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 16)
		row_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

		# Label for row (e.g. "R1: LISTEN" or "R1: CLAP")
		var label = Label.new()
		var phase_text = "LISTEN" if phase == "listen" else "CLAP"
		label.text = "R%d: %s" % [r + 1, phase_text]
		label.custom_minimum_size = Vector2(100, 0)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.add_theme_color_override("font_color", Color("#F7D117") if phase == "play" else Color("#FFF8E7"))
		label.add_theme_font_size_override("font_size", 14)
		row_hbox.add_child(label)

		var row_tiles = []
		for c in range(tiles_in_row.size()):
			var tile_id = tiles_in_row[c]
			var tile_node = TILE_SCENE.instantiate()
			row_hbox.add_child(tile_node)
			var def = tile_defs.get(tile_id, {"hits": [0.0], "symbol": tile_id, "family": "straight", "color": "#C85A6E"})
			if tile_node.has_method("setup"):
				tile_node.setup(tile_id, def)
			row_tiles.append(tile_node)

		tile_instances.append(row_tiles)
		grid_container.add_child(row_hbox)

func update_active(row_idx: int, col_idx: int, beat_progress: float, is_play_phase: bool) -> void:
	# If active changed, update old tile
	if row_idx != current_active_row or col_idx != current_active_col:
		if is_valid_coord(current_active_row, current_active_col):
			tile_instances[current_active_row][current_active_col].set_active(false, false)
		current_active_row = row_idx
		current_active_col = col_idx
		if is_valid_coord(row_idx, col_idx):
			tile_instances[row_idx][col_idx].set_active(true, is_play_phase)

	if is_valid_coord(row_idx, col_idx):
		tile_instances[row_idx][col_idx].set_progress(beat_progress)

func get_tile(row_idx: int, col_idx: int) -> Control:
	if is_valid_coord(row_idx, col_idx):
		return tile_instances[row_idx][col_idx]
	return null

func is_valid_coord(r: int, c: int) -> bool:
	return r >= 0 and r < tile_instances.size() and c >= 0 and c < tile_instances[r].size()

func clear_active() -> void:
	if is_valid_coord(current_active_row, current_active_col):
		tile_instances[current_active_row][current_active_col].set_active(false, false)
	current_active_row = -1
	current_active_col = -1
