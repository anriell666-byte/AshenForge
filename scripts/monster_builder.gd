extends RefCounted
## Procedural low-poly monsters. Four silhouettes (walker, stalker, brute, ogre) are
## reused for regular enemies and bosses; `extras` in monster_data.gd add boss features.
## Every model faces -Z, stands on y = 0 and returns limbs as [arm R, arm L, leg L, leg R].

const LP = preload("res://scripts/lowpoly.gd")
const MD = preload("res://scripts/monster_data.gd")

static func build(id: String) -> Dictionary:
    var p: Dictionary = MD.get_monster(id)
    var r: Dictionary
    match String(p["kind"]):
        "stalker":
            r = _stalker(p)
        "brute":
            r = _brute(p)
        "ogre":
            r = _ogre(p)
        _:
            r = _walker(p)
    var model: Node3D = r["model"]
    var s: float = float(p.get("scale", 1.0))
    model.scale = Vector3(s, s, s)
    r["height"] = float(r.get("height", 1.8)) * s
    r["radius"] = float(r.get("radius", 0.4)) * s
    return r

# ---------------------------------------------------------------- helpers
static func _lp() -> Object:
    var l = LP.new()
    l.smooth = true
    return l

static func _limb(label: String, pos: Vector3, main: Object, glow: Object = null, z_tilt: float = 0.0) -> Node3D:
    var pivot := Node3D.new()
    pivot.name = label
    pivot.position = pos
    pivot.rotation.z = z_tilt
    pivot.add_child(main.to_node("Mesh"))
    if glow != null and not glow.is_empty():
        pivot.add_child(glow.to_node("Glow", LP.glow_material(2.0)))
    return pivot

static func _finish(root: Node3D, body: Object, glow: Object, limbs: Array, rest: Array, swing: float, height: float, radius: float) -> Dictionary:
    root.add_child(body.to_node("Body"))
    if not glow.is_empty():
        root.add_child(glow.to_node("Glow", LP.glow_material(2.2)))
    for limb in limbs:
        root.add_child(limb)
    return {"model": root, "limbs": limbs, "rest": rest, "swing": swing, "height": height, "radius": radius}

static func _eyes(g: Object, b: Object, centre: Vector3, spread: float, col: Color, size: float) -> void:
    for sx in [-1.0, 1.0]:
        b.box(centre + Vector3(sx * spread, 0.0, 0.0), Vector3(size * 2.2, size * 1.5, size), Color(0.05, 0.03, 0.03))
        g.box(centre + Vector3(sx * spread, 0.0, -size * 0.4), Vector3(size * 1.2, size * 0.9, size * 0.8), col)

