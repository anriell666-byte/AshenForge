extends RefCounted
## Procedural low-poly models for hand-held items and worn gear.
## Hand items: origin at the grip, the business end points along +Y, the "front" faces -Z.
## Head items: origin at the middle of the skull, front faces -Z (same frame as hair/glasses).

const LP = preload("res://scripts/lowpoly.gd")

const WOOD := Color(0.5, 0.33, 0.17)
const DARK_WOOD := Color(0.34, 0.22, 0.12)
const STEEL := Color(0.68, 0.7, 0.72)
const DARK_STEEL := Color(0.3, 0.32, 0.34)
const RUST := Color(0.5, 0.3, 0.2)
const CLOTH := Color(0.55, 0.5, 0.4)

static func _new() -> Object:
    var b = LP.new()
    b.jitter = 0.05
    return b

## Returns a Node3D for the item id, or null when it has no model.
static func hand_item(id: String) -> Node3D:
    var b = _new()
    var glow = null
    match id:
        "club":
            b.frustum(Vector3(0, -0.1, 0), 0.9, 0.03, 0.03, 0.065, 0.065, 8, WOOD)
            for k in range(5):
                var a := float(k) * 1.26
                b.spike_dir(Vector3(cos(a) * 0.06, 0.55 + float(k) * 0.05, sin(a) * 0.06), Vector3(cos(a) * 0.115, 0.55 + float(k) * 0.05, sin(a) * 0.115), 0.012, STEEL, 4)
        "machete":
            b.box(Vector3(0, 0.02, 0), Vector3(0.04, 0.16, 0.04), DARK_WOOD)
            b.box(Vector3(0, 0.34, 0), Vector3(0.012, 0.5, 0.085), STEEL)
            b.box(Vector3(0, 0.62, -0.012), Vector3(0.012, 0.1, 0.1), STEEL)
            b.box(Vector3(0, 0.12, 0), Vector3(0.05, 0.02, 0.07), DARK_STEEL)
        "spear":
            b.limb_between(Vector3(0, -0.5, 0), Vector3(0, 1.3, 0), 0.022, 0.02, WOOD, 6)
            b.spike_dir(Vector3(0, 1.3, 0), Vector3(0, 1.62, 0), 0.05, STEEL, 4)
            b.box(Vector3(0, 1.28, 0), Vector3(0.05, 0.04, 0.05), CLOTH)
        "sling":
            b.limb_between(Vector3(0, 0, 0), Vector3(0, 0.22, 0), 0.02, 0.02, WOOD, 5)
            b.limb_between(Vector3(0, 0.22, 0), Vector3(-0.07, 0.34, 0), 0.015, 0.015, WOOD, 5)
            b.limb_between(Vector3(0, 0.22, 0), Vector3(0.07, 0.34, 0), 0.015, 0.015, WOOD, 5)
            b.blob(Vector3(0, 0.3, 0), Vector3(0.05, 0.03, 0.04), CLOTH, 2, 6)
        "bow", "crossbow":
            if id == "bow":
                var prev := Vector3(0, -0.5, 0)
                for k in range(1, 9):
                    var t := float(k) / 8.0
                    var p := Vector3(0, -0.5 + t, -sin(t * PI) * 0.16)
                    b.limb_between(prev, p, 0.018, 0.018, WOOD, 5)
                    prev = p
                b.limb_between(Vector3(0, -0.5, 0), Vector3(0, 0.5, 0), 0.004, 0.004, CLOTH.lightened(0.3), 3)
            else:
                b.box(Vector3(0, 0.2, 0), Vector3(0.06, 0.62, 0.07), DARK_WOOD)
                b.box(Vector3(0, 0.5, 0), Vector3(0.62, 0.035, 0.05), DARK_STEEL)
                b.limb_between(Vector3(-0.31, 0.5, 0), Vector3(0.31, 0.5, 0), 0.004, 0.004, CLOTH.lightened(0.3), 3)
                b.spike_dir(Vector3(0, 0.3, 0), Vector3(0, 0.62, 0), 0.015, STEEL, 4)
        "fire_axe":
            b.limb_between(Vector3(0, -0.2, 0), Vector3(0, 0.82, 0), 0.025, 0.025, WOOD, 6)
            b.box(Vector3(0, 0.78, -0.07), Vector3(0.05, 0.2, 0.2), Color(0.75, 0.15, 0.12))
            b.box(Vector3(0, 0.78, 0.04), Vector3(0.05, 0.12, 0.08), DARK_STEEL)
            b.box(Vector3(0, 0.74, -0.18), Vector3(0.015, 0.26, 0.04), STEEL)
        "hatchet":
            b.limb_between(Vector3(0, -0.15, 0), Vector3(0, 0.55, 0), 0.022, 0.022, WOOD, 6)
            b.box(Vector3(0, 0.52, -0.05), Vector3(0.035, 0.14, 0.14), DARK_STEEL)
            b.box(Vector3(0, 0.52, -0.13), Vector3(0.012, 0.19, 0.03), STEEL)
        "pickaxe":
            b.limb_between(Vector3(0, -0.2, 0), Vector3(0, 0.8, 0), 0.025, 0.025, WOOD, 6)
            b.spike_dir(Vector3(-0.28, 0.76, 0), Vector3(0.28, 0.76, 0), 0.03, DARK_STEEL, 4)
            b.box(Vector3(0, 0.78, 0), Vector3(0.1, 0.07, 0.05), DARK_STEEL)
        "crowbar":
            b.limb_between(Vector3(0, -0.05, 0), Vector3(0, 0.62, 0), 0.016, 0.016, Color(0.55, 0.12, 0.1), 6)
            b.spike_dir(Vector3(0, 0.62, 0), Vector3(0.05, 0.72, -0.1), 0.016, Color(0.55, 0.12, 0.1), 5)
        "sledgehammer":
            b.limb_between(Vector3(0, -0.25, 0), Vector3(0, 0.95, 0), 0.027, 0.027, WOOD, 6)
            b.box(Vector3(0, 0.98, 0), Vector3(0.12, 0.14, 0.3), DARK_STEEL)
            b.box(Vector3(0, 0.98, -0.14), Vector3(0.14, 0.15, 0.04), STEEL)
            b.box(Vector3(0, 0.98, 0.14), Vector3(0.14, 0.15, 0.04), STEEL)
        "shock_baton":
            b.limb_between(Vector3(0, -0.08, 0), Vector3(0, 0.55, 0), 0.025, 0.03, Color(0.12, 0.12, 0.14), 6)
            b.box(Vector3(0, 0.03, 0), Vector3(0.06, 0.04, 0.06), DARK_STEEL)
            glow = _new()
            glow.blob(Vector3(0, 0.6, 0), Vector3(0.045, 0.07, 0.045), Color(0.4, 0.8, 1.0), 2, 6)
        "chainsaw":
            b.box(Vector3(0, 0.05, 0), Vector3(0.14, 0.3, 0.2), Color(0.9, 0.5, 0.1))
            b.box(Vector3(0, 0.07, -0.03), Vector3(0.09, 0.09, 0.2), DARK_STEEL)
            b.box(Vector3(0, 0.45, -0.1), Vector3(0.025, 0.55, 0.07), STEEL)
            b.box(Vector3(0, 0.45, -0.1), Vector3(0.03, 0.5, 0.025), DARK_STEEL)
        "flamethrower":
            b.limb_between(Vector3(0, 0.0, 0), Vector3(0, 0.55, -0.08), 0.03, 0.025, DARK_STEEL, 6)
            b.blob(Vector3(0, 0.62, -0.1), Vector3(0.04, 0.05, 0.04), Color(0.9, 0.45, 0.1), 2, 6)
            b.frustum(Vector3(0, -0.1, 0.17), 0.5, 0.07, 0.07, 0.07, 0.07, 8, Color(0.75, 0.2, 0.15))
            glow = _new()
            glow.blob(Vector3(0, 0.68, -0.11), Vector3(0.03, 0.04, 0.03), Color(1.0, 0.7, 0.2), 2, 6)
        _:
            return null
    var node: Node3D = b.to_node("Held_" + id)
    if glow != null and not glow.is_empty():
        node.add_child(glow.to_node("HeldGlow", LP.glow_material()))
    return node

