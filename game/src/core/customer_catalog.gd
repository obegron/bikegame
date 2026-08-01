extends RefCounted
class_name CustomerCatalog

const PORTRAITS := {
	"marta": preload("res://assets/portraits/customers/marta_zielinska.png"),
	"leon": preload("res://assets/portraits/customers/leon_novak.png"),
	"amina": preload("res://assets/portraits/customers/amina_okafor.png"),
	"erik": preload("res://assets/portraits/customers/erik_lund.png"),
	"mei": preload("res://assets/portraits/customers/mei_tanaka.png"),
	"samira": preload("res://assets/portraits/customers/samira_haddad.png"),
	"elin": preload("res://assets/portraits/customers/elin_sorensen.png"),
}

const CUSTOMERS := {
	"marta": {
		"name": "Marta Zielińska",
		"role": "Garden designer",
		"lines": {
			"excellent": "Perfect timing—the herbs are still warm. Thank you!",
			"good": "Lovely, thank you. I hope the hill was kind to you.",
			"okay": "Thanks for bringing it all this way. Ride safely.",
			"late": "There you are! No harm done—mind the wet roads going back.",
		},
	},
	"leon": {
		"name": "Leon Novák",
		"role": "Architecture student",
		"lines": {
			"excellent": "You beat the app estimate! My model and I thank you.",
			"good": "Brilliant—dinner before the studio closes. Thanks!",
			"okay": "Made it! Thank you; that bridge can be confusing.",
			"late": "I was starting to sketch a search party. Thanks for finding me!",
		},
	},
	"amina": {
		"name": "Amina Okafor",
		"role": "Night-shift doctor",
		"lines": {
			"excellent": "Exactly when I got home. Thank you—and please ride safely.",
			"good": "That smells wonderful. You have rescued my evening.",
			"okay": "Thank you. A quiet meal is just what I needed.",
			"late": "Long evening for both of us, I think. Thank you for coming.",
		},
	},
	"erik": {
		"name": "Erik Lund",
		"role": "Harbour engineer",
		"lines": {
			"excellent": "Fast as the harbour launch. Fine work!",
			"good": "Right on time. Get something warm for yourself too.",
			"okay": "Cheers. The sea wind makes every route feel longer.",
			"late": "The tide waits for nobody, but supper can. Thanks, rider.",
		},
	},
	"mei": {
		"name": "Mei Tanaka",
		"role": "Violin teacher",
		"lines": {
			"excellent": "Wonderful timing—I can eat before my next lesson.",
			"good": "Thank you. You arrived on the very last note.",
			"okay": "Made it safely—that matters more than a few minutes.",
			"late": "A little late, but still very welcome. Thank you.",
		},
	},
	"samira": {
		"name": "Samira Haddad",
		"role": "Radio producer",
		"lines": {
			"excellent": "Perfect—you have saved tonight’s broadcast!",
			"good": "Excellent timing. I owe you a song request.",
			"okay": "Thank you! Live radio rarely runs to schedule either.",
			"late": "We missed the news jingle, not dinner. Thanks for making it.",
		},
	},
	"elin": {
		"name": "Elin Sørensen",
		"role": "Meadowcroft farmer",
		"dropoff_name": "Meadowcroft Farm",
		"lines": {
			"excellent": "That was quick! Come meet the geese before they steal your lunch.",
			"good": "Perfect, thank you. The animals have been waiting for me.",
			"okay": "Much appreciated. Mind the pigs—they are curious about bicycles.",
			"late": "You found us! Country lanes make every journey an adventure.",
		},
	},
}


static func get_order_profiles() -> Array[Dictionary]:
	var profiles: Array[Dictionary] = []
	for customer_id: String in CUSTOMERS:
		var profile := {
			"id": customer_id,
			"name": String(CUSTOMERS[customer_id].name),
		}
		var preferred_dropoff := String(CUSTOMERS[customer_id].get("dropoff_name", ""))
		if not preferred_dropoff.is_empty():
			profile["dropoff_name"] = preferred_dropoff
		profiles.append(profile)
	return profiles


static func get_name(customer_id: String) -> String:
	var customer: Dictionary = CUSTOMERS.get(customer_id, CUSTOMERS.marta)
	return String(customer.name)


static func get_role(customer_id: String) -> String:
	var customer: Dictionary = CUSTOMERS.get(customer_id, CUSTOMERS.marta)
	return String(customer.role)


static func get_portrait(customer_id: String) -> Texture2D:
	return PORTRAITS.get(customer_id, PORTRAITS.marta)


static func get_delivery_line(customer_id: String, rating: float) -> String:
	var tier := "excellent"
	if rating < 2.8:
		tier = "late"
	elif rating < 3.8:
		tier = "okay"
	elif rating < 4.8:
		tier = "good"
	var customer: Dictionary = CUSTOMERS.get(customer_id, CUSTOMERS.marta)
	var lines: Dictionary = customer.lines
	return String(lines.get(tier, lines.good))
