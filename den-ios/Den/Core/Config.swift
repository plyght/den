import Foundation

final class Config: @unchecked Sendable {
    static let shared = Config()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let serverURL = "den.serverURL"
        static let authToken = "den.authToken"
        static let lastActiveNoteId = "den.lastActiveNoteId"
        static let lastActiveTimestamp = "den.lastActiveTimestamp"
        static let resumeTimeoutSeconds = "den.resumeTimeoutSeconds"
    }

    var serverURL: String {
        get { defaults.string(forKey: Keys.serverURL) ?? "http://localhost:7745" }
        set { defaults.set(newValue, forKey: Keys.serverURL) }
    }

    var authToken: String {
        get { defaults.string(forKey: Keys.authToken) ?? "" }
        set { defaults.set(newValue, forKey: Keys.authToken) }
    }

    var lastActiveNoteId: String? {
        get { defaults.string(forKey: Keys.lastActiveNoteId) }
        set { defaults.set(newValue, forKey: Keys.lastActiveNoteId) }
    }

    var lastActiveTimestamp: Date? {
        get {
            let interval = defaults.double(forKey: Keys.lastActiveTimestamp)
            guard interval > 0 else { return nil }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            defaults.set(newValue?.timeIntervalSince1970 ?? 0, forKey: Keys.lastActiveTimestamp)
        }
    }

    var resumeTimeoutSeconds: TimeInterval {
        get {
            let stored = defaults.double(forKey: Keys.resumeTimeoutSeconds)
            return stored > 0 ? stored : 300
        }
        set { defaults.set(newValue, forKey: Keys.resumeTimeoutSeconds) }
    }

    private init() {}
}
