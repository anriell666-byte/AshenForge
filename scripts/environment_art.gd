extends RefCounted
## Low-poly environment dressing: trees, bushes, rocks, grass, flowers, campfire and
## house details. Every call adds a handful of mesh nodes (one per object) so it stays
## cheap on mobile; grass and flowers are MultiMesh batches.

const LP = preload("res://scripts/lowpoly.gd")

const PINE_GREENS := [Color(0.12, 0.26, 0.17), Color(0.15, 0.31, 0.19), Color(0.10, 0.22, 0.15), Color(0.18, 0.33, 0.20)]
const LEAF_GREENS := [Color(0.20, 0.35, 0.20), Color(0.26, 0.40, 0.22), Color(0.16, 0.30, 0.18), Color(0.30, 0.40, 0.20)]
const LEAF_AUTUMN := [Color(0.62, 0.38, 0.14), Color(0.55, 0.28, 0.12)]
const BARK := Color(0.27, 0.19, 0.13)
const STONE := [Color(0.34, 0.35, 0.33), Color(0.42, 0.42, 0.38), Color(0.28, 0.30, 0.30)]

# Footprints that must stay clear of grass and trees: [centre x, centre z, half x, half z].
const KEEP_CLEAR := [
    [-17.0, -14.0, 7.0, 8.0], [17.0, -14.0, 7.0, 8.0], [-18.0, 15.0, 7.0, 8.0],
    [17.0, 5.0, 7.5, 8.0], [-17.0, 2.0, 7.5, 8.0], [18.0, 23.0, 9.0, 9.0], [-9.0, 10.0, 5.0, 5.0],
]

static func is_blocked(x: float, z: float, margin: float = 0.0) -> bool:
    if absf(x) < 5.4 + margin:
        return true
    if z > -9.2 - margin and z < -0.8 + margin:
        return true
    for r in KEEP_CLEAR:
        if absf(x - float(r[0])) < float(r[2]) + margin and absf(z - float(r[1])) < float(r[3]) + margin:
            return true
    return false

# ---------------------------------------------------------------- entry points
static func populate(game: Node) -> void:
    var root := Node3D.new()
    root.name = "EnvironmentArt"
    game.add_child(root)
    _forest(root)
    _grass_and_flowers(root)
    for label in ["House A", "House B", "House C"]:
        var house := game.get_node_or_null(NodePath(label)) as Node3D
        if house != null:
            house_details(house, label)
    var shop := game.get_node_or_null(NodePath("Greywood Market")) as Node3D
    if shop != null:
        yard_clutter(shop, 1.0)
    var garage := game.get_node_or_null(NodePath("Garage")) as Node3D
    if garage != null:
        yard_clutter(garage, -1.0)

# ---------------------------------------------------------------- helpers
static func _finish(parent: Node, b: Object, label: String, pos: Vector3, yaw: float = 0.0) -> MeshInstance3D:
    var node: MeshInstance3D = b.to_node(label)
    node.position = pos
    node.rotation.y = yaw
    parent.add_child(node)
    return node

static func _solid_cylinder(parent: Node, pos: Vector3, radius: float, height: float) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    var cs := CollisionShape3D.new()
    var shape := CylinderShape3D.new()
    shape.radius = radius
    shape.height = height
    cs.shape = shape
    cs.position.y = height * 0.5
    body.add_child(cs)
    parent.add_child(body)

static func _rng_for(pos: Vector3, salt: int = 0) -> RandomNumberGenerator:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(absf(pos.x) * 733.0 + absf(pos.z) * 1291.0) + salt * 97 + 11
    return rng

# ---------------------------------------------------------------- vegetation
static func pine(parent: Node, pos: Vector3, s: float = 1.0) -> void:
    var rng := _rng_for(pos, 1)
    var b := LP.new()
    b.frustum(Vector3.ZERO, 1.7 * s, 0.3 * s, 0.3 * s, 0.19 * s, 0.19 * s, 6, BARK)
    var tiers := 4
    for i in range(tiers):
        var r := (1.7 - 0.34 * float(i)) * s
        var col: Color = PINE_GREENS[rng.randi() % PINE_GREENS.size()]
        b.frustum(Vector3(0, (1.1 + 0.95 * float(i)) * s, 0), 1.45 * s, r, r, 0.12 * s, 0.12 * s, 7, col, Vector2.ZERO, rng.randf() * 50.0)
    _finish(parent, b, "Pine", pos, rng.randf() * TAU)
    _solid_cylinder(parent, pos, 0.4 * s, 3.0)

