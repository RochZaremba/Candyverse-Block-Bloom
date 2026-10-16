# Candy Kingdom artwork

2026-10-16: the owner's five new screen references are implemented with separate
background plates, live Flutter UI and additional sprite assets. Sources and
generation notes: [REFERENCE_ART.md](REFERENCE_ART.md).

Created2026-10-15 for the owner's explicitly requested visual replacement.
All runtime assets are local; no image service or network SDK ships in the app.

| File | Source / intended use |
| --- | --- |
| brand-sheet.png | Owner-supplied `Candyverse_ Whimsical Candy Kingdom-1.png`, copied unchanged; the banner is selected at paint time. |
| mascots.png | Built-in image generation, reference-based kitten / puppy / bunny / fox, real RGBA alpha. |
| buildings.png | Built-in image generation, six evolutions of three buildings, real RGBA alpha. |
| worlds.png | Built-in image generation, three island backgrounds. |
| icon.png | Built-in image editing of the owner's icon reference into full-bleed artwork. |

The generated PNGs are copied unchanged from the built-in image tool output.
`scripts/generate_brand_icon.py` only packages/resamples icon.png for Android
density buckets and the store. Original supplied banner/logo remain intact.
Runtime sprite rectangles are explicit metadata in the rendering code, because
the generator did not produce perfectly uniform building rows. No alternate
third-party artwork or character likeness was requested.

Prompts and image-tool settings: [PROMPTS.md](PROMPTS.md).
The owner must confirm rights to supplied artwork before store submission;
this provenance records the source, rather than asserting a legal clearance.
