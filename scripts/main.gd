extends Control

const GameState = preload("res://scripts/game_state.gd")
const ForgeSystem = preload("res://scripts/forge_system.gd")
const EconomySystem = preload("res://scripts/economy_system.gd")
const RelicSystem = preload("res://scripts/relic_system.gd")
const WeaponSystem = preload("res://scripts/weapon_system.gd")
const MerchantSystem = preload("res://scripts/merchant_system.gd")
const SaveManager = preload("res://scripts/save_manager.gd")
const FORGE_SCENE = preload("res://scenes/ForgeView.tscn")
const DragonCombat = preload("res://scripts/dragon_combat.gd")
const DRAGON_VIEW_SCRIPT = preload("res://scripts/dragon_arena_view.gd")

var state = GameState.new()
var forge = ForgeSystem.new()
var economy = EconomySystem.new()
var relic_machine = RelicSystem.new()
var weapon_system = WeaponSystem.new()
var merchant = MerchantSystem.new()
var dragon_combat = DragonCombat.new()
var forge_ui: Control
var dragon_view: Control
var battle_overlay: PanelContainer
var battle_button: Button
var battle_title: Label
var battle_status: Label
var battle_message: String = "Пламя древнего существа освещает зал."
var battle_intent: Label
var dragon_health_bar: ProgressBar
var player_health_bar: ProgressBar
var forge_view: Control
var header_label: Label
var weapon_label: Label
var stats_label: Label
var progression_label: Label
var ability_label: Label
var frenzy_label: Label
var relic_label: Label
var heat_bar: ProgressBar
var quality_bar: ProgressBar
var durability_bar: ProgressBar
var message_label: Label
var strike_button: Button
var sell_button: Button
var tribute_button: Button
var cool_button: Button
var upgrade_buttons: Array[Button] = []
var relic_button: Button
var weapon_select_button: Button
var merchant_button: Button
var merchant_panel: PanelContainer
var merchant_status: Label
var merchant_offer_labels: Array[Label] = []
var merchant_buy_buttons: Array[Button] = []

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

	forge_ui = MarginContainer.new()
	forge_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := forge_ui
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

	ability_label = Label.new()
	ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ability_label.add_theme_font_size_override("font_size", 12)
	ability_label.add_theme_color_override("font_color", Color("#d7c18e"))
	panel_column.add_child(ability_label)

	frenzy_label = Label.new()
	frenzy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frenzy_label.add_theme_font_size_override("font_size", 14)
	frenzy_label.add_theme_color_override("font_color", Color("#ffad58"))
	panel_column.add_child(frenzy_label)

	heat_bar = _make_bar(panel_column, "Накал клинка", Color("#e67e45"))
	quality_bar = _make_bar(panel_column, "Качество клинка", Color("#d7c18e"))
	durability_bar = _make_bar(panel_column, "Прочность", Color("#8fae9b"))

	relic_label = Label.new()
	relic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	relic_label.add_theme_font_size_override("font_size", 12)
	relic_label.add_theme_color_override("font_color", Color("#c6a6e0"))
	panel_column.add_child(relic_label)

	message_label = Label.new()
	message_label.text = "Куй клинок. Десятый удар зарядит шквал FRENZY."
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size.y = 52
	message_label.add_theme_color_override("font_color", Color("#e4d5c4"))
	column.add_child(message_label)

	weapon_select_button = _make_button("СЛЕДУЮЩАЯ ЗАГОТОВКА")
	weapon_select_button.pressed.connect(_on_cycle_weapon)
	column.add_child(weapon_select_button)

	merchant_button = _make_button("ТОРГОВЕЦ • РЕДКИЕ ЧЕРТЕЖИ")
	merchant_button.pressed.connect(_on_toggle_merchant)
	column.add_child(merchant_button)

	merchant_panel = PanelContainer.new()
	merchant_panel.add_theme_stylebox_override("panel", _panel_style())
	merchant_panel.visible = false
	column.add_child(merchant_panel)
	var merchant_column := VBoxContainer.new()
	merchant_column.add_theme_constant_override("separation", 5)
	merchant_panel.add_child(merchant_column)
	var merchant_title := Label.new()
	merchant_title.text = "СТРАНСТВУЮЩИЙ ТОРГОВЕЦ"
	merchant_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	merchant_title.add_theme_color_override("font_color", Color("#e4c28f"))
	merchant_column.add_child(merchant_title)
	merchant_status = Label.new()
	merchant_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	merchant_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	merchant_column.add_child(merchant_status)
	for index in range(3):
		var offer_label := Label.new()
		offer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		offer_label.add_theme_font_size_override("font_size", 12)
		merchant_column.add_child(offer_label)
		merchant_offer_labels.append(offer_label)
		var buy_button := _make_button("Купить чертёж")
		buy_button.custom_minimum_size.y = 42
		buy_button.add_theme_font_size_override("font_size", 14)
		buy_button.pressed.connect(_on_buy_offer.bind(index))
		merchant_column.add_child(buy_button)
		merchant_buy_buttons.append(buy_button)

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

	relic_button = _make_button("Пожертвовать клинок машине реликвий")
	relic_button.pressed.connect(_on_relic)
	column.add_child(relic_button)

	tribute_button = _make_button("Принести дань дракону")
	tribute_button.pressed.connect(_on_tribute)
	column.add_child(tribute_button)

	battle_button = _make_button("ВОЙТИ В ЛОГОВО ДРАКОНА")
	battle_button.pressed.connect(_on_enter_dragon_lair)
	column.add_child(battle_button)

	var upgrade_row := HBoxContainer.new()
	upgrade_row.add_theme_constant_override("separation", 6)
	column.add_child(upgrade_row)
	for upgrade_id in ["bellows", "anvil", "luck"]:
		var upgrade_button := _make_button("")
		upgrade_button.custom_minimum_size.y = 46
		upgrade_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		upgrade_button.add_theme_font_size_override("font_size", 11)
		upgrade_button.pressed.connect(_on_upgrade.bind(upgrade_id))
		upgrade_row.add_child(upgrade_button)
		upgrade_buttons.append(upgrade_button)

	var footer := Label.new()
	footer.text = "КОНТРАКТ • РЕЛИКВИИ • ТОРГОВЕЦ • ДРАКОН"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", Color("#9d929f"))
	column.add_child(footer)

	var spacer_bottom := Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer_bottom)
	_build_battle_overlay()


