extends SceneTree

const LevelSelectType = preload("res://src/ui/level_select.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed := load("res://scenes/level_select.tscn") as PackedScene
	var selector := packed.instantiate() as Control
	root.add_child(selector)
	await process_frame
	var island_button := selector.get_node(
		"Center/Panel/Margin/Content/Cards/Caledonian/CaledonianButton"
	) as Button
	var monaco_button := selector.get_node(
		"Center/Panel/Margin/Content/Cards/Monaco/MonacoButton"
	) as Button
	_expect(
		island_button != null
		and monaco_button != null
		and not island_button.disabled
		and not monaco_button.disabled,
		"startup should offer both playable levels"
	)
	_expect(
		selector.get_level_scene_path("caledonian") == "res://scenes/delivery_game.tscn"
		and selector.get_level_scene_path("monaco") == "res://scenes/monaco_game.tscn"
		and ResourceLoader.exists(selector.get_level_scene_path("caledonian"))
		and ResourceLoader.exists(selector.get_level_scene_path("monaco")),
		"both level choices should resolve to loadable gameplay scenes"
	)
	_expect(
		ProjectSettings.get_setting("application/run/main_scene")
		== "res://scenes/level_select.tscn",
		"the project should begin at level selection"
	)
	selector.queue_free()
	await process_frame
	print("Level selection smoke test passed.")
	quit()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