## Head gear in the skull frame.
static func head_item(id: String, color: Color) -> Node3D:
    var b = _new()
    b.smooth = true
    match id:
        "cap":
            b.blob(Vector3(0, 0.07, 0.0), Vector3(0.125, 0.085, 0.135), color, 3, 9)
            b.box(Vector3(0, 0.035, -0.135), Vector3(0.17, 0.014, 0.09), color.darkened(0.15))
        "helmet":
            b.blob(Vector3(0, 0.06, 0.0), Vector3(0.14, 0.1, 0.15), color, 3, 9)
            b.box(Vector3(0, 0.02, -0.0), Vector3(0.3, 0.014, 0.32), color.darkened(0.12))
            b.box(Vector3(0, 0.13, 0.0), Vector3(0.035, 0.03, 0.2), color.darkened(0.2))
        "riot":
            b.blob(Vector3(0, 0.05, 0.01), Vector3(0.15, 0.12, 0.16), color, 3, 10)
            b.box(Vector3(0, 0.0, -0.13), Vector3(0.22, 0.09, 0.03), Color(0.08, 0.12, 0.16))
            b.box(Vector3(0, -0.07, 0.04), Vector3(0.3, 0.1, 0.2), color.lightened(0.05))
        _:
            return null
    return b.to_node("Head_" + id)