static func oak(parent: Node, pos: Vector3, s: float = 1.0) -> void:
    var rng := _rng_for(pos, 2)
    var b := LP.new()
    b.frustum(Vector3.ZERO, 2.3 * s, 0.34 * s, 0.34 * s, 0.22 * s, 0.22 * s, 7, BARK.lightened(0.05))
    b.limb_between(Vector3(0, 1.7 * s, 0), Vector3(-0.8 * s, 2.7 * s, 0.2 * s), 0.12 * s, 0.07 * s, BARK, 5)
    b.limb_between(Vector3(0, 1.9 * s, 0), Vector3(0.7 * s, 2.8 * s, -0.2 * s), 0.11 * s, 0.07 * s, BARK, 5)
    var autumn := rng.randf() < 0.22
    for i in range(6):
        var a := float(i) * TAU / 6.0 + rng.randf() * 0.5
        var palette: Array = LEAF_AUTUMN if (autumn and i % 2 == 0) else LEAF_GREENS
        var col: Color = palette[rng.randi() % palette.size()]
        var rad := (1.1 + rng.randf() * 0.35) * s
        b.blob(Vector3(cos(a) * 0.85 * s, (2.9 + rng.randf() * 0.7) * s, sin(a) * 0.85 * s), Vector3(rad, rad * 0.82, rad), col, 3, 7)
    b.blob(Vector3(0, 3.7 * s, 0), Vector3(1.25 * s, 1.0 * s, 1.25 * s), LEAF_GREENS[rng.randi() % LEAF_GREENS.size()], 3, 7)
    _finish(parent, b, "Oak", pos, rng.randf() * TAU)
    _solid_cylinder(parent, pos, 0.42 * s, 3.0)

static func dead_tree(parent: Node, pos: Vector3, s: float = 1.0) -> void:
    var rng := _rng_for(pos, 3)
    var b := LP.new()
    var wood := Color(0.30, 0.26, 0.22)
    b.frustum(Vector3.ZERO, 3.4 * s, 0.3 * s, 0.3 * s, 0.1 * s, 0.1 * s, 5, wood)
    for i in range(5):
        var y := (1.2 + float(i) * 0.42) * s
        var a := float(i) * 2.4 + rng.randf()
        var len := (1.0 - float(i) * 0.1) * s
        b.limb_between(Vector3(0, y, 0), Vector3(cos(a) * len, y + 0.7 * s, sin(a) * len), 0.08 * s, 0.025 * s, wood.darkened(0.1), 4)
    _finish(parent, b, "Dead tree", pos, rng.randf() * TAU)
    _solid_cylinder(parent, pos, 0.32 * s, 2.5)

static func bush(parent: Node, pos: Vector3, s: float = 1.0) -> void:
    var rng := _rng_for(pos, 4)
    var b := LP.new()
    for i in range(4):
        var a := float(i) * TAU / 4.0 + rng.randf()
        var col: Color = LEAF_GREENS[rng.randi() % LEAF_GREENS.size()].darkened(0.12)
        var r := (0.46 + rng.randf() * 0.14) * s
        b.blob(Vector3(cos(a) * 0.32 * s, 0.34 * s, sin(a) * 0.32 * s), Vector3(r, r * 0.8, r), col, 2, 6)
    _finish(parent, b, "Bush", pos, rng.randf() * TAU)
    _solid_cylinder(parent, pos, 0.62 * s, 0.8 * s)

