extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const PropScript = preload("res://scripts/destructible.gd")
const InfectedScript = preload("res://scripts/infected.gd")
const JoystickScript = preload("res://scripts/touch_joystick.gd")
const ExpansionScript = preload("res://scripts/expansion.gd")
const VisualUpgradeScript = preload("res://scripts/visual_upgrade.gd")
const SAVE_PATH := "user://afterfall_save.json"

var player
var joystick: Control
var props: Array = []
var loot_drops: Array[Dictionary] = []
var infected: Array = []
var inventory := {"wood": 0, "scrap": 0, "plastic": 0, "cloth": 0, "food": 0, "medicine": 0}
var chest_inventory := {"wood": 0, "scrap": 0, "plastic": 0, "cloth": 0, "food": 0, "medicine": 0}
var camp_chest_position := Vector3(-12.0, 0.0, 10.8)
var chest_panel: PanelContainer
var chest_label: Label
var chest_value_labels: Dictionary = {}
var resource_weights := {"wood": 0.8, "scrap": 1.2, "plastic": 0.25, "cloth": 0.15, "food": 0.35, "medicine": 0.1}
var carry_capacity: float = 35.0
var player_xp: int = 0
var player_level: int = 1
var skill_points: int = 0
var context_label: Label
var inventory_panel: PanelContainer
var inventory_label: Label
var upgrade_info: Label
var upgrade_buttons: Array[Button] = []
var salvaged_ids: Array[String] = []
var hud_label: Label
var message_label: Label
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var message_time: float = 0.0
var camp_position := Vector3(-9, 0, 10)
var expansion
var saved_expansion_state: Dictionary = {}

func _ready() -> void:
    _setup_input()
    _build_world()
    _build_player()
    var visual_upgrade = Node.new()
    visual_upgrade.set_script(VisualUpgradeScript)
    add_child(visual_upgrade)
    visual_upgrade.call("setup", self, player)
    _build_infected()
    visual_upgrade.call("dress_infected", infected)
    _build_ui()
    _load_game()
    expansion = Node.new()
    expansion.set_script(ExpansionScript)
    add_child(expansion)
    expansion.call("setup", self)
    refresh_hud()
    show_message("GREYWOOD — Найди припасы и вернись к лагерю")

func _process(delta: float) -> void:
    message_time = maxf(0.0, message_time - delta)
    if message_time <= 0.0 and message_label:
        message_label.text = ""
    _refresh_context_hint()

func _setup_input() -> void:
    _add_key("move_forward", KEY_W)
    _add_key("move_forward", KEY_UP)
    _add_key("move_back", KEY_S)
    _add_key("move_back", KEY_DOWN)
    _add_key("move_left", KEY_A)
    _add_key("move_left", KEY_LEFT)
    _add_key("move_right", KEY_D)
    _add_key("move_right", KEY_RIGHT)
    _add_key("sprint", KEY_SHIFT)
    _add_key("sneak", KEY_C)
    _add_key("interact", KEY_E)
    _add_key("attack", KEY_SPACE)

func _add_key(action: String, keycode: Key) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    var event := InputEventKey.new()
    event.physical_keycode = keycode
    InputMap.action_add_event(action, event)

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.42, 0.49, 0.46)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.72, 0.77, 0.72)
    environment.ambient_light_energy = 0.7
    env.environment = environment
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -28, 0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    add_child(sun)
    _box(self, "Ground", Vector3(0, -0.35, 0), Vector3(64, 0.6, 64), Color(0.28, 0.34, 0.27), true)
    _box(self, "Main road", Vector3(0, -0.02, 0), Vector3(9, 0.08, 64), Color(0.18, 0.2, 0.19), false)
    _box(self, "Cross road", Vector3(0, 0.025, -5), Vector3(64, 0.08, 7), Color(0.2, 0.22, 0.2), false)
    for i in range(9):
        var z := -28.0 + float(i) * 7.0
        _box(self, "Road marking", Vector3(0, 0.08, z), Vector3(0.18, 0.025, 3.0), Color(0.72, 0.68, 0.52), false)
    _build_house("House A", Vector3(-17, 0, -17), Color(0.54, 0.43, 0.34))
    _build_house("House B", Vector3(17, 0, -17), Color(0.43, 0.49, 0.46))
    _build_house("House C", Vector3(-18, 0, 12), Color(0.55, 0.5, 0.39))
    _build_shop(Vector3(17, 0, 4))
    _build_garage(Vector3(-17, 0, -1))
    _build_gas_station(Vector3(18, 0, 23))
    _build_camp()
    _scatter_trees()
    _make_prop("Wooden crate", "wood", 4, 2, Vector3(-11, 0.55, -12), Vector3(1.0, 1.1, 1.0), Color(0.43, 0.27, 0.15))
    _make_prop("Old cabinet", "wood", 5, 3, Vector3(-14, 0.8, 14), Vector3(1.2, 1.6, 0.6), Color(0.38, 0.28, 0.2))
    _make_prop("Metal barrel", "scrap", 5, 3, Vector3(12, 0.7, 11), Vector3(0.85, 1.4, 0.85), Color(0.32, 0.39, 0.36))
    _make_prop("Plastic bin", "plastic", 3, 2, Vector3(21, 0.55, 7), Vector3(1.0, 1.1, 0.8), Color(0.22, 0.35, 0.36))
    _make_prop("Supply bag", "food", 2, 1, Vector3(-4, 0.45, 19), Vector3(0.9, 0.8, 0.7), Color(0.48, 0.39, 0.25))
    _make_prop("Medical box", "medicine", 2, 1, Vector3(22, 0.4, -13), Vector3(0.8, 0.65, 0.7), Color(0.72, 0.7, 0.6))

