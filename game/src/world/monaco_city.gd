extends "res://src/world/delivery_city.gd"

const MONACO_SAND := Color("f3d7a2")
const MONACO_STONE := Color("c4bda4")
const MONACO_ROAD := Color("3b5167")
const MONACO_PALETTE := [
	Color("f5c96b"),
	Color("ed927b"),
	Color("f8d891"),
	Color("83cdb6"),
	Color("e67e75"),
	Color("d1a9d3"),
	Color("73bed0"),
	Color("f4aa63"),
]
const MONACO_FACADE_CHUNK_SIZE := 72.0

var _monaco_building_count := 0
var _marina_yacht_motion: Array[Dictionary] = []
var _monaco_facade_detail_transforms := {
	"trim": [],
	"rail": [],
	"planter": [],
	"window": [],
	"shutter_green": [],
	"shutter_plum": [],
	"awning_red": [],
	"awning_green": [],
	"door": [],
	"tower_glass_blue": [],
	"tower_glass_grey": [],
}


func _ready() -> void:
	add_to_group("terrain_provider")
	set_meta("level_id", "monaco")
	set_meta("level_name", "Monaco Corniche")
	_configure_height_noise()
	_height_noise.seed = 0x4D4F4E
	_road_plan_only = true
	_make_monaco_roads()
	_make_monaco_junctions()
	_road_plan_only = false
	_grade_monaco_road_network(0.125)
	_prepare_smooth_road_surface()
	_make_terrain()
	_make_surrounding_ocean()
	_make_mainland_mountain_backdrop()
	_make_monaco_roads()
	_make_monaco_junctions()
	_make_harbour_quays()
	_make_retaining_walls()
	_make_monaco_neighbourhoods()
	_make_monaco_infill()
	_flush_monaco_facade_batches()
	_make_casino_quarter()
	_make_prince_palace()
	_make_monaco_cathedral()
	_make_oceanographic_museum()
	_make_stade_louis_ii()
	_make_grimaldi_forum()
	_make_jardin_exotique()
	_make_fontvieille_marina()
	_make_grand_prix_tunnel()
	_make_larvotto_beach()
	_make_monaco_route_landmarks()
	_make_monaco_circuit_details()
	_make_monaco_palms()
	_make_monaco_hillside_gardens()
	_make_batched_mediterranean_planting()
	_make_monaco_street_details()
	_make_marina_yachts()
	_make_distant_boats()
	_make_monaco_lamps()
	_make_boundaries()
	set_meta("monaco_building_count", _monaco_building_count)
	set_meta("connected_road_path_count", _monaco_road_paths().size())
	set_meta("road_corridor_count", _road_corridors.size())
	set_meta(
		"circumferential_route_length_m",
		_monaco_route_length("Island circumferential route")
	)


func _process(delta: float) -> void:
	_world_motion_time += delta
	_update_distant_boats()
	_update_marina_yachts()


func _natural_ground_height_at(x: float, z: float) -> float:
	# Port Hercule opens toward the southern sea while dense streets climb the
	# north-facing amphitheatre. The road grader inherited from DeliveryCity
	# softens this natural relief only beneath the connected road ribbons.
	# The northern and lateral edge bands descend beneath the surrounding ocean
	# before the terrain mesh ends. Previously the elevated northern plateau ran
	# straight into the rectangular mesh boundary, so riding off it looked like
	# falling out of an unfinished level rather than leaving an island.
	var island_edge := _monaco_island_edge_influence(x, z)
	if island_edge >= 0.999:
		return WATER_LEVEL - 7.5
	var harbour_width := 72.0 + smoothstep(44.0, 116.0, z) * 11.0
	if z > 44.0 and absf(x) < harbour_width:
		return WATER_LEVEL - 7.5
	var coast_line := (
		126.0
		- absf(x) * 0.045
		+ _height_noise.get_noise_2d(x * 0.55 + 91.0, z * 0.55 - 37.0) * 2.2
	)
	if z > coast_line:
		return WATER_LEVEL - 7.5
	var climb := clampf((118.0 - z) / 270.0, 0.0, 1.0)
	var hillside := pow(climb, 1.06) * 31.5
	var ridge := smoothstep(65.0, 190.0, absf(x)) * climb * 2.7
	var broad_undulation := _height_noise.get_noise_2d(x * 0.62, z * 0.62) * 0.72
	var fine_undulation := _height_noise.get_noise_2d(
		x * 1.9 + 213.0,
		z * 1.9 - 177.0
	) * 0.18
	# Larvotto eases down toward the beach across a broad fan. A former binary
	# x/z threshold created a hidden terrain step directly beneath the loop
	# road and produced a short 35% ramp despite gentle neighbouring grades.
	var beach_influence := (
		smoothstep(90.0, 132.0, x)
		* smoothstep(72.0, 116.0, z)
	)
	var beach_flatten := lerpf(1.0, 0.26, beach_influence)
	var height := maxf(
		0.18,
		(hillside + ridge + broad_undulation + fine_undulation) * beach_flatten
	)
	var harbour_bowl := (
		smoothstep(5.0, 42.0, z)
		* (1.0 - smoothstep(82.0, 128.0, absf(x)))
	)
	var harbour_terrace := 2.2 + smoothstep(0.0, 128.0, absf(x)) * 2.2
	var interior_height := lerpf(height, harbour_terrace, harbour_bowl * 0.84)
	return lerpf(interior_height, WATER_LEVEL - 7.5, island_edge)


func _monaco_island_edge_influence(x: float, z: float) -> float:
	var absolute_x := absf(x)
	if z > -182.0 and absolute_x < 220.0:
		return 0.0
	var northern_cliff := 0.0
	if z <= -182.0:
		var north_shore := (
			-214.0
			+ smoothstep(145.0, 228.0, absolute_x) * 7.0
			+ _height_noise.get_noise_2d(
				x * 0.72 + 413.0,
				-937.0
			) * 3.8
		)
		northern_cliff = (
			1.0 - smoothstep(north_shore, north_shore + 16.0, z)
		)
	var lateral_cliff := 0.0
	if absolute_x >= 220.0:
		var side_shore := (
			234.0
			- smoothstep(160.0, 222.0, -z) * 3.0
			+ _height_noise.get_noise_2d(
				819.0,
				z * 0.66 - 271.0
			) * 1.25
		)
		lateral_cliff = smoothstep(
			side_shore - 10.0,
			side_shore,
			absolute_x
		)
	return clampf(maxf(northern_cliff, lateral_cliff), 0.0, 1.0)


func _terrain_height_without_channels(x: float, z: float) -> float:
	return ground_height_at(x, z)


func _junction_grade_score(distance: float, radius: float) -> float:
	# Monaco's junction discs are large enough that forcing their anchor height
	# across the whole apron compresses the final metres of a 12.5% climb into
	# one sharp ramp. Let each connected road own its centreline and use the
	# circular grade only to fill the wedges between ribbons.
	return 0.18 + distance / maxf(radius, 0.1)


func _terrain_control_at(x: float, z: float, height: float, normal: Vector3) -> Color:
	var is_beach := 1.0 if _coast_is_beach(x, z) else 0.0
	var slope := 1.0 - clampf(normal.y, 0.0, 1.0)
	var dry_scrub := clampf(
		smoothstep(8.0, 24.0, height) * 0.6
		+ smoothstep(0.08, 0.28, slope) * 0.52,
		0.0,
		1.0
	)
	var region := _height_noise.get_noise_2d(x * 0.41 + 612.0, z * 0.41) * 0.5 + 0.5
	return Color(is_beach, dry_scrub, region, 1.0)


func _coast_is_beach(x: float, z: float) -> bool:
	return x > 100.0 and z > 90.0


func _monaco_road_paths() -> Array[Dictionary]:
	var roads: Array[Dictionary] = [
		{
			"name": "Port Hercule waterfront",
			"width": 10.0,
			"points": [
				Vector3(-88.0, 0.0, 112.0),
				Vector3(-94.0, 0.0, 78.0),
				Vector3(-86.0, 0.0, 47.0),
				Vector3(-58.0, 0.0, 30.0),
				Vector3(0.0, 0.0, 22.0),
				Vector3(58.0, 0.0, 30.0),
				Vector3(86.0, 0.0, 47.0),
				Vector3(94.0, 0.0, 78.0),
				Vector3(88.0, 0.0, 112.0),
			],
		},
		{
			"name": "Moyenne Corniche",
			"width": 9.5,
			"points": [
				Vector3(-150.0, 0.0, 32.0),
				Vector3(-122.0, 0.0, 17.0),
				Vector3(-92.0, 0.0, 5.0),
				Vector3(-35.0, 0.0, -5.0),
				Vector3(25.0, 0.0, -2.0),
				Vector3(85.0, 0.0, 10.0),
				Vector3(118.0, 0.0, 18.0),
				Vector3(145.0, 0.0, 32.0),
			],
		},
		{
			"name": "Grande Corniche",
			"width": 9.0,
			"points": [
				Vector3(-185.0, 0.0, -35.0),
				Vector3(-135.0, 0.0, -60.0),
				Vector3(-70.0, 0.0, -82.0),
				Vector3(0.0, 0.0, -96.0),
				Vector3(70.0, 0.0, -86.0),
				Vector3(135.0, 0.0, -58.0),
				Vector3(170.0, 0.0, -30.0),
				Vector3(158.0, 0.0, -22.0),
			],
		},
		{
			"name": "Western switchbacks",
			"width": 8.5,
			"points": [
				Vector3(-88.0, 0.0, 112.0),
				Vector3(-132.0, 0.0, 82.0),
				Vector3(-103.0, 0.0, 56.0),
				Vector3(-150.0, 0.0, 32.0),
				Vector3(-138.0, 0.0, 3.0),
				Vector3(-158.0, 0.0, -22.0),
				Vector3(-185.0, 0.0, -35.0),
			],
		},
		{
			"name": "Eastern switchbacks",
			"width": 8.5,
			"points": [
				Vector3(88.0, 0.0, 112.0),
				Vector3(132.0, 0.0, 82.0),
				Vector3(104.0, 0.0, 56.0),
				Vector3(145.0, 0.0, 32.0),
				Vector3(168.0, 0.0, 10.0),
				Vector3(158.0, 0.0, -22.0),
				Vector3(135.0, 0.0, -58.0),
			],
		},
		{
			"name": "Casino circuit",
			"width": 8.5,
			"points": [
				Vector3(-35.0, 0.0, -5.0),
				Vector3(-20.0, 0.0, -29.0),
				Vector3(8.0, 0.0, -50.0),
				Vector3(42.0, 0.0, -46.0),
				Vector3(70.0, 0.0, -25.0),
				Vector3(85.0, 0.0, 10.0),
			],
		},
		{
			"name": "Fairmont hairpin",
			"width": 8.0,
			"points": [
				Vector3(8.0, 0.0, -50.0),
				Vector3(-5.0, 0.0, -65.0),
				Vector3(-28.0, 0.0, -62.0),
				Vector3(-40.0, 0.0, -47.0),
				Vector3(-28.0, 0.0, -30.0),
				Vector3(-20.0, 0.0, -29.0),
			],
		},
		{
			"name": "Grand Prix tunnel road",
			"width": 9.0,
			"points": [
				Vector3(42.0, 0.0, -46.0),
				Vector3(72.0, 0.0, -35.0),
				Vector3(91.0, 0.0, -43.0),
				Vector3(116.0, 0.0, -38.0),
				Vector3(138.0, 0.0, -18.0),
				Vector3(158.0, 0.0, -22.0),
			],
		},
		{
			"name": "Palace climb",
			"width": 8.0,
			"points": [
				Vector3(-122.0, 0.0, 17.0),
				Vector3(-132.0, 0.0, -7.0),
				Vector3(-122.0, 0.0, -30.0),
				Vector3(-118.0, 0.0, -43.0),
				Vector3(-135.0, 0.0, -60.0),
			],
		},
		{
			"name": "Larvotto beach loop",
			"width": 9.0,
			"points": [
				Vector3(88.0, 0.0, 112.0),
				Vector3(126.0, 0.0, 116.0),
				Vector3(171.0, 0.0, 110.0),
				Vector3(196.0, 0.0, 84.0),
				Vector3(178.0, 0.0, 55.0),
				Vector3(145.0, 0.0, 32.0),
			],
		},
		{
			# The existing Port Hercule waterfront and Larvotto loop close the
			# southern side, so this long outer arc forms one connected circuit
			# without drawing duplicate asphalt through the harbour.
			"name": "Island circumferential route",
			"width": 8.0,
			"points": [
				Vector3(-88.0, 0.0, 112.0),
				# Keep the western harbour connection inside the irregular
				# coastline. The former 122 m arc crossed the open harbour
				# mouth and produced a submerged road ribbon.
				Vector3(-112.0, 0.0, 108.0),
				Vector3(-142.0, 0.0, 104.0),
				Vector3(-166.0, 0.0, 94.0),
				Vector3(-181.0, 0.0, 79.0),
				Vector3(-181.0, 0.0, 45.0),
				Vector3(-190.0, 0.0, 12.0),
				Vector3(-202.0, 0.0, -24.0),
				Vector3(-204.0, 0.0, -60.0),
				Vector3(-198.0, 0.0, -94.0),
				Vector3(-190.0, 0.0, -130.0),
				Vector3(-145.0, 0.0, -163.0),
				Vector3(-100.0, 0.0, -180.0),
				Vector3(-42.0, 0.0, -186.0),
				Vector3(22.0, 0.0, -187.0),
				Vector3(84.0, 0.0, -181.0),
				Vector3(140.0, 0.0, -164.0),
				Vector3(179.0, 0.0, -139.0),
				Vector3(198.0, 0.0, -108.0),
				Vector3(210.0, 0.0, -76.0),
				Vector3(202.0, 0.0, -44.0),
				# Stay outside the switchback network instead of laying two
				# almost-parallel road ribbons over one another. The last leg
				# meets Larvotto in its direction of travel for a smooth join.
				Vector3(211.0, 0.0, -7.0),
				Vector3(214.0, 0.0, 29.0),
				Vector3(216.0, 0.0, 58.0),
				Vector3(210.0, 0.0, 80.0),
				Vector3(188.0, 0.0, 101.0),
				Vector3(171.0, 0.0, 110.0),
			],
		},
	]
	for road: Dictionary in roads:
		var source_points: Array[Vector3] = []
		source_points.assign(road.points)
		var subdivisions := 4 if String(road.name) in [
			"Fairmont hairpin",
			"Grand Prix tunnel road",
		] else 6
		road.points = _rounded_monaco_path(source_points, subdivisions)
	return roads


