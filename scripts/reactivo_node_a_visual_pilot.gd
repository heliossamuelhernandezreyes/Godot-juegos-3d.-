extends Node3D
## FISURA visual-production P2 pilot: a single authored hero assembly for Node A.
## All nodes are presentation only. No CollisionObject3D, navigation, signals or scripts
## with gameplay authority; no new Omni/Spot/Directional lights or realtime shadows.
## Geometry is deterministic and bounded for Godot gl_compatibility mobile.
const MAX_MESHES := 100
var render_meshes := 0
var pbr_steel: Material
var pbr_concrete: Material
var graphite: Material
var dark_metal: Material
var brass: Material
var rubber: Material
var cyan_glass: Material
var cyan_edge: Material
var pale_indicator: Material
var emergency: Material
var cached_boxes: Dictionary = {}

func _ready() -> void:
    name = "VISUAL PILOT | Node A coolant turbine | render only"
    pbr_steel = _pbr("green_metal_rust", Color("#839fa9"), 0.43)
    pbr_concrete = _pbr("concrete_wall_007", Color("#8397a4"), 0.28)
    graphite = _mat(Color("#18232d"), 0.72, 0.59)
    dark_metal = _mat(Color("#344651"), 0.72, 0.38)
    brass = _mat(Color("#ae8454"), 0.68, 0.34)
    rubber = _mat(Color("#090f17"), 0.12, 0.82)
    cyan_glass = _mat(Color("#3ad5f0"), 0.08, 0.18, 2.1)
    cyan_edge = _mat(Color("#7de7ea"), 0.2, 0.32, 0.85)
    pale_indicator = _mat(Color("#b7dedf"), 0.21, 0.43, 0.5)
    emergency = _mat(Color("#efb56e"), 0.4, 0.42, 0.55)
    _main_structure()
    _turbine_face()
    _coolant_manifolds()
    _control_identity()
    assert(render_meshes > 52 and render_meshes <= MAX_MESHES,
        "Node A visual pilot exceeds intended geometry scope")
    print("NODE A VISUAL PILOT READY render_only=true meshes=%d lights=0 colliders=0" % render_meshes)

func _mat(tint: Color, metallic: float, roughness: float, glow: float = 0.0) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.metallic = metallic
    mat.roughness = roughness
    if glow > 0.0:
        mat.emission_enabled = true
        mat.emission = tint
        mat.emission_energy_multiplier = glow
    return mat

func _pbr(slug: String, tint: Color, uv_scale: float) -> ORMMaterial3D:
    var base: String = "res://assets/vendor/polyhaven_materials/" + slug + "/"
    var mat := ORMMaterial3D.new()
    mat.albedo_color = tint
    mat.albedo_texture = load(base + "diff.jpg") as Texture2D
    mat.orm_texture = load(base + "arm.jpg") as Texture2D
    mat.normal_enabled = true
    mat.normal_texture = load(base + "nor_gl.jpg") as Texture2D
    mat.uv1_triplanar = true
    mat.uv1_scale = Vector3.ONE * uv_scale
    return mat

