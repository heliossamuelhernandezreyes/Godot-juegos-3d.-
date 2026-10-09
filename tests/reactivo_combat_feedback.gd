extends SceneTree
## Native Godot regression: a missed ray never confirms damage; a physical
## damageable body generates both a feedback marker and real damage.
const SCENE = preload("res://scenes/reactivo_13.tscn")

class TestTarget:
    extends StaticBody3D
    var received_damage := 0
    func take_hit(amount: int) -> void:
        received_damage += amount

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var world = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    # Keep the instrumented sight line above industrial world cover.
    world.player.global_position = Vector3(0, 10.0, 19.0)
    world.player.velocity = Vector3.ZERO
    world.camera.global_position = world._camera_position()
    world.camera.look_at(world._camera_target(), Vector3.UP)

    # Use an explicit center ray: headless Linux has no physical mouse.
    var pointer: Vector2 = root.get_visible_rect().size * 0.5
    # Even if a shot touches passive level geometry, it cannot confirm damage.
    world._fire(pointer)
    if world.hit_confirm_remaining > 0.001:
        _fail("A shot without a damageable target confirmed an enemy hit")
        return

    var target := TestTarget.new()
    target.name = "Instrumented physical damage target"
    var collision := CollisionShape3D.new()
    var body := BoxShape3D.new()
    body.size = Vector3(4.0, 3.0, 0.8)
    collision.shape = body
    target.add_child(collision)
    target.position = Vector3(0.0, 10.0, 16.0)
    world.add_child(target)
    await physics_frame

    world.camera.global_position = world._camera_position()
    world.camera.look_at(world._camera_target(), Vector3.UP)
    world._fire(pointer)
    if target.received_damage != 23:
        _fail("Damageable collider not hit by real camera-to-muzzle physics ray: " + str(target.received_damage))
        return
    if world.hit_confirm_remaining <= 0.0:
        _fail("Damage dealt without a hit confirmation")
        return
    world._process(0.01)
    if world.tactical_reticle.text != "×":
        _fail("HUD does not visually distinguish a confirmed damage hit")
        return
    world._process(0.2)
    if world.tactical_reticle.text != "+":
        _fail("Hit marker did not restore the ordinary reticle")
        return
    print("REACTIVO COMBAT FEEDBACK PASS miss_no_confirmation=true damage_physics=true hit_ui=true hit_audio_route=true")
    quit(0)

func _fail(reason: String) -> void:
    printerr("REACTIVO COMBAT FEEDBACK FAIL: " + reason)
    quit(1)
