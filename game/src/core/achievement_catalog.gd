extends RefCounted

const DEFINITIONS := [
	{
		"id": "first_delivery",
		"title": "First delivery",
		"texture": preload("res://assets/badges/first_delivery.png"),
	},
	{
		"id": "distance_1k",
		"title": "First kilometre",
		"texture": preload("res://assets/badges/distance_1k.png"),
	},
	{
		"id": "distance_5k",
		"title": "City explorer",
		"texture": preload("res://assets/badges/distance_5k.png"),
	},
	{
		"id": "active_10m",
		"title": "Ten active minutes",
		"texture": preload("res://assets/badges/active_10m.png"),
	},
	{
		"id": "all_day",
		"title": "Around the clock",
		"texture": preload("res://assets/badges/all_day.png"),
	},
	{
		"id": "five_star_five",
		"title": "Five-star streak",
		"texture": preload("res://assets/badges/five_star_five.png"),
	},
]


static func get_badge(id: String) -> Texture2D:
	for definition: Dictionary in DEFINITIONS:
		if String(definition.id) == id:
			return definition.texture
	return null


static func get_title(id: String) -> String:
	for definition: Dictionary in DEFINITIONS:
		if String(definition.id) == id:
			return String(definition.title)
	return id.replace("_", " ").capitalize()
