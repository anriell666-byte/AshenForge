extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const PropScript = preload("res://scripts/destructible.gd")
const InfectedScript = preload("res://scripts/infected.gd")
const JoystickScript = preload("res://scripts/touch_joystick.gd")
const ExpansionScript = preload("res://scripts/expansion.gd")
const VisualUpgradeScript = preload("res://scripts/visual_upgrade.gd")
const ProgressScript = preload("res://scripts/progress.gd")
const CraftingScript = preload("res://scripts/crafting_ui.gd")
const QuestsScript = preload("res://scripts/quests.gd")
const WorldScript = preload("res://scripts/world_manager.gd")
const JournalScript = preload("res://scripts/journal_ui.gd")
const ID = preload("res://scripts/items_data.gd")
const LPoly = preload("res://scripts/lowpoly.gd")
const CreatorScript = preload("res://scripts/character_creator.gd")
const EnvArt = preload("res://scripts/environment_art.gd")
const SAVE_PATH := "user://afterfall_save.json"

var player
var joystick: Control
var camera_joystick: Control
var props: Array = []
var loot_drops: Array[Dictionary] = []
var infected: Array = []
var inventory := {"wood": 0, "scrap": 0, "plastic": 0, "cloth": 0, "food": 0, "medicine": 0, "stone": 0, "fuel": 0, "essence": 0, "seal": 0}
var chest_inventory := {"wood": 0, "scrap": 0, "plastic": 0, "cloth": 0, "food": 0, "medicine": 0, "stone": 0, "fuel": 0, "essence": 0, "seal": 0}
var camp_chest_position := Vector3(-12.0, 0.0, 10.8)
var chest_panel: PanelContainer
var chest_label: Label
var chest_value_labels: Dictionary = {}
var resource_weights := {"wood": 0.8, "scrap": 1.2, "plastic": 0.25, "cloth": 0.15, "food": 0.35, "medicine": 0.1, "stone": 1.0, "fuel": 0.6, "essence": 0.1, "seal": 0.1}
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
var character_creator
var progress
var crafting
var quests
var world
var journal
var tracker_label: Label
var hud_canvas: CanvasLayer
var action_button: Button
var attack_held := false
var weapon_button: Button
var heal_button: Button
var tool_button: Button
var workbench_position := Vector3(-4.8, 0.0, 12.8)
var saved_expansion_state: Dictionary = {}

func _ready() -> void:
    _setup_input()
    _build_world()
    _build_player()
    var visual_upgrade = Node.new()
    visual_upgrade.set_script(VisualUpgradeScript)
    add_child(visual_upgrade)
    visual_upgrade.call("setup", self, player)
    _build_ui()
    _load_game()
    _setup_progression()
    _setup_character_creator()
    expansion = Node.new()
    expansion.set_script(ExpansionScript)
    add_child(expansion)
    expansion.call("setup", self)
    _build_workbench()
    _add_progression_ui()
    refresh_hud()
    show_message("Грейвуд — найди припасы, читай записки и возвращайся к лагерю")

