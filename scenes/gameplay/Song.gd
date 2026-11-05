extends Node2D

const RhythmHUD = preload("res://scenes/gameplay/HUD.gd")
const PatternGrid = preload("res://scenes/gameplay/PatternGrid.gd")
const RhythmCharacter = preload("res://scenes/characters/Character.gd")
const RhythmTile = preload("res://scenes/gameplay/Tile.gd")

@export var chart_path: String = "res://data/charts/week1_test.json"
@export var tiles_path: String = "res://data/tiles.json"

@onready var hud: Control = $CanvasLayer/HUD
@onready var pattern_grid: Control = $CanvasLayer/PatternGrid
@onready var opponent_char: Control = $CanvasLayer/OpponentChar
@onready var player_char: Control = $CanvasLayer/PlayerChar

var tile_defs: Dictionary = {}
var chart_data: Dictionary = {}

var rows: Array = []
var bpm: float = 100.0
var first_beat_offset_ms: float = 0.0
var audio_path: String = ""

# Gameplay states
enum State { COUNT_IN, PLAYING, RESULTS, GAME_OVER }
var current_state: State = State.COUNT_IN

const COUNT_IN_BEATS: int = 4
var current_row_index: int = -1
var total_rows: int = 0

class HitData:
	var row_idx: int
	var col_idx: int
	var sub_idx: int
	var target_beat: float
	var is_play_phase: bool
	var is_hit: bool = false
	var is_missed: bool = false
	var played_listen: bool = false

var all_hits: Array[HitData] = []
var count_in_done: bool = false

func _ready() -> void:
	hud.retry_requested.connect(restart_song)
	GameState.player_died.connect(_on_player_died)

	Conductor.beat_hit.connect(_on_conductor_beat_hit)
	Conductor.tick.connect(_on_conductor_tick)
	Conductor.song_finished.connect(_on_conductor_song_finished)

	load_definitions()
	start_level()

func load_definitions() -> void:
	# Load tiles.json
	if FileAccess.file_exists(tiles_path):
		var file = FileAccess.open(tiles_path, FileAccess.READ)
		var json_text = file.get_as_text()
		var parsed = JSON.parse_string(json_text)
		if parsed is Dictionary:
			tile_defs = parsed

	# Load chart JSON
	if FileAccess.file_exists(chart_path):
		var file = FileAccess.open(chart_path, FileAccess.READ)
		var json_text = file.get_as_text()
		var parsed = JSON.parse_string(json_text)
		if parsed is Dictionary:
			chart_data = parsed
			bpm = float(chart_data.get("bpm", 100.0))
			first_beat_offset_ms = float(chart_data.get("first_beat_offset_ms", 0.0))
			audio_path = chart_data.get("audio", "res://assets/audio/backing_100bpm.wav")
			rows = chart_data.get("rows", [])
			total_rows = rows.size()

func start_level() -> void:
	GameState.reset()
	all_hits.clear()
	current_row_index = -1
	current_state = State.COUNT_IN
	count_in_done = false

	# Setup Pattern Grid
	pattern_grid.load_grid(rows, tile_defs)

	# Generate HitData timeline
	var total_player_hits = 0
	for r in range(rows.size()):
		var row_info = rows[r]
		var is_play = row_info.get("phase", "listen") == "play"
		var tiles = row_info.get("tiles", [])
		var row_start_beat = float(COUNT_IN_BEATS + (r * 4))

		for c in range(tiles.size()):
			var t_id = tiles[c]
			var t_def = tile_defs.get(t_id, {"hits": [0.0]})
			var hit_offsets = t_def.get("hits", [0.0])
			var tile_start_beat = row_start_beat + float(c)

			for s in range(hit_offsets.size()):
				var sub_offset = float(hit_offsets[s])
				var hit = HitData.new()
				hit.row_idx = r
				hit.col_idx = c
				hit.sub_idx = s
				hit.target_beat = tile_start_beat + sub_offset
				hit.is_play_phase = is_play
				all_hits.append(hit)
				if is_play:
					total_player_hits += 1

	GameState.total_expected_hits = total_player_hits

	hud.set_phase("count_in", 1)

	# Start backing audio via Conductor
	if ResourceLoader.exists(audio_path):
		var stream = load(audio_path) as AudioStream
		Conductor.start_song(stream, bpm, first_beat_offset_ms)
	else:
		push_error("Audio stream not found: " + audio_path)

func restart_song() -> void:
	Conductor.stop_song()
	hud.results_panel.visible = false
	start_level()

