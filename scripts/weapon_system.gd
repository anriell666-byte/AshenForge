extends RefCounted
class_name AshenWeaponSystem

const WEAPONS := [
	{
		"id": "coal_blade", "name": "Угольный клинок", "base_value": 9.0,
		"quality_scale": 1.0, "durability_scale": 1.0, "heat_scale": 1.0,
		"break_risk": 1.0, "value_multiplier": 1.0, "unlock_chapter": 1,
		"merchant_only": false, "description": "Сбалансированная заготовка без слабых мест."
	},
	{
		"id": "ember_sabre", "name": "Сабля тлеющих углей", "base_value": 22.0,
		"quality_scale": 1.15, "durability_scale": 0.82, "heat_scale": 1.12,
		"break_risk": 1.12, "value_multiplier": 1.2, "unlock_chapter": 3,
		"merchant_only": false, "description": "Быстро набирает качество, но сильнее нагревается."
	},
	{
		"id": "wyrmfang", "name": "Клык дракона", "base_value": 55.0,
		"quality_scale": 1.35, "durability_scale": 1.22, "heat_scale": 0.92,
		"break_risk": 1.3, "value_multiplier": 1.65, "unlock_chapter": 6,
		"merchant_only": false, "description": "Драконья сталь дороже и капризнее в работе."
	},
	{
		"id": "glassfang", "name": "Стеклянная рапира", "base_value": 38.0,
		"quality_scale": 1.3, "durability_scale": 0.78, "heat_scale": 1.15,
		"break_risk": 1.18, "value_multiplier": 1.3, "unlock_chapter": 2,
		"merchant_only": true, "price": 95,
		"description": "Хрупкое лезвие. Быстро становится дорогим, но не прощает ошибок."
	},
	{
		"id": "frostbite", "name": "Морозный шип", "base_value": 44.0,
		"quality_scale": 1.05, "durability_scale": 1.2, "heat_scale": 0.72,
		"break_risk": 0.82, "value_multiplier": 1.5, "unlock_chapter": 4,
		"merchant_only": true, "price": 150,
		"description": "Холодная сталь медленно нагревается и выдерживает больше ударов."
	},
	{
		"id": "bloodiron", "name": "Кровавое железо", "base_value": 68.0,
		"quality_scale": 1.45, "durability_scale": 0.88, "heat_scale": 1.08,
		"break_risk": 1.35, "value_multiplier": 1.9, "unlock_chapter": 6,
		"merchant_only": true, "price": 240,
		"description": "Редкий сплав с огромной ценой и опасным характером."
	}
]

func get_weapon(weapon_id: String) -> Dictionary:
	for weapon in WEAPONS:
		if str(weapon.id) == weapon_id:
			return weapon
	return WEAPONS[0]

func unlocked(state: AshenGameState) -> Array:
	var result: Array = []
	for weapon in WEAPONS:
		var id := str(weapon.id)
		var available := false
		if bool(weapon.get("merchant_only", false)):
			available = state.owned_weapon_ids.has(id)
		else:
			available = state.chapter >= int(weapon.unlock_chapter)
		if available:
			result.append(weapon)
	return result

func next_weapon_id(state: AshenGameState, current_id: String) -> String:
	var available := unlocked(state)
	if available.size() <= 1:
		return current_id
	for index in range(available.size()):
		if str(available[index].id) == current_id:
			return str(available[(index + 1) % available.size()].id)
	return str(available[0].id)

func selection_text(state: AshenGameState) -> String:
	var weapon := get_weapon(state.selected_weapon_id)
	return "СЛЕДУЮЩАЯ ЗАГОТОВКА: %s\n%s" % [str(weapon.name), str(weapon.description)]
