import SwiftUI

enum HUDMode: String, CaseIterable {
    case compact, hidden, expanded
    var title: String {
        switch self {
        case .compact: return "Compact"
        case .hidden: return "Hidden"
        case .expanded: return "Full"
        }
    }
    var next: HUDMode {
        switch self {
        case .compact: return .hidden
        case .hidden: return .expanded
        case .expanded: return .compact
        }
    }
}

struct GameHUDState: Equatable {
    var height = 0
    var points = 0
    var streak = 0
    var best = 0
    var newBest = false
    var endless = false
    var turbo = false
    var tempo = 1.0
    var seconds = 0
    var remaining: Double?
    var instruction = "Pull a hero to launch"
    var chapter: String { height < 50 ? "The Depths" : (height < 100 ? "The Climb" : "Daylight Ahead") }
}

struct RunSummary {
    let height: Int
    let points: Int
    let seconds: TimeInterval
    let longestCombo: Int
    let turbo: Bool
    let endless: Bool
    let bestHeight: Int
}

enum GamePalette {
    static let ink = Color(red: 0.045, green: 0.075, blue: 0.115)
    static let panel = Color(red: 0.065, green: 0.105, blue: 0.15)
    static let mint = Color(red: 0.30, green: 0.94, blue: 0.80)
    static let gold = Color(red: 1, green: 0.79, blue: 0.36)
    static let coral = Color(red: 1, green: 0.43, blue: 0.35)
}

struct GameActionStyle: ButtonStyle {
    var primary = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .bold))
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(primary ? GamePalette.ink : .white)
            .background(primary ? GamePalette.mint : Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(primary ? 0 : 0.12)))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

struct GameModal<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GamePalette.ink.opacity(0.78).ignoresSafeArea()
                ScrollView {
                    VStack {
                        Spacer(minLength: 16)
                        VStack(spacing: 22) { content }
                            .padding(24)
                            .frame(maxWidth: 430)
                            .background(GamePalette.panel, in: RoundedRectangle(cornerRadius: 28))
                            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(.white.opacity(0.12)))
                            .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
                            .padding(.horizontal, 16)
                        Spacer(minLength: 16)
                    }
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
                .scrollIndicators(.hidden)
            }
        }
        .foregroundStyle(.white)
        .accessibilityAddTraits(.isModal)
    }
}

struct ModalHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 8) {
            Text(eyebrow.uppercased()).font(.caption2.bold()).tracking(2).foregroundStyle(GamePalette.mint)
            Text(title).font(.system(.largeTitle, design: .rounded, weight: .heavy)).minimumScaleFactor(0.75).multilineTextAlignment(.center)
            Text(subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.65)).multilineTextAlignment(.center)
        }
    }
}

