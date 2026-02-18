import SwiftUI

struct NoteDetailView: View {
    let noteId: String

    @Environment(SyncEngine.self) private var sync
    @State private var noteContent: String = ""
    @State private var saveTask: Task<Void, Never>?
    @State private var showingDeleteConfirm = false
    @State private var showingShareSheet = false

    private var note: Note? {
        sync.notes.first { $0.id == noteId }
    }

    private var navigationTitle: String {
        guard let note else { return "New Note" }
        let firstLine = note.content.components(separatedBy: "\n").first?.trimmingCharacters(in: .whitespaces) ?? ""
        return firstLine.isEmpty ? "New Note" : firstLine
    }

    var body: some View {
        Group {
            if note != nil {
                editorView
            } else {
                notFoundView
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let note {
                    Button {
                        DenTheme.hapticMedium()
                        Task { try? await sync.togglePin(id: note.id) }
                    } label: {
                        Image(systemName: note.pinned ? "pin.fill" : "pin")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(note.pinned ? DenTheme.accent : Color.secondary)
                            .animation(DenTheme.springBouncy, value: note.pinned)
                    }

                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(DenTheme.deleteRed)
                    }
                }
            }
        }
        .confirmationDialog("Delete this note?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                DenTheme.hapticWarning()
                Task {
                    try? await sync.deleteNote(id: noteId)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingShareSheet) {
            if let note {
                ShareSheet(items: [note.content])
            }
        }
        .onAppear {
            if let note {
                noteContent = note.content
            }
        }
        .onChange(of: note?.content) { _, newContent in
            if let newContent, newContent != noteContent {
                noteContent = newContent
            }
        }
    }

    @ViewBuilder
    private var editorView: some View {
        NoteEditorView(content: $noteContent)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onChange(of: noteContent) { _, newValue in
                scheduleSave(content: newValue)
            }
    }

    private var notFoundView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(.tertiary)

            Text("Note not found")
                .font(DenTheme.bodyFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func scheduleSave(content: String) {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            guard var updatedNote = note else { return }
            updatedNote.content = content
            updatedNote.updatedAt = Date()
            try? await sync.updateNote(updatedNote)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
