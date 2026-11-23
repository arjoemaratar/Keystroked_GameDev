extends Control
## Cinematic story text box: letterbox bars, an optional stage title card,
## a typewriter text box with per-speaker blip sounds, and screen flashes.
## Call play(lines, card) and await `finished`.
## Space/Enter/click advances, Esc skips the whole scene.
## Emits line_started(line) so a CutsceneDirector can move the camera and characters.

signal finished
signal line_started(line: Dictionary)

const StoryData = preload("res://scenes/story/StoryData.gd")
const CHARS_PER_SEC: float = 48.0
const BAR_HEIGHT: float = 64.0
const BLIP_PATH: String = "res://assets/audio/click.wav"

enum Phase { CLOSED, CARD, LINES, CLOSING }
var phase: Phase = Phase.CLOSED

var lines: Array = []
var index: int = -1
var typing: bool = false
var shown_chars: float = 0.0
var last_blip_char: int = 0
var blip_pitch: float = 1.0

var top_bar: ColorRect
var bottom_bar: ColorRect
var flash_rect: ColorRect
var panel: PanelContainer
var panel_style: StyleBoxFlat
var name_label: Label
var text_label: Label
var hint_label: Label
var next_arrow: Label
var card: Control
var card_bg: ColorRect
var card_sub: Label
var card_title: Label
var card_tag: Label
var blip: AudioStreamPlayer

var card_tween: Tween
var bars_tween: Tween
var arrow_time: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()

func _build() -> void:
	top_bar = _bar(true)
	bottom_bar = _bar(false)

	panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -440.0
	panel.offset_right = 440.0
	panel.offset_top = -200.0
	panel.offset_bottom = -22.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#1B1B2F")
	panel_style.border_color = Color("#FFF8E7")
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(16)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 8
	panel_style.shadow_offset = Vector2(4, 6)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.pivot_offset = Vector2(0, 14)
	vbox.add_child(name_label)

	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.add_theme_font_size_override("font_size", 20)
	text_label.add_theme_color_override("font_color", Color("#FFF8E7"))
	vbox.add_child(text_label)

	var foot = HBoxContainer.new()
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(foot)
	hint_label = Label.new()
	hint_label.text = "SPACE / ENTER: next     ESC: skip"
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color("#FFF8E7").lerp(Color("#1B1B2F"), 0.45))
	foot.add_child(hint_label)
	next_arrow = Label.new()
	next_arrow.text = "  ▼"
	next_arrow.add_theme_font_size_override("font_size", 14)
	next_arrow.add_theme_color_override("font_color", Color("#F7D117"))
	foot.add_child(next_arrow)

	_build_card()

	flash_rect = ColorRect.new()
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1, 1, 1, 0)
	add_child(flash_rect)

	blip = AudioStreamPlayer.new()
	if ResourceLoader.exists(BLIP_PATH):
		blip.stream = load(BLIP_PATH)
	blip.volume_db = -20.0
	blip.max_polyphony = 3
	add_child(blip)

func _bar(is_top: bool) -> ColorRect:
	var bar = ColorRect.new()
	bar.color = Color("#07060E")
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.anchor_left = 0.0
	bar.anchor_right = 1.0
	bar.anchor_top = 0.0 if is_top else 1.0
	bar.anchor_bottom = 0.0 if is_top else 1.0
	bar.offset_top = -BAR_HEIGHT if is_top else 0.0
	bar.offset_bottom = 0.0 if is_top else BAR_HEIGHT
	add_child(bar)
	return bar

func _build_card() -> void:
	card = Control.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.visible = false
	add_child(card)

	card_bg = ColorRect.new()
	card_bg.color = Color("#07060E")
	card_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card_bg)

	var box = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.custom_minimum_size = Vector2(900, 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)

	card_sub = _card_label(20, Color("#F7D117"))
	box.add_child(card_sub)
	card_title = _card_label(56, Color("#FFF8E7"))
	box.add_child(card_title)
	card_tag = _card_label(18, Color("#C9C3B3"))
	card_tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(card_tag)

func _card_label(font_size: int, col: Color) -> Label:
	var l = Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# ---------- Flow ----------

## Plays the lines. `title_card` may hold "subtitle", "title" and "tagline" to show
## a stage title card first. Emits `finished` when done or skipped
## (deferred, straight away, when there is nothing to show).
func play(new_lines: Array, title_card: Dictionary = {}) -> void:
	lines = new_lines
	index = -1
	if lines.is_empty() and title_card.is_empty():
		finished.emit.call_deferred()
		return
	visible = true
	panel.visible = false
	panel.modulate.a = 1.0
	_tween_bars(true)
	if not title_card.is_empty():
		_show_card(title_card)
	else:
		_start_lines()

func _tween_bars(show: bool) -> void:
	if bars_tween and bars_tween.is_valid():
		bars_tween.kill()
	bars_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var h := BAR_HEIGHT if show else 0.0
	bars_tween.tween_property(top_bar, "offset_bottom", h, 0.45)
	bars_tween.tween_property(top_bar, "offset_top", h - BAR_HEIGHT, 0.45)
	bars_tween.tween_property(bottom_bar, "offset_top", -h, 0.45)
	bars_tween.tween_property(bottom_bar, "offset_bottom", BAR_HEIGHT - h, 0.45)

