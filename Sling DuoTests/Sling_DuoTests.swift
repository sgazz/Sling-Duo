import SpriteKit
import UIKit
import Testing
@testable import Sling_Duo

@MainActor
struct Sling_DuoTests {
    @Test func heroPosesLoadWithoutMovingTheSimulationPoint() {
        let scene = SKScene(size: CGSize(width: 390, height: 844))
        for hero in ClimberNode.Hero.allCases {
            let climber = ClimberNode(hero: hero)
            scene.addChild(climber)
            climber.position = CGPoint(x: 100, y: 200)
            climber.setAnchored(true)
            for expression: ClimberNode.Expression in [.calm, .strained, .flying, .happy, .dizzy] {
                climber.updatePersonality(expression, lookingAt: .zero, deltaTime: 0)
                let artwork = climber.childNode(withName: "heroArtwork") as! SKSpriteNode
                #expect(artwork.texture != nil)
                #expect(artwork.size.width > 30 && artwork.size.height > 30)
                #expect(climber.position == CGPoint(x: 100, y: 200))
                #expect(abs(climber.ropeAttachment.x - 100) < 1)
                #expect(abs(climber.ropeAttachment.y - 200) < 20)
            }
            for state in ["Idle", "Anchored", "Pull", "Flight", "Catch", "Miss"] {
                let color = hero == .cyan ? "Cyan" : "Orange"
                #expect(UIImage(named: "Hero" + color + state) != nil)
            }
        }
    }

    @Test func routeFillsPhoneAndTabletAndPauseFreezesSimulation() {
        for size in [CGSize(width: 390, height: 844), CGSize(width: 768, height: 1024)] {
            let scene = GameScene(size: size)
            let view = SKView(frame: CGRect(origin: .zero, size: size))
            view.presentScene(scene)
            let ledges = scene.children.compactMap { $0 as? LedgeNode }
            #expect(ledges.count >= 4)
            #expect((ledges.map { $0.position.y }.max() ?? 0) > size.height)
            #expect(ledges.filter { $0.childNode(withName: "targetMarker") != nil }.count == 1)
            scene.setGameplayPaused(true)
            let positions = ledges.map { $0.position }
            scene.update(1)
            scene.update(5)
            #expect(positions == ledges.map { $0.position })
            scene.restartFromMenu()
            #expect(scene.isPaused)
            view.presentScene(nil)
        }
    }

    @Test func deadlinePersistsThroughReleaseAndRepeatedMissesUntilCatch() {
        var flow = JumpFlow()
        _ = flow.beginAim()
        _ = flow.advance(1, y: 0, verticalSpeed: 0, targetY: 100)
        flow.launch()
        _ = flow.advance(0.5, y: 200, verticalSpeed: 100, targetY: 100)
        #expect(abs(flow.rescueRemaining - 2.5) < 0.001)
        flow.miss()
        #expect(abs(flow.rescueRemaining - 2.5) < 0.001)
        _ = flow.beginAim()
        flow.launch()
        _ = flow.advance(0.5, y: 200, verticalSpeed: 100, targetY: 100)
        flow.miss()
        #expect(abs(flow.rescueRemaining - 2) < 0.001)
        flow.land()
        #expect(flow.rescueRemaining == JumpTuning.rescueDuration)
        #expect(!flow.deadlineActive)
    }

    @Test func slideSteeringIsBoundedResponsiveAndFrameIndependent() {
        func speed(rate: Double) -> CGFloat {
            var steering = SlideSteering()
            steering.move(displacement: 500, screenWidth: 390)
            for _ in 0..<Int(rate) { _ = steering.update(dt: 1 / rate) }
            return steering.speed
        }
        #expect(abs(speed(rate: 30) - speed(rate: 120)) < 0.01)
        #expect(speed(rate: 60) <= JumpTuning.maxTiltSpeed)
        var steering = SlideSteering()
        steering.move(displacement: -100, screenWidth: 768)
        for _ in 0..<30 { _ = steering.update(dt: 1.0 / 60) }
        #expect(steering.speed < -250)
        steering.release()
        for _ in 0..<30 { _ = steering.update(dt: 1.0 / 60) }
        #expect(abs(steering.speed) < 1)
    }

