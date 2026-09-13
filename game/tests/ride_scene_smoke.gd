extends SceneTree

const DeliveryOrderType = preload("res://src/core/delivery_order.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed := load("res://scenes/delivery_game.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.get_node("Onboarding/Overlay").visible = false
	paused = false

	var player = game.get_node("Player")
	var city = game.get_node("City")
	var street_life = game.get_node("StreetLife")
	var minimap = game.get_node_or_null("DeliveryHud/CourierMap")
	_expect(minimap != null, "delivery HUD should include the courier minimap")
	_expect(
		game.get_node_or_null("City/Saint Brigid church") != null,
		"expanded city should include the heritage church"
	)
	_expect(
		game.get_node_or_null("City/Saint Claire canal") != null,
		"expanded city should include the canal"
	)
	_expect(
		city.ground_height_at(0.0, -6.0) - city.ground_height_at(44.0, 48.0) > 3.2,
		"the old-town core should rise clearly above its perimeter streets"
	)
	_expect(
		int(city.get_meta("old_town_curved_lane_count", 0)) == 7
		and get_nodes_in_group("old_town_cobble_junction").size() == 9,
		"the medieval core should use crooked continuous lanes and clean cobble joins"
	)
	_expect(
		get_nodes_in_group("organic_market_square").size() == 1
		and get_nodes_in_group("old_town_infill").size() >= 4
		and get_nodes_in_group("staggered_old_town_house").size() >= 7,
		"the civic hill should use an irregular square and staggered roofscape"
	)
	var road_corridors: Array = city.get("_road_corridors")
	var maximum_road_grade := 0.0
	var maximum_core_grade := 0.0
	for corridor: Dictionary in road_corridors:
		var corridor_from: Vector2 = corridor.from
		var corridor_to: Vector2 = corridor.to
		var corridor_length := corridor_from.distance_to(corridor_to)
		_expect(
			is_finite(float(corridor.from_height))
			and is_finite(float(corridor.to_height)),
			"every audited road endpoint should have a finite terrain grade"
		)
		if corridor_length < 0.1:
			continue
		var grade := (
			absf(float(corridor.to_height) - float(corridor.from_height))
			/ corridor_length
		)
		maximum_road_grade = maxf(maximum_road_grade, grade)
		if (
			maxf(absf(corridor_from.x), absf(corridor_to.x)) <= 65.0
			and maxf(absf(corridor_from.y), absf(corridor_to.y)) <= 60.0
		):
			maximum_core_grade = maxf(maximum_core_grade, grade)
	_expect(
		road_corridors.size() >= 107
		and maximum_road_grade < 0.195
		and maximum_core_grade < 0.13,
		"the post-rebuild road audit should preserve connected, rideable grades"
	)
	var flower_pots = game.get_node_or_null("City/Terracotta street flower pots")
	_expect(
		int(city.get_meta("city_flower_pot_count", 0)) == 14
		and flower_pots is MultiMeshInstance3D
		and flower_pots.multimesh.instance_count == 14,
		"the market should have fourteen batched flowering terracotta pots"
	)
	var garlands := get_nodes_in_group("hanging_garland")
	var garland_masts := get_nodes_in_group("garland_anchor_mast")
	_expect(
		garlands.size() == 5 and garland_masts.size() == 4,
		"the market square should have a five-line hanging garland canopy"
	)
	for garland: Node3D in garlands:
		_expect(
			float(garland.get_meta("minimum_ground_clearance", 0.0)) > 4.75,
			"hanging garlands should remain safely above riders and traffic"
		)
	for mast: StaticBody3D in garland_masts:
		_expect(
			float(mast.get_meta("road_clearance", 0.0)) > 7.0,
			"garland masts should remain well outside every drivable lane"
		)
	var canal = game.get_node("City/Saint Claire canal")
	_expect(
		canal is MeshInstance3D and canal.material_override is ShaderMaterial,
		"the canal should use the animated water material"
	)
	var canal_material := canal.material_override as ShaderMaterial
	_expect(
		int(canal_material.get_meta("lightweight_wave_cascade_count", 0)) == 5
		and bool(canal_material.get_meta("distance_faded_wave_detail", false)),
		"water should use five distance-faded analytical wave bands"
	)
	_expect(
		get_nodes_in_group("water_reflection").size() == 2,
		"river and canal should each capture environmental reflections"
	)
	var environment = game.get_node("WorldEnvironment").environment
	_expect(
		environment.background_mode == Environment.BG_SKY
		and environment.sky != null
		and environment.sky.sky_material is ShaderMaterial,
		"day and night should use the dynamic cloud-and-star sky"
	)
	var sky_material := environment.sky.sky_material as ShaderMaterial
	var time_of_day = game.get_node("Services/TimeOfDay")
	_expect(
		bool(sky_material.get_meta("layered_cloud_sky", false))
		and bool(sky_material.get_meta("sculpted_cloud_sky", false)),
		"the dynamic sky should use the sculpted toy cloud treatment"
	)
	_expect(
		time_of_day.get_meta(
			"rare_shooting_star_interval_seconds",
			Vector2.ZERO
		) == Vector2(150.0, 360.0)
		and not time_of_day.trigger_shooting_star(),
		"shooting stars should be exceptionally rare and unable to appear in daylight"
	)
	var weather = game.get_node("Services/Weather")
	weather.automatic_weather = false
	var rain_particles := weather.get_rain_particles() as GPUParticles3D
	_expect(
		weather.current_weather == "clear"
		and rain_particles != null
		and not rain_particles.emitting,
		"weather should begin clear with its local rain emitter dormant"
	)
	weather.set_weather("rain", true)
	await process_frame
	_expect(
		rain_particles.emitting
		and rain_particles.amount_ratio > 0.99
		and environment.fog_enabled
		and environment.fog_density > 0.01
		and float(sky_material.get_shader_parameter("cloud_coverage")) > 0.85,
		"rain should bring dense clouds, mist, and rider-centred rain streaks"
	)
	weather.trigger_lightning()
	await process_frame
	var lightning := get_nodes_in_group("weather_lightning")[0] as DirectionalLight3D
	var lightning_bolt := get_nodes_in_group("weather_lightning_bolt")[0] as MeshInstance3D
	_expect(
		lightning.light_energy > 0.75
		and float(sky_material.get_shader_parameter("lightning_flash")) > 0.9,
		"rainstorms should occasionally illuminate both the sky and the city"
	)
	_expect(
		lightning_bolt.visible
		and lightning_bolt.mesh.get_surface_count() == 1,
		"the strongest flash should draw a forked lightning bolt"
	)
	weather.set_weather("fog", true)
	await process_frame
	_expect(
		not rain_particles.emitting
		and environment.fog_density > 0.03,
		"fog should reduce visibility without leaving rain particles active"
	)
	weather.set_weather("clear", true)
	await process_frame
	_expect(
		not environment.fog_enabled
		and is_equal_approx(
			float(sky_material.get_shader_parameter("cloud_coverage")),
			0.36
		),
		"clear weather should restore the normal sky and visibility"
	)
	var street_lamps := get_nodes_in_group("working_street_lamp")
	_expect(street_lamps.size() == 12, "all twelve old-town lamp posts should cast light")
	var lighthouses := get_nodes_in_group("coastal_lighthouse")
	var lighthouse_lights := get_nodes_in_group("lighthouse_light")
	var lighthouse_beams := get_nodes_in_group("working_lighthouse_beam")
	_expect(
		lighthouses.size() == 1
		and lighthouse_lights.size() == 2
		and lighthouse_beams.size() == 1
		and city.road_surface_clearance_at(lighthouses[0].global_position) > 20.0,
		"one cliff-top lighthouse should overlook the sea without obstructing a road"
	)
	for lighthouse_light: Light3D in lighthouse_lights:
		_expect(not lighthouse_light.visible, "the lighthouse should remain dark by day")
	var bike_headlight := game.get_node("Player/Camera3D/BikeHeadlight") as SpotLight3D
	_expect(not bike_headlight.visible, "the bicycle headlight should stay off in daylight")
	var boats := get_nodes_in_group("distant_boat")
	var boat_lights := get_nodes_in_group("boat_navigation_light")
	var seen_ship_types := {}
	var motor_ship_count := 0
	var signature_parts := {
		"motorboat": "Original cream cabin",
		"tanker": "Long black hull",
		"sailing": "Main cream sail",
		"cruise": "Passenger deck 2",
		"fishing": "Forward wheelhouse",
	}
	for boat: Node3D in boats:
		var ship_type := str(boat.get_meta("ship_type", ""))
		_expect(
			signature_parts.has(ship_type)
			and not seen_ship_types.has(ship_type)
			and boat.get_node_or_null(signature_parts[ship_type]) != null,
			"every selected distant ship should have one distinct, non-duplicated silhouette"
		)
		seen_ship_types[ship_type] = true
		if ship_type != "sailing":
			motor_ship_count += 1
	_expect(
		boats.size() >= 2
		and boats.size() <= 3
		and seen_ship_types.size() == boats.size()
		and get_nodes_in_group("boat_smoke").size() == motor_ship_count
		and boat_lights.size() == boats.size() * 3,
		"the horizon should show a sparse randomized fleet with working lights and appropriate smoke"
	)
	for lamp: OmniLight3D in street_lamps:
		_expect(not lamp.visible, "street lamps should remain off after sunrise")
		_expect(
			city.road_surface_clearance_at(lamp.global_position) > 0.45,
			"lamp posts should remain outside the drivable road surface"
		)
	var world_clock = game.get_node("Services/WorldClock")
	world_clock.set_hour(22.0)
	await process_frame
	_expect(
		time_of_day.trigger_shooting_star(),
		"a clear full night should permit a shooting star"
	)
	await process_frame
	_expect(
		float(sky_material.get_shader_parameter("shooting_star_visibility")) > 0.0
		and (
			sky_material.get_shader_parameter("shooting_star_from") as Vector3
		).distance_to(
			sky_material.get_shader_parameter("shooting_star_to") as Vector3
		) > 0.2,
		"a triggered shooting star should briefly cross the dynamic night sky"
	)
	for lamp: OmniLight3D in street_lamps:
		_expect(
			lamp.visible and lamp.light_energy > 1.5,
			"street lamps should illuminate the city at night"
		)
	_expect(
		lighthouse_beams[0].is_visible_in_tree(),
		"the lighthouse beam should sweep the coast after dusk"
	)
	for lighthouse_light: Light3D in lighthouse_lights:
		_expect(
			lighthouse_light.visible and lighthouse_light.light_energy > 2.0,
			"the lighthouse lantern and sea beam should work at night"
		)
	_expect(
		bike_headlight.visible
		and bike_headlight.light_energy > 9.0
		and bike_headlight.spot_range >= 40.0,
		"the bicycle should cast a useful forward headlight beam at night"
	)
	for marker: MeshInstance3D in boat_lights:
		var marker_material := marker.material_override as StandardMaterial3D
		_expect(
			marker_material.emission_energy_multiplier > 5.0,
			"boat navigation lights should glow at night"
		)
	var lamp_glass = game.get_node("City/Old town lamps")
	_expect(
		lamp_glass.material_override is StandardMaterial3D
		and lamp_glass.material_override.emission_enabled,
		"lit lamp glass should glow at night"
	)
	world_clock.set_hour(7.0)
	await process_frame
	for lamp: OmniLight3D in street_lamps:
		_expect(not lamp.visible, "street lamps should switch off again in daylight")
	_expect(not bike_headlight.visible, "the bicycle headlight should switch off after sunrise")
	_expect(
		float(sky_material.get_shader_parameter("shooting_star_visibility")) == 0.0
		and not lighthouse_beams[0].is_visible_in_tree(),
		"sunrise should clear the shooting star and switch off the lighthouse beam"
	)
	var daylight_sun := game.get_node("Sun") as DirectionalLight3D
	_expect(
		environment.ambient_light_energy < daylight_sun.light_energy * 0.5
		and environment.adjustment_enabled
		and environment.adjustment_contrast > 1.0,
		"direct daylight and contrast grading should model buildings without flat ambient wash"
	)
	_expect(
		environment.tonemap_exposure < 1.0,
		"daylight exposure should preserve color in pale sand, water, and plaster"
	)
	var guild_house = game.get_node("City/North guild house 03")
	var facade_meshes: Array[Node] = guild_house.find_children("*", "MeshInstance3D", true, false)
	_expect(
		not facade_meshes.is_empty()
		and facade_meshes[0].material_override is ShaderMaterial,
		"heritage buildings should use painted facade materials"
	)
	var facade_material := facade_meshes[0].material_override as ShaderMaterial
	var facade_color: Color = facade_material.get_shader_parameter("base_color")
	_expect(
		facade_color.a == 1.0 and facade_color.s > 0.15,
		"heritage façades should retain their opaque painted palette"
	)
	_expect(
		get_nodes_in_group("heritage_architecture_detail").size() >= 6
		and get_nodes_in_group("facade_vegetation").size() >= 3
		and get_nodes_in_group("gothic_window").size() >= 8,
		"houses and landmarks should include cornices, dormers, chimneys, planting, and Gothic detail"
	)
	var arrival_road = game.get_node("City/Southern arrival")
	_expect(
		arrival_road is MeshInstance3D
		and arrival_road.material_override is ShaderMaterial,
		"modern roads should use the satin road material"
	)
	_expect(
		get_nodes_in_group("textured_road").size() > 70,
		"asphalt, paving, and sidewalks should share the road surface treatment"
	)
	var foliage_instances := 0
	var foliage_variants := {}
	var foliage_uses_profile_data := true
	var foliage_uses_spatial_chunks := true
	var foliage_has_wind_material := false
	for foliage: MultiMeshInstance3D in get_nodes_in_group("foliage"):
		foliage_instances += foliage.multimesh.instance_count
		foliage_variants[foliage.get_meta("foliage_variant")] = true
		foliage_uses_profile_data = (
			foliage_uses_profile_data and foliage.multimesh.use_custom_data
		)
		foliage_uses_spatial_chunks = (
			foliage_uses_spatial_chunks and foliage.has_meta("foliage_chunk")
		)
		for surface_index in foliage.multimesh.mesh.get_surface_count():
			if foliage.multimesh.mesh.surface_get_material(surface_index) is ShaderMaterial:
				foliage_has_wind_material = true
	_expect(
		foliage_instances > 1100,
		"the city biomes should contain dense batched foliage (found %d)" % foliage_instances
	)
	_expect(
		foliage_variants.has("tree_oak")
		and foliage_variants.has("tree_cherry")
		and foliage_variants.has("bush_detailed")
		and foliage_variants.has("flower_yellow")
		and foliage_variants.has("dandelion_yellow")
		and foliage_variants.has("dandelion_seed"),
		"foliage should mix trees, blossoms, shrubs, grasses, and dandelions"
	)
	_expect(
		foliage_uses_profile_data
		and foliage_uses_spatial_chunks
		and foliage_has_wind_material,
		"foliage batches should carry wind, variation, and spatial culling data"
	)
	var city_foliage := game.get_node("City")
	_expect(
		int(city_foliage.get_meta("foliage_biome_west_meadow_groundcover", 0)) > 100
		and int(city_foliage.get_meta("foliage_biome_east_hillside_canopy", 0)) > 25
		and int(city_foliage.get_meta("foliage_biome_abbey_west_flower_bed", 0)) > 25
		and int(city_foliage.get_meta("foliage_biome_west_dandelion_drift", 0)) > 35
		and int(
			city_foliage.get_meta(
				"foliage_biome_island_wide_street_verge_mosaic",
				0
			)
		) > 250,
		"parks, hillsides, gardens, and street verges should have distinct planted layers"
	)
	var foliage_road_violations := 0
	var foliage_transforms: Dictionary = city_foliage.get("_foliage_transforms")
	for variant: String in foliage_transforms:
		var required_clearance := 1.2 if variant.begins_with("tree_") else 0.3
		for foliage_transform: Transform3D in foliage_transforms[variant]:
			if (
				city.road_surface_clearance_at(foliage_transform.origin)
				< required_clearance
			):
				foliage_road_violations += 1
	_expect(
		foliage_road_violations == 0,
		"trees and groundcover should remain outside bike and traffic lanes"
	)
	_expect(
		int(city.get_meta("road_rejected_building_count", 0)) >= 6,
		"procedural houses intersecting a road corridor should be rejected"
	)
	_expect(
		get_nodes_in_group("clean_road_merge").size() == 6,
		"all three north-bank bridge junctions should use clean raised merge aprons"
	)
	_expect(
		get_nodes_in_group("clean_coastal_merge").size() == 4,
		"the two acute coastal joins should use dedicated unified aprons"
	)
	_expect(
		get_nodes_in_group("clean_gateway_junction").size() == 8,
		"the Orchard, Hill, and east-coast gateways should use unified turning aprons"
	)
	for shop_building_name in [
		"Boulangerie du Pont",
		"Quayside pizzeria",
		"North Bank sushi",
		"Orchard farm shop",
	]:
		_expect(
			game.get_node_or_null("City/%s" % shop_building_name) != null,
			"specialist shops should have real storefront buildings"
		)
	_expect(
		game.get_node_or_null("City/North bank western merge") != null,
		"the problem north-bank junction should redraw one continuous priority road"
	)
	for removed_obstruction in [
		"North guild house 01",
		"North guild house 06",
		"South guild house 01",
		"South guild house 06",
		"Market stall 01",
		"Canal house 04",
		"South avenue terrace 09",
		"North guild house 00",
		"North guild house 02",
		"North guild house 05",
		"North guild house 07",
		"South guild house 00",
		"South guild house 02",
		"South guild house 05",
		"South guild house 07",
		"River close house 071",
		"Orchard cottage 00",
		"Orchard cottage 01",
	]:
		_expect(
			game.get_node_or_null("City/%s" % removed_obstruction) == null,
			"diagonal lanes and bridge approaches should not run under buildings"
		)
	_expect(
		is_equal_approx(game.get_node("City/University row 00").position.x, 91.0),
		"the university row should sit beyond Garden Avenue instead of on the road"
	)
	_expect(
		game.get_node_or_null("City/North quay") == null
		and game.get_node_or_null("City/North quay west") != null
		and game.get_node_or_null("City/North quay east") != null,
		"quay roads should stop at the canal instead of duplicating the bridge deck"
	)
	var old_mill = game.get_node("City/Old canal mill")
	var mill_wheel = game.get_node("City/Mill wheel")
	_expect(
		is_equal_approx(old_mill.position.z, -40.0)
		and mill_wheel.get_node_or_null("Rotating timber wheel/Timber rim") != null
		and mill_wheel.get_node("Rotating timber wheel").get_child_count() >= 18
		and mill_wheel.global_position.y < 1.5
		and get_nodes_in_group("mill_water_splash").size() == 1,
		"the mill wheel should clear the bridge, enter the water, and kick up spray"
	)
	var roofs := get_nodes_in_group("heritage_roof")
	_expect(roofs.size() > 50, "heritage buildings should use varied pitched roofs")
	_expect(
		get_nodes_in_group("hipped_roof").size() >= 4
		and get_nodes_in_group("house_shape_variant").size() >= 6,
		"the city should mix hipped roofs, cottage wings, and projecting bays"
	)
	for roof: Node3D in roofs:
		_expect(
			float(roof.get_meta("roof_clearance", -1.0)) > 0.0,
			"roof slopes should remain above the wall instead of clipping through it"
		)
		if roof.is_in_group("gabled_roof"):
			_expect(
				roof.get_node_or_null("Filled gable ends") != null,
				"every gabled roof should close its gable ends"
			)
	_expect(
		get_nodes_in_group("waterfront_door_landing").size() >= 4,
		"canal-facing doors should open onto stone loading platforms and steps"
	)
	var entry_stairs := get_nodes_in_group("heritage_entry_stair")
	_expect(
		entry_stairs.size() >= 20,
		"raised hillside and north-bank doors should have terrain-following stone stairs"
	)
	for entry_stair: Node3D in entry_stairs:
		_expect(
			city.road_surface_clearance_at(entry_stair.global_position) >= 0.27,
			"house entry stairs should remain outside bike and traffic lanes"
		)
	_expect(
		game.get_node_or_null("City/Meadowcroft farmhouse") != null
		and game.get_node_or_null("City/Meadowcroft barn") != null
		and game.get_node_or_null("City/Meadowcroft goose pond") != null
		and game.get_node_or_null("City/Meadowcroft farm lane") != null,
		"the orchard outskirts should include a road-accessible working farm"
	)
	_expect(
		get_nodes_in_group("farm_fence").size() >= 45
		and get_nodes_in_group("farm_landmark").size() >= 6,
		"Meadowcroft should have a fenced pasture, barnyard detail, and goose pond"
	)
	var sealed_foundations := get_nodes_in_group("terrain_sealed_foundation")
	_expect(
		sealed_foundations.size() >= 50,
		"heritage houses and rear wings should have terrain-sealing foundations"
	)
	for foundation: Node3D in sealed_foundations:
		_expect(
			float(foundation.get_meta("foundation_bottom", INF))
			< float(foundation.get_meta("sampled_ground_minimum", -INF)),
			"house foundations should extend below the lowest sampled terrain"
		)
	_expect(
		game.get_node_or_null("City/Market fountain/Animated fountain water") != null
		and game.get_node_or_null("City/Market fountain/Bronze courier") != null
		and get_nodes_in_group("fountain_water").size() >= 5
		and get_nodes_in_group("city_landmark").size() >= 1,
		"the market square should have an animated fountain and courier monument"
	)
	_expect(
		game.get_node_or_null("City/Grand river bridge") != null
		and game.get_node_or_null("City/Garden river bridge") != null
		and game.get_node_or_null("City/East river bridge") != null
		and game.get_node_or_null("City/West coast river bridge") != null
		and game.get_node_or_null("City/East coast river bridge") != null
		and game.get_node_or_null("City/South canal cycle bridge") != null,
		"all river and canal approaches should continue across rideable bridges"
	)
	_expect(
		absf(city.ground_height_at(-110.0, 75.0) - city.ground_height_at(-110.0, 81.0)) < 0.18,
		"terrain beneath the roadway should be graded flat across the cycle lanes"
	)
	_expect(
		game.get_node_or_null("City/West coast cycle road") != null
		and game.get_node_or_null("City/East coast cycle road") != null
		and game.get_node_or_null("City/West quay coastal link") != null
		and game.get_node_or_null("City/East quay coastal link") != null
		and game.get_node_or_null("City/Market to orchard link") != null,
		"promenade, quay, and market roads should feed connected district loops"
	)
	for coastal_join in [
		Vector3(-150.0, 0.0, -132.0),
		Vector3(-128.0, 0.0, 117.0),
		Vector3(150.0, 0.0, -121.0),
		Vector3(124.0, 0.0, 101.0),
		Vector3(-152.0, 0.0, -82.0),
		Vector3(152.0, 0.0, -82.0),
		Vector3(-182.0, 0.0, -68.0),
		Vector3(186.0, 0.0, -94.0),
		Vector3(-132.0, 0.0, 18.0),
		Vector3(-144.0, 0.0, 4.0),
	]:
		_expect(
			city.road_surface_clearance_at(coastal_join) < -3.5,
			"coastal road joins should overlap cleanly instead of leaving sharp dead ends"
		)
	_expect(
		get_nodes_in_group("surrounding_ocean").size() == 1
		and get_nodes_in_group("island_terrain").size() == 1
		and get_nodes_in_group("coastal_cliff_rock").size() >= 8,
		"the city should sit inside an ocean with beaches and rocky headlands"
	)
	var island_terrain := get_nodes_in_group("island_terrain")[0] as MeshInstance3D
	var terrain_arrays := island_terrain.mesh.surface_get_arrays(0)
	var terrain_material := island_terrain.material_override as ShaderMaterial
	_expect(
		terrain_arrays[Mesh.ARRAY_COLOR].size() == terrain_arrays[Mesh.ARRAY_VERTEX].size()
		and terrain_material.get_shader_parameter("macro_noise_texture") != null,
		"terrain should carry a control map and broad color variation"
	)
	_expect(
		city.ground_height_at(0.0, 185.0) < city.ground_height_at(0.0, 150.0)
		and city.ground_height_at(224.0, -20.0) < city.ground_height_at(200.0, -20.0) - 2.0,
		"the island edge should descend through beaches and steep cliff sectors"
	)
	_expect(
		absf(city.ground_height_at(145.0, 38.0) - city.ground_height_at(0.0, 0.0)) > 0.25,
		"outskirts should have terrain elevation"
	)
	var hill_house = game.get_node("City/Hill village house 00")
	var road_clearance := INF
	for road_segment in [
		[Vector3(76.0, 0.0, 119.0), Vector3(124.0, 0.0, 101.0)],
		[Vector3(124.0, 0.0, 101.0), Vector3(118.0, 0.0, 78.0)],
		[Vector3(118.0, 0.0, 78.0), Vector3(129.0, 0.0, 67.0)],
		[Vector3(-122.0, 0.0, 78.0), Vector3(118.0, 0.0, 78.0)],
	]:
		road_clearance = minf(
			road_clearance,
			_distance_xz_to_segment(hill_house.global_position, road_segment[0], road_segment[1])
		)
	_expect(road_clearance > 15.0, "hill cottage should remain outside every road corridor")
	var start_position: Vector3 = player.global_position
	Input.action_press("bike_pedal")
	Input.action_press("bike_steer_right")
	for _frame in 30:
		await physics_frame
	Input.action_release("bike_pedal")
	Input.action_release("bike_steer_right")

	_expect(player.get_speed_kph() > 0.5, "pedal action should accelerate the bike")
	_expect(player.global_position.distance_to(start_position) > 0.05, "bike should move through the world")
	_expect(absf(player.rotation.y) > 0.005, "steering action should change heading")
	var counts: Dictionary = street_life.get_agent_counts()
	_expect(counts.traffic == 12, "morning should activate twelve traffic agents")
	_expect(counts.pedestrians == 18, "morning should activate eighteen pedestrians")
	_expect(counts.wildlife == 8, "morning should keep wildlife visible")
	_expect(counts.farm_animals == 9, "the farm should keep all nine animals visible")
	_expect(counts.birds == 9, "morning should activate all three small bird flocks")
	var farm_species := {"horse": 0, "cow": 0, "pig": 0, "goose": 0}
	for animal: Node3D in get_nodes_in_group("farm_animal"):
		var species := String(animal.get_meta("species", ""))
		if farm_species.has(species):
			farm_species[species] += 1
		_expect(
			animal.global_position.is_finite()
			and city.road_surface_clearance_at(animal.global_position) > 1.0,
			"farm animals should remain finite and safely inside the pasture"
		)
	_expect(
		farm_species == {"horse": 1, "cow": 1, "pig": 2, "goose": 5},
		"Meadowcroft should have one horse, one cow, two pigs, and five geese"
	)
	for agent in get_nodes_in_group("traffic"):
		_expect(agent.global_position.is_finite(), "traffic position should remain finite")
	var birds := get_nodes_in_group("bird")
	_expect(birds.size() == 9, "street life should pool nine flying birds")
	for bird: Node3D in birds:
		_expect(
			bird.global_position.is_finite() and bird.global_position.y > 8.0,
			"birds should circle safely above the city"
		)
	var traffic_signals := get_nodes_in_group("traffic_signal")
	_expect(traffic_signals.size() == 3, "three modern junctions should have traffic lights")
	var first_signal = traffic_signals[0]
	var signal_state: String = first_signal.get_signal_state()
	_expect(
		signal_state in ["x_green", "x_amber", "z_green", "z_amber"],
		"traffic signals should expose a valid synchronized phase"
	)
	if signal_state == "x_green":
		_expect(
			not first_signal.should_stop(
				first_signal.global_position - Vector3.RIGHT * 8.0,
				Vector3.RIGHT
			),
			"east-west traffic should proceed on its green phase"
		)
		_expect(
			first_signal.should_stop(
				first_signal.global_position - Vector3.FORWARD * 8.0,
				Vector3.FORWARD
			),
			"north-south traffic should stop on east-west green"
		)

	var orders = game.order_service
	orders.automatic_generation = false
	orders.offers.clear()
	var offered_order = orders.create_offer()
	await process_frame
	await process_frame
	var marker = game.get_node_or_null("ObjectiveMarker")
	_expect(marker != null and marker.visible, "an offered pickup should show its world beacon")
	var customer_card = game.get_node("DeliveryHud/ObjectivePanel/Margin/VBox/CustomerRow")
	var customer_portrait = customer_card.get_node("Portrait") as TextureRect
	var customer_text = customer_card.get_node("Customer") as Label
	_expect(
		customer_card.visible
		and customer_portrait.texture != null
		and offered_order.customer_name in customer_text.text,
		"offers should show their named customer's illustrated portrait"
	)
	_expect(
		get_nodes_in_group("pickup_sign").size() == 8,
		"each restaurant should retain a nearby navigation label"
	)
	var shop_signs := get_nodes_in_group("shop_sign")
	_expect(shop_signs.size() == 8, "each restaurant should have a painted facade sign")
	var expected_shops := {
		"Market Hall": true,
		"Boulangerie du Pont": true,
		"Old Mill Bakery": true,
		"South Gate Burger Bar": true,
		"Quayside Pizzeria": true,
		"North Bank Sushi": true,
		"Hilltop Thai Kitchen": true,
		"Orchard Farm Shop": true,
	}
	for shop_sign: Node3D in shop_signs:
		var shop_name := String(shop_sign.get_meta("shop_name", ""))
		_expect(expected_shops.has(shop_name), "facade signs should use the new cuisine roster")
		var artwork := shop_sign.get_node_or_null("Shop artwork") as MeshInstance3D
		_expect(
			artwork != null
			and artwork.material_override is StandardMaterial3D
			and artwork.material_override.albedo_texture != null,
			"each painted shop sign should load its generated artwork"
		)
	var mill_sign: Node3D
	for shop_sign: Node3D in shop_signs:
		if String(shop_sign.get_meta("shop_name", "")) == "Old Mill Bakery":
			mill_sign = shop_sign
			break
	_expect(
		mill_sign != null
		and absf(mill_sign.global_position.z - mill_wheel.global_position.z) > 5.0,
		"the mill wheel should no longer cover the bakery sign"
	)
	var badge_gallery = game.get_node("PauseMenu/Overlay/Center/Panel/Margin/VBox/BadgeGallery")
	_expect(badge_gallery.get_child_count() == 6, "pause menu should show all six award badges")
	game._on_achievement_unlocked("first_delivery", "First delivery")
	await process_frame
	var award_badge: TextureRect = game.get_node("DeliveryHud/ResultPanel/Margin/ResultRow/Badge")
	_expect(
		award_badge.visible and award_badge.texture != null,
		"an achievement popup should show its graphic award badge"
	)
	player.global_position = offered_order.pickup_position + Vector3(0.0, 0.9, 0.0)
	await process_frame
	await process_frame
	await process_frame
	_expect(
		orders.active_order == offered_order
		and offered_order.state == DeliveryOrderType.State.TO_DROPOFF,
		"riding into an offered pickup should accept and collect it"
	)

	game.queue_free()
	await process_frame
	print("Ride scene smoke test passed.")
	quit()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _distance_xz_to_segment(point: Vector3, from: Vector3, to: Vector3) -> float:
	var point_2d := Vector2(point.x, point.z)
	var from_2d := Vector2(from.x, from.z)
	var to_2d := Vector2(to.x, to.z)
	var segment := to_2d - from_2d
	if segment.is_zero_approx():
		return point_2d.distance_to(from_2d)
	var weight := clampf((point_2d - from_2d).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point_2d.distance_to(from_2d.lerp(to_2d, weight))
