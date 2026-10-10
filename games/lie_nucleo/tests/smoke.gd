extends SceneTree
## Mandatory Linux software Vulkan smoke + gameplay progression + screenshot.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene=load("res://scenes/main.tscn") as PackedScene
    if scene==null:
        _fail("missing entry scene")
        return
    var game: Node3D=scene.instantiate() as Node3D
    if game==null:
        _fail("game scene invalid")
        return
    root.add_child(game)
    for n in range(35):
        await process_frame
    var effect: CompositorEffect=game.get("lie_effect")
    if effect==null or not bool(effect.get("gpu_ready")):
        _fail("LIE is not connected to main global GPU compositor")
        return
    if int(effect.get("frame_count")) < 3:
        _fail("GPU pipeline did not execute frames")
        return
    var screenshot: Image=root.get_texture().get_image()
    if screenshot==null or screenshot.is_empty():
        _fail("No Vulkan game framebuffer")
        return
    var out: String=ProjectSettings.globalize_path("res://lie-nucleo-smoke.png")
    if screenshot.save_png(out)!=OK:
        _fail("Could not preserve game screenshot")
        return
    var game_player: CharacterBody3D=game.get("player")
    var targets: Array=game.get("beacons")
    if targets.size()!=3:
        _fail("Expected three collectible modules")
        return
    for pickup in targets.duplicate():
        if is_instance_valid(pickup):
            game_player.global_position=pickup.global_position
            game.call("_check_pickups")
    if int(game.get("collected"))!=3:
        _fail("Collectibles cannot be collected")
        return
    var extraction: Node3D=game.get("gate")
    game_player.global_position=extraction.global_position
    game.call("_check_pickups")
    if not bool(game.get("won")):
        _fail("Extraction after three modules must win")
        return
    print("LIE-NUCLEO GAME PASS actual_vulkan=true frame_count=",effect.get("frame_count"),
        " pickups=3 extraction=true screenshot=true")
    game.queue_free()
    for n in range(5):
        await process_frame
    quit(0)

func _fail(message: String) -> void:
    printerr("LIE-NUCLEO GAME FAIL: ",message)
    quit(1)
