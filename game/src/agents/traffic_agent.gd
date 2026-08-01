extends CharacterBody3D

var route: Array[Vector3] = []
var cruise_speed := 5.5

var _target_index := 0
var _corner_pause := 0.0
var _player: Node3D
var _terrain: Node
var _traffic_wait_seconds := 0.0
var _yield_override_seconds := 0.0
var _stuck_seconds := 0.0


func configure(points: Array[Vector3], start_index: int, speed: float) -> void:
	route = points
	_target_index = posmod(start_index, maxi(route.size(), 1))
	cruise_speed = speed


func _ready() -> void:
	add_to_group("traffic")
	add_to_group("obstacle")
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_terrain = get_tree().get_first_node_in_group("terrain_provider")
	_snap_to_terrain()


func _physics_process(delta: float) -> void:
	if route.size() < 2:
		return
	_corner_pause = maxf(0.0, _corner_pause - delta)
	_yield_override_seconds = maxf(0.0, _yield_override_seconds - delta)
	var target := route[_target_index]
	var flat_target := Vector3(target.x, global_position.y, target.z)
	if global_position.distance_to(flat_target) < 1.0:
		_target_index = (_target_index + 1) % route.size()
		_corner_pause = 0.18
		return

	var direction := global_position.direction_to(flat_target)
	var traffic_ahead := _traffic_is_ahead(direction)
	var red_signal_ahead := _red_signal_is_ahead(direction)
	if traffic_ahead:
		_traffic_wait_seconds += delta
	else:
		_traffic_wait_seconds = 0.0
	if _traffic_wait_seconds > 2.2:
		_yield_override_seconds = 1.0
		_traffic_wait_seconds = 0.0
	var should_yield := (
		_corner_pause > 0.0
		or _bike_is_ahead(direction)
		or red_signal_ahead
		or (traffic_ahead and _yield_override_seconds <= 0.0)
	)
	var speed := 0.0 if should_yield else cruise_speed
	velocity = direction * speed
	if direction.length_squared() > 0.01:
		look_at(global_position + direction, Vector3.UP)
	var previous_position := global_position
	move_and_slide()
	_snap_to_terrain()
	if speed > 0.1 and global_position.distance_to(previous_position) < 0.015:
		_stuck_seconds += delta
	else:
		_stuck_seconds = 0.0
	if _stuck_seconds > 1.8:
		_target_index = (_target_index + 1) % route.size()
		_yield_override_seconds = 1.2
		_stuck_seconds = 0.0


func _bike_is_ahead(direction: Vector3) -> bool:
	if _player == null:
		return false
	var offset := _player.global_position - global_position
	return offset.length() < 6.0 and direction.dot(offset.normalized()) > 0.15


func _traffic_is_ahead(direction: Vector3) -> bool:
	for other in get_tree().get_nodes_in_group("traffic"):
		if other == self or not other is Node3D:
			continue
		var offset: Vector3 = other.global_position - global_position
		if offset.length() < 3.4 and direction.dot(offset.normalized()) > 0.6:
			return true
	return false


func _red_signal_is_ahead(direction: Vector3) -> bool:
	for signal_controller in get_tree().get_nodes_in_group("traffic_signal"):
		if signal_controller.has_method("should_stop"):
			if signal_controller.should_stop(global_position, direction):
				return true
	return false


func _snap_to_terrain() -> void:
	if _terrain == null:
		return
	if _terrain.has_method("travel_surface_height_at"):
		global_position.y = (
			_terrain.travel_surface_height_at(global_position.x, global_position.z) + 0.52
		)
	elif _terrain.has_method("ground_height_at"):
		global_position.y = _terrain.ground_height_at(global_position.x, global_position.z) + 0.52
