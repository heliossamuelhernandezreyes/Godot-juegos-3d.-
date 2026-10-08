#!/usr/bin/env python3
"""Source-pinned CC0 animated assets from Quaternius Sci-Fi Essentials Kit Standard.

Subset licensed CC0 by Quaternius; mirrored verbatim at source repository
agentkaerf/FreeModels, pinned commit. No runtime network dependency.
"""
from pathlib import Path
import hashlib, json, urllib.parse, urllib.request
REPO="agentkaerf/FreeModels"
COMMIT="db3df04d1e4714298a09510b26fb6de6645138a2"
SOURCE_PREFIX="Sci-Fi Essentials Kit[Standard]/glTF"
ROOT=Path("assets/vendor/quaternius/scifi_essentials")
FILES=[
"Enemy_QuadShell.gltf","Enemy_QuadShell.bin",
"Enemy_EyeDrone.gltf","Enemy_EyeDrone.bin",
"Gun_Rifle.gltf","Gun_Rifle.bin",
"T_Enemies_Normal.png","T_Enemies_BaseColor_png.png","T_Enemies_ORM.png",
"T_Guns_Batch1_Normal.png","T_Guns_Batch1_BaseColor.png","T_Guns_Batch1_ORM.png",
]
CAP=5*1024*1024
TOTAL_CAP=22*1024*1024
used=0
manifest={
"schema_version":1,"publisher":"Quaternius",
"license":"CC0-1.0","license_url":"https://creativecommons.org/publicdomain/zero/1.0/",
"original_pack":"https://quaternius.com/packs/scifiessentialskit.html",
"redistribution_repo":REPO,"source_commit":COMMIT,
"source_pack_subdirectory":SOURCE_PREFIX,
"purpose":"Godot 4.7.2 animation and visual QA, game-owned assets",
"files":[]}
ROOT.mkdir(parents=True,exist_ok=True)
for name in FILES:
    path=urllib.parse.quote(SOURCE_PREFIX+"/"+name,safe="/")
    url=f"https://raw.githubusercontent.com/{REPO}/{COMMIT}/{path}"
    req=urllib.request.Request(url,headers={"User-Agent":"FISURA-ARCONT-asset-provenance/0.4"})
    with urllib.request.urlopen(req,timeout=50) as response:
        size=response.headers.get("Content-Length")
        if size and int(size)>CAP:
            raise RuntimeError(f"Budget exceeded: {name}")
        data=response.read(CAP+1)
    if len(data)>CAP:
        raise RuntimeError(f"Single file too large: {name}")
    used+=len(data)
    if used>TOTAL_CAP:
        raise RuntimeError("Total asset budget exceeded")
    (ROOT/name).write_bytes(data)
    sha=hashlib.sha256(data).hexdigest()
    manifest["files"].append({"name":name,"url":url,"sha256":sha,"bytes":len(data)})
    print("QUATERNIUS FILE",name,len(data),sha,flush=True)
for character in ["Enemy_QuadShell","Enemy_EyeDrone"]:
    doc=json.loads((ROOT/(character+".gltf")).read_text(encoding="utf-8"))
    assert doc.get("skins"),f"Missing skeleton skin: {character}"
    assert len(doc.get("animations",[]))>=4,f"Missing clips: {character}"
    for img in doc.get("images",[]):
        assert (ROOT/img["uri"]).is_file(),f"Missing image dependency for {character}: {img['uri']}"
    for buffer in doc.get("buffers",[]):
        assert (ROOT/buffer["uri"]).is_file(),f"Missing binary for {character}"
    print("QUATERNIUS ANIMATIONS",character,[a.get("name") for a in doc["animations"]])
for image in json.loads((ROOT/"Gun_Rifle.gltf").read_text(encoding="utf-8")).get("images",[]):
    assert (ROOT/image["uri"]).is_file()
license_url=f"https://raw.githubusercontent.com/{REPO}/{COMMIT}/{urllib.parse.quote('Sci-Fi Essentials Kit[Standard]/License_Standard.txt',safe='/')}"
with urllib.request.urlopen(urllib.request.Request(license_url,headers={"User-Agent":"FISURA-ARCONT-asset-provenance/0.4"}),timeout=30) as response:
    license_content=response.read(5000)
assert b"CC0 1.0" in license_content, "Source license does not establish CC0"
(ROOT/"SOURCE_LICENSE.txt").write_bytes(license_content)
manifest["license_file_sha256"]=hashlib.sha256(license_content).hexdigest()
(ROOT/"PROVENANCE.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
print("QUATERNIUS VENDOR PASS",len(FILES),"bytes",used)
