extends Node
## Open world: lazily builds districts, spawns monsters / mini bosses / bosses, scales danger
## with distance from camp, keeps locked districts behind fences, places readable notes.

const WD = preload("res://scripts/world_data.gd")
const MD = preload("res://scripts/monster_data.gd")
const ID = preload("res://scripts/items_data.gd")
const LP = preload("res://scripts/lowpoly.gd")
const DB = preload("res://scripts/district_builder.gd")
const InfectedScript = preload("res://scripts/infected.gd")

const BUILD_DISTANCE := 32.0      # build a district when the player is this close to it
const ACTIVE_DISTANCE := 38.0     # simulate enemies of a district only inside this range
const RESPAWN_SECONDS := 110.0
const SEAL_BOSSES := ["boss_ripper", "boss_foreman", "boss_fistking"]
const ENTRY_POINTS := {
    "woods": [Vector2(32, -5)], "hospital": [Vector2(0, -32)], "rustworks": [Vector2(0, 32)],
    "quarry": [Vector2(-32, -5)], "forge": [Vector2(0, 32), Vector2(-32, 0)],
}
const FOG := {"woods": [Color(0.50, 0.62, 0.58), 0.010], "forge": [Color(0.40, 0.16, 0.10), 0.010], "rustworks": [Color(0.45, 0.30, 0.22), 0.006]}
const STONES := {
    "greywood": [Vector2(28.0, -14.0), Vector2(28.5, 11.5), Vector2(-27.0, -4.0)],
    "woods": [Vector2(-3, -18), Vector2(22, -20), Vector2(-24, 2)],
    "quarry": [Vector2(-10, -14), Vector2(6, 18), Vector2(-26, 16), Vector2(12, -20)],
}
## Loot containers per district: [label, resource, amount, hits, local x, local z, size, colour]
const LOOT_PROPS := {
    "woods": [
        ["Охотничий ящик", "food", 3, 2, Vector2(-11.5, -12.0), Vector3(1.0, 0.8, 0.7), Color(0.40, 0.30, 0.18)],
        ["Рюкзак путника", "cloth", 3, 1, Vector2(20.0, -9.0), Vector3(0.8, 0.6, 0.6), Color(0.45, 0.38, 0.26)],
        ["Склеп", "scrap", 4, 3, Vector2(17.0, 19.0), Vector3(1.2, 0.9, 1.0), Color(0.40, 0.40, 0.38)],
    ],
    "hospital": [
        ["Шкаф с лекарствами", "medicine", 3, 2, Vector2(-5.0, -11.5), Vector3(1.2, 1.4, 0.6), Color(0.62, 0.70, 0.68)],
        ["Шкаф с лекарствами", "medicine", 3, 2, Vector2(5.0, -11.5), Vector3(1.2, 1.4, 0.6), Color(0.62, 0.70, 0.68)],
        ["Тумба палаты", "medicine", 2, 1, Vector2(-14.0, -7.0), Vector3(0.7, 0.8, 0.6), Color(0.70, 0.74, 0.72)],
        ["Тумба палаты", "cloth", 3, 1, Vector2(14.0, -7.0), Vector3(0.7, 0.8, 0.6), Color(0.70, 0.74, 0.72)],
        ["Тележка с припасами", "plastic", 3, 2, Vector2(-14.0, 4.0), Vector3(1.0, 0.9, 0.7), Color(0.30, 0.52, 0.55)],
        ["Аптечный ящик", "medicine", 3, 1, Vector2(15.0, 4.0), Vector3(0.8, 0.6, 0.6), Color(0.85, 0.85, 0.82)],
    ],
    "rustworks": [
        ["Заводской шкаф", "scrap", 6, 3, Vector2(-8.0, -9.5), Vector3(1.2, 1.6, 0.6), Color(0.34, 0.38, 0.36)],
        ["Бочка с топливом", "fuel", 3, 2, Vector2(12.0, -9.0), Vector3(0.85, 1.3, 0.85), Color(0.72, 0.30, 0.12)],
        ["Бочка с топливом", "fuel", 3, 2, Vector2(-20.0, 20.0), Vector3(0.85, 1.3, 0.85), Color(0.72, 0.30, 0.12)],
        ["Ящик с деталями", "plastic", 3, 2, Vector2(28.0, 8.0), Vector3(1.0, 0.8, 0.8), Color(0.28, 0.45, 0.48)],
        ["Ящик инструментов", "scrap", 5, 2, Vector2(-22.0, -12.0), Vector3(1.0, 0.7, 0.7), Color(0.42, 0.30, 0.18)],
    ],
    "quarry": [
        ["Ящик с динамитом", "scrap", 4, 2, Vector2(-17.0, -14.5), Vector3(0.9, 0.6, 0.7), Color(0.55, 0.20, 0.14)],
        ["Бочка с топливом", "fuel", 3, 2, Vector2(22.0, 8.0), Vector3(0.85, 1.3, 0.85), Color(0.72, 0.30, 0.12)],
        ["Шкаф штейгера", "food", 3, 2, Vector2(-22.5, -20.0), Vector3(1.0, 1.4, 0.6), Color(0.40, 0.30, 0.2)],
    ],
    "forge": [
        ["Ящик с углём", "fuel", 4, 2, Vector2(-8.0, 20.0), Vector3(1.1, 0.8, 0.9), Color(0.16, 0.14, 0.14)],
        ["Обломок брони", "scrap", 6, 3, Vector2(9.0, 12.0), Vector3(1.2, 0.9, 0.9), Color(0.32, 0.30, 0.30)],
        ["Ящик с углём", "fuel", 4, 2, Vector2(-24.0, -8.0), Vector3(1.1, 0.8, 0.9), Color(0.16, 0.14, 0.14)],
    ],
}

