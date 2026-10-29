import SpriteKit
import SwiftUI

struct ContentView: View {
    @StateObject private var scene = GameScene(size: GameConstants.sceneSize)
    @Environment(\.scenePhase) private var phase
    @AppStorage("SlingDuo.soundEnabled") private var soundEnabled = true
    @AppStorage("SlingDuo.steeringMode") private var steeringMode = "tilt"
    @AppStorage("SlingDuo.turboEnabled") private var turboEnabled = false
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
            if let summary = scene.escapeSummary {
                ZStack {
                    Color.black.opacity(0.65).ignoresSafeArea()
                    VStack(spacing: 18) {
                        Image(systemName: "sun.max.fill").font(.system(size: 48)).foregroundStyle(.yellow)
                        Text("YOU ESCAPED!").font(.title.bold())
                        Text(summary.turbo ? "TURBO ESCAPE • 150 / 150" : "ESCAPE • 150 / 150")
                            .font(.caption.bold())
                        Text("SCORE \(summary.points)").font(.title2.bold())
                        Text("TIME \(EscapeProgress.timeText(summary.seconds))")
                        Text("LONGEST COMBO \(summary.longestCombo)")
                        Button("Keep Climbing") {
                            scene.setGameplayPaused(true)
                            scene.continueEndless()
                            paused = true
                            resume()
                        }.accessibilityIdentifier("keepClimbing")
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
                        Button("Play Again") {
                            scene.setGameplayPaused(true)
                            scene.restartFromMenu()
                            paused = true
                            resume()
                        }.accessibilityIdentifier("playAgain")
                        .buttonStyle(.bordered)
                    }
                    .foregroundStyle(.white)
                    .padding(30)
                    .background(Color(red: 0.06, green: 0.09, blue: 0.16).opacity(0.98), in: RoundedRectangle(cornerRadius: 24))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if paused {
                ZStack {
                    Color.black.opacity(0.65).ignoresSafeArea()
                    if let countdown {
                        Text("\(countdown)").font(.system(size: 80, weight: .heavy))
                            .accessibilityIdentifier("resumeCountdown")
                    } else {
                        VStack(spacing: 20) {
                            Text("PAUSED").font(.title.bold())
                            Button("Continue") { resume() }.accessibilityIdentifier("continueGame")
                            Button("Restart") { scene.restartFromMenu(); resume() }
                            Button(steeringMode == "tilt" ? "Controls: Tilt" : "Controls: Slide") {
                                steeringMode = steeringMode == "tilt" ? "slide" : "tilt"
                            }
                            .accessibilityIdentifier("steeringMode")
                            Button(turboEnabled ? "Turbo experiment: On" : "Turbo experiment: Off") {
                                turboEnabled.toggle()
                            }
                            .accessibilityIdentifier("turboToggle")
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
            scene.turboEnabled = turboEnabled
            scene.soundEnabled = soundEnabled
            scene.steeringMode = SteeringMode(rawValue: steeringMode) ?? .tilt
        }
        .onChange(of: turboEnabled) { _, enabled in scene.turboEnabled = enabled }
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
