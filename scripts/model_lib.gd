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
const GM = preload("res://scripts/gear_models.gd")
const ID = preload("res://scripts/items_data.gd")

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


# ------------------------------------------------------------------ faceting
## Skinned meshes are simplified (meshoptimizer LODs) and then flat-shaded, which gives
## the chunky hand-painted low-poly look. Simplified meshes are cached per source mesh.
const HERO_LOD := 1
const MONSTER_LOD := 1
static var _dec_cache := {}
static var _flat_cache := {}

static func _is_detail_mesh(mi: MeshInstance3D) -> bool:
    var n := String(mi.name)
    return n.begins_with("Eye") or n.begins_with("Eyebrow")

static func _decimate(node: Node, lod: int, gkey: String = "") -> void:
    for mi in node.find_children("*", "MeshInstance3D", true, false):
        var m := mi as MeshInstance3D
        if m.skin == null or not (m.mesh is ArrayMesh) or _is_detail_mesh(m):
            continue
        var src := m.mesh as ArrayMesh
        var key := ("%s|%s|%d" % [gkey, m.name, lod]) if gkey != "" else ("%d_%d" % [src.get_instance_id(), lod])
        var mats: Array = []
        for si in range(src.get_surface_count()):
            mats.append(m.get_active_material(si))
        if not _dec_cache.has(key):
            var im := ImporterMesh.new()
            for s in range(src.get_surface_count()):
                im.add_surface(src.surface_get_primitive_type(s), src.surface_get_arrays(s), [], {}, src.surface_get_material(s), "s%d" % s)
            im.generate_lods(25.0, 60.0, [])
            var out := ArrayMesh.new()
            for s in range(im.get_surface_count()):
                var full: Array = src.surface_get_arrays(s)
                var arr := []
                arr.resize(Mesh.ARRAY_MAX)
                for ch in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_BONES, Mesh.ARRAY_WEIGHTS, Mesh.ARRAY_INDEX]:
                    arr[ch] = full[ch]
                var n: int = im.get_surface_lod_count(s)
                if n > 0 and arr[Mesh.ARRAY_VERTEX].size() == im.get_surface_arrays(s)[Mesh.ARRAY_VERTEX].size():
                    arr[Mesh.ARRAY_INDEX] = im.get_surface_lod_indices(s, clampi(lod, 0, n - 1))
                out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
                out.surface_set_material(s, src.surface_get_material(s))
            _dec_cache[key] = out
        m.mesh = _dec_cache[key]
        for si in range(mats.size()):
            m.set_surface_override_material(si, mats[si])

static func _flat_copy(src: ArrayMesh) -> ArrayMesh:
    var out := ArrayMesh.new()
    for s in range(src.get_surface_count()):
        var arr: Array = src.surface_get_arrays(s)
        var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
        var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
        var uvs = arr[Mesh.ARRAY_TEX_UV]
        var bones = arr[Mesh.ARRAY_BONES]
        var wts = arr[Mesh.ARRAY_WEIGHTS]
        var cols = arr[Mesh.ARRAY_COLOR]
        var has_b: bool = bones != null and bones.size() > 0
        var per: int = (bones.size() / v.size()) if has_b else 0
        var count: int = idx.size() if idx.size() > 0 else v.size()
        var nv := PackedVector3Array(); var nn := PackedVector3Array(); var nu := PackedVector2Array()
        var nb := PackedInt32Array(); var nw := PackedFloat32Array(); var nc := PackedColorArray()
        for t in range(0, count, 3):
            var a: int = idx[t] if idx.size() > 0 else t
            var b: int = idx[t + 1] if idx.size() > 0 else t + 1
            var c: int = idx[t + 2] if idx.size() > 0 else t + 2
            var nrm: Vector3 = (v[b] - v[a]).cross(v[c] - v[a]).normalized()
            for k in [a, b, c]:
                nv.append(v[k]); nn.append(nrm)
                if uvs != null and uvs.size() > 0:
                    nu.append(uvs[k])
                if cols != null and cols.size() > 0:
                    nc.append(cols[k])
                if has_b:
                    for j in range(per):
                        nb.append(bones[k * per + j]); nw.append(wts[k * per + j])
        var a2 := []
        a2.resize(Mesh.ARRAY_MAX)
        a2[Mesh.ARRAY_VERTEX] = nv
        a2[Mesh.ARRAY_NORMAL] = nn
        if nu.size() > 0: a2[Mesh.ARRAY_TEX_UV] = nu
        if nc.size() > 0: a2[Mesh.ARRAY_COLOR] = nc
        if nb.size() > 0:
            a2[Mesh.ARRAY_BONES] = nb
            a2[Mesh.ARRAY_WEIGHTS] = nw
        out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a2)
        out.surface_set_material(s, src.surface_get_material(s))
    return out

