extends RefCounted
class_name AshenRelicSystem

const RELICS := {
	"ember_heart": {
		"name": "Сердце угля",
		"description": "Каждый удар сильнее улучшает качество.",
		"weight": 24
	},
	"cracked_mirror": {
		"name": "Треснувшее зеркало",
		"description": "Снижает шанс разрушения клинка.",
		"weight": 20
	},
	"dragon_tooth": {
		"name": "Зуб дракона",
		"description": "Повышает стоимость продаваемых мечей.",
		"weight": 18
	},
	"echo_rune": {
		"name": "Руна эха",
		"description": "Увеличивает длительность Frenzy.",
		"weight": 16
	},
	"greedy_eye": {
		"name": "Алчный глаз",
		"description": "Даёт дополнительное золото при продаже.",
		"weight": 22
	}
}

func sacrifice_blade(state: AshenGameState) -> Dictionary:
	if not state.has_blade:
		return {"ok": false, "message": "Машине нужен целый клинок. Сначала выкуй новый."}
	var relic_id := _draw_relic()
	state.has_blade = false
	state.total_blades += 1
	state.relics[relic_id] = int(state.relics.get(relic_id, 0)) + 1
	var relic: Dictionary = RELICS[relic_id]
	var count := int(state.relics[relic_id])
	var synergy := _distinct_relic_count(state) >= 2
	var message := "Клинок поглощён. Получена реликвия: %s." % relic.name
	if count > 1:
		message += " Её сила усилилась (x%d)." % count
	if synergy:
		message += " СИНЕРГИЯ: две разные реликвии усиливают кузницу."
	return {"ok": true, "id": relic_id, "name": relic.name, "count": count, "message": message}

func _draw_relic() -> String:
	var total_weight := 0
	for relic_id in RELICS:
		total_weight += int(RELICS[relic_id].weight)
	var ticket := randi_range(1, total_weight)
	for relic_id in RELICS:
		ticket -= int(RELICS[relic_id].weight)
		if ticket <= 0:
			return relic_id
	return "ember_heart"

func _distinct_relic_count(state: AshenGameState) -> int:
	var total := 0
	for relic_id in state.relics:
		if int(state.relics[relic_id]) > 0:
			total += 1
	return total

func count(state: AshenGameState, relic_id: String) -> int:
	return int(state.relics.get(relic_id, 0))

func quality_bonus(state: AshenGameState) -> float:
	return count(state, "ember_heart") * 1.5

func destruction_reduction(state: AshenGameState) -> float:
	return minf(0.08, count(state, "cracked_mirror") * 0.02)

func sale_multiplier(state: AshenGameState) -> float:
	return 1.0 + count(state, "dragon_tooth") * 0.12

func frenzy_bonus_hits(state: AshenGameState) -> int:
	return count(state, "echo_rune")

func extra_sale_gold(state: AshenGameState) -> int:
	return count(state, "greedy_eye") * 5

func synergy_bonus(state: AshenGameState) -> float:
	return 0.05 if _distinct_relic_count(state) >= 2 else 0.0

func summary(state: AshenGameState) -> String:
	var lines: Array[String] = []
	for relic_id in RELICS:
		var amount := count(state, relic_id)
		if amount > 0:
			lines.append("%s ×%d" % [RELICS[relic_id].name, amount])
	if lines.is_empty():
		return "Реликвии пока не найдены"
	if _distinct_relic_count(state) >= 2:
		lines.append("Синергия активна: +5% к цене мечей")
	return "РЕЛИКВИИ\n" + "\n".join(lines)
