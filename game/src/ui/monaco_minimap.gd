extends "res://src/ui/courier_minimap.gd"


func _draw() -> void:
	var panel_rect := Rect2(Vector2.ZERO, size)
	draw_rect(panel_rect, Color(0.025, 0.035, 0.045, 0.93))
	var map_rect := _scaled_map_rect()
	draw_rect(map_rect, WATER_COLOR.darkened(0.12))
	_draw_monaco_land(map_rect)
	_draw_monaco_blocks(map_rect)
	_draw_monaco_roads(map_rect)
	_draw_monaco_landmarks(map_rect)
	_draw_route(map_rect)
	_draw_remote_riders(map_rect)
	_draw_player(map_rect)
	draw_rect(map_rect, Color(0.8, 0.9, 0.92, 0.7), false, 1.5)
	draw_rect(panel_rect, Color(0.8, 0.9, 0.92, 0.42), false, 1.0)


func _draw_monaco_land(map_rect: Rect2) -> void:
	var coast_world: Array = game.city.minimap_coast_outline()
	var coast_map := PackedVector2Array()
	for point: Vector3 in coast_world:
		coast_map.append(world_to_map(point, map_rect))
	draw_colored_polygon(coast_map, Color("79935f"))
	var coast_outline := coast_map.duplicate()
	coast_outline.append(coast_map[0])
	draw_polyline(coast_outline, Color("d5c08f"), 1.4, true)

	var harbour_world := [
		Vector3(-72.0, 0.0, 45.0),
		Vector3(72.0, 0.0, 45.0),
		Vector3(84.0, 0.0, 114.0),
		Vector3(130.0, 0.0, 195.0),
		Vector3(-130.0, 0.0, 195.0),
		Vector3(-84.0, 0.0, 114.0),
	]
	var harbour_map := PackedVector2Array()
	for point: Vector3 in harbour_world:
		harbour_map.append(world_to_map(point, map_rect))
	draw_colored_polygon(harbour_map, WATER_COLOR.darkened(0.04))
	_draw_world_rect(Rect2(108.0, 104.0, 83.0, 18.0), map_rect, Color("d8c398"))


func _draw_monaco_blocks(map_rect: Rect2) -> void:
	for block in [
		Rect2(-177.0, -151.0, 354.0, 17.0),
		Rect2(-166.0, -124.0, 332.0, 16.0),
		Rect2(-180.0, -80.0, 360.0, 15.0),
		Rect2(-184.0, -39.0, 368.0, 14.0),
		Rect2(-176.0, 5.0, 352.0, 13.0),
	]:
		_draw_world_rect(block, map_rect, BLOCK_COLOR)
	_draw_world_rect(Rect2(-17.0, -88.0, 26.0, 18.0), map_rect, LANDMARK_COLOR)
	_draw_world_rect(Rect2(-125.0, -130.0, 28.0, 16.0), map_rect, Color("c4aa7e"))
	_draw_world_rect(Rect2(171.0, -79.0, 24.0, 16.0), map_rect, Color("b7ad98"))


func _draw_monaco_roads(map_rect: Rect2) -> void:
	if game.city == null or not game.city.has_method("minimap_road_paths"):
		return
	for road: Dictionary in game.city.call("minimap_road_paths"):
		var points: Array = road.points
		_draw_world_path(points, float(road.width), map_rect, ROAD_COLOR)
		_draw_world_path(points, 1.1, map_rect, CYCLE_COLOR)
	for junction: Vector3 in game.city._monaco_junction_positions():
		draw_circle(world_to_map(junction, map_rect), 2.8, ROAD_COLOR)


func _draw_monaco_landmarks(map_rect: Rect2) -> void:
	for landmark in get_tree().get_nodes_in_group("monaco_route_landmark"):
		var anchor: Vector3 = landmark.get_meta(
			"route_anchor",
			landmark.global_position
		)
		var map_position := world_to_map(anchor, map_rect)
		draw_circle(map_position, 2.25, Color("f2d06b"))
		draw_circle(map_position, 1.2, Color("263239"))
	for landmark_name in [
		"Monte Carlo Casino",
		"Prince's Palace",
		"Cathedral of Our Lady Immaculate",
		"Oceanographic Museum",
		"Stade Louis II",
		"Grimaldi Forum",
	]:
		var landmark: Node3D = game.city.get_node_or_null(landmark_name)
		if landmark == null:
			continue
		var map_position := world_to_map(landmark.global_position, map_rect)
		draw_circle(map_position, 2.7, Color("e7c677"))
		draw_circle(map_position, 1.45, LANDMARK_COLOR.darkened(0.35))
