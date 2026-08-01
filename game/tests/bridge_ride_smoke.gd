extends SceneTree


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
	player.global_position = Vector3(
		0.0,
		city.ground_height_at(0.0, -90.0) + 0.9,
		-90.0
	)
	player.rotation.y = 0.0
	player.set_reset_transform_to_current()
	Input.action_press("bike_pedal")
	for _frame in 240:
		await physics_frame
	Input.action_release("bike_pedal")

	if not player.global_position.is_finite():
		_fail("bridge ride should remain numerically stable")
		return
	if player.global_position.z >= -114.0:
		_fail("bike should cross the grand river bridge")
		return
	if player.global_position.y <= -1.0:
		_fail("bridge should support the bike above the river")
		return

	player.global_position = Vector3(
		58.0,
		city.ground_height_at(58.0, -90.0) + 0.9,
		-90.0
	)
	player.rotation.y = 0.0
	player.set_reset_transform_to_current()
	player._reset_to_start()
	Input.action_press("bike_pedal")
	for _frame in 240:
		await physics_frame
	Input.action_release("bike_pedal")
	if player.global_position.z >= -114.0:
		_fail("bike should cross the new Garden Avenue river bridge")
		return
	if player.global_position.y <= -1.0:
		_fail("Garden Avenue bridge should support the bike above the river")
		return

	player.global_position = Vector3(
		-87.0,
		city.ground_height_at(-87.0, 122.4) + 0.9,
		122.4
	)
	player.rotation.y = -PI * 0.5
	player.set_reset_transform_to_current()
	player._reset_to_start()
	Input.action_press("bike_pedal")
	for _frame in 260:
		await physics_frame
	Input.action_release("bike_pedal")
	if player.global_position.x <= -61.0:
		_fail(
			"bike should cross the south boulevard canal bridge (stopped at %s)"
			% player.global_position
		)
		return
	if player.global_position.y <= -1.0:
		_fail("south boulevard bridge should support the bike above the canal")
		return

	# The east coast bridge used to spill into stacked road ribbons and an
	# obstructed quay. Ride its complete mouth-to-bank transition so that a
	# visually plausible but physically blocked bridge cannot regress.
	player.global_position = Vector3(
		187.0,
		city.ground_height_at(187.0, -89.0) + 0.9,
		-89.0
	)
	player.rotation.y = 0.31
	player.set_reset_transform_to_current()
	player._reset_to_start()
	Input.action_press("bike_pedal")
	for _frame in 260:
		await physics_frame
	Input.action_release("bike_pedal")
	if player.global_position.z >= -114.0:
		_fail(
			"bike should cross the east coast bridge and its repaired approach (stopped at %s)"
			% player.global_position
		)
		return
	if player.global_position.y <= -1.0:
		_fail("east coast bridge should support the bike above the river")
		return

	game.queue_free()
	await process_frame
	print("Rideable bridge smoke test passed.")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
