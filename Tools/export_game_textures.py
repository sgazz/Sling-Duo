#!/usr/bin/env python3
"""Rebuild runtime textures and UI illustrations from ArtSources (Pillow required).

UV crops, belt pivots and landing geometry intentionally stay in original master
coordinates in Swift. Full canvases are resized, never trimmed or recentered.
"""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'Sling Duo' / 'Assets.xcassets'
report = []
for source in sorted((ROOT / 'ArtSources').glob('*.png')):
    name = source.stem
    original = Image.open(source).convert('RGBA')
    limit = 384 if name.startswith('Hero') else 256 if name == 'DawnheartFragment' else 768
    ratio = min(1, limit / max(original.size))
    size = tuple(round(value * ratio) for value in original.size)
    runtime = original.resize(size, Image.Resampling.LANCZOS)
    target = ASSETS / (name + 'Texture.dataset')
    runtime.save(target / 'texture.png', optimize=True)
    if name.startswith('Hero'):
        ratio = 640 / max(original.size)
        ui = original.resize(tuple(round(value * ratio) for value in original.size), Image.Resampling.LANCZOS)
        ui.save(ASSETS / (name + 'Illustration.imageset') / 'image.png', optimize=True)
    elif name == 'DawnheartFragment':
        contents = json.loads((ASSETS / (name + '.imageset') / 'Contents.json').read_text())
        runtime.save(ASSETS / (name + '.imageset') / contents['images'][0]['filename'], optimize=True)
    report.append(dict(name=name, before_width=original.width, before_height=original.height,
                       after_width=runtime.width, after_height=runtime.height,
                       before_rgba_bytes=original.width * original.height * 4,
                       after_rgba_bytes=runtime.width * runtime.height * 4,
                       before_png_bytes=source.stat().st_size,
                       after_png_bytes=(target / 'texture.png').stat().st_size))
(ROOT / 'ArtSources' / 'texture-export-report.json').write_text(json.dumps(report, indent=2) + '\n')
print(f'Rebuilt {len(report)} runtime textures; UI hero illustrations retain 640px canvases.')
