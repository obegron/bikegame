extends Node3D

@export var distant_fleet_seed := 0

const WATER_SHADER: Shader = preload("res://assets/shaders/water.gdshader")
const FACADE_SHADER: Shader = preload("res://assets/shaders/facade.gdshader")
const STONE_SHADER: Shader = preload("res://assets/shaders/stone.gdshader")
const ROOF_SHADER: Shader = preload("res://assets/shaders/roof_tiles.gdshader")
const ROAD_SURFACE_SHADER: Shader = preload("res://assets/shaders/road_surface.gdshader")
const FOLIAGE_SHADER: Shader = preload("res://assets/shaders/foliage_wind.gdshader")
const ISLAND_TERRAIN_SHADER: Shader = preload("res://assets/shaders/island_terrain.gdshader")
const FOLIAGE_ASSETS := {
	"tree_default": preload("res://assets/models/foliage/tree_default.glb"),
	"tree_oak": preload("res://assets/models/foliage/tree_oak.glb"),
	"tree_pine": preload("res://assets/models/foliage/tree_pineDefaultA.glb"),
	"tree_cherry": preload("res://assets/models/foliage/tree_oak.glb"),
	"bush_detailed": preload("res://assets/models/foliage/plant_bushDetailed.glb"),
	"bush_small": preload("res://assets/models/foliage/plant_bushSmall.glb"),
	"grass": preload("res://assets/models/foliage/grass_large.glb"),
	"grass_leaf": preload("res://assets/models/foliage/grass_leafsLarge.glb"),
	"flower_purple": preload("res://assets/models/foliage/flower_purpleB.glb"),
	"flower_red": preload("res://assets/models/foliage/flower_redB.glb"),
	"flower_yellow": preload("res://assets/models/foliage/flower_yellowB.glb"),
	"dandelion_yellow": preload("res://assets/models/foliage/flower_yellowB.glb"),
	"dandelion_seed": preload("res://assets/models/foliage/flower_purpleB.glb"),
}
const FOLIAGE_CHUNK_SIZE := 72.0
const FOLIAGE_PROFILES := {
	"tree_default": {
		"scale": Vector2(2.8, 4.0),
		"vertical_scale": Vector2(0.92, 1.12),
		"max_slope": 30.0,
		"tilt": 0.025,
		"wind": 0.035,
		"wind_height": 1.75,
		"visibility": 285.0,
	},
	"tree_oak": {
		"scale": Vector2(2.9, 4.2),
		"vertical_scale": Vector2(0.88, 1.16),
		"max_slope": 28.0,
		"tilt": 0.03,
		"wind": 0.04,
		"wind_height": 1.6,
		"visibility": 285.0,
	},
	"tree_pine": {
		"scale": Vector2(2.8, 4.15),
		"vertical_scale": Vector2(0.94, 1.18),
		"max_slope": 32.0,
		"tilt": 0.022,
		"wind": 0.03,
		"wind_height": 1.8,
		"visibility": 300.0,
	},
	"tree_cherry": {
		"scale": Vector2(2.9, 4.1),
		"vertical_scale": Vector2(0.88, 1.12),
		"max_slope": 26.0,
		"tilt": 0.028,
		"wind": 0.045,
		"wind_height": 1.6,
		"visibility": 290.0,
		"detail_mix": 0.72,
	},
	"bush_detailed": {
		"scale": Vector2(1.75, 2.8),
		"vertical_scale": Vector2(0.82, 1.12),
		"max_slope": 34.0,
		"tilt": 0.045,
		"wind": 0.055,
		"wind_height": 0.85,
		"visibility": 205.0,
	},
	"bush_small": {
		"scale": Vector2(1.75, 2.75),
		"vertical_scale": Vector2(0.78, 1.08),
		"max_slope": 36.0,
		"tilt": 0.05,
		"wind": 0.06,
		"wind_height": 0.7,
		"visibility": 195.0,
	},
	"grass": {
		"scale": Vector2(1.45, 2.6),
		"vertical_scale": Vector2(0.72, 1.24),
		"max_slope": 42.0,
		"tilt": 0.08,
		"wind": 0.09,
		"wind_height": 0.55,
		"visibility": 135.0,
	},
	"grass_leaf": {
		"scale": Vector2(1.5, 2.7),
		"vertical_scale": Vector2(0.76, 1.2),
		"max_slope": 42.0,
		"tilt": 0.075,
		"wind": 0.085,
		"wind_height": 0.62,
		"visibility": 140.0,
	},
	"flower_purple": {
		"scale": Vector2(1.35, 2.0),
		"vertical_scale": Vector2(0.82, 1.18),
		"max_slope": 38.0,
		"tilt": 0.06,
		"wind": 0.075,
		"wind_height": 0.55,
		"visibility": 120.0,
	},
	"flower_red": {
		"scale": Vector2(1.35, 2.0),
		"vertical_scale": Vector2(0.82, 1.18),
		"max_slope": 38.0,
		"tilt": 0.06,
		"wind": 0.075,
		"wind_height": 0.55,
		"visibility": 120.0,
	},
	"flower_yellow": {
		"scale": Vector2(1.35, 2.0),
		"vertical_scale": Vector2(0.82, 1.18),
		"max_slope": 38.0,
		"tilt": 0.06,
		"wind": 0.075,
		"wind_height": 0.55,
		"visibility": 120.0,
	},
	"dandelion_yellow": {
		"scale": Vector2(1.25, 1.85),
		"vertical_scale": Vector2(0.88, 1.28),
		"max_slope": 38.0,
		"tilt": 0.075,
		"wind": 0.09,
		"wind_height": 0.45,
		"visibility": 105.0,
	},
	"dandelion_seed": {
		"scale": Vector2(1.35, 1.95),
		"vertical_scale": Vector2(0.9, 1.3),
		"max_slope": 38.0,
		"tilt": 0.075,
		"wind": 0.095,
		"wind_height": 0.48,
		"visibility": 105.0,
	},
}

const ToyGeometry = preload("res://src/world/toy_geometry.gd")

const GRASS := Color("579d68")
const GARDEN_GRASS := Color("76b46e")
const ASPHALT := Color("3b5167")
const COBBLE := Color("c7bba0")
const PALE_COBBLE := Color("baac91")
const SIDEWALK := Color("e2d5b7")
const WATER := Color("279cba")
const STONE := Color("b7bea9")
const DARK_STONE := Color("829a95")
const TERRACOTTA := Color("d96548")
const SLATE := Color("426f88")
const TRUNK := Color("96643f")
const LEAVES := Color("369e6c")
const CYCLE_RED := Color("e9816d")

const WORLD_MIN_X := -205.0
const WORLD_MAX_X := 205.0
const WORLD_MIN_Z := -185.0
const WORLD_MAX_Z := 152.0
const TERRAIN_MIN_X := -235.0
const TERRAIN_MAX_X := 235.0
const TERRAIN_MIN_Z := -225.0
const TERRAIN_MAX_Z := 195.0
const TERRAIN_CELL_SIZE := 2.5
const TERRAIN_WIDTH := 189
const TERRAIN_DEPTH := 169
const COAST_CENTER := Vector2(0.0, -15.0)
const COAST_HALF_EXTENTS := Vector2(218.0, 195.0)
const WATER_LEVEL := -0.65

const HERITAGE_PALETTE := [
	Color("f4be62"),
	Color("ed886d"),
	Color("f9d88d"),
	Color("7ec9b1"),
	Color("c6a1cf"),
	Color("77bad3"),
	Color("efaa56"),
]

var _heritage_window_transforms: Array[Transform3D] = []
var _heritage_door_transforms: Array[Transform3D] = []
var _house_trim_transforms: Array[Transform3D] = []
var _house_pilaster_transforms: Array[Transform3D] = []
var _house_downpipe_transforms: Array[Transform3D] = []
var _house_chimney_transforms: Array[Transform3D] = []
var _house_chimney_pot_transforms: Array[Transform3D] = []
var _house_planter_transforms: Array[Transform3D] = []
var _house_planter_red_flower_transforms: Array[Transform3D] = []
var _house_planter_yellow_flower_transforms: Array[Transform3D] = []
var _house_vine_stem_transforms: Array[Transform3D] = []
var _house_vine_leaf_transforms: Array[Transform3D] = []
var _house_dormer_wall_transforms: Array[Transform3D] = []
var _house_dormer_roof_transforms: Array[Transform3D] = []
var _lamp_pole_transforms: Array[Transform3D] = []
var _lamp_bulb_transforms: Array[Transform3D] = []
var _city_flower_pot_transforms: Array[Transform3D] = []
var _city_flower_stem_transforms: Array[Transform3D] = []
var _city_flower_leaf_transforms: Array[Transform3D] = []
var _city_flower_red_transforms: Array[Transform3D] = []
var _city_flower_yellow_transforms: Array[Transform3D] = []
var _city_flower_purple_transforms: Array[Transform3D] = []
var _garland_leaf_transforms: Array[Transform3D] = []
var _garland_red_flower_transforms: Array[Transform3D] = []
var _garland_yellow_flower_transforms: Array[Transform3D] = []
var _lamp_bulb_material: StandardMaterial3D
var _street_lights: Array[OmniLight3D] = []
var _mill_wheel_rotator: Node3D
var _lighthouse_beacon_rotator: Node3D
var _lighthouse_beam_mesh: MeshInstance3D
var _lighthouse_spotlight: SpotLight3D
var _lighthouse_lantern_glow: OmniLight3D
var _lighthouse_lantern_material: StandardMaterial3D
var _height_noise := FastNoiseLite.new()
var _smooth_road_heights := PackedFloat32Array()
var _visual_terrain_heights := PackedFloat32Array()
var _terrain_macro_texture: NoiseTexture2D
var _facade_material_cache := {}
var _stone_material_cache := {}
var _roof_material_cache := {}
var _road_material_cache := {}
var _road_corridors: Array[Dictionary] = []
var _bridge_surfaces: Array[Dictionary] = []
var _road_plan_only := false
var _obstacle_clearings: Array[Vector3] = []
var _foliage_transforms := {
	"tree_default": [],
	"tree_oak": [],
	"tree_pine": [],
	"tree_cherry": [],
	"bush_detailed": [],
	"bush_small": [],
	"grass": [],
	"grass_leaf": [],
	"flower_purple": [],
	"flower_red": [],
	"flower_yellow": [],
	"dandelion_yellow": [],
	"dandelion_seed": [],
}
var _foliage_custom_data := {
	"tree_default": [],
	"tree_oak": [],
	"tree_pine": [],
	"tree_cherry": [],
	"bush_detailed": [],
	"bush_small": [],
	"grass": [],
	"grass_leaf": [],
	"flower_purple": [],
	"flower_red": [],
	"flower_yellow": [],
	"dandelion_yellow": [],
	"dandelion_seed": [],
}
var _foliage_tree_positions: Array[Vector2] = []
var _foliage_shrub_positions: Array[Vector2] = []
var _boat_routes: Array[Dictionary] = []
var _boat_navigation_lights: Array[Dictionary] = []
var _water_materials: Array[ShaderMaterial] = []
var _world_motion_time := 0.0


func _ready() -> void:
	add_to_group("terrain_provider")
	_configure_height_noise()
	# Register the complete street plan before generating terrain. This lets the
	# terrain itself be gently graded under roads, so the bike rides the same
	# smooth surface that is drawn instead of following lateral noise bumps.
	_road_plan_only = true
	_make_city_roads()
	_road_plan_only = false
	_harmonize_road_grade_endpoints()
	_prepare_smooth_road_surface()
	_make_ground_and_water()
	_make_city_roads()
	_make_bridges_and_quays()
	_make_old_town()
	_make_south_quarter()
	_make_east_quarter()
	_make_west_bank()
	_make_gardens()
	_make_north_bank()
	_make_hill_village()
	_make_orchard_outskirts()
	_make_coastal_landmarks()
	_make_foliage_pass()
	_make_distant_boats()
	_make_street_furniture()
	_make_boundaries()
	_flush_decoration_batches()
	_flush_foliage_batches()


func _process(delta: float) -> void:
	_world_motion_time += delta
	if _mill_wheel_rotator != null:
		_mill_wheel_rotator.rotate_y(delta * 0.24)
	if _lighthouse_beacon_rotator != null and _lighthouse_beacon_rotator.visible:
		_lighthouse_beacon_rotator.rotate_y(delta * 0.29)
	_update_distant_boats()


func _make_ground_and_water() -> void:
	_make_terrain()
	_make_surrounding_ocean()
	_make_water_body(
		"North river",
		Vector3(0.0, WATER_LEVEL, -105.0),
		Vector2(340.0, 18.0),
		WATER
	)
	_make_water_body(
		"Saint Claire canal",
		Vector3(-73.0, WATER_LEVEL + 0.01, 15.0),
		Vector2(14.0, 240.0),
		WATER.darkened(0.04)
	)


func _make_surrounding_ocean() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(1100.0, 1000.0)
	plane.subdivide_width = 224
	plane.subdivide_depth = 192
	var surface := MeshInstance3D.new()
	surface.name = "Caledonian sea"
	surface.position = Vector3(0.0, WATER_LEVEL - 0.035, COAST_CENTER.y)
	surface.mesh = plane
	var material := _water_material(Color("2f718e"))
	material.set_shader_parameter("wave_height", 0.36)
	material.set_shader_parameter("wave_speed", 0.52)
	material.set_shader_parameter("normal_strength", 1.2)
	material.set_shader_parameter("foam_strength", 0.3)
	surface.material_override = material
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	surface.add_to_group("animated_water")
	surface.add_to_group("surrounding_ocean")
	add_child(surface)


func _make_water_body(
	node_name: String,
	at: Vector3,
	size: Vector2,
	color: Color
) -> void:
	_make_visual_box(
		node_name + " depth",
		at - Vector3.UP * 0.18,
		Vector3(size.x, 0.34, size.y),
		color.darkened(0.48)
	)

	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = clampi(int(ceil(size.x / 1.5)), 6, 224)
	plane.subdivide_depth = clampi(int(ceil(size.y / 1.5)), 6, 160)
	var surface := MeshInstance3D.new()
	surface.name = node_name
	surface.position = at + Vector3.UP * 0.035
	surface.mesh = plane
	var water_material := _water_material(color)
	water_material.set_shader_parameter("normal_strength", 1.35)
	water_material.set_shader_parameter("foam_strength", 0.18)
	surface.material_override = water_material
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	surface.add_to_group("animated_water")
	add_child(surface)

	var probe := ReflectionProbe.new()
	probe.name = node_name + " reflections"
	probe.position = at + Vector3.UP * 7.0
	probe.size = Vector3(size.x, 26.0, size.y)
	probe.origin_offset = Vector3(0.0, 4.5, 0.0)
	probe.intensity = 0.72
	probe.max_distance = maxf(size.x, size.y)
	probe.box_projection = true
	probe.add_to_group("water_reflection")
	add_child(probe)


func _water_material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	material.set_shader_parameter("shallow_color", Color("4ac9cb"))
	material.set_shader_parameter("deep_color", Color("187d9e"))
	material.set_shader_parameter("foam_color", Color("c8ddd7"))
	material.set_meta("lightweight_wave_cascade_count", 5)
	material.set_meta("distance_faded_wave_detail", true)
	_water_materials.append(material)
	return material


func set_water_sky_parameters(
	zenith_color: Color,
	horizon_color: Color,
	sun_color: Color,
	sun_direction: Vector3,
	daylight: float
) -> void:
	for material: ShaderMaterial in _water_materials:
		material.set_shader_parameter("sky_zenith_color", zenith_color)
		material.set_shader_parameter("sky_horizon_color", horizon_color)
		material.set_shader_parameter("sun_color", sun_color)
		material.set_shader_parameter("sun_direction", sun_direction)
		material.set_shader_parameter("daylight", daylight)


func _island_terrain_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ISLAND_TERRAIN_SHADER
	material.set_shader_parameter("macro_noise_texture", _terrain_macro_texture)
	material.set_shader_parameter("grass_color", GRASS)
	material.set_shader_parameter("heather_color", Color("4f946b"))
	material.set_shader_parameter("sand_color", Color("f2d39b"))
	material.set_shader_parameter("wet_sand_color", Color("c6b280"))
	material.set_shader_parameter("cliff_color", Color("9ba9a6"))
	material.set_shader_parameter("cliff_highlight", Color("c3c6b2"))
	material.set_shader_parameter("water_level", WATER_LEVEL)
	return material


func ground_height_at(x: float, z: float) -> float:
	if not _smooth_road_heights.is_empty():
		return _height_from_grid(_smooth_road_heights, x, z)
	var natural_height := _natural_ground_height_at(x, z)
	# Channels and open sea remain cut through the island; their crossings are
	# handled by real bridge collision instead of terrain grading.
	if natural_height < WATER_LEVEL - 0.12 or _road_corridors.is_empty():
		return natural_height

	var point := Vector2(x, z)
	var best_score := INF
	var graded_height := natural_height
	var grade_blend := 0.0
	for corridor: Dictionary in _road_corridors:
		var from: Vector2 = corridor.from
		var to: Vector2 = corridor.to
		var radius: float = corridor.radius
		var feather := radius + 2.4
		var segment := to - from
		var is_junction := segment.is_zero_approx()
		var weight := 0.0
		if not is_junction:
			weight = clampf(
				(point - from).dot(segment) / segment.length_squared(),
				0.0,
				1.0
			)
		var distance := point.distance_to(from.lerp(to, weight))
		if distance >= feather:
			continue
		# Circular junction grading owns its complete apron. Without this
		# priority, each incoming line can win different triangles and tear the
		# concentric cycle/sidewalk rings on sloped terrain.
		var score := (
			_junction_grade_score(distance, radius)
			if is_junction
			else distance / maxf(radius, 0.1)
		)
		if score >= best_score:
			continue
		best_score = score
		graded_height = lerpf(
			float(corridor.from_height),
			float(corridor.to_height),
			weight
		)
		grade_blend = 1.0 - smoothstep(radius, feather, distance)
	return lerpf(natural_height, graded_height, grade_blend)


func _junction_grade_score(distance: float, radius: float) -> float:
	return -2.0 + distance / maxf(radius, 0.1)


func travel_surface_height_at(x: float, z: float) -> float:
	var surface_height := ground_height_at(x, z)
	var point := Vector2(x, z)
	for bridge: Dictionary in _bridge_surfaces:
		var from: Vector2 = bridge.from
		var to: Vector2 = bridge.to
		var segment := to - from
		var weight := (point - from).dot(segment) / segment.length_squared()
		if weight < 0.0 or weight > 1.0:
			continue
		if point.distance_to(from.lerp(to, weight)) > float(bridge.width) * 0.5:
			continue
		# The registered height is the top of the segmented deck boxes, not
		# their center line, so traffic remains visibly on the bridge.
		var bridge_height := (
			lerpf(float(bridge.from_height), float(bridge.to_height), weight)
			+ sin(weight * PI) * float(bridge.arch_height)
			+ 0.03
		)
		surface_height = maxf(surface_height, bridge_height)
	return surface_height


func _natural_ground_height_at(x: float, z: float) -> float:
	if absf(x + 73.0) < 7.2 and z > -105.0 and z < 178.0:
		return -1.75
	if absf(z + 105.0) < 8.5:
		return -2.2

	var broad_noise := _height_noise.get_noise_2d(x, z) * 5.2
	var secondary := _height_noise.get_noise_2d(x * 2.3 + 113.0, z * 2.3 - 71.0) * 0.65
	var old_town_distance := Vector2(x * 0.92, z).length()
	var outskirts_weight := smoothstep(68.0, 145.0, old_town_distance)
	var canal_flatten := smoothstep(12.0, 29.0, absf(x + 73.0))
	var river_flatten := smoothstep(11.0, 30.0, absf(z + 105.0))
	var east_hill := smoothstep(75.0, 155.0, x) * 3.2
	# Historic centres rarely occupy a perfectly level slab. A broad civic
	# rise gives the church, town hall, and market a layered skyline while the
	# registered road grades keep every approach gentle enough to ride.
	var civic_offset := Vector2(x, z + 6.0)
	var civic_distance := Vector2(
		civic_offset.x / 72.0,
		civic_offset.y / 64.0
	).length()
	var civic_hill := (
		1.0 - smoothstep(0.22, 1.02, civic_distance)
	) * 4.35
	var church_spur_distance := Vector2(
		(x + 24.0) / 38.0,
		(z + 9.0) / 32.0
	).length()
	var church_spur := (
		1.0 - smoothstep(0.16, 1.0, church_spur_distance)
	) * 0.95
	var civic_undulation := (
		_height_noise.get_noise_2d(x * 1.7 + 239.0, z * 1.7 - 181.0)
		* 0.34
		* (1.0 - smoothstep(0.15, 1.0, civic_distance))
	)
	var inland_height := (
		(broad_noise + secondary + east_hill)
		* outskirts_weight
		* canal_flatten
		* river_flatten
		+ civic_hill
		+ church_spur
		+ civic_undulation
	)
	return _coastal_height(x, z, inland_height)


func _harmonize_road_grade_endpoints() -> void:
	# A branch trimmed at the edge of a circular apron may naturally sit at a
	# different coastal/noise height than the apron center. Share the apron
	# grade at that endpoint so the transition slopes outward continuously.
	for junction: Dictionary in _road_corridors:
		var junction_from: Vector2 = junction.from
		var junction_to: Vector2 = junction.to
		if not junction_from.is_equal_approx(junction_to):
			continue
		var junction_height: float = junction.from_height
		var junction_radius: float = junction.radius + 0.35
		for corridor: Dictionary in _road_corridors:
			var from: Vector2 = corridor.from
			var to: Vector2 = corridor.to
			if from.is_equal_approx(to):
				continue
			if from.distance_to(junction_from) <= junction_radius:
				corridor["from_height"] = junction_height
			if to.distance_to(junction_from) <= junction_radius:
				corridor["to_height"] = junction_height


func _coastal_height(x: float, z: float, inland_height: float) -> float:
	var relative := Vector2(x, z) - COAST_CENTER
	var normalized := Vector2(
		absf(relative.x) / COAST_HALF_EXTENTS.x,
		absf(relative.y) / COAST_HALF_EXTENTS.y
	)
	var coast_noise := _height_noise.get_noise_2d(
		x * 0.61 + 417.0,
		z * 0.61 - 283.0
	) * 0.075
	var coast_metric := pow(normalized.x, 3.0) + pow(normalized.y, 3.0) + coast_noise
	var inward_distance := (1.0 - coast_metric) * 56.0
	if _coast_is_beach(x, z):
		var beach_blend := smoothstep(-9.0, 24.0, inward_distance)
		var beach_land := maxf(inland_height * 0.58, 0.16)
		return lerpf(WATER_LEVEL - 4.4, beach_land, beach_blend)

	var cliff_blend := smoothstep(-1.5, 7.0, inward_distance)
	var cliff_lift := (
		1.0 - smoothstep(7.0, 25.0, inward_distance)
	) * 2.8
	var cliff_top := maxf(inland_height, 0.7) + cliff_lift
	return lerpf(WATER_LEVEL - 7.5, cliff_top, cliff_blend)


func _coast_is_beach(x: float, z: float) -> bool:
	# Broad pale bays on the south and north-west contrast with exposed dark
	# headlands on the north and east, giving the island a Scottish silhouette.
	if z > 118.0 and x > -142.0 and x < 104.0:
		return true
	if x < -178.0 and z > -84.0 and z < 92.0:
		return true
	return z < -178.0 and x > -78.0 and x < 62.0


func _configure_height_noise() -> void:
	_height_noise.seed = 0xB1CE
	_height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_height_noise.frequency = 0.012
	_height_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_height_noise.fractal_octaves = 4
	_height_noise.fractal_gain = 0.48
	_height_noise.fractal_lacunarity = 2.05

	# Terrain3D uses a reusable noise texture for broad color variation rather
	# than evaluating obvious grid noise independently for every ground pixel.
	var material_noise := FastNoiseLite.new()
	material_noise.seed = 0x71D3
	material_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	material_noise.frequency = 0.022
	material_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	material_noise.fractal_octaves = 4
	material_noise.fractal_gain = 0.52
	material_noise.fractal_lacunarity = 2.0
	_terrain_macro_texture = NoiseTexture2D.new()
	_terrain_macro_texture.width = 256
	_terrain_macro_texture.height = 256
	_terrain_macro_texture.seamless = true
	_terrain_macro_texture.normalize = true
	_terrain_macro_texture.generate_mipmaps = true
	_terrain_macro_texture.noise = material_noise


func _make_terrain() -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var heights := PackedFloat32Array()

	for z_index in TERRAIN_DEPTH:
		var z := TERRAIN_MIN_Z + float(z_index) * TERRAIN_CELL_SIZE
		for x_index in TERRAIN_WIDTH:
			var x := TERRAIN_MIN_X + float(x_index) * TERRAIN_CELL_SIZE
			var height := ground_height_at(x, z)
			var normal := _terrain_normal(x, z)
			vertices.append(Vector3(x, height, z))
			heights.append(height)
			normals.append(normal)
			colors.append(_terrain_control_at(x, z, height, normal))
			uvs.append(Vector2(float(x_index) / 8.0, float(z_index) / 8.0))

	for z_index in TERRAIN_DEPTH - 1:
		for x_index in TERRAIN_WIDTH - 1:
			var top_left := z_index * TERRAIN_WIDTH + x_index
			var top_right := top_left + 1
			var bottom_left := top_left + TERRAIN_WIDTH
			var bottom_right := bottom_left + 1
			indices.append(top_left)
			indices.append(top_right)
			indices.append(bottom_left)
			indices.append(top_right)
			indices.append(bottom_right)
			indices.append(bottom_left)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var terrain_mesh := ArrayMesh.new()
	terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var terrain := MeshInstance3D.new()
	terrain.name = "Rolling terrain"
	terrain.mesh = terrain_mesh
	terrain.material_override = _island_terrain_material()
	terrain.add_to_group("island_terrain")
	add_child(terrain)

	_visual_terrain_heights = heights
	var height_shape := HeightMapShape3D.new()
	height_shape.map_width = TERRAIN_WIDTH
	height_shape.map_depth = TERRAIN_DEPTH
	height_shape.map_data = heights
	var terrain_body := StaticBody3D.new()
	terrain_body.name = "Terrain collision"
	var collision := CollisionShape3D.new()
	collision.position = Vector3(
		(TERRAIN_MIN_X + TERRAIN_MAX_X) * 0.5,
		0.0,
		(TERRAIN_MIN_Z + TERRAIN_MAX_Z) * 0.5
	)
	collision.scale = Vector3(TERRAIN_CELL_SIZE, 1.0, TERRAIN_CELL_SIZE)
	collision.shape = height_shape
	terrain_body.add_child(collision)
	add_child(terrain_body)


func _terrain_control_at(x: float, z: float, height: float, normal: Vector3) -> Color:
	# This compact per-vertex control map follows Terrain3D's separation of
	# geometry from material intent. R marks true beach sectors, G biases
	# heather on high/exposed land, and B supplies a stable regional tint.
	var beach_region := 1.0 if _coast_is_beach(x, z) else 0.0
	var slope := 1.0 - clampf(normal.y, 0.0, 1.0)
	var heather_weight := clampf(
		smoothstep(1.4, 6.2, height) * 0.74
		+ smoothstep(0.08, 0.32, slope) * 0.32,
		0.0,
		1.0
	)
	var regional_tint := _height_noise.get_noise_2d(
		x * 0.37 + 521.0,
		z * 0.37 - 349.0
	) * 0.5 + 0.5
	return Color(beach_region, heather_weight, regional_tint, 1.0)


func _terrain_normal(x: float, z: float) -> Vector3:
	var sample := 1.0
	var left := _terrain_height_without_channels(x - sample, z)
	var right := _terrain_height_without_channels(x + sample, z)
	var north := _terrain_height_without_channels(x, z - sample)
	var south := _terrain_height_without_channels(x, z + sample)
	return Vector3(left - right, sample * 2.0, north - south).normalized()


func _terrain_height_without_channels(x: float, z: float) -> float:
	# Normals at water edges stay gentle instead of inheriting the channel wall.
	if absf(x + 73.0) < 6.2 and z > -105.0 and z < 135.0:
		return -1.75
	if absf(z + 105.0) < 7.7:
		return -2.2
	return ground_height_at(x, z)


