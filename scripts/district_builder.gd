extends RefCounted
## Builds the low-poly scenery of every district. All static decoration of one district is
## merged into a single mesh (plus one emissive mesh), and all collision into one body,
## so a whole district costs only a handful of draw calls.

const LP = preload("res://scripts/lowpoly.gd")
const EnvArt = preload("res://scripts/environment_art.gd")
const WD = preload("res://scripts/world_data.gd")

const WALL_H := 1.8

class Ctx:
    extends RefCounted
    var root: Node3D
    var decor: RefCounted
    var glow: RefCounted
    var body: StaticBody3D
    var blocks: Array[Rect2] = []    # local footprints kept clear of spawns, trees and grass
    var rng: RandomNumberGenerator
    var game: Node
    var center := Vector3.ZERO

# ---------------------------------------------------------------- entry point
static func build(id: String, game: Node) -> Dictionary:
    var info: Dictionary = WD.DISTRICTS[id]
    var c2: Vector2 = info["center"]
    var ctx := Ctx.new()
    ctx.game = game
    ctx.center = Vector3(c2.x, 0.0, c2.y)
    ctx.root = Node3D.new()
    ctx.root.name = "District_" + id
    ctx.root.position = ctx.center
    game.add_child(ctx.root)
    ctx.decor = LP.new()
    ctx.glow = LP.new()
    ctx.glow.jitter = 0.0
    ctx.body = StaticBody3D.new()
    ctx.body.name = "Collision"
    ctx.root.add_child(ctx.body)
    ctx.rng = RandomNumberGenerator.new()
    ctx.rng.seed = hash(id)
    _ground(ctx, info["ground"])
    match id:
        "woods":
            _woods(ctx)
        "hospital":
            _hospital(ctx)
        "rustworks":
            _rustworks(ctx)
        "quarry":
            _quarry(ctx)
        "forge":
            _forge(ctx)
    ctx.root.add_child(ctx.decor.to_node("Scenery"))
    if not ctx.glow.is_empty():
        ctx.root.add_child(ctx.glow.to_node("Glow", LP.glow_material(2.0)))
    return {"root": ctx.root, "blocks": ctx.blocks}

# ---------------------------------------------------------------- primitives
static func _shape_box(ctx: Ctx, pos: Vector3, size: Vector3, yaw_deg: float = 0.0) -> void:
    var cs := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    cs.shape = shape
    cs.position = pos
    cs.rotation.y = deg_to_rad(yaw_deg)
    ctx.body.add_child(cs)

static func _shape_cyl(ctx: Ctx, pos: Vector3, radius: float, height: float) -> void:
    var cs := CollisionShape3D.new()
    var shape := CylinderShape3D.new()
    shape.radius = radius
    shape.height = height
    cs.shape = shape
    cs.position = pos + Vector3(0, height * 0.5, 0)
    ctx.body.add_child(cs)

## Solid coloured block standing on the ground; pos is the footprint centre.
static func block(ctx: Ctx, x: float, z: float, sx: float, h: float, sz: float, col: Color, yaw_deg: float = 0.0, solid: bool = true) -> void:
    ctx.decor.push(Vector3(x, 0, z), Vector3(0, yaw_deg, 0))
    ctx.decor.box(Vector3(0, h * 0.5, 0), Vector3(sx, h, sz), col)
    ctx.decor.pop()
    if solid:
        _shape_box(ctx, Vector3(x, h * 0.5, z), Vector3(sx, h, sz), yaw_deg)

static func _ground(ctx: Ctx, col: Color) -> void:
    var cs := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(WD.CELL, 0.6, WD.CELL)
    cs.shape = shape
    cs.position = Vector3(0, -0.35, 0)
    ctx.body.add_child(cs)
    var tile := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(WD.CELL, 0.06, WD.CELL)
    tile.mesh = mesh
    tile.position = Vector3(0, -0.02, 0)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = col
    mat.roughness = 0.95
    tile.material_override = mat
    tile.name = "GroundTile"
    ctx.root.add_child(tile)

