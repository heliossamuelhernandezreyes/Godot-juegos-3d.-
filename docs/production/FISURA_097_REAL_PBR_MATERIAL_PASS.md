# FISURA 0.9.7 — Material-first pass on actual procedurally generated geometry

## Why this exists
Primitive meshes generated via Godot code are already renderable 3D geometry. Rebuilding them as Blender assets is not required for a proper PBR surface. This pass addresses the user's request to apply **real metal, concrete, and glass** materials directly to those existing objects rather than demonstrating them in mockups.

## Implementation
- `scripts/reactivo_surface_material_upgrade.gd` gathers the **real already-instantiated MeshInstance3D** from the playable scene (map-owned primitive floor + walls, four authored OBJ pillars, industrial pedestals, cooling towers, center reactor piers, load-bearing pylons, canopies, exit frames, and interconnects).
- It reuses vendored **Poly Haven CC0 1K** texture families `green_metal_rust` and `concrete_wall_007`; each ORMMaterial3D includes actual diffuse, packed AO/roughness/metallic and OpenGL normal textures. **Triplanar UV projection** allows arbitrary BoxMesh dimensions without separate UV authoring.
- Four coolant towers receive small **genuine alpha-blended technical-glass panes**, dark backing and machined edge trim. No refraction, reflection probes, viewport capture textures or expensive custom transparent post-effects. These are inset control/instrument surfaces on existing solids, not fake traversable windows.
- The appearance can be A/B toggled with `world.material_pass.set_material_upgrade_enabled(false/true)`. Exactly the original material overrides are restored for baseline. Added glazing is hidden with baseline.
- Never modifies map JSON, BoxMesh dimensions, StaticBody3D, CollisionShape3D, navmesh, camera, mission state or realtime lights.
- Scene geometry/texture node counts have explicit budgets; glass used sparingly for GL Compatibility Android.

## Verification
- Native Godot `tests/reactivo_surface_materials.gd` checks original map bodies, PBR textures and ARM/normal presence, triplanar mode, genuine alpha transparency on the four panes, reversible materials, no new shadows/lighting or collider moves.
- `tests/capture_reactivo_materials_node_pair.gd` and `tests/capture_reactivo_materials_corridor_pair.gd` record unchanged world+camera BEFORE and AFTER at two meaningful shoulder-camera positions. Raw PNGs + source-commit-bound metadata go through the existing Godot/Pillow visual-diff gate. Pixel differences are **not beauty scores**.
- Android ARM64 debug APK is compiled by GitHub Actions. Hardware FPS and true phone thermals still require separate physical-device measurements.

## Artistic limitation
Materials improve surface character and shading but do **not** automatically replace simplistic silhouettes or the central column's obstruction of the camera. Those need spatial/camera review, not merely texture replacement. The material set is intended as a reversible baseline for later artist-directed topology and asset improvements.
