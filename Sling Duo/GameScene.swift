import CoreMotion
import SpriteKit
import UIKit

final class GameScene: SKScene {
    private let mint = ClimberNode(hero: .cyan)
    private let coral = ClimberNode(hero: .orange)
    private let sound = GameAudio()
    var soundEnabled: Bool {
        get { sound.enabled }
        set { sound.enabled = newValue }
    }
    private let rope = RubberRopeSystem()
    private let gameCamera = SKCameraNode()
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let hint = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let rescueTrack = SKShapeNode(rectOf: CGSize(width: 100, height: 5), cornerRadius: 2.5)
    private let rescueFill = SKShapeNode(rectOf: CGSize(width: 100, height: 5), cornerRadius: 2.5)
    private let recordToast = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private var celebratedRecord = false
    private var happyTime: TimeInterval = 0
    private let bestLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let retryCard = SKNode()
    private let retryTitle = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let retryScore = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let retryBest = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let launchHaptic = UIImpactFeedbackGenerator(style: .soft)
    private var trailClock: TimeInterval = 0
    private let backdrop = CaveBackdrop()
    private let aim = SKNode()
    private let predictionRope = RubberRopeSystem()
    private var touchOrigin = CGPoint.zero
    private var jumperOrigin = CGPoint.zero
    private var draggedDistance: CGFloat = 0
    private var anchor: ClimberNode!
    private var jumper: ClimberNode!
    private var current: LedgeNode!
    private var nextLedge: LedgeNode!
    private var spawner = LedgeSpawner(sceneWidth: 390)
    private var velocity = CGVector.zero
    private var previousTime: TimeInterval = 0
    private var accumulator: TimeInterval = 0
    private var drag: CGPoint?
    private var activeTouch: UITouch?
    private var score = 0
    private var best = UserDefaults.standard.integer(forKey: "SlingDuo.best")
    private let motion = CMMotionManager()
    private var tilt = TiltSteering()
    private var flow = JumpFlow()
    private var handoffElapsed: TimeInterval = 0
    private var handoffStart = CGPoint.zero
    private var handoffTarget = CGPoint.zero
    private var ended: Bool { flow.phase == .over }
    private var flight: Bool { flow.phase == .flying }
    private var ready = false


