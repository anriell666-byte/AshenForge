extends RefCounted
## Procedural low-poly human. Everything the character creator exposes lives in
## the `opts` dictionary, so the same data builds the preview and the in-game model.

const LP = preload("res://scripts/lowpoly.gd")

const SKIN := [Color("f2cdb0"), Color("e3b08a"), Color("c98f66"), Color("a06a48"), Color("74492f"), Color("4d3022")]
const HAIR := [Color("17120f"), Color("3b2619"), Color("5d3d24"), Color("c9a25a"), Color("a8481f"), Color("a9a9a4"), Color("e6e4de"), Color("2d4f7c")]
const CLOTH := [Color("d9d6cc"), Color("c0392b"), Color("3b6ea5"), Color("5f7f3a"), Color("d6a21e"), Color("2f2f34"), Color("7a4b9a"), Color("3a8a7e"), Color("8a5a3a"), Color("e07b9b")]
const PANTS := [Color("2a8bc9"), Color("2f3a4a"), Color("3d4a3a"), Color("4a3a2e"), Color("1f1f23"), Color("7a7568"), Color("6b2f2f"), Color("c8b78a")]
const SHOES := [Color("f0f0ee"), Color("1c1c1f"), Color("4a3226"), Color("8a2f2f"), Color("2f4a6b"), Color("6b6b66")]

const GENDER_NAMES := ["Мужской", "Женский"]
const BUILD_NAMES := ["Худощавое", "Обычное", "Крепкое"]
const HAIR_STYLE_NAMES := ["Лысый", "Короткая", "Пробор", "Андеркат", "Длинные", "Хвост", "Ирокез"]
const BEARD_NAMES := ["Нет", "Щетина", "Борода", "Эспаньолка"]
const TOP_NAMES := ["Футболка", "Рубашка", "Куртка"]
const BOTTOM_NAMES := ["Штаны", "Шорты"]
const EYES := [Color("3b2a1c"), Color("5d7a3a"), Color("3b6ea5"), Color("7a8a94"), Color("8a5a2a"), Color("2f6b5e")]
const FACE_NAMES := ["Овальное", "Круглое", "Квадратное", "Узкое"]
const BROW_NAMES := ["Тонкие", "Обычные", "Густые"]
const NOSE_NAMES := ["Маленький", "Средний", "Крупный", "Курносый"]
const MOUTH_NAMES := ["Спокойный", "Улыбка", "Суровый"]
const MARK_NAMES := ["Нет", "Веснушки", "Шрам", "Родинка"]

static func default_options() -> Dictionary:
    return {
        "gender": 0, "build": 1, "skin": 1,
        "hair_style": 1, "hair_color": 2, "beard": 0, "glasses": false,
        "top": 2, "top_color": 3, "bottom": 0, "bottom_color": 2, "shoes_color": 1,
        "face": 0, "eyes": 0, "brows": 1, "nose": 1, "mouth": 0, "mark": 0,
    }

static func random_options(rng: RandomNumberGenerator = null) -> Dictionary:
    if rng == null:
        rng = RandomNumberGenerator.new()
        rng.randomize()
    var female := rng.randi_range(0, 1)
    var o := default_options()
    o["gender"] = female
    o["build"] = rng.randi_range(0, 2)
    o["skin"] = rng.randi_range(0, SKIN.size() - 1)
    o["hair_style"] = rng.randi_range(1, HAIR_STYLE_NAMES.size() - 1) if female == 1 else rng.randi_range(0, HAIR_STYLE_NAMES.size() - 1)
    o["hair_color"] = rng.randi_range(0, HAIR.size() - 1)
    o["beard"] = 0 if female == 1 else rng.randi_range(0, BEARD_NAMES.size() - 1)
    o["glasses"] = rng.randf() < 0.3
    o["face"] = rng.randi_range(0, FACE_NAMES.size() - 1)
    o["eyes"] = rng.randi_range(0, EYES.size() - 1)
    o["brows"] = rng.randi_range(0, BROW_NAMES.size() - 1)
    o["nose"] = rng.randi_range(0, NOSE_NAMES.size() - 1)
    o["mouth"] = rng.randi_range(0, MOUTH_NAMES.size() - 1)
    o["mark"] = rng.randi_range(0, MARK_NAMES.size() - 1)
    o["top"] = rng.randi_range(0, TOP_NAMES.size() - 1)
    o["top_color"] = rng.randi_range(0, CLOTH.size() - 1)
    o["bottom"] = rng.randi_range(0, BOTTOM_NAMES.size() - 1)
    o["bottom_color"] = rng.randi_range(0, PANTS.size() - 1)
    o["shoes_color"] = rng.randi_range(0, SHOES.size() - 1)
    return o

