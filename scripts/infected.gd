extends CharacterBody3D

var target
var speed: float = 1.5
var health: float = 55.0
var max_health: float = 55.0
var attack_timer: float = 0.0
var attack_pose: float = 0.0
var animation_clock: float = 0.0
var animation_parts: Array[Node3D] = []
var animation_model: Node3D
var health_root: Node3D
var health_fill: MeshInstance3D

func _ready() -> void:
    var shape := CapsuleShape3D.new()
    shape.radius = 0.42
    shape.height = 1.7
    var collision := CollisionShape3D.new()
    collision.shape = shape
    collision.position.y = 0.85
    add_child(collision)
    var mesh_node := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = 0.42
    mesh.height = 1.7
    mesh_node.mesh = mesh
    mesh_node.position.y = 0.85
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.34, 0.43, 0.28)
    mat.roughness = 1.0
    mesh_node.material_override = mat
    add_child(mesh_node)
    _build_health_bar()

func _build_health_bar() -> void:
    health_root = Node3D.new()
    health_root.name = "EnemyHealthBar"
    health_root.top_level = true
    add_child(health_root)
    var back := MeshInstance3D.new()
    var back_mesh := BoxMesh.new()
    back_mesh.size = Vector3(0.92, 0.10, 0.045)
    back.mesh = back_mesh
    var back_mat := StandardMaterial3D.new()
    back_mat.albedo_color = Color(0.08, 0.09, 0.08)
    back.material_override = back_mat
    health_root.add_child(back)
    health_fill = MeshInstance3D.new()
    var fill_mesh := BoxMesh.new()
    fill_mesh.size = Vector3(0.82, 0.055, 0.055)
    health_fill.mesh = fill_mesh
    health_fill.position.z = 0.035
    var fill_mat := StandardMaterial3D.new()
    fill_mat.albedo_color = Color(0.62, 0.19, 0.13)
    fill_mat.emission_enabled = true
    fill_mat.emission = Color(0.22, 0.035, 0.02)
    health_fill.material_override = fill_mat
    health_root.add_child(health_fill)
    _refresh_health_bar()

func _process(_delta: float) -> void:
    if is_instance_valid(health_root):
        health_root.global_position = global_position + Vector3(0, 2.42, 0)
        var facing_yaw := float(target.get("camera_yaw")) if is_instance_valid(target) else 0.0
        health_root.global_rotation = Vector3(-0.22, facing_yaw, 0.0)

func _physics_process(delta: float) -> void:
    animation_clock += delta
    attack_timer = maxf(0.0, attack_timer - delta)
    attack_pose = maxf(0.0, attack_pose - delta)
    if not is_instance_valid(target):
        _animate_infected()
        return
    var offset: Vector3 = target.global_position - global_position
    var distance := Vector2(offset.x, offset.z).length()
    var target_speed := Vector2(target.velocity.x, target.velocity.z).length()
    var detection_range := 4.0 if target.get("is_sneaking") else (15.0 if target_speed > 4.5 else 10.5)
    if distance < detection_range and distance > 1.15:
        var direction := Vector3(offset.x, 0.0, offset.z).normalized()
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        rotation.y = atan2(-direction.x, -direction.z)
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed * delta * 3.0)
        velocity.z = move_toward(velocity.z, 0.0, speed * delta * 3.0)
    if not is_on_floor():
        velocity.y -= 22.0 * delta
    else:
        velocity.y = -0.2
    move_and_slide()
    if distance < 1.35 and attack_timer <= 0.0:
        attack_timer = 1.25
        attack_pose = 0.45
        target.call("take_damage", 7.0)
    _animate_infected()

func _animate_infected() -> void:
    var movement := Vector2(velocity.x, velocity.z).length()
    var gait := sin(animation_clock * 7.0)
    var amount := clampf(movement / maxf(0.1, speed), 0.0, 1.0)
    if is_instance_valid(animation_model):
        animation_model.position.y = absf(gait) * 0.04 * amount + sin(animation_clock * 2.1) * 0.014
        animation_model.rotation.x = 0.04 + absf(gait) * 0.035 * amount
    for i in range(animation_parts.size()):
        var part := animation_parts[i]
        if not is_instance_valid(part):
            continue
        var phase := gait if i % 2 == 0 else -gait
        if attack_pose > 0.0 and i == 0:
            part.rotation.z = lerpf(part.rotation.z, -1.0, 0.4)
        else:
            part.rotation.z = phase * 0.62 * amount

func take_hit(damage: float = 8.0) -> void:
    health = maxf(0.0, health - damage)
    _refresh_health_bar()
    if health <= 0.0:
        if is_instance_valid(target):
            var game = target.get("main_game")
            if is_instance_valid(game):
                game.call("_gain_xp", 25)
                game.call("show_message", "Заражённый устранён. +25 XP")
        queue_free()

func _refresh_health_bar() -> void:
    if not is_instance_valid(health_fill):
        return
    var ratio := clampf(health / maxf(1.0, max_health), 0.0, 1.0)
    health_fill.scale.x = ratio
    health_fill.position.x = -0.41 * (1.0 - ratio)
