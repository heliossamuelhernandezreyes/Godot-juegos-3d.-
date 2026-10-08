extends Node3D
## FISURA // REACTIVO-13 visual pass, source-traced PBR, deterministic geometry.
## This is render-only; gameplay geometry remains in the ARCONT semantic contract.
## Target: recognisable mission landmarks, controlled light budgets and mobile LOD path.
const BARREL: PackedScene = preload("res://assets/vendor/polyhaven/barrel_03/barrel_03_1k.gltf")
const WALL_LAMP: PackedScene = preload("res://assets/vendor/polyhaven/industrial_wall_lamp/industrial_wall_lamp_1k.gltf")
var metal: Material
var worn: Material
var copper: Material
var warning: Material
var cyan: Material
var amber: Material
var red: Material
var dark: Material
var glowing_core: MeshInstance3D
var halo: MeshInstance3D
var time_accum := 0.0
var draw_nodes := 0
var material_cache: Dictionary = {}
var box_cache: Dictionary = {}

func _ready() -> void:
    name = "REACTIVO-13 | cinematic industrial dressing"
    metal = _pbr("green_metal_rust", Color("#8babb7"), 0.5)
    worn = _pbr("concrete_wall_007", Color("#a7bbc7"), 0.38)
    copper = _mat(Color("#8e543c"), 0.76, 0.34)
    dark = _mat(Color("#182e3e"), 0.40, 0.68)
    warning = _mat(Color("#e0a75c"), 0.6, 0.35, 0.8)
    cyan = _mat(Color("#49d9e9"), 0.18, 0.27, 2.8)
    amber = _mat(Color("#ffa85c"), 0.2, 0.27, 2.6)
    red = _mat(Color("#ff5142"), 0.12, 0.34, 2.5)
    _perimeter()
    _main_corridor()
    _node_rooms()
    _reactor()
    _exit_platform()
    _light_rig()
    print("REACTIVO CINEMATIC READY visual_nodes=",draw_nodes," point_lights=7")

