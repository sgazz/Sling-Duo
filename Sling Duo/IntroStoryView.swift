import SwiftUI

/// A compact, skippable opening comic. The characters are the exact gameplay
/// sprites so the story establishes the duo the player will immediately use.
struct IntroStoryView: View {
    private struct Panel {
        let eyebrow: String
        let title: String
        let line: String
        let orangePose: String
        let cyanPose: String
        let showsDawnheart: Bool
    }

    private let panels: [Panel] = [
        .init(eyebrow: "MORNING IN THE VALLEY", title: "A signal below.",
              line: "Beyond the camp, an old cave has started to glow.",
              orangePose: "HeroOrangeIdle", cyanPose: "HeroCyanIdle", showsDawnheart: false),
        .init(eyebrow: "THE OLD MAP", title: "The Dawnheart is missing.",
              line: "Its fragments are scattered somewhere beneath the mountain.",
              orangePose: "HeroOrangePull", cyanPose: "HeroCyanAnchored", showsDawnheart: true),
        .init(eyebrow: "ONE WAY FORWARD", title: "Follow the light.",
              line: "Each cave holds a fragment — and a path to the next.",
              orangePose: "HeroOrangeCatch", cyanPose: "HeroCyanCatch", showsDawnheart: true),
        .init(eyebrow: "THE DUO", title: "Then we go down. Together.",
              line: "Pull, launch, catch — and bring the dawn back home.",
              orangePose: "HeroOrangeFlight", cyanPose: "HeroCyanFlight", showsDawnheart: false)
    ]

    let finish: () -> Void
    @State private var page = 0
    @State private var breathing = false

    private var panel: Panel { panels[page] }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image("IntroCampBackdrop")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .scaleEffect(breathing ? 1.06 : 1)
                    .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: breathing)
                    .clipped()

                LinearGradient(colors: [.black.opacity(0.12), .black.opacity(0.06), GamePalette.ink.opacity(0.88)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Button("Skip") { finish() }
                            .font(.caption.bold()).foregroundStyle(.white.opacity(0.82))
                            .padding(.horizontal, 15).padding(.vertical, 9)
                            .background(.black.opacity(0.28), in: Capsule())
                            .accessibilityIdentifier("skipStory")
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(panels.indices, id: \.self) { index in
                                Capsule().fill(index == page ? GamePalette.gold : .white.opacity(0.35))
                                    .frame(width: index == page ? 20 : 7, height: 7)
                            }
                        }
                    }
                    .padding(.horizontal, 22).padding(.top, 22)

                    Spacer()

                    ZStack(alignment: .bottom) {
                        if panel.showsDawnheart { dawnheart }
                        HStack(spacing: -12) {
                            hero(panel.orangePose, offset: page == 3 ? 18 : 0)
                            hero(panel.cyanPose, offset: page == 3 ? -18 : 0)
                        }
                    }
                    .frame(height: min(235, proxy.size.height * 0.29))

                    VStack(spacing: 10) {
                        Text(panel.eyebrow).font(.caption2.bold()).tracking(2.2).foregroundStyle(GamePalette.gold)
                        Text(panel.title).font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .multilineTextAlignment(.center).minimumScaleFactor(0.75)
                        Text(panel.line).font(.subheadline).foregroundStyle(.white.opacity(0.72))
                            .multilineTextAlignment(.center).frame(maxWidth: 360)
                    }
                    .padding(.horizontal, 26).padding(.top, 18)

                    Button(page == panels.count - 1 ? "Begin the climb" : "Continue") {
                        if page == panels.count - 1 { finish() }
                        else { withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) { page += 1 } }
                    }
                    .buttonStyle(GameActionStyle())
                    .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 28)
                    .accessibilityIdentifier("storyContinue")
                }
            }
            .foregroundStyle(.white)
        }
        .onAppear { breathing = true }
    }

    private func hero(_ image: String, offset: CGFloat) -> some View {
        Image(image).resizable().scaledToFit().frame(width: 132, height: 150)
            .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
            .offset(x: offset)
    }

    private var dawnheart: some View {
        ZStack {
            Circle().fill(GamePalette.gold.opacity(0.16)).frame(width: 116, height: 116).blur(radius: 14)
            Circle().stroke(GamePalette.gold, lineWidth: 3).frame(width: 54, height: 54)
            Image(systemName: "sparkles").font(.title2.bold()).foregroundStyle(GamePalette.gold)
        }
        .offset(y: -80)
        .transition(.scale.combined(with: .opacity))
    }
}
