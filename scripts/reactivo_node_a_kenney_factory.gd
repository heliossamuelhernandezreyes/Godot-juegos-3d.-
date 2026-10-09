extends Node3D
## FISURA 0.9.8 — authentic ARCONT-catalogued Kenney Factory Kit GLBs.
## These are real licensed polygon meshes, NOT BoxMesh lookalikes.
## Game physics, navigation, objectives, combat and realtime lights are unchanged.
const BASE := "res://assets/vendor/kenney_factory_node_a/"
const PREFABS := {
    "structure-high": preload(BASE + "structure-high.glb"),
    "machine-fortified": preload(BASE + "machine-fortified.glb"),
    "machine-window": preload(BASE + "machine-window.glb"),
    "piston-round": preload(BASE + "piston-round.glb"),
    "screen-panel-small": preload(BASE + "screen-panel-small.glb"),
    "pipe-large-valve": preload(BASE + "pipe-large-valve.glb"),
    "pipe-large-bend": preload(BASE + "pipe-large-bend.glb"),
    "pipe-large-long": preload(BASE + "pipe-large-long.glb"),
    "pipe-glass-large-valve": preload(BASE + "pipe-glass-large-valve.glb"),
    "catwalk-straight": preload(BASE + "catwalk-straight.glb")
}
const MODEL_LIMIT := 30
var authored_models: Array[Node3D] = []
var replaced_legacy_visuals: Array[Node3D] = []
var draw_mesh_nodes := 0
var visible_kit := true
var model_counts: Dictionary = {}
var geometry_triangles := 0
var _original_visibility: Dictionary = {}
var _panel_alpha_trim: Array[Node3D] = []

func _ready() -> void:
    name = "NODE A | KENNEY REAL FACTORY GLB KIT | CC0 | VISUAL ONLY"
    # Relative to Node A center(-28,0,4); all substantial new solid-looking
    # details sit in pre-existing machinery/architecture zones, off combat path.
    _model("structure-high", "original coolant tower south | load frame",
        Vector3(-4,0,-4), Vector3(4.8,2.8,1.35))
    _model("structure-high", "original coolant tower north | load frame",
        Vector3(-4,0,4), Vector3(4.8,2.8,1.35))
    _model("machine-fortified", "machine bay | fortified motor",
        Vector3(-1.65,0.63,-2.9), Vector3(1.45,1.20,1.10))
    _model("machine-window", "machine bay | inspection window",
        Vector3(2.15,0.63,-2.9), Vector3(1.48,1.18,1.18))
    _model("piston-round", "mechanical actuator | south",
        Vector3(-1.30,0.70,0.65), Vector3(0.88,1.55,0.88))
    _model("piston-round", "mechanical actuator | north",
        Vector3(1.28,0.70,0.65), Vector3(0.88,1.55,0.88))
    _model("screen-panel-small", "diagnostic status | high backplane",
        Vector3(-0.85,3.80,-3.45), Vector3(1.65,1.32,1.0))
    # Pipe cluster floats in a high utility zone, never creates path blockers.
    _model("pipe-large-long", "left real pipe span",
        Vector3(-3.55,5.56,0.92), Vector3(1.34,0.84,0.84))
    _model("pipe-large-bend", "left real pipe bend",
        Vector3(-4.20,5.56,-0.75), Vector3(0.83,0.83,0.83))
    _model("pipe-large-valve", "left real valve and wheel",
        Vector3(-3.54,5.47,2.25), Vector3(1.00,1.02,1.00))
    _model("pipe-glass-large-valve", "right real sight-glass valve",
        Vector3(3.66,5.45,1.15), Vector3(1.0,1.04,1.0))
    _model("pipe-large-long", "right real pipe span",
        Vector3(3.64,5.58,-1.00), Vector3(1.34,0.84,0.84))
    _model("catwalk-straight", "raised service walk | left",
        Vector3(-3.80,6.75,1.40), Vector3(1.3,1.25,2.45))
    _model("catwalk-straight", "raised service walk | right",
        Vector3(3.80,6.75,1.40), Vector3(1.3,1.25,2.45))
    assert(authored_models.size() == 14 and model_counts.size() == 10 and draw_mesh_nodes >= 14,
        "Missing actual prebuilt Kenney source meshes")
    assert(authored_models.size() <= MODEL_LIMIT, "Factory pass exceeds mobile instance budget")
    print("KENNEY FACTORY KIT READY real_glb_instances=%d unique_source_models=%d mesh_nodes=%d triangles=%d physics=0 lights=0" %
        [authored_models.size(),model_counts.size(),draw_mesh_nodes,geometry_triangles])

