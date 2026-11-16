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
	camera_target = clampf(camera_target + direction * 0.24, -0.52, 0.52)

func play_awakening() -> void:
	awakening_flash = 1.0
	sparks = 1.0
	hammer_angle = -0.85
	queue_redraw()

func play_strike() -> void:
	hammer_angle = -0.62
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
				if absf(delta_x) > 35.0 and absf(delta_x) > absf(event.position.y - drag_origin.y) * 1.2:
					rotate_camera(-signf(delta_x))
			drag_active = false
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_origin = event.position
			drag_active = true
		else:
			if drag_active:
				var delta_mouse: float = float(event.position.x - drag_origin.x)
				if absf(delta_mouse) > 35.0 and absf(delta_mouse) > absf(event.position.y - drag_origin.y) * 1.2:
					rotate_camera(-signf(delta_mouse))
			drag_active = false

func _process(delta: float) -> void:
	hammer_angle = move_toward(hammer_angle, 0.0, delta * 3.4)
	sparks = move_toward(sparks, 0.0, delta * 1.5)
	awakening_flash = move_toward(awakening_flash, 0.0, delta * 0.55)
	aura_phase = fposmod(aura_phase + delta * 2.0, TAU)
	flame_phase = fposmod(flame_phase + delta * 4.5, TAU)
	camera_yaw = lerpf(camera_yaw, camera_target, minf(1.0, delta * 4.0))
	queue_redraw()

func _poly(points: Array[Vector2], color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)

