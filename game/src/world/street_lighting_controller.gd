extends Node

@export var clock_path: NodePath
@export var city_path: NodePath

@onready var _clock = get_node(clock_path)
@onready var _city = get_node(city_path)


func _ready() -> void:
	_clock.time_changed.connect(_on_time_changed)
	_on_time_changed(_clock.hour, _clock.get_phase())


func _on_time_changed(hour: float, _phase: String) -> void:
	var strength := strength_for_hour(hour)
	_city.set_street_lamp_strength(strength)
	for headlight: SpotLight3D in get_tree().get_nodes_in_group("bike_headlight"):
		headlight.visible = strength > 0.001
		headlight.light_energy = 11.0 * strength


static func strength_for_hour(hour: float) -> float:
	var wrapped := fposmod(hour, 24.0)
	if wrapped >= 20.5 or wrapped < 5.0:
		return 1.0
	if wrapped >= 18.0:
		return smoothstep(18.0, 20.5, wrapped)
	if wrapped < 7.0:
		return 1.0 - smoothstep(5.0, 7.0, wrapped)
	return 0.0
