extends Node3D
class_name DeliveryGame

const DeliveryOrderType = preload("res://src/core/delivery_order.gd")
const CustomerCatalog = preload("res://src/core/customer_catalog.gd")

signal delivery_state_changed
signal delivery_result_available(result: Dictionary)

@export var input_adapter_path: NodePath
@export var player_path: NodePath
@export var world_clock_path: NodePath
@export var order_service_path: NodePath
@export var economy_service_path: NodePath
@export var progression_service_path: NodePath
@export var multiplayer_service_path: NodePath

@onready var input_adapter = get_node(input_adapter_path)
@onready var player = get_node(player_path)
@onready var world_clock = get_node(world_clock_path)
@onready var order_service = get_node(order_service_path)
@onready var economy_service = get_node(economy_service_path)
@onready var progression_service = get_node(progression_service_path)
@onready var multiplayer_service = get_node(multiplayer_service_path)
@onready var city = $City

var distance_ridden_m := 0.0
var active_time_seconds := 0.0
var last_result: Dictionary = {}
var result_display_seconds := 0.0

var _objective_marker: Node3D
var _last_player_position := Vector3.ZERO
var _collisions_at_accept := 0
var _pulse_time := 0.0
var _auto_accept_request_seconds := 0.0
var _queued_results: Array[Dictionary] = []


func _ready() -> void:
	player.global_position.y = (
		city.ground_height_at(player.global_position.x, player.global_position.z) + 0.9
	)
	player.set_reset_transform_to_current()
	order_service.world_clock = world_clock
	var pickup_locations := _ground_locations(_pickup_locations())
	var dropoff_locations := _ground_locations(_dropoff_locations())
	order_service.configure_locations(pickup_locations, dropoff_locations)
	order_service.configure_customers(CustomerCatalog.get_order_profiles())
	_create_pickup_signs(pickup_locations)
	order_service.order_offered.connect(_on_order_changed)
	order_service.order_accepted.connect(_on_order_accepted)
	order_service.order_declined.connect(_on_order_changed)
	order_service.order_expired.connect(_on_order_changed)
	order_service.order_stage_changed.connect(_on_order_changed)
	order_service.order_completed.connect(_on_order_completed)
	progression_service.bind_economy(economy_service)
	progression_service.achievement_unlocked.connect(_on_achievement_unlocked)
	player.apply_bike_style(progression_service.current_cosmetic)
	_objective_marker = _create_objective_marker()
	_last_player_position = player.global_position


func _process(delta: float) -> void:
	_update_exercise_stats(delta)
	_update_delivery_loop(delta)
	if result_display_seconds > 0.0:
		result_display_seconds = maxf(0.0, result_display_seconds - delta)
	if result_display_seconds <= 0.0 and not _queued_results.is_empty():
		_show_result(_queued_results.pop_front(), 4.0)


func get_active_order():
	return order_service.get_active_order()


func get_offers() -> Array:
	return order_service.offers


func get_offer_remaining_seconds(order) -> float:
	return order_service.get_offer_remaining_seconds(order)


func get_economy_snapshot() -> Dictionary:
	if multiplayer_service.is_client() and not multiplayer_service.shared_economy_snapshot.is_empty():
		return multiplayer_service.shared_economy_snapshot
	return economy_service.get_snapshot()


func get_objective_distance() -> float:
	var order = get_active_order()
	if order == null:
		return 0.0
	return player.global_position.distance_to(order.get_objective_position())