var game
var progress
var quests
var built := {}               # id -> {"root", "blocks", "enemies": Array, "notes": Array}
var gates := {}               # id -> Node3D
var notes: Array = []         # {"data", "node", "paper"}
var respawns: Array = []
var current: String = ""
var tick := 0.0
var clock := 0.0
var rng := RandomNumberGenerator.new()
var environment: Environment
var sun: DirectionalLight3D

func setup(owner_game, progress_node, quests_node) -> void:
    game = owner_game
    progress = progress_node
    quests = quests_node
    rng.seed = 90210
    for node in game.get_children():
        if node is WorldEnvironment:
            environment = node.environment
        elif node is DirectionalLight3D:
            sun = node
    _build_outskirts()
    built["greywood"] = {"root": game, "blocks": [], "enemies": [], "notes": []}
    _spawn_district("greywood")
    _spawn_stones("greywood")
    for data in WD.NOTES:
        if _note_district(data["pos"]) == "greywood":
            _place_note(data)
    for id in WD.GATES:
        if not progress.unlocked.has(id):
            _build_gate(id)
    tick = 0.0
    _update_current(true)

# ---------------------------------------------------------------- geometry helpers
func _rect_of(id: String) -> Rect2:
    var c: Vector2 = WD.DISTRICTS[id]["center"]
    return Rect2(c.x - WD.HALF, c.y - WD.HALF, WD.CELL, WD.CELL)

func district_at(pos: Vector3) -> String:
    for id in WD.DISTRICTS:
        if _rect_of(id).has_point(Vector2(pos.x, pos.z)):
            return id
    return ""

func _note_district(pos: Vector3) -> String:
    return district_at(pos)

func district_name(id: String) -> String:
    return String(WD.DISTRICTS.get(id, {}).get("name", "Пустошь"))

func is_locked(id: String) -> bool:
    return bool(WD.DISTRICTS[id].get("locked", false)) and not progress.unlocked.has(id)

## Monsters get stronger the farther they are from the camp.
func power_at(pos: Vector3) -> float:
    var d: float = Vector2(pos.x - game.camp_position.x, pos.z - game.camp_position.z).length()
    return 1.0 + clampf((d - 20.0) / 130.0, 0.0, 1.0) * 0.9

