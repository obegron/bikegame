extends CanvasLayer

const SETTINGS_PATH := "user://settings.cfg"
const AchievementCatalog = preload("res://src/core/achievement_catalog.gd")
const REMAPPABLE_ACTIONS := {
	"bike_pedal": "Pedal",
	"bike_brake": "Brake",
	"bike_steer_left": "Steer left",
	"bike_steer_right": "Steer right",
	"bike_accept": "Accept order",
	"bike_decline": "Decline order",
	"bike_reset": "Reset position",
}

@export var input_adapter_path: NodePath
@export var player_path: NodePath
@export var clock_path: NodePath
@export var progression_path: NodePath
@export var multiplayer_path: NodePath

@onready var _adapter = get_node(input_adapter_path)
@onready var _player = get_node(player_path)
@onready var _clock = get_node(clock_path)
@onready var _progression = get_node(progression_path)
@onready var _multiplayer = get_node(multiplayer_path)
@onready var _overlay: Control = $Overlay
@onready var _lean_slider: HSlider = $Overlay/Center/Panel/Margin/VBox/LeanRow/LeanSlider
@onready var _day_slider: HSlider = $Overlay/Center/Panel/Margin/VBox/DayRow/DaySlider
@onready var _volume_slider: HSlider = $Overlay/Center/Panel/Margin/VBox/VolumeRow/VolumeSlider
@onready var _binding_grid: GridContainer = $Overlay/Center/Panel/Margin/VBox/Bindings
@onready var _status: Label = $Overlay/Center/Panel/Margin/VBox/Status
@onready var _profile: Label = $Overlay/Center/Panel/Margin/VBox/Profile
@onready var _badge_gallery: HBoxContainer = (
	$Overlay/Center/Panel/Margin/VBox/BadgeGallery
)

var _waiting_for_action: StringName = &""
var _binding_buttons: Dictionary = {}
var _badge_icons: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_binding_buttons()
	_build_badge_gallery()
	_load_settings()
	$Overlay/Center/Panel/Margin/VBox/Resume.pressed.connect(_close)
	$Overlay/Center/Panel/Margin/VBox/ResetBindings.pressed.connect(_reset_bindings)
	$Overlay/Center/Panel/Margin/VBox/BikeStyle.pressed.connect(_cycle_bike_style)
	$Overlay/Center/Panel/Margin/VBox/Network/Host.pressed.connect(_host_session)
	$Overlay/Center/Panel/Margin/VBox/Network/Join.pressed.connect(_join_session)
	$Overlay/Center/Panel/Margin/VBox/Network/Offline.pressed.connect(_stop_session)
	_multiplayer.status_changed.connect(_on_network_status)
	_lean_slider.value_changed.connect(_on_lean_changed)
	_day_slider.value_changed.connect(_on_day_changed)
	_volume_slider.value_changed.connect(_on_volume_changed)


func _unhandled_input(event: InputEvent) -> void:
	if not _waiting_for_action.is_empty():
		if not event is InputEventKey or not event.pressed or event.echo:
			return
		if event.physical_keycode == KEY_ESCAPE:
			_waiting_for_action = &""
			_status.text = "Remapping cancelled."
		else:
			_adapter.rebind_keyboard_action(_waiting_for_action, event.physical_keycode)
			_waiting_for_action = &""
			_status.text = "Control updated."
			_refresh_binding_labels()
			_save_settings()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("bike_menu"):
		if _overlay.visible:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()


func _open() -> void:
	_refresh_profile()
	_overlay.visible = true
	get_tree().paused = true


func _close() -> void:
	_waiting_for_action = &""
	_overlay.visible = false
	get_tree().paused = false
	_save_settings()


func _build_binding_buttons() -> void:
	for action: StringName in REMAPPABLE_ACTIONS:
		var label := Label.new()
		label.text = REMAPPABLE_ACTIONS[action]
		_binding_grid.add_child(label)
		var button := Button.new()
		button.custom_minimum_size.x = 180.0
		button.pressed.connect(_begin_rebind.bind(action))
		_binding_grid.add_child(button)
		_binding_buttons[action] = button
	_refresh_binding_labels()


