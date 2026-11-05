extends Control
class_name RhythmHUD

signal retry_requested

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
@onready var res_retry_btn: Button = $ResultsPanel/MarginContainer/VBox/RetryButton

var hero_yellow: Color = Color("#F7D117")
var ink_color: Color = Color("#1B1B2F")
var paper_white: Color = Color("#FFF8E7")
var straight_red: Color = Color("#C85A6E")
var green_color: Color = Color("#4E9A5E")

var judgment_tween: Tween
var count_in_tween: Tween
var combo_tween: Tween

func _ready() -> void:
	GameState.stats_changed.connect(_on_stats_changed)
	GameState.player_died.connect(_on_player_died)
	res_retry_btn.pressed.connect(func(): retry_requested.emit())
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
		box.custom_minimum_size = Vector2(18, 18)
		var style = StyleBoxFlat.new()
		style.bg_color = ink_color.lerp(paper_white, 0.2)
		style.border_color = ink_color
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		box.add_theme_stylebox_override("panel", style)
		level_container.add_child(box)

func set_level(level: int) -> void:
	var boxes = level_container.get_children()
	for i in range(boxes.size()):
		var box = boxes[i] as Panel
		var style = box.get_theme_stylebox("panel") as StyleBoxFlat
		if i < level:
			style.bg_color = hero_yellow
		else:
			style.bg_color = ink_color.lerp(paper_white, 0.2)

func _on_stats_changed() -> void:
	score_label.text = "SCORE: %06d" % GameState.score
	health_bar.value = GameState.health

	if GameState.combo > 1:
		combo_label.text = "%d COMBO!" % GameState.combo
		combo_label.visible = true
		if combo_tween and combo_tween.is_valid():
			combo_tween.kill()
		combo_tween = create_tween()
		combo_label.scale = Vector2(1.25, 1.25)
		combo_tween.tween_property(combo_label, "scale", Vector2.ONE, 0.15)
	else:
		combo_label.visible = false

func show_count_in(number: int) -> void:
	count_in_label.text = str(number)
	count_in_label.modulate.a = 1.0
	count_in_label.scale = Vector2(2.0, 2.0)
	count_in_label.pivot_offset = count_in_label.size / 2.0

	if count_in_tween and count_in_tween.is_valid():
		count_in_tween.kill()
	count_in_tween = create_tween()
	count_in_tween.tween_property(count_in_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	count_in_tween.parallel().tween_property(count_in_label, "modulate:a", 0.0, 0.45).set_delay(0.25)

func set_phase(phase_name: String, level: int = 1) -> void:
	set_level(level)
	if phase_name == "listen":
		phase_banner.text = "LISTEN TO THE RHYTHM"
		phase_banner.add_theme_color_override("font_color", paper_white)
	elif phase_name == "play":
		phase_banner.text = "YOUR TURN: CLAP! [SPACE]"
		phase_banner.add_theme_color_override("font_color", hero_yellow)
	elif phase_name == "count_in":
		phase_banner.text = "GET READY..."
		phase_banner.add_theme_color_override("font_color", hero_yellow)
	else:
		phase_banner.text = phase_name.to_upper()

	var banner_tween = create_tween()
	phase_banner.scale = Vector2(1.15, 1.15)
	banner_tween.tween_property(phase_banner, "scale", Vector2.ONE, 0.18)

func show_judgment(rating: String, offset_ms: float = 0.0) -> void:
	judgment_label.text = rating.to_upper()
	var col = hero_yellow
	match rating:
		"Perfect":
			col = hero_yellow
			offset_label.text = "%+d ms" % int(offset_ms)
		"Good":
			col = green_color
			offset_label.text = "%+d ms" % int(offset_ms)
		"Miss", "Stray":
			col = straight_red
			offset_label.text = "MISS"

	judgment_label.add_theme_color_override("font_color", col)
	offset_label.add_theme_color_override("font_color", col.lerp(paper_white, 0.5))

	judgment_label.modulate.a = 1.0
	offset_label.modulate.a = 1.0
	judgment_label.scale = Vector2(1.3, 1.3)
	judgment_label.pivot_offset = judgment_label.size / 2.0

	if judgment_tween and judgment_tween.is_valid():
		judgment_tween.kill()
	judgment_tween = create_tween()
	judgment_tween.tween_property(judgment_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	judgment_tween.parallel().tween_property(judgment_label, "modulate:a", 0.0, 0.4).set_delay(0.2)
	judgment_tween.parallel().tween_property(offset_label, "modulate:a", 0.0, 0.4).set_delay(0.2)

func show_results(acc: float, rank: String, score_val: int, max_c: int) -> void:
	results_panel.visible = true
	res_rank_label.text = "RANK: %s" % rank
	res_rank_label.add_theme_color_override("font_color", hero_yellow if rank in ["S", "A"] else paper_white)
	res_acc_label.text = "ACCURACY: %.1f%%" % acc
	res_score_label.text = "FINAL SCORE: %d" % score_val
	res_combo_label.text = "MAX COMBO: %d" % max_c

	results_panel.scale = Vector2(0.8, 0.8)
	var tween = create_tween()
	tween.tween_property(results_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_player_died() -> void:
	show_results(GameState.get_accuracy(), "F", GameState.score, GameState.max_combo)
	res_rank_label.text = "STAGE FAILED"
	res_rank_label.add_theme_color_override("font_color", straight_red)
