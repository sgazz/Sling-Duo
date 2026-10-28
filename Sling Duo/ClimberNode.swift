import SpriteKit

final class ClimberNode: SKShapeNode {
    enum Hero: CaseIterable { case cyan, orange }
    enum Pose: CaseIterable { case idle, anchored, pull, flight, catchPose, miss }
    enum Expression { case calm, strained, flying, happy, dizzy }
    private struct Frame {
        let name: String
        let pixels: CGSize
        let crop: CGRect
        let beltY: CGFloat
    }
    private let hero: Hero
    private let artwork = SKSpriteNode()
    private var anchored = false
    private(set) var pose: Pose = .idle
    private var visualTime: TimeInterval = 0
    private var beltPoint = CGPoint.zero
    private static var textures: [String: SKTexture] = [:]

    // This point follows the artwork's belt, including lean and landing squash.
    var ropeAttachment: CGPoint {
        guard let parent else { return position }
        return artwork.convert(beltPoint, to: parent)
    }

    init(hero: Hero) {
        self.hero = hero
        super.init()
        fillColor = hero == .cyan ? SKColor(red: 0.12, green: 0.82, blue: 0.86, alpha: 1)
            : SKColor(red: 1, green: 0.43, blue: 0.12, alpha: 1)
        strokeColor = .clear
        zPosition = 20
        artwork.name = "heroArtwork"
        artwork.anchorPoint = CGPoint(x: 0.5, y: 0)
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
        let texture: SKTexture
        if let cached = Self.textures[frame.name] { texture = cached }
        else {
            let full = SKTexture(imageNamed: frame.name)
            let uv = CGRect(x: frame.crop.minX / frame.pixels.width,
                            y: 1 - frame.crop.maxY / frame.pixels.height,
                            width: frame.crop.width / frame.pixels.width,
                            height: frame.crop.height / frame.pixels.height)
            texture = SKTexture(rect: uv, in: full)
            texture.filteringMode = .linear
            Self.textures[frame.name] = texture
        }
        // A single pixel scale per hero preserves body size across all poses.
        let scale: CGFloat = hero == .cyan ? 48 / 995 : 46 / 1028
        artwork.texture = texture
        artwork.size = CGSize(width: frame.crop.width * scale, height: frame.crop.height * scale)
        beltPoint = CGPoint(x: (frame.pixels.width / 2 - frame.crop.midX) * scale,
                            y: (frame.crop.maxY - frame.beltY) * scale)
        let grounded = next == .idle || next == .anchored || next == .catchPose
        artwork.position = CGPoint(x: -beltPoint.x, y: grounded ? -18 : -3 - beltPoint.y)
    }

    private static func frame(_ hero: Hero, _ pose: Pose) -> Frame {
        switch (hero, pose) {
        case (.cyan, .idle): return Frame(name: "HeroCyanIdle", pixels: CGSize(width: 1282, height: 1227), crop: CGRect(x: 88, y: 135, width: 1101, height: 1003), beltY: 790)
        case (.cyan, .anchored): return Frame(name: "HeroCyanAnchored", pixels: CGSize(width: 1282, height: 1227), crop: CGRect(x: 139, y: 134, width: 1006, height: 1002), beltY: 850)
        case (.cyan, .pull): return Frame(name: "HeroCyanPull", pixels: CGSize(width: 1282, height: 1227), crop: CGRect(x: 79, y: 102, width: 1129, height: 1049), beltY: 750)
        case (.cyan, .flight): return Frame(name: "HeroCyanFlight", pixels: CGSize(width: 1282, height: 1227), crop: CGRect(x: 68, y: 125, width: 1155, height: 1016), beltY: 790)
        case (.cyan, .catchPose): return Frame(name: "HeroCyanCatch", pixels: CGSize(width: 1282, height: 1227), crop: CGRect(x: 40, y: 182, width: 1213, height: 953), beltY: 730)
        case (.cyan, .miss): return Frame(name: "HeroCyanMiss", pixels: CGSize(width: 1282, height: 1227), crop: CGRect(x: 94, y: 162, width: 1152, height: 929), beltY: 790)
        case (.orange, .idle): return Frame(name: "HeroOrangeIdle", pixels: CGSize(width: 1311, height: 1200), crop: CGRect(x: 74, y: 77, width: 1163, height: 1036), beltY: 780)
        case (.orange, .anchored): return Frame(name: "HeroOrangeAnchored", pixels: CGSize(width: 1312, height: 1199), crop: CGRect(x: 85, y: 71, width: 1148, height: 1047), beltY: 790)
        case (.orange, .pull): return Frame(name: "HeroOrangePull", pixels: CGSize(width: 1311, height: 1200), crop: CGRect(x: 57, y: 73, width: 1200, height: 1017), beltY: 760)
        case (.orange, .flight): return Frame(name: "HeroOrangeFlight", pixels: CGSize(width: 1311, height: 1200), crop: CGRect(x: 62, y: 73, width: 1209, height: 1044), beltY: 780)
        case (.orange, .catchPose): return Frame(name: "HeroOrangeCatch", pixels: CGSize(width: 1311, height: 1200), crop: CGRect(x: 20, y: 96, width: 1279, height: 995), beltY: 750)
        case (.orange, .miss): return Frame(name: "HeroOrangeMiss", pixels: CGSize(width: 1311, height: 1200), crop: CGRect(x: 68, y: 86, width: 1202, height: 1037), beltY: 770)
        }
    }
}