    @Test func bonusHasReachableNonoverlappingZeroPointAlternative() {
        for width: CGFloat in [240, 390, 768] {
            let spawner = LedgeSpawner(sceneWidth: width)
            for _ in 0..<40 {
                var base = spawner.startingLedge(y: 100)
                for height in 100..<125 {
                    let bonus = spawner.nextLedge(above: base, score: height)
                    if bonus.isMovingPlatform {
                        let trick = try! #require(bonus.trickAlternative)
                        #expect(trick.reward == 0)
                        #expect(trick.position.y == bonus.position.y)
                        #expect(abs(trick.position.x - base.position.x) <= 135.001)
                        #expect(abs(bonus.position.x - base.position.x) <= 135.001)
                        let gap = abs(trick.position.x - bonus.position.x) - 18
                        #expect(gap > (trick.size.width + bonus.size.width) * 0.55)
                    } else { #expect(bonus.trickAlternative == nil) }
                    base = bonus
                }
            }
        }
    }

    @Test func precisionUsesActualContactBeforeSnap() {
        let ledge = LedgeNode(center: CGPoint(x: 195, y: 300))
        let center = ledge.grabPoint
        let contact = ledge.grabContact(from: center + CGVector(dx: 0, dy: 70),
                                        to: center + CGVector(dx: 0, dy: -70),
                                        velocity: CGVector(dx: 0, dy: -900))!
        #expect(CatchRewards.isPerfect(contact: contact, centerX: 195, width: ledge.size.width, verticalSpeed: -900))
        #expect(!CatchRewards.isPerfect(contact: contact + CGVector(dx: ledge.size.width * 0.3, dy: 0),
                                       centerX: 195, width: ledge.size.width, verticalSpeed: -900))
        #expect(!CatchRewards.isPerfect(contact: contact, centerX: 195, width: ledge.size.width, verticalSpeed: 50))
    }

    @Test func comboAwardsOnlyEveryFifthCatchAndMissBreaksStreak() {
        var rewards = CatchRewards()
        for _ in 0..<4 {
            let award = rewards.catchPlatform(basePoints: 1, perfect: false)
            #expect(award.points == 1 && !award.combo)
        }
        let fifth = rewards.catchPlatform(basePoints: 2, perfect: true)
        #expect(fifth.points == 5 && fifth.combo && fifth.perfect)
        rewards.miss()
        #expect(rewards.streak == 0)
        let saved = rewards.catchPlatform(basePoints: 1, perfect: true)
        #expect(saved.points == 2 && !saved.combo)
        let trick = rewards.catchPlatform(basePoints: 0, perfect: true)
        #expect(trick.points == 0 && !trick.perfect && !trick.combo)
        #expect(rewards.streak == 0)
    }

    @Test func turboRampsEveryFiveSecondsAndStopsAtTripleSpeed() {
        var tempo = ExperimentalTempo()
        #expect(tempo.multiplier == 1)
        tempo.advance(4.99)
        #expect(tempo.multiplier == 1)
        tempo.advance(0.01)
        #expect(abs(tempo.multiplier - 1.05) < 0.0001)
        tempo.advance(95)
        #expect(tempo.multiplier == 2)
        tempo.advance(100)
        #expect(tempo.multiplier == 3)
        tempo.advance(1000)
        #expect(tempo.multiplier == 3)
        tempo.reset()
        #expect(tempo.multiplier == 1)
    }

    @Test func turboDoesNotAccelerateTheRealTimeDeadline() {
        var flow = JumpFlow()
        _ = flow.beginAim()
        flow.launch()
        _ = flow.advance(2, y: 200, verticalSpeed: 100, targetY: 100, realDelta: 1)
        #expect(flow.rescueRemaining == 3)
        let expired = flow.advance(6, y: 200, verticalSpeed: 100, targetY: 100, realDelta: 3)
        #expect(expired == .rescueExpired)
    }

    @Test func escapeCompletesOnceAndEndlessPreservesRunStatistics() {
        var progress = EscapeProgress()
        progress.advance(120)
        let before = progress.catchPlatform(height: 149, streak: 12)
        #expect(!before)
        progress.advance(1)
        let victory = progress.catchPlatform(height: 150, streak: 13)
        #expect(victory && progress.awaitingChoice)
        #expect(progress.longestCombo == 13)
        progress.advance(60)
        #expect(progress.seconds == 121)
        progress.keepClimbing()
        #expect(progress.endless && !progress.awaitingChoice)
        progress.advance(1)
        let again = progress.catchPlatform(height: 151, streak: 14)
        #expect(!again && progress.seconds == 122)
        #expect(progress.longestCombo == 14)
        #expect(EscapeProgress.timeText(122) == "2:02")
        progress = EscapeProgress()
        #expect(!progress.completed && progress.seconds == 0 && progress.longestCombo == 0)
    }

    @Test func turboRecordsStaySeparateEvenIfDisabledMidRun() {
        var progress = EscapeProgress()
        let normal = progress.recordPrefix
        progress.markTurbo()
        #expect(progress.recordPrefix != normal)
        #expect(progress.usedTurbo)
        progress.keepClimbing()
        #expect(progress.usedTurbo)
        #expect(EscapeProgress(turbo: true).recordPrefix == progress.recordPrefix)
        #expect(EscapeProgress().recordPrefix == normal)
    }

    @Test func exitAppearsOnlyAtEscapeGoal() {
        let spawner = LedgeSpawner(sceneWidth: 390)
        let base = spawner.startingLedge(y: 100)
        for height in [148, 149, 150] {
            let next = spawner.nextLedge(above: base, score: height)
            #expect((next.childNode(withName: "escapeExit") != nil) == (height == 149))
        }
    }

    @Test func deadlineExpiresAtFourRealSecondsIncludingFractionalTurboSteps() {
        for multiplier in [1.0, 1.05, 2, 3] {
            var flow = JumpFlow()
            _ = flow.beginAim()
            var elapsed = 0.0
            while elapsed < 4 {
                let realStep = min(1.0 / 120 / multiplier, 4 - elapsed)
                _ = flow.advance(1.0 / 120, y: 0, verticalSpeed: 0, targetY: 100, realDelta: realStep)
                elapsed += realStep
            }
            #expect(flow.rescueRemaining == 0)
            #expect(flow.phase == .over)
        }
    }

    @Test func holdingRescueAimStillConsumesTheDeadline() {
        var flow = JumpFlow()
        flow.launch()
        flow.miss()
        let began = flow.beginAim()
        #expect(began)
        _ = flow.advance(1.5, y: 0, verticalSpeed: 0, targetY: 100)
        #expect(abs(flow.rescueRemaining - 2.5) < 0.001)
        flow.cancelAim()
        let again = flow.beginAim()
        #expect(again)
        let expired = flow.advance(2.6, y: 0, verticalSpeed: 0, targetY: 100)
        #expect(expired == .rescueExpired)
        #expect(flow.phase == .over)
        var firstLaunch = JumpFlow()
        _ = firstLaunch.beginAim()
        _ = firstLaunch.advance(10, y: 0, verticalSpeed: 0, targetY: 100)
        #expect(firstLaunch.phase == .over)
    }

    @Test func movingPlatformsRewardDoubleAndStopAfterLanding() {
        for width: CGFloat in [240, 390, 768] {
            let spawner = LedgeSpawner(sceneWidth: width)
            var ledge = spawner.startingLedge(y: 100)
            for height in 0..<150 {
                let next = spawner.nextLedge(above: ledge, score: height)
                if next.isMovingPlatform {
                    #expect(height >= 100)
                    #expect(!next.isPrecisionPlatform)
                    #expect(next.reward == 2)
                    let center = next.position.x
                    next.setTarget(true)
                    for _ in 0..<480 {
                        next.advanceMotion(1.0 / 120)
                        #expect(abs(next.position.x - center) <= 18.001)
                        #expect(next.position.x - next.size.width / 2 >= 0)
                        #expect(next.position.x + next.size.width / 2 <= width)
                    }
                    next.setTarget(false)
                    let stopped = next.position
                    next.advanceMotion(1)
                    #expect(next.position == stopped)
                } else { #expect(next.reward == 1) }
                ledge = next
            }
        }
    }

    @Test func restartingRopeClearsPreviousFailure() {
        let rope = RubberRopeSystem()
        _ = rope.springForce(anchor: .zero, free: CGPoint(x: 0, y: -500), velocity: .zero,
                             deltaTime: GameConstants.overstretchGrace + 0.1)
        #expect(rope.didOverstretchTooLong)
        rope.reset()
        #expect(!rope.didOverstretchTooLong)
        #expect(rope.tension == 0)
    }

    @Test func targetDecorationDoesNotChangeGrabRegion() {
        let ledge = LedgeNode(center: CGPoint(x: 195, y: 300))
        let point = ledge.grabPoint
        let descending = CGVector(dx: 0, dy: -100)
        #expect(ledge.canGrab(climberPosition: point, velocity: descending))
        ledge.setTarget(true)
        ledge.setTarget(true)
        #expect(ledge.children.filter { $0.name == "targetMarker" }.count == 1)
        #expect(ledge.grabPoint == point)
        #expect(ledge.canGrab(climberPosition: point, velocity: descending))
        ledge.setTarget(false)
        #expect(ledge.childNode(withName: "targetMarker") == nil)
        #expect(!ledge.canGrab(climberPosition: point + CGVector(dx: 300, dy: 0), velocity: descending))
    }

    @Test func fastDescentGrabsBetweenPhysicsSteps() {
        let ledge = LedgeNode(center: CGPoint(x: 195, y: 300))
        let start = ledge.grabPoint + CGVector(dx: 0, dy: 70)
        let end = ledge.grabPoint + CGVector(dx: 0, dy: -70)
        let velocity = CGVector(dx: 0, dy: -1800)
        #expect(!ledge.canGrab(climberPosition: start, velocity: velocity))
        #expect(!ledge.canGrab(climberPosition: end, velocity: velocity))
        #expect(ledge.canGrab(from: start, to: end, velocity: velocity))
        #expect(!ledge.canGrab(from: end, to: start, velocity: CGVector(dx: 0, dy: 1800)))
        #expect(!ledge.canGrab(from: start + CGVector(dx: 150, dy: 0),
                              to: end + CGVector(dx: 150, dy: 0), velocity: velocity))
    }

    @Test func diagonalNearMissDoesNotGrab() {
        let ledge = LedgeNode(center: CGPoint(x: 195, y: 300))
        // The bounding box overlaps the platform, but the actual segment misses it.
        let start = ledge.grabPoint + CGVector(dx: -100, dy: 0)
        let end = ledge.grabPoint + CGVector(dx: 0, dy: 140)
        #expect(!ledge.canGrab(from: start, to: end, velocity: CGVector(dx: 80, dy: 100)))
    }

    @Test func difficultyRisesGraduallyAndStopsIncreasing() {
        let easy = ClimbDifficulty(score: 3)
        let hard = ClimbDifficulty(score: 30)
        #expect(easy.minimumWidth > hard.minimumWidth)
        #expect(easy.maximumGap < hard.maximumGap)
        for score in 4...100 {
            let previous = ClimbDifficulty(score: score - 1)
            let current = ClimbDifficulty(score: score)
            #expect(current.minimumWidth <= previous.minimumWidth)
            #expect(previous.minimumWidth - current.minimumWidth <= 1.5)
            #expect(current.maximumGap >= previous.maximumGap)
            #expect(current.maximumGap <= 185)
            #expect(current.horizontalReach <= 135)
        }
        #expect(ClimbDifficulty(score: 100).minimumWidth == hard.minimumWidth)
    }

    @Test func generatedRoutesStayInsideScreenAndWithinRopeReach() {
        for width: CGFloat in [240, 390, 768] {
            let spawner = LedgeSpawner(sceneWidth: width)
            var ledge = spawner.startingLedge(y: 200)
            for score in 0..<100 {
                let next = spawner.nextLedge(above: ledge, score: score)
                #expect(next.position.x - next.size.width / 2 >= 19.9)
                #expect(next.position.x + next.size.width / 2 <= width - 19.9)
                #expect(next.position.y > ledge.position.y)
                #expect((next.grabPoint - ledge.grabPoint).length < GameConstants.maxStretchLength)
                if score < 3 { #expect(next.size.width == 160) }
                if score >= 3 {
                    #expect(abs(next.position.x - ledge.position.x) > next.size.width * 0.55 + 7)
                }
                ledge = next
            }
        }
    }

    @Test func chainAllowsFingerOnlyAtStartAndAfterMiss() {
        var flow = JumpFlow()
        let check1 = flow.beginAim(); #expect(check1)
        flow.launch()
        let check2 = !flow.beginAim(); #expect(check2)
        flow.land()
        #expect(flow.phase == .handoff)
        let check3 = !flow.beginAim(); #expect(check3)
        let check4 = flow.advance(JumpTuning.handoffDuration - 0.01, y: 0, verticalSpeed: 0, targetY: 145) == .none; #expect(check4)
        let check5 = flow.advance(0.02, y: 0, verticalSpeed: 0, targetY: 145) == .launchPartner; #expect(check5)
        #expect(flow.phase == .flying)
        let check6 = flow.advance(0.2, y: 90, verticalSpeed: -100, targetY: 145) == .missed; #expect(check6)
        #expect(flow.phase == .rescue)
        let check7 = flow.beginAim(); #expect(check7)
        flow.launch()
        #expect(flow.phase == .flying)
    }

    @Test func rescueHasOneWindowAndCancelDoesNotRefillIt() {
        var flow = JumpFlow()
        flow.launch()
        flow.miss()
        _ = flow.advance(1, y: 0, verticalSpeed: -100, targetY: 145)
        let remaining = flow.rescueRemaining
        let check8 = flow.beginAim(); #expect(check8)
        flow.cancelAim()
        #expect(flow.phase == .rescue)
        #expect(flow.rescueRemaining == remaining)
        let check9 = flow.advance(remaining + 0.1, y: 0, verticalSpeed: 0, targetY: 145) == .rescueExpired; #expect(check9)
        let check10 = !flow.beginAim(); #expect(check10)
        flow.reset()
        let check11 = flow.beginAim(); #expect(check11)
    }

    @Test func risingBelowTargetIsNotAMiss() {
        var flow = JumpFlow()
        flow.launch()
        let check12 = flow.advance(0.5, y: 20, verticalSpeed: 200, targetY: 145) == .none; #expect(check12)
        #expect(flow.phase == .flying)
    }

    @Test func tiltCalibratesBoundsAndReturnsToNeutral() {
        var tilt = TiltSteering()
        tilt.calibrate(0.12)
        for _ in 0..<120 { let check13 = abs(tilt.update(sample: 0.12, dt: 1.0 / 120)) < 0.001; #expect(check13) }
        for _ in 0..<120 { _ = tilt.update(sample: 0.7, dt: 1.0 / 120) }
        #expect(tilt.speed > 250 && tilt.speed <= JumpTuning.maxTiltSpeed)
        for _ in 0..<120 { _ = tilt.update(sample: -0.7, dt: 1.0 / 120) }
        #expect(tilt.speed < -250 && tilt.speed >= -JumpTuning.maxTiltSpeed)
        for _ in 0..<240 { _ = tilt.update(sample: 0.12, dt: 1.0 / 120) }
        #expect(abs(tilt.speed) < 0.1)
        let check14 = tilt.update(sample: nil, dt: 1.0 / 120) == 0; #expect(check14)
    }

    @Test func tiltResponseIsIndependentOfFrameRate() {
        var slow = TiltSteering()
        var fast = TiltSteering()
        slow.calibrate(0)
        fast.calibrate(0)
        for _ in 0..<60 { _ = slow.update(sample: 0.2, dt: 1.0 / 60) }
        for _ in 0..<120 { _ = fast.update(sample: 0.2, dt: 1.0 / 120) }
        #expect(abs(slow.speed - fast.speed) < 1)
    }

    @Test func automaticLaunchClearsGeneratedPlatformHeights() {
        for gap: CGFloat in [145, 165, 185] {
            for offset: CGFloat in [-125, 0, 125] {
                let anchor = CGPoint(x: 195, y: 500)
                var position = anchor + CGVector(dx: -30, dy: -125)
                let target = anchor + CGVector(dx: offset, dy: gap)
                var velocity = PartnerLaunch.velocity(from: position, anchor: anchor, target: target)
                #expect(velocity.dy <= 3000)
                var apex = position.y
                var crossedOnDescent = false
                for _ in 0..<240 {
                    let previousY = position.y
                    RopeDynamics.step(position: &position, velocity: &velocity, anchor: anchor, dt: 1.0 / 120)
                    apex = max(apex, position.y)
                    if velocity.dy < 0 && previousY >= target.y && position.y < target.y {
                        crossedOnDescent = true
                        break
                    }
                }
                #expect(apex >= target.y + JumpTuning.autoClearance - 1)
                #expect(crossedOnDescent)
            }
        }
    }

    @Test func automaticReleaseKeepsBeatWithoutAimingForPlayer() {
        let anchor = CGPoint(x: 195, y: 500)
        var arrivals: [TimeInterval] = []
        var landingX: [CGFloat] = []
        for gap: CGFloat in [145, 165, 185] {
            for offset: CGFloat in [-125, 125] {
                let target = anchor + CGVector(dx: offset, dy: gap)
                var position = PartnerLaunch.startPosition(anchor: anchor, target: target)
                var speed = PartnerLaunch.velocity(from: position, anchor: anchor, target: target)
                for tick in 1...240 {
                    RopeDynamics.step(position: &position, velocity: &speed, anchor: anchor, dt: 1.0 / 120)
                    if speed.dy < 170 && abs(position.y - target.y) < GameConstants.grabDistance {
                        arrivals.append(Double(tick) / 120)
                        landingX.append(position.x - anchor.x)
                        #expect(abs(position.x - anchor.x) < 0.001)
                        break
                    }
                }
            }
        }
        #expect(arrivals.count == 6)
        #expect((arrivals.max() ?? 100) - (arrivals.min() ?? 0) < 0.12)
        #expect((arrivals.max() ?? 100) < 0.8)
        if landingX.count == 6 {
            for pair in stride(from: 0, to: 6, by: 2) {
                #expect(abs(landingX[pair] + landingX[pair + 1]) < 0.1)
            }
        }
    }

    @Test func tiltRespondsAndBrakesWithinTwoTenthsOfASecond() {
        var tilt = TiltSteering()
        tilt.calibrate(0)
        for _ in 0..<24 { _ = tilt.update(sample: 0.2, dt: 1.0 / 120) }
        let heldSpeed = (0.2 - JumpTuning.tiltDeadZone) / (JumpTuning.fullTilt - JumpTuning.tiltDeadZone) * JumpTuning.maxTiltSpeed
        #expect(tilt.speed > heldSpeed * 0.8)
        for _ in 0..<24 { _ = tilt.update(sample: 0, dt: 1.0 / 120) }
        #expect(abs(tilt.speed) < heldSpeed * 0.1)
        // Input warms during the handoff before movement starts again.
        tilt.stopSteering()
        for _ in 0..<22 { _ = tilt.update(sample: 0.2, dt: 1.0 / 120) }
        #expect(tilt.speed > heldSpeed * 0.75)
    }

    @Test func cameraDoesNotDropOnMissAndMatchesFrameRates() {
        var slow: CGFloat = 422
        var fast: CGFloat = 422
        for _ in 0..<60 {
            slow = ClimbCamera.nextY(current: slow, anchorY: 700, jumperY: 850, height: 844, inFlight: true, dt: 1.0 / 60)
        }
        for _ in 0..<120 {
            fast = ClimbCamera.nextY(current: fast, anchorY: 700, jumperY: 850, height: 844, inFlight: true, dt: 1.0 / 120)
        }
        #expect(abs(slow - fast) < 0.01)
        let afterMiss = ClimbCamera.nextY(current: slow, anchorY: 700, jumperY: 500, height: 844, inFlight: false, dt: 1.0 / 60)
        #expect(afterMiss >= slow)
    }

    private func simulateJump(anchor: CGPoint, target: LedgeNode, input: CGFloat) -> Bool {
        var position = PartnerLaunch.startPosition(anchor: anchor, target: target.grabPoint)
        var velocity = PartnerLaunch.velocity(from: position, anchor: anchor, target: target.grabPoint)
        var steering = TiltSteering()
        steering.calibrate(0)
        for tick in 0..<240 {
            let previous = position
            // Allow a human reaction delay rather than steering before launch.
            let horizontal = steering.update(sample: tick >= 12 ? input : 0, dt: 1.0 / 120)
            RopeDynamics.step(position: &position, velocity: &velocity, anchor: anchor,
                              dt: 1.0 / 120, steeringSpeed: horizontal)
            if target.canGrab(from: previous, to: position, velocity: velocity) { return true }
            if velocity.dy < 0 && position.y < target.grabPoint.y - GameConstants.grabDistance { return false }
        }
        return false
    }

    @Test func noInputCannotTurnIntoFiveHundredAutomaticJumps() {
        for width: CGFloat in [240, 390, 768] {
            let spawner = LedgeSpawner(sceneWidth: width)
            var ledge = spawner.startingLedge(y: 200)
            var automaticGrabs = 0
            for score in 0..<500 {
                let next = spawner.nextLedge(above: ledge, score: score)
                if !simulateJump(anchor: ledge.grabPoint, target: next, input: 0) { break }
                automaticGrabs += 1
                ledge = next
            }
            #expect(automaticGrabs <= 3)
        }
    }

    @Test func challengePlatformsRequireCorrectTiltAndRemainReachable() {
        for width: CGFloat in [240, 390, 768] {
            let spawner = LedgeSpawner(sceneWidth: width)
            for score in [3, 4, 9, 30, 80, 500] {
                for fraction: CGFloat in [0.3, 0.5, 0.7] {
                    let ledge = LedgeNode(center: CGPoint(x: width * fraction, y: 500))
                    let next = spawner.nextLedge(above: ledge, score: score)
                    let direction: CGFloat = next.position.x > ledge.position.x ? 1 : -1
                    let neutralHits = simulateJump(anchor: ledge.grabPoint, target: next, input: 0)
                    let correctTiltHits = simulateJump(anchor: ledge.grabPoint, target: next, input: direction * 0.28)
                    let wrongTiltHits = simulateJump(anchor: ledge.grabPoint, target: next, input: -direction * 0.28)
                    #expect(!neutralHits)
                    #expect(correctTiltHits)
                    #expect(!wrongTiltHits)
                }
            }
        }
    }

    @Test func smallPlatformsAppearAfterIntroAndNeverBackToBack() {
        let spawner = LedgeSpawner(sceneWidth: 390)
        var ledge = spawner.startingLedge(y: 200)
        var previousWasSmall = false
        var smallCount = 0
        for score in 0..<50 {
            let next = spawner.nextLedge(above: ledge, score: score)
            if next.isPrecisionPlatform {
                #expect(score >= 6)
                #expect(!previousWasSmall)
                #expect(next.size.width >= 62 && next.size.width <= 80)
                #expect(abs(next.position.x - ledge.position.x) <= 95.01)
                #expect(next.position.y - ledge.position.y <= 155.01)
                let direction: CGFloat = next.position.x > ledge.position.x ? 1 : -1
                let canReach = simulateJump(anchor: ledge.grabPoint, target: next, input: direction * 0.28)
                let autoReach = simulateJump(anchor: ledge.grabPoint, target: next, input: 0)
                #expect(canReach)
                #expect(!autoReach)
                smallCount += 1
            }
            previousWasSmall = next.isPrecisionPlatform
            ledge = next
        }
        #expect(smallCount == 9)
    }

    @Test func smallPlatformActuallyRequiresMorePreciseLanding() {
        let center = CGPoint(x: 195, y: 300)
        let normal = LedgeNode(center: center, size: CGSize(width: 126, height: 18))
        let small = LedgeNode(center: center, size: CGSize(width: 64, height: 18), isPrecision: true)
        let velocity = CGVector(dx: 0, dy: -100)
        let offCenter = small.grabPoint + CGVector(dx: 45, dy: 0)
        #expect(normal.canGrab(climberPosition: offCenter, velocity: velocity))
        #expect(!small.canGrab(climberPosition: offCenter, velocity: velocity))
        #expect(small.canGrab(climberPosition: small.grabPoint, velocity: velocity))
    }

    @Test func stoneVariantsLoadAndPreserveThePlayableFootprint() {
        for precision in [false, true] {
            let size = CGSize(width: precision ? 64 : 126, height: 18)
            let assets = precision ? PlatformArtwork.precision : PlatformArtwork.normal
            for index in 0..<3 {
                #expect(UIImage(named: assets[index].name) != nil)
                let ledge = LedgeNode(center: CGPoint(x: 195, y: 300), size: size,
                                      isPrecision: precision, artVariant: index)
                let art = ledge.childNode(withName: "platformArtwork") as? SKSpriteNode
                #expect(art != nil)
                #expect((art?.size.width ?? 0) >= size.width)
                #expect((art?.size.width ?? 1000) <= size.width * 1.03)
                let grab = ledge.grabPoint
                #expect(grab == CGPoint(x: 195, y: 323))
                #expect(ledge.canGrab(climberPosition: grab, velocity: CGVector(dx: 0, dy: -100)))
                #expect(!ledge.canGrab(climberPosition: grab + CGVector(dx: size.width * 0.65, dy: 0),
                                      velocity: CGVector(dx: 0, dy: -100)))
                ledge.setTarget(true)
                #expect(ledge.grabPoint == grab)
            }
        }
    }
}
