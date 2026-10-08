extends SceneTree
## ARCONT ANIM-004: regression for post-clip aim/recoil and multi-touch isolation.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    if scene == null:
        _fail("cannot load main")
        return
    var game = scene.instantiate()
    root.add_child(game)
    var actor = game.player
    if actor.aim_modifier == null or actor.humanoid_skeleton == null:
        _fail("missing torso modifier")
        return
    if actor.aim_modifier.get_skeleton() != actor.humanoid_skeleton:
        _fail("modifier not parented to Skeleton3D")
        return
    if actor.aim_modifier.spine_bones.is_empty():
        _fail("No real torso bone mapped; cannot apply correction")
        return
    var first := InputEventScreenTouch.new()
    first.index = 3
    first.position = Vector2(160, 580)
    first.pressed = true
    game._input(first)
    var second := InputEventScreenTouch.new()
    second.index = 7
    second.position = Vector2(960, 365)
    second.pressed = true
    game._input(second)
    var drag_move := InputEventScreenDrag.new()
    drag_move.index = 3
    drag_move.position = Vector2(220, 500)
    game._input(drag_move)
    var drag_look := InputEventScreenDrag.new()
    drag_look.index = 7
    drag_look.position = Vector2(1030, 300)
    game._input(drag_look)
    if actor.touch_axis.length_squared() < 0.05 or game.look_touch_axis.length_squared() < 0.05:
        _fail("multitouch axes not independent")
        return
    game._update_aim()
    if actor.aim_direction.length_squared() < 0.6 or actor.aim_pitch == 0.0:
        _fail("touch look did not orient torso")
        return
    actor.mobile_firing = true
    actor.on_weapon_fired()
    if actor.aim_modifier.recoil < 0.9:
        _fail("weapon did not drive post-animation recoil")
        return
    for i in range(5):
        await physics_frame
        await process_frame
    if actor.aim_modifier.applied_frames < 1:
        _fail("SkeletonModifier was not processed after native animation")
        return
    first.pressed = false
    second.pressed = false
    game._input(first)
    game._input(second)
    if actor.touch_axis.length_squared() > 0.001 or game.look_touch_axis.length_squared() > 0.001:
        _fail("touch was not released")
        return
    print("VANGUARD AIM PASS torso_bones=%d processed=%d independent_touch=true recoil=true" %
        [actor.aim_modifier.spine_bones.size(), actor.aim_modifier.applied_frames])
    quit(0)

func _fail(reason: String) -> void:
    printerr("VANGUARD AIM FAIL: "+reason)
    quit(1)
