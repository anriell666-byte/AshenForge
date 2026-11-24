extends RefCounted
## Loads the CC0 Quaternius skinned models (hero + monsters) and wires their animations.
## Every build() returns the same dictionary shape as the procedural builders, plus
## "anim": AnimationPlayer and "clips": {idle, walk, run, attack, hit, death}.
## Credits: see assets/CREDITS.txt.

const HERO_MALE := "res://assets/models/hero/char/Superhero_Male_FullBody.gltf"
const HERO_FEMALE := "res://assets/models/hero/char/Superhero_Female_FullBody.gltf"
const HERO_ANIMS := "res://assets/models/hero/anims.glb"
const MONSTER_DIR := "res://assets/models/monsters/"
const HB = preload("res://scripts/human_builder.gd")
const MD = preload("res://scripts/monster_data.gd")

## kind (or id) -> model file, target height at scale 1.0 and animation clip names
const MONSTER_MODELS := {
    "demon": {"file": "Demon.gltf", "height": 2.1, "clips": {"idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Punch", "hit": "HitReact", "death": "Death"}},
    "blue": {"file": "BlueDemon.gltf", "height": 1.5, "clips": {"idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Punch", "hit": "HitReact", "death": "Death"}},
    "orc": {"file": "Orc.gltf", "height": 2.6, "clips": {"idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Punch", "hit": "HitReact", "death": "Death"}},
    "creep": {"file": "CreepCreature.glb", "height": 2.3, "clips": {"idle": "Idle1_Action", "walk": "Walk1_Action", "run": "Walk2_Action", "attack": "Punch_Action", "hit": "Damage_Action", "death": "Death_Action"}},
}
const KIND_TO_MODEL := {"stalker": "creep", "brute": "demon", "ogre": "orc"}
const ID_TO_MODEL := {"hound": "blue", "crawler": "blue", "bramble": "blue", "cinder": "demon", "mb_hunter": "creep"}
const HERO_CLIPS := {"idle": "Idle", "walk": "Walk", "run": "Sprint", "attack": "Punch_Cross", "hit": "Hit_Chest", "death": "Death01"}

static var _hero_lib: AnimationLibrary = null

# ------------------------------------------------------------------ helpers
static func has_assets() -> bool:
    return ResourceLoader.exists(HERO_MALE) and ResourceLoader.exists(HERO_ANIMS)

static func _skeleton_of(n: Node) -> Skeleton3D:
    return n.find_child("Skeleton3D", true, false) as Skeleton3D

## Height of the rest pose, measured from the skinned meshes.
static func _rest_height(n: Node) -> float:
    var top := -INF
    var bottom := INF
    for mi in n.find_children("*", "MeshInstance3D", true, false):
        var bb: AABB = (mi as MeshInstance3D).get_aabb()
        var t: Transform3D = (mi as MeshInstance3D).transform
        var p: Node = mi.get_parent()
        while p != null and p != n:
            if p is Node3D:
                t = (p as Node3D).transform * t
            p = p.get_parent()
        for corner in [bb.position, bb.end]:
            var y: float = (t * corner).y
            top = maxf(top, y)
            bottom = minf(bottom, y)
    return maxf(0.1, top - bottom) if top > bottom else 1.8

static func _tint(n: Node, color: Color, mix: float, skip: Array = ["Eye", "Eyebrow"]) -> void:
    for mi in n.find_children("*", "MeshInstance3D", true, false):
        var m := mi as MeshInstance3D
        if m.mesh == null:
            continue
        var skipped := false
        for prefix in skip:
            if String(m.name).begins_with(String(prefix)):
                skipped = true
        if skipped:
            continue
        for s in range(m.mesh.get_surface_count()):
            var src := m.get_active_material(s)
            if src is StandardMaterial3D:
                var mat := (src as StandardMaterial3D).duplicate() as StandardMaterial3D
                mat.albedo_color = mat.albedo_color.lerp(color, mix) if mix < 1.0 else color
                mat.roughness = 0.9
                m.set_surface_override_material(s, mat)

static func _tint_named(n: Node, mesh_name: String, color: Color, mix: float) -> void:
    var target := n.find_child(mesh_name, true, false) as MeshInstance3D
    if target == null or target.mesh == null:
        return
    for i in range(target.mesh.get_surface_count()):
        var src := target.get_active_material(i)
        if src is StandardMaterial3D:
            var mat := (src as StandardMaterial3D).duplicate() as StandardMaterial3D
            mat.albedo_color = mat.albedo_color.lerp(color, mix)
            target.set_surface_override_material(i, mat)

