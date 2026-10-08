extends CharacterBody3D
## FISURA Vanguard 0.5: skinned humanoid, deterministic gameplay collider.
## ARCONT principle: Skeleton3D/AnimationPlayer are visual, CharacterBody3D remains authoritative.
signal health_changed(current: int, maximum: int)
signal dash_started
signal cover_entered
signal vault_started
signal vault_landed

const WALK_SPEED := 9.0
const DASH_SPEED := 24.0
const DASH_DURATION := 0.19
const DASH_COOLDOWN := 1.6
const GRAVITY := 24.0
const MOVE_ACCELERATION := 64.0
const MOVE_BRAKING := 78.0
const COVER_ENTER_GAP := 1.95
const COVER_EXIT_GAP := 2.25
const VAULT_TIME := 0.72
const VAULT_CAPSULE_CLEARANCE := 1.15
const VAULT_LANDING_GAP := 0.70
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
var cover_blend := 0.0
var vault_active := false
var vault_elapsed := 0.0
var vault_from := Vector3.ZERO
var vault_to := Vector3.ZERO
var vault_top_y := 0.0
var vault_start_height := 0.0
var vault_completed := 0
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
    if vault_active:
        # Use a native jump action if the source rig contains one.
        if rig_animation.has_animation("Jump_Gun"):
            _play_clip("Jump_Gun", 0.08)
        elif rig_animation.has_animation("Jump"):
            _play_clip("Jump", 0.08)
        else:
            _play_clip("Idle_Gun_Pointing", 0.12)
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
    cover_blend = move_toward(cover_blend, 1.0 if in_cover and not wants_to_fire() else 0.0, delta * 6.0)
    if vault_active:
        _advance_vault(delta)
        _update_visual_state(delta)
        return
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
        visual_root.rotation.x = lerpf(visual_root.rotation.x, 0.0, minf(1.0, delta * 9.0))
        visual_root.scale.y = lerpf(visual_root.scale.y, 1.0 - cover_blend * 0.15, minf(1.0, delta * 12.0))
        visual_root.position.y = lerpf(visual_root.position.y, -0.13 * cover_blend, minf(1.0, delta * 12.0))
        var lean := -0.17 * cover_normal.x if in_cover and wants_to_fire() else -0.09 * cover_normal.x * cover_blend
        visual_root.rotation.z = lerpf(visual_root.rotation.z, lean, minf(1.0, delta * 10.0))
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
    if health <= 0 or dash_remaining > 0.0 or vault_active:
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
    cover_entered.emit()
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

func can_vault() -> bool:
    # Only short, physical cover (the source-authored 1.4m crates) can be vaulted.
    if not in_cover or vault_active or dash_remaining > 0.0 or cover_guide.is_empty():
        return false
    var shape_size: Array = cover_guide["size"]
    if float(shape_size[1]) > 1.60:
        return false
    var place: Array = cover_guide["position"]
    var center := Vector3(float(place[0]), float(place[1]), float(place[2]))
    var half_width := float(shape_size[0]) * 0.5 if absf(cover_normal.x) > 0.5 else float(shape_size[2]) * 0.5
    var landing := center - cover_normal * (half_width + VAULT_LANDING_GAP + 0.45)
    landing.y = global_position.y
    var roof_y := center.y + float(shape_size[1]) + VAULT_CAPSULE_CLEARANCE
    var rise := Vector3.UP * maxf(0.0, roof_y - global_position.y)
    var across := Vector3(landing.x - global_position.x, 0.0, landing.z - global_position.z)
    if rise.y < 0.35 or across.length() > 5.0:
        return false
    # Three physical clearance sweeps; do not vault into walls or under a roof.
    if test_move(global_transform, rise):
        return false
    var raised := global_transform.translated(rise)
    if test_move(raised, across):
        return false
    var far_raised := raised.translated(across)
    if test_move(far_raised, -rise * 0.90):
        return false
    return true

func request_vault() -> bool:
    if not can_vault():
        return false
    var center: Array = cover_guide["position"]
    var dims: Array = cover_guide["size"]
    var half_width := float(dims[0]) * 0.5 if absf(cover_normal.x) > 0.5 else float(dims[2]) * 0.5
    vault_from = global_position
    vault_to = Vector3(float(center[0]), global_position.y, float(center[2])) - cover_normal * (half_width + VAULT_LANDING_GAP + 0.45)
    vault_top_y = float(center[1]) + float(dims[1]) + VAULT_CAPSULE_CLEARANCE
    vault_start_height = global_position.y
    vault_elapsed = 0.0
    vault_active = true
    vault_started.emit()
    velocity = Vector3.ZERO
    animation_lock = 0.0
    selected_clip = ""
    _leave_cover()
    return true

func _advance_vault(delta: float) -> void:
    vault_elapsed = minf(VAULT_TIME, vault_elapsed + delta)
    var t := vault_elapsed / VAULT_TIME
    # Rise without horizontal translation; cross only above the obstacle; land
    # on the far side after all horizontal traversal has completed.
    var wanted := vault_from
    if t <= 0.27:
        wanted.y = lerpf(vault_start_height, vault_top_y, smoothstep(0.0, 0.27, t))
    elif t <= 0.73:
        var progress := smoothstep(0.27, 0.73, t)
        wanted = vault_from.lerp(vault_to, progress)
        wanted.y = vault_top_y
    else:
        wanted = vault_to
        wanted.y = lerpf(vault_top_y, vault_start_height, smoothstep(0.73, 1.0, t))
    # Visual action curve (not yet full-body IK). Does not alter the physical capsule.
    if visual_root != null:
        visual_root.scale.y = lerpf(visual_root.scale.y, 1.0, minf(1.0, delta * 16.0))
        visual_root.position.y = lerpf(visual_root.position.y, 0.0, minf(1.0, delta * 16.0))
        visual_root.rotation.z = lerpf(visual_root.rotation.z, 0.0, minf(1.0, delta * 16.0))
        visual_root.rotation.x = -0.17 * sin(t * PI)
    # Native collision sweep, no transform teleportation through cover geometry.
    var collision := move_and_collide(wanted - global_position)
    if collision != null and t < 0.95:
        vault_active = false
        velocity = Vector3.ZERO
        return
    if vault_elapsed >= VAULT_TIME:
        vault_active = false
        vault_completed += 1
        vault_landed.emit()
        velocity = Vector3.ZERO

func _validate_cover() -> void:
    if not in_cover:
        return
    var nearby := _nearest_cover()
    if nearby.is_empty() or str(nearby["id"]) != cover_id:
        _leave_cover()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_Q:
            request_cover_toggle()
        elif event.keycode == KEY_F:
            request_vault()

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
    if vault_active:
        return false
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