func _make_city_roads() -> void:
	# The old city still has a few legible avenues, while the expanded outskirts
	# follow the terrain in broad curves.
	# Long east-west roads stop at the canal banks. The arched bridge meshes fill
	# the gap later, so no road ribbon is duplicated underneath a bridge.
	_make_modern_road(
		"South avenue west",
		Vector3(-114.4, 0.0, 78.0),
		Vector3(-82.0, 0.0, 78.0),
		10.0
	)
	_make_modern_road(
		"South avenue east",
		Vector3(-64.0, 0.0, 78.0),
		Vector3(110.4, 0.0, 78.0),
		10.0
	)
	_make_modern_road(
		"North quay west",
		Vector3(-152.0, 0.0, -82.0),
		Vector3(-82.0, 0.0, -82.0),
		10.0
	)
	_make_modern_road(
		"North quay east",
		Vector3(-64.0, 0.0, -82.0),
		Vector3(152.0, 0.0, -82.0),
		10.0
	)
	_make_modern_road("Garden avenue", Vector3(58.0, 0.0, -82.0), Vector3(58.0, 0.0, 78.0), 9.0)

	# The two middle crossings transition once at the old-town edge instead of
	# laying modern asphalt and cobbles over the same coordinates.
	_make_modern_road(
		"West lower connector",
		Vector3(-122.0, 0.0, -54.0),
		Vector3(-82.0, 0.0, -54.0),
		9.0
	)
	_make_modern_road(
		"West market connector",
		Vector3(-132.0, 0.0, 18.0),
		Vector3(-82.0, 0.0, 18.0),
		9.0
	)

	var south_curve_west: Array[Vector3] = [
		Vector3(-126.8, 0.0, 83.8),
		Vector3(-137.0, 0.0, 96.0),
		Vector3(-128.0, 0.0, 117.0),
		Vector3(-82.0, 0.0, 122.75),
	]
	_make_modern_path("South cycle boulevard west", south_curve_west, 9.0)
	var south_curve_east: Array[Vector3] = [
		Vector3(-64.0, 0.0, 124.0),
		Vector3(0.0, 0.0, 124.0),
		Vector3(76.0, 0.0, 119.0),
		Vector3(124.0, 0.0, 101.0),
		Vector3(119.9, 0.0, 85.3),
	]
	_make_modern_path("South cycle boulevard east", south_curve_east, 9.0)

	var east_hill_road: Array[Vector3] = [
		Vector3(123.4, 0.0, 72.6),
		Vector3(129.0, 0.0, 67.0),
		Vector3(147.0, 0.0, 38.0),
		Vector3(143.0, 0.0, 2.0),
		Vector3(128.0, 0.0, -34.0),
		Vector3(104.0, 0.0, -54.0),
	]
	_make_modern_path("Hill district cycle road", east_hill_road, 8.5)

	var orchard_road: Array[Vector3] = [
		Vector3(-127.8, 0.0, 73.3),
		Vector3(-132.0, 0.0, 70.0),
		Vector3(-150.0, 0.0, 42.0),
		Vector3(-144.0, 0.0, 4.0),
		Vector3(-126.0, 0.0, -31.0),
		Vector3(-104.0, 0.0, -54.0),
	]
	_make_modern_path("Orchard road", orchard_road, 8.0)
	_make_modern_path(
		"Meadowcroft farm lane",
		[
			Vector3(-132.0, 0.0, 70.0),
			Vector3(-120.0, 0.0, 62.0),
			Vector3(-108.0, 0.0, 57.0),
		],
		4.2
	)

	var north_bank_road: Array[Vector3] = [
		Vector3(-150.0, 0.0, -132.0),
		Vector3(-90.0, 0.0, -138.0),
		Vector3(-28.0, 0.0, -132.0),
		Vector3(38.0, 0.0, -136.0),
		Vector3(98.0, 0.0, -130.0),
		Vector3(150.0, 0.0, -121.0),
	]
	_make_modern_path("North bank promenade", north_bank_road, 9.0)

	# The promenade used to terminate abruptly at both ends. These coastal
	# sections complete one continuous island circuit by joining it to the
	# existing south boulevard on both sides.
	var west_coastal_road: Array[Vector3] = [
		Vector3(-150.0, 0.0, -132.0),
		Vector3(-180.0, 0.0, -116.0),
	]
	_make_modern_path("West coast cycle road", west_coastal_road, 8.0)
	var west_coastal_road_south: Array[Vector3] = [
		Vector3(-187.0, 0.0, -94.0),
		Vector3(-182.0, 0.0, -68.0),
		Vector3(-182.0, 0.0, -12.0),
		Vector3(-178.0, 0.0, 48.0),
		Vector3(-162.0, 0.0, 96.0),
		Vector3(-128.0, 0.0, 117.0),
	]
	_make_modern_path("West coast cycle road south", west_coastal_road_south, 8.0)
	var east_coastal_road: Array[Vector3] = [
		Vector3(150.0, 0.0, -121.0),
		Vector3(179.0, 0.0, -116.0),
	]
	_make_modern_path("East coast cycle road", east_coastal_road, 8.0)
	_make_modern_path(
		"East coast bridge continuation",
		[
			Vector3(186.0, 0.0, -94.0),
			Vector3(190.0, 0.0, -67.0),
			Vector3(191.0, 0.0, -58.0),
		],
		8.0
	)
	var east_coastal_road_south: Array[Vector3] = [
		Vector3(191.0, 0.0, -58.0),
		Vector3(191.0, 0.0, -49.0),
		Vector3(192.0, 0.0, 4.0),
		Vector3(182.0, 0.0, 64.0),
		Vector3(157.0, 0.0, 108.0),
		Vector3(124.0, 0.0, 101.0),
	]
	_make_modern_path("East coast cycle road south", east_coastal_road_south, 8.0)
	_make_modern_path(
		"West quay coastal link",
		[
			Vector3(-152.0, 0.0, -82.0),
			Vector3(-166.0, 0.0, -78.0),
			Vector3(-182.0, 0.0, -68.0),
		],
		8.0
	)
	_make_modern_path(
		"East quay coastal link",
		[
			Vector3(152.0, 0.0, -82.0),
			Vector3(170.0, 0.0, -80.0),
			Vector3(184.8, 0.0, -64.5),
			Vector3(191.0, 0.0, -58.0),
		],
		8.0
	)
	_make_modern_road(
		"Market to orchard link",
		Vector3(-132.0, 0.0, 18.0),
		Vector3(-144.0, 0.0, 4.0),
		8.0
	)

	# Medieval streets follow old property lines and terrain rather than a
	# surveyor's grid. The irregular wall loop remains fully connected while
	# bending every long sightline through the centre.
	_make_cobble_path("West old wall lane", [
		Vector3(-48.0, 0.0, -54.0),
		Vector3(-53.0, 0.0, -35.0),
		Vector3(-49.0, 0.0, -14.0),
		Vector3(-55.0, 0.0, 8.0),
		Vector3(-45.0, 0.0, 29.0),
		Vector3(-44.0, 0.0, 48.0),
	], 6.0)
	_make_cobble_path("East old wall lane", [
		Vector3(48.0, 0.0, -54.0),
		Vector3(49.0, 0.0, -37.0),
		Vector3(49.0, 0.0, -16.0),
		Vector3(49.0, 0.0, 4.0),
		Vector3(48.0, 0.0, 27.0),
		Vector3(44.0, 0.0, 48.0),
	], 6.0)
	_make_cobble_path("North old wall lane", [
		Vector3(-64.0, 0.0, -54.0),
		Vector3(-48.0, 0.0, -54.0),
		Vector3(-21.0, 0.0, -58.0),
		Vector3(8.0, 0.0, -54.0),
		Vector3(31.0, 0.0, -57.0),
		Vector3(48.0, 0.0, -54.0),
	], 6.0)
	_make_cobble_path("South old wall lane", [
		Vector3(-44.0, 0.0, 48.0),
		Vector3(-20.0, 0.0, 53.0),
		Vector3(5.0, 0.0, 49.0),
		Vector3(26.0, 0.0, 52.0),
		Vector3(44.0, 0.0, 48.0),
	], 6.0)
	_make_cobble_path("Cathedral street", [
		Vector3(5.0, 0.0, -55.0),
		Vector3(1.0, 0.0, -39.0),
		Vector3(3.0, 0.0, -24.0),
		Vector3(-2.0, 0.0, -9.0),
		Vector3(2.0, 0.0, 5.0),
		Vector3(-1.0, 0.0, 20.0),
	], 5.2)
	_make_cobble_path("Market street", [
		Vector3(-64.0, 0.0, 18.0),
		Vector3(-48.0, 0.0, 16.0),
		Vector3(-30.0, 0.0, 20.0),
		Vector3(-11.0, 0.0, 17.0),
		Vector3(8.0, 0.0, 20.0),
		Vector3(28.0, 0.0, 16.0),
		Vector3(51.0, 0.0, 18.0),
	], 6.2)
	_make_cobble_path("North market lane", [
		Vector3(-50.0, 0.0, -29.0),
		Vector3(-27.0, 0.0, -31.0),
		Vector3(-7.0, 0.0, -26.0),
		Vector3(17.0, 0.0, -30.0),
		Vector3(51.0, 0.0, -28.0),
	], 5.2)
	set_meta("old_town_curved_lane_count", 7)

	for connection in [
		[Vector3(-44.0, 0.0, 48.0), Vector3(-30.0, 0.0, 20.0)],
		[Vector3(44.0, 0.0, 48.0), Vector3(28.0, 0.0, 16.0)],
		[Vector3(-48.0, 0.0, -54.0), Vector3(-27.0, 0.0, -31.0)],
		[Vector3(48.0, 0.0, -54.0), Vector3(17.0, 0.0, -30.0)],
	]:
		_make_cobble_road("Crooked old-town lane", connection[0], connection[1], 4.6)

	# The arrival street aims directly at the medieval gate.
	_make_modern_road("Southern arrival", Vector3(0.0, 0.0, 124.0), Vector3(0.0, 0.0, 92.0), 10.0)
	_make_modern_road("Gate approach", Vector3(0.0, 0.0, 92.0), Vector3(0.0, 0.0, 50.0), 10.0)
	_make_cobble_path("Gate street", [
		Vector3(0.0, 0.0, 50.0),
		Vector3(2.0, 0.0, 35.0),
		Vector3(-1.0, 0.0, 20.0),
	], 6.0)

	_make_modern_road("Grand bridge south approach", Vector3(0.0, 0.0, -94.0), Vector3(0.0, 0.0, -82.0), 10.0)
	_make_modern_road(
		"Grand bridge north approach",
		Vector3(0.0, 0.0, -116.0),
		Vector3(-28.0, 0.0, -132.0),
		10.0,
		0.0,
		9.5
	)
	_make_modern_road("East bridge south approach", Vector3(92.0, 0.0, -94.0), Vector3(92.0, 0.0, -82.0), 9.0)
	_make_modern_road(
		"East bridge north approach",
		Vector3(92.0, 0.0, -116.0),
		Vector3(98.0, 0.0, -130.0),
		9.0,
		0.0,
		9.0
	)
	_make_modern_road(
		"Garden bridge south approach",
		Vector3(58.0, 0.0, -94.0),
		Vector3(58.0, 0.0, -82.0),
		9.0
	)
	_make_modern_road(
		"Garden bridge north approach",
		Vector3(58.0, 0.0, -116.0),
		Vector3(70.0, 0.0, -133.0),
		9.0,
		0.0,
		9.0
	)
	_make_modern_road("East hill link", Vector3(48.0, 0.0, -54.0), Vector3(104.0, 0.0, -54.0), 9.0)
	_make_road_junctions()
	if not _road_plan_only:
		_make_old_town_junction_paving()


func _make_old_town() -> void:
	var market_square := _make_terrain_polygon(
		"Market square paving",
		[
			Vector2(-20.0, -18.0),
			Vector2(-8.0, -23.0),
			Vector2(13.0, -21.0),
			Vector2(20.0, -11.0),
			Vector2(18.0, 4.0),
			Vector2(7.0, 10.0),
			Vector2(-12.0, 8.0),
			Vector2(-21.0, -2.0),
		],
		PALE_COBBLE,
		0.13
	)
	market_square.add_to_group("organic_market_square")
	for course_index in 3:
		var shift := float(course_index - 1) * 4.8
		_make_terrain_ribbon(
			"Market curved stone course %02d" % course_index,
			[
				Vector3(-17.0, 0.0, -12.0 + shift),
				Vector3(-5.0, 0.0, -15.0 + shift),
				Vector3(7.0, 0.0, -13.5 + shift),
				Vector3(16.0, 0.0, -8.0 + shift),
			],
			0.1,
			0.0,
			PALE_COBBLE.darkened(0.16),
			0.155
		)

	var north_x := [-40.0, -30.0, -20.0, -10.0, 10.0, 20.0, 30.0, 40.0]
	for index in north_x.size():
		if index not in [3, 4]:
			continue
		var north_at := Vector3(
			north_x[index] + (-3.0 if index == 3 else 1.5),
			0.0,
			-39.5 + (1.8 if index == 4 else 0.0)
		)
		_make_heritage_house(
			"North guild house %02d" % index,
			north_at,
			9.4,
			7.2 + float(index % 3) * 1.1,
			10.0,
			HERITAGE_PALETTE[index % HERITAGE_PALETTE.size()],
			-0.11 if index == 3 else 0.09
		)
		var north_house := get_node_or_null("North guild house %02d" % index)
		if north_house != null:
			north_house.add_to_group("staggered_old_town_house")

	var south_x := [-40.0, -30.0, -20.0, -10.0, 10.0, 20.0, 30.0, 40.0]
	for index in south_x.size():
		if index not in [3, 4]:
			continue
		var south_at := Vector3(
			south_x[index] + (-1.5 if index == 3 else 3.0),
			0.0,
			34.0 + (-2.5 if index == 4 else 0.0)
		)
		_make_heritage_house(
			"South guild house %02d" % index,
			south_at,
			9.4,
			6.7 + float((index + 1) % 3) * 1.1,
			10.0,
			HERITAGE_PALETTE[(index + 3) % HERITAGE_PALETTE.size()],
			PI + (-0.1 if index == 3 else 0.12)
		)
		var south_house := get_node_or_null("South guild house %02d" % index)
		if south_house != null:
			south_house.add_to_group("staggered_old_town_house")

	_make_church()
	_make_town_hall()
	_make_market_details()
	_make_medieval_gate()

	for data in [
		[Vector3(-40.5, 0.0, -15.0), PI * 0.5 - 0.1],
		[Vector3(-42.0, 0.0, -3.0), PI * 0.5 + 0.08],
		[Vector3(-39.0, 0.0, 8.5), PI * 0.5 - 0.14],
		[Vector3(40.5, 0.0, -16.5), -PI * 0.5 + 0.12],
		[Vector3(42.0, 0.0, -5.0), -PI * 0.5 - 0.08],
		[Vector3(39.5, 0.0, 6.5), -PI * 0.5 + 0.14],
	]:
		var house_index := int(absf(data[0].z))
		_make_heritage_house(
			"Close house %d" % house_index,
			data[0],
			9.8,
			7.5 + float(house_index % 2),
			9.0,
			HERITAGE_PALETTE[house_index % HERITAGE_PALETTE.size()],
			data[1]
		)
		var close_house := get_node_or_null("Close house %d" % house_index)
		if close_house != null:
			close_house.add_to_group("staggered_old_town_house")

	# Small, differently proportioned infill closes the largest leftover
	# parcels without returning to regimented terrace rows. Their slight
	# rotations follow the crooked lanes and create layered roof silhouettes
	# from every approach to the square.
	for data in [
		[
			"Weavers mews",
			Vector3(-26.0, 0.0, -46.0),
			7.2,
			6.1,
			7.0,
			Color("b99879"),
			-0.12,
		],
		[
			"Apothecary corner",
			Vector3(39.0, 0.0, -20.0),
			7.0,
			8.4,
			7.8,
			Color("a8b99a"),
			-PI * 0.5 + 0.12,
		],
		[
			"Coopers cottage",
			Vector3(-27.0, 0.0, 42.0),
			7.4,
			5.7,
			7.2,
			Color("d3b184"),
			0.11,
		],
		[
			"Bookbinders house",
			Vector3(28.0, 0.0, 41.0),
			7.2,
			7.7,
			7.0,
			Color("a7b7be"),
			-0.09,
		],
	]:
		_make_heritage_house(
			data[0],
			data[1],
			data[2],
			data[3],
			data[4],
			data[5],
			data[6]
		)
		var infill_house := get_node_or_null(data[0])
		if infill_house != null:
			infill_house.add_to_group("old_town_infill")


func _make_church() -> void:
	var church_at := Vector3(-28.0, 0.0, -7.5)
	var church_heights := _footprint_height_range(church_at, 12.0, 21.0, 0.0)
	var church_base := church_heights.y + 0.04
	var church_foundation_bottom := church_heights.x - 0.72
	var church_foundation_height := (
		church_base - church_foundation_bottom + 0.12
	)
	var church_foundation := _make_box(
		"Saint Brigid church stone foundation",
		Vector3(
			church_at.x,
			church_foundation_bottom + church_foundation_height * 0.5,
			church_at.z
		),
		Vector3(12.4, church_foundation_height, 21.4),
		DARK_STONE,
		true,
		_stone_material(DARK_STONE)
	)
	church_foundation.add_to_group("terrain_sealed_foundation")
	church_foundation.set_meta("foundation_bottom", church_foundation_bottom)
	church_foundation.set_meta("sampled_ground_minimum", church_heights.x)
	_make_rotated_box(
		"Saint Brigid church",
		Vector3(-28.0, church_base + 4.7, -7.5),
		Vector3(12.0, 9.4, 21.0),
		STONE,
		0.0,
		true,
		_stone_material(STONE)
	)
	_make_gabled_roof(
		Vector3(-28.0, church_base + 9.4, -7.5),
		12.0,
		21.0,
		0.0,
		SLATE,
		_stone_material(STONE)
	)
	# A compact twin-tower silhouette gives the square a Prague landmark
	# without copying a specific church. Unequal finials and dark slate spires
	# keep it readable from the outer cycle loop.
	for tower_index in 2:
		var tower_x := -31.25 + float(tower_index) * 6.5
		_make_box(
			"Church bell tower %02d" % tower_index,
			Vector3(tower_x, church_base + 10.5, 3.7),
			Vector3(4.5, 21.0, 5.2),
			DARK_STONE,
			true,
			_stone_material(DARK_STONE)
		)
		_make_visual_box(
			"Church tower cornice %02d" % tower_index,
			Vector3(tower_x, church_base + 19.4, 6.34),
			Vector3(5.05, 0.48, 0.38),
			Color("afa48f")
		)
		for window_y in [7.0, 12.0, 16.7]:
			_make_pointed_window(
				"Church tower lancet",
				Vector3(tower_x, church_base + window_y, 6.42),
				Vector2(0.8, 1.8 if window_y > 12.1 else 1.4),
				0.0
			)
		var spire_mesh := CylinderMesh.new()
		spire_mesh.top_radius = 0.0
		spire_mesh.bottom_radius = 2.55
		spire_mesh.height = 7.5 + float(tower_index) * 0.45
		spire_mesh.radial_segments = 4
		var spire := MeshInstance3D.new()
		spire.name = "Church spire %02d" % tower_index
		spire.position = Vector3(
			tower_x,
			church_base + 24.25 + float(tower_index) * 0.225,
			3.7
		)
		spire.mesh = spire_mesh
		spire.material_override = _roof_material(SLATE)
		add_child(spire)

	_make_box(
		"Church twin-tower central front",
		Vector3(-28.0, church_base + 7.5, 4.55),
		Vector3(2.35, 15.0, 3.55),
		DARK_STONE,
		true,
		_stone_material(DARK_STONE)
	)
	_make_pointed_window(
		"Church carved central portal",
		Vector3(-28.0, church_base + 3.2, 6.42),
		Vector2(2.7, 5.4),
		0.0
	)
	_make_pointed_window(
		"Church central tracery window",
		Vector3(-28.0, church_base + 10.6, 6.43),
		Vector2(2.2, 4.2),
		0.0
	)
	for buttress_x in [-33.9, -22.1]:
		_make_visual_box(
			"Church front buttress",
			Vector3(buttress_x, church_base + 4.2, 5.8),
			Vector3(0.7, 8.4, 1.15),
			DARK_STONE.lightened(0.04)
		)

	for z in [-12.5, -7.5, -2.5]:
		_make_visual_box(
			"Church window",
			Vector3(-21.96, church_base + 5.7, z),
			Vector3(0.1, 2.8, 1.2),
			Color("6e91a0")
		)


func _make_pointed_window(
	node_name: String,
	at: Vector3,
	size: Vector2,
	rotation_y: float
) -> void:
	var half_width := size.x * 0.5
	var shoulder_y := size.y * 0.23
	var half_height := size.y * 0.5
	var vertices := PackedVector3Array([
		Vector3(-half_width, -half_height, 0.0),
		Vector3(half_width, -half_height, 0.0),
		Vector3(half_width, shoulder_y, 0.0),
		Vector3(0.0, half_height, 0.0),
		Vector3(-half_width, shoulder_y, 0.0),
	])
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for vertex in vertices:
		normals.append(Vector3.FORWARD)
		uvs.append(Vector2(
			inverse_lerp(-half_width, half_width, vertex.x),
			1.0 - inverse_lerp(-half_height, half_height, vertex.y)
		))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 4, 4, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var window := MeshInstance3D.new()
	window.name = node_name
	window.position = at
	window.rotation.y = rotation_y
	window.mesh = mesh
	var window_material := _material(Color("3d5664"))
	window_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	window.material_override = window_material
	window.add_to_group("gothic_window")
	add_child(window)


func _make_town_hall() -> void:
	var hall_at := Vector3(29.0, 0.0, -7.5)
	var hall_heights := _footprint_height_range(hall_at, 14.0, 21.0, 0.0)
	var hall_base := hall_heights.y + 0.04
	var hall_foundation_bottom := hall_heights.x - 0.72
	var hall_foundation_height := hall_base - hall_foundation_bottom + 0.12
	var hall_foundation := _make_box(
		"Old town hall stone foundation",
		Vector3(
			hall_at.x,
			hall_foundation_bottom + hall_foundation_height * 0.5,
			hall_at.z
		),
		Vector3(14.4, hall_foundation_height, 21.4),
		DARK_STONE,
		true,
		_stone_material(DARK_STONE)
	)
	hall_foundation.add_to_group("terrain_sealed_foundation")
	hall_foundation.set_meta("foundation_bottom", hall_foundation_bottom)
	hall_foundation.set_meta("sampled_ground_minimum", hall_heights.x)
	_make_box(
		"Old town hall",
		Vector3(29.0, hall_base + 5.2, -7.5),
		Vector3(14.0, 10.4, 21.0),
		Color("c68b64"),
		true,
		_facade_material(Color("c68b64"))
	)
	_make_gabled_roof(
		Vector3(29.0, hall_base + 10.4, -7.5),
		14.0,
		21.0,
		0.0,
		TERRACOTTA,
		_facade_material(Color("c68b64"))
	)
	_make_box(
		"Town hall clock tower",
		Vector3(29.0, hall_base + 11.5, 2.0),
		Vector3(6.5, 23.0, 6.5),
		Color("b97857"),
		true,
		_facade_material(Color("b97857"))
	)
	var roof_mesh := CylinderMesh.new()
	roof_mesh.top_radius = 0.0
	roof_mesh.bottom_radius = 3.5
	roof_mesh.height = 5.0
	roof_mesh.radial_segments = 4
	var roof := MeshInstance3D.new()
	roof.name = "Town hall tower roof"
	roof.position = Vector3(29.0, hall_base + 25.5, 2.0)
	roof.mesh = roof_mesh
	roof.material_override = _roof_material(TERRACOTTA)
	add_child(roof)

	var clock := CylinderMesh.new()
	clock.top_radius = 1.15
	clock.bottom_radius = 1.15
	clock.height = 0.12
	clock.radial_segments = 24
	var clock_face := MeshInstance3D.new()
	clock_face.name = "Town hall clock"
	clock_face.position = Vector3(29.0, hall_base + 15.0, 5.28)
	clock_face.rotation_degrees.x = 90.0
	clock_face.mesh = clock
	clock_face.material_override = _material(Color("eee4c8"))
	add_child(clock_face)
	for floor_y in [2.8, 5.8, 8.6]:
		for window_z in [-14.0, -9.5, -5.0]:
			_make_visual_box(
				"Town hall window",
				Vector3(21.96, hall_base + floor_y, window_z),
				Vector3(0.1, 1.3, 1.15),
				Color("506d79")
			)
	_make_visual_box(
		"Town hall door",
		Vector3(21.94, hall_base + 1.25, 0.0),
		Vector3(0.12, 2.5, 1.5),
		Color("573c2d")
	)


func _make_market_details() -> void:
	var awning_colors := [Color("e9816d"), Color("d7b45e"), Color("6d8b75")]
	for index in [0, 2]:
		var x := -10.0 + float(index) * 10.0
		var stall_ground := ground_height_at(x, -15.5)
		_make_box(
			"Market stall %02d" % index,
			Vector3(x, stall_ground + 1.0, -15.5),
			Vector3(5.2, 2.0, 2.6),
			Color("8b633f"),
			true
		)
		_make_visual_box(
			"Market awning %02d" % index,
			Vector3(x, stall_ground + 2.25, -15.5),
			Vector3(5.8, 0.25, 3.2),
			awning_colors[index]
		)

	_make_market_fountain()


func _make_market_fountain() -> void:
	var center := Vector3(9.0, ground_height_at(9.0, -6.0), -6.0)
	var stone_material := _stone_material(Color("a69d8a"))
	var bronze_material := StandardMaterial3D.new()
	bronze_material.albedo_color = Color("4e695c")
	bronze_material.metallic = 0.72
	bronze_material.roughness = 0.36

	# A broad collision body keeps riders and pedestrians outside the pool while
	# every decorative part remains cheap visual geometry.
	var fountain := StaticBody3D.new()
	fountain.name = "Market fountain"
	fountain.position = center
	fountain.add_to_group("obstacle")
	fountain.add_to_group("city_landmark")
	var basin_collision_shape := CylinderShape3D.new()
	basin_collision_shape.radius = 3.25
	basin_collision_shape.height = 0.72
	var basin_collision := CollisionShape3D.new()
	basin_collision.position.y = 0.36
	basin_collision.shape = basin_collision_shape
	fountain.add_child(basin_collision)

	var basin_mesh := CylinderMesh.new()
	basin_mesh.top_radius = 3.15
	basin_mesh.bottom_radius = 3.38
	basin_mesh.height = 0.62
	basin_mesh.radial_segments = 40
	basin_mesh.rings = 2
	_add_visual_mesh(
		"Carved fountain basin",
		basin_mesh,
		Vector3(0.0, 0.31, 0.0),
		stone_material,
		Vector3.ZERO,
		fountain
	)
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 2.73
	rim_mesh.outer_radius = 3.35
	rim_mesh.rings = 40
	rim_mesh.ring_segments = 10
	_add_visual_mesh(
		"Fountain coping ring",
		rim_mesh,
		Vector3(0.0, 0.66, 0.0),
		stone_material,
		Vector3.ZERO,
		fountain
	)

	var pool_mesh := CylinderMesh.new()
	pool_mesh.top_radius = 2.73
	pool_mesh.bottom_radius = 2.73
	pool_mesh.height = 0.07
	pool_mesh.radial_segments = 40
	pool_mesh.rings = 2
	var pool_material := _water_material(Color("3f91aa"))
	pool_material.set_shader_parameter("wave_height", 0.045)
	pool_material.set_shader_parameter("wave_speed", 0.82)
	pool_material.set_shader_parameter("normal_strength", 1.55)
	pool_material.set_shader_parameter("foam_strength", 0.08)
	var pool := _add_visual_mesh(
		"Animated fountain water",
		pool_mesh,
		Vector3(0.0, 0.69, 0.0),
		pool_material,
		Vector3.ZERO,
		fountain
	)
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pool.add_to_group("animated_water")
	pool.add_to_group("fountain_water")

	var plinth_mesh := CylinderMesh.new()
	plinth_mesh.top_radius = 0.64
	plinth_mesh.bottom_radius = 0.82
	plinth_mesh.height = 1.28
	plinth_mesh.radial_segments = 16
	_add_visual_mesh(
		"Courier statue plinth",
		plinth_mesh,
		Vector3(0.0, 1.22, 0.0),
		stone_material,
		Vector3.ZERO,
		fountain
	)
	_make_courier_statue(fountain, bronze_material)

	var jet_material := StandardMaterial3D.new()
	jet_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	jet_material.albedo_color = Color(0.53, 0.9, 1.0, 0.82)
	jet_material.emission_enabled = true
	jet_material.emission = Color("80d8e8")
	jet_material.emission_energy_multiplier = 0.36
	jet_material.roughness = 0.12
	for spout_index in 4:
		var angle := TAU * float(spout_index) / 4.0 + PI * 0.25
		var radial := Vector3(cos(angle), 0.0, sin(angle))
		_make_fountain_spout_statue(fountain, radial, bronze_material)
		_make_fountain_jet(
			fountain,
			"Fountain jet %02d" % spout_index,
			radial * 2.36 + Vector3.UP * 1.22,
			radial * 0.62 + Vector3.UP * 0.73,
			jet_material
		)

	add_child(fountain)


