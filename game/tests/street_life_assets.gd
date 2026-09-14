extends SceneTree

const StreetLife = preload("res://src/world/street_life_manager.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var factory := Node3D.new()
	factory.set_script(StreetLife)
	var actors: Array[Node3D] = []
	for index in 5:
		actors.append(factory._create_car(index))
	for index in 4:
		actors.append(factory._create_pedestrian(index))
	actors.append(factory._create_animal(0))
	actors.append(factory._create_animal(2))
	for species in ["horse", "cow", "pig", "goose"]:
		actors.append(factory._create_farm_animal(species, 0))
	for actor in actors:
		var meshes := actor.find_children("*", "MeshInstance3D", true, false)
		assert(meshes.size() == 1, "Each actor must have one combined mesh")
		assert(meshes[0].material_override.vertex_color_use_as_albedo, "Palette must be enabled")
		var mesh: Mesh = meshes[0].mesh
		assert(mesh.get_surface_count() == 1, "One draw surface per actor")
		var arrays := mesh.surface_get_arrays(0)
		assert(arrays[Mesh.ARRAY_INDEX].size() / 3 <= 5000, "Triangle budget")
		assert(arrays[Mesh.ARRAY_COLOR].size() > 0, "Vertex palette must survive export")
		var bounds := mesh.get_aabb()
		assert(absf(bounds.position.y) < 0.035, "Grounded Y-up export")
		assert(bounds.size.y < 2.6 and bounds.size.y > 0.7, "Correct world scale")
	var duplicate: Node3D = factory._create_car(5)
	assert(duplicate.find_children("*", "MeshInstance3D", true, false)[0].mesh == actors[0].find_children("*", "MeshInstance3D", true, false)[0].mesh, "Repeated vehicles share mesh memory")
	duplicate.free()
	if "--capture" in OS.get_cmdline_user_args():
		await _capture(actors)
	else:
		for actor in actors: actor.free()
	factory.free()
	print("Street-life assets passed: 15 grounded models, one surface each, shared resources, <= 5000 triangles.")
	quit()

func _capture(actors: Array[Node3D]) -> void:
	root.size = Vector2i(1440, 960)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("bfd9de")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("c9e2ed")
	environment.environment.ambient_light_energy = 0.65
	stage.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_color = Color("fff0d5")
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	stage.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(35, 22)
	floor_mesh.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("8fae9f")
	floor_mesh.material_override = material
	stage.add_child(floor_mesh)
	for i in actors.size():
		var actor := actors[i]
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		stage.add_child(actor)
		var offset := 0.52 if i < 5 else (0.9 if i < 9 else (0.45 if i < 11 else 0.0))
		actor.position = Vector3(float(i % 5) * 4.1 - 8.2, offset, float(i / 5) * 4.7 - 4.7)
		actor.rotation.y = -0.35
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(10, 15, -22)
	camera.look_at(Vector3(0, .6, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 25
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/bikegame_street_life.png")
	stage.queue_free()
	await process_frame
