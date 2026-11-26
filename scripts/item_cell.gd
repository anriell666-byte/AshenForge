extends Button
## One square cell of an item grid. Draws its own rounded frame, a hand-painted vector icon
## for the item, the stack count, a durability bar and equipped/selected marks.

const ID = preload("res://scripts/items_data.gd")

const TIER_COLORS := [Color(0.38, 0.46, 0.4), Color(0.5, 0.64, 0.42), Color(0.86, 0.66, 0.3)]

var item_id: String = ""
var count: int = 0
var equipped: bool = false
var selected: bool = false
var dur_ratio: float = -1.0
var broken: bool = false
var slot_hint: String = ""

func _init() -> void:
    focus_mode = Control.FOCUS_NONE
    custom_minimum_size = Vector2(84, 84)
    flat = true

func setup(id: String, amount: int = 0) -> void:
    item_id = id
    count = amount
    queue_redraw()

func _draw() -> void:
    var r := Rect2(Vector2.ZERO, size)
    var sb := StyleBoxFlat.new()
    sb.set_corner_radius_all(10)
    sb.bg_color = Color(0.1, 0.125, 0.12, 1.0) if item_id != "" else Color(0.075, 0.09, 0.088, 1.0)
    var tier := 1
    if item_id != "":
        tier = int(ID.item(item_id).get("tier", 1))
    var border: Color = TIER_COLORS[clampi(tier - 1, 0, 2)] if item_id != "" else Color(0.22, 0.27, 0.25)
    if selected:
        border = Color(1.0, 0.92, 0.55)
    sb.border_color = border
    sb.set_border_width_all(4 if selected else 2)
    draw_style_box(sb, r)
    if is_pressed() or (is_hovered() and item_id != ""):
        draw_rect(r.grow(-3), Color(1, 1, 1, 0.06))
    if item_id == "":
        if slot_hint != "":
            var f := ThemeDB.fallback_font
            draw_string(f, Vector2(0, size.y * 0.5 + 5), slot_hint, HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color(0.45, 0.52, 0.48))
        return
    var icon_rect := r.grow(-9)
    _draw_icon(item_id, icon_rect, broken)
    var font := ThemeDB.fallback_font
    if count > 1 or (count == 1 and not ID.ITEMS.has(item_id) and not ID.GEAR.has(item_id)):
        var text := str(count)
        draw_string_outline(font, Vector2(0, size.y - 8), text, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 9, 17, 5, Color(0, 0, 0, 0.9))
        draw_string(font, Vector2(0, size.y - 8), text, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 9, 17, Color(1, 0.96, 0.8))
    if equipped:
        draw_circle(Vector2(14, 14), 8.0, Color(0.95, 0.78, 0.3))
        draw_string(font, Vector2(8, 19), "✔", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.15, 0.1, 0.0))
    if dur_ratio >= 0.0:
        var bar := Rect2(8, size.y - 9, size.x - 16, 5)
        draw_rect(bar, Color(0, 0, 0, 0.7))
        var fill := Color(0.5, 0.85, 0.4) if dur_ratio > 0.5 else (Color(0.95, 0.75, 0.3) if dur_ratio > 0.2 else Color(0.9, 0.3, 0.25))
        draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(dur_ratio, 0.0, 1.0), bar.size.y)), fill)

