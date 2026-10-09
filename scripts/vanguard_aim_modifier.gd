extends SkeletonModifier3D
## ARCONT ANIM-004 / FISURA tactical pose layer.
## Native imported animation remains authoritative. We add bounded pose
## corrections to source-audited bones AFTER the AnimationPlayer runs.
## This is not contact IK, motion matching, or a replacement for vault clips.
var recoil := 0.0
var aim_weight := 0.0
var pitch := 0.0
var yaw := 0.0
var spine_bones: Array[int] = []
var upper_legs: Array[int] = []
var lower_legs: Array[int] = []
var cover_weight := 0.0
var vault_phase := -1.0
var applied_frames := 0
var tactical_frames := 0

func _ready() -> void:
    var skeleton: Skeleton3D = get_skeleton()
    if skeleton == null:
        push_warning("Vanguard additive modifier must be a child of Skeleton3D")
        return
    for idx in range(skeleton.get_bone_count()):
        var bone_name := String(skeleton.get_bone_name(idx))
        var label := bone_name.to_lower()
        # The real 62-bone Quaternius rig uses Abdomen / Torso / Chest,
        # not generic Spine. Resolve names rather than hardcode bone indices.
        if label == "abdomen" or label == "torso" or label == "chest" or label.contains("spine"):
            spine_bones.append(idx)
        elif bone_name == "UpperLeg.L" or bone_name == "UpperLeg.R":
            upper_legs.append(idx)
        elif bone_name == "LowerLeg.L" or bone_name == "LowerLeg.R":
            lower_legs.append(idx)
    if spine_bones.size() > 3:
        spine_bones.resize(3)
    print("ARCONT ADDITIVE AIM READY torso_bones=", spine_bones.size(),
        " tactical_legs=", upper_legs.size(), "/", lower_legs.size())

func trigger_recoil() -> void:
    recoil = 1.0

func set_aim_motion(aiming: bool, pitch_radians: float, yaw_radians: float) -> void:
    aim_weight = move_toward(aim_weight, 1.0 if aiming else 0.0, 0.16)
    pitch = clampf(pitch_radians, -0.20, 0.20)
    yaw = clampf(yaw_radians, -0.18, 0.18)

func set_tactical_pose(cover_amount: float, vault_progress: float) -> void:
    # Existing CharacterBody3D owns all collision and traversal. The imported
    # skeleton is presentation only; this cannot alter capsule collision.
    cover_weight = clampf(cover_amount, 0.0, 1.0)
    vault_phase = clampf(vault_progress, 0.0, 1.0) if vault_progress >= 0.0 else -1.0

func _process(delta: float) -> void:
    recoil = move_toward(recoil, 0.0, delta * 9.0)

func _process_modification_with_delta(_delta: float) -> void:
    var skel: Skeleton3D = get_skeleton()
    if skel == null or spine_bones.is_empty():
        return
    var vault_tuck := sin(vault_phase * PI) if vault_phase >= 0.0 else 0.0
    var yaw_slice := yaw * aim_weight / float(spine_bones.size())
    # Compression is a 3-bone torso curve, not an overall vertical mesh squash.
    # During the jump a small limb tuck follows the actual physics-owned phase.
    var pitch_slice := (pitch * aim_weight + recoil * 0.055 +
        cover_weight * 0.16 + vault_tuck * 0.24) / float(spine_bones.size())
    if absf(yaw_slice) + absf(pitch_slice) > 0.00001:
        var adjustment := Quaternion(Vector3.UP, yaw_slice) * Quaternion(Vector3.RIGHT, pitch_slice)
        for bone in spine_bones:
            skel.set_bone_pose_rotation(bone, skel.get_bone_pose_rotation(bone) * adjustment)
    if vault_tuck > 0.001 and upper_legs.size() == 2 and lower_legs.size() == 2:
        for bone in upper_legs:
            skel.set_bone_pose_rotation(bone,
                skel.get_bone_pose_rotation(bone) * Quaternion(Vector3.RIGHT, vault_tuck * 0.20))
        for bone in lower_legs:
            skel.set_bone_pose_rotation(bone,
                skel.get_bone_pose_rotation(bone) * Quaternion(Vector3.RIGHT, -vault_tuck * 0.26))
    if cover_weight > 0.001 or vault_tuck > 0.001:
        tactical_frames += 1
    if absf(yaw_slice) + absf(pitch_slice) > 0.00001:
        applied_frames += 1
