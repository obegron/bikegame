extends CanvasLayer

@export var input_adapter_path: NodePath
@export var player_path: NodePath

@onready var _adapter: BikeInputAdapter = get_node(input_adapter_path) as BikeInputAdapter
@onready var _player: BikeController = get_node(player_path) as BikeController
@onready var _telemetry: Label = $Panel/Margin/VBox/Telemetry
@onready var _accept_status: Label = $Panel/Margin/VBox/AcceptStatus

var _f3_down_last_frame := false
var _accept_flash_seconds := 0.0


func _process(delta: float) -> void:
	var f3_down := Input.is_physical_key_pressed(KEY_F3)
	if f3_down and not _f3_down_last_frame:
		$Panel.visible = not $Panel.visible
	_f3_down_last_frame = f3_down

	if _adapter.is_accept_just_pressed():
		_accept_flash_seconds = 0.4
	_accept_flash_seconds = maxf(0.0, _accept_flash_seconds - delta)

	var state := _adapter.get_debug_snapshot()
	_telemetry.text = (
		"Input: %s%s\nRaw axes:  X %+0.3f   Y %+0.3f\nActions:   steer %+0.3f   throttle %0.3f   brake %0.1f\nBike:      %0.1f km/h   turn %+0.2f rad/s   collisions %d"
		% [
			state.device_name,
			" (ftms2pad)" if state.is_ftms else "",
			state.raw_x,
			state.raw_y,
			state.steer,
			state.throttle,
			state.brake,
			_player.get_speed_kph(),
			_player.get_turn_rate(),
			_player.get_collision_count(),
		]
	)
	_accept_status.text = "ACCEPT" if _accept_flash_seconds > 0.0 else "Space/Enter: accept placeholder"
