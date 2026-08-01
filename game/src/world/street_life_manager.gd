extends Node3D

const TrafficAgentScript = preload("res://src/agents/traffic_agent.gd")
const PedestrianAgentScript = preload("res://src/agents/pedestrian_agent.gd")
const WildlifeAgentScript = preload("res://src/agents/wildlife_agent.gd")
const FarmAnimalAgentScript = preload("res://src/agents/farm_animal_agent.gd")
const BirdAgentScript = preload("res://src/agents/bird_agent.gd")
const TrafficSignalScript = preload("res://src/world/traffic_signal_controller.gd")

@export var clock_path: NodePath

@onready var _clock = get_node(clock_path)

var _traffic: Array[Node3D] = []
var _pedestrians: Array[Node3D] = []
var _wildlife: Array[Node3D] = []
var _farm_animals: Array[Node3D] = []
var _birds: Array[Node3D] = []
var _traffic_signals: Array[Node3D] = []


func _ready() -> void:
	_spawn_traffic_signals()
	_spawn_traffic()
	_spawn_pedestrians()
	_spawn_wildlife()
	_spawn_farm_animals()
	_spawn_birds()
	_clock.phase_changed.connect(_apply_density)
	_apply_density(_clock.get_phase())


func get_agent_counts() -> Dictionary:
	return {
		"traffic": _count_active(_traffic),
		"pedestrians": _count_active(_pedestrians),
		"wildlife": _count_active(_wildlife),
		"farm_animals": _count_active(_farm_animals),
		"birds": _count_active(_birds),
	}


func _spawn_traffic_signals() -> void:
	var signal_data := [
		[Vector3(0.0, 0.0, 78.0), 0.0],
		[Vector3(58.0, 0.0, 78.0), 5.6],
		[Vector3(58.0, 0.0, -54.0), 11.2],
	]
	for index in signal_data.size():
		var signal_controller := Node3D.new()
		signal_controller.name = "TrafficSignals%02d" % index
		signal_controller.set_script(TrafficSignalScript)
		signal_controller.configure(signal_data[index][0], signal_data[index][1])
		add_child(signal_controller)
		_traffic_signals.append(signal_controller)


func _spawn_traffic() -> void:
	var loop_a: Array[Vector3] = [
		Vector3(-48.0, 0.52, 48.0),
		Vector3(-53.0, 0.52, 10.0),
		Vector3(-48.0, 0.52, -54.0),
		Vector3(48.0, 0.52, -54.0),
		Vector3(53.0, 0.52, 8.0),
		Vector3(48.0, 0.52, 48.0),
	]
	var loop_b: Array[Vector3] = [
		Vector3(58.0, 0.52, 78.0),
		Vector3(118.0, 0.52, 78.0),
		Vector3(129.0, 0.52, 67.0),
		Vector3(147.0, 0.52, 38.0),
		Vector3(143.0, 0.52, 2.0),
		Vector3(128.0, 0.52, -34.0),
		Vector3(104.0, 0.52, -54.0),
		Vector3(58.0, 0.52, -54.0),
	]
	var loop_c: Array[Vector3] = [
		Vector3(-122.0, 0.52, 78.0),
		Vector3(-137.0, 0.52, 96.0),
		Vector3(-128.0, 0.52, 117.0),
		Vector3(-72.0, 0.52, 124.0),
		Vector3(0.0, 0.52, 124.0),
		Vector3(76.0, 0.52, 119.0),
		Vector3(124.0, 0.52, 101.0),
		Vector3(118.0, 0.52, 78.0),
	]
	for index in 14:
		var route := loop_a
		if index >= 6 and index < 11:
			route = loop_b
		elif index >= 11:
			route = loop_c
		var segment_index := index % route.size()
		var next_index := (segment_index + 1) % route.size()
		var progress := 0.18 + float(index % 4) * 0.19
		var car := _create_car(index)
		var route_speed := 4.7 if index < 6 else 5.1
		car.configure(route, next_index, route_speed)
		car.position = route[segment_index].lerp(route[next_index], progress)
		add_child(car)
		_traffic.append(car)


