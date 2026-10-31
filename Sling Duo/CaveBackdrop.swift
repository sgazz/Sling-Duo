import SpriteKit

/// Existing artwork remains intact; cropping and repeating happen in texture coordinates.
final class CaveBackdrop: SKNode {
    private struct Layer {
        let node: SKNode
        let tileHeight: CGFloat
        let speed: CGFloat
    }
    private var layers: [Layer] = []

    func configure(size: CGSize, cave: CaveID = .depths) {
        removeAllChildren()
        layers.removeAll()
        if cave == .crystalCavern {
            addLayer(texture: SKTexture(imageNamed: "CrystalCavernBackdrop"), size: size,
                     height: size.height * 1.5, width: size.height,
                     speed: 0.055, alpha: 1, tint: 0)
            let foreground = SKTexture(imageNamed: "CrystalCavernForeground")
            addLayer(texture: foreground, size: size,
                     height: size.height * 1.12, width: size.width,
                     speed: 0.16, alpha: 0.82, tint: 0)
            return
        }
        if cave == .undergroundRiver {
            addLayer(texture: SKTexture(imageNamed: "UndergroundRiverBackdrop"), size: size,
                     height: size.height * 1.5, width: size.height,
                     speed: 0.05, alpha: 1, tint: 0)
            addLayer(texture: SKTexture(imageNamed: "UndergroundRiverForeground"), size: size,
                     height: size.height * 1.12, width: size.width,
                     speed: 0.15, alpha: 0.8, tint: 0)
            return
        }
        if cave == .ancientRuins {
            addLayer(texture: SKTexture(imageNamed: "AncientRuinsBackdrop"), size: size,
                     height: size.height * 1.5, width: size.height,
                     speed: 0.048, alpha: 1, tint: 0)
            addLayer(texture: SKTexture(imageNamed: "AncientRuinsForeground"), size: size,
                     height: size.height * 1.12, width: size.width,
                     speed: 0.14, alpha: 0.78, tint: 0)
            return
        }
        if cave == .volcanicPassage {
            addLayer(texture: SKTexture(imageNamed: "VolcanicPassageBackdrop"), size: size,
                     height: size.height * 1.5, width: size.height,
                     speed: 0.046, alpha: 1, tint: 0)
            addLayer(texture: SKTexture(imageNamed: "VolcanicPassageForeground"), size: size,
                     height: size.height * 1.12, width: size.width,
                     speed: 0.14, alpha: 0.78, tint: 0)
            return
        }
        if cave == .frozenRift {
            addLayer(texture: SKTexture(imageNamed: "FrozenRiftBackdrop"), size: size,
                     height: size.height * 1.5, width: size.height,
                     speed: 0.047, alpha: 1, tint: 0)
            addLayer(texture: SKTexture(imageNamed: "FrozenRiftForeground"), size: size,
                     height: size.height * 1.12, width: size.width,
                     speed: 0.14, alpha: 0.76, tint: 0)
            return
        }
        if cave == .glowrootGrotto {
            addLayer(texture: SKTexture(imageNamed: "GlowrootGrottoBackdrop"), size: size,
                     height: size.height * 1.5, width: size.height,
                     speed: 0.049, alpha: 1, tint: 0)
            addLayer(texture: SKTexture(imageNamed: "GlowrootGrottoForeground"), size: size,
                     height: size.height * 1.12, width: size.width,
                     speed: 0.145, alpha: 0.78, tint: 0)
            return
        }
        if cave == .stormChasm {
            addLayer(texture: SKTexture(imageNamed: "StormChasmBackdrop"), size: size,
                     height: size.height * 1.5, width: size.height,
                     speed: 0.052, alpha: 1, tint: 0)
            addLayer(texture: SKTexture(imageNamed: "StormChasmForeground"), size: size,
                     height: size.height * 1.12, width: size.width,
                     speed: 0.17, alpha: 0.76, tint: 0)
            return
        }
        if cave == .daybreakExit {
            addLayer(texture: SKTexture(imageNamed: "DaybreakExitBackdrop"), size: size,
                     height: size.height * 1.5, width: size.height,
                     speed: 0.042, alpha: 1, tint: 0)
            addLayer(texture: SKTexture(imageNamed: "DaybreakExitForeground"), size: size,
                     height: size.height * 1.12, width: size.width,
                     speed: 0.12, alpha: 0.72, tint: 0)
            return
        }
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
