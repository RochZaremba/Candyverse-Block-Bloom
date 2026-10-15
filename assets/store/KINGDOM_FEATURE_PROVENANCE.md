# Candy Kingdom feature graphic

Created2026-10-15 using the built-in `image_gen.imagegen` tool, following the
imagegen skill. This store-only promotional artwork does not change the signed
application or its runtime assets.

- Final file: [kingdom_feature_graphic.png](kingdom_feature_graphic.png).
- Format:1024×500, RGB PNG, opaque, sRGB;972056 bytes.
- SHA256: `51e2a3b83b0e781be3b1c7cdbba923269af6baec6abe812d8772783dfbe3e789`.
- Source: the owner's `Candyverse_ Whimsical Candy Kingdom-1.png`,1536×1024,
  used as a reference/edit target. Original unchanged composite is recorded in
  [artwork provenance](../kingdom/README.md).
- Generation: `referenced_image_paths` pointed to that reference;
  `transparent_background: false`. No CLI/API fallback was used.
- Generated output:1795×876 RGB PNG. Final export only resampled the complete
  frame to1024×500 with Pillow LANCZOS and embedded sRGB metadata. No compositing,
  painting, content cropping or further art edits were performed in code.
- The same artwork serves EN and PL listings; its only text is the Candyverse
  brand. Existing rc.1 feature graphics and screenshots remain untouched.
- Reviewed visually: readable logo, orange/white kitten, full-bleed landscape
  corners, no lower icon tile, UI, watermark, slogan or white canvas.

This is promotional artwork, not an app screenshot or a claim that all pictured
scenery is an interactive game feature. The owner must confirm rights to supplied
artwork before store submission; provenance does not assert legal clearance.

## Final prompt

```text
Use case: precise-object-edit.
Asset type: Final Google Play feature graphic for Candyverse, one landscape banner, exact target aspect ratio 1024:500 (about 2.048:1), ideally 1024x500.
Input image: edit target is the TOP BANNER of the supplied composite. The lower square icon and white canvas are not part of the requested output.
Primary request: adapt the top candy kingdom banner into a complete beautifully framed standalone feature graphic at 1024:500. Preserve the original Candyverse logo identity and precise word "Candyverse", the happy orange-white kitten with enormous violet-blue eyes, the glossy candy blocks, floating candy islands, waterfalls, flowers and bright blue sky. Recompose to the new moderately wide ratio so the full readable logo sits to the left and the complete waving kitten dominates the right, with clear space between them. Fill all four corners with lush rendered scenery, no blank white margins or rounded outer corners. Extend the scene naturally when necessary, do not squash the characters or logo.
Style: sumptuous high-end soft 3D game render faithful to the reference, rich clean saturated candy colors, sculpted fur and glossy blocks.
Constraints: one coherent scene, no lower icon tile, no split panels, no white canvas, no UI, no buttons, no slogans, no extra text. Only exact "Candyverse" logo lettering, perfectly readable, safely inset from edges. Artwork for both Polish and English store listing, no localized copy. No watermark.
```