func _build_house(label: String, pos: Vector3, wall_color: Color) -> void:
    var root := Node3D.new()
    root.name = label
    root.position = pos
    add_child(root)
    _box(root, "Back wall", Vector3(0, 2, -3.95), Vector3(9, 4, 0.25), wall_color, true)
    _box(root, "Left wall", Vector3(-4.4, 2, 0), Vector3(0.25, 4, 8), wall_color, true)
    _box(root, "Right wall", Vector3(4.4, 2, 0), Vector3(0.25, 4, 8), wall_color, true)
    _box(root, "Front wall left", Vector3(-3.0, 2, 3.95), Vector3(3, 4, 0.25), wall_color, true)
    _box(root, "Front wall right", Vector3(3.0, 2, 3.95), Vector3(3, 4, 0.25), wall_color, true)
    _box(root, "Window left", Vector3(-3.1, 2.1, 4.08), Vector3(1.2, 1.1, 0.12), Color(0.19, 0.28, 0.3), false)
    _box(root, "Window right", Vector3(3.1, 2.1, 4.08), Vector3(1.2, 1.1, 0.12), Color(0.19, 0.28, 0.3), false)

func _build_shop(pos: Vector3) -> void:
    var root := Node3D.new()
    root.position = pos
    root.name = "Greywood Market"
    add_child(root)
    _box(root, "Shop back wall", Vector3(0, 2, -4.4), Vector3(10, 4, 0.25), Color(0.48, 0.47, 0.36), true)
    _box(root, "Shop left wall", Vector3(-4.9, 2, 0), Vector3(0.25, 4, 9), Color(0.48, 0.47, 0.36), true)
    _box(root, "Shop right wall", Vector3(4.9, 2, 0), Vector3(0.25, 4, 9), Color(0.48, 0.47, 0.36), true)
    _box(root, "Shop front left", Vector3(-3.6, 2, 4.4), Vector3(2.8, 4, 0.25), Color(0.48, 0.47, 0.36), true)
    _box(root, "Shop front right", Vector3(3.6, 2, 4.4), Vector3(2.8, 4, 0.25), Color(0.48, 0.47, 0.36), true)
    _box(root, "Sign", Vector3(0, 3.5, 4.62), Vector3(5.2, 0.7, 0.18), Color(0.7, 0.57, 0.34), true)
    _make_prop("Shop shelf", "scrap", 4, 2, pos + Vector3(-2, 0.8, 6), Vector3(1.2, 1.6, 0.5), Color(0.34, 0.32, 0.26))

func _build_garage(pos: Vector3) -> void:
    var root := Node3D.new()
    root.position = pos
    root.name = "Garage"
    add_child(root)
    _box(root, "Garage back wall", Vector3(0, 1.8, -3.9), Vector3(10, 3.6, 0.25), Color(0.42, 0.43, 0.39), true)
    _box(root, "Garage left wall", Vector3(-4.9, 1.8, 0), Vector3(0.25, 3.6, 8), Color(0.42, 0.43, 0.39), true)
    _box(root, "Garage right wall", Vector3(4.9, 1.8, 0), Vector3(0.25, 3.6, 8), Color(0.42, 0.43, 0.39), true)
    _box(root, "Garage front left", Vector3(-3.8, 1.8, 3.9), Vector3(2.4, 3.6, 0.25), Color(0.42, 0.43, 0.39), true)
    _box(root, "Garage front right", Vector3(3.8, 1.8, 3.9), Vector3(2.4, 3.6, 0.25), Color(0.42, 0.43, 0.39), true)
    _make_prop("Tool cabinet", "scrap", 6, 3, pos + Vector3(6, 0.8, 1), Vector3(1.0, 1.6, 0.7), Color(0.34, 0.38, 0.35))

