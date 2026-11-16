extends RefCounted
class_name AshenForgeSystem

func strike(state: AshenGameState) -> Dictionary:
	if not state.has_blade:
		return {"ok": false, "message": "Сначала начни новую ковку."}
	var luck_bonus := float(state.upgrades.get("luck", 0)) * 0.025
	var critical := randf() < 0.14 + luck_bonus
	var power := randf_range(7.0, 15.0)
	state.heat = clampf(state.heat + randf_range(6.0, 12.0), 0.0, 100.0)
	state.quality = minf(100.0, state.quality + power * (1.75 if critical else 1.0))
	var wear := power * (0.42 if critical else randf_range(0.5, 0.82))
	state.durability -= wear
	if state.heat > 92.0:
		state.durability -= 10.0
	state.durability = maxf(0.0, state.durability)
	if state.durability <= 0.0:
		state.has_blade = false
		return {"ok": true, "broken": true, "critical": critical, "message": "Клинок рассыпался в искрах!"}
	return {"ok": true, "broken": false, "critical": critical, "message": "Критический удар! Металл поёт." if critical else "Удар точен. Качество растёт, прочность падает."}

func cool(state: AshenGameState) -> String:
	if not state.has_blade:
		return "В горне только остывающие угли."
	state.heat = maxf(0.0, state.heat - 22.0 - float(state.upgrades.get("bellows", 0)) * 3.0)
	return "Металл остывает. Температура снижена."

func start_new_blade(state: AshenGameState) -> void:
	state.has_blade = true
	state.weapon_name = "Угольный клинок"
	state.heat = 25.0
	state.quality = 5.0
	state.durability = 100.0
