extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed := load("res://scenes/monaco_game.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var city = game.get_node("City")

	var roads: Array = city.get("_road_corridors")
	var maximum_grade := 0.0
	var steepest := {}
	for corridor: Dictionary in roads:
		var length: float = (corridor.from as Vector2).distance_to(corridor.to)
		if length < 0.1:
			continue
		var grade := (
			absf(float(corridor.to_height) - float(corridor.from_height))
			/ length
		)
		if grade > maximum_grade:
			maximum_grade = grade
			steepest = corridor
	print(
		"Monaco road audit: corridors=%d max_grade=%.3f segment=%s"
		% [roads.size(), maximum_grade, steepest]
	)
	print(
		"Buildings=%d infill=%d palms=%d cypress=%d batched_plants=%d"
		% [
			int(city.get_meta("monaco_building_count", 0)),
			int(city.get_meta("monaco_infill_building_count", 0)),
			int(city.get_meta("monaco_palm_count", 0)),
			int(city.get_meta("monaco_cypress_count", 0)),
			int(city.get_meta("monaco_batched_plant_count", 0)),
		]
	)
	var style_counts := {}
	for building in get_nodes_in_group("monaco_building"):
		var style := String(building.get_meta("district_style", "unknown"))
		style_counts[style] = int(style_counts.get(style, 0)) + 1
	print(
		"Architecture=%s modern_towers=%d"
		% [style_counts, get_nodes_in_group("monaco_modern_tower").size()]
	)
	var objective_violations := 0
	for location: Dictionary in city.pickup_locations() + city.dropoff_locations():
		var point: Vector3 = location.position
		var clearance: float = city.road_surface_clearance_at(point)
		if clearance >= 0.75:
			objective_violations += 1
			print(
				"OBJECTIVE TOO FAR: %s clearance=%.2f at=%s"
				% [location.name, clearance, point]
			)

	var obstacle_violations := 0
	for obstacle in get_nodes_in_group("obstacle"):
		if not obstacle is StaticBody3D:
			continue
		var collision: CollisionShape3D
		for child in obstacle.get_children():
			if child is CollisionShape3D:
				collision = child
				break
		if collision == null or not collision.shape is BoxShape3D:
			continue
		var half_size: Vector3 = (collision.shape as BoxShape3D).size * 0.5
		var obstacle_bottom: float = obstacle.global_position.y - half_size.y
		var local_ground: float = city.ground_height_at(
			obstacle.global_position.x,
			obstacle.global_position.z
		)
		if obstacle_bottom > local_ground + 2.8:
			continue
		var minimum_clearance := INF
		for x_weight in [-1.0, 0.0, 1.0]:
			for z_weight in [-1.0, 0.0, 1.0]:
				var probe: Vector3 = obstacle.to_global(
					collision.position
					+ Vector3(half_size.x * x_weight, 0.0, half_size.z * z_weight)
				)
				minimum_clearance = minf(
					minimum_clearance,
					city.road_surface_clearance_at(probe)
				)
		if minimum_clearance < -0.08:
			obstacle_violations += 1
			print(
				"OBSTACLE IN ROAD: %s clearance=%.2f at=%s"
				% [obstacle.name, minimum_clearance, obstacle.global_position]
			)

	var prop_violations := 0
	for group_name in [
		"monaco_lamp_post",
		"freestanding_shop_sign",
		"monaco_route_landmark",
		"monaco_parked_car",
		"traffic_signal_pole",
	]:
		for prop in get_nodes_in_group(group_name):
			var clearance: float = city.road_surface_clearance_at(
				prop.global_position
			)
			if clearance < 0.5:
				prop_violations += 1
				print(
					"PROP IN ROAD: group=%s node=%s clearance=%.2f at=%s"
					% [group_name, prop.name, clearance, prop.global_position]
				)

	var foliage_violations := 0
	for batch in get_nodes_in_group("monaco_batched_foliage"):
		var audit_transforms: Array = batch.get_meta("road_audit_transforms", [])
		for instance_index in audit_transforms.size():
			var instance_transform: Transform3D = audit_transforms[instance_index]
			var instance_position: Vector3 = instance_transform.origin
			if city.road_surface_clearance_at(instance_position) < 0.5:
				foliage_violations += 1
				print(
					"FOLIAGE IN ROAD: %s instance=%d at=%s"
					% [batch.name, instance_index, instance_position]
				)
	print(
		"Monaco clearance audit: obstacle=%d prop=%d foliage=%d objective=%d"
		% [
			obstacle_violations,
			prop_violations,
			foliage_violations,
			objective_violations,
		]
	)
	game.queue_free()
	await process_frame
	quit(
		0
		if maximum_grade <= 0.13
		and obstacle_violations == 0
		and prop_violations == 0
		and foliage_violations == 0
		and objective_violations == 0
		else 1
	)