static func _flatten(node: Node) -> void:
    for mi in node.find_children("*", "MeshInstance3D", true, false):
        var m := mi as MeshInstance3D
        if m.skin == null or not (m.mesh is ArrayMesh) or _is_detail_mesh(m):
            continue
        var src := m.mesh as ArrayMesh
        var key: int = src.get_instance_id()
        var fmats: Array = []
        for si in range(src.get_surface_count()):
            fmats.append(m.get_active_material(si))
        if _flat_cache.has(key):
            m.mesh = _flat_cache[key]
            for si in range(fmats.size()):
                m.set_surface_override_material(si, fmats[si])
            continue
        var flat := _flat_copy(src)
        if _dec_cache.values().has(src):
            _flat_cache[key] = flat
        m.mesh = flat
        for si in range(fmats.size()):
            m.set_surface_override_material(si, fmats[si])

# ------------------------------------------------------------------ hero
static func build_hero(raw_opts: Dictionary, gear: Dictionary = {}) -> Dictionary:
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
    var top_style := int(o["top"])
    var top_col: Color = HB.CLOTH[int(o["top_color"])]
    var bottom_style := int(o["bottom"])
    var pants_col: Color = HB.PANTS[int(o["bottom_color"])]
    var shoe_col: Color = HB.SHOES[int(o["shoes_color"])]
    var extra := {}
    var body_gear: Dictionary = ID.item(String(gear.get("body", "")))
    if not body_gear.is_empty():
        var look := String(body_gear["look"])
        if look == "jacket":
            top_style = 2
            top_col = body_gear["color"]
        else:
            extra["vest"] = {"color": body_gear["color"], "plate": look == "plate"}
    var legs_gear: Dictionary = ID.item(String(gear.get("legs", "")))
    if not legs_gear.is_empty():
        bottom_style = 0
        pants_col = legs_gear["color"]
    var feet_gear: Dictionary = ID.item(String(gear.get("feet", "")))
    if not feet_gear.is_empty():
        shoe_col = feet_gear["color"]
        extra["boots"] = true
    add_clothes(node, top_style, top_col, bottom_style, pants_col, shoe_col, extra)
    var head_gear: Dictionary = ID.item(String(gear.get("head", "")))
    var head_covered: bool = not head_gear.is_empty() and String(head_gear["look"]) != "cap"
    if sk != null:
        _attach_head_parts(sk, o, female, skin, head_covered)
        _attach_gear(sk, gear, extra)
    _apply_face(node, o)
    _decimate(node, HERO_LOD, "h%d_%d_%d_%s_%s" % [int(female), top_style, bottom_style, str(extra.keys()), str(extra.get("vest", {}).get("plate", false))])
    _flatten(node)
    var clips := HERO_CLIPS.duplicate()
    var held_data: Dictionary = ID.item(String(gear.get("weapon", "")))
    if not held_data.is_empty() and String(held_data.get("kind", "")) == "melee":
        clips["attack"] = "Sword_Attack"
    var holder := _wrap(node, height, 1.78 if not female else 1.7)
    var bw: float = [0.92, 1.0, 1.1][int(o["build"])]
    holder.scale = Vector3(bw, 1.0, bw)
    holder.name = "Human"
    ap.play("Idle")
    return {"model": holder, "limbs": [], "rest": [], "anim": ap, "clips": clips, "height": 1.8, "radius": 0.4, "swing": 1.0, "skeletal": true}

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
static func _attach_head_parts(sk: Skeleton3D, o: Dictionary, female: bool, skin: Color, hide_hair: bool = false) -> void:
    if sk.find_bone("Head") < 0:
        return
    var LPc = preload("res://scripts/lowpoly.gd")
    var head = LPc.new()
    head.smooth = true
    var hair: Color = HB.HAIR[int(o["hair_color"])]
    var hair_node: Node3D = null
    if not hide_hair:
        hair_node = GM.hair(int(o["hair_style"]), hair)
    if not female:
        HB._add_beard(head, int(o["beard"]), hair, skin, 0.0)
    if bool(o["glasses"]):
        HB._add_glasses(head, 0.0)
    if hair_node != null:
        _bone_attach(sk, "Head", hair_node, HEAD_FIX, "HairMesh")
    if head.is_empty():
        return
    var mesh: Node3D = head.to_node("HeadMesh")
    # our heads face -Z with the origin in the middle of the skull; the bone's axes are tuned in HEAD_FIX
    _bone_attach(sk, "Head", mesh, HEAD_FIX, "HeadParts")

