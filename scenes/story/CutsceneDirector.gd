extends Node
## Moves a Camera2D and animates characters during story scenes.
## Listens to DialogueBox.line_started. Optional per-line fields in dialogue JSON:
##   "pose":  "cheer", "shock", "left", "right", "up", "down"  (speaker's pose)
##   "shake": true  (screen shake)          "flash": "#RRGGBB"  (handled by DialogueBox)
##   "shot":  "wide", "tower", "close"      (override the camera framing)

const TOWER_FOCUS := Vector2(640, 175)
const MOVE_TIME: float = 0.7

var camera: Camera2D
var dialogue_box: Control
var player_char: Control
var opponent_char: Control
var rival_speakers: Array = [] # speaker names that belong to the opponent character
var fade_nodes: Array = []     # HUD bits hidden during scenes

var talker: Control = null
var talk_timer: float = 0.0
var cam_tween: Tween
var shake_time: float = 0.0
var shake_strength: float = 0.0
var active: bool = false

# Gameplay turn camera: pans toward whoever's turn it is.
# Only the world (background + characters) moves; the UI layer stays fixed.
const PLAY_ZOOM: float = 1.06
const PLAY_PAN_TIME: float = 0.5
var song: Node = null
var world_layer: CanvasLayer = null
var turn_target: String = ""

func setup(cam: Camera2D, box: Control, player: Control, opponent: Control, rivals: Array, hide_during_scenes: Array) -> void:
	camera = cam
	dialogue_box = box
	player_char = player
	opponent_char = opponent
	rival_speakers = rivals
	fade_nodes = hide_during_scenes
	dialogue_box.line_started.connect(_on_line)
	_split_world_layer()

## Moves the characters onto a layer that follows the
## camera, and pins the HUD / grid layer so the camera can never move the UI.
func _split_world_layer() -> void:
	song = get_parent()
	var ui_layer := player_char.get_parent() as CanvasLayer
	if ui_layer == null:
		return
	world_layer = CanvasLayer.new()
	world_layer.name = "WorldLayer"
	world_layer.layer = ui_layer.layer
	world_layer.follow_viewport_enabled = true
	song.add_child(world_layer)
	ui_layer.layer = world_layer.layer + 1
	ui_layer.follow_viewport_enabled = false
	# The taunt bubble stays on the fixed UI layer so a pan can never push it off-screen.
	for n in [opponent_char, player_char]:
		if n is Node and n.get_parent() == ui_layer:
			n.reparent(world_layer, false)

func begin() -> void:
	active = true
	turn_target = "cutscene"
	camera.enabled = true
	for n in fade_nodes:
		create_tween().tween_property(n, "modulate:a", 0.0, 0.35)
	# Start slightly pushed in, then ease out to the wide shot
	_frame(Vector2(640, 380), 1.12, 0.0)
	_frame(Vector2(640, 360), 1.0, 2.2)

func end() -> void:
	active = false
	talker = null
	turn_target = ""
	_frame(Vector2(640, 360), 1.0, 0.5)
	for c in [player_char, opponent_char]:
		create_tween().tween_property(c, "modulate", Color.WHITE, 0.4)
	for n in fade_nodes:
		create_tween().tween_property(n, "modulate:a", 1.0, 0.5)
	await get_tree().create_timer(0.5).timeout
	camera.offset = Vector2.ZERO

func _char_center(c: Control) -> Vector2:
	return c.position + c.size * Vector2(0.5, 0.6)