static func road(ctx: Ctx, x: float, z: float, sx: float, sz: float, col: Color = Color(0.18, 0.2, 0.19)) -> void:
    var m := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(sx, 0.08, sz)
    m.mesh = mesh
    m.position = Vector3(x, -0.02, z)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = col
    mat.roughness = 0.95
    m.material_override = mat
    m.name = "Road"
    ctx.root.add_child(m)

## Walled room without a roof. door: 'n' 's' 'e' 'w' or '' for none. Records the footprint.
static func building(ctx: Ctx, cx: float, cz: float, w: float, d: float, col: Color, floor_col: Color, door: String = "s", door_w: float = 2.6, h: float = WALL_H) -> void:
    var t := 0.3
    ctx.decor.box(Vector3(cx, 0.03, cz), Vector3(w, 0.06, d), floor_col)
    var hw := w * 0.5
    var hd := d * 0.5
    _wall_x(ctx, cx, cz - hd, w, t, h, col, door_w if door == "n" else 0.0)
    _wall_x(ctx, cx, cz + hd, w, t, h, col, door_w if door == "s" else 0.0)
    _wall_z(ctx, cx - hw, cz, d, t, h, col, door_w if door == "w" else 0.0)
    _wall_z(ctx, cx + hw, cz, d, t, h, col, door_w if door == "e" else 0.0)
    ctx.blocks.append(Rect2(cx - hw - 1.0, cz - hd - 1.0, w + 2.0, d + 2.0))

static func _wall_x(ctx: Ctx, cx: float, z: float, w: float, t: float, h: float, col: Color, gap: float) -> void:
    if gap <= 0.0:
        block(ctx, cx, z, w, h, t, col)
        return
    var seg := (w - gap) * 0.5
    block(ctx, cx - (gap + seg) * 0.5, z, seg, h, t, col)
    block(ctx, cx + (gap + seg) * 0.5, z, seg, h, t, col)
    ctx.decor.box(Vector3(cx, h - 0.2, z), Vector3(gap, 0.4, t), col.darkened(0.15))

static func _wall_z(ctx: Ctx, x: float, cz: float, d: float, t: float, h: float, col: Color, gap: float) -> void:
    if gap <= 0.0:
        block(ctx, x, cz, t, h, d, col)
        return
    var seg := (d - gap) * 0.5
    block(ctx, x, cz - (gap + seg) * 0.5, t, h, seg, col)
    block(ctx, x, cz + (gap + seg) * 0.5, t, h, seg, col)
    ctx.decor.box(Vector3(x, h - 0.2, cz), Vector3(t, 0.4, gap), col.darkened(0.15))

# ---------------------------------------------------------------- vegetation / props
static func pine(ctx: Ctx, x: float, z: float, s: float) -> void:
    ctx.decor.push(Vector3(x, 0, z), Vector3(0, ctx.rng.randf() * 360.0, 0))
    ctx.decor.frustum(Vector3.ZERO, 1.7 * s, 0.3 * s, 0.3 * s, 0.19 * s, 0.19 * s, 6, EnvArt.BARK)
    for i in range(4):
        var r := (1.7 - 0.34 * float(i)) * s
        var col: Color = EnvArt.PINE_GREENS[ctx.rng.randi() % EnvArt.PINE_GREENS.size()]
        ctx.decor.frustum(Vector3(0, (1.1 + 0.95 * float(i)) * s, 0), 1.45 * s, r, r, 0.12 * s, 0.12 * s, 7, col, Vector2.ZERO, ctx.rng.randf() * 50.0)
    ctx.decor.pop()
    _shape_cyl(ctx, Vector3(x, 0, z), 0.4 * s, 3.0)

