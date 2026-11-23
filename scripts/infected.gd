extends CharacterBody3D
## Enemy controller for every monster in monster_data.gd (regular enemies and bosses).
## Set `monster_id` before adding the node to the tree.

const MB = preload("res://scripts/monster_builder.gd")
const MD = preload("res://scripts/monster_data.gd")

var monster_id: String = "walker"
var display_name: String = "Заражённый"
var is_boss: bool = false
var special: String = "none"
var specials: PackedStringArray = PackedStringArray()
var is_mini: bool = false
var power: float = 1.0          # danger multiplier set by the world manager before _ready
var home := Vector3.ZERO        # spawn point; enemies leash back to it
var has_home: bool = false
var district_id: String = ""
var spawn_key: String = ""
var stun_time: float = 0.0
var burn_time: float = 0.0
var burn_tick: float = 0.0
var knock := Vector3.ZERO
var fuse_time: float = 0.0
var shoot_timer: float = 2.5
var xp_reward: int = 25
var target
var speed: float = 1.5
var base_speed: float = 1.5
var health: float = 55.0
var max_health: float = 55.0
var damage: float = 7.0
var reach: float = 1.35
var attack_cooldown: float = 1.25
var attack_timer: float = 0.0
var attack_pose: float = 0.0
var animation_clock: float = 0.0
var animation_parts: Array[Node3D] = []
var limb_rest: Array[float] = []
var swing_scale: float = 1.0
var animation_model: Node3D
var health_root: Node3D
var health_fill: MeshInstance3D
var body_height: float = 1.8
var phase: int = 0
var state: String = "chase"
var state_time: float = 0.0
var special_timer: float = 3.0
var lunge_dir := Vector3.ZERO
var lunge_hit: bool = false
var hit_flash: float = 0.0
var dead: bool = false

