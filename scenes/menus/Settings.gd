extends Control
## Settings screen: audio/input calibration.
## Tap test plays a 120 BPM click track through the Conductor (clicks are baked
## into the audio so they are sample-accurate), collects 16 taps, and suggests
## the median offset. Positive offset = player taps late.

const TEST_BPM: float = 120.0
const COUNT_IN_BEATS: int = 4
const TAP_BEATS: int = 16
const MAX_TAP_ERROR_MS: float = 200.0
const UNEVEN_STDDEV_MS: float = 35.0
const MIN_VALID_TAPS: int = 8
const OFFSET_LIMIT_MS: float = 300.0
const MIX_RATE: int = 44100

const TAP_ACTIONS: Array[String] = ["arrow_left", "arrow_down", "arrow_up", "arrow_right"]

var ink_color: Color = Color("#1B1B2F")
var paper_white: Color = Color("#FFF8E7")
var hero_yellow: Color = Color("#F7D117")
var good_green: Color = Color("#38B000")
var warn_red: Color = Color("#FF4D6D")

var offset_value_label: Label
var offset_hint_label: Label
var test_status_label: Label
var result_label: Label
var btn_start: Button
var btn_apply: Button
var btn_back: Button
var btn_cue: Button
var beat_dots: Control

var test_running: bool = false
var saved_offset_ms: float = 0.0 # calibration restored after the test
var tap_offsets: Array[float] = []
var ignored_taps: int = 0
var current_beat: int = -1
var pending_result_ms: float = 0.0
var has_result: bool = false
var tapped_beats: Dictionary = {} # beat index -> offset ms, for dot colouring

func _ready() -> void:
	build_ui()
	Conductor.beat_hit.connect(_on_beat_hit)
	Conductor.song_finished.connect(_on_test_audio_finished)
	refresh_offset_display()

func _exit_tree() -> void:
	if test_running:
		stop_test(false)

# ---------------------------------------------------------------- UI ----

func build_ui() -> void:
	var root = VBoxContainer.new()
	root.anchor_left = 0.5
	root.anchor_right = 0.5
	root.anchor_top = 0.5
	root.anchor_bottom = 0.5
	root.offset_left = -380.0
	root.offset_right = 380.0
	root.offset_top = -350.0
	root.offset_bottom = 350.0
	root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var title = make_label("SETTINGS", 44, hero_yellow)
	title.add_theme_color_override("font_outline_color", ink_color)
	title.add_theme_constant_override("outline_size", 12)
	root.add_child(title)

	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", make_style(paper_white, 14, 4, 8))
	root.add_child(card)

	var margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	card.add_child(margin)

	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	col.add_child(make_label("AUDIO / INPUT OFFSET", 20, ink_color))
	offset_value_label = make_label("+0 ms", 34, ink_color)
	col.add_child(offset_value_label)
	offset_hint_label = make_label("", 14, ink_color.lightened(0.3))
	col.add_child(offset_hint_label)

	var adj_row = HBoxContainer.new()
	adj_row.alignment = BoxContainer.ALIGNMENT_CENTER
	adj_row.add_theme_constant_override("separation", 10)
	col.add_child(adj_row)
	for step in [-5, -1, 1, 5]:
		var b = make_button(("%+d" % step), Vector2(70, 40), 18)
		b.pressed.connect(_on_adjust_pressed.bind(float(step)))
		adj_row.add_child(b)
	var b_reset = make_button("RESET", Vector2(100, 40), 18)
	b_reset.pressed.connect(_on_reset_pressed)
	adj_row.add_child(b_reset)

	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 18)
	col.add_child(sep)

	col.add_child(make_label("TAP TEST", 20, ink_color))
	test_status_label = make_label("Press START, listen to 4 count-in clicks,\nthen tap any arrow key (or Space) on the next 16 clicks.", 15, ink_color)
	col.add_child(test_status_label)

	beat_dots = Control.new()
	beat_dots.custom_minimum_size = Vector2(700, 40)
	beat_dots.draw.connect(_draw_beat_dots)
	col.add_child(beat_dots)

	result_label = make_label("", 16, ink_color)
	col.add_child(result_label)

	var test_row = HBoxContainer.new()
	test_row.alignment = BoxContainer.ALIGNMENT_CENTER
	test_row.add_theme_constant_override("separation", 16)
	col.add_child(test_row)
	btn_start = make_button("START TAP TEST", Vector2(240, 46), 18)
	btn_start.pressed.connect(_on_start_pressed)
	test_row.add_child(btn_start)
	btn_apply = make_button("APPLY RESULT", Vector2(240, 46), 18)
	btn_apply.pressed.connect(_on_apply_pressed)
	btn_apply.disabled = true
	test_row.add_child(btn_apply)

	var bottom = HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 20)
	root.add_child(bottom)
	btn_back = make_button("BACK", Vector2(200, 46), 18)
	btn_back.pressed.connect(_go_back)
	bottom.add_child(btn_back)
	btn_cue = make_button("", Vector2(260, 46), 18)
	btn_cue.tooltip_text = "Shows a shrinking ring on each tile that closes exactly when you should press"
	btn_cue.pressed.connect(_on_cue_toggled)
	bottom.add_child(btn_cue)
	refresh_cue_button()
	var esc_hint = make_label("Esc: stop test / back", 14, hero_yellow)
	bottom.add_child(esc_hint)

