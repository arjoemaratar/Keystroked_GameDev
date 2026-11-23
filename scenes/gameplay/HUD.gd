extends Control

signal retry_requested
signal menu_requested

@onready var score_label: Label = $TopBar/ScoreBox/ScoreLabel
@onready var combo_label: Label = $CenterContainer/ComboLabel
@onready var health_bar: ProgressBar = $TopBar/HealthBox/HealthBar
@onready var phase_banner: Label = $PhaseBanner
@onready var count_in_label: Label = $CountInLabel
@onready var judgment_label: Label = $JudgmentContainer/JudgmentLabel
@onready var offset_label: Label = $JudgmentContainer/OffsetLabel
@onready var level_container: HBoxContainer = $TopBar/LevelBox/BoxesContainer

# Results Overlay
@onready var results_panel: PanelContainer = $ResultsPanel
@onready var res_rank_label: Label = $ResultsPanel/MarginContainer/VBox/RankLabel
@onready var res_acc_label: Label = $ResultsPanel/MarginContainer/VBox/AccLabel
@onready var res_score_label: Label = $ResultsPanel/MarginContainer/VBox/ScoreLabel
@onready var res_combo_label: Label = $ResultsPanel/MarginContainer/VBox/ComboLabel
@onready var res_retry_btn: Button = $ResultsPanel/MarginContainer/VBox/ButtonsHBox/RetryButton
@onready var res_menu_btn: Button = $ResultsPanel/MarginContainer/VBox/ButtonsHBox/MenuButton

var hero_yellow: Color = Color("#F7D117")
var ink_color: Color = Color("#1B1B2F")
var paper_white: Color = Color("#FFF8E7")
var straight_red: Color = Color("#C85A6E")
var green_color: Color = Color("#4E9A5E")
var gold_color: Color = Color("#FFD000")

var judgment_tween: Tween
var count_in_tween: Tween
var combo_tween: Tween

# Comic judgment burst badge animation
var burst_alpha: float = 0.0
var burst_scale: float = 0.0
var burst_color: Color = Color("#F7D117")
var burst_rot: float = 0.0

func _ready() -> void:
	GameState.stats_changed.connect(_on_stats_changed)
	GameState.player_died.connect(_on_player_died)
	res_retry_btn.pressed.connect(func(): retry_requested.emit())
	res_menu_btn.pressed.connect(func(): menu_requested.emit())
	results_panel.visible = false
	judgment_label.modulate.a = 0.0
	offset_label.modulate.a = 0.0
	count_in_label.modulate.a = 0.0
	setup_level_boxes()
	_on_stats_changed()

func setup_level_boxes() -> void:
	for child in level_container.get_children():
		child.queue_free()
	for i in range(5):
		var box = Panel.new()
		box.custom_minimum_size = Vector2(22, 22)
		var style = StyleBoxFlat.new()
		style.bg_color = ink_color.lerp(paper_white, 0.15)
		style.border_color = ink_color
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.shadow_color = Color(0, 0, 0, 0.3)
		style.shadow_size = 2
		style.shadow_offset = Vector2(1, 2)
		box.add_theme_stylebox_override("panel", style)
		level_container.add_child(box)

