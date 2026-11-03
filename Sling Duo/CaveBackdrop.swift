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
            addLayer(texture: textures.texture(named: "GlowrootGrottoBaseTile"), size: size, speed: 0.024, alpha: 1, tint: 0, mirrorsVertically: false)
            addLayer(texture: textures.texture(named: "GlowrootGrottoBankOverlay"), size: size, speed: 0.14, alpha: 1, tint: 0, mirrorsVertically: false)
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
        addLayer(texture: textures.texture(named: "RiverWaterTile"), size: size,
                 speed: 0.028, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "RiverBankOverlay"), size: size,
                 speed: 0.145, alpha: 1, tint: 0, mirrorsVertically: false)
    }

    private func configureCrystalLayers(size: CGSize) {
        addLayer(texture: textures.texture(named: "CrystalCavernBaseTile"), size: size,
                 speed: 0.024, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "CrystalCavernBankOverlay"), size: size,
                 speed: 0.135, alpha: 1, tint: 0, mirrorsVertically: false)
    }

    private func configureRuinsLayers(size: CGSize) {
        addLayer(texture: textures.texture(named: "AncientRuinsBaseTile"), size: size,
                 speed: 0.025, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "AncientRuinsBankOverlay"), size: size,
                 speed: 0.14, alpha: 1, tint: 0, mirrorsVertically: false)
    }

    private func configureVolcanicLayers(size: CGSize) {
        addLayer(texture: textures.texture(named: "VolcanicPassageBaseTile"), size: size, speed: 0.024, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "VolcanicPassageBankOverlay"), size: size, speed: 0.145, alpha: 1, tint: 0, mirrorsVertically: false)
    }

    private func configureFrozenLayers(size: CGSize) {
        addLayer(texture: textures.texture(named: "FrozenRiftBaseTile"), size: size, speed: 0.024, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "FrozenRiftBankOverlay"), size: size, speed: 0.14, alpha: 1, tint: 0, mirrorsVertically: false)
    }

    private func configureStormLayers(size: CGSize) {
        addLayer(texture: textures.texture(named: "StormChasmBaseTile"), size: size, speed: 0.03, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "StormChasmBankOverlay"), size: size, speed: 0.16, alpha: 1, tint: 0, mirrorsVertically: false)
    }

    private func configureDaybreakLayers(size: CGSize) {
        addLayer(texture: textures.texture(named: "DaybreakExitBaseTile"), size: size, speed: 0.022, alpha: 1, tint: 0, mirrorsVertically: false)
        addLayer(texture: textures.texture(named: "DaybreakExitBankOverlay"), size: size, speed: 0.13, alpha: 1, tint: 0, mirrorsVertically: false)
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
