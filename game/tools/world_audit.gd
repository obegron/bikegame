extends SceneTree

# Generates a machine-readable report and an SVG inspection map from the exact
# procedural world Godot builds at runtime. No Python environment or duplicated
# terrain implementation is required.
#
# Examples:
#   godot --headless --path game --script res://tools/world_audit.gd -- \
#     --level monaco --output /tmp/bikegame-audit
#   make audit-map

const WORLD_BOUNDS := Rect2(-235.0, -225.0, 470.0, 420.0)
const WATER_LEVEL := -0.65
const SVG_SIZE := Vector2(1240.0, 940.0)
const MAP_RECT := Rect2(28.0, 72.0, 920.0, 820.0)
const SCENES := {
	"caledonian": "res://scenes/delivery_game.tscn",
	"monaco": "res://scenes/monaco_game.tscn",
}

var _requested_level := "monaco"
var _output_directory := "/tmp/bikegame-audit"
var _fail_on_errors := false


func _initialize() -> void:
	_parse_arguments()
	_run.call_deferred()


func _parse_arguments() -> void:
	var arguments := OS.get_cmdline_user_args()
	var index := 0
	while index < arguments.size():
		match arguments[index]:
			"--level":
				if index + 1 < arguments.size():
					_requested_level = arguments[index + 1].to_lower()
					index += 1
			"--output":
				if index + 1 < arguments.size():
					_output_directory = arguments[index + 1]
					index += 1
			"--fail-on-errors":
				_fail_on_errors = true
		index += 1


func _run() -> void:
	if _requested_level != "all" and not SCENES.has(_requested_level):
		push_error(
			"Unknown level '%s'; choose monaco, caledonian, or all."
			% _requested_level
		)
		quit(2)
		return
	var absolute_output := _output_directory
	if not absolute_output.is_absolute_path():
		absolute_output = ProjectSettings.globalize_path(absolute_output)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_output)
	if directory_error != OK:
		push_error("Could not create audit output directory: %s" % absolute_output)
		quit(2)
		return

	var levels: Array[String] = []
	if _requested_level == "all":
		levels.assign(SCENES.keys())
		levels.sort()
	else:
		levels.append(_requested_level)
	var total_errors := 0
	for level_id: String in levels:
		var report := await _audit_level(level_id, String(SCENES[level_id]))
		if report.has("fatal_error"):
			push_error(String(report.fatal_error))
			quit(2)
			return
		total_errors += int(report.summary.error_count)
		_write_report(absolute_output, level_id, report)
		print(
			"WORLD_AUDIT level=%s roads=%d foundations=%d errors=%d warnings=%d"
			% [
				level_id,
				int(report.summary.road_count),
				int(report.summary.foundation_count),
				int(report.summary.error_count),
				int(report.summary.warning_count),
			]
		)
		print("  map: %s/%s_audit.svg" % [absolute_output, level_id])
		print("  data: %s/%s_audit.json" % [absolute_output, level_id])
	if _fail_on_errors and total_errors > 0:
		quit(1)
	else:
		quit()


func _audit_level(level_id: String, scene_path: String) -> Dictionary:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return {"fatal_error": "Could not load audit scene %s" % scene_path}
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	paused = false
	var city := game.get_node_or_null("City")
	if (
		city == null
		or not city.has_method("ground_height_at")
		or not city.has_method("road_surface_clearance_at")
	):
		game.queue_free()
		await process_frame
		return {
			"fatal_error": (
				"%s did not instantiate a valid procedural City; inspect"
				+ " the Godot script errors above"
			) % scene_path
		}
	var roads := _extract_roads(city)
	var violations: Array[Dictionary] = []
	var road_metrics := _audit_roads(city, roads, violations)
	var profile_metrics := _audit_road_profiles(city, roads, violations)
	var building_metrics := _audit_buildings(city, violations)
	var clearance_metrics := _audit_road_clearance(city, violations)
	var finding_sample_count := violations.size()
	violations = _coalesce_road_findings(violations)
	var error_count := 0
	var warning_count := 0
	for violation: Dictionary in violations:
		if String(violation.severity) == "error":
			error_count += 1
		else:
			warning_count += 1
	var report := {
		"level": level_id,
		"scene": scene_path,
		"bounds": {
			"x": WORLD_BOUNDS.position.x,
			"z": WORLD_BOUNDS.position.y,
			"width": WORLD_BOUNDS.size.x,
			"depth": WORLD_BOUNDS.size.y,
		},
		"summary": {
			"road_count": roads.size(),
			"road_segment_count": int(road_metrics.segment_count),
			"foundation_count": int(building_metrics.foundation_count),
			"building_shell_count": int(building_metrics.shell_count),
			"generated_building_count": int(
				city.get_meta("monaco_building_count", building_metrics.shell_count)
			),
			"infill_building_count": int(
				city.get_meta("monaco_infill_building_count", 0)
			),
			"facade_detail_instance_count": int(
				city.get_meta("monaco_facade_detail_instance_count", 0)
			),
			"batched_plant_count": int(
				city.get_meta("monaco_batched_plant_count", 0)
			),
			"maximum_grade": float(road_metrics.maximum_grade),
			"ride_surface_samples": int(profile_metrics.samples),
			"maximum_local_grade": float(profile_metrics.maximum_grade),
			"maximum_local_grade_change": float(profile_metrics.maximum_grade_change),
			"maximum_local_cross_slope": float(profile_metrics.maximum_cross_slope),
			"maximum_cross_slope": float(road_metrics.maximum_cross_slope),
			"minimum_bend_radius": float(road_metrics.minimum_bend_radius),
			"road_obstruction_count": int(
				clearance_metrics.road_obstruction_count
			),
			"inaccessible_objective_count": int(
				clearance_metrics.inaccessible_objective_count
			),
			"finding_sample_count": finding_sample_count,
			"error_count": error_count,
			"warning_count": warning_count,
		},
		"roads": _serializable_roads(roads),
		"foundations": building_metrics.foundations,
		"coast": _serializable_coast(city),
		"violations": violations,
	}
	game.queue_free()
	await process_frame
	await process_frame
	return report


