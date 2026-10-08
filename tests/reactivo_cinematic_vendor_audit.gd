extends SceneTree
## Source-licensed Poly Haven cinematic models must load with texture dependencies.
const CART = preload("res://assets/vendor/polyhaven_cinematic/industrial_storage_cart/industrial_storage_cart_1k.gltf")
const CONTAINER = preload("res://assets/vendor/polyhaven_cinematic/industrial_pastic_container/industrial_pastic_container_1k.gltf")
func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    for entry in [{"name":"industrial_storage_cart","packed":CART},{"name":"industrial_pastic_container","packed":CONTAINER}]:
        var model: PackedScene = entry["packed"]
        if model == null:
            _fail("Missing source glTF " + str(entry["name"]))
            return
        var root_node := model.instantiate()
        root.add_child(root_node)
        var counts := {"mesh":0,"surfaces":0}
        _scan(root_node,counts)
        if counts.mesh < 1 or counts.surfaces < 1:
            _fail("Missing rendered geometry "+str(entry["name"]))
            return
        print("CINEMATIC PBR IMPORT",entry["name"],counts)
        root_node.queue_free()
    print("CINEMATIC PBR IMPORT PASS assets=2")
    quit(0)

func _scan(node: Node, count: Dictionary) -> void:
    if node is MeshInstance3D and node.mesh != null:
        count.mesh += 1
        count.surfaces += node.mesh.get_surface_count()
    for child in node.get_children():
        _scan(child,count)

func _fail(reason: String) -> void:
    printerr("CINEMATIC PBR IMPORT FAIL: " + reason)
    quit(1)
