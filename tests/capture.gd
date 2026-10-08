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
    for i in range(12):
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
