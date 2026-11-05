extends Control

const TILE_SCENE = preload("res://scenes/gameplay/Tile.tscn")

@onready var grid_container: VBoxContainer = $RowsContainer

var rows_data: Array = []
var tile_instances: Array = [] # 2D array [row][col]
var current_active_row: int = -1
var current_active_col: int = -1

var displayed_row_offset: int = 0
const ROWS_PER_PAGE: int = 4

var hero_yellow: Color = Color("#F7D117")
var paper_white: Color = Color("#FFF8E7")
var ink_color: Color = Color("#1B1B2F")

func _ready() -> void:
	custom_minimum_size = Vector2(620, 500)

func load_chart_rows(chart_rows: Array) -> void:
	rows_data = chart_rows
	displayed_row_offset = 0
	render_page()

func render_page() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	tile_instances.clear()

	var start_idx = displayed_row_offset
	var end_idx = min(start_idx + ROWS_PER_PAGE, rows_data.size())

	for r in range(start_idx, end_idx):
		var row_info = rows_data[r]
		var tiles_arr = row_info.get("tiles", [])
		var phase = row_info.get("phase", "listen")

		var row_hbox = HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 14)
		row_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

		# Row Banner Label
		var label = Label.new()
		var phase_text = "LISTEN" if phase == "listen" else "CLAP!"
		label.text = "R%d: %s" % [r + 1, phase_text]
		label.custom_minimum_size = Vector2(95, 0)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", hero_yellow if phase == "play" else paper_white)
		row_hbox.add_child(label)

		var row_tiles = []
		for c in range(tiles_arr.size()):
			var t_data = tiles_arr[c]
			var t_type = "Q"
			var t_dir = "left"
			var sub_hits = []

			if t_data is Dictionary:
				t_type = t_data.get("type", "Q")
				t_dir = t_data.get("dir", "left")
				sub_hits = t_data.get("sub_hits", [])
			elif t_data is String:
				t_type = t_data
				t_dir = "left"

			var tile_node = TILE_SCENE.instantiate()
			row_hbox.add_child(tile_node)
			if tile_node.has_method("setup"):
				tile_node.setup(t_type, t_dir, sub_hits)
			row_tiles.append(tile_node)

		tile_instances.append(row_tiles)
		grid_container.add_child(row_hbox)

func update_active(row_idx: int, col_idx: int, beat_progress: float, is_play_phase: bool) -> void:
	# Check page paging
	var page = int(floor(float(row_idx) / float(ROWS_PER_PAGE)))
	var expected_offset = page * ROWS_PER_PAGE
	if expected_offset != displayed_row_offset and expected_offset < rows_data.size():
		displayed_row_offset = expected_offset
		render_page()

	var local_r = row_idx - displayed_row_offset

	if local_r != current_active_row or col_idx != current_active_col:
		if is_valid_coord(current_active_row, current_active_col):
			tile_instances[current_active_row][current_active_col].set_active(false, false)

		current_active_row = local_r
		current_active_col = col_idx

		if is_valid_coord(current_active_row, current_active_col):
			tile_instances[current_active_row][current_active_col].set_active(true, is_play_phase)

	if is_valid_coord(current_active_row, current_active_col):
		tile_instances[current_active_row][current_active_col].set_progress(beat_progress)

func get_tile(row_idx: int, col_idx: int) -> Control:
	var local_r = row_idx - displayed_row_offset
	if is_valid_coord(local_r, col_idx):
		return tile_instances[local_r][col_idx]
	return null

func is_valid_coord(r: int, c: int) -> bool:
	return r >= 0 and r < tile_instances.size() and c >= 0 and c < tile_instances[r].size()

func clear_active() -> void:
	if is_valid_coord(current_active_row, current_active_col):
		tile_instances[current_active_row][current_active_col].set_active(false, false)
	current_active_row = -1
	current_active_col = -1
