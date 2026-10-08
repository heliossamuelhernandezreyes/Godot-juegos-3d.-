extends SceneTree
## Exercise TouchScreenButton events independently with native Godot input dispatch.
const SCENE = preload("res://scenes/reactivo_13.tscn")
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game = SCENE.instantiate()
    root.add_child(game)
    var ui: Control
    for layer in game.get_children():
        if layer is CanvasLayer:
            for child in layer.get_children():
                if child is Control:
                    ui = child
                    break
    if ui == null:
        _fail("Missing HUD CanvasLayer root")
        return
    var fire: TouchScreenButton = game._touch_action(ui, "PRUEBA_FUEGO", -245, -25, -180, -112)
    var cover: TouchScreenButton = game._touch_action(ui, "PRUEBA_CUBRIR", -465, -285, -180, -112)
    if not (fire is TouchScreenButton and cover is TouchScreenButton):
        _fail("Gameplay controls are generic mouse-only GUI buttons")
        return
    if fire.shape == null or cover.shape == null:
        _fail("Finger hitboxes missing")
        return
    var fired := [0]
    var covered := [0]
    fire.pressed.connect(func() -> void: fired[0] += 1)
    cover.pressed.connect(func() -> void: covered[0] += 1)
    # Real InputEventScreenTouch parsing with two independent finger indices.
    var first := InputEventScreenTouch.new()
    first.index = 9
    first.position = Vector2(1150, 580)
    first.pressed = true
    var second := InputEventScreenTouch.new()
    second.index = 10
    second.position = Vector2(890, 580)
    second.pressed = true
    Input.parse_input_event(first)
    Input.parse_input_event(second)
    await process_frame
    if fired[0] != 1 or covered[0] != 1:
        _fail("Two independent held fingers lost gameplay action signals: " + str(fired) + " / " + str(covered))
        return
    first.pressed = false
    second.pressed = false
    Input.parse_input_event(first)
    Input.parse_input_event(second)
    await process_frame
    print("REACTIVO TOUCH BUTTONS PASS independent_held_actions=2")
    quit(0)

func _fail(reason: String) -> void:
    printerr("REACTIVO TOUCH BUTTONS FAIL: " + reason)
    quit(1)