## Backpacks in a frame where +Z points out of the back and +Y is up.
static func back_item(id: String, color: Color) -> Node3D:
    var b = _new()
    match id:
        "pack_small":
            b.box(Vector3(0, 0, 0.0), Vector3(0.28, 0.36, 0.14), color)
            b.box(Vector3(0, -0.05, 0.09), Vector3(0.2, 0.14, 0.05), color.darkened(0.15))
            b.box(Vector3(0, 0.16, 0.0), Vector3(0.24, 0.05, 0.12), color.lightened(0.1))
        "pack_big":
            b.box(Vector3(0, 0.0, 0.0), Vector3(0.34, 0.52, 0.2), color)
            b.box(Vector3(0, -0.1, 0.13), Vector3(0.26, 0.22, 0.07), color.darkened(0.15))
            b.box(Vector3(0, 0.27, 0.0), Vector3(0.3, 0.07, 0.17), color.lightened(0.12))
            b.box(Vector3(-0.2, -0.05, 0.0), Vector3(0.07, 0.24, 0.12), color.darkened(0.2))
            b.box(Vector3(0.2, -0.05, 0.0), Vector3(0.07, 0.24, 0.12), color.darkened(0.2))
            b.box(Vector3(0, -0.32, 0.0), Vector3(0.28, 0.12, 0.17), Color(0.2, 0.2, 0.2))
        _:
            return null
    return b.to_node("Back_" + id)

static func shoulder_pad(color: Color) -> Node3D:
    var b = _new()
    b.smooth = true
    b.blob(Vector3(0, 0, 0), Vector3(0.1, 0.06, 0.1), color, 3, 8)
    return b.to_node("Pad")

