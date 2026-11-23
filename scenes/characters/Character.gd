extends Control

@export var character_type: String = "clap" # clap, beats, straight_man, swing_queen, syncopator, twins, metronome
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
	fx_hit_burst(dir)

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
	fx_miss_puff()
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
	_fx_process(delta)

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

	draw_power_aura()

	match character_type:
		"beats":
			draw_beats_character()
		"straight_man":
			draw_straight_man()
		"swing_queen":
			draw_swing_queen()
		"syncopator":
			draw_syncopator()
		"twins":
			draw_twins()
		"metronome":
			draw_metronome_bot()
		_:
			draw_clap_character()

	# Comic hit stars / sparkles pop
	if hit_star_alpha > 0.01:
		draw_comic_hit_stars()

	# Particles in un-squashed space around the character
	if is_echo:
		return
	draw_set_transform(size / 2.0, 0.0, Vector2.ONE)
	draw_fx_particles()

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
	draw_driver_cap()

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

# ==============================================================================
# Shared helpers for the newer characters
# ==============================================================================
var skin_warm: Color = Color("#C98B62")
var skin_light: Color = Color("#F2C9A0")
var queen_purple: Color = Color("#6B3FA0")
var neon_pink: Color = Color("#FF4D8D")
var neon_cyan: Color = Color("#00E5FF")
var mohawk_green: Color = Color("#6BCB5A")
var shadow_col: Color = Color(0.1, 0.1, 0.15, 0.28)

func draw_poly(pts: PackedVector2Array, fill: Color, outline_w: float = 3.0) -> void:
	draw_colored_polygon(pts, fill)
	draw_polyline(pts + PackedVector2Array([pts[0]]), ink_color, outline_w)

func draw_ring(pos: Vector2, r: float, fill: Color, outline_w: float = 3.0) -> void:
	draw_circle(pos, r, fill)
	draw_arc(pos, r, 0, TAU, 28, ink_color, outline_w)

func pose_hands(base_l: Vector2, base_r: Vector2) -> Array:
	var lh = base_l + limb_offset
	var rh = base_r + limb_offset
	match current_pose:
		"left":
			lh = base_l + Vector2(-18, -14)
			rh = base_l + Vector2(16, -4)
		"right":
			lh = base_r + Vector2(-16, -4)
			rh = base_r + Vector2(18, -14)
		"up":
			lh = base_l + Vector2(-6, -52)
			rh = base_r + Vector2(6, -52)
		"down":
			lh = base_l + Vector2(-4, 18)
			rh = base_r + Vector2(4, 18)
	return [lh, rh]

func draw_simple_eyes(l: Vector2, r: Vector2, radius: float) -> void:
	if current_pose == "miss":
		draw_x_eye(l)
		draw_x_eye(r)
	elif is_blinking:
		draw_arc(l + Vector2(0, 2), radius + 1.0, PI + 0.3, TAU - 0.3, 10, ink_color, 2.5)
		draw_arc(r + Vector2(0, 2), radius + 1.0, PI + 0.3, TAU - 0.3, 10, ink_color, 2.5)
	else:
		var look = "center" if current_pose in ["idle", "hit"] else current_pose
		draw_glossy_eye(l, radius, look)
		draw_glossy_eye(r, radius, look)