static func _bone_attach(sk: Skeleton3D, bone: String, node: Node3D, xf: Transform3D, label: String) -> void:
    if sk.find_bone(bone) < 0:
        node.free()
        return
    var att := BoneAttachment3D.new()
    att.name = label
    att.bone_name = bone
    sk.add_child(att)
    node.transform = xf
    att.add_child(node)

## Weapon in the right hand, helmet/cap on the head, backpack on the back, pads on the shoulders.
static func _attach_gear(sk: Skeleton3D, gear: Dictionary, extra: Dictionary) -> void:
    var held := String(gear.get("weapon", ""))
    if held == "":
        held = String(gear.get("tool", ""))
    if held != "":
        var item := GM.hand_item(held)
        if item != null:
            _bone_attach(sk, "hand_r", item, HAND_FIX, "HeldItem")
    var hg: Dictionary = ID.item(String(gear.get("head", "")))
    if not hg.is_empty():
        var h := GM.head_item(String(hg["look"]), hg["color"])
        if h != null:
            _bone_attach(sk, "Head", h, HEAD_FIX, "HeadGear")
    var bg: Dictionary = ID.item(String(gear.get("back", "")))
    if not bg.is_empty():
        var p := GM.back_item(String(bg["look"]), bg["color"])
        if p != null:
            _bone_attach(sk, "spine_03", p, BACK_FIX, "BackItem")
    if extra.has("vest") and bool(extra["vest"].get("plate", false)):
        for side in ["l", "r"]:
            var pad := GM.shoulder_pad(extra["vest"]["color"])
            _bone_attach(sk, "upperarm_" + side, pad, Transform3D(Basis.IDENTITY, Vector3(0, 0.02, 0)), "Pad_" + side)

