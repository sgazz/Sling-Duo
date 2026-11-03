# Visual authoring data

`Sling Duo/Assets.xcassets/VisualManifest.dataset/manifest.json` is the runtime source of truth. `VisualManifest.swift` decodes it once; `ClimberNode`, `PlatformArtwork` and `CaveBackdrop` consume it. `GameTextureStore` checks each decoded runtime image's pixel size before creating its texture.

- `sourcePixels`: exact original PNG dimensions, not a target point size.
- `runtimePixels`: exact exported PNG dimensions.
- `crop`: normalized `[x, y, width, height]`, origin **top left** of the full source canvas. Hero crops exclude empty margins; platform crops describe the body, with 8 source pixels of rendering bleed added by `PlatformArtwork`.
- `pivot`: normalized `[x, y]`, origin **top left**. Hero pivot is the belt attachment; platform pivot is the middle of the landing line.
- `landingLine`: normalized source Y, origin **top left**.
- `regions`: named decor/foreground UV rectangles, origin **bottom left**, matching SpriteKit.

Coordinates remain normalized when full canvases are downsampled. No automatic trimming or recentering is allowed. The earlier Volcanic platform metadata described a 1792×1024 canvas while its PNG is 1774×887: this manifest uses the actual canvas and retains the existing normalized crop/pivot. That also removes the old incorrect crop aspect.

Run from the project root:

```sh
python3 Tools/export_game_textures.py
python3 Tools/export_backdrop_tiles.py
python3 Tools/validate_visual_manifest.py
```

Pillow is required. Validation rejects inventory differences, source/runtime size mismatches, out-of-bounds crops/UVs, invalid pivots/landing lines, and nonmatching upright tile edge pixels. It deliberately does not rewrite expected dimensions: an export-size change requires an explicit manifest edit.

`BackdropOriginals/` contains the unmodified 16 background/bank PNGs outside the app target. The backdrop exporter blends only 96 rows at each vertical edge, in premultiplied alpha, and preserves the center pixels. Both edge rows become identical. Runtime dimensions and texture count stay unchanged; there is no extra runtime shader or blend layer. This is an edge retouch, not a claim that large painted motifs are nonrepeating. Inspect the saved phone/tablet test attachments after art changes.

Depths retains alternating mirrored tiles; upright biomes repeat every one tile. All use uniform width-fit scaling, so the authored banks stay visible and the texture aspect ratio is preserved. Enough tiles are allocated for the viewport plus the wrap period. Decor coordinates are centered on the camera, and their one-cell wrap agrees with the replicated prop pattern.
