extends CanvasLayer
## Camp storage window: backpack on the left, chest on the right. Tap a stack to move
## it across; the quantity buttons choose how many per tap.

const ID = preload("res://scripts/items_data.gd")
const Cell = preload("res://scripts/item_cell.gd")

const GRID_COLUMNS := 5
const MIN_CELLS := 25

var game
var qty_mode: int = 1     # 1, 5 or 0 (= all)
var bag_grid: GridContainer
var chest_grid: GridContainer
var weight_label: Label
var weight_bar: ProgressBar
var chest_label: Label
var qty_buttons := {}

func setup(owner_game) -> void:
    game = owner_game
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 40
    visible = false
    _build()

func open() -> void:
    visible = true
    get_tree().paused = true
    refresh()

func close() -> void:
    visible = false
    get_tree().paused = false

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

    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 14)
    root.add_child(header)
    var title := Label.new()
    title.text = "СКЛАД У КОСТРА"
    title.add_theme_font_size_override("font_size", 26)
    title.add_theme_color_override("font_color", Color(0.93, 0.86, 0.66))
    header.add_child(title)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(spacer)
    var close_button := _button("✕  Закрыть", Vector2(160, 52))
    close_button.pressed.connect(close)
    header.add_child(close_button)

    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 12)
    root.add_child(body)

    # backpack side
    var bag_panel := _panel()
    bag_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_child(bag_panel)
    var bag_col := VBoxContainer.new()
    bag_col.add_theme_constant_override("separation", 6)
    bag_panel.add_child(bag_col)
    var bag_title := Label.new()
    bag_title.text = "РЮКЗАК"
    bag_title.add_theme_font_size_override("font_size", 20)
    bag_col.add_child(bag_title)
    weight_label = Label.new()
    weight_label.add_theme_font_size_override("font_size", 14)
    weight_label.add_theme_color_override("font_color", Color(0.8, 0.86, 0.78))
    bag_col.add_child(weight_label)
    weight_bar = ProgressBar.new()
    weight_bar.show_percentage = false
    weight_bar.custom_minimum_size = Vector2(0, 12)
    var fill := StyleBoxFlat.new()
    fill.bg_color = Color(0.85, 0.65, 0.25)
    fill.set_corner_radius_all(6)
    var back := StyleBoxFlat.new()
    back.bg_color = Color(0.1, 0.13, 0.12)
    back.set_corner_radius_all(6)
    weight_bar.add_theme_stylebox_override("fill", fill)
    weight_bar.add_theme_stylebox_override("background", back)
    bag_col.add_child(weight_bar)
    bag_grid = _scroll_grid(bag_col)

    # middle controls
    var mid := VBoxContainer.new()
    mid.alignment = BoxContainer.ALIGNMENT_CENTER
    mid.add_theme_constant_override("separation", 8)
    mid.custom_minimum_size = Vector2(112, 0)
    body.add_child(mid)
    var hint := Label.new()
    hint.text = "Сколько\nза раз"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 14)
    hint.add_theme_color_override("font_color", Color(0.7, 0.78, 0.72))
    mid.add_child(hint)
    for entry in [[1, "×1"], [5, "×5"], [0, "Все"]]:
        var b := _button(String(entry[1]), Vector2(100, 54))
        b.pressed.connect(_set_qty.bind(int(entry[0])))
        mid.add_child(b)
        qty_buttons[int(entry[0])] = b
    var put_all := _button("Всё →", Vector2(100, 54))
    put_all.pressed.connect(func() -> void:
        game.call("_store_all_resources")
        refresh())
    mid.add_child(put_all)
    var take_all := _button("← Всё", Vector2(100, 54))
    take_all.pressed.connect(func() -> void:
        game.call("_take_all_resources")
        refresh())
    mid.add_child(take_all)

    # chest side
    var chest_panel := _panel()
    chest_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_child(chest_panel)
    var chest_col := VBoxContainer.new()
    chest_col.add_theme_constant_override("separation", 6)
    chest_panel.add_child(chest_col)
    var chest_title := Label.new()
    chest_title.text = "СКЛАД"
    chest_title.add_theme_font_size_override("font_size", 20)
    chest_col.add_child(chest_title)
    chest_label = Label.new()
    chest_label.add_theme_font_size_override("font_size", 14)
    chest_label.add_theme_color_override("font_color", Color(0.8, 0.86, 0.78))
    chest_col.add_child(chest_label)
    var pad := Control.new()
    pad.custom_minimum_size = Vector2(0, 12)
    chest_col.add_child(pad)
    chest_grid = _scroll_grid(chest_col)

