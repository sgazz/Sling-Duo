# Texture masters

These 29 original PNGs are outside the application's synchronized target folder
and are not shipped in the app. Regenerate exports with:

    python3 Tools/export_game_textures.py

Install Pillow in the Python environment first. Runtime limits: heroes 384px,
platforms 768px, fragment 256px (long edge). Hero UI/intro illustrations use a
separate 640px canvas. No source is trimmed, recentered or repainted. Existing
Swift geometry remains in original master coordinates; normalized texture crops,
belt positions and platform anchors are unchanged. Integer pixel rounding affects
sampling resolution only, never the point size or gameplay footprint.

Runtime PNGs are data assets, decoded by GameTextureStore using NSDataAsset and
UIImage(data:), rather than the process-wide UIImage(named:) cache. Illustration
imagesets serve SwiftUI only. Background/decor data assets retain their original
resolution. Releasing the scene package clears app-owned texture references;
SpriteKit/Metal release timing remains framework-controlled.
