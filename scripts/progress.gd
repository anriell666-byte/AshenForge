extends Node
## Persistent progression that lives outside the main save: owned weapons/tools with
## durability and level, blueprints, defeated bosses, quest state and unlocked districts.
## Saved to user://progress.json shortly after every change.

const ID = preload("res://scripts/items_data.gd")
const SAVE_PATH := "user://progress.json"

signal changed

var game
var owned := {}          # id -> {"dur": float, "level": int}
var stock := {}          # consumable id -> count
var equipped_weapon: String = ""
var equipped_tool: String = ""
var equipment := {}      # gear slot -> item id
var blueprints: Array = []
var defeated: Array = []
var quests := {}         # quest id -> {"state": "active"|"done", "count": int}
var notes_read: Array = []
var unlocked: Array = ["greywood", "woods", "hospital"]
var dirty := false
var save_timer := 0.0

func setup(owner_game) -> void:
    game = owner_game
    if FileAccess.file_exists(SAVE_PATH):
        _load()
    else:
        _migrate_old_save()
    _sync_player()

func _process(delta: float) -> void:
    if dirty:
        save_timer -= delta
        if save_timer <= 0.0:
            save_state()

func mark_dirty() -> void:
    if not dirty:
        save_timer = 1.5
    dirty = true
    _sync_player()
    changed.emit()

func _sync_player() -> void:
    if game and is_instance_valid(game.player):
        game.player.equipped_weapon = equipped_weapon
        game.player.equipped_tool = equipped_tool
    var key := visual_signature()
    if key != _last_visual:
        _last_visual = key
        if game and game.has_method("refresh_player_model"):
            game.call_deferred("refresh_player_model")

var _last_visual := ""

func visual_gear() -> Dictionary:
    var out := equipment.duplicate()
    out["weapon"] = equipped_weapon
    out["tool"] = equipped_tool
    return out

func visual_signature() -> String:
    return JSON.stringify(visual_gear())

func armor_total() -> float:
    var total := 0.0
    for slot in equipment:
        total += float(ID.item(String(equipment[slot])).get("armor", 0.0))
    return clampf(total, 0.0, 0.6)

func carry_bonus() -> float:
    var total := 0.0
    for slot in equipment:
        total += float(ID.item(String(equipment[slot])).get("carry", 0.0))
    return total

func equipped_in(slot: String) -> String:
    if slot == "weapon":
        return equipped_weapon
    if slot == "tool":
        return equipped_tool
    return String(equipment.get(slot, ""))

func _migrate_old_save() -> void:
    # Saves from before the workbench stored crafted flags in the main save.
    var old: Dictionary = game.saved_expansion_state if game else {}
    for key in old:
        if bool(old[key]) and ID.ITEMS.has(key):
            add_item(key, false)
    if game and game.player.equipped_weapon != "" and owned.has(game.player.equipped_weapon):
        equipped_weapon = game.player.equipped_weapon
    if game and game.player.equipped_tool != "" and owned.has(game.player.equipped_tool):
        equipped_tool = game.player.equipped_tool

# ---------------------------------------------------------------- items
func has_item(id: String) -> bool:
    return owned.has(id)

func is_broken(id: String) -> bool:
    return owned.has(id) and float(owned[id]["dur"]) <= 0.0

func can_craft(id: String) -> bool:
    if not ID.needs_blueprint(id):
        return true
    return blueprints.has(id)

func add_item(id: String, auto_equip: bool = true) -> void:
    var data: Dictionary = ID.item(id)
    if data.is_empty():
        return
    if String(data["slot"]) == "consumable":
        stock[id] = int(stock.get(id, 0)) + 1
        mark_dirty()
        return
    owned[id] = {"dur": float(data.get("durability", 1.0)), "level": 1}
    if auto_equip:
        var s := String(data["slot"])
        if s == "weapon":
            equipped_weapon = id
        elif s == "tool":
            equipped_tool = id
        elif ID.GEAR_SLOTS.has(s) and String(equipment.get(s, "")) == "":
            equipment[s] = id
    mark_dirty()

