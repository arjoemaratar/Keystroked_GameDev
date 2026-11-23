extends "res://scenes/gameplay/Song.gd"
## Endless mode: back-to-back rounds against random rivals.
##
## Each round is one difficulty section (level 1-5) of a rival's stage chart,
## with its phrases shuffled and sometimes mirrored, and the stage's own music
## played from that section, so it stays on the beat. Difficulty rises every
## ENDLESS_ROUNDS_PER_TIER rounds and tops out at the stages' level 5, which is
## the same as the hardest part of the story, so it stays beatable. Harder
## (faster) rivals join the pool as the run goes on. Clearing a round heals.

const ROUNDS_PER_TIER: int = 2
const MAX_TIER: int = 5
const HEAL_PER_ROUND: float = 20.0
const BREAK_SEC: float = 1.6
# Which rivals can appear from which round (index into the pool order below)
const POOL_ORDER: Array[String] = ["tutorial", "week1", "week2", "week3", "week4", "finale"]
const POOL_UNLOCK_ROUND: Array[int] = [0, 0, 2, 4, 6, 8]

var stages: Dictionary = {}       # id -> { level, chart }
var round_index: int = 0
var last_rival: String = ""
var run_over: bool = false
var rng := RandomNumberGenerator.new()

func load_current_level() -> void:
	current_level_id = "endless"
	TileDefs.load_defs(tiles_path)
	rng.randomize()
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(LEVELS_PATH))
	if parsed is Array:
		for lvl in parsed:
			var id := str(lvl.get("id", ""))
			var chart_file := str(lvl.get("chart", ""))
			if id == "" or not FileAccess.file_exists(chart_file):
				continue
			var chart = JSON.parse_string(FileAccess.get_file_as_string(chart_file))
			if chart is Dictionary:
				stages[id] = { "level": lvl, "chart": chart }
	level_info = { "title": "Endless", "subtitle": "Endless" }
	prepare_round()

func current_tier() -> int:
	return mini(MAX_TIER, 1 + floori(float(round_index) / ROUNDS_PER_TIER))

func pick_rival() -> String:
	var pool: Array[String] = []
	for i in range(POOL_ORDER.size()):
		if round_index >= POOL_UNLOCK_ROUND[i] and stages.has(POOL_ORDER[i]):
			pool.append(POOL_ORDER[i])
	if pool.size() > 1:
		pool.erase(last_rival)
	return pool[rng.randi_range(0, pool.size() - 1)]

## Picks the next rival and builds this round's rows, music position and look.
func prepare_round() -> void:
	var id := pick_rival()
	last_rival = id
	var stage: Dictionary = stages[id]
	var chart: Dictionary = stage["chart"]
	chart_data = chart # for sfx_key etc.
	var lvl: Dictionary = stage["level"]
	var tier := current_tier()

	bpm = float(chart.get("bpm", 100.0))
	audio_path = str(chart.get("audio", ""))
	var all_rows: Array = chart.get("rows", [])

	# Rows of this tier's section (listen/play pairs)
	var first := -1
	var pairs: Array = []
	for r in range(all_rows.size()):
		if int(all_rows[r].get("level", 1)) == tier:
			if first < 0:
				first = r
			if all_rows[r].get("phase", "") == "listen" and r + 1 < all_rows.size():
				pairs.append([all_rows[r], all_rows[r + 1]])
	if first < 0: # chart without this tier: use its last section
		first = 0
		for r in range(0, all_rows.size() - 1, 2):
			pairs.append([all_rows[r], all_rows[r + 1]])

	# Shuffle phrase order and maybe mirror directions so rounds feel fresh
	pairs.shuffle()
	var mirror_lr := rng.randf() < 0.5
	var mirror_ud := rng.randf() < 0.5
	var rival_name := str(lvl.get("rival", "Rival"))
	rows = []
	for p in pairs:
		for row in p:
			var new_row: Dictionary = row.duplicate(true)
			new_row["tiles"] = mirror_tiles(row.get("tiles", []), mirror_lr, mirror_ud)
			var label := "ROUND %d · %s" % [round_index + 1, rival_name.to_upper()]
			new_row["instruction"] = label + (": WATCH!" if row.get("phase", "") == "listen" else ": YOUR TURN!")
			new_row["level"] = tier
			rows.append(new_row)

	# Play the stage's own track from the measure before this section, so the
	# count-in lands on the track's drum fill into the section.
	var beat_sec := 60.0 / bpm
	music_start_sec = float(first) * 4.0 * beat_sec
	first_beat_offset_ms = music_start_sec * 1000.0 + float(chart.get("first_beat_offset_ms", 0.0))

	var opp_type := str(lvl.get("rival_type", chart.get("opponent", "straight_man")))
	opponent_char.character_type = opp_type
	opponent_char.character_name = rival_name
	opponent_char.queue_redraw()

	# Rival taunts only (no story scenes in Endless)
	var full = StoryData.load_dialogue(str(lvl.get("dialogue", "")))
	dialogue = { "taunts": full.get("taunts", {}) } if full is Dictionary else {}

