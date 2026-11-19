extends Node
var game
var survivor

func setup(owner, player_node) -> void:
    game = owner
    survivor = player_node
    _repair_building_shells()
    _dress_greywood()
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
            child.visible = false
            if child is StaticBody3D:
                for part in child.get_children():
                    if part is CollisionShape3D:
                        part.disabled = true

func _rebuild_house(label: String, tint: Color) -> void:
    var root := _find_building(label)
    if root == null: return
    _hide_old_walls(root)
    _box(root,"Room floor",Vector3(0,-0.12,0),Vector3(8.5,0.24,7.6),Color(0.34,0.30,0.24),true)
    _box(root,"Rear solid wall",Vector3(0,2.0,-3.92),Vector3(8.9,4.0,0.28),tint,true)
    _box(root,"Left solid wall",Vector3(-4.35,2.0,0),Vector3(0.28,4.0,8.0),tint,true)
    _box(root,"Right solid wall",Vector3(4.35,2.0,0),Vector3(0.28,4.0,8.0),tint,true)
    # A low, visible front wall keeps the room enclosed without blocking the camera.
    _box(root,"Front cutaway left",Vector3(-3.0,0.78,3.92),Vector3(2.8,1.56,0.3),tint,true)
    _box(root,"Front cutaway right",Vector3(3.0,0.78,3.92),Vector3(2.8,1.56,0.3),tint,true)
    _box(root,"Door header",Vector3(0,3.35,3.92),Vector3(3.2,1.0,0.3),tint,true)
    var trim := Color(0.22,0.16,0.12)
    for x in [-4.18,4.18]:
        _box(root,"Timber corner post",Vector3(x,2.0,3.72),Vector3(0.16,3.85,0.16),trim,false)
    for x in [-1.62,1.62]:
        _box(root,"Door jamb",Vector3(x,1.2,3.72),Vector3(0.14,2.4,0.16),trim,false)
    _box(root,"Door lintel trim",Vector3(0,2.42,3.72),Vector3(3.35,0.16,0.16),trim,false)
    # Interior partitions and furniture are deliberately low-detail but readable silhouettes.
    _box(root,"Interior divider",Vector3(0,1.2,-1.15),Vector3(0.14,2.4,3.0),tint.darkened(0.14),true)
    _box(root,"Bed base",Vector3(-2.65,0.23,-2.35),Vector3(1.9,0.3,1.25),Color(0.23,0.17,0.13),false)
    _box(root,"Bed mattress",Vector3(-2.65,0.43,-2.35),Vector3(1.78,0.18,1.12),Color(0.47,0.43,0.35),false)
    _box(root,"Kitchen cabinet",Vector3(2.6,0.55,-2.45),Vector3(2.1,1.1,0.65),Color(0.30,0.23,0.17),false)
    _box(root,"Dining table",Vector3(1.8,0.72,1.0),Vector3(1.6,0.12,1.05),Color(0.33,0.23,0.15),false)
    for x in [1.2,2.4]:
        for z in [0.62,1.38]:
            _box(root,"Table leg",Vector3(x,0.35,z),Vector3(0.1,0.7,0.1),trim,false)
    _box(root,"Wall shelf",Vector3(-2.2,2.25,-3.68),Vector3(1.8,0.12,0.42),trim,false)
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
    _box(root,"Market entrance header",Vector3(0,3.35,4.35),Vector3(5.9,1.1,0.3),tint,true)
    _box(root,"Shop counter detail",Vector3(0,0.65,-1.0),Vector3(5.6,1.25,0.8),Color(0.26,0.20,0.14),false)
    for x in [-3.7,3.7]:
        _box(root,"Grocery rack",Vector3(x,1.0,-1.9),Vector3(0.5,2.0,3.2),Color(0.28,0.24,0.18),false)
    _box(root,"Broken display",Vector3(2.0,0.55,1.1),Vector3(1.5,1.1,0.65),Color(0.23,0.29,0.28),false)

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
    _box(root,"Garage lintel",Vector3(0,3.15,3.85),Vector3(6.2,0.8,0.3),tint,true)
    _box(root,"Workbench top",Vector3(-2.5,1.0,-2.2),Vector3(2.4,0.14,0.8),Color(0.28,0.21,0.14),false)
    _box(root,"Workbench legs",Vector3(-2.5,0.48,-2.2),Vector3(2.2,0.9,0.12),Color(0.18,0.2,0.19),false)
    _box(root,"Tool board",Vector3(-2.5,2.1,-3.65),Vector3(2.7,1.25,0.12),Color(0.25,0.29,0.27),false)

func _box(parent: Node, label: String, pos: Vector3, dimensions: Vector3, color: Color, solid: bool) -> void:
    game.call("_box",parent,label,pos,dimensions,color,solid)

