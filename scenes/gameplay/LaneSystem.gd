extends Control

signal hit_judged(rating: String, offset_ms: float, direction: String)
signal opponent_hit(direction: String)

const ARROW_PROMPT_SCENE = preload("res://scenes/gameplay/ArrowPrompt.tscn")

const LANE_DIRS = ["left", "down", "up", "right"]
const LANE_COLORS = {
	"left": Color("#C85A6E"),
	"down": Color("#4A7DBF"),
	"up": Color("#4E9A5E"),
	"right": Color("#D17B4A")
}

const SPAWN_Y: float = 60.0
const JUDGMENT_Y: float = 460.0
const SCROLL_DISTANCE: float = JUDGMENT_Y - SPAWN_Y # 400px
const APPROACH_BEATS: float = 3.0 # Arrow appears 3 beats before its hit time

var lane_x_positions: Array[float] = [360.0, 480.0, 600.0, 720.0]
var receptor_scales: Dictionary = {"left": 1.0, "down": 1.0, "up": 1.0, "right": 1.0}
var receptor_press: Dictionary = {"left": false, "down": false, "up": false, "right": false}

var active_prompts: Array = []
var ink_color: Color = Color("#1B1B2F")
var paper_white: Color = Color("#FFF8E7")
var hero_yellow: Color = Color("#F7D117")

func _ready() -> void:
	custom_minimum_size = Vector2(500, 540)
	# Center the lanes around x = size.x / 2
	update_lane_positions()

func update_lane_positions() -> void:
	var center_x = 640.0
	var spacing = 95.0
	lane_x_positions = [
		center_x - (spacing * 1.5),
		center_x - (spacing * 0.5),
		center_x + (spacing * 0.5),
		center_x + (spacing * 1.5)
	]

func spawn_prompt(beat_val: float, dir: String, for_player: bool) -> void:
	var prompt = ARROW_PROMPT_SCENE.instantiate()
	add_child(prompt)
	prompt.setup(beat_val, dir, for_player)

	var lane_idx = LANE_DIRS.find(dir)
	var lx = lane_x_positions[lane_idx] if lane_idx >= 0 else 640.0
	prompt.position = Vector2(lx - 32.0, SPAWN_Y)
	active_prompts.append(prompt)

func clear_all() -> void:
	for p in active_prompts:
		if is_instance_valid(p):
			p.queue_free()
	active_prompts.clear()

func handle_input_press(dir: String) -> void:
	trigger_receptor_pulse(dir, 1.25, true)

	var cur_beat = Conductor.current_beat_float
	var best_prompt = null
	var min_abs_ms: float = 999999.0
	var signed_ms: float = 0.0

	# Search for closest unhit prompt in this direction for player
	for p in active_prompts:
		if is_instance_valid(p) and p.is_play_phase and not p.is_hit and not p.is_missed:
			if p.direction == dir:
				var diff_beats = cur_beat - p.target_beat
				var offset_ms = diff_beats * Conductor.crotchet * 1000.0
				if absf(offset_ms) < min_abs_ms:
					min_abs_ms = absf(offset_ms)
					signed_ms = offset_ms
					best_prompt = p

	# Timing windows: Perfect <= 45ms, Good <= 90ms
	if best_prompt != null and min_abs_ms <= 90.0:
		var rating = "Perfect" if min_abs_ms <= 45.0 else "Good"
		best_prompt.pop_hit(rating)
		hit_judged.emit(rating, signed_ms, dir)
		Conductor.play_hit(dir)
	else:
		# Stray press or wrong lane
		hit_judged.emit("Stray", 0.0, dir)
		Conductor.play_hit(dir)

func handle_input_release(dir: String) -> void:
	receptor_press[dir] = false
	queue_redraw()

