import AVFoundation

class SpeechService: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?

    var onRecordingStateChanged: (@Sendable (Bool) -> Void)?
    var onSpeakingStateChanged: (@Sendable (Bool) -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    // MARK: - Audio Recording

    func startRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice_\(UUID().uuidString).wav")
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.record()
        onRecordingStateChanged?(true)
    }

    func stopRecording() -> Data? {
        audioRecorder?.stop()
        audioRecorder = nil
        // Recording is over: go back to playback so later speech uses the normal high-quality
        // route (headphones would otherwise stay on the hands-free call profile).
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        onRecordingStateChanged?(false)

        guard let url = recordingURL else { return nil }
        defer {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
        return try? Data(contentsOf: url)
    }

    // MARK: - Text to Speech

    func speak(_ text: String, language: String = "ja-JP") {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.42
        utterance.preUtteranceDelay = 0.1
        onSpeakingStateChanged?(true)
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        onSpeakingStateChanged?(false)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onSpeakingStateChanged?(false)
    }
}
