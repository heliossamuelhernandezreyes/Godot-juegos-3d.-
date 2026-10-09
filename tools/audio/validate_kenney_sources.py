#!/usr/bin/env python3
"""Offline integrity + contract validation for vendored Kenney CC0 Vorbis sounds.
Godot's headless loader already imports these during project import; a real
speaker/headphone mix and native Android playback are NOT tested here.
"""
import hashlib
import json
from pathlib import Path

root = Path("assets/vendor/kenney_sfx")
receipt = json.loads((root / "PROVENANCE.json").read_text(encoding="utf-8"))
assert receipt["license"] == "CC0-1.0"
assert receipt["vendor_intermediary_revision"] == "90673e14473430ef16a3b163431dc03d6adc6fd0"
assets = receipt["assets"]
assert len(assets) == 7
seen = set()
for sound in assets:
    name = sound["file"]
    assert name not in seen and name.endswith(".ogg") and "/" not in name
    seen.add(name)
    b = (root / name).read_bytes()
    assert hashlib.sha256(b).hexdigest() == sound["sha256"], name
    assert len(b) == sound["bytes"] and 1000 < len(b) < 250000
    assert b.startswith(b"OggS") and b.find(b"\x01vorbis") != -1
    assert 0.03 < sound["duration_seconds"] < 8.0
    assert sound["license"] == "CC0-1.0" and sound["author"] == "Kenney"
source = Path("scripts/audio_fx.gd").read_text(encoding="utf-8")
assert "const POOL_SIZE := 8" in source
for name in seen:
    assert name in source, "Audio runtime omits asset: " + name
for kind in ["fire", "hit", "damage", "dash", "pickup", "cover", "victory", "vault", "land"]:
    assert f'"{kind}"' in source, "Missing gameplay sound event: " + kind
print("REACTIVO AUDIO BUDGET PASS offline=true licensed_sources=7 original_bytes=true voice_cap=8 headless_playback_not_tested=true")
