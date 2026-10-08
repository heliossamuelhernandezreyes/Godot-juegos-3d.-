extends CharacterBody3D
## FISURA tactical Reaver: LOS, staggered grid routing, local separation, hit feedback.
const SENTINEL_MESH = preload("res://assets/models/reaver_sentry.obj")

var target
var director
var hit_points := 42
var speed := 3.7
var contact_cooldown := 0.0
var motion_time := 0.0
var core_mesh: MeshInstance3D
var steering := Vector3.ZERO
var path_refresh := 0.0
var flash_timer := 0.0
var flash_material: StandardMaterial3D

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
    core_mesh.name = "REAVER - PBR metal carcasa"
    core_mesh.mesh = SENTINEL_MESH
    add_child(core_mesh)

func _has_direct_sight() -> bool:
    if not is_instance_valid(target):
        return false
    var start := global_position + Vector3(0, 0.18, 0)
    var destination: Vector3 = target.global_position + Vector3(0, 0.18, 0)
    var query := PhysicsRayQueryParameters3D.create(start, destination)
    query.exclude = [get_rid()]
    var result := get_world_3d().direct_space_state.intersect_ray(query)
    return not result.is_empty() and result.get("collider") == target

func _neighbor_separation() -> Vector3:
    var away := Vector3.ZERO
    for actor in get_tree().get_nodes_in_group("enemies"):
        if actor == self or not is_instance_valid(actor):
            continue
        var gap: Vector3 = global_position - actor.global_position
        gap.y = 0
        var dist := gap.length()
        if dist > 0.04 and dist < 1.8:
            away += gap.normalized() * (1.8 - dist)
    return away

func _physics_process(delta: float) -> void:
    if not is_instance_valid(target) or target.health <= 0:
        return
    motion_time += delta
    contact_cooldown = maxf(0.0, contact_cooldown - delta)
    path_refresh -= delta
    flash_timer = maxf(0.0, flash_timer - delta)
    if flash_timer <= 0.0 and core_mesh.material_override != null:
        core_mesh.material_override = null

    var offset: Vector3 = target.global_position - global_position
    offset.y = 0
    var distance := offset.length()
    var direct_heading := offset.normalized() if distance > 0.01 else Vector3.ZERO
    if path_refresh <= 0.0:
        path_refresh = 0.30 + float(get_instance_id() % 6) * 0.045
        if _has_direct_sight():
            steering = direct_heading
        elif director != null and director.tactical_nav != null:
            steering = director.tactical_nav.next_direction(global_position, target.global_position)
        else:
            steering = Vector3.ZERO

    var separation := _neighbor_separation()
    var final_heading: Vector3 = steering + separation * 0.45
    final_heading.y = 0
    final_heading = final_heading.normalized()
    if distance > 1.45 and final_heading.length_squared() > 0.02:
        var desired := final_heading * speed
        velocity.x = move_toward(velocity.x, desired.x, delta * 22.0)
        velocity.z = move_toward(velocity.z, desired.z, delta * 22.0)
    else:
        velocity.x = move_toward(velocity.x, 0.0, delta * 18.0)
        velocity.z = move_toward(velocity.z, 0.0, delta * 18.0)
    if not is_on_floor():
        velocity.y -= 24.0 * delta
    else:
        velocity.y = -0.5
    move_and_slide()
    if distance < 1.55 and contact_cooldown <= 0.0 and _has_direct_sight():
        contact_cooldown = 0.95
        target.take_damage(12)
        if director != null and director.has_method("register_damage_feedback"):
            director.register_damage_feedback()
    if final_heading.length_squared() > 0.1:
        look_at(global_position + final_heading, Vector3.UP)
    if is_instance_valid(core_mesh):
        core_mesh.position.y = sin(motion_time * 6.5) * 0.10
        core_mesh.rotation.z = sin(motion_time * 4.2) * 0.045

func take_hit(damage: int) -> void:
    if hit_points <= 0:
        return
    hit_points -= damage
    flash_timer = 0.14
    if flash_material == null:
        flash_material = StandardMaterial3D.new()
        flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        flash_material.albedo_color = Color("#ffb98e")
        flash_material.emission_enabled = true
        flash_material.emission = Color("#ff502c")
        flash_material.emission_energy_multiplier = 3.4
    core_mesh.material_override = flash_material
    if director != null and director.has_method("register_hit_feedback"):
        director.register_hit_feedback(global_position)
    if hit_points <= 0:
        if is_instance_valid(director):
            director.register_kill()
        queue_free()