# ---------------------------------------------------------------- map outskirts
func _build_outskirts() -> void:
    var root := Node3D.new()
    root.name = "Outskirts"
    game.add_child(root)
    var cliff := LP.new()
    for c in WD.CLIFF_CELLS:
        var body := StaticBody3D.new()
        var cs := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(WD.CELL, 10.0, WD.CELL)
        cs.shape = shape
        cs.position = Vector3(c.x, 4.0, c.y)
        body.add_child(cs)
        root.add_child(body)
        var r := RandomNumberGenerator.new()
        r.seed = int(c.x * 7 + c.y * 13)
        cliff.box(Vector3(c.x, -0.2, c.y), Vector3(WD.CELL, 0.5, WD.CELL), Color(0.20, 0.24, 0.20))
        for i in range(14):
            var px: float = c.x + r.randf_range(-28.0, 28.0)
            var pz: float = c.y + r.randf_range(-28.0, 28.0)
            var h := r.randf_range(4.0, 11.0)
            var w := r.randf_range(4.0, 9.0)
            cliff.frustum(Vector3(px, 0, pz), h, w, w * 0.8, w * 0.25, w * 0.2, 6, Color(0.30, 0.31, 0.29).lerp(Color(0.40, 0.38, 0.33), r.randf()), Vector2(r.randf_range(-1, 1), r.randf_range(-1, 1)), r.randf() * 60.0)
    root.add_child(cliff.to_node("Cliffs"))
    # Perimeter walls around the playable cells.
    var edges := [
        [Vector3(-96.5, 3.0, 0.0), Vector3(1.0, 6.0, 64.0)],
        [Vector3(96.5, 3.0, -32.0), Vector3(1.0, 6.0, 128.0)],
        [Vector3(32.0, 3.0, -96.5), Vector3(128.0, 6.0, 1.0)],
        [Vector3(0.0, 3.0, 96.5), Vector3(64.0, 6.0, 1.0)],
        [Vector3(96.5, 3.0, 64.0), Vector3(1.0, 6.0, 64.0)],
        [Vector3(-64.0, 3.0, -96.5), Vector3(64.0, 6.0, 1.0)],
    ]
    for e in edges:
        var wall := StaticBody3D.new()
        var wcs := CollisionShape3D.new()
        var wshape := BoxShape3D.new()
        wshape.size = e[1]
        wcs.shape = wshape
        wcs.position = e[0]
        wall.add_child(wcs)
        root.add_child(wall)

# ---------------------------------------------------------------- gates
func _build_gate(id: String) -> void:
    var info: Dictionary = WD.GATES[id]
    var root := Node3D.new()
    root.name = "Gate_" + id
    game.add_child(root)
    var b := LP.new()
    b.jitter = 0.04
    var iron := Color(0.20, 0.19, 0.20)
    for seg in info["segments"]:
        var cx: float = seg[0]
        var cz: float = seg[1]
        var sx: float = seg[2]
        var sz: float = seg[3]
        var along_x: bool = sx > sz
        var length := sx if along_x else sz
        var body := StaticBody3D.new()
        var cs := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(sx, 4.0, sz)
        cs.shape = shape
        cs.position = Vector3(cx, 2.0, cz)
        body.add_child(cs)
        root.add_child(body)
        var n := int(length / 1.1)
        for i in range(n + 1):
            var t := -length * 0.5 + float(i) * (length / float(n))
            var p := Vector3(cx + (t if along_x else 0.0), 0, cz + (0.0 if along_x else t))
            b.frustum(p, 3.2 if i % 4 == 0 else 2.6, 0.12, 0.12, 0.06, 0.06, 5, iron)
        for y in [0.7, 1.6, 2.4]:
            b.box(Vector3(cx, y, cz), Vector3(sx if along_x else 0.16, 0.14, 0.16 if along_x else sz), iron.lightened(0.05))
        # Red banners every so often show that the way is shut.
        for k in range(1, 5):
            var t2 := -length * 0.5 + length * float(k) / 5.0
            var bp := Vector3(cx + (t2 if along_x else 0.0), 1.7, cz + (0.0 if along_x else t2))
            b.box(bp + (Vector3(0, 0, 0.1) if along_x else Vector3(0.1, 0, 0)), Vector3(0.9 if along_x else 0.05, 1.3, 0.05 if along_x else 0.9), Color(0.62, 0.12, 0.10))
    root.add_child(b.to_node("Fence"))
    var label := Label3D.new()
    label.text = "ЗАКРЫТО\n" + String(info["hint"]).replace("\\n", "\n")
    label.font_size = 42
    label.pixel_size = 0.012
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    label.modulate = Color(1.0, 0.82, 0.55)
    label.outline_size = 12
    var sp: Vector3 = info["sign"]
    label.position = Vector3(sp.x, 4.6, sp.z)
    root.add_child(label)
    gates[id] = root

