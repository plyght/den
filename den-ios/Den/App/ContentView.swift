import SwiftUI

struct ContentView: View {
    @Environment(SyncEngine.self) private var syncEngine
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhase(phase)
        }
    }

    // MARK: - iPad

    private var iPadLayout: some View {
        NavigationSplitView {
            NoteListView()
        } detail: {
            detailView
        }
    }

    // MARK: - iPhone

    private var iPhoneLayout: some View {
        NavigationStack {
            NoteListView()
                .navigationDestination(for: String.self) { noteId in
                    NoteDetailView(noteId: noteId)
                }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        if let noteId = resolvedInitialNoteId() {
            NoteDetailView(noteId: noteId)
        } else {
            emptyDetail
        }
    }

    private var emptyDetail: some View {
        Text("Select a note")
            .foregroundStyle(.secondary)
    }

    // MARK: - Resume Logic

    private func resolvedInitialNoteId() -> String? {
        let config = Config.shared

        if let noteId = syncEngine.selectedNoteId {
            return noteId
        }

        guard
            let lastId = config.lastActiveNoteId,
            let lastTimestamp = config.lastActiveTimestamp
        else { return nil }

        let elapsed = Date().timeIntervalSince(lastTimestamp)
        guard elapsed < config.resumeTimeoutSeconds else { return nil }
        guard syncEngine.notes.contains(where: { $0.id == lastId }) else { return nil }

        return lastId
    }

    // MARK: - Scene Phase

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            Task { await syncEngine.refresh() }
        case .background:
            if let id = syncEngine.selectedNoteId {
                Config.shared.lastActiveNoteId = id
                Config.shared.lastActiveTimestamp = Date()
            }
        case .inactive:
            break
        @unknown default:
            break
        }
    }
}
