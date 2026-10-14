#!/usr/bin/env python3
"""Rasterize original code/vector candy blocks and bloom using design tokens.

Development-only dependency: Pillow. Outputs Android launcher resources and a
512 px store icon; no Flutter icons, stock images, emoji or external samples.
"""
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
PALETTE = json.loads((ROOT / 'assets/design_tokens.json').read_text())['palette']
SHAPES = []


def shape(kind, box, color, radius=0):
    SHAPES.append((kind, box, PALETTE.get(color, color), radius))


# The mark sits inside the central adaptive-icon safe circle.
# Three glossy puzzle blocks grow a soft six-petal candy bloom.
shape('ellipse', (27, 74, 78, 83), '#8774D1')
for x, y, color, shadow in [(30, 47, 'candyPink', '#DE4088'),
                           (54, 47, 'turquoise', '#25BCB8'),
                           (42, 65, 'mangoOrange', '#E49B39')]:
    shape('round', (x, y + 3, x + 22, y + 22), shadow, 6)
    shape('round', (x, y, x + 22, y + 19), color, 6)
    shape('round', (x + 4, y + 3, x + 17, y + 6), 'creamWhite', 1.5)
shape('round', (49, 32, 55, 50), '#6BAE4B', 3)
shape('ellipse', (37, 34, 53, 44), 'candyLime')
shape('ellipse', (53, 30, 69, 40), 'turquoise')
for box in [(44, 24, 55, 36), (53, 25, 65, 37), (56, 34, 68, 46),
            (48, 40, 60, 52), (38, 36, 50, 48), (36, 27, 48, 39)]:
    shape('ellipse', box, 'bubblegumPink')
shape('ellipse', (44, 31, 60, 47), 'lemonYellow')
shape('ellipse', (47, 34, 50, 38), 'ink')
shape('ellipse', (54, 34, 57, 38), 'ink')
shape('round', (49, 40, 55, 42), 'ink', 1)
shape('ellipse', (46, 33, 48, 35), 'creamWhite')


def path_for(kind, box, radius):
    x, y, x2, y2 = box
    if kind == 'round':
        r = min(radius, (x2-x)/2, (y2-y)/2)
        return (f'M{x+r},{y} H{x2-r} Q{x2},{y} {x2},{y+r} '
                f'V{y2-r} Q{x2},{y2} {x2-r},{y2} '
                f'H{x+r} Q{x},{y2} {x},{y2-r} '
                f'V{y+r} Q{x},{y} {x+r},{y} Z')
    cx, cy = (x+x2)/2, (y+y2)/2
    rx, ry = (x2-x)/2, (y2-y)/2
    k = .5522847498
    return (f'M{x},{cy} C{x},{cy-k*ry} {cx-k*rx},{y} {cx},{y} '
            f'C{cx+k*rx},{y} {x2},{cy-k*ry} {x2},{cy} '
            f'C{x2},{cy+k*ry} {cx+k*rx},{y2} {cx},{y2} '
            f'C{cx-k*rx},{y2} {x},{cy+k*ry} {x},{cy} Z')


def raster(size):
    scale = size*4/108
    picture = Image.new('RGB', (size*4, size*4), PALETTE['electricPurple'])
    draw = ImageDraw.Draw(picture)
    draw.ellipse(tuple(v*scale for v in (-22, -30, 87, 76)), fill=PALETTE['blueberry'])
    draw.ellipse(tuple(v*scale for v in (-19, 89, 120, 145)), fill=PALETTE['bubblegumPink'])
    for kind, box, color, radius in SHAPES:
        coords = tuple(v*scale for v in box)
        if kind == 'round':
            draw.rounded_rectangle(coords, radius=radius*scale, fill=color)
        else:
            draw.ellipse(coords, fill=color)
    return picture.resize((size, size), Image.Resampling.LANCZOS)


def main():
    resources = ROOT / 'android/app/src/main/res'
    brand = ROOT / 'assets/brand'
    brand.mkdir(exist_ok=True)
    for directory, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                            ('xxhdpi', 144), ('xxxhdpi', 192)]:
        raster(size).save(resources / f'mipmap-{directory}/ic_launcher.png')
    raster(512).save(brand / 'store_icon_512.png')
    raster(1080).save(brand / 'icon_preview.png')
    svg_shapes = '\n'.join(f'<path fill="{color}" d="{path_for(kind, box, r)}"/>'
                           for kind, box, color, r in SHAPES)
    (brand / 'candyverse_mark.svg').write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108">\n'
        '<rect width="108" height="108" fill="'+PALETTE['electricPurple']+'"/>\n'
        '<ellipse cx="32.5" cy="23" rx="54.5" ry="53" fill="'+PALETTE['blueberry']+'"/>\n'
        '<ellipse cx="50.5" cy="117" rx="69.5" ry="28" fill="'+PALETTE['bubblegumPink']+'"/>\n'
        + svg_shapes + '\n</svg>\n')
    for monochrome in (False, True):
        name = 'ic_launcher_monochrome.xml' if monochrome else 'ic_launcher_foreground.xml'
        paths = '\n'.join(f'    <path android:fillColor="{"#FFFFFFFF" if monochrome else color}" android:pathData="{path_for(kind, box, r)}" />'
                          for kind, box, color, r in SHAPES if not monochrome or color not in [PALETTE['ink'], '#8774D1'])
        (resources / 'drawable' / name).write_text(
            '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
            '    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">\n'
            + paths + '\n</vector>\n')
    # Same native full-bleed background as the legacy/store icon.
    (resources / 'drawable/ic_launcher_background.xml').write_text(
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">\n'
        f'    <path android:fillColor="{PALETTE["electricPurple"]}" android:pathData="M0,0 H108 V108 H0 Z"/>\n'
        f'    <path android:fillColor="{PALETTE["blueberry"]}" android:pathData="{path_for("ellipse", (-22,-30,87,76), 0)}"/>\n'
        f'    <path android:fillColor="{PALETTE["bubblegumPink"]}" android:pathData="{path_for("ellipse", (-19,89,120,145), 0)}"/>\n'
        '</vector>\n')
    for version in (26, 33):
        directory = resources / f'mipmap-anydpi-v{version}'
        directory.mkdir(exist_ok=True)
        mono = '    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />\n' if version == 33 else ''
        (directory / 'ic_launcher.xml').write_text(
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@drawable/ic_launcher_background" />\n'
            '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
            + mono + '</adaptive-icon>\n')
    print('Generated original Candyverse launcher vectors, density PNGs and 512 px store icon.')


if __name__ == '__main__':
    main()
