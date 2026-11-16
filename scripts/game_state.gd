extends RefCounted
class_name AshenGameState

var gold: int = 24
var chapter: int = 1
var day: int = 1
var contract_days: int = 24
var contract_complete: bool = false
var tribute_goal: int = 35
var heat: float = 28.0
var quality: float = 8.0
var durability: float = 100.0
var has_blade: bool = true
var weapon_name: String = "Угольный клинок"
var weapon_id: String = "coal_blade"
var selected_weapon_id: String = "coal_blade"
var best_sale: int = 0
var total_blades: int = 0
var strikes_on_blade: int = 0
var frenzy_ready: bool = false
var frenzy_hits: int = 0
var last_forge_result: String = ""
var upgrades: Dictionary = {"bellows": 0, "anvil": 0, "luck": 0}
var relics: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"gold": gold, "chapter": chapter, "day": day,
		"contract_days": contract_days, "contract_complete": contract_complete,
		"tribute_goal": tribute_goal, "heat": heat, "quality": quality,
		"durability": durability, "has_blade": has_blade,
		"weapon_name": weapon_name, "weapon_id": weapon_id,
		"selected_weapon_id": selected_weapon_id, "best_sale": best_sale,
		"total_blades": total_blades, "strikes_on_blade": strikes_on_blade,
		"frenzy_ready": frenzy_ready, "frenzy_hits": frenzy_hits,
		"last_forge_result": last_forge_result, "upgrades": upgrades,
		"relics": relics
	}

func from_dict(data: Dictionary) -> void:
	gold = int(data.get("gold", gold))
	chapter = int(data.get("chapter", chapter))
	day = int(data.get("day", day))
	contract_days = int(data.get("contract_days", contract_days))
	contract_complete = bool(data.get("contract_complete", contract_complete))
	tribute_goal = int(data.get("tribute_goal", tribute_goal))
	heat = float(data.get("heat", heat))
	quality = float(data.get("quality", quality))
	durability = float(data.get("durability", durability))
	has_blade = bool(data.get("has_blade", has_blade))
	weapon_name = str(data.get("weapon_name", weapon_name))
	weapon_id = str(data.get("weapon_id", weapon_id))
	selected_weapon_id = str(data.get("selected_weapon_id", weapon_id))
	best_sale = int(data.get("best_sale", best_sale))
	total_blades = int(data.get("total_blades", total_blades))
	strikes_on_blade = int(data.get("strikes_on_blade", strikes_on_blade))
	frenzy_ready = bool(data.get("frenzy_ready", frenzy_ready))
	frenzy_hits = int(data.get("frenzy_hits", frenzy_hits))
	last_forge_result = str(data.get("last_forge_result", last_forge_result))
	var saved_upgrades = data.get("upgrades", upgrades)
	if saved_upgrades is Dictionary:
		upgrades = saved_upgrades
	var saved_relics = data.get("relics", relics)
	if saved_relics is Dictionary:
		relics = saved_relics
