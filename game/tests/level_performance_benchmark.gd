extends SceneTree

# A graphical, repeatable comparison of the two playable levels. Run with:
#   xvfb-run -a godot --path game --script res://tests/level_performance_benchmark.gd
#
# The software renderer used under Xvfb is not representative of a player's
# absolute FPS. It is useful for a controlled A/B comparison because both
# levels render through exactly the same viewport, renderer, and camera route.

const WARMUP_FRAMES := 30
const SAMPLE_FRAMES_PER_VIEW := 45

const LEVELS := [
	{
		"id": "caledonian",
		"scene": "res://scenes/delivery_game.tscn",
		"views": [
			[Vector3(0.0, 0.0, 112.0), Vector3(0.0, 0.0, 58.0)],
			[Vector3(-126.0, 0.0, 75.0), Vector3(-82.0, 0.0, 22.0)],
			[Vector3(0.0, 0.0, -84.0), Vector3(54.0, 0.0, -47.0)],
			[Vector3(124.0, 0.0, 72.0), Vector3(78.0, 0.0, 18.0)],
		],
	},
	{
		"id": "monaco",
		"scene": "res://scenes/monaco_game.tscn",
		"views": [
			[Vector3(-88.0, 0.0, 108.0), Vector3(-94.0, 0.0, 78.0)],
			[Vector3(-5.0, 0.0, -65.0), Vector3(-28.0, 0.0, -62.0)],
			[Vector3(145.0, 0.0, 32.0), Vector3(112.0, 0.0, 2.0)],
			[Vector3(-122.0, 0.0, 17.0), Vector3(-132.0, 0.0, -7.0)],
		],
	},
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var requested_level := ""
	var arguments := OS.get_cmdline_user_args()
	for index in arguments.size():
		if arguments[index] == "--level" and index + 1 < arguments.size():
			requested_level = arguments[index + 1].to_lower()
	var results: Array[Dictionary] = []
	for level_data: Dictionary in LEVELS:
		if (
			not requested_level.is_empty()
			and String(level_data.id) != requested_level
		):
			continue
		results.append(await _benchmark_level(level_data))
	if results.is_empty():
		push_error("Unknown benchmark level '%s'" % requested_level)
		quit(2)
		return
	if results.size() == 2:
		var caledonian: Dictionary = results[0]
		var monaco: Dictionary = results[1]
		print(
			"PERF_COMPARE monaco_vs_caledonian"
			+ " frame_time_ratio=%.3f" % (
				float(monaco.average_frame_ms)
				/ maxf(float(caledonian.average_frame_ms), 0.001)
			)
			+ " draw_call_ratio=%.3f" % (
				float(monaco.average_draw_calls)
				/ maxf(float(caledonian.average_draw_calls), 1.0)
			)
			+ " primitive_ratio=%.3f" % (
				float(monaco.average_primitives)
				/ maxf(float(caledonian.average_primitives), 1.0)
			)
			+ " node_ratio=%.3f" % (
				float(monaco.node_count)
				/ maxf(float(caledonian.node_count), 1.0)
			)
		)
	quit()


func _benchmark_level(level_data: Dictionary) -> Dictionary:
	var construction_started := Time.get_ticks_usec()
	var packed := load(String(level_data.scene)) as PackedScene
	var game := packed.instantiate()
	root.add_child(game)
	var construction_ms := (
		float(Time.get_ticks_usec() - construction_started) / 1000.0
	)
	await process_frame
	await process_frame
	_prepare_game(game)

	var player := game.get_node("Player") as CharacterBody3D
	var camera := game.get_node("Player/Camera3D") as Camera3D
	var city := game.get_node("City")
	_place_camera(player, camera, city, level_data.views[0])
	for _frame in WARMUP_FRAMES:
		await process_frame

	var frame_times: Array[float] = []
	var draw_calls: Array[float] = []
	var rendered_objects: Array[float] = []
	var primitives: Array[float] = []
	for view: Array in level_data.views:
		_place_camera(player, camera, city, view)
		for _settle in 4:
			await process_frame
		for _frame in SAMPLE_FRAMES_PER_VIEW:
			var frame_started := Time.get_ticks_usec()
			await process_frame
			frame_times.append(
				float(Time.get_ticks_usec() - frame_started) / 1000.0
			)
			draw_calls.append(_monitor(
				Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME
			))
			rendered_objects.append(_monitor(
				Performance.RENDER_TOTAL_OBJECTS_IN_FRAME
			))
			primitives.append(_monitor(
				Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME
			))

	var scene_counts := _count_scene_nodes(game)
	var result := {
		"id": String(level_data.id),
		"construction_ms": construction_ms,
		"average_frame_ms": _average(frame_times),
		"median_frame_ms": _percentile(frame_times, 0.5),
		"p95_frame_ms": _percentile(frame_times, 0.95),
		"average_draw_calls": _average(draw_calls),
		"average_rendered_objects": _average(rendered_objects),
		"average_primitives": _average(primitives),
		"node_count": int(scene_counts.nodes),
		"mesh_count": int(scene_counts.meshes),
		"multimesh_count": int(scene_counts.multimeshes),
		"multimesh_instances": int(scene_counts.multimesh_instances),
	}
	print(
		"PERF level=%s" % result.id
		+ " construction_ms=%.2f" % result.construction_ms
		+ " average_frame_ms=%.3f" % result.average_frame_ms
		+ " median_frame_ms=%.3f" % result.median_frame_ms
		+ " p95_frame_ms=%.3f" % result.p95_frame_ms
		+ " estimated_fps=%.1f" % (
			1000.0 / maxf(float(result.average_frame_ms), 0.001)
		)
		+ " draw_calls=%.1f" % result.average_draw_calls
		+ " rendered_objects=%.1f" % result.average_rendered_objects
		+ " primitives=%.0f" % result.average_primitives
		+ " nodes=%d" % result.node_count
		+ " meshes=%d" % result.mesh_count
		+ " multimeshes=%d" % result.multimesh_count
		+ " multimesh_instances=%d" % result.multimesh_instances
	)
	game.queue_free()
	await process_frame
	await process_frame
	return result


func _prepare_game(game: Node) -> void:
	for node_path in ["Onboarding/Overlay", "DeliveryHud", "PauseMenu"]:
		var node := game.get_node_or_null(node_path)
		if node is CanvasItem:
			node.visible = false
	var clock := game.get_node_or_null("Services/WorldClock")
	if clock != null:
		clock.call("set_hour", 10.5)
	var weather := game.get_node_or_null("Services/Weather")
	if weather != null:
		weather.call("set_weather", "clear", true)


func _place_camera(
	player: CharacterBody3D,
	camera: Camera3D,
	city: Node,
	view: Array
) -> void:
	var camera_position: Vector3 = view[0]
	var camera_target: Vector3 = view[1]
	camera_position.y = (
		float(city.call(
			"ground_height_at",
			camera_position.x,
			camera_position.z
		))
		+ 0.9
	)
	camera_target.y = (
		float(city.call(
			"ground_height_at",
			camera_target.x,
			camera_target.z
		))
		+ 1.5
	)
	player.velocity = Vector3.ZERO
	player.global_position = camera_position
	player.look_at(camera_target, Vector3.UP)
	camera.rotation = Vector3.ZERO


func _count_scene_nodes(scene_root: Node) -> Dictionary:
	var counts := {
		"nodes": 0,
		"meshes": 0,
		"multimeshes": 0,
		"multimesh_instances": 0,
	}
	var pending: Array[Node] = [scene_root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		counts.nodes = int(counts.nodes) + 1
		if node is MultiMeshInstance3D:
			counts.multimeshes = int(counts.multimeshes) + 1
			var multimesh := (node as MultiMeshInstance3D).multimesh
			if multimesh != null:
				counts.multimesh_instances = (
					int(counts.multimesh_instances)
					+ multimesh.instance_count
				)
		elif node is MeshInstance3D:
			counts.meshes = int(counts.meshes) + 1
		for child: Node in node.get_children():
			pending.append(child)
	return counts


func _monitor(monitor: Performance.Monitor) -> float:
	return float(Performance.get_monitor(monitor))


func _average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value: float in values:
		total += value
	return total / float(values.size())


func _percentile(values: Array[float], percentile: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted_values := values.duplicate()
	sorted_values.sort()
	var index := clampi(
		roundi(percentile * float(sorted_values.size() - 1)),
		0,
		sorted_values.size() - 1
	)
	return sorted_values[index]
