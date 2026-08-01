extends Control
class_name CourierMinimap

@export var game_path: NodePath
@export var player_path: NodePath

@onready var game = get_node(game_path)
@onready var player = get_node(player_path)

const WORLD_BOUNDS := Rect2(-235.0, -225.0, 470.0, 420.0)
const MAP_INSET := Rect2(8.0, 28.0, 216.0, 196.0)
const ROAD_COLOR := Color("3f474b")
const OLD_ROAD_COLOR := Color("77736b")
const PARK_COLOR := Color("7da765")
const WATER_COLOR := Color("397f9d")
const BLOCK_COLOR := Color("c19772")
const LANDMARK_COLOR := Color("b5a98f")
const BRIDGE_COLOR := Color("c4b79d")
const CYCLE_COLOR := Color("c95f55")
const ROUTE_COLOR := Color("ffd65a")
const PLAYER_COLOR := Color("f7fbff")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var panel_rect := Rect2(Vector2.ZERO, size)
	draw_rect(panel_rect, Color(0.025, 0.035, 0.045, 0.93))
	var map_rect := _scaled_map_rect()
	draw_rect(map_rect, WATER_COLOR.darkened(0.16))
	_draw_island(map_rect)
	_draw_world_rect(Rect2(-170.0, -114.0, 340.0, 18.0), map_rect, WATER_COLOR)
	_draw_world_rect(Rect2(-80.0, -105.0, 14.0, 240.0), map_rect, WATER_COLOR.darkened(0.04))
	_draw_world_rect(Rect2(61.5, -2.0, 25.0, 46.0), map_rect, PARK_COLOR)
	_draw_blocks(map_rect)
	_draw_roads(map_rect)
	_draw_route(map_rect)
	_draw_remote_riders(map_rect)
	_draw_player(map_rect)
	draw_rect(map_rect, Color(0.8, 0.9, 0.92, 0.7), false, 1.5)
	draw_rect(panel_rect, Color(0.8, 0.9, 0.92, 0.42), false, 1.0)


func _draw_island(map_rect: Rect2) -> void:
	var coast_world := [
		Vector3(-82.0, 0.0, -208.0),
		Vector3(12.0, 0.0, -212.0),
		Vector3(104.0, 0.0, -202.0),
		Vector3(166.0, 0.0, -181.0),
		Vector3(204.0, 0.0, -136.0),
		Vector3(220.0, 0.0, -72.0),
		Vector3(220.0, 0.0, 7.0),
		Vector3(207.0, 0.0, 82.0),
		Vector3(174.0, 0.0, 145.0),
		Vector3(104.0, 0.0, 178.0),
		Vector3(4.0, 0.0, 185.0),
		Vector3(-98.0, 0.0, 180.0),
		Vector3(-166.0, 0.0, 154.0),
		Vector3(-207.0, 0.0, 104.0),
		Vector3(-220.0, 0.0, 36.0),
		Vector3(-219.0, 0.0, -44.0),
		Vector3(-202.0, 0.0, -118.0),
		Vector3(-158.0, 0.0, -181.0),
	]
	var coast_map := PackedVector2Array()
	for point: Vector3 in coast_world:
		coast_map.append(world_to_map(point, map_rect))
	draw_colored_polygon(coast_map, Color("6d9c58"))
	var coast_outline := coast_map.duplicate()
	coast_outline.append(coast_map[0])
	draw_polyline(
		coast_outline,
		Color("c9b98d"),
		1.4,
		true
	)


static func world_to_map(world_position: Vector3, map_rect: Rect2) -> Vector2:
	var horizontal := inverse_lerp(
		WORLD_BOUNDS.position.x,
		WORLD_BOUNDS.end.x,
		world_position.x
	)
	var vertical := inverse_lerp(
		WORLD_BOUNDS.position.y,
		WORLD_BOUNDS.end.y,
		world_position.z
	)
	return map_rect.position + Vector2(
		clampf(horizontal, 0.0, 1.0) * map_rect.size.x,
		clampf(vertical, 0.0, 1.0) * map_rect.size.y
	)


