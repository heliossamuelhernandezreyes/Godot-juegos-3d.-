extends SceneTree
## Deterministic end-to-end Reactivo-13 objective and interaction regression.
const SCENE = preload("res://scenes/reactivo_13.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var world = SCENE.instantiate()
    root.add_child(world)
    if world.player == null or world.director == null or world.tactical_nav == null:
        _fail("Mission scene did not initialize")
        return
    for actor in get_nodes_in_group("enemies"):
        actor.set_physics_process(false)
    world.testing_disable_spawns = true
    if world.director.phase_id != "insertion" or world.director.complete("collect_reactor"):
        _fail("Intro state allows mission skip")
        return
    if world.gate_shape.disabled:
        _fail("Main gate must begin closed")
        return
    world.player.global_position = Vector3(0, 1, 16)
    world._process(0.016)
    if world.director.phase_id != "penetration":
        _fail("Zone access did not advance mission")
        return
    if world.director.complete("collect_reactor"):
        _fail("Reactor collection occurred before energy")
        return
    world.interact_held = true
    # B before A must be valid and not open gate early.
    world.player.global_position = world.positions["node_b_console"] + Vector3(0, 1, 0)
    world._interact_tick(1.6)
    if not world.director.is_complete("power_b") or world.director.phase_id != "penetration" or world.gate_shape.disabled:
        _fail("Node B behavior incorrect")
        return
    world.player.global_position = world.positions["node_a_console"] + Vector3(0, 1, 0)
    world._interact_tick(1.6)
    if world.director.phase_id != "core_chamber":
        _fail("Both nodes did not unlock reactor")
        return
    # set_deferred applies at the next physics frame
    await physics_frame
    if not world.gate_shape.disabled:
        _fail("Reactor gate collider remained solid")
        return
    world.player.global_position = world.positions["reactor_altar"] + Vector3(0, 1, 0)
    world._interact_tick(2.1)
    if world.director.phase_id != "defense":
        _fail("Reactor interact did not start defense")
        return
    if world.director.complete("evacuate"):
        _fail("Extraction unlocked before defense")
        return
    for actor in get_nodes_in_group("enemies"):
        if is_instance_valid(actor):
            actor.queue_free()
    await process_frame
    world.director.update_defense(74.9, 0)
    if world.director.phase_id != "defense":
        _fail("Defense gate opened before 75 s")
        return
    world.director.update_defense(0.2, 0)
    if world.director.phase_id != "extraction":
        _fail("Defense completion failed")
        return
    world.player.global_position = world.positions["extraction_pad"] + Vector3(0, 1, 0)
    world._interact_tick(2.1)
    if world.director.phase_id != "victory" or not world.won:
        _fail("Hold extraction did not end in victory")
        return
    if world.director.complete("evacuate"):
        _fail("Victory can be completed twice")
        return
    print("REACTIVO PLAYTHROUGH PASS insertion -> B+A -> core -> defense 75s -> extraction; anti-skip=true")
    quit(0)

func _fail(message: String) -> void:
    printerr("REACTIVO PLAYTHROUGH FAIL: " + message)
    quit(1)
