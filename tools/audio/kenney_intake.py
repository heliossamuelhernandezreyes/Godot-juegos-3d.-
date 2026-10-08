#!/usr/bin/env python3
"""Fetch *verified* CC0 Kenney OGG assets from a pinned public source checkout.
Never executes downloaded code. Fails closed on changed Git blob, size or codec.
"""
import hashlib
import json
import subprocess
from pathlib import Path
from urllib.request import Request, urlopen

REPO = "manuel-palacio/brickstorm"
REF = "90673e14473430ef16a3b163431dc03d6adc6fd0"
DEST = Path("assets/vendor/kenney_sfx")
# Each SHA1 is Git's blob SHA from the pinned public repository tree.
SOUNDS = {
    "fire_laser.ogg": ("laser.ogg", "ffc89b9e7e2d816fd532e1a06f379a32ef1d4cef", "Sci-fi Sounds", "laserSmall_001.ogg"),
    "fire_mechanical.ogg": ("paddle-hit.ogg", "e1ab0b5a969be92022eded6b4e2050b8da39ea4", "Impact Sounds", "impactPlate_medium_000.ogg"),
    "impact_metal.ogg": ("brick-hit.ogg", "3346d1a9c624d31cdb6d4a67f2b0b405110880eb", "Impact Sounds", "impactMining_000.ogg"),
    "impact_light.ogg": ("wall-hit.ogg", "db4e79ab6649090d66f96b30f5b5ffa0a593040e", "Impact Sounds", "impactPlate_light_002.ogg"),
    "explosion.ogg": ("brick-break.ogg", "019e53664abf859fc5529f95d0db23fa3ac1e42d", "Sci-fi Sounds", "explosionCrunch_000.ogg"),
    "pickup.ogg": ("powerup-get.ogg", "78f119c626bd8e9c18a19c0c9175d3e37d3a7a22", "Interface Sounds", "confirmation_001.ogg"),
    "cover_enter.ogg": ("ui-click.ogg", "7ca77c7186126ce177640aad0c7ccc4c59bf4446", "Interface Sounds", "click_001.ogg"),
}
LICENSES = {
    "Sci-fi Sounds": "https://kenney.nl/assets/sci-fi-sounds",
    "Impact Sounds": "https://kenney.nl/assets/impact-sounds",
    "Interface Sounds": "https://kenney.nl/assets/interface-sounds",
}
DEST.mkdir(parents=True, exist_ok=True)
out = []
for target, (source, expected_blob, pack, original) in SOUNDS.items():
    url = f"https://raw.githubusercontent.com/{REPO}/{REF}/public/audio/{source}"
    with urlopen(Request(url, headers={"User-Agent": "Fisura-v0.9.2-Arcont-CC0/1"}), timeout=25) as response:
        data = response.read(250001)
    assert 1000 <= len(data) < 250000 and data.startswith(b"OggS"), f"Invalid OGG bytes: {target}"
    # Redo the Git blob header without relying on a remote checksum manifest.
    git_blob = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\x00" + data).hexdigest()
    assert git_blob == expected_blob, f"Source blob mismatch for {source}: {git_blob}"
    target_path = DEST / target
    target_path.write_bytes(data)
    probe = subprocess.run(["ffprobe","-v","error","-show_entries","stream=codec_name:format=duration","-of","json",str(target_path)],
                           text=True,capture_output=True,check=True)
    props = json.loads(probe.stdout)
    assert props["streams"][0]["codec_name"] == "vorbis", f"Unexpected codec: {target}"
    duration = float(props["format"]["duration"])
    assert 0.02 < duration < 8.0, f"Unreasonable duration: {target}"
    out.append({
        "file":target,"sha256":hashlib.sha256(data).hexdigest(),"bytes":len(data),
        "duration_seconds":round(duration,4),
        "source_url":url,"source_git_blob_sha1":expected_blob,
        "author":"Kenney", "license":"CC0-1.0","source_pack":pack,
        "original_pack_filename":original,"official_pack_page":LICENSES[pack]
    })
manifest = {
    "license":"CC0-1.0","producer":"Kenney","vendor_intermediary_repository":REPO,
    "vendor_intermediary_revision":REF,
    "license_provenance":"https://kenney.nl/support",
    "note":"Original Kenney CC0 pack sounds, redistributed in a third-party game with file-level credits. OGG binaries copied unchanged, verified with the Git blob SHA and decoded through ffprobe. Not a FISURA subjective sound quality approval.",
    "assets":out
}
(DEST/"PROVENANCE.json").write_text(json.dumps(manifest, indent=2) + "\n",encoding="utf-8")
print("ARCONT CC0 AUDIO INTAKE PASS",len(out),"source-traced OGG files")
