extends Control

var anim_time: float = 0.0

var night_sky_top: Color = Color("#261C4E")
var night_sky_bot: Color = Color("#3D2B68")
var dark_navy: Color = Color("#131322")
var mid_navy: Color = Color("#1E1E34")
var light_navy: Color = Color("#2B2B48")
var hero_yellow: Color = Color("#F7D117")
var paper_white: Color = Color("#FFF8E7")
var neon_pink: Color = Color("#FF4D8D")
var neon_cyan: Color = Color("#00E5FF")
var wood_brown: Color = Color("#8B5E3C")

# Starfield & floating note seeds
var star_coords: Array[Vector2] = []
var star_phases: Array[float] = []

# Story: rivals you've already beaten cheer from the front of the stage.
const CROWD_FANS: Array = [
	{"level": "tutorial", "name": "Beats", "color": Color("#C49A45")},
	{"level": "week1", "name": "Straight Man", "color": Color("#C85A6E")},
	{"level": "week2", "name": "Swing Queen", "color": Color("#4A7DBF")},
	{"level": "week3", "name": "Syncopator", "color": Color("#4E9A5E")},
	{"level": "week4", "name": "Tri & Quad", "color": Color("#D17B4A")},
]
const LEVEL_ORDER: Array = ["tutorial", "week1", "week2", "week3", "week4", "finale"]
var crowd: Array = []

func _ready() -> void:
	# Generate deterministic star coordinates
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(32):
		star_coords.append(Vector2(rng.randf_range(30, 1250), rng.randf_range(25, 260)))
		star_phases.append(rng.randf_range(0.0, TAU))
	build_crowd()

func build_crowd() -> void:
	crowd.clear()
	var current: String = GameState.selected_level_id
	var cur_idx: int = LEVEL_ORDER.find(current)
	for fan in CROWD_FANS:
		var idx: int = LEVEL_ORDER.find(fan["level"])
		# Only rivals from earlier stages that you've beaten. Beats always tags along after the tutorial.
		if idx < 0 or cur_idx < 0 or idx >= cur_idx:
			continue
		if fan["level"] == "tutorial" or GameState.completed_levels.has(fan["level"]):
			crowd.append(fan)

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y

	# 1. Sky Gradient Fill (Paper-cut Night Sky)
	draw_sky_gradient(w, h)

	# 2. Twinkling Comic Stars & Drifting Musical Notes
	draw_celestial_sky(w, h)

	# 3. Stylized Paper Crescent Moon with Crater Dots
	draw_paper_moon(Vector2(w - 180, 100))

	# 4. Giant Metronome Clock Tower in Center Background (Dynamic Swinging Pendulum!)
	draw_metronome_tower(w, h)

	# 5. Distant City Skyline (Layer 1) with Antennas & Water Towers
	draw_distant_skyline(w, h)

	# 6. Near City Skyline (Layer 2) with Lit Windows & Neon Signs
	draw_near_skyline(w, h)

	# 7. Street Floor / Rhythm Stage with Planks & Dash Lines
	draw_stage_floor(w, h)

	# 8. Warm Beat Spotlights illuminating Player and Opponent
	draw_stage_spotlights(w, h)

	# 9. Beaten rivals cheering at the front of the stage
	draw_crowd(w, h)

func draw_sky_gradient(w: float, h: float) -> void:
	# Subtle 2-tone sky band
	draw_rect(Rect2(0, 0, w, h * 0.45), night_sky_top)
	draw_rect(Rect2(0, h * 0.45, w, h * 0.55), night_sky_bot)