static func oak(ctx: Ctx, x: float, z: float, s: float) -> void:
    ctx.decor.push(Vector3(x, 0, z), Vector3(0, ctx.rng.randf() * 360.0, 0))
    ctx.decor.frustum(Vector3.ZERO, 2.3 * s, 0.34 * s, 0.34 * s, 0.22 * s, 0.22 * s, 7, EnvArt.BARK.lightened(0.05))
    for i in range(5):
        var a := float(i) * TAU / 5.0 + ctx.rng.randf() * 0.5
        var col: Color = Color(0.17, 0.30, 0.19).lerp(Color(0.26, 0.38, 0.22), ctx.rng.randf())
        var rad := (1.05 + ctx.rng.randf() * 0.3) * s
        ctx.decor.blob(Vector3(cos(a) * 0.8 * s, (2.9 + ctx.rng.randf() * 0.6) * s, sin(a) * 0.8 * s), Vector3(rad, rad * 0.8, rad), col, 2, 6)
    ctx.decor.blob(Vector3(0, 3.6 * s, 0), Vector3(1.2 * s, 0.95 * s, 1.2 * s), Color(0.20, 0.34, 0.20), 2, 7)
    ctx.decor.pop()
    _shape_cyl(ctx, Vector3(x, 0, z), 0.42 * s, 3.0)

static func dead_tree(ctx: Ctx, x: float, z: float, s: float, wood: Color = Color(0.30, 0.26, 0.22)) -> void:
    ctx.decor.push(Vector3(x, 0, z), Vector3(0, ctx.rng.randf() * 360.0, 0))
    ctx.decor.frustum(Vector3.ZERO, 3.4 * s, 0.3 * s, 0.3 * s, 0.1 * s, 0.1 * s, 5, wood)
    for i in range(5):
        var y := (1.2 + float(i) * 0.42) * s
        var a := float(i) * 2.4 + ctx.rng.randf()
        var ln := (1.0 - float(i) * 0.1) * s
        ctx.decor.limb_between(Vector3(0, y, 0), Vector3(cos(a) * ln, y + 0.7 * s, sin(a) * ln), 0.08 * s, 0.025 * s, wood.darkened(0.1), 4)
    ctx.decor.pop()
    _shape_cyl(ctx, Vector3(x, 0, z), 0.32 * s, 2.5)

static func rocks(ctx: Ctx, x: float, z: float, s: float, solid: bool = true, tint: float = 0.0) -> void:
    ctx.decor.push(Vector3(x, 0, z), Vector3(0, ctx.rng.randf() * 360.0, 0))
    for i in range(4):
        var p := Vector3(float(i % 2) * 0.9 - 0.45, 0.0, float(i / 2) * 0.8 - 0.4) * s
        var r := (0.55 + ctx.rng.randf() * 0.35) * s
        var col: Color = EnvArt.STONE[ctx.rng.randi() % EnvArt.STONE.size()].lightened(tint)
        ctx.decor.blob(p + Vector3(0, r * 0.4, 0), Vector3(r, r * 0.7, r * 0.9), col, 2, 6)
    ctx.decor.pop()
    if solid:
        _shape_cyl(ctx, Vector3(x, 0, z), 1.0 * s, 1.0)

static func container(ctx: Ctx, x: float, z: float, yaw: float, col: Color) -> void:
    block(ctx, x, z, 6.0, 2.5, 2.4, col, yaw)
    ctx.decor.push(Vector3(x, 0, z), Vector3(0, yaw, 0))
    for i in range(-2, 3):
        ctx.decor.box(Vector3(float(i) * 1.1, 1.25, 1.22), Vector3(0.14, 2.3, 0.05), col.darkened(0.25))
        ctx.decor.box(Vector3(float(i) * 1.1, 1.25, -1.22), Vector3(0.14, 2.3, 0.05), col.darkened(0.25))
    ctx.decor.pop()
    ctx.blocks.append(Rect2(x - 3.4, z - 3.4, 6.8, 6.8) if int(roundf(yaw)) % 180 != 0 else Rect2(x - 3.4, z - 1.8, 6.8, 3.6))

static func barrel(ctx: Ctx, x: float, z: float, col: Color) -> void:
    ctx.decor.frustum(Vector3(x, 0, z), 0.95, 0.38, 0.38, 0.36, 0.36, 7, col)
    ctx.decor.frustum(Vector3(x, 0.45, z), 0.08, 0.40, 0.40, 0.40, 0.40, 7, col.darkened(0.3))
    _shape_cyl(ctx, Vector3(x, 0, z), 0.4, 0.95)

