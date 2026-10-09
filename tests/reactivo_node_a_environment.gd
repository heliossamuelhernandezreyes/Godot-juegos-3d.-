extends SceneTree
## ARCONT P2: native gameplay-immutable check for Node A environment/cover dressing.
const SCENE: PackedScene = preload("res://scenes/reactivo_13.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var world: Node3D = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    var stage: Node3D = world.cinematic_stage
    if stage == null or stage.node_a_environment == null:
        _fail("environment layer absent in playable Reactivo-13")
        return
    var layer: Node3D = stage.node_a_environment
    if layer.position.distance_to(Vector3(-28.0,0.0,4.0)) > 0.001:
        _fail("environment dressing displaced from game-owned Node A anchor")
        return
    var count: int = int(layer.get("environment_meshes"))
    if count < 60 or count > 124:
        _fail("environment mesh budget out of bounds: " + str(count))
        return
    var render_count := 0
    var normal_mapped := 0
    var cover_count := 0
    var coverage_count := 0
    for item in layer.get_children():
        if item is Light3D or item is CollisionObject3D or item is CollisionShape3D:
            _fail("visual layer may not create physics or lights: " + item.name)
            return
        if item is MeshInstance3D:
            render_count += 1
            var mesh := item as MeshInstance3D
            if mesh.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
                _fail("visual-only environment adds unwanted cast shadows")
                return
            if mesh.material_override is BaseMaterial3D and (mesh.material_override as BaseMaterial3D).normal_enabled:
                normal_mapped += 1
            if mesh.name.contains("cover |"):
                cover_count += 1
                # Cover is the existing game-owned x=-23,y=1,z=0 box, size 2x2x6.
                # The visual cover trim must lie within its collider extents.
                var at: Vector3 = mesh.global_position
                var cover: Vector3 = Vector3(-23.0,1.0,0.0)
                if absf(at.x - cover.x) > 1.0 or absf(at.y - cover.y) > 1.0 or absf(at.z - cover.z) > 3.0:
                    _fail("cover facade extends outside gameplay-owned cover proxy")
                    return
            if mesh.name.contains("panel | worn slab"):
                coverage_count += 1
    if render_count != count or normal_mapped < 35 or cover_count != 9 or coverage_count != 25:
        _fail("PBR floor/cover/pass missing: count=%d PBR=%d cover=%d floor=%d" %
            [render_count,normal_mapped,cover_count,coverage_count])
        return
    var total_light: int = _light_count(world)
    var total_physics: int = _physics_count(world)
    if total_light != 13:
        _fail("global light count changed unexpectedly: " + str(total_light))
        return
    if world.consoles["node_a_console"].global_position.distance_to(Vector3(-28,0.17,4)) > 0.05:
        _fail("Node A console interaction displaced")
        return
    stage.set_node_a_environment_enabled(false)
    if layer.visible:
        _fail("environment baseline cannot switch off")
        return
    stage.set_node_a_environment_enabled(true)
    if not layer.visible or total_light != _light_count(world) or total_physics != _physics_count(world):
        _fail("environment toggle modified scene physics or lighting")
        return
    print("REACTIVO NODE A ENVIRONMENT PASS meshes=%d normal_mapped=%d floor=25 cover=9 lights=13 physics=unchanged" %
        [render_count,normal_mapped])
    quit(0)

func _light_count(parent: Node) -> int:
    var tally := 1 if parent is Light3D else 0
    for item in parent.get_children():
        tally += _light_count(item)
    return tally

func _physics_count(parent: Node) -> int:
    var tally := 1 if parent is CollisionObject3D or parent is CollisionShape3D else 0
    for item in parent.get_children():
        tally += _physics_count(item)
    return tally

func _fail(detail: String) -> void:
    printerr("REACTIVO NODE A ENVIRONMENT FAIL ", detail)
    quit(1)
