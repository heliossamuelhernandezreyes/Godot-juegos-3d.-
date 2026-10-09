extends SceneTree
## Real, unretouched Godot 4.7.2 viewport captures of four playable mission positions.
## Visual evidence supplements tests; success is not an AAA quality certificate.
const SCENE = preload("res://scenes/reactivo_13.tscn")
const BULWARK = preload("res://scripts/reactivo_bulwark.gd")

func _initialize() -> void:
    call_deferred("_shoot")

func _shoot() -> void:
    var world = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    for e in get_nodes_in_group("enemies"):
        e.set_physics_process(false)
    var shots := [
        {"at":Vector3(0,1,19),"file":"reactivo-13-render-proof.png","label":"insertion"},
        {"at":Vector3(-28,1,10),"file":"reactivo-13-node.png","label":"node A"},
        {"at":Vector3(0,1,-2),"file":"reactivo-13-reactor.png","label":"reactor"}
    ]
    for shot in shots:
        world.player.global_position = shot["at"]
        world.player.velocity = Vector3.ZERO
        for i in range(40):
            await process_frame
        if not _save_frame(str(shot["file"])):
            quit(1)
            return
        print("REACTIVO VIEW CAPTURE",shot["label"], shot["file"])
    # Screenshot evidence of the actual collision-backed cover gameplay state.
    world.player.global_position = Vector3(-20.82, 1.0, 0.0)
    world.player.velocity = Vector3.ZERO
    if not world.player.request_cover_toggle():
        printerr("REACTIVO RENDER FAIL cannot engage authored Node A cover")
        quit(1)
        return
    for i in range(40):
        await process_frame
    if not _save_frame("reactivo-13-cover.png"):
        quit(1)
        return
    print("REACTIVO VIEW CAPTURE cover reactivo-13-cover.png")
    world.player.request_cover_toggle()
    # Capture actual physics-owned vault mid-crossing rather than static mock art.
    world.player.global_position = Vector3(-18.28, 1.0, 14.0)
    world.player.velocity = Vector3.ZERO
    if not world.player.request_cover_toggle() or not world.player.request_vault():
        printerr("REACTIVO RENDER FAIL low obstacle vault not authorized")
        quit(1)
        return
    for i in range(28):
        await physics_frame
    await process_frame
    if not _save_frame("reactivo-13-vault.png"):
        quit(1)
        return
    print("REACTIVO VIEW CAPTURE vault reactivo-13-vault.png")
    for i in range(30):
        await physics_frame
    world.player.global_position = Vector3(-20.82, 1.0, 0.0)
    world.player.velocity = Vector3.ZERO
    var guard := CharacterBody3D.new()
    guard.set_script(BULWARK)
    guard.target = world.player
    guard.director = world
    guard.position = Vector3(2.5, 1.0, -9)
    world.add_child(guard)
    guard.set_physics_process(false)
    guard.look_at(world.player.global_position,Vector3.UP)
    for i in range(20):
        await process_frame
    if not _save_frame("reactivo-13-bulwark.png"):
        quit(1)
        return
    print("REACTIVO RENDER PASS viewport series=6")
    quit(0)

func _save_frame(filename: String) -> bool:
    var frame: Image = root.get_texture().get_image()
    if frame == null or frame.is_empty() or frame.get_width() < 700:
        printerr("REACTIVO RENDER FAIL empty or wrong framebuffer")
        return false
    var result: Error = frame.save_png("res://" + filename)
    if result != OK:
        printerr("REACTIVO RENDER FAIL unable to save "+filename)
        return false
    print("REACTIVO VIEW PASS", filename,frame.get_width(),"x",frame.get_height())
    return true