func _scroll_grid(parent: Container) -> GridContainer:
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    parent.add_child(scroll)
    var g := GridContainer.new()
    g.columns = GRID_COLUMNS
    g.add_theme_constant_override("h_separation", 6)
    g.add_theme_constant_override("v_separation", 6)
    scroll.add_child(g)
    return g

func refresh() -> void:
    var cap: float = game.call("max_carry")
    var weight: float = game.call("_inventory_weight")
    weight_label.text = "Вес  %.1f / %.0f кг" % [weight, cap]
    weight_bar.max_value = cap
    weight_bar.value = minf(weight, cap)
    var total := 0
    for key in game.chest_inventory:
        total += int(game.chest_inventory[key])
    chest_label.text = "На складе %d ед.  •  не занимает вес" % total
    for mode in qty_buttons:
        _style_toggle(qty_buttons[mode] as Button, mode == qty_mode)
    _fill(bag_grid, game.inventory, false)
    _fill(chest_grid, game.chest_inventory, true)

func _fill(g: GridContainer, source: Dictionary, in_chest: bool) -> void:
    for child in g.get_children():
        g.remove_child(child)
        child.queue_free()
    var shown := 0
    for key in ID.RES_ORDER:
        var n := int(source.get(key, 0))
        if n <= 0:
            continue
        var cell: Button = Cell.new()
        cell.item_id = key
        cell.count = n
        cell.pressed.connect(_move.bind(key, not in_chest))
        g.add_child(cell)
        shown += 1
    var total := maxi(MIN_CELLS, int(ceil(float(shown) / float(GRID_COLUMNS))) * GRID_COLUMNS)
    for i in range(total - shown):
        g.add_child(Cell.new())

func _set_qty(mode: int) -> void:
    qty_mode = mode
    refresh()

## Moves resources one way: to_chest true = backpack -> chest.
func _move(key: String, to_chest: bool) -> void:
    var from_dict: Dictionary = game.inventory if to_chest else game.chest_inventory
    var to_dict: Dictionary = game.chest_inventory if to_chest else game.inventory
    var have := int(from_dict.get(key, 0))
    var amount := have if qty_mode == 0 else mini(qty_mode, have)
    if not to_chest:
        var unit: float = float(game.resource_weights.get(key, 0.5))
        var free: float = float(game.call("max_carry")) - float(game.call("_inventory_weight"))
        var fits := int(floor(free / maxf(0.01, unit)))
        if fits < amount:
            amount = maxi(0, fits)
            game.call("show_message", "В рюкзаке не хватает места.")
    if amount <= 0:
        return
    from_dict[key] = have - amount
    to_dict[key] = int(to_dict.get(key, 0)) + amount
    game.call("refresh_hud")
    game.call("_refresh_inventory_ui")
    game.call("save_game", false)
    refresh()

func _panel() -> PanelContainer:
    var p := PanelContainer.new()
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0.085, 0.11, 0.105)
    s.set_corner_radius_all(14)
    s.set_border_width_all(2)
    s.border_color = Color(0.27, 0.34, 0.31)
    s.content_margin_left = 10
    s.content_margin_right = 10
    s.content_margin_top = 8
    s.content_margin_bottom = 8
    p.add_theme_stylebox_override("panel", s)
    return p

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
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)
    button.add_theme_stylebox_override("focus", normal)
    return button