func _spawn_pedestrians() -> void:
	var routes: Array[Array] = [
		[
			Vector3(-16.5, 0.9, 5.5),
			Vector3(16.5, 0.9, 5.5),
			Vector3(16.5, 0.9, -20.0),
			Vector3(-16.5, 0.9, -20.0),
		],
		[
			Vector3(-62.5, 0.9, 70.0),
			Vector3(-62.5, 0.9, 23.0),
			Vector3(-62.5, 0.9, -49.0),
			Vector3(-62.5, 0.9, -76.0),
		],
		[
			Vector3(64.0, 0.9, 43.0),
			Vector3(84.0, 0.9, 43.0),
			Vector3(84.0, 0.9, 1.0),
			Vector3(64.0, 0.9, 1.0),
		],
		[
			Vector3(-7.5, 0.9, 114.0),
			Vector3(7.5, 0.9, 114.0),
			Vector3(7.5, 0.9, 96.0),
			Vector3(-7.5, 0.9, 96.0),
		],
		[
			Vector3(-85.0, 0.9, -128.0),
			Vector3(-25.0, 0.9, -128.0),
			Vector3(30.0, 0.9, -131.0),
			Vector3(82.0, 0.9, -126.0),
		],
		[
			Vector3(112.0, 0.9, 83.0),
			Vector3(132.0, 0.9, 69.0),
			Vector3(145.0, 0.9, 42.0),
			Vector3(138.0, 0.9, 18.0),
		],
	]
	for index in 24:
		var route_index := index % routes.size()
		var typed_route: Array[Vector3] = []
		typed_route.assign(routes[route_index])
		var segment_index := int(index / routes.size()) % typed_route.size()
		var next_index := (segment_index + 1) % typed_route.size()
		var progress := 0.15 + float(index % 4) * 0.2
		var pedestrian := _create_pedestrian(index)
		pedestrian.configure(typed_route, next_index)
		pedestrian.position = typed_route[segment_index].lerp(typed_route[next_index], progress)
		add_child(pedestrian)
		_pedestrians.append(pedestrian)


func _spawn_wildlife() -> void:
	var garden_route: Array[Vector3] = [
		Vector3(66.0, 0.45, 3.0),
		Vector3(80.0, 0.45, 8.0),
		Vector3(68.0, 0.45, 19.0),
		Vector3(81.0, 0.45, 31.0),
		Vector3(67.0, 0.45, 41.0),
	]
	var orchard_route: Array[Vector3] = [
		Vector3(-160.0, 0.45, 74.0),
		Vector3(-144.0, 0.45, 55.0),
		Vector3(-157.0, 0.45, 29.0),
		Vector3(-137.0, 0.45, 5.0),
		Vector3(-153.0, 0.45, -19.0),
	]
	for index in 8:
		var route := garden_route if index < 4 else orchard_route
		var animal := _create_animal(index)
		animal.configure(route, index % route.size())
		animal.position = route[index % route.size()]
		add_child(animal)
		_wildlife.append(animal)


func _spawn_farm_animals() -> void:
	var animal_data: Array[Dictionary] = [
		{
			"species": "horse",
			"route": [
				Vector3(-132.0, 0.0, 30.0),
				Vector3(-124.0, 0.0, 29.0),
				Vector3(-123.0, 0.0, 37.0),
				Vector3(-128.0, 0.0, 43.0),
				Vector3(-133.0, 0.0, 39.0),
			],
			"speed": 0.82,
		},
		{
			"species": "cow",
			"route": [
				Vector3(-132.0, 0.0, 49.5),
				Vector3(-125.0, 0.0, 51.0),
				Vector3(-121.0, 0.0, 47.0),
				Vector3(-126.0, 0.0, 42.5),
				Vector3(-133.0, 0.0, 44.0),
			],
			"speed": 0.48,
		},
		{
			"species": "pig",
			"route": [
				Vector3(-120.0, 0.0, 49.5),
				Vector3(-114.5, 0.0, 51.0),
				Vector3(-109.0, 0.0, 48.5),
				Vector3(-114.0, 0.0, 46.0),
			],
			"speed": 0.58,
		},
		{
			"species": "pig",
			"route": [
				Vector3(-116.0, 0.0, 46.0),
				Vector3(-109.0, 0.0, 47.5),
				Vector3(-112.0, 0.0, 51.0),
				Vector3(-119.0, 0.0, 50.0),
			],
			"speed": 0.62,
		},
	]
	var goose_route: Array[Vector3] = [
		Vector3(-132.0, 0.0, 48.0),
		Vector3(-130.0, 0.0, 44.0),
		Vector3(-126.0, 0.0, 44.0),
		Vector3(-124.0, 0.0, 49.0),
		Vector3(-128.0, 0.0, 52.0),
	]
	for index in 5:
		animal_data.append({
			"species": "goose",
			"route": goose_route,
			"speed": 0.48 + float(index % 2) * 0.05,
		})

	var species_counts := {}
	for data: Dictionary in animal_data:
		var species := String(data.species)
		var species_index := int(species_counts.get(species, 0))
		species_counts[species] = species_index + 1
		var animal := _create_farm_animal(species, species_index)
		var route: Array[Vector3] = []
		route.assign(data.route)
		var start_index := species_index % route.size()
		if species == "goose":
			start_index = species_index
		animal.configure(route, start_index, float(data.speed))
		animal.position = route[start_index]
		add_child(animal)
		_farm_animals.append(animal)


