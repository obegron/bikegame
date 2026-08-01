extends SceneTree

# Rider-height regression views for the Caledonian road joins most likely to
# expose overlapping ribbons, bridge seams, and steep gateway triangulation.
const VIEWS := [
	[
		"east_bridge_north",
		Vector3(179.0, 0.0, -121.0),
		Vector3(186.0, 0.0, -94.0),
	],
	[
		"east_bridge_south",
		Vector3(190.0, 0.0, -67.0),
		Vector3(186.0, 0.0, -94.0),
	],
	[
		"east_coast_gateway",
		Vector3(191.0, 0.0, -49.0),
		Vector3(190.0, 0.0, -67.0),
	],
	[
		"hill_gateway_outer",
		Vector3(157.0, 0.0, 108.0),
		Vector3(124.0, 0.0, 101.0),
	],
	[
		"hill_gateway_inner",
		Vector3(118.0, 0.0, 78.0),
		Vector3(123.4, 0.0, 72.6),
	],
	[
		"orchard_gateway",
		Vector3(-128.0, 0.0, 117.0),
		Vector3(-122.0, 0.0, 78.0),
	],
	[
		"south_canal_bridge",
		Vector3(-64.0, 0.0, 124.0),
		Vector3(-82.0, 0.0, 122.75),
	],
	[
		"bakery_facade",
		Vector3(-58.0, 0.0, 17.0),
		Vector3(-58.0, 0.0, 29.5),
		3.8,
	],
]


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var suffix := ""
	var arguments := OS.get_cmdline_user_args()
	for index in arguments.size():
		if arguments[index] == "--suffix" and index + 1 < arguments.size():
			suffix = "_" + arguments[index + 1].to_lower()
	var packed := load("res://scenes/delivery_game.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	for path in ["Onboarding/Overlay", "DeliveryHud", "PauseMenu"]:
		var overlay := game.get_node_or_null(path)
		if overlay != null:
			overlay.visible = false
	var clock = game.get_node("Services/WorldClock")
	clock.running = false
	clock.set_hour(12.0)
	var weather = game.get_node("Services/Weather")
	weather.automatic_weather = false
	weather.call("set_weather", "clear", true)
	game.get_node("Services/TimeOfDay").call("_process", 0.0)
	var player := game.get_node("Player") as CharacterBody3D
	var camera := game.get_node("Player/Camera3D") as Camera3D
	var city = game.get_node("City")
	for view: Array in VIEWS:
		var position: Vector3 = view[1]
		var target: Vector3 = view[2]
		position.y = city.travel_surface_height_at(position.x, position.z) + 0.9
		var target_lift := float(view[3]) if view.size() > 3 else 1.5
		target.y = city.travel_surface_height_at(target.x, target.z) + target_lift
		player.global_position = position
		player.look_at(target, Vector3.UP)
		camera.rotation = Vector3.ZERO
		for _frame in 5:
			await process_frame
		var output := "/tmp/bikegame_caledonian_%s%s.png" % [view[0], suffix]
		root.get_texture().get_image().save_png(output)
		print("Saved %s" % output)
	game.queue_free()
	await process_frame
	quit()
