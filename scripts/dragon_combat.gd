extends RefCounted
class_name AshenDragonCombat

const WeaponSystem = preload("res://scripts/weapon_system.gd")
const FORM_NAMES := ["ПЕПЕЛЬНЫЙ ДРАКОН", "ПЛАМЕННЫЙ ТИРАН", "ПОЖИРАТЕЛЬ ПУСТОТЫ"]

func form_name(state: AshenGameState) -> String:
	return FORM_NAMES[clampi(state.dragon_form, 0, FORM_NAMES.size() - 1)]

func begin(state: AshenGameState) -> Dictionary:
	if not state.contract_complete:
		return {"ok": false, "message": "Сначала выполни контракт дани. Дракон ещё не открыл врата логова."}
	if not state.has_blade:
		return {"ok": false, "message": "Без клинка в логово не войти. Возьми новую заготовку."}
	state.dragon_form = state.dragon_victories % FORM_NAMES.size()
	state.battle_active = true
	state.dragon_hp = 420.0 + max(0, state.chapter - 6) * 45.0 + state.dragon_victories * 35.0
	state.dragon_max_hp = state.dragon_hp
	state.player_hp = 120.0
	state.dragon_round = 1
	state.dragon_phase = 1
	state.dragon_burn_turns = 0
	state.dragon_intent = _next_intent(state)
	return {"ok": true, "message": "Врата захлопнулись. Перед тобой: %s. Охота №%d начинается!" % [form_name(state), state.dragon_victories + 1]}

func act(state: AshenGameState, action: String) -> Dictionary:
	if not state.battle_active:
		return {"ok": false, "message": "Бой сейчас не идёт."}
	var weapons = WeaponSystem.new()
	var ability := weapons.active_ability_id(state)
	var intent := state.dragon_intent
	var damage := 0.0
	var crit := false
	if action == "attack":
		var weapon: Dictionary = weapons.get_weapon(state.weapon_id)
		damage = 16.0 + float(weapon.base_value) * 0.32 + state.quality * 0.42
		damage *= float(weapon.value_multiplier) * (1.0 + float(state.relics.get("dragon_tooth", 0)) * 0.08)
		damage *= 1.0 + float(state.weapon_temper_levels.get(state.weapon_id, 0)) * 0.10
		damage *= 1.0 + float(state.void_mastery_level) * 0.12
		if ability == "spark_dance":
			damage *= 1.18
		elif ability == "ember_echo":
			damage += 12.0
		elif ability == "blood_price":
			damage *= 1.12
		elif ability == "rift_pierce" and state.dragon_phase >= 2:
			damage *= 1.25
		elif ability == "storm_combo" and state.dragon_round % 4 == 0:
			damage *= 2.0
			crit = true
		if ability == "glass_precision" and randf() < 0.30:
			damage *= 1.9
			crit = true
		if state.weapon_awakened and state.awakened_weapon_id == state.weapon_id:
			damage += 8.0
		state.dragon_hp = maxf(0.0, state.dragon_hp - damage)
	elif action != "dodge" and action != "guard":
		return {"ok": false, "message": "Неизвестное действие."}

	if state.dragon_hp <= 0.0:
		var reward := 120 + state.chapter * 12 + state.dragon_victories * 18
		state.battle_active = false
		state.dragon_defeated = true
		state.dragon_victories += 1
		state.gold += reward
		state.materials["dragon_ash"] = int(state.materials.get("dragon_ash", 0)) + 1
		var material_text := "Пепел дракона ×1"
		if state.dragon_form == 1:
			state.materials["dragon_scales"] = int(state.materials.get("dragon_scales", 0)) + 1
			material_text += ", чешуя дракона ×1"
		elif state.dragon_form == 2:
			state.materials["void_cores"] = int(state.materials.get("void_cores", 0)) + 1
			material_text += ", ядро пустоты ×1"
		state.chapter += 1
		return {"ok": true, "won": true, "damage": damage, "message": "%s ПОВЕРЖЕН! +%d золота. Добыча: %s. Побед в охоте: %d." % [form_name(state), reward, material_text, state.dragon_victories]}

	var phase_message := ""
	var hp_ratio := state.dragon_hp / maxf(1.0, state.dragon_max_hp)
	var next_phase := 1
	if hp_ratio <= 0.33:
		next_phase = 3
	elif hp_ratio <= 0.66:
		next_phase = 2
	if next_phase > state.dragon_phase:
		state.dragon_phase = next_phase
		phase_message = " ДРАКОН ПЕРЕХОДИТ В ФАЗУ %d! Его атаки становятся опаснее." % state.dragon_phase

	var incoming := 0.0
	var avoided := false
	match intent:
		"claw":
			incoming = 25.0 + state.dragon_round * 1.4
			avoided = action == "dodge"
		"flame":
			incoming = 32.0 + state.dragon_round * 1.7
			if action == "dodge": incoming *= 0.45
		"tail":
			incoming = 21.0 + state.dragon_round * 1.2
			avoided = action == "dodge"
		"inferno":
			incoming = 40.0 + state.dragon_round * 2.0
			if action == "dodge": incoming *= 0.62
			if action != "dodge": state.dragon_burn_turns = maxi(state.dragon_burn_turns, 2)
		"soul_drain":
			incoming = 28.0 + state.dragon_round * 1.5
			state.dragon_hp = minf(state.dragon_max_hp, state.dragon_hp + 10.0)
		"void_claw":
			incoming = 31.0 + state.dragon_round * 1.6
			avoided = action == "dodge"
		"ash_burst":
			incoming = 27.0 + state.dragon_round * 1.5
			avoided = action == "dodge"
		"cinder_bind":
			incoming = 30.0 + state.dragon_round * 1.6
			if action != "dodge": state.dragon_burn_turns = maxi(state.dragon_burn_turns, 2)
		"molten_rain":
			incoming = 35.0 + state.dragon_round * 1.7
			if action == "dodge": incoming *= 0.45
			if action != "dodge": state.dragon_burn_turns = maxi(state.dragon_burn_turns, 2)
		"eruption":
			incoming = 49.0 + state.dragon_round * 2.1
			if action == "dodge": incoming *= 0.55
			if action != "dodge": state.dragon_burn_turns = maxi(state.dragon_burn_turns, 2)
		"rift_pulse":
			incoming = 33.0 + state.dragon_round * 1.7
			avoided = action == "dodge"
		"void_collapse":
			incoming = 43.0 + state.dragon_round * 2.1
			if action == "dodge": incoming *= 0.65

	if action == "guard":
		incoming *= 0.38
	incoming *= 1.0 - float(state.dragon_armor_level) * 0.08
	if ability == "dragon_hide": incoming *= 0.72
	if ability == "frost_shell": incoming *= 0.82
	if ability == "ashen_guard": incoming *= 0.85
	if avoided: incoming = 0.0
	state.player_hp = maxf(0.0, state.player_hp - incoming)
	var burn_text := ""
	if state.dragon_burn_turns > 0 and state.player_hp > 0.0:
		state.player_hp = maxf(0.0, state.player_hp - 6.0)
		state.dragon_burn_turns -= 1
		burn_text = " Пепельный ожог наносит ещё 6 урона."
	if state.player_hp <= 0.0:
		state.battle_active = false
		return {"ok": true, "lost": true, "damage": damage, "incoming": incoming, "message": "Ты падаешь на колено. Дракон оставляет тебя в живых — пока. Вернись в кузницу, укрепи клинок и попробуй снова."}

	state.dragon_round += 1
	state.dragon_intent = _next_intent(state)
	var action_text := "Ты уклоняешься от удара!" if action == "dodge" and avoided else ("Ты принимаешь удар на защиту." if action == "guard" else ("Критический удар! " if crit else "") + "Ты наносишь дракону %.0f урона." % damage)
	var defense_text := " Атака дракона не задела тебя." if avoided else " Дракон наносит %.0f урона." % incoming
	if intent == "soul_drain": defense_text += " Дракон восстановил 10 здоровья."
	return {"ok": true, "damage": damage, "incoming": incoming, "message": action_text + defense_text + burn_text + phase_message}

