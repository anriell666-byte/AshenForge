extends CanvasLayer
## Workbench screen: craft weapons, tools and consumables; equip, repair and sharpen gear.
## Advanced recipes need the camp workbench (stand within 7 m of the camp).

const ID = preload("res://scripts/items_data.gd")
const MD = preload("res://scripts/monster_data.gd")

var game
var progress
var tab := "weapon"
var list: VBoxContainer
var title_label: Label
var res_label: RichTextLabel
var tab_buttons := {}

const TABS := [
    {"id": "weapon", "label": "Оружие"},
    {"id": "tool", "label": "Инструменты"},
    {"id": "consumable", "label": "Расходники"},
    {"id": "wear", "label": "Одежда"},
    {"id": "gear", "label": "Снаряжение"},
]

func setup(owner_game, progress_node) -> void:
    game = owner_game
    progress = progress_node
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 40
    visible = false
    _build()

func open() -> void:
    visible = true
    get_tree().paused = true
    _refresh()

func close() -> void:
    visible = false
    get_tree().paused = false

func toggle() -> void:
    if visible:
        close()
    else:
        open()

# ---------------------------------------------------------------- layout
func _build() -> void:
    var bg := ColorRect.new()
    bg.color = Color(0.04, 0.055, 0.05, 1.0)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var margin := MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 14)
    add_child(margin)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 8)
    margin.add_child(root)

    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 12)
    root.add_child(header)
    title_label = Label.new()
    title_label.add_theme_font_size_override("font_size", 24)
    title_label.add_theme_color_override("font_color", Color(0.93, 0.86, 0.66))
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_label)
    var close_button := _button("Закрыть", Vector2(130, 46))
    close_button.pressed.connect(close)
    header.add_child(close_button)

    res_label = RichTextLabel.new()
    res_label.bbcode_enabled = true
    res_label.fit_content = true
    res_label.scroll_active = false
    res_label.add_theme_font_size_override("normal_font_size", 15)
    root.add_child(res_label)

    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation", 8)
    root.add_child(tabs)
    for t in TABS:
        var b := _button(String(t["label"]), Vector2(150, 46))
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.pressed.connect(_set_tab.bind(String(t["id"])))
        tabs.add_child(b)
        tab_buttons[t["id"]] = b

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root.add_child(scroll)
    list = VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 8)
    scroll.add_child(list)

func _set_tab(id: String) -> void:
    tab = id
    _refresh()

# ---------------------------------------------------------------- resources
func _near_camp() -> bool:
    return game.player.global_position.distance_to(game.camp_position) < 7.0

func _have(key: String) -> int:
    var n := int(game.inventory.get(key, 0))
    if _near_camp():
        n += int(game.chest_inventory.get(key, 0))
    return n

func _can_afford(cost: Dictionary) -> bool:
    for key in cost:
        if _have(key) < int(cost[key]):
            return false
    return true

func _pay(cost: Dictionary) -> void:
    for key in cost:
        var needed := int(cost[key])
        var from_bag := mini(needed, int(game.inventory.get(key, 0)))
        game.inventory[key] = int(game.inventory.get(key, 0)) - from_bag
        needed -= from_bag
        if needed > 0 and _near_camp():
            game.chest_inventory[key] = int(game.chest_inventory.get(key, 0)) - needed

func _after_change() -> void:
    game._refresh_inventory_ui()
    game.call("_refresh_chest_ui")
    game.refresh_hud()
    game.save_game(false)
    _refresh()

func _cost_bbcode(cost: Dictionary) -> String:
    var parts: Array[String] = []
    for key in cost:
        var have := _have(key)
        var need := int(cost[key])
        var col := "#9fd68a" if have >= need else "#e07a6a"
        parts.append("[color=%s]%s %d/%d[/color]" % [col, ID.RES_LABELS.get(key, key), have, need])
    return "  ".join(parts)

# ---------------------------------------------------------------- content
func _refresh() -> void:
    var bench := _near_camp()
    title_label.text = "ВЕРСТАК  •  %s" % ("у лагеря: доступны все рецепты" if bench else "вдали от лагеря: только простые рецепты")
    var res_parts: Array[String] = []
    for key in ID.RES_ORDER:
        res_parts.append("%s [color=#f0e2b0]%d[/color]" % [ID.RES_LABELS[key], _have(key)])
    res_label.text = "  •  ".join(res_parts)
    for id in tab_buttons:
        var b: Button = tab_buttons[id]
        b.disabled = (id == tab)
    for child in list.get_children():
        child.queue_free()
    if tab == "gear":
        _build_gear()
    else:
        _build_recipes(tab)

func _build_recipes(slot: String) -> void:
    var ids: Array[String] = []
    for id in ID.all_ids():
        var item_slot := String(ID.item(id)["slot"])
        if (slot == "wear" and ID.GEAR_SLOTS.has(item_slot)) or item_slot == slot:
            ids.append(id)
    ids.sort_custom(func(a: String, b: String) -> bool:
        var ta := int(ID.item(a)["tier"])
        var tb := int(ID.item(b)["tier"])
        return ta < tb or (ta == tb and a < b))
    for id in ids:
        _recipe_card(id)