func _rounded_monaco_path(
	source_points: Array[Vector3],
	subdivisions: int
) -> Array[Vector3]:
	# A Catmull-Rom spline passes through every authored junction anchor. That
	# matters here: corner-cutting splines look smooth but silently pull an
	# intersecting road away from the exact point where another road joins it.
	var rounded: Array[Vector3] = []
	if source_points.size() < 3:
		return source_points.duplicate()
	for index in source_points.size() - 1:
		var p0 := source_points[maxi(0, index - 1)]
		var p1 := source_points[index]
		var p2 := source_points[index + 1]
		var p3 := source_points[mini(source_points.size() - 1, index + 2)]
		for step in subdivisions:
			var weight := float(step) / float(subdivisions)
			var weight_squared := weight * weight
			var weight_cubed := weight_squared * weight
			rounded.append(
				(
					p1 * 2.0
					+ (p2 - p0) * weight
					+ (p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3)
					* weight_squared
					+ (-p0 + p1 * 3.0 - p2 * 3.0 + p3)
					* weight_cubed
				) * 0.5
			)
	rounded.append(source_points.back())
	return rounded


func _make_monaco_roads() -> void:
	for road: Dictionary in _monaco_road_paths():
		var points: Array[Vector3] = []
		points.assign(road.points)
		_make_modern_path(String(road.name), points, float(road.width))


func minimap_road_paths() -> Array[Dictionary]:
	return _monaco_road_paths()


func _monaco_route_length(route_name: String) -> float:
	for road: Dictionary in _monaco_road_paths():
		if String(road.name) != route_name:
			continue
		var length := 0.0
		var points: Array = road.points
		for index in points.size() - 1:
			var from: Vector3 = points[index]
			var to: Vector3 = points[index + 1]
			length += from.distance_to(to)
		return length
	return 0.0


func minimap_coast_outline() -> Array[Vector3]:
	return [
		Vector3(-219.0, 0.0, -196.0),
		Vector3(-181.0, 0.0, -207.0),
		Vector3(-112.0, 0.0, -214.0),
		Vector3(-38.0, 0.0, -212.0),
		Vector3(41.0, 0.0, -215.0),
		Vector3(113.0, 0.0, -211.0),
		Vector3(183.0, 0.0, -204.0),
		Vector3(219.0, 0.0, -190.0),
		Vector3(230.0, 0.0, -140.0),
		Vector3(234.0, 0.0, -58.0),
		Vector3(232.0, 0.0, 28.0),
		Vector3(225.0, 0.0, 108.0),
		Vector3(185.0, 0.0, 118.0),
		Vector3(120.0, 0.0, 122.0),
		Vector3(84.0, 0.0, 114.0),
		Vector3(72.0, 0.0, 45.0),
		Vector3(-72.0, 0.0, 45.0),
		Vector3(-84.0, 0.0, 114.0),
		Vector3(-130.0, 0.0, 122.0),
		Vector3(-190.0, 0.0, 120.0),
		Vector3(-225.0, 0.0, 108.0),
		Vector3(-232.0, 0.0, 38.0),
		Vector3(-234.0, 0.0, -48.0),
		Vector3(-230.0, 0.0, -132.0),
	]


func _monaco_junction_positions() -> Array[Vector3]:
	var appearances := {}
	var ordered_points: Array[Vector2] = []
	for road: Dictionary in _monaco_road_paths():
		var points: Array = road.points
		for point_3d: Vector3 in points:
			var point := Vector2(point_3d.x, point_3d.z)
			if not appearances.has(point):
				appearances[point] = 0
				ordered_points.append(point)
			appearances[point] = int(appearances[point]) + 1
	var junctions: Array[Vector3] = []
	for point: Vector2 in ordered_points:
		if int(appearances[point]) >= 2:
			junctions.append(Vector3(point.x, 0.0, point.y))
	return junctions


func _make_monaco_junctions() -> void:
	for index in _monaco_junction_positions().size():
		var position := _monaco_junction_positions()[index]
		# A broad final asphalt pass covers the wedges produced where several
		# curved ribbons overlap. The matching clearance disc also forces all
		# later props beyond the complete junction, not merely beyond one lane.
		_register_road_corridor(position, position, 19.4, 15.2)
		if _road_plan_only:
			continue
		var sidewalk := _make_terrain_disc(
			"Monaco junction sidewalk %02d" % index,
			position,
			9.7,
			SIDEWALK,
			0.17
		)
		var roadway := _make_terrain_disc(
			"Monaco junction roadway %02d" % index,
			position,
			7.6,
			ASPHALT,
			0.215
		)
		sidewalk.add_to_group("monaco_road_junction")
		roadway.add_to_group("monaco_road_junction")


func _grade_monaco_road_network(maximum_grade: float) -> void:
	# Dense spline sampling is valuable for smooth bends, but sampling the raw
	# terrain at every four-metre interval also copies tiny hillside bumps into
	# the road profile. Solve the connected endpoints as one grade-constrained
	# graph instead: shared junctions receive one height and every edge stays
	# below the bike-safe limit while retaining Monaco's total climb.
	var node_heights := {}
	var node_samples := {}
	for corridor: Dictionary in _road_corridors:
		for endpoint_name in ["from", "to"]:
			var point: Vector2 = corridor[endpoint_name]
			var height_name: String = endpoint_name + "_height"
			node_heights[point] = float(node_heights.get(point, 0.0)) + float(
				corridor[height_name]
			)
			node_samples[point] = int(node_samples.get(point, 0)) + 1
	for point: Vector2 in node_heights:
		node_heights[point] = (
			float(node_heights[point]) / float(node_samples[point])
		)

	for _iteration in 320:
		var largest_excess := 0.0
		for corridor: Dictionary in _road_corridors:
			var from: Vector2 = corridor.from
			var to: Vector2 = corridor.to
			var length := from.distance_to(to)
			if length < 0.05:
				continue
			var from_height: float = node_heights[from]
			var to_height: float = node_heights[to]
			var height_delta := to_height - from_height
			var allowed_delta := length * maximum_grade
			var excess := absf(height_delta) - allowed_delta
			if excess <= 0.0001:
				continue
			largest_excess = maxf(largest_excess, excess)
			var correction := signf(height_delta) * excess * 0.5
			node_heights[from] = from_height + correction
			node_heights[to] = to_height - correction
		if largest_excess < 0.0005:
			break

	var audited_maximum := 0.0
	for corridor: Dictionary in _road_corridors:
		var from: Vector2 = corridor.from
		var to: Vector2 = corridor.to
		corridor.from_height = float(node_heights[from])
		corridor.to_height = float(node_heights[to])
		var length := from.distance_to(to)
		if length > 0.05:
			audited_maximum = maxf(
				audited_maximum,
				absf(float(corridor.to_height) - float(corridor.from_height))
				/ length
			)
	set_meta("maximum_road_grade", audited_maximum)


func _make_harbour_quays() -> void:
	var north_top := ground_height_at(0.0, 39.0)
	_make_quay_box(
		"Port Hercule north quay wall",
		Vector3(0.0, (north_top + WATER_LEVEL) * 0.5, 45.0),
		Vector3(146.0, north_top - WATER_LEVEL + 0.7, 1.4)
	)
	for side: float in [-1.0, 1.0]:
		for section in 4:
			var from_z := 46.0 + float(section) * 19.0
			var to_z := from_z + 19.0
			# The quay edge belongs between water and the waterfront road. The
			# previous 86–92 m offsets put the wall directly under the road
			# centreline; follow the widening harbour bowl at 73–82 m instead.
			var x: float = side * (73.0 + float(section) * 3.0)
			var top := ground_height_at(
				x + side * 5.2,
				(from_z + to_z) * 0.5
			)
			_make_quay_box(
				"Port Hercule side quay wall",
				Vector3(x, (top + WATER_LEVEL) * 0.5, (from_z + to_z) * 0.5),
				Vector3(1.4, top - WATER_LEVEL + 0.7, 20.0)
			)
	for bollard_index in 9:
		var x := -64.0 + float(bollard_index) * 16.0
		var top := north_top + 0.28
		var bollard_mesh := CylinderMesh.new()
		bollard_mesh.top_radius = 0.2
		bollard_mesh.bottom_radius = 0.28
		bollard_mesh.height = 0.58
		bollard_mesh.radial_segments = 10
		var bollard := _add_visual_mesh(
			"Marina mooring bollard %02d" % bollard_index,
			bollard_mesh,
			Vector3(x, top, 43.8),
			_material(Color("2b3336")),
			Vector3.ZERO,
			self
		)
		bollard.add_to_group("marina_detail")
	var harbour_marker := Node3D.new()
	harbour_marker.name = "Port Hercule marina"
	harbour_marker.add_to_group("monaco_landmark")
	harbour_marker.add_to_group("monaco_harbour")
	add_child(harbour_marker)


func _make_quay_box(node_name: String, at: Vector3, size: Vector3) -> void:
	var wall := _make_box(
		node_name,
		at,
		size,
		MONACO_STONE,
		true,
		_stone_material(MONACO_STONE)
	)
	wall.add_to_group("monaco_quay_wall")


func _make_retaining_walls() -> void:
	for wall_data in [
		[Vector3(-126.0, 0.0, 69.0), Vector3(-109.0, 0.0, 57.0)],
		[Vector3(-140.0, 0.0, 24.0), Vector3(-116.0, 0.0, 8.0)],
		[Vector3(-148.0, 0.0, -16.0), Vector3(-126.0, 0.0, -30.0)],
		[Vector3(126.0, 0.0, 69.0), Vector3(109.0, 0.0, 57.0)],
		[Vector3(139.0, 0.0, 25.0), Vector3(117.0, 0.0, 10.0)],
		[Vector3(149.0, 0.0, -17.0), Vector3(132.0, 0.0, -30.0)],
	]:
		_make_retaining_wall_segment(wall_data[0], wall_data[1])


func _make_retaining_wall_segment(from: Vector3, to: Vector3) -> void:
	var safe_segment := _shift_segment_beyond_road(from, to, 1.0)
	if safe_segment.is_empty():
		return
	from = safe_segment[0]
	to = safe_segment[1]
	var midpoint := (from + to) * 0.5
	var ground_from := ground_height_at(from.x, from.z)
	var ground_to := ground_height_at(to.x, to.z)
	var wall_height := 3.2
	var delta := to - from
	var wall := _make_rotated_box(
		"Corniche retaining wall",
		Vector3(midpoint.x, minf(ground_from, ground_to) + wall_height * 0.5, midpoint.z),
		Vector3(0.75, wall_height, Vector2(delta.x, delta.z).length()),
		MONACO_STONE,
		atan2(delta.x, delta.z),
		true,
		_stone_material(MONACO_STONE)
	)
	wall.add_to_group("monaco_retaining_wall")


