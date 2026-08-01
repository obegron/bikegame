extends Node

const DYNAMIC_SKY_SHADER: Shader = preload("res://assets/shaders/dynamic_sky.gdshader")
const CLOUD_PANORAMA: Texture2D = preload(
	"res://assets/textures/sky/evening_road_01_pure_sky.png"
)

@export var clock_path: NodePath
@export var environment_path: NodePath
@export var sun_path: NodePath
@export var weather_path: NodePath
@export var shooting_stars_enabled := true
@export_range(0.0, 1.0, 0.01) var mediterranean_warmth := 0.0

@onready var _clock = get_node(clock_path)
@onready var _world_environment: WorldEnvironment = get_node(environment_path)
@onready var _sun: DirectionalLight3D = get_node(sun_path)
@onready var _weather: Node = get_node_or_null(weather_path)

const HOURS := [0.0, 5.0, 8.0, 12.0, 18.5, 21.0, 24.0]
const SKY_COLORS := [
	Color("10172d"),
	Color("2d3859"),
	Color("86bed3"),
	Color("70b4d4"),
	Color("e68a68"),
	Color("263453"),
	Color("10172d"),
]
const LIGHT_COLORS := [
	Color("7180ac"),
	Color("d49a78"),
	Color("fff0d0"),
	Color("fff7df"),
	Color("ffb073"),
	Color("8592bd"),
	Color("7180ac"),
]
const ENERGIES := [0.12, 0.28, 0.95, 1.1, 0.75, 0.2, 0.12]

var _sky_material: ShaderMaterial
var _water_controller: Node
var _shooting_star_random := RandomNumberGenerator.new()
var _shooting_star_wait := 0.0
var _shooting_star_elapsed := -1.0
var _shooting_star_duration := 1.25
var _shooting_star_from := Vector3(-0.65, 0.68, -0.34).normalized()
var _shooting_star_to := Vector3(-0.28, 0.34, -0.9).normalized()
var _shooting_star_progress := 0.0
var _shooting_star_visibility := 0.0


func _ready() -> void:
	_sky_material = ShaderMaterial.new()
	_sky_material.shader = DYNAMIC_SKY_SHADER
	_sky_material.set_shader_parameter("cloud_panorama", CLOUD_PANORAMA)
	_sky_material.set_meta("layered_cloud_sky", true)
	_sky_material.set_meta("cloud_detail_texture", CLOUD_PANORAMA.resource_path)
	var sky := Sky.new()
	sky.sky_material = _sky_material
	_world_environment.environment.sky = sky
	_world_environment.environment.background_mode = Environment.BG_SKY
	_water_controller = get_tree().get_first_node_in_group("terrain_provider")
	_shooting_star_random.randomize()
	# With the default twelve-minute day, this gives a clear night only about
	# an even chance of seeing one. A shooting star is a small surprise, not a
	# repeating ambient animation.
	_shooting_star_wait = _shooting_star_random.randf_range(150.0, 360.0)
	set_meta("rare_shooting_star_interval_seconds", Vector2(150.0, 360.0))


