extends CanvasLayer
## Character creator: live 3D preview on the left, option rows on the right.
## Emits `confirmed(options)` or `cancelled`. The game is paused while it is open.

signal confirmed(options: Dictionary)
signal cancelled

const HB = preload("res://scripts/human_builder.gd")
const SAVE_PATH := "user://character.json"

var opts: Dictionary = HB.default_options()
var allow_cancel: bool = false
var preview_viewport: SubViewport
var preview_pivot: Node3D
var preview_model: Node3D
var drag_idle: float = 0.0
var rows: Dictionary = {}
var cancel_button: Button

const ROWS := [
    {"key": "gender", "label": "Пол", "kind": "names", "names": HB.GENDER_NAMES},
    {"key": "build", "label": "Телосложение", "kind": "names", "names": HB.BUILD_NAMES},
    {"key": "skin", "label": "Цвет кожи", "kind": "colors", "colors": HB.SKIN},
    {"key": "hair_style", "label": "Причёска", "kind": "names", "names": HB.HAIR_STYLE_NAMES},
    {"key": "hair_color", "label": "Цвет волос", "kind": "colors", "colors": HB.HAIR},
    {"key": "beard", "label": "Борода", "kind": "names", "names": HB.BEARD_NAMES},
    {"key": "glasses", "label": "Очки", "kind": "toggle"},
    {"key": "top", "label": "Одежда сверху", "kind": "names", "names": HB.TOP_NAMES},
    {"key": "top_color", "label": "Цвет верха", "kind": "colors", "colors": HB.CLOTH},
    {"key": "bottom", "label": "Одежда снизу", "kind": "names", "names": HB.BOTTOM_NAMES},
    {"key": "bottom_color", "label": "Цвет низа", "kind": "colors", "colors": HB.PANTS},
    {"key": "shoes_color", "label": "Цвет обуви", "kind": "colors", "colors": HB.SHOES},
]

# ---------------------------------------------------------------- persistence
static func has_saved() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

static func load_saved() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return HB.default_options()
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return HB.default_options()
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        return HB.default_options()
    return HB.sanitize(parsed)

static func save_options(options: Dictionary) -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(HB.sanitize(options)))
        file.close()

## Replaces the player's visible model with one built from `options`.
static func apply_to_player(player: Node, options: Dictionary) -> void:
    var old := player.get_node_or_null("DetailedSurvivor")
    if old:
        player.remove_child(old)
        old.queue_free()
    var built: Dictionary = HB.build(options)
    var model: Node3D = built["model"]
    model.name = "DetailedSurvivor"
    player.add_child(model)
    player.set("animation_model", model)
    var parts: Array[Node3D] = []
    parts.assign(built["limbs"])
    player.set("animation_parts", parts)

# ---------------------------------------------------------------- UI
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 50
    visible = false
    _build_ui()

func open(start_options: Dictionary, cancellable: bool) -> void:
    opts = HB.sanitize(start_options)
    allow_cancel = cancellable
    cancel_button.visible = cancellable
    visible = true
    get_tree().paused = true
    _refresh_all()

