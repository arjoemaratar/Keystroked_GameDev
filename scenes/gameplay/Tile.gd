extends Control

var tile_type: String = "Q"
var primary_dir: String = "left" # "left", "down", "up", "right", "rest"
var sub_hits: Array = [] # Array of Dictionary { "offset": float, "dir": String }
var sub_states: Array[int] = [] # 0: pending, 1: hit, 2: missed

var is_active: bool = false
var is_play_phase: bool = false
var playhead_progress: float = 0.0 # 0.0 to 1.0 within this beat
var scale_factor: float = 1.0

var ink_color: Color = Color("#1B1B2F")
var paper_white: Color = Color("#FFF8E7")
var hero_yellow: Color = Color("#F7D117")

const DIR_COLORS = {
	"left": Color("#C85A6E"),
	"down": Color("#4A7DBF"),
	"up": Color("#4E9A5E"),
	"right": Color("#D17B4A"),
	"rest": Color("#9D4EDD")
}

const TYPE_SYMBOLS = {
	"Q": "♩",
	"E2": "♫",
	"S4": "♬",
	"TR": "3",
	"ER": "𝄾♪",
	"R": "𝄽"
}

func _ready() -> void:
	custom_minimum_size = Vector2(104, 114)
	size = Vector2(104, 114)
	pivot_offset = size / 2.0

func setup(t_type: String, p_dir: String, hits_data: Array = []) -> void:
	tile_type = t_type
	primary_dir = p_dir
	sub_hits.clear()
	sub_states.clear()

	if hits_data.size() > 0:
		sub_hits = hits_data.duplicate()
	else:
		# Default fallback based on type
		match tile_type:
			"E2":
				sub_hits = [
					{ "offset": 0.0, "dir": primary_dir },
					{ "offset": 0.5, "dir": primary_dir }
				]
			"TR":
				sub_hits = [
					{ "offset": 0.0, "dir": primary_dir },
					{ "offset": 0.333, "dir": primary_dir },
					{ "offset": 0.667, "dir": primary_dir }
				]
			"S4":
				sub_hits = [
					{ "offset": 0.0, "dir": primary_dir },
					{ "offset": 0.25, "dir": primary_dir },
					{ "offset": 0.5, "dir": primary_dir },
					{ "offset": 0.75, "dir": primary_dir }
				]
			"ER":
				sub_hits = [{ "offset": 0.5, "dir": primary_dir }]
			"R":
				sub_hits = []
				primary_dir = "rest"
			_:
				sub_hits = [{ "offset": 0.0, "dir": primary_dir }]

	for _h in sub_hits:
		sub_states.append(0)

	reset_state()
	queue_redraw()

func reset_state() -> void:
	for i in range(sub_states.size()):
		sub_states[i] = 0
	is_active = false
	playhead_progress = 0.0
	scale_factor = 1.0
	queue_redraw()