func _on_line(line: Dictionary) -> void:
	var speaker: String = str(line.get("speaker", ""))
	var shot: String = str(line.get("shot", ""))
	var target: Control = null
	if speaker == "Clap":
		target = player_char
	elif speaker in rival_speakers:
		target = opponent_char
	talker = target

	# Spotlight the talker, dim whoever isn't talking
	for c in [player_char, opponent_char]:
		var col := Color.WHITE if (target == null or c == target) else Color(0.55, 0.55, 0.65)
		create_tween().tween_property(c, "modulate", col, 0.3)

	# Camera framing
	if shot == "wide" or (shot == "" and speaker == "Narrator"):
		_frame(Vector2(640, 360), 1.0, MOVE_TIME * 1.3)
	elif shot == "tower" or (shot == "" and speaker == "The Metronome" and target == null):
		_frame(TOWER_FOCUS, 1.55, MOVE_TIME)
		shake(5.0, 0.35)
	elif target != null:
		var zoom := 1.45 if shot == "close" else 1.28
		_frame(_char_center(target), zoom, MOVE_TIME)
	else:
		# Off-screen speaker (e.g. Beats in later stages): gentle push-in on the stage
		_frame(Vector2(640, 400), 1.08, MOVE_TIME)

	# Poses
	if target != null:
		match str(line.get("pose", "")):
			"cheer": target.trigger_clap()
			"shock": target.trigger_miss()
			"left", "right", "up", "down": target.trigger_direction(str(line["pose"]))
			_: target.bounce(12.0)
	if line.get("shake", false):
		shake(12.0, 0.45)

## Frames `focus` at `zoom`, keeping the view inside the 1280x720 stage.
func _frame(focus: Vector2, zoom: float, time: float) -> void:
	var vp: Vector2 = camera.get_viewport_rect().size
	var view: Vector2 = vp / zoom
	var pos: Vector2 = focus - view / 2.0
	pos.x = clampf(pos.x, 0.0, maxf(0.0, vp.x - view.x))
	pos.y = clampf(pos.y, 0.0, maxf(0.0, vp.y - view.y))
	if cam_tween and cam_tween.is_valid():
		cam_tween.kill()
	if time <= 0.0:
		camera.position = pos
		camera.zoom = Vector2(zoom, zoom)
		return
	cam_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	cam_tween.tween_property(camera, "position", pos, time)
	cam_tween.tween_property(camera, "zoom", Vector2(zoom, zoom), time)

func shake(strength: float, time: float) -> void:
	shake_strength = strength
	shake_time = time

func _process(delta: float) -> void:
	if shake_time > 0.0:
		shake_time -= delta
		var s := shake_strength * clampf(shake_time / 0.4, 0.0, 1.0)
		camera.offset = Vector2(randf_range(-s, s), randf_range(-s, s))
	elif camera and camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO
	if not active and song != null:
		_update_turn_camera()

	# Talking bob while the text types out
	if active and talker != null and dialogue_box.typing:
		talk_timer -= delta
		if talk_timer <= 0.0:
			talk_timer = 0.2
			talker.bounce(5.0)

func _current_turn() -> String:
	var state = song.get("current_state")
	if state != song.State.PLAYING:
		return "center"
	var rows = song.get("rows")
	var idx = song.get("current_row_index")
	if not (rows is Array) or idx == null or idx < 0 or idx >= rows.size():
		return "center"
	var row = rows[idx]
	if row is Dictionary and str(row.get("phase", "listen")) == "play":
		return "player"
	return "rival"

func _update_turn_camera() -> void:
	var t := _current_turn()
	if t == turn_target:
		return
	turn_target = t
	var vp: Vector2 = camera.get_viewport_rect().size
	var spare_x: float = vp.x - vp.x / PLAY_ZOOM
	var spare_y: float = vp.y - vp.y / PLAY_ZOOM
	var pos := Vector2(spare_x * 0.5, spare_y * 0.5)
	var zoom := PLAY_ZOOM
	match t:
		"rival": pos.x = 0.0
		"player": pos.x = spare_x
		_:
			zoom = 1.0
			pos = Vector2.ZERO
	if cam_tween and cam_tween.is_valid():
		cam_tween.kill()
	cam_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	cam_tween.tween_property(camera, "position", pos, PLAY_PAN_TIME)
	cam_tween.tween_property(camera, "zoom", Vector2(zoom, zoom), PLAY_PAN_TIME)
