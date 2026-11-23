extends Node
var game
var animals: Array[Node3D] = []
var crafted := {"hatchet": false, "spear": false, "bow": false}
var stealth := false
var craft_panel: PanelContainer
var status_label: Label
var animal_data := {}
func setup(owner) -> void:
    game = owner
    for key in game.saved_expansion_state:
        if crafted.has(key): crafted[key] = bool(game.saved_expansion_state[key])
    _hide_roofs()
    _add_interior_loot()
    _spawn_wildlife()
    _add_controls()
    _refresh_status()
func _process(delta: float) -> void:
    for animal in animals:
        if not is_instance_valid(animal): continue
        var data: Dictionary = animal_data.get(animal.get_instance_id(), {})
        var timer: float = float(data.get("timer", 0.0)) - delta
        if timer <= 0.0:
            var rng := RandomNumberGenerator.new()
            rng.randomize()
            data["direction"] = Vector3(rng.randf_range(-1,1),0,rng.randf_range(-1,1)).normalized()
            timer = rng.randf_range(1.5,4.0)
        data["timer"] = timer
        animal_data[animal.get_instance_id()] = data
        var dir: Vector3 = data.get("direction", Vector3.ZERO)
        animal.position += dir * delta * float(data.get("speed", 1.0))
        if dir.length() > 0.1: animal.rotation.y = atan2(-dir.x,-dir.z)
func _hide_roofs() -> void:
    for n in game.find_children("*", "Node", true, false):
        if n.name.to_lower().contains("roof") or n.name == "Flat roof":
            n.visible = false
            if n is StaticBody3D:
                for child in n.get_children():
                    if child is CollisionShape3D: child.disabled = true
func _add_interior_loot() -> void:
    # Interior props are positioned inside the now-open buildings.
    game._make_prop("Barricaded entrance A", "wood", 3, 5, Vector3(-17,1.0,-13), Vector3(1.5,2.1,0.2), Color(0.28,0.19,0.12))
    game._make_prop("Barricaded entrance B", "wood", 3, 5, Vector3(17,1.0,-13), Vector3(1.5,2.1,0.2), Color(0.28,0.19,0.12))
    game._make_prop("Barricaded entrance C", "wood", 3, 5, Vector3(-18,1.0,16), Vector3(1.5,2.1,0.2), Color(0.28,0.19,0.12))
    game._make_prop("House medicine cabinet", "medicine", 2, 2, Vector3(-17,0.55,-17), Vector3(0.8,1.1,0.45), Color(0.62,0.65,0.57))
    game._make_prop("House food cupboard", "food", 4, 2, Vector3(17,0.6,-17), Vector3(1.0,1.2,0.5), Color(0.45,0.32,0.22))
    game._make_prop("Hidden supply chest", "scrap", 5, 3, Vector3(-18,0.5,12), Vector3(1.1,0.8,0.7), Color(0.32,0.27,0.2))
    game._make_prop("Garage parts shelf", "scrap", 7, 3, Vector3(-17,0.7,-1), Vector3(1.2,1.4,0.45), Color(0.36,0.39,0.35))
    game._make_prop("Market ration shelf", "food", 5, 2, Vector3(17,0.55,4), Vector3(1.2,1.1,0.45), Color(0.55,0.43,0.29))
func _spawn_wildlife() -> void:
    _make_animal("Deer", Vector3(-25,0.1,4), Color(0.48,0.32,0.19), 1.4, 3, 4)
    _make_animal("Deer", Vector3(25,0.1,-20), Color(0.52,0.37,0.23), 1.5, 3, 4)
    _make_animal("Boar", Vector3(24,0.1,25), Color(0.25,0.19,0.15), 1.0, 4, 5)
    _make_animal("Rabbit", Vector3(-25,0.1,-25), Color(0.58,0.52,0.43), 2.0, 1, 2)
func _make_animal(label: String, pos: Vector3, tint: Color, speed: float, hp: int, meat: int) -> void:
    var animal := CharacterBody3D.new()
    animal.name = label
    animal.position = pos
    var body := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.55 if label != "Rabbit" else 0.28
    mesh.height = 0.8 if label != "Rabbit" else 0.42
    body.mesh = mesh
    body.position.y = 0.55 if label != "Rabbit" else 0.28
    body.scale = Vector3(1.35,0.8,0.75) if label != "Rabbit" else Vector3(1.0,0.8,0.8)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.roughness = 1.0
    body.material_override = mat
    animal.add_child(body)
    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.24 if label != "Rabbit" else 0.15
    head.mesh = head_mesh
    head.position = Vector3(0,0.72,-0.48)
    head.material_override = mat
    animal.add_child(head)
    game.add_child(animal)
    animals.append(animal)
    animal_data[animal.get_instance_id()] = {"hp":hp,"meat":meat,"speed":speed,"timer":1.0,"direction":Vector3.RIGHT}
