extends SceneTree
## ARCONT P1: native Godot scene-tree inventory. Evidence ONLY, not a runtime gameplay change.
## This script lives and runs in FISURA. ARCONT receives the resulting immutable JSON.
const SCENE: PackedScene = preload("res://scenes/reactivo_13.tscn")
const SCENE_PATH := "scenes/reactivo_13.tscn"
const OUTPUT_PATH := "res://reactivo-13-native-scene-snapshot.json"
const MAX_NODES := 18000

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var sha: String = FileAccess.get_sha256("res://" + SCENE_PATH)
    var commit: String = OS.get_environment("GITHUB_SHA").to_lower()
    if sha.length() != 64 or commit.length() != 40 or not commit.is_valid_hex_number():
        _fail("missing scene SHA-256 or GitHub Actions source commit")
        return
    var world: Node3D = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    for _frame in range(3):
        await physics_frame
    var rows: Array[Dictionary] = []
    _walk(world, rows)
    var lights := 0
    var meshes := 0
    var shadow_lights := 0
    var authored_props := 0
    var instances := 0
    var materials := 0
    for row in rows:
        if str(row["type"]) in ["DirectionalLight3D", "OmniLight3D", "SpotLight3D"]:
            lights += 1
            if row.get("shadow_enabled", false):
                shadow_lights += 1
        if str(row["type"]) in ["MeshInstance3D", "MultiMeshInstance3D"]:
            meshes += 1
            instances += int(row.get("instance_count", 1))
            materials += row.get("material_descriptors", []).size()
        if str(row["path"]).contains("Poly Haven CC0"):
            authored_props += 1
    if rows.size() < 200 or meshes < 150 or lights < 10 or shadow_lights < 1 or instances < meshes or materials < 80 or authored_props < 6:
        _fail("stage incomplete nodes=%d meshes=%d lights=%d shadows=%d instances=%d mats=%d sourced=%d" %
            [rows.size(), meshes, lights, shadow_lights, instances, materials, authored_props])
        return
    var document: Dictionary = {
        "protocol": "arcont-godot-scene-snapshot",
        "version": 1,
        "scene_path": SCENE_PATH,
        "scene_sha256": sha,
        "capture_source": "native-godot",
        "engine_version": str(Engine.get_version_info().get("string", "unknown")),
        "renderer": str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown")),
        "source_commit": commit,
        "nodes": rows
    }
    if document["renderer"] != "gl_compatibility":
        _fail("unexpected renderer: " + str(document["renderer"]))
        return
    var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
    if file == null:
        _fail("cannot open snapshot destination")
        return
    file.store_string(JSON.stringify(document, "\t") + "\n")
    file.close()
    print("REACTIVO NATIVE VISUAL INVENTORY PASS nodes=%d meshes=%d lights=%d shadows=%d instances=%d material_records=%d sourced_nodes=%d sha256=%s" %
        [rows.size(), meshes, lights, shadow_lights, instances, materials, authored_props, sha])
    quit(0)

func _walk(node: Node, rows: Array[Dictionary]) -> void:
    if rows.size() >= MAX_NODES:
        _fail("bounded node limit exceeded")
        return
    var item: Dictionary = {
        "path": str(node.get_path()),
        "type": str(node.get_class()),
    }
    if node is Node3D:
        item["visible"] = (node as Node3D).visible
    if node is Light3D:
        var lamp := node as Light3D
        item["shadow_enabled"] = lamp.shadow_enabled
        item["light_color"] = lamp.light_color.to_html(false)
        item["light_energy"] = lamp.light_energy
        if node is OmniLight3D:
            item["light_range"] = (node as OmniLight3D).omni_range
        elif node is SpotLight3D:
            item["light_range"] = (node as SpotLight3D).spot_range
    if node is MeshInstance3D:
        var mesh_node := node as MeshInstance3D
        item["instance_count"] = 1
        item["surfaces"] = mesh_node.mesh.get_surface_count() if mesh_node.mesh != null else 0
        _mesh_materials(mesh_node, mesh_node.mesh, item)
    elif node is MultiMeshInstance3D:
        var multi_node := node as MultiMeshInstance3D
        item["instance_count"] = multi_node.multimesh.instance_count if multi_node.multimesh != null else 0
        var model: Mesh = multi_node.multimesh.mesh if multi_node.multimesh != null else null
        item["surfaces"] = model.get_surface_count() if model != null else 0
        _mesh_materials(multi_node, model, item)
    if node is WorldEnvironment:
        var environment := (node as WorldEnvironment).environment
        if environment != null:
            item["ambient_light_energy"] = environment.ambient_light_energy
            item["background_mode"] = environment.background_mode
    rows.append(item)
    for child in node.get_children():
        _walk(child, rows)

func _mesh_materials(display: GeometryInstance3D, mesh: Mesh, item: Dictionary) -> void:
    var records: Array[Dictionary] = []
    var paths: Array[String] = []
    if display.material_override != null:
        _record_material(display.material_override, records, paths)
    if mesh != null:
        for surface_index in range(mesh.get_surface_count()):
            var mat: Material = null
            if display is MeshInstance3D:
                mat = (display as MeshInstance3D).get_surface_override_material(surface_index)
            if mat == null:
                mat = mesh.surface_get_material(surface_index)
            if mat != null:
                _record_material(mat, records, paths)
    item["material_paths"] = paths
    item["material_descriptors"] = records

func _record_material(material: Material, records: Array[Dictionary], paths: Array[String]) -> void:
    var path: String = str(material.resource_path)
    if path.begins_with("res://") and not paths.has(path):
        paths.append(path)
    var descriptor: Dictionary = {"kind": str(material.get_class()), "resource_path": path}
    if material is BaseMaterial3D:
        var surface := material as BaseMaterial3D
        descriptor["albedo_color"] = surface.albedo_color.to_html()
        descriptor["metallic"] = surface.metallic
        descriptor["roughness"] = surface.roughness
        descriptor["normal_enabled"] = surface.normal_enabled
        descriptor["emission_enabled"] = surface.emission_enabled
        if surface.albedo_texture != null:
            descriptor["albedo_texture"] = str(surface.albedo_texture.resource_path)
    if not records.has(descriptor):
        records.append(descriptor)

func _fail(reason: String) -> void:
    printerr("REACTIVO NATIVE VISUAL INVENTORY FAIL ", reason)
    quit(1)