func make_label(text: String, font_size: int, col: Color) -> Label:
	var l = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	return l

func make_style(bg: Color, radius: int, border: int, shadow: int) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border)
	s.border_color = ink_color
	s.shadow_color = Color(ink_color, 0.45)
	s.shadow_size = shadow
	s.shadow_offset = Vector2(3, 4)
	return s

func make_button(text: String, min_size: Vector2, font_size: int) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE # keeps Space/Enter taps from pressing buttons
	b.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, ink_color)
	b.add_theme_color_override("font_disabled_color", ink_color.lightened(0.5))
	b.add_theme_stylebox_override("normal", make_style(paper_white, 10, 3, 5))
	b.add_theme_stylebox_override("hover", make_style(hero_yellow, 10, 3, 7))
	b.add_theme_stylebox_override("pressed", make_style(hero_yellow.darkened(0.1), 10, 3, 2))
	b.add_theme_stylebox_override("disabled", make_style(paper_white.darkened(0.15), 10, 3, 2))
	return b

func refresh_offset_display() -> void:
	var v = GameState.calibration_offset_ms
	offset_value_label.text = "%+d ms" % int(round(v))
	if is_zero_approx(v):
		offset_hint_label.text = "No offset applied"
	elif v > 0.0:
		offset_hint_label.text = "Hits are judged %d ms later (for late taps / audio delay)" % int(round(v))
	else:
		offset_hint_label.text = "Hits are judged %d ms earlier (for early taps)" % int(round(-v))

func apply_offset(value_ms: float) -> void:
	GameState.calibration_offset_ms = clampf(value_ms, -OFFSET_LIMIT_MS, OFFSET_LIMIT_MS)
	GameState.save_game()
	refresh_offset_display()

func _draw_beat_dots() -> void:
	var total = COUNT_IN_BEATS + TAP_BEATS
	var w = beat_dots.size.x
	var spacing = w / float(total)
	var y = beat_dots.size.y / 2.0
	for i in range(total):
		var x = spacing * (i + 0.5)
		var is_count = i < COUNT_IN_BEATS
		var r = 9.0 if is_count else 7.0
		var fill = paper_white.darkened(0.12)
		if i <= current_beat and test_running:
			fill = hero_yellow if is_count else paper_white.darkened(0.3)
		if tapped_beats.has(i):
			fill = good_green if absf(tapped_beats[i]) <= MAX_TAP_ERROR_MS else warn_red
		if i == current_beat and test_running:
			r += 3.0
		beat_dots.draw_circle(Vector2(x, y), r, fill)
		beat_dots.draw_arc(Vector2(x, y), r, 0, TAU, 20, ink_color, 2.0)

# -------------------------------------------------------------- input ---

func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if test_running:
			stop_test(false)
			test_status_label.text = "Test stopped."
		else:
			_go_back()
		return

	if not test_running:
		return
	var is_tap = event is InputEventKey and event.pressed and event.keycode == KEY_SPACE
	for a in TAP_ACTIONS:
		if event.is_action_pressed(a):
			is_tap = true
	if is_tap:
		get_viewport().set_input_as_handled()
		register_tap()

# --------------------------------------------------------------- test ---

func _on_start_pressed() -> void:
	start_test()

func start_test() -> void:
	if test_running:
		return
	tap_offsets.clear()
	tapped_beats.clear()
	ignored_taps = 0
	current_beat = -1
	has_result = false
	btn_apply.disabled = true
	result_label.text = ""
	# Measure raw timing: Conductor subtracts the calibration offset, so zero it during the test.
	saved_offset_ms = GameState.calibration_offset_ms
	GameState.calibration_offset_ms = 0.0
	test_running = true
	btn_start.text = "STOP TEST"
	btn_start.pressed.disconnect(_on_start_pressed)
	btn_start.pressed.connect(_on_stop_pressed)
	test_status_label.text = "Listen... 4 count-in clicks"
	Conductor.start_song(build_click_track(), TEST_BPM, 0.0)
	beat_dots.queue_redraw()

func _on_stop_pressed() -> void:
	stop_test(false)
	test_status_label.text = "Test stopped."

func stop_test(evaluate: bool) -> void:
	if not test_running:
		return
	test_running = false
	Conductor.stop_song()
	GameState.calibration_offset_ms = saved_offset_ms
	btn_start.text = "START TAP TEST"
	btn_start.pressed.disconnect(_on_stop_pressed)
	btn_start.pressed.connect(_on_start_pressed)
	if evaluate:
		evaluate_taps()
	beat_dots.queue_redraw()