func _next_intent(state: AshenGameState) -> String:
	var choices: Array[String]
	match state.dragon_form:
		1:
			if state.dragon_phase >= 3: choices = ["eruption", "molten_rain", "inferno"]
			elif state.dragon_phase == 2: choices = ["molten_rain", "tail", "inferno"]
			else: choices = ["claw", "tail", "inferno"]
		2:
			if state.dragon_phase >= 3: choices = ["void_collapse", "soul_drain", "rift_pulse"]
			elif state.dragon_phase == 2: choices = ["rift_pulse", "void_claw", "soul_drain"]
			else: choices = ["void_claw", "tail", "soul_drain"]
		_:
			if state.dragon_phase >= 3: choices = ["cinder_bind", "ash_burst", "flame"]
			elif state.dragon_phase == 2: choices = ["ash_burst", "claw", "flame"]
			else: choices = ["claw", "flame", "tail"]
	return choices[randi_range(0, choices.size() - 1)]

func intent_text(state: AshenGameState) -> String:
	match state.dragon_intent:
		"claw": return "КОГТИ ДРАКОНА • тяжёлый выпад"
		"flame": return "ОГНЕННОЕ ДЫХАНИЕ • широкая атака"
		"tail": return "УДАР ХВОСТОМ • круговая атака"
		"inferno": return "ПЕКЛО • сокрушительный огненный шторм"
		"soul_drain": return "ПОГЛОЩЕНИЕ ДУШ • дракон крадёт жизненную силу"
		"void_claw": return "КОГТИ ПУСТОТЫ • пронзающий выпад"
		"ash_burst": return "ПЕПЕЛЬНЫЙ ВЗРЫВ • уклоняйся от волны пепла"
		"cinder_bind": return "УГОЛЬНЫЕ ОКОВЫ • уклонись, иначе получишь ожог"
		"molten_rain": return "ДОЖДЬ РАСПЛАВА • уклонение спасает от ожога"
		"eruption": return "ИЗВЕРЖЕНИЕ • сокрушительный удар Пламенного тирана"
		"rift_pulse": return "ИМПУЛЬС РАЗЛОМА • уклоняйся от волны Пустоты"
		"void_collapse": return "СХЛОПЫВАНИЕ ПУСТОТЫ • мощная атака последней фазы"
	return "Дракон готовится атаковать"