func _ready() -> void:
    var data: Dictionary = MD.get_monster(monster_id)
    display_name = String(data["name"])
    is_boss = bool(data.get("boss", false))
    is_mini = bool(data.get("mini", false))
    special = String(data.get("special", "none"))
    specials = special.split(",")
    xp_reward = roundi(float(data.get("xp", 25)) * power)
    base_speed = float(data["speed"])
    speed = base_speed
    max_health = float(data["hp"]) * power
    health = max_health
    damage = float(data["damage"]) * (1.0 + (power - 1.0) * 0.6)
    reach = float(data["reach"])
    attack_cooldown = 1.5 if is_boss else (1.0 if specials.has("long_reach") else 1.25)
    special_timer = randf_range(2.0, 4.0)
    var built: Dictionary = MB.build(monster_id)
    animation_model = built["model"]
    animation_model.name = "MonsterModel"
    add_child(animation_model)
    if not (is_boss or is_mini):
        for node in animation_model.find_children("*", "MeshInstance3D", true, false):
            (node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    animation_parts.assign(built["limbs"])
    limb_rest.assign(built["rest"])
    swing_scale = float(built.get("swing", 1.0))
    body_height = float(built["height"])
    var radius := clampf(float(built["radius"]) * 0.75, 0.36, 1.3)
    var shape := CapsuleShape3D.new()
    shape.radius = radius
    shape.height = maxf(body_height * 0.92, radius * 2.2)
    var collision := CollisionShape3D.new()
    collision.shape = shape
    collision.position.y = shape.height * 0.5
    add_child(collision)
    _build_health_bar()

func _build_health_bar() -> void:
    health_root = Node3D.new()
    health_root.name = "EnemyHealthBar"
    health_root.top_level = true
    add_child(health_root)
    var width := 1.5 if is_boss else (1.2 if is_mini else 0.92)
    var back := MeshInstance3D.new()
    var back_mesh := BoxMesh.new()
    back_mesh.size = Vector3(width, 0.12 if is_boss else 0.10, 0.045)
    back.mesh = back_mesh
    var back_mat := StandardMaterial3D.new()
    back_mat.albedo_color = Color(0.08, 0.09, 0.08)
    back_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    back.material_override = back_mat
    health_root.add_child(back)
    health_fill = MeshInstance3D.new()
    var fill_mesh := BoxMesh.new()
    fill_mesh.size = Vector3(width - 0.1, 0.07 if is_boss else 0.055, 0.055)
    health_fill.mesh = fill_mesh
    health_fill.position.z = 0.035
    var fill_mat := StandardMaterial3D.new()
    fill_mat.albedo_color = Color(0.82, 0.16, 0.1) if is_boss else (Color(0.85, 0.5, 0.12) if is_mini else Color(0.62, 0.19, 0.13))
    fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    health_fill.material_override = fill_mat
    health_root.add_child(health_fill)
    if is_boss or is_mini:
        var label := Label3D.new()
        label.text = display_name
        label.font_size = 56 if is_boss else 44
        label.pixel_size = 0.0045
        label.position = Vector3(0, 0.22, 0.04)
        label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
        label.no_depth_test = true
        label.modulate = Color(1.0, 0.86, 0.55) if is_boss else Color(0.75, 0.9, 1.0)
        label.outline_size = 12
        health_root.add_child(label)
    _refresh_health_bar()

func _process(_delta: float) -> void:
    if is_instance_valid(health_root):
        health_root.global_position = global_position + Vector3(0, body_height + 0.55, 0)
        var facing_yaw := float(target.get("camera_yaw")) if is_instance_valid(target) else 0.0
        health_root.global_rotation = Vector3(-0.22, facing_yaw, 0.0)

func _physics_process(delta: float) -> void:
    if dead:
        return
    animation_clock += delta
    attack_timer = maxf(0.0, attack_timer - delta)
    attack_pose = maxf(0.0, attack_pose - delta)
    hit_flash = maxf(0.0, hit_flash - delta)
    shoot_timer -= delta
    if burn_time > 0.0:
        burn_time -= delta
        burn_tick -= delta
        if burn_tick <= 0.0:
            burn_tick = 0.5
            take_hit(maxf(2.0, max_health * 0.012), {"silent": true})
            if dead:
                return
    if not is_instance_valid(target):
        _animate()
        return
    var offset: Vector3 = target.global_position - global_position
    var distance := Vector2(offset.x, offset.z).length()
    var flat := Vector3(offset.x, 0.0, offset.z)
    var direction := flat.normalized() if flat.length() > 0.001 else Vector3.ZERO
    if stun_time > 0.0:
        stun_time -= delta
        velocity.x = knock.x
        velocity.z = knock.z
        knock = knock.move_toward(Vector3.ZERO, 14.0 * delta)
    elif knock.length() > 0.1:
        velocity.x = knock.x
        velocity.z = knock.z
        knock = knock.move_toward(Vector3.ZERO, 14.0 * delta)
    elif fuse_time > 0.0:
        _tick_fuse(delta, distance)
    else:
        match state:
            "windup":
                _tick_windup(delta, distance, direction)
            "lunge":
                _tick_lunge(delta, distance)
            _:
                _tick_chase(delta, distance, direction)
    if not is_on_floor():
        velocity.y -= 22.0 * delta
    else:
        velocity.y = -0.2
    move_and_slide()
    _animate()

func _tick_fuse(delta: float, distance: float) -> void:
    velocity.x = 0.0
    velocity.z = 0.0
    fuse_time -= delta
    hit_flash = 0.1
    if fuse_time <= 0.0:
        var radius := 3.4
        if distance < radius:
            target.call("take_damage", damage)
        _spawn_shock_ring(radius)
        _explosion_flash()
        _die(true)

func _explosion_flash() -> void:
    var light := OmniLight3D.new()
    light.light_color = Color(1.0, 0.55, 0.15)
    light.light_energy = 6.0
    light.omni_range = 7.0
    light.top_level = true
    get_parent().add_child(light)
    light.global_position = global_position + Vector3(0, 1.0, 0)
    var tween := light.create_tween()
    tween.tween_property(light, "light_energy", 0.0, 0.35)
    tween.tween_callback(light.queue_free)

func _tick_chase(delta: float, distance: float, direction: Vector3) -> void:
    var target_speed := Vector2(target.velocity.x, target.velocity.z).length()
    var detection_range := 4.0 if target.get("is_sneaking") else (15.0 if target_speed > 4.5 else 10.5)
    if is_boss:
        detection_range = maxf(detection_range, 22.0)
    elif is_mini:
        detection_range = maxf(detection_range, 15.0)
    # Leash: do not chase the player out of the home area; walk back instead.
    var returning := false
    if has_home:
        var from_home := Vector2(global_position.x - home.x, global_position.z - home.z).length()
        var leash := 38.0 if (is_boss or is_mini) else 26.0
        if from_home > leash:
            returning = true
        elif from_home > 8.0 and distance > detection_range and health < max_health * 0.999 and not is_boss:
            returning = true
        if returning:
            var back := Vector3(home.x - global_position.x, 0.0, home.z - global_position.z).normalized()
            velocity.x = back.x * speed
            velocity.z = back.z * speed
            rotation.y = atan2(-back.x, -back.z)
            if from_home < 9.0:
                health = minf(max_health, health + max_health * 0.2)
                _refresh_health_bar()
            return
    var stop_distance := maxf(1.15, reach * 0.8)
    if specials.has("spit") and distance < 9.0 and distance > 3.0:
        stop_distance = maxf(stop_distance, 5.0)   # ranged enemies keep their distance
    if distance < detection_range and distance > stop_distance:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        rotation.y = atan2(-direction.x, -direction.z)
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed * delta * 3.0)
        velocity.z = move_toward(velocity.z, 0.0, speed * delta * 3.0)
        if distance < detection_range and distance > 0.01:
            rotation.y = atan2(-direction.x, -direction.z)
    special_timer -= delta
    if specials.has("lunge") and special_timer <= 0.0 and distance > 3.0 and distance < 9.0:
        state = "lunge"
        state_time = 0.45
        lunge_dir = direction
        lunge_hit = false
        special_timer = randf_range(3.5, 5.5) * (0.8 if phase > 0 else 1.0)
        return
    if specials.has("spit") and shoot_timer <= 0.0 and distance > 3.0 and distance < 11.0:
        shoot_timer = randf_range(2.2, 3.4)
        attack_pose = 0.4
        var col := Color(0.55, 0.9, 0.25) if monster_id != "mb_hunter" else Color(0.9, 0.85, 0.7)
        if monster_id == "mb_welder":
            col = Color(1.0, 0.5, 0.15)
        var proj_script = load("res://scripts/projectile.gd")
        proj_script.fire(get_parent(), global_position + Vector3(0, body_height * 0.7, 0), target.global_position, damage * 0.8, col, 9.5, monster_id == "mb_welder")
    if specials.has("explode") and distance < 2.6 and fuse_time <= 0.0:
        fuse_time = 0.7
        return
    if distance < reach and attack_timer <= 0.0:
        attack_timer = attack_cooldown
        if specials.has("slam"):
            state = "windup"
            state_time = 0.75
            attack_pose = 0.75
        else:
            attack_pose = 0.45
            target.call("take_damage", damage)
            if specials.has("burn") and target.has_method("ignite"):
                target.call("ignite", 3.0)