func _process(delta: float) -> void:
    message_time = maxf(0.0, message_time - delta)
    if message_time <= 0.0 and message_label:
        message_label.text = ""
    _refresh_context_hint()
    _refresh_tracker()
    if attack_held and player:
        player.call("perform_attack")

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
    _box(self, "Main road", Vector3(0, -0.02, 0), Vector3(9, 0.08, 63.8), Color(0.18, 0.2, 0.19), false)
    _box(self, "Cross road", Vector3(0, 0.025, -5), Vector3(63.8, 0.08, 7), Color(0.2, 0.22, 0.2), false)
    for i in range(9):
        var z := -28.0 + float(i) * 7.0
        if z > -10.5 and z < -0.5:
            continue  # junction: markings would float a hair above the cross road
        _box(self, "Road marking", Vector3(0, 0.05, z), Vector3(0.18, 0.025, 3.0), Color(0.72, 0.68, 0.52), false)
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
    _box(self, "Camp tarp", camp_position + Vector3(-1.1, 2.4, 0), Vector3(3.2, 0.25, 4.5), Color(0.32, 0.38, 0.3), false)
    _box(self, "Camp bed", camp_position + Vector3(-1.4, 0.35, 0), Vector3(1.1, 0.35, 2.2), Color(0.37, 0.28, 0.2), true)
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
    fire.mesh = null  # the visible fire is the low-poly campfire below
    add_child(fire)
    EnvArt.campfire(self, camp_position + Vector3(1.1, 0.0, 0.3))
    var fire_blocker := StaticBody3D.new()
    fire_blocker.position = fire.position
    var fire_collision := CollisionShape3D.new()
    var fire_shape := SphereShape3D.new()
    fire_shape.radius = 0.42
    fire_collision.shape = fire_shape
    fire_blocker.add_child(fire_collision)
    add_child(fire_blocker)

func _scatter_trees() -> void:
    EnvArt.scatter_trees(self)

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
    var salvage_key := "%s@%d,%d,%d" % [label, roundi(pos.x), roundi(pos.y), roundi(pos.z)]
    if salvaged_ids.has(salvage_key):
        return
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

func _setup_progression() -> void:
    progress = Node.new()
    progress.name = "Progress"
    progress.set_script(ProgressScript)
    add_child(progress)
    progress.call("setup", self)
    quests = Node.new()
    quests.name = "Quests"
    quests.set_script(QuestsScript)
    add_child(quests)
    world = Node.new()
    world.name = "World"
    world.set_script(WorldScript)
    add_child(world)
    journal = CanvasLayer.new()
    journal.name = "Journal"
    journal.set_script(JournalScript)
    add_child(journal)
    quests.call("setup", self, progress, world)
    journal.call("setup", self, progress, quests, world)
    world.call("setup", self, progress, quests)
    crafting = CanvasLayer.new()
    crafting.name = "Workbench"
    crafting.set_script(CraftingScript)
    add_child(crafting)
    crafting.call("setup", self, progress)
    progress.changed.connect(_on_progress_changed)

func _build_workbench() -> void:
    var root := Node3D.new()
    root.name = "Workbench model"
    root.position = workbench_position
    add_child(root)
    var b := LPoly.new()
    b.jitter = 0.05
    var wood := Color(0.40, 0.28, 0.17)
    b.box(Vector3(0, 0.95, 0), Vector3(2.4, 0.18, 1.1), wood.lightened(0.06))
    for sx in [-1.0, 1.0]:
        for sz in [-0.4, 0.4]:
            b.box(Vector3(sx, 0.46, sz), Vector3(0.14, 0.92, 0.14), wood.darkened(0.2))
    b.box(Vector3(0, 0.3, 0), Vector3(2.0, 0.08, 0.9), wood.darkened(0.1))
    b.box(Vector3(0, 1.7, -0.5), Vector3(2.4, 1.1, 0.08), Color(0.28, 0.26, 0.24))    # tool board
    for i in range(4):
        b.box(Vector3(-0.8 + float(i) * 0.55, 1.7, -0.44), Vector3(0.08, 0.7, 0.05), Color(0.62, 0.62, 0.58))
    b.frustum(Vector3(0.7, 1.04, 0.1), 0.28, 0.22, 0.12, 0.3, 0.14, 5, Color(0.30, 0.31, 0.34))   # little anvil
    b.box(Vector3(-0.6, 1.1, 0.1), Vector3(0.7, 0.06, 0.4), Color(0.7, 0.66, 0.5))               # blueprint sheet
    root.add_child(b.to_node("Bench"))
    var body := StaticBody3D.new()
    var cs := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.4, 1.2, 1.1)
    cs.shape = shape
    cs.position = Vector3(0, 0.6, 0)
    body.add_child(cs)
    root.add_child(body)