func close() -> void:
    visible = false
    get_tree().paused = false

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color(0.05, 0.065, 0.06, 0.97)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var margin := MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 18)
    add_child(margin)
    var split := HBoxContainer.new()
    split.add_theme_constant_override("separation", 18)
    margin.add_child(split)

    # preview
    var left := PanelContainer.new()
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    left.size_flags_stretch_ratio = 0.9
    left.add_theme_stylebox_override("panel", _panel_style(Color(0.15, 0.19, 0.19, 1.0)))
    split.add_child(left)
    var container := SubViewportContainer.new()
    container.stretch = true
    container.mouse_filter = Control.MOUSE_FILTER_STOP
    container.gui_input.connect(_on_preview_input)
    left.add_child(container)
    preview_viewport = SubViewport.new()
    preview_viewport.own_world_3d = true
    preview_viewport.size = Vector2i(560, 640)
    preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    container.add_child(preview_viewport)
    _build_preview_world()

    # options
    var right := VBoxContainer.new()
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.size_flags_stretch_ratio = 1.1
    right.add_theme_constant_override("separation", 10)
    split.add_child(right)
    var title := Label.new()
    title.text = "СОЗДАНИЕ ПЕРСОНАЖА"
    title.add_theme_font_size_override("font_size", 26)
    title.add_theme_color_override("font_color", Color(0.93, 0.86, 0.66))
    right.add_child(title)
    var hint := Label.new()
    hint.text = "Перетащите модель, чтобы повернуть"
    hint.add_theme_font_size_override("font_size", 14)
    hint.add_theme_color_override("font_color", Color(0.6, 0.66, 0.6))
    right.add_child(hint)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    right.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 8)
    scroll.add_child(list)
    for row_def in ROWS:
        _build_row(list, row_def)

    var buttons := HBoxContainer.new()
    buttons.add_theme_constant_override("separation", 10)
    right.add_child(buttons)
    cancel_button = _make_button("Отмена", Vector2(130, 54))
    cancel_button.pressed.connect(func() -> void:
        close()
        cancelled.emit())
    buttons.add_child(cancel_button)
    var random_button := _make_button("Случайный", Vector2(190, 54))
    random_button.pressed.connect(func() -> void:
        opts = HB.random_options()
        _refresh_all())
    buttons.add_child(random_button)
    var done := _make_button("Начать игру", Vector2(200, 54))
    done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    done.pressed.connect(func() -> void:
        var final := HB.sanitize(opts)
        save_options(final)
        close()
        confirmed.emit(final))
    buttons.add_child(done)

func _build_preview_world() -> void:
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.40, 0.46, 0.46)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.78, 0.8, 0.82)
    e.ambient_light_energy = 0.75
    env.environment = e
    preview_viewport.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-38, -150, 0)
    sun.light_energy = 1.15
    preview_viewport.add_child(sun)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-20, 40, 0)
    fill.light_energy = 0.4
    preview_viewport.add_child(fill)
    var floor_mesh := MeshInstance3D.new()
    var disc := CylinderMesh.new()
    disc.top_radius = 0.75
    disc.bottom_radius = 0.8
    disc.height = 0.05
    disc.radial_segments = 8
    floor_mesh.mesh = disc
    floor_mesh.position.y = -0.03
    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = Color(0.24, 0.29, 0.28)
    floor_mat.roughness = 1.0
    floor_mesh.material_override = floor_mat
    preview_viewport.add_child(floor_mesh)
    preview_pivot = Node3D.new()
    preview_viewport.add_child(preview_pivot)
    var cam := Camera3D.new()
    cam.fov = 34
    preview_viewport.add_child(cam)
    cam.position = Vector3(0, 1.05, -3.7)
    cam.look_at(Vector3(0, 0.93, 0))

func _build_row(parent: Container, def: Dictionary) -> void:
    var row := VBoxContainer.new()
    row.add_theme_constant_override("separation", 4)
    parent.add_child(row)
    var key := String(def["key"])
    var head := HBoxContainer.new()
    row.add_child(head)
    var label := Label.new()
    label.text = String(def["label"])
    label.custom_minimum_size = Vector2(190, 0)
    label.add_theme_font_size_override("font_size", 17)
    label.add_theme_color_override("font_color", Color(0.82, 0.87, 0.8))
    head.add_child(label)
    var entry := {"row": row, "def": def}
    match String(def["kind"]):
        "names":
            var prev := _make_button("◀", Vector2(54, 48))
            var value := Label.new()
            value.custom_minimum_size = Vector2(190, 0)
            value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            value.add_theme_font_size_override("font_size", 18)
            var next := _make_button("▶", Vector2(54, 48))
            prev.pressed.connect(_step.bind(key, -1))
            next.pressed.connect(_step.bind(key, 1))
            head.add_child(prev)
            head.add_child(value)
            head.add_child(next)
            entry["value"] = value
        "toggle":
            var toggle := CheckButton.new()
            toggle.focus_mode = Control.FOCUS_NONE
            toggle.custom_minimum_size = Vector2(90, 48)
            toggle.toggled.connect(func(on: bool) -> void:
                opts[key] = on
                _rebuild_preview())
            head.add_child(toggle)
            entry["toggle"] = toggle
        "colors":
            var flow := HFlowContainer.new()
            flow.add_theme_constant_override("h_separation", 8)
            flow.add_theme_constant_override("v_separation", 8)
            flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            row.add_child(flow)
            var swatches: Array = []
            var colors: Array = def["colors"]
            for i in range(colors.size()):
                var swatch := Button.new()
                swatch.custom_minimum_size = Vector2(46, 46)
                swatch.focus_mode = Control.FOCUS_NONE
                swatch.pressed.connect(_pick.bind(key, i))
                flow.add_child(swatch)
                swatches.append(swatch)
            entry["swatches"] = swatches
    rows[key] = entry

