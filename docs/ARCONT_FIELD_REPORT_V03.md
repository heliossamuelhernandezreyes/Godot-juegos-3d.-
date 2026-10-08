# FISURA v0.3 — ARCONT production experiment

**Status:** gameplay smoke and synthetic route tests; manual/Android validation outstanding.
**Engine:** Godot 4.7.2-stable. **Reference:** ARCONT `3dd31bd962999f36de264c5bb364f41624ca7f0b`.

## ARCONT concepts promoted to executable game checks

| ARCONT source | FISURA implementation | Automated evidence | Known limit |
|---|---|---|---|
| `MAP_FORGE_STANDARD.md` | `maps/crisol_01.json` now owns cover, prop colliders and industrial seed | Real `tools/map_forge_contract.py` from pinned Arcont | Existing schema allows extension but does not validate custom world_props semantics |
| `AI_NAVIGATION.md` | `scripts/tactical_grid.gd` coarse 1-metre A* global routing + cached local steering | `tests/tactical_validation.gd`: cover detour, reactor detour, 3 objectives reachable | Not a baked navmesh; moving obstacles and crowd-scale performance not measured |
| `PROCEDURAL_ANIMATION.md` | Original mesh-part rig and limited locomotion sway, enemy hit-flash | Godot scene parses and runs | No authored skeletal clips/IK/retargeting |
| `GRAPHICS_ASSET_FOUNDATIONS.md` | Multimesh floor, material reuse, volumetric-looking pipe/shell geometry without physics | Render capture under Xvfb, Godot import | Draw calls/overdraw/device thermal tests missing |
| `ASSET_LICENSE_POLICY.md` | 3 CC0 1K photogrammetric materials plus 2 CC0 textured glTF models, with source hashes | Vendor job, `PROVENANCE.json`, Godot import | No automatic certification of every license outside the verified shortlist |
| `MOBILE_PERFORMANCE_FOUNDATIONS.md` | bounded voices, capped enemies, no dynamic obstacle baking | Source inspection and code caps | Android export, p95/p99 latency and thermals untested |

## Confirmed improvements since 0.2

- Semantic geometry and navigation share 11 fixed prop descriptors and 2 cover guides. The visual stage draws from `world_props`, while pathfinder uses their collider sizes.
- Reaver enemies require direct line of sight for melee hits; blocked line of sight triggers cached A* query, rather than forward motion directly into cover. Neighbor separation is deliberately capped to at most 12 enemies.
- Industrial cathedral: upper wall cladding, gantries, cooling pipes, corner equipment, modular grates, illuminated warning markings, deterministic authored seed. Visual-only additions do not add new unreachable gameplay geometry.
- Real CC0 1K PBR from ARCONT catalog applied to environmental meshes: `concrete_wall_007`, `concrete_floor_worn_02`, `green_metal_rust`. Uses color + OpenGL normal + packed ARM where supported.
- Synthesized sounds (original WAVs assembled in memory) for shots, pickups, hits, damage, dash and victory; 7 pooled voices. Impact sphere and HUD feedback.
- Camera offset used at initialization now matches the follow offset, eliminating the first-frame camera mismatch.

## Risk register

1. Coarse grid navigation can navigate around static boxes but is not equivalent to Recast/Detour. Obstacles moving during gameplay are not represented and steering might still oscillate in dense crowds.
2. Procedural arm/leg pivots are not human-authored animation or IK. Distinct run/dash/attack clips and animation blending remain critical.
3. Photorealistic PBR textures improve surface response, but the original humanoid/robot meshes and procedural architecture are still primitive in silhouette/detail.
4. Generated sounds are functional feedback, not professionally mastered audio. No spatial audio mixing.
5. The new visual shell increases mesh/material/lighting cost. A green CI run on Linux does not prove playable frame rates or 15-minute thermal stability on Android.
6. Android input and perspective camera need a human playtest. No APK has been validated.

## Next validation gates

**Gate 1 — engine smoke:** import, 120-frame runtime and extraction playthrough in exact pinned Godot. **Gate 2 — navigation:** use ARCONT-like obstacle regression test. **Gate 3 — art:** automated real viewport image, with visual review separate from technical success. **Gate 4 — product:** 10-minute playtest on physical hardware, capture telemetry, texture residency, touch ergonomics and behavior under heat. **Gate 5 — AAA intent:** professional character pipeline, production lighting and assets, soundscape, VFX, polish and performance budget.

No claim of AAA-equivalent quality should be made until production/visual and physical-device gates are completed.