func _spawn_birds() -> void:
	var flock_centers := [
		Vector3(-34.0, 17.5, -104.0),
		Vector3(0.0, 20.0, -4.0),
		Vector3(74.0, 15.5, 21.0),
	]
	for index in 9:
		var flock_index := index / 3
		var bird := _create_bird(index)
		bird.configure(
			flock_centers[flock_index],
			9.5 + float(index % 3) * 2.1,
			0.28 + float(index % 3) * 0.035,
			float(index % 3) * TAU / 3.0 + float(flock_index) * 0.45
		)
		add_child(bird)
		_birds.append(bird)


func _create_car(index: int) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = "Car%02d" % index
	body.set_script(TrafficAgentScript)
	body.collision_layer = 2
	body.collision_mask = 1
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.65, 1.0, 3.2)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var visual_root := Node3D.new()
	visual_root.name = "VisualRoot"
	body.add_child(visual_root)
	var colors := [Color("d95f59"), Color("4f86b8"), Color("e5b94f"), Color("77a26a")]
	var paint: Color = colors[index % colors.size()]
	var glass := Color("263e4b")
	# A readable bonnet/cabin/boot silhouette costs only a handful of boxes but
	# stops traffic reading as a single placeholder block from rider height.
	_add_box_multimesh(visual_root, "PaintedBody", [
		_scaled_visual_transform(Vector3(0.0, -0.12, 0.0), Vector3(1.72, 0.52, 3.18)),
		_scaled_visual_transform(Vector3(0.0, 0.18, -1.05), Vector3(1.64, 0.24, 0.92)),
		_scaled_visual_transform(Vector3(0.0, 0.17, 1.22), Vector3(1.64, 0.26, 0.62)),
		_scaled_visual_transform(Vector3(0.0, 0.48, 0.14), Vector3(1.42, 0.58, 1.42)),
		_scaled_visual_transform(Vector3(0.0, 0.79, 0.17), Vector3(1.3, 0.12, 1.08)),
	], paint)
	var glass_panels: Array[Transform3D] = [
		_scaled_visual_transform(Vector3(0.0, 0.49, -0.585), Vector3(1.18, 0.35, 0.035)),
		_scaled_visual_transform(Vector3(0.0, 0.49, 0.865), Vector3(1.18, 0.35, 0.035)),
	]
	var dark_trim: Array[Transform3D] = [
		_scaled_visual_transform(Vector3(0.0, -0.18, -1.64), Vector3(1.48, 0.11, 0.1)),
		_scaled_visual_transform(Vector3(0.0, -0.18, 1.64), Vector3(1.48, 0.11, 0.1)),
	]
	for side_x in [-0.718, 0.718]:
		glass_panels.append(_scaled_visual_transform(
			Vector3(side_x, 0.49, 0.15), Vector3(0.035, 0.35, 0.94)
		))
		dark_trim.append(_scaled_visual_transform(
			Vector3(side_x * 1.015, 0.27, 0.48), Vector3(0.025, 0.055, 0.22)
		))
	_add_box_multimesh(visual_root, "Glazing", glass_panels, glass)
	_add_box_multimesh(visual_root, "BumpersAndHandles", dark_trim, Color("33383a"))
	var headlights: Array[Transform3D] = []
	var tail_lights: Array[Transform3D] = []
	for light_x in [-0.55, 0.55]:
		headlights.append(_scaled_visual_transform(
			Vector3(light_x, 0.02, -1.605), Vector3(0.3, 0.18, 0.045)
		))
		tail_lights.append(_scaled_visual_transform(
			Vector3(light_x, 0.02, 1.605), Vector3(0.28, 0.17, 0.045)
		))
	_add_box_multimesh(visual_root, "Headlights", headlights, Color("f1d999"))
	_add_box_multimesh(visual_root, "TailLights", tail_lights, Color("9d292d"))
	var wheels: Array[Transform3D] = []
	var hubs: Array[Transform3D] = []
	for wheel_x in [-0.88, 0.88]:
		for wheel_z in [-1.03, 1.03]:
			wheels.append(_scaled_visual_transform(
				Vector3(wheel_x, -0.33, wheel_z), Vector3(0.27, 0.16, 0.27), 90.0
			))
			hubs.append(_scaled_visual_transform(
				Vector3(wheel_x, -0.33, wheel_z), Vector3(0.12, 0.175, 0.12), 90.0
			))
	_add_cylinder_multimesh(visual_root, "Tyres", wheels, Color("25292b"))
	_add_cylinder_multimesh(visual_root, "WheelHubs", hubs, Color("9ca2a0"))
	return body


