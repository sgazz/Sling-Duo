#!/usr/bin/env python3
"""Validate authoring/runtime PNG dimensions, normalized geometry and tile seams."""
import json, struct
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'Sling Duo/Assets.xcassets'
def dimensions(path):
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', f'Invalid PNG: {path}'
    return list(struct.unpack('>II', data[16:24]))
def validate():
    manifest = json.loads((ASSETS/'VisualManifest.dataset/manifest.json').read_text())
    assert manifest['version'] == 1
    names = set()
    for name, entry in manifest['textures'].items():
        names.add(name)
        folder = ASSETS/(name+'Texture.dataset')
        contents = json.loads((folder/'Contents.json').read_text())
        png = folder/contents['data'][0]['filename']
        assert dimensions(png) == entry['runtimePixels'], name+' runtime dimensions'
        for key in ['sourcePixels', 'runtimePixels']:
            assert len(entry[key]) == 2 and all(isinstance(v, int) and v > 0 for v in entry[key]), (name, key)
        source = ROOT/'ArtSources'/f'{name}.png'
        if not source.exists(): source = ROOT/'ArtSources/BackdropOriginals'/f'{name}.png'
        assert dimensions(source if source.exists() else png) == entry['sourcePixels'], name+' source dimensions'
        for key, r in [('crop',entry.get('crop'))] + list(entry['regions'].items()):
            if r is None: continue
            assert len(r)==4 and all(0<=v<=1 for v in r) and r[2]>0 and r[3]>0, (name,key,r)
            assert r[0]+r[2]<=1.000001 and r[1]+r[3]<=1.000001, (name,key,r)
        if 'pivot' in entry:
            assert len(entry['pivot'])==2 and all(0<=v<=1 for v in entry['pivot']), name
        if name.startswith('Hero'): assert 'crop' in entry and 'pivot' in entry, name
        if 'Platform' in name:
            assert 'crop' in entry and 'pivot' in entry and 'landingLine' in entry, name
            c=entry['crop']; assert c[1]<=entry['landingLine']<=c[1]+c[3], name
            w,h=entry['sourcePixels']
            assert c[0]*w>=8 and c[1]*h>=8 and (c[0]+c[2])*w<=w-8 and (c[1]+c[3])*h<=h-8, name+' crop bleed'
    actual = {p.name.removesuffix('Texture.dataset') for p in ASSETS.glob('*Texture.dataset')}
    assert names == actual, f'Manifest inventory mismatch: {names ^ actual}'
    from PIL import Image
    for p in (ROOT/'ArtSources/BackdropOriginals').glob('*.png'):
        runtime=ASSETS/(p.stem+'Texture.dataset/texture.png'); im=Image.open(runtime).convert('RGBA')
        assert im.crop((0,0,im.width,1)).tobytes()==im.crop((0,im.height-1,im.width,im.height)).tobytes(),p.stem+' seam'
    print(f'Validated {len(names)} textures, crops, pivots, landing lines, decor regions and 16 tile seams.')
if __name__=='__main__': validate()
