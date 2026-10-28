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

    private static let textures = Dictionary(uniqueKeysWithValues: (normal + precision).map { art in
        (art.name, SKTexture(imageNamed: art.name))
    })

    func makeSprite(width: CGFloat) -> SKSpriteNode {
        let crop = body.insetBy(dx: -8, dy: -8)
        let uv = CGRect(x: crop.minX / pixels.width, y: (pixels.height - crop.maxY) / pixels.height,
                        width: crop.width / pixels.width, height: crop.height / pixels.height)
        let texture = SKTexture(rect: uv, in: Self.textures[name]!)
        texture.filteringMode = .linear
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
