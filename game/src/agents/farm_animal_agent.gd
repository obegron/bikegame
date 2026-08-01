extends CharacterBody3D

var roam_points: Array[Vector3] = []
var wander_speed := 0.65

var _target_index := 0
var _wait_seconds := 0.0
var _terrain: Node
var _visual_root: Node3D
var _motion_time := 0.0
var _rng := RandomNumberGenerator.new()


func configure(points: Array[Vector3], start_index: int, speed: float) -> void:
	roam_points = points
	_target_index = posmod(start_index, maxi(points.size(), 1))
	wander_speed = speed


func _ready() -> void:
	add_to_group("farm_animal")
	add_to_group("obstacle")
	_terrain = get_tree().get_first_node_in_group("terrain_provider")
	_visual_root = get_node_or_null("VisualRoot") as Node3D
	_rng.seed = hash(name)
	_snap_to_terrain()


func _physics_process(delta: float) -> void:
	if roam_points.is_empty():
		return
	_motion_time += delta
	_wait_seconds = maxf(0.0, _wait_seconds - delta)
	var direction := Vector3.ZERO
	if _wait_seconds <= 0.0:
		var target := roam_points[_target_index]
		var flat_target := Vector3(target.x, global_position.y, target.z)
		if global_position.distance_to(flat_target) < 0.55:
			_target_index = (_target_index + 1) % roam_points.size()
			_wait_seconds = _rng.randf_range(1.2, 3.6)
		else:
			direction = global_position.direction_to(flat_target)
			direction.y = 0.0

	velocity = direction.normalized() * wander_speed
	if direction.length_squared() > 0.01:
		look_at(global_position + direction, Vector3.UP)
	move_and_slide()
	_snap_to_terrain()
	if _visual_root != null:
		var moving_amount := clampf(velocity.length() / maxf(wander_speed, 0.01), 0.0, 1.0)
		_visual_root.position.y = sin(_motion_time * 7.0) * 0.025 * moving_amount
		_visual_root.rotation.z = sin(_motion_time * 3.5) * 0.012 * moving_amount


func _snap_to_terrain() -> void:
	if _terrain != null and _terrain.has_method("ground_height_at"):
		global_position.y = _terrain.ground_height_at(global_position.x, global_position.z)
