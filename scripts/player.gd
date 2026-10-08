extends CharacterBody3D
## FISURA Vanguard 0.5: skinned humanoid, deterministic gameplay collider.
## ARCONT principle: Skeleton3D/AnimationPlayer are visual, CharacterBody3D remains authoritative.
signal health_changed(current: int, maximum: int)
signal dash_started

const WALK_SPEED := 9.0
const DASH_SPEED := 24.0
const DASH_DURATION := 0.19
const DASH_COOLDOWN := 1.6
const GRAVITY := 24.0
const VANGUARD_SCENE = preload("res://assets/vendor/quaternius/vanguard_spacesuit/Spacesuit.gltf")
const RIFLE_SCENE = preload("res://assets/vendor/quaternius/scifi_essentials/Gun_Rifle.gltf")
const AIM_MODIFIER = preload("res://scripts/vanguard_aim_modifier.gd")
const LOCOMOTION := ["Idle_Gun", "Run", "Run_Back", "Run_Left", "Run_Right", "Walk", "Run_Shoot"]

var max_health := 100
var health := 100
var touch_axis := Vector2.ZERO
var aim_direction := Vector3.FORWARD
var mobile_firing := false
var dash_queued := false
var dash_remaining := 0.0
var dash_cooldown := 0.0
var dash_vector := Vector3.FORWARD
var invulnerability := 0.0
var visual_root: Node3D
var humanoid: Node3D
var rig_animation: AnimationPlayer
var humanoid_skeleton: Skeleton3D
var selected_clip := ""
var animation_lock := 0.0
var weapon_active := 0.0
var last_move := Vector3.ZERO
var fire_events := 0
var visual_ready := false
var aim_pitch := 0.0
var aim_modifier

func _ready() -> void:
    name = "Vanguard"
    collision_layer = 1
    collision_mask = 1
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.43
    capsule.height = 1.8
    collider.shape = capsule
    add_child(collider)
    _build_skeletal_vanguard()
    health_changed.emit(health, max_health)

func _build_skeletal_vanguard() -> void:
    visual_root = Node3D.new()
    visual_root.name = "VANGUARD | Quaternius CC0 skeletal visual"
    add_child(visual_root)
    humanoid = VANGUARD_SCENE.instantiate()
    humanoid.name = "Spacesuit | skinned mesh"
    # The source model has its feet at its own origin; CharacterBody3D origin is centered.
    humanoid.position = Vector3(0, -0.88, 0)
    visual_root.add_child(humanoid)
    rig_animation = _find_animator(humanoid)
    humanoid_skeleton = _find_skeleton(humanoid)
    if rig_animation == null or humanoid_skeleton == null:
        push_error("VANGUARD: animated model missing Skeleton3D or AnimationPlayer")
        return
    for clip in LOCOMOTION:
        if rig_animation.has_animation(clip):
            var motion: Animation = rig_animation.get_animation(clip)
            motion.loop_mode = Animation.LOOP_LINEAR
    _play_clip("Idle_Gun")
    # Separate gun mesh is attached only if a matching right-hand bone is present.
    _attach_rifle_to_hand()
    aim_modifier = AIM_MODIFIER.new()
    aim_modifier.name = "ARCONT additive upper-body aim and recoil"
    humanoid_skeleton.add_child(aim_modifier)
    visual_ready = true
    print("VANGUARD RIG READY bones=%d clips=%d" %
        [humanoid_skeleton.get_bone_count(), rig_animation.get_animation_list().size()])

func _find_animator(root_node: Node) -> AnimationPlayer:
    if root_node is AnimationPlayer:
        return root_node
    for child in root_node.get_children():
        var result := _find_animator(child)
        if result != null:
            return result
    return null

func _find_skeleton(root_node: Node) -> Skeleton3D:
    if root_node is Skeleton3D:
        return root_node
    for child in root_node.get_children():
        var result := _find_skeleton(child)
        if result != null:
            return result
    return null

func _attach_rifle_to_hand() -> void:
    if humanoid_skeleton == null:
        return
    var bone_id := -1
    for i in range(humanoid_skeleton.get_bone_count()):
        var name = humanoid_skeleton.get_bone_name(i).to_lower()
        if (name.contains("hand") and (name.contains("right") or name.contains(".r") or name.ends_with("_r"))) or name == "r_hand":
            bone_id = i
            break
    if bone_id < 0:
        print("VANGUARD: no compatible right-hand attachment bone; intrinsic gun animation retained")
        return
    var mount := BoneAttachment3D.new()
    mount.name = "Hand-held PBR rifle attachment"
    mount.bone_idx = bone_id
    humanoid_skeleton.add_child(mount)
    var rifle: Node3D = RIFLE_SCENE.instantiate()
    rifle.name = "Quaternius CC0 Rifle"
    # Local adjustment is deliberately separate from the imported animation/rig.
    rifle.position = Vector3(0.0, 0.0, -0.12)
    rifle.rotation_degrees = Vector3(-90, 0, 0)
    rifle.scale = Vector3.ONE * 0.78
    mount.add_child(rifle)