func unlock_district(id: String) -> void:
    progress.unlock_district(id)
    if gates.has(id):
        var gate: Node3D = gates[id]
        gates.erase(id)
        # Colliders go immediately; the fence sinks into the ground.
        for child in gate.get_children():
            if child is StaticBody3D:
                child.queue_free()
            elif child is Label3D:
                child.queue_free()
        var tween := gate.create_tween()
        tween.tween_property(gate, "position:y", -4.0, 1.4)
        tween.tween_callback(gate.queue_free)
    game.show_message("Открыт новый район: %s!" % district_name(id))

# ---------------------------------------------------------------- spawning
func _entry_clear(id: String, local: Vector2, margin: float) -> bool:
    for e in ENTRY_POINTS.get(id, []):
        if (e as Vector2).distance_to(local) < margin:
            return false
    return true

func _random_spot(id: String) -> Vector3:
    var c: Vector2 = WD.DISTRICTS[id]["center"]
    var blocks: Array = built[id]["blocks"]
    for attempt in range(60):
        var local := Vector2(rng.randf_range(-27.0, 27.0), rng.randf_range(-27.0, 27.0))
        if not _entry_clear(id, local, 14.0):
            continue
        var ok := true
        for r in blocks:
            if (r as Rect2).grow(1.5).has_point(local):
                ok = false
                break
        if ok:
            return Vector3(c.x + local.x, 0.2, c.y + local.y)
    return Vector3(c.x, 0.2, c.y)

func _spawn_district(id: String) -> void:
    var info: Dictionary = WD.DISTRICTS[id]
    var c: Vector2 = info["center"]
    var fixed: Array = info.get("fixed_spawns", [])
    var index := 0
    for entry in info["spawns"]:
        for n in range(int(entry[1])):
            var pos: Vector3
            if id == "greywood" and index < fixed.size():
                pos = Vector3(c.x + (fixed[index] as Vector2).x, 0.2, c.y + (fixed[index] as Vector2).y)
            elif id == "greywood":
                pos = _village_spot()
            else:
                pos = _random_spot(id)
            index += 1
            _spawn_enemy(String(entry[0]), pos, id, "")
    var boss: Array = info["boss"]
    if not progress.defeated.has(String(boss[0])):
        _spawn_enemy(String(boss[0]), Vector3(c.x + float(boss[1]), 0.2, c.y + float(boss[2])), id, String(boss[0]))
    var seen := {}
    for m in info["minis"]:
        var mid := String(m[0])
        var key := mid
        if seen.has(mid):
            key = "%s_%d" % [mid, int(seen[mid])]
        seen[mid] = int(seen.get(mid, 0)) + 1
        if not progress.defeated.has(key):
            _spawn_enemy(mid, Vector3(c.x + float(m[1]), 0.2, c.y + float(m[2])), id, key)

func _village_spot() -> Vector3:
    for attempt in range(40):
        var x := rng.randf_range(-29.0, 29.0)
        var z := rng.randf_range(-29.0, 29.0)
        if Vector2(x - game.camp_position.x, z - game.camp_position.z).length() < 16.0:
            continue
        if not preload("res://scripts/environment_art.gd").is_blocked(x, z, 1.5):
            return Vector3(x, 0.2, z)
    return Vector3(0, 0.2, -12)

func _spawn_enemy(monster_id: String, pos: Vector3, district: String, key: String) -> Node:
    var enemy := CharacterBody3D.new()
    enemy.set_script(InfectedScript)
    enemy.set("monster_id", monster_id)
    enemy.set("power", power_at(pos))
    enemy.set("home", pos)
    enemy.set("has_home", true)
    enemy.set("district_id", district)
    enemy.set("spawn_key", key)
    enemy.position = pos
    game.add_child(enemy)
    enemy.set("target", game.player)
    game.infected.append(enemy)
    (built[district]["enemies"] as Array).append(enemy)
    return enemy

func _spawn_stones(id: String) -> void:
    var c: Vector2 = WD.DISTRICTS[id]["center"]
    for local in STONES.get(id, []):
        var pos := Vector3(c.x + (local as Vector2).x, 0.5, c.y + (local as Vector2).y)
        var before: int = game.props.size()
        game._make_prop("Каменная осыпь", "stone", 3, 6.0, pos, Vector3(1.6, 1.0, 1.4), Color(0.45, 0.45, 0.42))
        if game.props.size() > before:
            _dress_stone(game.props.back())

