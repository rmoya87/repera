#!/usr/bin/env python3
"""Genera el mapa ilustrativo de outdoor (Casa de Campo, Madrid).

Compone teselas de OpenStreetMap, las pasa a tema oscuro, dibuja un recorrido
de ejemplo coloreado por ritmo y guarda assets/map-madrid-casa-de-campo-{640,1280}.webp.
Fuente: © OpenStreetMap contributors (atribucion incluida en la imagen).
"""
import io
import math
import urllib.request

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps

Z = 15
W, H = 1280, 720
CENTER = (40.4175, -3.7570)  # Casa de Campo, Madrid
UA = "ReperaWebStaticMap/1.0 (https://repera.app; hola@repera.app)"

# Recorrido de ejemplo (~8,4 km) por la Casa de Campo
ROUTE = [
    (40.4080, -3.7620), (40.4130, -3.7680), (40.4200, -3.7700),
    (40.4260, -3.7640), (40.4275, -3.7560), (40.4240, -3.7470),
    (40.4170, -3.7445), (40.4100, -3.7475), (40.4062, -3.7545),
]

PACE_STOPS = [
    (0.00, (48, 209, 88)),    # #30d158 suave
    (0.35, (160, 229, 72)),   # #a0e548 firme
    (0.65, (255, 214, 10)),   # #ffd60a medio
    (1.00, (255, 69, 58)),    # #ff453a rapido
]


def deg2num(lat, lon, z):
    lat_r = math.radians(lat)
    n = 2 ** z
    x = (lon + 180.0) / 360.0 * n
    y = (1.0 - math.log(math.tan(lat_r) + 1.0 / math.cos(lat_r)) / math.pi) / 2.0 * n
    return x * 256.0, y * 256.0


def chaikin(points, iterations=2):
    pts = points[:]
    for _ in range(iterations):
        out = []
        for i, p in enumerate(pts):
            q = pts[(i + 1) % len(pts)]
            out.append((0.75 * p[0] + 0.25 * q[0], 0.75 * p[1] + 0.25 * q[1]))
            out.append((0.25 * p[0] + 0.75 * q[0], 0.25 * p[1] + 0.75 * q[1]))
        pts = out
    return pts


def pace_color(t):
    t = max(0.0, min(1.0, t))
    for (t0, c0), (t1, c1) in zip(PACE_STOPS, PACE_STOPS[1:]):
        if t0 <= t <= t1:
            f = (t - t0) / (t1 - t0) if t1 > t0 else 0.0
            return tuple(round(a + (b - a) * f) for a, b in zip(c0, c1))
    return PACE_STOPS[-1][1]


def main():
    cx, cy = deg2num(*CENTER, Z)
    x0, y0 = cx - W / 2, cy - H / 2
    tx0, ty0 = int(x0 // 256), int(y0 // 256)
    tx1, ty1 = int((x0 + W) // 256), int((y0 + H) // 256)

    base = Image.new("RGB", ((tx1 - tx0 + 1) * 256, (ty1 - ty0 + 1) * 256))
    for tx in range(tx0, tx1 + 1):
        for ty in range(ty0, ty1 + 1):
            url = f"https://tile.openstreetmap.org/{Z}/{tx}/{ty}.png"
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            tile = Image.open(io.BytesIO(urllib.request.urlopen(req, timeout=30).read())).convert("RGB")
            base.paste(tile, ((tx - tx0) * 256, (ty - ty0) * 256))
    img = base.crop((int(x0 - tx0 * 256), int(y0 - ty0 * 256),
                     int(x0 - tx0 * 256) + W, int(y0 - ty0 * 256) + H))

    # tema oscuro a juego con la web
    gray = ImageOps.invert(ImageOps.grayscale(img))
    gray = ImageEnhance.Contrast(gray).enhance(1.15)
    gray = ImageEnhance.Brightness(gray).enhance(0.85)
    img = Image.merge("RGB", (
        gray.point(lambda v: int(v * 0.82)),
        gray.point(lambda v: int(v * 0.95)),
        gray.point(lambda v: int(v * 0.86)),
    ))

    def to_px(lat, lon):
        px, py = deg2num(lat, lon, Z)
        return (px - x0, py - y0)

    raw = [to_px(*c) for c in ROUTE]
    pts = chaikin(raw, 2) + [raw[0]]

    # longitudes acumuladas para el degradado por ritmo
    seg_len = [math.dist(a, b) for a, b in zip(pts, pts[1:])]
    total = sum(seg_len)

    def draw_route(draw, width):
        acc = 0.0
        for a, b, ln in zip(pts, pts[1:], seg_len):
            color = pace_color((acc + ln / 2) / total)
            draw.line([a, b], fill=color, width=width)
            r = width / 2
            draw.ellipse([a[0] - r, a[1] - r, a[0] + r, a[1] + r], fill=color)
            acc += ln

    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_route(ImageDraw.Draw(glow), 16)
    glow = glow.filter(ImageFilter.GaussianBlur(10))
    img = Image.alpha_composite(img.convert("RGBA"), glow)

    line = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_route(ImageDraw.Draw(line), 7)
    img = Image.alpha_composite(img, line)

    d = ImageDraw.Draw(img)
    for (lat, lon), color in ((ROUTE[0], (48, 209, 88)), (ROUTE[0], (255, 69, 58))):
        pass
    sx, sy = to_px(*ROUTE[0])
    for px, py, color in ((sx, sy, (48, 209, 88)), (sx - 4, sy - 30, (255, 69, 58))):
        d.ellipse([px - 20, py - 20, px + 20, py + 20], outline=color + (90,), width=3)
        d.ellipse([px - 11, py - 11, px + 11, py + 11], fill=color + (255,))

    # atribucion
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 17)
    attr = "(c) OpenStreetMap contributors"
    tw = d.textlength(attr, font=font)
    ax, ay = W - tw - 26, H - 34
    d.rounded_rectangle([ax - 10, ay - 6, ax + tw + 10, ay + 26], radius=6, fill=(0, 0, 0, 150))
    d.text((ax, ay), attr, font=font, fill=(255, 255, 255, 200))

    img.convert("RGB").save("assets/map-madrid-casa-de-campo-1280.webp", quality=80, method=6)
    img.convert("RGB").resize((640, 360), Image.LANCZOS).save(
        "assets/map-madrid-casa-de-campo-640.webp", quality=80, method=6)
    print("mapas guardados")


if __name__ == "__main__":
    main()