static func chimney(ctx: Ctx, x: float, z: float, h: float, col: Color, glowing: bool = false) -> void:
    ctx.decor.frustum(Vector3(x, 0, z), h, 1.7, 1.7, 1.1, 1.1, 8, col)
    ctx.decor.frustum(Vector3(x, h, z), 0.5, 1.3, 1.3, 1.3, 1.3, 8, col.darkened(0.2), Vector2.ZERO, 0.0, false)
    _shape_cyl(ctx, Vector3(x, 0, z), 1.7, h)
    if glowing:
        ctx.glow.frustum(Vector3(x, h - 0.1, z), 0.25, 1.0, 1.0, 1.0, 1.0, 8, Color(1.0, 0.4, 0.08))

static func lamp(ctx: Ctx, x: float, z: float, col: Color = Color(1.0, 0.82, 0.45)) -> void:
    ctx.decor.frustum(Vector3(x, 0, z), 2.8, 0.1, 0.1, 0.07, 0.07, 5, Color(0.2, 0.2, 0.22))
    ctx.glow.blob(Vector3(x, 2.95, z), Vector3(0.22, 0.16, 0.22), col, 1, 5)
    _shape_cyl(ctx, Vector3(x, 0, z), 0.12, 2.8)

static func gravestone(ctx: Ctx, x: float, z: float, yaw: float) -> void:
    ctx.decor.push(Vector3(x, 0, z), Vector3(0, yaw, 0))
    ctx.decor.box(Vector3(0, 0.5, 0), Vector3(0.7, 1.0, 0.18), Color(0.40, 0.42, 0.40))
    ctx.decor.blob(Vector3(0, 1.0, 0), Vector3(0.35, 0.22, 0.1), Color(0.44, 0.46, 0.43), 1, 6)
    ctx.decor.box(Vector3(0, 0.05, 0.5), Vector3(0.7, 0.1, 1.1), Color(0.26, 0.22, 0.18))
    ctx.decor.pop()
    _shape_box(ctx, Vector3(x, 0.5, z), Vector3(0.7, 1.0, 0.3), yaw)

static func _free(ctx: Ctx, x: float, z: float, margin: float) -> bool:
    for r in ctx.blocks:
        if x > r.position.x - margin and x < r.end.x + margin and z > r.position.y - margin and z < r.end.y + margin:
            return false
    return true

static func _grass(ctx: Ctx, count: int, rect: Rect2) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = ctx.rng.randi()
    var mesh := EnvArt._tuft_mesh(rng, false)
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = mesh
    var spots: Array[Vector3] = []
    var tries := 0
    while spots.size() < count and tries < count * 5:
        tries += 1
        var x := rng.randf_range(rect.position.x, rect.end.x)
        var z := rng.randf_range(rect.position.y, rect.end.y)
        if _free(ctx, x, z, 0.5):
            spots.append(Vector3(x, 0.0, z))
    mm.instance_count = spots.size()
    for i in range(spots.size()):
        var sc := rng.randf_range(0.8, 1.5)
        var basis := Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(sc, sc, sc))
        mm.set_instance_transform(i, Transform3D(basis, spots[i]))
    var inst := MultiMeshInstance3D.new()
    inst.name = "Grass"
    inst.multimesh = mm
    inst.material_override = LP.material()
    inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    ctx.root.add_child(inst)