struct StatTile: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 6) {
            Text(value).font(.system(.title2, design: .rounded, weight: .bold)).monospacedDigit().minimumScaleFactor(0.7).lineLimit(1)
            Text(label.uppercased()).font(.system(size: 10, weight: .bold)).tracking(1).foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct GameHUDOverlay: View {
    let mode: HUDMode
    let state: GameHUDState
    let soundEnabled: Bool
    let pause: () -> Void
    let toggleSound: () -> Void
    var body: some View {
        Group {
            if mode == .expanded { expandedHUD }
            else { minimalHUD }
        }
    }

    private var minimalHUD: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 8) {
                if mode == .compact {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(state.height)").font(.system(.title3, design: .rounded, weight: .heavy))
                            .foregroundStyle(GamePalette.mint).accessibilityIdentifier("heightValue")
                        if !state.endless { Text("/150").font(.caption).foregroundStyle(.white.opacity(0.5)) }
                        Text("·").foregroundStyle(.white.opacity(0.3)).padding(.horizontal, 3)
                        Text("\(state.points) pts").font(.subheadline.bold()).accessibilityIdentifier("scoreValue")
                        if state.turbo {
                            Text(String(format: "×%.2f", state.tempo)).font(.caption2.bold()).foregroundStyle(GamePalette.gold)
                        }
                    }
                    .lineLimit(1).minimumScaleFactor(0.7).monospacedDigit()
                    .allowsHitTesting(false)
                    Spacer(minLength: 4)
                    control(soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                            label: soundEnabled ? "Mute sound" : "Enable sound", id: "soundToggle", action: toggleSound)
                } else { Spacer() }
                control("pause.fill", label: "Pause game", id: "pauseGame", action: pause)
            }
            .padding(.leading, mode == .compact ? 14 : 0)
            .padding(.trailing, 4).padding(.vertical, 4)
            .background(mode == .compact ? GamePalette.ink.opacity(0.88) : .clear, in: Capsule())
            if let remaining = state.remaining {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                    Text(state.instruction).font(.caption.bold())
                    Text(String(format: "%.1fs", remaining)).font(.subheadline.bold()).monospacedDigit()
                        .accessibilityIdentifier("rescueTime")
                }
                .foregroundStyle(remaining <= 1 ? GamePalette.coral : GamePalette.gold)
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(GamePalette.ink.opacity(0.92), in: Capsule())
                .allowsHitTesting(false)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.top, 4)
        .frame(maxWidth: 560).frame(maxWidth: .infinity).foregroundStyle(.white)
    }

    private var expandedHUD: some View {
        ZStack(alignment: .topTrailing) {
            hudContent.allowsHitTesting(false)
            HStack(spacing: 8) {
                control("pause.fill", label: "Pause game", id: "pauseGame", action: pause)
                control(soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                        label: soundEnabled ? "Mute sound" : "Enable sound", id: "soundToggle", action: toggleSound)
            }
            .padding(.trailing, 30).padding(.top, 18)
        }
        .frame(maxWidth: 560).frame(maxWidth: .infinity).foregroundStyle(.white)
    }

    private var hudContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(state.endless ? "ENDLESS" : "ESCAPE").font(.caption2.bold()).tracking(2).foregroundStyle(GamePalette.mint)
                        Text(state.chapter).font(.system(.subheadline, design: .rounded, weight: .bold))
                    }
                    Spacer()
                    Color.clear.frame(width: 96, height: 44)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text("\(state.height)").font(.system(size: 32, weight: .heavy, design: .rounded)).monospacedDigit()
                        .accessibilityIdentifier("heightValue")
                    Text(state.endless ? "HEIGHT" : "/ 150").font(.subheadline.bold()).foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("SCORE \(state.points)").font(.system(.headline, design: .rounded, weight: .bold)).monospacedDigit()
                            .accessibilityIdentifier("scoreValue")
                        Text(state.newBest ? "NEW BEST · \(state.best)" : "BEST HEIGHT \(state.best)").font(.system(size: 10, weight: .bold)).foregroundStyle(state.newBest ? GamePalette.gold : .white.opacity(0.45))
                    }
                }
                if !state.endless {
                    ProgressView(value: Double(min(state.height, 150)), total: 150).tint(GamePalette.mint)
                        .accessibilityLabel("Escape progress").accessibilityValue("\(state.height) of 150 platforms")
                }
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("COMBO").font(.system(size: 9, weight: .bold)).foregroundStyle(.white.opacity(0.55))
                        ForEach(0..<5) { index in
                            Capsule().fill(index < state.streak % 5 ? GamePalette.gold : .white.opacity(0.12))
                                .frame(width: 10, height: 4)
                        }
                        if state.streak >= 5 { Text("\(state.streak)").font(.caption2.bold()).foregroundStyle(GamePalette.gold) }
                    }
                    .accessibilityElement(children: .ignore).accessibilityLabel("Combo streak \(state.streak)")
                    Spacer()
                    if state.turbo {
                        Label(String(format: "×%.2f", state.tempo), systemImage: "bolt.fill")
                            .font(.caption2.bold()).foregroundStyle(GamePalette.gold)
                    }
                    Text(EscapeProgress.timeText(Double(state.seconds))).font(.caption2).monospacedDigit().foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(14)
            .background(GamePalette.ink.opacity(0.92), in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.09)))
            Spacer(minLength: 0)
            bottomPrompt.padding(.bottom, 64).allowsHitTesting(false)
        }
        .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 12)
    }

    @ViewBuilder private var bottomPrompt: some View {
        if let remaining = state.remaining {
            let urgent = remaining <= 1
            VStack(spacing: 10) {
                HStack {
                    Label(state.instruction, systemImage: "timer").font(.subheadline.bold())
                    Spacer(minLength: 8)
                    Text(String(format: "%.1fs", remaining)).font(.system(.title2, design: .rounded, weight: .heavy)).monospacedDigit()
                        .accessibilityIdentifier("rescueTime")
                }
                ProgressView(value: max(0, remaining), total: JumpTuning.rescueDuration)
                    .tint(urgent ? GamePalette.coral : GamePalette.gold)
                Text("Catch a platform before time runs out.").font(.caption).foregroundStyle(.white.opacity(0.65))
            }
            .foregroundStyle(urgent ? GamePalette.coral : GamePalette.gold)
            .padding(16)
            .background(GamePalette.ink.opacity(0.95), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder((urgent ? GamePalette.coral : GamePalette.gold).opacity(0.5)))
        } else {
            Label(state.instruction, systemImage: state.height == 0 ? "hand.draw.fill" : "arrow.left.and.right")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(.vertical, 12).padding(.horizontal, 18)
                .background(GamePalette.ink.opacity(0.85), in: Capsule())
        }
    }

    private func control(_ symbol: String, label: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 15, weight: .bold))
                .frame(width: 44, height: 44).background(.white.opacity(0.07), in: Circle())
        }.buttonStyle(.plain).accessibilityLabel(label).accessibilityIdentifier(id)
    }
}

