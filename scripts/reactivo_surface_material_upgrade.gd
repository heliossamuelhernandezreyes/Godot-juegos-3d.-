extends Node3D
## FISURA 0.9.7: actual triplanar PBR textures over Godot-generated BoxMesh
## and legacy mesh proxies, plus inexpensive technical tinted-glass insets.
## Presentation only: NEVER edits shapes, physics, nav, mission, lights or assets.
const VISUAL_LIMIT := 36
var material_targets: Array[Dictionary] = []
var trim_nodes: Array[MeshInstance3D] = []
var textured_world_faces := 0
var textured_architecture_faces := 0
var textured_prop_faces := 0
var glazed_panels := 0
var active := false
var concrete: ORMMaterial3D
var worn_steel: ORMMaterial3D
var steel_blue: ORMMaterial3D
var painted_steel: ORMMaterial3D
var dark_inset: StandardMaterial3D
var glass: StandardMaterial3D
var edge: StandardMaterial3D

func _ready() -> void:
    name = "FISURA 0.9.7 | Real PBR Metal Concrete + Technical Glass"
    concrete = _pbr("concrete_wall_007", Color("#b6c2ca"), 0.54)
    worn_steel = _pbr("green_metal_rust", Color("#a8bdc9"), 0.58)
    steel_blue = _pbr("green_metal_rust", Color("#668b9d"), 0.80)
    painted_steel = _pbr("green_metal_rust", Color("#91b2c4"), 0.63)
    dark_inset = _plain(Color("#142735"), 0.25, 0.67)
    edge = _plain(Color("#9caab3"), 0.72, 0.32)
    glass = _plain(Color(0.33,0.71,0.85,0.47), 0.06, 0.16)
    # A restrained true-alpha glass accent. Real glass refraction is intentionally
    # avoided because GL Compatibility is the Android rendering target.
    glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    glass.cull_mode = BaseMaterial3D.CULL_DISABLED
    var world: Node3D = get_parent() as Node3D
    assert(world != null and world.stage != null and world.cinematic_stage != null,
        "Procedural material pass requires the actual playable Reactivo world")
    _upgrade_legacy_world(world)
    _upgrade_industrial_props(world.stage)
    _upgrade_procedural_architecture(world.cinematic_stage)
    assert(textured_world_faces == 5 and textured_prop_faces == 4,
        "Missing authoritative game wall or sentinel OBJ source surfaces")
    assert(textured_architecture_faces >= 20 and glazed_panels == 4,
        "Missing generated architectural meshes or glass surfaces")
    assert(trim_nodes.size() <= VISUAL_LIMIT, "Too many additional mobile glass/trim draw nodes")
    set_material_upgrade_enabled(true)
    print("FISURA MATERIAL UPGRADE READY world=%d architecture=%d props=%d glass=%d extra_nodes=%d lights=0 physics=0" %
        [textured_world_faces,textured_architecture_faces,textured_prop_faces,
        glazed_panels,trim_nodes.size()])

func _pbr(slug: String, tint: Color, repeat: float) -> ORMMaterial3D:
    # Existing vendored Poly Haven CC0 1K diff/ARM/normal. No runtime downloads.
    var folder: String = "res://assets/vendor/polyhaven_materials/" + slug + "/"
    var m := ORMMaterial3D.new()
    m.albedo_texture = load(folder+"diff.jpg") as Texture2D
    m.orm_texture = load(folder+"arm.jpg") as Texture2D
    m.normal_enabled = true
    m.normal_texture = load(folder+"nor_gl.jpg") as Texture2D
    m.albedo_color = tint
    m.uv1_triplanar = true
    m.uv1_scale = Vector3.ONE * repeat
    assert(m.albedo_texture != null and m.orm_texture != null and m.normal_texture != null,
        "Real local PBR texture set not loaded")
    return m

