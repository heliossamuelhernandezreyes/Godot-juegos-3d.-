# FISURA 0.6 — ARCONT ANIM / ballistic aiming evidence

**Date:** 2026-10-08 UTC · **Engine:** Godot 4.7.2-stable · **Scope:** production game; separate ARCONT research bank

## Problem addressed

Vanguard 0.5 imported 24 native Quaternius animation clips and played them through a single full-body `AnimationPlayer`; the weapon still used a **horizontal** hitscan irrespective of the on-screen camera ray. The touch interface only supported moving and pressing FIRE. The original model uses `Torso`, `Chest` and `Wrist.R` bones, not generic `Spine` and `Hand.R` strings. The first implementation correctly displayed animation but did not mount the custom rifle onto the source wrist.

## Implemented layers

| ARCONT investigation | Production change | Reproducible automated check |
|---|---|---|
| ANIM-001/002 — native motion + additive blending | `scripts/aim_spine_modifier.gd` derives from Godot `SkeletonModifier3D`, runs after animation and applies bounded distributed pitch/yaw plus fading recoil | `tests/aim_pipeline.gd` asserts exact Torso + Chest indices, modifier presence, normalized trajectory and bounded aim |
| ANIM-003 — rig awareness | Source-specific `Wrist.R` discovered from real Godot bone dump and mounted with `BoneAttachment3D` | `tests/aim_pipeline.gd` asserts mount has children |
| Input — dual-touch semantics | Independent movement finger and right-side aim finger, with a UI reticle following cursor/touch | `tests/aim_pipeline.gd` drives two distinct touch IDs and verifies changed aim |
| Ballistics — world coupling | Camera projects a ray into the scene; muzzle-directed physics hitscan uses that 3D aim vector; auto target remains optional when firing without manual aim | `tests/aim_pipeline.gd` checks ray changes and normalization, smoke and playthrough verify gameplay loop |
| ANIM-001 regression | Neutral movement uses source Run clip, aim-locked locomotion uses directional clips; retained Roll/Hit/Death | Existing `tests/vanguard_gameplay.gd` remains a mandatory gate |
| Android readiness | ARM64 debug export preset and separate GitHub workflow with source-pinned editor/templates, setup Java/Android SDK, per-run debug signing | Needs successful APK artifact creation, then **physical device** validation for frame pacing and controls |

## Intended player experience

- Desktop: point and shoot with mouse; space continues accessible automatic targeting; WASD moves, Shift dashes.
- Android: drag lower-left movement region and simultaneously aim by dragging in the right middle screen region; FIRE and IMPULSO remain tappable buttons. Automatic targeting is retained until manual aim is engaged.
- Imported Quaternius asset remains licensed CC0 and source-pinned. This change does not add proprietary models or unverified downloadable assets.

## Explicit limitations

- **This is a post-clip additive chest/torso aiming layer, not an IK solver.** Foot placement, two-hand grip adjustment and full-body IK have not been implemented.
- The modifier's small bone rotations, reticle and raycast pass logic tests but still need visual evaluation at varied camera angles and close cover.
- Current aim auto-targeting behavior differs between mouse, space-key and touch and needs UX study, not a guarantee of competitive-grade precision.
- A successful Android export would prove an installable APK file was built **on Linux CI only**, not that it starts, plays smoothly, avoids overheating or achieves a particular FPS on a POCO X7 Pro. Frame-time p50/p95/p99 and display refresh must be captured separately.
- A per-run debug signing identity is disposable; a subsequently generated debug APK may require uninstalling a previous build before installing. No production signing credentials exist in the repository.

## Next evidence gates

1. CI green on exact game commit: map validation, object and skeletal imports, native clip tests, additive aim, two-touch input, camera bounds, extraction, real framebuffer screenshot.
2. Android debug APK artifact present and checksummed (if export succeeds).
3. Human Android playtest 10–15 minutes plus cold/warm p50, p95, p99 frame pacing, touch accuracy, GPU/memory and thermals.
4. Foot IK and dual-hand weapon IK as a separate experiment with measurable CPU cost and animation snapshots, not a feature claim of this build.
5. Manual art pass: animated aim direction, muzzle-to-reticle agreement against cover and head camera occlusion.

**ARCONT boundary:** runtime code and assets live only in FISURA. Reusable test insights may be documented in ARCONT; its no-production-game-code invariant remains intact.
