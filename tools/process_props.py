"""
AI Prop Processor — Removes background + downscales to exact game size.

Usage:
    python tools/process_props.py

Workflow:
    1. Generate props with AI (any resolution)
    2. Save PNGs in "AI Generate/" folder at project root
    3. Name each file to match a key below (e.g., "front_door.png", "couch.png")
    4. Run this script — outputs go directly to game/rooms/*/props/*/placeholder.png

The script:
    - Removes fake checkerboard transparency backgrounds (grey/white pattern)
    - Downscales to exact target size using nearest-neighbor (crispy pixels)
    - Saves as transparent PNG
"""

from PIL import Image
import numpy as np
import os
import sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INPUT_DIR = os.path.join(BASE, "AI Generate")

# prop_name -> (target_width, target_height, output_path_relative_to_BASE)
PROPS = {
    "front_door":           (40, 60, "game/rooms/entrance_hall/props/front_door/placeholder.png"),
    "mirror":               (20, 30, "game/rooms/entrance_hall/props/mirror/placeholder.png"),
    "wall_clock":           (16, 20, "game/rooms/entrance_hall/props/wall_clock/placeholder.png"),
    "coat_rack":            (16, 40, "game/rooms/entrance_hall/props/coat_rack/placeholder.png"),
    "fireplace":            (70, 56, "game/rooms/living_room/props/fireplace/placeholder.png"),
    "fireplace_compartment":(15, 10, "game/rooms/living_room/props/fireplace_compartment/placeholder.png"),
    "couch":                (64, 32, "game/rooms/living_room/props/couch/placeholder.png"),
    "birthday_cake":        (32, 32, "game/rooms/living_room/props/birthday_cake/placeholder.png"),
    "painting":             (36, 28, "game/rooms/living_room/props/painting/placeholder.png"),
    "small_drawer":         (48, 34, "game/rooms/living_room/props/small_drawer/placeholder.png"),
    "bookshelf":            (56, 80, "game/rooms/living_room/props/bookshelf/placeholder.png"),
    "desk":                 (64, 44, "game/rooms/study/props/desk/placeholder.png"),
    "filing_cabinet":       (36, 64, "game/rooms/study/props/filing_cabinet/placeholder.png"),
    "safe":                 (34, 34, "game/rooms/study/props/safe/placeholder.png"),
    "barred_window":        (44, 44, "game/rooms/study/props/barred_window/placeholder.png"),
    "framed_certificate":   (28, 22, "game/rooms/study/props/framed_certificate/placeholder.png"),
}


def remove_checkerboard_bg(img):
    """
    Remove fake checkerboard transparency pattern (grey ~204-214 / white ~245-255).
    AI generators bake this pattern instead of using real alpha.
    Also removes any solid near-white or near-grey background via flood fill.
    """
    img = img.convert("RGBA")
    arr = np.array(img, dtype=np.float32)
    h, w = arr.shape[:2]

    # Step 1: Identify "background-like" pixels
    # AI generators produce fake checkerboard patterns in two variants:
    #   Light: white ~(245-255) + grey ~(200-215)
    #   Dark:  grey ~(100-115) + lighter grey ~(145-165)
    # Both have very low saturation (R ≈ G ≈ B)
    r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]

    # Low saturation: max(RGB) - min(RGB) < threshold
    rgb_stack = np.stack([r, g, b], axis=-1)
    sat = np.max(rgb_stack, axis=-1) - np.min(rgb_stack, axis=-1)

    # Background = low saturation (grey/white, any brightness)
    # We detect based on corner colors to adapt to light or dark checkerboard
    corner_pixels = [arr[0,0,:3], arr[0,w-1,:3], arr[h-1,0,:3], arr[h-1,w-1,:3]]
    corner_brightness = [np.mean(cp) for cp in corner_pixels]
    avg_corner_brightness = np.mean(corner_brightness)

    brightness = (r + g + b) / 3.0

    if avg_corner_brightness > 190:
        # Light checkerboard: remove grey (>180) and white (>235)
        is_bg_color = (sat < 25) & (brightness > 180)
    else:
        # Dark checkerboard: remove low-sat pixels near corner brightness
        # Allow wide range around the detected background brightness
        low = avg_corner_brightness - 40
        high = avg_corner_brightness + 70
        is_bg_color = (sat < 25) & (brightness > low) & (brightness < high)

    # Step 2: Flood fill from edges — only remove connected bg pixels
    # This prevents removing light-colored parts of the actual sprite
    from scipy.ndimage import label

    # Create mask of bg-colored pixels
    bg_mask = is_bg_color.astype(np.uint8)

    # Mark edge-touching pixels
    edge_mask = np.zeros_like(bg_mask)
    edge_mask[0, :] = 1
    edge_mask[-1, :] = 1
    edge_mask[:, 0] = 1
    edge_mask[:, -1] = 1

    # Label connected components in bg_mask
    labeled, num_features = label(bg_mask)

    # Find which labels touch the edge
    edge_labels = set(np.unique(labeled[edge_mask == 1]))
    edge_labels.discard(0)  # 0 = not bg

    # Build final mask: only bg pixels connected to edges
    remove_mask = np.isin(labeled, list(edge_labels))

    # Step 3: Apply transparency
    arr[remove_mask, 3] = 0

    result = Image.fromarray(arr.astype(np.uint8))
    removed_pct = np.sum(remove_mask) / (w * h) * 100
    return result, removed_pct