func _scaled_map_rect() -> Rect2:
	var reference_size := Vector2(232.0, 232.0)
	var scale_factor := Vector2(size.x / reference_size.x, size.y / reference_size.y)
	return Rect2(MAP_INSET.position * scale_factor, MAP_INSET.size * scale_factor)


func _draw_roads(map_rect: Rect2) -> void:
	for road in [
		[Vector3(-125.0, 0.0, 78.0), Vector3(118.0, 0.0, 78.0), 10.0],
		[Vector3(-152.0, 0.0, -82.0), Vector3(152.0, 0.0, -82.0), 10.0],
		[Vector3(58.0, 0.0, -82.0), Vector3(58.0, 0.0, 78.0), 9.0],
		[Vector3(-122.0, 0.0, -54.0), Vector3(-82.0, 0.0, -54.0), 9.0],
		[Vector3(48.0, 0.0, -54.0), Vector3(104.0, 0.0, -54.0), 9.0],
		[Vector3(-132.0, 0.0, 18.0), Vector3(-82.0, 0.0, 18.0), 9.0],
		[Vector3(0.0, 0.0, 124.0), Vector3(0.0, 0.0, 50.0), 10.0],
		[Vector3(58.0, 0.0, -82.0), Vector3(58.0, 0.0, -116.0), 9.0],
		[Vector3(58.0, 0.0, -116.0), Vector3(70.0, 0.0, -133.0), 9.0],
		[Vector3(-132.0, 0.0, 18.0), Vector3(-144.0, 0.0, 4.0), 8.0],
	]:
		_draw_world_line(road[0], road[1], float(road[2]), map_rect, ROAD_COLOR)
		_draw_world_line(road[0], road[1], 1.25, map_rect, CYCLE_COLOR)

	var curved_roads: Array[Array] = [
		[
			Vector3(-122.0, 0.0, 78.0),
			Vector3(-137.0, 0.0, 96.0),
			Vector3(-128.0, 0.0, 117.0),
			Vector3(-72.0, 0.0, 124.0),
			Vector3(0.0, 0.0, 124.0),
			Vector3(76.0, 0.0, 119.0),
			Vector3(124.0, 0.0, 101.0),
			Vector3(118.0, 0.0, 78.0),
		],
		[
			Vector3(118.0, 0.0, 78.0),
			Vector3(129.0, 0.0, 67.0),
			Vector3(147.0, 0.0, 38.0),
			Vector3(143.0, 0.0, 2.0),
			Vector3(128.0, 0.0, -34.0),
			Vector3(104.0, 0.0, -54.0),
		],
		[
			Vector3(-122.0, 0.0, 78.0),
			Vector3(-132.0, 0.0, 70.0),
			Vector3(-150.0, 0.0, 42.0),
			Vector3(-144.0, 0.0, 4.0),
			Vector3(-126.0, 0.0, -31.0),
			Vector3(-104.0, 0.0, -54.0),
		],
		[
			Vector3(-150.0, 0.0, -132.0),
			Vector3(-90.0, 0.0, -138.0),
			Vector3(-28.0, 0.0, -132.0),
			Vector3(38.0, 0.0, -136.0),
			Vector3(98.0, 0.0, -130.0),
			Vector3(150.0, 0.0, -121.0),
		],
		[
			Vector3(-150.0, 0.0, -132.0),
			Vector3(-180.0, 0.0, -116.0),
			Vector3(-187.0, 0.0, -94.0),
			Vector3(-182.0, 0.0, -68.0),
			Vector3(-182.0, 0.0, -12.0),
			Vector3(-178.0, 0.0, 48.0),
			Vector3(-162.0, 0.0, 96.0),
			Vector3(-128.0, 0.0, 117.0),
		],
		[
			Vector3(150.0, 0.0, -121.0),
			Vector3(179.0, 0.0, -116.0),
			Vector3(186.0, 0.0, -94.0),
			Vector3(191.0, 0.0, -58.0),
			Vector3(192.0, 0.0, 4.0),
			Vector3(182.0, 0.0, 64.0),
			Vector3(157.0, 0.0, 108.0),
			Vector3(124.0, 0.0, 101.0),
		],
		[
			Vector3(-152.0, 0.0, -82.0),
			Vector3(-166.0, 0.0, -78.0),
			Vector3(-182.0, 0.0, -68.0),
		],
		[
			Vector3(152.0, 0.0, -82.0),
			Vector3(170.0, 0.0, -80.0),
			Vector3(186.0, 0.0, -94.0),
		],
	]
	for road_points in curved_roads:
		_draw_world_path(road_points, 8.5, map_rect, ROAD_COLOR)
		_draw_world_path(road_points, 1.25, map_rect, CYCLE_COLOR)

	for old_road in [
		[Vector3(-48.0, 0.0, -54.0), Vector3(-48.0, 0.0, 48.0), 7.5],
		[Vector3(48.0, 0.0, -54.0), Vector3(48.0, 0.0, 48.0), 7.5],
		[Vector3(-64.0, 0.0, -54.0), Vector3(48.0, 0.0, -54.0), 7.5],
		[Vector3(-48.0, 0.0, 48.0), Vector3(48.0, 0.0, 48.0), 7.5],
		[Vector3(0.0, 0.0, -54.0), Vector3(0.0, 0.0, 48.0), 6.5],
		[Vector3(-64.0, 0.0, 18.0), Vector3(48.0, 0.0, 18.0), 7.0],
		[Vector3(-48.0, 0.0, -28.0), Vector3(48.0, 0.0, -28.0), 6.0],
		[Vector3(-48.0, 0.0, 48.0), Vector3(-20.0, 0.0, 18.0), 5.5],
		[Vector3(48.0, 0.0, 48.0), Vector3(20.0, 0.0, 18.0), 5.5],
		[Vector3(-48.0, 0.0, -54.0), Vector3(-20.0, 0.0, -28.0), 5.5],
		[Vector3(48.0, 0.0, -54.0), Vector3(20.0, 0.0, -28.0), 5.5],
	]:
		_draw_world_line(old_road[0], old_road[1], float(old_road[2]), map_rect, OLD_ROAD_COLOR)

	for crossing_z: float in [-82.0, -54.0, 18.0, 78.0]:
		_draw_world_line(
			Vector3(-82.0, 0.0, crossing_z),
			Vector3(-64.0, 0.0, crossing_z),
			9.0,
			map_rect,
			BRIDGE_COLOR
		)
	for river_x: float in [0.0, 58.0, 92.0]:
		_draw_world_line(
			Vector3(river_x, 0.0, -94.0),
			Vector3(river_x, 0.0, -116.0),
			9.5,
			map_rect,
			BRIDGE_COLOR
		)
	for coastal_bridge in [
		[Vector3(-180.0, 0.0, -116.0), Vector3(-187.0, 0.0, -94.0)],
		[Vector3(179.0, 0.0, -116.0), Vector3(186.0, 0.0, -94.0)],
	]:
		_draw_world_line(
			coastal_bridge[0],
			coastal_bridge[1],
			8.0,
			map_rect,
			BRIDGE_COLOR
		)


