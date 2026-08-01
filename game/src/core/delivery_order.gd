extends RefCounted
class_name DeliveryOrder

enum State {
	OFFERED,
	TO_PICKUP,
	TO_DROPOFF,
	COMPLETED,
	EXPIRED,
	DECLINED,
}

var id := 0
var kind := "Courier"
var pickup_name := ""
var pickup_position := Vector3.ZERO
var dropoff_name := ""
var dropoff_position := Vector3.ZERO
var customer_id := "marta"
var customer_name := "Marta Zielińska"
var base_pay := 4.0
var base_tip := 1.0
var estimate_seconds := 90.0
var elapsed_seconds := 0.0
var offer_age_seconds := 0.0
var state := State.OFFERED


func get_objective_position() -> Vector3:
	if state == State.TO_PICKUP:
		return pickup_position
	if state == State.TO_DROPOFF:
		return dropoff_position
	return Vector3.ZERO


func get_objective_name() -> String:
	if state == State.TO_PICKUP:
		return pickup_name
	if state == State.TO_DROPOFF:
		return dropoff_name
	return ""


func get_state_text() -> String:
	match state:
		State.OFFERED:
			return "Offered"
		State.TO_PICKUP:
			return "Ride to pickup"
		State.TO_DROPOFF:
			return "Ride to drop-off"
		State.COMPLETED:
			return "Completed"
		State.EXPIRED:
			return "Expired"
		_:
			return "Declined"


func to_network_state() -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"pickup_name": pickup_name,
		"pickup_position": pickup_position,
		"dropoff_name": dropoff_name,
		"dropoff_position": dropoff_position,
		"customer_id": customer_id,
		"customer_name": customer_name,
		"base_pay": base_pay,
		"base_tip": base_tip,
		"estimate_seconds": estimate_seconds,
		"elapsed_seconds": elapsed_seconds,
		"offer_age_seconds": offer_age_seconds,
		"state": state,
	}


static func from_network_state(data: Dictionary) -> DeliveryOrder:
	var order := DeliveryOrder.new()
	order.id = int(data.get("id", 0))
	order.kind = str(data.get("kind", "Courier"))
	order.pickup_name = str(data.get("pickup_name", ""))
	order.pickup_position = data.get("pickup_position", Vector3.ZERO)
	order.dropoff_name = str(data.get("dropoff_name", ""))
	order.dropoff_position = data.get("dropoff_position", Vector3.ZERO)
	order.customer_id = str(data.get("customer_id", "marta"))
	order.customer_name = str(data.get("customer_name", "Marta Zielińska"))
	order.base_pay = float(data.get("base_pay", 0.0))
	order.base_tip = float(data.get("base_tip", 0.0))
	order.estimate_seconds = float(data.get("estimate_seconds", 90.0))
	order.elapsed_seconds = float(data.get("elapsed_seconds", 0.0))
	order.offer_age_seconds = float(data.get("offer_age_seconds", 0.0))
	order.state = int(data.get("state", State.OFFERED)) as State
	return order
