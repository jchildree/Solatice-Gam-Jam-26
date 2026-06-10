"""Convert flat-color animation sheets into pixel-art sheets using character.png palette."""
import os
from collections import Counter
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANIM_DIR = os.path.join(ROOT, "assets", "sprites", "animations")
OUT_DIR = os.path.join(ANIM_DIR, "processed")
CHAR_PNG = os.path.join(ROOT, "assets", "sprites", "character.png")

FRAME = 128
OUT_FRAME = 72
HEAD_H = 15
CAP_ROWS = 7
BRIM_ROWS = 3
BRIM_LEN = 6
SHOE_BAND = 0.09
FAR_MUL = 0.72

# Source sheets use exactly these five flat colors to mark body parts.
SRC_ROLES = {
    (201, 212, 253): "ht",
    (94, 113, 142): "arm_near",
    (27, 36, 71): "arm_far",
    (138, 161, 246): "leg_near",
    (44, 52, 56): "leg_far",
}

SHEETS = ["Walking", "Running", "Jumping", "Falling", "Landing", "Roll"]

EXPECTED = {
    "Idle.png": (72, 72),
    "Walking.png": (864, 72),
    "Running.png": (864, 72),
    "Jumping.png": (720, 72),
    "Falling.png": (792, 72),
    "Landing.png": (432, 72),
    "Roll.png": (648, 72),
}


def sample_palette():
    im = Image.open(CHAR_PNG).convert("RGBA")
    w, h = im.size
    px = im.load()
    xs, ys = [], []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 0:
                xs.append(x)
                ys.append(y)
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    bh = y1 - y0 + 1
    # vertical zones of the reference sprite; exclude black outline except for feet
    zones = {
        "cap": (0.00, 0.12, False),
        "skin": (0.13, 0.22, False),
        "shirt": (0.30, 0.50, False),
        "jeans": (0.60, 0.85, False),
        "shoes": (0.92, 1.00, True),
    }
    pal = {}
    for name, (a, b, allow_black) in zones.items():
        c = Counter()
        for y in range(y0 + int(a * bh), y0 + int(b * bh)):
            for x in range(x0, x1 + 1):
                p = px[x, y]
                if p[3] > 200 and (allow_black or p[:3] != (0, 0, 0)):
                    c[p[:3]] += 1
        pal[name] = c.most_common(1)[0][0]
    return pal


def darken(color, mul):
    return tuple(int(c * mul) for c in color)


def classify(rgb):
    best_role, best_d = None, None
    for src, role in SRC_ROLES.items():
        d = sum((a - b) ** 2 for a, b in zip(src, rgb))
        if best_d is None or d < best_d:
            best_role, best_d = role, d
    return best_role


def analyze(px):
    ys, ht_xs, ht_ys = [], [], []
    for y in range(FRAME):
        for x in range(FRAME):
            p = px[x, y]
            if p[3] <= 200:
                continue
            ys.append(y)
            if classify(p[:3]) == "ht":
                ht_xs.append(x)
                ht_ys.append(y)
    if not ys or not ht_xs:
        return None
    ht_y0 = min(ht_ys)
    top_xs = [x for x, y in zip(ht_xs, ht_ys) if y < ht_y0 + 8]
    return {
        "y1": max(ys),
        "h": max(ys) - min(ys) + 1,
        "ht_y0": ht_y0,
        "ht_h": max(ht_ys) - ht_y0 + 1,
        "ht_w": max(ht_xs) - min(ht_xs) + 1,
        "topx0": min(top_xs),
        "topx1": max(top_xs),
    }


def draw_brim(px, info, pal):
    hx0 = info["topx0"] - 2
    hx1 = info["topx1"] + 3
    for y in range(info["ht_y0"] + CAP_ROWS - BRIM_ROWS, info["ht_y0"] + CAP_ROWS):
        edge = None
        for x in range(max(hx0, 0), min(hx1 + 1, FRAME)):
            if px[x, y][3] > 0:
                edge = x
        if edge is None:
            continue
        for x in range(edge + 1, min(edge + 1 + BRIM_LEN, FRAME)):
            if px[x, y][3] > 0:
                break
            px[x, y] = pal["cap"] + (255,)


def recolor_frame(frame, pal, allow_cap):
    px = frame.load()
    info = analyze(px)
    if info is None:
        return frame
    skin_far = darken(pal["skin"], FAR_MUL)
    jeans_far = darken(pal["jeans"], FAR_MUL)
    topw = info["topx1"] - info["topx0"] + 1
    # Head crown is ~11px wide when upright; tumble frames measure 23-41.
    upright = (
        allow_cap
        and topw <= 18
        and info["ht_h"] >= 20
        and info["ht_h"] >= 0.9 * info["ht_w"]
    )
    shoe_y = info["y1"] - round(SHOE_BAND * info["h"])
    head_y1 = info["ht_y0"] + HEAD_H
    cap_y1 = info["ht_y0"] + CAP_ROWS
    hx0 = info["topx0"] - 2
    hx1 = info["topx1"] + 3
    for y in range(FRAME):
        for x in range(FRAME):
            p = px[x, y]
            if p[3] == 0:
                continue
            role = classify(p[:3])
            if role == "arm_near":
                color = pal["skin"]
            elif role == "arm_far":
                color = skin_far
            elif role in ("leg_near", "leg_far"):
                if y >= shoe_y:
                    color = pal["shoes"]
                elif role == "leg_near":
                    color = pal["jeans"]
                else:
                    color = jeans_far
            elif upright and y < head_y1 and hx0 <= x <= hx1:
                color = pal["cap"] if y < cap_y1 else pal["skin"]
            else:
                color = pal["shirt"]
            px[x, y] = color + (p[3],)
    if upright:
        draw_brim(px, info, pal)
    return frame


def process_sheet(name, pal):
    sheet = Image.open(os.path.join(ANIM_DIR, name + ".png")).convert("RGBA")
    w, h = sheet.size
    assert h == FRAME and w % FRAME == 0, "%s unexpected size %s" % (name, (w, h))
    n = w // FRAME
    out = Image.new("RGBA", (n * OUT_FRAME, OUT_FRAME), (0, 0, 0, 0))
    small_frames = []
    allow_cap = name != "Roll"
    for i in range(n):
        frame = sheet.crop((i * FRAME, 0, (i + 1) * FRAME, FRAME))
        frame = recolor_frame(frame, pal, allow_cap)
        small = frame.resize((OUT_FRAME, OUT_FRAME), Image.NEAREST)
        small_frames.append(small)
        out.paste(small, (i * OUT_FRAME, 0))
    out.save(os.path.join(OUT_DIR, name + ".png"))
    return small_frames


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    pal = sample_palette()
    print("palette:", pal)
    for name in SHEETS:
        frames = process_sheet(name, pal)
        if name == "Walking":
            frames[0].save(os.path.join(OUT_DIR, "Idle.png"))
    for fname, size in EXPECTED.items():
        im = Image.open(os.path.join(OUT_DIR, fname))
        assert im.size == size, "%s is %s, expected %s" % (fname, im.size, size)
        print("ok:", fname, im.size)


if __name__ == "__main__":
    main()
