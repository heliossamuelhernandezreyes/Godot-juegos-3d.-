extends SceneTree
## ARCONT native Godot gate: source-audited bones, pose activation and
## third-person camera/shot-response contracts, NOT subjective animation QA.
const SCENE = preload("res://scenes/reactivo_13.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var world = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    var actor = world.player
    var modifier = actor.aim_modifier
    if modifier == null or not actor.visual_ready:
        _fail("Missing imported Vanguard rig or post-animation modifier")
        return
    if modifier.spine_bones.size() != 3 or modifier.upper_legs.size() != 2 or modifier.lower_legs.size() != 2:
        _fail("Tactical pose did not map the source-audited real bones")
        return

    actor.global_position = Vector3(0, 1, 19)
    world.camera_aim_blend = 0.0
    var walk_camera: Vector3 = world._camera_position()
    world.camera_aim_blend = 1.0
    var aim_camera: Vector3 = world._camera_position()
    if aim_camera.z >= walk_camera.z - 0.45 or aim_camera.y >= walk_camera.y - 0.10:
        _fail("Holding fire does not lower and tighten shoulder framing")
        return
    world.camera_recoil = 0.0
    var stable_aim: Vector3 = world._camera_target()
    world.camera_recoil = 0.32
    var kick_aim: Vector3 = world._camera_target()
    if kick_aim.y <= stable_aim.y or kick_aim.y - stable_aim.y > 0.05:
        _fail("Camera recoil must be noticeable but strictly bounded")
        return
    world.camera_aim_blend = 0.0
    world.camera_recoil = 0.0

    actor.global_position = Vector3(-18.28, 1.0, 14.0)
    actor.velocity = Vector3.ZERO
    if not actor.request_cover_toggle():
        _fail("Source-authored crate cover is not available")
        return
    for i in range(8):
        await physics_frame
    await process_frame
    if modifier.cover_weight < 0.40 or modifier.tactical_frames < 1:
        _fail("Cover did not activate the bone-owned brace pose")
        return
    if absf(actor.visual_root.scale.y - 1.0) > 0.01:
        _fail("Cover is still deforming the entire skinned character")
        return
    var cover_frames: int = modifier.tactical_frames

    if not actor.request_vault():
        _fail("Live physical cover could not start a vault")
        return
    for i in range(25):
        await physics_frame
    await process_frame
    if not actor.vault_active or modifier.vault_phase <= 0.25 or modifier.vault_phase >= 0.90:
        _fail("Physics-owned vault failed to update the tactical animation phase")
        return
    if modifier.tactical_frames <= cover_frames:
        _fail("Live SkeletonModifier did not process the airborne limb-tuck")
        return
    if actor.collision_layer != 1 or actor.collision_mask != 1:
        _fail("Animated pose must not change the authoritative collider")
        return
    print("REACTIVO TACTICAL ANIMATION CAMERA PASS torso=3 legs=4 bone_pose=true vault_phase=true camera_aim=true recoil_bound=true")
    quit(0)

func _fail(reason: String) -> void:
    printerr("REACTIVO TACTICAL ANIMATION CAMERA FAIL: " + reason)
    quit(1)