func draw_celestial_sky(w: float, _h: float) -> void:
	# Twinkling 4-point cartoon stars
	for i in range(star_coords.size()):
		var base_pos = star_coords[i]
		var phase = star_phases[i]
		var twinkle = 0.5 + sin(anim_time * 2.5 + phase) * 0.45
		var star_r = (3.5 + sin(anim_time * 3.0 + phase) * 1.5) * twinkle
		var star_col = paper_white
		star_col.a = twinkle

		if star_r > 1.0:
			draw_four_point_star(base_pos, star_r, star_col)

	# Floating drifting musical notes across sky (doodle charm)
	var notes = ["♪", "♫", "♩"]
	for j in range(4):
		var drift_x = fmod(80.0 + (j * 300.0) + (anim_time * 18.0), w + 60.0) - 30.0
		var drift_y = 60.0 + (j * 38.0) + sin(anim_time * 2.0 + j) * 12.0
		var n_col = paper_white.lerp(hero_yellow, 0.4)
		n_col.a = 0.45 + sin(anim_time * 2.5 + j) * 0.25
		draw_string(ThemeDB.fallback_font, Vector2(drift_x, drift_y), notes[j % notes.size()], HORIZONTAL_ALIGNMENT_CENTER, -1, 16, n_col)

func draw_four_point_star(pos: Vector2, r: float, col: Color) -> void:
	var r_in = r * 0.28
	var pts = PackedVector2Array([
		pos + Vector2(0, -r),
		pos + Vector2(r_in, -r_in),
		pos + Vector2(r, 0),
		pos + Vector2(r_in, r_in),
		pos + Vector2(0, r),
		pos + Vector2(-r_in, r_in),
		pos + Vector2(-r, 0),
		pos + Vector2(-r_in, -r_in)
	])
	draw_colored_polygon(pts, col)

func draw_paper_moon(pos: Vector2) -> void:
	var moon_r = 38.0

	# Moon Glow Halo
	draw_circle(pos, moon_r + 10.0, Color(hero_yellow.r, hero_yellow.g, hero_yellow.b, 0.15))

	# Moon Base Circle
	draw_circle(pos + Vector2(4, 5), moon_r, Color(0.1, 0.1, 0.15, 0.3))
	draw_circle(pos, moon_r, paper_white)
	draw_arc(pos, moon_r, 0, TAU, 32, dark_navy, 3.0)

	# Crater Doodles
	draw_circle(pos + Vector2(-12, -8), 6.5, hero_yellow.lerp(paper_white, 0.5))
	draw_arc(pos + Vector2(-12, -8), 6.5, 0, TAU, 12, dark_navy, 1.8)

	draw_circle(pos + Vector2(10, 12), 8.0, hero_yellow.lerp(paper_white, 0.5))
	draw_arc(pos + Vector2(10, 12), 8.0, 0, TAU, 14, dark_navy, 1.8)

	draw_circle(pos + Vector2(-6, 16), 4.5, hero_yellow.lerp(paper_white, 0.5))
	draw_arc(pos + Vector2(-6, 16), 4.5, 0, TAU, 10, dark_navy, 1.5)