func mirror_tiles(tiles: Array, lr: bool, ud: bool) -> Array:
	var out: Array = []
	for t in tiles:
		var nt = t.duplicate(true) if t is Dictionary else { "type": str(t), "dir": "left" }
		var d := str(nt.get("dir", "left"))
		if lr and d == "left": d = "right"
		elif lr and d == "right": d = "left"
		elif ud and d == "up": d = "down"
		elif ud and d == "down": d = "up"
		nt["dir"] = d
		out.append(nt)
	return out

## Starts the current round. Score, combo and HP carry over between rounds.
func start_level() -> void:
	var keep := {
		"score": GameState.score, "combo": GameState.combo, "max_combo": GameState.max_combo,
		"health": GameState.health, "p": GameState.hits_perfect, "g": GameState.hits_good, "m": GameState.hits_miss,
	}
	super.start_level()
	if round_index > 0:
		GameState.score = keep["score"]
		GameState.combo = keep["combo"]
		GameState.max_combo = keep["max_combo"]
		GameState.health = keep["health"]
		GameState.hits_perfect = keep["p"]
		GameState.hits_good = keep["g"]
		GameState.hits_miss = keep["m"]
		GameState.stats_changed.emit()

## Called by Song when the round's rows are done: next round instead of results.
func finish_song() -> void:
	if current_state != State.PLAYING:
		return
	current_state = State.RESULTS
	Conductor.stop_song()
	update_press_cues({})
	pattern_grid.clear_active()

	var cleared := round_index + 1
	GameState.health = minf(GameState.max_health, GameState.health + HEAL_PER_ROUND)
	GameState.stats_changed.emit()
	round_index += 1
	save_best(cleared)

	prepare_round()
	hud.set_instruction("ROUND %d CLEARED! +%d HP   NEXT: %s" % [cleared, int(HEAL_PER_ROUND), opponent_char.character_name.to_upper()], true)
	speech_bubble.say("Round %d! Difficulty %d/%d" % [round_index + 1, current_tier(), MAX_TIER], "ENDLESS")
	await get_tree().create_timer(BREAK_SEC).timeout
	if current_state != State.RESULTS or run_over or not is_inside_tree():
		return
	start_level()

func save_best(rounds_cleared: int) -> void:
	var changed := false
	if rounds_cleared > int(GameState.best_scores.get("endless_rounds", 0)):
		GameState.best_scores["endless_rounds"] = rounds_cleared
		changed = true
	if GameState.score > int(GameState.best_scores.get("endless", 0)):
		GameState.best_scores["endless"] = GameState.score
		changed = true
	if changed:
		GameState.save_game()

func _on_player_died() -> void:
	run_over = true
	super._on_player_died()
	save_best(round_index)
	var best := int(GameState.best_scores.get("endless_rounds", 0))
	hud.res_rank_label.text = "ROUND %d  (BEST %d)" % [round_index + 1, best]

func restart_song() -> void:
	# Retry = a brand new run
	Conductor.stop_song()
	hud.results_panel.visible = false
	speech_bubble.modulate.a = 0.0
	run_over = false
	round_index = 0
	last_rival = ""
	GameState.reset()
	prepare_round()
	start_level()

func _on_menu_requested() -> void:
	run_over = true
	Conductor.stop_song()
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
