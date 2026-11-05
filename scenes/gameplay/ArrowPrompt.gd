extends Control

var target_beat: float = 0.0
var direction: String = "left" # "left", "down", "up", "right", "rest"
var is_play_phase: bool = true
var is_hit: bool = false
var is_missed: bool = false
var has_played_listen: bool = false

var base_color: Color = Color("#C85A6E")
var ink_color: Color = Color("#1B1B2F")
var paper_white: Color = Color("#FFF8E7")
var hero_yellow: Color = Color("#F7D117")

var scale_factor: float = 1.0

func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	size = Vector2(64, 64)
	pivot_offset = Vector2(32, 32)
	update_color()

func setup(beat_val: float, dir: String, for_player: bool) -> void:
	target_beat = beat_val
	direction = dir
	is_play_phase = for_player
	is_hit = false
	is_missed = false
	has_played_listen = false
	update_color()
	queue_redraw()

func update_color() -> void:
	match direction:
		"left":
			base_color = Color("#C85A6E") # Red
		"down":
			base_color = Color("#4A7DBF") # Blue
		"up":
			base_color = Color("#4E9A5E") # Green
		"right":
			base_color = Color("#D17B4A") # Orange
		"rest":
			base_color = Color("#9D4EDD") # Purple / Rest

func pop_hit(rating: String) -> void:
	is_hit = true
	var tween = create_tween()
	var end_col = hero_yellow if rating == "Perfect" else Color("#55A630")
	base_color = end_col
	tween.tween_property(self, "scale_factor", 1.45, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tween.finished.connect(queue_free)

func pop_miss() -> void:
	is_missed = true
	base_color = Color("#6C757D")
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 40, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.finished.connect(queue_free)

func _draw() -> void:
	var rect = Rect2(Vector2.ZERO, size)
	var center = rect.size / 2.0
	draw_set_transform(center * (1.0 - scale_factor), 0.0, Vector2(scale_factor, scale_factor))

	# Paper Cut Shadow
	var shadow_rect = Rect2(Vector2(4, 4), rect.size)
	draw_rect_rounded(shadow_rect, 12.0, Color(0.1, 0.1, 0.18, 0.35))

	# Sticker body
	draw_rect_rounded(rect, 12.0, base_color)
	draw_rect_rounded_outline(rect, 12.0, ink_color, 3.5)

	# Draw Arrow or Rest Face
	if direction == "rest":
		# Silly "shhh" face
		draw_circle(center + Vector2(-8, -4), 3.0, ink_color)
		draw_circle(center + Vector2(8, -4), 3.0, ink_color)
		draw_arc(center + Vector2(0, 8), 6.0, 0, PI, 10, ink_color, 2.5)
		var font = ThemeDB.fallback_font
		draw_string(font, center + Vector2(-16, -14), "zZ", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, paper_white)
	else:
		draw_arrow_shape(center, direction)

func draw_arrow_shape(center: Vector2, dir: String) -> void:
	var angle = 0.0
	match dir:
		"left": angle = PI # 180 deg
		"down": angle = PI / 2.0 # 90 deg
		"up": angle = -PI / 2.0 # -90 deg
		"right": angle = 0.0 # 0 deg

	# Draw triangle head + stem pointing right by default, rotated by angle
	var points = PackedVector2Array([
		Vector2(16, 0),
		Vector2(-4, -14),
		Vector2(-4, -6),
		Vector2(-16, -6),
		Vector2(-16, 6),
		Vector2(-4, 6),
		Vector2(-4, 14)
	])

	# Rotate points
	var rotated_pts = PackedVector2Array()
	for pt in points:
		rotated_pts.append(center + pt.rotated(angle))

	draw_colored_polygon(rotated_pts, paper_white)
	draw_polyline(rotated_pts + PackedVector2Array([rotated_pts[0]]), ink_color, 2.5)

func draw_rect_rounded(r: Rect2, radius: float, col: Color) -> void:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
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

