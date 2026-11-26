extends Node
const CreatorScript = preload("res://scripts/character_creator.gd")
const EnvArt = preload("res://scripts/environment_art.gd")
var game
var survivor

func setup(owner, player_node) -> void:
    game = owner
    survivor = player_node
    _repair_building_shells()
    _add_building_detail_pass()
    _dress_greywood()
    _add_world_art_pass()
    EnvArt.populate(game)
    _replace_survivor_placeholder()

func _repair_building_shells() -> void:
    _rebuild_house("House A", Color(0.54,0.43,0.34))
    _rebuild_house("House B", Color(0.43,0.49,0.46))
    _rebuild_house("House C", Color(0.55,0.5,0.39))
    _rebuild_shop()
    _rebuild_garage()

func _find_building(label: String) -> Node3D:
    return game.get_node_or_null(NodePath(label)) as Node3D

func _hide_old_walls(root: Node3D) -> void:
    for child in root.get_children():
        var low := child.name.to_lower()
        if low.contains("wall") or low.contains("front"):
            if child is StaticBody3D:
                for part in child.get_children():
                    if part is CollisionShape3D:
                        part.disabled = true
                    elif part is MeshInstance3D:
                        part.visible = false
            elif child is MeshInstance3D:
                child.visible = false

func _rebuild_house(label: String, tint: Color) -> void:
    var root := _find_building(label)
    if root == null: return
    _hide_old_walls(root)
    _box(root,"Room floor",Vector3(0,-0.12,0),Vector3(8.5,0.24,7.6),Color(0.34,0.30,0.24),true)
    _box(root,"Rear solid wall",Vector3(0,2.0,-3.92),Vector3(8.9,4.0,0.28),tint,true)
    _box(root,"Left solid wall",Vector3(-4.35,2.0,0),Vector3(0.28,4.0,8.0),tint,true)
    _box(root,"Right solid wall",Vector3(4.35,2.0,0),Vector3(0.28,4.0,8.0),tint,true)
    # A low, visible front wall keeps the room enclosed without blocking the camera.
    # Lower front wall is solid; the upper facade (windows, door header) is drawn as a
    # separate group that hides while the player is inside, so the room stays visible.
    _box(root,"Front wall left",Vector3(-2.6,0.75,3.92),Vector3(3.8,1.5,0.3),tint,true)
    _box(root,"Front wall right",Vector3(2.6,0.75,3.92),Vector3(3.8,1.5,0.3),tint,true)
    var fac := Node3D.new()
    fac.name = "FacadeUpper"
    root.add_child(fac)
    _box(fac,"Door header",Vector3(0,3.15,3.92),Vector3(1.4,1.7,0.3),tint,false)
    for sd in [-1.0, 1.0]:
        _box(fac,"Pier inner",Vector3(sd*1.475,2.75,3.92),Vector3(1.55,2.5,0.3),tint,false)
        _box(fac,"Pier outer",Vector3(sd*3.925,2.75,3.92),Vector3(1.15,2.5,0.3),tint,false)
        _box(fac,"Window lintel",Vector3(sd*2.8,3.25,3.92),Vector3(1.1,1.5,0.3),tint,false)
    var trim := Color(0.22,0.16,0.12)
    for x in [-4.18,4.18]:
        _box(root,"Timber corner post",Vector3(x,2.0,3.72),Vector3(0.16,3.85,0.16),trim,false)
    for x in [-0.72,0.72]:
        _box(root,"Door jamb",Vector3(x,1.15,4.05),Vector3(0.12,2.3,0.14),trim,false)
    _box(root,"Door lintel trim",Vector3(0,2.34,4.05),Vector3(1.6,0.14,0.14),trim,false)
    # Interior partitions and furniture are deliberately low-detail but readable silhouettes.
    _box(root,"Interior divider",Vector3(0,1.2,-1.15),Vector3(0.14,2.4,3.0),tint.darkened(0.14),true)
    _box(root,"Bed base",Vector3(-2.65,0.23,-2.35),Vector3(1.9,0.3,1.25),Color(0.23,0.17,0.13),true)
    _box(root,"Bed mattress",Vector3(-2.65,0.43,-2.35),Vector3(1.78,0.18,1.12),Color(0.47,0.43,0.35),true)
    _box(root,"Kitchen cabinet",Vector3(2.6,0.55,-2.45),Vector3(2.1,1.1,0.65),Color(0.30,0.23,0.17),true)
    _box(root,"Dining table",Vector3(1.8,0.72,1.0),Vector3(1.6,0.12,1.05),Color(0.33,0.23,0.15),true)
    for x in [1.2,2.4]:
        for z in [0.62,1.38]:
            _box(root,"Table leg",Vector3(x,0.35,z),Vector3(0.1,0.7,0.1),trim,false)
    _box(root,"Wall shelf",Vector3(-2.2,2.25,-3.68),Vector3(1.8,0.12,0.42),trim,true)
    _box(root,"Window pane",Vector3(-2.8,2.0,4.09),Vector3(1.0,0.95,0.045),Color(0.13,0.23,0.26),false)
    _box(root,"Window pane",Vector3(2.8,2.0,4.09),Vector3(1.0,0.95,0.045),Color(0.13,0.23,0.26),false)
    for x in [-3.38,-2.22,2.22,3.38]:
        _box(root,"Window mullion",Vector3(x,2.0,4.13),Vector3(0.08,1.2,0.08),trim,false)
    for x in [-2.8,2.8]:
        _box(root,"Window sill",Vector3(x,1.46,4.14),Vector3(1.28,0.12,0.16),trim,false)