func _build_gas_station(pos: Vector3) -> void:
    var root := Node3D.new()
    root.position = pos
    root.name = "Gas station"
    add_child(root)
    _box(root, "Canopy", Vector3(0, 3.8, 0), Vector3(12, 0.5, 8), Color(0.55, 0.48, 0.34), true)
    for x in [-5.0, 5.0]:
        for z in [-3.0, 3.0]:
            _box(root, "Canopy post", Vector3(x, 1.9, z), Vector3(0.35, 3.8, 0.35), Color(0.35, 0.36, 0.32), true)
    _make_prop("Fuel pump", "scrap", 4, 3, pos + Vector3(0, 0.8, 0), Vector3(0.9, 1.6, 0.8), Color(0.55, 0.27, 0.19))

func _build_camp() -> void:
    _box(self, "Camp tarp", camp_position + Vector3(0, 2.4, 0), Vector3(5.5, 0.25, 4.5), Color(0.32, 0.38, 0.3), false)
    _box(self, "Camp bed", camp_position + Vector3(-1.4, 0.35, 0), Vector3(1.1, 0.35, 2.2), Color(0.37, 0.28, 0.2), false)
    var fire := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.38
    sphere.height = 0.7
    fire.mesh = sphere
    fire.position = camp_position + Vector3(1.1, 0.35, 0.3)
    var chest_root := Node3D.new()
    chest_root.name = "CampStorageChest"
    chest_root.position = camp_chest_position
    add_child(chest_root)
    _box(chest_root, "Storage chest body", Vector3(0, 0.55, 0), Vector3(1.5, 1.1, 1.0), Color(0.31, 0.22, 0.14), true)
    _box(chest_root, "Storage chest lid", Vector3(0, 1.13, 0), Vector3(1.55, 0.12, 1.05), Color(0.40, 0.29, 0.18), true)
    _box(chest_root, "Storage chest lock", Vector3(0, 0.78, -0.53), Vector3(0.22, 0.28, 0.08), Color(0.55, 0.48, 0.29), false)
    var fire_mat := StandardMaterial3D.new()
    fire_mat.albedo_color = Color(1.0, 0.35, 0.08)
    fire_mat.emission_enabled = true
    fire_mat.emission = Color(1.0, 0.16, 0.025)
    fire_mat.emission_energy_multiplier = 1.8
    fire.material_override = fire_mat
    add_child(fire)

func _scatter_trees() -> void:
    var positions := [Vector3(-27,0,-25),Vector3(-27,0,-10),Vector3(-28,0,8),Vector3(-27,0,25),Vector3(28,0,-26),Vector3(28,0,-8),Vector3(28,0,10),Vector3(27,0,27),Vector3(-8,0,-28),Vector3(9,0,-29)]
    for p in positions:
        _box(self, "Tree trunk", p + Vector3(0, 1.1, 0), Vector3(0.7, 2.2, 0.7), Color(0.28, 0.2, 0.14), true)
        var crown := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        sphere.radius = 1.8
        sphere.height = 3.4
        crown.mesh = sphere
        crown.position = p + Vector3(0, 3.2, 0)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.2, 0.31, 0.23)
        mat.roughness = 1.0
        crown.material_override = mat
        add_child(crown)

func _box(parent: Node, label: String, pos: Vector3, dimensions: Vector3, color: Color, solid: bool) -> Node3D:
    if solid:
        var body := StaticBody3D.new()
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = dimensions
        collision.shape = shape
        collision.position = pos
        body.add_child(collision)
        parent.add_child(body)
        body.name = label
        var mesh_node := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = dimensions
        mesh_node.mesh = mesh
        mesh_node.position = pos
        var mat := StandardMaterial3D.new()
        mat.albedo_color = color
        mat.roughness = 0.92
        mesh_node.material_override = mat
        body.add_child(mesh_node)
        return body
    var visual := MeshInstance3D.new()
    var box_mesh := BoxMesh.new()
    box_mesh.size = dimensions
    visual.mesh = box_mesh
    visual.position = pos
    var visual_mat := StandardMaterial3D.new()
    visual_mat.albedo_color = color
    visual_mat.roughness = 0.95
    visual.material_override = visual_mat
    parent.add_child(visual)
    visual.name = label
    return visual

func _make_prop(label: String, resource: String, amount: int, hits: float, pos: Vector3, dimensions: Vector3, color: Color) -> void:
    var body := StaticBody3D.new()
    body.set_script(PropScript)
    body.position = pos
    body.call("setup", label, resource, amount, hits, self)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = dimensions
    collision.shape = shape
    body.add_child(collision)
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    visual.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.9
    visual.material_override = mat
    body.add_child(visual)
    add_child(body)
    props.append(body)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.set_script(PlayerScript)
    player.position = Vector3(-9, 0.2, 13)
    player.main_game = self
    add_child(player)