func _extract_roads(city: Node) -> Array[Dictionary]:
	var roads: Array[Dictionary] = []
	if city.has_method("minimap_road_paths"):
		var source_roads: Array = city.call("minimap_road_paths")
		for source: Dictionary in source_roads:
			var points: Array[Vector2] = []
			for point: Vector3 in source.points:
				points.append(Vector2(point.x, point.z))
			roads.append({
				"name": String(source.name),
				"width": float(source.width),
				"points": points,
			})
		return roads
	var corridors: Array = city.get("_road_corridors")
	for index in corridors.size():
		var corridor: Dictionary = corridors[index]
		roads.append({
			"name": "Road corridor %04d" % index,
			"width": float(corridor.drivable_radius) * 2.0,
			"points": [corridor.from, corridor.to],
		})
	return roads


func _audit_roads(
	city: Node,
	roads: Array[Dictionary],
	violations: Array[Dictionary]
) -> Dictionary:
	var segments: Array[Dictionary] = []
	var maximum_grade := 0.0
	var maximum_cross_slope := 0.0
	var minimum_bend_radius := INF
	for road_index in roads.size():
		var road: Dictionary = roads[road_index]
		var points: Array = road.points
		var width := float(road.width)
		var previous_grade := NAN
		for segment_index in points.size() - 1:
			var from: Vector2 = points[segment_index]
			var to: Vector2 = points[segment_index + 1]
			var delta := to - from
			var length := delta.length()
			if length < 0.05:
				continue
			# ground_height_at is also the source used to construct every road
			# ribbon vertex. Measuring it here audits the surface the bicycle
			# actually sees, including water cut-outs and competing corridors;
			# the corridor's theoretical grade alone can hide both problems.
			var from_height := float(city.call("ground_height_at", from.x, from.y))
			var to_height := float(city.call("ground_height_at", to.x, to.y))
			var grade := (to_height - from_height) / length
			maximum_grade = maxf(maximum_grade, absf(grade))
			var midpoint := (from + to) * 0.5
			var side := Vector2(-delta.y, delta.x).normalized()
			var half_sample := width * 0.42
			var left := midpoint + side * half_sample
			var right := midpoint - side * half_sample
			var left_height := float(city.call(
				"ground_height_at", left.x, left.y
			))
			var right_height := float(city.call(
				"ground_height_at", right.x, right.y
			))
			var cross_slope := absf(left_height - right_height) / maxf(
				half_sample * 2.0,
				0.1
			)
			maximum_cross_slope = maxf(maximum_cross_slope, cross_slope)
			segments.append({
				"road_index": road_index,
				"road_name": String(road.name),
				"segment_index": segment_index,
				"from": from,
				"to": to,
				"width": width,
				"length": length,
			})
			if from_height < WATER_LEVEL - 0.2 or to_height < WATER_LEVEL - 0.2:
				_add_violation(
					violations,
					"submerged_road",
					"error",
					midpoint,
					"%s enters water" % String(road.name),
					{
						"height": minf(from_height, to_height),
						"road": String(road.name),
					}
				)
			if absf(grade) > 0.135:
				_add_violation(
					violations,
					"excessive_grade",
					"error",
					midpoint,
					"%s grade %.1f%%" % [String(road.name), absf(grade) * 100.0],
					{
						"grade": absf(grade),
						"road": String(road.name),
					}
				)
			if cross_slope > 0.105:
				_add_violation(
					violations,
					"cross_slope",
					"warning",
					midpoint,
					"%s cross-slope %.1f%%"
					% [String(road.name), cross_slope * 100.0],
					{
						"cross_slope": cross_slope,
						"road": String(road.name),
					}
				)
			if not is_nan(previous_grade) and absf(grade - previous_grade) > 0.115:
				_add_violation(
					violations,
					"vertical_kink",
					"warning",
					from,
					"%s has an abrupt grade change" % String(road.name),
					{
						"grade_change": absf(grade - previous_grade),
						"road": String(road.name),
					}
				)
			previous_grade = grade

		for point_index in range(1, points.size() - 1):
			var previous: Vector2 = points[point_index - 1]
			var current: Vector2 = points[point_index]
			var following: Vector2 = points[point_index + 1]
			var incoming := current - previous
			var outgoing := following - current
			if incoming.length() < 0.1 or outgoing.length() < 0.1:
				continue
			var turn := acos(clampf(
				incoming.normalized().dot(outgoing.normalized()),
				-1.0,
				1.0
			))
			if turn < 0.01:
				continue
			var radius := (
				minf(incoming.length(), outgoing.length())
				/ maxf(2.0 * sin(turn * 0.5), 0.001)
			)
			minimum_bend_radius = minf(minimum_bend_radius, radius)
			if radius < maxf(4.2, width * 0.56):
				_add_violation(
					violations,
					"tight_bend",
					"warning",
					current,
					"%s bend radius %.1fm" % [String(road.name), radius],
					{
						"radius": radius,
						"road": String(road.name),
					}
				)

	_audit_road_overlaps(segments, violations)
	return {
		"segment_count": segments.size(),
		"maximum_grade": maximum_grade,
		"maximum_cross_slope": maximum_cross_slope,
		"minimum_bend_radius": 0.0 if minimum_bend_radius == INF else minimum_bend_radius,
	}


