#!/usr/bin/env python3
"""Vendor exact 1K CC0 Poly Haven assets selected from the ARCONT catalog.

- Pin supplier identity and file-list hash in the local manifest.
- Use official API's canonical download URLs.
- Download referenced glTF buffers/textures, rewrite URIs to safe local filenames.
- Bound downloads to avoid accidentally ingesting huge textures.
- No runtime network requests; imported game assets remain in this repository.
"""
from __future__ import annotations
import hashlib
import json
import pathlib
import re
import urllib.parse
import urllib.request

# First vetted candidate import: barrel_03 + industrial_wall_lamp.
ROOT=pathlib.Path("assets/vendor/polyhaven")
SLUGS=("barrel_03","industrial_wall_lamp")
HEADER={"User-Agent":"FISURA-Godot-Game/0.2 (CC0 asset intake; github.com/heliossamuelhernandezreyes/Godot-juegos-3d.-)"}
MAX_SINGLE=18*1024*1024
MAX_TOTAL=52*1024*1024
total=0

def grab(url: str) -> bytes:
    global total
    parsed=urllib.parse.urlparse(url)
    if parsed.scheme!="https" or parsed.hostname not in ("api.polyhaven.com","dl.polyhaven.org"):
        raise ValueError("Untrusted asset URL: "+url)
    print("VENDOR GET",url,flush=True)
    request=urllib.request.Request(url,headers=HEADER)
    with urllib.request.urlopen(request,timeout=65) as resp:
        if resp.status != 200:
            raise ValueError("HTTP %d" % resp.status)
        declared=int(resp.headers.get("Content-Length","0"))
        if declared > MAX_SINGLE:
            raise ValueError("Asset exceeds individual size budget")
        data=resp.read(MAX_SINGLE+1)
    if len(data)>MAX_SINGLE:
        raise ValueError("Oversized downloaded file")
    total+=len(data)
    if total>MAX_TOTAL:
        raise ValueError("Asset intake exceeds total size budget")
    return data

def rec(name:str, url:str, data:bytes)->dict:
    return {"file":name,"source_url":url,"size_bytes":len(data),"sha256":hashlib.sha256(data).hexdigest()}

for slug in SLUGS:
    info_url="https://api.polyhaven.com/info/"+slug
    file_url="https://api.polyhaven.com/files/"+slug
    info=json.loads(grab(info_url))
    files=json.loads(grab(file_url))
    if info.get("type") != 2:
        raise RuntimeError("ARCONT preflight: %s is not a 3D model" % slug)
    record=files["gltf"]["1k"]["gltf"]
    root_url=record["url"]
    if not root_url.endswith(".gltf"):
        raise RuntimeError("Expected official 1K .gltf")
    gltf=json.loads(grab(root_url))
    output=ROOT/slug
    output.mkdir(parents=True,exist_ok=True)
    manifest={"schema_version":1,"name":slug,"catalog_ref":"heliossamuelhernandezreyes/Arcont","asset_page":"https://polyhaven.com/a/"+slug,"license":"CC0-1.0","license_page":"https://polyhaven.com/license","source_api":info_url,"files_api":file_url,"files_hash":info.get("files_hash"),"files":[]}
    for collection in ("buffers","images"):
        for index,object_ in enumerate(gltf.get(collection,[])):
            old=object_.get("uri","")
            if not old or old.startswith("data:"):
                continue
            remote=urllib.parse.urljoin(root_url,old)
            suffix=pathlib.PurePosixPath(urllib.parse.urlparse(remote).path).suffix.lower()
            if suffix not in (".bin",".jpg",".jpeg",".png",".webp"):
                raise ValueError("Unexpected binary asset extension: "+suffix)
            new_name=collection+"_"+str(index)+suffix
            data=grab(remote)
            (output/new_name).write_bytes(data)
            object_["uri"]=new_name
            manifest["files"].append(rec(new_name,remote,data))
    local=slug+"_1k.gltf"
    encoded=(json.dumps(gltf,separators=(",",":"),ensure_ascii=False)+"\n").encode("utf-8")
    (output/local).write_bytes(encoded)
    manifest["files"].insert(0,rec(local,root_url,encoded))
    (output/"PROVENANCE.json").write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print("VENDOR PASS",slug,"components",len(manifest["files"]),"bytes",sum(x["size_bytes"] for x in manifest["files"]),"sha256",hashlib.sha256(encoded).hexdigest())
print("VENDOR INTAKE COMPLETE bytes=%d" % total)
