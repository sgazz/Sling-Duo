import SpriteKit

final class ClimberNode: SKShapeNode {
    enum Expression { case calm, strained, flying, happy, dizzy }

    private let eyes = SKNode()
    private let mouth = SKShapeNode()
    private var pupils: [SKShapeNode] = []
    private var brows: [SKShapeNode] = []
    private var expression: Expression?
    private var blinkCountdown: TimeInterval = 3

    init(color: SKColor) {
        super.init()
        path = CGPath(roundedRect: CGRect(x: -16, y: -18, width: 32, height: 36), cornerWidth: 13, cornerHeight: 13, transform: nil)
        fillColor = color
        strokeColor = .white.withAlphaComponent(0.8)
        lineWidth = 2.5
        zPosition = 20
        addChild(eyes)
        for x: CGFloat in [-6, 6] {
            let eye = SKShapeNode(ellipseOf: CGSize(width: 8, height: 10))
            eye.position = CGPoint(x: x, y: 4)
            eye.fillColor = .white
            eye.strokeColor = .clear
            let pupil = SKShapeNode(circleOfRadius: 2)
            pupil.fillColor = SKColor(white: 0.08, alpha: 1)
            pupil.strokeColor = .clear
            eye.addChild(pupil)
            pupils.append(pupil)
            eyes.addChild(eye)
            let brow = SKShapeNode(rectOf: CGSize(width: 7, height: 1.8), cornerRadius: 0.8)
            brow.fillColor = SKColor(white: 0.08, alpha: 0.8)
            brow.strokeColor = .clear
            brow.position = CGPoint(x: x, y: 12)
            addChild(brow)
            brows.append(brow)
        }
        mouth.strokeColor = SKColor(white: 0.08, alpha: 1)
        mouth.lineWidth = 2
        mouth.lineCap = .round
        addChild(mouth)
        resetPersonality()
    }

    required init?(coder: NSCoder) { fatalError("Not supported") }

    func setAnchored(_ anchored: Bool) {
        removeAction(forKey: "landingSquash")
        zRotation = 0
        setScale(anchored ? 0.95 : 1)
    }

    func setFlightLean(_ tilt: CGFloat) { zRotation = tilt * 0.16 }

    func resetPersonality() {
        eyes.removeAllActions()
        eyes.yScale = 1
        blinkCountdown = Double.random(in: 2.5...5)
        expression = nil
        updatePersonality(.calm, lookingAt: position, deltaTime: 0)
    }

    func updatePersonality(_ next: Expression, lookingAt target: CGPoint, deltaTime: TimeInterval) {
        // Convert the world-space target into this rotated/scaled character's space.
        let localTarget = parent.map { convert(target, from: $0) } ?? .zero
        let direction = (localTarget - CGPoint.zero).normalized()
        for pupil in pupils {
            pupil.position = CGPoint(x: direction.dx * 1.7, y: direction.dy * 1.5)
        }
        blinkCountdown -= deltaTime
        if blinkCountdown <= 0 && next != .dizzy {
            blinkCountdown = Double.random(in: 2.5...5)
            eyes.run(.sequence([
                .scaleY(to: 0.08, duration: 0.06),
                .scaleY(to: 1, duration: 0.09)
            ]), withKey: "blink")
        }
        guard expression != next else { return }
        expression = next
        let curve = CGMutablePath()
        mouth.fillColor = .clear
        for brow in brows { brow.isHidden = next == .calm || next == .happy }
        switch next {
        case .calm, .happy:
            let width: CGFloat = next == .happy ? 6 : 4
            curve.move(to: CGPoint(x: -width, y: -6))
            curve.addQuadCurve(to: CGPoint(x: width, y: -6), control: CGPoint(x: 0, y: next == .happy ? -15 : -11))
        case .strained:
            curve.move(to: CGPoint(x: -4, y: -8))
            curve.addLine(to: CGPoint(x: 4, y: -8))
        case .flying:
            curve.addEllipse(in: CGRect(x: -3, y: -12, width: 6, height: 8))
            mouth.fillColor = SKColor(white: 0.08, alpha: 1)
        case .dizzy:
            curve.move(to: CGPoint(x: -5, y: -9))
            curve.addQuadCurve(to: CGPoint(x: 5, y: -9), control: CGPoint(x: 0, y: -3))
        }
        for (index, brow) in brows.enumerated() {
            brow.zRotation = (index == 0 ? 1 : -1) * (next == .strained ? -0.35 : 0.25)
            brow.position.y = next == .flying ? 14 : 12
        }
        mouth.path = curve
    }
}