# ---------------------------------------------------------------- walker (zombie)
static func _walker(p: Dictionary) -> Dictionary:
    var skin: Color = p["skin"]
    var shirt: Color = p["shirt"]
    var pants: Color = p["pants"]
    var extras: Array = p.get("extras", [])
    var glow_col: Color = p.get("glow", Color(0.85, 0.8, 0.45))
    var root := Node3D.new()
    root.name = "Walker"
    var b := _lp()
    var g := _lp()
    var lean := -17.0
    b.frustum(Vector3(0, 0.80, 0), 0.15, 0.15, 0.10, 0.15, 0.10, 8, pants, Vector2.ZERO, 22.5, false)
    b.push(Vector3(0, 0.93, 0), Vector3(lean, 0, 0))
    g.push(Vector3(0, 0.93, 0), Vector3(lean, 0, 0))
    b.frustum(Vector3.ZERO, 0.58, 0.15, 0.10, 0.21, 0.12, 8, shirt, Vector2.ZERO, 22.5, true)
    for i in range(8):
        var a := float(i) * TAU / 8.0 + 0.39
        var x := cos(a) * 0.15
        var z := sin(a) * 0.10
        b.spike_dir(Vector3(x, 0.05, z), Vector3(x * 1.05, -0.10 - 0.04 * float(i % 3), z * 1.05), 0.032, shirt.darkened(0.12), 3)
    b.box(Vector3(0.05, 0.34, -0.127), Vector3(0.09, 0.12, 0.012), Color(0.33, 0.05, 0.05))
    b.box(Vector3(-0.07, 0.17, -0.122), Vector3(0.06, 0.08, 0.012), Color(0.30, 0.06, 0.05))
    b.box(Vector3(-0.04, 0.42, -0.127), Vector3(0.08, 0.10, 0.012), skin.darkened(0.12))
    b.frustum(Vector3(0, 0.58, 0), 0.12, 0.05, 0.05, 0.045, 0.045, 6, skin)
    var hc := Vector3(0, 0.78, -0.05)
    b.blob(hc, Vector3(0.095, 0.12, 0.105), skin, 4, 8, 0.9)
    b.box(hc + Vector3(0, -0.09, -0.045), Vector3(0.07, 0.05, 0.05), skin)
    _eyes(g, b, hc + Vector3(0, 0.012, -0.098), 0.04, glow_col if extras.has("glow_eyes") else glow_col.darkened(0.55), 0.016)
    b.box(hc + Vector3(0, -0.07, -0.1), Vector3(0.05, 0.04, 0.012), Color(0.1, 0.02, 0.02))
    for k in range(4):
        b.box(hc + Vector3(-0.018 + float(k) * 0.012, -0.056, -0.104), Vector3(0.007, 0.012, 0.008), Color(0.85, 0.82, 0.7))
    b.box(hc + Vector3(-0.03, 0.115, 0.02), Vector3(0.05, 0.02, 0.08), Color(0.2, 0.18, 0.15))
    b.box(hc + Vector3(0.04, 0.10, 0.05), Vector3(0.04, 0.02, 0.06), Color(0.2, 0.18, 0.15))
    # exposed ribs through the torn shirt, collar bones, neck bite, patchy hair, hanging jaw
    var bone_c := Color(0.82, 0.78, 0.66)
    for k in range(4):
        var ry := 0.16 + float(k) * 0.045
        b.limb_between(Vector3(0.02, ry, -0.128), Vector3(0.11 - float(k) * 0.01, ry - 0.025, -0.108), 0.009, 0.007, bone_c, 4)
    for sx in [-1.0, 1.0]:
        b.limb_between(Vector3(sx * 0.02, 0.56, -0.1), Vector3(sx * 0.17, 0.55, -0.07), 0.014, 0.012, skin.darkened(0.05), 5)
    b.blob(Vector3(0.04, 0.6, -0.04), Vector3(0.03, 0.025, 0.02), Color(0.35, 0.05, 0.05), 2, 6)
    for k in range(3):
        b.blob(hc + Vector3(-0.05 + float(k) * 0.05, 0.1, 0.0), Vector3(0.03, 0.02, 0.04), Color(0.18, 0.15, 0.12), 2, 5)
    b.box(hc + Vector3(0, -0.115, -0.07), Vector3(0.06, 0.02, 0.05), skin.darkened(0.1))
    b.blob(hc + Vector3(0.03, -0.14, -0.095), Vector3(0.008, 0.03, 0.008), Color(0.55, 0.12, 0.1), 2, 5)
    if extras.has("bloat"):
        b.blob(Vector3(0, 0.22, -0.12), Vector3(0.27, 0.27, 0.25), skin.lightened(0.08), 4, 8)
        for k in range(6):
            var a2 := float(k) * 1.1
            b.blob(Vector3(cos(a2) * 0.2, 0.12 + float(k % 3) * 0.12, -0.3 + sin(a2) * 0.03), Vector3(0.05, 0.05, 0.045), Color(0.78, 0.74, 0.35), 2, 5)
    if extras.has("sash"):
        b.limb_between(Vector3(-0.2, 0.5, -0.13), Vector3(0.18, 0.02, -0.2), 0.035, 0.035, Color(0.62, 0.12, 0.1), 5)
    b.pop()
    g.pop()

    var sh_y := 0.93 + 0.52 * cos(deg_to_rad(lean))
    var sh_z := 0.52 * sin(deg_to_rad(lean))
    var limbs: Array = []
    for sx in [1.0, -1.0]:
        var a := _lp()
        a.limb_between(Vector3.ZERO, Vector3(0, -0.17, 0), 0.052, 0.048, shirt)
        a.limb_between(Vector3(0, -0.17, 0), Vector3(0, -0.60, 0), 0.044, 0.032, skin)
        a.blob(Vector3(0, -0.63, 0), Vector3(0.035, 0.05, 0.03), skin, 2, 6)
        a.blob(Vector3(0, -0.17, 0), Vector3(0.05, 0.045, 0.05), skin.darkened(0.1), 2, 6)
        a.spike_dir(Vector3(0.0, -0.3, -0.04), Vector3(0.0, -0.4, -0.06), 0.012, Color(0.82, 0.78, 0.66), 3)
        a.blob(Vector3(0, -0.33, -0.035), Vector3(0.03, 0.045, 0.012), Color(0.4, 0.06, 0.06), 2, 5)
        for f in range(4):
            a.spike_dir(Vector3((float(f) - 1.5) * 0.016, -0.65, 0), Vector3((float(f) - 1.5) * 0.024, -0.75 - float(f % 2) * 0.02, -0.035), 0.009, skin.darkened(0.2), 3)
        limbs.append(_limb("ArmPivot", Vector3(sx * 0.25, sh_y, sh_z), a, null, -sx * 0.1))
    var legs: Array = []
    for sx in [-1.0, 1.0]:
        var l := _lp()
        l.limb_between(Vector3.ZERO, Vector3(0, -0.46, 0), 0.075, 0.058, pants)
        l.limb_between(Vector3(0, -0.46, 0), Vector3(0, -0.64, 0), 0.058, 0.05, pants.darkened(0.1))
        l.limb_between(Vector3(0, -0.64, 0), Vector3(0, -0.88, 0), 0.048, 0.04, skin.darkened(0.08))
        l.box(Vector3(0, -0.9, -0.045), Vector3(0.1, 0.06, 0.25), Color(0.14, 0.12, 0.1))
        l.blob(Vector3(0, -0.46, -0.03), Vector3(0.06, 0.055, 0.055), pants.darkened(0.12), 2, 6)
        for k in range(5):
            var ca := float(k) * TAU / 5.0
            l.spike_dir(Vector3(cos(ca) * 0.05, -0.62, sin(ca) * 0.05), Vector3(cos(ca) * 0.055, -0.72, sin(ca) * 0.055), 0.016, pants.darkened(0.2), 3)
        legs.append(_limb("LegPivot", Vector3(sx * 0.09, 0.93, 0), l))
    limbs.append(legs[0])
    limbs.append(legs[1])
    return _finish(root, b, g, limbs, [1.25, 1.25, 0.0, 0.0], 1.0, 1.75, 0.4)

