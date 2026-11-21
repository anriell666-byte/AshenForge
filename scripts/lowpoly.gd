extends RefCounted
## Flat-shaded low-poly mesh builder. Collects triangles with per-face colour
## jitter (the faceted look) and commits a single ArrayMesh with vertex colours.
##
## Usage:
##   var b := LowPoly.new()
##   b.frustum(Vector3(0,0,0), 1.0, 0.3, 0.3, 0.2, 0.2, 6, Color.RED)
##   var node := b.to_node("Part", LowPoly.material())

var verts := PackedVector3Array()
var norms := PackedVector3Array()
var cols := PackedColorArray()
var _xf := Transform3D.IDENTITY
var _stack: Array[Transform3D] = []
var _counter := 0
var jitter := 0.07

static var _mat_cache: StandardMaterial3D
static var _glow_cache := {}

static func material() -> StandardMaterial3D:
    if _mat_cache == null:
        _mat_cache = StandardMaterial3D.new()
        _mat_cache.vertex_color_use_as_albedo = true
        _mat_cache.roughness = 0.92
        _mat_cache.metallic = 0.0
    return _mat_cache

static func glow_material(energy: float = 2.2) -> StandardMaterial3D:
    var key := int(energy * 10.0)
    if not _glow_cache.has(key):
        var m := StandardMaterial3D.new()
        m.vertex_color_use_as_albedo = true
        m.emission_enabled = true
        m.emission_energy_multiplier = energy
        m.roughness = 1.0
        # Emission follows the vertex colour so one mesh can hold several glow colours.
        m.emission_operator = BaseMaterial3D.EMISSION_OP_ADD
        _glow_cache[key] = m
    return _glow_cache[key]

# ---------------------------------------------------------------- transforms
func push(pos: Vector3 = Vector3.ZERO, euler_deg: Vector3 = Vector3.ZERO, scale_v: Vector3 = Vector3.ONE) -> void:
    _stack.append(_xf)
    var rot := Basis.from_euler(Vector3(deg_to_rad(euler_deg.x), deg_to_rad(euler_deg.y), deg_to_rad(euler_deg.z)))
    rot = rot.scaled(scale_v)
    _xf = _xf * Transform3D(rot, pos)

func pop() -> void:
    if _stack.size() > 0:
        _xf = _stack.pop_back()

# ---------------------------------------------------------------- primitives
func _hash_jitter() -> float:
    _counter += 1
    var h := sin(float(_counter) * 12.9898) * 43758.5453
    return (h - floor(h)) * 2.0 - 1.0

func tri(a: Vector3, b: Vector3, c: Vector3, col: Color, center: Vector3) -> void:
    a = _xf * a
    b = _xf * b
    c = _xf * c
    var ctr := _xf * center
    var n := (c - a).cross(b - a)
    if n.length() < 0.000001:
        return
    n = n.normalized()
    # Make the winding robust: the face normal must point away from the piece centre.
    if n.dot((a + b + c) / 3.0 - ctr) < 0.0:
        var t := b
        b = c
        c = t
        n = -n
    var k := 1.0 + _hash_jitter() * jitter
    var shaded := Color(clampf(col.r * k, 0.0, 1.0), clampf(col.g * k, 0.0, 1.0), clampf(col.b * k, 0.0, 1.0), col.a)
    verts.append(a); verts.append(b); verts.append(c)
    norms.append(n); norms.append(n); norms.append(n)
    cols.append(shaded); cols.append(shaded); cols.append(shaded)

func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, center: Vector3) -> void:
    tri(a, b, c, col, center)
    tri(a, c, d, col, center)

## Tapered prism. `base` is the centre of the bottom ring; the top ring sits
## `h` above it, shifted by `top_off` (x,z). Radii are elliptical.
func frustum(base: Vector3, h: float, rx0: float, rz0: float, rx1: float, rz1: float, sides: int, col: Color, top_off: Vector2 = Vector2.ZERO, rot_deg: float = 0.0, caps: bool = true) -> void:
    var bottom: Array[Vector3] = []
    var top: Array[Vector3] = []
    var rot := deg_to_rad(rot_deg)
    for i in range(sides):
        var ang := rot + float(i) * TAU / float(sides)
        bottom.append(base + Vector3(cos(ang) * rx0, 0.0, sin(ang) * rz0))
        top.append(base + Vector3(top_off.x + cos(ang) * rx1, h, top_off.y + sin(ang) * rz1))
    var centre := base + Vector3(top_off.x * 0.5, h * 0.5, top_off.y * 0.5)
    for i in range(sides):
        var j := (i + 1) % sides
        quad(bottom[i], bottom[j], top[j], top[i], col, centre)
    if caps:
        var cb := base
        var ct := base + Vector3(top_off.x, h, top_off.y)
        for i in range(sides):
            var j := (i + 1) % sides
            tri(cb, bottom[j], bottom[i], col, centre)
            tri(ct, top[i], top[j], col, centre)

