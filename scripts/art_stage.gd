extends Node3D
## Art direction — distinct mesh assets, canonical level gameplay kept in map JSON.
## Mobile-first: instanced floor geometry and conservative realtime lights.
const TILE = preload("res://assets/models/armature_floor.obj")
const PILLAR = preload("res://assets/models/sentinel_pillar.obj")
const CRATE = preload("res://assets/models/armored_crate.obj")
const GATE = preload("res://assets/models/extraction_gate.obj")
const REACTOR = preload("res://assets/models/reactor_altar.obj")

var mesh_count := 0
var mesh_instances := 0
var point_lights := 0

func build(map_data: Dictionary, anchors: Dictionary) -> void:
    name = "Direccion artistica - Crisol"
    _floor_tiles(map_data)
    for x in [-17.0, 17.0]:
        for z in [-17.0, 17.0]:
            _static_prop("Pilar", PILLAR, Vector3(x, 0, z), Vector3(1.3, 4.0, 1.3))
    _static_prop("Cobertura N1", CRATE, Vector3(-12, 0, -4), Vector3(1.3, 1.3, 1.3))
    _static_prop("Cobertura N2", CRATE, Vector3(12, 0, 2), Vector3(1.3, 1.3, 1.3))
    _static_prop("Cobertura S1", CRATE, Vector3(-13, 0, 9), Vector3(1.3, 1.3, 1.3))
    _static_prop("Cobertura S2", CRATE, Vector3(14, 0, 12), Vector3(1.3, 1.3, 1.3))
    _static_prop("Cobertura O1", CRATE, Vector3(-4, 0, -13), Vector3(1.3, 1.3, 1.3))
    _static_prop("Cobertura E1", CRATE, Vector3(4, 0, 10), Vector3(1.3, 1.3, 1.3))
    _static_prop("Reactor", REACTOR, Vector3(0, 0, 0), Vector3(1.8, 2.0, 1.8))
    _display_asset("Portico", GATE, anchors["exit_portal"], 0.0)
    _lighting()
    _set_wall_detail()
    print("ART STAGE READY models=%d instances=%d lights=%d" % [mesh_count, mesh_instances, point_lights])

func _display_asset(label: String, mesh: Mesh, pos: Vector3, yaw: float = 0.0) -> MeshInstance3D:
    var visual := MeshInstance3D.new()
    visual.name = label
    visual.mesh = mesh
    visual.position = pos
    visual.rotation.y = yaw
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    add_child(visual)
    mesh_count += 1
    return visual

func _static_prop(label: String, mesh: Mesh, pos: Vector3, shape_size: Vector3) -> void:
    var body := StaticBody3D.new()
    body.name = label + " colision"
    body.position = pos
    add_child(body)
    var collision := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = shape_size
    collision.shape = box
    collision.position = Vector3(0, shape_size.y * 0.5, 0)
    body.add_child(collision)
    var visual := MeshInstance3D.new()
    visual.name = label + " mesh OBJ"
    visual.mesh = mesh
    body.add_child(visual)
    mesh_count += 1

func _floor_tiles(map_data: Dictionary) -> void:
    var width := float(map_data["bounds"]["width"])
    var depth := float(map_data["bounds"]["depth"])
    var x_count := int(floorf(width / 4.0))
    var z_count := int(floorf(depth / 4.0))
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = TILE
    multimesh.instance_count = x_count * z_count
    var index := 0
    for x in range(x_count):
        for z in range(z_count):
            var offset := Vector3(-width * 0.5 + 2.0 + x * 4.0, 0.0, -depth * 0.5 + 2.0 + z * 4.0)
            multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, offset))
            index += 1
    var batch := MultiMeshInstance3D.new()
    batch.name = "Suelo modular instanciado"
    batch.multimesh = multimesh
    add_child(batch)
    mesh_count += 1
    mesh_instances += index

func _lighting() -> void:
    _spot("Recorte cian", Vector3(-12, 7.5, -8), Color("#16b9dc"), 8.5, 27.0)
    _spot("Recorte ambar", Vector3(15, 7.5, 9), Color("#e98042"), 7.5, 27.0)
    _spot("Portal", Vector3(0, 6.0, -16), Color("#49e8ed"), 8.5, 16.0)
    _spot("Reactor central", Vector3(0, 5.0, 0), Color("#fa7340"), 5.0, 12.0)

func _spot(label: String, at: Vector3, color: Color, energy: float, reach: float) -> void:
    var light := OmniLight3D.new()
    light.name = label
    light.position = at
    light.light_color = color
    light.light_energy = energy * 0.35
    light.omni_range = reach
    light.shadow_enabled = false
    add_child(light)
    point_lights += 1

func _set_wall_detail() -> void:
    # Vertical fins break the original untextured silhouette without altering hitbox.
    var metal := StandardMaterial3D.new()
    metal.albedo_color = Color("#556c7b")
    metal.metallic = 0.55
    metal.roughness = 0.47
    for n in range(-5, 6):
        var v := float(n) * 3.8
        _beam("Moldura norte", Vector3(v, 1.4, -21.95), Vector3(0.18, 2.75, 0.22), metal)
        _beam("Moldura sur", Vector3(v, 1.4, 21.95), Vector3(0.18, 2.75, 0.22), metal)
        _beam("Moldura oeste", Vector3(-21.95, 1.4, v), Vector3(0.22, 2.75, 0.18), metal)
        _beam("Moldura este", Vector3(21.95, 1.4, v), Vector3(0.22, 2.75, 0.18), metal)

func _beam(label: String, pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
    var beam := MeshInstance3D.new()
    beam.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    beam.mesh = mesh
    beam.material_override = mat
    beam.position = pos
    add_child(beam)
