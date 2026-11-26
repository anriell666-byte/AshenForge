extends Node3D
## Enemy projectile (acid spit, bone shards, sparks). Flies straight, hurts the player on contact.

var velocity := Vector3.ZERO
var damage: float = 8.0
var life: float = 2.2
var target
var burn: bool = false
var hit_radius: float = 0.75

static func fire(game: Node, from: Vector3, to: Vector3, dmg: float, col: Color, speed: float = 9.5, burning: bool = false) -> void:
    var p := Node3D.new()
    p.set_script(load("res://scripts/projectile.gd"))
    var mesh := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.2
    sphere.height = 0.4
    sphere.radial_segments = 6
    sphere.rings = 3
    mesh.mesh = sphere
    var mat := StandardMaterial3D.new()
    mat.albedo_color = col
    mat.emission_enabled = true
    mat.emission = col
    mat.emission_energy_multiplier = 1.6
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh.material_override = mat
    p.add_child(mesh)
    game.add_child(p)
    p.global_position = from
    var dir := (to - from)
    dir.y = 0.0
    p.velocity = dir.normalized() * speed
    p.damage = dmg
    p.burn = burning
    p.target = game.player

func _physics_process(delta: float) -> void:
    life -= delta
    global_position += velocity * delta
    if is_instance_valid(target):
        var flat: Vector3 = target.global_position + Vector3(0, 0.9, 0) - global_position
        if flat.length() < hit_radius:
            target.call("take_damage", damage)
            if burn and target.has_method("ignite"):
                target.call("ignite", 2.5)
            queue_free()
            return
    if life <= 0.0:
        queue_free()
