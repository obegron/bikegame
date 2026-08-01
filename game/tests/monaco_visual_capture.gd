extends SceneTree

const OUTPUTS := [
	[
		"/tmp/bikegame_monaco_aerial.png",
		Vector3(0.0, 112.0, 178.0),
		Vector3(0.0, 8.0, -48.0),
	],
	[
		"/tmp/bikegame_monaco_north_coast.png",
		Vector3(0.0, 52.0, -268.0),
		Vector3(0.0, 25.0, -158.0),
	],
	[
		"/tmp/bikegame_monaco_harbour.png",
		Vector3(-116.0, 19.0, 116.0),
		Vector3(0.0, 7.0, 19.0),
	],
	[
		"/tmp/bikegame_monaco_rocher.png",
		Vector3(-205.0, 42.0, -104.0),
		Vector3(-119.0, 27.0, -130.0),
	],
	[
		"/tmp/bikegame_monaco_casino.png",
		Vector3(26.0, 21.0, -45.0),
		Vector3(-4.0, 13.0, -79.0),
	],
	[
		"/tmp/bikegame_monaco_ride_harbour.png",
		Vector3(-88.0, 0.0, 108.0),
		Vector3(-94.0, 0.0, 78.0),
	],
	[
		"/tmp/bikegame_monaco_ride_hairpin.png",
		Vector3(-5.0, 0.0, -65.0),
		Vector3(-28.0, 0.0, -62.0),
	],
	[
		"/tmp/bikegame_monaco_ride_east.png",
		Vector3(145.0, 0.0, 32.0),
		Vector3(112.0, 0.0, 2.0),
	],
	[
		"/tmp/bikegame_monaco_ride_palace.png",
		Vector3(-122.0, 0.0, 17.0),
		Vector3(-132.0, 0.0, -7.0),
	],
]


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var hour := 10.5
	var weather_name := "clear"
	var suffix := ""
	var arguments := OS.get_cmdline_user_args()
	for index in arguments.size():
		if arguments[index] == "--hour" and index + 1 < arguments.size():
			hour = float(arguments[index + 1])
		elif arguments[index] == "--weather" and index + 1 < arguments.size():
			weather_name = arguments[index + 1].to_lower()
		elif arguments[index] == "--suffix" and index + 1 < arguments.size():
			suffix = arguments[index + 1].to_lower()
	var packed := load("res://scenes/monaco_game.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.get_node("Onboarding/Overlay").visible = false
	game.get_node("DeliveryHud").visible = false
	game.get_node("PauseMenu").visible = false
	var clock = game.get_node("Services/WorldClock")
	clock.running = false
	clock.set_hour(hour)
	var weather = game.get_node("Services/Weather")
	weather.automatic_weather = false
	weather.call("set_weather", weather_name, true)
	game.get_node("Services/TimeOfDay").call("_process", 0.0)
	var player: CharacterBody3D = game.get_node("Player")
	var camera: Camera3D = game.get_node("Player/Camera3D")
	var city = game.get_node("City")
	for capture_data in OUTPUTS:
		var camera_position: Vector3 = capture_data[1]
		var camera_target: Vector3 = capture_data[2]
		if String(capture_data[0]).contains("_ride_"):
			camera_position.y = (
				city.ground_height_at(camera_position.x, camera_position.z) + 0.9
			)
			camera_target.y = (
				city.ground_height_at(camera_target.x, camera_target.z) + 1.5
			)
		player.global_position = camera_position
		player.look_at(camera_target, Vector3.UP)
		camera.rotation = Vector3.ZERO
		for _frame in 5:
			await process_frame
		var output_path := String(capture_data[0])
		if not suffix.is_empty():
			output_path = output_path.trim_suffix(".png") + "_" + suffix + ".png"
		var image := root.get_texture().get_image()
		image.save_png(output_path)
		print("Saved %s" % output_path)
	game.queue_free()
	await process_frame
	quit()