static func rock_cluster(parent: Node, origin: Vector3, s: float = 1.0) -> void:
    var rng := _rng_for(origin, 5)
    var b := LP.new()
    for i in range(5):
        var p := Vector3(float(i % 3) * 0.7 - 0.6, 0.0, float(i / 3) * 0.7 - 0.35) * s
        var r := (0.38 + rng.randf() * 0.26) * s
        b.blob(p + Vector3(0, r * 0.45, 0), Vector3(r, r * 0.7, r * (0.8 + rng.randf() * 0.35)), STONE[rng.randi() % STONE.size()], 2, 6)
        var body := StaticBody3D.new()
        body.position = origin + p
        var cs := CollisionShape3D.new()
        var shape := SphereShape3D.new()
        shape.radius = r * 0.85
        cs.shape = shape
        cs.position.y = r * 0.4
        body.add_child(cs)
        parent.add_child(body)
    _finish(parent, b, "Rocks", origin)

static func _forest(root: Node3D) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 4242
    # Edge ring (denser pines), then scattered oaks and dead trees between the buildings.
    var placed: Array[Vector3] = []
    var tries := 0
    while placed.size() < 70 and tries < 900:
        tries += 1
        var edge := rng.randf() < 0.75
        var x := rng.randf_range(-30.5, 30.5)
        var z := rng.randf_range(-30.5, 30.5)
        if edge:
            if absf(x) < 22.0 and absf(z) < 24.0:
                continue
        if is_blocked(x, z, 2.0):
            continue
        var p := Vector3(x, 0, z)
        var too_close := false
        for q in placed:
            if q.distance_to(p) < 3.6:
                too_close = true
                break
        if too_close:
            continue
        placed.append(p)
        var roll := rng.randf()
        var s := rng.randf_range(0.85, 1.35)
        if edge:
            if roll < 0.62:
                pine(root, p, s)
            else:
                oak(root, p, s)
        else:
            if roll < 0.55:
                oak(root, p, s * 0.9)
            elif roll < 0.8:
                dead_tree(root, p, s * 0.9)
            else:
                pine(root, p, s * 0.9)
    for i in range(18):
        var bx := rng.randf_range(-30.0, 30.0)
        var bz := rng.randf_range(-30.0, 30.0)
        if is_blocked(bx, bz, 1.0):
            continue
        bush(root, Vector3(bx, 0, bz), rng.randf_range(0.8, 1.25))

static func _tuft_mesh(rng: RandomNumberGenerator, flowers: bool) -> ArrayMesh:
    var b := LP.new()
    b.jitter = 0.0
    var blades := 5 if not flowers else 3
    for i in range(blades):
        var a := float(i) * TAU / float(blades) + rng.randf() * 0.4
        var h := 0.28 + rng.randf() * 0.26
        var base := Vector3(cos(a) * 0.07, 0, sin(a) * 0.07)
        var lean := Vector2(cos(a) * 0.1, sin(a) * 0.1)
        var green: Color = Color(0.22, 0.36, 0.17).lerp(Color(0.38, 0.46, 0.20), rng.randf())
        b.frustum(base, h, 0.03, 0.012, 0.0, 0.0, 3, green, lean, 0.0, false)
        if flowers and i == 0:
            var heads := [Color(0.9, 0.85, 0.35), Color(0.85, 0.4, 0.5), Color(0.9, 0.9, 0.9), Color(0.6, 0.5, 0.85)]
            b.blob(base + Vector3(lean.x, h + 0.02, lean.y), Vector3(0.055, 0.04, 0.055), heads[rng.randi() % heads.size()], 1, 5)
    return b.build_mesh()

static func _grass_and_flowers(root: Node3D) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 77
    _scatter_multimesh(root, "Grass", _tuft_mesh(rng, false), 1100, rng, 0.0)
    _scatter_multimesh(root, "Flowers", _tuft_mesh(rng, true), 140, rng, 0.0)

static func _scatter_multimesh(root: Node3D, label: String, mesh: Mesh, count: int, rng: RandomNumberGenerator, margin: float) -> void:
    var positions: Array[Vector3] = []
    var attempts := 0
    while positions.size() < count and attempts < count * 6:
        attempts += 1
        var x := rng.randf_range(-31.0, 31.0)
        var z := rng.randf_range(-31.0, 31.0)
        if is_blocked(x, z, margin):
            continue
        positions.append(Vector3(x, 0.0, z))
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = mesh
    mm.instance_count = positions.size()
    for i in range(positions.size()):
        var sc := rng.randf_range(0.8, 1.5)
        var basis := Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(sc, sc, sc))
        mm.set_instance_transform(i, Transform3D(basis, positions[i]))
    var inst := MultiMeshInstance3D.new()
    inst.name = label
    inst.multimesh = mm
    inst.material_override = LP.material()
    inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(inst)