func draw_metronome_tower(w: float, h: float) -> void:
	var tower_x = w / 2.0
	var tower_w = 150.0

	# Tower Shadow
	draw_rect(Rect2(tower_x - (tower_w / 2.0) + 6, 75, tower_w, h), Color(0.08, 0.08, 0.14, 0.35))

	# Far Tower Silhouette Body
	var tower_rect = Rect2(tower_x - (tower_w / 2.0), 70, tower_w, h)
	draw_rect(tower_rect, mid_navy)

	# Tower Brickwork / Masonry texture (subtle horizontal seam lines)
	for ty in range(85, int(h) - 80, 22):
		draw_line(Vector2(tower_rect.position.x + 8, ty), Vector2(tower_rect.position.x + tower_w - 8, ty), light_navy, 1.5)

	# Tower Peak Roof Triangle
	var peak_pts = PackedVector2Array([
		Vector2(tower_x - (tower_w / 2.0), 70),
		Vector2(tower_x + (tower_w / 2.0), 70),
		Vector2(tower_x, 10)
	])
	draw_colored_polygon(peak_pts, mid_navy)
	draw_polyline(peak_pts + PackedVector2Array([peak_pts[0]]), dark_navy, 2.5)

	# Tower Peak Beacon Light (Blinks red on top of steeple)
	var beacon_alpha = 0.5 + sin(anim_time * 5.0) * 0.5
	var beacon_col = Color(1.0, 0.2, 0.2, beacon_alpha)
	draw_circle(Vector2(tower_x, 8), 5.0, beacon_col)
	draw_circle(Vector2(tower_x, 8), 2.0, paper_white)

	# Giant Clock Face on Tower
	var clock_pos = Vector2(tower_x, 125)
	draw_circle(clock_pos, 32.0, dark_navy)
	draw_circle(clock_pos, 28.0, hero_yellow.lerp(paper_white, 0.2))
	draw_arc(clock_pos, 28.0, 0, TAU, 28, dark_navy, 3.0)

	# Clock Roman / Tick marks
	for a_idx in range(12):
		var a = (float(a_idx) / 12.0) * TAU
		var p_out = clock_pos + Vector2(cos(a), sin(a)) * 24.0
		var p_in = clock_pos + Vector2(cos(a), sin(a)) * 18.0
		draw_line(p_in, p_out, dark_navy, 2.0)

	# Clock Hands
	draw_line(clock_pos, clock_pos + Vector2(10, -12), dark_navy, 3.0) # Minute
	draw_line(clock_pos, clock_pos + Vector2(-8, 5), dark_navy, 4.0) # Hour
	draw_circle(clock_pos, 3.5, dark_navy)

	# Dynamic Swinging Metronome Pendulum Arm!
	# Rocks smoothly to the music/tempo
	var pendulum_angle = sin(anim_time * 3.4) * 0.42
	var pivot_pt = Vector2(tower_x, 160)
	var arm_len = 85.0
	var bob_pos = pivot_pt + Vector2(sin(pendulum_angle), cos(pendulum_angle)) * arm_len

	# Pendulum slot cut-out in tower
	draw_rect_rounded(Rect2(tower_x - 42, 160, 84, 100), 12.0, dark_navy)

	# Swinging metallic arm
	draw_line(pivot_pt, bob_pos, hero_yellow.lerp(paper_white, 0.4), 5.0)
	draw_line(pivot_pt, bob_pos, dark_navy, 1.5)

	# Metronome Bob Weight with indicator notch
	draw_circle(bob_pos + Vector2(2, 3), 14.0, Color(0.1, 0.1, 0.15, 0.3))
	draw_circle(bob_pos, 14.0, hero_yellow)
	draw_arc(bob_pos, 14.0, 0, TAU, 20, dark_navy, 3.0)
	draw_circle(bob_pos, 4.0, paper_white)

func draw_distant_skyline(_w: float, h: float) -> void:
	var buildings_far = [
		Rect2(30, 210, 120, h),
		Rect2(170, 180, 90, h),
		Rect2(280, 230, 100, h),
		Rect2(910, 190, 110, h),
		Rect2(1040, 170, 95, h),
		Rect2(1155, 220, 100, h),
	]

	for b in buildings_far:
		draw_rect(b, mid_navy)

	# Rooftop Antennas with blinking aviation red beacon lights
	draw_antenna(Vector2(215, 180), 38.0)
	draw_antenna(Vector2(1085, 170), 45.0)

	# Rooftop Water Tower on building (wood texture)
	draw_water_tower(Vector2(330, 230))

func draw_antenna(base: Vector2, height: float) -> void:
	var tip = base - Vector2(0, height)
	# Mast line
	draw_line(base, tip, light_navy, 2.5)
	# Crossbars
	draw_line(tip + Vector2(-8, 12), tip + Vector2(8, 12), light_navy, 2.0)
	draw_line(tip + Vector2(-12, 22), tip + Vector2(12, 22), light_navy, 2.0)

	# Blinking red beacon tip
	var blink = 0.5 + sin(anim_time * 6.0 + base.x) * 0.5
	var b_col = Color(1.0, 0.25, 0.25, blink)
	draw_circle(tip, 3.5, b_col)