func _tick_windup(delta: float, distance: float, direction: Vector3) -> void:
    velocity.x = 0.0
    velocity.z = 0.0
    if direction != Vector3.ZERO:
        rotation.y = atan2(-direction.x, -direction.z)
    state_time -= delta
    if state_time <= 0.0:
        state = "chase"
        var slam_radius := reach + 0.9
        if distance < slam_radius:
            target.call("take_damage", damage * 1.25)
        _spawn_shock_ring(slam_radius)

func _tick_lunge(delta: float, distance: float) -> void:
    state_time -= delta
    velocity.x = lunge_dir.x * speed * 3.4
    velocity.z = lunge_dir.z * speed * 3.4
    rotation.y = atan2(-lunge_dir.x, -lunge_dir.z)
    if not lunge_hit and distance < reach + 0.3:
        lunge_hit = true
        attack_pose = 0.4
        target.call("take_damage", damage * 1.2)
        if specials.has("burn") and target.has_method("ignite"):
            target.call("ignite", 3.0)
    if state_time <= 0.0:
        state = "chase"

func _spawn_shock_ring(radius: float) -> void:
    var ring := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = 0.05
    mesh.radial_segments = 16
    ring.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.9, 0.55, 0.2, 0.45)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    ring.material_override = mat
    ring.top_level = true
    add_child(ring)
    ring.global_position = global_position + Vector3(0, 0.08, 0)
    var tween := ring.create_tween()
    tween.tween_property(ring, "scale", Vector3(1.25, 1.0, 1.25), 0.25)
    tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.25)
    tween.tween_callback(ring.queue_free)