func _make_courier_statue(parent: Node3D, bronze_material: Material) -> void:
	var torso := CapsuleMesh.new()
	torso.radius = 0.3
	torso.height = 1.18
	torso.radial_segments = 10
	torso.rings = 4
	_add_visual_mesh(
		"Bronze courier",
		torso,
		Vector3(0.0, 2.48, 0.0),
		bronze_material,
		Vector3.ZERO,
		parent
	)
	var head := SphereMesh.new()
	head.radius = 0.27
	head.height = 0.54
	head.radial_segments = 10
	head.rings = 5
	_add_visual_mesh(
		"Bronze courier head",
		head,
		Vector3(0.0, 3.3, 0.0),
		bronze_material,
		Vector3.ZERO,
		parent
	)
	var backpack := BoxMesh.new()
	backpack.size = Vector3(0.62, 0.72, 0.28)
	_add_visual_mesh(
		"Bronze delivery pack",
		backpack,
		Vector3(0.0, 2.58, -0.3),
		bronze_material,
		Vector3.ZERO,
		parent
	)
	for leg_x in [-0.16, 0.16]:
		var leg := CylinderMesh.new()
		leg.top_radius = 0.11
		leg.bottom_radius = 0.12
		leg.height = 0.82
		leg.radial_segments = 8
		_add_visual_mesh(
			"Bronze courier leg",
			leg,
			Vector3(leg_x, 1.74, 0.0),
			bronze_material,
			Vector3(0.0, 0.0, leg_x * 0.5),
			parent
		)

	# The wheel makes the silhouette legible as a courier monument even from
	# the far side of the square.
	var wheel := TorusMesh.new()
	wheel.inner_radius = 0.49
	wheel.outer_radius = 0.59
	wheel.rings = 20
	wheel.ring_segments = 7
	_add_visual_mesh(
		"Bronze bicycle wheel",
		wheel,
		Vector3(0.72, 2.12, 0.02),
		bronze_material,
		Vector3(PI * 0.5, 0.0, 0.0),
		parent
	)
	for spoke_angle in [0.0, PI * 0.25, PI * 0.5, PI * 0.75]:
		var spoke := BoxMesh.new()
		spoke.size = Vector3(1.02, 0.035, 0.035)
		_add_visual_mesh(
			"Bronze wheel spoke",
			spoke,
			Vector3(0.72, 2.12, 0.02),
			bronze_material,
			Vector3(0.0, 0.0, spoke_angle),
			parent
		)


func _make_fountain_spout_statue(
	parent: Node3D,
	radial: Vector3,
	bronze_material: Material
) -> void:
	var head := SphereMesh.new()
	head.radius = 0.23
	head.height = 0.42
	head.radial_segments = 8
	head.rings = 4
	_add_visual_mesh(
		"Bronze harbour bird spout",
		head,
		radial * 2.42 + Vector3.UP * 1.1,
		bronze_material,
		Vector3.ZERO,
		parent
	)
	var beak := CylinderMesh.new()
	beak.top_radius = 0.0
	beak.bottom_radius = 0.13
	beak.height = 0.42
	beak.radial_segments = 8
	var beak_rotation := Vector3(
		PI * 0.5,
		atan2(-radial.x, -radial.z),
		0.0
	)
	_add_visual_mesh(
		"Bronze harbour bird beak",
		beak,
		radial * 2.22 + Vector3.UP * 1.14,
		bronze_material,
		beak_rotation,
		parent
	)


