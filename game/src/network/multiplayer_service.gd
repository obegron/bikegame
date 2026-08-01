extends Node
class_name BikeMultiplayerService

signal status_changed(status: String)
signal remote_players_changed

const PORT := 27820
const MAX_CLIENTS := 4

@export var game_path: NodePath
@export var player_path: NodePath
@export var clock_path: NodePath
@export var order_service_path: NodePath

@onready var _game = get_node(game_path)
@onready var _player = get_node(player_path)
@onready var _clock = get_node(clock_path)
@onready var _orders = get_node(order_service_path)

var status := "Offline"
var shared_economy_snapshot: Dictionary = {}
var remote_player_states: Dictionary = {}

var _peer: ENetMultiplayerPeer
var _snapshot_seconds := 0.0
var _player_update_seconds := 0.0
var _remote_avatars: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_game.delivery_result_available.connect(_on_local_delivery_result)


func _process(delta: float) -> void:
	if is_offline():
		return
	_player_update_seconds += delta
	if _player_update_seconds >= 0.05:
		_player_update_seconds = 0.0
		_send_local_player_state()
	if not multiplayer.is_server():
		return
	_snapshot_seconds += delta
	if _snapshot_seconds >= 0.1:
		_snapshot_seconds = 0.0
		_receive_world_snapshot.rpc(_build_world_snapshot())


func host_session() -> Error:
	stop_session()
	_peer = ENetMultiplayerPeer.new()
	var error := _peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		_set_status("Host failed (%s)" % error_string(error))
		return error
	multiplayer.multiplayer_peer = _peer
	_clock.running = true
	_orders.automatic_generation = true
	_set_status("Hosting on port %d" % PORT)
	return OK


func join_session(address := "127.0.0.1") -> Error:
	stop_session()
	_peer = ENetMultiplayerPeer.new()
	var error := _peer.create_client(address, PORT)
	if error != OK:
		_set_status("Join failed (%s)" % error_string(error))
		return error
	multiplayer.multiplayer_peer = _peer
	_clock.running = false
	_orders.automatic_generation = false
	_set_status("Connecting to %s…" % address)
	return OK


func stop_session() -> void:
	if _peer != null:
		_peer.close()
	_peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_clock.running = true
	_orders.automatic_generation = true
	remote_player_states.clear()
	shared_economy_snapshot.clear()
	for avatar in _remote_avatars.values():
		if is_instance_valid(avatar):
			avatar.queue_free()
	_remote_avatars.clear()
	_set_status("Offline")


func is_offline() -> bool:
	return multiplayer.multiplayer_peer is OfflineMultiplayerPeer


func is_client() -> bool:
	return not is_offline() and not multiplayer.is_server()


func is_server_authority() -> bool:
	return is_offline() or multiplayer.is_server()


func request_accept_order() -> void:
	if is_client():
		_request_accept_order.rpc_id(1)
	else:
		_orders.accept_first_offer()


func request_decline_order() -> void:
	if is_client():
		_request_decline_order.rpc_id(1)
	else:
		_orders.decline_first_offer()


func get_delivery_actor(target: Vector3) -> Dictionary:
	var best := {
		"distance": _player.global_position.distance_to(target),
		"collisions": _player.get_collision_count(),
	}
	for state in remote_player_states.values():
		var distance: float = state.position.distance_to(target)
		if distance < float(best.distance):
			best = {"distance": distance, "collisions": int(state.collisions)}
	return best


@rpc("any_peer", "call_remote", "reliable")
func _request_accept_order() -> void:
	if multiplayer.is_server():
		_orders.accept_first_offer()


@rpc("any_peer", "call_remote", "reliable")
func _request_decline_order() -> void:
	if multiplayer.is_server():
		_orders.decline_first_offer()


@rpc("authority", "call_remote", "unreliable_ordered")
func _receive_world_snapshot(snapshot: Dictionary) -> void:
	if multiplayer.is_server():
		return
	_clock.set_hour(float(snapshot.get("hour", _clock.hour)))
	_orders.apply_network_snapshot(snapshot.get("orders", {}))
	shared_economy_snapshot = snapshot.get("economy", {}).duplicate(true)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _submit_player_state(
	position: Vector3,
	heading: float,
	speed_kph: float,
	collisions: int
) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	remote_player_states[sender] = {
		"position": position,
		"heading": heading,
		"speed_kph": speed_kph,
		"collisions": collisions,
	}
	_receive_player_state(sender, position, heading, speed_kph)
	_receive_player_state.rpc(sender, position, heading, speed_kph)


@rpc("authority", "call_remote", "unreliable_ordered")
func _receive_player_state(
	peer_id: int,
	position: Vector3,
	heading: float,
	speed_kph: float
) -> void:
	if peer_id == multiplayer.get_unique_id():
		return
	remote_player_states[peer_id] = {
		"position": position,
		"heading": heading,
		"speed_kph": speed_kph,
		"collisions": 0,
	}
	var avatar := _ensure_remote_avatar(peer_id)
	avatar.position = avatar.position.lerp(position + Vector3(0.0, 0.65, 0.0), 0.35)
	avatar.rotation.y = lerp_angle(avatar.rotation.y, heading, 0.35)


@rpc("authority", "call_remote", "reliable")
func _receive_delivery_result(result: Dictionary) -> void:
	if not multiplayer.is_server():
		_game.show_remote_result(result)


func _send_local_player_state() -> void:
	var position: Vector3 = _player.global_position
	var heading: float = _player.rotation.y
	var speed: float = _player.get_speed_kph()
	if multiplayer.is_server():
		_receive_player_state.rpc(1, position, heading, speed)
	else:
		_submit_player_state.rpc_id(
			1,
			position,
			heading,
			speed,
			_player.get_collision_count()
		)


func _build_world_snapshot() -> Dictionary:
	return {
		"hour": _clock.hour,
		"orders": _orders.get_network_snapshot(),
		"economy": _game.economy_service.get_snapshot(),
	}


func _ensure_remote_avatar(peer_id: int) -> Node3D:
	if _remote_avatars.has(peer_id) and is_instance_valid(_remote_avatars[peer_id]):
		return _remote_avatars[peer_id]
	var avatar := MeshInstance3D.new()
	avatar.name = "RemoteRider%d" % peer_id
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.38
	mesh.height = 1.35
	avatar.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.from_hsv(fposmod(float(peer_id) * 0.23, 1.0), 0.6, 0.9)
	avatar.material_override = material
	_game.add_child(avatar)
	_remote_avatars[peer_id] = avatar
	remote_players_changed.emit()
	return avatar


func _on_local_delivery_result(result: Dictionary) -> void:
	if multiplayer.is_server() and not is_offline():
		_receive_delivery_result.rpc(result)


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_set_status("Hosting • %d rider(s)" % (multiplayer.get_peers().size() + 1))
		_receive_world_snapshot.rpc_id(peer_id, _build_world_snapshot())


func _on_peer_disconnected(peer_id: int) -> void:
	remote_player_states.erase(peer_id)
	if _remote_avatars.has(peer_id):
		_remote_avatars[peer_id].queue_free()
		_remote_avatars.erase(peer_id)
	remote_players_changed.emit()
	if multiplayer.is_server():
		_set_status("Hosting • %d rider(s)" % (multiplayer.get_peers().size() + 1))


func _on_connected_to_server() -> void:
	_set_status("Connected")


func _on_connection_failed() -> void:
	stop_session()
	_set_status("Connection failed")


func _on_server_disconnected() -> void:
	stop_session()
	_set_status("Server disconnected")


func _set_status(value: String) -> void:
	status = value
	status_changed.emit(status)
