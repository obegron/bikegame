extends SceneTree

const WATER_LEVEL := -0.65


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed := load("res://scenes/monaco_game.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.get_node("Onboarding/Overlay").visible = false
	paused = false

	var city = game.get_node("City")
	var player = game.get_node("Player")
	var street_life = game.get_node("StreetLife")
	_expect(
		city.get_meta("level_id", "") == "monaco"
		and city.get_meta("level_name", "") == "Monaco Corniche",
		"the second gameplay scene should identify itself as Monaco"
	)
	_expect(
		city.ground_height_at(0.0, -145.0) - city.ground_height_at(0.0, 25.0) > 15.0
		and city.ground_height_at(0.0, 80.0) < -5.0,
		"Monaco should climb steeply behind an open central harbour"
	)
	_expect(
		(
			player.global_position.y
			- city.ground_height_at(player.global_position.x, player.global_position.z)
		) >= 0.72
		and (
			player.global_position.y
			- city.ground_height_at(player.global_position.x, player.global_position.z)
		) <= 0.96
		and city.road_surface_clearance_at(player.global_position) < 0.0,
		(
			"the rider should begin safely on the western harbour road"
			+ " position=%s ground=%.3f clearance=%.3f"
			% [
				player.global_position,
				city.ground_height_at(
					player.global_position.x,
					player.global_position.z
				),
				city.road_surface_clearance_at(player.global_position),
			]
		)
	)

	var roads: Array = city.get("_road_corridors")
	var maximum_grade := 0.0
	for corridor: Dictionary in roads:
		var from: Vector2 = corridor.from
		var to: Vector2 = corridor.to
		var length := from.distance_to(to)
		_expect(
			is_finite(float(corridor.from_height))
			and is_finite(float(corridor.to_height)),
			"every Monaco road grade should be finite"
		)
		if length > 0.1:
			maximum_grade = maxf(
				maximum_grade,
				absf(float(corridor.to_height) - float(corridor.from_height)) / length
			)
	_expect(
		roads.size() >= 65 and maximum_grade < 0.135,
		"the corniches and switchbacks should remain challenging but rideable"
	)
	for sea_point in [
		Vector2(0.0, -224.0),
		Vector2(-180.0, -222.0),
		Vector2(180.0, -222.0),
		Vector2(-234.0, -40.0),
		Vector2(234.0, -40.0),
	]:
		_expect(
			city.ground_height_at(sea_point.x, sea_point.y) < WATER_LEVEL - 1.0,
			"Monaco's terrain should descend into ocean around every outer edge"
		)
	for island_point in [
		Vector2(0.0, -190.0),
		Vector2(-208.0, -184.0),
		Vector2(208.0, -184.0),
	]:
		_expect(
			city.ground_height_at(island_point.x, island_point.y) > WATER_LEVEL,
			"the northern cliff-top neighbourhood should remain on solid island terrain"
		)
	var paths: Array[Dictionary] = city.minimap_road_paths()
	var circumferential_route := {}
	for path: Dictionary in paths:
		if String(path.name) == "Island circumferential route":
			circumferential_route = path
		var points: Array = path.points
		for endpoint in [points.front(), points.back()]:
			var connections := 0
			for candidate_path: Dictionary in paths:
				for candidate: Vector3 in candidate_path.points:
					if Vector2(endpoint.x, endpoint.z).distance_to(
						Vector2(candidate.x, candidate.z)
					) < 0.01:
						connections += 1
			_expect(
				connections >= 2,
				"every Monaco road endpoint should join another road instead of ending sharply"
			)
	_expect(
		not circumferential_route.is_empty()
		and (circumferential_route.points as Array).size() >= 140
		and float(city.get_meta("circumferential_route_length_m", 0.0)) > 900.0,
		"Monaco should have a substantial connected circumferential cycle route"
	)
	for route_point: Vector3 in circumferential_route.points:
		_expect(
			city.ground_height_at(route_point.x, route_point.z) > WATER_LEVEL,
			"the circumferential route should stay on the island"
		)

	_expect(
		int(city.get_meta("monaco_building_count", 0)) >= 75
		and int(city.get_meta("monaco_palm_count", 0)) >= 10
		and int(city.get_meta("monaco_cypress_count", 0)) >= 18
		and int(city.get_meta("monaco_batched_plant_count", 0)) >= 140,
		"the hillside should combine dense Riviera housing, palms, and cypress gardens"
	)
	var facade_batches := get_nodes_in_group("monaco_facade_detail_batch")
	var facade_instances := 0
	var facade_batches_are_culled := true
	for batch: MultiMeshInstance3D in facade_batches:
		facade_instances += batch.multimesh.instance_count
		facade_batches_are_culled = (
			facade_batches_are_culled
			and batch.visibility_range_end > 0.0
			and batch.cast_shadow
			== GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		)
	_expect(
		facade_batches.size() >= 100
		and facade_batches.size() <= 220
		and facade_instances >= 4000
		and facade_batches_are_culled,
		(
			"repeated Monaco facade details should stay spatially batched"
			+ " and distance-culled (batches=%d instances=%d)"
			% [facade_batches.size(), facade_instances]
		)
	)
	for landmark_name in [
		"Monte Carlo Casino",
		"Prince's Palace",
		"Cathedral of Our Lady Immaculate",
		"Oceanographic Museum",
		"Stade Louis II",
		"Grimaldi Forum",
		"Jardin Exotique",
		"Fontvieille Marina",
		"Larvotto Grand Prix tunnel",
		"Port Hercule marina",
		"Larvotto Beach",
	]:
		_expect(
			city.get_node_or_null(landmark_name) != null,
			"Monaco should include the %s landmark" % landmark_name
		)
	_expect(
		get_nodes_in_group("rideable_tunnel").size() == 1
		and get_nodes_in_group("tunnel_light").size() == 5
		and get_nodes_in_group("tunnel_emissive_strip").size() == 2
		and get_nodes_in_group("tunnel_acoustic_zone").size() == 1
		and get_nodes_in_group("marina_yacht").size() == 4
		and get_nodes_in_group("fontvieille_boat").size() == 1
		and int(city.get_meta("larvotto_parasol_count", 0)) >= 4
		and get_nodes_in_group("monaco_mountain_backdrop").size() == 9,
		(
			"the tunnel, marina, safe beach parasols, yachts, and mainland"
			+ " skyline should be fully dressed"
		)
	)
	var belle_epoque_count := 0
	var old_town_count := 0
	for building in get_nodes_in_group("monaco_building"):
		match String(building.get_meta("district_style", "")):
			"Belle Epoque":
				belle_epoque_count += 1
			"Le Rocher old town":
				old_town_count += 1
	_expect(
		belle_epoque_count >= 30
		and old_town_count >= 8
		and get_nodes_in_group("monaco_modern_tower").size() >= 2,
		"Belle Epoque, Le Rocher, and modern Monaco should read as separate architecture"
	)
	_expect(
		get_nodes_in_group("monaco_route_landmark").size() == 10
		and int(city.get_meta("monaco_curb_section_count", 0)) >= 50
		and int(city.get_meta("monaco_armco_count", 0)) >= 1
		and get_nodes_in_group("monaco_cafe_terrace").size() == 1,
		"the Grand Prix route should have named corners, curbs, Armco, and street life"
	)

	var pickup_locations: Array[Dictionary] = city.pickup_locations()
	var dropoff_locations: Array[Dictionary] = city.dropoff_locations()
	_expect(
		pickup_locations.size() == 8
		and dropoff_locations.size() == 10
		and get_nodes_in_group("pickup_sign").size() == 8
		and get_nodes_in_group("freestanding_shop_sign").size() == 8,
		"Monaco should have its own grounded pickup and delivery network"
	)
	for location: Dictionary in pickup_locations + dropoff_locations:
		var point: Vector3 = location.position
		_expect(
			city.ground_height_at(point.x, point.z) > WATER_LEVEL
			and city.road_surface_clearance_at(point) < 0.75,
			"every Monaco objective should be reachable from a road"
		)
	var order_service = game.get_node("Services/OrderService")
	_expect(
		(order_service.get("_pickups") as Array).size() == 8
		and (order_service.get("_dropoffs") as Array).size() == 10,
		"the shared order service should consume Monaco's locations"
	)

	var counts: Dictionary = street_life.get_agent_counts()
	_expect(
		int(counts.traffic) >= 10
		and int(counts.pedestrians) >= 18
		and int(counts.wildlife) == 4
		and int(counts.farm_animals) == 0
		and int(counts.birds) >= 8,
		"Monaco should feel alive without copying the island farm"
	)
	_expect(
		game.get_node("DeliveryHud/CourierMap/Title").text == "MONACO MAP",
		"the courier app should display Monaco's dedicated minimap"
	)

	var clock = game.get_node("Services/WorldClock")
	_expect(
		float(game.get_node("Services/TimeOfDay").mediterranean_warmth) >= 0.5,
		"Monaco should use warmer Riviera daylight than the Caledonian level"
	)
	clock.set_hour(22.0)
	await process_frame
	var working_lamps := get_nodes_in_group("working_street_lamp")
	_expect(
		working_lamps.size() == 14,
		"fourteen waterfront and corniche lamps should be installed"
	)
	for lamp: OmniLight3D in working_lamps:
		_expect(
			lamp.visible and lamp.light_energy > 1.5,
			"Monaco's street lamps should work after dusk"
		)

	game.queue_free()
	await process_frame
	print("Monaco scene smoke test passed.")
	quit()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