func _build_badge_gallery() -> void:
	for definition: Dictionary in AchievementCatalog.DEFINITIONS:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(58.0, 58.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = definition.texture
		icon.tooltip_text = String(definition.title)
		_badge_gallery.add_child(icon)
		_badge_icons[String(definition.id)] = icon


func _begin_rebind(action: StringName) -> void:
	_waiting_for_action = action
	_status.text = "Press a key for %s. Escape cancels." % REMAPPABLE_ACTIONS[action]


func _refresh_binding_labels() -> void:
	for action: StringName in _binding_buttons:
		var keycode: Key = _adapter.get_keyboard_binding(action)
		_binding_buttons[action].text = OS.get_keycode_string(keycode)


func _refresh_profile() -> void:
	var snapshot: Dictionary = _progression.get_snapshot()
	_profile.text = (
		"Lifetime: %0.2f km  •  %d active min  •  %d effort  •  %d achievements"
		% [
			snapshot.total_distance_m / 1000.0,
			int(snapshot.total_active_seconds / 60.0),
			int(snapshot.total_effort_points),
			snapshot.achievements.size(),
		]
	)
	$Overlay/Center/Panel/Margin/VBox/BikeStyle.text = (
		"Bike style: %s (%d unlocked)"
		% [snapshot.current_cosmetic.replace("_", " ").capitalize(), snapshot.cosmetics.size()]
	)
	for id: String in _badge_icons:
		var icon: TextureRect = _badge_icons[id]
		var unlocked: bool = id in Array(snapshot.achievements)
		icon.modulate = Color.WHITE if unlocked else Color(0.22, 0.25, 0.28, 0.35)
		icon.tooltip_text = (
			AchievementCatalog.get_title(id)
			if unlocked
			else "Locked: %s" % AchievementCatalog.get_title(id)
		)
	_on_network_status(_multiplayer.status)


func _load_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	_player.camera_lean_amount = float(config.get_value("comfort", "camera_lean", 0.075))
	_clock.day_duration_seconds = float(config.get_value("world", "day_duration", 720.0))
	var volume := float(config.get_value("audio", "master_volume", 0.8))
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.001)))
	for action: StringName in REMAPPABLE_ACTIONS:
		var stored := int(config.get_value("controls", action, KEY_NONE))
		if stored != KEY_NONE:
			_adapter.rebind_keyboard_action(action, stored as Key)
	_lean_slider.set_value_no_signal(_player.camera_lean_amount)
	_day_slider.set_value_no_signal(_clock.day_duration_seconds / 60.0)
	_volume_slider.set_value_no_signal(volume)
	_refresh_binding_labels()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("comfort", "camera_lean", _player.camera_lean_amount)
	config.set_value("world", "day_duration", _clock.day_duration_seconds)
	config.set_value("audio", "master_volume", _volume_slider.value)
	for action: StringName in REMAPPABLE_ACTIONS:
		config.set_value("controls", action, int(_adapter.get_keyboard_binding(action)))
	config.save(SETTINGS_PATH)


func _reset_bindings() -> void:
	for action: StringName in _adapter.DEFAULT_KEY_BINDINGS:
		_adapter.rebind_keyboard_action(action, _adapter.DEFAULT_KEY_BINDINGS[action][0])
	_refresh_binding_labels()
	_status.text = "Keyboard controls restored."
	_save_settings()


func _cycle_bike_style() -> void:
	var style: String = _progression.select_next_cosmetic()
	_player.apply_bike_style(style)
	_refresh_profile()


func _host_session() -> void:
	if _multiplayer.host_session() == OK:
		_close()


func _join_session() -> void:
	if _multiplayer.join_session() == OK:
		_close()


func _stop_session() -> void:
	_multiplayer.stop_session()


func _on_network_status(value: String) -> void:
	$Overlay/Center/Panel/Margin/VBox/NetworkStatus.text = "Multiplayer: %s" % value


func _on_lean_changed(value: float) -> void:
	_player.camera_lean_amount = value


func _on_day_changed(value: float) -> void:
	_clock.day_duration_seconds = value * 60.0


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.001)))