## Fills missing keys and clamps every index, so old or hand-edited saves never crash the builder.
static func sanitize(raw: Dictionary) -> Dictionary:
    var o := default_options()
    for key in o:
        if raw.has(key):
            o[key] = raw[key]
    o["gender"] = clampi(int(o["gender"]), 0, 1)
    o["build"] = clampi(int(o["build"]), 0, 2)
    o["skin"] = clampi(int(o["skin"]), 0, SKIN.size() - 1)
    o["hair_style"] = clampi(int(o["hair_style"]), 0, HAIR_STYLE_NAMES.size() - 1)
    o["hair_color"] = clampi(int(o["hair_color"]), 0, HAIR.size() - 1)
    o["beard"] = clampi(int(o["beard"]), 0, BEARD_NAMES.size() - 1)
    o["glasses"] = bool(o["glasses"])
    o["face"] = clampi(int(o["face"]), 0, FACE_NAMES.size() - 1)
    o["eyes"] = clampi(int(o["eyes"]), 0, EYES.size() - 1)
    o["brows"] = clampi(int(o["brows"]), 0, BROW_NAMES.size() - 1)
    o["nose"] = clampi(int(o["nose"]), 0, NOSE_NAMES.size() - 1)
    o["mouth"] = clampi(int(o["mouth"]), 0, MOUTH_NAMES.size() - 1)
    o["mark"] = clampi(int(o["mark"]), 0, MARK_NAMES.size() - 1)
    o["top"] = clampi(int(o["top"]), 0, TOP_NAMES.size() - 1)
    o["top_color"] = clampi(int(o["top_color"]), 0, CLOTH.size() - 1)
    o["bottom"] = clampi(int(o["bottom"]), 0, BOTTOM_NAMES.size() - 1)
    o["bottom_color"] = clampi(int(o["bottom_color"]), 0, PANTS.size() - 1)
    o["shoes_color"] = clampi(int(o["shoes_color"]), 0, SHOES.size() - 1)
    return o

