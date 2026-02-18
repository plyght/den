import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case notFound
    case serverError(Int)
    case networkError(Error)
    case decodingError(Error)
    case invalidURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized — check your auth token"
        case .notFound:
            return "Resource not found"
        case .serverError(let code):
            return "Server error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        }
    }
}

struct NotesResponse: Decodable, Sendable {
    let notes: [Note]
    let total: Int
}

final class APIClient: Sendable {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder.noteDecoder()
        self.encoder = JSONEncoder.noteEncoder()
    }

    private var baseURL: String { Config.shared.serverURL }
    private var token: String { Config.shared.authToken }

    // MARK: - Request Building

    private func request(
        method: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil
    ) throws -> URLRequest {
        guard var components = URLComponents(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return req
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            break
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func performVoid(_ request: URLRequest) async throws {
        let response: URLResponse

        do {
            (_, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(http.statusCode)
        }
    }

    // MARK: - Note Endpoints

    func createNote(
        content: String,
        title: String? = nil,
        pinned: Bool? = nil,
        tags: [String]? = nil
    ) async throws -> Note {
        var body: [String: Any] = ["content": content]
        if let title { body["title"] = title }
        if let pinned { body["pinned"] = pinned }
        if let tags { body["tags"] = tags }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let req = try request(method: "POST", path: "/api/notes", body: bodyData)
        return try await perform(req)
    }

    func listNotes(
        limit: Int? = nil,
        offset: Int? = nil,
        pinned: Bool? = nil,
        search: String? = nil
    ) async throws -> NotesResponse {
        var items: [URLQueryItem] = []
        if let limit { items.append(URLQueryItem(name: "limit", value: "\(limit)")) }
        if let offset { items.append(URLQueryItem(name: "offset", value: "\(offset)")) }
        if let pinned { items.append(URLQueryItem(name: "pinned", value: "\(pinned)")) }
        if let search { items.append(URLQueryItem(name: "search", value: search)) }

        let req = try request(method: "GET", path: "/api/notes", queryItems: items)
        return try await perform(req)
    }

    func getNote(id: String) async throws -> Note {
        let req = try request(method: "GET", path: "/api/notes/\(id)")
        return try await perform(req)
    }

    func updateNote(
        id: String,
        title: String? = nil,
        content: String? = nil,
        pinned: Bool? = nil,
        tags: [String]? = nil
    ) async throws -> Note {
        var body: [String: Any] = [:]
        if let title { body["title"] = title }
        if let content { body["content"] = content }
        if let pinned { body["pinned"] = pinned }
        if let tags { body["tags"] = tags }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let req = try request(method: "PUT", path: "/api/notes/\(id)", body: bodyData)
        return try await perform(req)
    }

    func deleteNote(id: String) async throws {
        let req = try request(method: "DELETE", path: "/api/notes/\(id)")
        try await performVoid(req)
    }
}