func _update_delivery_loop(delta: float) -> void:
	_auto_accept_request_seconds = maxf(0.0, _auto_accept_request_seconds - delta)
	if input_adapter.is_accept_just_pressed() and get_active_order() == null:
		multiplayer_service.request_accept_order()
	elif input_adapter.is_decline_just_pressed() and get_active_order() == null:
		multiplayer_service.request_decline_order()

	var order = get_active_order()
	if order == null:
		var offers: Array = get_offers()
		if offers.is_empty():
			_objective_marker.visible = false
			return
		var offered_order = offers[0]
		var pickup: Vector3 = offered_order.pickup_position
		_objective_marker.visible = true
		_objective_marker.global_position = pickup + Vector3(0.0, 0.08, 0.0)
		_pulse_time += delta
		var preview_scale := 0.72 + sin(_pulse_time * 3.0) * 0.05
		_objective_marker.scale = Vector3.ONE * preview_scale
		if (
			player.global_position.distance_to(pickup) <= 4.0
			and _auto_accept_request_seconds <= 0.0
		):
			_auto_accept_request_seconds = 1.0
			multiplayer_service.request_accept_order()
		return

	var target: Vector3 = order.get_objective_position()
	_objective_marker.visible = true
	_objective_marker.global_position = target + Vector3(0.0, 0.08, 0.0)
	_pulse_time += delta
	_objective_marker.scale = Vector3.ONE * (1.0 + sin(_pulse_time * 3.0) * 0.08)

	if not multiplayer_service.is_server_authority():
		return
	var actor: Dictionary = multiplayer_service.get_delivery_actor(target)
	if float(actor.distance) > 4.0:
		return
	if order.state == DeliveryOrderType.State.TO_PICKUP:
		order_service.mark_pickup_reached()
	elif order.state == DeliveryOrderType.State.TO_DROPOFF:
		var delivery_collisions: int = int(actor.collisions) - _collisions_at_accept
		order_service.complete_active_order(delivery_collisions)


func _update_exercise_stats(delta: float) -> void:
	var moved: float = player.global_position.distance_to(_last_player_position)
	if moved < 20.0:
		distance_ridden_m += moved
		progression_service.add_exercise(moved, 0.0, 0.0, world_clock.get_phase())
	if player.get_speed_kph() > 1.0:
		active_time_seconds += delta
		var effort_proxy: float = input_adapter.get_throttle() * delta
		progression_service.add_exercise(0.0, delta, effort_proxy, world_clock.get_phase())
	_last_player_position = player.global_position


func _on_order_accepted(_order) -> void:
	_collisions_at_accept = player.get_collision_count()
	delivery_state_changed.emit()


func _on_order_changed(_order) -> void:
	delivery_state_changed.emit()


func _on_order_completed(order, outcome: Dictionary) -> void:
	var delivery_result: Dictionary = economy_service.apply_delivery_outcome(outcome)
	delivery_result["customer_id"] = String(order.customer_id)
	delivery_result["customer_name"] = String(order.customer_name)
	delivery_result["customer_dialogue"] = CustomerCatalog.get_delivery_line(
		String(order.customer_id),
		float(delivery_result.rating)
	)
	_show_result(delivery_result, 7.0)
	# Achievements unlocked by this delivery are queued behind the customer's
	# response, so the portrait and dialogue do not vanish on milestone runs.
	progression_service.record_delivery(delivery_result)
	delivery_state_changed.emit()


func _on_achievement_unlocked(id: String, title: String) -> void:
	var achievement_result := {"achievement": title, "achievement_id": id}
	if result_display_seconds > 0.0 and last_result.has("customer_id"):
		_queued_results.append(achievement_result)
		return
	_show_result(achievement_result, 4.0)


func show_remote_result(result: Dictionary) -> void:
	_show_result(result.duplicate(true), 7.0 if result.has("customer_id") else 5.0)


func _show_result(result: Dictionary, duration: float) -> void:
	last_result = result
	result_display_seconds = duration
	delivery_result_available.emit(last_result)


func _create_objective_marker() -> Node3D:
	var marker := Node3D.new()
	marker.name = "ObjectiveMarker"
	marker.visible = false

	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 2.0
	ring_mesh.bottom_radius = 2.0
	ring_mesh.height = 0.12
	var ring := MeshInstance3D.new()
	ring.mesh = ring_mesh
	ring.material_override = _marker_material(Color("ffd65a"), 0.9)
	marker.add_child(ring)

	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.18
	beam_mesh.bottom_radius = 0.55
	beam_mesh.height = 7.0
	var beam := MeshInstance3D.new()
	beam.position.y = 3.5
	beam.mesh = beam_mesh
	beam.material_override = _marker_material(Color("ffe794"), 0.38)
	marker.add_child(beam)
	add_child(marker)
	return marker


