extends CharacterBody3D

var target
var speed: float = 1.5
var health: float = 2.0
var attack_timer: float = 0.0

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

func _physics_process(delta: float) -> void:
    attack_timer = maxf(0.0, attack_timer - delta)
    if not is_instance_valid(target):
        return
    var offset: Vector3 = target.global_position - global_position
    var distance := offset.length()
    if distance < 12.0 and distance > 1.15:
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
        target.call("take_damage", 7.0)

func take_hit() -> void:
    health -= 1.0
    if health <= 0.0:
        if is_instance_valid(target):
            var game = target.get("main_game")
            if is_instance_valid(game):
                game.call("_gain_xp", 25)
                game.call("show_message", "Заражённый устранён. +25 XP")
        queue_free()
