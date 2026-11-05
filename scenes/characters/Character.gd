extends Control
class_name RhythmCharacter

@export var character_type: String = "clap" # "clap" or "straight_man"
@export var character_name: String = "Clap"

var current_pose: String = "idle" # "idle", "hit", "miss"
var bounce_offset_y: float = 0.0
var arm_pose: float = 0.0 # 0 = down, 1 = clapping/up, -0.5 = flinch
var sweat_alpha: float = 0.0
var rotation_angle: float = 0.0

var ink_color: Color = Color("#1B1B2F")
var paper_white: Color = Color("#FFF8E7")
var hero_yellow: Color = Color("#F7D117")
var straight_red: Color = Color("#C85A6E")
var navy_suit: Color = Color("#24243E")

var active_tween: Tween

func _ready() -> void:
	custom_minimum_size = Vector2(160, 200)

func bounce(down_amount: float = 8.0) -> void:
	if current_pose != "idle":
		return
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	active_tween = create_tween()
	bounce_offset_y = down_amount
	active_tween.tween_property(self, "bounce_offset_y", 0.0, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	active_tween.connect("step_finished", func(_idx): queue_redraw())
	queue_redraw()

func trigger_clap() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	current_pose = "hit"
	arm_pose = 1.0
	bounce_offset_y = -12.0
	rotation_angle = -0.05 if character_type == "clap" else 0.03
	queue_redraw()

	active_tween = create_tween()
	active_tween.tween_property(self, "bounce_offset_y", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(self, "arm_pose", 0.0, 0.25).set_delay(0.08)
	active_tween.parallel().tween_property(self, "rotation_angle", 0.0, 0.2)
	active_tween.finished.connect(func(): current_pose = "idle"; queue_redraw())

func trigger_miss() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	current_pose = "miss"
	arm_pose = -0.5
	bounce_offset_y = 6.0
	sweat_alpha = 1.0
	rotation_angle = 0.08
	queue_redraw()

	active_tween = create_tween()
	active_tween.tween_property(self, "rotation_angle", 0.0, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(self, "bounce_offset_y", 0.0, 0.25)
	active_tween.parallel().tween_property(self, "sweat_alpha", 0.0, 0.45)
	active_tween.finished.connect(func(): current_pose = "idle"; arm_pose = 0.0; queue_redraw())

func _process(_delta: float) -> void:
	if active_tween and active_tween.is_valid():
		queue_redraw()

func _draw() -> void:
	var center = size / 2.0 + Vector2(0, bounce_offset_y)
	draw_set_transform(center, rotation_angle, Vector2.ONE)

	if character_type == "clap":
		draw_clap_character()
	else:
		draw_straight_man()

	# Draw Name Tag below
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var font = ThemeDB.fallback_font
	var tag = character_name
	var tag_size = font.get_string_size(tag, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
	var tag_pos = Vector2((size.x - tag_size.x) / 2.0, size.y + 16)
	
	# Tag background
	var tag_bg = Rect2(tag_pos.x - 8, tag_pos.y - 14, tag_size.x + 16, 20)
	draw_rect_rounded(tag_bg, 4.0, ink_color)
	draw_string(font, tag_pos, tag, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, hero_yellow)

func draw_clap_character() -> void:
	# Paper Cut Pop Protagonist "Clap"
	# 1. Shadow
	var shadow_offset = Vector2(6, 6)
	draw_circle(shadow_offset + Vector2(0, -20), 38.0, Color(0.1, 0.1, 0.15, 0.25))
	draw_circle(shadow_offset + Vector2(0, 35), 44.0, Color(0.1, 0.1, 0.15, 0.25))

	# 2. Body / Hoodie (Red Paper Cut)
	var body_rect = Rect2(-38, 5, 76, 75)
	draw_rect_rounded(body_rect, 22.0, straight_red)
	draw_rect_rounded_outline(body_rect, 22.0, ink_color, 3.5)

	# 3. Head (Cream Paper Cut)
	var head_pos = Vector2(0, -22)
	draw_circle(head_pos, 36.0, paper_white)
	draw_arc(head_pos, 36.0, 0, TAU, 32, ink_color, 3.5)

	# 4. Hero Yellow Cap
	var cap_rect = Rect2(-34, -58, 68, 26)
	draw_rect_rounded(cap_rect, 10.0, hero_yellow)
	draw_rect_rounded_outline(cap_rect, 10.0, ink_color, 3.5)
	# Cap Visor
	var visor_rect = Rect2(10, -42, 34, 10)
	draw_rect_rounded(visor_rect, 4.0, hero_yellow)
	draw_rect_rounded_outline(visor_rect, 4.0, ink_color, 3.0)

	# 5. Face (Dot eyes + mouth)
	var eye_y = -22.0
	if current_pose == "hit":
		# Happy crescent eyes ^ ^
		draw_arc(Vector2(-12, eye_y), 6.0, PI, TAU, 12, ink_color, 3.0)
		draw_arc(Vector2(12, eye_y), 6.0, PI, TAU, 12, ink_color, 3.0)
		# Big open smile
		draw_arc(Vector2(0, eye_y + 12), 10.0, 0, PI, 16, ink_color, 3.0)
	elif current_pose == "miss":
		# Uneasy line eyes > <
		draw_line(Vector2(-16, eye_y - 4), Vector2(-8, eye_y + 4), ink_color, 3.0)
		draw_line(Vector2(-8, eye_y + 4), Vector2(-16, eye_y + 8), ink_color, 3.0)
		draw_line(Vector2(16, eye_y - 4), Vector2(8, eye_y + 4), ink_color, 3.0)
		draw_line(Vector2(8, eye_y + 4), Vector2(16, eye_y + 8), ink_color, 3.0)
		# Wavy mouth
		draw_line(Vector2(-10, eye_y + 14), Vector2(10, eye_y + 14), ink_color, 3.0)
	else:
		# Cute round dot eyes
		draw_circle(Vector2(-12, eye_y), 4.5, ink_color)
		draw_circle(Vector2(12, eye_y), 4.5, ink_color)
		# Simple smile
		draw_arc(Vector2(0, eye_y + 10), 7.0, 0.2, PI - 0.2, 12, ink_color, 3.0)

	# 6. Clapping Hands / Mittens
	var hand_y = 25.0 - (arm_pose * 30.0)
	var left_hand = Vector2(-36 - (arm_pose * 10), hand_y)
	var right_hand = Vector2(36 + (arm_pose * 10), hand_y)
	if current_pose == "hit":
		left_hand = Vector2(-10, hand_y)
		right_hand = Vector2(10, hand_y)

	draw_circle(left_hand, 16.0, paper_white)
	draw_arc(left_hand, 16.0, 0, TAU, 20, ink_color, 3.0)
	draw_circle(right_hand, 16.0, paper_white)
	draw_arc(right_hand, 16.0, 0, TAU, 20, ink_color, 3.0)

	# Sweat drop on miss
	if sweat_alpha > 0.01:
		var s_color = Color(0.2, 0.6, 0.9, sweat_alpha)
		draw_circle(Vector2(38, -32), 6.0, s_color)
		draw_arc(Vector2(38, -32), 6.0, 0, TAU, 12, ink_color, 2.0)

func draw_straight_man() -> void:
	# Paper Cut Pop Boss "The Straight Man"
	# Tall, stiff, rectangular, navy suit, red tie, monocle
	var shadow_offset = Vector2(6, 6)
	var s_body = Rect2(shadow_offset + Vector2(-32, -10), Vector2(64, 95))
	draw_rect_rounded(s_body, 8.0, Color(0.1, 0.1, 0.15, 0.25))

	# Suit Body
	var body_rect = Rect2(-32, -10, 64, 95)
	draw_rect_rounded(body_rect, 8.0, navy_suit)
	draw_rect_rounded_outline(body_rect, 8.0, ink_color, 3.5)

	# White Collar Triangle
	var col_points = PackedVector2Array([Vector2(-14, -10), Vector2(14, -10), Vector2(0, 15)])
	draw_colored_polygon(col_points, paper_white)
	draw_polyline(col_points, ink_color, 2.5)

	# Red Stiff Tie
	var tie_points = PackedVector2Array([Vector2(-6, 8), Vector2(6, 8), Vector2(8, 48), Vector2(0, 58), Vector2(-8, 48)])
	draw_colored_polygon(tie_points, straight_red)
	draw_polyline(tie_points, ink_color, 2.5)

	# Stiff Head (Tall rounded rectangle)
	var head_rect = Rect2(-26, -65, 52, 52)
	draw_rect_rounded(head_rect, 8.0, paper_white)
	draw_rect_rounded_outline(head_rect, 8.0, ink_color, 3.5)

	# Slick Dark Hair
	var hair_rect = Rect2(-26, -65, 52, 16)
	draw_rect_rounded_top(hair_rect, 8.0, ink_color)

	# Monocle over left eye
	var eye_y = -38.0
	draw_circle(Vector2(-10, eye_y), 9.0, Color(0.9, 0.95, 1.0, 0.7))
	draw_arc(Vector2(-10, eye_y), 9.0, 0, TAU, 20, hero_yellow, 2.5)
	# Monocle string down
	draw_line(Vector2(-10, eye_y + 9), Vector2(-14, -10), hero_yellow, 1.8)

	# Dot eyes
	draw_circle(Vector2(-10, eye_y), 3.0, ink_color)
	draw_circle(Vector2(10, eye_y), 3.0, ink_color)

	# Smug / stiff flat mouth
	if current_pose == "hit":
		# Confident smirk
		draw_line(Vector2(-6, eye_y + 16), Vector2(8, eye_y + 13), ink_color, 2.5)
	elif current_pose == "miss":
		# Shocked O mouth
		draw_circle(Vector2(0, eye_y + 16), 4.5, ink_color)
	else:
		# Deadpan flat line
		draw_line(Vector2(-8, eye_y + 15), Vector2(8, eye_y + 15), ink_color, 2.5)

	# Stiff gloved hands
	var hand_y = 35.0 - (arm_pose * 25.0)
	var lh = Vector2(-38, hand_y)
	var rh = Vector2(38, hand_y)
	if current_pose == "hit":
		lh = Vector2(-12, hand_y - 10)
		rh = Vector2(12, hand_y - 10)
	draw_circle(lh, 12.0, paper_white)
	draw_arc(lh, 12.0, 0, TAU, 16, ink_color, 2.5)
	draw_circle(rh, 12.0, paper_white)
	draw_arc(rh, 12.0, 0, TAU, 16, ink_color, 2.5)

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
