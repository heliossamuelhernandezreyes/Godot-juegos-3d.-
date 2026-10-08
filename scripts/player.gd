extends CharacterBody3D
## Personaje sin dependencias de recursos externos. El origen está a ~1 m del suelo.
signal health_changed(current: int, maximum: int)

const WALK_SPEED := 9.0
const DASH_SPEED := 24.0
const DASH_DURATION := 0.19
const DASH_COOLDOWN := 1.6
const GRAVITY := 24.0
const BODY_MESH = preload("res://assets/models/vanguard_body.obj")
const ARM_MESH = preload("res://assets/models/vanguard_arm.obj")
const LEG_MESH = preload("res://assets/models/vanguard_leg.obj")
const RIFLE_MESH = preload("res://assets/models/vanguard_rifle.obj")

var max_health := 100
var health := 100
var touch_axis := Vector2.ZERO
var aim_direction := Vector3.FORWARD
var mobile_firing := false
var dash_queued := false
var dash_remaining := 0.0
var dash_cooldown := 0.0
var invulnerability := 0.0
var dash_vector := Vector3.FORWARD
var visual_root: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var animation_clock := 0.0

func _ready() -> void:
    name = "Piloto"
    collision_layer = 1
    collision_mask = 1
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.43
    capsule.height = 1.8
    collider.shape = capsule
    add_child(collider)

    _build_mech_visual()
    health_changed.emit(health, max_health)

func _build_mech_visual() -> void:
    visual_root = Node3D.new()
    visual_root.name = "VANGUARD - rig de piezas OBJ"
    add_child(visual_root)
    _piece(visual_root, BODY_MESH, "Armadura principal", Vector3.ZERO)
    left_leg = Node3D.new()
    left_leg.name = "Pierna izquierda - pivote"
    left_leg.position = Vector3(-0.23, -0.14, 0)
    visual_root.add_child(left_leg)
    _piece(left_leg, LEG_MESH, "Malla pierna izquierda", Vector3.ZERO)
    right_leg = Node3D.new()
    right_leg.name = "Pierna derecha - pivote"
    right_leg.position = Vector3(0.23, -0.14, 0)
    visual_root.add_child(right_leg)
    _piece(right_leg, LEG_MESH, "Malla pierna derecha", Vector3.ZERO)
    left_arm = Node3D.new()
    left_arm.name = "Brazo izquierdo - pivote"
    left_arm.position = Vector3(-0.55, 0.40, 0)
    visual_root.add_child(left_arm)
    _piece(left_arm, ARM_MESH, "Malla brazo izquierdo", Vector3.ZERO)
    right_arm = Node3D.new()
    right_arm.name = "Brazo derecho - pivote"
    right_arm.position = Vector3(0.55, 0.40, 0)
    visual_root.add_child(right_arm)
    _piece(right_arm, ARM_MESH, "Malla brazo derecho", Vector3.ZERO)
    _piece(right_arm, RIFLE_MESH, "Rifle de asalto", Vector3(-0.12, -0.43, -0.30))

func _piece(parent: Node3D, asset: Mesh, label: String, at: Vector3) -> void:
    var instance := MeshInstance3D.new()
    instance.name = label
    instance.mesh = asset
    instance.position = at
    parent.add_child(instance)

func _animate_suit(delta: float, moving: bool) -> void:
    if visual_root == null:
        return
    var gait := clampf(Vector2(velocity.x, velocity.z).length() / WALK_SPEED, 0.0, 1.0)
    if moving:
        animation_clock += delta * (11.0 if dash_remaining <= 0.0 else 19.0)
    var leg_angle := sin(animation_clock) * 0.48 * gait
    left_leg.rotation.x = lerpf(left_leg.rotation.x, leg_angle, minf(delta * 12.0, 1.0))
    right_leg.rotation.x = lerpf(right_leg.rotation.x, -leg_angle, minf(delta * 12.0, 1.0))
    left_arm.rotation.x = lerpf(left_arm.rotation.x, -0.25 - leg_angle * 0.42, minf(delta * 11.0, 1.0))
    right_arm.rotation.x = lerpf(right_arm.rotation.x, -0.35 + leg_angle * 0.3, minf(delta * 11.0, 1.0))
    visual_root.position.y = sin(animation_clock * 2.0) * 0.035 * gait
    visual_root.rotation.x = lerpf(visual_root.rotation.x, -0.11 if dash_remaining > 0.0 else 0.0, minf(delta * 9.0, 1.0))

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
    _animate_suit(delta, direction.length_squared() > 0.01)
    if aim_direction.length_squared() > 0.001:
        look_at(global_position + aim_direction, Vector3.UP)

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
    health_changed.emit(health, max_health)