func _marker_material(color: Color, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	color.a = alpha
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _create_pickup_signs(locations: Array[Dictionary]) -> void:
	for index in locations.size():
		var location: Dictionary = locations[index]
		var pickup_label := Label3D.new()
		pickup_label.name = "Pickup label %02d" % index
		pickup_label.text = "PICKUP  •  %s" % String(location.name).to_upper()
		pickup_label.position = location.position + Vector3(0.0, 3.4, 0.0)
		pickup_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		pickup_label.font_size = 42
		pickup_label.pixel_size = 0.012
		pickup_label.modulate = Color("ffe18a")
		pickup_label.outline_modulate = Color("172126")
		pickup_label.outline_size = 10
		pickup_label.visibility_range_end = 62.0
		pickup_label.visibility_range_fade_mode = (
			GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		)
		pickup_label.add_to_group("pickup_sign")
		add_child(pickup_label)
		_create_shop_facade_sign(location, index)


func _create_shop_facade_sign(location: Dictionary, index: int) -> void:
	var sign_root := Node3D.new()
	sign_root.name = "Shop facade sign %02d" % index
	var mount: Vector3 = location.sign_position
	mount.y = (
		float(location.get(
			"sign_base_y",
			city.ground_height_at(mount.x, mount.z)
		))
		+ float(location.get("sign_height", 4.0))
	)
	sign_root.position = mount
	sign_root.rotation.y = float(location.get("sign_rotation_y", 0.0))
	sign_root.add_to_group("shop_sign")
	sign_root.set_meta("shop_name", String(location.name))

	var sign_size: Vector2 = location.get("sign_size", Vector2(4.8, 1.6))
	var backing_mesh := BoxMesh.new()
	backing_mesh.size = Vector3(sign_size.x + 0.16, sign_size.y + 0.16, 0.12)
	var backing := MeshInstance3D.new()
	backing.name = "Painted wooden backing"
	backing.mesh = backing_mesh
	backing.material_override = _sign_backing_material()
	sign_root.add_child(backing)
	if bool(location.get("freestanding_sign", false)):
		var support_height := maxf(
			float(location.get("sign_height", 2.2)) - sign_size.y * 0.5,
			0.7
		)
		for support_x in [-sign_size.x * 0.32, sign_size.x * 0.32]:
			var support_mesh := BoxMesh.new()
			support_mesh.size = Vector3(0.13, support_height, 0.13)
			var support := MeshInstance3D.new()
			support.name = "Roadside sign support"
			support.position = Vector3(
				support_x,
				-sign_size.y * 0.5 - support_height * 0.5,
				0.0
			)
			support.mesh = support_mesh
			support.material_override = _sign_backing_material()
			sign_root.add_child(support)
		sign_root.add_to_group("freestanding_shop_sign")

	var image_mesh := QuadMesh.new()
	image_mesh.size = sign_size
	var image := MeshInstance3D.new()
	image.name = "Shop artwork"
	image.position.z = 0.065
	image.mesh = image_mesh
	image.material_override = _sign_image_material(load(String(location.sign_texture)))
	sign_root.add_child(image)
	add_child(sign_root)


func _sign_backing_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("3c2a20")
	material.roughness = 0.72
	return material


func _sign_image_material(texture: Texture2D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.roughness = 0.58
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _pickup_locations() -> Array[Dictionary]:
	if city != null and city.has_method("pickup_locations"):
		return city.call("pickup_locations")
	return [
		{
			"name": "Market Hall",
			"position": Vector3(-9.0, 0.0, -7.0),
			"sign_position": Vector3(-10.0, 0.0, -14.12),
			"sign_height": 2.0,
			"sign_rotation_y": 0.0,
			"sign_size": Vector2(4.8, 1.6),
			"sign_texture": "res://assets/signs/shops/market_hall.png",
		},
		{
			"name": "Boulangerie du Pont",
			"position": Vector3(-60.0, 0.0, 18.0),
			"sign_position": Vector3(-58.0, 0.0, 25.43),
			"sign_height": 4.15,
			"sign_rotation_y": PI,
			"sign_size": Vector2(4.8, 1.6),
			"sign_texture": "res://assets/signs/shops/boulangerie_du_pont.png",
		},
		{
			"name": "Old Mill Bakery",
			"position": Vector3(-78.0, 0.72, -54.0),
			"bridge": true,
			"sign_position": Vector3(-79.42, 0.0, -36.5),
			"sign_base_y": 0.0,
			"sign_height": 6.4,
			"sign_rotation_y": PI * 0.5,
			"sign_size": Vector2(4.7, 1.55),
			"sign_texture": "res://assets/signs/shops/old_mill_bakery.png",
		},
		{
			"name": "South Gate Burger Bar",
			"position": Vector3(-12.0, 0.0, 54.0),
			"sign_position": Vector3(-7.5, 0.0, 50.56),
			"sign_height": 9.1,
			"sign_rotation_y": 0.0,
			"sign_size": Vector2(4.8, 1.6),
			"sign_texture": "res://assets/signs/shops/south_gate_burger_bar.png",
		},
		{
			"name": "Quayside Pizzeria",
			"position": Vector3(28.0, 0.0, -82.0),
			"sign_position": Vector3(28.0, 0.0, -72.06),
			"sign_height": 4.2,
			"sign_rotation_y": PI,
			"sign_size": Vector2(5.0, 1.65),
			"sign_texture": "res://assets/signs/shops/quayside_pizzeria.png",
		},
		{
			"name": "North Bank Sushi",
			"position": Vector3(-28.0, 0.0, -132.0),
			"sign_position": Vector3(-28.0, 0.0, -143.94),
			"sign_height": 4.25,
			"sign_rotation_y": 0.0,
			"sign_size": Vector2(4.9, 1.6),
			"sign_texture": "res://assets/signs/shops/north_bank_sushi.png",
		},
		{
			"name": "Hilltop Thai Kitchen",
			"position": Vector3(129.0, 0.0, 67.0),
			"sign_position": Vector3(137.05, 0.0, 86.12),
			"sign_height": 4.25,
			"sign_rotation_y": -0.62,
			"sign_size": Vector2(5.0, 1.65),
			"sign_texture": "res://assets/signs/shops/hilltop_thai_kitchen.png",
		},
		{
			"name": "Orchard Farm Shop",
			"position": Vector3(-137.0, 0.0, 70.0),
			"sign_position": Vector3(-145.94, 0.0, 70.0),
			"sign_height": 4.0,
			"sign_rotation_y": PI * 0.5,
			"sign_size": Vector2(4.9, 1.6),
			"sign_texture": "res://assets/signs/shops/orchard_farm_shop.png",
		},
	]


func _dropoff_locations() -> Array[Dictionary]:
	if city != null and city.has_method("dropoff_locations"):
		return city.call("dropoff_locations")
	return [
		{"name": "Cathedral Close", "position": Vector3(-19.0, 0.0, -7.0)},
		{"name": "Canal Houses", "position": Vector3(-82.0, 0.0, 18.0)},
		{"name": "Old Town Hall", "position": Vector3(19.0, 0.0, -7.0)},
		{"name": "Abbey Gardens", "position": Vector3(74.0, 0.0, 21.0)},
		{"name": "University Court", "position": Vector3(52.0, 0.0, -43.0)},
		{"name": "South Avenue", "position": Vector3(34.0, 0.0, 78.0)},
		{"name": "North Quay", "position": Vector3(0.0, 0.0, -82.0)},
		{"name": "North Bank", "position": Vector3(-28.0, 0.0, -132.0)},
		{"name": "Hill Village", "position": Vector3(129.0, 0.0, 67.0)},
		{"name": "Orchard Cottages", "position": Vector3(-137.0, 0.0, 70.0)},
		{"name": "Meadowcroft Farm", "position": Vector3(-108.0, 0.0, 57.0)},
	]


func _ground_locations(locations: Array[Dictionary]) -> Array[Dictionary]:
	for location in locations:
		var position: Vector3 = location.position
		if bool(location.get("bridge", false)):
			continue
		position.y = city.ground_height_at(position.x, position.z)
		location.position = position
	return locations
