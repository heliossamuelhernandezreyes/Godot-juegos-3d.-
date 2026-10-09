extends SceneTree
## ARCONT P2 visual pilot regression: no changes to gameplay-owned physics.
const SCENE: PackedScene = preload("res://scenes/reactivo_13.tscn")

func _initialize() -> void:
    call_deferred("_check")

func _check() -> void:
    var world: Node3D = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    var stage: Node3D = world.cinematic_stage
    if stage == null or stage.node_a_pilot == null:
        _fail("Node A pilot missing from playable scene")
        return
    var pilot: Node3D = stage.node_a_pilot
    if pilot.position.distance_to(Vector3(-28.0, 0.0, 0.55)) > 0.01:
        _fail("Pilot not aligned behind game-owned Node A interaction anchor")
        return
    if pilot.render_meshes < 54 or pilot.render_meshes > 100:
        _fail("Pilot visual-only primitive budget violated: " + str(pilot.render_meshes))
        return
    var lights_before := _collect_lights(world)
    var shapes_before := _collect_colliders(world)
    if lights_before != 13:
        _fail("Existing Reactivo-13 light fixture count changed: " + str(lights_before))
        return
    if shapes_before < 20:
        _fail("Existing mission colliders unexpectedly missing")
        return
    var visuals := 0
    var normal_materials := 0
    var emission_materials := 0
    for child in pilot.get_children():
        if child is CollisionObject3D or child is CollisionShape3D or child is Light3D:
            _fail("Node A pilot must not own physics or real lights: " + child.name)
            return
        if child is MeshInstance3D:
            visuals += 1
            if child.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
                _fail("Pilot adds an unbudgeted realtime shadow")
                return
            if child.material_override is BaseMaterial3D:
                var material := child.material_override as BaseMaterial3D
                if material.normal_enabled:
                    normal_materials += 1
                if material.emission_enabled:
                    emission_materials += 1
    if visuals != pilot.render_meshes or normal_materials < 5 or emission_materials < 5:
        _fail("Hero asset is not fully instanced with PBR normal + emission accents")
        return
    var control: Node3D = world.consoles["node_a_console"]
    if control.global_position.distance_to(Vector3(-28, 0.17, 4)) > 0.05:
        _fail("Pilot displaced gameplay-owned interaction")
        return
    stage.set_node_a_pilot_enabled(false)
    if pilot.visible:
        _fail("Before shot cannot disable visual-only pilot")
        return
    stage.set_node_a_pilot_enabled(true)
    if not pilot.visible or _collect_lights(world) != lights_before or _collect_colliders(world) != shapes_before:
        _fail("Visual-only comparison changed physics or lights")
        return
    print("REACTIVO NODE A VISUAL PILOT PASS meshes=%d normals=%d emission=%d lights=unchanged colliders=unchanged" %
        [visuals, normal_materials, emission_materials])
    quit(0)

func _collect_lights(node: Node) -> int:
    var count := 1 if node is Light3D else 0
    for child in node.get_children():
        count += _collect_lights(child)
    return count

func _collect_colliders(node: Node) -> int:
    var count := 1 if node is CollisionObject3D or node is CollisionShape3D else 0
    for child in node.get_children():
        count += _collect_colliders(child)
    return count

func _fail(reason: String) -> void:
    printerr("REACTIVO NODE A VISUAL PILOT FAIL " + reason)
    quit(1)