func _make_fountain_jet(
	parent: Node3D,
	node_name: String,
	from: Vector3,
	to: Vector3,
	material: Material
) -> void:
	var path_segments := 12
	var radial_segments := 5
	var radius := 0.035
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for path_index in path_segments + 1:
		var weight := float(path_index) / float(path_segments)
		var center := from.lerp(to, weight)
		center.y += sin(weight * PI) * 0.92
		var tangent := (to - from).normalized()
		tangent.y += cos(weight * PI) * 1.45
		tangent = tangent.normalized()
		var side := tangent.cross(Vector3.UP).normalized()
		if side.length_squared() < 0.01:
			side = Vector3.RIGHT
		var ring_up := side.cross(tangent).normalized()
		for radial_index in radial_segments:
			var angle := TAU * float(radial_index) / float(radial_segments)
			var normal := side * cos(angle) + ring_up * sin(angle)
			vertices.append(center + normal * radius)
			normals.append(normal)
			uvs.append(Vector2(weight, float(radial_index) / float(radial_segments)))
	for path_index in path_segments:
		for radial_index in radial_segments:
			var following := (radial_index + 1) % radial_segments
			var current := path_index * radial_segments + radial_index
			var next_ring := (path_index + 1) * radial_segments + radial_index
			var next_ring_following := (path_index + 1) * radial_segments + following
			var current_following := path_index * radial_segments + following
			indices.append_array(PackedInt32Array([
				current,
				next_ring,
				current_following,
				current_following,
				next_ring,
				next_ring_following,
			]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var jet := _add_visual_mesh(node_name, mesh, Vector3.ZERO, material, Vector3.ZERO, parent)
	jet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	jet.add_to_group("fountain_water")


func _add_visual_mesh(
	node_name: String,
	mesh: Mesh,
	at: Vector3,
	material: Material,
	rotation: Vector3,
	parent: Node3D
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.rotation = rotation
	instance.mesh = mesh
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _make_medieval_gate() -> void:
	var gate_ground := ground_height_at(0.0, 47.0)
	for x in [-8.5, 8.5]:
		_make_box(
			"South gate tower",
			Vector3(x, gate_ground + 5.5, 47.0),
			Vector3(6.0, 11.0, 7.0),
			DARK_STONE,
			true,
			_stone_material(DARK_STONE)
		)
		var roof_mesh := CylinderMesh.new()
		roof_mesh.top_radius = 2.4
		roof_mesh.bottom_radius = 3.5
		roof_mesh.height = 2.5
		roof_mesh.radial_segments = 12
		var roof := MeshInstance3D.new()
		roof.position = Vector3(x, gate_ground + 12.0, 47.0)
		roof.mesh = roof_mesh
		roof.material_override = _roof_material(SLATE)
		add_child(roof)
		for window_y in [4.0, 7.0]:
			_make_visual_box(
				"Gate tower window",
				Vector3(x, gate_ground + window_y, 50.53),
				Vector3(1.0, 1.25, 0.1),
				Color("40535b")
			)
	_make_box(
		"South gate arch",
		Vector3(0.0, gate_ground + 9.2, 47.0),
		Vector3(9.0, 2.2, 3.0),
		DARK_STONE,
		true,
		_stone_material(DARK_STONE)
	)


func _make_south_quarter() -> void:
	_make_heritage_house(
		"Boulangerie du Pont",
		Vector3(-58.0, 0.0, 29.5),
		9.5,
		6.4,
		8.0,
		Color("f9d88d"),
		PI
	)
	var row_x := [-50.0, -40.0, -30.0, -20.0, -12.0, 12.0, 20.0, 30.0, 40.0, 50.0]
	for index in row_x.size():
		if index == row_x.size() - 1:
			continue
		_make_heritage_house(
			"South avenue terrace %02d" % index,
			Vector3(row_x[index], 0.0, 65.0),
			9.5,
			6.3 + float(index % 3) * 0.9,
			10.0,
			HERITAGE_PALETTE[(index + 2) % HERITAGE_PALETTE.size()],
			0.0
		)
	for index in range(1, row_x.size() - 1):
		if absf(row_x[index]) < 15.0:
			continue
		_make_heritage_house(
			"Southern terrace %02d" % index,
			Vector3(row_x[index], 0.0, 89.0),
			9.5,
			5.8 + float(index % 2) * 0.8,
			9.0,
			HERITAGE_PALETTE[(index + 5) % HERITAGE_PALETTE.size()],
			PI
		)


func _make_east_quarter() -> void:
	var garden_villa_z := [-68.0, -40.0, -8.0, 52.0, 66.0]
	for index in garden_villa_z.size():
		_make_heritage_house(
			"Garden district villa %02d" % index,
			Vector3(74.0, 0.0, garden_villa_z[index]),
			12.0,
			6.0 + float(index % 2) * 1.2,
			14.0,
			HERITAGE_PALETTE[(index + 1) % HERITAGE_PALETTE.size()],
			PI * 0.5
		)

	var university_row_z := [-68.0, -41.0, -8.0, 39.0, 58.0]
	for index in university_row_z.size():
		_make_heritage_house(
			"University row %02d" % index,
			Vector3(91.0, 0.0, university_row_z[index]),
			10.5,
			7.0 + float(index % 3),
			11.0,
			HERITAGE_PALETTE[(index + 4) % HERITAGE_PALETTE.size()],
			-PI * 0.5
		)


func _make_west_bank() -> void:
	for index in 7:
		var z := -68.0 + float(index) * 22.0
		if (z > -65.0 and z < -42.0) or absf(z - 20.0) < 1.0:
			continue
		_make_heritage_house(
			"Canal house %02d" % index,
			Vector3(-84.0, 0.0, z),
			10.0,
			6.0 + float(index % 3),
			9.0,
			HERITAGE_PALETTE[(index + 3) % HERITAGE_PALETTE.size()],
			PI * 0.5
		)

	_make_box(
		"Old canal mill",
		Vector3(-84.0, 4.5, -40.0),
		Vector3(9.0, 9.0, 14.0),
		Color("a66f51"),
		true,
		_facade_material(Color("a66f51"))
	)
	_make_gabled_roof(
		Vector3(-84.0, 9.0, -40.0),
		9.0,
		14.0,
		0.0,
		TERRACOTTA,
		_facade_material(Color("a66f51"))
	)
	_make_mill_wheel(Vector3(-79.28, 1.35, -43.1))
	_make_water_wheel_splash(Vector3(-78.96, WATER_LEVEL + 0.1, -43.1))
	_make_mill_gable_vent(Vector3(-79.47, 10.35, -40.0))
	for window_y in [2.5, 5.4, 7.5]:
		for window_z in [-44.0, -40.0, -36.0]:
			if window_y < 4.0 and absf(window_z + 43.1) < 3.2:
				continue
			_heritage_window_transforms.append(Transform3D(
				Basis(Vector3.UP, PI * 0.5),
				Vector3(-79.46, window_y, window_z)
			))


func _make_mill_wheel(at: Vector3) -> void:
	var mount := Node3D.new()
	mount.name = "Mill wheel"
	mount.position = at
	mount.rotation_degrees.z = 90.0
	add_child(mount)

	_mill_wheel_rotator = Node3D.new()
	_mill_wheel_rotator.name = "Rotating timber wheel"
	mount.add_child(_mill_wheel_rotator)

	var timber := _material(Color("67462f"))
	var iron := _material(Color("2d3639"))
	iron.metallic = 0.55
	iron.roughness = 0.42

	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 2.0
	rim_mesh.outer_radius = 2.3
	rim_mesh.rings = 32
	rim_mesh.ring_segments = 12
	var rim := MeshInstance3D.new()
	rim.name = "Timber rim"
	rim.mesh = rim_mesh
	rim.material_override = timber
	_mill_wheel_rotator.add_child(rim)

	for angle_index in 4:
		var spoke_mesh := BoxMesh.new()
		spoke_mesh.size = Vector3(4.05, 0.12, 0.14)
		var spoke := MeshInstance3D.new()
		spoke.name = "Cross spoke %02d" % angle_index
		spoke.rotation.y = float(angle_index) * PI * 0.25
		spoke.mesh = spoke_mesh
		spoke.material_override = _material(Color("765239"))
		_mill_wheel_rotator.add_child(spoke)

	for paddle_index in 12:
		var angle := float(paddle_index) * TAU / 12.0
		var paddle_mesh := BoxMesh.new()
		paddle_mesh.size = Vector3(0.55, 0.3, 0.2)
		var paddle := MeshInstance3D.new()
		paddle.name = "Water paddle %02d" % paddle_index
		paddle.position = Vector3(cos(angle) * 2.3, 0.0, sin(angle) * 2.3)
		paddle.rotation.y = -angle - PI * 0.5
		paddle.mesh = paddle_mesh
		paddle.material_override = _material(Color("5d3d2a"))
		_mill_wheel_rotator.add_child(paddle)

	var hub_mesh := CylinderMesh.new()
	hub_mesh.top_radius = 0.38
	hub_mesh.bottom_radius = 0.38
	hub_mesh.height = 0.52
	hub_mesh.radial_segments = 16
	var hub := MeshInstance3D.new()
	hub.name = "Iron hub"
	hub.mesh = hub_mesh
	hub.material_override = iron
	_mill_wheel_rotator.add_child(hub)


func _make_water_wheel_splash(at: Vector3) -> void:
	var foam_material := StandardMaterial3D.new()
	foam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	foam_material.albedo_color = Color(0.76, 0.92, 0.94, 0.72)
	foam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var foam_mesh := SphereMesh.new()
	foam_mesh.radius = 0.085
	foam_mesh.height = 0.17
	foam_mesh.material = foam_material

	var process_material := ParticleProcessMaterial.new()
	process_material.direction = Vector3(-0.18, 1.0, 0.0)
	process_material.spread = 42.0
	process_material.initial_velocity_min = 0.45
	process_material.initial_velocity_max = 1.25
	process_material.gravity = Vector3(0.0, -2.6, 0.0)
	process_material.scale_min = 0.45
	process_material.scale_max = 1.2

	var splash := GPUParticles3D.new()
	splash.name = "Mill race spray"
	splash.position = at
	splash.amount = 28
	splash.lifetime = 1.25
	splash.randomness = 0.68
	splash.process_material = process_material
	splash.draw_pass_1 = foam_mesh
	splash.visibility_aabb = AABB(
		Vector3(-2.5, -1.0, -2.5),
		Vector3(5.0, 4.0, 5.0)
	)
	splash.add_to_group("mill_water_splash")
	add_child(splash)


func _make_mill_gable_vent(at: Vector3) -> void:
	var surround_mesh := CylinderMesh.new()
	surround_mesh.top_radius = 0.82
	surround_mesh.bottom_radius = 0.82
	surround_mesh.height = 0.16
	surround_mesh.radial_segments = 24
	var surround := MeshInstance3D.new()
	surround.name = "Mill gable vent surround"
	surround.position = at
	surround.rotation_degrees.z = 90.0
	surround.mesh = surround_mesh
	surround.material_override = _stone_material(Color("695c4e"))
	surround.add_to_group("heritage_architecture_detail")
	add_child(surround)

	var inset_mesh := CylinderMesh.new()
	inset_mesh.top_radius = 0.61
	inset_mesh.bottom_radius = 0.61
	inset_mesh.height = 0.18
	inset_mesh.radial_segments = 24
	var inset := MeshInstance3D.new()
	inset.name = "Recessed mill gable vent"
	inset.position = at + Vector3(0.02, 0.0, 0.0)
	inset.rotation_degrees.z = 90.0
	inset.mesh = inset_mesh
	inset.material_override = _material(Color("354248"))
	add_child(inset)

	for slat_index in 4:
		_make_visual_box(
			"Mill vent louvre %02d" % slat_index,
			at + Vector3(0.13, 0.32 - float(slat_index) * 0.21, 0.0),
			Vector3(0.12, 0.075, 1.05),
			Color("8b755d")
		)


func _make_gardens() -> void:
	_make_visual_box(
		"Abbey garden lawn",
		Vector3(74.0, 0.07, 21.0),
		Vector3(25.0, 0.12, 46.0),
		GARDEN_GRASS
	)
	_make_visual_box(
		"Abbey garden path",
		Vector3(74.0, 0.14, 21.0),
		Vector3(3.0, 0.05, 43.0),
		Color("c8b990")
	)
	var garden_trees := [
		Vector3(67.0, 0.0, 3.0),
		Vector3(81.0, 0.0, 5.0),
		Vector3(68.0, 0.0, 17.0),
		Vector3(81.0, 0.0, 25.0),
		Vector3(67.0, 0.0, 38.0),
		Vector3(81.0, 0.0, 41.0),
		Vector3(-60.0, 0.0, 60.0),
		Vector3(-56.0, 0.0, -68.0),
	]
	for index in garden_trees.size():
		if index in [1, 3, 4]:
			_make_cherry_tree(garden_trees[index])
		else:
			_make_tree(garden_trees[index])


func _make_north_bank() -> void:
	_make_heritage_house(
		"Quayside pizzeria",
		Vector3(28.0, 0.0, -68.0),
		12.0,
		6.6,
		8.0,
		Color("f4be62"),
		PI
	)
	_make_heritage_house(
		"North Bank sushi",
		Vector3(-28.0, 0.0, -149.0),
		12.5,
		6.8,
		10.0,
		Color("77bad3"),
		0.0
	)
	var north_row_x := [-148.0, -134.0, -120.0, -106.0, -76.0, -60.0, -44.0, -14.0, 16.0, 34.0, 52.0, 70.0, 112.0, 130.0, 148.0]
	for index in north_row_x.size():
		_make_heritage_house(
			"North bank terrace %02d" % index,
			Vector3(north_row_x[index], 0.0, -149.0),
			12.5,
			6.2 + float(index % 3) * 0.9,
			10.0,
			HERITAGE_PALETTE[(index + 2) % HERITAGE_PALETTE.size()],
			0.0
		)

	for data in [
		[Vector3(-120.0, 0.0, -119.0), PI],
		[Vector3(-103.0, 0.0, -121.0), PI],
		[Vector3(-46.0, 0.0, -120.0), PI],
		[Vector3(26.0, 0.0, -120.0), PI],
		[Vector3(48.0, 0.0, -119.0), PI],
	]:
		var index := int(absf(data[0].x + data[0].z))
		_make_heritage_house(
			"River close house %03d" % index,
			data[0],
			13.0,
			6.5 + float(index % 2),
			10.0,
			HERITAGE_PALETTE[index % HERITAGE_PALETTE.size()],
			data[1]
		)


func _make_hill_village() -> void:
	var hill_houses: Array[Dictionary] = [
		{"at": Vector3(90.0, 0.0, 96.0), "rotation": -0.22},
		{"at": Vector3(140.0, 0.0, 82.0), "rotation": -0.62},
		{"at": Vector3(160.0, 0.0, 56.0), "rotation": -1.1},
		{"at": Vector3(163.0, 0.0, 20.0), "rotation": -1.42},
		{"at": Vector3(158.0, 0.0, -10.0), "rotation": -1.8},
		{"at": Vector3(137.0, 0.0, -46.0), "rotation": -2.2},
	]
	for index in hill_houses.size():
		var house: Dictionary = hill_houses[index]
		_make_heritage_house(
			"Hill village house %02d" % index,
			house.at,
			12.0,
			6.0 + float(index % 3),
			10.0,
			HERITAGE_PALETTE[(index + 4) % HERITAGE_PALETTE.size()],
			float(house.rotation)
		)

	for tree_position in [
		Vector3(112.0, 0.0, 104.0),
		Vector3(135.0, 0.0, 94.0),
		Vector3(153.0, 0.0, 69.0),
		Vector3(158.0, 0.0, 2.0),
		Vector3(142.0, 0.0, -28.0),
	]:
		_make_tree(tree_position)


func _make_orchard_outskirts() -> void:
	_make_heritage_house(
		"Orchard farm shop",
		Vector3(-151.0, 0.0, 70.0),
		11.0,
		5.8,
		10.0,
		Color("7ec9b1"),
		PI * 0.5
	)
	var cottage_x := [-162.0, -164.0, -164.0, -164.0, -162.0]
	for index in 5:
		var z := 94.0 - float(index) * 27.0
		_make_heritage_house(
			"Orchard cottage %02d" % index,
			Vector3(cottage_x[index], 0.0, z),
			11.0,
			5.5 + float(index % 2),
			10.0,
			HERITAGE_PALETTE[(index + 1) % HERITAGE_PALETTE.size()],
			PI * 0.5 + float(index) * 0.08
		)
	_make_meadowcroft_farm()
	for x in [-160.0, -144.0, -128.0, -112.0]:
		for z in [-66.0, -34.0, -2.0, 30.0, 62.0, 104.0]:
			if x == -112.0 and z in [30.0, 62.0]:
				continue
			_make_tree(Vector3(x, 0.0, z))


func _make_meadowcroft_farm() -> void:
	_make_heritage_house(
		"Meadowcroft farmhouse",
		Vector3(-95.0, 0.0, 66.0),
		12.5,
		6.4,
		9.5,
		Color("d6c79e"),
		PI
	)
	var farmhouse := get_node_or_null("Meadowcroft farmhouse")
	if farmhouse != null:
		farmhouse.add_to_group("farm_landmark")

	var barn_at := Vector3(-114.0, 0.0, 39.0)
	var barn_width := 13.5
	var barn_height := 6.2
	var barn_depth := 10.5
	var height_range := _footprint_height_range(
		barn_at,
		barn_width,
		barn_depth,
		0.0
	)
	var barn_base_y := height_range.y + 0.04
	var foundation_bottom := height_range.x - 0.64
	var foundation_height := barn_base_y - foundation_bottom + 0.12
	var foundation := _make_rotated_box(
		"Meadowcroft barn stone foundation",
		Vector3(
			barn_at.x,
			foundation_bottom + foundation_height * 0.5,
			barn_at.z
		),
		Vector3(barn_width + 0.3, foundation_height, barn_depth + 0.3),
		DARK_STONE,
		0.0,
		true,
		_stone_material(DARK_STONE)
	)
	foundation.add_to_group("terrain_sealed_foundation")
	foundation.set_meta("foundation_bottom", foundation_bottom)
	foundation.set_meta("sampled_ground_minimum", height_range.x)
	var barn := _make_rotated_box(
		"Meadowcroft barn",
		Vector3(barn_at.x, barn_base_y + barn_height * 0.5, barn_at.z),
		Vector3(barn_width, barn_height, barn_depth),
		Color("8d4234"),
		0.0,
		true,
		_facade_material(Color("8d4234"))
	)
	barn.add_to_group("farm_landmark")
	_make_gabled_roof(
		Vector3(barn_at.x, barn_base_y + barn_height, barn_at.z),
		barn_width,
		barn_depth,
		0.0,
		SLATE,
		_facade_material(Color("8d4234")),
		42.0
	)
	var door_material := _material(Color("4d3025"))
	for side in [-1.0, 1.0]:
		_make_visual_box(
			"Barn door",
			Vector3(
				barn_at.x + side * 2.15,
				barn_base_y + 2.15,
				barn_at.z + barn_depth * 0.5 + 0.07
			),
			Vector3(4.05, 4.3, 0.12),
			Color("4d3025")
		).material_override = door_material
	var loft_door := _make_visual_box(
		"Barn loft door",
		Vector3(
			barn_at.x,
			barn_base_y + 5.25,
			barn_at.z + barn_depth * 0.5 + 0.09
		),
		Vector3(2.2, 1.55, 0.13),
		Color("36241d")
	)
	loft_door.add_to_group("farm_landmark")

	# The pasture remains east of the barn and south of the access lane. Its
	# open western gate faces the yard rather than a public road.
	_make_farm_fence_line(Vector3(-136.0, 0.0, 26.0), Vector3(-104.0, 0.0, 26.0))
	_make_farm_fence_line(Vector3(-136.0, 0.0, 26.0), Vector3(-136.0, 0.0, 54.0))
	_make_farm_fence_line(Vector3(-136.0, 0.0, 54.0), Vector3(-104.0, 0.0, 54.0))
	_make_farm_fence_line(Vector3(-104.0, 0.0, 26.0), Vector3(-104.0, 0.0, 44.5))
	_make_farm_fence_line(Vector3(-104.0, 0.0, 49.0), Vector3(-104.0, 0.0, 54.0))
	_make_farm_pond(Vector3(-128.0, 0.0, 48.0))
	_make_farmyard_details(Vector3(-107.0, 0.0, 52.0))
	_make_farm_sign(Vector3(-105.0, 0.0, 60.0))


func _make_farm_fence_line(from: Vector3, to: Vector3) -> void:
	var distance := from.distance_to(to)
	var sections := maxi(1, int(ceil(distance / 3.0)))
	var post_material := _material(Color("725039"))
	for index in sections + 1:
		var point := from.lerp(to, float(index) / float(sections))
		point.y = ground_height_at(point.x, point.z)
		var post := _make_box(
			"Meadowcroft fence post",
			point + Vector3.UP * 0.68,
			Vector3(0.18, 1.36, 0.18),
			Color("725039"),
			false,
			post_material
		)
		post.add_to_group("farm_fence")
	for index in sections:
		var section_from := from.lerp(to, float(index) / float(sections))
		var section_to := from.lerp(to, float(index + 1) / float(sections))
		section_from.y = ground_height_at(section_from.x, section_from.z)
		section_to.y = ground_height_at(section_to.x, section_to.z)
		for rail_height in [0.46, 1.02]:
			var rail := _make_ridable_surface_segment(
				"Meadowcroft fence rail",
				section_from + Vector3.UP * rail_height,
				section_to + Vector3.UP * rail_height,
				0.13,
				0.13,
				Color("725039"),
				true
			)
			rail.add_to_group("farm_fence")


func _make_farm_pond(at: Vector3) -> void:
	var pond_mesh := CylinderMesh.new()
	pond_mesh.top_radius = 1.0
	pond_mesh.bottom_radius = 1.0
	pond_mesh.height = 0.08
	pond_mesh.radial_segments = 24
	var pond := MeshInstance3D.new()
	pond.name = "Meadowcroft goose pond"
	pond.position = Vector3(at.x, ground_height_at(at.x, at.z) + 0.035, at.z)
	pond.scale = Vector3(4.2, 1.0, 2.6)
	pond.mesh = pond_mesh
	var pond_material := _material(Color("4c91a1"))
	pond_material.metallic = 0.18
	pond_material.roughness = 0.24
	pond.material_override = pond_material
	pond.add_to_group("farm_pond")
	pond.add_to_group("farm_landmark")
	add_child(pond)


func _make_farmyard_details(at: Vector3) -> void:
	var ground := ground_height_at(at.x, at.z)
	for index in 3:
		var bale_mesh := CylinderMesh.new()
		bale_mesh.top_radius = 0.72
		bale_mesh.bottom_radius = 0.72
		bale_mesh.height = 1.15
		bale_mesh.radial_segments = 12
		var bale := MeshInstance3D.new()
		bale.name = "Hay bale %02d" % index
		bale.position = Vector3(
			at.x + float(index % 2) * 1.35,
			ground + 0.72 + float(index / 2) * 1.0,
			at.z + float(index % 2) * 0.3
		)
		bale.rotation_degrees.z = 90.0
		bale.mesh = bale_mesh
		bale.material_override = _material(Color("b89643"))
		bale.add_to_group("farm_landmark")
		add_child(bale)
	var trough := _make_box(
		"Meadowcroft animal trough",
		Vector3(-122.0, ground_height_at(-122.0, 50.0) + 0.35, 50.0),
		Vector3(2.6, 0.7, 0.8),
		Color("625042"),
		true
	)
	trough.add_to_group("farm_landmark")


func _make_farm_sign(at: Vector3) -> void:
	var sign := Node3D.new()
	sign.name = "Meadowcroft Farm sign"
	sign.position = Vector3(at.x, ground_height_at(at.x, at.z), at.z)
	sign.rotation.y = -1.18
	sign.add_to_group("farm_landmark")
	add_child(sign)
	var timber := _material(Color("62412d"))
	for x in [-1.45, 1.45]:
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.16, 1.75, 0.16)
		var post := MeshInstance3D.new()
		post.position = Vector3(x, 0.88, 0.0)
		post.mesh = post_mesh
		post.material_override = timber
		sign.add_child(post)
	var board_mesh := BoxMesh.new()
	board_mesh.size = Vector3(3.8, 1.08, 0.18)
	var board := MeshInstance3D.new()
	board.position = Vector3(0.0, 1.65, 0.0)
	board.mesh = board_mesh
	board.material_override = timber
	sign.add_child(board)
	var label := Label3D.new()
	label.name = "Farm name"
	label.position = Vector3(0.0, 1.65, 0.1)
	label.text = "MEADOWCROFT FARM"
	label.font_size = 42
	label.pixel_size = 0.004
	label.modulate = Color("f2dfaa")
	label.outline_modulate = Color("34251d")
	label.outline_size = 9
	sign.add_child(label)


func _make_coastal_landmarks() -> void:
	# Angular dark outcrops reinforce the steep sectors generated by the
	# terrain, while the southern and north-western bays remain open beaches.
	var rock_data := [
		[Vector3(-154.0, 0.0, -192.0), Vector3(5.8, 7.4, 5.0)],
		[Vector3(-126.0, 0.0, -202.0), Vector3(4.2, 6.0, 4.6)],
		[Vector3(-96.0, 0.0, -207.0), Vector3(6.5, 8.2, 5.2)],
		[Vector3(86.0, 0.0, -207.0), Vector3(5.2, 7.0, 4.4)],
		[Vector3(119.0, 0.0, -201.0), Vector3(6.8, 9.0, 5.6)],
		[Vector3(151.0, 0.0, -190.0), Vector3(4.8, 6.5, 4.2)],
		[Vector3(205.0, 0.0, -126.0), Vector3(5.6, 8.2, 4.8)],
		[Vector3(213.0, 0.0, -92.0), Vector3(4.4, 6.8, 4.0)],
		[Vector3(216.0, 0.0, -54.0), Vector3(6.2, 9.5, 5.2)],
		[Vector3(218.0, 0.0, -12.0), Vector3(4.7, 7.2, 4.0)],
		[Vector3(215.0, 0.0, 32.0), Vector3(6.0, 8.8, 5.0)],
		[Vector3(207.0, 0.0, 78.0), Vector3(4.6, 6.4, 4.0)],
		[Vector3(191.0, 0.0, 125.0), Vector3(6.4, 8.0, 5.6)],
		[Vector3(155.0, 0.0, 157.0), Vector3(4.8, 6.2, 4.2)],
		[Vector3(-171.0, 0.0, 157.0), Vector3(5.5, 7.4, 4.8)],
	]
	for index in rock_data.size():
		var at: Vector3 = rock_data[index][0]
		var size: Vector3 = rock_data[index][1]
		var ground := ground_height_at(at.x, at.z)
		var rock_base := maxf(ground, WATER_LEVEL - size.y * 0.28)
		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 2.0
		mesh.radial_segments = 7
		mesh.rings = 4
		var rock := MeshInstance3D.new()
		rock.name = "Coastal cliff outcrop %02d" % index
		rock.position = Vector3(at.x, rock_base + size.y * 0.42, at.z)
		rock.rotation_degrees = Vector3(
			float((index * 7) % 13) - 6.0,
			float(index * 41),
			float((index * 11) % 15) - 7.0
		)
		rock.scale = Vector3(size.x * 0.5, size.y * 0.5, size.z * 0.5)
		rock.mesh = mesh
		rock.material_override = _material(
			Color("444a45").lightened(float(index % 3) * 0.04)
		)
		rock.add_to_group("coastal_cliff_rock")
		add_child(rock)
	_make_lighthouse(Vector2(165.0, -155.0))


func _make_lighthouse(coast_position: Vector2) -> void:
	var ground := ground_height_at(coast_position.x, coast_position.y)
	var lighthouse := StaticBody3D.new()
	lighthouse.name = "Saint Brigid lighthouse"
	lighthouse.position = Vector3(coast_position.x, ground, coast_position.y)
	lighthouse.add_to_group("obstacle")
	lighthouse.add_to_group("city_landmark")
	lighthouse.add_to_group("coastal_lighthouse")
	add_child(lighthouse)
	# Keep the cliff-top landmark readable instead of burying its base in the
	# procedural foliage pass that follows coastal landmark construction.
	_obstacle_clearings.append(Vector3(coast_position.x, coast_position.y, 7.5))

	var tower_collision_shape := CylinderShape3D.new()
	tower_collision_shape.radius = 2.2
	tower_collision_shape.height = 15.0
	var tower_collision := CollisionShape3D.new()
	tower_collision.position.y = 7.5
	tower_collision.shape = tower_collision_shape
	lighthouse.add_child(tower_collision)

	var stone_material := _stone_material(Color("6f716c"))
	var white_plaster := _facade_material(Color("ddd8c7"))
	var red_plaster := _facade_material(Color("9b4039"))
	var iron_material := _material(Color("252d31"))
	iron_material.metallic = 0.42
	iron_material.roughness = 0.48

	_add_lighthouse_cylinder(
		lighthouse,
		"Octagonal stone lighthouse footing",
		Vector3(0.0, 0.6, 0.0),
		2.72,
		2.9,
		1.2,
		stone_material,
		12
	)
	_add_lighthouse_cylinder(
		lighthouse,
		"Weathered white lighthouse tower",
		Vector3(0.0, 7.65, 0.0),
		1.42,
		2.25,
		14.2,
		white_plaster,
		18
	)
	_add_lighthouse_cylinder(
		lighthouse,
		"Red lighthouse daymark band",
		Vector3(0.0, 7.05, 0.0),
		1.78,
		1.98,
		3.15,
		red_plaster,
		18
	)
	_add_lighthouse_cylinder(
		lighthouse,
		"Lantern gallery platform",
		Vector3(0.0, 14.92, 0.0),
		2.28,
		2.28,
		0.38,
		iron_material,
		24
	)

	var gallery_rail := TorusMesh.new()
	gallery_rail.inner_radius = 1.93
	gallery_rail.outer_radius = 2.08
	gallery_rail.rings = 28
	gallery_rail.ring_segments = 8
	_add_visual_mesh(
		"Lantern gallery handrail",
		gallery_rail,
		Vector3(0.0, 16.0, 0.0),
		iron_material,
		Vector3.ZERO,
		lighthouse
	)
	for rail_index in 12:
		var rail_angle := TAU * float(rail_index) / 12.0
		_add_lighthouse_cylinder(
			lighthouse,
			"Gallery rail post %02d" % rail_index,
			Vector3(cos(rail_angle) * 2.0, 15.52, sin(rail_angle) * 2.0),
			0.055,
			0.055,
			0.92,
			iron_material,
			6
		)

	_lighthouse_lantern_material = _material(Color("766b56"))
	_lighthouse_lantern_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_lighthouse_lantern_material.albedo_color = Color(0.68, 0.78, 0.75, 0.46)
	_lighthouse_lantern_material.emission_enabled = true
	_lighthouse_lantern_material.emission = Color("ffe0a0")
	_lighthouse_lantern_material.emission_energy_multiplier = 0.0
	_lighthouse_lantern_material.roughness = 0.12
	var lantern_glass := _add_lighthouse_cylinder(
		lighthouse,
		"Glazed lighthouse lantern room",
		Vector3(0.0, 16.1, 0.0),
		1.31,
		1.31,
		1.85,
		_lighthouse_lantern_material,
		16
	)
	lantern_glass.add_to_group("lighthouse_lantern")
	for column_index in 8:
		var column_angle := TAU * float(column_index) / 8.0
		_add_lighthouse_cylinder(
			lighthouse,
			"Lantern mullion %02d" % column_index,
			Vector3(cos(column_angle) * 1.33, 16.1, sin(column_angle) * 1.33),
			0.065,
			0.065,
			1.9,
			iron_material,
			6
		)

	var roof_mesh := CylinderMesh.new()
	roof_mesh.top_radius = 0.12
	roof_mesh.bottom_radius = 1.82
	roof_mesh.height = 1.55
	roof_mesh.radial_segments = 18
	var lantern_roof := _add_visual_mesh(
		"Red lantern roof",
		roof_mesh,
		Vector3(0.0, 17.76, 0.0),
		red_plaster,
		Vector3.ZERO,
		lighthouse
	)
	lantern_roof.add_to_group("lighthouse_roof")

	_lighthouse_beacon_rotator = Node3D.new()
	_lighthouse_beacon_rotator.name = "Rotating lighthouse beacon"
	_lighthouse_beacon_rotator.position = Vector3(0.0, 16.12, 0.0)
	_lighthouse_beacon_rotator.visible = false
	_lighthouse_beacon_rotator.add_to_group("lighthouse_beacon_rotator")
	lighthouse.add_child(_lighthouse_beacon_rotator)

	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.1
	beam_mesh.bottom_radius = 7.0
	beam_mesh.height = 160.0
	beam_mesh.radial_segments = 18
	var beam_material := StandardMaterial3D.new()
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam_material.albedo_color = Color(1.0, 0.88, 0.58, 0.032)
	beam_material.emission_enabled = true
	beam_material.emission = Color("ffe4a5")
	beam_material.emission_energy_multiplier = 0.12
	_lighthouse_beam_mesh = _add_visual_mesh(
		"Lighthouse beam haze",
		beam_mesh,
		Vector3(0.0, 0.0, -80.0),
		beam_material,
		Vector3(PI * 0.5, 0.0, 0.0),
		_lighthouse_beacon_rotator
	)
	_lighthouse_beam_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lighthouse_beam_mesh.add_to_group("working_lighthouse_beam")

	_lighthouse_spotlight = SpotLight3D.new()
	_lighthouse_spotlight.name = "Lighthouse sea spotlight"
	_lighthouse_spotlight.light_color = Color("ffe3a3")
	_lighthouse_spotlight.light_energy = 0.0
	_lighthouse_spotlight.spot_range = 190.0
	_lighthouse_spotlight.spot_angle = 6.0
	_lighthouse_spotlight.spot_attenuation = 0.7
	_lighthouse_spotlight.shadow_enabled = false
	_lighthouse_spotlight.visible = false
	_lighthouse_spotlight.add_to_group("lighthouse_light")
	_lighthouse_beacon_rotator.add_child(_lighthouse_spotlight)

	_lighthouse_lantern_glow = OmniLight3D.new()
	_lighthouse_lantern_glow.name = "Lighthouse lantern glow"
	_lighthouse_lantern_glow.position = Vector3(0.0, 16.12, 0.0)
	_lighthouse_lantern_glow.light_color = Color("ffdc92")
	_lighthouse_lantern_glow.light_energy = 0.0
	_lighthouse_lantern_glow.omni_range = 12.0
	_lighthouse_lantern_glow.omni_attenuation = 1.45
	_lighthouse_lantern_glow.shadow_enabled = false
	_lighthouse_lantern_glow.visible = false
	_lighthouse_lantern_glow.add_to_group("lighthouse_light")
	lighthouse.add_child(_lighthouse_lantern_glow)


func _add_lighthouse_cylinder(
	parent: Node3D,
	node_name: String,
	at: Vector3,
	top_radius: float,
	bottom_radius: float,
	height: float,
	material: Material,
	segments: int
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 2
	return _add_visual_mesh(
		node_name,
		mesh,
		at,
		material,
		Vector3.ZERO,
		parent
	)


func _make_distant_boats() -> void:
	var route_slots := [
		{
			"sector": "Northern",
			"origin": Vector3(-18.0, WATER_LEVEL + 0.3, -278.0),
			"direction": Vector2(1.0, 0.0),
			"span": 118.0,
		},
		{
			"sector": "Eastern",
			"origin": Vector3(302.0, WATER_LEVEL + 0.25, -18.0),
			"direction": Vector2(0.0, 1.0),
			"span": 96.0,
		},
		{
			"sector": "Southern",
			"origin": Vector3(12.0, WATER_LEVEL + 0.3, 274.0),
			"direction": Vector2(1.0, 0.0),
			"span": 126.0,
		},
		{
			"sector": "Western",
			"origin": Vector3(-302.0, WATER_LEVEL + 0.25, -5.0),
			"direction": Vector2(0.0, 1.0),
			"span": 90.0,
		},
	]
	var ship_types := ["motorboat", "tanker", "sailing", "cruise", "fishing"]
	var random := RandomNumberGenerator.new()
	if distant_fleet_seed == 0:
		random.randomize()
	else:
		random.seed = distant_fleet_seed
	_shuffle_with_rng(ship_types, random)
	_shuffle_with_rng(route_slots, random)

	var ship_count := random.randi_range(2, 3)
	var selected_types: Array[String] = []
	for index in ship_count:
		var ship_type: String = ship_types[index]
		var route: Dictionary = route_slots[index]
		var profile := _distant_ship_motion_profile(ship_type)
		route["ship_type"] = ship_type
		route["phase"] = random.randf_range(0.0, TAU)
		route["speed"] = float(profile.speed) * random.randf_range(0.92, 1.08)
		route["bob"] = float(profile.bob)
		route["roll"] = float(profile.roll)
		var ship_name := "%s %s" % [str(route.sector), str(profile.label)]
		var boat := _make_distant_ship(
			ship_name,
			ship_type,
			float(profile.scale) * random.randf_range(0.93, 1.07)
		)
		boat.position = route.origin
		route["node"] = boat
		_boat_routes.append(route)
		selected_types.append(ship_type)
	set_meta("visible_distant_ship_types", selected_types)


func _shuffle_with_rng(values: Array, random: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := random.randi_range(0, index)
		var temporary = values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary


func _distant_ship_motion_profile(ship_type: String) -> Dictionary:
	match ship_type:
		"motorboat":
			return {
				"label": "coastal motorboat",
				"scale": 0.9,
				"speed": 0.024,
				"bob": 0.075,
				"roll": 0.018,
			}
		"tanker":
			return {
				"label": "coastal tanker",
				"scale": 0.78,
				"speed": 0.013,
				"bob": 0.035,
				"roll": 0.006,
			}
		"sailing":
			return {
				"label": "sailing ship",
				"scale": 0.92,
				"speed": 0.019,
				"bob": 0.095,
				"roll": 0.026,
			}
		"cruise":
			return {
				"label": "cruise ship",
				"scale": 0.72,
				"speed": 0.011,
				"bob": 0.026,
				"roll": 0.004,
			}
		_:
			return {
				"label": "fishing boat",
				"scale": 0.88,
				"speed": 0.027,
				"bob": 0.09,
				"roll": 0.022,
			}


func _make_distant_ship(node_name: String, ship_type: String, boat_scale: float) -> Node3D:
	var boat := Node3D.new()
	boat.name = node_name
	boat.scale = Vector3.ONE * boat_scale
	boat.set_meta("ship_type", ship_type)
	boat.add_to_group("distant_boat")
	boat.add_to_group("distant_ship_" + ship_type)
	add_child(boat)

	match ship_type:
		"motorboat":
			_build_original_motorboat(boat)
		"tanker":
			_build_tanker_ship(boat)
		"sailing":
			_build_sailing_ship(boat)
		"cruise":
			_build_cruise_ship(boat)
		_:
			_build_fishing_ship(boat)
	return boat


func _build_original_motorboat(boat: Node3D) -> void:
	_add_boat_box(
		boat,
		"Original blue hull",
		Vector3(0.0, 0.0, 0.0),
		Vector3(3.4, 1.05, 8.2),
		Color("31566b")
	)
	_add_boat_box(
		boat,
		"Original red lower hull",
		Vector3(0.0, -0.42, 0.18),
		Vector3(3.12, 0.4, 7.75),
		Color("93483e")
	)
	_add_boat_box(
		boat,
		"Original cream cabin",
		Vector3(0.0, 1.08, 0.85),
		Vector3(2.55, 1.55, 3.1),
		Color("e8dfbd")
	)
	_add_boat_box(
		boat,
		"Original cabin windows",
		Vector3(0.0, 1.35, -0.74),
		Vector3(2.08, 0.52, 0.08),
		Color("294956")
	)
	_add_boat_box(
		boat,
		"Original red cabin roof",
		Vector3(0.0, 1.93, 0.85),
		Vector3(2.85, 0.18, 3.4),
		Color("a84e3d")
	)
	_add_boat_box(
		boat,
		"Original exhaust",
		Vector3(0.72, 2.42, 1.42),
		Vector3(0.42, 0.92, 0.42),
		Color("414a49")
	)
	_add_standard_ship_lights(boat, 1.58, -3.25, Vector3(0.0, 2.4, 2.3))
	_add_boat_smoke(boat, Vector3(0.72, 3.02, 1.42), 0.78)


func _build_tanker_ship(boat: Node3D) -> void:
	_add_boat_box(
		boat,
		"Long black hull",
		Vector3(0.0, 0.0, 0.0),
		Vector3(4.8, 1.35, 19.0),
		Color("242d31")
	)
	_add_boat_box(
		boat,
		"Red lower hull",
		Vector3(0.0, -0.55, 0.35),
		Vector3(4.45, 0.55, 18.2),
		Color("7f3d35")
	)
	_add_boat_box(
		boat,
		"Pipe deck",
		Vector3(0.0, 0.8, -1.0),
		Vector3(4.15, 0.22, 12.8),
		Color("9a8d72")
	)
	for tank_z in [-5.1, -2.0, 1.1, 4.2]:
		_add_boat_box(
			boat,
			"Cargo tank",
			Vector3(0.0, 1.03, tank_z),
			Vector3(3.55, 0.48, 2.35),
			Color("b3aa91")
		)
	_add_boat_box(
		boat,
		"Aft bridge",
		Vector3(0.0, 1.8, 6.9),
		Vector3(3.8, 2.35, 3.7),
		Color("ddd9c8")
	)
	_add_boat_box(
		boat,
		"Bridge windows",
		Vector3(0.0, 2.1, 4.99),
		Vector3(3.25, 0.5, 0.09),
		Color("263b45")
	)
	_add_boat_box(
		boat,
		"Tanker funnel",
		Vector3(0.0, 3.42, 7.5),
		Vector3(0.92, 1.15, 0.92),
		Color("b86b35")
	)
	_add_standard_ship_lights(boat, 2.25, -7.7, Vector3(0.0, 3.55, 5.8))
	_add_boat_smoke(boat, Vector3(0.0, 4.08, 7.5), 1.18)


func _build_sailing_ship(boat: Node3D) -> void:
	_add_boat_box(
		boat,
		"Blue sailing hull",
		Vector3(0.0, 0.0, 0.0),
		Vector3(2.8, 0.9, 8.6),
		Color("274b61")
	)
	_add_boat_box(
		boat,
		"Wooden deck",
		Vector3(0.0, 0.48, 0.15),
		Vector3(2.55, 0.18, 7.8),
		Color("a67b4d")
	)
	_add_boat_cylinder(
		boat,
		"Main mast",
		Vector3(0.0, 3.7, 0.35),
		0.12,
		6.7,
		Color("5e402a")
	)
	_add_boat_cylinder(
		boat,
		"Boom",
		Vector3(0.0, 2.2, -1.15),
		0.09,
		3.6,
		Color("5e402a"),
		Vector3(90.0, 0.0, 0.0)
	)
	_add_boat_sail(
		boat,
		"Main cream sail",
		Vector3(0.04, 1.4, 0.25),
		3.45,
		4.65,
		Color("eee2bd")
	)
	_add_boat_sail(
		boat,
		"Forward rust sail",
		Vector3(0.02, 1.75, -2.15),
		2.25,
		3.1,
		Color("b96748"),
		true
	)
	_add_boat_box(
		boat,
		"Small stern cabin",
		Vector3(0.0, 1.05, 2.55),
		Vector3(1.75, 0.95, 1.7),
		Color("e5dfc9")
	)
	_add_standard_ship_lights(boat, 1.34, -3.35, Vector3(0.0, 6.95, 0.35))


func _build_cruise_ship(boat: Node3D) -> void:
	_add_boat_box(
		boat,
		"Deep cruise hull",
		Vector3(0.0, 0.0, 0.0),
		Vector3(5.8, 1.65, 19.5),
		Color("263f55")
	)
	_add_boat_box(
		boat,
		"White cruise body",
		Vector3(0.0, 1.55, 0.8),
		Vector3(5.35, 2.2, 16.7),
		Color("e6e4dc")
	)
	for deck_index in 3:
		_add_boat_box(
			boat,
			"Passenger deck %d" % deck_index,
			Vector3(0.0, 2.95 + float(deck_index) * 0.72, 1.45 + float(deck_index) * 0.32),
			Vector3(4.65 - float(deck_index) * 0.35, 0.58, 13.5 - float(deck_index) * 1.1),
			Color("f2f0e6")
		)
		_add_boat_box(
			boat,
			"Window band %d" % deck_index,
			Vector3(0.0, 3.02 + float(deck_index) * 0.72, -5.35 + float(deck_index) * 0.35),
			Vector3(4.2 - float(deck_index) * 0.28, 0.23, 0.08),
			Color("294957")
		)
	_add_boat_box(
		boat,
		"Cruise funnel",
		Vector3(0.0, 5.35, 3.6),
		Vector3(1.35, 1.25, 1.45),
		Color("d8a13f")
	)
	_add_boat_box(
		boat,
		"Funnel cap",
		Vector3(0.0, 6.02, 3.6),
		Vector3(1.5, 0.22, 1.6),
		Color("30383b")
	)
	_add_standard_ship_lights(boat, 2.7, -8.15, Vector3(0.0, 5.75, -1.6))
	_add_boat_smoke(boat, Vector3(0.0, 6.48, 3.6), 1.28)


func _build_fishing_ship(boat: Node3D) -> void:
	_add_boat_box(
		boat,
		"Green fishing hull",
		Vector3(0.0, 0.0, 0.0),
		Vector3(3.2, 1.0, 8.2),
		Color("28534f")
	)
	_add_boat_box(
		boat,
		"Red fishing lower hull",
		Vector3(0.0, -0.42, 0.18),
		Vector3(2.95, 0.42, 7.8),
		Color("884139")
	)
	_add_boat_box(
		boat,
		"Forward wheelhouse",
		Vector3(0.0, 1.05, -1.75),
		Vector3(2.4, 1.55, 2.55),
		Color("dbd5bb")
	)
	_add_boat_box(
		boat,
		"Wheelhouse glass",
		Vector3(0.0, 1.32, -3.05),
		Vector3(1.95, 0.5, 0.08),
		Color("27434d")
	)
	_add_boat_cylinder(
		boat,
		"Fishing mast",
		Vector3(0.0, 3.05, -0.95),
		0.1,
		3.4,
		Color("505b58")
	)
	_add_boat_cylinder(
		boat,
		"Trawl boom",
		Vector3(0.0, 2.55, 1.15),
		0.08,
		4.2,
		Color("555c58"),
		Vector3(58.0, 0.0, 0.0)
	)
	_add_boat_box(
		boat,
		"Fishing crates",
		Vector3(-0.72, 0.72, 2.65),
		Vector3(1.05, 0.65, 1.25),
		Color("a27c4d")
	)
	_add_standard_ship_lights(boat, 1.5, -3.15, Vector3(0.0, 4.72, -0.95))
	_add_boat_smoke(boat, Vector3(0.78, 2.58, -0.55), 0.72)


func _add_boat_box(
	parent: Node3D,
	node_name: String,
	at: Vector3,
	size: Vector3,
	color: Color
) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.name = node_name
	part.position = at
	part.mesh = mesh
	part.material_override = _material(color)
	parent.add_child(part)


func _add_boat_cylinder(
	parent: Node3D,
	node_name: String,
	at: Vector3,
	radius: float,
	height: float,
	color: Color,
	rotation_degrees := Vector3.ZERO
) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 1
	var part := MeshInstance3D.new()
	part.name = node_name
	part.position = at
	part.rotation_degrees = rotation_degrees
	part.mesh = mesh
	part.material_override = _material(color)
	parent.add_child(part)


func _add_boat_sail(
	parent: Node3D,
	node_name: String,
	at: Vector3,
	width: float,
	height: float,
	color: Color,
	reversed := false
) -> void:
	var lower_forward := Vector3(0.0, 0.0, -width * 0.5)
	var lower_aft := Vector3(0.0, 0.0, width * 0.5)
	var top_z := width * (0.34 if reversed else -0.34)
	var top := Vector3(0.0, height, top_z)
	var vertices := PackedVector3Array([
		lower_forward,
		lower_aft,
		top,
		lower_aft,
		lower_forward,
		top,
	])
	var normals := PackedVector3Array([
		Vector3.LEFT,
		Vector3.LEFT,
		Vector3.LEFT,
		Vector3.RIGHT,
		Vector3.RIGHT,
		Vector3.RIGHT,
	])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := _material(color)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var sail := MeshInstance3D.new()
	sail.name = node_name
	sail.position = at
	sail.mesh = mesh
	sail.material_override = material
	parent.add_child(sail)


func _add_standard_ship_lights(
	parent: Node3D,
	half_width: float,
	bow_z: float,
	white_at: Vector3
) -> void:
	_add_boat_navigation_light(
		parent,
		Vector3(-half_width, maxf(1.25, white_at.y * 0.48), bow_z),
		Color("e84a45")
	)
	_add_boat_navigation_light(
		parent,
		Vector3(half_width, maxf(1.25, white_at.y * 0.48), bow_z),
		Color("56df87")
	)
	_add_boat_navigation_light(parent, white_at, Color("ffe8ad"))


func _add_boat_navigation_light(parent: Node3D, at: Vector3, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.62)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.0
	material.roughness = 0.35
	var mesh := SphereMesh.new()
	mesh.radius = 0.22
	mesh.height = 0.44
	var marker := MeshInstance3D.new()
	marker.name = "Navigation light"
	marker.position = at
	marker.mesh = mesh
	marker.material_override = material
	marker.add_to_group("boat_navigation_light")
	parent.add_child(marker)

	var light := OmniLight3D.new()
	light.name = "Navigation glow"
	light.position = at
	light.light_color = color
	light.light_energy = 0.0
	light.omni_range = 12.0
	light.visible = false
	parent.add_child(light)
	_boat_navigation_lights.append({
		"light": light,
		"material": material,
		"color": color,
	})


func _add_boat_smoke(parent: Node3D, at: Vector3, plume_scale := 1.0) -> void:
	var smoke_material := StandardMaterial3D.new()
	smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_material.albedo_color = Color(0.22, 0.24, 0.25, 0.44)
	smoke_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var smoke_mesh := SphereMesh.new()
	smoke_mesh.radius = 0.34 * plume_scale
	smoke_mesh.height = 0.68 * plume_scale
	smoke_mesh.material = smoke_material
	var process_material := ParticleProcessMaterial.new()
	process_material.direction = Vector3.UP
	process_material.spread = 17.0
	process_material.initial_velocity_min = 0.62 * plume_scale
	process_material.initial_velocity_max = 1.12 * plume_scale
	process_material.gravity = Vector3(0.08, 0.18, 0.03)
	process_material.scale_min = 0.45
	process_material.scale_max = 1.3
	var smoke := GPUParticles3D.new()
	smoke.name = "Funnel smoke"
	smoke.position = at
	smoke.amount = maxi(8, roundi(16.0 * plume_scale))
	smoke.lifetime = 4.2
	smoke.randomness = 0.46
	smoke.process_material = process_material
	smoke.draw_pass_1 = smoke_mesh
	smoke.visibility_aabb = AABB(
		Vector3(-4.0, -1.0, -4.0) * plume_scale,
		Vector3(8.0, 9.0, 8.0) * plume_scale
	)
	smoke.add_to_group("boat_smoke")
	parent.add_child(smoke)


func _update_distant_boats() -> void:
	for route: Dictionary in _boat_routes:
		var boat: Node3D = route.node
		var phase := _world_motion_time * float(route.speed) + float(route.phase)
		var direction: Vector2 = route.direction
		var travel := sin(phase) * float(route.span)
		var origin: Vector3 = route.origin
		boat.position = Vector3(
			origin.x + direction.x * travel,
			origin.y + sin(_world_motion_time * 0.72 + float(route.phase)) * float(route.bob),
			origin.z + direction.y * travel
		)
		var heading := direction if cos(phase) >= 0.0 else -direction
		boat.rotation.y = atan2(heading.x, heading.y)
		boat.rotation.z = (
			sin(_world_motion_time * 0.58 + float(route.phase))
			* float(route.roll)
		)


func _make_bridges_and_quays() -> void:
	_make_arched_bridge(
		"South canal cycle bridge",
		Vector3(-82.0, 0.0, 122.75),
		Vector3(-64.0, 0.0, 124.0),
		9.0,
		STONE.lightened(0.04),
		0.62
	)
	for crossing_z: float in [-82.0, -54.0, 18.0, 78.0]:
		_make_arched_bridge(
			"Arched canal bridge",
			Vector3(-82.0, 0.0, crossing_z),
			Vector3(-64.0, 0.0, crossing_z),
			10.0,
			STONE,
			0.72
		)

	_make_arched_bridge(
		"Grand river bridge",
		Vector3(0.0, 0.0, -94.0),
		Vector3(0.0, 0.0, -116.0),
		10.0,
		STONE.lightened(0.05),
		1.0
	)
	_make_arched_bridge(
		"East river bridge",
		Vector3(92.0, 0.0, -94.0),
		Vector3(92.0, 0.0, -116.0),
		9.0,
		STONE,
		0.85
	)
	_make_arched_bridge(
		"Garden river bridge",
		Vector3(58.0, 0.0, -94.0),
		Vector3(58.0, 0.0, -116.0),
		9.0,
		STONE.lightened(0.025),
		0.9
	)
	_make_arched_bridge(
		"West coast river bridge",
		Vector3(-180.0, 0.0, -116.0),
		Vector3(-187.0, 0.0, -94.0),
		8.0,
		DARK_STONE.lightened(0.08),
		0.72
	)
	_make_arched_bridge(
		"East coast river bridge",
		Vector3(179.0, 0.0, -116.0),
		Vector3(186.0, 0.0, -94.0),
		8.0,
		DARK_STONE.lightened(0.08),
		0.72
	)

	var open_crossings: Array[Vector2] = [
		Vector2(-105.0, -87.0),
		Vector2(-77.0, -59.0),
		Vector2(-49.0, 13.0),
		Vector2(23.0, 73.0),
		Vector2(83.0, 115.5),
		Vector2(130.5, 135.0),
	]
	for segment: Vector2 in open_crossings:
		var center_z: float = (segment.x + segment.y) * 0.5
		var length: float = segment.y - segment.x
		for edge_x in [-80.2, -65.8]:
			_make_box(
				"Canal quay wall",
				Vector3(edge_x, -0.2, center_z),
				Vector3(0.45, 1.7, length),
				DARK_STONE,
				true
			)

	var river_wall_sections: Array[Vector2] = [
		Vector2(-170.0, -6.0),
		Vector2(6.0, 52.5),
		Vector2(63.5, 86.5),
		Vector2(97.5, 170.0),
	]
	for section: Vector2 in river_wall_sections:
		var center_x := (section.x + section.y) * 0.5
		var length := section.y - section.x
		for edge_z in [-114.2, -95.8]:
			_make_box(
				"River quay wall",
				Vector3(center_x, -0.3, edge_z),
				Vector3(length, 1.9, 0.5),
				DARK_STONE,
				true
			)


func _make_arched_bridge(
	node_name: String,
	from: Vector3,
	to: Vector3,
	width: float,
	color: Color,
	arch_height: float
) -> void:
	_register_road_corridor(from, to, width + 1.0, width)
	var horizontal_direction := Vector3(to.x - from.x, 0.0, to.z - from.z).normalized()
	var side := Vector3(-horizontal_direction.z, 0.0, horizontal_direction.x)
	var segments := 12
	var from_ground := ground_height_at(from.x, from.z)
	var to_ground := ground_height_at(to.x, to.z)
	_bridge_surfaces.append({
		"from": Vector2(from.x, from.z),
		"to": Vector2(to.x, to.z),
		"width": width,
		"from_height": from_ground,
		"to_height": to_ground,
		"arch_height": arch_height,
	})
	for index in segments:
		var start_weight := float(index) / float(segments)
		var end_weight := float(index + 1) / float(segments)
		var start := from.lerp(to, start_weight)
		var end := from.lerp(to, end_weight)
		# The deck begins slightly inside the bank so a CharacterBody can roll
		# onto the slope without encountering a vertical curb.
		start.y = (
			lerpf(from_ground, to_ground, start_weight)
			+ sin(start_weight * PI) * arch_height
			- 0.08
		)
		end.y = (
			lerpf(from_ground, to_ground, end_weight)
			+ sin(end_weight * PI) * arch_height
			- 0.08
		)
		_make_ridable_surface_segment(
			node_name,
			start,
			end,
			width,
			0.22,
			color,
			false
		)

		for lane_side: float in [-1.0, 1.0]:
			var lane_offset: Vector3 = side * lane_side * (width * 0.5 - 1.0)
			_make_visual_surface_segment(
				node_name + " cycle track",
				start + lane_offset + Vector3.UP * 0.13,
				end + lane_offset + Vector3.UP * 0.13,
				1.55,
				0.035,
				CYCLE_RED
			)
			var parapet_offset: Vector3 = side * lane_side * (width * 0.5 + 0.16)
			_make_ridable_surface_segment(
				node_name + " parapet",
				start + parapet_offset + Vector3.UP * 0.48,
				end + parapet_offset + Vector3.UP * 0.48,
				0.35,
				0.72,
				DARK_STONE,
				true
			)


func _make_ridable_surface_segment(
	node_name: String,
	from: Vector3,
	to: Vector3,
	width: float,
	thickness: float,
	color: Color,
	is_obstacle: bool
) -> StaticBody3D:
	var delta := to - from
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = (from + to) * 0.5
	body.basis = _surface_basis(delta)
	if is_obstacle:
		body.add_to_group("obstacle")
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, thickness, delta.length())
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	if color.is_equal_approx(STONE) or color.is_equal_approx(DARK_STONE):
		visual.material_override = _stone_material(color)
	else:
		visual.material_override = _material(color)
	body.add_child(visual)
	add_child(body)
	return body


func _make_street_furniture() -> void:
	for position in [
		Vector3(-18.0, 0.0, 10.0),
		Vector3(18.0, 0.0, 10.0),
		Vector3(-18.0, 0.0, -23.0),
		Vector3(18.0, 0.0, -23.0),
		Vector3(-36.0, 0.0, 42.0),
		Vector3(36.0, 0.0, 42.0),
		Vector3(-32.0, 0.0, -48.0),
		Vector3(32.0, 0.0, -48.0),
		Vector3(-63.0, 0.0, 5.0),
		Vector3(-63.0, 0.0, 38.0),
		Vector3(-63.0, 0.0, -38.0),
		Vector3(66.0, 0.0, 42.0),
	]:
		var grounded_position: Vector3 = position
		grounded_position.y = ground_height_at(position.x, position.z)
		_lamp_pole_transforms.append(
			Transform3D(Basis.IDENTITY, grounded_position + Vector3(0.0, 2.1, 0.0))
		)
		_lamp_bulb_transforms.append(
			Transform3D(Basis.IDENTITY, grounded_position + Vector3(0.0, 4.25, 0.0))
		)
	_make_market_festival_decor()


func _make_market_festival_decor() -> void:
	var mast_positions: Array[Vector2] = [
		Vector2(-18.0, -18.0),
		Vector2(18.0, -18.0),
		Vector2(-17.0, 7.0),
		Vector2(17.0, 7.0),
	]
	var anchors: Array[Vector3] = []
	for index in mast_positions.size():
		var point := mast_positions[index]
		var ground := ground_height_at(point.x, point.y)
		var mast := _make_box(
			"Market garland mast %02d" % index,
			Vector3(point.x, ground + 3.1, point.y),
			Vector3(0.13, 6.2, 0.13),
			Color("31433d"),
			true,
			_material(Color("31433d"))
		)
		mast.add_to_group("garland_anchor_mast")
		mast.set_meta(
			"road_clearance",
			road_surface_clearance_at(Vector3(point.x, ground, point.y))
		)
		var finial := SphereMesh.new()
		finial.radius = 0.19
		finial.height = 0.38
		finial.radial_segments = 8
		finial.rings = 4
		_add_visual_mesh(
			"Garland mast finial",
			finial,
			Vector3(point.x, ground + 6.25, point.y),
			_material(Color("c49b51")),
			Vector3.ZERO,
			self
		)
		anchors.append(Vector3(point.x, ground + 5.95, point.y))

	for connection in [
		[0, 1],
		[1, 3],
		[3, 2],
		[2, 0],
		[0, 3],
	]:
		_make_hanging_garland(
			"Market hanging garland %02d" % int(connection[0] * 4 + connection[1]),
			anchors[connection[0]],
			anchors[connection[1]],
			0.72
		)

	# Terracotta pots cluster around the festival masts and fountain edge. They
	# occupy the square rather than the roadway and remain visual-only so a
	# rider brushing a flower never gets an unfair collision.
	var pot_positions: Array[Vector3] = []
	for point: Vector2 in mast_positions:
		pot_positions.append(Vector3(point.x - 0.52, 0.0, point.y + 0.48))
		pot_positions.append(Vector3(point.x + 0.52, 0.0, point.y - 0.48))
	for angle_index in 6:
		var angle := TAU * float(angle_index) / 6.0 + PI * 0.15
		pot_positions.append(
			Vector3(9.0 + cos(angle) * 4.15, 0.0, -6.0 + sin(angle) * 4.15)
		)
	for index in pot_positions.size():
		_queue_city_flower_pot(pot_positions[index], index)
	set_meta("city_flower_pot_count", _city_flower_pot_transforms.size())


func _queue_city_flower_pot(at: Vector3, variation: int) -> void:
	if road_surface_clearance_at(at) < 0.8:
		return
	var ground := ground_height_at(at.x, at.z)
	var center := Vector3(at.x, ground + 0.28, at.z)
	var rotation_y := float(variation) * 0.71
	_city_flower_pot_transforms.append(
		_scaled_cylinder_transform(center, Vector3(0.34, 0.56, 0.34), rotation_y)
	)
	for stem_index in 3:
		var angle := TAU * float(stem_index) / 3.0 + rotation_y
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * 0.12
		var stem_center := center + offset + Vector3.UP * (0.31 + 0.05 * stem_index)
		_city_flower_stem_transforms.append(
			_scaled_cylinder_transform(
				stem_center,
				Vector3(0.035, 0.48 + 0.08 * stem_index, 0.035),
				angle
			)
		)
		_city_flower_leaf_transforms.append(
			_scaled_sphere_transform(
				stem_center + Vector3(cos(angle), 0.03, sin(angle)) * 0.1,
				Vector3(0.12, 0.06, 0.2),
				angle
			)
		)
		var flower_transform := _scaled_sphere_transform(
			stem_center + Vector3.UP * (0.28 + 0.04 * stem_index),
			Vector3(0.15, 0.1, 0.15),
			angle
		)
		match (variation + stem_index) % 3:
			0:
				_city_flower_red_transforms.append(flower_transform)
			1:
				_city_flower_yellow_transforms.append(flower_transform)
			_:
				_city_flower_purple_transforms.append(flower_transform)


func _make_hanging_garland(
	node_name: String,
	from: Vector3,
	to: Vector3,
	sag: float
) -> void:
	var root_node := Node3D.new()
	root_node.name = node_name
	root_node.add_to_group("hanging_garland")
	var cable_material := _material(Color("2f593b"))
	var point_count := 25
	var points: Array[Vector3] = []
	var minimum_clearance := INF
	for point_index in point_count:
		var weight := float(point_index) / float(point_count - 1)
		var point := from.lerp(to, weight)
		point.y -= sin(weight * PI) * sag
		points.append(point)
		minimum_clearance = minf(
			minimum_clearance,
			point.y - ground_height_at(point.x, point.z)
		)
	for index in points.size() - 1:
		var start := points[index]
		var finish := points[index + 1]
		var segment := finish - start
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.055, 0.055, segment.length())
		var cable := MeshInstance3D.new()
		cable.name = "Leafy garland cable"
		cable.position = (start + finish) * 0.5
		cable.basis = _surface_basis(segment)
		cable.mesh = mesh
		cable.material_override = cable_material
		root_node.add_child(cable)
		var decoration_at := points[index]
		var travel := Vector3(to.x - from.x, 0.0, to.z - from.z).normalized()
		var leaf_rotation := atan2(travel.x, travel.z) + float(index) * 0.8
		for side in [-1.0, 1.0]:
			_garland_leaf_transforms.append(
				_scaled_sphere_transform(
					decoration_at
					+ Vector3.UP * -0.08
					+ Vector3(-travel.z, 0.0, travel.x) * float(side) * 0.11,
					Vector3(0.13, 0.055, 0.22),
					leaf_rotation + float(side) * 0.55
				)
			)
		if index % 2 == 0:
			var blossom := _scaled_sphere_transform(
				decoration_at + Vector3.UP * -0.15,
				Vector3(0.095, 0.075, 0.095),
				leaf_rotation
			)
			if index % 4 == 0:
				_garland_red_flower_transforms.append(blossom)
			else:
				_garland_yellow_flower_transforms.append(blossom)
	root_node.set_meta("minimum_ground_clearance", minimum_clearance)
	add_child(root_node)


func _building_footprint_is_road_clear(
	at: Vector3,
	width: float,
	depth: float,
	rotation_y: float,
	required_clearance := 0.65
) -> bool:
	var center := Vector2(at.x, at.z)
	var axis_x := Vector2(cos(rotation_y), -sin(rotation_y))
	var axis_z := Vector2(sin(rotation_y), cos(rotation_y))
	var half_size := Vector2(width, depth) * 0.5
	for corridor: Dictionary in _road_corridors:
		var from: Vector2 = corridor.from
		var to: Vector2 = corridor.to
		var segment := to - from
		var weight := 0.0
		if not segment.is_zero_approx():
			weight = clampf(
				(center - from).dot(segment) / segment.length_squared(),
				0.0,
				1.0
			)
		var offset := center - from.lerp(to, weight)
		var distance := offset.length()
		var normal := offset / distance if distance > 0.001 else Vector2.RIGHT
		var support := (
			absf(normal.dot(axis_x)) * half_size.x
			+ absf(normal.dot(axis_z)) * half_size.y
		)
		var clearance := distance - float(corridor.drivable_radius) - support
		if clearance < required_clearance:
			return false
	return true


func _make_heritage_house(
	node_name: String,
	at: Vector3,
	width: float,
	height: float,
	depth: float,
	color: Color,
	rotation_y: float
) -> void:
	if not _building_footprint_is_road_clear(at, width + 0.16, depth + 0.16, rotation_y):
		var rejected_count := int(get_meta("road_rejected_building_count", 0))
		set_meta("road_rejected_building_count", rejected_count + 1)
		return
	var grounded_at := at
	var height_range := _footprint_height_range(at, width, depth, rotation_y)
	grounded_at.y = height_range.y + 0.04
	var style_seed := absi(hash(node_name))
	var prague_style := (
		(absf(at.x) < 58.0 and at.z > -55.0 and at.z < 52.0)
		or "University" in node_name
	)
	var cornish_style := (
		not prague_style
		or "Canal" in node_name
		or "cottage" in node_name.to_lower()
		or "North bank" in node_name
	)
	var exposed_stone := cornish_style and style_seed % 4 == 0
	var wall_material: Material = (
		_stone_material(Color("918777"))
		if exposed_stone
		else _facade_material(color)
	)
	# Sink the plinth below the lowest footprint sample. A shallow foundation
	# can expose a black slit where the procedural slope dips between samples,
	# making the whole house appear to float.
	var foundation_bottom := height_range.x - 0.72
	var foundation_height := maxf(0.96, grounded_at.y - foundation_bottom + 0.12)
	var foundation := _make_rotated_box(
		node_name + " stone foundation",
		Vector3(
			grounded_at.x,
			foundation_bottom + foundation_height * 0.5,
			grounded_at.z
		),
		Vector3(width + 0.34, foundation_height, depth + 0.34),
		DARK_STONE,
		rotation_y,
		true,
		_stone_material(DARK_STONE)
	)
	foundation.add_to_group("terrain_sealed_foundation")
	foundation.set_meta("foundation_bottom", foundation_bottom)
	foundation.set_meta("sampled_ground_minimum", height_range.x)
	_make_rotated_box(
		node_name,
		grounded_at + Vector3(0.0, height * 0.5, 0.0),
		Vector3(width, height, depth),
		color,
		rotation_y,
		true,
		wall_material
	)
	var roof_color := (
		SLATE
		if cornish_style and style_seed % 3 != 0
		else TERRACOTTA
	)
	var roof_pitch := 34.0 if cornish_style else 29.0
	var uses_hipped_roof := prague_style and style_seed % 2 == 0
	if uses_hipped_roof:
		_make_hipped_roof(
			grounded_at + Vector3(0.0, height, 0.0),
			width,
			depth,
			rotation_y,
			roof_color,
			roof_pitch
		)
	else:
		_make_gabled_roof(
			grounded_at + Vector3(0.0, height, 0.0),
			width,
			depth,
			rotation_y,
			roof_color,
			wall_material,
			roof_pitch
		)
	if cornish_style and style_seed % 3 == 0:
		_make_cottage_rear_wing(
			node_name,
			grounded_at,
			width,
			height,
			depth,
			rotation_y,
			color,
			wall_material,
			roof_color,
			style_seed
		)
	elif prague_style and style_seed % 3 == 1:
		_make_projecting_urban_bay(
			node_name,
			grounded_at,
			width,
			height,
			depth,
			rotation_y,
			color,
			wall_material,
			style_seed
		)
	_queue_house_architectural_details(
		node_name,
		grounded_at,
		width,
		height,
		depth,
		rotation_y,
		style_seed,
		prague_style,
		cornish_style,
		roof_pitch
	)

	var facing_basis := Basis(Vector3.UP, rotation_y)
	var facing: Vector3 = facing_basis * Vector3(0.0, 0.0, depth * 0.5 + 0.06)
	var landing_probe: Vector3 = (
		grounded_at
		+ facing_basis * Vector3(0.0, 0.0, depth * 0.5 + 1.25)
	)
	var entrance_ground := ground_height_at(landing_probe.x, landing_probe.z)
	if entrance_ground < WATER_LEVEL - 0.1:
		_make_waterfront_door_landing(
			node_name,
			grounded_at,
			depth,
			rotation_y
		)
	elif grounded_at.y - entrance_ground > 0.28:
		_make_heritage_entry_stairs(
			node_name,
			grounded_at,
			depth,
			rotation_y
		)
	var right: Vector3 = facing_basis * Vector3.RIGHT
	var back_basis := Basis(Vector3.UP, rotation_y + PI)
	var back: Vector3 = back_basis * Vector3(0.0, 0.0, depth * 0.5 + 0.06)
	var back_right: Vector3 = back_basis * Vector3.RIGHT
	var right_side_basis := Basis(Vector3.UP, rotation_y + PI * 0.5)
	var right_side: Vector3 = right_side_basis * Vector3(0.0, 0.0, width * 0.5 + 0.06)
	var right_side_across: Vector3 = right_side_basis * Vector3.RIGHT
	var left_side_basis := Basis(Vector3.UP, rotation_y - PI * 0.5)
	var left_side: Vector3 = left_side_basis * Vector3(0.0, 0.0, width * 0.5 + 0.06)
	var left_side_across: Vector3 = left_side_basis * Vector3.RIGHT
	var floors := maxi(1, int((height - 0.8) / 2.2))
	var columns := maxi(2, int(width / 2.5))
	var side_columns := maxi(1, int(depth / 3.0))
	for floor_index in floors:
		var window_y := 1.5 + float(floor_index) * 2.15
		if window_y > height - 0.65:
			continue
		for column in columns:
			var horizontal := (
				(float(column) + 0.5) / float(columns) - 0.5
			) * (width - 1.2)
			_heritage_window_transforms.append(
				Transform3D(
					back_basis,
					grounded_at + back + back_right * horizontal + Vector3.UP * window_y
				)
			)
			if floor_index == 0 and absf(horizontal) < 0.8:
				continue
			# Delivery-game signage is added after the procedural city is built.
			# Reserve its facade bay here so lettering never sits on top of a
			# generic upper-storey window or climbing plant.
			if (
				node_name == "Boulangerie du Pont"
				and window_y > 3.15
				and window_y < 5.1
				and absf(horizontal) < 3.15
			):
				continue
			var front_window_transform := Transform3D(
				facing_basis,
				grounded_at + facing + right * horizontal + Vector3.UP * window_y
			)
			_heritage_window_transforms.append(front_window_transform)
			if (
				floor_index == 0
				and (style_seed + column * 5) % (3 if cornish_style else 5) == 0
			):
				_queue_window_planter(front_window_transform, style_seed + column)
		for column in side_columns:
			var side_horizontal := (
				(float(column) + 0.5) / float(side_columns) - 0.5
			) * (depth - 1.2)
			_heritage_window_transforms.append(
				Transform3D(
					right_side_basis,
					grounded_at
					+ right_side
					+ right_side_across * side_horizontal
					+ Vector3.UP * window_y
				)
			)
			_heritage_window_transforms.append(
				Transform3D(
					left_side_basis,
					grounded_at
					+ left_side
					+ left_side_across * side_horizontal
					+ Vector3.UP * window_y
				)
			)
	_heritage_door_transforms.append(
		Transform3D(
			facing_basis,
			grounded_at + facing + Vector3.UP * 1.1
		)
	)


func _make_cottage_rear_wing(
	node_name: String,
	grounded_at: Vector3,
	width: float,
	height: float,
	depth: float,
	rotation_y: float,
	color: Color,
	wall_material: Material,
	roof_color: Color,
	style_seed: int
) -> void:
	var facing_basis := Basis(Vector3.UP, rotation_y)
	var wing_width := clampf(width * 0.52, 3.8, 5.8)
	var wing_depth := clampf(depth * 0.9, 5.2, 8.4)
	var side := -1.0 if style_seed % 2 == 0 else 1.0
	var local_center := Vector3(
		side * (width * 0.5 - wing_width * 0.48),
		0.0,
		-depth * 0.5 - wing_depth * 0.34
	)
	var wing_at := grounded_at + facing_basis * local_center
	if not _building_footprint_is_road_clear(
		wing_at,
		wing_width,
		wing_depth,
		rotation_y,
		0.3
	):
		return
	var height_range := _footprint_height_range(
		wing_at,
		wing_width,
		wing_depth,
		rotation_y
	)
	var wing_base_y := maxf(grounded_at.y, height_range.y + 0.04)
	var wing_height := clampf(height * 0.68, 3.8, 5.8)
	var wing_foundation_bottom := height_range.x - 0.62
	var wing_foundation_height := maxf(
		0.82,
		wing_base_y - wing_foundation_bottom + 0.1
	)
	var wing_foundation := _make_rotated_box(
		node_name + " rear wing stone foundation",
		Vector3(
			wing_at.x,
			wing_foundation_bottom + wing_foundation_height * 0.5,
			wing_at.z
		),
		Vector3(wing_width + 0.28, wing_foundation_height, wing_depth + 0.28),
		DARK_STONE,
		rotation_y,
		true,
		_stone_material(DARK_STONE)
	)
	wing_foundation.add_to_group("terrain_sealed_foundation")
	wing_foundation.set_meta("foundation_bottom", wing_foundation_bottom)
	wing_foundation.set_meta("sampled_ground_minimum", height_range.x)
	var body := _make_rotated_box(
		node_name + " rear cottage wing",
		Vector3(wing_at.x, wing_base_y + wing_height * 0.5, wing_at.z),
		Vector3(wing_width, wing_height, wing_depth),
		color,
		rotation_y,
		true,
		wall_material
	)
	body.add_to_group("house_shape_variant")
	_make_gabled_roof(
		Vector3(wing_at.x, wing_base_y + wing_height, wing_at.z),
		wing_width,
		wing_depth,
		rotation_y,
		roof_color,
		wall_material,
		38.0
	)


func _make_projecting_urban_bay(
	node_name: String,
	grounded_at: Vector3,
	width: float,
	height: float,
	depth: float,
	rotation_y: float,
	color: Color,
	wall_material: Material,
	style_seed: int
) -> void:
	var facing_basis := Basis(Vector3.UP, rotation_y)
	var bay_width := clampf(width * 0.27, 2.1, 3.0)
	var bay_depth := 0.74
	var bay_height := minf(height - 0.45, 5.9)
	if bay_height < 3.2:
		return
	var horizontal := width * (0.17 if style_seed % 2 == 0 else -0.17)
	var bay_at := (
		grounded_at
		+ facing_basis * Vector3(
			horizontal,
			bay_height * 0.5,
			depth * 0.5 + bay_depth * 0.44
		)
	)
	if not _building_footprint_is_road_clear(
		Vector3(bay_at.x, grounded_at.y, bay_at.z),
		bay_width,
		bay_depth,
		rotation_y,
		0.12
	):
		return
	var body := _make_rotated_box(
		node_name + " projecting bay",
		bay_at,
		Vector3(bay_width, bay_height, bay_depth),
		color,
		rotation_y,
		true,
		wall_material
	)
	body.add_to_group("house_shape_variant")
	var cap_at := (
		grounded_at
		+ facing_basis * Vector3(
			horizontal,
			bay_height + 0.08,
			depth * 0.5 + bay_depth * 0.44
		)
	)
	var cap := _make_rotated_box(
		node_name + " bay stone cap",
		cap_at,
		Vector3(bay_width + 0.26, 0.2, bay_depth + 0.22),
		Color("d3c9ae"),
		rotation_y,
		false,
		_stone_material(Color("d3c9ae"))
	)
	cap.add_to_group("house_shape_variant")
	for floor_index in 2:
		var window_at := (
			grounded_at
			+ facing_basis * Vector3(
				horizontal,
				1.5 + float(floor_index) * 2.15,
				depth * 0.5 + bay_depth + 0.02
			)
		)
		_heritage_window_transforms.append(
			Transform3D(facing_basis, window_at)
		)


func _make_waterfront_door_landing(
	node_name: String,
	grounded_at: Vector3,
	depth: float,
	rotation_y: float
) -> void:
	var facing_basis := Basis(Vector3.UP, rotation_y)
	var platform := _make_rotated_box(
		node_name + " waterside loading platform",
		grounded_at
		+ facing_basis * Vector3(0.0, -0.05, depth * 0.5 + 1.15),
		Vector3(3.25, 0.28, 2.25),
		STONE,
		rotation_y,
		false,
		_stone_material(STONE)
	)
	platform.add_to_group("waterfront_door_landing")
	for step_index in 3:
		var step := _make_rotated_box(
			node_name + " water stair %02d" % step_index,
			grounded_at
			+ facing_basis * Vector3(
				0.0,
				-0.18 - float(step_index) * 0.17,
				depth * 0.5 + 2.45 + float(step_index) * 0.48
			),
			Vector3(2.65, 0.2, 0.62),
			DARK_STONE,
			rotation_y,
			false,
			_stone_material(DARK_STONE)
		)
		step.add_to_group("waterfront_door_landing")


func _make_heritage_entry_stairs(
	node_name: String,
	grounded_at: Vector3,
	depth: float,
	rotation_y: float
) -> void:
	var facing_basis := Basis(Vector3.UP, rotation_y)
	var outward := (facing_basis * Vector3.BACK).normalized()
	var right := (facing_basis * Vector3.RIGHT).normalized()
	var facade_edge := grounded_at + outward * (depth * 0.5)

	# Prefer a traditional straight stoop. Where a close street leaves too
	# little room, turn the flight along the facade instead of intruding into
	# a bike or traffic lane.
	var initial_drop := maxf(
		0.0,
		grounded_at.y
		- ground_height_at(
			facade_edge.x + outward.x * 1.4,
			facade_edge.z + outward.z * 1.4
		)
	)
	var estimated_steps := clampi(int(ceil(initial_drop / 0.21)), 2, 10)
	var estimated_run := 0.62 + float(estimated_steps) * 0.37
	var straight_end := facade_edge + outward * estimated_run
	var travel_direction := outward
	if road_surface_clearance_at(straight_end) < 0.42:
		var right_end := facade_edge + outward * 0.48 + right * estimated_run
		var left_end := facade_edge + outward * 0.48 - right * estimated_run
		travel_direction = (
			right
			if road_surface_clearance_at(right_end)
			>= road_surface_clearance_at(left_end)
			else -right
		)

	var landing_center := facade_edge + outward * 0.3
	if road_surface_clearance_at(landing_center) < 0.32:
		return
	var landing_ground := ground_height_at(landing_center.x, landing_center.z)
	var landing_height := maxf(0.18, grounded_at.y - landing_ground + 0.05)
	var landing := _make_rotated_box(
		node_name + " front door landing",
		Vector3(
			landing_center.x,
			landing_ground + landing_height * 0.5,
			landing_center.z
		),
		Vector3(2.15, landing_height, 0.58),
		STONE,
		rotation_y,
		false,
		_stone_material(STONE)
	)
	landing.add_to_group("heritage_entry_stair")

	var first_step_center := (
		facade_edge
		+ outward * (0.68 if travel_direction.is_equal_approx(outward) else 0.48)
	)
	var flight_end := (
		first_step_center
		+ travel_direction * (0.37 * float(estimated_steps))
	)
	var bottom_ground := ground_height_at(flight_end.x, flight_end.z)
	var total_drop := maxf(0.0, grounded_at.y - bottom_ground)
	var step_count := clampi(int(ceil(total_drop / 0.21)), 2, 10)
	var step_rise := total_drop / float(step_count)
	var step_rotation := atan2(travel_direction.x, travel_direction.z)
	for step_index in step_count:
		var step_center := (
			first_step_center
			+ travel_direction * (0.37 * (float(step_index) + 0.5))
		)
		if road_surface_clearance_at(step_center) < 0.28:
			break
		var local_ground := ground_height_at(step_center.x, step_center.z)
		var step_top := grounded_at.y - step_rise * float(step_index + 1)
		var block_height := maxf(0.17, step_top - local_ground + 0.04)
		var step := _make_rotated_box(
			node_name + " entrance step %02d" % step_index,
			Vector3(
				step_center.x,
				local_ground + block_height * 0.5,
				step_center.z
			),
			Vector3(1.85, block_height, 0.43),
			STONE,
			step_rotation,
			false,
			_stone_material(STONE)
		)
		step.add_to_group("heritage_entry_stair")


func _queue_house_architectural_details(
	node_name: String,
	grounded_at: Vector3,
	width: float,
	height: float,
	depth: float,
	rotation_y: float,
	style_seed: int,
	prague_style: bool,
	cornish_style: bool,
	roof_pitch_degrees: float
) -> void:
	var facing_basis := Basis(Vector3.UP, rotation_y)
	var front_z := depth * 0.5 + 0.13
	var back_z := -depth * 0.5 - 0.13

	# Prague's narrow streets read through strong horizontal cornices and
	# pilasters. Cornish cottages use the same language more sparingly as
	# chunky stone lintels and painted eaves.
	for local_z in [front_z, back_z]:
		var outward_sign := signf(local_z)
		_house_trim_transforms.append(_scaled_box_transform(
			grounded_at
			+ facing_basis * Vector3(
				0.0,
				height + 0.01,
				local_z + outward_sign * 0.1
			),
			Vector3(width + 0.5, 0.34, 0.3),
			rotation_y
		))
	if prague_style:
		for belt_height in [2.55, 5.05]:
			if belt_height >= height - 0.7:
				continue
			_house_trim_transforms.append(_scaled_box_transform(
				grounded_at + facing_basis * Vector3(0.0, belt_height, front_z),
				Vector3(width + 0.2, 0.16, 0.17),
				rotation_y
			))
		for local_x in [-width * 0.5 + 0.22, width * 0.5 - 0.22]:
			_house_pilaster_transforms.append(_scaled_box_transform(
				grounded_at
				+ facing_basis * Vector3(local_x, height * 0.5, front_z + 0.02),
				Vector3(0.28, height - 0.35, 0.2),
				rotation_y
			))
	# Drainpipes, chimneys, dormers, and imperfect planting stop otherwise
	# identical boxes from reading as clean procedural placeholders.
	var pipe_x := width * (0.5 if style_seed % 2 == 0 else -0.5)
	_house_downpipe_transforms.append(_scaled_box_transform(
		grounded_at
		+ facing_basis * Vector3(pipe_x, height * 0.47, front_z + 0.09),
		Vector3(0.11, height * 0.94, 0.11),
		rotation_y
	))

	var roof_rise := depth * 0.5 * tan(deg_to_rad(roof_pitch_degrees))
	var chimney_count := 2 if width > 11.5 and style_seed % 3 == 0 else 1
	for chimney_index in chimney_count:
		var chimney_x := (
			(float(chimney_index) + 0.5) / float(chimney_count) - 0.5
		) * width * 0.58
		var chimney_center := (
			grounded_at
			+ facing_basis * Vector3(
				chimney_x,
				height + roof_rise * 0.62 + 1.05,
				depth * (-0.1 if chimney_index % 2 == 0 else 0.12)
			)
		)
		_house_chimney_transforms.append(_scaled_box_transform(
			chimney_center,
			Vector3(0.72, 2.1, 0.62),
			rotation_y
		))
		for pot_offset in [-0.18, 0.18]:
			_house_chimney_pot_transforms.append(
				_scaled_cylinder_transform(
					chimney_center
					+ facing_basis * Vector3(pot_offset, 1.22, 0.0),
					Vector3(0.17, 0.42, 0.17),
					rotation_y
				)
			)

	var has_dormer := (
		height > 6.0
		and (
			(prague_style and style_seed % 2 == 0)
			or (cornish_style and style_seed % 4 == 1)
		)
	)
	if has_dormer:
		var dormer_x := (
			-width * 0.2
			if width > 11.0 and style_seed % 2 == 0
			else 0.0
		)
		var dormer_y := height + 1.12
		var dormer_z := depth * 0.5 - minf(1.35, depth * 0.16)
		var dormer_center := (
			grounded_at
			+ facing_basis * Vector3(dormer_x, dormer_y, dormer_z)
		)
		_house_dormer_wall_transforms.append(_scaled_box_transform(
			dormer_center,
			Vector3(1.55, 1.45, 1.15),
			rotation_y
		))
		_heritage_window_transforms.append(Transform3D(
			facing_basis,
			dormer_center + facing_basis * Vector3(0.0, 0.02, 0.61)
		))
		var dormer_pitch := deg_to_rad(38.0)
		var dormer_half_span := 0.95
		var dormer_rise := dormer_half_span * tan(dormer_pitch)
		var dormer_slope := dormer_half_span / cos(dormer_pitch)
		for roof_side in [-1.0, 1.0]:
			var roof_basis := facing_basis.rotated(
				facing_basis.z.normalized(),
				-float(roof_side) * dormer_pitch
			)
			roof_basis.x *= dormer_slope
			roof_basis.y *= 0.14
			roof_basis.z *= 1.55
			_house_dormer_roof_transforms.append(Transform3D(
				roof_basis,
				dormer_center
				+ facing_basis * Vector3(
					float(roof_side) * dormer_half_span * 0.5,
					0.78 + dormer_rise * 0.5,
					0.0
				)
			))

	if (
		cornish_style
		and style_seed % 2 == 0
		and node_name != "Boulangerie du Pont"
	):
		var vine_x := width * (-0.36 if style_seed % 4 == 0 else 0.36)
		var vine_height := minf(height - 0.7, 4.8)
		_house_vine_stem_transforms.append(_scaled_box_transform(
			grounded_at
			+ facing_basis * Vector3(vine_x, vine_height * 0.5, front_z + 0.12),
			Vector3(0.055, vine_height, 0.055),
			rotation_y
		))
		for leaf_index in 8:
			var leaf_height := 0.45 + float(leaf_index) * vine_height / 8.5
			var leaf_side := -1.0 if leaf_index % 2 == 0 else 1.0
			var leaf_position := (
				grounded_at
				+ facing_basis * Vector3(
					vine_x + leaf_side * (0.13 + float(leaf_index % 3) * 0.05),
					leaf_height,
					front_z + 0.15
				)
			)
			_house_vine_leaf_transforms.append(_scaled_sphere_transform(
				leaf_position,
				Vector3(0.16, 0.22, 0.1),
				rotation_y + float(leaf_index) * 0.7
			))


func _queue_window_planter(window_transform: Transform3D, seed_value: int) -> void:
	var planter_position := (
		window_transform.origin
		- window_transform.basis.y.normalized() * 0.68
		+ window_transform.basis.z.normalized() * 0.12
	)
	_house_planter_transforms.append(Transform3D(window_transform.basis, planter_position))
	for flower_index in 3:
		var flower_position := (
			planter_position
			+ window_transform.basis.x.normalized() * (float(flower_index) - 1.0) * 0.26
			+ window_transform.basis.y.normalized() * (0.16 + 0.04 * float(flower_index % 2))
			+ window_transform.basis.z.normalized() * 0.08
		)
		var flower_transform := _scaled_sphere_transform(
			flower_position,
			Vector3(0.13, 0.16, 0.13),
			float(seed_value + flower_index)
		)
		if (seed_value + flower_index) % 2 == 0:
			_house_planter_red_flower_transforms.append(flower_transform)
		else:
			_house_planter_yellow_flower_transforms.append(flower_transform)


func _scaled_box_transform(
	at: Vector3,
	size: Vector3,
	rotation_y: float
) -> Transform3D:
	return Transform3D(
		_basis_with_local_scale(rotation_y, size),
		at
	)


func _scaled_sphere_transform(
	at: Vector3,
	size: Vector3,
	rotation_y: float
) -> Transform3D:
	return Transform3D(
		_basis_with_local_scale(rotation_y, size),
		at
	)


func _scaled_cylinder_transform(
	at: Vector3,
	size: Vector3,
	rotation_y: float
) -> Transform3D:
	return Transform3D(
		_basis_with_local_scale(rotation_y, size),
		at
	)


func _basis_with_local_scale(rotation_y: float, size: Vector3) -> Basis:
	var basis := Basis(Vector3.UP, rotation_y)
	basis.x *= size.x
	basis.y *= size.y
	basis.z *= size.z
	return basis


func _footprint_height_range(
	at: Vector3,
	width: float,
	depth: float,
	rotation_y: float
) -> Vector2:
	var basis := Basis(Vector3.UP, rotation_y)
	var minimum_height := INF
	var maximum_height := -INF
	for x_weight in [-0.5, 0.0, 0.5]:
		for z_weight in [-0.5, 0.0, 0.5]:
			var offset := basis * Vector3(width * x_weight, 0.0, depth * z_weight)
			var sample_height := ground_height_at(at.x + offset.x, at.z + offset.z)
			minimum_height = minf(minimum_height, sample_height)
			maximum_height = maxf(maximum_height, sample_height)
	return Vector2(minimum_height, maximum_height)


func _make_gabled_roof(
	at: Vector3,
	width: float,
	depth: float,
	rotation_y: float,
	color: Color,
	gable_material: Material,
	pitch_degrees := 27.0
) -> void:
	var roof_root := Node3D.new()
	roof_root.name = "Gabled roof"
	roof_root.position = at
	roof_root.rotation.y = rotation_y
	roof_root.add_to_group("gabled_roof")
	roof_root.add_to_group("heritage_roof")
	add_child(roof_root)

	var pitch := deg_to_rad(pitch_degrees)
	var eave_overhang := 0.38
	var roof_width := width + eave_overhang * 2.0
	var roof_depth := depth + eave_overhang * 2.0
	var half_span := roof_depth * 0.5
	var roof_rise := half_span * tan(pitch)
	var eave_height := 0.14
	var slab_thickness := 0.22
	var slope_length := half_span / cos(pitch) + 0.08
	for side in [-1.0, 1.0]:
		var slab_mesh := BoxMesh.new()
		slab_mesh.size = Vector3(roof_width, slab_thickness, slope_length)
		var slab := MeshInstance3D.new()
		slab.name = "Roof slope"
		slab.position = Vector3(
			0.0,
			eave_height + roof_rise * 0.5,
			side * half_span * 0.5
		)
		slab.rotation.x = side * pitch
		slab.mesh = slab_mesh
		slab.material_override = _roof_material(color)
		roof_root.add_child(slab)

	var gable := MeshInstance3D.new()
	gable.name = "Filled gable ends"
	gable.mesh = _make_gable_end_mesh(width, depth, eave_height + roof_rise)
	gable.material_override = gable_material
	gable.add_to_group("roof_gable")
	roof_root.add_child(gable)
	roof_root.set_meta(
		"roof_clearance",
		eave_height - slab_thickness * 0.5 * cos(pitch)
	)


func _make_hipped_roof(
	at: Vector3,
	width: float,
	depth: float,
	rotation_y: float,
	color: Color,
	pitch_degrees := 29.0
) -> void:
	var roof_root := Node3D.new()
	roof_root.name = "Hipped roof"
	roof_root.position = at
	roof_root.rotation.y = rotation_y
	roof_root.add_to_group("hipped_roof")
	roof_root.add_to_group("heritage_roof")
	add_child(roof_root)

	var overhang := 0.4
	var half_width := width * 0.5 + overhang
	var half_depth := depth * 0.5 + overhang
	var eave_height := 0.13
	var roof_rise := half_depth * tan(deg_to_rad(pitch_degrees)) * 0.88
	var ridge_half := maxf(0.25, half_width - half_depth * 0.9)
	var back_left := Vector3(-half_width, eave_height, -half_depth)
	var back_right := Vector3(half_width, eave_height, -half_depth)
	var front_right := Vector3(half_width, eave_height, half_depth)
	var front_left := Vector3(-half_width, eave_height, half_depth)
	var ridge_left := Vector3(-ridge_half, eave_height + roof_rise, 0.0)
	var ridge_right := Vector3(ridge_half, eave_height + roof_rise, 0.0)
	var triangles := [
		[back_left, ridge_left, ridge_right],
		[back_left, ridge_right, back_right],
		[front_left, front_right, ridge_right],
		[front_left, ridge_right, ridge_left],
		[back_left, front_left, ridge_left],
		[back_right, ridge_right, front_right],
	]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle: Array in triangles:
		for vertex: Vector3 in triangle:
			surface.set_uv(Vector2(
				(vertex.x + half_width) / maxf(0.1, half_width * 2.0),
				(vertex.z + half_depth) / maxf(0.1, half_depth * 2.0)
			))
			surface.add_vertex(vertex)
	surface.generate_normals()
	surface.generate_tangents()
	var roof := MeshInstance3D.new()
	roof.name = "Four hipped roof planes"
	roof.mesh = surface.commit()
	roof.material_override = _roof_material(color)
	roof_root.add_child(roof)
	roof_root.set_meta("roof_clearance", eave_height)


func _make_gable_end_mesh(width: float, depth: float, height: float) -> ArrayMesh:
	var half_width := width * 0.5
	var half_depth := depth * 0.5
	var vertices := PackedVector3Array([
		Vector3(-half_width, -0.08, -half_depth),
		Vector3(-half_width, -0.08, half_depth),
		Vector3(-half_width, height, 0.0),
		Vector3(half_width, -0.08, half_depth),
		Vector3(half_width, -0.08, -half_depth),
		Vector3(half_width, height, 0.0),
	])
	var normals := PackedVector3Array([
		Vector3.LEFT,
		Vector3.LEFT,
		Vector3.LEFT,
		Vector3.RIGHT,
		Vector3.RIGHT,
		Vector3.RIGHT,
	])
	var tangents := PackedFloat32Array()
	for _vertex in vertices.size():
		tangents.append(0.0)
		tangents.append(0.0)
		tangents.append(1.0)
		tangents.append(1.0)
	var uvs := PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
		Vector2(0.5, 0.0),
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
		Vector2(0.5, 0.0),
	])
	var indices := PackedInt32Array([0, 2, 1, 3, 5, 4])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _make_tree(at: Vector3) -> void:
	var variant_index := absi(int(round(at.x * 3.0 + at.z * 5.0))) % 3
	var variant: String = ["tree_default", "tree_oak", "tree_pine"][variant_index]
	var scale := 3.0 + float(absi(int(round(at.x + at.z)))) * 0.013
	var phase := fposmod(at.x * 0.037 + at.z * 0.061, 1.0)
	var variation := 0.35 + 0.3 * fposmod(absf(at.x + at.z) * 0.071, 1.0)
	_queue_foliage(
		variant,
		at,
		minf(scale, 3.8),
		at.x * 0.17 + at.z * 0.11,
		1.0,
		Vector2.ZERO,
		Color(phase, variation, 0.8, 1.0)
	)


