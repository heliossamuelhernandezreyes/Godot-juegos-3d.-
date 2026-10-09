#!/usr/bin/env python3
"""Source-pinned Kenney CC0 Factory GLBs: byte, dependency and geometry QA."""
import hashlib
import json
import struct
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/"assets/vendor/kenney_factory_node_a"
INFO=json.loads((BASE/"PROVENANCE.json").read_text())
assert INFO["arcont_catalog_id"] == "ARC-ASSET-KENNEY-696C714A33FF63A1"
assert INFO["license"]["spdx"]=="CC0-1.0"
assert INFO["source_mirror"]["commit"] == "3694c6879e487c108f55677be7dd2ca75b07cc3b"
assert len(INFO["files"])==11
total_meshes=0
total_triangles=0
total_source_bytes=0

for record in INFO["files"]:
    rel=record["path"]
    assert not Path(rel).is_absolute() and ".." not in Path(rel).parts
    data=(BASE/rel).read_bytes()
    raw=b"blob "+str(len(data)).encode()+b"\0"+data
    assert hashlib.sha1(raw).hexdigest()==record["git_blob_sha1"],rel+" modified since source"
    total_source_bytes+=len(data)
    if not rel.endswith(".glb"):
        assert rel=="Textures/colormap.png" and data.startswith(b"\x89PNG\r\n\x1a\n")
        continue
    assert len(data) >=20 and data[:4]==b"glTF",rel+" bad GLB magic"
    version,fullsize=struct.unpack_from("<II",data,4)
    assert version==2 and fullsize==len(data),rel+" bad GLB header/length"
    chunk_length,chunk_type=struct.unpack_from("<I4s",data,12)
    assert chunk_type==b"JSON" and 20+chunk_length<=len(data)
    model=json.loads(data[20:20+chunk_length].decode("utf-8"))
    assert all(img["uri"]=="Textures/colormap.png" for img in model.get("images",[])),rel+" unpinned texture dependency"
    assert model.get("images"),rel+" unexpected textured mesh dependencies"
    assert model.get("meshes") and model.get("buffers"),rel+" missing real polygon data"
    meshes=model["meshes"]
    total_meshes+=len(meshes)
    for m in meshes:
        for face in m["primitives"]:
            assert face["mode"]==4 if "mode" in face else True,rel+" not triangle mesh"
            indices=model["accessors"][face["indices"]]
            assert indices["count"]%3==0
            total_triangles+=indices["count"]//3
assert total_source_bytes < 512*1024
assert total_meshes >= 10 and total_triangles > 1000
print(f"FISURA KENNEY FACTORY SOURCE PASS licensed=CC0 models=10 total_tris={total_triangles} bytes={total_source_bytes} upstream_sha=verified")
