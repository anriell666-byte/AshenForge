extends CanvasLayer
## Backpack window: equipment slots around a live 3D preview of the hero, an item grid,
## and a detail panel with actions. Opens as a paused full-screen layer.

const ID = preload("res://scripts/items_data.gd")
const Cell = preload("res://scripts/item_cell.gd")
const ML = preload("res://scripts/model_lib.gd")
const CC = preload("res://scripts/character_creator.gd")

const FILTERS := [["all", "Всё"], ["weapon", "Оружие"], ["wear", "Одежда"], ["res", "Ресурсы"]]
const GRID_COLUMNS := 6
const MIN_CELLS := 30

var game
var progress
var filter: String = "all"
var selected_id: String = ""
var from_slot: String = ""
var grid: GridContainer
var slot_cells := {}
var filter_buttons := {}
var title_label: Label
var weight_label: Label
var weight_bar: ProgressBar
var stats_label: Label
var skill_label: Label
var upgrade_buttons: Array[Button] = []
var detail_name: Label
var detail_text: Label
var detail_stats: Label
var action_button: Button
var action2_button: Button
var doll_viewport: SubViewport
var doll_pivot: Node3D
var doll_model: Node3D
var _last_visual := ""

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
    selected_id = ""
    from_slot = ""
    refresh()

func close() -> void:
    visible = false
    get_tree().paused = false

func toggle() -> void:
    if visible:
        close()
    else:
        open()

func _process(delta: float) -> void:
    if visible and is_instance_valid(doll_pivot):
        doll_pivot.rotation.y += delta * 0.5

# ---------------------------------------------------------------- layout
func _build() -> void:
    var bg := ColorRect.new()
    bg.color = Color(0.04, 0.055, 0.05, 1.0)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var margin := MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 12)
    add_child(margin)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 8)
    margin.add_child(root)

    # header: title, weight bar, close
    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 14)
    root.add_child(header)
    title_label = Label.new()
    title_label.text = "РЮКЗАК"
    title_label.add_theme_font_size_override("font_size", 26)
    title_label.add_theme_color_override("font_color", Color(0.93, 0.86, 0.66))
    title_label.custom_minimum_size = Vector2(140, 0)
    header.add_child(title_label)
    var weight_box := VBoxContainer.new()
    weight_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    weight_box.add_theme_constant_override("separation", 2)
    header.add_child(weight_box)
    weight_label = Label.new()
    weight_label.add_theme_font_size_override("font_size", 15)
    weight_label.add_theme_color_override("font_color", Color(0.8, 0.86, 0.78))
    weight_box.add_child(weight_label)
    weight_bar = ProgressBar.new()
    weight_bar.show_percentage = false
    weight_bar.custom_minimum_size = Vector2(0, 14)
    var fill := StyleBoxFlat.new()
    fill.bg_color = Color(0.85, 0.65, 0.25)
    fill.set_corner_radius_all(6)
    var back := StyleBoxFlat.new()
    back.bg_color = Color(0.1, 0.13, 0.12)
    back.set_corner_radius_all(6)
    weight_bar.add_theme_stylebox_override("fill", fill)
    weight_bar.add_theme_stylebox_override("background", back)
    weight_box.add_child(weight_bar)
    var close_button := _button("✕  Закрыть", Vector2(160, 52))
    close_button.pressed.connect(close)
    header.add_child(close_button)

    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 12)
    root.add_child(body)
    body.add_child(_build_doll_panel())
    body.add_child(_build_items_panel())

func _panel(color: Color = Color(0.085, 0.11, 0.105)) -> PanelContainer:
    var p := PanelContainer.new()
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.set_corner_radius_all(14)
    s.set_border_width_all(2)
    s.border_color = Color(0.27, 0.34, 0.31)
    s.content_margin_left = 10
    s.content_margin_right = 10
    s.content_margin_top = 8
    s.content_margin_bottom = 8
    p.add_theme_stylebox_override("panel", s)
    return p