func _add_progression_ui() -> void:
    var layer := hud_canvas
    tracker_label = Label.new()
    tracker_label.position = Vector2(20, 114)
    tracker_label.size = Vector2(330, 50)
    tracker_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    tracker_label.add_theme_font_size_override("font_size", 14)
    tracker_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.62))
    tracker_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    tracker_label.add_theme_constant_override("outline_size", 5)
    layer.add_child(tracker_label)
    var top_buttons := [["⌖\nКАРТА", 1, func() -> void: journal.call("open_journal", "map")],
        ["☰\nЖУРНАЛ", 2, func() -> void: journal.call("open_journal", "quests")],
        ["⚒\nКРАФТ", 3, func() -> void: crafting.call("open")]]
    for entry in top_buttons:
        var b := _make_ui_button(layer, String(entry[0]), Vector2.ZERO, Vector2(76, 62))
        _place_top_right(b, int(entry[1]))
        b.pressed.connect(entry[2])
    weapon_button = _make_ui_button(layer, "⚔\nКулаки", Vector2.ZERO, Vector2(84, 62))
    _place_bottom_right(weapon_button, 372.0, 112.0)
    weapon_button.pressed.connect(func() -> void:
        var id: String = progress.cycle("weapon")
        if id == "":
            show_message("Нет оружия. Создай его на верстаке.")
        else:
            show_message("В руках: %s" % String(ID.item(id)["name"])))
    heal_button = _make_ui_button(layer, "✚\nЛЕЧЕНИЕ", Vector2.ZERO, Vector2(84, 62))
    _place_bottom_right(heal_button, 466.0, 112.0)
    heal_button.pressed.connect(func() -> void: progress.use_best_consumable())
    tool_button = _make_ui_button(layer, "⛏\nИнстр.", Vector2.ZERO, Vector2(84, 62))
    _place_bottom_right(tool_button, 560.0, 30.0)
    tool_button.pressed.connect(func() -> void:
        var id: String = progress.cycle("tool")
        if id == "":
            show_message("Нет инструмента. Создай его на верстаке.")
        else:
            show_message("Инструмент: %s" % String(ID.item(id)["name"])))
    _refresh_progress_buttons()

func _short(text: String) -> String:
    return text if text.length() <= 11 else text.substr(0, 10) + "."

func _refresh_progress_buttons() -> void:
    if not progress or not weapon_button:
        return
    var stats: Dictionary = progress.attack_stats()
    weapon_button.text = "⚔\n" + _short(String(stats["name"]))
    var dur := ""
    if String(stats["id"]) != "" and progress.owned.has(String(stats["id"])):
        dur = " %d%%" % roundi(100.0 * float(progress.owned[String(stats["id"])]["dur"]) / maxf(1.0, progress.max_durability(String(stats["id"]))))
    weapon_button.text += dur
    heal_button.text = "✚\nЛечение %d" % progress.consumable_total()
    tool_button.text = "⛏\n" + (_short(String(ID.item(progress.equipped_tool)["name"])) if progress.equipped_tool != "" else "нет")

var _tracker_cache := ""
func _refresh_tracker() -> void:
    if not tracker_label or not quests:
        return
    var text: String = quests.call("tracker_text")
    if text != _tracker_cache:
        _tracker_cache = text
        tracker_label.text = text

func _on_progress_changed() -> void:
    _refresh_inventory_ui()
    _refresh_progress_buttons()

func _setup_character_creator() -> void:
    character_creator = CanvasLayer.new()
    character_creator.set_script(CreatorScript)
    character_creator.name = "CharacterCreator"
    add_child(character_creator)
    character_creator.confirmed.connect(_on_appearance_confirmed)
    var hud_layer := CanvasLayer.new()
    hud_layer.layer = 5
    add_child(hud_layer)
    var look_button := _make_ui_button(hud_layer, "☺\nВИД", Vector2.ZERO, Vector2(76, 62))
    look_button.anchor_left = 1.0
    look_button.anchor_right = 1.0
    look_button.offset_left = -94.0
    look_button.offset_right = -18.0
    look_button.offset_top = 16.0
    look_button.offset_bottom = 78.0
    look_button.pressed.connect(func() -> void: character_creator.call("open", CreatorScript.load_saved(), true))
    if not CreatorScript.has_saved():
        character_creator.call("open", CreatorScript.load_saved(), false)