func _create_pedestrian(index: int) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = "Pedestrian%02d" % index
	body.set_script(PedestrianAgentScript)
	body.collision_layer = 4
	body.collision_mask = 1
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.7
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var visual_root := Node3D.new()
	visual_root.name = "VisualRoot"
	body.add_child(visual_root)
	var coat_colors := [Color("6b82b4"), Color("d37f64"), Color("6ca07b"), Color("ac78a6")]
	var trouser_colors := [Color("344653"), Color("4a423c"), Color("33483c"), Color("514055")]
	var skin_colors := [Color("d6a276"), Color("8f5f43"), Color("efc29a"), Color("b87955")]
	var coat: Color = coat_colors[index % coat_colors.size()]
	var trousers: Color = trouser_colors[index % trouser_colors.size()]
	var skin: Color = skin_colors[index % skin_colors.size()]
	_add_capsule_visual(visual_root, "Torso", Vector3(0.0, 0.08, 0.0), 0.245, 0.82, coat)
	_add_sphere_visual(visual_root, "Head", Vector3(0.0, 0.65, 0.0), 0.19, skin)
	_add_box_visual(visual_root, "Hair", Vector3(0.0, 0.815, 0.015), Vector3(0.33, 0.1, 0.31), Color("49372d").lightened(float(index % 3) * 0.08))
	var legs: Array[Transform3D] = []
	var shoes: Array[Transform3D] = []
	for leg_x in [-0.13, 0.13]:
		legs.append(_scaled_visual_transform(
			Vector3(leg_x, -0.53, 0.0), Vector3(0.13, 0.62, 0.15)
		))
		shoes.append(_scaled_visual_transform(
			Vector3(leg_x, -0.82, -0.045), Vector3(0.16, 0.1, 0.27)
		))
	_add_box_multimesh(visual_root, "Legs", legs, trousers)
	_add_box_multimesh(visual_root, "Shoes", shoes, Color("292a2b"))
	var arms: Array[Transform3D] = []
	for arm_x in [-0.32, 0.32]:
		arms.append(_scaled_visual_transform(
			Vector3(arm_x, 0.06, 0.0),
			Vector3(0.12, 0.58, 0.13),
			-8.0 * signf(arm_x)
		))
	_add_box_multimesh(visual_root, "Arms", arms, coat.darkened(0.04))
	return body


