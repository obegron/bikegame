extends SceneTree

const CourierMinimapType = preload("res://src/ui/courier_minimap.gd")


func _initialize() -> void:
	var map_rect := Rect2(10.0, 20.0, 100.0, 200.0)
	_expect_near(
		CourierMinimapType.world_to_map(Vector3(-235.0, 0.0, -225.0), map_rect),
		Vector2(10.0, 20.0),
		"north-west boundary"
	)
	_expect_near(
		CourierMinimapType.world_to_map(Vector3(235.0, 0.0, 195.0), map_rect),
		Vector2(110.0, 220.0),
		"south-east boundary"
	)
	var north := CourierMinimapType.world_to_map(Vector3(0.0, 0.0, -138.0), map_rect)
	var south := CourierMinimapType.world_to_map(Vector3(0.0, 0.0, 124.0), map_rect)
	_expect(north.y < south.y, "negative world Z should be north/up on the map")
	print("Courier minimap smoke test passed.")
	quit()


func _expect_near(actual: Vector2, expected: Vector2, context: String) -> void:
	_expect(actual.distance_to(expected) < 0.001, "%s mapping should be exact" % context)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