func _build_battle_overlay() -> void:
	dragon_view = Control.new()
	dragon_view.set_script(DRAGON_VIEW_SCRIPT)
	dragon_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dragon_view.visible = false
	add_child(dragon_view)
	move_child(dragon_view, 1)

	battle_overlay = PanelContainer.new()
	battle_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_overlay.add_theme_stylebox_override("panel", _panel_style())
	battle_overlay.visible = false
	add_child(battle_overlay)
	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 24)
	outer.add_theme_constant_override("margin_right", 24)
	outer.add_theme_constant_override("margin_top", 34)
	outer.add_theme_constant_override("margin_bottom", 34)
	battle_overlay.add_child(outer)
	var battle_column := VBoxContainer.new()
	battle_column.add_theme_constant_override("separation", 12)
	outer.add_child(battle_column)
	var top_space := Control.new()
	top_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_column.add_child(top_space)
	battle_title = Label.new()
	battle_title.text = "ЛОГОВО ДРАКОНА"
	battle_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_title.add_theme_font_size_override("font_size", 26)
	battle_title.add_theme_color_override("font_color", Color("#f0c18e"))
	battle_column.add_child(battle_title)
	battle_status = Label.new()
	battle_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_status.custom_minimum_size.y = 64
	battle_status.add_theme_color_override("font_color", Color("#ead9c8"))
	battle_column.add_child(battle_status)
	dragon_health_bar = _make_bar(battle_column, "ЗДОРОВЬЕ ДРАКОНА", Color("#bd514b"))
	player_health_bar = _make_bar(battle_column, "ТВОЁ ЗДОРОВЬЕ", Color("#8fae9b"))
	battle_intent = Label.new()
	battle_intent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_intent.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_intent.custom_minimum_size.y = 48
	battle_intent.add_theme_color_override("font_color", Color("#ffb45e"))
	battle_intent.add_theme_font_size_override("font_size", 17)
	battle_column.add_child(battle_intent)
	var attack := _make_button("⚔  УДАРИТЬ КЛИНКОМ")
	attack.custom_minimum_size.y = 62
	attack.pressed.connect(_on_battle_action.bind("attack"))
	battle_column.add_child(attack)
	var defense_row := HBoxContainer.new()
	defense_row.add_theme_constant_override("separation", 8)
	battle_column.add_child(defense_row)
	var dodge := _make_button("Уклониться")
	dodge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dodge.pressed.connect(_on_battle_action.bind("dodge"))
	defense_row.add_child(dodge)
	var guard := _make_button("Блок")
	guard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guard.pressed.connect(_on_battle_action.bind("guard"))
	defense_row.add_child(guard)
	var leave := _make_button("Отступить в кузницу")
	leave.pressed.connect(_on_leave_battle)
	battle_column.add_child(leave)
	var bottom_space := Control.new()
	bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_column.add_child(bottom_space)

