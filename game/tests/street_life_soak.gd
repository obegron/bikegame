extends SceneTree

const SIMULATED_SECONDS := 600.0
const TIME_SCALE := 30.0


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
	Engine.time_scale = TIME_SCALE

	var traffic_start_positions := {}
	var traffic_max_displacements := {}
	var traffic_min_heights := {}
	for agent in get_nodes_in_group("traffic"):
		traffic_start_positions[agent] = agent.global_position
		traffic_max_displacements[agent] = 0.0
		traffic_min_heights[agent] = agent.global_position.y

	var frames := int(SIMULATED_SECONDS * Engine.physics_ticks_per_second / TIME_SCALE)
	for frame in frames:
		await physics_frame
		if frame % 10 == 0:
			for agent in traffic_start_positions:
				var displacement: float = agent.global_position.distance_to(
					traffic_start_positions[agent]
				)
				traffic_max_displacements[agent] = maxf(
					float(traffic_max_displacements[agent]),
					displacement
				)
				traffic_min_heights[agent] = minf(
					float(traffic_min_heights[agent]),
					agent.global_position.y
				)

	Engine.time_scale = 1.0
	var street_life = game.get_node("StreetLife")
	var counts: Dictionary = street_life.get_agent_counts()
	_expect(counts.traffic <= 14, "traffic pool should not grow during soak")
	_expect(counts.pedestrians <= 24, "pedestrian pool should not grow during soak")
	_expect(counts.wildlife <= 8, "wildlife pool should not grow during soak")
	_expect(counts.farm_animals == 9, "the farm animal pool should remain at nine")
	_expect(counts.birds <= 9, "bird pool should not grow during soak")
	for group in ["traffic", "pedestrian", "wildlife", "farm_animal", "bird"]:
		for agent in get_nodes_in_group(group):
			_expect(agent.global_position.is_finite(), "%s position should remain finite" % group)
	for agent in traffic_max_displacements:
		_expect(
			float(traffic_max_displacements[agent]) > 8.0,
			"%s should circulate instead of remaining stuck" % agent.name
		)
		_expect(
			float(traffic_min_heights[agent]) > 0.1,
			"%s should follow bridge decks instead of snapping into a channel" % agent.name
		)

	game.queue_free()
	await process_frame
	print("Street-life soak passed: simulated %d seconds." % int(SIMULATED_SECONDS))
	quit()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		Engine.time_scale = 1.0
		push_error(message)
		quit(1)