func _build_infected() -> void:
    for p in [Vector3(5,0.2,-15), Vector3(21,0.2,15), Vector3(-20,0.2,22)]:
        var enemy := CharacterBody3D.new()
        enemy.set_script(InfectedScript)
        enemy.position = p
        add_child(enemy)
        enemy.set("target", player)
        infected.append(enemy)

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(18, 16)
    panel.custom_minimum_size = Vector2(300, 92)
    layer.add_child(panel)
    var vbox := VBoxContainer.new()
    panel.add_child(vbox)
    hud_label = Label.new()
    hud_label.add_theme_font_size_override("font_size", 17)
    vbox.add_child(hud_label)
    health_bar = ProgressBar.new()
    health_bar.custom_minimum_size = Vector2(270, 13)
    health_bar.show_percentage = false
    vbox.add_child(health_bar)
    stamina_bar = ProgressBar.new()
    stamina_bar.custom_minimum_size = Vector2(270, 10)
    stamina_bar.show_percentage = false
    vbox.add_child(stamina_bar)
    message_label = Label.new()
    message_label.position = Vector2(350, 22)
    message_label.size = Vector2(580, 40)
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.add_theme_font_size_override("font_size", 19)
    layer.add_child(message_label)
    context_label = Label.new()
    context_label.anchor_left = 0.5
    context_label.anchor_right = 0.5
    context_label.offset_left = -260
    context_label.offset_right = 260
    context_label.offset_top = 78
    context_label.offset_bottom = 112
    context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    context_label.add_theme_font_size_override("font_size", 17)
    layer.add_child(context_label)
    joystick = Control.new()
    joystick.set_script(JoystickScript)
    joystick.position = Vector2(28, 500)
    joystick.size = Vector2(180, 180)
    joystick.anchor_top = 1.0
    joystick.anchor_bottom = 1.0
    joystick.offset_top = -205
    joystick.offset_bottom = -25
    layer.add_child(joystick)
    joystick.vector_changed.connect(_on_joystick_changed)
    var attack_button := _make_ui_button(layer, "ATTACK", Vector2.ZERO, Vector2(120, 64))
    _place_bottom_right(attack_button, 24.0, 24.0)
    attack_button.pressed.connect(func(): player.call("perform_attack"))
    var action_button := _make_ui_button(layer, "ACTION", Vector2.ZERO, Vector2(120, 64))
    _place_bottom_right(action_button, 24.0, 100.0)
    action_button.pressed.connect(interact)
    var run_button := _make_ui_button(layer, "RUN", Vector2.ZERO, Vector2(120, 64))
    _place_bottom_right(run_button, 160.0, 24.0)
    run_button.button_down.connect(_set_touch_sprint.bind(true))
    run_button.button_up.connect(_set_touch_sprint.bind(false))
    var save_button := _make_ui_button(layer, "SAVE", Vector2.ZERO, Vector2(100, 48))
    _place_bottom_right(save_button, 160.0, 100.0)
    save_button.pressed.connect(save_game)
    var bag_button := _make_ui_button(layer, "BAG", Vector2(18, 118), Vector2(105, 48))
    bag_button.pressed.connect(toggle_inventory)
    _build_inventory_panel(layer)
    _build_chest_panel(layer)

func _make_ui_button(parent: Node, label: String, pos: Vector2, dimensions: Vector2) -> Button:
    var button := Button.new()
    button.text = label
    button.position = pos
    button.size = dimensions
    button.add_theme_font_size_override("font_size", 17)
    parent.add_child(button)
    return button

func _place_bottom_right(button: Control, right_margin: float, bottom_margin: float) -> void:
    button.anchor_left = 1.0
    button.anchor_right = 1.0
    button.anchor_top = 1.0
    button.anchor_bottom = 1.0
    button.offset_left = -(right_margin + button.size.x)
    button.offset_right = -right_margin
    button.offset_top = -(bottom_margin + button.size.y)
    button.offset_bottom = -bottom_margin