func _on_appearance_confirmed(options: Dictionary) -> void:
    CreatorScript.apply_to_player(player, options)

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    hud_canvas = layer
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
    message_label.position = Vector2(330, 22)
    message_label.size = Vector2(440, 56)
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
    joystick.size = Vector2(210, 210)
    joystick.anchor_left = 0.0
    joystick.anchor_right = 0.0
    joystick.anchor_top = 1.0
    joystick.anchor_bottom = 1.0
    joystick.offset_left = 20.0
    joystick.offset_right = 230.0
    joystick.offset_top = -230.0
    joystick.offset_bottom = -20.0
    joystick.active_radius = 76.0
    joystick.display_label = "ДВИЖЕНИЕ"
    layer.add_child(joystick)
    joystick.vector_changed.connect(_on_joystick_changed)

    camera_joystick = Control.new()
    camera_joystick.set_script(JoystickScript)
    camera_joystick.size = Vector2(210, 210)
    camera_joystick.anchor_left = 1.0
    camera_joystick.anchor_right = 1.0
    camera_joystick.anchor_top = 1.0
    camera_joystick.anchor_bottom = 1.0
    camera_joystick.offset_left = -230.0
    camera_joystick.offset_right = -20.0
    camera_joystick.offset_top = -230.0
    camera_joystick.offset_bottom = -20.0
    camera_joystick.active_radius = 76.0
    camera_joystick.display_label = "КАМЕРА"
    layer.add_child(camera_joystick)
    camera_joystick.vector_changed.connect(_on_camera_joystick_changed)

    # Thumb cluster to the left of the camera stick: big attack button with the
    # context action above it, and a row of secondary buttons.
    var attack_button := _make_ui_button(layer, "⚔\nАТАКА", Vector2.ZERO, Vector2(116, 116))
    attack_button.add_theme_font_size_override("font_size", 19)
    _place_bottom_right(attack_button, 246.0, 30.0)
    attack_button.button_down.connect(func() -> void:
        attack_held = true
        player.call("perform_attack"))
    attack_button.button_up.connect(func() -> void: attack_held = false)
    action_button = _make_ui_button(layer, "ДЕЙСТВИЕ", Vector2.ZERO, Vector2(116, 84))
    action_button.add_theme_font_size_override("font_size", 16)
    _place_bottom_right(action_button, 246.0, 156.0)
    action_button.pressed.connect(interact)
    var run_button := _make_ui_button(layer, "⇧\nБЕГ", Vector2.ZERO, Vector2(84, 72))
    _place_bottom_right(run_button, 372.0, 30.0)
    run_button.button_down.connect(_set_touch_sprint.bind(true))
    run_button.button_up.connect(_set_touch_sprint.bind(false))
    var sneak_button := _make_ui_button(layer, "▼\nТИШЕ", Vector2.ZERO, Vector2(84, 72))
    sneak_button.toggle_mode = true
    _place_bottom_right(sneak_button, 466.0, 30.0)
    sneak_button.toggled.connect(func(on: bool) -> void:
        player.set("is_sneaking", on)
        show_message("Крадёшься: враги замечают хуже" if on else "Обычный шаг"))
    var top_extra := [["▤\nРЮКЗАК", 4, toggle_inventory], ["▣\nСЕЙВ", 5, save_game]]
    for entry in top_extra:
        var tb := _make_ui_button(layer, String(entry[0]), Vector2.ZERO, Vector2(76, 62))
        _place_top_right(tb, int(entry[1]))
        tb.pressed.connect(entry[2])
    _build_inventory_panel(layer)
    _build_chest_panel(layer)

