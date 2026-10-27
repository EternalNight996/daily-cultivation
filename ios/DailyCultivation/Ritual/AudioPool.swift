import AVFoundation

/// 音效池。V1 只有三段占位音（合成音，无版权问题），美术音到位后同名替换即可。
/// 会话类别固定 .ambient：尊重静音键、不打断用户正在听的音乐。
/// duckOthers 与 ambient 不兼容（Apple 只允许 playback/playAndRecord/multiRoute），所以不做 ducking。
@MainActor
final class AudioPool {
    enum Sound: String, CaseIterable {
        case tick
        case complete
        case settle
    }

    static let shared = AudioPool()

    private var pools: [Sound: [AVAudioPlayer]] = [:]
    private let voicesPerSound = 3
    private var isReady = false
    private var isEnabled = true

    private init() {}

    func prepare() {
        guard !isReady else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [])
        try? session.setActive(true)

        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
                AppLog.ritual.error("missing audio: \(sound.rawValue, privacy: .public)")
                continue
            }
            var voices: [AVAudioPlayer] = []
            for _ in 0..<voicesPerSound {
                guard let player = try? AVAudioPlayer(contentsOf: url) else { continue }
                player.prepareToPlay()          // 预加载，消掉首帧 80–150ms 的延迟
                player.volume = sound == .tick ? 0.45 : 0.85
                voices.append(player)
            }
            pools[sound] = voices
        }
        isReady = true
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        guard !enabled else { return }
        pools.values.flatMap { $0 }.forEach { $0.stop() }
    }

    func play(_ sound: Sound, at time: TimeInterval? = nil) {
        guard isEnabled, let voices = pools[sound], !voices.isEmpty else { return }
        let player = voices.first { !$0.isPlaying } ?? voices[0]
        player.currentTime = 0
        if let time {
            player.play(atTime: time)
        } else {
            player.play()
        }
    }
}
