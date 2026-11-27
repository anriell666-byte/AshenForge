extends RefCounted
## Hero built from the AFTERFALL hero customization kit (blockout GLBs, Z up, facing -Y).
## Every kit file has the same part slots, so a hero is assembled by picking each slot
## from the file that carries the wanted variant (head shape, hair, expression, outfit).

const HB = preload("res://scripts/human_builder.gd")
const GM = preload("res://scripts/gear_models.gd")
const ID = preload("res://scripts/items_data.gd")

const DIR := "res://assets/models/kit/"
const HEAD_SHAPES := ["standard", "broad", "broad", "slim"]        # indexed by the "face" option
const HAIR_FILES := ["", "short", "short", "short", "long", "ponytail", "mohawk"]   # by hair_style
const FACES := ["neutral", "smile", "stern"]                          # by the "mouth" option
static var ROT := Basis.from_euler(Vector3(-PI / 2.0, PI, 0.0))                       # kit space -> game space (Y up, faces -Z)
const BODY_SCALE := 0.9

const SKIN_PARTS := [2, 3, 7, 9, 13, 15]
const PANTS_PARTS := [1, 4, 10]
const SHOE_PARTS := [5, 11]
const EYE_PARTS := [8, 14]
const TOP_PARTS := [0, 6, 12]
const ARM_R := [6, 7]
const ARM_L := [12, 13]
const LEG_L := [10, 11]
const LEG_R := [4, 5]

static func has_assets() -> bool:
    return ResourceLoader.exists(DIR + "hero_male_standard.glb") and ResourceLoader.exists(DIR + "hero_female_standard.glb")

static func _parts_of(file: String) -> Dictionary:
    var scene := load(DIR + file + ".glb") as PackedScene
    var root: Node = scene.instantiate()
    var d := {}
    for c in root.find_children("*", "MeshInstance3D", true, false):
        var m := c as MeshInstance3D
        m.get_parent().remove_child(m)
        var n := String(m.name).trim_prefix("part_")
        d[int(n)] = m
    root.free()
    return d

static func _paint(m: MeshInstance3D, col: Color, flat: bool = true) -> void:
    var mat := StandardMaterial3D.new()
    mat.roughness = 0.92
    if flat:
        mat.albedo_color = col
    else:
        mat.vertex_color_use_as_albedo = true
    m.set_surface_override_material(0, mat)

