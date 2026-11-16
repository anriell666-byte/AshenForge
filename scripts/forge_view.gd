extends Control

var hammer_angle: float = 0.0
var sparks: float = 0.0
var awakening_flash: float = 0.0
var aura_phase: float = 0.0
var flame_phase: float = 0.0
var camera_yaw: float = 0.0
var camera_target: float = 0.0
var drag_origin: Vector2 = Vector2.ZERO
var drag_active: bool = false
var current_weapon_id: String = "coal_blade"
var blade_awakened: bool = false
var heat_level: float = 28.0
var quality_level: float = 8.0
var durability_level: float = 100.0
var forge_outcome: String = ""
var wall_weapons: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	set_process_input(true)

func set_wall_weapons(items: Array) -> void:
	wall_weapons = items.duplicate(true)
	queue_redraw()

func set_forge_state(heat: float, quality: float, durability: float, outcome: String) -> void:
	heat_level = clampf(heat, 0.0, 100.0)
	quality_level = clampf(quality, 0.0, 100.0)
	durability_level = clampf(durability, 0.0, 100.0)
	forge_outcome = outcome
	queue_redraw()

func set_blade_visual(weapon_id: String, awakened: bool) -> void:
	current_weapon_id = weapon_id
	blade_awakened = awakened
	queue_redraw()

func rotate_camera(direction: float) -> void:
	camera_target = clampf(camera_target + direction * 0.28, -0.62, 0.62)

func play_awakening() -> void:
	awakening_flash = 1.0
	sparks = 1.0
	hammer_angle = -0.8
	queue_redraw()

func play_strike() -> void:
	hammer_angle = -0.52
	sparks = 1.0
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			drag_origin = event.position
			drag_active = true
		else:
			if drag_active:
				var delta_x: float = float(event.position.x - drag_origin.x)
				if absf(delta_x) > 42.0 and absf(delta_x) > absf(event.position.y - drag_origin.y) * 1.25:
					if drag_origin.x < 105.0 or drag_origin.x > size.x - 105.0:
						rotate_camera(-signf(delta_x))
			drag_active = false
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_origin = event.position
			drag_active = true
		else:
			if drag_active:
				var delta_mouse: float = float(event.position.x - drag_origin.x)
				if absf(delta_mouse) > 42.0 and absf(delta_mouse) > absf(event.position.y - drag_origin.y) * 1.25:
					if drag_origin.x < 105.0 or drag_origin.x > size.x - 105.0:
						rotate_camera(-signf(delta_mouse))
			drag_active = false

func _process(delta: float) -> void:
	hammer_angle = move_toward(hammer_angle, 0.0, delta * 3.2)
	sparks = move_toward(sparks, 0.0, delta * 1.8)
	awakening_flash = move_toward(awakening_flash, 0.0, delta * 0.65)
	aura_phase = fposmod(aura_phase + delta * 2.2, TAU)
	flame_phase = fposmod(flame_phase + delta * 4.0, TAU)
	camera_yaw = lerpf(camera_yaw, camera_target, minf(1.0, delta * 5.0))
	queue_redraw()

