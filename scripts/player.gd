extends CharacterBody3D

@export var move_speed: float = 3.6
@export var sprint_speed: float = 6.2
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0
var health: float = 100.0
var stamina: float = 100.0
var touch_vector: Vector2 = Vector2.ZERO
var camera_touch_vector: Vector2 = Vector2.ZERO
var touch_sprinting: bool = false
var stamina_regen_delay: float = 0.0
const STAMINA_DRAIN_RATE := 22.0
const STAMINA_REGEN_RATE := 13.0
const STAMINA_REGEN_DELAY := 0.7
var main_game
var attack_cooldown: float = 0.0
var invulnerable: float = 0.0
var follow_camera: Camera3D
var camera_offset := Vector3(0.0, 12.5, 11.5)
var camera_yaw: float = 0.0
var is_sneaking: bool = false
var equipped_weapon: String = ""
var equipped_tool: String = ""
var body_collision: CollisionShape3D
var animation_model: Node3D
var animation_parts: Array[Node3D] = []
var animation_clock: float = 0.0
var attack_animation: float = 0.0

func _ready() -> void:
    health = max_health
    stamina = max_stamina
    var shape := CapsuleShape3D.new()
    shape.radius = 0.38
    shape.height = 1.65
    body_collision = CollisionShape3D.new()
    body_collision.shape = shape
    body_collision.position.y = 0.83
    add_child(body_collision)
    var body_mesh := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.38
    capsule.height = 1.65
    body_mesh.mesh = capsule
    body_mesh.position.y = 0.83
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.24, 0.34, 0.31)
    mat.roughness = 0.9
    body_mesh.material_override = mat
    add_child(body_mesh)
    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.25
    head_mesh.height = 0.5
    head.mesh = head_mesh
    head.position = Vector3(0, 1.72, 0)
    var head_mat := StandardMaterial3D.new()
    head_mat.albedo_color = Color(0.72, 0.58, 0.45)
    head.material_override = head_mat
    add_child(head)
    follow_camera = Camera3D.new()
    follow_camera.name = "FollowCamera"
    follow_camera.top_level = true
    follow_camera.global_position = global_position + camera_offset
    follow_camera.rotation_degrees = Vector3(-47.0, 0.0, 0.0)
    follow_camera.current = true
    follow_camera.fov = 52.0
    add_child(follow_camera)

func _physics_process(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    invulnerable = maxf(0.0, invulnerable - delta)
    var keys := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var input_dir := touch_vector if touch_vector.length() > 0.12 else keys
    var direction := Vector3(input_dir.x, 0.0, input_dir.y)
    if direction.length() > 1.0:
        direction = direction.normalized()
    if Input.is_action_just_pressed("sneak"):
        is_sneaking = not is_sneaking
        if is_instance_valid(main_game): main_game.call("show_message", "Подкрадывание включено" if is_sneaking else "Обычная стойка")
    var capsule := body_collision.shape as CapsuleShape3D
    capsule.height = 1.28 if is_sneaking else 1.65
    body_collision.position.y = 0.64 if is_sneaking else 0.83
    var wants_sprint := (Input.is_action_pressed("sprint") or touch_sprinting) and not is_sneaking
    var sprinting := wants_sprint and stamina > 0.0 and direction.length() > 0.1
    var speed := sprint_speed if sprinting else move_speed
    if is_sneaking: speed *= 0.48
    if sprinting:
        stamina = maxf(0.0, stamina - STAMINA_DRAIN_RATE * delta)
        stamina_regen_delay = STAMINA_REGEN_DELAY
    else:
        stamina_regen_delay = maxf(0.0, stamina_regen_delay - delta)
        if stamina_regen_delay <= 0.0:
            stamina = minf(max_stamina, stamina + STAMINA_REGEN_RATE * delta)
    camera_yaw += camera_touch_vector.x * 1.85 * delta
    var rotated := Vector2(direction.x, direction.z).rotated(camera_yaw)
    velocity.x = rotated.x * speed
    velocity.z = rotated.y * speed
    if not is_on_floor():
        velocity.y -= 22.0 * delta
    else:
        velocity.y = -0.2
    if direction.length() > 0.1:
        rotation.y = atan2(-rotated.x, -rotated.y)
    move_and_slide()
    _animate_character(delta, direction.length(), sprinting)
    # Keep the camera centered on the player without inheriting player rotation.
    if is_instance_valid(follow_camera):
        follow_camera.global_position = global_position + camera_offset.rotated(Vector3.UP, camera_yaw)
        follow_camera.rotation_degrees.y = rad_to_deg(camera_yaw)
    if is_instance_valid(main_game):
        main_game.call("refresh_stamina_hud")
        if Engine.get_physics_frames() % 12 == 0:
            main_game.call("_refresh_inventory_ui")

func _animate_character(delta: float, input_amount: float, sprinting: bool) -> void:
    animation_clock += delta
    attack_animation = maxf(0.0, attack_animation - delta)
    if not is_instance_valid(animation_model):
        animation_model = get_node_or_null("DetailedSurvivor") as Node3D
    var moving := Vector2(velocity.x, velocity.z).length()
    var gait := sin(animation_clock * (10.0 if sprinting else 7.0))
    var swing := clampf(moving / maxf(0.1, sprint_speed), 0.0, 1.0)
    if is_instance_valid(animation_model):
        animation_model.position.y = (-0.06 if is_sneaking else 0.0) + absf(gait) * 0.045 * swing + sin(animation_clock * 2.0) * 0.012
        animation_model.rotation.x = (0.13 if is_sneaking else 0.0) + sin(animation_clock * 1.7) * 0.008
    for i in range(animation_parts.size()):
        var part := animation_parts[i]
        if not is_instance_valid(part):
            continue
        var phase := gait if i % 2 == 0 else -gait
        if attack_animation > 0.0 and i == 0:
            part.rotation.z = lerpf(part.rotation.z, -0.9, 0.45)
        else:
            part.rotation.z = phase * 0.52 * swing
        if is_sneaking and i < 2:
            part.rotation.z *= 0.35
        elif is_sneaking and i >= 2:
            part.rotation.z += 0.12 if i == 2 else -0.12

func rotate_camera(amount: float) -> void:
    camera_yaw += amount

func take_damage(amount: float) -> void:
    if invulnerable > 0.0:
        return
    health = maxf(0.0, health - amount)
    invulnerable = 0.7
    if main_game:
        main_game.call("refresh_hud")
        if health <= 0.0:
            main_game.call("player_died")

func perform_attack() -> void:
    if attack_cooldown > 0.0 or main_game == null:
        return
    attack_cooldown = 0.48
    attack_animation = 0.32
    main_game.call("player_attack")