func _dress_stone(prop: Node) -> void:
    for child in prop.get_children():
        if child is MeshInstance3D:
            child.queue_free()
    var b := LP.new()
    var r := RandomNumberGenerator.new()
    r.seed = int(prop.position.x * 31.0 + prop.position.z * 17.0)
    for i in range(5):
        var p := Vector3(r.randf_range(-0.6, 0.6), -0.25, r.randf_range(-0.5, 0.5))
        var s := r.randf_range(0.35, 0.6)
        b.blob(p + Vector3(0, s * 0.6, 0), Vector3(s, s * 0.8, s * 0.9), Color(0.42, 0.42, 0.40).lerp(Color(0.55, 0.52, 0.46), r.randf()), 2, 6)
    b.blob(Vector3(0.1, 0.5, 0), Vector3(0.45, 0.4, 0.4), Color(0.70, 0.56, 0.30), 1, 5)   # ore vein
    prop.add_child(b.to_node("Stone deposit"))

func _spawn_loot_props(id: String) -> void:
    var c: Vector2 = WD.DISTRICTS[id]["center"]
    for e in LOOT_PROPS.get(id, []):
        var pos := Vector3(c.x + (e[4] as Vector2).x, 0.0, c.y + (e[4] as Vector2).y)
        var size: Vector3 = e[5]
        pos.y = size.y * 0.5
        game._make_prop(String(e[0]), String(e[1]), int(e[2]), float(e[3]), pos, size, e[6])

# ---------------------------------------------------------------- notes
func _place_note(data: Dictionary) -> void:
    var node := Node3D.new()
    node.position = data["pos"]
    node.name = "Note_" + String(data["id"])
    game.add_child(node)
    if bool(data.get("desk", false)):
        var desk := LP.new()
        desk.jitter = 0.03
        desk.box(Vector3(0, 0.62, 0), Vector3(1.1, 0.1, 0.65), Color(0.35, 0.24, 0.15))
        for sx in [-0.45, 0.45]:
            for sz in [-0.22, 0.22]:
                desk.box(Vector3(sx, 0.3, sz), Vector3(0.09, 0.6, 0.09), Color(0.24, 0.17, 0.11))
        node.add_child(desk.to_node("Desk"))
    var paper := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.46, 0.03, 0.34)
    paper.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.95, 0.9, 0.7)
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.85, 0.4)
    mat.emission_energy_multiplier = 0.9
    paper.material_override = mat
    paper.position.y = 0.82 if bool(data.get("desk", false)) else 0.4
    paper.rotation.y = 0.4
    node.add_child(paper)
    var read: bool = progress.notes_read.has(String(data["id"]))
    notes.append({"data": data, "node": node, "paper": paper, "mat": mat, "base": paper.position.y})
    if read:
        _mark_read_visual(notes.back())

func _mark_read_visual(entry: Dictionary) -> void:
    var mat: StandardMaterial3D = entry["mat"]
    mat.emission_enabled = false
    mat.albedo_color = Color(0.55, 0.53, 0.46)

func nearest_note(pos: Vector3, radius: float = 2.4) -> Dictionary:
    var best := {}
    var best_d := radius
    for entry in notes:
        var n: Node3D = entry["node"]
        if not is_instance_valid(n):
            continue
        var d := pos.distance_to(n.global_position)
        if d < best_d:
            best_d = d
            best = entry
    return best

## Action button: read the closest note.
func try_interact() -> bool:
    var entry := nearest_note(game.player.global_position)
    if entry.is_empty():
        return false
    var data: Dictionary = entry["data"]
    var first: bool = not progress.notes_read.has(String(data["id"]))
    if first:
        progress.notes_read.append(String(data["id"]))
        progress.mark_dirty()
        _mark_read_visual(entry)
        game._gain_xp(5)
    game.journal.call("show_note", data)
    var qid := String(data.get("quest", ""))
    if qid != "":
        quests.start(qid)
    return true

# ---------------------------------------------------------------- build on approach
func _distance_to_rect(rect: Rect2, p: Vector3) -> float:
    var dx := maxf(maxf(rect.position.x - p.x, 0.0), p.x - rect.end.x)
    var dz := maxf(maxf(rect.position.y - p.z, 0.0), p.z - rect.end.y)
    return Vector2(dx, dz).length()

func _ensure_built(id: String) -> void:
    if built.has(id):
        return
    var info: Dictionary = DB.build(id, game)
    built[id] = {"root": info["root"], "blocks": info["blocks"], "enemies": [], "notes": []}
    _spawn_district(id)
    _spawn_stones(id)
    _spawn_loot_props(id)
    for data in WD.NOTES:
        if _note_district(data["pos"]) == id:
            _place_note(data)