func _step(key: String, delta: int) -> void:
    var def: Dictionary = {}
    for r in ROWS:
        if r["key"] == key:
            def = r
    var count: int = (def["names"] as Array).size()
    var current: int = int(opts[key])
    if key == "hair_style" and int(opts["gender"]) == 1:
        # keep women from landing on the bald option by accident
        current = (current + delta - 1 + (count - 1)) % (count - 1) + 1
    else:
        current = (current + delta + count) % count
    opts[key] = current
    _refresh_all()

func _pick(key: String, index: int) -> void:
    opts[key] = index
    _refresh_all()

func _refresh_all() -> void:
    opts = HB.sanitize(opts)
    if int(opts["gender"]) == 1:
        opts["beard"] = 0
    for key in rows:
        var entry: Dictionary = rows[key]
        var def: Dictionary = entry["def"]
        match String(def["kind"]):
            "names":
                var names: Array = def["names"]
                (entry["value"] as Label).text = String(names[int(opts[key])])
            "toggle":
                (entry["toggle"] as CheckButton).set_pressed_no_signal(bool(opts[key]))
            "colors":
                var colors: Array = def["colors"]
                var swatches: Array = entry["swatches"]
                for i in range(swatches.size()):
                    _style_swatch(swatches[i], colors[i], i == int(opts[key]))
    (rows["beard"]["row"] as Control).visible = int(opts["gender"]) == 0
    _rebuild_preview()

func _rebuild_preview() -> void:
    if preview_model and is_instance_valid(preview_model):
        preview_pivot.remove_child(preview_model)
        preview_model.queue_free()
    var built: Dictionary = HB.build(opts)
    preview_model = built["model"]
    preview_pivot.add_child(preview_model)

func _process(delta: float) -> void:
    if not visible or preview_pivot == null:
        return
    drag_idle = maxf(0.0, drag_idle - delta)
    if drag_idle <= 0.0:
        preview_pivot.rotation.y += delta * 0.45

func _on_preview_input(event: InputEvent) -> void:
    if event is InputEventScreenDrag:
        preview_pivot.rotation.y += event.relative.x * 0.012
        drag_idle = 2.0
    elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
        preview_pivot.rotation.y += event.relative.x * 0.012
        drag_idle = 2.0

# ---------------------------------------------------------------- styling
func _panel_style(color: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.set_corner_radius_all(14)
    s.set_border_width_all(2)
    s.border_color = Color(0.3, 0.38, 0.34)
    return s

func _style_swatch(button: Button, color: Color, selected: bool) -> void:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.set_corner_radius_all(10)
    s.set_border_width_all(4 if selected else 2)
    s.border_color = Color(1.0, 0.92, 0.6) if selected else Color(0.0, 0.0, 0.0, 0.55)
    for state in ["normal", "hover", "pressed", "focus"]:
        button.add_theme_stylebox_override(state, s)

func _make_button(text: String, min_size: Vector2) -> Button:
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