func _process(delta: float) -> void:
	var hour: float = _clock.hour
	var segment := _find_segment(hour)
	var blend := inverse_lerp(HOURS[segment], HOURS[segment + 1], hour)
	var environment := _world_environment.environment
	var sky_color: Color = SKY_COLORS[segment].lerp(SKY_COLORS[segment + 1], blend)
	var light_color: Color = LIGHT_COLORS[segment].lerp(LIGHT_COLORS[segment + 1], blend)
	var light_energy := lerpf(ENERGIES[segment], ENERGIES[segment + 1], blend)
	var cloudiness: float = float(_weather.cloudiness) if _weather != null else 0.0
	var weather_fog: float = float(_weather.fog_intensity) if _weather != null else 0.0
	var rain: float = float(_weather.rain_intensity) if _weather != null else 0.0
	var lightning: float = float(_weather.lightning_intensity) if _weather != null else 0.0
	var sun_height := maxf(
		0.0,
		sin(clampf((hour - 5.0) / 16.0, 0.0, 1.0) * PI)
	)
	var riviera_warmth := mediterranean_warmth * (
		0.42 + (1.0 - sun_height) * 0.58
	)
	light_color = light_color.lerp(Color("ffd09a"), riviera_warmth * 0.42)
	sky_color = sky_color.lerp(Color("79b5ce"), mediterranean_warmth * sun_height * 0.16)
	_update_shooting_star(delta, hour, cloudiness)
	var storm_gray := Color("727d82")
	sky_color = sky_color.lerp(storm_gray, cloudiness * 0.34)
	light_color = light_color.lerp(Color("c3c8c7"), cloudiness * 0.48)
	light_energy *= lerpf(1.0, 0.64, cloudiness)
	var daylight := smoothstep(0.12, 0.92, light_energy)
	environment.background_color = sky_color
	# Cooler, lower-energy fill preserves readable shade without washing every
	# facade to the same value. Daylight exposure is lowered separately so pale
	# sand and water keep their color instead of clipping to white, while night
	# regains exposure for the headlight and working lamps.
	environment.ambient_light_color = sky_color.lerp(
		light_color,
		0.48 + mediterranean_warmth * 0.08
	)
	environment.ambient_light_energy = maxf(0.04, light_energy * 0.24)
	environment.tonemap_exposure = lerpf(1.0, 0.76, daylight) * lerpf(1.0, 0.94, cloudiness)
	environment.adjustment_contrast = lerpf(1.04, 1.09, daylight)
	environment.adjustment_saturation = (
		lerpf(1.02, 1.06 + mediterranean_warmth * 0.055, daylight)
		* lerpf(1.0, 0.88, cloudiness)
	)
	environment.fog_enabled = weather_fog > 0.002
	environment.fog_light_color = sky_color.lerp(Color("aab3b3"), 0.58)
	environment.fog_light_energy = lerpf(0.72, 0.94, daylight)
	environment.fog_density = lerpf(0.0, 0.032, weather_fog)
	environment.fog_height = 2.5
	environment.fog_height_density = 0.08
	environment.fog_aerial_perspective = 0.62
	environment.fog_sky_affect = lerpf(0.48, 0.88, weather_fog)
	_sun.light_color = light_color
	_sun.light_energy = light_energy * 0.98
	_sun.rotation_degrees.x = -15.0 - sin((hour - 6.0) / 24.0 * TAU) * 55.0
	_sun.rotation_degrees.y = hour / 24.0 * 360.0 - 90.0
	_update_sky(sky_color, light_color, light_energy, cloudiness, rain, lightning)


func _update_shooting_star(delta: float, hour: float, cloudiness: float) -> void:
	if not shooting_stars_enabled or not _is_dark_night(hour):
		_shooting_star_elapsed = -1.0
		_shooting_star_progress = 0.0
		_shooting_star_visibility = 0.0
		return
	if _shooting_star_elapsed >= 0.0:
		_shooting_star_elapsed += delta
		_shooting_star_progress = clampf(
			_shooting_star_elapsed / _shooting_star_duration,
			0.0,
			1.0
		)
		_shooting_star_visibility = pow(
			maxf(sin(_shooting_star_progress * PI), 0.0),
			0.55
		)
		if _shooting_star_elapsed >= _shooting_star_duration:
			_shooting_star_elapsed = -1.0
			_shooting_star_progress = 0.0
			_shooting_star_visibility = 0.0
			_shooting_star_wait = _shooting_star_random.randf_range(180.0, 420.0)
		return
	# Dense clouds already hide the star shader; pausing the rare-event clock
	# avoids silently spending the event behind an overcast sky.
	if cloudiness > 0.52:
		return
	_shooting_star_wait -= delta
	if _shooting_star_wait <= 0.0:
		trigger_shooting_star()