static func _hero_library() -> AnimationLibrary:
    if _hero_lib != null:
        return _hero_lib
    var lib := AnimationLibrary.new()
    var src: Node = (load(HERO_ANIMS) as PackedScene).instantiate()
    var ap := src.find_child("AnimationPlayer", true, false) as AnimationPlayer
    if ap != null:
        for clip in ap.get_animation_list():
            var a: Animation = ap.get_animation(clip).duplicate(true)
            var drop: Array[int] = []
            for i in range(a.get_track_count()):
                var path: NodePath = a.track_get_path(i)
                var leaf := String(path.get_name(path.get_name_count() - 1))
                var type := a.track_get_type(i)
                if type == Animation.TYPE_SCALE_3D or leaf == "root" or leaf == "Mannequin" or leaf == "Armature":
                    drop.append(i)
                    continue
                a.track_set_path(i, NodePath("Armature/Skeleton3D:" + leaf))
            drop.reverse()
            for i in drop:
                a.remove_track(i)
            if clip in ["Idle", "Walk", "Sprint", "Jog_Fwd", "Crouch_Idle", "Sword_Idle", "Pistol_Idle"]:
                a.loop_mode = Animation.LOOP_LINEAR
            lib.add_animation(clip, a)
    src.free()
    _hero_lib = lib
    return lib

static func _wrap(node: Node3D, height: float, target: float) -> Node3D:
    # glTF models face +Z, the game faces -Z: wrap in a node turned 180 degrees and normalise size.
    var holder := Node3D.new()
    var k := target / maxf(0.1, height)
    node.scale = Vector3(k, k, k)
    node.rotation.y = PI
    holder.add_child(node)
    return holder

# ------------------------------------------------------------------ hero
static func build_hero(raw_opts: Dictionary) -> Dictionary:
    var o := HB.sanitize(raw_opts)
    var female: bool = int(o["gender"]) == 1
    var scene := load(HERO_FEMALE if female else HERO_MALE) as PackedScene
    var node: Node3D = scene.instantiate()
    var skin: Color = HB.SKIN[int(o["skin"])]
    # the base texture is a warm medium tone: bring it towards the chosen skin colour
    _tint(node, skin.lerp(Color.WHITE, 0.25), 1.0)
    var height := _rest_height(node)
    var ap := AnimationPlayer.new()
    ap.name = "AnimationPlayer"
    ap.add_animation_library("", _hero_library())
    node.add_child(ap)
    ap.root_node = ap.get_path_to(node)
    var sk := _skeleton_of(node)
    add_clothes(node, int(o["top"]), HB.CLOTH[int(o["top_color"])], int(o["bottom"]), HB.PANTS[int(o["bottom_color"])], HB.SHOES[int(o["shoes_color"])])
    if sk != null:
        _attach_head_parts(sk, o, female, skin)
    _apply_face(node, o)
    var holder := _wrap(node, height, 1.78 if not female else 1.7)
    var bw: float = [0.92, 1.0, 1.1][int(o["build"])]
    holder.scale = Vector3(bw, 1.0, bw)
    holder.name = "Human"
    ap.play("Idle")
    return {"model": holder, "limbs": [], "rest": [], "anim": ap, "clips": HERO_CLIPS, "height": 1.8, "radius": 0.4, "swing": 1.0, "skeletal": true}

## Face shape = head bone scale; eye and eyebrow colours = material tints.
static func _apply_face(node: Node3D, o: Dictionary) -> void:
    var sk := _skeleton_of(node)
    if sk != null:
        var head_bone := sk.find_bone("Head")
        if head_bone >= 0:
            var shapes: Array = [Vector3(1, 1, 1), Vector3(1.1, 0.97, 1.05), Vector3(1.06, 0.95, 1.0), Vector3(0.92, 1.06, 0.96)]
            sk.set_bone_pose_scale(head_bone, shapes[int(o["face"])] * 1.06)
    _tint_named(node, "Eyes", HB.EYES[int(o["eyes"])].lightened(0.1), 0.7)
    _tint_named(node, "Eyebrows", HB.HAIR[int(o["hair_color"])], 0.9)

