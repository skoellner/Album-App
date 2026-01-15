import MusicKit
import SwiftData
import SwiftUI

struct AlbumListView: View {
    enum SortMode: String, CaseIterable, Identifiable {
        case album = "Album"
        case artistAlbum = "Artist + Album"

        var id: String { rawValue }
    }

    @Environment(\.modelContext) private var modelContext
    @Query private var hiddenAlbums: [HiddenAlbum]

    @ObservedObject var musicClient: MusicClient

    @State private var albums: [Album] = []
    @State private var loadingError: String?
    @State private var searchText: String = ""
    @State private var sortMode: SortMode = .album

    var body: some View {
        Group {
            if musicClient.authorizationStatus != .authorized {
                ContentUnavailableView(
                    "Apple Music Access Needed",
                    systemImage: "music.note.list",
                    description: Text("Enable Apple Music access to load your albums.")
                )
            } else if let loadingError {
                ContentUnavailableView(
                    "Couldn’t Load Albums",
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadingError)
                )
            } else {
                albumList
            }
        }
        .navigationTitle("Only Albums")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort", selection: $sortMode) {
                        ForEach(SortMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .accessibilityLabel("Sort")
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .task {
            await reload()
        }
        .refreshable {
            await reload()
        }
    }

    private var albumList: some View {
        let hiddenIDs = Set(hiddenAlbums.map(\.albumID))
        let visible = filteredAndSortedAlbums(albums: albums, hiddenIDs: hiddenIDs, searchText: searchText, sortMode: sortMode)
        let sections = sectionedAlbums(albums: visible, sortMode: sortMode)

        return ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                List {
                    ForEach(sections.keys.sorted(), id: \.self) { key in
                        Section(header: Text(key).id(key)) {
                            ForEach(sections[key] ?? [], id: \.id) { album in
                                NavigationLink {
                                    AlbumDetailView(album: album, musicClient: musicClient)
                                } label: {
                                    AlbumRow(album: album)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        hide(albumID: album.id.rawValue)
                                    } label: {
                                        Label("Hide", systemImage: "eye.slash")
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)

                AlphabetIndexBar { letter in
                    withAnimation(.snappy) {
                        proxy.scrollTo(letter, anchor: .top)
                    }
                }
                .padding(.trailing, 4)
            }
        }
    }

    private func reload() async {
        do {
            loadingError = nil
            albums = try await musicClient.fetchFavoritedLibraryAlbums()
        } catch {
            loadingError = String(describing: error)
        }
    }

    private func hide(albumID: String) {
        withAnimation {
            modelContext.insert(HiddenAlbum(albumID: albumID))
        }
    }
}

private func filteredAndSortedAlbums(albums: [Album], hiddenIDs: Set<String>, searchText: String, sortMode: AlbumListView.SortMode) -> [Album] {
    let visible = albums.filter { !hiddenIDs.contains($0.id.rawValue) }

    let filtered: [Album]
    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        filtered = visible
    } else {
        let q = searchText.lowercased()
        filtered = visible.filter {
            ($0.title.lowercased().contains(q)) || ($0.artistName.lowercased().contains(q))
        }
    }

    switch sortMode {
    case .album:
        return filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    case .artistAlbum:
        return filtered.sorted {
            let a0 = $0.artistName.localizedCaseInsensitiveCompare($1.artistName) == .orderedAscending
            let a1 = $0.artistName.localizedCaseInsensitiveCompare($1.artistName) == .orderedSame
            return a0 || (a1 && $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending)
        }
    }
}

private func sectionedAlbums(albums: [Album], sortMode: AlbumListView.SortMode) -> [String: [Album]] {
    func key(for album: Album) -> String {
        let s: String
        switch sortMode {
        case .album:
            s = album.title
        case .artistAlbum:
            s = album.artistName
        }
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "#" }
        let upper = String(first).uppercased()
        return upper.rangeOfCharacter(from: CharacterSet.letters) == nil ? "#" : upper
    }

    return Dictionary(grouping: albums, by: key(for:))
}

private struct AlbumRow: View {
    let album: Album

    var body: some View {
        HStack(spacing: 12) {
            ArtworkImage(album.artwork, width: 56, height: 56)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(album.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(releaseYearText(for: album))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func releaseYearText(for album: Album) -> String {
        guard let date = album.releaseDate else { return "" }
        return String(Calendar.current.component(.year, from: date))
    }
}

private struct AlphabetIndexBar: View {
    let onSelect: (String) -> Void

    private let letters: [String] = (65...90).map { String(UnicodeScalar($0)!) }

    var body: some View {
        VStack(spacing: 2) {
            ForEach(letters, id: \.self) { letter in
                Text(letter)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(letter) }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

