import Foundation

actor LocalStore {
    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("den_notes_cache.json")
    }

    func save(notes: [Note]) async {
        do {
            let data = try JSONEncoder.noteEncoder().encode(notes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
        }
    }

    func load() async -> [Note] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder.noteDecoder().decode([Note].self, from: data)
        } catch {
            return []
        }
    }
}