func _build_doll_panel() -> Control:
    var panel := _panel()
    panel.custom_minimum_size = Vector2(450, 0)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 6)
    panel.add_child(col)
    var row := HBoxContainer.new()
    row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 6)
    col.add_child(row)
    row.add_child(_slot_column(["head", "body", "legs", "feet"]))
    var container := SubViewportContainer.new()
    container.stretch = true
    container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    row.add_child(container)
    doll_viewport = SubViewport.new()
    doll_viewport.own_world_3d = true
    doll_viewport.size = Vector2i(220, 420)
    doll_viewport.transparent_bg = false
    doll_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
    container.add_child(doll_viewport)
    _build_doll_world()
    row.add_child(_slot_column(["back", "weapon", "tool"]))
    stats_label = Label.new()
    stats_label.add_theme_font_size_override("font_size", 16)
    stats_label.add_theme_color_override("font_color", Color(0.9, 0.84, 0.62))
    stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(stats_label)
    skill_label = Label.new()
    skill_label.add_theme_font_size_override("font_size", 14)
    skill_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.75))
    skill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(skill_label)
    var skills := HBoxContainer.new()
    skills.add_theme_constant_override("separation", 6)
    col.add_child(skills)
    for entry in [["Выносл. +15", "_upgrade_stamina"], ["Скорость +0.2", "_upgrade_speed"], ["Груз +10 кг", "_upgrade_capacity"]]:
        var b := _button(String(entry[0]), Vector2(0, 46))
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.add_theme_font_size_override("font_size", 15)
        b.pressed.connect(func() -> void:
            game.call(String(entry[1]))
            refresh())
        skills.add_child(b)
        upgrade_buttons.append(b)
    return panel

func _slot_column(slots: Array) -> Control:
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 8)
    for slot in slots:
        var cell: Button = Cell.new()
        cell.custom_minimum_size = Vector2(82, 82)
        cell.slot_hint = String(ID.SLOT_LABELS[slot])
        cell.pressed.connect(_on_slot_pressed.bind(String(slot)))
        col.add_child(cell)
        slot_cells[slot] = cell
    return col

func _build_doll_world() -> void:
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.17, 0.21, 0.2)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.78, 0.8, 0.82)
    e.ambient_light_energy = 0.8
    env.environment = e
    doll_viewport.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-38, -150, 0)
    sun.light_energy = 1.15
    doll_viewport.add_child(sun)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-20, 40, 0)
    fill.light_energy = 0.45
    doll_viewport.add_child(fill)
    doll_pivot = Node3D.new()
    doll_viewport.add_child(doll_pivot)
    var cam := Camera3D.new()
    cam.fov = 32
    doll_viewport.add_child(cam)
    cam.look_at_from_position(Vector3(0, 0.98, -4.3), Vector3(0, 0.9, 0))

func _build_items_panel() -> Control:
    var panel := _panel()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 8)
    panel.add_child(col)
    var filters := HBoxContainer.new()
    filters.add_theme_constant_override("separation", 6)
    col.add_child(filters)
    for f in FILTERS:
        var b := _button(String(f[1]), Vector2(0, 46))
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.pressed.connect(_set_filter.bind(String(f[0])))
        filters.add_child(b)
        filter_buttons[f[0]] = b
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    col.add_child(scroll)
    grid = GridContainer.new()
    grid.columns = GRID_COLUMNS
    grid.add_theme_constant_override("h_separation", 6)
    grid.add_theme_constant_override("v_separation", 6)
    scroll.add_child(grid)
    # details
    var detail := _panel(Color(0.06, 0.08, 0.075))
    detail.custom_minimum_size = Vector2(0, 118)
    col.add_child(detail)
    var drow := HBoxContainer.new()
    drow.add_theme_constant_override("separation", 10)
    detail.add_child(drow)
    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.add_theme_constant_override("separation", 2)
    drow.add_child(info)
    detail_name = Label.new()
    detail_name.add_theme_font_size_override("font_size", 20)
    detail_name.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
    info.add_child(detail_name)
    detail_text = Label.new()
    detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    detail_text.add_theme_font_size_override("font_size", 14)
    detail_text.add_theme_color_override("font_color", Color(0.75, 0.8, 0.74))
    info.add_child(detail_text)
    detail_stats = Label.new()
    detail_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    detail_stats.add_theme_font_size_override("font_size", 13)
    detail_stats.add_theme_color_override("font_color", Color(0.6, 0.72, 0.85))
    info.add_child(detail_stats)
    var buttons := VBoxContainer.new()
    buttons.add_theme_constant_override("separation", 6)
    drow.add_child(buttons)
    action_button = _button("", Vector2(150, 48))
    action_button.pressed.connect(_do_action)
    buttons.add_child(action_button)
    action2_button = _button("", Vector2(150, 42))
    action2_button.pressed.connect(_do_action2)
    buttons.add_child(action2_button)
    return panel

