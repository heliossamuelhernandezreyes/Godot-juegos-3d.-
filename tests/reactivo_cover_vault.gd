extends SceneTree
## ARCONT Godot-native collision/animation gate: actual crate vault in live map.
## Runtime physics is authoritative; no body teleport through a cover collider.
const SCENE = preload("res://scenes/reactivo_13.tscn")
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var world = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    var actor = world.player
    actor.global_position = Vector3(-20.82, 1.0, 0.0)
    if not actor.request_cover_toggle() or actor.can_vault():
        _fail("Tall Node A cover must never be vaulted")
        return
    actor.request_cover_toggle()
    actor.global_position = Vector3(-18.28, 1.0, 14.0)
    actor.velocity = Vector3.ZERO
    if not actor.request_cover_toggle():
        _fail("Missing real low crate cover")
        return
    if actor.cover_id != "workshop_crate_-1" or not actor.can_vault():
        _fail("Only collision-backed low obstacles can vault: "+actor.cover_id)
        return
    var entry: Vector3 = actor.global_position
    if not actor.request_vault() or not actor.vault_active or actor.in_cover:
        _fail("Vault must leave cover and start a true transition")
        return
    for i in range(75):
        await physics_frame
    if actor.vault_active or actor.vault_completed != 1:
        _fail("Timed vault did not complete: "+str(actor.vault_elapsed))
        return
    if actor.global_position.x < -16.2 or absf(actor.global_position.z - entry.z) > 1.0:
        _fail("Vault did not clear physical crate to far side: "+str(actor.global_position))
        return
    if actor.global_position.y < 0.7 or actor.global_position.y > 1.35:
        _fail("Vault landing is below ground or airborne: "+str(actor.global_position.y))
        return
    if actor.vault_active or actor.in_cover:
        _fail("Stale movement state on landing")
        return
    # Regression: a new obstacle can appear after the initial route sweep.
    # Place a 0.3m landing pad near the end of descent, not at the start.
    # The last frames must cancel instead of counting a phantom landing.
    actor.global_position = Vector3(-18.28, 1.0, 14.0)
    actor.velocity = Vector3.ZERO
    if not actor.request_cover_toggle() or not actor.request_vault():
        _fail("Unable to start second low-cover vault for late-collision test")
        return
    for i in range(41):
        await physics_frame
    if not actor.vault_active:
        _fail("Second vault ended before the late-collision setup")
        return
    var landing_pad := StaticBody3D.new()
    landing_pad.name = "Late-arriving landing obstruction"
    var pad_collider := CollisionShape3D.new()
    var pad_box := BoxShape3D.new()
    pad_box.size = Vector3(2.0, 0.30, 2.0)
    pad_collider.shape = pad_box
    landing_pad.add_child(pad_collider)
    landing_pad.position = Vector3(actor.vault_to.x, 0.05, actor.vault_to.z)
    world.add_child(landing_pad)
    for i in range(16):
        await physics_frame
    if actor.vault_active or actor.vault_completed != 1:
        _fail("Late landing obstruction incorrectly completed a vault")
        return
    if actor.vault_elapsed < actor.VAULT_TIME * 0.95:
        _fail("Late collision scenario did not reach the final landing window")
        return
    print("REACTIVO LOW COVER VAULT PASS actual-collider=true height-gate=true swept-crossing=true landing=true late-obstruction-cancels=true")
    quit(0)

func _fail(reason: String) -> void:
    printerr("REACTIVO LOW COVER VAULT FAIL: " + reason)
    quit(1)
