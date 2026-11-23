extends StaticBody3D
const ID = preload("res://scripts/items_data.gd")

var object_name: String = "Debris"
var material_id: String = "scrap"
var yield_amount: int = 2
var durability: float = 3.0
var max_durability: float = 3.0
var main_game

func setup(label: String, resource: String, amount: int, hits: float, game) -> void:
    object_name = label
    material_id = resource
    yield_amount = amount
    durability = hits
    max_durability = hits
    main_game = game

func damage_object() -> void:
    var damage := 1.0
    if is_instance_valid(main_game) and main_game.get("progress") != null:
        var progress = main_game.get("progress")
        damage = float(progress.call("harvest_power", material_id))
        progress.call("wear_for_harvest")
    durability -= damage
    if main_game:
        main_game.call("show_message", "%s: %d/%d" % [object_name, maxi(0, int(durability)), int(max_durability)])
    if durability <= 0.0:
        if main_game:
            main_game.call("spawn_loot", material_id, yield_amount, global_position)
            main_game.call("mark_salvaged", self)
            main_game.call("show_message", "+%d %s" % [yield_amount, String(ID.RES_LABELS.get(material_id, material_id))])
        queue_free()
