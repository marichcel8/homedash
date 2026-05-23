#!/usr/bin/env python3
"""
Generiert alle PNG-Assets für HomeDash:
- Layered Icons (Front / Middle / Back) für App Icon - Small (400x240) + Large (1280x768)
- Top Shelf Image (1920x720) + Wide (2320x720)
- Launch Image (1920x1080)

Design: Apple-Home-Style. Tiefblauer Verlauf hinten, weicher Lichthof mittig,
Haus-Silhouette mit kleinem Akzent-Quadrat (Geräte-Tile) vorne.
"""
import os
import math
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRAND = os.path.join(ROOT, "HomeDash", "Assets.xcassets", "Brand Assets.brandassets")
LAUNCH = os.path.join(ROOT, "HomeDash", "Assets.xcassets", "LaunchImage.launchimage")

# Farb-Palette (Apple System Colors dark, Akzent: HomeDash Coral)
NIGHT_TOP = (18, 18, 22, 255)
NIGHT_BOT = (5, 5, 8, 255)
ACCENT = (10, 132, 255, 255)        # systemBlue dark
ACCENT_2 = (94, 92, 230, 255)       # systemIndigo dark
WARM = (255, 214, 10, 255)          # systemYellow dark – warm light glow
WHITE = (255, 255, 255, 255)


def vertical_gradient(size, top, bottom):
    """Erzeuge einen vertikalen Gradient als RGBA-Image."""
    w, h = size
    img = Image.new("RGBA", size)
    for y in range(h):
        t = y / max(h - 1, 1)
        r = int(top[0] * (1 - t) + bottom[0] * t)
        g = int(top[1] * (1 - t) + bottom[1] * t)
        b = int(top[2] * (1 - t) + bottom[2] * t)
        a = int(top[3] * (1 - t) + bottom[3] * t)
        for x in range(w):
            img.putpixel((x, y), (r, g, b, a))
    return img


def radial_glow(size, color, center=None, radius_factor=0.7, intensity=1.0):
    """Erzeuge einen weichen radialen Hotspot."""
    w, h = size
    if center is None:
        center = (w // 2, h // 2)
    cx, cy = center
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    max_r = max(w, h) * radius_factor
    px = img.load()
    for y in range(h):
        for x in range(w):
            d = math.hypot(x - cx, y - cy)
            t = max(0.0, 1.0 - d / max_r)
            t = t * t * intensity
            a = int(color[3] * t)
            if a > 0:
                px[x, y] = (color[0], color[1], color[2], a)
    return img


def rounded_rect(draw, xy, radius, fill):
    """Pillow ≥9 hat round_rectangle, aber wir nutzen den kompatiblen Weg."""
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill)


def house_silhouette(size, color=(255, 255, 255, 240), scale=0.55):
    """Stilisierte Haus-Form: Dach + Körper mit Tile/Lampe als Akzent."""
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = w // 2, h // 2
    base = int(min(w, h) * scale)

    # Haus: zentriertes Quadrat (Körper) + Dreieck (Dach)
    body_w = int(base * 1.0)
    body_h = int(base * 0.62)
    body_x0 = cx - body_w // 2
    body_y1 = cy + int(base * 0.32)
    body_y0 = body_y1 - body_h
    radius = int(body_h * 0.18)
    rounded_rect(d, (body_x0, body_y0, body_x0 + body_w, body_y1), radius, color)

    # Dach: Dreieck über dem Körper, weicher Apex
    roof_apex_y = body_y0 - int(base * 0.38)
    roof_overhang = int(body_w * 0.18)
    roof_points = [
        (body_x0 - roof_overhang, body_y0 + int(base * 0.04)),
        (cx, roof_apex_y),
        (body_x0 + body_w + roof_overhang, body_y0 + int(base * 0.04)),
    ]
    d.polygon(roof_points, fill=color)

    # Akzent-„Tile" (kleines abgerundetes Quadrat im Haus, repräsentiert Smart-Home Gerät)
    tile = int(base * 0.26)
    tile_x = cx - tile // 2
    tile_y = cy - tile // 2 + int(base * 0.04)
    rounded_rect(d, (tile_x, tile_y, tile_x + tile, tile_y + tile),
                 int(tile * 0.28), WARM)
    return img


def make_back(size):
    """Solider, opaker Verlauf – Pflicht: alle Pixel Alpha=255."""
    img = vertical_gradient(size, NIGHT_TOP, NIGHT_BOT)
    glow = radial_glow(size, (94, 92, 230, 120),
                       center=(int(size[0] * 0.28), int(size[1] * 0.32)),
                       radius_factor=0.55, intensity=1.0)
    img = Image.alpha_composite(img, glow)
    # Erzwinge volle Opazität durch RGB-Roundtrip.
    return img.convert("RGB").convert("RGBA")


