extends SceneTree

const DeliveryOrderType = preload("res://src/core/delivery_order.gd")
const EconomyServiceType = preload("res://src/core/economy_service.gd")
const OrderServiceType = preload("res://src/core/order_service.gd")
const WorldClockType = preload("res://src/core/world_clock.gd")
const CustomerCatalog = preload("res://src/core/customer_catalog.gd")


func _initialize() -> void:
	_test_clock_phases()
	_test_order_state_machine()
	_test_economy_bounds()
	print("Core services smoke test passed.")
	quit()


func _test_clock_phases() -> void:
	_expect(WorldClockType.get_phase_for_hour(7.0) == "morning", "07:00 should be morning")
	_expect(WorldClockType.get_phase_for_hour(12.0) == "noon", "12:00 should be noon")
	_expect(WorldClockType.get_phase_for_hour(19.0) == "sunset", "19:00 should be sunset")
	_expect(WorldClockType.get_phase_for_hour(23.0) == "night", "23:00 should be night")


func _test_order_state_machine() -> void:
	var service := OrderServiceType.new()
	service.automatic_generation = false
	service.set_random_seed(7)
	service.configure_locations(
		[{"name": "Cafe", "position": Vector3(0.0, 0.0, 0.0)}],
		[{"name": "Home", "position": Vector3(30.0, 0.0, 0.0)}]
	)
	service.configure_customers(CustomerCatalog.get_order_profiles())
	var order := service.create_offer()
	_expect(order != null, "an order should be generated")
	_expect(order.state == DeliveryOrderType.State.OFFERED, "new order should be offered")
	_expect(
		not order.customer_id.is_empty()
		and not order.customer_name.is_empty()
		and CustomerCatalog.get_portrait(order.customer_id) != null,
		"each order should retain a named customer with a portrait"
	)
	_expect(
		order.base_pay <= 3.5 and order.base_tip <= 0.5,
		"a short route should use the grounded courier fee and tip scale"
	)
	_expect(service.accept_first_offer(), "first offer should be accepted")
	_expect(order.state == DeliveryOrderType.State.TO_PICKUP, "accepted order should target pickup")
	_expect(service.mark_pickup_reached(), "pickup should advance the order")
	_expect(order.state == DeliveryOrderType.State.TO_DROPOFF, "pickup should target drop-off")
	var outcome := service.complete_active_order(2)
	_expect(not outcome.is_empty(), "drop-off should return an outcome")
	_expect(int(outcome.collisions) == 2, "collision count should survive the state machine")
	var restored := DeliveryOrderType.from_network_state(order.to_network_state())
	_expect(restored.id == order.id, "network state should preserve order identity")
	_expect(restored.dropoff_position == order.dropoff_position, "network state should preserve route")
	_expect(
		restored.customer_id == order.customer_id
		and restored.customer_name == order.customer_name,
		"network state should preserve the order customer"
	)

	var declined := service.create_offer()
	_expect(service.decline_first_offer(), "an offered order should be declineable")
	_expect(declined.state == DeliveryOrderType.State.DECLINED, "decline should be recorded")
	_expect(service.offers.is_empty(), "declined offers should leave the queue")

	service.offer_timeout_seconds = 5.0
	var expiring := service.create_offer()
	expiring.offer_age_seconds = 2.0
	var synchronized := DeliveryOrderType.from_network_state(expiring.to_network_state())
	_expect(
		is_equal_approx(synchronized.offer_age_seconds, 2.0),
		"network state should preserve offer countdown age"
	)
	service._process(3.1)
	_expect(expiring.state == DeliveryOrderType.State.EXPIRED, "unanswered offers should expire")
	_expect(service.offers.is_empty(), "expired offers should leave the queue")
	service.free()


func _test_economy_bounds() -> void:
	_expect(
		is_equal_approx(EconomyServiceType.calculate_rating(80.0, 90.0, 0), 5.0),
		"early clean delivery should be five stars"
	)
	_expect(
		EconomyServiceType.calculate_rating(500.0, 90.0, 20) >= 1.0,
		"rating should never fall below one"
	)
	_expect(
		EconomyServiceType.calculate_rating(90.0, 90.0, -3) <= 5.0,
		"rating should never exceed five"
	)
	var economy := EconomyServiceType.new()
	economy.set_random_seed(23)
	for _delivery in 20:
		var result := economy.apply_delivery_outcome({
			"elapsed_seconds": 70.0,
			"estimate_seconds": 90.0,
			"collisions": 0,
			"base_pay": 5.0,
			"base_tip": 1.5,
		})
		_expect(
			float(result.tip) <= 1.81
			and is_equal_approx(float(result.delivery_fee), 5.0)
			and float(result.pay) <= 6.81,
			"tips should remain optional and modest beside the delivery fee"
		)
	economy.free()
	_expect(
		CustomerCatalog.get_order_profiles().size() == 7,
		"the city should ship with seven illustrated customer characters"
	)
	var farm_service := OrderServiceType.new()
	farm_service.automatic_generation = false
	farm_service.set_random_seed(2)
	farm_service.configure_locations(
		[{"name": "Cafe", "position": Vector3.ZERO}],
		[
			{"name": "Town", "position": Vector3(10.0, 0.0, 0.0)},
			{"name": "Meadowcroft Farm", "position": Vector3(20.0, 0.0, 0.0)},
		]
	)
	farm_service.configure_customers([
		{
			"id": "elin",
			"name": "Elin Sørensen",
			"dropoff_name": "Meadowcroft Farm",
		},
	])
	var farm_order := farm_service.create_offer()
	_expect(
		farm_order.dropoff_name == "Meadowcroft Farm",
		"Elin's customer orders should always be delivered to her farm"
	)
	farm_service.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
