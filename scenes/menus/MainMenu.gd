extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var btn_play: Button = $VBoxContainer/ButtonsVBox/BtnPlay
@onready var btn_tutorial: Button = $VBoxContainer/ButtonsVBox/BtnTutorial
@onready var btn_levels: Button = $VBoxContainer/ButtonsVBox/BtnLevels
@onready var btn_quit: Button = $VBoxContainer/ButtonsVBox/BtnQuit
@onready var dancing_clap: Control = $DancingClap

var logo_tween: Tween
var dance_timer: float = 0.0
var dance_step: int = 0
const DANCE_DIRS = ["left", "down", "up", "right"]

func _ready() -> void:
	btn_play.pressed.connect(_on_play_pressed)
	btn_tutorial.pressed.connect(_on_tutorial_pressed)
	btn_levels.pressed.connect(_on_levels_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

	start_title_wobble()

func start_title_wobble() -> void:
	if logo_tween and logo_tween.is_valid():
		logo_tween.kill()
	logo_tween = create_tween().set_loops()
	logo_tween.tween_property(title_label, "rotation", 0.04, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	logo_tween.tween_property(title_label, "rotation", -0.04, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(delta: float) -> void:
	dance_timer += delta
	# Clap does an awkward dance every 0.5 seconds
	if dance_timer >= 0.5:
		dance_timer = 0.0
		var dir = DANCE_DIRS[dance_step % DANCE_DIRS.size()]
		dance_step += 1
		if dancing_clap.has_method("trigger_direction"):
			dancing_clap.trigger_direction(dir)

func _on_play_pressed() -> void:
	# If tutorial not completed yet, jump to tutorial, else level select
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

func _on_quit_pressed() -> void:
	get_tree().quit()