static var HAND_FIX: Transform3D = Transform3D(Basis.from_euler(Vector3(-0.7, 0, PI)), Vector3(0, 0.0, 0))
static var BACK_FIX: Transform3D = Transform3D(Basis.from_euler(Vector3(0, PI, 0)), Vector3(0, 0.0, -0.13))

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
    if BOSS_MODELS.has(id):
        var boss := _build_boss(id, p)
        if not boss.is_empty():
            return boss
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
        _tint(node, Color(0.62, 0.74, 0.6).lerp(skin, 0.3).darkened(0.08), 0.92)
        height = _rest_height(node)
        ap = AnimationPlayer.new()
        ap.name = "AnimationPlayer"
        ap.add_animation_library("", _hero_library())
        node.add_child(ap)
        ap.root_node = ap.get_path_to(node)
        _add_zombie_clothes(node, p)
        _zombie_details(node, id, p)
        _decimate(node, HERO_LOD, "z_" + id + str(female))
        _flatten(node)
        clips = HERO_CLIPS
        target = 1.74
    else:
        var def: Dictionary = MONSTER_MODELS[key]
        var path: String = MONSTER_DIR + String(def["file"])
        if not ResourceLoader.exists(path):
            return {}
        node = (load(path) as PackedScene).instantiate()
        ap = node.find_child("AnimationPlayer", true, false) as AnimationPlayer
        _decimate(node, MONSTER_LOD)
        _flatten(node)
        height = _rest_height(node)
        clips = def["clips"]
        target = float(def["height"])
        # colour variation: shift each monster towards its own palette
        var tint_col: Color = p.get("accent", p.get("skin", Color.WHITE))
        _tint(node, tint_col.lightened(0.25), 0.28)
    var holder := _wrap(node, height, target)
    if key == "hero":
        node.rotation.x = 0.2    # hunched, leaning towards the victim
    holder.name = "Monster_" + key
    holder.scale = Vector3(s, s, s)
    if ap != null and ap.has_animation(clips["idle"]):
        ap.play(clips["idle"])
    var rad: float = {"demon": 0.55, "blue": 0.4, "orc": 0.8, "creep": 0.6, "hero": 0.4}[key]
    return {"model": holder, "limbs": [], "rest": [], "anim": ap, "clips": clips, "height": target * s, "radius": rad * s, "swing": 1.0, "skeletal": true}


# ------------------------------------------------------------------ bosses (blockout, unrigged)
const BOSS_DIR := "res://assets/models/bosses/"
const BOSS_MODELS := {
    "mb_butcher": {"file": "afterfall_butcher.glb", "height": 1.85, "radius": 0.7},
    "boss_elder": {"file": "afterfall_carrier.glb", "height": 1.8, "radius": 0.8},
    "boss_matriarch": {"file": "afterfall_distorted.glb", "height": 2.0, "radius": 0.6},
    "boss_ripper": {"file": "afterfall_titan.glb", "height": 1.75, "radius": 0.9},
}
const ARM_WORDS := ["shoulder", "upper_arm", "elbow", "forearm", "bracer", "hand", "claw", "cleaver", "arm"]
const LEG_WORDS := ["thigh", "knee", "shin", "boot", "foot", "hock", "leg"]

static func _word_in(n: String, words: Array) -> bool:
    for w in words:
        if n.contains(w):
            return true
    return false

