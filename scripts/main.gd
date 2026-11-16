extends Control

const SAVE_PATH := "user://ashenforge_save.json"
var gold := 18
var tribute_goal := 30
var chapter := 1
var heat := 24.0
var quality := 12.0
var durability := 100.0
var has_blade := true
var status: Label
var stats: Label
var hint: Label
var heat_bar: ProgressBar
var quality_bar: ProgressBar
var strike: Button
var sell: Button
var tribute: Button

func _ready() -> void:
	_build_ui()
	_load_game()
	_refresh()
	queue_redraw()

func _draw() -> void:
	var s := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, s), Color("#17131a"))
	draw_rect(Rect2(0, 0, s.x, s.y * 0.56), Color("#211c25"))
	for x in range(0, int(s.x), 90):
		draw_line(Vector2(x, 0), Vector2(x - 25, s.y * 0.56), Color("#302833"), 3.0)
	draw_circle(Vector2(s.x * 0.5, s.y * 0.49), s.x * 0.28, Color(0.95, 0.24, 0.04, 0.12))
	draw_colored_polygon(PackedVector2Array([Vector2(s.x*.27,s.y*.40),Vector2(s.x*.73,s.y*.40),Vector2(s.x*.69,s.y*.62),Vector2(s.x*.31,s.y*.62)]),Color("#51434a"))
	draw_rect(Rect2(s.x*.34,s.y*.47,s.x*.32,s.y*.12),Color("#171116"))
	draw_colored_polygon(PackedVector2Array([Vector2(s.x*.40,s.y*.57),Vector2(s.x*.45,s.y*.49),Vector2(s.x*.50,s.y*.56),Vector2(s.x*.55,s.y*.48),Vector2(s.x*.61,s.y*.57),Vector2(s.x*.57,s.y*.60),Vector2(s.x*.43,s.y*.60)]),Color("#f47a27"))
	draw_colored_polygon(PackedVector2Array([Vector2(s.x*.24,s.y*.70),Vector2(s.x*.76,s.y*.70),Vector2(s.x*.69,s.y*.76),Vector2(s.x*.31,s.y*.76)]),Color("#a6a0a7"))
	draw_rect(Rect2(s.x*.39,s.y*.76,s.x*.22,s.y*.07),Color("#57515b"))
	if has_blade:
		draw_colored_polygon(PackedVector2Array([Vector2(s.x*.36,s.y*.69),Vector2(s.x*.65,s.y*.675),Vector2(s.x*.58,s.y*.65),Vector2(s.x*.42,s.y*.66)]),Color("#c9d1d3"))
	draw_rect(Rect2(0,s.y*.88,s.x,s.y*.12),Color("#100e13"))

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	root.add_theme_constant_override("margin_left", 24)
	root.add_theme_constant_override("margin_right", 24)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_bottom", 22)
	add_child(root)
	var title := Label.new()
	title.text = "ASHENFORGE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#f0d6b2"))
	root.add_child(title)
	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 18)
	root.add_child(status)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var panel := PanelContainer.new()
	root.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	stats = Label.new()
	stats.add_theme_font_size_override("font_size", 17)
	box.add_child(stats)
	heat_bar = ProgressBar.new()
	heat_bar.max_value = 100
	heat_bar.show_percentage = false
	box.add_child(heat_bar)
	quality_bar = ProgressBar.new()
	quality_bar.max_value = 100
	quality_bar.show_percentage = false
	box.add_child(quality_bar)
	hint = Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.y = 48
	root.add_child(hint)
	strike = _button("УДАРИТЬ МОЛОТОМ")
	strike.pressed.connect(_on_strike)
	root.add_child(strike)
	var row := HBoxContainer.new()
	root.add_child(row)
	sell = _button("Продать клинок")
	sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell.pressed.connect(_on_sell)
	row.add_child(sell)
	tribute = _button("Отдать дань")
	tribute.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tribute.pressed.connect(_on_tribute)
	row.add_child(tribute)

func _button(caption: String) -> Button:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size.y = 60
	b.add_theme_font_size_override("font_size", 18)
	return b

func _on_strike() -> void:
	if not has_blade:
		hint.text = "Сначала начни новую ковку."
		return
	var power := randf_range(7.0, 17.0)
	heat = clampf(heat + randf_range(5.0, 13.0), 0.0, 100.0)
	var critical := randf() < 0.14
	quality = minf(100.0, quality + power * (1.7 if critical else 1.0))
	durability -= power * (0.45 if critical else randf_range(0.45, 0.9))
	if heat >= 92.0:
		durability -= 12.0
	hint.text = "Критический удар! Металл поёт." if critical else "Удар точен. Качество растёт, прочность падает."
	if durability <= 0.0:
		durability = 0.0
		has_blade = false
		hint.text = "Клинок рассыпался в искрах."
	_refresh()
	queue_redraw()

func _on_sell() -> void:
	if not has_blade:
		hint.text = "Нечего продавать. Начни новую ковку."
		return
	var value := int(8.0 + quality * 1.25 + durability * 0.22)
	gold += value
	has_blade = false
	heat = 18.0
	quality = 0.0
	durability = 100.0
	hint.text = "Клинок продан за %d золотых." % value
	_refresh()
	queue_redraw()

func _on_tribute() -> void:
	if gold < tribute_goal:
		hint.text = "Дракону нужно ещё %d золотых." % (tribute_goal - gold)
		return
	gold -= tribute_goal
	chapter += 1
	tribute_goal = int(ceil(float(tribute_goal) * 1.35 + 5.0))
	hint.text = "Дань принята. Дракон отступил… пока."
	_refresh()

func _refresh() -> void:
	status.text = "ГЛАВА %d     •     ЗОЛОТО: %d" % [chapter, gold]
	stats.text = "%s\nПрочность: %d%%    Качество: %d%%\nДань дракону: %d золота" % ["Угольный клинок" if has_blade else "Кузница ждёт нового клинка", int(durability), int(quality), tribute_goal]
	heat_bar.value = heat
	quality_bar.value = quality
	strike.disabled = not has_blade
	sell.disabled = not has_blade
	tribute.disabled = gold < tribute_goal
	_save_game()

func _save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"gold":gold,"chapter":chapter,"tribute_goal":tribute_goal}))

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		gold = int(data.get("gold", gold))
		chapter = int(data.get("chapter", chapter))
		tribute_goal = int(data.get("tribute_goal", tribute_goal))