func _create_animal(index: int) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = "Dog" if index < 2 else "Fox"
	body.set_script(WildlifeAgentScript)
	body.collision_layer = 8
	body.collision_mask = 1
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 0.9
	var collision := CollisionShape3D.new()
	collision.rotation_degrees.x = 90.0
	collision.shape = shape
	body.add_child(collision)
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.28
	mesh.height = 0.9
	var visual := MeshInstance3D.new()
	visual.rotation_degrees.x = 90.0
	visual.mesh = mesh
	visual.material_override = _material(Color("9a6a43") if index < 2 else Color("d66d3f"))
	body.add_child(visual)
	return body


func _create_farm_animal(species: String, index: int) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = "Farm%s%02d" % [species.capitalize(), index]
	body.set_script(FarmAnimalAgentScript)
	body.collision_layer = 8
	body.collision_mask = 1
	body.set_meta("species", species)
	var visual_root := Node3D.new()
	visual_root.name = "VisualRoot"
	body.add_child(visual_root)
	match species:
		"horse":
			_build_horse(body, visual_root)
		"cow":
			_build_cow(body, visual_root)
		"pig":
			_build_pig(body, visual_root, index)
		"goose":
			_build_goose(body, visual_root, index)
	return body


func _build_horse(body: CharacterBody3D, visual_root: Node3D) -> void:
	_set_farm_collision(body, Vector3(0.9, 1.65, 2.35), 0.84)
	var coat := Color("8e5639")
	var dark := Color("382a24")
	_add_capsule_visual(visual_root, "Body", Vector3(0.0, 1.22, 0.0), 0.48, 2.15, coat, 90.0)
	_add_box_visual(visual_root, "Neck", Vector3(0.0, 1.62, -0.82), Vector3(0.5, 1.25, 0.48), coat, -18.0)
	_add_capsule_visual(visual_root, "Head", Vector3(0.0, 2.08, -1.26), 0.27, 0.72, coat, 90.0)
	for x in [-0.3, 0.3]:
		for z in [-0.66, 0.66]:
			_add_box_visual(
				visual_root,
				"Leg",
				Vector3(x, 0.5, z),
				Vector3(0.16, 1.0, 0.17),
				coat
			)
	_add_box_visual(visual_root, "Mane", Vector3(0.0, 1.86, -0.74), Vector3(0.12, 0.78, 0.64), dark, -18.0)
	_add_box_visual(visual_root, "Tail", Vector3(0.0, 1.1, 1.2), Vector3(0.14, 0.72, 0.14), dark, 28.0)
	for x in [-0.14, 0.14]:
		_add_sphere_visual(visual_root, "Eye", Vector3(x, 2.17, -1.53), 0.035, Color("141313"))


func _build_cow(body: CharacterBody3D, visual_root: Node3D) -> void:
	_set_farm_collision(body, Vector3(1.15, 1.55, 2.35), 0.78)
	var hide := Color("e3d9bd")
	var patches := Color("3d3b37")
	_add_capsule_visual(visual_root, "Body", Vector3(0.0, 1.12, 0.0), 0.56, 2.15, hide, 90.0)
	_add_box_visual(visual_root, "Patch left", Vector3(-0.53, 1.2, 0.2), Vector3(0.07, 0.48, 0.72), patches, 12.0)
	_add_box_visual(visual_root, "Patch right", Vector3(0.53, 1.25, -0.46), Vector3(0.07, 0.42, 0.58), patches, -8.0)
	_add_sphere_visual(visual_root, "Head", Vector3(0.0, 1.5, -1.22), 0.43, hide)
	_add_box_visual(visual_root, "Muzzle", Vector3(0.0, 1.34, -1.57), Vector3(0.58, 0.32, 0.4), Color("c99d8d"))
	for x in [-0.36, 0.36]:
		for z in [-0.66, 0.66]:
			_add_box_visual(
				visual_root,
				"Leg",
				Vector3(x, 0.45, z),
				Vector3(0.18, 0.9, 0.2),
				patches
			)
	for x in [-0.28, 0.28]:
		_add_box_visual(visual_root, "Horn", Vector3(x, 1.9, -1.25), Vector3(0.12, 0.28, 0.12), Color("d8c58e"), x * 45.0)
		_add_sphere_visual(visual_root, "Eye", Vector3(x * 1.2, 1.62, -1.56), 0.04, Color("111111"))


