extends Node3D
## ARCONT gameplay VFX budget: transient emissive geometry, no dynamic shadows.
## 16 pooled-equivalent in-flight effects max; no GPU particles or external dependencies.
const CAP := 16
var live: Array[Node3D] = []
var cyan: StandardMaterial3D
var orange: StandardMaterial3D
var flare: StandardMaterial3D

func _ready() -> void:
    cyan = _glow(Color("#6bedf5"), 3.7)
    orange = _glow(Color("#ff8751"), 4.1)
    flare = _glow(Color("#ffcf8f"), 5.5)

func _glow(c: Color, power: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.emission_enabled = true
    m.emission = c
    m.emission_energy_multiplier = power
    return m

func _track(node: Node3D, lifetime: float) -> void:
    if live.size() >= CAP:
        var oldest: Node3D = live.pop_front()
        if is_instance_valid(oldest):
            oldest.queue_free()
    live.append(node)
    var timer := get_tree().create_timer(lifetime)
    timer.timeout.connect(func() -> void:
        live.erase(node)
        if is_instance_valid(node):
            node.queue_free()
    )

func _bolt(from: Vector3, target: Vector3, radius: float, color: Material, lifetime: float) -> void:
    var offset := target - from
    if offset.length_squared() < 0.0001:
        return
    var beam := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius
    cylinder.height = offset.length()
    cylinder.radial_segments = 6
    beam.mesh = cylinder
    beam.material_override = color
    beam.position = (from + target) * 0.5
    beam.quaternion = Quaternion(Vector3.UP, offset.normalized())
    beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(beam)
    _track(beam, lifetime)

func muzzle(pos: Vector3, forward: Vector3) -> void:
    var flash := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.27
    mesh.height = 0.54
    mesh.radial_segments = 10
    mesh.rings = 5
    flash.mesh = mesh
    flash.material_override = flare
    flash.position = pos + forward.normalized() * 0.4
    add_child(flash)
    _track(flash, 0.085)

func tracer(origin: Vector3, destination: Vector3) -> void:
    _bolt(origin, destination, 0.040, cyan, 0.090)

func hit(at: Vector3) -> void:
    for i in range(3):
        var angle := TAU * float(i) / 3.0
        var diff := Vector3(cos(angle), 0.6, sin(angle)) * 0.42
        _bolt(at, at + diff, 0.029, orange, 0.14)

func enemy_charge(origin: Vector3, destination: Vector3, duration: float) -> void:
    _bolt(origin, destination, 0.032, orange, maxf(0.10, duration))

func hostile_beam(origin: Vector3, destination: Vector3) -> void:
    _bolt(origin, destination, 0.075, orange, 0.15)