# ---------------------------------------------------------------- woods
static func _woods(ctx: Ctx) -> void:
    road(ctx, 0, -5, WD.CELL, 7.0, Color(0.20, 0.20, 0.17))
    ctx.blocks.append(Rect2(-32, -9, 64, 8))          # road corridor stays clear
    building(ctx, -14, -10, 8, 7, Color(0.36, 0.26, 0.17), Color(0.24, 0.18, 0.12), "s", 2.4)
    building(ctx, 14, 16, 9, 8, Color(0.40, 0.40, 0.37), Color(0.28, 0.28, 0.26), "n", 2.6)
    ctx.blocks.append(Rect2(5, 4, 20, 20))           # graveyard
    ctx.blocks.append(Rect2(-26, 11, 16, 16))        # matriarch's lair
    for row in range(3):
        for col in range(5):
            gravestone(ctx, 7.0 + float(col) * 3.4, 6.0 + float(row) * 3.0, ctx.rng.randf_range(-12, 12))
    # Lair: ring of dead trees and glowing egg sacs.
    for i in range(9):
        var a := float(i) * TAU / 9.0
        dead_tree(ctx, -18.0 + cos(a) * 7.5, 18.0 + sin(a) * 7.5, 1.1)
    for i in range(6):
        var a2 := float(i) * TAU / 6.0 + 0.3
        var ex := -18.0 + cos(a2) * 3.4
        var ez := 18.0 + sin(a2) * 3.4
        ctx.decor.blob(Vector3(ex, 0.55, ez), Vector3(0.6, 0.7, 0.6), Color(0.66, 0.62, 0.52), 2, 6)
        ctx.glow.blob(Vector3(ex, 0.6, ez), Vector3(0.28, 0.34, 0.28), Color(0.9, 0.45, 0.2), 1, 5)
    # Forest.
    var placed: Array[Vector2] = []
    var tries := 0
    while placed.size() < 92 and tries < 1500:
        tries += 1
        var x := ctx.rng.randf_range(-30.5, 30.5)
        var z := ctx.rng.randf_range(-30.5, 30.5)
        if not _free(ctx, x, z, 1.8):
            continue
        var ok := true
        for q in placed:
            if q.distance_to(Vector2(x, z)) < 3.5:
                ok = false
                break
        if not ok:
            continue
        placed.append(Vector2(x, z))
        var roll := ctx.rng.randf()
        var s := ctx.rng.randf_range(0.9, 1.4)
        if roll < 0.55:
            pine(ctx, x, z, s)
        elif roll < 0.80:
            dead_tree(ctx, x, z, s * 0.95)
        else:
            oak(ctx, x, z, s * 0.95)
    _grass(ctx, 650, Rect2(-31, -31, 62, 62))

# ---------------------------------------------------------------- hospital
static func _hospital(ctx: Ctx) -> void:
    road(ctx, 0, -18, 9.0, 28.0)
    var wall := Color(0.80, 0.84, 0.82)
    building(ctx, 0, -4, 36, 20, wall, Color(0.62, 0.66, 0.66), "n", 5.0, 2.0)
    # Interior partitions with doorways: rooms on both sides of a central corridor.
    for sx in [-9.0, 9.0]:
        block(ctx, sx, -10.2, 0.25, 1.6, 7.6, wall.darkened(0.1))
        block(ctx, sx, 2.6, 0.25, 1.6, 6.8, wall.darkened(0.1))
    block(ctx, 0, 2.5, 0.0 + 6.0, 1.0, 0.3, Color(0.55, 0.60, 0.60))      # reception desk
    for bx in [-14.0, 14.0]:
        for bz in [-11.0, 2.0]:
            block(ctx, bx, bz, 2.0, 0.55, 1.0, Color(0.72, 0.78, 0.80))
            ctx.decor.box(Vector3(bx - 0.65, 0.62, bz), Vector3(0.6, 0.1, 0.8), Color(0.85, 0.85, 0.85))
    for bx in [-5.0, 5.0]:
        block(ctx, bx, -11.0, 1.4, 0.9, 0.8, Color(0.55, 0.65, 0.62))      # medicine cabinets
    # Red cross sign over the entrance and glowing room lamps.
    ctx.decor.box(Vector3(0, 2.3, -14.1), Vector3(2.4, 0.9, 0.12), Color(0.90, 0.90, 0.88))
    ctx.glow.box(Vector3(0, 2.3, -14.2), Vector3(1.4, 0.3, 0.06), Color(0.9, 0.15, 0.15))
    ctx.glow.box(Vector3(0, 2.3, -14.2), Vector3(0.3, 1.2, 0.06), Color(0.9, 0.15, 0.15))
    # Courtyard.
    for p in [Vector2(-22, 12), Vector2(24, 15)]:
        block(ctx, p.x, p.y, 5.2, 1.6, 2.4, Color(0.88, 0.88, 0.86), 20.0)
        ctx.decor.box(Vector3(p.x, 1.62, p.y), Vector3(2.0, 0.05, 1.0), Color(0.8, 0.2, 0.2))
        ctx.blocks.append(Rect2(p.x - 3.4, p.y - 3.4, 6.8, 6.8))
    for p in [Vector2(-10, 10), Vector2(10, 10), Vector2(-10, 26), Vector2(10, 26), Vector2(-28, -22), Vector2(28, -22)]:
        lamp(ctx, p.x, p.y)
    for i in range(10):
        pine(ctx, ctx.rng.randf_range(-30.0, 30.0), 29.5 + ctx.rng.randf() * 1.5 if i % 2 == 0 else -30.0, 1.1)
    for i in range(6):
        block(ctx, -22.0 + float(i) * 8.8, 29.0, 3.0, 0.9, 1.2, Color(0.18, 0.27, 0.19))    # hedges
    _grass(ctx, 200, Rect2(-31, 8, 62, 22))

