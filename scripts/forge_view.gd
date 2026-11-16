extends Control

var hammer_angle: float = 0.0
var sparks: float = 0.0
var awakening_flash: float = 0.0
var aura_phase: float = 0.0
var current_weapon_id: String = "coal_blade"
var blade_awakened: bool = false

func set_blade_visual(weapon_id: String, awakened: bool) -> void:
	current_weapon_id = weapon_id
	blade_awakened = awakened
	queue_redraw()

func play_awakening() -> void:
	awakening_flash = 1.0
	sparks = 1.0
	hammer_angle = -0.7
	queue_redraw()

func play_strike() -> void:
	hammer_angle = -0.45
	sparks = 1.0
	queue_redraw()

func _process(delta: float) -> void:
	hammer_angle = move_toward(hammer_angle, 0.0, delta * 2.8)
	sparks = move_toward(sparks, 0.0, delta * 1.8)
	awakening_flash = move_toward(awakening_flash, 0.0, delta * 0.65)
	aura_phase = fposmod(aura_phase + delta * 2.2, TAU)
	queue_redraw()

func _draw() -> void:
	var s := size
	if s.x < 10.0 or s.y < 10.0:
		s = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, s), Color("#17131a"))
	draw_rect(Rect2(0, 0, s.x, s.y * 0.58), Color("#211c25"))
	for x in range(-40, int(s.x) + 100, 90):
		draw_line(Vector2(x, 0), Vector2(x - 34, s.y * 0.58), Color("#302833"), 3.0)
	# Furnace arch and fire
	draw_circle(Vector2(s.x * 0.5, s.y * 0.43), s.x * 0.235, Color("#39252a"))
	draw_circle(Vector2(s.x * 0.5, s.y * 0.43), s.x * 0.185, Color("#100e13"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(s.x*.39,s.y*.52), Vector2(s.x*.43,s.y*.43), Vector2(s.x*.48,s.y*.50),
		Vector2(s.x*.53,s.y*.40), Vector2(s.x*.61,s.y*.52), Vector2(s.x*.56,s.y*.57),
		Vector2(s.x*.43,s.y*.57)
	]), Color("#f47a27"))
	draw_circle(Vector2(s.x * 0.5, s.y * 0.50), s.x * 0.045, Color(1.0, 0.72, 0.28, 0.7))
	# Stone anvil
	draw_colored_polygon(PackedVector2Array([
		Vector2(s.x*.22,s.y*.69), Vector2(s.x*.78,s.y*.69), Vector2(s.x*.72,s.y*.75),
		Vector2(s.x*.65,s.y*.78), Vector2(s.x*.35,s.y*.78), Vector2(s.x*.28,s.y*.75)
	]), Color("#85818b"))
	draw_rect(Rect2(s.x*.39,s.y*.76,s.x*.22,s.y*.075), Color("#49434e"))
	draw_rect(Rect2(s.x*.34,s.y*.83,s.x*.32,s.y*.025), Color("#29242d"))
	# Blade resting on the anvil; each steel family has its own forged tint.
	var blade_color := Color("#c9d1d3")
	var edge_color := Color("#f6eee2")
	match current_weapon_id:
		"ember_sabre":
			blade_color = Color("#e9a05b")
			edge_color = Color("#fff0c4")
		"wyrmfang":
			blade_color = Color("#a9b7bd")
			edge_color = Color("#e8f4f4")
		"glassfang":
			blade_color = Color("#a9d9d8")
			edge_color = Color("#e3ffff")
		"frostbite":
			blade_color = Color("#8fc9e8")
			edge_color = Color("#e1f7ff")
		"bloodiron":
			blade_color = Color("#a85c62")
			edge_color = Color("#ffc0a7")
	var blade_center := Vector2(s.x*.505, s.y*.665)
	if blade_awakened:
		var pulse := 0.5 + 0.5 * sin(aura_phase)
		var aura_alpha := 0.12 + pulse * 0.13 + awakening_flash * 0.42
		draw_circle(blade_center, s.x * (0.12 + pulse * 0.025), Color(blade_color, aura_alpha))
		draw_circle(blade_center, s.x * (0.075 + pulse * 0.018), Color(edge_color, aura_alpha * 0.7))
	draw_colored_polygon(PackedVector2Array([
		Vector2(s.x*.35,s.y*.685), Vector2(s.x*.66,s.y*.665), Vector2(s.x*.57,s.y*.645),
		Vector2(s.x*.43,s.y*.655)
	]), blade_color)
	draw_line(Vector2(s.x*.5,s.y*.67), Vector2(s.x*.5,s.y*.65), edge_color, 2.0)
	if blade_awakened:
		# Fine glowing runes along the blade, kept large enough to read on a phone.
		for rune_index in range(3):
			var rune_x := s.x * (0.445 + float(rune_index) * 0.035)
			var rune_y := s.y * (0.669 - float(rune_index) * 0.002)
			draw_line(Vector2(rune_x - 5.0, rune_y), Vector2(rune_x + 5.0, rune_y - 4.0), edge_color, 2.0)
			draw_circle(Vector2(rune_x, rune_y - 2.0), 1.8, edge_color)
	# Hammer silhouette
	var pivot := Vector2(s.x*.67, s.y*.58)
	draw_set_transform(pivot, hammer_angle, Vector2.ONE)
	draw_rect(Rect2(-s.x*.018, -s.y*.20, s.x*.036, s.y*.22), Color("#79533d"))
	draw_rect(Rect2(-s.x*.085, -s.y*.23, s.x*.17, s.y*.065), Color("#aaa3a8"))
	draw_rect(Rect2(-s.x*.085, -s.y*.23, s.x*.17, s.y*.018), Color("#d8c8b5"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if sparks > 0.0:
		for i in range(12 if awakening_flash > 0.0 else 8):
			var a := float(i) * TAU / float(12 if awakening_flash > 0.0 else 8)
			var radius := 22.0 + (1.0-sparks)*38.0
			var p := Vector2(s.x*.5,s.y*.65) + Vector2(cos(a),sin(a)) * radius
			var spark_color := Color("#ffb34f", sparks)
			if awakening_flash > 0.0:
				spark_color = Color("#fff0b5", minf(1.0, sparks + awakening_flash * 0.3))
			draw_circle(p, (2.5 + awakening_flash * 2.0) * sparks, spark_color)
