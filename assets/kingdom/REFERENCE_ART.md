# October 16 reference artwork

The owner supplied five portrait Candyverse compositions on 2026-10-16 and
requested that the application follow them nearly one-to-one. Their file names
are `1000016960.jpg` (menu), `1000016962.jpg` (game), `1000016961.jpg`
(result), `1000016958.jpg` (return dialog), and `1000016959.jpg` (island).

All six new runtime PNGs were produced by the built-in image editing tool from
those references and copied unchanged from its output. There is no network
image service or generated text in the runtime app. The source JPEGs are not
used as flat screenshots behind invisible hit targets. Scores, currency,
board, tray, progress, controls, dialogs and navigation are Flutter widgets.

| Asset | Output / purpose |
| --- | --- |
| menu-scene.png | `exec-d3390365-535e-4867-9bf8-218dacffa684`, 941×1672; logo, empty banner, three pets and scenery; sample scores and buttons removed. |
| game-scene.png | `exec-adafea65-b805-422d-bd4f-a125a0264160`, 941×1672; game borders, pets, logo and empty banner; all board, score, tray and message UI removed. |
| result-scene.png | `exec-3c16e1ee-dee3-4972-9801-43cef84b3f5e`, portrait result background; original star/pet placement retained, result title, amounts and controls removed. |
| island-scene.png | `exec-e5fe4cf9-10ff-4cd9-816b-4d105b8b815d`, 1448×1086; island scenery with distant castle, bridges and waterfalls; foreground buildings and pets removed for live progression sprites. |
| control-atlas.png | `exec-1117ec4a-886a-4f74-9dc6-2962f1d4360d`, 1254×1254 RGBA; four blank gold, aqua, pink and cream pill surfaces. Source rectangles are in candy_controls.dart. |
| reference-mascots.png | `exec-37bf217b-d4dd-4a5d-aa27-33d8f709871f`, 1024×1536 RGBA; kitten/puppy, bunny/hamster, bird/star in two columns and three rows. |

The initial mascot output `exec-21e8c20f-731c-40fe-9deb-e97845160b10` had a
colored background; a second image-editing pass removed it, preserving the
characters. Only the final alpha cutout is bundled. Corner and inter-cell alpha
were checked. Sprite placement, cropping, resizing and opacity are applied by
Flutter at paint time, without rewriting the generated PNGs.

## Prompt record

The background edits asked to preserve the supplied composition, candy colors,
logo, scenery and character placement, remove drawn UI and sample values, and
fill those areas with matching clouds. The advertisement frame was preserved
with its center blank for a live caption. The result edit additionally retained
the smiling star and kept the pets lower than the result title. The island edit
retained only the landscape and left grass patches for independent buildings.

The control prompt specified four separated equal-size rows of glossy empty
pill surfaces, white/pink rims, gold/orange, turquoise, pink and cream shading,
sparkles, no lettering/icons and real transparent space between shapes.

The mascot prompt specified a 2×3 atlas in this order: kitten, puppy, bunny,
hamster holding pink candy, blue bird, smiling yellow star. It requested full
uncropped bodies, safe margins, the reference faces and real alpha. The second
pass explicitly requested removal of every colored background area while
preserving the six characters and their positions.

## Typography

`assets/fonts/LilitaOne-Regular.ttf` comes from Google Fonts' `ofl/lilitaone`
directory on GitHub. It is distributed under the SIL Open Font License 1.1,
retained as `assets/fonts/LilitaOne-OFL.txt`. It is bundled locally for headings
and button lettering; body text continues to use the app's existing font.

Historical Kingdom artwork remains intact for provenance and prestige worlds.
Existing building stage sprites remain the source of all 30 upgrade levels.
