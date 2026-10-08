extends CharacterBody3D
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
    var body := CapsuleMesh.new()
    body.radius = 0.48
    body.height = 1.7
    core_mesh.mesh = body
    var shell := StandardMaterial3D.new()
    shell.albedo_color = Color("#c44a53")
    shell.metallic = 0.35
    shell.roughness = 0.53
    shell.emission_enabled = true
    shell.emission = Color("#65202a")
    shell.emission_energy_multiplier = 0.5
    core_mesh.material_override = shell
    add_child(core_mesh)
    var eye := MeshInstance3D.new()
    var eye_mesh := BoxMesh.new()
    eye_mesh.size = Vector3(0.42, 0.18, 0.14)
    eye.mesh = eye_mesh
    eye.position = Vector3(0, 0.38, -0.45)
    var eye_mat := StandardMaterial3D.new()
    eye_mat.albedo_color = Color("#ffbd66")
    eye_mat.emission_enabled = true
    eye_mat.emission = Color("#ff5820")
    eye_mat.emission_energy_multiplier = 3.0
    eye.material_override = eye_mat
    add_child(eye)

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
        core_mesh.scale.x = 1.0 + sin(motion_time * 5.0) * 0.035

func take_hit(damage: int) -> void:
    if hit_points <= 0:
        return
    hit_points -= damage
    if hit_points <= 0:
        if is_instance_valid(director):
            director.register_kill()
        queue_free()