func _shift_segment_beyond_road(
	from: Vector3,
	to: Vector3,
	minimum_clearance: float
) -> Array[Vector3]:
	var delta := to - from
	var flat_direction := Vector3(delta.x, 0.0, delta.z).normalized()
	var side := Vector3(-flat_direction.z, 0.0, flat_direction.x)
	for shift_step in 9:
		var shift_distance := float(shift_step) * 1.75
		for direction: float in [1.0, -1.0]:
			if shift_step == 0 and direction < 0.0:
				continue
			var shift: Vector3 = side * shift_distance * direction
			var candidate_from: Vector3 = from + shift
			var candidate_to: Vector3 = to + shift
			var is_clear := true
			for sample_index in 7:
				var weight := float(sample_index) / 6.0
				var sample: Vector3 = candidate_from.lerp(candidate_to, weight)
				if road_surface_clearance_at(sample) < minimum_clearance:
					is_clear = false
					break
			if is_clear:
				return [candidate_from, candidate_to]
	return []


func _make_monaco_neighbourhoods() -> void:
	var rows := [
		{"z": -184.0, "start": -208.0, "end": 208.0, "step": 27.0, "height": 12.0},
		{"z": -162.0, "start": -198.0, "end": 198.0, "step": 26.0, "height": 15.0},
		{"z": -142.0, "start": -174.0, "end": 174.0, "step": 29.0, "height": 14.0},
		{"z": -116.0, "start": -164.0, "end": 164.0, "step": 27.0, "height": 17.0},
		{"z": -72.0, "start": -176.0, "end": 178.0, "step": 28.0, "height": 13.0},
		{"z": -31.0, "start": -182.0, "end": 184.0, "step": 30.0, "height": 11.0},
		{"z": 12.0, "start": -174.0, "end": 176.0, "step": 31.0, "height": 10.0},
	]
	var building_index := 0
	for row: Dictionary in rows:
		var x := float(row.start)
		while x <= float(row.end):
			var width := 14.0 + float((building_index * 7) % 6)
			var depth := 10.5 + float((building_index * 5) % 4)
			var height := float(row.height) + float((building_index * 11) % 8)
			var position := Vector2(x, float(row.z) + float((building_index % 3) - 1) * 2.0)
			var footprint_radius := Vector2(width, depth).length() * 0.5
			if (
				ground_height_at(position.x, position.y) > WATER_LEVEL
				and road_surface_clearance_at(
					Vector3(position.x, 0.0, position.y)
				) > footprint_radius + 1.65
				and not _monaco_site_is_reserved(
					position,
					footprint_radius
				)
			):
				var district_style := (
					"Le Rocher old town"
					if float(row.z) <= -132.0 and position.x < -48.0
					else "Belle Epoque"
				)
				_make_monaco_residence(
					"Monaco hillside residence %02d" % building_index,
					position,
					Vector3(width, height, depth),
					MONACO_PALETTE[building_index % MONACO_PALETTE.size()],
					building_index,
					district_style,
					float((building_index % 5) - 2) * 0.025
				)
			building_index += 1
			x += float(row.step)
	# A few narrow glass towers punctuate the older urban fabric without
	# turning the whole level into an interchangeable modern skyline.
	for tower_data in [
		[Vector2(-219.0, -126.0), Vector3(16.0, 27.0, 13.0)],
		[Vector2(217.0, -137.0), Vector3(18.0, 25.0, 14.0)],
		[Vector2(220.0, -91.0), Vector3(17.0, 30.0, 13.0)],
	]:
		_make_modern_monaco_tower(
			"Modern harbour apartment tower %02d" % building_index,
			tower_data[0],
			tower_data[1],
			building_index
		)
		building_index += 1


func _make_monaco_infill() -> void:
	# The outer cycle route replaces some cliff-edge parcels. Rehouse that
	# density on compact inner plots so the circuit does not hollow Monaco out.
	const INFILL_TARGET := 52
	var placed := 0
	var candidate_index := 0
	for z in [
		-150.0,
		-134.0,
		-118.0,
		-102.0,
		-86.0,
		-70.0,
		-54.0,
		-38.0,
		-22.0,
		-6.0,
		10.0,
	]:
		for column_index in 27:
			if placed >= INFILL_TARGET:
				break
			var x := -208.0 + float(column_index) * 16.0
			var position := Vector2(
				x + sin(float(candidate_index) * 2.17) * 2.1,
				z + cos(float(candidate_index) * 1.71) * 1.5
			)
			# Monaco's inner lanes use genuinely narrow row houses. Besides
			# reading better than scattered villas, their smaller footprints
			# preserve urban density between the expanded road reservations.
			var width := 7.0 + float(candidate_index % 4) * 0.75
			var depth := 6.0 + float((candidate_index * 3) % 4) * 0.6
			var height := 9.5 + float((candidate_index * 7) % 8)
			var radius := Vector2(width, depth).length() * 0.5
			if not _monaco_parcel_is_clear(position, radius):
				candidate_index += 1
				continue
			var style := (
				"Le Rocher old town"
				if position.x < -72.0 and position.y < -96.0
				else "Belle Epoque"
			)
			_make_monaco_residence(
				"Monaco crooked lane infill %02d" % placed,
				position,
				Vector3(width, height, depth),
				MONACO_PALETTE[(candidate_index + 3) % MONACO_PALETTE.size()],
				candidate_index + 80,
				style,
				float((candidate_index % 7) - 3) * 0.04
			)
			placed += 1
			candidate_index += 1
		if placed >= INFILL_TARGET:
			break
	set_meta("monaco_infill_building_count", placed)


func _monaco_parcel_is_clear(at: Vector2, footprint_radius: float) -> bool:
	if (
		ground_height_at(at.x, at.y) <= WATER_LEVEL
		or road_surface_clearance_at(Vector3(at.x, 0.0, at.y))
		< footprint_radius + 1.65
		or _monaco_site_is_reserved(at, footprint_radius)
	):
		return false
	for clearing: Vector3 in _obstacle_clearings:
		var clearing_center := Vector2(clearing.x, clearing.y)
		if at.distance_to(clearing_center) < footprint_radius + clearing.z + 0.8:
			return false
	# Infill is searched procedurally after the neighbourhood rows exist. Keep
	# each new plot clear of those foundations and of earlier infill rather than
	# relying on hand-tuned row spacing.
	for foundation: Node in get_tree().get_nodes_in_group(
		"terrain_sealed_foundation"
	):
		if not foundation is Node3D or not is_ancestor_of(foundation):
			continue
		var foundation_3d := foundation as Node3D
		var existing_radius := float(
			foundation.get_meta("footprint_radius", 0.0)
		)
		if existing_radius <= 0.0:
			for child: Node in foundation.get_children():
				if child is CollisionShape3D and child.shape is BoxShape3D:
					var box_size := (child.shape as BoxShape3D).size
					existing_radius = Vector2(box_size.x, box_size.z).length() * 0.5
					break
		if existing_radius <= 0.0:
			continue
		var existing_center := Vector2(
			foundation_3d.global_position.x,
			foundation_3d.global_position.z
		)
		# Radius is the rectangle's diagonal and is intentionally conservative;
		# scaling it back approximates separating the actual wall faces while
		# the generated audit performs an exact polygon intersection afterward.
		if at.distance_to(existing_center) < (
			(footprint_radius + existing_radius) * 0.82 + 0.65
		):
			return false
	return true


func _queue_monaco_facade_box(
	category: String,
	parent: Node3D,
	at: Vector3,
	size: Vector3,
	rotation := Vector3.ZERO
) -> void:
	var basis := Basis.from_euler(rotation)
	basis.x *= size.x
	basis.y *= size.y
	basis.z *= size.z
	var world_transform := parent.transform * Transform3D(basis, at)
	(_monaco_facade_detail_transforms[category] as Array).append(
		world_transform
	)


func _flush_monaco_facade_batches() -> void:
	var window_material := _material(Color("294d60"))
	window_material.metallic = 0.18
	window_material.roughness = 0.27
	var tower_blue := _material(Color("315d70"))
	tower_blue.metallic = 0.42
	tower_blue.roughness = 0.2
	var tower_grey := _material(Color("365866"))
	tower_grey.metallic = 0.42
	tower_grey.roughness = 0.2
	# Textured shells carry distant facades; individual rails, shutters, and
	# boxes only need to exist around the rider's current blocks.
	var profiles := {
		"trim": [_material(Color("eee4ce")), 125.0],
		"rail": [_material(Color("354442")), 105.0],
		"planter": [_material(Color("8f5140")), 80.0],
		"window": [window_material, 120.0],
		"shutter_green": [_material(Color("328e88")), 105.0],
		"shutter_plum": [_material(Color("9266a0")), 105.0],
		"awning_red": [_material(Color("e76855")), 95.0],
		"awning_green": [_material(Color("239e97")), 95.0],
		"door": [_material(Color("49372f")), 90.0],
		"tower_glass_blue": [tower_blue, 160.0],
		"tower_glass_grey": [tower_grey, 160.0],
	}
	var batch_count := 0
	var instance_count := 0
	for category: String in _monaco_facade_detail_transforms:
		var transforms: Array = _monaco_facade_detail_transforms[category]
		if transforms.is_empty():
			continue
		var chunks := {}
		for transform: Transform3D in transforms:
			var chunk_coord := Vector2i(
				floori(transform.origin.x / MONACO_FACADE_CHUNK_SIZE),
				floori(transform.origin.z / MONACO_FACADE_CHUNK_SIZE)
			)
			if not chunks.has(chunk_coord):
				chunks[chunk_coord] = []
			(chunks[chunk_coord] as Array).append(transform)
		var profile: Array = profiles[category]
		for chunk_coord: Vector2i in chunks:
			var chunk_anchor := Vector3(
				(float(chunk_coord.x) + 0.5) * MONACO_FACADE_CHUNK_SIZE,
				0.0,
				(float(chunk_coord.y) + 0.5) * MONACO_FACADE_CHUNK_SIZE
			)
			var local_transforms: Array[Transform3D] = []
			for transform: Transform3D in chunks[chunk_coord]:
				local_transforms.append(Transform3D(
					transform.basis,
					transform.origin - chunk_anchor
				))
			var batch := _make_unit_box_multimesh(
				"Monaco facade %s %d_%d" % [
					category,
					chunk_coord.x,
					chunk_coord.y,
				],
				local_transforms,
				Color.WHITE,
				profile[0]
			)
			if batch == null:
				continue
			batch.position = chunk_anchor
			batch.cast_shadow = (
				GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			)
			batch.visibility_range_end = float(profile[1])
			batch.visibility_range_end_margin = 18.0
			batch.visibility_range_fade_mode = (
				GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			)
			batch.add_to_group("monaco_facade_detail_batch")
			batch.set_meta("facade_detail_category", category)
			batch_count += 1
			instance_count += local_transforms.size()
	set_meta("monaco_facade_batch_count", batch_count)
	set_meta("monaco_facade_detail_instance_count", instance_count)


