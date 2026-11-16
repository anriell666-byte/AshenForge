extends RefCounted
class_name AshenWeaponSystem

const WEAPONS := [
	{
		"id": "coal_blade",
		"name": "Угольный клинок",
		"base_value": 9.0,
		"quality_scale": 1.0,
		"durability_scale": 1.0,
		"heat_scale": 1.0,
		"break_risk": 1.0,
		"value_multiplier": 1.0,
		"unlock_chapter": 1,
		"description": "Сбалансированная заготовка без слабых мест."
	},
	{
		"id": "ember_sabre",
		"name": "Сабля тлеющих углей",
		"base_value": 22.0,
		"quality_scale": 1.15,
		"durability_scale": 0.82,
		"heat_scale": 1.12,
		"break_risk": 1.12,
		"value_multiplier": 1.2,
		"unlock_chapter": 3,
		"description": "Быстро набирает качество, но сильнее нагревается."
	},
	{
		"id": "wyrmfang",
		"name": "Клык дракона",
		"base_value": 55.0,
		"quality_scale": 1.35,
		"durability_scale": 1.22,
		"heat_scale": 0.92,
		"break_risk": 1.3,
		"value_multiplier": 1.65,
		"unlock_chapter": 6,
		"description": "Драконья сталь дороже и капризнее в работе."
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
		if state.chapter >= int(weapon.unlock_chapter):
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
