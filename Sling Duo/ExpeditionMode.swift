import SwiftUI

enum ExpeditionMode: String {
    case climb
    case descent
}

struct ExpeditionModeView: View {
    let select: (ExpeditionMode) -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [GamePalette.ink, Color(red: 0.09, green: 0.12, blue: 0.22)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                Text("SLING DUO").font(.caption.bold()).tracking(4).foregroundStyle(GamePalette.mint)
                Text("Choose your route").font(.system(.largeTitle, design: .rounded, weight: .heavy))
                Text("Same sling. A new direction.").font(.subheadline).foregroundStyle(.white.opacity(0.62))
                VStack(spacing: 14) {
                    modeButton(.climb, title: "Climb the caves", detail: "Reach the light above.", icon: "arrow.up")
                    modeButton(.descent, title: "Descend the caves", detail: "Prototype route to the depths.", icon: "arrow.down")
                }.padding(.top, 16)
                Spacer()
            }.padding(24).foregroundStyle(.white).frame(maxWidth: 520)
        }
        .accessibilityIdentifier("expeditionMode")
    }

    private func modeButton(_ mode: ExpeditionMode, title: String, detail: String, icon: String) -> some View {
        Button { select(mode) } label: {
            HStack(spacing: 16) {
                Image(systemName: icon).font(.title2.bold()).frame(width: 54, height: 54)
                    .background(GamePalette.mint.opacity(0.14), in: Circle()).foregroundStyle(GamePalette.mint)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(.title3, design: .rounded, weight: .heavy))
                    Text(detail).font(.caption).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.45))
            }.padding(18).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
        }.buttonStyle(.plain).accessibilityIdentifier("mode.\(mode.rawValue)")
    }
}