func _audit_road_clearance(
	city: Node,
	violations: Array[Dictionary]
) -> Dictionary:
	var obstruction_count := 0
	var inaccessible_objective_count := 0
	var audited_nodes := {}
	for obstacle: Node in get_nodes_in_group("obstacle"):
		if not obstacle is Node3D or not city.is_ancestor_of(obstacle):
			continue
		var obstacle_3d := obstacle as Node3D
		for box: Dictionary in _collision_boxes_data(obstacle_3d):
			var center: Vector3 = box.center
			var local_ground := float(city.call(
				"ground_height_at",
				center.x,
				center.z
			))
			# Roofs, overhead decorations, and tunnel ceilings are legitimate
			# above the route; only collision reaching rider height obstructs it.
			if float(box.bottom) > local_ground + 2.8:
				continue
			var minimum_clearance := _box_road_clearance(city, box)
			if minimum_clearance >= -0.08:
				continue
			audited_nodes[obstacle.get_instance_id()] = true
			obstruction_count += 1
			_add_violation(
				violations,
				"road_obstruction",
				"error",
				Vector2(center.x, center.z),
				"%s collision overlaps the rideable road" % obstacle.name,
				{"clearance": minimum_clearance}
			)

	# These small props do not all own collision, but they are still visually
	# disruptive when generated on asphalt or in a cycle lane.
	for group_name in [
		"monaco_lamp_post",
		"freestanding_shop_sign",
		"monaco_route_landmark",
		"monaco_parked_car",
		"traffic_signal_pole",
		"working_street_lamp",
	]:
		for prop: Node in get_nodes_in_group(group_name):
			if not prop is Node3D or not city.is_ancestor_of(prop):
				continue
			if audited_nodes.has(prop.get_instance_id()):
				continue
			var prop_3d := prop as Node3D
			var clearance := float(city.call(
				"road_surface_clearance_at",
				prop_3d.global_position
			))
			if clearance >= 0.5:
				continue
			audited_nodes[prop.get_instance_id()] = true
			obstruction_count += 1
			_add_violation(
				violations,
				"road_prop",
				"error",
				Vector2(prop_3d.global_position.x, prop_3d.global_position.z),
				"%s (%s) stands inside the road envelope"
				% [prop.name, group_name],
				{"clearance": clearance}
			)

	# Collision-only checks miss large decorative meshes. Audit the low visual
	# bounds of landmarks and explicitly marked roadside set dressing, including
	# compound children such as the Grimaldi Forum and beach parasols.
	var visual_roots: Array[Node] = []
	for group_name in ["monaco_landmark", "roadside_visual_audit"]:
		for visual_root: Node in get_nodes_in_group(group_name):
			if (
				not visual_root is Node3D
				or not city.is_ancestor_of(visual_root)
				or visual_roots.has(visual_root)
			):
				continue
			visual_roots.append(visual_root)
	for visual_root: Node3D in visual_roots:
		var visual_audit := _visual_road_clearance(city, visual_root)
		if visual_audit.is_empty() or float(visual_audit.clearance) >= 0.25:
			continue
		obstruction_count += 1
		var visual_center: Vector2 = visual_audit.center
		_add_violation(
			violations,
			"visual_road_obstruction",
			"error",
			visual_center,
			"%s low visual geometry overlaps the rideable road"
			% visual_root.name,
			{
				"clearance": float(visual_audit.clearance),
				"width": float(visual_audit.width),
				"depth": float(visual_audit.depth),
				"mesh": String(visual_audit.mesh),
			}
		)

	for batch: Node in city.find_children("*", "", true, false):
		var audit_transforms: Array = batch.get_meta("road_audit_transforms", [])
		for instance_index in audit_transforms.size():
			var instance_transform: Transform3D = audit_transforms[instance_index]
			var instance_position := instance_transform.origin
			var clearance := float(city.call(
				"road_surface_clearance_at",
				instance_position
			))
			if clearance >= 0.5:
				continue
			obstruction_count += 1
			_add_violation(
				violations,
				"road_foliage",
				"error",
				Vector2(instance_position.x, instance_position.z),
				"%s instance %d grows inside the road envelope"
				% [batch.name, instance_index],
				{"clearance": clearance}
			)

	if city.has_method("pickup_locations") and city.has_method("dropoff_locations"):
		var locations: Array = (
			city.call("pickup_locations") + city.call("dropoff_locations")
		)
		for location: Dictionary in locations:
			var point: Vector3 = location.position
			var clearance := float(city.call(
				"road_surface_clearance_at",
				point
			))
			if clearance < 0.75:
				continue
			inaccessible_objective_count += 1
			_add_violation(
				violations,
				"inaccessible_objective",
				"error",
				Vector2(point.x, point.z),
				"%s is too far from a rideable road" % String(location.name),
				{"clearance": clearance}
			)
	return {
		"road_obstruction_count": obstruction_count,
		"inaccessible_objective_count": inaccessible_objective_count,
	}