func equip(id: String) -> void:
    if not owned.has(id) or is_broken(id):
        return
    var slot := String(ID.item(id)["slot"])
    if slot == "weapon":
        equipped_weapon = id
    elif slot == "tool":
        equipped_tool = id
    elif ID.GEAR_SLOTS.has(slot):
        equipment[slot] = id
    mark_dirty()

func unequip(slot: String) -> void:
    if slot == "weapon":
        equipped_weapon = ""
    elif slot == "tool":
        equipped_tool = ""
    else:
        equipment.erase(slot)
    mark_dirty()

func cycle(slot: String) -> String:
    var ids: Array[String] = []
    for id in owned:
        if String(ID.item(id)["slot"]) == slot and not is_broken(id):
            ids.append(id)
    ids.sort()
    if ids.is_empty():
        return ""
    var current := equipped_weapon if slot == "weapon" else equipped_tool
    var next: String = ids[0]
    var index := ids.find(current)
    if index >= 0:
        next = ids[(index + 1) % ids.size()]
    equip(next)
    return next

func repair_cost(id: String) -> Dictionary:
    var out := {}
    var cost: Dictionary = ID.item(id).get("cost", {})
    for key in cost:
        out[key] = maxi(1, int(ceil(float(cost[key]) * 0.5)))
    return out

func max_durability(id: String) -> float:
    var level := int(owned.get(id, {"level": 1})["level"])
    return float(ID.item(id).get("durability", 1.0)) * (1.0 + 0.3 * float(level - 1))

func repair(id: String) -> void:
    if owned.has(id):
        owned[id]["dur"] = max_durability(id)
        mark_dirty()

func upgrade(id: String) -> void:
    if owned.has(id):
        owned[id]["level"] = int(owned[id]["level"]) + 1
        owned[id]["dur"] = max_durability(id)
        mark_dirty()

## Stats of whatever the player attacks with right now (fists if nothing is equipped).
func attack_stats() -> Dictionary:
    var id := equipped_weapon
    if id == "" or not owned.has(id) or is_broken(id):
        id = equipped_tool if (equipped_tool != "" and owned.has(equipped_tool) and not is_broken(equipped_tool)) else ""
    if id == "":
        return {"id": "", "name": "Кулаки", "damage": 8.0, "reach": 2.6, "cooldown": 0.5, "kind": "melee"}
    var stats: Dictionary = ID.item(id).duplicate()
    var level := int(owned[id]["level"])
    stats["id"] = id
    stats["damage"] = float(stats["damage"]) * ID.level_multiplier(level)
    return stats

func wear(id: String, amount: float = 1.0) -> void:
    if id == "" or not owned.has(id):
        return
    var wear_amount := amount
    if id == "chainsaw":
        wear_amount *= 0.35
    elif id == "flamethrower":
        wear_amount *= 0.5
    owned[id]["dur"] = maxf(0.0, float(owned[id]["dur"]) - wear_amount)
    if float(owned[id]["dur"]) <= 0.0:
        if equipped_weapon == id:
            equipped_weapon = ""
        if equipped_tool == id:
            equipped_tool = ""
        game.show_message("%s сломан. Почини его на верстаке." % String(ID.item(id)["name"]))
    mark_dirty()

## Power of the best equipped item for breaking a material (wood/scrap/stone...).
func harvest_power(material: String) -> float:
    var best := 1.0
    var mining_best := 0.34
    for id in [equipped_tool, equipped_weapon]:
        if id == "" or not owned.has(id) or is_broken(id):
            continue
        var data: Dictionary = ID.item(id)
        best = maxf(best, float(data.get("harvest", 1.0)))
        mining_best = maxf(mining_best, float(data.get("mining", 0.34)))
    return mining_best if material == "stone" else best

func wear_for_harvest() -> void:
    for id in [equipped_tool, equipped_weapon]:
        if id != "" and owned.has(id) and ID.item(id).has("harvest"):
            wear(id, 0.5)
            return

