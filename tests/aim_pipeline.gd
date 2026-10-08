extends SceneTree
## ARCONT ANIM-002/004: real post-clip skeleton modifier + ballistic trajectory.
func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    var game = scene.instantiate()
    root.add_child(game)
    var hero = game.player
    for i in range(5):
        await physics_frame
    if hero.aim_layer == null or not hero.aim_layer is SkeletonModifier3D:
        _fail("No SkeletonModifier3D attached to Vanguard")
        return
    var screen := game.get_viewport().get_visible_rect().size
    var touch_move := InputEventScreenTouch.new()
    touch_move.index = 1
    touch_move.pressed = true
    touch_move.position = Vector2(screen.x * 0.2, screen.y * 0.80)
    game._input(touch_move)
    var touch_aim := InputEventScreenTouch.new()
    touch_aim.index = 2
    touch_aim.pressed = true
    touch_aim.position = Vector2(screen.x * 0.75, screen.y * 0.42)
    game._input(touch_aim)
    if game.move_touch_id != 1 or game.aim_touch_id != 2:
        _fail("Cannot track move and aim touch fingers independently")
        return
    game._update_aim()
    var before: Vector3 = hero.fire_direction
    if absf(before.length() - 1.0) > 0.02:
        _fail("Ballistic trajectory is not normalized")
        return
    var drag := InputEventScreenDrag.new()
    drag.index = 2
    drag.position = Vector2(screen.x * 0.87, screen.y * 0.28)
    game._input(drag)
    game._update_aim()
    if not game.manual_aim_active or game.aim_screen.distance_to(drag.position) > 0.01:
        _fail("Right touch aiming did not move crosshair")
        return
    var difference: float = before.distance_to(hero.fire_direction)
    if difference < 0.005:
        _fail("Aiming reticle did not affect 3D fire trajectory")
        return
    hero.on_weapon_fired()
    if hero.aim_layer.recoil <= 0.01 or hero.fire_events < 1:
        _fail("Shot failed to actuate additive aim recoil")
        return
    hero.aim_layer.configure_aim(1.0, -1.0)
    if absf(hero.aim_layer.target_pitch - 0.30) > 0.001 or absf(hero.aim_layer.target_yaw + 0.25) > 0.001:
        _fail("Post-animation bone-aim range is not clamped")
        return
    touch_aim.pressed = false
    game._input(touch_aim)
    touch_move.pressed = false
    game._input(touch_move)
    if game.aim_touch_id != -1 or game.move_touch_id != -1:
        _fail("Multitouch fingers not released")
        return
    print("ARCONT AIM PASS multitouch=2 modifier=true recoil=true 3d_aim_delta=", difference)
    quit(0)

func _fail(reason: String) -> void:
    printerr("ARCONT AIM FAIL: " + reason)
    quit(1)
