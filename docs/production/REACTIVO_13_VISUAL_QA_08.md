# FISURA 0.8 — Reactivo-13, real in-engine visual & combat QA

**Engine:** Godot 4.7.2-stable / Compatibility. **Game scene:** `scenes/reactivo_13.tscn`.  
**ARCONT knowledge/tools pinned:** `b3912c960092377b5984d50320109c0cfdf75b6b`.  
**Evidence status:** Linux Godot 4.7.2 scene import, deterministic extraction and render-capture; Android device *not* yet profiled.

## Improvements actually implemented

- **Scale-correct environment**: `scripts/reactivo_cinematic_stage.gd` now adds 84×66 mission-scaled metal/concrete structural ribs, containment frame, PBR weathered material, node A/B equipment and glowing wayfinding. Stage uses existing source-traced Poly Haven CC0 texture/material records, rather than downloading unsourced meshes. Geometry is visual only; it does not alter ARCONT Map Forge navigation/colliders.
- **Reactor**: independent moving containment rings, floating core, red alert when the defense phase begins. The obsolete Crisol reactor visual is hidden in Reactivo to remove coincident overlapping geometry while preserving canonical collider.
- **Bulwark Mk II**: existing Quaternius CC0 skinned robot reused as heavyweight chassis, with separate frontal PBR shield, warning plates and rear weakpoint. Different front/rear damage behavior remains authoritative, tested with Godot. **NOT** an independently authored AAA boss rig.
- **Combat**: transient capped emissive muzzle flashes, tracer/metal impact slashes and enemy laser effects; EyeDrone now warns for **0.72s** before inflicting damage and cancels if sight is broken; old legacy Crisol behavior stays unchanged.
- **Cinematic framing**: shoulder camera moved closer, FOV tightened, environment fill/luminance reduced; original broad flat blast door now has a segmented PBR façade with individual horizontal plates that disappear together when unlocked.
- **Objective legibility**: named 3D console labels display only when their objective is available, and defense alarm changes reactor colors.
- **Multi-view QA**: `tests/capture_reactivo.gd` produces **four raw 1280×720 actual Godot screenshots** (insertion, node A, reactor, Bulwark) from named scene points; generic new ARCONT `viewport_evidence_gate.py` checks distinct PNG files. This checks evidence file integrity, **not** AAA art quality.

## Audited automated gates

| Test | What is really checked | Remaining gap |
|---|---|---|
| ARCONT Map Forge + Mission Bridge | level JSON / mission objective references, semantic collisions, anchors | No actual crowd/cover traversal guarantee |
| `reactivo_navigation.gd` | routes avoid authored static grid solids | No stair/vertical traversal or crowd navmesh |
| `reactivo_playthrough.gd` | five mission phases, A/B lock, 75s defense, victory | Time budget, hand controls and fatigue not human tested |
| `reactivo_bulwark.gd` test | true frontal 22% damage reduction vs flank | No unique production IK/mech animation |
| `reactivo_attack_telegraph.gd` | no instant EyeDrone damage, pre-fire event and one delayed blast | Human readability and reflex windows not tested |
| `reactivo_art_budget.gd` | stage 80–420 render nodes, 4–7 shadowless local lamps, no accidental render-only colliders | Device GPU time, overdraw, shadows, thermal load unknown |
| 4 real capture angles | Godot render at 1280×720, visible scene and distinct PNG evidence | Human art comparison, HDR/localized atmosphere, custom art direction |

### Visual findings during iteration

The first 0.8 real render still had a small Vanguard, over-bright white floor, huge flat door and overlapping white reactor. These faults were corrected using actual screenshot review: closer camera, darker floor/fill, PBR segment plates and elimination of legacy overlapping reactor artwork. A scripted screenshot passing an integrity gate is necessary **but not sufficient** evidence for a high-quality scene.

### Production deficits (not obscured)

1. Bespoke studio-grade character models/rigs, carefully integrated humanoid reload/cover vaulting, animation state blending/foot IK, facial/character art.
2. Proper cinematic lightmap/reflection probe pipeline, higher-end materials, shadows and atmospheric VFX with Android graphics budget.
3. Professional soundscape and audio mixing, bespoke music, gameplay haptic response, contextual combat animation and aim offset refinement.
4. Physical Android sustained measurements p50/p95/p99, screen aspect ratios, GPU/performance and touch controls; export packaging alone cannot establish target FPS.
5. Human QA of mission 8–12 minutes, encounter fairness and clarity, no photography-grade terrain/model claims.

**Status: visibly improved prototype vertical slice. Not a finished AAA product.**
