import Foundation

enum NoteEvent: Sendable {
    case created(Note)
    case updated(Note)
    case deleted(String)
}

actor WebSocketClient: NSObject {
    private var task: URLSessionWebSocketTask?
    private var receiveLoopTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?
    private var connectionToken: UInt64 = 0
    private var isStopped = false

    private let eventContinuation: AsyncStream<NoteEvent>.Continuation
    nonisolated let events: AsyncStream<NoteEvent>

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        config.networkServiceType = .responsiveData
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "WebSocketClient.delegate"
        return URLSession(configuration: config, delegate: self, delegateQueue: queue)
    }()

    private var reconnectDelay: TimeInterval = 1
    private let maxReconnectDelay: TimeInterval = 30

    override init() {
        var continuation: AsyncStream<NoteEvent>.Continuation!
        events = AsyncStream { continuation = $0 }
        eventContinuation = continuation
        super.init()
    }

    func connect() async {
        isStopped = false
        reconnectDelay = 1
        await openConnection()
    }

    func disconnect() async {
        isStopped = true
        reconnectTask?.cancel()
        reconnectTask = nil
        await tearDown()
    }

    private func openConnection() async {
        guard !isStopped else { return }

        let token = Config.shared.authToken
        let serverURL = Config.shared.serverURL

        guard
            let baseURL = URL(string: serverURL),
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        else { return }

        components.scheme = components.scheme == "https" ? "wss" : "ws"
        components.path = "/ws"
        components.queryItems = [URLQueryItem(name: "token", value: token)]

        guard let url = components.url else { return }

        connectionToken = connectionToken &+ 1
        let snapshot = connectionToken

        await tearDown()

        let wsTask = session.webSocketTask(with: url)
        task = wsTask
        wsTask.resume()

        startReceiveLoop(token: snapshot, wsTask: wsTask)
        startPingLoop()
    }

    private func tearDown() async {
        receiveLoopTask?.cancel()
        receiveLoopTask = nil
        pingTask?.cancel()
        pingTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    private func startReceiveLoop(token: UInt64, wsTask: URLSessionWebSocketTask) {
        receiveLoopTask = Task { [weak self, continuation = eventContinuation] in
            guard let self else { return }
            while true {
                guard !Task.isCancelled else { break }
                do {
                    let message = try await wsTask.receive()
                    guard await self.isCurrentConnection(token: token, task: wsTask) else { break }

                    switch message {
                    case .string(let text):
                        if let event = await self.parseEvent(from: text) {
                            continuation.yield(event)
                        }
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8),
                           let event = await self.parseEvent(from: text) {
                            continuation.yield(event)
                        }
                    @unknown default:
                        break
                    }
                } catch {
                    guard await self.isCurrentConnection(token: token, task: wsTask) else { break }
                    await self.handleDisconnect()
                    break
                }
            }
        }
    }

    private func startPingLoop() {
        pingTask = Task { [weak self] in
            while true {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { break }
                await self?.sendPing()
            }
        }
    }

    private func sendPing() async {
        guard let task else { return }
        task.sendPing { _ in }
    }

    private func handleDisconnect() async {
        guard !isStopped else { return }
        await tearDown()
        scheduleReconnect()
    }

    private func scheduleReconnect() {
        guard !isStopped else { return }
        let delay = reconnectDelay
        reconnectDelay = min(reconnectDelay * 2, maxReconnectDelay)

        reconnectTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await self?.openConnection()
        }
    }

    private func isCurrentConnection(token: UInt64, task: URLSessionWebSocketTask) -> Bool {
        self.task === task && self.connectionToken == token
    }

    private func parseEvent(from text: String) -> NoteEvent? {
        guard let data = text.data(using: .utf8) else { return nil }

        struct RawEvent: Decodable {
            let type: String
            let note: Note?
        }

        let decoder = JSONDecoder.noteDecoder()
        guard let raw = try? decoder.decode(RawEvent.self, from: data) else { return nil }

        switch raw.type {
        case "note:created":
            guard let note = raw.note else { return nil }
            return .created(note)
        case "note:updated":
            guard let note = raw.note else { return nil }
            return .updated(note)
        case "note:deleted":
            guard let note = raw.note else { return nil }
            return .deleted(note.id)
        default:
            return nil
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketClient: URLSessionWebSocketDelegate, @unchecked Sendable {
    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        Task { await self.handleOpen(for: webSocketTask) }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        Task { await self.handleClose(for: webSocketTask) }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard error != nil else { return }
        Task { [weak self] in
            guard let self else { return }
            guard let current = await self.task, current === task else { return }
            await self.handleDisconnect()
        }
    }

    private func handleOpen(for wsTask: URLSessionWebSocketTask) async {
        guard task === wsTask else { return }
        reconnectDelay = 1
    }

    private func handleClose(for wsTask: URLSessionWebSocketTask) async {
        guard task === wsTask else { return }
        await handleDisconnect()
    }
}
