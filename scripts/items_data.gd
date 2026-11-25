extends RefCounted
## Item catalogue: weapons, tools, consumables, crafting costs and blueprint sources.
## Blueprints drop from mini bosses and bosses (see BLUEPRINT_SOURCES).

const RES_LABELS := {
    "wood": "Дерево", "scrap": "Металлолом", "plastic": "Пластик", "cloth": "Ткань", "food": "Еда",
    "medicine": "Медикаменты", "stone": "Камень", "fuel": "Топливо", "essence": "Эссенция", "seal": "Печать",
}
const RES_COLORS := {
    "wood": Color(0.58, 0.36, 0.17), "scrap": Color(0.62, 0.68, 0.66), "plastic": Color(0.25, 0.65, 0.7),
    "cloth": Color(0.65, 0.52, 0.35), "food": Color(0.7, 0.55, 0.22), "medicine": Color(0.8, 0.78, 0.68),
    "stone": Color(0.5, 0.5, 0.46), "fuel": Color(0.85, 0.35, 0.12), "essence": Color(0.7, 0.35, 0.9),
    "seal": Color(1.0, 0.82, 0.3),
}
const RES_WEIGHTS := {"stone": 1.0, "fuel": 0.6, "essence": 0.1, "seal": 0.1}
const RES_ORDER := ["wood", "scrap", "plastic", "cloth", "food", "medicine", "stone", "fuel", "essence", "seal"]

## slot: weapon | tool | consumable. kind: melee | ranged | cone.
## harvest: multiplier when breaking objects, mining: multiplier on stone deposits.
const ITEMS := {
    # ------------------------------------------------------------ tools
    "hatchet": {"name": "Каменный топор", "slot": "tool", "tier": 1, "damage": 16.0, "reach": 2.6, "cooldown": 0.55, "kind": "melee",
        "durability": 80.0, "harvest": 2.5, "mining": 0.8, "cost": {"wood": 3, "scrap": 2}, "desc": "Быстрая разборка дерева и мебели."},
    "crowbar": {"name": "Монтировка", "slot": "tool", "tier": 1, "damage": 18.0, "reach": 2.6, "cooldown": 0.55, "kind": "melee",
        "durability": 90.0, "harvest": 3.0, "mining": 1.0, "cost": {"wood": 1, "scrap": 4}, "desc": "Вскрывает баррикады и двери."},
    "pickaxe": {"name": "Кирка", "slot": "tool", "tier": 1, "damage": 17.0, "reach": 2.6, "cooldown": 0.6, "kind": "melee",
        "durability": 100.0, "harvest": 1.2, "mining": 3.5, "cost": {"wood": 2, "scrap": 4, "stone": 2}, "desc": "Добыча камня в карьере."},
    # ------------------------------------------------------------ weapons
    "club": {"name": "Дубина с гвоздями", "slot": "weapon", "tier": 1, "damage": 14.0, "reach": 2.7, "cooldown": 0.5, "kind": "melee",
        "durability": 60.0, "cost": {"wood": 3, "scrap": 2}, "desc": "Простое и надёжное оружие."},
    "machete": {"name": "Мачете", "slot": "weapon", "tier": 1, "damage": 20.0, "reach": 2.6, "cooldown": 0.42, "kind": "melee",
        "durability": 70.0, "cost": {"scrap": 4, "cloth": 1, "wood": 1}, "desc": "Быстрые удары, хороша против слабых врагов."},
    "spear": {"name": "Самодельное копьё", "slot": "weapon", "tier": 1, "damage": 28.0, "reach": 3.2, "cooldown": 0.6, "kind": "melee",
        "durability": 55.0, "cost": {"wood": 4, "scrap": 1}, "desc": "Длинное, бьёт издалека."},
    "sling": {"name": "Праща", "slot": "weapon", "tier": 1, "damage": 12.0, "reach": 7.0, "cooldown": 0.7, "kind": "ranged",
        "durability": 80.0, "cost": {"cloth": 2, "wood": 1}, "desc": "Дальний бой, но слабый урон."},
    "bow": {"name": "Лук охотника", "slot": "weapon", "tier": 1, "damage": 22.0, "reach": 9.0, "cooldown": 0.9, "kind": "ranged",
        "durability": 70.0, "cost": {"wood": 5, "cloth": 2}, "desc": "Дальняя охота и бой."},
    "fire_axe": {"name": "Пожарный топор", "slot": "weapon", "tier": 2, "damage": 32.0, "reach": 2.8, "cooldown": 0.65, "kind": "melee",
        "durability": 90.0, "harvest": 3.0, "mining": 0.8, "cost": {"scrap": 6, "wood": 3}, "needs_bench": true,
        "desc": "Тяжёлый топор: и оружие, и инструмент."},
    "crossbow": {"name": "Арбалет", "slot": "weapon", "tier": 2, "damage": 44.0, "reach": 11.0, "cooldown": 1.4, "kind": "ranged",
        "durability": 80.0, "cost": {"wood": 4, "scrap": 6, "cloth": 2}, "needs_bench": true, "desc": "Мощный выстрел издалека."},
    "sledgehammer": {"name": "Кувалда", "slot": "weapon", "tier": 2, "damage": 50.0, "reach": 2.7, "cooldown": 1.15, "kind": "melee",
        "aoe": 2.4, "knockback": 6.0, "durability": 90.0, "harvest": 3.5, "mining": 2.0,
        "cost": {"scrap": 10, "wood": 4, "stone": 4}, "needs_bench": true, "desc": "Бьёт по площади и отбрасывает врагов."},
    "shock_baton": {"name": "Шоковая дубинка", "slot": "weapon", "tier": 3, "damage": 26.0, "reach": 2.6, "cooldown": 0.5, "kind": "melee",
        "stun": 0.9, "durability": 100.0, "cost": {"scrap": 6, "plastic": 4, "fuel": 2}, "needs_bench": true,
        "desc": "Оглушает врагов на короткое время."},
    "chainsaw": {"name": "Бензопила", "slot": "weapon", "tier": 3, "damage": 15.0, "reach": 2.4, "cooldown": 0.18, "kind": "melee",
        "durability": 140.0, "harvest": 6.0, "mining": 1.5, "cost": {"scrap": 10, "fuel": 4, "plastic": 2}, "needs_bench": true,
        "desc": "Очень быстрые удары. Расходует топливо (прочность)."},
    "flamethrower": {"name": "Огнемёт", "slot": "weapon", "tier": 3, "damage": 9.0, "reach": 4.4, "cooldown": 0.25, "kind": "cone",
        "burn": 6.0, "durability": 100.0, "cost": {"scrap": 8, "fuel": 6, "plastic": 3}, "needs_bench": true,
        "desc": "Конус огня, поджигает врагов."},
    # ------------------------------------------------------------ consumables
    "bandage": {"name": "Бинт", "slot": "consumable", "tier": 1, "heal": 25.0, "cost": {"cloth": 2}, "desc": "Лечит 25 HP."},
    "stew": {"name": "Похлёбка", "slot": "consumable", "tier": 1, "heal": 35.0, "stamina": 60.0, "cost": {"food": 3, "wood": 1},
        "desc": "Лечит 35 HP и восстанавливает выносливость."},
    "medkit": {"name": "Аптечка", "slot": "consumable", "tier": 2, "heal": 70.0, "cost": {"medicine": 2, "cloth": 2, "plastic": 1},
        "needs_bench": true, "desc": "Лечит 70 HP."},
}