func _animate() -> void:
    var movement := Vector2(velocity.x, velocity.z).length()
    var gait := sin(animation_clock * (6.0 + base_speed * 1.6))
    var amount := clampf(movement / maxf(0.1, speed), 0.0, 1.0)
    if is_instance_valid(animation_model):
        animation_model.position.y = absf(gait) * 0.05 * amount + sin(animation_clock * 2.1) * 0.014
        var tilt := 0.0
        if state == "windup":
            tilt = lerpf(-0.18, 0.14, clampf(1.0 - state_time / 0.75, 0.0, 1.0))
        animation_model.rotation.x = 0.03 + absf(gait) * 0.03 * amount + tilt
        animation_model.rotation.z = sin(animation_clock * 40.0) * 0.03 * (hit_flash / 0.15) if hit_flash > 0.0 else 0.0
    for i in range(animation_parts.size()):
        var part := animation_parts[i]
        if not is_instance_valid(part):
            continue
        var rest: float = limb_rest[i] if i < limb_rest.size() else 0.0
        var phase_value := gait if i % 2 == 0 else -gait
        var goal := rest + phase_value * 0.62 * amount * swing_scale
        if i < 2:
            if state == "windup":
                goal = lerpf(-2.7, 0.3, clampf(1.0 - state_time / 0.75, 0.0, 1.0) * clampf(1.0 - state_time / 0.75, 0.0, 1.0))
            elif attack_pose > 0.0:
                goal = rest + 1.0 if i == 0 else rest + 0.4
        part.rotation.x = lerpf(part.rotation.x, goal, 0.35)

func take_hit(damage_amount: float = 8.0, opts: Dictionary = {}) -> void:
    if dead:
        return
    health = maxf(0.0, health - damage_amount)
    hit_flash = 0.15
    if opts.has("stun") and not is_boss:
        stun_time = maxf(stun_time, float(opts["stun"]) * (0.5 if is_mini else 1.0))
    if opts.has("burn"):
        burn_time = maxf(burn_time, float(opts["burn"]))
    if opts.has("knock") and opts["knock"] is Vector3:
        var resist := 0.1 if is_boss else (0.35 if is_mini else 1.0)
        knock = (opts["knock"] as Vector3) * resist
    _refresh_health_bar()
    _check_phase()
    if health <= 0.0:
        _die()

func _check_phase() -> void:
    if not is_boss:
        return
    var ratio := health / maxf(1.0, max_health)
    var new_phase := 0
    if ratio <= 0.33:
        new_phase = 2
    elif ratio <= 0.66:
        new_phase = 1
    if new_phase > phase and health > 0.0:
        phase = new_phase
        speed = base_speed * (1.0 + 0.18 * float(phase))
        damage *= 1.15
        attack_cooldown *= 0.85
        if is_instance_valid(target):
            var game = target.get("main_game")
            if is_instance_valid(game):
                game.call("show_message", "%s в ярости!" % display_name)

func _die(exploded: bool = false) -> void:
    if dead:
        return
    dead = true
    var game = null
    if is_instance_valid(target):
        game = target.get("main_game")
    if is_instance_valid(game):
        game.call("_gain_xp", xp_reward)
        game.call("show_message", "%s %s. +%d XP" % [display_name, "взорван" if exploded else "повержен", xp_reward])
        var at: Vector3 = global_position + Vector3(0, 0.45, 0)
        var loot: Array = MD.LOOT.get(MD.get_monster(monster_id).get("kind", "walker") if not MD.LOOT.has(monster_id) else monster_id, ["cloth", 0.3, 1, 2])
        if randf() < float(loot[1]):
            game.call("spawn_loot", String(loot[0]), randi_range(int(loot[2]), int(loot[3])), at)
        if is_boss or is_mini:
            game.call("spawn_loot", String(loot[0]) if is_mini else "medicine", 4 if is_boss else 3, at + Vector3(0.7, 0, 0.3))
            game.call("spawn_loot", "essence", randi_range(3, 4) if is_boss else randi_range(1, 2), at + Vector3(-0.7, 0, 0.4))
        var world = game.get("world")
        if world != null:
            world.call("on_monster_killed", self)
    queue_free()

func _refresh_health_bar() -> void:
    if not is_instance_valid(health_fill):
        return
    var ratio := clampf(health / maxf(1.0, max_health), 0.0, 1.0)
    var full_width := 1.4 if is_boss else (1.1 if is_mini else 0.82)
    health_fill.scale.x = ratio
    health_fill.position.x = -full_width * 0.5 * (1.0 - ratio)