func set_level(level: int) -> void:
	var boxes = level_container.get_children()
	for i in range(boxes.size()):
		var box = boxes[i] as Panel
		var style = box.get_theme_stylebox("panel") as StyleBoxFlat
		if i < level:
			style.bg_color = hero_yellow
			style.border_color = paper_white
			# Punchy little pop
			box.scale = Vector2(1.2, 1.2)
			var tw = create_tween()
			tw.tween_property(box, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			style.bg_color = ink_color.lerp(paper_white, 0.15)
			style.border_color = ink_color

func _on_stats_changed() -> void:
	score_label.text = "SCORE: %06d" % GameState.score
	health_bar.value = GameState.health

	if GameState.combo > 1:
		combo_label.text = "%d COMBO!" % GameState.combo
		combo_label.visible = true
		if combo_tween and combo_tween.is_valid():
			combo_tween.kill()
		combo_tween = create_tween()
		# Punchier bouncy scale
		combo_label.scale = Vector2(1.4, 1.4)
		combo_label.rotation = randf_range(-0.08, 0.08)
		combo_tween.tween_property(combo_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		combo_tween.parallel().tween_property(combo_label, "rotation", 0.0, 0.18)
	else:
		combo_label.visible = false

func show_count_in(number: int) -> void:
	count_in_label.text = str(number)
	count_in_label.modulate.a = 1.0
	count_in_label.scale = Vector2(2.4, 2.4)
	count_in_label.pivot_offset = count_in_label.size / 2.0
	count_in_label.rotation = randf_range(-0.15, 0.15)

	if count_in_tween and count_in_tween.is_valid():
		count_in_tween.kill()
	count_in_tween = create_tween()
	count_in_tween.tween_property(count_in_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	count_in_tween.parallel().tween_property(count_in_label, "rotation", 0.0, 0.22)
	count_in_tween.parallel().tween_property(count_in_label, "modulate:a", 0.0, 0.45).set_delay(0.25)

func set_instruction(text: String, is_player: bool) -> void:
	phase_banner.text = text.to_upper()
	var col = hero_yellow if is_player else paper_white
	phase_banner.add_theme_color_override("font_color", col)

	var banner_tween = create_tween()
	phase_banner.scale = Vector2(1.18, 1.18)
	banner_tween.tween_property(phase_banner, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func show_judgment(rating: String, offset_ms: float = 0.0) -> void:
	var col = hero_yellow
	burst_color = hero_yellow
	burst_rot = randf_range(-0.12, 0.12)

	match rating:
		"Perfect":
			judgment_label.text = "PERFECT!"
			col = hero_yellow
			burst_color = hero_yellow
			offset_label.text = "%+d ms" % int(offset_ms)
		"Good":
			judgment_label.text = "NICE!"
			col = green_color
			burst_color = green_color
			offset_label.text = "%+d ms" % int(offset_ms)
		"Miss":
			judgment_label.text = "BONK!"
			col = straight_red
			burst_color = straight_red
			offset_label.text = "MISS"
		"Stray":
			judgment_label.text = "OOPS!"
			col = straight_red
			burst_color = straight_red
			offset_label.text = "WRONG NOTE"

	judgment_label.add_theme_color_override("font_color", col)
	offset_label.add_theme_color_override("font_color", col.lerp(paper_white, 0.5))

	judgment_label.modulate.a = 1.0
	offset_label.modulate.a = 1.0
	judgment_label.scale = Vector2(1.5, 1.5)
	judgment_label.rotation = burst_rot
	judgment_label.pivot_offset = judgment_label.size / 2.0

	burst_alpha = 0.85
	burst_scale = 1.0
	queue_redraw()

	if judgment_tween and judgment_tween.is_valid():
		judgment_tween.kill()
	judgment_tween = create_tween()
	judgment_tween.tween_property(judgment_label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	judgment_tween.parallel().tween_property(judgment_label, "rotation", 0.0, 0.16)
	judgment_tween.parallel().tween_property(judgment_label, "modulate:a", 0.0, 0.35).set_delay(0.28)
	judgment_tween.parallel().tween_property(offset_label, "modulate:a", 0.0, 0.35).set_delay(0.28)
	judgment_tween.parallel().tween_property(self, "burst_alpha", 0.0, 0.25).set_delay(0.12)
	judgment_tween.parallel().tween_property(self, "burst_scale", 1.4, 0.25)

func _process(_delta: float) -> void:
	if burst_alpha > 0.01:
		queue_redraw()

func _draw() -> void:
	# Draw comic starburst badge behind judgment if active
	if burst_alpha > 0.01:
		var jc = $JudgmentContainer
		var j_pos = jc.position + (jc.size / 2.0)
		var pts = PackedVector2Array()
		var points_count = 14
		var r_out = 95.0 * burst_scale
		var r_in = 55.0 * burst_scale

		for i in range(points_count * 2):
			var r = r_out if i % 2 == 0 else r_in
			var a = (float(i) / float(points_count * 2)) * TAU + burst_rot
			pts.append(j_pos + Vector2(cos(a) * r, sin(a) * r * 0.65))

		var fill_col = burst_color.darkened(0.25)
		fill_col.a = burst_alpha * 0.6
		draw_colored_polygon(pts, fill_col)

		var out_col = ink_color
		out_col.a = burst_alpha
		draw_polyline(pts + PackedVector2Array([pts[0]]), out_col, 2.5)

func show_results(acc: float, rank: String, score_val: int, max_c: int) -> void:
	results_panel.visible = true
	res_rank_label.text = "RANK: %s" % rank
	res_rank_label.add_theme_color_override("font_color", hero_yellow if rank in ["S", "A"] else paper_white)
	res_acc_label.text = "ACCURACY: %.1f%%" % acc
	res_score_label.text = "FINAL SCORE: %d" % score_val
	res_combo_label.text = "MAX COMBO: %d" % max_c

	results_panel.scale = Vector2(0.75, 0.75)
	var tween = create_tween()
	tween.tween_property(results_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_player_died() -> void:
	show_results(GameState.get_accuracy(), "F", GameState.score, GameState.max_combo)
	res_rank_label.text = "STAGE FAILED"
	res_rank_label.add_theme_color_override("font_color", straight_red)
