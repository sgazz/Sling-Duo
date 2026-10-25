import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var scene = GameScene(size: GameConstants.sceneSize)
    @Environment(\.scenePhase) private var phase
    @AppStorage("SlingDuo.soundEnabled") private var soundEnabled = true

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SpriteView(scene: scene, preferredFramesPerSecond: 60)
                .ignoresSafeArea()
            Button {
                soundEnabled.toggle()
            } label: {
                Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.07), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 18)
            .padding(.top, 8)
            .accessibilityLabel(soundEnabled ? "Mute sound" : "Enable sound")
            .accessibilityIdentifier("soundToggle")
        }
        .statusBarHidden()
        .onAppear { scene.soundEnabled = soundEnabled }
        .onChange(of: soundEnabled) { _, enabled in scene.soundEnabled = enabled }
        .onChange(of: phase) { _, newPhase in scene.setActive(newPhase == .active) }
    }
}
