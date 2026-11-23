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
var rotation_angle: float = 0.0
var burst_scale: float = 0.0
var burst_alpha: float = 0.0
var trail_time: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(68, 68)
	size = Vector2(68, 68)
	pivot_offset = Vector2(34, 34)
	update_color()

func setup(beat_val: float, dir: String, for_player: bool) -> void:
	target_beat = beat_val
	direction = dir
	is_play_phase = for_player
	is_hit = false
	is_missed = false
	has_played_listen = false
	scale_factor = 1.0
	rotation_angle = 0.0
	burst_scale = 0.0
	burst_alpha = 0.0
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
			base_color = Color("#9D4EDD") # Purple

func pop_hit(rating: String) -> void:
	is_hit = true
	var end_col = hero_yellow if rating == "Perfect" else Color("#38B000")
	base_color = end_col

	burst_scale = 0.8
	burst_alpha = 1.0

	var tween = create_tween()
	tween.tween_property(self, "scale_factor", 1.55, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "burst_scale", 2.2, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "burst_alpha", 0.0, 0.18)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.18)
	tween.finished.connect(queue_free)

func pop_miss() -> void:
	is_missed = true
	base_color = Color("#6C757D")
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 50, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "rotation_angle", 0.35, 0.28)
	tween.parallel().tween_property(self, "scale_factor", 0.6, 0.28)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.28)
	tween.finished.connect(queue_free)

func _process(delta: float) -> void:
	trail_time += delta
	if not is_hit and not is_missed:
		# Playful rhythm wobble while traveling down the track
		rotation_angle = sin(trail_time * 12.0) * 0.06
		queue_redraw()
	elif is_hit or is_missed:
		queue_redraw()

func _draw() -> void:
	var rect = Rect2(Vector2.ZERO, size)
	var center = rect.size / 2.0
	draw_set_transform(center * (1.0 - scale_factor), rotation_angle, Vector2(scale_factor, scale_factor))

	# 1. Comic Speed Trail lines (above arrow when moving down)
	if not is_hit and not is_missed:
		draw_speed_trail(rect)

	# 2. Paper Drop Shadow (5px down-right)
	var shadow_rect = Rect2(Vector2(5, 5), rect.size)
	draw_rect_rounded(shadow_rect, 14.0, Color(0.1, 0.1, 0.18, 0.38))

	# 3. White Die-Cut Sticker Outline Border (collectible vinyl sticker feel)
	var sticker_rect = Rect2(Vector2(-2, -2), rect.size + Vector2(4, 4))
	draw_rect_rounded(sticker_rect, 15.0, paper_white)
	draw_rect_rounded_outline(sticker_rect, 15.0, ink_color, 3.5)

	# 4. Color Sticker Body
	draw_rect_rounded(rect, 13.0, base_color)

	# Inner top highlight edge
	draw_arc(rect.position + Vector2(13, 13), 11.0, PI, PI * 1.5, 6, base_color.lightened(0.35), 2.0)
	draw_line(Vector2(13, 2), Vector2(rect.size.x - 13, 2), base_color.lightened(0.35), 2.0)

	# 5. Diagonal Glossy Sticker Sheen (specular shine)
	draw_glossy_sheen(rect)

	# 6. Inner Comic Border
	draw_rect_rounded_outline(rect, 13.0, ink_color, 2.5)

	# 7. Center Arrow Glyph with 3D Pop Bevel or Rest Face
	if direction == "rest":
		draw_rest_face(center)
	else:
		draw_arrow_shape(center, direction)

	# 8. Explosive Comic Starburst on Hit
	if burst_alpha > 0.01:
		draw_hit_starburst(center)

func draw_speed_trail(r: Rect2) -> void:
	# Motion dash lines behind the falling prompt
	var trail_alpha = 0.5 + sin(trail_time * 16.0) * 0.2
	var trail_col = base_color.lerp(paper_white, 0.4)
	trail_col.a = trail_alpha

	for ox in [-16, 0, 16]:
		var top_pt = Vector2(r.size.x / 2.0 + ox, -16)
		var bot_pt = Vector2(r.size.x / 2.0 + ox, -4)
		draw_line(top_pt, bot_pt, trail_col, 2.0)

func draw_glossy_sheen(r: Rect2) -> void:
	# Translucent white curved gloss reflection
	var sheen_col = Color(1.0, 1.0, 1.0, 0.22)
	var pts = PackedVector2Array([
		Vector2(6, r.size.y - 12),
		Vector2(r.size.x - 14, 8),
		Vector2(r.size.x - 6, 8),
		Vector2(14, r.size.y - 12)
	])
	draw_colored_polygon(pts, sheen_col)

func draw_arrow_shape(center: Vector2, dir: String) -> void:
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
	var shadow_pts = PackedVector2Array()
	for pt in points:
		var rot = pt.rotated(angle)
		rotated_pts.append(center + rot)
		shadow_pts.append(center + rot + Vector2(2, 2))

	# Arrow Drop Shadow
	draw_colored_polygon(shadow_pts, Color(0.1, 0.1, 0.15, 0.25))

	# Crisp White Arrow with Inner Highlight
	draw_colored_polygon(rotated_pts, paper_white)
	draw_polyline(rotated_pts + PackedVector2Array([rotated_pts[0]]), ink_color, 2.5)

	# Center Pop Core Dot
	draw_circle(center, 3.0, base_color)

func draw_rest_face(center: Vector2) -> void:
	# Sleeping comic character face
	draw_arc(center + Vector2(-8, -3), 4.5, PI + 0.3, TAU - 0.3, 8, ink_color, 2.5)
	draw_arc(center + Vector2(8, -3), 4.5, PI + 0.3, TAU - 0.3, 8, ink_color, 2.5)
	draw_circle(center + Vector2(-12, 2), 3.0, Color(0.98, 0.55, 0.65, 0.5))
	draw_circle(center + Vector2(12, 2), 3.0, Color(0.98, 0.55, 0.65, 0.5))
	draw_arc(center + Vector2(0, 5), 5.0, 0.2, PI - 0.2, 8, ink_color, 2.5)
	var font = ThemeDB.fallback_font
	draw_string(font, center + Vector2(-12, -14), "zZ", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, paper_white)

func draw_hit_starburst(center: Vector2) -> void:
	# 8-point cartoon starburst on hit
	var col = hero_yellow
	col.a = burst_alpha
	var out_col = ink_color
	out_col.a = burst_alpha

	var r_outer = 28.0 * burst_scale
	var r_inner = 14.0 * burst_scale
	var pts = PackedVector2Array()

	for i in range(16):
		var r = r_outer if i % 2 == 0 else r_inner
		var a = (float(i) / 16.0) * TAU
		pts.append(center + Vector2(cos(a) * r, sin(a) * r))

	draw_colored_polygon(pts, col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), out_col, 2.5)

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
