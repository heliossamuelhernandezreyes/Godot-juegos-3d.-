extends Node3D
## FISURA 0.9.5 — render-only environmental hierarchy around NODE A.
## Geometry inherits the scene; it never creates lights, physics, or gameplay data.
## Game-owned Node A cover proxy is read from Map Forge's structure_guides.
const MAX_MESHES := 124
var environment_meshes := 0
var cover_guide: Dictionary = {}
var box_cache: Dictionary = {}
var floor_pbr: Material
var oxidized: Material
var concrete: Material
var structural: Material
var inset: Material
var brass: Material
var cyan: Material
var hazard: Material
var gasket: Material

func _ready() -> void:
    name = "VISUAL PASS | Node A industrial bay | render only"
    floor_pbr = _pbr("concrete_floor_worn_02", Color("#788c98"), 0.83)
    oxidized = _pbr("green_metal_rust", Color("#90a4af"), 0.53)
    concrete = _pbr("concrete_wall_007", Color("#788d99"), 0.42)
    structural = _metal(Color("#455765"), 0.77, 0.40)
    inset = _metal(Color("#142a36"), 0.62, 0.56)
    brass = _metal(Color("#a28260"), 0.68, 0.37)
    cyan = _metal(Color("#59d6df"), 0.18, 0.30, 0.72)
    hazard = _metal(Color("#f0b26c"), 0.43, 0.36, 0.42)
    gasket = _metal(Color("#17242d"), 0.13, 0.90)
    _floor_grid()
    _industrial_backdrop()
    _pipe_racks()
    _cover_finish()
    assert(environment_meshes > 60 and environment_meshes <= MAX_MESHES,
        "Node A environmental layer exceeds visual-only geometry budget")
    print("NODE A ENVIRONMENT PASS READY meshes=%d lights=0 colliders=0" % environment_meshes)

func _pbr(slug: String, tint: Color, scale: float) -> ORMMaterial3D:
    var material := ORMMaterial3D.new()
    var dir: String = "res://assets/vendor/polyhaven_materials/" + slug + "/"
    material.albedo_color = tint
    material.albedo_texture = load(dir + "diff.jpg") as Texture2D
    material.orm_texture = load(dir + "arm.jpg") as Texture2D
    material.normal_enabled = true
    material.normal_texture = load(dir + "nor_gl.jpg") as Texture2D
    material.uv1_triplanar = true
    material.uv1_scale = Vector3.ONE * scale
    return material

