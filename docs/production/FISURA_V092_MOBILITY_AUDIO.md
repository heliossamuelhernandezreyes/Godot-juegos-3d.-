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
`tests/reactivo_cover_vault.gd`: validate inability to vault tall cover, eligibility at authored crate, physical crossing and landing. `tests/reactivo_audio_budget.gd`: decode source OGG, verify SHA-256 and voice cap.
Existing full mission playthrough, 1280x720 Godot render evidence and ARM64 APK export remain CI gates.

**Release blocker:** Android three-finger movement/aim/fire, cover/vault responsiveness, character boot contact/weapon alignment, and recorded sound balance must be checked on an actual handset. Arcont's finish profile additionally calls for native skeletal contact samples and 15+ minutes of performance/thermal measurements; those are *not* provided by these tests.
