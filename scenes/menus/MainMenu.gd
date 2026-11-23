extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var btn_play: Button = $VBoxContainer/ButtonsVBox/BtnPlay
@onready var btn_tutorial: Button = $VBoxContainer/ButtonsVBox/BtnTutorial
@onready var btn_levels: Button = $VBoxContainer/ButtonsVBox/BtnLevels
@onready var btn_endless: Button = $VBoxContainer/ButtonsVBox/BtnEndless
@onready var btn_settings: Button = $VBoxContainer/ButtonsVBox/BtnSettings
@onready var btn_quit: Button = $VBoxContainer/ButtonsVBox/BtnQuit
@onready var dancing_clap: Control = $DancingClap

var logo_tween: Tween
var dance_timer: float = 0.0
var dance_step: int = 0
const DANCE_DIRS = ["left", "up", "right", "down", "up", "left", "right", "up"]

# Floating rhythm confetti particles
var particles: Array[Dictionary] = []

func _ready() -> void:
	btn_play.pressed.connect(_on_play_pressed)
	btn_tutorial.pressed.connect(_on_tutorial_pressed)
	btn_levels.pressed.connect(_on_levels_pressed)
	btn_endless.pressed.connect(_on_endless_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

	# Add tactile hover bounce to all buttons
	for btn in [btn_play, btn_tutorial, btn_levels, btn_endless, btn_settings, btn_quit]:
		setup_button_hover(btn)

	start_title_wobble()
	init_floating_particles()

func setup_button_hover(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	btn.mouse_entered.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)

func start_title_wobble() -> void:
	if logo_tween and logo_tween.is_valid():
		logo_tween.kill()
	title_label.pivot_offset = title_label.size / 2.0
	logo_tween = create_tween().set_loops()
	logo_tween.tween_property(title_label, "rotation", 0.04, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	logo_tween.parallel().tween_property(title_label, "scale", Vector2(1.04, 0.96), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	logo_tween.tween_property(title_label, "rotation", -0.04, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	logo_tween.parallel().tween_property(title_label, "scale", Vector2(0.96, 1.04), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func init_floating_particles() -> void:
	particles.clear()
	var symbols = ["♪", "♫", "★", "⚡", "♩", "●"]
	for i in range(16):
		particles.append({
			"pos": Vector2(randf_range(50, 1230), randf_range(100, 700)),
			"speed": randf_range(25.0, 50.0),
			"symbol": symbols[i % symbols.size()],
			"rot": randf_range(-PI, PI),
			"rot_speed": randf_range(-1.5, 1.5),
			"alpha": randf_range(0.25, 0.6),
			"size": randi_range(14, 22)
		})

func _process(delta: float) -> void:
	# Clap rhythm dance
	dance_timer += delta
	if dance_timer >= 0.45:
		dance_timer = 0.0
		var dir = DANCE_DIRS[dance_step % DANCE_DIRS.size()]
		dance_step += 1
		if dancing_clap.has_method("trigger_direction"):
			dancing_clap.trigger_direction(dir)

	# Update floating particles
	for p in particles:
		p["pos"].y -= p["speed"] * delta
		p["rot"] += p["rot_speed"] * delta
		if p["pos"].y < -30:
			p["pos"].y = 740
			p["pos"].x = randf_range(50, 1230)

	queue_redraw()

func _draw() -> void:
	# Draw floating rhythm particles
	var font = ThemeDB.fallback_font
	for p in particles:
		var col = Color("#F7D117") if p["symbol"] in ["★", "⚡"] else Color("#FFF8E7")
		col.a = p["alpha"]
		draw_set_transform(p["pos"], p["rot"], Vector2.ONE)
		draw_string(font, Vector2.ZERO, p["symbol"], HORIZONTAL_ALIGNMENT_CENTER, -1, p["size"], col)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _on_play_pressed() -> void:
	if not GameState.completed_levels.has("tutorial"):
		GameState.selected_level_id = "tutorial"
		get_tree().change_scene_to_file("res://scenes/gameplay/Song.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")

func _on_tutorial_pressed() -> void:
	GameState.selected_level_id = "tutorial"
	get_tree().change_scene_to_file("res://scenes/gameplay/Song.tscn")

func _on_levels_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")

func _on_endless_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/gameplay/Endless.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/Settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