func _rebuild_shop() -> void:
    var root := _find_building("Greywood Market")
    if root == null: return
    _hide_old_walls(root)
    var tint := Color(0.48,0.47,0.36)
    _box(root,"Market floor",Vector3(0,-0.12,0),Vector3(9.6,0.24,8.5),Color(0.36,0.33,0.26),true)
    _box(root,"Market rear wall",Vector3(0,2.0,-4.35),Vector3(10,4.0,0.28),tint,true)
    _box(root,"Market left wall",Vector3(-4.85,2.0,0),Vector3(0.28,4.0,8.9),tint,true)
    _box(root,"Market right wall",Vector3(4.85,2.0,0),Vector3(0.28,4.0,8.9),tint,true)
    _box(root,"Market entrance left",Vector3(-3.9,0.85,4.35),Vector3(1.9,1.7,0.3),tint,true)
    _box(root,"Market entrance right",Vector3(3.9,0.85,4.35),Vector3(1.9,1.7,0.3),tint,true)
    var fac := Node3D.new()
    fac.name = "FacadeUpper"
    root.add_child(fac)
    _box(fac,"Market entrance header",Vector3(0,3.35,4.35),Vector3(5.9,1.3,0.3),tint,false)
    for sd in [-1.0, 1.0]:
        _box(fac,"Market pier",Vector3(sd*3.9,2.85,4.35),Vector3(1.9,2.3,0.3),tint,false)
        _box(fac,"Market window",Vector3(sd*3.9,2.4,4.52),Vector3(1.2,0.9,0.05),Color(0.13,0.23,0.26),false)
    _box(root,"Shop counter detail",Vector3(0,0.65,-1.0),Vector3(5.6,1.25,0.8),Color(0.26,0.20,0.14),true)
    for x in [-3.7,3.7]:
        _box(root,"Grocery rack",Vector3(x,1.0,-1.9),Vector3(0.5,2.0,3.2),Color(0.28,0.24,0.18),true)
    _box(root,"Broken display",Vector3(2.0,0.55,1.1),Vector3(1.5,1.1,0.65),Color(0.23,0.29,0.28),true)

