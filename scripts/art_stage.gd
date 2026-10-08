extends Node3D
## Art direction — distinct mesh assets, canonical level gameplay kept in map JSON.
## Mobile-first: instanced floor geometry and conservative realtime lights.
const TILE = preload("res://assets/models/armature_floor.obj")
const PILLAR = preload("res://assets/models/sentinel_pillar.obj")
const CRATE = preload("res://assets/models/armored_crate.obj")
const GATE = preload("res://assets/models/extraction_gate.obj")
const REACTOR = preload("res://assets/models/reactor_altar.obj")
const POLY_BARREL = preload("res://assets/vendor/polyhaven/barrel_03/barrel_03_1k.gltf")
const POLY_LAMP = preload("res://assets/vendor/polyhaven/industrial_wall_lamp/industrial_wall_lamp_1k.gltf")

var mesh_count := 0
var mesh_instances := 0
var point_lights := 0

func build(map_data: Dictionary, anchors: Dictionary) -> void:
    name = "Direccion artistica - Crisol"
    _floor_tiles(map_data)
    # Gameplay + visual props share a single semantic manifest, not duplicate lists.
    var resource_map := {"pillar": PILLAR, "crate": CRATE, "reactor": REACTOR}
    for item in map_data.get("authoring", {}).get("world_props", []):
        var kind: String = str(item.get("kind", ""))
        if not resource_map.has(kind):
            continue
        var pos: Array = item["position"]
        var dims: Array = item["collider_size"]
        _static_prop(str(item["id"]), resource_map[kind],
            Vector3(float(pos[0]), float(pos[1]), float(pos[2])),
            Vector3(float(dims[0]), float(dims[1]), float(dims[2])))
    _display_asset("Portico", GATE, anchors["exit_portal"], 0.0)
    _place_polyhaven_props()
    _lighting()
    _set_wall_detail()
    _industrial_architecture(map_data)
    _dress_covers(map_data)
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
    batch.material_override = _pbr_material("concrete_floor_worn_02", Color("#899da7"), 0.7)
    add_child(batch)
    mesh_count += 1
    mesh_instances += index

func _place_polyhaven_props() -> void:
    # Actual PBR glTF assets acquired from Poly Haven official CC0 API,
    # pinned with asset manifests; no live dependency during gameplay.
    for point in [Vector3(-16, 0, 1), Vector3(16, 0, -3), Vector3(-10, 0, 15),
                  Vector3(10, 0, -15), Vector3(-8, 0, -17)]:
        _vendor_instance("Barril PBR Poly Haven", POLY_BARREL, point, 1.0)
    for point in [Vector3(-20.9, 2.5, -13), Vector3(-20.9, 2.5, 6),
                  Vector3(20.9, 2.5, -10), Vector3(20.9, 2.5, 10)]:
        _vendor_instance("Luz PBR industrial", POLY_LAMP, point, 2.3)

func _vendor_instance(label: String, packed: PackedScene, pos: Vector3, scale_factor: float) -> void:
    var instance: Node3D = packed.instantiate()
    instance.name = label
    instance.position = pos
    instance.scale = Vector3.ONE * scale_factor
    add_child(instance)
    mesh_count += 1

func _lighting() -> void:
    _spot("Recorte cian", Vector3(-12, 7.5, -8), Color("#16b9dc"), 8.5, 27.0)
    _spot("Recorte ambar", Vector3(15, 7.5, 9), Color("#e98042"), 7.5, 27.0)
    _spot("Portal", Vector3(0, 6.0, -16), Color("#49e8ed"), 8.5, 16.0)
    _spot("Reactor central", Vector3(0, 5.0, 0), Color("#fa7340"), 5.0, 12.0)
    _spot("Luz protagonista", Vector3(0, 8.5, 13.5), Color("#b7deee"), 6.7, 18.0)

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

func _beam(label: String, pos: Vector3, size: Vector3, mat: Material) -> void:
    var beam := MeshInstance3D.new()
    beam.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    beam.mesh = mesh
    beam.material_override = mat
    beam.position = pos
    add_child(beam)

