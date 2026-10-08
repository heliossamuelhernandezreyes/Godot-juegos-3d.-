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
    if actor.cover_zones.size() != 7:
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
    if absf(actor.velocity.x) > 0.20:
        _fail("Cover movement penetrates the wall: " + str(actor.velocity))
        return
    actor.touch_axis = Vector2(0, -1)
    for i in range(8):
        await physics_frame
    if actor.velocity.z > -1.0 or not actor.in_cover:
        _fail("No responsive cover strafe: " + str(actor.velocity))
        return
    if actor.velocity.length() > actor.WALK_SPEED * 0.70:
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
    print("REACTIVO COVER MOTION PASS guides=7 near-geometry=true wall-tangent=true dash-break=true")
    quit(0)

func _fail(why: String) -> void:
    printerr("REACTIVO COVER MOTION FAIL: " + why)
    quit(1)
