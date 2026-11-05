extends Control

@export var character_type: String = "clap" # "clap", "beats", "straight_man"
@export var character_name: String = "Clap"

var current_pose: String = "idle" # "idle", "hit", "miss", "left", "down", "up", "right"
var bounce_offset_y: float = 0.0
var limb_offset: Vector2 = Vector2.ZERO
var sweat_alpha: float = 0.0
var rotation_angle: float = 0.0

var ink_color: Color = Color("#1B1B2F")
var paper_white: Color = Color("#FFF8E7")
var hero_yellow: Color = Color("#F7D117")
var straight_red: Color = Color("#C85A6E")
var triplet_blue: Color = Color("#4A7DBF")
var offbeat_green: Color = Color("#4E9A5E")
var rest_orange: Color = Color("#D17B4A")
var cardboard_brown: Color = Color("#C49A45")

var active_tween: Tween

func _ready() -> void:
	custom_minimum_size = Vector2(180, 220)

func bounce(down_amount: float = 8.0) -> void:
	if current_pose != "idle":
		return
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	active_tween = create_tween()
	bounce_offset_y = down_amount
	active_tween.tween_property(self, "bounce_offset_y", 0.0, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	queue_redraw()

func trigger_direction(dir: String) -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	current_pose = dir
	active_tween = create_tween()

	match dir:
		"left":
			rotation_angle = -0.15
			limb_offset = Vector2(-22, 0)
		"right":
			rotation_angle = 0.15
			limb_offset = Vector2(22, 0)
		"up":
			bounce_offset_y = -16.0
			limb_offset = Vector2(0, -20)
		"down":
			bounce_offset_y = 14.0
			limb_offset = Vector2(0, 15)

	queue_redraw()
	active_tween.tween_property(self, "rotation_angle", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(self, "bounce_offset_y", 0.0, 0.22)
	active_tween.parallel().tween_property(self, "limb_offset", Vector2.ZERO, 0.22)
	active_tween.finished.connect(func(): current_pose = "idle"; queue_redraw())

func trigger_clap() -> void:
	trigger_direction("up")

func trigger_miss() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	current_pose = "miss"
	bounce_offset_y = 8.0
	sweat_alpha = 1.0
	rotation_angle = 0.12
	queue_redraw()

	active_tween = create_tween()
	active_tween.tween_property(self, "rotation_angle", 0.0, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(self, "bounce_offset_y", 0.0, 0.25)
	active_tween.parallel().tween_property(self, "sweat_alpha", 0.0, 0.5)
	active_tween.finished.connect(func(): current_pose = "idle"; queue_redraw())

func _process(_delta: float) -> void:
	if active_tween and active_tween.is_valid():
		queue_redraw()

func _draw() -> void:
	var center = size / 2.0 + Vector2(0, bounce_offset_y)
	draw_set_transform(center, rotation_angle, Vector2.ONE)

	match character_type:
		"beats":
			draw_beats_character()
		"straight_man":
			draw_straight_man()
		_:
			draw_clap_character()

	# Name tag badge below
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var font = ThemeDB.fallback_font
	var tag = character_name
	var tag_size = font.get_string_size(tag, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
	var tag_pos = Vector2((size.x - tag_size.x) / 2.0, size.y + 14)

	var tag_bg = Rect2(tag_pos.x - 8, tag_pos.y - 14, tag_size.x + 16, 20)
	draw_rect_rounded(tag_bg, 4.0, ink_color)
	draw_string(font, tag_pos, tag, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, hero_yellow)

func draw_clap_character() -> void:
	# "Clap" - Goofy Doodle Pop Underdog
	var shadow_offset = Vector2(5, 5)
	draw_circle(shadow_offset + Vector2(0, -15), 36.0, Color(0.1, 0.1, 0.15, 0.25))
	draw_circle(shadow_offset + Vector2(0, 38), 42.0, Color(0.1, 0.1, 0.15, 0.25))

	# Red Hoodie Body
	var body_rect = Rect2(-35, 10, 70, 70)
	draw_rect_rounded(body_rect, 20.0, straight_red)
	draw_rect_rounded_outline(body_rect, 20.0, ink_color, 3.5)

	# Round Head
	var head_pos = Vector2(0, -18)
	draw_circle(head_pos, 35.0, paper_white)
	draw_arc(head_pos, 35.0, 0, TAU, 32, ink_color, 3.5)

	# Hero Yellow Cap
	var cap_rect = Rect2(-32, -54, 64, 25)
	draw_rect_rounded(cap_rect, 10.0, hero_yellow)
	draw_rect_rounded_outline(cap_rect, 10.0, ink_color, 3.5)
	var visor_rect = Rect2(8, -38, 32, 10)
	draw_rect_rounded(visor_rect, 4.0, hero_yellow)
	draw_rect_rounded_outline(visor_rect, 4.0, ink_color, 3.0)

	# Face expressions
	var eye_y = -18.0
	if current_pose == "miss":
		# Panic swirl / cross eyes
		draw_line(Vector2(-14, eye_y - 4), Vector2(-6, eye_y + 4), ink_color, 3.0)
		draw_line(Vector2(-6, eye_y + 4), Vector2(-14, eye_y + 8), ink_color, 3.0)
		draw_line(Vector2(14, eye_y - 4), Vector2(6, eye_y + 4), ink_color, 3.0)
		draw_line(Vector2(6, eye_y + 4), Vector2(14, eye_y + 8), ink_color, 3.0)
		draw_circle(Vector2(0, eye_y + 14), 5.0, ink_color)
	elif current_pose in ["left", "right", "up", "down"]:
		# Exaggerated animated wink / cheer
		draw_circle(Vector2(-10, eye_y), 5.0, ink_color)
		draw_arc(Vector2(10, eye_y), 5.0, PI, TAU, 12, ink_color, 3.0)
		draw_arc(Vector2(0, eye_y + 10), 10.0, 0, PI, 16, ink_color, 3.0)
	else:
		# Cute round eyes + smile
		draw_circle(Vector2(-10, eye_y), 4.5, ink_color)
		draw_circle(Vector2(10, eye_y), 4.5, ink_color)
		draw_arc(Vector2(0, eye_y + 10), 7.0, 0.2, PI - 0.2, 12, ink_color, 3.0)

	# Clapping Cartoon Mittens / Noodle Hands
	var lh = Vector2(-36, 30) + limb_offset
	var rh = Vector2(36, 30) + limb_offset
	if current_pose == "left":
		lh = Vector2(-52, 15)
		rh = Vector2(-20, 25)
	elif current_pose == "right":
		lh = Vector2(20, 25)
		rh = Vector2(52, 15)
	elif current_pose == "up":
		lh = Vector2(-25, -28)
		rh = Vector2(25, -28)
	elif current_pose == "down":
		lh = Vector2(-30, 68)
		rh = Vector2(30, 68)

	draw_circle(lh, 15.0, paper_white)
	draw_arc(lh, 15.0, 0, TAU, 18, ink_color, 3.0)
	draw_circle(rh, 15.0, paper_white)
	draw_arc(rh, 15.0, 0, TAU, 18, ink_color, 3.0)

	# Sweat drop on miss
	if sweat_alpha > 0.01:
		draw_circle(Vector2(36, -30), 6.0, Color(0.2, 0.6, 0.9, sweat_alpha))
		draw_arc(Vector2(36, -30), 6.0, 0, TAU, 12, ink_color, 2.0)

func draw_beats_character() -> void:
	# "Beats" - Nervous drummer kid with cardboard drum taped to chest
	var shadow_offset = Vector2(5, 5)
	draw_circle(shadow_offset + Vector2(0, -15), 32.0, Color(0.1, 0.1, 0.15, 0.25))

	# Striped Green T-Shirt Body
	var body_rect = Rect2(-30, 15, 60, 65)
	draw_rect_rounded(body_rect, 14.0, offbeat_green)
	draw_rect_rounded_outline(body_rect, 14.0, ink_color, 3.0)

	# Big Nervous Head
	var head_pos = Vector2(0, -20)
	draw_circle(head_pos, 32.0, paper_white)
	draw_arc(head_pos, 32.0, 0, TAU, 28, ink_color, 3.0)

	# Messy hair doodle tufts
	var hair_pts = PackedVector2Array([
		Vector2(-25, -45), Vector2(-15, -55), Vector2(-5, -46),
		Vector2(5, -56), Vector2(18, -48), Vector2(26, -42), Vector2(0, -40)
	])
	draw_colored_polygon(hair_pts, ink_color)

	# Huge worried/excited eyes
	var eye_y = -20.0
	draw_circle(Vector2(-10, eye_y), 7.0, paper_white)
	draw_arc(Vector2(-10, eye_y), 7.0, 0, TAU, 14, ink_color, 2.5)
	draw_circle(Vector2(-10, eye_y), 3.5, ink_color)

	draw_circle(Vector2(10, eye_y), 7.0, paper_white)
	draw_arc(Vector2(10, eye_y), 7.0, 0, TAU, 14, ink_color, 2.5)
	draw_circle(Vector2(10, eye_y), 3.5, ink_color)

	# Nervous wavy smile
	draw_line(Vector2(-8, eye_y + 12), Vector2(0, eye_y + 10), ink_color, 2.5)
	draw_line(Vector2(0, eye_y + 10), Vector2(8, eye_y + 12), ink_color, 2.5)

	# Cardboard Drum strapped to chest
	var drum_rect = Rect2(-24, 25, 48, 40)
	draw_rect_rounded(drum_rect, 6.0, cardboard_brown)
	draw_rect_rounded_outline(drum_rect, 6.0, ink_color, 3.0)

	# Drum tape "X"
	draw_line(Vector2(-14, 33), Vector2(14, 57), paper_white, 3.5)
	draw_line(Vector2(-14, 57), Vector2(14, 33), paper_white, 3.5)

	# Wooden Drumsticks in hands
	var lh = Vector2(-28, 20) + limb_offset
	var rh = Vector2(28, 20) + limb_offset
	if current_pose != "idle":
		lh.y += 10
		rh.y += 10

	# Drumsticks
	draw_line(lh, lh + Vector2(18, 12), cardboard_brown, 4.0)
	draw_line(rh, rh + Vector2(-18, 12), cardboard_brown, 4.0)

	draw_circle(lh, 8.0, paper_white)
	draw_arc(lh, 8.0, 0, TAU, 12, ink_color, 2.5)
	draw_circle(rh, 8.0, paper_white)
	draw_arc(rh, 8.0, 0, TAU, 12, ink_color, 2.5)

func draw_straight_man() -> void:
	# "The Straight Man" - Week 1 Boss
	var shadow_offset = Vector2(5, 5)
	var s_body = Rect2(shadow_offset + Vector2(-30, -5), Vector2(60, 95))
	draw_rect_rounded(s_body, 8.0, Color(0.1, 0.1, 0.15, 0.25))

	# Suit Body
	var body_rect = Rect2(-30, -5, 60, 95)
	draw_rect_rounded(body_rect, 8.0, Color("#24243E"))
	draw_rect_rounded_outline(body_rect, 8.0, ink_color, 3.5)

	# White Collar
	var col_points = PackedVector2Array([Vector2(-14, -5), Vector2(14, -5), Vector2(0, 18)])
	draw_colored_polygon(col_points, paper_white)
	draw_polyline(col_points, ink_color, 2.5)

	# Dancing Stiff Red Tie
	var tie_swing = 12.0 if current_pose in ["left", "right"] else 0.0
	var tie_points = PackedVector2Array([
		Vector2(-6, 12), Vector2(6, 12),
		Vector2(8 + tie_swing, 52), Vector2(0 + tie_swing, 62), Vector2(-8 + tie_swing, 52)
	])
	draw_colored_polygon(tie_points, straight_red)
	draw_polyline(tie_points, ink_color, 2.5)

	# Stiff Rectangular Head
	var head_rect = Rect2(-24, -62, 48, 52)
	draw_rect_rounded(head_rect, 8.0, paper_white)
	draw_rect_rounded_outline(head_rect, 8.0, ink_color, 3.5)

	# Slick Dark Hair
	var hair_rect = Rect2(-24, -62, 48, 16)
	draw_rect_rounded_top(hair_rect, 8.0, ink_color)

	# Monocle
	var eye_y = -36.0
	draw_circle(Vector2(-10, eye_y), 9.0, Color(0.9, 0.95, 1.0, 0.7))
	draw_arc(Vector2(-10, eye_y), 9.0, 0, TAU, 20, hero_yellow, 2.5)
	draw_circle(Vector2(-10, eye_y), 3.0, ink_color)
	draw_circle(Vector2(10, eye_y), 3.0, ink_color)

	# Deadpan mouth
	draw_line(Vector2(-8, eye_y + 15), Vector2(8, eye_y + 15), ink_color, 2.5)

	# Stiff hands
	var lh = Vector2(-36, 35) + limb_offset
	var rh = Vector2(36, 35) + limb_offset
	draw_circle(lh, 11.0, paper_white)
	draw_arc(lh, 11.0, 0, TAU, 14, ink_color, 2.5)
	draw_circle(rh, 11.0, paper_white)
	draw_arc(rh, 11.0, 0, TAU, 14, ink_color, 2.5)

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
