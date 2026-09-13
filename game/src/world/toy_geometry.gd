extends RefCounted
## Shared molded shapes. Collision boxes retain their original dimensions.

static var _boxes: Dictionary = {}

static func rounded_box(size: Vector3) -> ArrayMesh:
	if _boxes.has(size):
		return _boxes[size]
	var half := size * 0.5
	var radius := minf(0.24, minf(size.x, minf(size.y, size.z)) * 0.16)
	var core := half - Vector3.ONE * radius
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Two narrow strips around each flat face form a smooth molded bevel.
	for axis in 3:
		var u_axis := (axis + 1) % 3
		var v_axis := (axis + 2) % 3
		for sign_value in [-1.0, 1.0]:
			var us := [-half[u_axis], -core[u_axis], core[u_axis], half[u_axis]]
			var vs := [-half[v_axis], -core[v_axis], core[v_axis], half[v_axis]]
			for u in 3:
				for v in 3:
					var corners: Array[Vector2i] = [Vector2i(u,v), Vector2i(u+1,v), Vector2i(u+1,v+1), Vector2i(u,v+1)]
					var order := [0,2,1,0,3,2] if sign_value > 0 else [0,1,2,0,2,3]
					for index in order:
						var point := Vector3.ZERO
						point[axis] = half[axis] * sign_value
						point[u_axis] = us[corners[index].x]
						point[v_axis] = vs[corners[index].y]
						var nearest := point.clamp(-core, core)
						var normal := (point - nearest).normalized()
						surface.set_normal(normal)
						surface.set_uv(Vector2(point[u_axis] / size[u_axis] + 0.5, point[v_axis] / size[v_axis] + 0.5))
						surface.add_vertex(nearest + normal * radius)
	surface.index()
	var mesh := surface.commit()
	_boxes[size] = mesh
	return mesh