func _show_card(info: Dictionary) -> void:
	phase = Phase.CARD
	card.visible = true
	card.modulate.a = 1.0
	card_bg.modulate.a = 1.0
	card_sub.text = str(info.get("subtitle", "")).to_upper()
	card_title.text = str(info.get("title", ""))
	card_tag.text = str(info.get("tagline", ""))
	for l in [card_sub, card_title, card_tag]:
		l.modulate.a = 0.0
	card_title.pivot_offset = Vector2(450, 34)
	card_title.scale = Vector2(1.25, 1.25)

	card_tween = create_tween()
	card_tween.tween_interval(0.25)
	card_tween.tween_property(card_sub, "modulate:a", 1.0, 0.35)
	card_tween.tween_callback(func(): _blip(0.8))
	card_tween.tween_property(card_title, "modulate:a", 1.0, 0.3)
	card_tween.parallel().tween_property(card_title, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	card_tween.tween_property(card_tag, "modulate:a", 1.0, 0.4)
	card_tween.tween_interval(1.6)
	card_tween.tween_callback(_end_card)

func _end_card() -> void:
	if phase != Phase.CARD:
		return
	if card_tween and card_tween.is_valid():
		card_tween.kill()
	var tw = create_tween()
	tw.tween_property(card, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): card.visible = false)
	_start_lines()

func _start_lines() -> void:
	if lines.is_empty():
		_close()
		return
	phase = Phase.LINES
	panel.visible = true
	_next_line()

func _next_line() -> void:
	index += 1
	if index >= lines.size():
		_close()
		return
	var line = lines[index]
	if not (line is Dictionary):
		line = {"speaker": "", "text": str(line)}
	var speaker: String = str(line.get("speaker", ""))
	var col: Color = StoryData.speaker_color(speaker)
	var is_narrator: bool = speaker == "Narrator" or speaker == ""
	name_label.visible = not is_narrator
	name_label.text = speaker.to_upper()
	name_label.add_theme_color_override("font_color", col)
	panel_style.border_color = Color("#FFF8E7").lerp(Color("#1B1B2F"), 0.3) if is_narrator else col
	panel_style.bg_color = Color("#12111F") if is_narrator else Color("#1B1B2F")
	text_label.add_theme_color_override("font_color", Color("#C9C3B3") if is_narrator else Color("#FFF8E7"))
	text_label.text = str(line.get("text", ""))
	text_label.visible_characters = 0
	shown_chars = 0.0
	last_blip_char = 0
	typing = true
	blip_pitch = 0.75 + float(abs(speaker.hash()) % 60) / 100.0

	# Box pops in, name plate swings in
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.96, 0.96)
	var tw = create_tween()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not is_narrator:
		name_label.scale = Vector2(1.35, 1.35)
		name_label.rotation = -0.06
		tw.parallel().tween_property(name_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(name_label, "rotation", 0.0, 0.22)

	if line.has("flash"):
		flash(Color(str(line["flash"])))
	line_started.emit(line)

func _close() -> void:
	if phase == Phase.CLOSING or phase == Phase.CLOSED:
		return
	phase = Phase.CLOSING
	typing = false
	if card_tween and card_tween.is_valid():
		card_tween.kill()
	_tween_bars(false)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(panel, "modulate:a", 0.0, 0.25)
	if card.visible:
		tw.tween_property(card, "modulate:a", 0.0, 0.35)
	tw.chain().tween_interval(0.2)
	tw.chain().tween_callback(func():
		visible = false
		card.visible = false
		phase = Phase.CLOSED
		lines = []
		finished.emit())

func flash(col: Color, strength: float = 0.75) -> void:
	col.a = strength
	flash_rect.color = col
	var tw = create_tween()
	tw.tween_property(flash_rect, "color:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _blip(pitch: float) -> void:
	if blip.stream:
		blip.pitch_scale = pitch * randf_range(0.95, 1.05)
		blip.play()

func _process(delta: float) -> void:
	if not visible:
		return
	arrow_time += delta
	next_arrow.modulate.a = 0.0 if typing else (0.6 + sin(arrow_time * 6.0) * 0.4)
	if phase != Phase.LINES or not typing:
		return
	shown_chars += delta * CHARS_PER_SEC
	var total: int = text_label.get_total_character_count()
	text_label.visible_characters = mini(int(shown_chars), total)
	# Blip every few letters while typing
	if text_label.visible_characters - last_blip_char >= 3:
		last_blip_char = text_label.visible_characters
		_blip(blip_pitch)
	if text_label.visible_characters >= total:
		typing = false

func _advance() -> void:
	match phase:
		Phase.CARD:
			_end_card()
		Phase.LINES:
			if typing:
				typing = false
				text_label.visible_characters = -1
			else:
				_next_line()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_advance()
