#!/usr/bin/env python3
"""Build upright periodic tiles from preserved originals; no runtime blending cost."""
from pathlib import Path
from PIL import Image
import json

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'Sling Duo/Assets.xcassets'
SOURCES = ROOT / 'ArtSources/BackdropOriginals'

def export():
    report = []
    for source in sorted(SOURCES.glob('*.png')):
        image = Image.open(source).convert('RGBA')
        # Blend in premultiplied alpha so transparent bank edges have no dark fringe.
        premultiplied = image.convert('RGBa')
        output = image.copy()
        band = min(96, image.height // 8)
        for y in range(band):
            t = y / (band - 1)
            weight = .5 * (1 - t * t * (3 - 2 * t))
            top = premultiplied.crop((0, y, image.width, y + 1))
            bottom = premultiplied.crop((0, image.height - 1 - y, image.width, image.height - y))
            output.paste(Image.blend(top, bottom, weight).convert('RGBA'), (0, y))
            output.paste(Image.blend(bottom, top, weight).convert('RGBA'), (0, image.height - 1 - y))
        output = output.convert('RGBA')
        output.save(ASSETS / (source.stem + 'Texture.dataset/texture.png'), optimize=True)
        assert output.crop((0, 0, output.width, 1)).tobytes() == output.crop((0, output.height-1, output.width, output.height)).tobytes()
        report.append(dict(name=source.stem, size=list(output.size), edgeBand=band, edgePixelsIdentical=True))
    (ROOT / 'ArtSources/backdrop-export-report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f'Exported {len(report)} upright periodic tiles.')

if __name__ == '__main__':
    export()
