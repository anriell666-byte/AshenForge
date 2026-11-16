extends RefCounted
class_name AshenMerchantSystem

const WeaponSystem = preload("res://scripts/weapon_system.gd")

var weapons = WeaponSystem.new()

func stock(state: AshenGameState) -> Array:
	var offers: Array = []
	for weapon in weapons.WEAPONS:
		if not bool(weapon.get("merchant_only", false)) or bool(weapon.get("craft_only", false)):
			continue
		if state.chapter < int(weapon.unlock_chapter):
			continue
		offers.append(weapon)
	return offers

func rare_owned_count(state: AshenGameState) -> int:
	var total := 0
	for weapon in WeaponSystem.WEAPONS:
		if bool(weapon.get("merchant_only", false)) and state.owned_weapon_ids.has(str(weapon.id)):
			total += 1
	return total

func buy_weapon(state: AshenGameState, weapon_id: String) -> Dictionary:
	var weapon: Dictionary = weapons.get_weapon(weapon_id)
	if not bool(weapon.get("merchant_only", false)) or bool(weapon.get("craft_only", false)):
		return {"ok": false, "message": "Этот чертёж нельзя купить у торговца."}
	if state.owned_weapon_ids.has(weapon_id):
		return {"ok": false, "message": "Этот чертёж уже есть в твоей коллекции."}
	if state.chapter < int(weapon.unlock_chapter):
		return {"ok": false, "message": "Торговец пока не доверяет тебе настолько редкий товар."}
	var price := int(weapon.get("price", 0))
	if state.gold < price:
		return {"ok": false, "message": "Не хватает %d золотых." % (price - state.gold)}
	state.gold -= price
	state.owned_weapon_ids.append(weapon_id)
	state.selected_weapon_id = weapon_id
	return {
		"ok": true,
		"weapon_id": weapon_id,
		"message": "Куплен чертёж «%s»! Он выбран для следующей заготовки." % str(weapon.name)
	}

func offer_text(weapon: Dictionary) -> String:
	return "%s • %d золота\n%s\nКачество ×%.2f | Нагрев ×%.2f | Риск ×%.2f" % [
		str(weapon.name), int(weapon.price), str(weapon.description),
		float(weapon.quality_scale), float(weapon.heat_scale), float(weapon.break_risk)
	]

func craft_weapon(state: AshenGameState, weapon_id: String) -> Dictionary:
	var weapon: Dictionary = weapons.get_weapon(weapon_id)
	if not bool(weapon.get("craft_only", false)):
		return {"ok": false, "message": "Для этого клинка нет кузнечного рецепта."}
	if state.owned_weapon_ids.has(weapon_id):
		return {"ok": false, "message": "Этот рецепт уже освоен."}
	if state.chapter < int(weapon.unlock_chapter):
		return {"ok": false, "message": "Твоя кузница пока не готова к этому рецепту."}
	var gold_cost := int(weapon.get("recipe_gold", 0))
	var ash_cost := int(weapon.get("recipe_ash", 0))
	var scale_cost := int(weapon.get("recipe_scales", 0))
	var core_cost := int(weapon.get("recipe_cores", 0))
	if state.gold < gold_cost:
		return {"ok": false, "message": "Не хватает %d золота для рецепта." % (gold_cost - state.gold)}
	if int(state.materials.get("dragon_ash", 0)) < ash_cost:
		return {"ok": false, "message": "Недостаточно пепла дракона для рецепта."}
	if int(state.materials.get("dragon_scales", 0)) < scale_cost:
		return {"ok": false, "message": "Недостаточно чешуи дракона для рецепта."}
	if int(state.materials.get("void_cores", 0)) < core_cost:
		return {"ok": false, "message": "Недостаточно ядер Пустоты для рецепта."}
	state.gold -= gold_cost
	state.materials["dragon_ash"] = int(state.materials.get("dragon_ash", 0)) - ash_cost
	state.materials["dragon_scales"] = int(state.materials.get("dragon_scales", 0)) - scale_cost
	state.materials["void_cores"] = int(state.materials.get("void_cores", 0)) - core_cost
	state.owned_weapon_ids.append(weapon_id)
	state.selected_weapon_id = weapon_id
	return {"ok": true, "weapon_id": weapon_id, "message": "Освоен рецепт «%s»! Клинок выбран для следующей заготовки." % str(weapon.name)}
