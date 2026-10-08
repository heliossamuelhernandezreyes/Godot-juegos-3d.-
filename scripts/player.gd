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
const MOVE_ACCELERATION := 64.0
const MOVE_BRAKING := 78.0
const COVER_ENTER_GAP := 1.95
const COVER_EXIT_GAP := 2.25
const VANGUARD_SCENE = preload("res://assets/vendor/quaternius/vanguard_spacesuit/Spacesuit.gltf")
const RIFLE_SCENE = preload("res://assets/vendor/quaternius/scifi_essentials/Gun_Rifle.gltf")
const AIM_MODIFIER = preload("res://scripts/vanguard_aim_modifier.gd")
const LOCOMOTION := ["Idle_Gun", "Idle_Gun_Pointing", "Run", "Run_Back", "Run_Left", "Run_Right", "Walk", "Run_Shoot"]

var max_health := 100
var health := 100
var touch_axis := Vector2.ZERO
var camera_yaw := 0.0
var mobile_input_mode := OS.has_feature("mobile")
var aim_direction := Vector3.FORWARD
var mobile_firing := false
var dash_queued := false
var dash_remaining := 0.0
var dash_cooldown := 0.0
var dash_vector := Vector3.FORWARD
var cover_zones: Array = []
var in_cover := false
var cover_id := ""
var cover_normal := Vector3.ZERO
var cover_guide: Dictionary = {}
var cover_requests := 0
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
    # Quaternius mesh front uses +Z; gameplay CharacterBody3D forward uses -Z.
    # Author this rest-space facing conversion once, before any native animations.
    humanoid.rotation.y = PI
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
    _play_clip("Idle_Gun_Pointing")
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
        # The shipped Quaternius Spacesuit rig calls its grip bone "Wrist.R",
        # not "RightHand". This is source-audited against all 62 imported bones.
        bone_id = humanoid_skeleton.find_bone("Wrist.R")
    if bone_id < 0:
        print("VANGUARD: no compatible grip bone; intrinsic gun animation retained")
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
        if in_cover and rig_animation.has_animation("Crouch"):
            _play_clip("Crouch")
        else:
            _play_clip("Gun_Shoot" if weapon_active > 0.0 else "Idle_Gun_Pointing")
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
    _validate_cover()
    var motion := _movement_axis()
    var direction := (Basis(Vector3.UP, camera_yaw) * Vector3(motion.x, 0.0, motion.y)).normalized()
    if in_cover and direction.length_squared() > 0.001:
        if direction.dot(cover_normal) > 0.72:
            _leave_cover() # deliberately push away from a wall to disengage
        else:
            # Follow the measured wall tangent and correct into the cover slot.
            direction = (direction - cover_normal * direction.dot(cover_normal)).normalized()
    if direction.length_squared() > 0.01:
        dash_vector = direction
    elif aim_direction.length_squared() > 0.01:
        dash_vector = aim_direction.normalized()
    if (dash_queued or Input.is_key_pressed(KEY_SHIFT)) and dash_cooldown <= 0.0:
        _leave_cover()
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
        var target_speed := WALK_SPEED * (0.56 if in_cover else 1.0)
        var target_velocity := direction * target_speed
        if in_cover:
            var correction := (_cover_snap_point() - global_position).dot(cover_normal)
            target_velocity += cover_normal * clampf(correction * 10.0, -4.0, 4.0)
        var planar := Vector3(velocity.x, 0.0, velocity.z)
        var acceleration := MOVE_ACCELERATION if direction.length_squared() > 0.01 else MOVE_BRAKING
        planar = planar.move_toward(target_velocity, acceleration * delta)
        velocity.x = planar.x
        velocity.z = planar.z
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = -0.5
    move_and_slide()
    if aim_direction.length_squared() > 0.001:
        look_at(global_position + aim_direction, Vector3.UP)
    if visual_root != null:
        # Animation-safe visual brace, without changing the authoritative capsule.
        # Preserve feet height when lowering the silhouette. Imported Crouch (if any) owns the detailed pose.
        visual_root.scale.y = lerpf(visual_root.scale.y, 0.85 if in_cover else 1.0, minf(1.0, delta * 9.0))
        visual_root.position.y = lerpf(visual_root.position.y, -0.13 if in_cover else 0.0, minf(1.0, delta * 9.0))
        visual_root.rotation.z = lerpf(visual_root.rotation.z, -0.09 * cover_normal.x if in_cover else 0.0, minf(1.0, delta * 8.0))
    _update_visual_state(delta)

