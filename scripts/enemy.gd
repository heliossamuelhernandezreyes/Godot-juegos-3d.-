extends CharacterBody3D
const SENTINEL_MESH = preload("res://assets/models/reaver_sentry.obj")
## Perseguidor básico: separación de navegación global y steering queda como prueba futura.
var target
var director
var hit_points := 42
var speed := 3.7
var contact_cooldown := 0.0
var motion_time := 0.0
var core_mesh: MeshInstance3D

func _ready() -> void:
    add_to_group("enemies")
    collision_layer = 1
    collision_mask = 1
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.48
    capsule.height = 1.7
    collider.shape = capsule
    add_child(collider)
    core_mesh = MeshInstance3D.new()
    core_mesh.name = "REAVER - asset 3D original"
    core_mesh.mesh = SENTINEL_MESH
    add_child(core_mesh)

func _physics_process(delta: float) -> void:
    if not is_instance_valid(target) or target.health <= 0:
        return
    motion_time += delta
    contact_cooldown = maxf(0.0, contact_cooldown - delta)
    var offset: Vector3 = target.global_position - global_position
    offset.y = 0.0
    var distance := offset.length()
    var dir := offset.normalized() if distance > 0.01 else Vector3.ZERO
    if distance > 1.15:
        velocity.x = dir.x * speed
        velocity.z = dir.z * speed
    else:
        velocity.x = 0.0
        velocity.z = 0.0
    if not is_on_floor():
        velocity.y -= 24.0 * delta
    else:
        velocity.y = -0.5
    move_and_slide()
    if distance < 1.55 and contact_cooldown <= 0.0:
        contact_cooldown = 0.95
        target.take_damage(12)
    if dir.length_squared() > 0.1:
        look_at(global_position + dir, Vector3.UP)
    if is_instance_valid(core_mesh):
        core_mesh.position.y = sin(motion_time * 6.5) * 0.10
        core_mesh.rotation.z = sin(motion_time * 4.2) * 0.045

func take_hit(damage: int) -> void:
    if hit_points <= 0:
        return
    hit_points -= damage
    if hit_points <= 0:
        if is_instance_valid(director):
            director.register_kill()
        queue_free()