func _make_cherry_tree(at: Vector3) -> void:
	var phase := fposmod(at.x * 0.043 + at.z * 0.057, 1.0)
	var scale := 3.15 + 0.45 * fposmod(absf(at.x - at.z) * 0.093, 1.0)
	_queue_foliage(
		"tree_cherry",
		at,
		scale,
		at.x * -0.12 + at.z * 0.16,
		0.96,
		Vector2.ZERO,
		Color(phase, 0.48, 0.86, 1.0)
	)


func _make_foliage_pass() -> void:
	# These layers mirror a gardener's plant profiles: each species family has
	# its own spacing, density, scale, slope, and visual treatment. Jittered
	# cells keep the distribution organic without the collisions and empty
	# patches produced by unconstrained random scatter.

	# Courtyard planting softens the civic hill's leftover triangular parcels.
	# Clearance filtering keeps every trunk and planter outside the crooked
	# bike lanes and away from building foundations.
	_paint_foliage_biome(
		"Old town pocket gardens",
		Vector2(0.0, -2.0),
		Vector2(106.0, 104.0),
		2.35,
		0.31,
		[
			{"variant": "grass_leaf", "weight": 1.8},
			{"variant": "bush_small", "weight": 0.85},
			{"variant": "flower_yellow", "weight": 1.4},
			{"variant": "flower_purple", "weight": 1.1},
			{"variant": "dandelion_yellow", "weight": 0.65},
		],
		0xC1A1
	)
	_paint_foliage_biome(
		"Old town courtyard canopy",
		Vector2(0.0, -2.0),
		Vector2(104.0, 102.0),
		14.5,
		0.54,
		[
			{"variant": "tree_cherry", "weight": 2.2},
			{"variant": "tree_oak", "weight": 1.0},
		],
		0xC1A2,
		0.18
	)

	# Formal clipped hedges and flower drifts give the abbey garden a maintained
	# character before the vegetation becomes wilder at the edges.
	for z in range(1, 43, 3):
		var phase := fposmod(float(z) * 0.071, 1.0)
		_queue_foliage(
			"bush_small",
			Vector3(63.2, 0.0, float(z)),
			2.25,
			float(z) * 0.13,
			0.82,
			Vector2.ZERO,
			Color(phase, 0.48, 0.45, 1.0)
		)
		_queue_foliage(
			"bush_small",
			Vector3(84.8, 0.0, float(z)),
			2.25,
			float(z) * -0.11,
			0.82,
			Vector2.ZERO,
			Color(1.0 - phase, 0.52, 0.45, 1.0)
		)
	_paint_foliage_biome(
		"Abbey west flower bed",
		Vector2(68.4, 21.0),
		Vector2(7.1, 38.0),
		1.45,
		0.72,
		[
			{"variant": "grass", "weight": 1.0},
			{"variant": "flower_purple", "weight": 2.4},
			{"variant": "flower_red", "weight": 1.8},
			{"variant": "flower_yellow", "weight": 2.7},
		],
		0xABB3
	)
	_paint_foliage_biome(
		"Abbey east flower bed",
		Vector2(79.6, 21.0),
		Vector2(7.1, 38.0),
		1.45,
		0.72,
		[
			{"variant": "grass_leaf", "weight": 1.0},
			{"variant": "flower_purple", "weight": 2.1},
			{"variant": "flower_red", "weight": 2.5},
			{"variant": "flower_yellow", "weight": 1.9},
		],
		0xA8E4
	)

	# West-bank meadow: low vegetation forms broad drifts, while shrubs and
	# orchard trees retain their own larger spacing.
	_paint_foliage_biome(
		"West meadow groundcover",
		Vector2(-140.0, 20.0),
		Vector2(48.0, 190.0),
		2.2,
		0.34,
		[
			{"variant": "grass", "weight": 3.5},
			{"variant": "grass_leaf", "weight": 2.4},
			{"variant": "flower_yellow", "weight": 1.5},
			{"variant": "flower_purple", "weight": 0.7},
		],
		0x0C47
	)
	_paint_foliage_biome(
		"West dandelion drift",
		Vector2(-136.0, 42.0),
		Vector2(30.0, 44.0),
		1.35,
		0.58,
		[
			{"variant": "dandelion_yellow", "weight": 3.4},
			{"variant": "dandelion_seed", "weight": 1.0},
		],
		0xDA7D,
		0.42
	)
	_paint_foliage_biome(
		"West meadow shrubs",
		Vector2(-140.0, 20.0),
		Vector2(48.0, 190.0),
		4.6,
		0.42,
		[
			{"variant": "bush_small", "weight": 2.0},
			{"variant": "bush_detailed", "weight": 1.0},
		],
		0x0B59
	)
	_paint_foliage_biome(
		"West orchard canopy",
		Vector2(-140.0, 20.0),
		Vector2(48.0, 190.0),
		8.6,
		0.5,
		[
			{"variant": "tree_default", "weight": 1.4},
			{"variant": "tree_oak", "weight": 2.2},
			{"variant": "tree_cherry", "weight": 0.8},
		],
		0x0A63
	)

	# The east hillside is more wooded and conifer-heavy than the open orchard.
	_paint_foliage_biome(
		"East hillside groundcover",
		Vector2(140.0, 18.0),
		Vector2(48.0, 200.0),
		2.35,
		0.32,
		[
			{"variant": "grass", "weight": 2.0},
			{"variant": "grass_leaf", "weight": 3.2},
			{"variant": "flower_purple", "weight": 0.55},
		],
		0xE457
	)
	_paint_foliage_biome(
		"East dandelion drift",
		Vector2(132.0, -30.0),
		Vector2(28.0, 36.0),
		1.4,
		0.48,
		[
			{"variant": "dandelion_yellow", "weight": 3.0},
			{"variant": "dandelion_seed", "weight": 0.8},
		],
		0xD4E5,
		0.4
	)
	_paint_foliage_biome(
		"East hillside shrubs",
		Vector2(140.0, 18.0),
		Vector2(48.0, 200.0),
		4.25,
		0.5,
		[
			{"variant": "bush_small", "weight": 1.0},
			{"variant": "bush_detailed", "weight": 2.2},
		],
		0xE391
	)
	_paint_foliage_biome(
		"East hillside canopy",
		Vector2(140.0, 18.0),
		Vector2(48.0, 200.0),
		7.6,
		0.62,
		[
			{"variant": "tree_default", "weight": 0.8},
			{"variant": "tree_oak", "weight": 1.1},
			{"variant": "tree_pine", "weight": 2.5},
			{"variant": "tree_cherry", "weight": 0.35},
		],
		0xE2C1
	)

	# Moist river and canal verges are dense in grasses, with occasional
	# flowering plants. Road, bridge, building, water, and slope checks still
	# decide whether each projected placement is valid.
	_paint_foliage_biome(
		"North river verge",
		Vector2(0.0, -92.5),
		Vector2(310.0, 4.5),
		1.85,
		0.7,
		[
			{"variant": "grass", "weight": 2.7},
			{"variant": "grass_leaf", "weight": 3.4},
			{"variant": "flower_purple", "weight": 0.7},
			{"variant": "flower_yellow", "weight": 0.9},
		],
		0xB4A9
	)
	for canal_bank_x in [-63.5, -82.5]:
		_paint_foliage_biome(
			"Canal verge %.1f" % canal_bank_x,
			Vector2(canal_bank_x, 14.0),
			Vector2(3.2, 224.0),
			1.75,
			0.67,
			[
				{"variant": "grass", "weight": 2.5},
				{"variant": "grass_leaf", "weight": 3.0},
				{"variant": "flower_yellow", "weight": 0.55},
			],
			0xCA11 + int(canal_bank_x * 10.0)
		)

	# A light base layer now reaches beyond the named parks into residential
	# verges, vacant corners, quay edges, and the approaches between districts.
	# Denser biomes above still give parks a distinct identity.
	_paint_foliage_biome(
		"Island wide street verge mosaic",
		Vector2(0.0, -12.0),
		Vector2(392.0, 316.0),
		3.45,
		0.2,
		[
			{"variant": "grass", "weight": 2.5},
			{"variant": "grass_leaf", "weight": 2.0},
			{"variant": "bush_small", "weight": 0.42},
			{"variant": "flower_yellow", "weight": 0.75},
			{"variant": "flower_purple", "weight": 0.48},
			{"variant": "dandelion_yellow", "weight": 0.62},
		],
		0x157A
	)
	for coast_data in [
		[Vector2(-184.0, -16.0), Vector2(30.0, 286.0), 0xC071],
		[Vector2(184.0, -16.0), Vector2(30.0, 286.0), 0xC072],
		[Vector2(0.0, 137.0), Vector2(348.0, 22.0), 0xC073],
		[Vector2(0.0, -166.0), Vector2(330.0, 25.0), 0xC074],
	]:
		_paint_foliage_biome(
			"Coastal gorse %04x" % int(coast_data[2]),
			coast_data[0],
			coast_data[1],
			4.2,
			0.42,
			[
				{"variant": "bush_detailed", "weight": 2.5},
				{"variant": "bush_small", "weight": 1.4},
				{"variant": "grass_leaf", "weight": 1.8},
				{"variant": "flower_purple", "weight": 0.55},
				{"variant": "flower_yellow", "weight": 0.7},
			],
			int(coast_data[2])
		)


