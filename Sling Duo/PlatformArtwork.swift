import SpriteKit

/// Original cutouts stay intact. UV bounds discard empty canvas and align the
/// visible stone width and landing surface with the gameplay dimensions.
struct PlatformArtwork {
    let name: String
    let pixels: CGSize
    let body: CGRect

    static let normal: [PlatformArtwork] = [
        .init(name: "PlatformNormal01", pixels: CGSize(width: 1983, height: 793), body: CGRect(x: 173, y: 210, width: 1638, height: 436)),
        .init(name: "PlatformNormal02", pixels: CGSize(width: 1774, height: 887), body: CGRect(x: 91, y: 277, width: 1593, height: 478)),
        .init(name: "PlatformNormal03", pixels: CGSize(width: 1774, height: 887), body: CGRect(x: 141, y: 275, width: 1492, height: 479))
    ]
    static let precision: [PlatformArtwork] = [
        .init(name: "PlatformPrecision01", pixels: CGSize(width: 1774, height: 887), body: CGRect(x: 276, y: 304, width: 1218, height: 413)),
        .init(name: "PlatformPrecision02", pixels: CGSize(width: 1774, height: 887), body: CGRect(x: 358, y: 326, width: 1058, height: 377)),
        .init(name: "PlatformPrecision03", pixels: CGSize(width: 1774, height: 887), body: CGRect(x: 59, y: 248, width: 1655, height: 465))
    ]
    static let crystal: [PlatformArtwork] = [
        .init(name: "CrystalPlatformNormal01", pixels: CGSize(width: 1774, height: 887),
              body: CGRect(x: 42, y: 305, width: 1690, height: 360))
    ]
    static let river: [PlatformArtwork] = [
        .init(name: "RiverPlatformNormal01", pixels: CGSize(width: 1983, height: 793),
              body: CGRect(x: 22, y: 220, width: 1938, height: 410))
    ]
    static let riverPrecision: [PlatformArtwork] = [
        .init(name: "RiverPlatformPrecision01", pixels: CGSize(width: 1983, height: 793),
              body: CGRect(x: 400, y: 225, width: 1160, height: 355))
    ]
    static let riverMoving: [PlatformArtwork] = [
        .init(name: "RiverPlatformMoving01", pixels: CGSize(width: 1983, height: 793),
              body: CGRect(x: 158, y: 190, width: 1670, height: 425))
    ]
    static let ruins: [PlatformArtwork] = [
        .init(name: "RuinsPlatformNormal01", pixels: CGSize(width: 1774, height: 887),
              body: CGRect(x: 25, y: 270, width: 1724, height: 440))
    ]
    static let volcanic: [PlatformArtwork] = [
        .init(name: "VolcanicPlatformNormal01", pixels: CGSize(width: 1792, height: 1024),
              body: CGRect(x: 30, y: 315, width: 1730, height: 420))
    ]
    static let frozen: [PlatformArtwork] = [
        .init(name: "FrozenPlatformNormal01", pixels: CGSize(width: 2048, height: 768),
              body: CGRect(x: 32, y: 105, width: 1984, height: 560))
    ]
    static let glowroot: [PlatformArtwork] = [
        .init(name: "GlowrootPlatformNormal01", pixels: CGSize(width: 1920, height: 819),
              body: CGRect(x: 32, y: 160, width: 1856, height: 470))
    ]
    static let storm: [PlatformArtwork] = [
        .init(name: "StormPlatformNormal01", pixels: CGSize(width: 2172, height: 724),
              body: CGRect(x: 32, y: 115, width: 2108, height: 470))
    ]
    static let daybreak: [PlatformArtwork] = [
        .init(name: "DaybreakPlatformNormal01", pixels: CGSize(width: 2172, height: 724),
              body: CGRect(x: 32, y: 115, width: 2108, height: 470))
    ]

    static func names(for style: PlatformStyle) -> [String] {
        let artwork: [PlatformArtwork]
        switch style {
        case .depths: artwork = normal + precision
        case .crystal: artwork = crystal
        case .river: artwork = river + riverPrecision + riverMoving
        case .ruins: artwork = ruins
        case .volcanic: artwork = volcanic
        case .frozen: artwork = frozen
        case .glowroot: artwork = glowroot
        case .storm: artwork = storm
        case .daybreak: artwork = daybreak
        }
        return artwork.map(\.name)
    }

    func makeSprite(width: CGFloat, textures: GameTextureStore = GameTextureStore()) -> SKSpriteNode {
        // Geometry remains in master-image coordinates; normalized UVs and pivots
        // are identical for the downsampled runtime canvas.
        let crop = body.insetBy(dx: -8, dy: -8)
        let uv = CGRect(x: crop.minX / pixels.width, y: (pixels.height - crop.maxY) / pixels.height,
                        width: crop.width / pixels.width, height: crop.height / pixels.height)
        let texture = textures.texture(named: name, rect: uv)
        let sprite = SKSpriteNode(texture: texture)
        sprite.name = "platformArtwork"
        let scale = width / body.width
        sprite.size = CGSize(width: crop.width * scale, height: crop.height * scale)
        // The feet sit slightly below the logical grab plane; this pins that
        // plane inside the shallow visible top face rather than above the rock.
        let landingY = body.minY + body.height * 0.30
        sprite.anchorPoint = CGPoint(x: (body.midX - crop.minX) / crop.width,
                                     y: (crop.maxY - landingY) / crop.height)
        return sprite
    }
}