func _draw() -> void:
	var s := size
	if s.x < 10.0 or s.y < 10.0:
		s = get_viewport_rect().size
	var cx := s.x * 0.5
	draw_rect(Rect2(Vector2.ZERO, s), Color("#100e14"))
	# Deep stone wall and perspective floor.
	draw_colored_polygon(PackedVector2Array([Vector2(0,0),Vector2(s.x,0),Vector2(s.x,s.y*0.68),Vector2(0,s.y*0.68)]), Color("#29232d"))
	for x in range(-80, int(s.x) + 120, 105):
		draw_line(Vector2(x,0), Vector2(x-42,s.y*0.68), Color("#39303b"), 3.0)
	for y in range(90, int(s.y*0.65), 100):
		draw_line(Vector2(0,y), Vector2(s.x,y), Color("#342b37"), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0,s.y*0.66),Vector2(s.x,s.y*0.66),Vector2(s.x*0.86,s.y),Vector2(s.x*0.14,s.y)]), Color("#19151d"))
	for i in range(7):
		var floor_x := s.x * (0.12 + float(i)*0.13)
		draw_line(Vector2(floor_x,s.y*0.7), Vector2(cx+(floor_x-cx)*1.42,s.y), Color("#302832"), 2.0)
	# Camera-responsive props: slight yaw creates a diorama/parallax feeling.
	draw_set_transform(Vector2(cx,s.y*0.42), camera_yaw*0.22, Vector2.ONE)
	# Furnace, with a deep arch, rim and animated flame.
	draw_colored_polygon(PackedVector2Array([Vector2(-s.x*.31,-s.y*.01),Vector2(s.x*.31,-s.y*.01),Vector2(s.x*.27,s.y*.23),Vector2(-s.x*.27,s.y*.23)]), Color("#51404a"))
	draw_circle(Vector2(0,s.y*.105), s.x*.205, Color("#171219"))
	draw_circle(Vector2(0,s.y*.105), s.x*.165, Color("#09080c"))
	var glow := 0.5 + 0.5*sin(flame_phase)
	draw_circle(Vector2(0,s.y*.12), s.x*(.12+glow*.018), Color(1.0,.25,.07,.18+glow*.12))
	for i in range(5):
		var fx := -s.x*.105 + float(i)*s.x*.052
		var fh := s.y*(.065+glow*.025+heat_level*.00018)
		draw_colored_polygon(PackedVector2Array([Vector2(fx-7,s.y*.19),Vector2(fx,s.y*.19-fh),Vector2(fx+8,s.y*.19)]), Color("#ff7b2c") if heat_level>60.0 else Color("#e6a04a"))
	# Wall rack with dimensional beams and eight collectible weapon hooks.
	draw_rect(Rect2(-s.x*.39,-s.y*.29,s.x*.78,s.y*.018), Color("#5d3c31"))
	draw_rect(Rect2(-s.x*.39,-s.y*.265,s.x*.78,s.y*.014), Color("#2d2023"))
	var wall_count := mini(wall_weapons.size(), 8)
	var wall_positions: Array[Vector2] = []
	for i in range(8):
		var wx := -s.x*.32 + float(i%4)*s.x*.213
		var wy := -s.y*.205 if i<4 else -s.y*.055
		draw_circle(Vector2(wx,wy), 5.0, Color("#c18a52"))
		if i < wall_count:
			wall_positions.append(Vector2(wx,wy+s.y*.055))
		else:
			draw_line(Vector2(wx,wy+8),Vector2(wx,wy+25),Color("#75523d"),3.0)
	# Anvil pedestal and anvil top, with top/side faces to sell the volume.
	draw_colored_polygon(PackedVector2Array([Vector2(-s.x*.29,s.y*.285),Vector2(s.x*.29,s.y*.285),Vector2(s.x*.24,s.y*.37),Vector2(-s.x*.24,s.y*.37)]), Color("#51434a"))
	draw_colored_polygon(PackedVector2Array([Vector2(-s.x*.36,s.y*.255),Vector2(s.x*.36,s.y*.255),Vector2(s.x*.29,s.y*.305),Vector2(-s.x*.29,s.y*.305)]), Color("#a3a0a4"))
	draw_line(Vector2(-s.x*.34,s.y*.26),Vector2(s.x*.34,s.y*.26),Color("#e2d6ca"),3.0)
	# Display the wall trophies after the room geometry so each weapon keeps its depth transform.
	for wall_index in range(wall_positions.size()):
		var trophy: Dictionary = wall_weapons[wall_index]
		_draw_weapon(wall_positions[wall_index], s.y*.105, str(trophy.get("weapon_id","coal_blade")), float(trophy.get("quality",0.0)), bool(trophy.get("awakened",false)), false)
	# Active blade lies across the anvil; its silhouette evolves with quality.
	_draw_weapon(Vector2(0,s.y*.247), s.x*.36, current_weapon_id, quality_level, blade_awakened, true)
	# Hammer with a heavy handle and metal head.
	var pivot := _camera_point(Vector2(s.x*.255,s.y*.16))
	draw_set_transform(pivot, hammer_angle, Vector2.ONE)
	draw_rect(Rect2(-s.x*.014,-s.y*.19,s.x*.028,s.y*.21), Color("#80583d"))
	draw_colored_polygon(PackedVector2Array([Vector2(-s.x*.09,-s.y*.22),Vector2(s.x*.09,-s.y*.22),Vector2(s.x*.075,-s.y*.15),Vector2(-s.x*.075,-s.y*.15)]), Color("#aaa4a9"))
	draw_line(Vector2(-s.x*.08,-s.y*.215),Vector2(s.x*.08,-s.y*.215),Color("#e4d8cb"),3.0)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	# Floating sparks and heat haze.
	if sparks > 0.0:
		for i in range(14):
			var a := float(i)*TAU/14.0
			var radius := 18.0+(1.0-sparks)*58.0
			var p := Vector2(cx,s.y*.665)+Vector2(cos(a),sin(a))*radius
			draw_circle(p, (2.0+awakening_flash*2.5)*sparks, Color("#ffd18a") if awakening_flash>0.0 else Color("#ff9a43"))
	# Rotation hint.
	draw_string(ThemeDB.fallback_font, Vector2(18,s.y*.49), "СВАЙП ОТ КРАЯ ЭКРАНА • ПОВОРОТ КУЗНИЦЫ", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.88,0.72,0.56,0.72))
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func _camera_point(local_point: Vector2) -> Vector2:
	var origin := Vector2(size.x*0.5,size.y*0.42)
	return origin + local_point.rotated(camera_yaw*0.22)

