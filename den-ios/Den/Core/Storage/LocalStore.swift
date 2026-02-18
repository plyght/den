import Foundation

actor LocalStore {
    private let fileURL: URL
    private var cached: [Note]?

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("den_notes_cache.json")
    }

    func save(notes: [Note]) async {
        cached = notes
        do {
            let data = try JSONEncoder.noteEncoder().encode(notes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
        }
    }

    func load() async -> [Note] {
        if let cached { return cached }
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            let notes = try JSONDecoder.noteDecoder().decode([Note].self, from: data)
            cached = notes
            return notes
        } catch {
            return []
        }
    }

    // MARK: - Local CRUD

    func createNote(content: String) async -> Note {
        var notes = await load()
        let now = Date()
        let note = Note(
            id: UUID().uuidString.lowercased(),
            title: "",
            content: content,
            pinned: false,
            tags: [],
            createdAt: now,
            updatedAt: now
        )
        notes.append(note)
        await save(notes: notes)
        return note
    }

    func getNote(id: String) async -> Note? {
        let notes = await load()
        return notes.first { $0.id == id }
    }

    func updateNote(_ note: Note) async {
        var notes = await load()
        guard let idx = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[idx] = note
        await save(notes: notes)
    }

    func deleteNote(id: String) async {
        var notes = await load()
        notes.removeAll { $0.id == id }
        await save(notes: notes)
    }
}
