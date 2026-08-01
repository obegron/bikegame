extends Node3D

var flight_center := Vector3.ZERO
var orbit_radius := 12.0
var orbit_speed := 0.3
var _angle := 0.0
var _flight_time := 0.0
var _left_wing: MeshInstance3D
var _right_wing: MeshInstance3D


func configure(
	center: Vector3,
	radius: float,
	speed: float,
	start_angle: float
) -> void:
	flight_center = center
	orbit_radius = radius
	orbit_speed = speed
	_angle = start_angle


func _ready() -> void:
	add_to_group("bird")
	_left_wing = get_node("LeftWing") as MeshInstance3D
	_right_wing = get_node("RightWing") as MeshInstance3D
	_update_flight(0.0)


func _process(delta: float) -> void:
	_angle = fposmod(_angle + orbit_speed * delta, TAU)
	_flight_time += delta
	_update_flight(delta)


func _update_flight(_delta: float) -> void:
	var next_position := Vector3(
		flight_center.x + cos(_angle) * orbit_radius,
		flight_center.y + sin(_angle * 2.0) * 1.15,
		flight_center.z + sin(_angle) * orbit_radius * 0.62
	)
	var tangent := Vector3(
		-sin(_angle),
		cos(_angle * 2.0) * 0.12,
		cos(_angle) * 0.62
	).normalized()
	position = next_position
	look_at(position + tangent, Vector3.UP)
	var flap := sin(_flight_time * 8.5 + _angle * 2.0) * 0.62
	_left_wing.rotation.z = flap
	_right_wing.rotation.z = -flap