func _metal(color: Color, metal: float, rough: float, glow: float = 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metal
    m.roughness = rough
    if glow > 0.0:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = glow
    return m

func _box(label: String, at: Vector3, dimensions: Vector3, finish: Material) -> void:
    var key: String = str(dimensions.snapped(Vector3.ONE * 0.001))
    if not box_cache.has(key):
        var mesh := BoxMesh.new()
        mesh.size = dimensions
        box_cache[key] = mesh
    var item := MeshInstance3D.new()
    # Godot auto-renames duplicate sibling names to @MeshInstance3D@xx and
    # loses semantic labels; use a stable unique ordinal for every visual item.
    item.name = "ENV A | %03d | %s" % [environment_meshes, label]
    item.mesh = box_cache[key]
    item.position = at
    item.material_override = finish
    item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(item)
    environment_meshes += 1

func _pipe(label: String, at: Vector3, radius: float, length: float,
        axis_z: bool, finish: Material) -> void:
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius
    cylinder.height = length
    cylinder.radial_segments = 10
    var display := MeshInstance3D.new()
    display.name = "ENV A | " + label
    display.mesh = cylinder
    display.position = at
    display.rotation = Vector3(PI * 0.5, 0, 0) if axis_z else Vector3(0, 0, PI * 0.5)
    display.material_override = finish
    display.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(display)
    environment_meshes += 1

func _floor_grid() -> void:
    # Shallow panels decorate the existing solid floor; no navigation surface is added.
    # Defined around actual Node A console at world (-28,0,4), avoiding a fake level.
    for strip in range(5):
        var x: float = (float(strip) - 2.0) * 1.85
        for depth in range(5):
            var z: float = -2.0 + float(depth) * 2.2
            _box("panel | worn slab %d-%d" % [strip, depth],
                Vector3(x, 0.066, z),
                Vector3(1.73, 0.12, 2.05),
                floor_pbr if (strip + depth) % 3 != 0 else concrete)
    for side in [-1.0, 1.0]:
        var x: float = float(side) * 4.85
        _box("service trench | protective rail", Vector3(x, 0.098, 3.0),
            Vector3(0.22, 0.10, 10.7), oxidized)
        for segment in range(6):
            var z: float = -1.7 + float(segment) * 1.80
            _box("service trench | vent grille", Vector3(x, 0.138, z),
                Vector3(0.79, 0.065, 0.10), structural)
        _box("coolant route | caution rail", Vector3(float(side)*3.54, 0.151, 2.8),
            Vector3(0.095, 0.045, 9.4), hazard)
    _box("node A waypoint floor blade", Vector3(0, 0.151, 8.0),
        Vector3(2.30, 0.045, 0.12), cyan)
    _box("service bay serial inlay", Vector3(0, 0.152, -2.18),
        Vector3(3.70, 0.045, 0.13), hazard)

func _industrial_backdrop() -> void:
    # Nonblocking, high back wall and service portal around the existing
    # Node A turbine, with pronounced PBR layers instead of another plain cube.
    for side in [-1.0, 1.0]:
        var x: float = float(side) * 5.22
        _box("frame | dark structural vertical", Vector3(x, 3.90, -3.35),
            Vector3(0.64, 7.40, 0.78), structural)
        _box("frame | corroded inner rail", Vector3(x - float(side)*0.30, 3.88, -2.81),
            Vector3(0.15, 6.24, 0.18), oxidized)
        _box("frame | upright hazard insert", Vector3(x + float(side)*0.25, 3.4, -2.80),
            Vector3(0.11, 3.9, 0.13), hazard)
        _box("bay | concrete weathering flank", Vector3(x + float(side)*0.7, 3.36, -4.05),
            Vector3(1.36, 6.0, 0.29), concrete)
    _box("service portal | top gantry", Vector3(0, 7.58, -3.30),
        Vector3(11.8, 0.64, 1.06), oxidized)
    _box("service portal | inner dark soffit", Vector3(0, 7.15, -2.88),
        Vector3(10.3, 0.25, 0.41), inset)
    _box("service portal | restrained cyan edge", Vector3(0, 7.0, -2.63),
        Vector3(4.9, 0.08, 0.08), cyan)
    for section in range(5):
        var x: float = (float(section) - 2.0) * 1.75
        _box("backplane | deep wall cassette", Vector3(x, 3.56, -4.12),
            Vector3(1.57, 4.44, 0.31), concrete if section % 2 == 0 else oxidized)
        _box("backplane | inset rib", Vector3(x, 3.56, -3.90),
            Vector3(0.09, 3.40, 0.11), inset)
    for x in [-3.7, 3.7]:
        _box("ceiling hydraulic service", Vector3(x, 6.36, -3.01),
            Vector3(0.92, 0.28, 0.95), brass)

func _pipe_racks() -> void:
    # Short, shadow-free infrastructure above sight/cover height.
    for side in [-1.0, 1.0]:
        var x: float = float(side) * 4.05
        _pipe("ceiling loop | copper", Vector3(x, 6.52, 0.08),
            0.15, 6.0, true, brass)
        _pipe("ceiling loop | secondary", Vector3(x + float(side)*0.34, 6.31, -0.01),
            0.09, 5.4, true, inset)
        for support in range(3):
            var z: float = -2.15 + float(support) * 1.75
            _box("pipe bracket | forged holder", Vector3(x, 6.35, z),
                Vector3(0.50, 0.28, 0.16), oxidized)

func _cover_finish() -> void:
    if cover_guide.is_empty():
        # The game contract must explicitly identify gameplay-owned cover.
        push_error("Node A environment was not supplied an authoritative Map Forge cover guide")
        return
    var pos: Array = cover_guide["position"]
    var ext: Array = cover_guide["size"]
    var world_center := Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
    var bounds := Vector3(float(ext[0]),float(ext[1]),float(ext[2]))
    # Node A layer origin is world (-28,0,4); strictly INSIDE the existing
    # physical AABB so art cannot promise traversable or cover geometry wrongly.
    var center := world_center - Vector3(-28.0,0.0,4.0)
    var hx: float = bounds.x * 0.5
    var hy: float = bounds.y * 0.5
    var hz: float = bounds.z * 0.5
    for side in [-1.0,1.0]:
        _box("cover | inlaid armored wall face", center + Vector3(float(side)*(hx-0.04),0,0),
            Vector3(0.055,bounds.y*0.80,bounds.z*0.90), oxidized)
        _box("cover | edge channel inside solid proxy", center + Vector3(float(side)*(hx-0.035),-0.42,0),
            Vector3(0.062,0.10,bounds.z*0.82), gasket)
    _box("cover | shadowless service cap", center + Vector3(0,hy-0.04,0),
        Vector3(bounds.x*0.93,0.056,bounds.z*0.96), structural)
    for side in [-1.0,1.0]:
        _box("cover | recessed safety plate", center + Vector3(0,0,float(side)*(hz-0.04)),
            Vector3(bounds.x*0.83,bounds.y*0.64,0.06), oxidized)
        _box("cover | side warning insert", center + Vector3(0,-0.4,float(side)*(hz-0.033)),
            Vector3(bounds.x*0.60,0.11,0.045), hazard)
