extends CharacterBody3D
class_name BikeController

signal obstacle_hit(total_collisions: int)

@export var input_adapter_path: NodePath
@export var maximum_speed_mps := 12.0
@export var acceleration_mps2 := 4.5
@export var coast_deceleration_mps2 := 1.8
@export var braking_mps2 := 9.0
@export var maximum_turn_rate := 1.55
@export var steering_response := 5.0
@export_range(0.0, 0.14, 0.005) var camera_lean_amount := 0.075

@onready var _camera: Camera3D = $Camera3D
@onready var _headlight: SpotLight3D = $Camera3D/BikeHeadlight
@onready var _adapter: BikeInputAdapter = get_node(input_adapter_path) as BikeInputAdapter

var _speed_mps := 0.0
var _turn_rate := 0.0
var _collision_count := 0
var _collision_cooldown := 0.0
var _start_transform: Transform3D
var _gravity := 9.8
var _camera_base_position := Vector3.ZERO
var _ride_phase := 0.0


func _ready() -> void:
	add_to_group("player")
	_start_transform = global_transform
	_camera_base_position = _camera.position
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_headlight.add_to_group("bike_headlight")


func _physics_process(delta: float) -> void:
	if _adapter.is_reset_just_pressed() or global_position.y < -5.0:
		_reset_to_start()
		return

	var throttle := _adapter.get_throttle()
	var brake := _adapter.get_brake()
	var target_speed := throttle * maximum_speed_mps
	var speed_change := acceleration_mps2 if target_speed > _speed_mps else coast_deceleration_mps2
	_speed_mps = move_toward(_speed_mps, target_speed, speed_change * delta)
	_speed_mps = move_toward(_speed_mps, 0.0, braking_mps2 * brake * delta)

	var steer := _adapter.get_steer()
	var speed_ratio := clampf(_speed_mps / maximum_speed_mps, 0.0, 1.0)
	var low_speed_authority := lerpf(0.25, 1.0, speed_ratio)
	var desired_turn_rate := steer * maximum_turn_rate * low_speed_authority
	var steering_blend := 1.0 - exp(-steering_response * delta)
	_turn_rate = lerpf(_turn_rate, desired_turn_rate, steering_blend)
	rotate_y(-_turn_rate * delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0
	var forward := -global_transform.basis.z.normalized()
	velocity.x = forward.x * _speed_mps
	velocity.z = forward.z * _speed_mps
	move_and_slide()

	_camera.rotation.z = lerpf(_camera.rotation.z, -steer * camera_lean_amount, steering_blend)
	_ride_phase += delta * (2.0 + _speed_mps * 0.75)
	var ride_bob := sin(_ride_phase) * 0.012 * speed_ratio
	_camera.position.y = _camera_base_position.y + ride_bob
	_camera.fov = lerpf(_camera.fov, lerpf(75.0, 82.0, speed_ratio), steering_blend)
	_detect_obstacle_hit(delta)


func get_speed_kph() -> float:
	return _speed_mps * 3.6


func get_turn_rate() -> float:
	return _turn_rate


func get_collision_count() -> int:
	return _collision_count


func apply_bike_style(style: String) -> void:
	var handlebar := _camera.get_node_or_null("Handlebar") as MeshInstance3D
	if handlebar == null or handlebar.material_override == null:
		return
	var material := handlebar.material_override.duplicate() as StandardMaterial3D
	match style:
		"ocean_blue":
			material.albedo_color = Color("3d77a8")
		"sunset_gold":
			material.albedo_color = Color("e0a63b")
		_:
			material.albedo_color = Color("a83f38")
	handlebar.material_override = material


func set_reset_transform_to_current() -> void:
	_start_transform = global_transform


func _detect_obstacle_hit(delta: float) -> void:
	_collision_cooldown = maxf(0.0, _collision_cooldown - delta)
	if _collision_cooldown > 0.0:
		return
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider is Node and collider.is_in_group("obstacle"):
			_collision_count += 1
			_collision_cooldown = 0.6
			_speed_mps *= 0.65
			obstacle_hit.emit(_collision_count)
			return


func _reset_to_start() -> void:
	global_transform = _start_transform
	velocity = Vector3.ZERO
	_speed_mps = 0.0
	_turn_rate = 0.0
