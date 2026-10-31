import SpriteKit
import SwiftUI

struct ContentView: View {
    @StateObject private var scene = GameScene(size: GameConstants.sceneSize)
    @Environment(\.scenePhase) private var phase
    @AppStorage("SlingDuo.soundEnabled") private var soundEnabled = true
    @AppStorage("SlingDuo.steeringMode") private var steeringMode = "tilt"
    @AppStorage("SlingDuo.turboEnabled") private var turboEnabled = false
    @AppStorage("SlingDuo.didSeeTutorial") private var didSeeTutorial = false
    @AppStorage("SlingDuo.didSeeStory") private var didSeeStory = false
    @AppStorage("SlingDuo.hudMode") private var hudMode = "compact"
    @AppStorage("SlingDuo.unlocked.crystalCavern") private var crystalCavernUnlocked = false
    @AppStorage("SlingDuo.unlocked.undergroundRiver") private var undergroundRiverUnlocked = false
    @AppStorage("SlingDuo.unlocked.ancientRuins") private var ancientRuinsUnlocked = false
    @AppStorage("SlingDuo.unlocked.volcanicPassage") private var volcanicPassageUnlocked = false
    @AppStorage("SlingDuo.unlocked.frozenRift") private var frozenRiftUnlocked = false
    @AppStorage("SlingDuo.unlocked.glowrootGrotto") private var glowrootGrottoUnlocked = false
    @AppStorage("SlingDuo.unlocked.stormChasm") private var stormChasmUnlocked = false
    @AppStorage("SlingDuo.unlocked.daybreakExit") private var daybreakExitUnlocked = false
    @AppStorage("SlingDuo.dawnheartFragmentMask") private var dawnheartFragmentMask = 0
    @State private var selectedCave: CaveID?
    @State private var paused = false
    @State private var showingTutorial = false
    @State private var tutorialFromPause = false
    @State private var countdown: Int?
    @State private var resumeTask: Task<Void, Never>?

    // Temporary while the level package is being play-tested. Flip this to
    // false when campaign gating is ready for players.
    private let allCavesUnlockedForTesting = true
    private var dawnheartFragments: Int { dawnheartFragmentMask.nonzeroBitCount }

