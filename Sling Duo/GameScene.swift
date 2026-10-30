import CoreMotion
import SpriteKit
import UIKit
import Combine

final class GameScene: SKScene, ObservableObject {
    @Published private(set) var escapeSummary: EscapeSummary?
    @Published private(set) var hud = GameHUDState()
    @Published private(set) var runSummary: RunSummary?
    private var hudClock: TimeInterval = 0
    private var progress = EscapeProgress()

    private let mint = ClimberNode(hero: .cyan)
    private let coral = ClimberNode(hero: .orange)
    private let sound = GameAudio()
    var soundEnabled: Bool {
        get { sound.enabled }
        set { sound.enabled = newValue }
    }
    var steeringMode: SteeringMode = .tilt {
        didSet {
            slide.reset()
            tilt.stopSteering()
            steeringTouch = nil
            if steeringMode == .slide { motion.stopDeviceMotionUpdates() }
            else if !userPaused && appActive && view != nil { startMotion() }
            if ready && !ended { publishHUD() }
        }
    }
    private var slide = SlideSteering()
    private var steeringTouch: UITouch?
    private var steeringOrigin: CGFloat = 0
    private let rope = RubberRopeSystem()
    private let gameCamera = SKCameraNode()
    private var celebratedRecord = false
    private var happyTime: TimeInterval = 0
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
    private var upcoming: [LedgeNode] = []
    private var rewards = CatchRewards()
    var turboEnabled = false {
        didSet {
            guard oldValue != turboEnabled else { return }
            if turboEnabled {
                progress.markTurbo()
                best = UserDefaults.standard.integer(forKey: progress.recordPrefix + ".height")
            }
            tempo.reset()
            accumulator = 0
            if ready { publishHUD() }
        }
    }
    private var tempo = ExperimentalTempo()
    private var points = 0
    private var rescueWarningPlayed = false
    private var userPaused = false
    private var appActive = true
    private var score = 0
    private var best = 0
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
        if UIApplication.shared.applicationState == .active && !userPaused { startMotion() }
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
        layoutHUD()
        reset()
        #if DEBUG
        scheduleUIPreview()
        #endif
    }


    #if DEBUG
    private func scheduleUIPreview() {
        let environment = ProcessInfo.processInfo.environment
        guard environment["SLINGDUO_ESCAPE_UI_TEST"] == "1" || environment["SLINGDUO_UI_SCREEN"] != nil else { return }
        run(.sequence([.wait(forDuration: 0.3), .run { [weak self] in
            guard let self else { return }
            if environment["SLINGDUO_ESCAPE_UI_TEST"] == "1" { self.prepareEscapeUITest() }
            switch environment["SLINGDUO_UI_SCREEN"] {
            case "rescue":
                _ = self.flow.beginAim()
                _ = self.flow.advance(2.6, y: self.jumper.position.y, verticalSpeed: 0, targetY: self.nextLedge.grabPoint.y)
                self.publishHUD()
                self.setGameplayPaused(true)
            case "expiryAiming", "expiryFlying":
                _ = self.flow.beginAim()
                _ = self.flow.advance(3.85, y: self.jumper.position.y, verticalSpeed: 0, targetY: self.nextLedge.grabPoint.y)
                if environment["SLINGDUO_UI_SCREEN"] == "expiryAiming" {
                    self.drag = self.jumper.position
                } else { self.flow.launch() }
                self.publishHUD()
            case "defeat":
                self.score = 42
                self.points = 86
                self.progress.advance(83)
                _ = self.progress.catchPlatform(height: 42, streak: 14)
                self.finish()
            default: break
            }
        }]), withKey: "UITestPreview")
    }
    #endif

    override func willMove(from view: SKView) {
        sound.suspend()
        motion.stopDeviceMotionUpdates()
    }

    deinit { motion.stopDeviceMotionUpdates() }

    func setActive(_ active: Bool) {
        appActive = active
        if !active { setGameplayPaused(true) }
    }

    func setGameplayPaused(_ paused: Bool) {
        steeringTouch = nil
        slide.reset()
        if paused, let touch = activeTouch { touchesCancelled([touch], with: nil) }
        publishHUD()
        userPaused = paused
        isPaused = paused || !appActive
        previousTime = 0
        accumulator = 0
        if isPaused {
            sound.suspend()
            motion.stopDeviceMotionUpdates()
            tilt.stopSteering()
        } else if view != nil {
            sound.prepare()
            startMotion()
        }
    }

    func restartFromMenu() { reset() }

    func continueEndless() {
        guard progress.awaitingChoice else { return }
        progress.keepClimbing()
        escapeSummary = nil
        anchor.removeAllActions()
        jumper.removeAllActions()
        anchor.position = current.grabPoint
        jumper.position = handoffStart
        anchor.setScale(0.95)
        jumper.setScale(1)
        previousTime = 0
        accumulator = 0
        for ledge in upcoming {
            ledge.isHidden = false
            ledge.trickAlternative?.isHidden = false
        }
        nextLedge.setTarget(true)
        updateRunHUD()
        publishHUD()
        if !userPaused && appActive { startMotion() }
    }

    private func startMotion() {
        guard steeringMode == .tilt, motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive else { return }
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
        guard flow.isRescuing, flow.rescueRemaining <= 1, !rescueWarningPlayed else { return }
        rescueWarningPlayed = true
        sound.play(.miss)
    }

    private func beginRescue() {
        rewards.miss()
        updatePointsHUD()
        steeringTouch = nil
        slide.reset()
        rescueWarningPlayed = false
        velocity = velocity * 0.25
        tilt.stopSteering()
        rope.reset()

        sound.play(.miss)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard ready else { return }
        layoutHUD()
        // Rebuild when the initial SpriteView size adopts the device viewport.
        reset()
        #if DEBUG
        scheduleUIPreview()
        #endif
    }

    private func layoutHUD() {
        buildBackdrop()
    }

    private func reset() {
        removeAllActions()
        escapeSummary = nil
        runSummary = nil
        hudClock = 0
        progress = EscapeProgress(turbo: turboEnabled)
        best = UserDefaults.standard.integer(forKey: progress.recordPrefix + ".height")
        backdrop.alpha = 1
        backgroundColor = SKColor(red: 0.055, green: 0.075, blue: 0.16, alpha: 1)
        for child in children where child !== gameCamera && child !== rope.node && child !== aim { child.removeFromParent() }
        rope.reset()
        aim.isHidden = true




        trailClock = 0
        happyTime = 0
        celebratedRecord = false
        rescueWarningPlayed = false




        mint.resetPersonality()
        coral.resetPersonality()
        score = 0
        points = 0
        tempo.reset()
        rewards = CatchRewards()
        updatePointsHUD()

        upcoming.removeAll()
        steeringTouch = nil
        slide.reset()
        mint.removeAllActions()
        coral.removeAllActions()
        addChild(mint)
        addChild(coral)
        spawner = LedgeSpawner(sceneWidth: size.width)
        gameCamera.position = CGPoint(x: size.width / 2, y: size.height / 2)
        current = spawner.startingLedge(y: size.height * 0.34)
        addChild(current)
        fillUpcoming()
        nextLedge = upcoming[0]
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


        updateRunHUD()
        rope.updateDragVisual(anchor: anchor.position, free: jumper.position)
        publishHUD()
    }

    private func fillUpcoming() {
        let top = max(gameCamera.position.y + size.height / 2, current.position.y + size.height)
        while upcoming.count < 2 || (upcoming.last?.position.y ?? current.position.y) < top + 190 {
            let base = upcoming.last ?? current!
            let ledge = spawner.nextLedge(above: base, score: score + upcoming.count)
            ledge.isHidden = !progress.endless && score + upcoming.count + 1 > EscapeProgress.goal
            ledge.trickAlternative?.isHidden = ledge.isHidden
            upcoming.append(ledge)
            addChild(ledge)
            if let trick = ledge.trickAlternative { addChild(trick) }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard ready, !userPaused, appActive else { return }
        defer {
            previousTime = currentTime
            if hudClock >= 0.1 { publishHUD(); hudClock = 0 }
        }
        guard !ended, !progress.awaitingChoice else { return }
        let elapsed = previousTime == 0 ? 1.0 / 60 : max(0, min(1.0 / 15, currentTime - previousTime))
        hudClock += elapsed
        if flow.phase != .ready || flow.deadlineActive { progress.advance(elapsed) }
        if turboEnabled && (flow.phase != .ready || flow.deadlineActive) {
            tempo.advance(elapsed)
        }
        let multiplier = turboEnabled ? tempo.multiplier : 1
        accumulator += elapsed * multiplier
        let step = 1.0 / 120
        while accumulator >= step {
            simulate(step, realDelta: step / multiplier)
            accumulator -= step
            if ended || progress.awaitingChoice { accumulator = 0; break }
        }
        guard !ended, !progress.awaitingChoice else { return }
        if drag == nil {
            gameCamera.position.y = ClimbCamera.nextY(current: gameCamera.position.y,
                anchorY: anchor.position.y, jumperY: jumper.position.y,
                height: size.height, inFlight: flight, dt: elapsed * multiplier)
        }
        fillUpcoming()
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

    private func publishHUD() {
        var state = GameHUDState()
        state.height = score
        state.points = points
        state.streak = rewards.streak
        state.best = best
        state.newBest = celebratedRecord
        state.endless = progress.endless
        state.turbo = turboEnabled
        state.tempo = tempo.multiplier
        state.seconds = Int(progress.seconds)
        if flow.isRescuing { state.remaining = ceil(flow.rescueRemaining * 10) / 10 }
        switch flow.phase {
        case .ready: state.instruction = "Pull a hero to launch"
        case .aiming: state.instruction = "Release to fly"
        case .rescue: state.instruction = "Pull to save the duo"
        case .handoff: state.instruction = "Your partner is up next"
        case .flying: state.instruction = steeringMode == .tilt ? "Tilt gently to steer" : "Slide left or right to steer"
        case .over: state.instruction = "Same rope. Another chance."
        }
        if state != hud { hud = state }
    }

    private func simulate(_ dt: TimeInterval, realDelta: TimeInterval) {
        let targetStartX = nextLedge.position.x
        nextLedge.advanceMotion(dt)
        anchor.position = current.grabPoint
        if let target = drag {
            if flow.advance(dt, y: jumper.position.y, verticalSpeed: 0, targetY: nextLedge.grabPoint.y, realDelta: realDelta) == .rescueExpired {
                finish()
                return
            }
            jumper.position = jumper.position + (target - jumper.position) * CGFloat(1 - exp(-20 * dt))
            velocity = .zero
            rope.updateDragVisual(anchor: anchor.position, free: jumper.position)
            return
        }
        if flow.phase == .handoff {
            // Read input during the handoff so holding a tilt doesn't feel unresponsive.
            _ = tilt.update(sample: gravityInput, dt: realDelta)
            handoffElapsed += dt
            let fraction = min(1, CGFloat(handoffElapsed / JumpTuning.handoffDuration))
            let eased = fraction * fraction * (3 - 2 * fraction)
            jumper.position = handoffStart + (handoffTarget - handoffStart) * eased
            rope.updateDragVisual(anchor: anchor.position, free: jumper.position)
            if flow.advance(dt, y: jumper.position.y, verticalSpeed: 0, targetY: nextLedge.grabPoint.y, realDelta: realDelta) == .launchPartner {
                velocity = PartnerLaunch.velocity(from: jumper.position, anchor: anchor.position, target: nextLedge.grabPoint)
                rope.reset()
                rope.launchPulse()
                trailClock = 0


                sound.play(.launch)
                launchHaptic.impactOccurred(intensity: 0.35)
            }
            return
        }
        let steeringSpeed = flight ? (steeringMode == .tilt
            ? tilt.update(sample: gravityInput, dt: realDelta) : slide.update(dt: realDelta)) : 0
        let actualVelocity = velocity + CGVector(dx: steeringSpeed, dy: 0)
        var force = GameConstants.gravity
        force += rope.springForce(anchor: anchor.position, free: jumper.position, velocity: actualVelocity, deltaTime: dt)
        let previousPosition = jumper.position
        var position = previousPosition
        RopeDynamics.integrate(position: &position, velocity: &velocity, force: force,
                               dt: dt, steeringSpeed: steeringSpeed)
        jumper.position = position
        jumper.setFlightLean(max(-1, min(1, (velocity.dx + steeringSpeed) / 450)))
        if flow.deadlineActive && flow.rescueRemaining <= realDelta {
            _ = flow.advance(dt, y: jumper.position.y, verticalSpeed: velocity.dy, targetY: nextLedge.grabPoint.y, realDelta: realDelta)
            finish()
            return
        }
        if flight, let trick = nextLedge.trickAlternative,
           let contact = trick.grabContact(from: previousPosition, to: jumper.position, velocity: velocity) {
            land(on: trick, contact: contact)
            return
        }
        let relativeStart = previousPosition + CGVector(dx: nextLedge.position.x - targetStartX, dy: 0)
        if flight, let contact = nextLedge.grabContact(from: relativeStart, to: jumper.position, velocity: velocity) {
            land(contact: contact)
            return
        }
        let event = flow.advance(dt, y: jumper.position.y, verticalSpeed: velocity.dy, targetY: nextLedge.grabPoint.y, realDelta: realDelta)
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

            if jumper.position.y < gameCamera.position.y - size.height / 2 - 100 { finish() }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !userPaused, appActive, !progress.awaitingChoice, let touch = touches.first, activeTouch == nil else { return }
        if ended { return }
        if steeringMode == .slide && (flight || flow.phase == .handoff) {
            guard steeringTouch == nil else { return }
            steeringTouch = touch
            steeringOrigin = touch.location(in: view).x
            return
        }
        guard flow.beginAim() else { return }
        activeTouch = touch
        touchOrigin = touch.location(in: self)
        jumperOrigin = jumper.position
        draggedDistance = 0
        drag = jumper.position
        launchHaptic.prepare()

    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = steeringTouch, touches.contains(touch) {
            slide.move(displacement: touch.location(in: view).x - steeringOrigin,
                       screenWidth: view?.bounds.width ?? size.width)
            return
        }
        guard let touch = activeTouch, touches.contains(touch) else { return }
        let movement = touch.location(in: self) - touchOrigin
        draggedDistance = max(draggedDistance, movement.length)
        drag = clamped(jumperOrigin + movement)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = steeringTouch, touches.contains(touch) {
            steeringTouch = nil
            slide.release()
            return
        }
        guard !userPaused, !ended, let touch = activeTouch, touches.contains(touch) else { return }
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

        rope.reset()
        rope.launchPulse()

    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = steeringTouch, touches.contains(touch) {
            steeringTouch = nil
            slide.release()
            return
        }
        guard let touch = activeTouch, touches.contains(touch) else { return }
        activeTouch = nil
        drag = nil
        aim.isHidden = true
        velocity = .zero
        flow.cancelAim()

    }
    private func clamped(_ point: CGPoint) -> CGPoint {
        let offset = point - anchor.position
        return anchor.position + offset.normalized() * min(offset.length, GameConstants.maxDragDistance)
    }

    private func updatePointsHUD() { publishHUD() }

    private func land(on chosen: LedgeNode? = nil, contact: CGPoint) {
        let destination = chosen ?? nextLedge!
        let tookTrick = destination.isTrickPlatform
        // Judge precision before snapping the climber to the platform center.
        let perfect = CatchRewards.isPerfect(contact: contact, centerX: destination.position.x,
                                             width: destination.size.width, verticalSpeed: velocity.dy)
        let award = rewards.catchPlatform(basePoints: destination.reward, perfect: perfect)
        if tookTrick { nextLedge.removeFromParent() }
        else { nextLedge.trickAlternative?.removeFromParent() }
        jumper.position = destination.grabPoint
        let oldAnchor = anchor!
        anchor = jumper
        jumper = oldAnchor
        anchor.setAnchored(true)
        jumper.setAnchored(false)
        velocity = .zero
        handoffStart = jumper.position
        handoffElapsed = 0
        tilt.stopSteering()
        current = destination
        let earned = award.points
        points += earned
        updatePointsHUD()
        upcoming.removeFirst()
        if tookTrick {
            // Regenerate from the chosen branch so subsequent jumps stay reachable.
            for ledge in upcoming {
                ledge.trickAlternative?.removeFromParent()
                ledge.removeFromParent()
            }
            upcoming.removeAll()
        }
        current.setTarget(false)
        celebrate(at: anchor.position, color: anchor.fillColor)
        anchor.run(.sequence([
            .scaleX(to: 1.15, y: 0.8, duration: 0.07),
            .scale(to: 0.95, duration: 0.14)
        ]), withKey: "landingSquash")
        happyTime = 0.65
        score += 1
        if score > best {
            celebratedRecord = true
            best = score
            UserDefaults.standard.set(best, forKey: progress.recordPrefix + ".height")
        }
        updateRunHUD()
        saveRunRecords()
        fillUpcoming()
        nextLedge = upcoming[0]
        handoffTarget = PartnerLaunch.startPosition(anchor: anchor.position, target: nextLedge.grabPoint)
        nextLedge.setTarget(true)
        flow.land()
        rescueWarningPlayed = false
        rope.reset()
        rope.pulse()
        updateRunHUD()
        sound.play(.grab, step: score + (award.perfect ? 2 : 0))
        if award.combo { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        else { UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: award.perfect ? 1 : 0.5) }
        let pop = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        if award.combo {
            pop.text = award.perfect ? "PERFECT • COMBO! +\(earned)" : "COMBO 5! +\(earned)"
        } else if award.perfect { pop.text = "PERFECT! +\(earned)" }
        else { pop.text = earned == 0 ? "0 • TRICK!" : "+\(earned)" }
        pop.fontSize = award.combo ? 18 : 22
        pop.fontColor = award.perfect || award.combo ? .systemYellow : .white
        pop.position = anchor.position + CGVector(dx: 0, dy: 35)
        pop.zPosition = 40
        addChild(pop)
        pop.run(.sequence([.group([.moveBy(x: 0, y: 45, duration: 0.8), .fadeOut(withDuration: 0.8)]), .removeFromParent()]))
        if progress.catchPlatform(height: score, streak: rewards.streak) { completeEscape() }
        saveRunRecords()
    }


    private func updateRunHUD() {
        let light = CGFloat(min(score, EscapeProgress.goal)) / CGFloat(EscapeProgress.goal)
        backdrop.alpha = 1 - light * 0.35
        backgroundColor = SKColor(red: 0.055 + light * 0.32, green: 0.075 + light * 0.23,
                                  blue: 0.16 + light * 0.18, alpha: 1)
    }

    private func saveRunRecords() {
        let defaults = UserDefaults.standard
        let prefix = progress.recordPrefix
        for (key, value) in [("height", score), ("score", points), ("combo", max(progress.longestCombo, rewards.streak))] {
            defaults.set(max(value, defaults.integer(forKey: prefix + "." + key)), forKey: prefix + "." + key)
        }
    }

    #if DEBUG
    // Exercise the real final-catch path without requiring 150 manual test jumps.
    private func prepareEscapeUITest() {
        for ledge in children.compactMap({ $0 as? LedgeNode }) { ledge.removeFromParent() }
        upcoming.removeAll()
        score = EscapeProgress.goal - 1
        current = spawner.startingLedge(y: size.height * 0.34)
        addChild(current)
        fillUpcoming()
        nextLedge = upcoming[0]
        anchor.position = current.grabPoint
        jumper.position = nextLedge.grabPoint
        flow.launch()
        land(contact: nextLedge.grabPoint)
    }
    #endif

    private func completeEscape() {
        activeTouch = nil
        drag = nil
        steeringTouch = nil
        slide.reset()
        tilt.stopSteering()
        aim.isHidden = true


        nextLedge.setTarget(false)
        motion.stopDeviceMotionUpdates()
        let defaults = UserDefaults.standard
        let key = progress.recordPrefix + ".escapeTime"
        let previous = defaults.double(forKey: key)
        if previous == 0 || progress.seconds < previous { defaults.set(progress.seconds, forKey: key) }
        mint.updatePersonality(.happy, lookingAt: current.grabPoint, deltaTime: 0)
        coral.updatePersonality(.happy, lookingAt: current.grabPoint, deltaTime: 0)


        // Bring both partners to the exit before offering the endless continuation.
        anchor.run(.move(to: current.grabPoint + CGVector(dx: -20, dy: 5), duration: 0.45))
        jumper.run(.move(to: current.grabPoint + CGVector(dx: 20, dy: 5), duration: 0.45))
        gameCamera.run(.moveTo(y: max(gameCamera.position.y, current.position.y + size.height * 0.12), duration: 0.4))
        run(.customAction(withDuration: 0.5) { [weak self] _, _ in
            guard let self else { return }
            self.rope.render(anchor: self.anchor.ropeAttachment, free: self.jumper.ropeAttachment)
        }, withKey: "exitRope")
        sound.play(.grab, step: 4)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        run(.sequence([.wait(forDuration: 0.6), .run { [weak self] in
            guard let self else { return }
            self.rope.render(anchor: self.anchor.ropeAttachment, free: self.jumper.ropeAttachment)
            self.publishHUD()
            self.escapeSummary = EscapeSummary(points: self.points, seconds: self.progress.seconds,
                longestCombo: self.progress.longestCombo, turbo: self.progress.usedTurbo)
        }]), withKey: "escapeCelebration")
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

    private func finish() {
        // JumpFlow may already be .over when its deadline expires. Guard the
        // presentation, not the phase, so every expiry still produces a result.
        guard runSummary == nil else { return }
        aim.isHidden = true
        flow.finish()
        sound.play(.end)


        mint.updatePersonality(.dizzy, lookingAt: coral.position, deltaTime: 0)
        coral.updatePersonality(.dizzy, lookingAt: mint.position, deltaTime: 0)


        activeTouch = nil
        drag = nil
        best = max(best, score)
        saveRunRecords()
        UserDefaults.standard.set(best, forKey: progress.recordPrefix + ".height")
        nextLedge.setTarget(false)
        runSummary = RunSummary(height: score, points: points, seconds: progress.seconds,
            longestCombo: max(progress.longestCombo, rewards.streak), turbo: progress.usedTurbo,
            endless: progress.endless, bestHeight: best)
        publishHUD()
    }
}
