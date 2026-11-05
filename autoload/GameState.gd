extends Node

signal stats_changed
signal player_died
signal level_unlocked(level_id: String)

var score: int = 0
var combo: int = 0
var max_combo: int = 0
var health: float = 100.0
var max_health: float = 100.0

var hits_perfect: int = 0
var hits_good: int = 0
var hits_miss: int = 0
var total_expected_hits: int = 0

# Settings
var calibration_offset_ms: float = 0.0
var scroll_speed: float = 1.0

# Progression
var selected_level_id: String = "tutorial"
var unlocked_levels: Array[String] = ["tutorial", "week1"]
var completed_levels: Dictionary = {} # level_id -> rank string
var best_scores: Dictionary = {} # level_id -> int score

const SAVE_PATH = "user://savegame.json"

func _ready() -> void:
	load_game()

func reset() -> void:
	score = 0
	combo = 0
	max_combo = 0
	health = 100.0
	hits_perfect = 0
	hits_good = 0
	hits_miss = 0
	total_expected_hits = 0
	stats_changed.emit()

func register_hit(rating: String, _offset_ms: float = 0.0) -> void:
	match rating:
		"Perfect":
			score += 300
			combo += 1
			health = clampf(health + 2.5, 0.0, max_health)
			hits_perfect += 1
		"Good":
			score += 100
			combo += 1
			health = clampf(health + 1.0, 0.0, max_health)
			hits_good += 1
		"Miss":
			combo = 0
			health = clampf(health - 7.0, 0.0, max_health)
			hits_miss += 1
		"Stray":
			combo = 0
			health = clampf(health - 4.0, 0.0, max_health)

	if combo > max_combo:
		max_combo = combo

	stats_changed.emit()

	if health <= 0.0:
		player_died.emit()

func get_accuracy() -> float:
	var total = hits_perfect + hits_good + hits_miss
	if total == 0:
		return 100.0
	var weighted = (hits_perfect * 1.0) + (hits_good * 0.6)
	return clampf((weighted / float(total)) * 100.0, 0.0, 100.0)

func get_rank() -> String:
	var acc = get_accuracy()
	if acc >= 95.0:
		return "S"
	elif acc >= 85.0:
		return "A"
	elif acc >= 70.0:
		return "B"
	else:
		return "C"

func is_level_unlocked(level_id: String) -> bool:
	return level_id in unlocked_levels

func unlock_level(level_id: String) -> void:
	if level_id not in unlocked_levels:
		unlocked_levels.append(level_id)
		level_unlocked.emit(level_id)
		save_game()

func record_level_completion(level_id: String, rank: String, final_score: int) -> void:
	var prev_rank = completed_levels.get(level_id, "")
	# Higher rank priority: S > A > B > C > F
	if prev_rank == "" or rank_value(rank) > rank_value(prev_rank):
		completed_levels[level_id] = rank

	var prev_score = best_scores.get(level_id, 0)
	if final_score > prev_score:
		best_scores[level_id] = final_score

	# Unlock next stages automatically
	if level_id == "tutorial":
		unlock_level("week1")
	elif level_id == "week1":
		unlock_level("week2")
	elif level_id == "week2":
		unlock_level("week3")
	elif level_id == "week3":
		unlock_level("week4")
	elif level_id == "week4":
		unlock_level("finale")

	save_game()

func rank_value(r: String) -> int:
	match r:
		"S": return 4
		"A": return 3
		"B": return 2
		"C": return 1
		_: return 0

func get_best_rank(level_id: String) -> String:
	return completed_levels.get(level_id, "-")

func get_best_score(level_id: String) -> int:
	return best_scores.get(level_id, 0)

func save_game() -> void:
	var data = {
		"unlocked_levels": unlocked_levels,
		"completed_levels": completed_levels,
		"best_scores": best_scores,
		"calibration_offset_ms": calibration_offset_ms,
		"scroll_speed": scroll_speed
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text = file.get_as_text()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		if parsed.has("unlocked_levels"):
			unlocked_levels.clear()
			for lvl in parsed["unlocked_levels"]:
				unlocked_levels.append(str(lvl))
		if parsed.has("completed_levels"):
			completed_levels = parsed["completed_levels"]
		if parsed.has("best_scores"):
			best_scores = parsed["best_scores"]
		if parsed.has("calibration_offset_ms"):
			calibration_offset_ms = float(parsed["calibration_offset_ms"])
		if parsed.has("scroll_speed"):
			scroll_speed = float(parsed["scroll_speed"])
