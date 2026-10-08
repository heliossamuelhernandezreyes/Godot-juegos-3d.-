extends SceneTree
## ARCONT visual/cost gate for the actual 84x66 Reactivo-13 stage.
const SCENE = preload("res://scenes/reactivo_13.tscn")
func _initialize() -> void:
    call_deferred("_check")

func _check() -> void:
    var game = SCENE.instantiate()
    root.add_child(game)
    var art = game.stage
    if art == null or not is_instance_valid(art):
        _fail("missing live art stage")
        return
    if art.instanced_tiles < 300:
        _fail("floor instancing absent: " + str(art.instanced_tiles))
        return
    if art.unique_lights > 8 or art.unique_lights < 5:
        _fail("bad dynamic light budget " + str(art.unique_lights))
        return
    if art.environment_parts < 150 or art.environment_parts > 750:
        _fail("stage geometry unexpectedly sparse/expensive: " + str(art.environment_parts))
        return
    # ARCONT VISUAL-02: prevent uncollidable presentation meshes enclosing
    # the camera at the two mission terminals (regression from screenshot review).
    var processors := 0
    for node in art.get_children():
        if not (node is MeshInstance3D) or not str(node.name).begins_with("Cryo processor vessel"):
            continue
        processors += 1
        var processor_box: BoxMesh = node.mesh as BoxMesh
        if processor_box == null:
            _fail("Cryo processor must have finite BoxMesh bounds")
            return
        var size: Vector3 = processor_box.size
        for id in ["node_a_console", "node_b_console"]:
            var camera_probe: Vector3 = game.positions[id] + Vector3(1.05, 4.35, 12.15)
            var offset: Vector3 = camera_probe - node.global_position
            if absf(offset.x) < size.x * 0.5 + 0.20 and absf(offset.y) < size.y * 0.5 + 0.20 and absf(offset.z) < size.z * 0.5 + 0.20:
                _fail("Terminal shoulder-camera inside procedural machine: " + str(id))
                return
    if processors != 4:
        _fail("Expected four industrial processor meshes, got " + str(processors))
        return
    if art.reactor_light == null:
        _fail("reactor focal lighting missing")
        return
    var prior: float = art.reactor_light.light_energy
    art.set_alarm(true)
    for _i in range(3):
        await process_frame
    if not art.is_alarm:
        _fail("phase did not reach visual warning system")
        return
    art.set_alarm(false)
    if art.is_alarm:
        _fail("visual warning cannot reset")
        return
    if game.camera.global_position.distance_to(game.player.global_position) > 7.8:
        _fail("hero too small by camera distance; visual framing regression")
        return
    print("REACTIVO ART QA PASS instanced_tiles=%d drawn_nodes=%d lights=%d camera=%s" %
        [art.instanced_tiles,art.environment_parts,art.unique_lights,str(game.camera.global_position)])
    print("QA LIMIT: no device-GPU draw call, screenshot aesthetics or Android thermals measured")
    quit(0)

func _fail(reason: String) -> void:
    printerr("REACTIVO ART QA FAIL: " + reason)
    quit(1)