func _stats_line(data: Dictionary) -> String:
    var parts: Array[String] = []
    if data.has("damage") and String(data["slot"]) != "consumable":
        parts.append("Урон %d" % roundi(float(data["damage"])))
        parts.append("Дальность %.1f" % float(data["reach"]))
        parts.append("Удар/с %.1f" % (1.0 / maxf(0.05, float(data["cooldown"]))))
        parts.append("Прочность %d" % roundi(float(data["durability"])))
    if data.has("heal"):
        parts.append("Лечение %d" % roundi(float(data["heal"])))
    if float(data.get("armor", 0.0)) > 0.0:
        parts.append("Броня %d%%" % roundi(float(data["armor"]) * 100.0))
    if float(data.get("carry", 0.0)) > 0.0:
        parts.append("Рюкзак +%d кг" % roundi(float(data["carry"])))
    if data.has("harvest"):
        parts.append("Разборка ×%.1f" % float(data["harvest"]))
    if data.has("mining") and float(data["mining"]) >= 1.0:
        parts.append("Добыча камня ×%.1f" % float(data["mining"]))
    var kind := String(data.get("kind", ""))
    if kind == "ranged":
        parts.append("Дальний бой")
    elif kind == "cone":
        parts.append("Конус огня")
    if data.has("aoe"):
        parts.append("Удар по площади")
    if data.has("stun"):
        parts.append("Оглушение")
    return "  •  ".join(parts)

func _card(title: String, tier: int) -> Array:
    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.1, 0.13, 0.12, 0.98)
    style.set_corner_radius_all(12)
    style.set_border_width_all(2)
    style.border_color = [Color(0.4, 0.5, 0.42), Color(0.55, 0.62, 0.45), Color(0.82, 0.62, 0.3)][clampi(tier - 1, 0, 2)]
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    panel.add_theme_stylebox_override("panel", style)
    list.add_child(panel)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    panel.add_child(row)
    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.add_theme_constant_override("separation", 2)
    row.add_child(info)
    var name_label := Label.new()
    name_label.text = title
    name_label.add_theme_font_size_override("font_size", 20)
    name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
    info.add_child(name_label)
    return [info, row]

func _info_label(info: VBoxContainer, text: String, size: int = 14, color: Color = Color(0.75, 0.8, 0.74)) -> Label:
    var l := Label.new()
    l.text = text
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    info.add_child(l)
    return l

func _info_rich(info: VBoxContainer, bbcode: String) -> void:
    var r := RichTextLabel.new()
    r.bbcode_enabled = true
    r.fit_content = true
    r.scroll_active = false
    r.add_theme_font_size_override("normal_font_size", 14)
    r.text = bbcode
    info.add_child(r)

func _recipe_card(id: String) -> void:
    var data: Dictionary = ID.item(id)
    var tier := int(data["tier"])
    var parts := _card("%s   [ур. рецепта %d]" % [String(data["name"]), tier], tier)
    var info: VBoxContainer = parts[0]
    var row: HBoxContainer = parts[1]
    _info_label(info, String(data["desc"]))
    var stats := _stats_line(data)
    if stats != "":
        _info_label(info, stats, 13, Color(0.6, 0.72, 0.85))
    var is_consumable := String(data["slot"]) == "consumable"
    var action: Button
    if not progress.can_craft(id):
        var source := ID.blueprint_for(id)
        var source_name := String(MD.get_monster(source).get("name", source))
        _info_label(info, "Чертёж ещё не найден. Его носит: %s" % source_name, 14, Color(0.9, 0.6, 0.4))
        action = _button("Закрыто", Vector2(170, 54))
        action.disabled = true
    else:
        _info_rich(info, _cost_bbcode(data["cost"]))
        var needs_bench := bool(data.get("needs_bench", false))
        if needs_bench and not _near_camp():
            _info_label(info, "Нужен верстак в лагере.", 14, Color(0.9, 0.75, 0.4))
        if not is_consumable and progress.has_item(id):
            action = _button("Создано", Vector2(170, 54))
            action.disabled = true
        else:
            action = _button("Создать", Vector2(170, 54))
            action.disabled = (needs_bench and not _near_camp()) or not _can_afford(data["cost"])
            action.pressed.connect(_craft.bind(id))
    row.add_child(action)

func _craft(id: String) -> void:
    var data: Dictionary = ID.item(id)
    if not progress.can_craft(id):
        return
    if bool(data.get("needs_bench", false)) and not _near_camp():
        game.show_message("Нужен верстак в лагере.")
        return
    if not _can_afford(data["cost"]):
        game.show_message("Не хватает ресурсов.")
        return
    _pay(data["cost"])
    progress.add_item(id)
    game.show_message("Создано: %s" % String(data["name"]))
    _after_change()

