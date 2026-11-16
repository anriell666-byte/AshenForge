extends Control

var hammer_angle: float = 0.0
var sparks: float = 0.0

func play_strike() -> void:
	hammer_angle = -0.45
	sparks = 1.0
	queue_redraw()

func _process(delta: float) -> void:
	hammer_angle = move_toward(hammer_angle, 0.0, delta * 2.8)
	sparks = move_toward(sparks, 0.0, delta * 1.8)
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
	# Blade resting on the anvil
	draw_colored_polygon(PackedVector2Array([
		Vector2(s.x*.35,s.y*.685), Vector2(s.x*.66,s.y*.665), Vector2(s.x*.57,s.y*.645),
		Vector2(s.x*.43,s.y*.655)
	]), Color("#c9d1d3"))
	draw_line(Vector2(s.x*.5,s.y*.67), Vector2(s.x*.5,s.y*.65), Color("#f6eee2"), 2.0)
	# Hammer silhouette
	var pivot := Vector2(s.x*.67, s.y*.58)
	draw_set_transform(pivot, hammer_angle, Vector2.ONE)
	draw_rect(Rect2(-s.x*.018, -s.y*.20, s.x*.036, s.y*.22), Color("#79533d"))
	draw_rect(Rect2(-s.x*.085, -s.y*.23, s.x*.17, s.y*.065), Color("#aaa3a8"))
	draw_rect(Rect2(-s.x*.085, -s.y*.23, s.x*.17, s.y*.018), Color("#d8c8b5"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if sparks > 0.0:
		for i in range(8):
			var a := float(i) * TAU / 8.0
			var p := Vector2(s.x*.5,s.y*.65) + Vector2(cos(a),sin(a)) * (22.0 + (1.0-sparks)*38.0)
			draw_circle(p, 2.5 * sparks, Color("#ffb34f", sparks))