func _paint_foliage_biome(
	biome_name: String,
	center: Vector2,
	size: Vector2,
	spacing: float,
	coverage: float,
	species: Array,
	seed_value: int,
	edge_falloff := 0.0
) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var columns := maxi(1, ceili(size.x / spacing))
	var rows := maxi(1, ceili(size.y / spacing))
	var actual_step := Vector2(size.x / float(columns), size.y / float(rows))
	var jitter_fraction := 0.62
	var placed := 0
	for column in columns:
		for row in rows:
			var cell_center := Vector2(
				center.x - size.x * 0.5 + (float(column) + 0.5) * actual_step.x,
				center.y - size.y * 0.5 + (float(row) + 0.5) * actual_step.y
			)
			var jitter := Vector2(
				random.randf_range(-0.5, 0.5) * actual_step.x * jitter_fraction,
				random.randf_range(-0.5, 0.5) * actual_step.y * jitter_fraction
			)
			var point := cell_center + jitter
			var effective_coverage := coverage
			if edge_falloff > 0.0:
				var normalized_offset := Vector2(
					(point.x - center.x) / (size.x * 0.5),
					(point.y - center.y) / (size.y * 0.5)
				)
				var edge_distance := normalized_offset.length()
				if edge_distance >= 1.0:
					continue
				effective_coverage *= clampf(
					(1.0 - edge_distance) / edge_falloff,
					0.0,
					1.0
				)
			if random.randf() > effective_coverage:
				continue
			var variant := _pick_foliage_variant(random, species)
			var profile: Dictionary = FOLIAGE_PROFILES[variant]
			var position := Vector3(point.x, 0.0, point.y)
			var normal := _terrain_normal(position.x, position.z)
			var slope_degrees := rad_to_deg(acos(clampf(normal.dot(Vector3.UP), -1.0, 1.0)))
			if slope_degrees > float(profile.max_slope):
				continue
			var clearance := _foliage_clearance_for_variant(variant)
			if not _foliage_position_is_clear(position, clearance):
				continue
			if not _foliage_has_species_spacing(position, variant):
				continue
			var scale_range: Vector2 = profile.scale
			var vertical_range: Vector2 = profile.vertical_scale
			var scale := random.randf_range(scale_range.x, scale_range.y)
			var vertical_scale := random.randf_range(vertical_range.x, vertical_range.y)
			var max_tilt: float = profile.tilt
			var tilt := Vector2(
				random.randf_range(-max_tilt, max_tilt),
				random.randf_range(-max_tilt, max_tilt)
			)
			var custom_data := Color(
				random.randf(),
				random.randf_range(0.18, 0.82),
				random.randf_range(0.72, 1.0),
				1.0
			)
			_queue_foliage(
				variant,
				position,
				scale,
				random.randf_range(0.0, TAU),
				vertical_scale,
				tilt,
				custom_data
			)
			placed += 1
	var metadata_key := biome_name.to_snake_case().replace(".", "_").replace("-", "minus_")
	set_meta("foliage_biome_%s" % metadata_key, placed)


func _pick_foliage_variant(random: RandomNumberGenerator, species: Array) -> String:
	var total_weight := 0.0
	for entry: Dictionary in species:
		total_weight += float(entry.weight)
	var choice := random.randf_range(0.0, total_weight)
	for entry: Dictionary in species:
		choice -= float(entry.weight)
		if choice <= 0.0:
			return str(entry.variant)
	return str((species.back() as Dictionary).variant)


func _foliage_has_species_spacing(at: Vector3, variant: String) -> bool:
	var point := Vector2(at.x, at.z)
	if variant.begins_with("tree_"):
		for existing: Vector2 in _foliage_tree_positions:
			if point.distance_squared_to(existing) < 20.25:
				return false
	elif variant.begins_with("bush_"):
		for existing: Vector2 in _foliage_shrub_positions:
			if point.distance_squared_to(existing) < 1.96:
				return false
	return true


func _foliage_position_is_clear(at: Vector3, margin: float) -> bool:
	if at.x < WORLD_MIN_X + 2.0 or at.x > WORLD_MAX_X - 2.0:
		return false
	if at.z < WORLD_MIN_Z + 2.0 or at.z > WORLD_MAX_Z - 2.0:
		return false
	if ground_height_at(at.x, at.z) < WATER_LEVEL - 0.1:
		return false
	var point := Vector2(at.x, at.z)
	for corridor in _road_corridors:
		if _distance_to_segment_2d(point, corridor.from, corridor.to) < corridor.radius + margin:
			return false
	for clearing in _obstacle_clearings:
		if point.distance_to(Vector2(clearing.x, clearing.y)) < clearing.z + margin:
			return false
	return true


