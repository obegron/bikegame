extends CharacterBody3D

var wander_points: Array[Vector3] = []
var wander_speed := 0.9
var flee_speed := 4.2

var _target_index := 0
var _flee_seconds := 0.0
var _wait_seconds := 0.0
var _player: Node3D
var _terrain: Node


func configure(points: Array[Vector3], start_index: int) -> void:
	wander_points = points
	_target_index = posmod(start_index, maxi(points.size(), 1))


func _ready() -> void:
	add_to_group("wildlife")
	add_to_group("obstacle")
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_terrain = get_tree().get_first_node_in_group("terrain_provider")
	_snap_to_terrain()


func _physics_process(delta: float) -> void:
	if wander_points.is_empty():
		return
	_flee_seconds = maxf(0.0, _flee_seconds - delta)
	_wait_seconds = maxf(0.0, _wait_seconds - delta)
	if _player != null and global_position.distance_to(_player.global_position) < 6.0:
		_flee_seconds = 1.2

	var direction := Vector3.ZERO
	var speed := 0.0
	if _flee_seconds > 0.0 and _player != null:
		direction = _player.global_position.direction_to(global_position)
		direction.y = 0.0
		speed = flee_speed
	elif _wait_seconds <= 0.0:
		var target := wander_points[_target_index]
		var flat_target := Vector3(target.x, global_position.y, target.z)
		if global_position.distance_to(flat_target) < 0.6:
			_target_index = (_target_index + 1) % wander_points.size()
			_wait_seconds = 0.7
		else:
			direction = global_position.direction_to(flat_target)
			speed = wander_speed

	velocity = direction.normalized() * speed
	if direction.length_squared() > 0.01:
		look_at(global_position + direction, Vector3.UP)
	move_and_slide()
	_snap_to_terrain()


func _snap_to_terrain() -> void:
	if _terrain != null and _terrain.has_method("ground_height_at"):
		global_position.y = _terrain.ground_height_at(global_position.x, global_position.z) + 0.45