func _make_monaco_residence(
	node_name: String,
	at: Vector2,
	size: Vector3,
	color: Color,
	variant: int,
	district_style := "Belle Epoque",
	rotation_y := 0.0
) -> void:
	var height_range := _footprint_height_range(
		Vector3(at.x, 0.0, at.y),
		size.x,
		size.z,
		rotation_y
	)
	var ground := height_range.y + 0.04
	var foundation_bottom := height_range.x - 0.62
	var foundation_height := ground - foundation_bottom + 0.08
	var foundation := _make_rotated_box(
		node_name + " fitted stone foundation",
		Vector3(at.x, foundation_bottom + foundation_height * 0.5, at.y),
		Vector3(size.x + 0.3, foundation_height, size.z + 0.3),
		MONACO_STONE.darkened(0.13),
		rotation_y,
		true,
		_stone_material(MONACO_STONE.darkened(0.13))
	)
	foundation.add_to_group("terrain_sealed_foundation")
	foundation.set_meta(
		"footprint_radius",
		Vector2(size.x + 0.3, size.z + 0.3).length() * 0.5
	)
	var building := _make_rotated_box(
		node_name,
		Vector3(at.x, ground + size.y * 0.5, at.y),
		size,
		color,
		rotation_y,
		true,
		_facade_material(color)
	)
	building.add_to_group("monaco_building")
	building.set_meta("district_style", district_style)
	_monaco_building_count += 1
	var roof_color := (
		Color("dc7150")
		if district_style == "Le Rocher old town" or variant % 3 != 0
		else Color("487b98")
	)
	if district_style == "Belle Epoque" and variant % 2 == 0:
		_make_hipped_roof(
			Vector3(at.x, ground + size.y, at.y),
			size.x,
			size.z,
			rotation_y,
			roof_color,
			31.0
		)
	else:
		_make_gabled_roof(
			Vector3(at.x, ground + size.y, at.y),
			size.x,
			size.z,
			rotation_y,
			roof_color,
			_facade_material(color.darkened(0.04)),
			34.0 if district_style == "Le Rocher old town" else 29.0
		)
	var floors := maxi(2, int(size.y / 3.1))
	var shutter_category := (
		"shutter_green" if variant % 2 == 0 else "shutter_plum"
	)
	for floor_index in floors:
		var floor_y := -size.y * 0.5 + 2.0 + float(floor_index) * 3.0
		if floor_y > size.y * 0.5 - 1.0:
			continue
		if district_style == "Belle Epoque":
			_queue_monaco_facade_box(
				"trim",
				building,
				Vector3(0.0, floor_y - 0.55, size.z * 0.5 + 0.38),
				Vector3(size.x * 0.76, 0.15, 0.9)
			)
			_queue_monaco_facade_box(
				"rail",
				building,
				Vector3(0.0, floor_y - 0.19, size.z * 0.5 + 0.81),
				Vector3(size.x * 0.74, 0.54, 0.06)
			)
			if floor_index == 0 or (floor_index + variant) % 3 == 0:
				for planter_x in [-size.x * 0.26, 0.0, size.x * 0.26]:
					_queue_monaco_facade_box(
						"planter",
						building,
						Vector3(
							planter_x,
							floor_y - 0.05,
							size.z * 0.5 + 0.86
						),
						Vector3(1.1, 0.23, 0.27)
					)
		var window_count := 2 if size.x < 16.0 else 3
		for window_index in window_count:
			var window_x := (
				(float(window_index) - float(window_count - 1) * 0.5)
				* size.x * (0.31 if window_count == 2 else 0.24)
			)
			_queue_monaco_facade_box(
				"window",
				building,
				Vector3(
					window_x,
					floor_y,
					size.z * 0.5 + 0.06
				),
				Vector3(1.3, 1.52, 0.08)
			)
			# Rear elevations are visible from the climbing roads and the new
			# coastal circuit. Varying rather than cloning every rear frontage
			# gives that view a real window rhythm without submitting another
			# full city's worth of tiny geometry.
			if variant % 3 == 0:
				_queue_monaco_facade_box(
					"window",
					building,
					Vector3(
						-window_x,
						floor_y,
						-size.z * 0.5 - 0.06
					),
					Vector3(1.3, 1.52, 0.08)
				)
			for shutter_side in [-1.0, 1.0]:
				_queue_monaco_facade_box(
					shutter_category,
					building,
					Vector3(
						window_x + shutter_side * 0.83,
						floor_y,
						size.z * 0.5 + 0.075
					),
					Vector3(0.34, 1.58, 0.07)
				)
	# Cornices and striped awnings make the Belle Époque frontage readable at
	# riding speed, while ochre Le Rocher houses stay tighter and plainer.
	if district_style == "Belle Epoque":
		_queue_monaco_facade_box(
			"trim",
			building,
			Vector3(0.0, size.y * 0.5 - 0.38, size.z * 0.5 + 0.2),
			Vector3(size.x + 0.3, 0.36, 0.5)
		)
		if variant % 3 == 0:
			_queue_monaco_facade_box(
				"awning_red" if variant % 2 == 0 else "awning_green",
				building,
				Vector3(0.0, -size.y * 0.5 + 2.35, size.z * 0.5 + 0.68),
				Vector3(size.x * 0.42, 0.15, 1.35),
				Vector3(-0.18, 0.0, 0.0)
			)
	_queue_monaco_facade_box(
		"door",
		building,
		Vector3(0.0, -size.y * 0.5 + 1.18, size.z * 0.5 + 0.065),
		Vector3(1.45, 2.35, 0.1)
	)
	_make_heritage_entry_stairs(
		node_name,
		Vector3(at.x, ground, at.y),
		size.z,
		rotation_y
	)


func _make_modern_monaco_tower(
	node_name: String,
	at: Vector2,
	size: Vector3,
	variant: int
) -> void:
	var footprint_radius := Vector2(size.x, size.z).length() * 0.5
	if not _monaco_parcel_is_clear(at, footprint_radius):
		return
	var height_range := _footprint_height_range(
		Vector3(at.x, 0.0, at.y),
		size.x,
		size.z,
		0.0
	)
	var base := height_range.y + 0.04
	# The fitted plinth is wider than the tower shell, so sample that complete
	# footprint. Sampling only the shell left its outer corners visibly aloft
	# on lateral slopes.
	var foundation_range := _footprint_height_range(
		Vector3(at.x, 0.0, at.y),
		size.x + 0.35,
		size.z + 0.35,
		0.0
	)
	var foundation_bottom := foundation_range.x - 0.62
	var foundation_height := base - foundation_bottom + 0.08
	var foundation := _make_box(
		node_name + " fitted stone foundation",
		Vector3(
			at.x,
			foundation_bottom + foundation_height * 0.5,
			at.y
		),
		Vector3(size.x + 0.35, foundation_height, size.z + 0.35),
		MONACO_STONE.darkened(0.16),
		true,
		_stone_material(MONACO_STONE.darkened(0.16))
	)
	foundation.add_to_group("terrain_sealed_foundation")
	foundation.set_meta(
		"footprint_radius",
		Vector2(size.x + 0.35, size.z + 0.35).length() * 0.5
	)
	var shell := _make_box(
		node_name,
		Vector3(at.x, base + size.y * 0.5, at.y),
		size,
		Color("9ba9a6"),
		true,
		_facade_material(Color("8fcac5"))
	)
	shell.add_to_group("monaco_building")
	shell.add_to_group("monaco_modern_tower")
	shell.set_meta("district_style", "Modern Monaco")
	_monaco_building_count += 1
	var glass_category := (
		"tower_glass_blue" if variant % 2 == 0 else "tower_glass_grey"
	)
	for floor_index in maxi(5, int(size.y / 2.7)):
		var floor_y := -size.y * 0.5 + 1.5 + float(floor_index) * 2.7
		if floor_y > size.y * 0.5 - 0.7:
			continue
		_queue_monaco_facade_box(
			glass_category,
			shell,
			Vector3(0.0, floor_y, size.z * 0.5 + 0.06),
			Vector3(size.x * 0.86, 1.55, 0.08)
		)
	var crown_mesh := BoxMesh.new()
	crown_mesh.size = Vector3(size.x + 0.55, 0.45, size.z + 0.55)
	_add_visual_mesh(
		"Modern tower roof terrace",
		crown_mesh,
		Vector3(0.0, size.y * 0.5 + 0.24, 0.0),
		_material(Color("d8d3c5")),
		Vector3.ZERO,
		shell
	)


func _monaco_site_is_reserved(at: Vector2, footprint_radius: float) -> bool:
	for reservation in [
		[Vector2(-4.0, -79.0), 22.0],
		[Vector2(-111.0, -122.0), 25.0],
		[Vector2(-157.0, -130.0), 18.0],
		[Vector2(183.0, -71.0), 20.0],
		[Vector2(-174.0, -104.0), 18.0],
		[Vector2(-204.0, 69.0), 20.0],
		[Vector2(192.0, 20.0), 20.0],
	]:
		if at.distance_to(reservation[0]) < footprint_radius + float(reservation[1]):
			return true
	return false


func _make_casino_quarter() -> void:
	var at := Vector2(-4.0, -79.0)
	var ground := ground_height_at(at.x, at.y)
	var casino := Node3D.new()
	casino.name = "Monte Carlo Casino"
	casino.position = Vector3(at.x, ground, at.y)
	casino.add_to_group("monaco_landmark")
	casino.add_to_group("casino_quarter")
	add_child(casino)
	var facade := _facade_material(Color("f6d891"))
	var wing_mesh := BoxMesh.new()
	wing_mesh.size = Vector3(25.0, 8.5, 12.0)
	_add_visual_mesh(
		"Belle Epoque casino hall",
		wing_mesh,
		Vector3(0.0, 4.25, 0.0),
		facade,
		Vector3.ZERO,
		casino
	)
	for side in [-1.0, 1.0]:
		var tower_mesh := BoxMesh.new()
		tower_mesh.size = Vector3(6.0, 11.0, 7.5)
		_add_visual_mesh(
			"Casino corner pavilion",
			tower_mesh,
			Vector3(side * 9.0, 5.5, -0.5),
			facade,
			Vector3.ZERO,
			casino
		)
		var dome_mesh := SphereMesh.new()
		dome_mesh.radius = 2.8
		dome_mesh.height = 3.2
		dome_mesh.radial_segments = 16
		dome_mesh.rings = 6
		_add_visual_mesh(
			"Verdigris casino dome",
			dome_mesh,
			Vector3(side * 9.0, 11.0, -0.5),
			_material(Color("5f8a79")),
			Vector3.ZERO,
			casino
		)
	for column_index in 7:
		var column_mesh := CylinderMesh.new()
		column_mesh.top_radius = 0.24
		column_mesh.bottom_radius = 0.3
		column_mesh.height = 4.6
		column_mesh.radial_segments = 10
		_add_visual_mesh(
			"Casino colonnade",
			column_mesh,
			Vector3(-7.8 + float(column_index) * 2.6, 3.1, 6.25),
			_material(Color("eee2c8")),
			Vector3.ZERO,
			casino
		)
	var casino_collision := _make_box(
		"Casino collision",
		Vector3(at.x, ground + 4.25, at.y),
		Vector3(25.0, 8.5, 12.0),
		Color.TRANSPARENT,
		true,
		_material(Color(0.0, 0.0, 0.0, 0.0))
	)
	casino_collision.visible = false


func _make_prince_palace() -> void:
	var at := Vector2(-111.0, -122.0)
	var ground := ground_height_at(at.x, at.y)
	var palace := Node3D.new()
	palace.name = "Prince's Palace"
	palace.position = Vector3(at.x, ground, at.y)
	palace.add_to_group("monaco_landmark")
	palace.add_to_group("palace")
	add_child(palace)
	var palace_material := _facade_material(Color("f3bf7b"))
	var main_mesh := BoxMesh.new()
	main_mesh.size = Vector3(28.0, 10.0, 16.0)
	_add_visual_mesh(
		"Palace main court",
		main_mesh,
		Vector3(0.0, 5.0, 0.0),
		palace_material,
		Vector3.ZERO,
		palace
	)
	for side in [-1.0, 1.0]:
		var tower_mesh := BoxMesh.new()
		tower_mesh.size = Vector3(6.5, 15.0, 7.0)
		_add_visual_mesh(
			"Palace watch tower",
			tower_mesh,
			Vector3(side * 11.0, 7.5, 0.0),
			palace_material,
			Vector3.ZERO,
			palace
		)
		var crenel_mesh := BoxMesh.new()
		crenel_mesh.size = Vector3(7.0, 0.7, 7.5)
		_add_visual_mesh(
			"Palace tower cornice",
			crenel_mesh,
			Vector3(side * 11.0, 15.1, 0.0),
			_material(Color("b6a27f")),
			Vector3.ZERO,
			palace
		)
	var flag_pole := CylinderMesh.new()
	flag_pole.top_radius = 0.07
	flag_pole.bottom_radius = 0.07
	flag_pole.height = 7.0
	flag_pole.radial_segments = 8
	_add_visual_mesh(
		"Palace flag pole",
		flag_pole,
		Vector3(0.0, 13.5, 0.0),
		_material(Color("d2d0c1")),
		Vector3.ZERO,
		palace
	)
	_make_monaco_flag(
		palace,
		Vector3(0.55, 15.0, 0.0),
		Vector2(2.3, 1.25)
	)


func _make_monaco_cathedral() -> void:
	var at := Vector2(-157.0, -130.0)
	var ground := ground_height_at(at.x, at.y)
	var cathedral := Node3D.new()
	cathedral.name = "Cathedral of Our Lady Immaculate"
	cathedral.position = Vector3(at.x, ground, at.y)
	cathedral.rotation.y = -0.08
	cathedral.add_to_group("monaco_landmark")
	cathedral.add_to_group("le_rocher_landmark")
	add_child(cathedral)
	var pale_stone := _stone_material(Color("d2c5a7"))
	var nave_mesh := BoxMesh.new()
	nave_mesh.size = Vector3(15.5, 10.5, 22.0)
	_add_visual_mesh(
		"Cathedral pale stone nave",
		nave_mesh,
		Vector3(0.0, 5.25, 0.0),
		pale_stone,
		Vector3.ZERO,
		cathedral
	)
	for side in [-1.0, 1.0]:
		var tower_mesh := BoxMesh.new()
		tower_mesh.size = Vector3(4.2, 16.5, 5.0)
		_add_visual_mesh(
			"Cathedral bell tower",
			tower_mesh,
			Vector3(side * 5.15, 8.25, 9.0),
			pale_stone,
			Vector3.ZERO,
			cathedral
		)
		var roof_mesh := CylinderMesh.new()
		roof_mesh.top_radius = 0.0
		roof_mesh.bottom_radius = 2.45
		roof_mesh.height = 3.5
		roof_mesh.radial_segments = 4
		_add_visual_mesh(
			"Cathedral tower roof",
			roof_mesh,
			Vector3(side * 5.15, 18.25, 9.0),
			_roof_material(Color("657178")),
			Vector3(0.0, PI * 0.25, 0.0),
			cathedral
		)
	var rose_mesh := CylinderMesh.new()
	rose_mesh.top_radius = 1.55
	rose_mesh.bottom_radius = 1.55
	rose_mesh.height = 0.12
	rose_mesh.radial_segments = 16
	_add_visual_mesh(
		"Cathedral rose window",
		rose_mesh,
		Vector3(0.0, 8.3, 11.05),
		_material(Color("385b67")),
		Vector3(PI * 0.5, 0.0, 0.0),
		cathedral
	)
	_make_gabled_roof(
		Vector3(at.x, ground + 10.5, at.y),
		15.5,
		22.0,
		cathedral.rotation.y,
		Color("718087"),
		pale_stone,
		38.0
	)
	_make_landmark_label(
		cathedral,
		"MONACO CATHEDRAL",
		Vector3(0.0, 13.0, 12.0)
	)


