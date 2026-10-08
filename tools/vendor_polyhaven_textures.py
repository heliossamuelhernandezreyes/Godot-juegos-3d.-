#!/usr/bin/env python3
"""Pinned Poly Haven CC0 texture acquisition for FISURA.

Selected asset IDs originate from the ARCONT Asset Vault. This operation
downloads 1K JPEG PBR maps directly from official API URLs, records hashes,
and vendors bounded bytes to our *game* repo, never to ARCONT.
"""
import hashlib
import json
from pathlib import Path
import urllib.parse
import urllib.request

# Canonical CC0 shortlist evaluated using ARCONT catalog.
SLUGS = ("concrete_wall_007", "concrete_floor_worn_02", "green_metal_rust")
ROOT = Path("assets/vendor/polyhaven_materials")
HEADERS = {"User-Agent": "FISURA-Godot-Game/0.3 (CC0 asset intake, github.com/heliossamuelhernandezreyes/Godot-juegos-3d.-)"}
CAP = 8 * 1024 * 1024

def fetch(url: str) -> bytes:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != "https" or parsed.hostname not in {"api.polyhaven.com", "dl.polyhaven.org"}:
        raise ValueError("Non-official Poly Haven download " + url)
    print("TEXTURE DOWNLOAD", url, flush=True)
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=45) as response:
        data = response.read(CAP + 1)
    if len(data) > CAP:
        raise ValueError("Texture exceeded size cap")
    return data

for slug in SLUGS:
    info_url = "https://api.polyhaven.com/info/" + slug
    file_url = "https://api.polyhaven.com/files/" + slug
    info = json.loads(fetch(info_url))
    files = json.loads(fetch(file_url))
    if info.get("type") != 1:
        raise ValueError("Not a verified texture: " + slug)
    print("TEXTURE ROOT",slug,list(files.keys()),flush=True)
    def channel_record(code):
        names = {"diff": ("Diffuse","diff","diffuse"),"nor_gl": ("nor_gl","NormalGL","nor"),"arm": ("arm","ARM")}[code]
        for name in names:
            if name in files:
                layer = files[name].get("1k",{})
                for fmt in ("jpg","png"):
                    candidate=layer.get(fmt)
                    if isinstance(candidate, dict) and candidate.get("url"):
                        return candidate,fmt
        legacy=files.get("1k",{}).get("jpg",{}).get(code)
        if isinstance(legacy,dict) and legacy.get("url"):
            return legacy,"jpg"
        return None,None
    if channel_record("diff")[0] is None:
        raise ValueError("Missing 1K diffuse map for "+slug)
    folder = ROOT/slug
    folder.mkdir(parents=True, exist_ok=True)
    manifest = {
        "asset": slug, "source_page": "https://polyhaven.com/a/" + slug,
        "license": "CC0-1.0", "license_url": "https://polyhaven.com/license",
        "arcont_catalog": "heliossamuelhernandezreyes/Arcont",
        "api_files_hash": info.get("files_hash"), "files": []
    }
    for channel in ("diff", "nor_gl", "arm"):
        entry,fmt = channel_record(channel)
        if not isinstance(entry, dict) or not entry.get("url"):
            continue
        remote = entry["url"]
        data = fetch(remote)
        filename = channel + "." + fmt
        (folder/filename).write_bytes(data)
        manifest["files"].append({
            "name": filename, "source": remote,
            "size_bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()
        })
    (folder/"PROVENANCE.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print("TEXTURE VENDOR PASS", slug, len(manifest["files"]), flush=True)
print("TEXTURE INTAKE PASS")
