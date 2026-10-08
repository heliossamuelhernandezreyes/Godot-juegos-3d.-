extends SceneTree
## Reactivo-13 actual CharacterBody3D cover and dash regression; authoritative map geometry.
const SCENE = preload("res://scenes/reactivo_13.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var world = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    var actor = world.player
    if actor.cover_zones.size() != 11:
        _fail("Missing authored cover geometry: " + str(actor.cover_zones.size()))
        return
    actor.global_position = Vector3(0, 1, 23)
    if actor.can_take_cover() or actor.request_cover_toggle():
        _fail("Cannot activate cover far from an authored collider")
        return
    actor.global_position = Vector3(-20.82, 1, 0)
    actor.velocity = Vector3.ZERO
    if not actor.can_take_cover() or not actor.request_cover_toggle():
        _fail("Could not enter west face of Node A cover")
        return
    if not actor.in_cover or actor.cover_id != "node_a_cover":
        _fail("Attached to incorrect cover")
        return
    actor.touch_axis = Vector2(-1, 0)
    for i in range(4):
        await physics_frame
    if actor.global_position.x < -21.67 or actor.global_position.x > -20.81:
        _fail("Cover snapping penetrated collider or moved away from wall: " + str(actor.global_position))
        return
    actor.touch_axis = Vector2(0, -1)
    for i in range(8):
        await physics_frame
    if actor.velocity.z > -1.0 or not actor.in_cover:
        _fail("No responsive cover strafe: " + str(actor.velocity))
        return
    if absf(actor.velocity.z) > actor.WALK_SPEED * 0.70:
        _fail("Cover strafe speed budget exceeded")
        return
    actor.request_dash()
    await physics_frame
    if actor.in_cover or actor.dash_remaining <= 0 or actor.dash_cooldown <= 0:
        _fail("Dash must break cover while retaining cooldown")
        return
    actor.touch_axis = Vector2.ZERO
    actor.global_position = Vector3(0, 1, 23)
    if actor.can_take_cover():
        _fail("Cover retained outside authored guide")
        return
    actor.global_position = Vector3(-15.0, 1, 14.0)
    actor.dash_remaining = 0.0
    if not actor.can_take_cover() or not actor.request_cover_toggle() or actor.cover_id != "workshop_crate_-1":
        _fail("Solid world crate is not an eligible cover")
        return
    actor.request_cover_toggle()
    actor.global_position = Vector3(0, 1, 19)
    world.shoulder_side = 1.0
    var right_shoulder: Vector3 = world._camera_position()
    world._swap_shoulder()
    var left_shoulder: Vector3 = world._camera_position()
    if right_shoulder.x < 0.8 or left_shoulder.x > -0.8:
        _fail("Shoulder switching lost the over-shoulder sides: " + str(right_shoulder) + " / " + str(left_shoulder))
        return
    print("REACTIVO COVER MOTION PASS guides=11 near-geometry=true wall-tangent=true dash-break=true shoulder-swap=true")
    quit(0)

func _fail(why: String) -> void:
    printerr("REACTIVO COVER MOTION FAIL: " + why)
    quit(1)