func _make_oceanographic_museum() -> void:
	var at := Vector2(183.0, -71.0)
	var ground := ground_height_at(at.x, at.y)
	var museum := Node3D.new()
	museum.name = "Oceanographic Museum"
	museum.position = Vector3(at.x, ground, at.y)
	museum.rotation.y = -0.2
	museum.add_to_group("monaco_landmark")
	museum.add_to_group("museum")
	add_child(museum)
	var stone := _stone_material(Color("b5aa91"))
	var hall_mesh := BoxMesh.new()
	hall_mesh.size = Vector3(24.0, 15.0, 13.0)
	_add_visual_mesh(
		"Cliff museum hall",
		hall_mesh,
		Vector3(0.0, 7.5, 0.0),
		stone,
		Vector3.ZERO,
		museum
	)
	for tower_x in [-9.0, 9.0]:
		var tower_mesh := CylinderMesh.new()
		tower_mesh.top_radius = 3.0
		tower_mesh.bottom_radius = 3.4
		tower_mesh.height = 17.0
		tower_mesh.radial_segments = 12
		_add_visual_mesh(
			"Museum sea tower",
			tower_mesh,
			Vector3(tower_x, 8.5, 0.0),
			stone,
			Vector3.ZERO,
			museum
		)


func _make_stade_louis_ii() -> void:
	var at := Vector2(-204.0, 69.0)
	var ground := ground_height_at(at.x, at.y)
	var stadium := Node3D.new()
	stadium.name = "Stade Louis II"
	stadium.position = Vector3(at.x, ground, at.y)
	stadium.rotation.y = 0.16
	stadium.add_to_group("monaco_landmark")
	stadium.add_to_group("fontvieille_landmark")
	add_child(stadium)
	var track_mesh := TorusMesh.new()
	track_mesh.inner_radius = 8.2
	track_mesh.outer_radius = 11.2
	track_mesh.rings = 14
	track_mesh.ring_segments = 28
	var track := _add_visual_mesh(
		"Stade running track",
		track_mesh,
		Vector3(0.0, 0.28, 0.0),
		_material(Color("a64f43")),
		Vector3.ZERO,
		stadium
	)
	track.scale.z = 1.48
	var pitch_mesh := CylinderMesh.new()
	pitch_mesh.top_radius = 7.9
	pitch_mesh.bottom_radius = 7.9
	pitch_mesh.height = 0.22
	pitch_mesh.radial_segments = 28
	var pitch := _add_visual_mesh(
		"Stade football pitch",
		pitch_mesh,
		Vector3(0.0, 0.22, 0.0),
		_material(Color("4f8553")),
		Vector3.ZERO,
		stadium
	)
	pitch.scale.z = 1.48
	for side in [-1.0, 1.0]:
		var stand_mesh := BoxMesh.new()
		stand_mesh.size = Vector3(4.2, 4.5, 28.0)
		_add_visual_mesh(
			"Stade covered stand",
			stand_mesh,
			Vector3(side * 13.4, 2.3, 0.0),
			_material(Color("d7d2c4")),
			Vector3.ZERO,
			stadium
		)
	_make_landmark_label(stadium, "STADE LOUIS II", Vector3(0.0, 6.4, 0.0))


func _make_grimaldi_forum() -> void:
	# Turn the long frontage parallel to the coast and keep its low exhibition
	# hall inside the outer cycle route. The former x=203 placement put the
	# entire glass tier and its fins across the new road.
	var at := Vector2(192.0, 20.0)
	var ground := ground_height_at(at.x, at.y)
	var forum := Node3D.new()
	forum.name = "Grimaldi Forum"
	forum.position = Vector3(at.x, ground, at.y)
	forum.rotation.y = 1.42
	forum.add_to_group("monaco_landmark")
	forum.add_to_group("modern_monaco_landmark")
	forum.add_to_group("roadside_visual_audit")
	add_child(forum)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color("376b7a")
	glass.metallic = 0.48
	glass.roughness = 0.17
	for tier_data in [
		[Vector3(0.0, 3.0, 0.0), Vector3(30.0, 6.0, 16.0)],
		[Vector3(-2.0, 7.4, -1.3), Vector3(25.0, 3.2, 13.0)],
	]:
		var tier_mesh := BoxMesh.new()
		tier_mesh.size = tier_data[1]
		_add_visual_mesh(
			"Forum glass exhibition tier",
			tier_mesh,
			tier_data[0],
			glass,
			Vector3.ZERO,
			forum
		)
	for column_x in [-11.0, -5.5, 0.0, 5.5, 11.0]:
		var column_mesh := BoxMesh.new()
		column_mesh.size = Vector3(0.35, 7.2, 0.5)
		_add_visual_mesh(
			"Forum pale structural fin",
			column_mesh,
			Vector3(column_x, 4.2, 8.15),
			_material(Color("d9d6c9")),
			Vector3.ZERO,
			forum
		)
	_make_landmark_label(forum, "GRIMALDI FORUM", Vector3(0.0, 10.2, 0.0))


func _make_jardin_exotique() -> void:
	# The former x=-204 site put the lowest 26 m terrace directly across the
	# western leg of the circumferential route.
	var at := Vector2(-174.0, -104.0)
	var ground := ground_height_at(at.x, at.y)
	var garden := Node3D.new()
	garden.name = "Jardin Exotique"
	garden.position = Vector3(at.x, ground, at.y)
	garden.add_to_group("monaco_landmark")
	garden.add_to_group("jardin_exotique")
	add_child(garden)
	for terrace_index in 3:
		var terrace_mesh := BoxMesh.new()
		terrace_mesh.size = Vector3(
			26.0 - float(terrace_index) * 4.0,
			0.7,
			6.0
		)
		_add_visual_mesh(
			"Exotic garden stone terrace",
			terrace_mesh,
			Vector3(
				0.0,
				float(terrace_index) * 1.35 + 0.35,
				float(terrace_index) * -5.4
			),
			_stone_material(Color("9e927c")),
			Vector3.ZERO,
			garden
		)
	_make_landmark_label(
		garden,
		"JARDIN EXOTIQUE",
		Vector3(0.0, 5.6, -5.5)
	)


func _make_fontvieille_marina() -> void:
	var marina := Node3D.new()
	marina.name = "Fontvieille Marina"
	marina.position = Vector3(-168.0, WATER_LEVEL, 139.0)
	marina.add_to_group("monaco_landmark")
	marina.add_to_group("fontvieille_landmark")
	add_child(marina)
	for pier_x in [-10.0, 0.0, 10.0]:
		var pier_mesh := BoxMesh.new()
		pier_mesh.size = Vector3(2.1, 0.32, 18.0)
		_add_visual_mesh(
			"Fontvieille floating pier",
			pier_mesh,
			Vector3(pier_x, 0.38, 0.0),
			_material(Color("8f795b")),
			Vector3.ZERO,
			marina
		)
	var harbour_boat := _make_distant_ship(
		"Fontvieille original motorboat",
		"motorboat",
		0.34
	)
	harbour_boat.position = marina.position + Vector3(-5.0, 0.45, 1.5)
	harbour_boat.rotation.y = 0.07
	harbour_boat.add_to_group("fontvieille_boat")
	_marina_yacht_motion.append({
		"node": harbour_boat,
		"origin": harbour_boat.position,
		"yaw": harbour_boat.rotation.y,
		"phase": 4.7,
	})


func _make_monaco_route_landmarks() -> void:
	var route_landmarks := [
		["Sainte-Devote", Vector3(-35.0, 0.0, -5.0)],
		["Beau Rivage · Massenet", Vector3(-20.0, 0.0, -29.0)],
		["Casino Square", Vector3(8.0, 0.0, -50.0)],
		["Mirabeau · Fairmont", Vector3(-28.0, 0.0, -62.0)],
		["Portier", Vector3(70.0, 0.0, -25.0)],
		["Grand Prix Tunnel", Vector3(91.0, 0.0, -43.0)],
		["Tabac", Vector3(58.0, 0.0, 30.0)],
		["Piscine Chicane", Vector3(86.0, 0.0, 47.0)],
		["La Rascasse", Vector3(-86.0, 0.0, 47.0)],
		["Anthony Noghes", Vector3(-94.0, 0.0, 78.0)],
	]
	for index in route_landmarks.size():
		var landmark_name: String = route_landmarks[index][0]
		var anchor: Vector3 = route_landmarks[index][1]
		var preferred_direction := Vector3(
			-1.0 if index % 2 == 0 else 1.0,
			0.0,
			-0.75 if index % 3 == 0 else 0.75
		).normalized()
		var sign_at := _find_clear_roadside_position(
			anchor,
			anchor + preferred_direction * 8.0,
			1.65
		)
		var ground := ground_height_at(sign_at.x, sign_at.z)
		var marker := Node3D.new()
		marker.name = landmark_name
		marker.position = Vector3(sign_at.x, ground, sign_at.z)
		marker.add_to_group("monaco_route_landmark")
		marker.set_meta("route_anchor", anchor)
		add_child(marker)
		var plaque_mesh := BoxMesh.new()
		plaque_mesh.size = Vector3(3.2, 0.82, 0.14)
		var facing := anchor - marker.position
		var plaque := _add_visual_mesh(
			"Grand Prix corner plaque",
			plaque_mesh,
			Vector3(0.0, 1.72, 0.0),
			_material(Color("273439")),
			Vector3(0.0, atan2(facing.x, facing.z), 0.0),
			marker
		)
		plaque.add_to_group("roadside_route_sign")
		var label := Label3D.new()
		label.name = "Corner name"
		label.text = landmark_name.to_upper()
		label.position = Vector3(0.0, 1.72, 0.09)
		label.rotation.y = plaque.rotation.y
		label.font_size = 32
		label.pixel_size = 0.009
		label.modulate = Color("f1dfac")
		label.outline_modulate = Color("172126")
		label.outline_size = 7
		label.visibility_range_end = 48.0
		label.visibility_range_fade_mode = (
			GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		)
		marker.add_child(label)
	set_meta("monaco_route_landmark_count", route_landmarks.size())


func _make_monaco_circuit_details() -> void:
	var selected_paths: Array[Dictionary] = []
	for road: Dictionary in _monaco_road_paths():
		if String(road.name) in ["Fairmont hairpin", "Port Hercule waterfront"]:
			selected_paths.append(road)
	var curb_count := 0
	var armco_count := 0
	for road: Dictionary in selected_paths:
		var points: Array[Vector3] = []
		points.assign(road.points)
		var half_width := float(road.width) * 0.5
		for index in points.size() - 1:
			var curb_segment: Array[Vector3] = [
				points[index],
				points[index + 1],
			]
			for side in [-1.0, 1.0]:
				_make_terrain_ribbon(
					"Monaco red-white curb %03d" % curb_count,
					_sample_polyline(curb_segment, 2.2),
					0.42,
					side * (half_width + 0.18),
					Color("d8584d") if (index + int(side)) % 2 == 0 else Color("eee6d4"),
					0.195
				)
				curb_count += 1
			if index % 2 != 0 or String(road.name) != "Fairmont hairpin":
				continue
			var from := points[index]
			var to := points[index + 1]
			var delta := to - from
			var flat_direction := Vector3(delta.x, 0.0, delta.z).normalized()
			var side_direction := Vector3(
				-flat_direction.z,
				0.0,
				flat_direction.x
			)
			var midpoint := (from + to) * 0.5 + side_direction * (half_width + 1.0)
			if road_surface_clearance_at(midpoint) < 0.65:
				continue
			var ground := ground_height_at(midpoint.x, midpoint.z)
			var rail_mesh := BoxMesh.new()
			rail_mesh.size = Vector3(
				0.16,
				0.62,
				Vector2(delta.x, delta.z).length() + 0.45
			)
			var rail := _add_visual_mesh(
				"Fairmont Armco barrier",
				rail_mesh,
				Vector3(midpoint.x, ground + 0.72, midpoint.z),
				_material(Color("aab1ae")),
				Vector3(0.0, atan2(delta.x, delta.z), 0.0),
				self
			)
			rail.add_to_group("monaco_armco")
			armco_count += 1
	set_meta("monaco_curb_section_count", curb_count)
	set_meta("monaco_armco_count", armco_count)


