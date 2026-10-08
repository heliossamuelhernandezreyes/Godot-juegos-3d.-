extends "res://scripts/enemy.gd"
## Bulwark Mk II: a heavy skinned machine using *already licensed* Quaternius rig.
## Directional armor/collision are authoritative; render-only plates are independent.
## Distinct source mesh creation/retargeting remains a future production requirement.
const RIGGED_CHASSIS = preload("res://assets/vendor/quaternius/scifi_essentials/Enemy_Trilobite.gltf")
const ARMOR_MAP = preload("res://assets/vendor/polyhaven_materials/green_metal_rust/diff.jpg")
var shield_mesh: MeshInstance3D
var absorbed_hits := 0
var heavy_rig: Node3D
var rig_anim: AnimationPlayer
var current_clip := ""
var weak_point: MeshInstance3D
var impact := 0.0

func _ready() -> void:
    hit_points = 175
    speed = 2.25
    super._ready()
    core_mesh.visible = false
    var collider: CollisionShape3D = get_node_or_null("CollisionShape3D")
    if collider != null and collider.shape is CapsuleShape3D:
        var capsule: CapsuleShape3D = collider.shape
        capsule.radius = 0.66
        capsule.height = 2.05
    heavy_rig = RIGGED_CHASSIS.instantiate()
    heavy_rig.name = "Bulwark | unique CC0 Quaternius Trilobite nine-clip heavy chassis"
    heavy_rig.scale = Vector3.ONE * 1.26
    heavy_rig.position.y = -0.84
    add_child(heavy_rig)
    rig_anim = _find_anim(heavy_rig)
    _animate("Idle")
    _plating()

func _find_anim(at: Node) -> AnimationPlayer:
    if at is AnimationPlayer:
        return at
    for node in at.get_children():
        var result := _find_anim(node)
        if result != null:
            return result
    return null

func _animate(clip: String) -> void:
    if rig_anim == null or current_clip == clip or not rig_anim.has_animation(clip):
        return
    current_clip = clip
    if clip == "Run" or clip == "Idle":
        var animation: Animation = rig_anim.get_animation(clip)
        animation.loop_mode = Animation.LOOP_LINEAR
    rig_anim.play(clip, 0.14)

func _plating() -> void:
    var plated := StandardMaterial3D.new()
    plated.albedo_color = Color("#9ba9ab")
    plated.albedo_texture = ARMOR_MAP
    plated.metallic = 0.66
    plated.roughness = 0.32
    var edge := StandardMaterial3D.new()
    edge.albedo_color = Color("#d19e58")
    edge.metallic = 0.7
    edge.roughness = 0.29
    var emissive := StandardMaterial3D.new()
    emissive.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    emissive.albedo_color = Color("#5be6f6")
    emissive.emission_enabled = true
    emissive.emission = Color("#31c9e8")
    emissive.emission_energy_multiplier = 2.9
    shield_mesh = _plate("BULWARK / frontal guard", Vector3(0, 0.27, -0.77),
        Vector3(1.95, 1.50, 0.24), plated)
    _plate("Shield upper bevel", Vector3(0, 1.10, -0.76), Vector3(2.12, 0.16, 0.35), edge)
    _plate("Shield lower bevel", Vector3(0, -0.57, -0.76), Vector3(2.12, 0.15, 0.35), edge)
    for x in [-0.80, 0.80]:
        _plate("Bulwark warning border", Vector3(x, 0.29, -0.93),
            Vector3(0.11, 1.32, 0.045), edge)
        _plate("Twin shoulder armor", Vector3(x * 1.06, 0.72, 0.13),
            Vector3(0.55, 0.60, 1.30), plated)
    _plate("Shield sensor slit", Vector3(0, 0.38, -0.91), Vector3(1.03, 0.16, 0.05), emissive)
    weak_point = _plate("Bulwark / visible rear vulnerability", Vector3(0, 0.28, 0.64),
        Vector3(0.70, 0.74, 0.12), emissive)
    var crest := Label3D.new()
    crest.name = "BU-LW / serial label"
    crest.text = "BW-13"
    crest.font_size = 36
    crest.pixel_size = 0.0048
    crest.position = Vector3(0, -0.15, -0.95)
    crest.modulate = Color("#ffc680")
    add_child(crest)

func _plate(name: String, pos: Vector3, size: Vector3, finish: Material) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var part := MeshInstance3D.new()
    part.mesh = mesh
    part.name = name
    part.position = pos
    part.material_override = finish
    part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(part)
    return part

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    impact = maxf(0.0, impact - delta * 3.0)
    if heavy_rig == null:
        return
    if impact > 0.0:
        _animate("Hit")
    elif Vector2(velocity.x, velocity.z).length() > 1.0:
        _animate("Run")
    else:
        _animate("Idle")
    if weak_point != null:
        weak_point.scale = Vector3.ONE * (1.0 + 0.08 * sin(motion_time * 4.0))

func take_hit_from(damage: int, shooter: Vector3) -> void:
    var offset := shooter - global_position
    offset.y = 0.0
    if offset.length_squared() < 0.0001:
        take_hit(damage)
        return
    var forward: Vector3 = -global_basis.z
    forward.y = 0.0
    var frontal: bool = forward.dot(offset.normalized()) > 0.35
    if frontal:
        absorbed_hits += 1
        take_hit(maxi(1, int(ceil(float(damage) * 0.22))))
    else:
        take_hit(damage)

func take_hit(damage: int) -> void:
    impact = 0.25
    _animate("Hit")
    super.take_hit(damage)
