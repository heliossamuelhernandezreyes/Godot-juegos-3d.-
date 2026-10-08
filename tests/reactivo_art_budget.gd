extends SceneTree
## ARCONT stage-authoring budget: visual nodes must not modify semantic navigation.
const SCENE = preload("res://scenes/reactivo_13.tscn")
func _initialize() -> void:
    call_deferred("_verify")
func _verify() -> void:
    var world = SCENE.instantiate()
    root.add_child(world)
    var stage: Node3D
    for n in world.get_children():
        if n.name == "REACTIVO-13 | cinematic industrial dressing":
            stage = n
            break
    if stage == null:
        _fail("New cinematic stage is not instanced by live scene")
        return
    if stage.draw_nodes < 80 or stage.draw_nodes > 420:
        _fail("Visual geometry budget: "+str(stage.draw_nodes))
        return
    var lights := 0
    for item in stage.get_children():
        if item is CollisionObject3D or item is CollisionShape3D:
            _fail("Art-only node created an unvalidated gameplay collider")
            return
        if item is Light3D:
            lights += 1
            if item.shadow_enabled:
                _fail("Cinematic accessory light casts unbudgeted realtime shadow")
                return
    if lights > 7 or lights < 4:
        _fail("Excess/missing visual lights: "+str(lights))
        return
    print("REACTIVO ART BUDGET PASS geometry=%d lights=%d collision-free=true" % [stage.draw_nodes,lights])
    quit(0)
func _fail(reason: String) -> void:
    printerr("REACTIVO ART BUDGET FAIL: "+reason)
    quit(1)
