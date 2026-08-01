extends Node
class_name WeatherController

signal weather_changed(weather: String)
signal lightning_struck

const WEATHER_STATES := ["clear", "overcast", "fog", "rain"]
const WEATHER_TARGETS := {
	"clear": {"cloudiness": 0.0, "fog": 0.0, "rain": 0.0},
	"overcast": {"cloudiness": 0.82, "fog": 0.12, "rain": 0.0},
	"fog": {"cloudiness": 0.72, "fog": 1.0, "rain": 0.0},
	"rain": {"cloudiness": 1.0, "fog": 0.42, "rain": 1.0},
}
const WEATHER_TRANSITIONS := {
	"clear": ["clear", "overcast", "fog"],
	"overcast": ["clear", "overcast", "fog", "rain", "rain"],
	"fog": ["clear", "overcast", "fog"],
	"rain": ["overcast", "overcast", "rain", "clear"],
}

@export var player_path: NodePath
@export var automatic_weather := true
@export_range(20.0, 300.0, 1.0) var minimum_weather_seconds := 55.0
@export_range(20.0, 300.0, 1.0) var maximum_weather_seconds := 105.0
@export_range(1.0, 30.0, 0.5) var transition_seconds := 8.0

var current_weather := "clear"
var cloudiness := 0.0
var fog_intensity := 0.0
var rain_intensity := 0.0
var lightning_intensity := 0.0

var _target_cloudiness := 0.0
var _target_fog := 0.0
var _target_rain := 0.0
var _weather_timer := 0.0
var _rng := RandomNumberGenerator.new()
var _rain_particles: GPUParticles3D
var _lightning_light: DirectionalLight3D
var _lightning_bolt: MeshInstance3D
var _lightning_timer := 10.0
var _lightning_elapsed := 1.0
var _lightning_active := false


func _ready() -> void:
	add_to_group("weather_controller")
	_rng.randomize()
	_create_rain()
	_create_lightning()
	set_weather("clear", true)


func _process(delta: float) -> void:
	if automatic_weather:
		_weather_timer -= delta
		if _weather_timer <= 0.0:
			_choose_next_weather()
	var blend_speed := delta / maxf(transition_seconds, 0.01)
	cloudiness = move_toward(cloudiness, _target_cloudiness, blend_speed)
	fog_intensity = move_toward(fog_intensity, _target_fog, blend_speed)
	rain_intensity = move_toward(rain_intensity, _target_rain, blend_speed)
	if _rain_particles != null:
		_rain_particles.amount_ratio = rain_intensity
		_rain_particles.emitting = rain_intensity > 0.01
	_update_lightning(delta)


func set_weather(weather: String, immediate := false) -> void:
	if weather not in WEATHER_STATES:
		push_warning("Unknown weather state: %s" % weather)
		return
	current_weather = weather
	var targets: Dictionary = WEATHER_TARGETS[weather]
	_target_cloudiness = float(targets.cloudiness)
	_target_fog = float(targets.fog)
	_target_rain = float(targets.rain)
	if immediate:
		cloudiness = _target_cloudiness
		fog_intensity = _target_fog
		rain_intensity = _target_rain
		if _rain_particles != null:
			_rain_particles.amount_ratio = rain_intensity
			_rain_particles.emitting = rain_intensity > 0.01
	if weather == "rain":
		_lightning_timer = _rng.randf_range(6.0, 16.0)
	else:
		_lightning_active = false
		lightning_intensity = 0.0
		if _lightning_light != null:
			_lightning_light.light_energy = 0.0
	_reset_weather_timer()
	weather_changed.emit(current_weather)


func get_weather_name() -> String:
	return current_weather.capitalize()


func get_rain_particles() -> GPUParticles3D:
	return _rain_particles


func trigger_lightning() -> void:
	if current_weather != "rain":
		return
	_lightning_active = true
	_lightning_elapsed = 0.0
	_lightning_timer = _rng.randf_range(12.0, 30.0)
	if _lightning_bolt != null:
		_lightning_bolt.position = Vector3(
			_rng.randf_range(-18.0, 18.0),
			22.0,
			-_rng.randf_range(48.0, 72.0)
		)
	lightning_struck.emit()


func _choose_next_weather() -> void:
	var choices: Array = WEATHER_TRANSITIONS[current_weather]
	var next_weather := String(choices[_rng.randi_range(0, choices.size() - 1)])
	set_weather(next_weather)


func _reset_weather_timer() -> void:
	_weather_timer = _rng.randf_range(
		minimum_weather_seconds,
		maxf(minimum_weather_seconds, maximum_weather_seconds)
	)


