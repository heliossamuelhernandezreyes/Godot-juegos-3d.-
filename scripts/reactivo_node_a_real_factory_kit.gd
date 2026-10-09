extends Node3D
## FISURA 0.9.8 ARCONT: actual source-pinned Kenney CC0 GLB modular
## manufacturing machinery, NOT Godot primitives disguised as assets.
## Two non-colliding artistic blockout towers are hidden. Physics is untouched.
const MACHINE: PackedScene = preload("res://assets/vendor/kenney_factory_kit/machine-fortified.glb")
const WINDOW: PackedScene = preload("res://assets/vendor/kenney_factory_kit/machine-window.glb")
const VALVE: PackedScene = preload("res://assets/vendor/kenney_factory_kit/pipe-large-valve.glb")
const PIPE: PackedScene = preload("res://assets/vendor/kenney_factory_kit/pipe-large-long.glb")
const ROBOT: PackedScene = preload("res://assets/vendor/kenney_factory_kit/robot-arm-a.glb")
const CONVEYOR: PackedScene = preload("res://assets/vendor/kenney_factory_kit/conveyor-long.glb")
const CATWALK: PackedScene = preload("res://assets/vendor/kenney_factory_kit/catwalk-straight.glb")

const MAX_KIT_INSTANCES := 20
var authentic_instances: Array[Node3D] = []
var legacy_blockouts: Array[MeshInstance3D] = []
var authentic_mesh_nodes := 0
var active := false
var batches := 0

func _ready() -> void:
    name = "ARCONT / Kenney real 3D factory kit | Node A"
    var cinema: Node3D = get_parent() as Node3D
    assert(cinema != null, "Factory modular layer requires playable cinematic scene")
    # Authoritative cinematic stage has two purely VISUAL oversized coolant boxes
    # at Node A: x=-32,z=0 and x=-32,z=8. They have no collider. Only those
    # two and their original neon strips are hidden, not game semantic meshes.
    for child in cinema.get_children():
        if not child is MeshInstance3D:
            continue
        var tag: String = str(child.get_meta("semantic_art_tag", child.name))
        if (tag == "Node side coolant tower" or tag == "Node coolant column strip") \
                and child.position.x < -30.0:
            legacy_blockouts.append(child)
    assert(legacy_blockouts.size() == 4,
        "Require two authored, collider-free Node A towers + two trim strips")
    _factory_towers()
    _maintenance_machinery()
    assert(authentic_instances.size() <= MAX_KIT_INSTANCES)
    assert(authentic_mesh_nodes >= authentic_instances.size(),
        "Native real model scenes not instantiated")
    set_factory_kit_enabled(true)
    print("FISURA ARCONT FACTORY KIT READY imported_glb_instances=%d meshes=%d legacy_hidden=%d collision=0 lights=0" %
        [authentic_instances.size(),authentic_mesh_nodes,legacy_blockouts.size()])

func _place(tag: String, packed: PackedScene, where: Vector3,
        scale_factor: float, yaw: float = 0.0) -> Node3D:
    var visual: Node3D = packed.instantiate()
    visual.name = "KENNEY CC0 | " + tag
    visual.position = where
    visual.scale = Vector3.ONE * scale_factor
    visual.rotation.y = yaw
    add_child(visual)
    authentic_instances.append(visual)
    authentic_mesh_nodes += _inspect(visual)
    return visual

func _inspect(node: Node) -> int:
    assert(not node is CollisionObject3D and not node is CollisionShape3D,
        "Selected art-only GLB unexpectedly contains game physics")
    assert(not node is Light3D, "Factory asset unexpectedly adds gameplay light")
    var count := 1 if node is MeshInstance3D else 0
    for child in node.get_children():
        count += _inspect(child)
    return count

func _factory_towers() -> void:
    for z in [0.0, 8.0]:
        # Genuine authored machine geometry stacked into a service bay tower.
        # Compared with the original 4.3m cuboid this has non-box silhouette,
        # grilles, maintenance windows, exposed controls and machinery seams.
        _place("fortified industrial machine | bay z=%d" % int(z),
            MACHINE, Vector3(-32.0,0.08,z),1.40)
        _place("instrument window machine | bay z=%d" % int(z),
            WINDOW, Vector3(-32.0,1.92,z),1.38)
        _place("pressure valve head | bay z=%d" % int(z),
            VALVE, Vector3(-32.0,3.75,z),0.88)

func _maintenance_machinery() -> void:
    # Positioned on service perimeter, not on Node A cover or mission console.
    _place("robotic maintenance arm west", ROBOT, Vector3(-34.4,0.10,0.0),1.43,0.8)
    _place("robotic maintenance arm south", ROBOT, Vector3(-34.5,0.10,7.8),1.24,-0.6)
    _place("floor transfer bed service", CONVEYOR, Vector3(-35.0,0.08,3.6),1.18,PI*0.5)
    _place("ceiling transfer pipe", PIPE, Vector3(-34.6,6.3,2.6),1.35,PI*0.5)
    _place("maintenance overhead catwalk",CATWALK,Vector3(-34.0,6.7,5.5),1.18)

func set_factory_kit_enabled(enabled: bool) -> void:
    active = enabled
    for visual in authentic_instances:
        visual.visible = enabled
    for old in legacy_blockouts:
        old.visible = not enabled