func _build_inventory_panel(layer: CanvasLayer) -> void:
    inventory_panel = PanelContainer.new()
    inventory_panel.position = Vector2(18, 174)
    inventory_panel.custom_minimum_size = Vector2(330, 300)
    inventory_panel.visible = false
    layer.add_child(inventory_panel)
    var column := VBoxContainer.new()
    inventory_panel.add_child(column)
    var heading := Label.new()
    heading.text = "РЮКЗАК И РАЗВИТИЕ"
    heading.add_theme_font_size_override("font_size", 19)
    column.add_child(heading)
    inventory_label = Label.new()
    inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(inventory_label)
    upgrade_info = Label.new()
    column.add_child(upgrade_info)
    var stamina_upgrade := _make_ui_button(column, "Выносливость +15", Vector2.ZERO, Vector2.ZERO)
    stamina_upgrade.pressed.connect(_upgrade_stamina)
    upgrade_buttons.append(stamina_upgrade)
    var speed_upgrade := _make_ui_button(column, "Скорость +0.2", Vector2.ZERO, Vector2.ZERO)
    speed_upgrade.pressed.connect(_upgrade_speed)
    upgrade_buttons.append(speed_upgrade)
    var capacity_upgrade := _make_ui_button(column, "Рюкзак +10 кг", Vector2.ZERO, Vector2.ZERO)
    capacity_upgrade.pressed.connect(_upgrade_capacity)
    upgrade_buttons.append(capacity_upgrade)
    var close_button := _make_ui_button(column, "ЗАКРЫТЬ", Vector2.ZERO, Vector2.ZERO)
    close_button.pressed.connect(toggle_inventory)
    _refresh_inventory_ui()

func toggle_inventory() -> void:
    if inventory_panel:
        inventory_panel.visible = not inventory_panel.visible
        _refresh_inventory_ui()

func _refresh_inventory_ui() -> void:
    if not inventory_label or not player:
        return
    var lines := ["Уровень %d  •  XP %d/%d  •  Очки навыков: %d" % [player_level, player_xp, player_level * 100, skill_points]]
    var keys := ["wood", "scrap", "plastic", "cloth", "food", "medicine"]
    var labels := {"wood":"Дерево", "scrap":"Металлолом", "plastic":"Пластик", "cloth":"Ткань", "food":"Еда", "medicine":"Медикаменты"}
    for key in keys:
        lines.append("%s: %d" % [labels[key], int(inventory.get(key, 0))])
    lines.append("Вес: %.1f / %.1f кг" % [_inventory_weight(), carry_capacity])
    lines.append("Инструменты: базовое снаряжение")
    inventory_label.text = "\n".join(lines)
    upgrade_info.text = "Навыки становятся доступны за опыт. Каждые 100 XP — новый уровень."
    for button in upgrade_buttons:
        button.disabled = skill_points <= 0


func _build_chest_panel(layer: CanvasLayer) -> void:
    chest_panel = PanelContainer.new()
    chest_panel.position = Vector2(360, 145)
    chest_panel.custom_minimum_size = Vector2(390, 390)
    chest_panel.visible = false
    layer.add_child(chest_panel)
    var column := VBoxContainer.new()
    chest_panel.add_child(column)
    var title := Label.new()
    title.text = "ЛАГЕРНЫЙ СХРОН"
    title.add_theme_font_size_override("font_size", 20)
    column.add_child(title)
    chest_label = Label.new()
    column.add_child(chest_label)
    var deposit_all := _make_ui_button(column, "СЛОЖИТЬ ВСЁ В СУНДУК", Vector2.ZERO, Vector2.ZERO)
    deposit_all.pressed.connect(_store_all_resources)
    var take_all := _make_ui_button(column, "ЗАБРАТЬ ВСЁ В РЮКЗАК", Vector2.ZERO, Vector2.ZERO)
    take_all.pressed.connect(_take_all_resources)
    var keys := ["wood", "scrap", "plastic", "cloth", "food", "medicine"]
    var labels := {"wood":"Дерево", "scrap":"Металлолом", "plastic":"Пластик", "cloth":"Ткань", "food":"Еда", "medicine":"Медикаменты"}
    for key in keys:
        var row := HBoxContainer.new()
        column.add_child(row)
        var value := Label.new()
        value.custom_minimum_size = Vector2(205, 30)
        value.text = str(labels[key])
        row.add_child(value)
        chest_value_labels[key] = value
        var resource_key := str(key)
        var put := _make_ui_button(row, "→", Vector2.ZERO, Vector2(44, 34))
        put.pressed.connect(_deposit_one.bind(resource_key))
        var take := _make_ui_button(row, "←", Vector2.ZERO, Vector2(44, 34))
        take.pressed.connect(_withdraw_one.bind(resource_key))
    var close := _make_ui_button(column, "ЗАКРЫТЬ", Vector2.ZERO, Vector2.ZERO)
    close.pressed.connect(func(): chest_panel.visible = false)
    _refresh_chest_ui()

func _refresh_chest_ui() -> void:
    if not chest_panel:
        return
    var total := 0
    for key in chest_inventory:
        total += int(chest_inventory[key])
        if chest_value_labels.has(key):
            chest_value_labels[key].text = "%s   Рюкзак %d  |  Сундук %d" % [str(key).capitalize(), int(inventory.get(key, 0)), int(chest_inventory.get(key, 0))]
    if chest_label:
        chest_label.text = "Хранилище: %d единиц. Не занимает вес рюкзака." % total

