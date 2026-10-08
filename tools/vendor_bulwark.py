#!/usr/bin/env python3
"""Source-pinned Quaternius CC0 heavy robot with real skinned animation."""
import json, hashlib, urllib.request, urllib.parse
from pathlib import Path
SRC="agentkaerf/FreeModels"
REV="db3df04d1e4714298a09510b26fb6de6645138a2"
PACK="Sci-Fi Essentials Kit[Standard]/glTF/"
DIR=Path("assets/vendor/quaternius/scifi_essentials")
FILES=("Enemy_Trilobite.gltf","Enemy_Trilobite.bin",
       "T_Enemies_Large_Normal.png","T_Enemies_Large_BaseColor.png","T_Enemies_Large_ORM.png")
assert (DIR/"SOURCE_LICENSE.txt").exists()
lic=(DIR/"SOURCE_LICENSE.txt").read_bytes()
assert b"CC0 1.0" in lic
total=0
records=[]
for file in FILES:
    link=f"https://raw.githubusercontent.com/{SRC}/{REV}/{urllib.parse.quote(PACK+file,safe='/')}"
    with urllib.request.urlopen(urllib.request.Request(link,headers={"User-Agent":"FISURA-0.8-Arcont-CC0-model-audit"}),timeout=60) as h:
        data=h.read(11_000_000)
    if len(data)>10_000_000:
        raise RuntimeError("Source data exceeds approved size")
    total+=len(data)
    if total>25_000_000:
        raise RuntimeError("Vendor total size budget exceeded")
    (DIR/file).write_bytes(data)
    records.append({"name":file,"official_author":"Quaternius","source_mirror":link,
                    "size_bytes":len(data),"sha256":hashlib.sha256(data).hexdigest()})
    print("BULWARK FILE",file,len(data),flush=True)
doc=json.loads((DIR/"Enemy_Trilobite.gltf").read_text())
assert len(doc.get("skins",[]))>=1
assert len(doc.get("animations",[]))>=8
assert all((DIR[x["uri"]]).is_file() for x in doc.get("images",[]))
assert all((DIR[x["uri"]]).is_file() for x in doc.get("buffers",[]))
record={"model":"Enemy_Trilobite","source_pack":"https://quaternius.com/packs/scifiessentialskit.html",
        "source_mirror_commit":REV,"license":"CC0-1.0",
        "license_file":"assets/vendor/quaternius/scifi_essentials/SOURCE_LICENSE.txt",
        "animations":[v["name"] for v in doc["animations"]],"skins":len(doc["skins"]),"files":records}
(DIR/"BULWARK_PROVENANCE.json").write_text(json.dumps(record,indent=2)+"\n")
print("BULWARK VENDOR PASS",len(records),"clips",len(doc["animations"]))

# Additional binary dependencies are stored only in the game, not ARCONT.
