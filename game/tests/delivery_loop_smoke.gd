extends SceneTree

const DeliveryOrderType = preload("res://src/core/delivery_order.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed := load("res://scenes/delivery_game.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.get_node("Onboarding/Overlay").visible = false
	paused = false

	var orders = game.get_node("Services/OrderService")
	var economy = game.get_node("Services/EconomyService")
	var player = game.get_node("Player")
	var deliveries_before: int = economy.deliveries
	var money_before: float = economy.money
	orders.automatic_generation = false
	orders.offers.clear()
	for _delivery in 5:
		var order = orders.create_offer()
		_expect(order != null, "scene should generate a configured order")
		_expect(game.multiplayer_service.request_accept_order() == null, "accept request should be callable")
		_expect(order.state == DeliveryOrderType.State.TO_PICKUP, "accepted scene order should target pickup")

		player.global_position = order.pickup_position + Vector3(0.0, 0.9, 0.0)
		await process_frame
		_expect(order.state == DeliveryOrderType.State.TO_DROPOFF, "pickup proximity should advance the scene order")

		player.global_position = order.dropoff_position + Vector3(0.0, 0.9, 0.0)
		await process_frame
		_expect(orders.active_order == null, "drop-off proximity should complete the scene order")
	_expect(economy.deliveries == deliveries_before + 5, "five completions should pay five deliveries")
	_expect(economy.money > money_before, "completion should increase money")
	_expect(
		economy.money - money_before < 75.0,
		"five city deliveries should no longer produce oversized earnings"
	)
	_expect(
		game.last_result.has("customer_id")
		and not String(game.last_result.customer_dialogue).is_empty()
		and float(game.last_result.tip) <= 4.0,
		"a completed delivery should show modest pay and customer dialogue"
	)
	var result_portrait = game.get_node(
		"DeliveryHud/ResultPanel/Margin/ResultRow/CustomerPortrait"
	) as TextureRect
	_expect(
		result_portrait.visible and result_portrait.texture != null,
		"the delivery result should show the customer's portrait"
	)

	game.queue_free()
	await process_frame
	print("Delivery loop smoke test passed.")
	quit()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