func _add_controls() -> void:
    var layers: Array[Node] = game.find_children("*", "CanvasLayer", true, false)
    if layers.is_empty(): return
    var layer := layers[0] as CanvasLayer
    var left: Button = game._make_ui_button(layer,"⟲",Vector2.ZERO,Vector2(58,52))
    game._place_bottom_right(left,300,24)
    left.pressed.connect(func(): game.player.rotate_camera(-PI/4.0))
    var right: Button = game._make_ui_button(layer,"⟳",Vector2.ZERO,Vector2(58,52))
    game._place_bottom_right(right,364,24)
    right.pressed.connect(func(): game.player.rotate_camera(PI/4.0))
    var sneak: Button = game._make_ui_button(layer,"SNEAK",Vector2.ZERO,Vector2(92,48))
    game._place_bottom_right(sneak,300,88)
    sneak.toggle_mode = true
    sneak.toggled.connect(_toggle_stealth)
    _refresh_status()
func _recipe_button(parent: Node, label: String, id: String, cost: Dictionary, note: String) -> void:
    var b: Button = game._make_ui_button(parent,label+"  ["+_cost_text(cost)+"]",Vector2.ZERO,Vector2.ZERO)
    b.pressed.connect(func(): _craft(id,cost,note))
func _cost_text(cost: Dictionary) -> String:
    var out: Array[String] = []
    for k in cost: out.append("%s %d" % [str(k),int(cost[k])])
    return ", ".join(out)
func _craft(id: String, cost: Dictionary, note: String) -> void:
    if crafted.get(id,false):
        game.show_message("Уже создано: "+id)
        return
    var can_use_chest: bool = game.player.global_position.distance_to(game.camp_position) < 5.0
    for key in cost:
        var available := int(game.inventory.get(key,0))
        if can_use_chest:
            available += int(game.chest_inventory.get(key,0))
        if available < int(cost[key]):
            game.show_message("Не хватает ресурсов: "+str(key))
            return
    for key in cost:
        var needed := int(cost[key])
        var from_bag := mini(needed, int(game.inventory.get(key,0)))
        game.inventory[key] = int(game.inventory.get(key,0)) - from_bag
        needed -= from_bag
        if needed > 0 and can_use_chest:
            game.chest_inventory[key] = int(game.chest_inventory.get(key,0)) - needed
    crafted[id] = true
    if id == "hatchet" or id == "crowbar": game.player.equipped_tool = id
    else: game.player.equipped_weapon = id
    game.show_message("Создано: "+id+" — "+note)
    game._refresh_inventory_ui()
    game.call("_refresh_chest_ui")
    game.call("save_game", false)
    _refresh_status()
func _refresh_status() -> void:
    if status_label:
        status_label.text = "Создано: "+", ".join(_crafted_names())+"\nТихий шаг снижает радиус обнаружения."
func _crafted_names() -> Array[String]:
    var out: Array[String] = []
    for k in crafted:
        if crafted[k]: out.append(str(k))
    if out.is_empty(): out.append("пока ничего")
    return out
func _toggle_craft() -> void:
    craft_panel.visible = not craft_panel.visible
    _refresh_status()
func _toggle_stealth(active: bool) -> void:
    stealth = active
    game.player.is_sneaking = active
    game.show_message("Тихий шаг включён" if active else "Обычная стойка")
func try_interact() -> bool:
    return false
func try_attack(damage: float = 1.0, reach: float = 2.8) -> bool:
    var closest: Node3D = null
    var best := reach
    for a in animals:
        if is_instance_valid(a):
            var d: float = game.player.global_position.distance_to(a.global_position)
            if d < best: best=d; closest=a
    if closest == null: return false
    var data: Dictionary = animal_data.get(closest.get_instance_id(),{})
    data["hp"] = int(data.get("hp",1))-maxi(1,roundi(damage))
    if int(data["hp"]) <= 0:
        game.spawn_loot("food",int(data.get("meat",2)),closest.global_position)
        game._gain_xp(12)
        animals.erase(closest)
        animal_data.erase(closest.get_instance_id())
        closest.queue_free()
        game.show_message("Добыча получена. Собери мясо.")
    else:
        animal_data[closest.get_instance_id()] = data
        game.show_message("Животное ранено и пытается уйти.")
    return true