## Wearable gear. slot: head | body | legs | feet | back. armor = share of damage absorbed,
## carry = extra backpack capacity (kg). look/color drive the 3D model on the hero.
const GEAR_SLOTS := ["head", "body", "legs", "feet", "back"]
const SLOT_LABELS := {"head": "Голова", "body": "Тело", "legs": "Ноги", "feet": "Обувь", "back": "Спина", "weapon": "Оружие", "tool": "Инструмент"}
const GEAR := {
    "cap": {"name": "Кепка", "slot": "head", "tier": 1, "armor": 0.02, "look": "cap", "color": Color(0.32, 0.38, 0.27), "cost": {"cloth": 2}, "desc": "Защищает от солнца и чуть-чуть от укусов."},
    "helmet": {"name": "Строительная каска", "slot": "head", "tier": 2, "armor": 0.08, "look": "helmet", "color": Color(0.88, 0.7, 0.14), "cost": {"scrap": 5, "cloth": 1}, "needs_bench": true, "desc": "Жёсткая каска смягчает удары по голове."},
    "riot_helmet": {"name": "Шлем штурмовика", "slot": "head", "tier": 3, "armor": 0.14, "look": "riot", "color": Color(0.16, 0.18, 0.2), "cost": {"scrap": 8, "plastic": 4}, "needs_bench": true, "desc": "Тяжёлый шлем с забралом."},
    "hoodie": {"name": "Тёплая куртка", "slot": "body", "tier": 1, "armor": 0.03, "look": "jacket", "color": Color(0.45, 0.32, 0.2), "cost": {"cloth": 4}, "desc": "Плотная ткань: немного защищает."},
    "leather_jacket": {"name": "Кожаная куртка", "slot": "body", "tier": 2, "armor": 0.08, "look": "jacket", "color": Color(0.2, 0.15, 0.12), "cost": {"cloth": 4, "scrap": 2}, "needs_bench": true, "desc": "Прочная кожа держит когти."},
    "vest": {"name": "Бронежилет", "slot": "body", "tier": 2, "armor": 0.15, "look": "vest", "color": Color(0.2, 0.24, 0.22), "cost": {"scrap": 8, "cloth": 3, "plastic": 2}, "needs_bench": true, "desc": "Пластины на груди и спине."},
    "plate_armor": {"name": "Пластинчатая броня", "slot": "body", "tier": 3, "armor": 0.24, "look": "plate", "color": Color(0.5, 0.52, 0.55), "cost": {"scrap": 14, "plastic": 4, "fuel": 2}, "needs_bench": true, "desc": "Самая крепкая броня. Чертёж носит Мясник."},
    "work_pants": {"name": "Рабочие штаны", "slot": "legs", "tier": 1, "armor": 0.02, "look": "pants", "color": Color(0.22, 0.3, 0.42), "cost": {"cloth": 3}, "desc": "Простые штаны из плотной ткани."},
    "cargo_pants": {"name": "Штаны с накладками", "slot": "legs", "tier": 2, "armor": 0.06, "look": "pants", "color": Color(0.28, 0.3, 0.2), "cost": {"cloth": 3, "scrap": 2}, "needs_bench": true, "desc": "Накладки на коленях и бёдрах."},
    "boots": {"name": "Крепкие ботинки", "slot": "feet", "tier": 1, "armor": 0.02, "look": "boots", "color": Color(0.24, 0.17, 0.11), "cost": {"cloth": 2, "scrap": 1}, "desc": "Высокие ботинки."},
    "steel_boots": {"name": "Ботинки со сталью", "slot": "feet", "tier": 2, "armor": 0.06, "look": "boots", "color": Color(0.12, 0.12, 0.13), "cost": {"scrap": 5, "cloth": 1}, "needs_bench": true, "desc": "Стальные носки и накладки."},
    "pack_small": {"name": "Походный рюкзак", "slot": "back", "tier": 1, "armor": 0.0, "carry": 10.0, "look": "pack_small", "color": Color(0.35, 0.3, 0.16), "cost": {"cloth": 4, "wood": 1}, "desc": "+10 кг к грузоподъёмности."},
    "pack_big": {"name": "Туристический рюкзак", "slot": "back", "tier": 2, "armor": 0.0, "carry": 25.0, "look": "pack_big", "color": Color(0.7, 0.25, 0.14), "cost": {"cloth": 8, "plastic": 3, "scrap": 2}, "needs_bench": true, "desc": "+25 кг к грузоподъёмности."},
}

