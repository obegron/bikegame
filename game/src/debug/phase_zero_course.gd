extends Node3D

const GROUND_COLOR := Color("8aa36b")
const ROAD_COLOR := Color("4c5359")
const CURB_COLOR := Color("d6d2c4")
const BARRIER_COLOR := Color("e9724c")
const GATE_COLOR := Color("f3c969")


func _ready() -> void:
	_make_box("Ground", Vector3(0.0, -0.15, -5.0), Vector3(72.0, 0.3, 96.0), GROUND_COLOR)
	_make_visual_box("Road", Vector3(0.0, 0.015, -5.0), Vector3(18.0, 0.03, 94.0), ROAD_COLOR)
	_make_boundaries()
	_make_slalom()
	_make_narrow_gate()
	_make_district_blocks()


func _make_boundaries() -> void:
	_make_box("Left curb", Vector3(-9.25, 0.35, -5.0), Vector3(0.5, 0.7, 94.0), CURB_COLOR, true)
	_make_box("Right curb", Vector3(9.25, 0.35, -5.0), Vector3(0.5, 0.7, 94.0), CURB_COLOR, true)
	_make_box("Far curb", Vector3(0.0, 0.35, -51.75), Vector3(19.0, 0.7, 0.5), CURB_COLOR, true)
	_make_box("Start curb", Vector3(0.0, 0.35, 41.75), Vector3(19.0, 0.7, 0.5), CURB_COLOR, true)


func _make_slalom() -> void:
	var z_positions := [18.0, 8.0, -2.0, -12.0]
	for index in z_positions.size():
		var side := -1.0 if index % 2 == 0 else 1.0
		_make_box(
			"Slalom %d" % index,
			Vector3(side * 3.4, 0.65, z_positions[index]),
			Vector3(4.5, 1.3, 0.8),
			BARRIER_COLOR,
			true
		)


func _make_narrow_gate() -> void:
	_make_box("Gate left", Vector3(-2.1, 1.25, -25.0), Vector3(0.55, 2.5, 0.55), GATE_COLOR, true)
	_make_box("Gate right", Vector3(2.1, 1.25, -25.0), Vector3(0.55, 2.5, 0.55), GATE_COLOR, true)
	_make_visual_box("Gate lintel", Vector3(0.0, 2.5, -25.0), Vector3(4.75, 0.35, 0.35), GATE_COLOR)


func _make_district_blocks() -> void:
	var downtown := Color("7698b3")
	var residential := Color("c9a66b")
	for index in 5:
		var z := 30.0 - index * 17.0
		var height := 2.0 + float(index % 3) * 1.5
		_make_visual_box(
			"West block %d" % index,
			Vector3(-16.0, height * 0.5, z),
			Vector3(10.0, height, 10.0),
			downtown
		)
		_make_visual_box(
			"East block %d" % index,
			Vector3(16.0, 1.25, z),
			Vector3(10.0, 2.5, 10.0),
			residential
		)


func _make_box(
	node_name: String,
	at: Vector3,
	size: Vector3,
	color: Color,
	is_obstacle := false
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	if is_obstacle:
		body.add_to_group("obstacle")

	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)

	var mesh := BoxMesh.new()
	mesh.size = size
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color)
	body.add_child(mesh_instance)
	add_child(body)
	return body


func _make_visual_box(node_name: String, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = at
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color)
	add_child(mesh_instance)
	return mesh_instance


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material