func _on_enter_dragon_lair() -> void:
	var result: Dictionary = dragon_combat.begin(state)
	message_label.text = str(result.get("message", ""))
	battle_message = str(result.get("message", "Пламя древнего существа освещает зал."))
	if bool(result.get("ok", false)):
		_refresh()

func _on_battle_action(action: String) -> void:
	var result: Dictionary = dragon_combat.act(state, action)
	battle_message = str(result.get("message", ""))
	if dragon_view.has_method("play_hit") and action == "attack":
		dragon_view.play_hit()
	if bool(result.get("won", false)) or bool(result.get("lost", false)):
		message_label.text = str(result.get("message", ""))
	_refresh()

func _on_leave_battle() -> void:
	state.battle_active = false
	battle_message = "Ты отступил в кузницу. Дракон останется ждать следующей попытки."
	message_label.text = battle_message
	_refresh()

func _update_battle_ui() -> void:
	var in_battle: bool = state.battle_active
	battle_overlay.visible = in_battle
	dragon_view.visible = in_battle
	forge_ui.visible = not in_battle
	if not in_battle:
		return
	battle_title.text = "%s  •  РАУНД %d" % [dragon_combat.form_name(state), state.dragon_round]
	if dragon_view.has_method("set_dragon_form"):
		dragon_view.set_dragon_form(state.dragon_form)
	battle_status.text = battle_message
	battle_intent.text = dragon_combat.intent_text(state)
	dragon_health_bar.max_value = maxf(1.0, state.dragon_max_hp)
	dragon_health_bar.value = state.dragon_hp
	player_health_bar.max_value = 120.0
	player_health_bar.value = state.player_hp

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

func _on_toggle_merchant() -> void:
	merchant_panel.visible = not merchant_panel.visible
	_refresh()

func _on_buy_offer(index: int) -> void:
	var offers := merchant.stock(state)
	if index >= offers.size():
		message_label.text = "У торговца пока нет подходящего товара."
		_refresh()
		return
	var result: Dictionary = merchant.buy_weapon(state, str(offers[index].id))
	message_label.text = str(result.get("message", ""))
	_refresh()

func _on_cycle_weapon() -> void:
	state.selected_weapon_id = weapon_system.next_weapon_id(state, state.selected_weapon_id)
	var selected: Dictionary = weapon_system.get_weapon(state.selected_weapon_id)
	message_label.text = "Выбрана следующая заготовка: %s. Текущий клинок не изменён." % str(selected.name)
	_refresh()

func _on_strike() -> void:
	var result: Dictionary = forge.strike(state)
	message_label.text = str(result.get("message", ""))
	if forge_view.has_method("play_strike"):
		forge_view.play_strike()
	if str(result.get("message", "")).contains("ПРОБУЖДЕНИЕ!") and forge_view.has_method("play_awakening"):
		forge_view.play_awakening()
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

func _on_relic() -> void:
	var result: Dictionary = relic_machine.sacrifice_blade(state)
	message_label.text = str(result.get("message", ""))
	if bool(result.get("ok", false)):
		forge.start_new_blade(state)
	_refresh()

func _on_tribute() -> void:
	var result: Dictionary = economy.pay_tribute(state)
	message_label.text = str(result.get("message", ""))
	_refresh()

func _on_upgrade(upgrade_id: String) -> void:
	var result: Dictionary = economy.buy_upgrade(state, upgrade_id)
	message_label.text = str(result.get("message", ""))
	_refresh()

