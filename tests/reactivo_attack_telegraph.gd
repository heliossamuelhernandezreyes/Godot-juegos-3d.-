extends SceneTree
## Runtime evidence: audible/readable enemy attack has a live dodge/cover window.
const SCENE = preload("res://scenes/reactivo_13.tscn")
const DRONE = preload("res://scripts/reactivo_eyedrone.gd")
func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var world = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    for e in get_nodes_in_group("enemies"):
        e.set_physics_process(false)
    world.player.global_position = Vector3(0, 1, 0)
    world.player.set_physics_process(false)
    var drone := CharacterBody3D.new()
    drone.set_script(DRONE)
    drone.asset_kind = "eye"
    drone.target = world.player
    drone.director = world
    drone.position = Vector3(0, 1, -6)
    world.add_child(drone)
    drone.set_physics_process(false)
    for i in range(3):
        await physics_frame
    if not drone._has_direct_sight():
        _fail("Expected exposed direct sight")
        return
    drone.ranged_timer = 0.0
    drone.action_time = 0.0
    var health_before: int = world.player.health
    drone._try_ranged_attack()
    if not drone.windup_active or drone.windup_remaining < 0.6:
        _fail("No visible pre-fire window")
        return
    if world.player.health != health_before:
        _fail("Damage landed before warning")
        return
    drone.windup_remaining = 0.001
    drone._try_ranged_attack()
    if world.player.health != health_before - 9 or drone.charged_shots != 1:
        _fail("Warning resolution did not fire a single 9-damage burst")
        return
    drone._try_ranged_attack()
    if world.player.health != health_before - 9:
        _fail("Cooldown failed: double hit")
        return
    print("REACTIVO TELEGRAPH PASS no-instant-damage 720ms-warning post-warning-hit=true cooldown=true")
    quit(0)

func _fail(reason: String) -> void:
    printerr("REACTIVO TELEGRAPH FAIL: "+reason)
    quit(1)