func _make_monaco_flag(
	parent: Node3D,
	at: Vector3,
	size: Vector2
) -> void:
	for stripe_index in 2:
		var flag_mesh := QuadMesh.new()
		flag_mesh.size = Vector2(size.x, size.y * 0.5)
		var flag_material := StandardMaterial3D.new()
		flag_material.albedo_color = (
			Color("d74d43") if stripe_index == 0 else Color("f3eee2")
		)
		flag_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		flag_material.roughness = 0.82
		var flag := _add_visual_mesh(
			"Monaco flag stripe",
			flag_mesh,
			at + Vector3(
				0.0,
				size.y * (0.25 if stripe_index == 0 else -0.25),
				0.0
			),
			flag_material,
			Vector3.ZERO,
			parent
		)
		flag.add_to_group("monaco_flag")


func _make_landmark_label(
	parent: Node3D,
	text: String,
	at: Vector3
) -> void:
	var label := Label3D.new()
	label.name = text.to_pascal_case()
	label.text = text
	label.position = at
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 42
	label.pixel_size = 0.012
	label.modulate = Color("f0d992")
	label.outline_modulate = Color("172126")
	label.outline_size = 9
	label.visibility_range_end = 95.0
	label.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	parent.add_child(label)


func _make_grand_prix_tunnel() -> void:
	var from := Vector3(83.0, 0.0, -42.0)
	var to := Vector3(116.0, 0.0, -38.0)
	from.y = ground_height_at(from.x, from.z)
	to.y = ground_height_at(to.x, to.z)
	var delta := to - from
	var flat_length := Vector2(delta.x, delta.z).length()
	var angle := atan2(delta.x, delta.z)
	var midpoint := (from + to) * 0.5
	var side := Vector3(-delta.z, 0.0, delta.x).normalized()
	var tunnel := Node3D.new()
	tunnel.name = "Larvotto Grand Prix tunnel"
	tunnel.add_to_group("monaco_landmark")
	tunnel.add_to_group("rideable_tunnel")
	tunnel.set_meta("lighting_transition", "bright-dark-bright")
	add_child(tunnel)
	for direction: float in [-1.0, 1.0]:
		var wall_center: Vector3 = midpoint + side * 10.0 * direction
		var wall := _make_rotated_box(
			"Tunnel side wall",
			Vector3(wall_center.x, midpoint.y + 2.7, wall_center.z),
			Vector3(0.75, 5.4, flat_length),
			Color("76736c"),
			angle,
			true,
			_stone_material(Color("76736c"))
		)
		wall.add_to_group("tunnel_structure")
	var roof := _make_rotated_box(
		"Tunnel roof",
		Vector3(midpoint.x, midpoint.y + 5.8, midpoint.z),
		Vector3(20.8, 0.8, flat_length),
		Color("5a5955"),
		angle,
		true,
		_stone_material(Color("5a5955"))
	)
	roof.add_to_group("tunnel_structure")
	var strip_material := StandardMaterial3D.new()
	strip_material.albedo_color = Color("ffe0ad")
	strip_material.emission_enabled = true
	strip_material.emission = Color("ffd69a")
	strip_material.emission_energy_multiplier = 2.2
	strip_material.roughness = 0.38
	for direction: float in [-1.0, 1.0]:
		var strip_center: Vector3 = midpoint + side * 6.8 * direction
		var strip_mesh := BoxMesh.new()
		strip_mesh.size = Vector3(0.11, 0.11, flat_length - 1.0)
		var strip := _add_visual_mesh(
			"Continuous tunnel ceiling light",
			strip_mesh,
			Vector3(strip_center.x, midpoint.y + 5.25, strip_center.z),
			strip_material,
			Vector3(0.0, angle, 0.0),
			self
		)
		strip.add_to_group("tunnel_emissive_strip")
	for portal_index in 2:
		var portal_center := from if portal_index == 0 else to
		for direction: float in [-1.0, 1.0]:
			var pylon_at := portal_center + side * 10.0 * direction
			var pylon_mesh := BoxMesh.new()
			pylon_mesh.size = Vector3(0.75, 6.2, 0.75)
			_add_visual_mesh(
				"Tunnel portal stone pier",
				pylon_mesh,
				Vector3(pylon_at.x, pylon_at.y + 3.1, pylon_at.z),
				_stone_material(Color("8e887b")),
				Vector3(0.0, angle, 0.0),
				self
			)
		var lintel_mesh := BoxMesh.new()
		lintel_mesh.size = Vector3(20.5, 0.85, 0.85)
		_add_visual_mesh(
			"Tunnel portal lintel",
			lintel_mesh,
			Vector3(portal_center.x, portal_center.y + 6.0, portal_center.z),
			_stone_material(Color("8e887b")),
			Vector3(0.0, angle, 0.0),
			self
		)
	var acoustic_zone := Area3D.new()
	acoustic_zone.name = "Tunnel acoustic and exposure zone"
	acoustic_zone.position = midpoint + Vector3.UP * 2.5
	acoustic_zone.rotation.y = angle
	acoustic_zone.collision_layer = 0
	acoustic_zone.collision_mask = 1
	acoustic_zone.add_to_group("tunnel_acoustic_zone")
	var zone_shape := BoxShape3D.new()
	zone_shape.size = Vector3(19.5, 5.0, flat_length)
	var zone_collision := CollisionShape3D.new()
	zone_collision.shape = zone_shape
	acoustic_zone.add_child(zone_collision)
	add_child(acoustic_zone)
	for light_index in 5:
		var weight := (float(light_index) + 0.5) / 5.0
		var position := from.lerp(to, weight) + Vector3.UP * 4.7
		var light := OmniLight3D.new()
		light.name = "Tunnel light %02d" % light_index
		light.position = position
		light.light_color = Color("ffd8a1")
		light.light_energy = 1.4
		light.omni_range = 9.0
		light.shadow_enabled = false
		light.add_to_group("tunnel_light")
		add_child(light)


func _make_larvotto_beach() -> void:
	var beach_marker := Node3D.new()
	beach_marker.name = "Larvotto Beach"
	beach_marker.position = Vector3(158.0, ground_height_at(158.0, 121.0), 121.0)
	beach_marker.add_to_group("monaco_landmark")
	beach_marker.add_to_group("larvotto_beach")
	add_child(beach_marker)
	var placed_parasols := 0
	for candidate in [
		Vector2(184.0, 112.0),
		Vector2(190.0, 111.0),
		Vector2(196.0, 109.0),
		Vector2(202.0, 106.0),
		Vector2(208.0, 102.0),
	]:
		var ground := ground_height_at(candidate.x, candidate.y)
		if (
			ground <= WATER_LEVEL
			or road_surface_clearance_at(
				Vector3(candidate.x, ground, candidate.y)
			) < 1.9
		):
			continue
		var parasol := Node3D.new()
		parasol.name = "Larvotto beach parasol %02d" % placed_parasols
		parasol.position = Vector3(candidate.x, ground, candidate.y)
		parasol.add_to_group("roadside_visual_audit")
		add_child(parasol)
		var pole_mesh := CylinderMesh.new()
		pole_mesh.top_radius = 0.06
		pole_mesh.bottom_radius = 0.06
		pole_mesh.height = 2.2
		pole_mesh.radial_segments = 8
		_add_visual_mesh(
			"Beach parasol pole",
			pole_mesh,
			Vector3(0.0, 1.1, 0.0),
			_material(Color("e4d5b4")),
			Vector3.ZERO,
			parasol
		)
		var shade_mesh := CylinderMesh.new()
		shade_mesh.top_radius = 0.08
		shade_mesh.bottom_radius = 1.55
		shade_mesh.height = 0.55
		shade_mesh.radial_segments = 14
		_add_visual_mesh(
			"Striped beach parasol",
			shade_mesh,
			Vector3(0.0, 2.25, 0.0),
			_material(
				Color("d95d4f")
				if placed_parasols % 2 == 0
				else Color("e9d9b8")
			),
			Vector3.ZERO,
			parasol
		)
		placed_parasols += 1
	set_meta("larvotto_parasol_count", placed_parasols)


func _make_mainland_mountain_backdrop() -> void:
	for index in 9:
		var mountain_mesh := SphereMesh.new()
		mountain_mesh.radius = 1.0
		mountain_mesh.height = 2.0
		mountain_mesh.radial_segments = 9
		mountain_mesh.rings = 5
		var mountain := MeshInstance3D.new()
		mountain.name = "Alpine foothill backdrop %02d" % index
		mountain.position = Vector3(
			-260.0 + float(index) * 65.0,
			14.0 + float((index * 7) % 13),
			-270.0 - float(index % 2) * 18.0
		)
		mountain.scale = Vector3(
			49.0 + float(index % 3) * 9.0,
			38.0 + float((index * 5) % 17),
			54.0
		)
		mountain.rotation_degrees = Vector3(
			float((index * 3) % 9) - 4.0,
			float(index * 23),
			float((index * 5) % 13) - 6.0
		)
		mountain.mesh = mountain_mesh
		mountain.material_override = _material(
			Color("55685c").lightened(float(index % 3) * 0.035)
		)
		mountain.add_to_group("monaco_mountain_backdrop")
		mountain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mountain)


func _make_monaco_hillside_gardens() -> void:
	var garden_positions: Array[Vector2] = [
		Vector2(-194.0, -86.0),
		Vector2(-171.0, -103.0),
		Vector2(-147.0, -92.0),
		Vector2(-123.0, -104.0),
		Vector2(-90.0, -112.0),
		Vector2(-54.0, -121.0),
		Vector2(-16.0, -126.0),
		Vector2(28.0, -121.0),
		Vector2(63.0, -113.0),
		Vector2(98.0, -105.0),
		Vector2(132.0, -95.0),
		Vector2(164.0, -84.0),
		Vector2(193.0, -68.0),
		Vector2(-181.0, 5.0),
		Vector2(-161.0, -5.0),
		Vector2(-139.0, -2.0),
		Vector2(-75.0, -36.0),
		Vector2(-53.0, -43.0),
		Vector2(66.0, -57.0),
		Vector2(130.0, -40.0),
		Vector2(177.0, 10.0),
		Vector2(-116.0, 92.0),
		Vector2(118.0, 92.0),
		Vector2(-216.0, -154.0),
		Vector2(-194.0, -169.0),
		Vector2(-154.0, -172.0),
		Vector2(-112.0, -168.0),
		Vector2(112.0, -169.0),
		Vector2(153.0, -171.0),
		Vector2(195.0, -153.0),
		Vector2(216.0, -121.0),
	]
	var placed := 0
	for index in garden_positions.size():
		var point := garden_positions[index]
		if (
			ground_height_at(point.x, point.y) <= WATER_LEVEL
			or road_surface_clearance_at(Vector3(point.x, 0.0, point.y)) < 5.0
		):
			continue
		_make_cypress_tree(point, index)
		placed += 1
	for flower_data in [
		[Vector2(-24.0, -72.0), Color("b64f87")],
		[Vector2(19.0, -71.0), Color("c14d72")],
		[Vector2(-101.0, -116.0), Color("b64f87")],
		[Vector2(147.0, -82.0), Color("c44f76")],
		[Vector2(109.0, 38.0), Color("b94b8e")],
	]:
		_make_bougainvillea_cluster(flower_data[0], flower_data[1])
	set_meta("monaco_cypress_count", placed)


