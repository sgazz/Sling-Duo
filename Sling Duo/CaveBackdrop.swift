import SpriteKit

/// Source art is preserved in ArtSources; upright tiles have precomputed seamless edges.
final class CaveBackdrop: SKNode {
    private struct Layer {
        let node: SKNode
        let period: CGFloat
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
            addLayer(texture: textures.texture(named: "GlowrootGrottoBaseTile"), size: size, speed: 0.024, alpha: 1, tint: 0, mirrorsVertically: false)
            addLayer(texture: textures.texture(named: "GlowrootGrottoBankOverlay"), size: size, speed: 0.14, alpha: 0.88, tint: 0, mirrorsVertically: false)
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
                 speed: 0.035, alpha: 0.8, tint: 0.25)
        addLayer(texture: textures.texture(named: "CaveMid"), size: size,
                 speed: 0.09, alpha: 0.28, tint: 0.4)
        let foreground = textures.texture(named: "CaveForeground", rect: VisualManifest.region("foreground", in: "CaveForeground"))
        addLayer(texture: foreground, size: size,
                 speed: 0.18, alpha: 0.85, tint: 0.15)
    }

    /// River is deliberately assembled from independently scrolling modules.
    /// It prevents a scenic illustration's shoreline or horizon from becoming a
    /// visible seam when the player climbs beyond its original frame.
    private func configureRiverLayers(size: CGSize) {
        let cellHeight = size.height * 1.34
        addLayer(texture: textures.texture(named: "RiverWaterTile"), size: size,
                 speed: 0.028, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "RiverBankOverlay"), size: size,
                 speed: 0.145, alpha: 0.88, tint: 0, mirrorsVertically: false)
        // Props sit in front of the banks, otherwise the darker edge artwork
        // visually swallows their smaller cyan accents.
        addRiverDecorations(size: size, cellHeight: cellHeight)
    }

    private func configureCrystalLayers(size: CGSize) {
        let cellHeight = size.height * 1.34
        addLayer(texture: textures.texture(named: "CrystalCavernBaseTile"), size: size,
                 speed: 0.024, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "CrystalCavernBankOverlay"), size: size,
                 speed: 0.135, alpha: 0.88, tint: 0, mirrorsVertically: false)
        addCrystalDecorations(size: size, cellHeight: cellHeight)
    }

    private func configureRuinsLayers(size: CGSize) {
        let cellHeight = size.height * 1.34
        addLayer(texture: textures.texture(named: "AncientRuinsBaseTile"), size: size,
                 speed: 0.025, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "AncientRuinsBankOverlay"), size: size,
                 speed: 0.14, alpha: 0.88, tint: 0, mirrorsVertically: false)
        addRuinsDecorations(size: size, cellHeight: cellHeight)
    }

    private func configureVolcanicLayers(size: CGSize) {
        let cellHeight = size.height * 1.34
        addLayer(texture: textures.texture(named: "VolcanicPassageBaseTile"), size: size, speed: 0.024, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "VolcanicPassageBankOverlay"), size: size, speed: 0.145, alpha: 0.9, tint: 0, mirrorsVertically: false)
        addVolcanicDecorations(size: size, cellHeight: cellHeight)
    }

    private func configureFrozenLayers(size: CGSize) {
        let h = size.height * 1.34
        addLayer(texture: textures.texture(named: "FrozenRiftBaseTile"), size: size, speed: 0.024, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "FrozenRiftBankOverlay"), size: size, speed: 0.14, alpha: 0.88, tint: 0, mirrorsVertically: false)
        addFrozenDecorations(size: size, cellHeight: h)
    }

    private func addFrozenDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode(); group.zPosition = CGFloat(layers.count); addChild(group)
        let boulder = textures.texture(named: "FrozenRiftDecorSheet", rect: VisualManifest.region("boulder", in: "FrozenRiftDecorSheet"))
        let crystal = textures.texture(named: "FrozenRiftDecorSheet", rect: VisualManifest.region("crystal", in: "FrozenRiftDecorSheet"))
        let frost = textures.texture(named: "FrozenRiftDecorSheet", rect: VisualManifest.region("frost", in: "FrozenRiftDecorSheet"))
        let debris = textures.texture(named: "FrozenRiftDecorSheet", rect: VisualManifest.region("debris", in: "FrozenRiftDecorSheet"))
        let props: [(SKTexture, CGSize, CGFloat, CGFloat, CGFloat)] = [(boulder,CGSize(width:72,height:48),0.15,0.12,0.8),(crystal,CGSize(width:50,height:61),0.84,0.38,0.9),(frost,CGSize(width:44,height:58),0.15,0.65,0.78),(debris,CGSize(width:66,height:39),0.83,0.89,0.7),(crystal,CGSize(width:37,height:45),0.16,0.46,0.78),(boulder,CGSize(width:54,height:35),0.84,0.20,0.66),(frost,CGSize(width:32,height:43),0.82,0.74,0.72),(debris,CGSize(width:50,height:30),0.18,0.97,0.6)]
        for cell in -2...2 { for (texture, propSize, x, y, alpha) in props { let s = SKSpriteNode(texture: texture); s.size = propSize; s.position = CGPoint(x: size.width*(x - 0.5), y: CGFloat(cell)*cellHeight + cellHeight*y); s.alpha = alpha; group.addChild(s) } }
        layers.append(Layer(node: group, period: cellHeight, speed: 0.08, repeatsVertically: true))
    }

    private func addGlowrootDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode(); group.zPosition = CGFloat(layers.count); addChild(group)
        let mushrooms = textures.texture(named: "GlowrootGrottoDecorSheet", rect: VisualManifest.region("mushrooms", in: "GlowrootGrottoDecorSheet"))
        let roots = textures.texture(named: "GlowrootGrottoDecorSheet", rect: VisualManifest.region("roots", in: "GlowrootGrottoDecorSheet"))
        let boulder = textures.texture(named: "GlowrootGrottoDecorSheet", rect: VisualManifest.region("boulder", in: "GlowrootGrottoDecorSheet"))
        let spores = textures.texture(named: "GlowrootGrottoDecorSheet", rect: VisualManifest.region("spores", in: "GlowrootGrottoDecorSheet"))
        let props: [(SKTexture, CGSize, CGFloat, CGFloat, CGFloat)] = [(mushrooms,CGSize(width:60,height:56),0.15,0.12,0.94),(roots,CGSize(width:47,height:70),0.84,0.39,0.88),(boulder,CGSize(width:66,height:60),0.15,0.66,0.76),(spores,CGSize(width:42,height:56),0.83,0.90,0.9),(mushrooms,CGSize(width:44,height:41),0.84,0.21,0.82),(roots,CGSize(width:34,height:51),0.16,0.47,0.78),(spores,CGSize(width:30,height:40),0.82,0.74,0.82),(boulder,CGSize(width:48,height:44),0.18,0.97,0.6)]
        for cell in -2...2 { for (texture, propSize, x, y, alpha) in props { let s = SKSpriteNode(texture: texture); s.size = propSize; s.position = CGPoint(x: size.width*(x - 0.5), y: CGFloat(cell)*cellHeight + cellHeight*y); s.alpha = alpha; group.addChild(s) } }
        layers.append(Layer(node: group, period: cellHeight, speed: 0.08, repeatsVertically: true))
    }

    private func configureStormLayers(size: CGSize) {
        let h = size.height * 1.34
        addLayer(texture: textures.texture(named: "StormChasmBaseTile"), size: size, speed: 0.03, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "StormChasmBankOverlay"), size: size, speed: 0.16, alpha: 0.88, tint: 0, mirrorsVertically: false)
        addStormDecorations(size: size, cellHeight: h)
    }

    private func addStormDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode(); group.zPosition = CGFloat(layers.count); addChild(group)
        let boulders = textures.texture(named: "StormChasmDecorSheet", rect: VisualManifest.region("boulders", in: "StormChasmDecorSheet"))
        let lightning = textures.texture(named: "StormChasmDecorSheet", rect: VisualManifest.region("lightning", in: "StormChasmDecorSheet"))
        let mist = textures.texture(named: "StormChasmDecorSheet", rect: VisualManifest.region("mist", in: "StormChasmDecorSheet"))
        let debris = textures.texture(named: "StormChasmDecorSheet", rect: VisualManifest.region("debris", in: "StormChasmDecorSheet"))
        let props: [(SKTexture, CGSize, CGFloat, CGFloat, CGFloat)] = [(boulders,CGSize(width:70,height:52),0.15,0.12,0.82),(lightning,CGSize(width:48,height:61),0.84,0.38,0.94),(mist,CGSize(width:55,height:53),0.15,0.65,0.72),(debris,CGSize(width:65,height:48),0.83,0.89,0.80),(lightning,CGSize(width:36,height:46),0.16,0.46,0.85),(boulders,CGSize(width:50,height:37),0.84,0.20,0.68),(mist,CGSize(width:42,height:40),0.82,0.74,0.72),(debris,CGSize(width:48,height:35),0.18,0.97,0.62)]
        for cell in -2...2 { for (texture, propSize, x, y, alpha) in props { let s = SKSpriteNode(texture: texture); s.size = propSize; s.position = CGPoint(x: size.width*(x - 0.5), y: CGFloat(cell)*cellHeight + cellHeight*y); s.alpha = alpha; group.addChild(s) } }
        layers.append(Layer(node: group, period: cellHeight, speed: 0.092, repeatsVertically: true))
    }

    private func configureDaybreakLayers(size: CGSize) {
        let h = size.height * 1.34
        addLayer(texture: textures.texture(named: "DaybreakExitBaseTile"), size: size, speed: 0.022, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "DaybreakExitBankOverlay"), size: size, speed: 0.13, alpha: 0.88, tint: 0, mirrorsVertically: false)
        addDaybreakDecorations(size: size, cellHeight: h)
    }

    private func addDaybreakDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode(); group.zPosition = CGFloat(layers.count); addChild(group)
        let flowers = textures.texture(named: "DaybreakExitDecorSheet", rect: VisualManifest.region("flowers", in: "DaybreakExitDecorSheet"))
        let roots = textures.texture(named: "DaybreakExitDecorSheet", rect: VisualManifest.region("roots", in: "DaybreakExitDecorSheet"))
        let vines = textures.texture(named: "DaybreakExitDecorSheet", rect: VisualManifest.region("vines", in: "DaybreakExitDecorSheet"))
        let motes = textures.texture(named: "DaybreakExitDecorSheet", rect: VisualManifest.region("motes", in: "DaybreakExitDecorSheet"))
        let props: [(SKTexture, CGSize, CGFloat, CGFloat, CGFloat)] = [(flowers,CGSize(width:70,height:42),0.15,0.12,0.88),(roots,CGSize(width:62,height:48),0.84,0.38,0.82),(vines,CGSize(width:45,height:62),0.15,0.65,0.84),(motes,CGSize(width:42,height:48),0.83,0.89,0.92),(flowers,CGSize(width:50,height:30),0.84,0.20,0.72),(roots,CGSize(width:46,height:35),0.16,0.47,0.72),(motes,CGSize(width:32,height:37),0.82,0.74,0.88),(vines,CGSize(width:34,height:47),0.18,0.97,0.68)]
        for cell in -2...2 { for (texture, propSize, x, y, alpha) in props { let s = SKSpriteNode(texture: texture); s.size = propSize; s.position = CGPoint(x: size.width*(x - 0.5), y: CGFloat(cell)*cellHeight + cellHeight*y); s.alpha = alpha; group.addChild(s) } }
        layers.append(Layer(node: group, period: cellHeight, speed: 0.075, repeatsVertically: true))
    }

    private func addVolcanicDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode(); group.zPosition = CGFloat(layers.count); addChild(group)
        let basalt = textures.texture(named: "VolcanicPassageDecorSheet", rect: VisualManifest.region("basalt", in: "VolcanicPassageDecorSheet"))
        let obsidian = textures.texture(named: "VolcanicPassageDecorSheet", rect: VisualManifest.region("obsidian", in: "VolcanicPassageDecorSheet"))
        let embers = textures.texture(named: "VolcanicPassageDecorSheet", rect: VisualManifest.region("embers", in: "VolcanicPassageDecorSheet"))
        let lavaDebris = textures.texture(named: "VolcanicPassageDecorSheet", rect: VisualManifest.region("lavaDebris", in: "VolcanicPassageDecorSheet"))
        let props: [(SKTexture, CGSize, CGFloat, CGFloat, CGFloat)] = [(basalt,CGSize(width:72,height:44),0.15,0.12,0.8),(obsidian,CGSize(width:48,height:61),0.84,0.38,0.92),(embers,CGSize(width:42,height:64),0.15,0.65,0.82),(lavaDebris,CGSize(width:70,height:40),0.83,0.89,0.72),(obsidian,CGSize(width:36,height:46),0.16,0.46,0.78),(basalt,CGSize(width:54,height:33),0.84,0.20,0.64),(embers,CGSize(width:32,height:49),0.82,0.74,0.76),(lavaDebris,CGSize(width:52,height:30),0.18,0.97,0.6)]
        for cell in -2...2 { for (texture, propSize, x, y, alpha) in props { let sprite = SKSpriteNode(texture: texture); sprite.size = propSize; sprite.position = CGPoint(x: size.width*(x - 0.5), y: CGFloat(cell)*cellHeight + cellHeight*y); sprite.alpha = alpha; group.addChild(sprite) } }
        layers.append(Layer(node: group, period: cellHeight, speed: 0.082, repeatsVertically: true))
    }

    private func addRuinsDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode(); group.zPosition = CGFloat(layers.count); addChild(group)
        let rubble = textures.texture(named: "AncientRuinsDecorSheet", rect: VisualManifest.region("rubble", in: "AncientRuinsDecorSheet"))
        let rune = textures.texture(named: "AncientRuinsDecorSheet", rect: VisualManifest.region("rune", in: "AncientRuinsDecorSheet"))
        let vines = textures.texture(named: "AncientRuinsDecorSheet", rect: VisualManifest.region("vines", in: "AncientRuinsDecorSheet"))
        let pottery = textures.texture(named: "AncientRuinsDecorSheet", rect: VisualManifest.region("pottery", in: "AncientRuinsDecorSheet"))
        let props: [(SKTexture, CGSize, CGFloat, CGFloat, CGFloat)] = [
            (rubble, CGSize(width: 78, height: 42), 0.15, 0.12, 0.78), (rune, CGSize(width: 46, height: 58), 0.84, 0.37, 0.94),
            (vines, CGSize(width: 45, height: 74), 0.14, 0.64, 0.82), (pottery, CGSize(width: 68, height: 38), 0.83, 0.88, 0.72),
            (rubble, CGSize(width: 56, height: 30), 0.84, 0.20, 0.64), (rune, CGSize(width: 36, height: 46), 0.16, 0.47, 0.84),
            (vines, CGSize(width: 34, height: 56), 0.82, 0.73, 0.72), (pottery, CGSize(width: 52, height: 29), 0.18, 0.97, 0.60)
        ]
        for cell in -2...2 { for (texture, propSize, x, y, alpha) in props {
            let sprite = SKSpriteNode(texture: texture); sprite.size = propSize
            sprite.position = CGPoint(x: size.width * (x - 0.5), y: CGFloat(cell) * cellHeight + cellHeight * y); sprite.alpha = alpha; group.addChild(sprite)
        }}
        layers.append(Layer(node: group, period: cellHeight, speed: 0.08, repeatsVertically: true))
    }

    private func addCrystalDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode()
        group.zPosition = CGFloat(layers.count)
        addChild(group)
        let violetCluster = textures.texture(named: "CrystalCavernDecorSheet", rect: VisualManifest.region("violetCluster", in: "CrystalCavernDecorSheet"))
        let cyanCluster = textures.texture(named: "CrystalCavernDecorSheet", rect: VisualManifest.region("cyanCluster", in: "CrystalCavernDecorSheet"))
        let shards = textures.texture(named: "CrystalCavernDecorSheet", rect: VisualManifest.region("shards", in: "CrystalCavernDecorSheet"))
        let debris = textures.texture(named: "CrystalCavernDecorSheet", rect: VisualManifest.region("debris", in: "CrystalCavernDecorSheet"))
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
                sprite.position = CGPoint(x: size.width * (xFraction - 0.5),
                                          y: CGFloat(cell) * cellHeight + cellHeight * yFraction)
                sprite.alpha = alpha
                group.addChild(sprite)
            }
        }
        layers.append(Layer(node: group, period: cellHeight, speed: 0.078, repeatsVertically: true))
    }

    private func addRiverDecorations(size: CGSize, cellHeight: CGFloat) {
        let group = SKNode()
        group.zPosition = CGFloat(layers.count)
        addChild(group)

        // SpriteKit texture coordinates start at the bottom. Each crop selects
        // a separate prop family from the transparent decor sheet.
        let boulders = textures.texture(named: "RiverDecorSheet", rect: VisualManifest.region("boulders", in: "RiverDecorSheet"))
        let mushrooms = textures.texture(named: "RiverDecorSheet", rect: VisualManifest.region("mushrooms", in: "RiverDecorSheet"))
        let crystals = textures.texture(named: "RiverDecorSheet", rect: VisualManifest.region("crystals", in: "RiverDecorSheet"))
        let debris = textures.texture(named: "RiverDecorSheet", rect: VisualManifest.region("debris", in: "RiverDecorSheet"))

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
                sprite.position = CGPoint(x: size.width * (xFraction - 0.5),
                                          y: CGFloat(cell) * cellHeight + cellHeight * yFraction)
                sprite.alpha = alpha
                group.addChild(sprite)
            }
        }
        layers.append(Layer(node: group, period: cellHeight, speed: 0.085, repeatsVertically: true))
    }

    private func addLayer(texture: SKTexture, size: CGSize, speed: CGFloat, alpha: CGFloat, tint: CGFloat,
                          repeatsVertically: Bool = true, mirrorsVertically: Bool = true) {
        let group = SKNode()
        group.zPosition = CGFloat(layers.count)
        addChild(group)
        texture.filteringMode = .linear
        // Every layer scrolls. Legacy Depths alternates mirrored tiles, while
        // hand-painted biomes repeat upright so their horizon and lighting
        // direction are never shown upside down.
        // Fit the full authored width (including banks); repetition covers height.
        // A nonrepeating layer instead covers the entire viewport uniformly.
        let aspect = texture.size().width / texture.size().height
        let actualWidth = repeatsVertically ? size.width : max(size.width, size.height * aspect)
        let actualHeight = actualWidth / aspect
        let period = actualHeight * (mirrorsVertically ? 2 : 1)
        let halfViewport = size.height / (2 * actualHeight)
        let first = Int(floor(-halfViewport - 0.5))
        let last = Int(ceil(halfViewport + period / actualHeight - 0.5))
        let indices = repeatsVertically ? Array(first...last) : [0]
        for index in indices {
            let tile = SKSpriteNode(texture: texture)
            tile.size = CGSize(width: actualWidth, height: actualHeight)
            tile.position.y = CGFloat(index) * actualHeight
            tile.yScale = mirrorsVertically && !index.isMultiple(of: 2) ? -1 : 1
            tile.alpha = alpha
            tile.color = SKColor(red: 0.055, green: 0.075, blue: 0.16, alpha: 1)
            tile.colorBlendFactor = tint
            group.addChild(tile)
        }
        layers.append(Layer(node: group, period: period, speed: speed, repeatsVertically: repeatsVertically))
    }

    func update(travel: CGFloat) {
        for layer in layers {
            guard layer.repeatsVertically else { continue }
            layer.node.position.y = -(max(0, travel) * layer.speed)
                .truncatingRemainder(dividingBy: layer.period)
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
