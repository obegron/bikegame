extends Node
class_name ProgressionService

signal achievement_unlocked(id: String, title: String)
signal progression_changed(snapshot: Dictionary)

const SAVE_VERSION := 1
const SAVE_PATH := "user://profile.json"

var total_distance_m := 0.0
var total_active_seconds := 0.0
var total_effort_points := 0.0
var visited_phases: Dictionary = {}
var achievements: Array[String] = []
var cosmetics: Array[String] = ["classic_red"]
var current_cosmetic := "classic_red"

var _economy
var _loaded_profile: Dictionary = {}
var _autosave_seconds := 0.0


func _ready() -> void:
	_loaded_profile = _load_profile()
	_apply_progression_data(_loaded_profile.get("progression", {}))


func _process(delta: float) -> void:
	_autosave_seconds += delta
	if _autosave_seconds >= 15.0:
		_autosave_seconds = 0.0
		save_profile()


func bind_economy(economy) -> void:
	_economy = economy
	_economy.load_save_data(_loaded_profile.get("economy", {}))
	_check_achievements()


func add_exercise(
	distance_m: float,
	active_seconds: float,
	effort_points: float,
	phase: String
) -> void:
	total_distance_m += maxf(0.0, distance_m)
	total_active_seconds += maxf(0.0, active_seconds)
	total_effort_points += maxf(0.0, effort_points)
	if not phase.is_empty():
		visited_phases[phase] = true
	_check_achievements()


func record_delivery(result: Dictionary) -> void:
	if float(result.get("rating", 0.0)) >= 5.0 and _economy != null:
		if _economy.five_star_streak >= 5:
			_unlock("five_star_five", "Five-star streak")
	_check_achievements()
	save_profile()


func get_snapshot() -> Dictionary:
	return {
		"total_distance_m": total_distance_m,
		"total_active_seconds": total_active_seconds,
		"total_effort_points": total_effort_points,
		"visited_phases": visited_phases.duplicate(true),
		"achievements": achievements.duplicate(),
		"cosmetics": cosmetics.duplicate(),
		"current_cosmetic": current_cosmetic,
	}


func select_next_cosmetic() -> String:
	var current_index := cosmetics.find(current_cosmetic)
	current_cosmetic = cosmetics[(current_index + 1) % cosmetics.size()]
	progression_changed.emit(get_snapshot())
	save_profile()
	return current_cosmetic


func save_profile() -> Error:
	var economy_data := {}
	if _economy != null:
		economy_data = _economy.get_save_data()
	var payload := {
		"version": SAVE_VERSION,
		"economy": economy_data,
		"progression": get_snapshot(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload, "\t"))
	return OK


static func migrate_profile(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	var version := int(migrated.get("version", 0))
	if version == 0:
		if not migrated.has("progression"):
			migrated.progression = {
				"total_distance_m": float(migrated.get("distance_m", 0.0)),
				"total_active_seconds": float(migrated.get("active_seconds", 0.0)),
				"total_effort_points": 0.0,
				"visited_phases": {},
				"achievements": [],
				"cosmetics": ["classic_red"],
				"current_cosmetic": "classic_red",
			}
		migrated.version = 1
	return migrated


func _load_profile() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {"version": SAVE_VERSION, "economy": {}, "progression": {}}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {"version": SAVE_VERSION, "economy": {}, "progression": {}}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {"version": SAVE_VERSION, "economy": {}, "progression": {}}
	return migrate_profile(parsed)


func _apply_progression_data(data: Dictionary) -> void:
	total_distance_m = maxf(0.0, float(data.get("total_distance_m", 0.0)))
	total_active_seconds = maxf(0.0, float(data.get("total_active_seconds", 0.0)))
	total_effort_points = maxf(0.0, float(data.get("total_effort_points", 0.0)))
	visited_phases = data.get("visited_phases", {}).duplicate(true)
	achievements.assign(data.get("achievements", []))
	cosmetics.assign(data.get("cosmetics", ["classic_red"]))
	if cosmetics.is_empty():
		cosmetics.append("classic_red")
	current_cosmetic = str(data.get("current_cosmetic", cosmetics[0]))
	if current_cosmetic not in cosmetics:
		current_cosmetic = cosmetics[0]


func _check_achievements() -> void:
	if _economy != null and _economy.deliveries >= 1:
		_unlock("first_delivery", "First delivery")
	if total_distance_m >= 1000.0:
		_unlock("distance_1k", "First kilometre")
	if total_distance_m >= 5000.0:
		_unlock("distance_5k", "City explorer")
		_unlock_cosmetic("ocean_blue")
	if total_active_seconds >= 600.0:
		_unlock("active_10m", "Ten active minutes")
	if visited_phases.size() >= 5:
		_unlock("all_day", "Around the clock")
		_unlock_cosmetic("sunset_gold")


func _unlock(id: String, title: String) -> void:
	if id in achievements:
		return
	achievements.append(id)
	achievement_unlocked.emit(id, title)
	progression_changed.emit(get_snapshot())


func _unlock_cosmetic(id: String) -> void:
	if id not in cosmetics:
		cosmetics.append(id)
