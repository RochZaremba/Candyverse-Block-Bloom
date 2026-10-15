#!/usr/bin/env python3
"""Package the owner-approved rendered kitten artwork at Android/store densities.

No AI/API is invoked here. The immutable source render and its prompt/provenance
are checked in under assets/kingdom; Pillow only exports required resolutions.
"""
from pathlib import Path
from PIL import Image, PngImagePlugin

ROOT = Path(__file__).resolve().parent.parent


def main():
    source = Image.open(ROOT/'assets/kingdom/icon.png').convert('RGBA')
    resources = ROOT/'android/app/src/main/res'
    brand = ROOT/'assets/brand'
    metadata = PngImagePlugin.PngInfo()
    metadata.add(b'sRGB', b'\x00')
    for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                          ('xxhdpi', 144), ('xxxhdpi', 192)]:
        source.resize((size, size), Image.Resampling.LANCZOS).save(
            resources/f'mipmap-{density}/ic_launcher.png', pnginfo=metadata)
    source.resize((512, 512), Image.Resampling.LANCZOS).save(
        brand/'store_icon_512.png', pnginfo=metadata)
    source.resize((1080, 1080), Image.Resampling.LANCZOS).save(
        brand/'icon_preview.png', pnginfo=metadata)
    # Android masks the full-bleed square; no second rounded frame is baked in.
    drawable = resources/'drawable-nodpi'
    drawable.mkdir(exist_ok=True)
    source.resize((432, 432), Image.Resampling.LANCZOS).save(
        drawable/'candyverse_kitten.png', pnginfo=metadata)
    (resources/'drawable/ic_launcher_foreground.xml').write_text(
        '<bitmap xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    android:src="@drawable/candyverse_kitten" android:gravity="fill" />\n')
    (resources/'drawable/ic_launcher_background.xml').write_text(
        '<shape xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <solid android:color="#62C9FF" />\n</shape>\n')
    (resources/'drawable/ic_launcher_monochrome.xml').write_text(
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        ' android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">\n'
        ' <path android:fillColor="#FFFFFFFF" android:pathData="M25,48 L24,22 Q38,24 43,35 Q54,31 65,35 Q76,24 84,22 L83,48 Q91,60 83,75 Q72,88 54,88 Q36,88 25,75 Q17,60 25,48 Z" />\n'
        '</vector>\n')
    print('Exported rendered kitten store icon, legacy densities and adaptive icon.')


if __name__ == '__main__':
    main()