func box(center: Vector3, size: Vector3, col: Color) -> void:
    var h := size * 0.5
    var p := [
        center + Vector3(-h.x, -h.y, -h.z), center + Vector3(h.x, -h.y, -h.z),
        center + Vector3(h.x, h.y, -h.z), center + Vector3(-h.x, h.y, -h.z),
        center + Vector3(-h.x, -h.y, h.z), center + Vector3(h.x, -h.y, h.z),
        center + Vector3(h.x, h.y, h.z), center + Vector3(-h.x, h.y, h.z)]
    quad(p[0], p[1], p[2], p[3], col, center)
    quad(p[5], p[4], p[7], p[6], col, center)
    quad(p[4], p[0], p[3], p[7], col, center)
    quad(p[1], p[5], p[6], p[2], col, center)
    quad(p[3], p[2], p[6], p[7], col, center)
    quad(p[4], p[5], p[1], p[0], col, center)

## Low-poly ellipsoid.
func blob(center: Vector3, radii: Vector3, col: Color, rings: int = 3, segs: int = 7, squash_bottom: float = 1.0) -> void:
    var grid: Array = []
    for r in range(rings + 1):
        var phi := PI * float(r) / float(rings)
        var row: Array[Vector3] = []
        var y := cos(phi)
        var rad := sin(phi)
        for s in range(segs):
            var ang := float(s) * TAU / float(segs) + (PI / float(segs) if r % 2 == 1 else 0.0)
            var yy := y * radii.y * (squash_bottom if y < 0.0 else 1.0)
            row.append(center + Vector3(cos(ang) * rad * radii.x, yy, sin(ang) * rad * radii.z))
        grid.append(row)
    for r in range(rings):
        for s in range(segs):
            var s2 := (s + 1) % segs
            var a: Vector3 = grid[r][s]
            var b: Vector3 = grid[r][s2]
            var c: Vector3 = grid[r + 1][s2]
            var d: Vector3 = grid[r + 1][s]
            if r == 0:
                tri(a, c, d, col, center)
            elif r == rings - 1:
                tri(a, b, d, col, center)
            else:
                quad(a, b, c, d, col, center)

## Cone / spike pointing along +Y from `base`, optionally leaning by `lean` (x,z).
func spike(base: Vector3, h: float, radius: float, col: Color, sides: int = 5, lean: Vector2 = Vector2.ZERO) -> void:
    frustum(base, h, radius, radius, 0.0, 0.0, sides, col, lean, 0.0, true)

## Spike between two points (any direction).
func spike_dir(from: Vector3, to: Vector3, radius: float, col: Color, sides: int = 5) -> void:
    var dir := to - from
    var len := dir.length()
    if len < 0.0001:
        return
    var up := Vector3.UP
    var d := dir / len
    var axis := up.cross(d)
    var basis := Basis.IDENTITY
    if axis.length() > 0.0001:
        basis = Basis(axis.normalized(), up.angle_to(d))
    elif d.y < 0.0:
        basis = Basis(Vector3.RIGHT, PI)
    _stack.append(_xf)
    _xf = _xf * Transform3D(basis, from)
    frustum(Vector3.ZERO, len, radius, radius, 0.0, 0.0, sides, col)
    _xf = _stack.pop_back()

## Tube between two points with different radii.
func limb_between(from: Vector3, to: Vector3, r0: float, r1: float, col: Color, sides: int = 6) -> void:
    var dir := to - from
    var len := dir.length()
    if len < 0.0001:
        return
    var d := dir / len
    var axis := Vector3.UP.cross(d)
    var basis := Basis.IDENTITY
    if axis.length() > 0.0001:
        basis = Basis(axis.normalized(), Vector3.UP.angle_to(d))
    elif d.y < 0.0:
        basis = Basis(Vector3.RIGHT, PI)
    _stack.append(_xf)
    _xf = _xf * Transform3D(basis, from)
    frustum(Vector3.ZERO, len, r0, r0, r1, r1, sides, col)
    _xf = _stack.pop_back()

# ---------------------------------------------------------------- output
func is_empty() -> bool:
    return verts.size() == 0

func build_mesh() -> ArrayMesh:
    var mesh := ArrayMesh.new()
    if verts.size() == 0:
        return mesh
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = verts
    arrays[Mesh.ARRAY_NORMAL] = norms
    arrays[Mesh.ARRAY_COLOR] = cols
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh

func to_node(label: String, mat: Material = null) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = build_mesh()
    node.material_override = mat if mat != null else material()
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    return node

# ---------------------------------------------------------------- colour helpers
static func shade(c: Color, amount: float) -> Color:
    return c.darkened(amount) if amount > 0.0 else c.lightened(-amount)

static func mix(a: Color, b: Color, t: float) -> Color:
    return a.lerp(b, t)