func _visual_road_clearance(city: Node, visual_root: Node3D) -> Dictionary:
	var worst_clearance := INF
	var worst_result := {}
	for descendant: Node in visual_root.find_children(
		"*",
		"MeshInstance3D",
		true,
		false
	):
		var mesh_instance := descendant as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var world_aabb: AABB = (
			mesh_instance.global_transform * mesh_instance.get_aabb()
		)
		var aabb_center := world_aabb.get_center()
		var local_ground := float(city.call(
			"ground_height_at",
			aabb_center.x,
			aabb_center.z
		))
		# Signs, roofs, and suspended decorations above rider height do not
		# block the route even when their shadow crosses the road.
		if world_aabb.position.y > local_ground + 3.1:
			continue
		var mesh_clearance := INF
		for x_weight: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
			for z_weight: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
				var probe := Vector3(
					lerpf(
						world_aabb.position.x,
						world_aabb.end.x,
						x_weight
					),
					0.0,
					lerpf(
						world_aabb.position.z,
						world_aabb.end.z,
						z_weight
					)
				)
				mesh_clearance = minf(
					mesh_clearance,
					float(city.call("road_surface_clearance_at", probe))
				)
		if mesh_clearance >= worst_clearance:
			continue
		worst_clearance = mesh_clearance
		worst_result = {
			"center": Vector2(aabb_center.x, aabb_center.z),
			"width": world_aabb.size.x,
			"depth": world_aabb.size.z,
			"clearance": mesh_clearance,
			"mesh": mesh_instance.name,
		}
	return worst_result


func _coalesce_road_findings(
	findings: Array[Dictionary]
) -> Array[Dictionary]:
	# Dense spline samples are useful for measurement but unreadable as dozens
	# of overlapping map pins. Collapse adjacent samples of one road/problem
	# into a single issue zone while retaining the worst measurement.
	var result: Array[Dictionary] = []
	for finding: Dictionary in findings:
		var metrics: Dictionary = finding.metrics
		var road_name := String(metrics.get("road", ""))
		if road_name.is_empty():
			result.append(finding)
			continue
		var position := Vector2(
			float(finding.position[0]),
			float(finding.position[1])
		)
		var match_index := -1
		for index in range(result.size() - 1, -1, -1):
			var candidate: Dictionary = result[index]
			var candidate_metrics: Dictionary = candidate.metrics
			if (
				String(candidate.type) != String(finding.type)
				or String(candidate_metrics.get("road", "")) != road_name
			):
				continue
			var last_pair: Array = candidate.get(
				"_last_position",
				candidate.position
			)
			var last_position := Vector2(
				float(last_pair[0]),
				float(last_pair[1])
			)
			if position.distance_to(last_position) <= 11.0:
				match_index = index
				break
		if match_index < 0:
			var new_finding := finding.duplicate(true)
			new_finding["_last_position"] = finding.position.duplicate()
			new_finding["sample_count"] = 1
			result.append(new_finding)
			continue
		var cluster: Dictionary = result[match_index]
		cluster["_last_position"] = finding.position.duplicate()
		cluster["sample_count"] = int(cluster.get("sample_count", 1)) + 1
		if _finding_magnitude(finding) > _finding_magnitude(cluster):
			cluster.position = finding.position
			cluster.message = finding.message
			cluster.metrics = finding.metrics
	for finding: Dictionary in result:
		finding.erase("_last_position")
	return result


func _finding_magnitude(finding: Dictionary) -> float:
	var magnitude := 0.0
	for value: Variant in (finding.metrics as Dictionary).values():
		if value is float or value is int:
			magnitude = maxf(magnitude, absf(float(value)))
	return magnitude


func _box_road_clearance(city: Node, box: Dictionary) -> float:
	var center: Vector3 = box.center
	var minimum_clearance := INF
	for x_weight: float in [-1.0, 0.0, 1.0]:
		for z_weight: float in [-1.0, 0.0, 1.0]:
			var probe: Vector3 = (
				center
				+ (box.axis_x as Vector3) * float(box.half_x) * x_weight
				+ (box.axis_z as Vector3) * float(box.half_z) * z_weight
			)
			minimum_clearance = minf(
				minimum_clearance,
				float(city.call("road_surface_clearance_at", probe))
			)
	return minimum_clearance


