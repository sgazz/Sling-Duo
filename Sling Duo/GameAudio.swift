import AVFoundation

@MainActor
final class GameAudio {
    enum Cue: String, CaseIterable { case launch, grab, miss, end }
    var enabled = true {
        didSet { if !enabled { suspend() } }
    }
    private var players: [Cue: AVAudioPlayer] = [:]
    private var sessionActive = false

    func prepare() {
        guard players.isEmpty else { return }
        for cue in Cue.allCases {
            let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "wav", subdirectory: "Sounds")
                ?? Bundle.main.url(forResource: cue.rawValue, withExtension: "wav")
            guard let url, let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.volume = 0.6
            player.enableRate = true
            players[cue] = player
        }
    }

    func play(_ cue: Cue, step: Int = 0) {
        guard enabled else { return }
        prepare()
        if !sessionActive {
            do {
                let session = AVAudioSession.sharedInstance()
                // Ambient respects the silent switch and mixes with the user's music.
                try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)
                sessionActive = true
            } catch { return }
        }
        guard let player = players[cue] else { return }
        player.currentTime = 0
        player.rate = cue == .grab ? 1 + Float(step % 4) * 0.04 : 1
        player.prepareToPlay()
        player.play()
    }

    func suspend() {
        for player in players.values { player.stop(); player.currentTime = 0 }
        if sessionActive {
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
            sessionActive = false
        }
    }
}
