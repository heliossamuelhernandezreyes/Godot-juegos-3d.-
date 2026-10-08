extends SceneTree
## ARCONT provenance + executable skeletal source-audit for Vanguard.
const MODEL = preload("res://assets/vendor/quaternius/vanguard_spacesuit/Spacesuit.gltf")
const REQUIRED = ["Idle_Gun", "Run", "Run_Back", "Run_Left", "Run_Right", "Gun_Shoot", "Roll", "HitRecieve", "Run_Shoot"]

func _initialize() -> void:
    call_deferred("_audit")

func _audit() -> void:
    var actor: Node3D = MODEL.instantiate()
    root.add_child(actor)
    var totals := {"meshes": 0, "triangles": 0, "skeletons": 0, "bones": 0, "players": 0}
    var anim := _scan(actor, totals)
    if anim == null:
        _fail("No AnimationPlayer")
        return
    for clip in REQUIRED:
        if not anim.has_animation(clip):
            _fail("Missing critical humanoid animation: " + clip)
            return
        var item: Animation = anim.get_animation(clip)
        if item == null or item.get_track_count() < 1:
            _fail("Empty animation "+clip)
            return
    if totals.skeletons != 1 or totals.bones < 12 or totals.meshes < 1:
        _fail("Humanoid rig incomplete: "+str(totals))
        return
    print("VANGUARD IMPORT PASS", totals, "anim_count=",anim.get_animation_list().size())
    print("VANGUARD CLIPS",anim.get_animation_list())
    print("VANGUARD RIG bone name audit:")
    var pending: Array[Node] = [actor]
    while not pending.is_empty():
        var node: Node = pending.pop_back()
        if node is Skeleton3D:
            var skeleton := node as Skeleton3D
            for i in range(skeleton.get_bone_count()):
                print("VANGUARD BONE ",i," ",skeleton.get_bone_name(i))
        for child in node.get_children():
            pending.append(child)
    anim.play("Run")
    for i in range(3):
        await process_frame
    if not anim.is_playing():
        _fail("Run clip not actively playing")
        return
    print("VANGUARD SKELETAL PLAY PASS clips=",REQUIRED.size())
    quit(0)

func _scan(node: Node, totals: Dictionary) -> AnimationPlayer:
    var player: AnimationPlayer
    if node is AnimationPlayer:
        totals.players += 1
        player = node
    if node is Skeleton3D:
        totals.skeletons += 1
        totals.bones += node.get_bone_count()
    if node is MeshInstance3D and node.mesh != null:
        totals.meshes += 1
        for surface in range(node.mesh.get_surface_count()):
            totals.triangles += int(node.mesh.surface_get_array_index_len(surface)/3)
    for child in node.get_children():
        var found := _scan(child,totals)
        if found != null:
            player = found
    return player

func _fail(message: String) -> void:
    printerr("VANGUARD IMPORT FAIL: "+message)
    quit(1)
