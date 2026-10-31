import SpriteKit

/// A cave is a complete expedition: its own visual package, records and exit.
enum CaveID: String, CaseIterable, Identifiable {
    case depths
    case crystalCavern
    case undergroundRiver
    case ancientRuins
    case volcanicPassage
    case frozenRift
    case glowrootGrotto
    case stormChasm
    case daybreakExit

    var id: String { rawValue }
    var title: String {
        switch self {
        case .depths: "The Depths"
        case .crystalCavern: "Crystal Cavern"
        case .undergroundRiver: "Underground River"
        case .ancientRuins: "Ancient Ruins"
        case .volcanicPassage: "Volcanic Passage"
        case .frozenRift: "Frozen Rift"
        case .glowrootGrotto: "Glowroot Grotto"
        case .stormChasm: "Storm Chasm"
        case .daybreakExit: "Daybreak Exit"
        }
    }
    var subtitle: String {
        switch self {
        case .depths: "Find the first way out."
        case .crystalCavern: "Follow the mineral glow."
        case .undergroundRiver: "Climb above the rushing water."
        case .ancientRuins: "Follow the forgotten torchlight."
        case .volcanicPassage: "Find a path through the ember glow."
        case .frozenRift: "Climb through the frozen silence."
        case .glowrootGrotto: "Follow the living light."
        case .stormChasm: "Ride the wind through the open void."
        case .daybreakExit: "Climb into the morning light."
        }
    }
    var platformStyle: PlatformStyle {
        switch self {
        case .depths: .depths
        case .crystalCavern: .crystal
        case .undergroundRiver: .river
        case .ancientRuins: .ruins
        case .volcanicPassage: .volcanic
        case .frozenRift: .frozen
        case .glowrootGrotto: .glowroot
        case .stormChasm: .storm
        case .daybreakExit: .daybreak
        }
    }
    var next: CaveID? {
        switch self {
        case .depths: .crystalCavern
        case .crystalCavern: .undergroundRiver
        case .undergroundRiver: .ancientRuins
        case .ancientRuins: .volcanicPassage
        case .volcanicPassage: .frozenRift
        case .frozenRift: .glowrootGrotto
        case .glowrootGrotto: .stormChasm
        case .stormChasm: .daybreakExit
        case .daybreakExit: nil
        }
    }
    var recordPrefix: String { "SlingDuo.records." + rawValue }
    var dawnheartBit: Int { 1 << (Self.allCases.firstIndex(of: self) ?? 0) }
}

enum PlatformStyle {
    case depths
    case crystal
    case river
    case ruins
    case volcanic
    case frozen
    case glowroot
    case storm
    case daybreak
}
