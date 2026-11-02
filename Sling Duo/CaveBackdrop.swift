import SpriteKit

/// Existing artwork remains intact; cropping and repeating happen in texture coordinates.
final class CaveBackdrop: SKNode {
    private struct Layer {
        let node: SKNode
        let tileHeight: CGFloat
        let speed: CGFloat
        let repeatsVertically: Bool
    }
    private var layers: [Layer] = []
    private let textures: GameTextureStore

    func configure(size: CGSize, cave: CaveID = .depths) {
        removeAllChildren()
        layers.removeAll()
        if cave == .crystalCavern {
            configureCrystalLayers(size: size)
            return
        }
        if cave == .undergroundRiver {
            configureRiverLayers(size: size)
            return
        }
        if cave == .ancientRuins {
            configureRuinsLayers(size: size)
            return
        }
        if cave == .volcanicPassage {
            configureVolcanicLayers(size: size)
            return
        }
        if cave == .frozenRift {
            configureFrozenLayers(size: size)
            return
        }
        if cave == .glowrootGrotto {
            let h = size.height * 1.34
            addLayer(texture: textures.texture(named: "GlowrootGrottoBaseTile"), size: size, height: h, width: size.width, speed: 0.024, alpha: 1, tint: 0, mirrorsVertically: false)
            addLayer(texture: textures.texture(named: "GlowrootGrottoBankOverlay"), size: size, height: h, width: size.width, speed: 0.14, alpha: 0.88, tint: 0, mirrorsVertically: false)
            addGlowrootDecorations(size: size, cellHeight: h)
            return
        }
        if cave == .stormChasm {
            configureStormLayers(size: size)
            return
        }
        if cave == .daybreakExit {
            configureDaybreakLayers(size: size)
            return
        }
        addLayer(texture: textures.texture(named: "CaveFar"), size: size,
                 height: size.height * 1.3, width: size.height * 1.3 * 2 / 3,
                 speed: 0.035, alpha: 0.8, tint: 0.25)
        addLayer(texture: textures.texture(named: "CaveMid"), size: size,
                 height: size.height * 1.45, width: size.height * 1.45 * 2 / 3,
                 speed: 0.09, alpha: 0.28, tint: 0.4)
        let foreground = SKTexture(rect: CGRect(x: 0, y: 0.18, width: 1, height: 0.64),
                                   in: textures.texture(named: "CaveForeground"))
        addLayer(texture: foreground, size: size,
                 height: size.height * 1.12, width: size.width,
                 speed: 0.18, alpha: 0.85, tint: 0.15)
    }

