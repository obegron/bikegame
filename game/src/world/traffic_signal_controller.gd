extends Node3D
class_name TrafficSignalController

const GREEN_SECONDS := 7.0
const AMBER_SECONDS := 1.5
const HALF_CYCLE_SECONDS := GREEN_SECONDS + AMBER_SECONDS
const CYCLE_SECONDS := HALF_CYCLE_SECONDS * 2.0

var _elapsed := 0.0
var _heads: Array[Dictionary] = []
var _active_materials := {}
var _inactive_materials := {}
var _last_state := ""
var _head_setback := 5.7
var _head_inset := 5.1
var _terrain: Node


func configure(at: Vector3, phase_offset: float, head_setback := 5.7) -> void:
	position = at
	_elapsed = fposmod(phase_offset, CYCLE_SECONDS)
	_head_setback = head_setback
	_head_inset = head_setback - 0.6


func _ready() -> void:
	add_to_group("traffic_signal")
	_terrain = get_tree().get_first_node_in_group("terrain_provider")
	if _terrain != null and _terrain.has_method("ground_height_at"):
		position.y = _terrain.ground_height_at(position.x, position.z)
	_create_materials()
	_create_signal_head(
		Vector3(-_head_setback, 0.0, -_head_inset),
		"x",
		-PI * 0.5
	)
	_create_signal_head(
		Vector3(_head_setback, 0.0, _head_inset),
		"x",
		PI * 0.5
	)
	_create_signal_head(
		Vector3(_head_inset, 0.0, -_head_setback),
		"z",
		0.0
	)
	_create_signal_head(
		Vector3(-_head_inset, 0.0, _head_setback),
		"z",
		PI
	)
	_update_lamps()


func _process(delta: float) -> void:
	_elapsed = fposmod(_elapsed + delta, CYCLE_SECONDS)
	var state := get_signal_state()
	if state != _last_state:
		_update_lamps()


func get_signal_state() -> String:
	if _elapsed < GREEN_SECONDS:
		return "x_green"
	if _elapsed < HALF_CYCLE_SECONDS:
		return "x_amber"
	if _elapsed < HALF_CYCLE_SECONDS + GREEN_SECONDS:
		return "z_green"
	return "z_amber"


func should_stop(car_position: Vector3, movement_direction: Vector3) -> bool:
	var flat_direction := Vector2(movement_direction.x, movement_direction.z)
	if flat_direction.length_squared() < 0.1:
		return false
	var axis := "x" if absf(flat_direction.x) >= absf(flat_direction.y) else "z"
	if _axis_has_green(axis):
		return false

	var distance_to_line := 0.0
	var lateral_distance := 0.0
	if axis == "x":
		distance_to_line = (
			position.x - car_position.x
			if flat_direction.x > 0.0
			else car_position.x - position.x
		)
		lateral_distance = absf(car_position.z - position.z)
	else:
		distance_to_line = (
			position.z - car_position.z
			if flat_direction.y > 0.0
			else car_position.z - position.z
		)
		lateral_distance = absf(car_position.x - position.x)
	return distance_to_line > 2.4 and distance_to_line < 11.0 and lateral_distance < 4.8


func _axis_has_green(axis: String) -> bool:
	return get_signal_state() == "%s_green" % axis


func _create_materials() -> void:
	for lamp_name in ["red", "amber", "green"]:
		var color := {
			"red": Color("e33f36"),
			"amber": Color("f2ae36"),
			"green": Color("39bf68"),
		}[lamp_name] as Color
		var active := StandardMaterial3D.new()
		active.albedo_color = color
		active.emission_enabled = true
		active.emission = color
		active.emission_energy_multiplier = 3.0
		active.roughness = 0.28
		_active_materials[lamp_name] = active

		var inactive := StandardMaterial3D.new()
		inactive.albedo_color = color.darkened(0.76)
		inactive.roughness = 0.8
		_inactive_materials[lamp_name] = inactive