func draw_water_tower(base: Vector2) -> void:
	var tw = 32.0
	var th = 34.0
	var t_pos = base - Vector2(tw / 2.0, th + 18)

	# Steel stilt legs
	draw_line(base + Vector2(-12, 0), t_pos + Vector2(4, th), mid_navy.darkened(0.2), 2.5)
	draw_line(base + Vector2(12, 0), t_pos + Vector2(tw - 4, th), mid_navy.darkened(0.2), 2.5)
	draw_line(base + Vector2(-12, 0), t_pos + Vector2(tw - 4, th), mid_navy.darkened(0.2), 1.5)
	draw_line(base + Vector2(12, 0), t_pos + Vector2(4, th), mid_navy.darkened(0.2), 1.5)

	# Wooden Barrel Body
	var barrel_rect = Rect2(t_pos, Vector2(tw, th))
	draw_rect_rounded(barrel_rect, 4.0, wood_brown)

	# Wooden Staves texture (vertical lines)
	for sx in range(int(t_pos.x) + 6, int(t_pos.x + tw) - 2, 7):
		draw_line(Vector2(sx, t_pos.y), Vector2(sx, t_pos.y + th), wood_brown.darkened(0.25), 1.5)

	# Iron Hoops (horizontal bands)
	draw_line(Vector2(t_pos.x, t_pos.y + 8), Vector2(t_pos.x + tw, t_pos.y + 8), dark_navy, 2.0)
	draw_line(Vector2(t_pos.x, t_pos.y + th - 8), Vector2(t_pos.x + tw, t_pos.y + th - 8), dark_navy, 2.0)

	# Conical Roof
	var roof_pts = PackedVector2Array([
		Vector2(t_pos.x - 2, t_pos.y),
		Vector2(t_pos.x + tw + 2, t_pos.y),
		Vector2(t_pos.x + (tw / 2.0), t_pos.y - 12)
	])
	draw_colored_polygon(roof_pts, dark_navy)

func draw_near_skyline(_w: float, h: float) -> void:
	var buildings_near = [
		Rect2(10, 300, 160, h),
		Rect2(180, 280, 120, h),
		Rect2(970, 270, 130, h),
		Rect2(1110, 295, 160, h),
	]

	for b in buildings_near:
		# Paper drop shadow
		draw_rect(Rect2(b.position + Vector2(6, 6), b.size), Color(0.06, 0.06, 0.10, 0.45))
		# Building Body
		draw_rect(b, dark_navy)

		# Warm lit windows with window frame crossbars
		for wy in range(int(b.position.y) + 32, int(h) - 75, 42):
			for wx in range(int(b.position.x) + 20, int(b.position.x + b.size.x) - 24, 28):
				if (wx * 3 + wy * 7) % 5 != 0:
					var win_rect = Rect2(wx, wy, 14, 18)
					# Cozy warm window glow
					draw_rect_rounded(win_rect, 2.0, hero_yellow.lerp(paper_white, 0.35))
					# Window crossbar pane
					draw_line(Vector2(wx + 7, wy), Vector2(wx + 7, wy + 18), dark_navy, 1.2)
					draw_line(Vector2(wx, wy + 9), Vector2(wx + 14, wy + 9), dark_navy, 1.2)

	# Animated Neon Signs on Rooftops!
	# Left: "BEAT" in neon cyan
	draw_neon_sign(Vector2(75, 292), "BEAT", neon_cyan)
	# Right: "RHYTHM" in neon pink
	draw_neon_sign(Vector2(1020, 262), "JAM", neon_pink)

func draw_neon_sign(pos: Vector2, text: String, col: Color) -> void:
	var font = ThemeDB.fallback_font
	var flicker = 0.75 + sin(anim_time * 8.0 + pos.x) * 0.25
	var neon_col = col
	neon_col.a = flicker

	var str_sz = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
	var bg_rect = Rect2(pos.x - 6, pos.y - 14, str_sz.x + 12, 18)

	# Sign scaffolding frame
	draw_rect_rounded(bg_rect, 3.0, mid_navy)
	draw_rect_rounded_outline(bg_rect, 3.0, neon_col, 1.8)

	# Neon glow string
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, neon_col)