func _deposit_one(resource: String) -> void:
    if int(inventory.get(resource, 0)) <= 0:
        show_message("В рюкзаке нет этого ресурса.")
        return
    inventory[resource] -= 1
    chest_inventory[resource] = int(chest_inventory.get(resource, 0)) + 1
    _refresh_chest_ui()
    _refresh_inventory_ui()
    refresh_hud()

func _withdraw_one(resource: String) -> void:
    if int(chest_inventory.get(resource, 0)) <= 0:
        show_message("В сундуке нет этого ресурса.")
        return
    var unit_weight := float(resource_weights.get(resource, 0.5))
    if _inventory_weight() + unit_weight > carry_capacity:
        show_message("В рюкзаке нет места.")
        return
    chest_inventory[resource] -= 1
    inventory[resource] = int(inventory.get(resource, 0)) + 1
    _refresh_chest_ui()
    _refresh_inventory_ui()
    refresh_hud()

func _store_all_resources() -> void:
    for key in inventory:
        chest_inventory[key] = int(chest_inventory.get(key, 0)) + int(inventory[key])
        inventory[key] = 0
    _refresh_chest_ui()
    _refresh_inventory_ui()
    refresh_hud()

func _take_all_resources() -> void:
    for key in chest_inventory:
        var unit_weight := float(resource_weights.get(key, 0.5))
        var free_weight := maxf(0.0, carry_capacity - _inventory_weight())
        var can_take := int(floor(free_weight / unit_weight)) if unit_weight > 0.0 else int(chest_inventory[key])
        var amount := mini(int(chest_inventory[key]), can_take)
        if amount > 0:
            inventory[key] = int(inventory.get(key, 0)) + amount
            chest_inventory[key] = int(chest_inventory[key]) - amount
    _refresh_chest_ui()
    _refresh_inventory_ui()
    refresh_hud()
    show_message("В рюкзак помещено всё, для чего хватило места.")

func _inventory_weight() -> float:
    var total := 0.0
    for key in inventory:
        total += float(inventory[key]) * float(resource_weights.get(key, 0.5))
    return total

func _gain_xp(amount: int) -> void:
    player_xp += amount
    while player_xp >= player_level * 100:
        player_xp -= player_level * 100
        player_level += 1
        skill_points += 1
        show_message("Новый уровень: %d. Очко навыка получено!" % player_level)
    _refresh_inventory_ui()

func _spend_skill_point() -> bool:
    if skill_points <= 0:
        show_message("Нет очков навыков.")
        return false
    skill_points -= 1
    return true

func _upgrade_stamina() -> void:
    if _spend_skill_point():
        player.max_stamina += 15.0
        player.stamina = minf(player.max_stamina, player.stamina + 15.0)
        refresh_hud()
        _refresh_inventory_ui()

func _upgrade_speed() -> void:
    if _spend_skill_point():
        player.move_speed += 0.2
        player.sprint_speed += 0.2
        _refresh_inventory_ui()

func _upgrade_capacity() -> void:
    if _spend_skill_point():
        carry_capacity += 10.0
        _refresh_inventory_ui()

func _refresh_context_hint() -> void:
    if not context_label or not player:
        return
    var nearest_enemy: Node = null
    var enemy_distance := 2.6
    for enemy in infected:
        if is_instance_valid(enemy):
            var current_enemy_distance: float = player.global_position.distance_to(enemy.global_position)
            if current_enemy_distance < enemy_distance:
                enemy_distance = current_enemy_distance
                nearest_enemy = enemy
    if nearest_enemy:
        context_label.text = "ATTACK — ударить заражённого"
        return
    var nearest_drop: Dictionary = {}
    var drop_distance := 2.2
    for drop in loot_drops:
        var node: Node3D = drop.get("node")
        if is_instance_valid(node):
            var distance: float = player.global_position.distance_to(node.global_position)
            if distance < drop_distance:
                drop_distance = distance
                nearest_drop = drop
    if not nearest_drop.is_empty():
        context_label.text = "E / ACTION — подобрать: %s ×%d" % [str(nearest_drop.resource).capitalize(), int(nearest_drop.amount)]
        return
    var nearest_prop: Node = null
    var prop_distance := 3.2
    for prop in props:
        if is_instance_valid(prop):
            var distance: float = player.global_position.distance_to(prop.global_position)
            if distance < prop_distance:
                prop_distance = distance
                nearest_prop = prop
    if nearest_prop:
        context_label.text = "E / ACTION — разобрать: %s" % nearest_prop.object_name
    elif player.global_position.distance_to(camp_chest_position) < 2.1:
        context_label.text = "E / ACTION — открыть лагерный сундук"
    elif player.global_position.distance_to(camp_position) < 3.5:
        context_label.text = "E / ACTION — отдохнуть у костра"
    else:
        context_label.text = ""