# ---------------------------------------------------------------- campfire
static func campfire(parent: Node, pos: Vector3) -> Node3D:
    var root := Node3D.new()
    root.name = "Campfire"
    root.position = pos
    parent.add_child(root)
    var b := LP.new()
    var g := LP.new()
    var rng := _rng_for(pos, 6)
    for i in range(9):
        var a := float(i) * TAU / 9.0
        b.blob(Vector3(cos(a) * 0.58, 0.1, sin(a) * 0.58), Vector3(0.2, 0.13, 0.17), STONE[i % STONE.size()], 2, 5)
    b.frustum(Vector3(0, 0, 0), 0.05, 0.5, 0.5, 0.46, 0.46, 9, Color(0.1, 0.09, 0.08), Vector2.ZERO, 0.0, true)
    var wood := Color(0.30, 0.20, 0.12)
    for i in range(5):
        var a := float(i) * TAU / 5.0 + 0.3
        b.limb_between(Vector3(cos(a) * 0.5, 0.1, sin(a) * 0.5), Vector3(cos(a) * 0.04, 0.42, sin(a) * 0.04), 0.075, 0.055, wood.lightened(rng.randf() * 0.1), 5)
    for i in range(6):
        var a2 := float(i) * 1.1
        g.box(Vector3(cos(a2) * 0.18, 0.08, sin(a2) * 0.18), Vector3(0.09, 0.05, 0.09), Color(0.9, 0.25, 0.05))
    root.add_child(b.to_node("Fire logs"))
    root.add_child(g.to_node("Embers", LP.glow_material(2.0)))

    var flames := LP.new()
    flames.jitter = 0.0
    flames.spike(Vector3(0, 0.15, 0), 0.82, 0.26, Color(1.0, 0.42, 0.08), 6)
    flames.spike(Vector3(0.07, 0.15, 0.04), 0.58, 0.16, Color(1.0, 0.78, 0.28), 5, Vector2(0.04, 0))
    flames.spike(Vector3(-0.14, 0.15, -0.06), 0.5, 0.13, Color(1.0, 0.32, 0.06), 5, Vector2(-0.05, 0.02))
    flames.spike(Vector3(0.1, 0.15, -0.14), 0.44, 0.11, Color(1.0, 0.5, 0.1), 5, Vector2(0.03, -0.04))
    var flame_node: MeshInstance3D = flames.to_node("Flames", LP.glow_material(2.6))
    flame_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(flame_node)

    var light := OmniLight3D.new()
    light.name = "Firelight"
    light.light_color = Color(1.0, 0.58, 0.28)
    light.light_energy = 1.8
    light.omni_range = 9.5
    light.position = Vector3(0, 1.0, 0)
    root.add_child(light)

    var flicker := root.create_tween().set_loops()
    flicker.tween_property(light, "light_energy", 2.3, 0.12)
    flicker.tween_property(light, "light_energy", 1.5, 0.09)
    flicker.tween_property(light, "light_energy", 2.0, 0.14)
    flicker.tween_property(light, "light_energy", 1.65, 0.1)
    var sway := root.create_tween().set_loops()
    sway.tween_property(flame_node, "scale", Vector3(1.08, 1.18, 1.08), 0.16)
    sway.tween_property(flame_node, "scale", Vector3(0.92, 0.9, 0.92), 0.13)
    sway.tween_property(flame_node, "scale", Vector3(1.02, 1.08, 1.0), 0.15)

    var sparks := CPUParticles3D.new()
    sparks.name = "Sparks"
    sparks.amount = 14
    sparks.lifetime = 1.5
    sparks.position = Vector3(0, 0.55, 0)
    sparks.direction = Vector3.UP
    sparks.spread = 24.0
    sparks.initial_velocity_min = 1.0
    sparks.initial_velocity_max = 2.4
    sparks.gravity = Vector3(0, -0.6, 0)
    sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
    sparks.emission_sphere_radius = 0.18
    var spark_mesh := BoxMesh.new()
    spark_mesh.size = Vector3(0.05, 0.05, 0.05)
    var spark_mat := StandardMaterial3D.new()
    spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    spark_mat.vertex_color_use_as_albedo = true
    spark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    spark_mesh.material = spark_mat
    sparks.mesh = spark_mesh
    var ramp := Gradient.new()
    ramp.set_color(0, Color(1.0, 0.8, 0.3, 1.0))
    ramp.set_color(1, Color(1.0, 0.25, 0.05, 0.0))
    sparks.color_ramp = ramp
    sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(sparks)
    return root

