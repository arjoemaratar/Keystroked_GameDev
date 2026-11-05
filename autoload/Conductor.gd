extends Node

signal beat_hit(beat: int)
signal measure_hit(measure: int)
signal tick(song_time: float, beat_float: float)
signal song_finished

var bpm: float = 100.0
var crotchet: float = 0.6
var song_time: float = 0.0
var current_beat: int = -1
var current_beat_float: float = 0.0
var current_measure: int = -1
var first_beat_offset_sec: float = 0.0
var is_playing: bool = false

var music_player: AudioStreamPlayer
var click_player: AudioStreamPlayer
var clap_player: AudioStreamPlayer
var miss_player: AudioStreamPlayer

var dir_hit_players: Dictionary = {}
var dir_hit_sfx: Dictionary = {}

var click_sfx: AudioStream
var clap_sfx: AudioStream
var miss_sfx: AudioStream

func _ready() -> void:
	process_priority = -1

	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)

	click_player = AudioStreamPlayer.new()
	add_child(click_player)

	clap_player = AudioStreamPlayer.new()
	add_child(clap_player)

	miss_player = AudioStreamPlayer.new()
	add_child(miss_player)

	click_sfx = load_audio("res://assets/audio/click.wav")
	click_player.stream = click_sfx

	clap_sfx = load_audio("res://assets/audio/clap.wav")
	clap_player.stream = clap_sfx

	miss_sfx = load_audio("res://assets/audio/miss.wav")
	miss_player.stream = miss_sfx

	var dirs = ["left", "down", "up", "right"]
	for d in dirs:
		var p = AudioStreamPlayer.new()
		add_child(p)
		dir_hit_players[d] = p
		var sfx = load_audio("res://assets/audio/hit_%s.wav" % d)
		if sfx:
			p.stream = sfx
			dir_hit_sfx[d] = sfx

func load_audio(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			return res

	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var total_len = file.get_length()
			if total_len > 44:
				file.seek(44)
				var pcm = file.get_buffer(total_len - 44)
				var stream = AudioStreamWAV.new()
				stream.format = AudioStreamWAV.FORMAT_16_BITS
				stream.mix_rate = 44100
				stream.stereo = false
				stream.data = pcm
				return stream
	return null

func start_song(stream: AudioStream, new_bpm: float, offset_ms: float = 0.0) -> void:
	bpm = new_bpm
	crotchet = 60.0 / bpm
	first_beat_offset_sec = offset_ms / 1000.0
	current_beat = -1
	current_measure = -1
	current_beat_float = 0.0
	song_time = 0.0

	music_player.stream = stream
	music_player.play()
	is_playing = true

func stop_song() -> void:
	is_playing = false
	if music_player.playing:
		music_player.stop()

func play_click() -> void:
	if click_player and click_player.stream:
		click_player.play()

func play_clap() -> void:
	if clap_player and clap_player.stream:
		clap_player.play()

func play_hit(direction: String) -> void:
	if dir_hit_players.has(direction):
		var p: AudioStreamPlayer = dir_hit_players[direction]
		if p and p.stream:
			p.play()
			return
	play_clap()

func play_miss() -> void:
	if miss_player and miss_player.stream:
		miss_player.play()

func _process(_delta: float) -> void:
	if not is_playing or not music_player.playing:
		return

	var time_since_mix = AudioServer.get_time_since_last_mix()
	var latency = AudioServer.get_output_latency()
	var raw_playback = music_player.get_playback_position()

	song_time = (raw_playback + time_since_mix - latency) - (GameState.calibration_offset_ms / 1000.0)
	current_beat_float = (song_time - first_beat_offset_sec) / crotchet

	var beat_floor = int(floor(current_beat_float))
	if beat_floor > current_beat:
		current_beat = beat_floor
		beat_hit.emit(current_beat)

		var measure_floor = int(floor(float(current_beat) / 4.0))
		if measure_floor > current_measure:
			current_measure = measure_floor
			measure_hit.emit(current_measure)

	tick.emit(song_time, current_beat_float)

func _on_music_finished() -> void:
	is_playing = false
	song_finished.emit()