# ---------------------------------------------------------------- rustworks
static func _rustworks(ctx: Ctx) -> void:
    road(ctx, 0, 12, 9.0, 40.0)
    var steel := Color(0.37, 0.34, 0.31)
    building(ctx, 0, -2, 32, 20, steel, Color(0.22, 0.20, 0.19), "s", 6.0, 2.2)
    for i in range(3):
        block(ctx, -9.0 + float(i) * 9.0, -6.0, 5.0, 1.4, 1.4, Color(0.45, 0.28, 0.16))   # machines
        ctx.glow.box(Vector3(-9.0 + float(i) * 9.0, 1.45, -6.6), Vector3(2.2, 0.1, 0.06), Color(1.0, 0.45, 0.12))
    block(ctx, 0, 3.0, 22.0, 0.35, 0.8, Color(0.26, 0.25, 0.24), 0.0, false)             # conveyor
    building(ctx, -24, -14, 8, 6, Color(0.42, 0.33, 0.24), Color(0.25, 0.20, 0.16), "e", 2.4)
    var cols := [Color(0.55, 0.22, 0.14), Color(0.18, 0.38, 0.42), Color(0.25, 0.32, 0.50), Color(0.42, 0.44, 0.22), Color(0.50, 0.38, 0.14)]
    var yard := [Vector3(-26, -4, 0), Vector3(-26, 12, 0), Vector3(-12, 17, 90), Vector3(9, 19, 0), Vector3(22, 12, 90),
        Vector3(25, -3, 0), Vector3(25, -10, 0), Vector3(-8, 27, 0), Vector3(14, 27, 90), Vector3(-24, 24, 0)]
    for i in range(yard.size()):
        var y: Vector3 = yard[i]
        container(ctx, y.x, y.y, y.z, cols[i % cols.size()])
    for p in [Vector2(-12, -24), Vector2(12, -24), Vector2(0, -29)]:
        chimney(ctx, p.x, p.y, 13.0, Color(0.40, 0.30, 0.26), true)
    # Pipe run on posts.
    for x in range(-14, 15, 7):
        ctx.decor.box(Vector3(float(x), 1.2, -17.0), Vector3(0.3, 2.4, 0.3), Color(0.30, 0.30, 0.32))
    ctx.decor.box(Vector3(0, 2.5, -17.0), Vector3(30, 0.5, 0.5), Color(0.52, 0.34, 0.20))
    for p in [Vector2(-16, 24), Vector2(-2, 30), Vector2(18, 20), Vector2(28, 5), Vector2(-30, 8)]:
        barrel(ctx, p.x, p.y, Color(0.55, 0.20, 0.14))
        barrel(ctx, p.x + 0.9, p.y + 0.3, Color(0.30, 0.38, 0.34))
    for i in range(7):
        rocks(ctx, ctx.rng.randf_range(-29.0, 29.0), ctx.rng.randf_range(-29.0, -22.0), 0.9, true, -0.08)
    for p in [Vector2(-6, 8), Vector2(6, 8), Vector2(-14, -20), Vector2(14, 22)]:
        lamp(ctx, p.x, p.y, Color(1.0, 0.6, 0.25))