func _play_clip(clip: String, blend: float = 0.15) -> void:
    if rig_animation == null or selected_clip == clip or not rig_animation.has_animation(clip):
        return
    selected_clip = clip
    rig_animation.play(clip, blend)

func on_weapon_fired() -> void:
    fire_events += 1
    weapon_active = 0.24
    if aim_modifier != null:
        aim_modifier.trigger_recoil()
    if health > 0 and dash_remaining <= 0.0 and animation_lock <= 0.0:
        var moving := Vector2(velocity.x, velocity.z).length() > 1.0
        _play_clip("Run_Shoot" if moving else "Gun_Shoot", 0.10)

func _update_visual_state(delta: float) -> void:
    if not visual_ready:
        return
    if aim_modifier != null:
        var local_velocity := global_basis.inverse() * Vector3(velocity.x, 0.0, velocity.z)
        var lateral := clampf(local_velocity.x / WALK_SPEED, -1.0, 1.0)
        aim_modifier.set_aim_motion(wants_to_fire() or weapon_active > 0.0, aim_pitch, -lateral * 0.11)
    animation_lock = maxf(0.0, animation_lock - delta)
    weapon_active = maxf(0.0, weapon_active - delta)
    if health <= 0:
        _play_clip("Death", 0.15)
        return
    if dash_remaining > 0.0:
        if selected_clip != "Roll":
            _play_clip("Roll", 0.06)
            animation_lock = 0.43
        return
    if animation_lock > 0.0:
        return
    var movement := Vector3(velocity.x, 0.0, velocity.z)
    if movement.length_squared() < 0.30:
        _play_clip("Gun_Shoot" if weapon_active > 0.0 else "Idle_Gun")
        return
    if weapon_active > 0.0:
        _play_clip("Run_Shoot", 0.10)
        return
    var local_movement := global_basis.inverse() * movement.normalized()
    # Directional clips remove backward/sideways moonwalking.
    if local_movement.z > 0.42:
        _play_clip("Run_Back")
    elif local_movement.x > 0.53:
        _play_clip("Run_Right")
    elif local_movement.x < -0.53:
        _play_clip("Run_Left")
    else:
        _play_clip("Run")

func _physics_process(delta: float) -> void:
    dash_cooldown = maxf(0.0, dash_cooldown - delta)
    invulnerability = maxf(0.0, invulnerability - delta)
    var motion := _movement_axis()
    var direction := Vector3(motion.x, 0.0, motion.y).normalized()
    if direction.length_squared() > 0.01:
        dash_vector = direction
    elif aim_direction.length_squared() > 0.01:
        dash_vector = aim_direction.normalized()
    if (dash_queued or Input.is_key_pressed(KEY_SHIFT)) and dash_cooldown <= 0.0:
        dash_remaining = DASH_DURATION
        dash_cooldown = DASH_COOLDOWN
        invulnerability = DASH_DURATION + 0.12
        animation_lock = 0.0
        selected_clip = ""
        dash_started.emit()
    dash_queued = false

    if dash_remaining > 0.0:
        velocity.x = dash_vector.x * DASH_SPEED
        velocity.z = dash_vector.z * DASH_SPEED
        dash_remaining -= delta
    else:
        velocity.x = direction.x * WALK_SPEED
        velocity.z = direction.z * WALK_SPEED
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = -0.5
    move_and_slide()
    if aim_direction.length_squared() > 0.001:
        look_at(global_position + aim_direction, Vector3.UP)
    _update_visual_state(delta)

func _movement_axis() -> Vector2:
    if touch_axis.length_squared() > 0.02:
        return touch_axis.limit_length(1.0)
    var axis := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        axis.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        axis.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        axis.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        axis.y += 1.0
    return axis.normalized()

func wants_to_fire() -> bool:
    return mobile_firing or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE)

func request_dash() -> void:
    dash_queued = true

func take_damage(amount: int) -> void:
    if invulnerability > 0.0 or health <= 0:
        return
    health = maxi(0, health - amount)
    invulnerability = 0.45
    if health > 0:
        animation_lock = 0.24
        _play_clip("HitRecieve", 0.06)
    else:
        animation_lock = 0.0
        _play_clip("Death", 0.07)
    health_changed.emit(health, max_health)
