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
    private let targetRim = SKShapeNode()

    init(center: CGPoint, size: CGSize = GameConstants.ledgeSize, isPrecision: Bool = false, artVariant: Int? = nil) {
        self.size = size
        self.isPrecisionPlatform = isPrecision
        super.init()
        position = center
        zPosition = 8
        let variants = isPrecision ? PlatformArtwork.precision : PlatformArtwork.normal
        let index = max(0, min(variants.count - 1, artVariant ?? Int.random(in: 0..<variants.count)))
        let stone = variants[index].makeSprite(width: size.width)
        stone.position.y = size.height / 2
        addChild(stone)
        let rim = CGMutablePath()
        rim.move(to: CGPoint(x: -size.width * 0.43, y: size.height / 2 - 1))
        rim.addLine(to: CGPoint(x: size.width * 0.43, y: size.height / 2 - 1))
        targetRim.path = rim
        targetRim.lineCap = .round
        targetRim.lineWidth = 1.5
        targetRim.zPosition = 1
        addChild(targetRim)
        setTarget(false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        childNode(withName: "targetMarker")?.removeFromParent()
        if isMovingPlatform {
            strokeColor = .systemYellow
        } else if isPrecisionPlatform {
            strokeColor = SKColor(red: 1, green: 0.78, blue: 0.42, alpha: 1)
        } else {
            strokeColor = targeted
                ? SKColor(red: 0.39, green: 0.96, blue: 0.8, alpha: 1)
                : SKColor(red: 0.64, green: 0.74, blue: 0.98, alpha: 1)
        }
        targetRim.strokeColor = strokeColor
        targetRim.glowWidth = targeted ? 2 : 0
        targetRim.alpha = targeted ? 0.9 : (isPrecisionPlatform ? 0.35 : 0)
        guard targeted else { return }
        let marker = SKShapeNode()
        let arrow = CGMutablePath()
        arrow.move(to: CGPoint(x: -5, y: 5))
        arrow.addLine(to: .zero)
        arrow.addLine(to: CGPoint(x: 5, y: 5))
        marker.path = arrow
        marker.name = "targetMarker"
        marker.strokeColor = strokeColor
        marker.lineWidth = 2.5
        marker.lineCap = .round
        marker.position = CGPoint(x: 0, y: size.height / 2 + 43)
        addChild(marker)
        marker.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: -5, duration: 0.5),
            .moveBy(x: 0, y: 5, duration: 0.5)
        ])))
    }

}