func _industrial_architecture(contract: Dictionary) -> void:
    # ARCONT procedural generation: deterministic inputs, presentation-only data,
    # separable collision/nav proxies, and finite workload.
    var seed_value := int(contract.get("authoring", {}).get("environment", {}).get("seed", 70421))
    var generator := RandomNumberGenerator.new()
    generator.seed = seed_value
    var iron := _pbr_material("green_metal_rust", Color("#91a4ae"), 0.28)
    var frame := _material(Color("#667986"), 0.72, 0.35)
    var soot := _pbr_material("concrete_wall_007", Color("#8897a3"), 0.44)
    var copper := _material(Color("#694531"), 0.65, 0.49)
    var cyan := _material(Color("#4dd9ed"), 0.22, 0.28, 2.3)
    var orange := _material(Color("#ef7d38"), 0.25, 0.31, 2.0)
    var width := float(contract["bounds"]["width"])
    var depth := float(contract["bounds"]["depth"])
    var bx := width * 0.5 - 0.9
    var bz := depth * 0.5 - 0.9

    # Industrial cathedral: tall exterior wall cladding and outer girder ring.
    for side in [-1.0, 1.0]:
        _beam("Fachada norte-sur", Vector3(0, 5.8, side * (bz + 0.12)),
            Vector3(width - 1.0, 7.8, 0.46), soot)
        _beam("Fachada este-oeste", Vector3(side * (bx + 0.12), 5.8, 0),
            Vector3(0.46, 7.8, depth - 1.0), soot)
        for height in [4.4, 7.0, 9.3]:
            _beam("Viga exterior Z", Vector3(0, height, side * bz), Vector3(width, 0.19, 0.42), iron)
            _beam("Viga exterior X", Vector3(side * bx, height, 0), Vector3(0.42, 0.19, depth), iron)
        for k in range(-5, 6):
            var along := float(k) * 3.6
            # Recessed wall blades + handrails are high enough not to obscure play.
            _beam("Nervio vertical", Vector3(along, 6.15, side * bz),
                Vector3(0.25, 7.1, 0.43), frame)
            _beam("Nervio lateral", Vector3(side * bx, 6.15, along),
                Vector3(0.43, 7.1, 0.25), frame)
            if k % 2 == 0:
                _beam("Rejilla alta", Vector3(along, 6.5, side * (bz - 0.34)),
                    Vector3(1.0, 0.18, 0.08), cyan)
                _beam("Luz lateral", Vector3(side * (bx - 0.34), 6.5, along),
                    Vector3(0.08, 0.18, 1.0), orange)

    # Perimeter maintenance catwalks and railings; decoration only, not walkable.
    for x in [-19.0, 19.0]:
        _beam("Pasarela E-O", Vector3(x, 13.5, 0), Vector3(1.65, 0.24, 35.0), iron)
        for side in [-1.0, 1.0]:
            _beam("Pasamanos", Vector3(x + side * 0.80, 14.20, 0),
                Vector3(0.12, 1.2, 35), frame)
    for z in [-19.0, 19.0]:
        _beam("Pasarela N-S", Vector3(0, 13.5, z), Vector3(35.0, 0.24, 1.65), iron)
        for side in [-1.0, 1.0]:
            _beam("Baranda metalica", Vector3(0, 14.2, z + side * 0.80),
                Vector3(35.0, 1.2, 0.12), frame)

    # Industrial utility pipes; cylindrical geometry has no gameplay collider.
    for x in [-20.1, -19.3, 19.3, 20.1]:
        _pipe("Conduccion primaria", Vector3(x, 6.55, 0), 0.19, depth - 3.0, copper)
        _pipe("Tuberia presurizada", Vector3(x, 6.91, 0), 0.08, depth - 3.0, iron)
    for z in [-20.1, 20.1]:
        _pipe("Troncal de refrigeracion", Vector3(0, 5.6, z), 0.22, width - 3.0, frame, true)

    # Giant corner machines with deterministic light accents.
    for side_x in [-1.0, 1.0]:
        for side_z in [-1.0, 1.0]:
            var x: float = float(side_x) * 19.2
            var z: float = float(side_z) * 19.2
            _beam("Torre de extraccion", Vector3(x, 5.1, z),
                Vector3(2.1, 8.9, 2.1), iron)
            _beam("Panel de mantenimiento", Vector3(x - side_x * 0.48, 5.6, z - side_z * 1.10),
                Vector3(0.9, 3.8, 0.12), soot)
            _beam("Refrigeracion luminosa", Vector3(x - side_x * 0.48, 5.8, z - side_z * 1.18),
                Vector3(0.16, 2.8, 0.05), cyan)

    # Readable visual lanes: cable trays frame paths; never obstruct objectives.
    for i in range(-3, 4):
        var z := float(i) * 4.8
        var tone := orange if i % 2 == 0 else cyan
        _beam("Carril iluminado O", Vector3(-15.65, 0.025, z), Vector3(0.12, 0.035, 2.7), tone)
        _beam("Carril iluminado E", Vector3(15.65, 0.025, z), Vector3(0.12, 0.035, 2.7), tone)
    for i in range(12):
        var v := float(i) * 3.25 - 18.0
        var choice := generator.randf()
        if choice > 0.56:
            _beam("Rejilla drenaje", Vector3(v, 0.045, -18.5),
                Vector3(0.9, 0.04, 0.11), soot)
        if choice < 0.34:
            _beam("Marca advertencia", Vector3(v, 0.048, 18.4),
                Vector3(0.55, 0.04, 0.12), orange)
    print("ARCONT INDUSTRIAL SHELL seed=%d, visual-only architecture" % seed_value)

