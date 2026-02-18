import Foundation
import Observation

@Observable
@MainActor
final class SyncEngine {
    var notes: [Note] = []
    var selectedNoteId: String?
    var isLoading: Bool = false
    var searchQuery: String = ""
    var error: String?

    private let api: APIClient
    private let store: LocalStore
    private let wsClient: WebSocketClient

    private var wsListenTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?

    private var isLocal: Bool { Config.shared.localMode }

    init(api: APIClient = .shared, store: LocalStore = LocalStore(), wsClient: WebSocketClient = WebSocketClient()) {
        self.api = api
        self.store = store
        self.wsClient = wsClient
    }

    // MARK: - Computed

    var pinnedNotes: [Note] {
        notes.filter(\.pinned)
    }

    var recentNotes: [Note] {
        notes.filter { !$0.pinned }
    }

    var filteredNotes: [Note] {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return notes
        }
        let q = searchQuery.lowercased()
        return notes.filter {
            $0.title.lowercased().contains(q) ||
            $0.content.lowercased().contains(q) ||
            $0.tags.contains { $0.lowercased().contains(q) }
        }
    }

    // MARK: - Lifecycle

    func start() async {
        let cached = await store.load()
        if !cached.isEmpty {
            notes = sorted(cached)
        }

        if isLocal {
            isLoading = false
            return
        }

        await refresh()
        startWebSocket()
    }

    func stop() async {
        wsListenTask?.cancel()
        wsListenTask = nil
        await wsClient.disconnect()
    }

    // MARK: - Sync

    func refresh() async {
        isLoading = true
        error = nil

        if isLocal {
            notes = sorted(await store.load())
            isLoading = false
            return
        }

        do {
            let response = try await api.listNotes()
            notes = sorted(response.notes)
            await store.save(notes: notes)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    @discardableResult
    func createNote(content: String) async throws -> Note {
        if isLocal {
            let note = await store.createNote(content: content)
            notes = sorted(notes + [note])
            return note
        }

        let note = try await api.createNote(content: content)
        notes = sorted(notes + [note])
        await store.save(notes: notes)
        return note
    }

    func updateNote(_ note: Note) async throws {
        guard let idx = notes.firstIndex(where: { $0.id == note.id }) else { return }

        let previous = notes[idx]
        notes[idx] = note
        notes = sorted(notes)

        if isLocal {
            debounceTask?.cancel()
            debounceTask = Task {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                await self.store.updateNote(note)
            }
            return
        }

        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            do {
                let updated = try await self.api.updateNote(
                    id: note.id,
                    title: note.title,
                    content: note.content,
                    pinned: note.pinned,
                    tags: note.tags
                )
                if let i = self.notes.firstIndex(where: { $0.id == updated.id }) {
                    self.notes[i] = updated
                    self.notes = self.sorted(self.notes)
                }
                await self.store.save(notes: self.notes)
            } catch {
                if let i = self.notes.firstIndex(where: { $0.id == previous.id }) {
                    self.notes[i] = previous
                    self.notes = self.sorted(self.notes)
                }
                self.error = error.localizedDescription
            }
        }
    }

    func deleteNote(id: String) async throws {
        let previous = notes
        notes.removeAll { $0.id == id }
        if selectedNoteId == id { selectedNoteId = nil }

        if isLocal {
            await store.deleteNote(id: id)
            return
        }

        do {
            try await api.deleteNote(id: id)
            await store.save(notes: notes)
        } catch {
            notes = previous
            throw error
        }
    }

    func togglePin(id: String) async throws {
        guard let idx = notes.firstIndex(where: { $0.id == id }) else { return }
        var updated = notes[idx]
        updated.pinned.toggle()
        try await updateNote(updated)
    }

    func search(query: String) async {
        searchQuery = query
    }

    // MARK: - WebSocket

    private func startWebSocket() {
        wsListenTask?.cancel()
        wsListenTask = Task { [weak self] in
            guard let self else { return }
            await self.wsClient.connect()
            for await event in await self.wsClient.events {
                guard !Task.isCancelled else { break }
                await self.handleEvent(event)
            }
        }
    }

    private func handleEvent(_ event: NoteEvent) async {
        switch event {
        case .created(let note):
            guard !notes.contains(where: { $0.id == note.id }) else { return }
            notes = sorted(notes + [note])
            await store.save(notes: notes)

        case .updated(let note):
            if let idx = notes.firstIndex(where: { $0.id == note.id }) {
                notes[idx] = note
                notes = sorted(notes)
            } else {
                notes = sorted(notes + [note])
            }
            await store.save(notes: notes)

        case .deleted(let id):
            notes.removeAll { $0.id == id }
            if selectedNoteId == id { selectedNoteId = nil }
            await store.save(notes: notes)
        }
    }

    // MARK: - Sorting

    private func sorted(_ input: [Note]) -> [Note] {
        input.sorted {
            if $0.pinned != $1.pinned { return $0.pinned }
            return $0.updatedAt > $1.updatedAt
        }
    }
}
