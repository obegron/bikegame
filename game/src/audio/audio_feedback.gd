extends Node

@export var game_path: NodePath
@export var player_path: NodePath
@export var weather_path: NodePath

@onready var _game = get_node(game_path)
@onready var _player = get_node(player_path)
@onready var _weather = get_node_or_null(weather_path)

var _audio_player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _sample_rate := 22050.0
var _phase := 0.0
var _frequency := 0.0
var _samples_remaining := 0
var _queued_tones: Array[Vector2] = []
var _thunder_delay_samples := 0
var _thunder_samples_remaining := 0
var _thunder_total_samples := 1
var _thunder_phase := 0.0
var _thunder_noise := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = _sample_rate
	generator.buffer_length = 0.15
	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = generator
	_audio_player.volume_db = -13.0
	add_child(_audio_player)
	_audio_player.play()
	_playback = _audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	_rng.randomize()
	_game.delivery_state_changed.connect(_on_state_changed)
	_game.delivery_result_available.connect(_on_result)
	_player.obstacle_hit.connect(_on_obstacle_hit)
	if _weather != null and _weather.has_signal("lightning_struck"):
		_weather.lightning_struck.connect(_on_lightning)


func _process(_delta: float) -> void:
	if _playback == null:
		return
	if _samples_remaining <= 0 and not _queued_tones.is_empty():
		var tone: Vector2 = _queued_tones.pop_front()
		_frequency = tone.x
		_samples_remaining = int(tone.y * _sample_rate)
	var available: int = _playback.get_frames_available()
	for _index in available:
		var sample := 0.0
		if _samples_remaining > 0:
			var envelope := minf(1.0, float(_samples_remaining) / (_sample_rate * 0.025))
			sample = sin(_phase) * 0.18 * envelope
			_phase = fposmod(_phase + TAU * _frequency / _sample_rate, TAU)
			_samples_remaining -= 1
		if _thunder_delay_samples > 0:
			_thunder_delay_samples -= 1
		elif _thunder_samples_remaining > 0:
			var progress := (
				1.0
				- float(_thunder_samples_remaining) / float(_thunder_total_samples)
			)
			var envelope := minf(1.0, progress * 18.0) * pow(
				float(_thunder_samples_remaining) / float(_thunder_total_samples),
				1.45
			)
			_thunder_noise = lerpf(
				_thunder_noise,
				_rng.randf_range(-1.0, 1.0),
				0.022
			)
			_thunder_phase = fposmod(
				_thunder_phase + TAU * 47.0 / _sample_rate,
				TAU
			)
			sample += (
				_thunder_noise * 0.34 + sin(_thunder_phase) * 0.1
			) * envelope
			_thunder_samples_remaining -= 1
		_playback.push_frame(Vector2(sample, sample))


func _exit_tree() -> void:
	if _audio_player != null:
		_audio_player.stop()
		_audio_player.stream = null
	_playback = null


func _queue_tone(frequency: float, duration: float) -> void:
	_queued_tones.append(Vector2(frequency, duration))


func _on_state_changed() -> void:
	_queue_tone(540.0, 0.08)


func _on_result(_result: Dictionary) -> void:
	_queue_tone(720.0, 0.1)
	_queue_tone(900.0, 0.14)


func _on_obstacle_hit(_total: int) -> void:
	_queue_tone(145.0, 0.12)


func _on_lightning() -> void:
	_thunder_delay_samples = int(_rng.randf_range(0.45, 1.2) * _sample_rate)
	_thunder_total_samples = int(2.4 * _sample_rate)
	_thunder_samples_remaining = _thunder_total_samples