func set_active(active: bool, play_phase: bool) -> void:
	is_active = active
	is_play_phase = play_phase
	if active:
		var tween = create_tween()
		scale_factor = 1.1
		tween.tween_property(self, "scale_factor", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	queue_redraw()

func set_progress(p: float) -> void:
	playhead_progress = clampf(p, 0.0, 1.0)
	queue_redraw()

func mark_sub_hit(index: int, rating: String) -> void:
	if index >= 0 and index < sub_states.size():
		sub_states[index] = 1 if (rating == "Perfect" or rating == "Good") else 2
		var tween = create_tween()
		scale_factor = 1.18
		tween.tween_property(self, "scale_factor", 1.0, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		queue_redraw()

func pulse_listen(index: int) -> void:
	if index >= 0 and index < sub_states.size():
		sub_states[index] = 1
	var tween = create_tween()
	scale_factor = 1.14
	tween.tween_property(self, "scale_factor", 1.0, 0.12)
	queue_redraw()

func _draw() -> void:
	var rect = Rect2(Vector2.ZERO, size)
	var center = rect.size / 2.0
	draw_set_transform(center * (1.0 - scale_factor), 0.0, Vector2(scale_factor, scale_factor))

	# Paper Cut Drop Shadow (down & right 5px)
	var shadow_rect = Rect2(Vector2(5, 5), rect.size)
	draw_rect_rounded(shadow_rect, 12.0, Color(0.1, 0.1, 0.18, 0.35))

	# Base card color
	var dir_col = DIR_COLORS.get(primary_dir, Color("#C85A6E"))
	var bg_col = paper_white
	if is_active:
		bg_col = hero_yellow.lerp(paper_white, 0.4)

	draw_rect_rounded(rect, 12.0, bg_col)

	# Direction Header Strip
	var header_rect = Rect2(0, 0, rect.size.x, 24)
	draw_rect_rounded_top(header_rect, 12.0, dir_col)

	# Thick Paper Cut Outline (3.5px)
	var outline_col = ink_color
	draw_rect_rounded_outline(rect, 12.0, outline_col, 3.5)

	# Header text: Tile Type & Notation Symbol (e.g. "Q ♩" or "E2 ♫")
	var font = ThemeDB.fallback_font
	var not_sym = TYPE_SYMBOLS.get(tile_type, "♩")
	var header_str = "%s  %s" % [tile_type, not_sym]
	var h_size = font.get_string_size(header_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
	draw_string(font, Vector2((rect.size.x - h_size.x) / 2.0, 16), header_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, paper_white)

	# Center Arrow or Rest Face
	var center_arrow_pos = Vector2(rect.size.x / 2.0, 62.0)
	if primary_dir == "rest":
		draw_rest_face(center_arrow_pos)
	else:
		draw_arrow_glyph(center_arrow_pos, primary_dir, dir_col)

	# Bottom Sub-hit Markers
	if sub_hits.size() > 1:
		var dot_y = rect.size.y - 12.0
		var usable_w = rect.size.x - 24.0
		for i in range(sub_hits.size()):
			var h_info = sub_hits[i]
			var offset_val = float(h_info.get("offset", 0.0))
			var sub_dir = str(h_info.get("dir", primary_dir))
			var dot_x = 12.0 + (offset_val * usable_w)
			var dot_pos = Vector2(dot_x, dot_y)
			var state = sub_states[i] if i < sub_states.size() else 0

			var dot_col = DIR_COLORS.get(sub_dir, ink_color)
			if state == 1:
				dot_col = Color("#38B000")
			elif state == 2:
				dot_col = Color("#D90429")

			draw_circle(dot_pos, 4.5, dot_col)
			draw_arc(dot_pos, 4.5, 0, TAU, 16, ink_color, 1.5)

	# Sweeping Playhead Line
	if is_active:
		var sweep_x = rect.size.x * playhead_progress
		draw_line(Vector2(sweep_x, 25), Vector2(sweep_x, rect.size.y - 3), hero_yellow, 3.0)

func draw_arrow_glyph(center: Vector2, dir: String, fill_col: Color) -> void:
	var angle = 0.0
	match dir:
		"left": angle = PI
		"down": angle = PI / 2.0
		"up": angle = -PI / 2.0
		"right": angle = 0.0

	var points = PackedVector2Array([
		Vector2(18, 0),
		Vector2(-4, -15),
		Vector2(-4, -7),
		Vector2(-18, -7),
		Vector2(-18, 7),
		Vector2(-4, 7),
		Vector2(-4, 15)
	])

	var rotated_pts = PackedVector2Array()
	for pt in points:
		rotated_pts.append(center + pt.rotated(angle))

	# Filled arrow with dark outline
	draw_colored_polygon(rotated_pts, fill_col)
	draw_polyline(rotated_pts + PackedVector2Array([rotated_pts[0]]), ink_color, 2.5)

func draw_rest_face(center: Vector2) -> void:
	# Cute sleeping comic face
	draw_circle(center + Vector2(-8, -4), 3.0, ink_color)
	draw_circle(center + Vector2(8, -4), 3.0, ink_color)
	draw_arc(center + Vector2(0, 6), 6.0, 0, PI, 10, ink_color, 2.5)
	var font = ThemeDB.fallback_font
	draw_string(font, center + Vector2(-12, -14), "zZ", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, DIR_COLORS["rest"])

func draw_rect_rounded(r: Rect2, radius: float, col: Color) -> void:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	style.bg_color = col
	style.draw(get_canvas_item(), r)

func draw_rect_rounded_top(r: Rect2, radius: float, col: Color) -> void:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.bg_color = col
	style.draw(get_canvas_item(), r)

func draw_rect_rounded_outline(r: Rect2, radius: float, col: Color, width: float) -> void:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	style.draw_center = false
	style.border_width_left = int(width)
	style.border_width_top = int(width)
	style.border_width_right = int(width)
	style.border_width_bottom = int(width)
	style.border_color = col
	style.draw(get_canvas_item(), r)
