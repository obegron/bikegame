extends Node
class_name OrderService

const DeliveryOrderType = preload("res://src/core/delivery_order.gd")
const WorldClockType = preload("res://src/core/world_clock.gd")

signal order_offered(order: DeliveryOrderType)
signal order_accepted(order: DeliveryOrderType)
signal order_declined(order: DeliveryOrderType)
signal order_expired(order: DeliveryOrderType)
signal order_stage_changed(order: DeliveryOrderType)
signal order_completed(order: DeliveryOrderType, outcome: Dictionary)

@export_range(1, 2, 1) var maximum_offers := 2
@export var automatic_generation := true
@export var initial_offer_delay_seconds := 2.0
@export_range(5.0, 60.0, 1.0) var offer_timeout_seconds := 18.0

var world_clock: WorldClockType
var active_order: DeliveryOrderType
var offers: Array[DeliveryOrderType] = []

var _pickups: Array[Dictionary] = []
var _dropoffs: Array[Dictionary] = []
var _customers: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _next_id := 1
var _offer_timer := 2.0


func _ready() -> void:
	# Normal sessions should not repeat the same restaurant, customer, and
	# destination sequence. Tests can still call set_random_seed() explicitly.
	_rng.randomize()
	_offer_timer = initial_offer_delay_seconds


func _process(delta: float) -> void:
	_age_and_expire_offers(delta)
	if active_order != null:
		active_order.elapsed_seconds += delta
	if not automatic_generation or _pickups.is_empty() or _dropoffs.is_empty():
		return
	_offer_timer -= delta
	if _offer_timer <= 0.0 and offers.size() < maximum_offers:
		create_offer()
		_reset_offer_timer()


func set_random_seed(value: int) -> void:
	_rng.seed = value


func configure_locations(pickups: Array[Dictionary], dropoffs: Array[Dictionary]) -> void:
	_pickups = pickups.duplicate(true)
	_dropoffs = dropoffs.duplicate(true)


func configure_customers(customers: Array[Dictionary]) -> void:
	_customers = customers.duplicate(true)


func create_offer() -> DeliveryOrderType:
	if _pickups.is_empty() or _dropoffs.is_empty() or offers.size() >= maximum_offers:
		return null
	var pickup := _pickups[_rng.randi_range(0, _pickups.size() - 1)]
	var customer: Dictionary = (
		_customers[_rng.randi_range(0, _customers.size() - 1)]
		if not _customers.is_empty()
		else {"id": "marta", "name": "Marta Zielińska"}
	)
	var dropoff := _pick_dropoff_for_customer(customer)
	var context := (
		world_clock.get_order_context()
		if world_clock != null
		else {"kind": "Courier", "demand": 1.0, "tip_multiplier": 1.0}
	)
	var distance: float = pickup.position.distance_to(dropoff.position)

	var order := DeliveryOrderType.new()
	order.id = _next_id
	order.kind = context.kind
	order.pickup_name = pickup.name
	order.pickup_position = pickup.position
	order.dropoff_name = dropoff.name
	order.dropoff_position = dropoff.position
	order.customer_id = String(customer.id)
	order.customer_name = String(customer.name)
	# Compact city rides should feel like individual courier jobs, not lottery
	# payouts. Distance still matters, but a typical run now lands around
	# $4–$9 before the optional customer tip.
	order.base_pay = snappedf(2.5 + distance * 0.025, 0.25)
	order.base_tip = snappedf(
		(0.35 + distance * 0.0045) * float(context.tip_multiplier),
		0.25
	)
	order.estimate_seconds = maxf(55.0, distance / 5.25 + 32.0)
	_next_id += 1
	offers.append(order)
	order_offered.emit(order)
	return order


func _pick_dropoff_for_customer(customer: Dictionary) -> Dictionary:
	var preferred_name := String(customer.get("dropoff_name", ""))
	if not preferred_name.is_empty():
		for dropoff: Dictionary in _dropoffs:
			if String(dropoff.get("name", "")) == preferred_name:
				return dropoff
	return _dropoffs[_rng.randi_range(0, _dropoffs.size() - 1)]


func accept_first_offer() -> bool:
	if active_order != null or offers.is_empty():
		return false
	active_order = offers.pop_front()
	active_order.state = DeliveryOrderType.State.TO_PICKUP
	order_accepted.emit(active_order)
	order_stage_changed.emit(active_order)
	return true


func decline_first_offer() -> bool:
	if active_order != null or offers.is_empty():
		return false
	var declined: DeliveryOrderType = offers.pop_front()
	declined.state = DeliveryOrderType.State.DECLINED
	order_declined.emit(declined)
	_offer_timer = maxf(_offer_timer, 2.0)
	return true


func get_offer_remaining_seconds(order: DeliveryOrderType) -> float:
	if order == null:
		return 0.0
	return maxf(0.0, offer_timeout_seconds - order.offer_age_seconds)


func mark_pickup_reached() -> bool:
	if active_order == null or active_order.state != DeliveryOrderType.State.TO_PICKUP:
		return false
	active_order.state = DeliveryOrderType.State.TO_DROPOFF
	order_stage_changed.emit(active_order)
	return true


func complete_active_order(collisions: int) -> Dictionary:
	if active_order == null or active_order.state != DeliveryOrderType.State.TO_DROPOFF:
		return {}
	var completed := active_order
	completed.state = DeliveryOrderType.State.COMPLETED
	var outcome := {
		"order_id": completed.id,
		"elapsed_seconds": completed.elapsed_seconds,
		"estimate_seconds": completed.estimate_seconds,
		"collisions": maxi(0, collisions),
		"base_pay": completed.base_pay,
		"base_tip": completed.base_tip,
		"customer_id": completed.customer_id,
		"customer_name": completed.customer_name,
	}
	active_order = null
	order_completed.emit(completed, outcome)
	_reset_offer_timer()
	return outcome


func get_active_order() -> DeliveryOrderType:
	return active_order


func get_network_snapshot() -> Dictionary:
	var serialized_offers: Array[Dictionary] = []
	for order in offers:
		serialized_offers.append(order.to_network_state())
	return {
		"offers": serialized_offers,
		"active": active_order.to_network_state() if active_order != null else {},
	}


func apply_network_snapshot(snapshot: Dictionary) -> void:
	var synchronized_offers: Array[DeliveryOrderType] = []
	for data in snapshot.get("offers", []):
		if data is Dictionary:
			synchronized_offers.append(DeliveryOrderType.from_network_state(data))
	offers = synchronized_offers
	var active_data = snapshot.get("active", {})
	active_order = (
		DeliveryOrderType.from_network_state(active_data)
		if active_data is Dictionary and not active_data.is_empty()
		else null
	)


func _reset_offer_timer() -> void:
	var demand := 1.0
	if world_clock != null:
		demand = float(world_clock.get_order_context().demand)
	_offer_timer = 10.0 / maxf(demand, 0.25)


func _age_and_expire_offers(delta: float) -> void:
	var expired: Array[DeliveryOrderType] = []
	for order in offers:
		order.offer_age_seconds += delta
		if order.offer_age_seconds >= offer_timeout_seconds:
			expired.append(order)
	for order in expired:
		offers.erase(order)
		order.state = DeliveryOrderType.State.EXPIRED
		order_expired.emit(order)