func _rebuild_garage() -> void:
    var root := _find_building("Garage")
    if root == null: return
    _hide_old_walls(root)
    var tint := Color(0.40,0.41,0.37)
    _box(root,"Garage floor",Vector3(0,-0.12,0),Vector3(9.5,0.24,7.5),Color(0.29,0.30,0.28),true)
    _box(root,"Garage rear wall",Vector3(0,1.8,-3.85),Vector3(10,3.6,0.28),tint,true)
    _box(root,"Garage left wall",Vector3(-4.85,1.8,0),Vector3(0.28,3.6,8),tint,true)
    _box(root,"Garage right wall",Vector3(4.85,1.8,0),Vector3(0.28,3.6,8),tint,true)
    _box(root,"Garage front left",Vector3(-4.0,0.9,3.85),Vector3(1.7,1.8,0.3),tint,true)
    _box(root,"Garage front right",Vector3(4.0,0.9,3.85),Vector3(1.7,1.8,0.3),tint,true)
    var fac := Node3D.new()
    fac.name = "FacadeUpper"
    root.add_child(fac)
    _box(fac,"Garage lintel",Vector3(0,3.1,3.85),Vector3(6.2,1.0,0.3),tint,false)
    for sd in [-1.0, 1.0]:
        _box(fac,"Garage pier",Vector3(sd*4.0,2.7,3.85),Vector3(1.7,1.8,0.3),tint,false)
    _box(root,"Workbench top",Vector3(-2.5,1.0,-2.2),Vector3(2.4,0.14,0.8),Color(0.28,0.21,0.14),true)
    _box(root,"Workbench legs",Vector3(-2.5,0.48,-2.2),Vector3(2.2,0.9,0.12),Color(0.18,0.2,0.19),true)
    _box(root,"Tool board",Vector3(-2.5,2.1,-3.65),Vector3(2.7,1.25,0.12),Color(0.25,0.29,0.27),true)

func _add_building_detail_pass() -> void:
    var trim := Color(0.22, 0.16, 0.12)
    var roof := Color(0.20, 0.23, 0.21)
    for building_name in ["House A", "House B", "House C"]:
        var root := _find_building(building_name)
        if root == null:
            continue
        var tint := Color(0.54,0.43,0.34)
        if building_name == "House B":
            tint = Color(0.43,0.49,0.46)
        elif building_name == "House C":
            tint = Color(0.55,0.5,0.39)
        _rotated_box(root, "Roof left slope", Vector3(-2.25,4.15,0), Vector3(5.1,0.22,8.5), roof.darkened(0.08), Vector3(0,0,-24.0))
        _rotated_box(root, "Roof right slope", Vector3(2.25,4.15,0), Vector3(5.1,0.22,8.5), roof, Vector3(0,0,24.0))
        _box(root, "Roof ridge", Vector3(0,4.9,0), Vector3(0.22,0.22,8.7), trim, false)
        for z in [-2.7,0.0,2.7]:
            _box(root, "Roof seam", Vector3(0,4.82,z), Vector3(8.2,0.06,0.06), trim, false)
        _box(root, "Front door", Vector3(0,1.1,4.09), Vector3(1.32,2.2,0.12), Color(0.25,0.18,0.13), false)
        _box(root, "Door handle", Vector3(0.5,1.1,4.17), Vector3(0.07,0.16,0.05), Color(0.62,0.52,0.31), false)
        for x in [-2.8,2.8]:
            _box(root, "Window crossbar", Vector3(x,2.0,4.16), Vector3(1.0,0.07,0.06), trim, false)
            _box(root, "Window vertical bar", Vector3(x,2.0,4.16), Vector3(0.07,0.98,0.06), trim, false)
        _box(root, "Boarded window plank", Vector3(-2.8,1.82,4.19), Vector3(0.95,0.10,0.07), Color(0.32,0.22,0.15), false)
        _box(root, "Foundation front", Vector3(0,0.12,3.88), Vector3(8.6,0.22,0.36), Color(0.25,0.24,0.21), false)
        for x in [-3.8,3.8]:
            _box(root, "Wall weathering", Vector3(x,1.55,4.10), Vector3(0.22,0.48,0.025), tint.darkened(0.22), false)
    var shop := _find_building("Greywood Market")
    if shop:
        _box(shop, "Market sign backing", Vector3(0,3.65,4.62), Vector3(5.7,0.16,0.22), Color(0.22,0.18,0.13), false)
        _box(shop, "Market sign stripe", Vector3(0,3.62,4.76), Vector3(4.8,0.08,0.04), Color(0.72,0.52,0.28), false)
        for x in [-4.3,4.3]:
            _box(shop, "Shop corner trim", Vector3(x,2.0,4.5), Vector3(0.16,3.8,0.16), Color(0.25,0.20,0.15), false)
    var garage := _find_building("Garage")
    if garage:
        _box(garage, "Garage roof fascia", Vector3(0,3.72,-3.9), Vector3(10.2,0.24,0.3), Color(0.24,0.25,0.22), false)
        for x in [-3.1,-1.55,0.0,1.55,3.1]:
            _box(garage, "Garage shutter rib", Vector3(x,1.0,4.02), Vector3(0.06,1.65,0.05), Color(0.26,0.28,0.25), false)

