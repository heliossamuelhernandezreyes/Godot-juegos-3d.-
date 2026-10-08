# FISURA 0.8 — Art direction and performance-gated cinematic factory

**Date:** 2026-10-08. **Engine:** Godot 4.7.2-stable.  
**Objective:** visually upgrade the working Reactivo-13 84×66 extraction slice while preserving gameplay, ARCONT map contracts and Android-targeted cost discipline.

## Visual work actually authored

- Dedicated **`reactivo_cinematic_stage.gd`** replaces the old environment decorator dimensioned around 44×44 with an 84×66 industrial cathedral: enclosed segmented canopy, lit skylight, large reactor containment rings, coolant plumbing, machinery banks, perimeter cladding and navigation-colour wayfinding.
- True **Poly Haven 1K CC0 PBR** surfaces (floor, corroded metal and concrete), reused instanced floor via MultiMesh. Source files and checksums from earlier manifest.
- Additional source-verified **Poly Haven CC0** props `industrial_storage_cart` and `industrial_pastic_container`: official API, 1K glTF+textures with SHA-256 and import audit `tests/reactivo_cinematic_vendor_audit.gd`.
- **Bulwark** upgraded from box-only prototype to the Quaternius Sci-Fi Essentials **Enemy_Trilobite**, native skeleton and 9 authored clips. The enemy retains its forward-armor/side-flank damage behavior. Source mirror is pinned to `agentkaerf/FreeModels@db3df04d1e4714298a09510b26fb6de6645138a2`; provenance for this additional model at `assets/vendor/quaternius/scifi_essentials/BULWARK_PROVENANCE.json`. The source license remains CC0.
- Closer shoulder framing, subtle weathered fog/grade, tactical reticle, luminous shots/tracers, high contrast lock gate with warning signage; reactor emergency phase changes light color and oscillation.

## Critical QA regressions — evidence, not marketing

1. **Node A camera occlusion:** actual in-engine screenshot was almost entirely covered by a non-collidable industrial machine. Physics raycast remained green. Machinery was moved away from objective-relative camera probes; `tests/reactivo_art_qa.gd` checks known AABBs vs those probes. Source insight logged to ARCONT.
2. **Actual render pack:** `tests/capture_reactivo_visual_suite.gd` saves insertion, node A, reactor, extraction views at 1280×720 to GitHub Actions. A PNG existing is **not** proof of good composition; inspect all images before treating quality as improving.
3. **Mobile performance not assumed:** scene budget asserts one instanced floor batch with hundreds of tiles, max eight omnidirectional lights, bounded mesh parts and camera distance. It does **not** measure actual render draw calls, GPU RAM, thermal stability or touch latency.
4. **License and import are separate:** provenance does not certify working glTF, so the actual Godot exporter/import process and live Bulwark animation test run alongside old game regressions.
5. **Sustained QA still absent:** Linux CI and Android APK export cannot establish 60/120 FPS, 15 minute thermal results, IK footplant, sound mix, true shooting animation quality or human mission pacing.

## What remains before a genuinely AAA-like vertical slice

- Replace the remaining flat module silhouettes with authored industrial interiors, dedicated high-detail collision meshes, believable worn decals, more light-baking strategy and material tone matching.
- Proper procedural/clip-based contextual cover/vault animations with validated IK, authored muzzle VFX, screen-space feedback polish and spatial audio.
- Camera field-of-view and target blending through moving enemies and all cover angles; visual occlusion test presently covers a limited known class.
- Real device telemetry across cold and warmed sessions (FPS p50/p95/p99, rendered resolution, GPU timings where possible, CPU load, temperatures and memory).
- Human playtest of the full 8–12-minute Reactivo-13 mission with failure/disorientation counts.

**Honest status:** this is a substantial visual production pass over a functional prototype; it is **not a commercial AAA game**. The game repo alone owns engine project/runtime and all art binaries; ARCONT owns source knowledge and cross-system validation.
