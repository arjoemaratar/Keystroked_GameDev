extends Node

signal stats_changed
signal player_died

var score: int = 0
var combo: int = 0
var max_combo: int = 0
var health: float = 100.0
var max_health: float = 100.0

var hits_perfect: int = 0
var hits_good: int = 0
var hits_miss: int = 0
var total_expected_hits: int = 0

var calibration_offset_ms: float = 0.0

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
			health = clampf(health + 2.0, 0.0, max_health)
			hits_perfect += 1
		"Good":
			score += 100
			combo += 1
			health = clampf(health + 0.5, 0.0, max_health)
			hits_good += 1
		"Miss":
			combo = 0
			health = clampf(health - 8.0, 0.0, max_health)
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