func _plain(tint: Color, metallic: float, rough: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = tint
    m.metallic = metallic
    m.roughness = rough
    return m

func _target(node: MeshInstance3D, finish: Material, category: String) -> void:
    assert(node != null, "Material target must be actual MeshInstance3D")
    material_targets.append({"target":node,"previous":node.material_override,
        "candidate":finish,"category":category})
    node.material_override = finish

func _upgrade_legacy_world(world: Node3D) -> void:
    for label in ["Reactivo | solid base", "Reactivo | north wall",
            "Reactivo | south wall", "Reactivo | east wall", "Reactivo | west wall"]:
        var body: Node = world.get_node_or_null(label)
        assert(body is StaticBody3D and body.get_child_count() >= 2,
            "Unmodified map-generated primitive is required: "+label)
        var display: MeshInstance3D
        for child in body.get_children():
            if child is MeshInstance3D:
                display = child
                break
        assert(display != null and display.mesh is BoxMesh,
            "Expected original solid Godot BoxMesh "+label)
        _target(display, steel_blue if label == "Reactivo | solid base" else concrete,
            "world")
        textured_world_faces += 1

func _upgrade_industrial_props(art_stage: Node3D) -> void:
    # Real OBJ meshes, not procedural pieces: same PBR material interface works
    # on both. Keep their StaticBody3D and canonical BoxShape3D untouched.
    for child in art_stage.get_children():
        if not child is StaticBody3D or not str(child.name).begins_with("perimeter_"):
            continue
        for leaf in child.get_children():
            if leaf is MeshInstance3D:
                _target(leaf, worn_steel, "prop")
                textured_prop_faces += 1

func _upgrade_procedural_architecture(cinema: Node3D) -> void:
    var tower_counter := 0
    for child in cinema.get_children():
        if not child is MeshInstance3D:
            continue
        var label: String = str(child.get_meta("semantic_art_tag", child.name))
        # Godot auto-renames repeated children: metadata keeps the authored
        # family for every tower, not just the first sibling.
        # Exactly the existing scene-generated BoxMeshs; no mesh replacement.
        if label.begins_with("Node side coolant tower"):
            _target(child, painted_steel, "architecture")
            _glaze_tower(child, tower_counter)
            tower_counter += 1
        elif label.begins_with("Reactor spine | vertical pier"):
            _target(child, concrete, "architecture")
        elif label.begins_with("Containment load-bearing pylon"):
            _target(child, steel_blue, "architecture")
        elif label.begins_with("Node A/B industrial pedestal"):
            _target(child, worn_steel, "architecture")
        elif label.begins_with("Node interconnect bus"):
            _target(child, worn_steel, "architecture")
        elif label.begins_with("Canopy over combat lane"):
            _target(child, painted_steel, "architecture")
        elif label.begins_with("Extraction frame pier"):
            _target(child, concrete, "architecture")
        else:
            continue
        textured_architecture_faces += 1

func _detail(label: String, at: Vector3, size: Vector3, finish: Material) -> void:
    var mesh := BoxMesh.new()
    mesh.size = size
    var part := MeshInstance3D.new()
    part.name = "PBR material pass | "+label
    part.mesh = mesh
    part.material_override = finish
    part.position = at
    part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(part)
    trim_nodes.append(part)

func _glaze_tower(source: MeshInstance3D, tower_index: int) -> void:
    # Place a small technical observation pane on the FRONT face of a solid
    # coolant tower. This is not a fake traversable opening or collider.
    var src_mesh: BoxMesh = source.mesh as BoxMesh
    assert(src_mesh != null and src_mesh.size.z >= 1.3, "Non-box coolant tower")
    var center: Vector3 = source.global_position
    var front: float = src_mesh.size.z * 0.5 + 0.006
    var inset_w: float = src_mesh.size.x * 0.66
    var inset_h := 1.5
    var y: float = center.y + 0.40
    _detail("tower %d | tinted instrumentation glass" % tower_index,
        Vector3(center.x,y,center.z+front+0.017),
        Vector3(inset_w,inset_h,0.026),glass)
    _detail("tower %d | recessed instrument backing" % tower_index,
        Vector3(center.x,y,center.z+front-0.010),
        Vector3(inset_w+0.035,inset_h+0.04,0.018),dark_inset)
    for side in [-1.0,1.0]:
        _detail("tower %d | machined glass edge" % tower_index,
            Vector3(center.x+float(side)*(inset_w*0.5+0.045),y,center.z+front+0.037),
            Vector3(0.065,inset_h+0.12,0.040),edge)
    glazed_panels += 1

func set_material_upgrade_enabled(enabled: bool) -> void:
    active = enabled
    for data in material_targets:
        var node: MeshInstance3D = data["target"]
        node.material_override = data["candidate"] if enabled else data["previous"]
    for node in trim_nodes:
        node.visible = enabled