# ---------------------------------------------------------------- icons
func _draw_icon(id: String, rect: Rect2, dim: bool) -> void:
    var o := rect.position
    var k := minf(rect.size.x, rect.size.y) / 100.0
    var tint := Color(1, 1, 1, 0.45 if dim else 1.0)
    var data: Dictionary = ID.item(id)
    var P := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * k
    var poly := func(pts: Array, col: Color) -> void:
        var arr := PackedVector2Array()
        for p in pts:
            arr.append(o + Vector2(p[0], p[1]) * k)
        draw_colored_polygon(arr, col * tint)
    var line := func(a: Array, b: Array, w: float, col: Color) -> void:
        draw_line(o + Vector2(a[0], a[1]) * k, o + Vector2(b[0], b[1]) * k, col * tint, w * k, true)
    var disc := func(c: Array, rad: float, col: Color) -> void:
        draw_circle(o + Vector2(c[0], c[1]) * k, rad * k, col * tint)
    var wood := Color(0.55, 0.36, 0.18)
    var steel := Color(0.72, 0.75, 0.78)
    var dark := Color(0.28, 0.3, 0.33)
    match id:
        # ---- resources
        "wood":
            line.call([18, 72], [78, 44], 15, wood)
            line.call([18, 50], [70, 26], 15, wood.darkened(0.15))
            disc.call([78, 44], 8, Color(0.82, 0.62, 0.36))
            disc.call([70, 26], 8, Color(0.82, 0.62, 0.36))
        "scrap":
            for i in range(8):
                var a := float(i) * TAU / 8.0
                line.call([50 + cos(a) * 22, 50 + sin(a) * 22], [50 + cos(a) * 34, 50 + sin(a) * 34], 11, Color(0.6, 0.66, 0.66))
            disc.call([50, 50], 26, Color(0.62, 0.68, 0.68))
            disc.call([50, 50], 10, Color(0.1, 0.125, 0.12))
        "plastic":
            poly.call([[36, 34], [64, 34], [66, 80], [34, 80]], Color(0.25, 0.68, 0.72))
            poly.call([[43, 18], [57, 18], [58, 34], [42, 34]], Color(0.35, 0.78, 0.82))
            poly.call([[41, 14], [59, 14], [59, 20], [41, 20]], Color(0.9, 0.9, 0.95))
            line.call([42, 58], [58, 58], 5, Color(1, 1, 1, 0.5))
        "cloth":
            poly.call([[20, 34], [80, 30], [78, 72], [22, 74]], Color(0.72, 0.58, 0.38))
            line.call([22, 52], [78, 50], 3, Color(0.5, 0.38, 0.22))
            line.call([50, 32], [50, 74], 3, Color(0.5, 0.38, 0.22))
        "food":
            poly.call([[30, 34], [70, 34], [70, 78], [30, 78]], Color(0.78, 0.5, 0.2))
            disc.call([50, 34], 20, Color(0.85, 0.85, 0.88))
            poly.call([[30, 50], [70, 50], [70, 62], [30, 62]], Color(0.9, 0.82, 0.55))
        "medicine":
            poly.call([[22, 32], [78, 32], [78, 76], [22, 76]], Color(0.88, 0.88, 0.82))
            line.call([50, 40], [50, 68], 10, Color(0.8, 0.2, 0.2))
            line.call([36, 54], [64, 54], 10, Color(0.8, 0.2, 0.2))
        "stone":
            poly.call([[20, 68], [28, 40], [52, 24], [76, 38], [82, 68], [52, 78]], Color(0.52, 0.53, 0.5))
            poly.call([[28, 40], [52, 24], [76, 38], [52, 50]], Color(0.66, 0.67, 0.64))
        "fuel":
            poly.call([[26, 34], [68, 34], [78, 44], [78, 80], [26, 80]], Color(0.78, 0.2, 0.16))
            poly.call([[34, 20], [58, 20], [58, 34], [34, 34]], Color(0.55, 0.14, 0.12))
            line.call([36, 56], [68, 56], 5, Color(0.95, 0.8, 0.3))
        "essence":
            poly.call([[50, 14], [74, 46], [50, 86], [26, 46]], Color(0.62, 0.3, 0.86))
            poly.call([[50, 14], [74, 46], [50, 46]], Color(0.85, 0.6, 1.0))
            poly.call([[50, 46], [74, 46], [50, 86]], Color(0.45, 0.2, 0.68))
        "seal":
            disc.call([50, 50], 32, Color(0.92, 0.72, 0.22))
            disc.call([50, 50], 24, Color(0.72, 0.52, 0.12))
            var star: Array = []
            for i in range(10):
                var a2 := -PI / 2.0 + float(i) * TAU / 10.0
                var rad2 := 20.0 if i % 2 == 0 else 8.0
                star.append([50 + cos(a2) * rad2, 50 + sin(a2) * rad2])
            poly.call(star, Color(1.0, 0.9, 0.5))
        # ---- consumables
        "bandage":
            disc.call([50, 52], 28, Color(0.92, 0.9, 0.82))
            disc.call([50, 52], 11, Color(0.2, 0.22, 0.2))
            line.call([22, 40], [78, 40], 5, Color(0.8, 0.25, 0.22))
        "stew":
            poly.call([[18, 46], [82, 46], [74, 74], [26, 74]], Color(0.5, 0.34, 0.2))
            poly.call([[22, 46], [78, 46], [76, 52], [24, 52]], Color(0.8, 0.5, 0.2))
            line.call([38, 40], [40, 24], 4, Color(1, 1, 1, 0.5))
            line.call([58, 40], [56, 22], 4, Color(1, 1, 1, 0.5))
        "medkit":
            poly.call([[18, 34], [82, 34], [82, 76], [18, 76]], Color(0.85, 0.2, 0.18))
            poly.call([[36, 24], [64, 24], [64, 34], [36, 34]], Color(0.65, 0.14, 0.12))
            line.call([50, 42], [50, 68], 10, Color(0.95, 0.95, 0.95))
            line.call([37, 55], [63, 55], 10, Color(0.95, 0.95, 0.95))
        # ---- weapons and tools
        "club":
            line.call([26, 80], [62, 30], 9, wood)
            line.call([56, 38], [68, 20], 17, wood.lightened(0.05))
            disc.call([74, 28], 3, steel)
            disc.call([62, 18], 3, steel)
        "machete":
            line.call([28, 78], [40, 62], 9, Color(0.3, 0.2, 0.12))
            poly.call([[40, 62], [72, 20], [80, 32], [62, 72]], steel)
        "spear":
            line.call([22, 84], [68, 26], 5, wood)
            poly.call([[62, 28], [84, 8], [76, 38]], steel)
        "sling":
            line.call([50, 82], [50, 56], 7, wood)
            line.call([50, 56], [30, 28], 5, wood)
            line.call([50, 56], [70, 28], 5, wood)
            disc.call([50, 22], 8, Color(0.6, 0.6, 0.58))
        "bow":
            var pts := PackedVector2Array()
            for i in range(0, 11):
                var t := float(i) / 10.0
                pts.append(P.call(66 - sin(t * PI) * 34, 14 + t * 72))
            draw_polyline(pts, wood * tint, 6.0 * k, true)
            line.call([66, 14], [66, 86], 2, Color(0.9, 0.9, 0.8))
            line.call([30, 50], [74, 50], 3, wood.darkened(0.2))
        "crossbow":
            line.call([24, 74], [74, 36], 9, Color(0.38, 0.25, 0.14))
            line.call([42, 26], [74, 66], 7, dark)
            line.call([42, 26], [74, 66], 2, Color(0.9, 0.9, 0.8))
        "fire_axe":
            line.call([26, 82], [64, 26], 7, wood)
            poly.call([[52, 18], [82, 26], [76, 52], [58, 38]], Color(0.78, 0.18, 0.14))
            poly.call([[76, 26], [84, 28], [78, 54], [74, 50]], steel)
        "hatchet":
            line.call([30, 80], [62, 30], 7, wood)
            poly.call([[54, 22], [80, 26], [72, 46], [58, 38]], dark)
            poly.call([[78, 26], [84, 28], [76, 48], [72, 46]], steel)
        "pickaxe":
            line.call([30, 82], [62, 28], 7, wood)
            line.call([30, 30], [84, 44], 8, dark)
            poly.call([[22, 28], [34, 28], [34, 40]], steel)
            poly.call([[84, 44], [78, 56], [72, 42]], steel)
        "crowbar":
            line.call([26, 80], [64, 30], 6, Color(0.72, 0.16, 0.14))
            line.call([64, 30], [78, 22], 6, Color(0.72, 0.16, 0.14))
            line.call([26, 80], [22, 72], 6, Color(0.72, 0.16, 0.14))
        "sledgehammer":
            line.call([26, 84], [64, 36], 7, wood)
            poly.call([[44, 20], [80, 34], [72, 54], [38, 40]], dark)
            poly.call([[72, 30], [84, 36], [76, 58], [68, 52]], steel)
        "shock_baton":
            line.call([26, 82], [66, 30], 9, Color(0.14, 0.14, 0.16))
            disc.call([70, 24], 10, Color(0.4, 0.85, 1.0))
            disc.call([70, 24], 5, Color(0.9, 1.0, 1.0))
        "chainsaw":
            poly.call([[20, 50], [58, 50], [58, 80], [20, 80]], Color(0.92, 0.5, 0.12))
            line.call([58, 62], [88, 40], 8, steel)
            line.call([58, 62], [88, 40], 3, dark)
            line.call([26, 50], [40, 36], 5, dark)
        "flamethrower":
            disc.call([34, 66], 17, Color(0.78, 0.2, 0.16))
            line.call([46, 56], [80, 32], 8, dark)
            poly.call([[78, 24], [92, 20], [90, 38], [80, 40]], Color(1.0, 0.6, 0.15))
        # ---- gear
        "cap", "helmet", "riot_helmet":
            var c: Color = data.get("color", Color(0.4, 0.4, 0.4))
            poly.call([[22, 62], [26, 44], [38, 30], [58, 28], [74, 40], [78, 62]], c)
            if id == "cap":
                poly.call([[54, 58], [86, 58], [84, 68], [54, 66]], c.darkened(0.25))
            elif id == "helmet":
                line.call([14, 64], [86, 64], 8, c.darkened(0.2))
                line.call([50, 28], [50, 62], 5, c.darkened(0.25))
            else:
                poly.call([[28, 50], [72, 50], [72, 62], [28, 62]], Color(0.2, 0.35, 0.45))
                poly.call([[24, 62], [76, 62], [70, 78], [30, 78]], c.lightened(0.08))
        "hoodie", "leather_jacket":
            var c2: Color = data.get("color", Color(0.4, 0.3, 0.2))
            poly.call([[42, 22], [58, 22], [82, 36], [74, 58], [66, 50], [66, 82], [34, 82], [34, 50], [26, 58], [18, 36]], c2)
            line.call([50, 24], [50, 82], 4, c2.darkened(0.3))
            line.call([42, 22], [50, 34], 4, c2.lightened(0.2))
            line.call([58, 22], [50, 34], 4, c2.lightened(0.2))
        "vest", "plate_armor":
            var c3: Color = data.get("color", Color(0.3, 0.3, 0.3))
            poly.call([[34, 24], [46, 22], [54, 22], [66, 24], [70, 40], [66, 82], [34, 82], [30, 40]], c3)
            poly.call([[38, 36], [62, 36], [62, 62], [38, 62]], c3.lightened(0.18))
            if id == "plate_armor":
                disc.call([28, 30], 11, c3.lightened(0.1))
                disc.call([72, 30], 11, c3.lightened(0.1))
            line.call([38, 70], [62, 70], 5, c3.darkened(0.3))
        "work_pants", "cargo_pants":
            var c4: Color = data.get("color", Color(0.3, 0.3, 0.4))
            poly.call([[30, 20], [70, 20], [74, 84], [54, 84], [50, 44], [46, 84], [26, 84]], c4)
            line.call([30, 28], [70, 28], 5, c4.darkened(0.3))
            if id == "cargo_pants":
                poly.call([[28, 52], [40, 52], [40, 64], [28, 64]], c4.lightened(0.15))
                poly.call([[60, 52], [72, 52], [72, 64], [60, 64]], c4.lightened(0.15))
        "boots", "steel_boots":
            var c5: Color = data.get("color", Color(0.3, 0.2, 0.1))
            poly.call([[34, 18], [54, 18], [54, 56], [82, 66], [82, 82], [30, 82]], c5)
            poly.call([[30, 76], [82, 76], [82, 84], [30, 84]], c5.darkened(0.4))
            if id == "steel_boots":
                poly.call([[60, 60], [82, 66], [82, 78], [60, 76]], steel)
        "pack_small", "pack_big":
            var c6: Color = data.get("color", Color(0.4, 0.3, 0.2))
            var big := id == "pack_big"
            var top := 14.0 if big else 26.0
            poly.call([[26, top + 4], [74, top + 4], [78, 84], [22, 84]], c6)
            poly.call([[24, top], [76, top], [76, top + 14], [24, top + 14]], c6.lightened(0.15))
            poly.call([[32, 56], [68, 56], [68, 80], [32, 80]], c6.darkened(0.2))
            line.call([14, top + 12], [20, 80], 5, c6.darkened(0.4))
            line.call([86, top + 12], [80, 80], 5, c6.darkened(0.4))
        _:
            disc.call([50, 50], 28, Color(0.5, 0.5, 0.5))