# ---------------------------------------------------------------- quarry
static func _quarry(ctx: Ctx) -> void:
    road(ctx, 0, -5, WD.CELL, 7.0, Color(0.30, 0.28, 0.24))
    ctx.blocks.append(Rect2(-32, -9, 64, 8))
    building(ctx, -20, -18, 8, 6, Color(0.46, 0.38, 0.28), Color(0.28, 0.24, 0.20), "s", 2.4)
    # Terraced rock walls to the north and south.
    var rock := Color(0.44, 0.41, 0.36)
    for i in range(6):
        var x := -26.0 + float(i) * 10.5
        block(ctx, x, -28.5, 10.0, 3.0 + float(i % 3) * 1.2, 5.0, rock.darkened(0.04 * float(i % 3)))
        block(ctx, x + 2.0, -27.0, 6.0, 4.4 + float(i % 2), 3.0, rock.lightened(0.05))
        block(ctx, x + 3.0, 28.5, 8.0, 2.6 + float(i % 2) * 1.4, 5.0, rock)
    # Mine entrance on the east side.
    block(ctx, 29.5, -4.0, 5.0, 5.0, 11.0, Color(0.34, 0.31, 0.28))
    ctx.decor.box(Vector3(26.9, 1.6, -4.0), Vector3(0.6, 3.2, 4.0), Color(0.05, 0.05, 0.06))
    for z in [-6.0, -2.0]:
        ctx.decor.box(Vector3(26.6, 1.6, z), Vector3(0.5, 3.4, 0.4), Color(0.36, 0.25, 0.15))
    ctx.decor.box(Vector3(26.6, 3.4, -4.0), Vector3(0.5, 0.4, 4.6), Color(0.36, 0.25, 0.15))
    ctx.blocks.append(Rect2(24, -9, 8, 10))
    # Rails and carts.
    ctx.decor.box(Vector3(10.0, 0.05, -4.0), Vector3(36, 0.08, 0.14), Color(0.22, 0.22, 0.24))
    ctx.decor.box(Vector3(10.0, 0.05, -3.2), Vector3(36, 0.08, 0.14), Color(0.22, 0.22, 0.24))
    for p in [Vector2(6, -3.6), Vector2(-9, 9)]:
        block(ctx, p.x, p.y, 2.0, 1.0, 1.2, Color(0.34, 0.26, 0.18))
        ctx.decor.box(Vector3(p.x, 1.05, p.y), Vector3(1.7, 0.2, 0.9), Color(0.45, 0.42, 0.38))
    # Crane.
    for p in [Vector2(-5, 6), Vector2(-1, 6)]:
        ctx.decor.box(Vector3(p.x, 3.5, p.y), Vector3(0.35, 7.0, 0.35), Color(0.62, 0.48, 0.14))
        _shape_cyl(ctx, Vector3(p.x, 0, p.y), 0.25, 7.0)
    ctx.decor.box(Vector3(-3.0, 7.1, 6.0), Vector3(9, 0.4, 0.4), Color(0.62, 0.48, 0.14))
    ctx.blocks.append(Rect2(-8, 3, 10, 6))
    for p in [Vector2(-26, 8), Vector2(-14, 24), Vector2(12, 6), Vector2(4, -24), Vector2(-4, 20), Vector2(22, 16)]:
        rocks(ctx, p.x, p.y, 1.2, true, 0.04)
        ctx.blocks.append(Rect2(p.x - 2, p.y - 2, 4, 4))
    for p in [Vector2(-12, 3), Vector2(14, -14), Vector2(18, 10)]:
        lamp(ctx, p.x, p.y, Color(1.0, 0.72, 0.3))

