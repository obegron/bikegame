extends SceneTree

const ProgressionServiceType = preload("res://src/core/progression_service.gd")


func _initialize() -> void:
	var old_profile := {
		"distance_m": 1234.0,
		"active_seconds": 90.0,
	}
	var migrated := ProgressionServiceType.migrate_profile(old_profile)
	_expect(int(migrated.version) == 1, "legacy profile should migrate to version one")
	_expect(
		is_equal_approx(float(migrated.progression.total_distance_m), 1234.0),
		"distance should survive migration"
	)
	_expect(
		"classic_red" in migrated.progression.cosmetics,
		"default cosmetic should survive migration"
	)
	print("Progression smoke test passed.")
	quit()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
