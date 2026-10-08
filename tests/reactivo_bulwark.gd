extends SceneTree
## Source-traced negative control: Bulwark frontal shield cannot be bypassed by head-on fire.
const BULWARK = preload("res://scripts/reactivo_bulwark.gd")
const SCENE = preload("res://scenes/reactivo_13.tscn")

func _initialize() -> void:
    call_deferred("_check")

func _check() -> void:
    var world = SCENE.instantiate()
    root.add_child(world)
    for enemy in get_nodes_in_group("enemies"):
        enemy.set_physics_process(false)
    var guard := CharacterBody3D.new()
    guard.set_script(BULWARK)
    guard.target = world.player
    guard.director = world
    guard.position = Vector3(0, 1, 1)
    world.add_child(guard)
    guard.set_physics_process(false)
    guard.rotation.y = 0.0
    if guard.rig == null or guard.animation_player == null:
        _fail("High-fidelity Bulwark must have an imported skinned playable rig")
        return
    if guard.animation_player.get_animation_list().size() < 8:
        _fail("Bulwark source pack animation clips missing")
        return
    if guard.selected_clip != "Idle":
        _fail("Bulwark fails to activate Idle at initial spawn")
        return
    var full_hp: int = guard.hit_points
    guard.take_hit_from(23, guard.global_position + Vector3(0, 0, -5))
    var front_loss: int = full_hp - guard.hit_points
    if guard.selected_clip != "Hit":
        _fail("Bulwark frontal impact did not trigger native Hit animation")
        return
    if front_loss != 6 or guard.absorbed_hits != 1:
        _fail("Frontal armor did not reduce damage to ceil(23*0.22)=6: "+str(front_loss))
        return
    var before: int = guard.hit_points
    guard.take_hit_from(23, guard.global_position + Vector3(0, 0, 5))
    if before - guard.hit_points != 23:
        _fail("Rear attack wrongly benefited from frontal armor")
        return
    if world.director.phase_id != "insertion":
        _fail("Bulwark test unexpectedly changes mission")
        return
    print("BULWARK SHIELD PASS front=%d back=23 flanking=true skinned_rig=true native_hit=true" % front_loss)
    quit(0)

func _fail(reason: String) -> void:
    printerr("BULWARK SHIELD FAIL: " + reason)
    quit(1)