func _refresh() -> void:
	if forge_view.has_method("set_blade_visual"):
		forge_view.set_blade_visual(state.weapon_id, state.weapon_awakened and state.awakened_weapon_id == state.weapon_id)
	header_label.text = "ASHENFORGE  •  ДЕНЬ %d/%d" % [state.day, state.contract_days]
	weapon_label.text = state.weapon_name if state.has_blade else "Кузница ждёт новой заготовки"
	stats_label.text = "Золото: %d     Дань: %d     Лучший клинок: %d" % [state.gold, state.tribute_goal, state.best_sale]
	progression_label.text = "Удары: %d/%d   Глава: %d   Победы над драконами: %d" % [state.strikes_on_blade, forge.STRIKES_FOR_FRENZY, state.chapter, state.dragon_victories]
	ability_label.text = weapon_system.final_form_status(state)
	if state.frenzy_hits > 0:
		frenzy_label.text = "FRENZY АКТИВЕН • безопасных ударов: %d" % state.frenzy_hits
	elif state.frenzy_ready:
		frenzy_label.text = "FRENZY ЗАРЯЖЕН • следующий удар!"
	else:
		frenzy_label.text = "Заряд FRENZY: %d%%" % int(minf(100.0, float(state.strikes_on_blade) / float(forge.STRIKES_FOR_FRENZY) * 100.0))
	heat_bar.value = state.heat
	quality_bar.value = state.quality
	durability_bar.value = state.durability
	relic_label.text = relic_machine.summary(state)
	var selected: Dictionary = weapon_system.get_weapon(state.selected_weapon_id)
	weapon_select_button.text = "СЛЕДУЮЩАЯ ЗАГОТОВКА: %s" % str(selected.name)
	weapon_select_button.disabled = weapon_system.unlocked(state).size() <= 1
	strike_button.disabled = not state.has_blade
	sell_button.disabled = not state.has_blade
	cool_button.disabled = not state.has_blade
	relic_button.disabled = not state.has_blade
	tribute_button.disabled = state.gold < state.tribute_goal or state.contract_complete
	var upgrade_ids := ["bellows", "anvil", "luck"]
	for index in range(upgrade_buttons.size()):
		var upgrade_id: String = upgrade_ids[index]
		var level := int(state.upgrades.get(upgrade_id, 0))
		var cost := economy.upgrade_cost(state, upgrade_id)
		upgrade_buttons[index].text = "%s\nУР. %d • %d" % [economy.upgrade_name(upgrade_id), level, cost]
		upgrade_buttons[index].disabled = state.gold < cost or level >= 5
		upgrade_buttons[index].tooltip_text = economy.upgrade_description(upgrade_id)
	if state.contract_complete:
		tribute_button.text = "КОНТРАКТ ЗАВЕРШЁН • ДРАКОН ЖДЁТ"
	battle_button.disabled = not state.contract_complete or not state.has_blade
	battle_button.text = "НОВАЯ ОХОТА • %s" % dragon_combat.FORM_NAMES[state.dragon_victories % dragon_combat.FORM_NAMES.size()] if state.dragon_defeated else "ВОЙТИ В ЛОГОВО ДРАКОНА"

	var offers := merchant.stock(state)
	var owned_count := merchant.rare_owned_count(state)
	merchant_status.text = "Золото: %d • редких чертежей собрано: %d/3" % [state.gold, owned_count]
	for index in range(merchant_offer_labels.size()):
		if index < offers.size():
			var offer: Dictionary = offers[index]
			merchant_offer_labels[index].text = merchant.offer_text(offer)
			merchant_offer_labels[index].visible = true
			merchant_buy_buttons[index].visible = true
			merchant_buy_buttons[index].disabled = state.gold < int(offer.price) or state.owned_weapon_ids.has(str(offer.id))
			merchant_buy_buttons[index].text = "Уже куплено" if state.owned_weapon_ids.has(str(offer.id)) else "Купить • %d золота" % int(offer.price)
		else:
			merchant_offer_labels[index].visible = false
			merchant_buy_buttons[index].visible = false
	_update_battle_ui()
	SaveManager.save_game(state)
