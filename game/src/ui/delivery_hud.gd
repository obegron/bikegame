extends CanvasLayer

const DeliveryOrderType = preload("res://src/core/delivery_order.gd")
const AchievementCatalog = preload("res://src/core/achievement_catalog.gd")
const CustomerCatalog = preload("res://src/core/customer_catalog.gd")

@export var game_path: NodePath
@export var clock_path: NodePath
@export var player_path: NodePath
@export var weather_path: NodePath

@onready var game = get_node(game_path)
@onready var clock = get_node(clock_path)
@onready var player = get_node(player_path)
@onready var weather: Node = get_node_or_null(weather_path)
@onready var stats_label: Label = $TopBar/Margin/Stats
@onready var objective_label: Label = $ObjectivePanel/Margin/VBox/Objective
@onready var detail_label: Label = $ObjectivePanel/Margin/VBox/Detail
@onready var prompt_label: Label = $ObjectivePanel/Margin/VBox/Prompt
@onready var customer_row: HBoxContainer = $ObjectivePanel/Margin/VBox/CustomerRow
@onready var customer_portrait: TextureRect = $ObjectivePanel/Margin/VBox/CustomerRow/Portrait
@onready var customer_label: Label = $ObjectivePanel/Margin/VBox/CustomerRow/Customer
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_badge: TextureRect = $ResultPanel/Margin/ResultRow/Badge
@onready var result_portrait: TextureRect = $ResultPanel/Margin/ResultRow/CustomerPortrait
@onready var result_label: Label = $ResultPanel/Margin/ResultRow/Result


func _ready() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("183c46", 0.94)
	panel_style.set_corner_radius_all(16)
	panel_style.border_width_left = 4
	panel_style.border_color = Color("f3bd63")
	panel_style.shadow_color = Color(0.03, 0.1, 0.14, 0.2)
	panel_style.shadow_size = 8
	$ObjectivePanel.add_theme_stylebox_override("panel", panel_style)
	for label in [detail_label, prompt_label, customer_label]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$ObjectivePanel/Margin/VBox/CustomerRow/Portrait.custom_minimum_size = Vector2(56, 56)
	customer_row.custom_minimum_size.y = 56


func _process(_delta: float) -> void:
	_update_stats()
	_update_objective()
	_update_result()
	prompt_label.visible = not prompt_label.text.is_empty()
	var active: bool = game.get_active_order() != null or not game.get_offers().is_empty()
	$ObjectivePanel.size.x = minf(470.0 if active else 380.0, get_viewport().get_visible_rect().size.x - 36.0)
	_fit_objective_panel.call_deferred()


func _fit_objective_panel() -> void:
	# Fit after text wrapping and container sorting, without first collapsing
	# the panel to zero (which feeds stale widths back into autowrap sizing).
	$ObjectivePanel.size.y = $ObjectivePanel/Margin.get_combined_minimum_size().y


func _update_stats() -> void:
	var economy: Dictionary = game.get_economy_snapshot()
	var rating_text := "—" if economy.deliveries == 0 else "%0.1f" % economy.average_rating
	stats_label.text = (
		"$%0.2f     ★ %s     %d deliveries     %0.2f km     %s  %s  •  %s"
		% [
			economy.money,
			rating_text,
			economy.deliveries,
			game.distance_ridden_m / 1000.0,
			clock.get_time_text(),
			clock.get_phase().capitalize(),
			weather.get_weather_name() if weather != null else "Clear",
		]
	)


func _update_objective() -> void:
	var order = game.get_active_order()
	if order != null:
		_update_customer_card(order)
		objective_label.text = order.get_state_text().to_upper()
		detail_label.text = (
			"%s  •  %dm away  •  %ds / %ds estimate"
			% [
				order.get_objective_name(),
				int(round(game.get_objective_distance())),
				int(round(order.elapsed_seconds)),
				int(round(order.estimate_seconds)),
			]
		)
		prompt_label.text = "Pickup is automatic" if order.state == DeliveryOrderType.State.TO_PICKUP else "Drop-off is automatic"
		return

	var offers: Array = game.get_offers()
	if offers.is_empty():
		customer_row.visible = false
		objective_label.text = "LOOKING FOR ORDERS"
		detail_label.text = "Enjoy the ride—another offer is coming."
		prompt_label.text = ""
		return
	var offer = offers[0]
	_update_customer_card(offer)
	objective_label.text = "%s OFFER" % offer.kind.to_upper()
	detail_label.text = (
		"%s → %s  •  $%0.2f fee  •  about %ds"
		% [
			offer.pickup_name,
			offer.dropoff_name,
			offer.base_pay,
			int(offer.estimate_seconds),
		]
	)
	prompt_label.text = (
		"SPACE/A accept   •   Q/X decline   •   %ds"
		% int(ceil(game.get_offer_remaining_seconds(offer)))
	)


func _update_customer_card(order) -> void:
	customer_row.visible = true
	customer_portrait.texture = CustomerCatalog.get_portrait(String(order.customer_id))
	customer_label.text = "%s  •  %s\nWaiting at %s" % [
		String(order.customer_name),
		CustomerCatalog.get_role(String(order.customer_id)),
		String(order.dropoff_name),
	]


func _update_result() -> void:
	result_panel.visible = game.result_display_seconds > 0.0
	if not result_panel.visible:
		return
	var result: Dictionary = game.last_result
	if result.has("achievement"):
		result_badge.visible = true
		result_portrait.visible = false
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_badge.texture = AchievementCatalog.get_badge(
			String(result.get("achievement_id", ""))
		)
		result_label.text = "ACHIEVEMENT UNLOCKED\n%s" % result.achievement
		return
	result_badge.visible = false
	result_portrait.visible = true
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	result_portrait.texture = CustomerCatalog.get_portrait(
		String(result.get("customer_id", "marta"))
	)
	var delivery_fee := float(result.get(
		"delivery_fee",
		float(result.pay) - float(result.tip)
	))
	result_label.text = (
		"%s\n“%s”\n★ %0.1f     Fee $%0.2f     Tip $%0.2f     Total $%0.2f"
		% [
			String(result.get("customer_name", "Customer")).to_upper(),
			String(result.get("customer_dialogue", "Thank you!")),
			result.rating,
			delivery_fee,
			result.tip,
			result.pay,
		]
	)
