extends SkeletonModifier3D
## ARCONT ANIM-002 / ANIM-004: post-animation additive *aim pose*, NOT full IK.
## Godot SkeletonModifier3D executes after AnimationMixer. Imported clips untouched.
## Only small torso angles are applied; root/legs stay motion authored.
var target_pitch := 0.0
var target_yaw := 0.0
var recoil := 0.0
var smoothed_pitch := 0.0
var smoothed_yaw := 0.0
var chest_id := -1
var spine_id := -1
var frame_count := 0

func _ready() -> void:
    active = true
    var skeleton := get_skeleton()
    if skeleton == null:
        return
    for i in range(skeleton.get_bone_count()):
        var lower := skeleton.get_bone_name(i).to_lower()
        if lower.contains("spine") or lower == "torso":
            if spine_id < 0:
                spine_id = i
            chest_id = i
        elif lower.contains("chest"):
            chest_id = i
    if chest_id < 0:
        chest_id = spine_id
    if spine_id == chest_id:
        spine_id = -1
    print("ARCONT AIM LAYER bones=%d chest=%d lower=%d" % [skeleton.get_bone_count(), chest_id, spine_id])

func configure_aim(pitch: float, yaw: float) -> void:
    target_pitch = clampf(pitch, -0.30, 0.30)
    target_yaw = clampf(yaw, -0.25, 0.25)

func add_recoil() -> void:
    recoil = minf(recoil + 0.09, 0.17)

func _process_modification_with_delta(delta: float) -> void:
    var skeleton := get_skeleton()
    if skeleton == null or chest_id < 0:
        return
    var blend: float = 1.0 - exp(-maxf(delta, 0.016) * 12.0)
    smoothed_pitch = lerpf(smoothed_pitch, target_pitch, blend)
    smoothed_yaw = lerpf(smoothed_yaw, target_yaw, blend)
    recoil = move_toward(recoil, 0.0, maxf(delta, 0.016) * 0.60)
    var pitch := smoothed_pitch - recoil
    var yaw := smoothed_yaw
    var bone_pose: Quaternion = skeleton.get_bone_pose_rotation(chest_id)
    var offset: Quaternion = Quaternion(Vector3.RIGHT, pitch * 0.72) * Quaternion(Vector3.UP, yaw * 0.70)
    skeleton.set_bone_pose_rotation(chest_id, (bone_pose * offset).normalized())
    if spine_id >= 0:
        var lower_pose: Quaternion = skeleton.get_bone_pose_rotation(spine_id)
        var lower_offset := Quaternion(Vector3.RIGHT, pitch * 0.28) * Quaternion(Vector3.UP, yaw * 0.30)
        skeleton.set_bone_pose_rotation(spine_id, (lower_pose * lower_offset).normalized())
    frame_count += 1