func _model(id: String, label: String, local_at: Vector3, size: Vector3) -> void:
    var proto: PackedScene = PREFABS.get(id)
    assert(proto != null, "A pinned GLB prefab is missing "+id)
    var obj: Node3D = proto.instantiate() as Node3D
    assert(obj != null, "Kenney source failed to instantiate as Node3D "+id)
    obj.name = "KENNEY FACTORY 3D | %02d | %s" % [authored_models.size(),label]
    obj.position = local_at
    obj.scale = size
    add_child(obj)
    authored_models.append(obj)
    model_counts[id] = int(model_counts.get(id,0)) + 1
    _prepare_imported_geometry(obj)

func _prepare_imported_geometry(tree: Node) -> void:
    assert(not tree is CollisionObject3D and not tree is CollisionShape3D and not tree is Light3D,
        "Imported game art unexpectedly contained collision or realtime light")
    if tree is MeshInstance3D:
        var visible_mesh: MeshInstance3D = tree as MeshInstance3D
        assert(visible_mesh.mesh != null and visible_mesh.mesh.get_surface_count() > 0,
            "Imported Kenney source is an empty geometry proxy")
        visible_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        draw_mesh_nodes += 1
        for surface in range(visible_mesh.mesh.get_surface_count()):
            var arrays: Array = visible_mesh.mesh.surface_get_arrays(surface)
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            geometry_triangles += indices.size()/3 if not indices.is_empty() else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()/3
    for sub in tree.get_children():
        _prepare_imported_geometry(sub)

func bind_existing_legacy_visuals(world: Node3D) -> void:
    # Called only after both ArtStage and 0.9.7 material layer have finished.
    # Swap exactly Node A's two giant 4.3m primitive coolant boxes and their
    # emissive stripes; restore for true same-build before/after evidence.
    var cinema: Node3D = world.cinematic_stage
    for item in cinema.get_children():
        if not item is MeshInstance3D:
            continue
        var tag: String = str(item.get_meta("semantic_art_tag", item.name))
        if tag != "Node side coolant tower" and tag != "Node coolant column strip":
            continue
        if absf(item.global_position.x - (-32.0)) > 1.1:
            continue
        _register_replaced(item)
    # Glass overlays for the two hidden procedural towers are themselves
    # render-only, and should not hang in mid-air when GLB frame replaces them.
    for panel in world.material_pass.trim_nodes:
        if panel.name.contains("tower 0 |") or panel.name.contains("tower 1 |"):
            _register_replaced(panel)
    assert(replaced_legacy_visuals.size() == 12,
        "Source coolant tower or corresponding glass trim is missing")
    set_factory_upgrade_enabled(true)

func _register_replaced(item: Node3D) -> void:
    if replaced_legacy_visuals.has(item):
        return
    replaced_legacy_visuals.append(item)
    _original_visibility[item.get_instance_id()] = item.visible

func set_factory_upgrade_enabled(enabled: bool) -> void:
    visible_kit = enabled
    for item in authored_models:
        item.visible = enabled
    for previous in replaced_legacy_visuals:
        previous.visible = false if enabled else bool(_original_visibility[previous.get_instance_id()])
