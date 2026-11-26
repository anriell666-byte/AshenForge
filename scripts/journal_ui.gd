extends CanvasLayer
## Full-screen journal (quests, notes, map) and the note reader popup. Pauses the game while open.

const WD = preload("res://scripts/world_data.gd")

class MapView:
    extends Control
    var ui

    func _draw() -> void:
        if ui == null:
            return
        var size_px := minf(size.x, size.y)
        var cell := size_px / 3.0
        var origin := Vector2((size.x - size_px) * 0.5, (size.y - size_px) * 0.5)
        var font := ThemeDB.fallback_font
        for gz in range(3):
            for gx in range(3):
                var center := Vector2(float(gx - 1) * WD.CELL, float(gz - 1) * WD.CELL)
                var rect := Rect2(origin + Vector2(gx, gz) * cell, Vector2(cell, cell)).grow(-3.0)
                var id: String = ui.district_at_center(center)
                var col := Color(0.10, 0.11, 0.10)
                var label := ""
                var sub := ""
                if id != "":
                    var info: Dictionary = WD.DISTRICTS[id]
                    col = (info["ground"] as Color).lerp(Color(0.12, 0.14, 0.13), 0.35)
                    label = String(info["name"])
                    if ui.world.is_locked(id):
                        col = col.darkened(0.45)
                        sub = "ЗАКРЫТО"
                    else:
                        sub = "Опасность %d" % int(info["tier"])
                draw_rect(rect, col, true)
                draw_rect(rect, Color(0.5, 0.58, 0.5, 0.8) if id != "" else Color(0.2, 0.22, 0.2), false, 2.0)
                if label != "":
                    var fs := int(clampf(cell * 0.11, 12.0, 22.0))
                    draw_string(font, rect.position + Vector2(8, fs + 6), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12.0, fs, Color(0.95, 0.9, 0.75))
                    draw_string(font, rect.position + Vector2(8, fs * 2 + 10), sub, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12.0, int(fs * 0.85), Color(0.9, 0.55, 0.45) if sub == "ЗАКРЫТО" else Color(0.7, 0.8, 0.7))
                    var boss_id := String(WD.DISTRICTS[id]["boss"][0])
                    var dead: bool = ui.progress.defeated.has(boss_id)
                    draw_string(font, rect.position + Vector2(8, rect.size.y - 8), ("Босс повержен" if dead else "Босс жив"), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12.0, int(fs * 0.8), Color(0.55, 0.85, 0.55) if dead else Color(0.9, 0.6, 0.5))
        # Camp and player markers.
        var p: Vector3 = ui.game.player.global_position
        var to_px := func(w: Vector2) -> Vector2:
            return origin + (w + Vector2(WD.HALF * 3.0, WD.HALF * 3.0)) / (WD.CELL * 3.0) * size_px
        var camp: Vector3 = ui.game.camp_position
        draw_circle(to_px.call(Vector2(camp.x, camp.z)), 6.0, Color(1.0, 0.7, 0.25))
        draw_circle(to_px.call(Vector2(p.x, p.z)), 7.0, Color(0.4, 0.9, 1.0))
        draw_arc(to_px.call(Vector2(p.x, p.z)), 11.0, 0.0, TAU, 20, Color(0.4, 0.9, 1.0), 2.0)

var game
var progress
var quests
var world
var tab := "quests"
var journal_root: Control
var body: VBoxContainer
var map_view: MapView
var scroll: ScrollContainer
var tab_buttons := {}
var note_root: Control
var note_title: Label
var note_text: Label
var note_quest: Label
var open_flag := false

func setup(owner_game, progress_node, quests_node, world_node) -> void:
    game = owner_game
    progress = progress_node
    quests = quests_node
    world = world_node
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 41
    _build_journal()
    _build_note()
    journal_root.visible = false
    note_root.visible = false

func district_at_center(center: Vector2) -> String:
    for id in WD.DISTRICTS:
        if (WD.DISTRICTS[id]["center"] as Vector2).distance_to(center) < 1.0:
            return id
    return ""

func is_open() -> bool:
    return journal_root.visible or note_root.visible

# ---------------------------------------------------------------- journal
func _style(bg: Color, border: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.border_color = border
    s.set_border_width_all(2)
    s.set_corner_radius_all(12)
    s.content_margin_left = 12
    s.content_margin_right = 12
    s.content_margin_top = 8
    s.content_margin_bottom = 8
    return s

func _button(text: String, min_size: Vector2) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = min_size
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_size_override("font_size", 17)
    b.add_theme_color_override("font_color", Color(0.91, 0.94, 0.87))
    b.add_theme_color_override("font_disabled_color", Color(0.5, 0.54, 0.5))
    b.add_theme_stylebox_override("normal", _style(Color(0.1, 0.13, 0.12, 0.95), Color(0.48, 0.57, 0.48)))
    b.add_theme_stylebox_override("hover", _style(Color(0.17, 0.22, 0.19), Color(0.77, 0.79, 0.59)))
    b.add_theme_stylebox_override("pressed", _style(Color(0.34, 0.27, 0.16), Color(0.92, 0.71, 0.39)))
    b.add_theme_stylebox_override("disabled", _style(Color(0.07, 0.08, 0.075, 0.7), Color(0.28, 0.31, 0.28, 0.7)))
    return b

func _build_journal() -> void:
    journal_root = Control.new()
    journal_root.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(journal_root)
    var bg := ColorRect.new()
    bg.color = Color(0.04, 0.055, 0.05, 1.0)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    journal_root.add_child(bg)
    var margin := MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 14)
    journal_root.add_child(margin)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 8)
    margin.add_child(root)
    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 8)
    root.add_child(header)
    for t in [["quests", "Задания"], ["notes", "Записки"], ["map", "Карта"]]:
        var b := _button(String(t[1]), Vector2(140, 46))
        b.pressed.connect(_set_tab.bind(String(t[0])))
        header.add_child(b)
        tab_buttons[t[0]] = b
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(spacer)
    var close := _button("Закрыть", Vector2(130, 46))
    close.pressed.connect(close_journal)
    header.add_child(close)
    scroll = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root.add_child(scroll)
    body = VBoxContainer.new()
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 8)
    scroll.add_child(body)
    map_view = MapView.new()
    map_view.ui = self
    map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    map_view.visible = false
    root.add_child(map_view)

