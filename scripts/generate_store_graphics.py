#!/usr/bin/env python3
"""Render original store illustrations using the existing vector brand mark.

Development dependency: Pillow. These promotional graphics are not screenshots.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, PngImagePlugin
from generate_brand_icon import raster, PALETTE

ROOT = Path(__file__).resolve().parent.parent


def render(language):
    scale = 2
    image = Image.new('RGB', (1024*scale, 500*scale), PALETTE['electricPurple'])
    draw = ImageDraw.Draw(image)

    def ellipse(box, color):
        draw.ellipse(tuple(int(v*scale) for v in box), fill=color)

    def text(position, value, size, weight='Bold', color='creamWhite'):
        font = ImageFont.truetype(str(ROOT/f'test/fonts/Roboto-{weight}.ttf'), size*scale)
        draw.text(tuple(v*scale for v in position), value, font=font, fill=PALETTE[color])

    ellipse((-280, -340, 600, 620), PALETTE['blueberry'])
    ellipse((650, 320, 1270, 820), PALETTE['bubblegumPink'])
    ellipse((740, -190, 1100, 170), PALETTE['turquoise'])
    # The already established mark; no external stock art or new game content.
    mark = raster(370*scale)
    mask = Image.new('L', mark.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, mark.width-1, mark.height-1), 72*scale, fill=255)
    image.paste(mark, (48*scale, 65*scale), mask)
    text((455, 107), 'Candyverse', 74, 'Black')
    text((459, 200), 'Block & Bloom', 42)
    if language == 'pl':
        lines = ('Układaj klocki.', 'Rozwijaj cukierkową wyspę.')
    else:
        lines = ('Place colorful blocks.', 'Grow your candy island.')
    for y, line in zip((291, 333), lines):
        text((460, y), line, 28, 'Regular')
    metadata = PngImagePlugin.PngInfo()
    metadata.add(b'sRGB', b'\x00')
    output = ROOT/f'assets/store/feature_graphic_{language}.png'
    image.resize((1024, 500), Image.Resampling.LANCZOS).save(output, pnginfo=metadata)


if __name__ == '__main__':
    for language in ('pl', 'en'):
        render(language)