func _audit_road_overlaps(
	segments: Array[Dictionary],
	violations: Array[Dictionary]
) -> void:
	var overlap_pairs := {}
	var crossing_cells := {}
	for first_index in segments.size():
		var first: Dictionary = segments[first_index]
		for second_index in range(first_index + 1, segments.size()):
			var second: Dictionary = segments[second_index]
			var same_road := int(first.road_index) == int(second.road_index)
			if (
				same_road
				and abs(int(first.segment_index) - int(second.segment_index)) <= 2
			):
				continue
			var first_from: Vector2 = first.from
			var first_to: Vector2 = first.to
			var second_from: Vector2 = second.from
			var second_to: Vector2 = second.to
			var shared_endpoint := _segments_share_endpoint(
				first_from,
				first_to,
				second_from,
				second_to,
				0.8
			)
			var first_direction := (first_to - first_from).normalized()
			var second_direction := (second_to - second_from).normalized()
			var alignment := absf(first_direction.dot(second_direction))
			if alignment > 0.965:
				var overlap := _parallel_overlap_length(
					first_from,
					first_to,
					second_from,
					second_to
				)
				var lateral_distance := _point_line_distance(
					(second_from + second_to) * 0.5,
					first_from,
					first_to
				)
				var overlap_threshold := maxf(
					8.0,
					minf(float(first.width), float(second.width))
				)
				var lateral_threshold := (
					(float(first.width) + float(second.width)) * 0.34
				)
				if (
					overlap > overlap_threshold
					and lateral_distance < lateral_threshold
					and not (shared_endpoint and overlap < 13.0)
				):
					var pair_key := _road_pair_key(first, second)
					var score := overlap - lateral_distance
					if (
						not overlap_pairs.has(pair_key)
						or score > float(overlap_pairs[pair_key].score)
					):
						overlap_pairs[pair_key] = {
							"score": score,
							"position": (
								(first_from + first_to + second_from + second_to)
								* 0.25
							),
							"first": first,
							"second": second,
							"overlap": overlap,
							"distance": lateral_distance,
						}
			var intersection = Geometry2D.segment_intersects_segment(
				first_from,
				first_to,
				second_from,
				second_to
			)
			if intersection == null or shared_endpoint or alignment > 0.965:
				continue
			var crossing: Vector2 = intersection
			var cell := Vector2i(
				roundi(crossing.x / 5.0),
				roundi(crossing.y / 5.0)
			)
			var crossing_key := "%s|%s|%d,%d" % [
				String(first.road_name),
				String(second.road_name),
				cell.x,
				cell.y,
			]
			if crossing_cells.has(crossing_key):
				continue
			crossing_cells[crossing_key] = true
			_add_violation(
				violations,
				"unregistered_crossing",
				"warning",
				crossing,
				"%s crosses %s away from a shared point"
				% [String(first.road_name), String(second.road_name)]
			)
	for pair_key: String in overlap_pairs:
		var overlap: Dictionary = overlap_pairs[pair_key]
		_add_violation(
			violations,
			"road_overlap",
			"error",
			overlap.position,
			"%s overlaps %s for %.1fm"
			% [
				String(overlap.first.road_name),
				String(overlap.second.road_name),
				float(overlap.overlap),
			],
			{
				"overlap_length": float(overlap.overlap),
				"centerline_distance": float(overlap.distance),
			}
		)


func _audit_buildings(
	city: Node,
	violations: Array[Dictionary]
) -> Dictionary:
	var foundation_nodes: Array[Node] = []
	for node: Node in get_nodes_in_group("terrain_sealed_foundation"):
		if city.is_ancestor_of(node):
			foundation_nodes.append(node)
	var foundations: Array[Dictionary] = []
	var foundation_centers: Array[Vector2] = []
	for foundation: Node3D in foundation_nodes:
		var box := _collision_box_data(foundation)
		if box.is_empty():
			continue
		var center: Vector3 = box.center
		var axis_x: Vector3 = box.axis_x
		var axis_z: Vector3 = box.axis_z
		var half_x := float(box.half_x)
		var half_z := float(box.half_z)
		var bottom := float(box.bottom)
		var top := float(box.top)
		var maximum_gap := -INF
		var maximum_burial := -INF
		for x_weight: float in [-1.0, 0.0, 1.0]:
			for z_weight: float in [-1.0, 0.0, 1.0]:
				var sample: Vector3 = (
					center
					+ axis_x * half_x * x_weight
					+ axis_z * half_z * z_weight
				)
				var ground := float(city.call(
					"ground_height_at",
					sample.x,
					sample.z
				))
				maximum_gap = maxf(maximum_gap, bottom - ground)
				maximum_burial = maxf(maximum_burial, ground - top)
		var footprint := _footprint_points(center, axis_x, axis_z, half_x, half_z)
		foundations.append({
			"name": foundation.name,
			"center": [center.x, center.z],
			"footprint": _vector2_array_to_pairs(footprint),
			"maximum_gap": maximum_gap,
			"maximum_burial": maximum_burial,
		})
		foundation_centers.append(Vector2(center.x, center.z))
		if maximum_gap > 0.18:
			_add_violation(
				violations,
				"floating_foundation",
				"error",
				Vector2(center.x, center.z),
				"%s floats %.2fm above terrain"
				% [foundation.name, maximum_gap],
				{"gap": maximum_gap}
			)
		if maximum_burial > 0.18:
			_add_violation(
				violations,
				"buried_foundation",
				"error",
				Vector2(center.x, center.z),
				"%s is %.2fm below terrain"
				% [foundation.name, maximum_burial],
				{"burial": maximum_burial}
			)

	var shells: Array[Node] = []
	for group_name in ["building_shell", "monaco_building"]:
		for node: Node in get_nodes_in_group(group_name):
			if city.is_ancestor_of(node) and not shells.has(node):
				shells.append(node)
	for shell: Node3D in shells:
		var shell_center := Vector2(shell.global_position.x, shell.global_position.z)
		var nearest_foundation := INF
		for center: Vector2 in foundation_centers:
			nearest_foundation = minf(
				nearest_foundation,
				shell_center.distance_to(center)
			)
		if nearest_foundation > 2.5:
			_add_violation(
				violations,
				"missing_foundation",
				"error",
				shell_center,
				"%s has no fitted foundation" % shell.name,
				{"nearest_foundation": nearest_foundation}
			)
	for first_index in foundations.size():
		var first: Dictionary = foundations[first_index]
		for second_index in range(first_index + 1, foundations.size()):
			var second: Dictionary = foundations[second_index]
			var overlap_polygons := Geometry2D.intersect_polygons(
				_pairs_to_vector2_array(first.footprint),
				_pairs_to_vector2_array(second.footprint)
			)
			var overlap_area := 0.0
			for polygon: PackedVector2Array in overlap_polygons:
				overlap_area += absf(_polygon_area(polygon))
			if overlap_area <= 0.5:
				continue
			var first_center := Vector2(
				float(first.center[0]),
				float(first.center[1])
			)
			var second_center := Vector2(
				float(second.center[0]),
				float(second.center[1])
			)
			_add_violation(
				violations,
				"building_overlap",
				"error",
				(first_center + second_center) * 0.5,
				"%s overlaps %s" % [String(first.name), String(second.name)],
				{"overlap_area": overlap_area}
			)
	return {
		"foundation_count": foundations.size(),
		"shell_count": shells.size(),
		"foundations": foundations,
	}


