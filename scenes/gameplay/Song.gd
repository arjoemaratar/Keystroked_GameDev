extends Node2D

@export var chart_path: String = ""
@export var tiles_path: String = "res://data/tiles.json"

@onready var hud: Control = $CanvasLayer/HUD
@onready var lane_system: Control = $CanvasLayer/LaneSystem
@onready var opponent_char: Control = $CanvasLayer/OpponentChar
@onready var player_char: Control = $CanvasLayer/PlayerChar

var chart_data: Dictionary = {}
var phrases: Array = []
var bpm: float = 100.0
var first_beat_offset_ms: float = 0.0
var audio_path: String = ""
var current_level_id: String = "tutorial"

enum State { COUNT_IN, PLAYING, RESULTS, GAME_OVER }
var current_state: State = State.COUNT_IN

const COUNT_IN_BEATS: int = 4
var current_phrase_index: int = -1
var total_player_prompts: int = 0
var max_chart_beat: float = 0.0

func _ready() -> void:
	hud.retry_requested.connect(restart_song)
	hud.menu_requested.connect(_on_menu_requested)
	GameState.player_died.connect(_on_player_died)

	lane_system.hit_judged.connect(_on_hit_judged)
	lane_system.opponent_hit.connect(_on_opponent_hit)

	Conductor.beat_hit.connect(_on_conductor_beat_hit)
	Conductor.tick.connect(_on_conductor_tick)
	Conductor.song_finished.connect(_on_conductor_song_finished)

	load_current_level()
	start_level()

func load_current_level() -> void:
	current_level_id = GameState.selected_level_id
	if chart_path == "":
		if current_level_id == "tutorial":
			chart_path = "res://data/charts/tutorial.json"
		else:
			chart_path = "res://data/charts/week1.json"

	if FileAccess.file_exists(chart_path):
		var file = FileAccess.open(chart_path, FileAccess.READ)
		var text = file.get_as_text()
		var parsed = JSON.parse_string(text)
		if parsed is Dictionary:
			chart_data = parsed
			bpm = float(chart_data.get("bpm", 100.0))
			first_beat_offset_ms = float(chart_data.get("first_beat_offset_ms", 0.0))
			audio_path = chart_data.get("audio", "res://assets/audio/backing_100bpm.wav")
			phrases = chart_data.get("phrases", [])

			var opp_type = chart_data.get("opponent", "straight_man")
			opponent_char.character_type = opp_type
			opponent_char.character_name = "Beats" if opp_type == "beats" else "The Straight Man"
			opponent_char.queue_redraw()

func start_level() -> void:
	GameState.reset()
	lane_system.clear_all()
	current_phrase_index = -1
	current_state = State.COUNT_IN
	total_player_prompts = 0
	max_chart_beat = 0.0

	# Spawn prompts into LaneSystem
	for p_info in phrases:
		var is_play = p_info.get("phase", "listen") == "play"
		var prompts = p_info.get("prompts", [])
		for p in prompts:
			var b = float(p.get("beat", 0.0))
			var d = str(p.get("direction", "left"))
			lane_system.spawn_prompt(b, d, is_play)
			if is_play and d != "rest":
				total_player_prompts += 1
			if b > max_chart_beat:
				max_chart_beat = b

	GameState.total_expected_hits = total_player_prompts

	hud.set_instruction("GET READY! COUNT-IN: 1 2 3 4", false)

	# Start audio with reliable loader
	var stream = Conductor.load_audio(audio_path)
	if stream:
		Conductor.start_song(stream, bpm, first_beat_offset_ms)
	else:
		push_error("Audio not found: " + audio_path)

func restart_song() -> void:
	Conductor.stop_song()
	hud.results_panel.visible = false
	start_level()

func _unhandled_input(event: InputEvent) -> void:
	if current_state != State.PLAYING:
		return

	if event is InputEventKey:
		var k = event.keycode
		var pressed = event.pressed
		var echo = event.echo

		if pressed and not echo:
			if k == KEY_LEFT or k == KEY_A:
				get_viewport().set_input_as_handled()
				lane_system.handle_input_press("left")
			elif k == KEY_DOWN or k == KEY_S:
				get_viewport().set_input_as_handled()
				lane_system.handle_input_press("down")
			elif k == KEY_UP or k == KEY_W:
				get_viewport().set_input_as_handled()
				lane_system.handle_input_press("up")
			elif k == KEY_RIGHT or k == KEY_D:
				get_viewport().set_input_as_handled()
				lane_system.handle_input_press("right")

		elif not pressed:
			if k == KEY_LEFT or k == KEY_A:
				lane_system.handle_input_release("left")
			elif k == KEY_DOWN or k == KEY_S:
				lane_system.handle_input_release("down")
			elif k == KEY_UP or k == KEY_W:
				lane_system.handle_input_release("up")
			elif k == KEY_RIGHT or k == KEY_D:
				lane_system.handle_input_release("right")

func _on_hit_judged(rating: String, offset_ms: float, direction: String) -> void:
	GameState.register_hit(rating, offset_ms)
	hud.show_judgment(rating, offset_ms)

	if rating == "Perfect" or rating == "Good":
		player_char.trigger_direction(direction)
	elif rating == "Miss":
		player_char.trigger_miss()
	elif rating == "Stray":
		player_char.trigger_miss()

func _on_opponent_hit(direction: String) -> void:
	opponent_char.trigger_direction(direction)

func _on_conductor_beat_hit(beat: int) -> void:
	if current_state == State.GAME_OVER or current_state == State.RESULTS:
		return

	# Idle bounce
	opponent_char.bounce(6.0)
	player_char.bounce(6.0)
	lane_system.pulse_beat()

	# Count-in beats 0, 1, 2, 3
	if beat < COUNT_IN_BEATS:
		hud.show_count_in(beat + 1)
		Conductor.play_click()
		return

	if current_state == State.COUNT_IN:
		current_state = State.PLAYING

func _on_conductor_tick(_song_time: float, beat_float: float) -> void:
	if current_state != State.PLAYING:
		return

	lane_system.update_frame(beat_float)

	# Update active instruction banner based on current beat
	for i in range(phrases.size()):
		var phrase = phrases[i]
		var prompts = phrase.get("prompts", [])
		if prompts.size() > 0:
			var first_b = float(prompts[0].get("beat", 0.0))
			var last_b = float(prompts[prompts.size() - 1].get("beat", 0.0)) + 2.0
			if beat_float >= (first_b - 1.5) and beat_float <= last_b:
				if i != current_phrase_index:
					current_phrase_index = i
					var is_play = phrase.get("phase", "listen") == "play"
					var inst = phrase.get("instruction", "FOLLOW THE ARROWS")
					hud.set_instruction(inst, is_play)
					hud.set_level(clamp(i + 1, 1, 5))

	# Check for completion (2 beats past the final arrow)
	if beat_float >= (max_chart_beat + 2.0) and current_state == State.PLAYING:
		finish_song()

func finish_song() -> void:
	current_state = State.RESULTS
	var acc = GameState.get_accuracy()
	var rank = GameState.get_rank()
	GameState.record_level_completion(current_level_id, rank, GameState.score)
	hud.show_results(acc, rank, GameState.score, GameState.max_combo)

func _on_conductor_song_finished() -> void:
	if current_state == State.PLAYING:
		finish_song()

func _on_player_died() -> void:
	current_state = State.GAME_OVER
	Conductor.stop_song()

func _on_menu_requested() -> void:
	Conductor.stop_song()
	get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")
