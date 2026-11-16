extends RefCounted
class_name AshenEconomySystem

func blade_value(state: AshenGameState) -> int:
	var relics = preload("res://scripts/relic_system.gd").new()
	var weapons = preload("res://scripts/weapon_system.gd").new()
	var weapon: Dictionary = weapons.get_weapon(state.weapon_id)
	var base := float(weapon.base_value) + state.quality * 1.35 + state.durability * 0.24 + state.chapter * 1.5
	var synergy := relics.synergy_bonus(state)
	var temper_bonus := 1.0 + float(state.weapon_temper_levels.get(state.weapon_id, 0)) * 0.08
	var final_form_bonus := 1.25 if state.weapon_awakened and state.awakened_weapon_id == state.weapon_id and weapons.active_ability_id(state) == "blood_price" else 1.0
	return maxi(1, int(base * float(weapon.value_multiplier) * relics.sale_multiplier(state) * (1.0 + synergy) * final_form_bonus * temper_bonus))

func sell_blade(state: AshenGameState) -> Dictionary:
	if not state.has_blade:
		return {"ok": false, "message": "Нечего продавать. Возьми новую заготовку."}
	var relics = preload("res://scripts/relic_system.gd").new()
	var value := blade_value(state) + relics.extra_sale_gold(state)
	state.gold += value
	state.best_sale = maxi(state.best_sale, value)
	state.total_blades += 1
	state.has_blade = false
	return {"ok": true, "value": value, "message": "%s продан за %d золотых." % [state.weapon_name, value]}

func pay_tribute(state: AshenGameState) -> Dictionary:
	if state.contract_complete:
		return {"ok": false, "message": "Контракт завершён. Дальше — путь к дракону."}
	if state.gold < state.tribute_goal:
		return {"ok": false, "message": "Дракону не хватает %d золотых." % (state.tribute_goal - state.gold)}
	state.gold -= state.tribute_goal
	state.day += 1
	state.chapter = int(ceil(float(state.day) / 4.0))
	state.tribute_goal = int(ceil(float(state.tribute_goal) * 1.16 + 5.0))
	if state.day > state.contract_days:
		state.day = state.contract_days
		state.contract_complete = true
		return {"ok": true, "contract_complete": true, "message": "Последняя дань принята. Дракон ждёт тебя в своём логове!"}
	return {"ok": true, "message": "Дань принята. Наступил день %d из %d." % [state.day, state.contract_days]}

func upgrade_cost(state: AshenGameState, upgrade_id: String) -> int:
	var costs := {"bellows": 45, "anvil": 60, "luck": 75}
	if not costs.has(upgrade_id):
		return 0
	return int(costs[upgrade_id]) * (int(state.upgrades.get(upgrade_id, 0)) + 1)

func upgrade_name(upgrade_id: String) -> String:
	var names := {"bellows": "МЕХИ", "anvil": "НАКОВАЛЬНЯ", "luck": "УДАЧА"}
	return str(names.get(upgrade_id, "УЛУЧШЕНИЕ"))

func upgrade_description(upgrade_id: String) -> String:
	var descriptions := {
		"bellows": "Усиливает охлаждение клинка на 3 единицы за уровень.",
		"anvil": "Увеличивает прирост качества на 6% и снижает износ на 3% за уровень.",
		"luck": "Снижает шанс разрушения и неудачных ударов; повышает шанс великолепного удара."
	}
	return str(descriptions.get(upgrade_id, ""))

func buy_upgrade(state: AshenGameState, upgrade_id: String) -> Dictionary:
	var costs := {"bellows": 45, "anvil": 60, "luck": 75}
	if not costs.has(upgrade_id):
		return {"ok": false, "message": "Неизвестное улучшение."}
	var level := int(state.upgrades.get(upgrade_id, 0))
	if level >= 5:
		return {"ok": false, "message": "Это улучшение уже достигло максимального уровня."}
	var cost := upgrade_cost(state, upgrade_id)
	if state.gold < cost:
		return {"ok": false, "message": "Нужно ещё %d золота." % (cost - state.gold)}
	state.gold -= cost
	state.upgrades[upgrade_id] = level + 1
	return {"ok": true, "message": "Улучшение установлено: уровень %d." % (level + 1)}

func dragon_armor_cost(state: AshenGameState) -> int:
	return 120 * (state.dragon_armor_level + 1)

func upgrade_dragon_armor(state: AshenGameState) -> Dictionary:
	if state.dragon_armor_level >= 5:
		return {"ok": false, "message": "Чешуйчатый доспех достиг максимального уровня."}
	var scales := int(state.materials.get("dragon_scales", 0))
	var cost := dragon_armor_cost(state)
	if scales < 1:
		return {"ok": false, "message": "Нужна чешуя Пламенного тирана. Победи его в охоте."}
	if state.gold < cost:
		return {"ok": false, "message": "Для укрепления доспеха нужно ещё %d золота." % (cost - state.gold)}
	state.gold -= cost
	state.materials["dragon_scales"] = scales - 1
	state.dragon_armor_level += 1
	return {"ok": true, "message": "Чешуйчатый доспех усилен до уровня %d. Получаемый урон от драконов снижен на %d%%." % [state.dragon_armor_level, state.dragon_armor_level * 8]}

func void_mastery_cost(state: AshenGameState) -> int:
	return 150 * (state.void_mastery_level + 1)

func upgrade_void_mastery(state: AshenGameState) -> Dictionary:
	if state.void_mastery_level >= 5:
		return {"ok": false, "message": "Знание Пустоты достигло максимального уровня."}
	var cores := int(state.materials.get("void_cores", 0))
	var cost := void_mastery_cost(state)
	if cores < 1:
		return {"ok": false, "message": "Нужно ядро Пустоты. Победи Пожирателя пустоты."}
	if state.gold < cost:
		return {"ok": false, "message": "Для изучения Пустоты нужно ещё %d золота." % (cost - state.gold)}
	state.gold -= cost
	state.materials["void_cores"] = cores - 1
	state.void_mastery_level += 1
	return {"ok": true, "message": "Знание Пустоты достигло уровня %d. Урон по дракону увеличен на %d%%." % [state.void_mastery_level, state.void_mastery_level * 12]}

func temper_cost(state: AshenGameState) -> int:
	var level := int(state.weapon_temper_levels.get(state.weapon_id, 0))
	return 100 * (level + 1)

func temper_weapon(state: AshenGameState) -> Dictionary:
	if not state.has_blade:
		return {"ok": false, "message": "Для закалки нужен клинок в кузнице."}
	var level := int(state.weapon_temper_levels.get(state.weapon_id, 0))
	if level >= 5:
		return {"ok": false, "message": "Этот клинок достиг предела закалки."}
	var cost := temper_cost(state)
	var ash := int(state.materials.get("dragon_ash", 0))
	if ash < 1:
		return {"ok": false, "message": "Нужен пепел дракона. Победи дракона, чтобы получить его."}
	if state.gold < cost:
		return {"ok": false, "message": "Для закалки нужно ещё %d золота." % (cost - state.gold)}
	state.gold -= cost
	state.materials["dragon_ash"] = ash - 1
	state.weapon_temper_levels[state.weapon_id] = level + 1
	return {"ok": true, "message": "%s закалён до уровня %d: урон в бою +10%%, цена продажи +8%% за уровень." % [state.weapon_name, level + 1]}
