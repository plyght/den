import SwiftUI

struct ContentView: View {
    @Environment(SyncEngine.self) private var syncEngine
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var navigationPath = NavigationPath()
    @State private var columnVisibility = NavigationSplitViewVisibility.all

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
        .onChange(of: syncEngine.selectedNoteId) { _, newId in
            guard let newId else { return }
            if horizontalSizeClass != .regular {
                if !navigationPath.isEmpty {
                    navigationPath = NavigationPath()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    navigationPath.append(newId)
                }
            }
        }
        .task {
            resumeIfNeeded()
        }
    }

    // MARK: - iPad

    private var iPadLayout: some View {
        @Bindable var sync = syncEngine
        return NavigationSplitView(columnVisibility: $columnVisibility) {
            NoteListView()
        } detail: {
            if let noteId = sync.selectedNoteId {
                NoteDetailView(noteId: noteId)
            } else {
                emptyDetail
            }
        }
    }

    // MARK: - iPhone

    private var iPhoneLayout: some View {
        NavigationStack(path: $navigationPath) {
            NoteListView()
                .navigationDestination(for: String.self) { noteId in
                    NoteDetailView(noteId: noteId)
                }
        }
    }

    // MARK: - Empty Detail

    private var emptyDetail: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(.tertiary)
            Text("Select a note")
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Resume Logic

    private func resumeIfNeeded() {
        let config = Config.shared
        guard syncEngine.selectedNoteId == nil else { return }
        guard let lastId = config.lastActiveNoteId,
              let lastTimestamp = config.lastActiveTimestamp else { return }

        let elapsed = Date().timeIntervalSince(lastTimestamp)
        guard elapsed < config.resumeTimeoutSeconds else { return }

        syncEngine.selectedNoteId = lastId
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
