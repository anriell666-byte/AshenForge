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
	},
	{
		"id": "ashen_greatsword", "name": "Двуручник Пепельного стража", "base_value": 74.0,
		"quality_scale": 0.88, "durability_scale": 1.35, "heat_scale": 0.90,
		"break_risk": 0.85, "value_multiplier": 1.75, "unlock_chapter": 1,
		"merchant_only": true, "craft_only": true, "recipe_gold": 180,
		"recipe_ash": 2, "recipe_scales": 1, "recipe_cores": 0,
		"description": "Тяжёлый клинок: медленнее растёт качество, зато выдерживает долгую ковку."
	},
	{
		"id": "rift_spear", "name": "Копьё Разлома", "base_value": 82.0,
		"quality_scale": 1.22, "durability_scale": 0.90, "heat_scale": 0.95,
		"break_risk": 1.10, "value_multiplier": 1.90, "unlock_chapter": 1,
		"merchant_only": true, "craft_only": true, "recipe_gold": 220,
		"recipe_ash": 1, "recipe_scales": 0, "recipe_cores": 1,
		"description": "Пробивает защиту драконов и раскрывает силу на поздних фазах боя."
	},
	{
		"id": "storm_twins", "name": "Парные клинки Грозы", "base_value": 62.0,
		"quality_scale": 1.50, "durability_scale": 0.75, "heat_scale": 1.18,
		"break_risk": 1.25, "value_multiplier": 1.70, "unlock_chapter": 1,
		"merchant_only": true, "craft_only": true, "recipe_gold": 260,
		"recipe_ash": 0, "recipe_scales": 1, "recipe_cores": 1,
		"description": "Быстрые парные клинки: высокая отдача, но требуют точной работы с жаром."
	}
]

const FINAL_FORMS := {
	"coal_blade": {"name": "Пепельный клинок", "ability_id": "ember_echo", "ability": "Эхо углей", "description": "Каждый удар после пробуждения дополнительно укрепляет качество клинка."},
	"ember_sabre": {"name": "Сабля солнечных искр", "ability_id": "spark_dance", "ability": "Танец искр", "description": "Качество от каждого удара увеличивается на 15%."},
	"wyrmfang": {"name": "Клык древнего дракона", "ability_id": "dragon_hide", "ability": "Драконья чешуя", "description": "Шанс разрушения клинка снижается на 35%."},
	"glassfang": {"name": "Зеркальная рапира", "ability_id": "glass_precision", "ability": "Зеркальная точность", "description": "Шанс великолепного удара становится выше."},
	"frostbite": {"name": "Ледяное жало", "ability_id": "frost_shell", "ability": "Панцирь вечной мерзлоты", "description": "Износ прочности от ударов снижается на 28%."},
	"bloodiron": {"name": "Кровавый бастард", "ability_id": "blood_price", "ability": "Кровавая цена", "description": "Продажа пробуждённого клинка приносит на 25% больше золота."},
	"ashen_greatsword": {"name": "Эгида Пепельного стража", "ability_id": "ashen_guard", "ability": "Пепельная эгида", "description": "Снижает входящий урон в бою с драконом ещё на 15%."},
	"rift_spear": {"name": "Копьё Последнего разлома", "ability_id": "rift_pierce", "ability": "Пробой разлома", "description": "Наносит на 25% больше урона драконам начиная со второй фазы."},
	"storm_twins": {"name": "Грозовые близнецы", "ability_id": "storm_combo", "ability": "Шквал молний", "description": "Каждый четвёртый раунд боя наносит двойной дополнительный урон."}
}

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

func final_form(weapon_id: String) -> Dictionary:
	return FINAL_FORMS.get(weapon_id, FINAL_FORMS["coal_blade"])

func active_ability_id(state: AshenGameState) -> String:
	if state.weapon_awakened and state.awakened_weapon_id == state.weapon_id:
		return str(final_form(state.weapon_id).ability_id)
	return ""

func try_awaken(state: AshenGameState) -> Dictionary:
	if not state.has_blade or state.weapon_awakened or state.quality < 85.0:
		return {"ok": false}
	state.weapon_awakened = true
	state.awakened_weapon_id = state.weapon_id
	var form := final_form(state.weapon_id)
	return {
		"ok": true,
		"name": str(form.name),
		"ability": str(form.ability),
		"description": str(form.description),
		"message": "ПРОБУЖДЕНИЕ! %s обрёл финальную форму: «%s». Способность «%s»: %s" % [state.weapon_name, str(form.name), str(form.ability), str(form.description)]
	}

func final_form_status(state: AshenGameState) -> String:
	if not state.has_blade:
		return "ФИНАЛЬНАЯ ФОРМА: появится вместе с новой заготовкой"
	if state.weapon_awakened and state.awakened_weapon_id == state.weapon_id:
		var form := final_form(state.weapon_id)
		return "✦ %s • %s\n%s" % [str(form.name), str(form.ability), str(form.description)]
	return "ПРОБУЖДЕНИЕ: %.0f/85 качества" % minf(85.0, state.quality)

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