func _draw() -> void:
	var s: Vector2 = size
	if s.x < 10.0 or s.y < 10.0:
		s = get_viewport_rect().size
	var w: float = s.x
	var h: float = s.y
	var cx: float = w * 0.5
	var yaw: float = camera_yaw
	# A deep, enclosed smithy: stone vault, timber framing and a distant doorway.
	draw_rect(Rect2(Vector2.ZERO, s), Color("#100d12"))
	_poly([Vector2(0,0),Vector2(w,0),Vector2(w,h*.72),Vector2(0,h*.72)],Color("#28232c"))
	_poly([Vector2(0,0),Vector2(w*.5,h*.10),Vector2(w,h*.0),Vector2(w,h*.72),Vector2(0,h*.72)],Color("#211e27"))
	# Tall stone blocks and mortar lines.
	for row in range(5):
		var yy: float = h*(.08+float(row)*.125)
		draw_line(Vector2(0,yy),Vector2(w,yy),Color("#39313c"),2.0)
		for col in range(7):
			var xx: float = float(col)*w/6.0 + (w/12.0 if row%2==0 else 0.0)
			draw_line(Vector2(xx,yy-h*.12),Vector2(xx,yy),Color("#342d37"),2.0)
	# Ceiling beams and hanging chains.
	for i in range(4):
		var bx: float = w*(.08+float(i)*.29)
		_poly([Vector2(bx,0),Vector2(bx+w*.025,0),Vector2(bx+w*.12,h*.30),Vector2(bx+w*.09,h*.30)],Color("#49352f"))
		draw_line(Vector2(bx+w*.012,0),Vector2(bx+w*.105,h*.29),Color("#74513a"),3.0)
	# Rear arched window with cold moonlight.
	var win := Rect2(w*.075,h*.12,w*.19,h*.31)
	draw_rect(win,Color("#121821"))
	draw_arc(Vector2(win.position.x+win.size.x*.5,win.position.y+win.size.x*.5),win.size.x*.5,PI,TAU,32,Color("#887b78"),5.0)
	draw_line(Vector2(win.position.x+win.size.x*.5,win.position.y+8),Vector2(win.position.x+win.size.x*.5,win.end.y),Color("#625b63"),5.0)
	draw_line(Vector2(win.position.x+8,win.position.y+win.size.y*.58),Vector2(win.end.x-8,win.position.y+win.size.y*.58),Color("#625b63"),4.0)
	draw_circle(Vector2(win.position.x+win.size.x*.72,win.position.y+win.size.y*.27),w*.027,Color(0.62,0.73,0.83,0.18))
	# Rear weapon display wall: forged iron rack and trophies with silhouettes.
	_poly([Vector2(w*.30,h*.12),Vector2(w*.92,h*.12),Vector2(w*.92,h*.43),Vector2(w*.30,h*.43)],Color("#211a20"))
	for shelf in range(2):
		var sy: float = h*(.245+float(shelf)*.17)
		draw_rect(Rect2(w*.31,sy,w*.60,h*.018),Color("#654536"))
		draw_rect(Rect2(w*.31,sy+h*.018,w*.60,h*.012),Color("#2d2022"))
		for slot in range(5):
			var sx: float = w*(.37+float(slot)*.115)
			draw_circle(Vector2(sx,sy-h*.018),4.0,Color("#c28a50"))
			if shelf*5+slot < wall_weapons.size():
				var trophy: Dictionary = wall_weapons[shelf*5+slot]
				_draw_weapon(Vector2(sx,sy+h*.085),h*.14,str(trophy.get("weapon_id","coal_blade")),float(trophy.get("quality",0.0)),bool(trophy.get("awakened",false)),false)
			else:
				draw_line(Vector2(sx,sy+4),Vector2(sx,sy+h*.05),Color("#76533f"),3.0)
	# Left side: workbench, tools, leather roll and stacked ingots.
	_poly([Vector2(w*.015,h*.48),Vector2(w*.30,h*.48),Vector2(w*.33,h*.57),Vector2(w*.02,h*.57)],Color("#684632"))
	draw_rect(Rect2(w*.045,h*.565,w*.025,h*.17),Color("#382a28"))
	draw_rect(Rect2(w*.25,h*.565,w*.025,h*.17),Color("#382a28"))
	for i in range(3):
		draw_rect(Rect2(w*(.055+float(i)*.062),h*.435,w*.045,h*.035),Color("#73747a"))
		draw_line(Vector2(w*(.06+float(i)*.062),h*.44),Vector2(w*(.09+float(i)*.062),h*.46),Color("#c1b7a7"),2.0)
	# Furnace mass on the right, with masonry, iron mouth, bellows and animated fire.
	_poly([Vector2(w*.69,h*.27),Vector2(w*.97,h*.27),Vector2(w*.99,h*.62),Vector2(w*.67,h*.62)],Color("#51404a"))
	for i in range(4):
		draw_line(Vector2(w*.70,h*(.34+float(i)*.065)),Vector2(w*.97,h*(.34+float(i)*.065)),Color("#77606a"),3.0)
	draw_rect(Rect2(w*.735,h*.40,w*.22,h*.17),Color("#171219"))
	draw_rect(Rect2(w*.755,h*.42,w*.18,h*.13),Color("#09080c"))
	var flame: float = .5+.5*sin(flame_phase)
	draw_circle(Vector2(w*.845,h*.53),w*(.07+flame*.008),Color(1.0,.22,.035,.20+flame*.12))
	for i in range(7):
		var fx: float = w*(.77+float(i)*.023)
		var fh: float = h*(.055+flame*.035+heat_level*.00015)
		_poly([Vector2(fx-w*.008,h*.55),Vector2(fx,h*.55-fh),Vector2(fx+w*.009,h*.55)],Color("#ff8a35") if heat_level<65.0 else Color("#fff0a0"))
	# Chimney and hood.
	_poly([Vector2(w*.75,h*.27),Vector2(w*.93,h*.27),Vector2(w*.90,h*.12),Vector2(w*.79,h*.12)],Color("#3c333e"))
	_poly([Vector2(w*.80,h*.12),Vector2(w*.88,h*.12),Vector2(w*.91,h*.02),Vector2(w*.77,h*.02)],Color("#51434a"))
	# Bellows to the right of the furnace.
	_poly([Vector2(w*.92,h*.43),Vector2(w*.99,h*.40),Vector2(w*.99,h*.55),Vector2(w*.92,h*.57)],Color("#784a38"))
	draw_line(Vector2(w*.94,h*.44),Vector2(w*.97,h*.54),Color("#c08a5a"),3.0)
	# Floor perspective, stone slabs and warm pool of light.
	_poly([Vector2(0,h*.61),Vector2(w,h*.61),Vector2(w,h),Vector2(0,h)],Color("#17141a"))
	_poly([Vector2(w*.38,h*.61),Vector2(w*.72,h*.61),Vector2(w*.95,h),Vector2(w*.08,h)],Color(0.50,.25,.13,.10))
	for row in range(4):
		var fy: float = h*(.68+float(row)*.085)
		draw_line(Vector2(0,fy),Vector2(w,fy),Color("#302832"),2.0)
	for col in range(6):
		var fx2: float = float(col)*w/5.0
		draw_line(Vector2(cx+(fx2-cx)*.35,h*.61),Vector2(fx2,h),Color("#302832"),2.0)
	# Foreground anvil: broad horn, steel top, bevels, pedestal and shadow.
	var anvil_x: float = cx + yaw*w*.12
	draw_ellipse_placeholder(Vector2(anvil_x,h*.80),Vector2(w*.31,h*.045),Color(0,0,0,.42))
	_poly([Vector2(anvil_x-w*.20,h*.76),Vector2(anvil_x+w*.20,h*.76),Vector2(anvil_x+w*.14,h*.89),Vector2(anvil_x-w*.14,h*.89)],Color("#51414a"))
	_poly([Vector2(anvil_x-w*.10,h*.87),Vector2(anvil_x+w*.10,h*.87),Vector2(anvil_x+w*.075,h*.98),Vector2(anvil_x-w*.075,h*.98)],Color("#302932"))
	_poly([Vector2(anvil_x-w*.30,h*.72),Vector2(anvil_x-w*.18,h*.68),Vector2(anvil_x+w*.19,h*.68),Vector2(anvil_x+w*.30,h*.72),Vector2(anvil_x+w*.22,h*.78),Vector2(anvil_x-w*.22,h*.78)],Color("#a4a3a8"))
	draw_line(Vector2(anvil_x-w*.27,h*.725),Vector2(anvil_x+w*.26,h*.725),Color("#e0d7d0"),3.0)
	# Active blade on the anvil, larger and central, visibly changing with quality.
	_draw_weapon(Vector2(anvil_x,h*.735),w*.47,current_weapon_id,quality_level,blade_awakened,true)
	# Smith hammer, animated on each strike.
	var hammer_pivot := Vector2(anvil_x+w*.25,h*.61)
	draw_set_transform(hammer_pivot,hammer_angle,Vector2.ONE)
	draw_rect(Rect2(-w*.012,-h*.17,w*.024,h*.20),Color("#80583d"))
	_poly([Vector2(-w*.075,-h*.20),Vector2(w*.075,-h*.20),Vector2(w*.085,-h*.14),Vector2(-w*.085,-h*.14)],Color("#aaa4a9"))
	draw_line(Vector2(-w*.07,-h*.195),Vector2(w*.07,-h*.195),Color("#eee2d4"),3.0)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	# Ambient ember motes and impact sparks.
	for i in range(18):
		var drift: float = fposmod(flame_phase*.07+float(i)*.137,1.0)
		var ex: float = w*(.68+float(i%5)*.055)+sin(flame_phase+float(i))*8.0
		var ey: float = h*(.58-drift*.38)
		draw_circle(Vector2(ex,ey),1.0+float(i%3),Color(1.0,.52,.19,.28+drift*.3))
	if sparks > 0.0:
		for i in range(24):
			var a: float = float(i)*TAU/24.0
			var radius: float = 14.0+(1.0-sparks)*w*.15
			var p: Vector2 = Vector2(anvil_x,h*.72)+Vector2(cos(a),sin(a))*radius
			draw_circle(p,(2.0+awakening_flash*2.0)*sparks,Color("#ffe0a0") if awakening_flash>0.0 else Color("#ff9a43"))
	# Directional vignette and discreet camera hint.
	draw_rect(Rect2(0,0,w,h*.035),Color(0,0,0,.22))
	draw_string(ThemeDB.fallback_font,Vector2(16,h*.59),"СВАЙПАЙ, ЧТОБЫ ОСМОТРЕТЬ КУЗНИЦУ",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(.85,.74,.63,.7))