# ---------------------------------------------------------------- buildings
static func house_details(house: Node3D, label: String) -> void:
    var rng := _rng_for(house.position, 7)
    var wood := Color(0.36, 0.26, 0.17)
    var trim := Color(0.22, 0.16, 0.12)
    var paint := Color(0.78, 0.74, 0.64)
    var b := LP.new()
    var g := LP.new()
    # porch deck, planks and steps
    b.box(Vector3(0, 0.06, 5.5), Vector3(4.6, 0.12, 3.2), wood)
    for k in range(8):
        b.box(Vector3(-2.0 + float(k) * 0.57, 0.125, 5.5), Vector3(0.025, 0.012, 3.2), wood.darkened(0.35))
    b.box(Vector3(0, 0.03, 7.35), Vector3(2.2, 0.06, 0.5), wood.darkened(0.08))
    for sx in [-2.0, 2.0]:
        b.frustum(Vector3(sx, 0.12, 6.9), 2.45, 0.09, 0.09, 0.08, 0.08, 6, paint)
    b.box(Vector3(0, 2.62, 6.9), Vector3(4.5, 0.16, 0.2), trim)
    # railings
    for sx in [-2.0, 2.0]:
        b.box(Vector3(sx, 0.62, 5.5), Vector3(0.07, 0.07, 2.9), trim)
        b.box(Vector3(sx, 0.38, 5.5), Vector3(0.05, 0.05, 2.9), trim)
    # shutters and flower boxes at the front windows
    for sx in [-2.8, 2.8]:
        for dx in [-0.8, 0.8]:
            b.box(Vector3(sx + dx, 2.0, 4.13), Vector3(0.32, 1.05, 0.06), trim.lightened(0.12))
        b.box(Vector3(sx, 1.36, 4.3), Vector3(1.1, 0.18, 0.28), wood.darkened(0.15))
        for k in range(4):
            var flower: Color = [Color(0.85, 0.35, 0.4), Color(0.95, 0.8, 0.3), Color(0.8, 0.8, 0.9)][rng.randi() % 3]
            b.blob(Vector3(sx - 0.4 + float(k) * 0.27, 1.5, 4.3), Vector3(0.11, 0.09, 0.11), flower, 1, 5)
    # doormat + lantern with a warm glow
    b.box(Vector3(0, 0.14, 4.55), Vector3(1.2, 0.025, 0.65), Color(0.4, 0.2, 0.15))
    b.box(Vector3(1.05, 2.0, 4.18), Vector3(0.14, 0.22, 0.14), trim)
    g.box(Vector3(1.05, 2.0, 4.25), Vector3(0.09, 0.15, 0.03), Color(1.0, 0.72, 0.3))
    # picket fence with a gap for the path
    var fence := paint.darkened(0.12)
    for side in [-1.0, 1.0]:
        for k in range(11):
            var fx: float = side * (1.5 + float(k) * 0.42)
            if absf(fx) > 6.2:
                continue
            b.box(Vector3(fx, 0.42, 10.0), Vector3(0.14, 0.84, 0.05), fence)
            b.spike(Vector3(fx, 0.84, 10.0), 0.14, 0.07, fence, 4)
        b.box(Vector3(side * 3.9, 0.65, 10.0), Vector3(4.8, 0.07, 0.05), fence.darkened(0.2))
        b.box(Vector3(side * 3.9, 0.3, 10.0), Vector3(4.8, 0.07, 0.05), fence.darkened(0.2))
    # stepping stones along the path
    for k in range(5):
        b.blob(Vector3(rng.randf_range(-0.12, 0.12), 0.02, 8.0 + float(k) * 0.45), Vector3(0.4, 0.04, 0.22), STONE[k % STONE.size()], 1, 6)
    # mailbox by the gate
    b.frustum(Vector3(2.0, 0.0, 10.45), 1.0, 0.04, 0.04, 0.04, 0.04, 4, trim)
    b.box(Vector3(2.0, 1.12, 10.45), Vector3(0.3, 0.22, 0.4), Color(0.25, 0.32, 0.4))
    # corner shrubs
    for sx in [-5.1, 5.1]:
        for k in range(3):
            b.blob(Vector3(sx + rng.randf_range(-0.3, 0.3), 0.32, 4.6 + float(k) * 0.55), Vector3(0.42, 0.34, 0.42), LEAF_GREENS[(k + (1 if sx > 0 else 0)) % LEAF_GREENS.size()].darkened(0.1), 2, 6)
    # chimney: named "Roof ..." so it hides together with the roof for the top-down camera
    var chimney := LP.new()
    chimney.box(Vector3(2.6, 5.4, -2.0), Vector3(0.9, 2.0, 0.9), Color(0.42, 0.36, 0.33))
    chimney.box(Vector3(2.6, 6.5, -2.0), Vector3(1.1, 0.16, 1.1), Color(0.3, 0.28, 0.27))
    var chimney_node: MeshInstance3D = chimney.to_node("Roof chimney")
    house.add_child(chimney_node)
    house.add_child(b.to_node("House details %s" % label))
    house.add_child(g.to_node("Lantern glow", LP.glow_material(2.0)))

