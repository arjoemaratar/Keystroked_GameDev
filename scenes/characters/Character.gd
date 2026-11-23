extends Control

@export var character_type: String = "clap" # "clap", "beats", "straight_man"
@export var character_name: String = "Clap"

var current_pose: String = "idle" # "idle", "hit", "miss", "left", "down", "up", "right"
var bounce_offset_y: float = 0.0
var limb_offset: Vector2 = Vector2.ZERO
var sweat_alpha: float = 0.0
var rotation_angle: float = 0.0
var squash_stretch: Vector2 = Vector2.ONE

# Dynamic secondary motion variables
var idle_time: float = 0.0
var blink_timer: float = 0.0
var is_blinking: bool = false
var tie_swing: float = 0.0
var hoodie_swing: float = 0.0
var hair_bob: float = 0.0
var foot_tap_l: float = 0.0
var foot_tap_r: float = 0.0
var hit_star_scale: float = 0.0
var hit_star_alpha: float = 0.0
var hit_star_rot: float = 0.0
var action_line_alpha: float = 0.0

# Palette
var ink_color: Color = Color("#1B1B2F")
var paper_white: Color = Color("#FFF8E7")
var hero_yellow: Color = Color("#F7D117")
var straight_red: Color = Color("#C85A6E")
var triplet_blue: Color = Color("#4A7DBF")
var offbeat_green: Color = Color("#4E9A5E")
var rest_orange: Color = Color("#D17B4A")
var cardboard_brown: Color = Color("#C49A45")
var cardboard_dark: Color = Color("#9B732B")
var cardboard_light: Color = Color("#D8B263")
var blush_pink: Color = Color("#FF8FA3")
var gold_color: Color = Color("#FFD000")
var suit_navy: Color = Color("#202038")
var suit_stripe: Color = Color("#323254")

var active_tween: Tween

func _ready() -> void:
	custom_minimum_size = Vector2(180, 220)
	pivot_offset = Vector2(90, 150)
	blink_timer = randf_range(2.0, 4.0)

