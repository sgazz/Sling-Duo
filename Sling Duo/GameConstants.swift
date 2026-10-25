import CoreGraphics
import SpriteKit

enum GameConstants {
    static let sceneSize = CGSize(width: 390, height: 844)
    static let gravity = CGVector(dx: 0, dy: -900)
    static let damping: CGFloat = 0.986
    static let climberRadius: CGFloat = 14
    static let ledgeSize = CGSize(width: 118, height: 18)
    static let restLength: CGFloat = 70
    static let maxStretchLength: CGFloat = 355
    static let ropeSlackBeforePull: CGFloat = 36
    static let ropeSpringStrength: CGFloat = 9.5
    static let ropeDamping: CGFloat = 9.5
    static let maxTension: CGFloat = 1
    static let tensionChargeRate: CGFloat = 1.8
    static let maxDragDistance: CGFloat = 180
    static let dragFollowSmoothing: CGFloat = 0.25
    static let slingshotPower: CGFloat = 11.5
    static let minLaunchPower: CGFloat = 450
    static let maxLaunchPower: CGFloat = 1500
    static let ropeStretchVisualMultiplier: CGFloat = 1.45
    static let ropeThicknessAtRest: CGFloat = 8.0
    static let ropeThicknessAtMaxStretch: CGFloat = 2.5
    static let ropeMinVisibleThickness: CGFloat = 2.0
    static let ropeMaxStretchMultiplier: CGFloat = maxStretchLength / restLength
    static let targetAssistStrength: CGFloat = 0.08
    static let swingBoost: CGFloat = 0.42
    static let landingYankPower: CGFloat = 760
    static let landingYankUpwardBoost: CGFloat = 460
    static let landingTransitionDuration: TimeInterval = 0.25
    static let ropePulseDuration: TimeInterval = 0.18
    static let ledgeMinVerticalGap: CGFloat = 140
    static let ledgeMaxVerticalGap: CGFloat = 190
    static let ledgeMaxHorizontalOffset: CGFloat = 130
    static let ledgeMinWidth: CGFloat = 120
    static let ledgeMaxWidth: CGFloat = 160
    static let grabDistance: CGFloat = 34
    static let forgivingFallDistance: CGFloat = 520
    static let overstretchGrace: TimeInterval = 1.2
}

extension CGVector {
    var length: CGFloat { sqrt(dx * dx + dy * dy) }

    func normalized() -> CGVector {
        let len = length
        guard len > 0 else { return .zero }
        return CGVector(dx: dx / len, dy: dy / len)
    }

    static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }

    static func - (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
    }

    static func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
        CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }

    static func += (lhs: inout CGVector, rhs: CGVector) {
        lhs = lhs + rhs
    }
}

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGVector {
        CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
    }
}
