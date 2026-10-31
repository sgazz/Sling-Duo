import SpriteKit

final class LedgeNode: SKShapeNode {
    let size: CGSize
    let isPrecisionPlatform: Bool
    private(set) var isMovingPlatform = false
    private(set) var isTrickPlatform = false
    var trickAlternative: LedgeNode?
    var reward: Int { isTrickPlatform ? 0 : (isMovingPlatform ? 2 : 1) }
    func configureTrick() {
        isTrickPlatform = true
        let badge = SKLabelNode(fontNamed: "AvenirNext-Bold")
        badge.text = "0"
        badge.fontSize = 12
        badge.fontColor = .white.withAlphaComponent(0.7)
        badge.position.y = -24
        addChild(badge)
    }
    private var motionCenter: CGFloat = 0
    private var motionTime: TimeInterval = 0
    private var motionActive = false
    private var dawnheartFragment: SKSpriteNode?

    init(center: CGPoint, size: CGSize = GameConstants.ledgeSize, isPrecision: Bool = false,
         artVariant: Int? = nil, style: PlatformStyle = .depths, usesMovingArtwork: Bool = false) {
        self.size = size
        self.isPrecisionPlatform = isPrecision
        super.init()
        position = center
        zPosition = 8
        let variants: [PlatformArtwork]
        switch style {
        case .depths: variants = isPrecision ? PlatformArtwork.precision : PlatformArtwork.normal
        // The luminous rim still distinguishes precision platforms until this
        // chapter receives its dedicated narrow-platform art set.
        case .crystal: variants = PlatformArtwork.crystal
        case .river:
            variants = usesMovingArtwork ? PlatformArtwork.riverMoving
                : (isPrecision ? PlatformArtwork.riverPrecision : PlatformArtwork.river)
        case .ruins: variants = PlatformArtwork.ruins
        case .volcanic: variants = PlatformArtwork.volcanic
        case .frozen: variants = PlatformArtwork.frozen
        case .glowroot: variants = PlatformArtwork.glowroot
        case .storm: variants = PlatformArtwork.storm
        case .daybreak: variants = PlatformArtwork.daybreak
        }
        let index = max(0, min(variants.count - 1, artVariant ?? Int.random(in: 0..<variants.count)))
        let stone = variants[index].makeSprite(width: size.width)
        stone.position.y = size.height / 2
        addChild(stone)
        setTarget(false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func markExit() {
        let light = SKNode()
        light.name = "escapeExit"
        light.zPosition = -2
        let halo = SKShapeNode(ellipseOf: CGSize(width: 154, height: 110))
        halo.fillColor = SKColor(red: 1, green: 0.9, blue: 0.56, alpha: 0.12)
        halo.strokeColor = .clear
        halo.position.y = 82
        light.addChild(halo)
        for (offset, alpha) in [(-56 as CGFloat, 0.13 as CGFloat), (0, 0.18), (56, 0.13)] {
            let beam = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: offset - 13, y: 22))
            path.addLine(to: CGPoint(x: offset + 13, y: 22))
            path.addLine(to: CGPoint(x: offset + 42, y: 150))
            path.addLine(to: CGPoint(x: offset - 42, y: 150))
            path.closeSubpath()
            beam.path = path
            beam.fillColor = SKColor(red: 1, green: 0.9, blue: 0.58, alpha: alpha)
            beam.strokeColor = .clear
            light.addChild(beam)
        }
        let opening = SKShapeNode()
        let openingPath = CGMutablePath()
        openingPath.move(to: CGPoint(x: -28, y: 15))
        openingPath.addLine(to: CGPoint(x: -28, y: 67))
        openingPath.addArc(center: CGPoint(x: 0, y: 67), radius: 28, startAngle: .pi, endAngle: 0, clockwise: true)
        openingPath.addLine(to: CGPoint(x: 28, y: 15))
        opening.path = openingPath
        opening.strokeColor = SKColor(red: 1, green: 0.9, blue: 0.58, alpha: 0.95)
        opening.lineWidth = 4
        opening.glowWidth = 8
        opening.zPosition = 1
        light.addChild(opening)
        addChild(light)
        let fragment = SKSpriteNode(imageNamed: "DawnheartFragment")
        fragment.name = "dawnheartFragment"
        fragment.size = CGSize(width: 50, height: 50)
        fragment.position = CGPoint(x: 0, y: 100)
        fragment.zPosition = 4
        fragment.texture?.filteringMode = .linear
        addChild(fragment)
        dawnheartFragment = fragment
        fragment.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 7, duration: 0.85),
            .moveBy(x: 0, y: -7, duration: 0.85)
        ])), withKey: "dawnheartHover")
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "DAYLIGHT"
        label.fontSize = 11
        label.position.y = 143
        label.fontColor = SKColor(red: 1, green: 0.91, blue: 0.63, alpha: 1)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 2
        addChild(label)
    }

    func collectDawnheartFragment() {
        guard let fragment = dawnheartFragment else { return }
        dawnheartFragment = nil
        fragment.removeAction(forKey: "dawnheartHover")
        let gather = SKAction.group([
            .move(to: CGPoint(x: 0, y: 48), duration: 0.32),
            .scale(to: 1.28, duration: 0.32),
            .rotate(byAngle: .pi * 1.5, duration: 0.32)
        ])
        let vanish = SKAction.group([.scale(to: 0.05, duration: 0.18), .fadeOut(withDuration: 0.18)])
        fragment.run(.sequence([gather, vanish, .removeFromParent()]))
    }

    func configureMotion() {
        isMovingPlatform = true
        motionCenter = position.x
        let badge = SKLabelNode(fontNamed: "AvenirNext-Bold")
        badge.name = "movingBadge"
        badge.text = "↔ 2×"
        badge.fontSize = 12
        badge.fontColor = .systemYellow
        badge.position.y = -24
        addChild(badge)
    }

    func advanceMotion(_ dt: TimeInterval) {
        guard motionActive else { return }
        motionTime += dt
        position.x = motionCenter + sin(motionTime * .pi / 2) * 18
    }

    var topY: CGFloat { position.y + size.height / 2 }
    var grabPoint: CGPoint { CGPoint(x: position.x, y: topY + GameConstants.climberRadius) }

    func canGrab(climberPosition: CGPoint, velocity: CGVector) -> Bool {
        canGrab(from: climberPosition, to: climberPosition, velocity: velocity)
    }

    // Intersect the full movement segment with the forgiving grab rectangle.
    // Endpoint-only checks can skip a platform on a fast descending jump.
    func canGrab(from start: CGPoint, to end: CGPoint, velocity: CGVector) -> Bool {
        grabContact(from: start, to: end, velocity: velocity) != nil
    }

    func grabContact(from start: CGPoint, to end: CGPoint, velocity: CGVector) -> CGPoint? {
        guard velocity.dy < 170 else { return nil }
        let halfWidth = size.width * 0.55
        let bounds = CGRect(x: position.x - halfWidth,
                            y: grabPoint.y - GameConstants.grabDistance,
                            width: halfWidth * 2, height: GameConstants.grabDistance * 2)
        let movement = end - start
        var entry: CGFloat = 0
        var exit: CGFloat = 1
        for (origin, delta, lower, upper) in [
            (start.x, movement.dx, bounds.minX, bounds.maxX),
            (start.y, movement.dy, bounds.minY, bounds.maxY)
        ] {
            if abs(delta) < 0.000001 {
                guard origin >= lower && origin <= upper else { return nil }
            } else {
                let first = (lower - origin) / delta
                let second = (upper - origin) / delta
                entry = max(entry, min(first, second))
                exit = min(exit, max(first, second))
                if entry > exit { return nil }
            }
        }
        return start + movement * entry
    }

    func setTarget(_ targeted: Bool) {
        motionActive = targeted && isMovingPlatform
        removeAction(forKey: "targetPulse")
        if isMovingPlatform {
            strokeColor = .systemYellow
        } else if isPrecisionPlatform {
            strokeColor = SKColor(red: 1, green: 0.78, blue: 0.42, alpha: 1)
        } else {
            strokeColor = targeted
                ? SKColor(red: 0.39, green: 0.96, blue: 0.8, alpha: 1)
                : SKColor(red: 0.64, green: 0.74, blue: 0.98, alpha: 1)
        }
    }

}
