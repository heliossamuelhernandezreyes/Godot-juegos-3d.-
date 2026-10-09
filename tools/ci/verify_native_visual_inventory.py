#!/usr/bin/env python3
"""CI receipt for real Godot visual inventory: verifies source, provenance and useful stage counts.

Requires an external ARCONT P1 inspection report and the raw Godot-produced
snapshot from the same CI checkout. Not a certification of artistic quality,
physical Android performance or externally supplied snapshot authenticity.
"""
from __future__ import annotations
import argparse
from collections import Counter
import hashlib
import json
import os
from pathlib import Path
import re


def verify(snapshot_file: Path, audit_file: Path, project_root: Path,
           source_commit: str) -> dict:
    raw = snapshot_file.read_bytes()
    payload = json.loads(raw)
    audited = json.loads(audit_file.read_text(encoding="utf-8"))
    scene = (project_root / "scenes/reactivo_13.tscn").read_bytes()
    actual_hash = hashlib.sha256(scene).hexdigest()
    if payload["scene_sha256"] != actual_hash:
        raise ValueError("scene snapshot refers to different .tscn bytes")
    if payload["source_commit"] != source_commit or not re.fullmatch(r"[0-9a-f]{40}", source_commit):
        raise ValueError("native inventory source commit disagrees with CI checkout")
    if payload["renderer"] != "gl_compatibility" or "4.7.2" not in payload["engine_version"]:
        raise ValueError("unexpected engine version / renderer")
    if payload["capture_source"] != "native-godot":
        raise ValueError("capture source metadata invalid")
    if not audited["ok"] or audited["runtime"] is None:
        raise ValueError("ARCONT P1 did not accept snapshot")
    runtime = audited["runtime"]
    if runtime["snapshot_sha256"] != hashlib.sha256(raw).hexdigest():
        raise ValueError("snapshot content disagrees with ARCONT audited SHA")
    if audited["static_source"]["node_count"] != 1:
        raise ValueError("unexpected Reactivo-13 static root count")
    if runtime["node_count"] <= audited["static_source"]["node_count"] + 150:
        raise ValueError("runtime decoration missing: snapshot resembles static source")
    if runtime["light_count"] < 10 or runtime["mesh_nodes"] < 150 or runtime["reported_instances"] < 150:
        raise ValueError("runtime scene visual detail/light coverage is insufficient")

    nodes = payload["nodes"]
    lights = [n for n in nodes if n["type"] in ("OmniLight3D", "DirectionalLight3D", "SpotLight3D")]
    if len(lights) != runtime["light_count"]:
        raise ValueError("ARCONT report light inventory count differs from native capture")
    if sum(1 for n in lights if n.get("shadow_enabled")) < 1:
        raise ValueError("main light has no shadow casters")
    if not any(n["type"] == "OmniLight3D" and not n.get("shadow_enabled") for n in lights):
        raise ValueError("no low-cost practical accent lighting")
    materials = [m for n in nodes for m in n.get("material_descriptors", [])]
    if len(materials) < 80 or not any(m.get("normal_enabled") for m in materials):
        raise ValueError("real material inventory absent or no normal-mapped PBR materials found")
    if not any(m.get("emission_enabled") for m in materials):
        raise ValueError("no emissive environment material observed")
    named_assets = [n["path"] for n in nodes if "Poly Haven CC0" in n["path"]]
    if len(named_assets) < 6:
        raise ValueError("expected actual staged Poly Haven decor was not instanced")
    if not any(n["type"] == "MultiMeshInstance3D" and n.get("instance_count", 0) > 100 for n in nodes):
        raise ValueError("missing instanced floor geometry")
    if audited.get("runtime_complete", False):
        raise ValueError("ARCONT unexpectedly claims independent verification of external snapshot")
    if runtime.get("evidence_status") != "externally_supplied_runtime_snapshot_unverified":
        raise ValueError("ARCONT did not preserve unverified external-evidence status")
    if not any("not authenticated" in s.lower() for s in audited["limitations"]):
        raise ValueError("ARCONT omitted the external CI receipt/provenance caveat")

    report = {
        "protocol": "fisura-native-visual-ci-receipt",
        "version": 1,
        "source_commit": source_commit,
        "scene_sha256": actual_hash,
        "snapshot_sha256": hashlib.sha256(raw).hexdigest(),
        "arcont_inventory_sha256": hashlib.sha256(audit_file.read_bytes()).hexdigest(),
        "engine_version": payload["engine_version"],
        "renderer": payload["renderer"],
        "runtime_node_count": runtime["node_count"],
        "runtime_light_count": runtime["light_count"],
        "shadowed_lights": sum(bool(n.get("shadow_enabled")) for n in lights),
        "mesh_node_count": runtime["mesh_nodes"],
        "reported_instances": runtime["reported_instances"],
        "material_descriptors": len(materials),
        "asset_nodes_polyhaven_labeled": len(named_assets),
        "limitations": ["Headless Linux engine evidence, not mobile FPS/thermal test",
                        "CI ties commit and file digests, but cannot certify artistic quality",
                        "Native scene inventory includes all visited nodes, not GPU draw call counts",
                        "Scene snapshot parser reports unverified until CI provenance is reviewed"]
    }
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("snapshot", type=Path)
    parser.add_argument("audit", type=Path)
    parser.add_argument("--project-root", type=Path, default=Path("."))
    parser.add_argument("--output", type=Path, default=Path("reactivo-13-native-visual-receipt.json"))
    args = parser.parse_args()
    try:
        report = verify(args.snapshot, args.audit, args.project_root, os.environ.get("GITHUB_SHA", ""))
        args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print("REACTIVO NATIVE VISUAL AUDIT PASS",
              "nodes=%d lights=%d shadows=%d meshes=%d materials=%d vendor=%d" % (
                  report["runtime_node_count"], report["runtime_light_count"], report["shadowed_lights"],
                  report["mesh_node_count"], report["material_descriptors"],
                  report["asset_nodes_polyhaven_labeled"]))
        return 0
    except (OSError, ValueError, TypeError, KeyError, json.JSONDecodeError) as exc:
        print("REACTIVO NATIVE VISUAL AUDIT FAIL", exc)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