## Hair, beard and glasses are the procedural low-poly pieces, glued to the Head bone.
static func _attach_head_parts(sk: Skeleton3D, o: Dictionary, female: bool, skin: Color) -> void:
    if sk.find_bone("Head") < 0:
        return
    var LPc = preload("res://scripts/lowpoly.gd")
    var head = LPc.new()
    head.smooth = true
    var hair: Color = HB.HAIR[int(o["hair_color"])]
    HB._add_hair(head, int(o["hair_style"]), hair, 0.0)
    if not female:
        HB._add_beard(head, int(o["beard"]), hair, skin, 0.0)
    if bool(o["glasses"]):
        HB._add_glasses(head, 0.0)
    if head.is_empty():
        return
    var att := BoneAttachment3D.new()
    att.name = "HeadParts"
    att.bone_name = "Head"
    sk.add_child(att)
    var mesh: Node3D = head.to_node("HeadMesh")
    # our heads face -Z with the origin in the middle of the skull; the bone's axes are tuned in HEAD_FIX
    mesh.transform = HEAD_FIX
    att.add_child(mesh)

static var HEAD_FIX: Transform3D = Transform3D(Basis.from_euler(Vector3(0, PI, 0)).scaled(Vector3(0.9, 0.9, 0.9)), Vector3(0, 0.092, 0.0))

# ------------------------------------------------------------------ monsters
static func model_key_for(id: String) -> String:
    if ID_TO_MODEL.has(id):
        return ID_TO_MODEL[id]
    var kind := String(MD.get_monster(id).get("kind", "walker"))
    return KIND_TO_MODEL.get(kind, "hero")

## Returns {} when the monster should keep its procedural model.
static func build_monster(id: String) -> Dictionary:
    if not has_assets():
        return {}
    var p: Dictionary = MD.get_monster(id)
    var key := model_key_for(id)
    var s: float = float(p.get("scale", 1.0))
    var node: Node3D
    var ap: AnimationPlayer
    var clips: Dictionary
    var height: float
    var target: float
    if key == "hero":
        var female := (id.hash() % 2) == 1 and not bool(p.get("boss", false))
        var scene := load(HERO_FEMALE if female else HERO_MALE) as PackedScene
        node = scene.instantiate()
        var skin: Color = p.get("skin", Color(0.6, 0.67, 0.56))
        _tint(node, skin.darkened(0.1), 0.85)
        height = _rest_height(node)
        ap = AnimationPlayer.new()
        ap.name = "AnimationPlayer"
        ap.add_animation_library("", _hero_library())
        node.add_child(ap)
        ap.root_node = ap.get_path_to(node)
        _add_zombie_clothes(node, p)
        clips = HERO_CLIPS
        target = 1.74
    else:
        var def: Dictionary = MONSTER_MODELS[key]
        var path: String = MONSTER_DIR + String(def["file"])
        if not ResourceLoader.exists(path):
            return {}
        node = (load(path) as PackedScene).instantiate()
        ap = node.find_child("AnimationPlayer", true, false) as AnimationPlayer
        height = _rest_height(node)
        clips = def["clips"]
        target = float(def["height"])
        # colour variation: shift each monster towards its own palette
        var tint_col: Color = p.get("accent", p.get("skin", Color.WHITE))
        _tint(node, tint_col.lightened(0.25), 0.28)
    var holder := _wrap(node, height, target)
    holder.name = "Monster_" + key
    holder.scale = Vector3(s, s, s)
    if ap != null and ap.has_animation(clips["idle"]):
        ap.play(clips["idle"])
    var rad: float = {"demon": 0.55, "blue": 0.4, "orc": 0.8, "creep": 0.6, "hero": 0.4}[key]
    return {"model": holder, "limbs": [], "rest": [], "anim": ap, "clips": clips, "height": target * s, "radius": rad * s, "swing": 1.0, "skeletal": true}

static func _add_zombie_clothes(node: Node3D, p: Dictionary) -> void:
    add_clothes(node, 1, p.get("shirt", Color(0.5, 0.5, 0.45)), 0, p.get("pants", Color(0.3, 0.3, 0.27)), Color(0.14, 0.12, 0.1))
    var body: MeshInstance3D = null
    for mi in node.find_children("*", "MeshInstance3D", true, false):
        if String(mi.name).to_lower().begins_with("superhero"):
            body = mi
    if body != null:
        var blood := Color(0.34, 0.04, 0.04)
        for spec in [[["spine_02", "spine_03"], 1.12, 1.3], [["lowerarm_l"], 0.0, 9.0], [["thigh_r"], 0.5, 0.8]]:
            var l := _layer(body, "Blood", spec[0], spec[1], spec[2], 0.021, blood, 0.6)
            if l != null:
                body.get_parent().add_child(l)

