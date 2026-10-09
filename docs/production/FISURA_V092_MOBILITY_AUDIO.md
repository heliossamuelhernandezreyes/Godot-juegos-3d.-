# FISURA v0.9.2 — authored tactical traversal and CC0 sound package

**Source:** PR #17 FISURA 0.9.1 device correction plus pinned ARCONT 1.1 quality contracts.
**Status:** production candidate pending in-engine validation, screenshot review and physical device feedback. This is not a finished Gears-style animation system.

## Mechanics changed
- Each player can only vault while already attached to a low cover guide backed by a real Godot StaticBody3D box. Source asset crates are 1.4m tall; tall 2m node barriers cannot be vaulted.
- `request_vault()` samples upward, horizontal, and downward future collision sweeps with `CharacterBody3D.test_move`. `_advance_vault()` then performs a timed rise, horizontal cross only above the obstruction, and descent via `move_and_collide`. Mid-course contacts interrupt the traversal instead of moving through a wall. No direct global transform teleport.
- `SALTAR` on Android / `F` on desktop initiates contextual traversal. The action is disallowed outside valid cover and disables shooting while airborne.
- Cover blends into a compressed posture and stands/leans when aimed from cover. Muzzle origin lifts for short-cover peeking, then uses a real muzzle LOS ray, so a 2m wall still blocks a hit. The character may use imported `Jump_Gun` or `Jump` if present, otherwise maintains its imported armed idle.
- These are authored body-root transitions and existing native rig clips, **not** motion-matched full-body vaults, dynamic contact IK, reloading or climbing assets. Those remain separate production tasks.

## Licensed audio
- Kenney [Sci-fi Sounds](https://kenney.nl/assets/sci-fi-sounds), [Impact Sounds](https://kenney.nl/assets/impact-sounds) and [Interface Sounds](https://kenney.nl/assets/interface-sounds) all declare CC0. Seven original OGG sounds have exact file-level hashes and a pinned intermediary commit in `assets/vendor/kenney_sfx/PROVENANCE.json`.
- `tools/audio/kenney_intake.py` performs bounded network asset acquisition **in GitHub Actions**, verifies source Git blob SHA, original OGG page integrity/duration and stores stable receipts. The shipped game does not call the network.
- `scripts/audio_fx.gd` plays imported Vorbis clips with an eight-voice cap and two complementary source samples on shots. Synthetic code-generated beeps were removed. The mix has not been approved on device or headphones.

## ARCONT acceptance
`tests/reactivo_cover_vault.gd`: validate inability to vault tall cover, eligibility at authored crate, physical crossing and landing. `tests/reactivo_audio_budget.gd`: verify source OGG headers/SHA-256, registered runtime paths and voice cap without claiming live headless playback.
Existing full mission playthrough, six 1280x720 Godot render images including mid-vault evidence and ARM64 APK export remain CI gates.

**Release blocker:** Android three-finger movement/aim/fire, cover/vault responsiveness, character boot contact/weapon alignment, and recorded sound balance must be checked on an actual handset. Arcont's finish profile additionally calls for native skeletal contact samples and 15+ minutes of performance/thermal measurements; those are *not* provided by these tests.

## Tactical camera and additive animation hardening (2026-10-08)
- The actual Quaternius Vanguard import has **62 bones / 24 native clips**; its source-audited `Abdomen`, `Torso`, `Chest`, `UpperLeg.L/R`, and `LowerLeg.L/R` bones now drive an additive pose layer during cover and mid-vault. The existing `SkeletonModifier3D` runs after the native `AnimationPlayer` and preserves the physical `CharacterBody3D`.
- The old full-mesh Y-scale squash was removed. Cover applies a restrained three-bone forward brace; crossing low cover adds phase-driven leg flexion. Neither relies on fictitious crouch/jump clips, and neither is hand-contact IK, root-motion matching, or a cinematic authored vault animation.
- The Reactivo-13 shoulder camera now smoothly tightens/lowers its offset and narrows FOV during explicit fire, eases out afterward, and applies a bounded transient camera recoil. At rest the existing 4.25m / 1.30m full-body camera stays intact and maintains the real physics ray clipping.
- Native `tests/reactivo_tactical_animation_camera.gd` checks the source bone map, runtime additive cover and vault states, no whole-mesh squash, camera shoulder offset transition, bounded recoil, and unchanged collider. This confirms runtime wiring, **not** whether the motions look high quality on a handset.

### Remaining release-quality gates
1. Actual physical Android review: three fingers (move/aim/fire), camera interpolation at 30/60fps, cover peeking, safe clip transitions, rifle-hand alignment and sound playback.
2. Authored crouch, brace, vault and landing clips with motion-matched contact timing and validated foot/hand IK. Today's procedural bone tweaks are only an intermediate visual pass.
3. Human evaluation of six authentic 1280x720 render captures; sustained frame-time and thermal measurements for 15+ minutes.

## Combat readability correction
- `reactivo_13_game.gd` only spawns an impact effect for a **real physics ray collision**, avoiding phantom sparks at the maximum ray distance.
- A collider that implements `take_hit_from` or `take_hit` is treated as a confirmed damageable contact and triggers a short amber crosshair cue and the existing licensed impact sound. Ordinary static walls do not confirm enemy damage.
- `tests/reactivo_combat_feedback.gd` exercises a real instrumented `StaticBody3D` target, the two-part camera-to-muzzle ray, the timer and reset of the reticle.
- This is combat feedback wiring, not a final weapon mix or an authored material-specific soundscape.
