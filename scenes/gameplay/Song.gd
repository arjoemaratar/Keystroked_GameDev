extends Node2D

@export var chart_path: String = ""
@export var tiles_path: String = "res://data/tiles.json"

@onready var hud: Control = $CanvasLayer/HUD
@onready var pattern_grid: Control = $CanvasLayer/PatternGrid
@onready var opponent_char: Control = $CanvasLayer/OpponentChar
@onready var player_char: Control = $CanvasLayer/PlayerChar

var chart_data: Dictionary = {}
var rows: Array = []
var bpm: float = 100.0
var first_beat_offset_ms: float = 0.0
var audio_path: String = ""
var current_level_id: String = "tutorial"

enum State { COUNT_IN, PLAYING, RESULTS, GAME_OVER }
var current_state: State = State.COUNT_IN

const COUNT_IN_BEATS: int = 4
var current_row_index: int = -1
var total_player_prompts: int = 0
var max_chart_beat: float = 0.0

class GridHitData:
	var row_idx: int
	var col_idx: int
	var sub_idx: int
	var target_beat: float
	var target_dir: String
	var is_play_phase: bool
	var is_hit: bool = false
	var is_missed: bool = false
	var played_listen: bool = false

var all_hits: Array[GridHitData] = []
var count_in_done: bool = false

func _ready() -> void:
	hud.retry_requested.connect(restart_song)
	hud.menu_requested.connect(_on_menu_requested)
	GameState.player_died.connect(_on_player_died)

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
			rows = chart_data.get("rows", [])

			var opp_type = chart_data.get("opponent", "straight_man")
			opponent_char.character_type = opp_type
			opponent_char.character_name = "Beats" if opp_type == "beats" else "The Straight Man"
			opponent_char.queue_redraw()

func start_level() -> void:
	GameState.reset()
	all_hits.clear()
	current_row_index = -1
	current_state = State.COUNT_IN
	count_in_done = false
	total_player_prompts = 0
	max_chart_beat = 0.0

	# Load grid of 16 tiles into PatternGrid
	pattern_grid.load_chart_rows(rows)

	# Generate all hits timeline
	for r in range(rows.size()):
		var row_info = rows[r]
		var is_play = row_info.get("phase", "listen") == "play"
		var tiles_arr = row_info.get("tiles", [])
		var row_start_beat = float(COUNT_IN_BEATS + (r * 4))

		for c in range(tiles_arr.size()):
			var t_data = tiles_arr[c]
			var t_type = "Q"
			var t_dir = "left"
			var sub_offsets = [0.0]
			var sub_dirs = []

			if t_data is Dictionary:
				t_type = t_data.get("type", "Q")
				t_dir = t_data.get("dir", "left")
				var sub_hits = t_data.get("sub_hits", [])
				if sub_hits.size() > 0:
					sub_offsets.clear()
					for sh in sub_hits:
						sub_offsets.append(float(sh.get("offset", 0.0)))
						sub_dirs.append(str(sh.get("dir", t_dir)))

			if sub_dirs.size() == 0:
				match t_type:
					"E2":
						sub_offsets = [0.0, 0.5]
						sub_dirs = [t_dir, t_dir]
					"TR":
						sub_offsets = [0.0, 0.333, 0.667]
						sub_dirs = [t_dir, t_dir, t_dir]
					"S4":
						sub_offsets = [0.0, 0.25, 0.5, 0.75]
						sub_dirs = [t_dir, t_dir, t_dir, t_dir]
					"R":
						sub_offsets = []
						sub_dirs = []
					_:
						sub_offsets = [0.0]
						sub_dirs = [t_dir]

			var tile_start_beat = row_start_beat + float(c)
			for s in range(sub_offsets.size()):
				var hit = GridHitData.new()
				hit.row_idx = r
				hit.col_idx = c
				hit.sub_idx = s
				hit.target_beat = tile_start_beat + sub_offsets[s]
				hit.target_dir = sub_dirs[s]
				hit.is_play_phase = is_play
				all_hits.append(hit)

				if is_play and hit.target_dir != "rest":
					total_player_prompts += 1
				if hit.target_beat > max_chart_beat:
					max_chart_beat = hit.target_beat

	GameState.total_expected_hits = total_player_prompts
	hud.set_instruction("GET READY! COUNT-IN: 1 2 3 4", false)

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

	if event is InputEventKey and event.pressed and not event.echo:
		var dir = ""
		match event.keycode:
			KEY_LEFT, KEY_A: dir = "left"
			KEY_DOWN, KEY_S: dir = "down"
			KEY_UP, KEY_W: dir = "up"
			KEY_RIGHT, KEY_D: dir = "right"

		if dir != "":
			get_viewport().set_input_as_handled()
			handle_arrow_input(dir)

