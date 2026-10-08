#!/usr/bin/env python3
"""Vendor one source-pinned Quaternius CC0 fully rigged Vanguard candidate.

This is a human player mesh and its native animation clips, not an unverified
retarget from a separate library. Keep the game's collision and script outside.
"""
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import quote
import hashlib, json, base64
REPO="agentkaerf/FreeModels"
SHA="db3df04d1e4714298a09510b26fb6de6645138a2"
PACKAGE="Ultimate Modular Men- Feb 2022"
FILENAME="Spacesuit.gltf"
SOURCE=f"{PACKAGE}/Individual Characters/glTF/{FILENAME}"
DST=Path("assets/vendor/quaternius/vanguard_spacesuit")
DST.mkdir(parents=True,exist_ok=True)
def get(p, limit):
    url=f"https://raw.githubusercontent.com/{REPO}/{SHA}/{quote(p,safe='/')}"
    with urlopen(Request(url,headers={"User-Agent":"FISURA-Quaternius-CC0-Skeletal-intake/0.5"}),timeout=60) as conn:
        payload=conn.read(limit+1)
    if len(payload)>limit:
        raise ValueError("Oversized asset file: "+p)
    return url,payload
url,data=get(SOURCE,7_000_000)
j=json.loads(data)
images=j.get("images",[])
buffers=j.get("buffers",[])
animations=[a.get("name","") for a in j.get("animations",[])]
print("VANGUARD MODEL META","nodes",len(j.get("nodes",[])),"meshes",len(j.get("meshes",[])),
      "skins",len(j.get("skins",[])),"clips",animations,"images",len(images),"buffers",len(buffers),flush=True)
assert j.get("skins"),"Spacesuit has no rig"
assert len(animations)>1,"Spacesuit missing expected native clips"
dependency_manifest=[]
for category,items in (("images",images),("buffers",buffers)):
    for index,item in enumerate(items):
        uri=item.get("uri")
        if not uri:
            print("EMBEDDED GLTF OBJECT",category,index,flush=True)
            continue
        if uri.startswith("data:"):
            print("EMBEDDED URI",category,index,len(uri),flush=True)
            continue
        if "/" in uri or ".." in uri or "\\" in uri:
            raise ValueError("Unexpected asset dependency URI: "+uri)
        dependency_source=f"{PACKAGE}/Individual Characters/glTF/{uri}"
        dep_url,dep_data=get(dependency_source,9_000_000)
        (DST/uri).write_bytes(dep_data)
        dependency_manifest.append({"name":uri,"source":dep_url,"sha256":hashlib.sha256(dep_data).hexdigest(),"bytes":len(dep_data)})
(DST/FILENAME).write_bytes(data)
lic_url,license_data=get(PACKAGE+"/License.txt",5000)
assert b"CC0 1.0" in license_data,"License not verifiable"
(DST/"SOURCE_LICENSE.txt").write_bytes(license_data)
manifest={
"schema_version":1,"original_creator":"Quaternius","license":"CC0-1.0",
"license_url":"https://creativecommons.org/publicdomain/zero/1.0/",
"source_repo":REPO,"source_commit":SHA,"source":url,"license_source":lic_url,
"model":"Spacesuit","model_sha256":hashlib.sha256(data).hexdigest(),
"license_sha256":hashlib.sha256(license_data).hexdigest(),"bytes":len(data),
"animations":animations,"skins":len(j["skins"]),"meshes":len(j.get("meshes",[])),
"dependencies":dependency_manifest,"runtime_verified":False}
(DST/"PROVENANCE.json").write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
print("VANGUARD CC0 INTAKE PASS",len(animations),"animations",len(data),"bytes",flush=True)

# Source-vetted CC0 Vanguard candidate for Godot 4.7.2 regression campaign.