## Returns {"model": Node3D, "limbs": Array[Node3D] (arm R, arm L, leg L, leg R), "rest": Array[float]}.
static func build(raw_opts: Dictionary) -> Dictionary:
    var o := sanitize(raw_opts)
    var female: bool = int(o["gender"]) == 1
    var bw: float = [0.88, 1.0, 1.18][int(o["build"])]
    var skin: Color = SKIN[int(o["skin"])]
    var hair: Color = HAIR[int(o["hair_color"])]
    var top_col: Color = CLOTH[int(o["top_color"])]
    var pants_col: Color = PANTS[int(o["bottom_color"])]
    var shoe_col: Color = SHOES[int(o["shoes_color"])]
    var top_style := int(o["top"])
    var shorts: bool = int(o["bottom"]) == 1

    var shoulder: float = 0.255 * bw * (0.88 if female else 1.0)
    var waist: float = (0.175 if female else 0.205) * bw
    var hip: float = 0.19 * bw * (1.12 if female else 1.0)
    var depth: float = 0.125 * (0.94 + 0.06 * bw)

    var body := LP.new()
    body.smooth = true
    var root := Node3D.new()
    root.name = "Human"

    # ------------------------------------------------------------- torso
    body.frustum(Vector3(0, 0.80, 0), 0.14, hip * 0.97, depth * 0.95, hip, depth, 8, pants_col, Vector2.ZERO, 22.5, false)
    body.frustum(Vector3(0, 0.93, 0), 0.25, hip * 0.96, depth * 0.95, waist, depth * 0.92, 8, top_col, Vector2.ZERO, 22.5, false)
    body.frustum(Vector3(0, 1.18, 0), 0.32, waist, depth * 0.92, shoulder, depth * 0.98, 8, top_col, Vector2.ZERO, 22.5, true)
    body.frustum(Vector3(0, 0.905, 0), 0.05, hip * 0.97 + 0.01, depth * 0.98 + 0.01, hip * 0.96 + 0.01, depth * 0.97 + 0.01, 8, Color("2a1f18"), Vector2.ZERO, 22.5, false)
    body.box(Vector3(0, 0.93, -depth * 0.98 - 0.012), Vector3(0.05, 0.04, 0.012), Color("c9a24a"))
    if female:
        for sx in [-1.0, 1.0]:
            body.blob(Vector3(sx * 0.07, 1.27, -depth * 0.72), Vector3(0.062, 0.05, 0.04), top_col, 3, 8)
    # neck + collar
    body.frustum(Vector3(0, 1.49, 0), 0.13, 0.052, 0.05, 0.046, 0.045, 6, skin.darkened(0.04), Vector2.ZERO, 0.0, true)
    var collar := top_col.lightened(0.08) if top_style != 2 else top_col.darkened(0.12)
    body.frustum(Vector3(0, 1.465, 0), 0.06 if top_style != 2 else 0.095, 0.095, 0.075, 0.078, 0.066, 8, collar, Vector2.ZERO, 22.5, false)
    if top_style == 2:
        # open jacket: light undershirt strip, pockets, zip line
        body.box(Vector3(0, 1.32, -depth * 0.97 - 0.004), Vector3(0.13, 0.44, 0.012), Color("e7e4da"))
        for sx in [-1.0, 1.0]:
            body.box(Vector3(sx * waist * 0.62, 1.05, -depth * 0.95 - 0.012), Vector3(0.1, 0.085, 0.022), top_col.darkened(0.18))
            body.box(Vector3(sx * 0.08, 1.32, -depth * 0.99 - 0.01), Vector3(0.035, 0.46, 0.014), top_col.darkened(0.1))
    elif top_style == 1:
        for k in range(4):
            body.box(Vector3(0, 1.4 - float(k) * 0.12, -depth * 0.98 - 0.006), Vector3(0.02, 0.02, 0.012), top_col.lightened(0.3))

    # ------------------------------------------------------------- head
    # The head is its own mesh scaled up a little: bigger faces read far better on a phone.
    var head := LP.new()
    head.smooth = true
    _add_face(head, o, female, skin, hair, 0.0)
    var beard_style := int(o["beard"]) if not female else 0
    _add_beard(head, beard_style, hair, skin, 0.0)
    _add_hair(head, int(o["hair_style"]), hair, 0.0)
    if bool(o["glasses"]):
        _add_glasses(head, 0.0)
    var head_node: Node3D = head.to_node("Head")
    var head_scale := 1.22 if not female else 1.18
    head_node.scale = Vector3(head_scale, head_scale, head_scale)
    head_node.position = Vector3(0, 1.725 + 0.012 * head_scale, 0)
    root.add_child(head_node)

    root.add_child(body.to_node("Body"))

    # ------------------------------------------------------------- arms
    var arm_r := _build_arm(1.0, shoulder, bw, skin, top_col, top_style)
    var arm_l := _build_arm(-1.0, shoulder, bw, skin, top_col, top_style)
    root.add_child(arm_r)
    root.add_child(arm_l)

    # ------------------------------------------------------------- legs
    var leg_l := _build_leg(-1.0, hip, bw, skin, pants_col, shoe_col, shorts)
    var leg_r := _build_leg(1.0, hip, bw, skin, pants_col, shoe_col, shorts)
    root.add_child(leg_l)
    root.add_child(leg_r)

    if female:
        root.scale = Vector3(0.97, 0.95, 0.97)
    return {"model": root, "limbs": [arm_r, arm_l, leg_l, leg_r], "rest": [0.0, 0.0, 0.0, 0.0]}

