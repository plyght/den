import Foundation

struct Note: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var title: String
    var content: String
    var pinned: Bool
    var tags: [String]
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case pinned
        case tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Computed Properties

extension Note {
    var isEmpty: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var preview: String {
        let stripped = strippingMarkdown(from: content)
        let trimmed = stripped.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 100 else { return trimmed }
        return String(trimmed.prefix(100))
    }

    private func strippingMarkdown(from text: String) -> String {
        var result = text

        let multilinePatterns: [(String, String)] = [
            (#"^#{1,6}\s+"#, ""),
            (#"^>\s?"#, ""),
            (#"^[\-\*\+]\s+"#, ""),
            (#"^\d+\.\s+"#, ""),
        ]

        for (pattern, replacement) in multilinePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else { continue }
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: replacement)
        }

        let inlinePatterns: [(String, String)] = [
            (#"(\*{1,3}|_{1,3})(.*?)\1"#, "$2"),
            (#"`[^`]+`"#, ""),
            (#"```[\s\S]*?```"#, ""),
            (#"\[([^\]]+)\]\([^\)]+\)"#, "$1"),
            (#"\n+"#, " "),
        ]

        for (pattern, replacement) in inlinePatterns {
            result = result.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }

        return result
    }
}

// MARK: - JSON Coder Factories

extension JSONDecoder {
    static func noteDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let primary = ISO8601DateFormatter()
        primary.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = primary.date(from: string) { return date }
            if let date = fallback.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(string)"
            )
        }
        return decoder
    }
}

extension JSONEncoder {
    static func noteEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(formatter.string(from: date))
        }
        return encoder
    }
}