func _queue_foliage(
	variant: String,
	at: Vector3,
	scale: float,
	rotation_y: float,
	vertical_scale := 1.0,
	tilt := Vector2.ZERO,
	custom_data := Color(0.0, 0.5, 0.85, 1.0)
) -> void:
	if not _foliage_transforms.has(variant):
		return
	if not _foliage_position_is_clear(at, _foliage_clearance_for_variant(variant)):
		return
	var grounded_at := at
	grounded_at.y = ground_height_at(at.x, at.z)
	var basis := Basis.IDENTITY.rotated(Vector3.UP, rotation_y)
	basis = basis.rotated(Vector3.RIGHT, tilt.x)
	basis = basis.rotated(Vector3.FORWARD, tilt.y)
	basis = basis.scaled(Vector3(scale, scale * vertical_scale, scale))
	var transforms: Array = _foliage_transforms[variant]
	transforms.append(Transform3D(basis, grounded_at))
	var instance_data: Array = _foliage_custom_data[variant]
	instance_data.append(custom_data)
	var point := Vector2(grounded_at.x, grounded_at.z)
	if variant.begins_with("tree_"):
		_foliage_tree_positions.append(point)
	elif variant.begins_with("bush_"):
		_foliage_shrub_positions.append(point)


func _foliage_clearance_for_variant(variant: String) -> float:
	if variant.begins_with("tree_"):
		return 2.8
	if variant.begins_with("bush_"):
		return 1.15
	return 0.55


func _register_road_corridor(
	from: Vector3,
	to: Vector3,
	outer_width: float,
	drivable_width: float
) -> void:
	var from_2d := Vector2(from.x, from.z)
	var to_2d := Vector2(to.x, to.z)
	var radius := outer_width * 0.5
	var drivable_radius := drivable_width * 0.5
	for corridor: Dictionary in _road_corridors:
		if (
			(corridor.from as Vector2).is_equal_approx(from_2d)
			and (corridor.to as Vector2).is_equal_approx(to_2d)
			and is_equal_approx(float(corridor.radius), radius)
			and is_equal_approx(float(corridor.drivable_radius), drivable_radius)
		):
			return
	_road_corridors.append({
		"from": from_2d,
		"to": to_2d,
		"radius": radius,
		"drivable_radius": drivable_radius,
		"from_height": _natural_ground_height_at(from.x, from.z),
		"to_height": _natural_ground_height_at(to.x, to.z),
	})


func road_surface_clearance_at(at: Vector3) -> float:
	var point := Vector2(at.x, at.z)
	var clearance := INF
	for corridor: Dictionary in _road_corridors:
		clearance = minf(
			clearance,
			_distance_to_segment_2d(point, corridor.from, corridor.to)
			- float(corridor.drivable_radius)
		)
	return clearance


func _distance_to_segment_2d(point: Vector2, from: Vector2, to: Vector2) -> float:
	var segment := to - from
	if segment.is_zero_approx():
		return point.distance_to(from)
	var weight := clampf((point - from).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(from.lerp(to, weight))


func _make_modern_road(
	node_name: String,
	from: Vector3,
	to: Vector3,
	width: float,
	marking_trim_from := 0.0,
	marking_trim_to := 0.0
) -> void:
	_register_road_corridor(from, to, width + 3.0, width)
	if _road_plan_only:
		return
	_make_flat_segment(node_name + " sidewalk", from, to, width + 3.0, SIDEWALK, 0.055)
	_make_flat_segment(node_name, from, to, width, ASPHALT, 0.085)
	var flat_direction := Vector3(to.x - from.x, 0.0, to.z - from.z).normalized()
	var marked_from := from + flat_direction * marking_trim_from
	var marked_to := to - flat_direction * marking_trim_to
	if Vector2(
		marked_to.x - marked_from.x,
		marked_to.z - marked_from.z
	).length() < 0.5:
		return
	_make_flat_segment(
		node_name + " center line",
		marked_from,
		marked_to,
		0.14,
		Color("e2e1d8"),
		0.118
	)
	var side := Vector3(-flat_direction.z, 0.0, flat_direction.x)
	var lane_offset := width * 0.5 - 1.05
	for direction: float in [-1.0, 1.0]:
		var offset: Vector3 = side * lane_offset * direction
		_make_flat_segment(
			node_name + " cycle track",
			marked_from + offset,
			marked_to + offset,
			1.65,
			CYCLE_RED,
			0.135
		)


func _make_cobble_road(node_name: String, from: Vector3, to: Vector3, width: float) -> void:
	_register_road_corridor(from, to, width + 1.2, width)
	if _road_plan_only:
		return
	_make_flat_segment(
		node_name + " edge",
		from,
		to,
		width + 1.2,
		COBBLE.lightened(0.08),
		0.06
	)
	_make_flat_segment(node_name, from, to, width, COBBLE, 0.095)


func _make_modern_path(node_name: String, points: Array[Vector3], width: float) -> void:
	points = _fillet_road_path(points)
	for index in points.size() - 1:
		_register_road_corridor(
			points[index],
			points[index + 1],
			width + 3.0,
			width
		)
	# A polyline elbow needs one owner for both its grading and its visible top
	# surface. Independent ribbons are otherwise free to expose their sidewalk
	# layer through the acute inside corner, especially on sloping coast roads.
	for index in range(1, points.size() - 1):
		if _path_turn_angle(points, index) < deg_to_rad(20.0):
			continue
		_register_road_corridor(
			points[index],
			points[index],
			(width + 3.0) * 1.18,
			width * 1.18
		)
	if _road_plan_only:
		return
	var samples := _sample_polyline(points, 3.5)
	_make_terrain_ribbon(node_name + " sidewalk", samples, width + 3.0, 0.0, SIDEWALK, 0.07)
	_make_terrain_ribbon(node_name, samples, width, 0.0, ASPHALT, 0.105)
	_make_terrain_ribbon(
		node_name + " center line",
		samples,
		0.14,
		0.0,
		Color("e2e1d8"),
		0.135
	)
	var lane_offset := width * 0.5 - 1.05
	for direction: float in [-1.0, 1.0]:
		_make_terrain_ribbon(
			node_name + " cycle track",
			samples,
			1.65,
			lane_offset * direction,
			CYCLE_RED,
			0.15
		)
	for index in range(1, points.size() - 1):
		if _path_turn_angle(points, index) < deg_to_rad(20.0):
			continue
		var bend := points[index]
		var sidewalk := _make_terrain_disc(
			node_name + " bend sidewalk",
			bend,
			(width + 3.0) * 0.59,
			SIDEWALK,
			0.18
		)
		var roadway := _make_terrain_disc(
			node_name + " bend roadway",
			bend,
			width * 0.59,
			ASPHALT,
			0.215
		)
		sidewalk.add_to_group("clean_road_bend")
		roadway.add_to_group("clean_road_bend")


func _path_turn_angle(points: Array[Vector3], index: int) -> float:
	if index <= 0 or index >= points.size() - 1:
		return 0.0
	var incoming := Vector2(
		points[index].x - points[index - 1].x,
		points[index].z - points[index - 1].z
	).normalized()
	var outgoing := Vector2(
		points[index + 1].x - points[index].x,
		points[index + 1].z - points[index].z
	).normalized()
	if incoming.is_zero_approx() or outgoing.is_zero_approx():
		return 0.0
	return acos(clampf(incoming.dot(outgoing), -1.0, 1.0))


func _make_cobble_path(node_name: String, points: Array[Vector3], width: float) -> void:
	for index in points.size() - 1:
		_register_road_corridor(
			points[index],
			points[index + 1],
			width + 1.2,
			width
		)
	if _road_plan_only:
		return
	# One continuous ribbon gives the old streets smooth mitred bends. Drawing
	# every leg as a separate rectangle leaves overlapping wedges and visible
	# seams exactly where a crooked medieval street should look most natural.
	var samples := _sample_polyline(points, 2.5)
	_make_terrain_ribbon(
		node_name + " edge",
		samples,
		width + 1.2,
		0.0,
		COBBLE.lightened(0.08),
		0.06
	)
	_make_terrain_ribbon(node_name, samples, width, 0.0, COBBLE, 0.095)


func _make_flat_segment(
	node_name: String,
	from: Vector3,
	to: Vector3,
	width: float,
	color: Color,
	y: float
) -> void:
	var points: Array[Vector3] = [from, to]
	_make_terrain_ribbon(
		node_name,
		_sample_polyline(points, 3.5),
		width,
		0.0,
		color,
		y
	)


func _sample_polyline(points: Array[Vector3], spacing: float) -> Array[Vector3]:
	var samples: Array[Vector3] = []
	if points.is_empty():
		return samples
	for index in points.size() - 1:
		var from := points[index]
		var to := points[index + 1]
		var distance := Vector2(to.x - from.x, to.z - from.z).length()
		var steps := maxi(1, int(ceil(distance / spacing)))
		for step in steps:
			samples.append(from.lerp(to, float(step) / float(steps)))
	samples.append(points[-1])
	return samples


func _make_terrain_ribbon(
	node_name: String,
	samples: Array[Vector3],
	width: float,
	center_offset: float,
	color: Color,
	height_offset: float
) -> void:
	if color.is_equal_approx(SIDEWALK):
		height_offset = 0.045
	if samples.size() < 2:
		return
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var distance_along := 0.0
	var across_segments := maxi(2, int(ceil(width / 1.5)))
	var row_size := across_segments + 1

	for index in samples.size():
		var previous := samples[maxi(0, index - 1)]
		var following := samples[mini(samples.size() - 1, index + 1)]
		var tangent := Vector3(
			following.x - previous.x,
			0.0,
			following.z - previous.z
		).normalized()
		var join_side := _ribbon_join_side(samples, index)
		var side := join_side.normalized()
		var center := samples[index] + join_side * center_offset
		if index > 0:
			distance_along += Vector2(
				samples[index].x - samples[index - 1].x,
				samples[index].z - samples[index - 1].z
			).length()
		for across in row_size:
			var across_weight := float(across) / float(across_segments)
			var vertex := center + join_side * (across_weight - 0.5) * width
			vertex.y = ground_height_at(vertex.x, vertex.z) + height_offset
			vertices.append(vertex)
			normals.append(Vector3.UP)
			tangents.append(side.x)
			tangents.append(side.y)
			tangents.append(side.z)
			tangents.append(1.0)
			uvs.append(Vector2(
				(across_weight - 0.5) * width / 3.2,
				distance_along / 3.2
			))

	for index in samples.size() - 1:
		for across in across_segments:
			var current := index * row_size + across
			var current_next := current + 1
			var following := current + row_size
			var following_next := following + 1
			indices.append(current)
			indices.append(following)
			indices.append(current_next)
			indices.append(current_next)
			indices.append(following)
			indices.append(following_next)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _conform_road_arrays(arrays, height_offset))
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = _surface_material(color)
	# These thin meshes behave as terrain decals. Letting them cast directional
	# shadows turns their small height offsets into long black wedges at joins.
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _is_textured_surface_color(color):
		instance.add_to_group("textured_road")
	add_child(instance)


func _ribbon_join_side(samples: Array[Vector3], index: int) -> Vector3:
	var current := samples[index]
	var incoming := Vector3.ZERO
	var outgoing := Vector3.ZERO
	if index > 0:
		incoming = Vector3(
			current.x - samples[index - 1].x,
			0.0,
			current.z - samples[index - 1].z
		).normalized()
	if index + 1 < samples.size():
		outgoing = Vector3(
			samples[index + 1].x - current.x,
			0.0,
			samples[index + 1].z - current.z
		).normalized()
	if incoming.is_zero_approx():
		incoming = outgoing
	if outgoing.is_zero_approx():
		outgoing = incoming
	var incoming_side := Vector3(-incoming.z, 0.0, incoming.x)
	var outgoing_side := Vector3(-outgoing.z, 0.0, outgoing.x)
	var combined := incoming_side + outgoing_side
	if combined.length_squared() < 0.001:
		return outgoing_side
	var miter := combined.normalized()
	var projection := absf(miter.dot(outgoing_side))
	# A true miter keeps every nested road layer aligned around a bend. Limit
	# very acute corners so an almost-reversing polyline cannot create a spike.
	var miter_length := minf(1.0 / maxf(projection, 0.35), 1.8)
	return miter * miter_length


func _make_terrain_polygon(
	node_name: String,
	points: Array,
	color: Color,
	height_offset: float
) -> MeshInstance3D:
	if color.is_equal_approx(SIDEWALK):
		height_offset = 0.045
	var center := Vector2.ZERO
	for point: Vector2 in points:
		center += point
	center /= float(maxi(points.size(), 1))
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var center_vertex := Vector3(
		center.x,
		ground_height_at(center.x, center.y) + height_offset,
		center.y
	)
	vertices.append(center_vertex)
	normals.append(_terrain_normal(center.x, center.y))
	uvs.append(center / 3.2)
	for point: Vector2 in points:
		vertices.append(Vector3(
			point.x,
			ground_height_at(point.x, point.y) + height_offset,
			point.y
		))
		normals.append(_terrain_normal(point.x, point.y))
		uvs.append(point / 3.2)
	for index in points.size():
		indices.append(0)
		indices.append(index + 1)
		indices.append((index + 1) % points.size() + 1)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _conform_road_arrays(arrays, height_offset))
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = _surface_material(color)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance


func _make_old_town_junction_paving() -> void:
	var junctions := [
		[Vector2(-44.0, 48.0), 5.0],
		[Vector2(44.0, 48.0), 5.0],
		[Vector2(-48.0, -54.0), 5.0],
		[Vector2(48.0, -54.0), 5.0],
		[Vector2(-30.0, 20.0), 4.4],
		[Vector2(28.0, 16.0), 4.4],
		[Vector2(-27.0, -31.0), 4.1],
		[Vector2(17.0, -30.0), 4.1],
		[Vector2(-1.0, 20.0), 5.2],
	]
	for index in junctions.size():
		var center: Vector2 = junctions[index][0]
		var radius: float = junctions[index][1]
		var points: Array[Vector2] = []
		for point_index in 14:
			var angle := TAU * float(point_index) / 14.0
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		var paving := _make_terrain_polygon(
			"Old town cobble junction %02d" % index,
			points,
			COBBLE,
			0.135
		)
		paving.add_to_group("old_town_cobble_junction")


func _make_road_junctions() -> void:
	var simple_junctions: Array[Vector3] = [
		Vector3(0.0, 0.0, 124.0),
		Vector3(0.0, 0.0, 78.0),
		Vector3(-104.0, 0.0, -54.0),
		Vector3(104.0, 0.0, -54.0),
		Vector3(58.0, 0.0, 78.0),
		Vector3(58.0, 0.0, -54.0),
		Vector3(58.0, 0.0, -82.0),
		Vector3(0.0, 0.0, -82.0),
		Vector3(92.0, 0.0, -82.0),
		Vector3(-152.0, 0.0, -82.0),
		Vector3(152.0, 0.0, -82.0),
		Vector3(-132.0, 0.0, 18.0),
		Vector3(-144.0, 0.0, 4.0),
	]
	var gateway_junctions: Array[Dictionary] = [
		{
			"name": "Orchard gateway",
			"position": Vector3(-122.0, 0.0, 78.0),
			"sidewalk_inner": 9.95,
			"sidewalk_outer": 12.2,
			"cycle_inner": 7.95,
			"cycle_outer": 10.25,
			"roadway_radius": 8.15,
			"show_cycle_ring": true,
		},
		{
			"name": "Hill gateway",
			"position": Vector3(118.0, 0.0, 78.0),
			"sidewalk_inner": 9.95,
			"sidewalk_outer": 12.2,
			"cycle_inner": 7.95,
			"cycle_outer": 10.25,
			"roadway_radius": 8.15,
			"show_cycle_ring": true,
		},
		{
			"name": "East coast cycle gateway",
			"position": Vector3(191.0, 0.0, -58.0),
			"sidewalk_inner": 8.85,
			"sidewalk_outer": 10.8,
			"cycle_inner": 0.0,
			"cycle_outer": 0.0,
			"roadway_radius": 9.05,
			"show_cycle_ring": false,
		},
	]
	var priority_merges: Array[Vector3] = [
		Vector3(-28.0, 0.0, -132.0),
		Vector3(70.0, 0.0, -133.0),
		Vector3(98.0, 0.0, -130.0),
		Vector3(124.0, 0.0, 101.0),
	]
	var orchard_merge := Vector3(-128.0, 0.0, 117.0)
	var orchard_merge_arms: Array[Vector3] = [
		Vector3(-137.0, 0.0, 96.0),
		Vector3(-162.0, 0.0, 96.0),
		Vector3(-82.0, 0.0, 122.75),
	]

	if _road_plan_only:
		for position in simple_junctions:
			_register_road_corridor(position, position, 13.4, 10.4)
		for junction: Dictionary in gateway_junctions:
			var position: Vector3 = junction.position
			_register_road_corridor(
				position,
				position,
				float(junction.sidewalk_outer) * 2.0,
				float(junction.roadway_radius) * 2.0
			)
		for position in priority_merges:
			_register_road_corridor(position, position, 18.4, 15.1)
		# This is a shallow Y rather than an ordinary crossing. Its two western
		# arms overlap for roughly fifteen metres before visibly separating.
		_register_road_corridor(orchard_merge, orchard_merge, 38.0, 32.0)
		return

	for position in simple_junctions:
		_make_terrain_disc("Junction sidewalk", position, 6.7, SIDEWALK, 0.18)
		_make_terrain_disc("Junction", position, 5.2, ASPHALT, 0.215)

	# Several full road profiles meet at each of these gateways. Letting their
	# independently triangulated sidewalk and cycle-track ribbons overlap made
	# large spikes and patchwork wedges. Raised, concentric aprons cover those
	# raw ends with one continuous junction; inland gateways keep a cycle ring,
	# while the narrow coastal junction uses a quieter asphalt turning apron.
	for junction: Dictionary in gateway_junctions:
		var junction_name: String = junction.name
		var position: Vector3 = junction.position
		_register_road_corridor(
			position,
			position,
			float(junction.sidewalk_outer) * 2.0,
			float(junction.roadway_radius) * 2.0
		)
		var sidewalk := _make_terrain_ring(
			junction_name + " sidewalk apron",
			position,
			float(junction.sidewalk_inner),
			float(junction.sidewalk_outer),
			SIDEWALK,
			0.08
		)
		var cycle_ring: MeshInstance3D
		if bool(junction.show_cycle_ring):
			cycle_ring = _make_terrain_ring(
				junction_name + " cycle apron",
				position,
				float(junction.cycle_inner),
				float(junction.cycle_outer),
				CYCLE_RED,
				0.14
			)
		var roadway := _make_terrain_disc(
			junction_name + " roadway apron",
			position,
			float(junction.roadway_radius),
			ASPHALT,
			0.16
		)
		sidewalk.add_to_group("clean_gateway_junction")
		if cycle_ring != null:
			cycle_ring.add_to_group("clean_gateway_junction")
		roadway.add_to_group("clean_gateway_junction")

	# These are acute bridge-to-promenade merges rather than right-angle
	# crossings. A larger raised apron masks the overlapping sidewalk, lane,
	# and marking ribbons and leaves one unambiguous rideable surface.
	for position in priority_merges:
		var sidewalk := _make_terrain_disc(
			"Priority merge sidewalk",
			position,
			9.2,
			SIDEWALK,
			0.185
		)
		var roadway := _make_terrain_disc(
			"Priority merge roadway",
			position,
			7.55,
			ASPHALT,
			0.225
		)
		var merge_group := (
			"clean_coastal_merge"
			if position.is_equal_approx(Vector3(124.0, 0.0, 101.0))
			else "clean_road_merge"
		)
		sidewalk.add_to_group(merge_group)
		roadway.add_to_group(merge_group)
	var orchard_sidewalk := _make_terrain_merge_apron(
		"Orchard coast merge sidewalk",
		orchard_merge,
		orchard_merge_arms,
		15.5,
		6.1,
		SIDEWALK,
		0.19
	)
	var orchard_roadway := _make_terrain_merge_apron(
		"Orchard coast merge roadway",
		orchard_merge,
		orchard_merge_arms,
		15.5,
		4.65,
		ASPHALT,
		0.235
	)
	orchard_sidewalk.add_to_group("clean_coastal_merge")
	orchard_roadway.add_to_group("clean_coastal_merge")
	_make_priority_merge_path(
		"North bank western merge",
		[
			Vector3(-50.0, 0.0, -134.13),
			Vector3(-28.0, 0.0, -132.0),
			Vector3(-6.0, 0.0, -133.33),
		],
		9.0
	)
	_make_priority_merge_path(
		"North bank eastern merge",
		[
			Vector3(78.0, 0.0, -132.0),
			Vector3(98.0, 0.0, -130.0),
			Vector3(118.0, 0.0, -126.54),
		],
		9.0
	)


func _make_terrain_merge_apron(
	node_name: String,
	center: Vector3,
	arms: Array[Vector3],
	reach: float,
	half_width: float,
	color: Color,
	height_offset: float
) -> MeshInstance3D:
	var center_2d := Vector2(center.x, center.z)
	var corners := PackedVector2Array()
	for arm in arms:
		var arm_offset := Vector2(arm.x, arm.z) - center_2d
		if arm_offset.is_zero_approx():
			continue
		var direction := arm_offset.normalized()
		var side := Vector2(-direction.y, direction.x)
		var arm_reach := minf(reach, arm_offset.length())
		corners.append(center_2d + side * half_width)
		corners.append(center_2d - side * half_width)
		corners.append(center_2d + direction * arm_reach + side * half_width)
		corners.append(center_2d + direction * arm_reach - side * half_width)
	var hull := Geometry2D.convex_hull(corners)
	var polygon_points: Array[Vector2] = []
	for point in hull:
		polygon_points.append(point)
	return _make_terrain_polygon(node_name, polygon_points, color, height_offset)


func _make_priority_merge_path(
	node_name: String,
	points: Array[Vector3],
	width: float
) -> void:
	var samples := _sample_polyline(points, 2.5)
	_make_terrain_ribbon(node_name, samples, width, 0.0, ASPHALT, 0.255)
	_make_terrain_ribbon(
		node_name + " center line",
		samples,
		0.14,
		0.0,
		Color("e2e1d8"),
		0.282
	)
	var lane_offset := width * 0.5 - 1.05
	for direction: float in [-1.0, 1.0]:
		_make_terrain_ribbon(
			node_name + " cycle track",
			samples,
			1.65,
			lane_offset * direction,
			CYCLE_RED,
			0.295
		)


func _make_terrain_disc(
	node_name: String,
	center: Vector3,
	radius: float,
	color: Color,
	height_offset: float
) -> MeshInstance3D:
	if color.is_equal_approx(SIDEWALK):
		height_offset = 0.045
	var radial_segments := 64
	var rings := maxi(2, int(ceil(radius / 1.5)))
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var center_vertex := center
	center_vertex.y = ground_height_at(center.x, center.z) + height_offset
	vertices.append(center_vertex)
	normals.append(Vector3.UP)
	tangents.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 1.0]))
	uvs.append(Vector2(center.x, center.z) / 3.2)

	for ring in rings:
		var ring_radius := radius * float(ring + 1) / float(rings)
		for segment in radial_segments:
			var angle := TAU * float(segment) / float(radial_segments)
			var vertex := center + Vector3(cos(angle), 0.0, sin(angle)) * ring_radius
			vertex.y = ground_height_at(vertex.x, vertex.z) + height_offset
			vertices.append(vertex)
			normals.append(Vector3.UP)
			tangents.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 1.0]))
			uvs.append(Vector2(vertex.x, vertex.z) / 3.2)

	for segment in radial_segments:
		var current := 1 + segment
		var following := 1 + (segment + 1) % radial_segments
		indices.append(0)
		indices.append(current)
		indices.append(following)

	for ring in rings - 1:
		var inner_start := 1 + ring * radial_segments
		var outer_start := inner_start + radial_segments
		for segment in radial_segments:
			var next_segment := (segment + 1) % radial_segments
			var inner_current := inner_start + segment
			var inner_next := inner_start + next_segment
			var outer_current := outer_start + segment
			var outer_next := outer_start + next_segment
			indices.append(inner_current)
			indices.append(outer_current)
			indices.append(inner_next)
			indices.append(inner_next)
			indices.append(outer_current)
			indices.append(outer_next)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _conform_road_arrays(arrays, height_offset))
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = _surface_material(color)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _is_textured_surface_color(color):
		instance.add_to_group("textured_road")
	add_child(instance)
	return instance


func _make_terrain_ring(
	node_name: String,
	center: Vector3,
	inner_radius: float,
	outer_radius: float,
	color: Color,
	height_offset: float
) -> MeshInstance3D:
	if color.is_equal_approx(SIDEWALK):
		height_offset = 0.045
	var radial_segments := 48
	var radial_rings := maxi(2, int(ceil((outer_radius - inner_radius) / 0.75)))
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for ring in radial_rings + 1:
		var ring_weight := float(ring) / float(radial_rings)
		var ring_radius := lerpf(inner_radius, outer_radius, ring_weight)
		for segment in radial_segments:
			var angle := TAU * float(segment) / float(radial_segments)
			var vertex := center + Vector3(cos(angle), 0.0, sin(angle)) * ring_radius
			vertex.y = ground_height_at(vertex.x, vertex.z) + height_offset
			vertices.append(vertex)
			normals.append(Vector3.UP)
			tangents.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 1.0]))
			uvs.append(Vector2(vertex.x, vertex.z) / 3.2)

	for ring in radial_rings:
		var inner_start := ring * radial_segments
		var outer_start := (ring + 1) * radial_segments
		for segment in radial_segments:
			var next_segment := (segment + 1) % radial_segments
			var inner_current := inner_start + segment
			var inner_next := inner_start + next_segment
			var outer_current := outer_start + segment
			var outer_next := outer_start + next_segment
			indices.append(inner_current)
			indices.append(outer_current)
			indices.append(inner_next)
			indices.append(inner_next)
			indices.append(outer_current)
			indices.append(outer_next)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _conform_road_arrays(arrays, height_offset))
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = _surface_material(color)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _is_textured_surface_color(color):
		instance.add_to_group("textured_road")
	add_child(instance)
	return instance


func _make_visual_surface_segment(
	node_name: String,
	from: Vector3,
	to: Vector3,
	width: float,
	thickness: float,
	color: Color
) -> MeshInstance3D:
	var delta := to - from
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, thickness, delta.length())
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = (from + to) * 0.5
	instance.basis = _surface_basis(delta)
	instance.mesh = mesh
	instance.material_override = _material(color)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance


func _surface_basis(delta: Vector3) -> Basis:
	var forward := delta.normalized()
	var right := Vector3.UP.cross(forward).normalized()
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	var up := forward.cross(right).normalized()
	return Basis(right, up, forward)