func _mat(tint: Color, metallic: float, roughness: float, emission: float = 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = tint
    m.metallic = metallic
    m.roughness = roughness
    if emission > 0.0:
        m.emission_enabled = true
        m.emission = tint
        m.emission_energy_multiplier = emission
    return m

func _pbr(id: String, tint: Color, uv_scale: float) -> ORMMaterial3D:
    var m := ORMMaterial3D.new()
    var base := "res://assets/vendor/polyhaven_materials/" + id + "/"
    m.albedo_color = tint
    m.albedo_texture = load(base + "diff.jpg") as Texture2D
    m.orm_texture = load(base + "arm.jpg") as Texture2D
    m.normal_enabled = true
    m.normal_texture = load(base + "nor_gl.jpg") as Texture2D
    m.uv1_triplanar = true
    m.uv1_scale = Vector3.ONE * uv_scale
    return m

func _box(tag: String, pos: Vector3, dimensions: Vector3, finish: Material) -> MeshInstance3D:
    var display := MeshInstance3D.new()
    display.name = tag
    var key := str(dimensions.snapped(Vector3.ONE * 0.001))
    if not box_cache.has(key):
        var primitive := BoxMesh.new()
        primitive.size = dimensions
        box_cache[key] = primitive
    display.mesh = box_cache[key]
    display.material_override = finish
    display.position = pos
    display.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(display)
    draw_nodes += 1
    return display

func _tube(tag: String, pos: Vector3, radius: float, height: float, along_x: bool, finish: Material) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = tag
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius
    cylinder.height = height
    cylinder.radial_segments = 8
    item.mesh = cylinder
    item.material_override = finish
    item.position = pos
    item.rotation = Vector3(0, 0, PI / 2.0) if along_x else Vector3(PI / 2.0, 0, 0)
    item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(item)
    draw_nodes += 1
    return item

func _text(message: String, pos: Vector3, size: int, tint: Color) -> void:
    var label := Label3D.new()
    label.name = "Wayfinding | " + message
    label.text = message
    label.font_size = size
    label.pixel_size = 0.0048
    label.modulate = tint
    label.outline_modulate = Color("#061723")
    label.outline_size = 8
    label.position = pos
    add_child(label)

func _perimeter() -> void:
    # Source PBR surface architecture, scaled to 84x66 rather than hard-coded Crisol 44x44.
    for x in range(-38, 39, 8):
        var xx := float(x)
        for z in [-32.1, 32.1]:
            _box("North/South buttress", Vector3(xx, 5.6, z), Vector3(0.8, 9.7, 0.7), metal)
            _box("Buttress status cap", Vector3(xx, 8.9, z), Vector3(0.94, 0.20, 0.83), cyan if x % 16 == 0 else warning)
    for z in range(-28, 29, 7):
        var zz := float(z)
        for x in [-41.0, 41.0]:
            _box("East/West buttress", Vector3(x, 5.6, zz), Vector3(0.7, 9.7, 0.8), metal)
            _box("Service window", Vector3(x * 0.995, 5.3, zz), Vector3(0.12, 2.1, 2.9), dark)
            _box("Power conduit", Vector3(x * 0.990, 4.1, zz), Vector3(0.17, 0.14, 2.3), amber)
    for z in [-30.0, 30.0]:
        _box("Continuous ceiling rib", Vector3(0, 9.9, z), Vector3(80, 0.64, 0.8), metal)
    for x in [-39.0, 39.0]:
        _box("Longitudinal service truss", Vector3(x, 9.9, 0), Vector3(0.8, 0.64, 60), metal)

func _main_corridor() -> void:
    # Repeated canopy ribs sit above the shoulder camera and signal progression.
    for z in [25.0, 16.0, 7.0, -2.0, -19.0]:
        for x in [-9.8, 9.8]:
            _box("Reactor spine | vertical pier", Vector3(x, 5.6, z), Vector3(1.05, 9.3, 1.25), worn)
            _box("Spine energy strip", Vector3(x, 4.6, z - 0.67), Vector3(0.18, 3.5, 0.12), amber if z < -1.0 else cyan)
            _box("Pier foot armor", Vector3(x, 0.52, z), Vector3(2.0, 0.9, 1.8), metal)
        _box("Canopy over combat lane", Vector3(0, 10.15, z), Vector3(20.6, 0.55, 1.4), metal)
        _box("Canopy warning trim", Vector3(0, 9.79, z - 0.3), Vector3(9.5, 0.11, 0.12), red if z < 0 else cyan)
        _text("SECTOR %02d  //  REACTIVO-13" % int(absf(z)), Vector3(0, 7.45, z - 0.88), 46, Color("#9ce9ee"))
    for x in [-13.5, 13.5]:
        _tube("Cooling high pressure pipe", Vector3(x, 8.4, 0), 0.24, 58.0, false, copper)
        _tube("Cooling pipe trim", Vector3(x + 0.55, 8.4, 0), 0.10, 58.0, false, warning)
    for z in range(-25, 27, 5):
        var zz := float(z)
        _box("Track left hazard", Vector3(-4.8, 0.055, zz), Vector3(0.09, 0.06, 3.5), cyan)
        _box("Track right hazard", Vector3(4.8, 0.055, zz), Vector3(0.09, 0.06, 3.5), cyan)
        if z % 10 == 0:
            _box("Service hatch", Vector3(0, 0.059, zz), Vector3(2.9, 0.06, 0.09), dark)

func _node_rooms() -> void:
    for side in [-1.0, 1.0]:
        var x := side * 28.0
        _box("Node A/B industrial pedestal", Vector3(x, 0.37, 4), Vector3(3.8, 0.62, 3.3), metal)
        for dz in [-2.0, 2.0]:
            _box("Node side coolant tower", Vector3(x + side * 4.0, 2.2, 4.0 + dz * 2.0),
                Vector3(1.6, 4.3, 1.5), worn)
            _box("Node coolant column strip", Vector3(x + side * 3.3, 2.4, 4.0 + dz * 2.0),
                Vector3(0.08, 3.1, 0.14), cyan if side < 0 else amber)
        _box("Node interconnect bus", Vector3(x, 6.4, 4), Vector3(12.0, 0.65, 1.05), metal)
        _box("Node status display", Vector3(x, 6.0, 3.38), Vector3(5.0, 0.21, 0.12), cyan if side < 0 else amber)
        _text("NODO A  /  ENERGIA" if side < 0 else "NODO B  /  ENERGIA",
            Vector3(x, 4.6, 3.2), 50, Color("#7de9fa") if side < 0 else Color("#ffbe70"))
        for dx in [-6.0, 6.0]:
            var prop: Node3D = BARREL.instantiate()
            prop.name = "Poly Haven CC0 PBR industrial barrel"
            prop.position = Vector3(x + dx, 0, 2)
            add_child(prop)
            draw_nodes += 1

func _reactor() -> void:
    var core := MeshInstance3D.new()
    core.name = "MAIN REACTOR | luminous unstable core"
    var sph := SphereMesh.new()
    sph.radius = 1.48
    sph.height = 2.96
    sph.radial_segments = 32
    sph.rings = 16
    core.mesh = sph
    core.material_override = amber
    core.position = Vector3(0, 3.4, -11)
    add_child(core)
    glowing_core = core
    draw_nodes += 1
    for index in range(3):
        var ring := MeshInstance3D.new()
        ring.name = "REACTOR | toroidal containment gyro %d" % index
        var torus := TorusMesh.new()
        torus.inner_radius = 2.0 + float(index) * 0.35
        torus.outer_radius = 2.20 + float(index) * 0.35
        torus.rings = 32
        torus.ring_segments = 10
        ring.mesh = torus
        ring.material_override = cyan if index % 2 == 0 else copper
        ring.position = Vector3(0, 3.4, -11)
        ring.rotation = Vector3(float(index) * 0.56, float(index) * 0.34, float(index) * 0.72)
        add_child(ring)
        if index == 0:
            halo = ring
        draw_nodes += 1
    for x in [-6.0, 6.0]:
        for z in [-17.0, -5.0]:
            _box("Containment load-bearing pylon", Vector3(x, 4.4, z), Vector3(1.65, 8.4, 1.65), metal)
            _box("Reactor hazard strip", Vector3(x, 4.9, z + 0.88), Vector3(0.4, 5.6, 0.1), red)
    _text("ZONA DE CONFINAMIENTO  |  NIVEL 04", Vector3(0, 8.8, -18), 48, Color("#ffb084"))

func _exit_platform() -> void:
    _box("Extraction frame upper arch", Vector3(0, 6.8, -27.5), Vector3(11.0, 0.95, 1.2), metal)
    for x in [-5.3, 5.3]:
        _box("Extraction frame pier", Vector3(x, 3.35, -27.5), Vector3(0.9, 6.7, 1.4), worn)
        _box("Extraction illuminated bar", Vector3(x * 0.98, 3.0, -28.4), Vector3(0.1, 5.4, 0.13), cyan)
    _text("EXTRACCION  /  13", Vector3(0, 5.7, -28.35), 58, Color("#85f3cb"))

func _light_rig() -> void:
    var fixtures := [
        [Vector3(0, 8, 22), Color("#69caff"), 13.0],
        [Vector3(-28, 6.5, 4), Color("#54d7f3"), 11.0],
        [Vector3(28, 6.5, 4), Color("#ffb873"), 11.0],
        [Vector3(0, 7, -11), Color("#ff7d4a"), 16.0],
        [Vector3(-7, 6, -16), Color("#e97751"), 10.0],
        [Vector3(7, 6, -16), Color("#e97751"), 10.0],
        [Vector3(0, 7, -29), Color("#75f6dd"), 10.0]
    ]
    for record in fixtures:
        var lamp := OmniLight3D.new()
        lamp.position = record[0]
        lamp.light_color = record[1]
        lamp.light_energy = 2.1
        lamp.omni_range = float(record[2])
        lamp.shadow_enabled = false
        add_child(lamp)

func _process(delta: float) -> void:
    time_accum += delta
    if glowing_core != null:
        glowing_core.position.y = 3.4 + sin(time_accum * 1.25) * 0.23
        glowing_core.rotate_y(delta * 0.5)
    if halo != null:
        halo.rotate_y(delta * 0.30)