## Parts are authored in world space (Z up, facing -Y). Arms and legs are grouped into
## pivots at the shoulder/hip so the usual limb swing animation works.
static func _build_boss(id: String, p: Dictionary) -> Dictionary:
    var def: Dictionary = BOSS_MODELS[id]
    var path: String = BOSS_DIR + String(def["file"])
    if not ResourceLoader.exists(path):
        return {}
    var src: Node = (load(path) as PackedScene).instantiate()
    var rot := Basis.from_euler(Vector3(-PI / 2.0, PI, 0.0))
    var body := Node3D.new()
    body.name = "BossBody"
    var groups := {"arm_a": [], "arm_b": [], "leg_a": [], "leg_b": []}
    var minz := INF
    var maxz := -INF
    for mi in src.find_children("*", "MeshInstance3D", true, false):
        var m := mi as MeshInstance3D
        var ab: AABB = m.get_aabb()
        var c: Vector3 = m.transform * ab.get_center()
        minz = minf(minz, (m.transform * ab).position.z)
        maxz = maxf(maxz, (m.transform * ab).end.z)
        var n := String(m.name).to_lower()
        var side := "a" if c.x < 0.0 else "b"
        var key := ""
        if absf(c.x) > 0.12:
            if _word_in(n, LEG_WORDS) and not n.contains("shoulder"):
                key = "leg_" + side
            elif _word_in(n, ARM_WORDS):
                key = "arm_" + side
        var mat := StandardMaterial3D.new()
        var src_mat := m.get_active_material(0)
        if src_mat is StandardMaterial3D:
            mat = (src_mat as StandardMaterial3D).duplicate()
        mat.vertex_color_use_as_albedo = true
        mat.roughness = 0.9
        mat.metallic = 0.0
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
        if n.contains("eye"):
            mat.emission_enabled = true
            mat.emission = Color(1.0, 0.25, 0.12)
            mat.emission_energy_multiplier = 1.8
        m.set_surface_override_material(0, mat)
        m.get_parent().remove_child(m)
        m.transform = Transform3D.IDENTITY
        if key == "":
            m.transform = Transform3D(rot, Vector3.ZERO)
            body.add_child(m)
        else:
            groups[key].append(m)
    var limbs: Array = []
    var rests: Array = []
    for key in ["arm_a", "arm_b", "leg_a", "leg_b"]:
        var parts: Array = groups[key]
        var pivot_model := Vector3.ZERO
        var bb := AABB()
        var first := true
        for m in parts:
            var a: AABB = (m as MeshInstance3D).get_aabb()
            bb = a if first else bb.merge(a)
            first = false
        if not first:
            pivot_model = Vector3(bb.get_center().x, bb.get_center().y, bb.end.z - (0.18 if key.begins_with("arm") else 0.12))
        var pivot := Node3D.new()
        pivot.name = "Limb_" + key
        pivot.position = rot * pivot_model
        body.add_child(pivot)
        for m in parts:
            (m as MeshInstance3D).transform = Transform3D(rot, rot * (-pivot_model))
            pivot.add_child(m)
        limbs.append(pivot)
        rests.append(0.0)
    src.free()
    var raw_h: float = maxz - minz
    var target: float = float(def["height"])
    var holder := Node3D.new()
    holder.name = "Monster_boss"
    holder.add_child(body)
    body.scale = Vector3.ONE * (target / raw_h)
    body.position.y = -minz * (target / raw_h)
    var sc: float = float(p.get("scale", 1.0))
    holder.scale = Vector3(sc, sc, sc)
    return {"model": holder, "limbs": limbs, "rest": rests, "height": target * sc, "radius": float(def["radius"]) * sc, "swing": 1.0}

## Glowing eyes, wounds on the face and ratty hair for the infected.
static func _zombie_details(node: Node3D, id: String, p: Dictionary) -> void:
    var sk := _skeleton_of(node)
    var boss: bool = bool(p.get("boss", false)) or bool(p.get("mini", false))
    var eye_col := Color(1.0, 0.2, 0.12) if boss else Color(1.0, 0.82, 0.25)
    var eyes := node.find_child("Eyes", true, false) as MeshInstance3D
    if eyes != null and eyes.mesh != null:
        for i in range(eyes.mesh.get_surface_count()):
            var mat := StandardMaterial3D.new()
            mat.albedo_color = eye_col.darkened(0.2)
            mat.emission_enabled = true
            mat.emission = eye_col
            mat.emission_energy_multiplier = 1.6
            eyes.set_surface_override_material(i, mat)
    if sk == null:
        return
    var h := id.hash()
    var blood := Color(0.36, 0.04, 0.04)
    _bone_attach(sk, "Head", GM.zombie_head(h, blood), HEAD_FIX, "ZombieHead")
    if h % 3 != 0:
        var hair_col := Color(0.2, 0.17, 0.14).lerp(Color(0.5, 0.5, 0.48), float(h % 5) / 8.0)
        var hair_node := GM.hair(1 + (h % 2) * 3, hair_col)
        if hair_node != null:
            _bone_attach(sk, "Head", hair_node, HEAD_FIX, "RattyHair")

