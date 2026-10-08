extends "res://scripts/enemy.gd"
## Skinned Quaternius CC0 enemy built over proven ARCONT tactical collision behavior.
const QUAD_SCENE = preload("res://assets/vendor/quaternius/scifi_essentials/Enemy_QuadShell.gltf")
const EYE_SCENE = preload("res://assets/vendor/quaternius/scifi_essentials/Enemy_EyeDrone.gltf")

var asset_kind := "quad"
var rig: Node3D
var animation_player: AnimationPlayer
var selected_clip := ""
var action_time := 0.0
var ranged_timer := 1.7

func _ready() -> void:
    super._ready()
    if core_mesh != null:
        core_mesh.visible = false
    var resource: PackedScene = EYE_SCENE if asset_kind == "eye" else QUAD_SCENE
    rig = resource.instantiate()
    rig.name = "CC0 Quaternius " + asset_kind
    # Preserve game character collision as a distinct proxy from skinned geometry.
    rig.position.y = -0.68 if asset_kind == "eye" else -0.75
    rig.scale = Vector3.ONE * (0.92 if asset_kind == "eye" else 0.96)
    add_child(rig)
    animation_player = _animation_player(rig)
    if animation_player != null:
        _change_animation("Idle")
    else:
        push_warning("Missing imported Quaternius animation player " + asset_kind)

func _animation_player(node: Node) -> AnimationPlayer:
    if node is AnimationPlayer:
        return node
    for child in node.get_children():
        var found := _animation_player(child)
        if found != null:
            return found
    return null

func _change_animation(clip: String) -> void:
    if animation_player == null or selected_clip == clip:
        return
    var available := animation_player.get_animation_list()
    if not available.has(clip):
        return
    var sequence: Animation = animation_player.get_animation(clip)
    if sequence != null and clip in ["Idle", "Run", "Walk", "Look", "Charging"]:
        sequence.loop_mode = Animation.LOOP_LINEAR
    selected_clip = clip
    animation_player.play(clip, 0.12)

func _physics_process(delta: float) -> void:
    var before := contact_cooldown
    super._physics_process(delta)
    if rig == null or not is_instance_valid(rig):
        return
    action_time = maxf(0.0, action_time - delta)
    if asset_kind == "eye":
        ranged_timer = maxf(0.0, ranged_timer - delta)
        _try_ranged_attack()
    if before <= 0.0 and contact_cooldown > 0.8:
        action_time = 0.30
        _change_animation("Attack")
    elif action_time <= 0.0:
        var motion := Vector2(velocity.x, velocity.z).length()
        if motion > 2.0:
            _change_animation("Run" if asset_kind == "quad" else "Charging")
        elif motion > 0.12:
            _change_animation("Walk" if asset_kind == "quad" else "Look")
        else:
            _change_animation("Idle")
    if asset_kind == "eye":
        rig.position.y = -0.58 + sin(motion_time * 3.5) * 0.17

func _try_ranged_attack() -> void:
    if target == null or not is_instance_valid(target) or target.health <= 0:
        return
    if ranged_timer > 0.0 or action_time > 0.0:
        return
    var range_to_player: float = global_position.distance_to(target.global_position)
    if range_to_player < 2.4 or range_to_player > 15.0 or not _has_direct_sight():
        return
    ranged_timer = 2.3
    action_time = 0.28
    _change_animation("Attack")
    var previous_health: int = target.health
    target.take_damage(9)
    if director != null and director.has_method("register_enemy_laser"):
        director.register_enemy_laser(global_position + Vector3(0, 0.25, 0),target.global_position + Vector3(0, 0.2, 0))
    if target.health < previous_health and director != null:
        director.register_damage_feedback()

func take_hit(damage: int) -> void:
    action_time = 0.18
    _change_animation("Hit")
    super.take_hit(damage)