func draw_stage_floor(w: float, h: float) -> void:
	var stage_h = 85.0
	var stage_rect = Rect2(0, h - stage_h, w, stage_h)

	# Stage Base
	draw_rect(stage_rect, dark_navy)

	# Golden Glowing Stage Marquee Edge
	draw_line(Vector2(0, h - stage_h), Vector2(w, h - stage_h), hero_yellow, 3.5)
	draw_line(Vector2(0, h - stage_h + 3), Vector2(w, h - stage_h + 3), dark_navy.lerp(hero_yellow, 0.4), 1.5)

	# Dashed Rhythm Road lines / Stage Planks
	for rx in range(15, int(w), 48):
		draw_line(Vector2(rx, h - 42), Vector2(rx + 28, h - 42), paper_white.lerp(dark_navy, 0.65), 3.0)

	# Stage floor cross-hatch stipples
	for px in range(20, int(w), 60):
		draw_line(Vector2(px, h - 18), Vector2(px + 8, h - 18), light_navy, 1.5)

func draw_stage_spotlights(_w: float, h: float) -> void:
	# Warm spotlight cones aimed down at Left (Opponent) and Right (Player)
	var left_spot_x = 150.0
	var right_spot_x = 1130.0
	var spot_pulse = 0.12 + sin(anim_time * 3.4) * 0.04

	var spot_col = hero_yellow
	spot_col.a = spot_pulse

	# Left Spotlight Cone (Opponent)
	var left_cone = PackedVector2Array([
		Vector2(left_spot_x - 30, 0),
		Vector2(left_spot_x + 30, 0),
		Vector2(left_spot_x + 120, h - 85),
		Vector2(left_spot_x - 120, h - 85)
	])
	draw_colored_polygon(left_cone, spot_col)

	# Right Spotlight Cone (Player)
	var right_cone = PackedVector2Array([
		Vector2(right_spot_x - 30, 0),
		Vector2(right_spot_x + 30, 0),
		Vector2(right_spot_x + 120, h - 85),
		Vector2(right_spot_x - 120, h - 85)
	])
	draw_colored_polygon(right_cone, spot_col)

	# Floor Spotlight Ellipses
	var floor_col = hero_yellow
	floor_col.a = spot_pulse * 1.5
	draw_spotlight_ellipse(Vector2(left_spot_x, h - 80), Vector2(95, 22), floor_col)
	draw_spotlight_ellipse(Vector2(right_spot_x, h - 80), Vector2(95, 22), floor_col)

func draw_spotlight_ellipse(center: Vector2, radius: Vector2, col: Color) -> void:
	var pts = PackedVector2Array()
	var segs = 20
	for i in range(segs):
		var a = (float(i) / float(segs)) * TAU
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(pts, col)

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

func draw_crowd(w: float, h: float) -> void:
	if crowd.is_empty():
		return
	var font = ThemeDB.fallback_font
	var spacing: float = 120.0
	var start_x: float = w / 2.0 - spacing * float(crowd.size() - 1) / 2.0
	for i in range(crowd.size()):
		var fan: Dictionary = crowd[i]
		var col: Color = fan["color"]
		var bob: float = absf(sin(anim_time * 3.4 + float(i) * 1.3)) * 7.0
		var base := Vector2(start_x + spacing * float(i), h - 8.0)
		var head := base + Vector2(0, -44.0 - bob)

		# Body (peeking up from below the stage edge)
		var body := Rect2(base.x - 20, base.y - 26 - bob, 40, 34)
		draw_rect_rounded(body, 10.0, col.darkened(0.25))
		draw_rect_rounded_outline(body, 10.0, dark_navy, 2.5)

		# Waving noodle arms
		var wave: float = sin(anim_time * 6.0 + float(i)) * 8.0
		draw_line(base + Vector2(-18, -20 - bob), head + Vector2(-30, -18 + wave), dark_navy, 4.0)
		draw_line(base + Vector2(18, -20 - bob), head + Vector2(30, -18 - wave), dark_navy, 4.0)

		# Head with happy face
		draw_circle(head, 20.0, col)
		draw_arc(head, 20.0, 0, TAU, 24, dark_navy, 2.5)
		draw_circle(head + Vector2(-7, -3), 2.6, dark_navy)
		draw_circle(head + Vector2(7, -3), 2.6, dark_navy)
		draw_arc(head + Vector2(0, 4), 7.0, 0.2, PI - 0.2, 10, dark_navy, 2.2)

		# Name tag
		var name_text: String = fan["name"]
		var sz = font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
		draw_string(font, Vector2(base.x - sz.x / 2.0, base.y + 4), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, paper_white)
