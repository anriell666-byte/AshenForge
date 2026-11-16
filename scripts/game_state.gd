extends RefCounted
class_name AshenGameState

var gold: int = 24
var chapter: int = 1
var tribute_goal: int = 35
var heat: float = 28.0
var quality: float = 8.0
var durability: float = 100.0
var has_blade: bool = true
var weapon_name: String = "Угольный клинок"
var best_sale: int = 0
var total_blades: int = 0
var upgrades: Dictionary = {"bellows": 0, "anvil": 0, "luck": 0}

func to_dict() -> Dictionary:
	return {
		"gold": gold, "chapter": chapter, "tribute_goal": tribute_goal,
		"heat": heat, "quality": quality, "durability": durability,
		"has_blade": has_blade, "weapon_name": weapon_name,
		"best_sale": best_sale, "total_blades": total_blades,
		"upgrades": upgrades
	}

func from_dict(data: Dictionary) -> void:
	gold = int(data.get("gold", gold))
	chapter = int(data.get("chapter", chapter))
	tribute_goal = int(data.get("tribute_goal", tribute_goal))
	heat = float(data.get("heat", heat))
	quality = float(data.get("quality", quality))
	durability = float(data.get("durability", durability))
	has_blade = bool(data.get("has_blade", has_blade))
	weapon_name = str(data.get("weapon_name", weapon_name))
	best_sale = int(data.get("best_sale", best_sale))
	total_blades = int(data.get("total_blades", total_blades))
	var saved_upgrades = data.get("upgrades", upgrades)
	if saved_upgrades is Dictionary:
		upgrades = saved_upgrades