func _unhandled_input(event: InputEvent) -> void:
	if current_state != State.PLAYING:
		return

	# Support Space key, Left mouse button, or configured 'clap' action
	var is_clap_action = event.is_action_pressed("clap")
	var is_space = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE)
	var is_click = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)

	if is_clap_action or is_space or is_click:
		get_viewport().set_input_as_handled()
		handle_player_clap()

func handle_player_clap() -> void:
	var cur_beat = Conductor.current_beat_float
	var best_hit: HitData = null
	var min_abs_offset_ms: float = 999999.0
	var signed_offset_ms: float = 0.0

	# Find closest unhit target in the current or adjacent row during play phase
	for hit in all_hits:
		if hit.is_play_phase and not hit.is_hit and not hit.is_missed:
			var diff_beats = cur_beat - hit.target_beat
			var offset_ms = diff_beats * Conductor.crotchet * 1000.0
			if absf(offset_ms) < min_abs_offset_ms:
				min_abs_offset_ms = absf(offset_ms)
				signed_offset_ms = offset_ms
				best_hit = hit

	# Judge windows: Perfect <= 45ms, Good <= 90ms
	if best_hit != null and min_abs_offset_ms <= 90.0:
		best_hit.is_hit = true
		var rating = "Perfect" if min_abs_offset_ms <= 45.0 else "Good"
		GameState.register_hit(rating, signed_offset_ms)
		hud.show_judgment(rating, signed_offset_ms)
		player_char.trigger_clap()
		Conductor.play_clap()

		var tile = pattern_grid.get_tile(best_hit.row_idx, best_hit.col_idx)
		if tile:
			tile.mark_sub_hit(best_hit.sub_idx, rating)
	else:
		# Stray clap with no tile expecting it
		GameState.register_hit("Stray", 0.0)
		hud.show_judgment("Stray", 0.0)
		player_char.trigger_clap()
		Conductor.play_clap()

func _on_conductor_beat_hit(beat: int) -> void:
	if current_state == State.GAME_OVER or current_state == State.RESULTS:
		return

	# Idle beat bounce
	opponent_char.bounce(6.0)
	player_char.bounce(6.0)

	# Count-in beats (0, 1, 2, 3)
	if beat < COUNT_IN_BEATS:
		hud.show_count_in(beat + 1)
		Conductor.play_click()
		return

	if not count_in_done:
		count_in_done = true
		current_state = State.PLAYING

	# Determine active row
	var song_beat = beat - COUNT_IN_BEATS
	var row_idx = int(floor(float(song_beat) / 4.0))

	if row_idx != current_row_index and row_idx < rows.size():
		current_row_index = row_idx
		var row_info = rows[current_row_index]
		var phase = row_info.get("phase", "listen")
		var level = row_info.get("level", 1)
		hud.set_phase(phase, level)

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

	# Check listen hits and late miss judgments
	for hit in all_hits:
		if not hit.is_play_phase:
			# Opponent listen playback
			if beat_float >= hit.target_beat and not hit.played_listen:
				hit.played_listen = true
				Conductor.play_clap()
				opponent_char.trigger_clap()
				var tile = pattern_grid.get_tile(hit.row_idx, hit.col_idx)
				if tile:
					tile.pulse_listen(hit.sub_idx)
		else:
			# Player play phase: check for expired (missed) hits
			if not hit.is_hit and not hit.is_missed:
				var late_ms = (beat_float - hit.target_beat) * Conductor.crotchet * 1000.0
				if late_ms > 90.0: # Exceeded Good window
					hit.is_missed = true
					GameState.register_hit("Miss", late_ms)
					hud.show_judgment("Miss", late_ms)
					player_char.trigger_miss()
					Conductor.play_miss()
					var tile = pattern_grid.get_tile(hit.row_idx, hit.col_idx)
					if tile:
						tile.mark_sub_hit(hit.sub_idx, "Miss")

	# Check if all rows completed
	if row_idx >= rows.size() and current_state == State.PLAYING:
		finish_song()

func finish_song() -> void:
	current_state = State.RESULTS
	pattern_grid.clear_active()
	var acc = GameState.get_accuracy()
	var rank = GameState.get_rank()
	hud.show_results(acc, rank, GameState.score, GameState.max_combo)

func _on_conductor_song_finished() -> void:
	if current_state == State.PLAYING:
		finish_song()

func _on_player_died() -> void:
	current_state = State.GAME_OVER
	Conductor.stop_song()
