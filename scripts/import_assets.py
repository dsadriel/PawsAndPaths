"""Chroma-key, trim and import generated assets into Assets.xcassets.

Usage: python3 import_assets.py <brain_dir> <xcassets_dir>
"""
import glob
import json
import os
import sys

import numpy as np
from PIL import Image

BRAIN, XCASSETS = sys.argv[1], sys.argv[2]

SPRITES = {
    # name -> (group folder, max side px)
    "mascot_kitten_idle": ("Mascot", 512),
    "mascot_kitten_walk": ("Mascot", 512),
    "mascot_kitten_celebrate": ("Mascot", 512),
    "prop_yarn_ball": ("Props", 384),
    "prop_tree": ("Props", 384),
    "prop_rock": ("Props", 384),
    "prop_flower_bush": ("Props", 384),
    "icon_seed_coin": ("Icons", 256),
    "icon_star": ("Icons", 256),
}
BACKGROUNDS = {"bg_meadow_game": ("Backgrounds", 1536)}


def latest(name):
    files = sorted(glob.glob(os.path.join(BRAIN, f"{name}_*.jpg")))
    if not files:
        raise SystemExit(f"missing {name}")
    return files[-1]


def chroma_key(img):
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    h, w, _ = rgb.shape
    corners = np.concatenate([
        rgb[:8, :8].reshape(-1, 3), rgb[:8, -8:].reshape(-1, 3),
        rgb[-8:, :8].reshape(-1, 3), rgb[-8:, -8:].reshape(-1, 3),
    ])
    key = np.median(corners, axis=0)
    dist = np.linalg.norm(rgb - key, axis=2)
    lo, hi = 60.0, 140.0  # fully transparent below lo, opaque above hi
    alpha = np.clip((dist - lo) / (hi - lo), 0.0, 1.0)

    # Despill: pull key-color contamination out of semi-transparent edges.
    edge = (alpha > 0) & (alpha < 1)
    a = alpha[..., None]
    safe_a = np.where(a > 0.05, a, 1.0)
    unmixed = (rgb - key * (1 - a)) / safe_a
    rgb = np.where(edge[..., None], np.clip(unmixed, 0, 255), rgb)

    out = np.dstack([rgb, alpha * 255]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def trim(img, pad_ratio=0.04):
    bbox = img.getchannel("A").point(lambda v: 255 if v > 16 else 0).getbbox()
    img = img.crop(bbox)
    pad = int(max(img.size) * pad_ratio)
    canvas = Image.new("RGBA", (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    canvas.paste(img, (pad, pad))
    return canvas


def fit(img, max_side):
    scale = max_side / max(img.size)
    if scale < 1:
        img = img.resize((round(img.width * scale), round(img.height * scale)), Image.LANCZOS)
    return img


def write_imageset(group, name, img):
    group_dir = os.path.join(XCASSETS, group)
    os.makedirs(group_dir, exist_ok=True)
    with open(os.path.join(group_dir, "Contents.json"), "w") as f:
        json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)
    set_dir = os.path.join(group_dir, f"{name}.imageset")
    os.makedirs(set_dir, exist_ok=True)
    img.save(os.path.join(set_dir, f"{name}.png"), optimize=True)
    contents = {
        "images": [{"filename": f"{name}.png", "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    }
    with open(os.path.join(set_dir, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
    print(f"{group}/{name}: {img.size}")


for name, (group, size) in SPRITES.items():
    img = Image.open(latest(name))
    write_imageset(group, name, fit(trim(chroma_key(img)), size))

for name, (group, size) in BACKGROUNDS.items():
    img = Image.open(latest(name)).convert("RGB")
    write_imageset(group, name, fit(img, size))