func _dress_greywood() -> void:
    # Layered foliage, roadside clutter, broken asphalt and camp dressing.
    for p in [Vector3(-8,0,-14),Vector3(9,0,-10),Vector3(-10,0,8),Vector3(10,0,21),Vector3(24,0,5),Vector3(-25,0,4),Vector3(26,0,-20)]:
        _bush(p,1.0)
    for p in [Vector3(-11,0,-23),Vector3(12,0,-23),Vector3(-11,0,5),Vector3(12,0,17),Vector3(24,0,-4)]:
        _box(game,"Cracked asphalt",p+Vector3(0,0.04,0),Vector3(2.0,0.04,1.15),Color(0.12,0.14,0.13),false)
        _box(game,"Roadside rubble",p+Vector3(1.1,0.22,0.65),Vector3(0.65,0.42,0.55),Color(0.31,0.28,0.23),false)
    for p in [Vector3(-24,0,-5),Vector3(24,0,-15),Vector3(-25,0,18),Vector3(26,0,20)]:
        _box(game,"Streetlight",p+Vector3(0,2.2,0),Vector3(0.16,4.4,0.16),Color(0.21,0.24,0.22),true)
        _box(game,"Lamp arm",p+Vector3(0.5,4.25,0),Vector3(1.0,0.12,0.12),Color(0.21,0.24,0.22),false)
        _box(game,"Lamp head",p+Vector3(0.95,4.12,0),Vector3(0.38,0.16,0.3),Color(0.75,0.65,0.43),false)
    _box(game,"Greywood welcome sign",Vector3(-24,2.0,-27),Vector3(3.6,1.1,0.2),Color(0.28,0.34,0.27),false)
    _box(game,"Camp crate",game.camp_position+Vector3(2.4,0.45,-1.4),Vector3(0.9,0.9,0.9),Color(0.35,0.24,0.15),false)
    _box(game,"Camp barrel",game.camp_position+Vector3(2.5,0.6,1.2),Vector3(0.7,1.2,0.7),Color(0.24,0.32,0.31),false)

func _bush(pos: Vector3, size: float) -> void:
    var shades := [Color(0.16,0.27,0.18),Color(0.22,0.33,0.21),Color(0.27,0.34,0.22),Color(0.14,0.23,0.16)]
    for i in range(4):
        var leaf := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = size*0.48
        mesh.height = size*0.72
        leaf.mesh = mesh
        leaf.position = pos+Vector3(cos(float(i)*1.57)*size*0.3,size*0.34,sin(float(i)*1.57)*size*0.3)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = shades[i]
        mat.roughness = 1.0
        leaf.material_override = mat
        game.add_child(leaf)

func _replace_survivor_placeholder() -> void:
    for child in survivor.get_children():
        if child is MeshInstance3D and child.name != "FollowCamera":
            child.visible = false
    var model := Node3D.new()
    model.name = "DetailedSurvivor"
    survivor.add_child(model)
    var jacket := Color(0.23,0.31,0.26)
    var dark := Color(0.14,0.19,0.17)
    var pants := Color(0.18,0.21,0.20)
    var skin := Color(0.64,0.49,0.37)
    var canvas := Color(0.37,0.31,0.22)
    var boots := Color(0.10,0.12,0.12)
    var metal := Color(0.35,0.39,0.37)
    _part(model,"Field jacket",CapsuleMesh.new(),Vector3(0,1.06,0),Vector3(0.82,0.92,0.58),jacket)
    _part(model,"Jacket collar",BoxMesh.new(),Vector3(0,1.48,-0.03),Vector3(0.48,0.14,0.43),dark)
    _part(model,"Neck",CylinderMesh.new(),Vector3(0,1.57,0),Vector3(0.22,0.18,0.22),skin)
    _part(model,"Head",SphereMesh.new(),Vector3(0,1.82,0),Vector3(0.48,0.53,0.43),skin)
    _part(model,"Hair",SphereMesh.new(),Vector3(0,2.02,0.02),Vector3(0.5,0.25,0.46),Color(0.12,0.12,0.10))
    _part(model,"Face shadow",BoxMesh.new(),Vector3(0,1.78,-0.2),Vector3(0.25,0.05,0.03),Color(0.3,0.22,0.18))
    _part(model,"Backpack",BoxMesh.new(),Vector3(0,1.13,0.34),Vector3(0.62,0.8,0.32),canvas)
    _part(model,"Backpack flap",BoxMesh.new(),Vector3(0,1.5,0.52),Vector3(0.52,0.16,0.07),dark)
    for x in [-0.23,0.23]:
        _part(model,"Backpack strap",BoxMesh.new(),Vector3(x,1.14,-0.22),Vector3(0.09,0.78,0.07),canvas)
        _part(model,"Chest pocket",BoxMesh.new(),Vector3(x,1.0,-0.29),Vector3(0.2,0.24,0.08),dark)
        _part(model,"Glove",SphereMesh.new(),Vector3(x*2.15,0.82,-0.02),Vector3(0.19,0.2,0.18),boots)
    _part(model,"Utility belt",BoxMesh.new(),Vector3(0,0.72,0),Vector3(0.72,0.12,0.48),boots)
    _part(model,"Buckle",BoxMesh.new(),Vector3(0,0.72,-0.25),Vector3(0.13,0.12,0.04),metal)
    for x in [-0.19,0.19]:
        _part(model,"Cargo trousers",CapsuleMesh.new(),Vector3(x,0.37,0),Vector3(0.32,0.72,0.34),pants)
        _part(model,"Knee pad",BoxMesh.new(),Vector3(x,0.37,-0.17),Vector3(0.24,0.2,0.07),dark)
        _part(model,"Boot",BoxMesh.new(),Vector3(x,0.12,-0.09),Vector3(0.28,0.2,0.44),boots)
    for x in [-0.42,0.42]:
        _part(model,"Sleeve",CapsuleMesh.new(),Vector3(x,1.12,0),Vector3(0.27,0.7,0.28),jacket)
        _part(model,"Elbow patch",BoxMesh.new(),Vector3(x,0.98,-0.12),Vector3(0.24,0.18,0.07),dark)
    _part(model,"Radio",BoxMesh.new(),Vector3(-0.34,1.47,-0.18),Vector3(0.16,0.22,0.12),metal)
    _part(model,"Radio antenna",CylinderMesh.new(),Vector3(-0.36,1.62,-0.18),Vector3(0.025,0.22,0.025),dark)

func _part(parent: Node3D, label: String, mesh: PrimitiveMesh, pos: Vector3, scale_value: Vector3, color: Color) -> void:
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.position = pos
    node.scale = scale_value
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.9
    node.material_override = mat
    parent.add_child(node)