func _build_pig(body: CharacterBody3D, visual_root: Node3D, index: int) -> void:
	_set_farm_collision(body, Vector3(0.7, 0.85, 1.35), 0.43)
	var pink := Color("d98e8f").lightened(float(index) * 0.035)
	_add_capsule_visual(visual_root, "Body", Vector3(0.0, 0.62, 0.0), 0.38, 1.25, pink, 90.0)
	_add_sphere_visual(visual_root, "Head", Vector3(0.0, 0.72, -0.72), 0.34, pink)
	_add_cylinder_visual(visual_root, "Snout", Vector3(0.0, 0.65, -1.0), 0.18, 0.22, Color("bc7177"), 90.0)
	for x in [-0.22, 0.22]:
		for z in [-0.34, 0.34]:
			_add_box_visual(visual_root, "Leg", Vector3(x, 0.2, z), Vector3(0.12, 0.4, 0.13), pink)
		_add_box_visual(visual_root, "Ear", Vector3(x, 1.0, -0.67), Vector3(0.2, 0.25, 0.08), pink, x * 40.0)
		_add_sphere_visual(visual_root, "Eye", Vector3(x, 0.79, -0.98), 0.027, Color("171313"))


func _build_goose(body: CharacterBody3D, visual_root: Node3D, index: int) -> void:
	_set_farm_collision(body, Vector3(0.42, 1.05, 0.72), 0.53)
	var feathers := Color("ece8d7").darkened(float(index % 3) * 0.025)
	var orange := Color("dc8c32")
	_add_capsule_visual(visual_root, "Body", Vector3(0.0, 0.45, 0.05), 0.22, 0.68, feathers, 90.0)
	_add_cylinder_visual(visual_root, "Neck", Vector3(0.0, 0.78, -0.19), 0.09, 0.62, feathers)
	_add_sphere_visual(visual_root, "Head", Vector3(0.0, 1.1, -0.2), 0.14, feathers)
	_add_box_visual(visual_root, "Beak", Vector3(0.0, 1.08, -0.38), Vector3(0.14, 0.08, 0.26), orange)
	for x in [-0.1, 0.1]:
		_add_box_visual(visual_root, "Foot", Vector3(x, 0.04, 0.02), Vector3(0.1, 0.07, 0.22), orange)
		_add_sphere_visual(visual_root, "Eye", Vector3(x * 0.75, 1.13, -0.32), 0.018, Color("101010"))


func _set_farm_collision(body: CharacterBody3D, size: Vector3, center_y: float) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.position.y = center_y
	collision.shape = shape
	body.add_child(collision)


func _scaled_visual_transform(
	at: Vector3,
	size: Vector3,
	rotation_z_degrees := 0.0
) -> Transform3D:
	var basis := Basis.IDENTITY.rotated(
		Vector3.FORWARD,
		deg_to_rad(rotation_z_degrees)
	)
	basis.x *= size.x
	basis.y *= size.y
	basis.z *= size.z
	return Transform3D(basis, at)


func _add_box_multimesh(
	parent: Node3D,
	node_name: String,
	transforms: Array,
	color: Color
) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	_add_visual_multimesh(parent, node_name, mesh, transforms, color)


func _add_cylinder_multimesh(
	parent: Node3D,
	node_name: String,
	transforms: Array,
	color: Color
) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 1.0
	mesh.radial_segments = 10
	_add_visual_multimesh(parent, node_name, mesh, transforms, color)


func _add_visual_multimesh(
	parent: Node3D,
	node_name: String,
	mesh: Mesh,
	transforms: Array,
	color: Color
) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	var visual := MultiMeshInstance3D.new()
	visual.name = node_name
	visual.multimesh = multimesh
	visual.material_override = _material(color)
	parent.add_child(visual)


func _add_box_visual(
	parent: Node3D,
	node_name: String,
	at: Vector3,
	size: Vector3,
	color: Color,
	rotation_z := 0.0
) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.position = at
	visual.rotation_degrees.z = rotation_z
	visual.mesh = mesh
	visual.material_override = _material(color)
	parent.add_child(visual)


