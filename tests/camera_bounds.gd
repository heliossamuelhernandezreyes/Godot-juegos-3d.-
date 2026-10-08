extends SceneTree
## ARCONT visual obstruction regression: camera must remain inside closed map shell.

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    if scene == null:
        printerr("CAMERA FAIL: scene load")
        quit(1)
        return
    var game = scene.instantiate()
    root.add_child(game)
    var width := float(game.map_data["bounds"]["width"]) * 0.5
    var depth := float(game.map_data["bounds"]["depth"]) * 0.5
    for point in [Vector3(0, 1, 15),Vector3(0, 1, 20),Vector3(0, 1, -20),
                  Vector3(20, 1, 0),Vector3(-20, 1, 0)]:
        game.player.global_position = point
        var goal: Vector3 = game._camera_safe_position()
        if absf(goal.x) >= width - 2.0 or absf(goal.z) >= depth - 2.0:
            printerr("CAMERA FAIL behind wall player=",point," camera=",goal)
            quit(1)
            return
    print("CAMERA OCCLUSION PASS: five edge spawns keep camera inside walls")
    quit(0)
