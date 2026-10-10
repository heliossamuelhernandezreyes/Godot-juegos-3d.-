# LIE: Nucleo Omega — playable hybrid Godot/Lie vertical slice

**Folder:** `games/lie_nucleo/` inside `Godot-juegos-3d.-`. This is a self-contained Godot 4.7.2 project. The existing FISURA/Reactivo 13 root projects remain untouched.

## What is playable

One enclosed 3D industrial arena. Control a third-person operator, collect **three orange Archive Modules**, avoid or eliminate four red enemy drones, then reach the **northern extraction gate**. Player uses actual Godot CharacterBody3D physics, collisions, dash and health; enemies chase and deal damage. Windows / Linux: WASD movement, right-button drag camera, left-click attack (closest drone within 19 m), Shift dash, Space jump, R restart. Touch screen: drag left to steer and right to orbit; DISPARAR and DASH on-screen buttons.

**Visual technology:** The hovering reactor centerpiece is an image-based reconstruction performed through the LIE-07 five-phase Vulkan compute shader inside a Godot Forward+ CompositorEffect, with the LIE-09 native-scene depth comparison for proper foreground/behind relationships. It uses four **procedurally generated albedo/depth sample views** of a sphere at startup, then projects those samples into the game camera, depth-tests and composites without a CPU readback per frame. The sphere is NOT represented by a Godot 3D mesh when Vulkan works.

This first game verifies a real, moving gameplay camera feeding the Lie pipeline. It **does not** claim the Lie-10 complex Blender materials or captured animation are integrated; those will be a separate next milestone. It uses genuine Lie algorithms, not merely Godot with a renamed render mode.

## Run

Open `games/lie_nucleo/project.godot` in Godot 4.7.2 (Forward+ Vulkan) and press Play. There is a plainly labeled conventional sphere fallback if the GPU compositor isn't supported; this must not be counted as successful Lie rendering. This prototype is not an APK or published Android game yet.

## Tests

`.github/workflows/lie-nucleo-smoke.yml` installs Godot and software Vulkan on CI, renders an actual gameplay frame, demands `gpu_ready=true` and multiple LIE compositor frames, collects three objectives programmatically, and tests the win condition. It uploads a real `lie-nucleo-smoke.png` screenshot to GitHub Actions.

## Source attribution / engineering limitations

LIE shaders / effect adapted from [Lie-Engine](https://github.com/heliossamuelhernandezreyes/Lie-Engine), experimental LIE-08 plus LIE-09 compositor, at `feat/lie-09-blender-depth-native-occlusion`. This code remains an experiment; LIE-10 benchmarking on a complex object has not demonstrated faster median frame pacing than Godot rasterization. The core uses a fixed 256² GPU surface, four 64² capture grids, GPU atomics and screen-space splats, and still lacks animation, disocclusion repair, quality adaptivity, persistent capture atlas streaming, native GPU timers and mobile thermal testing.

The game is designed to be extended with actual Blender/Arcont assets and mobile-first HUD and input polish, not to claim commercial readiness.
