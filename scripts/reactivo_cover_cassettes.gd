extends Node3D
## FISURA 0.9.6: mobile-conscious modular cover cassettes, visual-only.
## Every shell is constructed INSIDE a Map Forge gameplay collider AABB.
## No physics, navigation, lights, runtime asset downloads, or new sources.
const LIMIT_MESH_NODES := 190
const LIMIT_TOTAL_INSTANCES := 290
var cover_guides: Array = []
var mesh_nodes := 0
var visual_instances := 0
var built_cover_ids: Array[String] = []
var box_cache: Dictionary = {}
var plate: Material
var steel: Material
var gasket: Material
var inset: Material
var stripe: Material
var diode: Material

func _ready() -> void:
    name = "FISURA | 0.9.6 map-owned modular cover cassettes | VISUAL ONLY"
    plate = _pbr("green_metal_rust", Color("#a9bac3"), 0.43)
    steel = _pbr("concrete_wall_007", Color("#8196a3"), 0.47)
    gasket = _mat(Color("#18262f"), 0.18, 0.86)
    inset = _mat(Color("#273e4b"), 0.68, 0.49)
    stripe = _mat(Color("#ca9e62"), 0.53, 0.48)
    diode = _mat(Color("#75bbbf"), 0.16, 0.41, 0.42)
    for data in cover_guides:
        if not isinstance(data, Dictionary) or str(data.get("kind", "")) != "cover":
            continue
        _cassette(data)
    assert(built_cover_ids.size() == 7, "Expected exactly seven authoritative Reactivo-13 cover guides")
    assert(mesh_nodes <= LIMIT_MESH_NODES and visual_instances <= LIMIT_TOTAL_INSTANCES,
        "Visual cover module exceeds declared Android planning budget")
    print("FISURA COVER CASSETTES READY guides=%d mesh_nodes=%d instances=%d physics=0 lights=0" %
        [built_cover_ids.size(), mesh_nodes, visual_instances])

func _pbr(slug: String, tint: Color, scale: float) -> ORMMaterial3D:
    var mat := ORMMaterial3D.new()
    var prefix: String = "res://assets/vendor/polyhaven_materials/" + slug + "/"
    mat.albedo_color = tint
    mat.albedo_texture = load(prefix + "diff.jpg") as Texture2D
    mat.orm_texture = load(prefix + "arm.jpg") as Texture2D
    mat.normal_enabled = true
    mat.normal_texture = load(prefix + "nor_gl.jpg") as Texture2D
    mat.uv1_triplanar = true
    mat.uv1_scale = Vector3.ONE * scale
    return mat

func _mat(color: Color, metallic: float, rough: float, glow: float = 0.0) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metallic
    mat.roughness = rough
    if glow > 0.0:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = glow
    return mat

func _box(parent: Node3D, label: String, position: Vector3, dimensions: Vector3,
        finish: Material) -> void:
    var key: String = str(dimensions.snapped(Vector3.ONE * 0.001))
    if not box_cache.has(key):
        var mesh := BoxMesh.new()
        mesh.size = dimensions
        box_cache[key] = mesh
    var display := MeshInstance3D.new()
    display.name = "Cover part %03d | %s" % [mesh_nodes, label]
    display.position = position
    display.mesh = box_cache[key]
    display.material_override = finish
    display.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(display)
    mesh_nodes += 1
    visual_instances += 1

func _vent_louvers(parent: Node3D, w: float, h: float, l: float) -> void:
    # One draw node per face; five small plates per side via MultiMesh.
    var blade := BoxMesh.new()
    blade.size = Vector3(minf(w*0.49, 0.90), 0.065, 0.028)
    for side in [-1.0, 1.0]:
        var bank := MultiMesh.new()
        bank.transform_format = MultiMesh.TRANSFORM_3D
        bank.mesh = blade
        bank.instance_count = 5
        for row in range(5):
            var y := -h*0.30 + float(row) * h*0.15
            bank.set_instance_transform(row, Transform3D(Basis.IDENTITY,
                Vector3(0, y, float(side)*(l*0.5-0.028))))
        var display := MultiMeshInstance3D.new()
        display.name = "Cover vent louvers | %s" % ("front" if side > 0 else "back")
        display.multimesh = bank
        display.material_override = inset
        display.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        parent.add_child(display)
        mesh_nodes += 1
        visual_instances += 5

func _cassette(guide: Dictionary) -> void:
    var identifier: String = str(guide.get("id", ""))
    assert(not identifier.is_empty() and not built_cover_ids.has(identifier),
        "Map Forge cover duplicate/blank id")
    var p: Array = guide["position"]
    var s: Array = guide["size"]
    var center := Vector3(float(p[0]), float(p[1]), float(p[2]))
    var size := Vector3(float(s[0]), float(s[1]), float(s[2]))
    assert(size.x >= 1.8 and size.y >= 1.8 and size.z >= 1.8,
        "Cover cassette cannot fit within Map Forge collider")
    built_cover_ids.append(identifier)
    var group := Node3D.new()
    group.name = "COVER CASSETTE | " + identifier
    group.position = center
    group.set_meta("map_forge_center", center)
    group.set_meta("map_forge_size", size)
    add_child(group)
    var hx: float = size.x * 0.5
    var hy: float = size.y * 0.5
    var hz: float = size.z * 0.5
    # Full shell surfaces conceal the formerly plain primitive, while staying
    # slightly *inside* gameplay collider faces and keeping cover silhouette solid.
    for side in [-1.0, 1.0]:
        var direction: float = float(side)
        _box(group, "PBR steel X shell", Vector3(direction*(hx-0.055), 0, 0),
            Vector3(0.085,size.y*0.89,size.z*0.94), plate)
        _box(group, "PBR concrete Z shell", Vector3(0, 0, direction*(hz-0.055)),
            Vector3(size.x*0.91,size.y*0.88,0.085), steel)
        _box(group, "recessed end armor", Vector3(0, 0.26, direction*(hz-0.008)),
            Vector3(size.x*0.67,size.y*0.47,0.012), inset)
        _box(group, "caution inlay", Vector3(0, -hy*0.49, direction*(hz-0.007)),
            Vector3(size.x*0.69,0.08,0.012), stripe)
        _box(group, "lower impact gasket", Vector3(direction*(hx-0.013), -hy*0.58, 0),
            Vector3(0.018,0.085,size.z*0.89), gasket)
    for sx in [-1.0, 1.0]:
        for sz in [-1.0, 1.0]:
            _box(group, "machined corner rail", Vector3(float(sx)*(hx-0.12), 0,
                float(sz)*(hz-0.11)),Vector3(0.17,size.y*0.95,0.15),plate)
    _box(group, "top pressure hull", Vector3(0, hy-0.052, 0),
        Vector3(size.x*0.95,0.085,size.z*0.96),plate)
    _box(group, "top service spine", Vector3(0, hy-0.008, 0),
        Vector3(size.x*0.65,0.012,size.z*0.78),gasket)
    _box(group, "status capsule", Vector3(0, hy-0.003, 0),
        Vector3(size.x*0.38,0.008,minf(1.2,size.z*0.31)),diode)
    _vent_louvers(group,size.x,size.y,size.z)