func bounce(down_amount: float = 8.0) -> void:
	if current_pose != "idle":
		return
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	active_tween = create_tween()
	bounce_offset_y = down_amount
	# Bouncy squash & stretch
	squash_stretch = Vector2(1.12, 0.88)
	hoodie_swing = 0.12 if randf() > 0.5 else -0.12
	tie_swing = 10.0
	hair_bob = 5.0
	foot_tap_l = 4.0

	active_tween.tween_property(self, "bounce_offset_y", 0.0, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(self, "squash_stretch", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(self, "foot_tap_l", 0.0, 0.2)
	queue_redraw()

func trigger_direction(dir: String) -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	current_pose = dir
	active_tween = create_tween()

	# Dynamic pop effects
	hit_star_scale = 1.3
	hit_star_alpha = 1.0
	hit_star_rot = randf_range(-PI, PI)
	action_line_alpha = 1.0

	match dir:
		"left":
			rotation_angle = -0.18
			limb_offset = Vector2(-28, 4)
			squash_stretch = Vector2(1.12, 0.94)
			hoodie_swing = -0.25
			tie_swing = -18.0
			hair_bob = -4.0
			foot_tap_l = -8.0
		"right":
			rotation_angle = 0.18
			limb_offset = Vector2(28, 4)
			squash_stretch = Vector2(1.12, 0.94)
			hoodie_swing = 0.25
			tie_swing = 18.0
			hair_bob = 4.0
			foot_tap_r = -8.0
		"up":
			bounce_offset_y = -22.0
			limb_offset = Vector2(0, -26)
			squash_stretch = Vector2(0.86, 1.20)
			hoodie_swing = 0.0
			tie_swing = 0.0
			hair_bob = -8.0
			foot_tap_l = -5.0
			foot_tap_r = -5.0
		"down":
			bounce_offset_y = 18.0
			limb_offset = Vector2(0, 20)
			squash_stretch = Vector2(1.24, 0.78)
			hoodie_swing = 0.15
			tie_swing = 8.0
			hair_bob = 8.0
			foot_tap_l = 4.0
			foot_tap_r = 4.0

	queue_redraw()
	active_tween.tween_property(self, "rotation_angle", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(self, "bounce_offset_y", 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(self, "squash_stretch", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(self, "limb_offset", Vector2.ZERO, 0.25)
	active_tween.parallel().tween_property(self, "hit_star_scale", 1.8, 0.22)
	active_tween.parallel().tween_property(self, "hit_star_alpha", 0.0, 0.22)
	active_tween.parallel().tween_property(self, "action_line_alpha", 0.0, 0.22)
	active_tween.parallel().tween_property(self, "hoodie_swing", 0.0, 0.3)
	active_tween.parallel().tween_property(self, "tie_swing", 0.0, 0.35)
	active_tween.parallel().tween_property(self, "hair_bob", 0.0, 0.25)
	active_tween.parallel().tween_property(self, "foot_tap_l", 0.0, 0.2)
	active_tween.parallel().tween_property(self, "foot_tap_r", 0.0, 0.2)
	active_tween.finished.connect(func(): current_pose = "idle"; queue_redraw())

func trigger_clap() -> void:
	trigger_direction("up")

func trigger_miss() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	current_pose = "miss"
	bounce_offset_y = 12.0
	sweat_alpha = 1.0
	rotation_angle = 0.16
	squash_stretch = Vector2(1.2, 0.85)
	queue_redraw()

	active_tween = create_tween()
	active_tween.tween_property(self, "rotation_angle", 0.0, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(self, "bounce_offset_y", 0.0, 0.3)
	active_tween.parallel().tween_property(self, "squash_stretch", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(self, "sweat_alpha", 0.0, 0.6)
	active_tween.finished.connect(func(): current_pose = "idle"; queue_redraw())

func _process(delta: float) -> void:
	idle_time += delta

	# Natural blinking cycle
	blink_timer -= delta
	if blink_timer <= 0.0:
		if not is_blinking:
			is_blinking = true
			blink_timer = 0.14 # Blink duration
			queue_redraw()
		else:
			is_blinking = false
			blink_timer = randf_range(2.8, 5.0) # Next blink interval
			queue_redraw()

	# Idle breathing and subtle rhythm sway
	if current_pose == "idle":
		queue_redraw()
	elif active_tween and active_tween.is_valid():
		queue_redraw()

func _draw() -> void:
	# Subtle rhythmic breathing
	var breath_scale = Vector2.ONE
	var breath_y = 0.0
	if current_pose == "idle":
		var breath = sin(idle_time * 3.2)
		breath_scale = Vector2(1.0 + breath * 0.015, 1.0 - breath * 0.015)
		breath_y = breath * 1.5

	var effective_scale = squash_stretch * breath_scale
	var center = (size / 2.0) + Vector2(0, bounce_offset_y + breath_y)

	# Transform for character rendering
	draw_set_transform(center, rotation_angle, effective_scale)

	match character_type:
		"beats":
			draw_beats_character()
		"straight_man":
			draw_straight_man()
		_:
			draw_clap_character()

	# Comic hit stars / sparkles pop
	if hit_star_alpha > 0.01:
		draw_comic_hit_stars()

	# Reset transform for HUD name tag badge
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_character_name_tag()

func draw_comic_hit_stars() -> void:
	var star_col = hero_yellow
	star_col.a = hit_star_alpha
	var rim_col = ink_color
	rim_col.a = hit_star_alpha

	var angles = [0.0, 0.8, 2.1, 3.7, 5.0]
	var dists = [42.0, 48.0, 39.0, 45.0, 40.0]
	for i in range(angles.size()):
		var pt = Vector2(cos(angles[i] + hit_star_rot), sin(angles[i] + hit_star_rot)) * dists[i] * (hit_star_scale * 0.7)
		draw_four_point_star(pt, 8.0 * hit_star_scale, star_col, rim_col)

func draw_four_point_star(pos: Vector2, radius: float, fill_col: Color, outline_col: Color) -> void:
	var r_in = radius * 0.3
	var pts = PackedVector2Array([
		pos + Vector2(0, -radius),
		pos + Vector2(r_in, -r_in),
		pos + Vector2(radius, 0),
		pos + Vector2(r_in, r_in),
		pos + Vector2(0, radius),
		pos + Vector2(-r_in, r_in),
		pos + Vector2(-radius, 0),
		pos + Vector2(-r_in, -r_in)
	])
	draw_colored_polygon(pts, fill_col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), outline_col, 2.0)

func draw_character_name_tag() -> void:
	var font = ThemeDB.fallback_font
	var tag = character_name
	var tag_size = font.get_string_size(tag, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
	var tag_pos = Vector2((size.x - tag_size.x) / 2.0, size.y + 15)

	# Paper tag shadow
	var tag_bg = Rect2(tag_pos.x - 10, tag_pos.y - 14, tag_size.x + 20, 22)
	draw_rect_rounded(Rect2(tag_bg.position + Vector2(2, 3), tag_bg.size), 6.0, Color(0.1, 0.1, 0.18, 0.35))
	draw_rect_rounded(tag_bg, 6.0, ink_color)
	draw_rect_rounded_outline(tag_bg, 6.0, paper_white.lerp(hero_yellow, 0.5), 1.5)
	draw_string(font, tag_pos + Vector2(0, 1), tag, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, hero_yellow)

# ==============================================================================
# 1. CLAP (The Playful Underdog Hero)
# ==============================================================================
func draw_clap_character() -> void:
	var shadow_offset = Vector2(4, 5)

	# Floor shadow
	draw_ellipse_shape(Vector2(0, 85) + shadow_offset, Vector2(46, 14), Color(0.1, 0.1, 0.15, 0.28))

	# 1. Comic High-top Sneakers
	draw_clap_sneakers()

	# 2. Denim Shorts/Pants Cuffs
	var pants_rect = Rect2(-28, 52, 56, 18)
	draw_rect_rounded(pants_rect, 6.0, triplet_blue)
	draw_rect_rounded_outline(pants_rect, 6.0, ink_color, 3.0)
	# Pant seam
	draw_line(Vector2(0, 56), Vector2(0, 70), ink_color, 2.0)

	# 3. Red Hoodie Body
	var body_rect = Rect2(-36, 6, 72, 60)
	# Body shadow
	draw_rect_rounded(Rect2(body_rect.position + shadow_offset, body_rect.size), 22.0, Color(0.1, 0.1, 0.15, 0.25))
	# Body base
	draw_rect_rounded(body_rect, 22.0, straight_red)

	# Subtle fabric texture (stitched seam hem at bottom)
	draw_dashes(Vector2(-30, 58), Vector2(30, 58), paper_white.lerp(straight_red, 0.5), 2.0, 4.0, 3.0)

	# Kangaroo Pocket
	var pocket_rect = Rect2(-24, 28, 48, 28)
	draw_rect_rounded(pocket_rect, 10.0, straight_red.darkened(0.12))
	draw_rect_rounded_outline(pocket_rect, 10.0, ink_color, 2.5)
	# Pocket side openings
	draw_arc(Vector2(-20, 42), 6.0, PI * 0.5, PI * 1.5, 6, ink_color, 2.0)
	draw_arc(Vector2(20, 42), 6.0, -PI * 0.5, PI * 0.5, 6, ink_color, 2.0)

	# Hoodie Outer Outline
	draw_rect_rounded_outline(body_rect, 22.0, ink_color, 3.5)

	# Hoodie Dangling Drawstrings (with dynamic physics sway)
	var sway_x = hoodie_swing * 25.0
	var str_l_start = Vector2(-10, 14)
	var str_r_start = Vector2(10, 14)
	var str_l_end = Vector2(-12 + sway_x, 38)
	var str_r_end = Vector2(8 + sway_x, 40)
	draw_line(str_l_start, str_l_end, paper_white, 3.0)
	draw_line(str_r_start, str_r_end, paper_white, 3.0)
	# Knots at string tips
	draw_circle(str_l_end, 3.5, paper_white)
	draw_arc(str_l_end, 3.5, 0, TAU, 8, ink_color, 2.0)
	draw_circle(str_r_end, 3.5, paper_white)
	draw_arc(str_r_end, 3.5, 0, TAU, 8, ink_color, 2.0)

	# 4. Round Head
	var head_pos = Vector2(0, -22)
	draw_circle(head_pos + shadow_offset, 36.0, Color(0.1, 0.1, 0.15, 0.25))
	draw_circle(head_pos, 36.0, paper_white)
	draw_arc(head_pos, 36.0, 0, TAU, 32, ink_color, 3.5)

	# Rosy Blush Cheeks (playful doodle detail)
	draw_rosy_blush(Vector2(-22, -14))
	draw_rosy_blush(Vector2(22, -14))

	# 5. Hero Yellow Cap
	draw_clap_cap(head_pos)

	# 6. Expressive Face & Eyes
	draw_clap_face()

	# 7. Clapping Cartoon Mittens / Hands
	draw_clap_hands()

	# 8. Sweat drop / panic doodle on miss
	if sweat_alpha > 0.01:
		draw_sweat_and_dizzy_cloud()

func draw_clap_sneakers() -> void:
	var l_pos = Vector2(-18, 76 + foot_tap_l)
	var r_pos = Vector2(18, 76 + foot_tap_r)

	for pos in [l_pos, r_pos]:
		var is_left = pos.x < 0
		var flip = -1.0 if is_left else 1.0

		# Rubber Sole
		var sole_rect = Rect2(pos.x - 14, pos.y + 6, 28, 7)
		draw_rect_rounded(sole_rect, 3.0, paper_white)
		draw_rect_rounded_outline(sole_rect, 3.0, ink_color, 2.5)

		# Red Canvas Upper
		var shoe_rect = Rect2(pos.x - 13, pos.y - 4, 26, 12)
		draw_rect_rounded(shoe_rect, 5.0, straight_red)
		draw_rect_rounded_outline(shoe_rect, 5.0, ink_color, 2.5)

		# White Rubber Toe Cap
		var toe_pos = Vector2(pos.x + (9.0 * flip), pos.y + 4)
		draw_circle(toe_pos, 5.5, paper_white)
		draw_arc(toe_pos, 5.5, 0, TAU, 10, ink_color, 2.0)

		# Criss-cross shoe laces
		draw_line(Vector2(pos.x - 4, pos.y), Vector2(pos.x + 4, pos.y), paper_white, 2.0)
		draw_line(Vector2(pos.x - 3, pos.y + 3), Vector2(pos.x + 3, pos.y + 3), paper_white, 2.0)

func draw_clap_cap(head_pos: Vector2) -> void:
	var cap_tilt = rotation_angle * 0.5
	var cap_rect = Rect2(-34, -60, 68, 28)

	# Cap Crown
	draw_rect_rounded(cap_rect, 12.0, hero_yellow)

	# Cap Panel Seam lines (radiating from center top button)
	draw_line(Vector2(0, -60), Vector2(-18, -36), ink_color.lerp(hero_yellow, 0.4), 2.0)
	draw_line(Vector2(0, -60), Vector2(18, -36), ink_color.lerp(hero_yellow, 0.4), 2.0)
	draw_line(Vector2(0, -60), Vector2(0, -34), ink_color.lerp(hero_yellow, 0.4), 2.0)

	# Cap Outer Outline
	draw_rect_rounded_outline(cap_rect, 12.0, ink_color, 3.5)

	# Cap Visor (brim) sticking out
	var visor_rect = Rect2(10, -42, 34, 11)
	draw_rect_rounded(visor_rect, 5.0, hero_yellow)
	# Stitched line on brim
	draw_dashes(Vector2(14, -36), Vector2(38, -36), paper_white, 1.5, 3.0, 2.0)
	draw_rect_rounded_outline(visor_rect, 5.0, ink_color, 3.0)

	# Top Rivet Button
	draw_circle(Vector2(0, -60), 4.5, paper_white)
	draw_arc(Vector2(0, -60), 4.5, 0, TAU, 10, ink_color, 2.5)

	# Cool collectible embroidered sticker badge on front of cap
	var badge_pos = Vector2(-12, -46)
	draw_circle(badge_pos, 7.5, paper_white)
	draw_arc(badge_pos, 7.5, 0, TAU, 12, ink_color, 2.0)
	# Musical note doodle on badge
	draw_string(ThemeDB.fallback_font, badge_pos + Vector2(-4, 4), "♪", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, ink_color)

func draw_rosy_blush(pos: Vector2) -> void:
	# Cute blushing oval + comic hatch marks
	draw_circle(pos, 6.0, Color(blush_pink.r, blush_pink.g, blush_pink.b, 0.45))
	draw_line(pos + Vector2(-3, -2), pos + Vector2(-1, 2), blush_pink.darkened(0.2), 1.5)
	draw_line(pos + Vector2(1, -2), pos + Vector2(3, 2), blush_pink.darkened(0.2), 1.5)

func draw_clap_face() -> void:
	var eye_y = -22.0

	if current_pose == "miss":
		# Dizzy comic spirals / X eyes
		draw_x_eye(Vector2(-12, eye_y))
		draw_x_eye(Vector2(12, eye_y))
		# Worried squiggly mouth
		var mouth_pts = PackedVector2Array([
			Vector2(-10, eye_y + 14), Vector2(-4, eye_y + 11),
			Vector2(2, eye_y + 15), Vector2(10, eye_y + 12)
		])
		draw_polyline(mouth_pts, ink_color, 3.0)
	elif is_blinking:
		# Cute closed curved blink lines ⌒
		draw_arc(Vector2(-11, eye_y + 2), 6.0, PI + 0.3, TAU - 0.3, 10, ink_color, 3.0)
		draw_arc(Vector2(11, eye_y + 2), 6.0, PI + 0.3, TAU - 0.3, 10, ink_color, 3.0)
		draw_arc(Vector2(0, eye_y + 12), 8.0, 0.2, PI - 0.2, 12, ink_color, 3.0)
	elif current_pose in ["left", "right", "up", "down"]:
		# Dynamic enthusiastic wink & open singing mouth!
		draw_glossy_eye(Vector2(-11, eye_y), 5.5, current_pose)
		# Winking eye ⌒
		draw_arc(Vector2(12, eye_y + 1), 6.0, PI + 0.3, TAU - 0.3, 10, ink_color, 3.0)
		# Open singing mouth with tongue
		draw_open_singing_mouth(Vector2(0, eye_y + 12))
	else:
		# Idle cute round glossy eyes with specular reflection sparkles
		draw_glossy_eye(Vector2(-11, eye_y), 5.0, "center")
		draw_glossy_eye(Vector2(11, eye_y), 5.0, "center")
		# Happy cartoon smile
		draw_arc(Vector2(0, eye_y + 11), 8.0, 0.2, PI - 0.2, 14, ink_color, 3.0)

func draw_glossy_eye(pos: Vector2, radius: float, look_dir: String) -> void:
	var look_offset = Vector2.ZERO
	match look_dir:
		"left": look_offset = Vector2(-2, 0)
		"right": look_offset = Vector2(2, 0)
		"up": look_offset = Vector2(0, -2)
		"down": look_offset = Vector2(0, 2)

	# Dark pupil
	draw_circle(pos + look_offset, radius, ink_color)
	# Big sparkle highlight
	draw_circle(pos + look_offset + Vector2(-1.8, -1.8), radius * 0.4, paper_white)
	# Secondary tiny specular dot
	draw_circle(pos + look_offset + Vector2(1.5, 1.5), radius * 0.2, paper_white)

func draw_x_eye(pos: Vector2) -> void:
	var d = 5.0
	draw_line(pos + Vector2(-d, -d), pos + Vector2(d, d), ink_color, 3.0)
	draw_line(pos + Vector2(d, -d), pos + Vector2(-d, d), ink_color, 3.0)

func draw_open_singing_mouth(pos: Vector2) -> void:
	# Curved open mouth with tongue
	var pts = PackedVector2Array([
		pos + Vector2(-10, -2),
		pos + Vector2(10, -2),
		pos + Vector2(8, 9),
		pos + Vector2(-8, 9)
	])
	draw_colored_polygon(pts, ink_color)
	# Pink tongue inside
	draw_circle(pos + Vector2(0, 5), 5.5, blush_pink)
	# Ink mouth outline
	draw_polyline(pts + PackedVector2Array([pts[0]]), ink_color, 2.5)

func draw_clap_hands() -> void:
	var lh = Vector2(-40, 26) + limb_offset
	var rh = Vector2(40, 26) + limb_offset

	if current_pose == "left":
		lh = Vector2(-56, 12)
		rh = Vector2(-22, 22)
		# Action speed lines behind left punch
		draw_action_lines(Vector2(-35, 12), Vector2(-1, 0))
	elif current_pose == "right":
		lh = Vector2(22, 22)
		rh = Vector2(56, 12)
		# Action speed lines behind right punch
		draw_action_lines(Vector2(35, 12), Vector2(1, 0))
	elif current_pose == "up":
		lh = Vector2(-28, -32)
		rh = Vector2(28, -32)
		draw_action_lines(Vector2(0, -10), Vector2(0, -1))
	elif current_pose == "down":
		lh = Vector2(-34, 72)
		rh = Vector2(34, 72)
		draw_action_lines(Vector2(0, 50), Vector2(0, 1))

	# Draw Puffy Cartoon Mittens
	for h in [lh, rh]:
		var is_left = h.x < 0
		var flip = -1.0 if is_left else 1.0

		# Glove Shadow
		draw_circle(h + Vector2(3, 3), 16.0, Color(0.1, 0.1, 0.15, 0.25))

		# Glove Body
		draw_circle(h, 16.0, paper_white)
		draw_arc(h, 16.0, 0, TAU, 20, ink_color, 3.2)

		# Defined cartoon thumb
		var thumb_pos = h + Vector2(-10.0 * flip, -5.0)
		draw_circle(thumb_pos, 7.5, paper_white)
		draw_arc(thumb_pos, 7.5, 0, TAU, 14, ink_color, 2.5)

		# Cute palm crease line
		draw_arc(h + Vector2(2.0 * flip, 3), 6.0, 0.2, PI - 0.2, 8, ink_color, 2.0)

		# Wrist Cuffs
		var cuff_rect = Rect2(h.x - 10, h.y + 11, 20, 6)
		draw_rect_rounded(cuff_rect, 3.0, paper_white)
		draw_rect_rounded_outline(cuff_rect, 3.0, ink_color, 2.0)

func draw_action_lines(pos: Vector2, normal: Vector2) -> void:
	if action_line_alpha <= 0.01:
		return
	var col = paper_white
	col.a = action_line_alpha
	var perp = Vector2(-normal.y, normal.x)

	for o in [-14, 0, 14]:
		var start = pos + (perp * o) - (normal * 20.0)
		var end = pos + (perp * o) - (normal * 4.0)
		draw_line(start, end, col, 2.5)

func draw_sweat_and_dizzy_cloud() -> void:
	# Dripping cartoon sweat drop
	var s_pos = Vector2(38, -34)
	draw_circle(s_pos, 7.0, Color(0.3, 0.7, 1.0, sweat_alpha))
	draw_arc(s_pos, 7.0, 0, TAU, 12, ink_color, 2.2)
	# Teardrop point
	draw_colored_polygon(PackedVector2Array([
		s_pos + Vector2(-6, -2), s_pos + Vector2(6, -2), s_pos + Vector2(0, -12)
	]), Color(0.3, 0.7, 1.0, sweat_alpha))
	draw_polyline(PackedVector2Array([
		s_pos + Vector2(-6, -2), s_pos + Vector2(0, -12), s_pos + Vector2(6, -2)
	]), ink_color, 2.2)

	# Dizzy little stars floating above head
	draw_four_point_star(Vector2(-20, -75), 6.0, hero_yellow, ink_color)
	draw_four_point_star(Vector2(22, -72), 7.0, blush_pink, ink_color)

# ==============================================================================
# 2. BEATS (Nervous Drummer Kid with Cardboard Drum)
# ==============================================================================
func draw_beats_character() -> void:
	var shadow_offset = Vector2(4, 5)

	# Floor shadow
	draw_ellipse_shape(Vector2(0, 85) + shadow_offset, Vector2(42, 13), Color(0.1, 0.1, 0.15, 0.28))

	# 1. Striped T-Shirt Body
	var body_rect = Rect2(-32, 12, 64, 62)
	draw_rect_rounded(Rect2(body_rect.position + shadow_offset, body_rect.size), 14.0, Color(0.1, 0.1, 0.15, 0.25))
	draw_rect_rounded(body_rect, 14.0, offbeat_green)

	# Textured T-Shirt Stripes
	for sy in range(22, 68, 12):
		var stripe_rect = Rect2(-30, sy, 60, 6)
		draw_rect(stripe_rect, offbeat_green.lightened(0.25))
		draw_line(Vector2(-30, sy), Vector2(30, sy), ink_color.lerp(offbeat_green, 0.4), 1.5)

	draw_rect_rounded_outline(body_rect, 14.0, ink_color, 3.2)

	# 2. Big Nervous Head
	var head_pos = Vector2(0, -22)
	draw_circle(head_pos + shadow_offset, 34.0, Color(0.1, 0.1, 0.15, 0.25))
	draw_circle(head_pos, 34.0, paper_white)
	draw_arc(head_pos, 34.0, 0, TAU, 30, ink_color, 3.2)

	# Band-Aid plaster on cheek (cute lovable detail)
	draw_bandaid(Vector2(16, -14))

	# Messy hair doodle tufts (with bouncy secondary motion)
	draw_beats_hair(head_pos)

	# Huge worried/excited eyes + expression
	draw_beats_face(head_pos)

	# 3. Cardboard Drum with Realistic Corrugated Texture
	draw_beats_cardboard_drum()

	# 4. Drumsticks & Hands
	draw_beats_hands()

func draw_bandaid(pos: Vector2) -> void:
	var b_rect = Rect2(pos.x - 7, pos.y - 7, 14, 14)
	draw_rect_rounded(b_rect, 3.0, cardboard_light)
	draw_rect_rounded_outline(b_rect, 3.0, ink_color, 2.0)
	# Center pad cross
	draw_line(Vector2(pos.x - 3, pos.y), Vector2(pos.x + 3, pos.y), cardboard_dark, 1.5)
	draw_line(Vector2(pos.x, pos.y - 3), Vector2(pos.x, pos.y + 3), cardboard_dark, 1.5)

func draw_beats_hair(head_pos: Vector2) -> void:
	var h_bob = hair_bob
	var hair_pts = PackedVector2Array([
		Vector2(-28, -46 + h_bob),
		Vector2(-20, -62 + h_bob * 1.2),
		Vector2(-10, -50 + h_bob),
		Vector2(2, -64 + h_bob * 1.3),
		Vector2(14, -52 + h_bob),
		Vector2(24, -60 + h_bob * 1.1),
		Vector2(30, -44 + h_bob),
		Vector2(0, -38)
	])
	draw_colored_polygon(hair_pts, ink_color)
	draw_polyline(hair_pts + PackedVector2Array([hair_pts[0]]), ink_color, 2.5)

	# Comic hair shine highlight tuft
	draw_line(Vector2(-12, -48 + h_bob), Vector2(-4, -56 + h_bob), paper_white, 2.5)

func draw_beats_face(head_pos: Vector2) -> void:
	var eye_y = -22.0
	# Pupils vibrate slightly when nervous
	var tremble = Vector2(randf_range(-0.6, 0.6), randf_range(-0.6, 0.6)) if current_pose != "miss" else Vector2.ZERO

	if current_pose == "miss":
		draw_x_eye(Vector2(-11, eye_y))
		draw_x_eye(Vector2(11, eye_y))
		# Nervous wavy zigzag mouth
		draw_line(Vector2(-10, eye_y + 14), Vector2(-5, eye_y + 11), ink_color, 2.5)
		draw_line(Vector2(-5, eye_y + 11), Vector2(0, eye_y + 15), ink_color, 2.5)
		draw_line(Vector2(0, eye_y + 15), Vector2(5, eye_y + 11), ink_color, 2.5)
		draw_line(Vector2(5, eye_y + 11), Vector2(10, eye_y + 14), ink_color, 2.5)
	elif is_blinking:
		draw_arc(Vector2(-11, eye_y + 2), 6.0, PI + 0.3, TAU - 0.3, 8, ink_color, 3.0)
		draw_arc(Vector2(11, eye_y + 2), 6.0, PI + 0.3, TAU - 0.3, 8, ink_color, 3.0)
	else:
		# Large round expressive cartoon eyes
		for ex in [-11.0, 11.0]:
			draw_circle(Vector2(ex, eye_y), 8.0, paper_white)
			draw_arc(Vector2(ex, eye_y), 8.0, 0, TAU, 16, ink_color, 2.5)
			# Pupil with tremble
			draw_circle(Vector2(ex, eye_y) + tremble, 4.0, ink_color)
			draw_circle(Vector2(ex - 2, eye_y - 2), 1.8, paper_white)

		# Nervous wavy smile
		var mouth_pts = PackedVector2Array([
			Vector2(-9, eye_y + 13), Vector2(-3, eye_y + 10),
			Vector2(3, eye_y + 14), Vector2(9, eye_y + 11)
		])
		draw_polyline(mouth_pts, ink_color, 2.5)

	# Sweat drop on temple
	draw_circle(Vector2(-24, -30), 4.5, Color(0.3, 0.7, 1.0, 0.85))
	draw_arc(Vector2(-24, -30), 4.5, 0, TAU, 8, ink_color, 1.8)

func draw_beats_cardboard_drum() -> void:
	var drum_rect = Rect2(-28, 22, 56, 46)
	var shadow_offset = Vector2(3, 4)

	# Drum shadow
	draw_rect_rounded(Rect2(drum_rect.position + shadow_offset, drum_rect.size), 8.0, Color(0.1, 0.1, 0.15, 0.25))

	# Cardboard Base
	draw_rect_rounded(drum_rect, 8.0, cardboard_brown)

	# Corrugated Cardboard Fluting Texture (horizontal ribbed texture)
	for ry in range(int(drum_rect.position.y) + 6, int(drum_rect.position.y + drum_rect.size.y) - 4, 6):
		# Dark rib groove
		draw_line(Vector2(drum_rect.position.x + 4, ry), Vector2(drum_rect.position.x + drum_rect.size.x - 4, ry), cardboard_dark, 1.5)
		# Light rib highlight
		draw_line(Vector2(drum_rect.position.x + 4, ry + 1.5), Vector2(drum_rect.position.x + drum_rect.size.x - 4, ry + 1.5), cardboard_light, 1.5)

	# Packaging Tape "X" with torn fiber edges
	draw_torn_tape_strip(Vector2(-18, 30), Vector2(18, 60))
	draw_torn_tape_strip(Vector2(-18, 60), Vector2(18, 30))

	# Metallic Drum Rim Hoops (top and bottom silver brackets)
	var rim_top = Rect2(-29, 21, 58, 6)
	draw_rect_rounded(rim_top, 3.0, Color("#D3D3E0"))
	draw_rect_rounded_outline(rim_top, 3.0, ink_color, 2.0)

	var rim_bot = Rect2(-29, 62, 58, 6)
	draw_rect_rounded(rim_bot, 3.0, Color("#D3D3E0"))
	draw_rect_rounded_outline(rim_bot, 3.0, ink_color, 2.0)

	# 4 Tension bracket lugs
	for lx in [-22, -8, 8, 22]:
		draw_line(Vector2(lx, 26), Vector2(lx, 63), Color("#D3D3E0"), 2.0)
		draw_circle(Vector2(lx, 44), 2.5, ink_color)

	# Outer outline
	draw_rect_rounded_outline(drum_rect, 8.0, ink_color, 3.2)

func draw_torn_tape_strip(p1: Vector2, p2: Vector2) -> void:
	# Translucent masking tape strip
	var tape_col = Color(paper_white.r, paper_white.g, paper_white.b, 0.75)
	draw_line(p1, p2, tape_col, 5.5)
	# Subtle edge lines
	draw_line(p1, p2, paper_white.darkened(0.2), 1.0)

func draw_beats_hands() -> void:
	var lh = Vector2(-32, 18) + limb_offset
	var rh = Vector2(32, 18) + limb_offset

	if current_pose != "idle":
		lh.y += 14
		rh.y += 14

	# Wooden Drumsticks with wood grain
	draw_drumstick(lh, lh + Vector2(20, 16))
	draw_drumstick(rh, rh + Vector2(-20, 16))

	# Cartoon Hands
	draw_circle(lh, 9.0, paper_white)
	draw_arc(lh, 9.0, 0, TAU, 14, ink_color, 2.5)
	draw_circle(rh, 9.0, paper_white)
	draw_arc(rh, 9.0, 0, TAU, 14, ink_color, 2.5)

func draw_drumstick(start: Vector2, tip: Vector2) -> void:
	# Stick body
	draw_line(start, tip, cardboard_dark, 4.0)
	draw_line(start, tip, cardboard_light, 1.5)
	# Wooden tip bead
	draw_circle(tip, 3.5, cardboard_light)
	draw_arc(tip, 3.5, 0, TAU, 8, ink_color, 1.8)

# ==============================================================================
# 3. THE STRAIGHT MAN (Stiff Week 1 Boss in Crisp Pinstripe Suit)
# ==============================================================================
func draw_straight_man() -> void:
	var shadow_offset = Vector2(4, 5)

	# Floor shadow
	draw_ellipse_shape(Vector2(0, 92) + shadow_offset, Vector2(48, 14), Color(0.1, 0.1, 0.15, 0.28))

	# 1. Polished Leather Dress Shoes
	draw_straight_man_shoes()

	# 2. Suit Body with Crisp Pinstripe Fabric Texture
	var body_rect = Rect2(-32, -8, 64, 100)
	draw_rect_rounded(Rect2(body_rect.position + shadow_offset, body_rect.size), 8.0, Color(0.1, 0.1, 0.15, 0.25))
	draw_rect_rounded(body_rect, 8.0, suit_navy)

	# Crisp Vertical Pinstripes Texture
	for px in range(-26, 28, 8):
		draw_line(Vector2(px, -4), Vector2(px, 88), suit_stripe, 1.5)

	# Crisp White Collar & Lapels
	var col_points = PackedVector2Array([Vector2(-16, -8), Vector2(16, -8), Vector2(0, 16)])
	draw_colored_polygon(col_points, paper_white)
	draw_polyline(col_points, ink_color, 2.5)

	# Lapels
	draw_line(Vector2(-16, -8), Vector2(-8, 32), ink_color, 2.5)
	draw_line(Vector2(16, -8), Vector2(8, 32), ink_color, 2.5)

	# Breast Pocket with Folded Red Pocket Square
	var pocket_rect = Rect2(-26, 12, 14, 4)
	draw_rect(pocket_rect, ink_color)
	# Red handkerchief tip peeking out
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24, 12), Vector2(-19, 4), Vector2(-14, 12)
	]), straight_red)

	# Suit Outline
	draw_rect_rounded_outline(body_rect, 8.0, ink_color, 3.5)

	# 3. Dynamic Swinging Silk Red Tie
	draw_straight_man_tie()

	# 4. Rectangular Stiff Head & Monocle
	draw_straight_man_head()

	# 5. Crisp Hands with Golden Cuff Links
	draw_straight_man_hands()

func draw_straight_man_shoes() -> void:
	for sx in [-16.0, 16.0]:
		var s_rect = Rect2(sx - 11, 88, 22, 10)
		draw_rect_rounded(s_rect, 4.0, ink_color)
		# Shiny polish reflection line
		draw_line(Vector2(sx - 6, 90), Vector2(sx + 6, 90), Color(0.4, 0.4, 0.6, 0.6), 2.0)
		draw_line(Vector2(sx - 10, 97), Vector2(sx + 10, 97), paper_white, 1.5)

func draw_straight_man_tie() -> void:
	var swing = tie_swing + (sin(idle_time * 2.8) * 3.0)
	var tie_points = PackedVector2Array([
		Vector2(-6, 14), Vector2(6, 14),
		Vector2(7 + swing, 54), Vector2(0 + swing, 65), Vector2(-7 + swing, 54)
	])
	draw_colored_polygon(tie_points, straight_red)

	# Diagonal textured micro-stripes on tie
	for ty in [22, 32, 42, 52]:
		var t_pos = Vector2(swing * 0.5, ty)
		draw_line(t_pos + Vector2(-4, -2), t_pos + Vector2(4, 2), hero_yellow.lerp(straight_red, 0.5), 1.8)

	draw_polyline(tie_points + PackedVector2Array([tie_points[0]]), ink_color, 2.5)

func draw_straight_man_head() -> void:
	var head_rect = Rect2(-25, -66, 50, 56)
	var shadow_offset = Vector2(3, 4)

	# Head shadow
	draw_rect_rounded(Rect2(head_rect.position + shadow_offset, head_rect.size), 8.0, Color(0.1, 0.1, 0.15, 0.25))

	# Head base
	draw_rect_rounded(head_rect, 8.0, paper_white)
	draw_rect_rounded_outline(head_rect, 8.0, ink_color, 3.5)

	# Slick Dark Hair with Gel Sheen
	var hair_rect = Rect2(-25, -66, 50, 18)
	draw_rect_rounded_top(hair_rect, 8.0, ink_color)
	# Gel highlight sheen
	draw_line(Vector2(-16, -60), Vector2(8, -60), Color(0.4, 0.4, 0.6, 0.8), 2.5)

	var eye_y = -38.0

	# 1. Monocle on Left Eye (Golden Rim + Glass Glint + Chain)
	var monocle_pos = Vector2(-10, eye_y)
	draw_circle(monocle_pos, 10.0, Color(0.85, 0.95, 1.0, 0.55)) # Glass tint
	draw_arc(monocle_pos, 10.0, 0, TAU, 22, gold_color, 2.8) # Gold rim
	# Specular glass glint diagonal slash //
	draw_line(monocle_pos + Vector2(-5, -5), monocle_pos + Vector2(2, 5), paper_white, 2.0)
	draw_line(monocle_pos + Vector2(-2, -5), monocle_pos + Vector2(5, 5), paper_white, 1.2)

	# Delicate Draped Golden Monocle Chain down to lapel
	var chain_pts = PackedVector2Array([
		monocle_pos + Vector2(10, 2),
		Vector2(2, -22),
		Vector2(-4, -6)
	])
	draw_polyline(chain_pts, gold_color, 1.5)

	# Pupils / Eyes
	if current_pose == "miss":
		draw_x_eye(monocle_pos)
		draw_x_eye(Vector2(11, eye_y))
		# Frustrated sneer
		draw_line(Vector2(-10, eye_y + 16), Vector2(10, eye_y + 13), ink_color, 3.0)
	elif is_blinking:
		draw_line(Vector2(-15, eye_y), Vector2(-5, eye_y), ink_color, 2.5)
		draw_line(Vector2(6, eye_y), Vector2(16, eye_y), ink_color, 2.5)
		draw_line(Vector2(-8, eye_y + 16), Vector2(8, eye_y + 16), ink_color, 2.5)
	else:
		# Stiff deadpan pupils
		draw_circle(monocle_pos, 3.2, ink_color)
		draw_circle(Vector2(11, eye_y), 3.2, ink_color)

		# Raised skeptical eyebrow on right eye
		var brow_twitch = sin(idle_time * 4.0) * 1.5
		draw_line(Vector2(6, eye_y - 8 + brow_twitch), Vector2(16, eye_y - 11 + brow_twitch), ink_color, 2.5)

		# Deadpan stiff mouth
		draw_line(Vector2(-8, eye_y + 16), Vector2(8, eye_y + 16), ink_color, 2.5)

func draw_straight_man_hands() -> void:
	var lh = Vector2(-38, 38) + limb_offset
	var rh = Vector2(38, 38) + limb_offset

	for h in [lh, rh]:
		var is_left = h.x < 0
		var flip = -1.0 if is_left else 1.0

		# White Shirt Cuff peeking out
		var cuff_rect = Rect2(h.x - 7, h.y - 12, 14, 6)
		draw_rect_rounded(cuff_rect, 2.0, paper_white)
		draw_rect_rounded_outline(cuff_rect, 2.0, ink_color, 1.8)

		# Golden Cuff Link
		draw_circle(Vector2(h.x + (5.0 * flip), h.y - 9), 2.2, gold_color)

		# Hand
		draw_circle(h, 11.0, paper_white)
		draw_arc(h, 11.0, 0, TAU, 16, ink_color, 2.8)

# ==============================================================================
# Helper Drawing Utilities
# ==============================================================================
func draw_ellipse_shape(center: Vector2, radius: Vector2, col: Color) -> void:
	var pts = PackedVector2Array()
	var segments = 24
	for i in range(segments):
		var a = (float(i) / float(segments)) * TAU
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(pts, col)

func draw_dashes(from_pos: Vector2, to_pos: Vector2, col: Color, width: float, dash_len: float, gap_len: float) -> void:
	var total_dist = from_pos.distance_to(to_pos)
	if total_dist <= 0.001:
		return
	var dir = (to_pos - from_pos).normalized()
	var cur = 0.0
	while cur < total_dist:
		var end_pt = min(cur + dash_len, total_dist)
		draw_line(from_pos + (dir * cur), from_pos + (dir * end_pt), col, width)
		cur += dash_len + gap_len

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
