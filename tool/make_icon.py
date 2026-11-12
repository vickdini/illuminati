"""Draws the Illuminati logo/app icon.  Run:  python tool/make_icon.py

Outputs (assets/icon/):
  app_icon.png             1024px rounded-square icon (Windows, Linux, Android legacy, in-app)
  app_icon_macos.png       1024px with macOS-style inset and shadow
  app_icon_foreground.png  1024px transparent emblem for Android adaptive icons
"""
import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon')
SS = 4  # supersampling factor
GOLD = (233, 188, 82)
GOLD_LIGHT = (255, 222, 140)
CREAM = (255, 246, 222)
VIOLET_TOP = (84, 52, 150)
VIOLET_BOTTOM = (26, 14, 58)


def bezier(p0, p1, p2, n=64):
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0],
             (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1])
            for t in (i / n for i in range(n + 1))]


def background(size, radius):
    grad = Image.new('RGB', (1, 256))
    for y in range(256):
        t = y / 255
        grad.putpixel((0, y), tuple(int(a + (b - a) * t) for a, b in zip(VIOLET_TOP, VIOLET_BOTTOM)))
    bg = grad.resize((size, size), Image.BICUBIC).convert('RGBA')
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    bg.putalpha(mask)
    return bg


def emblem(size):
    """Book, light rays and star on a transparent canvas of `size` px."""
    S = size
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    cx, cy = 0.5 * S, 0.60 * S  # where the light comes from (book gutter)

    # --- soft glow ---
    glow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    r = 0.30 * S
    ImageDraw.Draw(glow).ellipse([cx - r, cy - r * 1.1, cx + r, cy + r * 0.7], fill=GOLD_LIGHT + (150,))
    glow = glow.filter(ImageFilter.GaussianBlur(0.09 * S))
    img = Image.alpha_composite(img, glow)

    # --- rays fanning upward ---
    rays = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(rays)
    n = 9
    for i in range(n):
        a = math.radians(205 + i * (130 / (n - 1)))
        long = (0.44 if i % 2 == 0 else 0.33) * S
        half = math.radians(3.2 if i % 2 == 0 else 2.2)
        p1 = (cx + long * math.cos(a - half), cy + long * math.sin(a - half))
        p2 = (cx + long * math.cos(a + half), cy + long * math.sin(a + half))
        d.polygon([(cx, cy), p1, p2], fill=GOLD_LIGHT + (255,))
    # fade rays out with distance
    fade = Image.new('L', (S, S), 0)
    fd = ImageDraw.Draw(fade)
    steps = 60
    for k in range(steps, 0, -1):
        rr = 0.46 * S * k / steps
        fd.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=int(235 * (1 - k / steps) ** 0.8))
    rays.putalpha(ImageChops.multiply(rays.getchannel('A'), fade))
    img = Image.alpha_composite(img, rays)

    # --- open book ---
    book = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(book)
    w = 0.33 * S  # half width
    top, bot = 0.555 * S, 0.745 * S
    sag = 0.035 * S

    def page(sign, inset, y_off, color):
        ox = cx + sign * (w - inset)
        outline = (
            bezier((cx, top + sag + y_off), (cx + sign * w * 0.45, top - sag * 1.2 + y_off), (ox, top + y_off))
            + [(ox, bot + y_off)]
            + bezier((ox, bot + y_off), (cx + sign * w * 0.45, bot - sag * 1.3 + y_off), (cx, bot + sag + y_off))
        )
        d.polygon(outline, fill=color)

    for s in (-1, 1):  # cover
        page(s, -0.022 * S, 0.028 * S, GOLD)
    for s in (-1, 1):  # page block edge
        page(s, -0.004 * S, 0.012 * S, (238, 214, 160, 255))
    for s in (-1, 1):  # top pages
        page(s, 0, 0, CREAM + (255,))

    # text lines
    for s in (-1, 1):
        for k in range(5):
            y = top + 0.040 * S + k * 0.026 * S
            x0, x1 = cx + s * 0.05 * S, cx + s * (w - 0.05 * S)
            pts = bezier((x0, y + sag * 0.6), (cx + s * w * 0.45, y - sag * 1.1), (x1, y), 24)
            d.line(pts, fill=(196, 160, 96, 200), width=max(1, int(0.008 * S)), joint='curve')
    # gutter
    d.line([(cx, top + sag), (cx, bot + sag)], fill=(176, 132, 60, 255), width=max(1, int(0.010 * S)))

    shadow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    shadow.putalpha(book.getchannel('A').point(lambda v: v * 0.45))
    shadow = shadow.transform(shadow.size, Image.AFFINE, (1, 0, 0, 0, 1, -0.012 * S)).filter(
        ImageFilter.GaussianBlur(0.015 * S))
    img = Image.alpha_composite(img, shadow)
    img = Image.alpha_composite(img, book)

    # --- guiding star ---
    star = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    sx, sy, R, rr = cx, 0.235 * S, 0.075 * S, 0.016 * S
    pts = []
    for i in range(8):
        a = math.radians(-90 + i * 45)
        rad = R if i % 2 == 0 else rr
        pts.append((sx + rad * math.cos(a), sy + rad * math.sin(a)))
    sg = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(sg).ellipse([sx - R * 0.6, sy - R * 0.6, sx + R * 0.6, sy + R * 0.6], fill=(255, 240, 190, 200))
    star = Image.alpha_composite(star, sg.filter(ImageFilter.GaussianBlur(0.03 * S)))
    ImageDraw.Draw(star).polygon(pts, fill=(255, 248, 225, 255))
    img = Image.alpha_composite(img, star)
    return img


def render(size, *, with_bg=True, emblem_scale=1.0, inset=0.0, shadow=False):
    S = size * SS
    canvas = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    body = int(S * (1 - 2 * inset))
    off = (S - body) // 2
    if with_bg:
        if shadow:
            sh = Image.new('RGBA', (S, S), (0, 0, 0, 0))
            ImageDraw.Draw(sh).rounded_rectangle(
                [off, off + int(0.01 * S), off + body, off + body + int(0.01 * S)],
                radius=int(body * 0.225), fill=(0, 0, 0, 110))
            canvas = Image.alpha_composite(canvas, sh.filter(ImageFilter.GaussianBlur(0.012 * S)))
        layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        layer.paste(background(body, int(body * 0.225)), (off, off))
        canvas = Image.alpha_composite(canvas, layer)
    e_size = int(body * emblem_scale)
    e = emblem(e_size)
    layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    layer.paste(e, ((S - e_size) // 2, (S - e_size) // 2 - int(0.02 * body)), e)
    canvas = Image.alpha_composite(canvas, layer)
    return canvas.resize((size, size), Image.LANCZOS)


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    render(1024).save(os.path.join(OUT, 'app_icon.png'))
    # macOS Big Sur+ grid: ~824px body inside 1024px, with a soft shadow.
    render(1024, inset=0.098, shadow=True).save(os.path.join(OUT, 'app_icon_macos.png'))
    # Android adaptive foreground: keep the emblem inside the 66% safe zone.
    render(1024, with_bg=False, emblem_scale=0.68).save(os.path.join(OUT, 'app_icon_foreground.png'))
    print('icons written to', os.path.abspath(OUT))
