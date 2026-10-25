import SpriteKit

final class LedgeNode: SKShapeNode {
    let size: CGSize
    let isPrecisionPlatform: Bool

    init(center: CGPoint, size: CGSize = GameConstants.ledgeSize, isPrecision: Bool = false) {
        self.size = size
        self.isPrecisionPlatform = isPrecision
        super.init()
        position = center
        path = LedgeNode.makePath(size: size)
        fillColor = isPrecision
            ? SKColor(red: 0.38, green: 0.29, blue: 0.23, alpha: 1)
            : SKColor(red: 0.32, green: 0.38, blue: 0.58, alpha: 1)
        strokeColor = isPrecision
            ? SKColor(red: 1, green: 0.78, blue: 0.42, alpha: 1)
            : SKColor(red: 0.64, green: 0.74, blue: 0.98, alpha: 1)
        lineWidth = 2
        zPosition = 8
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var topY: CGFloat { position.y + size.height / 2 }
    var grabPoint: CGPoint { CGPoint(x: position.x, y: topY + GameConstants.climberRadius) }

    func canGrab(climberPosition: CGPoint, velocity: CGVector) -> Bool {
        canGrab(from: climberPosition, to: climberPosition, velocity: velocity)
    }

    // Intersect the full movement segment with the forgiving grab rectangle.
    // Endpoint-only checks can skip a platform on a fast descending jump.
    func canGrab(from start: CGPoint, to end: CGPoint, velocity: CGVector) -> Bool {
        guard velocity.dy < 170 else { return false }
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
                guard origin >= lower && origin <= upper else { return false }
            } else {
                let first = (lower - origin) / delta
                let second = (upper - origin) / delta
                entry = max(entry, min(first, second))
                exit = min(exit, max(first, second))
                if entry > exit { return false }
            }
        }
        return true
    }

    func setTarget(_ targeted: Bool) {
        removeAction(forKey: "targetPulse")
        childNode(withName: "targetMarker")?.removeFromParent()
        glowWidth = targeted ? 3 : 0
        if isPrecisionPlatform {
            strokeColor = SKColor(red: 1, green: 0.78, blue: 0.42, alpha: 1)
        } else {
            strokeColor = targeted
                ? SKColor(red: 0.39, green: 0.96, blue: 0.8, alpha: 1)
                : SKColor(red: 0.64, green: 0.74, blue: 0.98, alpha: 1)
        }
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

    private static func makePath(size: CGSize) -> CGPath {
        let w = size.width / 2
        let h = size.height / 2
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -w, y: h - 3))
        path.addLine(to: CGPoint(x: -w * 0.45, y: h + 3))
        path.addLine(to: CGPoint(x: w * 0.2, y: h - 1))
        path.addLine(to: CGPoint(x: w, y: h + 2))
        path.addLine(to: CGPoint(x: w - 9, y: -h))
        path.addLine(to: CGPoint(x: -w + 7, y: -h - 2))
        path.closeSubpath()
        return path
    }
}