# ---------------------------------------------------------------- stalker (stilt-limbed)
static func _stalker(p: Dictionary) -> Dictionary:
    var skin: Color = p["skin"]
    var accent: Color = p["accent"]
    var dark: Color = p["dark"]
    var extras: Array = p.get("extras", [])
    var glow_col: Color = p.get("glow", Color(1.0, 0.4, 0.2))
    var root := Node3D.new()
    root.name = "Stalker"
    var b := _lp()
    var g := _lp()
    var lean := -26.0
    b.frustum(Vector3(0, 1.45, 0), 0.12, 0.12, 0.09, 0.12, 0.09, 7, skin.darkened(0.1), Vector2.ZERO, 0.0, false)
    b.push(Vector3(0, 1.55, 0), Vector3(lean, 0, 0))
    g.push(Vector3(0, 1.55, 0), Vector3(lean, 0, 0))
    b.frustum(Vector3.ZERO, 0.78, 0.12, 0.08, 0.19, 0.10, 7, skin, Vector2.ZERO, 0.0, true)
    for k in range(5):
        var y := 0.12 + float(k) * 0.14
        b.box(Vector3(0, y, -0.09 + 0.0), Vector3(0.26 - 0.01 * float(k), 0.012, 0.012), skin.darkened(0.18))
    var spine_n := 9 if extras.has("extra_spines") else 5
    for k in range(spine_n):
        var t := float(k) / float(maxi(1, spine_n - 1))
        var base := Vector3(0, 0.1 + t * 0.62, 0.09)
        var tip := base + Vector3(0, 0.22 + (0.18 if extras.has("extra_spines") else 0.0) * (1.0 - t), 0.2)
        b.spike_dir(base, tip, 0.032, dark, 4)
        if extras.has("extra_spines"):
            g.spike_dir(tip - (tip - base).normalized() * 0.07, tip, 0.016, glow_col, 4)
    if extras.has("egg_sacs"):
        for k in range(5):
            b.blob(Vector3(sin(float(k) * 2.1) * 0.1, 0.18 + float(k) * 0.12, 0.17), Vector3(0.07, 0.08, 0.07), accent.lightened(0.15), 2, 6)
    b.frustum(Vector3(0, 0.78, 0), 0.26, 0.055, 0.05, 0.045, 0.045, 6, skin, Vector2(0, -0.13), 0.0, false)
    var hc := Vector3(0, 1.1, -0.2)
    b.blob(hc, Vector3(0.1, 0.15, 0.115), skin.lightened(0.12), 4, 8, 0.85)
    b.box(hc + Vector3(0, -0.02, -0.1), Vector3(0.05, 0.12, 0.02), Color(0.06, 0.03, 0.04))
    b.box(hc + Vector3(0, -0.02, -0.108), Vector3(0.026, 0.08, 0.01), Color(0.02, 0.0, 0.0))
    if extras.has("glow_eyes"):
        g.box(hc + Vector3(0, -0.02, -0.112), Vector3(0.016, 0.06, 0.006), glow_col)
    for sx in [-1.0, 1.0]:
        b.spike_dir(hc + Vector3(sx * 0.02, 0.04, -0.105), hc + Vector3(sx * 0.05, 0.065, -0.125), 0.008, Color(0.05, 0.02, 0.03), 3)
    # hanging jaw with needle teeth, curved ribs, vertebra knobs
    b.box(hc + Vector3(0, -0.15, -0.07), Vector3(0.07, 0.03, 0.09), skin.darkened(0.08))
    for k in range(6):
        var tx2 := -0.026 + float(k) * 0.0105
        b.spike_dir(hc + Vector3(tx2, -0.135, -0.108), hc + Vector3(tx2, -0.085, -0.11), 0.005, Color(0.9, 0.88, 0.8), 3)
    for k in range(5):
        var ry2 := 0.1 + float(k) * 0.14
        for sx in [-1.0, 1.0]:
            b.limb_between(Vector3(sx * 0.02, ry2, -0.09), Vector3(sx * (0.14 - 0.008 * float(k)), ry2 - 0.04, -0.03), 0.012, 0.009, skin.lightened(0.18), 4)
    for k in range(7):
        b.blob(Vector3(0, 0.06 + float(k) * 0.11, 0.1), Vector3(0.03, 0.03, 0.03), skin.darkened(0.2), 2, 5)
    b.pop()
    g.pop()

    var sh_y := 1.55 + 0.72 * cos(deg_to_rad(lean))
    var sh_z := 0.72 * sin(deg_to_rad(lean))
    var limbs: Array = []
    for sx in [1.0, -1.0]:
        var a := _lp()
        a.limb_between(Vector3.ZERO, Vector3(0, -0.45, 0), 0.058, 0.045, skin)
        a.limb_between(Vector3(0, -0.45, 0), Vector3(0, -0.8, 0), 0.045, 0.038, accent)
        a.limb_between(Vector3(0, -0.8, 0), Vector3(0, -sh_y + 0.02, 0), 0.036, 0.012, dark, 5)
        a.blob(Vector3(0, -0.45, 0), Vector3(0.062, 0.06, 0.062), skin.darkened(0.12), 2, 6)
        a.spike_dir(Vector3(0, -0.45, 0.04), Vector3(0, -0.52, 0.14), 0.014, dark, 3)
        limbs.append(_limb("ArmPivot", Vector3(sx * 0.21, sh_y, sh_z), a, null, -sx * 0.08))
    var legs: Array = []
    for sx in [-1.0, 1.0]:
        var l := _lp()
        l.limb_between(Vector3.ZERO, Vector3(0, -0.6, 0), 0.085, 0.06, skin)
        l.limb_between(Vector3(0, -0.6, 0), Vector3(0, -0.92, 0), 0.06, 0.045, accent)
        l.limb_between(Vector3(0, -0.92, 0), Vector3(0, -1.55, 0), 0.04, 0.013, dark, 5)
        l.blob(Vector3(0, -0.6, -0.02), Vector3(0.075, 0.07, 0.07), skin.darkened(0.12), 2, 6)
        l.blob(Vector3(0, -0.92, 0), Vector3(0.055, 0.055, 0.055), accent.darkened(0.1), 2, 6)
        legs.append(_limb("LegPivot", Vector3(sx * 0.11, 1.55, 0), l))
    limbs.append(legs[0])
    limbs.append(legs[1])
    return _finish(root, b, g, limbs, [0.15, 0.15, 0.0, 0.0], 0.32, 2.45, 0.55)