func _make_ui_button(parent: Node, label: String, pos: Vector2, dimensions: Vector2) -> Button:
    var button := Button.new()
    button.text = label
    button.position = pos
    button.size = dimensions
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 15 if dimensions.x > 0.0 else 16)
    button.add_theme_color_override("font_color", Color(0.91, 0.94, 0.87))
    button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.94))
    button.add_theme_color_override("font_pressed_color", Color(1.0, 0.86, 0.58))
    button.add_theme_color_override("font_disabled_color", Color(0.55, 0.58, 0.53))
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(0.055, 0.075, 0.07, 0.88)
    normal.border_color = Color(0.48, 0.57, 0.48, 0.9)
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(14)
    normal.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
    normal.shadow_size = 5
    normal.content_margin_left = 5.0
    normal.content_margin_right = 5.0
    normal.content_margin_top = 4.0
    normal.content_margin_bottom = 4.0
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color(0.13, 0.18, 0.15, 0.96)
    hover.border_color = Color(0.77, 0.79, 0.59, 1.0)
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color(0.34, 0.27, 0.16, 0.98)
    pressed.border_color = Color(0.92, 0.71, 0.39, 1.0)
    var disabled := normal.duplicate() as StyleBoxFlat
    disabled.bg_color = Color(0.07, 0.08, 0.075, 0.55)
    disabled.border_color = Color(0.28, 0.31, 0.28, 0.6)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)
    button.add_theme_stylebox_override("focus", normal)
    button.add_theme_stylebox_override("disabled", disabled)
    parent.add_child(button)
    return button

## Slot 0 is the rightmost top button (VIEW); each next slot sits 82 px to its left.
func _place_top_right(button: Control, slot: int) -> void:
    button.anchor_left = 1.0
    button.anchor_right = 1.0
    button.offset_left = -(18.0 + float(slot + 1) * 82.0 - 6.0)
    button.offset_right = button.offset_left + 76.0
    button.offset_top = 16.0
    button.offset_bottom = 78.0

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
    for key in ID.RES_ORDER:
        if int(inventory.get(key, 0)) > 0 or ["wood", "scrap", "plastic", "cloth", "food", "medicine"].has(key):
            lines.append("%s: %d" % [ID.RES_LABELS[key], int(inventory.get(key, 0))])
    lines.append("Вес: %.1f / %.1f кг" % [_inventory_weight(), carry_capacity])
    if progress:
        var stats: Dictionary = progress.attack_stats()
        lines.append("Оружие: %s  •  урон %d" % [String(stats["name"]), roundi(_current_weapon_damage())])
        if progress.equipped_tool != "":
            lines.append("Инструмент: %s" % String(ID.item(progress.equipped_tool)["name"]))
        lines.append("Бинты и аптечки: %d" % progress.consumable_total())
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
    var keys: Array = ID.RES_ORDER
    var labels: Dictionary = ID.RES_LABELS
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
    var labels: Dictionary = ID.RES_LABELS
    for key in chest_inventory:
        total += int(chest_inventory[key])
        if chest_value_labels.has(key):
            chest_value_labels[key].text = "%s   Рюкзак %d  |  Сундук %d" % [str(labels.get(key, key)), int(inventory.get(key, 0)), int(chest_inventory.get(key, 0))]
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
    save_game(false)

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
    save_game(false)

func _store_all_resources() -> void:
    for key in inventory:
        chest_inventory[key] = int(chest_inventory.get(key, 0)) + int(inventory[key])
        inventory[key] = 0
    _refresh_chest_ui()
    _refresh_inventory_ui()
    refresh_hud()
    save_game(false)

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
    save_game(false)
    show_message("В рюкзак помещено всё, для чего хватило места.")