func _create_rain() -> void:
	var player := get_node_or_null(player_path) as Node3D
	if player == null:
		return
	var rain := GPUParticles3D.new()
	rain.name = "Local Rain"
	rain.position = Vector3(0.0, 9.0, 0.0)
	rain.amount = 420
	rain.amount_ratio = 0.0
	rain.lifetime = 1.35
	rain.randomness = 0.32
	rain.fixed_fps = 30
	rain.interpolate = true
	rain.local_coords = false
	rain.visibility_aabb = AABB(Vector3(-18.0, -20.0, -18.0), Vector3(36.0, 30.0, 36.0))
	rain.add_to_group("weather_rain")

	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(13.0, 1.0, 13.0)
	process_material.direction = Vector3(0.08, -1.0, 0.03)
	process_material.spread = 3.0
	process_material.initial_velocity_min = 13.0
	process_material.initial_velocity_max = 18.0
	process_material.gravity = Vector3(1.4, -3.0, 0.45)
	process_material.scale_min = 0.72
	process_material.scale_max = 1.15
	rain.process_material = process_material

	var streak_mesh := QuadMesh.new()
	streak_mesh.size = Vector2(0.035, 0.95)
	var streak_material := StandardMaterial3D.new()
	streak_material.albedo_color = Color(0.72, 0.86, 0.96, 0.54)
	streak_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	streak_material.no_depth_test = false
	streak_mesh.material = streak_material
	rain.draw_pass_1 = streak_mesh
	player.add_child(rain)
	_rain_particles = rain


func _create_lightning() -> void:
	var flash := DirectionalLight3D.new()
	flash.name = "Lightning Flash"
	flash.rotation_degrees = Vector3(-52.0, 28.0, 0.0)
	flash.light_color = Color("d7e6ff")
	flash.light_energy = 0.0
	flash.shadow_enabled = false
	flash.add_to_group("weather_lightning")
	add_child(flash)
	_lightning_light = flash
	var player := get_node_or_null(player_path) as Node3D
	if player != null:
		var bolt := MeshInstance3D.new()
		bolt.name = "Lightning Bolt"
		bolt.mesh = _make_lightning_bolt_mesh()
		bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bolt.visible = false
		bolt.add_to_group("weather_lightning_bolt")
		player.add_child(bolt)
		_lightning_bolt = bolt


func _update_lightning(delta: float) -> void:
	if current_weather == "rain" and rain_intensity > 0.6:
		_lightning_timer -= delta
		if _lightning_timer <= 0.0 and not _lightning_active:
			trigger_lightning()
	if not _lightning_active:
		return
	# Keep the double flash visible across at least a few rendered frames even
	# if a busy frame arrives while the city is streaming or compiling shaders.
	_lightning_elapsed += minf(delta, 0.045)
	if _lightning_elapsed < 0.085:
		lightning_intensity = 1.0
	elif _lightning_elapsed < 0.16:
		lightning_intensity = 0.08
	elif _lightning_elapsed < 0.255:
		lightning_intensity = 0.74
	elif _lightning_elapsed < 0.46:
		lightning_intensity = lerpf(
			0.42,
			0.0,
			inverse_lerp(0.255, 0.46, _lightning_elapsed)
		)
	else:
		lightning_intensity = 0.0
		_lightning_active = false
	if _lightning_light != null:
		_lightning_light.light_energy = lightning_intensity * 0.9
	if _lightning_bolt != null:
		_lightning_bolt.visible = lightning_intensity > 0.58


func _make_lightning_bolt_mesh() -> ArrayMesh:
	var segments := [
		[Vector2(-1.8, 13.0), Vector2(1.1, 8.0), 0.34],
		[Vector2(1.1, 8.0), Vector2(-0.7, 3.8), 0.31],
		[Vector2(-0.7, 3.8), Vector2(1.5, -0.3), 0.27],
		[Vector2(1.5, -0.3), Vector2(0.3, -4.8), 0.23],
		[Vector2(0.3, -4.8), Vector2(1.8, -9.5), 0.18],
		[Vector2(-0.7, 3.8), Vector2(-3.1, 0.5), 0.18],
		[Vector2(-3.1, 0.5), Vector2(-4.2, -3.2), 0.12],
	]
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for segment: Array in segments:
		var from: Vector2 = segment[0]
		var to: Vector2 = segment[1]
		var width: float = float(segment[2])
		var direction := (to - from).normalized()
		var side := Vector2(-direction.y, direction.x) * width
		var first := vertices.size()
		vertices.append(Vector3(from.x + side.x, from.y + side.y, 0.0))
		vertices.append(Vector3(from.x - side.x, from.y - side.y, 0.0))
		vertices.append(Vector3(to.x + side.x, to.y + side.y, 0.0))
		vertices.append(Vector3(to.x - side.x, to.y - side.y, 0.0))
		for _normal in 4:
			normals.append(Vector3(0.0, 0.0, 1.0))
		indices.append_array([
			first,
			first + 2,
			first + 1,
			first + 1,
			first + 2,
			first + 3,
		])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("e7efff")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color("bbd1ff")
	material.emission_energy_multiplier = 14.0
	material.no_depth_test = true
	material.disable_fog = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, material)
	return mesh