# ---------------------------------------------------------------- brute (hunched clawed)
static func _brute(p: Dictionary) -> Dictionary:
    var skin: Color = p["skin"]
    var bone: Color = p["accent"]
    var glow_col: Color = p["glow"]
    var extras: Array = p.get("extras", [])
    var root := Node3D.new()
    root.name = "Brute"
    var b := _lp()
    var g := _lp()
    var lean := -30.0
    b.frustum(Vector3(0, 0.86, 0), 0.16, 0.24, 0.16, 0.22, 0.15, 8, skin.darkened(0.12), Vector2.ZERO, 22.5, false)
    b.push(Vector3(0, 0.95, 0), Vector3(lean, 0, 0))
    g.push(Vector3(0, 0.95, 0), Vector3(lean, 0, 0))
    b.frustum(Vector3.ZERO, 0.72, 0.2, 0.14, 0.43, 0.23, 8, skin, Vector2.ZERO, 22.5, true)
    for k in range(5):
        b.box(Vector3(0, 0.12 + float(k) * 0.12, -0.14 - float(k) * 0.01), Vector3(0.22 + float(k) * 0.05, 0.014, 0.014), skin.darkened(0.3))
    b.box(Vector3(0, 0.4, -0.15), Vector3(0.014, 0.46, 0.014), skin.darkened(0.3))
    b.blob(Vector3(0, 0.62, 0.12), Vector3(0.3, 0.2, 0.2), skin.darkened(0.06), 3, 8)
    # pecs, abs, trapezius, back plates and a glowing vein network
    for sx in [-1.0, 1.0]:
        b.blob(Vector3(sx * 0.14, 0.5, -0.15), Vector3(0.14, 0.1, 0.07), skin.lightened(0.05), 3, 7)
        b.blob(Vector3(sx * 0.2, 0.7, 0.0), Vector3(0.12, 0.09, 0.12), skin.darkened(0.03), 3, 7)
        for k in range(3):
            b.blob(Vector3(sx * 0.05, 0.13 + float(k) * 0.1, -0.17), Vector3(0.05, 0.04, 0.03), skin.darkened(0.04), 2, 6)
        g.limb_between(Vector3(sx * 0.06, 0.62, -0.17), Vector3(sx * 0.14, 0.42, -0.19), 0.006, 0.004, glow_col.darkened(0.25), 4)
        g.limb_between(Vector3(sx * 0.14, 0.42, -0.19), Vector3(sx * 0.1, 0.22, -0.19), 0.005, 0.003, glow_col.darkened(0.25), 4)
    for k in range(4):
        b.spike_dir(Vector3(0, 0.45 + float(k) * 0.13, 0.2), Vector3(0, 0.55 + float(k) * 0.14, 0.33), 0.03, bone, 4)
    b.frustum(Vector3(0, 0.7, -0.02), 0.12, 0.1, 0.09, 0.09, 0.08, 6, skin.darkened(0.05), Vector2(0, -0.04), 0.0, false)
    var hc := Vector3(0, 0.92, -0.1)
    b.blob(hc, Vector3(0.17, 0.2, 0.18), skin.lightened(0.14), 4, 9, 0.8)
    for k in range(3):
        b.box(hc + Vector3(0, 0.1 - float(k) * 0.045, 0.0), Vector3(0.012, 0.012, 0.3 - float(k) * 0.03), skin.darkened(0.18))
    # maw
    b.box(hc + Vector3(0, -0.04, -0.17), Vector3(0.18, 0.15, 0.03), Color(0.1, 0.02, 0.02))
    g.box(hc + Vector3(0, -0.05, -0.185), Vector3(0.13, 0.1, 0.012), glow_col.darkened(0.25))
    for k in range(7):
        var tx := -0.075 + float(k) * 0.025
        b.spike_dir(hc + Vector3(tx, 0.03, -0.18), hc + Vector3(tx, -0.02, -0.19), 0.011, bone, 3)
        b.spike_dir(hc + Vector3(tx, -0.12, -0.18), hc + Vector3(tx, -0.07, -0.19), 0.011, bone, 3)
    if extras.has("horns"):
        for sx in [-1.0, 1.0]:
            b.spike_dir(hc + Vector3(sx * 0.12, 0.13, 0.0), hc + Vector3(sx * 0.26, 0.32, -0.1), 0.04, bone, 5)
    b.pop()
    g.pop()

    var sh_y := 0.95 + 0.62 * cos(deg_to_rad(lean))
    var sh_z := 0.62 * sin(deg_to_rad(lean))
    var limbs: Array = []
    for sx in [1.0, -1.0]:
        var a := _lp()
        a.blob(Vector3.ZERO, Vector3(0.15, 0.13, 0.14), skin, 3, 7)
        a.limb_between(Vector3.ZERO, Vector3(0, -0.55, 0), 0.115, 0.09, skin)
        a.limb_between(Vector3(0, -0.55, 0), Vector3(0, -1.05, 0), 0.09, 0.07, skin.darkened(0.08))
        a.blob(Vector3(0, -1.1, 0), Vector3(0.09, 0.1, 0.08), skin.darkened(0.12), 3, 6)
        a.blob(Vector3(0, -0.2, 0), Vector3(0.14, 0.17, 0.13), skin.lightened(0.04), 3, 7)
        a.blob(Vector3(0, -0.55, 0), Vector3(0.1, 0.1, 0.1), skin.darkened(0.1), 2, 6)
        for c in range(4):
            var cx := (float(c) - 1.5) * 0.045
            a.spike_dir(Vector3(cx, -1.14, -0.02), Vector3(cx * 1.4, -1.58, -0.14), 0.026, bone, 4)
        if extras.has("arm_blades"):
            for k in range(3):
                var y0 := -0.35 - float(k) * 0.22
                a.spike_dir(Vector3(sx * 0.1, y0, 0), Vector3(sx * 0.26, y0 - 0.2, 0.06), 0.03, bone, 4)
        limbs.append(_limb("ArmPivot", Vector3(sx * 0.46, sh_y, sh_z), a, null, -sx * 0.12))
    var legs: Array = []
    for sx in [-1.0, 1.0]:
        var l := _lp()
        l.limb_between(Vector3.ZERO, Vector3(0, -0.5, 0), 0.13, 0.1, skin.darkened(0.06))
        l.limb_between(Vector3(0, -0.5, 0), Vector3(0, -0.92, 0), 0.09, 0.07, skin)
        l.box(Vector3(0, -0.93, -0.07), Vector3(0.2, 0.08, 0.34), skin.darkened(0.2))
        l.blob(Vector3(0, -0.22, -0.02), Vector3(0.15, 0.2, 0.14), skin.lightened(0.03), 3, 7)
        l.blob(Vector3(0, -0.5, -0.04), Vector3(0.1, 0.09, 0.1), skin.darkened(0.12), 2, 6)
        for t in range(3):
            l.spike_dir(Vector3((float(t) - 1.0) * 0.06, -0.93, -0.22), Vector3((float(t) - 1.0) * 0.07, -0.95, -0.34), 0.02, bone, 3)
        legs.append(_limb("LegPivot", Vector3(sx * 0.17, 0.95, 0), l))
    limbs.append(legs[0])
    limbs.append(legs[1])
    return _finish(root, b, g, limbs, [0.3, 0.3, 0.0, 0.0], 0.8, 2.0, 0.6)

