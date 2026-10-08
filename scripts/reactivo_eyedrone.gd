extends "res://scripts/animated_reaver.gd"
## Reactivo EyeDrone: LOS-gated windup and explicit counterplay instead of instant damage.
## Leaves legacy 0.7 drone tests and independent asset import intact.
const WINDUP := 0.72
var windup_active := false
var windup_remaining := 0.0
var projectile_target := Vector3.ZERO
var charged_shots := 0

func _try_ranged_attack() -> void:
    if target == null or not is_instance_valid(target) or target.health <= 0:
        windup_active = false
        return
    if windup_active:
        if not _has_direct_sight() or global_position.distance_to(target.global_position) > 15.0:
            windup_active = false
            windup_remaining = 0.0
            ranged_timer = 0.5
            return
        windup_remaining -= get_physics_process_delta_time()
        if windup_remaining <= 0.0:
            windup_active = false
            ranged_timer = 2.25
            action_time = 0.28
            _change_animation("Attack")
            charged_shots += 1
            var previous: int = target.health
            target.take_damage(9)
            if director != null:
                if director.has_method("register_enemy_laser"):
                    director.register_enemy_laser(global_position + Vector3(0, 0.25, 0), target.global_position + Vector3(0, 0.2, 0))
                if target.health < previous and director.has_method("register_damage_feedback"):
                    director.register_damage_feedback()
        return
    if ranged_timer > 0.0 or action_time > 0.0:
        return
    var distance: float = global_position.distance_to(target.global_position)
    if distance < 2.4 or distance > 15.0 or not _has_direct_sight():
        return
    windup_active = true
    windup_remaining = WINDUP
    action_time = WINDUP
    projectile_target = target.global_position
    _change_animation("Charging")
    if director != null and director.has_method("register_enemy_telegraph"):
        director.register_enemy_telegraph(global_position + Vector3(0, 0.3, 0), projectile_target + Vector3(0, 0.2, 0), WINDUP)