func _draw_blocks(map_rect: Rect2) -> void:
	for heritage_block in [
		Rect2(-45.0, -42.0, 40.0, 10.0),
		Rect2(5.0, -42.0, 40.0, 10.0),
		Rect2(-45.0, 26.5, 40.0, 10.0),
		Rect2(5.0, 26.5, 40.0, 10.0),
		Rect2(-45.0, 60.0, 40.0, 10.0),
		Rect2(5.0, 60.0, 50.0, 10.0),
		Rect2(-55.0, 84.5, 40.0, 9.0),
		Rect2(15.0, 84.5, 40.0, 9.0),
		Rect2(-88.5, -75.0, 9.0, 145.0),
		Rect2(68.0, -75.0, 13.0, 80.0),
		Rect2(85.5, -76.0, 11.0, 98.0),
		Rect2(-154.0, -154.0, 60.0, 10.0),
		Rect2(-82.0, -154.0, 70.0, 10.0),
		Rect2(10.0, -154.0, 66.0, 10.0),
		Rect2(105.0, -154.0, 49.0, 10.0),
		Rect2(110.0, 80.0, 18.0, 15.0),
		Rect2(130.0, 61.0, 18.0, 15.0),
		Rect2(144.0, 8.0, 18.0, 50.0),
		Rect2(-158.0, -18.0, 18.0, 118.0),
	]:
		_draw_world_rect(heritage_block, map_rect, BLOCK_COLOR)

	_draw_world_rect(Rect2(-34.0, -18.0, 12.0, 22.0), map_rect, LANDMARK_COLOR)
	_draw_world_rect(Rect2(22.0, -18.0, 14.0, 22.0), map_rect, Color("b97e5f"))
	_draw_world_rect(Rect2(-88.5, -47.0, 9.0, 14.0), map_rect, Color("a66f51"))


