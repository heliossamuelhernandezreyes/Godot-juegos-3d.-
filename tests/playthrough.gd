extends SceneTree
## End-to-end logic test. Runs with: godot --headless --path . --script res://tests/playthrough.gd

var game

func _initialize() -> void:
    call_deferred("_run_test")

func _run_test() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    if scene == null:
        _fail("Main scene not loadable")
        return
    game = scene.instantiate()
    root.add_child(game)
    if game.player == null:
        _fail("Player was not spawned")
        return
    if game.cores.size() != 3:
        _fail("Three collectable cores were not created")
        return
    game.player.take_damage(25)
    if game.player.health != 75:
        _fail("Health/damage contract failed")
        return
    for core_id in ["core_alpha", "core_beta", "core_gamma"]:
        var destination: Vector3 = game.anchors[core_id]
        game.player.global_position = destination + Vector3(0, 1.0, 0)
        game._check_objectives()
    if game.collected != 3:
        _fail("Core extraction loop failed")
        return
    if game.portal_material.emission_energy_multiplier < 3.0:
        _fail("Portal did not unlock")
        return
    game.player.global_position = game.anchors["exit_portal"] + Vector3(0, 1.0, 0)
    game._check_objectives()
    if not game.finished:
        _fail("Victory did not trigger")
        return
    print("PLAYTHROUGH PASS: player, health, 3 cores, unlocked portal, extraction victory")
    quit(0)

func _fail(reason: String) -> void:
    printerr("PLAYTHROUGH FAIL: " + reason)
    quit(1)
