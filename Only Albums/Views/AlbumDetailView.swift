import MusicKit
import SwiftUI

struct AlbumDetailView: View {
    let album: Album
    @ObservedObject var musicClient: MusicClient

    @State private var hydratedAlbum: Album?
    @State private var loadingError: String?
    @State private var isPlayingRequestInFlight = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ArtworkImage((hydratedAlbum ?? album).artwork, width: nil, height: 320)
                    .frame(maxWidth: .infinity)
                    .clipped()

                VStack(alignment: .leading, spacing: 6) {
                    Text((hydratedAlbum ?? album).title)
                        .font(.title2.weight(.semibold))

                    Text((hydratedAlbum ?? album).artistName)
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    if let year = releaseYear(for: hydratedAlbum ?? album) {
                        Text(String(year))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                Button {
                    Task { await playAlbum() }
                } label: {
                    HStack {
                        Spacer()
                        if isPlayingRequestInFlight {
                            ProgressView()
                        } else {
                            Label("Play", systemImage: "play.fill")
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(isPlayingRequestInFlight)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Tracks")
                        .font(.headline)
                        .padding(.horizontal)

                    if let tracks = (hydratedAlbum ?? album).tracks {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(tracks, id: \.id) { track in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.title)
                                        .font(.body)
                                    if track.artistName.isEmpty == false {
                                        Text(track.artistName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    } else if let loadingError {
                        ContentUnavailableView(
                            "Couldn’t Load Tracks",
                            systemImage: "exclamationmark.triangle",
                            description: Text(loadingError)
                        )
                        .padding(.horizontal)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
            }
        }
        .navigationTitle("Album")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await hydrate()
        }
    }

    private func hydrate() async {
        do {
            loadingError = nil
            hydratedAlbum = try await musicClient.fetchAlbumWithTracks(albumID: album.id)
        } catch {
            loadingError = String(describing: error)
        }
    }

    private func playAlbum() async {
        isPlayingRequestInFlight = true
        defer { isPlayingRequestInFlight = false }

        do {
            let a: Album
            if let hydratedAlbum {
                a = hydratedAlbum
            } else {
                a = try await musicClient.fetchAlbumWithTracks(albumID: album.id)
            }
            guard let tracks = a.tracks else { return }
            try await musicClient.playAlbumTracks(tracks)
        } catch {
            loadingError = String(describing: error)
        }
    }

    private func releaseYear(for album: Album) -> Int? {
        guard let date = album.releaseDate else { return nil }
        return Calendar.current.component(.year, from: date)
    }
}

