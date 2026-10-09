# FISURA 0.9.8 — Genuine ARCONT catalog 3D models in Node A

The user requested replacing cube-based scenery with third-party authored 3D assets from ARCONT Asset Vault. This implementation **actually imports source-pinned GLB files** rather than rendering more BoxMesh geometry or misrepresenting catalog JSON records as model binaries.

## Source and provenance

- Asset Vault record: `heliossamuelhernandezreyes/Arcont/assets/catalog/kenney/factory-kit.asset.json`
- Official creator's asset page: https://kenney.nl/assets/factory-kit
- Creator Kenney uploaded the **Factory Kit 3.0** source under CC0 at https://opengameart.org/content/factory-kit
- Source ZIP: https://opengameart.org/sites/default/files/kenney_factory-kit_3.0.zip
- Locked ZIP SHA-256: `7e31fb2308e90304672bd15cd18fa9d9f02c03731a8cbc57a8e3e1c181dfb0a7`.
- Only nine chosen original GLB models and their single required external `Textures/colormap.png` palette were added to FISURA; the source archive and unused 134 models are not bundled.
- `tools/assets/import_kenney_factory.py` securely enforces the original digest, creator license, GLB 2.0 headers/JSON, polygon bound and per-model hashes in `assets/vendor/kenney_factory_kit/PROVENANCE.json`.
- The FISURA-specific licensed GLB files belong in this game repository, **not ARCONT's metadata vault**.

## Scene and gameplay

`scripts/reactivo_node_a_real_factory_kit.gd` creates an actual factory assembly. Two visual-only Node A coolant towers (old generic `BoxMesh`) plus two artificial glow strips are hidden and exchanged for authored mechanical machine blocks, true framed inspection windows, pressure valves, robot arms, conveyor and overhead pipe/catwalk pieces. The visual-only replacement is reversible through `cinematic_stage.set_node_a_factory_kit_enabled(bool)`. Source glTF scenes preserve their embedded colored materials. No player collision, navigation, tactical cover, objective routes, HUD controls or mission state changes.

The original source meshes have hundreds, not thousands, of triangles per imported component; this is promising for mobile but it **does not certify real phone FPS**. The replacement makes no AAA photorealism claim: Kenney's original is a deliberately stylized low-poly factory kit. Real asset topology improves shape variety but must be artistically integrated with the surrounding Poly Haven PBR materials.

## Evidence

`tests/reactivo_real_factory_assets.gd` verifies exact authorized CC0 provenance, imported mesh nodes, swap A/B, no new source light/collider and unchanged whole-scene physics/lighting. `tests/capture_reactivo_factory_pair.gd` takes two native 1280×720 Godot camera-locked frames of the playable scene, verified by scene SHA + commit SHA with a transparent image-difference report. CI attaches untouched source PNGs. Before/after pixel change is **not an artistic quality score**. Physical Android testing and runtime device metrics remain separate requirements.
