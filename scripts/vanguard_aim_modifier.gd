extends SkeletonModifier3D
## ARCONT ANIM-004 research prototype: bounded additive upper-torso recoil.
## Runs *after* AnimationPlayer; NEVER claims full-body/hand/foot IK.
## It adjusts only named torso bones; no bone indices hardcoded.
var recoil := 0.0
var aim_weight := 0.0
var pitch := 0.0
var yaw := 0.0
var spine_bones: Array[int] = []
var applied_frames := 0

func _ready() -> void:
    var skeleton: Skeleton3D = get_skeleton()
    if skeleton == null:
        push_warning("Vanguard additive modifier must be a child of Skeleton3D")
        return
    for idx in range(skeleton.get_bone_count()):
        var label := String(skeleton.get_bone_name(idx)).to_lower()
        if label.contains("spine") or label.contains("chest"):
            spine_bones.append(idx)
    # Three bones max for a low-budget mobile animation correction.
    if spine_bones.size() > 3:
        spine_bones.resize(3)
    print("ARCONT ADDITIVE AIM READY torso_bones=",spine_bones.size())

func trigger_recoil() -> void:
    recoil = 1.0

func set_aim_motion(aiming: bool, pitch_radians: float, yaw_radians: float) -> void:
    aim_weight = move_toward(aim_weight, 1.0 if aiming else 0.0, 0.16)
    pitch = clampf(pitch_radians, -0.20, 0.20)
    yaw = clampf(yaw_radians, -0.18, 0.18)

func _process(delta: float) -> void:
    recoil = move_toward(recoil, 0.0, delta * 9.0)

func _process_modification_with_delta(_delta: float) -> void:
    var skel: Skeleton3D = get_skeleton()
    if skel == null or spine_bones.is_empty():
        return
    var yaw_slice := yaw * aim_weight / float(spine_bones.size())
    var pitch_slice := (pitch * aim_weight + recoil * 0.055) / float(spine_bones.size())
    if absf(yaw_slice) + absf(pitch_slice) < 0.00001:
        return
    var adjustment := Quaternion(Vector3.UP, yaw_slice) * Quaternion(Vector3.RIGHT, pitch_slice)
    for bone in spine_bones:
        skel.set_bone_pose_rotation(bone, skel.get_bone_pose_rotation(bone) * adjustment)
    applied_frames += 1
