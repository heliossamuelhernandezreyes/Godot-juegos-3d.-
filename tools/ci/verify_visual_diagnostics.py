#!/usr/bin/env python3
"""Produce CI-bound visual diagnosis receipt and human-readable summary (not a beauty score)."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path

def build_report(diagnostics_file: Path, native_file: Path, commit: str) -> tuple[dict, str]:
    diag = json.loads(diagnostics_file.read_text(encoding="utf-8"))
    raw = native_file.read_bytes()
    snap = json.loads(raw)
    if not diag.get("ok") or diag.get("protocol") != "arcont-visual-scene-diagnostics":
        raise ValueError("ARCONT P1 diagnostics invalid")
    if diag["evidence_status"] != "externally_supplied_runtime_snapshot_unverified":
        raise ValueError("unverified external-provenance status not preserved")
    if diag["source_commit"] != commit or snap["source_commit"] != commit or len(commit) != 40:
        raise ValueError("diagnosis does not match the checked-out GitHub commit")
    if diag["snapshot_sha256"] != hashlib.sha256(raw).hexdigest():
        raise ValueError("snapshot SHA mismatch")
    if diag["scene_sha256"] != snap["scene_sha256"] or diag["renderer"] != "gl_compatibility":
        raise ValueError("scene hash/renderer mismatch")
    f = diag["facts"]
    if f["node_count"] < 400 or f["mesh_nodes"] < 250 or f["all_light_count"] < 10:
        raise ValueError("runtime art/tree inventory incomplete")
    if f["light_positions_missing"] != 0:
        raise ValueError("light position missing for spatial analysis")
    if "unrecorded" in f["mesh_instances_by_geometry_type"]:
        raise ValueError("mesh primitives were not captured")
    if f["materials"]["observed_descriptors"] < 200:
        raise ValueError("missing PBR material metrics")
    # Real art-stage StaticBody3D and CollisionShape3D descendants are
    # game-owned props generated from maps/reactivo_13.json, not invalid decor.
    # Insist that ARCONT traces them to authoritative Map Forge world_props.
    if f.get("gameplay_semantic_collision_nodes_in_art_stage") != 18:
        raise ValueError("expected nine game-owned world props and their collision shapes")
    if f.get("total_suspicious_colliders") != 0 or f.get("semantic_collider_mismatches"):
        raise ValueError("unmapped or mispositioned collision nodes in the visual stage")
    if f.get("unmeasured_semantic_box_sizes") != 0:
        raise ValueError("native exporter must capture the Map Forge collision box dimensions")
    zones = diag["zones"]
    if len(zones) != 5 or any(z["sampling_status"] != "anchor_center_only_not_camera_visibility" for z in zones):
        raise ValueError("all five zones require actual map anchors")
    if any(z["mesh_centers_in_radius"] is None or z["lights_reaching_anchor"] is None for z in zones):
        raise ValueError("missing spatial zone observations")

    receipt = {
        "protocol": "fisura-visual-zone-diagnostics-receipt", "version": 1,
        "source_commit": commit, "native_sha256": hashlib.sha256(raw).hexdigest(),
        "diagnostics_sha256": hashlib.sha256(diagnostics_file.read_bytes()).hexdigest(),
        "engine": snap["engine_version"], "renderer": diag["renderer"],
        "zones_sampled": len(zones), "budget_warnings": len(diag["budget_warnings"]),
        "scene_node_count": f["node_count"], "light_count": f["all_light_count"],
        "distinct_material_signatures": f["materials"]["unique_parameter_signatures"],
        "unique_albedo_paths": f["materials"]["unique_albedo_texture_paths"],
        "semantic_map_collision_nodes_reconciled": f["gameplay_semantic_collision_nodes_in_art_stage"],
        "unmapped_collider_nodes": f["total_suspicious_colliders"],
        "approval": "engineering-evidence-only",
        "limitations": [
            "CI ties supplied native snapshot to source commit and exact scene SHA",
            "Light overlap is sphere/range potential only, not visibility or measured illuminance",
            "Mesh center counts are neither on-screen visibility nor GPU draw calls",
            "Material parameter signatures are not objective artistic quality",
            "No Android frame pacing, thermal profile, or human playtest measured"
        ]
    }
    m = f["materials"]
    lines = [
        "# FISURA 0.9.3 — diagnóstico visual de Reactivo-13",
        "",
        "Captura auténtica de Godot en CI y análisis de Arcont P1. No mide belleza ni rendimiento en Android.",
        "",
        f"Commit: {commit} | Motor: {snap['engine_version']} | Renderer: {diag['renderer']}",
        "", "## Inventario observado", "",
        "| Indicador | Valor |", "|---|---:|",
        f"| Nodos | {f['node_count']} |",
        f"| Nodos de malla | {f['mesh_nodes']} |",
        f"| Instancias declaradas | {f['total_mesh_instances']} |",
        f"| Luces / con sombras | {f['all_light_count']} / {f['shadowed_light_count']} |",
        f"| Materiales registrados / firmas distintas | {m['observed_descriptors']} / {m['unique_parameter_signatures']} |",
        f"| Normales / emisión activadas | {m['normal_enabled_descriptors']} / {m['emission_enabled_descriptors']} |",
        f"| Texturas albedo distintas referenciadas | {m['unique_albedo_texture_paths']} |",
        f"| Nodos de colisión reconciliados con Map Forge | {f['gameplay_semantic_collision_nodes_in_art_stage']} |",
        f"| Colisiones de arte sin correspondencia semántica | {f['total_suspicious_colliders']} |",
        "", "## Muestreo por ancla de misión", "",
        "Mallas: centros dentro del radio. Luces: rango geométrico que alcanza el ancla (sin oclusiones ni sombras).",
        "",
        "| Zona | Ancla | Radio m | Centros de malla | Luces locales potenciales |",
        "|---|---|---:|---:|---:|",
    ]
    for z in zones:
        lines.append(f"| {z['id']} | {z['anchor_id']} | {z['sample_radius_m']} | {z['mesh_centers_in_radius']} | {z['lights_reaching_anchor']} |")
    lines.extend(["", "## Geometría instanciada por tipo", ""])
    for shape, count in list(f["mesh_instances_by_geometry_type"].items())[:15]:
        lines.append(f"- {shape}: {count}")
    lines.extend(["", "## Alertas técnicas para revisión", ""])
    for w in diag["budget_warnings"]:
        lines.append(f"- {w['code']}: zona={w.get('zone','global')}; datos={json.dumps({k:v for k,v in w.items() if k!='message'},ensure_ascii=False)}. {w.get('message','')}")
    if not diag["budget_warnings"]:
        lines.append("- Sin alertas basadas en presupuestos y alcance geométrico.")
    lines.extend(["", "## Límites de evidencia", "",
        "- No son draw calls, luz medida, visibilidad ni garantía de calidad artística.",
        "- Una firma repetida de material no implica necesariamente que dos objetos se vean idénticos.",
        "- Falta medición sostenida en Android y comparación antes/después con cámara equivalente.",
        ""])
    return receipt, "\n".join(lines)

def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("diagnostics", type=Path)
    p.add_argument("snapshot", type=Path)
    p.add_argument("--receipt", type=Path, default=Path("reactivo-13-visual-diagnostics-receipt.json"))
    p.add_argument("--markdown", type=Path, default=Path("reactivo-13-visual-diagnostics.md"))
    a = p.parse_args()
    try:
        receipt, md = build_report(a.diagnostics, a.snapshot, os.environ.get("GITHUB_SHA", ""))
        a.receipt.write_text(json.dumps(receipt, indent=2, ensure_ascii=False)+"\n", encoding="utf-8")
        a.markdown.write_text(md, encoding="utf-8")
    except (ValueError, KeyError, OSError, TypeError, json.JSONDecodeError) as e:
        print("REACTIVO VISUAL DIAGNOSIS FAIL", e)
        return 1
    print("REACTIVO VISUAL DIAGNOSIS PASS zones=%d notices=%d" %
          (receipt["zones_sampled"],receipt["budget_warnings"]))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
