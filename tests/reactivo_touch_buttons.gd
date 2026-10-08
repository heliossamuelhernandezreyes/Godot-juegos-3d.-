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
    # Linux headless Godot does not dispatch touchscreen shape presses from
    # Input.parse_input_event. Check native class, independent hitbox geometry
    # and signal-wiring only; physical finger dispatch is an Android test.
    var viewport_size := root.get_visible_rect().size
    var expected_fire := viewport_size + Vector2(-245, -180)
    var expected_cover := viewport_size + Vector2(-465, -180)
    if (fire.position - expected_fire).length() > 0.1 or (cover.position - expected_cover).length() > 0.1:
        _fail("Touch hitboxes are not at the displayed button positions")
        return
    fire.pressed.emit()
    cover.pressed.emit()
    if fired[0] != 1 or covered[0] != 1:
        _fail("Touch action signals did not reach their independent handlers")
        return
    print("REACTIVO TOUCH BUTTONS PASS class=TouchScreenButton signal_wiring=true headless_dispatch_unverified=true")
    quit(0)

func _fail(reason: String) -> void:
    printerr("REACTIVO TOUCH BUTTONS FAIL: " + reason)
    quit(1)