func _rotated_box(parent: Node3D, label: String, pos: Vector3, dimensions: Vector3, color: Color, angles: Vector3) -> void:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    node.mesh = mesh
    node.position = pos
    node.rotation_degrees = angles
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.96
    node.material_override = mat
    parent.add_child(node)

func _box(parent: Node, label: String, pos: Vector3, dimensions: Vector3, color: Color, solid: bool) -> void:
    game.call("_box",parent,label,pos,dimensions,color,solid)

func _dress_greywood() -> void:
    # Layered foliage, roadside clutter, broken asphalt and camp dressing.
    for p in [Vector3(-8,0,-14),Vector3(9,0,-10),Vector3(-10,0,8),Vector3(10,0,21),Vector3(24,0,5),Vector3(-25,0,4),Vector3(26,0,-20)]:
        _bush(p,1.0)
    for p in [Vector3(-11,0,-23),Vector3(12,0,-23),Vector3(-11,0,5),Vector3(12,0,17),Vector3(24,0,-4)]:
        _box(game,"Cracked asphalt",p+Vector3(0,0.04,0),Vector3(2.0,0.04,1.15),Color(0.12,0.14,0.13),false)
        _box(game,"Roadside rubble",p+Vector3(1.1,0.22,0.65),Vector3(0.65,0.42,0.55),Color(0.31,0.28,0.23),true)
    for p in [Vector3(-24,0,-5),Vector3(24,0,-15),Vector3(-25,0,18),Vector3(26,0,20)]:
        _box(game,"Streetlight",p+Vector3(0,2.2,0),Vector3(0.16,4.4,0.16),Color(0.21,0.24,0.22),true)
        _box(game,"Lamp arm",p+Vector3(0.5,4.25,0),Vector3(1.0,0.12,0.12),Color(0.21,0.24,0.22),true)
        _box(game,"Lamp head",p+Vector3(0.95,4.12,0),Vector3(0.38,0.16,0.3),Color(0.75,0.65,0.43),true)
    _box(game,"Greywood welcome sign",Vector3(-24,2.0,-27),Vector3(3.6,1.1,0.2),Color(0.28,0.34,0.27),true)
    _box(game,"Camp crate",game.camp_position+Vector3(2.4,0.45,-1.4),Vector3(0.9,0.9,0.9),Color(0.35,0.24,0.15),true)
    _box(game,"Camp barrel",game.camp_position+Vector3(2.5,0.6,1.2),Vector3(0.7,1.2,0.7),Color(0.24,0.32,0.31),true)


func _bush(pos: Vector3, size: float) -> void:
    EnvArt.bush(game, pos, size)

func _replace_survivor_placeholder() -> void:
    for child in survivor.get_children():
        if child is MeshInstance3D and child.name != "FollowCamera":
            child.visible = false
    # The look comes from the character creator (saved appearance, or defaults on first launch).
    CreatorScript.apply_to_player(survivor, CreatorScript.load_saved())

func _add_world_art_pass() -> void:
    _add_rock_cluster(Vector3(-25,0,-17), 1.0)
    _add_rock_cluster(Vector3(25,0,-25), 1.25)
    _add_rock_cluster(Vector3(-25,0,23), 0.9)
    _add_rock_cluster(Vector3(25,0,25), 1.1)
    _add_rock_cluster(Vector3(8,0,-27), 0.75)
    _add_vehicle(Vector3(-23,0,0), -0.18, Color(0.27,0.31,0.29))
    _add_vehicle(Vector3(24,0,17), 2.9, Color(0.39,0.29,0.19))
    _add_fence_line(Vector3(-29,0,-4), 8, Vector3(0,0,1))
    _add_fence_line(Vector3(29,0,4), 7, Vector3(0,0,1))
    _add_dead_tree(Vector3(-29,0,16), 1.0)
    _add_dead_tree(Vector3(29,0,-17), 0.85)
    _add_signpost(Vector3(6,0,-9))
    _add_debris_pile(Vector3(-12,0,-7))
    _add_debris_pile(Vector3(13,0,9))
    _add_debris_pile(Vector3(-22,0,7))
    _add_roadside_grass()