def process_prop(name, input_path):
    """Remove background and resize a single prop."""
    if name not in PROPS:
        print(f"[SKIP] Unknown prop name: {name}")
        return False

    target_w, target_h, output_rel = PROPS[name]
    output_path = os.path.join(BASE, output_rel)

    try:
        img = Image.open(input_path).convert("RGBA")
    except Exception as e:
        print(f"[ERR]  {name}: Cannot open {input_path} — {e}")
        return False

    print(f"[...] {name}: {img.size[0]}x{img.size[1]} -> {target_w}x{target_h}")

    # Check if already has real transparency
    alpha_min = img.split()[3].getextrema()[0]
    if alpha_min == 255:
        img, pct = remove_checkerboard_bg(img)
        print(f"       Background removed ({pct:.1f}% of pixels)")
    else:
        print(f"       Already has transparency, skipping bg removal")

    # Crop to content (trim transparent edges)
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        print(f"       Cropped to content: {img.size[0]}x{img.size[1]}")

    # Resize to target with nearest-neighbor (crispy pixels)
    img = img.resize((target_w, target_h), Image.NEAREST)

    # Save
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    print(f"[OK]  {name}: saved to {output_rel}")
    return True


def main():
    if not os.path.isdir(INPUT_DIR):
        os.makedirs(INPUT_DIR)
        print(f"Created '{INPUT_DIR}/'")
        print(f"Place your AI-generated PNGs there and run again.")
        print(f"\nExpected filenames:")
        for name in sorted(PROPS):
            w, h, _ = PROPS[name]
            print(f"  {name}.png  (will be resized to {w}x{h})")
        return

    # Find all PNGs in input directory
    found = {}
    for f in os.listdir(INPUT_DIR):
        if f.lower().endswith(".png"):
            name = os.path.splitext(f)[0].lower().replace(" ", "_").replace("-", "_")
            found[name] = os.path.join(INPUT_DIR, f)

    if not found:
        print(f"No PNGs found in '{INPUT_DIR}/'")
        print(f"\nExpected filenames:")
        for name in sorted(PROPS):
            w, h, _ = PROPS[name]
            print(f"  {name}.png  (will be resized to {w}x{h})")
        return

    print(f"Found {len(found)} PNGs in '{INPUT_DIR}/'")
    print(f"{'='*50}")

    ok = 0
    skip = 0
    for name, path in sorted(found.items()):
        if process_prop(name, path):
            ok += 1
        else:
            skip += 1

    # Report missing props
    missing = set(PROPS.keys()) - set(found.keys())
    print(f"\n{'='*50}")
    print(f"Processed: {ok}  |  Skipped: {skip}  |  Missing: {len(missing)}")
    if missing:
        print(f"\nStill need:")
        for name in sorted(missing):
            w, h, _ = PROPS[name]
            print(f"  {name}.png  ({w}x{h})")


if __name__ == "__main__":
    main()
