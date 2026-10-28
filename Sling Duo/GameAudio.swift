import AVFoundation

nonisolated enum AudioCue: String, CaseIterable, Sendable {
    case launch, grab, miss, end
}

/// Main-thread facade. Audio I/O and session changes are serialized off the UI thread.
@MainActor
final class GameAudio {
    typealias Cue = AudioCue
    var enabled = true {
        didSet { playback.setEnabled(enabled) }
    }
    private let playback = AudioPlayback()

    func prepare() { playback.prepare() }
    func play(_ cue: Cue, step: Int = 0) {
        guard enabled else { return }
        playback.play(cue, step: step)
    }
    func suspend() { playback.suspend() }
}

/// All mutable state and every AVFoundation call are confined to `queue`.
/// The same queue orders activation, playback, mute and background deactivation.
private nonisolated final class AudioPlayback: @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.slingduo.audio", qos: .userInitiated)
    private var players: [AudioCue: AVAudioPlayer] = [:]
    private var sessionActive = false
    private var enabled = true

    func setEnabled(_ enabled: Bool) {
        queue.async {
            guard self.enabled != enabled else { return }
            self.enabled = enabled
            if enabled { self.prepareOnQueue() } else { self.suspendOnQueue() }
        }
    }

    func prepare() { queue.async { self.prepareOnQueue() } }

    func play(_ cue: AudioCue, step: Int) {
        queue.async {
            guard self.enabled else { return }
            self.prepareOnQueue()
            guard self.sessionActive, let player = self.players[cue] else { return }
            player.currentTime = 0
            player.rate = cue == .grab ? 1 + Float(step % 4) * 0.04 : 1
            player.play()
        }
    }

    func suspend() { queue.async { self.suspendOnQueue() } }

    private func prepareOnQueue() {
        dispatchPrecondition(condition: .onQueue(queue))
        guard enabled else { return }
        if !sessionActive {
            do {
                let session = AVAudioSession.sharedInstance()
                // Ambient respects the silent switch and mixes with other music.
                // Synchronous session APIs run only on this dedicated queue,
                // including on iOS versions before asynchronous activation exists.
                try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)
                sessionActive = true
            } catch { return }
        }
        guard players.isEmpty else { return }
        for cue in AudioCue.allCases {
            let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "wav", subdirectory: "Sounds")
                ?? Bundle.main.url(forResource: cue.rawValue, withExtension: "wav")
            guard let url, let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.volume = 0.6
            player.enableRate = true
            player.prepareToPlay()
            players[cue] = player
        }
    }

    private func suspendOnQueue() {
        dispatchPrecondition(condition: .onQueue(queue))
        for player in players.values { player.stop(); player.currentTime = 0 }
        if sessionActive {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
                sessionActive = false
            } catch {
                // Preserve the active state so a later suspend can retry.
            }
        }
    }
}