func _add_rock_cluster(origin: Vector3, scale_value: float) -> void:
    EnvArt.rock_cluster(game, origin, scale_value)

func _add_vehicle(origin: Vector3, yaw: float, paint: Color) -> void:
    var car := Node3D.new()
    car.name = "Abandoned vehicle"
    car.position = origin
    car.rotation.y = yaw
    game.add_child(car)
    _box(car,"Rusty chassis",Vector3(0,0.72,0),Vector3(4.0,0.72,1.85),paint,true)
    _box(car,"Cabin shell",Vector3(-0.25,1.48,0),Vector3(2.1,0.92,1.62),paint.darkened(0.12),true)
    _box(car,"Windshield",Vector3(-0.25,1.55,-0.83),Vector3(1.55,0.62,0.035),Color(0.12,0.19,0.2),false)
    _box(car,"Rear window",Vector3(-0.25,1.55,0.83),Vector3(1.45,0.58,0.035),Color(0.10,0.15,0.16),false)
    _box(car,"Hood",Vector3(-1.45,1.05,0),Vector3(0.9,0.18,1.72),paint.lightened(0.06),true)
    _box(car,"Front bumper",Vector3(-2.04,0.52,0),Vector3(0.16,0.22,2.0),Color(0.24,0.26,0.25),true)
    _box(car,"Rear bumper",Vector3(2.04,0.52,0),Vector3(0.16,0.22,2.0),Color(0.24,0.26,0.25),true)
    for x in [-1.35,1.35]:
        for z in [-0.98,0.98]:
            var wheel := MeshInstance3D.new()
            var cylinder := CylinderMesh.new()
            cylinder.top_radius = 0.43
            cylinder.bottom_radius = 0.43
            cylinder.height = 0.24
            wheel.mesh = cylinder
            wheel.position = Vector3(x,0.43,z)
            wheel.rotation_degrees.z = 90
            var mat := StandardMaterial3D.new()
            mat.albedo_color = Color(0.07,0.08,0.075)
            mat.roughness = 1.0
            wheel.material_override = mat
            car.add_child(wheel)
    for z in [-0.58,0.58]:
        _box(car,"Broken headlamp",Vector3(-2.08,0.82,z),Vector3(0.06,0.22,0.34),Color(0.66,0.56,0.34),false)
    _box(car,"Rust patch",Vector3(0.9,1.1,0.94),Vector3(0.72,0.16,0.035),Color(0.32,0.16,0.09),false)

func _add_fence_line(origin: Vector3, count: int, direction: Vector3) -> void:
    for i in range(count):
        var p := origin + direction * float(i) * 1.7
        _box(game,"Weathered fence post",p+Vector3(0,0.65,0),Vector3(0.16,1.3,0.16),Color(0.28,0.23,0.17),true)
        if i < count-1:
            _box(game,"Fence rail",p+direction*0.85+Vector3(0,0.95,0),Vector3(0.12,0.12,1.7),Color(0.34,0.27,0.19),true)

func _add_dead_tree(pos: Vector3, size: float) -> void:
    EnvArt.dead_tree(game, pos, size)

func _add_signpost(pos: Vector3) -> void:
    _box(game,"Road sign pole",pos+Vector3(0,1.1,0),Vector3(0.12,2.2,0.12),Color(0.24,0.23,0.19),true)
    _box(game,"Road sign board",pos+Vector3(0,1.95,0),Vector3(1.5,0.8,0.12),Color(0.34,0.39,0.31),true)
    _box(game,"Sign warning stripe",pos+Vector3(0,1.95,-0.075),Vector3(1.1,0.08,0.025),Color(0.72,0.55,0.29),false)

func _add_debris_pile(pos: Vector3) -> void:
    var colors := [Color(0.27,0.28,0.25),Color(0.39,0.31,0.22),Color(0.18,0.22,0.21)]
    for i in range(6):
        var dims := Vector3(0.45+float(i%2)*0.22,0.16,0.3+float(i%3)*0.12)
        var p := pos+Vector3(float(i%3)*0.42-0.4,0.12+float(i%2)*0.08,float(i/3)*0.42-0.2)
        _box(game,"Debris collision",p,dims,colors[i%colors.size()],true)
func _add_roadside_grass() -> void:
    pass  # grass and flowers are MultiMesh batches in environment_art.gd

