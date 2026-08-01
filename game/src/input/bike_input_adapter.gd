extends Node
class_name BikeInputAdapter

signal device_changed(device_id: int, device_name: String)

@export var preferred_device_name := "ftms2pad"
@export var steer_axis := JOY_AXIS_LEFT_X
@export var throttle_axis := JOY_AXIS_LEFT_Y
@export var joy_deadzone := 0.08
@export var ftms_profile_inverts_y := true

const DEFAULT_KEY_BINDINGS := {
	"bike_steer_left": [KEY_A, KEY_LEFT],
	"bike_steer_right": [KEY_D, KEY_RIGHT],
	"bike_pedal": [KEY_W, KEY_UP],
	"bike_brake": [KEY_S, KEY_DOWN],
	"bike_accept": [KEY_SPACE, KEY_ENTER],
	"bike_decline": [KEY_Q, KEY_BACKSPACE],
	"bike_reset": [KEY_R],
	"bike_menu": [KEY_ESCAPE],
}
const DEFAULT_JOY_BINDINGS := {
	"bike_accept": JOY_BUTTON_A,
	"bike_decline": JOY_BUTTON_X,
	"bike_brake": JOY_BUTTON_B,
	"bike_reset": JOY_BUTTON_Y,
	"bike_menu": JOY_BUTTON_START,
}

var _device_id := -1
var _device_name := "keyboard"
var _scan_cooldown := 0.0
var _accept_down_last_tick := false
var _accept_just_pressed := false
var _decline_down_last_tick := false
var _decline_just_pressed := false
var _reset_down_last_tick := false
var _reset_just_pressed := false


func _ready() -> void:
	_ensure_default_actions()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_select_device()


func _physics_process(delta: float) -> void:
	_scan_cooldown -= delta
	if _scan_cooldown <= 0.0:
		_scan_cooldown = 1.0
		_select_device()

	var accept_down := Input.is_action_pressed("bike_accept")
	_accept_just_pressed = accept_down and not _accept_down_last_tick
	_accept_down_last_tick = accept_down

	var decline_down := Input.is_action_pressed("bike_decline")
	_decline_just_pressed = decline_down and not _decline_down_last_tick
	_decline_down_last_tick = decline_down

	var reset_down := Input.is_action_pressed("bike_reset")
	_reset_just_pressed = reset_down and not _reset_down_last_tick
	_reset_down_last_tick = reset_down


func get_steer() -> float:
	var keyboard := Input.get_axis("bike_steer_left", "bike_steer_right")
	if not is_zero_approx(keyboard):
		return keyboard
	if _device_id < 0:
		return 0.0
	return _with_deadzone(Input.get_joy_axis(_device_id, steer_axis))


func get_throttle() -> float:
	if Input.is_action_pressed("bike_pedal"):
		return 1.0
	if _device_id < 0:
		return 0.0

	var raw_y := Input.get_joy_axis(_device_id, throttle_axis)
	if is_ftms_device():
		# ftms2pad emits its normalized 0..1 signal across a signed axis.
		# With the supplied inverted profile, rest is +1 and max effort is -1.
		return map_ftms_throttle(raw_y, ftms_profile_inverts_y)

	# A normal pad uses forward on the left stick for development.
	return clampf(-raw_y, 0.0, 1.0)


func get_brake() -> float:
	if Input.is_action_pressed("bike_brake"):
		return 1.0
	return 0.0


func is_accept_just_pressed() -> bool:
	return _accept_just_pressed


func is_decline_just_pressed() -> bool:
	return _decline_just_pressed


func is_reset_just_pressed() -> bool:
	return _reset_just_pressed


func is_ftms_device() -> bool:
	return _device_id >= 0 and preferred_device_name.to_lower() in _device_name.to_lower()


func get_device_id() -> int:
	return _device_id


func get_device_name() -> String:
	return _device_name


func rebind_keyboard_action(action: StringName, physical_keycode: Key) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = physical_keycode
	InputMap.action_add_event(action, key_event)


func get_keyboard_binding(action: StringName) -> Key:
	if not InputMap.has_action(action):
		return KEY_NONE
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.physical_keycode
	return KEY_NONE


func get_debug_snapshot() -> Dictionary:
	var raw_x := 0.0
	var raw_y := 0.0
	if _device_id >= 0:
		raw_x = Input.get_joy_axis(_device_id, steer_axis)
		raw_y = Input.get_joy_axis(_device_id, throttle_axis)
	return {
		"device_id": _device_id,
		"device_name": _device_name,
		"is_ftms": is_ftms_device(),
		"raw_x": raw_x,
		"raw_y": raw_y,
		"steer": get_steer(),
		"throttle": get_throttle(),
		"brake": get_brake(),
	}


static func map_ftms_throttle(raw_y: float, profile_inverts_y: bool) -> float:
	if profile_inverts_y:
		return clampf((1.0 - raw_y) * 0.5, 0.0, 1.0)
	return clampf((raw_y + 1.0) * 0.5, 0.0, 1.0)


func _with_deadzone(value: float) -> float:
	if absf(value) <= joy_deadzone:
		return 0.0
	return signf(value) * (absf(value) - joy_deadzone) / (1.0 - joy_deadzone)


func _select_device() -> void:
	var connected := Input.get_connected_joypads()
	var selected := -1
	for candidate in connected:
		var candidate_name := Input.get_joy_name(candidate)
		if preferred_device_name.to_lower() in candidate_name.to_lower():
			selected = candidate
			break
	if selected < 0 and not connected.is_empty():
		selected = connected[0]

	var selected_name := "keyboard"
	if selected >= 0:
		selected_name = Input.get_joy_name(selected)
	if selected == _device_id and selected_name == _device_name:
		return
	_device_id = selected
	_device_name = selected_name
	device_changed.emit(_device_id, _device_name)


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_select_device()


func _ensure_default_actions() -> void:
	for action: StringName in DEFAULT_KEY_BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode: Key in DEFAULT_KEY_BINDINGS[action]:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = keycode
			InputMap.action_add_event(action, key_event)
	for action: StringName in DEFAULT_JOY_BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var has_joy_event := false
		for existing in InputMap.action_get_events(action):
			if existing is InputEventJoypadButton:
				has_joy_event = true
		if not has_joy_event:
			var joy_event := InputEventJoypadButton.new()
			joy_event.button_index = DEFAULT_JOY_BINDINGS[action]
			InputMap.action_add_event(action, joy_event)