func _add_mesh(label: String, shape: Mesh, local: Vector3, surface: Material,
        rotation_euler: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var display := MeshInstance3D.new()
    display.name = "A-PILOT | " + label
    display.mesh = shape
    display.material_override = surface
    display.position = local
    display.rotation = rotation_euler
    display.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(display)
    render_meshes += 1
    return display

func _box(label: String, pos: Vector3, size: Vector3, material: Material,
        rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var key: String = str(size.snapped(Vector3.ONE * 0.001))
    if not cached_boxes.has(key):
        var shape := BoxMesh.new()
        shape.size = size
        cached_boxes[key] = shape
    return _add_mesh(label, cached_boxes[key], pos, material, rot)

func _cylinder(label: String, at: Vector3, r: float, length: float,
        material: Material, facing_camera: bool = false) -> MeshInstance3D:
    var shape := CylinderMesh.new()
    shape.top_radius = r
    shape.bottom_radius = r
    shape.height = length
    shape.radial_segments = 16
    var tilt: Vector3 = Vector3(PI * 0.5, 0, 0) if facing_camera else Vector3.ZERO
    return _add_mesh(label, shape, at, material, tilt)

func _ring(label: String, at: Vector3, inner: float, outer: float,
        material: Material) -> MeshInstance3D:
    var torus := TorusMesh.new()
    torus.inner_radius = inner
    torus.outer_radius = outer
    torus.rings = 24
    torus.ring_segments = 8
    return _add_mesh(label, torus, at, material, Vector3(PI * 0.5, 0, 0))

func _main_structure() -> void:
    # The visual machine is behind the gameplay terminal at x=-28,z=4.
    # Local z=0 corresponds to world z=0.55, and leaves console interaction clear.
    _box("substation plinth | stained concrete", Vector3(0, 0.38, 0.0), Vector3(6.4, 0.76, 3.7), pbr_concrete)
    _box("substation plinth | low steel curb", Vector3(0, 0.78, 0.8), Vector3(5.8, 0.18, 0.33), graphite)
    _box("turbine mounting bulkhead", Vector3(0, 3.22, -1.10), Vector3(5.9, 4.65, 1.1), pbr_steel)
    _box("deep inset around rotor", Vector3(0, 3.18, -0.40), Vector3(3.65, 3.60, 0.28), rubber)
    for side in [-1.0, 1.0]:
        _box("reinforced vertical gantry", Vector3(side * 2.76, 3.4, 0.0), Vector3(0.62, 5.7, 1.7), dark_metal)
        _box("worn armor outer face", Vector3(side * 2.85, 3.5, 0.9), Vector3(0.28, 4.35, 0.16), pbr_steel)
        _box("gantry gold seam", Vector3(side * 2.67, 3.5, 1.01), Vector3(0.10, 3.88, 0.05), brass)
        _box("lower stabilizer foot", Vector3(side * 2.76, 0.7, 0.35), Vector3(1.2, 0.62, 2.2), pbr_steel)
        _box("coolant collar above chassis", Vector3(side * 2.25, 6.05, -0.35), Vector3(1.0, 0.45, 1.2), dark_metal)
    _box("machined overhead crossbeam", Vector3(0, 6.22, -0.20), Vector3(6.2, 0.48, 1.95), graphite)
    _box("ceiling emitter seam", Vector3(0, 5.92, 1.02), Vector3(3.5, 0.10, 0.10), cyan_edge)
    _box("floor trench warning on left", Vector3(-3.15, 0.035, 1.75), Vector3(0.12, 0.045, 1.7), emergency)
    _box("floor trench warning on right", Vector3(3.15, 0.035, 1.75), Vector3(0.12, 0.045, 1.7), emergency)

func _turbine_face() -> void:
    # The circular iris, concentric geometry and visible depth replace a plain box.
    # All surfaces are noncolliding and use existing PBR + a few emission materials.
    var center := Vector3(0, 3.42, 0.76)
    _cylinder("dark recessed turbine drum", center + Vector3(0, 0, -0.28), 1.62, 0.95, graphite, true)
    _ring("outer forged iron turbine bearing", center + Vector3(0, 0, 0.34), 1.53, 1.78, pbr_steel)
    _ring("gasket|soft shadow break", center + Vector3(0, 0, 0.45), 1.26, 1.43, rubber)
    _ring("coolant energy conduit | cyan", center + Vector3(0, 0, 0.58), 1.12, 1.23, cyan_glass)
    _ring("inner rotor brass collar", center + Vector3(0, 0, 0.65), 0.72, 0.91, brass)
    _cylinder("central containment iris", center + Vector3(0, 0, 0.78), 0.73, 0.22, dark_metal, true)
    _cylinder("center warning diode", center + Vector3(0, 0, 0.93), 0.28, 0.12, cyan_glass, true)
    for index in range(8):
        var angle := float(index) * TAU / 8.0
        var rotor_r := 1.01
        var spoke := Vector3(cos(angle) * rotor_r, sin(angle) * rotor_r, 0.65)
        _box("radial ceramic fan plate %02d" % index, center + spoke,
            Vector3(0.42, 0.19, 0.12), pbr_steel if index % 2 == 0 else dark_metal,
            Vector3(0, 0, angle))
    for quadrant in range(4):
        var angle := float(quadrant) * TAU / 4.0 + PI * 0.25
        var rivet := Vector3(cos(angle) * 1.88, sin(angle) * 1.88, 0.54)
        _cylinder("turbine service bolt %d" % quadrant, center + rivet,
            0.14, 0.18, brass, true)

func _coolant_manifolds() -> void:
    # Vertical cooling fins define a much more recognizable machine silhouette
    # without adding a dynamic light, physics collider or particle emitter.
    for side in [-1.0, 1.0]:
        var sx: float = side * 2.10
        _cylinder("pressure return pipe", Vector3(sx, 3.24, -0.08), 0.24, 4.75, brass)
        _cylinder("return-pipe inner lumen", Vector3(sx, 3.24, -0.08), 0.11, 4.85, graphite)
        for y in [1.55, 2.95, 4.35, 5.55]:
            _box("captive coolant clamp", Vector3(sx, y, 0.33),
                Vector3(0.54, 0.26, 0.54), dark_metal)
        for slot in range(8):
            var v: float = 1.50 + float(slot) * 0.48
            _box("interleaved fin | deep negative space %d" % slot,
                Vector3(side * 2.30, v, 1.08), Vector3(0.72, 0.13, 0.26),
                pbr_steel if slot % 3 == 0 else graphite)
    for branch in [-1.0, 1.0]:
        _box("conduit upper | segmented copper", Vector3(branch * 1.75, 6.58, -0.54),
            Vector3(1.8, 0.18, 0.22), brass)
    for x in [-1.47, -0.49, 0.49, 1.47]:
        _box("status pixel | alternating industrial signal",
            Vector3(x, 6.50, 0.77), Vector3(0.46, 0.13, 0.12),
            cyan_edge if absf(x) < 1 else pale_indicator)

func _control_identity() -> void:
    _box("serial plate | central backer", Vector3(0, 1.06, 1.14),
        Vector3(2.35, 0.30, 0.12), dark_metal)
    _box("serial plate | thin identity insert", Vector3(0, 1.06, 1.21),
        Vector3(1.84, 0.12, 0.05), cyan_edge)
    var plaque := Label3D.new()
    plaque.name = "A-PILOT | NODE A | coolant containment serial"
    plaque.text = "A-01   //   CRYO CORE"
    plaque.font_size = 52
    plaque.pixel_size = 0.0033
    plaque.modulate = Color("#b4eff5")
    plaque.outline_modulate = Color("#09151e")
    plaque.outline_size = 9
    plaque.position = Vector3(0, 5.42, 1.02)
    add_child(plaque)
    # No extra lights, and the existing node interaction remains at z=4.