# ---------------------------------------------------------------- pieces
static func _build_arm(side: float, shoulder: float, bw: float, skin: Color, shirt: Color, top_style: int) -> Node3D:
    var pivot := Node3D.new()
    pivot.name = "ArmPivot"
    pivot.position = Vector3(side * (shoulder + 0.04), 1.455, 0.0)
    var b := LP.new()
    b.smooth = true
    var r0 := 0.052 * (0.9 + 0.1 * bw)
    var r1 := 0.044 * (0.9 + 0.1 * bw)
    var long_sleeve := top_style != 0
    b.blob(Vector3(0, -0.01, 0), Vector3(r0 + 0.014, 0.065, r0 + 0.012), shirt, 4, 6)
    if long_sleeve:
        b.frustum(Vector3(0, -0.30, 0), 0.30, r1 + 0.003, r1 + 0.003, r0 + 0.012, r0 + 0.012, 6, shirt, Vector2.ZERO, 0.0, false)
        b.frustum(Vector3(0, -0.55, 0), 0.26, r1 - 0.004, r1 - 0.004, r1 + 0.003, r1 + 0.003, 6, shirt, Vector2.ZERO, 0.0, true)
        b.frustum(Vector3(0, -0.565, 0), 0.04, r1 - 0.002, r1 - 0.002, r1 - 0.002, r1 - 0.002, 6, shirt.darkened(0.15), Vector2.ZERO, 0.0, false)
    else:
        # short sleeve: sleeve on the upper arm, bare skin below it
        b.frustum(Vector3(0, -0.17, 0), 0.17, r0 * 0.95 + 0.012, r0 * 0.95 + 0.012, r0 + 0.012, r0 + 0.012, 6, shirt, Vector2.ZERO, 0.0, false)
        b.frustum(Vector3(0, -0.57, 0), 0.41, r1 - 0.008, r1 - 0.008, r0 - 0.004, r0 - 0.004, 6, skin, Vector2.ZERO, 0.0, false)
    b.blob(Vector3(0, -0.62, 0.0), Vector3(0.042, 0.058, 0.032), skin, 2, 6)
    b.box(Vector3(side * -0.034, -0.64, -0.02), Vector3(0.018, 0.04, 0.02), skin.darkened(0.04))
    pivot.add_child(b.to_node("Arm"))
    return pivot

static func _build_leg(side: float, hip: float, bw: float, skin: Color, pants: Color, shoe: Color, shorts: bool) -> Node3D:
    var pivot := Node3D.new()
    pivot.name = "LegPivot"
    pivot.position = Vector3(side * hip * 0.5, 0.93, 0.0)
    var b := LP.new()
    b.smooth = true
    var r0 := 0.088 * (0.9 + 0.1 * bw)
    var r1 := 0.066 * (0.9 + 0.1 * bw)
    var r2 := 0.048 * (0.9 + 0.1 * bw)
    b.frustum(Vector3(0, -0.46, 0), 0.46, r1, r1, r0, r0, 7, pants, Vector2.ZERO, 0.0, false)
    if shorts:
        b.frustum(Vector3(0, -0.46, 0), 0.20, r1 - 0.012, r1 - 0.012, r1 - 0.004, r1 - 0.004, 7, skin, Vector2.ZERO, 0.0, true)
        b.frustum(Vector3(0, -0.90, 0), 0.46, r2, r2, r1 - 0.012, r1 - 0.012, 7, skin, Vector2.ZERO, 0.0, false)
        # shorts hem sits above the knee: cover the upper part only
        b.frustum(Vector3(0, -0.30, 0), 0.04, r0 * 0.78, r0 * 0.78, r0 * 0.8, r0 * 0.8, 7, pants.darkened(0.12), Vector2.ZERO, 0.0, true)
    else:
        b.frustum(Vector3(0, -0.89, 0), 0.43, r2, r2, r1, r1, 7, pants, Vector2.ZERO, 0.0, false)
        b.frustum(Vector3(0, -0.89, 0), 0.04, r2 + 0.004, r2 + 0.004, r2 + 0.004, r2 + 0.004, 7, pants.darkened(0.15), Vector2.ZERO, 0.0, false)
    b.box(Vector3(0, -0.905, -0.045), Vector3(0.105, 0.06, 0.27), shoe)
    b.box(Vector3(0, -0.935, -0.045), Vector3(0.11, 0.025, 0.285), shoe.darkened(0.45))
    b.box(Vector3(0, -0.88, -0.17), Vector3(0.08, 0.04, 0.06), shoe.lightened(0.08))
    pivot.add_child(b.to_node("Leg"))
    return pivot