# ==============================================================================
# 4. SWING QUEEN (Jazz singer: sequin gown, big curls, vintage mic)
# ==============================================================================
func draw_swing_queen() -> void:
	# Swings in a lazy triplet sway
	var sway = sin(idle_time * 2.2) * 4.0 + hoodie_swing * 24.0
	draw_ellipse_shape(Vector2(4, 98), Vector2(56, 13), shadow_col)

	# Sequin gown: a tall triangle that flares at the hem
	var gown = PackedVector2Array([
		Vector2(-15, -8), Vector2(15, -8),
		Vector2(50 + sway, 92), Vector2(-50 + sway, 92)
	])
	draw_poly(gown, triplet_blue, 3.5)
	for i in range(16):
		var t = float(i % 4) / 3.0
		var row = float(i / 4) / 3.0
		var y = 6.0 + row * 80.0
		var half_w = 15.0 + (y + 8.0) / 100.0 * 35.0
		var x = lerpf(-half_w + 8.0, half_w - 8.0, t) + sway * (y + 8.0) / 100.0
		var tw = 0.45 + 0.55 * absf(sin(idle_time * 3.0 + float(i) * 1.7))
		draw_circle(Vector2(x, y), 2.2, Color(1, 1, 1, tw * 0.8))
	# Scalloped hem
	for i in range(7):
		var hx = -44.0 + float(i) * 14.7 + sway
		draw_arc(Vector2(hx, 92), 7.0, 0, PI, 8, ink_color, 2.5)
	# Gold belt
	draw_rect_rounded(Rect2(-17, 4, 34, 7), 3.0, gold_color)
	draw_rect_rounded_outline(Rect2(-17, 4, 34, 7), 3.0, ink_color, 2.0)

	# Feather boa draped over the shoulders
	var boa = PackedVector2Array()
	for i in range(13):
		var t = float(i) / 12.0
		var bx = lerpf(-36.0, 36.0, t)
		var by = -4.0 + 8.0 * pow(2.0 * t - 1.0, 2.0) + sin(idle_time * 5.0 + t * 9.0) * 2.0
		boa.append(Vector2(bx, by))
	draw_polyline(boa, ink_color, 14.0)
	draw_polyline(boa, blush_pink, 10.0)
	for i in range(0, 13, 2):
		draw_circle(boa[i] + Vector2(0, 3), 3.0, Color("#FFC2D1"))

	# Arms + hands, right hand holds a vintage mic
	var hands = pose_hands(Vector2(-36, 28), Vector2(34, 10))
	var lh: Vector2 = hands[0]
	var rh: Vector2 = hands[1]
	draw_line(Vector2(-16, 0), lh, ink_color, 7.0)
	draw_line(Vector2(-16, 0), lh, skin_warm, 4.0)
	draw_line(Vector2(16, 0), rh, ink_color, 7.0)
	draw_line(Vector2(16, 0), rh, skin_warm, 4.0)
	# Long satin glove on the hand
	draw_ring(lh, 7.5, paper_white, 2.5)
	draw_ring(rh, 7.5, paper_white, 2.5)
	var mic_top = rh + Vector2(4, -20)
	draw_line(rh, mic_top, ink_color, 5.0)
	draw_ring(mic_top, 7.0, Color("#B8B8C8"), 2.5)
	for k in range(-1, 2):
		draw_line(mic_top + Vector2(-5, k * 3), mic_top + Vector2(5, k * 3), ink_color, 1.0)

	# Big curly hair behind the head
	var head = Vector2(0, -38)
	var bob = hair_bob * 0.5
	for c in [Vector2(-22, -8), Vector2(22, -8), Vector2(-16, -26), Vector2(16, -26), Vector2(0, -32), Vector2(-26, 8), Vector2(26, 8)]:
		draw_circle(head + c + Vector2(0, bob), 14.0, ink_color)
	for c in [Vector2(-22, -8), Vector2(22, -8), Vector2(-16, -26), Vector2(16, -26), Vector2(0, -32), Vector2(-26, 8), Vector2(26, 8)]:
		draw_circle(head + c + Vector2(0, bob), 11.5, queen_purple)

	# Face
	draw_ring(head, 21.0, skin_warm, 3.0)
	var eye_y = head.y - 3.0
	if current_pose == "miss":
		draw_x_eye(Vector2(-8, eye_y))
		draw_x_eye(Vector2(8, eye_y))
		draw_arc(Vector2(0, eye_y + 15), 4.0, 0, TAU, 10, ink_color, 2.5)
	else:
		for ex in [-8.0, 8.0]:
			if is_blinking or current_pose == "idle":
				# Glamorous half-closed eyes with lashes
				draw_arc(Vector2(ex, eye_y), 5.0, 0.2, PI - 0.2, 10, ink_color, 2.5)
				for l in range(3):
					var a = 0.5 + float(l) * 1.0
					var p = Vector2(ex, eye_y) + Vector2(cos(a), sin(a)) * 5.0
					draw_line(p, p + Vector2(cos(a), sin(a)) * 3.5, ink_color, 1.5)
			else:
				draw_glossy_eye(Vector2(ex, eye_y), 4.0, current_pose)
		# Red lips (open when performing)
		if current_pose in ["left", "right", "up", "down"]:
			draw_circle(Vector2(0, eye_y + 14), 5.0, straight_red)
			draw_circle(Vector2(0, eye_y + 15), 2.5, ink_color)
		else:
			draw_ellipse_shape(Vector2(0, eye_y + 13), Vector2(6, 3), straight_red)
	draw_rosy_blush(Vector2(-13, eye_y + 8))
	draw_rosy_blush(Vector2(13, eye_y + 8))

	# Tiara
	var tiara = PackedVector2Array([
		head + Vector2(-14, -20 + bob), head + Vector2(-8, -34 + bob), head + Vector2(-3, -24 + bob),
		head + Vector2(0, -38 + bob), head + Vector2(3, -24 + bob), head + Vector2(8, -34 + bob),
		head + Vector2(14, -20 + bob)
	])
	draw_poly(tiara, gold_color, 2.0)
	draw_circle(head + Vector2(0, -27 + bob), 2.5, neon_pink)

	if sweat_alpha > 0.01:
		draw_sweat_and_dizzy_cloud()

