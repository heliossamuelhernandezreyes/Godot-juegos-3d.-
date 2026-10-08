extends SceneTree
## ARCONT-inspired geometric asset integrity test.
const ASSETS = [
    "res://assets/models/vanguard_body.obj",
    "res://assets/models/vanguard_arm.obj",
    "res://assets/models/vanguard_leg.obj",
    "res://assets/models/vanguard_rifle.obj",
    "res://assets/models/reaver_sentry.obj",
    "res://assets/models/sentinel_pillar.obj",
    "res://assets/models/armored_crate.obj",
    "res://assets/models/extraction_gate.obj",
    "res://assets/models/reactor_altar.obj",
    "res://assets/models/armature_floor.obj"
]
func _initialize() -> void:
    call_deferred("_check")

func _check() -> void:
    var triangle_total := 0
    var material_total := 0
    for path in ASSETS:
        var mesh: Mesh = load(path)
        if mesh == null or mesh.get_surface_count() == 0:
            printerr("ASSET FAIL: model import " + path)
            quit(1)
            return
        var triangles := 0
        for surface_id in range(mesh.get_surface_count()):
            var primitive: int = mesh.surface_get_primitive_type(surface_id)
            if primitive != Mesh.PRIMITIVE_TRIANGLES:
                printerr("ASSET FAIL: expected triangular surface " + path)
                quit(1)
                return
            triangles += mesh.surface_get_array_index_len(surface_id) / 3
            if mesh.surface_get_material(surface_id) != null:
                material_total += 1
        triangle_total += triangles
        print("MODEL PASS %s surfaces=%d triangles=%d" % [path, mesh.get_surface_count(), triangles])
    if triangle_total <= 0:
        printerr("ASSET FAIL: empty geometry")
        quit(1)
        return
    print("ASSET INTEGRITY PASS models=%d triangles=%d material_surfaces=%d" % [ASSETS.size(), triangle_total, material_total])
    quit(0)
