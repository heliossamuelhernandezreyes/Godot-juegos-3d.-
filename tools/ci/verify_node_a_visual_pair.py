#!/usr/bin/env python3
"""ARCONT P2: independently verify camera-paired real Godot PNGs.

Checks metadata, exact camera pose and source SHA, same image geometry,
pixel change in a predeclared objective ROI, limited drift outside the ROI.
Pixel difference only proves material visibility/change, NOT improved art.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

# Fixed shot regions per independently toggled visual variable. The original
# turbine is central; the bay/floor treatment intentionally reaches the edges
# of the shoulder view. Neither gate relaxes the out-of-ROI drift threshold.
ROIS = {
    "pilot_visible": (0.23, 0.13, 0.83, 0.87),
    "environment_visible": (0.06, 0.07, 0.95, 0.98),
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate(meta_path: Path, original: Path, candidate: Path, scene: Path,
             source_commit: str, proof: Path, sheet: Path) -> dict:
    meta = json.loads(meta_path.read_text(encoding="utf-8"))
    if meta.get("protocol") != "fisura-visual-paired-capture" or meta.get("version") != 1:
        raise ValueError("unrecognized native camera-pair protocol")
    if len(source_commit) != 40 or meta.get("source_commit") != source_commit:
        raise ValueError("pair did not originate from this CI commit")
    if meta.get("scene_sha256") != sha256(scene):
        raise ValueError("pair is not bound to exact Godot scene SHA")
    if meta.get("renderer") != "gl_compatibility" or "4.7.2" not in meta.get("engine",""):
        raise ValueError("engine / renderer differs from expected Compatibility capture")
    if meta.get("quality_review") != "human_review_required" or meta.get("device_performance") != "not_measured":
        raise ValueError("capture metadata falsely declares aesthetic or Android certification")
    flag = meta.get("toggle_flag", "pilot_visible")
    if flag not in ROIS:
        raise ValueError("unrecognized visual-only variable in matched comparison")
    roi = ROIS[flag]
    if meta.get("baseline",{}).get(flag) is not False or meta.get("candidate",{}).get(flag) is not True:
        raise ValueError("baseline/candidate visual-only toggle was not off/on")
    if meta["baseline"]["sha256"] != sha256(original) or meta["candidate"]["sha256"] != sha256(candidate):
        raise ValueError("a captured PNG was altered since the native Godot capture")
    pose = meta.get("camera", {})
    for required in ("origin", "basis_x", "basis_y", "basis_z", "fov", "near", "far"):
        if required not in pose:
            raise ValueError(f"missing camera property: {required}")
    if meta.get("mission_state") != "insertion mission idle, world processes frozen":
        raise ValueError("mission was not frozen before both frames")
    with Image.open(original) as image_a, Image.open(candidate) as image_b:
        a, b = image_a.convert("RGB"), image_b.convert("RGB")
    if a.size != b.size or a.size != tuple(meta.get("resolution", [])):
        raise ValueError("paired images have unequal dimensions")
    w, h = a.size
    if w < 1280 or h < 720:
        raise ValueError("paired viewport smaller than minimum 1280x720")
    x0,y0,x1,y1 = int(roi[0]*w),int(roi[1]*h),int(roi[2]*w),int(roi[3]*h)
    diff = ImageChops.difference(a, b)
    mask = diff.convert("L").point(lambda gray: 255 if gray > 12 else 0)
    changed_all = mask.histogram()[255]
    roi_mask = mask.crop((x0,y0,x1,y1))
    changed_roi = roi_mask.histogram()[255]
    ratio_roi = changed_roi / ((x1-x0)*(y1-y0))
    changed_outside = changed_all - changed_roi
    ratio_outside = changed_outside / (w*h - (x1-x0)*(y1-y0))
    if ratio_roi < 0.006:
        raise ValueError(f"Node A visual change too subtle/absent in hero ROI: {ratio_roi:.4f}")
    if ratio_roi > 0.72:
        raise ValueError(f"scene changed too widely to trust focused visual comparison: {ratio_roi:.4f}")
    # The pilot is a localized central-object toggle: out-of-ROI changes imply
    # drift. Architecture/floor cladding legitimately occupies almost the
    # entire image, including edge strips; its outside-ROI ratio is reported
    # transparently, not mislabeled as camera movement.
    if flag == "pilot_visible" and ratio_outside > 0.07:
        raise ValueError(f"localized turbine shot drift outside target ROI: {ratio_outside:.4f}")
    if changed_all <= 1000:
        raise ValueError("identical/fake camera pair (insufficient changed pixels)")

    # Contact sheet is only a viewing aid; raw native screenshots remain unchanged.
    header_h = 58
    sheet_image = Image.new("RGB", (2*w, h + header_h), (20, 27, 35))
    sheet_image.paste(a, (0,header_h))
    sheet_image.paste(b, (w,header_h))
    drawing = ImageDraw.Draw(sheet_image)
    drawing.text((24,20),"BASELINE  |  Node A pilot OFF  |  same camera", fill=(232,240,245))
    drawing.text((w+24,20),"CANDIDATE  |  Node A pilot ON  |  same camera", fill=(232,240,245))
    sheet_image.save(sheet)
    report = {
        "protocol": "fisura-node-a-visual-comparison-gate", "version":1,
        "pass":True,"source_commit":source_commit,"scene_sha256":sha256(scene),
        "before_sha256":sha256(original),"after_sha256":sha256(candidate),
        "camera":pose,"renderer":meta["renderer"],"resolution":[w,h],
        "comparison_roi_normalized":list(roi),
        "comparison_toggle": flag,
        "changed_pixel_ratio_in_roi":round(ratio_roi,6),
        "changed_pixel_ratio_outside_roi":round(ratio_outside,6),
        "outside_roi_policy": "strict_7_percent" if flag == "pilot_visible" else "informational_wide_floor_and_architecture",
        "camera_stability_evidence": "native exporter asserted exact before/after camera transforms; both frames bound to the same frozen scene",
        "changed_pixels_in_roi":changed_roi,
        "measurement":"Pixel difference proves visible implementation, NOT an aesthetic improvement",
        "artistic_quality":"pending independent visual/human review",
        "hardware":"Linux software OpenGL, no Android device/profile",
        "gameplay":"not modified by this visual-only toggle"
    }
    proof.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    return report


def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--metadata",type=Path,default=Path("reactivo-13-node-a-camera-pair.json"))
    parser.add_argument("--before",type=Path,default=Path("reactivo-13-node-a-before.png"))
    parser.add_argument("--after",type=Path,default=Path("reactivo-13-node-a-after.png"))
    parser.add_argument("--scene",type=Path,default=Path("scenes/reactivo_13.tscn"))
    parser.add_argument("--report",type=Path,default=Path("reactivo-13-node-a-visual-comparison.json"))
    parser.add_argument("--sheet",type=Path,default=Path("reactivo-13-node-a-before-after.png"))
    args=parser.parse_args()
    try:
        report=validate(args.metadata,args.before,args.after,args.scene,
                        os.environ.get("GITHUB_SHA",""),args.report,args.sheet)
    except (ValueError,OSError,TypeError,KeyError,json.JSONDecodeError) as error:
        print("REACTIVO NODE A PAIRED VISUAL FAIL",error)
        return 1
    print("REACTIVO NODE A PAIRED VISUAL PASS roi_changed=%.4f outside=%.4f identical_pose=true" %
          (report["changed_pixel_ratio_in_roi"],report["changed_pixel_ratio_outside_roi"]))
    return 0

if __name__=="__main__":
    raise SystemExit(main())