# ==============================================================================
# 5. THE SYNCOPATOR (Off-beat prankster: leaning hoodie, mohawk, odd shoes)
# ==============================================================================
func draw_syncopator() -> void:
	var lean = 0.14 + sin(idle_time * 3.7) * 0.05
	var sk = func(p: Vector2) -> Vector2: return Vector2(p.x - p.y * lean, p.y)
	draw_ellipse_shape(Vector2(6, 96), Vector2(46, 12), shadow_col)

	# Skinny legs + mismatched sneakers
	for side in [-1.0, 1.0]:
		var hip = sk.call(Vector2(side * 10, 62))
		var foot = Vector2(side * 14 + (foot_tap_l if side < 0 else foot_tap_r), 88)
		draw_line(hip, foot, ink_color, 9.0)
		draw_line(hip, foot, Color("#3A3A52"), 6.0)
		var shoe = Rect2(foot.x - 12, foot.y - 2, 24, 10)
		draw_rect_rounded(shoe, 4.0, rest_orange if side < 0 else neon_pink)
		draw_rect_rounded_outline(shoe, 4.0, ink_color, 2.5)

	# Leaning hoodie with a zigzag stripe
	var body = PackedVector2Array([
		sk.call(Vector2(-25, -6)), sk.call(Vector2(25, -6)),
		sk.call(Vector2(29, 66)), sk.call(Vector2(-27, 66))
	])
	draw_poly(body, offbeat_green, 3.5)
	var zig = PackedVector2Array()
	for i in range(7):
		zig.append(sk.call(Vector2(-25 + i * 8.6, 28 + (8 if i % 2 == 0 else -8))))
	draw_polyline(zig, ink_color, 6.0)
	draw_polyline(zig, hero_yellow, 3.5)
	# Hood strings
	draw_line(sk.call(Vector2(-6, -4)), sk.call(Vector2(-8, 14)), paper_white, 2.0)
	draw_line(sk.call(Vector2(6, -4)), sk.call(Vector2(8, 16)), paper_white, 2.0)

	# Arms: one hand does finger guns
	var hands = pose_hands(sk.call(Vector2(-38, 30)), sk.call(Vector2(40, 12)))
	var lh: Vector2 = hands[0]
	var rh: Vector2 = hands[1]
	draw_line(sk.call(Vector2(-22, 2)), lh, ink_color, 9.0)
	draw_line(sk.call(Vector2(-22, 2)), lh, offbeat_green, 6.0)
	draw_line(sk.call(Vector2(22, 2)), rh, ink_color, 9.0)
	draw_line(sk.call(Vector2(22, 2)), rh, offbeat_green, 6.0)
	draw_ring(lh, 8.0, skin_light, 2.5)
	draw_ring(rh, 8.0, skin_light, 2.5)
	draw_line(rh, rh + Vector2(12, -4), ink_color, 5.0)
	draw_line(rh, rh + Vector2(12, -4), skin_light, 2.5)

	# Tilted oval head
	var head = sk.call(Vector2(-2, -36))
	var head_pts = PackedVector2Array()
	for i in range(24):
		var a = float(i) / 24.0 * TAU
		head_pts.append(head + Vector2(cos(a) * 20.0, sin(a) * 24.0).rotated(-0.18))
	# Mohawk spikes (behind the head outline so it reads as hair)
	for i in range(5):
		var bx = -12.0 + float(i) * 6.0
		var tip_sway = sin(idle_time * 6.0 + float(i)) * 2.0 + hair_bob
		var spike = PackedVector2Array([
			head + Vector2(bx - 4, -18).rotated(-0.18),
			head + Vector2(bx + tip_sway + 3, -40 - (i % 2) * 6).rotated(-0.18),
			head + Vector2(bx + 4, -18).rotated(-0.18)
		])
		draw_poly(spike, mohawk_green, 2.5)
	draw_poly(head_pts, skin_light, 3.0)

	# Mismatched eyes: one big, one small, plus a raised brow
	var le = head + Vector2(-8, -4)
	var re = head + Vector2(9, -2)
	if current_pose == "miss":
		draw_x_eye(le)
		draw_x_eye(re)
	elif is_blinking:
		draw_line(le + Vector2(-6, 0), le + Vector2(6, 0), ink_color, 2.5)
		draw_line(re + Vector2(-4, 0), re + Vector2(4, 0), ink_color, 2.5)
	else:
		draw_ring(le, 7.0, paper_white, 2.5)
		draw_circle(le + Vector2(2, 1), 3.2, ink_color)
		draw_ring(re, 4.5, paper_white, 2.0)
		draw_circle(re + Vector2(1, 1), 2.0, ink_color)
	draw_line(le + Vector2(-7, -11 + sin(idle_time * 5.0) * 2.0), le + Vector2(5, -14), ink_color, 2.5)
	# Gap-toothed grin
	var m = head + Vector2(1, 11)
	draw_arc(m, 9.0, 0.1, PI - 0.1, 12, ink_color, 3.0)
	draw_rect(Rect2(m.x - 6, m.y + 1, 5, 5), paper_white)
	draw_rect(Rect2(m.x + 1, m.y + 1, 5, 5), paper_white)
	# Gold earring
	draw_arc(head + Vector2(20, 4), 3.5, 0, TAU, 10, gold_color, 2.0)

	if sweat_alpha > 0.01:
		draw_sweat_and_dizzy_cloud()

# ==============================================================================
# 6. THE TWINS: TRI (triangle, counts in 3) and QUAD (square, counts in 4)
# ==============================================================================
func draw_twins() -> void:
	draw_ellipse_shape(Vector2(4, 96), Vector2(70, 13), shadow_col)
	# Bob out of sync: Tri on a 3-feel, Quad on a 4-feel
	var tri_y = -absf(sin(idle_time * 4.2)) * 5.0
	var quad_y = -absf(sin(idle_time * 3.15)) * 5.0
	draw_tri(Vector2(-30, tri_y))
	draw_quad(Vector2(32, quad_y))

