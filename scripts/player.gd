extends CharacterBody3D
## Personaje sin dependencias de recursos externos. El origen está a ~1 m del suelo.
signal health_changed(current: int, maximum: int)

const WALK_SPEED := 9.0
const DASH_SPEED := 24.0
const DASH_DURATION := 0.19
const DASH_COOLDOWN := 1.6
const GRAVITY := 24.0

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

    var mesh := MeshInstance3D.new()
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.43
    body_mesh.height = 1.8
    mesh.mesh = body_mesh
    var suit := StandardMaterial3D.new()
    suit.albedo_color = Color("#76d9ff")
    suit.metallic = 0.6
    suit.roughness = 0.32
    suit.emission_enabled = true
    suit.emission = Color("#1b7699")
    suit.emission_energy_multiplier = 0.65
    mesh.material_override = suit
    add_child(mesh)

    var visor := MeshInstance3D.new()
    var visor_mesh := BoxMesh.new()
    visor_mesh.size = Vector3(0.48, 0.20, 0.16)
    visor.mesh = visor_mesh
    visor.position = Vector3(0, 0.43, -0.40)
    var glow := StandardMaterial3D.new()
    glow.albedo_color = Color("#fcffff")
    glow.emission_enabled = true
    glow.emission = Color("#00dafa")
    glow.emission_energy_multiplier = 2.8
    visor.material_override = glow
    add_child(visor)
    health_changed.emit(health, max_health)

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