func configure_cover_zones(guides: Array, props: Array = []) -> void:
    cover_zones.clear()
    for guide in guides:
        if typeof(guide) == TYPE_DICTIONARY and str(guide.get("kind", "")) == "cover":
            cover_zones.append(guide)
    # Crates already carry StaticBody3D / BoxShape3D in art_stage.gd.
    # A decorative mesh without a physics collider never becomes cover.
    for prop in props:
        if typeof(prop) == TYPE_DICTIONARY and str(prop.get("kind", "")) == "crate":
            cover_zones.append({
                "id": prop["id"], "position": prop["position"],
                "size": prop["collider_size"], "kind": "cover"
            })
    _leave_cover()

func _nearest_cover() -> Dictionary:
    var best: Dictionary = {}
    var best_gap := INF
    for guide in cover_zones:
        var raw_pos: Array = guide["position"]
        var raw_size: Array = guide["size"]
        var ox: float = global_position.x - float(raw_pos[0])
        var oz: float = global_position.z - float(raw_pos[2])
        var edge_x: float = absf(ox) - float(raw_size[0]) * 0.5
        var edge_z: float = absf(oz) - float(raw_size[2]) * 0.5
        var gap_x := maxf(edge_x, 0.0)
        var gap_z := maxf(edge_z, 0.0)
        var gap := Vector2(gap_x, gap_z).length()
        if gap < 0.42 or gap > COVER_EXIT_GAP or gap >= best_gap:
            continue
        var normal := Vector3.ZERO
        if gap_x > gap_z:
            normal.x = 1.0 if ox >= 0.0 else -1.0
        else:
            normal.z = 1.0 if oz >= 0.0 else -1.0
        best = {"id":str(guide["id"]),"normal":normal,"gap":gap,"guide":guide}
        best_gap = gap
    return best

func can_take_cover() -> bool:
    if health <= 0 or dash_remaining > 0.0:
        return false
    var nearby := _nearest_cover()
    return not nearby.is_empty() and float(nearby["gap"]) <= COVER_ENTER_GAP

func request_cover_toggle() -> bool:
    cover_requests += 1
    if in_cover:
        _leave_cover()
        return false
    if not can_take_cover():
        return false
    var nearby := _nearest_cover()
    in_cover = true
    cover_id = str(nearby["id"])
    cover_normal = nearby["normal"]
    cover_guide = nearby["guide"]
    return true

func _leave_cover() -> void:
    in_cover = false
    cover_id = ""
    cover_normal = Vector3.ZERO
    cover_guide = {}

func _cover_snap_point() -> Vector3:
    if cover_guide.is_empty():
        return global_position
    var raw_pos: Array = cover_guide["position"]
    var raw_size: Array = cover_guide["size"]
    var p := Vector3(float(raw_pos[0]), global_position.y, float(raw_pos[2]))
    if absf(cover_normal.x) > 0.5:
        p.x += cover_normal.x * (float(raw_size[0]) * 0.5 + 0.60)
        p.z = clampf(global_position.z, float(raw_pos[2]) - float(raw_size[2]) * 0.5 + 0.30,
            float(raw_pos[2]) + float(raw_size[2]) * 0.5 - 0.30)
    else:
        p.z += cover_normal.z * (float(raw_size[2]) * 0.5 + 0.60)
        p.x = clampf(global_position.x, float(raw_pos[0]) - float(raw_size[0]) * 0.5 + 0.30,
            float(raw_pos[0]) + float(raw_size[0]) * 0.5 - 0.30)
    return p

func _validate_cover() -> void:
    if not in_cover:
        return
    var nearby := _nearest_cover()
    if nearby.is_empty() or str(nearby["id"]) != cover_id:
        _leave_cover()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q:
        request_cover_toggle()

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
    # Android emulates a mouse click for a touch on some builds. A screen touch
    # is never a shot. Only the explicit FIRE button controls mobile_firing.
    if mobile_input_mode:
        return mobile_firing
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