func _create_signal_head(offset: Vector3, axis: String, rotation_y: float) -> void:
	offset = _safe_grounded_head_offset(offset)
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.09
	pole_mesh.bottom_radius = 0.12
	pole_mesh.height = 4.3
	pole_mesh.radial_segments = 8
	var pole := MeshInstance3D.new()
	pole.position = offset + Vector3.UP * 2.15
	pole.mesh = pole_mesh
	pole.material_override = _solid_material(Color("253239"))
	pole.add_to_group("traffic_signal_pole")
	add_child(pole)

	var head := Node3D.new()
	head.position = offset + Vector3.UP * 4.45
	head.rotation.y = rotation_y
	add_child(head)

	var housing_mesh := BoxMesh.new()
	housing_mesh.size = Vector3(0.7, 1.72, 0.4)
	var housing := MeshInstance3D.new()
	housing.mesh = housing_mesh
	housing.material_override = _solid_material(Color("172126"))
	head.add_child(housing)

	var visor_mesh := BoxMesh.new()
	visor_mesh.size = Vector3(0.58, 0.12, 0.36)
	for y in [0.72, 0.18, -0.36]:
		var visor := MeshInstance3D.new()
		visor.position = Vector3(0.0, y, -0.31)
		visor.mesh = visor_mesh
		visor.material_override = _solid_material(Color("11191d"))
		head.add_child(visor)

	var lamp_mesh := SphereMesh.new()
	lamp_mesh.radius = 0.2
	lamp_mesh.height = 0.4
	lamp_mesh.radial_segments = 12
	lamp_mesh.rings = 6
	var lamps := {}
	for lamp_data in [
		["red", 0.53],
		["amber", 0.0],
		["green", -0.53],
	]:
		var lamp_name: String = lamp_data[0]
		var lamp := MeshInstance3D.new()
		lamp.position = Vector3(0.0, float(lamp_data[1]), -0.24)
		lamp.mesh = lamp_mesh
		head.add_child(lamp)
		lamps[lamp_name] = lamp
	_heads.append({"axis": axis, "lamps": lamps})


func _safe_grounded_head_offset(preferred_offset: Vector3) -> Vector3:
	if (
		_terrain == null
		or not _terrain.has_method("road_surface_clearance_at")
		or not _terrain.has_method("ground_height_at")
	):
		return preferred_offset
	var preferred_angle := Vector2(
		preferred_offset.x,
		preferred_offset.z
	).angle()
	var preferred_radius := Vector2(
		preferred_offset.x,
		preferred_offset.z
	).length()
	for radius_step in 8:
		var radius := preferred_radius + float(radius_step) * 1.5
		for angle_step in 17:
			var signed_step := (
				0
				if angle_step == 0
				else (angle_step + 1) / 2
				* (1 if angle_step % 2 == 1 else -1)
			)
			var angle := preferred_angle + float(signed_step) * PI / 18.0
			var local_candidate := Vector3(
				cos(angle) * radius,
				0.0,
				sin(angle) * radius
			)
			var world_candidate := to_global(local_candidate)
			if float(_terrain.call(
				"road_surface_clearance_at",
				world_candidate
			)) < 1.25:
				continue
			local_candidate.y = (
				float(_terrain.call(
					"ground_height_at",
					world_candidate.x,
					world_candidate.z
				))
				- global_position.y
			)
			return local_candidate
	var fallback := preferred_offset.normalized() * (preferred_radius + 12.0)
	var fallback_world := to_global(fallback)
	fallback.y = (
		float(_terrain.call(
			"ground_height_at",
			fallback_world.x,
			fallback_world.z
		))
		- global_position.y
	)
	return fallback


func _update_lamps() -> void:
	_last_state = get_signal_state()
	for head in _heads:
		var axis: String = head.axis
		var lamps: Dictionary = head.lamps
		var active_lamp := "red"
		if _last_state == "%s_green" % axis:
			active_lamp = "green"
		elif _last_state == "%s_amber" % axis:
			active_lamp = "amber"
		for lamp_name in lamps:
			var lamp := lamps[lamp_name] as MeshInstance3D
			lamp.material_override = (
				_active_materials[lamp_name]
				if lamp_name == active_lamp
				else _inactive_materials[lamp_name]
			)


func _solid_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.25
	material.roughness = 0.62
	return material
