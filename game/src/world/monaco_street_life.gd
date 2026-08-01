extends "res://src/world/street_life_manager.gd"


func _city() -> Node:
	return get_tree().get_first_node_in_group("terrain_provider")


func _spawn_traffic_signals() -> void:
	for index in 2:
		var signal_controller := Node3D.new()
		signal_controller.name = "MonacoTrafficSignals%02d" % index
		signal_controller.set_script(TrafficSignalScript)
		signal_controller.configure(
			Vector3(-35.0, 0.0, -5.0) if index == 0 else Vector3(85.0, 0.0, 10.0),
			float(index) * 7.4,
			8.9
		)
		signal_controller.rotation.y = -0.14 if index == 0 else 0.33
		add_child(signal_controller)
		_traffic_signals.append(signal_controller)


func _spawn_traffic() -> void:
	var terrain := _city()
	if terrain == null or not terrain.has_method("traffic_routes"):
		return
	var routes: Array[Array] = terrain.call("traffic_routes")
	for index in 11:
		var route_index := index % routes.size()
		var route: Array[Vector3] = []
		route.assign(routes[route_index])
		var segment_index := index % route.size()
		var next_index := (segment_index + 1) % route.size()
		var progress := 0.14 + float(index % 4) * 0.2
		var car := _create_car(index)
		car.configure(route, next_index, 4.2 + float(route_index) * 0.35)
		car.position = route[segment_index].lerp(route[next_index], progress)
		add_child(car)
		_traffic.append(car)


func _spawn_pedestrians() -> void:
	var terrain := _city()
	if terrain == null or not terrain.has_method("pedestrian_routes"):
		return
	var routes: Array[Array] = terrain.call("pedestrian_routes")
	for index in 20:
		var route_index := index % routes.size()
		var route: Array[Vector3] = []
		route.assign(routes[route_index])
		var segment_index := int(index / routes.size()) % route.size()
		var next_index := (segment_index + 1) % route.size()
		var pedestrian := _create_pedestrian(index)
		pedestrian.configure(route, next_index)
		pedestrian.position = route[segment_index].lerp(
			route[next_index],
			0.16 + float(index % 4) * 0.2
		)
		add_child(pedestrian)
		_pedestrians.append(pedestrian)


func _spawn_wildlife() -> void:
	var terrain := _city()
	if terrain == null or not terrain.has_method("wildlife_routes"):
		return
	var routes: Array[Array] = terrain.call("wildlife_routes")
	for index in 4:
		var route: Array[Vector3] = []
		route.assign(routes[index % routes.size()])
		var animal := _create_animal(index)
		animal.configure(route, index % route.size())
		animal.position = route[index % route.size()]
		add_child(animal)
		_wildlife.append(animal)


func _spawn_farm_animals() -> void:
	# Monaco's animal life is limited to dogs, gulls, and the occasional fox;
	# farm species remain distinctive to Caledonian Island.
	pass


func _spawn_birds() -> void:
	var flock_centers := [
		Vector3(-45.0, 26.0, 65.0),
		Vector3(28.0, 34.0, -52.0),
		Vector3(142.0, 24.0, 94.0),
	]
	for index in 9:
		var flock_index := index / 3
		var bird := _create_bird(index)
		bird.configure(
			flock_centers[flock_index],
			9.0 + float(index % 3) * 2.0,
			0.27 + float(index % 3) * 0.04,
			float(index % 3) * TAU / 3.0 + float(flock_index) * 0.5
		)
		add_child(bird)
		_birds.append(bird)