func _current_weapon_damage() -> float:
    var base := 8.0
    if progress:
        base = float(progress.attack_stats()["damage"])
    # +6% per player level keeps later districts beatable without new gear alone.
    return base * (1.0 + 0.06 * float(player_level - 1))

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
        _set_hint("Враг: %s" % String(nearest_enemy.get("display_name")), "ДЕЙСТВИЕ")
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
        _set_hint("Подобрать: %s ×%d" % [String(ID.RES_LABELS.get(str(nearest_drop.resource), str(nearest_drop.resource))), int(nearest_drop.amount)], "ВЗЯТЬ")
        return
    var nearest_prop: Node = _harvest_target(3.2)
    if nearest_prop:
        if nearest_prop.is_in_group("choppable"):
            _set_hint("Дерево: бей АТАКОЙ или кнопкой РУБИТЬ", "РУБИТЬ")
        else:
            _set_hint("Разобрать: %s (АТАКА или РАЗОБРАТЬ)" % nearest_prop.object_name, "РАЗОБРАТЬ")
    elif world and not world.call("nearest_note", player.global_position).is_empty():
        _set_hint("Прочитать: %s" % String(world.call("nearest_note", player.global_position)["data"]["title"]), "ЧИТАТЬ")
    elif player.global_position.distance_to(workbench_position) < 3.0:
        _set_hint("Верстак: создать и починить", "ВЕРСТАК")
    elif player.global_position.distance_to(camp_chest_position) < 2.1:
        _set_hint("Лагерный сундук", "СУНДУК")
    elif player.global_position.distance_to(camp_position) < 3.5:
        _set_hint("Отдохнуть у костра", "ОТДЫХ")
    else:
        _set_hint("", "ДЕЙСТВИЕ")

func _set_hint(text: String, action: String) -> void:
    context_label.text = text
    if action_button:
        action_button.text = action
        action_button.modulate = Color(1, 1, 1, 1.0 if text != "" else 0.55)

func spawn_loot(resource: String, amount: int, world_position: Vector3) -> void:
    var drop := Node3D.new()
    drop.position = world_position + Vector3(0, 0.45, 0)
    var orb := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.22
    mesh.height = 0.44
    orb.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = ID.RES_COLORS.get(resource, Color.WHITE)
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
        show_message("Подобрано: %s ×%d" % [String(ID.RES_LABELS.get(str(drop.resource), str(drop.resource))), int(drop.amount)])
    return true

func _set_touch_sprint(active: bool) -> void:
    if player:
        player.touch_sprinting = active

func _on_joystick_changed(value: Vector2) -> void:
    if player:
        player.touch_vector = value

func _on_camera_joystick_changed(value: Vector2) -> void:
    if player:
        player.camera_touch_vector = value

func interact() -> void:
    if not player:
        return
    if expansion and expansion.call("try_interact"):
        return
    if world and world.call("try_interact"):
        return
    if _collect_nearest_drop():
        return
    if player.global_position.distance_to(workbench_position) < 3.0:
        crafting.call("open")
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
    var target := _harvest_target(3.2)
    if target:
        _harvest_hit(target)
    else:
        show_message("Рядом нечего собирать. Подойди ближе к дереву, камню или предмету.")

## Nearest breakable prop or choppable tree within `max_dist`.
func _harvest_target(max_dist: float) -> Node:
    var nearest: Node = null
    var best := max_dist
    for prop in props:
        if is_instance_valid(prop):
            var d: float = player.global_position.distance_to(prop.global_position)
            if d < best:
                best = d
                nearest = prop
    for tree in get_tree().get_nodes_in_group("choppable"):
        if is_instance_valid(tree):
            var d2: float = player.global_position.distance_to((tree as Node3D).global_position) - 0.6
            if d2 < best:
                best = d2
                nearest = tree
    return nearest

