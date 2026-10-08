extends SceneTree
## Enemy attack evidence: line of sight required, ranged damage and cooldown.
const ENEMY_SCRIPT = preload("res://scripts/animated_reaver.gd")
func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    var game = scene.instantiate()
    root.add_child(game)
    game.player.global_position = Vector3(0, 1, 13)
    var drone := CharacterBody3D.new()
    drone.set_script(ENEMY_SCRIPT)
    drone.asset_kind = "eye"
    drone.target = game.player
    drone.director = game
    drone.ranged_timer = 99.0
    drone.position = Vector3(4, 1, 13)
    game.add_child(drone)
    for i in range(3):
        await physics_frame
    if not drone._has_direct_sight():
        _fail("No line of sight on open arena")
        return
    var hp_start: int = game.player.health
    drone.ranged_timer = 0.0
    drone.action_time = 0.0
    drone._try_ranged_attack()
    if game.player.health >= hp_start:
        _fail("Drone did not apply ranged damage")
        return
    if drone.ranged_timer < 2.0:
        _fail("Drone cooldown not set")
        return
    if drone.selected_clip != "Attack":
        _fail("Ranged fire did not trigger skeletal Attack")
        return
    drone.ranged_timer = 99.0
    game.player.global_position = Vector3(-7, 1, 3)
    drone.global_position = Vector3(-7, 1, -6)
    for i in range(3):
        await physics_frame
    if drone._has_direct_sight():
        _fail("Ranged attack sees through solid cover")
        return
    print("DRONE RANGED PASS: visible damage, cooldown, skeletal attack; cover blocks fire")
    quit(0)

func _fail(msg: String) -> void:
    printerr("DRONE RANGED FAIL " + msg)
    quit(1)