func _on_beat_hit(beat: int) -> void:
	if not test_running:
		return
	current_beat = beat
	if beat < COUNT_IN_BEATS:
		test_status_label.text = "Count-in: %d" % (beat + 1)
	elif beat < COUNT_IN_BEATS + TAP_BEATS:
		test_status_label.text = "TAP! %d / %d" % [beat - COUNT_IN_BEATS + 1, TAP_BEATS]
	else:
		# One beat after the last tap click, so late taps on the final click still count
		test_status_label.text = "Done!"
		stop_test(true)
	beat_dots.queue_redraw()

func _on_test_audio_finished() -> void:
	if test_running:
		stop_test(true)

func current_test_beat_float() -> float:
	# Same smoothed clock and press-time estimate the game uses for judging
	# (calibration is zeroed during the test, so this is the raw timing).
	return Conductor.get_input_beat()

func refresh_cue_button() -> void:
	btn_cue.text = "PRESS CUE: %s" % ("ON" if GameState.show_press_cue else "OFF")

func _on_cue_toggled() -> void:
	GameState.show_press_cue = not GameState.show_press_cue
	GameState.save_game()
	refresh_cue_button()

func register_tap() -> void:
	var b = current_test_beat_float()
	var nearest = int(round(b))
	if nearest < COUNT_IN_BEATS or nearest >= COUNT_IN_BEATS + TAP_BEATS:
		return # taps during count-in or after the test are ignored
	if tapped_beats.has(nearest):
		ignored_taps += 1
		return # one tap per click
	var offset_ms = (b - float(nearest)) * (60.0 / TEST_BPM) * 1000.0
	tapped_beats[nearest] = offset_ms
	if absf(offset_ms) <= MAX_TAP_ERROR_MS:
		tap_offsets.append(offset_ms)
	else:
		ignored_taps += 1
	beat_dots.queue_redraw()

func evaluate_taps() -> void:
	if tap_offsets.size() < MIN_VALID_TAPS:
		test_status_label.text = "Not enough taps on the beat (%d of %d needed). Try again." % [tap_offsets.size(), MIN_VALID_TAPS]
		result_label.text = ""
		return
	var sorted = tap_offsets.duplicate()
	sorted.sort()
	var n = sorted.size()
	var mid: int = n >> 1
	var median: float = sorted[mid] if n % 2 == 1 else (sorted[mid - 1] + sorted[mid]) / 2.0
	var mean = 0.0
	for v in sorted:
		mean += v
	mean /= float(n)
	var variance = 0.0
	for v in sorted:
		variance += (v - mean) * (v - mean)
	var stddev = sqrt(variance / float(n))

	pending_result_ms = clampf(median, -OFFSET_LIMIT_MS, OFFSET_LIMIT_MS)
	has_result = true
	btn_apply.disabled = false
	var lateness = "late" if pending_result_ms >= 0.0 else "early"
	var txt = "Result: %+d ms (you tapped %s). Used %d taps, ignored %d." % [int(round(pending_result_ms)), lateness, n, ignored_taps]
	if stddev > UNEVEN_STDDEV_MS:
		txt += "\nYour taps were uneven (spread %d ms). Consider running it again." % int(round(stddev))
		result_label.add_theme_color_override("font_color", warn_red.darkened(0.2))
	else:
		result_label.add_theme_color_override("font_color", good_green.darkened(0.2))
	result_label.text = txt
	test_status_label.text = "Press APPLY RESULT to use it."

func _on_apply_pressed() -> void:
	if not has_result:
		return
	apply_offset(pending_result_ms)
	has_result = false
	btn_apply.disabled = true
	test_status_label.text = "Saved! Offset is now %+d ms." % int(round(GameState.calibration_offset_ms))

func _on_adjust_pressed(step: float) -> void:
	apply_offset(GameState.calibration_offset_ms + step)

func _on_reset_pressed() -> void:
	apply_offset(0.0)

func _go_back() -> void:
	if test_running:
		stop_test(false)
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")

# -------------------------------------------------------------- audio ---

## Click track with clicks baked in at exact sample positions. Count-in
## clicks are higher pitched. Includes 2 spare beats after the last tap click.
func build_click_track() -> AudioStreamWAV:
	var crotchet = 60.0 / TEST_BPM
	var total_beats = COUNT_IN_BEATS + TAP_BEATS + 2
	var total_samples = int(total_beats * crotchet * MIX_RATE)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	data.fill(0)
	var click_len = int(0.03 * MIX_RATE)
	for beat in range(COUNT_IN_BEATS + TAP_BEATS):
		var freq = 1600.0 if beat < COUNT_IN_BEATS else 1000.0
		var start = int(beat * crotchet * MIX_RATE)
		for i in range(click_len):
			var idx = start + i
			if idx >= total_samples:
				break
			var t = float(i) / MIX_RATE
			var env = exp(-t * 140.0)
			var s = sin(TAU * freq * t) * env * 0.8
			data.encode_s16(idx * 2, int(s * 32767.0))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
