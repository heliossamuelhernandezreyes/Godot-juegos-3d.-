extends SceneTree
## Real viewport proof for new mission, not a fabricated AAA concept.
const SCENE = preload("res://scenes/reactivo_13.tscn")
func _initialize() -> void:
    call_deferred("_shoot")

func _shoot() -> void:
    var world = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    world.player.global_position = Vector3(0, 1, 19)
    for e in get_nodes_in_group("enemies"):
        e.set_physics_process(false)
    for i in range(30):
        await process_frame
    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty():
        printerr("REACTIVO RENDER FAIL empty framebuffer")
        quit(1)
        return
    var path := "res://reactivo-13-render-proof.png"
    var result: Error = image.save_png(path)
    if result != OK:
        printerr("REACTIVO RENDER FAIL cannot save image")
        quit(1)
        return
    print("REACTIVO RENDER PASS %d x %d" % [image.get_width(), image.get_height()])
    quit(0)
