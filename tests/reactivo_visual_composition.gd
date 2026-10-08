extends SceneTree
## ARCONT visual-shot QA: validate in-engine composition, not only screen PNG integrity.
## Static camera + UI assertions cannot replace human screenshot review or Android profiling.
const SCENE = preload("res://scenes/reactivo_13.tscn")
func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var world = SCENE.instantiate()
    root.add_child(world)
    if world.camera == null or world.player == null or world.cinematic_stage == null:
        _fail("Missing live camera, actor, or cinematic art stage")
        return
    # The insertion spawn is close to a perimeter wall; test an open-lane shot, while
    # retaining the runtime wall-clamping rule for real gameplay.
    world.player.global_position = Vector3(0.0, 1.0, 19.0)
    world.camera.global_position = world._camera_position()
    var camera_offset: Vector3 = world.camera.global_position - world.player.global_position
    if camera_offset.z < 3.8 or camera_offset.z > 4.7:
        _fail("Third-person camera must keep a legible player silhouette: " + str(camera_offset))
        return
    if camera_offset.x < 0.8 or camera_offset.x > 1.4:
        _fail("Over-shoulder framing was lost: " + str(camera_offset))
        return
    if world.camera.fov > 63.0:
        _fail("Excessive wide FOV reduces character readability")
        return
    # Photo evidence caught a previous regression with the actor's legs off-screen.
    # Evaluate an open-lane camera projection, not merely FOV and 3D distance.
    world.camera.look_at(world._camera_target(), Vector3.UP)
    var frame_height: float = root.get_visible_rect().size.y
    var foot: Vector2 = world.camera.unproject_position(world.player.global_position + Vector3(0, -0.87, 0))
    var head: Vector2 = world.camera.unproject_position(world.player.global_position + Vector3(0, 0.93, 0))
    if foot.y > frame_height * 0.93 or head.y < frame_height * 0.10:
        _fail("Player silhouette is cropped: head=" + str(head) + " feet=" + str(foot))
        return
    if foot.y - head.y < frame_height * 0.19:
        _fail("Player silhouette too small for 3rd-person readability")
        return
    if camera_offset.y > 1.8:
        _fail("Third-person camera is too high (near top-down): " + str(camera_offset))
        return
    if world.tactical_reticle == null or world.tactical_reticle.text != "+":
        _fail("Aim position has no HUD affordance")
        return
    var hud_panel: ColorRect
    for layer in world.get_children():
        if layer is CanvasLayer:
            for control in layer.get_children():
                for widget in control.get_children():
                    if widget is ColorRect and widget.size.x > 400.0 and widget.size.y > 60.0:
                        hud_panel = widget
                        break
    if hud_panel == null or hud_panel.size.x > 620.0 or hud_panel.size.y > 130.0:
        _fail("Mission HUD occludes too much of the view")
        return
    var real_asset_count := 0
    for child in world.cinematic_stage.get_children():
        if child.name.begins_with("Poly Haven CC0 |"):
            real_asset_count += 1
        if child is CollisionObject3D:
            _fail("A presentation prop is incorrectly authoritative for physics")
            return
    if real_asset_count < 6:
        _fail("Photogrammetry props are not present in the playable scene: " + str(real_asset_count))
        return
    print("REACTIVO VISUAL COMPOSITION PASS camera=",camera_offset,
        " fov=",world.camera.fov," hud=",hud_panel.size," vendor_props=",real_asset_count)
    quit(0)

func _fail(reason: String) -> void:
    printerr("REACTIVO VISUAL COMPOSITION FAIL: " + reason)
    quit(1)
