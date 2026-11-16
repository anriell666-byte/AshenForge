extends RefCounted
class_name AshenEconomySystem

func blade_value(state: AshenGameState) -> int:
	var relics = preload("res://scripts/relic_system.gd").new()
	var weapons = preload("res://scripts/weapon_system.gd").new()
	var weapon: Dictionary = weapons.get_weapon(state.weapon_id)
	var base := float(weapon.base_value) + state.quality * 1.35 + state.durability * 0.24 + state.chapter * 1.5
	var synergy := relics.synergy_bonus(state)
	var final_form_bonus := 1.25 if state.weapon_awakened and state.awakened_weapon_id == state.weapon_id and weapons.active_ability_id(state) == "blood_price" else 1.0
	return maxi(1, int(base * float(weapon.value_multiplier) * relics.sale_multiplier(state) * (1.0 + synergy) * final_form_bonus))

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

func buy_upgrade(state: AshenGameState, upgrade_id: String) -> Dictionary:
	var costs := {"bellows": 45, "anvil": 60, "luck": 75}
	if not costs.has(upgrade_id):
		return {"ok": false, "message": "Неизвестное улучшение."}
	var level := int(state.upgrades.get(upgrade_id, 0))
	if level >= 5:
		return {"ok": false, "message": "Это улучшение уже достигло максимального уровня."}
	var cost := int(costs[upgrade_id]) * (level + 1)
	if state.gold < cost:
		return {"ok": false, "message": "Нужно ещё %d золота." % (cost - state.gold)}
	state.gold -= cost
	state.upgrades[upgrade_id] = level + 1
	return {"ok": true, "message": "Улучшение установлено: уровень %d." % (level + 1)}