func spawn_loot(resource: String, amount: int, world_position: Vector3) -> void:
    var drop := Node3D.new()
    drop.position = world_position + Vector3(0, 0.45, 0)
    var orb := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.22
    mesh.height = 0.44
    orb.mesh = mesh
    var mat := StandardMaterial3D.new()
    var colors := {"wood":Color(0.58,0.36,0.17), "scrap":Color(0.62,0.68,0.66), "plastic":Color(0.25,0.65,0.7), "cloth":Color(0.65,0.52,0.35), "food":Color(0.7,0.55,0.22), "medicine":Color(0.8,0.78,0.68)}
    mat.albedo_color = colors.get(resource, Color.WHITE)
    mat.emission_enabled = true
    mat.emission = mat.albedo_color * 0.25
    orb.material_override = mat
    drop.add_child(orb)
    add_child(drop)
    loot_drops.append({"node":drop, "resource":resource, "amount":amount})

func _collect_nearest_drop() -> bool:
    var nearest_index := -1
    var best := 2.2
    for i in range(loot_drops.size()):
        var node: Node3D = loot_drops[i].node
        if is_instance_valid(node):
            var distance: float = player.global_position.distance_to(node.global_position)
            if distance < best:
                best = distance
                nearest_index = i
    if nearest_index < 0:
        return false
    var drop: Dictionary = loot_drops[nearest_index]
    var accepted := add_resource(str(drop.resource), int(drop.amount))
    if accepted:
        var node: Node3D = drop.node
        node.queue_free()
        loot_drops.remove_at(nearest_index)
        _gain_xp(10)
        show_message("Подобрано: %s ×%d" % [str(drop.resource).capitalize(), int(drop.amount)])
    return true

func _set_touch_sprint(active: bool) -> void:
    if player:
        player.touch_sprinting = active

func _on_joystick_changed(value: Vector2) -> void:
    if player:
        player.touch_vector = value

func interact() -> void:
    if not player:
        return
    if expansion and expansion.call("try_interact"):
        return
    if _collect_nearest_drop():
        return
    if player.global_position.distance_to(camp_chest_position) < 2.1:
        if chest_panel:
            chest_panel.visible = not chest_panel.visible
            _refresh_chest_ui()
        return
    if player.global_position.distance_to(camp_position) < 3.5:
        player.health = player.max_health
        player.stamina = player.max_stamina
        _store_all_resources()
        save_game()
        show_message("Ты отдохнул. Ресурсы убраны в лагерный сундук, прогресс сохранён.")
        refresh_hud()
        return
    var nearest: Node = null
    var best := 3.2
    for prop in props:
        if is_instance_valid(prop):
            var d: float = player.global_position.distance_to(prop.global_position)
            if d < best:
                best = d
                nearest = prop
    if nearest:
        nearest.call("damage_object")
    else:
        show_message("Подойди ближе к объекту или лагерю.")

func player_attack() -> void:
    var nearest: Node = null
    var best := 7.0 if player.equipped_weapon == "bow" else (3.2 if player.equipped_weapon == "spear" else 2.6)
    for enemy in infected:
        if is_instance_valid(enemy):
            var d: float = player.global_position.distance_to(enemy.global_position)
            if d < best:
                best = d
                nearest = enemy
    if expansion and expansion.call("try_attack"):
        return
    if nearest:
        var weapon_damage := 8.0
        match player.equipped_weapon:
            "spear": weapon_damage = 28.0
            "bow": weapon_damage = 22.0
            "":
                if player.equipped_tool == "hatchet": weapon_damage = 16.0
                elif player.equipped_tool == "crowbar": weapon_damage = 18.0
        nearest.call("take_hit", weapon_damage)
        show_message("Попадание! Урон: %d" % roundi(weapon_damage))
    else:
        show_message("Никого рядом.")

func add_resource(resource: String, amount: int) -> bool:
    if not inventory.has(resource):
        inventory[resource] = 0
    var unit_weight := float(resource_weights.get(resource, 0.5))
    if _inventory_weight() + unit_weight * amount > carry_capacity:
        show_message("Рюкзак перегружен. Освободи место.")
        return false
    inventory[resource] += amount
    refresh_hud()
    _refresh_inventory_ui()
    return true

func mark_salvaged(prop: Node) -> void:
    _gain_xp(15)
    var key := "%s@%d,%d,%d" % [prop.object_name, roundi(prop.global_position.x), roundi(prop.global_position.y), roundi(prop.global_position.z)]
    if not salvaged_ids.has(key):
        salvaged_ids.append(key)

