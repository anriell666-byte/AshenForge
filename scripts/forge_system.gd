extends RefCounted
class_name AshenForgeSystem

const STRIKES_FOR_FRENZY := 10
const FRENZY_SAFE_HITS := 3

func strike(state: AshenGameState) -> Dictionary:
	if not state.has_blade:
		return {"ok": false, "message": "Сначала возьми новую заготовку."}

	var frenzy_this_hit := state.frenzy_hits > 0
	if state.frenzy_ready and not frenzy_this_hit:
		state.frenzy_ready = false
		state.frenzy_hits = FRENZY_SAFE_HITS
		frenzy_this_hit = true

	var luck_bonus := float(state.upgrades.get("luck", 0)) * 0.025
	var roll := randf()
	var outcome := "good"
	if frenzy_this_hit:
		outcome = "frenzy"
	elif roll < maxf(0.04, 0.10 - luck_bonus):
		outcome = "destruction"
	elif roll < 0.28 - luck_bonus:
		outcome = "bad"
	elif roll > 0.88 - luck_bonus:
		outcome = "great"

	state.strikes_on_blade += 1
	state.heat = minf(100.0, state.heat + randf_range(5.0, 11.0))

	var power := randf_range(6.0, 11.0)
	var wear := randf_range(5.0, 9.0)
	var message := ""

	match outcome:
		"destruction":
			state.has_blade = false
			state.durability = 0.0
			message = "РАЗРУШЕНИЕ! Клинок раскололся на осколки."
		"bad":
			state.quality = maxf(0.0, state.quality - power * 0.55)
			state.durability = maxf(1.0, state.durability - wear * 1.4)
			message = "Неудачный удар. Качество клинка снизилось."
		"great":
			state.quality = minf(100.0, state.quality + power * 2.0)
			state.durability = maxf(1.0, state.durability - wear * 0.65)
			message = "ВЕЛИКОЛЕПНО! Металл принял идеальную форму."
		"frenzy":
			state.quality = minf(100.0, state.quality + power * 1.65)
			state.durability = maxf(1.0, state.durability - wear * 0.35)
			state.frenzy_hits = maxi(0, state.frenzy_hits - 1)
			message = "FRENZY! Молот не знает промаха — клинок крепнет."
		_:
			state.quality = minf(100.0, state.quality + power)
			state.durability = maxf(1.0, state.durability - wear)
			message = "Удачный удар. Качество растёт."

	if state.has_blade and state.strikes_on_blade >= STRIKES_FOR_FRENZY and state.frenzy_hits == 0:
		state.frenzy_ready = true
		message += " Шквал заряжен! Следующий удар активирует FRENZY."

	state.last_forge_result = outcome
	return {
		"ok": true,
		"outcome": outcome,
		"frenzy": frenzy_this_hit,
		"broken": not state.has_blade,
		"message": message
	}

func cool(state: AshenGameState) -> String:
	if not state.has_blade:
		return "На наковальне пока нет клинка."
	state.heat = maxf(0.0, state.heat - 22.0 - float(state.upgrades.get("bellows", 0)) * 3.0)
	return "Металл остывает. Можно продолжать ковку."

func start_new_blade(state: AshenGameState) -> void:
	state.has_blade = true
	state.weapon_name = "Угольный клинок"
	state.heat = 25.0
	state.quality = 5.0
	state.durability = 100.0
	state.strikes_on_blade = 0
	state.frenzy_ready = false
	state.frenzy_hits = 0
	state.last_forge_result = ""