func _harvest_hit(target: Node) -> void:
    if target.is_in_group("choppable"):
        var power: float = float(progress.call("harvest_power", "wood"))
        progress.call("wear_for_harvest")
        var hp: float = float(target.get_meta("hp")) - power
        target.set_meta("hp", hp)
        var vis = target.get_meta("visual")
        if is_instance_valid(vis):
            var tween := (vis as Node3D).create_tween()
            tween.tween_property(vis, "scale", Vector3(1.04, 0.97, 1.04), 0.05)
            tween.tween_property(vis, "scale", Vector3.ONE, 0.08)
        show_message("Дерево: %d/5" % maxi(0, int(ceil(hp))))
        if hp <= 0.0:
            var key := "Tree@%d,%d,%d" % [roundi((target as Node3D).global_position.x), roundi((target as Node3D).global_position.y), roundi((target as Node3D).global_position.z)]
            if not salvaged_ids.has(key):
                salvaged_ids.append(key)
            spawn_loot("wood", 3, (target as Node3D).global_position)
            _gain_xp(10)
            if is_instance_valid(vis):
                vis.queue_free()
            target.queue_free()
    else:
        target.call("damage_object")

func attack_cooldown_value() -> float:
    return float(progress.attack_stats()["cooldown"]) if progress else 0.5

func _facing() -> Vector3:
    return -player.global_transform.basis.z

func player_attack() -> void:
    var stats: Dictionary = progress.attack_stats()
    var damage := _current_weapon_damage()
    var reach := float(stats["reach"])
    var kind := String(stats.get("kind", "melee"))
    var forward := _facing()
    forward.y = 0.0
    forward = forward.normalized()
    var opts := {}
    if stats.has("stun"):
        opts["stun"] = float(stats["stun"])
    if stats.has("burn"):
        opts["burn"] = float(stats["burn"])
    var hits: Array = []
    var origin: Vector3 = player.global_position
    if kind == "cone":
        for enemy in infected:
            if is_instance_valid(enemy) and not enemy.get("dead"):
                var to: Vector3 = enemy.global_position - origin
                to.y = 0.0
                if to.length() < reach and (to.length() < 0.8 or forward.dot(to.normalized()) > 0.72):
                    hits.append(enemy)
        _flame_effect(origin, forward, reach)
    elif kind == "ranged":
        var best_enemy: Node = null
        var best_score := 1e9
        for enemy in infected:
            if is_instance_valid(enemy) and not enemy.get("dead"):
                var to2: Vector3 = enemy.global_position - origin
                to2.y = 0.0
                var d := to2.length()
                if d < reach and d > 0.3:
                    var dot := forward.dot(to2.normalized())
                    # Aim assist: anything in a wide cone in front counts; prefer the most central, then closest.
                    if dot > 0.82:
                        var score := d * (2.0 - dot)
                        if score < best_score:
                            best_score = score
                            best_enemy = enemy
        var end_point: Vector3 = origin + forward * reach
        if best_enemy:
            hits.append(best_enemy)
            end_point = best_enemy.global_position
        _tracer_effect(origin + Vector3(0, 1.1, 0), end_point + Vector3(0, 1.0, 0))
    else:
        var nearest: Node = null
        var best := reach
        for enemy in infected:
            if is_instance_valid(enemy) and not enemy.get("dead"):
                var d2: float = origin.distance_to(enemy.global_position)
                if d2 < best:
                    best = d2
                    nearest = enemy
        if nearest:
            hits.append(nearest)
            var aoe := float(stats.get("aoe", 0.0))
            if aoe > 0.0:
                for enemy in infected:
                    if is_instance_valid(enemy) and enemy != nearest and not enemy.get("dead") and enemy.global_position.distance_to(nearest.global_position) < aoe:
                        hits.append(enemy)
                _ring_effect(nearest.global_position, aoe)
    if hits.is_empty():
        var animal_damage := damage * 0.25
        if expansion and expansion.call("try_attack", animal_damage, maxf(reach, 2.8)):
            progress.wear(String(stats["id"]), 1.0)
            return
        if kind != "ranged":
            var target := _harvest_target(maxf(2.6, minf(reach, 3.4)))
            if target:
                _harvest_hit(target)
                return
        show_message("Мимо." if kind == "ranged" else "Никого рядом.")
        return
    var knock_force := float(stats.get("knockback", 0.0))
    for enemy in hits:
        var hit_opts := opts.duplicate()
        if knock_force > 0.0:
            var away: Vector3 = enemy.global_position - origin
            away.y = 0.0
            hit_opts["knock"] = away.normalized() * knock_force
        var dealt := damage if (enemy == hits[0] or kind == "cone") else damage * 0.6
        enemy.call("take_hit", dealt, hit_opts)
    if kind != "cone":
        show_message("Попадание! Урон: %d%s" % [roundi(damage), " ×%d" % hits.size() if hits.size() > 1 else ""])
    progress.wear(String(stats["id"]), 1.0)
    _refresh_progress_buttons()

