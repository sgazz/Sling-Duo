import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var scene = GameScene(size: GameConstants.sceneSize)
    @Environment(\.scenePhase) private var phase
    @AppStorage("SlingDuo.soundEnabled") private var soundEnabled = true
    @AppStorage("SlingDuo.steeringMode") private var steeringMode = "tilt"
    @State private var paused = false
    @State private var countdown: Int?
    @State private var resumeTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SpriteView(scene: scene, preferredFramesPerSecond: 60)
                .ignoresSafeArea()
            HStack(spacing: 8) {
                Button { pause() } label: { controlIcon("pause.fill") }
                    .accessibilityLabel("Pause game")
                    .accessibilityIdentifier("pauseGame")
                Button { soundEnabled.toggle() } label: {
                    controlIcon(soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                }
                .accessibilityLabel(soundEnabled ? "Mute sound" : "Enable sound")
                .accessibilityIdentifier("soundToggle")
            }
            .buttonStyle(.plain)
            .padding(.trailing, 18)
            .padding(.top, 8)
            if paused {
                ZStack {
                    Color.black.opacity(0.65).ignoresSafeArea()
                    if let countdown {
                        Text("\(countdown)").font(.system(size: 80, weight: .heavy))
                            .accessibilityIdentifier("resumeCountdown")
                    } else {
                        VStack(spacing: 24) {
                            Text("PAUSED").font(.title.bold())
                            Button("Continue") { resume() }.accessibilityIdentifier("continueGame")
                            Button("Restart") { scene.restartFromMenu(); resume() }
                            Button(steeringMode == "tilt" ? "Controls: Tilt" : "Controls: Slide") {
                                steeringMode = steeringMode == "tilt" ? "slide" : "tilt"
                            }
                            .accessibilityIdentifier("steeringMode")
                            Button(soundEnabled ? "Sound: On" : "Sound: Off") { soundEnabled.toggle() }
                        }
                        .font(.title3.bold())
                        .padding(40)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .statusBarHidden()
        .onAppear {
            scene.soundEnabled = soundEnabled
            scene.steeringMode = SteeringMode(rawValue: steeringMode) ?? .tilt
        }
        .onChange(of: steeringMode) { _, mode in scene.steeringMode = SteeringMode(rawValue: mode) ?? .tilt }
        .onChange(of: soundEnabled) { _, enabled in scene.soundEnabled = enabled }
        .onChange(of: phase) { _, newPhase in
            scene.setActive(newPhase == .active)
            if newPhase != .active { pause() }
        }
        .onDisappear { resumeTask?.cancel() }
    }

    private func controlIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white.opacity(0.8))
            .frame(width: 44, height: 44)
            .background(.white.opacity(0.07), in: Circle())
            .contentShape(Circle())
    }

    private func pause() {
        resumeTask?.cancel()
        countdown = nil
        paused = true
        scene.setGameplayPaused(true)
    }

    private func resume() {
        resumeTask?.cancel()
        resumeTask = Task { @MainActor in
            for number in (1...3).reversed() {
                guard !Task.isCancelled else { return }
                countdown = number
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
            }
            guard !Task.isCancelled, phase == .active else { return }
            countdown = nil
            paused = false
            scene.setGameplayPaused(false)
        }
    }
}