# ---------------------------------------------------------------- forge
static func _forge(ctx: Ctx) -> void:
    var basalt := Color(0.20, 0.18, 0.19)
    # Lava cracks radiate from the anvil.
    for i in range(9):
        var a := float(i) * TAU / 9.0 + 0.2
        var p := Vector3(0, 0.035, -14)
        for step in range(5):
            var len := 3.0 + ctx.rng.randf() * 2.5
            var na := a + ctx.rng.randf_range(-0.45, 0.45)
            var q := p + Vector3(cos(na) * len, 0, sin(na) * len)
            if absf(q.x) > 30.0 or q.z > 30.0 or q.z < -30.0:
                break
            var mid := (p + q) * 0.5
            ctx.glow.push(mid, Vector3(0, -rad_to_deg(atan2(q.z - p.z, q.x - p.x)), 0))
            ctx.glow.box(Vector3.ZERO, Vector3(len, 0.02, 0.22), Color(1.0, 0.38, 0.06))
            ctx.glow.pop()
            p = q
    # Big anvil monument.
    block(ctx, 0, -20, 6.0, 1.4, 3.2, basalt)
    block(ctx, 0, -20, 3.4, 3.0, 2.0, basalt.lightened(0.04))
    ctx.decor.box(Vector3(0, 3.4, -20), Vector3(7.5, 0.9, 2.6), basalt.lightened(0.08))
    ctx.decor.box(Vector3(-4.8, 3.3, -20), Vector3(2.2, 0.5, 1.2), basalt.lightened(0.1))
    _shape_box(ctx, Vector3(0, 3.4, -20), Vector3(7.5, 0.9, 2.6))
    ctx.blocks.append(Rect2(-6, -24, 12, 8))
    # Chimneys with glowing mouths, lava pools with low rims.
    for p in [Vector2(-20, -22), Vector2(20, -22), Vector2(-26, 4), Vector2(26, 2)]:
        chimney(ctx, p.x, p.y, 11.0, basalt.lightened(0.05), true)
    for p in [Vector2(-18, 8), Vector2(20, -4)]:
        ctx.glow.box(Vector3(p.x, 0.04, p.y), Vector3(6.0, 0.03, 5.0), Color(1.0, 0.32, 0.05))
        for s in [[0.0, -2.8, 6.6, 0.5], [0.0, 2.8, 6.6, 0.5], [-3.3, 0.0, 0.5, 5.6], [3.3, 0.0, 0.5, 5.6]]:
            block(ctx, p.x + float(s[0]), p.y + float(s[1]), float(s[2]), 0.7, float(s[3]), basalt)
        ctx.blocks.append(Rect2(p.x - 4, p.y - 3.5, 8, 7))
    # Entrance arch and braziers along the path.
    for x in [-6.0, 6.0]:
        block(ctx, x, 26.0, 1.8, 6.0, 1.8, basalt.lightened(0.06))
    ctx.decor.box(Vector3(0, 6.2, 26), Vector3(14, 1.2, 2.0), basalt.lightened(0.1))
    ctx.blocks.append(Rect2(-8, 24, 16, 4))
    for z in [22.0, 14.0, 6.0]:
        for x in [-5.0, 5.0]:
            ctx.decor.frustum(Vector3(x, 0, z), 1.1, 0.35, 0.35, 0.5, 0.5, 6, Color(0.22, 0.2, 0.2))
            ctx.glow.blob(Vector3(x, 1.3, z), Vector3(0.42, 0.34, 0.42), Color(1.0, 0.5, 0.1), 2, 6)
            _shape_cyl(ctx, Vector3(x, 0, z), 0.5, 1.1)
    # Note pedestal.
    block(ctx, 0, 16, 1.2, 0.9, 1.2, basalt.lightened(0.1))
    for i in range(10):
        rocks(ctx, ctx.rng.randf_range(-29.0, 29.0), ctx.rng.randf_range(-29.0, 22.0), 1.0, true, -0.12)