# ---------------------------------------------------------------- ogre (club-fist heavy)
static func _ogre(p: Dictionary) -> Dictionary:
    var skin: Color = p["skin"]
    var bone: Color = p["accent"]
    var cloth: Color = p["cloth"]
    var extras: Array = p.get("extras", [])
    var glow_col: Color = p.get("glow", Color(1.0, 0.45, 0.1))
    var root := Node3D.new()
    root.name = "Ogre"
    var b := _lp()
    var g := _lp()
    b.frustum(Vector3(0, 0.92, 0), 0.2, 0.34, 0.22, 0.38, 0.24, 8, skin.darkened(0.08), Vector2.ZERO, 22.5, false)
    b.box(Vector3(0, 0.98, -0.24), Vector3(0.5, 0.42, 0.05), cloth)
    b.box(Vector3(0, 0.98, 0.24), Vector3(0.5, 0.42, 0.05), cloth.darkened(0.1))
    b.box(Vector3(0, 1.17, 0), Vector3(0.78, 0.07, 0.5), cloth.darkened(0.3))
    b.blob(Vector3(0, 1.3, -0.1), Vector3(0.48, 0.42, 0.4), skin, 4, 9)
    b.push(Vector3(0, 1.35, 0), Vector3(-9, 0, 0))
    g.push(Vector3(0, 1.35, 0), Vector3(-9, 0, 0))
    b.frustum(Vector3.ZERO, 0.62, 0.42, 0.27, 0.58, 0.3, 8, skin, Vector2.ZERO, 22.5, true)
    for sx in [-1.0, 1.0]:
        b.blob(Vector3(sx * 0.22, 0.42, -0.2), Vector3(0.22, 0.14, 0.12), skin.lightened(0.06), 3, 7)
    b.frustum(Vector3(0, 0.6, 0), 0.1, 0.16, 0.14, 0.13, 0.12, 6, skin.darkened(0.05))
    b.blob(Vector3(0, 0.58, 0.0), Vector3(0.52, 0.13, 0.28), skin.darkened(0.02), 3, 9)
    # belly folds, pecs, scars, studs and a bone-bead chain
    for k in range(3):
        b.blob(Vector3(0, 0.12 + float(k) * 0.1, -0.27), Vector3(0.34 - 0.03 * float(k), 0.055, 0.06), skin.darkened(0.1), 2, 8)
    for sx in [-1.0, 1.0]:
        b.blob(Vector3(sx * 0.2, 0.36, -0.27), Vector3(0.17, 0.12, 0.08), skin.lightened(0.05), 3, 8)
        b.limb_between(Vector3(sx * 0.1, 0.5, -0.26), Vector3(sx * 0.3, 0.2, -0.28), 0.008, 0.008, Color(0.45, 0.16, 0.14), 4)
    for k in range(9):
        var ca2 := -1.2 + float(k) * 0.3
        b.blob(Vector3(sin(ca2) * 0.24, 0.52 - absf(ca2) * 0.09, -0.24 + (1.0 - absf(ca2)) * -0.02), Vector3(0.035, 0.04, 0.035), bone, 2, 5)
    var hc := Vector3(0, 0.86, -0.08)
    b.blob(hc, Vector3(0.16, 0.18, 0.17), skin, 4, 8, 0.85)
    b.box(hc + Vector3(0, 0.04, -0.14), Vector3(0.3, 0.05, 0.05), skin.darkened(0.2))
    _eyes(g, b, hc + Vector3(0, 0.0, -0.15), 0.06, glow_col if extras.has("forge") else Color(0.9, 0.85, 0.7).darkened(0.4), 0.025)
    b.box(hc + Vector3(0, -0.1, -0.1), Vector3(0.2, 0.06, 0.1), skin.darkened(0.1))
    for sx in [-1.0, 1.0]:
        b.spike_dir(hc + Vector3(sx * 0.07, -0.1, -0.16), hc + Vector3(sx * 0.09, 0.02, -0.19), 0.025, bone, 4)
        b.spike_dir(hc + Vector3(sx * 0.1, 0.14, 0.0), hc + Vector3(sx * 0.2, 0.34, -0.06), 0.035, bone, 5)
    for k in range(5):
        b.blob(hc + Vector3(-0.1 + float(k) * 0.05, 0.1 + float(k % 2) * 0.02, -0.12), Vector3(0.016, 0.014, 0.012), skin.darkened(0.15), 2, 5)
    if extras.has("crown"):
        for k in range(8):
            var a := float(k) * TAU / 8.0
            b.spike_dir(hc + Vector3(cos(a) * 0.12, 0.15, sin(a) * 0.12), hc + Vector3(cos(a) * 0.15, 0.34, sin(a) * 0.15), 0.025, Color(0.82, 0.68, 0.28), 4)
    if extras.has("horns"):
        for sx in [-1.0, 1.0]:
            b.spike_dir(hc + Vector3(sx * 0.13, 0.12, 0.0), hc + Vector3(sx * 0.36, 0.4, -0.12), 0.05, bone, 5)
    if extras.has("armor"):
        for sx in [-1.0, 1.0]:
            b.box(Vector3(sx * 0.5, 0.52, 0.0), Vector3(0.34, 0.1, 0.36), cloth.lightened(0.1))
            b.box(Vector3(sx * 0.52, 0.6, 0.0), Vector3(0.24, 0.08, 0.28), cloth.lightened(0.18))
        b.box(Vector3(0, 0.26, -0.3), Vector3(0.62, 0.4, 0.05), cloth.lightened(0.08))
    if extras.has("forge"):
        b.frustum(Vector3(0.2, 0.2, 0.3), 0.7, 0.12, 0.12, 0.09, 0.09, 6, Color(0.1, 0.09, 0.09))
        g.spike(Vector3(0.2, 0.84, 0.3), 0.34, 0.08, glow_col, 5)
        g.spike(Vector3(0.2, 0.84, 0.3), 0.22, 0.05, Color(1.0, 0.8, 0.3), 5, Vector2(0.03, 0.0))
    if extras.has("cracks"):
        for k in range(7):
            var cy := 0.05 + float(k) * 0.085
            g.box(Vector3(sin(float(k) * 2.3) * 0.18, cy, -0.3), Vector3(0.015, 0.1, 0.01), glow_col)
        g.box(Vector3(0, -0.28, -0.37), Vector3(0.012, 0.3, 0.01), glow_col)
        g.box(Vector3(-0.12, -0.3, -0.4), Vector3(0.1, 0.012, 0.01), glow_col)
    b.pop()
    g.pop()

    var big_right := true
    var limbs: Array = []
    for sx in [1.0, -1.0]:
        var a := _lp()
        var giant: bool = (sx > 0.0 and big_right) or extras.has("both_fists")
        a.blob(Vector3.ZERO, Vector3(0.25, 0.2, 0.22), skin, 3, 7)
        if giant:
            a.limb_between(Vector3.ZERO, Vector3(0, -0.6, 0), 0.17, 0.15, skin)
            a.limb_between(Vector3(0, -0.6, 0), Vector3(0, -1.2, 0), 0.17, 0.3, skin.darkened(0.06))
            if extras.has("hammer"):
                a.limb_between(Vector3(0, -1.0, 0), Vector3(0, -1.7, 0), 0.07, 0.06, Color(0.2, 0.15, 0.1), 6)
                a.box(Vector3(0, -1.78, -0.05), Vector3(0.62, 0.42, 0.42), Color(0.16, 0.15, 0.15))
                a.box(Vector3(0, -1.78, -0.05), Vector3(0.7, 0.1, 0.5), Color(0.1, 0.1, 0.1))
                var gg := _lp()
                gg.box(Vector3(0, -1.78, -0.272), Vector3(0.5, 0.26, 0.012), glow_col)
                a.blob(Vector3(0, -1.0, 0), Vector3(0.16, 0.16, 0.16), skin.darkened(0.1), 2, 6)
                limbs.append(_limb("ArmPivot", Vector3(sx * 0.7, 1.9, 0), a, gg, -sx * 0.1))
                continue
            a.blob(Vector3(0, -1.4, 0), Vector3(0.38, 0.34, 0.36), skin.darkened(0.04), 3, 8)
            for k in range(8):
                var ang := float(k) * TAU / 8.0
                var dirv := Vector3(cos(ang), sin(ang * 2.0) * 0.4, sin(ang)).normalized()
                var centre := Vector3(0, -1.4, 0)
                a.spike_dir(centre + dirv * 0.3, centre + dirv * 0.66, 0.045, bone, 4)
        else:
            a.limb_between(Vector3.ZERO, Vector3(0, -0.55, 0), 0.14, 0.11, skin)
            a.limb_between(Vector3(0, -0.55, 0), Vector3(0, -1.05, 0), 0.11, 0.1, skin.darkened(0.05))
            a.blob(Vector3(0, -1.12, 0), Vector3(0.12, 0.13, 0.1), skin.darkened(0.1), 3, 6)
        limbs.append(_limb("ArmPivot", Vector3(sx * 0.7, 1.9, 0), a, null, -sx * 0.1))
    var legs: Array = []
    for sx in [-1.0, 1.0]:
        var l := _lp()
        l.limb_between(Vector3.ZERO, Vector3(0, -0.55, 0), 0.17, 0.13, skin.darkened(0.05))
        l.limb_between(Vector3(0, -0.55, 0), Vector3(0, -1.02, 0), 0.12, 0.095, skin.darkened(0.1))
        l.box(Vector3(0, -1.03, -0.07), Vector3(0.26, 0.1, 0.38), skin.darkened(0.2))
        l.blob(Vector3(0, -0.2, -0.02), Vector3(0.2, 0.28, 0.18), skin.lightened(0.02), 3, 8)
        l.blob(Vector3(0, -0.55, -0.06), Vector3(0.13, 0.11, 0.12), skin.darkened(0.14), 2, 6)
        for t in range(3):
            l.spike_dir(Vector3((float(t) - 1.0) * 0.08, -1.03, -0.24), Vector3((float(t) - 1.0) * 0.09, -1.05, -0.36), 0.03, bone, 3)
        legs.append(_limb("LegPivot", Vector3(sx * 0.22, 1.05, 0), l))
    limbs.append(legs[0])
    limbs.append(legs[1])
    return _finish(root, b, g, limbs, [0.12, 0.12, 0.0, 0.0], 0.55, 2.7, 0.75)
