#!/usr/bin/env python3
"""Archive baseline 2a73bfe and add only the same opt-in measurement hooks."""
from pathlib import Path
import io
import subprocess
import sys
import tarfile

repo = Path(__file__).resolve().parents[1]
destination = Path(sys.argv[1]).resolve()
if destination.exists() and any(destination.iterdir()):
    raise SystemExit('Destination must be empty')
destination.mkdir(parents=True, exist_ok=True)
archive = subprocess.check_output(['git', 'archive', '2a73bfe'], cwd=repo)
with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
    tar.extractall(destination, filter='data')
app = destination / 'Sling Duo'
scene_file = app / 'GameScene.swift'
s = scene_file.read_text()
s = s.replace('    private var ready = false', '''    #if GRAPHICS_PROFILE
    private var graphicsProfileSession: GraphicsProfileSession?
    #endif
    private var ready = false''')
s = s.replace('        reset()\n        #if DEBUG', '''        reset()
        #if GRAPHICS_PROFILE
        startGraphicsProfile()
        #endif
        #if DEBUG''', 1)
s = s.replace('    override func update(_ currentTime: TimeInterval) {', '''    override func update(_ currentTime: TimeInterval) {
        #if GRAPHICS_PROFILE
        graphicsProfileSession?.frame(currentTime)
        #endif''')
current = (repo / 'Sling Duo' / 'GameScene.swift').read_text()
extension = '#if GRAPHICS_PROFILE\nextension GameScene' + current.split('#if GRAPHICS_PROFILE\nextension GameScene', 1)[1]
extension = extension.replace('cachedTextureNames.count', '-1').replace('extension GameScene {', '''extension GameScene {
    private func releaseCaveResources() { setGameplayPaused(true) }
    private func preloadCave(_ cave: CaveID) async {}''')
scene_file.write_text(s + '\n' + extension)
(app / 'GraphicsProfileSession.swift').write_bytes((repo / 'Sling Duo' / 'GraphicsProfileSession.swift').read_bytes())
p = app / 'ContentView.swift'
s = p.read_text()
needle = '        scene.steeringMode = SteeringMode(rawValue: steeringMode) ?? .tilt\n'
a = s.index(needle) + len(needle)
s = s[:a] + '''        #if GRAPHICS_PROFILE
        didSeeStory = true
        didSeeTutorial = true
        selectedCave = .depths
        scene.setGameplayPaused(false)
        #endif
''' + s[a:]
p.write_text(s)
(destination / 'Tools').mkdir()
(destination / 'Tools' / 'profile_graphics.sh').write_bytes((repo / 'Tools' / 'profile_graphics.sh').read_bytes())
print(f'Baseline 2a73bfe with measurement-only hooks saved at {destination}')