func draw_ellipse_placeholder(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(32):
		var a: float = TAU*float(i)/32.0
		pts.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(pts,color)

func _draw_weapon(center: Vector2, length: float, weapon_id: String, quality: float, awakened: bool, horizontal: bool) -> void:
	var blade_color := Color("#aebbc4")
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
	var tier: int = 0
	if quality >= 30.0: tier=1
	if quality >= 60.0: tier=2
	if quality >= 85.0: tier=3
	var angle: float = PI*.5 if horizontal else 0.0
	draw_set_transform(center,angle+(camera_yaw*.06),Vector2.ONE)
	var blade_len: float = length*(.65+float(tier)*.09)
	var half_width: float = length*(.052+float(tier)*.012)
	# Cast shadow and layered steel blade create a stronger 2.5D silhouette.
	draw_colored_polygon(PackedVector2Array([Vector2(-half_width*1.4,5),Vector2(half_width*1.4,5),Vector2(half_width*.7,-blade_len*.9),Vector2(0,-blade_len*1.08),Vector2(-half_width*.7,-blade_len*.9)]),Color(0,0,0,.35))
	if awakened:
		draw_circle(Vector2(0,-blade_len*.45),length*.25,Color(accent,.16+.08*sin(aura_phase)))
	var pts := PackedVector2Array([Vector2(-half_width,0),Vector2(half_width,0),Vector2(half_width*.78,-blade_len*.72),Vector2(half_width*.45,-blade_len*.92),Vector2(0,-blade_len),Vector2(-half_width*.45,-blade_len*.92),Vector2(-half_width*.78,-blade_len*.72)])
	draw_colored_polygon(pts,blade_color)
	draw_colored_polygon(PackedVector2Array([Vector2(0,-4),Vector2(half_width*.45,-blade_len*.92),Vector2(0,-blade_len),Vector2(-half_width*.18,-blade_len*.35)]),Color(1,1,1,.18))
	draw_line(Vector2(0,-4),Vector2(0,-blade_len*.96),edge_color,maxf(1.5,length*.018))
	if tier >= 1:
		draw_line(Vector2(-half_width*.58,-blade_len*.22),Vector2(-half_width*.35,-blade_len*.78),Color("#e8d9bd"),2.0)
	if tier >= 2:
		draw_line(Vector2(half_width*.48,-blade_len*.18),Vector2(half_width*.3,-blade_len*.78),accent,2.0)
		for rune in range(3):
			var ry: float = -blade_len*(.36+float(rune)*.15)
			draw_line(Vector2(-half_width*.28,ry),Vector2(half_width*.28,ry-4),accent,2.0)
	# Guard, grip, wrapped leather and pommel.
	draw_rect(Rect2(-length*.13,1,length*.26,length*.055),Color("#5c4039"))
	draw_colored_polygon(PackedVector2Array([Vector2(-length*.19,1),Vector2(-length*.12,-length*.025),Vector2(length*.12,-length*.025),Vector2(length*.19,1),Vector2(length*.12,length*.035),Vector2(-length*.12,length*.035)]),accent if tier>=2 else Color("#9a795e"))
	draw_rect(Rect2(-length*.035,length*.055,length*.07,length*.18),Color("#49343a"))
	for wrap in range(3):
		draw_line(Vector2(-length*.03,length*(.075+float(wrap)*.05)),Vector2(length*.03,length*(.10+float(wrap)*.05)),Color("#a17a60"),1.5)
	draw_circle(Vector2(0,length*.25),length*.055,accent if awakened else Color("#8b6c59"))
	if tier >= 3 or awakened:
		for rune in range(4):
			var ry2: float = -blade_len*(.28+float(rune)*.14)
			draw_circle(Vector2(0,ry2),length*.025,Color("#fff0bd") if awakened else accent)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