struct SettingsRow: View {
    let symbol: String
    let title: String
    let detail: String
    let value: String
    let id: String
    let accessibilityLabel: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.headline).foregroundStyle(GamePalette.mint).frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.subheadline.bold()).foregroundStyle(.white)
                    Text(detail).font(.caption).foregroundStyle(.white.opacity(0.5)).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)
                Text(value).font(.caption.bold()).foregroundStyle(GamePalette.gold)
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.35))
            }
            .padding(12)
            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel).accessibilityIdentifier(id)
    }
}

struct HowToPlayView: View {
    @Binding var steeringMode: String
    let returning: Bool
    let done: () -> Void
    var body: some View {
        GameModal {
            HStack(spacing: -12) {
                Image("HeroCyanIdle").resizable().scaledToFit().frame(width: 95, height: 95)
                Image("HeroOrangeIdle").resizable().scaledToFit().frame(width: 95, height: 95)
            }.accessibilityHidden(true)
            ModalHeading(eyebrow: "Sling Duo", title: "Better together.", subtitle: "Two heroes. One rope. Find your way out.")
            VStack(spacing: 16) {
                lesson("1", title: "Pull. Release. Fly.", detail: "Drag a hero to stretch the rope, then let go.")
                lesson("2", title: "Find your rhythm.", detail: "Steer in the air. Each catch launches your partner.")
                lesson("3", title: "Four seconds to save it.", detail: "The clock runs through your pull and flight. A catch refills it.")
            }
            HStack(spacing: 8) {
                modeButton("Tilt", symbol: "iphone.gen3.radiowaves.left.and.right", mode: "tilt")
                modeButton("Slide", symbol: "hand.draw", mode: "slide")
            }
            Text(steeringMode == "tilt" ? "Tilt gently left or right. Your launch angle sets neutral." : "During flight, touch and slide left or right. Lift your finger to brake.")
                .font(.caption).foregroundStyle(.white.opacity(0.55)).multilineTextAlignment(.center)
            Button(returning ? "Back to Pause" : "Let's Climb", action: done)
                .buttonStyle(GameActionStyle()).accessibilityIdentifier("finishTutorial")
        }
    }
    private func lesson(_ number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number).font(.caption.bold()).foregroundStyle(GamePalette.ink)
                .frame(width: 24, height: 24).background(GamePalette.mint, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.caption).foregroundStyle(.white.opacity(0.6)).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
    private func modeButton(_ title: String, symbol: String, mode: String) -> some View {
        Button { steeringMode = mode } label: {
            Label(title, systemImage: symbol).font(.subheadline.bold()).frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(steeringMode == mode ? GamePalette.ink : .white)
                .background(steeringMode == mode ? GamePalette.mint : .white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain).accessibilityIdentifier("tutorial" + title)
    }
}

struct ScoringGuide: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("MAKE EACH CATCH COUNT").font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(GamePalette.mint)
            Text("PERFECT  +1 for the center of a platform\nCOMBO  +2 every five catches without a miss\n↔ 2×  Moving platform, double base points\n0  Trick platform, no points; breaks combo")
                .font(.caption).foregroundStyle(.white.opacity(0.55)).lineSpacing(5).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
