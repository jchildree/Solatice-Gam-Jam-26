"""Convert silhouette animation sheets into pixel-art sheets using character.png palette."""
import os
from collections import Counter
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANIM_DIR = os.path.join(ROOT, "assets", "sprites", "animations")
OUT_DIR = os.path.join(ANIM_DIR, "processed")
CHAR_PNG = os.path.join(ROOT, "assets", "sprites", "character.png")

FRAME = 128
OUT_FRAME = 48

SHEETS = ["Walking", "Running", "Jumping", "Falling", "Landing", "Roll"]

EXPECTED = {
    "Idle.png": (48, 48),
    "Walking.png": (576, 48),
    "Running.png": (576, 48),
    "Jumping.png": (480, 48),
    "Falling.png": (528, 48),
    "Landing.png": (288, 48),
    "Roll.png": (432, 48),
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


def luminance(p):
    return 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]


def shade(color, lum, lum_min, lum_max):
    # map source luminance to 0.6-1.0 so near/far limbs still read
    span = max(lum_max - lum_min, 1.0)
    t = 0.6 + 0.4 * (lum - lum_min) / span
    return tuple(min(255, int(round(c * t))) for c in color)


def frame_stats(px, fw, fh):
    xs, ys, lums = [], [], []
    for y in range(fh):
        for x in range(fw):
            p = px[x, y]
            if p[3] > 0:
                xs.append(x)
                ys.append(y)
                lums.append(luminance(p))
    if not xs:
        return None
    lums.sort()
    return (min(ys), max(ys), lums[0], lums[-1], lums[len(lums) // 2])


def recolor_upright(frame, pal):
    px = frame.load()
    stats = frame_stats(px, FRAME, FRAME)
    if stats is None:
        return frame
    y0, y1, lmin, lmax, _ = stats
    bh = max(y1 - y0, 1)
    for y in range(FRAME):
        for x in range(FRAME):
            p = px[x, y]
            if p[3] == 0:
                continue
            rel = (y - y0) / bh
            if rel < 0.10:
                color = pal["cap"]
            elif rel < 0.20:
                color = pal["skin"]
            elif rel < 0.55:
                color = pal["shirt"]
            elif rel < 0.90:
                color = pal["jeans"]
            else:
                color = pal["shoes"]
            px[x, y] = shade(color, luminance(p), lmin, lmax) + (p[3],)
    return frame


def recolor_roll(frame, pal):
    px = frame.load()
    stats = frame_stats(px, FRAME, FRAME)
    if stats is None:
        return frame
    _, _, lmin, lmax, lmed = stats
    for y in range(FRAME):
        for x in range(FRAME):
            p = px[x, y]
            if p[3] == 0:
                continue
            lum = luminance(p)
            color = pal["shirt"] if lum > lmed else pal["jeans"]
            px[x, y] = shade(color, lum, lmin, lmax) + (p[3],)
    return frame


def process_sheet(name, pal):
    sheet = Image.open(os.path.join(ANIM_DIR, name + ".png")).convert("RGBA")
    w, h = sheet.size
    assert h == FRAME and w % FRAME == 0, "%s unexpected size %s" % (name, (w, h))
    n = w // FRAME
    out = Image.new("RGBA", (n * OUT_FRAME, OUT_FRAME), (0, 0, 0, 0))
    small_frames = []
    for i in range(n):
        frame = sheet.crop((i * FRAME, 0, (i + 1) * FRAME, FRAME))
        if name == "Roll":
            frame = recolor_roll(frame, pal)
        else:
            frame = recolor_upright(frame, pal)
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
