import Foundation

@Observable
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var inputText = ""
    var isRecording = false
    var isSpeaking = false
    var isProcessing = false
    var errorMessage: String?
    var selectedLevel: JLPTLevel = .n5
    var permissionsGranted = false

    private let speechService = SpeechService()

    init() {
        speechService.onRecordingStateChanged = { [weak self] recording in
            Task { @MainActor in self?.isRecording = recording }
        }
        speechService.onSpeakingStateChanged = { [weak self] speaking in
            Task { @MainActor in self?.isSpeaking = speaking }
        }
    }

    func requestPermissions() async {
        permissionsGranted = await speechService.requestPermissions()
    }

    func toggleListening() {
        if isSpeaking {
            speechService.stopSpeaking()
        }

        if isRecording {
            guard let audioData = speechService.stopRecording() else { return }
            sendAudioMessage(audioData)
        } else {
            do {
                try speechService.startRecording()
            } catch {
                errorMessage = "Microphone error: \(error.localizedDescription)"
            }
        }
    }

    func sendAudioMessage(_ audioData: Data) {
        guard !isProcessing else { return }
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                let response = try await GeminiService.sendAudioMessage(
                    audioData: audioData,
                    history: messages,
                    level: selectedLevel
                )

                let (heardText, aiResponse) = parseAudioResponse(response)

                if !heardText.isEmpty {
                    messages.append(ChatMessage(text: heardText, isUser: true))
                }
                messages.append(ChatMessage(text: aiResponse, isUser: false))

                let japanese = extractJapanese(from: aiResponse)
                if !japanese.isEmpty {
                    speechService.speak(japanese)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }

    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isProcessing else { return }

        messages.append(ChatMessage(text: trimmed, isUser: true))
        inputText = ""
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                let response = try await GeminiService.sendMessage(history: messages, level: selectedLevel)
                messages.append(ChatMessage(text: response, isUser: false))

                let japanese = extractJapanese(from: response)
                if !japanese.isEmpty {
                    speechService.speak(japanese)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }

    func sendTypedMessage() {
        sendMessage(inputText)
    }

    func replayMessage(_ message: ChatMessage) {
        guard !message.isUser else { return }
        let japanese = extractJapanese(from: message.text)
        if !japanese.isEmpty {
            speechService.speak(japanese)
        }
    }

    func stopSpeaking() {
        speechService.stopSpeaking()
    }

    func clearChat() {
        messages.removeAll()
        errorMessage = nil
        speechService.stopSpeaking()
        _ = speechService.stopRecording()
    }

    private func parseAudioResponse(_ text: String) -> (heard: String, response: String) {
        let lines = text.components(separatedBy: "\n")
        if let firstLine = lines.first?.trimmingCharacters(in: .whitespaces),
           firstLine.lowercased().hasPrefix("heard:") {
            let heard = firstLine
                .replacingOccurrences(of: "Heard:", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "**", with: "")
                .trimmingCharacters(in: .whitespaces)
            let response = lines.dropFirst()
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (heard, response)
        }
        return ("", text)
    }

    private func extractJapanese(from text: String) -> String {
        text.components(separatedBy: "\n")
            .compactMap { line -> String? in
                if line.contains("**Japanese:**") {
                    return line.replacingOccurrences(of: "**Japanese:**", with: "")
                        .replacingOccurrences(of: "**", with: "")
                        .trimmingCharacters(in: .whitespaces)
                }
                return nil
            }
            .joined(separator: "。")
    }
}
