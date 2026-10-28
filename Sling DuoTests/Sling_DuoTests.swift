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
