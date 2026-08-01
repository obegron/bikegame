extends SceneTree

const BikeInputAdapterType = preload("res://src/input/bike_input_adapter.gd")


func _initialize() -> void:
	_expect_near(BikeInputAdapterType.map_ftms_throttle(1.0, true), 0.0, "inverted rest")
	_expect_near(BikeInputAdapterType.map_ftms_throttle(0.0, true), 0.5, "inverted midpoint")
	_expect_near(BikeInputAdapterType.map_ftms_throttle(-1.0, true), 1.0, "inverted maximum")
	_expect_near(BikeInputAdapterType.map_ftms_throttle(-1.0, false), 0.0, "normal rest")
	_expect_near(BikeInputAdapterType.map_ftms_throttle(1.0, false), 1.0, "normal maximum")
	_expect(
		BikeInputAdapterType.DEFAULT_KEY_BINDINGS.has("bike_decline"),
		"decline should have a keyboard binding"
	)
	_expect(
		BikeInputAdapterType.DEFAULT_JOY_BINDINGS.get("bike_decline") == JOY_BUTTON_X,
		"decline should use the gamepad west button"
	)
	_expect(
		BikeInputAdapterType.DEFAULT_JOY_BINDINGS.get("bike_menu") == JOY_BUTTON_START,
		"menu should use the gamepad start button"
	)
	_expect(
		BikeInputAdapterType.DEFAULT_JOY_BINDINGS.get("bike_reset") == JOY_BUTTON_Y,
		"reset should not overlap the menu button"
	)
	print("Input mapping smoke test passed.")
	quit()


func _expect_near(actual: float, expected: float, context: String) -> void:
	if not is_equal_approx(actual, expected):
		push_error("%s: expected %f, got %f" % [context, expected, actual])
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