func _build_gear() -> void:
    var any := false
    var ids: Array[String] = []
    for id in progress.owned:
        if not ID.is_gear(id):
            ids.append(id)
    ids.sort()
    for id in ids:
        any = true
        _gear_card(id)
    var stock_lines: Array[String] = []
    for id in progress.stock:
        if int(progress.stock[id]) > 0:
            stock_lines.append("%s ×%d" % [String(ID.item(id)["name"]), int(progress.stock[id])])
    if not stock_lines.is_empty():
        var parts := _card("Расходники", 1)
        _info_label(parts[0], "  •  ".join(stock_lines) + "\nИспользуй кнопку ЛЕЧЕНИЕ на экране игры.")
    if not any:
        var parts := _card("Пока пусто", 1)
        _info_label(parts[0], "Создай оружие или инструмент на вкладках выше. Простые рецепты доступны сразу.")

func _gear_card(id: String) -> void:
    var data: Dictionary = ID.item(id)
    var state: Dictionary = progress.owned[id]
    var level := int(state["level"])
    var equipped: bool = id == progress.equipped_weapon or id == progress.equipped_tool
    var title := "%s  ур. %d%s" % [String(data["name"]), level, "   ✔ в руках" if equipped else ""]
    var parts := _card(title, int(data["tier"]))
    var info: VBoxContainer = parts[0]
    var row: HBoxContainer = parts[1]
    var max_dur: float = progress.max_durability(id)
    var dur := float(state["dur"])
    _info_label(info, "Прочность %d / %d%s" % [roundi(dur), roundi(max_dur), "   СЛОМАНО" if dur <= 0.0 else ""], 15, Color(0.95, 0.6, 0.5) if dur <= 0.0 else Color(0.75, 0.82, 0.75))
    var stats: Dictionary = data.duplicate()
    stats["damage"] = float(data["damage"]) * ID.level_multiplier(level)
    _info_label(info, _stats_line(stats), 13, Color(0.6, 0.72, 0.85))
    var buttons := VBoxContainer.new()
    buttons.add_theme_constant_override("separation", 6)
    row.add_child(buttons)
    var equip_button := _button("Снять" if equipped else "Надеть", Vector2(170, 46))
    equip_button.disabled = dur <= 0.0
    equip_button.pressed.connect(_toggle_equip.bind(id))
    buttons.add_child(equip_button)
    if dur < max_dur:
        var cost: Dictionary = progress.repair_cost(id)
        var repair_button := _button("Починить", Vector2(170, 46))
        repair_button.disabled = not _can_afford(cost)
        repair_button.pressed.connect(_repair.bind(id))
        buttons.add_child(repair_button)
        _info_rich(info, "Починка: " + _cost_bbcode(cost))
    if level < 3:
        var up_cost := ID.upgrade_cost(level)
        var up_button := _button("Заточить ур. %d" % (level + 1), Vector2(170, 46))
        up_button.disabled = not _can_afford(up_cost) or (bool(data.get("needs_bench", false)) and not _near_camp()) or String(data["slot"]) == "consumable"
        up_button.pressed.connect(_upgrade.bind(id))
        buttons.add_child(up_button)
        _info_rich(info, "Улучшение: " + _cost_bbcode(up_cost))

func _toggle_equip(id: String) -> void:
    var slot := String(ID.item(id)["slot"])
    if (slot == "weapon" and progress.equipped_weapon == id) or (slot == "tool" and progress.equipped_tool == id):
        progress.unequip(slot)
    else:
        progress.equip(id)
    game._refresh_inventory_ui()
    _refresh()

func _repair(id: String) -> void:
    var cost: Dictionary = progress.repair_cost(id)
    if not _can_afford(cost):
        return
    _pay(cost)
    progress.repair(id)
    game.show_message("Починено: %s" % String(ID.item(id)["name"]))
    _after_change()

func _upgrade(id: String) -> void:
    var level := int(progress.owned[id]["level"])
    var cost := ID.upgrade_cost(level)
    if cost.is_empty() or not _can_afford(cost):
        return
    _pay(cost)
    progress.upgrade(id)
    game.show_message("%s заточен до уровня %d" % [String(ID.item(id)["name"]), level + 1])
    _after_change()

# ---------------------------------------------------------------- styling
func _button(text: String, min_size: Vector2) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = min_size
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 17)
    button.add_theme_color_override("font_color", Color(0.91, 0.94, 0.87))
    button.add_theme_color_override("font_disabled_color", Color(0.5, 0.54, 0.5))
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(0.1, 0.13, 0.12, 0.95)
    normal.border_color = Color(0.48, 0.57, 0.48, 0.95)
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(12)
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color(0.17, 0.22, 0.19, 1.0)
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color(0.34, 0.27, 0.16, 1.0)
    var disabled := normal.duplicate() as StyleBoxFlat
    disabled.bg_color = Color(0.07, 0.08, 0.075, 0.7)
    disabled.border_color = Color(0.28, 0.31, 0.28, 0.7)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)
    button.add_theme_stylebox_override("focus", normal)
    button.add_theme_stylebox_override("disabled", disabled)
    return button