    /// River is deliberately assembled from independently scrolling modules.
    /// It prevents a scenic illustration's shoreline or horizon from becoming a
    /// visible seam when the player climbs beyond its original frame.
    private func configureRiverLayers(size: CGSize) {
        let cellHeight = size.height * 1.34
        addLayer(texture: textures.texture(named: "RiverWaterTile"), size: size,
                 height: cellHeight, width: size.width,
                 speed: 0.028, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "RiverBankOverlay"), size: size,
                 height: cellHeight, width: size.width,
                 speed: 0.145, alpha: 0.88, tint: 0, mirrorsVertically: false)
        // Props sit in front of the banks, otherwise the darker edge artwork
        // visually swallows their smaller cyan accents.
        addRiverDecorations(size: size, cellHeight: cellHeight)
    }

    private func configureCrystalLayers(size: CGSize) {
        let cellHeight = size.height * 1.34
        addLayer(texture: textures.texture(named: "CrystalCavernBaseTile"), size: size,
                 height: cellHeight, width: size.width,
                 speed: 0.024, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "CrystalCavernBankOverlay"), size: size,
                 height: cellHeight, width: size.width,
                 speed: 0.135, alpha: 0.88, tint: 0, mirrorsVertically: false)
        addCrystalDecorations(size: size, cellHeight: cellHeight)
    }

    private func configureRuinsLayers(size: CGSize) {
        let cellHeight = size.height * 1.34
        addLayer(texture: textures.texture(named: "AncientRuinsBaseTile"), size: size,
                 height: cellHeight, width: size.width, speed: 0.025, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "AncientRuinsBankOverlay"), size: size,
                 height: cellHeight, width: size.width, speed: 0.14, alpha: 0.88, tint: 0, mirrorsVertically: false)
        addRuinsDecorations(size: size, cellHeight: cellHeight)
    }

    private func configureVolcanicLayers(size: CGSize) {
        let cellHeight = size.height * 1.34
        addLayer(texture: textures.texture(named: "VolcanicPassageBaseTile"), size: size, height: cellHeight, width: size.width, speed: 0.024, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "VolcanicPassageBankOverlay"), size: size, height: cellHeight, width: size.width, speed: 0.145, alpha: 0.9, tint: 0, mirrorsVertically: false)
        addVolcanicDecorations(size: size, cellHeight: cellHeight)
    }

    private func configureFrozenLayers(size: CGSize) {
        let h = size.height * 1.34
        addLayer(texture: textures.texture(named: "FrozenRiftBaseTile"), size: size, height: h, width: size.width, speed: 0.024, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "FrozenRiftBankOverlay"), size: size, height: h, width: size.width, speed: 0.14, alpha: 0.88, tint: 0, mirrorsVertically: false)
        addFrozenDecorations(size: size, cellHeight: h)
    }

    private func addFrozenDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode(); group.zPosition = CGFloat(layers.count); addChild(group)
        let sheet = textures.texture(named: "FrozenRiftDecorSheet"); sheet.filteringMode = .linear
        let boulder = SKTexture(rect: CGRect(x: 0.02, y: 0.69, width: 0.46, height: 0.28), in: sheet)
        let crystal = SKTexture(rect: CGRect(x: 0.52, y: 0.69, width: 0.46, height: 0.28), in: sheet)
        let frost = SKTexture(rect: CGRect(x: 0.02, y: 0.34, width: 0.46, height: 0.29), in: sheet)
        let debris = SKTexture(rect: CGRect(x: 0.52, y: 0.03, width: 0.46, height: 0.28), in: sheet)
        let props: [(SKTexture, CGSize, CGFloat, CGFloat, CGFloat)] = [(boulder,CGSize(width:72,height:48),0.15,0.12,0.8),(crystal,CGSize(width:50,height:61),0.84,0.38,0.9),(frost,CGSize(width:44,height:58),0.15,0.65,0.78),(debris,CGSize(width:66,height:39),0.83,0.89,0.7),(crystal,CGSize(width:37,height:45),0.16,0.46,0.78),(boulder,CGSize(width:54,height:35),0.84,0.20,0.66),(frost,CGSize(width:32,height:43),0.82,0.74,0.72),(debris,CGSize(width:50,height:30),0.18,0.97,0.6)]
        for cell in -2...2 { for (texture, propSize, x, y, alpha) in props { let s = SKSpriteNode(texture: texture); s.size = propSize; s.position = CGPoint(x: size.width*x, y: CGFloat(cell)*cellHeight + cellHeight*y); s.alpha = alpha; group.addChild(s) } }
        layers.append(Layer(node: group, tileHeight: cellHeight, speed: 0.08, repeatsVertically: true))
    }

    private func addGlowrootDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode(); group.zPosition = CGFloat(layers.count); addChild(group)
        let sheet = textures.texture(named: "GlowrootGrottoDecorSheet"); sheet.filteringMode = .linear
        let mushrooms = SKTexture(rect: CGRect(x: 0.02, y: 0.68, width: 0.46, height: 0.29), in: sheet)
        let roots = SKTexture(rect: CGRect(x: 0.52, y: 0.68, width: 0.46, height: 0.29), in: sheet)
        let boulder = SKTexture(rect: CGRect(x: 0.02, y: 0.02, width: 0.46, height: 0.59), in: sheet)
        let spores = SKTexture(rect: CGRect(x: 0.52, y: 0.02, width: 0.46, height: 0.59), in: sheet)
        let props: [(SKTexture, CGSize, CGFloat, CGFloat, CGFloat)] = [(mushrooms,CGSize(width:60,height:56),0.15,0.12,0.94),(roots,CGSize(width:47,height:70),0.84,0.39,0.88),(boulder,CGSize(width:66,height:60),0.15,0.66,0.76),(spores,CGSize(width:42,height:56),0.83,0.90,0.9),(mushrooms,CGSize(width:44,height:41),0.84,0.21,0.82),(roots,CGSize(width:34,height:51),0.16,0.47,0.78),(spores,CGSize(width:30,height:40),0.82,0.74,0.82),(boulder,CGSize(width:48,height:44),0.18,0.97,0.6)]
        for cell in -2...2 { for (texture, propSize, x, y, alpha) in props { let s = SKSpriteNode(texture: texture); s.size = propSize; s.position = CGPoint(x: size.width*x, y: CGFloat(cell)*cellHeight + cellHeight*y); s.alpha = alpha; group.addChild(s) } }
        layers.append(Layer(node: group, tileHeight: cellHeight, speed: 0.08, repeatsVertically: true))
    }

    private func configureStormLayers(size: CGSize) {
        let h = size.height * 1.34
        addLayer(texture: textures.texture(named: "StormChasmBaseTile"), size: size, height: h, width: size.width, speed: 0.03, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "StormChasmBankOverlay"), size: size, height: h, width: size.width, speed: 0.16, alpha: 0.88, tint: 0, mirrorsVertically: false)
        addStormDecorations(size: size, cellHeight: h)
    }

    private func addStormDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode(); group.zPosition = CGFloat(layers.count); addChild(group)
        let sheet = textures.texture(named: "StormChasmDecorSheet"); sheet.filteringMode = .linear
        let boulders = SKTexture(rect: CGRect(x: 0.02, y: 0.69, width: 0.46, height: 0.28), in: sheet)
        let lightning = SKTexture(rect: CGRect(x: 0.52, y: 0.69, width: 0.46, height: 0.28), in: sheet)
        let mist = SKTexture(rect: CGRect(x: 0.02, y: 0.34, width: 0.46, height: 0.29), in: sheet)
        let debris = SKTexture(rect: CGRect(x: 0.52, y: 0.03, width: 0.46, height: 0.28), in: sheet)
        let props: [(SKTexture, CGSize, CGFloat, CGFloat, CGFloat)] = [(boulders,CGSize(width:70,height:52),0.15,0.12,0.82),(lightning,CGSize(width:48,height:61),0.84,0.38,0.94),(mist,CGSize(width:55,height:53),0.15,0.65,0.72),(debris,CGSize(width:65,height:48),0.83,0.89,0.80),(lightning,CGSize(width:36,height:46),0.16,0.46,0.85),(boulders,CGSize(width:50,height:37),0.84,0.20,0.68),(mist,CGSize(width:42,height:40),0.82,0.74,0.72),(debris,CGSize(width:48,height:35),0.18,0.97,0.62)]
        for cell in -2...2 { for (texture, propSize, x, y, alpha) in props { let s = SKSpriteNode(texture: texture); s.size = propSize; s.position = CGPoint(x: size.width*x, y: CGFloat(cell)*cellHeight + cellHeight*y); s.alpha = alpha; group.addChild(s) } }
        layers.append(Layer(node: group, tileHeight: cellHeight, speed: 0.092, repeatsVertically: true))
    }

    private func configureDaybreakLayers(size: CGSize) {
        let h = size.height * 1.34
        addLayer(texture: textures.texture(named: "DaybreakExitBaseTile"), size: size, height: h, width: size.width, speed: 0.022, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "DaybreakExitBankOverlay"), size: size, height: h, width: size.width, speed: 0.13, alpha: 0.88, tint: 0, mirrorsVertically: false)
        addDaybreakDecorations(size: size, cellHeight: h)
    }

    private func addDaybreakDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode(); group.zPosition = CGFloat(layers.count); addChild(group)
        let sheet = textures.texture(named: "DaybreakExitDecorSheet"); sheet.filteringMode = .linear
        let flowers = SKTexture(rect: CGRect(x: 0.02, y: 0.69, width: 0.96, height: 0.28), in: sheet)
        let roots = SKTexture(rect: CGRect(x: 0.02, y: 0.36, width: 0.96, height: 0.28), in: sheet)
        let vines = SKTexture(rect: CGRect(x: 0.02, y: 0.02, width: 0.46, height: 0.29), in: sheet)
        let motes = SKTexture(rect: CGRect(x: 0.52, y: 0.02, width: 0.46, height: 0.29), in: sheet)
        let props: [(SKTexture, CGSize, CGFloat, CGFloat, CGFloat)] = [(flowers,CGSize(width:70,height:42),0.15,0.12,0.88),(roots,CGSize(width:62,height:48),0.84,0.38,0.82),(vines,CGSize(width:45,height:62),0.15,0.65,0.84),(motes,CGSize(width:42,height:48),0.83,0.89,0.92),(flowers,CGSize(width:50,height:30),0.84,0.20,0.72),(roots,CGSize(width:46,height:35),0.16,0.47,0.72),(motes,CGSize(width:32,height:37),0.82,0.74,0.88),(vines,CGSize(width:34,height:47),0.18,0.97,0.68)]
        for cell in -2...2 { for (texture, propSize, x, y, alpha) in props { let s = SKSpriteNode(texture: texture); s.size = propSize; s.position = CGPoint(x: size.width*x, y: CGFloat(cell)*cellHeight + cellHeight*y); s.alpha = alpha; group.addChild(s) } }
        layers.append(Layer(node: group, tileHeight: cellHeight, speed: 0.075, repeatsVertically: true))
    }

    private func addVolcanicDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode(); group.zPosition = CGFloat(layers.count); addChild(group)
        let sheet = textures.texture(named: "VolcanicPassageDecorSheet"); sheet.filteringMode = .linear
        let basalt = SKTexture(rect: CGRect(x: 0.02, y: 0.69, width: 0.46, height: 0.28), in: sheet)
        let obsidian = SKTexture(rect: CGRect(x: 0.52, y: 0.69, width: 0.46, height: 0.28), in: sheet)
        let embers = SKTexture(rect: CGRect(x: 0.02, y: 0.34, width: 0.46, height: 0.29), in: sheet)
        let lavaDebris = SKTexture(rect: CGRect(x: 0.52, y: 0.03, width: 0.46, height: 0.28), in: sheet)
        let props: [(SKTexture, CGSize, CGFloat, CGFloat, CGFloat)] = [(basalt,CGSize(width:72,height:44),0.15,0.12,0.8),(obsidian,CGSize(width:48,height:61),0.84,0.38,0.92),(embers,CGSize(width:42,height:64),0.15,0.65,0.82),(lavaDebris,CGSize(width:70,height:40),0.83,0.89,0.72),(obsidian,CGSize(width:36,height:46),0.16,0.46,0.78),(basalt,CGSize(width:54,height:33),0.84,0.20,0.64),(embers,CGSize(width:32,height:49),0.82,0.74,0.76),(lavaDebris,CGSize(width:52,height:30),0.18,0.97,0.6)]
        for cell in -2...2 { for (texture, propSize, x, y, alpha) in props { let sprite = SKSpriteNode(texture: texture); sprite.size = propSize; sprite.position = CGPoint(x: size.width*x, y: CGFloat(cell)*cellHeight + cellHeight*y); sprite.alpha = alpha; group.addChild(sprite) } }
        layers.append(Layer(node: group, tileHeight: cellHeight, speed: 0.082, repeatsVertically: true))
    }

    private func addRuinsDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode(); group.zPosition = CGFloat(layers.count); addChild(group)
        let sheet = textures.texture(named: "AncientRuinsDecorSheet"); sheet.filteringMode = .linear
        let rubble = SKTexture(rect: CGRect(x: 0.02, y: 0.69, width: 0.96, height: 0.28), in: sheet)
        let rune = SKTexture(rect: CGRect(x: 0.02, y: 0.35, width: 0.46, height: 0.29), in: sheet)
        let vines = SKTexture(rect: CGRect(x: 0.52, y: 0.34, width: 0.45, height: 0.30), in: sheet)
        let pottery = SKTexture(rect: CGRect(x: 0.02, y: 0.02, width: 0.96, height: 0.27), in: sheet)
        let props: [(SKTexture, CGSize, CGFloat, CGFloat, CGFloat)] = [
            (rubble, CGSize(width: 78, height: 42), 0.15, 0.12, 0.78), (rune, CGSize(width: 46, height: 58), 0.84, 0.37, 0.94),
            (vines, CGSize(width: 45, height: 74), 0.14, 0.64, 0.82), (pottery, CGSize(width: 68, height: 38), 0.83, 0.88, 0.72),
            (rubble, CGSize(width: 56, height: 30), 0.84, 0.20, 0.64), (rune, CGSize(width: 36, height: 46), 0.16, 0.47, 0.84),
            (vines, CGSize(width: 34, height: 56), 0.82, 0.73, 0.72), (pottery, CGSize(width: 52, height: 29), 0.18, 0.97, 0.60)
        ]
        for cell in -2...2 { for (texture, propSize, x, y, alpha) in props {
            let sprite = SKSpriteNode(texture: texture); sprite.size = propSize
            sprite.position = CGPoint(x: size.width * x, y: CGFloat(cell) * cellHeight + cellHeight * y); sprite.alpha = alpha; group.addChild(sprite)
        }}
        layers.append(Layer(node: group, tileHeight: cellHeight, speed: 0.08, repeatsVertically: true))
    }

    private func addCrystalDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode()
        group.zPosition = CGFloat(layers.count)
        addChild(group)
        let sheet = textures.texture(named: "CrystalCavernDecorSheet")
        sheet.filteringMode = .linear
        let violetCluster = SKTexture(rect: CGRect(x: 0.02, y: 0.69, width: 0.46, height: 0.28), in: sheet)
        let cyanCluster = SKTexture(rect: CGRect(x: 0.51, y: 0.69, width: 0.46, height: 0.28), in: sheet)
        let shards = SKTexture(rect: CGRect(x: 0.02, y: 0.32, width: 0.46, height: 0.30), in: sheet)
        let debris = SKTexture(rect: CGRect(x: 0.51, y: 0.03, width: 0.46, height: 0.27), in: sheet)
        let props: [(SKTexture, CGSize, CGFloat, CGFloat, CGFloat)] = [
            (violetCluster, CGSize(width: 56, height: 58), 0.15, 0.12, 0.82),
            (cyanCluster, CGSize(width: 58, height: 62), 0.84, 0.37, 0.90),
            (shards, CGSize(width: 44, height: 58), 0.15, 0.61, 0.88),
            (debris, CGSize(width: 66, height: 38), 0.83, 0.86, 0.68),
            (cyanCluster, CGSize(width: 42, height: 46), 0.84, 0.19, 0.72),
            (violetCluster, CGSize(width: 44, height: 46), 0.16, 0.45, 0.78),
            (shards, CGSize(width: 34, height: 46), 0.82, 0.72, 0.80),
            (debris, CGSize(width: 54, height: 31), 0.18, 0.96, 0.60)
        ]
        for cell in -2...2 {
            for (texture, propSize, xFraction, yFraction, alpha) in props {
                let sprite = SKSpriteNode(texture: texture)
                sprite.size = propSize
                sprite.position = CGPoint(x: size.width * xFraction,
                                          y: CGFloat(cell) * cellHeight + cellHeight * yFraction)
                sprite.alpha = alpha
                group.addChild(sprite)
            }
        }
        layers.append(Layer(node: group, tileHeight: cellHeight, speed: 0.078, repeatsVertically: true))
    }

    private func addRiverDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode()
        group.zPosition = CGFloat(layers.count)
        addChild(group)

        let sheet = textures.texture(named: "RiverDecorSheet")
        sheet.filteringMode = .linear
        // SpriteKit texture coordinates start at the bottom. Each crop selects
        // a separate prop family from the transparent decor sheet.
        let boulders = SKTexture(rect: CGRect(x: 0.02, y: 0.74, width: 0.96, height: 0.24), in: sheet)
        let mushrooms = SKTexture(rect: CGRect(x: 0.38, y: 0.47, width: 0.58, height: 0.26), in: sheet)
        let crystals = SKTexture(rect: CGRect(x: 0.05, y: 0.23, width: 0.59, height: 0.28), in: sheet)
        let debris = SKTexture(rect: CGRect(x: 0.02, y: 0.01, width: 0.96, height: 0.20), in: sheet)

        let props: [(SKTexture, CGSize, CGFloat, CGFloat, CGFloat)] = [
            (boulders, CGSize(width: 82, height: 39), 0.15, 0.12, 0.78),
            (mushrooms, CGSize(width: 62, height: 45), 0.84, 0.40, 0.96),
            (crystals, CGSize(width: 52, height: 72), 0.14, 0.66, 0.90),
            (debris, CGSize(width: 86, height: 30), 0.82, 0.90, 0.72),
            (boulders, CGSize(width: 62, height: 30), 0.83, 0.22, 0.68),
            (mushrooms, CGSize(width: 48, height: 35), 0.16, 0.47, 0.88),
            (crystals, CGSize(width: 40, height: 56), 0.82, 0.74, 0.84),
            (debris, CGSize(width: 66, height: 23), 0.18, 0.96, 0.62)
        ]
        for cell in -2...2 {
            for (texture, propSize, xFraction, yFraction, alpha) in props {
                let sprite = SKSpriteNode(texture: texture)
                sprite.size = propSize
                sprite.position = CGPoint(x: size.width * xFraction,
                                          y: CGFloat(cell) * cellHeight + cellHeight * yFraction)
                sprite.alpha = alpha
                group.addChild(sprite)
            }
        }
        layers.append(Layer(node: group, tileHeight: cellHeight, speed: 0.085, repeatsVertically: true))
    }

    private func addLayer(texture: SKTexture, size: CGSize, height: CGFloat,
                          width: CGFloat, speed: CGFloat, alpha: CGFloat, tint: CGFloat,
                          repeatsVertically: Bool = true, mirrorsVertically: Bool = true) {
        let group = SKNode()
        group.zPosition = CGFloat(layers.count)
        addChild(group)
        texture.filteringMode = .linear
        // Every layer scrolls. Legacy Depths alternates mirrored tiles, while
        // hand-painted biomes repeat upright so their horizon and lighting
        // direction are never shown upside down.
        let indices = repeatsVertically ? Array(-2...2) : [0]
        for index in indices {
            let tile = SKSpriteNode(texture: texture)
            tile.size = CGSize(width: max(size.width, width), height: height)
            tile.position.y = CGFloat(index) * height
            tile.yScale = mirrorsVertically && !index.isMultiple(of: 2) ? -1 : 1
            tile.alpha = alpha
            tile.color = SKColor(red: 0.055, green: 0.075, blue: 0.16, alpha: 1)
            tile.colorBlendFactor = tint
            group.addChild(tile)
        }
        layers.append(Layer(node: group, tileHeight: height, speed: speed, repeatsVertically: repeatsVertically))
    }

    func update(travel: CGFloat) {
        for layer in layers {
            guard layer.repeatsVertically else { continue }
            layer.node.position.y = -(max(0, travel) * layer.speed)
                .truncatingRemainder(dividingBy: layer.tileHeight * 2)
        }
    }

    required init?(coder: NSCoder) { fatalError("Not supported") }
    init(textures: GameTextureStore = GameTextureStore()) {
        self.textures = textures
        super.init()
    }

    func releaseLayers() {
        removeAllChildren()
        layers.removeAll()
    }
}
