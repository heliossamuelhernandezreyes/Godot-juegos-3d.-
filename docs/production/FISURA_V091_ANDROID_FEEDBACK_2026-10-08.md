# FISURA 0.9.1 — corrective pass from physical Android screenshots and player report

## Field evidence
2026-10-08: Real landscape screenshots and player report identified (1) shots fired by touching the viewport without pressing DISPARAR; (2) high, near top-down camera unlike Gears-style close shoulder third person; (3) animations rotated inconsistently with movement/aim; (4) pressing COBERTURA seemed ineffective even near visually similar props; (5) thin unpleasant synthetic audio. The reported device play session proves 0.9 was **not** user-accepted; the earlier headless green CI was an insufficient acceptance boundary.

## Root cause and immediate correction
- `player.gd` previously accepted `Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)` on Android, where GUI/touch emulation can generate mouse presses. Mobile trigger is now **explicit button-only** and cannot be set by incidental mouse input. Do NOT disable global touch-to-mouse emulation while depending on ordinary Control Buttons: Godot GUI Buttons need emulation. Native `TouchScreenButton` controls are used for held gameplay actions and work with independent fingers; restart remains a standard GUI button.
- `reactivo_13_game.gd` previously assigned fixed high camera (+2.75 Y, +3.10 Z), targeted a point behind/down from the avatar, and converted a relative right touch into a world-space aim vector. A lower/longer orbiting shoulder camera now rotates incrementally with touch and movement is camera-relative; shooting resolves the current camera reticle to an actual muzzle obstruction-aware ray.
- Cover now accepts all seven authored solid obstacles plus four map crates that already carry `StaticBody3D` in `art_stage.gd`. It moves toward a wall slot using the CharacterBody3D controller instead of teleporting; tangent movement, cover exit/dash and no-through-cover shots are tested. A short visual brace preserves boot-ground contact. This remains a provisional movement/pose system; genuine animation-matched enter, peek, vault and mantle need their own clips and contact testing.
- `audio_fx.gd` removes the old rising/falling exposed sine-sweep firearm beeps. New bounded PCM samples combine filtered noise and low transient thump for firing/impacts; soft musical tones are kept only for UI/victory. **Synthetic replacement is a stopgap, not a professionally sourced CC0 recording or subjective sound approval.**

## ARCONT evidence gates
- `tests/reactivo_input_camera_regression.gd`: two simulated fingers, right-drag yaw/pitch, mobile ignoring incidental left-mouse, independent movement and explicit fire.
- `tests/reactivo_touch_buttons.gd`: native actual `TouchScreenButton` dual-finger press path. This verifies engine event dispatch on Linux CI, not physical handset behavior.
- `tests/reactivo_cover_movement.gd`: 11 world-authoritative physics-backed guides/crates, capsule snapping clearance, constrained tangent travel, dash disengage.
- `tests/reactivo_visual_composition.gd`: safe 3rd-person camera offsets, actor head/foot projected into screen.
- `tests/reactivo_audio_budget.gd`: voice/sample/mix/peak bounds; *not* subjective fidelity.
- Existing full Reactivo mission + actual screenshots + signed Android export remain required.

## Do not claim release quality until physical follow-up
Install test APK, start a mission at full HP, and hold one finger to move while a second rotates the camera. **No weapon shot** should occur except while a dedicated DISPARAR finger is held. Independently verify that HOMBRO and COBERTURA react without blocking movement or looking; both sides of green crates should allow snapping and tangent movement. Stop/rotate while using Roll and Run, checking feet and shoulders remain correctly oriented. Fire into and away from a solid cover wall and confirm no hit passes through. Test headphones and speaker, check SFX peaks. Record actual device, display/orientation, FPS P50/P95/P99, 15-minute thermals and screenshots. If any point fails, keep the PR as a development candidate.

## Next phase beyond this hotfix
Replace provisional synthetic SFX with a provenance-tracked, engine-tested CC0 audio pack; implement full-body animation clips for cover entry/exit/vault, camera damping against walls and animation/contact tests. Do not extrapolate correctness of those future features from these tests.
