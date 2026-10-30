import CoreGraphics
import Foundation

enum JumpTuning {
    static let handoffDuration: TimeInterval = 0.18
    static let rescueDuration: TimeInterval = 4
    static let autoClearance: CGFloat = 55
    static let maxTiltSpeed: CGFloat = 280
    static let tiltDeadZone: CGFloat = 0.035
    static let fullTilt: CGFloat = 0.32
    static let tiltInputRate: Double = 20
    static let tiltResponseRate: Double = 18
    static let tiltBrakeRate: Double = 28
    static let cameraFollowRate: Double = 4.5
}

struct JumpFlow {
    enum Phase { case ready, aiming, flying, handoff, rescue, over }
    enum Event { case none, launchPartner, missed, rescueExpired }
    private(set) var phase: Phase = .ready
    private(set) var rescueRemaining = JumpTuning.rescueDuration
    private(set) var deadlineActive = false
    private var elapsed: TimeInterval = 0
    private var aimOrigin: Phase = .ready

    var isRescuing: Bool { deadlineActive && phase != .over }

    mutating func reset() { self = JumpFlow() }
    mutating func beginAim() -> Bool {
        guard phase == .ready || phase == .rescue else { return false }
        aimOrigin = phase
        deadlineActive = true
        phase = .aiming
        return true
    }
    mutating func cancelAim() { if phase == .aiming { phase = aimOrigin } }
    mutating func launch() { phase = .flying; elapsed = 0 }
    mutating func land() {
        phase = .handoff; elapsed = 0
        rescueRemaining = JumpTuning.rescueDuration
        deadlineActive = false
    }
    mutating func finish() { phase = .over }
    mutating func miss() {
        guard phase == .flying else { return }
        phase = .rescue
        deadlineActive = true
    }
    mutating func advance(_ dt: TimeInterval, y: CGFloat, verticalSpeed: CGFloat, targetY: CGFloat, realDelta: TimeInterval? = nil) -> Event {
        if isRescuing {
            let remaining = rescueRemaining - max(0, realDelta ?? dt)
            // Avoid a residual fraction rounding up to 0.1s at the deadline.
            rescueRemaining = remaining <= 0.000000001 ? 0 : remaining
            if rescueRemaining == 0 { finish(); return .rescueExpired }
        }
        switch phase {
        case .handoff:
            elapsed += dt
            if elapsed >= JumpTuning.handoffDuration {
                launch()
                return .launchPartner
            }
        case .flying:
            elapsed += dt
            if elapsed > 0.15 && verticalSpeed < 0 && y < targetY - GameConstants.grabDistance {
                miss()
                return .missed
            }
        default: break
        }
        return .none
    }
}

enum SteeringMode: String { case tilt, slide }

struct SlideSteering {
    private(set) var speed: CGFloat = 0
    private var input: CGFloat = 0
    mutating func move(displacement: CGFloat, screenWidth: CGFloat) {
        input = max(-1, min(1, displacement / max(40, min(90, screenWidth * 0.18))))
    }
    mutating func release() { input = 0 }
    mutating func reset() { self = SlideSteering() }
    mutating func update(dt: TimeInterval) -> CGFloat {
        let desired = input * JumpTuning.maxTiltSpeed
        let rate = desired * speed < 0 || abs(desired) < abs(speed)
            ? JumpTuning.tiltBrakeRate : JumpTuning.tiltResponseRate
        speed += (desired - speed) * CGFloat(1 - exp(-rate * max(0, dt)))
        return speed
    }
}

struct TiltSteering {
    private var neutral: CGFloat?
    private var filtered: CGFloat = 0
    private(set) var speed: CGFloat = 0

    mutating func reset() { self = TiltSteering() }
    mutating func stopSteering() { filtered = 0; speed = 0 }
    mutating func calibrate(_ sample: CGFloat?) {
        neutral = sample
        filtered = 0
        speed = 0
    }
    mutating func update(sample: CGFloat?, dt: TimeInterval) -> CGFloat {
        guard let sample else { speed = 0; return 0 }
        if neutral == nil { calibrate(sample) }
        let relative = sample - (neutral ?? sample)
        filtered += (relative - filtered) * CGFloat(1 - exp(-JumpTuning.tiltInputRate * dt))
        let magnitude = max(0, abs(filtered) - JumpTuning.tiltDeadZone)
        let normalized = min(1, magnitude / (JumpTuning.fullTilt - JumpTuning.tiltDeadZone))
        let desired = normalized * (filtered < 0 ? -1 : 1) * JumpTuning.maxTiltSpeed
        let braking = abs(desired) < abs(speed) || desired * speed < 0
        let response = braking ? JumpTuning.tiltBrakeRate : JumpTuning.tiltResponseRate
        speed += (desired - speed) * CGFloat(1 - exp(-response * dt))
        return speed
    }
}

// Shared by live rope physics and the launch solver; no rendering or mutable state.
enum RopeDynamics {
    static func force(anchor: CGPoint, free: CGPoint, velocity: CGVector) -> CGVector {
        let offset = anchor - free
        let distance = offset.length
        guard distance > GameConstants.restLength + GameConstants.ropeSlackBeforePull else { return .zero }
        let direction = offset.normalized()
        let stretch = min(distance - GameConstants.restLength - GameConstants.ropeSlackBeforePull,
                          GameConstants.maxStretchLength - GameConstants.restLength)
        let ratio = max(0, min(1, stretch / (GameConstants.maxStretchLength - GameConstants.restLength)))
        let radialSpeed = velocity.dx * direction.dx + velocity.dy * direction.dy
        let pull = stretch * GameConstants.ropeSpringStrength * (0.2 + ratio * ratio)
            - radialSpeed * GameConstants.ropeDamping
        return direction * max(0, pull)
    }
    static func step(position: inout CGPoint, velocity: inout CGVector, anchor: CGPoint,
                     dt: TimeInterval, steeringSpeed: CGFloat = 0) {
        let actualVelocity = velocity + CGVector(dx: steeringSpeed, dy: 0)
        let force = GameConstants.gravity + self.force(anchor: anchor, free: position, velocity: actualVelocity)
        integrate(position: &position, velocity: &velocity, force: force, dt: dt, steeringSpeed: steeringSpeed)
    }