def make_middle(size):
    """Weicher Glanz / Halo – transparent, sorgt für Tiefen-Parallax."""
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    # warmer Hotspot in der Bildmitte
    halo = radial_glow(size, (255, 214, 10, 80),
                       center=(int(size[0] * 0.5), int(size[1] * 0.55)),
                       radius_factor=0.45, intensity=1.0)
    # zweiter cooler Akzent rechts
    halo2 = radial_glow(size, (10, 132, 255, 70),
                        center=(int(size[0] * 0.78), int(size[1] * 0.4)),
                        radius_factor=0.4, intensity=1.0)
    img = Image.alpha_composite(img, halo)
    img = Image.alpha_composite(img, halo2)
    img = img.filter(ImageFilter.GaussianBlur(radius=max(size) // 80))
    return img


def make_front(size):
    """Haus-Silhouette – transparenter Hintergrund."""
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    house = house_silhouette(size, color=(255, 255, 255, 245), scale=0.50)
    img = Image.alpha_composite(img, house)
    return img


def write_icon_stack(stack_dir, size):
    back = make_back(size)
    middle = make_middle(size)
    front = make_front(size)
    back.save(os.path.join(stack_dir, "Back.imagestacklayer", "Content.imageset", "Back.png"),
              format="PNG", optimize=True)
    middle.save(os.path.join(stack_dir, "Middle.imagestacklayer", "Content.imageset", "Middle.png"),
                format="PNG", optimize=True)
    front.save(os.path.join(stack_dir, "Front.imagestacklayer", "Content.imageset", "Front.png"),
               format="PNG", optimize=True)
    print(f"  → wrote layers {size} into {os.path.basename(stack_dir)}")


def make_top_shelf(size):
    """Top-Shelf-Banner. Muss vollständig opak sein (Apple-Requirement)."""
    img = vertical_gradient(size, NIGHT_TOP, NIGHT_BOT)
    halo = radial_glow(size, (10, 132, 255, 130),
                       center=(int(size[0] * 0.78), int(size[1] * 0.5)),
                       radius_factor=0.55, intensity=1.0)
    img = Image.alpha_composite(img, halo)
    shifted = Image.new("RGBA", size, (0, 0, 0, 0))
    src = house_silhouette(size, color=(255, 255, 255, 235), scale=0.42)
    offset_x = -int(size[0] * 0.22)
    shifted.paste(src, (offset_x, 0), src)
    img = Image.alpha_composite(img, shifted)
    # Konvertiere nach RGB (drop Alpha komplett), dann zurück nach RGBA
    # mit Alpha=255 – damit ist jedes Pixel garantiert opak.
    return img.convert("RGB").convert("RGBA")


def make_launch(size):
    img = vertical_gradient(size, NIGHT_TOP, NIGHT_BOT)
    halo = radial_glow(size, (10, 132, 255, 90),
                       center=(int(size[0] * 0.5), int(size[1] * 0.6)),
                       radius_factor=0.5, intensity=1.0)
    img = Image.alpha_composite(img, halo)
    house = house_silhouette(size, color=(255, 255, 255, 230), scale=0.32)
    img = Image.alpha_composite(img, house)
    return img


def main():
    # App Icon - Small: 400×240
    small = os.path.join(BRAND, "App Icon - Small.imagestack")
    write_icon_stack(small, (400, 240))

    # App Icon - Large: 1280×768
    large = os.path.join(BRAND, "App Icon - Large.imagestack")
    write_icon_stack(large, (1280, 768))

    # Top Shelf 1920×720 + @2x 3840×1440
    ts_dir = os.path.join(BRAND, "Top Shelf Image.imageset")
    make_top_shelf((1920, 720)).save(os.path.join(ts_dir, "TopShelf.png"),
                                     format="PNG", optimize=True)
    make_top_shelf((3840, 1440)).save(os.path.join(ts_dir, "TopShelf@2x.png"),
                                      format="PNG", optimize=True)
    print("  → top shelf written")

    # Top Shelf Wide 2320×720 + @2x 4640×1440
    tsw_dir = os.path.join(BRAND, "Top Shelf Image Wide.imageset")
    make_top_shelf((2320, 720)).save(os.path.join(tsw_dir, "TopShelfWide.png"),
                                     format="PNG", optimize=True)
    make_top_shelf((4640, 1440)).save(os.path.join(tsw_dir, "TopShelfWide@2x.png"),
                                      format="PNG", optimize=True)
    print("  → top shelf wide written")

    # Launch Image 1920×1080
    make_launch((1920, 1080)).save(os.path.join(LAUNCH, "LaunchImage.png"),
                                   format="PNG", optimize=True)
    print("  → launch image written")

    print("Alle Assets erzeugt.")


if __name__ == "__main__":
    main()
