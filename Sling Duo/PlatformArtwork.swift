import SpriteKit

/// Original cutouts stay intact. UV bounds discard empty canvas and align the
/// visible stone width and landing surface with the gameplay dimensions.
struct PlatformArtwork {
    let name: String
    let pixels: CGSize
    let body: CGRect

    init(name: String) {
        self.name = name
        let entry = VisualManifest.entry(name)
        pixels = entry.pixels
        body = entry.cropRect
    }

    static let normal: [PlatformArtwork] = [
        .init(name: "PlatformNormal01"),
        .init(name: "PlatformNormal02"),
        .init(name: "PlatformNormal03")
    ]
    static let precision: [PlatformArtwork] = [
        .init(name: "PlatformPrecision01"),
        .init(name: "PlatformPrecision02"),
        .init(name: "PlatformPrecision03")
    ]
    static let crystal: [PlatformArtwork] = [
        .init(name: "CrystalPlatformNormal01")
    ]
    static let river: [PlatformArtwork] = [
        .init(name: "RiverPlatformNormal01")
    ]
    static let riverPrecision: [PlatformArtwork] = [
        .init(name: "RiverPlatformPrecision01")
    ]
    static let riverMoving: [PlatformArtwork] = [
        .init(name: "RiverPlatformMoving01")
    ]
    static let ruins: [PlatformArtwork] = [
        .init(name: "RuinsPlatformNormal01")
    ]
    static let volcanic: [PlatformArtwork] = [
        .init(name: "VolcanicPlatformNormal01")
    ]
    static let frozen: [PlatformArtwork] = [
        .init(name: "FrozenPlatformNormal01")
    ]
    static let glowroot: [PlatformArtwork] = [
        .init(name: "GlowrootPlatformNormal01")
    ]
    static let storm: [PlatformArtwork] = [
        .init(name: "StormPlatformNormal01")
    ]
    static let daybreak: [PlatformArtwork] = [
        .init(name: "DaybreakPlatformNormal01")
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
        let landingY = VisualManifest.entry(name).landingLine! * pixels.height
        sprite.anchorPoint = CGPoint(x: (VisualManifest.entry(name).pivot![0] * pixels.width - crop.minX) / crop.width,
                                     y: (crop.maxY - landingY) / crop.height)
        return sprite
    }
}
