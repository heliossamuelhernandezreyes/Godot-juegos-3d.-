extends SceneTree
## ARCONT P2 same-build comparison: map-owned cover original blocks OFF vs modular PBR ON; all other art constant.
## Camera, HUD, character, mission phase, renderer and all lights are identical.
## No image compositing or color edits. Two raw images from Godot viewport.
const SCENE: PackedScene = preload("res://scenes/reactivo_13.tscn")
const BEFORE_PATH := "res://reactivo-13-materials-node-baseline.png"
const AFTER_PATH := "res://reactivo-13-materials-node-textured.png"
const PAIR_META := "res://reactivo-13-materials-node-camera-pair.json"

func _initialize() -> void:
    call_deferred("_run_capture")

func _run_capture() -> void:
    var world: Node3D = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    if world.cinematic_stage == null or world.material_pass == null or world.camera == null:
        _fail("missing native scene pilot/camera")
        return
    world.player.global_position = Vector3(-32.0, 1.0, 14.0)
    world.player.velocity = Vector3.ZERO
    world.camera_yaw = 0.0
    world.camera_pitch = 0.0
    for e in get_nodes_in_group("enemies"):
        e.set_physics_process(false)
    for _frame in range(8):
        await physics_frame
    # Freeze ALL gameplay and movement. Comparison switches exactly ONE visible
    # render-only subtree, not the camera, world lights, runtime or objective state.
    world.set_process(false)
    world.set_physics_process(false)
    world.player.set_process(false)
    world.player.set_physics_process(false)
    world.cinematic_stage.set_process(false)
    world.camera.global_position = world._camera_position()
    world.camera.look_at(world._camera_target(), Vector3.UP)
    var camera: Camera3D = world.camera
    var matched_pose: Dictionary = _camera_pose(camera)
    var source_sha: String = FileAccess.get_sha256("res://scenes/reactivo_13.tscn")
    var commit: String = OS.get_environment("GITHUB_SHA").to_lower()
    if commit.length() != 40 or not commit.is_valid_hex_number():
        _fail("missing source commit metadata")
        return
    world.material_pass.set_material_upgrade_enabled(false)
    for _step in range(8):
        await process_frame
    if not _save_frame(BEFORE_PATH):
        return
    var before_pose: Dictionary = _camera_pose(camera)
    world.material_pass.set_material_upgrade_enabled(true)
    for _step in range(8):
        await process_frame
    if not _save_frame(AFTER_PATH):
        return
    var after_pose: Dictionary = _camera_pose(camera)
    if matched_pose != before_pose or matched_pose != after_pose:
        _fail("camera moved or FOV changed while taking matched viewport captures")
        return
    var img: Image = root.get_texture().get_image()
    var meta := {
        "protocol": "fisura-visual-paired-capture", "version": 1,
        "source_commit": commit,
        "scene_path": "scenes/reactivo_13.tscn",
        "scene_sha256": source_sha,
        "engine": str(Engine.get_version_info().get("string","unknown")),
        "renderer": str(ProjectSettings.get_setting("rendering/renderer/rendering_method","unknown")),
        "resolution": [img.get_width(),img.get_height()],
        "camera": matched_pose,
        "player_world_position": [-32.0,1.0,14.0],
        "mission_state": "insertion mission idle, world processes frozen",
        "fixture": "Actual Poly Haven PBR metal/concrete + tinted technical glass at node; original collision unchanged",
        "toggle_flag": "surface_materials_visible",
        "baseline": {"filename":"reactivo-13-materials-node-baseline.png",
                     "surface_materials_visible":false,"sha256":FileAccess.get_sha256(BEFORE_PATH)},
        "candidate": {"filename":"reactivo-13-materials-node-textured.png",
                      "surface_materials_visible":true,"sha256":FileAccess.get_sha256(AFTER_PATH)},
        "claim": "same-build scene-generated untextured primitives vs real metal/concrete texture and technical glass from node",
        "quality_review": "human_review_required",
        "device_performance": "not_measured"
    }
    var output := FileAccess.open(PAIR_META, FileAccess.WRITE)
    if output == null:
        _fail("unable to store camera comparison metadata")
        return
    output.store_string(JSON.stringify(meta,"\t") + "\n")
    output.close()
    print("REACTIVO SURFACE MATERIAL CAMERA PAIR PASS matched_pose=true resolution=%dx%d baseline_sha=%s candidate_sha=%s" %
        [img.get_width(),img.get_height(),meta["baseline"]["sha256"],meta["candidate"]["sha256"]])
    quit(0)

func _camera_pose(camera: Camera3D) -> Dictionary:
    var t: Transform3D = camera.global_transform
    return {
        "origin": _vec(t.origin), "basis_x":_vec(t.basis.x),
        "basis_y":_vec(t.basis.y), "basis_z":_vec(t.basis.z),
        "fov": camera.fov,
        "near": camera.near,
        "far": camera.far,
        "projection": camera.projection
    }

func _vec(v: Vector3) -> Array[float]:
    return [v.x, v.y, v.z]

func _save_frame(path: String) -> bool:
    var frame: Image = root.get_texture().get_image()
    if frame == null or frame.is_empty() or frame.get_width() < 1200 or frame.get_height() < 700:
        _fail("invalid viewport contents")
        return false
    var error: Error = frame.save_png(path)
    if error != OK:
        _fail("could not save Godot framebuffer image")
        return false
    return true

func _fail(reason: String) -> void:
    printerr("REACTIVO SURFACE MATERIAL CAMERA PAIR FAIL ", reason)
    quit(1)
