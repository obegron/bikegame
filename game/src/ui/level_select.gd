extends Control
class_name LevelSelect

const LEVEL_SCENES := {
	"caledonian": "res://scenes/delivery_game.tscn",
	"monaco": "res://scenes/monaco_game.tscn",
}

@onready var _caledonian_button: Button = %CaledonianButton
@onready var _monaco_button: Button = %MonacoButton


func _ready() -> void:
	_connect_level_buttons()
	_focus_default_level()
	queue_redraw()


func _connect_level_buttons() -> void:
	_caledonian_button.pressed.connect(start_level.bind("caledonian"))
	_monaco_button.pressed.connect(start_level.bind("monaco"))


func _focus_default_level() -> void:
	_caledonian_button.grab_focus()


func start_level(level_id: String) -> void:
	var scene_path := get_level_scene_path(level_id)
	if scene_path.is_empty():
		return
	_caledonian_button.disabled = true
	_monaco_button.disabled = true
	get_tree().change_scene_to_file(scene_path)


func get_level_scene_path(level_id: String) -> String:
	return String(LEVEL_SCENES.get(level_id, ""))


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_1:
		start_level("caledonian")
	elif event.physical_keycode == KEY_2:
		start_level("monaco")


func _draw() -> void:
	var viewport_size := size
	# A restrained Mediterranean horizon behind the cards gives the menu a
	# sense of place without loading either expensive procedural city.
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("142a3d"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0.0, viewport_size.y * 0.56),
			Vector2(viewport_size.x * 0.15, viewport_size.y * 0.43),
			Vector2(viewport_size.x * 0.29, viewport_size.y * 0.5),
			Vector2(viewport_size.x * 0.47, viewport_size.y * 0.35),
			Vector2(viewport_size.x * 0.65, viewport_size.y * 0.46),
			Vector2(viewport_size.x * 0.82, viewport_size.y * 0.32),
			Vector2(viewport_size.x, viewport_size.y * 0.43),
			Vector2(viewport_size.x, viewport_size.y * 0.72),
			Vector2(0.0, viewport_size.y * 0.72),
		]),
		Color("4f665c")
	)
	draw_rect(
		Rect2(
			Vector2(0.0, viewport_size.y * 0.7),
			Vector2(viewport_size.x, viewport_size.y * 0.3)
		),
		Color("245b78")
	)
	for index in 10:
		var building_width := viewport_size.x / 16.0
		var x := float(index) * viewport_size.x / 9.0 - building_width * 0.5
		var height := 35.0 + float((index * 29) % 72)
		draw_rect(
			Rect2(
				Vector2(x, viewport_size.y * 0.7 - height),
				Vector2(building_width, height)
			),
			Color("c8aa82").lerp(Color("d7d4c7"), float(index % 3) * 0.32)
		)
	for wave_index in 6:
		var wave_y := viewport_size.y * 0.76 + float(wave_index) * 28.0
		draw_line(
			Vector2(0.0, wave_y),
			Vector2(viewport_size.x, wave_y - 7.0),
			Color(0.48, 0.77, 0.86, 0.2),
			2.0
		)