func draw_tri(o: Vector2) -> void:
	# Legs
	for lx in [-10.0, 10.0]:
		draw_line(o + Vector2(lx, 78), o + Vector2(lx, 92), ink_color, 5.0)
		draw_rect_rounded(Rect2(o.x + lx - 8, o.y + 88, 16, 7), 3.0, ink_color)
	# Triangle body
	draw_poly(PackedVector2Array([o + Vector2(0, -4), o + Vector2(30, 80), o + Vector2(-30, 80)]), rest_orange, 3.5)
	# Shop apron with a big 3
	draw_poly(PackedVector2Array([o + Vector2(-12, 34), o + Vector2(12, 34), o + Vector2(16, 74), o + Vector2(-16, 74)]), paper_white, 2.5)
	draw_string(ThemeDB.fallback_font, o + Vector2(-7, 64), "3", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, rest_orange.darkened(0.3))
	# Arms
	var hands = pose_hands(o + Vector2(-26, 40), o + Vector2(24, 40))
	draw_line(o + Vector2(-10, 26), hands[0], ink_color, 4.0)
	draw_line(o + Vector2(10, 26), hands[1], ink_color, 4.0)
	draw_ring(hands[0], 6.0, skin_light, 2.0)
	draw_ring(hands[1], 6.0, skin_light, 2.0)
	# Round head with a three-spike haircut
	var head = o + Vector2(0, -22)
	for i in range(3):
		var sx = -9.0 + float(i) * 9.0
		draw_poly(PackedVector2Array([head + Vector2(sx - 6, -12), head + Vector2(sx, -30 + hair_bob * 0.5), head + Vector2(sx + 6, -12)]), Color("#3A2A20"), 2.0)
	draw_ring(head, 17.0, skin_light, 3.0)
	draw_simple_eyes(head + Vector2(-6, -2), head + Vector2(6, -2), 3.5)
	if current_pose in ["left", "right", "up", "down"]:
		draw_open_singing_mouth(head + Vector2(0, 8))
	else:
		draw_arc(head + Vector2(0, 6), 5.0, 0.3, PI - 0.3, 8, ink_color, 2.5)

