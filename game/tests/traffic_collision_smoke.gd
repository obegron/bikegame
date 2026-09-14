extends SceneTree

const Factory = preload("res://src/world/street_life_manager.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var factory := Node3D.new()
	factory.set_script(Factory)
	var lead: CharacterBody3D = factory._create_car(0)
	var follower: CharacterBody3D = factory._create_car(1)
	root.add_child(lead)
	root.add_child(follower)
	lead.position = Vector3(0, 0.52, 0)
	follower.position = Vector3(0, 0.52, 6)
	lead.set_physics_process(false)
	follower.set_physics_process(false)
	var route: Array[Vector3] = [Vector3(0, .52, -20), Vector3(0, .52, 20)]
	follower.configure(route, 0, 5.5)
	await physics_frame
	# Simulate a stopped queue beyond the old 2.2-second drive-through timeout.
	for step in 480:
		follower._physics_process(1.0 / 60.0)
		await physics_frame
		assert(follower.position.z >= 3.35, "Queued cars must never interpenetrate")
	assert(follower.position.z < 6, "The follower must approach the queue")
	# Bypass the steering sensor to exercise physical protection independently.
	follower.velocity = Vector3(0, 0, -300)
	follower.move_and_slide()
	assert(follower.position.z >= 3.35, "Traffic collision layers must block contact")
	# A waiting car must resume when the car in front clears the lane.
	lead.position.x = 10
	await physics_frame
	var stopped_z := follower.position.z
	for step in 30:
		follower._physics_process(1.0 / 60.0)
		await physics_frame
	assert(follower.position.z < stopped_z - 1, "Traffic must resume after the queue clears")
	lead.queue_free()
	follower.queue_free()
	factory.free()
	await process_frame
	print("Traffic collision smoke passed: queue, physical contact, and resumption.")
	quit()