func use_consumable(id: String) -> bool:
    if int(stock.get(id, 0)) <= 0:
        return false
    var data: Dictionary = ID.item(id)
    stock[id] = int(stock[id]) - 1
    var player = game.player
    player.health = minf(player.max_health, player.health + float(data.get("heal", 0.0)))
    player.stamina = minf(player.max_stamina, player.stamina + float(data.get("stamina", 0.0)))
    game.refresh_hud()
    game.show_message("%s: +%d HP" % [String(data["name"]), roundi(float(data.get("heal", 0.0)))])
    mark_dirty()
    return true

func use_best_consumable() -> bool:
    var missing: float = game.player.max_health - game.player.health
    var best := ""
    var best_heal := 0.0
    for id in stock:
        if int(stock[id]) <= 0:
            continue
        var heal := float(ID.item(id).get("heal", 0.0))
        # Prefer the smallest item that covers the missing health, else the biggest one.
        if best == "" or (heal >= missing and (best_heal < missing or heal < best_heal)) or (best_heal < missing and heal > best_heal):
            best = id
            best_heal = heal
    if best == "":
        game.show_message("Нет бинтов и аптечек. Создай их на верстаке.")
        return false
    return use_consumable(best)

func consumable_total() -> int:
    var total := 0
    for id in stock:
        total += int(stock[id])
    return total

# ---------------------------------------------------------------- unlocks / defeats
func grant_blueprint_from(monster_id: String) -> String:
    var item_id := String(ID.BLUEPRINT_SOURCES.get(monster_id, ""))
    if item_id == "" or blueprints.has(item_id):
        return ""
    blueprints.append(item_id)
    mark_dirty()
    return item_id

func record_defeat(monster_id: String) -> void:
    if not defeated.has(monster_id):
        defeated.append(monster_id)
        mark_dirty()

func unlock_district(id: String) -> void:
    if not unlocked.has(id):
        unlocked.append(id)
        mark_dirty()

# ---------------------------------------------------------------- persistence
func save_state() -> void:
    dirty = false
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify({
        "owned": owned, "stock": stock, "weapon": equipped_weapon, "tool": equipped_tool, "equipment": equipment,
        "blueprints": blueprints, "defeated": defeated, "quests": quests,
        "notes": notes_read, "unlocked": unlocked,
    }))
    file.close()

func _load() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    var saved_owned = parsed.get("owned", {})
    if saved_owned is Dictionary:
        for id in saved_owned:
            if (ID.ITEMS.has(id) or ID.GEAR.has(id)) and saved_owned[id] is Dictionary:
                owned[id] = {"dur": float(saved_owned[id].get("dur", 1.0)), "level": clampi(int(saved_owned[id].get("level", 1)), 1, 3)}
    var saved_stock = parsed.get("stock", {})
    if saved_stock is Dictionary:
        for id in saved_stock:
            if ID.ITEMS.has(id):
                stock[id] = maxi(0, int(saved_stock[id]))
    equipped_weapon = String(parsed.get("weapon", ""))
    equipped_tool = String(parsed.get("tool", ""))
    if not owned.has(equipped_weapon):
        equipped_weapon = ""
    if not owned.has(equipped_tool):
        equipped_tool = ""
    var saved_eq = parsed.get("equipment", {})
    if saved_eq is Dictionary:
        for slot in saved_eq:
            if ID.GEAR_SLOTS.has(slot) and owned.has(String(saved_eq[slot])):
                equipment[slot] = String(saved_eq[slot])
    var bp = parsed.get("blueprints", [])
    if bp is Array:
        blueprints = bp.duplicate()
    var df = parsed.get("defeated", [])
    if df is Array:
        defeated = df.duplicate()
    var q = parsed.get("quests", {})
    if q is Dictionary:
        quests = q.duplicate(true)
    var nr = parsed.get("notes", [])
    if nr is Array:
        notes_read = nr.duplicate()
    var ul = parsed.get("unlocked", [])
    if ul is Array and not ul.is_empty():
        unlocked = ul.duplicate()
