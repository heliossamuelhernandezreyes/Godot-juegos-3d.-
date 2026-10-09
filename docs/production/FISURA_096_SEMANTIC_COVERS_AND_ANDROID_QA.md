# FISURA 0.9.6 — Map Forge modular cover + Android debug frame pacing

**Status:** stacked draft over PR #21. Existing game collision, controls, mission state, pathfinding and original asset licenses remain authoritative and unchanged.

## Cover art

The seven `authoring.structure_guides[kind=cover]` records in `maps/reactivo_13.json` define the real physical barriers. A new `scripts/reactivo_cover_cassettes.gd` generates seven dedicated render-only industrial cassettes, each positioned and dimensioned **from the exact game map**. Each cassette is composed of cached PBR steel/concrete shells, inset armor plates, forged corner rails, pressure-hull cap, hazard inlays, a restrained status diode and **batched MultiMesh vent louvers**. The source images are existing Poly Haven CC0 vendored steel and concrete textures, with no new download or license claim.

`scripts/art_stage.gd` collects the old cover finish meshes and makes them mutually exclusive with the new cover display. It also toggles visibility of the original blockout **MeshInstance3D**, never the parent `StaticBody3D` or `CollisionShape3D`. The default is the upgraded visual treatment. `set_cover_upgrade_enabled(false)` restores the exact legacy cover visuals for controlled same-build before/after evidence.

`tests/reactivo_modular_cover.gd` uses the real Godot scene and authoritative Map Forge records to assert seven complete cover module roots and that **each BoxMesh and batched louver lies wholly within the original collision AABB**. It also checks shadow-free mesh-only upgrades, old skins toggled correctly, no added lights, no collider modification and unchanged physics node counts. These checks are CI gates; they do not prove good tactical readability on every device.

`tests/capture_reactivo_cover_pair.gd` exports two native Godot PNGs at the same player position, frozen camera/FOV, renderer and mission state. The pair changes exactly the old cover blockout/finish to the new cassette appearance, **not** the Node A turbine or architecture, and is verified with scene SHA, commit hash and bounded change metrics. A labeled contact sheet is supplemental; native Godot screenshots remain raw.

## Android debug hardware instrumentation

`scripts/reactivo_device_perf_probe.gd` attaches **only when `OS.get_name() == "Android" and OS.has_feature("debug")`**. No probe exists in release or desktop/headless CI. It reads real `Time.get_ticks_usec()` intervals between rendered `_process` callbacks, bounds the ring buffer to 1800 samples and writes a **local-only** JSON summary every 30 seconds. It computes p50/p95/p99 frame intervals, mean, sample counts and frames slower than 33.33 ms. It also records the Godot engine FPS and engine-reported per-frame draw calls when available.

This probe does not transmit any data. It does **not** prove a phone is physical rather than emulated, profile the GPU itself, measure thermal/clock frequency, validate frame presenting or produce a score for artistic quality. The synthetic test in Linux validates only percentile arithmetic, not Android runtime performance.

### How to gather a real-device report

Install the debug APK on an **actual ARM64 Android phone**, run a repeatable route through insertion, Node A, Node B, reactor and extraction for more than one 30-second window, then recover the file from the private app data using Android Debug Bridge:

```bash
adb devices -l
adb shell run-as com.fisura.prototype find files -name fisura_qa_frame_pacing.json
adb shell run-as com.fisura.prototype cat files/fisura_qa_frame_pacing.json > fisura_qa_frame_pacing.json
```

The exact `user://` subdirectory and `run-as` availability depend on the phone/debug manifest. If `find` shows a different relative path, use that actual path with `cat`; do not fabricate telemetry if the file is unavailable.

Also record the phone model, Android version, refresh rate, thermal state (if accessible), game route and tested APK GitHub commit. The JSON field `physical_device_verified=false` intentionally remains false until independently documented. Linux screenshot runs and synthetic tests must never be substituted for this.

## Explicit limitations

More meshes are not automatically better. This pass targets silhouette/material articulation while respecting old collisions and shadow/light budgets. PBR and MultiMesh are sensible engineering choices, **not measured 60 FPS**. Real phone review must check cover peek/vault readability, interaction, artifact flickering, texture aliasing, battery and p95/p99 frame pacing before merging.
