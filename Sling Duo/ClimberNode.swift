import SpriteKit

final class ClimberNode: SKShapeNode {
    enum Hero: CaseIterable { case cyan, orange }
    enum Pose: CaseIterable { case idle, anchored, pull, flight, catchPose, miss }
    enum Expression { case calm, strained, flying, happy, dizzy }
    private let hero: Hero
    private let artwork = SKSpriteNode()
    private let artworkOutline = SKSpriteNode()
    private var anchored = false
    private(set) var pose: Pose = .idle
    private var visualTime: TimeInterval = 0
    private var beltPoint = CGPoint.zero
    private let textures: GameTextureStore

    // This point follows the artwork's belt, including lean and landing squash.
    var ropeAttachment: CGPoint {
        guard let parent else { return position }
        return artwork.convert(beltPoint, to: parent)
    }

    init(hero: Hero, textures: GameTextureStore = GameTextureStore()) {
        self.textures = textures
        self.hero = hero
        super.init()
        fillColor = hero == .cyan ? SKColor(red: 0.12, green: 0.82, blue: 0.86, alpha: 1)
            : SKColor(red: 1, green: 0.43, blue: 0.12, alpha: 1)
        strokeColor = .clear
        zPosition = 20
        artwork.name = "heroArtwork"
        artwork.anchorPoint = CGPoint(x: 0.5, y: 0)
        artworkOutline.name = "heroReadabilityOutline"
        artworkOutline.anchorPoint = CGPoint(x: 0.5, y: 0)
        artworkOutline.zPosition = -1
        artworkOutline.color = SKColor(red: 0.015, green: 0.025, blue: 0.06, alpha: 1)
        artworkOutline.colorBlendFactor = 1
        artworkOutline.alpha = 0.78
        artworkOutline.xScale = 1.12
        artworkOutline.yScale = 1.09
        artwork.addChild(artworkOutline)
        addChild(artwork)
        show(.idle)
    }

    required init?(coder: NSCoder) { fatalError("Not supported") }

    func setAnchored(_ value: Bool) {
        anchored = value
        removeAction(forKey: "landingSquash")
        zRotation = 0
        setScale(value ? 0.95 : 1)
        show(value ? .anchored : .idle)
    }

    func setFlightLean(_ tilt: CGFloat) { zRotation = tilt * 0.16 }

    func resetPersonality() {
        visualTime = 0
        artwork.removeAllActions()
        artwork.setScale(1)
        show(.idle)
    }

    func updatePersonality(_ expression: Expression, lookingAt target: CGPoint, deltaTime: TimeInterval) {
        visualTime += deltaTime
        let next: Pose
        switch expression {
        case .calm: next = anchored ? .anchored : .idle
        case .strained: next = .pull
        case .flying: next = .flight
        case .happy: next = .catchPose
        case .dizzy: next = .miss
        }
        if pose != next { show(next) }
        // Animate only the artwork; the simulation point and grab region stay fixed.
        let breath = next == .idle || next == .anchored ? sin(visualTime * 3) * 0.012 : 0
        artwork.yScale = 1 + breath
        artwork.xScale = 1 - breath * 0.4
    }

    private func show(_ next: Pose) {
        pose = next
        let frame = Self.frame(hero, next)
        let uv = CGRect(x: frame.crop.minX / frame.pixels.width,
                        y: 1 - frame.crop.maxY / frame.pixels.height,
                        width: frame.crop.width / frame.pixels.width,
                        height: frame.crop.height / frame.pixels.height)
        let texture = textures.texture(named: frame.name, rect: uv)
        // A single pixel scale per hero preserves body size across all poses.
        let scale: CGFloat = hero == .cyan ? 48 / 995 : 46 / 1028
        artwork.texture = texture
        artwork.size = CGSize(width: frame.crop.width * scale, height: frame.crop.height * scale)
        artworkOutline.texture = texture
        artworkOutline.size = artwork.size
        beltPoint = CGPoint(x: (frame.beltX - frame.crop.midX) * scale,
                            y: (frame.crop.maxY - frame.beltY) * scale)
        let grounded = next == .idle || next == .anchored || next == .catchPose
        artwork.position = CGPoint(x: -beltPoint.x, y: grounded ? -18 : -3 - beltPoint.y)
    }

    func releaseArtwork() {
        artwork.texture = nil
        artworkOutline.texture = nil
    }

    private static func frame(_ hero: Hero, _ pose: Pose) -> VisualManifest.HeroFrame {
        switch (hero, pose) {
        case (.cyan, .idle): return VisualManifest.hero("HeroCyanIdle")
        case (.cyan, .anchored): return VisualManifest.hero("HeroCyanAnchored")
        case (.cyan, .pull): return VisualManifest.hero("HeroCyanPull")
        case (.cyan, .flight): return VisualManifest.hero("HeroCyanFlight")
        case (.cyan, .catchPose): return VisualManifest.hero("HeroCyanCatch")
        case (.cyan, .miss): return VisualManifest.hero("HeroCyanMiss")
        case (.orange, .idle): return VisualManifest.hero("HeroOrangeIdle")
        case (.orange, .anchored): return VisualManifest.hero("HeroOrangeAnchored")
        case (.orange, .pull): return VisualManifest.hero("HeroOrangePull")
        case (.orange, .flight): return VisualManifest.hero("HeroOrangeFlight")
        case (.orange, .catchPose): return VisualManifest.hero("HeroOrangeCatch")
        case (.orange, .miss): return VisualManifest.hero("HeroOrangeMiss")
        }
    }
}
