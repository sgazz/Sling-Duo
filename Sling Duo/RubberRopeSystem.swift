import SpriteKit

final class RubberRopeSystem {
    let node = SKShapeNode()
    private(set) var tension: CGFloat = 0
    private var overstretchTime: TimeInterval = 0
    private var pulseGlowBonus: CGFloat = 0
    private var releaseProgress: CGFloat = 1
    private let halo = SKShapeNode()
    private let body = SKShapeNode()
    private let core = SKShapeNode()
    private let impulse = SKShapeNode()

    init() {
        node.strokeColor = .clear
        node.zPosition = 12
        for (index, layer) in [halo, body, core, impulse].enumerated() {
            layer.lineCap = .round
            layer.lineJoin = .round
            layer.fillColor = .clear
            layer.zPosition = CGFloat(index)
            node.addChild(layer)
        }
        halo.name = "ropeHalo"
        body.name = "ropeBody"
        core.name = "ropeCore"
        impulse.name = "ropeImpulse"
        impulse.isHidden = true
    }

    func charge(deltaTime: TimeInterval) {
        tension = min(GameConstants.maxTension, tension + CGFloat(deltaTime) * GameConstants.tensionChargeRate)
    }

    func reset() {
        tension = 0
        overstretchTime = 0
        pulseGlowBonus = 0
        node.removeAllActions()
        releaseProgress = 1
        impulse.isHidden = true
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

    /// A visual pulse traveling from the anchored partner to the launched partner.
    func launchPulse() {
        releaseProgress = 0
        node.run(.sequence([
            .customAction(withDuration: 0.32) { [weak self] _, elapsed in
                self?.releaseProgress = min(1, elapsed / 0.32)
            },
            .run { [weak self] in
                self?.releaseProgress = 1
                self?.impulse.isHidden = true
            }
        ]), withKey: "ropeRelease")
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

    func render(anchor: CGPoint, free: CGPoint) {
        updateVisual(anchor: anchor, free: free, distance: (free - anchor).length)
    }

    private func updateVisual(anchor: CGPoint, free: CGPoint, distance: CGFloat) {
        let stretch = min(1, max(0, (distance - GameConstants.restLength) /
            (GameConstants.maxStretchLength - GameConstants.restLength)))
        let energy = max(stretch, tension)
        let thickness = max(GameConstants.ropeMinVisibleThickness,
                            lerp(6, GameConstants.ropeThicknessAtMaxStretch, energy))
        let slack = 1 - min(1, distance / GameConstants.maxDragDistance)
        let sag = min(distance * 0.22, 25) * slack * (1 - tension)
        let direction = (free - anchor).normalized()
        let normal = CGVector(dx: -direction.dy, dy: direction.dx)
        let shiver = sin(CACurrentMediaTime() * 32) * max(0, energy - 0.85) * 4
        let recoil = releaseProgress < 1
            ? sin(releaseProgress * .pi * 4) * (1 - releaseProgress) * 7 : 0
        let control = CGPoint(x: (anchor.x + free.x) / 2,
                              y: (anchor.y + free.y) / 2 - sag) + normal * (shiver + recoil)
        func point(_ t: CGFloat) -> CGPoint {
            let u = 1 - t
            return CGPoint(x: u * u * anchor.x + 2 * u * t * control.x + t * t * free.x,
                           y: u * u * anchor.y + 2 * u * t * control.y + t * t * free.y)
        }
        let path = CGMutablePath()
        path.move(to: anchor)
        path.addQuadCurve(to: free, control: control)
        // Dark teal edging keeps the elastic readable over bright cave artwork.
        body.path = path
        body.lineWidth = thickness + 2
        body.strokeColor = SKColor(red: 0.06, green: 0.32, blue: 0.38, alpha: 0.95)
        core.path = path
        core.lineWidth = thickness
        core.strokeColor = SKColor(red: lerp(0.35, 1, energy),
                                   green: lerp(0.92, 0.78, energy),
                                   blue: lerp(0.94, 0.28, energy), alpha: 1)
        halo.path = path
        halo.lineWidth = thickness + 1
        halo.strokeColor = core.strokeColor.withAlphaComponent(0.16 + energy * 0.18)
        halo.glowWidth = 1 + energy * 3 + pulseGlowBonus * 4
        impulse.isHidden = releaseProgress >= 1
        if !impulse.isHidden {
            let flash = CGMutablePath()
            let start = max(0, releaseProgress - 0.16)
            let end = min(1, releaseProgress + 0.08)
            flash.move(to: point(start))
            for index in 1...8 {
                flash.addLine(to: point(lerp(start, end, CGFloat(index) / 8)))
            }
            impulse.path = flash
            impulse.lineWidth = thickness + 0.8
            impulse.strokeColor = SKColor(red: 1, green: 0.97, blue: 0.72,
                                          alpha: 1 - releaseProgress * 0.65)
            impulse.glowWidth = 3
        }
    }

    private func lerp(_ from: CGFloat, _ to: CGFloat, _ t: CGFloat) -> CGFloat {
        from + (to - from) * t
    }
}