func _make_batched_mediterranean_planting() -> void:
	var umbrella_pine_points := [
		Vector2(-214.0, -116.0),
		Vector2(-186.0, -132.0),
		Vector2(-142.0, -157.0),
		Vector2(-78.0, -157.0),
		Vector2(52.0, -160.0),
		Vector2(112.0, -150.0),
		Vector2(168.0, -131.0),
		Vector2(210.0, -102.0),
		Vector2(-207.0, 13.0),
		Vector2(207.0, 76.0),
	]
	var pine_trunks: Array[Transform3D] = []
	var pine_crowns: Array[Transform3D] = []
	for index in umbrella_pine_points.size():
		var point: Vector2 = umbrella_pine_points[index]
		if not _monaco_foliage_point_is_clear(point, 5.0):
			continue
		var ground := ground_height_at(point.x, point.y)
		var height := 4.7 + float(index % 3) * 0.55
		pine_trunks.append(Transform3D(
			Basis().scaled(Vector3(0.26, height, 0.26)),
			Vector3(point.x, ground + height * 0.5, point.y)
		))
		pine_crowns.append(Transform3D(
			Basis(Vector3.UP, float(index) * 0.77).scaled(
				Vector3(3.6, 1.15, 2.8)
			),
			Vector3(point.x, ground + height + 0.7, point.y)
		))
	var pine_trunk_batch := _make_unit_cylinder_multimesh(
		"Umbrella pine trunks",
		pine_trunks,
		Color("72533c")
	)
	var pine_crown_batch := _make_unit_sphere_multimesh(
		"Umbrella pine crowns",
		pine_crowns,
		Color("356647")
	)
	for batch in [pine_trunk_batch, pine_crown_batch]:
		if batch != null:
			batch.add_to_group("monaco_batched_foliage")
	if pine_trunk_batch != null:
		pine_trunk_batch.set_meta("road_audit_transforms", pine_trunks)
	if pine_crown_batch != null:
		pine_crown_batch.set_meta("road_audit_transforms", pine_crowns)

	var oleander_transforms: Array[Transform3D] = []
	var lavender_transforms: Array[Transform3D] = []
	for row_index in 8:
		for column_index in 18:
			var x := -216.0 + float(column_index) * 25.5
			var z := -188.0 + float(row_index) * 43.0
			var jitter := sin(float(column_index * 17 + row_index * 31)) * 7.0
			var point := Vector2(x + jitter, z + cos(jitter) * 5.0)
			if not _monaco_foliage_point_is_clear(point, 4.4):
				continue
			var ground := ground_height_at(point.x, point.y)
			if (column_index + row_index) % 3 == 0:
				oleander_transforms.append(Transform3D(
					Basis(Vector3.UP, float(column_index) * 0.63).scaled(
						Vector3(1.45, 0.95, 1.2)
					),
					Vector3(point.x, ground + 0.82, point.y)
				))
			else:
				for sprig_index in 3:
					var sprig_angle := float(sprig_index) * TAU / 3.0
					var sprig_at := point + Vector2.from_angle(sprig_angle) * 0.52
					lavender_transforms.append(Transform3D(
						Basis(Vector3.UP, sprig_angle).scaled(
							Vector3(0.22, 0.32, 0.22)
						),
						Vector3(
							sprig_at.x,
							ground + 0.28,
							sprig_at.y
						)
					))
	var oleander_batch := _make_unit_sphere_multimesh(
		"Oleander shrubs",
		oleander_transforms,
		Color("d66c91")
	)
	var lavender_batch := _make_unit_sphere_multimesh(
		"Lavender and rosemary",
		lavender_transforms,
		Color("7568a4")
	)
	for batch in [oleander_batch, lavender_batch]:
		if batch != null:
			batch.add_to_group("monaco_batched_foliage")
	if oleander_batch != null:
		oleander_batch.set_meta("road_audit_transforms", oleander_transforms)
	if lavender_batch != null:
		lavender_batch.set_meta("road_audit_transforms", lavender_transforms)

	var agave_transforms: Array[Transform3D] = []
	var agave_centers := [
		Vector2(-214.0, -83.0),
		Vector2(-205.0, -92.0),
		Vector2(-195.0, -80.0),
		Vector2(-187.0, -91.0),
		Vector2(196.0, 105.0),
		Vector2(211.0, 92.0),
	]
	for center_index in agave_centers.size():
		var center: Vector2 = agave_centers[center_index]
		if not _monaco_foliage_point_is_clear(center, 4.0):
			continue
		var ground := ground_height_at(center.x, center.y)
		for leaf_index in 7:
			var angle := TAU * float(leaf_index) / 7.0
			var basis := Basis(Vector3.UP, angle)
			basis = basis.rotated(basis.x, -0.48)
			basis = basis.scaled(Vector3(0.15, 0.055, 1.05))
			agave_transforms.append(Transform3D(
				basis,
				Vector3(
					center.x + cos(angle) * 0.55,
					ground + 0.38,
					center.y + sin(angle) * 0.55
				)
			))
	var agave_mesh := BoxMesh.new()
	agave_mesh.size = Vector3.ONE
	var agave_batch := _make_multimesh(
		"Jardin Exotique agave and aloe",
		agave_mesh,
		agave_transforms,
		_material(Color("4e7d63"))
	)
	if agave_batch != null:
		agave_batch.add_to_group("monaco_batched_foliage")
		agave_batch.set_meta("road_audit_transforms", agave_transforms)
	set_meta(
		"monaco_batched_plant_count",
		pine_crowns.size()
		+ oleander_transforms.size()
		+ lavender_transforms.size()
		+ agave_transforms.size()
	)


func _monaco_foliage_point_is_clear(
	point: Vector2,
	minimum_road_clearance: float
) -> bool:
	if not (
		point.x > TERRAIN_MIN_X + 5.0
		and point.x < TERRAIN_MAX_X - 5.0
		and point.y > TERRAIN_MIN_Z + 5.0
		and point.y < TERRAIN_MAX_Z - 5.0
		and ground_height_at(point.x, point.y) > WATER_LEVEL
		and road_surface_clearance_at(Vector3(point.x, 0.0, point.y))
		>= minimum_road_clearance
	):
		return false
	for foundation: Node in get_tree().get_nodes_in_group(
		"terrain_sealed_foundation"
	):
		if not foundation is Node3D or not is_ancestor_of(foundation):
			continue
		var foundation_3d := foundation as Node3D
		var radius := float(foundation.get_meta("footprint_radius", 0.0))
		if radius <= 0.0:
			for child: Node in foundation.get_children():
				if child is CollisionShape3D and child.shape is BoxShape3D:
					var box_size := (child.shape as BoxShape3D).size
					radius = Vector2(box_size.x, box_size.z).length() * 0.5
					break
		if radius <= 0.0:
			continue
		var center := Vector2(
			foundation_3d.global_position.x,
			foundation_3d.global_position.z
		)
		if point.distance_to(center) < radius * 0.82 + 1.1:
			return false
	return true


func _make_monaco_street_details() -> void:
	_make_casino_cafe_terrace()
	var parked_car_anchors := [
		[Vector3(-58.0, 0.0, 30.0), Vector3(-64.0, 0.0, 37.0), Color("6f2630")],
		[Vector3(58.0, 0.0, 30.0), Vector3(65.0, 0.0, 37.0), Color("284f68")],
		[Vector3(-112.0, 0.0, 2.0), Vector3(-119.0, 0.0, 8.0), Color("d7c9a4")],
		[Vector3(112.0, 0.0, 2.0), Vector3(120.0, 0.0, 7.0), Color("494a4b")],
		[Vector3(145.0, 0.0, 32.0), Vector3(151.0, 0.0, 39.0), Color("b34e42")],
	]
	var parked_count := 0
	for car_data in parked_car_anchors:
		var anchor: Vector3 = car_data[0]
		var parked_at := _find_clear_roadside_position(
			anchor,
			car_data[1],
			2.3
		)
		if road_surface_clearance_at(parked_at) < 2.3:
			continue
		_make_parked_sports_car(
			parked_at,
			anchor,
			car_data[2],
			parked_count
		)
		parked_count += 1
	set_meta("monaco_parked_car_count", parked_count)


func _make_casino_cafe_terrace() -> void:
	var anchor := Vector3(-4.0, 0.0, -79.0)
	var terrace_at := _find_clear_roadside_position(
		anchor,
		Vector3(23.0, 0.0, -77.0),
		6.0
	)
	if road_surface_clearance_at(terrace_at) < 6.0:
		return
	var ground := ground_height_at(terrace_at.x, terrace_at.z)
	var terrace := Node3D.new()
	terrace.name = "Cafe de Paris terrace"
	terrace.position = Vector3(terrace_at.x, ground, terrace_at.z)
	terrace.add_to_group("monaco_cafe_terrace")
	terrace.add_to_group("roadside_visual_audit")
	add_child(terrace)
	for table_index in 4:
		var x := float(table_index % 2) * 3.2 - 1.6
		var z := float(table_index / 2) * 3.2 - 1.6
		var table_mesh := CylinderMesh.new()
		table_mesh.top_radius = 0.72
		table_mesh.bottom_radius = 0.72
		table_mesh.height = 0.08
		table_mesh.radial_segments = 12
		_add_visual_mesh(
			"Cafe marble table",
			table_mesh,
			Vector3(x, 0.78, z),
			_material(Color("e1d9c8")),
			Vector3.ZERO,
			terrace
		)
		var pole_mesh := CylinderMesh.new()
		pole_mesh.top_radius = 0.04
		pole_mesh.bottom_radius = 0.05
		pole_mesh.height = 2.45
		pole_mesh.radial_segments = 7
		_add_visual_mesh(
			"Cafe parasol pole",
			pole_mesh,
			Vector3(x, 1.22, z),
			_material(Color("4d5656")),
			Vector3.ZERO,
			terrace
		)
		var shade_mesh := CylinderMesh.new()
		shade_mesh.top_radius = 0.08
		shade_mesh.bottom_radius = 1.35
		shade_mesh.height = 0.42
		shade_mesh.radial_segments = 14
		_add_visual_mesh(
			"Cafe striped parasol",
			shade_mesh,
			Vector3(x, 2.5, z),
			_material(Color("ad433c") if table_index % 2 == 0 else Color("e7d9bb")),
			Vector3.ZERO,
			terrace
		)


func _make_parked_sports_car(
	at: Vector3,
	road_anchor: Vector3,
	color: Color,
	index: int
) -> void:
	var ground := ground_height_at(at.x, at.z)
	var car := Node3D.new()
	car.name = "Parked Monaco sports car %02d" % index
	car.position = Vector3(at.x, ground + 0.36, at.z)
	var road_direction := road_anchor - at
	car.rotation.y = atan2(road_direction.x, road_direction.z) + PI * 0.5
	car.add_to_group("monaco_parked_car")
	add_child(car)
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(1.72, 0.54, 3.75)
	_add_visual_mesh(
		"Low sports car body",
		body_mesh,
		Vector3.ZERO,
		_material(color),
		Vector3.ZERO,
		car
	)
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.38, 0.55, 1.65)
	_add_visual_mesh(
		"Dark sports car cabin",
		cabin_mesh,
		Vector3(0.0, 0.43, 0.15),
		_material(Color("263942")),
		Vector3.ZERO,
		car
	)
	for wheel_x in [-0.91, 0.91]:
		for wheel_z in [-1.22, 1.22]:
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.31
			wheel_mesh.bottom_radius = 0.31
			wheel_mesh.height = 0.18
			wheel_mesh.radial_segments = 10
			_add_visual_mesh(
				"Sports car wheel",
				wheel_mesh,
				Vector3(wheel_x, -0.15, wheel_z),
				_material(Color("202426")),
				Vector3(0.0, 0.0, PI * 0.5),
				car
			)


func _make_cypress_tree(at: Vector2, index: int) -> void:
	var ground := ground_height_at(at.x, at.y)
	var tree := Node3D.new()
	tree.name = "Italian cypress %02d" % index
	tree.position = Vector3(at.x, ground, at.y)
	tree.add_to_group("monaco_garden_tree")
	add_child(tree)
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.1
	trunk_mesh.bottom_radius = 0.16
	trunk_mesh.height = 1.8
	trunk_mesh.radial_segments = 7
	_add_visual_mesh(
		"Cypress trunk",
		trunk_mesh,
		Vector3(0.0, 0.9, 0.0),
		_material(Color("66503a")),
		Vector3.ZERO,
		tree
	)
	var crown_mesh := CylinderMesh.new()
	crown_mesh.top_radius = 0.12
	crown_mesh.bottom_radius = 1.05
	crown_mesh.height = 5.6 + float(index % 3) * 0.45
	crown_mesh.radial_segments = 10
	_add_visual_mesh(
		"Cypress crown",
		crown_mesh,
		Vector3(0.0, 3.8, 0.0),
		_material(Color("315d42").lightened(float(index % 2) * 0.035)),
		Vector3.ZERO,
		tree
	)


func _make_bougainvillea_cluster(at: Vector2, color: Color) -> void:
	var ground := ground_height_at(at.x, at.y)
	var cluster := Node3D.new()
	cluster.name = "Bougainvillea terrace"
	cluster.position = Vector3(at.x, ground, at.y)
	cluster.add_to_group("monaco_flowers")
	add_child(cluster)
	for index in 9:
		var blossom_mesh := SphereMesh.new()
		blossom_mesh.radius = 0.42 + float(index % 3) * 0.1
		blossom_mesh.height = blossom_mesh.radius * 2.0
		blossom_mesh.radial_segments = 7
		blossom_mesh.rings = 4
		_add_visual_mesh(
			"Bougainvillea blossom",
			blossom_mesh,
			Vector3(
				float((index * 7) % 5) * 0.52 - 1.0,
				0.45 + float(index % 3) * 0.48,
				float((index * 11) % 4) * 0.38 - 0.55
			),
			_material(color.lightened(float(index % 2) * 0.06)),
			Vector3.ZERO,
			cluster
		)


func _make_monaco_palms() -> void:
	var palm_positions := [
		Vector2(-72.0, 35.0),
		Vector2(-52.0, 25.0),
		Vector2(-28.0, 20.0),
		Vector2(28.0, 20.0),
		Vector2(52.0, 25.0),
		Vector2(72.0, 35.0),
		Vector2(-105.0, 98.0),
		Vector2(105.0, 98.0),
		Vector2(127.0, 101.0),
		Vector2(151.0, 96.0),
		Vector2(176.0, 87.0),
	]
	var placed := 0
	for index in palm_positions.size():
		var point: Vector2 = palm_positions[index]
		var candidate := Vector3(point.x, 0.0, point.y)
		if road_surface_clearance_at(candidate) < 4.4:
			candidate = _find_clear_roadside_position(
				candidate,
				candidate,
				4.4
			)
			point = Vector2(candidate.x, candidate.z)
		if ground_height_at(point.x, point.y) <= WATER_LEVEL:
			continue
		_make_palm_tree(point, index)
		placed += 1
	set_meta("monaco_palm_count", placed)