func refresh_stamina_hud() -> void:
    if not player or not stamina_bar:
        return
    stamina_bar.max_value = player.max_stamina
    stamina_bar.value = player.stamina

func refresh_hud() -> void:
    if not player or not hud_label:
        return
    hud_label.text = "AFTERFALL  |  GREYWOOD\nHP %d   WOOD %d   SCRAP %d   FOOD %d" % [roundi(player.health), inventory.wood, inventory.scrap, inventory.food]
    health_bar.value = player.health
    health_bar.max_value = player.max_health
    stamina_bar.value = player.stamina
    stamina_bar.max_value = player.max_stamina

func show_message(value: String) -> void:
    if message_label:
        message_label.text = value
        message_time = 2.6

func player_died() -> void:
    show_message("Ты погиб. Перезапусти игру, чтобы продолжить.")
    save_game()

func save_game() -> void:
    var saved_loot: Array[Dictionary] = []
    for drop in loot_drops:
        var node: Node3D = drop.get("node")
        if is_instance_valid(node):
            saved_loot.append({"resource": str(drop.get("resource", "scrap")), "amount": int(drop.get("amount", 1)), "position": [node.global_position.x, node.global_position.y, node.global_position.z]})
    var data := {"position": [player.global_position.x, player.global_position.y, player.global_position.z], "health": player.health, "stamina": player.stamina, "inventory": inventory, "chest": chest_inventory, "salvaged": salvaged_ids, "loot": saved_loot, "xp": player_xp, "level": player_level, "skill_points": skill_points, "carry_capacity": carry_capacity, "move_speed": player.move_speed, "sprint_speed": player.sprint_speed, "max_stamina": player.max_stamina, "crafted": expansion.crafted if expansion else {}, "equipped_weapon": player.equipped_weapon, "equipped_tool": player.equipped_tool, "camera_yaw": player.camera_yaw}
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))
        file.close()
        show_message("Игра сохранена.")

func _load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    var saved_position = parsed.get("position", [])
    if saved_position is Array and saved_position.size() == 3:
        player.global_position = Vector3(float(saved_position[0]), float(saved_position[1]), float(saved_position[2]))
    player.max_stamina = maxf(50.0, float(parsed.get("max_stamina", player.max_stamina)))
    player.health = clampf(float(parsed.get("health", player.max_health)), 0.0, player.max_health)
    player.stamina = clampf(float(parsed.get("stamina", player.max_stamina)), 0.0, player.max_stamina)
    var saved_inventory = parsed.get("inventory", {})
    if saved_inventory is Dictionary:
        for key in saved_inventory:
            inventory[key] = int(saved_inventory[key])
    var saved_chest = parsed.get("chest", {})
    if saved_chest is Dictionary:
        for key in saved_chest:
            chest_inventory[key] = int(saved_chest[key])
    var saved_loot = parsed.get("loot", [])
    if saved_loot is Array:
        for saved_drop in saved_loot:
            if saved_drop is Dictionary:
                var saved_pos = saved_drop.get("position", [])
                if saved_pos is Array and saved_pos.size() == 3:
                    spawn_loot(str(saved_drop.get("resource", "scrap")), maxi(1, int(saved_drop.get("amount", 1))), Vector3(float(saved_pos[0]), float(saved_pos[1]), float(saved_pos[2])) - Vector3(0, 0.45, 0))
    player_xp = int(parsed.get("xp", 0))
    player_level = maxi(1, int(parsed.get("level", 1)))
    skill_points = int(parsed.get("skill_points", 0))
    carry_capacity = maxf(10.0, float(parsed.get("carry_capacity", carry_capacity)))
    player.move_speed = maxf(1.0, float(parsed.get("move_speed", player.move_speed)))
    player.sprint_speed = maxf(player.move_speed, float(parsed.get("sprint_speed", player.sprint_speed)))
    player.equipped_weapon = str(parsed.get("equipped_weapon", ""))
    player.equipped_tool = str(parsed.get("equipped_tool", ""))
    player.camera_yaw = float(parsed.get("camera_yaw", 0.0))
    var crafted_state = parsed.get("crafted", {})
    if crafted_state is Dictionary: saved_expansion_state = crafted_state
    var saved_ids = parsed.get("salvaged", [])
    if saved_ids is Array:
        for saved_id in saved_ids:
            salvaged_ids.append(str(saved_id))
    for prop in props.duplicate():
        if is_instance_valid(prop):
            var key := "%s@%d,%d,%d" % [prop.object_name, roundi(prop.global_position.x), roundi(prop.global_position.y), roundi(prop.global_position.z)]
            if salvaged_ids.has(key):
                props.erase(prop)
                prop.queue_free()
    refresh_hud()
    _refresh_inventory_ui()