static func yard_clutter(building: Node3D, side: float) -> void:
    var rng := _rng_for(building.position, 8)
    var b := LP.new()
    var g := LP.new()
    # crates and barrels near the entrance
    for k in range(3):
        var cx := 5.8 * side + rng.randf_range(-0.4, 0.4)
        var cz := 5.5 + float(k) * 1.2
        b.box(Vector3(cx, 0.4, cz), Vector3(0.8, 0.8, 0.8), Color(0.40, 0.27, 0.15).lightened(rng.randf() * 0.1))
        b.box(Vector3(cx, 0.4, cz), Vector3(0.84, 0.08, 0.84), Color(0.24, 0.16, 0.1))
    for k in range(2):
        var bx := -5.5 * side + rng.randf_range(-0.3, 0.3)
        var bz := 5.2 + float(k) * 1.1
        var col: Color = [Color(0.3, 0.38, 0.4), Color(0.5, 0.22, 0.16)][k]
        b.frustum(Vector3(bx, 0, bz), 1.0, 0.36, 0.36, 0.34, 0.34, 8, col)
        b.frustum(Vector3(bx, 0.45, bz), 0.08, 0.37, 0.37, 0.37, 0.37, 8, col.darkened(0.3))
    # tyre stack
    for k in range(3):
        b.frustum(Vector3(-5.6 * side, float(k) * 0.26, 8.6), 0.26, 0.42, 0.42, 0.42, 0.42, 8, Color(0.09, 0.09, 0.1), Vector2.ZERO, 0.0, true)
    # wall lamp
    b.box(Vector3(0, 3.0, 4.7), Vector3(0.2, 0.2, 0.2), Color(0.2, 0.2, 0.2))
    g.box(Vector3(0, 2.86, 4.7), Vector3(0.14, 0.06, 0.14), Color(1.0, 0.8, 0.45))
    building.add_child(b.to_node("Yard clutter"))
    building.add_child(g.to_node("Lamp glow", LP.glow_material(2.0)))

static func scatter_trees(parent: Node) -> void:
    # Hand-placed hero trees along the map edge, same spots as the original layout.
    var positions := [Vector3(-27, 0, -25), Vector3(-27, 0, -10), Vector3(-28, 0, 8), Vector3(-27, 0, 25), Vector3(28, 0, -26), Vector3(28, 0, -8), Vector3(28, 0, 10), Vector3(27, 0, 27), Vector3(-8, 0, -28), Vector3(9, 0, -29)]
    for i in range(positions.size()):
        if i % 2 == 0:
            pine(parent, positions[i], 1.35)
        else:
            oak(parent, positions[i], 1.25)
