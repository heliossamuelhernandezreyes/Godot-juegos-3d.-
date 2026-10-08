extends SceneTree
## In-engine visual-regression set: staged camera locations, NOT simulated user playtime.
const SCENE = preload("res://scenes/reactivo_13.tscn")
func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var world = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    for enemy in get_nodes_in_group("enemies"):
        enemy.set_physics_process(false)
    for view in [
        {"id":"insertion", "position":Vector3(0,1,23)},
        {"id":"node-a","position":Vector3(-28,1,11)},
        {"id":"reactor","position":Vector3(0,1,-3)},
        {"id":"extraction","position":Vector3(0,1,-25)},
        {"id":"bulwark","position":Vector3(6,1,-3)}
    ]:
        world.player.global_position = view["position"]
        if view["id"] == "bulwark":
            var guard := CharacterBody3D.new()
            guard.set_script(load("res://scripts/reactivo_bulwark.gd"))
            guard.target = world.player
            guard.director = world
            guard.position = Vector3(6,1,-11)
            world.add_child(guard)
            guard.set_physics_process(false)
        world.player.touch_axis = Vector2.ZERO
        world.player.set_physics_process(false)
        for _f in range(22):
            await process_frame
        var image: Image = root.get_texture().get_image()
        if image == null or image.is_empty():
            printerr("REACTIVO VISUAL SUITE FAIL: empty frame ",view["id"])
            quit(1)
            return
        var file_name := "reactivo-13-" + str(view["id"]) + ".png"
        if image.save_png("res://" + file_name) != OK:
            printerr("REACTIVO VISUAL SUITE FAIL: save ",file_name)
            quit(1)
            return
        print("REACTIVO VISUAL FRAME PASS ",view["id"]," ",image.get_width(),"x",image.get_height())
    print("REACTIVO VISUAL SUITE PASS frames=5; inspect visually before merging")
    quit(0)
