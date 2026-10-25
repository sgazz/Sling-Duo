import SpriteKit

final class RubberRopeSystem {
    let node = SKShapeNode()
    private(set) var tension: CGFloat = 0
    private var overstretchTime: TimeInterval = 0
    private var pulseGlowBonus: CGFloat = 0

    init() {
        node.strokeColor = .cyan
        node.lineCap = .round
        node.lineWidth = 5
        node.glowWidth = 6
        node.zPosition = 12
    }

    func charge(deltaTime: TimeInterval) {
        tension = min(GameConstants.maxTension, tension + CGFloat(deltaTime) * GameConstants.tensionChargeRate)
    }

    func reset() {
        tension = 0
        overstretchTime = 0
        pulseGlowBonus = 0
        node.removeAllActions()
    }

    func resetTension() {
        tension = 0
    }

    func updateDragVisual(anchor: CGPoint, free: CGPoint) {
        let distance = (free - anchor).length
        tension = min(GameConstants.maxTension, distance / GameConstants.maxDragDistance)
        overstretchTime = 0
        updateVisual(anchor: anchor, free: free, distance: distance)
    }

    func pulse() {
        node.removeAction(forKey: "ropePulse")
        let duration = GameConstants.ropePulseDuration
        let pulse = SKAction.sequence([
            .customAction(withDuration: duration) { [weak self] _, elapsed in
                self?.pulseGlowBonus = 1 - elapsed / duration
            },
            .run { [weak self] in
                self?.pulseGlowBonus = 0
            }
        ])
        node.run(pulse, withKey: "ropePulse")
    }

    func springForce(anchor: CGPoint, free: CGPoint, velocity: CGVector, deltaTime: TimeInterval) -> CGVector {
        let offset = anchor - free
        let distance = offset.length
        updateVisual(anchor: anchor, free: free, distance: distance)

        guard distance > GameConstants.restLength + GameConstants.ropeSlackBeforePull else {
            overstretchTime = 0
            return .zero
        }

        if distance > GameConstants.maxStretchLength {
            overstretchTime += deltaTime
        } else {
            overstretchTime = max(0, overstretchTime - deltaTime)
        }

        return RopeDynamics.force(anchor: anchor, free: free, velocity: velocity)
    }

    func slingshotVelocity(anchor: CGPoint, free: CGPoint, target: CGPoint) -> CGVector {
        let towardTarget = (target - free).normalized()
        let stretchVector = free - anchor
        let stretchDistance = stretchVector.length
        let launchDirection = CGVector(dx: -stretchVector.dx, dy: -stretchVector.dy).normalized()
        let assist = GameConstants.targetAssistStrength
        let finalDirection = CGVector(
            dx: launchDirection.dx * (1 - assist) + towardTarget.dx * assist,
            dy: launchDirection.dy * (1 - assist) + towardTarget.dy * assist
        ).normalized()
        let normalizedStretch = min(1, stretchDistance / GameConstants.maxDragDistance)
        let rawPower = stretchDistance * GameConstants.slingshotPower
        let impulseStrength = min(GameConstants.maxLaunchPower, max(GameConstants.minLaunchPower, rawPower))
        return finalDirection * impulseStrength + CGVector(dx: 0, dy: normalizedStretch * 150)
    }

    var didOverstretchTooLong: Bool {
        overstretchTime > GameConstants.overstretchGrace
    }

    private func updateVisual(anchor: CGPoint, free: CGPoint, distance: CGFloat) {
        let path = CGMutablePath()
        let restLength = GameConstants.restLength
        let maxStretchMultiplier = GameConstants.ropeMaxStretchMultiplier
        let stretchRatio = min(maxStretchMultiplier, max(1.0, distance / restLength))
        let normalizedStretch = min(1.0, max(0.0, (stretchRatio - 1.0) / (maxStretchMultiplier - 1.0)))

        var currentThickness = lerp(
            GameConstants.ropeThicknessAtRest,
            GameConstants.ropeThicknessAtMaxStretch,
            normalizedStretch
        )
        currentThickness = max(currentThickness, GameConstants.ropeMinVisibleThickness)

        let relaxedGlow = currentThickness * 0.7 + 5
        let stretchedGlow = currentThickness * 0.25 + normalizedStretch * 16 + tension * 6
        var glowWidth = lerp(relaxedGlow, stretchedGlow, normalizedStretch) + pulseGlowBonus * 14

        if normalizedStretch > 0.85 {
            let wobble = sin(CACurrentMediaTime() * 30) * (normalizedStretch - 0.85) * 6
            glowWidth += abs(wobble)
        }

        let sag = 18 + normalizedStretch * 42 - tension * 18
        let mid = CGPoint(x: (anchor.x + free.x) / 2, y: (anchor.y + free.y) / 2 - sag)
        path.move(to: anchor)
        path.addQuadCurve(to: free, control: mid)
        node.path = path
        node.lineWidth = currentThickness
        node.glowWidth = glowWidth
        node.strokeColor = SKColor(
            red: 0.25 + normalizedStretch * 0.55 + tension * 0.35 + pulseGlowBonus * 0.2,
            green: 0.88 + normalizedStretch * 0.07,
            blue: 1,
            alpha: min(1, lerp(0.72, 0.95, normalizedStretch) + pulseGlowBonus * 0.08)
        )
    }

    private func lerp(_ from: CGFloat, _ to: CGFloat, _ t: CGFloat) -> CGFloat {
        from + (to - from) * t
    }
}
