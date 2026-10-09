extends SceneTree
## Native level verifies honest imported GLB meshes and unchanged gameplay physics.
const SCENE = preload("res://scenes/reactivo_13.tscn")
func _initialize() -> void:
    call_deferred("_verify")
func _verify() -> void:
    var world: Node3D = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    var kit: Node3D = world.cinematic_stage.node_a_factory
    if kit == null or kit.authored_models.size()!=14 or kit.model_counts.size()!=10:
        _fail("missing source-licensed Factory Kit instances")
        return
    if kit.replaced_legacy_visuals.size()!=12 or not kit.visible_kit:
        _fail("legacy Node A geometry not actually replaced")
        return
    var collision_baseline: Dictionary = _collision_state(world)
    var light_baseline: int = _light_count(world)
    var imported_meshes := 0
    for model in kit.authored_models:
        if model.scale == Vector3.ONE or not model.visible:
            _fail("source model not positioned/scaled and visible")
            return
        if model is CollisionObject3D or model is Light3D:
            _fail("source instance introduces new physical / lighting nodes")
            return
        imported_meshes+=_validate_meshes(model)
    if imported_meshes < 14 or kit.draw_mesh_nodes != imported_meshes or kit.geometry_triangles < 1000:
        _fail("GLB native polygon evidence incomplete")
        return
    for mesh in kit.replaced_legacy_visuals:
        if mesh.visible:
            _fail("original giant coolant block still occludes real model")
            return
    kit.set_factory_upgrade_enabled(false)
    for model in kit.authored_models:
        if model.visible:
            _fail("original-state toggle kept new polygon asset on")
            return
    for mesh in kit.replaced_legacy_visuals:
        if not mesh.visible:
            _fail("baseline did not restore authored coolant structure")
            return
    kit.set_factory_upgrade_enabled(true)
    if collision_baseline != _collision_state(world) or light_baseline != _light_count(world):
        _fail("render-only GLB swap changed gameplay collision or light budget")
        return
    for mesh in kit.replaced_legacy_visuals:
        if mesh.visible:
            _fail("source primitive overlap returned after candidate toggle")
            return
    print("FISURA KENNEY FACTORY NATIVE PASS models=14 unique=10 actual_meshes=%d source_triangles=%d changed_colliders=0 lights=%d" %
        [imported_meshes,kit.geometry_triangles,light_baseline])
    quit(0)

func _validate_meshes(node: Node) -> int:
    if node is CollisionObject3D or node is CollisionShape3D or node is Light3D:
        _fail("embedded physics/light in imported source")
        return 0
    var n := 0
    if node is MeshInstance3D:
        var mesh: Mesh = node.mesh
        if mesh == null or mesh is BoxMesh or mesh is CylinderMesh or mesh.get_surface_count()==0:
            _fail("imported GLB lacks genuine polygon mesh")
            return 0
        if node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
            _fail("unexpected mobile shadow caster in decoration")
            return 0
        n += 1
    for sub in node.get_children():
        n += _validate_meshes(sub)
    return n

func _collision_state(parent: Node, path: String = "") -> Dictionary:
    var result := {}
    var at := path+"/"+str(parent.name)
    if parent is CollisionObject3D:
        result[at] = str(parent.global_transform)
    if parent is CollisionShape3D:
        var meta: String = parent.shape.get_class()
        if parent.shape is BoxShape3D:
            meta += str(parent.shape.size)
        result[at] = str(parent.global_transform)+meta
    for item in parent.get_children():
        result.merge(_collision_state(item,at))
    return result

func _light_count(parent: Node) -> int:
    var n:=1 if parent is Light3D else 0
    for item in parent.get_children():
        n+=_light_count(item)
    return n

func _fail(reason: String) -> void:
    printerr("FISURA KENNEY FACTORY NATIVE FAIL ",reason)
    quit(1)
