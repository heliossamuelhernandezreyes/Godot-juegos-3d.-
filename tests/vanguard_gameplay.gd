extends SceneTree
## ARCONT runtime evidence: actual imported Vanguard humanoid plays gameplay states.
func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var packed: PackedScene = load("res://scenes/main.tscn")
    var game = packed.instantiate()
    root.add_child(game)
    var soldier = game.player
    if soldier.humanoid_skeleton == null or soldier.rig_animation == null or not soldier.visual_ready:
        _fail("No active Vanguard human rig")
        return
    if soldier.selected_clip != "Idle_Gun":
        _fail("Idle is not the initial animation")
        return
    soldier.touch_axis = Vector2(0,-1)
    for i in range(4):
        await physics_frame
    if soldier.selected_clip != "Run":
        _fail("Forward movement did not activate Run: "+soldier.selected_clip)
        return
    soldier.on_weapon_fired()
    if soldier.selected_clip != "Run_Shoot":
        _fail("Run+Shoot animation does not play: "+soldier.selected_clip)
        return
    soldier.request_dash()
    for i in range(2):
        await physics_frame
    if soldier.selected_clip != "Roll":
        _fail("Dash does not trigger native Roll: "+soldier.selected_clip)
        return
    if soldier.dash_cooldown <= 0:
        _fail("Dash cooldown was not preserved")
        return
    soldier.invulnerability = 0.0
    soldier.take_damage(10)
    if soldier.selected_clip != "HitRecieve":
        _fail("Damage reaction is not skeletal: "+soldier.selected_clip)
        return
    soldier.invulnerability = 0.0
    soldier.take_damage(90)
    if soldier.health != 0 or soldier.selected_clip != "Death":
        _fail("Death animation and zero health mismatch")
        return
    var dist := game.player.global_position.distance_to(game._camera_safe_position())
    if dist >= 10.0:
        _fail("Shoulder camera too far from protagonist: "+str(dist))
        return
    print("VANGUARD GAMEPLAY PASS idle-run-runshoot-roll-hit-death, physics retained, shoulder-camera distance=",dist)
    quit(0)

func _fail(reason: String) -> void:
    printerr("VANGUARD GAMEPLAY FAIL: "+reason)
    quit(1)
