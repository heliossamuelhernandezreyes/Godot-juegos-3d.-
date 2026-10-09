# FISURA 0.9.4 — Node A visual production pilot

**Status:** experimental draft. One visually improved sector, no changes to gameplay, assets' licensing, input, encounter scripts, mission map, objective collision or Android export.

## What is actually new

`scripts/reactivo_node_a_visual_pilot.gd` is a hand-authored deterministic presentation assembly centered behind the existing Node A gameplay console (x=-28, z=4). It consists of a sculpted circular turbine with recessed hub, cyan coolant containment rings, radial fan vanes, worn steel mounts, pipe manifolds, ventilation fins, dark negative-space layering, serial signage and warm safety-color accents.

Art direction relies on the already-local Poly Haven CC0 triplanar steel/concrete PBR maps plus cached BoxMesh primitives and modest procedural cylinder/torus geometry. All pilot meshes have real-time shadow casting disabled, and the entire subtree adds **zero** Light3D and **zero** collision/nav primitives. This is intended as a mobile-Compatibility visual hierarchy experiment, not a finished premium environment or a new third-party asset.

The cinematic stage inserts a toggleable `node_a_pilot` child by calling `set_node_a_pilot_enabled(enabled)`. Normal gameplay displays the new artwork; the evidence script disables it only during the baseline capture, then re-enables it without changing the scene, render setup, materials, game state, camera or lights.

## Real before/after comparison

`tests/capture_reactivo_node_a_pair.gd` instantiates the actual Reactivo-13 scene, positions the real Vanguard player at (-28,1,10), freezes movement/game processes and the cinematic animation, fixes an over-shoulder camera pose/FOV, then captures two raw 1280×720 Godot viewports: pilot OFF vs. pilot ON.

`tools/ci/verify_node_a_visual_pair.py` independently verifies:

- native images untouched (SHA-256) and source commit matching the GitHub CI checkout;
- identical camera pose, FOV, resolution, renderer, and mission state;
- a predeclared normalized Node A ROI (0.23,0.13–0.83,0.87), with meaningful changed pixels and limited image drift outside that ROI;
- a labeled **comparison sheet** as a viewing aid, retaining the two raw framebuffers;
- strictly `human_review_required` for artistic quality and `not_measured` for Android hardware.

This is a **same-build feature-toggle comparison**, not a claim of screenshot equivalence to old PR #19 source or proof of aesthetic improvement. The only independent variable is the visibility of this presentation subtree. Image change does NOT by itself mean a better game.

## CI and acceptance

A native Godot test (`tests/reactivo_node_a_visual_pilot.gd`) verifies bounded pilot mesh count, PBR/emissive materials, no lights, no unbudgeted shadow casters, no colliders, immutable actual game console and unchanged global light/collider counts under the OFF/ON switch. All existing cover, traversal, combat, map, Android-facing code and old screenshot gates remain intact.

Artifacts: `fisura-094-node-a-visual-pilot-before-after`, containing raw PNGs, same-camera contact sheet, source-bound metadata, Python comparison results and SHA files.

The next human review must check whether the turbine is correctly framed and reads at typical phone display scale, whether it blocks the mission prompt in the camera or introduces over-bright cyan noise, and whether the art looks materially better than the previous industrial pedestal. Tweak position/scale/material response if needed; use native screenshots, not mock renders.

No draw-call, fps, GPU-memory, input-lag or thermal claims until the build is profiled on a real Android device. Do not merge into FISURA main while earlier #17–#19 drafts remain gated.