func open_journal(start_tab: String = "") -> void:
    if start_tab != "":
        tab = start_tab
    journal_root.visible = true
    get_tree().paused = true
    _refresh()

func close_journal() -> void:
    journal_root.visible = false
    get_tree().paused = note_root.visible

func toggle_journal() -> void:
    if journal_root.visible:
        close_journal()
    else:
        open_journal()

func _set_tab(id: String) -> void:
    tab = id
    _refresh()

func _card(title: String, color: Color) -> VBoxContainer:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _style(Color(0.1, 0.13, 0.12, 0.98), color))
    body.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 3)
    panel.add_child(box)
    var l := Label.new()
    l.text = title
    l.add_theme_font_size_override("font_size", 19)
    l.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
    box.add_child(l)
    return box

func _text(box: VBoxContainer, text: String, size: int = 15, color: Color = Color(0.78, 0.83, 0.77)) -> void:
    var l := Label.new()
    l.text = text
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    box.add_child(l)

func _refresh() -> void:
    for id in tab_buttons:
        (tab_buttons[id] as Button).disabled = (id == tab)
    for child in body.get_children():
        child.queue_free()
    scroll.visible = tab != "map"
    map_view.visible = tab == "map"
    match tab:
        "quests":
            _build_quests()
        "notes":
            _build_notes()
        "map":
            map_view.queue_redraw()

func _build_quests() -> void:
    var active: Array = quests.active_ids()
    if active.is_empty():
        var box := _card("Нет активных заданий", Color(0.4, 0.5, 0.42))
        _text(box, "Читай записки и дневники в домах, лагерях и зданиях районов: кнопка ЧИТАТЬ рядом с бумагой. Новые задания открывают закрытые районы.")
    for id in active:
        var q: Dictionary = WD.QUESTS[id]
        var box := _card(String(q["title"]), Color(0.82, 0.62, 0.3))
        _text(box, String(q["desc"]))
        var p: String = quests.progress_text(id)
        if p != "":
            _text(box, "Прогресс: " + p, 15, Color(0.6, 0.85, 0.6))
        _text(box, "Источник: " + String(q["from"]), 13, Color(0.6, 0.66, 0.75))
    var done: Array = []
    for id in progress.quests:
        if String(progress.quests[id].get("state", "")) == "done":
            done.append(id)
    if not done.is_empty():
        var lines: Array[String] = []
        for id in done:
            lines.append("✔ " + String(WD.QUESTS[id]["title"]))
        var box2 := _card("Выполнено (%d из %d)" % [done.size(), WD.QUESTS.size()], Color(0.4, 0.55, 0.4))
        _text(box2, "\n".join(lines), 15, Color(0.6, 0.78, 0.6))

func _build_notes() -> void:
    if progress.notes_read.is_empty():
        var box := _card("Пока ничего не найдено", Color(0.4, 0.5, 0.42))
        _text(box, "Записки лежат на столах в домах и зданиях.")
        return
    for data in WD.NOTES:
        if not progress.notes_read.has(String(data["id"])):
            continue
        var box2 := _card(String(data["title"]), Color(0.5, 0.58, 0.5))
        var b := _button("Перечитать", Vector2(170, 40))
        b.pressed.connect(show_note.bind(data))
        box2.add_child(b)

# ---------------------------------------------------------------- note reader
func _build_note() -> void:
    note_root = Control.new()
    note_root.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(note_root)
    var dim := ColorRect.new()
    dim.color = Color(0, 0, 0, 0.62)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    note_root.add_child(dim)
    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    note_root.add_child(center)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(560, 0)
    panel.add_theme_stylebox_override("panel", _style(Color(0.86, 0.80, 0.63, 0.98), Color(0.45, 0.33, 0.18)))
    center.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    panel.add_child(box)
    note_title = Label.new()
    note_title.add_theme_font_size_override("font_size", 24)
    note_title.add_theme_color_override("font_color", Color(0.22, 0.14, 0.08))
    box.add_child(note_title)
    note_text = Label.new()
    note_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note_text.custom_minimum_size = Vector2(520, 0)
    note_text.add_theme_font_size_override("font_size", 18)
    note_text.add_theme_color_override("font_color", Color(0.18, 0.12, 0.08))
    box.add_child(note_text)
    note_quest = Label.new()
    note_quest.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note_quest.add_theme_font_size_override("font_size", 16)
    note_quest.add_theme_color_override("font_color", Color(0.50, 0.22, 0.08))
    box.add_child(note_quest)
    var close := _button("Закрыть", Vector2(160, 46))
    close.pressed.connect(close_note)
    box.add_child(close)

func show_note(data: Dictionary) -> void:
    note_title.text = String(data["title"])
    note_text.text = String(data["text"])
    var qid := String(data.get("quest", ""))
    note_quest.text = ("Задание: %s" % String(WD.QUESTS[qid]["title"])) if qid != "" else ""
    note_root.visible = true
    get_tree().paused = true

func close_note() -> void:
    note_root.visible = false
    get_tree().paused = journal_root.visible