## Returns {"model": Node3D, "limbs": [arm R, arm L, leg L, leg R], "rest": [...]}, same as HumanBuilder.build.
static func build(raw_opts: Dictionary, gear: Dictionary = {}) -> Dictionary:
    var o := HB.sanitize(raw_opts)
    var g := "female" if int(o["gender"]) == 1 else "male"
    var shape: String = HEAD_SHAPES[clampi(int(o["face"]), 0, 3)]
    var skin: Color = HB.SKIN[int(o["skin"])]
    var hair_col: Color = HB.HAIR[int(o["hair_color"])]
    var top_col: Color = HB.CLOTH[int(o["top_color"])]
    var pants_col: Color = HB.PANTS[int(o["bottom_color"])]
    var shoe_col: Color = HB.SHOES[int(o["shoes_color"])]
    var eye_col: Color = HB.EYES[int(o["eyes"])]
    var outfit := "hoodie" if int(o["top"]) == 0 else "survivor_jacket"
    var plated := false

    var body_gear: Dictionary = ID.item(String(gear.get("body", "")))
    if not body_gear.is_empty():
        var look := String(body_gear["look"])
        top_col = body_gear["color"]
        if look == "jacket":
            outfit = "survivor_jacket"
        else:
            outfit = "tactical_vest"
            plated = look == "plate"
    var legs_gear: Dictionary = ID.item(String(gear.get("legs", "")))
    if not legs_gear.is_empty():
        pants_col = legs_gear["color"]
    var feet_gear: Dictionary = ID.item(String(gear.get("feet", "")))
    if not feet_gear.is_empty():
        shoe_col = feet_gear["color"]
    var head_gear: Dictionary = ID.item(String(gear.get("head", "")))
    var hat_on: bool = not head_gear.is_empty() and String(head_gear["look"]) != "cap"

    # --- pick every slot from the right file
    var parts: Dictionary = _parts_of("hero_%s_%s" % [g, shape])
    var style := int(o["hair_style"])
    var hair_extra: Array = []
    if style > 0:
        var hf: Dictionary = _parts_of("hair_%s_%s" % [g, HAIR_FILES[style]])
        _swap(parts, hf, 19)
        for k in hf:
            if int(k) >= 20:
                hair_extra.append(hf[k])
        for k in hf:
            if int(k) < 20 and int(k) != 19:
                (hf[k] as MeshInstance3D).free()
    else:
        (parts[19] as MeshInstance3D).free()
        parts.erase(19)
    var ff: Dictionary = _parts_of("face_%s_%s" % [g, FACES[clampi(int(o["mouth"]), 0, 2)]])
    _swap(parts, ff, 17)
    for k in ff:
        if int(k) != 17:
            (ff[k] as MeshInstance3D).free()
    var of: Dictionary = _parts_of("outfit_%s_%s" % [g, outfit])
    for k in TOP_PARTS:
        _swap(parts, of, k)
    var outfit_extra: Array = []
    for k in of:
        if int(k) >= 20:
            outfit_extra.append(of[k])
        elif not TOP_PARTS.has(int(k)):
            (of[k] as MeshInstance3D).free()

    # --- colours
    for k in parts:
        var m := parts[k] as MeshInstance3D
        var i := int(k)
        if SKIN_PARTS.has(i):
            _paint(m, skin)
        elif i == 16:
            _paint(m, skin.darkened(0.12))
        elif PANTS_PARTS.has(i):
            _paint(m, pants_col)
        elif SHOE_PARTS.has(i):
            _paint(m, shoe_col)
        elif EYE_PARTS.has(i):
            _paint(m, Color(0.08, 0.08, 0.08).lerp(eye_col, 0.25))
        elif TOP_PARTS.has(i):
            _paint(m, top_col)
        elif i == 19:
            _paint(m, hair_col)
        else:
            _paint(m, Color.WHITE, false)
    for m in hair_extra:
        _paint(m, hair_col)
    for m in outfit_extra:
        _paint(m, Color.WHITE, false)

    # --- assemble: torso parts sit on the body, limbs get pivots at shoulder / hip
    var root := Node3D.new()
    root.name = "KitHero"
    var body := Node3D.new()
    body.name = "KitBody"
    root.add_child(body)
    var limb_sets := {"arm_r": ARM_R, "arm_l": ARM_L, "leg_l": LEG_L, "leg_r": LEG_R}
    var in_limb := {}
    for key in limb_sets:
        for k in limb_sets[key]:
            in_limb[k] = key
    var pivots := {}
    var hand_center := {}
    for key in limb_sets:
        var bb := AABB()
        var first := true
        for k in limb_sets[key]:
            var a: AABB = (parts[k] as MeshInstance3D).get_aabb()
            bb = a if first else bb.merge(a)
            first = false
        var pm := Vector3(bb.get_center().x, bb.get_center().y, bb.end.z - (0.06 if key.begins_with("arm") else 0.03))
        var pivot := Node3D.new()
        pivot.name = "Limb_" + key
        pivot.position = ROT * pm
        body.add_child(pivot)
        pivots[key] = [pivot, pm]
        for k in limb_sets[key]:
            var m := parts[k] as MeshInstance3D
            m.transform = Transform3D(ROT, ROT * (-pm))
            pivot.add_child(m)
        hand_center[key] = ROT * (Vector3(bb.get_center().x, bb.get_center().y, bb.position.z + 0.09) - pm)
    for k in parts:
        if in_limb.has(k):
            continue
        var m := parts[k] as MeshInstance3D
        m.transform = Transform3D(ROT, Vector3.ZERO)
        if hat_on and (k == 19):
            m.visible = false
        body.add_child(m)
    for m in hair_extra:
        (m as MeshInstance3D).transform = Transform3D(ROT, Vector3.ZERO)
        (m as MeshInstance3D).visible = not hat_on
        body.add_child(m)
    for m in outfit_extra:
        (m as MeshInstance3D).transform = Transform3D(ROT, Vector3.ZERO)
        body.add_child(m)

    _attach_gear(body, pivots, hand_center, gear, head_gear, plated, top_col)

    var bw: float = [0.92, 1.0, 1.1][int(o["build"])]
    body.scale = Vector3(BODY_SCALE * bw, BODY_SCALE, BODY_SCALE * bw)
    var limbs: Array = [pivots["arm_r"][0], pivots["arm_l"][0], pivots["leg_l"][0], pivots["leg_r"][0]]
    return {"model": root, "limbs": limbs, "rest": [0.0, 0.0, 0.0, 0.0], "anim": null, "clips": {}, "height": 1.8}

static func _swap(parts: Dictionary, donor: Dictionary, k: int) -> void:
    if not donor.has(k):
        return
    if parts.has(k):
        (parts[k] as MeshInstance3D).free()
    parts[k] = donor[k]
    donor.erase(k)

static func _attach_gear(body: Node3D, pivots: Dictionary, hand_center: Dictionary, gear: Dictionary, head_gear: Dictionary, plated: bool, vest_col: Color) -> void:
    var held := String(gear.get("weapon", ""))
    if held == "":
        held = String(gear.get("tool", ""))
    if held != "":
        var item := GM.hand_item(held)
        if item != null:
            var arm: Node3D = pivots["arm_r"][0]
            item.position = hand_center["arm_r"]
            item.rotation = Vector3(-1.45, 0.0, 0.0)
            item.scale = Vector3.ONE * 1.15
            arm.add_child(item)
    if not head_gear.is_empty():
        var h := GM.head_item(String(head_gear["look"]), head_gear["color"])
        if h != null:
            h.position = Vector3(0, 1.6, 0.0)
            h.scale = Vector3.ONE * 2.0
            body.add_child(h)
    var bg: Dictionary = ID.item(String(gear.get("back", "")))
    if not bg.is_empty():
        var p := GM.back_item(String(bg["look"]), bg["color"])
        if p != null:
            p.position = Vector3(0, 1.0, 0.24)
            p.scale = Vector3.ONE * 1.4
            body.add_child(p)
    if plated:
        for key in ["arm_r", "arm_l"]:
            var pad := GM.shoulder_pad(vest_col)
            pad.position = Vector3(0, 0.05, 0)
            pad.scale = Vector3.ONE * 1.6
            (pivots[key][0] as Node3D).add_child(pad)