func _draw_world_line(
	from: Vector3,
	to: Vector3,
	world_width: float,
	map_rect: Rect2,
	color: Color
) -> void:
	var map_width := world_width / WORLD_BOUNDS.size.x * map_rect.size.x
	draw_line(
		world_to_map(from, map_rect),
		world_to_map(to, map_rect),
		color,
		maxf(1.0, map_width),
		true
	)


func _draw_world_path(
	points: Array,
	world_width: float,
	map_rect: Rect2,
	color: Color
) -> void:
	for index in points.size() - 1:
		_draw_world_line(points[index], points[index + 1], world_width, map_rect, color)


func _draw_route(map_rect: Rect2) -> void:
	var target := Vector3.ZERO
	var has_target := false
	var order = game.get_active_order()
	if order != null:
		target = order.get_objective_position()
		has_target = true
	else:
		var offers: Array = game.get_offers()
		if not offers.is_empty():
			target = offers[0].pickup_position
			has_target = true
	if not has_target:
		return
	var rider_point := world_to_map(player.global_position, map_rect)
	var target_point := world_to_map(target, map_rect)
	draw_line(rider_point, target_point, Color(0.08, 0.1, 0.12, 0.7), 5.0, true)
	draw_line(rider_point, target_point, ROUTE_COLOR, 2.5, true)
	draw_circle(target_point, 7.5, Color(0.06, 0.08, 0.09, 0.92))
	draw_circle(target_point, 5.0, ROUTE_COLOR)
	draw_circle(target_point, 2.0, Color("fff4bf"))


func _draw_remote_riders(map_rect: Rect2) -> void:
	for state in game.multiplayer_service.remote_player_states.values():
		var point := world_to_map(state.position, map_rect)
		draw_circle(point, 4.0, Color("75d9e6"))
		draw_circle(point, 4.0, Color(0.03, 0.06, 0.07, 0.9), false, 1.0)


func _draw_player(map_rect: Rect2) -> void:
	var point := world_to_map(player.global_position, map_rect)
	var forward: Vector3 = -player.global_transform.basis.z
	var direction := Vector2(forward.x, forward.z).normalized()
	if direction.is_zero_approx():
		direction = Vector2.UP
	var side := Vector2(-direction.y, direction.x)
	var arrow := PackedVector2Array([
		point + direction * 8.0,
		point - direction * 5.0 + side * 5.0,
		point - direction * 2.5,
		point - direction * 5.0 - side * 5.0,
	])
	draw_colored_polygon(arrow, PLAYER_COLOR)
	var outline := PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[3], arrow[0]])
	draw_polyline(outline, Color(0.03, 0.05, 0.06, 0.95), 1.5, true)


func _draw_world_rect(world_rect: Rect2, map_rect: Rect2, color: Color) -> void:
	var top_left := world_to_map(
		Vector3(world_rect.position.x, 0.0, world_rect.position.y),
		map_rect
	)
	var bottom_right := world_to_map(
		Vector3(world_rect.end.x, 0.0, world_rect.end.y),
		map_rect
	)
	draw_rect(Rect2(top_left, bottom_right - top_left), color)