func _material(color: Color, metallic: float, roughness: float, glow: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    if glow > 0.0:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = glow
    return material

func _pipe(label: String, pos: Vector3, radius: float, length: float,
           mat: Material, along_x: bool = false) -> void:
    var visual := MeshInstance3D.new()
    visual.name = label
    var tube := CylinderMesh.new()
    tube.top_radius = radius
    tube.bottom_radius = radius
    tube.height = length
    tube.radial_segments = 8
    visual.mesh = tube
    visual.material_override = mat
    visual.position = pos
    visual.rotation = Vector3(0, 0, PI * 0.5) if along_x else Vector3(PI * 0.5, 0, 0)
    add_child(visual)

func _pbr_material(slug: String, tint: Color, scale: float) -> ORMMaterial3D:
    # Real Poly Haven 1K CC0: albedo + OpenGL normal + AO/Roughness/Metallic.
    # Triplanar keeps proportions consistent on repeated procedural meshes.
    var path := "res://assets/vendor/polyhaven_materials/" + slug + "/"
    var mat := ORMMaterial3D.new()
    mat.albedo_color = tint
    mat.albedo_texture = load(path + "diff.jpg") as Texture2D
    mat.orm_texture = load(path + "arm.jpg") as Texture2D
    mat.normal_enabled = true
    mat.normal_texture = load(path + "nor_gl.jpg") as Texture2D
    mat.uv1_triplanar = true
    mat.uv1_scale = Vector3.ONE * scale
    return mat

func _dress_covers(contract: Dictionary) -> void:
    # Collision remains with game semantic blockout; layers below are visual-only.
    var armor := _pbr_material("green_metal_rust", Color("#bac8d1"), 0.58)
    var trim := _material(Color("#c3a573"), 0.70, 0.35)
    var seam := _material(Color("#0c2433"), 0.25, 0.42, 1.5)
    for guide in contract.get("authoring", {}).get("structure_guides", []):
        if guide.get("kind", "") != "cover":
            continue
        var p: Array = guide["position"]
        var d: Array = guide["size"]
        var center := Vector3(float(p[0]), float(p[1]), float(p[2]))
        var size := Vector3(float(d[0]), float(d[1]), float(d[2]))
        var x_offset := size.x * 0.5 + 0.06
        var z_offset := size.z * 0.5 + 0.06
        var y_offset := size.y * 0.5 + 0.06
        _beam("Blindaje cubierta - superior", center + Vector3(0, y_offset, 0),
            Vector3(size.x + 0.16, 0.13, size.z + 0.16), armor)
        for xside in [-1.0, 1.0]:
            _beam("Blindaje lateral", center + Vector3(float(xside) * x_offset, 0, 0),
                Vector3(0.14, size.y, size.z + 0.13), armor)
        for zside in [-1.0, 1.0]:
            _beam("Panel frontal", center + Vector3(0, 0, float(zside) * z_offset),
                Vector3(size.x, size.y, 0.14), armor)
            _beam("Linea de aviso", center + Vector3(0, -size.y * 0.28, float(zside) * (z_offset + 0.08)),
                Vector3(size.x * 0.78, 0.10, 0.03), seam)
        for along in [-0.4, 0.4]:
            _beam("Montante blindado", center + Vector3(0, size.y * 0.34, along * size.z),
                Vector3(size.x + 0.20, 0.12, 0.14), trim)
