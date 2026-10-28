import SpriteKit

/// Existing artwork remains intact; cropping and repeating happen in texture coordinates.
final class CaveBackdrop: SKNode {
    private struct Layer {
        let node: SKNode
        let tileHeight: CGFloat
        let speed: CGFloat
    }
    private var layers: [Layer] = []

    func configure(size: CGSize) {
        removeAllChildren()
        layers.removeAll()
        addLayer(texture: SKTexture(imageNamed: "CaveFar"), size: size,
                 height: size.height * 1.3, width: size.height * 1.3 * 2 / 3,
                 speed: 0.035, alpha: 0.8, tint: 0.25)
        addLayer(texture: SKTexture(imageNamed: "CaveMid"), size: size,
                 height: size.height * 1.45, width: size.height * 1.45 * 2 / 3,
                 speed: 0.09, alpha: 0.28, tint: 0.4)
        let foreground = SKTexture(rect: CGRect(x: 0, y: 0.18, width: 1, height: 0.64),
                                   in: SKTexture(imageNamed: "CaveForeground"))
        addLayer(texture: foreground, size: size,
                 height: size.height * 1.12, width: size.width,
                 speed: 0.18, alpha: 0.85, tint: 0.15)
    }

    private func addLayer(texture: SKTexture, size: CGSize, height: CGFloat,
                          width: CGFloat, speed: CGFloat, alpha: CGFloat, tint: CGFloat) {
        let group = SKNode()
        group.zPosition = CGFloat(layers.count)
        addChild(group)
        texture.filteringMode = .linear
        // A mirrored pair repeats every two tiles; five copies cover wrap boundaries.
        for index in -2...2 {
            let tile = SKSpriteNode(texture: texture)
            tile.size = CGSize(width: max(size.width, width), height: height)
            tile.position.y = CGFloat(index) * height
            tile.yScale = index.isMultiple(of: 2) ? 1 : -1
            tile.alpha = alpha
            tile.color = SKColor(red: 0.055, green: 0.075, blue: 0.16, alpha: 1)
            tile.colorBlendFactor = tint
            group.addChild(tile)
        }
        layers.append(Layer(node: group, tileHeight: height, speed: speed))
    }

    func update(travel: CGFloat) {
        for layer in layers {
            layer.node.position.y = -(max(0, travel) * layer.speed)
                .truncatingRemainder(dividingBy: layer.tileHeight * 2)
        }
    }

    required init?(coder: NSCoder) { fatalError("Not supported") }
    override init() { super.init() }
}