    static func integrate(position: inout CGPoint, velocity: inout CGVector, force: CGVector,
                          dt: TimeInterval, steeringSpeed: CGFloat = 0) {
        velocity += force * CGFloat(dt)
        velocity = velocity * CGFloat(pow(Double(GameConstants.damping), dt * 60))
        position = position + (velocity + CGVector(dx: steeringSpeed, dy: 0)) * CGFloat(dt)
    }

}

enum PartnerLaunch {
    static func startPosition(anchor: CGPoint, target: CGPoint) -> CGPoint {
        // Vertical handoff preserves the beat; horizontal aiming belongs to tilt.
        anchor + CGVector(dx: 0, dy: -125)
    }

    static func velocity(from start: CGPoint, anchor: CGPoint, target: CGPoint) -> CGVector {
        let horizontal: CGFloat = 0
        var lower: CGFloat = 350
        var upper: CGFloat = 3000
        // Match a consistent apex clearance using the actual spring and damping.
        for _ in 0..<12 {
            let vertical = (lower + upper) / 2
            var position = start
            var speed = CGVector(dx: horizontal, dy: vertical)
            var apex = start.y
            for _ in 0..<240 {
                RopeDynamics.step(position: &position, velocity: &speed, anchor: anchor, dt: 1.0 / 120)
                apex = max(apex, position.y)
                if speed.dy < 0 { break }
            }
            if apex < target.y + JumpTuning.autoClearance { lower = vertical } else { upper = vertical }
        }
        return CGVector(dx: horizontal, dy: upper)
    }
}

// A little upward anticipation spreads camera movement across the flight.
// Never move down on a miss; the player retains a stable frame for the rescue.
enum ClimbCamera {
    static func nextY(current: CGFloat, anchorY: CGFloat, jumperY: CGFloat,
                      height: CGFloat, inFlight: Bool, dt: TimeInterval) -> CGFloat {
        let lead = inFlight ? max(0, min(60, (jumperY - anchorY) * 0.25)) : 0
        let target = max(height / 2, anchorY + height * 0.15 + lead)
        return max(current, current + (target - current) * CGFloat(1 - exp(-JumpTuning.cameraFollowRate * dt)))
    }
}

// Small, additive rewards; zero-point trick platforms never grant bonuses.
struct CatchRewards {
    struct Award {
        let points: Int
        let perfect: Bool
        let combo: Bool
    }
    private(set) var streak = 0
    mutating func miss() { streak = 0 }
    mutating func catchPlatform(basePoints: Int, perfect: Bool) -> Award {
        guard basePoints > 0 else {
            streak = 0
            return Award(points: 0, perfect: false, combo: false)
        }
        streak += 1
        let combo = streak % 5 == 0
        return Award(points: basePoints + (perfect ? 1 : 0) + (combo ? 2 : 0),
                     perfect: perfect, combo: combo)
    }
    static func isPerfect(contact: CGPoint, centerX: CGFloat, width: CGFloat,
                          verticalSpeed: CGFloat) -> Bool {
        verticalSpeed <= 0 && abs(contact.x - centerX) <= width * 0.15
    }
}

struct ExperimentalTempo {
    private(set) var activeSeconds: TimeInterval = 0
    var multiplier: Double { 1 + Double(min(40, Int((activeSeconds + 0.000001) / 5))) * 0.05 }
    mutating func advance(_ dt: TimeInterval) { activeSeconds = min(200, activeSeconds + max(0, dt)) }
    mutating func reset() { activeSeconds = 0 }
}

struct EscapeProgress {
    static let goal = 150
    private(set) var seconds: TimeInterval = 0
    private(set) var longestCombo = 0
    private(set) var completed = false
    private(set) var awaitingChoice = false
    private(set) var endless = false
    private(set) var usedTurbo: Bool
    init(turbo: Bool = false) { usedTurbo = turbo }
    mutating func markTurbo() { usedTurbo = true }
    mutating func advance(_ dt: TimeInterval) {
        guard !awaitingChoice else { return }
        seconds += max(0, dt)
    }
    mutating func catchPlatform(height: Int, streak: Int) -> Bool {
        longestCombo = max(longestCombo, streak)
        guard height >= Self.goal, !completed else { return false }
        completed = true
        awaitingChoice = true
        return true
    }
    mutating func keepClimbing() {
        guard awaitingChoice else { return }
        awaitingChoice = false
        endless = true
    }
    var recordPrefix: String {
        #if DEBUG
        if ProcessInfo.processInfo.environment["SLINGDUO_ESCAPE_UI_TEST"] == "1"
            || ProcessInfo.processInfo.environment["SLINGDUO_UI_SCREEN"] != nil {
            return "SlingDuo.testRecords." + (usedTurbo ? "turbo" : "normal")
        }
        #endif
        return "SlingDuo.records." + (usedTurbo ? "turbo" : "normal")
    }
    var stage: String {
        if endless { return "ENDLESS" }
        return "ESCAPE"
    }
    static func timeText(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

struct EscapeSummary {
    let points: Int
    let seconds: TimeInterval
    let longestCombo: Int
    let turbo: Bool
}
