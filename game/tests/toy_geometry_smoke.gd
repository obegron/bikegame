extends SceneTree

const ToyGeometry = preload("res://src/world/toy_geometry.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	# Test thin trim and large buildings: rounding must stay inside collision
	# bounds, preserve outward winding, and share identical geometry.
	for size in [Vector3(0.1, 2.0, 0.2), Vector3(12.0, 18.0, 9.0), Vector3.ONE]:
		var mesh := ToyGeometry.rounded_box(size)
		assert(mesh == ToyGeometry.rounded_box(size), "Molded meshes should be reused")
		var arrays := mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for index in vertices.size():
			assert(vertices[index].abs().x <= size.x * 0.5 + 0.00001)
			assert(vertices[index].abs().y <= size.y * 0.5 + 0.00001)
			assert(vertices[index].abs().z <= size.z * 0.5 + 0.00001)
			assert(is_equal_approx(normals[index].length(), 1.0))
		for index in range(0, indices.size(), 3):
			var a := vertices[indices[index]]
			var b := vertices[indices[index + 1]]
			var c := vertices[indices[index + 2]]
			assert((c - a).cross(b - a).dot((a + b + c) / 3.0) > 0.0, "Molded faces must wind outward")
	var city := Node3D.new()
	city.set_script(load("res://src/world/delivery_city.gd"))
	# A synthetic nonplanar cell reproduces the visible hill-road failure.
	# It must remain above the rendered triangles even at interior points.
	var heights := PackedFloat32Array()
	heights.resize(city.TERRAIN_WIDTH * city.TERRAIN_DEPTH)
	heights[0] = 0.0
	heights[1] = 1.0
	heights[city.TERRAIN_WIDTH] = 2.0
	heights[city.TERRAIN_WIDTH + 1] = 0.2
	city._visual_terrain_heights = heights
	var origin := Vector3(city.TERRAIN_MIN_X, 0.0, city.TERRAIN_MIN_Z)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		origin + Vector3(0.2, 0.0, 0.2),
		origin + Vector3(2.3, 0.0, 0.3),
		origin + Vector3(2.2, 0.0, 2.2),
	])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0,1,2])
	var conformed: Array = city._conform_road_arrays(arrays, 0.1)
	var road_vertices: PackedVector3Array = conformed[Mesh.ARRAY_VERTEX]
	var road_indices: PackedInt32Array = conformed[Mesh.ARRAY_INDEX]
	assert(road_indices.size() > 3, "The road must split across the terrain diagonal")
	for index in range(0, road_indices.size(), 3):
		var center := (road_vertices[road_indices[index]] + road_vertices[road_indices[index + 1]] + road_vertices[road_indices[index + 2]]) / 3.0
		assert(absf(center.y - city._rendered_ground_height(center.x, center.z) - 0.1) < 0.0001, "Road interiors must follow the rendered surface")
	city.free()
	print("Toy geometry smoke test passed.")
	quit()