## Blueprint -> item. Key is the monster id that drops it.
const BLUEPRINT_SOURCES := {
    "mb_gravedigger": "fire_axe",
    "mb_hunter": "crossbow",
    "mb_welder": "chainsaw",
    "boss_foreman": "sledgehammer",
    "mb_nurse": "medkit",
    "boss_ripper": "shock_baton",
    "mb_butcher": "plate_armor",
    "boss_fistking": "flamethrower",
}

static func item(id: String) -> Dictionary:
    if GEAR.has(id):
        return GEAR[id]
    return ITEMS.get(id, {})

static func is_gear(id: String) -> bool:
    return GEAR.has(id)

static func all_ids() -> Array:
    var ids: Array = ITEMS.keys()
    ids.append_array(GEAR.keys())
    return ids

static func blueprint_for(item_id: String) -> String:
    for monster_id in BLUEPRINT_SOURCES:
        if BLUEPRINT_SOURCES[monster_id] == item_id:
            return monster_id
    return ""

static func needs_blueprint(item_id: String) -> bool:
    return blueprint_for(item_id) != ""

static func cost_text(cost: Dictionary) -> String:
    var out: Array[String] = []
    for key in cost:
        out.append("%s %d" % [RES_LABELS.get(key, key), int(cost[key])])
    return ", ".join(out)

## Damage / durability scaling for weapon level (1..3).
static func level_multiplier(level: int) -> float:
    return 1.0 + 0.25 * float(maxi(0, level - 1))

static func upgrade_cost(level: int) -> Dictionary:
    if level == 1:
        return {"scrap": 4, "essence": 1}
    if level == 2:
        return {"scrap": 8, "essence": 2}
    return {}