func trigger_receptor_pulse(dir: String, scale_val: float = 1.2, is_pressed: bool = false) -> void:
	receptor_scales[dir] = scale_val
	receptor_press[dir] = is_pressed
	var tween = create_tween()
	tween.tween_property(self, "receptor_scales:" + dir, 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	queue_redraw()

func pulse_beat() -> void:
	for d in LANE_DIRS:
		if not receptor_press[d]:
			trigger_receptor_pulse(d, 1.06, false)

func update_frame(current_beat_float: float) -> void:
	var to_remove = []

	for p in active_prompts:
		if not is_instance_valid(p):
			to_remove.append(p)
			continue

		if p.is_hit or p.is_missed:
			continue

		# Scroll math: target_beat lands at JUDGMENT_Y
		# At (target_beat - APPROACH_BEATS), y = SPAWN_Y
		var beats_until_target = p.target_beat - current_beat_float
		var progress = 1.0 - (beats_until_target / APPROACH_BEATS)
		var current_y = SPAWN_Y + (progress * SCROLL_DISTANCE)

		var lane_idx = LANE_DIRS.find(p.direction)
		var lx = lane_x_positions[lane_idx] if lane_idx >= 0 else 640.0
		p.position = Vector2(lx - 32.0, current_y)

		# Listen phase auto-play when prompt arrives at judgment line
		if not p.is_play_phase:
			if beats_until_target <= 0.05 and not p.has_played_listen:
				p.has_played_listen = true
				if p.direction != "rest":
					p.pop_hit("Perfect")
					trigger_receptor_pulse(p.direction, 1.25, false)
					Conductor.play_hit(p.direction)
					opponent_hit.emit(p.direction)
				else:
					p.pop_hit("Perfect")
		else:
			# Play phase: check for late miss if expired (> 90ms late)
			var late_sec = -beats_until_target * Conductor.crotchet
			if late_sec * 1000.0 > 90.0:
				if p.direction != "rest":
					p.pop_miss()
					hit_judged.emit("Miss", late_sec * 1000.0, p.direction)
					Conductor.play_miss()
				else:
					# Player successfully ignored rest tile!
					p.pop_hit("Perfect")

	for r in to_remove:
		active_prompts.erase(r)

	queue_redraw()

func _draw() -> void:
	# 1. Lane track vertical guide lines
	for i in range(LANE_DIRS.size()):
		var lx = lane_x_positions[i]
		var col = LANE_COLORS[LANE_DIRS[i]].lerp(Color("#1B1B2F"), 0.75)
		draw_line(Vector2(lx, SPAWN_Y - 20), Vector2(lx, JUDGMENT_Y + 40), col, 2.0)

	# 2. Judgment horizontal line
	draw_line(Vector2(lane_x_positions[0] - 60, JUDGMENT_Y), Vector2(lane_x_positions[3] + 60, JUDGMENT_Y), hero_yellow.lerp(paper_white, 0.4), 3.0)

	# 3. Receptor targets at judgment line
	for i in range(LANE_DIRS.size()):
		var dir = LANE_DIRS[i]
		var lx = lane_x_positions[i]
		var center = Vector2(lx, JUDGMENT_Y)
		var s = receptor_scales.get(dir, 1.0)
		var is_p = receptor_press.get(dir, false)
		var base_col = LANE_COLORS[dir]

		draw_set_transform(center * (1.0 - s), 0.0, Vector2(s, s))

		# Receptor shadow
		draw_circle(center + Vector2(3, 3), 32.0, Color(0.1, 0.1, 0.15, 0.3))

		# Receptor body
		var body_col = base_col.lerp(paper_white, 0.3) if is_p else base_col.lerp(ink_color, 0.5)
		draw_circle(center, 30.0, body_col)
		draw_arc(center, 30.0, 0, TAU, 24, ink_color, 3.5)

		# Receptor outline arrow
		draw_arrow_outline(center, dir, paper_white)

	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func draw_arrow_outline(center: Vector2, dir: String, col: Color) -> void:
	var angle = 0.0
	match dir:
		"left": angle = PI
		"down": angle = PI / 2.0
		"up": angle = -PI / 2.0
		"right": angle = 0.0

	var points = PackedVector2Array([
		Vector2(14, 0),
		Vector2(-3, -12),
		Vector2(-3, -5),
		Vector2(-14, -5),
		Vector2(-14, 5),
		Vector2(-3, 5),
		Vector2(-3, 12)
	])

	var rotated_pts = PackedVector2Array()
	for pt in points:
		rotated_pts.append(center + pt.rotated(angle))

	draw_polyline(rotated_pts + PackedVector2Array([rotated_pts[0]]), col, 2.5)