    override func didMove(to view: SKView) {
        if UIApplication.shared.applicationState == .active { startMotion() }
        guard !ready else { return }
        ready = true
        sound.prepare()
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.055, green: 0.075, blue: 0.16, alpha: 1)
        camera = gameCamera
        addChild(gameCamera)
        addChild(rope.node)
        aim.zPosition = 10
        addChild(aim)
        backdrop.zPosition = -100
        gameCamera.addChild(backdrop)
        for index in 0..<18 {
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor = .white
            dot.strokeColor = .clear
            dot.alpha = 0.65 * (1 - CGFloat(index) / 22)
            aim.addChild(dot)
        }
        aim.isHidden = true
        for label in [title, scoreLabel, hint] {
            label.zPosition = 100
            gameCamera.addChild(label)
        }
        bestLabel.fontSize = 11
        bestLabel.fontColor = .white.withAlphaComponent(0.45)
        bestLabel.zPosition = 100
        gameCamera.addChild(bestLabel)
        recordToast.fontSize = 14
        recordToast.fontColor = SKColor(red: 1, green: 0.81, blue: 0.36, alpha: 1)
        recordToast.text = "NEW BEST!"
        recordToast.alpha = 0
        recordToast.zPosition = 100
        gameCamera.addChild(recordToast)
        rescueTrack.fillColor = .white.withAlphaComponent(0.12)
        rescueTrack.strokeColor = .clear
        rescueFill.fillColor = SKColor(red: 1, green: 0.76, blue: 0.4, alpha: 1)
        rescueFill.strokeColor = .clear
        rescueTrack.zPosition = 100
        rescueFill.zPosition = 101
        rescueTrack.isHidden = true
        rescueFill.isHidden = true
        gameCamera.addChild(rescueTrack)
        gameCamera.addChild(rescueFill)
        setupRetryCard()
        title.fontSize = 19
        title.fontColor = SKColor(white: 1, alpha: 0.65)
        title.text = "SLING DUO"
        scoreLabel.fontSize = 42
        hint.fontSize = 15
        layoutHUD()
        reset()
    }


    override func willMove(from view: SKView) {
        sound.suspend()
        motion.stopDeviceMotionUpdates()
    }

    deinit { motion.stopDeviceMotionUpdates() }

    func setActive(_ active: Bool) {
        if !active, let touch = activeTouch {
            touchesCancelled([touch], with: nil)
        }
        isPaused = !active
        previousTime = 0
        if active {
            if view != nil {
                sound.prepare()
                startMotion()
            }
        } else {
            sound.suspend()
            motion.stopDeviceMotionUpdates()
            tilt.reset()
        }
    }

    private func startMotion() {
        guard motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 60
        motion.startDeviceMotionUpdates()
    }

    private var gravityInput: CGFloat? {
        guard let gravity = motion.deviceMotion?.gravity else { return nil }
        switch view?.window?.windowScene?.interfaceOrientation {
        case .landscapeLeft: return CGFloat(-gravity.y)
        case .landscapeRight: return CGFloat(gravity.y)
        case .portraitUpsideDown: return CGFloat(-gravity.x)
        default: return CGFloat(gravity.x)
        }
    }

    private func updateRescueMeter() {
        rescueTrack.isHidden = !flow.isRescuing
        rescueFill.isHidden = !flow.isRescuing
        guard flow.isRescuing else { return }
        let fraction = CGFloat(flow.rescueRemaining / JumpTuning.rescueDuration)
        rescueFill.xScale = fraction
        rescueFill.position.x = -50 * (1 - fraction)
    }

    private func beginRescue() {
        velocity = velocity * 0.25
        tilt.stopSteering()
        rope.reset()
        hint.fontColor = SKColor(red: 1, green: 0.76, blue: 0.4, alpha: 1)
        sound.play(.miss)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard ready else { return }
        layoutHUD()
        // Rebuild the short prototype run when the playfield changes size.
        reset()
    }

    private func layoutHUD() {
        buildBackdrop()
        let topInset = view?.safeAreaInsets.top ?? 0
        title.position = CGPoint(x: 0, y: size.height / 2 - max(70, topInset + 25))
        scoreLabel.position = title.position + CGVector(dx: 0, dy: -50)
        bestLabel.position = scoreLabel.position + CGVector(dx: 0, dy: -24)
        recordToast.position = bestLabel.position + CGVector(dx: 0, dy: -29)
        rescueTrack.position = CGPoint(x: 0, y: -size.height / 2 + 83)
        rescueFill.position = rescueTrack.position
        retryCard.position = CGPoint(x: 0, y: 15)
        hint.position = CGPoint(x: 0, y: -size.height / 2 + max(48, (view?.safeAreaInsets.bottom ?? 0) + 24))
    }

    private func reset() {
        removeAllActions()
        for child in children where child !== gameCamera && child !== rope.node && child !== aim { child.removeFromParent() }
        rope.reset()
        aim.isHidden = true
        retryCard.isHidden = true
        rescueTrack.isHidden = true
        rescueFill.isHidden = true
        scoreLabel.isHidden = false
        bestLabel.isHidden = false
        trailClock = 0
        happyTime = 0
        celebratedRecord = false
        recordToast.removeAllActions()
        recordToast.alpha = 0
        scoreLabel.removeAllActions()
        scoreLabel.setScale(1)
        mint.resetPersonality()
        coral.resetPersonality()
        score = 0
        mint.removeAllActions()
        coral.removeAllActions()
        addChild(mint)
        addChild(coral)
        spawner = LedgeSpawner(sceneWidth: size.width)
        current = spawner.startingLedge(y: size.height * 0.34)
        nextLedge = makeNext()
        addChild(current)
        addChild(nextLedge)
        nextLedge.setTarget(true)
        anchor = mint
        jumper = coral
        anchor.position = current.grabPoint
        jumper.position = anchor.position + CGVector(dx: 65, dy: -95)
        anchor.setAnchored(true)
        jumper.setAnchored(false)
        velocity = .zero
        drag = nil
        activeTouch = nil
        flow.reset()
        tilt.reset()
        handoffElapsed = 0
        score = 0
        previousTime = 0
        accumulator = 0
        gameCamera.position = CGPoint(x: size.width / 2, y: size.height / 2)
        hint.text = "SLING TO START • THEN TILT"
        hint.fontColor = .white.withAlphaComponent(0.7)
        scoreLabel.text = "0"
        bestLabel.text = "BEST \(best)"
        rope.updateDragVisual(anchor: anchor.position, free: jumper.position)
    }

    private func makeNext() -> LedgeNode {
        spawner.nextLedge(above: current, score: score)
    }

    override func update(_ currentTime: TimeInterval) {
        guard ready else { return }
        defer { previousTime = currentTime }
        guard !ended else { return }
        let elapsed = previousTime == 0 ? 1.0 / 60 : max(0, min(1.0 / 15, currentTime - previousTime))
        accumulator += elapsed
        let step = 1.0 / 120
        while accumulator >= step {
            simulate(step)
            accumulator -= step
            if ended { accumulator = 0; break }
        }
        guard !ended else { return }
        if drag == nil {
            gameCamera.position.y = ClimbCamera.nextY(current: gameCamera.position.y,
                anchorY: anchor.position.y, jumperY: jumper.position.y,
                height: size.height, inFlight: flight, dt: elapsed)
        }
        updateRescueMeter()
        happyTime = max(0, happyTime - elapsed)
        anchor.updatePersonality(happyTime > 0 ? .happy : .calm,
                                 lookingAt: jumper.position, deltaTime: elapsed)
        let jumperExpression: ClimberNode.Expression = drag != nil
            ? .strained : (flow.phase == .rescue ? .dizzy : (flight ? .flying : .calm))
        jumper.updatePersonality(jumperExpression, lookingAt: nextLedge.grabPoint, deltaTime: elapsed)
        rope.render(anchor: anchor.ropeAttachment, free: jumper.ropeAttachment)
        updateAim()
        updateTrail(elapsed)
        backdrop.update(travel: gameCamera.position.y - size.height / 2)
        for ledge in children.compactMap({ $0 as? LedgeNode }) where ledge !== current && ledge !== nextLedge && ledge.position.y < gameCamera.position.y - size.height / 2 - 80 {
            ledge.removeFromParent()
        }
    }

    private func simulate(_ dt: TimeInterval) {
        anchor.position = current.grabPoint
        if let target = drag {
            jumper.position = jumper.position + (target - jumper.position) * CGFloat(1 - exp(-20 * dt))
            velocity = .zero
            rope.updateDragVisual(anchor: anchor.position, free: jumper.position)
            return
        }
        if flow.phase == .handoff {
            // Read input during the handoff so holding a tilt doesn't feel unresponsive.
            _ = tilt.update(sample: gravityInput, dt: dt)
            handoffElapsed += dt
            let fraction = min(1, CGFloat(handoffElapsed / JumpTuning.handoffDuration))
            let eased = fraction * fraction * (3 - 2 * fraction)
            jumper.position = handoffStart + (handoffTarget - handoffStart) * eased
            rope.updateDragVisual(anchor: anchor.position, free: jumper.position)
            if flow.advance(dt, y: jumper.position.y, verticalSpeed: 0, targetY: nextLedge.grabPoint.y) == .launchPartner {
                velocity = PartnerLaunch.velocity(from: jumper.position, anchor: anchor.position, target: nextLedge.grabPoint)
                rope.reset()
                rope.launchPulse()
                trailClock = 0
                hint.text = "TILT TO STEER"
                hint.fontColor = .white.withAlphaComponent(0.7)
                sound.play(.launch)
                launchHaptic.impactOccurred(intensity: 0.35)
            }
            return
        }
        let steeringSpeed = flight ? tilt.update(sample: gravityInput, dt: dt) : 0
        let actualVelocity = velocity + CGVector(dx: steeringSpeed, dy: 0)
        var force = GameConstants.gravity
        force += rope.springForce(anchor: anchor.position, free: jumper.position, velocity: actualVelocity, deltaTime: dt)
        let previousPosition = jumper.position
        var position = previousPosition
        RopeDynamics.integrate(position: &position, velocity: &velocity, force: force,
                               dt: dt, steeringSpeed: steeringSpeed)
        jumper.position = position
        jumper.setFlightLean(max(-1, min(1, (velocity.dx + steeringSpeed) / 450)))
        if flight && nextLedge.canGrab(from: previousPosition, to: jumper.position, velocity: velocity) {
            land()
            return
        }
        let event = flow.advance(dt, y: jumper.position.y, verticalSpeed: velocity.dy, targetY: nextLedge.grabPoint.y)
        if event == .missed {
            beginRescue()
        } else if event == .rescueExpired {
            finish()
            return
        }
        if flight && rope.didOverstretchTooLong {
            flow.miss()
            beginRescue()
        }
        if flow.phase == .rescue {
            hint.text = "MISSED • PULL TO SAVE \(Int(ceil(flow.rescueRemaining)))"
            if jumper.position.y < gameCamera.position.y - size.height / 2 - 100 { finish() }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, activeTouch == nil else { return }
        if ended { reset(); return }
        guard flow.beginAim() else { return }
        activeTouch = touch
        touchOrigin = touch.location(in: self)
        jumperOrigin = jumper.position
        draggedDistance = 0
        drag = jumper.position
        launchHaptic.prepare()
        hint.text = "RELEASE TO FLY"
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        let movement = touch.location(in: self) - touchOrigin
        draggedDistance = max(draggedDistance, movement.length)
        drag = clamped(jumperOrigin + movement)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        guard draggedDistance > 8 else {
            touchesCancelled(touches, with: event)
            return
        }
        velocity = rope.slingshotVelocity(anchor: anchor.position, free: jumper.position, target: nextLedge.grabPoint)
        sound.play(.launch)
        launchHaptic.impactOccurred(intensity: 0.6)
        trailClock = 0
        aim.isHidden = true
        drag = nil
        activeTouch = nil
        tilt.calibrate(gravityInput)
        flow.launch()
        hint.fontColor = .white.withAlphaComponent(0.7)
        rope.reset()
        rope.launchPulse()
        hint.text = "TILT TO STEER"
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        activeTouch = nil
        drag = nil
        aim.isHidden = true
        velocity = .zero
        flow.cancelAim()
        hint.text = flow.phase == .rescue ? "PULL TO SAVE THE DUO" : "SLING TO START • THEN TILT"
    }
    private func clamped(_ point: CGPoint) -> CGPoint {
        let offset = point - anchor.position
        return anchor.position + offset.normalized() * min(offset.length, GameConstants.maxDragDistance)
    }

    private func land() {
        jumper.position = nextLedge.grabPoint
        let oldAnchor = anchor!
        anchor = jumper
        jumper = oldAnchor
        anchor.setAnchored(true)
        jumper.setAnchored(false)
        velocity = .zero
        handoffStart = jumper.position
        handoffElapsed = 0
        tilt.stopSteering()
        current = nextLedge
        current.setTarget(false)
        celebrate(at: anchor.position, color: anchor.fillColor)
        anchor.run(.sequence([
            .scaleX(to: 1.15, y: 0.8, duration: 0.07),
            .scale(to: 0.95, duration: 0.14)
        ]), withKey: "landingSquash")
        happyTime = 0.65
        score += 1
        if score > best {
            if !celebratedRecord {
                celebratedRecord = true
                recordToast.removeAllActions()
                recordToast.run(.sequence([
                    .fadeIn(withDuration: 0.12),
                    .wait(forDuration: 1.3),
                    .fadeOut(withDuration: 0.35)
                ]))
            }
            best = score
            UserDefaults.standard.set(best, forKey: "SlingDuo.best")
        }
        bestLabel.text = "BEST \(best)"
        nextLedge = makeNext()
        handoffTarget = PartnerLaunch.startPosition(anchor: anchor.position, target: nextLedge.grabPoint)
        addChild(nextLedge)
        nextLedge.setTarget(true)
        flow.land()
        rope.reset()
        rope.pulse()
        scoreLabel.text = "\(score)"
        scoreLabel.run(.sequence([
            .scale(to: 1.12, duration: 0.08),
            .scale(to: 1, duration: 0.16)
        ]), withKey: "scorePop")
        hint.text = score % 5 == 0
            ? "\(score) UP. STILL TOGETHER!"
            : ["TEAMWORK!", "STILL FRIENDS!", "NO ONE PANIC.", "UP WE GO!"][score % 4]
        sound.play(.grab, step: score)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let pop = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        pop.text = "+1"
        pop.fontSize = 24
        pop.fontColor = .white
        pop.position = anchor.position + CGVector(dx: 0, dy: 35)
        pop.zPosition = 40
        addChild(pop)
        pop.run(.sequence([.group([.moveBy(x: 0, y: 45, duration: 0.5), .fadeOut(withDuration: 0.5)]), .removeFromParent()]))
    }


    // The guide advances the same spring, gravity and damping as the live jumper.
    // Its rope has independent state so previewing cannot charge the live rope.
    private func updateAim() {
        aim.isHidden = drag == nil || draggedDistance <= 8
        guard !aim.isHidden else { return }
        predictionRope.reset()
        var position = jumper.position
        var predictedVelocity = rope.slingshotVelocity(anchor: anchor.position, free: position, target: nextLedge.grabPoint)
        let dt = 1.0 / 120
        for dot in aim.children {
            for _ in 0..<6 {
                var force = GameConstants.gravity
                force += predictionRope.springForce(anchor: anchor.position, free: position, velocity: predictedVelocity, deltaTime: dt)
                predictedVelocity += force * CGFloat(dt)
                predictedVelocity = predictedVelocity * CGFloat(pow(Double(GameConstants.damping), dt * 60))
                position = position + predictedVelocity * CGFloat(dt)
            }
            dot.position = position
        }
    }

    private func buildBackdrop() {
        backdrop.configure(size: size)
    }

    private func updateTrail(_ elapsed: TimeInterval) {
        guard flight, drag == nil, !ended else { trailClock = 0; return }
        trailClock += elapsed
        guard trailClock >= 0.035 else { return }
        trailClock = 0
        let dot = SKShapeNode(circleOfRadius: 4)
        dot.position = jumper.position
        dot.fillColor = jumper.fillColor.withAlphaComponent(0.3)
        dot.strokeColor = .clear
        dot.zPosition = 9
        addChild(dot)
        dot.run(.sequence([
            .group([.fadeOut(withDuration: 0.28), .scale(to: 0.2, duration: 0.28)]),
            .removeFromParent()
        ]))
    }

    private func celebrate(at point: CGPoint, color: SKColor) {
        for index in 0..<10 {
            let angle = CGFloat(index) / 10 * .pi * 2
            let dot = SKShapeNode(circleOfRadius: index % 2 == 0 ? 3 : 2)
            dot.fillColor = index % 2 == 0 ? color : .white
            dot.strokeColor = .clear
            dot.position = point
            dot.zPosition = 25
            addChild(dot)
            dot.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * 42, y: sin(angle) * 32 + 15, duration: 0.35),
                    .fadeOut(withDuration: 0.35)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func setupRetryCard() {
        retryCard.zPosition = 150
        retryCard.isHidden = true
        let width = min(size.width - 40, 310)
        let panel = SKShapeNode(rectOf: CGSize(width: width, height: 210), cornerRadius: 24)
        panel.fillColor = SKColor(red: 0.09, green: 0.12, blue: 0.23, alpha: 0.98)
        panel.strokeColor = SKColor(red: 0.35, green: 0.43, blue: 0.62, alpha: 1)
        panel.lineWidth = 1.5
        retryCard.addChild(panel)
        retryTitle.text = "A LITTLE TANGLED."
        retryTitle.fontSize = 18
        retryTitle.fontColor = SKColor(red: 1, green: 0.76, blue: 0.4, alpha: 1)
        retryTitle.position.y = 60
        retryScore.fontSize = 48
        retryScore.position.y = 0
        retryBest.fontSize = 13
        retryBest.position.y = -30
        let prompt = SKLabelNode(fontNamed: "AvenirNext-Bold")
        prompt.text = "TAP ANYWHERE TO RETRY"
        prompt.fontSize = 12
        prompt.position.y = -75
        for label in [retryTitle, retryScore, retryBest, prompt] { retryCard.addChild(label) }
        gameCamera.addChild(retryCard)
    }

    private func finish() {
        aim.isHidden = true
        flow.finish()
        sound.play(.end)
        rescueTrack.isHidden = true
        rescueFill.isHidden = true
        mint.updatePersonality(.dizzy, lookingAt: coral.position, deltaTime: 0)
        coral.updatePersonality(.dizzy, lookingAt: mint.position, deltaTime: 0)
        recordToast.removeAllActions()
        recordToast.alpha = 0
        activeTouch = nil
        drag = nil
        best = max(best, score)
        UserDefaults.standard.set(best, forKey: "SlingDuo.best")
        nextLedge.setTarget(false)
        retryScore.text = "\(score)"
        retryBest.text = "BEST \(best)"
        retryCard.isHidden = false
        retryCard.setScale(0.92)
        retryCard.run(.scale(to: 1, duration: 0.15))
        scoreLabel.isHidden = true
        bestLabel.isHidden = true
        hint.text = "SAME ROPE. ANOTHER CHANCE."
        hint.fontColor = SKColor(red: 1, green: 0.76, blue: 0.4, alpha: 1)
    }
}
