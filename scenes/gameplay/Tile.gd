extends Control
class_name RhythmTile

@export var tile_id: String = "Q"
var hits: Array = [0.0]
var family: String = "straight"
var symbol: String = "♩"
var tile_name: String = "Quarter"
var base_color: Color = Color("#C85A6E")
var ink_color: Color = Color("#1B1B2F")
var paper_white: Color = Color("#FFF8E7")
var hero_yellow: Color = Color("#F7D117")

var is_active: bool = false
var is_play_phase: bool = false
var current_sub_progress: float = 0.0 # 0.0 to 1.0 progress through this beat
var sub_hit_states: Array[int] = [] # 0: pending, 1: hit, 2: missed

var scale_factor: float = 1.0

func _ready() -> void:
	custom_minimum_size = Vector2(100, 110)

func setup(id: String, def: Dictionary) -> void:
	tile_id = id
	hits = def.get("hits", [0.0])
	family = def.get("family", "straight")
	symbol = def.get("symbol", "♩")
	tile_name = def.get("name", id)
	base_color = Color(def.get("color", "#C85A6E"))
	reset_state()
	queue_redraw()

func reset_state() -> void:
	sub_hit_states.clear()
	for _h in hits:
		sub_hit_states.append(0)
	is_active = false
	current_sub_progress = 0.0
	scale_factor = 1.0
	queue_redraw()

func set_active(active: bool, play_phase: bool) -> void:
	is_active = active
	is_play_phase = play_phase
	if active:
		var tween = create_tween()
		scale_factor = 1.08
		tween.tween_property(self, "scale_factor", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	queue_redraw()

func set_progress(p: float) -> void:
	current_sub_progress = clampf(p, 0.0, 1.0)
	queue_redraw()

func mark_sub_hit(index: int, rating: String) -> void:
	if index >= 0 and index < sub_hit_states.size():
		if rating == "Perfect" or rating == "Good":
			sub_hit_states[index] = 1
		else:
			sub_hit_states[index] = 2

		var tween = create_tween()
		scale_factor = 1.15
		tween.tween_property(self, "scale_factor", 1.0, 0.12)
		queue_redraw()

func pulse_listen(index: int) -> void:
	if index >= 0 and index < sub_hit_states.size():
		sub_hit_states[index] = 1
	var tween = create_tween()
	scale_factor = 1.12
	tween.tween_property(self, "scale_factor", 1.0, 0.12)
	queue_redraw()

func _draw() -> void:
	var rect = Rect2(Vector2.ZERO, size)
	var center = rect.size / 2.0
	
	# Apply scale around center
	draw_set_transform(center * (1.0 - scale_factor), 0.0, Vector2(scale_factor, scale_factor))

	# Paper Cut Pop Drop Shadow (offset down and right 5px, 5px)
	var shadow_rect = Rect2(Vector2(5, 5), rect.size)
	draw_rect_rounded(shadow_rect, 10.0, Color(0.1, 0.1, 0.18, 0.35))

	# Tile Background Body
	var body_color = paper_white
	if is_active:
		body_color = hero_yellow.lerp(paper_white, 0.4)
	draw_rect_rounded(rect, 10.0, body_color)

	# Family Color Top Header Bar
	var header_rect = Rect2(0, 0, rect.size.x, 24)
	draw_rect_rounded_top(header_rect, 10.0, base_color)

	# Thick Paper Cut Outline (3px)
	var outline_color = ink_color
	if is_active:
		outline_color = ink_color
	draw_rect_rounded_outline(rect, 10.0, outline_color, 3.5)

	# Tile Name in header
	var font = ThemeDB.fallback_font
	var font_size = 11
	var name_pos = Vector2(rect.size.x / 2.0, 16)
	draw_string(font, name_pos - Vector2(font.get_string_size(tile_id, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x / 2.0, 0), tile_id, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, paper_white)

	# Notation Symbol in center
	var sym_font_size = 38
	if symbol.length() > 2:
		sym_font_size = 24
	var sym_size = font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, sym_font_size)
	var sym_pos = Vector2((rect.size.x - sym_size.x) / 2.0, 68)
	draw_string(font, sym_pos, symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, sym_font_size, ink_color)

	# Sub-beat progress / hit dots at bottom
	if hits.size() > 0:
		var dot_y = rect.size.y - 14
		var dot_radius = 5.0
		var usable_width = rect.size.x - 24
		for i in range(hits.size()):
			var hit_offset = hits[i]
			var dot_x = 12 + hit_offset * usable_width
			var dot_pos = Vector2(dot_x, dot_y)
			var dot_state = sub_hit_states[i] if i < sub_hit_states.size() else 0

			var dot_color = ink_color.lerp(paper_white, 0.5)
			if dot_state == 1:
				dot_color = Color("#38B000") # Hit green
			elif dot_state == 2:
				dot_color = Color("#D90429") # Miss red
			elif is_active and current_sub_progress >= hit_offset:
				dot_color = hero_yellow

			draw_circle(dot_pos, dot_radius, dot_color)
			draw_arc(dot_pos, dot_radius, 0, TAU, 16, ink_color, 1.5)

	# Active playhead sweep indicator if active
	if is_active:
		var sweep_x = rect.size.x * current_sub_progress
		draw_line(Vector2(sweep_x, 26), Vector2(sweep_x, rect.size.y - 4), hero_yellow, 2.5)

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