static func _add_hair(b, style: int, hair: Color, hy: float) -> void:
    match style:
        1, 2, 3, 4, 5:
            var top_y := hy + 0.075
            var ry := 0.075
            if style == 3:
                top_y = hy + 0.085
                ry = 0.065
            b.blob(Vector3(0, top_y, 0.014), Vector3(0.118, ry, 0.126), hair, 3, 8)
            # back of head
            b.blob(Vector3(0, hy + 0.01, 0.045), Vector3(0.112, 0.105, 0.088), hair, 3, 8)
            if style == 2:
                b.box(Vector3(-0.045, hy + 0.062, -0.108), Vector3(0.09, 0.038, 0.03), hair.lightened(0.05))
                b.box(Vector3(0.04, hy + 0.088, -0.07), Vector3(0.06, 0.03, 0.07), hair)
            if style == 1:
                b.box(Vector3(0, hy + 0.068, -0.112), Vector3(0.18, 0.03, 0.03), hair)
            if style == 4:
                b.frustum(Vector3(0, hy - 0.2, 0.05), 0.28, 0.115, 0.04, 0.125, 0.07, 6, hair, Vector2.ZERO, 0.0, true)
                for sx in [-1.0, 1.0]:
                    b.frustum(Vector3(sx * 0.115, hy - 0.16, 0.0), 0.22, 0.02, 0.05, 0.026, 0.06, 5, hair, Vector2.ZERO, 0.0, true)
            if style == 5:
                b.limb_between(Vector3(0, hy + 0.04, 0.12), Vector3(0, hy - 0.12, 0.2), 0.04, 0.025, hair, 6)
                b.blob(Vector3(0, hy + 0.045, 0.125), Vector3(0.04, 0.04, 0.04), hair.darkened(0.2), 2, 6)
        6:
            for k in range(7):
                var z := -0.1 + float(k) * 0.034
                var h := 0.07 - absf(float(k) - 3.0) * 0.008
                b.box(Vector3(0, hy + 0.12 + h * 0.5, z), Vector3(0.028, h, 0.04), hair)
        _:
            pass

static func _add_beard(b, style: int, hair: Color, skin: Color, hy: float) -> void:
    match style:
        1:
            b.blob(Vector3(0, hy - 0.075, -0.03), Vector3(0.104, 0.065, 0.097), skin.lerp(hair, 0.42), 3, 8)
        2:
            b.blob(Vector3(0, hy - 0.112, -0.035), Vector3(0.104, 0.058, 0.094), hair, 3, 8)
            for sx in [-1.0, 1.0]:
                b.blob(Vector3(sx * 0.085, hy - 0.05, -0.02), Vector3(0.026, 0.07, 0.08), hair, 2, 6)
            b.blob(Vector3(0, hy - 0.04, -0.106), Vector3(0.05, 0.012, 0.016), hair.darkened(0.1), 2, 6)
        3:
            b.box(Vector3(0, hy - 0.045, -0.107), Vector3(0.08, 0.02, 0.02), hair)
            b.blob(Vector3(0, hy - 0.098, -0.075), Vector3(0.04, 0.045, 0.035), hair, 2, 6)
        _:
            pass

