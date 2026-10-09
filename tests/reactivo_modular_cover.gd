extends SceneTree
## Native verification: every modular cover detail remains within a Map Forge AABB.
const SCENE: PackedScene = preload("res://scenes/reactivo_13.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var world: Node3D = SCENE.instantiate()
    root.add_child(world)
    world.testing_disable_spawns = true
    var stage: Node3D = world.stage
    if stage == null or stage.modular_cover_layer == null:
        _fail("cover cassette layer missing in playable level")
        return
    var visuals: Node3D = stage.modular_cover_layer
    var source: Array = world.map_data["authoring"]["structure_guides"]
    if visuals.get_child_count() != 7 or visuals.built_cover_ids.size() != 7:
        _fail("all seven genuine map covers must be remodeled")
        return
    var physical_before := _physics_count(world)
    var light_before := _light_count(world)
    if light_before != 13:
        _fail("visual upgrade changed scene light budget")
        return
    var counted := 0
    var instances := 0
    for item in source:
        if str(item["kind"]) != "cover":
            continue
        var id: String = str(item["id"])
        var game_body: StaticBody3D = world.get_node_or_null(id) as StaticBody3D
        var shell: Node3D = visuals.get_node_or_null("COVER CASSETTE | "+id) as Node3D
        if game_body == null or shell == null:
            _fail("missing physical and decorative cover pair " + id)
            return
        var pos: Array = item["position"]
        var sz: Array = item["size"]
        var center := Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
        var size := Vector3(float(sz[0]),float(sz[1]),float(sz[2]))
        if game_body.global_position.distance_to(center) > 0.001 or shell.global_position.distance_to(center) > 0.001:
            _fail("visuals or physical body displaced from Map Forge center")
            return
        var found_shape := false
        var original_block := false
        for child in game_body.get_children():
            if child is CollisionShape3D:
                var box: BoxShape3D = child.shape as BoxShape3D
                if box == null or box.size.distance_to(size) > 0.001:
                    _fail("game-owned physics collider modified")
                    return
                found_shape = true
            if child is MeshInstance3D:
                if child.visible:
                    _fail("upgraded cover still displays original primitive")
                    return
                original_block = true
        if not found_shape or not original_block:
            _fail("source collision / blockout pair missing")
            return
        for child in shell.get_children():
            if child is Light3D or child is CollisionObject3D or child is CollisionShape3D:
                _fail("cover decoration created physical obstruction or real light")
                return
            if not child is GeometryInstance3D or child.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
                _fail("cover piece is not a shadowless visual geometry instance")
                return
            if child is MeshInstance3D:
                var boxmesh := (child as MeshInstance3D).mesh as BoxMesh
                if boxmesh == null or not _inside_bounds(child.position,boxmesh.size,size):
                    _fail("authored cover panel outside gameplay AABB: " + child.name)
                    return
                counted += 1
                instances += 1
            elif child is MultiMeshInstance3D:
                var mm: MultiMesh = (child as MultiMeshInstance3D).multimesh
                var boxmesh: BoxMesh = mm.mesh as BoxMesh
                if boxmesh == null:
                    _fail("cover louver uses non-box mesh")
                    return
                for index in range(mm.instance_count):
                    if not _inside_bounds(mm.get_instance_transform(index).origin,boxmesh.size,size):
                        _fail("batched louver outside physics volume")
                        return
                counted += 1
                instances += mm.instance_count
    if counted != visuals.mesh_nodes or instances != visuals.visual_instances:
        _fail("native cassette inventory inconsistent")
        return
    stage.set_cover_upgrade_enabled(false)
    if visuals.visible:
        _fail("legacy camera baseline switch failed")
        return
    for item in source:
        if str(item["kind"]) != "cover":
            continue
        var body: StaticBody3D = world.get_node(str(item["id"])) as StaticBody3D
        if not (body.get_child(1) as MeshInstance3D).visible:
            _fail("legacy source geometry not restored")
            return
    stage.set_cover_upgrade_enabled(true)
    if not visuals.visible or _physics_count(world) != physical_before or _light_count(world) != light_before:
        _fail("visual cover switch altered gameplay physics or lighting")
        return
    if stage.original_cover_finishes.size() != 63:
        _fail("legacy cover assets were not enumerated or correctly hidden")
        return
    print("FISURA MODULAR COVERS PASS guides=7 mesh_nodes=%d instances=%d original_colliders=unchanged lights=unchanged" %
        [counted,instances])
    quit(0)

func _inside_bounds(at: Vector3, extents: Vector3, physical: Vector3) -> bool:
    var d: Vector3 = at.abs() + extents * 0.5
    return d.x <= physical.x*0.5 + 0.002 and d.y <= physical.y*0.5 + 0.002 and d.z <= physical.z*0.5 + 0.002

func _physics_count(n: Node) -> int:
    var count := 1 if n is CollisionObject3D or n is CollisionShape3D else 0
    for child in n.get_children():
        count += _physics_count(child)
    return count

func _light_count(n: Node) -> int:
    var count := 1 if n is Light3D else 0
    for child in n.get_children():
        count += _light_count(child)
    return count

func _fail(why: String) -> void:
    printerr("FISURA MODULAR COVERS FAIL ",why)
    quit(1)