func _add_sphere_visual(
	parent: Node3D,
	node_name: String,
	at: Vector3,
	radius: float,
	color: Color
) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.position = at
	visual.mesh = mesh
	visual.material_override = _material(color)
	parent.add_child(visual)


func _add_capsule_visual(
	parent: Node3D,
	node_name: String,
	at: Vector3,
	radius: float,
	height: float,
	color: Color,
	rotation_x := 0.0
) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 5
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.position = at
	visual.rotation_degrees.x = rotation_x
	visual.mesh = mesh
	visual.material_override = _material(color)
	parent.add_child(visual)


func _add_cylinder_visual(
	parent: Node3D,
	node_name: String,
	at: Vector3,
	radius: float,
	height: float,
	color: Color,
	rotation_x := 0.0
) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.position = at
	visual.rotation_degrees.x = rotation_x
	visual.mesh = mesh
	visual.material_override = _material(color)
	parent.add_child(visual)


func _create_bird(index: int) -> Node3D:
	var bird := Node3D.new()
	bird.name = "Bird%02d" % index
	bird.set_script(BirdAgentScript)
	var is_gull := index < 3
	var body_color := Color("e3e1d4") if is_gull else Color("65727a")
	var wing_color := Color("c7ccd0") if is_gull else Color("53616a")
	var body_material := _material(body_color)
	var wing_material := _material(wing_color)
	wing_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.1
	body_mesh.height = 0.42
	body_mesh.radial_segments = 8
	body_mesh.rings = 4
	var body := MeshInstance3D.new()
	body.rotation_degrees.x = 90.0
	body.mesh = body_mesh
	body.material_override = body_material
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bird.add_child(body)

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.105
	head_mesh.height = 0.21
	head_mesh.radial_segments = 8
	head_mesh.rings = 4
	var head := MeshInstance3D.new()
	head.position.z = -0.23
	head.mesh = head_mesh
	head.material_override = body_material
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bird.add_child(head)

	var left_wing := MeshInstance3D.new()
	left_wing.name = "LeftWing"
	left_wing.mesh = _bird_wing_mesh(1.0)
	left_wing.material_override = wing_material
	left_wing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bird.add_child(left_wing)
	var right_wing := MeshInstance3D.new()
	right_wing.name = "RightWing"
	right_wing.mesh = _bird_wing_mesh(-1.0)
	right_wing.material_override = wing_material
	right_wing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bird.add_child(right_wing)
	return bird


func _bird_wing_mesh(side: float) -> ArrayMesh:
	var vertices := PackedVector3Array([
		Vector3(0.0, 0.02, -0.06),
		Vector3(side * 0.56, 0.0, 0.1),
		Vector3(side * 0.15, 0.02, 0.32),
	])
	var normals := PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP])
	var indices := PackedInt32Array([0, 1, 2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _apply_density(phase: String) -> void:
	var traffic_count := 10
	var pedestrian_count := 16
	var wildlife_count := 6
	var bird_count := 7
	match phase:
		"morning":
			traffic_count = 12
			pedestrian_count = 18
			wildlife_count = 8
			bird_count = 9
		"noon":
			traffic_count = 14
			pedestrian_count = 24
			wildlife_count = 4
			bird_count = 8
		"sunset":
			traffic_count = 13
			pedestrian_count = 21
			wildlife_count = 6
			bird_count = 5
		"night":
			traffic_count = 5
			pedestrian_count = 7
			wildlife_count = 2
			bird_count = 0
	for index in _traffic.size():
		_set_agent_active(_traffic[index], index < traffic_count)
	for index in _pedestrians.size():
		_set_agent_active(_pedestrians[index], index < pedestrian_count)
	for index in _wildlife.size():
		_set_agent_active(_wildlife[index], index < wildlife_count)
	for index in _birds.size():
		_set_agent_active(_birds[index], index < bird_count)


func _set_agent_active(agent: Node3D, active: bool) -> void:
	agent.visible = active
	agent.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	var collision := agent.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null:
		collision.disabled = not active


func _count_active(agents: Array[Node3D]) -> int:
	var total := 0
	for agent in agents:
		if agent.process_mode != Node.PROCESS_MODE_DISABLED:
			total += 1
	return total


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	return material
