extends RefCounted
class_name AshenDragonCombat

const WeaponSystem = preload("res://scripts/weapon_system.gd")

func begin(state: AshenGameState) -> Dictionary:
	if not state.contract_complete:
		return {"ok": false, "message": "Сначала выполни контракт дани. Дракон ещё не открыл врата логова."}
	if not state.has_blade:
		return {"ok": false, "message": "Без клинка в логово не войти. Возьми новую заготовку."}
	state.battle_active = true
	state.dragon_hp = 420.0 + max(0, state.chapter - 6) * 45.0
	state.dragon_max_hp = state.dragon_hp
	state.player_hp = 120.0
	state.dragon_round = 1
	state.dragon_intent = _next_intent()
	return {"ok": true, "message": "Врата захлопнулись. Дракон поднимает голову..."}

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
		if ability == "spark_dance":
			damage *= 1.18
		elif ability == "ember_echo":
			damage += 12.0
		elif ability == "blood_price":
			damage *= 1.12
		if ability == "glass_precision" and randf() < 0.30:
			damage *= 1.9
			crit = true
		if state.weapon_awakened and state.awakened_weapon_id == state.weapon_id:
			damage += 8.0
		state.dragon_hp = maxf(0.0, state.dragon_hp - damage)
	elif action != "dodge" and action != "guard":
		return {"ok": false, "message": "Неизвестное действие."}

	if state.dragon_hp <= 0.0:
		state.battle_active = false
		state.dragon_defeated = true
		state.gold += 120 + state.chapter * 12
		state.chapter += 1
		return {"ok": true, "won": true, "damage": damage, "message": "ДРАКОН ПОВЕРЖЕН! Ты забираешь сокровища логова. +%d золота. Дверь в мастерской теперь ведёт в Бесконечный режим." % (120 + (state.chapter - 1) * 12)}

	var incoming := 0.0
	var avoided := false
	if intent == "claw":
		incoming = 25.0 + state.dragon_round * 1.4
		avoided = action == "dodge"
	elif intent == "flame":
		incoming = 32.0 + state.dragon_round * 1.7
		avoided = action == "dodge"
		if avoided:
			incoming *= 0.45
	elif intent == "tail":
		incoming = 21.0 + state.dragon_round * 1.2
		avoided = action == "dodge"
	if action == "guard":
		incoming *= 0.34
	if ability == "dragon_hide":
		incoming *= 0.72
	if ability == "frost_shell":
		incoming *= 0.82
	if avoided:
		incoming = 0.0
	state.player_hp = maxf(0.0, state.player_hp - incoming)
	if state.player_hp <= 0.0:
		state.battle_active = false
		return {"ok": true, "lost": true, "damage": damage, "incoming": incoming, "message": "Ты падаешь на колено. Дракон оставляет тебя в живых — пока. Вернись в кузницу, укрепи клинок и попробуй снова."}

	state.dragon_round += 1
	state.dragon_intent = _next_intent()
	var action_text := "Ты уклоняешься от удара!" if action == "dodge" and avoided else ("Ты принимаешь удар на защиту." if action == "guard" else ("Критический удар! " if crit else "") + "Ты наносишь дракону %.0f урона." % damage)
	var defense_text := " Атака дракона не задела тебя." if avoided else " Дракон наносит %.0f урона." % incoming
	return {"ok": true, "damage": damage, "incoming": incoming, "message": action_text + defense_text}

func _next_intent() -> String:
	var roll := randi_range(0, 2)
	return ["claw", "flame", "tail"][roll]

func intent_text(state: AshenGameState) -> String:
	match state.dragon_intent:
		"claw": return "КОГТИ ДРАКОНА • тяжёлый выпад"
		"flame": return "ОГНЕННОЕ ДЫХАНИЕ • широкая атака"
		"tail": return "УДАР ХВОСТОМ • круговая атака"
	return "Дракон готовится атаковать"
