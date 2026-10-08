extends SceneTree
## Device-input contract simulated through real Godot InputEvent streams.
## Headless != hardware validation; checks the exact touch/mouse regression.
const SCENE = preload("res://scenes/reactivo_13.tscn")
func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var world = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    var actor = world.player
    actor.mobile_input_mode = true
    var count_before: int = actor.fire_events
    var touch := InputEventScreenTouch.new()
    touch.index = 2
    touch.position = Vector2(1060, 290)
    touch.pressed = true
    world._input(touch)
    if world.touch_look_id != 2 or actor.wants_to_fire():
        _fail("A right-hand touch is treated as a fire event")
        return
    var move_touch := InputEventScreenTouch.new()
    move_touch.index = 3
    move_touch.position = Vector2(130, 570)
    move_touch.pressed = true
    world._input(move_touch)
    var swipe := InputEventScreenDrag.new()
    swipe.index = 2
    swipe.position = Vector2(1140, 245)
    world._input(swipe)
    if world.camera_yaw >= -0.12 or world.camera_pitch <= 0.02:
        _fail("Camera did not yaw/pitch from the right touch: " + str(world.camera_yaw) + " / " + str(world.camera_pitch))
        return
    if actor.wants_to_fire():
        _fail("Looking around must not shoot")
        return
    var mouse := InputEventMouseButton.new()
    mouse.button_index = MOUSE_BUTTON_LEFT
    mouse.pressed = true
    Input.parse_input_event(mouse)
    await process_frame
    if actor.wants_to_fire() or actor.fire_events != count_before:
        _fail("An emulated touch/mouse press fired the mobile weapon")
        return
    mouse.pressed = false
    Input.parse_input_event(mouse)
    actor.mobile_firing = true
    if not actor.wants_to_fire():
        _fail("Explicit FIRE control cannot shoot")
        return
    actor.mobile_firing = false
    swipe.index = 3
    swipe.position = Vector2(130, 485)
    world._input(swipe)
    for i in range(5):
        await physics_frame
    var expected := Basis(Vector3.UP, world.camera_yaw) * Vector3.FORWARD
    var actual := Vector3(actor.velocity.x, 0, actor.velocity.z).normalized()
    if actual.dot(expected) < 0.82:
        _fail("Movement no longer follows camera heading: actual=" + str(actual) + " expected=" + str(expected))
        return
    touch.pressed = false
    move_touch.pressed = false
    world._input(touch)
    world._input(move_touch)
    if world.touch_look_id != -1 or world.touch_move_id != -1:
        _fail("Touch ownership leaked")
        return
    print("REACTIVO MOBILE CAMERA PASS no-touch-fire=true independent-input=true heading=true")
    quit(0)

func _fail(reason: String) -> void:
    printerr("REACTIVO MOBILE CAMERA FAIL: " + reason)
    quit(1)
