extends Node2D

@export var chart_path: String = ""
@export var tiles_path: String = "res://data/tiles.json"

const LEVELS_PATH: String = "res://data/levels.json"
const TileDefs = preload("res://scenes/gameplay/TileDefs.gd")
const StoryData = preload("res://scenes/story/StoryData.gd")
const DialogueBoxScript = preload("res://scenes/story/DialogueBox.gd")
const SpeechBubbleScript = preload("res://scenes/story/SpeechBubble.gd")
const CutsceneDirectorScript = preload("res://scenes/story/CutsceneDirector.gd")
const STREAK_TAUNTS_AT: Array[int] = [10, 25, 50, 100]
const MISS_TAUNT_COOLDOWN_MS: int = 5000
const ARROW_ACTIONS: Dictionary = {
	"left": "arrow_left",
	"down": "arrow_down",
	"up": "arrow_up",
	"right": "arrow_right",
}

@onready var hud: Control = $CanvasLayer/HUD
@onready var pattern_grid: Control = $CanvasLayer/PatternGrid
@onready var opponent_char: Control = $CanvasLayer/OpponentChar
@onready var player_char: Control = $CanvasLayer/PlayerChar

var chart_data: Dictionary = {}
var rows: Array = []
var bpm: float = 100.0
var first_beat_offset_ms: float = 0.0
var audio_path: String = ""
var music_start_sec: float = 0.0 # where playback starts in the track (Endless mode)
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
	var played_listen: bool = false   # listen-phase sound started
	var shown_listen: bool = false    # listen-phase tile pulse / rival move shown

var all_hits: Array[GridHitData] = []
var count_in_done: bool = false
var count_in_clicked: int = 0 # count-in clicks already started

# Timing windows (ms either side of the note)
const PERFECT_WINDOW_MS: float = 45.0
const GOOD_WINDOW_MS: float = 90.0

# Press cue: rings on tiles that close exactly when to press
const CUE_LEAD_SEC: float = 0.7 # ring starts this long before the note
var cued_tiles: Array = []

var judge_log: Array[float] = [] # signed offsets of judged hits (for debugging/tests)

# Story
var dialogue: Dictionary = {}
var dialogue_box: Control
var speech_bubble: PanelContainer
var director: Node
var story_camera: Camera2D
var level_info: Dictionary = {}
var last_miss_taunt_ms: int = -MISS_TAUNT_COOLDOWN_MS

func _ready() -> void:
	hud.retry_requested.connect(restart_song)
	hud.menu_requested.connect(_on_menu_requested)
	GameState.player_died.connect(_on_player_died)

	Conductor.beat_hit.connect(_on_conductor_beat_hit)
	Conductor.tick.connect(_on_conductor_tick)
	Conductor.song_finished.connect(_on_conductor_song_finished)

	load_current_level()
	setup_story_ui()
	await play_dialogue("intro")
	start_level()

func find_level_entry(level_id: String) -> Dictionary:
	if not FileAccess.file_exists(LEVELS_PATH):
		push_warning("Song: %s not found" % LEVELS_PATH)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(LEVELS_PATH))
	if parsed is Array:
		for lvl in parsed:
			if lvl is Dictionary and str(lvl.get("id", "")) == level_id:
				return lvl
	push_warning("Song: level '%s' not found in %s" % [level_id, LEVELS_PATH])
	return {}

