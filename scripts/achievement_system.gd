extends RefCounted
class_name AshenAchievementSystem

const ACHIEVEMENTS: Array[Dictionary] = [
	{"id":"first_sale","name":"Первый звон золота","description":"Продай первый клинок","reward":60,"condition":"sale1"},
	{"id":"smith_10","name":"Руки мастера","description":"Продай 10 клинков","reward":150,"condition":"sale10"},
	{"id":"big_sale","name":"Золотое лезвие","description":"Продай клинок дороже 250 золота","reward":120,"condition":"sale250"},
	{"id":"first_dragon","name":"Охотник на драконов","description":"Победи первого дракона","reward":100,"condition":"dragon1"},
	{"id":"dragon_5","name":"Гроза логова","description":"Одержи 5 побед над драконами","reward":300,"condition":"dragon5"},
	{"id":"relic_3","name":"Хранитель реликвий","description":"Собери 3 разные реликвии","reward":140,"condition":"relic3"},
	{"id":"arsenal_6","name":"Арсенал легенд","description":"Собери 6 чертежей оружия","reward":180,"condition":"weapon6"},
	{"id":"chapter_10","name":"За гранью пепла","description":"Достигни 10-й главы","reward":250,"condition":"chapter10"}
]

func is_complete(state: AshenGameState, condition: String) -> bool:
	match condition:
		"sale1": return state.total_blades >= 1
		"sale10": return state.total_blades >= 10
		"sale250": return state.best_sale >= 250
		"dragon1": return state.dragon_victories >= 1
		"dragon5": return state.dragon_victories >= 5
		"relic3": return state.relics.size() >= 3
		"weapon6": return state.owned_weapon_ids.size() >= 6
		"chapter10": return state.chapter >= 10
	return false

func claim_ready(state: AshenGameState) -> Array[String]:
	var messages: Array[String] = []
	for achievement in ACHIEVEMENTS:
		var achievement_id: String = str(achievement.id)
		if state.claimed_achievement_ids.has(achievement_id):
			continue
		if is_complete(state, str(achievement.condition)):
			state.claimed_achievement_ids.append(achievement_id)
			state.gold += int(achievement.reward)
			messages.append("%s (+%d золота)" % [str(achievement.name), int(achievement.reward)])
	return messages

func journal(state: AshenGameState) -> String:
	var lines: PackedStringArray = ["ЗАЛ СЛАВЫ • ДОСТИЖЕНИЯ"]
	for achievement in ACHIEVEMENTS:
		var done: bool = state.claimed_achievement_ids.has(str(achievement.id))
		var complete: bool = is_complete(state, str(achievement.condition))
		var mark: String = "✓" if done else ("◆" if complete else "○")
		lines.append("%s %s — %s%s" % [mark, str(achievement.name), str(achievement.description), " • НАГРАДА ЗАЧИСЛЕНА" if done else (" • ГОТОВО" if complete else "")])
	return "\n".join(lines)
