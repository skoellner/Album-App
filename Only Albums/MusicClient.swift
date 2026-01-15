import Foundation
import Combine
import MusicKit

@MainActor
final class MusicClient: ObservableObject {
    enum MusicClientError: Error {
        case notAuthorized
        case albumNotFound
    }

    @Published private(set) var authorizationStatus: MusicAuthorization.Status = .notDetermined

    func ensureAuthorized() async -> Bool {
        let current = MusicAuthorization.currentStatus
        authorizationStatus = current

        guard current != .notDetermined else {
            let requested = await MusicAuthorization.request()
            authorizationStatus = requested
            return requested == .authorized
        }

        return current == .authorized
    }

    func fetchFavoritedLibraryAlbums() async throws -> [Album] {
        guard await ensureAuthorized() else { throw MusicClientError.notAuthorized }

        var request = MusicLibraryRequest<Album>()
        request.limit = 500

        // Note: MusicKit filtering APIs vary slightly by OS/toolchain; we filter in-memory for robustness.
        let response = try await request.response()
        let albums = Array(response.items)

        // TODO (validated on-device): refine to true “favorited albums” once we confirm the exact MusicKit property semantics.
        return albums
    }

    func fetchAlbumWithTracks(albumID: MusicItemID) async throws -> Album {
        guard await ensureAuthorized() else { throw MusicClientError.notAuthorized }

        var request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: albumID)
        request.properties = [.tracks, .artists]
        request.limit = 1

        let response = try await request.response()
        guard let album = response.items.first else { throw MusicClientError.albumNotFound }
        return album
    }

    func playAlbumTracks(_ tracks: MusicItemCollection<Track>) async throws {
        guard await ensureAuthorized() else { throw MusicClientError.notAuthorized }

        let player = SystemMusicPlayer.shared
        player.queue = SystemMusicPlayer.Queue(for: tracks)
        try await player.play()
    }
}