func _draw_weapon(center: Vector2, length: float, weapon_id: String, quality: float, awakened: bool, horizontal: bool) -> void:
	var blade_color := Color("#b8c3c9")
	var edge_color := Color("#f4eee3")
	var accent := Color("#d7a978")
	match weapon_id:
		"ember_sabre":
			blade_color=Color("#d99a5c"); accent=Color("#f2a14a")
		"wyrmfang":
			blade_color=Color("#9daeb6"); accent=Color("#65b6a4")
		"glassfang":
			blade_color=Color("#a8d9d6"); accent=Color("#8ff4ed")
		"frostbite":
			blade_color=Color("#83c4e5"); accent=Color("#c6efff")
		"bloodiron":
			blade_color=Color("#a85860"); accent=Color("#e37b78")
		"ashen_greatsword":
			blade_color=Color("#77717f"); accent=Color("#f18b4b")
		"rift_spear":
			blade_color=Color("#8374a9"); accent=Color("#c3a6ff")
		"storm_twins":
			blade_color=Color("#a9c9d2"); accent=Color("#f3df9a")
	var tier := 0
	if quality >= 30.0: tier=1
	if quality >= 60.0: tier=2
	if quality >= 85.0: tier=3
	var angle := PI*0.5 if horizontal else 0.0
	draw_set_transform(_camera_point(center),angle+camera_yaw*0.22,Vector2.ONE)
	var blade_len := length*(0.62+float(tier)*0.09)
	var half_width := length*(0.055+float(tier)*0.009)
	if awakened:
		draw_circle(Vector2(0,-blade_len*.42),length*.22,Color(accent,0.15+0.08*sin(aura_phase)))
	var blade_points := PackedVector2Array([
		Vector2(-half_width,0),Vector2(half_width,0),Vector2(half_width*.78,-blade_len*.72),
		Vector2(half_width*.48,-blade_len*.91),Vector2(0,-blade_len),Vector2(-half_width*.48,-blade_len*.91),
		Vector2(-half_width*.78,-blade_len*.72)
	])
	draw_colored_polygon(blade_points,blade_color)
	draw_line(Vector2(0,-4),Vector2(0,-blade_len*.96),edge_color, maxf(1.5,length*.018))
	# Quality tiers add fuller bevels, grooves and a visible spine.
	if tier >= 1:
		draw_line(Vector2(-half_width*.58,-blade_len*.22),Vector2(-half_width*.35,-blade_len*.78),Color("#e8d9bd"),2.0)
	if tier >= 2:
		draw_line(Vector2(half_width*.48,-blade_len*.18),Vector2(half_width*.3,-blade_len*.78),accent,2.0)
		for rune in range(3):
			var ry := -blade_len*(.36+float(rune)*.15)
			draw_line(Vector2(-half_width*.28,ry),Vector2(half_width*.28,ry-4),accent,2.0)
	# Guard and pommel become more elaborate with mastery.
	draw_rect(Rect2(-length*.13,1,length*.26,length*.055),Color("#5c4039"))
	draw_colored_polygon(PackedVector2Array([Vector2(-length*.19,1),Vector2(-length*.12,-length*.025),Vector2(length*.12,-length*.025),Vector2(length*.19,1),Vector2(length*.12,length*.035),Vector2(-length*.12,length*.035)]),accent if tier>=2 else Color("#9a795e"))
	draw_rect(Rect2(-length*.035,length*.055,length*.07,length*.18),Color("#49343a"))
	draw_circle(Vector2(0,length*.25),length*.055,accent if awakened else Color("#8b6c59"))
	if tier >= 3 or awakened:
		for rune in range(4):
			var ry2 := -blade_len*(.28+float(rune)*.14)
			draw_circle(Vector2(0,ry2),length*.025,Color("#fff0bd") if awakened else accent)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
