extends RefCounted
## Tile rhythm definitions loaded from tiles.json.
## Use via: const TileDefs = preload("res://scenes/gameplay/TileDefs.gd")
## Every place that needs a tile's hit offsets (judging, drawing, grid) goes
## through parse_tile() so they all agree.

const DEFAULT_PATH: String = "res://data/tiles.json"

static var _defs: Dictionary = {}
static var _loaded_path: String = ""

static func load_defs(path: String = DEFAULT_PATH) -> void:
	if path == "":
		path = DEFAULT_PATH
	if path == _loaded_path and not _defs.is_empty():
		return
	_loaded_path = path
	_defs = {}
	if not FileAccess.file_exists(path):
		push_warning("TileDefs: %s not found, using single-hit fallback for all tiles" % path)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		_defs = parsed
	else:
		push_warning("TileDefs: could not parse %s" % path)

static func _ensure_loaded() -> void:
	if _loaded_path == "":
		load_defs(DEFAULT_PATH)

static func has_type(t_type: String) -> bool:
	_ensure_loaded()
	return _defs.has(t_type)

## Beat offsets (0.0 to <1.0) of each hit inside the tile's beat.
static func get_hit_offsets(t_type: String) -> Array[float]:
	_ensure_loaded()
	var out: Array[float] = []
	if _defs.has(t_type):
		for h in _defs[t_type].get("hits", []):
			out.append(float(h))
	else:
		push_warning("TileDefs: unknown tile type '%s', treating as one quarter hit" % t_type)
		out.append(0.0)
	return out

static func get_symbol(t_type: String, fallback: String = "♩") -> String:
	_ensure_loaded()
	if _defs.has(t_type):
		return str(_defs[t_type].get("symbol", fallback))
	return fallback

static func is_rest(t_type: String) -> bool:
	return has_type(t_type) and get_hit_offsets(t_type).is_empty()

## Normalises a chart tile entry into { type, dir, sub_hits: [{offset, dir}] }.
## Accepts a Dictionary ({"type": "E2", "dir": "up", "sub_hits": [...]})
## or a plain String ("E2"), which defaults to direction "left".
static func parse_tile(t_data) -> Dictionary:
	var t_type: String = "Q"
	var t_dir: String = "left"
	var custom: Array = []

	if t_data is Dictionary:
		t_type = str(t_data.get("type", "Q"))
		t_dir = str(t_data.get("dir", "left"))
		custom = t_data.get("sub_hits", [])
	elif t_data is String:
		t_type = t_data
	else:
		push_warning("TileDefs: unexpected tile entry %s" % str(t_data))

	var sub_hits: Array = []
	if custom.size() > 0:
		for sh in custom:
			sub_hits.append({
				"offset": float(sh.get("offset", 0.0)),
				"dir": str(sh.get("dir", t_dir))
			})
	else:
		for off in get_hit_offsets(t_type):
			sub_hits.append({ "offset": off, "dir": t_dir })
		if sub_hits.is_empty():
			t_dir = "rest"

	return { "type": t_type, "dir": t_dir, "sub_hits": sub_hits }
