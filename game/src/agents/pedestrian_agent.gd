extends CharacterBody3D

enum State {
	WALK,
	WAIT,
	EVADE,
}

var route: Array[Vector3] = []
var walk_speed := 1.35

var _target_index := 0
var _state := State.WALK
var _state_seconds := 0.0
var _player: Node3D
var _terrain: Node


func configure(points: Array[Vector3], start_index: int) -> void:
	route = points
	_target_index = posmod(start_index, maxi(route.size(), 1))


func _ready() -> void:
	add_to_group("pedestrian")
	add_to_group("obstacle")
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_terrain = get_tree().get_first_node_in_group("terrain_provider")
	_snap_to_terrain()


func _physics_process(delta: float) -> void:
	if route.size() < 2:
		return
	_state_seconds = maxf(0.0, _state_seconds - delta)
	var player_distance := INF
	if _player != null:
		player_distance = global_position.distance_to(_player.global_position)
	if player_distance < 2.7:
		_state = State.EVADE
		_state_seconds = 0.75
	elif _state_seconds <= 0.0 and _state != State.WALK:
		_state = State.WALK

	match _state:
		State.WAIT:
			velocity = Vector3.ZERO
		State.EVADE:
			var away := (_player.global_position.direction_to(global_position) if _player != null else Vector3.ZERO)
			away.y = 0.0
			velocity = away.normalized() * 2.1
			_look_in_direction(away)
		State.WALK:
			_walk_route()
	move_and_slide()
	_snap_to_terrain()


func _walk_route() -> void:
	var target := route[_target_index]
	var flat_target := Vector3(target.x, global_position.y, target.z)
	if global_position.distance_to(flat_target) < 0.55:
		_target_index = (_target_index + 1) % route.size()
		_state = State.WAIT
		_state_seconds = 0.35 + float(_target_index % 3) * 0.18
		velocity = Vector3.ZERO
		return
	var direction := global_position.direction_to(flat_target)
	velocity = direction * walk_speed
	_look_in_direction(direction)


func _look_in_direction(direction: Vector3) -> void:
	if direction.length_squared() > 0.01:
		look_at(global_position + direction, Vector3.UP)


func _snap_to_terrain() -> void:
	if _terrain != null and _terrain.has_method("ground_height_at"):
		global_position.y = _terrain.ground_height_at(global_position.x, global_position.z) + 0.9