func load_current_level() -> void:
	current_level_id = GameState.selected_level_id
	TileDefs.load_defs(tiles_path)

	var level: Dictionary = find_level_entry(current_level_id)
	level_info = level
	var level_bpm: float = float(level.get("bpm", 0.0))

	if chart_path == "":
		chart_path = str(level.get("chart", ""))
	if chart_path == "":
		chart_path = "res://data/charts/tutorial.json" if current_level_id == "tutorial" else "res://data/charts/week1.json"

	if not FileAccess.file_exists(chart_path):
		push_error("Song: chart not found: " + chart_path)
		return

	var parsed = JSON.parse_string(FileAccess.get_file_as_string(chart_path))
	if not (parsed is Dictionary):
		push_error("Song: could not parse chart " + chart_path)
		return

	chart_data = parsed
	first_beat_offset_ms = float(chart_data.get("first_beat_offset_ms", 0.0))
	audio_path = chart_data.get("audio", "res://assets/audio/backing_100bpm.wav")
	rows = chart_data.get("rows", [])

	# BPM: levels.json is the intended tempo, but the chart's BPM matches its audio,
	# so the chart wins if they disagree.
	if chart_data.has("bpm"):
		bpm = float(chart_data["bpm"])
		if level_bpm > 0.0 and not is_equal_approx(level_bpm, bpm):
			push_warning("Song: level '%s' says %s BPM but chart %s is %s BPM; using the chart's BPM to match its audio" % [current_level_id, level_bpm, chart_path, bpm])
	elif level_bpm > 0.0:
		bpm = level_bpm

	var opp_type = str(level.get("rival_type", chart_data.get("opponent", "straight_man")))
	var opp_name = str(level.get("rival", "Beats" if opp_type == "beats" else "The Straight Man"))
	opponent_char.character_type = opp_type
	opponent_char.character_name = opp_name
	opponent_char.queue_redraw()

	var dialogue_path := str(level.get("dialogue", "res://data/dialogue/%s.json" % current_level_id))
	dialogue = StoryData.load_dialogue(dialogue_path)

# ---------- Story ----------

func setup_story_ui() -> void:
	var layer = $CanvasLayer
	speech_bubble = SpeechBubbleScript.new()
	speech_bubble.position = Vector2(40, 250)
	layer.add_child(speech_bubble)

	# Story UI sits on its own layer so the camera never zooms the text box
	var story_layer := CanvasLayer.new()
	story_layer.layer = 10
	add_child(story_layer)
	dialogue_box = DialogueBoxScript.new()
	story_layer.add_child(dialogue_box)

	# Camera for cutscenes. Top-left anchor at (0,0), zoom 1 = the normal gameplay view.
	story_camera = Camera2D.new()
	story_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(story_camera)
	story_camera.make_current()
	layer.follow_viewport_enabled = true

	var rivals: Array = [opponent_char.character_name]
	rivals.append_array(level_info.get("rival_speakers", []))
	director = CutsceneDirectorScript.new()
	add_child(director)
	director.setup(story_camera, dialogue_box, player_char, opponent_char, rivals, [hud, pattern_grid])

## Plays a dialogue section ("intro", "win") and waits until it's done.
func play_dialogue(section: String) -> void:
	var lines = dialogue.get(section, [])
	if not (lines is Array) or lines.is_empty():
		return
	var title_card: Dictionary = {}
	if section == "intro":
		var sub := str(level_info.get("subtitle", ""))
		if level_info.has("district"):
			sub += "  ·  " + str(level_info["district"])
		title_card = {"subtitle": sub, "title": level_info.get("title", ""), "tagline": level_info.get("tagline", "")}
	director.begin()
	dialogue_box.play(lines, title_card)
	await dialogue_box.finished
	await director.end()

## Rival says a random line from taunts[kind] ("miss" or "streak").
func rival_taunt(kind: String) -> void:
	var taunts = dialogue.get("taunts", {})
	if not (taunts is Dictionary):
		return
	var pool = taunts.get(kind, [])
	if pool is Array and not pool.is_empty():
		speech_bubble.say(str(pool.pick_random()), opponent_char.character_name)

func on_player_missed() -> void:
	var now := Time.get_ticks_msec()
	if now - last_miss_taunt_ms >= MISS_TAUNT_COOLDOWN_MS and randf() < 0.6:
		last_miss_taunt_ms = now
		rival_taunt("miss")