static func _add_zombie_clothes(node: Node3D, p: Dictionary) -> void:
    add_clothes(node, 1, Color(p.get("shirt", Color(0.5, 0.5, 0.45))).darkened(0.35), 0, Color(p.get("pants", Color(0.3, 0.3, 0.27))).darkened(0.25), Color(0.14, 0.12, 0.1), {"torn": true})
    var body: MeshInstance3D = null
    for mi in node.find_children("*", "MeshInstance3D", true, false):
        if String(mi.name).to_lower().begins_with("superhero"):
            body = mi
    if body != null:
        var blood := Color(0.34, 0.04, 0.04)
        var specs := [
            [["spine_01", "spine_02", "spine_03", "clavicle_l", "clavicle_r"], 0.95, 1.5, 0.45],
            [["upperarm_l", "upperarm_r", "lowerarm_l", "lowerarm_r"], 0.0, 9.0, 0.7],
            [["thigh_l", "thigh_r", "calf_l", "calf_r"], 0.0, 1.0, 0.75]]
        for spec in specs:
            var l := _layer(body, "Blood", spec[0], spec[1], spec[2], 0.024, blood, 0.5, 0.0, spec[3])
            if l != null:
                body.get_parent().add_child(l)

# ------------------------------------------------------------------ clothes
const SHIRT_BONES := ["spine_01", "spine_02", "spine_03", "clavicle_l", "clavicle_r", "upperarm_l", "upperarm_r"]
const SLEEVE_BONES := ["lowerarm_l", "lowerarm_r"]
const PANT_BONES := ["pelvis", "thigh_l", "thigh_r", "calf_l", "calf_r"]
const SHOE_BONES := ["foot_l", "foot_r", "ball_l", "ball_r", "calf_l", "calf_r"]

## Builds a clothing layer as a copy of a part of the body mesh, pushed out along the normals.
## `bones`: dominant-bone whitelist, `ymin/ymax`: rest-pose height window, `grow`: thickness.
static func _layer(mi: MeshInstance3D, label: String, bones: Array, ymin: float, ymax: float, grow: float, color: Color, rough: float = 0.92, rag: float = 0.0, splat: float = 99.0) -> MeshInstance3D:
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
        if ok[a] + ok[b] + ok[c] >= 2:
            if splat < 90.0:
                var sc: Vector3 = (verts[a] + verts[b] + verts[c]) / 3.0
                var f := sin(sc.x * 11.0 + 1.3) * sin(sc.y * 8.0 + 0.7) + sin(sc.z * 10.0 + 2.1) * sin(sc.y * 6.0 + sc.x * 3.0)
                if f <= splat:
                    continue
            if rag > 0.0:
                var cen: Vector3 = (verts[a] + verts[b] + verts[c]) / 3.0
                var noise := fposmod(sin(cen.x * 91.7 + cen.z * 47.3 + cen.y * 131.1) * 43758.5453, 1.0)
                if cen.y < ymin + rag * noise:
                    continue
            tris.append(a); tris.append(b); tris.append(c)
    if tris.size() == 0:
        return null
    var out_verts := PackedVector3Array(verts)
    for v in range(out_verts.size()):
        out_verts[v] = verts[v] + norms[v] * (grow + 0.009)
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

static func add_clothes(node: Node3D, top_style: int, top_col: Color, bottom_style: int, pants_col: Color, shoe_col: Color, extra: Dictionary = {}) -> void:
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
    var torn: bool = bool(extra.get("torn", false))
    layers.append(_layer(body, "Shirt", sleeve, 0.93, 1.5, 0.02 if jacket else 0.015, top_col.darkened(0.08) if jacket else top_col, 0.92, 0.2 if torn else 0.0))
    # pants or shorts
    var pmin := 0.0 if bottom_style == 0 else 0.5
    layers.append(_layer(body, "Pants", PANT_BONES, pmin, 1.0, 0.013, pants_col, 0.92, 0.45 if torn else 0.0))
    layers.append(_layer(body, "Shoes", SHOE_BONES, 0.0, 0.27 if bool(extra.get("boots", false)) else 0.1, 0.013 if bool(extra.get("boots", false)) else 0.01, shoe_col, 0.7))
    if extra.has("vest"):
        var v: Dictionary = extra["vest"]
        layers.append(_layer(body, "Vest", ["spine_01", "spine_02", "spine_03"], 0.95, 1.48, 0.03 if bool(v["plate"]) else 0.024, v["color"], 0.55 if bool(v["plate"]) else 0.9))
    for l in layers:
        if l != null:
            parent.add_child(l)
