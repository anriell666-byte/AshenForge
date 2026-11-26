extends Node
## Quest log. State lives in progress.quests {id: {"state": "active"|"done", "count": int}}.
## Quests start when the player reads the matching note (see world_manager.gd).

const WD = preload("res://scripts/world_data.gd")
const ID = preload("res://scripts/items_data.gd")

signal updated

var game
var progress
var world
var timer := 0.0

func setup(owner_game, progress_node, world_node) -> void:
    game = owner_game
    progress = progress_node
    world = world_node

func _process(delta: float) -> void:
    timer -= delta
    if timer <= 0.0:
        timer = 0.6
        _check_collect()

func state_of(id: String) -> String:
    return String(progress.quests.get(id, {}).get("state", ""))

func active_ids() -> Array:
    var out: Array = []
    for id in progress.quests:
        if String(progress.quests[id].get("state", "")) == "active":
            out.append(id)
    return out

func done_count() -> int:
    var n := 0
    for id in progress.quests:
        if String(progress.quests[id].get("state", "")) == "done":
            n += 1
    return n

func start(id: String) -> bool:
    if not WD.QUESTS.has(id) or state_of(id) != "":
        return false
    progress.quests[id] = {"state": "active", "count": 0}
    progress.mark_dirty()
    game.show_message("Новое задание: %s" % String(WD.QUESTS[id]["title"]))
    # Goals that may already be satisfied.
    var goal: Dictionary = WD.QUESTS[id]["goal"]
    match String(goal["type"]):
        "defeat":
            if progress.defeated.has(String(goal["id"])):
                complete(id)
        "visit":
            if world.current == String(goal["district"]):
                complete(id)
        "collect":
            _check_collect()
    updated.emit()
    return true

func progress_text(id: String) -> String:
    var q: Dictionary = WD.QUESTS[id]
    var goal: Dictionary = q["goal"]
    var count := int(progress.quests.get(id, {}).get("count", 0))
    match String(goal["type"]):
        "kill_any", "kill", "collect":
            return "%d / %d" % [mini(count, int(goal["count"])), int(goal["count"])]
    return ""

func tracker_text() -> String:
    var ids := active_ids()
    if ids.is_empty():
        return ""
    var lines: Array[String] = []
    for i in range(mini(2, ids.size())):
        var q: Dictionary = WD.QUESTS[ids[i]]
        var p := progress_text(ids[i])
        lines.append("• %s%s" % [String(q["title"]), ("  " + p) if p != "" else ""])
    if ids.size() > 2:
        lines.append("… и ещё %d" % (ids.size() - 2))
    return "\n".join(lines)

# ---------------------------------------------------------------- events
func on_kill(monster_id: String, district: String) -> void:
    for id in active_ids():
        var goal: Dictionary = WD.QUESTS[id]["goal"]
        match String(goal["type"]):
            "kill_any":
                if String(goal.get("district", "")) == "" or String(goal["district"]) == district:
                    _add_count(id, 1)
            "kill":
                if String(goal["id"]) == monster_id:
                    _add_count(id, 1)
            "defeat":
                if String(goal["id"]) == monster_id:
                    complete(id)

func on_visit(district: String) -> void:
    for id in active_ids():
        var goal: Dictionary = WD.QUESTS[id]["goal"]
        if String(goal["type"]) == "visit" and String(goal["district"]) == district:
            complete(id)

func _add_count(id: String, amount: int) -> void:
    var goal: Dictionary = WD.QUESTS[id]["goal"]
    var entry: Dictionary = progress.quests[id]
    entry["count"] = int(entry.get("count", 0)) + amount
    progress.mark_dirty()
    if int(entry["count"]) >= int(goal["count"]):
        complete(id)
    else:
        game.show_message("%s: %d/%d" % [String(WD.QUESTS[id]["title"]), int(entry["count"]), int(goal["count"])])
        updated.emit()

func _check_collect() -> void:
    for id in active_ids():
        var goal: Dictionary = WD.QUESTS[id]["goal"]
        if String(goal["type"]) != "collect":
            continue
        var res := String(goal["res"])
        var have := int(game.inventory.get(res, 0)) + int(game.chest_inventory.get(res, 0))
        var entry: Dictionary = progress.quests[id]
        if have > int(entry.get("count", 0)):
            entry["count"] = have
            progress.mark_dirty()
            updated.emit()
        if int(entry.get("count", 0)) >= int(goal["count"]):
            complete(id)

# ---------------------------------------------------------------- rewards
func complete(id: String) -> void:
    if state_of(id) != "active":
        return
    var q: Dictionary = WD.QUESTS[id]
    var entry: Dictionary = progress.quests[id]
    entry["state"] = "done"
    var goal: Dictionary = q["goal"]
    if goal.has("count"):
        entry["count"] = int(goal["count"])
    progress.mark_dirty()
    var reward: Dictionary = q["reward"]
    var parts: Array[String] = []
    if reward.has("xp"):
        game._gain_xp(int(reward["xp"]))
        parts.append("%d XP" % int(reward["xp"]))
    var res: Dictionary = reward.get("res", {})
    var offset := 0.0
    for key in res:
        game.spawn_loot(String(key), int(res[key]), game.player.global_position + Vector3(1.2, 0, offset))
        parts.append("%s ×%d" % [String(ID.RES_LABELS.get(key, key)), int(res[key])])
        offset += 0.7
    var items: Dictionary = reward.get("items", {})
    for key in items:
        for n in range(int(items[key])):
            progress.add_item(String(key), false)
        parts.append("%s ×%d" % [String(ID.item(String(key)).get("name", key)), int(items[key])])
    game.show_message("Задание выполнено: %s  (%s)" % [String(q["title"]), ", ".join(parts)])
    if reward.has("unlock"):
        world.unlock_district(String(reward["unlock"]))
    updated.emit()
