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
    private var elapsed: TimeInterval = 0
    private var aimOrigin: Phase = .ready

    var isRescuing: Bool { phase == .rescue || (phase == .aiming && aimOrigin == .rescue) }

    mutating func reset() { self = JumpFlow() }
    mutating func beginAim() -> Bool {
        guard phase == .ready || phase == .rescue else { return false }
        aimOrigin = phase
        phase = .aiming
        return true
    }
    mutating func cancelAim() { if phase == .aiming { phase = aimOrigin } }
    mutating func launch() { phase = .flying; elapsed = 0 }
    mutating func land() { phase = .handoff; elapsed = 0 }
    mutating func finish() { phase = .over }
    mutating func miss() {
        guard phase == .flying else { return }
        phase = .rescue
        rescueRemaining = JumpTuning.rescueDuration
    }
    mutating func advance(_ dt: TimeInterval, y: CGFloat, verticalSpeed: CGFloat, targetY: CGFloat) -> Event {
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
        case .rescue:
            rescueRemaining = max(0, rescueRemaining - dt)
            if rescueRemaining == 0 { finish(); return .rescueExpired }
        default: break
        }
        return .none
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
