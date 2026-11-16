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
var owned_weapon_ids: Array = ["coal_blade"]
var weapon_awakened: bool = false
var awakened_weapon_id: String = ""
var best_sale: int = 0
var total_blades: int = 0
var strikes_on_blade: int = 0
var frenzy_ready: bool = false
var frenzy_hits: int = 0
var last_forge_result: String = ""
var upgrades: Dictionary = {"bellows": 0, "anvil": 0, "luck": 0}
var relics: Dictionary = {}
var battle_active: bool = false
var dragon_hp: float = 420.0
var dragon_max_hp: float = 420.0
var player_hp: float = 120.0
var dragon_round: int = 1
var dragon_phase: int = 1
var dragon_burn_turns: int = 0
var dragon_intent: String = "claw"
var dragon_defeated: bool = false
var dragon_victories: int = 0
var dragon_form: int = 0
var materials: Dictionary = {"dragon_ash": 0, "dragon_scales": 0, "void_cores": 0}
var weapon_temper_levels: Dictionary = {}
var dragon_armor_level: int = 0
var void_mastery_level: int = 0
var battle_items: Dictionary = {"healing_flask": 1, "dragon_bomb": 0, "ward_rune": 0}
var claimed_achievement_ids: Array = []

func to_dict() -> Dictionary:
	return {
		"gold": gold, "chapter": chapter, "day": day,
		"contract_days": contract_days, "contract_complete": contract_complete,
		"tribute_goal": tribute_goal, "heat": heat, "quality": quality,
		"durability": durability, "has_blade": has_blade,
		"weapon_name": weapon_name, "weapon_id": weapon_id,
		"selected_weapon_id": selected_weapon_id, "owned_weapon_ids": owned_weapon_ids,
		"weapon_awakened": weapon_awakened, "awakened_weapon_id": awakened_weapon_id,
		"best_sale": best_sale, "total_blades": total_blades,
		"strikes_on_blade": strikes_on_blade, "frenzy_ready": frenzy_ready,
		"frenzy_hits": frenzy_hits, "last_forge_result": last_forge_result,
		"upgrades": upgrades, "relics": relics,
		"battle_active": battle_active, "dragon_hp": dragon_hp,
		"dragon_max_hp": dragon_max_hp, "player_hp": player_hp,
		"dragon_round": dragon_round, "dragon_phase": dragon_phase,
		"dragon_burn_turns": dragon_burn_turns, "dragon_intent": dragon_intent,
		"dragon_defeated": dragon_defeated, "dragon_victories": dragon_victories,
		"dragon_form": dragon_form, "materials": materials,
		"weapon_temper_levels": weapon_temper_levels,
		"dragon_armor_level": dragon_armor_level,
		"void_mastery_level": void_mastery_level,
		"battle_items": battle_items,
		"claimed_achievement_ids": claimed_achievement_ids
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
	var saved_owned = data.get("owned_weapon_ids", ["coal_blade"])
	if saved_owned is Array:
		owned_weapon_ids = saved_owned.duplicate()
	weapon_awakened = bool(data.get("weapon_awakened", false))
	awakened_weapon_id = str(data.get("awakened_weapon_id", ""))
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
	battle_active = bool(data.get("battle_active", false))
	dragon_hp = float(data.get("dragon_hp", dragon_hp))
	dragon_max_hp = float(data.get("dragon_max_hp", dragon_max_hp))
	player_hp = float(data.get("player_hp", player_hp))
	dragon_round = int(data.get("dragon_round", dragon_round))
	dragon_phase = clampi(int(data.get("dragon_phase", 1)), 1, 3)
	dragon_burn_turns = clampi(int(data.get("dragon_burn_turns", 0)), 0, 5)
	dragon_intent = str(data.get("dragon_intent", dragon_intent))
	dragon_defeated = bool(data.get("dragon_defeated", false))
	dragon_victories = int(data.get("dragon_victories", 0))
	dragon_form = int(data.get("dragon_form", 0))
	var saved_materials = data.get("materials", materials)
	if saved_materials is Dictionary:
		materials = saved_materials
	var saved_temper = data.get("weapon_temper_levels", weapon_temper_levels)
	if saved_temper is Dictionary:
		weapon_temper_levels = saved_temper
	dragon_armor_level = clampi(int(data.get("dragon_armor_level", 0)), 0, 5)
	void_mastery_level = clampi(int(data.get("void_mastery_level", 0)), 0, 5)
	var saved_items = data.get("battle_items", battle_items)
	if saved_items is Dictionary:
		battle_items = saved_items
	var saved_achievements = data.get("claimed_achievement_ids", [])
	if saved_achievements is Array:
		claimed_achievement_ids = saved_achievements.duplicate()
