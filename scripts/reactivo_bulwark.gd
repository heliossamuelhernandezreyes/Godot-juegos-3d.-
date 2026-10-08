extends "res://scripts/enemy.gd"
## FISURA heavy Bulwark: CC0 Quaternius native skeleton + meaningful frontal armor.
## ARCONT asset license / live Godot import proof kept separately in game provenance.
const TRILOBITE_RIG = preload("res://assets/vendor/quaternius/scifi_essentials/Enemy_Trilobite.gltf")

var shield_mesh: MeshInstance3D
var absorbed_hits := 0
var rig: Node3D
var animation_player: AnimationPlayer
var selected_clip := ""
var action_lock := 0.0

func _ready() -> void:
    hit_points = 175
    speed = 2.25
    super._ready()
    core_mesh.visible = false
    rig = TRILOBITE_RIG.instantiate()
    rig.name = "BULWARK | Quaternius CC0 skinned Trilobite"
    rig.scale = Vector3.ONE * 0.82
    rig.position.y = -0.85
    add_child(rig)
    animation_player = _find_anim(rig)
    if animation_player != null:
        for clip in ["Idle","Walk","Run"]:
            if animation_player.has_animation(clip):
                animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
        _play("Idle")
    _shield_visual()

func _find_anim(node: Node) -> AnimationPlayer:
    if node is AnimationPlayer:
        return node
    for child in node.get_children():
        var found := _find_anim(child)
        if found != null:
            return found
    return null

func _play(clip: String) -> void:
    if animation_player == null or selected_clip == clip or not animation_player.has_animation(clip):
        return
    selected_clip = clip
    animation_player.play(clip,0.16)

func _shield_visual() -> void:
    var plating := StandardMaterial3D.new()
    plating.albedo_color = Color("#2d4a55")
    plating.metallic = 0.82
    plating.roughness = 0.27
    shield_mesh = MeshInstance3D.new()
    shield_mesh.name = "BULWARK | rugged ventral guard"
    var armor := BoxMesh.new()
    armor.size = Vector3(1.12,1.10,0.17)
    shield_mesh.mesh = armor
    shield_mesh.position = Vector3(0,0.05,-0.72)
    shield_mesh.material_override = plating
    add_child(shield_mesh)
    var signal_material := StandardMaterial3D.new()
    signal_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    signal.albedo_color = Color("#f3b568")
    signal.emission_enabled = true
    signal.emission = Color("#d87c3e")
    signal.emission_energy_multiplier = 2.4
    for side in [-1.0,1.0]:
        var rail := MeshInstance3D.new()
        rail.name = "BULWARK | shield charge bar"
        var mesh := BoxMesh.new()
        mesh.size = Vector3(0.10,0.90,0.08)
        rail.mesh = mesh
        rail.position = Vector3(side*0.48,0.06,-0.84)
        rail.material_override = signal_material
        add_child(rail)

func _physics_process(delta: float) -> void:
    var before: float = contact_cooldown
    super._physics_process(delta)
    action_lock = maxf(0.0,action_lock-delta)
    if before <= 0.0 and contact_cooldown > 0.8:
        action_lock = 0.48
        _play("Attack")
    elif action_lock <= 0.0:
        var speed_now := Vector2(velocity.x,velocity.z).length()
        _play("Walk" if speed_now > 0.45 else "Idle")

func take_hit_from(damage: int, shooter: Vector3) -> void:
    var line := shooter - global_position
    line.y = 0.0
    if line.length_squared() < 0.0001:
        super.take_hit(damage)
        return
    var forward: Vector3 = -global_basis.z
    forward.y = 0.0
    if forward.dot(line.normalized()) > 0.35:
        absorbed_hits += 1
        super.take_hit(maxi(1,int(ceil(float(damage)*0.22))))
    else:
        super.take_hit(damage)
    if hit_points > 0:
        action_lock = 0.2
        _play("Hit")
