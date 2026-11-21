extends Node
## Spawns each stage's monsters plus its boss, and advances to the next stage
## when the boss falls. Stage index is stored in the save file by main.gd.

const InfectedScript = preload("res://scripts/infected.gd")
const MD = preload("res://scripts/monster_data.gd")

const SPAWN_POINTS := [
    Vector3(5, 0.2, -15), Vector3(21, 0.2, 15), Vector3(-20, 0.2, 22),
    Vector3(-25, 0.2, -12), Vector3(26, 0.2, -8), Vector3(2, 0.2, 27),
]
const BOSS_POINT := Vector3(0, 0.2, -23)

var game
var stage: int = 0
var boss_node: Node

func setup(owner_game, start_stage: int) -> void:
    game = owner_game
    stage = maxi(0, start_stage)
    _spawn_stage()

func _spawn_stage() -> void:
    if stage >= MD.STAGES.size():
        game.show_message("Все уровни пройдены! Кузница погасла.")
        return
    var data: Dictionary = MD.get_stage(stage)
    _apply_tint(data)
    var points := SPAWN_POINTS.duplicate()
    var spawns: Array = data["spawns"]
    for i in range(spawns.size()):
        _spawn(String(spawns[i]), points[i % points.size()])
    boss_node = _spawn(String(data["boss"]), BOSS_POINT)
    game.show_message("Уровень %d: %s" % [stage + 1, data["name"]])

func _spawn(id: String, pos: Vector3) -> Node:
    var enemy := CharacterBody3D.new()
    enemy.set_script(InfectedScript)
    enemy.set("monster_id", id)
    enemy.position = pos
    game.add_child(enemy)
    enemy.set("target", game.player)
    game.infected.append(enemy)
    return enemy

func on_boss_defeated(_boss_id: String) -> void:
    var finished := stage
    stage += 1
    # Leftover regular monsters from the finished stage leave with their boss.
    for enemy in game.infected:
        if is_instance_valid(enemy) and enemy != boss_node and not enemy.get("dead"):
            enemy.queue_free()
    game.infected.clear()
    if is_instance_valid(game.player):
        game.player.health = game.player.max_health
        game.refresh_hud()
    if stage >= MD.STAGES.size():
        game.show_message("Ты победил Пепельного Кузнеца! Все уровни пройдены.")
        return
    var next: Dictionary = MD.get_stage(stage)
    game.show_message("Уровень %d пройден! Дальше: %s" % [finished + 1, next["name"]])
    game.save_game(false)
    await get_tree().create_timer(4.0).timeout
    if is_instance_valid(game):
        _spawn_stage()

func _apply_tint(data: Dictionary) -> void:
    var sun_color: Color = data["sun"]
    var sky_color: Color = data["sky"]
    for node in game.get_children():
        if node is DirectionalLight3D:
            node.light_color = sun_color
        elif node is WorldEnvironment and node.environment:
            node.environment.background_color = sky_color.lerp(Color(0.42, 0.49, 0.46), 0.55)
            node.environment.ambient_light_color = Color(0.72, 0.77, 0.72).lerp(sun_color, 0.35)