func _make_palm_tree(at: Vector2, index: int) -> void:
	var ground := ground_height_at(at.x, at.y)
	var palm := Node3D.new()
	palm.name = "Mediterranean palm %02d" % index
	palm.position = Vector3(at.x, ground, at.y)
	palm.rotation.y = float(index) * 0.91
	palm.add_to_group("monaco_palm")
	add_child(palm)
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.3
	trunk_mesh.bottom_radius = 0.48
	trunk_mesh.height = 5.8
	trunk_mesh.radial_segments = 9
	_add_visual_mesh(
		"Palm trunk",
		trunk_mesh,
		Vector3(0.0, 2.9, 0.0),
		_material(Color("8b6a45")),
		Vector3.ZERO,
		palm
	)
	var leaf_material := _material(Color("35a477"))
	leaf_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for frond_index in 9:
		var angle := TAU * float(frond_index) / 9.0
		var frond_mesh := SphereMesh.new()
		frond_mesh.radius = 1.0
		frond_mesh.height = 2.0
		frond_mesh.radial_segments = 12
		frond_mesh.rings = 6
		var frond := _add_visual_mesh(
			"Sculpted palm frond", frond_mesh,
			Vector3(sin(angle) * 1.55, 5.95, cos(angle) * 1.55),
			leaf_material, Vector3(0.18, angle, 0.0), palm
		)
		frond.scale = Vector3(0.65, 0.22, 2.2)


func _make_marina_yachts() -> void:
	var yachts := [
		["sailing", Vector3(-42.0, WATER_LEVEL + 0.35, 76.0), -0.2, 0.42],
		["sailing", Vector3(-18.0, WATER_LEVEL + 0.35, 92.0), 0.14, 0.36],
		["motorboat", Vector3(24.0, WATER_LEVEL + 0.35, 74.0), -0.1, 0.38],
		["cruise", Vector3(51.0, WATER_LEVEL + 0.3, 102.0), 0.18, 0.28],
	]
	for index in yachts.size():
		var yacht_data: Array = yachts[index]
		var yacht := _make_distant_ship(
			"Port Hercule yacht %02d" % index,
			String(yacht_data[0]),
			float(yacht_data[3])
		)
		yacht.position = yacht_data[1]
		yacht.rotation.y = float(yacht_data[2])
		yacht.add_to_group("marina_yacht")
		_marina_yacht_motion.append({
			"node": yacht,
			"origin": yacht.position,
			"yaw": yacht.rotation.y,
			"phase": float(index) * 1.73,
		})
	set_meta("marina_yacht_count", yachts.size())


func _update_marina_yachts() -> void:
	for motion: Dictionary in _marina_yacht_motion:
		var yacht: Node3D = motion.node
		if not is_instance_valid(yacht):
			continue
		var phase := _world_motion_time * 0.58 + float(motion.phase)
		var origin: Vector3 = motion.origin
		yacht.position = origin + Vector3.UP * sin(phase) * 0.075
		yacht.rotation.y = float(motion.yaw) + sin(phase * 0.47) * 0.012
		yacht.rotation.z = sin(phase * 0.83) * 0.018


func _make_monaco_lamps() -> void:
	_lamp_bulb_material = _material(Color("5c594e"))
	var lamp_positions: Array[Vector2] = [
		Vector2(-75.0, 26.0),
		Vector2(-48.0, 18.0),
		Vector2(-18.0, 15.0),
		Vector2(18.0, 15.0),
		Vector2(48.0, 18.0),
		Vector2(75.0, 26.0),
		Vector2(-105.0, 70.0),
		Vector2(105.0, 70.0),
		Vector2(-72.0, -7.0),
		Vector2(64.0, -10.0),
		Vector2(-90.0, -76.0),
		Vector2(92.0, -70.0),
		Vector2(135.0, 101.0),
		Vector2(173.0, 91.0),
	]
	for index in lamp_positions.size():
		var point: Vector2 = lamp_positions[index]
		if road_surface_clearance_at(Vector3(point.x, 0.0, point.y)) < 1.15:
			var safe_point := _find_clear_roadside_position(
				Vector3(point.x, 0.0, point.y),
				Vector3(point.x, 0.0, point.y),
				1.4
			)
			point = Vector2(safe_point.x, safe_point.z)
		var ground := ground_height_at(point.x, point.y)
		var pole_mesh := CylinderMesh.new()
		pole_mesh.top_radius = 0.08
		pole_mesh.bottom_radius = 0.13
		pole_mesh.height = 4.1
		pole_mesh.radial_segments = 8
		var pole := _add_visual_mesh(
			"Monaco lamp post %02d" % index,
			pole_mesh,
			Vector3(point.x, ground + 2.05, point.y),
			_material(Color("283338")),
			Vector3.ZERO,
			self
		)
		pole.add_to_group("monaco_lamp_post")
		var bulb_mesh := SphereMesh.new()
		bulb_mesh.radius = 0.25
		bulb_mesh.height = 0.5
		bulb_mesh.radial_segments = 8
		bulb_mesh.rings = 4
		_add_visual_mesh(
			"Monaco lamp glass",
			bulb_mesh,
			Vector3(point.x, ground + 4.28, point.y),
			_lamp_bulb_material,
			Vector3.ZERO,
			self
		)
		var light := OmniLight3D.new()
		light.name = "Monaco street lamp light %02d" % index
		light.position = Vector3(point.x, ground + 4.28, point.y)
		light.light_color = Color("ffd692")
		light.light_energy = 0.0
		light.omni_range = 13.0
		light.shadow_enabled = false
		light.visible = false
		light.add_to_group("working_street_lamp")
		add_child(light)
		_street_lights.append(light)


func traffic_routes() -> Array[Array]:
	return [
		[
			Vector3(-35.0, 0.0, -5.0),
			Vector3(-20.0, 0.0, -29.0),
			Vector3(8.0, 0.0, -50.0),
			Vector3(42.0, 0.0, -46.0),
			Vector3(70.0, 0.0, -25.0),
			Vector3(85.0, 0.0, 10.0),
			Vector3(25.0, 0.0, -2.0),
		],
		[
			Vector3(-150.0, 0.0, 32.0),
			Vector3(-138.0, 0.0, 3.0),
			Vector3(-158.0, 0.0, -22.0),
			Vector3(-185.0, 0.0, -35.0),
			Vector3(-135.0, 0.0, -60.0),
			Vector3(-118.0, 0.0, -43.0),
			Vector3(-122.0, 0.0, -30.0),
			Vector3(-132.0, 0.0, -7.0),
			Vector3(-122.0, 0.0, 17.0),
		],
		[
			Vector3(145.0, 0.0, 32.0),
			Vector3(168.0, 0.0, 10.0),
			Vector3(158.0, 0.0, -22.0),
			Vector3(138.0, 0.0, -18.0),
			Vector3(116.0, 0.0, -38.0),
			Vector3(91.0, 0.0, -43.0),
			Vector3(72.0, 0.0, -35.0),
			Vector3(85.0, 0.0, 10.0),
		],
	]


func pedestrian_routes() -> Array[Array]:
	return [
		[
			Vector3(-68.0, 0.0, 35.0),
			Vector3(-28.0, 0.0, 24.0),
			Vector3(28.0, 0.0, 24.0),
			Vector3(68.0, 0.0, 35.0),
		],
		[
			Vector3(-30.0, 0.0, -72.0),
			Vector3(-8.0, 0.0, -68.0),
			Vector3(18.0, 0.0, -73.0),
			Vector3(4.0, 0.0, -84.0),
		],
		[
			Vector3(118.0, 0.0, 104.0),
			Vector3(145.0, 0.0, 99.0),
			Vector3(174.0, 0.0, 90.0),
			Vector3(192.0, 0.0, 80.0),
		],
		[
			Vector3(-126.0, 0.0, -68.0),
			Vector3(-92.0, 0.0, -84.0),
			Vector3(-52.0, 0.0, -95.0),
			Vector3(-22.0, 0.0, -98.0),
		],
	]


func wildlife_routes() -> Array[Array]:
	return [
		[
			Vector3(-174.0, 0.0, -83.0),
			Vector3(-160.0, 0.0, -92.0),
			Vector3(-147.0, 0.0, -79.0),
			Vector3(-158.0, 0.0, -67.0),
		],
		[
			Vector3(150.0, 0.0, 117.0),
			Vector3(164.0, 0.0, 113.0),
			Vector3(177.0, 0.0, 103.0),
			Vector3(161.0, 0.0, 101.0),
		],
	]


func pickup_locations() -> Array[Dictionary]:
	return [
		_shop_location("Condamine Market", Vector3(-55.0, 0.0, 29.0), "market_hall.png", 0),
		_shop_location("Cafe de Paris", Vector3(-18.0, 0.0, -29.0), "old_mill_bakery.png", 1),
		_shop_location("Port Hercule Pizzeria", Vector3(83.0, 0.0, 48.0), "quayside_pizzeria.png", 2),
		_shop_location("Riviera Sushi", Vector3(-91.0, 0.0, 70.0), "north_bank_sushi.png", 3),
		_shop_location("Monte Carlo Thai", Vector3(69.0, 0.0, -25.0), "hilltop_thai_kitchen.png", 4),
		_shop_location("Palace Burger Bar", Vector3(-119.0, 0.0, -44.0), "south_gate_burger_bar.png", 5),
		_shop_location("Larvotto Gelateria", Vector3(148.0, 0.0, 113.5), "boulangerie_du_pont.png", 6),
		_shop_location("Marina Yacht Club", Vector3(55.0, 0.0, 30.0), "market_hall.png", 7),
	]


func _shop_location(
	shop_name: String,
	position: Vector3,
	texture_name: String,
	index: int
) -> Dictionary:
	var side := -1.0 if index % 2 == 0 else 1.0
	var preferred := position + Vector3(side * 3.8, 0.0, -4.8)
	var sign_position := _find_clear_roadside_position(
		position,
		preferred,
		2.9
	)
	var facing := position - sign_position
	return {
		"name": shop_name,
		"position": position,
		"sign_position": sign_position,
		"sign_height": 2.2,
		"sign_rotation_y": atan2(facing.x, facing.z),
		"sign_size": Vector2(4.7, 1.55),
		"sign_texture": "res://assets/signs/shops/" + texture_name,
		"freestanding_sign": true,
	}


func _find_clear_roadside_position(
	road_anchor: Vector3,
	preferred: Vector3,
	minimum_clearance: float
) -> Vector3:
	if (
		ground_height_at(preferred.x, preferred.z) > WATER_LEVEL
		and road_surface_clearance_at(preferred) >= minimum_clearance
	):
		return preferred
	var preferred_direction := Vector2(
		preferred.x - road_anchor.x,
		preferred.z - road_anchor.z
	).normalized()
	if preferred_direction.is_zero_approx():
		preferred_direction = Vector2.RIGHT
	for radius in [7.0, 8.5, 10.0, 12.0, 14.0]:
		for offset_index in 16:
			var angle := (
				preferred_direction.angle()
				+ float(offset_index / 2 + 1)
				* (1.0 if offset_index % 2 == 0 else -1.0)
				* PI / 16.0
			)
			var direction := Vector2.from_angle(angle)
			var candidate := road_anchor + Vector3(
				direction.x * radius,
				0.0,
				direction.y * radius
			)
			if (
				ground_height_at(candidate.x, candidate.z) > WATER_LEVEL
				and road_surface_clearance_at(candidate) >= minimum_clearance
			):
				return candidate
	return preferred


func dropoff_locations() -> Array[Dictionary]:
	return [
		{"name": "Casino Square", "position": Vector3(-7.0, 0.0, -65.0)},
		{"name": "Prince's Palace", "position": Vector3(-118.0, 0.0, -61.0)},
		{"name": "Port Hercule", "position": Vector3(0.0, 0.0, 22.0)},
		{"name": "Larvotto Beach", "position": Vector3(171.0, 0.0, 110.0)},
		{"name": "Oceanographic Museum", "position": Vector3(158.0, 0.0, -22.0)},
		{"name": "Fairmont Hairpin", "position": Vector3(-28.0, 0.0, -62.0)},
		{"name": "Western Corniche", "position": Vector3(-150.0, 0.0, 32.0)},
		{"name": "Eastern Corniche", "position": Vector3(145.0, 0.0, 32.0)},
		{"name": "Hill Terraces", "position": Vector3(0.0, 0.0, -96.0)},
		{"name": "Yacht Club", "position": Vector3(58.0, 0.0, 30.0)},
	]