func handle_arrow_input(pressed_dir: String) -> void:
	var cur_beat = Conductor.current_beat_float
	var best_hit: GridHitData = null
	var min_abs_offset_ms: float = 999999.0
	var signed_offset_ms: float = 0.0

	# Find closest unhit target in play phase
	for hit in all_hits:
		if hit.is_play_phase and not hit.is_hit and not hit.is_missed:
			var diff_beats = cur_beat - hit.target_beat
			var offset_ms = diff_beats * Conductor.crotchet * 1000.0
			if absf(offset_ms) < min_abs_offset_ms:
				min_abs_offset_ms = absf(offset_ms)
				signed_offset_ms = offset_ms
				best_hit = hit

	# Timing check: within Good window (<= 90ms)
	if best_hit != null and min_abs_offset_ms <= 90.0:
		if pressed_dir == best_hit.target_dir:
			best_hit.is_hit = true
			var rating = "Perfect" if min_abs_offset_ms <= 45.0 else "Good"
			GameState.register_hit(rating, signed_offset_ms)
			hud.show_judgment(rating, signed_offset_ms)
			Conductor.play_hit(pressed_dir)
			player_char.trigger_direction(pressed_dir)

			var tile = pattern_grid.get_tile(best_hit.row_idx, best_hit.col_idx)
			if tile:
				tile.mark_sub_hit(best_hit.sub_idx, rating)
		else:
			# Wrong arrow key pressed!
			GameState.register_hit("Stray", 0.0)
			hud.show_judgment("Stray", 0.0)
			Conductor.play_miss()
			player_char.trigger_miss()
	else:
		# Stray arrow press
		GameState.register_hit("Stray", 0.0)
		hud.show_judgment("Stray", 0.0)
		Conductor.play_miss()
		player_char.trigger_miss()

func _on_conductor_beat_hit(beat: int) -> void:
	if current_state == State.GAME_OVER or current_state == State.RESULTS:
		return

	# Gentle idle beat bounce
	opponent_char.bounce(6.0)
	player_char.bounce(6.0)

	# Count-in beats (0, 1, 2, 3)
	if beat < COUNT_IN_BEATS:
		hud.show_count_in(beat + 1)
		Conductor.play_click()
		return

	if current_state == State.COUNT_IN:
		current_state = State.PLAYING

func _on_conductor_tick(_song_time: float, beat_float: float) -> void:
	if current_state != State.PLAYING:
		return

	var song_beat = beat_float - float(COUNT_IN_BEATS)
	if song_beat < 0.0:
		return

	var row_idx = int(floor(song_beat / 4.0))
	var col_idx = int(floor(fmod(song_beat, 4.0)))
	var beat_progress = fmod(song_beat, 1.0)

	if row_idx < rows.size():
		var row_info = rows[row_idx]
		var is_play = row_info.get("phase", "listen") == "play"
		pattern_grid.update_active(row_idx, col_idx, beat_progress, is_play)

		if row_idx != current_row_index:
			current_row_index = row_idx
			var inst = row_info.get("instruction", "FOLLOW THE ARROWS")
			hud.set_instruction(inst, is_play)
			hud.set_level(row_info.get("level", 1))

	# Listen auto-play & late miss checking
	for hit in all_hits:
		if not hit.is_play_phase:
			if beat_float >= hit.target_beat and not hit.played_listen:
				hit.played_listen = true
				if hit.target_dir != "rest":
					Conductor.play_hit(hit.target_dir)
					opponent_char.trigger_direction(hit.target_dir)
				var tile = pattern_grid.get_tile(hit.row_idx, hit.col_idx)
				if tile:
					tile.pulse_listen(hit.sub_idx)
		else:
			if not hit.is_hit and not hit.is_missed:
				var late_ms = (beat_float - hit.target_beat) * Conductor.crotchet * 1000.0
				if late_ms > 90.0:
					hit.is_missed = true
					if hit.target_dir == "rest":
						# Successfully avoided pressing rest!
						var tile = pattern_grid.get_tile(hit.row_idx, hit.col_idx)
						if tile:
							tile.mark_sub_hit(hit.sub_idx, "Good")
					else:
						GameState.register_hit("Miss", late_ms)
						hud.show_judgment("Miss", late_ms)
						player_char.trigger_miss()
						Conductor.play_miss()
						var tile = pattern_grid.get_tile(hit.row_idx, hit.col_idx)
						if tile:
							tile.mark_sub_hit(hit.sub_idx, "Miss")

	# Finish song when past final row
	if row_idx >= rows.size() and current_state == State.PLAYING:
		finish_song()

func finish_song() -> void:
	current_state = State.RESULTS
	pattern_grid.clear_active()
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
