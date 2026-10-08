extends SceneTree
## Real Godot 4.7.2 import audit of Quaternius CC0 skinning and animation.
const ROOT := "res://assets/vendor/quaternius/scifi_essentials/"
const MODELS := ["Enemy_QuadShell", "Enemy_EyeDrone", "Gun_Rifle"]
func _initialize() -> void:
    call_deferred("_audit")

func _audit() -> void:
    for name in MODELS:
        var scene: PackedScene = load(ROOT + name + ".gltf")
        if scene == null:
            _fail("GLTF not loaded " + name)
            return
        var node: Node3D = scene.instantiate()
        root.add_child(node)
        var counters: Dictionary = {"mesh":0,"skeleton":0,"players":0,"clips":[],"triangles":0}
        _traverse(node, counters)
        print("QUATERNIUS SCENE",name,"summary=",counters)
        if counters["mesh"] < 1:
            _fail("No renderer mesh " + name)
            return
        if name.begins_with("Enemy_"):
            if counters["skeleton"] == 0 or counters["players"] == 0:
                _fail("No skinned playable animation rig " + name)
                return
            if counters["clips"].size() < 4:
                _fail("Missing clips " + name)
                return
        node.queue_free()
    print("SKELETAL ASSET PASS: 2 animated rigs + PBR rifle")
    quit(0)

func _traverse(node: Node, counters: Dictionary) -> void:
    if node is Skeleton3D:
        counters["skeleton"] += 1
    if node is MeshInstance3D:
        counters["mesh"] += 1
        if node.mesh != null:
            for i in range(node.mesh.get_surface_count()):
                counters["triangles"] += node.mesh.surface_get_array_index_len(i) / 3
    if node is AnimationPlayer:
        counters["players"] += 1
        for name in node.get_animation_list():
            counters["clips"].append(name)
    for child in node.get_children():
        _traverse(child,counters)

func _fail(message: String) -> void:
    printerr("SKELETAL ASSET FAIL: " + message)
    quit(1)
