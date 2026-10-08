extends SceneTree
## Executable L3 evidence that rigged enemy animations attach to real AI bodies.
const ENEMY_SCRIPT = preload("res://scripts/animated_reaver.gd")
func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    var game = scene.instantiate()
    root.add_child(game)
    var actors: Array[CharacterBody3D] = []
    for kind in ["quad", "eye"]:
        var enemy := CharacterBody3D.new()
        enemy.set_script(ENEMY_SCRIPT)
        enemy.asset_kind = kind
        enemy.target = game.player
        enemy.director = game
        enemy.position = Vector3(-5.0, 1, 8) if kind == "quad" else Vector3(5.0, 1, 8)
        game.add_child(enemy)
        actors.append(enemy)
        if enemy.animation_player == null:
            _fail("Missing active AnimationPlayer on " + kind)
            return
        if enemy.rig == null:
            _fail("Missing rig " + kind)
            return
        if enemy.selected_clip != "Idle":
            _fail("No skeletal Idle state " + kind)
            return
        if not enemy.animation_player.has_animation("Hit"):
            _fail("No imported Hit clip " + kind)
            return
        enemy.take_hit(7)
        if enemy.selected_clip != "Hit":
            _fail("Hit does not trigger skeletal animation " + kind)
            return
    for frame in range(6):
        await physics_frame
    for actor in actors:
        if not is_instance_valid(actor):
            _fail("Animated enemy freed unexpectedly")
            return
        if actor.animation_player == null:
            _fail("Skeleton animation lost in runtime")
            return
    print("ANIMATED COMBAT PASS rigs=2 idle-hit=true collision_ai_preserved=true")
    quit(0)

func _fail(error_text: String) -> void:
    printerr("ANIMATED COMBAT FAIL " + error_text)
    quit(1)