# ---------------------------------------------------------------- content
func refresh() -> void:
    if not visible and not is_inside_tree():
        return
    var cap: float = game.call("max_carry")
    var weight: float = game.call("_inventory_weight")
    weight_label.text = "Вес  %.1f / %.0f кг        Уровень %d  •  опыт %d/%d" % [weight, cap, game.player_level, game.player_xp, game.player_level * 100]
    weight_bar.max_value = cap
    weight_bar.value = minf(weight, cap)
    stats_label.text = "Броня %d%%    Рюкзак %.0f кг" % [roundi(progress.armor_total() * 100.0), cap]
    skill_label.text = "Очки навыков: %d" % game.skill_points
    for b in upgrade_buttons:
        b.disabled = game.skill_points <= 0
    for f in filter_buttons:
        _style_toggle(filter_buttons[f] as Button, f == filter)
    _refresh_slots()
    _refresh_grid()
    _refresh_detail()
    _refresh_doll()

func _refresh_slots() -> void:
    for slot in slot_cells:
        var cell: Button = slot_cells[slot]
        var id: String = progress.equipped_in(slot)
        cell.item_id = id
        cell.count = 0
        cell.selected = (from_slot == slot and id != "")
        cell.dur_ratio = _dur_ratio(id) if id != "" else -1.0
        cell.broken = id != "" and progress.is_broken(id)
        cell.queue_redraw()

func _dur_ratio(id: String) -> float:
    if ID.is_gear(id) or not progress.owned.has(id):
        return -1.0
    var maxd: float = progress.max_durability(id)
    return float(progress.owned[id]["dur"]) / maxf(1.0, maxd)

func _grid_entries() -> Array:
    var entries: Array = []
    var owned_ids: Array = progress.owned.keys()
    owned_ids.sort()
    for id in owned_ids:
        var slot := String(ID.item(id)["slot"])
        if progress.equipped_in(slot) == id:
            continue
        var is_wear := ID.GEAR_SLOTS.has(slot)
        if filter == "wear" and not is_wear:
            continue
        if filter == "weapon" and (is_wear or slot == "consumable"):
            continue
        if filter == "res":
            continue
        entries.append({"id": id, "count": 1})
    if filter == "all" or filter == "weapon":
        var stock_ids: Array = progress.stock.keys()
        stock_ids.sort()
        for id in stock_ids:
            if int(progress.stock[id]) > 0:
                entries.append({"id": id, "count": int(progress.stock[id])})
    if filter == "all" or filter == "res":
        for key in ID.RES_ORDER:
            if int(game.inventory.get(key, 0)) > 0:
                entries.append({"id": key, "count": int(game.inventory[key])})
    return entries

func _refresh_grid() -> void:
    for child in grid.get_children():
        grid.remove_child(child)
        child.queue_free()
    var entries := _grid_entries()
    var total := maxi(MIN_CELLS, int(ceil(float(entries.size()) / float(GRID_COLUMNS))) * GRID_COLUMNS)
    for i in range(total):
        var cell: Button = Cell.new()
        if i < entries.size():
            var entry: Dictionary = entries[i]
            var id := String(entry["id"])
            cell.item_id = id
            cell.count = int(entry["count"])
            cell.selected = (selected_id == id and from_slot == "")
            cell.dur_ratio = _dur_ratio(id)
            cell.broken = progress.is_broken(id)
            cell.pressed.connect(_on_item_pressed.bind(id))
        grid.add_child(cell)

