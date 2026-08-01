extends Node
class_name WorldClock

signal time_changed(hour: float, phase: String)
signal phase_changed(phase: String)

@export_range(60.0, 3600.0, 1.0) var day_duration_seconds := 720.0
@export_range(0.0, 24.0, 0.25) var start_hour := 7.0
@export var running := true

var hour := 7.0
var _phase := "morning"


func _ready() -> void:
	set_hour(start_hour)


func _process(delta: float) -> void:
	if running:
		advance(delta)


func advance(real_seconds: float) -> void:
	set_hour(hour + real_seconds * 24.0 / day_duration_seconds)


func set_hour(value: float) -> void:
	hour = fposmod(value, 24.0)
	var next_phase := get_phase_for_hour(hour)
	if next_phase != _phase:
		_phase = next_phase
		phase_changed.emit(_phase)
	time_changed.emit(hour, _phase)


func get_phase() -> String:
	return _phase


func get_time_text() -> String:
	var total_minutes := int(round(hour * 60.0)) % (24 * 60)
	return "%02d:%02d" % [total_minutes / 60, total_minutes % 60]


func get_order_context() -> Dictionary:
	match _phase:
		"morning":
			return {"kind": "Breakfast", "demand": 1.15, "tip_multiplier": 1.0}
		"noon":
			return {"kind": "Lunch", "demand": 1.45, "tip_multiplier": 1.05}
		"sunset":
			return {"kind": "Dinner", "demand": 1.35, "tip_multiplier": 1.15}
		"night":
			return {"kind": "Late-night", "demand": 0.7, "tip_multiplier": 1.5}
		_:
			return {"kind": "Courier", "demand": 0.9, "tip_multiplier": 1.0}


static func get_phase_for_hour(value: float) -> String:
	var wrapped := fposmod(value, 24.0)
	if wrapped >= 5.0 and wrapped < 9.0:
		return "morning"
	if wrapped >= 11.5 and wrapped < 14.0:
		return "noon"
	if wrapped >= 17.5 and wrapped < 20.5:
		return "sunset"
	if wrapped >= 20.5 or wrapped < 5.0:
		return "night"
	return "day"