# ------------------------------------------------------------------ clothes
const SHIRT_BONES := ["spine_01", "spine_02", "spine_03", "clavicle_l", "clavicle_r", "upperarm_l", "upperarm_r"]
const SLEEVE_BONES := ["lowerarm_l", "lowerarm_r"]
const PANT_BONES := ["pelvis", "thigh_l", "thigh_r", "calf_l", "calf_r"]
const SHOE_BONES := ["foot_l", "foot_r", "ball_l", "ball_r", "calf_l", "calf_r"]

## Builds a clothing layer as a copy of a part of the body mesh, pushed out along the normals.
## `bones`: dominant-bone whitelist, `ymin/ymax`: rest-pose height window, `grow`: thickness.
static func _layer(mi: MeshInstance3D, label: String, bones: Array, ymin: float, ymax: float, grow: float, color: Color, rough: float = 0.92) -> MeshInstance3D:
    var mesh := mi.mesh as ArrayMesh
    if mesh == null or mi.skin == null:
        return null
    var arrays: Array = mesh.surface_get_arrays(0)
    var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
    var bone_ids: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
    var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
    var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
    if bone_ids.size() == 0 or verts.size() == 0:
        return null
    var per: int = bone_ids.size() / verts.size()
    var ok := PackedByteArray()
    ok.resize(verts.size())
    for v in range(verts.size()):
        var best := -1
        var best_w := -1.0
        for k in range(per):
            var w: float = weights[v * per + k]
            if w > best_w:
                best_w = w
                best = bone_ids[v * per + k]
        var bone_name := String(mi.skin.get_bind_name(best)) if best >= 0 and best < mi.skin.get_bind_count() else ""
        if bone_name == "":
            var bi := mi.skin.get_bind_bone(best) if best >= 0 and best < mi.skin.get_bind_count() else -1
            var sk := mi.get_node_or_null(mi.skeleton) as Skeleton3D
            if sk != null and bi >= 0:
                bone_name = sk.get_bone_name(bi)
        var y: float = verts[v].y
        ok[v] = 1 if (bones.has(bone_name) and y >= ymin and y <= ymax) else 0
    var tris := PackedInt32Array()
    var count := index.size() if index.size() > 0 else verts.size()
    for t in range(0, count, 3):
        var a: int = index[t] if index.size() > 0 else t
        var b: int = index[t + 1] if index.size() > 0 else t + 1
        var c: int = index[t + 2] if index.size() > 0 else t + 2
        if ok[a] == 1 and ok[b] == 1 and ok[c] == 1:
            tris.append(a); tris.append(b); tris.append(c)
    if tris.size() == 0:
        return null
    var out_verts := PackedVector3Array(verts)
    for v in range(out_verts.size()):
        out_verts[v] = verts[v] + norms[v] * grow
    var out := []
    out.resize(Mesh.ARRAY_MAX)
    out[Mesh.ARRAY_VERTEX] = out_verts
    out[Mesh.ARRAY_NORMAL] = norms
    out[Mesh.ARRAY_BONES] = bone_ids
    out[Mesh.ARRAY_WEIGHTS] = weights
    out[Mesh.ARRAY_INDEX] = tris
    var cm := ArrayMesh.new()
    cm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = rough
    mat.cull_mode = BaseMaterial3D.CULL_BACK
    cm.surface_set_material(0, mat)
    var inst := MeshInstance3D.new()
    inst.name = label
    inst.mesh = cm
    inst.skin = mi.skin
    inst.skeleton = mi.skeleton
    inst.transform = mi.transform
    return inst

static func add_clothes(node: Node3D, top_style: int, top_col: Color, bottom_style: int, pants_col: Color, shoe_col: Color) -> void:
    var body: MeshInstance3D = null
    for mi in node.find_children("*", "MeshInstance3D", true, false):
        if String(mi.name).to_lower().begins_with("superhero"):
            body = mi
    if body == null:
        return
    var parent := body.get_parent()
    var layers: Array = []
    # shirt: torso (+ upper arms for a T-shirt, whole arms for shirt/jacket)
    var sleeve: Array = SHIRT_BONES.duplicate()
    if top_style != 0:
        sleeve.append_array(SLEEVE_BONES)
    var jacket: bool = top_style == 2
    layers.append(_layer(body, "Shirt", sleeve, 0.93, 1.5, 0.02 if jacket else 0.015, top_col.darkened(0.08) if jacket else top_col))
    # pants or shorts
    var pmin := 0.0 if bottom_style == 0 else 0.5
    layers.append(_layer(body, "Pants", PANT_BONES, pmin, 1.0, 0.013, pants_col))
    layers.append(_layer(body, "Shoes", SHOE_BONES, 0.0, 0.1, 0.01, shoe_col, 0.7))
    for l in layers:
        if l != null:
            parent.add_child(l)