func trigger_shooting_star(force := false) -> bool:
	var cloudiness: float = float(_weather.cloudiness) if _weather != null else 0.0
	if (
		not shooting_stars_enabled
		or (not force and not _is_dark_night(float(_clock.hour)))
		or (not force and cloudiness > 0.52)
	):
		return false
	var azimuth := _shooting_star_random.randf_range(0.0, TAU)
	var direction_sign := -1.0 if _shooting_star_random.randf() < 0.5 else 1.0
	var start_elevation := _shooting_star_random.randf_range(0.58, 0.96)
	var end_elevation := maxf(
		0.24,
		start_elevation - _shooting_star_random.randf_range(0.24, 0.42)
	)
	var end_azimuth := azimuth + (
		direction_sign * _shooting_star_random.randf_range(0.3, 0.54)
	)
	_shooting_star_from = _sky_direction(azimuth, start_elevation)
	_shooting_star_to = _sky_direction(end_azimuth, end_elevation)
	_shooting_star_duration = _shooting_star_random.randf_range(1.05, 1.45)
	_shooting_star_elapsed = 0.0
	_shooting_star_progress = 0.0
	_shooting_star_visibility = 0.01
	return true


func _sky_direction(azimuth: float, elevation: float) -> Vector3:
	var horizontal := cos(elevation)
	return Vector3(
		horizontal * cos(azimuth),
		sin(elevation),
		horizontal * sin(azimuth)
	).normalized()


func _is_dark_night(hour: float) -> bool:
	var wrapped := fposmod(hour, 24.0)
	return wrapped >= 21.5 or wrapped < 4.5


func _update_sky(
	sky_color: Color,
	light_color: Color,
	light_energy: float,
	cloudiness: float,
	rain: float,
	lightning: float
) -> void:
	if _sky_material == null:
		return
	var daylight := smoothstep(0.12, 0.92, light_energy)
	var star_visibility := 1.0 - smoothstep(0.1, 0.34, light_energy)
	var zenith := sky_color.darkened(lerpf(0.34, 0.16, daylight))
	var horizon := sky_color.lightened(lerpf(0.08, 0.24, daylight))
	var cloud_day_color := light_color.lerp(Color("b7c3c7"), 0.5)
	var cloud_night_color := sky_color.lightened(0.12)
	var clouds := cloud_night_color.lerp(cloud_day_color, daylight)
	clouds = clouds.lerp(Color("657075"), rain * 0.56)
	var sun_direction := -_sun.global_transform.basis.z.normalized()
	var reflected_sun_color := light_color.lightened(0.08)
	_sky_material.set_shader_parameter("zenith_color", zenith)
	_sky_material.set_shader_parameter("horizon_color", horizon)
	_sky_material.set_shader_parameter("cloud_color", clouds)
	_sky_material.set_shader_parameter(
		"cloud_light",
		lerpf(0.5, 0.88, daylight) * lerpf(1.0, 0.58, cloudiness)
	)
	_sky_material.set_shader_parameter("cloud_coverage", lerpf(0.56, 0.9, cloudiness))
	_sky_material.set_shader_parameter(
		"star_visibility",
		star_visibility * lerpf(1.0, 0.08, cloudiness)
	)
	_sky_material.set_shader_parameter(
		"sun_visibility",
		smoothstep(0.28, 0.72, light_energy) * lerpf(1.0, 0.1, cloudiness)
	)
	_sky_material.set_shader_parameter("moon_visibility", star_visibility * 0.82)
	_sky_material.set_shader_parameter("sun_color", reflected_sun_color)
	_sky_material.set_shader_parameter("sun_direction", sun_direction)
	_sky_material.set_shader_parameter("lightning_flash", lightning)
	_sky_material.set_shader_parameter("shooting_star_from", _shooting_star_from)
	_sky_material.set_shader_parameter("shooting_star_to", _shooting_star_to)
	_sky_material.set_shader_parameter(
		"shooting_star_progress",
		_shooting_star_progress
	)
	_sky_material.set_shader_parameter(
		"shooting_star_visibility",
		_shooting_star_visibility
	)
	if _water_controller == null:
		_water_controller = get_tree().get_first_node_in_group("terrain_provider")
	if (
		_water_controller != null
		and _water_controller.has_method("set_water_sky_parameters")
	):
		_water_controller.call(
			"set_water_sky_parameters",
			zenith,
			horizon,
			reflected_sun_color,
			sun_direction,
			daylight
		)


func _find_segment(hour: float) -> int:
	for index in HOURS.size() - 1:
		if hour >= HOURS[index] and hour < HOURS[index + 1]:
			return index
	return HOURS.size() - 2
