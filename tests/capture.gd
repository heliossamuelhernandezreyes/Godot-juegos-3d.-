extends SceneTree
## Capture a real rendered game frame for visual QA, never a mockup.
func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    if scene == null:
        printerr("RENDER FAIL: cannot load main scene")
        quit(1)
        return
    var world = scene.instantiate()
    root.add_child(world)
    # Real gameplay proof, with both skinned enemy roles inside camera framing.
    world.player.global_position = Vector3(0, 1, 12.0)
    var enemy_script = load("res://scripts/animated_reaver.gd")
    for variant in ["quad", "eye"]:
        var actor := CharacterBody3D.new()
        actor.set_script(enemy_script)
        actor.asset_kind = variant
        actor.target = world.player
        actor.director = world
        actor.global_position = Vector3(-4.2, 1.0, 6.5) if variant == "quad" else Vector3(4.2, 1.0, 6.5)
        world.add_child(actor)
    for i in range(25):
        await process_frame
    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty():
        printerr("RENDER FAIL: empty viewport texture")
        quit(1)
        return
    var target := "res://fisura-render-proof.png"
    var error: Error = image.save_png(target)
    if error != OK:
        printerr("RENDER FAIL: cannot save screenshot %s error %d" % [target, error])
        quit(1)
        return
    print("RENDER PROOF PASS %d x %d %s" % [image.get_width(), image.get_height(), target])
    quit(0)