func _pairs_to_vector2_array(pairs: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for pair: Array in pairs:
		result.append(Vector2(float(pair[0]), float(pair[1])))
	return result


func _polygon_area(polygon: PackedVector2Array) -> float:
	var area := 0.0
	for index in polygon.size():
		var current := polygon[index]
		var following := polygon[(index + 1) % polygon.size()]
		area += current.x * following.y - following.x * current.y
	return area * 0.5


func _collision_box_data(body: Node3D) -> Dictionary:
	var boxes := _collision_boxes_data(body)
	return {} if boxes.is_empty() else boxes[0]


func _collision_boxes_data(body: Node3D) -> Array[Dictionary]:
	var boxes: Array[Dictionary] = []
	var collision_nodes: Array[Node] = []
	for child: Node in body.get_children():
		if child is CollisionShape3D:
			collision_nodes.append(child)
	for descendant: Node in body.find_children(
		"*",
		"CollisionShape3D",
		true,
		false
	):
		if not collision_nodes.has(descendant):
			collision_nodes.append(descendant)
	for collision_node: Node in collision_nodes:
		var collision := collision_node as CollisionShape3D
		if collision.shape is not BoxShape3D:
			continue
		var shape := collision.shape as BoxShape3D
		var transform := collision.global_transform
		var scale_x := transform.basis.x.length()
		var scale_y := transform.basis.y.length()
		var scale_z := transform.basis.z.length()
		boxes.append({
			"center": transform.origin,
			"axis_x": transform.basis.x.normalized(),
			"axis_z": transform.basis.z.normalized(),
			"half_x": shape.size.x * scale_x * 0.5,
			"half_z": shape.size.z * scale_z * 0.5,
			"bottom": transform.origin.y - shape.size.y * scale_y * 0.5,
			"top": transform.origin.y + shape.size.y * scale_y * 0.5,
		})
	return boxes


func _footprint_points(
	center: Vector3,
	axis_x: Vector3,
	axis_z: Vector3,
	half_x: float,
	half_z: float
) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for weights: Vector2 in [
		Vector2(-1.0, -1.0),
		Vector2(1.0, -1.0),
		Vector2(1.0, 1.0),
		Vector2(-1.0, 1.0),
	]:
		var point: Vector3 = (
			center
			+ axis_x * half_x * weights.x
			+ axis_z * half_z * weights.y
		)
		points.append(Vector2(point.x, point.z))
	return points


func _segments_share_endpoint(
	first_from: Vector2,
	first_to: Vector2,
	second_from: Vector2,
	second_to: Vector2,
	tolerance: float
) -> bool:
	return (
		first_from.distance_to(second_from) <= tolerance
		or first_from.distance_to(second_to) <= tolerance
		or first_to.distance_to(second_from) <= tolerance
		or first_to.distance_to(second_to) <= tolerance
	)


func _parallel_overlap_length(
	first_from: Vector2,
	first_to: Vector2,
	second_from: Vector2,
	second_to: Vector2
) -> float:
	var axis := (first_to - first_from).normalized()
	var first_length := first_from.distance_to(first_to)
	var second_start := (second_from - first_from).dot(axis)
	var second_end := (second_to - first_from).dot(axis)
	var second_min := minf(second_start, second_end)
	var second_max := maxf(second_start, second_end)
	return maxf(
		0.0,
		minf(first_length, second_max) - maxf(0.0, second_min)
	)


func _point_line_distance(
	point: Vector2,
	line_from: Vector2,
	line_to: Vector2
) -> float:
	var segment := line_to - line_from
	if segment.length_squared() < 0.001:
		return point.distance_to(line_from)
	var weight := clampf(
		(point - line_from).dot(segment) / segment.length_squared(),
		0.0,
		1.0
	)
	return point.distance_to(line_from.lerp(line_to, weight))


func _road_pair_key(first: Dictionary, second: Dictionary) -> String:
	var first_name := String(first.road_name)
	var second_name := String(second.road_name)
	if first_name > second_name:
		var swap := first_name
		first_name = second_name
		second_name = swap
	if int(first.road_index) == int(second.road_index):
		return "%s|self" % first_name
	return "%s|%s" % [first_name, second_name]


func _add_violation(
	violations: Array[Dictionary],
	type: String,
	severity: String,
	position: Vector2,
	message: String,
	metrics := {}
) -> void:
	violations.append({
		"type": type,
		"severity": severity,
		"position": [position.x, position.y],
		"message": message,
		"metrics": metrics,
	})


func _serializable_roads(roads: Array[Dictionary]) -> Array[Dictionary]:
	var serialized: Array[Dictionary] = []
	for road: Dictionary in roads:
		serialized.append({
			"name": road.name,
			"width": road.width,
			"points": _vector2_array_to_pairs(road.points),
		})
	return serialized


func _serializable_coast(city: Node) -> Array:
	if not city.has_method("minimap_coast_outline"):
		return []
	var result := []
	for point: Vector3 in city.call("minimap_coast_outline"):
		result.append([point.x, point.z])
	return result


func _vector2_array_to_pairs(points: Array) -> Array:
	var result := []
	for point: Vector2 in points:
		result.append([point.x, point.y])
	return result


func _write_report(
	output_directory: String,
	level_id: String,
	report: Dictionary
) -> void:
	var json_path := output_directory.path_join("%s_audit.json" % level_id)
	var json_file := FileAccess.open(json_path, FileAccess.WRITE)
	if json_file == null:
		push_error("Could not write %s" % json_path)
		return
	json_file.store_string(JSON.stringify(report, "\t"))
	json_file.close()
	var svg_path := output_directory.path_join("%s_audit.svg" % level_id)
	var svg_file := FileAccess.open(svg_path, FileAccess.WRITE)
	if svg_file == null:
		push_error("Could not write %s" % svg_path)
		return
	svg_file.store_string(_build_svg(report))
	svg_file.close()


func _build_svg(report: Dictionary) -> String:
	var svg := PackedStringArray()
	svg.append(
		'<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d"'
		% [int(SVG_SIZE.x), int(SVG_SIZE.y)]
		+ ' viewBox="0 0 %d %d">\n' % [int(SVG_SIZE.x), int(SVG_SIZE.y)]
	)
	svg.append('<rect width="100%" height="100%" fill="#101a20"/>\n')
	svg.append(
		'<text x="28" y="38" fill="#f0d36b" font-family="sans-serif"'
		+ ' font-size="24" font-weight="bold">%s WORLD AUDIT</text>\n'
		% _xml_escape(String(report.level).to_upper())
	)
	svg.append(
		'<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#326f88"'
		% [MAP_RECT.position.x, MAP_RECT.position.y, MAP_RECT.size.x, MAP_RECT.size.y]
		+ ' stroke="#b8cbd0" stroke-width="2"/>\n'
	)
	var coast: Array = report.coast
	if not coast.is_empty():
		svg.append(
			'<polygon points="%s" fill="#759a61" stroke="#d4c18e" stroke-width="3"/>\n'
			% _svg_pairs(coast)
		)
	for road: Dictionary in report.roads:
		var width_pixels := float(road.width) * MAP_RECT.size.x / WORLD_BOUNDS.size.x
		svg.append(
			'<polyline points="%s" fill="none" stroke="#343e43"'
			% _svg_pairs(road.points)
			+ ' stroke-width="%.2f" stroke-linejoin="round" stroke-linecap="round"/>\n'
			% width_pixels
		)
		svg.append(
			'<polyline points="%s" fill="none" stroke="#c85e56"'
			% _svg_pairs(road.points)
			+ ' stroke-width="1.4" stroke-linejoin="round" stroke-linecap="round"/>\n'
		)
	for foundation: Dictionary in report.foundations:
		svg.append(
			'<polygon points="%s" fill="#c3a27e" fill-opacity="0.72"'
			% _svg_pairs(foundation.footprint)
			+ ' stroke="#66594e" stroke-width="0.8"/>\n'
		)
	var violation_index := 0
	for violation: Dictionary in report.violations:
		var map_point := _world_pair_to_svg(violation.position)
		var color := (
			"#ff4655" if String(violation.severity) == "error" else "#ffb23e"
		)
		svg.append(
			'<circle cx="%.2f" cy="%.2f" r="6.5" fill="%s"'
			% [map_point.x, map_point.y, color]
			+ ' stroke="#151b1f" stroke-width="2"/>\n'
		)
		svg.append(
			'<text x="%.2f" y="%.2f" fill="#111820" font-family="sans-serif"'
			% [map_point.x, map_point.y + 3.2]
			+ ' font-size="8" text-anchor="middle">%d</text>\n'
			% (violation_index + 1)
		)
		violation_index += 1
	_append_svg_panel(svg, report)
	svg.append("</svg>\n")
	return "".join(svg)


func _append_svg_panel(svg: PackedStringArray, report: Dictionary) -> void:
	var x := 974.0
	svg.append(
		'<rect x="962" y="72" width="250" height="820" rx="8" fill="#17242a"'
		+ ' stroke="#53666d" stroke-width="1.5"/>\n'
	)
	svg.append(_svg_text(x, 105.0, "SUMMARY", "#f0d36b", 17))
	var summary: Dictionary = report.summary
	var summary_lines := [
		"Roads: %d" % int(summary.road_count),
		"Segments: %d" % int(summary.road_segment_count),
		"Foundations: %d" % int(summary.foundation_count),
		"Building shells: %d" % int(summary.building_shell_count),
		"Infill buildings: %d" % int(summary.infill_building_count),
		"Facade details: %d" % int(summary.facade_detail_instance_count),
		"Batched plants: %d" % int(summary.batched_plant_count),
		"Max grade: %.1f%%" % (float(summary.maximum_grade) * 100.0),
		"Max cross-slope: %.1f%%" % (float(summary.maximum_cross_slope) * 100.0),
		"Minimum bend: %.1fm" % float(summary.minimum_bend_radius),
		"Road obstructions: %d" % int(summary.road_obstruction_count),
		"Remote objectives: %d" % int(summary.inaccessible_objective_count),
		"Finding samples: %d" % int(summary.finding_sample_count),
		"Errors: %d" % int(summary.error_count),
		"Warnings: %d" % int(summary.warning_count),
	]
	var y := 135.0
	for line: String in summary_lines:
		var color := "#e6ecee"
		if line.begins_with("Errors:") and int(summary.error_count) > 0:
			color = "#ff6470"
		elif line.begins_with("Warnings:") and int(summary.warning_count) > 0:
			color = "#ffc05c"
		svg.append(_svg_text(x, y, line, color, 13))
		y += 22.0
	y += 10.0
	svg.append(_svg_text(x, y, "FINDINGS", "#f0d36b", 17))
	y += 25.0
	var shown := 0
	var finding_limit := maxi(4, int(floor((842.0 - y) / 16.0)))
	for index in report.violations.size():
		if shown >= finding_limit:
			break
		var violation: Dictionary = report.violations[index]
		var color := (
			"#ff6470" if String(violation.severity) == "error" else "#ffc05c"
		)
		var message := "%d. %s" % [index + 1, String(violation.type)]
		svg.append(_svg_text(x, y, message, color, 11))
		y += 16.0
		shown += 1
	if report.violations.size() > shown:
		svg.append(_svg_text(
			x,
			y + 4.0,
			"+ %d more in JSON" % (report.violations.size() - shown),
			"#b8c5c9",
			11
		))
	svg.append(_svg_text(x, 858.0, "Red = error", "#ff6470", 12))
	svg.append(_svg_text(x, 878.0, "Amber = warning", "#ffc05c", 12))


func _svg_pairs(pairs: Array) -> String:
	var values := PackedStringArray()
	for pair: Array in pairs:
		var point := _world_pair_to_svg(pair)
		values.append("%.2f,%.2f" % [point.x, point.y])
	return " ".join(values)


func _world_pair_to_svg(pair: Array) -> Vector2:
	var horizontal := inverse_lerp(
		WORLD_BOUNDS.position.x,
		WORLD_BOUNDS.end.x,
		float(pair[0])
	)
	var vertical := inverse_lerp(
		WORLD_BOUNDS.position.y,
		WORLD_BOUNDS.end.y,
		float(pair[1])
	)
	return MAP_RECT.position + Vector2(
		horizontal * MAP_RECT.size.x,
		vertical * MAP_RECT.size.y
	)


func _svg_text(
	x: float,
	y: float,
	value: String,
	color: String,
	font_size: int
) -> String:
	return (
		'<text x="%.1f" y="%.1f" fill="%s" font-family="sans-serif"'
		% [x, y, color]
		+ ' font-size="%d">%s</text>\n' % [font_size, _xml_escape(value)]
	)


func _xml_escape(value: String) -> String:
	return (
		value
		.replace("&", "&amp;")
		.replace("<", "&lt;")
		.replace(">", "&gt;")
		.replace('"', "&quot;")
	)


func _audit_road_profiles(city: Node, roads: Array[Dictionary], violations: Array[Dictionary]) -> Dictionary:
	var maximum_grade := 0.0
	var maximum_grade_change := 0.0
	var maximum_cross_slope := 0.0
	var sample_count := 0
	for road: Dictionary in roads:
		var points: Array = road.points
		var width := float(road.width)
		for segment_index in points.size() - 1:
			var from: Vector2 = points[segment_index]
			var to: Vector2 = points[segment_index + 1]
			var length := from.distance_to(to)
			if length < 0.1:
				continue
			var count := maxi(2, int(ceil(length / 1.25)))
			var step_length := length / count
			var side := Vector2(-(to - from).y, (to - from).x).normalized()
			# Include both cycle lanes. Endpoint-only centerline audits miss
			# bumps between endpoints and steep strips along the road margins.
			for lane: float in [-0.35, 0.0, 0.35]:
				var previous_height := NAN
				var previous_grade := NAN
				for sample_index in count + 1:
					var center := from.lerp(to, float(sample_index) / count)
					var point := center + side * width * lane
					var height := float(city.call("travel_surface_height_at", point.x, point.y))
					sample_count += 1
					if not is_nan(previous_height):
						var grade := (height - previous_height) / step_length
						maximum_grade = maxf(maximum_grade, absf(grade))
						if absf(grade) > 0.135:
							_add_violation(violations, "local_road_grade", "error", point,
								"%s local ride-surface grade %.1f%%" % [road.name, absf(grade) * 100.0],
								{"road": road.name, "grade": absf(grade), "lane_offset": lane * width})
						if not is_nan(previous_grade):
							var change := absf(grade - previous_grade)
							maximum_grade_change = maxf(maximum_grade_change, change)
							if change > 0.08:
								_add_violation(violations, "road_surface_kink", "error", point,
									"%s abrupt ride-surface grade change %.1f%%" % [road.name, change * 100.0],
									{"road": road.name, "grade_change": change})
						previous_grade = grade
					previous_height = height
					if lane == 0.0:
						var left := center - side * width * 0.35
						var right := center + side * width * 0.35
						var cross_slope := absf(float(city.call("travel_surface_height_at", left.x, left.y)) - float(city.call("travel_surface_height_at", right.x, right.y))) / (width * 0.7)
						maximum_cross_slope = maxf(maximum_cross_slope, cross_slope)
						if cross_slope > 0.105:
							_add_violation(violations, "local_cross_slope", "error", center,
								"%s local cross-slope %.1f%%" % [road.name, cross_slope * 100.0],
								{"road": road.name, "cross_slope": cross_slope})
	return {"samples": sample_count, "maximum_grade": maximum_grade, "maximum_grade_change": maximum_grade_change, "maximum_cross_slope": maximum_cross_slope}
