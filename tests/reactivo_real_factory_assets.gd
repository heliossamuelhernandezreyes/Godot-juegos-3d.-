extends SceneTree
## Gate actual 3D imported Kenney GLB geometry, reversible same-build art,
## and unchanged game-owned mission route/collision/lighting.
const SCENE: PackedScene = preload("res://scenes/reactivo_13.tscn")
const PROVENANCE := "res://assets/vendor/kenney_factory_kit/PROVENANCE.json"

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var receipt: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROVENANCE))
    if typeof(receipt) != TYPE_DICTIONARY or receipt.get("license") != "CC0-1.0":
        _fail("source provenance or Kenney CC0 license missing")
        return
    if receipt.get("archive_sha256") != "7e31fb2308e90304672bd15cd18fa9d9f02c03731a8cbc57a8e3e1c181dfb0a7":
        _fail("upstream creator source archive not cryptographically pinned")
        return
    if int(receipt.get("source_triangles_sum",1000000)) > 5000:
        _fail("asset pack source polygon bound exceeded")
        return
    var world: Node3D = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    var layer: Node3D = world.cinematic_stage.node_a_factory_kit
    if layer == null or not layer.active:
        _fail("new real GLB factory kit is not active in actual playable scene")
        return
    if layer.legacy_blockouts.size() != 4 or layer.authentic_instances.size() != 11:
        _fail("incomplete production asset staging/replacement count")
        return
    if layer.authentic_mesh_nodes < 11:
        _fail("no authentic mesh nodes imported from GLB assets")
        return
    var colliders: Dictionary = _physics_snapshot(world)
    var light_count: int = _count_lights(world)
    for original in layer.legacy_blockouts:
        if original.visible or not original.mesh is BoxMesh:
            _fail("original cuboid visual not hidden or original collision altered")
            return
    for asset in layer.authentic_instances:
        if not asset.visible:
            _fail("imported GLB model hidden unexpectedly")
            return
        if not str(asset.name).begins_with("KENNEY CC0 |"):
            _fail("source trace missing")
            return
        if _has_gameplay_node(asset):
            _fail("unexpected physics collision or realtime light inside source 3D asset")
            return
    world.cinematic_stage.set_node_a_factory_kit_enabled(false)
    for original in layer.legacy_blockouts:
        if not original.visible:
            _fail("original primitive could not be restored")
            return
    for model in layer.authentic_instances:
        if model.visible:
            _fail("genuine imported model contaminates baseline screenshot")
            return
    world.cinematic_stage.set_node_a_factory_kit_enabled(true)
    if not layer.active or _physics_snapshot(world) != colliders or _count_lights(world) != light_count:
        _fail("render-only source swap mutated game physics or illumination")
        return
    print("FISURA ARCONT REAL GLB PASS imported_models=%d visible_meshes=%d source_triangles=%d collider=unchanged lights=unchanged" %
        [layer.authentic_instances.size(),layer.authentic_mesh_nodes,receipt.source_triangles_sum])
    quit(0)

func _has_gameplay_node(node: Node) -> bool:
    if node is CollisionObject3D or node is CollisionShape3D or node is Light3D:
        return true
    for child in node.get_children():
        if _has_gameplay_node(child):
            return true
    return false

func _physics_snapshot(node: Node, prefix: String = "") -> Dictionary:
    var result := {}
    var path := prefix + "/" + str(node.name)
    if node is CollisionObject3D:
        result[path] = str(node.global_transform)
    if node is CollisionShape3D:
        var shape: Shape3D = node.shape
        result[path] = str(node.global_transform) + ":" + (str((shape as BoxShape3D).size) if shape is BoxShape3D else str(shape))
    for child in node.get_children():
        result.merge(_physics_snapshot(child,path))
    return result

func _count_lights(node: Node) -> int:
    var count := 1 if node is Light3D else 0
    for child in node.get_children():
        count += _count_lights(child)
    return count

func _fail(message: String) -> void:
    printerr("FISURA ARCONT REAL GLB FAIL ", message)
    quit(1)
