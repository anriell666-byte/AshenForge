extends RefCounted
class_name AshenEconomySystem

func blade_value(state: AshenGameState) -> int:
	return maxi(1, int(9.0 + state.quality * 1.35 + state.durability * 0.24 + state.chapter * 1.5))

func sell_blade(state: AshenGameState) -> Dictionary:
	if not state.has_blade:
		return {"ok": false, "message": "Нечего продавать. Начни новую ковку."}
	var value := blade_value(state)
	state.gold += value
	state.best_sale = maxi(state.best_sale, value)
	state.total_blades += 1
	state.has_blade = false
	return {"ok": true, "value": value, "message": "Клинок продан за %d золотых." % value}

func pay_tribute(state: AshenGameState) -> Dictionary:
	if state.gold < state.tribute_goal:
		return {"ok": false, "message": "Дракону не хватает %d золотых." % (state.tribute_goal - state.gold)}
	state.gold -= state.tribute_goal
	state.chapter += 1
	state.tribute_goal = int(ceil(float(state.tribute_goal) * 1.32 + 6.0))
	return {"ok": true, "message": "Дань принята. Впереди новая глава."}

func buy_upgrade(state: AshenGameState, upgrade_id: String) -> Dictionary:
	var costs := {"bellows": 45, "anvil": 60, "luck": 75}
	if not costs.has(upgrade_id):
		return {"ok": false, "message": "Неизвестное улучшение."}
	var level := int(state.upgrades.get(upgrade_id, 0))
	var cost := int(costs[upgrade_id]) * (level + 1)
	if state.gold < cost:
		return {"ok": false, "message": "Нужно ещё %d золота." % (cost - state.gold)}
	state.gold -= cost
	state.upgrades[upgrade_id] = level + 1
	return {"ok": true, "message": "Улучшение установлено: уровень %d." % (level + 1)}
