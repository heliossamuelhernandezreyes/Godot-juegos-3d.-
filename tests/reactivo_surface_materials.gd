extends SceneTree
## In-engine material acceptance: maps own physics, visuals own PBR.
const SCENE: PackedScene = preload("res://scenes/reactivo_13.tscn")

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var world: Node3D = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    var upgrade: Node3D = world.material_pass
    if upgrade == null or not upgrade.active:
        _fail("actual playable scene missing active material upgrade")
        return
    var col_before: Dictionary = _collider_fingerprints(world)
    var lights_before: int = _lights(world)
    if upgrade.textured_world_faces != 5 or upgrade.textured_prop_faces != 4:
        _fail("physical map/world source meshes not detected")
        return
    if upgrade.textured_architecture_faces < 20 or upgrade.glazed_panels != 4:
        _fail("generated architectural primitive coverage incomplete")
        return
    if upgrade.trim_nodes.size() != 16:
        _fail("expected four real tinted glass panels and twelve dry backing/frames")
        return
    for entry in upgrade.material_targets:
        var view: MeshInstance3D = entry["target"]
        var finish: Material = entry["candidate"]
        if view == null or view.material_override != finish:
            _fail("render source did not receive PBR override")
            return
        if not finish is ORMMaterial3D:
            _fail("replaced source primitive with flat shader rather than physical texture material")
            return
        var physical: ORMMaterial3D = finish as ORMMaterial3D
        if physical.albedo_texture == null or physical.orm_texture == null or not physical.normal_enabled:
            _fail("real albedo+ARM+normal textures not connected")
            return
        if not physical.uv1_triplanar:
            _fail("procedural geometry material lacks triplanar UV")
            return
    for part in upgrade.trim_nodes:
        if not part is MeshInstance3D or part.get_parent() != upgrade:
            _fail("glazing not a separate visual-only node")
            return
        if part.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
            _fail("unbudgeted real-time mobile shadow")
            return
        if part.name.contains("tinted instrumentation glass"):
            var glass: StandardMaterial3D = part.material_override as StandardMaterial3D
            if glass == null or glass.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA:
                _fail("instrument glazing is not actually transparent")
                return
    upgrade.set_material_upgrade_enabled(false)
    for entry in upgrade.material_targets:
        var view: MeshInstance3D = entry["target"]
        if view.material_override != entry["previous"]:
            _fail("original material not restored for matched camera baseline")
            return
    for part in upgrade.trim_nodes:
        if part.visible:
            _fail("glazing appears in OFF baseline")
            return
    upgrade.set_material_upgrade_enabled(true)
    if not upgrade.active or col_before != _collider_fingerprints(world) or lights_before != _lights(world):
        _fail("material-only toggle altered physics or lighting")
        return
    print("FISURA PROCEDURAL PBR PASS textures=%d world=%d architecture=%d props=%d true_glass=%d physics=unchanged lights=unchanged" %
        [upgrade.material_targets.size(),upgrade.textured_world_faces,
         upgrade.textured_architecture_faces,upgrade.textured_prop_faces,
         upgrade.glazed_panels])
    quit(0)

func _collider_fingerprints(node: Node, path: String = "") -> Dictionary:
    var result: Dictionary = {}
    var here := path + "/" + str(node.name)
    if node is CollisionObject3D:
        result[here] = {"class":node.get_class(),"transform":str(node.global_transform)}
    if node is CollisionShape3D:
        var shape: Shape3D = node.shape
        var descriptor := shape.get_class() if shape != null else "null"
        if shape is BoxShape3D:
            descriptor += ":" + str((shape as BoxShape3D).size)
        result[here] = {"class":descriptor, "transform":str(node.global_transform)}
    for child in node.get_children():
        result.merge(_collider_fingerprints(child,here))
    return result

func _lights(node: Node) -> int:
    var n := 1 if node is Light3D else 0
    for child in node.get_children():
        n += _lights(child)
    return n

func _fail(reason: String) -> void:
    printerr("FISURA PROCEDURAL PBR FAIL: ", reason)
    quit(1)