func _flush_decoration_batches() -> void:
	_make_box_multimesh(
		"Heritage windows",
		Vector3(0.95, 1.15, 0.09),
		_heritage_window_transforms,
		Color("456270")
	)
	var window_frame_verticals: Array[Transform3D] = []
	var window_frame_horizontals: Array[Transform3D] = []
	var window_mullion_verticals: Array[Transform3D] = []
	var window_mullion_horizontals: Array[Transform3D] = []
	for window_transform: Transform3D in _heritage_window_transforms:
		var x_axis := window_transform.basis.x.normalized()
		var y_axis := window_transform.basis.y.normalized()
		var z_axis := window_transform.basis.z.normalized()
		for side in [-1.0, 1.0]:
			window_frame_verticals.append(Transform3D(
				window_transform.basis,
				window_transform.origin + x_axis * float(side) * 0.53 + z_axis * 0.045
			))
			window_frame_horizontals.append(Transform3D(
				window_transform.basis,
				window_transform.origin + y_axis * float(side) * 0.63 + z_axis * 0.045
			))
		window_mullion_verticals.append(Transform3D(
			window_transform.basis,
			window_transform.origin + z_axis * 0.055
		))
		window_mullion_horizontals.append(Transform3D(
			window_transform.basis,
			window_transform.origin + z_axis * 0.06
		))
	_make_box_multimesh(
		"Heritage window side frames",
		Vector3(0.095, 1.32, 0.12),
		window_frame_verticals,
		Color("d8d0bd")
	)
	_make_box_multimesh(
		"Heritage window lintels and sills",
		Vector3(1.15, 0.095, 0.12),
		window_frame_horizontals,
		Color("d8d0bd")
	)
	_make_box_multimesh(
		"Heritage window vertical mullions",
		Vector3(0.055, 1.12, 0.125),
		window_mullion_verticals,
		Color("d5cdb9")
	)
	_make_box_multimesh(
		"Heritage window horizontal mullions",
		Vector3(0.92, 0.055, 0.13),
		window_mullion_horizontals,
		Color("d5cdb9")
	)
	_make_box_multimesh(
		"Heritage doors",
		Vector3(1.15, 2.2, 0.12),
		_heritage_door_transforms,
		Color("543c31")
	)
	var door_side_frames: Array[Transform3D] = []
	var door_lintels: Array[Transform3D] = []
	for door_transform: Transform3D in _heritage_door_transforms:
		var x_axis := door_transform.basis.x.normalized()
		var y_axis := door_transform.basis.y.normalized()
		var z_axis := door_transform.basis.z.normalized()
		for side in [-1.0, 1.0]:
			door_side_frames.append(Transform3D(
				door_transform.basis,
				door_transform.origin + x_axis * float(side) * 0.66 + z_axis * 0.055
			))
		door_lintels.append(Transform3D(
			door_transform.basis,
			door_transform.origin + y_axis * 1.19 + z_axis * 0.055
		))
	_make_box_multimesh(
		"Heritage door stone surrounds",
		Vector3(0.16, 2.48, 0.16),
		door_side_frames,
		Color("b9ad96")
	)
	_make_box_multimesh(
		"Heritage door lintels",
		Vector3(1.48, 0.18, 0.16),
		door_lintels,
		Color("b9ad96")
	)

	var architectural_batches := [
		_make_unit_box_multimesh(
			"Weathered facade cornices",
			_house_trim_transforms,
			Color("c6b99f")
		),
		_make_unit_box_multimesh(
			"Prague facade pilasters",
			_house_pilaster_transforms,
			Color("b9aa8f")
		),
		_make_unit_box_multimesh(
			"House rain downpipes",
			_house_downpipe_transforms,
			Color("343b3b")
		),
		_make_unit_box_multimesh(
			"House chimneys",
			_house_chimney_transforms,
			Color("6f6458"),
			_stone_material(Color("807568"))
		),
		_make_unit_cylinder_multimesh(
			"Terracotta chimney pots",
			_house_chimney_pot_transforms,
			Color("864b39")
		),
		_make_unit_box_multimesh(
			"Prague and Cornwall dormers",
			_house_dormer_wall_transforms,
			Color("c8b48f"),
			_facade_material(Color("c8b48f"))
		),
		_make_unit_box_multimesh(
			"Dormer slate roofs",
			_house_dormer_roof_transforms,
			SLATE,
			_roof_material(SLATE)
		),
	]
	for architecture_batch: MultiMeshInstance3D in architectural_batches:
		if architecture_batch != null:
			architecture_batch.add_to_group("heritage_architecture_detail")

	_make_box_multimesh(
		"Cornish window boxes",
		Vector3(0.86, 0.19, 0.28),
		_house_planter_transforms,
		Color("674b37")
	)
	var facade_vegetation_batches := [
		_make_unit_sphere_multimesh(
			"Window box red flowers",
			_house_planter_red_flower_transforms,
			Color("a3424c")
		),
		_make_unit_sphere_multimesh(
			"Window box yellow flowers",
			_house_planter_yellow_flower_transforms,
			Color("d7ad43")
		),
		_make_unit_box_multimesh(
			"Cottage climbing stems",
			_house_vine_stem_transforms,
			Color("385d35")
		),
		_make_unit_leaf_multimesh(
			"Cottage climbing leaves",
			_house_vine_leaf_transforms,
			Color("369e6c")
		),
	]
	for vegetation_batch: MultiMeshInstance3D in facade_vegetation_batches:
		if vegetation_batch != null:
			vegetation_batch.add_to_group("facade_vegetation")

	var flower_pot_batch := _make_unit_cylinder_multimesh(
		"Terracotta street flower pots",
		_city_flower_pot_transforms,
		Color("9f5f45")
	)
	if flower_pot_batch != null:
		flower_pot_batch.add_to_group("city_flower_pots")
	var city_flower_batches := [
		_make_unit_cylinder_multimesh(
			"Street flower pot stems",
			_city_flower_stem_transforms,
			Color("3f713f")
		),
		_make_unit_sphere_multimesh(
			"Street flower pot leaves",
			_city_flower_leaf_transforms,
			Color("54854a")
		),
		_make_unit_sphere_multimesh(
			"Street pot red flowers",
			_city_flower_red_transforms,
			Color("b64652")
		),
		_make_unit_sphere_multimesh(
			"Street pot yellow flowers",
			_city_flower_yellow_transforms,
			Color("e1b84d")
		),
		_make_unit_sphere_multimesh(
			"Street pot purple flowers",
			_city_flower_purple_transforms,
			Color("8d67a7")
		),
	]
	for flower_batch: MultiMeshInstance3D in city_flower_batches:
		if flower_batch != null:
			flower_batch.add_to_group("city_flower_pot_detail")

	var garland_batches := [
		_make_unit_sphere_multimesh(
			"Hanging garland leaves",
			_garland_leaf_transforms,
			Color("397044")
		),
		_make_unit_sphere_multimesh(
			"Hanging garland red blossoms",
			_garland_red_flower_transforms,
			Color("bb4c59")
		),
		_make_unit_sphere_multimesh(
			"Hanging garland golden blossoms",
			_garland_yellow_flower_transforms,
			Color("e3bd55")
		),
	]
	for garland_batch: MultiMeshInstance3D in garland_batches:
		if garland_batch != null:
			garland_batch.add_to_group("hanging_garland_foliage")

	_make_box_multimesh(
		"Old town lamp posts",
		Vector3(0.14, 4.2, 0.14),
		_lamp_pole_transforms,
		Color("27343a")
	)
	var lamp_mesh := SphereMesh.new()
	lamp_mesh.radius = 0.29
	lamp_mesh.height = 0.58
	_lamp_bulb_material = _material(Color("605b4e"))
	_make_multimesh(
		"Old town lamps",
		lamp_mesh,
		_lamp_bulb_transforms,
		_lamp_bulb_material
	)
	for index in _lamp_bulb_transforms.size():
		var light := OmniLight3D.new()
		light.name = "Street lamp light %02d" % index
		light.position = _lamp_bulb_transforms[index].origin
		light.light_color = Color("ffd692")
		light.light_energy = 0.0
		light.omni_range = 13.0
		light.omni_attenuation = 1.45
		light.shadow_enabled = false
		light.visible = false
		light.add_to_group("working_street_lamp")
		add_child(light)
		_street_lights.append(light)


func set_street_lamp_strength(strength: float) -> void:
	var amount := clampf(strength, 0.0, 1.0)
	if _lamp_bulb_material != null:
		_lamp_bulb_material.albedo_color = (
			Color("605b4e").lerp(Color("fff0bd"), amount)
		)
		_lamp_bulb_material.emission_enabled = amount > 0.001
		_lamp_bulb_material.emission = Color("ffd692")
		_lamp_bulb_material.emission_energy_multiplier = 4.0 * amount
	for light: OmniLight3D in _street_lights:
		light.visible = amount > 0.001
		light.light_energy = 2.1 * amount
	for navigation_light: Dictionary in _boat_navigation_lights:
		var light: OmniLight3D = navigation_light.light
		var material: StandardMaterial3D = navigation_light.material
		var color: Color = navigation_light.color
		light.visible = amount > 0.001
		light.light_energy = 2.8 * amount
		material.albedo_color = color.darkened(lerpf(0.62, 0.08, amount))
		material.emission_energy_multiplier = 8.5 * amount
	if _lighthouse_beacon_rotator != null:
		_lighthouse_beacon_rotator.visible = amount > 0.001
	if _lighthouse_spotlight != null:
		_lighthouse_spotlight.visible = amount > 0.001
		_lighthouse_spotlight.light_energy = 6.2 * amount
	if _lighthouse_lantern_glow != null:
		_lighthouse_lantern_glow.visible = amount > 0.001
		_lighthouse_lantern_glow.light_energy = 2.4 * amount
	if _lighthouse_lantern_material != null:
		_lighthouse_lantern_material.emission_energy_multiplier = 7.5 * amount


func _flush_foliage_batches() -> void:
	for variant: String in FOLIAGE_ASSETS:
		var transforms: Array = _foliage_transforms[variant]
		if transforms.is_empty():
			continue
		var custom_data: Array = _foliage_custom_data[variant]
		var mesh := _mesh_from_foliage_scene(
			FOLIAGE_ASSETS[variant] as PackedScene,
			variant
		)
		if mesh == null:
			continue
		var chunks := {}
		for index in transforms.size():
			var instance_transform: Transform3D = transforms[index]
			var chunk_coord := Vector2i(
				floori(instance_transform.origin.x / FOLIAGE_CHUNK_SIZE),
				floori(instance_transform.origin.z / FOLIAGE_CHUNK_SIZE)
			)
			if not chunks.has(chunk_coord):
				chunks[chunk_coord] = {"transforms": [], "custom_data": []}
			var chunk: Dictionary = chunks[chunk_coord]
			(chunk.transforms as Array).append(instance_transform)
			(chunk.custom_data as Array).append(custom_data[index])

		var profile: Dictionary = FOLIAGE_PROFILES[variant]
		for chunk_coord: Vector2i in chunks:
			var chunk: Dictionary = chunks[chunk_coord]
			var instance := _make_multimesh(
				"Foliage %s %d_%d" % [variant, chunk_coord.x, chunk_coord.y],
				mesh,
				chunk.transforms,
				null,
				chunk.custom_data
			)
			if instance != null:
				instance.add_to_group("foliage")
				instance.set_meta("foliage_variant", variant)
				instance.set_meta("foliage_chunk", chunk_coord)
				instance.visibility_range_end = float(profile.visibility)
				instance.visibility_range_end_margin = minf(
					24.0,
					float(profile.visibility) * 0.14
				)
				instance.visibility_range_fade_mode = (
					GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				)


func _mesh_from_foliage_scene(packed: PackedScene, variant: String) -> Mesh:
	var scene_root := packed.instantiate()
	var mesh_nodes: Array[Node] = scene_root.find_children("*", "MeshInstance3D", true, false)
	if mesh_nodes.is_empty():
		scene_root.free()
		return null
	var mesh_instance := mesh_nodes[0] as MeshInstance3D
	var mesh := mesh_instance.mesh.duplicate(true) as ArrayMesh
	for surface_index in mesh.get_surface_count():
		var source_material := mesh.surface_get_material(surface_index)
		if source_material is not StandardMaterial3D:
			continue
		var material := source_material.duplicate(true) as StandardMaterial3D
		var source_color := material.albedo_color
		if _is_kenney_foliage_green(source_color):
			var wind_material := ShaderMaterial.new()
			wind_material.shader = FOLIAGE_SHADER
			wind_material.set_shader_parameter("base_color", _foliage_green_for(variant))
			var profile: Dictionary = FOLIAGE_PROFILES[variant]
			wind_material.set_shader_parameter(
				"secondary_color",
				_foliage_secondary_for(variant)
			)
			wind_material.set_shader_parameter(
				"detail_mix",
				float(profile.get("detail_mix", 0.2))
			)
			wind_material.set_shader_parameter("wind_strength", float(profile.wind))
			wind_material.set_shader_parameter("wind_height", float(profile.wind_height))
			mesh.surface_set_material(surface_index, wind_material)
			continue
		elif variant == "dandelion_seed":
			material.albedo_color = Color("f4f1dc")
			material.roughness = 0.96
		elif variant == "dandelion_yellow":
			material.albedo_color = Color("f5c842")
			material.roughness = 0.92
		elif variant.begins_with("tree_"):
			material.albedo_color = Color("765038")
		material.roughness = 0.88
		material.metallic = 0.0
		mesh.surface_set_material(surface_index, material)
	scene_root.free()
	return mesh


func _is_kenney_foliage_green(color: Color) -> bool:
	return color.r < 0.65 and color.g > 0.78 and color.b > 0.68


func _foliage_green_for(variant: String) -> Color:
	match variant:
		"tree_oak":
			return Color("369b69")
		"tree_pine":
			return Color("278479")
		"tree_default":
			return Color("54b578")
		"tree_cherry":
			return Color("e694ae")
		"bush_detailed":
			return Color("45aa6b")
		"bush_small":
			return Color("70bf70")
		"grass_leaf":
			return Color("7cc276")
		"dandelion_yellow", "dandelion_seed":
			return Color("668d48")
		_:
			return Color("719751")


func _foliage_secondary_for(variant: String) -> Color:
	match variant:
		"tree_oak":
			return Color("678f4f")
		"tree_pine":
			return Color("496f4c")
		"tree_default":
			return Color("73a05d")
		"tree_cherry":
			return Color("ffe0e7")
		"bush_detailed":
			return Color("72964d")
		"bush_small":
			return Color("80a75a")
		"grass_leaf":
			return Color("83aa57")
		"dandelion_yellow", "dandelion_seed":
			return Color("82a85a")
		_:
			return Color("88ad5c")


func _make_boundaries() -> void:
	_make_collision_box(
		"North boundary",
		Vector3(0.0, 2.0, TERRAIN_MIN_Z + 2.0),
		Vector3(TERRAIN_MAX_X - TERRAIN_MIN_X, 24.0, 1.0)
	)
	_make_collision_box(
		"South boundary",
		Vector3(0.0, 2.0, TERRAIN_MAX_Z - 2.0),
		Vector3(TERRAIN_MAX_X - TERRAIN_MIN_X, 24.0, 1.0)
	)
	_make_collision_box(
		"West boundary",
		Vector3(TERRAIN_MIN_X + 2.0, 2.0, (TERRAIN_MIN_Z + TERRAIN_MAX_Z) * 0.5),
		Vector3(1.0, 24.0, TERRAIN_MAX_Z - TERRAIN_MIN_Z)
	)
	_make_collision_box(
		"East boundary",
		Vector3(TERRAIN_MAX_X - 2.0, 2.0, (TERRAIN_MIN_Z + TERRAIN_MAX_Z) * 0.5),
		Vector3(1.0, 24.0, TERRAIN_MAX_Z - TERRAIN_MIN_Z)
	)


func _make_collision_box(node_name: String, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	body.add_to_group("obstacle")
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body


func _make_rotated_box(
	node_name: String,
	at: Vector3,
	size: Vector3,
	color: Color,
	rotation_y: float,
	is_obstacle := false,
	visual_material: Material = null
) -> StaticBody3D:
	var body := _make_box(node_name, at, size, color, is_obstacle, visual_material)
	body.rotation.y = rotation_y
	return body


func _make_box(
	node_name: String,
	at: Vector3,
	size: Vector3,
	color: Color,
	is_obstacle := false,
	visual_material: Material = null
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	if is_obstacle:
		body.add_to_group("obstacle")
		_obstacle_clearings.append(Vector3(
			at.x,
			at.z,
			Vector2(size.x, size.z).length() * 0.52
		))
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var mesh := ToyGeometry.rounded_box(size)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = visual_material if visual_material != null else _material(color)
	body.add_child(mesh_instance)
	add_child(body)
	return body


func _make_visual_box(
	node_name: String,
	at: Vector3,
	size: Vector3,
	color: Color
) -> MeshInstance3D:
	var mesh := ToyGeometry.rounded_box(size)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = at
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color)
	add_child(mesh_instance)
	return mesh_instance


func _make_box_multimesh(
	node_name: String,
	size: Vector3,
	transforms: Array[Transform3D],
	color: Color
) -> MultiMeshInstance3D:
	var mesh := ToyGeometry.rounded_box(size)
	return _make_multimesh(node_name, mesh, transforms, _material(color))


func _make_unit_box_multimesh(
	node_name: String,
	transforms: Array[Transform3D],
	color: Color,
	material: Material = null
) -> MultiMeshInstance3D:
	var mesh := ToyGeometry.rounded_box(Vector3.ONE)
	return _make_multimesh(
		node_name,
		mesh,
		transforms,
		material if material != null else _material(color)
	)


func _make_unit_sphere_multimesh(
	node_name: String,
	transforms: Array[Transform3D],
	color: Color
) -> MultiMeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	return _make_multimesh(node_name, mesh, transforms, _material(color))


func _make_unit_leaf_multimesh(
	node_name: String,
	transforms: Array[Transform3D],
	color: Color
) -> MultiMeshInstance3D:
	# A tapered, slightly folded card reads as foliage from rider distance while
	# avoiding the bead-like silhouette produced by scaled sphere primitives.
	var vertices := PackedVector3Array([
		Vector3(0.0, 1.0, 0.0),
		Vector3(0.72, 0.0, 0.08),
		Vector3(0.0, -1.0, 0.0),
		Vector3(-0.72, 0.0, 0.08),
		Vector3(0.0, 1.0, 0.0),
		Vector3(0.72, 0.0, 0.08),
		Vector3(0.0, -1.0, 0.0),
		Vector3(-0.72, 0.0, 0.08),
	])
	var normals := PackedVector3Array()
	for _index in 4:
		normals.append(Vector3.FORWARD)
	for _index in 4:
		normals.append(Vector3.BACK)
	var indices := PackedInt32Array([
		0, 1, 2, 0, 2, 3,
		4, 6, 5, 4, 7, 6,
	])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := _material(color)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _make_multimesh(node_name, mesh, transforms, material)


func _make_unit_cylinder_multimesh(
	node_name: String,
	transforms: Array[Transform3D],
	color: Color
) -> MultiMeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.8
	mesh.bottom_radius = 1.0
	mesh.height = 1.0
	mesh.radial_segments = 10
	return _make_multimesh(node_name, mesh, transforms, _material(color))


func _make_multimesh(
	node_name: String,
	mesh: Mesh,
	transforms: Array,
	material: Material,
	custom_data: Array = []
) -> MultiMeshInstance3D:
	if transforms.is_empty():
		return null
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var uses_custom_data := custom_data.size() == transforms.size()
	multimesh.use_custom_data = uses_custom_data
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		var instance_transform: Transform3D = transforms[index]
		multimesh.set_instance_transform(index, instance_transform)
		if uses_custom_data:
			multimesh.set_instance_custom_data(index, custom_data[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	if material != null:
		instance.material_override = material
	add_child(instance)
	return instance


func _facade_material(color: Color) -> ShaderMaterial:
	var key := color.to_html()
	if _facade_material_cache.has(key):
		return _facade_material_cache[key]
	var material := ShaderMaterial.new()
	material.shader = FACADE_SHADER
	material.set_shader_parameter("base_color", color)
	_facade_material_cache[key] = material
	return material


func _stone_material(color: Color) -> ShaderMaterial:
	var key := color.to_html()
	if _stone_material_cache.has(key):
		return _stone_material_cache[key]
	var material := ShaderMaterial.new()
	material.shader = STONE_SHADER
	material.set_shader_parameter("base_color", color)
	_stone_material_cache[key] = material
	return material


func _roof_material(color: Color) -> ShaderMaterial:
	var key := color.to_html()
	if _roof_material_cache.has(key):
		return _roof_material_cache[key]
	var material := ShaderMaterial.new()
	material.shader = ROOF_SHADER
	material.set_shader_parameter("base_color", color)
	_roof_material_cache[key] = material
	return material


func _surface_material(color: Color) -> Material:
	if _is_textured_surface_color(color):
		return _road_material(color)
	return _material(color)


func _is_textured_surface_color(color: Color) -> bool:
	return (
		color.is_equal_approx(ASPHALT)
		or color.is_equal_approx(COBBLE)
		or color.is_equal_approx(SIDEWALK)
	)


func _road_material(color: Color) -> ShaderMaterial:
	var is_asphalt := color.is_equal_approx(ASPHALT)
	var key := ("asphalt-" if is_asphalt else "paving-") + color.to_html()
	if _road_material_cache.has(key):
		return _road_material_cache[key]
	var material := ShaderMaterial.new()
	material.shader = ROAD_SURFACE_SHADER
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("roughness", 0.72 if is_asphalt else 0.6)
	_road_material_cache[key] = material
	return material


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.48
	return material


func _emissive_material(color: Color) -> StandardMaterial3D:
	var material := _material(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.3
	return material


func _rendered_ground_height(x: float, z: float) -> float:
	return _height_from_grid(_visual_terrain_heights, x, z)


func _conform_road_arrays(arrays: Array, height_offset: float) -> Array:
	# Clip to the *rendered* terrain triangles. Sampling the analytic height
	# function separately creates intersections even with very dense ribbons.
	# All nested road layers now occupy the same planes with ordered offsets.
	if _visual_terrain_heights.is_empty():
		return arrays
	var source: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var source_indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for triangle in range(0, source_indices.size(), 3):
		var points := PackedVector2Array()
		for corner in 3:
			var p := source[source_indices[triangle + corner]]
			points.append(Vector2(p.x, p.z))
		var bounds := Rect2(points[0], Vector2.ZERO).expand(points[1]).expand(points[2])
		var min_x := int(floor((bounds.position.x - TERRAIN_MIN_X) / TERRAIN_CELL_SIZE))
		var min_z := int(floor((bounds.position.y - TERRAIN_MIN_Z) / TERRAIN_CELL_SIZE))
		var max_x := int(floor((bounds.end.x - TERRAIN_MIN_X) / TERRAIN_CELL_SIZE))
		var max_z := int(floor((bounds.end.y - TERRAIN_MIN_Z) / TERRAIN_CELL_SIZE))
		for iz in range(min_z, max_z + 1):
			for ix in range(min_x, max_x + 1):
				var a := Vector2(TERRAIN_MIN_X + ix * TERRAIN_CELL_SIZE, TERRAIN_MIN_Z + iz * TERRAIN_CELL_SIZE)
				var b := a + Vector2(TERRAIN_CELL_SIZE, 0.0)
				var c := a + Vector2(0.0, TERRAIN_CELL_SIZE)
				var d := a + Vector2.ONE * TERRAIN_CELL_SIZE
				for tile in [PackedVector2Array([a,b,c]), PackedVector2Array([b,d,c])]:
					for polygon: PackedVector2Array in Geometry2D.intersect_polygons(points, tile):
						if Geometry2D.is_polygon_clockwise(polygon):
							polygon.reverse()
						for corner in range(1, polygon.size() - 1):
							var p0 := polygon[0]
							var p1 := polygon[corner]
							var p2 := polygon[corner + 1]
							if absf((p1 - p0).cross(p2 - p0)) < 0.00001:
								continue
							for point in [p0,p1,p2]:
								indices.append(vertices.size())
								vertices.append(Vector3(point.x, _rendered_ground_height(point.x, point.y) + height_offset, point.y))
								normals.append(Vector3.UP)
								uvs.append(point / 3.2)
	var result := []
	result.resize(Mesh.ARRAY_MAX)
	result[Mesh.ARRAY_VERTEX] = vertices
	result[Mesh.ARRAY_NORMAL] = normals
	result[Mesh.ARRAY_TEX_UV] = uvs
	result[Mesh.ARRAY_INDEX] = indices
	return result


func _prepare_smooth_road_surface() -> void:
	# Filter only land around road corridors. A shared height field removes
	# winner-takes-all corridor seams from rendering, collision and agents.
	var heights := PackedFloat32Array()
	var influence := PackedFloat32Array()
	heights.resize(TERRAIN_WIDTH * TERRAIN_DEPTH)
	influence.resize(heights.size())
	for iz in TERRAIN_DEPTH:
		for ix in TERRAIN_WIDTH:
			var x := TERRAIN_MIN_X + ix * TERRAIN_CELL_SIZE
			var z := TERRAIN_MIN_Z + iz * TERRAIN_CELL_SIZE
			var index := iz * TERRAIN_WIDTH + ix
			heights[index] = ground_height_at(x, z)
			if _natural_ground_height_at(x, z) <= WATER_LEVEL + 0.1:
				continue
			var clearance := road_surface_clearance_at(Vector3(x, 0.0, z))
			influence[index] = 1.0 - smoothstep(3.0, 12.0, clearance)
	for iteration in 18:
		var filtered := heights.duplicate()
		for iz in range(1, TERRAIN_DEPTH - 1):
			for ix in range(1, TERRAIN_WIDTH - 1):
				var index := iz * TERRAIN_WIDTH + ix
				if influence[index] <= 0.0:
					continue
				var total := heights[index] * 4.0
				var weight := 4.0
				for dz in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						if dx == 0 and dz == 0:
							continue
						var neighbor: int = index + dz * TERRAIN_WIDTH + dx
						# Preserve water channels and bridge abutments.
						if heights[neighbor] <= WATER_LEVEL + 0.1:
							continue
						var kernel := 2.0 if dx == 0 or dz == 0 else 1.0
						total += heights[neighbor] * kernel
						weight += kernel
				filtered[index] = lerpf(heights[index], total / weight, influence[index])
		heights = filtered
	# Shape a level cross-section from the smoothed centerline profile, rather
	# than allowing adjacent hillside elevations to bank the cycle lanes.
	for pass_index in 3:
		var leveled := heights.duplicate()
		for iz in range(1, TERRAIN_DEPTH - 1):
			for ix in range(1, TERRAIN_WIDTH - 1):
				var index := iz * TERRAIN_WIDTH + ix
				if influence[index] <= 0.0:
					continue
				var point := Vector2(TERRAIN_MIN_X + ix * TERRAIN_CELL_SIZE, TERRAIN_MIN_Z + iz * TERRAIN_CELL_SIZE)
				var total := 0.0
				var total_weight := 0.0
				var coverage := 0.0
				for corridor: Dictionary in _road_corridors:
					var from: Vector2 = corridor.from
					var segment: Vector2 = corridor.to - from
					var t := clampf((point - from).dot(segment) / maxf(segment.length_squared(), 0.001), 0.0, 1.0)
					var center := from + segment * t
					var distance := point.distance_to(center)
					var radius := float(corridor.radius)
					if distance >= radius + 8.0:
						continue
					var weight := pow(1.0 - smoothstep(0.0, radius + 8.0, distance), 4.0)
					total += _height_from_grid(heights, center.x, center.y) * weight
					total_weight += weight
					coverage = maxf(coverage, 1.0 - smoothstep(radius + 0.8, radius + 8.0, distance))
				if total_weight > 0.0001:
					leveled[index] = lerpf(heights[index], total / total_weight, coverage)
		heights = leveled
	# Bound the gradient on the shared terrain triangles. Bounding both grid
	# axes by max_grade/sqrt(2) also bounds diagonally aligned roads.
	var axis_delta := TERRAIN_CELL_SIZE * 0.12 / sqrt(2.0)
	for iteration in 100:
		var largest_excess := 0.0
		for iz in range(1, TERRAIN_DEPTH - 1):
			for ix in range(1, TERRAIN_WIDTH - 1):
				var index := iz * TERRAIN_WIDTH + ix
				if influence[index] < 0.99:
					continue
				for neighbor in [index + 1, index + TERRAIN_WIDTH]:
					if influence[neighbor] < 0.99:
						continue
					var difference: float = heights[neighbor] - heights[index]
					var excess := absf(difference) - axis_delta
					if excess <= 0.0001:
						continue
					var correction := signf(difference) * excess * 0.5
					heights[index] += correction
					heights[neighbor] -= correction
					largest_excess = maxf(largest_excess, excess)
		if largest_excess < 0.0005:
			break
	_smooth_road_heights = heights


func _height_from_grid(heights: PackedFloat32Array, x: float, z: float) -> float:
	var gx := clampf((x - TERRAIN_MIN_X) / TERRAIN_CELL_SIZE, 0.0, TERRAIN_WIDTH - 1.001)
	var gz := clampf((z - TERRAIN_MIN_Z) / TERRAIN_CELL_SIZE, 0.0, TERRAIN_DEPTH - 1.001)
	var ix := int(gx)
	var iz := int(gz)
	var u := gx - ix
	var v := gz - iz
	var index := iz * TERRAIN_WIDTH + ix
	if u + v <= 1.0:
		return heights[index] * (1.0 - u - v) + heights[index + 1] * u + heights[index + TERRAIN_WIDTH] * v
	return heights[index + TERRAIN_WIDTH + 1] * (u + v - 1.0) + heights[index + 1] * (1.0 - v) + heights[index + TERRAIN_WIDTH] * (1.0 - u)


func _fillet_road_path(points: Array[Vector3]) -> Array[Vector3]:
	var rounded: Array[Vector3] = [points[0]]
	for index in range(1, points.size() - 1):
		var before := points[index - 1]
		var corner := points[index]
		var after := points[index + 1]
		var incoming := corner.direction_to(before)
		var outgoing := corner.direction_to(after)
		var turn := PI - acos(clampf(incoming.dot(outgoing), -1.0, 1.0))
		if turn < deg_to_rad(12.0):
			rounded.append(corner)
			continue
		var trim := minf(7.0, minf(corner.distance_to(before), corner.distance_to(after)) * 0.3)
		var entry := corner + incoming * trim
		var exit_point := corner + outgoing * trim
		for step in 9:
			var t := float(step) / 8.0
			rounded.append(entry.lerp(corner, t).lerp(corner.lerp(exit_point, t), t))
	rounded.append(points[-1])
	return rounded
