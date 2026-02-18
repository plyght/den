import SwiftUI

struct SearchView: View {
    @Environment(SyncEngine.self) private var sync
    @Binding var isPresented: Bool
    @State private var query: String = ""
    @State private var appeared = false
    @FocusState private var searchFocused: Bool

    @AppStorage("den.recentSearches") private var recentSearchesData: Data = Data()

    private var recentSearches: [String] {
        (try? JSONDecoder().decode([String].self, from: recentSearchesData)) ?? []
    }

    private var filteredNotes: [Note] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let q = query.lowercased()
        return sync.notes.filter { $0.content.lowercased().contains(q) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if query.isEmpty {
                        recentSearchesView
                    } else if filteredNotes.isEmpty {
                        noResultsView
                    } else {
                        resultsView
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        withAnimation(DenTheme.springSnappy) {
                            isPresented = false
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(DenTheme.accent)
                }
            }
            .searchable(text: $query, isPresented: $searchFocused, prompt: "Search notes")
            .onAppear {
                searchFocused = true
                withAnimation(DenTheme.springGentle) {
                    appeared = true
                }
            }
            .onChange(of: query) { _, newValue in
                if !newValue.isEmpty {
                    saveRecentSearch(newValue)
                }
            }
        }
        .scaleEffect(appeared ? 1.0 : 0.96)
        .opacity(appeared ? 1.0 : 0.0)
    }

    @ViewBuilder
    private var recentSearchesView: some View {
        if recentSearches.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 44, weight: .thin))
                    .foregroundStyle(DenTheme.accent.opacity(0.5))
                    .padding(.bottom, 4)

                Text("Search your notes")
                    .font(DenTheme.headingFont)
                    .foregroundStyle(.primary)

                Text("Find notes by any word or phrase.")
                    .font(DenTheme.bodyFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                Section("Recent") {
                    ForEach(recentSearches.prefix(8), id: \.self) { search in
                        Button {
                            query = search
                        } label: {
                            HStack {
                                Image(systemName: "clock")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.tertiary)
                                Text(search)
                                    .font(DenTheme.bodyFont)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        clearRecentSearches(at: indexSet)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    @ViewBuilder
    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: DenTheme.listSpacing) {
                ForEach(Array(filteredNotes.enumerated()), id: \.element.id) { index, note in
                    NavigationLink(value: note.id) {
                        NoteRowView(note: note, appeared: true)
                    }
                    .buttonStyle(.plain)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .padding(.horizontal, DenTheme.horizontalInset)
            .padding(.vertical, 8)
            .animation(DenTheme.springSnappy, value: filteredNotes.map(\.id))
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44, weight: .thin))
                .foregroundStyle(.tertiary)

            Text("No results for "\(query)"")
                .font(DenTheme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }

    private func saveRecentSearch(_ search: String) {
        var searches = recentSearches
        searches.removeAll { $0.lowercased() == search.lowercased() }
        searches.insert(search, at: 0)
        searches = Array(searches.prefix(10))
        recentSearchesData = (try? JSONEncoder().encode(searches)) ?? Data()
    }

    private func clearRecentSearches(at offsets: IndexSet) {
        var searches = recentSearches
        searches.remove(atOffsets: offsets)
        recentSearchesData = (try? JSONEncoder().encode(searches)) ?? Data()
    }
}