## Hair for the hero in the skull frame (smooth, hugs the head). style: 1 short, 2 parting,
## 3 undercut, 4 long, 5 ponytail, 6 mohawk.
static func hair(style: int, color: Color) -> Node3D:
    if style <= 0:
        return null
    var b = _new()
    b.smooth = true
    b.jitter = 0.04
    var dark := color.darkened(0.18)
    var light := color.lightened(0.1)
    if style == 3 or style == 6:
        # shaved sides read as stubble
        b.blob(Vector3(0, 0.07, 0.015), Vector3(0.116, 0.09, 0.126), color.lerp(Color(0.18, 0.15, 0.13), 0.55), 3, 9)
    else:
        b.blob(Vector3(0, 0.08, 0.012), Vector3(0.12, 0.094, 0.13), color, 3, 9)
        b.blob(Vector3(0, -0.005, 0.06), Vector3(0.102, 0.088, 0.075), dark, 3, 9)
    match style:
        1:
            b.blob(Vector3(0, 0.108, -0.075), Vector3(0.1, 0.03, 0.045), color, 3, 8)
            for k in range(-3, 4):
                b.spike_dir(Vector3(float(k) * 0.028, 0.115, -0.085), Vector3(float(k) * 0.03, 0.082 - absf(float(k)) * 0.004, -0.112 + absf(float(k)) * 0.01), 0.018, color, 4)
            for sx in [-1.0, 1.0]:
                b.blob(Vector3(sx * 0.108, 0.01, -0.025), Vector3(0.012, 0.045, 0.034), dark, 2, 6)
        2:
            b.blob(Vector3(0.0, 0.118, -0.02), Vector3(0.1, 0.04, 0.1), light, 3, 8)
            for k in range(5):
                var x0 := -0.03 + float(k) * 0.02
                b.spike_dir(Vector3(x0 - 0.05, 0.135, -0.03), Vector3(x0 + 0.075, 0.075 - float(k) * 0.004, -0.098 - float(k) * 0.003), 0.024, color if k % 2 == 0 else light, 5)
            for sx in [-1.0, 1.0]:
                b.blob(Vector3(sx * 0.108, 0.0, -0.02), Vector3(0.012, 0.05, 0.034), dark, 2, 6)
        3:
            b.blob(Vector3(0, 0.115, -0.015), Vector3(0.08, 0.06, 0.105), color, 3, 8)
            b.blob(Vector3(0, 0.14, 0.0), Vector3(0.052, 0.04, 0.095), light, 2, 8)
            b.blob(Vector3(0, 0.112, -0.08), Vector3(0.07, 0.03, 0.04), color, 2, 7)
        4:
            b.blob(Vector3(0, -0.1, 0.082), Vector3(0.115, 0.15, 0.065), dark, 3, 9)
            b.blob(Vector3(0, -0.23, 0.085), Vector3(0.1, 0.11, 0.055), color.darkened(0.1), 3, 8)
            b.blob(Vector3(0, 0.108, -0.07), Vector3(0.105, 0.032, 0.05), color, 3, 8)
            for sx in [-1.0, 1.0]:
                b.blob(Vector3(sx * 0.108, -0.07, 0.0), Vector3(0.026, 0.115, 0.06), color, 2, 8)
                b.spike_dir(Vector3(sx * 0.02, 0.118, -0.075), Vector3(sx * 0.1, 0.0, -0.085), 0.02, color, 4)
        5:
            b.blob(Vector3(0, 0.108, -0.072), Vector3(0.1, 0.03, 0.045), color, 3, 8)
            b.limb_between(Vector3(0, 0.08, 0.1), Vector3(0, -0.02, 0.19), 0.045, 0.04, color, 7)
            b.limb_between(Vector3(0, -0.02, 0.19), Vector3(0, -0.2, 0.2), 0.04, 0.018, dark, 7)
            b.blob(Vector3(0, 0.07, 0.115), Vector3(0.03, 0.03, 0.03), Color(0.7, 0.2, 0.2), 2, 6)
        6:
            for k in range(9):
                var z := -0.1 + float(k) * 0.025
                var h := 0.12 - absf(float(k) - 4.0) * 0.01
                b.spike_dir(Vector3(0, 0.14, z), Vector3(0, 0.14 + h, z + 0.012), 0.032, color if k % 2 == 0 else light, 5)
    return b.to_node("Hair")

## Wounds, blood and a missing patch of hair on a zombie head (skull frame).
static func zombie_head(seed_value: int, blood: Color) -> Node3D:
    var b = _new()
    b.smooth = true
    var side := 1.0 if seed_value % 2 == 0 else -1.0
    # blood around the mouth and chin
    b.blob(Vector3(0, -0.07, -0.085), Vector3(0.05, 0.032, 0.02), blood, 2, 7)
    b.blob(Vector3(0.012, -0.11, -0.075), Vector3(0.012, 0.04, 0.012), blood, 2, 5)
    b.blob(Vector3(-0.025, -0.1, -0.07), Vector3(0.009, 0.03, 0.01), blood, 2, 5)
    # cheek wound with a bone showing
    b.blob(Vector3(side * 0.068, -0.012, -0.09), Vector3(0.034, 0.028, 0.012), blood.darkened(0.25), 2, 7)
    b.spike_dir(Vector3(side * 0.07, -0.02, -0.1), Vector3(side * 0.062, 0.0, -0.118), 0.008, Color(0.85, 0.82, 0.7), 4)
    # sunken dark eye sockets
    for sx in [-1.0, 1.0]:
        b.blob(Vector3(sx * 0.044, 0.016, -0.094), Vector3(0.027, 0.02, 0.012), Color(0.1, 0.07, 0.07), 2, 6)
    # scalp wound
    b.blob(Vector3(-side * 0.05, 0.1, -0.03), Vector3(0.04, 0.02, 0.05), blood.darkened(0.15), 2, 6)
    return b.to_node("ZombieHead")
