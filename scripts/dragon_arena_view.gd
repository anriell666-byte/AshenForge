extends Control

var pulse := 0.0
var hit_flash := 0.0

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
	draw_rect(Rect2(Vector2.ZERO, s), Color("#100e16"))
	for i in range(7):
		var x := float(i) * s.x / 6.0
		draw_line(Vector2(x, 0), Vector2(s.x * 0.5 + (x - s.x * 0.5) * 0.35, s.y * 0.82), Color("#29212d"), 2.0)
	draw_circle(Vector2(s.x * 0.5, s.y * 0.39), s.x * (0.30 + sin(pulse) * 0.008), Color(0.48, 0.12, 0.10, 0.12))
	# Distant volcanic arch
	draw_arc(Vector2(s.x * 0.5, s.y * 0.49), s.x * 0.42, PI, TAU, 48, Color("#59404a"), 8.0)
	# Dragon wings
	var wing := Color("#34232e")
	draw_colored_polygon(PackedVector2Array([Vector2(s.x*.46,s.y*.36),Vector2(s.x*.12,s.y*.16),Vector2(s.x*.19,s.y*.48),Vector2(s.x*.32,s.y*.43),Vector2(s.x*.43,s.y*.54)]), wing)
	draw_colored_polygon(PackedVector2Array([Vector2(s.x*.54,s.y*.36),Vector2(s.x*.88,s.y*.16),Vector2(s.x*.81,s.y*.48),Vector2(s.x*.68,s.y*.43),Vector2(s.x*.57,s.y*.54)]), wing)
	# Neck, head and body
	draw_ellipse(Vector2(s.x*.5,s.y*.48), Vector2(s.x*.19,s.y*.18), Color("#4b3035"))
	draw_colored_polygon(PackedVector2Array([Vector2(s.x*.43,s.y*.42),Vector2(s.x*.36,s.y*.23),Vector2(s.x*.43,s.y*.18),Vector2(s.x*.52,s.y*.31),Vector2(s.x*.57,s.y*.40)]), Color("#604047"))
	draw_colored_polygon(PackedVector2Array([Vector2(s.x*.49,s.y*.29),Vector2(s.x*.58,s.y*.22),Vector2(s.x*.68,s.y*.26),Vector2(s.x*.62,s.y*.34),Vector2(s.x*.52,s.y*.35)]), Color("#76504a"))
	draw_colored_polygon(PackedVector2Array([Vector2(s.x*.62,s.y*.27),Vector2(s.x*.72,s.y*.29),Vector2(s.x*.65,s.y*.34)]), Color("#4b3035"))
	draw_line(Vector2(s.x*.58,s.y*.24), Vector2(s.x*.55,s.y*.16), Color("#b18b69"), 5.0)
	draw_line(Vector2(s.x*.65,s.y*.25), Vector2(s.x*.69,s.y*.18), Color("#b18b69"), 5.0)
	var eye_glow := Color("#ffb44d", 0.75 + sin(pulse * 2.0) * 0.2)
	draw_circle(Vector2(s.x*.615,s.y*.275), 5.0 + hit_flash * 2.0, eye_glow)
	# Fire glow and arena floor
	draw_circle(Vector2(s.x*.5,s.y*.66), s.x*.22, Color(0.9,0.23,0.07,0.08 + sin(pulse)*0.025))
	draw_rect(Rect2(0,s.y*.73,s.x,s.y*.27), Color("#211923"))
	for i in range(5):
		draw_line(Vector2(s.x*.1 + i*s.x*.2,s.y*.74), Vector2(s.x*.5,s.y*.98), Color("#45323b"), 2.0)

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var a := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(points, color)
