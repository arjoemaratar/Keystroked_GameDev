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

# Heard-audio beat WITHOUT the player's calibration offset. Use this to schedule
# sounds against the music; use current_beat_float / get_input_beat() for judging.
var audio_beat_float: float = 0.0

# Smoothed audio clock. get_playback_position() only advances once per audio mix
# chunk, so the raw value stutters by several ms per frame. We advance a clock
# with the system timer and gently steer it toward the audio position.
const CLOCK_RESYNC_SEC: float = 0.15   # snap only on a real jump (seek, device stall)
const CLOCK_CORRECTION: float = 0.1    # fraction of the error corrected per frame
var _clock_time: float = 0.0           # heard time in seconds (no calibration)
var _clock_ticks_usec: int = 0         # Time.get_ticks_usec() when _clock_time was set
var _clock_started: bool = false
var debug_resyncs: int = 0 # how often the clock had to snap (for diagnostics)

var music_player: AudioStreamPlayer
var click_player: AudioStreamPlayer
var clap_player: AudioStreamPlayer
var miss_player: AudioStreamPlayer
var perfect_player: AudioStreamPlayer # sparkle layered on PERFECT hits

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
	miss_player.max_polyphony = 2
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
		# Fast patterns (S4, SE/ES) retrigger before the previous hit ends;
		# polyphony lets them overlap instead of cutting each other off.
		p.max_polyphony = 4
		add_child(p)
		dir_hit_players[d] = p
		var sfx = load_audio("res://assets/audio/hit_%s.wav" % d)
		if sfx:
			p.stream = sfx
			dir_hit_sfx[d] = sfx

	perfect_player = AudioStreamPlayer.new()
	perfect_player.max_polyphony = 4
	perfect_player.volume_db = -3.0
	add_child(perfect_player)
	perfect_player.stream = load_audio("res://assets/audio/hit_perfect.wav")

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

## start_at_sec: where in the audio to begin playing (Endless mode starts tracks
## mid-song). offset_ms is still measured from the start of the file.
func start_song(stream: AudioStream, new_bpm: float, offset_ms: float = 0.0, start_at_sec: float = 0.0) -> void:
	bpm = new_bpm
	crotchet = 60.0 / bpm
	first_beat_offset_sec = offset_ms / 1000.0
	current_beat = -1
	current_measure = -1
	current_beat_float = 0.0
	audio_beat_float = 0.0
	song_time = 0.0
	_clock_started = false

	music_player.stream = stream
	music_player.play(start_at_sec)
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

## Lane note for a hit. rating "Perfect" adds the sparkle layer on top;
## rival notes and "Good" hits play the lane note alone.
func play_hit(direction: String, rating: String = "") -> void:
	if rating == "Perfect" and perfect_player and perfect_player.stream:
		perfect_player.play()
	if dir_hit_players.has(direction):
		var p: AudioStreamPlayer = dir_hit_players[direction]
		if p and p.stream:
			p.play()
			return
	play_clap()

## Transposes the hit sounds into a stage's key (semitones from C).
func set_sfx_key(semitones: float) -> void:
	var scale := pow(2.0, semitones / 12.0)
	for d in dir_hit_players:
		dir_hit_players[d].pitch_scale = scale
	if perfect_player:
		perfect_player.pitch_scale = scale

func play_miss() -> void:
	if miss_player and miss_player.stream:
		miss_player.play()

func _process(_delta: float) -> void:
	if not is_playing or not music_player.playing:
		return

	_update_clock()

	song_time = _clock_time - (GameState.calibration_offset_ms / 1000.0)
	current_beat_float = (song_time - first_beat_offset_sec) / crotchet
	audio_beat_float = (_clock_time - first_beat_offset_sec) / crotchet

	# Emit every beat crossed (a long frame could skip one)
	var beat_floor = int(floor(current_beat_float))
	while current_beat < beat_floor:
		current_beat += 1
		beat_hit.emit(current_beat)

		var measure_floor = int(floor(float(current_beat) / 4.0))
		if measure_floor > current_measure:
			current_measure = measure_floor
			measure_hit.emit(current_measure)

	tick.emit(song_time, current_beat_float)

## Raw heard time of the music (seconds), stepping once per audio mix chunk.
func _raw_audio_time() -> float:
	return music_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()

func _update_clock() -> void:
	var now := Time.get_ticks_usec()
	var raw := _raw_audio_time()
	if not _clock_started:
		_clock_time = raw
		_clock_started = true
	else:
		var predicted := _clock_time + float(now - _clock_ticks_usec) / 1000000.0 * music_player.pitch_scale
		var err := raw - predicted
		if absf(err) > CLOCK_RESYNC_SEC:
			debug_resyncs += 1
			_clock_time = raw
		else:
			# Never run backwards: a beat that was judged must stay judged.
			_clock_time = maxf(_clock_time, predicted + err * CLOCK_CORRECTION)
	_clock_ticks_usec = now

## Beat position for judging a key press that is being handled right now.
## Input is only polled once per frame, so the press really happened somewhere
## between the last frame and now; the midpoint is the unbiased estimate.
func get_input_beat() -> float:
	if not is_playing or not _clock_started:
		return current_beat_float
	var since_frame := float(Time.get_ticks_usec() - _clock_ticks_usec) / 1000000.0
	var t := _clock_time + since_frame * 0.5 * music_player.pitch_scale
	return (t - GameState.calibration_offset_ms / 1000.0 - first_beat_offset_sec) / crotchet

## How far ahead (in beats) a sound must be started so it is heard on time:
## output latency plus about half a frame (sounds start on the next frame).
func get_sfx_lead_beats() -> float:
	var frame := 1.0 / maxf(Engine.get_frames_per_second(), 30.0)
	return (AudioServer.get_output_latency() + frame * 0.5) / crotchet

func _on_music_finished() -> void:
	is_playing = false
	song_finished.emit()