func start_level() -> void:
	GameState.reset()
	all_hits.clear()
	last_miss_taunt_ms = -MISS_TAUNT_COOLDOWN_MS
	current_row_index = -1
	current_state = State.COUNT_IN
	count_in_done = false
	count_in_clicked = 0
	cued_tiles.clear()
	judge_log.clear()
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
			# Hit offsets come from tiles.json (via TileDefs), same as Tile/PatternGrid
			var tile_info: Dictionary = TileDefs.parse_tile(tiles_arr[c])
			var sub_hits: Array = tile_info["sub_hits"]

			var tile_start_beat = row_start_beat + float(c)
			for s in range(sub_hits.size()):
				var hit = GridHitData.new()
				hit.row_idx = r
				hit.col_idx = c
				hit.sub_idx = s
				hit.target_beat = tile_start_beat + float(sub_hits[s]["offset"])
				hit.target_dir = str(sub_hits[s]["dir"])
				hit.is_play_phase = is_play
				all_hits.append(hit)

				if is_play and hit.target_dir != "rest":
					total_player_prompts += 1
				if hit.target_beat > max_chart_beat:
					max_chart_beat = hit.target_beat

	GameState.total_expected_hits = total_player_prompts
	hud.set_instruction("GET READY! COUNT-IN: 1 2 3 4", false)

	Conductor.set_sfx_key(float(chart_data.get("sfx_key", 0)))
	var stream = Conductor.load_audio(audio_path)
	if stream:
		Conductor.start_song(stream, bpm, first_beat_offset_ms, music_start_sec)
	else:
		push_error("Audio not found: " + audio_path)

func restart_song() -> void:
	Conductor.stop_song()
	hud.results_panel.visible = false
	speech_bubble.modulate.a = 0.0
	start_level()

func _unhandled_input(event: InputEvent) -> void:
	if current_state != State.PLAYING:
		return

	if event.is_echo():
		return
	for dir in ARROW_ACTIONS:
		if event.is_action_pressed(ARROW_ACTIONS[dir]):
			get_viewport().set_input_as_handled()
			handle_arrow_input(dir)
			return

func handle_arrow_input(pressed_dir: String) -> void:
	# Fresh, smoothed clock read for this press (not last frame's value)
	var cur_beat = Conductor.get_input_beat()
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

	# Timing check: within Good window
	if best_hit != null and min_abs_offset_ms <= GOOD_WINDOW_MS:
		if pressed_dir == best_hit.target_dir:
			best_hit.is_hit = true
			judge_log.append(signed_offset_ms)
			var rating = "Perfect" if min_abs_offset_ms <= PERFECT_WINDOW_MS else "Good"
			GameState.register_hit(rating, signed_offset_ms)
			hud.show_judgment(rating, signed_offset_ms)
			Conductor.play_hit(pressed_dir, rating)
			player_char.trigger_direction(pressed_dir)
			if GameState.combo in STREAK_TAUNTS_AT:
				rival_taunt("streak")

			var tile = pattern_grid.get_tile(best_hit.row_idx, best_hit.col_idx)
			if tile:
				tile.mark_sub_hit(best_hit.sub_idx, rating)
		else:
			# Wrong arrow key pressed!
			GameState.register_hit("Stray", 0.0)
			hud.show_judgment("Stray", 0.0)
			Conductor.play_miss()
			player_char.trigger_miss()
			on_player_missed()
	else:
		# Stray arrow press
		GameState.register_hit("Stray", 0.0)
		hud.show_judgment("Stray", 0.0)
		Conductor.play_miss()
		player_char.trigger_miss()
		on_player_missed()

func _on_conductor_beat_hit(beat: int) -> void:
	if current_state == State.GAME_OVER or current_state == State.RESULTS:
		return

	# Gentle idle beat bounce
	opponent_char.bounce(6.0)
	player_char.bounce(6.0)

	# Count-in beats (0, 1, 2, 3)
	if beat < COUNT_IN_BEATS:
		hud.show_count_in(beat + 1) # the click itself is scheduled ahead in _on_conductor_tick
		return

	if current_state == State.COUNT_IN:
		current_state = State.PLAYING

