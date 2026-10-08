#!/usr/bin/env python3
"""Probe Poly Haven direct asset API for curated CC0 candidates.

Probe-only: never claims a downloaded/validated binary. Designed for ARCONT's
source-identity/license-first workflow. Use a descriptive User-Agent.
"""
import json
import urllib.request

SLUGS=("barrel_03","industrial_wall_lamp","Barrel_01")
HEADERS={"User-Agent": "FisuraGame/0.2 (GitHub repository heliossamuelhernandezreyes/Godot-juegos-3d.-; CC0 asset research)"}

def fetch_json(path: str):
    req=urllib.request.Request("https://api.polyhaven.com/"+path, headers=HEADERS)
    with urllib.request.urlopen(req,timeout=20) as resp:
        return json.load(resp)

def walk(obj, keys=()):
    if isinstance(obj,dict):
        if "url" in obj and isinstance(obj["url"],str):
            yield ("/".join(keys),obj)
        for key,value in obj.items():
            yield from walk(value,keys+(str(key),))
    elif isinstance(obj,list):
        for i,value in enumerate(obj):
            yield from walk(value,keys+(str(i),))

for slug in SLUGS:
    try:
        info=fetch_json("info/"+slug)
        files=fetch_json("files/"+slug)
        if info.get("type")!=2:
            print("POLYHAVEN SKIP",slug,"not a model",info.get("type"))
            continue
        choices=[(path,rec) for path,rec in walk(files) if "dl.polyhaven.org" in rec.get("url","")]
        candidates=[{"key":name,"size":d.get("size"),"url":d["url"]} for name,d in choices if any(x in d["url"].lower() for x in (".glb",".gltf",".zip"))]
        print("POLYHAVEN MODEL",slug,"files_hash",info.get("files_hash"),"formats",len(choices))
        print(json.dumps(candidates[:24],ensure_ascii=False))
    except Exception as exc:
        print("POLYHAVEN PROBE ERROR",slug,repr(exc))