static func _add_glasses(b, hy: float) -> void:
    var frame := Color("17171a")
    var y := hy + 0.012
    for sx in [-1.0, 1.0]:
        var cx: float = sx * 0.045
        b.box(Vector3(cx, y + 0.027, -0.12), Vector3(0.07, 0.009, 0.01), frame)
        b.box(Vector3(cx, y - 0.027, -0.12), Vector3(0.07, 0.009, 0.01), frame)
        b.box(Vector3(cx - 0.034, y, -0.12), Vector3(0.009, 0.054, 0.01), frame)
        b.box(Vector3(cx + 0.034, y, -0.12), Vector3(0.009, 0.054, 0.01), frame)
        b.box(Vector3(sx * 0.1, y, -0.06), Vector3(0.008, 0.008, 0.12), frame)
    b.box(Vector3(0, y + 0.01, -0.12), Vector3(0.022, 0.008, 0.01), frame)

static func _add_face(b, o: Dictionary, female: bool, skin: Color, hair: Color, hy: float) -> void:
    var face := int(o["face"])
    var fw: float = [1.0, 1.1, 1.04, 0.92][face]
    var jaw_w: float = [0.80, 0.86, 0.98, 0.70][face] * (0.92 if female else 1.0)
    var jaw_y: float = [0.07, 0.062, 0.058, 0.08][face]
    # skull + jaw + chin
    b.blob(Vector3(0, hy + 0.012, 0.004), Vector3(0.104 * fw, 0.122, 0.114), skin, 4, 8, 0.95)
    b.blob(Vector3(0, hy - jaw_y, -0.022), Vector3(0.088 * fw * jaw_w + 0.012, 0.062, 0.092), skin, 3, 8, 0.8)
    b.blob(Vector3(0, hy - jaw_y - 0.03, -0.062), Vector3(0.032 * (1.2 if face == 2 else 1.0), 0.026, 0.03), skin.darkened(0.02), 2, 6)
    var ear_w := 0.011 if not female else 0.009
    for sx in [-1.0, 1.0]:
        b.blob(Vector3(sx * 0.104 * fw, hy - 0.004, 0.004), Vector3(ear_w, 0.026, 0.017), skin.darkened(0.05), 2, 6)
    # eyes
    var eye_col: Color = EYES[int(o["eyes"])]
    var es: float = 1.12 if female else 1.0
    for sx in [-1.0, 1.0]:
        var ex: float = sx * 0.042 * fw
        var ey: float = hy + 0.014
        b.blob(Vector3(ex, ey, -0.1 * fw), Vector3(0.0185 * es, 0.0135 * es, 0.01), Color("f4f2ec"), 2, 7)
        b.blob(Vector3(ex, ey, -0.108 * fw), Vector3(0.0095 * es, 0.0095 * es, 0.006), eye_col, 2, 6)
        b.box(Vector3(ex, ey, -0.1135 * fw), Vector3(0.005, 0.005, 0.004), Color("0e1218"))
        b.box(Vector3(ex - sx * 0.003, ey + 0.004, -0.1165 * fw), Vector3(0.0025, 0.0025, 0.002), Color("ffffff"))
        # lids: shadow above, light line below
        b.box(Vector3(ex, ey + 0.0135 * es, -0.1035 * fw), Vector3(0.04 * es, 0.005, 0.008), skin.darkened(0.22))
        b.box(Vector3(ex, ey - 0.0135 * es, -0.1035 * fw), Vector3(0.036 * es, 0.003, 0.006), skin.darkened(0.1))
        if female:
            b.box(Vector3(ex + sx * 0.016, ey + 0.012, -0.1 * fw), Vector3(0.012, 0.004, 0.008), Color("17120f"))
    # brows
    var brow_col: Color = hair if (int(o["hair_style"]) != 0 or int(o["beard"]) != 0) else skin.darkened(0.3)
    var bt: float = [0.007, 0.011, 0.017][int(o["brows"])]
    var angle: float = -8.0 if int(o["mouth"]) == 2 else 4.0
    for sx in [-1.0, 1.0]:
        b.push(Vector3(sx * 0.043 * fw, hy + 0.046, -0.1 * fw), Vector3(0, 0, sx * -angle))
        b.box(Vector3.ZERO, Vector3(0.05 if not female else 0.046, bt, 0.012), brow_col)
        b.pop()
    # nose
    var nose := int(o["nose"])
    var nl: float = [0.024, 0.032, 0.043, 0.026][nose]
    var nw: float = [0.011, 0.014, 0.018, 0.013][nose]
    b.limb_between(Vector3(0, hy + 0.025, -0.106), Vector3(0, hy - 0.012, -0.108 - nl), 0.009, nw * 0.8, skin.darkened(0.03), 5)
    b.blob(Vector3(0, hy - 0.012, -0.108 - nl), Vector3(nw, 0.012, 0.014), skin.darkened(0.04), 2, 6)
    for sx in [-1.0, 1.0]:
        b.blob(Vector3(sx * nw * 0.9, hy - 0.016, -0.1 - nl * 0.85), Vector3(0.007, 0.008, 0.008), skin.darkened(0.06), 2, 5)
        b.box(Vector3(sx * nw * 0.7, hy - 0.022, -0.105 - nl * 0.8), Vector3(0.006, 0.004, 0.005), skin.darkened(0.45))
    # mouth
    var mouth := int(o["mouth"])
    var lip: Color = Color("b8505a") if female else skin.lerp(Color("a4524b"), 0.55)
    var lh: float = 0.01 if female else 0.0075
    var my: float = hy - 0.052
    var mz: float = -0.1 * fw + 0.004
    b.blob(Vector3(0, my + 0.004, mz - 0.004), Vector3(0.026, lh * 0.8, 0.008), lip.lightened(0.05), 2, 6)
    b.blob(Vector3(0, my - 0.005, mz - 0.003), Vector3(0.024, lh, 0.008), lip, 2, 6)
    b.box(Vector3(0, my, mz - 0.011), Vector3(0.044, 0.0025, 0.004), lip.darkened(0.5))
    if mouth == 1:
        for sx in [-1.0, 1.0]:
            b.box(Vector3(sx * 0.026, my + 0.004, mz - 0.006), Vector3(0.008, 0.004, 0.006), lip.darkened(0.3))
        b.box(Vector3(0, my - 0.0015, mz - 0.0125), Vector3(0.03, 0.004, 0.003), Color("f4f2ec"))
    elif mouth == 2:
        for sx in [-1.0, 1.0]:
            b.box(Vector3(sx * 0.026, my - 0.005, mz - 0.006), Vector3(0.008, 0.004, 0.006), lip.darkened(0.3))
    # marks
    match int(o["mark"]):
        1:
            for k in range(8):
                var sx2: float = -1.0 if k % 2 == 0 else 1.0
                var px: float = sx2 * (0.02 + float(k / 2) * 0.012) * fw
                b.box(Vector3(px, hy - 0.008 - float(k % 3) * 0.006, -0.1 * fw - 0.012 + absf(px) * 0.1), Vector3(0.005, 0.005, 0.004), skin.darkened(0.28))
        2:
            b.push(Vector3(0.05 * fw, hy + 0.01, -0.098 * fw), Vector3(0, 0, 25))
            b.box(Vector3.ZERO, Vector3(0.007, 0.06, 0.006), Color("b86a60"))
            b.pop()
        3:
            b.box(Vector3(-0.03 * fw, hy - 0.035, -0.104 * fw), Vector3(0.006, 0.006, 0.004), Color("3a2418"))
    if female:
        for sx in [-1.0, 1.0]:
            b.blob(Vector3(sx * 0.05 * fw, hy - 0.03, -0.096 * fw), Vector3(0.022, 0.012, 0.006), skin.lerp(Color("e08a8a"), 0.28), 2, 6)
