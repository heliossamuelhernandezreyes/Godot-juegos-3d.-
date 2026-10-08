# FISURA 0.9 — ARCONT 1.1 tactical mobility integration

## Goal
Bridge responsive mobile shooter movement with explicit authored cover interactions. FISURA remains the Godot game; ARCONT remains a version-pinned source of contracts, validations and optional external agent tooling.

## Implemented
- Godot 4.7.2 `CharacterBody3D` acceleration/deceleration; instant dash remains directional and temporarily invulnerable.
- Seven authored map `structure_guides` of kind `cover` map to **real collision**. No render-only machine may become cover automatically.
- Press **Q** on keyboard or **COBERTURA** in the Android HUD within 1.40m outside a marked cover surface to enter. Cover is manually toggled. Moving along a wall is restricted to its tangent and slowed to 56% normal speed.
- **IMPULSO/Shift** exits cover immediately; the old dash cooldown and movement animation remain.
- Cover cannot trigger from a remote position or while dashing; leaving the cover's neighborhood cancels the state.
- If the imported rig contains an exact `Crouch` clip it plays at idle, otherwise the engine retains its safe default skeletal idle and applies a small visual brace, not a new crouch skeleton/animation.
- HUD reports availability and engagement; no cover hint appears in empty space.
- Press **V** (desktop) or **HOMBRO** (Android) to swap left/right shoulder camera; the collision-aware camera remains authoritative on both sides.

## ARCONT 1.1 integration
- `project.intent.json` describes targets, aspirational frame rate, known quality limits, asset license policy, visual references and safety constraints. Schema: `schemas/project-intent.schema.json` from pinned ARCONT commit `f9f9b3cfeef5f768257f21c4796b2a7653434b64`.
- Smoke CI uses pinned ARCONT Map Forge/mission/viewport validators and validates project intent using Draft 2020-12 JSON Schema. The new Godot cover test checks near/far interactions, tangent movement and dash cancellation.
- The official ARCONT MCP gateway and Development Sessions **are not automatically launched** by CI or GitHub. To use them, run the gateway in an independently authorized environment with the ARCONT and FISURA trees disjoint. Start read-only; enable project writing explicitly only after connecting a compatible MCP client, installing pinned dependencies and reviewing the session plan. GitHub write permissions alone are **not** equivalent to local ARCONT MCP execution.

## Evidence and limits
- Tests run in Linux/headless Godot CI and verify fixed interaction cases only. Device tests must check two-finger aim/movement with UI button focus, frame pacing, battery and thermals on Android.
- This is the **first cover implementation**, not Gears of War's authored mantle, vault, wall transition or motion-matched full-body cover systems.
- No claim of AAA graphics or physical Android performance without recorded device evidence.

## Next acceptance
1. Inspect four new real Godot 1280x720 shots for camera/crosshair/HUD occlusion.
2. Install an APK generated from green CI, play Reactivo-13 from insertion to extraction, toggle cover both sides, exit into dash, and confirm the rifle and reticle remain aligned.
3. Add physical cover snapping/lean and authored crouch/vault animation only after observing the selected rig's real skeleton clips and integrating animation-specific collision tests.
