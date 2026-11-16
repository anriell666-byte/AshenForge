extends Control

const GameState = preload("res://scripts/game_state.gd")
const ForgeSystem = preload("res://scripts/forge_system.gd")
const EconomySystem = preload("res://scripts/economy_system.gd")
const SaveManager = preload("res://scripts/save_manager.gd")
const FORGE_SCENE = preload("res://scenes/ForgeView.tscn")

var state = GameState.new()
var forge = ForgeSystem.new()
var economy = EconomySystem.new()
var forge_view: Control
var header_label: Label
var weapon_label: Label
var stats_label: Label
var progression_label: Label
var frenzy_label: Label
var heat_bar: ProgressBar
var quality_bar: ProgressBar
var durability_bar: ProgressBar
var message_label: Label
var strike_button: Button
var sell_button: Button
var tribute_button: Button
var cool_button: Button
var upgrade_button: Button

func _ready() -> void:
	randomize()
	SaveManager.load_game(state)
	_build_screen()
	_refresh()

func _build_screen() -> void:
	forge_view = FORGE_SCENE.instantiate()
	forge_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(forge_view)
	move_child(forge_view, 0)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	header_label = Label.new()
	header_label.text = "ASHENFORGE"
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.add_theme_font_size_override("font_size", 29)
	header_label.add_theme_color_override("font_color", Color("#f0d6b2"))
	column.add_child(header_label)

	var spacer_top := Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer_top)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	column.add_child(panel)
	var panel_column := VBoxContainer.new()
	panel_column.add_theme_constant_override("separation", 6)
	panel.add_child(panel_column)

	weapon_label = Label.new()
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_label.add_theme_font_size_override("font_size", 19)
	weapon_label.add_theme_color_override("font_color", Color("#f0d6b2"))
	panel_column.add_child(weapon_label)

	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 14)
	panel_column.add_child(stats_label)

	progression_label = Label.new()
	progression_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progression_label.add_theme_color_override("font_color", Color("#d7c18e"))
	panel_column.add_child(progression_label)

	frenzy_label = Label.new()
	frenzy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frenzy_label.add_theme_font_size_override("font_size", 14)
	frenzy_label.add_theme_color_override("font_color", Color("#ffad58"))
	panel_column.add_child(frenzy_label)

	heat_bar = _make_bar(panel_column, "Накал клинка", Color("#e67e45"))
	quality_bar = _make_bar(panel_column, "Качество клинка", Color("#d7c18e"))
	durability_bar = _make_bar(panel_column, "Прочность", Color("#8fae9b"))

	message_label = Label.new()
	message_label.text = "Куй клинок. Десятый удар зарядит шквал FRENZY."
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size.y = 52
	message_label.add_theme_color_override("font_color", Color("#e4d5c4"))
	column.add_child(message_label)

	strike_button = _make_button("УДАРИТЬ МОЛОТОМ")
	strike_button.custom_minimum_size.y = 62
	strike_button.pressed.connect(_on_strike)
	column.add_child(strike_button)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	cool_button = _make_button("Остудить")
	cool_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cool_button.pressed.connect(_on_cool)
	row.add_child(cool_button)
	sell_button = _make_button("Продать")
	sell_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_button.pressed.connect(_on_sell)
	row.add_child(sell_button)

	tribute_button = _make_button("Принести дань дракону")
	tribute_button.pressed.connect(_on_tribute)
	column.add_child(tribute_button)

	upgrade_button = _make_button("Улучшить мехи • 45 золота")
	upgrade_button.pressed.connect(_on_upgrade)
	column.add_child(upgrade_button)

	var footer := Label.new()
	footer.text = "КОНТРАКТ • РЕЛИКВИИ • ДРАКОН"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", Color("#9d929f"))
	column.add_child(footer)

	var spacer_bottom := Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer_bottom)

func _panel_style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.065, 0.94)
	style.border_color = Color("#66515a")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12)
	return style

func _make_bar(parent: VBoxContainer, caption: String, fill: Color) -> ProgressBar:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", 12)
	parent.add_child(label)
	var bar := ProgressBar.new()
	bar.max_value = 100
	bar.show_percentage = false
	bar.custom_minimum_size.y = 12
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#29232d")
	bg.set_corner_radius_all(5)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	parent.add_child(bar)
	return bar

func _make_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 50
	button.add_theme_font_size_override("font_size", 16)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#49343a")
	normal.border_color = Color("#9a705c")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(9)
	normal.set_content_margin_all(8)
	var hover := normal.duplicate()
	hover.bg_color = Color("#62434a")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	return button

func _on_strike() -> void:
	var result: Dictionary = forge.strike(state)
	message_label.text = str(result.get("message", ""))
	if forge_view.has_method("play_strike"):
		forge_view.play_strike()
	_refresh()

func _on_cool() -> void:
	message_label.text = forge.cool(state)
	_refresh()

func _on_sell() -> void:
	var result: Dictionary = economy.sell_blade(state)
	message_label.text = str(result.get("message", ""))
	if bool(result.get("ok", false)):
		forge.start_new_blade(state)
	_refresh()

func _on_tribute() -> void:
	var result: Dictionary = economy.pay_tribute(state)
	message_label.text = str(result.get("message", ""))
	_refresh()

func _on_upgrade() -> void:
	var result: Dictionary = economy.buy_upgrade(state, "bellows")
	message_label.text = str(result.get("message", ""))
	_refresh()

func _refresh() -> void:
	header_label.text = "ASHENFORGE  •  ДЕНЬ %d/%d" % [state.day, state.contract_days]
	weapon_label.text = state.weapon_name if state.has_blade else "Кузница ждёт новой заготовки"
	stats_label.text = "Золото: %d     Дань: %d     Лучший клинок: %d" % [state.gold, state.tribute_goal, state.best_sale]
	progression_label.text = "Удары по клинку: %d/%d     Глава: %d" % [state.strikes_on_blade, forge.STRIKES_FOR_FRENZY, state.chapter]
	if state.frenzy_hits > 0:
		frenzy_label.text = "FRENZY АКТИВЕН • безопасных ударов: %d" % state.frenzy_hits
	elif state.frenzy_ready:
		frenzy_label.text = "FRENZY ЗАРЯЖЕН • следующий удар!"
	else:
		frenzy_label.text = "Заряд FRENZY: %d%%" % int(minf(100.0, float(state.strikes_on_blade) / float(forge.STRIKES_FOR_FRENZY) * 100.0))
	heat_bar.value = state.heat
	quality_bar.value = state.quality
	durability_bar.value = state.durability
	strike_button.disabled = not state.has_blade
	sell_button.disabled = not state.has_blade
	cool_button.disabled = not state.has_blade
	tribute_button.disabled = state.gold < state.tribute_goal or state.contract_complete
	upgrade_button.disabled = state.gold < 45 * (int(state.upgrades.get("bellows", 0)) + 1) or int(state.upgrades.get("bellows", 0)) >= 5
	upgrade_button.text = "Улучшить мехи • %d золота" % (45 * (int(state.upgrades.get("bellows", 0)) + 1))
	if state.contract_complete:
		tribute_button.text = "КОНТРАКТ ЗАВЕРШЁН • ДРАКОН ЖДЁТ"
	SaveManager.save_game(state)
