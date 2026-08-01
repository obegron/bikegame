extends Node
class_name EconomyService

signal economy_changed(snapshot: Dictionary)
signal delivery_paid(result: Dictionary)

var money := 0.0
var deliveries := 0
var five_star_streak := 0
var best_five_star_streak := 0
var rating_total := 0.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Tip occurrence and variance get a fresh stream each launch. Deterministic
	# tests and future replay tooling can override it through set_random_seed().
	_rng.randomize()


func set_random_seed(value: int) -> void:
	_rng.seed = value


func apply_delivery_outcome(outcome: Dictionary) -> Dictionary:
	var rating := calculate_rating(
		float(outcome.elapsed_seconds),
		float(outcome.estimate_seconds),
		int(outcome.collisions)
	)
	var rating_weight := (rating - 1.0) / 4.0
	var tip_chance := lerpf(0.12, 0.82, rating_weight)
	var tip := 0.0
	if _rng.randf() <= tip_chance:
		var rating_multiplier := lerpf(0.08, 1.0, rating_weight)
		var tip_variance := _rng.randf_range(0.65, 1.2)
		tip = snappedf(
			float(outcome.base_tip) * rating_multiplier * tip_variance,
			0.1
		)
	var delivery_fee := snappedf(float(outcome.base_pay), 0.1)
	var pay := snappedf(delivery_fee + tip, 0.1)

	money += pay
	deliveries += 1
	rating_total += rating
	if is_equal_approx(rating, 5.0):
		five_star_streak += 1
		best_five_star_streak = maxi(best_five_star_streak, five_star_streak)
	else:
		five_star_streak = 0

	var result := {
		"rating": rating,
		"tip": tip,
		"delivery_fee": delivery_fee,
		"pay": pay,
		"money": money,
		"deliveries": deliveries,
	}
	delivery_paid.emit(result)
	economy_changed.emit(get_snapshot())
	return result


func get_average_rating() -> float:
	if deliveries == 0:
		return 0.0
	return rating_total / float(deliveries)


func get_snapshot() -> Dictionary:
	return {
		"money": money,
		"deliveries": deliveries,
		"average_rating": get_average_rating(),
		"five_star_streak": five_star_streak,
		"best_five_star_streak": best_five_star_streak,
	}


func get_save_data() -> Dictionary:
	return {
		"money": money,
		"deliveries": deliveries,
		"five_star_streak": five_star_streak,
		"best_five_star_streak": best_five_star_streak,
		"rating_total": rating_total,
	}


func load_save_data(data: Dictionary) -> void:
	money = maxf(0.0, float(data.get("money", 0.0)))
	deliveries = maxi(0, int(data.get("deliveries", 0)))
	five_star_streak = maxi(0, int(data.get("five_star_streak", 0)))
	best_five_star_streak = maxi(
		five_star_streak,
		int(data.get("best_five_star_streak", five_star_streak))
	)
	rating_total = maxf(0.0, float(data.get("rating_total", 0.0)))
	economy_changed.emit(get_snapshot())


static func calculate_rating(
	elapsed_seconds: float,
	estimate_seconds: float,
	collisions: int
) -> float:
	var safe_estimate := maxf(estimate_seconds, 1.0)
	var lateness_ratio := maxf(0.0, elapsed_seconds - safe_estimate) / safe_estimate
	var late_penalty := minf(lateness_ratio * 2.5, 3.0)
	var collision_penalty := minf(float(maxi(collisions, 0)) * 0.35, 2.0)
	return snappedf(clampf(5.0 - late_penalty - collision_penalty, 1.0, 5.0), 0.1)