func _refresh_detail() -> void:
    var id := selected_id
    action_button.visible = false
    action2_button.visible = false
    if id == "":
        detail_name.text = "Выбери предмет"
        detail_text.text = "Нажми на предмет в сетке или на слот, чтобы увидеть описание. Оружие, одежда и рюкзаки надеваются кнопкой."
        detail_stats.text = ""
        return
    var data: Dictionary = ID.item(id)
    if data.is_empty():
        detail_name.text = String(ID.RES_LABELS.get(id, id))
        detail_text.text = "Ресурс. Нужен для создания предметов на верстаке. Лишнее можно сложить на склад в лагере."
        detail_stats.text = "В рюкзаке: %d" % int(game.inventory.get(id, 0))
        return
    detail_name.text = String(data["name"])
    detail_text.text = String(data.get("desc", ""))
    var parts: Array[String] = []
    if data.has("damage") and String(data["slot"]) != "consumable":
        var level := int(progress.owned.get(id, {"level": 1})["level"])
        parts.append("Урон %d" % roundi(float(data["damage"]) * ID.level_multiplier(level)))
        parts.append("Дальность %.1f" % float(data["reach"]))
    if float(data.get("armor", 0.0)) > 0.0:
        parts.append("Броня %d%%" % roundi(float(data["armor"]) * 100.0))
    if float(data.get("carry", 0.0)) > 0.0:
        parts.append("Рюкзак +%d кг" % roundi(float(data["carry"])))
    if data.has("heal"):
        parts.append("Лечение %d" % roundi(float(data["heal"])))
    if progress.owned.has(id) and not ID.is_gear(id):
        parts.append("Прочность %d/%d" % [roundi(float(progress.owned[id]["dur"])), roundi(progress.max_durability(id))])
    detail_stats.text = "  •  ".join(parts)
    var slot := String(data["slot"])
    action_button.visible = true
    if slot == "consumable":
        action_button.text = "Использовать"
        action_button.disabled = int(progress.stock.get(id, 0)) <= 0
    elif from_slot != "":
        action_button.text = "Снять"
        action_button.disabled = false
    else:
        action_button.text = "Надеть"
        action_button.disabled = progress.is_broken(id)

func _refresh_doll() -> void:
    var key: String = progress.visual_signature()
    if key == _last_visual and is_instance_valid(doll_model):
        return
    _last_visual = key
    if is_instance_valid(doll_model):
        doll_model.queue_free()
    if not ML.has_assets():
        return
    var built: Dictionary = ML.build_hero(CC.load_saved(), progress.visual_gear())
    doll_model = built["model"]
    doll_pivot.add_child(doll_model)

# ---------------------------------------------------------------- actions
func _set_filter(f: String) -> void:
    filter = f
    refresh()

func _on_item_pressed(id: String) -> void:
    selected_id = id
    from_slot = ""
    refresh()

func _on_slot_pressed(slot: String) -> void:
    var id: String = progress.equipped_in(slot)
    if id == "":
        selected_id = ""
        from_slot = ""
        filter = "weapon" if slot in ["weapon", "tool"] else "wear"
    else:
        selected_id = id
        from_slot = slot
    refresh()

func _do_action() -> void:
    if selected_id == "":
        return
    var data: Dictionary = ID.item(selected_id)
    var slot := String(data["slot"])
    if slot == "consumable":
        progress.use_consumable(selected_id)
        if int(progress.stock.get(selected_id, 0)) <= 0:
            selected_id = ""
    elif from_slot != "":
        progress.unequip(from_slot)
        from_slot = ""
    else:
        progress.equip(selected_id)
        from_slot = slot
    game.call("refresh_hud")
    refresh()

func _do_action2() -> void:
    pass

# ---------------------------------------------------------------- styling
func _style_toggle(button: Button, active: bool) -> void:
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0.36, 0.28, 0.15, 1.0) if active else Color(0.1, 0.13, 0.12, 0.95)
    s.border_color = Color(0.95, 0.75, 0.4, 1.0) if active else Color(0.4, 0.48, 0.42, 0.9)
    s.set_border_width_all(3 if active else 2)
    s.set_corner_radius_all(12)
    for state in ["normal", "hover", "pressed", "focus"]:
        button.add_theme_stylebox_override(state, s)

func _button(text: String, min_size: Vector2) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = min_size
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 18)
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
    pressed.border_color = Color(0.92, 0.71, 0.39, 1.0)
    var disabled := normal.duplicate() as StyleBoxFlat
    disabled.bg_color = Color(0.07, 0.08, 0.075, 0.9)
    disabled.border_color = Color(0.25, 0.3, 0.27)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)
    button.add_theme_stylebox_override("disabled", disabled)
    button.add_theme_stylebox_override("focus", normal)
    return button
