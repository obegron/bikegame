extends CanvasLayer

const SETTINGS_PATH := "user://settings.cfg"
const PAGES := [
	{
		"title": "RIDE YOUR WAY",
		"body": "Pedal with W or your bike. Lean—or use A and D—to steer.\nS brakes, and R safely returns you to the start.",
	},
	{
		"title": "DELIVER WITHOUT THE STRESS",
		"body": "Accept with Space/A, or simply ride into the offered pickup beacon.\nDecline with Q/X. Pickup and drop-off happen automatically.",
	},
	{
		"title": "SHOWING UP COUNTS",
		"body": "Money and ratings track the game. Distance and active time track the ride.\nCollisions slow you down, but never fail the delivery.",
	},
]

@onready var _overlay: Control = $Overlay
@onready var _title: Label = $Overlay/Center/Panel/Margin/VBox/Title
@onready var _body: Label = $Overlay/Center/Panel/Margin/VBox/Body
@onready var _next: Button = $Overlay/Center/Panel/Margin/VBox/Next

var _page := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("onboarding")
	_next.pressed.connect(_advance)
	if "--skip-onboarding" in OS.get_cmdline_user_args():
		_overlay.visible = false
		return
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	if bool(config.get_value("onboarding", "complete", false)):
		_overlay.visible = false
	else:
		call_deferred("_show_onboarding")


func _unhandled_input(event: InputEvent) -> void:
	if not _overlay.visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode in [KEY_SPACE, KEY_ENTER]:
		_advance()
	get_viewport().set_input_as_handled()


func _show_onboarding() -> void:
	_page = 0
	_overlay.visible = true
	get_tree().paused = true
	_refresh()


func _advance() -> void:
	_page += 1
	if _page >= PAGES.size():
		var config := ConfigFile.new()
		config.load(SETTINGS_PATH)
		config.set_value("onboarding", "complete", true)
		config.save(SETTINGS_PATH)
		_overlay.visible = false
		get_tree().paused = false
		return
	_refresh()


func _refresh() -> void:
	_title.text = PAGES[_page].title
	_body.text = PAGES[_page].body
	_next.text = "LET'S RIDE" if _page == PAGES.size() - 1 else "NEXT"