func _tracer_effect(from: Vector3, to: Vector3) -> void:
    var line := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    var length := from.distance_to(to)
    mesh.size = Vector3(0.05, 0.05, maxf(0.2, length))
    line.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(1.0, 0.92, 0.6)
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.85, 0.4)
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    line.material_override = mat
    add_child(line)
    line.global_position = (from + to) * 0.5
    if length > 0.01:
        line.look_at(to, Vector3.UP)
    var tween := line.create_tween()
    tween.tween_property(mat, "albedo_color:a", 0.0, 0.18)
    tween.tween_callback(line.queue_free)

func _ring_effect(pos: Vector3, radius: float) -> void:
    var ring := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = 0.05
    mesh.radial_segments = 16
    ring.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.85, 0.8, 0.6, 0.45)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    ring.material_override = mat
    add_child(ring)
    ring.global_position = pos + Vector3(0, 0.08, 0)
    var tween := ring.create_tween()
    tween.tween_property(ring, "scale", Vector3(1.2, 1.0, 1.2), 0.2)
    tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.2)
    tween.tween_callback(ring.queue_free)

func _flame_effect(origin: Vector3, forward: Vector3, reach: float) -> void:
    var fx := CPUParticles3D.new()
    fx.emitting = true
    fx.one_shot = true
    fx.amount = 22
    fx.lifetime = 0.35
    fx.explosiveness = 0.9
    fx.direction = forward
    fx.spread = 18.0
    fx.initial_velocity_min = reach * 1.6
    fx.initial_velocity_max = reach * 2.4
    fx.gravity = Vector3(0, 1.5, 0)
    fx.scale_amount_min = 0.5
    fx.scale_amount_max = 1.1
    var mesh := SphereMesh.new()
    mesh.radius = 0.2
    mesh.height = 0.4
    mesh.radial_segments = 6
    mesh.rings = 3
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(1.0, 0.5, 0.1)
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.4, 0.05)
    mat.emission_energy_multiplier = 2.0
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh.material = mat
    fx.mesh = mesh
    add_child(fx)
    fx.global_position = origin + Vector3(0, 1.0, 0) + forward * 0.6
    var timer := get_tree().create_timer(0.8)
    timer.timeout.connect(fx.queue_free)

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
    var place := String(world.call("district_name", world.current)) if (world and world.current != "") else "Пустошь"
    hud_label.text = "%s  |  ур. %d\nHP %d   WOOD %d   SCRAP %d   FOOD %d" % [place, player_level, roundi(player.health), inventory.wood, inventory.scrap, inventory.food]
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

func save_game(show_feedback: bool = true) -> void:
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
        if show_feedback:
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
    for tree in get_tree().get_nodes_in_group("choppable"):
        var tkey := "Tree@%d,%d,%d" % [roundi((tree as Node3D).global_position.x), roundi((tree as Node3D).global_position.y), roundi((tree as Node3D).global_position.z)]
        if salvaged_ids.has(tkey):
            var tvis = tree.get_meta("visual")
            if is_instance_valid(tvis):
                tvis.queue_free()
            tree.queue_free()
    refresh_hud()
    _refresh_inventory_ui()
    _refresh_chest_ui()
