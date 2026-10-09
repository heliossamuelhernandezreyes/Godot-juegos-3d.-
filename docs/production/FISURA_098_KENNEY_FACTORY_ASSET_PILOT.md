# FISURA v0.9.8 — first genuine Arcont-catalogue-to-Godot Factory Kit

## What changed and what was actually obtained

This change is a real **3D asset import**, not a texture-only mockup. ARCONT's verified catalogue includes **ARC-ASSET-KENNEY-696C714A33FF63A1 (Kenney Factory Kit)**, official source [Kenney Factory Kit](https://kenney.nl/assets/factory-kit), CC0 public domain. ARCONT itself does **not** store these heavy binaries; it stores their metadata.

The exact original game-ready GLB meshes were fetched from the independently hosted, public Kenney asset archive at **shorepine/kenney**, pinned source commit `3694c6879e487c108f55677be7dd2ca75b07cc3b`; FISURA now vendors 10 specific GLB files and their required relative texture `Textures/colormap.png`. All 11 Git blob IDs matched before and after copying. Complete source URL, license, per-file source path, byte identity and mobile limitations are preserved in `assets/vendor/kenney_factory_node_a/PROVENANCE.json`.

This is a deliberately modest, 10-model curated pilot rather than blindly importing the 140-model pack or a huge high-poly Poly Haven kit. GLB imports preserve actual polygon source with an original 512px color-map instead of generating fake cube meshes.

## Genuine model-to-runtime placement

`scripts/reactivo_node_a_kenney_factory.gd` creates exactly 14 actual 3D source instances from the 10 unique GLB prefabs. It places structural frames, machine consoles, piston actuators, industrial valve/pipe sections and a short service catwalk around Node A. The two old 4.3m cyan-side coolant primitive boxes are hidden when the modelled frames are shown, along with the accompanying accent stripes and floating technical glass trim. Their original collision/navigation semantics remain untouched. The new 3D models are **visual only** and add no new physics, navigation or realtime lights. The GLB model kit can be turned OFF/ON independently to inspect legacy-vs-GLB from the exact same live Godot camera, without altering the turbine, player, map or mission.

`scripts/reactivo_cinematic_stage.gd` is responsible for the independent kit subtree; `scripts/reactivo_13_game.gd` binds the old primitive visuals only after the 0.9.7 PBR/glazing layer is fully initialized.

## Gates

- `tools/ci/verify_kenney_factory_kit.py`: verifies exact original SHA-1 Git blob identities, GLB v2 JSON and polygon indices, original PNG dependency and bounded vendored bytes.
- `tests/reactivo_kenney_factory_native.gd`: checks real engine-imported polygon meshes (not BoxMesh), source counts, model toggling, original visual restoration, unchanged collision topology and unchanged light budget.
- `tests/capture_reactivo_kenney_factory_pair.gd`: frozen camera true runtime 1280×720 PNGs with authentic GLB kit off/on, JSON provenance and GitHub commit/scene SHA, checked through the existing `verify_node_a_visual_pair.py` with pixel-difference metrics.
- Full pre-existing ARCONT Map Forge, locomotion, vault, touch, no-auto-fire and mission smoke suites remain mandatory.
- Android ARM64 debug APK built by GitHub Actions. Real physical Android device FPS, thermals and scene readability **not verified**.

## Limitations and next stage

Kenney Factory Kit was created with a stylized modular color-map aesthetic. It produces honest, low-poly real industrial geometry but does **not** automatically provide AAA fidelity or match the existing gritty/photogrammetric Poly Haven surfaces. Use its modular source silhouette as a starting point, retain material palette consistency and avoid excessive model density on Android. An Arcont-driven asset pipeline should automatically select/download/import/QA candidate source models; the current pilot required our GitHub integration because the Arcont registry is metadata-first. Production merge should follow screenshot review and a physical Android profiling session.
