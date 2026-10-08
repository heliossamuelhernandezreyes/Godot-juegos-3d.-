extends "res://scripts/enemy.gd"
## Bulwark 0.7: temporary readable armored geometry, independent frontal damage model.
## Not a production AAA asset. Direction is the agent's actual facing, not camera-facing.
var shield_mesh: MeshInstance3D
var absorbed_hits := 0

func _ready() -> void:
    hit_points = 175
    speed = 2.25
    super._ready()
    core_mesh.visible = false
    var shell := MeshInstance3D.new()
    shell.name = "Bulwark | provisional armored body"
    var body := BoxMesh.new()
    body.size = Vector3(1.45, 1.85, 0.86)
    shell.mesh = body
    shell.position.y = 0.04
    var matte := StandardMaterial3D.new()
    matte.albedo_color = Color("#546371")
    matte.metallic = 0.7
    matte.roughness = 0.37
    shell.material_override = matte
    add_child(shell)
    shield_mesh = MeshInstance3D.new()
    shield_mesh.name = "Bulwark | forward frontal shield"
    var armor := BoxMesh.new()
    armor.size = Vector3(1.70, 1.52, 0.20)
    shield_mesh.mesh = armor
    shield_mesh.position = Vector3(0, 0.15, -0.65)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#a9783c")
    material.metallic = 0.82
    material.roughness = 0.3
    shield_mesh.material_override = material
    add_child(shield_mesh)

func take_hit_from(damage: int, shooter: Vector3) -> void:
    var line := shooter - global_position
    line.y = 0.0
    if line.length_squared() < 0.0001:
        super.take_hit(damage)
        return
    # Character forward in Godot is -Z, matching look_at target.
    var forward: Vector3 = -global_basis.z
    forward.y = 0.0
    if forward.dot(line.normalized()) > 0.35:
        absorbed_hits += 1
        super.take_hit(maxi(1, int(ceil(float(damage) * 0.22))))
    else:
        super.take_hit(damage)
