# FISURA 0.9.3 — ARCONT native visual-scene inventory

Status: **draft integration; Godot CI evidence required**. This is not an art overhaul, an Android profile or an AAA certificate.

## Purpose

Reactivo-13 is mostly created inside GDScript (base geometry, ArtStage, CinematicStage, node machines, reactor and more). Its `scenes/reactivo_13.tscn` source declares only the root and a script; a static .tscn inspector would incorrectly report 0 lights and few/no props. FISURA must produce the **runtime source of truth** under Godot 4.7.2 before ARCONT can audit environments.

## Outputs produced by FISURA smoke CI

1. `visual.intent.json`: five zones (insertion, Node A/B, reactor, extraction), distinct lighting profiles, asset-role planning, renderer `gl_compatibility`, 60 fps goal and `unmeasured` device status.
2. `tests/capture_scene_inventory.gd`: instantiates the **real** playable Reactivo-13 inside Godot, waits for physics frames, traverses the active runtime subtree and serializes every native node class/path. Lights include color, energy, shadow flags, applicable range. Meshes include instance counts, surfaces, PBR and procedurally created material descriptors including texture paths and emission/normal flag.
3. `reactivo-13-native-scene-snapshot.json`: exact scene .tscn SHA-256, `GITHUB_SHA` (the checked out CI commit), Godot engine version and renderer, plus captured node tree.
4. ARCONT P0 validation: `visual_production_contract.py` checks the actual map, visual contract and scene intent.
5. ARCONT P1 audit: `visual_scene_inventory.py` ingests the native snapshot, checks scene SHA/commit shape, counts runtime nodes, lights, materials and instances but honestly labels the JSON as **external unverified evidence** absent independent CI provenance.
6. `tools/ci/verify_native_visual_inventory.py`: binds CI `GITHUB_SHA` to the snapshot and map scene SHA, checks actual runtime mesh and light population, shadowed directional light, at least six named Poly Haven nodes, PBR normal and emission descriptors and MultiMesh instancing. It emits a receipt and separate SHA-256 listing.
7. GitHub Actions uploads all reports/snapshot/receipt as the `reactivo-13-arcont-native-visual-inventory` artifact.

### Source integrity / versions

- Gameplay code, collisions, map, encounter and Android export remain unchanged.
- CI checks out ARCONT 1.1 integration toolchain at its established immutable SHA and *separately* pins ARCONT P0/P1 experimental tools to commit `9b12f92cb78339ea09b75a05409044c03632401e` (draft PR #49). This intentionally does not reassign the project's canonical Arcont 1.1 version.
- No network asset discovery or staging is activated; all materials and assets are existing resources already in FISURA.
- Snapshot is output of real Godot invocation, *not* a source inference and *not* a fabricated image.
- JSON `capture_source` and `source_commit` alone cannot cryptographically prove native execution; retained engine logs, Actions run and matching artifact hashes provide the CI-bound provenance.

## Next engineering milestones

- Add native Godot exporter as a reusable external-game fixture/adapter, with stricter receipts in ARCONT; then a semantic analyzer for anomalies such as excess accent lights, repeatedly instanced primitive geometry, procedural materials that are identical, missing area coverage, scene camera occlusion and visual focus.
- Build comparably posed and color-managed before/after captures for each zone; record light/node budget differences and prevent GDScript scene-state drift from contaminating comparisons.
- Run the APK on a physical Android device to record actual p50/p95/p99 and thermal/frame-pacing evidence. Native Linux headless node inventory does **not** provide a GPU cost measurement or guarantee mobile FPS.
- Promote only after tests, human art review and real Android QA. ARCONT P2/P3 are not claimed complete.