    var body: some View {
        Group {
            if !didSeeStory {
                IntroStoryView { didSeeStory = true }
            } else if selectedCave == nil {
                CaveMapView(crystalUnlocked: crystalCavernUnlocked, riverUnlocked: undergroundRiverUnlocked,
                            ruinsUnlocked: ancientRuinsUnlocked, volcanicUnlocked: volcanicPassageUnlocked,
                            frozenUnlocked: frozenRiftUnlocked, glowrootUnlocked: glowrootGrottoUnlocked,
                            stormUnlocked: stormChasmUnlocked, daybreakUnlocked: daybreakExitUnlocked,
                            fragmentMask: dawnheartFragmentMask, unlocksAllCaves: allCavesUnlockedForTesting, select: start)
            } else {
                ZStack {
                    SpriteView(scene: scene, preferredFramesPerSecond: 60).ignoresSafeArea()
                    GameHUDOverlay(mode: HUDMode(rawValue: hudMode) ?? .compact, state: scene.hud, soundEnabled: soundEnabled,
                                   pause: pause, toggleSound: { soundEnabled.toggle() })
                        .accessibilityHidden(paused || showingTutorial || scene.runSummary != nil || scene.escapeSummary != nil)
                    if let summary = scene.runSummary { defeat(summary).accessibilityHidden(paused || showingTutorial) }
                    if let summary = scene.escapeSummary { victory(summary).accessibilityHidden(paused || showingTutorial) }
                    if paused && !showingTutorial { pauseOverlay }
                    if showingTutorial {
                        HowToPlayView(steeringMode: $steeringMode, returning: tutorialFromPause) {
                            didSeeTutorial = true
                            showingTutorial = false
                            if !tutorialFromPause { resume() }
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .onAppear(perform: configure)
        .onChange(of: turboEnabled) { _, enabled in scene.turboEnabled = enabled }
        .onChange(of: steeringMode) { _, mode in scene.steeringMode = SteeringMode(rawValue: mode) ?? .tilt }
        .onChange(of: soundEnabled) { _, enabled in scene.soundEnabled = enabled }
        .onChange(of: scene.escapeSummary?.cave) { _, completedCave in
            if let completedCave { dawnheartFragmentMask |= completedCave.dawnheartBit }
            if completedCave == .depths { crystalCavernUnlocked = true }
            if completedCave == .crystalCavern { undergroundRiverUnlocked = true }
            if completedCave == .undergroundRiver { ancientRuinsUnlocked = true }
            if completedCave == .ancientRuins { volcanicPassageUnlocked = true }
            if completedCave == .volcanicPassage { frozenRiftUnlocked = true }
            if completedCave == .frozenRift { glowrootGrottoUnlocked = true }
            if completedCave == .glowrootGrotto { stormChasmUnlocked = true }
            if completedCave == .stormChasm { daybreakExitUnlocked = true }
        }
        .onChange(of: phase) { _, newPhase in
            scene.setActive(newPhase == .active)
            if newPhase != .active { pause() }
        }
        .onDisappear { resumeTask?.cancel() }
    }

    private func configure() {
        scene.turboEnabled = turboEnabled
        scene.soundEnabled = soundEnabled
        scene.steeringMode = SteeringMode(rawValue: steeringMode) ?? .tilt
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        let launchesGameplayForTest = environment["SLINGDUO_SKIP_ONBOARDING"] == "1"
            || environment["SLINGDUO_SHOW_ONBOARDING"] == "1"
            || environment["SLINGDUO_ESCAPE_UI_TEST"] == "1"
            || environment["SLINGDUO_UI_SCREEN"] != nil
        if selectedCave == nil, launchesGameplayForTest {
            didSeeStory = true
            selectedCave = .depths
            scene.selectCave(.depths)
            scene.setGameplayPaused(false)
        }
        #endif
        guard selectedCave != nil else {
            scene.setGameplayPaused(true)
            return
        }
        var needsTutorial = !didSeeTutorial
        #if DEBUG
        if environment["SLINGDUO_SKIP_ONBOARDING"] == "1" { needsTutorial = false }
        if environment["SLINGDUO_SHOW_ONBOARDING"] == "1" { needsTutorial = true }
        if environment["SLINGDUO_HUD_COMPACT_TEST"] == "1" { hudMode = "compact" }
        #endif
        if needsTutorial {
            showingTutorial = true
            scene.setGameplayPaused(true)
        }
    }

    private func start(_ cave: CaveID) {
        resumeTask?.cancel()
        scene.turboEnabled = turboEnabled
        scene.soundEnabled = soundEnabled
        scene.steeringMode = SteeringMode(rawValue: steeringMode) ?? .tilt
        scene.setGameplayPaused(true)
        scene.selectCave(cave)
        selectedCave = cave
        if !didSeeTutorial {
            tutorialFromPause = false
            showingTutorial = true
        } else {
            paused = true
            resume()
        }
    }

    private func returnToMap() {
        resumeTask?.cancel()
        scene.setGameplayPaused(true)
        paused = false
        showingTutorial = false
        selectedCave = nil
    }

    private var pauseOverlay: some View {
        Group {
            if let countdown {
                ZStack {
                    GamePalette.ink.opacity(0.72).ignoresSafeArea()
                    VStack(spacing: 18) {
                        Text("BACK IN RHYTHM").font(.caption.bold()).tracking(3).foregroundStyle(GamePalette.mint)
                        Text("\(countdown)").font(.system(size: 96, weight: .heavy, design: .rounded)).monospacedDigit()
                            .accessibilityIdentifier("resumeCountdown")
                        Text(steeringMode == "tilt" ? "Hold your phone ready." : "Get your finger ready.")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                    }.foregroundStyle(.white)
                }
            } else {
                GameModal {
                    ModalHeading(eyebrow: scene.hud.endless ? "Endless" : "Escape", title: "Take a breath.", subtitle: "Your duo is waiting. Everything is paused.")
                    HStack(spacing: 8) {
                        StatTile(label: "Height", value: "\(scene.hud.height)")
                        StatTile(label: "Score", value: "\(scene.hud.points)")
                        StatTile(label: "Time", value: EscapeProgress.timeText(Double(scene.hud.seconds)))
                    }
                    Button(scene.runSummary == nil ? "Continue" : "Try Again") {
                        if scene.runSummary != nil { scene.restartFromMenu() }
                        resume()
                    }.buttonStyle(GameActionStyle()).accessibilityIdentifier("continueGame")
                    VStack(spacing: 8) {
                        SettingsRow(symbol: steeringMode == "tilt" ? "iphone.gen3" : "hand.draw", title: "Controls",
                                    detail: steeringMode == "tilt" ? "Tilt gently to steer in flight" : "Slide horizontally to steer in flight",
                                    value: steeringMode == "tilt" ? "TILT" : "SLIDE", id: "steeringMode",
                                    accessibilityLabel: steeringMode == "tilt" ? "Controls: Tilt" : "Controls: Slide") {
                            steeringMode = steeringMode == "tilt" ? "slide" : "tilt"
                        }
                        SettingsRow(symbol: soundEnabled ? "speaker.wave.2" : "speaker.slash", title: "Sound", detail: "Launch, catch and warning cues",
                                    value: soundEnabled ? "ON" : "OFF", id: "pauseSound",
                                    accessibilityLabel: soundEnabled ? "Sound: On" : "Sound: Off") { soundEnabled.toggle() }
                        SettingsRow(symbol: "bolt", title: "Turbo experiment", detail: "+5% every 5 seconds, up to 3×. Separate records.",
                                    value: turboEnabled ? "ON" : "OFF", id: "turboToggle",
                                    accessibilityLabel: turboEnabled ? "Turbo experiment: On" : "Turbo experiment: Off") { turboEnabled.toggle() }
                        SettingsRow(symbol: "rectangle.compress.vertical", title: "HUD", detail: "Compact, hidden or full. Pause stays available.",
                                    value: (HUDMode(rawValue: hudMode) ?? .compact).title.uppercased(), id: "hudMode",
                                    accessibilityLabel: "HUD: " + (HUDMode(rawValue: hudMode) ?? .compact).title) {
                            hudMode = (HUDMode(rawValue: hudMode) ?? .compact).next.rawValue
                        }
                    }
                    HStack(spacing: 12) {
                        Button("How to Play") {
                            tutorialFromPause = true
                            showingTutorial = true
                        }.accessibilityIdentifier("howToPlay")
                        Spacer()
                        Button("Restart") { scene.restartFromMenu(); resume() }.accessibilityIdentifier("restartGame")
                    }.font(.subheadline.bold()).foregroundStyle(GamePalette.mint).frame(minHeight: 44)
                    ScoringGuide()
                }
            }
        }
    }

    private func victory(_ summary: EscapeSummary) -> some View {
        GameModal {
            Image(systemName: "sun.max.fill").font(.system(size: 44)).foregroundStyle(GamePalette.gold)
            ModalHeading(eyebrow: summary.turbo ? "Turbo Escape • 150 / 150" : "Escape • 150 / 150",
                         title: "YOU ESCAPED!", subtitle: "One rope. Two heroes. All the way out.")
            Text("\(summary.points)").font(.system(size: 56, weight: .heavy, design: .rounded)).monospacedDigit()
            Text("TOTAL SCORE").font(.caption2.bold()).tracking(2).foregroundStyle(GamePalette.gold).padding(.top, -18)
            HStack(spacing: 8) {
                StatTile(label: "Time", value: EscapeProgress.timeText(summary.seconds))
                StatTile(label: "Best combo", value: "\(summary.longestCombo)")
            }
            DawnheartReward(fragmentCount: dawnheartFragments, cave: summary.cave)
            if let next = summary.cave.next {
                Button("Enter \(next.title)") {
                    start(next)
                }.buttonStyle(GameActionStyle()).accessibilityIdentifier("nextCave")
                Text("A new cave is open. Each expedition has its own records.")
                    .font(.caption).foregroundStyle(.white.opacity(0.5)).multilineTextAlignment(.center).padding(.top, -12)
            }
            Button("Keep Climbing") {
                scene.setGameplayPaused(true)
                scene.continueEndless()
                paused = true
                resume()
            }.buttonStyle(GameActionStyle(primary: summary.cave.next == nil)).accessibilityIdentifier("keepClimbing")
            Text("Continue this run in Endless. Keep your score and tempo.")
                .font(.caption).foregroundStyle(.white.opacity(0.5)).multilineTextAlignment(.center).padding(.top, -12)
            Button("Cave Map", action: returnToMap)
                .buttonStyle(GameActionStyle(primary: false)).accessibilityIdentifier("playAgain")
        }
    }

    private func defeat(_ summary: RunSummary) -> some View {
        GameModal {
            Image("HeroOrangeMiss").resizable().scaledToFit().frame(height: 90).accessibilityHidden(true)
            ModalHeading(eyebrow: (summary.turbo ? "Turbo • " : "") + (summary.endless ? "Endless" : "Escape"),
                         title: "A little tangled.", subtitle: "Same rope. Another chance.")
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(summary.height)").font(.system(size: 54, weight: .heavy, design: .rounded))
                Text(summary.endless ? "HEIGHT" : "/ 150").font(.headline).foregroundStyle(.white.opacity(0.45))
            }
            if !summary.endless {
                ProgressView(value: Double(min(summary.height, 150)), total: 150).tint(GamePalette.mint)
            }
            HStack(spacing: 8) {
                StatTile(label: "Score", value: "\(summary.points)")
                StatTile(label: "Time", value: EscapeProgress.timeText(summary.seconds))
                StatTile(label: "Best combo", value: "\(summary.longestCombo)")
            }
            Text("BEST HEIGHT \(summary.bestHeight)").font(.caption.bold()).foregroundStyle(GamePalette.gold)
            Button("Try Again") { scene.setGameplayPaused(true); scene.restartFromMenu(); paused = true; resume() }
                .buttonStyle(GameActionStyle()).accessibilityIdentifier("tryAgain")
            Button("Settings & Controls", action: pause).font(.subheadline.bold()).foregroundStyle(GamePalette.mint)
                .frame(minHeight: 44)
        }
    }

    private func pause() {
        resumeTask?.cancel()
        countdown = nil
        scene.setGameplayPaused(true)
        if !showingTutorial { paused = true }
    }

    private func resume() {
        resumeTask?.cancel()
        scene.setGameplayPaused(true)
        paused = true
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
