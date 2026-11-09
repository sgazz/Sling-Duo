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
    @State private var caveLoadTask: Task<Void, Never>?
    @State private var loadingCave: CaveID?
    @State private var selectedCave: CaveID?
    @State private var showingCaveMap = false
    @State private var paused = false
    @State private var showingTutorial = false
    @State private var tutorialFromPause = false
    @State private var introPresented = false

    private var dawnheartFragments: Int { dawnheartFragmentMask.nonzeroBitCount }

    var body: some View {
        Group {
            if !introPresented {
                IntroStoryView { introPresented = true; didSeeStory = true }
            } else if selectedCave == nil || showingCaveMap {
                CaveMapView(crystalUnlocked: crystalCavernUnlocked, riverUnlocked: undergroundRiverUnlocked,
                            ruinsUnlocked: ancientRuinsUnlocked, volcanicUnlocked: volcanicPassageUnlocked,
                            frozenUnlocked: frozenRiftUnlocked, glowrootUnlocked: glowrootGrottoUnlocked,
                            stormUnlocked: stormChasmUnlocked, daybreakUnlocked: daybreakExitUnlocked,
                            fragmentMask: dawnheartFragmentMask, select: start,
                            back: selectedCave == nil ? nil : { backToPause() })
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
        .overlay {
            if loadingCave != nil {
                ZStack {
                    GamePalette.ink.ignoresSafeArea()
                    ProgressView("Preparing cave…").tint(GamePalette.mint).foregroundStyle(.white)
                }
                .accessibilityIdentifier("caveLoading")
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
        .onDisappear { caveLoadTask?.cancel() }
    }

    private func configure() {
        scene.turboEnabled = turboEnabled
        scene.soundEnabled = soundEnabled
        scene.steeringMode = SteeringMode(rawValue: steeringMode) ?? .tilt
        #if GRAPHICS_PROFILE
        didSeeStory = true
        didSeeTutorial = true
        introPresented = true
        selectedCave = .depths
        scene.setGameplayPaused(false)
        #endif
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        let launchesGameplayForTest = environment["SLINGDUO_SKIP_ONBOARDING"] == "1"
            || environment["SLINGDUO_SHOW_ONBOARDING"] == "1"
            || environment["SLINGDUO_ESCAPE_UI_TEST"] == "1"
            || environment["SLINGDUO_UI_SCREEN"] != nil
        if selectedCave == nil, launchesGameplayForTest {
            didSeeStory = true
            introPresented = true
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
        caveLoadTask?.cancel()
        scene.setGameplayPaused(true)
        // Drop old nodes before dropping their texture ownership.
        scene.releaseCaveResources()
        loadingCave = cave
        caveLoadTask = Task { @MainActor in
            await scene.preloadCave(cave)
            guard !Task.isCancelled else { return }
            scene.turboEnabled = turboEnabled
            scene.soundEnabled = soundEnabled
            scene.steeringMode = SteeringMode(rawValue: steeringMode) ?? .tilt
            scene.selectCave(cave)
            selectedCave = cave
            showingCaveMap = false
            loadingCave = nil
            if !didSeeTutorial {
                tutorialFromPause = false
                showingTutorial = true
            } else {
                paused = true
                resume()
            }
        }
    }

    private func returnToMap() {
        caveLoadTask?.cancel()
        loadingCave = nil
        scene.setGameplayPaused(true)
        paused = true
        showingTutorial = false
        showingCaveMap = true
    }

    private func backToPause() {
        showingCaveMap = false
        pause()
    }

    private var pauseOverlay: some View {
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
                SettingsRow(symbol: "rectangle.compress.vertical", title: "HUD", detail: "Compact, hidden or full. Pause stays available.",
                            value: (HUDMode(rawValue: hudMode) ?? .compact).title.uppercased(), id: "hudMode",
                            accessibilityLabel: "HUD: " + (HUDMode(rawValue: hudMode) ?? .compact).title) {
                    hudMode = (HUDMode(rawValue: hudMode) ?? .compact).next.rawValue
                }
            }
            HStack(spacing: 12) {
                Button("Cave Map", action: returnToMap)
                    .accessibilityIdentifier("leaveToCaveMap")
                Button("Restart") { scene.restartFromMenu(); resume() }
                    .accessibilityIdentifier("restartGame")
            }
            .buttonStyle(GameActionStyle(primary: false))
            Button("How to Play") {
                tutorialFromPause = true
                showingTutorial = true
            }
            .font(.headline)
            .foregroundStyle(GamePalette.mint)
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityIdentifier("howToPlay")
            ScoringGuide()
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
                Text("The way to the next cave is now open. Each expedition has its own records.")
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
            Image("HeroOrangeMissIllustration").resizable().scaledToFit().frame(height: 90).accessibilityHidden(true)
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
        scene.setGameplayPaused(true)
        if !showingTutorial { paused = true }
    }

    private func resume() {
        guard phase == .active else { return }
        paused = false
        scene.setGameplayPaused(false)
    }
}