func _process(delta: float) -> void:
    clock += delta
    tick -= delta
    for entry in notes:
        if is_instance_valid(entry["paper"]) and not progress.notes_read.has(String(entry["data"]["id"])):
            (entry["paper"] as Node3D).position.y = float(entry["base"]) + sin(clock * 2.2) * 0.06
            (entry["paper"] as Node3D).rotation.y += delta * 0.8
    if tick > 0.0 or not is_instance_valid(game.player):
        return
    tick = 0.5
    var p: Vector3 = game.player.global_position
    for id in WD.DISTRICTS:
        if not built.has(id) and _distance_to_rect(_rect_of(id), p) < BUILD_DISTANCE:
            _ensure_built(id)
    _update_activity(p)
    _update_current(false)
    _process_respawns(p)
    game.infected = game.infected.filter(func(e): return is_instance_valid(e))

func _update_activity(p: Vector3) -> void:
    for id in built:
        var near: bool = id == "greywood" or _distance_to_rect(_rect_of(id), p) < ACTIVE_DISTANCE
        var root: Node3D = built[id]["root"]
        if id != "greywood" and root.visible != near:
            root.visible = near
        for e in built[id]["enemies"]:
            if not is_instance_valid(e):
                continue
            var close: bool = near and (e as Node3D).global_position.distance_to(p) < 32.0
            var mode := Node.PROCESS_MODE_INHERIT if close else Node.PROCESS_MODE_DISABLED
            if e.process_mode != mode:
                e.process_mode = mode
                (e as Node3D).visible = close

func _update_current(force: bool) -> void:
    var id := district_at(game.player.global_position)
    if id == current and not force:
        return
    current = id
    if id == "":
        return
    game.show_message("Район: %s" % district_name(id))
    game.refresh_hud()
    _apply_mood(id)
    quests.on_visit(id)

func _apply_mood(id: String) -> void:
    var info: Dictionary = WD.DISTRICTS[id]
    var sun_color: Color = info["sun"]
    var sky_color: Color = info["sky"]
    var tween := create_tween().set_parallel(true)
    if sun:
        tween.tween_property(sun, "light_color", sun_color, 1.5)
    if environment:
        tween.tween_property(environment, "background_color", sky_color.lerp(Color(0.42, 0.49, 0.46), 0.55), 1.5)
        tween.tween_property(environment, "ambient_light_color", Color(0.72, 0.77, 0.72).lerp(sun_color, 0.35), 1.5)
        var fog: Array = FOG.get(id, [Color(0.5, 0.55, 0.5), 0.0])
        environment.fog_enabled = float(fog[1]) > 0.0 or environment.fog_density > 0.0005
        environment.fog_light_color = fog[0]
        tween.tween_property(environment, "fog_density", float(fog[1]), 1.5)

# ---------------------------------------------------------------- combat events
func on_monster_killed(enemy: Node) -> void:
    var mid := String(enemy.get("monster_id"))
    var district := String(enemy.get("district_id"))
    var key := String(enemy.get("spawn_key"))
    var pos: Vector3 = enemy.global_position
    var boss: bool = bool(enemy.get("is_boss"))
    var mini: bool = bool(enemy.get("is_mini"))
    if boss or mini:
        progress.record_defeat(key if key != "" else mid)
        var bp: String = progress.grant_blueprint_from(mid)
        if bp != "":
            game.show_message("Найден чертёж: %s" % String(ID.item(bp)["name"]))
        if SEAL_BOSSES.has(mid):
            game.spawn_loot("seal", 1, pos + Vector3(0.0, 0.0, -0.9))
        if boss:
            game.show_message("Босс района «%s» повержен!" % district_name(district))
    else:
        respawns.append({"district": district, "id": mid, "pos": enemy.get("home"), "time": clock + RESPAWN_SECONDS})
    quests.on_kill(mid, district)

func _process_respawns(player_pos: Vector3) -> void:
    var keep: Array = []
    for r in respawns:
        if clock < float(r["time"]):
            keep.append(r)
            continue
        var pos: Vector3 = r["pos"]
        if player_pos.distance_to(pos) < 30.0 or not built.has(r["district"]):
            r["time"] = clock + 20.0
            keep.append(r)
            continue
        _spawn_enemy(String(r["id"]), pos, String(r["district"]), "")
    respawns = keep
