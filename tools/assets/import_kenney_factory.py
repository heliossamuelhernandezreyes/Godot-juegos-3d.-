#!/usr/bin/env python3
"""Deterministic CC0 factory kit import from original Kenney creator-upload ZIP.

No opportunistic search, no hidden dependency, no blanket asset mirroring.
Only approved selected genuine GLB assets + original source-license evidence.
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import struct
import sys
import zipfile

SOURCE_SHA = "7e31fb2308e90304672bd15cd18fa9d9f02c03731a8cbc57a8e3e1c181dfb0a7"
SOURCE_URL = "https://opengameart.org/sites/default/files/kenney_factory-kit_3.0.zip"
APPROVED = (
    "machine-fortified",
    "machine-window",
    "machine",
    "pipe-large-valve",
    "pipe-large-long",
    "pipe-glass-large-valve",
    "robot-arm-a",
    "conveyor-long",
    "catwalk-straight",
)
DEST = Path("assets/vendor/kenney_factory_kit")
MAX_MODEL_SIZE = 1_500_000

def main() -> None:
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("factory-kit-source.zip")
    raw = source.read_bytes()
    assert len(raw) < 25_000_000 and hashlib.sha256(raw).hexdigest() == SOURCE_SHA, "Source ZIP not pinned"
    DEST.mkdir(parents=True, exist_ok=True)
    provenance = {
        "provider": "Kenney", "title": "Factory Kit", "version": "3.0",
        "license": "CC0-1.0",
        "source_page": "https://opengameart.org/content/factory-kit",
        "official_page": "https://kenney.nl/assets/factory-kit",
        "archive_url": SOURCE_URL, "archive_sha256": SOURCE_SHA,
        "catalog_source": "ARCONT assets/catalog/kenney/factory-kit.asset.json",
        "selection_policy": "Only selected GLB production candidates, source archive kept upstream",
        "model_files": {},
    }
    total_triangles = 0
    with zipfile.ZipFile(source) as z:
        assert b"Creative Commons" in z.read("License.txt") or b"CC0" in z.read("License.txt")
        for name in APPROVED:
            data = z.read(f"Models/GLB format/{name}.glb")
            assert 20 < len(data) < MAX_MODEL_SIZE, "Asset malformed/excessive: " + name
            magic, version, total_length = struct.unpack_from("<III", data)
            assert magic == 0x46546C67 and version == 2 and total_length == len(data), name
            chunk_length, kind = struct.unpack_from("<II", data, 12)
            assert kind == 0x4E4F534A and chunk_length <= len(data) - 20, name
            spec = json.loads(data[20:20+chunk_length])
            acc = spec["accessors"]
            tris = sum(acc[p["indices"]]["count"]//3 for m in spec.get("meshes", [])
                       for p in m.get("primitives", []) if "indices" in p)
            assert 80 <= tris <= 2000, f"{name} bad/huge triangle budget: {tris}"
            total_triangles += tris
            dest = DEST / (name + ".glb")
            dest.write_bytes(data)
            provenance["model_files"][dest.name] = {
                "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data),
                "triangles_source": tris
            }
        # Kenney's GLB source references a shared palette by relative URI
        # "Textures/colormap.png". Preserve this exact dependency so Godot
        # imports authored colors instead of showing missing-texture errors.
        palette = z.read("Models/GLB format/Textures/colormap.png")
        assert 1000 < len(palette) < 500000 and palette.startswith(b"\\x89PNG\\r\\n\\x1a\\n")
        (DEST / "Textures").mkdir(exist_ok=True)
        (DEST / "Textures" / "colormap.png").write_bytes(palette)
        provenance["texture_files"] = {"Textures/colormap.png": {
            "sha256": hashlib.sha256(palette).hexdigest(),
            "bytes": len(palette)
        }}
        (DEST / "License.txt").write_bytes(z.read("License.txt"))
    assert total_triangles <= 5000, "Selected Kenney source batch exceeds triangle budget"
    provenance["source_triangles_sum"] = total_triangles
    (DEST / "PROVENANCE.json").write_text(json.dumps(provenance, indent=2, ensure_ascii=False)+"\n")
    print(f"FISURA ARCONT KENNEY INTAKE PASS models={len(APPROVED)} source_triangles={total_triangles} archive_sha={SOURCE_SHA}")
if __name__ == "__main__":
    main()