func draw_quad(o: Vector2) -> void:
	for lx in [-12.0, 12.0]:
		draw_line(o + Vector2(lx, 78), o + Vector2(lx, 92), ink_color, 5.0)
		draw_rect_rounded(Rect2(o.x + lx - 8, o.y + 88, 16, 7), 3.0, ink_color)
	# Square body
	var body = Rect2(o.x - 24, o.y + 4, 48, 76)
	draw_rect_rounded(body, 4.0, Color("#B85F35"))
	draw_rect_rounded_outline(body, 4.0, ink_color, 3.5)
	draw_rect_rounded(Rect2(o.x - 14, o.y + 34, 28, 40), 3.0, paper_white)
	draw_rect_rounded_outline(Rect2(o.x - 14, o.y + 34, 28, 40), 3.0, ink_color, 2.5)
	draw_string(ThemeDB.fallback_font, o + Vector2(-7, 64), "4", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#B85F35").darkened(0.3))
	var hands = pose_hands(o + Vector2(-32, 42), o + Vector2(32, 42))
	draw_line(o + Vector2(-22, 20), hands[0], ink_color, 4.0)
	draw_line(o + Vector2(22, 20), hands[1], ink_color, 4.0)
	draw_ring(hands[0], 6.0, skin_light, 2.0)
	draw_ring(hands[1], 6.0, skin_light, 2.0)
	# Square head, flat-top hair, square glasses
	var head = Rect2(o.x - 18, o.y - 40, 36, 36)
	draw_rect_rounded(head, 5.0, skin_light)
	draw_rect_rounded_outline(head, 5.0, ink_color, 3.0)
	draw_rect_rounded_top(Rect2(head.position.x, head.position.y - 4 + hair_bob * 0.3, 36, 10), 4.0, Color("#3A2A20"))
	var c = head.get_center()
	for gx in [-8.0, 8.0]:
		draw_rect_rounded_outline(Rect2(c.x + gx - 6, c.y - 7, 12, 10), 2.0, ink_color, 2.0)
	draw_line(Vector2(c.x - 2, c.y - 3), Vector2(c.x + 2, c.y - 3), ink_color, 2.0)
	if current_pose == "miss":
		draw_x_eye(c + Vector2(-8, -2))
		draw_x_eye(c + Vector2(8, -2))
	elif not is_blinking:
		draw_circle(c + Vector2(-8, -2), 2.2, ink_color)
		draw_circle(c + Vector2(8, -2), 2.2, ink_color)
	else:
		draw_line(c + Vector2(-12, -2), c + Vector2(-4, -2), ink_color, 2.0)
		draw_line(c + Vector2(4, -2), c + Vector2(12, -2), ink_color, 2.0)
	if current_pose in ["left", "right", "up", "down"]:
		draw_rect(Rect2(c.x - 6, c.y + 6, 12, 7), ink_color)
	else:
		draw_line(c + Vector2(-6, 9), c + Vector2(6, 9), ink_color, 2.5)

# ==============================================================================
# 7. THE METRONOME (the clock tower's robot form: pyramid body, swinging arm, clock eye)
# ==============================================================================
func draw_metronome_bot() -> void:
	draw_ellipse_shape(Vector2(4, 98), Vector2(58, 13), shadow_col)
	# Stubby feet
	for fx in [-28.0, 28.0]:
		draw_rect_rounded(Rect2(fx - 12, 86, 24, 10), 3.0, ink_color)
	# Pyramid body
	var body = PackedVector2Array([Vector2(-20, -88), Vector2(20, -88), Vector2(52, 90), Vector2(-52, 90)])
	draw_poly(body, suit_navy, 4.0)
	var panel = PackedVector2Array([Vector2(-12, -30), Vector2(12, -30), Vector2(30, 80), Vector2(-30, 80)])
	draw_poly(panel, suit_stripe, 2.5)
	# Tempo scale tick marks
	for i in range(8):
		var y = -22.0 + float(i) * 12.0
		var w = 6.0 + float(i) * 1.6
		draw_line(Vector2(-w, y), Vector2(w, y), neon_pink.lerp(suit_stripe, 0.4), 2.0)
	# Neon trim + finial
	draw_line(Vector2(-20, -88), Vector2(-52, 90), neon_pink, 2.0)
	draw_line(Vector2(20, -88), Vector2(52, 90), neon_pink, 2.0)
	draw_poly(PackedVector2Array([Vector2(-8, -88), Vector2(0, -100), Vector2(8, -88)]), gold_color, 2.5)

	# Gear hands on thin metal arms
	var hands = pose_hands(Vector2(-54, 30), Vector2(54, 30))
	for i in range(2):
		var shoulder = Vector2(-26 if i == 0 else 26, -10)
		var h: Vector2 = hands[i]
		draw_line(shoulder, h, ink_color, 6.0)
		draw_line(shoulder, h, Color("#8C8CA8"), 3.0)
		for k in range(8):
			var a = float(k) / 8.0 * TAU + idle_time * 2.0
			draw_line(h, h + Vector2(cos(a), sin(a)) * 11.0, ink_color, 4.0)
		draw_ring(h, 8.0, Color("#8C8CA8"), 2.5)

	# Swinging pendulum arm (pivot near the base, weight slides on the rod)
	var swing = sin(idle_time * 3.4) * 0.45 + rotation_angle * 2.0
	var pivot = Vector2(0, 72)
	var tip = pivot + Vector2(sin(swing), -cos(swing)) * 118.0
	draw_line(pivot, tip, ink_color, 6.0)
	draw_line(pivot, tip, gold_color, 3.0)
	var wpos = pivot.lerp(tip, 0.62)
	var wdir = (tip - pivot).normalized()
	var wperp = Vector2(-wdir.y, wdir.x)
	draw_poly(PackedVector2Array([
		wpos + wdir * 8 + wperp * 9, wpos + wdir * 8 - wperp * 9,
		wpos - wdir * 8 - wperp * 13, wpos - wdir * 8 + wperp * 13
	]), gold_color, 2.5)
	draw_ring(pivot, 5.0, gold_color, 2.0)

	# Single clock-face eye
	var eye = Vector2(0, -52)
	var glow = Color(neon_cyan.r, neon_cyan.g, neon_cyan.b, 0.25 + absf(sin(idle_time * 3.4)) * 0.2)
	draw_circle(eye, 22.0, glow)
	if current_pose == "miss":
		# Glitch: pink X and sparks
		draw_ring(eye, 15.0, Color("#2A0E1E"), 3.0)
		draw_line(eye + Vector2(-8, -8), eye + Vector2(8, 8), neon_pink, 4.0)
		draw_line(eye + Vector2(8, -8), eye + Vector2(-8, 8), neon_pink, 4.0)
		for k in range(5):
			var a = float(k) * 1.3 + idle_time * 20.0
			draw_line(eye + Vector2(cos(a), sin(a)) * 20.0, eye + Vector2(cos(a), sin(a)) * 28.0, hero_yellow, 2.0)
	elif is_blinking:
		draw_ring(eye, 15.0, suit_stripe, 3.0)
		draw_line(eye + Vector2(-12, 0), eye + Vector2(12, 0), neon_cyan, 3.0)
	else:
		draw_ring(eye, 15.0, paper_white, 3.0)
		for k in range(12):
			var a = float(k) / 12.0 * TAU
			draw_line(eye + Vector2(cos(a), sin(a)) * 11.0, eye + Vector2(cos(a), sin(a)) * 14.0, ink_color, 1.5)
		var look = Vector2.ZERO
		match current_pose:
			"left": look = Vector2(-3, 0)
			"right": look = Vector2(3, 0)
			"up": look = Vector2(0, -3)
			"down": look = Vector2(0, 3)
		var ha = idle_time * 1.2
		draw_line(eye + look, eye + look + Vector2(cos(ha), sin(ha)) * 9.0, ink_color, 2.5)
		draw_line(eye + look, eye + look + Vector2(cos(ha * 12.0), sin(ha * 12.0)) * 11.0, neon_pink, 1.5)
		draw_circle(eye + look, 2.5, neon_pink)

# ==============================================================================
# Straight Man's bus driver cap (he drives the Main Street bus)
# ==============================================================================
func draw_driver_cap() -> void:
	var crown = Rect2(-28, -84, 56, 20)
	draw_rect_rounded_top(crown, 10.0, suit_navy)
	draw_rect_rounded_outline(crown, 6.0, ink_color, 3.0)
	draw_rect(Rect2(-28, -70, 56, 6), suit_stripe)
	var brim = PackedVector2Array([Vector2(-30, -64), Vector2(30, -64), Vector2(24, -57), Vector2(-24, -57)])
	draw_poly(brim, ink_color, 2.0)
	draw_ring(Vector2(0, -75), 5.0, gold_color, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-9, -86), "BUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, gold_color)

# ==============================================================================
# RHYTHM FX (KeyStroked's own look)
# - The Echo: a ghostly copy floats behind the character and repeats their moves a beat
#   late. Clap's Echo appears as your combo grows; rivals' Echo shows when they play hard.
# - A spinning vinyl disc under their feet pulses on the beat.
# - Hits fire arrow chevrons in the lane's colour plus speaker sound waves and little notes.
# - Misses do a grey record-scratch and drop a sad flat note.
# - At full power, beat-count stickers (1, 2, 3, 4) pop up like rhythm tiles.
# ==============================================================================
const FX_MAX_PARTICLES: int = 90
const LANE_COLORS: Dictionary = {
	"left": Color("#C85A6E"), "down": Color("#4A7DBF"), "up": Color("#4E9A5E"), "right": Color("#D17B4A"),
}
var fx_particles: Array = []
var aura_flare: float = 0.0
var aura_time: float = 0.0
var note_timer: float = 0.0
var sticker_timer: float = 0.0
var sticker_count: int = 0
var last_pulse_beat: int = -1

# The Echo: a ghostly copy of the character that floats behind them and repeats
# their moves a moment later (call and response!). Fades in as power builds.
const ECHO_DELAY: float = 0.13
var is_echo: bool = false
var echo: Control = null

func _setup_echo() -> void:
	if is_echo or echo != null:
		return
	echo = Control.new()
	echo.set_script(get_script())
	echo.set("is_echo", true)
	echo.show_behind_parent = true
	echo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(echo)
	echo.modulate.a = 0.0

func _update_echo(delta: float) -> void:
	if is_echo:
		return
	if echo == null:
		_setup_echo()
	echo.set("character_type", character_type)
	echo.size = size
	echo.pivot_offset = Vector2(size.x / 2.0, size.y)
	var power := aura_power()
	var target := clampf((power - 0.3) / 0.9, 0.0, 1.0) * 0.5
	var col := aura_color().lightened(0.35)
	var alpha := move_toward(echo.modulate.a, target, delta * 1.5)
	echo.modulate = Color(col.r, col.g, col.b, alpha)
	echo.visible = alpha > 0.01
	var side := -1.0 if (global_position.x + size.x / 2.0) < 640.0 else 1.0
	echo.position = Vector2(side * 22.0 + sin(aura_time * 1.3) * 4.0, -38.0 + sin(aura_time * 2.1) * 5.0)
	echo.scale = Vector2(1.18, 1.18)

func _echo_repeat(dir: String) -> void:
	if echo == null or is_echo:
		return
	get_tree().create_timer(ECHO_DELAY).timeout.connect(func():
		if is_instance_valid(echo):
			if dir == "miss":
				echo.trigger_miss()
			else:
				echo.trigger_direction(dir))

func aura_color() -> Color:
	match character_type:
		"beats": return cardboard_light
		"straight_man": return straight_red
		"swing_queen": return Color("#7FA8FF")
		"syncopator": return Color("#7CFF6B")
		"twins": return rest_orange
		"metronome": return Color("#FF4D8D")
	return hero_yellow

func aura_power() -> float:
	var p := aura_flare
	if character_type == "clap":
		p += clampf((float(GameState.combo) - 4.0) / 20.0, 0.0, 1.2)
	elif character_type != "beats":
		p += 0.22 # ticked rivals always hum a little
	return clampf(p, 0.0, 1.6)

## 1.0 right on the beat, falling to 0 by the next one.
func beat_pulse() -> float:
	var b: float = aura_time * 1.6
	if Conductor.get("is_playing"):
		b = float(Conductor.get("current_beat_float"))
	var f := b - floorf(b)
	return pow(1.0 - f, 3.0)

func _fx_process(delta: float) -> void:
	aura_time += delta
	if is_echo:
		return
	_update_echo(delta)
	aura_flare = move_toward(aura_flare, 0.0, delta * 1.1)
	var power := aura_power()

	# Little music notes drifting up from the ring
	if power > 0.15:
		note_timer -= delta * (0.5 + power * 2.0)
		if note_timer <= 0.0:
			note_timer = 0.16
			var side := -1.0 if randf() < 0.5 else 1.0
			_spawn({"kind": "note", "pos": Vector2(side * randf_range(40, 70), randf_range(-10, 60)),
				"vel": Vector2(side * randf_range(5, 15), randf_range(-60, -95)), "life": randf_range(0.9, 1.4),
				"size": randf_range(0.7, 1.0) * (0.8 + power * 0.3), "rot": randf_range(-0.3, 0.3), "color": aura_color().lightened(0.25)})

	# Beat-count stickers at full power: 1, 2, 3, 4...
	if power > 0.85:
		sticker_timer -= delta
		if sticker_timer <= 0.0:
			sticker_timer = 0.6
			sticker_count = sticker_count % 4 + 1
			var side := -1.0 if sticker_count % 2 == 1 else 1.0
			_spawn({"kind": "sticker", "text": str(sticker_count),
				"pos": Vector2(side * randf_range(72, 92), randf_range(-60, 0)),
				"vel": Vector2(side * 10.0, -40.0), "life": 1.1, "size": 16.0 + power * 4.0,
				"rot": side * randf_range(0.08, 0.2), "color": aura_color()})

	var alive: Array = []
	for p in fx_particles:
		p["life"] -= delta
		if p["life"] <= 0.0:
			continue
		p["pos"] += p["vel"] * delta
		match p["kind"]:
			"chevron", "wave":
				p["vel"] *= pow(0.05, delta)
			"flat":
				p["vel"] += Vector2(0, 260) * delta
		alive.append(p)
	fx_particles = alive
	if power > 0.01 or not fx_particles.is_empty():
		queue_redraw()

func _spawn(p: Dictionary) -> void:
	if fx_particles.size() >= FX_MAX_PARTICLES:
		fx_particles.pop_front()
	p["max_life"] = p["life"]
	fx_particles.append(p)

func _dir_vec(dir: String) -> Vector2:
	match dir:
		"left": return Vector2(-1, 0)
		"right": return Vector2(1, 0)
		"down": return Vector2(0, 1)
	return Vector2(0, -1)

func fx_hit_burst(dir: String) -> void:
	if is_echo:
		return
	_echo_repeat(dir)
	aura_flare = minf(aura_flare + 0.45, 1.0)
	var d := _dir_vec(dir)
	var lane: Color = LANE_COLORS.get(dir, hero_yellow)
	var power := aura_power()
	var origin := d * 34.0 + Vector2(0, -10)
	# A train of arrow chevrons in the lane colour, more when powered up
	var count := 2 if power < 0.85 else 3
	for i in range(count):
		_spawn({"kind": "chevron", "pos": origin - d * float(i) * 16.0, "vel": d * (520.0 - float(i) * 60.0),
			"life": 0.32, "size": 13.0 - float(i), "dir": d, "color": lane})
	# Speaker sound waves
	for i in range(3):
		_spawn({"kind": "wave", "pos": origin, "vel": d * 40.0, "life": 0.28 + float(i) * 0.08,
			"size": 14.0 + float(i) * 10.0, "dir": d, "color": aura_color()})
	# A couple of notes scatter off the hit
	for i in range(2):
		var a := randf_range(-1.0, 1.0)
		_spawn({"kind": "note", "pos": origin + d * 30.0, "vel": (d.rotated(a) * randf_range(90, 150)) + Vector2(0, -40),
			"life": 0.6, "size": 0.8, "rot": randf_range(-0.4, 0.4), "color": lane.lightened(0.3)})

func fx_miss_puff() -> void:
	if is_echo:
		return
	_echo_repeat("miss")
	aura_flare = maxf(aura_flare - 0.4, 0.0)
	_spawn({"kind": "scratch", "pos": Vector2(0, -30), "vel": Vector2.ZERO, "life": 0.35, "size": 1.0, "color": Color(0.75, 0.75, 0.85)})
	_spawn({"kind": "flat", "pos": Vector2(randf_range(-20, 20), -80), "vel": Vector2(randf_range(-30, 30), -60),
		"life": 0.8, "size": 1.0, "rot": 0.0, "color": Color(0.6, 0.6, 0.72)})

## Vinyl disc under the character's feet: spins, and pulses on the beat.
func draw_power_aura() -> void:
	var power := aura_power()
	if power <= 0.15 or is_echo:
		return
	var col := aura_color()
	var a := clampf(power, 0.0, 1.0)
	var pulse := beat_pulse()
	var c := Vector2(0, 92)
	var r := Vector2(74.0, 17.0) * (1.0 + pulse * 0.06 * a)
	draw_ellipse_shape(c, r, Color(0.05, 0.05, 0.09, 0.75 * a))
	# Grooves
	for k in range(1, 5):
		var f := 1.0 - float(k) * 0.16
		var g := PackedVector2Array()
		for i in range(33):
			var ang := float(i) / 32.0 * TAU
			g.append(c + Vector2(cos(ang) * r.x * f, sin(ang) * r.y * f))
		draw_polyline(g, Color(1, 1, 1, 0.10 * a), 1.0)
	# Coloured label
	draw_ellipse_shape(c, r * 0.32, Color(col.r, col.g, col.b, 0.9 * a))
	draw_ellipse_shape(c, r * 0.07, Color(0.05, 0.05, 0.09, a))
	# Spinning highlight
	var spin := aura_time * 4.0
	var hl := Color(1, 1, 1, 0.35 * a)
	for k in [0.0, PI]:
		var ang: float = spin + k
		draw_line(c + Vector2(cos(ang) * r.x * 0.4, sin(ang) * r.y * 0.4), c + Vector2(cos(ang) * r.x * 0.92, sin(ang) * r.y * 0.92), hl, 2.0)
	# Rim glow on the beat
	var rim := PackedVector2Array()
	for i in range(41):
		var ang := float(i) / 40.0 * TAU
		rim.append(c + Vector2(cos(ang) * r.x, sin(ang) * r.y))
	draw_polyline(rim, Color(col.r, col.g, col.b, (0.35 + 0.6 * pulse) * a), 2.5)

func draw_note_shape(pos: Vector2, s: float, rot: float, col: Color) -> void:
	draw_set_transform(size / 2.0 + pos, rot, Vector2(s, s))
	var ink := Color(ink_color.r, ink_color.g, ink_color.b, col.a)
	draw_line(Vector2(5, 0), Vector2(5, -18), ink, 4.0)
	draw_line(Vector2(5, -18), Vector2(13, -11), ink, 4.0)
	draw_line(Vector2(5, 0), Vector2(5, -18), col, 2.0)
	draw_line(Vector2(5, -18), Vector2(12, -12), col, 2.0)
	draw_ellipse_shape(Vector2(0, 1), Vector2(7.5, 5.5), ink)
	draw_ellipse_shape(Vector2(0, 1), Vector2(5.5, 3.8), col)
	draw_set_transform(size / 2.0, 0.0, Vector2.ONE)

## Particles drawn in front, in un-squashed local space around the character's centre.
func draw_fx_particles() -> void:
	var font = ThemeDB.fallback_font
	for p in fx_particles:
		var t: float = p["life"] / p["max_life"] # 1 -> 0
		var col: Color = p["color"]
		var pos: Vector2 = p["pos"]
		match p["kind"]:
			"note":
				col.a = minf(1.0, t * 1.6)
				draw_note_shape(pos + Vector2(sin(aura_time * 6.0 + pos.y * 0.1) * 3.0, 0), p["size"], p["rot"], col)
			"chevron":
				var d: Vector2 = p["dir"]
				var perp := Vector2(-d.y, d.x)
				var s: float = p["size"]
				var pts := PackedVector2Array([pos - d * s * 0.6 + perp * s, pos + d * s * 0.6, pos - d * s * 0.6 - perp * s])
				draw_polyline(pts, Color(ink_color.r, ink_color.g, ink_color.b, t), 9.0)
				col.a = t
				draw_polyline(pts, col, 5.5)
			"wave":
				var d: Vector2 = p["dir"]
				var grow: float = p["size"] + (1.0 - t) * 30.0
				col.a = t * 0.9
				draw_arc(pos, grow, d.angle() - 0.7, d.angle() + 0.7, 12, col, 3.0)
			"scratch":
				col.a = t
				var zig := PackedVector2Array()
				for i in range(8):
					zig.append(pos + Vector2(-36 + i * 10, (6.0 if i % 2 == 0 else -6.0) * (0.5 + t)))
				draw_polyline(zig, Color(ink_color.r, ink_color.g, ink_color.b, t), 6.0)
				draw_polyline(zig, col, 3.0)
			"flat":
				col.a = t
				p["rot"] = float(p["rot"]) + 0.08
				draw_set_transform(size / 2.0 + pos, p["rot"], Vector2.ONE)
				var ink := Color(ink_color.r, ink_color.g, ink_color.b, t)
				draw_line(Vector2(-4, -16), Vector2(-4, 6), ink, 4.0)
				draw_arc(Vector2(0, 2), 5.0, -PI / 2.0, PI / 2.0, 10, ink, 4.0)
				draw_line(Vector2(-4, -16), Vector2(-4, 6), col, 2.0)
				draw_arc(Vector2(0, 2), 5.0, -PI / 2.0, PI / 2.0, 10, col, 2.0)
				draw_set_transform(size / 2.0, 0.0, Vector2.ONE)
			"sticker":
				# A little rhythm-tile sticker with the beat count on it
				var pop := 1.0 + maxf(0.0, (t - 0.85) / 0.15) * 0.4
				var alpha := minf(1.0, t * 2.5)
				var s: float = p["size"]
				draw_set_transform(size / 2.0 + pos, p["rot"], Vector2(pop, pop))
				var rect := Rect2(-s, -s, s * 2.0, s * 2.0)
				draw_rect_rounded(Rect2(rect.position + Vector2(2, 3), rect.size), 6.0, Color(0, 0, 0, 0.3 * alpha))
				draw_rect_rounded(rect, 6.0, Color(paper_white.r, paper_white.g, paper_white.b, alpha))
				draw_rect_rounded_outline(rect, 6.0, Color(col.r, col.g, col.b, alpha), 3.0)
				draw_rect(Rect2(-s, -s, s * 2.0, 5.0), Color(col.r, col.g, col.b, alpha))
				var fs := int(s * 1.4)
				var tw: float = font.get_string_size(p["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				draw_string(font, Vector2(-tw / 2.0, s * 0.55), p["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(ink_color.r, ink_color.g, ink_color.b, alpha))
				draw_set_transform(size / 2.0, 0.0, Vector2.ONE)