func _on_conductor_tick(_song_time: float, beat_float: float) -> void:
	if current_state == State.GAME_OVER or current_state == State.RESULTS:
		return

	# Sounds are started early by the audio output latency so they are heard
	# in time with the music (which the clock already compensates for).
	var sound_beat: float = Conductor.audio_beat_float + Conductor.get_sfx_lead_beats()

	# Count-in clicks
	while count_in_clicked < COUNT_IN_BEATS and sound_beat >= float(count_in_clicked):
		count_in_clicked += 1
		Conductor.play_click()

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
	var cue_on: bool = GameState.show_press_cue
	var cue_lead_beats: float = CUE_LEAD_SEC / Conductor.crotchet
	var cues: Dictionary = {} # tile -> Array of { sub, remain (beats) }
	for hit in all_hits:
		if not hit.is_play_phase:
			# Sound: started ahead so it's heard on the beat
			if sound_beat >= hit.target_beat and not hit.played_listen:
				hit.played_listen = true
				if hit.target_dir != "rest":
					Conductor.play_hit(hit.target_dir)
			# Visuals: on the beat as heard (no calibration shift)
			if Conductor.audio_beat_float >= hit.target_beat and not hit.shown_listen:
				hit.shown_listen = true
				if hit.target_dir != "rest":
					opponent_char.trigger_direction(hit.target_dir)
				var tile = pattern_grid.get_tile(hit.row_idx, hit.col_idx)
				if tile:
					tile.pulse_listen(hit.sub_idx)
		else:
			if cue_on and not hit.is_hit and not hit.is_missed and hit.target_dir != "rest":
				var remain: float = hit.target_beat - beat_float
				if remain <= cue_lead_beats and remain >= -GOOD_WINDOW_MS / 1000.0 / Conductor.crotchet:
					var cue_tile = pattern_grid.get_tile(hit.row_idx, hit.col_idx)
					if cue_tile:
						if not cues.has(cue_tile):
							cues[cue_tile] = []
						cues[cue_tile].append({ "sub": hit.sub_idx, "remain": remain / cue_lead_beats, "dir": hit.target_dir })
			if not hit.is_hit and not hit.is_missed:
				var late_ms = (beat_float - hit.target_beat) * Conductor.crotchet * 1000.0
				if late_ms > GOOD_WINDOW_MS:
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
						on_player_missed()
						var tile = pattern_grid.get_tile(hit.row_idx, hit.col_idx)
						if tile:
							tile.mark_sub_hit(hit.sub_idx, "Miss")

	update_press_cues(cues)

	# Finish song when past final row
	if row_idx >= rows.size() and current_state == State.PLAYING:
		finish_song()

## Sends this frame's press cues to tiles and clears tiles that no longer have one.
func update_press_cues(cues: Dictionary) -> void:
	for t in cued_tiles:
		if is_instance_valid(t) and not cues.has(t):
			t.set_cues([])
	cued_tiles.clear()
	for t in cues:
		t.set_cues(cues[t])
		cued_tiles.append(t)

func finish_song() -> void:
	current_state = State.RESULTS
	Conductor.stop_song()
	update_press_cues({})
	pattern_grid.clear_active()
	var acc = GameState.get_accuracy()
	var rank = GameState.get_rank()
	GameState.record_level_completion(current_level_id, rank, GameState.score)
	await play_dialogue("win")
	if current_state != State.RESULTS:
		return
	hud.show_results(acc, rank, GameState.score, GameState.max_combo)

func _on_conductor_song_finished() -> void:
	if current_state == State.PLAYING:
		finish_song()

func _on_player_died() -> void:
	current_state = State.GAME_OVER
	Conductor.stop_song()
	var lose_lines = dialogue.get("lose", [])
	if lose_lines is Array and not lose_lines.is_empty():
		var line = lose_lines.pick_random()
		if line is Dictionary:
			speech_bubble.say(str(line.get("text", "")), str(line.get("speaker", "")), 0.0)

func _on_menu_requested() -> void:
	Conductor.stop_song()
	get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")
