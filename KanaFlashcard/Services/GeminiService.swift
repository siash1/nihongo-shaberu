import Foundation

struct GeminiService {
    private static let apiKey = Secrets.geminiAPIKey
    private static let model = "gemini-3.8-flash"
    private static let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    private static func systemPrompt(for level: JLPTLevel) -> String {
        """
        You are a friendly Japanese-speaking friend having a casual conversation. \
        You help the user practice Japanese naturally, like a real conversation partner.

        The user's current level: \(level.promptDescription)

        Rules for EVERY response:
        1. Include Japanese text (appropriate to their level)
        2. Provide romaji (romanized pronunciation) for all Japanese text
        3. Provide English translation

        Format each Japanese phrase or sentence as:

        **Japanese:** Japanese text here
        **Romaji:** Romanized pronunciation
        **English:** English translation

        Guidelines:
        - Talk like a friendly conversation partner, not a textbook
        - If the user speaks in English, respond naturally and teach them the Japanese way to say it
        - If the user attempts Japanese, encourage them and gently correct mistakes
        - Introduce new vocabulary naturally in conversation
        - Keep responses concise - focus on 1-3 phrases per response
        - Match vocabulary and grammar complexity to their JLPT level
        - Occasionally ask the user questions to keep the conversation going
        """
    }

    // MARK: - Request Types

    private struct Request: Encodable {
        let contents: [RequestContent]
        let systemInstruction: SystemInstruction

        enum CodingKeys: String, CodingKey {
            case contents
            case systemInstruction = "system_instruction"
        }
    }

    private struct RequestContent: Encodable {
        let role: String
        let parts: [RequestPart]
    }

    private struct SystemInstruction: Encodable {
        let parts: [RequestPart]
    }

    private struct RequestPart: Encodable {
        var text: String?
        var inlineData: InlineData?

        struct InlineData: Encodable {
            let mimeType: String
            let data: String

            enum CodingKeys: String, CodingKey {
                case mimeType = "mime_type"
                case data
            }
        }

        enum CodingKeys: String, CodingKey {
            case text
            case inlineData = "inline_data"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(text, forKey: .text)
            try container.encodeIfPresent(inlineData, forKey: .inlineData)
        }
    }

    // MARK: - Response Types

    private struct Response: Decodable {
        let candidates: [Candidate]?
        let error: ErrorDetail?
    }

    private struct Candidate: Decodable {
        let content: CandidateContent
    }

    private struct CandidateContent: Decodable {
        let parts: [ResponsePart]
    }

    private struct ResponsePart: Decodable {
        let text: String
    }

    private struct ErrorDetail: Decodable {
        let message: String
    }

    // MARK: - Shared Request Helper

    private static func performRequest(contents: [RequestContent], systemPrompt: String) async throws -> String {
        let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body = Request(
            contents: contents,
            systemInstruction: SystemInstruction(parts: [RequestPart(text: systemPrompt)])
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, httpResponse) = try await URLSession.shared.data(for: request)

        if let httpResponse = httpResponse as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GeminiError.apiError("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        let response = try JSONDecoder().decode(Response.self, from: data)

        if let error = response.error {
            throw GeminiError.apiError(error.message)
        }

        guard let text = response.candidates?.first?.content.parts.first?.text else {
            throw GeminiError.noResponse
        }

        return text
    }

    // MARK: - Word Generation

    static func generateWords(script: String, level: JLPTLevel, count: Int = 10) async throws -> [WordCard] {
        let prompt = """
        Generate \(count) random Japanese words appropriate for \(level.rawValue) level. \
        Focus on words that primarily use \(script) script.

        Rules:
        - Prefer words written in \(script), but use the natural/correct Japanese writing \
        (mixing scripts is OK if that's how the word is actually written)
        - Do NOT use kanji
        - Choose common, useful vocabulary appropriate for \(level.rawValue) level
        - Each word should be different
        - Give a variety of word types (nouns, verbs, adjectives, etc.)

        Return ONLY a JSON array with no other text, like this:
        [{"word":"にほん","romaji":"nihon","meaning":"Japan"}]

        Each object must have exactly these keys: "word", "romaji", "meaning"
        """

        let contents = [RequestContent(role: "user", parts: [RequestPart(text: prompt)])]
        let text = try await performRequest(
            contents: contents,
            systemPrompt: "You are a Japanese language teaching assistant. Return only valid JSON with no markdown formatting or code blocks."
        )

        // Extract JSON array from response (strip markdown code fences if present)
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if jsonString.hasPrefix("```") {
            let lines = jsonString.components(separatedBy: "\n")
            let filtered = lines.drop { $0.hasPrefix("```") }.reversed().drop { $0.hasPrefix("```") }.reversed()
            jsonString = filtered.joined(separator: "\n")
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw GeminiError.noResponse
        }

        struct WordJSON: Decodable {
            let word: String
            let romaji: String
            let meaning: String
        }

        let words = try JSONDecoder().decode([WordJSON].self, from: jsonData)
        return words.map { WordCard(word: $0.word, romaji: $0.romaji, meaning: $0.meaning, level: level) }
    }

    // MARK: - Chat (Text)

    static func sendMessage(history: [ChatMessage], level: JLPTLevel) async throws -> String {
        let contents = history.map { msg in
            RequestContent(
                role: msg.isUser ? "user" : "model",
                parts: [RequestPart(text: msg.text)]
            )
        }
        return try await performRequest(contents: contents, systemPrompt: systemPrompt(for: level))
    }

    // MARK: - Chat (Audio)

    static func sendAudioMessage(audioData: Data, history: [ChatMessage], level: JLPTLevel) async throws -> String {
        // Previous messages as text
        var contents = history.map { msg in
            RequestContent(
                role: msg.isUser ? "user" : "model",
                parts: [RequestPart(text: msg.text)]
            )
        }

        // Latest message: audio + instruction
        let audioPart = RequestPart(inlineData: RequestPart.InlineData(
            mimeType: "audio/wav",
            data: audioData.base64EncodedString()
        ))
        let instructionPart = RequestPart(text: "This is a voice message. First write 'Heard: [what I said]' on its own line, then respond normally.")
        contents.append(RequestContent(role: "user", parts: [audioPart, instructionPart]))

        return try await performRequest(contents: contents, systemPrompt: systemPrompt(for: level))
    }
}

enum GeminiError: LocalizedError {
    case apiError(String)
    case noResponse

    var errorDescription: String? {
        switch self {
        case .apiError(let message): return message
        case .noResponse: return "No response received from Gemini"
        }
    }
}
