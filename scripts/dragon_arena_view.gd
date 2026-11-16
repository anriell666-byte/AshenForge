extends Control

var pulse := 0.0
var hit_flash := 0.0
var dragon_form := 0

func set_dragon_form(form: int) -> void:
	dragon_form = clampi(form, 0, 2)
	queue_redraw()

func play_hit() -> void:
	hit_flash = 1.0

func _process(delta: float) -> void:
	pulse = fposmod(pulse + delta * 1.5, TAU)
	hit_flash = move_toward(hit_flash, 0.0, delta * 2.5)
	queue_redraw()

func _draw() -> void:
	var s := size
	if s.x < 10.0 or s.y < 10.0:
		s = get_viewport_rect().size
	var body_color := Color("#4b3035")
	var wing_color := Color("#34232e")
	var head_color := Color("#604047")
	var horn_color := Color("#b18b69")
	var eye_color := Color("#ffb44d")
	var aura_color := Color(0.9, 0.23, 0.07, 0.08 + sin(pulse) * 0.025)
	match dragon_form:
		1:
			body_color = Color("#71352b")
			wing_color = Color("#54251f")
			head_color = Color("#a64d2e")
			horn_color = Color("#f0a45c")
			eye_color = Color("#fff07a")
			aura_color = Color(1.0, 0.28, 0.04, 0.12 + sin(pulse) * 0.04)
		2:
			body_color = Color("#302b50")
			wing_color = Color("#211d3d")
			head_color = Color("#514477")
			horn_color = Color("#a99be8")
			eye_color = Color("#b8f4ff")
			aura_color = Color(0.25, 0.32, 1.0, 0.12 + sin(pulse) * 0.04)
	draw_rect(Rect2(Vector2.ZERO, s), Color("#100e16"))
	for i in range(7):
		var x := float(i) * s.x / 6.0
		draw_line(Vector2(x, 0), Vector2(s.x * 0.5 + (x - s.x * 0.5) * 0.35, s.y * 0.82), Color("#29212d"), 2.0)
	draw_circle(Vector2(s.x * 0.5, s.y * 0.39), s.x * (0.30 + sin(pulse) * 0.008), aura_color)
	draw_arc(Vector2(s.x * 0.5, s.y * 0.49), s.x * 0.42, PI, TAU, 48, Color("#59404a"), 8.0)
	draw_colored_polygon(PackedVector2Array([Vector2(s.x*.46,s.y*.36),Vector2(s.x*.12,s.y*.16),Vector2(s.x*.19,s.y*.48),Vector2(s.x*.32,s.y*.43),Vector2(s.x*.43,s.y*.54)]), wing_color)
	draw_colored_polygon(PackedVector2Array([Vector2(s.x*.54,s.y*.36),Vector2(s.x*.88,s.y*.16),Vector2(s.x*.81,s.y*.48),Vector2(s.x*.68,s.y*.43),Vector2(s.x*.57,s.y*.54)]), wing_color)
	draw_ellipse(Vector2(s.x*.5,s.y*.48), Vector2(s.x*.19,s.y*.18), body_color)
	draw_colored_polygon(PackedVector2Array([Vector2(s.x*.43,s.y*.42),Vector2(s.x*.36,s.y*.23),Vector2(s.x*.43,s.y*.18),Vector2(s.x*.52,s.y*.31),Vector2(s.x*.57,s.y*.40)]), head_color)
	draw_colored_polygon(PackedVector2Array([Vector2(s.x*.49,s.y*.29),Vector2(s.x*.58,s.y*.22),Vector2(s.x*.68,s.y*.26),Vector2(s.x*.62,s.y*.34),Vector2(s.x*.52,s.y*.35)]), head_color.lightened(0.12))
	draw_colored_polygon(PackedVector2Array([Vector2(s.x*.62,s.y*.27),Vector2(s.x*.72,s.y*.29),Vector2(s.x*.65,s.y*.34)]), body_color)
	draw_line(Vector2(s.x*.58,s.y*.24), Vector2(s.x*.55,s.y*.16), horn_color, 5.0)
	draw_line(Vector2(s.x*.65,s.y*.25), Vector2(s.x*.69,s.y*.18), horn_color, 5.0)
	draw_circle(Vector2(s.x*.615,s.y*.275), 5.0 + hit_flash * 2.0, eye_color)
	draw_circle(Vector2(s.x*.5,s.y*.66), s.x*.22, aura_color)
	draw_rect(Rect2(0,s.y*.73,s.x,s.y*.27), Color("#211923"))
	for i in range(5):
		draw_line(Vector2(s.x*.1 + i*s.x*.2,s.y*.74), Vector2(s.x*.5,s.y*.98), Color("#45323b"), 2.0)

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var a := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(points, color)
