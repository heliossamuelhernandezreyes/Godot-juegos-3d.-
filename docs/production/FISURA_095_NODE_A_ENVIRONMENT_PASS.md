# FISURA 0.9.5 — Node A architectural, floor and cover finish

**State:** draft visual engineering pass; this is not the AAA milestone or real-device Android QA. Stacked on FISURA 0.9.4 PR #20.

## Change

This adds `scripts/reactivo_node_a_environment_pass.gd`, a **render-only** layer around the existing working Node A coolant turbine:

- Modular PBR floor plates, drainage trench grilles, hazard wayfinding and safety strip accents. Reuses already shipped and licensed CC0 Poly Haven steel, concrete and worn-floor texture maps.
- Structural industrial machine-bay frame, rear service cassettes, high mechanical conduit rack, restrained cyan guidance. No shadow-casting new meshes, no lamps.
- Nine cover facade/cap pieces **inside** the existing map-owned `node_a_cover` AABB. Dimensions and center come from `maps/reactivo_13.json` `authoring.structure_guides`, not magic duplicated collision coordinates. The gameplay cover collider itself is untouched.
- Independently toggleable `node_a_environment` stage sibling to `node_a_pilot` from v0.9.4. This isolates the new architecture in same-build visual A/B evidence without hiding the turbine.

The layer creates neither `CollisionObject3D` / `CollisionShape3D` nor `Light3D` instances; uses texture maps already vendored, mesh size caching and disabled dynamic shadow casting for mobile Compatibility.

## Verification

`tests/reactivo_node_a_environment.gd` asserts the true gameplay scene has bounded visual mesh count, **25** floor slabs, **9** cover cladding pieces within gameplay-owned cover center, PBR normal map coverage, no physical collider or new light/shadow, unchanged true Node A interaction point and global scene light/physics totals across the toggle.

`tests/capture_reactivo_node_a_environment_pair.gd` freezes player / camera / mission / animation inside real Godot at the existing Node A shoulder camera and renders exactly two 1280×720 images: environmental pass OFF vs ON, with v0.9.4 turbine ON both times. It writes camera pose + SHA/commit metadata. The existing `tools/ci/verify_node_a_visual_pair.py` is extended to accept a distinct `environment_visible` switch and checks hashes, identical camera, focused ROI change, limited outside-ROI drift and qualitative-review status. Contact sheet is a *viewing aid*, unretouched Godot PNG files remain available.

The smoke CI must pass all existing ARCONT map/semantics, cover traversal, firing and gameplay tests plus the new regression and visual comparison; Android debug build CI must still compile. Actual mobile FPS/thermal draw-call budgets remain **unmeasured**.

## Visual tradeoffs and next review

This is a handcrafted deterministic PBR + primitive geometry architectural finish, not a new photogrammetric environment. In particular, material richness, cover legibility and third-person silhouette require examination of real screenshots at phone display scale. Increasing a scene's mesh count is **not** evidence of AAA fidelity or acceptable GPU cost.

Merged gameplay source, user controls, enemy AI, original objective collision/nav, assets' license receipts, and sound are **not** modified. Keep the PR in draft until human image comparison and physical Android testing.
