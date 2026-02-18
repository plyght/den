import SwiftUI

struct NoteListView: View {
    @Environment(SyncEngine.self) private var sync
    @State private var appearedNoteIds: Set<String> = []
    @State private var showingSettings = false
    @State private var selectedNoteId: String?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            noteList

            FloatingButton {
                createNewNote()
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .navigationTitle("Den")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .refreshable {
            await sync.refresh()
        }
    }

    @ViewBuilder
    private var noteList: some View {
        if sync.notes.isEmpty && !sync.isLoading {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: DenTheme.listSpacing) {
                    if !sync.searchQuery.isEmpty {
                        searchResultsSection
                    } else {
                        if !sync.pinnedNotes.isEmpty {
                            pinnedSection
                        }
                        recentSection
                    }
                }
                .padding(.horizontal, DenTheme.horizontalInset)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .searchable(
                text: Binding(
                    get: { sync.searchQuery },
                    set: { sync.searchQuery = $0 }
                ),
                prompt: "Search notes"
            )
        }
    }

    @ViewBuilder
    private var pinnedSection: some View {
        VStack(alignment: .leading, spacing: DenTheme.listSpacing) {
            Text("Pinned")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
                .padding(.top, 4)

            ForEach(sync.pinnedNotes) { note in
                noteRow(note)
            }
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: DenTheme.listSpacing) {
            if !sync.pinnedNotes.isEmpty {
                Text("Recent")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
            }

            ForEach(sync.recentNotes) { note in
                noteRow(note)
            }
        }
    }

    @ViewBuilder
    private var searchResultsSection: some View {
        let filtered = sync.notes.filter { note in
            let q = sync.searchQuery.lowercased()
            return note.content.lowercased().contains(q)
        }

        if filtered.isEmpty {
            searchEmptyState
        } else {
            ForEach(filtered) { note in
                noteRow(note)
            }
        }
    }

    @ViewBuilder
    private func noteRow(_ note: Note) -> some View {
        let appeared = appearedNoteIds.contains(note.id)

        NavigationLink(value: note.id) {
            NoteRowView(note: note, appeared: appeared)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                DenTheme.hapticMedium()
                Task { try? await sync.togglePin(id: note.id) }
            } label: {
                Label(
                    note.pinned ? "Unpin" : "Pin",
                    systemImage: note.pinned ? "pin.slash.fill" : "pin.fill"
                )
            }
            .tint(DenTheme.accent)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                DenTheme.hapticWarning()
                Task { try? await sync.deleteNote(id: note.id) }
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
        .onAppear {
            withAnimation(DenTheme.springSnappy.delay(Double(sync.notes.firstIndex(where: { $0.id == note.id }) ?? 0) * 0.04)) {
                appearedNoteIds.insert(note.id)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(DenTheme.accent.opacity(0.6))

            Text("Your den is empty.")
                .font(DenTheme.headingFont)
                .foregroundStyle(.primary)

            Text("Tap + to capture a thought.")
                .font(DenTheme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }

    private var searchEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(.tertiary)

            Text("No results for "\(sync.searchQuery)"")
                .font(DenTheme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func createNewNote() {
        DenTheme.hapticMedium()
        Task {
            do {
                let note = try await sync.createNote(content: "")
                sync.selectedNoteId = note.id
            } catch {}
        }
    }
}
